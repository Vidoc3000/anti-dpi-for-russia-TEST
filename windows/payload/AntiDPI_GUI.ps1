#requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$AntiDPILibraryOnly=$true
. (Join-Path $PSScriptRoot 'AntiDPI_Launcher_Core_20261023_public_v1.ps1')
$AntiDPILibraryOnly=$false
$installRoot=Split-Path -Parent $PSScriptRoot
$bundle=Join-Path $installRoot 'zapret-winws'
$state=Join-Path $PSScriptRoot '_state'
$catalogue=Join-Path $PSScriptRoot 'Zapret2_Golden_Silver_TLS_20261023_public_v1.ps1'
$script:analysisWorker=$null
$script:analysisResultPath=''
$script:analysisCancelFile=''
$script:guiSettingsPath=Join-Path $state 'gui-settings.json'
$script:guiSettings=@{AddressFamily='ipv4';Protocol='tls';Ports='443'}
$guiLog=Join-Path $state 'gui\startup.log'
function Write-GuiLog([string]$Message) {
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $guiLog))|Out-Null
        [IO.File]::AppendAllText($guiLog,((Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')+' '+$Message+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
    } catch {}
}
if(Test-Path -LiteralPath $script:guiSettingsPath -PathType Leaf){
    try{
        $saved=Get-Content -LiteralPath $script:guiSettingsPath -Raw -Encoding UTF8|ConvertFrom-Json
        if([string]$saved.AddressFamily -in @('ipv4','ipv6')){$script:guiSettings.AddressFamily=[string]$saved.AddressFamily}
        if([string]$saved.Protocol -in @('tls','quic')){$script:guiSettings.Protocol=[string]$saved.Protocol}
        if($saved.Ports){$script:guiSettings.Ports=ConvertTo-AntiDPIPortScope ([string]$saved.Ports)}
    }catch{Write-GuiLog ('Ignoring invalid GUI settings: '+$_.Exception.Message)}
}
Write-GuiLog 'GUI script entry'
Add-Type -AssemblyName System.Windows.Forms
Write-GuiLog 'Loaded Windows Forms assembly'
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
if(-not ('AntiDPIConsoleWindow' -as [type])){
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class AntiDPIConsoleWindow {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr handle, int command);
    public static void Hide() {
        IntPtr handle=GetConsoleWindow();
        if(handle!=IntPtr.Zero) ShowWindow(handle,0);
    }
}
'@
}
[AntiDPIConsoleWindow]::Hide()

Write-GuiLog ('GUI startup; PSVersion='+$PSVersionTable.PSVersion.ToString()+'; Apartment='+[Threading.Thread]::CurrentThread.ApartmentState)
$profileRows=@()
$script:profileItems=@()
$script:runningProfile=0
$worker=$null
$stopPending=$false

$script:closeWhenStopped=$false

function Show-GuiError([string]$Message) {
    [System.Windows.Forms.MessageBox]::Show($Message,'AntiDPI',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)|Out-Null
}
function Get-GuiProfiles([string]$Protocol='tls') {
    if($Protocol -eq 'quic'){
        $json=(& $catalogue -ListQuicProfilesJson|Out-String).Trim()
        if(-not $json){throw 'Не удалось прочитать QUIC-профили.'}
        $rows=@($json|ConvertFrom-Json)
        if($rows.Count -eq 1 -and $rows[0] -is [array]){$rows=@($rows[0])}
        return $rows
    }
    $source=[IO.File]::ReadAllText($catalogue,[Text.Encoding]::UTF8)
    $match=[regex]::Match($source,'(?s)\$ProfileRows = @''\r?\n(.*?)\r?\n''@ \| ConvertFrom-Json')
    if(-not $match.Success){throw 'Не удалось прочитать каталог стратегий. Переустановите AntiDPI.'}
    $rows=@($match.Groups[1].Value|ConvertFrom-Json)
    if($rows.Count -eq 1 -and $rows[0] -is [array]){$rows=@($rows[0])}
    return $rows
}
function Get-GuiAdapters([string]$AddressFamily='ipv4') {
    $family=if($AddressFamily -eq 'ipv6'){'IPv6'}else{'IPv4'}
    $active=@(Get-NetAdapter -Physical -ErrorAction Stop|Where-Object {$_.Status -eq 'Up'})
    return @($active|Where-Object {@(Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily $family -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource -and $(if($family -eq 'IPv6'){$_.IPAddress -notmatch '^(fe80:|ff|::1$|::$)'}else{$_.IPAddress -notlike '169.254.*'})}).Count})
}
$script:quicProfileRows=@(Get-GuiProfiles 'quic')
function Get-ProfileLabel($Profile) {
    return ('{0}  [№ {1}]' -f [string]$Profile.Name,[int]$Profile.Number)
}
function Set-GuiStatus([string]$Text,[System.Drawing.Color]$Color) {
    $statusLabel.Text=$Text
    $statusLabel.ForeColor=$Color
}
function Start-GuiStrategy {
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){return}
    try{
        $profileText=$profileBox.Text.Trim()
        $selectedProfile=$null
        if($null -ne $profileBox.SelectedItem -and $profileBox.Text -ceq [string]$profileBox.SelectedItem.Label){$selectedProfile=$profileBox.SelectedItem}
        else{$profileMatches=@($script:profileItems|Where-Object {([string]$_.Number -ceq $profileText) -or ([string]$_.Label -ceq $profileText)});if($profileMatches.Count -eq 1){$selectedProfile=$profileMatches[0]}}
        if($null -eq $selectedProfile){throw 'Выберите стратегию из списка, введите её номер или укажите точное название.'}
        if($null -eq $adapterBox.SelectedItem){throw ('Не найден активный физический адаптер с '+$addressFamilyBox.SelectedItem.Value+'. Подключите сеть и нажмите Обновить.')}
        $selectedAdapter=$adapterBox.SelectedItem
        $addressFamily=[string]$addressFamilyBox.SelectedItem.Value
        $protocol=[string]$protocolBox.SelectedItem.Value
        $scope=ConvertTo-AntiDPIPortScope $portsBox.Text
        if($scope -eq 'all' -and [System.Windows.Forms.MessageBox]::Show(('Будут перехватываться все '+$(if($protocol -eq 'quic'){'UDP'}else{'TCP'})+'-порты выбранного IP-семейства. Это может заметно увеличить нагрузку. Продолжить?'),'Широкий охват',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning) -ne [System.Windows.Forms.DialogResult]::Yes){return}
        Save-AntiDPIAdapter $state $selectedAdapter -AddressFamily $addressFamily
        $logs=Get-AntiDPILogDirectory $bundle
        $stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'
        $stdout=Join-Path $logs ('gui_'+$stamp+'.out.log')
        $stderr=Join-Path $logs ('gui_'+$stamp+'.err.log')

        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $selectedProfileNumber=[int]$selectedProfile.Number
        $script:runningProfile=$selectedProfileNumber
$launchArguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$catalogue,'-ProfileNumber',[string]$selectedProfileNumber,'-InterfaceIndex',[string]$selectedAdapter.ifIndex,'-Scope',$scope,'-AddressFamily',$addressFamily,'-Protocol',$protocol,'-ZapretDirectory',$bundle,'-StateDirectory',$state)
        $joined=(@($launchArguments|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
        $script:worker=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $script:stopPending=$false
        $startButton.Enabled=$false
        $stopButton.Enabled=$true
        $profileBox.Enabled=$false
        $adapterBox.Enabled=$false;$refreshButton.Enabled=$false;$addressFamilyBox.Enabled=$false;$protocolBox.Enabled=$false
        $portsBox.Enabled=$false
        Set-GuiStatus ('Запуск стратегии {0}…' -f $selectedProfileNumber) ([System.Drawing.Color]::DarkOrange)
    }catch{Show-GuiError $_.Exception.Message}
}
function Request-GuiStop {
    if($null -eq $script:worker -or $script:worker.HasExited){return}
    $script:stopPending=$true
    try{
        Initialize-AntiDPIRuntime
        $null=[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle)
        Set-GuiStatus 'Останавливается… завершается управляемый процесс и восстанавливается состояние.' ([System.Drawing.Color]::DarkOrange)
        $stopButton.Enabled=$false
    }catch{Show-GuiError ('Не удалось запросить остановку: '+$_.Exception.Message)}
}
function Refresh-GuiAdapters {
    $savedGuid=''
    $config=Join-Path $state 'adapter.json'
    if(Test-Path -LiteralPath $config){try{$savedGuid=[string](Get-Content -LiteralPath $config -Raw -Encoding UTF8|ConvertFrom-Json).Guid}catch{}}
    $adapterBox.Items.Clear()
    $addressFamily=[string]$addressFamilyBox.SelectedItem.Value
    $adapters=@(Get-GuiAdapters $addressFamily)
    Write-GuiLog ('Available physical '+$addressFamily+' adapters='+$adapters.Count)
    $adapterBox.DisplayMember='Name'
    foreach($adapter in $adapters){
        $item=[pscustomobject]@{Name=[string]$adapter.Name;ifIndex=[int]$adapter.ifIndex;InterfaceGuid=[string]$adapter.InterfaceGuid;InterfaceDescription=[string]$adapter.InterfaceDescription;Status=[string]$adapter.Status}
        $null=$adapterBox.Items.Add($item)
    }
    if($adapterBox.Items.Count){
        $match=-1
        for($i=0;$i -lt $adapterBox.Items.Count;$i++){if([string]$adapterBox.Items[$i].InterfaceGuid -eq $savedGuid){$match=$i;break}}
        if($match -lt 0){
            $indices=@($adapters|ForEach-Object {[int]$_.ifIndex})
            $netFamily=if($addressFamily -eq 'ipv6'){'IPv6'}else{'IPv4'};$prefix=if($addressFamily -eq 'ipv6'){'::/0'}else{'0.0.0.0/0'}
            $routes=@(Get-NetRoute -AddressFamily $netFamily -DestinationPrefix $prefix -ErrorAction SilentlyContinue|Where-Object {$_.InterfaceIndex -in $indices}|ForEach-Object {$route=$_;$ip=Get-NetIPInterface -InterfaceIndex $route.InterfaceIndex -AddressFamily $netFamily -ErrorAction SilentlyContinue|Select-Object -First 1;$metric=[int]$route.RouteMetric;if($null -ne $ip){$metric+=[int]$ip.InterfaceMetric};[pscustomobject]@{Index=[int]$route.InterfaceIndex;Metric=$metric}}|Sort-Object Metric)
            if($routes.Count){for($i=0;$i -lt $adapterBox.Items.Count;$i++){if([int]$adapterBox.Items[$i].ifIndex -eq [int]$routes[0].Index){$match=$i;break}}}
        }
        $adapterBox.SelectedIndex=if($match -ge 0){$match}else{0}
    }
}
function Set-GuiProfileItems([string]$Protocol) {
    $profileBox.Items.Clear();$profileBox.AutoCompleteCustomSource.Clear()
    $rows=if($Protocol -eq 'quic'){$script:quicProfileRows}else{$profileRows}
    $items=[Collections.Generic.List[object]]::new()
    foreach($row in $rows){
        $number=[int]$row.Number
        $label=if($Protocol -eq 'quic'){('[QUIC #{0}] {1}' -f $number,$row.Name)}else{Get-ProfileLabel $row}
        $itemFamily=if($Protocol -eq 'quic'){'QUIC'}else{[string]$row.Family}
        $item=[pscustomobject]@{Number=$number;Family=$itemFamily;Name=[string]$row.Name;Processing=[string]$row.Processing;Chain=[string]$row.Chain;Args=@($row.Args);Protocol=$Protocol;Label=$label}
        $items.Add($item);$null=$profileBox.Items.Add($item);$null=$profileBox.AutoCompleteCustomSource.Add($item.Label);$null=$profileBox.AutoCompleteCustomSource.Add([string]$item.Number)
    }
    $script:profileItems=$items.ToArray();$profileBox.SelectedIndex=-1;$profileBox.Text='';$details.Text=''
    $transport=if($Protocol -eq 'quic'){'UDP'}else{'TCP'}
    $portsLabel.Text=($transport+'-порты назначения')
    $portsBox.Text='443'
    $portsHint.Text=if($Protocol -eq 'quic'){'443 по умолчанию; all охватывает весь UDP — осторожно'}else{'443 по умолчанию; all — любые TCP-порты, выше нагрузка'}
}


function Set-GuiAnalysisResults([string]$Path) {
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){return $false}
    try{$data=Get-Content -LiteralPath $Path -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop}catch{throw ('Не удалось прочитать результаты анализа: '+$_.Exception.Message)}
    $analysisGrid.Rows.Clear()
    $results=@($data.Results)
    if($results.Count -eq 1 -and $null -eq $results[0]){$results=@()}
    foreach($result in $results){
        $number=[int]$result.Number
        $profile=@($profileRows|Where-Object {[int]$_.Number -eq $number}|Select-Object -First 1)
        $name=if($profile.Count){[string]$profile[0].Name}else{('Стратегия '+$number)}
        $status=[string]$result.Status
        $recommendation=switch($status){
            'PASS' {'Рекомендуется для YouTube'}
            'UNSTABLE' {'Нестабильно — повторите тест'}
            'FAIL' {'Не прошла тест YouTube'}
            default {'Техническая ошибка'}
        }
        $null=$analysisGrid.Rows.Add([object[]]@($number,$name,$status,$recommendation))
        $row=$analysisGrid.Rows[$analysisGrid.Rows.Count-1]
        if($status -eq 'PASS'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(225,245,233)}
        elseif($status -eq 'UNSTABLE'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(255,247,214)}
        elseif($status -eq 'FAIL'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(252,231,231)}
    }
    $passed=@($results|Where-Object {$_.Status -eq 'PASS'}).Count
    $unstable=@($results|Where-Object {$_.Status -eq 'UNSTABLE'}).Count
    $failed=@($results|Where-Object {$_.Status -eq 'FAIL'}).Count
    $errors=@($results|Where-Object {$_.Status -eq 'ERROR'}).Count
    $when=if($data.CreatedUtc){([DateTime]::Parse([string]$data.CreatedUtc).ToLocalTime().ToString('g'))}else{'—'}
    $analysisStatusLabel.Text=('Последний тест: {0} | PASS: {1} | нестабильно: {2} | FAIL: {3} | ошибки: {4}' -f $when,$passed,$unstable,$failed,$errors)
    return $true
}
function Start-GuiAnalysis {
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){return}
    try{
        if($null -eq $adapterBox.SelectedItem){throw 'Для анализа выберите доступный физический адаптер.'}
        $selectedAdapter=$adapterBox.SelectedItem
        $ipv4=@(Get-NetIPAddress -InterfaceIndex ([int]$selectedAdapter.ifIndex) -AddressFamily IPv4 -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike '169.254.*' -and -not $_.SkipAsSource})
        if(-not $ipv4.Count){throw 'Анализ YouTube требует IPv4 на выбранном физическом адаптере. Выберите адаптер с IPv4.'}
        $rangeMatch=[regex]::Match($analysisRangeBox.Text.Trim(),'^([0-9]+)(?:\s*-\s*([0-9]+))?$')
        if(-not $rangeMatch.Success){throw 'Введите номер стратегии или диапазон, например 1-45.'}
        $first=[int]$rangeMatch.Groups[1].Value
        $last=if($rangeMatch.Groups[2].Success){[int]$rangeMatch.Groups[2].Value}else{$first}
        if($first -lt 1 -or $last -lt $first -or $last -gt 492){throw 'Диапазон стратегий должен находиться в пределах 1-492.'}
        $parallelism=[int]$analysisParallelBox.SelectedItem
        $logs=Get-AntiDPILogDirectory $bundle
        $stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'
        $resultDirectory=Join-Path $state 'gui\analysis'
        [IO.Directory]::CreateDirectory($resultDirectory)|Out-Null
        $script:analysisResultPath=Join-Path $resultDirectory ('analysis_'+$stamp+'.json')
        $script:analysisCancelFile=Join-Path $resultDirectory ('cancel_'+$stamp+'.request')
        $stdout=Join-Path $logs ('analysis_'+$stamp+'.out.log')
        $stderr=Join-Path $logs ('analysis_'+$stamp+'.err.log')
        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$catalogue,'-Analyze','-FirstProfile',[string]$first,'-LastProfile',[string]$last,'-Parallelism',[string]$parallelism,'-InterfaceIndex',[string]$selectedAdapter.ifIndex,'-Scope','443','-AddressFamily','ipv4','-Protocol','tls','-ZapretDirectory',$bundle,'-StateDirectory',$state,'-AnalysisResultPath',$script:analysisResultPath,'-AnalysisCancelFile',$script:analysisCancelFile)
        $joined=(@($arguments|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
        $script:analysisWorker=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $analysisButton.Enabled=$false;$analysisCancelButton.Enabled=$true;$startButton.Enabled=$false;$settingsSaveButton.Enabled=$false
        $analysisRangeBox.Enabled=$false;$analysisParallelBox.Enabled=$false
        $analysisStatusLabel.Text=('Анализ YouTube по IPv4/TCP/TLS: стратегии {0}-{1}. Можно безопасно остановить.' -f $first,$last)
    }catch{Show-GuiError $_.Exception.Message}
}
function Request-GuiAnalysisCancel {
    if($null -eq $script:analysisWorker -or $script:analysisWorker.HasExited){return}
    try{
        [IO.File]::WriteAllText($script:analysisCancelFile,'cancel',[Text.UTF8Encoding]::new($false))
        $analysisCancelButton.Enabled=$false
        $analysisStatusLabel.Text='Останавливаем анализ и ждём завершения тестовых процессов…'
    }catch{Show-GuiError ('Не удалось запросить остановку анализа: '+$_.Exception.Message)}
}
function Save-GuiSettings {
    $family=[string]$settingsFamilyBox.SelectedItem.Value
    $protocol=[string]$settingsProtocolBox.SelectedItem.Value
    $ports=ConvertTo-AntiDPIPortScope $settingsPortsBox.Text
    $settings=@{AddressFamily=$family;Protocol=$protocol;Ports=$ports}
    [IO.Directory]::CreateDirectory((Split-Path -Parent $script:guiSettingsPath))|Out-Null
    $temporary=$script:guiSettingsPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try{
        [IO.File]::WriteAllText($temporary,($settings|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
        if(Test-Path -LiteralPath $script:guiSettingsPath -PathType Leaf){[IO.File]::Replace($temporary,$script:guiSettingsPath,[NullString]::Value)}else{[IO.File]::Move($temporary,$script:guiSettingsPath)}
    }finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force}}
    $script:guiSettings=$settings
    $addressFamilyBox.SelectedIndex=if($family -eq 'ipv6'){1}else{0}
    $protocolBox.SelectedIndex=if($protocol -eq 'quic'){1}else{0}
    $portsBox.Text=$ports
    Refresh-GuiAdapters
    $settingsStatusLabel.Text='Настройки сохранены и применены.'
}
function Load-GuiAnalysisHistory {
    $directory=Join-Path $state 'gui\analysis'
    $latest=Get-ChildItem -LiteralPath $directory -Filter 'analysis_*.json' -File -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 1
    if($latest){try{$null=Set-GuiAnalysisResults $latest.FullName}catch{Write-GuiLog ('Could not load analysis history: '+$_.Exception.Message)}}
}

try{
    if(-not (Test-Path -LiteralPath $bundle -PathType Container)){ throw 'Не найдена папка установленного Zapret2: '+$bundle}
    if(-not (Test-Path -LiteralPath (Join-Path $installRoot '.antidpi-install.json') -PathType Leaf)){throw 'Маркер установки не найден. Запустите установку заново.'}
    Write-GuiLog 'Validating installation files'
    $profileRows=Get-GuiProfiles
    Write-GuiLog ('Loaded profiles='+$profileRows.Count)
    if($profileRows.Count -ne 492){throw ('Ожидалось 492 стратегии, найдено '+$profileRows.Count+'.')}

    $form=New-Object System.Windows.Forms.Form
    $form.Text='AntiDPI — управление стратегиями'
    $form.StartPosition='CenterScreen'
    $form.Size=[System.Drawing.Size]::new(800,700)
    $form.MinimumSize=[System.Drawing.Size]::new(780,680)
    $form.Font=[System.Drawing.Font]::new('Segoe UI',10)
    $form.BackColor=[System.Drawing.Color]::FromArgb(247,249,252)
    $form.ForeColor=[System.Drawing.Color]::FromArgb(31,41,55)
    $tabs=New-Object System.Windows.Forms.TabControl
    $tabs.Location=[System.Drawing.Point]::new(16,16);$tabs.Size=[System.Drawing.Size]::new(752,650);$tabs.Anchor='Top,Bottom,Left,Right'
    $strategyTab=[System.Windows.Forms.TabPage]::new('Стратегии')
    $analysisTab=[System.Windows.Forms.TabPage]::new('Анализ')
    $settingsTab=[System.Windows.Forms.TabPage]::new('Настройки')
    $tabs.TabPages.AddRange([System.Windows.Forms.TabPage[]]@($strategyTab,$analysisTab,$settingsTab))
    $form.Controls.Add($tabs)

    $header=New-Object System.Windows.Forms.Label
    $header.Text='AntiDPI'
    $header.Font=[System.Drawing.Font]::new('Segoe UI Semibold',22,[System.Drawing.FontStyle]::Bold)
    $header.Location=[System.Drawing.Point]::new(26,18);$header.Size=[System.Drawing.Size]::new(680,42)
    $strategyTab.Controls.Add($header)
    $subtitle=New-Object System.Windows.Forms.Label
    $subtitle.Text='TCP/TLS и UDP/QUIC для IPv4 или IPv6. Это не проверка VPN/Tor-туннеля или авторизации.'
    $subtitle.Location=[System.Drawing.Point]::new(29,62);$subtitle.Size=[System.Drawing.Size]::new(680,25)
    $strategyTab.Controls.Add($subtitle)

    $familyLabel=New-Object System.Windows.Forms.Label
    $familyLabel.Text='IP-семейство';$familyLabel.Location=[System.Drawing.Point]::new(30,100);$familyLabel.Size=[System.Drawing.Size]::new(250,24)
    $strategyTab.Controls.Add($familyLabel)
    $addressFamilyBox=New-Object System.Windows.Forms.ComboBox
    $addressFamilyBox.DropDownStyle='DropDownList';$addressFamilyBox.Location=[System.Drawing.Point]::new(30,128);$addressFamilyBox.Size=[System.Drawing.Size]::new(250,32)
    $addressFamilyBox.DisplayMember='Label';$addressFamilyBox.Items.Add([pscustomobject]@{Label='IPv4';Value='ipv4'})|Out-Null;$addressFamilyBox.Items.Add([pscustomobject]@{Label='IPv6';Value='ipv6'})|Out-Null
    $addressFamilyBox.SelectedIndex=if($script:guiSettings.AddressFamily -eq 'ipv6'){1}else{0};$strategyTab.Controls.Add($addressFamilyBox)
    $protocolLabel=New-Object System.Windows.Forms.Label
    $protocolLabel.Text='Транспорт и распознаваемый протокол';$protocolLabel.Location=[System.Drawing.Point]::new(310,100);$protocolLabel.Size=[System.Drawing.Size]::new(400,24)
    $strategyTab.Controls.Add($protocolLabel)
    $protocolBox=New-Object System.Windows.Forms.ComboBox
    $protocolBox.DropDownStyle='DropDownList';$protocolBox.Location=[System.Drawing.Point]::new(310,128);$protocolBox.Size=[System.Drawing.Size]::new(400,32)
    $protocolBox.DisplayMember='Label';$protocolBox.Items.Add([pscustomobject]@{Label='TCP + TLS ClientHello';Value='tls'})|Out-Null;$protocolBox.Items.Add([pscustomobject]@{Label='UDP + QUIC Initial (HTTP/3)';Value='quic'})|Out-Null
    $protocolBox.SelectedIndex=if($script:guiSettings.Protocol -eq 'quic'){1}else{0};$strategyTab.Controls.Add($protocolBox)

    $profileLabel=New-Object System.Windows.Forms.Label
    $profileLabel.Text='Стратегия — введите номер или часть названия';$profileLabel.Location=[System.Drawing.Point]::new(30,178);$profileLabel.Size=[System.Drawing.Size]::new(500,24)
    $strategyTab.Controls.Add($profileLabel)
    $profileBox=New-Object System.Windows.Forms.ComboBox
    $profileBox.DropDownStyle='DropDown';$profileBox.AutoCompleteMode='SuggestAppend';$profileBox.AutoCompleteSource='CustomSource'
    $profileBox.Location=[System.Drawing.Point]::new(30,206);$profileBox.Size=[System.Drawing.Size]::new(680,32)
    $profileBox.Anchor='Top,Left,Right';$profileBox.DisplayMember='Label'
    $profileBox.AutoCompleteCustomSource=[System.Windows.Forms.AutoCompleteStringCollection]::new()
    $strategyTab.Controls.Add($profileBox)
    $details=New-Object System.Windows.Forms.Label
    $details.Location=[System.Drawing.Point]::new(32,244);$details.Size=[System.Drawing.Size]::new(675,40);$details.ForeColor=[System.Drawing.Color]::DimGray
    $details.Anchor='Top,Left,Right';$strategyTab.Controls.Add($details)
    $profileBox.Add_SelectedIndexChanged({if($null -ne $profileBox.SelectedItem){$p=$profileBox.SelectedItem;$details.Text=if($p.Protocol -eq 'quic'){('UDP/QUIC Initial; стратегия: {0}' -f $p.Chain)}else{('Семейство {0}    Обработка: {1}    Цепочка: {2}' -f $p.Family,$p.Processing,$p.Chain)}}})

    $adapterLabel=New-Object System.Windows.Forms.Label
    $adapterLabel.Text='Активный физический адаптер с адресом выбранного IP-семейства';$adapterLabel.Location=[System.Drawing.Point]::new(30,294);$adapterLabel.Size=[System.Drawing.Size]::new(500,24)
    $strategyTab.Controls.Add($adapterLabel)
    $adapterBox=New-Object System.Windows.Forms.ComboBox
    $adapterBox.DropDownStyle='DropDownList';$adapterBox.Location=[System.Drawing.Point]::new(30,322);$adapterBox.Size=[System.Drawing.Size]::new(500,32);$adapterBox.Anchor='Top,Left,Right'
    $strategyTab.Controls.Add($adapterBox)
    $refreshButton=New-Object System.Windows.Forms.Button
    $refreshButton.Text='Обновить';$refreshButton.Location=[System.Drawing.Point]::new(544,321);$refreshButton.Size=[System.Drawing.Size]::new(166,34);$refreshButton.Anchor='Top,Right'
    $strategyTab.Controls.Add($refreshButton)
    $refreshButton.Add_Click({try{Refresh-GuiAdapters}catch{Show-GuiError $_.Exception.Message}})
    $addressFamilyBox.Add_SelectedIndexChanged({try{Refresh-GuiAdapters}catch{Show-GuiError $_.Exception.Message}})

    $portsLabel=New-Object System.Windows.Forms.Label
    $portsLabel.Text='Порты назначения';$portsLabel.Location=[System.Drawing.Point]::new(30,374);$portsLabel.Size=[System.Drawing.Size]::new(260,24)
    $strategyTab.Controls.Add($portsLabel)
    $portsBox=New-Object System.Windows.Forms.TextBox
    $portsBox.Text='443';$portsBox.Location=[System.Drawing.Point]::new(30,402);$portsBox.Size=[System.Drawing.Size]::new(300,30)
    $strategyTab.Controls.Add($portsBox)
    $portsHint=New-Object System.Windows.Forms.Label
    $portsHint.Text='';$portsHint.Location=[System.Drawing.Point]::new(344,405);$portsHint.Size=[System.Drawing.Size]::new(365,34);$portsHint.Anchor='Top,Left,Right';$portsHint.ForeColor=[System.Drawing.Color]::DimGray
    $strategyTab.Controls.Add($portsHint)
    Set-GuiProfileItems $script:guiSettings.Protocol
    $portsBox.Text=$script:guiSettings.Ports
    $protocolBox.Add_SelectedIndexChanged({if($null -ne $protocolBox.SelectedItem){Set-GuiProfileItems ([string]$protocolBox.SelectedItem.Value)}})

    $startButton=New-Object System.Windows.Forms.Button
    $startButton.Text='Запустить стратегию';$startButton.Location=[System.Drawing.Point]::new(30,462);$startButton.Size=[System.Drawing.Size]::new(210,42);$startButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$startButton.ForeColor=[System.Drawing.Color]::White;$startButton.FlatStyle='Flat'
    $startButton.Add_Click({Start-GuiStrategy});$strategyTab.Controls.Add($startButton)
    $stopButton=New-Object System.Windows.Forms.Button
    $stopButton.Text='Остановить';$stopButton.Location=[System.Drawing.Point]::new(251,462);$stopButton.Size=[System.Drawing.Size]::new(145,42);$stopButton.Enabled=$false
    $stopButton.Add_Click({Request-GuiStop});$strategyTab.Controls.Add($stopButton)
    $logsButton=New-Object System.Windows.Forms.Button
    $logsButton.Text='Открыть логи';$logsButton.Location=[System.Drawing.Point]::new(407,462);$logsButton.Size=[System.Drawing.Size]::new(145,42)
    $logsButton.Add_Click({try{$directory=Get-AntiDPILogDirectory $bundle;Start-Process explorer.exe -ArgumentList (ConvertTo-WindowsArgument $directory)}catch{Show-GuiError $_.Exception.Message}});$strategyTab.Controls.Add($logsButton)
    $statusLabel=New-Object System.Windows.Forms.Label
    $statusLabel.Text='Готово к запуску';$statusLabel.Location=[System.Drawing.Point]::new(30,525);$statusLabel.Size=[System.Drawing.Size]::new(680,25);$statusLabel.Anchor='Left,Right,Bottom';$statusLabel.ForeColor=[System.Drawing.Color]::DarkGreen
    $strategyTab.Controls.Add($statusLabel)

    $analysisInfo=New-Object System.Windows.Forms.Label
    $analysisInfo.Text='Проверяется только YouTube по IPv4/TCP/TLS. PASS означает успешные HTTPS-попытки, но не доказывает работу VPN/Tor или другого приложения. Дважды щёлкните PASS, чтобы выбрать стратегию; запуск не выполняется автоматически.'
    $analysisInfo.Location=[System.Drawing.Point]::new(20,18);$analysisInfo.Size=[System.Drawing.Size]::new(690,52);$analysisInfo.Anchor='Top,Left,Right'
    $analysisTab.Controls.Add($analysisInfo)
    $analysisRangeLabel=New-Object System.Windows.Forms.Label
    $analysisRangeLabel.Text='Номера стратегий (например, 1-45)';$analysisRangeLabel.Location=[System.Drawing.Point]::new(22,82);$analysisRangeLabel.Size=[System.Drawing.Size]::new(300,24)
    $analysisTab.Controls.Add($analysisRangeLabel)
    $analysisRangeBox=New-Object System.Windows.Forms.TextBox
    $analysisRangeBox.Text='1-45';$analysisRangeBox.Location=[System.Drawing.Point]::new(22,110);$analysisRangeBox.Size=[System.Drawing.Size]::new(180,30)
    $analysisTab.Controls.Add($analysisRangeBox)
    $analysisParallelLabel=New-Object System.Windows.Forms.Label
    $analysisParallelLabel.Text='Одновременно';$analysisParallelLabel.Location=[System.Drawing.Point]::new(222,82);$analysisParallelLabel.Size=[System.Drawing.Size]::new(140,24)
    $analysisTab.Controls.Add($analysisParallelLabel)
    $analysisParallelBox=New-Object System.Windows.Forms.ComboBox
    $analysisParallelBox.DropDownStyle='DropDownList';$analysisParallelBox.Location=[System.Drawing.Point]::new(222,110);$analysisParallelBox.Size=[System.Drawing.Size]::new(110,30)
    foreach($n in 1..5){$null=$analysisParallelBox.Items.Add([string]$n)}
    $analysisParallelBox.SelectedItem='2';$analysisTab.Controls.Add($analysisParallelBox)
    $analysisButton=New-Object System.Windows.Forms.Button
    $analysisButton.Text='Начать анализ';$analysisButton.Location=[System.Drawing.Point]::new(354,108);$analysisButton.Size=[System.Drawing.Size]::new(160,36);$analysisButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$analysisButton.ForeColor=[System.Drawing.Color]::White
    $analysisTab.Controls.Add($analysisButton)
    $analysisCancelButton=New-Object System.Windows.Forms.Button
    $analysisCancelButton.Text='Остановить';$analysisCancelButton.Location=[System.Drawing.Point]::new(524,108);$analysisCancelButton.Size=[System.Drawing.Size]::new(150,36);$analysisCancelButton.Enabled=$false
    $analysisTab.Controls.Add($analysisCancelButton)
    $analysisGrid=New-Object System.Windows.Forms.DataGridView
    $analysisGrid.Location=[System.Drawing.Point]::new(20,158);$analysisGrid.Size=[System.Drawing.Size]::new(690,365);$analysisGrid.Anchor='Top,Bottom,Left,Right'
    $analysisGrid.ReadOnly=$true;$analysisGrid.AllowUserToAddRows=$false;$analysisGrid.AllowUserToDeleteRows=$false;$analysisGrid.RowHeadersVisible=$false
    $analysisGrid.AutoSizeColumnsMode='Fill';$analysisGrid.SelectionMode='FullRowSelect';$analysisGrid.MultiSelect=$false
    foreach($column in @(
        @{Name='Number';Header='№';Fill=55},
        @{Name='Name';Header='Стратегия';Fill=210},
        @{Name='Status';Header='Результат';Fill=90},
        @{Name='Recommendation';Header='Оценка';Fill=245}
    )){
        $gridColumn=New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $gridColumn.Name=$column.Name;$gridColumn.HeaderText=$column.Header;$gridColumn.FillWeight=[single]$column.Fill
        $null=$analysisGrid.Columns.Add($gridColumn)
    }
    $analysisTab.Controls.Add($analysisGrid)
    $analysisStatusLabel=New-Object System.Windows.Forms.Label
    $analysisStatusLabel.Text='Ещё нет результатов. Для сравнения начните с Golden-стратегий 1-45.'
    $analysisStatusLabel.Location=[System.Drawing.Point]::new(22,535);$analysisStatusLabel.Size=[System.Drawing.Size]::new(690,40);$analysisStatusLabel.Anchor='Bottom,Left,Right'
    $analysisTab.Controls.Add($analysisStatusLabel)

    $settingsInfo=New-Object System.Windows.Forms.Label
    $settingsInfo.Text='Сохраните значения по умолчанию для следующего запуска. Они не включают трафик сами по себе; стратегия начинает работать только после нажатия «Запустить стратегию».'
    $settingsInfo.Location=[System.Drawing.Point]::new(24,24);$settingsInfo.Size=[System.Drawing.Size]::new(680,52);$settingsInfo.Anchor='Top,Left,Right'
    $settingsTab.Controls.Add($settingsInfo)
    $settingsFamilyLabel=New-Object System.Windows.Forms.Label
    $settingsFamilyLabel.Text='IP-семейство по умолчанию';$settingsFamilyLabel.Location=[System.Drawing.Point]::new(28,96);$settingsFamilyLabel.Size=[System.Drawing.Size]::new(300,24)
    $settingsTab.Controls.Add($settingsFamilyLabel)
    $settingsFamilyBox=New-Object System.Windows.Forms.ComboBox
    $settingsFamilyBox.DropDownStyle='DropDownList';$settingsFamilyBox.DisplayMember='Label';$settingsFamilyBox.Location=[System.Drawing.Point]::new(28,124);$settingsFamilyBox.Size=[System.Drawing.Size]::new(300,32)
    $null=$settingsFamilyBox.Items.Add([pscustomobject]@{Label='IPv4';Value='ipv4'});$null=$settingsFamilyBox.Items.Add([pscustomobject]@{Label='IPv6';Value='ipv6'})
    $settingsFamilyBox.SelectedIndex=if($script:guiSettings.AddressFamily -eq 'ipv6'){1}else{0};$settingsTab.Controls.Add($settingsFamilyBox)
    $settingsProtocolLabel=New-Object System.Windows.Forms.Label
    $settingsProtocolLabel.Text='Режим по умолчанию';$settingsProtocolLabel.Location=[System.Drawing.Point]::new(360,96);$settingsProtocolLabel.Size=[System.Drawing.Size]::new(300,24)
    $settingsTab.Controls.Add($settingsProtocolLabel)
    $settingsProtocolBox=New-Object System.Windows.Forms.ComboBox
    $settingsProtocolBox.DropDownStyle='DropDownList';$settingsProtocolBox.DisplayMember='Label';$settingsProtocolBox.Location=[System.Drawing.Point]::new(360,124);$settingsProtocolBox.Size=[System.Drawing.Size]::new(340,32)
    $null=$settingsProtocolBox.Items.Add([pscustomobject]@{Label='TCP + TLS ClientHello';Value='tls'});$null=$settingsProtocolBox.Items.Add([pscustomobject]@{Label='UDP + QUIC Initial';Value='quic'})
    $settingsProtocolBox.SelectedIndex=if($script:guiSettings.Protocol -eq 'quic'){1}else{0};$settingsTab.Controls.Add($settingsProtocolBox)
    $settingsPortsLabel=New-Object System.Windows.Forms.Label
    $settingsPortsLabel.Text='Порты по умолчанию (например, 443 или 80,443)';$settingsPortsLabel.Location=[System.Drawing.Point]::new(28,178);$settingsPortsLabel.Size=[System.Drawing.Size]::new(500,24)
    $settingsTab.Controls.Add($settingsPortsLabel)
    $settingsPortsBox=New-Object System.Windows.Forms.TextBox
    $settingsPortsBox.Text=[string]$script:guiSettings.Ports;$settingsPortsBox.Location=[System.Drawing.Point]::new(28,206);$settingsPortsBox.Size=[System.Drawing.Size]::new(420,30)
    $settingsTab.Controls.Add($settingsPortsBox)
    $settingsSaveButton=New-Object System.Windows.Forms.Button
    $settingsSaveButton.Text='Сохранить настройки';$settingsSaveButton.Location=[System.Drawing.Point]::new(28,256);$settingsSaveButton.Size=[System.Drawing.Size]::new(210,40);$settingsSaveButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$settingsSaveButton.ForeColor=[System.Drawing.Color]::White
    $settingsTab.Controls.Add($settingsSaveButton)
    $settingsStatusLabel=New-Object System.Windows.Forms.Label
    $settingsStatusLabel.Text='';$settingsStatusLabel.Location=[System.Drawing.Point]::new(28,312);$settingsStatusLabel.Size=[System.Drawing.Size]::new(650,32)
    $settingsTab.Controls.Add($settingsStatusLabel)
    $settingsSaveButton.Add_Click({try{Save-GuiSettings}catch{Show-GuiError $_.Exception.Message}})
    $analysisButton.Add_Click({Start-GuiAnalysis})
    $analysisCancelButton.Add_Click({Request-GuiAnalysisCancel})
    $analysisGrid.Add_CellDoubleClick({
        param($sender,$eventArgs)
        if($eventArgs.RowIndex -lt 0){return}
        $status=[string]$analysisGrid.Rows[$eventArgs.RowIndex].Cells['Status'].Value
        if($status -ne 'PASS'){return}
        $number=[int]$analysisGrid.Rows[$eventArgs.RowIndex].Cells['Number'].Value
        $addressFamilyBox.SelectedIndex=0
        $protocolBox.SelectedIndex=0
        $portsBox.Text='443'
        $profileBox.Text=[string]$number
        $tabs.SelectedTab=$strategyTab
        Set-GuiStatus ('Выбрана стратегия {0}, прошедшая только YouTube-тест. VPN/Tor проверьте отдельно.' -f $number) ([System.Drawing.Color]::DarkOrange)
    })

    Refresh-GuiAdapters
    Load-GuiAnalysisHistory
    $timer=New-Object System.Windows.Forms.Timer
    $timer.Interval=800
    $timer.Add_Tick({
        if($null -ne $script:worker -and $script:worker.HasExited){
            $code=$script:worker.ExitCode
            $script:worker.Dispose();$script:worker=$null
            $script:stopPending=$false
            $startButton.Enabled=$true;$stopButton.Enabled=$false;$profileBox.Enabled=$true;$adapterBox.Enabled=$true;$refreshButton.Enabled=$true;$portsBox.Enabled=$true;$addressFamilyBox.Enabled=$true;$protocolBox.Enabled=$true
            if($code -eq 0){Set-GuiStatus 'Остановлено. Можно выбрать другую стратегию и запустить снова.' ([System.Drawing.Color]::DarkGreen)}
            else{Set-GuiStatus ('Процесс завершился с кодом {0}; откройте логи для подробностей.' -f $code) ([System.Drawing.Color]::Firebrick)}
            if($script:closeWhenStopped -and $null -eq $script:analysisWorker){$form.Close()}
        }elseif($script:stopPending -and $null -ne $script:worker){
            try{$null=[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle)}catch{}
        }elseif($null -ne $script:worker){
            $ownedRecord=Join-Path $state 'owned_process.json'
            if(Test-Path -LiteralPath $ownedRecord){
                try{$owned=Get-Content -LiteralPath $ownedRecord -Raw|ConvertFrom-Json;$engine=Get-Process -Id ([int]$owned.PID) -ErrorAction Stop;if($engine.Path -ieq [string]$owned.Exe -and $engine.StartTime.ToUniversalTime().ToString('o') -ceq [string]$owned.StartUTC){Set-GuiStatus ('Работает стратегия {0} на выбранном адаптере.' -f [int]$script:runningProfile) ([System.Drawing.Color]::DarkGreen)}}catch{}
            }
        }
        if($null -ne $script:analysisWorker -and $script:analysisWorker.HasExited){
            $code=$script:analysisWorker.ExitCode
            $script:analysisWorker.Dispose();$script:analysisWorker=$null
            $analysisButton.Enabled=$true;$analysisCancelButton.Enabled=$false;$analysisRangeBox.Enabled=$true;$analysisParallelBox.Enabled=$true
            $startButton.Enabled=$true;$settingsSaveButton.Enabled=$true
            if(Test-Path -LiteralPath $script:analysisCancelFile){Remove-Item -LiteralPath $script:analysisCancelFile -Force -ErrorAction SilentlyContinue}
            if(Test-Path -LiteralPath $script:analysisResultPath -PathType Leaf){
                try{
                    $null=Set-GuiAnalysisResults $script:analysisResultPath
                    if($code -eq 0){$analysisStatusLabel.Text+=' — анализ завершён'}else{$analysisStatusLabel.Text+=' — показаны доступные результаты до остановки/ошибки'}
                }catch{Show-GuiError $_.Exception.Message}
            }else{
                $analysisStatusLabel.Text=('Анализ завершился с кодом {0}; подробности — в логах.' -f $code)
                if($code -ne 0){[System.Windows.Forms.MessageBox]::Show('Анализ не завершился. Откройте логи для подробностей.','AntiDPI',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)|Out-Null}
            }
            if($script:closeWhenStopped -and $null -eq $script:worker){$form.Close()}
        }
        if($script:closeWhenStopped -and $null -eq $script:worker -and $null -eq $script:analysisWorker){$form.Close()}
    })
    $timer.Start()
    $form.Add_FormClosing({
        $strategyActive=$null -ne $script:worker -and -not $script:worker.HasExited
        $analysisActive=$null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited
        if($strategyActive -or $analysisActive){
            $answer=[System.Windows.Forms.MessageBox]::Show('AntiDPI выполняет задачу. Закрытие запросит безопасную остановку и дождётся завершения тестовых процессов. Продолжить?','AntiDPI',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
            if($answer -ne [System.Windows.Forms.DialogResult]::Yes){$_.Cancel=$true}
            else{
                $_.Cancel=$true;$script:closeWhenStopped=$true
                if($strategyActive){Request-GuiStop}
                if($analysisActive){Request-GuiAnalysisCancel}
            }
        }
    })
    $form.Add_FormClosed({$timer.Stop();$timer.Dispose()})
    Write-GuiLog 'Showing main form'
    [void]$form.ShowDialog()
    Write-GuiLog 'Main form closed normally'
}catch{Write-GuiLog ('FATAL: '+$_.Exception.ToString());Show-GuiError $_.Exception.Message}
finally{if($null -ne $script:worker){$script:worker.Dispose()};if($null -ne $script:analysisWorker){$script:analysisWorker.Dispose()}}
