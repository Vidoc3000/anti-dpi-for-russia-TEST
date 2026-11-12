#requires -Version 5.1
# Copyright (C) 2026 Igor Krauch (github.com/igareck). See the repository LICENSE.
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$OutputDirectory,
    [ValidatePattern('^[0-9]+\.[0-9]+(?:\.[0-9]+){0,2}$')][string]$Version = '1.9',
    [string]$CompilerPath,
    [ValidateRange(0,4294967295)][long]$SourceDateEpoch = 0,
    [switch]$ZipOnly,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression

function Resolve-PlatformSource([string]$Directory) {
    if (Test-Path -LiteralPath (Join-Path $Directory 'AntiDPI_Manager.ps1') -PathType Leaf) {
        return [IO.Path]::GetFullPath($Directory)
    }
    $candidates = @(Get-ChildItem -LiteralPath $Directory -Directory -ErrorAction Stop | Where-Object {
        $_.Name -match '^AntiDPI_CLI_v[0-9.]+_Windows_x64$' -and
        (Test-Path -LiteralPath (Join-Path $_.FullName 'AntiDPI_Manager.ps1') -PathType Leaf)
    })
    if ($candidates.Count -eq 1) { return $candidates[0].FullName }
    throw 'В windows/ не найден исходный комплект. Поместите туда содержимое папки из Windows ZIP.'
}

function Get-SourceFiles([string]$Directory,[string]$Relative = '') {
    $excludedDirectories = @('.git','.svn','.venv','venv','node_modules','__pycache__','.pytest_cache',
        'dist','build','logs','_state','zapret-winws')
    foreach ($item in @(Get-ChildItem -LiteralPath $Directory -Force | Sort-Object Name)) {
        if ($item.PSIsContainer -and $item.Name.ToLowerInvariant() -in $excludedDirectories) { continue }
        if (-not $item.PSIsContainer -and ($item.Name -in @('.DS_Store','Thumbs.db','desktop.ini','.antidpi-install.json') -or
            $item.Name -match '\.(pyc|pyo|log|tmp)$|^SHA256SUMS|^Verification_')) { continue }
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw ('Ссылки и junction в исходном комплекте не поддерживаются: ' + $item.FullName)
        }
        $name = if ($Relative) { $Relative + '/' + $item.Name } else { $item.Name }
        if ($item.PSIsContainer) { Get-SourceFiles $item.FullName $name }
        else { [pscustomobject]@{ Relative = $name; Source = $item.FullName } }
    }
}

function Add-PackageFile($Table,[string]$Name,[string]$Source) {
    if ($Table.ContainsKey($Name)) {
        $existing = @($Table.Keys | Where-Object { [string]::Equals($_,$Name,[StringComparison]::OrdinalIgnoreCase) })[0]
        if (-not [string]::Equals($existing,$Name,[StringComparison]::Ordinal)) {
            throw ('Конфликт регистра имён файлов: ' + $existing + ' / ' + $Name)
        }
        if ((Get-FileHash -LiteralPath $Table[$Name] -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash) {
            throw ('Конфликт разных файлов с одним путём в пакете: ' + $Name)
        }
        return
    }
    $Table.Add($Name,$Source)
}

function Assert-WindowsNames($Table) {
    foreach ($name in $Table.Keys) {
        $parts = $name.Split('/')
        foreach ($part in $parts) {
            if (-not $part -or $part -eq '.' -or $part -eq '..' -or $part -match '[ .]$|[\x00-\x1f\\:*?"<>|]' -or
                $part -match '^(CON|PRN|AUX|NUL|COM[1-9\u00b9\u00b2\u00b3]|LPT[1-9\u00b9\u00b2\u00b3])(?:\.|$)') {
                throw ('Имя файла несовместимо с Windows: ' + $name)
            }
        }
        for ($i = 1; $i -lt $parts.Length; $i++) {
            if ($Table.ContainsKey(($parts[0..($i-1)] -join '/'))) { throw ('Конфликт файла и папки: ' + $name) }
        }
    }
}

function Write-PackageZip($Table,[string]$RootName,[string]$Destination,[long]$Epoch) {
    [string[]]$names = @($Table.Keys)
    [Array]::Sort($names,[StringComparer]::Ordinal)
    $stamp = [DateTimeOffset]::FromUnixTimeSeconds($Epoch)
    if ($stamp.Year -lt 1980) { $stamp = [DateTimeOffset]::new(1980,1,1,0,0,0,[TimeSpan]::Zero) }
    if ($stamp.Year -gt 2107) { $stamp = [DateTimeOffset]::new(2107,12,31,23,59,58,[TimeSpan]::Zero) }
    $file = [IO.File]::Open($Destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $zip = $null
    try {
        $zip = [IO.Compression.ZipArchive]::new($file,[IO.Compression.ZipArchiveMode]::Create,$true,[Text.Encoding]::UTF8)
        foreach ($name in $names) {
            $entry = $zip.CreateEntry($RootName + '/' + $name,[IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $stamp
            $entry.ExternalAttributes = ([int]33188 -shl 16) # Unix regular file, 0644.
            $inputFile = [IO.File]::OpenRead($Table[$name]);$outputFile = $null
            try { $outputFile = $entry.Open();$inputFile.CopyTo($outputFile) }
            finally { if ($null -ne $outputFile) { $outputFile.Dispose() };$inputFile.Dispose() }
        }
    } finally { if ($null -ne $zip) { $zip.Dispose() };$file.Dispose() }
    if ((Get-Item -LiteralPath $Destination).Length -gt 67108864) { throw 'ZIP превышает лимит EXE-запускателя: 64 МиБ.' }
}

function Invoke-SetupCompiler([string]$Compiler,[string]$Framework,[string]$SourceDirectory,
    [string]$Workspace,[string]$ZipPath,[string]$ExePath,[string]$RootName,[string]$ProductVersion,[string]$Icon) {
    $numbers = @($ProductVersion.Split('.') | ForEach-Object { [int]$_ })
    foreach ($number in $numbers) { if ($number -gt 65534) { throw 'Компоненты версии должны быть не больше 65534.' } }
    while ($numbers.Count -lt 4) { $numbers += 0 }
    $assemblyVersion = $numbers -join '.'
    $hash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $infoPath = Join-Path $Workspace 'BuildInfo.g.cs'
    $info = @(
        'using System.Reflection;',
        '[assembly: AssemblyTitle("AntiDPI CLI Setup")]',
        '[assembly: AssemblyDescription("AntiDPI CLI for Windows 10/11 x64")]',
        '[assembly: AssemblyCompany("Igor Krauch (github.com/igareck)")]',
        '[assembly: AssemblyProduct("AntiDPI CLI")]',
        '[assembly: AssemblyCopyright("Igor Krauch (github.com/igareck)")]',
        ('[assembly: AssemblyVersion("' + $assemblyVersion + '")]'),
        ('[assembly: AssemblyFileVersion("' + $assemblyVersion + '")]'),
        ('[assembly: AssemblyInformationalVersion("' + $ProductVersion + '")]'),
        'namespace AntiDPI.Setup { internal static class BuildInfo {',
        ('internal const string Version = "' + $ProductVersion + '";'),
        ('internal const string PayloadRoot = "' + $RootName + '";'),
        ('internal const string PayloadSha256 = "' + $hash + '";'),
        'internal const string ResourceName = "AntiDPI.Payload.Zip";',
        '} }'
    ) -join "`r`n"
    [IO.File]::WriteAllText($infoPath,$info,[Text.UTF8Encoding]::new($true))
    $manifestPath = Join-Path $Workspace 'app.manifest'
    [xml]$manifest = [IO.File]::ReadAllText((Join-Path $SourceDirectory 'app.manifest'))
    $identity = $manifest.SelectSingleNode("/*[local-name()='assembly']/*[local-name()='assemblyIdentity']")
    $identity.SetAttribute('version',$assemblyVersion)
    $manifest.Save($manifestPath)
    $compilerArguments = @('/nologo','/target:winexe','/platform:x64','/optimize+','/checked+',
        '/utf8output','/codepage:65001','/langversion:5',('/out:' + $ExePath),
        ('/win32manifest:' + $manifestPath),('/win32icon:' + $Icon),
        ('/resource:' + $ZipPath + ',AntiDPI.Payload.Zip'),
        ('/reference:' + (Join-Path $Framework 'System.dll')),
        ('/reference:' + (Join-Path $Framework 'System.Core.dll')),
        ('/reference:' + (Join-Path $Framework 'System.IO.Compression.dll')),
        (Join-Path $SourceDirectory 'Setup.cs'),$infoPath)
    & $Compiler @compilerArguments | Out-Host
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ExePath -PathType Leaf)) {
        throw ('Компилятор C# завершился с ошибкой: ' + $LASTEXITCODE)
    }
    # Load bytes, not a path: verification must not lock the generated EXE.
    $assembly = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($ExePath))
    $resourceNames = @($assembly.GetManifestResourceNames())
    if ($resourceNames.Count -ne 1 -or $resourceNames[0] -ne 'AntiDPI.Payload.Zip') { throw 'Некорректный ресурс EXE.' }
    $resource = $assembly.GetManifestResourceStream('AntiDPI.Payload.Zip');$sha = [Security.Cryptography.SHA256]::Create()
    try { $actual = [BitConverter]::ToString($sha.ComputeHash($resource)).Replace('-','').ToLowerInvariant() }
    finally { $resource.Dispose();$sha.Dispose() }
    if ($actual -ne $hash) { throw 'Встроенный ZIP не совпадает с отдельным ZIP.' }
    $attributes = @($assembly.GetCustomAttributesData() | Where-Object { $_.AttributeType.Name -eq 'AssemblyCopyrightAttribute' })
    if ($attributes.Count -ne 1 -or $attributes[0].ConstructorArguments[0].Value -ne 'Igor Krauch (github.com/igareck)') {
        throw 'Некорректные метаданные авторства EXE.'
    }
}

function Publish-BuildFile([string]$Source,[string]$Destination,[bool]$AllowReplace) {
    $temporary = Join-Path (Split-Path -Parent $Destination) ('.ig-publish-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::Copy($Source,$temporary,$false)
        if ($AllowReplace -and [IO.File]::Exists($Destination)) { [IO.File]::Replace($temporary,$Destination,[NullString]::Value) }
        else { [IO.File]::Move($temporary,$Destination) }
    } finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
}

$resolvedRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$platformDirectory = Join-Path $resolvedRoot 'windows'
if (-not (Test-Path -LiteralPath $platformDirectory -PathType Container)) { throw ('Не найдена папка: ' + $platformDirectory) }
$sourceRoot = Resolve-PlatformSource $platformDirectory
foreach ($relative in @('УСТАНОВКА.cmd','AntiDPI_Installer.ps1','payload/AntiDPI_Zapret2.ico','payload/AntiDPI_Launcher_Core_20261023_public_v1.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $relative) -PathType Leaf)) { throw ('Не найден обязательный файл: ' + $relative) }
}
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $resolvedRoot 'dist' }
$resolvedOutput = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd([IO.Path]::DirectorySeparatorChar)
foreach ($protected in @($platformDirectory,(Join-Path $resolvedRoot 'linux'),(Join-Path $resolvedRoot 'packaging'))) {
    $protected = [IO.Path]::GetFullPath($protected).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if ($resolvedOutput -eq $protected -or $resolvedOutput.StartsWith($protected + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Папка результатов не должна находиться внутри windows/, linux/ или packaging/.'
    }
}
if ($resolvedOutput -eq $resolvedRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) -or $resolvedOutput -eq [IO.Path]::GetPathRoot($resolvedOutput).TrimEnd([IO.Path]::DirectorySeparatorChar)) {
    throw 'Укажите отдельную папку для результатов, например dist/.'
}
if (-not $PSBoundParameters.ContainsKey('SourceDateEpoch') -and $env:SOURCE_DATE_EPOCH) {
    if ($env:SOURCE_DATE_EPOCH -notmatch '^[0-9]+$') { throw 'SOURCE_DATE_EPOCH должен быть целым неотрицательным числом.' }
    $SourceDateEpoch = [long]$env:SOURCE_DATE_EPOCH
    if ($SourceDateEpoch -gt 4294967295) { throw 'SOURCE_DATE_EPOCH превышает допустимый диапазон.' }
}
$packageFiles = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($file in @(Get-SourceFiles $sourceRoot)) { Add-PackageFile $packageFiles $file.Relative $file.Source }
$licenseCandidates = @('LICENSE','LICENSE.txt') | ForEach-Object { Join-Path $resolvedRoot $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
$licenseCandidates = @($licenseCandidates)
if ($licenseCandidates.Count -eq 0) { throw 'В корне репозитория нужен основной файл LICENSE или LICENSE.txt.' }
if ($licenseCandidates.Count -eq 2 -and (Get-FileHash -LiteralPath $licenseCandidates[0]).Hash -ne (Get-FileHash -LiteralPath $licenseCandidates[1]).Hash) {
    throw 'В корне обнаружены разные LICENSE и LICENSE.txt. Оставьте один однозначный основной текст.'
}
Add-PackageFile $packageFiles 'LICENSE' $licenseCandidates[0]
$notices = Join-Path $resolvedRoot 'THIRD_PARTY_NOTICES.md'
$thirdPartyDirectory = Join-Path $resolvedRoot 'licenses'
if (-not (Test-Path -LiteralPath $notices -PathType Leaf) -or -not (Test-Path -LiteralPath $thirdPartyDirectory -PathType Container)) {
    throw 'В корне нужны THIRD_PARTY_NOTICES.md и папка licenses/.'
}
Add-PackageFile $packageFiles 'THIRD_PARTY_NOTICES.md' $notices
$thirdPartyFiles = @(Get-SourceFiles $thirdPartyDirectory)
if ($thirdPartyFiles.Count -eq 0) { throw 'Папка licenses/ пуста.' }
foreach ($file in $thirdPartyFiles) { Add-PackageFile $packageFiles ('licenses/' + $file.Relative) $file.Source }
Assert-WindowsNames $packageFiles
if ($packageFiles.Count -gt 10000) { throw 'Слишком много файлов для встроенного ZIP.' }
$expandedBytes = [long]0
foreach ($path in $packageFiles.Values) { $expandedBytes += (Get-Item -LiteralPath $path).Length }
if ($expandedBytes -gt 536870912) { throw 'Размер исходного комплекта превышает 512 МиБ.' }

$compiler = $null;$framework = $null
if (-not $ZipOnly) {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'EXE собирается на Windows. Для одного ZIP используйте -ZipOnly.' }
    $framework = Join-Path ([Environment]::GetFolderPath('Windows')) 'Microsoft.NET/Framework64/v4.0.30319'
    $compiler = if ($CompilerPath) { [IO.Path]::GetFullPath($CompilerPath) } else { Join-Path $framework 'csc.exe' }
    foreach ($required in @($compiler,(Join-Path $framework 'System.IO.Compression.dll'))) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw ('Не найден компонент .NET Framework для сборки: ' + $required) }
    }
}
$rootName = 'AntiDPI_CLI_v' + $Version + '_Windows_x64'
$zipName = $rootName + '.zip';$exeName = $rootName + '.exe'
$sumsName = if ($ZipOnly) { 'SHA256SUMS_Windows_ZIP_v' + $Version + '.txt' } else { 'SHA256SUMS_Windows_v' + $Version + '.txt' }
$selectedNames = @($zipName,$sumsName)
if (-not $ZipOnly) { $selectedNames += $exeName }
foreach ($name in $selectedNames) {
    if ((Test-Path -LiteralPath (Join-Path $resolvedOutput $name)) -and -not $Force) { throw ('Файл уже существует: ' + $name + '. Для пересборки используйте -Force.') }
}
[IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null
$workspace = Join-Path ([IO.Path]::GetTempPath()) ('ig-build-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($workspace) | Out-Null
try {
    $zipPath = Join-Path $workspace $zipName
    Write-PackageZip $packageFiles $rootName $zipPath $SourceDateEpoch
    $artifacts = @($zipName)
    if (-not $ZipOnly) {
        Invoke-SetupCompiler $compiler $framework $PSScriptRoot $workspace $zipPath (Join-Path $workspace $exeName) $rootName $Version (Join-Path $sourceRoot 'payload/AntiDPI_Zapret2.ico')
        $artifacts += $exeName
    }
    $lines = @($artifacts | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $workspace $_) -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + $_ })
    [IO.File]::WriteAllText((Join-Path $workspace $sumsName),(($lines -join "`n") + "`n"),[Text.UTF8Encoding]::new($false))
    foreach ($name in @($artifacts) + @($sumsName)) {
        Publish-BuildFile (Join-Path $workspace $name) (Join-Path $resolvedOutput $name) ([bool]$Force)
        Write-Host ('Создано: ' + (Join-Path $resolvedOutput $name))
    }
    if ($ZipOnly) { Write-Host 'Собран только ZIP. EXE этой командой не создавался.' }
} finally {
    if (Test-Path -LiteralPath $workspace) { Remove-Item -LiteralPath $workspace -Recurse -Force }
}
