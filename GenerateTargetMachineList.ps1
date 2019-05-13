$VerbosePreference = "SilentlyContinue"
function GetAllActiveCompAD {
    Param (
        $VerbosePreference = "SilentlyContinue", 
        $domain, 
        $DaysInactive=90, 
        $creds
    )
    # Ref: https://gallery.technet.microsoft.com/scriptcenter/Get-Inactive-Computer-in-54feafde
    $time = (Get-Date).Adddays(-($DaysInactive)) 
    $pdce = (Get-ADDomain -identity $domain -Credential $creds).PDCEmulator
    # Get all AD server computers with lastLogonTimestamp greater than our time 
    $computers = Get-ADComputer -Filter {(LastLogonTimeStamp -gt $time)-and(operatingsystem -like "*Server*")-and(trustedfordelegation -eq "false")} -server $pdce -Properties DNSHostName,LastLogonTimeStamp
    Write-Verbose "found $($Computers.Count) computers"
    foreach ($computer in $computers) {
        $computerObj = New-Object System.Object
        $computerObj | Add-Member -type NoteProperty -Name Machine -Value $computer.DNSHostName
        $computerObj | Add-Member -type NoteProperty -Name LastLogonTimeStamp -Value ([DateTime]::FromFileTime($computer.lastLogonTimestamp))
        $computerObj | Export-Csv -Path "$($ReportFolder)\ActiveComputers.csv" -NoTypeInformation -Append -Force
        Remove-Variable computerObj
    }
    return $computers
}