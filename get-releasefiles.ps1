# =============================
# INLINE SCRIPT
# =============================

Set-Location "$(rootFolder)"

$ctx = New-AzureStorageContext -StorageAccountName "$(storageAcctName)" -StorageAccountKey $env:storageKey
$files = Get-AzureStorageBlob -prefix "$(Release.ReleaseId)" -Container "$(storageContainerName)" -Context $ctx
foreach ( $file in $files ){
    $fileName = $file.Name
    Write-Host "Downloading: $fileName"
    Get-AzureStorageBlobContent -Blob $fileName -Container "$(storageContainerName)" -Context $ctx
}

Set-Location "$(Release.ReleaseId)"
ls
