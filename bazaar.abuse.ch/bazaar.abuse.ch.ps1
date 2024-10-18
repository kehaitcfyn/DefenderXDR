$ErrorActionPreference = "Stop" # Ensures all non-terminating errors are treated as terminating

try {
    $uri = "https://mb-api.abuse.ch/api/v1/"

    $body = @{
        query = "get_file_type"
        # Filetype kan være exe,zip,dll,doc,docx,xlx,xlsx,pdf
        file_type = "exe"
        limit = 250
    }

    # Send request to API
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop

    # Convert response to JSON and save it to a file
    $jsonResponse = $response | ConvertTo-Json -Depth 4
    $filePath = "C:\xxx\TEMP_bazaarAbuseC-Sha256.json"
    $jsonResponse | Out-File -FilePath $filePath -Encoding utf8

    Write-Host "Response saved to $filePath"

    # Indlæs den originale JSON-fil
    $jsonFilePath = "C:\xxx\TEMP_bazaarAbuseC-Sha256.json"
    $jsonData = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json -ErrorAction Stop

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
            # Tjek om alle felter er null, hvis ja spring det over
            if ($item.sha256_hash -ne $null -or $item.first_seen -ne $null -or $item.file_name -ne $null -or $item.file_type_mime -ne $null -or $item.magika -ne $null) {
                # Tilføj de ønskede værdier til resultatlisten
                $result += [PSCustomObject]@{
                    sha256_hash       = $item.sha256_hash
                    first_seen        = $item.first_seen
                    file_name         = $item.file_name
                    file_type_mime    = $item.file_type_mime
                    magika            = $item.magika
                }
            }
        }
    }

    # Check if $result is not empty
    if ($result.Count -eq 0) {
        Write-Host "Fejl: Ingen data blev fundet."
        exit
    }

    # Konverter resultatet til JSON
    $outputJson = $result | ConvertTo-Json -Depth 3

    # Trim leading/trailing whitespace
    $outputJson = $outputJson.Trim()

    # Gem den nye JSON i en fil
    $outputFilePath = "C:\xxx\bazaarAbuseC-Sha256.json"
    $outputJson | Set-Content -Path $outputFilePath -Encoding UTF8

    Write-Host "Data er gemt i $outputFilePath"

} catch {
    Write-Host "En fejl opstod: $($_.Exception.Message)"
    # Optional: Log the error or take other action
}

################################

# kopier Json fil til min Azure Blob Storage
# Azure Blob Storage konfiguration
$storageAccountName = ""  # Erstat med din Storage Account Name
$storageAccountKey = ""   # Erstat med din Storage Account Key
$containerName = ""       # Erstat med din Blob Container Name
$blobName = "bazaarAbuseC-Sha256.json"             # Navn på blob'en i Azure

# Opret forbindelse til din storage-konto
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Upload filen til blob container
Set-AzStorageBlobContent -File $outputFilePath -Container $containerName -Blob $blobName -Context $context -Force

Write-Host "Filen er uploadet til Azure Blob Storage som $blobName"