function Connect-ToAzure {
    param (
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )

    $retryCount = 0
    $connectionAchieved = $false
    $errorLog = @()

    while (-not $connectionAchieved -and $retryCount -lt $MaxRetries) {
        try {
            Write-Host "Attempting to connect to Azure... (Try $($retryCount + 1)/$MaxRetries)" -ForegroundColor Cyan
            $null = Connect-AzAccount -ErrorAction Stop
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

            if ($retryCount -lt $MaxRetries) {
                Write-Host "Retrying in $DelaySeconds seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    # Collate and display error messages if authentication fails
    if (-not $connectionAchieved) {
        Write-Error "Failed to authenticate to Azure after $MaxRetries attempts."
        $errorMessages | ForEach-Object { Write-Error $_ }
        throw "Azure authentication failed. See error messages above."
    }
}