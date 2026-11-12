#requires -Version 5.1
[CmdletBinding()]
param(
 [ValidateSet('Install','Launch','GUI','Uninstall')][string]$Action='Install',[switch]$SkipHeader,
 [string]$InstallPath='', [string]$BundleSelection='', [string]$CreateShortcutChoice='', [switch]$NonInteractiveInstaller)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$payload=if(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'payload')){Join-Path $PSScriptRoot 'payload'}else{$PSScriptRoot}
$AntiDPILibraryOnly=$true
. (Join-Path $payload 'AntiDPI_Launcher_Core_20261023_public_v1.ps1')
$AntiDPILibraryOnly=$false
$script:AntiDPITranscriptActive=$false
$script:AntiDPITranscriptPath=''
$script:AntiDPIInstalledRoot=''
$script:AntiDPIInstallerNonInteractive=[bool]$NonInteractiveInstaller
function Test-ChildPath([string]$Root,[string]$Candidate) {
    $r=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    return [IO.Path]::GetFullPath($Candidate).StartsWith($r,[StringComparison]::OrdinalIgnoreCase)
}
function Read-InstallManifest {
    $root=Split-Path -Parent $PSScriptRoot;$path=Join-Path $root '.antidpi-install.json'
    if(-not (Test-Path -LiteralPath $path -PathType Leaf)){throw 'Маркер установки не найден. Автоматическое удаление не выполняется.'}
    $m=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
    if($m.Schema -ne 'antidpi.zapret.install.v1' -or [IO.Path]::GetFullPath($m.InstallRoot) -ine [IO.Path]::GetFullPath($root)){throw 'Маркер установки не соответствует этой папке.'}
    foreach($f in $m.Files){if([IO.Path]::IsPathRooted($f.Path) -or -not (Test-ChildPath $root (Join-Path $root $f.Path))){throw 'Некорректный путь в списке установленных файлов.'}}
    return $m
}
function Stop-OwnedWinws($Manifest) {
    $record=Join-Path $Manifest.InstallRoot 'AntiDPI\_state\owned_process.json'
    if(-not (Test-Path -LiteralPath $record)){return}
    try{$r=Get-Content -LiteralPath $record -Raw|ConvertFrom-Json}
    catch{if(-not (Test-Path -LiteralPath $record)){return};throw}
    $p=Get-Process -Id $r.PID -ErrorAction SilentlyContinue
    if($p){
        if(-not (Test-ChildPath $Manifest.InstallRoot $r.Exe) -or $p.Path -ine $r.Exe -or $p.StartTime.ToUniversalTime().ToString('o') -ne $r.StartUTC){throw 'PID из маркера уже принадлежит другому процессу. Он не остановлен.'}
        Stop-Process -Id $p.Id -Force;$p.WaitForExit(5000)|Out-Null
    }
    Remove-Item -LiteralPath $record -Force
}
function Assert-AntiDPIPathLength([string]$Path,[switch]$Directory) {
    $limit=if($Directory){247}else{259}
    if([IO.Path]::GetFullPath($Path).Length -gt $limit){
        throw ('Слишком длинный путь для Windows: '+$Path+'. Выберите более короткую папку установки.')
    }
}
function New-AntiDPIShortDirectory {
    # A private, uniquely created working directory independent of a long user TEMP.
    $parents=@([IO.Path]::GetPathRoot([Environment]::GetFolderPath('Windows')),
        [Environment]::GetFolderPath('CommonApplicationData')) | Select-Object -Unique
    $lastError=''
    foreach($parent in $parents){
        if(-not $parent){continue}
        for($attempt=0;$attempt -lt 8;$attempt++){
            $path=Join-Path $parent ('.ig-'+[guid]::NewGuid().ToString('N').Substring(0,12))
            if(Test-Path -LiteralPath $path){continue}
            $created=$false
            try{
                New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
                $created=$true
                $acl=[Security.AccessControl.DirectorySecurity]::new()
                $acl.SetAccessRuleProtection($true,$false)
                $sids=@([Security.Principal.WindowsIdentity]::GetCurrent().User.Value,'S-1-5-18','S-1-5-32-544') | Select-Object -Unique
                foreach($sid in $sids){
                    $identity=[Security.Principal.SecurityIdentifier]::new($sid)
                    $rule=[Security.AccessControl.FileSystemAccessRule]::new($identity,
                        [Security.AccessControl.FileSystemRights]::FullControl,
                        ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit),
                        [Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow)
                    $acl.AddAccessRule($rule)
                }
                Set-Acl -LiteralPath $path -AclObject $acl -ErrorAction Stop
                return $path
            }catch{
                $lastError=$_.Exception.Message
                if($created){Remove-AntiDPITemporaryDirectory $path}
                break
            }
        }
    }
    throw ('Не удалось создать короткую временную папку установщика: '+$lastError)
}
function Assert-AntiDPIBundlePaths([string]$Source,[string]$Destination) {
    Assert-AntiDPIPathLength $Destination -Directory
    foreach($file in Get-ChildItem -LiteralPath $Source -Force -Recurse){
        $relative=$file.FullName.Substring($Source.TrimEnd('\','/').Length+1)
        $target=Join-Path $Destination $relative
        Assert-AntiDPIPathLength $target -Directory:$file.PSIsContainer
    }
}
function Expand-VerifiedBundle([string]$Zip,[string]$Destination,[string]$ArchiveRoot) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if($ArchiveRoot -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$'){throw 'Некорректный корень официального архива.'}
    $prefix=$ArchiveRoot+'/'
    $z=[IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $entries=[Collections.Generic.List[object]]::new()
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        # Validate every original entry before creating any extracted file.
        foreach($entry in $z.Entries){
            $name=$entry.FullName
            if(-not $name.StartsWith($prefix,[StringComparison]::Ordinal) -or $name.Contains('\')){throw 'Неожиданный корень или путь официального архива.'}
            $relative=$name.Substring($prefix.Length)
            if(-not $relative){continue}
            if($relative.Contains(':') -or $relative -match '(^|/)[.]{1,2}(/|$)'){throw 'Недопустимый путь внутри архива.'}
            $full=Join-Path $Destination ($relative.Replace('/',[IO.Path]::DirectorySeparatorChar))
            if(-not (Test-ChildPath $Destination $full)){throw 'Недопустимый путь внутри архива.'}
            if(-not $seen.Add($full.TrimEnd('\','/'))){throw 'Повторяющийся путь внутри архива.'}
            if((($entry.ExternalAttributes -shr 16) -band 61440) -eq 40960){throw 'Символическая ссылка в архиве запрещена.'}
            $directory=$name.EndsWith('/')
            Assert-AntiDPIPathLength $full -Directory:$directory
            if(-not $directory){Assert-AntiDPIPathLength (Split-Path -Parent $full) -Directory}
            $entries.Add([pscustomobject]@{Entry=$entry;Path=$full;Directory=$directory})
        }
        foreach($item in $entries){
            if($item.Directory){[IO.Directory]::CreateDirectory($item.Path)|Out-Null;continue}
            [IO.Directory]::CreateDirectory((Split-Path -Parent $item.Path))|Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($item.Entry,$item.Path,$false)
        }
    }finally{$z.Dispose()}
}
function New-UserCommand([string]$Path,[string]$Mode) {
    $text='@echo off'+"`r`n"+'start "" "%SystemRoot%\System32\conhost.exe" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0AntiDPI\AntiDPI_Manager.ps1" -Action '+$Mode+"`r`n"+'if errorlevel 1 pause'+"`r`n"
    [IO.File]::WriteAllText($Path,$text,[Text.Encoding]::ASCII)
}
function Write-AntiDPIBusyDirectory([string]$Reason='') {
    Write-Host 'Папка уже занята, выберите другую папку или удалите текущую!' -ForegroundColor Yellow
    if($Reason){Write-Host ('Причина: '+$Reason) -ForegroundColor DarkYellow}
}
function Move-AntiDPIPreparedDirectory([string]$Prepared,[string]$Destination) {
    # Atomic same-volume rename. Unlike Move-Item, never nests inside a target
    # directory that another process happened to create after our last check.
    [IO.Directory]::Move($Prepared,$Destination)
}
function Read-AntiDPIInstallDirectory {
    while($true){
        $answer=Read-AntiDPIInstallPathInput
        $answer=([string]$answer).Trim().Trim('"').Trim()
        if([string]::IsNullOrWhiteSpace($answer) -or $answer -match '^(?i:C):[\\/]+$'){$answer='C:\AntiDPI'}
        try{$candidate=[IO.Path]::GetFullPath($answer)}catch{Write-Host 'Неверный путь.';continue}
        if(-not [IO.Path]::IsPathRooted($answer) -or $candidate -eq [IO.Path]::GetPathRoot($candidate)){
            Write-Host 'Укажите отдельную абсолютную папку.';continue
        }
        try{
            if(Test-Path -LiteralPath $candidate){
                if(-not (Test-Path -LiteralPath $candidate -PathType Container)){
                    Write-AntiDPIBusyDirectory 'Этот путь занят файлом.';continue
                }
                if(@(Get-ChildItem -LiteralPath $candidate -Force -ErrorAction Stop).Count){
                    Write-AntiDPIBusyDirectory;continue
                }
            }
            return $candidate
        }catch{Write-AntiDPIBusyDirectory $_.Exception.Message}
    }
}
function Show-AntiDPIAntivirusNotice([switch]$Installing) {
    Write-Host 'БЕЗОПАСНОСТЬ УСТАНОВКИ' -ForegroundColor Yellow
    Write-Host 'Установщик не отключает антивирус и не добавляет широкие исключения.' -ForegroundColor Yellow
    Write-Host 'Если защитное ПО блокирует файл, проверьте сообщение и SHA-256 релизного архива; не продолжайте при сомнении.' -ForegroundColor Yellow
    Write-Host 'Windows Firewall получает только узкое исходящее правило для проверенного winws2.exe этой установки.' -ForegroundColor Yellow
    if(-not $Installing){Write-Host 'Исключения для VPN-клиентов, если они вообще нужны, настраиваются отдельно по рекомендациям их разработчика.' -ForegroundColor Yellow}
    Write-Host ''
    Write-Host '----------------------'
    Write-Host ''
    if(-not $script:AntiDPIInstallerNonInteractive){Wait-AntiDPIEnter 'Нажмите Enter, чтобы продолжить и прочитать ЗАМЕТКИ'}
    $notes=@(
        'ЗАМЕТКИ:',
        '1. Программа с готовыми AntiDPI стратегиями разработана специально для восстановления работоспособности VPN-конфигураций Черных Списков, Tor и YouTube.',
        '2. Для работы с VPN Черных Списков или Tor включайте каждую стратегию поочередно, затем пингуйте подписки/мосты в вашем клиенте!',
        '   На одних стратегиях будет больше живых VPN-конфигураций, на других меньше.',
        '3. Для работы с YouTube следуйте инструкциям ниже и запустите автоматическую проверку стратегий на доступ к YouTube.',
        '   VPN для доступа к YouTube не требуется. YouTube работает напрямую из вашей сети вместе с AntiDPI стратегиями.',
        '4. Успешный тест на доступ к YouTube не всегда означает, что стратегия идеально работает с VPN-конфигурациями.',
        '   В свою очередь — отрицательный тест на YouTube абсолютно не значит, что стратегия не работает с VPN, часто наоборот.',
        '   Бывает, что стратегия не дает прямой доступ на YouTube, но при этом пингует самое максимальное число VPN-конфигураций.',
        '5. Стратегии Golden для VPN/Tor/YouTube могут работать лучше, чем Silver.',
        '6. Набор стратегий протестирован на российских кабельных/мобильных сетях.'
    )
    # A physical newline marks a paragraph; the console performs soft wrapping.
    foreach($note in $notes){Write-Host $note -ForegroundColor Yellow}
    Write-Host ''
    Write-Host '----------------------'
    Write-Host ''
    if(-not $script:AntiDPIInstallerNonInteractive){
        if($Installing){Wait-AntiDPIEnter 'Нажмите Enter, чтобы продолжить установку'}
        else{Wait-AntiDPIEnter 'Нажмите Enter, чтобы продолжить работу'}
    }
}
function Wait-AntiDPIEnter([string]$Message) {
    Initialize-AntiDPIRuntime
    Write-Host $Message
    if(-not [AntiDPI.Public10.ConsoleEnterPause]::Wait()){
        throw [OperationCanceledException]::new('Работа остановлена пользователем.')
    }
    Write-Host ''
}

function Test-AntiDPIAntivirusBlock($Failure) {
    # Win32 225/226 survive localized messages and nested PowerShell exceptions.
    $errorObject=$Failure
    if($errorObject -is [Management.Automation.ErrorRecord]){$errorObject=$errorObject.Exception}
    while($null -ne $errorObject){
        if($errorObject -is [Exception]){
            $code=([long]$errorObject.HResult -band 65535)
            if($code -eq 225 -or $code -eq 226){return $true}
            if($errorObject -is [ComponentModel.Win32Exception] -and $errorObject.NativeErrorCode -in @(225,226)){return $true}
            if($errorObject.Message -match '(?i)virus|вирус|potentially unwanted|потенциально нежелательн'){return $true}
            $errorObject=$errorObject.InnerException
        }else{break}
    }
    return $false
}
function Read-AntiDPIBundleRetry($Failure) {
    if($script:AntiDPIInstallerNonInteractive){throw ('Установка остановлена без интерактивного повтора: '+$Failure.Exception.Message)}
    Write-Host ('ОШИБКА: '+$Failure.Exception.Message) -ForegroundColor Red
    Write-Host ''
    Write-Host 'Выберите 1 или 2.'
    Write-Host '1 - попытаться повторно загрузить (перед эти шагом отключите антивирус)'
    Write-Host '2 - выйти из программы'
    while($true){
        $answer=(Read-AntiDPIChoice).Trim()
        if($answer -eq '1'){return $true}
        if($answer -eq '2'){return $false}
        Write-Host 'Введите 1 или 2.' -ForegroundColor Yellow
    }
}
function Remove-AntiDPITemporaryDirectory([string]$Path) {
    if(-not $Path){return}
    try{if(Test-Path -LiteralPath $Path){Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop}}
    catch{Write-Verbose ('Не удалось очистить временную папку '+$Path+': '+$_.Exception.Message)}
}
function Get-AntiDPIVerifiedBundle($Meta,[string]$Selection,[string]$Url,[string]$Stage) {
    while($true){
        # A retry never reuses a quarantined ZIP or partially extracted directory.
        $attempt=Join-Path $Stage ('d-'+[guid]::NewGuid().ToString('N').Substring(0,8))
        [IO.Directory]::CreateDirectory($attempt)|Out-Null
        $complete=$false
        try{
            $zip=Join-Path $attempt 'b.zip'
            $branchArchive=([string]$Meta.commit -notmatch '^[0-9a-f]{40}$')
            if($branchArchive){Write-Host 'Скачиваю последнюю версию официальной ветки master bol-van.'}
            else{Write-Host ('Скачиваю официальный Windows Bundle bol-van: '+$Meta.commit)}
            $mirror=Get-AntiDPIBundleMirrorUrl ([string]$Meta.commit)
            $download=Invoke-AntiDPIBundleDownload -Url $Url -AlternativeUrls @($mirror) -Destination $zip -ExpectedBytes ([long]$Meta.bytes)
            $hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
            if($Selection -eq 'Compatible'){
                Write-Host 'Проверяю SHA-256...'
                if($hash -cne $Meta.sha256){throw 'SHA-256 архива не совпал. Установка остановлена.'}
            }
            $archiveRef=if($branchArchive){'master'}else{[string]$Meta.commit}
            $commit=[string]$Meta.commit
            if($branchArchive){
                Initialize-AntiDPIRuntime
                $commit=[AntiDPI.Public10.BundleArchiveInfo]::ReadCommit($zip)
                Write-Host ('Коммит загруженного архива master: '+$commit)
            }
            $selected=[ordered]@{repo=$Meta.repo;commit=$commit;commit_date=$Meta.commit_date;url=$Url;download_url=$download.Url;download_final_url=$download.FinalUrl;download_mirror=$download.Mirror;sha256=$hash;bytes=(Get-Item -LiteralPath $zip -ErrorAction Stop).Length;selection=$Selection;hash_verified_against_known_value=($Selection -eq 'Compatible');archive_ref=$archiveRef}
            Write-Host '----------------------'
            $unpacked=Join-Path $attempt 's';[IO.Directory]::CreateDirectory($unpacked)|Out-Null
            Expand-VerifiedBundle $zip $unpacked ('zapret-win-bundle-'+$archiveRef)
            $bundle=$unpacked
            if(-not (Test-Path -LiteralPath (Join-Path $bundle 'zapret-winws\winws2.exe'))){throw 'В официальном архиве отсутствует winws2.exe.'}
            $complete=$true
            return [pscustomobject]@{Bundle=$bundle;Hash=$hash;Metadata=$selected}
        }catch{
            if(-not (Test-AntiDPIAntivirusBlock $_)){throw}
            if(-not (Read-AntiDPIBundleRetry $_)){return $null}
        }finally{if(-not $complete){Remove-AntiDPITemporaryDirectory $attempt}}
    }
}

function Get-AntiDPIFirewallIdentity($Manifest) {
    $id=[guid]::Empty
    if(-not [guid]::TryParse([string]$Manifest.InstallID,[ref]$id) -or $id -eq [guid]::Empty){
        throw 'В маркере установки отсутствует корректный InstallID для правила Firewall.'
    }
    $tag=$id.ToString('N')
    return [pscustomobject]@{
        Name='AntiDPI-Zapret2-'+$tag+'-OUT'
        Group='AntiDPI-Zapret2-'+$tag
        Program=[IO.Path]::GetFullPath((Join-Path $Manifest.InstallRoot 'zapret-winws\winws2.exe'))
    }
}
function Set-AntiDPIFirewallRule($Manifest) {
    $rule=Get-AntiDPIFirewallIdentity $Manifest
    if(-not (Test-Path -LiteralPath $rule.Program -PathType Leaf)){
        throw ('Не найден установленный winws2.exe: '+$rule.Program)
    }
    Import-Module NetSecurity -ErrorAction Stop
    $existing=@(Get-NetFirewallRule -PolicyStore PersistentStore -ErrorAction Stop | Where-Object Name -eq $rule.Name)
    foreach($item in $existing){
        if($item.Group -cne $rule.Group){throw 'Имя правила Firewall занято посторонним правилом. Оно сохранено.'}
        $item|Remove-NetFirewallRule -ErrorAction Stop
    }
    $parameters=@{
        Name=$rule.Name
        DisplayName='AntiDPI Zapret2: winws2.exe (OUT)'
        Group=$rule.Group
        Program=$rule.Program
        Direction='Outbound'
        Action='Allow'
        Profile='Any'
        Protocol='Any'
        Enabled='True'
        PolicyStore='PersistentStore'
        Description='AntiDPI GUI + CLI Version 1.7. Исходящее разрешение только для winws2.exe этой установки.'
    }
    $created=New-NetFirewallRule @parameters -ErrorAction Stop
    $application=@($created|Get-NetFirewallApplicationFilter -ErrorAction Stop)
    if($application.Count -ne 1 -or $application[0].Program -ine $rule.Program){
        throw 'Не удалось подтвердить привязку правила Firewall к установленному winws2.exe.'
    }
    Write-Host ('Windows Firewall: добавлено исходящее разрешение для '+$rule.Program)
}
function Remove-AntiDPIFirewallRule($Manifest) {
    $rule=Get-AntiDPIFirewallIdentity $Manifest
    Import-Module NetSecurity -ErrorAction Stop
    $existing=@(Get-NetFirewallRule -PolicyStore PersistentStore -ErrorAction Stop | Where-Object Name -eq $rule.Name)
    foreach($item in $existing){
        if($item.Group -cne $rule.Group){throw 'Правило Firewall с этим именем принадлежит другой группе. Оно сохранено.'}
        $item|Remove-NetFirewallRule -ErrorAction Stop
    }
    Write-Host 'Собственное правило Windows Firewall этой установки удалено.'
}
function Get-AntiDPIBundleMirrorUrl([string]$Commit) {
    if([string]::IsNullOrEmpty($Commit)){$ref='refs/heads/master'}
    elseif($Commit -match '^[0-9a-f]{40}$'){$ref=$Commit}
    else{throw 'Некорректный идентификатор коммита для зеркала.'}
    return ('https://cdn.gh-proxy.org/https://github.com/bol-van/zapret-win-bundle/archive/'+$ref+'.zip')
}
function Write-AntiDPIDownloadProgress([string]$Source,[long]$Received,[long]$Total,[int]$Percent,[bool]$Estimated=$false) {
    # Append complete lines. A classic Write-Progress pane can overwrite the
    # catalogue when the buffer scrolls during installation or a YouTube scan.
    $filled=[int][Math]::Floor($Percent/5.0)
    $bar=('#'*$filled)+('-'*(20-$filled))
    $approx=if($Estimated -and $Percent -lt 100){'~'}else{''}
    Write-Host ('{0}: [{1}] {2}{3}% — {4:N1} / {2}{5:N1} МиБ' -f $Source,$bar,$approx,$Percent,($Received/1MB),($Total/1MB))
}
function Invoke-AntiDPIBundleDownload([string]$Url,[string]$Destination,[long]$ExpectedBytes=0,[string[]]$AlternativeUrls=@()) {
    Initialize-AntiDPIRuntime
    if(Test-Path -LiteralPath $Destination){throw 'Путь загружаемого архива уже занят.'}
    $sources=@($Url)+@($AlternativeUrls)
    $sourceIndex=0
    $windowSeconds=15
    $minimumPercent=3
    # A server may stream without Content-Length. In that case this is a size
    # estimate from the compatible bundle, not an independently known total.
    if($ExpectedBytes -le 0){$ExpectedBytes=19522338}
    while($true){
        $source=[string]$sources[$sourceIndex]
        $sourceName=if($sourceIndex -eq 0){'GitHub'}else{'cdn.gh-proxy.org'}
        $partial=$Destination+'.part_'+[guid]::NewGuid().ToString('N')
        $attempt=$null;$clock=$null;$reason=''
        Write-Host ('Источник: '+$sourceName)
        Write-AntiDPIDownloadProgress $sourceName 0 $ExpectedBytes 0 $true
        try{
            $clock=[Diagnostics.Stopwatch]::StartNew()
            $attempt=[AntiDPI.Public10.BundleDownloadAttempt]::new($source,$partial,$ExpectedBytes)
            $windowStart=[long]0;$windowBytes=[long]0;$lastUpdate=[long]0;$lastPercent=0
            while(-not $attempt.Task.IsCompleted){
                $elapsed=$clock.ElapsedMilliseconds
                $received=$attempt.ReceivedBytes;$total=$attempt.TotalBytes
                if($elapsed-$windowStart -ge ($windowSeconds*1000)){
                    $required=[long][Math]::Ceiling($total*$minimumPercent/100.0)
                    if(($received-$windowBytes) -lt $required){
                        $reason='Прирост меньше 3% за 15 секунд. Переключаю источник.'
                        $attempt.Abort();break
                    }
                    $windowStart=$elapsed;$windowBytes=$received
                }
                $percent=[int][Math]::Min(99,[Math]::Floor(100.0*$received/$total))
                if($elapsed-$lastUpdate -ge 5000 -or $percent-$lastPercent -ge 5){
                    Write-AntiDPIDownloadProgress $sourceName $received $total $percent (-not $attempt.SizeKnown)
                    $lastUpdate=$elapsed;$lastPercent=$percent
                }
                Start-Sleep -Milliseconds 100
            }
            if(-not $reason){
                $result=$attempt.Task.GetAwaiter().GetResult()
                if($result.Success){
                    $received=$attempt.ReceivedBytes
                    $attempt.Dispose();$attempt=$null
                    [IO.File]::Move($partial,$Destination)
                    Write-AntiDPIDownloadProgress $sourceName $received $received 100
                    Write-Host ('Скачано: 100% ({0:N1} МиБ).' -f ($received/1MB))
                    return [pscustomobject]@{Url=$source;FinalUrl=$result.FinalUrl;Mirror=$sourceName}
                }
                if((Test-AntiDPIAntivirusBlock $result.Error) -or $result.FailureKind -ne 'Network'){throw $result.Error}
                $reason='Ошибка загрузки: '+$result.Error.Message+'. Переключаю источник.'
            }
        }finally{
            if($null -ne $attempt){$attempt.Dispose()}
            try{if(Test-Path -LiteralPath $partial){Remove-Item -LiteralPath $partial -Force -ErrorAction Stop}}
            catch{Write-Verbose ('Не удалось удалить частичную загрузку: '+$_.Exception.Message)}
        }
        Write-Host $reason -ForegroundColor Yellow
        $sourceIndex=($sourceIndex+1)%$sources.Count
        Start-Sleep -Milliseconds 250
    }

}
function Invoke-AntiDPILicenseDownload([string]$Url,[string[]]$AlternativeUrls,[string]$Destination,[int]$TimeoutSeconds=5) {
    Initialize-AntiDPIRuntime
    if(Test-Path -LiteralPath $Destination){throw 'Путь файла лицензии уже занят.'}
    $sources=@($Url)+@($AlternativeUrls)
    $attemptLimit=3
    $lastError=''
    $acceptedBytes=$null
    for($number=0;$number -lt $attemptLimit;$number++){
        $source=[string]$sources[$number%$sources.Count]
        $attempt=$null
        Write-Host ('Источник лицензии: {0}; попытка {1}/{2}' -f $source,($number+1),$attemptLimit)
        try{
            # This is a UTF-8 text file, not a bundle ZIP. Keep network reads
            # cancellable and bounded independently of archive progress rules.
            $attempt=[AntiDPI.Public10.BundleDownloadAttempt]::new($source,'',1069,$false,65536)
            $clock=[Diagnostics.Stopwatch]::StartNew()
            while(-not $attempt.Task.IsCompleted){
                if($clock.Elapsed.TotalSeconds -ge $TimeoutSeconds){
                    $attempt.Abort()
                    throw [TimeoutException]::new('Истекло время загрузки лицензии.')
                }
                Start-Sleep -Milliseconds 100
            }
            $result=$attempt.Task.GetAwaiter().GetResult()
            if(-not $result.Success){
                if((Test-AntiDPIAntivirusBlock $result.Error) -or $result.FailureKind -eq 'File'){throw $result.Error}
                throw [IO.InvalidDataException]::new(('Ошибка загрузки лицензии: '+$result.Error.Message),$result.Error)
            }
            $attempt.Dispose();$attempt=$null
            $text=([Text.UTF8Encoding]::new($false,$true)).GetString($result.Content).TrimStart([char]0xfeff)
            if($text.Length -lt 500 -or $text.Length -gt 65536 -or -not $text.TrimStart().StartsWith('MIT License') -or $text -notmatch '(?i)Copyright.*bol-van' -or $text -notmatch 'Permission is hereby granted'){
                throw [IO.InvalidDataException]::new('Источник вернул некорректный текст лицензии Bol-Van.')
            }
            $acceptedBytes=$result.Content
            break
        }catch{
            if((Test-AntiDPIAntivirusBlock $_) -or $_.Exception -is [UnauthorizedAccessException]){throw}
            $lastError=$_.Exception.Message
            Write-Host $lastError -ForegroundColor Yellow
        }finally{
            if($null -ne $attempt){$attempt.Dispose()}
        }
    }
    if($null -eq $acceptedBytes){
        Write-Host ''
        Write-Host 'Неудачная попытка скачивания лицензии, для ознакомления самостоятельно перейдите по ссылке выше.'
        return $false
    }
    # The small licence is validated entirely in memory. No archive signatures,
    # size estimates, partial files or delayed temp-file writes are involved.
    $file=[IO.FileStream]::new($Destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$file.Write($acceptedBytes,0,$acceptedBytes.Length)}finally{$file.Dispose()}
    Write-Host ('Лицензия скачана и проверена ({0} байт).' -f $acceptedBytes.Length)
    return $true
}
function Get-AntiDPIBolVanLicense([string]$Destination) {
    $source='https://raw.githubusercontent.com/bol-van/zapret2/refs/heads/master/docs/LICENSE.txt'
    $mirror='https://cdn.gh-proxy.org/'+$source
    Write-Host 'Скачиваю лицензию Zapret2 Bol-Van.'
    Invoke-AntiDPILicenseDownload -Url $source -AlternativeUrls @($mirror) -Destination $Destination
}
function Install-AntiDPI {
    Show-AntiDPIAntivirusNotice -Installing
    if($InstallPath){
        $rawPath=([string]$InstallPath).Trim().Trim('"').Trim()
        try{$finalRoot=[IO.Path]::GetFullPath($rawPath)}catch{throw ('Некорректный путь установки: '+$_.Exception.Message)}
        if(-not [IO.Path]::IsPathRooted($rawPath) -or $finalRoot -eq [IO.Path]::GetPathRoot($finalRoot)){throw 'Укажите отдельную абсолютную папку установки.'}
        if(Test-Path -LiteralPath $finalRoot){
            if(-not (Test-Path -LiteralPath $finalRoot -PathType Container) -or @(Get-ChildItem -LiteralPath $finalRoot -Force -ErrorAction Stop).Count){throw 'Выбранная папка уже занята. Для установки выберите новую пустую папку.'}
        }
    }elseif($script:AntiDPIInstallerNonInteractive){throw 'Мастер установки не передал папку назначения.'}
    else{
        Write-Host 'Нажмите Enter для установки программы в C:\AntiDPI по умолчанию или укажите новую пустую папку.'
        $finalRoot=Read-AntiDPIInstallDirectory
    }
    if($BundleSelection){if($BundleSelection -notin @('Compatible','Latest')){throw 'Выбран неизвестный вариант Zapret2.'};$selection=$BundleSelection}
    elseif($script:AntiDPIInstallerNonInteractive){throw 'Не выбран вариант Zapret2 в мастере установки.'}
    else{$selection=Read-AntiDPIBundleSelection}
    if($CreateShortcutChoice){if($CreateShortcutChoice -notin @('Yes','No')){throw 'Некорректный выбор ярлыков.'};$createShortcut=($CreateShortcutChoice -eq 'Yes')}
    elseif($script:AntiDPIInstallerNonInteractive){throw 'Не задан выбор создания ярлыков.'}
    else{$createShortcut=Read-AntiDPIShortcutChoice}
    Write-Host '----------------------'
    $meta=Get-Content -LiteralPath (Join-Path $payload 'Official_Bundle_20261023_public_v1.json') -Raw -Encoding UTF8|ConvertFrom-Json
    if($meta.repo -cne 'bol-van/zapret-win-bundle' -or $meta.commit -notmatch '^[0-9a-f]{40}$' -or $meta.sha256 -notmatch '^[0-9a-f]{64}$'){throw 'Некорректные сведения об официальной сборке.'}
    if($selection -eq 'Latest'){$meta=Get-AntiDPILatestBundle -ExpectedBytes ([long]$meta.bytes)}
    $url=[string]$meta.url
    $stage=New-AntiDPIShortDirectory
    $ready=$null
    try{
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $verified=Get-AntiDPIVerifiedBundle $meta $selection $url $stage
        if($null -eq $verified){return}
        $bundle=$verified.Bundle;$downloadHash=$verified.Hash;$selectedMeta=$verified.Metadata
        $bolVanLicense=Join-Path $stage 'LICENSE_Bol-Van.txt'
        $bolVanLicenseDownloaded=Get-AntiDPIBolVanLicense $bolVanLicense
        $driverBefore=@(Get-CimInstance Win32_SystemDriver -Filter "Name='WinDivert'" -ErrorAction SilentlyContinue|Select-Object Name,PathName,State)
        while($true){
            # A path can become occupied while the archive is downloading.
            $needsAnother=$false;$reason=''
            try{
                if(Test-Path -LiteralPath $finalRoot){
                    if(-not (Test-Path -LiteralPath $finalRoot -PathType Container) -or @(Get-ChildItem -LiteralPath $finalRoot -Force -ErrorAction Stop).Count){$needsAnother=$true}
                }
                $parent=Split-Path -Parent $finalRoot
                if(-not $needsAnother){
                    Assert-AntiDPIBundlePaths $bundle $finalRoot
                    Assert-AntiDPIBundlePaths $bundle (Join-Path $parent '.ig-000000000000')
                    [IO.Directory]::CreateDirectory($parent)|Out-Null
                }
            }catch{$needsAnother=$true;$reason=$_.Exception.Message}
            if($needsAnother){
                Write-AntiDPIBusyDirectory $reason
                if($script:AntiDPIInstallerNonInteractive){throw ('Папка установки стала недоступна: '+$reason)}
                $finalRoot=Read-AntiDPIInstallDirectory;continue
            }
            $retry=$false;$retryDownload=$false
            $ready=Join-Path $parent ('.ig-'+[guid]::NewGuid().ToString('N').Substring(0,12))
            try{
                [IO.Directory]::CreateDirectory($ready)|Out-Null
                # Keep verified extracted originals for a retry on any target volume.
                foreach($file in Get-ChildItem -LiteralPath $bundle -Force){
                    if($file.Name -ieq 'readme.md'){continue}
                    Copy-Item -LiteralPath $file.FullName -Destination $ready -Recurse -Force
                }
                $installed=Join-Path $ready 'AntiDPI';[IO.Directory]::CreateDirectory($installed)|Out-Null
                foreach($name in @('AntiDPI_GUI.ps1','AntiDPI_Launcher_Core_20261023_public_v1.ps1','AntiDPI_ActualTLS_20261023_public_v1.lua','Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1','Official_Bundle_20261023_public_v1.json','AntiDPI_Runtime_20261023_public_v1.cs','AntiDPI_WinDivert_Recovery.cs','AntiDPI_Zapret2.ico','AntiDPI_Zapret2_delete.ico')){
                    Copy-Item -LiteralPath (Join-Path $payload $name) -Destination $installed
                }
                foreach($name in @('README_Установка_Windows_v1.7.txt','README_Стратегии_Windows_v1.7.txt','LICENSE.txt')){
                    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $ready $name)
                }
                $engine=Join-Path $ready 'engine';[IO.Directory]::CreateDirectory($engine)|Out-Null
                if($bolVanLicenseDownloaded){
                    Copy-Item -LiteralPath $bolVanLicense -Destination (Join-Path $engine 'LICENSE_Bol-Van.txt')
                }
                [IO.File]::WriteAllText((Join-Path $installed 'Official_Bundle_20261023_public_v1.json'),($selectedMeta|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
                $lists=Join-Path $installed 'lists';[IO.Directory]::CreateDirectory($lists)|Out-Null
                foreach($name in @('ips-exclude.txt','ips6-exclude.txt')){
                    Copy-Item -LiteralPath (Join-Path (Join-Path $payload 'lists') $name) -Destination $lists
                }
                Copy-Item -LiteralPath $PSCommandPath -Destination (Join-Path $installed 'AntiDPI_Manager.ps1')
                New-UserCommand (Join-Path $ready 'ЗАПУСК_AntiDPI_Zapret2.cmd') 'GUI'
                New-UserCommand (Join-Path $ready 'УДАЛИТЬ_AntiDPI_Zapret2.cmd') 'Uninstall'
                $files=@(Get-ChildItem -LiteralPath $ready -Recurse -File -Force|ForEach-Object {[pscustomobject]@{Path=$_.FullName.Substring($ready.TrimEnd('\','/').Length+1);Sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}})
                $manifest=[ordered]@{Schema='antidpi.zapret.install.v1';InstallID=[guid]::NewGuid().ToString();InstallRoot=$finalRoot;Version='GUI_CLI_1.7';DisplayVersion='GUI + CLI Version 1.7';OfficialCommit=$selectedMeta.commit;OfficialSHA256=$downloadHash;OfficialSelection=$selection;Shortcut=$null;DriverBefore=$driverBefore;Files=$files}
                $manifest['Firewall']=Get-AntiDPIFirewallIdentity ([pscustomobject]$manifest)
                [IO.File]::WriteAllText((Join-Path $ready '.antidpi-install.json'),($manifest|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
                # Only destination/commit failures return to folder selection.
                # Missing payload, checksum and extraction errors remain real errors.
                try{
                    if(Test-Path -LiteralPath $finalRoot){
                        if(-not (Test-Path -LiteralPath $finalRoot -PathType Container) -or @(Get-ChildItem -LiteralPath $finalRoot -Force -ErrorAction Stop).Count){
                            throw [IO.IOException]::new('Папка назначения стала занятой во время установки.')
                        }
                        Remove-Item -LiteralPath $finalRoot -Force -ErrorAction Stop
                    }
                    Move-AntiDPIPreparedDirectory $ready $finalRoot
                }catch{
                    if(Test-AntiDPIAntivirusBlock $_){throw}
                    $retry=$true
                    Write-AntiDPIBusyDirectory $_.Exception.Message
                }
            }catch{
                if(-not (Test-AntiDPIAntivirusBlock $_)){throw}
                if(-not (Read-AntiDPIBundleRetry $_)){return}
                $retryDownload=$true
            }finally{
                Remove-AntiDPITemporaryDirectory $ready
                $ready=$null
            }
            if($retryDownload){
                $verified=Get-AntiDPIVerifiedBundle $meta $selection $url $stage
                if($null -eq $verified){return}
                $bundle=$verified.Bundle;$downloadHash=$verified.Hash;$selectedMeta=$verified.Metadata
                continue
            }
            if($retry){
                Write-Host 'Архив уже скачан и проверен. Выберите другую папку; повторное скачивание не требуется.'
                $finalRoot=Read-AntiDPIInstallDirectory;continue
            }
            break
        }
        $installed=Join-Path $finalRoot 'AntiDPI'
        $installedManifest=Get-Content -LiteralPath (Join-Path $finalRoot '.antidpi-install.json') -Raw -Encoding UTF8|ConvertFrom-Json
        $script:AntiDPIInstalledRoot=$finalRoot
        Write-Host ''
        Write-Host '----------------------'
        Set-AntiDPIFirewallRule $installedManifest
        Write-Host '----------------------'
        if($createShortcut){
            $installedManifest.Shortcut=New-AntiDPIDesktopShortcut $finalRoot
            [IO.File]::WriteAllText((Join-Path $finalRoot '.antidpi-install.json'),($installedManifest|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
        }
        Write-Host ("Установлено в:`r`n{0}`r`nИсходные файлы запуска и удаления находятся в этой корневой папке." -f $finalRoot) -ForegroundColor Yellow
        Write-Host '----------------------'
        Complete-AntiDPISessionLog
        $guiManager=Join-Path $installed 'AntiDPI_Manager.ps1'
        $guiArguments=@('-NoLogo','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',$guiManager,'-Action','GUI','-SkipHeader')
        $guiJoined=(@($guiArguments|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
        $null=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $guiJoined -WindowStyle Normal
    }finally{
        Remove-AntiDPITemporaryDirectory $ready
        Remove-AntiDPITemporaryDirectory $stage
    }
}

function Launch-AntiDPI([switch]$SkipIntro) {
    if(-not $SkipIntro){Show-AntiDPIAntivirusNotice}
    $m=Read-InstallManifest;$state=Join-Path $PSScriptRoot '_state';[IO.Directory]::CreateDirectory($state)|Out-Null
    $config=Join-Path $state 'adapter.json';$index=0
    if(Test-Path -LiteralPath $config){
        try{
            $saved=Get-Content -LiteralPath $config -Raw -Encoding UTF8 | ConvertFrom-Json
            if($null -eq $saved.PSObject.Properties['Guid']){throw 'Нет GUID адаптера.'}
            $foundSaved=@(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object {$_.Status -eq 'Up' -and [string]$_.InterfaceGuid -eq [string]$saved.Guid})
            if($foundSaved.Count -eq 1){$index=[int]$foundSaved[0].ifIndex}
            else{Write-Host 'Прошлый адаптер сейчас не найден среди активных. Выберите новый.' -ForegroundColor Yellow}
        }catch{Write-Host 'Не удалось прочитать сохранённый адаптер. Выберите его заново.' -ForegroundColor Yellow}
    }
    $adapter=Select-AntiDPIAdapter -Requested $index -Prompt
    Save-AntiDPIAdapter $state $adapter
    $scope=Read-AntiDPITcpPorts
    & (Join-Path $PSScriptRoot 'Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1') -InterfaceIndex $adapter.ifIndex -Scope $scope -ZapretDirectory (Join-Path $m.InstallRoot 'zapret-winws') -StateDirectory $state
}
function Uninstall-AntiDPI {
    $m=Read-InstallManifest;$root=$m.InstallRoot
    Write-Host "Будут удалены файлы этой установки: $root. Изменённые и посторонние файлы сохранятся."
    Write-Host 'Внимание! Перед удалением закройте папку с установленным Zapret2 и остановите все процессы Zapret2, если они запущены.' -ForegroundColor Yellow
    $confirmation=Read-Host 'Для удаления введите УДАЛИТЬ (или DELETE)'
    if(([string]$confirmation).Trim() -notin @('УДАЛИТЬ','DELETE')){Write-Host 'Удаление отменено.';return}
    Initialize-AntiDPIRuntime
    $bundle=Join-Path $root 'zapret-winws'
    $requested=[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle)
    if($requested){
        # Let the controller cancel its own capture/parallel slots first.
        $wait=[Diagnostics.Stopwatch]::StartNew()
        do{
            $other=@(Get-Process -Name 'winws','winws2','goodbyedpi' -ErrorAction SilentlyContinue)
            if(-not $other.Count){break}
            Start-Sleep -Milliseconds 100
        }while($wait.ElapsedMilliseconds -lt 15000)
    }
    Stop-OwnedWinws $m
    $other=@(Get-Process -Name 'winws','winws2','goodbyedpi' -ErrorAction SilentlyContinue)
    if($other.Count){throw 'Другой AntiDPI ещё работает. Остановите его самостоятельно и повторите удаление; чужие процессы не остановлены.'}
    $driverMutex=[Threading.Mutex]::new($false,'Global\AntiDPI_WinDivert_Recovery')
    $driverLock=$false
    try{
        try{$driverLock=$driverMutex.WaitOne(20000)}catch [Threading.AbandonedMutexException]{$driverLock=$true}
        if(-not $driverLock){throw 'Восстановление WinDivert ещё выполняется. Файлы сохранены; повторите удаление после его завершения.'}
        $backend=[AntiDPI.Public10.NativeWinDivertBackend]::new($bundle)
        $driver=$backend.Read()
        if($driver.Error -ne 0){throw ('Не удалось проверить службу WinDivert: Win32 '+$driver.Error+'. Файлы сохранены.')}
        if($driver.Exists){
            if($driver.Owned){
                $backend.Reset($driver)
                Write-Host 'Запись собственного драйвера WinDivert удалена.'
            }else{Write-Host 'WinDivert принадлежит другой установке и сохранён.'}
        }
    }finally{
        if($driverLock){$driverMutex.ReleaseMutex()}
        $driverMutex.Dispose()
    }
    $backup=Join-Path $PSScriptRoot '_state\timestamps_before.json'
    if(Test-Path -LiteralPath $backup){
        $old=Get-Content -LiteralPath $backup -Raw|ConvertFrom-Json
        if($old.Original -notin @('disabled','enabled','allowed','default')){throw 'Некорректное исходное значение timestamps.'}
        $dump=(& netsh.exe interface tcp dump 2>&1|Out-String)
        if($dump -match '(?i)\btimestamps=enabled\b'){
            & netsh.exe interface tcp set global ("timestamps="+$old.Original)
            if($LASTEXITCODE -ne 0){throw 'Не удалось восстановить timestamps. Установка сохранена для повторного удаления.'}
        }else{Write-Host 'Timestamps изменены отдельно; текущее значение оставлено.'}
    }
    Remove-AntiDPIFirewallRule $m
    Remove-AntiDPIDesktopShortcut $m
    $kept=[Collections.Generic.List[string]]::new();$locked=[Collections.Generic.List[string]]::new()
    $critical=@('УДАЛИТЬ_AntiDPI_Zapret2.cmd','AntiDPI\AntiDPI_Manager.ps1','AntiDPI\AntiDPI_Launcher_Core_20261023_public_v1.ps1')
    $ordered=@($m.Files|Where-Object {$_.Path -notin $critical})+@($m.Files|Where-Object {$_.Path -in $critical})
    foreach($file in $ordered){
        if($file.Path -in $critical -and $locked.Count){continue}
        $path=Join-Path $root $file.Path;if(-not (Test-Path -LiteralPath $path -PathType Leaf)){continue}
        if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $file.Sha256){$kept.Add($file.Path);continue}
        try{Remove-Item -LiteralPath $path -Force}catch{$locked.Add($file.Path)}
    }
    if($locked.Count){Write-Host ('Занятые файлы: '+($locked -join ', '));throw 'Перезагрузите ПК и повторите удаление из сохранённого файла УДАЛИТЬ_AntiDPI_Zapret2.cmd.'}
    $state=Join-Path $PSScriptRoot '_state'
    if(Test-Path -LiteralPath $state){
        foreach($name in @('owned_process.json','adapter.json','timestamps_before.json')){$p=Join-Path $state $name;if(Test-Path -LiteralPath $p){Remove-Item -LiteralPath $p -Force}}
    }
    Remove-Item -LiteralPath (Join-Path $root '.antidpi-install.json') -Force
    Get-ChildItem -LiteralPath $root -Directory -Force -Recurse|Sort-Object {$_.FullName.Length} -Descending|ForEach-Object {if(-not @(Get-ChildItem -LiteralPath $_.FullName -Force).Count){Remove-Item -LiteralPath $_.FullName -Force}}
    if(-not @(Get-ChildItem -LiteralPath $root -Force).Count){Remove-Item -LiteralPath $root -Force;Write-Host 'Zapret2 этой установки полностью удалён.'}else{Write-Host "Собственные неизменённые файлы удалены. Посторонние или изменённые файлы оставлены в $root."}
}
function Show-AntiDPIHeader {
    $lines=@(
        '===============================================================================',
        '  AntiDPI Strategies + Bol-Van Zapret2',
        '  GUI + CLI Version 1.7 | Windows 10/11 x64',
        '===============================================================================',
        '  ПРОГРАММА ГОТОВЫХ ANTI-DPI СТРАТЕГИЙ ОТ AntiDPI НА БАЗЕ ZAPRET2 (BOL-VAN)',
        '  В УДОБНОЙ CLI ОБОЛОЧКЕ ДЛЯ РАБОТЫ ЧЕРНЫХ СПИСКОВ VPN/TOR + YOUTUBE',
        '===============================================================================',
        '  AntiDPI из репозитория:',
        '  https://github.com/igareck/anti-dpi-for-russia',
        '  VPN/Tor Черные Списки:',
        '  https://github.com/igareck/vpn-configs-for-russia',
        '  Telegram: https://t.me/igareq',
        '===============================================================================',
        '  Zapret2 от Bol-Van, сборка для Windows из репозитория:',
        '  https://github.com/bol-van/zapret-win-bundle',
        '  Скачивается напрямую или через прокси из оригинального репозитория',
        '==============================================================================='
    )
    Write-Host ($lines -join [Environment]::NewLine) -ForegroundColor Cyan
    Write-Host ''
}
function Start-AntiDPISessionLog {
    if($script:AntiDPITranscriptActive){return}
    $directory=if($Action -eq 'Install'){Join-Path ([IO.Path]::GetTempPath()) 'AntiDPI_Install_Logs'}else{Join-Path (Split-Path -Parent $PSScriptRoot) 'logs'}
    [IO.Directory]::CreateDirectory($directory)|Out-Null
    $script:AntiDPITranscriptPath=Join-Path $directory ('AntiDPI_{0}_{1}_{2}.log' -f $Action,(Get-Date -Format 'yyyyMMdd_HHmmss_fff'),$PID)
    Start-Transcript -LiteralPath $script:AntiDPITranscriptPath -Force|Out-Null
    $script:AntiDPITranscriptActive=$true
}
function Complete-AntiDPISessionLog {
    if($script:AntiDPITranscriptActive){Stop-Transcript|Out-Null;$script:AntiDPITranscriptActive=$false}
    if($Action -eq 'Install' -and $script:AntiDPIInstalledRoot -and $script:AntiDPITranscriptPath){
        $logs=Join-Path $script:AntiDPIInstalledRoot 'logs'
        [IO.Directory]::CreateDirectory($logs)|Out-Null
        $target=Join-Path $logs (Split-Path -Leaf $script:AntiDPITranscriptPath)
        if([IO.Path]::GetFullPath($target) -ine [IO.Path]::GetFullPath($script:AntiDPITranscriptPath)){
            Copy-Item -LiteralPath $script:AntiDPITranscriptPath -Destination $target -Force
            $script:AntiDPITranscriptPath=$target
        }
    }
}
function Read-AntiDPIInstallPathInput {
    Initialize-AntiDPIRuntime
    if(-not [Console]::IsInputRedirected){
        try{$null=[Console]::KeyAvailable}
        catch{return (Read-Host 'Папка установки [C:\AntiDPI]')}
        return [AntiDPI.Public10.ConsoleLineEditor]::Read('Папка установки [C:\AntiDPI]: ','C:\')
    }
    return (Read-Host 'Папка установки [C:\AntiDPI]')
}
function Read-AntiDPIBundleSelection {
    Write-Host '----------------------'
    while($true){
        Write-Host 'Выберите одно из двух.' -ForegroundColor Cyan
        Write-Host '1. Для установки максимально совместимой версии Zapret2 (рекомендуется) - нажмите 1'
        Write-Host '2. Для установки самой последней версии Zapret2 - нажмите 2'
        $answer=Read-AntiDPIChoice 'Ваш выбор [Enter = 1]'
        if([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -eq '1'){return 'Compatible'}
        if($answer.Trim() -eq '2'){return 'Latest'}
    }
}
function Get-AntiDPILatestBundle([long]$ExpectedBytes=0) {
    # Both archive routes work without a prerequisite request to api.github.com.
    # The actual full commit ID is read from the downloaded git-archive ZIP.
    return [pscustomobject]@{
        repo='bol-van/zapret-win-bundle';commit='';commit_date=''
        url='https://codeload.github.com/bol-van/zapret-win-bundle/zip/refs/heads/master';sha256='';bytes=$ExpectedBytes;selection='Latest'
    }
}
function Read-AntiDPIShortcutChoice {
    Write-Host '----------------------'
    while($true){
        Write-Host 'Создать папку с ярлыками Запуска и Удаления Программы на Рабочем Столе?' -ForegroundColor Cyan
        $answer=Read-Host 'Введите Да/Yes или Нет/No'
        if(([string]$answer).Trim() -in @('Да','Yes')){return $true}
        if(([string]$answer).Trim() -in @('Нет','No')){return $false}
    }
}
function Get-AntiDPIDesktopDirectory {
    $desktop=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    if([string]::IsNullOrWhiteSpace($desktop)){throw 'Не удалось определить папку рабочего стола.'}
    return $desktop
}
function New-AntiDPIDesktopShortcut([string]$InstallRoot) {
    $desktop=Get-AntiDPIDesktopDirectory
    $directory=Join-Path $desktop 'AntiDPI'
    $specs=@(
        [pscustomobject]@{
            Name='START_AntiDPI.lnk'
            Target=(Join-Path $InstallRoot 'ЗАПУСК_AntiDPI_Zapret2.cmd')
            Icon=(Join-Path $InstallRoot 'AntiDPI\AntiDPI_Zapret2.ico')
            Description='Графическое управление AntiDPI Strategies + Bol-Van Zapret2'
        },
        [pscustomobject]@{
            Name='DELETE_AntiDPI.lnk'
            Target=(Join-Path $InstallRoot 'УДАЛИТЬ_AntiDPI_Zapret2.cmd')
            Icon=(Join-Path $InstallRoot 'AntiDPI\AntiDPI_Zapret2_delete.ico')
            Description='Удаление AntiDPI Strategies + Bol-Van Zapret2 — GUI + CLI Version 1.7'
        }
    )
    foreach($spec in $specs){
        foreach($path in @($spec.Target,$spec.Icon)){
            if(-not (Test-Path -LiteralPath $path -PathType Leaf)){throw ('Нет файла для создания ярлыка: '+$path)}
        }
    }
    if((Test-Path -LiteralPath $directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)){
        throw ('Невозможно создать папку ярлыков: путь занят файлом '+$directory)
    }
    $created=-not (Test-Path -LiteralPath $directory -PathType Container)
    $records=[Collections.Generic.List[object]]::new()
    $documents=[Collections.Generic.List[object]]::new()
    $shell=$null
    try{
        [IO.Directory]::CreateDirectory($directory)|Out-Null
        $shell=New-Object -ComObject WScript.Shell
        foreach($spec in $specs){
            $path=Join-Path $directory $spec.Name
            $shortcut=$null
            try{
                $shortcut=$shell.CreateShortcut($path)
                $shortcut.TargetPath=$spec.Target
                $shortcut.Arguments=''
                $shortcut.WorkingDirectory=$InstallRoot
                $shortcut.IconLocation=$spec.Icon+',0'
                $shortcut.Description=$spec.Description
                $shortcut.WindowStyle=1
                $shortcut.Save()
                $records.Add([pscustomobject]@{Path=$path;Target=$spec.Target;Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()})
            }finally{
                if($null -ne $shortcut -and [Runtime.InteropServices.Marshal]::IsComObject($shortcut)){
                    [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut)|Out-Null
                }
            }
        }
        foreach($name in @('README_Установка_Windows_v1.7.txt','README_Стратегии_Windows_v1.7.txt')){
            $path=Join-Path $directory $name
            Copy-Item -LiteralPath (Join-Path $InstallRoot $name) -Destination $path -Force
            $documents.Add([pscustomobject]@{Path=$path;Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()})
        }
    }catch{
        foreach($record in (@($records.ToArray())+@($documents.ToArray()))){
            if(Test-Path -LiteralPath $record.Path -PathType Leaf){
                if((Get-FileHash -LiteralPath $record.Path -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $record.Sha256){
                    Remove-Item -LiteralPath $record.Path -Force
                }
            }
        }
        if($created -and (Test-Path -LiteralPath $directory -PathType Container) -and -not @(Get-ChildItem -LiteralPath $directory -Force).Count){
            Remove-Item -LiteralPath $directory -Force
        }
        throw
    }finally{
        if($null -ne $shell -and [Runtime.InteropServices.Marshal]::IsComObject($shell)){
            [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)|Out-Null
        }
    }
    Write-Host "Создана папка с удобными Ярлыками Запуска и Удаления на Рабочем Столе:`r`nAntiDPI`r`nВ папку также добавлено подробное Описание Стратегий и Инструкции в формате txt." -ForegroundColor Yellow
    return [pscustomobject]@{Directory=$directory;Links=$records.ToArray();Documents=$documents.ToArray()}
}
function Remove-AntiDPIDesktopShortcut($Manifest) {
    if($null -eq $Manifest.PSObject.Properties['Shortcut'] -or $null -eq $Manifest.Shortcut){return}
    $bundle=$Manifest.Shortcut
    $desktop=Get-AntiDPIDesktopDirectory
    if($null -eq $bundle.PSObject.Properties['Links']){
        throw 'Некорректный список ярлыков в маркере установки.'
    }
    $directory=Join-Path $desktop 'AntiDPI'
    if([IO.Path]::GetFullPath($bundle.Directory) -ine [IO.Path]::GetFullPath($directory)){throw 'Некорректный путь папки ярлыков в маркере установки.'}
    $targets=@{
        'START_AntiDPI.lnk'=(Join-Path $Manifest.InstallRoot 'ЗАПУСК_AntiDPI_Zapret2.cmd')
        'DELETE_AntiDPI.lnk'=(Join-Path $Manifest.InstallRoot 'УДАЛИТЬ_AntiDPI_Zapret2.cmd')
    }
    $links=@($bundle.Links);$seen=@{}
    if($links.Count -ne 2){throw 'Некорректный список ярлыков в маркере установки.'}
    foreach($link in $links){
        $name=[IO.Path]::GetFileName([string]$link.Path)
        if(-not $targets.ContainsKey($name) -or $seen.ContainsKey($name)){throw 'Некорректное имя ярлыка в маркере установки.'}
        $seen[$name]=$true
        $expected=Join-Path $directory $name
        if([IO.Path]::GetFullPath($link.Path) -ine [IO.Path]::GetFullPath($expected) -or [string]$link.Target -ine $targets[$name]){
            throw 'Ярлык в маркере установки не соответствует программе.'
        }
    }
    $documents=@()
    if($null -ne $bundle.PSObject.Properties['Documents']){$documents=@($bundle.Documents)}
    $documentNames=@('README_Установка_Windows_v1.7.txt','README_Стратегии_Windows_v1.7.txt');$seenDocuments=@{}
    foreach($document in $documents){
        $name=[IO.Path]::GetFileName([string]$document.Path)
        if($name -notin $documentNames -or $seenDocuments.ContainsKey($name) -or [IO.Path]::GetFullPath($document.Path) -ine [IO.Path]::GetFullPath((Join-Path $directory $name))){
            throw 'Некорректный путь инструкции в папке ярлыков.'
        }
        $seenDocuments[$name]=$true
    }
    foreach($link in (@($links)+@($documents))){
        if(Test-Path -LiteralPath $link.Path -PathType Leaf){
            if((Get-FileHash -LiteralPath $link.Path -Algorithm SHA256).Hash.ToLowerInvariant() -ceq [string]$link.Sha256){
                Remove-Item -LiteralPath $link.Path -Force
            }
        }
    }
    if((Test-Path -LiteralPath $directory -PathType Container) -and -not @(Get-ChildItem -LiteralPath $directory -Force).Count){
        Remove-Item -LiteralPath $directory -Force
    }
}

if($env:OS -ne 'Windows_NT'){throw 'Этот установщик предназначен для Windows 10/11 x64.'}
if(-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'){throw 'Нужна Windows x64. ARM64 требует отдельной подготовки официального драйвера.'}
$needsElevation=-not (Test-AntiDPIAdmin)
$needsSta=($Action -eq 'GUI' -and [Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA)
if($needsElevation -or $needsSta){
    $arguments=@('-NoLogo','-NoProfile')
    if($Action -eq 'GUI'){$arguments+='-STA'}
    $arguments+=@('-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-Action',$Action)
    if($InstallPath){$arguments+=@('-InstallPath',$InstallPath)}
    if($BundleSelection){$arguments+=@('-BundleSelection',$BundleSelection)}
    if($CreateShortcutChoice){$arguments+=@('-CreateShortcutChoice',$CreateShortcutChoice)}
    if($NonInteractiveInstaller){$arguments+='-NonInteractiveInstaller'}
    if($SkipHeader -or $Action -eq 'GUI'){$arguments+='-SkipHeader'}
    $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $joined=(ConvertTo-WindowsArgument $powershell)+' '+(@($arguments|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
    if($Action -eq 'GUI'){
        $startParameters=@{FilePath=$powershell;ArgumentList=(@($arguments|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ');WindowStyle='Normal';PassThru=$true}
        if($needsElevation){$startParameters.Verb='RunAs'}
        $null=Start-Process @startParameters
    }else{
        $null=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\conhost.exe') -ArgumentList $joined -Verb RunAs -PassThru
    }
    exit 0
}

try{
    Start-AntiDPISessionLog
    if(-not $SkipHeader -and $Action -ne 'GUI'){
        Show-AntiDPIHeader
    }
    switch($Action){'Install'{Install-AntiDPI};'Launch'{Launch-AntiDPI -SkipIntro:$SkipHeader};'GUI'{& (Join-Path $PSScriptRoot 'AntiDPI_GUI.ps1')};'Uninstall'{Uninstall-AntiDPI}}
}
catch [OperationCanceledException]{Write-Host ''}
catch{if($Action -eq 'GUI'){Add-Type -AssemblyName System.Windows.Forms;[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'AntiDPI')|Out-Null}else{Write-Host ("ОШИБКА: "+$_.Exception.Message) -ForegroundColor Red;Read-Host 'Enter — закрыть'|Out-Null};exit 1}
finally{Complete-AntiDPISessionLog}
