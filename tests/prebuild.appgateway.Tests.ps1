#Requires -Modules Pester
<#
.SYNOPSIS
    ARM template validation for Application Gateways
.EXAMPLE
    Invoke-Pester 
.NOTES
    
#>

Param(
	[string][Parameter(Mandatory=$true)] $ParamFileLocation,
	[string][Parameter(Mandatory=$true)] $TemplateFileLocation	
)

# Set file locations and variables
$rootDir = $MyInvocation.MyCommand.Path | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
$templateFilePath = $rootDir + "\" + $TemplateFileLocation
$paramsFilePath = $rootDir + "\" + $ParamFileLocation
$paramObj = Get-Content $paramsFilePath | Out-String | ConvertFrom-Json
$Location = $paramObj.parameters.location.value
$ResourceGroupName = $paramObj.parameters.resourceGroup.value
$pesterRG = $ResourceGroupName + "-Pester-Unit"

Describe "Microsoft.Network/applicationGateways" -Tags Unit {
     BeforeAll {
         New-AzResourceGroup -Name $pesterRG -Location $Location
    }

    Context "Template Syntax" {
        
        It "Has a JSON template" {        
            "$templateFilePath" | Should Exist
        }
        
        It "Has a parameters file" {        
            "$paramsFilePath" | Should Exist
        }
        
        It "Converts from JSON and has the expected properties" {
            $expectedProperties = '$schema',
            'contentVersion',
            'parameters',
            'variables',
            'resources' | Sort-Object 
            $templateProperties = (get-content "$templateFilePath" | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Sort-Object | Should Be $expectedProperties
        }
        
        It "Application Gateway template creates the expected Azure resources" {
            $expectedResources = 'Microsoft.Network/publicIPAddresses',
            'Microsoft.Network/applicationGateways' | Sort-Object 

            $templateResources = (get-content "$templateFilePath" | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $templateResources | Sort-Object | Should Be $expectedResources 
        }

    }
    
    Context "Template Validation" {
          
        It "Template and parameter file passes deployment validation" {
      
            # Complete mode - will deploy everything in the template from scratch. If the resource group already contains things (or even items that are not in the template) they will be deleted first.
            # If it passes validation no output is returned, hence we test for NullOrEmpty
            $ValidationResult = Test-AzResourceGroupDeployment -ResourceGroupName $pesterRG -Mode Complete -TemplateFile "$templateFilePath" -TemplateParameterFile "$paramsFilePath" -resourceGroupFromTemplate $pesterRG
            $ValidationResult | Should BeNullOrEmpty
        }
    }

     AfterAll {
         Remove-AzResourceGroup $pesterRG -Force
     }
}