#
# New_AutomationAccount.ps1
#
Switch-AzureMode -Name AzureResourceManager 

# gain access to Microsoft.Automation resource provider and feature set (do this once)
Register-AzureProvider –ProviderNamespace Microsoft.Automation 
Register-AzureProviderFeature -FeatureName dsc -ProviderNamespace Microsoft.Automation 

# Create a resource group to contain your automation account
New-AzureResourceGroup –Name MyAutomationRG –Location “East US 2” 

# Create your automation account in the new RG
New-AzureAutomationAccount –ResourceGroupName MyAutomationRG –Location “East US 2” –Name MyAutomationAccount
