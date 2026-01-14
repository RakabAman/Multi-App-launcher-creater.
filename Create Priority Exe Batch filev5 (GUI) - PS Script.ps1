Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "Batch Script Generator"
$form.Size = New-Object System.Drawing.Size(350, 300)
$form.StartPosition = "CenterScreen"

$exeFiles = @()
$exeConfigs = @()
$instanceNumber = 1

$exeFileLabel = New-Object System.Windows.Forms.Label
$exeFileLabel.Location = New-Object System.Drawing.Point(10, 20)
$exeFileLabel.Size = New-Object System.Drawing.Size(100, 20)
$exeFileLabel.Text = "Select EXE files:"
$form.Controls.Add($exeFileLabel)

$exeFileListBox = New-Object System.Windows.Forms.ListBox
$exeFileListBox.Location = New-Object System.Drawing.Point(10, 40)
$exeFileListBox.Size = New-Object System.Drawing.Size(200, 100)
$exeFileListBox.SelectionMode = "MultiExtended"
$form.Controls.Add($exeFileListBox)

$addExeButton = New-Object System.Windows.Forms.Button
$addExeButton.Location = New-Object System.Drawing.Point(220, 40)
$addExeButton.Size = New-Object System.Drawing.Size(100, 23)
$addExeButton.Text = "Add EXE file"
$addExeButton.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter = 'Executable files (*.exe)|*.exe'
    }
    $ofd.ShowDialog() | Out-Null
    if ($ofd.FileName) {
        $exeFiles += $ofd.FileName
        $exeFileListBox.Items.Add($ofd.FileName)
    }
})
$form.Controls.Add($addExeButton)

$priorityLabel = New-Object System.Windows.Forms.Label
$priorityLabel.Location = New-Object System.Drawing.Point(10, 150)
$priorityLabel.Size = New-Object System.Drawing.Size(100, 20)
$priorityLabel.Text = "Priority:"
$form.Controls.Add($priorityLabel)

$priorityComboBox = New-Object System.Windows.Forms.ComboBox
$priorityComboBox.Location = New-Object System.Drawing.Point(10, 170)
$priorityComboBox.Size = New-Object System.Drawing.Size(100, 20)
$priorityComboBox.Items.Add("Low")
$priorityComboBox.Items.Add("BelowNormal")
$priorityComboBox.Items.Add("Normal")
$priorityComboBox.Items.Add("AboveNormal")
$priorityComboBox.Items.Add("High")
$form.Controls.Add($priorityComboBox)

$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Location = New-Object System.Drawing.Point(150, 200)
$generateButton.Size = New-Object System.Drawing.Size(100, 23)
$generateButton.Text = "Generate Batch Script"
$generateButton.Add_Click({
    $exeConfigs = @()
    $instanceNumber = 1
    foreach ($exeFile in $exeFiles) {
        $instance = "Instance $instanceNumber"
        $filename = [System.IO.Path]::GetFileName($exeFile)
        $filepath = [System.IO.Path]::GetDirectoryName($exeFile)
        $priority = $priorityComboBox.SelectedItem
        $exeConfigs += [PSCustomObject]@{
            ExeFile = $exeFile
            FileName = $filename
            FilePath = $filepath
            Instance = $instance
            Priority = $priority
        }
        $instanceNumber++
    }

    $batchScript = @()
    $exeConfigs | Sort-Object -Property Instance | ForEach-Object {
        if ($_.Instance -ne "Instance 1") {
            $cmd = "start `"$($_.Instance)`" /"
            switch ($_.Priority) {
                'Low' { $cmd += 'low' }
                'BelowNormal' { $cmd += 'belownormal' }
                'Normal' { $cmd += '' }
                'AboveNormal' { $cmd += 'abovenormal' }
                'High' { $cmd += 'high' }
            }
            $cmd += " `"$($_.ExeFile)`""
            $batchScript += $cmd
        }
    }
    $exeConfigs | Where-Object {$_.Instance -eq "Instance 1"} | ForEach-Object {
        $cmd = "start /wait `"$($_.Instance)`" /"
        switch ($_.Priority) {
            'Low' { $cmd += 'low' }
            'BelowNormal' { $cmd += 'belownormal' }
            'Normal' { $cmd += '' }
            'AboveNormal' { $cmd += 'abovenormal' }
            'High' { $cmd += 'high' }
        }
        $cmd += " `"$($_.ExeFile)`""
        $batchScript += $cmd
}

    $batFilePath = $exeConfigs | Where-Object {$_.Instance -eq "Instance 1"} | Select-Object -ExpandProperty FilePath
    $batFileName = $exeConfigs | Where-Object {$_.Instance -eq "Instance 1"} | Select-Object -ExpandProperty FileName
    $batchScript | Set-Content -Path "$batFilePath\$batFileName.bat" -Encoding UTF8
    Write-Host "Batch script saved to $batFilePath\$batFileName.bat"
})
$form.Controls.Add($generateButton)

$form.ShowDialog()