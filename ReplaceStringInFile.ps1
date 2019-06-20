# Script to replace a string in a file remotely (like an ossec.conf update)
function ReplaceStringInFile {
    param (
        $fileFullPath,
        $ComputerName,
        $TextToReplace,
        $ReplacementText,
        $creds,
        [switch]$LiveRun,
        $VerbosePreference = "SilentlyContinue"
    )
        
    $ScriptBlock = {
        param (
            $fileFullPath,
            $TextToReplace,
            $ReplacementText,
            $LiveRun,
            $VerbosePreference = "SilentlyContinue"
        )
        Write-Verbose "Path: $($fileFullPath)"
        Write-Verbose "To Replace: $($TextToReplace)"
        Write-Verbose "Replace With: $($ReplacementText)"
        Write-Verbose "Live: $($LiveRun)"

        $ResultObject = New-Object System.Object
        $ResultObject | Add-Member -type NoteProperty -Name Machine -Value $env:COMPUTERNAME
        $ResultObject | Add-Member -type NoteProperty -Name LiveRun -Value $LiveRun
        $ResultObject | Add-Member -type NoteProperty -Name FilePath -Value $fileFullPath
        $ResultObject | Add-Member -type NoteProperty -Name TextToReplace -Value $TextToReplace
        $ResultObject | Add-Member -type NoteProperty -Name ReplacementText -Value $ReplacementText
        $ResultObject | Add-Member -type NoteProperty -Name FileFound -Value $false
        $ResultObject | Add-Member -type NoteProperty -Name TextToReplaceFound -Value $false
        $ResultObject | Add-Member -type NoteProperty -Name ReplaceVerified -Value $false
        $ResultObject | Add-Member -type NoteProperty -Name BackupFileCreated -Value "NA"

        if (Test-Path $fileFullPath) {
            $ResultObject.FileFound = $true
            # Backup the file
            $fileBackupFullPath = ""
            $i = 0
            do {
                Write-Verbose "Checking for backup name not in use..."
                if ($i -eq 0) {$backupExt = ".bak"}
                else {$backupExt = ".bak$($i)"}
                if (!(Test-Path ($fileFullPath + $backupExt))) {$fileBackupFullPath = ($fileFullPath + $backupExt)}
                $i++
            } until ($fileBackupFullPath)
            if ($LiveRun) {Copy-Item -Path $fileFullPath -Destination $fileBackupFullPath}
            else {Write-Verbose "!!!Test run, no backup made!!!"}
            Start-Sleep -Seconds 1
            if ((!(Test-Path $fileBackupFullPath))-and($LiveRun)) {
                Write-Verbose "file backup failed!"
                $ResultObject.BackupFileCreated = "Create $($fileBackupFullPath) failed!"
            }
            else {
                if ($LiveRun) {$ResultObject.BackupFileCreated = $fileBackupFullPath}
                # Check for the target string to be replaced
                $TargetStringMatches = Select-String -Path $fileFullPath -Pattern $TextToReplace
                # need logic to handle multiple results
                if ($TargetStringMatches.Matches.Success) {
                    Write-Verbose "String Found on line $($TargetStringMatches.LineNumber).  Attempting to replace..."
                    $ResultObject.TextToReplaceFound = $true
                    # Replace the text
                    if ($LiveRun) {(Get-Content $fileFullPath).replace($TextToReplace, $ReplacementText) | Set-Content $fileFullPath}
                    else {Write-Verbose "!!!Test run, nothing changed!!!"}
                    # Pause for system to make the change
                    Start-Sleep -Seconds 1
                    # Verify the text was changed
                    $TargetStringMatches = Select-String -Path $fileFullPath -Pattern $ReplacementText
                    if ($TargetStringMatches.Matches.Success) {
                        Write-Verbose "String replacement Found on line $($TargetStringMatches.LineNumber)"
                        $ResultObject.ReplaceVerified = $true
                    }
                    else {Write-Verbose "String NOT Replaced"}
                }
                else {Write-Verbose "String NOT Found"}
            }
        }
        else {Write-Verbose "Target file not found!"}

        Return $ResultObject
    }

    # Connect to Computer remotely
    Write-Verbose "Testing remote connection: $($computername)"
    Test-WsMan $computerName | Out-Null
    if ($?) {
        Write-Verbose "Connection test to $($computername) succeeded. sending commands"
        $ResultObject = Invoke-Command -Computername $ComputerName -Credential $creds -ScriptBlock $ScriptBlock `
          -ArgumentList $fileFullPath,$TextToReplace,$ReplacementText,$LiveRun,$VerbosePreference
    }
    else {
        Write-Verbose "Connection to $($computername) failed!"
    }

    Return $ResultObject
}
