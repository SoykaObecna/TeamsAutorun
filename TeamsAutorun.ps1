[Cmdletbinding(SupportsShouldProcess=$true)]

$VerbosePreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

# Run registry property name
$TeamsPropertyName = 'com.squirrel.Teams.Teams' 
$RegistryRunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 

# Teams Config Data file Path
$TeamsConfig = "$env:APPDATA\Microsoft\Teams\desktop-config.json"

# a flag that indicates whether there are some chnges to be saved to $TeamsConfig json config file
$SaveConfigFile = $false

$TeamsAutoRun = (Get-ItemProperty -Path $RegistryRunKeyPath -ErrorAction SilentlyContinue)."$TeamsPropertyName"

# If Teams autorun entry exists, remove it
if ($TeamsAutoRun) {
    Write-Verbose "property $TeamsPropertyName exists in HKCU Run registry"
    if ($PSCmdlet.ShouldProcess("registry Value $RegistryRunKeyPath\$TeamsPropertyName", "Remove") {
            Remove-ItemProperty -Path $RegistryRunKeyPath -Name $TeamsPropertyName
        }
    }
    else {
        Write-Verbose "property $TeamsPropertyName does not exist in HKCU Run registry"

    }

}

if (Test-Path -Path $TeamsConfig) {
    Write-Verbose "file $TeamsConfig exists"

    $TeamsConfigData = Get-Content -Path $TeamsConfig -Raw | ConvertFrom-Json

    switch ($TeamsConfigData.appPreferenceSettings)
    {
        {$_.openAtLogin -eq $false} {
            # It's already configured, do nothing
            Write-Verbose "openAtLogin=false ... do nothing"
            #break
        }

        {$_.openAtLogin -eq $true} {
            Write-Verbose "openAtLogin=true ... setting it to false"
            $TeamsConfigData.appPreferenceSettings.openAtLogin = $false  
            
            $SaveConfigFile  = $true
            
            #break
        }

        {$null -eq $_.openAtLogin} {
            Write-Verbose "openAtLogin setting does not exist yet ... creating it and setting it to false"
            $TeamsConfigData.appPreferenceSettings | Add-Member -Name "openAtLogin" -Value $false -MemberType NoteProperty
            
            $SaveConfigFile = $true
            
            #break
        }

        {$_.runningOnClose -eq $false} {
            # It's already configured, do nothing
            Write-Verbose "runningOnClose=false ... do nothing"
            #break
        }

        {$_.runningOnClose -eq $true} {
            Write-Verbose "runningOnClose=true ... setting it to false"
            $TeamsConfigData.appPreferenceSettings.runningOnClose = $false  

            $SaveConfigFile = $true
            #break
        }

        {$null -eq $_.runningOnClose} {
            Write-Verbose "runningOnClose setting does not exist yet ... creating it and setting it to false"
            $TeamsConfigData.appPreferenceSettings | Add-Member -Name "runningOnClose" -Value $false -MemberType NoteProperty
            
            $SaveConfigFile = $true
            
            #break
        }
        

        Default {
            Write-Verbose "default switch branch, wtf?"
        }
    } #switch


    #save config file
    #kill teams before saving the file
    if (Get-Process -Name 'teams' -ErrorAction SilentlyContinue) {
        Write-Verbose "killing teams process"

        Stop-Process -Name 'teams' -ErrorAction SilentlyContinue
    }

    if ($SaveConfigFile) {
        Write-Verbose "saving $TeamsConfig file"
        $TeamsConfigData | ConvertTo-Json -Depth 100 | Out-File -Encoding UTF8 -FilePath $TeamsConfig -Force
    }
    

	
		
		
} else {
    Write-Verbose "file $TeamsConfig does not exist"
}