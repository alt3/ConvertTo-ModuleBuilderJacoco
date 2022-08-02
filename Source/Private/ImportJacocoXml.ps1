function ImportJacocoXml() {
    <#
        .SYNOPSIS
        Imports Jacoco XML

        .PARAMETER Path
        Path to the Pester produced Jacoco code coverage file.

        .OUTPUTS
        System.Xml.XmlDocument
    #>
    param(
        [Parameter(Mandatory = $True)]
        [System.IO.FileInfo]
        $Path
    )

    Write-Verbose "Importing Pester produced Jacoco code coverage file"

    $xml = New-Object -TypeName 'System.Xml.XmlDocument'
    $xml.XmlResolver = $null
    $xml.Load($Path)

    return $xml
}
