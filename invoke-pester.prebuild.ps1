<#
    Receives comma-separated list of deployment parameter files and identifies the referenced ARM template
    For each deployment parameter file, the resource types contained in the ARM template is documented and
    a matchign Pester test is launched for it.
#>

Param ( [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]$DeploymentFiles,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]$RootFolder
    )
    
# Set up directory paths
$currentPath = $MyInvocation.MyCommand.Path
$currentPath = $currentPath | Split-Path -Parent
Write-Host "Current path: $currentPath"
$testScriptPath = $currentPath + '\azure-gitops\tests*'

<#
    This function examines an ARM template file and returns a list of the resource types it deploys
    This list of resources is sent as a parameter to the Invoke-Pester command to tell Pester which tests to run
#>
function Get-ResourceTypes($templatePath) {

    $resourceTypes = @()
    $templateObj = Get-Content $templatePath | Out-String | ConvertFrom-Json
    $resources = $templateObj.resources

    foreach ($resource in $resources) {
        $resourceTypes += $resource.type
    }

    return $resourceTypes
}

<#
    This files moves the parameter and template files to the staging directory so they can be publised later in the
    pipeline as build artifacts. It also re-names the template file to match the parameter file for easy matching by
    scripts and reviewers
#>
function Move-Templates($parameterPath, $templatePath) {

    Write-Host "Staging templates for deployment"

    # $paramFileName = $parameterPath.Split("/")[1]
    # $templateFileName = $paramFileName.Replace(".params", "")

    if (-not (Test-Path "stage")) {
        New-Item -Name "stage" -ItemType directory
    }
    
    Copy-Item $parameterPath -Destination "$currentPath\stage\$paramFileName"
    Write-host "Added param file to staging directory: $currentPath\stage\$paramFileName"
    Copy-Item $templatePath -Destination "$currentPath\stage\$templateFileName"
    Write-host "Added template file to staging directory: $currentPath\stage\$templateFileName"
}

# Terminate script if no deployment files
if (-not $DeploymentFiles) {
    Write-Host "No deployment files. Exiting."
    return
}

# This is a hastable of the file path for parameter / template pairs
$paramTemplatePaths = @{}

# install Pester and Az modules
Write-Host "Installing Pester from PSGallery"
Install-Module -Name Pester -Force -Scope CurrentUser -MinimumVersion 4.8.0
Write-Host "Pester imported."
$env:PSModulePath = "C:\Modules\az_1.0.0\Az\1.0.0;" + $env:PSModulePath
Write-Host "Installing Az module"
Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
Write-Host "Az module installed"

$files = $DeploymentFiles.Split(",")

foreach ($filePath in $files) {

    $templateFilePath = ""
    $paramsFilePath = ""

    if ($filePath -like "*params.json") {
        $paramsFilePath = $filePath.Replace("/", "\")
        $templateFilePath = "templates\" + $filePath.Replace("params.", "").Replace("parameters/","")

    }
    else {
        $templateFilePath = $filePath.Replace("/", "\")
        $paramsFilePath = "parameters\" + $filePath.Replace(".json", ".params.json").Replace("templates/","")
    }

    if (-not $paramTemplatePaths.ContainsKey($paramsFilePath)) {
        $paramTemplatePaths.Add($paramsFilePath, $templateFilePath)
    }
}

Write-Host "Deployments:"
Write-Host ($paramTemplatePaths | Out-String) -ForegroundColor Green

# Override for local debugging
# $env:TENANT_ID = ""
# $env:APP_ID = ""
# $env:APP_SECRET = ""
# $env:SUBSCRIPTION_ID = ""

# provided by Azure DevOps variables
Write-Host "Authenticating to AAD using: $env:APP_ID"
$securePassword = $env:APP_SECRET | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$env:APP_ID", $securePassword
Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $env:TENANT_ID -ErrorAction Stop
Set-AzContext -SubscriptionId  $env:SUBSCRIPTION_ID

# create tests directory
New-Item -Name "tests" -ItemType "directory"

# Iterate through parameter / template pairs and excute relevant Pester tests
foreach ($item in $paramTemplatePaths.GetEnumerator()) {

    $resourceTypes = Get-ResourceTypes(($item.value))
    $testFileName = "tests\" + ($item.value).Split("\")[1].Split(".")[0] + ".xml"
    $result = Invoke-Pester -Script @{Path=$testScriptPath;Parameters=@{ParamFileLocation=$item.Key;TemplateFileLocation=$item.Value}} -PassThru -TestName $resourceTypes -OutputFile $testFileName -OutputFormat NUnitXml
    
    # TODO: Selective action based on error type (warning, etc...). Send emails
    if ($result.failedCount -ne 0) { 
         Write-Error "Pester returned errors"
    }
    else {
        Move-Templates $item.Key $item.Value
    }
}
