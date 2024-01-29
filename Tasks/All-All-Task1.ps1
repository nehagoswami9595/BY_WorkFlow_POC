# parameters of caller script
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("PreFailoverValidation", "Failover", "DataSyncToPrimary", "PreFailbackValidation", "Failback", "DataSyncToDR", "PostFailbackValidation")]
    [System.String]$DRPhase,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Get", "Update")]
    [System.String]$OperationType
)

Import-Module -Name .\Modules\Module14\ -Force 
Import-Module -Name .\Modules\Module19\ -Force
#Import-Module -Name .\Modules\Module18\ -Force

$ENV:MESSAGE_LOGGING = $True
$ENV:RUN_ID = "0569392b97eb7d1060d352800153af87"
$ENV:CUSTOMER_NAME = "BYPOC"
$ENV:APPLICATION_NAME = "TMS"
$ENV:GITHUB_RUN_NUMBER = 45
$ENV:GITHUB_RUN_ATTEMPT = 3
$ENV:GITHUB_WORKFLOW_NAME = "wfname"
$ENV:JOB_NAME = "jobname"
$ModuleID = "10"
$TaskID = "yuh"

# Short assignments for environmental variables
$MessageLogging = $ENV:MESSAGE_LOGGING
$RunId = $ENV:RUN_ID
$CustomerName = $ENV:CUSTOMER_NAME
$GitHubWorkflowName = $ENV:GITHUB_WORKFLOW_NAME
$JobName = $ENV:JOB_NAME
$GitHubRunNumber = $ENV:GITHUB_RUN_NUMBER
$GitHubRunAttempt = $ENV:GITHUB_RUN_ATTEMPT
$ApplicationName = $ENV:APPLICATION_NAME


# ## Transcript Logging
# try {
#   Start-CustomTranscript -CustomerId $CustomerName -GitHubWorkflowName $GitHubWorkflowName -GitHubRunNumber $ENV:GITHUB_RUN_NUMBER -GitHubRunAttemptNumber $ENV:GITHUB_RUN_ATTEMPT -JobName $JobName
# }
# catch {
#   Write-Host -ForegroundColor Red "Failed to record the transcript logging.`n" $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
# }

# Message logging block
if ($MessageLogging -eq $True) {

  # inform that function has started
  Write-Host -ForegroundColor Magenta "`"$($MyInvocation.MyCommand.Name)`" task has started in `"$DRPhase`" mode..."

  # parse environmental variables
  Write-Host "Reading environmental variables..." 

  # all applicable environmental variables will be added here to inform what's being parsed
  Write-Host $($($([ordered]@{
                  "MESSAGE_LOGGING"                   = $MessageLogging
                  "RUN_ID"                            = $RunId
                  "MODULE_ID"                         = $ModuleID
                  "TASK_ID"                           = $TaskID
                  "GITHUB_WORKFLOW_NAME"              = $GitHubWorkflowName
                  "JOB_NAME"                          = $JobName
                  "APPLICATION_NAME"                  = $ApplicationName
              } | Format-Table -AutoSize -Force
          ) | Out-String
      ).TrimEnd()
  )

}
else {
  Write-Host "Message logging is not enabled."
}

switch ($DRPhase) {
    # perform PreFailoverValidation steps
    PreFailoverValidation {
                              ## Query the task
                              if($OperationType -eq "GET")
                              {
                              try{                                 
                                $GetSNOWTask = Get-SNOWTask -SNOWTaskID $RunId -ModuleID $ModuleID -TaskID $TaskID
                                }
                                catch {
                                    Write-Host -ForegroundColor Red "Failed to Get details for Task ID for `"$($RunId)`".`n" $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
                                }
                                
                                if($GetSNOWTask -eq $true)
                                {
                                  if ($MessageLogging -eq $True) {
                                    Write-Host "Successfully fetched the Task Details for $RunId"
                                  }
                                }
                                else {
                                  if ($MessageLogging -eq $True) {
                                    Write-Host "Details has not been fetched for $RunId"
                                  }
                                }

                              }

                              # ## Update the task
                              if($OperationType -eq "UPDATE")
                              {
                              try{                                 
                                $UpdateSNOWTask = Update-SNOWTask -SNOWTaskID $RunId -ModuleID $ModuleID -TaskID "All-All-Task1" -GitHubRunNumber $GitHubRunNumber -GitHubRunAttempt $GitHubRunAttempt -JobName $JobName -DRPhase $DRPhase -Message $Message
                              }
                                catch {
                                    Write-Host -ForegroundColor Red "Failed to Update for Task ID for `"$($RunId)`".`n" $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
                                }

                                if($UpdateSNOWTask -eq $true)
                                {
                                  if ($MessageLogging -eq $True) {
                                    Write-Host "Successfully updated the Task for $RunId"
                                  }
                                }
                                else {
                                  if ($MessageLogging -eq $True) {
                                    Write-Host "Comment has not been updated for $RunId"
                                  }
                                }
                              }
    }
}
