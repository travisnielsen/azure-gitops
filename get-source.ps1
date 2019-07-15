# Download automation scripts
$url = "https://github.com/travisnielsen/azure-gitops"

# For internal ADO repositories that require access control
# $url = "https://$env:SYSTEM_ACCESSTOKEN@$url"

Write-Host "Fetching from $url"

# Need to use silent mode for git. Otherwise, the command will fail
# See: https://github.com/Microsoft/azure-pipelines-image-generation/issues/740
git clone -q $url

# Move invoke-pester script to root
Move-Item -Path "azure-gitops\\invoke-pester.prebuild.ps1" -Destination "."
ls
