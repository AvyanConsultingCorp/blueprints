Steps:
====
** Create Active Directory Tenant myaadname.onmicrosoft.com and a Global Admin user
* Browse to azure management portal manage.windowsazure.com
* Add a new active directory myaadname
* Optional: add a customer domain mydomainname.com.
* Add a global admin user, e.g. globalAdmin
     Make sure to set the role to Global Admin. 
     Make a note of the temp password.
* Login to https://account.activedirectory.windowsazure.com/ with GlobalAdmin@myaadname.onmicrosoft.com and update the password

====
** Create a Simulated On-Premises environment with ADDS
 
   Note: please replace mydomainname with your own unique domain name in the following direction.

* Open and edit onpremdeploy.sh
* Fill the follwoign values (for example)
	BASE_NAME=my (use a short name less than 4 letters)
	SUBSCRIPTION=MySubscriptionId
	LOCATION=eastus
	ADMIN_USER_NAME=adminUser
	ADMIN_PASSWORD=adminP@ssw0rd
	DOMAIN_NAME=mydomainname.com
	DOMAIN_NETBIOS_NAME=MYDOMAINNAME
* Save the file
* Start the bash command and run the script
* Start the azure portal, expand the resource group my-rg
* RDP to my-1-vm
*. Verify that mydomainname ADDS is installed correctly.
* Add a new user mydomainname\OnPremUser1


====
** Install Azure AD Connect on the ADDS server

*  Download and install Microsoft Azure Active Directory Connect (AzureADConnect.msi) 
*  Install with with Express settings
*  After installation completion, browse to Azure management portal to myaadname
*  If mydomainname.com is not a verified domain, Verify that OnPremUer1@myaadname.onmicrosoft.com (Local Active Directory) is available
*  If mydomainname.com is a verified domain, Verify that OnPremUer1@mydomainname.com (Local Active Directory) is available

====
** Test: Login to https://account.activedirectory.windowsazure.com/
*  If mydomainname.com is not a verified custom domain, use account name OnPreUser1@myaadname.onmicrosoft.com

*  If mydomainname.com is a verified custom domain, use account name OnPreUser1@mydomainname.com


*  You should be able to see your profiles and applications you can run


====

** Initiate a Delta Sync

*  RDP to mydomainname ADDS server my-1-vm
.
*  Add a new user mydomainname\OnPremUser2
*  To initiate a Delta Sync, open Windows PowerShell and run:
	Start-ADSyncSyncCycle  -PolicyType  Delta
*  To initiate a Full Sync, on the DirSync server, open Windows PowerShell and run:
	Start-ADSyncSyncCycle  -PolicyType  Initial
*  Browse to Azure management portal to myaadname
*  If mydomainname.com is not a verified domain, Verify that OnPremUer2@myaadname.onmicrosoft.com (Local Active Directory) is available
*  If mydomainname.com is a verified domain, Verify that OnPremUer2@mydomainname.com (Local Active Directory) is available


====
** Test: Login to https://account.activedirectory.windowsazure.com/
*  If mydomainname.com is not a verified custom domain, use account name OnPreUser2@myaadname.onmicrosoft.com

*  If mydomainname.com is a verified custom domain, use account name OnPreUser2@mydomainname.com


*  You should be able to see your profiles and applications you can run


====
** Create WebApp1 (ASP.NET 4.6.2) to authenticate with the AAD tenant myaadname.onmicrosoft.com
* Start VS
* Add a new ASP.NET Web Application 
   *Visual C# => Web => ASP.NET Web Application =>ASP.NET 4.6.2 Templates => MVC
   *Change Authentication to Work And Shool Accounts and use Cloud -Single Organization and select Domain to myaadname
   *Let VS to create the project
* Open Startup.cs and insert the following line:
    using Owin;
    [assembly:OwinStartup(typeof(WebApp1.Startup))]
    namespace WebApp1
* Build and start the web app 
* Login to the application with 
   GlobalAdmin@myaadname.onmicrosoft.com
   OnPreUser1@myaadname.onmicrosoft.com or OnPreUser1@mydomainname.com



====
** Create WebApp2 (ASP.NET 5 Web Application) to authenticate with the AAD tenant myaadname.onmicrosoft.com
1. Start VS
2. Add a new ASP.NET Web Application 
   *Visual C# => Web => ASP.NET Web Application =>ASP.NET 5 Templates => Web Application
   *Change Authentication to Work And School Accounts and use Cloud -Single Organization and select Domain to myaadname
   *Let VS to create the project
* Build and start the web app 
* Login to the application with 
   GlobalAdmin@myaadname.onmicrosoft.com
   OnPreUser1@myaadname.onmicrosoft.com or OnPreUser1@mydomainname.com


