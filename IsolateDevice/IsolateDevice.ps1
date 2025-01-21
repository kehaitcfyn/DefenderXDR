$tenantId = '' # Indsæt din egen tenant ID her
$appId = '' # Indsæt din egen app ID her
$appSecret = '' # Indsæt din egen app secret her
$resourceAppIdUri = 'https://api.securitycenter.microsoft.com'
$oAuthUri = "https://login.microsoftonline.com/$tenantId/oauth2/token"

# Hent token til autentificering
$authBody = [Ordered] @{
    resource      = "$resourceAppIdUri"
    client_id     = "$appId"
    client_secret = "$appSecret"
    grant_type    = 'client_credentials'
}
$response = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
$aadToken = $response.access_token

# Læs maskin-ID'er fra filen
$machineIds = Get-Content -Path "C:\PS\Deviceid.txt"

# Kommentar til isolationsanmodning
$Comment = @{
    Comment = "Isolating machine due to security concern"
} | ConvertTo-Json -Depth 1

foreach ($machineId in $machineIds) {
    # Definer API-endepunkt
    $uri = "https://api.securitycenter.microsoft.com/api/machines/$machineId/isolate"

    # Anmodningsdata
    $requestData = @{
        isolationType = "Full" # Alternativt kan "Selective" bruges
        Comment       = "Isolating machine due to detected threat"
    } | ConvertTo-Json -Depth 1

    try {
        # Kald API til isolering af maskine
        $isolateResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers @{Authorization = "Bearer $aadToken"} -Body $requestData -ContentType 'application/json' -ErrorAction Stop

        if ($isolateResponse) {
            Write-Output "Maskine $machineId er blevet isoleret med succes."
        } else {
            Write-Output "Fejl ved isolering af maskine $machineId."
        }
    } catch {
        Write-Output "Fejl ved isolering af maskine $machineId. $_"
    }
}
