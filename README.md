README.md

This script is designed reboot Citrix VDAs that operate in a 24/7 shop. It's based off odds and even numbered machine names.  If the machine name does not end in a numeric increment number the script would need to be modified to accomidate the machine catalog's naming scheme.

This reboot script is design to run from a Citrix Delivery Controller or from a utility server that has the Citrix PowerShell SDK installed.

What This Reboot Script Does
=============================
1) Determines weither it is an odd or even day (via algoritm)
2) Grabs a full list of VDAs from the select machine catalog
3) Builds the nightly working set by removing machine not in the set for that day (remove odd machines if it is an even day)
4) Removes, from the working set, any machines that are in maintenance mode
5) Puts the working set machines into maintenance mode
6) Sends a polite message to users to logoff and relaunch their desktop or applications
7) Waits for the machine to drain users
    Will logoff of inactive session (default 30 minutes) and disconnected sessions
8) Reboots the machine
9) Takes the machine out of mainteance mode

There are fail safes for aggressive end-users who do not wish to end their sessions.  After 6 hours (default) they will get another warning and then subsequently logged off 15 minutes later.

Note: Each machine in the working set is tracked seperately.  If VDA1 has 5 users and VDA2 has no users then VDA2 will proceed to the machine restart stage and then taken of maintenace mode while VDA1 is still in the process of draining user sessions.

Installation
=============
To install, simply copy contents of the RebootScript directory to C:\RebootScript
The folder location can be adjusted, however, the scheduled task (action) locations would also need to be updated.

Open up "Task Scheduler" from 

Under "Task Scheduler Library" select Import Task...

Browse to the C:\RebootScript\ folder and select "Maintenance Script - v1.1"

For the Name, add a dash "-" and the name of the Machine Catalog that this scheduled task instance will run against

Select Change User or Group
Browser or enter in the name of the Service Account that has permissions to a) run a scheduled task on the Delivery Controller and b) permissions to the Citrix VDAs.  This service account needs the permissions to enumerate the Citrix Machine Catalog, put VDAs in and out of maintenance mode, logoff user sessions, and restart the machines.

Under the "Actions" tab, highlight the "Start a program" entry under the Action column
Select Edit
In the "Add arguments (optional):" text box, scroll to the right and modify 'MachineCatalog' entry and replace it with the name of the machine catalog this instance of the maintenance script will service.  If the machine catalog name contains spaces then keep the name between the single quotes ''.  ie.  'This is my machine catalog'

Click OK when done

Task Scheduler will ask you to input the service account password

Repeat this process for any other Machine Catalogs you wish to reboot.

Logging
========
Log files are outputted to C:\RebootScript\Logs

They don't grow particularly large, however, you may want to occasionally trim/delete older ones after a while.

Configurable Items
===================

The C:\RebootScript\MaintenanceScript\preferences.ps1 file contains a list of configurable items:

If the reboot script determines that "today" is an odd day by you want it to be an even day then set:

$SWITCH_PARITY = $true

This is useful if migrating from a different odd/even reboot script and continuity is important.

If you want to include the day's odd or even machines in maintnance mode set this to $false
$SKIP_MACHINES_IN_MAINTENANCE = $true

Set a different location for the log file:
$LOG_FILE_LOCATION_AND_NAME = "C:\RebootScript\Logs\$MACHINE_CATALOG" + " Maintenance for $today.log"

Enable or disable logging:
$LOG_FILE_ENABLED = $true

Manipulate timeout values: (Everything, except for SLEEP_TIME_BETWEEN_CYCLES, is in minutes)
$REBOOT_TIME_LIMIT = 130                     # In Minutes
$IDLE_SESSION_TIME_LIMIT = 30                # In Minutes
$SLEEP_TIME_BETWEEN_CYCLES = 120             # In Seconds
$MAINTENANCE_CYCLE_FINAL_WARNING_TIME_LIMIT = 300
$MAINTENANCE_CYCLE_FORCE_LOGOFF_TIME_LIMIT = 315
$MAINTENANCE_CYCLE_FORCE_REBOOT_TIME_LIMIT = 330
$MAINTENANCE_CYCLE_FORCE_END_MAINT_MODE_TIME_LIMIT = 345
$MAINTENANCE_CYCLE_FORCE_COMPLETION_TIME_LIMIT = 360

Messages sent to the end users as part of the notification stages:
$MAINTENANCE_TITLE_MESSAGE = "Planned Maintenance"
$MAINTENANCE_MESSAGE = "Please logoff and relaunch all of your applications."
$MAINTENANCE_TITLE_MESSAGE_FORCE_LOGOFF_WARNING = "Final Notification"
$MAINTENANCE_MESSAGE_FORCE_LOGOFF_WARNING = "Your session will end shortly, please save your work and logoff."

The SA date is used to calculate if "today" is an odd or even date

$SA_DATE = @{
    Day     = 18
    Month   = 12 
    Year    = 2012
    Hour    = 0
    Minute  = 0
    Second  = 0
}




