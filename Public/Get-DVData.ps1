# Heritage: formerly XB-DataverseTools (NexaBlue)
function Get-DVData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$TableName,
        [int]$BatchSize = 5000,
        [switch]$Parallel,
        [int]$MaxRetries = 3,
        [string]$AccessToken
    )
    $headers = @{ Accept = 'application/json' }
    if ($AccessToken) { $headers['Authorization'] = "Bearer $AccessToken" }

    $url = "$EnvironmentUrl/api/data/v9.2/$TableName`?`$top=$BatchSize"
    $allResults = @()
    $page = 1

    do {
        $response = $null
        $attempt = 0
        while ($attempt -le $MaxRetries) {
            try {
                $response = Invoke-RestMethod -Method GET -Uri $url -Headers $headers -ErrorAction Stop
                break
            }
            catch {
                $attempt++
                if ($_.Exception.Response -and ($_.Exception.Response.StatusCode -eq 429 -or ($_.Exception.Response.StatusCode -ge 500 -and $_.Exception.Response.StatusCode -lt 600))) {
                    $retryAfter = 5
                    if ($_.Exception.Response.Headers['Retry-After']) { [int]$retryAfter = $_.Exception.Response.Headers['Retry-After'] }
                    else { if ($_.Exception.Response.StatusCode -eq 429) { $retryAfter = 10 } }
                    Write-Warning "Received HTTP $($_.Exception.Response.StatusCode). Waiting $retryAfter sec before retry (attempt $attempt of $MaxRetries)..."
                    Start-Sleep -Seconds $retryAfter
                    continue
                }
                else { Throw "Data retrieval failed: $($_.Exception.Message)" }
            }
        }
        if (-not $response) { Throw "Data retrieval failed after $MaxRetries attempts." }
        $allResults += $response.value
        Write-Verbose "Page ${page}: Retrieved $($response.value.Count) records."
        $url = $response.'@odata.nextLink'
        $page++
    } while ($url)

    Write-Verbose "Total records retrieved: $($allResults.Count)"
    return $allResults
}
Export-ModuleMember -Function Get-DVData

# Example: Retrieve all account records in batches of 1000 rows
# $accounts = Get-DVData -EnvironmentUrl "https://org.crm4.dynamics.com" -TableName "accounts" -BatchSize 1000
# "$($accounts.Count) records retrieved."
