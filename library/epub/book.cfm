
<!--- Check the execution mode of the tag. --->
<cfif (thistag.executionMode eq "start")>


	<!--- Start Mode. --->

	<!--- Param the book attributes. --->
	
	<!--- This is the name of the book. --->
	<cfparam
		name="attributes.title"
		type="string"
		/>
		
	<!--- This is the author of the book. --->
	<cfparam
		name="attributes.author"
		type="string"
		/>
		
	<!--- This is the publisher of the book. --->
	<cfparam
		name="attributes.publisher"
		type="string"
		/>

	<!--- 
		This is the full file path to ePub file that we are 
		going to generate. 
	--->
	<cfparam
		name="attributes.filename"
		type="string"
		/>
		
	<!--- 
		This determines whether or not we can overwrite an existing 
		ePub file at the given filename. By default, this will throw
		an error if there is an existing file.  
	--->
	<cfparam
		name="attributes.overwrite"
		type="boolean"
		default="false"
		/>
		
	<!--- 
		This is the scratch directory that this tag will use to 
		create the intermediary ePub assets. 
	--->
	<cfparam
		name="attributes.tempDirectory"
		type="string"
		default="#getTempDirectory()#"
		/>
		
	<!--- 
		This is the boilerplate directory for the ePub book. When the 
		book is generated, the first thing that will happen is this
		directory will get copied to the scratch (temp) directory and
		then be augmented for the book specifics.
	--->
	<cfparam
		name="attributes.templateDirectory"
		type="string"
		default="#getDirectoryFromPath( getCurrentTemplatePath() )#template/"
		/>
		
	<!--- 
		This is the directory for the "document" that is being compiled 
		into an ePub file. This is used to calculate the relatives paths
		of any images used in the content of the ePub sections.
		
		NOTE: This will default to the directory of the calling context
		(the way CFDocument works). 
	--->
	<cfparam 
		name="attributes.documentRoot"
		type="string"
		default="#getDirectoryFromPath( createObject( 'component', 'com.Utility' ).init().getCallerTemplatePath( caller ) )#"
		/>
		
	<!--- 
		I determine whether or not the imported images should be converted 
		to PNG format on the fly. Some ePub readers can only handle PNG format. 
	--->
	<cfparam
		name="convertImagesToPNG"
		type="boolean"
		default="false"
		/>
		
		
	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->
	<!--- ------------------------------------------------- --->


	<!--- 
		Create an instance of the Book component using the attributes
		as the arguments. 
	--->
	<cfset book = createObject( "component", "com.Book" ).init(
		argumentCollection = attributes
		) />

	
<cfelse>


	<!--- End Mode. --->
	
	<!--- 
		At this point, all the sections will have been added. Now, 
		it's time to generate the physical ePub book asset. 
	--->
	<cfset book.compile() />
	
	<!--- Clear the generated output for the ePub tags. --->
	<cfset thistag.generatedContent = "" />


</cfif>
