# Hent IOC fra de sidste 7 dage

$body = @{
    query = "get_iocs"
    days = 7
}

# Send POST-forespørgsel og gem resultatet
$response = Invoke-RestMethod -Uri "https://threatfox-api.abuse.ch/api/v1/" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"


# Gem outputtet i en JSON-fil

$response | ConvertTo-Json | Set-Content -Path "# Erstat" -Encoding utf8


# træk de data ud af Json filen som du har brug for


# Indlæs den originale JSON-fil
$jsonFilePath = "# Erstat"
$jsonData = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

# Check if the JSON data was loaded correctly
if ($null -eq $jsonData) {
    Write-Host "Fejl: JSON-data kunne ikke indlæses. Tjek filstien og filens indhold."
    exit
}

# Debug: Inspect the structure of the loaded JSON
Write-Host "Struktur af JSON-data:"


$jsonData | Format-List

# Opret en liste til at gemme de nye objekter
$result = @()

# Gå igennem hvert element i JSON-strukturen
foreach ($key in $jsonData.PSObject.Properties.Name) {
    foreach ($item in $jsonData.$key) {
        # Check if the item's "ioc_type" is "sha256_hash or payload_delivery"
        if ($item.ioc_type -eq "sha256_hash" -or $item.threat_type -eq "payload_delivery") {
            # Tilføj de ønskede værdier til resultatlisten
            $result += [PSCustomObject]@{
                ioc               = $item.ioc
                threat_type       = $item.threat_type
                threat_type_desc  = $item.threat_type_desc 
                ioc_type          = $item.ioc_type
                ioc_type_desc     = $item.ioc_type_desc
                malware           = $item.malware
                malware_printable = $item.malware_printable
            }
        }
    }
}

# Check if $result is not empty
if ($result.Count -eq 0) {
    Write-Host "Fejl: Ingen data blev fundet for ioc_type 'sha256_hash'."
    exit
}

# Konverter resultatet til JSON
$outputJson = $result | ConvertTo-Json -Depth 3

# Trim leading/trailing whitespace
$outputJson = $outputJson.Trim()

# Gem den nye JSON i en fil
$outputFilePath = "# Erstat"
$outputJson | Set-Content -Path $outputFilePath -Encoding UTF8

Write-Host "Data er gemt i $outputFilePath"


# kopier Json fil til min Azure Blob Storage
# Azure Blob Storage konfiguration
$storageAccountName = ""  # Erstat med din Storage Account Name
$storageAccountKey = "" # Erstat at med din Storage Account Key
$containerName = ""            # Erstat med din Blob Container Name
$blobName = "# Erstat"             # Navn på blob'en i Azure

# Opret forbindelse til din storage-konto
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Upload filen til blob container
Set-AzStorageBlobContent -File $outputFilePath -Container $containerName -Blob $blobName -Context $context -Force

Write-Host "Filen er uploadet til Azure Blob Storage som $blobName"
