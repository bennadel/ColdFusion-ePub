
<!--- Check the execution mode of the tag. --->
<cfif (thistag.executionMode eq "start")>

	
	<!--- Start Mode. --->

	<!--- Param the book attributes. --->
	
	<!--- This is CSS class that will be added to the body. --->
	<cfparam
		name="attributes.class"
		type="string"
		default=""
		/>


<cfelse>


	<!--- End Mode. --->

	<!--- Define the XHTML wrapper for the content. --->
	<cfxml variable="xhtml">
		<cfoutput>
			
			<?xml version="1.0" encoding="iso-8859-1"?>
			<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title></title>
					<!-- Styles. -->
					<link rel="stylesheet" type="text/css" href="stylesheet.css" />
					
					<!-- For Adobe Digital Editions only. -->
					<link rel="stylesheet" type="application/vnd.adobe-page-template+xml" href="page-template.xpgt" />
				</head>
				<body class="#attributes.class#">
					
					<!--- Defined by user. --->
					#trim( thistag.generatedContent )#

				</body>
			</html>
		
		</cfoutput>
	</cfxml>

	<!--- Get the title from the content (the H1 tag). --->
	<cfset title = xmlSearch(
		xhtml,
		"normalize-space( string( //:h1[ 1 ] ) )"
		) />
		
	<!--- Update the title tag of the XHTML. --->
	<cfset xhtml.xmlRoot.head.title.xmlText = title />
	
	<!--- Create a new section container. --->
	<cfset section = createObject( "component", "com.Section" ).init(
		title = title,
		content = xhtml
		) />
		
	<!--- 
		Add the section to the root book object (the container for 
		all sections in the current ePub book). 
	--->
	<cfset getBaseTagData( "cf_book" ).book.addSection( section ) />


</cfif>
