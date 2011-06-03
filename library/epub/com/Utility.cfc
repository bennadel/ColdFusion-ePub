
<cfcomponent
	output="false"
	hint="I provide utility methods for use in conjunction with ePub book creation.">
	
	
	<cffunction
		name="init"
		access="public"
		returntype="any"
		output="false"
		hint="I return an intialized component.">
		
		<!--- Return this object reference. --->
		<cfreturn this />
	</cffunction>
	

	<cffunction 
		name="getCallerTemplatePath"
		access="public"
		returntype="string"
		output="false"
		hint="I return the file path of the given caller context (as available within a custom tag).">
		
		<!--- Define arguments. --->
		<cfargument
			name="caller"
			type="any"
			required="true"
			hint="I am the Caller context made available within a custom tag."
			/>
			
		<!--- Define the local scope. --->
		<cfset var local = {} />
		
		<!--- Get the pageContext field for the caller scope. --->
		<cfset local.pageContextProperty = getMetaData( arguments.caller )
			.getDeclaredField(
				javaCast( "string", "pageContext" )
				)
			/>
		
		<!--- Make sure the field is accessible. --->
		<cfset local.pageContextProperty.setAccessible( javaCast( "boolean", true ) ) />
		
		<!--- Return the template path for the calling context. --->
		<cfreturn local.pageContextProperty.get( arguments.caller ).getPage().getCurrentTemplatePath() />
	</cffunction>
	
</cfcomponent>
