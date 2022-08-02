function XmlAddNode() {
    <#
        .SYNOPSIS
        Adds a node to the given XML document

        .OUTPUTS
        System.Xml.XmlDocument
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [String]
        $Path,

        [Parameter(Mandatory = $True)]
        [String]
        $Name,

        [Parameter(Mandatory = $False)]
        [System.Collections.Specialized.OrderedDictionary]
        $Attributes,

        [Parameter(ValueFromPipeline, DontShow)]
        [psobject]
        $InputObject,

        # If set, updates and returns the passed InputObject
        [Parameter()]
        [switch]
        $Passthru
    )

    if (-not $Passthru) {
        throw "Using -Passthru is required"
    }

    Write-Verbose "XML: Creating node '$Name' in path '$Path'"

    $parent = $InputObject.selectSingleNode($Path)

    $new = $InputObject.CreateElement($Name)

    if ($Attributes) {
        $Attributes.GetEnumerator() | ForEach-Object {
            Write-Verbose "XML: With attribute '$($_.Name.ToLower())' set to '$($_.Value)'"

            $new.SetAttribute($_.Name.ToLower(), $_.Value) | Out-Null
        }
    }

    $parent.AppendChild($new) | Out-Null
}
