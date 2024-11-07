##############################--Forbind
Tenant--##########################################################################################################
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

##############################--Forespørgsel 2 MissingUpdates--##########################################################################################################
# Forespørgsel 2 MissingUpdates
    $kqlQuery1 = @"
DeviceTvmSoftwareVulnerabilities
| where OSPlatform !contains "server"
| where RecommendedSecurityUpdate contains "security updates" 
| where VulnerabilitySeverityLevel =="High"
| where RecommendedSecurityUpdate !has "Last updated at" 
|summarize by DeviceName,RecommendedSecurityUpdate,SoftwareName
| sort by RecommendedSecurityUpdate asc 
"@  
$body1 = @{ Query = $kqlQuery1 }
 
     
    $url = "https://api.security.microsoft.com/api/advancedhunting/run" 
$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $token" 
}
$body = ConvertTo-Json -InputObject @{ "Query" = $kqlQuery1}
$webResponse = Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop -UseBasicParsing
$response =  $webResponse.Content | ConvertFrom-Json
$results1 = $response.Results

# Eksporter til CSV uden typeinformat
$Results1 | Export-Csv -Path "C:\xxxx\MissingUpdates.csv" -NoTypeInformation

###############################--Forespørgsel 2 Computer--#########################################################################################################

# Forespørgsel 2 Computer
    $kqlQuery2 = @"
DeviceTvmSoftwareVulnerabilities
| where OSPlatform !contains "server"
| where RecommendedSecurityUpdate contains "security updates" 
| where VulnerabilitySeverityLevel =="High"
| where RecommendedSecurityUpdate !has "Last updated at" 
|summarize by DeviceName
| project DeviceName
"@  
$body2 = @{ Query = $kqlQuery2 }
 
      
    $url = "https://api.security.microsoft.com/api/advancedhunting/run" 
$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $token" 
}
$body = ConvertTo-Json -InputObject @{ "Query" = $kqlQuery2}
$webResponse = Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop -UseBasicParsing
$response =  $webResponse.Content | ConvertFrom-Json
$results2 = $response.Results

# Eksporter til CSV uden typeinformation
$Results2 | Export-Csv -Path "C:xxxx\Computer.csv" -NoTypeInformation

####################################--Kopier filen til Blobstorage--####################################################################################################

# Kopier filen til Blobstorage
$context = New-AzStorageContext -StorageAccountName "Indsæt dig eget" -StorageAccountKey "Indsæt dig eget"

Set-AzStorageBlobContent -File "C:\xxxx\Computer.csv" -Container "Indsæt dig eget" -Blob "Computer.csv" -Context $context -Force
Write-Host "Filen er uploadet til Azure Blob Storage"
Set-AzStorageBlobContent -File "C:\xxxx\MissingUpdates.csv" -Container "Indsæt dig eget" -Blob "MissingUpdates.csv" -Context $context -Force
Write-Host "Filen er uploadet til Azure Blob Storage
