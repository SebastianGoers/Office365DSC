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
    -DscResource "SPOHubSite" -GenericStubModule $GenericStubPath

Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock -CommandName Test-MSCloudLogin -MockWith { }
        Mock -CommandName New-Office365DSCLogEntry -MockWith {}

        # Test contexts
        Context -Name "When the site doesn't already exist" -Fixture {
            $testParams = @{
                Url                  = "https://contoso.sharepoint.com/sites/Marketing"
                Title                = "Marketing Hub"
                Description          = "Hub for the Marketing division"
                LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                RequiresJoinApproval = $true
                AllowedToJoin        = @("admin@contoso.onmicrosoft.com", "superuser@contoso.onmicrosoft.com")
                SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                GlobalAdminAccount   = $GlobalAdminAccount
                Ensure               = "Present"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                throw
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw error in the Set method" {
                { Set-TargetResource @testParams } | Should throw "The specified Site Collection {$($testParams.Url)} for SPOHubSite doesn't already exist."
            }
        }

        Context -Name "When the site isn't a hub site and shouldn't" -Fixture {
            $testParams = @{
                Url                = "https://contoso.sharepoint.com/sites/Marketing"
                GlobalAdminAccount = $GlobalAdminAccount
                Ensure             = "Absent"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    IsHubSite = $false
                }
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true from the Test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When the site is a hub site and shouldn't" -Fixture {
            $testParams = @{
                Url                = "https://contoso.sharepoint.com/sites/Marketing"
                GlobalAdminAccount = $GlobalAdminAccount
                Ensure             = "Absent"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    IsHubSite = $true
                }
            }

            Mock -CommandName Get-SPOHubSite -MockWith {
                $returnVal = @{
                    Permissions          = @(
                        @{
                            PrincipalName = "i:0#.f|membership|admin@contoso.onmicrosoft.com"
                        },
                        @{
                            PrincipalName = "c:0o.c|federateddirectoryclaimprovider|bfc75218-faac-4202-bf33-3a8ba2e2b4a7"
                        }
                    )
                    LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                    Title                = "Marketing Hub"
                    Description          = "Hub for the Marketing division"
                    RequiresJoinApproval = $true
                    SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                }
                return $returnVal
            }

            Mock -CommandName Get-MsolGroup -MockWith {
                return @(
                    @{
                        EmailAddress = "group@contoso.onmicrosoft.com"
                    }
                )
            }

            Mock -CommandName Unregister-SPOHubSite -MockWith { }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call mocks in the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Unregister-SPOHubSite
            }
        }

        Context -Name "When the site should be a hub site and is correctly configured" -Fixture {
            $testParams = @{
                Url                  = "https://contoso.sharepoint.com/sites/Marketing"
                Title                = "Marketing Hub"
                Description          = "Hub for the Marketing division"
                LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                RequiresJoinApproval = $true
                AllowedToJoin        = @("admin@contoso.onmicrosoft.com", "group@contoso.onmicrosoft.com")
                SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                GlobalAdminAccount   = $GlobalAdminAccount
                Ensure               = "Present"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    IsHubSite = $true
                }
            }

            Mock -CommandName Get-SPOHubSite -MockWith {
                $returnVal = @{
                    Permissions          = @(
                        @{
                            PrincipalName = "i:0#.f|membership|admin@contoso.onmicrosoft.com"
                        },
                        @{
                            PrincipalName = "c:0o.c|federateddirectoryclaimprovider|bfc75218-faac-4202-bf33-3a8ba2e2b4a7"
                        }
                    )
                    LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                    Title                = "Marketing Hub"
                    Description          = "Hub for the Marketing division"
                    RequiresJoinApproval = $true
                    SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                }
                return $returnVal
            }

            Mock -CommandName Get-MsolGroup -MockWith {
                return @{
                    EmailAddress = "group@contoso.onmicrosoft.com"
                }
            }

            Mock -CommandName Unregister-SPOHubSite -MockWith { }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the Test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When the site should be a hub site, but is incorrectly configured" -Fixture {
            $testParams = @{
                Url                  = "https://contoso.sharepoint.com/sites/Marketing"
                Title                = "Marketing Hub"
                Description          = "Hub for the Marketing division"
                LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                RequiresJoinApproval = $true
                AllowedToJoin        = @("admin@contoso.onmicrosoft.com", "group@contoso.onmicrosoft.com")
                SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                GlobalAdminAccount   = $GlobalAdminAccount
                Ensure               = "Present"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    IsHubSite = $true
                }
            }

            Mock -CommandName Get-SPOHubSite -MockWith {
                $returnVal = @{
                    Permissions          = @(
                        @{
                            PrincipalName = "i:0#.f|membership|wrongadmin@contoso.onmicrosoft.com"
                        },
                        @{
                            PrincipalName = "c:0o.c|federateddirectoryclaimprovider|bfc75218-faac-4202-bf33-3a8ba2e2b4a7"
                        }
                    )
                    LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                    Title                = "Wrong Title"
                    Description          = "Wrong Description"
                    RequiresJoinApproval = $false
                    SiteDesignId         = "e8eba920-9cca-4de8-b5aa-1da75a2a893c"
                }
                return $returnVal
            }

            Mock -CommandName Get-MsolGroup -MockWith {
                return @{
                    EmailAddress = "wronggroup@contoso.onmicrosoft.com"
                }
            }

            Mock -CommandName Set-SPOHubSite -MockWith { }
            Mock -CommandName Grant-SPOHubSiteRights -MockWith { }
            Mock -CommandName Revoke-SPOHubSiteRights -MockWith { }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call mocks in the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPOHubSite
                Assert-MockCalled Grant-SPOHubSiteRights
                Assert-MockCalled Revoke-SPOHubSiteRights
            }
        }

        Context -Name "When the site isn't a hub site but should be" -Fixture {
            $testParams = @{
                Url                  = "https://contoso.sharepoint.com/sites/Marketing"
                Title                = "Marketing Hub"
                Description          = "Hub for the Marketing division"
                LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                RequiresJoinApproval = $true
                AllowedToJoin        = @("admin@contoso.onmicrosoft.com", "group@contoso.onmicrosoft.com", "SecurityGroup")
                SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                GlobalAdminAccount   = $GlobalAdminAccount
                Ensure               = "Present"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    IsHubSite = $false
                }
            }

            Mock -CommandName Get-MsolGroup -MockWith {
                return @{
                    DisplayName = "SecurityGroup"
                }
            }

            Mock -CommandName Register-SPOHubSite -MockWith { }
            Mock -CommandName Set-SPOHubSite -MockWith { }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call mocks in the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Register-SPOHubSite
                Assert-MockCalled Set-SPOHubSite
            }
        }

        Context -Name "When specified AllowedToJoin group doesn't exist" -Fixture {
            $testParams = @{
                Url                  = "https://contoso.sharepoint.com/sites/Marketing"
                Title                = "Marketing Hub"
                Description          = "Hub for the Marketing division"
                LogoUrl              = "https://contoso.sharepoint.com/sites/Marketing/SiteAssets/hublogo.png"
                RequiresJoinApproval = $true
                AllowedToJoin        = @("admin@contoso.onmicrosoft.com", "group@contoso.onmicrosoft.com", "SecurityGroup")
                SiteDesignId         = "f7eba920-9cca-4de8-b5aa-1da75a2a893c"
                GlobalAdminAccount   = $GlobalAdminAccount
                Ensure               = "Present"
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    IsHubSite = $false
                }
            }

            Mock -CommandName Register-SPOHubSite -MockWith { }
            Mock -CommandName Set-SPOHubSite -MockWith { }

            It "Should throw exception the Set method" {
                { Set-TargetResource @testParams } | Should Throw "Error for principal"
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-SPOSite -MockWith {
                return @{
                    Url    = "https://contoso.com/sites/TestSite"
                    Ensure = "Present"
                }
            }

            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
