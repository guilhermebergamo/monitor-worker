# Cleanup Azure Resources Script

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-monitor-dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🧹 Azure Resources Cleanup Script" -ForegroundColor Yellow
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to delete ALL resources in '$ResourceGroupName'? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "❌ Operation cancelled by user." -ForegroundColor Red
        exit 0
    }
}

try {
    # Check if resource group exists
    $rg = az group show --name $ResourceGroupName --query "name" -o tsv 2>$null
    if (-not $rg) {
        Write-Host "❌ Resource group '$ResourceGroupName' not found." -ForegroundColor Red
        exit 1
    }

    Write-Host "🗑️ Deleting resource group and all resources..." -ForegroundColor Yellow
    az group delete --name $ResourceGroupName --yes --no-wait

    Write-Host "✅ Cleanup initiated successfully!" -ForegroundColor Green
    Write-Host "📋 The deletion is running in the background." -ForegroundColor Cyan
    Write-Host "📋 To check status: az group show --name $ResourceGroupName" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Error during cleanup: $_" -ForegroundColor Red
    exit 1
}