# Configuration ConfigureWeb
# {
  # param ($machineName)

  # Node $machineName
  # {
    # #Install the IIS Role
    # WindowsFeature IIS
    # {
      # Ensure = "Present"
      # Name = "Web-Server"
    # }

    # #Install ASP.NET 4.6
    # WindowsFeature ASP
    # {
      # Ensure = "Present"
      # Name = "Web-Asp-Net46"
    # }

     # WindowsFeature WebServerManagementConsole
    # {
        # Name = "Web-Mgmt-Console"
        # Ensure = "Present"
    # }
  # }
# }
Configuration IIS
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