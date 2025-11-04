# Azure Container Apps Deployment Script
# Prerequisites: Azure CLI installed and logged in

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-monitor-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "centralus",
    
    [Parameter(Mandatory=$false)]
    [string]$FrontendUrl = "https://your-frontend.azurestaticapps.net"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Azure Container Apps deployment..." -ForegroundColor Green

# Check if Azure CLI is installed
try {
    az --version | Out-Null
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    exit 1
}

# Check if logged in to Azure
try {
    $account = az account show --query "user.name" -o tsv 2>$null
    if ($account) {
        Write-Host "✅ Logged in to Azure as: $account" -ForegroundColor Green
    } else {
        Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Deploy infrastructure using Bicep
Write-Host "🏗️ Deploying infrastructure..." -ForegroundColor Yellow
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azure/main.bicep" `
    --parameters "azure/main.parameters.json" `
    --parameters frontendUrl=$FrontendUrl `
    --query "properties.outputs" -o json | ConvertFrom-Json

$registryName = $deployment.containerRegistryName.value
$registryLoginServer = $deployment.containerRegistryLoginServer.value

Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "📋 Container Registry: $registryName" -ForegroundColor Cyan
Write-Host "📋 Registry Server: $registryLoginServer" -ForegroundColor Cyan

# Build and push Docker image
Write-Host "🐳 Building and pushing Docker image..." -ForegroundColor Yellow

# Login to ACR
az acr login --name $registryName

# Build and push image
$imageTag = "$registryLoginServer/monitor-worker:latest"
docker build -t $imageTag .
docker push $imageTag

Write-Host "✅ Docker image pushed successfully!" -ForegroundColor Green

# Update Container App with new image
Write-Host "🔄 Updating Container App..." -ForegroundColor Yellow
az containerapp update `
    --name "monitor-worker" `
    --resource-group $ResourceGroupName `
    --image $imageTag

Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "📋 Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "📋 Container App: monitor-worker" -ForegroundColor Cyan

# Show logs command
Write-Host ""
Write-Host "📊 To view logs, run:" -ForegroundColor Yellow
Write-Host "az containerapp logs show --name monitor-worker --resource-group $ResourceGroupName --follow" -ForegroundColor White