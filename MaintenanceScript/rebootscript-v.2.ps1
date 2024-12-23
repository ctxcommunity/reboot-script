param (
    [Parameter (Mandatory = $true)] [String]$MachineCatalog = $null
)

$MACHINE_CATALOG = $MachineCatalog

. .\preferences.ps1
. .\functions\maint_script_general.ps1
. .\functions\maint_script_citrix.ps1
. .\functions\messages.ps1

Write-Output $MACHINE_CATALOG

if ($LOG_FILE_ENABLED) { Out-File -FilePath $LOG_FILE_LOCATION_AND_NAME -InputObject "" -NoNewline }

Out-Message -Message "Start of Maintenance Script"
$startTime = Get-Date
$fixedDate = Get-Date @SA_DATE
$timeSpan = New-TimeSpan -Start $fixedDate -End $startTime

$parityOffset = 0
if ($SWITCH_PARITY) { $parityOffset = 1 }
$parityforToday = ($timeSpan.days + $parityOffset) % 2

$machines = Get-BrokerMachine -CatalogName $MACHINE_CATALOG

$machineWorkingSet = @()

if ($parityforToday) {
    Out-Message -Message "Working set will consist of " -MessagePartTwo "Odd" -MessagePartThree " numbered machines"
    $machineWorkingSet = Get-MachinesbyParity -Machines $machines -Parity Odd
} else {
    Out-Message -Message "Working set will consist of " -MessagePartTwo "Even" -MessagePartThree " numbered machines"
    $machineWorkingSet = Get-MachinesbyParity -Machines $machines -Parity Even
}

if ($SKIP_MACHINES_IN_MAINTENANCE) {
    Out-Message -Message "Prune work list of machines currently in maintenance mode"
    $machineWorkingSet = Remove-MachinesinMaintenanceModefromWorkingSet -WorkingSet $machineWorkingSet
}

if ($machineWorkingSet.Count -eq 0) {
    Out-Message -Message 'Nothing to do - The working set is empty. ' -MessagePartTwo "Exiting."
    Exit                                #No work to do.  Need a better exit strategy
}

#Build a tracking WorkingSet to track the progress of a machine through the maintenance cycle
$progressWorkingSet = @{}
foreach ($machine in $machineWorkingSet) {
    $progressWorkingSet[$machine.HostedMachineName] = @{
        nextTask                    = 'Enable Maintenance Mode'
        maintenanceComplete         = $false
        logoffWarningComplete       = $false
        logoffSessionsComplete      = $false
        rebootComplete              = $false
        enableMaintModeComplete     = $false
    }
}

$logoffWarning = $false
$logoff = $false
$reboot = $false
$exitMaintMode = $false
$forceCompletion = $false

$loopCount = 0

#Loop while there are machines that still have tasks to complete or time expiry
Do {
    $loopCount++
    Out-Message -Message "Start of maintenance cycle loop " -MessagePartTwo $loopCount
    Out-Message -Message "Start of cycle sleep for " -MessagePartTwo $SLEEP_TIME_BETWEEN_CYCLES -MessagePartThree " Seconds"
    Start-Sleep -Seconds $SLEEP_TIME_BETWEEN_CYCLES 
    $areMachinesStillinMaintenance = $false
    foreach ($machine in $machineWorkingSet) {
        $progressforMachine = $progressWorkingSet[$machine.HostedMachineName]
        
        if ($progressforMachine.maintenanceComplete -eq $false) {
            Out-Message -Message "  Processing Machine: " -MessagePartTwo $machine.HostedMachineName -NoNewLine

            if (($logoffWarning) -and ($progressforMachine.logoffWarningComplete -eq $false)) {
                Out-Message -Message ". Force logoff warning time has been reached." -NoNewLine -NoDateTime
                $progressforMachine.nextTask = 'Send Final Warning Message'
            }
            if (($logoff) -and ($progressforMachine.logoffSessionsComplete -eq $false)) {
                Out-Message -Message ". Force logoff all sessions time has been reached." -NoNewLine -NoDateTime
                $progressforMachine.nextTask = 'Logoff All Sessions'
            }
            if (($reboot) -and ($progressforMachine.rebootComplete -eq $false)) {
                Out-Message -Message ". Force reboot of machine time has been reached." -NoNewLine -NoDateTime
                $progressforMachine.nextTask = 'Reboot Machine'
            }
            if (($exitMaintMode) -and ($progressforMachine.enableMaintModeComplete -eq $false)) {
                Out-Message -Message ". Force exit of maintenance mode time has been reached." -NoNewLine -NoDateTime
                $progressforMachine.nextTask = 'Exit Maintenance Mode'
            }
            Out-Message -Message ". Next task to be performed: " -MessagePartTwo $progressforMachine.nextTask -NoDateTime

          $areThereActiveSessions = Test-ActiveSessions -Machine $machine
          $areThereDisconnectedSessions = Test-DisconnectedSessions -Machine $machine

          Switch ($progressforMachine.nextTask) {
              'Enable Maintenance Mode'       { Out-Message -Message "        " -MessagePartTwo "Enabling Maintenance Mode "
                                                Enable-MaintenanceMode -Machine $machine
                                                $progressforMachine.nextTask = 'Send Message to Users'; break
                                              }
              'Send Message to Users'         { if ($areThereActiveSessions) {
                                                  Out-Message -Message "        " -MessagePartTwo "Active sessions detected-Sending active sessions a logoff message"
                                                  Send-UserMessage -Machine $machine -MessageStyle Exclamation -Title $MAINTENANCE_TITLE_MESSAGE -Message $MAINTENANCE_MESSAGE
                                                }
                                                $progressforMachine.nextTask = 'Drain Sessions'; break 
                                              }
              'Drain Sessions'                { if ($areThereActiveSessions -or $areThereDisconnectedSessions) {
                                                    Out-Message -Message "        " -MessagePartTwo "Draining sessions-Logoff any disconnected or idle sessions"
                                                    Invoke-LogoffDisconnectedSessions -Machine $machine
                                                    Invoke-LogoffIdleSessions -Machine $machine
                                                } else {
                                                    Out-Message -Message "        " -MessagePartTwo "Draining sessions-No more active sessions to drain"
                                                    $progressforMachine.nextTask = 'Reboot Machine'
                                                }; break 
                                              }
              'Send Final Warning Message'    { if ($areThereActiveSessions) {
                                                    Out-Message -Message "        " -MessagePartTwo "Active sessions detected-Sending active sessions final logoff message"
                                                    Send-UserMessage -Machine $machine -MessageStyle Critical -Title $MAINTENANCE_TITLE_MESSAGE_FORCE_LOGOFF_WARNING -Message $MAINTENANCE_MESSAGE_FORCE_LOGOFF_WARNING
                                                }
                                                $progressforMachine.logoffWarningComplete = $true
                                                $progressforMachine.nextTask = 'Drain Sessions'; break 
                                              }
              'Logoff All Sessions'           { Out-Message -Message "        " -MessagePartTwo "Force logoff of all remaining sessions"
                                                Invoke-LogoffAllSessions -Machine $machine
                                                $progressforMachine.logoffSessionsComplete = $true  
                                                $progressforMachine.nextTask = 'Reboot Machine'; break
                                              }
              'Reboot Machine'                { Out-Message -Message "        " -MessagePartTwo "Rebooting Machine"
                                                Restart-Machine -Machine $machine
                                                $progressforMachine.nextTask = 'Check Reboot Status'; break 
                                              }
              'Check Reboot Status'           { Out-Message -Message "        " -MessagePartTwo "Checking Reboot Status" -NoNewLine
                                                $rebootConfirmation = Confirm-Reboot -Machine $machine
                                                if ($rebootConfirmation) {
                                                    Out-Message -Message "-" -MessagePartTwo "Machine detected after reboot" -NoDateTime
                                                    $progressforMachine.nextTask = 'Reboot Cycle Completed'
                                                } else {
                                                    Out-Message -Message "-" -MessagePartTwo "Reboot still progress" -NoDateTime
                                                }; break 
                                              }
              'Reboot Cycle Completed'        { Out-Message -Message "        " -MessagePartTwo "Reboot cycle completed"
                                                $progressforMachine.rebootComplete = $true
                                                $progressforMachine.nextTask = 'Exit Maintenance Mode'; break 
                                              }
              'Exit Maintenance Mode'         { Out-Message -Message "        " -MessagePartTwo "Exiting machine from maintenance mode"
                                                Exit-MaintenanceMode -Machine $Machine
                                                $progressforMachine.enableMaintModeComplete = $true
                                                Out-Message -Message "        " -MessagePartTwo "The maintenance cycle for this machine has completed"
                                                $progressforMachine.maintenanceComplete = $true; break 
                                              }
          }
        }
        
        if (($progressforMachine.maintenanceComplete -eq $false) -and ($areMachinesStillinMaintenance -eq $false)) {
            $areMachinesStillinMaintenance = $true
        }
    }

    #Check if limits have been reached. 
    #Action will process at the next cycle with expection of the Force Completion which will end the current cycle or
    #if limit was reached just as all machines completed their maintenance cycle
    
    $timeElapsedinMinutes = Get-ElapsedTimetoNow -Start $startTime 
    Out-Message -Message "Time elapsed since the maintenance script first started: " -MessagePartTwo $timeElapsedinMinutes
    if ($areMachinesStillinMaintenance) { 
        Out-Message -Message "There are still machines in maintenance mode" 
    } else {
        Out-Message -Message "All machines in the working set have completed their maintenance cycle" 
    }
    $repeatLoop = $areMachinesStillinMaintenance
    $forceCompletion = $timeElapsedinMinutes -ge $MAINTENANCE_CYCLE_FORCE_COMPLETION_TIME_LIMIT
    if ($forceCompletion) {
        Out-Message -Message -Message "!!!" -MessagePartTwo "This maintenance cycle has reached its time limited and will be force to complete" -MessagePartThree "!!!"
        $repeatLoop = $false
    }
        
    switch ($false) {
        $repeatLoop             { break }
        $logoffWarning          { $logoffWarning = $timeElapsedinMinutes -ge $MAINTENANCE_CYCLE_FINAL_WARNING_TIME_LIMIT
                                  if ($logoffWarning) { 
                                    Out-Message -Message -Message "!!!" -MessagePartTwo "This maintenance cycle has reached a time limited to warn users of pending logoff" -MessagePartThree "!!!"
                                  }; break
                                }
        $logoff                 { $logoff = $timeElapsedinMinutes -ge $MAINTENANCE_CYCLE_FORCE_LOGOFF_TIME_LIMIT
                                  if ($logoff) { 
                                    Out-Message -Message -Message "!!!" -MessagePartTwo "This maintenance cycle has reached a time limited to logoff all remaining sessions" -MessagePartThree "!!!"
                                  }; break
                                }
        $reboot                 { $reboot = $timeElapsedinMinutes -ge $MAINTENANCE_CYCLE_FORCE_REBOOT_TIME_LIMIT
                                  if ($reboot) { 
                                    Out-Message -Message -Message "!!!" -MessagePartTwo "This maintenance cycle has reached a time limited to reboot all machines" -MessagePartThree "!!!"
                                  }; break
                                }
        $exitMaintMode          { $exitMaintMode = $timeElapsedinMinutes -ge $MAINTENANCE_CYCLE_FORCE_END_MAINT_MODE_TIME_LIMIT
                                  if ($exitMaintMode) { 
                                    Out-Message -Message -Message "!!!" -MessagePartTwo "This maintenance cycle has reached a time limited to exit maintenance mode for all machines" -MessagePartThree "!!!"
                                  }; break
                                }
    }
} while ($repeatLoop)
Out-Message -Message "Maintenance Cycle Complete "
