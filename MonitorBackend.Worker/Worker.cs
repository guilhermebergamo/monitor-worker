using System.Text;
using System.Text.Json;

namespace MonitorBackend.Worker;

/// <summary>
/// Worker Service que executa periodicamente chamadas HTTP para manter a API ativa.
/// Realiza health checks e operações pesadas para manter o backend "aquecido".
/// </summary>
public sealed class FrontendHealthCheckWorker : BackgroundService
{
    private readonly ILogger<FrontendHealthCheckWorker> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly int _intervalMinutes;
    private readonly string _apiBaseUrl;

    public FrontendHealthCheckWorker(
        ILogger<FrontendHealthCheckWorker> logger,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _httpClientFactory = httpClientFactory ?? throw new ArgumentNullException(nameof(httpClientFactory));
        _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));

        _intervalMinutes = _configuration.GetValue<int>("WorkerSettings:IntervalMinutes", 2);
        _apiBaseUrl = _configuration.GetValue<string>("WorkerSettings:ApiBaseUrl")
            ?? "https://monitor-api-dev.livelyisland-44050ad2.centralus.azurecontainerapps.io";
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "Monitor Worker iniciado. Intervalo: {Interval} minutos. API: {Url}",
            _intervalMinutes, _apiBaseUrl);

        // Aguarda 30 segundos antes da primeira execução
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            await ExecuteAllChecksAsync(stoppingToken);

            var delay = TimeSpan.FromMinutes(_intervalMinutes);
            _logger.LogInformation("Próxima execução em {Minutes} minutos", _intervalMinutes);
            await Task.Delay(delay, stoppingToken);
        }

        _logger.LogInformation("Monitor Worker finalizando...");
    }

    private async Task ExecuteAllChecksAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("========================================");
        _logger.LogInformation("Iniciando ciclo de verificações...");
        
        var tasks = new List<Task>
        {
            RegistrarAcessoAsync(cancellationToken),
            ProcessDataAsync(cancellationToken),
            CpuIntensiveAsync(cancellationToken),
            ParallelProcessingAsync(cancellationToken),
            GenerateReportAsync(cancellationToken)
        };

        await Task.WhenAll(tasks);
        
        _logger.LogInformation("Ciclo de verificações concluído!");
        _logger.LogInformation("========================================");
    }

    private async Task RegistrarAcessoAsync(CancellationToken cancellationToken)
    {
        try
        {
            var url = $"{_apiBaseUrl}/api/registros/acesso";
            _logger.LogInformation("📝 Registrando acesso...");

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.Timeout = TimeSpan.FromSeconds(30);

            var payload = new { observacao = "Acesso do worker - Keep Alive" };
            var content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var response = await httpClient.PostAsync(url, content, cancellationToken);
            stopwatch.Stop();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "✅ Acesso registrado! Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning(
                    "⚠️ Erro ao registrar acesso. Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao registrar acesso");
        }
    }

    private async Task ProcessDataAsync(CancellationToken cancellationToken)
    {
        try
        {
            var url = $"{_apiBaseUrl}/api/heavyops/process-data?sizeMB=50";
            _logger.LogInformation("💾 Processando dados (50MB)...");

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.Timeout = TimeSpan.FromMinutes(2);

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var response = await httpClient.GetAsync(url, cancellationToken);
            stopwatch.Stop();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "✅ Dados processados! Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning(
                    "⚠️ Erro ao processar dados. Status: {StatusCode}",
                    (int)response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao processar dados");
        }
    }

    private async Task CpuIntensiveAsync(CancellationToken cancellationToken)
    {
        try
        {
            var url = $"{_apiBaseUrl}/api/heavyops/cpu-intensive?iterations=1000000";
            _logger.LogInformation("🔥 Executando operação CPU intensiva (1M iterações)...");

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.Timeout = TimeSpan.FromMinutes(2);

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var response = await httpClient.GetAsync(url, cancellationToken);
            stopwatch.Stop();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "✅ CPU intensivo concluído! Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning(
                    "⚠️ Erro em CPU intensivo. Status: {StatusCode}",
                    (int)response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro em operação CPU intensiva");
        }
    }

    private async Task ParallelProcessingAsync(CancellationToken cancellationToken)
    {
        try
        {
            var url = $"{_apiBaseUrl}/api/heavyops/parallel-processing?itemCount=30";
            _logger.LogInformation("⚡ Executando processamento paralelo (30 itens)...");

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.Timeout = TimeSpan.FromMinutes(2);

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var response = await httpClient.GetAsync(url, cancellationToken);
            stopwatch.Stop();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "✅ Processamento paralelo concluído! Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning(
                    "⚠️ Erro em processamento paralelo. Status: {StatusCode}",
                    (int)response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro em processamento paralelo");
        }
    }

    private async Task GenerateReportAsync(CancellationToken cancellationToken)
    {
        try
        {
            var url = $"{_apiBaseUrl}/api/heavyops/generate-report?recordCount=50000";
            _logger.LogInformation("📊 Gerando relatório (50k registros)...");

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.Timeout = TimeSpan.FromMinutes(3);

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var response = await httpClient.GetAsync(url, cancellationToken);
            stopwatch.Stop();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "✅ Relatório gerado! Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning(
                    "⚠️ Erro ao gerar relatório. Status: {StatusCode}",
                    (int)response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao gerar relatório");
        }
    }
}
