$today = Get-Date -Format "yyyy-MM-dd"

$SWITCH_PARITY = $false
$SKIP_MACHINES_IN_MAINTENANCE = $true
$LOG_FILE_LOCATION_AND_NAME = "C:\RebootScript\Logs\$MACHINE_CATALOG" + " Maintenance for $today.log"
$LOG_FILE_ENABLED = $true
$REBOOT_TIME_LIMIT = 130                     # In Minutes
$IDLE_SESSION_TIME_LIMIT = 30                # In Minutes
$SLEEP_TIME_BETWEEN_CYCLES = 120             # In Seconds
$MAINTENANCE_CYCLE_FINAL_WARNING_TIME_LIMIT = 300
$MAINTENANCE_CYCLE_FORCE_LOGOFF_TIME_LIMIT = 315
$MAINTENANCE_CYCLE_FORCE_REBOOT_TIME_LIMIT = 330
$MAINTENANCE_CYCLE_FORCE_END_MAINT_MODE_TIME_LIMIT = 345
$MAINTENANCE_CYCLE_FORCE_COMPLETION_TIME_LIMIT = 360
$MAINTENANCE_TITLE_MESSAGE = "Planned Maintenance"
$MAINTENANCE_MESSAGE = "Please logoff and relaunch all of your applications."
$MAINTENANCE_TITLE_MESSAGE_FORCE_LOGOFF_WARNING = "Final Notification"
$MAINTENANCE_MESSAGE_FORCE_LOGOFF_WARNING = "Your session will end shortly, please save your work and logoff."
$SA_DATE = @{
    Day     = 18
    Month   = 12 
    Year    = 2012
    Hour    = 0
    Minute  = 0
    Second  = 0
}
