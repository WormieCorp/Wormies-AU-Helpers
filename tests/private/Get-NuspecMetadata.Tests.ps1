Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe "Parsing" {
    Context "Nuspec Parsing" {
        It "Should return metadata when nuspec file is valid" {
            $data = Get-NuspecMetadata -nuspecFile "$PSScriptRoot\ValidNuspec.nuspec"
            $data.id | Should Be "ValidNuspec"
            $data.version | Should Be "1.0.3"
        }

        It "Should resolve the correct nuspec file when using globbing pattern" {
            $data = Get-NuspecMetadata -nuspecFile "$PSScriptRoot\*.nuspec"
            $data.id | Should Be "ValidNuspec"
            $data.version | Should Be "1.0.3"
        }
    }
}
