<#
    Iterates through template and parameter files in the release folder and deploys them
#>
Param ( [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]$ArtifactFolderPath )

# Hashtable for storing template and param file pairs
$deployments = @{}
$paramFiles = @()

try {
    $files = Get-ChildItem -Recurse -Path $ArtifactFolderPath -Filter "*.params.json"
    $paramFiles = $files
}
catch {
    Write-Host "No deployment files"
    return
}

# populate the deployment hashtable based on files in the release directory
foreach($paramFile in $paramFiles) {
    # find the matching template
    $templateFileName = $paramFile.Name.Replace(".params", "")
    $templateFile = Get-ChildItem -Recurse -Path $ArtifactFolderPath -Filter $templateFileName
    $deployments.Add($paramFile.FullName, $templateFile.FullName)
    $paramFullName = $paramFile.Fullname
    $templFullName = $templateFile.FullName
    Write-Host "Added deployment file: $paramFullName"
    Write-Host "Added deployment file: $templFullName "
}

# install Az modules
$env:PSModulePath = "C:\Modules\az_1.0.0\Az\1.0.0;" + $env:PSModulePath
Write-Host "Installing Az module"
Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
Write-Host "Az module installed"

# Authenticate to Azure

# Override for local debugging
# $env:TENANT_ID = ""
# $env:APP_ID = ""
# $env:APP_SECRET = ""
# $env:SUBSCRIPTION_ID = ""

Write-Host "Authenticating to AAD using: $env:APP_ID"
$securePassword = $env:APP_SECRET | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$env:APP_ID", $securePassword
Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $env:TENANT_ID -ErrorAction Stop
Set-AzContext -SubscriptionId  $env:SUBSCRIPTION_ID

# run the deployments
foreach ($item in $deployments.GetEnumerator()) {
    $deploymentNameSuffix = Get-Date -Format FileDateTime
    $deploymentName = $item.Value.Replace(".json", "").Split("\")[-1] + "-$deploymentNameSuffix"
    $paramObj = Get-Content $item.Key | Out-String | ConvertFrom-Json
    $rgName = $paramObj.parameters.resourceGroup.value
    $location = $paramObj.parameters.location.value

    Get-AzResourceGroup -Name $rgName -ErrorVariable notPresent -ErrorAction SilentlyContinue

    if ($notPresent) {
        New-AzResourceGroup -Name $rgName -Location $location -Force
    }

    Write-Host "Starting deployment: $deploymentName"
    New-AzResourceGroupDeployment -ResourceGroupName $rgName -resourceGroupFromTemplate $rgName -Name $deploymentName  -TemplateParameterFile $item.Key -TemplateFile $item.Value -Force -Mode Incremental
    Write-Host "Completed deployment: $deploymentName"
}
