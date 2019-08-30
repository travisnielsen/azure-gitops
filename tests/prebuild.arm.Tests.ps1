#Requires -Modules Pester
<#
.SYNOPSIS
    Validates ARM template structure and performs a test-mode deployment to a temporary resource group 
.EXAMPLE
    Invoke-Pester 
.NOTES
    This test file should support any tests that are applicable to any given ARM template regardless of resource type.
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
$location = $paramObj.parameters.location.value
$rgName = $paramObj.parameters.resourceGroup.value
$pesterRG = $rgName + "-Pester-Unit"

Describe "arm" -Tags Unit {

    BeforeAll {
        New-AzResourceGroup -Name $pesterRG -Location $location
    }

   Context "Template Validation" {

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
          
    }

    Context "Test deployment" {

        It "Template and parameter file deploys successfully" {
    
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