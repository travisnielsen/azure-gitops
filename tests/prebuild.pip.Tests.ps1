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
$resource = $templateData.resources | Where-Object {$_.type -eq "Microsoft.Network/publicIPAddresses"} | Select-Object

Describe "Microsoft.Network/publicIPAddresses" -Tags Unit {

    Context "IP settings" {
        
        It "Has static IP allocation configured" {
            $expectedValue = 'static'
            $templateProperty = $resource.properties.publicIPAllocationMethod.ToLower()
            $templateProperty | Should Be $expectedValue
        }

        It "IP is a standard SKU" {
            $expectedValue = 'standard'
            $templateProperty = $resource.sku.name.ToLower()
            $templateProperty | Should Be $expectedValue
        }
        
    }

}