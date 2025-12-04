function Connect-XbDataverse {
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
    other XB-DataverseTools functions.

.PARAMETER EnvironmentUrl
    The base URL of the Dataverse environment, e.g., "https://org.crm4.dynamics.com".

.EXAMPLE
    $token = Connect-XbDataverse -EnvironmentUrl "https://org.crm4.dynamics.com"

    Authenticates to the environment and returns a plain text access token.

.EXAMPLE
    $envUrl = "https://org.crm4.dynamics.com"
    $token = Connect-XbDataverse -EnvironmentUrl $envUrl
    Remove-XbDVTable -EnvironmentUrl $envUrl -TableLogicalName "new_test" -AccessToken $token

    Authenticates and then uses the token to delete a table.

.OUTPUTS
    System.String
    Returns a plain text OAuth 2.0 bearer token.

.NOTES
    Author      : Claude Code
    Version     : 1.0
    Date        : 2025-12-04
    License     : CC BY-NC-ND 4.0

    Requires Az.Accounts module to be installed:
    Install-Module -Name Az.Accounts -Scope CurrentUser

.LINK
    https://learn.microsoft.com/en-us/powershell/module/az.accounts/
#>

    # Validate EnvironmentUrl format
    if ($EnvironmentUrl -notmatch '^https:\/\/[\w-]+\.crm\d*\.dynamics\.com\/?$') {
        Write-Host ""
        Write-Host "Invalid Environment URL" -ForegroundColor Red
        Write-Host "-----------------------" -ForegroundColor Red
        Write-Host ""
        Write-Host "The URL '$EnvironmentUrl' is not a valid Dataverse environment URL." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Expected format:" -ForegroundColor Cyan
        Write-Host "  https://orgname.crm.dynamics.com" -ForegroundColor White
        Write-Host "  https://orgname.crm4.dynamics.com" -ForegroundColor White
        Write-Host "  https://orgname.crm11.dynamics.com" -ForegroundColor White
        Write-Host ""
        Throw "Invalid EnvironmentUrl format. Please provide a valid Dataverse environment URL."
    }

    # Check if Az.Accounts is available
    try {
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Write-Host ""
            Write-Host "Missing Required Module" -ForegroundColor Red
            Write-Host "-----------------------" -ForegroundColor Red
            Write-Host ""
            Write-Host "The Az.Accounts module is required but not installed." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To install, run:" -ForegroundColor Cyan
            Write-Host "  Install-Module -Name Az.Accounts -Scope CurrentUser" -ForegroundColor Green
            Write-Host ""
            Throw "Az.Accounts module is not installed."
        }
    }
    catch {
        if ($_.Exception.Message -notlike "*Az.Accounts module is not installed*") {
            Throw "Failed to check for Az.Accounts module: $($_.Exception.Message)"
        }
        throw
    }

    # Import Az.Accounts if not already loaded
    try {
        if (-not (Get-Module -Name Az.Accounts)) {
            Import-Module Az.Accounts -ErrorAction Stop
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($errMsg -like "*SerializationSettings*" -or $errMsg -like "*ResourceManagementClient*") {
             Write-Host ""
            Write-Host "Module Version Conflict" -ForegroundColor Red
            Write-Host "-----------------------" -ForegroundColor Red
            Write-Host ""
            Write-Host "Az.Accounts module version conflict detected." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To fix this issue, try:" -ForegroundColor Cyan
            Write-Host "  1. Update-Module Az.Accounts -Force" -ForegroundColor Green 
            Write-Host "  2. Restart PowerShell" -ForegroundColor Green
            Write-Host ""
            Write-Host "Or use Azure CLI instead:" -ForegroundColor Cyan
            Write-Host "  az login" -ForegroundColor Green
            Write-Host ""
            Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor DarkGray
            Write-Host ""
            Throw "Az.Accounts module version conflict."
        }
        Write-Host ""
        Write-Host "Module Import Failed" -ForegroundColor Red
        Write-Host "-----------------------" -ForegroundColor Red
        Write-Host ""
        Write-Host "Failed to import Az.Accounts module." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Error: $errMsg" -ForegroundColor DarkGray
        Write-Host ""
        Throw "Failed to import Az.Accounts module: $errMsg"
    }

    Write-Host "Connecting to $EnvironmentUrl..." -ForegroundColor Cyan

    # Connect to Azure with the correct auth scope
    try {
        $azContext = Connect-AzAccount -AuthScope $EnvironmentUrl -ErrorAction Stop
        if (-not $azContext) {
            Write-Host ""
            Write-Host "Authentication Cancelled" -ForegroundColor Red
            Write-Host "------------------------" -ForegroundColor Red
            Write-Host ""
            Write-Host "Azure authentication was cancelled or failed." -ForegroundColor Yellow
            Write-Host ""
            Throw "Authentication was cancelled."
        }
    }
    catch {
        $errMsg = $_.Exception.Message

        # Check for Az module version conflict during authentication
        if ($errMsg -like "*SerializationSettings*" -or $errMsg -like "*ResourceManagementClient*") {
            Write-Host ""
            Write-Host "Module Version Conflict" -ForegroundColor Red
            Write-Host "-----------------------" -ForegroundColor Red
            Write-Host ""
            Write-Host "Az.Accounts module version conflict detected during authentication." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "To fix this issue, try:" -ForegroundColor Cyan
            Write-Host "  1. Update-Module Az.Accounts -Force" -ForegroundColor Green
            Write-Host "  2. Restart PowerShell" -ForegroundColor Green
            Write-Host ""
            Write-Host "Or use Azure CLI instead:" -ForegroundColor Cyan
            Write-Host "  az login" -ForegroundColor Green
            Write-Host ""
            Write-Host "Error details: $errMsg" -ForegroundColor DarkGray
            Write-Host ""
            Throw "Az.Accounts module version conflict."
        }

        if ($errMsg -notlike "*Authentication was cancelled*") {
            Write-Host ""
            Write-Host "Authentication Failed" -ForegroundColor Red
            Write-Host "---------------------" -ForegroundColor Red
            Write-Host ""
            Write-Host "Failed to authenticate to Azure." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Error: $errMsg" -ForegroundColor DarkGray
            Write-Host ""
            Throw "Azure authentication failed: $errMsg"
        }
        throw
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

    # Parse JWT token to get expiration time (optional, non-fatal)
    try {
        $tokenParts = $token.Split('.')
        if ($tokenParts.Count -ge 2) {
            # Decode the payload (second part of JWT)
            $payload = $tokenParts[1]
            # Add padding if needed for Base64 decoding
            $padding = '=' * ((4 - ($payload.Length % 4)) % 4)
            $payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload + $padding))
            $tokenData = $payloadJson | ConvertFrom-Json

            if ($tokenData.exp) {
                # Convert Unix timestamp to DateTime
                $epoch = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                $expirationUtc = $epoch.AddSeconds($tokenData.exp)
                $expirationLocal = $expirationUtc.ToLocalTime()
                $timeUntilExpiry = $expirationUtc - [DateTime]::UtcNow

                Write-Host "Token expires: $expirationLocal (in $([Math]::Floor($timeUntilExpiry.TotalMinutes)) minutes)" -ForegroundColor Cyan
            }
        }
    }
    catch {
        # If token parsing fails, continue anyway
        Write-Verbose "Could not parse token expiration: $($_.Exception.Message)"
    }

    # Verify token by testing connection to Dataverse (optional, non-fatal)
    Write-Host "Verifying token with Dataverse..." -ForegroundColor Cyan
    $headers = @{
        'Authorization' = "Bearer $token"
        'Accept' = 'application/json'
        'OData-MaxVersion' = '4.0'
        'OData-Version' = '4.0'
    }
    $testUrl = "$EnvironmentUrl/api/data/v9.2/WhoAmI"

    try {
        $whoAmIResponse = Invoke-RestMethod -Method GET -Uri $testUrl -Headers $headers -ErrorAction Stop
        Write-Host "Token verified successfully!" -ForegroundColor Green
        Write-Host "  User ID: $($whoAmIResponse.UserId)" -ForegroundColor Cyan
        Write-Host "  Organization ID: $($whoAmIResponse.OrganizationId)" -ForegroundColor Cyan
    }
    catch {
        Write-Warning "Token verification failed: $($_.Exception.Message)"
        Write-Warning "The token was obtained but may not have valid permissions for this Dataverse environment."
        return $token
    }

    # Get organization details (optional, non-fatal)
    try {
        $orgUrl = "$EnvironmentUrl/api/data/v9.2/organizations($($whoAmIResponse.OrganizationId))?`$select=name,friendlyname"
        $orgResponse = Invoke-RestMethod -Method GET -Uri $orgUrl -Headers $headers -ErrorAction Stop
        if ($orgResponse) {
            Write-Host "  Environment: $($orgResponse.friendlyname)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Verbose "Could not retrieve environment name: $($_.Exception.Message)"
    }

    return $token
}
Export-ModuleMember -Function Connect-XbDataverse
