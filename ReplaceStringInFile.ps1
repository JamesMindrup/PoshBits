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
    
    $connError = $false
    Write-host "live: $($liverun)"
    $creds = Get-Credential
    # Connect to Computer remotely unless we are running on the target computer
    if ($env:COMPUTERNAME -ne $ComputerName) {
        Write-Verbose "Attempting to create remote session: $($computername)"
        Test-WsMan $computerName | Out-Null
        if ($?) {
            Write-Verbose "Connection test to $($computername) succeeded"
            $RemoteSession = New-PSSession -Credential $creds -ComputerName $ComputerName
            Enter-PSSession $RemoteSession
        }
        else {
            Write-Verbose "Connection to $($computername) failed!"
            $connError = $true
        }
        #Invoke-Command -Computername $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $fileFullPath,$TextToReplace,$ReplacementText #(Get-Content $fileFullPath)}.replace($TextToReplace, $ReplacementText) | Set-Content $fileFullPath}
    }
    else {Write-Verbose "Running local: $($computername)"}
    
    if ($connError) {Write-Verbose "Connection Error, aborting."}
    else {
        Write-Host "Path: $($fileFullPath)"
        Write-Host "To Replace: $($TextToReplace)"
        Write-Host "Replace With: $($ReplacementText)"
        Get-ChildItem "D:"
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
    if ($env:COMPUTERNAME -ne $ComputerName) {
        Write-Verbose "Removing remote session: $($computername)"
        Remove-PSSession $RemoteSession
    }
}
