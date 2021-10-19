using namespace System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Application]::EnableVisualStyles()

# Form�^�C�g���A�o�[�W�������
$ScriptTitle = "DeepL Clipboard Translator Ver2.1"

# GUI����Ȃ̂�Shell�͉B���Ă���
Get-Process -Name powershell | Where-Object -FilterScript {$_.Id -eq $PID} | % {
  $hWnd = If ($_.ID -eq $PID) { $_.MainWindowHandle }
}
[Void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
sv SYSCOMMAND 0x0112 -Option Constant
sv SC_MINIMIZE 0xf020 -Option Constant
$msg = [System.Windows.Forms.Message]::Create($hWnd ,$SYSCOMMAND ,$SC_MINIMIZE, 0)
(New-Object System.Windows.Forms.NativeWindow) | % {
  $_.DefWndProc([Ref]$msg)
  $_ = $null
}

# �J�����g�����g�̃f�B���N�g���ɕύX
$current_dir = (Convert-Path .)
Set-Location -LiteralPath $PSScriptRoot

# class object����
. .\class\class_DeepL.ps1
$objectDeepL = New-Object class_DeepL

# Auth key�ݒ�
$file = New-Object System.IO.StreamReader($PSScriptRoot + "\\auth_key.txt")
$objectDeepL.auth_key = "$($file.ReadLine())"
$file.Close()

# �t�H�[��
$form = New-Object System.Windows.Forms.Form
$form.Text = $ScriptTitle
$form.Size = New-Object System.Drawing.Size(960,480)
#$form.MinimumSize = New-Object System.Drawing.Size(960,480)
$form.StartPosition = "CenterScreen"
#$form.Icon = ".\DeepL_Logo_darkBlue_v2.ico"

$size = $form.Size;
$width = $size.Width; 
$height = $size.Height;

##
# ���j���[���C�A�E�g�e�[�u��
$table_Menu = New-Object System.Windows.Forms.TableLayoutPanel
$table_Menu.ColumnCount = 6
$table_Menu.RowCount = 1

# ���s��������
$CheckBox_SkipRet = New-Object CheckBox
$CheckBox_SkipRet.Text = '���s�����iPDF��Web�ŁA���͂̓r���ŉ��s����Ă���悤�ȏꍇ�ɗ��p�B�j'
$CheckBox_SkipRet.AutoSize = $true
$CheckBox_SkipRet.Dock = [System.Windows.Forms.DockStyle]::Fill
$CheckBox_SkipRet.Checked = $False
$CheckBox_SkipRet.Add_CheckedChanged({
})
$table_Menu.Controls.Add($CheckBox_SkipRet, 0, 0)
$table_Menu.SetColumnSpan($CheckBox_SkipRet, 3)

# �|��挾��
$RadioButtonJapanese = New-Object System.Windows.Forms.RadioButton
$RadioButtonJapanese.Text = "���{��"
$RadioButtonJapanese.Location = New-Object Drawing.Point(20, 20)
$RadioButtonJapanese.Checked = $True
$RadioButtonEnglish = New-Object System.Windows.Forms.RadioButton
$RadioButtonEnglish.Text = "�p��"
$RadioButtonEnglish.Location = New-Object Drawing.Point(150, 20)
$RadioButtonEnglish.Checked = $False
$GroupBoxTargetLang = New-Object System.Windows.Forms.GroupBox
$GroupBoxTargetLang.Text     = '�|��挾��'
$GroupBoxTargetLang.Location = New-Object Drawing.Point($($width/2), 10)
$GroupBoxTargetLang.Size     = New-Object Drawing.Size(300, 60)
$GroupBoxTargetLang.Controls.AddRange(@($RadioButtonJapanese, $RadioButtonEnglish))
$RadioButtonJapanese.Add_CheckedChanged({
  If($RadioButtonJapanese.Checked){
    $objectDeepL.target_lang = "JA"
  }Else{
    $objectDeepL.target_lang = "EN"
  }
  $Global:clipText = ""
  $Global:startTranslate = $True
})
$table_Menu.Controls.Add($GroupBoxTargetLang, 3, 0)

# �ꎞ��~
$CheckBox_Stop = New-Object CheckBox
$CheckBox_Stop.TextAlign = "MiddleCenter"
$CheckBox_Stop.Appearance = "Button"
$CheckBox_Stop.Dock = [System.Windows.Forms.DockStyle]::Fill
$CheckBox_Stop.Text = "Click��`r`n�ꎞ��~"
$CheckBox_Stop.Checked = $False
$CheckBox_Stop.Add_CheckedChanged({
  If ( $CheckBox_Stop.text -eq "Click��`r`n�ꎞ��~")
  {
    $CheckBox_Stop.text = "�ꎞ��~��"
    $CheckBox_Stop.Checked = $True
    $Global:startTranslate = $True
  }else{
    $CheckBox_Stop.text = "Click��`r`n�ꎞ��~"
    $CheckBox_Stop.Checked = $False
  }
})
$table_Menu.Controls.Add($CheckBox_Stop, 4, 0)

# Clear�{�^��
$ClearButton = New-Object System.Windows.Forms.Button
$ClearButton.Dock = [System.Windows.Forms.DockStyle]::Fill
$ClearButton.Text = "Clear"
$ClearButton.Add_Click({
  $textBox.Clear()
  $textBox_TargetClip.Clear()
  $textBox_SourceInput.Clear()
  $textBox_TargetInput.Clear()
})
$table_Menu.Controls.Add($ClearButton, 5, 0)

##
# ���C�A�E�g�e�[�u��
$table_Main = New-Object System.Windows.Forms.TableLayoutPanel
$table_Main.ColumnCount = 2
$table_Main.RowCount = 4

# ���̓��x��
$label_SourceClip = New-Object System.Windows.Forms.Label
$label_SourceClip.Text = "�N���b�v�{�[�h(�|��) [�N���b�v�{�[�h���玩������]"
$label_SourceClip.AutoSize = $true
$table_Main.Controls.Add($label_SourceClip, 0, 0)

# ���ʃ��x��
$label_TargetClip = New-Object System.Windows.Forms.Label
$label_TargetClip.Text = "�N���b�v�{�[�h(�|�󌋉�)"
$label_TargetClip.AutoSize = $true
$table_Main.Controls.Add($label_TargetClip, 1, 0)

# ���̓{�b�N�X
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$textBox.Multiline = $True
$textBox.ReadOnly = $True
$textBox.AcceptsReturn = $True
$textBox.AcceptsTab = $True
$textBox.WordWrap = $True
$textBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$table_Main.Controls.Add($textBox, 0, 1)

# �|��e�L�X�g�{�b�N�X
$textBox_TargetClip = New-Object System.Windows.Forms.textBox
$textBox_TargetClip.Dock = [System.Windows.Forms.DockStyle]::Fill
$textBox_TargetClip.Multiline = $True
$textBox_TargetClip.ReadOnly = $True
$textBox_TargetClip.AcceptsReturn = $True
$textBox_TargetClip.AcceptsTab = $True
$textBox_TargetClip.WordWrap = $True
$textBox_TargetClip.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$table_Main.Controls.Add($textBox_TargetClip, 1, 1)

# ����̓��x��
$label_SourceInput = New-Object System.Windows.Forms.Label
$label_SourceInput.Text = "�����(�|��) [���͌�G���^�[�L�[�Ŗ|��J�n]"
$label_SourceInput.AutoSize = $true
$table_Main.Controls.Add($label_SourceInput, 0, 2)

# ����̓{�b�N�X
$textBox_SourceInput = New-Object System.Windows.Forms.TextBox
$textBox_SourceInput.Dock = [System.Windows.Forms.DockStyle]::Fill
$textBox_SourceInput.Multiline = $True
$textBox_SourceInput.ReadOnly = $False
$textBox_SourceInput.AcceptsReturn = $True
$textBox_SourceInput.AcceptsTab = $True
$textBox_SourceInput.WordWrap = $True
$textBox_SourceInput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical

$ReturnEvent = {
  $PushKey = $_.KeyCode
  If ($PushKey -eq "Return")
  {
    If ($textBox_SourceInput.Text -replace "`r`n",'' -ne "")
    {
      $Global:startTranslate = $True
    }
  }
}
$textBox_SourceInput.Add_KeyDown($ReturnEvent)
#$textBox_SourceInput.Add_TextChanged({
#  $Global:startTranslate = $True
#})
$table_Main.Controls.Add($textBox_SourceInput, 0, 3)

# ����͖|�󃉃x��
$label_TargetInput = New-Object System.Windows.Forms.Label
$label_TargetInput.Text = "�����(�|�󌋉�)"
$label_TargetInput.AutoSize = $true
$table_Main.Controls.Add($label_TargetInput, 1, 2)

# ����͖|��e�L�X�g�{�b�N�X
$textBox_TargetInput = New-Object System.Windows.Forms.textBox
$textBox_TargetInput.Dock = [System.Windows.Forms.DockStyle]::Fill
$textBox_TargetInput.Multiline = $True
$textBox_TargetInput.ReadOnly = $True
$textBox_TargetInput.AcceptsReturn = $True
$textBox_TargetInput.AcceptsTab = $True
$textBox_TargetInput.WordWrap = $True
$textBox_TargetInput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$table_Main.Controls.Add($textBox_TargetInput, 1, 3)

# ���j���[���C�A�E�g
$table_Menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 100)))
$table_Menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 200)))
$table_Menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$table_Menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 300)))
$table_Menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$table_Menu.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 25)))
$table_Menu.Anchor = (([System.Windows.Forms.AnchorStyles]::Left) `
              -bor ([System.Windows.Forms.AnchorStyles]::Right) `
              -bor ([System.Windows.Forms.AnchorStyles]::Top))
$table_Menu.Location = New-Object System.Drawing.Point(5, 10)
$table_Menu.Size = New-Object System.Drawing.Size($($width-25), 65)
$form.Controls.Add($table_Menu)

# ���C�����C�A�E�g
$table_Main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$table_Main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
$table_Main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 15)))
$table_Main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 70)))
$table_Main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 15)))
$table_Main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 30)))
$table_Main.Anchor = (([System.Windows.Forms.AnchorStyles]::Left) `
              -bor ([System.Windows.Forms.AnchorStyles]::Right) `
              -bor ([System.Windows.Forms.AnchorStyles]::Top) `
              -bor ([System.Windows.Forms.AnchorStyles]::Bottom))
$table_Main.Location = New-Object System.Drawing.Point(5, 80)
$table_Main.Size = New-Object System.Drawing.Size($($width-25), $($height-130))
$form.Controls.Add($table_Main)

# �t�H�[������Ɏ�O�ɕ\��
#$form.Topmost = $True

# �N���b�v�{�[�h����e�L�X�g���擾
$clipText = [Windows.Forms.Clipboard]::GetText()

# �N���b�v�{�[�h�擾�^�C�}
$timerTranslate = New-Object Windows.Forms.Timer
$timerTranslate.Interval = 1000
$timerTranslate.Enabled = $TRUE
$timerTranslateTick = {
  # �N���b�v�{�[�h�̃e�L�X�g���ēx�擾���A�O��̕�����ύX���Ȃ����`�F�b�N����
  $latestClipText = [Windows.Forms.Clipboard]::GetText()

  If($Global:CheckBox_SkipRet.Checked){
    $latestClipText = $latestClipText -replace "`r`n",''
#    $latestClipText = $latestClipText -replace "`n",''
  }

  If ($Global:startTranslate -eq $true)
  {
    $Global:startTranslate = $False
    $objectDeepL.target_text = $Global:textBox_SourceInput.Text
    $ret2 = $objectDeepL.funcTranslate()
    $textBox_TargetInput.Text = $($ret2)
  }
  
  # ����̓e�L�X�g�{�b�N�X�Ƀt�H�[�J�X������Ԃ͖|��͒�~����
  If ($false -eq $textBox_TargetInput.Focused)
  {
    # �ꎞ��~���łȂ����
    If ($Global:CheckBox_Stop.Checked -eq $False)
    {
      # �ύX���������ꍇ�͍X�V����
      If ($latestClipText -ne $Global:clipText)
      {
        # ����
        $Global:clipText = $latestClipText
        $textBox.AppendText($Global:clipText + "`r`n`r`n")
        # �|��
        $objectDeepL.target_text = $latestClipText
        $ret = $objectDeepL.funcTranslate()
        $textBox_TargetClip.AppendText($ret + "`r`n`r`n")
      }
    }
  }
}
$timerTranslate.Add_Tick($timerTranslateTick)
$timerTranslate.Start()

# �t�H�[����\��
$result = $form.ShowDialog()

# �J�����g�����s�ꏊ�ɖ߂�
Set-Location -LiteralPath $current_dir

