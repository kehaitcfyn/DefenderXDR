# Load the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Opret GUI elementer
$form = New-Object System.Windows.Forms.Form
$form.Text = "Hash Lookup Tool"
$form.Size = New-Object System.Drawing.Size(800, 500)
$form.StartPosition = "CenterScreen"

# Label for hash input
$label = New-Object System.Windows.Forms.Label
$label.Text = "Indtast hashværdi:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Textbox for hash input
$textBoxHash = New-Object System.Windows.Forms.TextBox
$textBoxHash.Size = New-Object System.Drawing.Size(500, 20)
$textBoxHash.Location = New-Object System.Drawing.Point(120, 15)
$form.Controls.Add($textBoxHash)

# Button to trigger the lookup
$button = New-Object System.Windows.Forms.Button
$button.Text = "Slå op"
$button.Location = New-Object System.Drawing.Point(630, 15)
$form.Controls.Add($button)

# DataGridView to display the results
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Size = New-Object System.Drawing.Size(760, 350)
$dataGrid.Location = New-Object System.Drawing.Point(10, 50)
$dataGrid.ColumnCount = 2
$dataGrid.Columns[0].Name = "Attribute"
$dataGrid.Columns[1].Name = "Value"
$dataGrid.AutoSizeColumnsMode = 'Fill'
$form.Controls.Add($dataGrid)

# Function to fetch the hash info and update the table
$button.Add_Click({
    # Clear previous results
    $dataGrid.Rows.Clear()

    # Fetch the hash value from the input field
    $hashValue = $textBoxHash.Text

    # Definer API URL
    $apiUrl = "https://mb-api.abuse.ch/api/v1/"

    # Definer POST data
    $postData = @{
        query = "get_info"
        hash  = $hashValue
    }

    # Send POST forespørgsel til API'en
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $postData

        # Hvis data blev fundet
        if ($response.query_status -eq "ok" -and $response.data.Count -gt 0) {
            $data = $response.data[0]

            # Add rows to the DataGridView
            $dataGrid.Rows.Add("SHA256", $data.sha256_hash)
            $dataGrid.Rows.Add("SHA1", $data.sha1_hash)
            $dataGrid.Rows.Add("MD5", $data.md5_hash)
            $dataGrid.Rows.Add("File Name", $data.file_name)
            $dataGrid.Rows.Add("File Size", $data.file_size)
            $dataGrid.Rows.Add("File Type", $data.file_type)
            $dataGrid.Rows.Add("First Seen", $data.first_seen)
            $dataGrid.Rows.Add("Last Seen", $data.last_seen)
            $dataGrid.Rows.Add("Origin Country", $data.origin_country)
            $dataGrid.Rows.Add("Tags", ($data.tags -join ', '))

            # YARA Rules
            foreach ($rule in $data.yara_rules) {
                $dataGrid.Rows.Add("YARA Rule", $rule.rule_name)
            }

            # Vendor Intel
            foreach ($vendor in $data.vendor_intel.PSObject.Properties) {
                foreach ($entry in $vendor.Value) {
                    if ($entry.verdict) {
                        $dataGrid.Rows.Add("$($vendor.Name) Verdict", $entry.verdict)
                    }
                    if ($entry.analysis_url) {
                        $dataGrid.Rows.Add("$($vendor.Name) Analysis URL", $entry.analysis_url)
                    }
                }
            }

        } else {
            $dataGrid.Rows.Add("Ingen data fundet", "")
        }

    } catch {
        $dataGrid.Rows.Add("Der opstod en fejl", $_)
    }
})

# Vis formen
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
