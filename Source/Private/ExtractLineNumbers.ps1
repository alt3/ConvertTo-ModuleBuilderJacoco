function ExtractLineNumbers() {
    <#
        .SYNOPSIS
        Extracts all line numbers from from the Jacoco XML.

        .NOTES
        Uses a three-step process:

        1. Gets all lines inside the `class` branch
        2. Gets all lines inside the ``sourcefile` branch
        3. Returns only unique lines

        .OUTPUTS
        System.Collections.ArrayList
    #>
    param(
        [Parameter(Mandatory = $True)]
        [System.Xml.XmlDocument]
        $Xml
    )

    Write-Verbose "Extracting line numbers"

    $result = [System.Collections.ArrayList]::new()

    $xml.report.package.class.ChildNodes | ForEach-Object {
        $result.Add([int]$_.line) | Out-Null
    }

    $xml.report.package.sourcefile.line | ForEach-Object {
        $result.Add([int]$_.nr) | Out-Null
    }

    # return unique lines only
    $result | Sort-Object | Select-Object -Unique
}
