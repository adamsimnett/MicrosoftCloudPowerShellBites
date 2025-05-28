function Connect-AzurePwsh {
    param (
        [int]$maxRetries = 3,
        [int]$delaySeconds = 5,
        [string]$tenantId,
        [string]$subscriptionId
    )

    $retryCount = 0
    $connectionAchieved = $false
    $errorLog = @()

    while (-not $connectionAchieved -and $retryCount -lt $maxRetries) {
        try {
            Write-Host "Attempting to connect to Azure... (Try $($retryCount + 1)/$maxRetries)" -ForegroundColor Cyan

            if ($tenantId -or $subscriptionId) {
                $null = Connect-AzAccount -TenantID $tenantId -Subscription $subscriptionId -ErrorAction Stop
            } else {
                $null = Connect-AzAccount -ErrorAction Stop
            }
            

            # Run context command to check auth has succeeded, return info if it has            
            $context = Get-AzContext
            if ($context -and $context.Account) {
                Write-Host "Successfully connected as $($context.Account)" -ForegroundColor Green
                $connectionAchieved = $true
            } else {
                throw "Authentication to Azure failed!"
            }
        } catch {
            
            # Increase retry counter, format error message and attach to the attempt count
            $retryCount++
            $errorMessage = "[$(Get-Date -Format 's')] Login attempt $retryCount failed: $_"
            
            #Append error message to error log
            $errorLog += $errorMessage

            Write-Warning $errorMessage

            if ($retryCount -lt $maxRetries) {
                Write-Host "Retrying in $delaySeconds seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $delaySeconds
            }
        }
    }

    # Collate and display error messages if authentication fails
    if (-not $connectionAchieved) {
        Write-Error "Failed to authenticate to Azure after $maxRetries attempts."
        $errorMessages | ForEach-Object { Write-Error $_ }
        throw "Azure authentication failed. See error messages above."
    }
}