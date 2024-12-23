switch ($null) {
    $REBOOT_TIME_LIMIT      { $REBOOT_TIME_LIMIT   = 130 }
}

function Get-ElapsedTimetoNow {
    param (
        [Parameter(Mandatory = $true)] [datetime]$Start
    )

    $currentTime = Get-Date
    $timeSpan = New-TimeSpan -Start $Start -End $currentTime
    $elapsedTimetoNow = ($timeSpan.Days * 1440) + ($timeSpan.Hours * 60) + $timeSpan.Minutes

    return $elapsedTimetoNow
}

function Get-MachineParity {
    param (
        [Parameter(Mandatory = $true)] [string]$Name
    )
    $parity = $Name.SubString($Name.Length - 1) % 2
    return $parity
}

function Restart-Machine {
    param (
        [Parameter(Mandatory)] $Machine
    )

    Restart-Computer -ComputerName $Machine.HostedMachineName -force
}

function Confirm-Reboot {
    param (
        [Parameter(Mandatory)] $Machine
    )

    $rebootConfirmation = $false
    $result = Get-WMIObject -ComputerName $machine.HostedMachineName -ClassName Win32_OperatingSystem -EA Ignore | Select-Object @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.LastBootUpTime)}}
    if ($result) {
        $timeElapsedinMinutes = Get-ElapsedTimetoNow -Start $result.LastBootUpTime
        if ($timeElapsedinMinutes -le $REBOOT_TIME_LIMIT) {
            $rebootConfirmation = $true
        }
    }

    return $rebootConfirmation
}

function Get-MachinesbyParity {
    param (
        [Parameter(Mandatory)] $Machines,
        [Parameter(Mandatory)] [ValidateSet("Odd","Even", IgnoreCase = $true)]$Parity
    )

    $listofMachines = @()
    foreach ($machine in $machines) {
        $machineParity = Get-MachineParity -Name $machine.HostedMachineName

        if ($Parity -eq 'odd') {
            if ($machineParity) {
                $listofMachines += $machine
            }
        } else {
            if (!$machineParity) {
                $listofMachines += $machine
            }
        }
    }
    return $listofMachines
}
