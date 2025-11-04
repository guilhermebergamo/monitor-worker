# Deploy script for Production Environment
# Uses rg-monitor-prod resource group

param(
    [Parameter(Mandatory=$false)]
    [string]$FrontendUrl = "https://seu-frontend-prod.azurestaticapps.net"
)

$ErrorActionPreference = "Stop"
$ResourceGroupName = "rg-monitor-prod"
$Environment = "prod"

Write-Host "🚀 Starting PRODUCTION deployment to: $ResourceGroupName" -ForegroundColor Red

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

# Confirmation for production
Write-Host "⚠️  WARNING: This will deploy to PRODUCTION!" -ForegroundColor Red
$confirm = Read-Host "Type 'DEPLOY' to continue with production deployment"
if ($confirm -ne "DEPLOY") {
    Write-Host "❌ Production deployment cancelled" -ForegroundColor Red
    exit 0
}

Write-Host "🏗️ Deploying PRODUCTION infrastructure..." -ForegroundColor Yellow

# Deploy infrastructure with prod-specific naming
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azure/main.bicep" `
    --parameters "azure/main.parameters.prod.json" `
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

$imageTag = "$registryServer/monitor-worker:prod-latest"
docker build -t $imageTag .
docker push $imageTag

Write-Host "✅ Image pushed successfully!" -ForegroundColor Green

Write-Host "🔄 Updating Container App..." -ForegroundColor Yellow

# Update Container App
az containerapp update `
    --name "monitor-worker-prod" `
    --resource-group $ResourceGroupName `
    --image $imageTag

Write-Host "🎉 PRODUCTION deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 View logs:" -ForegroundColor Yellow
Write-Host "az containerapp logs show --name monitor-worker-prod --resource-group $ResourceGroupName --follow" -ForegroundColor White