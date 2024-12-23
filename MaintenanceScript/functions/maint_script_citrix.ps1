switch ($null) {
    $IDLE_SESSION_TIME_LIMIT       { $IDLE_SESSION_TIME_LIMIT  = 30 }
}

function Invoke-LogoffSession {
    param (
        [Parameter(Mandatory)] $Session
    )

    Stop-BrokerSession -InputObject $Session
}

function Test-DisconnectedSessions {
    param (
        [Parameter(Mandatory)] $Machine
    )

    $disconnectedSessions = Get-BrokerSession -MachineName $Machine.MachineName -Filter { (SessionState -eq 'Disconnected') -and (Protocol -eq 'HDX') -and (LogoffInProgress -eq $false) }
    $areThereDisconnectedSessions = $false
    if ($disconnectedSessions) {
        $areThereDisconnectedSessions = $true
    }

    return $areThereDisconnectedSessions
}

function Test-ActiveSessions {
    param (
        [Parameter(Mandatory)] $Machine
    )

    $activeSessions = Get-BrokerSession -MachineName $Machine.MachineName -Filter { (SessionState -eq 'Active') -and (Protocol -eq 'HDX') -and (LogoffInProgress -eq $false) }
    $areThereActiveSessions = $false
    if ($activeSessions) {
        $areThereActiveSessions = $true
    }

    return $areThereActiveSessions
}

function Invoke-LogoffDisconnectedSessions {
    param (
        [Parameter(Mandatory)] $Machine
    )

    $disconnectedSessions = Get-BrokerSession -MachineName $Machine.MachineName -Filter { (SessionState -eq 'Disconnected') -and (Protocol -eq 'HDX') -and (LogoffInProgress -eq $false) }
    if ($disconnectedSessions) {
        foreach ($disconnectedSession in $disconnectedSessions) {
            Stop-BrokerSession -InputObject $disconnectedSession
        }
    }
}

function Invoke-LogoffIdleSessions {
    param (
        [Parameter(Mandatory)] $Machine
    )

    $activeSessions = Get-BrokerSession -MachineName $Machine.MachineName -Filter { (SessionState -eq 'Active') -and (Protocol -eq 'HDX') -and (LogoffInProgress -eq $false) }
    if ($activeSessions) {
        foreach ($activeSession in $activeSessions) {
            if ($null -ne $activeSession.IdleDuration) {
                $idleTimeinMinutes = ($activeSession.IdleDuration.Days * 1440) + ($activeSession.IdleDuration.Hours * 60) + $activeSession.IdleDuration.Minutes
                If ($idleTimeinMinutes -ge $IDLE_SESSION_TIME_LIMIT) {
                    Stop-BrokerSession -InputObject $activeSession
                }
            }
        }
    }
}

function Invoke-LogoffAllSessions {
    param (
        [Parameter(Mandatory)] $Machine
    )

    $allSessions = Get-BrokerSession -MachineName $Machine.MachineName
    if ($allSessions) {
        foreach ($session in $allSessions) {
            Stop-BrokerSession -InputObject $session
        }
    }
}

function Enable-MaintenanceMode {
    param (
        [Parameter(Mandatory)] $Machine
    )

    Set-BrokerMachineMaintenanceMode -InputObject $machine -MaintenanceMode $true
}

function Exit-MaintenanceMode {
    param (
        [Parameter(Mandatory)] $Machine
    )

    Set-BrokerMachineMaintenanceMode -InputObject $machine -MaintenanceMode $false
}

function Send-UserMessage {
    param (
        [Parameter(Mandatory)] $Machine,
        [Parameter(Mandatory)] [ValidateSet('Critical', 'Question', 'Exclamation', 'Information', IgnoreCase = $true)]$MessageStyle,
        [Parameter(Mandatory)] $Title,
        [Parameter(Mandatory)] $Message
    )

    $activeSessions = Get-BrokerSession -MachineName $Machine.MachineName -Filter { (SessionState -eq 'Active') -and (Protocol -eq 'HDX') -and (LogoffInProgress -eq $false) }
    if ($activeSessions) {
        foreach ($activeSession in $activeSessions) {
            $null = Send-BrokerSessionMessage -InputObject $activeSession -MessageStyle $MessageStyle -Title $Title -Text $Message
        }
    }
}

function Remove-MachinesinMaintenanceModefromWorkingSet {
    param (
        [Parameter(Mandatory)] $WorkingSet
    )

    $tempWorkingSet = @()
    foreach ($machine in $WorkingSet) {
        if (!$machine.InMaintenanceMode)
        {
            $tempWorkingSet += $machine
        }
    }
    return $tempWorkingSet
}
