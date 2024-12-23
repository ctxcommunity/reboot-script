switch ($null) {
    $PRIMARY_FOREGROUND_COLOR       { $PRIMARY_FOREGROUND_COLOR   = 'DarkCyan' }
    $PRIMARY_BACKGROUND_COLOR       { $PRIMARY_BACKGROUND_COLOR   = 'Black' }
    $SECONDARY_FOREGROUND_COLOR     { $SECONDARY_FOREGROUND_COLOR = 'DarkYellow'}
    $SECONDARY_BACKGROUND_COLOR     { $SECONDARY_BACKGROUND_COLOR = 'Black' }
    $MESSAGE_DATE_FORMAT            { $MESSAGE_DATE_FORMAT = 'yyyy-MM-dd HH:mm:ss' }
    $LOG_FILE_LOCATION_AND_NAME     { $LOG_FILE_LOCATION_AND_NAME = '.\reseal-script.log' }
    $LOG_FILE_ENABLED               { $LOG_FILE_ENABLED = $false }
}

function Out-Message {
    param (
        [Parameter (Mandatory = $false)] [String]$Message = "",
        [Parameter (Mandatory = $false)] [String]$MessagePartTwo = "",
        [Parameter (Mandatory = $false)] [String]$MessagePartThree = "",
        [Parameter (Mandatory = $false)] [String]$PrimaryForegroundColor = $PRIMARY_FOREGROUND_COLOR,
        [Parameter (Mandatory = $false)] [String]$PrimaryBackgroundColor = $PRIMARY_BACKGROUND_COLOR,
        [Parameter (Mandatory = $false)] [String]$SecondaryForegroundColor = $SECONDARY_FOREGROUND_COLOR,
        [Parameter (Mandatory = $false)] [String]$SecondaryBackgroundColor = $SECONDARY_BACKGROUND_COLOR,
        [Parameter (Mandatory = $false)] [String]$MessageLevel = 'Normal',
        [Parameter (Mandatory = $false)] [switch]$NoNewLine = $false,
        [Parameter (Mandatory = $false)] [switch]$NoDateTime = $false
    )

    $messageDate = Get-Date -Format $MESSAGE_DATE_FORMAT

    Switch ($MessageLevel) {
        'Normal'    { if ($NoDateTime -eq $false) { Write-Host "[$messageDate][Normal ] " -ForegroundColor $SecondaryForegroundColor -BackgroundColor $SecondaryBackgroundColor -NoNewLine }
                      Write-Host $Message -ForegroundColor $PrimaryForegroundColor -BackgroundColor $PrimaryBackgroundColor -NoNewLine
                      Write-Host $MessagePartTwo -ForegroundColor $SecondaryForegroundColor -BackgroundColor $SecondaryBackgroundColor -NoNewLine
                      Write-Host $MessagePartThree -ForegroundColor $PrimaryForegroundColor -BackgroundColor $PrimaryBackgroundColor -NoNewLine:$NoNewLine
                    
                      if ($LOG_FILE_ENABLED) {
                        if ($NoDateTime -eq $false) { Out-File -FilePath $LOG_FILE_LOCATION_AND_NAME -InputObject "[$messageDate][Normal ] " -Append -NoNewLine }
                        Out-File -FilePath $LOG_FILE_LOCATION_AND_NAME -InputObject "$Message$MessagePartTwo$MessagePartThree" -Append -NoNewLine:$NoNewLine
                      }                    
                    }
        #     if ($MessageLevel -eq 'Normal') { 
        #         Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewLine:$NoNewLine }
        # }
        # 'Verbose' {
        #     if (($MessageLevel -eq 'Verbose') -or ($MessageLevel -eq 'Normal')) { Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewLine:$NoNewLine }
        # }
        # 'Debug' { 
        #     Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewLine:$NoNewLine
        #     break
        # }
        Default {}
    }
}
