# -----------------------------------------------------------------------------
# ModuleBuilder configuration file. Use this file to override the default
# parameter values used by the `Build-Module` command when building the module.
#
# For a full list of supported arguments run `Get-Help Build-Module -Full`.
# -----------------------------------------------------------------------------

@{
    Path = "Alt3.ConvertTo-ModuleBuilderJacoco.psd1"
    VersionedOutputDirectory = $true
    CopyDirectories = @(
        'en-US'
    )
}
