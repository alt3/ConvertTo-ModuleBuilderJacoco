# ConvertTo-ModuleBuilderJacoco

PowerShell module for converting Pester produced Jacoco code coverage files to
[ModuleBuilder](https://github.com/PoshCode/ModuleBuilder)
compatible format. 

### Installation

```powershell
Install-Module -Name Alt3.ConvertTo-ModuleBuilderJacoco
```

### Usage

```powershell
ConvertTo-ModuleBuilderJacoco -ModulePath ModuleBuilderModule.psm1 -InFile PesterCoverageResults.xml -OutFile ConvertedCoverageResults.xml
```

### HTML reports

1. Install [danielpalme/ReportGenerator](https://github.com/danielpalme/ReportGenerator)
2. Run:

    ```powershell
    ReportGenerator.exe -reports:ConvertedCoverageResults.xml -targetdir:.\Dev\reports -reporttypes:'Latex;Html' -sourcedirs:path-to-your-module-source-files
    ```

3. Open `.\Dev\reports\index.html`

### Good to know

- Every covered ModuleBuilder source subfolder gets a correlating Jacoco `package` XML node
- Every covered ModuleBuilder source file gets a correlating `class`, `method` and `sourcefile` XML node
- Jacoco `counter` nodes are not recreated as they are not required for ReportGenerator, CodeCov, etc.
