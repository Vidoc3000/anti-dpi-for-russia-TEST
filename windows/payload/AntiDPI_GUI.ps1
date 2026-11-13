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
$script:analysisCurrentData=$null
$script:analysisExportButton=$null
$script:analysisCancelFile=''
$script:historyPath=Join-Path $state 'gui\history.jsonl'
$script:historyGrid=$null
$script:dashboardLabel=$null
$script:historySearchBox=$null
$script:historyStatusLabel=$null
$script:favoritesOnly=$false
$script:guiSettingsPath=Join-Path $state 'gui-settings.json'
$script:programVersion='Версия не определена'
$script:analysisSnapshotIdentity=''
$script:workerStdoutPath='';$script:workerStderrPath=''
$script:analysisStdoutPath='';$script:analysisStderrPath=''
$script:guiSettings=@{AddressFamily='ipv4';Protocol='tls';Ports='443';AnalysisRange='1-45';AnalysisParallelism=3;AnalysisAttempts=2;AnalysisTimeoutSeconds=15;AnalysisThresholdKB=100;RememberAdapter=$true;SkipTimestampSetup=$false;ShowErrorDetails=$true;Favorites=@();RecentProfiles=@();FirstRunComplete=$false;WindowBounds=$null;WindowMaximized=$false}
$guiLog=Join-Path $state 'gui\startup.log'
function Write-GuiLog([string]$Message) {
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $guiLog))|Out-Null
        [IO.File]::AppendAllText($guiLog,((Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')+' '+$Message+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
    } catch {}
}
$installManifestPath=Join-Path $installRoot '.antidpi-install.json'
try{if(Test-Path -LiteralPath $installManifestPath -PathType Leaf){$installManifest=Get-Content -LiteralPath $installManifestPath -Raw -Encoding UTF8|ConvertFrom-Json;if($installManifest.DisplayVersion){$script:programVersion=[string]$installManifest.DisplayVersion}elseif($installManifest.Version -match '([0-9]+\.[0-9]+(?:\.[0-9]+)*)'){$script:programVersion=('Версия '+$Matches[1])}}}catch{Write-GuiLog ('Could not read installed version: '+$_.Exception.Message)}
if(Test-Path -LiteralPath $script:guiSettingsPath -PathType Leaf){
    try{
        $saved=Get-Content -LiteralPath $script:guiSettingsPath -Raw -Encoding UTF8|ConvertFrom-Json
        if([string]$saved.AddressFamily -in @('ipv4','ipv6')){$script:guiSettings.AddressFamily=[string]$saved.AddressFamily}
        if([string]$saved.Protocol -in @('tls','quic')){$script:guiSettings.Protocol=[string]$saved.Protocol}
        if($saved.Ports){$script:guiSettings.Ports=ConvertTo-AntiDPIPortScope ([string]$saved.Ports)}
        if($saved.PSObject.Properties['AnalysisRange']){
            $savedRange=[regex]::Match([string]$saved.AnalysisRange,'^([0-9]+)(?:\s*-\s*([0-9]+))?$')
            if($savedRange.Success){$a=[int]$savedRange.Groups[1].Value;$z=if($savedRange.Groups[2].Success){[int]$savedRange.Groups[2].Value}else{$a};if($a -ge 1 -and $z -ge $a -and $z -le 492){$script:guiSettings.AnalysisRange=('{0}-{1}' -f $a,$z)}}
        }
        if($saved.PSObject.Properties['RememberAdapter']){$script:guiSettings.RememberAdapter=[bool]$saved.RememberAdapter}
        if($saved.PSObject.Properties['SkipTimestampSetup']){$script:guiSettings.SkipTimestampSetup=[bool]$saved.SkipTimestampSetup}
        if($saved.PSObject.Properties['ShowErrorDetails']){$script:guiSettings.ShowErrorDetails=[bool]$saved.ShowErrorDetails}
        if($saved.PSObject.Properties['AnalysisParallelism']){$savedParallelism=0;if([int]::TryParse([string]$saved.AnalysisParallelism,[ref]$savedParallelism) -and $savedParallelism -ge 1 -and $savedParallelism -le 5){$script:guiSettings.AnalysisParallelism=$savedParallelism}}
        if($saved.PSObject.Properties['AnalysisAttempts']){$savedAttempts=0;if([int]::TryParse([string]$saved.AnalysisAttempts,[ref]$savedAttempts) -and $savedAttempts -ge 1 -and $savedAttempts -le 5){$script:guiSettings.AnalysisAttempts=$savedAttempts}}
        if($saved.PSObject.Properties['AnalysisTimeoutSeconds']){$savedTimeout=0;if([int]::TryParse([string]$saved.AnalysisTimeoutSeconds,[ref]$savedTimeout) -and $savedTimeout -ge 5 -and $savedTimeout -le 120){$script:guiSettings.AnalysisTimeoutSeconds=$savedTimeout}}
        if($saved.PSObject.Properties['AnalysisThresholdKB']){$savedThreshold=0;if([int]::TryParse([string]$saved.AnalysisThresholdKB,[ref]$savedThreshold) -and $savedThreshold -ge 16 -and $savedThreshold -le 1024){$script:guiSettings.AnalysisThresholdKB=$savedThreshold}}
        if($saved.PSObject.Properties['Favorites']){$script:guiSettings.Favorites=@($saved.Favorites|ForEach-Object {$number=0;if([int]::TryParse([string]$_,[ref]$number) -and $number -ge 1 -and $number -le 494){$number}}|Where-Object {$_}|Select-Object -Unique)}
        if($saved.PSObject.Properties['RecentProfiles']){$script:guiSettings.RecentProfiles=@($saved.RecentProfiles|ForEach-Object {$number=0;if([int]::TryParse([string]$_,[ref]$number) -and $number -ge 1 -and $number -le 494){$number}}|Where-Object {$_}|Select-Object -Unique|Select-Object -First 20)}
        if($saved.PSObject.Properties['FirstRunComplete']){$script:guiSettings.FirstRunComplete=[bool]$saved.FirstRunComplete}
        if($saved.PSObject.Properties['WindowBounds'] -and $null -ne $saved.WindowBounds){$script:guiSettings.WindowBounds=$saved.WindowBounds}
        if($saved.PSObject.Properties['WindowMaximized']){$script:guiSettings.WindowMaximized=[bool]$saved.WindowMaximized}
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
$script:workerMode='start'
$script:restartAfterStop=$false
$script:focusAfterStop=''
$worker=$null
$stopPending=$false

$script:closeWhenStopped=$false

function Show-GuiError([string]$Message) {
    [System.Windows.Forms.MessageBox]::Show($Message,'AntiDPI',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)|Out-Null
}
function Get-GuiProcessOutput([string]$StdoutPath,[string]$StderrPath,[int]$Lines=24) {
    $parts=[Collections.Generic.List[string]]::new()
    foreach($spec in @(@{Name='Вывод';Path=$StdoutPath},@{Name='Ошибки';Path=$StderrPath})){
        if($spec.Path -and (Test-Path -LiteralPath $spec.Path -PathType Leaf)){
            try{$tail=@(Get-Content -LiteralPath $spec.Path -Tail $Lines -Encoding UTF8 -ErrorAction Stop);if($tail.Count){$parts.Add(('--- '+$spec.Name+' ---'));$parts.Add(($tail -join [Environment]::NewLine))}}catch{}
        }
    }
    if($parts.Count){return ($parts -join [Environment]::NewLine)}
    return 'Процесс не записал текстовый вывод. Откройте каталог логов для диагностики.'
}
function Get-GuiFailureLine([string]$StdoutPath,[string]$StderrPath) {
    foreach($path in @($StderrPath,$StdoutPath)){
        if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){
            try{$lines=@(Get-Content -LiteralPath $path -Tail 30 -Encoding UTF8 -ErrorAction Stop|Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)});if($lines.Count){return [string]$lines[$lines.Count-1]}}catch{}
        }
    }
    return 'Подробности не записаны.'
}
function Add-GuiHistory([string]$Kind,[string]$Status,[string]$Summary) {
    try {
        $directory=Split-Path -Parent $script:historyPath
        [IO.Directory]::CreateDirectory($directory)|Out-Null
        $record=[ordered]@{Time=(Get-Date).ToString('o');Kind=$Kind;Status=$Status;Summary=$Summary}
        [IO.File]::AppendAllText($script:historyPath,(($record|ConvertTo-Json -Compress)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
        $lines=@(Get-Content -LiteralPath $script:historyPath -Encoding UTF8 -ErrorAction SilentlyContinue)
        if($lines.Count -gt 1000){[IO.File]::WriteAllLines($script:historyPath,[string[]]$lines[($lines.Count-1000)..($lines.Count-1)],[Text.UTF8Encoding]::new($false))}
        if($null -ne $script:historyGrid){Update-GuiHistory}
    } catch {Write-GuiLog ('Could not append activity history: '+$_.Exception.Message)}
}
function Save-GuiUiPreferences {
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $script:guiSettingsPath))|Out-Null
        $temporary=$script:guiSettingsPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
        try{[IO.File]::WriteAllText($temporary,($script:guiSettings|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false));if(Test-Path -LiteralPath $script:guiSettingsPath -PathType Leaf){[IO.File]::Replace($temporary,$script:guiSettingsPath,[NullString]::Value)}else{[IO.File]::Move($temporary,$script:guiSettingsPath)}}finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
    }catch{Write-GuiLog ('Could not save GUI preferences: '+$_.Exception.Message);throw}
}
function Update-GuiHistory {
    if($null -eq $script:historyGrid){return}
    $script:historyGrid.Rows.Clear()
    if(-not (Test-Path -LiteralPath $script:historyPath -PathType Leaf)){return}
    $query='';if($null -ne $script:historySearchBox){$query=[string]$script:historySearchBox.Text.Trim()}
    foreach($line in @(Get-Content -LiteralPath $script:historyPath -Encoding UTF8 -ErrorAction SilentlyContinue)){
        try{$entry=$line|ConvertFrom-Json -ErrorAction Stop;$values=@([string]$entry.Time,[string]$entry.Kind,[string]$entry.Status,[string]$entry.Summary);if(-not $query -or (($values -join ' ').IndexOf($query,[StringComparison]::OrdinalIgnoreCase) -ge 0)){$null=$script:historyGrid.Rows.Add([object[]]$values)}}catch{}
    }
}
function Export-GuiHistory {
    if($script:historyGrid.Rows.Count -eq 0){Show-GuiError 'История пока пуста.';return}
    $dialog=New-Object System.Windows.Forms.SaveFileDialog;$dialog.Title='Экспорт истории';$dialog.Filter='CSV для Excel (*.csv)|*.csv|Все файлы (*.*)|*.*';$dialog.DefaultExt='csv';$dialog.AddExtension=$true;$dialog.FileName=('AntiDPI_history_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.csv')
    try{if($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK){return};$rows=foreach($row in $script:historyGrid.Rows){[pscustomobject][ordered]@{Time=$row.Cells[0].Value;Kind=$row.Cells[1].Value;Status=$row.Cells[2].Value;Summary=$row.Cells[3].Value}};[IO.File]::WriteAllText($dialog.FileName,(($rows|ConvertTo-Csv -NoTypeInformation -Delimiter ';') -join [Environment]::NewLine)+[Environment]::NewLine,[Text.UTF8Encoding]::new($true));$historyStatusLabel.Text='История экспортирована.'}catch{Show-GuiError ('Не удалось экспортировать историю: '+$_.Exception.Message)}finally{$dialog.Dispose()}
}
function Get-GuiAnalysisRecommendation([string]$Status) {
    switch($Status){
        'PASS' {'Сработала только при провале контроля'}
        'BASELINE_PASS' {'YouTube доступен и без выбранной стратегии'}
        'INCONCLUSIVE' {'Неоднозначно: контроль уже успешен'}
        'UNSTABLE' {'Нестабильно — повторите тест'}
        'FAIL' {'Не прошла тест YouTube'}
        'ERROR' {'Ошибка проверки'}
        'CANCELLED' {'Остановлено до завершения'}
        default {'Проверка выполняется'}
    }
}
function Get-GuiObjectProperty($Object,[string]$Name,$Default='') {
    if($null -eq $Object){return $Default}
    $property=$Object.PSObject.Properties[$Name]
    if($null -ne $property -and $null -ne $property.Value){return $property.Value}
    return $Default
}
function ConvertTo-GuiAnalysisCsv($Data) {
    if($null -eq $Data){throw 'Нет результатов анализа для экспорта.'}
    $results=@($Data.Results)
    if($results.Count -eq 1 -and $null -eq $results[0]){$results=@()}
    if(-not $results.Count){throw 'Нет результатов анализа для экспорта.'}
    $baseline=Get-GuiObjectProperty $Data 'Baseline' $null
    $createdUtc=[string](Get-GuiObjectProperty $Data 'CreatedUtc' '')
    $test=[string](Get-GuiObjectProperty $Data 'Test' 'YouTube HTTPS')
    $addressFamily=[string](Get-GuiObjectProperty $Data 'AddressFamily' '')
    $protocol=[string](Get-GuiObjectProperty $Data 'Protocol' '')
    $rows=foreach($result in $results){
        $number=[int](Get-GuiObjectProperty $result 'Number' 0)
        $profile=@($profileRows|Where-Object {[int]$_.Number -eq $number}|Select-Object -First 1)
        $name=if($profile.Count){[string]$profile[0].Name}else{('Стратегия '+$number)}
        $status=[string](Get-GuiObjectProperty $result 'Status' '')
        [pscustomobject][ordered]@{
            CreatedUtc=$createdUtc
            Test=$test
            AddressFamily=$addressFamily
            Protocol=$protocol
            FirstStrategy=[int](Get-GuiObjectProperty $Data 'FirstProfile' 0)
            LastStrategy=[int](Get-GuiObjectProperty $Data 'LastProfile' 0)
            BaselineSuccesses=[int](Get-GuiObjectProperty $baseline 'Successes' 0)
            BaselineAttempts=[int](Get-GuiObjectProperty $baseline 'Attempts' 0)
            StrategyNumber=$number
            StrategyName=$name
            Status=$status
            Recommendation=(Get-GuiAnalysisRecommendation $status)
            SuccessfulAttempts=[int](Get-GuiObjectProperty $result 'Successes' 0)
            ExpectedAttempts=[int](Get-GuiObjectProperty $result 'ExpectedAttempts' 0)
            AttemptDetails=[string](Get-GuiObjectProperty $result 'AttemptDetails' '')
            Details=[string](Get-GuiObjectProperty $result 'Details' '')
        }
    }
    return (($rows|ConvertTo-Csv -NoTypeInformation -Delimiter ';') -join [Environment]::NewLine)
}
function Write-GuiAnalysisCsv($Data,[string]$Path) {
    if([string]::IsNullOrWhiteSpace($Path)){throw 'Не задан путь сохранения CSV.'}
    $fullPath=[IO.Path]::GetFullPath($Path)
    $directory=Split-Path -Parent $fullPath
    if(-not (Test-Path -LiteralPath $directory -PathType Container)){throw 'Папка для сохранения CSV не найдена.'}
    $temporary=$fullPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try{
        $csv=ConvertTo-GuiAnalysisCsv $Data
        [IO.File]::WriteAllText($temporary,($csv+[Environment]::NewLine),[Text.UTF8Encoding]::new($true))
        if(Test-Path -LiteralPath $fullPath -PathType Leaf){[IO.File]::Replace($temporary,$fullPath,[NullString]::Value)}
        elseif(Test-Path -LiteralPath $fullPath){throw 'Путь экспорта занят не файлом.'}
        else{[IO.File]::Move($temporary,$fullPath)}
    }finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
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
function Get-GuiFamilies {
    $source=[IO.File]::ReadAllText($catalogue,[Text.Encoding]::UTF8)
    $match=[regex]::Match($source,'(?s)\$FamilyRows = @''\r?\n(.*?)\r?\n''@ \| ConvertFrom-Json')
    if(-not $match.Success){throw 'Не удалось прочитать каталог семейств стратегий.'}
    $rows=@($match.Groups[1].Value|ConvertFrom-Json)
    if($rows.Count -eq 1 -and $rows[0] -is [array]){$rows=@($rows[0])}
    return $rows
}
function Show-GuiTextDialog([string]$Title,[string]$Content) {
    $dialog=[System.Windows.Forms.Form]::new();$dialog.Text=$Title;$dialog.StartPosition='CenterParent';$dialog.Size=[System.Drawing.Size]::new(760,520);$dialog.MinimumSize=[System.Drawing.Size]::new(540,360)
    $box=[System.Windows.Forms.TextBox]::new();$box.Multiline=$true;$box.ReadOnly=$true;$box.ScrollBars='Both';$box.WordWrap=$false;$box.Font=[System.Drawing.Font]::new('Consolas',9);$box.Dock='Fill';$box.Text=$Content
    $dialog.Controls.Add($box)
    $buttons=[System.Windows.Forms.FlowLayoutPanel]::new();$buttons.Dock='Bottom';$buttons.Height=48;$buttons.FlowDirection='RightToLeft'
    $close=[System.Windows.Forms.Button]::new();$close.Text='Закрыть';$close.Width=100;$close.DialogResult='OK'
    $copy=[System.Windows.Forms.Button]::new();$copy.Text='Копировать';$copy.Width=120;$copy.Add_Click({[Windows.Forms.Clipboard]::SetText($box.Text)})
    $openLogs=New-Object System.Windows.Forms.Button;$openLogs.Text='Открыть логи';$openLogs.Width=120;$openLogs.Add_Click({try{$directory=Get-AntiDPILogDirectory $bundle;Start-Process explorer.exe -ArgumentList (ConvertTo-WindowsArgument $directory)}catch{Show-GuiError $_.Exception.Message}})
    $buttons.Controls.Add($close);$buttons.Controls.Add($copy);$buttons.Controls.Add($openLogs);$dialog.Controls.Add($buttons);$dialog.AcceptButton=$close
    [void]$dialog.ShowDialog($form)
}
function Show-GuiInterfaces {
    try{
        $rows=@(Get-NetAdapter -ErrorAction Stop|Sort-Object ifIndex|ForEach-Object {'{0,4}  {1,-30}  {2,-12}  Physical={3}  {4}' -f $_.ifIndex,$_.Name,$_.Status,$_.HardwareInterface,$_.InterfaceDescription})
        if(-not $rows.Count){$rows=@('Интерфейсы не найдены.')}
        Show-GuiTextDialog 'Сетевые интерфейсы Windows' ($rows -join [Environment]::NewLine)
    }catch{Show-GuiError $_.Exception.Message}
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
function Update-GuiDashboard {
    if($null -eq $script:dashboardLabel){return}
    $profile=if($null -ne $profileListBox -and $null -ne $profileListBox.SelectedItem){$profileListBox.SelectedItem}else{$null}
    $profileText=if($null -ne $profile){('#{0} {1}' -f $profile.Number,$profile.Name)}else{'стратегия не выбрана'}
    $familyText=if($null -ne $addressFamilyBox -and $null -ne $addressFamilyBox.SelectedItem){[string]$addressFamilyBox.SelectedItem.Label}else{'IP не выбран'}
    $protocolText=if($null -ne $protocolBox -and $null -ne $protocolBox.SelectedItem){[string]$protocolBox.SelectedItem.Label}else{'транспорт не выбран'}
    $adapterText=if($null -ne $adapterBox -and $null -ne $adapterBox.SelectedItem){[string]$adapterBox.SelectedItem.Name}else{'адаптер не выбран'}
    $portText=if($null -ne $portsBox){[string]$portsBox.Text}else{'443'}
    $stateText=if($null -ne $statusLabel){[string]$statusLabel.Text}else{'Готово к запуску'}
    $script:dashboardLabel.Text=('{0}  |  {1}  |  {2}  |  {3}  |  порты {4}  |  {5}' -f $stateText,$profileText,$familyText,$protocolText,$portText,$adapterText)
}
function Set-GuiStatus([string]$Text,[System.Drawing.Color]$Color) {
    $statusLabel.Text=$Text
    $statusLabel.ForeColor=$Color
    Update-GuiDashboard
}
function Get-GuiSelectedProfile {
    $profileText=$profileSearchBox.Text.Trim()
    $selectedProfile=$null
    if($null -ne $profileListBox.SelectedItem){$selectedProfile=$profileListBox.SelectedItem}
    else{$profileMatches=@($script:profileItems|Where-Object {([string]$_.Number -ceq $profileText) -or ([string]$_.Label -ceq $profileText)});if($profileMatches.Count -eq 1){$selectedProfile=$profileMatches[0]}}
    if($null -eq $selectedProfile){throw 'Выберите стратегию из списка, введите её номер или укажите точное название.'}
    return $selectedProfile
}
function Show-GuiProfileDetails([string]$Mode) {
    try{
        $selectedProfile=Get-GuiSelectedProfile
        if($Mode -eq 'arguments'){
            if($null -eq $adapterBox.SelectedItem){throw 'Сначала выберите физический адаптер.'}
            $scope=ConvertTo-AntiDPIPortScope $portsBox.Text
            $family=[string]$addressFamilyBox.SelectedItem.Value
            $protocol=[string]$protocolBox.SelectedItem.Value
            $content=@(Get-AntiDPIArguments $selectedProfile ([int]$adapterBox.SelectedItem.ifIndex) $scope -AddressFamily $family -Protocol $protocol) -join [Environment]::NewLine
            $title='Аргументы winws2.exe'
        }else{
            $recipe=[ordered]@{Number=$selectedProfile.Number;Protocol=$selectedProfile.Protocol;Family=$selectedProfile.Family;Name=$selectedProfile.Name;Processing=$selectedProfile.Processing;Chain=$selectedProfile.Chain;Init=$selectedProfile.Init;NeedsTimestamps=$selectedProfile.NeedsTimestamps;StockTlsPattern=$selectedProfile.StockTlsPattern;Args=$selectedProfile.Args}
            $content=$recipe|ConvertTo-Json -Depth 20
            $title='Рецепт стратегии'
        }
        $dialog=[System.Windows.Forms.Form]::new()
        $dialog.Text=$title+' — №'+$selectedProfile.Number
        $dialog.StartPosition='CenterParent';$dialog.Size=[System.Drawing.Size]::new(760,520);$dialog.MinimumSize=[System.Drawing.Size]::new(540,360)
        $box=[System.Windows.Forms.TextBox]::new();$box.Multiline=$true;$box.ReadOnly=$true;$box.ScrollBars='Both';$box.WordWrap=$false;$box.Font=[System.Drawing.Font]::new('Consolas',9);$box.Dock='Fill';$box.Text=$content
        $dialog.Controls.Add($box)
        $buttons=[System.Windows.Forms.FlowLayoutPanel]::new();$buttons.Dock='Bottom';$buttons.Height=48;$buttons.FlowDirection='RightToLeft'
        $close=[System.Windows.Forms.Button]::new();$close.Text='Закрыть';$close.Width=100;$close.DialogResult='OK'
        $copy=[System.Windows.Forms.Button]::new();$copy.Text='Копировать';$copy.Width=120;$copy.Add_Click({[Windows.Forms.Clipboard]::SetText($box.Text)})
        $buttons.Controls.Add($close);$buttons.Controls.Add($copy);$dialog.Controls.Add($buttons);$dialog.AcceptButton=$close
        [void]$dialog.ShowDialog($form)
    }catch{Show-GuiError $_.Exception.Message}
}

function Start-GuiStrategy([switch]$CheckOnly) {
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){return}
    try{
        $selectedProfile=Get-GuiSelectedProfile
        if($null -eq $adapterBox.SelectedItem){throw ('Не найден активный физический адаптер с '+$addressFamilyBox.SelectedItem.Value+'. Подключите сеть и нажмите Обновить.')}
        $selectedAdapter=$adapterBox.SelectedItem
        $addressFamily=[string]$addressFamilyBox.SelectedItem.Value
        $protocol=[string]$protocolBox.SelectedItem.Value
        $scope=ConvertTo-AntiDPIPortScope $portsBox.Text
        if($scope -eq 'all' -and [System.Windows.Forms.MessageBox]::Show(('Будут перехватываться все '+$(if($protocol -eq 'quic'){'UDP'}else{'TCP'})+'-порты выбранного IP-семейства. Это может заметно увеличить нагрузку. Продолжить?'),'Широкий охват',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning) -ne [System.Windows.Forms.DialogResult]::Yes){return}
        if($script:guiSettings.RememberAdapter){Save-AntiDPIAdapter $state $selectedAdapter -AddressFamily $addressFamily}
        $logs=Get-AntiDPILogDirectory $bundle
        $stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'
        $stdout=Join-Path $logs ('gui_'+$stamp+'.out.log')
        $stderr=Join-Path $logs ('gui_'+$stamp+'.err.log')
        $script:workerStdoutPath=$stdout;$script:workerStderrPath=$stderr

        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $selectedProfileNumber=[int]$selectedProfile.Number
        if(-not $CheckOnly){$script:guiSettings.RecentProfiles=@($selectedProfileNumber)+@($script:guiSettings.RecentProfiles|Where-Object {$_ -ne $selectedProfileNumber}|Select-Object -First 19);Save-GuiUiPreferences}
        $script:runningProfile=$selectedProfileNumber
$launchArguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$catalogue,'-ProfileNumber',[string]$selectedProfileNumber,'-InterfaceIndex',[string]$selectedAdapter.ifIndex,'-Scope',$scope,'-AddressFamily',$addressFamily,'-Protocol',$protocol,'-ZapretDirectory',$bundle,'-StateDirectory',$state)
        if($CheckOnly){$launchArguments+= '-Check'}
        if($script:guiSettings.SkipTimestampSetup){$launchArguments+= '-SkipTimestampSetup'}
        $joined=(@($launchArguments|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
        $script:worker=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        if(-not $CheckOnly){Add-GuiHistory 'Стратегия' 'ЗАПУСК' ('№{0} {1}; {2}; {3}; адаптер {4}; порты {5}' -f $selectedProfileNumber,$selectedProfile.Name,$addressFamily,$protocol,$selectedAdapter.Name,$scope)}
        $script:stopPending=$false
        $script:workerMode=if($CheckOnly){'check'}else{'start'}
        $startButton.Enabled=$false
        $stopButton.Enabled=(-not $CheckOnly)
        $restartButton.Enabled=(-not $CheckOnly)
        $checkButton.Enabled=$false;$recipeButton.Enabled=$false;$argumentsButton.Enabled=$false
        $profileListBox.Enabled=$false;$profileSearchBox.Enabled=$false
        $adapterBox.Enabled=$false;$refreshButton.Enabled=$false;$addressFamilyBox.Enabled=$false;$protocolBox.Enabled=$false
        $portsBox.Enabled=$false
        Set-GuiStatus $(if($CheckOnly){'Проверка параметров стратегии '+$selectedProfileNumber+'…'}else{'Запуск стратегии '+$selectedProfileNumber+'…'}) ([System.Drawing.Color]::DarkOrange)
    }catch{$message=$_.Exception.Message;Set-GuiStatus ('Ошибка запуска: '+$message+' Проверьте адаптер и права администратора; откройте логи.') ([System.Drawing.Color]::Firebrick);Add-GuiHistory 'Стратегия' 'ОШИБКА' $message;Show-GuiError ($message+[Environment]::NewLine+[Environment]::NewLine+'Дальше: проверьте выбранный физический адаптер, права администратора и журналы AntiDPI. Остановка активного процесса остаётся управляемой кнопкой «Остановить».')}
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
function Request-GuiRestart {
    if($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited){return}
    if($null -eq $script:worker -or $script:worker.HasExited){Start-GuiStrategy;return}
    if($script:workerMode -eq 'check'){return}
    $script:restartAfterStop=$true
    Request-GuiStop
    Set-GuiStatus 'Перезапуск: безопасная остановка, затем повторный запуск текущего профиля…' ([System.Drawing.Color]::DarkOrange)
}
function Refresh-GuiAdapters {
    $savedGuid=''
    $config=Join-Path $state 'adapter.json'
    if($script:guiSettings.RememberAdapter -and (Test-Path -LiteralPath $config)){try{$savedGuid=[string](Get-Content -LiteralPath $config -Raw -Encoding UTF8|ConvertFrom-Json).Guid}catch{}}
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
function Update-GuiProfileFilter {
    if($null -eq $profileListBox -or $null -eq $familyFilterBox){return}
    $profileListBox.BeginUpdate()
    try{
        $profileListBox.Items.Clear()
        $familyValue=[string]$familyFilterBox.SelectedItem.Value
        $query=[string]$profileSearchBox.Text.Trim()
        $visible=if($familyValue -eq 'all'){@($script:allProfileItems)}else{@($script:allProfileItems|Where-Object {[string]$_.Family -ceq $familyValue})}
        if($script:favoritesOnly){$visible=@($visible|Where-Object {[int]$_.Number -in @($script:guiSettings.Favorites)})}
        if($query){$visible=@($visible|Where-Object {([string]$_.Number).IndexOf($query,[StringComparison]::OrdinalIgnoreCase) -ge 0 -or ([string]$_.Name).IndexOf($query,[StringComparison]::OrdinalIgnoreCase) -ge 0})}
        $script:profileItems=@($visible)
        foreach($item in $script:profileItems){$null=$profileListBox.Items.Add($item)}
        $profileListBox.SelectedIndex=-1
        $details.Text=''
    }finally{$profileListBox.EndUpdate()}
    $profileCountLabel.Text=('{0} стратегий' -f $script:profileItems.Count)
}
function Set-GuiProfileItems([string]$Protocol) {
    $rows=if($Protocol -eq 'quic'){$script:quicProfileRows}else{$profileRows}
    $items=[Collections.Generic.List[object]]::new()
    foreach($row in $rows){
        $number=[int]$row.Number
        $label=if($Protocol -eq 'quic'){('[QUIC #{0}] {1}' -f $number,$row.Name)}else{Get-ProfileLabel $row}
        $itemFamily=if($Protocol -eq 'quic'){'QUIC'}else{[string]$row.Family}
        $init=$null;$needsTimestamps=$false;$stockTlsPattern=$false
        if($row.PSObject.Properties['Init']){$init=$row.Init}
        if($row.PSObject.Properties['NeedsTimestamps']){$needsTimestamps=[bool]$row.NeedsTimestamps}
        if($row.PSObject.Properties['StockTlsPattern']){$stockTlsPattern=[bool]$row.StockTlsPattern}
        $item=[pscustomobject]@{Number=$number;Family=$itemFamily;Name=[string]$row.Name;Processing=[string]$row.Processing;Chain=[string]$row.Chain;Init=$init;NeedsTimestamps=$needsTimestamps;StockTlsPattern=$stockTlsPattern;Args=@($row.Args);Protocol=$Protocol;Label=$label}
        $items.Add($item)
    }
    $script:allProfileItems=$items.ToArray()
    $familyFilterBox.Items.Clear()
    $null=$familyFilterBox.Items.Add([pscustomobject]@{Label='Все семейства';Value='all'})
    foreach($familyId in @($script:allProfileItems|ForEach-Object {[string]$_.Family}|Sort-Object -Unique)){
        if($familyId -eq 'QUIC'){$label='QUIC'}
        else{
            $meta=@($familyRows|Where-Object {[string]$_.Number -ceq $familyId}|Select-Object -First 1)
            if($meta.Count){$label=('{0} · №{1} ({2}-{3}, {4})' -f $meta[0].Name,$familyId,$meta[0].First,$meta[0].Last,$meta[0].Count)}else{$label='Семейство '+$familyId}
        }
        $null=$familyFilterBox.Items.Add([pscustomobject]@{Label=$label;Value=$familyId})
    }
    $familyFilterBox.SelectedIndex=0
    Update-GuiProfileFilter
    $transport=if($Protocol -eq 'quic'){'UDP'}else{'TCP'}
    $portsLabel.Text=($transport+'-порты назначения')
    $portsBox.Text='443'
    $portsHint.Text=if($Protocol -eq 'quic'){'443 по умолчанию; all охватывает весь UDP — осторожно'}else{'443 по умолчанию; all — любые TCP-порты, выше нагрузка'}
}

function Set-GuiAnalysisResults([string]$Path) {
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){return 0}
    try{$file=Get-Item -LiteralPath $Path -ErrorAction Stop;$identity=('{0}:{1}' -f $file.Length,$file.LastWriteTimeUtc.Ticks);if($identity -ceq $script:analysisSnapshotIdentity){return @($analysisGrid.Rows.Count)};$data=Get-Content -LiteralPath $Path -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop}catch{return 0}
    $script:analysisSnapshotIdentity=$identity
    $script:analysisCurrentData=$data
    if($null -ne $script:analysisExportButton){$script:analysisExportButton.Enabled=(@($data.Results).Count -gt 0)}
    $results=@($data.Results)
    if($results.Count -eq 1 -and $null -eq $results[0]){$results=@()}
    $rowByNumber=@{}
    for($i=0;$i -lt $analysisGrid.Rows.Count;$i++){
        $row=$analysisGrid.Rows[$i]
        if($null -ne $row.Cells['Number'].Value){$rowByNumber[[int]$row.Cells['Number'].Value]=$row}
    }
    foreach($result in $results){
        $number=[int]$result.Number
        if($rowByNumber.ContainsKey($number)){$row=$rowByNumber[$number]}
        else{
            $profile=@($profileRows|Where-Object {[int]$_.Number -eq $number}|Select-Object -First 1)
            $name=if($profile.Count){[string]$profile[0].Name}else{('Стратегия '+$number)}
            $null=$analysisGrid.Rows.Add([object[]]@($number,$name,'Проверка…','','',''))
            $row=$analysisGrid.Rows[$analysisGrid.Rows.Count-1]
            $rowByNumber[$number]=$row
        }
        $status=[string]$result.Status
        $recommendation=Get-GuiAnalysisRecommendation $status
        $row.Cells['Status'].Value=$status
        $attemptText=if($result.PSObject.Properties['AttemptDetails']){[string]$result.AttemptDetails}else{''}
        if(-not $attemptText -and $result.PSObject.Properties['Successes']){$attemptText=('{0}/{1} успешных попыток' -f [int]$result.Successes,[int]$result.ExpectedAttempts)}
        $row.Cells['Attempts'].Value=$attemptText
        $row.Cells['Attempts'].ToolTipText=$attemptText
        $row.Cells['Recommendation'].Value=$recommendation
        $row.Cells['Details'].Value=[string]$result.Details
        $row.Cells['Details'].ToolTipText=[string]$result.Details
        if($status -eq 'PASS'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(225,245,233)}
        elseif($status -eq 'BASELINE_PASS'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(226,235,247)}
        elseif($status -eq 'INCONCLUSIVE'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(255,247,214)}
        elseif($status -eq 'UNSTABLE'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(255,247,214)}
        elseif($status -eq 'FAIL' -or $status -eq 'ERROR'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(252,231,231)}
        elseif($status -eq 'CANCELLED'){$row.DefaultCellStyle.BackColor=[System.Drawing.Color]::FromArgb(235,235,235)}
    }
    $passed=@($results|Where-Object {$_.Status -eq 'PASS'}).Count
    $unstable=@($results|Where-Object {$_.Status -eq 'UNSTABLE'}).Count
    $failed=@($results|Where-Object {$_.Status -eq 'FAIL'}).Count
    $errors=@($results|Where-Object {$_.Status -eq 'ERROR'}).Count
    $baselinePass=@($results|Where-Object {$_.Status -eq 'BASELINE_PASS'}).Count
    $inconclusive=@($results|Where-Object {$_.Status -eq 'INCONCLUSIVE'}).Count
    $baselineText=if($data.PSObject.Properties['Baseline'] -and $null -ne $data.Baseline){('контроль без стратегии: {0}/{1}' -f [int]$data.Baseline.Successes,[int]$data.Baseline.Attempts)}else{'контроль без стратегии: нет данных'}
    $when=if($data.CreatedUtc){([DateTime]::Parse([string]$data.CreatedUtc).ToLocalTime().ToString('g'))}else{'—'}
    $total=[int]$data.LastProfile-[int]$data.FirstProfile+1
    $current=0;if($data.PSObject.Properties['CurrentProfile']){$current=[int]$data.CurrentProfile}
    if($current -gt 0){$analysisStatusLabel.Text=('YouTube: {0}/{1}; сейчас №{2} | {3} | PASS: {4}; уже доступно: {5}; неоднозначно: {6}; нестабильно: {7}; FAIL: {8}; ошибки: {9}' -f $results.Count,$total,$current,$baselineText,$passed,$baselinePass,$inconclusive,$unstable,$failed,$errors)}
    else{$analysisStatusLabel.Text=('Результаты {0} | проверено: {1}/{2} | {3} | PASS: {4}; уже доступно: {5}; неоднозначно: {6}; нестабильно: {7}; FAIL: {8}; ошибки: {9}' -f $when,$results.Count,$total,$baselineText,$passed,$baselinePass,$inconclusive,$unstable,$failed,$errors)}
    return $results.Count
}
function Start-GuiAnalysis {
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){return}
    try{
        if($null -eq $adapterBox.SelectedItem){throw 'Для анализа выберите доступный физический адаптер.'}
        $selectedAdapter=$adapterBox.SelectedItem
        if($script:guiSettings.RememberAdapter){Save-AntiDPIAdapter $state $selectedAdapter -AddressFamily 'ipv4'}
        $ipv4=@(Get-NetIPAddress -InterfaceIndex ([int]$selectedAdapter.ifIndex) -AddressFamily IPv4 -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and $_.IPAddress -notlike '169.254.*' -and -not $_.SkipAsSource})
        if(-not $ipv4.Count){throw 'Анализ YouTube требует IPv4 на выбранном физическом адаптере. Выберите адаптер с IPv4.'}
        $rangeMatch=[regex]::Match($analysisRangeBox.Text.Trim(),'^([0-9]+)(?:\s*-\s*([0-9]+))?$')
        if(-not $rangeMatch.Success){throw 'Введите номер стратегии или диапазон, например 1-45.'}
        $first=[int]$rangeMatch.Groups[1].Value
        $last=if($rangeMatch.Groups[2].Success){[int]$rangeMatch.Groups[2].Value}else{$first}
        if($first -lt 1 -or $last -lt $first -or $last -gt 492){throw 'Диапазон стратегий должен находиться в пределах 1-492.'}
        $parallelism=[int]$analysisParallelismBox.Value
        $attempts=[int]$script:guiSettings.AnalysisAttempts
        $timeoutSeconds=[int]$script:guiSettings.AnalysisTimeoutSeconds
        $thresholdKB=[int]$script:guiSettings.AnalysisThresholdKB
        $logs=Get-AntiDPILogDirectory $bundle
        $stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'
        $resultDirectory=Join-Path $state 'gui\analysis'
        [IO.Directory]::CreateDirectory($resultDirectory)|Out-Null
        $script:analysisResultPath=Join-Path $resultDirectory ('analysis_'+$stamp+'.json')
        $script:analysisCancelFile=Join-Path $resultDirectory ('cancel_'+$stamp+'.request')
        $analysisGrid.Rows.Clear()
        $script:analysisSnapshotIdentity=''
        $script:analysisCurrentData=$null
        $script:analysisExportButton.Enabled=$false
        $analysisStatusLabel.Text=('Подготовка контрольного HTTPS-запроса; затем стратегии {0}-{1}, {2} параллельно…' -f $first,$last,$parallelism)
        $stdout=Join-Path $logs ('analysis_'+$stamp+'.out.log')
        $stderr=Join-Path $logs ('analysis_'+$stamp+'.err.log')
        $script:analysisStdoutPath=$stdout;$script:analysisStderrPath=$stderr
        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$catalogue,'-Analyze','-FirstProfile',[string]$first,'-LastProfile',[string]$last,'-Parallelism',[string]$parallelism,'-AnalysisAttempts',[string]$attempts,'-AnalysisThresholdKB',[string]$thresholdKB,'-AnalysisTimeoutSeconds',[string]$timeoutSeconds,'-InterfaceIndex',[string]$selectedAdapter.ifIndex,'-Scope','443','-AddressFamily','ipv4','-Protocol','tls','-ZapretDirectory',$bundle,'-StateDirectory',$state,'-AnalysisResultPath',$script:analysisResultPath,'-AnalysisCancelFile',$script:analysisCancelFile)
        if($script:guiSettings.SkipTimestampSetup){$arguments+= '-SkipTimestampSetup'}
        $joined=(@($arguments|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
        $script:analysisWorker=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        Add-GuiHistory 'Анализ YouTube' 'ЗАПУСК' ('Стратегии {0}-{1}; адаптер {2}; параллельность {3}' -f $first,$last,$selectedAdapter.Name,$parallelism)
        $analysisButton.Enabled=$false;$analysisCancelButton.Enabled=$true;$startButton.Enabled=$false;$settingsSaveButton.Enabled=$false
        $analysisRangeBox.Enabled=$false
        $analysisStatusLabel.Text=('Контроль и YouTube IPv4/TCP/TLS: стратегии {0}-{1}; параллельно {2}, {3} попытки × {4} КиБ, таймаут {5} сек.' -f $first,$last,$parallelism,$attempts,$thresholdKB,$timeoutSeconds)
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
function Export-GuiAnalysisResults {
    if($null -eq $script:analysisCurrentData -or @($script:analysisCurrentData.Results).Count -eq 0){
        Show-GuiError 'Нет результатов анализа для экспорта.';return
    }
    $dialog=New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title='Экспорт результатов анализа'
    $dialog.Filter='CSV для Excel (*.csv)|*.csv|Все файлы (*.*)|*.*'
    $dialog.FilterIndex=1;$dialog.DefaultExt='csv';$dialog.AddExtension=$true;$dialog.OverwritePrompt=$true
    $dialog.FileName=('AntiDPI_analysis_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.csv')
    try{
        if($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK){return}
        Write-GuiAnalysisCsv $script:analysisCurrentData $dialog.FileName
        $analysisStatusLabel.Text=('Результаты CSV сохранены: '+[IO.Path]::GetFileName($dialog.FileName))
    }catch{Show-GuiError ('Не удалось экспортировать результаты анализа: '+$_.Exception.Message)}
    finally{$dialog.Dispose()}
}

function Save-GuiSettings {
    $family=[string]$settingsFamilyBox.SelectedItem.Value
    $protocol=[string]$settingsProtocolBox.SelectedItem.Value
    $ports=ConvertTo-AntiDPIPortScope $settingsPortsBox.Text
    $rangeText=$settingsAnalysisRangeBox.Text.Trim()
    $rangeMatch=[regex]::Match($rangeText,'^([0-9]+)(?:\s*-\s*([0-9]+))?$')
    if(-not $rangeMatch.Success){throw 'Диапазон анализа должен выглядеть как 1-45.'}
    $rangeFirst=[int]$rangeMatch.Groups[1].Value;$rangeLast=if($rangeMatch.Groups[2].Success){[int]$rangeMatch.Groups[2].Value}else{$rangeFirst}
    if($rangeFirst -lt 1 -or $rangeLast -lt $rangeFirst -or $rangeLast -gt 492){throw 'Диапазон анализа должен находиться в пределах 1-492.'}
    $rangeText=('{0}-{1}' -f $rangeFirst,$rangeLast)
    $parallelism=[int]$settingsAnalysisParallelismBox.Value
    if($parallelism -lt 1 -or $parallelism -gt 5){throw 'Параллельность анализа должна быть от 1 до 5.'}
    $attempts=[int]$settingsAnalysisAttemptsBox.Value
    $timeoutSeconds=[int]$settingsAnalysisTimeoutBox.Value
    $thresholdKB=[int]$settingsAnalysisThresholdBox.Value
    if($attempts -lt 1 -or $attempts -gt 5){throw 'Число попыток должно быть от 1 до 5.'}
    if($timeoutSeconds -lt 5 -or $timeoutSeconds -gt 120){throw 'Таймаут должен быть от 5 до 120 секунд.'}
    if($thresholdKB -lt 16 -or $thresholdKB -gt 1024){throw 'Порог ответа должен быть от 16 до 1024 КиБ.'}
    $settings=@{AddressFamily=$family;Protocol=$protocol;Ports=$ports;AnalysisRange=$rangeText;AnalysisParallelism=$parallelism;AnalysisAttempts=$attempts;AnalysisTimeoutSeconds=$timeoutSeconds;AnalysisThresholdKB=$thresholdKB;RememberAdapter=[bool]$settingsRememberAdapterCheck.Checked;SkipTimestampSetup=[bool]$settingsSkipTimestampCheck.Checked;ShowErrorDetails=[bool]$settingsShowErrorDetailsCheck.Checked;Favorites=@($script:guiSettings.Favorites);RecentProfiles=@($script:guiSettings.RecentProfiles);FirstRunComplete=$true;WindowBounds=$script:guiSettings.WindowBounds;WindowMaximized=$script:guiSettings.WindowMaximized}
    [IO.Directory]::CreateDirectory((Split-Path -Parent $script:guiSettingsPath))|Out-Null
    $temporary=$script:guiSettingsPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try{
        [IO.File]::WriteAllText($temporary,($settings|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
        if(Test-Path -LiteralPath $script:guiSettingsPath -PathType Leaf){[IO.File]::Replace($temporary,$script:guiSettingsPath,[NullString]::Value)}else{[IO.File]::Move($temporary,$script:guiSettingsPath)}
    }finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force}}
    $script:guiSettings=$settings
    if($script:guiSettings.RememberAdapter -and $null -ne $adapterBox.SelectedItem){Save-AntiDPIAdapter $state $adapterBox.SelectedItem -AddressFamily $family}
    $analysisRangeBox.Text=$rangeText
    $analysisParallelismBox.Value=$parallelism
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
    $familyRows=Get-GuiFamilies
    Write-GuiLog ('Loaded profiles='+$profileRows.Count+'; families='+$familyRows.Count)
    if($profileRows.Count -ne 492){throw ('Ожидалось 492 стратегии, найдено '+$profileRows.Count+'.')}

    $form=New-Object System.Windows.Forms.Form
    $form.Text=('AntiDPI — управление стратегиями ('+$script:programVersion+')')
    $form.StartPosition='CenterScreen'
    $workingArea=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Size=[System.Drawing.Size]::new([Math]::Min(980,[Math]::Max(640,$workingArea.Width-32)),[Math]::Min(840,[Math]::Max(520,$workingArea.Height-24)))
    $form.MinimumSize=[System.Drawing.Size]::new([Math]::Min(640,$workingArea.Width),[Math]::Min(480,$workingArea.Height))
    if($null -ne $script:guiSettings.WindowBounds){try{$savedBounds=$script:guiSettings.WindowBounds;$candidate=[System.Drawing.Rectangle]::new([int]$savedBounds.X,[int]$savedBounds.Y,[int]$savedBounds.Width,[int]$savedBounds.Height);$visible=$false;foreach($screen in [System.Windows.Forms.Screen]::AllScreens){if($screen.WorkingArea.IntersectsWith($candidate)){$visible=$true;break}};if($visible){$form.StartPosition='Manual';$form.Bounds=$candidate}}catch{Write-GuiLog 'Ignoring invalid saved window bounds'}};if($script:guiSettings.WindowMaximized){$form.WindowState='Maximized'}
    $form.MaximizeBox=$true
    $form.AutoScaleMode=[System.Windows.Forms.AutoScaleMode]::Dpi
    $form.Padding=[System.Windows.Forms.Padding]::new(12)
    $form.Font=[System.Drawing.Font]::new('Segoe UI',10)
    $form.BackColor=[System.Drawing.Color]::FromArgb(247,249,252)
    $form.ForeColor=[System.Drawing.Color]::FromArgb(31,41,55)
    $tabs=New-Object System.Windows.Forms.TabControl
    $tabs.Dock=[System.Windows.Forms.DockStyle]::Fill
    $strategyTab=[System.Windows.Forms.TabPage]::new('Стратегии')
    $analysisTab=[System.Windows.Forms.TabPage]::new('Анализ')
    $historyTab=[System.Windows.Forms.TabPage]::new('История')
    $settingsTab=[System.Windows.Forms.TabPage]::new('Настройки')
    $aboutTab=[System.Windows.Forms.TabPage]::new('О программе')
    foreach($page in @($strategyTab,$analysisTab,$historyTab,$settingsTab,$aboutTab)){$page.AutoScroll=$true;$page.BackColor=[System.Drawing.Color]::White}
    $strategyTab.AutoScrollMinSize=[System.Drawing.Size]::new(740,660)
    $analysisTab.AutoScrollMinSize=[System.Drawing.Size]::new(720,590)
    $historyTab.AutoScrollMinSize=[System.Drawing.Size]::new(720,520)
    $settingsTab.AutoScrollMinSize=[System.Drawing.Size]::new(720,610)
    $aboutTab.AutoScrollMinSize=[System.Drawing.Size]::new(700,390)
    $tabs.TabPages.AddRange([System.Windows.Forms.TabPage[]]@($strategyTab,$analysisTab,$historyTab,$settingsTab,$aboutTab))
    $form.Controls.Add($tabs)

    $header=New-Object System.Windows.Forms.Label
    $header.Text='AntiDPI'
    $header.Font=[System.Drawing.Font]::new('Segoe UI Semibold',22,[System.Drawing.FontStyle]::Bold)
    $header.Location=[System.Drawing.Point]::new(26,8);$header.Size=[System.Drawing.Size]::new(680,38)
    $header.ForeColor=[System.Drawing.Color]::FromArgb(31,91,160)
    $strategyTab.Controls.Add($header)
    $versionLabel=New-Object System.Windows.Forms.Label
    $versionLabel.Text=$script:programVersion;$versionLabel.Location=[System.Drawing.Point]::new(470,18);$versionLabel.Size=[System.Drawing.Size]::new(235,28);$versionLabel.TextAlign=[System.Drawing.ContentAlignment]::MiddleRight;$versionLabel.ForeColor=[System.Drawing.Color]::DimGray
    $strategyTab.Controls.Add($versionLabel)
    $subtitle=New-Object System.Windows.Forms.Label
    $subtitle.Text='TCP/TLS и UDP/QUIC для IPv4 или IPv6. Не доказывает работу VPN/Tor-туннеля или авторизацию.'
    $subtitle.Location=[System.Drawing.Point]::new(29,48);$subtitle.Size=[System.Drawing.Size]::new(680,25)
    $strategyTab.Controls.Add($subtitle)

    $familyLabel=New-Object System.Windows.Forms.Label
    $familyLabel.Text='IP-семейство';$familyLabel.Location=[System.Drawing.Point]::new(30,78);$familyLabel.Size=[System.Drawing.Size]::new(250,24)
    $strategyTab.Controls.Add($familyLabel)
    $addressFamilyBox=New-Object System.Windows.Forms.ComboBox
    $addressFamilyBox.DropDownStyle='DropDownList';$addressFamilyBox.Location=[System.Drawing.Point]::new(30,106);$addressFamilyBox.Size=[System.Drawing.Size]::new(250,32)
    $addressFamilyBox.DisplayMember='Label';$addressFamilyBox.Items.Add([pscustomobject]@{Label='IPv4';Value='ipv4'})|Out-Null;$addressFamilyBox.Items.Add([pscustomobject]@{Label='IPv6';Value='ipv6'})|Out-Null
    $addressFamilyBox.SelectedIndex=if($script:guiSettings.AddressFamily -eq 'ipv6'){1}else{0};$strategyTab.Controls.Add($addressFamilyBox)
    $protocolLabel=New-Object System.Windows.Forms.Label
    $protocolLabel.Text='Транспорт и распознаваемый протокол';$protocolLabel.Location=[System.Drawing.Point]::new(310,78);$protocolLabel.Size=[System.Drawing.Size]::new(400,24)
    $strategyTab.Controls.Add($protocolLabel)
    $protocolBox=New-Object System.Windows.Forms.ComboBox
    $protocolBox.DropDownStyle='DropDownList';$protocolBox.Location=[System.Drawing.Point]::new(310,106);$protocolBox.Size=[System.Drawing.Size]::new(400,32)
    $protocolBox.DisplayMember='Label';$protocolBox.Items.Add([pscustomobject]@{Label='TCP + TLS ClientHello';Value='tls'})|Out-Null;$protocolBox.Items.Add([pscustomobject]@{Label='UDP + QUIC Initial (HTTP/3)';Value='quic'})|Out-Null
    $protocolBox.SelectedIndex=if($script:guiSettings.Protocol -eq 'quic'){1}else{0};$strategyTab.Controls.Add($protocolBox)

    $familyFilterLabel=New-Object System.Windows.Forms.Label
    $familyFilterLabel.Text='Группа / семейство';$familyFilterLabel.Location=[System.Drawing.Point]::new(530,144);$familyFilterLabel.Size=[System.Drawing.Size]::new(180,24)
    $strategyTab.Controls.Add($familyFilterLabel)
    $familyFilterBox=New-Object System.Windows.Forms.ComboBox
    $familyFilterBox.DropDownStyle='DropDownList';$familyFilterBox.DisplayMember='Label';$familyFilterBox.Location=[System.Drawing.Point]::new(530,172);$familyFilterBox.Size=[System.Drawing.Size]::new(180,32)
    $familyFilterBox.Add_SelectedIndexChanged({if($null -ne $familyFilterBox.SelectedItem){Update-GuiProfileFilter}})
    $strategyTab.Controls.Add($familyFilterBox)
    $profileLabel=New-Object System.Windows.Forms.Label
    $profileLabel.Text='Стратегии — поиск по номеру или названию';$profileLabel.Location=[System.Drawing.Point]::new(30,144);$profileLabel.Size=[System.Drawing.Size]::new(490,24)
    $strategyTab.Controls.Add($profileLabel)
    $profileSearchBox=New-Object System.Windows.Forms.TextBox
    $profileSearchBox.Location=[System.Drawing.Point]::new(30,172);$profileSearchBox.Size=[System.Drawing.Size]::new(390,30);$profileSearchBox.Anchor='Top,Left,Right'
    $strategyTab.Controls.Add($profileSearchBox)
    $profileCountLabel=New-Object System.Windows.Forms.Label
    $profileCountLabel.Text='492 стратегии';$profileCountLabel.Location=[System.Drawing.Point]::new(428,175);$profileCountLabel.Size=[System.Drawing.Size]::new(92,24);$profileCountLabel.ForeColor=[System.Drawing.Color]::DimGray
    $strategyTab.Controls.Add($profileCountLabel)
    $profileListBox=New-Object System.Windows.Forms.ListBox
    $profileListBox.Location=[System.Drawing.Point]::new(30,208);$profileListBox.Size=[System.Drawing.Size]::new(490,82);$profileListBox.Anchor='Top,Left,Right'
    $profileListBox.DisplayMember='Label';$profileListBox.IntegralHeight=$false;$profileListBox.ScrollAlwaysVisible=$true
    $strategyTab.Controls.Add($profileListBox)
    $favoritesCheck=New-Object System.Windows.Forms.CheckBox;$favoritesCheck.Text='Только избранное';$favoritesCheck.Location=[System.Drawing.Point]::new(530,212);$favoritesCheck.Size=[System.Drawing.Size]::new(180,28);$favoritesCheck.Add_CheckedChanged({$script:favoritesOnly=[bool]$favoritesCheck.Checked;Update-GuiProfileFilter});$strategyTab.Controls.Add($favoritesCheck)
    $profileMenu=New-Object System.Windows.Forms.ContextMenuStrip
    $favoriteMenuItem=$profileMenu.Items.Add('Добавить / убрать из избранного')
    $favoriteMenuItem.Add_Click({try{$p=Get-GuiSelectedProfile;$number=[int]$p.Number;if($number -in $script:guiSettings.Favorites){$script:guiSettings.Favorites=@($script:guiSettings.Favorites|Where-Object {$_ -ne $number})}else{$script:guiSettings.Favorites=@($script:guiSettings.Favorites)+$number};Save-GuiUiPreferences;Update-GuiProfileFilter}catch{Show-GuiError $_.Exception.Message}})
    $recentMenuItem=$profileMenu.Items.Add('Выбрать недавно использованную')
    $recentMenuItem.Add_Click({$number=@($script:guiSettings.RecentProfiles|Select-Object -First 1);if($number.Count){$profileSearchBox.Text=[string]$number[0];Update-GuiProfileFilter;if($profileListBox.Items.Count){$profileListBox.SelectedIndex=0}}})
    $profileListBox.ContextMenuStrip=$profileMenu
    $profileListBox.Add_MouseDown({param($sender,$eventArgs) if($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Right){$index=$profileListBox.IndexFromPoint($eventArgs.Location);if($index -ge 0){$profileListBox.SelectedIndex=$index}}})
    $details=New-Object System.Windows.Forms.TextBox
    $details.Location=[System.Drawing.Point]::new(32,294);$details.Size=[System.Drawing.Size]::new(675,46);$details.ForeColor=[System.Drawing.Color]::DimGray;$details.BackColor=[System.Drawing.Color]::FromArgb(248,250,252);$details.Multiline=$true;$details.ReadOnly=$true;$details.ScrollBars='Vertical'
    $details.Anchor='Top,Left,Right';$strategyTab.Controls.Add($details)
    $profileListBox.Add_SelectedIndexChanged({if($null -ne $profileListBox.SelectedItem){$p=$profileListBox.SelectedItem;$details.Text=if($p.Protocol -eq 'quic'){('Стратегия №{0}: {1}{2}Цепочка: {3}{2}Параметры: {4}' -f $p.Number,$p.Name,[Environment]::NewLine,$p.Chain,(@($p.Args)-join ' '))}else{('Стратегия №{0}: {1}{2}Семейство {3} · обработка: {4}{2}Цепочка: {5}{2}Параметры: {6}' -f $p.Number,$p.Name,[Environment]::NewLine,$p.Family,$p.Processing,$p.Chain,(@($p.Args)-join ' '))};Update-GuiDashboard}})
    $profileSearchBox.Add_TextChanged({Update-GuiProfileFilter})

    $adapterLabel=New-Object System.Windows.Forms.Label
    $adapterLabel.Text='Активный физический адаптер с адресом выбранного IP-семейства';$adapterLabel.Location=[System.Drawing.Point]::new(30,350);$adapterLabel.Size=[System.Drawing.Size]::new(500,24)
    $strategyTab.Controls.Add($adapterLabel)
    $adapterBox=New-Object System.Windows.Forms.ComboBox
    $adapterBox.DropDownStyle='DropDownList';$adapterBox.Location=[System.Drawing.Point]::new(30,378);$adapterBox.Size=[System.Drawing.Size]::new(500,32);$adapterBox.Anchor='Top,Left,Right'
    $strategyTab.Controls.Add($adapterBox)
    $refreshButton=New-Object System.Windows.Forms.Button
    $refreshButton.Text='Обновить';$refreshButton.Location=[System.Drawing.Point]::new(544,377);$refreshButton.Size=[System.Drawing.Size]::new(166,34);$refreshButton.Anchor='Top,Right'
    $strategyTab.Controls.Add($refreshButton)
    $refreshButton.Add_Click({try{Refresh-GuiAdapters}catch{Show-GuiError $_.Exception.Message}})
    $addressFamilyBox.Add_SelectedIndexChanged({try{Refresh-GuiAdapters}catch{Show-GuiError $_.Exception.Message}})

    $portsLabel=New-Object System.Windows.Forms.Label
    $portsLabel.Text='Порты назначения';$portsLabel.Location=[System.Drawing.Point]::new(30,422);$portsLabel.Size=[System.Drawing.Size]::new(260,24)
    $strategyTab.Controls.Add($portsLabel)
    $portsBox=New-Object System.Windows.Forms.TextBox
    $portsBox.Text='443';$portsBox.Location=[System.Drawing.Point]::new(30,450);$portsBox.Size=[System.Drawing.Size]::new(300,30)
    $strategyTab.Controls.Add($portsBox)
    $portsHint=New-Object System.Windows.Forms.Label
    $portsHint.Text='';$portsHint.Location=[System.Drawing.Point]::new(344,453);$portsHint.Size=[System.Drawing.Size]::new(365,34);$portsHint.Anchor='Top,Left,Right';$portsHint.ForeColor=[System.Drawing.Color]::DimGray
    $strategyTab.Controls.Add($portsHint)
    Set-GuiProfileItems $script:guiSettings.Protocol
    $portsBox.Text=$script:guiSettings.Ports
    $protocolBox.Add_SelectedIndexChanged({if($null -ne $protocolBox.SelectedItem){Set-GuiProfileItems ([string]$protocolBox.SelectedItem.Value)}})

    $recipeButton=New-Object System.Windows.Forms.Button
    $recipeButton.Text='Показать рецепт';$recipeButton.Location=[System.Drawing.Point]::new(30,494);$recipeButton.Size=[System.Drawing.Size]::new(150,34)
    $recipeButton.Add_Click({Show-GuiProfileDetails 'recipe'});$strategyTab.Controls.Add($recipeButton)
    $favoriteButton=New-Object System.Windows.Forms.Button;$favoriteButton.Text='★ Избранное';$favoriteButton.Location=[System.Drawing.Point]::new(565,494);$favoriteButton.Size=[System.Drawing.Size]::new(145,34);$favoriteButton.Add_Click({try{$p=Get-GuiSelectedProfile;$number=[int]$p.Number;if($number -in $script:guiSettings.Favorites){$script:guiSettings.Favorites=@($script:guiSettings.Favorites|Where-Object {$_ -ne $number})}else{$script:guiSettings.Favorites=@($script:guiSettings.Favorites)+$number};Save-GuiUiPreferences;Update-GuiProfileFilter}catch{Show-GuiError $_.Exception.Message}});$strategyTab.Controls.Add($favoriteButton)
    $argumentsButton=New-Object System.Windows.Forms.Button
    $argumentsButton.Text='Аргументы движка';$argumentsButton.Location=[System.Drawing.Point]::new(190,494);$argumentsButton.Size=[System.Drawing.Size]::new(160,34)
    $argumentsButton.Add_Click({Show-GuiProfileDetails 'arguments'});$strategyTab.Controls.Add($argumentsButton)
    $checkButton=New-Object System.Windows.Forms.Button
    $checkButton.Text='Проверить, не запускать';$checkButton.Location=[System.Drawing.Point]::new(360,494);$checkButton.Size=[System.Drawing.Size]::new(200,34)
    $checkButton.Add_Click({Start-GuiStrategy -CheckOnly});$strategyTab.Controls.Add($checkButton)
    $startButton=New-Object System.Windows.Forms.Button
    $startButton.Text='Запустить стратегию';$startButton.Location=[System.Drawing.Point]::new(30,538);$startButton.Size=[System.Drawing.Size]::new(210,40);$startButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$startButton.ForeColor=[System.Drawing.Color]::White;$startButton.FlatStyle='Flat'
    $startButton.Add_Click({Start-GuiStrategy});$strategyTab.Controls.Add($startButton)
    $stopButton=New-Object System.Windows.Forms.Button
    $stopButton.Text='Остановить';$stopButton.Location=[System.Drawing.Point]::new(251,538);$stopButton.Size=[System.Drawing.Size]::new(145,40);$stopButton.Enabled=$false
    $stopButton.Add_Click({Request-GuiStop});$strategyTab.Controls.Add($stopButton)
    $logsButton=New-Object System.Windows.Forms.Button
    $logsButton.Text='Открыть логи';$logsButton.Location=[System.Drawing.Point]::new(407,538);$logsButton.Size=[System.Drawing.Size]::new(145,40)
    $logsButton.Add_Click({try{$directory=Get-AntiDPILogDirectory $bundle;Start-Process explorer.exe -ArgumentList (ConvertTo-WindowsArgument $directory)}catch{Show-GuiError $_.Exception.Message}});$strategyTab.Controls.Add($logsButton)
    $restartButton=New-Object System.Windows.Forms.Button
    $restartButton.Text='Перезапустить';$restartButton.Location=[System.Drawing.Point]::new(560,538);$restartButton.Size=[System.Drawing.Size]::new(150,40);$restartButton.Enabled=$false
    $restartButton.Add_Click({Request-GuiRestart});$strategyTab.Controls.Add($restartButton)
    $statusLabel=New-Object System.Windows.Forms.Label
    $statusLabel.Text='Готово к запуску';$statusLabel.Location=[System.Drawing.Point]::new(30,586);$statusLabel.Size=[System.Drawing.Size]::new(680,25);$statusLabel.Anchor='Left,Right,Bottom';$statusLabel.ForeColor=[System.Drawing.Color]::DarkGreen
    $strategyTab.Controls.Add($statusLabel)
    $script:dashboardLabel=New-Object System.Windows.Forms.Label;$script:dashboardLabel.Text='Готово к запуску';$script:dashboardLabel.Location=[System.Drawing.Point]::new(30,630);$script:dashboardLabel.Size=[System.Drawing.Size]::new(680,32);$script:dashboardLabel.Anchor='Left,Right,Bottom';$script:dashboardLabel.BorderStyle='FixedSingle';$script:dashboardLabel.BackColor=[System.Drawing.Color]::FromArgb(242,246,250);$strategyTab.Controls.Add($script:dashboardLabel)
    $addressFamilyBox.Add_SelectedIndexChanged({Update-GuiDashboard});$protocolBox.Add_SelectedIndexChanged({Update-GuiDashboard});$adapterBox.Add_SelectedIndexChanged({Update-GuiDashboard});$portsBox.Add_TextChanged({Update-GuiDashboard})

    $analysisInfo=New-Object System.Windows.Forms.Label
    $analysisInfo.Text='Контроль без тестовой стратегии сравнивается с каждой стратегией: если оба проходят, статус будет BASELINE_PASS, а не PASS. Число попыток, таймаут и порог ответа настраиваются во вкладке «Настройки». Тест только YouTube IPv4/TCP/TLS; не доказывает VPN/Tor или обход DPI.'
    $analysisInfo.Location=[System.Drawing.Point]::new(20,18);$analysisInfo.Size=[System.Drawing.Size]::new(690,68);$analysisInfo.Anchor='Top,Left,Right'
    $analysisTab.Controls.Add($analysisInfo)
    $analysisRangeLabel=New-Object System.Windows.Forms.Label
    $analysisRangeLabel.Text='Номера стратегий (например, 1-45)';$analysisRangeLabel.Location=[System.Drawing.Point]::new(22,92);$analysisRangeLabel.Size=[System.Drawing.Size]::new(300,24)
    $analysisTab.Controls.Add($analysisRangeLabel)
    $analysisRangeBox=New-Object System.Windows.Forms.TextBox
    $analysisRangeBox.Text=[string]$script:guiSettings.AnalysisRange;$analysisRangeBox.Location=[System.Drawing.Point]::new(22,120);$analysisRangeBox.Size=[System.Drawing.Size]::new(180,30)
    $analysisTab.Controls.Add($analysisRangeBox)
    $analysisParallelLabel=New-Object System.Windows.Forms.Label
    $analysisParallelLabel.Text='Параллельность (1–5)';$analysisParallelLabel.Location=[System.Drawing.Point]::new(218,92);$analysisParallelLabel.Size=[System.Drawing.Size]::new(150,24)
    $analysisTab.Controls.Add($analysisParallelLabel)
    $analysisParallelismBox=New-Object System.Windows.Forms.NumericUpDown
    $analysisParallelismBox.Minimum=1;$analysisParallelismBox.Maximum=5;$analysisParallelismBox.Value=[decimal]$script:guiSettings.AnalysisParallelism
    $analysisParallelismBox.Location=[System.Drawing.Point]::new(222,120);$analysisParallelismBox.Size=[System.Drawing.Size]::new(72,30)
    $analysisTab.Controls.Add($analysisParallelismBox)
    $analysisButton=New-Object System.Windows.Forms.Button
    $analysisButton.Text='Начать анализ';$analysisButton.Location=[System.Drawing.Point]::new(310,118);$analysisButton.Size=[System.Drawing.Size]::new(155,36);$analysisButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$analysisButton.ForeColor=[System.Drawing.Color]::White
    $analysisTab.Controls.Add($analysisButton)
    $analysisCancelButton=New-Object System.Windows.Forms.Button
    $analysisCancelButton.Text='Остановить';$analysisCancelButton.Location=[System.Drawing.Point]::new(475,118);$analysisCancelButton.Size=[System.Drawing.Size]::new(130,36);$analysisCancelButton.Enabled=$false
    $analysisTab.Controls.Add($analysisCancelButton)
    $script:analysisExportButton=New-Object System.Windows.Forms.Button
    $script:analysisExportButton.Text='Экспорт CSV';$script:analysisExportButton.Location=[System.Drawing.Point]::new(615,118);$script:analysisExportButton.Size=[System.Drawing.Size]::new(96,36);$script:analysisExportButton.Enabled=$false
    $script:analysisExportButton.Add_Click({Export-GuiAnalysisResults});$analysisTab.Controls.Add($script:analysisExportButton)
    $analysisGrid=New-Object System.Windows.Forms.DataGridView
    $analysisGrid.Location=[System.Drawing.Point]::new(20,166);$analysisGrid.Size=[System.Drawing.Size]::new(690,365);$analysisGrid.Anchor='Top,Bottom,Left,Right'
    $analysisGrid.ReadOnly=$true;$analysisGrid.AllowUserToAddRows=$false;$analysisGrid.AllowUserToDeleteRows=$false;$analysisGrid.RowHeadersVisible=$false
    $analysisGrid.AutoSizeColumnsMode='Fill';$analysisGrid.SelectionMode='FullRowSelect';$analysisGrid.MultiSelect=$false
    foreach($column in @(
        @{Name='Number';Header='№';Fill=42},
        @{Name='Name';Header='Стратегия';Fill=190},
        @{Name='Status';Header='Статус';Fill=90},
        @{Name='Attempts';Header='Попытки';Fill=135},
        @{Name='Recommendation';Header='Оценка';Fill=170},
        @{Name='Details';Header='Причина / данные';Fill=180}
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

    $historySearchLabel=New-Object System.Windows.Forms.Label;$historySearchLabel.Text='Поиск истории';$historySearchLabel.Location=[System.Drawing.Point]::new(22,24);$historySearchLabel.Size=[System.Drawing.Size]::new(105,24);$historyTab.Controls.Add($historySearchLabel)
    $historySearchBox=New-Object System.Windows.Forms.TextBox;$script:historySearchBox=$historySearchBox;$historySearchBox.Location=[System.Drawing.Point]::new(130,20);$historySearchBox.Size=[System.Drawing.Size]::new(352,30);$historySearchBox.Anchor='Top,Left,Right';$historySearchBox.Add_TextChanged({Update-GuiHistory});$historyTab.Controls.Add($historySearchBox)
    $historyExportButton=New-Object System.Windows.Forms.Button;$historyExportButton.Text='Экспорт CSV';$historyExportButton.Location=[System.Drawing.Point]::new(500,18);$historyExportButton.Size=[System.Drawing.Size]::new(130,34);$historyExportButton.Anchor='Top,Right';$historyExportButton.Add_Click({Export-GuiHistory});$historyTab.Controls.Add($historyExportButton)
    $historyRefreshButton=New-Object System.Windows.Forms.Button;$historyRefreshButton.Text='Обновить';$historyRefreshButton.Location=[System.Drawing.Point]::new(642,18);$historyRefreshButton.Size=[System.Drawing.Size]::new(80,34);$historyRefreshButton.Anchor='Top,Right';$historyRefreshButton.Add_Click({Update-GuiHistory});$historyTab.Controls.Add($historyRefreshButton)
    $script:historyGrid=New-Object System.Windows.Forms.DataGridView;$script:historyGrid.Location=[System.Drawing.Point]::new(22,64);$script:historyGrid.Size=[System.Drawing.Size]::new(700,420);$script:historyGrid.Anchor='Top,Bottom,Left,Right';$script:historyGrid.ReadOnly=$true;$script:historyGrid.AllowUserToAddRows=$false;$script:historyGrid.AllowUserToDeleteRows=$false;$script:historyGrid.RowHeadersVisible=$false;$script:historyGrid.AutoSizeColumnsMode='Fill';$script:historyGrid.SelectionMode='FullRowSelect'
    foreach($col in @(@{Name='Time';Header='Время';Fill=150},@{Name='Kind';Header='Тип';Fill=90},@{Name='Status';Header='Результат';Fill=90},@{Name='Summary';Header='Событие';Fill=300})){$c=New-Object System.Windows.Forms.DataGridViewTextBoxColumn;$c.Name=$col.Name;$c.HeaderText=$col.Header;$c.FillWeight=[single]$col.Fill;$null=$script:historyGrid.Columns.Add($c)};$historyTab.Controls.Add($script:historyGrid)
    $historyStatusLabel=New-Object System.Windows.Forms.Label;$historyStatusLabel.Text='События сохраняются локально (до 1000 записей).';$historyStatusLabel.Location=[System.Drawing.Point]::new(22,492);$historyStatusLabel.Size=[System.Drawing.Size]::new(690,28);$historyStatusLabel.Anchor='Bottom,Left,Right';$historyTab.Controls.Add($historyStatusLabel)

    $aboutTitle=New-Object System.Windows.Forms.Label
    $aboutTitle.Text='AntiDPI';$aboutTitle.Font=[System.Drawing.Font]::new('Segoe UI Semibold',22,[System.Drawing.FontStyle]::Bold);$aboutTitle.Location=[System.Drawing.Point]::new(28,24);$aboutTitle.Size=[System.Drawing.Size]::new(650,40)
    $aboutTab.Controls.Add($aboutTitle)
    $aboutVersionLabel=New-Object System.Windows.Forms.Label
    $aboutVersionLabel.Text=('Установленная версия: '+$script:programVersion);$aboutVersionLabel.Font=[System.Drawing.Font]::new('Segoe UI',12,[System.Drawing.FontStyle]::Bold);$aboutVersionLabel.Location=[System.Drawing.Point]::new(30,82);$aboutVersionLabel.Size=[System.Drawing.Size]::new(650,30)
    $aboutTab.Controls.Add($aboutVersionLabel)
    $aboutText=New-Object System.Windows.Forms.Label
    $aboutText.Text='Графический интерфейс и CLI для выбора и проверки стратегий Zapret2. Поддерживаются Windows 10/11 x64. Ctrl+F — поиск, Ctrl+Enter — запуск, Ctrl+L — журналы, F2 — безопасный перезапуск, Ctrl+C — безопасная остановка. Проверка YouTube оценивает только IPv4/TCP/TLS и не является проверкой VPN/Tor-туннеля или гарантией обхода DPI.'
    $aboutText.Location=[System.Drawing.Point]::new(30,128);$aboutText.Size=[System.Drawing.Size]::new(660,105);$aboutText.Anchor='Top,Left,Right';$aboutText.AutoSize=$false
    $aboutTab.Controls.Add($aboutText)
    $aboutLicense=New-Object System.Windows.Forms.Label
    $aboutLicense.Text='Источник: github.com/Vidoc3000/anti-dpi-for-russia-TEST. Движок Zapret2 — проект bol-van; лицензии и уведомления включены в комплект.'
    $aboutLicense.Location=[System.Drawing.Point]::new(30,250);$aboutLicense.Size=[System.Drawing.Size]::new(660,60);$aboutLicense.Anchor='Top,Left,Right'
    $aboutTab.Controls.Add($aboutLicense)
    $aboutReleaseButton=New-Object System.Windows.Forms.Button
    $aboutReleaseButton.Text='Открыть страницу релизов';$aboutReleaseButton.Location=[System.Drawing.Point]::new(30,350);$aboutReleaseButton.Size=[System.Drawing.Size]::new(230,40)
    $aboutReleaseButton.Add_Click({try{Start-Process 'https://github.com/Vidoc3000/anti-dpi-for-russia-TEST/releases'}catch{Show-GuiError $_.Exception.Message}})
    $aboutTab.Controls.Add($aboutReleaseButton)

    $settingsInfo=New-Object System.Windows.Forms.Label
    $settingsInfo.Text='Настройки сохраняются для следующих запусков. Активный трафик изменяется только после запуска стратегии.'
    $settingsInfo.Location=[System.Drawing.Point]::new(24,24);$settingsInfo.Size=[System.Drawing.Size]::new(680,34);$settingsInfo.Anchor='Top,Left,Right'
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
    $settingsRememberAdapterCheck=New-Object System.Windows.Forms.CheckBox
    $settingsRememberAdapterCheck.Text='Запоминать последний выбранный физический адаптер'
    $settingsRememberAdapterCheck.Checked=[bool]$script:guiSettings.RememberAdapter
    $settingsRememberAdapterCheck.Location=[System.Drawing.Point]::new(28,254);$settingsRememberAdapterCheck.Size=[System.Drawing.Size]::new(500,28)
    $settingsTab.Controls.Add($settingsRememberAdapterCheck)
    $settingsAnalysisRangeLabel=New-Object System.Windows.Forms.Label
    $settingsAnalysisRangeLabel.Text='Диапазон YouTube-анализа по умолчанию (1-492)'
    $settingsAnalysisRangeLabel.Location=[System.Drawing.Point]::new(28,298);$settingsAnalysisRangeLabel.Size=[System.Drawing.Size]::new(500,24)
    $settingsTab.Controls.Add($settingsAnalysisRangeLabel)
    $settingsAnalysisRangeBox=New-Object System.Windows.Forms.TextBox
    $settingsAnalysisRangeBox.Text=[string]$script:guiSettings.AnalysisRange
    $settingsAnalysisRangeBox.Location=[System.Drawing.Point]::new(28,326);$settingsAnalysisRangeBox.Size=[System.Drawing.Size]::new(220,30)
    $settingsTab.Controls.Add($settingsAnalysisRangeBox)
    $settingsParallelLabel=New-Object System.Windows.Forms.Label
    $settingsParallelLabel.Text='Параллельность анализа (1–5)';$settingsParallelLabel.Location=[System.Drawing.Point]::new(280,298);$settingsParallelLabel.Size=[System.Drawing.Size]::new(260,24)
    $settingsTab.Controls.Add($settingsParallelLabel)
    $settingsAnalysisParallelismBox=New-Object System.Windows.Forms.NumericUpDown
    $settingsAnalysisParallelismBox.Minimum=1;$settingsAnalysisParallelismBox.Maximum=5;$settingsAnalysisParallelismBox.Value=[decimal]$script:guiSettings.AnalysisParallelism
    $settingsAnalysisParallelismBox.Location=[System.Drawing.Point]::new(280,326);$settingsAnalysisParallelismBox.Size=[System.Drawing.Size]::new(100,30)
    $settingsTab.Controls.Add($settingsAnalysisParallelismBox)
    $settingsAttemptsLabel=New-Object System.Windows.Forms.Label
    $settingsAttemptsLabel.Text='Попыток на стратегию (1–5)';$settingsAttemptsLabel.Location=[System.Drawing.Point]::new(28,370);$settingsAttemptsLabel.Size=[System.Drawing.Size]::new(215,24)
    $settingsTab.Controls.Add($settingsAttemptsLabel)
    $settingsAnalysisAttemptsBox=New-Object System.Windows.Forms.NumericUpDown
    $settingsAnalysisAttemptsBox.Minimum=1;$settingsAnalysisAttemptsBox.Maximum=5;$settingsAnalysisAttemptsBox.Value=[decimal]$script:guiSettings.AnalysisAttempts
    $settingsAnalysisAttemptsBox.Location=[System.Drawing.Point]::new(28,398);$settingsAnalysisAttemptsBox.Size=[System.Drawing.Size]::new(100,30)
    $settingsTab.Controls.Add($settingsAnalysisAttemptsBox)
    $settingsTimeoutLabel=New-Object System.Windows.Forms.Label
    $settingsTimeoutLabel.Text='Таймаут HTTPS (сек, 5–120)';$settingsTimeoutLabel.Location=[System.Drawing.Point]::new(260,370);$settingsTimeoutLabel.Size=[System.Drawing.Size]::new(220,24)
    $settingsTab.Controls.Add($settingsTimeoutLabel)
    $settingsAnalysisTimeoutBox=New-Object System.Windows.Forms.NumericUpDown
    $settingsAnalysisTimeoutBox.Minimum=5;$settingsAnalysisTimeoutBox.Maximum=120;$settingsAnalysisTimeoutBox.Value=[decimal]$script:guiSettings.AnalysisTimeoutSeconds
    $settingsAnalysisTimeoutBox.Location=[System.Drawing.Point]::new(260,398);$settingsAnalysisTimeoutBox.Size=[System.Drawing.Size]::new(100,30)
    $settingsTab.Controls.Add($settingsAnalysisTimeoutBox)
    $settingsThresholdLabel=New-Object System.Windows.Forms.Label
    $settingsThresholdLabel.Text='Порог ответа, КиБ (16–1024)';$settingsThresholdLabel.Location=[System.Drawing.Point]::new(492,370);$settingsThresholdLabel.Size=[System.Drawing.Size]::new(220,24)
    $settingsTab.Controls.Add($settingsThresholdLabel)
    $settingsAnalysisThresholdBox=New-Object System.Windows.Forms.NumericUpDown
    $settingsAnalysisThresholdBox.Minimum=16;$settingsAnalysisThresholdBox.Maximum=1024;$settingsAnalysisThresholdBox.Value=[decimal]$script:guiSettings.AnalysisThresholdKB
    $settingsAnalysisThresholdBox.Location=[System.Drawing.Point]::new(492,398);$settingsAnalysisThresholdBox.Size=[System.Drawing.Size]::new(100,30)
    $settingsTab.Controls.Add($settingsAnalysisThresholdBox)
    $settingsSkipTimestampCheck=New-Object System.Windows.Forms.CheckBox
    $settingsSkipTimestampCheck.Text='Не менять системную настройку TCP timestamps'
    $settingsSkipTimestampCheck.Checked=[bool]$script:guiSettings.SkipTimestampSetup
    $settingsSkipTimestampCheck.Location=[System.Drawing.Point]::new(28,442);$settingsSkipTimestampCheck.Size=[System.Drawing.Size]::new(560,28)
    $settingsTab.Controls.Add($settingsSkipTimestampCheck)
    $settingsShowErrorDetailsCheck=New-Object System.Windows.Forms.CheckBox
    $settingsShowErrorDetailsCheck.Text='Автоматически показывать подробные логи при ошибках'
    $settingsShowErrorDetailsCheck.Checked=[bool]$script:guiSettings.ShowErrorDetails
    $settingsShowErrorDetailsCheck.Location=[System.Drawing.Point]::new(28,478);$settingsShowErrorDetailsCheck.Size=[System.Drawing.Size]::new(560,28)
    $settingsTab.Controls.Add($settingsShowErrorDetailsCheck)
    $settingsSaveButton=New-Object System.Windows.Forms.Button
    $settingsSaveButton.Text='Сохранить настройки';$settingsSaveButton.Location=[System.Drawing.Point]::new(28,520);$settingsSaveButton.Size=[System.Drawing.Size]::new(210,40);$settingsSaveButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$settingsSaveButton.ForeColor=[System.Drawing.Color]::White
    $settingsTab.Controls.Add($settingsSaveButton)
    $interfacesButton=New-Object System.Windows.Forms.Button
    $interfacesButton.Text='Список всех интерфейсов';$interfacesButton.Location=[System.Drawing.Point]::new(250,520);$interfacesButton.Size=[System.Drawing.Size]::new(220,40)
    $interfacesButton.Add_Click({Show-GuiInterfaces});$settingsTab.Controls.Add($interfacesButton)
    $settingsStatusLabel=New-Object System.Windows.Forms.Label
    $settingsStatusLabel.Text='';$settingsStatusLabel.Location=[System.Drawing.Point]::new(28,572);$settingsStatusLabel.Size=[System.Drawing.Size]::new(650,32)
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
        $profileSearchBox.Text=[string]$number;Update-GuiProfileFilter;if($profileListBox.Items.Count){$profileListBox.SelectedIndex=0}
        $tabs.SelectedTab=$strategyTab
        Set-GuiStatus ('Выбрана стратегия {0}, прошедшая только YouTube-тест. VPN/Tor проверьте отдельно.' -f $number) ([System.Drawing.Color]::DarkOrange)
    })

    Refresh-GuiAdapters
    Load-GuiAnalysisHistory
    Update-GuiHistory
    if(-not $script:guiSettings.FirstRunComplete){$welcome='Добро пожаловать в AntiDPI.'+[Environment]::NewLine+[Environment]::NewLine+'1. Выберите IP-семейство, транспорт и физический сетевой адаптер.'+[Environment]::NewLine+'2. Найдите стратегию; её описание показано под списком. Сначала нажмите «Проверить, не запускать».'+[Environment]::NewLine+'3. Запуск меняет обработку трафика; останавливайте кнопкой «Остановить», чтобы корректно восстановить состояние.'+[Environment]::NewLine+[Environment]::NewLine+'Анализ проверяет только доступность YouTube IPv4/TCP/TLS и не доказывает работу VPN/Tor или обход DPI.';[System.Windows.Forms.MessageBox]::Show($welcome,'Первый запуск AntiDPI',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null;$script:guiSettings.FirstRunComplete=$true}
    $timer=New-Object System.Windows.Forms.Timer
    $timer.Interval=650
    $timer.Add_Tick({
        if($null -ne $script:worker -and $script:worker.HasExited){
            $code=$script:worker.ExitCode
            $script:worker.Dispose();$script:worker=$null
            $script:stopPending=$false
            $startButton.Enabled=$true;$stopButton.Enabled=$false;$restartButton.Enabled=$false;$checkButton.Enabled=$true;$recipeButton.Enabled=$true;$argumentsButton.Enabled=$true;$profileListBox.Enabled=$true;$profileSearchBox.Enabled=$true;$adapterBox.Enabled=$true;$refreshButton.Enabled=$true;$portsBox.Enabled=$true;$addressFamilyBox.Enabled=$true;$protocolBox.Enabled=$true
            if($code -eq 0 -and $script:workerMode -eq 'check'){
                $output=Get-GuiProcessOutput $script:workerStdoutPath $script:workerStderrPath
                $checkLine=Get-GuiFailureLine $script:workerStdoutPath ''
                Set-GuiStatus ('Проверка завершена успешно: '+$checkLine+'; перехват не запускался.') ([System.Drawing.Color]::DarkGreen)
                Show-GuiTextDialog ('Результат проверки стратегии '+[int]$script:runningProfile) $output
            }elseif($code -eq 0){Set-GuiStatus 'Остановлено. Можно выбрать другую стратегию и запустить снова.' ([System.Drawing.Color]::DarkGreen);Add-GuiHistory 'Стратегия' 'ОСТАНОВЛЕНА' ('№{0}' -f [int]$script:runningProfile)}
            else{
                $failure=Get-GuiFailureLine $script:workerStdoutPath $script:workerStderrPath
                Set-GuiStatus ('Ошибка процесса: '+$failure) ([System.Drawing.Color]::Firebrick);Add-GuiHistory 'Стратегия' 'ОШИБКА' ('№{0}: {1}' -f [int]$script:runningProfile,$failure)
                if($script:guiSettings.ShowErrorDetails){Show-GuiTextDialog ('Ошибка стратегии '+[int]$script:runningProfile) (Get-GuiProcessOutput $script:workerStdoutPath $script:workerStderrPath)}
            }
            if($script:restartAfterStop){$script:restartAfterStop=$false;Start-GuiStrategy}
            elseif($script:focusAfterStop){
                $focusTarget=$script:focusAfterStop;$script:focusAfterStop=''
                if($focusTarget -eq 'profile'){$tabs.SelectedTab=$strategyTab;$profileListBox.Focus()}
                elseif($focusTarget -eq 'adapter'){$tabs.SelectedTab=$strategyTab;$adapterBox.Focus()}
            }
            if($script:closeWhenStopped -and $null -eq $script:analysisWorker){$form.Close()}
        }elseif($script:stopPending -and $null -ne $script:worker){
            try{$null=[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle)}catch{}
        }elseif($null -ne $script:worker){
            $ownedRecord=Join-Path $state 'owned_process.json'
            if(Test-Path -LiteralPath $ownedRecord){
                try{$owned=Get-Content -LiteralPath $ownedRecord -Raw|ConvertFrom-Json;$engine=Get-Process -Id ([int]$owned.PID) -ErrorAction Stop;if($engine.Path -ieq [string]$owned.Exe -and $engine.StartTime.ToUniversalTime().ToString('o') -ceq [string]$owned.StartUTC){Set-GuiStatus ('Работает стратегия {0} на выбранном адаптере.' -f [int]$script:runningProfile) ([System.Drawing.Color]::DarkGreen)}}catch{}
            }
        }
        if($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited -and (Test-Path -LiteralPath $script:analysisResultPath -PathType Leaf)){
            try{$null=Set-GuiAnalysisResults $script:analysisResultPath}catch{}
        }
        if($null -ne $script:analysisWorker -and $script:analysisWorker.HasExited){
            $code=$script:analysisWorker.ExitCode
            $script:analysisWorker.Dispose();$script:analysisWorker=$null
            $analysisButton.Enabled=$true;$analysisCancelButton.Enabled=$false;$analysisRangeBox.Enabled=$true
            $startButton.Enabled=$true;$settingsSaveButton.Enabled=$true
            if(Test-Path -LiteralPath $script:analysisCancelFile){Remove-Item -LiteralPath $script:analysisCancelFile -Force -ErrorAction SilentlyContinue}
            if(Test-Path -LiteralPath $script:analysisResultPath -PathType Leaf){
                try{
                    $shown=Set-GuiAnalysisResults $script:analysisResultPath
                    if($code -eq 0){$analysisStatusLabel.Text+=' — анализ завершён; результаты выше';Add-GuiHistory 'Анализ YouTube' 'ЗАВЕРШЁН' ('Стратегии {0}; результаты: {1}' -f $script:guiSettings.AnalysisRange,$shown)}
                    else{
                        Add-GuiHistory 'Анализ YouTube' 'ОШИБКА' ('Стратегии {0}; код {1}' -f $script:guiSettings.AnalysisRange,$code)
                        $failure=Get-GuiFailureLine $script:analysisStdoutPath $script:analysisStderrPath
                        $analysisStatusLabel.Text=('Анализ остановлен с ошибкой после {0} результатов: {1}' -f $shown,$failure)
                        if($script:guiSettings.ShowErrorDetails){Show-GuiTextDialog 'Диагностика анализа YouTube' (Get-GuiProcessOutput $script:analysisStdoutPath $script:analysisStderrPath)}
                    }
                }catch{Show-GuiError $_.Exception.Message}
            }else{
                $failure=Get-GuiFailureLine $script:analysisStdoutPath $script:analysisStderrPath
                $analysisStatusLabel.Text=('Не удалось получить результаты анализа: '+$failure)
                if($script:guiSettings.ShowErrorDetails){Show-GuiTextDialog 'Диагностика анализа YouTube' (Get-GuiProcessOutput $script:analysisStdoutPath $script:analysisStderrPath)}
            }
            if($script:closeWhenStopped -and $null -eq $script:worker){$form.Close()}
        }
        if($script:closeWhenStopped -and $null -eq $script:worker -and $null -eq $script:analysisWorker){$form.Close()}
    })
    $timer.Start()
    $form.KeyPreview=$true
    $form.Add_KeyDown({
        if($_.KeyCode -eq [System.Windows.Forms.Keys]::F1){
            $_.Handled=$true
            if($null -ne $script:worker -and -not $script:worker.HasExited){$script:focusAfterStop='profile';Request-GuiStop}
            else{$tabs.SelectedTab=$strategyTab;$profileListBox.Focus()}
        }elseif($_.KeyCode -eq [System.Windows.Forms.Keys]::F2){
            $_.Handled=$true
            Request-GuiRestart
        }elseif($_.KeyCode -eq [System.Windows.Forms.Keys]::F3){
            $_.Handled=$true
            if($null -ne $script:worker -and -not $script:worker.HasExited){$script:focusAfterStop='adapter';Request-GuiStop}
            else{$tabs.SelectedTab=$strategyTab;$adapterBox.Focus()}
        }elseif($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::F){$_.Handled=$true;$tabs.SelectedTab=$strategyTab;$profileSearchBox.Focus();$profileSearchBox.SelectAll()}elseif($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::Enter){$_.Handled=$true;Start-GuiStrategy} elseif($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::L){$_.Handled=$true;try{$directory=Get-AntiDPILogDirectory $bundle;Start-Process explorer.exe -ArgumentList (ConvertTo-WindowsArgument $directory)}catch{Show-GuiError $_.Exception.Message}} elseif($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::C -and $null -ne $script:worker -and -not $script:worker.HasExited){
            $_.Handled=$true;Request-GuiStop
        }
    })
    $form.Add_FormClosing({
        $strategyActive=$null -ne $script:worker -and -not $script:worker.HasExited
        $analysisActive=$null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited
        if($strategyActive -or $analysisActive){
            $answer=[System.Windows.Forms.MessageBox]::Show('AntiDPI выполняет задачу. Закрытие запросит безопасную остановку и дождётся завершения тестовых процессов. Продолжить?','AntiDPI',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
            if($answer -ne [System.Windows.Forms.DialogResult]::Yes){$_.Cancel=$true}
            else{
                $_.Cancel=$true;$script:closeWhenStopped=$true;$script:restartAfterStop=$false
                if($strategyActive){Request-GuiStop}
                if($analysisActive){Request-GuiAnalysisCancel}
            }
        }
    })
    $form.Add_FormClosing({if($form.WindowState -ne 'Minimized'){$bounds=if($form.WindowState -eq 'Maximized'){$form.RestoreBounds}else{$form.Bounds};$script:guiSettings.WindowBounds=@{X=$bounds.X;Y=$bounds.Y;Width=$bounds.Width;Height=$bounds.Height};$script:guiSettings.WindowMaximized=($form.WindowState -eq 'Maximized');$script:guiSettings.FirstRunComplete=$true;try{[IO.Directory]::CreateDirectory((Split-Path -Parent $script:guiSettingsPath))|Out-Null;[IO.File]::WriteAllText($script:guiSettingsPath,($script:guiSettings|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))}catch{Write-GuiLog ('Could not persist window state: '+$_.Exception.Message)}}})
    $form.Add_FormClosed({$timer.Stop();$timer.Dispose()})
    Write-GuiLog 'Showing main form'
    [void]$form.ShowDialog()
    Write-GuiLog 'Main form closed normally'
}catch{Write-GuiLog ('FATAL: '+$_.Exception.ToString());Show-GuiError $_.Exception.Message}
finally{if($null -ne $script:worker){$script:worker.Dispose()};if($null -ne $script:analysisWorker){$script:analysisWorker.Dispose()}}
