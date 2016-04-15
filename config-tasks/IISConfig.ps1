Configuration ConfigureWeb
{ 
	node ("localhost")
	{ 
		WindowsFeature InstallWebServer 
		{ 
			Ensure = "Present"
			Name = "Web-Server" 
		} 
	} 
}