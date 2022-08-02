function ExtractJacocoCoverageLines() {
    <#
        .SYNOPSIS
        Extracts all code coverage line numbers from from the Jacoco XML.

        .NOTES
        As found inside the Jacoco XML branch `report.package.sourcefile`

        .OUTPUTS
        System.Collections.ArrayList
    #>
    param(
        [Parameter(Mandatory = $True)]
        [System.Xml.XmlDocument]
        $Xml
    )

    Write-Verbose "Extracting Jacoco line coverage"

    $result = [ordered]@{}

    $xml.report.package.sourcefile.line | ForEach-Object {
        $result.($_.nr) = @{
            LineNumber          = $_.nr # required KeyName so we can use Convert-LineNumber
            CoveredInstructions = $_.ci
            MissedInstructions  = $_.mi
            CoveredBranches     = $_.cb
            MissedBranches      = $_.mb
        }
    }

    $result
}
