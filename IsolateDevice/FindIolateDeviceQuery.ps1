
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

    $query =  @"
DeviceInfo
| where Timestamp >ago(24h)
| extend MitigationStatusObject = parse_json(MitigationStatus)
| mv-expand MitigationStatusObject
| extend IsolationStatus = tostring(MitigationStatusObject.Isolated)
| where IsolationStatus == "true"
|project DeviceId
"@  
 
   
#$query = [IO.File]::ReadAllText("C:\xxx\myQuery.txt"); # Replace with the path to your file   
     
    $url = "https://api.security.microsoft.com/api/advancedhunting/run" 
$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $token" 
}
$body = ConvertTo-Json -InputObject @{ "Query" = $query}
$webResponse = Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop -UseBasicParsing
$response =  $webResponse.Content | ConvertFrom-Json
$results = $response.Results

$results| Out-File -FilePath "C:\xxx\myQuery.txt"" 


