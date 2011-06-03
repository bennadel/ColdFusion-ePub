
<cfcomponent
	output="false"
	hint="I define the application settings and event handlers.">
	
	<!--- Define the application settings. --->
	<cfset this.name = hash( getCurrentTemplatePath() ) />
	<cfset this.applicationTimeout = createTimeSpan( 0, 0, 5, 0 ) />
	
	<!--- Define the request settings. --->
	<cfsetting showdebugoutput="false" />
	
</cfcomponent>
