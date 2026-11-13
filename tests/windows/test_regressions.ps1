$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$corePath = Join-Path $repoRoot 'windows\payload\AntiDPI_Launcher_Core_20261023_public_v1.ps1'
$AntiDPILibraryOnly = $true
. $corePath
$AntiDPILibraryOnly = $false

function Assert-Equal([object]$Expected, [object]$Actual, [string]$Label) {
    if ([string]$Expected -cne [string]$Actual) {
        throw ("{0}: expected <{1}>, got <{2}>" -f $Label, $Expected, $Actual)
    }
}

function Assert-True([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw ("Assertion failed: " + $Label) }
}

function Assert-Throws([scriptblock]$Action, [string]$Label) {
    try { & $Action } catch { return }
    throw ("Expected an exception: " + $Label)
}

function Assert-Contains([string[]]$Values, [string]$Expected, [string]$Label) {
    if ($Values -cnotcontains $Expected) {
        throw ("{0}: missing <{1}>" -f $Label, $Expected)
    }
}

# Parse every shipped/test PowerShell script with the Windows PowerShell parser.
$scriptRoots = @(
    (Join-Path $repoRoot 'windows'),
    (Join-Path $repoRoot 'packaging\windows'),
    (Join-Path $repoRoot 'tests\windows')
)
foreach ($root in $scriptRoots) {
    foreach ($file in Get-ChildItem -LiteralPath $root -Filter '*.ps1' -File -Recurse) {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count) {
            $details = ($parseErrors | ForEach-Object { $_.Message }) -join '; '
            throw ("PowerShell parse failure in {0}: {1}" -f $file.FullName, $details)
        }
    }
}

$managerText = [IO.File]::ReadAllText((Join-Path $repoRoot 'windows\AntiDPI_Manager.ps1'))
$coreText = [IO.File]::ReadAllText($corePath)
$catalogueText = [IO.File]::ReadAllText((Join-Path $repoRoot 'windows\payload\Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1'))
$guiText = [IO.File]::ReadAllText((Join-Path $repoRoot 'windows\payload\AntiDPI_GUI.ps1'))
$runtimeText = [IO.File]::ReadAllText((Join-Path $repoRoot 'windows\payload\AntiDPI_Runtime_20261023_public_v1.cs'))
$installerText = [IO.File]::ReadAllText((Join-Path $repoRoot 'windows\AntiDPI_Installer.ps1'))
$setupText = [IO.File]::ReadAllText((Join-Path $repoRoot 'packaging\windows\Setup.cs'))
$installerCommand = [IO.File]::ReadAllText((Join-Path $repoRoot 'windows\УСТАНОВКА.cmd'))
$buildWorkflowText = [IO.File]::ReadAllText((Join-Path $repoRoot '.github\workflows\build.yml'))
Assert-True ($buildWorkflowText.Contains("if: inputs.publish_release && inputs.platform == 'all' && github.ref == 'refs/heads/main'")) 'stable release publishing is gated to the main branch'
Assert-True ($managerText.Contains("DisplayVersion='GUI + CLI Version 1.14'") -and $managerText.Contains("Version='GUI_CLI_1.14'") -and $buildWorkflowText.Contains("default: '1.14'")) 'Windows release package version matches the manager manifest and workflow default'
Assert-True ($managerText.Contains("'AntiDPI_GUI.ps1'")) 'installer packages the Windows GUI'
Assert-True ($managerText.Contains('function Remove-AntiDPIPartialInstallation') -and $managerText.Contains('Remove-AntiDPIPartialInstallation $installedManifest') -and $managerText.Contains('Save-AntiDPIManifest ([pscustomobject]$manifest)')) 'late installation failures roll back the owned install files and write the staged manifest atomically'
Assert-True ($managerText.Contains('Remove-AntiDPIFirewallRule $installedManifest') -and $managerText.Contains('Ярлык уже существует и будет сохранён')) 'install rollback cleans its firewall rule and preserves pre-existing desktop items'
Assert-True ($managerText.Contains('function Restore-AntiDPIUpdateChanges') -and $managerText.Contains('UpdatedSha256') -and $managerText.Contains('if($rollbackComplete){Remove-AntiDPITemporaryDirectory $stage}')) 'failed updates verify rollback ownership and retain recovery backups if rollback is incomplete'
Assert-True ($managerText.Contains("'Install','Update','Rollback'") -and $managerText.Contains('function Save-AntiDPIUpdateRollbackBackup') -and $managerText.Contains('function Rollback-AntiDPIUpdate')) 'successful updates expose a verified backup and explicit rollback action'
Assert-True ($managerText.Contains('SourceCommit=$sourceCommit') -and $managerText.Contains('BuildInfo.json')) 'installed manifests record the package source commit when build metadata is available'
$buildScriptText=[IO.File]::ReadAllText((Join-Path $repoRoot 'packaging\windows\build.ps1'))
Assert-True ($buildScriptText.Contains('antidpi.build-info.v1') -and $buildScriptText.Contains('payload/BuildInfo.json') -and $buildScriptText.Contains('$env:GITHUB_SHA')) 'Windows packages carry the source commit used for the release diff'
Assert-True ($guiText.Contains('Start-GuiRollbackManager') -and $guiText.Contains("'-Action','Rollback'")) 'GUI exposes the manager rollback action after update check'
Assert-True ($managerText.Contains('function Assert-AntiDPIInstallPath') -and $managerText.Contains('Assert-AntiDPIInstallPath $root') -and $managerText.Contains('Assert-AntiDPIInstallPath ([string]$Manifest.InstallRoot)')) 'manifest-driven update, uninstall, and owned-process paths reject links and junctions'
Assert-True ($installerText.Contains('Test-InstallerExistingInstall')) 'installer source contains the existing-install verification helper'
Assert-True ($managerText.Contains("'GUI'{& (Join-Path `$PSScriptRoot 'AntiDPI_GUI.ps1')")) 'manager dispatches GUI action'
$launchLines = @($managerText -split '\r?\n' | Where-Object { $_.Contains("New-UserCommand (Join-Path `$ready '") -and $_.EndsWith("') 'GUI'") })
Assert-True ($launchLines.Count -eq 1) 'primary Windows launcher opens GUI'
Assert-True ($coreText.Contains('if($ListProfilesJson)')) 'profile catalogue provides JSON for the GUI'
Assert-True ($catalogueText.Contains('[switch]$ListProfilesJson')) 'catalogue exposes JSON listing switch'
$guiProfileJson = (& (Join-Path $repoRoot 'windows\payload\Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1') -ListProfilesJson | Out-String)
$guiProfiles = @($guiProfileJson | ConvertFrom-Json)
if ($guiProfiles.Count -eq 1 -and $guiProfiles[0] -is [array]) { $guiProfiles = @($guiProfiles[0]) }
Assert-Equal 492 $guiProfiles.Count 'GUI JSON profile list count'
$guiFamilies = @($guiProfiles | Group-Object Family | ForEach-Object { [pscustomobject]@{Count=$_.Count} })
Assert-Equal 24 $guiFamilies.Count 'GUI family/group count'
Assert-Equal 492 (($guiFamilies | Measure-Object -Property Count -Sum).Sum) 'family groups cover all GUI profiles'
$quicJson = (& (Join-Path $repoRoot 'windows\payload\Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1') -ListQuicProfilesJson | Out-String)
$quicProfiles = @($quicJson | ConvertFrom-Json)
if ($quicProfiles.Count -eq 1 -and $quicProfiles[0] -is [array]) { $quicProfiles = @($quicProfiles[0]) }
Assert-Equal 2 $quicProfiles.Count 'QUIC profile count'
Assert-Contains $quicProfiles[0].Args '--payload=quic_initial' 'QUIC Initial payload'
Assert-Contains $quicProfiles[0].Args '--lua-desync=fake:blob=fake_default_quic:repeats=2' 'QUIC fake recipe'
Assert-True ($guiText.Contains('Set-GuiProfileItems $script:guiSettings.Protocol')) 'GUI populates profiles for the saved transport'
Assert-True ($guiText.Contains("Set-GuiProfileItems ([string]`$protocolBox.SelectedItem.Value)")) 'GUI switches profiles by transport'
Assert-True ($guiText.Contains("Label='IPv6';Value='ipv6'")) 'GUI offers IPv6'
Assert-True ($guiText.Contains("Label='UDP + QUIC Initial (HTTP/3)';Value='quic'")) 'GUI offers UDP/QUIC'
Assert-True ($guiText.Contains('$strategyTab') -and $guiText.Contains('$analysisTab') -and $guiText.Contains('$settingsTab') -and $guiText.Contains('$aboutTab')) 'GUI contains strategy, analysis, settings, and about tabs'
Assert-True ($guiText.Contains('$script:programVersion') -and $guiText.Contains('$installManifestPath=Join-Path $installRoot') -and $guiText.Contains('.antidpi-install.json')) 'GUI displays the installed version from its install manifest'
Assert-True ($guiText.Contains('Save-GuiSettings') -and $guiText.Contains("'gui-settings.json'")) 'GUI persists settings'
Assert-True ($guiText.Contains('$adapterBox.DisplayMember=''Name''') -and $guiText.Contains('$adapterBox.Items.Add($item)')) 'adapter dropdown displays a name-only wrapper'
Assert-True ($guiText.Contains('-AnalysisResultPath') -and $guiText.Contains('Request-GuiAnalysisCancel')) 'GUI runs and safely cancels analysis'
Assert-True ($guiText.Contains('function ConvertTo-GuiAnalysisCsv') -and $guiText.Contains('UTF8Encoding]::new($true)')) 'GUI exports analysis results as UTF-8 CSV'
Assert-True ($guiText.Contains('SaveFileDialog') -and $guiText.Contains('Export-GuiAnalysisResults') -and $guiText.Contains('$script:analysisExportButton')) 'GUI exposes an explicit save dialog for analysis CSV exports'
Assert-True ($guiText.Contains('$profileListBox.ScrollAlwaysVisible=$true') -and $guiText.Contains('AutoScrollMinSize=')) 'GUI keeps the strategy ListBox scrollable on compact displays'
Assert-True ($guiText.Contains('$strategyTab.AutoScrollMinSize=[System.Drawing.Size]::new(740,680)') -and $guiText.Contains('$analysisTab.AutoScrollMinSize=[System.Drawing.Size]::new(740,700)') -and $guiText.Contains('$aboutTab.AutoScrollMinSize=[System.Drawing.Size]::new(700,440)') -and $guiText.Contains('$form.MaximizeBox=$true')) 'GUI uses content-sized scroll regions and a larger resizable layout instead of forcing every tab to scroll'
Assert-True ($guiText.Contains('$script:guiSettings.AnalysisRange') -and $guiText.Contains('RememberAdapter') -and $guiText.Contains('Set-GuiAnalysisResults $script:analysisResultPath')) 'GUI persists more settings and polls live analysis results'
Assert-True ($guiText.Contains('$parallelism=if($benchmarkMode){1}else{[int]$analysisParallelismBox.Value}') -and $guiText.Contains("'-Parallelism',[string]`$parallelism")) 'GUI forwards the user-selected analysis parallelism to the CLI'
Assert-True ($guiText.Contains('AnalysisParallelism=3') -and $guiText.Contains('SkipTimestampSetup=$false') -and $guiText.Contains('$arguments+= ''-SkipTimestampSetup''')) 'GUI saves and applies the analysis concurrency and timestamp opt-out settings'
Assert-True ($guiText.Contains('$analysisParallelismBox.Minimum=1') -and $guiText.Contains('$analysisParallelismBox.Maximum=5')) 'GUI constrains configurable parallelism to the CLI supported range'
Assert-True ($guiText.Contains('ShowErrorDetails=$true') -and $guiText.Contains('$settingsShowErrorDetailsCheck.Checked')) 'GUI exposes and persists the automatic error-diagnostics setting'
Assert-True ($guiText.Contains('Get-GuiProcessOutput') -and $guiText.Contains('Show-GuiTextDialog') -and $guiText.Contains('$failure')) 'GUI displays real process output and useful failure diagnostics'
Assert-True ($guiText.Contains('Get-GuiFamilies') -and $guiText.Contains('$FamilyRows') -and $guiText.Contains('familyFilterBox')) 'GUI provides catalogue family browsing equivalent to CLI group listing'
Assert-True ($guiText.Contains('Show-GuiInterfaces') -and $guiText.Contains('$interfacesButton.Add_Click({Show-GuiInterfaces})')) 'GUI provides an all-network-interface inventory equivalent to the CLI listing'
Assert-True ($guiText.Contains('Show-GuiProfileDetails') -and $guiText.Contains('Get-AntiDPIArguments') -and $guiText.Contains('ConvertTo-Json -Depth 20')) 'GUI exposes CLI recipe and resolved engine-argument inspection'
Assert-True ($guiText.Contains('$historyTab=') -and $guiText.Contains('function Add-GuiHistory') -and $guiText.Contains('function Update-GuiHistory')) 'GUI provides persistent searchable run and analysis history'
Assert-True ($guiText.Contains('function Export-GuiHistory') -and $guiText.Contains('AntiDPI_history_')) 'GUI supports CSV export of activity history'
Assert-True ($guiText.Contains('$favoritesCheck.Text=') -and $guiText.Contains('ContextMenuStrip=$profileMenu') -and $guiText.Contains('Save-GuiUiPreferences')) 'GUI supports persistent favorite and recent strategies with context actions'
Assert-True ($guiText.Contains('$details.Text=') -and $guiText.Contains('$details.Multiline=$true') -and $guiText.Contains('$details.ReadOnly=$true')) 'GUI displays strategy recipe information inline'
Assert-True ($guiText.Contains('function Update-GuiDashboard') -and $guiText.Contains('$script:dashboardLabel.Text=') -and $guiText.Contains('$adapterText')) 'GUI exposes current state and configuration in its dashboard'
Assert-True ($guiText.Contains('WindowBounds=$null') -and $guiText.Contains('$form.RestoreBounds') -and $guiText.Contains('WindowMaximized')) 'GUI restores and persists a visible window position and maximized state'
Assert-True ($guiText.Contains('$script:guiSettings.FirstRunComplete=$true') -and $guiText.Contains('FirstRunComplete')) 'GUI guides first-time users through a safe initial setup'
Assert-True ($guiText.Contains('[System.Windows.Forms.Keys]::Enter') -and $guiText.Contains('[System.Windows.Forms.Keys]::L') -and $guiText.Contains('Ctrl+F')) 'GUI documents and implements quick keyboard commands'
Assert-True ($guiText.Contains('function ConvertTo-GuiConnectionProfile') -and $guiText.Contains('connection-profiles.json') -and $guiText.Contains('function Apply-GuiConnectionProfile')) 'GUI saves, validates, and applies named connection profiles'
Assert-True ($guiText.Contains('antidpi.gui-backup.v1') -and $guiText.Contains('Export-GuiConfiguration') -and $guiText.Contains('Import-GuiConfiguration')) 'GUI exports and validates importable settings backups'
Assert-True ($guiText.Contains('function Get-GuiReadiness') -and $guiText.Contains('Assert-GuiReadiness') -and $guiText.Contains('Show-GuiReadiness')) 'GUI performs a pre-launch system and adapter readiness check'
Assert-True ($guiText.Contains('NotifyIcon') -and $guiText.Contains('MinimizeToTray') -and $guiText.Contains('Request-GuiStop')) 'GUI exposes safe system-tray controls and optional minimize-to-tray'
Assert-True ($guiText.Contains('$networkTimer.Interval=4000') -and $guiText.Contains('networkCandidateCount') -and $guiText.Contains('Get-DnsClientServerAddress') -and $guiText.Contains('Request-GuiAnalysisCancel') -and $guiText.Contains('Request-GuiStop')) 'GUI debounces network changes across address, route, and DNS before safe cancellation'
Assert-True ($guiText.Contains('Show-GuiDiagnosticReport') -and $guiText.Contains('New-GuiDiagnosticReport') -and $guiText.Contains('[USER]') -and $guiText.Contains('[IPv6]')) 'GUI previews and exports redacted diagnostic reports'
Assert-True ($guiText.Contains('Start-GuiUpdateManager') -and $guiText.Contains("'-Action','Update'") -and $guiText.Contains('Start-Process -FilePath $powershell')) 'GUI opens the ownership-checked update manager after confirmation'
Assert-True ($guiText.Contains('/compare/') -and $guiText.Contains('Start-GuiAssetVerification') -and $guiText.Contains('$InstalledCommit')) 'GUI previews a commit diff and offers bounded GitHub asset digest verification'
Assert-True ($guiText.Contains('Start-GuiConnectivityMatrix') -and $guiText.Contains('AuthenticateAsClient') -and $guiText.Contains('--http3-only') -and $guiText.Contains('cloudflare.com')) 'GUI performs real service-targeted HTTPS and HTTP/3 checks where curl supports HTTP/3'
Assert-True ($guiText.Contains('$httpStatus=if') -and $guiText.Contains('$quicStatus=if') -and $guiText.Contains('$httpResponses') -and $guiText.Contains('$quicResponses')) 'Connectivity checks distinguish an HTTP application response from transport failure'
Assert-True ($guiText.Contains('youtube.com') -and $guiText.Contains('netflix.com') -and $guiText.Contains('twitch.tv')) 'GUI offers a distinct video-service check set, separate from general web services'
Assert-True ($guiText.Contains('Start-GuiTorVerification') -and $guiText.Contains('check.torproject.org/api/ip') -and $guiText.Contains('IsTor -eq $true') -and $guiText.Contains('Start-GuiVpnVerification') -and $guiText.Contains('--interface')) 'GUI tests Tor through its local SOCKS proxy and VPN through a selected, route-bound interface as separate tunnel checks'
Assert-True ($guiText.Contains('Get-GuiVerifiedOwnedEngine') -and $guiText.Contains('Show-GuiOrphanRecoveryPrompt') -and $guiText.Contains('RequestStop($bundle)') -and $guiText.Contains('StartUTC')) 'GUI restart recovery verifies PID, path, and start time, then offers only graceful stop'
Assert-True ($managerText.Contains('function Update-AntiDPI')) 'Update handler exists for approved in-place updates'
Assert-True ($guiText.Contains('Stop-GuiConnectivityMatrix') -and $guiText.Contains('Remove-Job -Job $script:networkMatrixJob')) 'GUI lets users cancel the baseline connectivity matrix and cleans up its job'
Assert-True ($guiText.Contains('$launchArguments+= ''-Check''') -and $guiText.Contains('CheckOnly') -and $guiText.Contains('Start-GuiStrategy')) 'GUI offers the CLI validation-only mode without enabling packet interception'
Assert-True ($guiText.Contains('Request-GuiRestart') -and $guiText.Contains('Request-GuiStop') -and $guiText.Contains('F2')) 'GUI restart and keyboard actions route through managed shutdown'
Assert-True ($guiText.Contains('$script:workerMode=if($CheckOnly)') -and $guiText.Contains('Start-Process -FilePath $powershell')) 'GUI owns and tracks its CLI worker process'
Assert-True ($guiText.Contains('BASELINE_PASS') -and $guiText.Contains('Start-GuiAnalysis')) 'GUI distinguishes already-available YouTube from strategy PASS without claiming tunnel or DPI-bypass proof'
Assert-True ($guiText.Contains('$profileListBox=New-Object System.Windows.Forms.ListBox') -and $guiText.Contains('$profileSearchBox.Add_TextChanged') -and $guiText.Contains('profileCountLabel')) 'GUI shows a persistent searchable strategy list'
Assert-True ($guiText.Contains('AnalysisAttempts') -and $guiText.Contains('AnalysisTimeoutSeconds') -and $guiText.Contains('AnalysisThresholdKB')) 'GUI persists configurable YouTube attempts, timeout, and response threshold'
Assert-True ($guiText.Contains("'-AnalysisAttempts',[string]`$attempts") -and $guiText.Contains("'-AnalysisTimeoutSeconds',[string]`$timeoutSeconds") -and $guiText.Contains("'-AnalysisThresholdKB',[string]`$thresholdKB")) 'GUI forwards analysis tuning settings to the CLI'
Assert-True ($catalogueText.Contains('[int]$AnalysisAttempts=2') -and $catalogueText.Contains('[int]$AnalysisThresholdKB=100') -and $catalogueText.Contains('[int]$AnalysisTimeoutSeconds=15')) 'CLI supports bounded analysis tuning parameters'


Assert-True ($guiText.Contains('analysisRangeBox')) 'GUI accepts a single strategy number or an inclusive numeric range'
Assert-True ($coreText.Contains('Write-AntiDPIAnalysisSnapshot') -and $coreText.Contains('Get-AntiDPIAnalysisRow')) 'YouTube results are written after each strategy without parsing diagnostic Event fields'
Assert-True ($coreText.Contains('BaselineAfter') -and $coreText.Contains('BASELINE_AFTER') -and $coreText.Contains('MeanSuccessSeconds') -and $catalogueText.Contains('[switch]$BracketBaseline')) 'benchmark mode brackets serial strategy trials with a second baseline and records successful response times'
Assert-True ($coreText.Contains('Test-AntiDPIYoutubeBaseline') -and $coreText.Contains('$SourceAddress') -and $runtimeText.Contains('candidate.Client.Bind(new IPEndPoint(IPAddress.Parse(sourceAddress), 0))')) 'baseline HTTPS requests are bound to the selected physical adapter IPv4 address'
$analysisSuccess = [pscustomobject]@{Successes=2;Cancelled=$false;Error=''}
Assert-Equal 'BASELINE_PASS' (Get-AntiDPIAnalysisRow $analysisSuccess 1 2 2).Status 'strategy success is not reported as strategy-specific PASS when the control also succeeds'
Assert-Equal 'PASS' (Get-AntiDPIAnalysisRow $analysisSuccess 1 0 2).Status 'strategy PASS requires success with a failing control'
Assert-Equal 'INCONCLUSIVE' (Get-AntiDPIAnalysisRow $analysisSuccess 1 1 2).Status 'strategy success with an unstable control is inconclusive'
$analysisAttempts = [pscustomobject]@{Successes=1;Cancelled=$false;Error='';Attempts=@([pscustomobject]@{Success=$true;HttpStatus=200;Bytes=131072;Seconds=1.2;Reason=''},[pscustomobject]@{Success=$false;HttpStatus=0;Bytes=0;Seconds=15.0;Reason='TIMEOUT'})}
$analysisRow = Get-AntiDPIAnalysisRow $analysisAttempts 1 0 2
Assert-Equal 'UNSTABLE' $analysisRow.Status 'mixed results are not marked PASS'
Assert-True ($analysisRow.AttemptDetails.Contains('HTTP 200') -and $analysisRow.AttemptDetails.Contains('TIMEOUT')) 'analysis rows carry useful per-attempt evidence'
Assert-Equal 1.2 $analysisRow.MeanSuccessSeconds 'analysis row records mean successful response time'
Assert-True ($coreText.Contains('Get-AntiDPIAnalysisRow') -and $coreText.Contains('Write-AntiDPIAnalysisSnapshot')) 'YouTube result export uses structured analysis rows rather than diagnostic records'
Assert-True ($installerText.Contains('мастер установки') -and $installerText.Contains('-NonInteractiveInstaller') -and $installerText.Contains('Start-Process')) 'Windows uses a graphical installer with explicit options and progress logs'
Assert-True ($installerText.Contains('Test-InstallerExistingInstall') -and $installerText.Contains("'Update'") -and $installerText.Contains('сохранить настройки, логи')) 'installer offers safe in-place updates for recognized existing installations'
Assert-True ($installerText.Contains('-Encoding UTF8') -and $installerText.Contains("`$status.Text=('Ошибка: '")) 'installer reads UTF-8 output and reports useful failure text'
Assert-True ($installerText.Contains('$cancelButton.Add_Click') -and $installerText.Contains('CancelFile') -and $installerText.Contains('.closed')) 'installer exposes cooperative cancellation only while the verified bundle is downloading'
Assert-True ($managerText.Contains('function Test-AntiDPIInstallCancellation') -and $managerText.Contains('$maxAttempts=3*$sources.Count') -and $managerText.Contains('$maximumSeconds=600')) 'bundle download checks cancellation and has finite retries and a total deadline'
Assert-True ($managerText.Contains('exit 2') -and $installerText.Contains('if($code -eq 2)')) 'installer cancellation is reported distinctly from success and failure'
Assert-True ($managerText.Contains('$finalUri=[Uri]$download.FinalUrl') -and $managerText.Contains('codeload.github.com') -and $managerText.Contains('computed_locally_no_trusted_expected_digest')) 'latest bundle is restricted to direct GitHub HTTPS and recorded as lacking a trusted expected digest'
Assert-True ($managerText.Contains("if(`$Selection -eq 'Compatible')") -and $installerText.Contains('SHA-256 заранее не закреплён')) 'unverified mirror is reserved for pinned bundles and Latest integrity limits are disclosed in the installer'
Assert-True ($managerText.Contains("'Update'") -and $managerText.Contains('Update-AntiDPI') -and $managerText.Contains('Сохраните свою копию')) 'manager has an ownership-checked update path that protects modified files'
Assert-True ($managerText.Contains('[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)')) 'manager sets UTF-8 output for Cyrillic installer logs'
Assert-True ($installerText.Contains('-WindowStyle Normal') -and -not $installerText.Contains("'-WindowStyle','Hidden'")) 'Installer subprocesses are not hidden from the user'
Assert-True ($installerCommand -notmatch '(?i)-WindowStyle\s+Hidden') 'ZIP installer entry point does not hide PowerShell'
Assert-True ($setupText.Contains('0x00000010') -and $setupText -notmatch '(?i)-WindowStyle Hidden') 'EXE bootstrapper starts its installer visibly instead of creating a hidden PowerShell process'
Assert-True ($setupText.Contains('AntiDPI_Installer.ps1') -and $installerCommand.Contains('AntiDPI_Installer.ps1')) 'EXE and ZIP entry points both launch the new Windows installer UI'
Assert-True ($managerText.Contains('$NonInteractiveInstaller') -and $managerText.Contains('$CreateShortcutChoice') -and $managerText.Contains('$BundleSelection')) 'installer backend accepts the GUI-selected setup options'
Assert-True ($managerText.Contains("'AntiDPI_Zapret2.ico'") -and $managerText.Contains("'AntiDPI_Zapret2_delete.ico'")) 'install and uninstall shortcuts use their separate application icons'
foreach ($iconName in @('AntiDPI_Zapret2.ico','AntiDPI_Zapret2_delete.ico')) {
    $iconBytes = [IO.File]::ReadAllBytes((Join-Path $repoRoot ('windows\payload\' + $iconName)))
    Assert-Equal 0 ([BitConverter]::ToUInt16($iconBytes,0)) ($iconName + ' reserved header')
    Assert-Equal 1 ([BitConverter]::ToUInt16($iconBytes,2)) ($iconName + ' ICO type')
    Assert-Equal 7 ([BitConverter]::ToUInt16($iconBytes,4)) ($iconName + ' contains seven standard resolutions')
}
Assert-True (-not $managerText.Contains('AntiDPIArtCLI.ttf') -and -not $coreText.Contains('PrepareFont') -and -not $coreText.Contains('AntiDPI_Console_Artwork.cs')) 'Windows CLI uses the system console font and no longer installs the artwork font'
foreach ($removedAsset in @('windows\payload\AntiDPIArtCLI.ttf','windows\payload\AntiDPIArtCLI_OFL.txt','licenses\AntiDPIArtCLI_OFL.txt','windows\payload\AntiDPI_Artwork_CLI.json','windows\payload\AntiDPI_Console_Artwork.cs','windows\payload\ascii-art-new-1147-25102026.txt','linux\assets\logo\ascii-art-new-1147-25102026.txt')) {
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot $removedAsset))) ('Removed unused custom-font/artwork asset: ' + $removedAsset)
}
Assert-True (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'assets'))) 'Removed unused root assets directory'
Assert-True ($coreText.Contains('if($Analyze)') -and $coreText.Contains('strategy-analysis.v1')) 'analysis uses measured YouTube results'
Assert-True ($catalogueText.Contains('[switch]$Analyze')) 'catalogue provides GUI analysis mode'
Assert-True ($catalogueText.Contains('[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)') -and $catalogueText.Contains('$OutputEncoding=[Console]::OutputEncoding')) 'Windows catalogue writes UTF-8 so redirected GUI logs preserve Cyrillic'
Assert-True ($coreText.Contains('--wf-udp-out')) 'engine builder supports outbound UDP capture'
Assert-True ($coreText.Contains('--filter-$transport=$ports')) 'engine builder chooses TCP or UDP filter'
Assert-True ($managerText.Contains("'ips6-exclude.txt'")) 'installer packages IPv6 exclusions'
Assert-True (Test-Path -LiteralPath (Join-Path $repoRoot 'windows\payload\lists\ips6-exclude.txt')) 'IPv6 exclusions are shipped'
Assert-True ($guiText.Contains('[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle)')) 'GUI requests managed controller shutdown'
Assert-True ($guiText.Contains('[AntiDPIConsoleWindow]::Hide()')) 'GUI hides only the console, not its form'
Assert-True ($managerText.Contains("WindowStyle='Normal';PassThru=`$true")) 'restarted GUI process starts with a visible window style'
Assert-True ($managerText.Contains('-WindowStyle Normal')) 'post-install GUI process starts with a visible window style'
Assert-True ($guiText.Contains("Write-GuiLog 'Showing main form'")) 'GUI records whether the form was shown'
Assert-True (-not $guiText.Contains('Invoke-WebRequest')) 'GUI does not present a network probe as a tunnel check'

# Ensure the Windows CLI carries the same expanded catalogue as Linux.
$windowsCataloguePath = Join-Path $repoRoot 'windows\payload\Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1'
$windowsCatalogueText = [IO.File]::ReadAllText($windowsCataloguePath)
$catalogueMatch = [regex]::Match($windowsCatalogueText, '(?s)\$ProfileRows = @''\r?\n(.*?)\r?\n''@ \| ConvertFrom-Json')
Assert-True $catalogueMatch.Success 'embedded Windows profile catalogue exists'
$windowsRows = @($catalogueMatch.Groups[1].Value | ConvertFrom-Json)
if ($windowsRows.Count -eq 1 -and $windowsRows[0] -is [array]) {
    $windowsRows = @($windowsRows[0])
}
$linuxCatalogue = Get-Content -LiteralPath (Join-Path $repoRoot 'linux\data\catalogue.json') -Raw | ConvertFrom-Json
Assert-Equal $linuxCatalogue.CatalogueInfo.ProfileCount $windowsRows.Count 'Windows profile count matches Linux'
Assert-Equal 492 $windowsRows.Count 'expanded profile count'
$newWindowsRows = @($windowsRows | Where-Object { $_.Number -ge 485 })
Assert-Equal 8 $newWindowsRows.Count 'new strategy count'
Assert-Contains $newWindowsRows[0].Args '--lua-desync=syndata' 'new SYN-data method'
Assert-Contains $newWindowsRows[4].Args '--lua-desync=wssize:wsize=1:scale=6' 'new TCP window-size method'
foreach ($number in 485..492) {
    $linuxRow = $linuxCatalogue.ProfileRows | Where-Object { $_.Number -eq $number }
    $windowsRow = $windowsRows | Where-Object { $_.Number -eq $number }
    Assert-Equal $linuxRow.RecipeSHA256 $windowsRow.RecipeSHA256 ("cross-platform recipe {0}" -f $number)
}
Assert-Equal $linuxCatalogue.CatalogueInfo.FamilyCount $linuxCatalogue.FamilyRows.Count 'Linux family metadata'

# The CI job supplies the hash-verified official bundle and runs these with
# interception disabled, so only option/Lua validation occurs, not packet capture.
if ($env:AntiDPI_WINWS2_DIR) {
    $enginePath = Join-Path $env:AntiDPI_WINWS2_DIR 'winws2.exe'
    if (-not (Test-Path -LiteralPath $enginePath -PathType Leaf)) { throw 'Verified winws2.exe not found.' }
    Push-Location -LiteralPath $env:AntiDPI_WINWS2_DIR
    try {
        foreach ($profile in $newWindowsRows) {
            $engineArguments = @(Get-AntiDPIArguments -Row $profile -Index 1 -PortScope '443')
            $handlers = @($profile.Args | Where-Object { $_.StartsWith('--lua-desync=') } |
                ForEach-Object { ($_ -split ':', 2)[0].Substring('--lua-desync='.Length) } | Sort-Object -Unique)
            $luaChecks = @($handlers | ForEach-Object { "assert(type($_)=='function','missing $_')" })
            if ($profile.StockTlsPattern) { $luaChecks += "assert(type(fake_default_tls)=='string','missing TLS pattern')" }
            $engineArguments += '--intercept=0'
            $engineArguments += '--lua-init=' + ($luaChecks -join ';')
            $output = & $enginePath @engineArguments 2>&1
            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0) {
                throw ("Windows engine rejected strategy {0} (exit {1}): {2}" -f $profile.Number, $exitCode, ($output -join "`n"))
            }
        }
        foreach ($profile in $quicProfiles) {
            $row = [pscustomobject]@{ Args = @($profile.Args); Init = $null; NeedsTimestamps = $false; StockTlsPattern = $false }
            foreach ($family in @('ipv4','ipv6')) {
                $engineArguments = @(Get-AntiDPIArguments -Row $row -Index 1 -PortScope '443' -AddressFamily $family -Protocol 'quic')
                $handlers = @($row.Args | Where-Object { $_.StartsWith('--lua-desync=') } |
                    ForEach-Object { ($_ -split ':', 2)[0].Substring('--lua-desync='.Length) } | Sort-Object -Unique)
                $luaChecks = @($handlers | ForEach-Object { "assert(type($_)=='function','missing $_')" })
                $engineArguments += '--intercept=0'
                $engineArguments += '--lua-init=' + ($luaChecks -join ';')
                $output = & $enginePath @engineArguments 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -ne 0) { throw ("Windows engine rejected QUIC strategy {0} / {1} (exit {2}): {3}" -f $profile.Number,$family,$exitCode,($output -join "`n")) }
            }
        }
    } finally { Pop-Location }
}

# Port-scope normalization and validation.
Assert-Equal 'all' (ConvertTo-AntiDPIPortScope '') 'empty scope defaults to all'
Assert-Equal 'all' (ConvertTo-AntiDPIPortScope '0-65535') 'full range canonicalizes to all'
Assert-Equal '80-81,443' (ConvertTo-AntiDPIPortScope '443,80-81,80') 'ranges sort and merge'
Assert-True (Test-AntiDPIScopePort '80-81,443' 443) 'selected destination port matches'
Assert-True (-not (Test-AntiDPIScopePort '80-81,443' 8443)) 'unselected destination port is excluded'
Assert-Throws { ConvertTo-AntiDPIPortScope '65536' } 'port above maximum'
Assert-Throws { ConvertTo-AntiDPIPortScope '100-80' } 'descending port range'
Assert-Throws { ConvertTo-AntiDPIPortScope '443,,80' } 'empty list member'

# Engine argument construction must preserve the IPv4/TCP/TLS and port filters.
$row = [pscustomobject]@{ Args = @('--payload=tls_client_hello'); Init = $null }
$singlePort = @(Get-AntiDPIArguments -Row $row -Index 12 -PortScope '443')
Assert-Contains $singlePort '--wf-l3=ipv4' 'IPv4 layer filter'
Assert-Contains $singlePort '--wf-iface=12' 'adapter filter'
Assert-Contains $singlePort '--wf-tcp-out=443' 'outbound TCP scope'
Assert-Contains $singlePort '--filter-tcp=443' 'engine TCP scope'
Assert-Contains $singlePort '--filter-l7=tls' 'TLS application filter'

$allPorts = @(Get-AntiDPIArguments -Row $row -Index 12 -PortScope 'all')
Assert-Contains $allPorts '--wf-tcp-out=0-65535' 'all TCP port scope'
Assert-Contains $allPorts '--filter-tcp=0-65535' 'engine all-port scope'

$quicRow = [pscustomobject]@{ Args = @('--payload=quic_initial','--lua-desync=fake:blob=fake_default_quic:repeats=2'); Init = $null }
$ipv6Quic = @(Get-AntiDPIArguments -Row $quicRow -Index 12 -PortScope '443' -AddressFamily 'ipv6' -Protocol 'quic')
Assert-Contains $ipv6Quic '--wf-l3=ipv6' 'IPv6 layer filter'
Assert-Contains $ipv6Quic '--wf-udp-out=443' 'QUIC outbound UDP scope'
Assert-Contains $ipv6Quic '--filter-udp=443' 'QUIC UDP scope'
Assert-Contains $ipv6Quic '--filter-l7=quic' 'QUIC application filter'
Assert-Contains $ipv6Quic '--payload=quic_initial' 'QUIC Initial payload'
Assert-Contains $ipv6Quic ('--ipset-exclude=' + (Join-Path $repoRoot 'windows\payload\lists\ips6-exclude.txt')) 'IPv6 exclusions selected'
Assert-True ($ipv6Quic -cnotcontains '--wf-tcp-out=443' -and $ipv6Quic -cnotcontains '--filter-tcp=443') 'QUIC does not use TCP filters'
Assert-Throws { Get-AntiDPIArguments -Row $quicRow -Index 12 -PortScope '443' -ProbePorts @(45001) -Protocol 'quic' } 'TLS probes cannot be combined with QUIC'

$probeArgs = @(Get-AntiDPIArguments -Row $row -Index 12 -PortScope '443' -ProbePorts @(45001, 45002))
$rawFilter = $probeArgs | Where-Object { $_ -like '--wf-raw-filter=*' }
Assert-True ($rawFilter -like '*tcp.SrcPort == 45001*' -and $rawFilter -like '*tcp.SrcPort == 45002*') 'probe source-port isolation'
Assert-True ($rawFilter -like '*tcp.DstPort == 45001*' -and $rawFilter -like '*tcp.DstPort == 45002*') 'probe reverse-flow isolation'

# Exercise the partial-install rollback helper without invoking the full elevated installer.
$rollbackTokens = $null
$rollbackParseErrors = $null
$managerAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'windows\AntiDPI_Manager.ps1'), [ref]$rollbackTokens, [ref]$rollbackParseErrors)
Assert-Equal 0 $rollbackParseErrors.Count 'rollback helper source parses successfully'
$rollbackAst = $managerAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Remove-AntiDPIPartialInstallation' }, $true)
Assert-True ($null -ne $rollbackAst) 'partial installation rollback helper can be isolated for tests'
. ([scriptblock]::Create($rollbackAst.Extent.Text))
$rollbackRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntiDPI-rollback-test-' + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($rollbackRoot) | Out-Null
    $ownedPath = Join-Path $rollbackRoot 'owned.txt'
    $modifiedPath = Join-Path $rollbackRoot 'modified.txt'
    $extraPath = Join-Path $rollbackRoot 'user-extra.txt'
    $emptyUserDirectory = Join-Path $rollbackRoot 'user-empty'
    [IO.File]::WriteAllText($ownedPath, 'installer-owned')
    [IO.File]::WriteAllText($modifiedPath, 'installer-original')
    [IO.File]::WriteAllText($extraPath, 'do-not-delete')
    [IO.Directory]::CreateDirectory($emptyUserDirectory) | Out-Null
    $ownedHash = (Get-FileHash -LiteralPath $ownedPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $modifiedHash = (Get-FileHash -LiteralPath $modifiedPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText($modifiedPath, 'user-modified')
    $installId = [guid]::NewGuid().ToString()
    $rollbackManifest = [pscustomobject]@{
        Schema='antidpi.zapret.install.v1'; InstallID=$installId; InstallRoot=$rollbackRoot
        Files=@([pscustomobject]@{Path='owned.txt';Sha256=$ownedHash},[pscustomobject]@{Path='modified.txt';Sha256=$modifiedHash})
    }
    $markerPath = Join-Path $rollbackRoot '.antidpi-install.json'
    $markerData = [ordered]@{Schema='antidpi.zapret.install.v1';InstallID=$installId;InstallRoot=$rollbackRoot}
    [IO.File]::WriteAllText($markerPath,($markerData|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
    Remove-AntiDPIPartialInstallation $rollbackManifest
    Assert-True (-not (Test-Path -LiteralPath $ownedPath)) 'rollback removes an unchanged installer-owned file'
    Assert-True (Test-Path -LiteralPath $modifiedPath) 'rollback preserves an installer-owned file modified by the user'
    Assert-True (Test-Path -LiteralPath $extraPath) 'rollback preserves an untracked user file'
    Assert-True (Test-Path -LiteralPath $emptyUserDirectory) 'rollback preserves an unrelated empty user directory'
    Assert-True (-not (Test-Path -LiteralPath $markerPath)) 'rollback removes only its matching installation marker'
} finally {
    if(Test-Path -LiteralPath $rollbackRoot){Remove-Item -LiteralPath $rollbackRoot -Recurse -Force -ErrorAction SilentlyContinue}
}

# Test update rollback ownership and verify that failed restoration keeps its backup.
$updateRollbackAst = $managerAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Restore-AntiDPIUpdateChanges' }, $true)
Assert-True ($null -ne $updateRollbackAst) 'update rollback helper can be isolated for tests'
. ([scriptblock]::Create($updateRollbackAst.Extent.Text))
$updateRollbackRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntiDPI-update-rollback-test-' + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($updateRollbackRoot) | Out-Null
    $destination = Join-Path $updateRollbackRoot 'application.txt'
    $backup = Join-Path $updateRollbackRoot 'backup.txt'
    [IO.File]::WriteAllText($destination, 'updated')
    [IO.File]::WriteAllText($backup, 'original')
    $updatedHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    $change = [pscustomobject]@{Destination=$destination;Backup=$backup;Existed=$true;UpdatedSha256=$updatedHash}
    $restoreResult = Restore-AntiDPIUpdateChanges @($change)
    Assert-True $restoreResult.Success 'rollback restores a verified update from its backup'
    Assert-Equal 'original' ([IO.File]::ReadAllText($destination)) 'rollback restores original bytes'
    Assert-True (-not (Test-Path -LiteralPath $backup)) 'successful rollback consumes its recovery backup'

    [IO.File]::WriteAllText($destination, 'changed-after-update')
    [IO.File]::WriteAllText($backup, 'preserved-original')
    $restoreResult = Restore-AntiDPIUpdateChanges @($change)
    Assert-True (-not $restoreResult.Success) 'rollback refuses to overwrite a file changed after the update'
    Assert-Equal 'changed-after-update' ([IO.File]::ReadAllText($destination)) 'rollback preserves the post-update user change'
    Assert-Equal 'preserved-original' ([IO.File]::ReadAllText($backup)) 'failed rollback leaves the original backup available'
} finally {
    if(Test-Path -LiteralPath $updateRollbackRoot){Remove-Item -LiteralPath $updateRollbackRoot -Recurse -Force -ErrorAction SilentlyContinue}
}

# Persist a prior version only after copying and verifying every original update file.
$installPathAst = $managerAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-AntiDPIInstallPath' }, $true)
Assert-True ($null -ne $installPathAst) 'install path helper is available to update backup tests'
. ([scriptblock]::Create($installPathAst.Extent.Text))
$updateBackupAst = $managerAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Save-AntiDPIUpdateRollbackBackup' }, $true)
Assert-True ($null -ne $updateBackupAst) 'successful-update backup helper can be isolated for tests'
. ([scriptblock]::Create($updateBackupAst.Extent.Text))
$updateBackupRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntiDPI-update-backup-test-' + [guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($updateBackupRoot) | Out-Null
    $oldContentPath = Join-Path $updateBackupRoot 'old-content.txt'
    $newContentPath = Join-Path $updateBackupRoot 'application.txt'
    [IO.File]::WriteAllText($oldContentPath, 'previous version bytes')
    [IO.File]::WriteAllText($newContentPath, 'updated version bytes')
    $oldManifestJson = ([ordered]@{Schema='antidpi.zapret.install.v1';InstallRoot=$updateBackupRoot;DisplayVersion='Previous'}) | ConvertTo-Json -Depth 4
    $updatedHash = (Get-FileHash -LiteralPath $newContentPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $change = [pscustomobject]@{Destination=$newContentPath;Backup=$oldContentPath;Existed=$true;UpdatedSha256=$updatedHash}
    $backupPath = Save-AntiDPIUpdateRollbackBackup $updateBackupRoot $oldManifestJson @($change) 'Updated'
    $backupMetadata = Get-Content -LiteralPath (Join-Path $backupPath 'rollback.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Equal 'antidpi.update.rollback.v1' $backupMetadata.Schema 'rollback backup schema'
    Assert-Equal 'Previous' $backupMetadata.PreviousVersion 'rollback backup records previous version'
    Assert-Equal 1 @($backupMetadata.Changes).Count 'rollback backup records changed file'
    $savedPrevious = Join-Path (Join-Path $backupPath 'files') 'application.txt'
    Assert-Equal 'previous version bytes' ([IO.File]::ReadAllText($savedPrevious)) 'rollback backup contains original file bytes'
    Assert-Equal ([string]$backupMetadata.Changes[0].PreviousSha256) ((Get-FileHash -LiteralPath $savedPrevious -Algorithm SHA256).Hash.ToLowerInvariant()) 'rollback backup records a verifiable original hash'
} finally {
    if(Test-Path -LiteralPath $updateBackupRoot){Remove-Item -LiteralPath $updateBackupRoot -Recurse -Force -ErrorAction SilentlyContinue}
}

# Reject reparse points inside an installation tree and lexical escapes from its root.
$pathSafetyAst = $managerAst.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-AntiDPIInstallPath' }, $true)
Assert-True ($null -ne $pathSafetyAst) 'install path safety helper can be isolated for tests'
. ([scriptblock]::Create($pathSafetyAst.Extent.Text))
$pathSafetyRoot = Join-Path ([IO.Path]::GetTempPath()) ('AntiDPI-path-safety-test-' + [guid]::NewGuid().ToString('N'))
$installRoot = Join-Path $pathSafetyRoot 'install'
$outsideRoot = Join-Path $pathSafetyRoot 'outside'
$junctionPath = Join-Path $installRoot 'linked'
$rootJunction = Join-Path $pathSafetyRoot 'install-alias'
try {
    [IO.Directory]::CreateDirectory($installRoot) | Out-Null
    [IO.Directory]::CreateDirectory($outsideRoot) | Out-Null
    [IO.File]::WriteAllText((Join-Path $outsideRoot 'outside.txt'), 'outside-data')
    $junctionCommand = 'mklink /J "' + $junctionPath + '" "' + $outsideRoot + '"'
    & $env:ComSpec /d /c $junctionCommand | Out-Null
    Assert-Equal 0 $LASTEXITCODE 'test junction creation'
    Assert-Throws { Assert-AntiDPIInstallPath $installRoot 'linked\outside.txt' } 'reject a manifest path through a junction'
    Assert-Throws { Assert-AntiDPIInstallPath $installRoot '..\outside\outside.txt' } 'reject a lexical escape from the install root'
    Assert-True (Test-Path -LiteralPath (Join-Path $outsideRoot 'outside.txt')) 'path validation leaves data behind a junction untouched'
    $aliasCommand = 'mklink /J "' + $rootJunction + '" "' + $installRoot + '"'
    & $env:ComSpec /d /c $aliasCommand | Out-Null
    Assert-Equal 0 $LASTEXITCODE 'test installation-root junction creation'
    Assert-Throws { Assert-AntiDPIInstallPath $rootJunction 'outside.txt' } 'reject a reparse point used as the installation root'
} finally {
    if(Test-Path -LiteralPath $rootJunction){[IO.Directory]::Delete($rootJunction)}
    if(Test-Path -LiteralPath $junctionPath){[IO.Directory]::Delete($junctionPath)}
    if(Test-Path -LiteralPath $pathSafetyRoot){Remove-Item -LiteralPath $pathSafetyRoot -Recurse -Force -ErrorAction SilentlyContinue}
}

# Exercise CSV quoting, UTF-8 BOM output, replacement, and temporary-file cleanup.
$guiTokens = $null
$guiParseErrors = $null
$guiAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'windows\payload\AntiDPI_GUI.ps1'), [ref]$guiTokens, [ref]$guiParseErrors)
Assert-Equal 0 $guiParseErrors.Count 'GUI source parses before CSV helper extraction'
foreach($functionName in @('Get-GuiAnalysisRecommendation','Get-GuiObjectProperty','ConvertTo-GuiAnalysisCsv','Write-GuiAnalysisCsv','ConvertTo-GuiConnectionProfile')){
    $functionAst=$guiAst.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName},$true)
    Assert-True ($null -ne $functionAst) ('CSV helper is available: '+$functionName)
    . ([scriptblock]::Create($functionAst.Extent.Text))
}
$profileRows=@([pscustomobject]@{Number=37;Name='Example; "strategy"'})
$connectionProfile=ConvertTo-GuiConnectionProfile ([pscustomobject]@{Name='Дом';ProfileNumber=493;AddressFamily='ipv6';Protocol='quic';Ports='443';AdapterGuid='guid';AdapterName='Ethernet'})
Assert-Equal 493 $connectionProfile.ProfileNumber 'connection profile supports QUIC catalog numbers'
Assert-Equal 'ipv6' $connectionProfile.AddressFamily 'connection profile keeps the selected IP family'
Assert-Equal '443' $connectionProfile.Ports 'connection profile normalizes its port scope'
Assert-Throws { ConvertTo-GuiConnectionProfile ([pscustomobject]@{Name='Bad';ProfileNumber=999;AddressFamily='ipv4';Protocol='tls';Ports='443'}) } 'connection profiles reject unknown strategy numbers'
Assert-Throws { ConvertTo-GuiConnectionProfile ([pscustomobject]@{Name='Bad';ProfileNumber=1;AddressFamily='ipv4';Protocol='tls';Ports='70000'}) } 'connection profiles reject invalid ports'
$csvData=[pscustomobject]@{
    CreatedUtc='2026-11-10T12:00:00.0000000Z';Test='YouTube HTTPS';AddressFamily='ipv4';Protocol='tcp-tls';FirstProfile=37;LastProfile=37
    Baseline=[pscustomobject]@{Successes=0;Attempts=2}
    Results=@([pscustomobject]@{Number=37;Status='FAIL';Successes=0;ExpectedAttempts=2;AttemptDetails='Попытка 1; HTTP 200, текст "ok"';Details='ошибка; строка "две"'})
}
$csvRoot=Join-Path ([IO.Path]::GetTempPath()) ('AntiDPI-csv-test-'+[guid]::NewGuid().ToString('N'))
try {
    [IO.Directory]::CreateDirectory($csvRoot)|Out-Null
    $csvPath=Join-Path $csvRoot 'analysis.csv'
    Write-GuiAnalysisCsv $csvData $csvPath
    $csvBytes=[IO.File]::ReadAllBytes($csvPath)
    Assert-Equal '239' ([string]$csvBytes[0]) 'CSV UTF-8 BOM first byte'
    Assert-Equal '187' ([string]$csvBytes[1]) 'CSV UTF-8 BOM second byte'
    Assert-Equal '191' ([string]$csvBytes[2]) 'CSV UTF-8 BOM third byte'
    $csvText=[IO.File]::ReadAllText($csvPath,[Text.Encoding]::UTF8)
    $csvRows=@($csvText|ConvertFrom-Csv -Delimiter ';')
    Assert-Equal 1 $csvRows.Count 'CSV export row count'
    Assert-Equal 'Example; "strategy"' $csvRows[0].StrategyName 'CSV preserves semicolons and quotes in strategy names'
    Assert-Equal 'Попытка 1; HTTP 200, текст "ok"' $csvRows[0].AttemptDetails 'CSV preserves semicolons and quotes in attempt details'
    Assert-Equal 'ошибка; строка "две"' $csvRows[0].Details 'CSV preserves semicolons and quotes in diagnostic details'
    Assert-Equal 'Не прошла тест YouTube' $csvRows[0].Recommendation 'CSV exports the displayed recommendation'
    $csvData.Results[0].Status='UNSTABLE'
    Write-GuiAnalysisCsv $csvData $csvPath
    $replacedRows=@(([IO.File]::ReadAllText($csvPath,[Text.Encoding]::UTF8)|ConvertFrom-Csv -Delimiter ';'))
    Assert-Equal 'UNSTABLE' $replacedRows[0].Status 're-export atomically replaces an existing CSV'
    Assert-Equal 0 @(Get-ChildItem -LiteralPath $csvRoot -Filter 'analysis.csv.*.tmp' -File).Count 'CSV export removes temporary files'
} finally {
    if(Test-Path -LiteralPath $csvRoot){Remove-Item -LiteralPath $csvRoot -Recurse -Force -ErrorAction SilentlyContinue}
}

Write-Host 'Windows regression checks passed.' -ForegroundColor Green
