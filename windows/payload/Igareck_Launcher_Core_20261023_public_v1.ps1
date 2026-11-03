#requires -Version 5.1
# Shared launcher for the installer catalogues.
# Requires the original Windows Bundle for winws2, Lua and driver files.
$ErrorActionPreference='Stop'
# The classic host progress pane restores stale screen cells after scrolling.
# Use ordinary output / the window title; never draw progress over the catalogue.
$ProgressPreference='SilentlyContinue'
Set-StrictMode -Version Latest
$script:IgareckScanControl=$null
$script:IgareckRecoveryBudget=$null
$script:IgareckRecoveryReason=""
$script:IgareckRecoveryAwaitingStart=$false
$script:IgareckLifecycle=$null
function Test-IgareckStopRequested {
    return ($null -ne $script:IgareckLifecycle -and $script:IgareckLifecycle.StopRequested)
}
function Get-IgareckArguments($Row,[int]$Index,[string]$PortScope,[int[]]$ProbePorts=@()) {
    if($Index -le 0){throw 'Укажите положительный индекс физического адаптера.'}
    $scope=ConvertTo-IgareckPortScope $PortScope
    $ports=if($scope -eq 'all'){'0-65535'}else{$scope}
    $a=[Collections.Generic.List[string]]::new()
    foreach($s in @('--wf-l3=ipv4',"--wf-iface=$Index","--wf-tcp-out=$ports",'--wf-tcp-empty=0','--lua-init=@lua\zapret-lib.lua','--lua-init=@lua\zapret-antidpi.lua')){$a.Add($s)}
    if($ProbePorts.Count){
        if(@($ProbePorts | Where-Object {$_ -lt 1 -or $_ -gt 65535}).Count){throw 'Некорректные порты проверки.'}
        $outbound=(@($ProbePorts | ForEach-Object {"tcp.SrcPort == $_"}) -join ' or ')
        $inbound=(@($ProbePorts | ForEach-Object {"tcp.DstPort == $_"}) -join ' or ')
        # AND preserves the constructor's interface, LAN and inbound SYN/ACK guards.
        $a.Add("--wf-raw-filter=tcp and ((outbound and ($outbound)) or (inbound and ($inbound)))")
    }
    if(@($Row.Args | Where-Object {$_ -match '^--lua-desync=fake:.*\bblob=reasm_data(?:[:]|$)' -and $_ -match ':tls_mod='}).Count){
        $guard=Join-Path $PSScriptRoot 'Igareck_ActualTLS_20261023_public_v1.lua'
        if(-not (Test-Path -LiteralPath $guard -PathType Leaf)){throw 'Нет Igareck_ActualTLS_20261023_public_v1.lua. Распакуйте весь архив новой версии.'}
        $a.Add('--lua-init=@'+$guard)
    }
    if($Row.Init){$a.Add('--lua-init='+$Row.Init)}
    $a.Add("--filter-tcp=$ports");$a.Add('--filter-l7=tls')
    # Keep address exclusions; every real TLS SNI is eligible for the recipe.
    foreach($list in @(
        @{Name='ips-exclude.txt';Option='--ipset-exclude='}
    )){
        $path=Join-Path (Join-Path $PSScriptRoot 'lists') $list.Name
        if(-not (Test-Path -LiteralPath $path -PathType Leaf)){
            throw ('Нет списка исключений: '+$path+'. Распакуйте весь комплект новой версии.')
        }
        $a.Add($list.Option+$path)
    }
    foreach($s in $Row.Args){$a.Add([string]$s)}
    return $a.ToArray()
}
function ConvertTo-WindowsArgument([string]$Value) {
    if($Value.Length -and $Value -notmatch '[\s"]'){return $Value}
    return '"'+[regex]::Replace([regex]::Replace($Value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')+'"'
}
function Get-IgareckConsoleWidth {
    $widths=[Collections.Generic.List[int]]::new()
    try { $w=[int]$Host.UI.RawUI.WindowSize.Width; if($w -gt 0){$widths.Add($w)} } catch {}
    try { $w=[int][Console]::WindowWidth; if($w -gt 0){$widths.Add($w)} } catch {}
    if(-not $widths.Count){return 100}
    return [int]($widths | Measure-Object -Minimum).Minimum
}
function Read-IgareckChoice([string]$Prompt='Ваш выбор') {
    Write-Host ($Prompt+': ') -NoNewline -ForegroundColor Cyan
    $answer=Read-Host
    Write-Host ''
    return [string]$answer
}
function ConvertTo-IgareckPortScope([string]$Value) {
    $text=([string]$Value).Trim()
    if(-not $text -or $text -imatch '^(all|все|всё)$'){return 'all'}
    $text=$text -replace '[\u2010-\u2014\u2212]','-'
    $ranges=[Collections.Generic.List[object]]::new()
    foreach($part in $text.Split(',')){
        $match=[regex]::Match($part,'^\s*([0-9]+)\s*(?:-\s*([0-9]+)\s*)?$')
        $first=0;$last=0
        if(-not $match.Success -or -not [int]::TryParse($match.Groups[1].Value,[ref]$first)){
            throw 'Введите TCP-порт 0–65535, диапазон, комбинацию через запятую либо все/all.'
        }
        $last=$first
        if($match.Groups[2].Success -and -not [int]::TryParse($match.Groups[2].Value,[ref]$last)){
            throw 'Некорректный TCP-диапазон.'
        }
        if($first -lt 0 -or $last -gt 65535 -or $first -gt $last){throw 'Некорректный TCP-диапазон.'}
        $ranges.Add([pscustomobject]@{First=$first;Last=$last})
    }
    $ordered=@($ranges | Sort-Object First,Last)
    $merged=[Collections.Generic.List[object]]::new()
    foreach($range in $ordered){
        if($merged.Count -and $range.First -le $merged[$merged.Count-1].Last+1){
            $merged[$merged.Count-1].Last=[Math]::Max($merged[$merged.Count-1].Last,$range.Last)
        }else{$merged.Add([pscustomobject]@{First=[int]$range.First;Last=[int]$range.Last})}
    }
    if($merged.Count -eq 1 -and $merged[0].First -eq 0 -and $merged[0].Last -eq 65535){return 'all'}
    return (@($merged | ForEach-Object {if($_.First -eq $_.Last){[string]$_.First}else{'{0}-{1}' -f $_.First,$_.Last}}) -join ',')
}
function Test-IgareckScopePort([string]$PortScope,[int]$Port) {
    $scope=ConvertTo-IgareckPortScope $PortScope
    if($scope -eq 'all'){return $true}
    foreach($part in $scope.Split(',')){
        $ends=$part.Split('-');$first=[int]$ends[0];$last=if($ends.Count -eq 2){[int]$ends[1]}else{$first}
        if($Port -ge $first -and $Port -le $last){return $true}
    }
    return $false
}
function Read-IgareckTcpPorts {
    Write-Host '----------------------'
    Write-Host ''
    Write-Host 'Выберите порты назначения TCP, трафик которых будет перехватываться Zapret2.' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Либо определенный номер порта, например 443, 80 и т.д.'
    Write-Host 'Либо диапазон, например 0–1023'
    Write-Host 'Либо введите комбинацию: несколько диапазонов и/или одиночных портов через запятую, например: 53, 80, 443, 1000-2000, 3000-4000'
    Write-Host 'Либо введите слово "все/all" (регистр неважен), чтобы перехватывать любые TCP-порты (нужно для подписок VPN).'
    Write-Host ''
    while($true){
        $answer=Read-IgareckChoice 'Ваш выбор [Нажатие Enter активирует все порты по умолчанию]'
        try{return (ConvertTo-IgareckPortScope $answer)}catch{}
    }
}
function Split-IgareckCell([string]$Text,[int]$Width) {
    if($Width -lt 1){throw 'Ширина ячейки должна быть положительной.'}
    $rest=($Text -replace '[\r\n\t]+',' ').Trim()
    if(-not $rest.Length){return ''}
    while($rest.Length -gt $Width){
        $cut=$rest.LastIndexOf(' ',$Width)
        if($cut -lt 1){$cut=$Width}
        $rest.Substring(0,$cut).TrimEnd()
        $rest=$rest.Substring($cut).TrimStart()
    }
    if($rest.Length){$rest}
}
function Get-IgareckTableLines([string[]]$Headers,[int[]]$Widths,[object[]]$Rows) {
    if($Headers.Count -ne $Widths.Count){throw 'Некорректные колонки таблицы.'}
    $parts=@(foreach($w in $Widths){'-'*($w+2)})
    $border='+'+($parts -join '+')+'+'
    $border
    $all=[Collections.Generic.List[object]]::new()
    $all.Add([pscustomobject]@{Cells=$Headers})
    foreach($r in $Rows){$all.Add($r)}
    foreach($r in $all){
        if($r.Cells.Count -ne $Widths.Count){throw 'Некорректная строка таблицы.'}
        $cells=@(for($c=0;$c -lt $Widths.Count;$c++){
            [pscustomobject]@{Lines=@(Split-IgareckCell ([string]$r.Cells[$c]) $Widths[$c])}
        })
        $height=[int]($cells | ForEach-Object {$_.Lines.Count} | Measure-Object -Maximum).Maximum
        for($y=0;$y -lt $height;$y++){
            $pieces=@(for($c=0;$c -lt $Widths.Count;$c++){
                $text=if($y -lt $cells[$c].Lines.Count){[string]$cells[$c].Lines[$y]}else{''}
                ' '+$text.PadRight($Widths[$c])+' '
            })
            '|'+($pieces -join '|')+'|'
        }
        $border
    }
}
function Get-IgareckFlatRows([object[]]$Rows) {
    # Windows PowerShell 5.1 can send the entire JSON array as ONE pipeline object.
    # Flatten only catalogue containers; never recurse into a recipe's Args/Init.
    foreach($item in $Rows){
        if($item -is [Array]){Get-IgareckFlatRows -Rows $item;continue}
        if($null -eq $item -or $null -eq $item.PSObject.Properties['Number']){
            throw 'В каталоге обнаружена запись без номера. Распакуйте весь архив новой версии.'
        }
        $item
    }
}
function Get-IgareckFamilyTable([int]$Width) {
    $width=[Math]::Min(120,[Math]::Max(20,$Width))
    $rows=[Collections.Generic.List[object]]::new()
    foreach($family in $FamilyRows){
        $prefix=[regex]::Match([string]$family.Name,'^(Golden|Silver|Failed_Weak)\s*/\s*(.*)$')
        $set=if($prefix.Success){$prefix.Groups[1].Value}else{$CatalogueInfo.Slug}
        $name=if($prefix.Success){$prefix.Groups[2].Value}else{[string]$family.Name}
        $range=if($family.First -eq $family.Last){[string]$family.First}else{'{0}-{1}' -f $family.First,$family.Last}
        if($width -ge 48){
            $rows.Add([pscustomobject]@{Cells=@([string]$family.Number,$set,$name,[string]$family.Count,$range)})
        }else{
            foreach($pair in @(@('Группа',[string]$family.Number),@('Набор',$set),@('Сем-во',$name),@('Кол-во',[string]$family.Count),@('Номера',$range))){
                $rows.Add([pscustomobject]@{Cells=$pair})
            }
        }
    }
    if($width -ge 48){
        Get-IgareckTableLines -Headers @('#','Набор','Семейство','Кол.','Номера') -Widths @(2,6,($width-35),4,7) -Rows $rows.ToArray()
    }else{
        Get-IgareckTableLines -Headers @('Поле','Значение') -Widths @(6,($width-13)) -Rows $rows.ToArray()
    }
}
function Initialize-IgareckArtworkTypes {
    if(-not ('Igareck.ConsoleArtworkCLI' -as [type])){
        $source=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Igareck_Console_Artwork.cs'),[Text.Encoding]::UTF8)
        Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
    }
}
function Initialize-IgareckArtworkConsole([string]$FontPath) {
    if($env:OS -ne 'Windows_NT'){return $false}
    Initialize-IgareckArtworkTypes
    $data=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Igareck_Artwork_CLI.json') -Raw -Encoding UTF8|ConvertFrom-Json
    return [Igareck.ConsoleArtworkCLI]::PrepareFont($FontPath,[int]$data.GlyphCount)
}
function Resize-IgareckArtworkConsole([int]$Columns,[int]$Rows) {
    return [Igareck.ConsoleArtworkCLI]::EnsureWidth($Columns,$Rows)
}
function Set-IgareckArtworkLayout([int]$Columns,[int]$Rows,[string]$FontPath) {
    try{
        if(-not (Initialize-IgareckArtworkConsole $FontPath)){return $false}
        return (Resize-IgareckArtworkConsole ($Columns+1) ($Rows+10)) -and (Get-IgareckConsoleWidth) -ge ($Columns+1)
    }catch{Write-Verbose ('Console artwork: '+$_.Exception.Message);return $false}
}
function Close-IgareckArtworkConsole {
    if($env:OS -eq 'Windows_NT' -and ('Igareck.ConsoleArtworkCLI' -as [type])){
        try{[Igareck.ConsoleArtworkCLI]::ReleaseFont()}catch{Write-Verbose $_.Exception.Message}
    }
}
function Show-IgareckArtwork([string]$Path,[switch]$Prepared) {
    try{
        Initialize-IgareckArtworkTypes
        $data=Get-Content -LiteralPath $Path -Raw -Encoding UTF8|ConvertFrom-Json
        if([int]$data.Columns -ne 100 -or [int]$data.Rows -ne 32){throw 'Некорректный формат логотипа.'}
        $font=Join-Path (Split-Path -Parent $Path) 'IgareckArtCLI.ttf'
        if(-not $Prepared -and -not (Set-IgareckArtworkLayout 100 32 $font)){
            Write-Host 'Для логотипа нужен обычный терминал с шириной не меньше 101 колонки.' -ForegroundColor Yellow
            return
        }
        if(-not [Igareck.ConsoleArtworkCLI]::DrawRows([string[]]$data.Tiles,[string[]]$data.Colours)){
            Write-Host 'Для логотипа нужен обычный терминал с шириной не меньше 101 колонки.' -ForegroundColor Yellow
        }
    }catch{Write-Warning ('Логотип: '+$_.Exception.Message)}
}

function Select-IgareckAdapter([int]$Requested=0,[switch]$Prompt) {
    $active=@(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object {$_.Status -eq 'Up'})
    $usable=@($active | Where-Object {@(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {$_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike '169.254.*' -and -not $_.SkipAsSource}).Count})
    if(-not $usable.Count){throw 'Не найден активный физический адаптер с IPv4.'}
    $previous=@($usable | Where-Object ifIndex -eq $Requested)
    if($Requested -and -not $Prompt){
        if($previous.Count -ne 1){throw "Адаптер $Requested недоступен. Выберите активный физический адаптер."}
        return $previous[0]
    }
    Write-Host 'Выберите активный Интернет-адаптер для работы AntiDPI Стратегий' -ForegroundColor Cyan
    $indices=@(foreach($a in $usable){[int]$a.ifIndex})
    $rank=@(Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Where-Object {$_.InterfaceIndex -in $indices} | ForEach-Object {
        $route=$_;$ip=Get-NetIPInterface -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
        $metric=[int]$route.RouteMetric;if($null -ne $ip){$metric+=[int]$ip.InterfaceMetric}
        [pscustomobject]@{Index=[int]$route.InterfaceIndex;Metric=$metric}
    } | Sort-Object Metric)
    $recommend=if($rank.Count){$rank[0].Index}else{[int]$usable[0].ifIndex}
    $width=[Math]::Min(120,[Math]::Max(20,(Get-IgareckConsoleWidth)-1))
    $rows=[Collections.Generic.List[object]]::new()
    foreach($a in $usable){
        if($width -ge 60){$rows.Add([pscustomobject]@{Cells=@([string]$a.ifIndex,[string]$a.Name,[string]$a.InterfaceDescription)})}
        else{$rows.Add([pscustomobject]@{Cells=@([string]$a.ifIndex,[string]$a.Name)})}
    }
    $table=if($width -ge 60){
        $nameWidth=[int][Math]::Floor(($width-18)*0.45)
        Get-IgareckTableLines -Headers @('Индекс','Адаптер (Up)','Описание') -Widths @(6,$nameWidth,($width-16-$nameWidth)) -Rows $rows.ToArray()
    }else{
        Get-IgareckTableLines -Headers @('Индекс','Адаптер (Up)') -Widths @(6,($width-13)) -Rows $rows.ToArray()
    }
    Write-Host (@($table) -join [Environment]::NewLine)
    Write-Host ('Активные (Up) индексы: '+($indices -join ', ')+". Рекомендуется: $recommend.")
    $default=$recommend
    if($Requested -gt 0 -and $previous.Count -eq 1){
        $default=$Requested
        Write-Host ("Прошлый выбор: {0}, индекс {1}." -f $previous[0].Name,$Requested)
        Write-Host 'Нажмите Enter, если хотите использовать прошлый выбор адаптера. Либо введите цифру из предложенного списка.' -ForegroundColor Cyan
    }elseif($Requested -gt 0){
        Write-Host 'Сохранённый адаптер сейчас недоступен. Выберите другой; Enter = рекомендуемый.' -ForegroundColor Yellow
    }
    while($true){
        $answer=Read-Host "Индекс основного адаптера [Enter = $default]";$chosen=0
        if([string]::IsNullOrWhiteSpace($answer)){$chosen=$default}
        elseif(-not [int]::TryParse($answer,[ref]$chosen)){Write-Host 'Введите индекс из таблицы.';continue}
        $found=@($usable | Where-Object ifIndex -eq $chosen)
        if($found.Count -eq 1){return $found[0]}
        Write-Host 'Введите один из показанных активных индексов.'
    }
}
function Show-IgareckFamilies {
    Write-Host ''
    Write-Host '######################'
    Write-Host ''
    $set=([string]$CatalogueInfo.Slug).Replace('_','+')
    Write-Host ('КАТАЛОГ (Октябрь 2026): {0}; {1} уникальных AntiDPI стратегии, подобранные специально для российских сетей.' -f $set,$ProfileRows.Count) -ForegroundColor Cyan
    if($CatalogueInfo.Slug -eq 'Golden_Silver'){Write-Host 'Golden: 1-45 (45). Silver: 46-484 (439).'}
    Write-Host '----------------------'
    Write-Host 'Вводите номер стратегии из колонки «Номера».'
    $table=@(Get-IgareckFamilyTable -Width ((Get-IgareckConsoleWidth)-1))
    for($i=0;$i -lt $table.Count;$i++){
        if($i -eq 1){Write-Host $table[$i] -ForegroundColor Cyan}else{Write-Host $table[$i]}
    }
    Write-Host ''
}

function Find-IgareckBundle([string]$Directory) {
    foreach($p in @($Directory,(Join-Path $Directory 'zapret-winws'),(Split-Path -Parent $PSScriptRoot))){
        if(Test-Path -LiteralPath (Join-Path $p 'winws2.exe') -PathType Leaf){
            foreach($n in @('lua\zapret-lib.lua','lua\zapret-antidpi.lua','cygwin1.dll','WinDivert.dll','WinDivert64.sys')){if(-not (Test-Path -LiteralPath (Join-Path $p $n) -PathType Leaf)){throw "Нет $n в $p"}}
            return (Resolve-Path -LiteralPath $p).Path
        }
    };throw 'Не найден Windows Bundle. Укажите -ZapretDirectory с папкой zapret-winws.'
}
function Test-IgareckAdmin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent();return ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Enable-IgareckTimestamps([string]$StateDirectory) {
    $dump=(& netsh.exe interface tcp dump 2>&1|Out-String)
    $m=[regex]::Match($dump,'(?i)\btimestamps=(disabled|enabled|allowed|default)\b')
    if(-not $m.Success){throw 'Не удалось прочитать исходную настройку timestamps через netsh. Выберите стратегию без TS или включите timestamps вручную штатным enable_timestamps.cmd.'}
    $old=$m.Groups[1].Value.ToLowerInvariant();if($old -eq 'enabled'){return}
    $backup=Join-Path $StateDirectory 'timestamps_before.json'
    if(-not (Test-Path -LiteralPath $backup)){[IO.File]::WriteAllText($backup,(@{Original=$old;ChangedTo='enabled'}|ConvertTo-Json))}
    & netsh.exe interface tcp set global timestamps=enabled
    if($LASTEXITCODE -ne 0){throw 'Не удалось включить TCP timestamps.'}
    Write-Host "TCP timestamps: $old -> enabled. Исходное значение записано для удаления."
}
function Read-IgareckStrategyNumber([hashtable]$Profiles,[int]$Count,[int]$StoppedNumber=0) {
    if($StoppedNumber -gt 0){
        Write-Host ''
        Write-Host ('СТРАТЕГИЯ {0} ОСТАНОВЛЕНА!' -f $StoppedNumber) -ForegroundColor Red
        Write-Host ''
    }
    while($true){
        Write-Host 'Выберите один из двух вариантов.' -ForegroundColor Cyan
        Write-Host '1. Либо введите номер AntiDPI-стратегии из таблицы (0 — выход из программы)'
        Write-Host '2. Либо, чтобы проверить диапазон стратегий на доступ к Youtube, наберите слово "Youtube" (без учета регистра) и далее следуйте указаниям'
        Write-Host '----------------------'
        $answer=Read-IgareckChoice;$number=0
        if(([string]$answer).Trim() -ieq 'Youtube'){return 'Youtube'}
        if([int]::TryParse($answer,[ref]$number)){
            if($number -eq 0 -or $Profiles.ContainsKey($number)){return $number}
        }
    }
}
function Open-IgareckConsoleInput {
    $state=[pscustomobject]@{Supported=$false;Changed=$false;Previous=$false}
    try{
        if([Console]::IsInputRedirected){return $state}
        $state.Previous=[Console]::TreatControlCAsInput
        $null=[Console]::KeyAvailable
        [Console]::TreatControlCAsInput=$true
        $state.Changed=$true;$state.Supported=$true
    }catch{
        if($state.Changed){[Console]::TreatControlCAsInput=$state.Previous;$state.Changed=$false}
    }
    return $state
}
function Close-IgareckConsoleInput($State) {
    if($State.Changed){[Console]::TreatControlCAsInput=[bool]$State.Previous;$State.Changed=$false}
}
function Read-IgareckControlKey {
    if(-not [Console]::KeyAvailable){return}
    $key=[Console]::ReadKey($true)
    if($key.Key -eq [ConsoleKey]::F1){return 'Switch'}
    if($key.Key -eq [ConsoleKey]::F2){return 'Restart'}
    if($key.Key -eq [ConsoleKey]::F3){return 'Adapter'}
    if([int]$key.KeyChar -eq 3 -or ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control))){return 'Stop'}
}
function Get-IgareckRecoveryLog([string]$Bundle) {
    return (Join-Path (Get-IgareckLogDirectory $Bundle) 'WinDivert_recovery.log')
}
function Initialize-IgareckDriverControl([string]$Bundle) {
    Initialize-IgareckRuntime
    if($null -eq $script:IgareckRecoveryBudget){$script:IgareckRecoveryBudget=[Igareck.Public10.WinDivertRecoveryBudget]::new()}
    $snapshot=[Igareck.Public10.NativeWinDivertBackend]::new($Bundle).Read()
    [Igareck.Public10.WinDivertRecovery]::Log((Get-IgareckRecoveryLog $Bundle),('STARTUP '+$snapshot))
    if(-not $snapshot.FilesReady){throw $snapshot.FileProblem}
    if($snapshot.Error -eq 0 -and $snapshot.Exists -and $snapshot.Owned -and
        ($snapshot.StartType -eq 4 -or -not (Test-Path -LiteralPath $snapshot.ImagePath -PathType Leaf))){
        if(-not (Invoke-IgareckAutomaticRecovery $Bundle 'STARTUP_CONFIGURATION')){
            throw 'Автоматическое восстановление WinDivert не выполнено. Подробности — в WinDivert_recovery.log.'
        }
    }
}
function Invoke-IgareckAutomaticRecovery([string]$Bundle,[string]$Reason) {
    if(Test-IgareckStopRequested){$script:IgareckScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
    $attempt=0;$delay=0
    $log=Get-IgareckRecoveryLog $Bundle
    if(-not $script:IgareckRecoveryBudget.TryBegin([DateTime]::UtcNow,[ref]$attempt,[ref]$delay)){
        [Igareck.Public10.WinDivertRecovery]::Log($log,('LIMIT reason='+$Reason))
        Write-Host ('Автовосстановление приостановлено: исчерпаны 3 попытки за 10 минут. Лог: '+$log) -ForegroundColor Red
        return $false
    }
    Write-Host ''
    Write-Host ('Сбой движка/WinDivert. Автоматическое восстановление, попытка {0}/3...' -f $attempt) -ForegroundColor Yellow
    $scanning=$null -ne $script:IgareckScanControl
    $inputState=if($scanning){$null}else{Open-IgareckConsoleInput}
    try{
        $wait=[Diagnostics.Stopwatch]::StartNew()
        while($wait.ElapsedMilliseconds -lt $delay){
            if(Test-IgareckStopRequested){$script:IgareckScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
            if($scanning){Test-IgareckScanCancellation}
            elseif($inputState.Supported -and (Read-IgareckControlKey) -eq 'Stop'){
                throw [OperationCanceledException]::new('Работа остановлена пользователем.')
            }
            Start-Sleep -Milliseconds 50
        }
        $result=[Igareck.Public10.WinDivertRecovery]::Repair($Bundle,$log,$Reason,$attempt)
        if(Test-IgareckStopRequested){$script:IgareckScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
        if($scanning){Test-IgareckScanCancellation}
        elseif($inputState.Supported -and (Read-IgareckControlKey) -eq 'Stop'){
            throw [OperationCanceledException]::new('Работа остановлена пользователем.')
        }
        if(-not $result.Retry){
            Write-Host ('Автовосстановление не выполнено: '+$result.Reason+' Лог: '+$log) -ForegroundColor Red
            return $false
        }
        $script:IgareckRecoveryAwaitingStart=$true
        return $true
    }finally{if($null -ne $inputState){Close-IgareckConsoleInput $inputState}}
}
function Wait-IgareckStrategyControl($Session,[string]$Bundle) {
    $inputState=Open-IgareckConsoleInput
    $monitor=[Igareck.Public10.WinDivertHealthMonitor]::new($Bundle)
    try{
        if(-not $inputState.Supported){
            Write-Host 'F1/F2/F3 недоступны в этом хосте. Запустите CMD в обычном окне консоли; Ctrl+C останавливает Zapret2.' -ForegroundColor Yellow
        }
        while($true){
            if(Test-IgareckStopRequested){return 'Stop'}
            if($inputState.Supported){
                $command=Read-IgareckControlKey
                if($command -in @('Switch','Restart','Adapter','Stop')){return $command}
            }
            if($Session.Process.HasExited){$Session.DrainOutput()}
            $fault=[string]$Session.WinDivertError
            if(-not $fault -and $Session.Process.HasExited){$fault='PROCESS_EXIT: '+$Session.Process.ExitCode}
            if(-not $fault){$fault=$monitor.Poll([DateTime]::UtcNow)}
            if($fault){
                $script:IgareckRecoveryReason=$fault
                [Igareck.Public10.WinDivertRecovery]::Log((Get-IgareckRecoveryLog $Bundle),('DETECTED reason='+$fault+'; native_log='+$Session.LogPath+'; '+$monitor.LastState))
                return 'Recover'
            }
            $null=$Session.Process.WaitForExit(100)
        }
    }finally{Close-IgareckConsoleInput $inputState}
}
function Stop-IgareckOwnedProcess([Diagnostics.Process]$Process) {
    if(-not $Process.HasExited){
        $Process.Kill()
        if(-not $Process.WaitForExit(5000)){
            throw 'Не удалось дождаться остановки текущего winws2. Новая стратегия не запущена.'
        }
    }
}
function Save-IgareckAdapter([string]$StateDirectory,$Adapter) {
    [IO.Directory]::CreateDirectory($StateDirectory)|Out-Null
    $path=Join-Path $StateDirectory 'adapter.json'
    $temp=Join-Path $StateDirectory ('adapter.'+[guid]::NewGuid().ToString('N')+'.tmp')
    try{
        $json=@{Index=[int]$Adapter.ifIndex;Guid=[string]$Adapter.InterfaceGuid;Name=[string]$Adapter.Name}|ConvertTo-Json
        [IO.File]::WriteAllText($temp,$json,[Text.UTF8Encoding]::new($false))
        if(Test-Path -LiteralPath $path -PathType Leaf){[IO.File]::Replace($temp,$path,[NullString]::Value)}
        else{[IO.File]::Move($temp,$path)}
    }finally{
        if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force}
    }
}
function Initialize-IgareckRuntime {
    if(-not ('Igareck.Public10.EngineSession' -as [type])){
        $parameters=@{Path=@((Join-Path $PSScriptRoot 'Igareck_Runtime_20261023_public_v1.cs'),(Join-Path $PSScriptRoot 'Igareck_WinDivert_Recovery.cs'));IgnoreWarnings=$true;WarningAction='SilentlyContinue';ErrorAction='Stop'}
        if($PSVersionTable.PSVersion.Major -le 5){$parameters.ReferencedAssemblies=@('System.dll','System.Core.dll','System.IO.Compression.dll')}
        Add-Type @parameters
    }
}
function Get-IgareckLogDirectory([string]$Bundle) {
    $directory=Join-Path (Split-Path -Parent $Bundle) 'logs'
    [IO.Directory]::CreateDirectory($directory)|Out-Null
    return $directory
}
function Write-IgareckDiagnostic([string]$Path,$Data) {
    $line=$Data|ConvertTo-Json -Depth 12 -Compress
    try{[IO.File]::AppendAllText($Path,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))}
    catch{
        # An exclusively opened log must not stop the recipe scan.
        $fallback=Join-Path (Split-Path -Parent $Path) ('diagnostic_'+[guid]::NewGuid().ToString('N')+'.log')
        [IO.File]::WriteAllText($fallback,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
    }
}
function Test-IgareckNoOtherEngine {
    if(-not (Test-IgareckAdmin)){throw 'Запустите CMD от администратора.'}
    if(@(Get-Process -Name 'winws','winws2','goodbyedpi' -ErrorAction SilentlyContinue).Count){
        throw 'Другой AntiDPI уже работает. Остановите его перед запуском этого набора.'
    }
}
function Test-IgareckScanCancellation {
    if(Test-IgareckStopRequested){$script:IgareckScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
    if($null -ne $script:IgareckScanControl){
        $signal=[string]$script:IgareckScanControl.Signal
        if($signal){$script:IgareckScanSignal=$signal;throw [OperationCanceledException]::new('Проверка остановлена.')}
        if(-not $script:IgareckScanControl.ReaderError){return}
    }
    if($script:IgareckScanInputSupported){
        while([Console]::KeyAvailable){
            $key=[Console]::ReadKey($true)
            if($key.Key -eq [ConsoleKey]::Escape){$script:IgareckScanSignal='Escape';throw [OperationCanceledException]::new('Проверка остановлена.')}
            if([int]$key.KeyChar -eq 3 -or ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control))){
                $script:IgareckScanSignal='Stop';throw [OperationCanceledException]::new('Проверка остановлена.')
            }
        }
    }
}
function New-IgareckNativeSession([string]$Executable,[string]$Arguments,[string]$Directory,[string]$LogPath) {
    if(Test-IgareckStopRequested){$script:IgareckScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
    return [Igareck.Public10.EngineSession]::new($Executable,$Arguments,$Directory,$LogPath)
}
function Wait-IgareckStartupRetry([int]$Attempt,[switch]$Cancellable) {
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $delay=[Igareck.Public10.EngineStartupPolicy]::RetryDelayMilliseconds($Attempt)
    while($timer.ElapsedMilliseconds -lt $delay){
        if($Cancellable){Test-IgareckScanCancellation}
        Start-Sleep -Milliseconds 50
    }
}
function Test-IgareckEngineConfiguration($Row,[int]$Index,[string]$PortScope,[string]$Bundle,[string]$LogPath,[switch]$Cancellable) {
    Initialize-IgareckRuntime
    $native=@(Get-IgareckArguments $Row $Index $PortScope)
    $verbs=@($Row.Args|Where-Object {$_.StartsWith('--lua-desync=')}|ForEach-Object {($_.Substring(13) -split ':')[0]}|Sort-Object -Unique)
    $assertions=@($verbs|ForEach-Object {"assert(type($_)=='function','missing $_')"})
    if($Row.StockTlsPattern){$assertions+="assert(type(fake_default_tls)=='string','missing TLS pattern')"}
    $arguments=@('--intercept=0')+$native+@('--lua-init='+($assertions -join '; '))
    $joined=(@($arguments|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
    for($attempt=1;$attempt -le [Igareck.Public10.EngineStartupPolicy]::MaxAttempts;$attempt++){
        if($Cancellable){Test-IgareckScanCancellation}
        if($attempt -gt 1){Wait-IgareckStartupRetry ($attempt-1) -Cancellable:$Cancellable}
        $session=New-IgareckNativeSession (Join-Path $Bundle 'winws2.exe') $joined $Bundle $LogPath
        try{
            $session.RecordStartup(('Stage=проверка параметров/Lua; Attempt={0}/3' -f $attempt))
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while(-not $session.Process.WaitForExit(50)){
                if($Cancellable){Test-IgareckScanCancellation}
                if($timer.Elapsed.TotalSeconds -gt 15){throw ('Проверка параметров winws2 превысила время ожидания. Лог: '+$LogPath)}
            }
            $session.DrainOutput()
            $code=[int]$session.Process.ExitCode
            if($code -eq 0){return}
            if($session.WinDivertError){throw [Igareck.Public10.WinDivertEngineException]::new($session.WinDivertError,$LogPath)}
            if(-not [Igareck.Public10.EngineStartupPolicy]::IsDllInitFailure($code)){
                throw ('Проверка параметров/Lua: winws2 код {0}. Лог: {1}' -f [Igareck.Public10.EngineStartupPolicy]::FormatExit($code),$LogPath)
            }
            if($attempt -eq [Igareck.Public10.EngineStartupPolicy]::MaxAttempts){
                throw [Igareck.Public10.NativeStartupException]::new('проверка параметров/Lua',$code,$LogPath)
            }
            $session.RecordStartup(('RETRY: {0}; delay_ms={1}' -f [Igareck.Public10.EngineStartupPolicy]::FormatExit($code),[Igareck.Public10.EngineStartupPolicy]::RetryDelayMilliseconds($attempt)))
            Write-Host ('Windows: временный сбой запуска DLL winws2 (0xC0000142). Повтор {0}/3...' -f ($attempt+1)) -ForegroundColor Yellow
        }finally{$session.Dispose()}
    }
}
function Start-IgareckEngine($Row,[int]$Index,[string]$PortScope,[string]$Bundle,[string]$State,[string]$LogPath,[switch]$Cancellable) {
    Test-IgareckNoOtherEngine
    Initialize-IgareckRuntime
    $native=@(Get-IgareckArguments $Row $Index $PortScope)
    $joined=(@($native|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
    $record=Join-Path $State 'owned_process.json'
    for($attempt=1;$attempt -le [Igareck.Public10.EngineStartupPolicy]::MaxAttempts;$attempt++){
        if($Cancellable){Test-IgareckScanCancellation}
        if($attempt -gt 1){Wait-IgareckStartupRetry ($attempt-1) -Cancellable:$Cancellable}
        Test-IgareckNoOtherEngine
        $session=New-IgareckNativeSession (Join-Path $Bundle 'winws2.exe') $joined $Bundle $LogPath
        $published=$false
        try{
            $session.RecordStartup(('Stage=запуск перехвата; Attempt={0}/3' -f $attempt))
            $process=$session.Process
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while($timer.ElapsedMilliseconds -lt 1000){
                if($Cancellable){Test-IgareckScanCancellation}
                if($process.WaitForExit(40)){break}
            }
            if($Cancellable){Test-IgareckScanCancellation}
            if($process.HasExited){
                $session.DrainOutput()
                $code=[int]$process.ExitCode
                if($session.WinDivertError){throw [Igareck.Public10.WinDivertEngineException]::new($session.WinDivertError,$LogPath)}
                if(-not [Igareck.Public10.EngineStartupPolicy]::IsDllInitFailure($code)){
                    throw ('winws2 завершился при запуске: {0}. Лог: {1}' -f [Igareck.Public10.EngineStartupPolicy]::FormatExit($code),$LogPath)
                }
                if($attempt -eq [Igareck.Public10.EngineStartupPolicy]::MaxAttempts){
                    throw [Igareck.Public10.NativeStartupException]::new('запуск перехвата',$code,$LogPath)
                }
                $session.RecordStartup(('RETRY: {0}; delay_ms={1}' -f [Igareck.Public10.EngineStartupPolicy]::FormatExit($code),[Igareck.Public10.EngineStartupPolicy]::RetryDelayMilliseconds($attempt)))
                Write-Host ('Windows: временный сбой запуска DLL winws2 (0xC0000142). Повтор {0}/3...' -f ($attempt+1)) -ForegroundColor Yellow
                continue
            }
            $start=$process.StartTime.ToUniversalTime().ToString('o')
            [IO.File]::WriteAllText($record,(@{PID=$process.Id;Exe=$process.StartInfo.FileName;StartUTC=$start}|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
            $published=$true
            return $session
        }finally{
            if(-not $published){
                $session.Dispose()
                Remove-Item -LiteralPath $record -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
function Close-IgareckEngine($Session,[string]$State) {
    if($null -eq $Session){return}
    $Session.Stop()
    $Session.Dispose()
    Remove-Item -LiteralPath (Join-Path $State 'owned_process.json') -Force -ErrorAction SilentlyContinue
}
function Read-IgareckRecipeRange([hashtable]$Profiles) {
    $prompt='Введите для проверки номер одиночной стратегии или диапазон в формате Первая-Последняя (например 1-50)'
    while($true){
        $answer=Read-Host $prompt
        $m=[regex]::Match([string]$answer,'^\s*([0-9]+)(?:\s*-\s*([0-9]+))?\s*$')
        if(-not $m.Success){continue}
        $first=0;$last=0
        if(-not [int]::TryParse($m.Groups[1].Value,[ref]$first)){continue}
        $last=$first
        if($m.Groups[2].Success -and -not [int]::TryParse($m.Groups[2].Value,[ref]$last)){continue}
        if($first -lt 1 -or $last -lt $first -or -not $Profiles.ContainsKey($first) -or -not $Profiles.ContainsKey($last)){continue}
        $valid=$true
        for($n=$first;$n -le $last;$n++){if(-not $Profiles.ContainsKey($n)){$valid=$false;break}}
        if($valid){return [pscustomobject]@{First=$first;Last=$last}}
    }
}
function Read-IgareckYoutubeParallelism {
    while($true){
        $answer=([string](Read-Host 'Параллельная проверка для ускорения. Введите число одновременно проверяемых стратегий [от 1 до 5]')).Trim()
        if($answer -match '^[1-5]$'){return [int]$answer}
    }
}
function New-IgareckYoutubeJob($Row,[int]$Index,[string]$PortScope,[string]$Bundle,[string]$State,[string]$NativeLog,[int]$Slot) {
    $lease=[Igareck.Public10.ProbePortLease]::new(64)
    $published=$false
    try{
        $native=@(Get-IgareckArguments $Row $Index $PortScope -ProbePorts $lease.Ports)
        $verbs=@($Row.Args|Where-Object {$_.StartsWith('--lua-desync=')}|ForEach-Object {($_.Substring(13) -split ':')[0]}|Sort-Object -Unique)
        $assertions=@($verbs|ForEach-Object {"assert(type($_)=='function','missing $_')"})
        if($Row.StockTlsPattern){$assertions+="assert(type(fake_default_tls)=='string','missing TLS pattern')"}
        $preflight=@('--intercept=0')+$native+@('--lua-init='+($assertions -join '; '))
        $plan=[Igareck.Public10.YoutubeRecipePlan]::new()
        $plan.Number=[int]$Row.Number
        $plan.Executable=Join-Path $Bundle 'winws2.exe'
        $plan.Directory=$Bundle
        $plan.PreflightArguments=(@($preflight|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
        $plan.EngineArguments=(@($native|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
        $plan.NativeLog=$NativeLog
        $plan.RecordPath=Join-Path $State ('slot{0}_p{1}.json' -f $Slot,$Row.Number)
        $plan.Ports=$lease
        $worker=[Igareck.Public10.YoutubeRecipeCheck]::new($plan)
        $published=$true
        return [pscustomobject]@{Number=[int]$Row.Number;Slot=$Slot;Ports=$lease.Ports;Worker=$worker}
    }finally{if(-not $published){$lease.Dispose()}}
}
function Receive-IgareckYoutubeJob($Job,[string]$Log,[switch]$RetryRequired) {
    $result=$Job.Worker.Task.GetAwaiter().GetResult()
    for($attempt=0;$attempt -lt $result.Attempts.Length;$attempt++){
        Write-IgareckDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Attempt=($attempt+1);Result=$result.Attempts[$attempt]})
    }
    if($result.Error){Write-IgareckDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='TECHNICAL_ERROR';Error=$result.Error;Successes=$result.Successes})}
    if($result.Cancelled){Write-IgareckDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='CANCELLED';Signal=$script:IgareckScanSignal;Successes=$result.Successes})}
    # A replacement is allowed only after both HTTP requests and this engine have stopped.
    $Job.Worker.Dispose()
    if($RetryRequired){
        Write-IgareckDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='RETRY_AFTER_DRIVER_RECOVERY'})
        return
    }
    $status=if($result.Successes -eq 2){'PASS'}elseif($result.Successes -eq 1){'UNSTABLE'}else{'FAIL'}
    Write-IgareckDiagnostic $Log ([ordered]@{Utc=$result.CompletedUtc.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='RESULT';Status=$status;Successes=$result.Successes})
    if($result.Successes -gt 0){return ('{0} ({1})' -f $Job.Number,$status)}
}
function Invoke-IgareckYoutubeScan([hashtable]$Profiles,$Range,$Adapter,[string]$PortScope,[string]$Bundle,[string]$State,[string]$Logs,[switch]$SkipTimestamps,[Parameter(Mandatory=$true)][ValidateRange(1,5)][int]$Parallelism) {
    Test-IgareckNoOtherEngine
    Initialize-IgareckRuntime
    $tag=(Get-Date -Format 'yyyyMMdd_HHmmss_fff')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)
    $log=Join-Path $Logs ('YouTube_'+$tag+'.log')
    $scanState=Join-Path $State ('youtube_'+$tag)
    [IO.Directory]::CreateDirectory($scanState)|Out-Null
    $found=[Collections.Generic.List[string]]::new()
    $jobs=[Collections.Generic.List[object]]::new()
    $retryQueue=[Collections.Generic.Queue[int]]::new()
    $recoveryPending=$false;$recoveryReason=""
    $script:IgareckScanSignal=''
    $inputState=Open-IgareckConsoleInput
    $script:IgareckScanInputSupported=$inputState.Supported
    $previousTitle=$null
    if(-not [Console]::IsOutputRedirected){
        try{$previousTitle=$Host.UI.RawUI.WindowTitle}catch{}
    }
    try{
        $script:IgareckScanControl=[Igareck.Public10.YoutubeScanControl]::new($inputState.Supported)
        $next=[int]$Range.First;$completed=0;$total=$Range.Last-$Range.First+1
        Write-Host '----------------------'
        Write-Host 'Для остановки проверки нажмите клавишу Esc. Если нашлась рабочая стратегия, проверку можно остановить заранее.' -ForegroundColor Yellow
        if($null -ne $previousTitle){Write-Host 'Ход проверки отображается в заголовке окна.'}
        if(-not $inputState.Supported){Write-Host 'В этом хосте Esc недоступна; используйте обычное окно CMD/PowerShell.' -ForegroundColor Yellow}
        Write-Host ''
        Write-IgareckDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='START';First=$Range.First;Last=$Range.Last;Interface=[int]$Adapter.ifIndex;ThresholdBytes=102400;Attempts=2;TimeoutSeconds=15;ParallelSlots=$Parallelism;Isolation='exclusive IPv4 TCP source ports; AND WinDivert filter';URL='https://www.youtube.com/'})
        # This OS setting is shared. Configure it once before starting the workers.
        if(-not $SkipTimestamps){
            $needsTimestamps=$false
            for($n=$Range.First;$n -le $Range.Last;$n++){if($Profiles[$n].NeedsTimestamps){$needsTimestamps=$true;break}}
            if($needsTimestamps){Enable-IgareckTimestamps $State *> (Join-Path $Logs ('timestamps_'+$tag+'.log'))}
        }
        while($next -le $Range.Last -or $jobs.Count -or $retryQueue.Count){
            Test-IgareckScanCancellation
            # Publish finished recipes before doing any further preparation. Ordering is by completion,
            # never by catalogue number; a slow slot cannot hold up the other slot's result or refill.
            $ready=@($jobs | Where-Object {$_.Worker.Task.IsCompleted} | Sort-Object {$_.Worker.Task.Result.CompletedUtc})
            foreach($job in $ready){
                $script:IgareckScanControl.Unregister($job.Worker)
                $driverFailure=[bool]$job.Worker.Task.Result.DriverFailure
                $driverReason=[string]$job.Worker.Task.Result.DriverError
                $entry=Receive-IgareckYoutubeJob $job $log -RetryRequired:$driverFailure
                if($driverFailure){
                    $retryQueue.Enqueue([int]$job.Number)
                    $recoveryPending=$true;$recoveryReason=$driverReason
                }
                if($entry){
                    if($found.Count){Write-Host ', ' -NoNewline}
                    Write-Host $entry -NoNewline -ForegroundColor Green
                    $found.Add($entry)
                }
                $null=$jobs.Remove($job)
                if(-not $driverFailure){$completed++}
            }
            if($recoveryPending -and -not $jobs.Count){
                if(-not (Invoke-IgareckAutomaticRecovery $Bundle $recoveryReason)){break}
                $script:IgareckRecoveryAwaitingStart=$false
                $recoveryPending=$false
            }
            while(-not $recoveryPending -and $jobs.Count -lt $Parallelism -and ($retryQueue.Count -or $next -le $Range.Last)){
                Test-IgareckScanCancellation
                if($retryQueue.Count){$number=$retryQueue.Dequeue()}else{$number=$next;$next++}
                $slot=0
                for($candidate=1;$candidate -le $Parallelism;$candidate++){
                    if(-not @($jobs|Where-Object Slot -eq $candidate).Count){$slot=$candidate;break}
                }
                if($slot -eq 0){throw 'Не найден свободный слот проверки YouTube.'}
                $nativeLog=Join-Path $Logs ('YouTube_winws2_{0}_s{1}_p{2}.log' -f $tag,$slot,$number)
                try{
                    $job=New-IgareckYoutubeJob $Profiles[$number] ([int]$Adapter.ifIndex) $PortScope $Bundle $scanState $nativeLog $slot
                    $jobs.Add($job)
                    $script:IgareckScanControl.Register($job.Worker)
                    Write-IgareckDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$number;Slot=$slot;Event='RECIPE_START';SourcePorts=$job.Ports;NativeLog=$nativeLog})
                }catch{
                    Write-IgareckDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$number;Slot=$slot;Event='TECHNICAL_ERROR';Error=$_.Exception.Message;Successes=0})
                    $completed++
                }
            }
            if($null -ne $previousTitle){
                try{$Host.UI.RawUI.WindowTitle=('YouTube: {0} / {1}; проверяются: {2}' -f $completed,$total,(@($jobs | ForEach-Object {$_.Number}) -join ', '))}catch{}
            }
            if($jobs.Count){Start-Sleep -Milliseconds 50}
        }
    }catch [OperationCanceledException]{
        if(-not $script:IgareckScanSignal){throw}
    }finally{
        try{
            # Signal all slots before waiting for any one. No new recipe starts during cleanup.
            foreach($job in $jobs){$job.Worker.Cancel()}
            $cleanupErrors=[Collections.Generic.List[string]]::new()
            foreach($job in @($jobs.ToArray())){
                try{
                    $script:IgareckScanControl.Unregister($job.Worker)
                    $job.Worker.Dispose()
                    $entry=Receive-IgareckYoutubeJob $job $log
                    if($entry){
                        if($found.Count){Write-Host ', ' -NoNewline}
                        Write-Host $entry -NoNewline -ForegroundColor Green
                        $found.Add($entry)
                    }
                    $null=$jobs.Remove($job)
                }catch{$cleanupErrors.Add($_.Exception.Message)}
            }
            if($cleanupErrors.Count){throw ('Не удалось завершить проверочные процессы: '+($cleanupErrors -join '; '))}
        }finally{
            if($null -ne $previousTitle){try{$Host.UI.RawUI.WindowTitle=$previousTitle}catch{}}
            try{
                if($null -ne $script:IgareckScanControl){
                    $script:IgareckScanControl.Dispose()
                    $signal=[string]$script:IgareckScanControl.Signal
                    if($signal -eq 'Stop' -or ($signal -and -not $script:IgareckScanSignal)){$script:IgareckScanSignal=$signal}
                }
            }finally{
                $script:IgareckScanControl=$null
                Close-IgareckConsoleInput $inputState
                $script:IgareckScanInputSupported=$false
            }
            if($found.Count){Write-Host ''}else{Write-Host 'Рабочие стратегии не найдены'}
            Write-Host '----------------------'
            Write-IgareckDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='FINISH';Signal=$script:IgareckScanSignal;Working=$found.ToArray()})
            if(-not @(Get-ChildItem -LiteralPath $scanState -Force).Count){Remove-Item -LiteralPath $scanState -Force}
        }
    }
    return ($script:IgareckScanSignal -eq 'Stop')
}

function Show-IgareckSelectedStrategy($Row,$Adapter,[string]$PortScope,$Family) {
    if($null -eq $Family -or [int]$Family.Number -ne [int]$Row.Family){throw 'Не найдено семейство выбранной стратегии.'}
    $set=[regex]::Match([string]$Family.Name,'^(Golden|Silver)\s*/')
    if(-not $set.Success){throw 'Не определён набор выбранной стратегии.'}
    $parts=@(
        ('{0} #{1}:' -f $set.Groups[1].Value,$Row.Number),
        ('Семейство {0}: {1}; вариант {2};' -f $Row.Family,$Family.Name,$Row.Variant),
        [string]$Row.Name,
        ('Физический адаптер {0}, индекс {1}; IPv4 TLS/TCP, порты {2}' -f $Adapter.Name,$Adapter.ifIndex,$PortScope)
    )
    foreach($part in $parts){
        Write-Host $part
    }
}
function Invoke-IgareckCatalogue {
    $Scope=ConvertTo-IgareckPortScope $Scope
    $FamilyRows=@(Get-IgareckFlatRows -Rows $FamilyRows)
    $ProfileRows=@(Get-IgareckFlatRows -Rows $ProfileRows)
    if($ProfileRows.Count -ne $CatalogueInfo.ProfileCount -or $FamilyRows.Count -ne $CatalogueInfo.FamilyCount){throw 'Число записей каталога не совпадает с его описанием. Распакуйте весь архив.'}
    $profilesByNumber=@{}
    foreach($entry in $ProfileRows){
        $key=[int]$entry.Number
        if($key -lt 1 -or $profilesByNumber.ContainsKey($key)){throw 'Некорректные или повторяющиеся номера стратегий.'}
        $profilesByNumber.Add($key,$entry)
    }
    if($ListGroups){Show-IgareckFamilies;return}
    if($ListProfiles){$ProfileRows|Select-Object Number,Family,Name,Processing,Chain|Format-Table -AutoSize|Out-Host;return}
    if($ListInterfaces){Get-NetAdapter|Select-Object ifIndex,Name,Status,HardwareInterface|Format-Table -AutoSize|Out-Host;return}
    $interactiveSelection=-not [bool]$ProfileNumber
    $selection=$ProfileNumber
    if(-not $selection){Show-IgareckFamilies;$selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}
    if($selection -eq 0){return}
    if($selection -ne 'Youtube'){
        if(-not $profilesByNumber.ContainsKey([int]$selection)){throw 'В каталоге нет такого номера стратегии.'}
        $row=$profilesByNumber[[int]$selection]
        if($ShowRecipe){$row|ConvertTo-Json -Depth 40|Write-Output;return}
        if($PrintArguments){Get-IgareckArguments $row $InterfaceIndex $Scope;return}
    }
    $adapter=Select-IgareckAdapter $InterfaceIndex
    if($InterfaceIndex -le 0){$Scope=Read-IgareckTcpPorts}
    $bundle=Find-IgareckBundle $ZapretDirectory
    $state=if($StateDirectory){$StateDirectory}else{Join-Path $PSScriptRoot '_state'}
    [IO.Directory]::CreateDirectory($state)|Out-Null
    $logs=Get-IgareckLogDirectory $bundle
    Initialize-IgareckRuntime
    $lifecycle=[Igareck.Public10.WinDivertLifecycle]::new($bundle)
    $script:IgareckLifecycle=$lifecycle
    $locationPushed=$false
    try{
        Initialize-IgareckDriverControl $bundle
        Push-Location -LiteralPath $bundle
        $locationPushed=$true
        while($true){
            if(Test-IgareckStopRequested){return}
            if($selection -eq 'Youtube'){
                if(-not (Test-IgareckScopePort $Scope 443)){
                    Write-Host 'Для проверки YouTube в выбранные TCP-порты должен входить порт 443. Выберите порты для проверки.' -ForegroundColor Yellow
                    $Scope=Read-IgareckTcpPorts
                    continue
                }
                $range=Read-IgareckRecipeRange $profilesByNumber
                $parallelism=Read-IgareckYoutubeParallelism
                $stop=Invoke-IgareckYoutubeScan $profilesByNumber $range $adapter $Scope $bundle $state $logs -SkipTimestamps:$SkipTimestampSetup -Parallelism $parallelism
                if($stop){return}
                $selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount
                if($selection -eq 0){return}
                continue
            }
            $ProfileNumber=[int]$selection
            $row=$profilesByNumber[$ProfileNumber]
            $nativeLog=Join-Path $logs ('winws2_{0}_p{1}.log' -f (Get-Date -Format 'yyyyMMdd_HHmmss_fff'),$ProfileNumber)
            try{Test-IgareckEngineConfiguration $row ([int]$adapter.ifIndex) $Scope $bundle $nativeLog}
            catch [Igareck.Public10.WinDivertEngineException]{
                if(Invoke-IgareckAutomaticRecovery $bundle $_.Exception.DriverError){continue}
                if(-not $interactiveSelection){throw}
                $selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount
                if($selection -eq 0){return}
                continue
            }
            catch [Igareck.Public10.NativeStartupException]{
                if(-not $interactiveSelection){throw}
                Write-Host ('ОШИБКА: '+$_.Exception.Message) -ForegroundColor Red
                Write-Host 'Стратегия не запущена. Можно повторить её номер или выбрать другую.' -ForegroundColor Yellow
                $selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount
                if($selection -eq 0){return}
                continue
            }
            if($Check){Write-Host 'Параметры проверены. Перехват не запущен.';return}
            Test-IgareckNoOtherEngine
            if($row.NeedsTimestamps -and -not $SkipTimestampSetup){Enable-IgareckTimestamps $state}
            $session=$null;$command='Exited'
            try{
                $session=Start-IgareckEngine $row ([int]$adapter.ifIndex) $Scope $bundle $state $nativeLog
                if($script:IgareckRecoveryAwaitingStart){
                    Write-Host ('Автовосстановление: стратегия {0} снова запущена. Передача данных через VPN оценивается отдельно.' -f $ProfileNumber) -ForegroundColor Yellow
                    [Igareck.Public10.WinDivertRecovery]::Log((Get-IgareckRecoveryLog $bundle),('ENGINE_RESTARTED profile='+$ProfileNumber+'; pid='+$session.Process.Id+'; traffic_verified=false'))
                    $script:IgareckRecoveryAwaitingStart=$false
                }
                $family=$FamilyRows | Where-Object { [int]$_.Number -eq [int]$row.Family }
                Show-IgareckSelectedStrategy $row $adapter $Scope $family
                Write-Host ''
                Write-Host ('СЕЙЧАС РАБОТАЕТ СТРАТЕГИЯ {0}!' -f $row.Number) -ForegroundColor Yellow
                Write-Host ''
                Write-Host 'ЧТОБЫ СМЕНИТЬ СТРАТЕГИЮ И ВЫБРАТЬ НОВУЮ - нажмите F1' -ForegroundColor Yellow
                Write-Host 'ЧТОБЫ ПЕРЕЗАГРУЗИТЬ ТЕКУЩУЮ СТРАТЕГИЮ - нажмите F2' -ForegroundColor Yellow
                Write-Host 'ЧТОБЫ СМЕНИТЬ СЕТЕВОЙ АДАПТЕР/ПОРТ - нажмите F3' -ForegroundColor Yellow
                Write-Host 'ЧТОБЫ ПОЛНОСТЬЮ ОСТАНОВИТЬ РАБОТУ AntiDPI/ZAPRET2 - нажмите CTRL+C' -ForegroundColor Yellow
                Write-Host ''
                $command=Wait-IgareckStrategyControl $session $bundle
            }catch [Igareck.Public10.WinDivertEngineException]{
                $script:IgareckRecoveryReason=$_.Exception.DriverError
                $command='Recover'
            }catch [Igareck.Public10.NativeStartupException]{
                if(-not $interactiveSelection){throw}
                Write-Host ('ОШИБКА: '+$_.Exception.Message) -ForegroundColor Red
                Write-Host 'Стратегия не запущена. Можно повторить её номер или выбрать другую.' -ForegroundColor Yellow
                $command='StartupFailed'
            }finally{Close-IgareckEngine $session $state}
            switch($command){
                'Recover'{
                    if(Invoke-IgareckAutomaticRecovery $bundle $script:IgareckRecoveryReason){continue}
                    if(-not $interactiveSelection){throw 'Движок остановлен; автоматическое восстановление не выполнено.'}
                    $selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount
                    if($selection -eq 0){return}
                }
                'StartupFailed'{
                    $selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount
                    if($selection -eq 0){return}
                }
                'Switch'{
                    $selection=Read-IgareckStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount $ProfileNumber
                    if($selection -eq 0){return}
                }
                'Restart'{
                    Write-Host ''
                    Write-Host ('ПЕРЕЗАГРУЗКА СТРАТЕГИИ {0}...' -f $ProfileNumber) -ForegroundColor Yellow
                    Write-Host ''
                }
                'Adapter'{
                    Write-Host ''
                    Write-Host ('СТРАТЕГИЯ {0} ОСТАНОВЛЕНА!' -f $ProfileNumber) -ForegroundColor Red
                    Write-Host ''
                    $adapter=Select-IgareckAdapter -Requested ([int]$adapter.ifIndex) -Prompt
                    Save-IgareckAdapter $state $adapter
                    $Scope=Read-IgareckTcpPorts
                }
                default{return}
            }
        }
    }finally{
        if($locationPushed){Pop-Location}
        $lifecycle.Dispose()
        $script:IgareckLifecycle=$null
    }
}

if(-not (Get-Variable IgareckLibraryOnly -ErrorAction SilentlyContinue) -or -not $IgareckLibraryOnly){Invoke-IgareckCatalogue}

