#https://learn.microsoft.com/en-us/defender-endpoint/api/unisolate-machine

$tenantId = '' # Paste your own tenant ID here
$appId = '' # Paste your own app ID here
$appSecret = '' # Paste your own app secret here
$resourceAppIdUri = 'https://api.securitycenter.microsoft.com'
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$response = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $body -ErrorAction Stop
$aadToken = $response.access_token
$resourceAppIdUri = 'https://api.security.microsoft.com'
    $oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    $authBody = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
    $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
    $token = $authResponse.access_token
    

    # Læs maskin-ID'er fra filen
 $machineIds = Get-Content -Path "C:\PS\Deviceid.txt"

$Comment = @"
"Comment": "Unisolate machine since it was clean and validated"
"@

foreach ($machineId in $machineIds) {
        # Definer API-endepunkt
        $uri = "https://api.securitycenter.microsoft.com/api/machines/$machineId/unisolate"

        $requestData = @{
        Comment = $Comment
    } | ConvertTo-Json

    
        try {
            # Kald API til un-isolering af maskine
            #$unisolateResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers @{Authorization = "Bearer $aadToken"} -ErrorAction Stop
            $unisolateResponse = Invoke-RestMethod -Method Post -Uri $uri -Headers @{Authorization = "Bearer $aadToken"} -Body $requestData -ContentType 'application/json' -ErrorAction Stop
                       

            if ($unisolateResponse) {
                Write-Output "Maskine $machineId un-isoleret med succes."
            } else {
                Write-Output "Fejl ved at un-isolere maskine $machineId."
            }
               

        } catch {
            Write-Output "Fejl ved at un-isolere maskine $machineId."
        }
    }
















