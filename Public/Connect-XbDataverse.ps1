function Connect-XbDataverse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The base URL of the Dataverse environment, e.g., 'https://org.crm4.dynamics.com'")]
        [Alias('Url', 'OrgUrl')]
        [ValidatePattern('^https:\/\/[\w-]+\.crm\d*\.dynamics\.com$')]
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

    try {
        # Check if Az.Accounts is available
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            Throw "Az.Accounts module is not installed. Run: Install-Module -Name Az.Accounts -Scope CurrentUser"
        }

        # Import Az.Accounts if not already loaded
        if (-not (Get-Module -Name Az.Accounts)) {
            Import-Module Az.Accounts -ErrorAction Stop
        }

        Write-Host "Connecting to Azure..." -ForegroundColor Cyan

        # Connect to Azure with the correct auth scope
        $azContext = Connect-AzAccount -AuthScope $EnvironmentUrl -ErrorAction Stop

        if (-not $azContext) {
            Throw "Failed to connect to Azure. Authentication was cancelled or failed."
        }

        Write-Host "Retrieving access token for $EnvironmentUrl..." -ForegroundColor Cyan

        # Get the access token
        $secureToken = (Get-AzAccessToken -ResourceUrl $EnvironmentUrl -ErrorAction Stop).Token

        # Convert SecureString to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        Write-Host "Successfully authenticated to $EnvironmentUrl" -ForegroundColor Green

        # Parse JWT token to get expiration time
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

        # Verify token by testing connection to Dataverse
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
        }
        return $token
    }
    catch {
        $errMsg = $_.Exception.Message

        # Check for known Az module version conflicts
        if ($errMsg -like "*SerializationSettings*" -or $errMsg -like "*ResourceManagementClient*") {
            $errMsg = "Az.Accounts module version conflict detected.`n`n"
            $errMsg += "To fix this issue, try one of these solutions:`n"
            $errMsg += "1. Update Az modules: Update-Module Az.Accounts -Force`n"
            $errMsg += "2. Restart PowerShell after updating`n"
            $errMsg += "3. Or use Azure CLI instead:`n"
            $errMsg += "   az login`n"
         #   $errMsg += "   $token = az account get-access-token --resource '$EnvironmentUrl' --query accessToken -o tsv`n"
            $errMsg += "`nOriginal error: $($_.Exception.Message)"
        }

        Throw "Authentication failed. Error: $errMsg"
    }
}
Export-ModuleMember -Function Connect-XbDataverse
