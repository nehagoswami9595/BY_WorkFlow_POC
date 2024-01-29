
# Function to Get the CPU unit details according to VM Size - Start
function Get-VirtualMachineCPU {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [guid]$PrimarySubscriptionId,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$PrimaryResourceGroup

    )
    
    begin {
        ## Validating Loging Switch.
        $MessageLogging = $ENV:MESSAGE_LOGGING
        if ($MessageLogging -eq $True) {             
            Write-Output -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Output "Printing received parameters..."
            Write-Output $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }

        ## Checking and Selecting Subscription
        try { 
            $GetSubscriptionContext = (Get-AzContext -ErrorAction Stop).Subscription.Id
            if($GetSubscriptionContext -eq $PrimarySubscriptionId)
            {
                if ($MessageLogging -eq $True) {
                    Write-Output " Current Context is matching with required subscription, no need to change subscription!"
                }
            }
            else {
                if ($MessageLogging -eq $True) {
                    Write-Output " Selecting the subscription..."
                }
                try{
                Select-AzSubscription -Subscription $PrimarySubscriptionId -ErrorAction Stop | Out-Null 
                }
                catch {                       
                    Write-Output "Encountered Error while selecting subscription! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
                    throw
                }
            }                
        } 
        catch {                       
            Write-Output "Encountered Error while checking current context! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
            throw
        } 
    }
    
    process {
        #Get All VMs from Primary RG
        if ($MessageLogging -eq $True) {
            Write-Output "Getting all Virtual machines from Primary RG."
        }

        try { 
            $GetAllVMs = Get-AzVM -ResourceGroupName $PrimaryResourceGroup -ErrorAction Stop
        } 
        catch {                       
            Write-Output "Encountered Error while fetching all Virtual machines from Primary RG.! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
            throw
        }

        ## Fetching CPU unit for all Virtual Machines
        try {
            $VMObject = @()                    
            foreach ($SingleVM in $GetAllVMs) {
                $VirtualMachineName = $SingleVM.Name
                Write-Output "Fetching CPU unit for $VirtualMachineName"
                $VirtualMachineLocation = $SingleVM.Location
                $Size = $SingleVM.HardwareProfile.VmSize                        
                $vCPU = (Get-AzVMSize -location $VirtualMachineLocation | Where-Object { $_.name -eq $Size } -ErrorAction Stop ).NumberOfCores 
                $VMObject += New-Object psobject -Property @{                    
                    VirtualMachineSize = $Size
                    vCPU               = $vCPU                 
                }                    
            }
        }  
        catch {                       
            Write-Output "Encountered Error while fetching CPU unit for Virtual machines! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
            throw
        } 

        try {
            $VMCPUObject = @()
            $AllVMData = $VMObject | Group-Object VirtualMachineSize
            foreach ($SingleInstance in $AllVMData ) {
                $Size = $SingleInstance.Name
                [int]$Count = $SingleInstance.Count
                [int]$Cores = ($SingleInstance.Group | Select-Object -First 1).vCPU
                [int]$TotalUnit = $count * $Cores
                $VMSize = ((Get-AzComputeResourceSku -Location $SingleVM.Location | where ResourceType -eq "virtualMachines") | Where-Object { $_.Name -eq $Size }).Family                   
                $VMCPUObject += New-Object psobject -Property @{                    
                    Size          = $VMSize
                    NumberOfCores = $TotalUnit
                }
            }
        }  
        catch {                       
            Write-Output "Encountered Error while creating data set according to VM Size! Filename:$($MyInvocation.MyCommand.Name), Line:" $_.InvocationInfo.ScriptLineNumber ", Exception:"$_.Exception.Message                    
            throw
        }  
    }
    
    end { 
        if ($VMCPUObject.count -gt 0) {
            if ($MessageLogging -eq $True) {
                Write-Output "Dataset has been created according to VM Size!" $VMCPUObject
            }
            $Result = $true
        }
        else {
            if ($MessageLogging -eq $True) {
                Write-Output "Dataset has not been created according to VM Size!" $VMCPUObject
            }
            $Result = $false
        }
        return $Result, $VMCPUObject       
    }
}
# Function to Get the CPU unit details according to VM Size - End

# Function to Get the quota limit of a resource - Start
function Get-SubscriptionQuotaLimit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [guid]$SecondarySubscriptionId,

        [Parameter(Mandatory = $True)]
        [ValidatePattern('Microsoft.\s*\w*')]
        [string]$ResourceProviders, 

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$QuotaName,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$SecondaryLocation

    )
    
    begin {
        ## Validating Loging Switch.
        $MessageLogging = $ENV:MESSAGE_LOGGING
        if ($MessageLogging -eq $True) {             
            Write-Output -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Output "Printing received parameters..."
            Write-Output $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }

        # fetch az access token
        if ($MessageLogging -eq $True) {
            Write-Output "Fetching az access token!!"
        }
        try {
            $AzAccessToken = (Get-AzAccessToken -ErrorAction Stop).Token
        }
        catch {
            Write-Output -ForegroundColor Red "Failed to fetch az access token." $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
        }
    }
    
    process {
            
        #Prepare authentication headers
        if ($MessageLogging -eq $True) {
            Write-Output "Preparing authentication headers..."
        }
        $AuthenticationHeaders = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer" + " " + $AzAccessToken
        }

        # build uri variable
        if ($MessageLogging -eq $True) {
            Write-Output "Constructing rest api uri..."
        }            
            
        $UriData = "https://management.azure.com/subscriptions/" + $SecondarySubscriptionId + "/providers/" + $ResourceProviders + "/locations/" + $SecondaryLocation + "/providers/Microsoft.Quota/quotas/" + $QuotaName
        $ApiVersion = "?api-version=2023-02-01"
        $ApiUri = $UriData + $ApiVersion
            
        # Fetch Network details
        if ($ENV:MESSAGE_LOGGING -eq $True) {
            Write-Output "Invoking REST API..."   
        }

        # Invoking REST API
        try {
            $WebRequest = Invoke-WebRequest -Uri $ApiUri -Headers $AuthenticationHeaders -UseBasicParsing -Method Get -ErrorAction Stop
            $WebResponse = ((($WebRequest.Content | ConvertFrom-Json -ErrorAction Stop).properties).limit).value
        }
        catch {
            Write-Output -ForegroundColor Red "Failed to invoke the web request on the rest api.`n" $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
        }          
    }
    
    end { 
        
        # Validate if the NSG data has been exported the JSON File
        if ($WebResponse -ge 0) {
            if ($MessageLogging -eq $True) {
                Write-Output  "Quota Limit has been fetched for $QuotaName, $WebResponse" 
            }
            $Result = $true       
        }
        else {
            if ($MessageLogging -eq $True) {
                Write-Output  "Quota Limit has not been fetched for $QuotaName, $WebResponse"                     
            } 
            throw
            $Result = $false 
        } 
        return $Result , $WebResponse 
    }
}
# Function to Get the quota limit of a resource - End


# Function to get the current usage of a resource - Start
function Get-SubscriptionUsage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [guid]$SecondarySubscriptionId,

        [Parameter(Mandatory = $True)]
        [ValidatePattern('Microsoft.\s*\w*')]
        [string]$ResourceProviders,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$QuotaName,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$SecondaryLocation

    )
    
    begin {
        ## Validating Loging Switch.
        $MessageLogging = $ENV:MESSAGE_LOGGING
        if ($MessageLogging -eq $True) {             
            Write-Output -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Output "Printing received parameters..."
            Write-Output $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }

        # fetch az access token
        if ($MessageLogging -eq $True) {
            Write-Output "Fetching az access token!!"
        }
        try {
            $AzAccessToken = (Get-AzAccessToken -ErrorAction Stop).Token
        }
        catch {
            Write-Output -ForegroundColor Red "Failed to fetch az access token." $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
        }
    }
    
    process {
            
        #Prepare authentication headers
        if ($MessageLogging -eq $True) {
            Write-Output "Preparing authentication headers..."
        }
        $AuthenticationHeaders = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer" + " " + $AzAccessToken
        }

        # build uri variable
        if ($MessageLogging -eq $True) {
            Write-Output "Constructing rest api uri..."
        }            
            
        $UriData = "https://management.azure.com/subscriptions/" + $SecondarySubscriptionId + "/providers/" + $ResourceProviders + "/locations/" + $SecondaryLocation + "/providers/Microsoft.Quota/usages/" + $QuotaName
        $ApiVersion = "?api-version=2023-02-01"
        $ApiUri = $UriData + $ApiVersion
            
        # Fetch Network details
        if ($ENV:MESSAGE_LOGGING -eq $True) {
            Write-Output "Invoking REST API..."   
        }

        # Invoking REST API
        try {
            $WebRequest = Invoke-WebRequest -Uri $ApiUri -Headers $AuthenticationHeaders -UseBasicParsing -Method Get -ErrorAction Stop
            $WebResponse = ((($WebRequest.Content | ConvertFrom-Json -ErrorAction Stop).properties).usages).value
        }
        catch {
            Write-Output -ForegroundColor Red "Failed to invoke the web request on the rest api.`n" $($_.Exception | Out-String) $($_.InvocationInfo | Out-String); throw
        }          
    }
    
    end { 
        
        # Validate if the NSG data has been exported the JSON File
        if ($WebResponse -ge 0) {
            if ($MessageLogging -eq $True) {
                Write-Output  "Usage has been fetched for $QuotaName, $WebResponse" 
            }
            $Result = $true       
        }
        else {
            if ($MessageLogging -eq $True) {
                Write-Output  "Usage has not been fetched for $QuotaName, $WebResponse"                     
            } 
            throw
            $Result = $false 
        } 
        return $Result , $WebResponse 
    }
}
# Function to get the current usage of a resource - End


# Function to Validate diff resorces - Start
function Get-AvailableLimit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [guid]$PrimarySubscriptionId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$PrimaryResourceGroup,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [guid]$SecondarySubscriptionId,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$SecondaryLocation,

        [Parameter(Mandatory = $True)]
        [ValidatePattern('Microsoft.\s*\w*')]
        [string]$ResourceProviders,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$QuotaName
    )
    
    begin {
        ## Validating Loging Switch.
        $MessageLogging = $ENV:MESSAGE_LOGGING
        if ($MessageLogging -eq $True) {             
            Write-Output -ForegroundColor Blue "`n`"$($MyInvocation.MyCommand.Name)`" function has started..." 
            # print passed parameters
            Write-Output "Printing received parameters..."
            Write-Output $($($MyInvocation.BoundParameters | Out-String) -replace "`n$") 
        }
    }
    
    process {
        ## Validate NIC, storage accounts Limit 
        if ($QuotaName -in ("networkInterfaces", "storageAccounts")) {
            if ($MessageLogging -eq $True) {
                Write-Output "Start checking available quota for $($QuotaName)"
            } 

            $GetQuota = Get-SubscriptionQuotaLimit -SecondarySubscriptionId $SecondarySubscriptionId -ResourceProviders $ResourceProviders -QuotaName $QuotaName -SecondaryLocation $SecondaryLocation            
            $GetUsage = Get-SubscriptionUsage -SecondarySubscriptionId $SecondarySubscriptionId -ResourceProviders $ResourceProviders -QuotaName $QuotaName -SecondaryLocation $SecondaryLocation
            [int]$AvailableLimit = [int]$GetQuota[1] - [int]$GetUsage[1]

            ## Compare Primary and secondary Limit
            if ($AvailableLimit -gt 0) {
                 Write-Output "[$AvailableLimit] $($QuotaName) are available in secondary subscription."
                $Result = $true
            }
            else {                
                Write-Output "Available Limit[$AvailableLimit] in secondary subscription is less than 1 for $($QuotaName), can not proceed further."                
                $Result = $false
                throw
            }
        }

        ## Validate Virtual Machine Limit
        elseif ($PrimaryResourceGroup -and ($ResourceProviders -eq "Microsoft.Compute")) {
            if ($MessageLogging -eq $True) {
                Write-Output "Start checking available quota for $($ResourceProviders)"
            }

            $VMCPUData = Get-VirtualMachineCPU -PrimarySubscriptionId $PrimarySubscriptionId -PrimaryResourceGroup $PrimaryResourceGroup
            if ( $VMCPUData[0] -eq $true) {
                $VMQuotaNames = $VMCPUData[1]
                foreach ($VMQuotaName in $VMQuotaNames) {
                    if ($MessageLogging -eq $True) {
                        Write-Output "Checking Available Limit for:" $VMQuotaName.Size                        
                    }
                        
                    $GetQuota = Get-SubscriptionQuotaLimit -SecondarySubscriptionId $SecondarySubscriptionId -ResourceProviders $ResourceProviders -QuotaName $VMQuotaName.Size -SecondaryLocation $SecondaryLocation            
                    $GetUsage = Get-SubscriptionUsage -SecondarySubscriptionId $SecondarySubscriptionId -ResourceProviders $ResourceProviders -QuotaName $VMQuotaName.Size -SecondaryLocation $SecondaryLocation
                    [int]$AvailableLimit = [int]$GetQuota[1] - [int]$GetUsage[1]
                        
                    ## Compare Primary and secondary Limit
                    if ($VMQuotaName.NumberOfCores -gt $AvailableLimit) {                        
                            Write-Output "Available Limit[$AvailableLimit] in secondary subscription is less than utilised limit in Primary! Family:$($VMQuotaName.Size), Needed Core: $($VMQuotaName.NumberOfCores)."
                        $Result = $false
                        throw
                    }
                    else {                        
                            Write-Output "Available Limit[$AvailableLimit] in secondary subscription is greater than utilised limit in Primary! Family:$($VMQuotaName.Size), Needed Core: $($VMQuotaName.NumberOfCores)."
                        $Result = $true
                    }
                }
            }
        }

        else {
            if ($MessageLogging -eq $True) {
                Write-Output "Wrong Input received for $ResourceProviders, Please verify again"
            }
            throw
        }
    }
    
    end { 
        if ($MessageLogging -eq $True) {
            Write-Output "Validation has been done for $ResourceProviders"
        }  
        return $Result
    }
}
# Function to Validate diff resorces - End

