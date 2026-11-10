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
$guiLog=Join-Path $state 'gui\startup.log'
function Write-GuiLog([string]$Message) {
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $guiLog))|Out-Null
        [IO.File]::AppendAllText($guiLog,((Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')+' '+$Message+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
    } catch {}
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
    if($null -ne $script:worker -and -not $script:worker.HasExited){return}
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
    foreach($adapter in $adapters){$null=$adapterBox.Items.Add($adapter)}
    if($adapterBox.Items.Count){
        $adapterBox.DisplayMember='Name'
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
    $form.Size=[System.Drawing.Size]::new(760,620)
    $form.MinimumSize=[System.Drawing.Size]::new(720,590)
    $form.Font=[System.Drawing.Font]::new('Segoe UI',10)
    $form.BackColor=[System.Drawing.Color]::FromArgb(247,249,252)
    $form.ForeColor=[System.Drawing.Color]::FromArgb(31,41,55)

    $header=New-Object System.Windows.Forms.Label
    $header.Text='AntiDPI'
    $header.Font=[System.Drawing.Font]::new('Segoe UI Semibold',22,[System.Drawing.FontStyle]::Bold)
    $header.Location=[System.Drawing.Point]::new(26,18);$header.Size=[System.Drawing.Size]::new(680,42)
    $form.Controls.Add($header)
    $subtitle=New-Object System.Windows.Forms.Label
    $subtitle.Text='TCP/TLS и UDP/QUIC для IPv4 или IPv6. Это не проверка VPN/Tor-туннеля или авторизации.'
    $subtitle.Location=[System.Drawing.Point]::new(29,62);$subtitle.Size=[System.Drawing.Size]::new(680,25)
    $form.Controls.Add($subtitle)

    $familyLabel=New-Object System.Windows.Forms.Label
    $familyLabel.Text='IP-семейство';$familyLabel.Location=[System.Drawing.Point]::new(30,100);$familyLabel.Size=[System.Drawing.Size]::new(250,24)
    $form.Controls.Add($familyLabel)
    $addressFamilyBox=New-Object System.Windows.Forms.ComboBox
    $addressFamilyBox.DropDownStyle='DropDownList';$addressFamilyBox.Location=[System.Drawing.Point]::new(30,128);$addressFamilyBox.Size=[System.Drawing.Size]::new(250,32)
    $addressFamilyBox.DisplayMember='Label';$addressFamilyBox.Items.Add([pscustomobject]@{Label='IPv4';Value='ipv4'})|Out-Null;$addressFamilyBox.Items.Add([pscustomobject]@{Label='IPv6';Value='ipv6'})|Out-Null
    $addressFamilyBox.SelectedIndex=0;$form.Controls.Add($addressFamilyBox)
    $protocolLabel=New-Object System.Windows.Forms.Label
    $protocolLabel.Text='Транспорт и распознаваемый протокол';$protocolLabel.Location=[System.Drawing.Point]::new(310,100);$protocolLabel.Size=[System.Drawing.Size]::new(400,24)
    $form.Controls.Add($protocolLabel)
    $protocolBox=New-Object System.Windows.Forms.ComboBox
    $protocolBox.DropDownStyle='DropDownList';$protocolBox.Location=[System.Drawing.Point]::new(310,128);$protocolBox.Size=[System.Drawing.Size]::new(400,32)
    $protocolBox.DisplayMember='Label';$protocolBox.Items.Add([pscustomobject]@{Label='TCP + TLS ClientHello';Value='tls'})|Out-Null;$protocolBox.Items.Add([pscustomobject]@{Label='UDP + QUIC Initial (HTTP/3)';Value='quic'})|Out-Null
    $protocolBox.SelectedIndex=0;$form.Controls.Add($protocolBox)

    $profileLabel=New-Object System.Windows.Forms.Label
    $profileLabel.Text='Стратегия — введите номер или часть названия';$profileLabel.Location=[System.Drawing.Point]::new(30,178);$profileLabel.Size=[System.Drawing.Size]::new(500,24)
    $form.Controls.Add($profileLabel)
    $profileBox=New-Object System.Windows.Forms.ComboBox
    $profileBox.DropDownStyle='DropDown';$profileBox.AutoCompleteMode='SuggestAppend';$profileBox.AutoCompleteSource='CustomSource'
    $profileBox.Location=[System.Drawing.Point]::new(30,206);$profileBox.Size=[System.Drawing.Size]::new(680,32)
    $profileBox.Anchor='Top,Left,Right';$profileBox.DisplayMember='Label'
    $profileBox.AutoCompleteCustomSource=[System.Windows.Forms.AutoCompleteStringCollection]::new()
    $form.Controls.Add($profileBox)
    $details=New-Object System.Windows.Forms.Label
    $details.Location=[System.Drawing.Point]::new(32,244);$details.Size=[System.Drawing.Size]::new(675,40);$details.ForeColor=[System.Drawing.Color]::DimGray
    $details.Anchor='Top,Left,Right';$form.Controls.Add($details)
    $profileBox.Add_SelectedIndexChanged({if($null -ne $profileBox.SelectedItem){$p=$profileBox.SelectedItem;$details.Text=if($p.Protocol -eq 'quic'){('UDP/QUIC Initial; стратегия: {0}' -f $p.Chain)}else{('Семейство {0}    Обработка: {1}    Цепочка: {2}' -f $p.Family,$p.Processing,$p.Chain)}}})

    $adapterLabel=New-Object System.Windows.Forms.Label
    $adapterLabel.Text='Активный физический адаптер с адресом выбранного IP-семейства';$adapterLabel.Location=[System.Drawing.Point]::new(30,294);$adapterLabel.Size=[System.Drawing.Size]::new(500,24)
    $form.Controls.Add($adapterLabel)
    $adapterBox=New-Object System.Windows.Forms.ComboBox
    $adapterBox.DropDownStyle='DropDownList';$adapterBox.Location=[System.Drawing.Point]::new(30,322);$adapterBox.Size=[System.Drawing.Size]::new(500,32);$adapterBox.Anchor='Top,Left,Right'
    $form.Controls.Add($adapterBox)
    $refreshButton=New-Object System.Windows.Forms.Button
    $refreshButton.Text='Обновить';$refreshButton.Location=[System.Drawing.Point]::new(544,321);$refreshButton.Size=[System.Drawing.Size]::new(166,34);$refreshButton.Anchor='Top,Right'
    $form.Controls.Add($refreshButton)
    $refreshButton.Add_Click({try{Refresh-GuiAdapters}catch{Show-GuiError $_.Exception.Message}})
    $addressFamilyBox.Add_SelectedIndexChanged({try{Refresh-GuiAdapters}catch{Show-GuiError $_.Exception.Message}})

    $portsLabel=New-Object System.Windows.Forms.Label
    $portsLabel.Text='Порты назначения';$portsLabel.Location=[System.Drawing.Point]::new(30,374);$portsLabel.Size=[System.Drawing.Size]::new(260,24)
    $form.Controls.Add($portsLabel)
    $portsBox=New-Object System.Windows.Forms.TextBox
    $portsBox.Text='443';$portsBox.Location=[System.Drawing.Point]::new(30,402);$portsBox.Size=[System.Drawing.Size]::new(300,30)
    $form.Controls.Add($portsBox)
    $portsHint=New-Object System.Windows.Forms.Label
    $portsHint.Text='';$portsHint.Location=[System.Drawing.Point]::new(344,405);$portsHint.Size=[System.Drawing.Size]::new(365,34);$portsHint.Anchor='Top,Left,Right';$portsHint.ForeColor=[System.Drawing.Color]::DimGray
    $form.Controls.Add($portsHint)
    Set-GuiProfileItems 'tls'
    $protocolBox.Add_SelectedIndexChanged({if($null -ne $protocolBox.SelectedItem){Set-GuiProfileItems ([string]$protocolBox.SelectedItem.Value)}})

    $startButton=New-Object System.Windows.Forms.Button
    $startButton.Text='Запустить стратегию';$startButton.Location=[System.Drawing.Point]::new(30,462);$startButton.Size=[System.Drawing.Size]::new(210,42);$startButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$startButton.ForeColor=[System.Drawing.Color]::White;$startButton.FlatStyle='Flat'
    $startButton.Add_Click({Start-GuiStrategy});$form.Controls.Add($startButton)
    $stopButton=New-Object System.Windows.Forms.Button
    $stopButton.Text='Остановить';$stopButton.Location=[System.Drawing.Point]::new(251,462);$stopButton.Size=[System.Drawing.Size]::new(145,42);$stopButton.Enabled=$false
    $stopButton.Add_Click({Request-GuiStop});$form.Controls.Add($stopButton)
    $logsButton=New-Object System.Windows.Forms.Button
    $logsButton.Text='Открыть логи';$logsButton.Location=[System.Drawing.Point]::new(407,462);$logsButton.Size=[System.Drawing.Size]::new(145,42)
    $logsButton.Add_Click({try{$directory=Get-AntiDPILogDirectory $bundle;Start-Process explorer.exe -ArgumentList (ConvertTo-WindowsArgument $directory)}catch{Show-GuiError $_.Exception.Message}});$form.Controls.Add($logsButton)
    $statusLabel=New-Object System.Windows.Forms.Label
    $statusLabel.Text='Готово к запуску';$statusLabel.Location=[System.Drawing.Point]::new(30,525);$statusLabel.Size=[System.Drawing.Size]::new(680,25);$statusLabel.Anchor='Left,Right,Bottom';$statusLabel.ForeColor=[System.Drawing.Color]::DarkGreen
    $form.Controls.Add($statusLabel)

    Refresh-GuiAdapters
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
            if($script:closeWhenStopped){$form.Close()}
        }elseif($script:stopPending -and $null -ne $script:worker){
            try{$null=[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle)}catch{}
        }elseif($null -ne $script:worker){
            $ownedRecord=Join-Path $state 'owned_process.json'
            if(Test-Path -LiteralPath $ownedRecord){
                try{$owned=Get-Content -LiteralPath $ownedRecord -Raw|ConvertFrom-Json;$engine=Get-Process -Id ([int]$owned.PID) -ErrorAction Stop;if($engine.Path -ieq [string]$owned.Exe -and $engine.StartTime.ToUniversalTime().ToString('o') -ceq [string]$owned.StartUTC){Set-GuiStatus ('Работает стратегия {0} на выбранном адаптере.' -f [int]$script:runningProfile) ([System.Drawing.Color]::DarkGreen)}}catch{}
            }
        }
    })
    $timer.Start()
    $form.Add_FormClosing({
        if($null -ne $script:worker -and -not $script:worker.HasExited){
            $answer=[System.Windows.Forms.MessageBox]::Show('AntiDPI работает. Закрытие окна запросит безопасную остановку и будет ожидать её завершения. Продолжить?','AntiDPI',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
            if($answer -ne [System.Windows.Forms.DialogResult]::Yes){$_.Cancel=$true}
            else{$_.Cancel=$true;$script:closeWhenStopped=$true;Request-GuiStop}
        }
    })
    $form.Add_FormClosed({$timer.Stop();$timer.Dispose()})
    Write-GuiLog 'Showing main form'
    [void]$form.ShowDialog()
    Write-GuiLog 'Main form closed normally'
}catch{Write-GuiLog ('FATAL: '+$_.Exception.ToString());Show-GuiError $_.Exception.Message}
finally{if($null -ne $script:worker){$script:worker.Dispose()}}
