
<cfcomponent
	output="false"
	hint="I provide the API for a section contained within an ePub book.">
	
	
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
			hint="I am the title of this section (used for linking)."
			/>
			
		<cfargument
			name="content"
			type="string"
			required="true"
			hint="I am the XHTML content for this section."
			/>
			
		<!--- Store the properties. --->
		<cfset variables.title = arguments.title />
		<cfset variables.content = xmlParse( arguments.content ) />
		
		<!--- Return this object reference. --->
		<cfreturn this />
	</cffunction>
	
	
	<cffunction
		name="getContent"
		access="public"
		returntype="xml"
		output="false"
		hint="I return the xhtml content value.">
		
		<cfreturn variables.content />
	</cffunction>
	
	
	<cffunction
		name="getTitle"
		access="public"
		returntype="string"
		output="false"
		hint="I return the title value.">
		
		<cfreturn variables.title />
	</cffunction>	
	
	
</cfcomponent>
