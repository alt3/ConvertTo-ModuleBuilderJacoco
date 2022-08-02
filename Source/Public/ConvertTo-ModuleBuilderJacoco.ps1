function ConvertTo-ModuleBuilderJacoco {
    <#
        .SYNOPSIS
        Converts a Pester produced Jacoco code coverage file to ModuleBuilder compatible format.

        .PARAMETER InFile
        Path to a Pester produced Jacoco code coverage XML file.

        .PARAMETER Module
        Full path to the compiled module.

        .PARAMETER OutFile
        File name of newly generated Jacoco XML file.
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $InFile,

        [Parameter(Mandatory = $True)]
        [string]
        $ModulePath,

        [Parameter(Mandatory = $True)]
        [string]
        $OutFile
    )

    try {
        # make sure required files exist
        if (-not (Test-Path -Path $InFile)) {
            throw "Cannot load Pester produced Jacoco code coverage file '$($InFile)' because it does not exist"
        }

        if (-not (Test-Path -Path $ModulePath)) {
            throw "Cannot load module '$($ModulePath)' because it does not exist"
        }

        # make required files resolvable
        [System.IO.FileInfo]$ModulePath = Get-Item -Path $ModulePath
        [System.IO.FileInfo]$Infile = Get-Item -Path $InFile

        # get required data
        $sourceFiles = ExtractModuleSourceFiles -Path $ModulePath
        $coverageXml = ImportJacocoXml -Path $Infile
        $coverageLines = ExtractJacocoCoverageLines -Xml $coverageXml

        # get module info
        $moduleName = $coverageXml.report.package.class.name -replace '^.*?[\/|\\]'

        # ---------------------------------------------------------------------
        # Convert Jacoco code coverage lines to module sources
        # ---------------------------------------------------------------------
        Write-Verbose "Converting Jacoco line coverage"

        $coverageLines.GetEnumerator() | ForEach-Object {
            $coverageLine = $_

            $converted = Convert-LineNumber -SourceLineNumber $coverageLine.Name -SourceFile $ModulePath

            # skip regions that are not present in the module (like PREFIX)
            if (-not $sourceFiles.($converted.SourceFile)) {
                Write-Verbose "[!] skipping non-module REGION '$($converted.SourceFile)'"

                return
            }

            # create initial Coverage property if needed
            if (-not $sourceFiles.($converted.SourceFile).Coverage) {
                $sourceFiles.($converted.SourceFile).Coverage = [ordered]@{}
            }

            # add coverage property
            $sourceFiles.($converted.SourceFile).Coverage.($converted.SourceLineNumber) = [ordered]@{
                JacocoLineNumber    = $coverageLine.Value.LineNumber
                CoveredInstructions = $coverageLine.Value.CoveredInstructions
                MissedInstructions  = $coverageLine.Value.MissedInstructions
                CoveredBranches     = $coverageLine.Value.CoveredBranches
                MissedBranches      = $coverageLine.Value.MissedBranches
            }
        }

        # ---------------------------------------------------------------------
        # Generate new xml document
        # ---------------------------------------------------------------------
        $xml = NewXmlDocument

        # report
        $params = @{
            Path       = "/"
            Name       = "report"
            Attributes = [ordered]@{
                Name = $coverageXml.report.name
            }
        }
        $xml | XmlAddNode @params  -PassThru

        # sessioninfo
        $params = @{
            Path       = "/report"
            Name       = "sessioninfo"
            Attributes = [ordered]@{
                Id    = "this"
                Start = $coverageXml.report.sessioninfo.start
                Dump  = $coverageXml.report.sessioninfo.dump
            }
        }
        $xml | XmlAddNode @params  -PassThru

        # ---------------------------------------------------------------------
        # Create a `package` node for each source folder
        # ---------------------------------------------------------------------
        Write-Verbose "Creating a 'package' node for each module source folder"

        $coveredMethodsCounter = 0
        $missedMethodsCounter = 0

        $sourceFiles.Values.Folder | Get-Unique | ForEach-Object {
            $sourceFile = $_

            $params = @{
                Path       = "/report"
                Name       = "package"
                Attributes = [ordered]@{
                    Name = "$moduleName/$($sourceFile)"
                }
            }

            $xml | XmlAddNode @params  -PassThru
        }

        # ---------------------------------------------------------------------
        # For each source file create `class`, `method` and `sourcefile` nodes
        # ---------------------------------------------------------------------
        $sourceFiles.GetEnumerator() | ForEach-Object {
            $sourceFile = $_

            # get coverage counts
            $measureMethodCovered = $sourceFile | ForEach-Object {
                $_.Value.Coverage.GetEnumerator() | ForEach-Object {
                    $_.Value.CoveredInstructions | Where-Object { $_ -ne 0 }
                }
            } | Measure-Object -Sum

            # keep track of methods
            if ($measureMethodCovered.Sum -gt 0) {
                $coveredMethodsCounter++
            }
            else {
                $missedMethodsCounter++
            }

            # create root node `class`
            $params = @{
                Path       = "/report/package[@name='$moduleName/$($sourceFile.Value.Folder)']"
                Name       = "class"
                Attributes = [ordered]@{
                    Name           = $sourceFile.Value.File
                    SourceFileName = "$($sourceFile.Value.Folder)/$($sourceFile.Value.File)"
                }
            }

            $xml | XmlAddNode @params  -PassThru

            # create child node `method`
            $params = @{
                Path       = "/report/package[@name='$moduleName/$($sourceFile.Value.Folder)']/class[@name= '$($sourceFile.Value.File)']"
                Name       = "method"
                Attributes = [ordered]@{
                    Name = $sourceFile.Value.Command
                    Line = $sourceFile.Value.Coverage.Keys | Select-Object -First 1 # line is always first of Jacoco sourcefile-lines
                    Desc = ""
                }
            }

            $xml | XmlAddNode @params  -PassThru

            # create root node `sourcefile`
            $params = @{
                Path       = "/report/package[@name='$moduleName/$($sourceFile.Value.Folder)']"
                Name       = "sourcefile"
                Attributes = [ordered]@{
                    Name = "$($sourceFile.Value.Folder)/$($sourceFile.Value.File)"
                }
            }

            $xml | XmlAddNode @params  -PassThru

            # fill `sourcefile` with `line` nodes, one for each Jacoco coverage line
            $sourceFile.Value.Coverage.GetEnumerator()  | ForEach-Object {
                $line = $_
                $params = @{
                    Path       = "/report/package[@name='$moduleName/$($sourceFile.Value.Folder)']/sourcefile[@name='$($sourceFile.Value.Folder)/$($sourceFile.Value.File)']"
                    Name       = "line"
                    Attributes = [ordered]@{
                        Nr = $line.Key
                        Ci = $line.Value.CoveredInstructions
                        Mi = $line.Value.MissedInstructions
                        Cb = $line.Value.CoveredBranches
                        Mb = $line.Value.MissedBranches
                    }
                }

                $xml | XmlAddNode @params  -PassThru
            }
        }

        # Save the new xml document
        $OutFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)

        $xml.Save($OutFile)
    }
    catch {
        $_
    }

}
