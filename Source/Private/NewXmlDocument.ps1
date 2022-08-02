function NewXmlDocument() {
    <#
        .SYNOPSIS
        Returns an xml document with declaration and Jacoco document type.

        .LINK
        https://www.jacoco.org/jacoco/trunk/coverage/report.dtd

        .OUTPUTS
        System.Xml.XmlDocument
    #>
    param()

    Write-Verbose "Creating new Jacoco XML skeleton"

    $xml = New-Object -TypeName 'System.Xml.XmlDocument'
    $xml.XmlResolver = $null

    # xml declaration
    $declaration = $xml.CreateXmlDeclaration("1.0", "UTF-8", "no")
    $xml.AppendChild($declaration) | Out-Null

    # document type
    $documentType = $xml.CreateDocumentType(
        "report",
        "-//JACOCO//DTD Report 1.1//EN", # public identifier
        "report.dtd", # system identifier
        $null
    )

    $xml.AppendChild($documentType) | Out-Null

    return $xml
}


