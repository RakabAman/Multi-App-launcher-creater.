Add-Type -AssemblyName System.Windows.Forms

$exeFiles = @()
while ($true) {
    $ofd = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath('Desktop')
        Filter = 'Executable files (*.exe)|*.exe|All files (*.*)|*.*'
    }
    $ofd.ShowDialog() | Out-Null
    if ($ofd.FileName) {
        $exeFiles += $ofd.FileName
    } else {
        break
    }
}

$exeConfigs = @()
$instanceNumber = 1
foreach ($exeFile in $exeFiles) {
    $instance = "Instance $instanceNumber"
    $filename = [System.IO.Path]::GetFileName($exeFile)
    $filepath = [System.IO.Path]::GetDirectoryName($exeFile)
    $priority = Read-Host "Enter priority for $($filename) (Low, BelowNormal, Normal, AboveNormal, High): "
    $exeConfigs += [PSCustomObject]@{
        ExeFile = $exeFile
        FileName = $filename
        FilePath = $filepath
        Instance = $instance
        Priority = $priority
    }
    $instanceNumber++
}
Read-Host $exeConfigs

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
$exeConfigs | Sort-Object -Property Instance | ForEach-Object {
    if ($_.Instance -ne "Instance 1") {
        $cmd = "Taskkill /F /IM `"$($_.Filename)`" /T"
        
        $batchScript += $cmd
    }
}

$batFilePath = $exeConfigs | Where-Object {$_.Instance -eq "Instance 1"} | Select-Object -ExpandProperty FilePath
$batFileName = $exeConfigs | Where-Object {$_.Instance -eq "Instance 1"} | Select-Object -ExpandProperty FileName
$batchScript | Set-Content -Path "$batFilePath\$batFileName.bat" -Encoding Ascii
Write-Host "Batch script saved to $batFilePath\$batFileName.bat"