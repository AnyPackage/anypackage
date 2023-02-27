﻿#requires -modules AnyPackage

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Does not work with Pester scopes.')]
param()

Describe Find-Package {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath PowerShellProvider)
    }

    Context 'with no additional parameters' {
        It 'should return results' {
            Find-Package |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -Name parameter' {
        BeforeDiscovery {
            $names = @('Apple', 'Banana', @('Apple', 'Banana'), 'A*')
        }

        It 'should return <_> package' -ForEach $names {
            Find-Package -Name $_ |
            Should -Not -BeNullOrEmpty
        }

        It 'should fail with <_> non-existent package' -ForEach 'broke' {
            { Find-Package -Name $_ -ErrorAction Stop } |
            Should -Throw -ExpectedMessage "Package not found. (Package '$_')"
        }
    }

    Context 'with -Version parameter' {
        BeforeDiscovery {
            $versions = @(
                '1.0',
                '1.0',
                '[1.0,]',
                '(1.0,)',
                '(,2.0)',
                '(1.0,2.0]',
                '(1.0,2.0)',
                '[1.0,2.0)'
            )
        }

        It 'should return packages for <_> version range' -ForEach $versions {
            Find-Package -Version $_ |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with -Source parameter' {
        BeforeAll {
            $path = Join-Path -Path TestDrive: -ChildPath repo
            New-Item -Path $path -ItemType Directory
            $provider = Get-PackageProvider
            $provider.Sources.Add([PSCustomObject]@{ Name = 'Test'; Location = $path; Trusted = $true })
            Copy-Item -Path $PSScriptRoot/packages/* -Destination $path
        }

        AfterAll {
            if ($provider.Sources.Count -gt 1) {
                $provider.Sources.RemoveAt($provider.Sources.Count - 1)
            }
        }

        It 'should return <_> source packages' -ForEach 'Test' {
            $results = Find-Package -Source $_

            $results.Source |
            Select-Object -ExpandProperty Name -Unique |
            Should -Be $_
        }
    }

    Context 'with -Prerelease parameter' {
        It 'should return prerelease versions' {
            Find-Package -Prerelease |
            Where-Object { $_.Version.IsPrerelease } |
            Should -Not -BeNullOrEmpty
        }
    }

    Context 'with pipeline input' {
        It 'should return packages for <_>' -ForEach 'Apple', 'Banana', 'A*' {
            $_ |
            Find-Package |
            Should -Not -BeNullOrEmpty
        }
    }
}
