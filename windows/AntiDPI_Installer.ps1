#requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function ConvertTo-InstallerArgument([string]$Value) {
    if($Value.Length -and $Value -notmatch '[\s"]'){return $Value}
    return '"'+[regex]::Replace([regex]::Replace($Value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')+'"'
}
function Show-InstallerError([string]$Message) {
    [System.Windows.Forms.MessageBox]::Show($Message,'AntiDPI — установка',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)|Out-Null
}

$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    try{
        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments=@('-NoLogo','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',$PSCommandPath)
        $joined=(@($arguments|ForEach-Object {ConvertTo-InstallerArgument ([string]$_)}) -join ' ')
        $null=Start-Process -FilePath $powershell -ArgumentList $joined -Verb RunAs
    }catch{Show-InstallerError ('Для установки нужны права администратора. '+$_.Exception.Message)}
    exit
}

$script:installProcess=$null
$script:stdoutPath=''
$script:stderrPath=''
$script:cancelFile=''
$script:lastLog=''
$script:installedPath=''
function Test-InstallerExistingInstall([string]$Path) {
    try{
        $root=[IO.Path]::GetFullPath(([string]$Path).Trim())
        $marker=Join-Path $root '.antidpi-install.json'
        if(-not (Test-Path -LiteralPath $marker -PathType Leaf)){return $false}
        $data=Get-Content -LiteralPath $marker -Raw -Encoding UTF8|ConvertFrom-Json
        return ($data.Schema -eq 'antidpi.zapret.install.v1' -and [IO.Path]::GetFullPath([string]$data.InstallRoot) -ieq $root -and (Test-Path -LiteralPath (Join-Path $root 'AntiDPI\AntiDPI_Manager.ps1') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $root 'zapret-winws\winws2.exe') -PathType Leaf))
    }catch{return $false}
}
$manager=Join-Path $PSScriptRoot 'AntiDPI_Manager.ps1'
if(-not (Test-Path -LiteralPath $manager -PathType Leaf)){Show-InstallerError 'Не найден AntiDPI_Manager.ps1 рядом с установщиком.';exit 1}

$form=New-Object System.Windows.Forms.Form
$form.Text='AntiDPI — мастер установки'
$form.StartPosition='CenterScreen'
$form.ClientSize=[System.Drawing.Size]::new(720,650)
$form.MinimumSize=[System.Drawing.Size]::new(660,690)
$form.Font=[System.Drawing.Font]::new('Segoe UI',10)
$form.BackColor=[System.Drawing.Color]::FromArgb(247,249,252)
$form.AutoScaleMode=[System.Windows.Forms.AutoScaleMode]::Dpi

$title=New-Object System.Windows.Forms.Label
$title.Text='Установка AntiDPI'
$title.Font=[System.Drawing.Font]::new('Segoe UI Semibold',22,[System.Drawing.FontStyle]::Bold)
$title.Location=[System.Drawing.Point]::new(28,20);$title.Size=[System.Drawing.Size]::new(620,42)
$form.Controls.Add($title)
$intro=New-Object System.Windows.Forms.Label
$intro.Text='Выберите папку и вариант официального Zapret2. Установщик проверит SHA-256, установит программу и настроит разрешение Firewall только для winws2.exe.'
$intro.Location=[System.Drawing.Point]::new(30,70);$intro.Size=[System.Drawing.Size]::new(660,48);$intro.Anchor='Top,Left,Right'
$form.Controls.Add($intro)

$pathLabel=New-Object System.Windows.Forms.Label
$pathLabel.Text='Папка установки (должна быть новой или пустой)'
$pathLabel.Location=[System.Drawing.Point]::new(30,132);$pathLabel.Size=[System.Drawing.Size]::new(610,24)
$form.Controls.Add($pathLabel)
$pathBox=New-Object System.Windows.Forms.TextBox
$pathBox.Text='C:\AntiDPI';$pathBox.Location=[System.Drawing.Point]::new(30,160);$pathBox.Size=[System.Drawing.Size]::new(530,30);$pathBox.Anchor='Top,Left,Right'
$form.Controls.Add($pathBox)
$updateCheck=New-Object System.Windows.Forms.CheckBox
$updateCheck.Text='Обновить установленную AntiDPI (сохранить настройки, логи и папку Zapret2)'
$updateCheck.Checked=(Test-InstallerExistingInstall $pathBox.Text)
$updateCheck.Location=[System.Drawing.Point]::new(30,198);$updateCheck.Size=[System.Drawing.Size]::new(660,26);$updateCheck.Anchor='Top,Left,Right'
$form.Controls.Add($updateCheck)
$browseButton=New-Object System.Windows.Forms.Button
$browseButton.Text='Обзор…';$browseButton.Location=[System.Drawing.Point]::new(570,158);$browseButton.Size=[System.Drawing.Size]::new(120,34);$browseButton.Anchor='Top,Right'
$form.Controls.Add($browseButton)
$browseButton.Add_Click({
    $dialog=New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description='Выберите родительскую папку для установки AntiDPI'
    $dialog.ShowNewFolderButton=$true
    $existing=Split-Path -Parent $pathBox.Text
    if(Test-Path -LiteralPath $existing -PathType Container){$dialog.SelectedPath=$existing}
    if($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK){$pathBox.Text=Join-Path $dialog.SelectedPath 'AntiDPI'}
    $dialog.Dispose()
})

$bundleGroup=New-Object System.Windows.Forms.GroupBox
$bundleGroup.Text='Источник Zapret2';$bundleGroup.Location=[System.Drawing.Point]::new(30,232);$bundleGroup.Size=[System.Drawing.Size]::new(660,116);$bundleGroup.Anchor='Top,Left,Right'
$form.Controls.Add($bundleGroup)
$compatibleRadio=New-Object System.Windows.Forms.RadioButton
$compatibleRadio.Text='Совместимая закреплённая версия (рекомендуется)'
$compatibleRadio.Checked=$true;$compatibleRadio.Location=[System.Drawing.Point]::new(18,28);$compatibleRadio.Size=[System.Drawing.Size]::new(610,26)
$bundleGroup.Controls.Add($compatibleRadio)
$latestRadio=New-Object System.Windows.Forms.RadioButton
$latestRadio.Text='Последняя версия официальной ветки master'
$latestRadio.Location=[System.Drawing.Point]::new(18,64);$latestRadio.Size=[System.Drawing.Size]::new(610,26)
$bundleGroup.Controls.Add($latestRadio)
$shortcutCheck=New-Object System.Windows.Forms.CheckBox
$shortcutCheck.Text='Создать ярлыки запуска и удаления на Рабочем столе'
$shortcutCheck.Checked=$true;$shortcutCheck.Location=[System.Drawing.Point]::new(32,358);$shortcutCheck.Size=[System.Drawing.Size]::new(640,28)
$form.Controls.Add($shortcutCheck)
$warning=New-Object System.Windows.Forms.Label
$warning.Text='Установка требует прав администратора. Не отключайте антивирус автоматически: при необходимости настройте его исключения вручную. Запуск анализа YouTube не проверяет VPN/Tor-туннель.'
$warning.Location=[System.Drawing.Point]::new(32,396);$warning.Size=[System.Drawing.Size]::new(650,48);$warning.ForeColor=[System.Drawing.Color]::FromArgb(120,74,0);$warning.Anchor='Top,Left,Right'
$form.Controls.Add($warning)

$status=New-Object System.Windows.Forms.Label
$status.Text='Готово к установке';$status.Location=[System.Drawing.Point]::new(32,454);$status.Size=[System.Drawing.Size]::new(650,24);$status.Anchor='Top,Left,Right'
$form.Controls.Add($status)
$progress=New-Object System.Windows.Forms.ProgressBar
$progress.Location=[System.Drawing.Point]::new(32,483);$progress.Size=[System.Drawing.Size]::new(650,18);$progress.Style=[System.Windows.Forms.ProgressBarStyle]::Blocks;$progress.Anchor='Top,Left,Right'
$form.Controls.Add($progress)
$logBox=New-Object System.Windows.Forms.TextBox
$logBox.Multiline=$true;$logBox.ReadOnly=$true;$logBox.ScrollBars='Vertical';$logBox.Font=[System.Drawing.Font]::new('Consolas',8.5)
$logBox.Location=[System.Drawing.Point]::new(32,510);$logBox.Size=[System.Drawing.Size]::new(650,68);$logBox.Anchor='Top,Bottom,Left,Right'
$form.Controls.Add($logBox)
$installButton=New-Object System.Windows.Forms.Button
$installButton.Text='Установить';$installButton.Location=[System.Drawing.Point]::new(32,590);$installButton.Size=[System.Drawing.Size]::new(150,36);$installButton.BackColor=[System.Drawing.Color]::FromArgb(31,111,235);$installButton.ForeColor=[System.Drawing.Color]::White;$installButton.Anchor='Bottom,Left'
$form.Controls.Add($installButton)
$openLogsButton=New-Object System.Windows.Forms.Button
$openLogsButton.Text='Открыть логи';$openLogsButton.Location=[System.Drawing.Point]::new(192,590);$openLogsButton.Size=[System.Drawing.Size]::new(140,36);$openLogsButton.Enabled=$false;$openLogsButton.Anchor='Bottom,Left'
$form.Controls.Add($openLogsButton)
$cancelButton=New-Object System.Windows.Forms.Button
$cancelButton.Text='Отменить загрузку';$cancelButton.Location=[System.Drawing.Point]::new(350,590);$cancelButton.Size=[System.Drawing.Size]::new(180,36);$cancelButton.Enabled=$false;$cancelButton.Anchor='Bottom,Left'
$form.Controls.Add($cancelButton)
$closeButton=New-Object System.Windows.Forms.Button
$closeButton.Text='Закрыть';$closeButton.Location=[System.Drawing.Point]::new(552,590);$closeButton.Size=[System.Drawing.Size]::new(130,36);$closeButton.Anchor='Bottom,Right'
$form.Controls.Add($closeButton)
$updateCheck.Add_CheckedChanged({
    $pathLabel.Text=if($updateCheck.Checked){'Папка существующей установки (обновление на месте)'}else{'Папка установки (новая или пустая)'}
    $bundleGroup.Enabled=(-not $updateCheck.Checked)
    $shortcutCheck.Enabled=(-not $updateCheck.Checked)
    if($updateCheck.Checked){$installButton.Text='Обновить'}else{$installButton.Text='Установить'}
})
$pathLabel.Text=if($updateCheck.Checked){'Папка существующей установки (обновление на месте)'}else{'Папка установки (новая или пустая)'}
$bundleGroup.Enabled=(-not $updateCheck.Checked);$shortcutCheck.Enabled=(-not $updateCheck.Checked)
if($updateCheck.Checked){$installButton.Text='Обновить'}

$openLogsButton.Add_Click({
    try{$directory=Split-Path -Parent $script:stdoutPath;if($directory){Start-Process explorer.exe -ArgumentList (ConvertTo-InstallerArgument $directory)}}catch{Show-InstallerError $_.Exception.Message}
})
$cancelButton.Add_Click({
    if($null -eq $script:installProcess -or $script:installProcess.HasExited -or -not $script:cancelFile){return}
    if(Test-Path -LiteralPath ($script:cancelFile+'.closed') -PathType Leaf){$cancelButton.Enabled=$false;$status.Text='Архив уже проверен; отмена загрузки недоступна.';return}
    try{
        [IO.File]::WriteAllText($script:cancelFile,'cancel',[Text.UTF8Encoding]::new($false))
        $cancelButton.Enabled=$false
        $status.Text='Отмена запрошена. Очищаю временные файлы…';$status.ForeColor=[System.Drawing.Color]::DarkOrange
    }catch{Show-InstallerError ('Не удалось отменить загрузку: '+$_.Exception.Message)}
})
$closeButton.Add_Click({$form.Close()})
$installButton.Add_Click({
    try{
        $raw=$pathBox.Text.Trim().Trim('"').Trim()
        if(-not [IO.Path]::IsPathRooted($raw)){throw 'Укажите абсолютный путь, например C:\AntiDPI.'}
        $target=[IO.Path]::GetFullPath($raw)
        if($target -eq [IO.Path]::GetPathRoot($target)){throw 'Выберите отдельную папку, а не корень диска.'}
        if($updateCheck.Checked){
            if(-not (Test-InstallerExistingInstall $target)){throw 'В выбранной папке не найдена целая установка AntiDPI. Проверьте путь или отключите режим обновления для чистой установки.'}
        }elseif(Test-Path -LiteralPath $target){
            if(-not (Test-Path -LiteralPath $target -PathType Container) -or @(Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop).Count){throw 'Выбранная папка не пуста. Включите «Обновить установленную AntiDPI» или укажите новую пустую папку.'}
        }
        $pathBox.Text=$target
        $logDirectory=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'AntiDPI_Install_Logs'
        [IO.Directory]::CreateDirectory($logDirectory)|Out-Null
        $stamp=Get-Date -Format 'yyyyMMdd_HHmmss_fff'
        $script:stdoutPath=Join-Path $logDirectory ('Wizard_'+$stamp+'.out.log')
        $script:stderrPath=Join-Path $logDirectory ('Wizard_'+$stamp+'.err.log')
        $script:cancelFile=Join-Path $logDirectory ('cancel_'+$stamp+'.request')
        $script:lastLog=''
        $powershell=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $action=if($updateCheck.Checked){'Update'}else{'Install'}
        $args=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$manager,'-Action',$action,'-InstallPath',$target,'-NonInteractiveInstaller','-SkipHeader')
        if($action -eq 'Install'){$args+=@('-CancelFile',$script:cancelFile)}
        if(-not $updateCheck.Checked){
            $choice=if($latestRadio.Checked){'Latest'}else{'Compatible'}
            $shortcut=if($shortcutCheck.Checked){'Yes'}else{'No'}
            $args+=@('-BundleSelection',$choice,'-CreateShortcutChoice',$shortcut)
        }
        $joined=(@($args|ForEach-Object {ConvertTo-InstallerArgument ([string]$_)}) -join ' ')
        $script:installProcess=Start-Process -FilePath $powershell -ArgumentList $joined -WindowStyle Normal -RedirectStandardOutput $script:stdoutPath -RedirectStandardError $script:stderrPath -PassThru
        $installButton.Enabled=$false;$pathBox.Enabled=$false;$browseButton.Enabled=$false;$bundleGroup.Enabled=$false;$shortcutCheck.Enabled=$false;$updateCheck.Enabled=$false
        $openLogsButton.Enabled=$true;$cancelButton.Enabled=($action -eq 'Install');$progress.Style=[System.Windows.Forms.ProgressBarStyle]::Marquee;$progress.MarqueeAnimationSpeed=25
        $status.Text=if($action -eq 'Update'){'Обновляются файлы AntiDPI; настройки, логи и текущий Zapret2 сохраняются.'}else{'Идёт загрузка, проверка и установка. Это может занять несколько минут.'}
    }catch{Show-InstallerError $_.Exception.Message}
})

$timer=New-Object System.Windows.Forms.Timer
$timer.Interval=600
$timer.Add_Tick({
    if($script:stdoutPath -and (Test-Path -LiteralPath $script:stdoutPath -PathType Leaf)){
        try{
            $lines=@(Get-Content -LiteralPath $script:stdoutPath -Tail 8 -Encoding UTF8 -ErrorAction Stop)
            $tail=$lines -join [Environment]::NewLine
            if($tail -cne $script:lastLog){$logBox.Text=$tail;$logBox.SelectionStart=$logBox.TextLength;$logBox.ScrollToCaret();$script:lastLog=$tail}
        }catch{}
    }
    if($cancelButton.Enabled -and $script:cancelFile -and (Test-Path -LiteralPath ($script:cancelFile+'.closed') -PathType Leaf)){$cancelButton.Enabled=$false;$status.Text='Архив проверен. Выполняется подготовка установки; отмена загрузки уже недоступна.';$status.ForeColor=[System.Drawing.Color]::DarkGreen}
    if($null -ne $script:installProcess -and $script:installProcess.HasExited){
        $code=$script:installProcess.ExitCode
        $script:installProcess.Dispose();$script:installProcess=$null
        $cancelButton.Enabled=$false
        if($script:cancelFile -and (Test-Path -LiteralPath $script:cancelFile)){Remove-Item -LiteralPath $script:cancelFile -Force -ErrorAction SilentlyContinue}
        if($script:cancelFile -and (Test-Path -LiteralPath ($script:cancelFile+'.closed'))){Remove-Item -LiteralPath ($script:cancelFile+'.closed') -Force -ErrorAction SilentlyContinue}
        $progress.Style=[System.Windows.Forms.ProgressBarStyle]::Blocks;$progress.MarqueeAnimationSpeed=0;$progress.Value=if($code -eq 0){100}else{0}
        $openLogsButton.Enabled=$true
        $recent=@()
        foreach($logPath in @($script:stderrPath,$script:stdoutPath)){
            if($logPath -and (Test-Path -LiteralPath $logPath -PathType Leaf)){try{$recent+=@(Get-Content -LiteralPath $logPath -Tail 18 -Encoding UTF8 -ErrorAction Stop)}catch{}}
        }
        $recent=@($recent|Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)})
        if($recent.Count){$logBox.Text=($recent -join [Environment]::NewLine);$logBox.SelectionStart=$logBox.TextLength;$logBox.ScrollToCaret()}
        if($code -eq 2){
            $status.Text='Установка отменена. Временные файлы очищены; можно повторить.';$status.ForeColor=[System.Drawing.Color]::DarkOrange
            $installButton.Text='Повторить установку';$installButton.Enabled=$true;$pathBox.Enabled=$true;$browseButton.Enabled=$true;$updateCheck.Enabled=$true
            $bundleGroup.Enabled=(-not $updateCheck.Checked);$shortcutCheck.Enabled=(-not $updateCheck.Checked)
        }elseif($code -eq 0){
            $verb=if($updateCheck.Checked){'Обновление'}else{'Установка'}
            $status.Text=($verb+' завершено: '+$pathBox.Text);$status.ForeColor=[System.Drawing.Color]::DarkGreen
            $installButton.Text=if($updateCheck.Checked){'Обновлено'}else{'Установлено'};$installButton.Enabled=$false
        }else{
            $detail=if($recent.Count){[string]$recent[$recent.Count-1]}else{'Подробности смотрите в файлах логов.'}
            $status.Text=('Ошибка: '+$detail);$status.ForeColor=[System.Drawing.Color]::Firebrick
            $installButton.Text=if($updateCheck.Checked){'Повторить обновление'}else{'Повторить'};$installButton.Enabled=$true;$pathBox.Enabled=$true;$browseButton.Enabled=$true;$updateCheck.Enabled=$true
            $bundleGroup.Enabled=(-not $updateCheck.Checked);$shortcutCheck.Enabled=(-not $updateCheck.Checked)
            if($recent.Count){Show-InstallerError ($detail+"`r`n`r`nПолный вывод доступен в открываемых логах.")}
        }
    }
})
$timer.Start()
$form.Add_FormClosing({
    param($sender,$eventArgs)
    if($null -ne $script:installProcess -and -not $script:installProcess.HasExited){
        [System.Windows.Forms.MessageBox]::Show('Дождитесь завершения или отмените загрузку кнопкой «Отменить загрузку». Закрытие окна не прервёт системные изменения.','AntiDPI',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)|Out-Null
        $eventArgs.Cancel=$true
    }
})
$form.Add_FormClosed({$timer.Stop();$timer.Dispose()})
[void]$form.ShowDialog()
