## Create Azure resources

Run DeplySqlResources.cmd.

VMs created:

VM | role | static IP?
---|------|-----------
app1-ad-1 | Domain controller (primary) | 10.0.0.4
app1-ad-2 | Domain controller (secondary) | 10.0.0.6
app1-sql-1 | SQL Server (primary replica) | dynamic
app1-sql-2 | SQL Server (secondary replica) | dynamic
app1-fsw  | File share witness | dynamic
app1-jump | Jumpbox | dynamic

where *app1* is the the APP_NAME variable in the batch file. All VMs have a local user account "sqladmin".

(Throughout this doc, replace "app1" with the actual value of APP_NAME.)

## Create Forest

RDP into the jumpbox with the local account (e.g., "app1-jump\sqladmin").

From there, RDP into ad-1, using its static IP address (10.0.0.4), with the local account (e.g., "app1-ad-1\sqladmin")

Copy Create-AdForest.ps1 to ad-1 and run it from PowerShell.

    ./Create-AdForest.ps1 -SafeModePassword <pwd> -Domain contoso.local

Select 'Yes' when prompted to configure the domain controller.

## Promote secondary DC

From the jumpbox, RDP into ad-2, using its static IP address (10.0.0.6), with the local account (e.g., "app1-ad-2\sqladmin")

Copy Configure-SecondaryDC.ps1 to ad-2 and run it from PowerShell.

    ./Configure-SecondaryDC.ps1 -SafeModePassword <pwd> -Domain contoso.local `
       -AdminUser contoso.local\sqladmin -AdminPassword <admin-pwd>

Where `admin-pwd` is the password that you passed into the batch file.

At this point, ad-1 and ad-2 are domain controllers for contoso.local, and you can log into them as "contoso.local\sqladmin".

## Prepare SQL VMs

For app1-sql-1 and app1-sql-2:

1. Find the private IP address on the NIC. You can get this from the portal.

2. Log into the local account.

3. Run Add-SqlServerDomainUser.ps1

        ./Add-SqlServerDomainUser.ps1 -Domain contoso.local -AdminUser contoso\sqladmin -AdminPassword <pwd>

    This script adds the contoso.local\sqladmin domain user as a sysadmin on the SQL server instance.

4. Join the VM to the domain. You can run JoinDomain.ps1

        ./JoinDomain.ps1 -SafeModePassword <pwd> -Domain contoso.local -AdminUser contoso\sqladmin -AdminPassword <domain-pwd>


## Configure file-share witness

Join app1-fsw to the domain. Then log into as the domain user (contoso.local\sqladmin).

Run Configure-FileShareWitness.ps1.

This script creates a file share at `\\app1-fsw\cluster1-fsw` which is needed for the file share witness, which is used to establish a quorum in the failover cluster.


## Create the SQL availability group

Log into sql-1 with domain credentials.

1. Run Create-FailoverCluster.ps1 to create the failover cluster.

        ./Create-FailoverCluster.ps1 -AppName "app1" -ClusterName "cluster1"

    For -AppName, use the value of APP_NAME from the batch file.


2. Run Create-SqlAvailabilityGroup.ps1

        ./Create-SqlAvailabilityGroup.ps1 -AdminUser contoso.local\sqladmin -AdminPassword <pwd> -AppName app1 -Domain contoso.local
