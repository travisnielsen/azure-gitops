<#
    Iterates through deployment files and launches Pester tasks
#>

Param ( [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]$RepoFolder,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]$DeploymentFiles
)

