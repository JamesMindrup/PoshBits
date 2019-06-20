# Script to replace a string in a file remotely (like an ossec.conf update)
function ReplaceStringInFile {
    param (
        $fileFullPath,
        $ComputerName,
        $TextToReplace,
        $ReplacementText,
        [switch]$LiveRun,
        $VerbosePreference = "SilentlyContinue"
    )
    
    Write-host "live: $($liverun)"
    $creds = Get-Credential
    
    $ScriptBlock = {
        param (
            $fileFullPath,
            $TextToReplace,
            $ReplacementText,
            $LiveRun,
            $VerbosePreference = "SilentlyContinue"
        )
        Write-Host "Path: $($fileFullPath)"
        Write-Host "To Replace: $($TextToReplace)"
        Write-Host "Replace With: $($ReplacementText)"
        Write-Host "Live: $($LiveRun)"

        if (Test-Path $fileFullPath) {

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
            Copy-Item -Path $fileFullPath -Destination $fileBackupFullPath

            # Check for the target string to be replaced
            $TargetStringMatches = Select-String -Path $fileFullPath -Pattern $TextToReplace
            if ($TargetStringMatches.Matches.Success) {
                Write-Verbose "String Found on line $($TargetStringMatches.LineNumber).  Attempting to replace..."
                # Replace the text
                if ($LiveRun) {(Get-Content $fileFullPath).replace($TextToReplace, $ReplacementText) | Set-Content $fileFullPath}
                else {Write-Verbose "!!!Test run, nothing changed!!!"}
                # Pause for system to make the change
                Start-Sleep -Seconds 1
                # Verify the text was changed
                $TargetStringMatches = Select-String -Path $fileFullPath -Pattern $ReplacementText
                if ($TargetStringMatches.Matches.Success) {Write-Verbose "String replacement Found on line $($TargetStringMatches.LineNumber)"}
                else {Write-Verbose "String NOT Replaced"}
            }
            else {Write-Verbose "String NOT Found"}
        }
        else {Write-Verbose "Target file not found!"}
    }

    # Connect to Computer remotely
    Write-Verbose "Testing remote connection: $($computername)"
    Test-WsMan $computerName | Out-Null
    if ($?) {
        Write-Verbose "Connection test to $($computername) succeeded. sending commands"
        Invoke-Command -Computername $ComputerName -Credential $creds -ScriptBlock $ScriptBlock `
          -ArgumentList $fileFullPath,$TextToReplace,$ReplacementText,$LiveRun,$VerbosePreference
    }
    else {
        Write-Verbose "Connection to $($computername) failed!"
    }
}
