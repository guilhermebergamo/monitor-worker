Write-Host "🔍 Monitor Worker Status Check" -ForegroundColor Cyan

Write-Host "`n📱 Container App Status:" -ForegroundColor Yellow
az containerapp show --name monitor-worker-dev --resource-group rg-monitor-dev --query "properties.runningStatus" --output tsv

Write-Host "`n📊 Recent Health Checks:" -ForegroundColor Yellow  
az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --tail 10

Write-Host "`n💡 Para logs em tempo real:" -ForegroundColor Cyan
Write-Host "az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --follow" -ForegroundColor White

Write-Host "`n🌐 Links úteis:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "GitHub Actions: https://github.com/guilhermebergamo/monitor-worker/actions" -ForegroundColor White