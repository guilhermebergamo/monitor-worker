# Monitor Worker Status Check Script
param()

Write-Host "🔍 Checking Monitor Worker Status..." -ForegroundColor Cyan

# Reload PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Check if logged in
$account = az account show --query "user.name" -o tsv 2>$null
if (-not $account) {
    Write-Host "❌ Please login: az login" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Logged in as: $account" -ForegroundColor Green

# Check Container App Status
Write-Host "`n📱 Container App Status:" -ForegroundColor Yellow
$status = az containerapp show --name monitor-worker-dev --resource-group rg-monitor-dev --query "properties.runningStatus" --output tsv

if ($status -eq "Running") {
    Write-Host "✅ Status: $status" -ForegroundColor Green
} else {
    Write-Host "⚠️ Status: $status" -ForegroundColor Yellow
}

# Get recent logs  
Write-Host "`n📊 Recent Logs:" -ForegroundColor Yellow
az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --tail 5

# Container details
Write-Host "`n📈 Container Details:" -ForegroundColor Yellow
az containerapp show --name monitor-worker-dev --resource-group rg-monitor-dev --query "{CPU:properties.template.containers[0].resources.cpu, Memory:properties.template.containers[0].resources.memory}" --output table

Write-Host "`n💡 Useful Commands:" -ForegroundColor Cyan
Write-Host "  Real-time logs: az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --follow" -ForegroundColor White
Write-Host "  Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "  GitHub Actions: https://github.com/guilhermebergamo/monitor-worker/actions" -ForegroundColor White