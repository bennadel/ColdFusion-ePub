
<!--- Check the execution mode of the tag. --->
<cfif (thistag.executionMode eq "end")>

		
	<!--- Set the styles for the book. --->
	<cfset getBaseTagData( "cf_book" ).book.setStylesheet( thistag.generatedContent ) />


</cfif>
