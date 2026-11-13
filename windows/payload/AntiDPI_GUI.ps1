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
$script:connectionProfilesPath=Join-Path $state 'gui\connection-profiles.json'
$script:connectionProfiles=@()
$script:trayIcon=$null
$script:networkSignature=''
$script:networkMatrixJob=$null
$script:networkMatrixCancelPath=''
$script:tunnelCheckJob=$null
$script:releaseCheckJob=$null
$script:assetVerificationJob=$null
$script:installedSourceCommit=''
$script:networkCandidateSignature=''
$script:networkCandidateCount=0
$script:profilesCombo=$null
$script:trayMinimizeCheck=$null
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
$script:guiSettings=@{AddressFamily='ipv4';Protocol='tls';Ports='443';AnalysisRange='1-45';AnalysisParallelism=3;AnalysisAttempts=2;AnalysisTimeoutSeconds=15;AnalysisThresholdKB=100;RememberAdapter=$true;SkipTimestampSetup=$false;ShowErrorDetails=$true;Favorites=@();RecentProfiles=@();RecentProfileConfig=$null;FirstRunComplete=$false;WindowBounds=$null;WindowMaximized=$false;MinimizeToTray=$false}
$guiLog=Join-Path $state 'gui\startup.log'
function Write-GuiLog([string]$Message) {
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $guiLog))|Out-Null
        [IO.File]::AppendAllText($guiLog,((Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')+' '+$Message+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
    } catch {}
}
$installManifestPath=Join-Path $installRoot '.antidpi-install.json'
try{if(Test-Path -LiteralPath $installManifestPath -PathType Leaf){$installManifest=Get-Content -LiteralPath $installManifestPath -Raw -Encoding UTF8|ConvertFrom-Json;if($installManifest.DisplayVersion){$script:programVersion=[string]$installManifest.DisplayVersion}elseif($installManifest.Version -match '([0-9]+\.[0-9]+(?:\.[0-9]+)*)'){$script:programVersion=('Версия '+$Matches[1])};if($installManifest.PSObject.Properties['SourceCommit'] -and [string]$installManifest.SourceCommit -match '^[0-9a-f]{40}$'){$script:installedSourceCommit=[string]$installManifest.SourceCommit}}}catch{Write-GuiLog ('Could not read installed version: '+$_.Exception.Message)}
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
        if($saved.PSObject.Properties['RecentProfileConfig']){$script:guiSettings.RecentProfileConfig=$saved.RecentProfileConfig}
        if($saved.PSObject.Properties['FirstRunComplete']){$script:guiSettings.FirstRunComplete=[bool]$saved.FirstRunComplete}
        if($saved.PSObject.Properties['WindowBounds'] -and $null -ne $saved.WindowBounds){$script:guiSettings.WindowBounds=$saved.WindowBounds}
        if($saved.PSObject.Properties['WindowMaximized']){$script:guiSettings.WindowMaximized=[bool]$saved.WindowMaximized}
        if($saved.PSObject.Properties['MinimizeToTray']){$script:guiSettings.MinimizeToTray=[bool]$saved.MinimizeToTray}
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
$script:workerStartedUtc=[DateTime]::MinValue
$script:workerHealthMissCount=0
$script:workerHealthWarningShown=$false
$script:orphanedOwnedEngine=$null
$script:orphanRecoveryPending=$false
$script:orphanRecoveryStartedUtc=[DateTime]::MinValue
$script:orphanRecoveryWarned=$false
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
    $baselineAfter=Get-GuiObjectProperty $Data 'BaselineAfter' $null
    $mode=[string](Get-GuiObjectProperty $Data 'Mode' 'standard')
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
            BaselineAfterSuccesses=[int](Get-GuiObjectProperty $baselineAfter 'Successes' 0)
            Mode=$mode
            StrategyNumber=$number
            StrategyName=$name
            Status=$status
            Recommendation=(Get-GuiAnalysisRecommendation $status)
            SuccessfulAttempts=[int](Get-GuiObjectProperty $result 'Successes' 0)
            ExpectedAttempts=[int](Get-GuiObjectProperty $result 'ExpectedAttempts' 0)
            MeanSuccessSeconds=(Get-GuiObjectProperty $result 'MeanSuccessSeconds' $null)
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
    if($null -ne $script:trayIcon){$safeText=$Text -replace '[\r\n]+',' ';if($safeText.Length -gt 60){$safeText=$safeText.Substring(0,57)+'...'};$script:trayIcon.Text=('AntiDPI — '+$safeText)}
}
function Get-GuiSelectedProfile {
    $profileText=$profileSearchBox.Text.Trim()
    $selectedProfile=$null
    if($null -ne $profileListBox.SelectedItem){$selectedProfile=$profileListBox.SelectedItem}
    else{$profileMatches=@($script:profileItems|Where-Object {([string]$_.Number -ceq $profileText) -or ([string]$_.Label -ceq $profileText)});if($profileMatches.Count -eq 1){$selectedProfile=$profileMatches[0]}}
    if($null -eq $selectedProfile){throw 'Выберите стратегию из списка, введите её номер или укажите точное название.'}
    return $selectedProfile
}
function ConvertTo-GuiConnectionProfile($Profile) {
    if($null -eq $Profile){throw 'Профиль подключения пуст.'}
    $name=[string](Get-GuiObjectProperty $Profile 'Name' '').Trim()
    $number=0
    if([string]::IsNullOrWhiteSpace($name) -or $name.Length -gt 48 -or $name -match '[\x00-\x1F]'){throw 'Имя профиля должно содержать от 1 до 48 печатных символов.'}
    if(-not [int]::TryParse([string](Get-GuiObjectProperty $Profile 'ProfileNumber' ''),[ref]$number) -or $number -lt 1 -or $number -gt 494){throw 'В профиле указан неизвестный номер стратегии.'}
    $family=[string](Get-GuiObjectProperty $Profile 'AddressFamily' 'ipv4');$protocol=[string](Get-GuiObjectProperty $Profile 'Protocol' 'tls')
    if($family -notin @('ipv4','ipv6')){throw 'В профиле указано неизвестное IP-семейство.'}
    if($protocol -notin @('tls','quic')){throw 'В профиле указан неизвестный транспорт.'}
    if($protocol -eq 'quic' -and $number -notin @(493,494)){throw 'Для QUIC используются только профили 493 и 494.'}
    if($protocol -eq 'tls' -and $number -gt 492){throw 'TLS-профиль должен иметь номер от 1 до 492.'}
    $ports=ConvertTo-AntiDPIPortScope ([string](Get-GuiObjectProperty $Profile 'Ports' '443'))
    return [pscustomobject][ordered]@{Name=$name;ProfileNumber=$number;AddressFamily=$family;Protocol=$protocol;Ports=$ports;AdapterGuid=[string](Get-GuiObjectProperty $Profile 'AdapterGuid' '');AdapterName=[string](Get-GuiObjectProperty $Profile 'AdapterName' '')}
}
function Read-GuiConnectionProfiles {
    $loaded=[Collections.Generic.List[object]]::new()
    if(Test-Path -LiteralPath $script:connectionProfilesPath -PathType Leaf){
        try{$raw=Get-Content -LiteralPath $script:connectionProfilesPath -Raw -Encoding UTF8|ConvertFrom-Json;foreach($item in @($raw)){try{$loaded.Add((ConvertTo-GuiConnectionProfile $item))}catch{Write-GuiLog ('Skipping invalid saved connection profile: '+$_.Exception.Message)}}}catch{Write-GuiLog ('Could not read connection profiles: '+$_.Exception.Message)}
    }
    return @($loaded.ToArray())
}
function Save-GuiConnectionProfiles {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $script:connectionProfilesPath))|Out-Null
    $temporary=$script:connectionProfilesPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try{[IO.File]::WriteAllText($temporary,(@($script:connectionProfiles)|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false));if(Test-Path -LiteralPath $script:connectionProfilesPath -PathType Leaf){[IO.File]::Replace($temporary,$script:connectionProfilesPath,[NullString]::Value)}else{[IO.File]::Move($temporary,$script:connectionProfilesPath)}}finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue}}
}
function Update-GuiConnectionProfileItems {
    if($null -eq $script:profilesCombo){return}
    $script:profilesCombo.BeginUpdate();try{$script:profilesCombo.Items.Clear();foreach($item in @($script:connectionProfiles)){$null=$script:profilesCombo.Items.Add($item)};if($script:profilesCombo.Items.Count){$script:profilesCombo.SelectedIndex=0}}finally{$script:profilesCombo.EndUpdate()}
}
function Save-GuiConnectionProfile {
    $name=[string]$connectionProfileNameBox.Text.Trim()
    $selected=Get-GuiSelectedProfile
    $adapter=$adapterBox.SelectedItem
    if($null -eq $adapter){throw 'Выберите физический адаптер перед сохранением профиля подключения.'}
    $entry=ConvertTo-GuiConnectionProfile ([pscustomobject]@{Name=$name;ProfileNumber=$selected.Number;AddressFamily=$addressFamilyBox.SelectedItem.Value;Protocol=$protocolBox.SelectedItem.Value;Ports=$portsBox.Text;AdapterGuid=$(if($null -ne $adapter){$adapter.InterfaceGuid}else{''});AdapterName=$(if($null -ne $adapter){$adapter.Name}else{''})})
    if(@($script:connectionProfiles|Where-Object {$_.Name -ine $entry.Name}).Count -ge 100){throw 'Можно сохранить не более 100 профилей подключений.'};$script:connectionProfiles=@(@($script:connectionProfiles|Where-Object {$_.Name -ine $entry.Name})+@($entry)|Sort-Object Name)
    Save-GuiConnectionProfiles;Update-GuiConnectionProfileItems;$settingsStatusLabel.Text=('Профиль подключения «{0}» сохранён.' -f $entry.Name)
}
function Set-GuiConnectionControls($Profile) {
    $entry=ConvertTo-GuiConnectionProfile $Profile
    $addressFamilyBox.SelectedIndex=if($entry.AddressFamily -eq 'ipv6'){1}else{0}
    $protocolBox.SelectedIndex=if($entry.Protocol -eq 'quic'){1}else{0}
    $portsBox.Text=$entry.Ports
    Refresh-GuiAdapters
    if($entry.AdapterGuid){$adapterFound=$false;for($i=0;$i -lt $adapterBox.Items.Count;$i++){if([string]$adapterBox.Items[$i].InterfaceGuid -eq $entry.AdapterGuid){$adapterBox.SelectedIndex=$i;$adapterFound=$true;break}};if(-not $adapterFound){throw ('Сохранённый адаптер профиля «{0}» не подключён. Подключите его или выберите актуальный адаптер вручную; запуск не выполнялся.' -f $entry.AdapterName)}}
    if($favoritesCheck.Checked){$favoritesCheck.Checked=$false}
    $profileSearchBox.Text=[string]$entry.ProfileNumber;Update-GuiProfileFilter
    for($i=0;$i -lt $profileListBox.Items.Count;$i++){if([int]$profileListBox.Items[$i].Number -eq $entry.ProfileNumber){$profileListBox.SelectedIndex=$i;break}}
    $tabs.SelectedTab=$strategyTab
    return $entry
}
function Apply-GuiConnectionProfile {
    if($null -eq $script:profilesCombo.SelectedItem){throw 'Выберите сохранённый профиль подключения.'}
    $entry=Set-GuiConnectionControls $script:profilesCombo.SelectedItem
    Set-GuiStatus ('Применён профиль «{0}». Проверьте адаптер и нажмите «Проверить готовность» перед запуском.' -f $entry.Name) ([System.Drawing.Color]::DarkGreen)
}
function Remove-GuiConnectionProfile {
    if($null -eq $script:profilesCombo.SelectedItem){throw 'Выберите профиль подключения для удаления.'}
    $name=[string]$script:profilesCombo.SelectedItem.Name
    $script:connectionProfiles=@($script:connectionProfiles|Where-Object {$_.Name -ine $name});Save-GuiConnectionProfiles;Update-GuiConnectionProfileItems
}
function Export-GuiConfiguration {
    $dialog=New-Object System.Windows.Forms.SaveFileDialog;$dialog.Title='Экспорт настроек AntiDPI';$dialog.Filter='AntiDPI JSON (*.json)|*.json';$dialog.DefaultExt='json';$dialog.AddExtension=$true;$dialog.FileName=('AntiDPI_settings_'+(Get-Date -Format 'yyyyMMdd')+'.json')
    try{if($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK){return};Save-GuiSettings;$document=[ordered]@{Schema='antidpi.gui-backup.v1';CreatedUtc=[DateTime]::UtcNow.ToString('o');Settings=$script:guiSettings;ConnectionProfiles=@($script:connectionProfiles)};[IO.File]::WriteAllText($dialog.FileName,($document|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($true));$settingsStatusLabel.Text='Настройки и профили экспортированы.'}finally{$dialog.Dispose()}
}
function Import-GuiConfiguration {
    $dialog=New-Object System.Windows.Forms.OpenFileDialog;$dialog.Title='Импорт настроек AntiDPI';$dialog.Filter='AntiDPI JSON (*.json)|*.json|Все файлы (*.*)|*.*';$dialog.Multiselect=$false
    try{
        if($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK){return}
        $document=Get-Content -LiteralPath $dialog.FileName -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop
        if([string]$document.Schema -cne 'antidpi.gui-backup.v1'){throw 'Формат резервной копии не поддерживается.'}
        $candidate=$script:guiSettings.Clone()
        $settings=$document.Settings
        if([string]$settings.AddressFamily -notin @('ipv4','ipv6') -or [string]$settings.Protocol -notin @('tls','quic')){throw 'В резервной копии некорректны IP-семейство или транспорт.'}
        $candidate.AddressFamily=[string]$settings.AddressFamily;$candidate.Protocol=[string]$settings.Protocol;$candidate.Ports=ConvertTo-AntiDPIPortScope ([string]$settings.Ports)
        $range=[regex]::Match([string]$settings.AnalysisRange,'^([0-9]+)(?:\s*-\s*([0-9]+))?$');if(-not $range.Success){throw 'В резервной копии некорректен диапазон анализа.'};$first=[int]$range.Groups[1].Value;$last=if($range.Groups[2].Success){[int]$range.Groups[2].Value}else{$first};if($first -lt 1 -or $last -lt $first -or $last -gt 492){throw 'Диапазон анализа вне допустимого диапазона.'};$candidate.AnalysisRange=('{0}-{1}' -f $first,$last)
        $numericBounds=[ordered]@{AnalysisParallelism=@(1,5);AnalysisAttempts=@(1,5);AnalysisTimeoutSeconds=@(5,120);AnalysisThresholdKB=@(16,1024)};foreach($key in $numericBounds.Keys){$limits=$numericBounds[$key];$value=0;if(-not [int]::TryParse([string]$settings.$key,[ref]$value) -or $value -lt $limits[0] -or $value -gt $limits[1]){throw ('Некорректная настройка '+$key)};$candidate[$key]=$value}
        foreach($key in @('RememberAdapter','SkipTimestampSetup','ShowErrorDetails','MinimizeToTray')){if($settings.PSObject.Properties[$key]){$candidate[$key]=[bool]$settings.$key}}
        $candidate.Favorites=@($settings.Favorites|ForEach-Object {$n=0;if([int]::TryParse([string]$_,[ref]$n) -and $n -ge 1 -and $n -le 494){$n}}|Where-Object {$_}|Select-Object -Unique)
        $candidate.RecentProfiles=@($settings.RecentProfiles|ForEach-Object {$n=0;if([int]::TryParse([string]$_,[ref]$n) -and $n -ge 1 -and $n -le 494){$n}}|Where-Object {$_}|Select-Object -Unique|Select-Object -First 20)
        if($settings.PSObject.Properties['RecentProfileConfig'] -and $null -ne $settings.RecentProfileConfig){$candidate.RecentProfileConfig=ConvertTo-GuiConnectionProfile $settings.RecentProfileConfig}
        $newProfiles=[Collections.Generic.List[object]]::new();foreach($profile in @($document.ConnectionProfiles)){$newProfiles.Add((ConvertTo-GuiConnectionProfile $profile))};if($newProfiles.Count -gt 100){throw 'Слишком много профилей в резервной копии.'};if(@($newProfiles.ToArray()|Group-Object Name|Where-Object {$_.Count -gt 1}).Count){throw 'В резервной копии повторяются имена профилей подключений.'}
        if([System.Windows.Forms.MessageBox]::Show('Импорт заменит текущие настройки и сохранённые профили подключений. Продолжить?','Импорт настроек',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning) -ne [System.Windows.Forms.DialogResult]::Yes){return}
        $script:guiSettings=$candidate;$script:connectionProfiles=@($newProfiles.ToArray());Save-GuiConnectionProfiles
        $settingsFamilyBox.SelectedIndex=if($candidate.AddressFamily -eq 'ipv6'){1}else{0};$settingsProtocolBox.SelectedIndex=if($candidate.Protocol -eq 'quic'){1}else{0};$settingsPortsBox.Text=$candidate.Ports;$settingsAnalysisRangeBox.Text=$candidate.AnalysisRange;$settingsAnalysisParallelismBox.Value=[decimal]$candidate.AnalysisParallelism;$settingsAnalysisAttemptsBox.Value=[decimal]$candidate.AnalysisAttempts;$settingsAnalysisTimeoutBox.Value=[decimal]$candidate.AnalysisTimeoutSeconds;$settingsAnalysisThresholdBox.Value=[decimal]$candidate.AnalysisThresholdKB;$settingsRememberAdapterCheck.Checked=$candidate.RememberAdapter;$settingsSkipTimestampCheck.Checked=$candidate.SkipTimestampSetup;$settingsShowErrorDetailsCheck.Checked=$candidate.ShowErrorDetails;$trayMinimizeCheck.Checked=$candidate.MinimizeToTray
        Save-GuiSettings;Update-GuiConnectionProfileItems;Update-GuiProfileFilter;$settingsStatusLabel.Text='Импорт настроек завершён.'
    }finally{$dialog.Dispose()}
}
function Get-GuiReadiness {
    $rows=[Collections.Generic.List[object]]::new()
    try{$admin=Test-AntiDPIAdmin;if($admin){$rows.Add([pscustomobject]@{Level='OK';Check='Права';Details='Запущено с правами администратора.'})}else{$rows.Add([pscustomobject]@{Level='ERROR';Check='Права';Details='Запустите AntiDPI от имени администратора.'})}}catch{$rows.Add([pscustomobject]@{Level='ERROR';Check='Права';Details=$_.Exception.Message})}
    if(Test-Path -LiteralPath (Join-Path $bundle 'winws2.exe') -PathType Leaf){$rows.Add([pscustomobject]@{Level='OK';Check='Движок';Details='winws2.exe найден.'})}else{$rows.Add([pscustomobject]@{Level='ERROR';Check='Движок';Details='Не найден zapret-winws\winws2.exe.'})}
    if($null -eq $adapterBox.SelectedItem){$rows.Add([pscustomobject]@{Level='ERROR';Check='Адаптер';Details='Выберите активный физический адаптер.'})}else{
        $adapter=$adapterBox.SelectedItem;$family=if($null -ne $addressFamilyBox.SelectedItem){[string]$addressFamilyBox.SelectedItem.Value}else{'ipv4'};$net=Get-NetAdapter -InterfaceIndex ([int]$adapter.ifIndex) -ErrorAction SilentlyContinue|Select-Object -First 1
        if($null -eq $net -or $net.Status -ne 'Up'){$rows.Add([pscustomobject]@{Level='ERROR';Check='Адаптер';Details='Выбранный сетевой адаптер не находится в состоянии Up.'})}else{$rows.Add([pscustomobject]@{Level='OK';Check='Адаптер';Details=('Адаптер «{0}» активен.' -f $adapter.Name)})}
        $netFamily=if($family -eq 'ipv6'){'IPv6'}else{'IPv4'};$addresses=@(Get-NetIPAddress -InterfaceIndex ([int]$adapter.ifIndex) -AddressFamily $netFamily -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource -and $(if($family -eq 'ipv6'){$_.IPAddress -notmatch '^(fe80:|ff|::1$|::$)'}else{$_.IPAddress -notlike '169.254.*'})})
        if($addresses.Count){$rows.Add([pscustomobject]@{Level='OK';Check=$family.ToUpperInvariant();Details='На выбранном адаптере есть подходящий адрес.'})}else{$rows.Add([pscustomobject]@{Level='ERROR';Check=$family.ToUpperInvariant();Details=('На выбранном адаптере нет пригодного адреса '+$family+'.')})}
        $prefix=if($family -eq 'ipv6'){'::/0'}else{'0.0.0.0/0'};$netFamily=if($family -eq 'ipv6'){'IPv6'}else{'IPv4'};$routes=@(Get-NetRoute -AddressFamily $netFamily -DestinationPrefix $prefix -ErrorAction SilentlyContinue|Where-Object {$_.InterfaceIndex -eq [int]$adapter.ifIndex});if($routes.Count){$rows.Add([pscustomobject]@{Level='OK';Check='Маршрут';Details='Для адаптера найден маршрут по умолчанию.'})}else{$rows.Add([pscustomobject]@{Level='WARNING';Check='Маршрут';Details='На выбранном адаптере не найден маршрут по умолчанию.'})}
    }
    try{$profile=Get-GuiSelectedProfile;$rows.Add([pscustomobject]@{Level='OK';Check='Стратегия';Details=('№{0}: {1}' -f $profile.Number,$profile.Name)})}catch{$rows.Add([pscustomobject]@{Level='ERROR';Check='Стратегия';Details=$_.Exception.Message})}
    try{$scope=ConvertTo-AntiDPIPortScope $portsBox.Text;$rows.Add([pscustomobject]@{Level='OK';Check='Порты';Details=('Корректная область портов: '+$scope)})}catch{$rows.Add([pscustomobject]@{Level='ERROR';Check='Порты';Details=$_.Exception.Message})}
    $curlPath=Join-Path $env:SystemRoot 'System32\curl.exe';if(Test-Path -LiteralPath $curlPath -PathType Leaf){$curlFeatures=(& $curlPath --version 2>$null|Out-String);if($curlFeatures -match '(?im)^Features:.*\bHTTP3\b'){$rows.Add([pscustomobject]@{Level='OK';Check='HTTP/3';Details='Системный curl поддерживает реальный HTTP/3 тест.'})}else{$rows.Add([pscustomobject]@{Level='INFO';Check='HTTP/3';Details='Системный curl не поддерживает HTTP/3; HTTPS/TLS матрица останется доступна.'})}}else{$rows.Add([pscustomobject]@{Level='INFO';Check='HTTP/3';Details='curl.exe не найден; HTTP/3 матрица будет пропущена.'})}
    if($null -ne $script:worker -and -not $script:worker.HasExited){$rows.Add([pscustomobject]@{Level='WARNING';Check='Движок';Details='Управляемый процесс уже работает; второй запуск невозможен.'})}
    if($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited){$rows.Add([pscustomobject]@{Level='WARNING';Check='Анализ';Details='Идёт сетевой анализ; запуск стратегии невозможен.'})}
    return @($rows.ToArray())
}
function Show-GuiReadiness {
    $rows=@(Get-GuiReadiness);$text=foreach($row in $rows){'{0,-8} {1}: {2}' -f $row.Level,$row.Check,$row.Details};Show-GuiTextDialog 'Проверка готовности AntiDPI' ($text -join [Environment]::NewLine)
}
function Assert-GuiReadiness {
    $rows=@(Get-GuiReadiness);$errors=@($rows|Where-Object {$_.Level -eq 'ERROR'});$warnings=@($rows|Where-Object {$_.Level -eq 'WARNING'})
    if($errors.Count){Show-GuiTextDialog 'Исправьте проблемы перед запуском' ((@($rows|ForEach-Object {'{0,-8} {1}: {2}' -f $_.Level,$_.Check,$_.Details})) -join [Environment]::NewLine);throw 'Проверка готовности не пройдена; запуск не выполнялся.'}
    if($warnings.Count -and [System.Windows.Forms.MessageBox]::Show(($warnings.Details -join [Environment]::NewLine),'Предупреждение',[System.Windows.Forms.MessageBoxButtons]::OKCancel,[System.Windows.Forms.MessageBoxIcon]::Warning) -ne [System.Windows.Forms.DialogResult]::OK){throw 'Запуск отменён пользователем.'}
}
function New-GuiDiagnosticReport([switch]$IncludeLogs) {
    $lines=[Collections.Generic.List[string]]::new()
    $admin=Test-AntiDPIAdmin
    $lines.Add('AntiDPI — диагностический отчёт')
    $lines.Add(('Создан: '+(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')))
    $lines.Add(('Версия: '+$script:programVersion))
    $lines.Add(('Windows: '+[Environment]::OSVersion.VersionString))
    $lines.Add(('PowerShell: '+$PSVersionTable.PSVersion.ToString()))
    $lines.Add(('Администратор: '+[string]$admin))
    $lines.Add('')
    $lines.Add('Проверки готовности:')
    foreach($row in @(Get-GuiReadiness)){$lines.Add(('{0,-8} {1}: {2}' -f $row.Level,$row.Check,$row.Details))}
    $lines.Add('')
    $lines.Add('Параметры активного интерфейса (IP-адреса скрыты):')
    if($null -ne $addressFamilyBox.SelectedItem){$lines.Add(('IP-семейство: '+[string]$addressFamilyBox.SelectedItem.Label))}
    if($null -ne $protocolBox.SelectedItem){$lines.Add(('Транспорт: '+[string]$protocolBox.SelectedItem.Label))}
    $lines.Add(('Порты: '+[string]$portsBox.Text))
    if($null -ne $adapterBox.SelectedItem){$lines.Add(('Адаптер: '+[string]$adapterBox.SelectedItem.Name))}
    $lines.Add('')
    if($IncludeLogs){
        $lines.Add('Фрагменты последних журналов (пути и IP-адреса маскируются; проверьте перед отправкой):')
        $logs=Get-AntiDPILogDirectory $bundle
        $files=@(Get-ChildItem -LiteralPath $logs -File -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 3)
        foreach($file in $files){
            $lines.Add(('--- '+$file.Name+' ---'))
            foreach($line in @(Get-Content -LiteralPath $file.FullName -Tail 60 -Encoding UTF8 -ErrorAction SilentlyContinue)){
                $safe=[string]$line
                if($env:USERPROFILE){$safe=$safe.Replace([string]$env:USERPROFILE,'[USER]')}
                $safe=$safe -replace '(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])','[IP]'
                $safe=$safe -replace '(?i)(?<![0-9a-f:])(?:[0-9a-f]{0,4}:){3,7}[0-9a-f]{0,4}(?![0-9a-f:])','[IPv6]'
                $safe=$safe -replace [regex]::Escape($installRoot),'[INSTALL]'
                $lines.Add($safe)
            }
        }
    }
    return ($lines -join [Environment]::NewLine)
}
function Show-GuiDiagnosticReport {
    $dialog=[System.Windows.Forms.Form]::new();$dialog.Text='Диагностика — просмотр и экспорт';$dialog.StartPosition='CenterParent';$dialog.Size=[System.Drawing.Size]::new(820,620);$dialog.MinimumSize=[System.Drawing.Size]::new(620,440)
    $include=[System.Windows.Forms.CheckBox]::new();$include.Text='Включить последние журналы (IP и пути будут замаскированы)';$include.Location=[System.Drawing.Point]::new(12,12);$include.Size=[System.Drawing.Size]::new(760,28)
    $box=[System.Windows.Forms.TextBox]::new();$box.Multiline=$true;$box.ReadOnly=$true;$box.ScrollBars='Both';$box.WordWrap=$false;$box.Font=[System.Drawing.Font]::new('Consolas',9);$box.Location=[System.Drawing.Point]::new(12,48);$box.Size=[System.Drawing.Size]::new(780,470);$box.Anchor='Top,Bottom,Left,Right';$box.Text=New-GuiDiagnosticReport
    $buttons=[System.Windows.Forms.FlowLayoutPanel]::new();$buttons.Dock='Bottom';$buttons.Height=48;$buttons.FlowDirection='RightToLeft'
    $close=[System.Windows.Forms.Button]::new();$close.Text='Закрыть';$close.Width=100;$close.DialogResult='OK'
    $copy=[System.Windows.Forms.Button]::new();$copy.Text='Копировать';$copy.Width=110;$copy.Add_Click({[Windows.Forms.Clipboard]::SetText($box.Text)})
    $save=[System.Windows.Forms.Button]::new();$save.Text='Экспортировать…';$save.Width=140;$save.Add_Click({$saveDialog=New-Object System.Windows.Forms.SaveFileDialog;$saveDialog.Title='Экспорт диагностического отчёта';$saveDialog.Filter='Текстовый отчёт (*.txt)|*.txt';$saveDialog.DefaultExt='txt';$saveDialog.AddExtension=$true;$saveDialog.FileName=('AntiDPI_diagnostic_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.txt');try{if($saveDialog.ShowDialog($dialog) -eq [System.Windows.Forms.DialogResult]::OK){[IO.File]::WriteAllText($saveDialog.FileName,$box.Text,[Text.UTF8Encoding]::new($true));[System.Windows.Forms.MessageBox]::Show('Отчёт сохранён. Перед отправкой проверьте содержимое файла.','AntiDPI')|Out-Null}}finally{$saveDialog.Dispose()}})
    $include.Add_CheckedChanged({$box.Text=New-GuiDiagnosticReport -IncludeLogs:$include.Checked})
    $buttons.Controls.Add($close);$buttons.Controls.Add($copy);$buttons.Controls.Add($save);$dialog.Controls.AddRange([System.Windows.Forms.Control[]]@($include,$box,$buttons));$dialog.AcceptButton=$close;[void]$dialog.ShowDialog($form);$dialog.Dispose()
}
function Start-GuiReleaseCheck {
    if($null -ne $script:releaseCheckJob -and $script:releaseCheckJob.State -eq 'Running'){return}
    $sourceCommit=[string]$script:installedSourceCommit
    $script:releaseCheckJob=Start-Job -ArgumentList $sourceCommit -ScriptBlock {
        param([string]$InstalledCommit)
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $headers=@{ 'User-Agent'='AntiDPI-Windows-GUI';'Accept'='application/vnd.github+json' }
        $release=Invoke-RestMethod -Uri 'https://api.github.com/repos/Vidoc3000/anti-dpi-for-russia-TEST/releases/latest' -Headers $headers -TimeoutSec 15 -ErrorAction Stop
        $assets=@($release.assets|ForEach-Object {[pscustomobject]@{Name=[string]$_.name;Url=[string]$_.browser_download_url;Digest=[string]$_.digest;Size=[long]$_.size}})
        $escapedTag=[Uri]::EscapeDataString([string]$release.tag_name);$targetCommit='';$comparison=$null;$compareError=''
        try{$tagObject=Invoke-RestMethod -Uri ('https://api.github.com/repos/Vidoc3000/anti-dpi-for-russia-TEST/commits/'+$escapedTag) -Headers $headers -TimeoutSec 15 -ErrorAction Stop;if([string]$tagObject.sha -match '^[0-9a-f]{40}$'){$targetCommit=[string]$tagObject.sha}}catch{$compareError=$_.Exception.Message}
        if($InstalledCommit -match '^[0-9a-f]{40}$'){
            try{
                $compare=Invoke-RestMethod -Uri ('https://api.github.com/repos/Vidoc3000/anti-dpi-for-russia-TEST/compare/'+$InstalledCommit+'...'+$escapedTag) -Headers $headers -TimeoutSec 20 -ErrorAction Stop
                $changed=@($compare.files|Select-Object -First 40|ForEach-Object {$patch=[string]$_.patch;if($patch.Length -gt 1200){$patch=$patch.Substring(0,1200)+'… [patch сокращён]'};[pscustomobject]@{Name=[string]$_.filename;Status=[string]$_.status;Additions=[int]$_.additions;Deletions=[int]$_.deletions;Patch=$patch}})
                $comparison=[pscustomobject]@{Status=[string]$compare.status;AheadBy=[int]$compare.ahead_by;BehindBy=[int]$compare.behind_by;TotalCommits=[int]$compare.total_commits;TargetCommit=[string]$compare.head_commit.sha;Files=$changed;Url=('https://github.com/Vidoc3000/anti-dpi-for-russia-TEST/compare/'+$InstalledCommit+'...'+$escapedTag)}
            }catch{$compareError=$_.Exception.Message}
        }
        if(-not $targetCommit -and $comparison){$targetCommit=[string]$comparison.TargetCommit}
        [pscustomobject]@{Name=[string]$release.name;Tag=[string]$release.tag_name;TargetCommit=$targetCommit;Published=[string]$release.published_at;Url=[string]$release.html_url;Notes=[string]$release.body;Assets=$assets;InstalledCommit=$InstalledCommit;Comparison=$comparison;CompareError=$compareError}
    }
    Set-GuiStatus 'Проверяю релиз и изменения относительно установленной сборки. Проверка ничего не скачивает для установки.' ([System.Drawing.Color]::DarkOrange)
}
function Start-GuiAssetVerification($Asset) {
    if($null -ne $script:assetVerificationJob -and $script:assetVerificationJob.State -eq 'Running'){throw 'Проверка asset уже выполняется.'}
    if($null -eq $Asset -or [string]$Asset.Digest -notmatch '^sha256:([0-9a-fA-F]{64})$'){throw 'Для выбранного файла GitHub API не опубликовал SHA-256 digest.'}
    $uri=$null;if(-not [Uri]::TryCreate([string]$Asset.Url,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com'){throw 'Недоверенный URL asset; разрешены только HTTPS-ссылки GitHub Releases.'}
    $size=[long]$Asset.Size;if($size -lt 1 -or $size -gt 134217728){throw 'Проверка ограничена файлами размером до 128 МиБ.'}
    $expected=([string]$Asset.Digest).Substring(7).ToLowerInvariant()
    $script:assetVerificationJob=Start-Job -ArgumentList $uri.AbsoluteUri,$expected,$size -ScriptBlock {
        param([string]$Url,[string]$Expected,[long]$ExpectedSize)
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        $request=[Net.HttpWebRequest]::Create($Url);$request.UserAgent='AntiDPI-Windows-GUI';$request.Timeout=30000;$request.ReadWriteTimeout=30000;$request.AllowAutoRedirect=$true
        $response=$null;$stream=$null;$sha=[Security.Cryptography.SHA256]::Create()
        try{
            $response=$request.GetResponse();$finalUri=$response.ResponseUri
            if($finalUri.Scheme -ne 'https' -or $finalUri.Host -notin @('github.com','objects.githubusercontent.com','release-assets.githubusercontent.com','github-releases.githubusercontent.com')){throw 'Перенаправление скачивания ведёт на неожиданный домен.'}
            if($response.ContentLength -ge 0 -and [long]$response.ContentLength -ne $ExpectedSize){throw 'Размер ответа не совпал с метаданными GitHub.'}
            $stream=$response.GetResponseStream();$buffer=New-Object byte[] 65536;$total=[long]0
            while(($read=$stream.Read($buffer,0,$buffer.Length)) -gt 0){$total+=$read;if($total -gt 134217728 -or $total -gt $ExpectedSize){throw 'Размер загрузки превысил безопасный предел.'};$null=$sha.TransformBlock($buffer,0,$read,$buffer,0)}
            $null=$sha.TransformFinalBlock([byte[]]@(),0,0);$actual=([BitConverter]::ToString($sha.Hash)).Replace('-','').ToLowerInvariant()
            if($total -ne $ExpectedSize){throw ('Размер не совпал: ожидалось {0} байт, получено {1}.' -f $ExpectedSize,$total)}
            if($actual -cne $Expected){throw ('SHA-256 не совпал: GitHub объявил {0}, получено {1}.' -f $Expected,$actual)}
            [pscustomobject]@{Verified=$true;Name=[IO.Path]::GetFileName(([Uri]$Url).AbsolutePath);Size=$total;Sha256=$actual;Message='Размер и SHA-256 совпали с метаданными GitHub API. Файл не сохранён и не запускался.'}
        }finally{if($null -ne $stream){$stream.Dispose()};if($null -ne $response){$response.Dispose()};$sha.Dispose()}
    }
    Add-GuiHistory 'Проверка целостности' 'ЗАПУЩЕНА' ('Проверяется asset '+[string]$Asset.Name+'; файл не будет запускаться.')
}
function Show-GuiReleaseInfo($Release) {
    $lines=[Collections.Generic.List[string]]::new();$lines.Add(('Последний опубликованный релиз: {0} ({1})' -f $Release.Name,$Release.Tag));$lines.Add(('Опубликован: '+$Release.Published));$lines.Add(('Коммит релиза: '+[string]$Release.TargetCommit));$lines.Add(('Страница релиза: '+$Release.Url));$lines.Add('')
    $lines.Add('Примечания к выпуску:');$notes=[string]$Release.Notes;if($notes.Length -gt 8000){$notes=$notes.Substring(0,8000)+'… [текст сокращён]'};if($notes){$lines.Add($notes)}else{$lines.Add('Нет описания релиза.')}
    $lines.Add('');$lines.Add('Изменения кода относительно установленной сборки:')
    if($Release.Comparison){$lines.Add(('Состояние сравнения: {0}; коммитов вперёд: {1}; изменено файлов: до {2} показанных.' -f $Release.Comparison.Status,$Release.Comparison.AheadBy,@($Release.Comparison.Files).Count));foreach($file in @($Release.Comparison.Files)){$lines.Add(('--- {0} ({1}, +{2}/-{3})' -f $file.Name,$file.Status,$file.Additions,$file.Deletions));if($file.Patch){$patch=[string]$file.Patch;if($patch.Length -gt 800){$patch=$patch.Substring(0,800)+'…'};$lines.Add($patch)}};$lines.Add(('Полный diff: '+$Release.Comparison.Url))}
    elseif(-not $Release.InstalledCommit){$lines.Add('Для этой установки нет SourceCommit; точный diff не доступен. Установите пакет с BuildInfo.json.')}
    else{$lines.Add(('Не удалось получить diff через GitHub API: '+[string]$Release.CompareError))}
    $lines.Add('Diff — текстовое сравнение коммитов, это не аудит и не подпись кода.')
    $lines.Add('');$lines.Add('Файлы релиза:');foreach($asset in @($Release.Assets)){$line=('• {0} ({1} байт)' -f $asset.Name,$asset.Size);if($asset.Digest){$line+=' — '+$asset.Digest};$lines.Add($line);if($asset.Name -match '(?i)SHA256SUMS|checksums|checksum'){$lines.Add(('  Файл контрольных сумм: '+$asset.Url))}}
    $lines.Add('Выберите asset ниже, чтобы проверить скачанный поток по опубликованным GitHub API размеру и SHA-256. Это проверка целостности передачи, а не независимая криптографическая подпись.')
    $lines.Add('Штатный установщик отдельно проверяет SHA-256 закреплённого архива движка перед распаковкой.')
    $releaseDialog=[System.Windows.Forms.Form]::new();$releaseDialog.Text=('Релиз AntiDPI — '+[string]$Release.Tag);$releaseDialog.StartPosition='CenterParent';$releaseDialog.Size=[System.Drawing.Size]::new(820,690);$releaseDialog.MinimumSize=[System.Drawing.Size]::new(640,540)
    $box=[System.Windows.Forms.TextBox]::new();$box.Multiline=$true;$box.ReadOnly=$true;$box.ScrollBars='Vertical';$box.Location=[System.Drawing.Point]::new(12,12);$box.Size=[System.Drawing.Size]::new(780,470);$box.Anchor='Top,Bottom,Left,Right';$box.Text=$lines -join [Environment]::NewLine
    $assetLabel=[System.Windows.Forms.Label]::new();$assetLabel.Text='Проверить asset:';$assetLabel.Location=[System.Drawing.Point]::new(12,493);$assetLabel.Size=[System.Drawing.Size]::new(120,24);$assetLabel.Anchor='Bottom,Left'
    $assetBox=[System.Windows.Forms.ComboBox]::new();$assetBox.DropDownStyle='DropDownList';$assetBox.Location=[System.Drawing.Point]::new(132,489);$assetBox.Size=[System.Drawing.Size]::new(430,28);$assetBox.Anchor='Bottom,Left,Right';$assetBox.DisplayMember='Name'
    foreach($asset in @($Release.Assets)){$null=$assetBox.Items.Add($asset)};if($assetBox.Items.Count){$assetBox.SelectedIndex=0}
    $verifyButton=[System.Windows.Forms.Button]::new();$verifyButton.Text='Проверить SHA-256';$verifyButton.Location=[System.Drawing.Point]::new(570,487);$verifyButton.Size=[System.Drawing.Size]::new(220,32);$verifyButton.Anchor='Bottom,Right';$verifyButton.Enabled=($assetBox.Items.Count -gt 0)
    $assetBox.Add_SelectedIndexChanged({$selectedAsset=$assetBox.SelectedItem;$verifyButton.Enabled=($null -ne $selectedAsset -and [string]$selectedAsset.Digest -match '^sha256:[0-9a-fA-F]{64}$' -and [long]$selectedAsset.Size -gt 0 -and [long]$selectedAsset.Size -le 134217728)})
    $verifyButton.Add_Click({try{if($null -eq $assetBox.SelectedItem){throw 'Выберите файл релиза.'};Start-GuiAssetVerification $assetBox.SelectedItem;$verifyButton.Enabled=$false;$verifyButton.Text='Проверка в процессе…'}catch{Show-GuiError $_.Exception.Message}});if($null -ne $assetBox.SelectedItem){$verifyButton.Enabled=([string]$assetBox.SelectedItem.Digest -match '^sha256:[0-9a-fA-F]{64}$' -and [long]$assetBox.SelectedItem.Size -gt 0 -and [long]$assetBox.SelectedItem.Size -le 134217728)}
    $buttons=[System.Windows.Forms.FlowLayoutPanel]::new();$buttons.Dock='Bottom';$buttons.Height=48;$buttons.FlowDirection='RightToLeft'
    $close=[System.Windows.Forms.Button]::new();$close.Text='Закрыть';$close.Width=100;$close.DialogResult='OK'
    $update=[System.Windows.Forms.Button]::new();$update.Text='Открыть updater…';$update.Width=150;$update.Add_Click({$releaseDialog.Close();Start-GuiUpdateManager})
    $rollback=[System.Windows.Forms.Button]::new();$rollback.Text='Откатить обновление…';$rollback.Width=165;$rollback.Add_Click({$releaseDialog.Close();Start-GuiRollbackManager})
    $open=[System.Windows.Forms.Button]::new();$open.Text='Открыть страницу';$open.Width=140;$open.Add_Click({Start-Process ([string]$Release.Url)})
    $buttons.Controls.Add($close);$buttons.Controls.Add($update);$buttons.Controls.Add($rollback);$buttons.Controls.Add($open)
    $releaseDialog.Controls.AddRange([System.Windows.Forms.Control[]]@($box,$assetLabel,$assetBox,$verifyButton,$buttons));$releaseDialog.AcceptButton=$close;[void]$releaseDialog.ShowDialog($form);$releaseDialog.Dispose()
}

function Start-GuiUpdateManager {
    $manager=Join-Path (Split-Path -Parent $PSScriptRoot) 'AntiDPI_Manager.ps1'
    if(-not (Test-Path -LiteralPath $manager -PathType Leaf)){throw 'Не найден менеджер установки AntiDPI.'}
    $answer=[System.Windows.Forms.MessageBox]::Show('Откроется менеджер текущей установки. Он обновляет файлы из уже установленного пакета и сам не загружает выбранный GitHub-релиз. Для новой версии откройте страницу релиза, проверьте asset и запустите официальный установщик. Продолжить?','Обновление AntiDPI',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Information)
    if($answer -ne [System.Windows.Forms.DialogResult]::Yes){return}
    $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe';$managerArgs=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$manager,'-Action','Update','-InstallPath',$installRoot);$joined=(@($managerArgs|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
    Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Normal|Out-Null;Add-GuiHistory 'Обновление' 'ЗАПУЩЕНО' 'Открыт штатный менеджер обновлений.'
}
function Start-GuiRollbackManager {
    $manager=Join-Path (Split-Path -Parent $PSScriptRoot) 'AntiDPI_Manager.ps1'
    if(-not (Test-Path -LiteralPath $manager -PathType Leaf)){throw 'Не найден менеджер установки AntiDPI.'}
    $answer=[System.Windows.Forms.MessageBox]::Show('Штатный менеджер проверит резервную копию, версии файлов и SHA-256 перед откатом. Если установленные файлы были изменены вручную, операция будет отменена. Продолжить?','Откат обновления AntiDPI',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if($answer -ne [System.Windows.Forms.DialogResult]::Yes){return}
    $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe';$managerArgs=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$manager,'-Action','Rollback','-InstallPath',$installRoot);$joined=(@($managerArgs|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
    Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Normal|Out-Null;Add-GuiHistory 'Откат' 'ЗАПУЩЕНО' 'Открыт штатный менеджер отката; подтверждение выполняется отдельно в консоли.'
}
function Get-GuiSelectedNetworkSignature {
    if($null -eq $adapterBox.SelectedItem){return 'none'}
    $adapter=$adapterBox.SelectedItem;$family=[string]$addressFamilyBox.SelectedItem.Value;$net=Get-NetAdapter -InterfaceIndex ([int]$adapter.ifIndex) -ErrorAction SilentlyContinue|Select-Object -First 1
    $netFamily=if($family -eq 'ipv6'){'IPv6'}else{'IPv4'};$ips=@(Get-NetIPAddress -InterfaceIndex ([int]$adapter.ifIndex) -AddressFamily $netFamily -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource}|ForEach-Object {[string]$_.IPAddress}|Sort-Object)
    $prefix=if($family -eq 'ipv6'){'::/0'}else{'0.0.0.0/0'}
    $routes=@(Get-NetRoute -InterfaceIndex ([int]$adapter.ifIndex) -AddressFamily $netFamily -DestinationPrefix $prefix -ErrorAction SilentlyContinue|Sort-Object RouteMetric|Select-Object -First 3|ForEach-Object {('{0}:{1}' -f $_.NextHop,$_.RouteMetric)})
    $dns=@(Get-DnsClientServerAddress -InterfaceIndex ([int]$adapter.ifIndex) -AddressFamily $netFamily -ErrorAction SilentlyContinue|ForEach-Object {@($_.ServerAddresses)}|Where-Object {$_}|Sort-Object -Unique)
    return ('{0}|{1}|{2}|{3}|routes={4}|dns={5}' -f $adapter.InterfaceGuid,$net.Status,$family,($ips -join ','),($routes -join ','),($dns -join ','))
}
function Start-GuiConnectivityMatrix {
    if($null -ne $script:networkMatrixJob -and $script:networkMatrixJob.State -eq 'Running'){return}
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){throw 'Сначала безопасно остановите активную задачу: матрица должна измерять сеть без стратегии.'}
    if($null -eq $adapterBox.SelectedItem){throw 'Сначала выберите физический сетевой адаптер.'}
    if($null -eq $matrixTargetBox.SelectedItem){throw 'Выберите целевой сервис для проверки.'}
    $sources=@{}
    foreach($family in @('ipv4','ipv6')){
        $netFamily=if($family -eq 'ipv6'){'IPv6'}else{'IPv4'}
        $addresses=@(Get-NetIPAddress -InterfaceIndex ([int]$adapterBox.SelectedItem.ifIndex) -AddressFamily $netFamily -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource -and $(if($family -eq 'ipv6'){$_.IPAddress -notmatch '^(fe80:|ff|::1$|::$)'}else{$_.IPAddress -notlike '169.254.*'})}|Select-Object -First 1 -ExpandProperty IPAddress)
        if($addresses.Count){$sources[$family]=[string]$addresses[0]}
    }
    $target=$matrixTargetBox.SelectedItem
    $analysisStatusLabel.Text=('Проверяю '+[string]$target.Name+' по IPv4/IPv6; HTTPS/HTTP/3, до двух попыток…')
    $script:networkMatrixCancelPath=Join-Path $state ('network-matrix-cancel-'+[guid]::NewGuid().ToString('N')+'.flag')
    $script:networkMatrixJob=Start-Job -ArgumentList (,$sources),[string]$target.Name,[string]$target.Host,[string]$target.Path,[string]$script:networkMatrixCancelPath -ScriptBlock {
        param($Sources,[string]$TargetName,[string]$TargetHost,[string]$TargetPath,[string]$CancelPath)
        $ErrorActionPreference='Continue';$rows=[Collections.Generic.List[string]]::new();$attempts=2
        $rows.Add(('Цель: {0} — {1}{2}' -f $TargetName,$TargetHost,$TargetPath))
        $rows.Add('TCP/TLS проверка выполняет HTTPS GET и учитывает HTTP-код и время ответа; по две попытки.')
        foreach($family in @('ipv4','ipv6')){
            if(Test-Path -LiteralPath $CancelPath){$rows.Add('ПРОВЕРКА ОТМЕНЕНА пользователем.');break}
            if(-not $Sources.ContainsKey($family)){$rows.Add(('{0}: ПРОПУСК — на адаптере нет пригодного адреса.' -f $family.ToUpperInvariant()));continue}
            $source=[string]$Sources[$family];$addr=[Net.IPAddress]::Parse($source)
            $socketFamily=if($family -eq 'ipv6'){[Net.Sockets.AddressFamily]::InterNetworkV6}else{[Net.Sockets.AddressFamily]::InterNetwork}
            $dns=@([Net.Dns]::GetHostAddresses($TargetHost)|Where-Object {$_.AddressFamily -eq $socketFamily}|Select-Object -First 1)
            if(-not $dns.Count){$rows.Add(('{0} HTTPS: ОШИБКА DNS — нет адреса нужного семейства.' -f $family.ToUpperInvariant()));continue}
            $httpSuccess=0;$httpResponses=0;$httpTimes=[Collections.Generic.List[double]]::new();$httpDetails=[Collections.Generic.List[string]]::new()
            for($attempt=1;$attempt -le $attempts;$attempt++){
                if(Test-Path -LiteralPath $CancelPath){$rows.Add(('IPv{0} HTTPS: отменено пользователем.' -f $(if($family -eq 'ipv6'){6}else{4})));break}
                $watch=[Diagnostics.Stopwatch]::StartNew();$tcp=$null;$ssl=$null;$reader=$null;$writer=$null
                try{
                    $tcp=[Net.Sockets.TcpClient]::new($socketFamily);$tcp.ReceiveTimeout=6000;$tcp.SendTimeout=6000
                    $tcp.Client.Bind([Net.IPEndPoint]::new($addr,0));$pending=$tcp.BeginConnect($dns[0],443,$null,$null)
                    if(-not $pending.AsyncWaitHandle.WaitOne(5000)){$pending.AsyncWaitHandle.Dispose();throw 'TCP connect timeout (5 s)'}
                    $pending.AsyncWaitHandle.Dispose();$tcp.EndConnect($pending)
                    $ssl=[Net.Security.SslStream]::new($tcp.GetStream(),$false);$ssl.ReadTimeout=6000;$ssl.WriteTimeout=6000;$ssl.AuthenticateAsClient($TargetHost)
                    $writer=[IO.StreamWriter]::new($ssl,[Text.Encoding]::ASCII,1024,$true);$writer.NewLine="`r`n";$writer.Write(('GET {0} HTTP/1.1`r`nHost: {1}`r`nUser-Agent: AntiDPI-connectivity-check`r`nAccept: */*`r`nConnection: close`r`n`r`n' -f $TargetPath,$TargetHost));$writer.Flush()
                    $reader=[IO.StreamReader]::new($ssl,[Text.Encoding]::ASCII,$false,1024,$true);$statusLine=$reader.ReadLine();$watch.Stop()
                    if($statusLine -match '^HTTP/1\.[01]\s+([0-9]{3})'){$status=[int]$Matches[1];if($status -ge 100 -and $status -le 599){$httpResponses++};if($status -ge 200 -and $status -lt 400){$httpSuccess++;$httpTimes.Add($watch.Elapsed.TotalSeconds)};$httpDetails.Add(('попытка {0}: HTTP {1}{2}, {3:N2} с' -f $attempt,$status,$(if($status -ge 200 -and $status -lt 400){''}else{' (сервер ответил, код вне 2xx/3xx)'}),$watch.Elapsed.TotalSeconds))}else{$httpDetails.Add(('попытка {0}: неожиданный ответ сервера' -f $attempt))}
                }catch{$watch.Stop();$httpDetails.Add(('попытка {0}: ошибка — {1}' -f $attempt,$_.Exception.Message))}
                finally{if($null -ne $reader){$reader.Dispose()};if($null -ne $writer){$writer.Dispose()};if($null -ne $ssl){$ssl.Dispose()};if($null -ne $tcp){$tcp.Close()}}
            }
            if(Test-Path -LiteralPath $CancelPath){$rows.Add('Проверка отменена после завершения текущего HTTPS запроса.');return ($rows -join [Environment]::NewLine)}
            $httpMean=if($httpTimes.Count){($httpTimes|Measure-Object -Average).Average}else{$null}
            $httpStatus=if($httpSuccess -eq $attempts){'УСПЕХ'}elseif($httpSuccess -gt 0){'НЕСТАБИЛЬНО'}elseif($httpResponses -eq $attempts){'HTTP ОТВЕТ, КОД НЕ 2xx/3xx'}elseif($httpResponses -gt 0){'ЧАСТИЧНЫЙ HTTP ОТВЕТ'}else{'ОШИБКА'}
            $rows.Add(('{0} IPv{1} TCP/TLS + HTTPS: {2} ({3}/{4}); среднее успешных ответов: {5}; {6}' -f $TargetName,$(if($family -eq 'ipv6'){6}else{4}),$httpStatus,$httpSuccess,$attempts,$(if($null -ne $httpMean){'{0:N2} с' -f $httpMean}else{'нет'}),($httpDetails -join ' | ')))

            $curlPath=Join-Path $env:SystemRoot 'System32\curl.exe'
            if(-not (Test-Path -LiteralPath $curlPath -PathType Leaf)){$rows.Add(('{0} IPv{1} HTTP/3: НЕ ПРОВЕРЕНО — системный curl.exe не найден.' -f $TargetName,$(if($family -eq 'ipv6'){6}else{4})));continue}
            $curlVersion=(& $curlPath --version 2>$null|Out-String)
            if($curlVersion -notmatch '(?im)^Features:.*\bHTTP3\b'){$rows.Add(('{0} IPv{1} HTTP/3: НЕ ПРОВЕРЕНО — в установленном curl.exe нет поддержки HTTP/3.' -f $TargetName,$(if($family -eq 'ipv6'){6}else{4})));continue}
            $quicSuccess=0;$quicResponses=0;$quicTimes=[Collections.Generic.List[double]]::new();$quicDetails=[Collections.Generic.List[string]]::new();$ipSwitch=if($family -eq 'ipv6'){'--ipv6'}else{'--ipv4'}
            for($attempt=1;$attempt -le $attempts;$attempt++){
                if(Test-Path -LiteralPath $CancelPath){$rows.Add(('IPv{0} HTTP/3: отменено пользователем.' -f $(if($family -eq 'ipv6'){6}else{4})));break}
                $curlOutput=@(& $curlPath '--silent' '--show-error' '--http3-only' '--connect-timeout' '5' '--max-time' '12' '--interface' $source '--noproxy' '*' $ipSwitch '--output' 'NUL' '--write-out' '%{http_code}|%{time_total}|%{http_version}' ('https://'+$TargetHost+$TargetPath) 2>&1);$curlCode=$LASTEXITCODE;$last=[string]($curlOutput|Select-Object -Last 1)
                if($curlCode -eq 0 -and $last -match '^([0-9]{3})\|([0-9.]+)\|(.+)$'){$code=[int]$Matches[1];$seconds=[double]::Parse($Matches[2],[Globalization.CultureInfo]::InvariantCulture);$version=[string]$Matches[3];if($version -match '^3(?:\.|$)' -and $code -ge 100 -and $code -le 599){$quicResponses++};if($code -ge 200 -and $code -lt 400 -and $version -match '^3(?:\.|$)'){$quicSuccess++;$quicTimes.Add($seconds)};$quicDetails.Add(('попытка {0}: HTTP {1}, {2}{3}, {4:N2} с' -f $attempt,$code,$version,$(if($code -ge 200 -and $code -lt 400){''}else{' (HTTP/3 отвечает, код вне 2xx/3xx)'}),$seconds))}else{$quicDetails.Add(('попытка {0}: HTTP/3 не подтверждён — {1}' -f $attempt,($curlOutput -join ' ')))}
            }
            if(Test-Path -LiteralPath $CancelPath){$rows.Add('Проверка отменена после текущего HTTP/3 запроса.');return ($rows -join [Environment]::NewLine)}
            $quicMean=if($quicTimes.Count){($quicTimes|Measure-Object -Average).Average}else{$null};$quicStatus=if($quicSuccess -eq $attempts){'УСПЕХ'}elseif($quicSuccess -gt 0){'НЕСТАБИЛЬНО'}elseif($quicResponses -eq $attempts){'HTTP/3 ОТВЕТ, КОД НЕ 2xx/3xx'}elseif($quicResponses -gt 0){'ЧАСТИЧНЫЙ HTTP/3 ОТВЕТ'}else{'ОШИБКА'}
            $rows.Add(('{0} IPv{1} HTTP/3: {2} ({3}/{4}); среднее успешных ответов: {5}; {6}' -f $TargetName,$(if($family -eq 'ipv6'){6}else{4}),$quicStatus,$quicSuccess,$attempts,$(if($null -ne $quicMean){'{0:N2} с' -f $quicMean}else{'нет'}),($quicDetails -join ' | ')))
        }
        return ($rows -join [Environment]::NewLine)
    }
    $matrixButton.Enabled=$false;$matrixCancelButton.Enabled=$true
}
function Stop-GuiConnectivityMatrix {
    if($null -ne $script:networkMatrixJob -and $script:networkMatrixJob.State -eq 'Running'){try{[IO.File]::WriteAllText($script:networkMatrixCancelPath,'cancel',[Text.UTF8Encoding]::new($false))}catch{};$analysisStatusLabel.Text='Запрошена отмена; текущий запрос завершится по таймауту (максимум около 15 секунд).';$matrixCancelButton.Enabled=$false;Add-GuiHistory 'Матрица сети' 'ОТМЕНА ЗАПРОШЕНА' 'Дождитесь завершения текущего ограниченного по времени сетевого запроса.'}
}
function Start-GuiTorVerification {
    if($null -ne $script:tunnelCheckJob -and $script:tunnelCheckJob.State -eq 'Running'){throw 'Проверка VPN/Tor уже выполняется.'}
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){throw 'Для отдельной проверки Tor сначала безопасно остановите движок/анализ.'}
    $script:tunnelCheckJob=Start-Job -ScriptBlock {
        $curl=Join-Path $env:SystemRoot 'System32\curl.exe';if(-not (Test-Path -LiteralPath $curl)){return 'Tor: НЕ ПРОВЕРЕНО — curl.exe не найден.'}
        foreach($port in @(9050,9150)){
            $output=@(& $curl '--silent' '--show-error' '--socks5-hostname' ('127.0.0.1:'+ $port) '--connect-timeout' '4' '--max-time' '15' '--noproxy' '' '--output' '-' '--write-out' "`n%{http_code}|%{time_total}" 'https://check.torproject.org/api/ip' 2>&1);$code=$LASTEXITCODE
            if($code -eq 0 -and $output.Count -ge 2){$marker=[string]$output[-1];$body=($output[0..($output.Count-2)] -join "`n");$json=$null;try{$json=$body|ConvertFrom-Json -ErrorAction Stop}catch{};if($marker -match '^200\|([0-9.]+)$' -and $null -ne $json -and $json.IsTor -eq $true){return ('Tor через SOCKS5 localhost:{0}: ПОДТВЕРЖДЁН ответ check.torproject.org (IsTor=true), {1} с. Это проверяет Tor-маршрут отдельно от прямых HTTPS тестов.' -f $port,$Matches[1])};if($marker -match '^200\|' -and $null -ne $json -and $json.IsTor -eq $false){return ('SOCKS5 localhost:{0} ответил, но сервис сообщил IsTor=false; Tor не подтверждён.' -f $port)}}
        }
        return 'Tor: НЕ ПОДТВЕРЖДЁН — локальные SOCKS5 порты 9050/9150 не дали успешный IsTor=true. Проверьте, что Tor Browser/служба запущены. VPN этим тестом не проверяется.'
    }
    $analysisStatusLabel.Text='Проверяю Tor отдельно через локальный SOCKS5 и API check.torproject.org…'
}
function Start-GuiVpnVerification {
    if($null -ne $script:tunnelCheckJob -and $script:tunnelCheckJob.State -eq 'Running'){throw 'Проверка VPN/Tor уже выполняется.'}
    if(($null -ne $script:worker -and -not $script:worker.HasExited) -or ($null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited)){throw 'Для отдельной проверки VPN сначала безопасно остановите движок/анализ.'}
    $dialog=[System.Windows.Forms.Form]::new();$dialog.Text='Отдельная проверка VPN-маршрута';$dialog.Size=[System.Drawing.Size]::new(560,210);$dialog.StartPosition='CenterParent';$dialog.FormBorderStyle='FixedDialog';$dialog.MaximizeBox=$false
    $label=[System.Windows.Forms.Label]::new();$label.Text='Выберите активный VPN/TUN/TAP адаптер. Проверка привяжет HTTPS к его адресу и подтвердит маршрут; это не аудит утечки или политики VPN.';$label.Location=[System.Drawing.Point]::new(12,12);$label.Size=[System.Drawing.Size]::new(520,52);$dialog.Controls.Add($label)
    $combo=[System.Windows.Forms.ComboBox]::new();$combo.DropDownStyle='DropDownList';$combo.Location=[System.Drawing.Point]::new(12,72);$combo.Size=[System.Drawing.Size]::new(520,28);$combo.DisplayMember='Label';$dialog.Controls.Add($combo)
    foreach($adapter in @(Get-NetAdapter -ErrorAction Stop|Where-Object {$_.Status -eq 'Up'})){$families=@(Get-NetIPAddress -InterfaceIndex ([int]$adapter.ifIndex) -ErrorAction SilentlyContinue|Where-Object {$_.AddressState -eq 'Preferred' -and -not $_.SkipAsSource -and $_.IPAddress -notmatch '^(fe80:|ff|::1$|::$)' -and $_.IPAddress -notlike '169.254.*'});foreach($ip in $families){$row=[pscustomobject]@{Label=('{0} ({1}, ifIndex {2})' -f $adapter.Name,$ip.IPAddress,$adapter.ifIndex);Name=[string]$adapter.Name;IfIndex=[int]$adapter.ifIndex;Address=[string]$ip.IPAddress;Family=[string]$ip.AddressFamily};$null=$combo.Items.Add($row)}}
    if($combo.Items.Count){$combo.SelectedIndex=0}
    $ok=[System.Windows.Forms.Button]::new();$ok.Text='Проверить';$ok.Location=[System.Drawing.Point]::new(340,120);$ok.DialogResult='OK';$ok.Enabled=($combo.Items.Count -gt 0);$dialog.Controls.Add($ok);$cancel=[System.Windows.Forms.Button]::new();$cancel.Text='Отмена';$cancel.Location=[System.Drawing.Point]::new(430,120);$cancel.DialogResult='Cancel';$dialog.Controls.Add($cancel);$dialog.AcceptButton=$ok;$dialog.CancelButton=$cancel
    try{if($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK){return};$selected=$combo.SelectedItem;if($null -eq $selected){throw 'Нет активного адаптера с пригодным адресом.'};$index=[int]$selected.IfIndex;$address=[string]$selected.Address;$family=[string]$selected.Family;$networkFamily=if($family -eq 'IPv6'){'IPv6'}else{'IPv4'};$prefix=if($family -eq 'IPv6'){'::/0'}else{'0.0.0.0/0'};$route=@(Get-NetRoute -InterfaceIndex $index -AddressFamily $networkFamily -DestinationPrefix $prefix -ErrorAction SilentlyContinue|Select-Object -First 1);if(-not $route.Count){throw 'Для адаптера не найден маршрут по умолчанию; HTTP проверка не запускается.'};$script:tunnelCheckJob=Start-Job -ArgumentList $address,$family -ScriptBlock {param([string]$Source,[string]$AddressFamily);$curl=Join-Path $env:SystemRoot 'System32\curl.exe';if(-not (Test-Path -LiteralPath $curl)){return 'VPN-маршрут найден, но HTTPS тест не выполнен: curl.exe отсутствует.'};$ipSwitch=if($AddressFamily -eq 'IPv6'){'--ipv6'}else{'--ipv4'};$output=@(& $curl '--silent' '--show-error' '--connect-timeout' '5' '--max-time' '15' '--interface' $Source '--noproxy' '*' $ipSwitch '--output' 'NUL' '--write-out' '%{http_code}|%{time_total}' 'https://www.cloudflare.com/cdn-cgi/trace' 2>&1);$code=$LASTEXITCODE;$last=[string]($output|Select-Object -Last 1);if($code -eq 0 -and $last -match '^([0-9]{3})\|([0-9.]+)$' -and [int]$Matches[1] -ge 200 -and [int]$Matches[1] -lt 400){return ('VPN-маршрут + привязанный HTTPS: ОТВЕТ получен (HTTP {0}, {1} с). Тест отдельно от прямой матрицы; это подтверждает путь через выбранный интерфейс, но не скрытие IP, kill switch или политику VPN.' -f $Matches[1],$Matches[2])};return ('VPN-маршрут найден, но привязанный HTTPS не прошёл (код {0}; {1}). Причина может быть в DNS, firewall, сервере или туннеле.' -f $code,($output -join ' '))};$analysisStatusLabel.Text=('Проверяю HTTPS через выбранный интерфейс '+$selected.Name+'; тест отделён от прямой матрицы…') }finally{$dialog.Dispose()}
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
        Assert-GuiReadiness
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
        if(-not $CheckOnly){$script:guiSettings.RecentProfiles=@($selectedProfileNumber)+@($script:guiSettings.RecentProfiles|Where-Object {$_ -ne $selectedProfileNumber}|Select-Object -First 19);$script:guiSettings.RecentProfileConfig=[pscustomobject]@{Name='Последний использованный';ProfileNumber=$selectedProfileNumber;AddressFamily=$addressFamily;Protocol=$protocol;Ports=$scope;AdapterGuid=[string]$selectedAdapter.InterfaceGuid;AdapterName=[string]$selectedAdapter.Name};Save-GuiUiPreferences}
        $script:runningProfile=$selectedProfileNumber
$launchArguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$catalogue,'-ProfileNumber',[string]$selectedProfileNumber,'-InterfaceIndex',[string]$selectedAdapter.ifIndex,'-Scope',$scope,'-AddressFamily',$addressFamily,'-Protocol',$protocol,'-ZapretDirectory',$bundle,'-StateDirectory',$state)
        if($CheckOnly){$launchArguments+= '-Check'}
        if($script:guiSettings.SkipTimestampSetup){$launchArguments+= '-SkipTimestampSetup'}
        $joined=(@($launchArguments|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
        $script:worker=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $script:workerStartedUtc=[DateTime]::UtcNow;$script:workerHealthMissCount=0;$script:workerHealthWarningShown=$false
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
function Get-GuiVerifiedOwnedEngine {
    $record=Join-Path $state 'owned_process.json'
    if(-not (Test-Path -LiteralPath $record -PathType Leaf)){return $null}
    try{$owned=Get-Content -LiteralPath $record -Raw -Encoding UTF8|ConvertFrom-Json -ErrorAction Stop;$pidValue=0;if(-not [int]::TryParse([string]$owned.PID,[ref]$pidValue) -or $pidValue -le 0 -or [string]$owned.Exe -notmatch '(?i)\\winws2\.exe$' -or [string]$owned.StartUTC -notmatch '^\d{4}-'){return $null};$process=Get-Process -Id $pidValue -ErrorAction Stop;if($process.Path -ine [string]$owned.Exe -or $process.StartTime.ToUniversalTime().ToString('o') -cne [string]$owned.StartUTC){return $null};return [pscustomobject]@{PID=$pidValue;Exe=[string]$owned.Exe;StartUTC=[string]$owned.StartUTC}}catch{return $null}
}
function Show-GuiOrphanRecoveryPrompt {
    $owned=Get-GuiVerifiedOwnedEngine
    if($null -eq $owned){return}
    $script:orphanedOwnedEngine=$owned
    Add-GuiHistory 'Восстановление' 'НАЙДЕН ДВИЖОК' ('После перезапуска GUI найден подтверждённый принадлежащий AntiDPI winws2.exe PID '+$owned.PID)
    $answer=[System.Windows.Forms.MessageBox]::Show(('Найден принадлежащий AntiDPI движок (PID {0}), запущенный до текущего окна. Проверены PID, путь и время старта. GUI не будет завершать его принудительно. Запросить штатную остановку и восстановление состояния?' -f $owned.PID),'Восстановление после перезапуска',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if($answer -eq [System.Windows.Forms.DialogResult]::Yes){try{Initialize-AntiDPIRuntime;$null=[AntiDPI.Public10.WinDivertLifecycle]::RequestStop($bundle);$script:orphanRecoveryPending=$true;$script:orphanRecoveryStartedUtc=[DateTime]::UtcNow;$script:orphanRecoveryWarned=$false;Set-GuiStatus 'Запрошена штатная остановка найденного движка; отслеживаю восстановление.' ([System.Drawing.Color]::DarkOrange)}catch{Show-GuiError ('Не удалось запросить штатную остановку: '+$_.Exception.Message)}}
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
    $baselineAfter=Get-GuiObjectProperty $data 'BaselineAfter' $null
    if($null -ne $baselineAfter -and [int]$baselineAfter.Successes -gt 0){foreach($item in $results){if([string]$item.Status -eq 'PASS'){$item.Status='INCONCLUSIVE';$item.Details=('Control succeeded after the scan ({0}/{1}); strategy effect cannot be isolated.' -f [int]$baselineAfter.Successes,[int]$baselineAfter.Attempts)}}}
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
        if($null -ne $result.PSObject.Properties['MeanSuccessSeconds'] -and $null -ne $result.MeanSuccessSeconds){$recommendation+=(' · ср. {0:N2} с' -f [double]$result.MeanSuccessSeconds)}
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
    if($null -ne $baselineAfter){$baselineText+=('; контроль после серии: {0}/{1}' -f [int]$baselineAfter.Successes,[int]$baselineAfter.Attempts)}
    $when=if($data.CreatedUtc){([DateTime]::Parse([string]$data.CreatedUtc).ToLocalTime().ToString('g'))}else{'—'}
    $total=[int]$data.LastProfile-[int]$data.FirstProfile+1
    $current=0;if($data.PSObject.Properties['CurrentProfile']){$current=[int]$data.CurrentProfile}
    if($current -gt 0){$analysisStatusLabel.Text=('YouTube: {0}/{1}; сейчас №{2} | {3} | PASS: {4}; уже доступно: {5}; неоднозначно: {6}; нестабильно: {7}; FAIL: {8}; ошибки: {9}' -f $results.Count,$total,$current,$baselineText,$passed,$baselinePass,$inconclusive,$unstable,$failed,$errors)}
    else{$analysisStatusLabel.Text=('Результаты {0} | проверено: {1}/{2} | {3} | PASS: {4}; уже доступно: {5}; неоднозначно: {6}; нестабильно: {7}; FAIL: {8}; ошибки: {9}' -f $when,$results.Count,$total,$baselineText,$passed,$baselinePass,$inconclusive,$unstable,$failed,$errors)}
    if([string](Get-GuiObjectProperty $data 'Mode' 'standard') -eq 'sequential-bracketed'){$analysisStatusLabel.Text+=' | контроль до/после'}
    $leader=@($results|Where-Object {$_.Status -eq 'PASS'}|Sort-Object @{Expression='Successes';Descending=$true},@{Expression={if($null -ne $_.MeanSuccessSeconds){[double]$_.MeanSuccessSeconds}else{[double]::MaxValue}};Ascending=$true}|Select-Object -First 1)
    if($leader.Count){$analysisStatusLabel.Text+=(' | лучший кандидат по этим измерениям: №{0} ({1}/{2}, без гарантии для других сервисов)' -f [int]$leader[0].Number,[int]$leader[0].Successes,[int]$leader[0].ExpectedAttempts)}
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
        $benchmarkMode=[bool]$benchmarkModeCheck.Checked
        $parallelism=if($benchmarkMode){1}else{[int]$analysisParallelismBox.Value}
        $attempts=if($benchmarkMode){3}else{[int]$script:guiSettings.AnalysisAttempts}
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
        $analysisStatusLabel.Text=if($benchmarkMode){('Сравнительный режим: контроль до/после, стратегии по одной, 3 попытки ({0}-{1})…' -f $first,$last)}else{('Подготовка контрольного HTTPS-запроса; затем стратегии {0}-{1}, {2} параллельно…' -f $first,$last,$parallelism)}
        $stdout=Join-Path $logs ('analysis_'+$stamp+'.out.log')
        $stderr=Join-Path $logs ('analysis_'+$stamp+'.err.log')
        $script:analysisStdoutPath=$stdout;$script:analysisStderrPath=$stderr
        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$catalogue,'-Analyze','-FirstProfile',[string]$first,'-LastProfile',[string]$last,'-Parallelism',[string]$parallelism,'-AnalysisAttempts',[string]$attempts,'-AnalysisThresholdKB',[string]$thresholdKB,'-AnalysisTimeoutSeconds',[string]$timeoutSeconds,'-InterfaceIndex',[string]$selectedAdapter.ifIndex,'-Scope','443','-AddressFamily','ipv4','-Protocol','tls','-ZapretDirectory',$bundle,'-StateDirectory',$state,'-AnalysisResultPath',$script:analysisResultPath,'-AnalysisCancelFile',$script:analysisCancelFile)
        if($script:guiSettings.SkipTimestampSetup){$arguments+= '-SkipTimestampSetup'}
        if($benchmarkMode){$arguments+= '-BracketBaseline'}
        $joined=(@($arguments|ForEach-Object {ConvertTo-WindowsArgument ([string]$_)}) -join ' ')
        $script:analysisWorker=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        Add-GuiHistory 'Анализ YouTube' 'ЗАПУСК' ('Стратегии {0}-{1}; адаптер {2}; параллельность {3}' -f $first,$last,$selectedAdapter.Name,$parallelism)
        $analysisButton.Enabled=$false;$analysisCancelButton.Enabled=$true;$startButton.Enabled=$false;$settingsSaveButton.Enabled=$false
        $analysisRangeBox.Enabled=$false
        $analysisStatusLabel.Text=if($benchmarkMode){('Сравнение: контроль до и после; стратегии {0}-{1} последовательно; 3 попытки, таймаут {2} сек.' -f $first,$last,$timeoutSeconds)}else{('Контроль и YouTube IPv4/TCP/TLS: стратегии {0}-{1}; параллельно {2}, {3} попытки × {4} КиБ, таймаут {5} сек.' -f $first,$last,$parallelism,$attempts,$thresholdKB,$timeoutSeconds)}
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
    $settings=@{AddressFamily=$family;Protocol=$protocol;Ports=$ports;AnalysisRange=$rangeText;AnalysisParallelism=$parallelism;AnalysisAttempts=$attempts;AnalysisTimeoutSeconds=$timeoutSeconds;AnalysisThresholdKB=$thresholdKB;RememberAdapter=[bool]$settingsRememberAdapterCheck.Checked;SkipTimestampSetup=[bool]$settingsSkipTimestampCheck.Checked;ShowErrorDetails=[bool]$settingsShowErrorDetailsCheck.Checked;MinimizeToTray=[bool]$trayMinimizeCheck.Checked;Favorites=@($script:guiSettings.Favorites);RecentProfiles=@($script:guiSettings.RecentProfiles);RecentProfileConfig=$script:guiSettings.RecentProfileConfig;FirstRunComplete=$true;WindowBounds=$script:guiSettings.WindowBounds;WindowMaximized=$script:guiSettings.WindowMaximized}
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
    $script:guiSettings.MinimizeToTray=[bool]$trayMinimizeCheck.Checked
    $settingsStatusLabel.Text='Настройки сохранены и применены.'
}
function Load-GuiAnalysisHistory {
    $directory=Join-Path $state 'gui\analysis'
    $latest=Get-ChildItem -LiteralPath $directory -Filter 'analysis_*.json' -File -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 1
    if($latest){try{$null=Set-GuiAnalysisResults $latest.FullName}catch{Write-GuiLog ('Could not load analysis history: '+$_.Exception.Message)}}
}

$script:connectionProfiles=@(Read-GuiConnectionProfiles)
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
    $strategyTab.AutoScrollMinSize=[System.Drawing.Size]::new(740,680)
    $analysisTab.AutoScrollMinSize=[System.Drawing.Size]::new(740,700)
    $historyTab.AutoScrollMinSize=[System.Drawing.Size]::new(720,520)
    $settingsTab.AutoScrollMinSize=[System.Drawing.Size]::new(740,910)
    $aboutTab.AutoScrollMinSize=[System.Drawing.Size]::new(700,440)
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
    $analysisInfo.Text='Обычный анализ измеряет только YouTube IPv4/TCP/TLS. Сравнительный режим запускает стратегии по одной, делает 3 попытки и повторяет контроль после серии. Матрица ниже проверяет реальные HTTPS-ответы и HTTP/3 по IPv4/IPv6, если системный curl поддерживает HTTP/3. Это сетевые измерения, не гарантия обхода DPI.'
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
    $benchmarkModeCheck=New-Object System.Windows.Forms.CheckBox;$benchmarkModeCheck.Text='Сравнительный режим: последовательно, 3 повтора и контроль после серии';$benchmarkModeCheck.Location=[System.Drawing.Point]::new(22,158);$benchmarkModeCheck.Size=[System.Drawing.Size]::new(680,26);$benchmarkModeCheck.Checked=$false;$benchmarkModeCheck.Add_CheckedChanged({$analysisParallelismBox.Enabled=(-not $benchmarkModeCheck.Checked)});$analysisTab.Controls.Add($benchmarkModeCheck)
    $analysisGrid.Location=[System.Drawing.Point]::new(20,190);$analysisGrid.Size=[System.Drawing.Size]::new(690,340);$analysisGrid.Anchor='Top,Bottom,Left,Right'
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
    $matrixTargetLabel=New-Object System.Windows.Forms.Label;$matrixTargetLabel.Text='Сервис:';$matrixTargetLabel.Location=[System.Drawing.Point]::new(22,585);$matrixTargetLabel.Size=[System.Drawing.Size]::new(65,26);$analysisTab.Controls.Add($matrixTargetLabel)
    $matrixTargetBox=New-Object System.Windows.Forms.ComboBox;$matrixTargetBox.DropDownStyle='DropDownList';$matrixTargetBox.Location=[System.Drawing.Point]::new(88,582);$matrixTargetBox.Size=[System.Drawing.Size]::new(210,32)
    foreach($target in @([pscustomobject]@{Name='Веб — Google';Host='www.google.com';Path='/generate_204'},[pscustomobject]@{Name='Веб — Cloudflare';Host='cloudflare.com';Path='/cdn-cgi/trace'},[pscustomobject]@{Name='Видео — YouTube';Host='www.youtube.com';Path='/generate_204'},[pscustomobject]@{Name='Видео — Netflix';Host='www.netflix.com';Path='/'},[pscustomobject]@{Name='Видео — Twitch';Host='www.twitch.tv';Path='/'})){$null=$matrixTargetBox.Items.Add($target)};$matrixTargetBox.DisplayMember='Name';$matrixTargetBox.SelectedIndex=0;$analysisTab.Controls.Add($matrixTargetBox)
    $matrixButton=New-Object System.Windows.Forms.Button;$matrixButton.Text='Проверить HTTPS + HTTP/3';$matrixButton.Location=[System.Drawing.Point]::new(310,580);$matrixButton.Size=[System.Drawing.Size]::new(250,38);$matrixButton.Add_Click({try{if($null -eq $adapterBox.SelectedItem){throw 'Сначала выберите физический сетевой адаптер.'};Start-GuiConnectivityMatrix}catch{Show-GuiError $_.Exception.Message}});$analysisTab.Controls.Add($matrixButton)
    $matrixCancelButton=New-Object System.Windows.Forms.Button;$matrixCancelButton.Text='Отменить';$matrixCancelButton.Location=[System.Drawing.Point]::new(570,580);$matrixCancelButton.Size=[System.Drawing.Size]::new(120,38);$matrixCancelButton.Enabled=$false;$matrixCancelButton.Add_Click({Stop-GuiConnectivityMatrix});$analysisTab.Controls.Add($matrixCancelButton)
    $vpnTestButton=New-Object System.Windows.Forms.Button;$vpnTestButton.Text='VPN: отдельный тест';$vpnTestButton.Location=[System.Drawing.Point]::new(310,625);$vpnTestButton.Size=[System.Drawing.Size]::new(190,38);$vpnTestButton.Add_Click({try{Start-GuiVpnVerification}catch{Show-GuiError $_.Exception.Message}});$analysisTab.Controls.Add($vpnTestButton)
    $torTestButton=New-Object System.Windows.Forms.Button;$torTestButton.Text='Tor: SOCKS5 тест';$torTestButton.Location=[System.Drawing.Point]::new(510,625);$torTestButton.Size=[System.Drawing.Size]::new(190,38);$torTestButton.Add_Click({try{Start-GuiTorVerification}catch{Show-GuiError $_.Exception.Message}});$analysisTab.Controls.Add($torTestButton)

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
    $aboutUpdateButton=New-Object System.Windows.Forms.Button;$aboutUpdateButton.Text='Проверить релиз / изменения';$aboutUpdateButton.Location=[System.Drawing.Point]::new(30,330);$aboutUpdateButton.Size=[System.Drawing.Size]::new(310,40);$aboutUpdateButton.Add_Click({try{Start-GuiReleaseCheck}catch{Show-GuiError $_.Exception.Message}});$aboutTab.Controls.Add($aboutUpdateButton)
    $aboutReleaseButton.Text='Открыть страницу релизов';$aboutReleaseButton.Location=[System.Drawing.Point]::new(30,382);$aboutReleaseButton.Size=[System.Drawing.Size]::new(230,40)
    $aboutReleaseButton.Add_Click({try{Start-Process 'https://github.com/Vidoc3000/anti-dpi-for-russia-TEST/releases'}catch{Show-GuiError $_.Exception.Message}})
    $aboutTab.Controls.Add($aboutReleaseButton)
    $aboutRollbackButton=New-Object System.Windows.Forms.Button;$aboutRollbackButton.Text='Откатить обновление…';$aboutRollbackButton.Location=[System.Drawing.Point]::new(280,382);$aboutRollbackButton.Size=[System.Drawing.Size]::new(210,40);$aboutRollbackButton.Add_Click({try{Start-GuiRollbackManager}catch{Show-GuiError $_.Exception.Message}});$aboutTab.Controls.Add($aboutRollbackButton)

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
    $trayMinimizeCheck=New-Object System.Windows.Forms.CheckBox;$trayMinimizeCheck.Text='Сворачивать окно в системный трей';$trayMinimizeCheck.Checked=[bool]$script:guiSettings.MinimizeToTray;$trayMinimizeCheck.Location=[System.Drawing.Point]::new(28,514);$trayMinimizeCheck.Size=[System.Drawing.Size]::new(500,28);$settingsTab.Controls.Add($trayMinimizeCheck)
    $settingsSaveButton.Text='Сохранить настройки';$settingsSaveButton.Location=[System.Drawing.Point]::new(28,550);$settingsSaveButton.Size=[System.Drawing.Size]::new(210,40);$settingsSaveButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$settingsSaveButton.ForeColor=[System.Drawing.Color]::White
    $settingsTab.Controls.Add($settingsSaveButton)
    $interfacesButton=New-Object System.Windows.Forms.Button
    $interfacesButton.Text='Список всех интерфейсов';$interfacesButton.Location=[System.Drawing.Point]::new(250,550);$interfacesButton.Size=[System.Drawing.Size]::new(220,40)
    $interfacesButton.Add_Click({Show-GuiInterfaces});$settingsTab.Controls.Add($interfacesButton)
    $settingsStatusLabel=New-Object System.Windows.Forms.Label
    $settingsStatusLabel.Text='';$settingsStatusLabel.Location=[System.Drawing.Point]::new(28,600);$settingsStatusLabel.Size=[System.Drawing.Size]::new(650,32)
    $settingsTab.Controls.Add($settingsStatusLabel)
    $connectionTitle=New-Object System.Windows.Forms.Label;$connectionTitle.Text='Профили подключения: стратегия, IP-семейство, транспорт, адаптер и порты';$connectionTitle.Location=[System.Drawing.Point]::new(28,644);$connectionTitle.Size=[System.Drawing.Size]::new(680,24);$settingsTab.Controls.Add($connectionTitle)
    $script:profilesCombo=New-Object System.Windows.Forms.ComboBox;$script:profilesCombo.DropDownStyle='DropDownList';$script:profilesCombo.DisplayMember='Name';$script:profilesCombo.Location=[System.Drawing.Point]::new(28,672);$script:profilesCombo.Size=[System.Drawing.Size]::new(420,30);$settingsTab.Controls.Add($script:profilesCombo)
    $connectionProfileNameLabel=New-Object System.Windows.Forms.Label;$connectionProfileNameLabel.Text='Название';$connectionProfileNameLabel.Location=[System.Drawing.Point]::new(28,706);$connectionProfileNameLabel.Size=[System.Drawing.Size]::new(180,20);$settingsTab.Controls.Add($connectionProfileNameLabel)
    $connectionProfileNameBox=New-Object System.Windows.Forms.TextBox;$connectionProfileNameBox.Location=[System.Drawing.Point]::new(28,730);$connectionProfileNameBox.Size=[System.Drawing.Size]::new(260,30);$settingsTab.Controls.Add($connectionProfileNameBox)
    $profileSaveButton=New-Object System.Windows.Forms.Button;$profileSaveButton.Text='Сохранить текущий';$profileSaveButton.Location=[System.Drawing.Point]::new(300,728);$profileSaveButton.Size=[System.Drawing.Size]::new(170,34);$profileSaveButton.Add_Click({try{Save-GuiConnectionProfile}catch{Show-GuiError $_.Exception.Message}});$settingsTab.Controls.Add($profileSaveButton)
    $profileApplyButton=New-Object System.Windows.Forms.Button;$profileApplyButton.Text='Применить';$profileApplyButton.Location=[System.Drawing.Point]::new(28,770);$profileApplyButton.Size=[System.Drawing.Size]::new(130,34);$profileApplyButton.Add_Click({try{Apply-GuiConnectionProfile}catch{Show-GuiError $_.Exception.Message}});$settingsTab.Controls.Add($profileApplyButton)
    $profileDeleteButton=New-Object System.Windows.Forms.Button;$profileDeleteButton.Text='Удалить';$profileDeleteButton.Location=[System.Drawing.Point]::new(170,770);$profileDeleteButton.Size=[System.Drawing.Size]::new(120,34);$profileDeleteButton.Add_Click({try{Remove-GuiConnectionProfile}catch{Show-GuiError $_.Exception.Message}});$settingsTab.Controls.Add($profileDeleteButton)
    $configExportButton=New-Object System.Windows.Forms.Button;$configExportButton.Text='Экспортировать настройки…';$configExportButton.Location=[System.Drawing.Point]::new(28,815);$configExportButton.Size=[System.Drawing.Size]::new(250,38);$configExportButton.Add_Click({try{Export-GuiConfiguration}catch{Show-GuiError $_.Exception.Message}});$settingsTab.Controls.Add($configExportButton)
    $configImportButton=New-Object System.Windows.Forms.Button;$configImportButton.Text='Импортировать настройки…';$configImportButton.Location=[System.Drawing.Point]::new(292,815);$configImportButton.Size=[System.Drawing.Size]::new(250,38);$configImportButton.Add_Click({try{Import-GuiConfiguration}catch{Show-GuiError $_.Exception.Message}});$settingsTab.Controls.Add($configImportButton)
    $readinessButton=New-Object System.Windows.Forms.Button;$readinessButton.Text='Проверить готовность';$readinessButton.Location=[System.Drawing.Point]::new(28,860);$readinessButton.Size=[System.Drawing.Size]::new(210,38);$readinessButton.Add_Click({Show-GuiReadiness});$settingsTab.Controls.Add($readinessButton)
    $diagnosticButton=New-Object System.Windows.Forms.Button;$diagnosticButton.Text='Диагностический отчёт…';$diagnosticButton.Location=[System.Drawing.Point]::new(252,860);$diagnosticButton.Size=[System.Drawing.Size]::new(230,38);$diagnosticButton.Add_Click({Show-GuiDiagnosticReport});$settingsTab.Controls.Add($diagnosticButton)
    Update-GuiConnectionProfileItems
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
    $trayMenu=New-Object System.Windows.Forms.ContextMenuStrip
    $trayOpen=$trayMenu.Items.Add('Открыть AntiDPI');$trayOpen.Add_Click({$form.Show();$form.WindowState='Normal';$form.Activate()})
    $trayRunRecent=$trayMenu.Items.Add('Запустить последний профиль');$trayRunRecent.Add_Click({try{$recent=$script:guiSettings.RecentProfileConfig;if($null -eq $recent -and @($script:guiSettings.RecentProfiles).Count){$recent=[pscustomobject]@{Name='Последний использованный';ProfileNumber=[int]$script:guiSettings.RecentProfiles[0];AddressFamily=[string]$addressFamilyBox.SelectedItem.Value;Protocol=[string]$protocolBox.SelectedItem.Value;Ports=[string]$portsBox.Text;AdapterGuid='';AdapterName=''}};if($null -eq $recent){throw 'Нет ранее использованного профиля.'};$null=Set-GuiConnectionControls $recent;$form.Show();$form.WindowState='Normal';Start-GuiStrategy}catch{Show-GuiError $_.Exception.Message}})
    $trayStop=$trayMenu.Items.Add('Безопасно остановить');$trayStop.Add_Click({Request-GuiStop})
    $trayMenu.Items.Add('-')|Out-Null;$trayExit=$trayMenu.Items.Add('Закрыть');$trayExit.Add_Click({$form.Close()})
    $script:trayIcon=New-Object System.Windows.Forms.NotifyIcon;$script:trayIcon.Icon=[System.Drawing.SystemIcons]::Application;$script:trayIcon.Text='AntiDPI — готово';$script:trayIcon.ContextMenuStrip=$trayMenu;$script:trayIcon.Visible=$true
    $script:trayIcon.Add_DoubleClick({$form.Show();$form.WindowState='Normal';$form.Activate()})
    $form.Add_Resize({if($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized -and $script:guiSettings.MinimizeToTray){$form.Hide();$script:trayIcon.ShowBalloonTip(1200,'AntiDPI','Окно скрыто в системный трей. Перехват продолжает работать до безопасной остановки.','Info')}})
    $script:networkSignature=Get-GuiSelectedNetworkSignature
    $networkTimer=New-Object System.Windows.Forms.Timer;$networkTimer.Interval=4000;$networkTimer.Add_Tick({
        $strategyActive=$null -ne $script:worker -and -not $script:worker.HasExited
        $analysisActive=$null -ne $script:analysisWorker -and -not $script:analysisWorker.HasExited
        if($strategyActive -or $analysisActive){
            try{
                $signature=Get-GuiSelectedNetworkSignature
                if(-not $script:networkSignature){$script:networkSignature=$signature;$script:networkCandidateSignature='';$script:networkCandidateCount=0}
                elseif($signature -ceq $script:networkSignature){$script:networkCandidateSignature='';$script:networkCandidateCount=0}
                else{
                    if($signature -ceq $script:networkCandidateSignature){$script:networkCandidateCount++}else{$script:networkCandidateSignature=$signature;$script:networkCandidateCount=1}
                    if($script:networkCandidateCount -ge 2){
                        $script:networkSignature=$signature;$script:networkCandidateSignature='';$script:networkCandidateCount=0
                        Set-GuiStatus 'Сетевые параметры изменились и стабильно держатся 8 секунд.' ([System.Drawing.Color]::DarkOrange)
                        $adapterGuid=if($null -ne $adapterBox.SelectedItem){[string]$adapterBox.SelectedItem.InterfaceGuid}else{''};$matching=@($script:connectionProfiles|Where-Object {$adapterGuid -and [string]$_.AdapterGuid -eq $adapterGuid}|ForEach-Object {$_.Name})
                        $extra=if($matching.Count){[Environment]::NewLine+'Профили для этого адаптера: '+($matching -join ', ')+'. После остановки задачу можно безопасно переключить на нужный профиль.'}else{[Environment]::NewLine+'После остановки можно вручную применить сохранённый профиль сети.'}
                        $answer=[System.Windows.Forms.MessageBox]::Show(('Изменились адаптер, адрес, маршрут или DNS во время задачи.'+$extra+[Environment]::NewLine+[Environment]::NewLine+'Безопасно остановить текущую задачу?'),'Смена сети',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
                        if($answer -eq [System.Windows.Forms.DialogResult]::Yes){if($strategyActive){Request-GuiStop};if($analysisActive){Request-GuiAnalysisCancel}}
                    }
                }
            }catch{Write-GuiLog ('Network change monitor: '+$_.Exception.Message)}
        }else{try{$script:networkSignature=Get-GuiSelectedNetworkSignature;$script:networkCandidateSignature='';$script:networkCandidateCount=0}catch{}}
    })
    $timer.Add_Tick({
        if($script:orphanRecoveryPending){
            $stillOwned=Get-GuiVerifiedOwnedEngine
            if($null -eq $stillOwned){$script:orphanRecoveryPending=$false;$script:orphanedOwnedEngine=$null;Set-GuiStatus 'Штатная остановка движка после перезапуска GUI подтверждена.' ([System.Drawing.Color]::DarkGreen);Add-GuiHistory 'Восстановление' 'ГОТОВО' 'Подтверждённый движок завершился; GUI не применял принудительное завершение.'}
            elseif(-not $script:orphanRecoveryWarned -and ([DateTime]::UtcNow-$script:orphanRecoveryStartedUtc).TotalSeconds -ge 30){$script:orphanRecoveryWarned=$true;Set-GuiStatus 'Движок ещё работает; принудительно не завершён. Повторно проверьте службу/состояние.' ([System.Drawing.Color]::DarkOrange);Add-GuiHistory 'Восстановление' 'ОЖИДАНИЕ' 'Штатный запрос остановки отправлен, но подтверждённый PID всё ещё активен.';[System.Windows.Forms.MessageBox]::Show('Движок пока не завершился после штатного запроса. AntiDPI не будет принудительно убивать процесс. Проверьте системную службу/драйвер и используйте безопасную остановку повторно.','Восстановление после перезапуска',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)|Out-Null}
        }
        if($null -ne $script:worker -and $script:worker.HasExited){
            $code=$script:worker.ExitCode
            $script:worker.Dispose();$script:worker=$null
            $script:workerHealthMissCount=0;$script:workerHealthWarningShown=$false
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
        }elseif($null -ne $script:worker -and $script:workerMode -eq 'start'){
            $ownedRecord=Join-Path $state 'owned_process.json';$engineHealthy=$false
            if(Test-Path -LiteralPath $ownedRecord){
                try{$owned=Get-Content -LiteralPath $ownedRecord -Raw|ConvertFrom-Json;$engine=Get-Process -Id ([int]$owned.PID) -ErrorAction Stop;if($engine.Path -ieq [string]$owned.Exe -and $engine.StartTime.ToUniversalTime().ToString('o') -ceq [string]$owned.StartUTC){$engineHealthy=$true;Set-GuiStatus ('Работает стратегия {0} на выбранном адаптере.' -f [int]$script:runningProfile) ([System.Drawing.Color]::DarkGreen)}}catch{}
            }
            if($engineHealthy){$script:workerHealthMissCount=0;$script:workerHealthWarningShown=$false}
            elseif(([DateTime]::UtcNow-$script:workerStartedUtc).TotalSeconds -ge 15){
                $script:workerHealthMissCount++
                if($script:workerHealthMissCount -ge 3 -and -not $script:workerHealthWarningShown){
                    $script:workerHealthWarningShown=$true;Set-GuiStatus 'Не удалось подтвердить состояние принадлежащего AntiDPI движка.' ([System.Drawing.Color]::DarkOrange);Add-GuiHistory 'Надёжность' 'ПРЕДУПРЕЖДЕНИЕ' 'Рабочий процесс жив, но маркер движка отсутствует или не подтверждается.'
                    $answer=[System.Windows.Forms.MessageBox]::Show('Рабочий процесс GUI ещё работает, но три проверки подряд не подтвердили PID, путь и время старта движка. Не завершая посторонние процессы, запросить штатную безопасную остановку?','Проверка состояния движка',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
                    if($answer -eq [System.Windows.Forms.DialogResult]::Yes){Request-GuiStop}
                }
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
        if($null -ne $script:releaseCheckJob -and $script:releaseCheckJob.State -in @('Completed','Failed','Stopped')){try{$release=Receive-Job -Job $script:releaseCheckJob -ErrorAction Stop|Select-Object -Last 1;if($null -eq $release -or -not $release.Tag){throw 'GitHub API не вернул сведения о релизе.'};Show-GuiReleaseInfo $release}catch{[System.Windows.Forms.MessageBox]::Show(('Не удалось проверить релизы онлайн: '+$_.Exception.Message+[Environment]::NewLine+'Можно открыть страницу релизов вручную.'),'Проверка обновлений',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)|Out-Null;try{Start-Process 'https://github.com/Vidoc3000/anti-dpi-for-russia-TEST/releases'}catch{}}finally{Remove-Job -Job $script:releaseCheckJob -Force -ErrorAction SilentlyContinue;$script:releaseCheckJob=$null}}
        if($null -ne $script:tunnelCheckJob -and $script:tunnelCheckJob.State -in @('Completed','Failed','Stopped')){try{$tunnelResult=(Receive-Job -Job $script:tunnelCheckJob -ErrorAction SilentlyContinue|Out-String).Trim();if(-not $tunnelResult){$tunnelResult='Проверка VPN/Tor не вернула данных.'};$analysisStatusLabel.Text='Проверка VPN/Tor завершена.';Add-GuiHistory 'Проверка VPN/Tor' 'ЗАВЕРШЕНА' $tunnelResult;Show-GuiTextDialog 'Отдельный результат VPN/Tor' $tunnelResult}catch{Show-GuiError $_.Exception.Message}finally{Remove-Job -Job $script:tunnelCheckJob -Force -ErrorAction SilentlyContinue;$script:tunnelCheckJob=$null}}
        if($null -ne $script:assetVerificationJob -and $script:assetVerificationJob.State -in @('Completed','Failed','Stopped')){try{$verification=Receive-Job -Job $script:assetVerificationJob -ErrorAction Stop|Select-Object -Last 1;if($null -eq $verification -or -not $verification.Verified){throw 'Asset не прошёл проверку SHA-256.'};Add-GuiHistory 'Проверка целостности' 'УСПЕХ' ([string]$verification.Name+' — SHA-256 совпал с GitHub API');[System.Windows.Forms.MessageBox]::Show(($verification.Message+[Environment]::NewLine+[Environment]::NewLine+'SHA-256: '+$verification.Sha256),'Проверка целостности',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null}catch{Add-GuiHistory 'Проверка целостности' 'ОШИБКА' $_.Exception.Message;[System.Windows.Forms.MessageBox]::Show(('Проверка asset не прошла: '+$_.Exception.Message),'Проверка целостности',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)|Out-Null}finally{Remove-Job -Job $script:assetVerificationJob -Force -ErrorAction SilentlyContinue;$script:assetVerificationJob=$null}}
        if($null -ne $script:networkMatrixJob -and $script:networkMatrixJob.State -in @('Completed','Failed','Stopped')){$matrixState=[string]$script:networkMatrixJob.State;try{$matrixText=(Receive-Job -Job $script:networkMatrixJob -ErrorAction SilentlyContinue|Out-String).Trim();$matrixButton.Enabled=$true;$matrixCancelButton.Enabled=$false;if(-not $matrixText){$matrixText='Проверка матрицы не вернула данных.'};if($matrixState -eq 'Completed' -and -not (Test-Path -LiteralPath $script:networkMatrixCancelPath)){Add-GuiHistory 'Матрица сети' 'ЗАВЕРШЕНА' 'Базовые HTTPS и HTTP/3 проверки для выбранного сервиса; без стратегии.'}else{Add-GuiHistory 'Матрица сети' 'ОТМЕНЕНА' 'Проверка завершила текущий запрос после запроса отмены.'};Show-GuiTextDialog 'Базовая матрица доступности сети' ($matrixText+[Environment]::NewLine+[Environment]::NewLine+'Это базовая проверка без стратегии. HTTPS выполняет реальный TLS/HTTP запрос; HTTP/3 считается успешным только при завершённом запросе с HTTP-версией 3.0. Если curl без поддержки HTTP/3, тест явно помечается как не выполненный. Успех не доказывает обход DPI, а отказ не доказывает блокировку: возможны DNS, маршрут, сервер или локальный firewall.')}catch{$matrixButton.Enabled=$true;$matrixCancelButton.Enabled=$false;Show-GuiError $_.Exception.Message}finally{Remove-Job -Job $script:networkMatrixJob -Force -ErrorAction SilentlyContinue;if($script:networkMatrixCancelPath -and (Test-Path -LiteralPath $script:networkMatrixCancelPath)){Remove-Item -LiteralPath $script:networkMatrixCancelPath -Force -ErrorAction SilentlyContinue};$script:networkMatrixCancelPath='';$script:networkMatrixJob=$null}}
        if($script:closeWhenStopped -and $null -eq $script:worker -and $null -eq $script:analysisWorker){$form.Close()}
    })
    $timer.Start();$networkTimer.Start()
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
    $form.Add_FormClosing({if($null -ne $script:networkMatrixJob -and $script:networkMatrixJob.State -eq 'Running'){$_.Cancel=$true;Stop-GuiConnectivityMatrix};if($null -ne $script:tunnelCheckJob -and $script:tunnelCheckJob.State -eq 'Running'){$_.Cancel=$true;Set-GuiStatus 'Дождитесь окончания VPN/Tor проверки (ограниченной таймаутом), чтобы не оставить curl-процесс.' ([System.Drawing.Color]::DarkOrange)}})
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
    $form.Add_FormClosed({$timer.Stop();$timer.Dispose();$networkTimer.Stop();$networkTimer.Dispose();if($null -ne $script:trayIcon){$script:trayIcon.Visible=$false;$script:trayIcon.Dispose();$script:trayIcon=$null};if($null -ne $script:networkMatrixJob){Stop-Job -Job $script:networkMatrixJob -ErrorAction SilentlyContinue;Remove-Job -Job $script:networkMatrixJob -Force -ErrorAction SilentlyContinue};if($null -ne $script:tunnelCheckJob){Stop-Job -Job $script:tunnelCheckJob -ErrorAction SilentlyContinue;Remove-Job -Job $script:tunnelCheckJob -Force -ErrorAction SilentlyContinue};if($null -ne $script:releaseCheckJob){Stop-Job -Job $script:releaseCheckJob -ErrorAction SilentlyContinue;Remove-Job -Job $script:releaseCheckJob -Force -ErrorAction SilentlyContinue};if($null -ne $script:assetVerificationJob){Stop-Job -Job $script:assetVerificationJob -ErrorAction SilentlyContinue;Remove-Job -Job $script:assetVerificationJob -Force -ErrorAction SilentlyContinue}})
    Write-GuiLog 'Showing main form'
    $form.Add_Shown({Show-GuiOrphanRecoveryPrompt})
    [void]$form.ShowDialog()
    Write-GuiLog 'Main form closed normally'
}catch{Write-GuiLog ('FATAL: '+$_.Exception.ToString());Show-GuiError $_.Exception.Message}
finally{if($null -ne $script:worker){$script:worker.Dispose()};if($null -ne $script:analysisWorker){$script:analysisWorker.Dispose()}}
