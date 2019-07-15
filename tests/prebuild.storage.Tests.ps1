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
$paramsFilePath = $rootDir + "\" + $ParamFileLocation

$templateData = (get-content "$templateFilePath" | ConvertFrom-Json -ErrorAction SilentlyContinue)
$resource = $templateData.resources | Where-Object {$_.type -eq "Microsoft.Storage/storageAccounts"} | Select-Object

$paramsData = (get-content "$paramsFilePath" | ConvertFrom-Json -ErrorAction SilentlyContinue)

Describe "Microsoft.Storage/storageAccounts" -Tags Unit {

    Context "Network settings" {
        
        It "Supports HTTPS traffic only" {
            $expectedValue = $true
            $templateProperty = $resource.properties.supportsHttpsTrafficOnly
            $templateProperty | Should Be $expectedValue
        }

        It "Defaults network access to Deny" {
            $expectedValue = 'deny'
            $templateProperty = $resource.properties.networkAcls.defaultAction.ToLower()
            $templateProperty | Should Be $expectedValue
        }

    }

    Context "Datalake settings" {

        It "Sets valid access control for data classification" {
        
            # TODO: Enumerate access control object and check POSIX ACLs are valid for data classification
            Set-ItResult -Skipped -Because 'Not implemented'

        }

    }
}