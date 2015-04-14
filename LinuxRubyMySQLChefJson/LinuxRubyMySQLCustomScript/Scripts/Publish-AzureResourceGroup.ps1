#Requires -Version 3.0

Param(
  [string] $SubscriptionId,
  [System.Management.Automation.PSCredential] $AzureCredential,
  # parameters above this comment eventually go away
  [string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
  [string] $ResourceGroupName = 'LinuxRubyMySQLChefJson',
  [switch] $StageDrop,
  [string] $StorageAccountName, 
  [string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stagedrop',
  [string] $TemplateFile = '..\Templates\DeploymentTemplate.json',
  [string] $TemplateParametersFile = '..\Templates\DeploymentTemplate.param.dev.json',
  [string] $LocalStorageDropPath = '..\bin\Debug\StorageDrop',
  [string] $AzCopyPath = '..\Tools\AzCopy.exe'
)

Set-StrictMode -Version 3
########################################################### remove this section when New-AzureProfile comes online)
if (!(Get-AzureAccount))
{
    if ($AzureCredential)
    {
        Add-AzureAccount -Credential $AzureCredential
    }
    else
    {   
        Add-AzureAccount
    }
}

if ($SubscriptionId)
{
    Select-AzureSubscription -Id $SubscriptionId -Current
}
######################################################################################################

$OptionalParameters = New-Object -TypeName Hashtable

if ($StageDrop)
{
    # Convert relative paths to absolute paths if needed
    $AzCopyPath = [System.IO.Path]::Combine($PSScriptRoot, $AzCopyPath)
    $TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
    $TemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile)
    $LocalStorageDropPath = [System.IO.Path]::Combine($PSScriptRoot, $LocalStorageDropPath)

    $OptionalParameters.Add('dropLocation', $null)
    $OptionalParameters.Add('dropLocationSasToken', $null)

    # Parse the parameter file and update the values of dopLocation and dropLocationSasToken if they are present
    $JsonContent = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    $JsonContent.parameters | Get-Member -Type NoteProperty | ForEach-Object {

        $ParameterValue = $JsonContent.parameters | Select-Object -ExpandProperty $_.Name
    
        if ($_.Name -eq 'dropLocation' -or $_.Name -eq 'dropLocationSasToken')
        {
            $OptionalParameters[$_.Name] = $ParameterValue.value
        }
    }
       
    Switch-AzureMode AzureServiceManagement
    # Generate the value for dropLocation if it is not provided in the parameter file
    $DropLocation = $OptionalParameters['dropLocation']
    if ($DropLocation -eq $null)
    {
        $StorageAccountKey = (Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary
        $StorageAccountContext = New-AzureStorageContext $StorageAccountName (Get-AzureStorageKey $StorageAccountName).Primary
        $DropLocation = $StorageAccountContext.BlobEndPoint + $StorageContainerName
        $OptionalParameters['dropLocation'] = $DropLocation     
    }
    
    # Use AzCopy to copy files from the local storage drop path to the storage account container
    & "$AzCopyPath" """$LocalStorageDropPath"" $DropLocation /DestKey:$StorageAccountKey /S /Y /Z:""$env:LocalAppData\Microsoft\Azure\AzCopy\$ResourceGroupName"""

    # Generate the value for dropLocationSasToken if it is not provided in the parameter file
    $DropLocationSasToken = $OptionalParameters['dropLocationSasToken']  
    if ($DropLocationSasToken -eq $null)
    {
       # Create a SAS token for the storage container - this gives temporary read-only access to the container (defaults to 1 hour).
       $DropLocationSasToken = New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccountContext -Permission r 
       $DropLocationSasToken = ConvertTo-SecureString $DropLocationSasToken -AsPlainText -Force
       $OptionalParameters['dropLocationSasToken'] = $DropLocationSasToken
    }     
}

# Create or update the resource group using the specified template file and template parameters file
Switch-AzureMode AzureResourceManager
New-AzureResourceGroup -Name $ResourceGroupName `
                       -Location $ResourceGroupLocation `
                       -TemplateFile $TemplateFile `
                       -TemplateParameterFile $TemplateParametersFile `
                        @OptionalParameters `
                        -Force -Verbose
