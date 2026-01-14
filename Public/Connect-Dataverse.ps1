# Heritage: formerly XB-DataverseTools (NexaBlue)
function Connect-Dataverse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentUrl
    )

<#
.SYNOPSIS
    Authenticates to a Dataverse environment and returns a plain text access token.

.DESCRIPTION
    Connects to Azure using Connect-AzAccount, retrieves an access token for the specified
    Dataverse environment, and converts it from SecureString to plain text for use with
    other DataverseCmdlets functions.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.EXAMPLE
    $token = Connect-Dataverse -EnvironmentUrl "https://org.crm4.dynamics.com"

.OUTPUTS
    System.String
    Returns a plain text OAuth 2.0 bearer token.
#>

    # Validate EnvironmentUrl format
    if ($EnvironmentUrl -notmatch '^https:\/\/[\w-]+\.crm\d*\.dynamics\.com\/?$') {
        Write-Host ""
        Write-Host "Invalid Environment URL" -ForegroundColor Red
        Throw "Invalid EnvironmentUrl format. Please provide a valid Dataverse environment URL."
    }

    # Check if Az.Accounts is available
    try {
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Throw "Az.Accounts module is not installed."
        }
    }
    catch {
        throw
    }

    # Import Az.Accounts if not already loaded
    try {
        if (-not (Get-Module -Name Az.Accounts)) {
            Import-Module Az.Accounts -ErrorAction Stop
        }
    }
    catch {
        Throw "Failed to import Az.Accounts module: $($_.Exception.Message)"
    }

    Write-Host "Connecting to $EnvironmentUrl..." -ForegroundColor Cyan

    # Connect to Azure with the correct auth scope
    try {
        $azContext = Connect-AzAccount -AuthScope $EnvironmentUrl -ErrorAction Stop
        if (-not $azContext) { Throw "Authentication was cancelled." }
    }
    catch {
        Throw "Azure authentication failed: $($_.Exception.Message)"
    }

    Write-Host "Retrieving access token for $EnvironmentUrl..." -ForegroundColor Cyan

    # Get the access token
    try {
        $secureToken = (Get-AzAccessToken -ResourceUrl $EnvironmentUrl -ErrorAction Stop).Token
    }
    catch {
        Throw "Failed to retrieve access token: $($_.Exception.Message)"
    }

    # Convert SecureString to plain text
    try {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    catch {
        Throw "Failed to convert token to plain text: $($_.Exception.Message)"
    }

    Write-Host "Successfully authenticated to $EnvironmentUrl" -ForegroundColor Green

    # Verify token by testing connection to Dataverse (optional)
    $headers = @{ 'Authorization' = "Bearer $token"; 'Accept' = 'application/json' }
    $testUrl = "$EnvironmentUrl/api/data/v9.2/WhoAmI"

    try {
        $whoAmIResponse = Invoke-RestMethod -Method GET -Uri $testUrl -Headers $headers -ErrorAction Stop
        Write-Host "Token verified successfully!" -ForegroundColor Green
    }
    catch {
        Write-Warning "Token verification failed: $($_.Exception.Message)"
        return $token
    }

    return $token
}
Export-ModuleMember -Function Connect-Dataverse
