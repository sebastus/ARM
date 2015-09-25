#
# New_ConfigurationScript.ps1
# Also use this for Update-ConfigurationScript
# 
Import-AzureAutomationDscConfiguration `
    -ResourceGroupName MyAutomationRG -AutomationAccountName MyAutomationAccount `
    -SourcePath C:\temp\AzureAutomationDsc\ISVBoxConfig.ps1 `
    -Published -Force
    
$jobData = Start-AzureAutomationDscCompilationJob `
    -ResourceGroupName MyAutomationRG -AutomationAccountName MyAutomationAccount `
    -ConfigurationName ISVBoxConfig 

$compilationJobId = $jobData.Id

Get-AzureAutomationDscCompilationJob `
    -ResourceGroupName MyAutomationRG -AutomationAccountName MyAutomationAccount `
    -Id $compilationJobId

