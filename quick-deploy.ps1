# Quick Deploy Script for rg-monitor-dev
# Deploy Monitor Worker to existing Resource Group

param(
    [Parameter(Mandatory=$false)]
    [string]$FrontendUrl = "https://your-frontend.azurestaticapps.net"
)

$ErrorActionPreference = "Stop"
$ResourceGroupName = "rg-monitor-dev"

Write-Host "🚀 Starting deployment to Resource Group: $ResourceGroupName" -ForegroundColor Green

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

# Check if resource group exists
try {
    $rgExists = az group show --name $ResourceGroupName --query "name" -o tsv 2>$null
    if ($rgExists) {
        Write-Host "✅ Resource Group '$ResourceGroupName' found" -ForegroundColor Green
    } else {
        Write-Host "❌ Resource Group '$ResourceGroupName' not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error checking Resource Group" -ForegroundColor Red
    exit 1
}

Write-Host "🏗️ Deploying infrastructure..." -ForegroundColor Yellow

# Deploy infrastructure
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azure/main.bicep" `
    --parameters "azure/main.parameters.json" `
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

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ACR login failed" -ForegroundColor Red
    exit 1
}

$imageTag = "$registryServer/monitor-worker:latest"
docker build -t $imageTag .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}

docker push $imageTag

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker push failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image pushed successfully!" -ForegroundColor Green

Write-Host "🔄 Updating Container App..." -ForegroundColor Yellow

# Update Container App
az containerapp update `
    --name "monitor-worker" `
    --resource-group $ResourceGroupName `
    --image $imageTag

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Container App update failed" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 View logs:" -ForegroundColor Yellow
Write-Host "az containerapp logs show --name monitor-worker --resource-group $ResourceGroupName --follow" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Check status:" -ForegroundColor Yellow
Write-Host "az containerapp show --name monitor-worker --resource-group $ResourceGroupName --query 'properties.runningStatus'" -ForegroundColor White