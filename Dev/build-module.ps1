<#
    .SYNOPSIS
    Use this script to rebuild and test the Alt3 module after making code changes.

    .NOTES
    Newly compiled module and Pester results will be created in the `Output` folder.

    .PARAMETER Test
    Runs Pester tests against a freshly built Alt3-module.

    .PARAMETER Path
    Limit Pester tests by specifiying path to specific test(s).

    .PARAMETER Coverage
    Runs Pester code coverage.
#>
[cmdletbinding()]
param(
    [Parameter()]
    [switch]
    $Test,

    [Parameter(Mandatory = $False)]
    [string]
    $Path = ".",

    [Parameter(Mandatory = $False)]
    [ValidateSet("Diagnostic", "Detailed", "Normal", "Minimal", "None")]
    [string]
    $Output = "Normal",

    [Parameter()]
    [switch]
    $Coverage,

    [Parameter()]
    [switch]
    $GenerateDocs,

    [Parameter()]
    [switch]
    $PassThru
)

# Make this work from all locations
Push-Location (Get-Item -Path $PSScriptRoot).Parent

# Build new Alt3 module
Write-Output "Building new module"
Build-Module -SourcePath .\Source -VersionedOutputDirectory

# Prevent duplicate module versions breaking PlatyPS
Remove-Module Alt3.ConvertTo-ModuleBuilderJacoco -Force -ErrorAction SilentlyContinue

# Determine latest module version
$outputFolder = ".\Output\Alt3.ConvertTo-ModuleBuilderJacoco"
$latestModuleVersion = (Get-ChildItem -Path $outputFolder -Directory | Sort-Object CreationTime | Select-Object -Last 1).Name
Write-Output "Importing new module $latestModuleVersion"

$latestManifestPath = Join-Path -Path $outputFolder -ChildPath $latestModuleVersion | Join-Path -ChildPath Alt3.ConvertTo-ModuleBuilderJacoco.psd1
$latestModulePath = Join-Path -Path $outputFolder -ChildPath $latestModuleVersion | Join-Path -ChildPath Alt3.ConvertTo-ModuleBuilderJacoco.psm1

# Import latest module version
Import-Module $latestManifestPath -Force -Global
Get-Module Alt3.ConvertTo-ModuleBuilderJacoco

# Pester tests and code coverage
if ($Test) {
    if (-not(Get-Module Pester)) {
        throw "Required module 'Pester' is not loaded. Run 'Import-Module -Name Pester' first."
    }

    $configuration = [PesterConfiguration]::Default

    $configuration.Run.Path = $Path
    $configuration.Output.Verbosity = $Output
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputPath = Join-Path -Path "Output" -ChildPath "Pester" | Join-Path -ChildPath "TestResults.xml"
    $configuration.TestResult.OutputFormat = "NUnitXml"

    if ($Coverage) {
        $configuration.CodeCoverage.Enabled = $true
        $configuration.CodeCoverage.Path = $latestModulePath
        $configuration.CodeCoverage.UseBreakpoints = $false # use new and faster profiler-based coverage
        $configuration.CodeCoverage.OutputPath = Join-Path -Path "Output" -ChildPath "Pester" | Join-Path -ChildPath "CodeCoverageResults.xml"
        $configuration.CodeCoverage.OutputFormat = 'JaCoCo'

        $configuration.CodeCoverage.CoveragePercentTarget = 80 # minimum threshold needed to pass
    }

    if ($PassThru) {
        $configuration.Run.PassThru = $true
    }

    Invoke-Pester -Configuration $configuration

    Write-Output "Test files created in $(Join-Path -Path "Output" -ChildPath "Pester")"
}

Pop-Location
