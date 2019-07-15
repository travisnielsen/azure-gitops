#Requires -Modules Pester
<#
.SYNOPSIS
    ARM template validation of Microsoft.Network/publicIPAddresses resources
.EXAMPLE
    Invoke-Pester 
.NOTES
    This resource type is an Azure primitive (i.e part of a larger resource type) and does not include deployment testing
#>

Param(
	[string][Parameter(Mandatory=$true)] $ParamFileLocation,
	[string][Parameter(Mandatory=$true)] $TemplateFileLocation	
)

# Set file locations and variables
$rootDir = $MyInvocation.MyCommand.Path | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
$templateFilePath = $rootDir + "\" + $TemplateFileLocation

$templateData = (get-content "$templateFilePath" | ConvertFrom-Json -ErrorAction SilentlyContinue)
$resource = $templateData.resources | Where-Object {$_.type -eq "Microsoft.Logic/workflows"} | Select-Object

Describe "Microsoft.Logic/workflows" -Tags Unit {
    Context "Basic test" {
        It "Uses the correct ARM API version" {
            $expectedValue = "2016-06-01"
            $templateProperty = $resource.apiVersion.ToLower()
            $templateProperty | Should Be $expectedValue
        }
    }
}

$resource = $templateData.resources | Where-Object {$_.type -eq "Microsoft.Web/connections"} | Select-Object

Describe "Microsoft.Web/connections" -Tags Unit {
    Context "Basic test" {
        It "Uses the correct ARM API version" {
            $expectedValue = "2016-06-01"
            $templateProperty = $resource.apiVersion.ToLower()
            $templateProperty | Should Be $expectedValue
        }
    }
}