Set-Location "$(rootFolder)"
$deploymentFiles = ""
$editedFiles = @( git diff HEAD HEAD~ --name-only )
Write-Host "Edited files:"
Write-Host $editedFiles

$editedFilesFiltered = $editedFiles -match "parameters/*|templates/*"

foreach ($file in $editedFilesFiltered) {

    Write-Host "Filtered file: $file"

    # check if file exists in the directory (filter out deletions)
    $exists = Test-Path $file -PathType Leaf

    if ($exists) {
        Write-Host "Identified update file: $file"
        $deploymentFiles += $file
        $deploymentFiles += ","
    } else {
        Write-Host "Deleted file: $file"
    }
}

$deploymentFiles = $deploymentFiles.TrimEnd(",")
Write-Host "Deployment files: $deploymentFiles" 
Write-Output "##vso[task.setvariable variable=deploymentFiles]${deploymentFiles}"
