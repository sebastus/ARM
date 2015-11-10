#
# New_ConfigurationScript.ps1
# Also use this for Update-ConfigurationScript
# 
Import-AzureRmAutomationDscConfiguration `
    -ResourceGroupName MyAutomationRG -AutomationAccountName MyAutomationAccount `
    -SourcePath C:\temp\AzureAutomationDsc\ISVBoxConfig.ps1 `
    -Published -Force
    
$jobData = Start-AzureRmAutomationDscCompilationJob `
    -ResourceGroupName MyAutomationRG -AutomationAccountName MyAutomationAccount `
    -ConfigurationName ISVBoxConfig 

$compilationJobId = $jobData.Id

Get-AzureRmAutomationDscCompilationJob `
    -ResourceGroupName MyAutomationRG -AutomationAccountName MyAutomationAccount `
    -Id $compilationJobId

