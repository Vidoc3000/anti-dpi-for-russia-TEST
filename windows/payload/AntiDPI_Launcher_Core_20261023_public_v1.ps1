#requires -Version 5.1
# Shared launcher for the installer catalogues.
# Requires the original Windows Bundle for winws2, Lua and driver files.
$ErrorActionPreference='Stop'
# The classic host progress pane restores stale screen cells after scrolling.
# Use ordinary output / the window title; never draw progress over the catalogue.
$ProgressPreference='SilentlyContinue'
Set-StrictMode -Version Latest
$script:AntiDPIScanControl=$null
$script:AntiDPIScanCancelFile=$null
$script:AntiDPIRecoveryBudget=$null
$script:AntiDPIRecoveryReason=""
$script:AntiDPIRecoveryAwaitingStart=$false
$script:AntiDPILifecycle=$null
function Test-AntiDPIStopRequested {
    return ($null -ne $script:AntiDPILifecycle -and $script:AntiDPILifecycle.StopRequested)
}
function Get-AntiDPIArguments($Row,[int]$Index,[string]$PortScope,[int[]]$ProbePorts=@(),[string]$AddressFamily='ipv4',[string]$Protocol='tls') {
    if($Index -le 0){throw 'Укажите положительный индекс физического адаптера.'}
    if($AddressFamily -notin @('ipv4','ipv6')){throw 'Неподдерживаемое IP-семейство.'}
    if($Protocol -notin @('tls','quic')){throw 'Неподдерживаемый транспорт.'}
    if($ProbePorts.Count -and $Protocol -ne 'tls'){throw 'Проверочные порты TCP/TLS нельзя использовать с QUIC.'}
    $scope=ConvertTo-AntiDPIPortScope $PortScope
    $ports=if($scope -eq 'all'){'0-65535'}else{$scope}
    $transport=if($Protocol -eq 'quic'){'udp'}else{'tcp'}
    $layer7=if($Protocol -eq 'quic'){'quic'}else{'tls'}
    $wf=if($Protocol -eq 'quic'){'--wf-udp-out'}else{'--wf-tcp-out'}
    $a=[Collections.Generic.List[string]]::new()
    foreach($s in @("--wf-l3=$AddressFamily","--wf-iface=$Index","$wf=$ports",'--lua-init=@lua\zapret-lib.lua','--lua-init=@lua\zapret-antidpi.lua')){$a.Add($s)}
    if($Protocol -eq 'tls'){$a.Add('--wf-tcp-empty=0')}
    if($ProbePorts.Count){

        if(@($ProbePorts | Where-Object {$_ -lt 1 -or $_ -gt 65535}).Count){throw 'Некорректные порты проверки.'}
        $outbound=(@($ProbePorts | ForEach-Object {"tcp.SrcPort == $_"}) -join ' or ')
        $inbound=(@($ProbePorts | ForEach-Object {"tcp.DstPort == $_"}) -join ' or ')
        # AND preserves the constructor's interface, LAN and inbound SYN/ACK guards.
        $a.Add("--wf-raw-filter=tcp and ((outbound and ($outbound)) or (inbound and ($inbound)))")
    }
    if(@($Row.Args | Where-Object {$_ -match '^--lua-desync=fake:.*\bblob=reasm_data(?:[:]|$)' -and $_ -match ':tls_mod='}).Count){
        $guard=Join-Path $PSScriptRoot 'AntiDPI_ActualTLS_20261023_public_v1.lua'
        if(-not (Test-Path -LiteralPath $guard -PathType Leaf)){throw 'Нет AntiDPI_ActualTLS_20261023_public_v1.lua. Распакуйте весь архив новой версии.'}
        $a.Add('--lua-init=@'+$guard)
    }
    if($Row.Init){$a.Add('--lua-init='+$Row.Init)}
    $a.Add("--filter-$transport=$ports");$a.Add("--filter-l7=$layer7")
    # Keep the address-family-appropriate exclusion list.
    foreach($list in @(
        @{Name=($(if($AddressFamily -eq 'ipv6'){'ips6-exclude.txt'}else{'ips-exclude.txt'}));Option='--ipset-exclude='}
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
function Get-AntiDPIConsoleWidth {
    $widths=[Collections.Generic.List[int]]::new()
    try { $w=[int]$Host.UI.RawUI.WindowSize.Width; if($w -gt 0){$widths.Add($w)} } catch {}
    try { $w=[int][Console]::WindowWidth; if($w -gt 0){$widths.Add($w)} } catch {}
    if(-not $widths.Count){return 100}
    return [int]($widths | Measure-Object -Minimum).Minimum
}
function Read-AntiDPIChoice([string]$Prompt='Ваш выбор') {
    Write-Host ($Prompt+': ') -NoNewline -ForegroundColor Cyan
    $answer=Read-Host
    Write-Host ''
    return [string]$answer
}
function ConvertTo-AntiDPIPortScope([string]$Value) {
    $text=([string]$Value).Trim()
    if(-not $text -or $text -imatch '^(all|все|всё)$'){return 'all'}
    $text=$text -replace '[\u2010-\u2014\u2212]','-'
    if($text -match '(^\s*,|,\s*(,|$))'){throw 'Empty TCP port-list member.'}
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
function Test-AntiDPIScopePort([string]$PortScope,[int]$Port) {
    $scope=ConvertTo-AntiDPIPortScope $PortScope
    if($scope -eq 'all'){return $true}
    foreach($part in $scope.Split(',')){
        $ends=$part.Split('-');$first=[int]$ends[0];$last=if($ends.Count -eq 2){[int]$ends[1]}else{$first}
        if($Port -ge $first -and $Port -le $last){return $true}
    }
    return $false
}
function Read-AntiDPITcpPorts([string]$Protocol='tls') {
    $transport=if($Protocol -eq 'quic'){'UDP'}else{'TCP'}
    $default=if($Protocol -eq 'quic'){'443'}else{'all'}
    Write-Host '----------------------'
    Write-Host ''
    Write-Host ("Выберите порты назначения $transport, трафик которых будет перехватываться Zapret2.") -ForegroundColor Cyan
    if($Protocol -eq 'quic'){
        Write-Host 'Обрабатываются только распознанные QUIC Initial (UDP/QUIC); обычный UDP не изменяется.' -ForegroundColor Yellow
        Write-Host 'Для снижения нагрузки по умолчанию выбран порт 443. Параметр all захватывает весь UDP и повышает нагрузку.' -ForegroundColor Yellow
    }else{
        Write-Host 'Обрабатываются только распознанные TLS ClientHello (TCP); IPv6 выбирается отдельно.' -ForegroundColor Yellow
        Write-Host 'Динамические порты VPN могут требовать all; широкий охват увеличивает нагрузку.' -ForegroundColor Yellow
    }
    Write-Host 'Можно ввести порт, диапазон или комбинацию через запятую, например 53,80,443,1000-2000.'
    Write-Host 'Слово все/all охватывает все порты соответствующего транспорта.'
    Write-Host ''
    while($true){
        $answer=Read-AntiDPIChoice ("Ваш выбор [Enter = $default]")
        if(-not $answer.Trim()){$answer=$default}
        try{return (ConvertTo-AntiDPIPortScope $answer)}catch{Write-Host $_.Exception.Message -ForegroundColor Yellow}
    }
}
function Split-AntiDPICell([string]$Text,[int]$Width) {
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
function Get-AntiDPITableLines([string[]]$Headers,[int[]]$Widths,[object[]]$Rows) {
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
            [pscustomobject]@{Lines=@(Split-AntiDPICell ([string]$r.Cells[$c]) $Widths[$c])}
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
function Get-AntiDPIFlatRows([object[]]$Rows) {
    # Windows PowerShell 5.1 can send the entire JSON array as ONE pipeline object.
    # Flatten only catalogue containers; never recurse into a recipe's Args/Init.
    foreach($item in $Rows){
        if($item -is [Array]){Get-AntiDPIFlatRows -Rows $item;continue}
        if($null -eq $item -or $null -eq $item.PSObject.Properties['Number']){
            throw 'В каталоге обнаружена запись без номера. Распакуйте весь архив новой версии.'
        }
        $item
    }
}
function Get-AntiDPIFamilyTable([int]$Width) {
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
        Get-AntiDPITableLines -Headers @('#','Набор','Семейство','Кол.','Номера') -Widths @(2,6,($width-35),4,7) -Rows $rows.ToArray()
    }else{
        Get-AntiDPITableLines -Headers @('Поле','Значение') -Widths @(6,($width-13)) -Rows $rows.ToArray()
    }
}
function Select-AntiDPIAdapter([int]$Requested=0,[switch]$Prompt,[string]$AddressFamily='ipv4') {
    if($AddressFamily -notin @('ipv4','ipv6')){throw 'Неподдерживаемое IP-семейство.'}
    $family=if($AddressFamily -eq 'ipv6'){'IPv6'}else{'IPv4'}
    $active=@(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object {$_.Status -eq 'Up'})
    $usable=@($active | Where-Object {@(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily $family -ErrorAction SilentlyContinue | Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource -and $(if($family -eq 'IPv6'){$_.IPAddress -notmatch '^(fe80:|ff|::1$|::$)'}else{$_.IPAddress -notlike '169.254.*'})}).Count})
    if(-not $usable.Count){throw "Не найден активный физический адаптер с $family-адресом."}
    $previous=@($usable | Where-Object ifIndex -eq $Requested)
    if($Requested -and -not $Prompt){
        if($previous.Count -ne 1){throw "Адаптер $Requested недоступен. Выберите активный физический адаптер."}
        return $previous[0]
    }
    Write-Host ("Выберите активный Интернет-адаптер для работы AntiDPI-стратегий ($family)") -ForegroundColor Cyan
    $indices=@(foreach($a in $usable){[int]$a.ifIndex})
    $prefix=if($family -eq 'IPv6'){'::/0'}else{'0.0.0.0/0'}
    $rank=@(Get-NetRoute -AddressFamily $family -DestinationPrefix $prefix -ErrorAction SilentlyContinue | Where-Object {$_.InterfaceIndex -in $indices} | ForEach-Object {
        $route=$_;$ip=Get-NetIPInterface -InterfaceIndex $route.InterfaceIndex -AddressFamily $family -ErrorAction SilentlyContinue | Select-Object -First 1
        $metric=[int]$route.RouteMetric;if($null -ne $ip){$metric+=[int]$ip.InterfaceMetric}
        [pscustomobject]@{Index=[int]$route.InterfaceIndex;Metric=$metric}
    } | Sort-Object Metric)
    $recommend=if($rank.Count){$rank[0].Index}else{[int]$usable[0].ifIndex}
    $width=[Math]::Min(120,[Math]::Max(20,(Get-AntiDPIConsoleWidth)-1))
    $rows=[Collections.Generic.List[object]]::new()
    foreach($a in $usable){
        if($width -ge 60){$rows.Add([pscustomobject]@{Cells=@([string]$a.ifIndex,[string]$a.Name,[string]$a.InterfaceDescription)})}
        else{$rows.Add([pscustomobject]@{Cells=@([string]$a.ifIndex,[string]$a.Name)})}
    }
    $table=if($width -ge 60){
        $nameWidth=[int][Math]::Floor(($width-18)*0.45)
        Get-AntiDPITableLines -Headers @('Индекс','Адаптер (Up)','Описание') -Widths @(6,$nameWidth,($width-16-$nameWidth)) -Rows $rows.ToArray()
    }else{
        Get-AntiDPITableLines -Headers @('Индекс','Адаптер (Up)') -Widths @(6,($width-13)) -Rows $rows.ToArray()
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
function Show-AntiDPIFamilies {
    Write-Host ''
    Write-Host '######################'
    Write-Host ''
    $set=([string]$CatalogueInfo.Slug).Replace('_','+')
    Write-Host ('КАТАЛОГ (Октябрь 2026): {0}; {1} уникальных AntiDPI стратегии, подобранные специально для российских сетей.' -f $set,$ProfileRows.Count) -ForegroundColor Cyan
    if($CatalogueInfo.Slug -eq 'Golden_Silver'){$golden=45;$silver=[int]$ProfileRows.Count-$golden;Write-Host ('Golden: 1-{0} ({0}). Silver: {1}-{2} ({3}).' -f $golden,($golden+1),$ProfileRows.Count,$silver)}
    Write-Host '----------------------'
    Write-Host 'Вводите номер стратегии из колонки «Номера».'
    $table=@(Get-AntiDPIFamilyTable -Width ((Get-AntiDPIConsoleWidth)-1))
    for($i=0;$i -lt $table.Count;$i++){
        if($i -eq 1){Write-Host $table[$i] -ForegroundColor Cyan}else{Write-Host $table[$i]}
    }
    Write-Host ''
}

function Find-AntiDPIBundle([string]$Directory) {
    foreach($p in @($Directory,(Join-Path $Directory 'zapret-winws'),(Split-Path -Parent $PSScriptRoot))){
        if(Test-Path -LiteralPath (Join-Path $p 'winws2.exe') -PathType Leaf){
            foreach($n in @('lua\zapret-lib.lua','lua\zapret-antidpi.lua','cygwin1.dll','WinDivert.dll','WinDivert64.sys')){if(-not (Test-Path -LiteralPath (Join-Path $p $n) -PathType Leaf)){throw "Нет $n в $p"}}
            return (Resolve-Path -LiteralPath $p).Path
        }
    };throw 'Не найден Windows Bundle. Укажите -ZapretDirectory с папкой zapret-winws.'
}
function Test-AntiDPIAdmin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent();return ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Enable-AntiDPITimestamps([string]$StateDirectory) {
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
function Read-AntiDPIStrategyNumber([hashtable]$Profiles,[int]$Count,[int]$StoppedNumber=0) {
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
        $answer=Read-AntiDPIChoice;$number=0
        if(([string]$answer).Trim() -ieq 'Youtube'){return 'Youtube'}
        if([int]::TryParse($answer,[ref]$number)){
            if($number -eq 0 -or $Profiles.ContainsKey($number)){return $number}
        }
    }
}
function Open-AntiDPIConsoleInput {
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
function Close-AntiDPIConsoleInput($State) {
    if($State.Changed){[Console]::TreatControlCAsInput=[bool]$State.Previous;$State.Changed=$false}
}
function Read-AntiDPIControlKey {
    if(-not [Console]::KeyAvailable){return}
    $key=[Console]::ReadKey($true)
    if($key.Key -eq [ConsoleKey]::F1){return 'Switch'}
    if($key.Key -eq [ConsoleKey]::F2){return 'Restart'}
    if($key.Key -eq [ConsoleKey]::F3){return 'Adapter'}
    if([int]$key.KeyChar -eq 3 -or ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control))){return 'Stop'}
}
function Get-AntiDPIRecoveryLog([string]$Bundle) {
    return (Join-Path (Get-AntiDPILogDirectory $Bundle) 'WinDivert_recovery.log')
}
function Initialize-AntiDPIDriverControl([string]$Bundle) {
    Initialize-AntiDPIRuntime
    if($null -eq $script:AntiDPIRecoveryBudget){$script:AntiDPIRecoveryBudget=[AntiDPI.Public10.WinDivertRecoveryBudget]::new()}
    $snapshot=[AntiDPI.Public10.NativeWinDivertBackend]::new($Bundle).Read()
    [AntiDPI.Public10.WinDivertRecovery]::Log((Get-AntiDPIRecoveryLog $Bundle),('STARTUP '+$snapshot))
    if(-not $snapshot.FilesReady){throw $snapshot.FileProblem}
    if($snapshot.Error -eq 0 -and $snapshot.Exists -and $snapshot.Owned -and
        ($snapshot.StartType -eq 4 -or -not (Test-Path -LiteralPath $snapshot.ImagePath -PathType Leaf))){
        if(-not (Invoke-AntiDPIAutomaticRecovery $Bundle 'STARTUP_CONFIGURATION')){
            throw 'Автоматическое восстановление WinDivert не выполнено. Подробности — в WinDivert_recovery.log.'
        }
    }
}
function Invoke-AntiDPIAutomaticRecovery([string]$Bundle,[string]$Reason) {
    if(Test-AntiDPIStopRequested){$script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
    $attempt=0;$delay=0
    $log=Get-AntiDPIRecoveryLog $Bundle
    if(-not $script:AntiDPIRecoveryBudget.TryBegin([DateTime]::UtcNow,[ref]$attempt,[ref]$delay)){
        [AntiDPI.Public10.WinDivertRecovery]::Log($log,('LIMIT reason='+$Reason))
        Write-Host ('Автовосстановление приостановлено: исчерпаны 3 попытки за 10 минут. Лог: '+$log) -ForegroundColor Red
        return $false
    }
    Write-Host ''
    Write-Host ('Сбой движка/WinDivert. Автоматическое восстановление, попытка {0}/3...' -f $attempt) -ForegroundColor Yellow
    $scanning=$null -ne $script:AntiDPIScanControl
    $inputState=if($scanning){$null}else{Open-AntiDPIConsoleInput}
    try{
        $wait=[Diagnostics.Stopwatch]::StartNew()
        while($wait.ElapsedMilliseconds -lt $delay){
            if(Test-AntiDPIStopRequested){$script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
            if($scanning){Test-AntiDPIScanCancellation}
            elseif($inputState.Supported -and (Read-AntiDPIControlKey) -eq 'Stop'){
                throw [OperationCanceledException]::new('Работа остановлена пользователем.')
            }
            Start-Sleep -Milliseconds 50
        }
        $result=[AntiDPI.Public10.WinDivertRecovery]::Repair($Bundle,$log,$Reason,$attempt)
        if(Test-AntiDPIStopRequested){$script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
        if($scanning){Test-AntiDPIScanCancellation}
        elseif($inputState.Supported -and (Read-AntiDPIControlKey) -eq 'Stop'){
            throw [OperationCanceledException]::new('Работа остановлена пользователем.')
        }
        if(-not $result.Retry){
            Write-Host ('Автовосстановление не выполнено: '+$result.Reason+' Лог: '+$log) -ForegroundColor Red
            return $false
        }
        $script:AntiDPIRecoveryAwaitingStart=$true
        return $true
    }finally{if($null -ne $inputState){Close-AntiDPIConsoleInput $inputState}}
}
function Wait-AntiDPIStrategyControl($Session,[string]$Bundle) {
    $inputState=Open-AntiDPIConsoleInput
    $monitor=[AntiDPI.Public10.WinDivertHealthMonitor]::new($Bundle)
    try{
        if(-not $inputState.Supported){
            Write-Host 'F1/F2/F3 недоступны в этом хосте. Запустите CMD в обычном окне консоли; Ctrl+C останавливает Zapret2.' -ForegroundColor Yellow
        }
        while($true){
            if(Test-AntiDPIStopRequested){return 'Stop'}
            if($inputState.Supported){
                $command=Read-AntiDPIControlKey
                if($command -in @('Switch','Restart','Adapter','Stop')){return $command}
            }
            if($Session.Process.HasExited){$Session.DrainOutput()}
            $fault=[string]$Session.WinDivertError
            if(-not $fault -and $Session.Process.HasExited){$fault='PROCESS_EXIT: '+$Session.Process.ExitCode}
            if(-not $fault){$fault=$monitor.Poll([DateTime]::UtcNow)}
            if($fault){
                $script:AntiDPIRecoveryReason=$fault
                [AntiDPI.Public10.WinDivertRecovery]::Log((Get-AntiDPIRecoveryLog $Bundle),('DETECTED reason='+$fault+'; native_log='+$Session.LogPath+'; '+$monitor.LastState))
                return 'Recover'
            }
            $null=$Session.Process.WaitForExit(100)
        }
    }finally{Close-AntiDPIConsoleInput $inputState}
}
function Stop-AntiDPIOwnedProcess([Diagnostics.Process]$Process) {
    if(-not $Process.HasExited){
        $Process.Kill()
        if(-not $Process.WaitForExit(5000)){
            throw 'Не удалось дождаться остановки текущего winws2. Новая стратегия не запущена.'
        }
    }
}
function Save-AntiDPIAdapter([string]$StateDirectory,$Adapter,[string]$AddressFamily='ipv4') {
    [IO.Directory]::CreateDirectory($StateDirectory)|Out-Null
    $path=Join-Path $StateDirectory 'adapter.json'
    $temp=Join-Path $StateDirectory ('adapter.'+[guid]::NewGuid().ToString('N')+'.tmp')
    try{
        $json=@{Index=[int]$Adapter.ifIndex;Guid=[string]$Adapter.InterfaceGuid;Name=[string]$Adapter.Name;AddressFamily=$AddressFamily}|ConvertTo-Json
        [IO.File]::WriteAllText($temp,$json,[Text.UTF8Encoding]::new($false))
        if(Test-Path -LiteralPath $path -PathType Leaf){[IO.File]::Replace($temp,$path,[NullString]::Value)}
        else{[IO.File]::Move($temp,$path)}
    }finally{
        if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force}
    }
}
function Initialize-AntiDPIRuntime {
    if(-not ('AntiDPI.Public10.EngineSession' -as [type])){
        $parameters=@{Path=@((Join-Path $PSScriptRoot 'AntiDPI_Runtime_20261023_public_v1.cs'),(Join-Path $PSScriptRoot 'AntiDPI_WinDivert_Recovery.cs'));IgnoreWarnings=$true;WarningAction='SilentlyContinue';ErrorAction='Stop'}
        if($PSVersionTable.PSVersion.Major -le 5){$parameters.ReferencedAssemblies=@('System.dll','System.Core.dll','System.IO.Compression.dll')}
        Add-Type @parameters
    }
}
function Get-AntiDPILogDirectory([string]$Bundle) {
    $directory=Join-Path (Split-Path -Parent $Bundle) 'logs'
    [IO.Directory]::CreateDirectory($directory)|Out-Null
    return $directory
}
function Write-AntiDPIDiagnostic([string]$Path,$Data) {
    $line=$Data|ConvertTo-Json -Depth 12 -Compress
    try{[IO.File]::AppendAllText($Path,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))}
    catch{
        # An exclusively opened log must not stop the recipe scan.
        $fallback=Join-Path (Split-Path -Parent $Path) ('diagnostic_'+[guid]::NewGuid().ToString('N')+'.log')
        [IO.File]::WriteAllText($fallback,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
    }
}
function Get-AntiDPIAnalysisRow($Result,[int]$Number,[int]$BaselineSuccesses=-1,[int]$ExpectedAttempts=2) {
    $successes=[int]$Result.Successes
    if($Result.Cancelled){$status='CANCELLED'}elseif($Result.Error){$status='ERROR'}elseif($successes -ge $ExpectedAttempts -and $BaselineSuccesses -ge $ExpectedAttempts){$status='BASELINE_PASS'}elseif($successes -ge $ExpectedAttempts -and $BaselineSuccesses -gt 0){$status='INCONCLUSIVE'}elseif($successes -ge $ExpectedAttempts){$status='PASS'}elseif($successes -gt 0){$status='UNSTABLE'}else{$status='FAIL'}
    $attemptDetails=[Collections.Generic.List[string]]::new();$attemptNumber=0
    if($null -ne $Result.PSObject.Properties['Attempts']){
        foreach($attempt in @($Result.Attempts)){
            if($null -eq $attempt){continue};$attemptNumber++
            if($attempt.Success){$attemptDetails.Add(('Попытка {0}: HTTP {1}, {2:N0} байт, {3:N1} с' -f $attemptNumber,[int]$attempt.HttpStatus,[long]$attempt.Bytes,[double]$attempt.Seconds))}
            else{$reason=if($attempt.Reason){[string]$attempt.Reason}else{'ошибка запроса'};$attemptDetails.Add(('Попытка {0}: {1}' -f $attemptNumber,$reason))}
        }
    }
    $durations=@();if($null -ne $Result.PSObject.Properties['Attempts']){$durations=@($Result.Attempts|Where-Object {$_.Success}|ForEach-Object {[double]$_.Seconds}|Sort-Object)}
    $meanSeconds=$null;if($durations.Count){$meanSeconds=[Math]::Round((($durations|Measure-Object -Average).Average),3)}
    return [pscustomobject]@{Number=$Number;Status=$status;Successes=$successes;ExpectedAttempts=$ExpectedAttempts;BaselineSuccesses=$BaselineSuccesses;MeanSuccessSeconds=$meanSeconds;AttemptDetails=($attemptDetails -join '; ');Details=[string]$Result.Error}
}
function Write-AntiDPIAnalysisSnapshot([string]$Path,$Range,[hashtable]$Results,[int]$CurrentProfile=0,$Baseline=$null,$BaselineAfter=$null,[switch]$BracketBaseline) {
    if(-not $Path){return}
    $document=[ordered]@{Schema='antidpi.strategy-analysis.v1';CreatedUtc=[DateTime]::UtcNow.ToString('o');Test='YouTube HTTPS';AddressFamily='ipv4';Protocol='tcp-tls';Mode=$(if($BracketBaseline){'sequential-bracketed'}else{'standard'});FirstProfile=[int]$Range.First;LastProfile=[int]$Range.Last;CurrentProfile=$CurrentProfile;Baseline=$Baseline;BaselineAfter=$BaselineAfter;Results=@($Results.Values|Sort-Object Number)}
    $parent=Split-Path -Parent $Path
    [IO.Directory]::CreateDirectory($parent)|Out-Null
    $temporary=$Path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try{
        [IO.File]::WriteAllText($temporary,($document|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
        if(Test-Path -LiteralPath $Path -PathType Leaf){
            $replaced=$false
            for($attempt=0;$attempt -lt 8 -and -not $replaced;$attempt++){
                try{[IO.File]::Replace($temporary,$Path,[NullString]::Value);$replaced=$true}
                catch{if($attempt -ge 7){throw};Start-Sleep -Milliseconds 25}
            }
        }else{[IO.File]::Move($temporary,$Path)}
    }finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
}
function Test-AntiDPINoOtherEngine {
    if(-not (Test-AntiDPIAdmin)){throw 'Запустите CMD от администратора.'}
    if(@(Get-Process -Name 'winws','winws2','goodbyedpi' -ErrorAction SilentlyContinue).Count){
        throw 'Другой AntiDPI уже работает. Остановите его перед запуском этого набора.'
    }
}
function Test-AntiDPIScanCancellation {
    if($script:AntiDPIScanCancelFile -and (Test-Path -LiteralPath $script:AntiDPIScanCancelFile -PathType Leaf)){$script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Пользователь остановил анализ.')}
    if(Test-AntiDPIStopRequested){$script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
    if($null -ne $script:AntiDPIScanControl){
        $signal=[string]$script:AntiDPIScanControl.Signal
        if($signal){$script:AntiDPIScanSignal=$signal;throw [OperationCanceledException]::new('Проверка остановлена.')}
        if(-not $script:AntiDPIScanControl.ReaderError){return}
    }
    if($script:AntiDPIScanInputSupported){
        while([Console]::KeyAvailable){
            $key=[Console]::ReadKey($true)
            if($key.Key -eq [ConsoleKey]::Escape){$script:AntiDPIScanSignal='Escape';throw [OperationCanceledException]::new('Проверка остановлена.')}
            if([int]$key.KeyChar -eq 3 -or ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control))){
                $script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Проверка остановлена.')
            }
        }
    }
}
function New-AntiDPINativeSession([string]$Executable,[string]$Arguments,[string]$Directory,[string]$LogPath) {
    if(Test-AntiDPIStopRequested){$script:AntiDPIScanSignal='Stop';throw [OperationCanceledException]::new('Установка завершает работу.')}
    return [AntiDPI.Public10.EngineSession]::new($Executable,$Arguments,$Directory,$LogPath)
}
function Wait-AntiDPIStartupRetry([int]$Attempt,[switch]$Cancellable) {
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $delay=[AntiDPI.Public10.EngineStartupPolicy]::RetryDelayMilliseconds($Attempt)
    while($timer.ElapsedMilliseconds -lt $delay){
        if($Cancellable){Test-AntiDPIScanCancellation}
        Start-Sleep -Milliseconds 50
    }
}
function Test-AntiDPIEngineConfiguration($Row,[int]$Index,[string]$PortScope,[string]$Bundle,[string]$LogPath,[switch]$Cancellable,[string]$AddressFamily='ipv4',[string]$Protocol='tls') {
    Initialize-AntiDPIRuntime
    $native=@(Get-AntiDPIArguments $Row $Index $PortScope -AddressFamily $AddressFamily -Protocol $Protocol)
    $verbs=@($Row.Args|Where-Object {$_.StartsWith('--lua-desync=')}|ForEach-Object {($_.Substring(13) -split ':')[0]}|Sort-Object -Unique)
    $assertions=@($verbs|ForEach-Object {"assert(type($_)=='function','missing $_')"})
    if($Row.StockTlsPattern){$assertions+="assert(type(fake_default_tls)=='string','missing TLS pattern')"}
    $arguments=@('--intercept=0')+$native+@('--lua-init='+($assertions -join '; '))
    $joined=(@($arguments|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
    for($attempt=1;$attempt -le [AntiDPI.Public10.EngineStartupPolicy]::MaxAttempts;$attempt++){
        if($Cancellable){Test-AntiDPIScanCancellation}
        if($attempt -gt 1){Wait-AntiDPIStartupRetry ($attempt-1) -Cancellable:$Cancellable}
        $session=New-AntiDPINativeSession (Join-Path $Bundle 'winws2.exe') $joined $Bundle $LogPath
        try{
            $session.RecordStartup(('Stage=проверка параметров/Lua; Attempt={0}/3' -f $attempt))
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while(-not $session.Process.WaitForExit(50)){
                if($Cancellable){Test-AntiDPIScanCancellation}
                if($timer.Elapsed.TotalSeconds -gt 15){throw ('Проверка параметров winws2 превысила время ожидания. Лог: '+$LogPath)}
            }
            $session.DrainOutput()
            $code=[int]$session.Process.ExitCode
            if($code -eq 0){return}
            if($session.WinDivertError){throw [AntiDPI.Public10.WinDivertEngineException]::new($session.WinDivertError,$LogPath)}
            if(-not [AntiDPI.Public10.EngineStartupPolicy]::IsDllInitFailure($code)){
                throw ('Проверка параметров/Lua: winws2 код {0}. Лог: {1}' -f [AntiDPI.Public10.EngineStartupPolicy]::FormatExit($code),$LogPath)
            }
            if($attempt -eq [AntiDPI.Public10.EngineStartupPolicy]::MaxAttempts){
                throw [AntiDPI.Public10.NativeStartupException]::new('проверка параметров/Lua',$code,$LogPath)
            }
            $session.RecordStartup(('RETRY: {0}; delay_ms={1}' -f [AntiDPI.Public10.EngineStartupPolicy]::FormatExit($code),[AntiDPI.Public10.EngineStartupPolicy]::RetryDelayMilliseconds($attempt)))
            Write-Host ('Windows: временный сбой запуска DLL winws2 (0xC0000142). Повтор {0}/3...' -f ($attempt+1)) -ForegroundColor Yellow
        }finally{$session.Dispose()}
    }
}
function Start-AntiDPIEngine($Row,[int]$Index,[string]$PortScope,[string]$Bundle,[string]$State,[string]$LogPath,[switch]$Cancellable,[string]$AddressFamily='ipv4',[string]$Protocol='tls') {
    Test-AntiDPINoOtherEngine
    Initialize-AntiDPIRuntime
    $native=@(Get-AntiDPIArguments $Row $Index $PortScope -AddressFamily $AddressFamily -Protocol $Protocol)
    $joined=(@($native|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
    $record=Join-Path $State 'owned_process.json'
    for($attempt=1;$attempt -le [AntiDPI.Public10.EngineStartupPolicy]::MaxAttempts;$attempt++){
        if($Cancellable){Test-AntiDPIScanCancellation}
        if($attempt -gt 1){Wait-AntiDPIStartupRetry ($attempt-1) -Cancellable:$Cancellable}
        Test-AntiDPINoOtherEngine
        $session=New-AntiDPINativeSession (Join-Path $Bundle 'winws2.exe') $joined $Bundle $LogPath
        $published=$false
        try{
            $session.RecordStartup(('Stage=запуск перехвата; Attempt={0}/3' -f $attempt))
            $process=$session.Process
            $timer=[Diagnostics.Stopwatch]::StartNew()
            while($timer.ElapsedMilliseconds -lt 1000){
                if($Cancellable){Test-AntiDPIScanCancellation}
                if($process.WaitForExit(40)){break}
            }
            if($Cancellable){Test-AntiDPIScanCancellation}
            if($process.HasExited){
                $session.DrainOutput()
                $code=[int]$process.ExitCode
                if($session.WinDivertError){throw [AntiDPI.Public10.WinDivertEngineException]::new($session.WinDivertError,$LogPath)}
                if(-not [AntiDPI.Public10.EngineStartupPolicy]::IsDllInitFailure($code)){
                    throw ('winws2 завершился при запуске: {0}. Лог: {1}' -f [AntiDPI.Public10.EngineStartupPolicy]::FormatExit($code),$LogPath)
                }
                if($attempt -eq [AntiDPI.Public10.EngineStartupPolicy]::MaxAttempts){
                    throw [AntiDPI.Public10.NativeStartupException]::new('запуск перехвата',$code,$LogPath)
                }
                $session.RecordStartup(('RETRY: {0}; delay_ms={1}' -f [AntiDPI.Public10.EngineStartupPolicy]::FormatExit($code),[AntiDPI.Public10.EngineStartupPolicy]::RetryDelayMilliseconds($attempt)))
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
function Close-AntiDPIEngine($Session,[string]$State) {
    if($null -eq $Session){return}
    $Session.Stop()
    $Session.Dispose()
    Remove-Item -LiteralPath (Join-Path $State 'owned_process.json') -Force -ErrorAction SilentlyContinue
}
function Read-AntiDPIRecipeRange([hashtable]$Profiles) {
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
function Read-AntiDPIYoutubeParallelism {
    while($true){
        $answer=([string](Read-Host 'Параллельная проверка для ускорения. Введите число одновременно проверяемых стратегий [от 1 до 5]')).Trim()
        if($answer -match '^[1-5]$'){return [int]$answer}
    }
}
function New-AntiDPIYoutubeJob($Row,[int]$Index,[string]$PortScope,[string]$Bundle,[string]$State,[string]$NativeLog,[int]$Slot,[int]$ThresholdBytes=102400,[int]$TimeoutMilliseconds=15000,[int]$Attempts=2) {
    $lease=[AntiDPI.Public10.ProbePortLease]::new(64)
    $published=$false
    try{
        $native=@(Get-AntiDPIArguments $Row $Index $PortScope -ProbePorts $lease.Ports)
        $verbs=@($Row.Args|Where-Object {$_.StartsWith('--lua-desync=')}|ForEach-Object {($_.Substring(13) -split ':')[0]}|Sort-Object -Unique)
        $assertions=@($verbs|ForEach-Object {"assert(type($_)=='function','missing $_')"})
        if($Row.StockTlsPattern){$assertions+="assert(type(fake_default_tls)=='string','missing TLS pattern')"}
        $preflight=@('--intercept=0')+$native+@('--lua-init='+($assertions -join '; '))
        $plan=[AntiDPI.Public10.YoutubeRecipePlan]::new()
        $plan.Number=[int]$Row.Number
        $plan.Executable=Join-Path $Bundle 'winws2.exe'
        $plan.Directory=$Bundle
        $plan.PreflightArguments=(@($preflight|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
        $plan.EngineArguments=(@($native|ForEach-Object {ConvertTo-WindowsArgument $_}) -join ' ')
        $plan.NativeLog=$NativeLog
        $plan.RecordPath=Join-Path $State ('slot{0}_p{1}.json' -f $Slot,$Row.Number)
        $plan.Ports=$lease
        $plan.Threshold=$ThresholdBytes
        $plan.TimeoutMilliseconds=$TimeoutMilliseconds
        $plan.Attempts=$Attempts
        $worker=[AntiDPI.Public10.YoutubeRecipeCheck]::new($plan)
        $published=$true
        return [pscustomobject]@{Number=[int]$Row.Number;Slot=$Slot;Ports=$lease.Ports;Worker=$worker}
    }finally{if(-not $published){$lease.Dispose()}}
}
function Receive-AntiDPIYoutubeJob($Job,[string]$Log,[switch]$RetryRequired,[int]$BaselineSuccesses=-1,[int]$ExpectedAttempts=2) {
    $result=$Job.Worker.Task.GetAwaiter().GetResult()
    for($attempt=0;$attempt -lt $result.Attempts.Length;$attempt++){
        Write-AntiDPIDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Attempt=($attempt+1);Result=$result.Attempts[$attempt]})
    }
    if($result.Error){Write-AntiDPIDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='TECHNICAL_ERROR';Error=$result.Error;Successes=$result.Successes})}
    if($result.Cancelled){Write-AntiDPIDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='CANCELLED';Signal=$script:AntiDPIScanSignal;Successes=$result.Successes})}
    # A replacement is allowed only after both HTTP requests and this engine have stopped.
    $Job.Worker.Dispose()
    if($RetryRequired){
        Write-AntiDPIDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='RETRY_AFTER_DRIVER_RECOVERY'})
        return
    }
    $status=(Get-AntiDPIAnalysisRow $result ([int]$Job.Number) $BaselineSuccesses $ExpectedAttempts).Status
    Write-AntiDPIDiagnostic $Log ([ordered]@{Utc=$result.CompletedUtc.ToString('o');Profile=$Job.Number;Slot=$Job.Slot;Event='RESULT';Status=$status;Successes=$result.Successes;BaselineSuccesses=$BaselineSuccesses;ExpectedAttempts=$ExpectedAttempts})
    if($status -eq 'BASELINE_PASS'){Write-Host ('{0}: HTTPS прошёл и в контрольном запуске без тестовой стратегии; эффект этой стратегии не подтверждён.' -f $Job.Number) -ForegroundColor DarkGray;return}
    if($status -eq 'INCONCLUSIVE'){Write-Host ('{0}: контроль нестабилен; сравнение стратегии неубедительно.' -f $Job.Number) -ForegroundColor Yellow;return}
    if($result.Successes -gt 0){return ('{0} ({1})' -f $Job.Number,$status)}
}
function Test-AntiDPIYoutubeBaseline([int]$Attempts,[int]$ThresholdBytes,[int]$TimeoutMilliseconds,[string]$Log,[string]$SourceAddress) {
    $successes=0;$attemptRows=[Collections.Generic.List[object]]::new()
    for($attempt=1;$attempt -le $Attempts;$attempt++){
        Test-AntiDPIScanCancellation
        $probe=[AntiDPI.Public10.YoutubeProbe]::new('https://www.youtube.com/','www.youtube.com',$ThresholdBytes,$TimeoutMilliseconds,$null,$SourceAddress)
        try{
            while(-not $probe.Task.IsCompleted){Test-AntiDPIScanCancellation;Start-Sleep -Milliseconds 25}
            $result=$probe.Task.GetAwaiter().GetResult()
            if($result.Success){$successes++}
            $attemptRows.Add([pscustomobject]@{Attempt=$attempt;Success=[bool]$result.Success;Reason=[string]$result.Reason;Bytes=[long]$result.Bytes;Seconds=[double]$result.Seconds})
            Write-AntiDPIDiagnostic $Log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='BASELINE_ATTEMPT';Attempt=$attempt;Success=[bool]$result.Success;Reason=[string]$result.Reason;Bytes=[long]$result.Bytes;RemoteIP=[string]$result.RemoteIP})
        }finally{
            $probe.Cancel()
            if(-not $probe.Task.IsCompleted){$null=$probe.Task.Wait(3000)}
            $probe.Dispose()
        }
    }
    $status=if($successes -eq $Attempts){'PASS'}elseif($successes -gt 0){'UNSTABLE'}else{'FAIL'}
    return [pscustomobject]@{Status=$status;Successes=$successes;Attempts=$Attempts;Details=@($attemptRows.ToArray())}
}

function Invoke-AntiDPIYoutubeScan([hashtable]$Profiles,$Range,$Adapter,[string]$PortScope,[string]$Bundle,[string]$State,[string]$Logs,[switch]$SkipTimestamps,[Parameter(Mandatory=$true)][ValidateRange(1,5)][int]$Parallelism,[Parameter()][ValidateRange(1,5)][int]$Attempts=2,[Parameter()][ValidateRange(16,1048576)][int]$ThresholdBytes=102400,[Parameter()][ValidateRange(5000,120000)][int]$TimeoutMilliseconds=15000,[string]$AnalysisResultPath='',[switch]$BracketBaseline) {
    Test-AntiDPINoOtherEngine
    Initialize-AntiDPIRuntime
    $tag=(Get-Date -Format 'yyyyMMdd_HHmmss_fff')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)
    $log=Join-Path $Logs ('YouTube_'+$tag+'.log')
    $scanState=Join-Path $State ('youtube_'+$tag)
    [IO.Directory]::CreateDirectory($scanState)|Out-Null
    $found=[Collections.Generic.List[string]]::new()
    $analysisResults=@{}
    $jobs=[Collections.Generic.List[object]]::new()
    $retryQueue=[Collections.Generic.Queue[int]]::new()
    $recoveryPending=$false;$recoveryReason=""
    $script:AntiDPIScanSignal=''
    $inputState=Open-AntiDPIConsoleInput
    $script:AntiDPIScanInputSupported=$inputState.Supported
    $previousTitle=$null
    if(-not [Console]::IsOutputRedirected){
        try{$previousTitle=$Host.UI.RawUI.WindowTitle}catch{}
    }
    try{
        $script:AntiDPIScanControl=[AntiDPI.Public10.YoutubeScanControl]::new($inputState.Supported)
        $next=[int]$Range.First;$completed=0;$total=$Range.Last-$Range.First+1
        $baseline=$null
        if($AnalysisResultPath){Write-AntiDPIAnalysisSnapshot $AnalysisResultPath $Range $analysisResults $next $baseline}
        $sourceAddresses=@(Get-NetIPAddress -InterfaceIndex ([int]$Adapter.ifIndex) -AddressFamily IPv4 -ErrorAction Stop|Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource -and $_.IPAddress -notlike '169.254.*'}|Select-Object -First 1 -ExpandProperty IPAddress)
        if(-not $sourceAddresses.Count){throw 'Не найден IPv4-адрес выбранного адаптера для контрольного запроса.'}
        $sourceAddress=[string]$sourceAddresses[0]
        $baseline=Test-AntiDPIYoutubeBaseline $Attempts $ThresholdBytes $TimeoutMilliseconds $log $sourceAddress
        Write-AntiDPIDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='BASELINE';Status=$baseline.Status;Successes=$baseline.Successes;Attempts=$baseline.Attempts})
        Write-Host ('Контроль без тестовой стратегии: {0}/{1} успешных запросов.' -f $baseline.Successes,$baseline.Attempts) -ForegroundColor Cyan
        if($AnalysisResultPath){Write-AntiDPIAnalysisSnapshot $AnalysisResultPath $Range $analysisResults $next $baseline}
        Write-Host '----------------------'
        Write-Host 'Для остановки проверки нажмите клавишу Esc. Если нашлась рабочая стратегия, проверку можно остановить заранее.' -ForegroundColor Yellow
        if($null -ne $previousTitle){Write-Host 'Ход проверки отображается в заголовке окна.'}
        if(-not $inputState.Supported){Write-Host 'В этом хосте Esc недоступна; используйте обычное окно CMD/PowerShell.' -ForegroundColor Yellow}
        Write-Host ''
        Write-AntiDPIDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='START';First=$Range.First;Last=$Range.Last;Interface=[int]$Adapter.ifIndex;SourceAddress=$sourceAddress;ThresholdBytes=$ThresholdBytes;Attempts=$Attempts;TimeoutSeconds=[int]($TimeoutMilliseconds/1000);ParallelSlots=$Parallelism;Isolation='exclusive IPv4 TCP source ports; AND WinDivert filter';URL='https://www.youtube.com/'})
        # This OS setting is shared. Configure it once before starting the workers.
        if(-not $SkipTimestamps){
            $needsTimestamps=$false
            for($n=$Range.First;$n -le $Range.Last;$n++){if($Profiles[$n].NeedsTimestamps){$needsTimestamps=$true;break}}
            if($needsTimestamps){Enable-AntiDPITimestamps $State *> (Join-Path $Logs ('timestamps_'+$tag+'.log'))}
        }
        while($next -le $Range.Last -or $jobs.Count -or $retryQueue.Count){
            Test-AntiDPIScanCancellation
            # Publish finished recipes before doing any further preparation. Ordering is by completion,
            # never by catalogue number; a slow slot cannot hold up the other slot's result or refill.
            $ready=@($jobs | Where-Object {$_.Worker.Task.IsCompleted} | Sort-Object {$_.Worker.Task.Result.CompletedUtc})
            foreach($job in $ready){
                $script:AntiDPIScanControl.Unregister($job.Worker)
                $jobResult=$job.Worker.Task.GetAwaiter().GetResult()
                $driverFailure=[bool]$jobResult.DriverFailure
                $driverReason=[string]$jobResult.DriverError
                $entry=Receive-AntiDPIYoutubeJob $job $log -RetryRequired:$driverFailure -BaselineSuccesses $baseline.Successes -ExpectedAttempts $Attempts
                if($driverFailure){
                    $retryQueue.Enqueue([int]$job.Number)
                    $recoveryPending=$true;$recoveryReason=$driverReason
                }elseif($AnalysisResultPath){
                    $analysisResults[[int]$job.Number]=Get-AntiDPIAnalysisRow $jobResult ([int]$job.Number) $baseline.Successes $Attempts
                    $current=if($retryQueue.Count){[int]$retryQueue.Peek()}else{[int]$next}
                    Write-AntiDPIAnalysisSnapshot $AnalysisResultPath $Range $analysisResults $current $baseline
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
                if(-not (Invoke-AntiDPIAutomaticRecovery $Bundle $recoveryReason)){break}
                $script:AntiDPIRecoveryAwaitingStart=$false
                $recoveryPending=$false
            }
            while(-not $recoveryPending -and $jobs.Count -lt $Parallelism -and ($retryQueue.Count -or $next -le $Range.Last)){
                Test-AntiDPIScanCancellation
                if($retryQueue.Count){$number=$retryQueue.Dequeue()}else{$number=$next;$next++}
                $slot=0
                for($candidate=1;$candidate -le $Parallelism;$candidate++){
                    if(-not @($jobs|Where-Object Slot -eq $candidate).Count){$slot=$candidate;break}
                }
                if($slot -eq 0){throw 'Не найден свободный слот проверки YouTube.'}
                $nativeLog=Join-Path $Logs ('YouTube_winws2_{0}_s{1}_p{2}.log' -f $tag,$slot,$number)
                try{
                    $job=New-AntiDPIYoutubeJob $Profiles[$number] ([int]$Adapter.ifIndex) $PortScope $Bundle $scanState $nativeLog $slot $ThresholdBytes $TimeoutMilliseconds $Attempts
                    $jobs.Add($job)
                    $script:AntiDPIScanControl.Register($job.Worker)
                    Write-AntiDPIDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$number;Slot=$slot;Event='RECIPE_START';SourcePorts=$job.Ports;NativeLog=$nativeLog})
                }catch{
                    Write-AntiDPIDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Profile=$number;Slot=$slot;Event='TECHNICAL_ERROR';Error=$_.Exception.Message;Successes=0})
                    if($AnalysisResultPath){$analysisResults[[int]$number]=[pscustomobject]@{Number=[int]$number;Status='ERROR';Successes=0;Details=$_.Exception.Message};Write-AntiDPIAnalysisSnapshot $AnalysisResultPath $Range $analysisResults ([int]$next)}
                    $completed++
                }
            }
            if($null -ne $previousTitle){
                try{$Host.UI.RawUI.WindowTitle=('YouTube: {0} / {1}; проверяются: {2}' -f $completed,$total,(@($jobs | ForEach-Object {$_.Number}) -join ', '))}catch{}
            }
            if($jobs.Count){Start-Sleep -Milliseconds 50}
        }
    }catch [OperationCanceledException]{
        if(-not $script:AntiDPIScanSignal){throw}
    }finally{
        try{
            # Signal all slots before waiting for any one. No new recipe starts during cleanup.
            foreach($job in $jobs){$job.Worker.Cancel()}
            $cleanupErrors=[Collections.Generic.List[string]]::new()
            foreach($job in @($jobs.ToArray())){
                try{
                    $script:AntiDPIScanControl.Unregister($job.Worker)
                    $jobResult=$job.Worker.Task.GetAwaiter().GetResult()
                    $job.Worker.Dispose()
                    $entry=Receive-AntiDPIYoutubeJob $job $log -BaselineSuccesses $baseline.Successes -ExpectedAttempts $Attempts
                    if($AnalysisResultPath){$analysisResults[[int]$job.Number]=Get-AntiDPIAnalysisRow $jobResult ([int]$job.Number) $baseline.Successes $Attempts;Write-AntiDPIAnalysisSnapshot $AnalysisResultPath $Range $analysisResults 0 $baseline}
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
                if($null -ne $script:AntiDPIScanControl){
                    $script:AntiDPIScanControl.Dispose()
                    $signal=[string]$script:AntiDPIScanControl.Signal
                    if($signal -eq 'Stop' -or ($signal -and -not $script:AntiDPIScanSignal)){$script:AntiDPIScanSignal=$signal}
                }
            }finally{
                $script:AntiDPIScanControl=$null
                Close-AntiDPIConsoleInput $inputState
                $script:AntiDPIScanInputSupported=$false
            }
            if($found.Count){Write-Host ''}else{Write-Host 'Рабочие стратегии не найдены'}
            Write-Host '----------------------'
            Write-AntiDPIDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='FINISH';Signal=$script:AntiDPIScanSignal;Working=$found.ToArray()})
            if(-not @(Get-ChildItem -LiteralPath $scanState -Force).Count){Remove-Item -LiteralPath $scanState -Force}
        }
    }
    $baselineAfter=$null
    if($BracketBaseline -and $null -ne $baseline -and $completed -ge $total -and $script:AntiDPIScanSignal -ne 'Stop') {
        $baselineAfter=Test-AntiDPIYoutubeBaseline $Attempts $ThresholdBytes $TimeoutMilliseconds $log $sourceAddress
        Write-AntiDPIDiagnostic $log ([ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Event='BASELINE_AFTER';Status=$baselineAfter.Status;Successes=$baselineAfter.Successes;Attempts=$baselineAfter.Attempts})
    }
    if($AnalysisResultPath){Write-AntiDPIAnalysisSnapshot $AnalysisResultPath $Range $analysisResults 0 $baseline $baselineAfter -BracketBaseline:$BracketBaseline}
    return ($script:AntiDPIScanSignal -eq 'Stop')
}

function Show-AntiDPISelectedStrategy($Row,$Adapter,[string]$PortScope,$Family,[string]$AddressFamily='ipv4',[string]$Protocol='tls') {
    $ipLabel=if($AddressFamily -eq 'ipv6'){'IPv6'}else{'IPv4'}
    if($Protocol -eq 'quic'){
        Write-Host ('QUIC #{0}: {1}' -f $Row.Number,$Row.Name)
        Write-Host ('Физический адаптер {0}, индекс {1}; {2} UDP/QUIC, порты {3}.' -f $Adapter.Name,$Adapter.ifIndex,$ipLabel,$PortScope)
        Write-Host 'Обрабатываются только распознанные QUIC Initial; это не проверка сайта, приложения или VPN/Tor-туннеля.'
        return
    }
    if($null -eq $Family -or [int]$Family.Number -ne [int]$Row.Family){throw 'Не найдено семейство выбранной стратегии.'}
    $set=[regex]::Match([string]$Family.Name,'^(Golden|Silver)\s*/')
    if(-not $set.Success){throw 'Не определён набор выбранной стратегии.'}
    $parts=@(
        ('{0} #{1}:' -f $set.Groups[1].Value,$Row.Number),
        ('Семейство {0}: {1}; вариант {2};' -f $Row.Family,$Family.Name,$Row.Variant),
        [string]$Row.Name,
        ('Физический адаптер {0}, индекс {1}; {2} TLS/TCP, порты {3}' -f $Adapter.Name,$Adapter.ifIndex,$ipLabel,$PortScope),
        'Стратегия применяется к TLS ClientHello; проверка авторизации/трафика стороннего VPN или Tor-клиента не выполняется.'
    )
    foreach($part in $parts){Write-Host $part}
}


function Read-AntiDPIQuicSelection([int]$StoppedNumber=0) {
    Write-Host 'UDP/QUIC-профили: 493) fake_default_quic × 2; 494) fake_default_quic × 11; 0) выход.' -ForegroundColor Cyan
    while($true){
        $answer=Read-AntiDPIChoice 'Номер QUIC-профиля'
        if($answer -eq '0'){return 0}
        if($answer -in @('493','494')){return [int]$answer}
        if($answer -in @('1','2')){return $(if($answer -eq '1'){493}else{494})}
        Write-Host 'Введите 493, 494, 1, 2 или 0.' -ForegroundColor Yellow
    }
}

function Invoke-AntiDPICatalogue {
    $Scope=ConvertTo-AntiDPIPortScope $Scope
    $FamilyRows=@(Get-AntiDPIFlatRows -Rows $FamilyRows)
    $ProfileRows=@(Get-AntiDPIFlatRows -Rows $ProfileRows)
    if($ProfileRows.Count -ne $CatalogueInfo.ProfileCount -or $FamilyRows.Count -ne $CatalogueInfo.FamilyCount){throw 'Число записей каталога не совпадает с его описанием. Распакуйте весь архив.'}
    $profilesByNumber=@{}
    foreach($entry in $ProfileRows){
        $key=[int]$entry.Number
        if($key -lt 1 -or $profilesByNumber.ContainsKey($key)){throw 'Некорректные или повторяющиеся номера стратегий.'}
        $profilesByNumber.Add($key,$entry)
    }
    if($ListGroups){Show-AntiDPIFamilies;return}
    if($ListProfilesJson){$ProfileRows|Select-Object Number,Family,Name,Processing,Chain|ConvertTo-Json -Depth 8 -Compress|Write-Output;return}
    if($ListQuicProfilesJson){$QuicRows|Select-Object Number,Family,Name,Processing,Chain,Args|ConvertTo-Json -Depth 8 -Compress|Write-Output;return}
    if($ListProfiles){$ProfileRows|Select-Object Number,Family,Name,Processing,Chain|Format-Table -AutoSize|Out-Host;return}
    if($ListInterfaces){Get-NetAdapter|Select-Object ifIndex,Name,Status,HardwareInterface|Format-Table -AutoSize|Out-Host;return}
    if($Analyze){
        if($Protocol -ne 'tls' -or $AddressFamily -ne 'ipv4'){throw 'Анализ YouTube поддерживает только IPv4/TCP/TLS и не проверяет VPN/Tor-клиент.'}
        if($FirstProfile -lt 1 -or $LastProfile -lt $FirstProfile -or $LastProfile -gt $CatalogueInfo.ProfileCount){throw 'Укажите диапазон стратегий от 1 до 492.'}
        if($Parallelism -lt 1 -or $Parallelism -gt 5){throw 'Параллельность анализа должна быть от 1 до 5.'}
        if($AnalysisAttempts -lt 1 -or $AnalysisAttempts -gt 5){throw 'Число попыток анализа должно быть от 1 до 5.'}
        if($AnalysisThresholdKB -lt 16 -or $AnalysisThresholdKB -gt 1024){throw 'Порог ответа должен быть от 16 до 1024 КиБ.'}
        if($AnalysisTimeoutSeconds -lt 5 -or $AnalysisTimeoutSeconds -gt 120){throw 'Таймаут HTTPS должен быть от 5 до 120 секунд.'}
        if(-not (Test-AntiDPIScopePort $Scope 443)){throw 'Для YouTube-анализа используется TCP-порт 443.'}
        if($InterfaceIndex -le 0){throw 'Для анализа выберите физический адаптер.'}
        if(-not $AnalysisResultPath){throw 'Не указан файл для результатов анализа.'}
        $adapter=Select-AntiDPIAdapter $InterfaceIndex -AddressFamily ipv4
        $bundle=Find-AntiDPIBundle $ZapretDirectory
        $state=if($StateDirectory){$StateDirectory}else{Join-Path $PSScriptRoot '_state'}
        [IO.Directory]::CreateDirectory($state)|Out-Null
        $logs=Get-AntiDPILogDirectory $bundle
        Test-AntiDPINoOtherEngine
        Initialize-AntiDPIRuntime
        $lifecycle=[AntiDPI.Public10.WinDivertLifecycle]::new($bundle)
        $script:AntiDPILifecycle=$lifecycle
        $locationPushed=$false
        $script:AntiDPIScanCancelFile=$AnalysisCancelFile
        try{
            Initialize-AntiDPIDriverControl $bundle
            Push-Location -LiteralPath $bundle
            $locationPushed=$true
            $range=[pscustomobject]@{First=$FirstProfile;Last=$LastProfile}
            $null=Invoke-AntiDPIYoutubeScan $profilesByNumber $range $adapter '443' $bundle $state $logs -SkipTimestamps:$SkipTimestampSetup -Parallelism $Parallelism -Attempts $AnalysisAttempts -ThresholdBytes ($AnalysisThresholdKB*1024) -TimeoutMilliseconds ($AnalysisTimeoutSeconds*1000) -AnalysisResultPath $AnalysisResultPath -BracketBaseline:$BracketBaseline
            return
        }finally{
            $script:AntiDPIScanCancelFile=$null
            if($locationPushed){Pop-Location}
            $lifecycle.Dispose()
            $script:AntiDPILifecycle=$null
        }
    }
    $interactiveSelection=-not [bool]$ProfileNumber
    $selection=$ProfileNumber
    if(-not $selection){if($Protocol -eq 'quic'){$selection=Read-AntiDPIQuicSelection}else{Show-AntiDPIFamilies;$selection=Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}}
    if($selection -eq 0){return}
    if($selection -ne 'Youtube'){
        if($Protocol -eq 'quic'){if(-not $QuicRowsByNumber.ContainsKey([int]$selection)){throw 'Выберите QUIC-профиль 493 или 494.'};$row=$QuicRowsByNumber[[int]$selection]}else{if(-not $profilesByNumber.ContainsKey([int]$selection)){throw 'В каталоге нет такого номера стратегии.'};$row=$profilesByNumber[[int]$selection]}
        if($ShowRecipe){$row|ConvertTo-Json -Depth 40|Write-Output;return}
        if($PrintArguments){Get-AntiDPIArguments $row $InterfaceIndex $Scope -AddressFamily $AddressFamily -Protocol $Protocol;return}
    }
    $adapter=Select-AntiDPIAdapter $InterfaceIndex -AddressFamily $AddressFamily
    if($InterfaceIndex -le 0){$Scope=Read-AntiDPITcpPorts $Protocol}
    $bundle=Find-AntiDPIBundle $ZapretDirectory
    $state=if($StateDirectory){$StateDirectory}else{Join-Path $PSScriptRoot '_state'}
    [IO.Directory]::CreateDirectory($state)|Out-Null
    $logs=Get-AntiDPILogDirectory $bundle
    Initialize-AntiDPIRuntime
    $lifecycle=[AntiDPI.Public10.WinDivertLifecycle]::new($bundle)
    $script:AntiDPILifecycle=$lifecycle
    $locationPushed=$false
    try{
        Initialize-AntiDPIDriverControl $bundle
        Push-Location -LiteralPath $bundle
        $locationPushed=$true
        while($true){
            if(Test-AntiDPIStopRequested){return}
            if($selection -eq 'Youtube'){
                if(-not (Test-AntiDPIScopePort $Scope 443)){
                    Write-Host 'Для проверки YouTube в выбранные TCP-порты должен входить порт 443. Выберите порты для проверки.' -ForegroundColor Yellow
                    $Scope=Read-AntiDPITcpPorts $Protocol
                    continue
                }
                $range=Read-AntiDPIRecipeRange $profilesByNumber
                $parallelism=Read-AntiDPIYoutubeParallelism
                $stop=Invoke-AntiDPIYoutubeScan $profilesByNumber $range $adapter $Scope $bundle $state $logs -SkipTimestamps:$SkipTimestampSetup -Parallelism $parallelism -Attempts $AnalysisAttempts -ThresholdBytes ($AnalysisThresholdKB*1024) -TimeoutMilliseconds ($AnalysisTimeoutSeconds*1000)
                if($stop){return}
                $selection=if($Protocol -eq 'quic'){Read-AntiDPIQuicSelection}else{Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}
                if($selection -eq 0){return}
                continue
            }
            $ProfileNumber=[int]$selection
            $row=if($Protocol -eq 'quic'){$QuicRowsByNumber[$ProfileNumber]}else{$profilesByNumber[$ProfileNumber]}
            $nativeLog=Join-Path $logs ('winws2_{0}_p{1}.log' -f (Get-Date -Format 'yyyyMMdd_HHmmss_fff'),$ProfileNumber)
            try{Test-AntiDPIEngineConfiguration $row ([int]$adapter.ifIndex) $Scope $bundle $nativeLog -AddressFamily $AddressFamily -Protocol $Protocol}
            catch [AntiDPI.Public10.WinDivertEngineException]{
                if(Invoke-AntiDPIAutomaticRecovery $bundle $_.Exception.DriverError){continue}
                if(-not $interactiveSelection){throw}
                $selection=if($Protocol -eq 'quic'){Read-AntiDPIQuicSelection}else{Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}
                if($selection -eq 0){return}
                continue
            }
            catch [AntiDPI.Public10.NativeStartupException]{
                if(-not $interactiveSelection){throw}
                Write-Host ('ОШИБКА: '+$_.Exception.Message) -ForegroundColor Red
                Write-Host 'Стратегия не запущена. Можно повторить её номер или выбрать другую.' -ForegroundColor Yellow
                $selection=if($Protocol -eq 'quic'){Read-AntiDPIQuicSelection}else{Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}
                if($selection -eq 0){return}
                continue
            }
            if($Check){Write-Host 'Параметры проверены. Перехват не запущен.';return}
            Test-AntiDPINoOtherEngine
            if($row.NeedsTimestamps -and -not $SkipTimestampSetup){Enable-AntiDPITimestamps $state}
            $session=$null;$command='Exited'
            try{
                $session=Start-AntiDPIEngine $row ([int]$adapter.ifIndex) $Scope $bundle $state $nativeLog -AddressFamily $AddressFamily -Protocol $Protocol
                if($script:AntiDPIRecoveryAwaitingStart){
                    Write-Host ('Автовосстановление: стратегия {0} снова запущена. Передача данных через VPN оценивается отдельно.' -f $ProfileNumber) -ForegroundColor Yellow
                    [AntiDPI.Public10.WinDivertRecovery]::Log((Get-AntiDPIRecoveryLog $bundle),('ENGINE_RESTARTED profile='+$ProfileNumber+'; pid='+$session.Process.Id+'; traffic_verified=false'))
                    $script:AntiDPIRecoveryAwaitingStart=$false
                }
                $family=$FamilyRows | Where-Object { [int]$_.Number -eq [int]$row.Family }
                Show-AntiDPISelectedStrategy $row $adapter $Scope $family $AddressFamily $Protocol
                Write-Host ''
                Write-Host ('СЕЙЧАС РАБОТАЕТ СТРАТЕГИЯ {0}!' -f $row.Number) -ForegroundColor Yellow
                Write-Host ''
                Write-Host 'ЧТОБЫ СМЕНИТЬ СТРАТЕГИЮ И ВЫБРАТЬ НОВУЮ - нажмите F1' -ForegroundColor Yellow
                Write-Host 'ЧТОБЫ ПЕРЕЗАГРУЗИТЬ ТЕКУЩУЮ СТРАТЕГИЮ - нажмите F2' -ForegroundColor Yellow
                Write-Host 'ЧТОБЫ СМЕНИТЬ СЕТЕВОЙ АДАПТЕР/ПОРТ - нажмите F3' -ForegroundColor Yellow
                Write-Host 'ЧТОБЫ ПОЛНОСТЬЮ ОСТАНОВИТЬ РАБОТУ AntiDPI/ZAPRET2 - нажмите CTRL+C' -ForegroundColor Yellow
                Write-Host ''
                $command=Wait-AntiDPIStrategyControl $session $bundle
            }catch [AntiDPI.Public10.WinDivertEngineException]{
                $script:AntiDPIRecoveryReason=$_.Exception.DriverError
                $command='Recover'
            }catch [AntiDPI.Public10.NativeStartupException]{
                if(-not $interactiveSelection){throw}
                Write-Host ('ОШИБКА: '+$_.Exception.Message) -ForegroundColor Red
                Write-Host 'Стратегия не запущена. Можно повторить её номер или выбрать другую.' -ForegroundColor Yellow
                $command='StartupFailed'
            }finally{Close-AntiDPIEngine $session $state}
            switch($command){
                'Recover'{
                    if(Invoke-AntiDPIAutomaticRecovery $bundle $script:AntiDPIRecoveryReason){continue}
                    if(-not $interactiveSelection){throw 'Движок остановлен; автоматическое восстановление не выполнено.'}
                    $selection=if($Protocol -eq 'quic'){Read-AntiDPIQuicSelection}else{Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}
                    if($selection -eq 0){return}
                }
                'StartupFailed'{
                    $selection=if($Protocol -eq 'quic'){Read-AntiDPIQuicSelection}else{Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount}
                    if($selection -eq 0){return}
                }
                'Switch'{
                    if($Protocol -eq 'quic'){$selection=Read-AntiDPIQuicSelection $ProfileNumber}else{$selection=Read-AntiDPIStrategyNumber $profilesByNumber $CatalogueInfo.ProfileCount $ProfileNumber}
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
                    $adapter=Select-AntiDPIAdapter -Requested ([int]$adapter.ifIndex) -Prompt -AddressFamily $AddressFamily
                    Save-AntiDPIAdapter $state $adapter -AddressFamily $AddressFamily
                    $Scope=Read-AntiDPITcpPorts $Protocol
                }
                default{return}
            }
        }
    }finally{
        if($locationPushed){Pop-Location}
        $lifecycle.Dispose()
        $script:AntiDPILifecycle=$null
    }
}

if(-not (Get-Variable AntiDPILibraryOnly -ErrorAction SilentlyContinue) -or -not $AntiDPILibraryOnly){Invoke-AntiDPICatalogue}

