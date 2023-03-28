# Set parameters
$apiUrl = "https://prices.azure.com/api/retail/prices"
$pageSize = 100
$filter = "serviceName eq 'Virtual Machines' and armRegionName eq 'eastus2' and priceType eq 'Reservation'"
$currency = "USD"
$outputFile = "VM-prices.csv"

# Initialize variables
$headers = @{"Content-Type" = "application/json"}
$nextLink = $apiUrl + "?`$filter=$filter&\$top=$pageSize"
$count = 0

# Loop through all pages of API results
do {
    # Make API call
    Write-Host "Requesting URL: $nextLink"
    $response = Invoke-RestMethod -Uri $nextLink -Headers $headers
    
    # Write results to CSV
    if ($response.items) {
        $response.items | Export-Csv -Path $outputFile -NoTypeInformation -Append
        $count += $response.items.Count
        Write-Host "Records retrieved: $count"
    } else {
        Write-Host "No more results."
    }
    
    # Get link to next page, if available
    $nextLink = $response.nextPageLink
    
} while ($nextLink)

Write-Host "Results saved to $outputFile"
