function ExtractModuleSourceFiles() {
    <#
        .SYNOPSIS
        Extracts all source files (functions) from the compiled module including their file length.

        .PARAMETER Path
        Path to the ModuleBuilder compiled module.

        .LINK
        https://regex101.com/r/aV49mC/1

        .OUTPUTS
        Hashtable
    #>
    param(
        [Parameter(Mandatory = $True)]
        [System.IO.FileInfo]
        $Path
    )

    Write-Verbose "Extracting source files from ModuleBuilder compiled module"

    # parse module file line-by-line
    $regions = @{}

    Get-Content -Path $Path | ForEach-Object {
        if ($_ -match "^#EndRegion.+\'(\.\\(.+)\\(.+))'\s(\d+|\d)$") {
            # see .LINK
            $sourceFile = $matches[1]

            if (-not $regions.$sourceFile) {
                $regions.$sourceFile = [ordered]@{
                    Folder     = $matches[2]
                    File       = $matches[3]
                    Command    = [io.path]::GetFileNameWithoutExtension($matches[3])
                    FileLength = $matches[4]
                }
            }
        }
    }

    # return sorted hashtable
    $result = [ordered]@{}

    $regions.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
        $result.($_.Key) = $_.Value
    }

    $result
}
