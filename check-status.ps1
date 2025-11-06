# Monitor Worker Status Check Script
# Run this to check the status of your application

Write-Host "🔍 Checking Monitor Worker Status..." -ForegroundColor Cyan

try {
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
    Write-Host "`n📊 Recent Health Checks:" -ForegroundColor Yellow
    $logs = az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --tail 20 | ConvertFrom-Json
    
    $healthLogs = $logs | Where-Object { $_.Log -like "*Frontend respondeu*" -or $_.Log -like "*Executando health check*" } | Select-Object -First 5
    
    foreach ($log in $healthLogs) {
        $timestamp = ([DateTime]$log.TimeStamp).ToString("HH:mm:ss")
        if ($log.Log -like "*Frontend respondeu*") {
            Write-Host "  ✅ $timestamp - $($log.Log)" -ForegroundColor Green
        } else {
            Write-Host "  � $timestamp - $($log.Log)" -ForegroundColor Cyan
        }
    }

    # Check replica count
    Write-Host "`n📈 Container Details:" -ForegroundColor Yellow
    az containerapp show --name monitor-worker-dev --resource-group rg-monitor-dev --query "{CPU:properties.template.containers[0].resources.cpu, Memory:properties.template.containers[0].resources.memory, MinReplicas:properties.template.scale.minReplicas, MaxReplicas:properties.template.scale.maxReplicas}" --output table

} catch {
    Write-Host "❌ Error checking status: $_" -ForegroundColor Red
}

Write-Host "`n💡 Commands:" -ForegroundColor Cyan
Write-Host "  Real-time logs: az containerapp logs show --name monitor-worker-dev --resource-group rg-monitor-dev --follow" -ForegroundColor White
Write-Host "  Azure Portal: https://portal.azure.com (search for 'monitor-worker-dev')" -ForegroundColor White
Write-Host "  GitHub Actions: https://github.com/guilhermebergamo/monitor-worker/actions" -ForegroundColor White