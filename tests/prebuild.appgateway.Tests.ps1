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
# $paramsFilePath = $rootDir + "\" + $ParamFileLocation
# $paramObj = Get-Content $paramsFilePath | Out-String | ConvertFrom-Json

Describe "Microsoft.Network/applicationGateways" -Tags Unit {

    Context "Template Syntax" {
        
        It "Application Gateway template creates the expected Azure resources" {
            $expectedResources = 'Microsoft.Network/publicIPAddresses',
            'Microsoft.Network/applicationGateways' | Sort-Object 

            $templateResources = (get-content "$templateFilePath" | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
            $templateResources | Sort-Object | Should Be $expectedResources 
        }

    }
    

}