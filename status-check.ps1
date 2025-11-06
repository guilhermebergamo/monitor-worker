Write-Host "Monitor Worker Status Check" -ForegroundColor Cyan

Write-Host "`nContainer App Status:" -ForegroundColor Yellow
az containerapp show --name monitor-worker-dev --resource-group rg-monitor-dev --query "properties.runningStatus" --output tsv

Write-Host "`nRecent Health Checks:" -ForegroundColor Yellow  
az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --tail 10

Write-Host "`nPara logs em tempo real:" -ForegroundColor Cyan
Write-Host "az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --follow" -ForegroundColor White

Write-Host "`nLinks:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "GitHub Actions: https://github.com/guilhermebergamo/monitor-worker/actions" -ForegroundColor White