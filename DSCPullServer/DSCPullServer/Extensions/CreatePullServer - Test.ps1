#
# CreatePullServer.ps1
#
# DSC configuration for Pull Server and Compliance Server
# Prerequisite: Certificate "CN=PSDSCPullServerCert" in "CERT:\LocalMachine\MY\" store
# Note: A Certificate may be generated using MakeCert.exe: http://msdn.microsoft.com/en-us/library/windows/desktop/aa386968%28v=vs.85%29.aspx
# this configuration originates here: https://github.com/PowerShell/xPSDesiredStateConfiguration/blob/dev/Examples/Sample_xDscWebService.ps1
#
configuration CreatePullServer
{

    param 
    (
        [string[]]$NodeName = 'localhost',
        [string]$certificateThumbprint = '?d4ca86fd6f8b67745a5acbdba2fa00394dc6dd56'
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration 
    
	# clean up DSC Certs from the store
#	Get-ChildItem CERT:\LocalMachine\MY\ | where {$_.Subject -eq "CN=PSDSCPullServerCert"} | Remove-Item

	# Generate a self-signed cert and deploy it in CERT:\LocalMachine\MY
#	$scriptFolder = Split-Path $script:MyInvocation.MyCommand.Path
#	$makeCertPath = "$scriptFolder\MakeCert.exe"
#	& $makeCertPath -r -pe -n "CN=PSDSCPullServerCert" -ss my -sr localMachine
#	$psDscCert = Get-ChildItem CERT:\LocalMachine\MY\ | where {$_.Subject -eq "CN=PSDSCPullServerCert"}
#	$certificateThumbPrint = $psDscCert.Thumbprint

    Node $NodeName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"            
        }

        xDscWebService PSDSCPullServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint   = $certificateThumbPrint         
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"            
            State                   = "Started"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"                        
        }

        xDscWebService PSDSCComplianceServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCComplianceServer"
            Port                    = 9080
            PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCComplianceServer"
            CertificateThumbPrint   = "AllowUnencryptedTraffic"
            State                   = "Started"
            IsComplianceServer      = $true
            DependsOn               = @("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
        }
    }

 }

CreatePullServer

start-dscconfiguration CreatePullServer -wait -Verbose
