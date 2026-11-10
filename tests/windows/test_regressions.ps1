$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$corePath = Join-Path $repoRoot 'windows\payload\Igareck_Launcher_Core_20261023_public_v1.ps1'
$IgareckLibraryOnly = $true
. $corePath
$IgareckLibraryOnly = $false

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

# Port-scope normalization and validation.
Assert-Equal 'all' (ConvertTo-IgareckPortScope '') 'empty scope defaults to all'
Assert-Equal 'all' (ConvertTo-IgareckPortScope '0-65535') 'full range canonicalizes to all'
Assert-Equal '80-81,443' (ConvertTo-IgareckPortScope '443,80-81,80') 'ranges sort and merge'
Assert-True (Test-IgareckScopePort '80-81,443' 443) 'selected destination port matches'
Assert-True (-not (Test-IgareckScopePort '80-81,443' 8443)) 'unselected destination port is excluded'
Assert-Throws { ConvertTo-IgareckPortScope '65536' } 'port above maximum'
Assert-Throws { ConvertTo-IgareckPortScope '100-80' } 'descending port range'
Assert-Throws { ConvertTo-IgareckPortScope '443,,80' } 'empty list member'

# Engine argument construction must preserve the IPv4/TCP/TLS and port filters.
$row = [pscustomobject]@{ Args = @('--payload=tls_client_hello'); Init = $null }
$singlePort = @(Get-IgareckArguments -Row $row -Index 12 -PortScope '443')
Assert-Contains $singlePort '--wf-l3=ipv4' 'IPv4 layer filter'
Assert-Contains $singlePort '--wf-iface=12' 'adapter filter'
Assert-Contains $singlePort '--wf-tcp-out=443' 'outbound TCP scope'
Assert-Contains $singlePort '--filter-tcp=443' 'engine TCP scope'
Assert-Contains $singlePort '--filter-l7=tls' 'TLS application filter'

$allPorts = @(Get-IgareckArguments -Row $row -Index 12 -PortScope 'all')
Assert-Contains $allPorts '--wf-tcp-out=0-65535' 'all TCP port scope'
Assert-Contains $allPorts '--filter-tcp=0-65535' 'engine all-port scope'

$probeArgs = @(Get-IgareckArguments -Row $row -Index 12 -PortScope '443' -ProbePorts @(45001, 45002))
$rawFilter = $probeArgs | Where-Object { $_ -like '--wf-raw-filter=*' }
Assert-True ($rawFilter -like '*tcp.SrcPort == 45001*' -and $rawFilter -like '*tcp.SrcPort == 45002*') 'probe source-port isolation'
Assert-True ($rawFilter -like '*tcp.DstPort == 45001*' -and $rawFilter -like '*tcp.DstPort == 45002*') 'probe reverse-flow isolation'

Write-Host 'Windows regression checks passed.' -ForegroundColor Green
