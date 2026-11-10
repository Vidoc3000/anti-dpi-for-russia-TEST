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
Assert-True ($managerText.Contains("'AntiDPI_GUI.ps1'")) 'installer packages the Windows GUI'
Assert-True ($managerText.Contains("'GUI'{& (Join-Path `$PSScriptRoot 'AntiDPI_GUI.ps1')")) 'manager dispatches GUI action'
$launchLines = @($managerText -split '\r?\n' | Where-Object { $_.Contains("New-UserCommand (Join-Path `$ready '") -and $_.EndsWith("') 'GUI'") })
Assert-True ($launchLines.Count -eq 1) 'primary Windows launcher opens GUI'
Assert-True ($coreText.Contains('if($ListProfilesJson)')) 'profile catalogue provides JSON for the GUI'
Assert-True ($catalogueText.Contains('[switch]$ListProfilesJson')) 'catalogue exposes JSON listing switch'
$guiProfileJson = (& (Join-Path $repoRoot 'windows\payload\Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1') -ListProfilesJson | Out-String)
$guiProfiles = @($guiProfileJson | ConvertFrom-Json)
if ($guiProfiles.Count -eq 1 -and $guiProfiles[0] -is [array]) { $guiProfiles = @($guiProfiles[0]) }
Assert-Equal 492 $guiProfiles.Count 'GUI JSON profile list count'
$quicJson = (& (Join-Path $repoRoot 'windows\payload\Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1') -ListQuicProfilesJson | Out-String)
$quicProfiles = @($quicJson | ConvertFrom-Json)
if ($quicProfiles.Count -eq 1 -and $quicProfiles[0] -is [array]) { $quicProfiles = @($quicProfiles[0]) }
Assert-Equal 2 $quicProfiles.Count 'QUIC profile count'
Assert-Contains $quicProfiles[0].Args '--payload=quic_initial' 'QUIC Initial payload'
Assert-Contains $quicProfiles[0].Args '--lua-desync=fake:blob=fake_default_quic:repeats=2' 'QUIC fake recipe'
Assert-True ($guiText.Contains("Set-GuiProfileItems 'tls'")) 'GUI populates TCP profile selection'
Assert-True ($guiText.Contains("Set-GuiProfileItems ([string]`$protocolBox.SelectedItem.Value)")) 'GUI switches profiles by transport'
Assert-True ($guiText.Contains("Label='IPv6';Value='ipv6'")) 'GUI offers IPv6'
Assert-True ($guiText.Contains("Label='UDP + QUIC Initial (HTTP/3)';Value='quic'")) 'GUI offers UDP/QUIC'
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

Write-Host 'Windows regression checks passed.' -ForegroundColor Green
