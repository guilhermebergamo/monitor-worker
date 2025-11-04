# Deploy script for Development Environment
# Uses rg-monitor-dev resource group

param(
    [Parameter(Mandatory=$false)]
    [string]$FrontendUrl = "https://white-river-0f9f4b40f.3.azurestaticapps.net"
)

$ErrorActionPreference = "Stop"
$ResourceGroupName = "rg-monitor-dev"
$Environment = "dev"

Write-Host "🚀 Starting DEVELOPMENT deployment to: $ResourceGroupName" -ForegroundColor Green

# Check Azure CLI and login
try {
    $account = az account show --query "user.name" -o tsv 2>$null
    if ($account) {
        Write-Host "✅ Logged in to Azure as: $account" -ForegroundColor Green
    } else {
        Write-Host "❌ Please login first: az login" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Please login first: az login" -ForegroundColor Red
    exit 1
}

Write-Host "🏗️ Deploying DEVELOPMENT infrastructure..." -ForegroundColor Yellow

# Deploy infrastructure with dev-specific naming
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azure/main.bicep" `
    --parameters "azure/main.parameters.dev.json" `
    --parameters frontendUrl=$FrontendUrl `
    --query "properties.outputs" -o json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Infrastructure deployment failed" -ForegroundColor Red
    exit 1
}

$deploymentResult = $deployment | ConvertFrom-Json
$registryName = $deploymentResult.containerRegistryName.value
$registryServer = $deploymentResult.containerRegistryLoginServer.value

Write-Host "✅ Infrastructure deployed!" -ForegroundColor Green
Write-Host "📋 Registry: $registryName" -ForegroundColor Cyan

Write-Host "🐳 Building and pushing Docker image..." -ForegroundColor Yellow

# Login to ACR and build/push
az acr login --name $registryName

$imageTag = "$registryServer/monitor-worker:dev-latest"
docker build -t $imageTag .
docker push $imageTag

Write-Host "✅ Image pushed successfully!" -ForegroundColor Green

Write-Host "🔄 Updating Container App..." -ForegroundColor Yellow

# Update Container App
az containerapp update `
    --name "monitor-worker-dev" `
    --resource-group $ResourceGroupName `
    --image $imageTag

Write-Host "🎉 DEVELOPMENT deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 View logs:" -ForegroundColor Yellow
Write-Host "az containerapp logs show --name monitor-worker-dev --resource-group $ResourceGroupName --follow" -ForegroundColor White