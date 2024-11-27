$ErrorActionPreference = "Stop" # Ensures all non-terminating errors are treated as terminating

try {
    $uri = "https://mb-api.abuse.ch/api/v1/"

    # Opret en liste over filtyper, som skal hentes
    $fileTypes = @("exe", "zip","doc","xls")

    # Loop igennem hver filtype og hent data
    foreach ($fileType in $fileTypes) {
        $body = @{
            query = "get_file_type"
            file_type = $fileType
            limit = 100
        }

        # Send request to API
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop

        # Convert response to JSON and save it to a file
        $jsonResponse = $response | ConvertTo-Json -Depth 4
        $filePath = "C:\_Export-Data\TEMP_bazaarAbuseC-Sha256_$fileType.json"
        $jsonResponse | Out-File -FilePath $filePath -Encoding utf8

        Write-Host "Response for file type '$fileType' saved to $filePath"

        # Indlæs den originale JSON-fil
        $jsonData = Get-Content -Path $filePath -Raw | ConvertFrom-Json -ErrorAction Stop

        # Check if the JSON data was loaded correctly
        if ($null -eq $jsonData) {
            Write-Host "Fejl: JSON-data kunne ikke indlæses. Tjek filstien og filens indhold for filtype '$fileType'."
            continue
        }

        # Debug: Inspect the structure of the loaded JSON
        Write-Host "Struktur af JSON-data for '$fileType':"
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
            Write-Host "Fejl: Ingen data blev fundet for filtype '$fileType'."
            continue
        }

        # Konverter resultatet til JSON
        $outputJson = $result | ConvertTo-Json -Depth 3

        # Trim leading/trailing whitespace
        $outputJson = $outputJson.Trim()

        # Gem den nye JSON i en fil
        $outputFilePath = "C:\_Export-Data\bazaarAbuseC-Sha256_$fileType.json"
        $outputJson | Set-Content -Path $outputFilePath -Encoding UTF8

        Write-Host "Data for filtype '$fileType' er gemt i $outputFilePath"
    }

} catch {
    Write-Host "En fejl opstod: $($_.Exception.Message)"
    # Optional: Log the error or take other action
}
  
################################ Merge Json filer til ################################


# Indstil filstierne
$filePath1 = "C:\_Export-Data\bazaarAbuseC-Sha256_exe.json"
$filePath2 = "C:\_Export-Data\bazaarAbuseC-Sha256_zip.json"
$filePath3 = "C:\_Export-Data\bazaarAbuseC-Sha256_doc.json"
$filePath4 = "C:\_Export-Data\bazaarAbuseC-Sha256_xls.json"
$outputFilePath = "C:\_Export-Data\bazaarAbuseC-Sha256.json"

# Indlæs JSON-data fra begge filer
$jsonData1 = Get-Content -Path $filePath1 -Raw | ConvertFrom-Json
$jsonData2 = Get-Content -Path $filePath2 -Raw | ConvertFrom-Json
$jsonData3 = Get-Content -Path $filePath3 -Raw | ConvertFrom-Json
$jsonData4 = Get-Content -Path $filePath4 -Raw | ConvertFrom-Json

# Initialiser en liste til sammenlagte data
$mergedData = @()

# Sammenlæg JSON-data (håndterer både objekter og arrays)
if ($jsonData1 -is [System.Collections.ArrayList]) {
    # Hvis JSON-dataene er arrays, kombiner dem direkte
    $mergedData = $jsonData1 + $jsonData2 + $jsonData3 + $jsonData4
} else {
    # Hvis JSON-dataene er objekter, tilføj dem som individuelle elementer til mergedData
    $mergedData += $jsonData1
    $mergedData += $jsonData2
    $mergedData += $jsonData3
    $mergedData += $jsonData4
}

# Filtrér de uønskede metadata-egenskaber
$filteredData = $mergedData | ForEach-Object {
    $_ | Select-Object -Property * -ExcludeProperty Count, Length, LongLength, Rank, SyncRoot, IsReadOnly, IsFixedSize, IsSynchronized, Keys, Values
}

# Konverter de sammenlagte data til JSON og gem dem
$mergedJson = $filteredData | ConvertTo-Json -Depth 4
$mergedJson | Set-Content -Path $outputFilePath -Encoding UTF8

Write-Host "De to JSON-filer er blevet sammenlagt og gemt i $outputFilePath"


################################

# kopier Json fil til min Azure Blob Storage
# Azure Blob Storage konfiguration
$storageAccountName = ""  		# Erstat med din Storage Account Name
$storageAccountKey = ""    		# Erstat med din Storage Account Key
$containerName = ""            		# Erstat med din Blob Container Name
$blobName = "bazaarAbuseC-Sha256.json"  # Navn på blob'en i Azure

# Opret forbindelse til din storage-konto
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Upload filen til blob container
Set-AzStorageBlobContent -File $outputFilePath -Container $containerName -Blob $blobName -Context $context -Force

Write-Host "Filen er uploadet til Azure Blob Storage som $blobName"