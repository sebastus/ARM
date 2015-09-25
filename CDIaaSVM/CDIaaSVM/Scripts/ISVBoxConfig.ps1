#
# ISVBoxConfig.ps1
#
# Creates a node configuration named 'ISVBoxConfig.isvbox'
# Replace the address of the NuGet server below
# Replace the name of the package to install.  Mine is 'trivialWeb'
#
Configuration ISVBoxConfig
{
    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName xNetworking

    Node "isvbox" {

		cChocoInstaller installChoco
		{
			InstallDir = "C:\choco"
		}

        WindowsFeature installIIS 
        {
            Ensure="Present"
            Name="Web-Server"
        }

        xFirewall WebFirewallRule
        {
            Direction = "Inbound"
            Name = "Web-Server-TCP-In"
            DisplayName = "Web Server (TCP-In)"
            Description = "Inbound rule for IIS to allow incoming web site traffic."
            DisplayGroup = "Internet Information Service Incoming Traffic"
            State = "Enabled"
            Access = "Allow"
            Protocol = "TCP"
            LocalPort = "80"
            Ensure = "Present"
        }

        cChocoPackageInstaller trivialWeb
		{            
			Name = "trivialweb"
            Version = "1.0.0"
            Source = "https://<your NuGet server address>"
			DependsOn = "[cChocoInstaller]installChoco",
             "[WindowsFeature]installIIS"
		}
    }

}