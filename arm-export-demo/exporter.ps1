function Get-LatestCommit {
    param (
        [string]$organization,
        [string]$project,
        [string]$repository,
        [string]$branch,
        [hashtable]$headers
    )

    $uri = "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/refs?filter=heads/$branch&api-version=6.0"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    if ($response.count -eq 1) {
        return $response.value[0].objectId
    } else {
        throw "Could not find the specified branch."
    }
}

function Check-FileExists {
    param (
        [string]$organization,
        [string]$project,
        [string]$repository,
        [string]$path,
        [hashtable]$headers
    )

    $encodedPath = [System.Web.HttpUtility]::UrlPathEncode($path)
    $uri = "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/items?path=$encodedPath&api-version=6.0"
    try {
        Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $true
    } catch {
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
            return $false
        } else {
            throw $_
        }
    }
}

# Input parameters
$ResourceGroupName = "resource-group-name"
$RouteTableName = "source-route-table-name"
$KeyVaultName = "your-keyvault-name"
$SecretName = "your-azure-devops-pat"
$OrganizationName = "your-azure-devops-org"
$ProjectName = "your-azure-devops-project"
$RepoName = "your-azure-devops-repo"
$BranchName = "main"

# Import required modules
Import-Module Az.KeyVault
Import-Module Az.Accounts
Import-Module Az.ResourceGraph

# # Authenticate to Azure
Connect-AzAccount -Identity

# Retrieve Personal Access Token (PAT) from Azure Key Vault
$pat = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText

# Set Authorization Header
$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))
    "Content-Type"  = "application/json"
}

# Get the route table
$routeTable = Get-AzRouteTable -ResourceGroupName $ResourceGroupName -Name $RouteTableName

# Export ARM Template
$ExportPath = Join-Path $env:TEMP -ChildPath "armtemplate.json"
$template = Export-AzResourceGroup -ResourceGroupName $ResourceGroupName -Resource $routeTable.Id `
    -SkipAllParameterization -Path $ExportPath
$armTemplate = Get-Content -Path $template.Path -Raw

# Get the latest commit
$latestCommit = Get-LatestCommit -organization $OrganizationName -project $ProjectName -repository $RepoName -branch $BranchName -headers $headers

# Check if the ARM template already exists
$fileExists = Check-FileExists -organization $OrganizationName -project $ProjectName -repository $RepoName -path "/$RouteTableName-armtemplate.json" -headers $headers

# Commit ARM Template to Azure DevOps
$uri = "https://dev.azure.com/$OrganizationName/$ProjectName/_apis/git/repositories/$RepoName/pushes?api-version=6.0"

$body = @{
    "refUpdates" = @(
        @{
            "name"        = "refs/heads/$BranchName"
            "oldObjectId" = $latestCommit
        }
    )
    "commits" = @(
        @{
            "comment" = "Automated commit of ARM template for $RouteTableName"
            "changes" = @(
                @{
                    "changeType" = if ($fileExists) { "edit" } else { "add" }
                    "item"       = @{
                        "path" = "/$RouteTableName-armtemplate.json"
                    }
                    "newContent" = @{
                        "content"     = $armTemplate
                        "contentType" = "rawtext"
                    }
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

