
<cfcomponent
	output="false"
	hint="I provide the core API for creating an ePub book.">
	
	
	<cffunction
		name="init"
		access="public"
		returntype="any"
		output="false"
		hint="I return an intialized component.">
		
		<!--- Define arguments. --->
		<cfargument
			name="title"
			type="string"
			required="true"
			hint="I am the title of the ePub book."
			/>
		
		<cfargument
			name="author"
			type="string"
			required="true"
			hint="I am the author of the book."
			/>

		<cfargument
			name="publisher"
			type="string"
			required="true"
			hint="I am the publisher of the book."
			/>

		<cfargument
			name="filename"
			type="string"
			required="true"
			hint="I am the file path to which the generated [.epub] file will be written."
			/>
			
		<cfargument
			name="overwrite"
			type="boolean"
			required="false"
			default="false"
			hint="I determine whether or not a new ePub file can be generated over an exisitng ePub file (should one already exist at the [filename] location)."
			/>
		
		<cfargument
			name="tempDirectory"
			type="string"
			required="false"
			default="#getTempDirectory()#"
			hint="I am the temp directory in which the intermediary ePub assets will be put during file generation."
			/>
			
		<cfargument
			name="templateDirectory"
			type="string"
			required="true"
			hint="I am the directory which represents the initial cookie-cutter version of the ePub book contents. When the book is being generated, this directory will copied to the scratch directory and then augmented."
			/>
			
		<cfargument
			name="documentRoot"
			type="string"
			required="true"
			hint="I am the directory of the document that is being compiled into an ePub book. This is required in order to import the image assets with relative file paths."
			/>
			
		<cfargument
			name="convertImagesToPNG"
			type="boolean"
			required="false"
			default="false"
			hint="Some ePub readers can only handle PNG images. This allows you to convert the images to PNG on the fly (if desired)."
			/>
		
		<cfargument
			name="stylesheet"
			type="string"
			required="false"
			default=""
			hint="I am the optional stylesheet that can be used in place of the core CSS."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Store the properties. --->
		<cfset variables.title = arguments.title />
		<cfset variables.author = arguments.author />
		<cfset variables.publisher = arguments.publisher />
		<cfset variables.filename = arguments.filename />
		<cfset variables.overwrite = arguments.overwrite />
		<cfset variables.tempDirectory = arguments.tempDirectory />
		<cfset variables.templateDirectory = arguments.templateDirectory />
		<cfset variables.documentRoot = arguments.documentRoot />
		<cfset variables.convertImagesToPNG = arguments.convertImagesToPNG />
		<cfset variables.stylesheet = arguments.stylesheet />
		
		<!--- 
			Create a collection of sections for the book. These will 
			be instance of the Section.cfc.
		--->
		<cfset variables.sections = [] />
		
		<!--- 
			Create a collection of images for the book. These will be imported
			during the compile process.
		--->
		<cfset variables.images = [] />
		
		<!--- 
			Create a UUID for this book. Each book needs to have a unique identifier
			which will be used when generating the XML. 
		--->
		<cfset variables.bookID = createUUID() />
		
		<!--- Return this object reference. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction 
		name="addSection"
		access="public"
		returntype="any"
		output="false"
		hint="I add the given section to the book.">
		
		<!--- Define arguments. --->
		<cfargument
			name="section"
			type="any"
			required="true"
			hint="I am the Section.cfc being added to the book."
			/>
		
		<!--- Add to the sections collection. --->
		<cfset arrayAppend( variables.sections, arguments.section ) />
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="compile"
		access="public"
		returntype="any"
		output="false"
		hint="I compile the book into an actual .epub binary file.">
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- 
			The first thing we want to do is check to see if this is even worth doing - 
			that is, are we going to have any file overwriting conflits. 
		--->
		<cfif (
			!variables.overwrite &&
			fileExists( variables.filename )
			)>
			
			<!--- There will be an inappropriate file conflict. --->
			<cfthrow
				type="ExistingFile"
				message="There is already an existing file at the given filename [#attributes.filename#]."
				detail="In order to ovewrite an existing file, you must set ovewrite to true."
				/>
			
		</cfif>
		
		<!--- 
			Copy the template directory into the temp directory so that we can start
			building the assets. 
		--->
		<cfset local.scratchDirectory = this.generateScratchDirectory() />
		
		<!--- 
			Now that we have our scratch directory, we are going to create our ePub 
			book. If anything goes wrong during this process, we want to leave the 
			disk as clean as possible. As such, let's put this in a try/catch and 
			clean up the disk in error (like a trasnactional rollback). 
		--->
		<cftry>
		
			<!--- Generate the files. --->
			<cfset this.generateXhtmlFiles( local.scratchDirectory ) />
			
			<!--- Augment the content.opf file. --->
			<cfset this.configureContent( local.scratchDirectory ) />
			
			<!--- Augment the table-of-contents file. --->
			<cfset this.configureTOC( local.scratchDirectory ) />
			
			<!--- Merge the stylesheet. --->
			<cfset this.mergeStylesheet( local.scratchDirectory ) />
			
			<!--- 
				Now that we have configured all of the content, zip it all up into
				an ePub file. 
			--->
			<cfzip
				action="zip"
				file="#variables.filename#"
				source="#local.scratchDirectory#"
				overwrite="#variables.overwrite#"
				recurse="true"
				storepath="true"
				/>
				
			<!--- Catch any compile errors. --->
			<cfcatch>
			
				<!--- Try to clean up the disk. --->
				<cfset this.destroyScratchDirectory( local.scratchDirectory ) />

				<!--- Rethrow the error. --->
				<cfrethrow />

			</cfcatch>
				
		</cftry>

		<!--- Remove the scratch directory. --->
		<cfset this.destroyScratchDirectory( local.scratchDirectory ) />
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="configureContent"
		access="public"
		returntype="any"
		output="false"
		hint="I augment the templated contenet.opf file.">
		
		<!--- Define arguments. --->
		<cfargument
			name="scratchDirectory"
			type="string"
			required="true"
			hint="I am the scratch directory in which we will configure the content.opf file."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Get the file path to our content file. --->
		<cfset local.contentFilePath = "#arguments.scratchDirectory#OEBPS/content.opf" />
		
		<!--- Read in the current content file as XML. --->
		<cfset local.content = xmlParse( local.contentFilePath ) />
		
		<!--- Locate the title node. --->
		<cfset local.titleNodes = xmlSearch(
			local.content,
			"//dc:title"
			) />
		
		<!--- Update the title. --->
		<cfset local.titleNodes[ 1 ].xmlText = variables.title />
		
		<!--- Locate the author nodes. --->
		<cfset local.authorNodes = xmlSearch(
			local.content,
			"//dc:creator"
			) />
			
		<!--- Update the author. --->
		<cfset local.authorNodes[ 1 ].xmlText = variables.author />
			
		<!--- Locate the publisher nodes. --->
		<cfset local.publisherNodes = xmlSearch(
			local.content,
			"//dc:publisher"
			) />
			
		<!--- Update the publisher. --->
		<cfset local.publisherNodes[ 1 ].xmlText = variables.publisher />
	
		<!--- Locate the bookID nodes. --->
		<cfset local.bookIDNodes = xmlSearch(
			local.content,
			"//dc:identifier"
			) />
			
		<!--- Update the bookID. --->
		<cfset local.bookIDNodes[ 1 ].xmlText = "urn:uuid:#variables.bookID#" />
		
		<!--- 
			Find the manifest node. This is the node to which we are going to be
			adding section items. 
		--->
		<cfset local.manifestNodes = xmlSearch(
			local.content,
			"//:manifest"
			) />
			
		<!--- Get the actual manifest node. --->
		<cfset local.manifestNode = local.manifestNodes[ 1 ] />
		
		<!--- Loop over the sections to create a manifest item. --->
		<cfloop
			index="local.sectionIndex"
			from="1"
			to="#arrayLen( variables.sections )#"
			step="1">
			
			<!--- Get the section refrence. --->
			<cfset local.section = variables.sections[ local.sectionIndex ] />
			
			<!--- Create a new ITEM node for this section. --->
			<cfset local.itemNode = xmlElemNew( local.content, "item" ) />
			
			<!--- Set the properties. --->
			<cfset local.itemNode.xmlAttributes[ "id" ] = "section_#local.sectionIndex#" />
			<cfset local.itemNode.xmlAttributes[ "href" ] = "section_#local.sectionIndex#.xhtml" />
			<cfset local.itemNode.xmlAttributes[ "media-type" ] = "application/xhtml+xml" />
			
			<!--- Add this item to the manifest. --->
			<cfset arrayAppend( local.manifestNode.xmlChildren, local.itemNode ) />
			
		</cfloop>
		
		<!--- Loop over the images to create a manifest item. --->
		<cfloop
			index="local.imageIndex"
			from="1"
			to="#arrayLen( variables.images )#"
			step="1">
			
			<!--- Get the image filename. --->
			<cfset local.imageFilename = variables.images[ local.imageIndex ] />
			
			<!--- Create a new ITEM node for this image. --->
			<cfset local.itemNode = xmlElemNew( local.content, "item" ) />
			
			<!--- Set the properties. --->
			<cfset local.itemNode.xmlAttributes[ "id" ] = "image_#local.imageIndex#" />
			<cfset local.itemNode.xmlAttributes[ "href" ] = "images/#local.imageFilename#" />
			<cfset local.itemNode.xmlAttributes[ "media-type" ] = "image/#listLast( local.imageFilename, '.' )#" />
			
			<!--- Add this item to the manifest. --->
			<cfset arrayAppend( local.manifestNode.xmlChildren, local.itemNode ) />
			
		</cfloop>
		
		<!--- 
			Find the spine node. This is the node to which we are going to be
			adding the able of contents (this is like the manifest, but only
			includes the sections of the book, not additional assets). 
		--->
		<cfset local.spineNodes = xmlSearch(
			local.content,
			"//:spine"
			) />
			
		<!--- Get the actual spine node. --->
		<cfset local.spineNode = local.spineNodes[ 1 ] />
		
		<!--- Loop over the sections to create a each spine item. --->
		<cfloop
			index="local.sectionIndex"
			from="1"
			to="#arrayLen( variables.sections )#"
			step="1">
			
			<!--- Get the section refrence. --->
			<cfset local.section = variables.sections[ local.sectionIndex ] />
			
			<!--- Create a new ItemRef node for this section. --->
			<cfset local.itemNode = xmlElemNew( local.content, "itemref" ) />
			
			<!--- Set the properties. --->
			<cfset local.itemNode.xmlAttributes[ "idref" ] = "section_#local.sectionIndex#" />
			
			<!--- Add this item to the spine. --->
			<cfset arrayAppend( local.spineNode.xmlChildren, local.itemNode ) />
			
		</cfloop>
		
		<!--- Write the updated content XML document back to the disk. --->
		<cffile
			action="write"
			file="#local.contentFilePath#"
			output="#toString( local.content )#"
			/>
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="configureTOC"
		access="public"
		returntype="any"
		output="false"
		hint="I augment the templated toc.ncx file.">
		
		<!--- Define arguments. --->
		<cfargument
			name="scratchDirectory"
			type="string"
			required="true"
			hint="I am the scratch directory in which we will configure the toc.ncx file."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Get the file path to our TOC file. --->
		<cfset local.tocFilePath = "#arguments.scratchDirectory#OEBPS/toc.ncx" />
		
		<!--- Read in the current TOC file as XML. --->
		<cfset local.toc = xmlParse( local.tocFilePath ) />
		
		<!--- Locate the bookID node. --->
		<cfset local.bookIDNodes = xmlSearch(
			local.toc,
			"//:meta[ @name = 'dtb:uid' ]"
			) />
			
		<!--- Update the bookID. --->
		<cfset local.bookIDNodes[ 1 ].xmlAttributes[ "content" ] = variables.bookID />
		
		<!--- Locate the title node. --->
		<cfset local.titleNodes = xmlSearch(
			local.toc,
			"//:docTitle/:text/"
			) />
		
		<!--- Update the title. --->
		<cfset local.titleNodes[ 1 ].xmlText = variables.title />

		<!--- 
			Find the navMap node. This is the node to which we are going to be
			adding section items. 
		--->
		<cfset local.navMapNodes = xmlSearch(
			local.toc,
			"//:navMap"
			) />
			
		<!--- Get the actual navMap node. --->
		<cfset local.navMapNode = local.navMapNodes[ 1 ] />
		
		<!--- Loop over the sections to create navMap items. --->
		<cfloop
			index="local.sectionIndex"
			from="1"
			to="#arrayLen( variables.sections )#"
			step="1">
			
			<!--- Get the section refrence. --->
			<cfset local.section = variables.sections[ local.sectionIndex ] />
			
			<!--- Create a new point node for this section. --->
			<cfset local.pointNode = xmlElemNew( local.toc, "navPoint" ) />
			
			<!--- Set the properties. --->
			<cfset local.pointNode.xmlAttributes[ "id" ] = "section_#local.sectionIndex#" />
			<cfset local.pointNode.xmlAttributes[ "playOrder" ] = local.sectionIndex />
			
			<!--- Create the label node for this section. --->
			<cfset local.labelNode = xmlElemNew( local.toc, "navLabel" ) />
			
			<!--- Create teh text node for this section. --->
			<cfset local.textNode = xmlElemNew( local.toc, "text" ) />
			
			<!--- Set the text. --->
			<cfset local.textNode.xmlText = local.section.getTitle() />
			
			<!--- Create the content node for this section. --->
			<cfset local.contentNode = xmlElemNew( local.toc, "content" ) />
			
			<!--- Set the properties. --->
			<cfset local.contentNode.xmlAttributes[ "src" ] = "section_#local.sectionIndex#.xhtml" />
			
			<!--- Synthsize the nav item node. --->
			<cfset arrayAppend( local.labelNode.xmlChildren, local.textNode ) />
			<cfset arrayAppend( local.pointNode.xmlChildren, local.labelNode ) />
			<cfset arrayAppend( local.pointNode.xmlChildren, local.contentNode ) />

			<!--- Add this item to the nav map. --->
			<cfset arrayAppend( local.navMapNode.xmlChildren, local.pointNode ) />
			
		</cfloop>
		
		<!--- Write the updated TOC XML document back to the disk. --->
		<cffile
			action="write"
			file="#local.tocFilePath#"
			output="#toString( local.toc )#"
			/>
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="destroyScratchDirectory"
		access="public"
		returntype="any"
		output="false"
		hint="I remove the scratch directory.">
		
		<!--- Define arguments. --->
		<cfargument
			name="scratchDirectory"
			type="string"
			required="true"
			hint="I am the scratch directory being cleaned up (removed)."
			/>
		
		<!--- 
			Check to see if the directory exists. Since this function (destroy) may be 
			called if anything goes wrong (so as to leave the disk as clean as possible), 
			we need to check to see if the directory exists before we try to delete it.
		--->
		<cfif directoryExists( arguments.scratchDirectory )>
				
			<!--- Delete the scratch directory. --->
			<cfdirectory
				action="delete"
				directory="#arguments.scratchDirectory#"
				recurse="true"
				/>
	
		</cfif>
			
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="generateScratchDirectory"
		access="public"
		returntype="string"
		output="false"
		hint="I copy the given template directory to the given temp directory with a unique name (and return that unique filepath).">
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Use the unique book ID to define the scratch directory. --->
		<cfset local.scratchDirectory = "#variables.tempDirectory#/#variables.bookID#/" />
		
		<!--- Create the scratch directory. --->
		<cfdirectory
			action="create"
			directory="#local.scratchDirectory#"
			/>
		
		<!--- Gather all the directories in the template directory. --->
		<cfdirectory 
			name="local.templateAssets"
			action="list"
			directory="#variables.templateDirectory#"
			type="dir"
			recurse="true"
			/>
			
		<!--- Loop over the template directories top copy them over. --->
		<cfloop query="local.templateAssets">
		
			<!--- Determine the relative path from the template directory. --->
			<cfset local.relativePath = (
				replaceNoCase(
					"#local.templateAssets.directory#/",
					variables.templateDirectory,
					"",
					"one"
					) &
				local.templateAssets.name &
				"/"
				) />
		
			<!--- Create the new directory. --->
			<cfdirectory
				action="create"
				directory="#local.scratchDirectory#/#local.relativePath#"
				/> 
		
		</cfloop>
		
		<!--- Gather all the files in the template directory. --->
		<cfdirectory 
			name="local.templateAssets"
			action="list"
			directory="#variables.templateDirectory#"
			type="file"
			recurse="true"
			/>
			
		<!--- Loop over the template files top copy them over. --->
		<cfloop query="local.templateAssets">
		
			<!--- Determine the relative path from the template directory. --->
			<cfset local.relativePath = (
				replaceNoCase(
					"#local.templateAssets.directory#/",
					variables.templateDirectory,
					"",
					"one"
					) &
				local.templateAssets.name
				) />
				
			<!--- Copy the file to scratch directory. --->
			<cffile
				action="copy"
				source="#local.templateAssets.directory#/#local.templateAssets.name#"
				destination="#local.scratchDirectory#/#local.relativePath#"
				/>
				
		</cfloop>
		
		<!--- Return the path to the generated scratch directory. --->
		<cfreturn local.scratchDirectory />
	</cffunction>
	
	
	<cffunction
		name="generateXhtmlFiles"
		access="public"
		returntype="any"
		output="false"
		hint="I generate an XHTML file for each section.">
		
		<!--- Define arguments. --->
		<cfargument
			name="scratchDirectory"
			type="string"
			required="true"
			hint="I am the scratch directory in which we will be generated the XHTML files."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- For each section, create an XHTML file. --->
		<cfloop
			index="local.sectionIndex"
			from="1"
			to="#arrayLen( variables.sections )#"
			step="1">
			
			<!--- Get a reference to this section. --->
			<cfset local.section = variables.sections[ local.sectionIndex ] />
			
			<!--- 
				Get the content for the section. As we do this, however, import 
				the images (and later the content as necessary).
			--->
			<cfset local.content = this.importImages(
				arguments.scratchDirectory, 
				local.section.getContent()
				) />
				
			<!--- Create the XHTML file. --->
			<cffile
				action="write"
				file="#arguments.scratchDirectory#OEBPS/section_#local.sectionIndex#.xhtml"
				output="#toString( local.content )#"
				/>
			
		</cfloop>
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="importImages"
		access="public"
		returntype="any"
		output="false"
		hint="I copy the images from each section into the scratch directory.">
		
		<!--- Define arguments. --->
		<cfargument
			name="scratchDirectory"
			type="string"
			required="true"
			hint="I am the scratch directory into which we will be importing images."
			/>
			
		<cfargument
			name="content"
			type="xml"
			required="true"
			hint="I am the xhtml content from which we are going to import images."
			/>
		
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Get the images directory. --->
		<cfset local.imagesDirectory = "#arguments.scratchDirectory#OEBPS/images/" />
	
		<!--- Find all of the image nodes in the content. --->
		<cfset local.imageNodes = xmlSearch(
			arguments.content,
			"//:img[ @src ]"
			) />
				
		<!--- Loop over the images to copy the files. --->
		<cfloop
			index="local.imageNode"
			array="#local.imageNodes#">
			
			<!--- Get the external path. --->
			<cfset local.externalFilePath = "#variables.documentRoot##local.imageNode.xmlAttributes.src#" />
			
			<!--- Get the file name of the image that we are going to create locally. --->
			<cfset local.internalFilename = reReplace(
				getFileFromPath( local.externalFilePath ),
				"(\.[^.]+$)",
				"_#hash( local.externalFilePath )#\1",
				"one"
				) />
			
			<!--- 
				Copy the file locally. When doing this, we need to check to see if the
				images need to be converted to PNG on the fly (for some ePub reader support).
			--->
			<cfif (
				variables.convertImagesToPNG &&
				!reFindNoCase( "\.png$", local.internalFilename )
				)>
				
				<!--- Update the PNG-filename. --->
				<cfset local.internalFilename = reReplace(
					local.internalFilename,
					"[^.]+$",
					"png",
					"one"
					) />
				
				<!--- Copy and convert the image in one move. --->
				<cfimage
					action="write"
					source="#local.externalFilePath#"
					destination="#local.imagesDirectory##local.internalFilename#"
					quality=".9"
					/>
				
			<cfelse>
			
				<!--- No need to conver to PNG; just do a straight file copy --->
				<cffile
					action="copy"
					source="#local.externalFilePath#"
					destination="#local.imagesDirectory##local.internalFilename#"
					/>
				
			</cfif>
			
			<!--- Update the image node for internal usage. --->
			<cfset local.imageNode.xmlAttributes.src = "images/#local.internalFilename#" />
			
			<!--- Add the images name to the images collection. --->
			<cfset arrayAppend( variables.images, local.internalFilename ) />
			
		</cfloop>
		
		<!--- Return this updated content. --->
		<cfreturn arguments.content />
	</cffunction>
	
	
	<cffunction
		name="mergeStylesheet"
		access="public"
		returntype="any"
		output="false"
		hint="I mege in any external stylesheet requirement.">
		
		<!--- Define arguments. --->
		<cfargument
			name="scratchDirectory"
			type="string"
			required="true"
			hint="I am the scratch directory in which we may update the styles."
			/>
			
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Check to see if we have any external stylesheet - if not we can exit. --->
		<cfif !len( variables.stylesheet )>
		
			<!--- Nothing to do here. --->
			<cfreturn this />
		
		</cfif>
		
		<!--- Overrite the stylesheet file. --->
		<cffile
			action="write"
			file="#arguments.scratchDirectory#OEBPS/stylesheet.css"
			output="#variables.stylesheet#"
			/>
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="setStylesheet"
		access="public"
		returntype="any"
		output="false"
		hint="I override the core stylesheet.">
		
		<!--- Define arguments. --->
		<cfargument
			name="stylesheet"
			type="string"
			required="true"
			hint="I am the CSS content to be used in lieu of the core stylesheet."
			/>
			
		<!--- Store the stylesheet. --->
		<cfset variables.stylesheet = arguments.stylesheet />
		
		<!--- Return this object reference for method chaining. --->
		<cfreturn this />
	</cffunction>
	
	
</cfcomponent>
