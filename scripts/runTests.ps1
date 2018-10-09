param([Boolean]$outputTestResultAsJunit=$false)

$rootPath = Get-Location
$extensionDirectory = Join-Path -Path $rootPath -ChildPath "azure-dev-cli-extensions"

Set-Location $extensionDirectory
Write-Host "installing azure dev cli extension"
pip install --upgrade .
Write-Host "done"
Write-Host "creating wheel"
python setup.py bdist_wheel
Write-Host "done"
Set-Location $rootPath

$ErrorActionPreference = "Continue"
try {
    Write-Host "trying to uninstall extension of az dev extension was installed"
    $uninstallCommand = "az extension remove -n azure-dev-cli-extensions **2>&1 | Write-Host**"
    Invoke-Expression $uninstallCommand
    Write-Host "extension was installed and it was removed"
}
catch {
    Write-Host "extension was not installed"
}

$ErrorActionPreference = "Stop"

Write-Host "installing azure dev cli extension"
$extensions = Get-ChildItem -Path $sourceDir -Filter "*.whl" -Recurse | Select-Object FullName
az extension add --source $extensions[0].FullName -y
Write-Host "done"

pip uninstall msrest -y
pip install msrest==0.5.5

az -h
az dev -h

$testFiles = @()

$testDirectory = Join-Path -Path $rootPath -ChildPath "tests"
$reposPrTest = Join-Path -Path $testDirectory -ChildPath "reposPrTest.py"
$testFiles +=  $reposPrTest

$reposTests = Join-Path -Path $testDirectory -ChildPath "reposRepoTest.py"
$testFiles += $reposTests

$boardsTests = Join-Path -Path $testDirectory -ChildPath "boardsWorkItemTest.py"
$testFiles +=  $boardsTests

$testFailureFound = $false

foreach($testFile in $testFiles){
    if($outputTestResultAsJunit -eq $true)
    {
        $leafFile = Split-Path $testFile -leaf
        $testResultFile = "TEST-" + $leafFile + ".xml"
        Write-Host "test result output at " $testResultFile
        pytest $testFile --junitxml $testResultFile
    }
    else{
        pytest $testFile
    }

    if ($LastExitCode -ne 0) {
        $testFailureFound = $true
      }
}

if($testFailureFound -eq $true){
    exit 1
}