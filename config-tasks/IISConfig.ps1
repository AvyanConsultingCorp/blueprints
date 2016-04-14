Configuration MyBluePrint
{
    Node 'WebServer'
    {
        # Use the Windows Feature resources to add IIS webserver
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name = 'Web-Server'
        }
    }
}