[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $CmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\Office365.psm1" `
            -Resolve)
)
$GenericStubPath = (Join-Path -Path $PSScriptRoot `
    -ChildPath "..\Stubs\Generic.psm1" `
    -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-O365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "EXOHostedConnectionFilterPolicy" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope
        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)
        Mock -CommandName Close-SessionsAndReturnError -MockWith {

        }

        Mock -CommandName Test-MSCloudLogin -MockWith {

        }

        Mock -CommandName Get-PSSession -MockWith {

        }

        Mock -CommandName Remove-PSSession -MockWith {

        }

        Mock -CommandName New-HostedConnectionFilterPolicy -MockWith {

        }

        Mock -CommandName Set-HostedConnectionFilterPolicy -MockWith {

        }

        Mock -CommandName Remove-HostedConnectionFilterPolicy -MockWith {

        }

        # Test contexts
        Context -Name "HostedConnectionFilterPolicy creation." -Fixture {
            $testParams = @{
                Ensure             = 'Present'
                Identity           = 'TestPolicy'
                GlobalAdminAccount = $GlobalAdminAccount
                AdminDisplayName   = 'This policiy is a test'
                EnableSafeList     = $true
                IPAllowList        = @('192.168.1.100', '10.1.1.0/24', '172.16.5.1-172.16.5.150')
                IPBlockList        = @('10.1.1.13', '172.16.5.2')
                MakeDefault        = $false
            }

            Mock -CommandName Get-HostedConnectionFilterPolicy -MockWith {
                return @{
                    Identity = 'SomeOtherPolicy'
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "HostedConnectionFilterPolicy update not required." -Fixture {
            $testParams = @{
                Ensure             = 'Present'
                Identity           = 'TestPolicy'
                GlobalAdminAccount = $GlobalAdminAccount
                AdminDisplayName   = 'This policiy is a test'
                EnableSafeList     = $true
                IPAllowList        = @('192.168.1.100', '10.1.1.0/24', '172.16.5.1-172.16.5.150')
                IPBlockList        = @('10.1.1.13', '172.16.5.2')
                MakeDefault        = $false
            }

            Mock -CommandName Get-HostedConnectionFilterPolicy -MockWith {
                return @{
                    Ensure             = 'Present'
                    Identity           = 'TestPolicy'
                    GlobalAdminAccount = $GlobalAdminAccount
                    AdminDisplayName   = 'This policiy is a test'
                    EnableSafeList     = $true
                    IPAllowList        = @('192.168.1.100', '10.1.1.0/24', '172.16.5.1-172.16.5.150')
                    IPBlockList        = @('10.1.1.13', '172.16.5.2')
                    MakeDefault        = $false
                }
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "HostedConnectionFilterPolicy update needed." -Fixture {
            $testParams = @{
                Ensure             = 'Present'
                Identity           = 'TestPolicy'
                GlobalAdminAccount = $GlobalAdminAccount
                AdminDisplayName   = 'This policiy is a test'
                EnableSafeList     = $true
                IPAllowList        = @('192.168.1.100', '10.1.1.0/24', '172.16.5.1-172.16.5.150')
                IPBlockList        = @('10.1.1.13', '172.16.5.2')
                MakeDefault        = $false
            }

            Mock -CommandName Get-HostedConnectionFilterPolicy -MockWith {
                return @{
                    Ensure             = 'Present'
                    Identity           = 'TestPolicy'
                    GlobalAdminAccount = $GlobalAdminAccount
                    AdminDisplayName   = 'This different description'
                    EnableSafeList     = $false
                    IPAllowList        = @('192.168.1.100')
                    IPBlockList        = @('10.1.1.13')
                    MakeDefault        = $false
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "HostedConnectionFilterPolicy removal." -Fixture {
            $testParams = @{
                Ensure             = 'Absent'
                Identity           = 'TestPolicy'
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-HostedConnectionFilterPolicy -MockWith {
                return @{
                    Identity = 'TestPolicy'
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                GlobalAdminAccount = $GlobalAdminAccount
            }

            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
