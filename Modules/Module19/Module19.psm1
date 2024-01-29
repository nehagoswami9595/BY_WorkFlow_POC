## Function to Uplaod/Donwload Azure Blob on Azure Storage Account - Start
function DownloadUpload-Blob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [guid]$SubscriptionID,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BlobName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$BlobSourcePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageContainerName, 

        [Parameter(Mandatory = $True)]
        [ValidateSet("Upload", "Download")]
        [string]$OperationType, 

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$CustomerName
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

            ## Selecting Subscription -- make key generator as function
            try { 
                    Select-AzSubscription -Subscription $SubscriptionID -ErrorAction Stop | Out-Null     
            } 
            catch {                       
                    Write-host "Encountered Error while selecting subscription! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
                    throw
            
            } 

             ## Get account keys and generate Context
             try {
                $StorageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName  $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
            }
            catch {
                Write-host "Encountered Error while getting Storage Account Keys! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
                throw
            }
            if ($VERBOSE_LOGGING -eq $True) {
                Write-Host "Generating storage context with storage account key" $($StorageAccountKeys[0].KeyName)
            }              
            $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKeys[0].Value -Protocol Https 
            ## Validation over storage container ##var name is not correct
             try {
                $GetContainer = Get-AzStorageContainer -Name $StorageContainerName -context $StorageContext -ErrorAction Stop
            }
            catch {
                Write-host "Encountered Error while getting Storage container! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
                throw
            }
    }
    
    process {
    ## Upload the blob to Storage account  
        if ($OperationType -eq "Upload")  
        {
        try {
            $BlobOperation = Set-AzStorageBlobContent -File $BlobSourcePath -Container $StorageContainerName -Blob $BlobName  -Context $StorageContext -ErrorAction Stop -Force
            }
            catch {
                Write-host "Encountered Error while uploading file to storage! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message
                throw
            }
        }
        else
        {
            try {
                $DownloadPath = $env:TEMP+ "\" + $CustomerName + "\DRReports\" + $BlobName                
                $BlobOperation = Get-AzStorageBlobContent -Blob $BlobName -Container $StorageContainerName -Context $StorageContext -Destination $DownloadPath -Force
                }
                catch {
                    Write-host "Encountered Error while downloading blob from storage! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message ##trwo in case terminating error.
                    throw
                }
         }

    }
    
    end {

        if (($OperationType -eq "Upload") -or ($OperationType -eq "Download"))  
        {
            if($BlobOperation.Name -eq $BlobName)
            {
                if ($MessageLogging-eq $True) {
                    Write-Host  "Report $OperationType Done for File: $BlobName" 
                    }
                $Result = $true       
            }
            else {
                if ($MessageLogging-eq $True) {
                    Write-Host  "Report $OperationType failed for File: $BlobName" 
                    $BlobOperation.Name 
                    } 
                $Result = $false 
            } 
            
            }
        
        return $Result,$BlobName
    }
}
## Function to Uplaod Azure Blob on Azure Storage Account - End

# Function to get Value from Data.Json using a Key - Start
function Get-ValueFromJson {
    [CmdletBinding()]
    param (
                [Parameter(Mandatory = $False)]
                [string]$FilePath = "Data\Data.json",
        
                [Parameter(Mandatory = $True)]
                [string]$ModuleID,

                [Parameter(Mandatory = $True)]
                [ValidateNotNullOrEmpty()]
                [string]$TaskID,

                [Parameter(Mandatory = $True)]
                [ValidateNotNullOrEmpty()]
                [string]$KeyName
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
    }
    
    process {
                ##Fetching out the values using key
                if ($ENV:VERBOSE_LOGGING -eq $True) {
                    Write-Host "Fetching out the Key from Data.Json"
                    }
                     try {
                        $GetFileData = (Get-Content -path $FilePath -ErrorAction Stop | convertfrom-json)
                        $GetValue = $GetFileData.$ModuleID.$TaskID.$KeyName
                    }
                    catch { 
                            Write-host "Encountered error while getting Data from Json within Module! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                       
                            throw                
                    }
    }
    
    end { 
        if($GetValue)
        {
            if ($ENV:VERBOSE_LOGGING -eq $True) {
                Write-Host "Value successfully fetched of $KeyName from DataJson"
                }
        }
        else {
            if ($ENV:VERBOSE_LOGGING -eq $True) {
                Write-Host "Value not fetched for key: $KeyName from DataJson"
                }
        }
        return $GetValue
    }
}
# Function to get Value from Data.Json using a Key - End

# Function to get secret from Key vault - Start
function Get-KeyVaultSecret {
    [CmdletBinding()]
    param(
            [Parameter(Mandatory = $True)]
            [guid]$KeyVaultSubscriptionID,

            [Parameter(Mandatory = $True)]
            [ValidateNotNullOrEmpty()]
            [string]$SecretName,

            [Parameter(Mandatory = $True)]
            [ValidateNotNullOrEmpty()]
            [string]$KeyVaultName
    )
    
    begin {
             ## Validating Loging Switch.
             $MessageLogging = $ENV:MESSAGE_LOGGING
             if ($MessageLogging -eq $True) {             
             Write-Host -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
             Write-Host "Printing received parameters..."
             Write-Host $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
             }  
             
             ## Selecting Subscription
            try { 
                    Select-AzSubscription -Subscription $KeyVaultSubscriptionID -ErrorAction Stop | Out-Null     
            } 
            catch {                       
                    Write-host "Encountered Error while selecting subscription! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
                    throw
            } 
    }
    
    process {
                    try { 
                    $SecretValue = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText  -ErrorAction Stop   
                    } 
                    catch {
                    Write-host "Encountered Error while fetching secret! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message
                    throw
                    } 
            }
    
    end {
            if($SecretValue)
            {
            if ($ENV:VERBOSE_LOGGING -eq $True) {
                    Write-Host "Value successfully fetched from Keyvault, Secret:" $SecretName
                    }
                    $Result = $true
            }
            else {
            if ($ENV:VERBOSE_LOGGING -eq $True) {
                    Write-Host "Value not fetched from Keyvault, Secret:" $SecretName
                    }
                    $Result = $false
            }
            return $Result,$SecretValue                  
    }
}
# Function to get secret from Key vault - End
