# Function to generated Auth headers - Start
function New-AuthHeaders {

    [CmdletBinding()]
    param (          
          [Parameter(Mandatory = $True)]
          [ValidateSet("Get", "Put")]
          [string]$RequestType,

          [Parameter(Mandatory = $False)]
          [string]$FilePath = "Data\SnowCreds.json"
    )
    
    begin {
          ## Validating Loging Switch.
          $MessageLogging = $ENV:MESSAGE_LOGGING
          if ($MessageLogging -eq $True) {             
            Write-Host -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Host "Printing received parameters..."
            Write-Host $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }
        try {
            $GetFileData = (Get-Content -path $FilePath -ErrorAction Stop | convertfrom-json)
            $SNOWUsername = "drautomation_user"
            #$GetFileData.SNOW.Credentials.UserName
            $SNOWPassword = "6xp+J1,qXop?la"
            #$GetFileData.SNOW.Credentials.Password
        }
        catch { 
                Write-host "Encountered error while getting Data from Json within Module! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                       
                throw                
        }
    }
    
    process {
            # Build Authorization
            try{
            $Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $SNOWUsername, $SNOWPassword)))
            }
            catch {
                Write-host "Encountered Error while generating Auth Info! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message         
                throw
            }
  
            # Build headers          
            try{
              $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
              $Headers.Add('Authorization',('Basic {0}' -f $Base64AuthInfo))
              $Headers.Add('Accept','application/json')
                if($RequestType -eq "Put")
                {
                  $Headers.Add('Content-Type','application/json')
                }
              }
              catch {
                  Write-host "Encountered Error while generating Headers! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message         
                  throw
              }
    }
    
    end {
      if(($Headers) -and ($Base64AuthInfo)){
        if ($MessageLogging-eq $True) {
          Write-Host  "Headers have been genered Successfully" 
          } 
          $Result = $true 
      }
      else{
        if ($MessageLogging-eq $True) {
          Write-Host  "Headers have not been genered Successfully" 
          }  
          $Result = $fasle
      }
      return $Result,$Headers
    }
  }
  # Function to generated Auth headers - End
  
  # Function to Query/Fetch a SC TasK - Start
  function Get-SNOWTask {
    [CmdletBinding()]
    param (
          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$SNOWTaskID,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$ModuleID,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$TaskID
    )
    
    begin {
          ## Validating Loging Switch.
          $MessageLogging = $ENV:MESSAGE_LOGGING
          if ($MessageLogging -eq $True) {             
            Write-Host -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Host "Printing received parameters..."
            Write-Host $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }
  
        # Fetchging Endpoint URI
        try { 
          $URL = Get-ValueFromJson -ModuleID $ModuleID -TaskID $TaskID -KeyName "SNOWURL"          
        } 
        catch {                       
            Write-host "Encountered Error while fetching keys from JSON! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
            throw
        }

        $URI = $URL + $SNOWTaskID
        $Method = "Get"
    }
    
    process {
            # Getting Headers
            try{
              $Headers = New-AuthHeaders -RequestType $Method
            }
            catch {
                Write-host "Encountered Error while generating Headers! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message         
                throw
            }
  
            # Query a Task          
            try{
              $Response = Invoke-WebRequest -Headers $Headers[1] -Method $Method -Uri $URI -ErrorAction Stop
              }
              catch {
                  Write-host "Encountered Error while fetching Task Details! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message         
                  throw
              }
    }
    
    end {
      if($Response.StatusCode -like "20*"){
        if ($MessageLogging-eq $True) {
          Write-Host  "Task Details have been fetched Successfully" 
          } 
          $Result = $true 
          $ResponseResult = ($Response.Content | Convertfrom-Json).result
      }
      else{
        if ($MessageLogging-eq $True) {
          Write-Host  "Task Details have not been fetched Successfully" 
          }  
          $Result = $fasle
      }
      return $Result,$ResponseResult
    }
  }
  # Function to Query/Fetch a SC TasK - End
  
  # Function to Update SC TasK - Start
  function Update-SNOWTask {
    [CmdletBinding()]
    param (          
          [Parameter(Mandatory = $true)]
          [ValidateNotNullOrEmpty()]
          [string]$SNOWTaskID,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$ModuleID,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$TaskID,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$GitHubRunNumber,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$GitHubRunAttempt,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$JobName,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$DRPhase,

          [Parameter(Mandatory = $True)]
          [ValidateNotNullOrEmpty()]
          [string]$Message
          
    )
    
    begin {
          ## Validating Loging Switch.
          $MessageLogging = $ENV:MESSAGE_LOGGING
          if ($MessageLogging -eq $True) {             
            Write-Host -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Host "Printing received parameters..."
            Write-Host $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }
  
            # Fetchging Endpoint URI
            try { 
              $URL = Get-ValueFromJson -ModuleID $ModuleID -TaskID $TaskID -KeyName "SNOWURL"          
            } 
            catch {                       
                Write-host "Encountered Error while fetching keys from JSON! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
                throw
            }
            
            $URI = $URL + $SNOWTaskID
            $Method = "put"
    }
    
    process {
            # Getting Headers
            try{
              $Headers = New-AuthHeaders -RequestType $Method
            }
            catch {
                Write-host "Encountered Error while generating Headers! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message         
                throw
            }
  
            # Update a Task          
            try{
              # Specify request body
              $Body = "{`"comments`":`"Phase: $DRPhase, $Message!! JobName: $JobName, RunNumber: $GitHubRunNumber, Attempt: $GitHubRunAttempt.`"}"
              #$Body = "{`"work_notes`":`"Update worknotes for $SNOWTaskID`",`"comments`":`"Update worknotes for $SNOWTaskID`"}" #body should cover all details wrt RUN.
              $Response = Invoke-WebRequest -Headers $Headers[1] -Method $Method -Uri $URI -Body $Body -ErrorAction Stop
              $Response.Result
              }
              catch {
                  Write-host "Encountered Error while updating Task Comments/Worknotes! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message         
                  throw
              }
    }
    
    end {
      if($Response.StatusCode -like "20*"){
        if ($MessageLogging-eq $True) {
          Write-Host  "Task has been updated Successfully, Task id:" $SNOWTaskID
          } 
          $Result = $true 
      }
      else{
        if ($MessageLogging-eq $True) {
          Write-Host  "Task has not been updated Successfully, Task id:" $SNOWTaskID
          }  
          $Result = $fasle
      }
      return $Result,$Response.StatusCode
    }
  }
  # Function to Update SC TasK - End
