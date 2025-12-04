function Get-XbDVData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$TableName,   # use entity's plural name (EntitySetName) in URL, e.g., "accounts"
        [int]$BatchSize = 5000,                     # number of records per call (max 5000 per Dataverse API limit)
        [switch]$Parallel,                          # experimental parallel loading
        [int]$MaxRetries = 3,                       # max attempts on error (429/5xx)
        [string]$AccessToken                        # OAuth 2.0 Bearer token if required for REST call
    )
    # Prepare authorization header
    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) {
        $headers['Authorization'] = "Bearer $AccessToken"
    } else {
        Write-Verbose "No AccessToken provided - expecting existing auth context (e.g., Connect-PowerPlatform)."
    }

    # Build initial URL with $top (batch size) and optional query options
    $url = "$EnvironmentUrl/api/data/v9.2/$TableName`?`$top=$BatchSize"
    $allResults = @()
    $page = 1

    Write-Verbose "Retrieving data from $TableName with batch size $BatchSize..."
    do {
        $response = $null
        $attempt = 0
        # Retry logic
        while ($attempt -le $MaxRetries) {
            try {
                $response = Invoke-RestMethod -Method GET -Uri $url -Headers $headers -ErrorAction Stop
                break  # success - exit retry loop
            }
            catch {
                $attempt++
                # If HTTP 429 (too many requests) or 5xx error, wait and retry
                if ($_.Exception.Response -and ($_.Exception.Response.StatusCode -eq 429 -or ($_.Exception.Response.StatusCode -ge 500 -and $_.Exception.Response.StatusCode -lt 600))) {
                    # Extract Retry-After if available
                    $retryAfter = 5
                    if ($_.Exception.Response.Headers['Retry-After']) {
                        [int]$retryAfter = $_.Exception.Response.Headers['Retry-After']
                    }
                    else {
                        # no header - set generic wait time depending on status
                        if ($_.Exception.Response.StatusCode -eq 429) { $retryAfter = 10 }
                    }
                    Write-Warning "Received HTTP $($_.Exception.Response.StatusCode). Waiting $retryAfter sec before retry (attempt $attempt of $MaxRetries)..."
                    Start-Sleep -Seconds $retryAfter
                    continue
                }
                else {
                    # Other error - abort and throw
                    Throw "Data retrieval failed: $($_.Exception.Message)"
                }
            }
        }
        if (-not $response) { 
            Throw "Data retrieval failed after $MaxRetries attempts."
        }
        # Append retrieved records to total result
        $allResults += $response.value
        Write-Verbose "Page ${page}: Retrieved $($response.value.Count) records."

        # Get next link if available
        $url = $response.'@odata.nextLink'
        $page++
    } while ($url)

    Write-Verbose "Total records retrieved: $($allResults.Count)"
    return $allResults
}
Export-ModuleMember -Function Get-XbDVData

# Example: Retrieve all account records in batches of 1000 rows
# $accounts = Get-DVData -EnvironmentUrl "https://org.crm4.dynamics.com" -TableName "accounts" -BatchSize 1000
# "$($accounts.Count) records retrieved."
