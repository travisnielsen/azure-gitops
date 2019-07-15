#Requires -Modules Pester
<#
.SYNOPSIS
    ARM template validation of Microsoft.Network/networkSecurityGroups resources
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
$resource = $templateData.resources | Where-Object {$_.type -eq "Microsoft.Network/networkSecurityGroups"} | Select-Object

Describe "Microsoft.Network/networkSecurityGroups" -Tags Unit {

    Context "General settings" {
        
        It "Is the correct API version" {
            $expectedValue = '2018-02-01'
            $templateProperty = $resource.apiVersion.ToLower()
            $templateProperty | Should Be $expectedValue
        }
    }

}