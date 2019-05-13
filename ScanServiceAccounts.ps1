Get-ChildItem -Path IIS:\AppPools\ | Select-Object name, state, managedRuntimeVersion, managedPipelineMode, @{e={$_.processModel.username};l="username"}, <#@{e={$_.processModel.password};l="password"}, #> @{e={$_.processModel.identityType};l="identityType"}

#$VerbosePreference = "SilentlyContinue"
    
    $VerbosePreference = "SilentlyContinue"    
    $ResultsDetails = @()
    # Local Services
    foreach ($service in (get-wmiobject win32_service | select DisplayName, name, startname, startmode, State)) {
        if (($service.startname.Length -gt 1)-and($service.startname -notlike "NT AUTHORITY\*")-and($service.startname -notlike "BUILTIN\*")-and($service.startname -notlike "NT SERVICE\*")-and($service.startname -ne "LocalSystem")-and($service.startname -ne "LocalSystem")) {
            $ServiceObj = New-Object System.Object
            $ServiceObj | Add-Member -type NoteProperty -Name Machine -Value $env:COMPUTERNAME
            $ServiceObj | Add-Member -type NoteProperty -Name svcDisplayName -Value $service.displayname
            $ServiceObj | Add-Member -type NoteProperty -Name svcName -Value $service.name
            $ServiceObj | Add-Member -type NoteProperty -Name svcCredentials -Value $service.startname
            $ServiceObj | Add-Member -type NoteProperty -Name svcStartMode -Value $service.startmode
            $ServiceObj | Add-Member -type NoteProperty -Name svcState -Value $service.State
            $ResultsDetails += $ServiceObj
        }
    }

    # IIS App Pools
    if (Test-Path IIS:\AppPools) {
        $iisAppPools = Get-ChildItem -Path IIS:\AppPools\ | Select-Object name, state, managedRuntimeVersion, managedPipelineMode, @{e={$_.processModel.username};l="username"}, <#@{e={$_.processModel.password};l="password"}, #> @{e={$_.processModel.identityType};l="identityType"}
        foreach ($iisAppPool in $iisAppPools) {
            $ServiceObj = New-Object System.Object
            $ServiceObj | Add-Member -type NoteProperty -Name Machine -Value $env:COMPUTERNAME
            $ServiceObj | Add-Member -type NoteProperty -Name svcDisplayName -Value "IIS App Pool (.NET: $($iisAppPool.managedRuntimeVersion))"
            $ServiceObj | Add-Member -type NoteProperty -Name svcName -Value $iisAppPool.name
            $ServiceObj | Add-Member -type NoteProperty -Name svcCredentials -Value $iisAppPool.username
            $ServiceObj | Add-Member -type NoteProperty -Name svcStartMode -Value $iisAppPool.managedPipelineMode
            $ServiceObj | Add-Member -type NoteProperty -Name svcState -Value $iisAppPool.State
            $ResultsDetails += $ServiceObj
        }
    }
    Return $ResultsDetails