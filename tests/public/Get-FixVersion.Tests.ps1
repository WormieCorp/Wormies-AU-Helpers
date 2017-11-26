Remove-Module wormies-au-helpers -ea ignore
Import-Module "$PSScriptRoot/../../Wormies-AU-Helpers"

Describe 'Get-FixVersion' {
    Mock "Resolve-Path" { return "$PSScriptRoot\test.nuspec" }
    $nuspecFile = "$PSScriptRoot/../private/ValidNuspec.nuspec"
    It "Should return same version when no padding is needed" {
        $global:au_Force = $false
        $nuspecFile = "$PSScriptRoot/../private/ValidNuspec.nuspec"

        Get-FixVersion -Version '0.1' -NuspecFile $nuspecFile | Should Be '0.1'
        Get-FixVersion -Version "1.0.3" -NuspecFile $nuspecFile | Should Be "1.0.3"
    }

    It "Should return same version when onlyFixBelowVersionIsLower" {
        $global:au_Force = $true
        $nuspecFile = "$PSScriptRoot/../private/ValidNuspec.nuspec"

        Get-FixVersion -Version '0.2.3.6' -OnlyFixBelowVersion '0.2.2' -NuspecFile $nuspecFile | Should Be '0.2.3.6'
        Get-FixVersion -Version "0.3.2-pre" -OnlyFixBelowVersion "0.3.1" -NuspecFile $nuspecFile | Should Be "0.3.2-pre"
        Get-FixVersion -Version "0.3.2" -OnlyFixBelowVersion "0.3.2-rc100" -NuspecFile $nuspecFile | Should Be "0.3.2"
        Get-FixVersion -Version "1.0.3-beta2" -OnlyFixBelowVersion "1.0.3-alpha100" -NuspecFile $nuspecFile | Should Be "1.0.3-beta2"
    }

    It "Throws exception when the passed version is invalid" {
        { Get-FixVersion -Version '0' } | Should Throw
        { Get-FixVersion -Version '0.5.23.2.1' } | Should Throw
        { Get-FixVersion -Version '0.54-preview-beta-ueaj' } | Should Throw
    }

    It "Should append padding when force is used" {
        $global:au_Force = $true
        $nuspecFile = "$PSScriptRoot/../private/ValidNuspec.nuspec"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.1" } } -Verifiable -ModuleName "Wormies-AU-Helpers"

        Get-FixVersion -Version "0.5.3.1" -NuspecFile $nuspecFile | Should Be "0.5.3.101"
        Assert-MockCalled -CommandName Get-NuspecMetadata -ModuleName "Wormies-AU-Helpers"
    }

    It "Returns same version when nuspec file is equal to passed version and au_Force is $false" {
        $global:au_Force = $false
        $nuspecFile = "$PSScriptRoot/../private/ValidNuspec.nuspec"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.1" } } -Verifiable -ModuleName "Wormies-AU-Helpers"

        Get-FixVersion -Version "0.5.3.1" -NuspecFile $nuspecFile | Should Be "0.5.3.1"
        Assert-MockCalled -CommandName Get-NuspecMetadata -ModuleName "Wormies-AU-Helpers"
    }

    It "Returns fix for pre-releases" {
        $global:au_Force = $true
        $nuspecFile = "$PSScriptRoot/../private/ValidNuspec.nuspec"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.3-beta" } } -Verifiable -ModuleName "Wormies-AU-Helpers"
        $currentDate = Get-Date -UFormat "{0:yyyyMMdd}"

        Get-FixVersion -Version "0.3-beta" -NuspecFile $nuspecFile | Should Be ("0.3-beta-" + $currentDate)
        Assert-MockCalled -CommandName Get-NuspecMetadata -ModuleName "Wormies-AU-Helpers"
    }

    It "Returns padded version but no fix if version is higher than previous" {
        $global:au_Force = $false
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.1.0" } } -Verifiable -ModuleName "Wormies-AU-Helpers"

        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.200"
    }

    It "Returns padded version when one is used in nuspec file, and no force is used" {
        $global:au_Force = $false

        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.200" } } -ModuleName "Wormies-AU-Helpers"
        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.200"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.201" } } -ModuleName "Wormies-AU-Helpers"
        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.201"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.202" } } -ModuleName "Wormies-AU-Helpers"
        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.202"
    }

    It "Returns padded fix version when one is used in the nuspec file, and force is used" {
        $global:au_Force = $true

        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.200" } } -ModuleName "Wormies-AU-Helpers"
        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.201"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.201" } } -ModuleName "Wormies-AU-Helpers"
        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.202"
        Mock Get-NuspecMetadata { return @{ id = "myid"; version = "0.5.3.202" } } -ModuleName "Wormies-AU-Helpers"
        Get-FixVersion -Version 0.5.3.2 -NuspecFile $nuspecFile | Should Be "0.5.3.203"
    }
}
