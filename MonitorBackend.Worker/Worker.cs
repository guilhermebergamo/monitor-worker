namespace MonitorBackend.Worker;

/// <summary>
/// Worker Service que executa periodicamente uma chamada HTTP ao frontend.
/// Mantém o frontend "aquecido" e monitora sua disponibilidade.
/// </summary>
public sealed class FrontendHealthCheckWorker : BackgroundService
{
    private readonly ILogger<FrontendHealthCheckWorker> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly int _intervalMinutes;
    private readonly string _frontendUrl;

    public FrontendHealthCheckWorker(
        ILogger<FrontendHealthCheckWorker> logger,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _httpClientFactory = httpClientFactory ?? throw new ArgumentNullException(nameof(httpClientFactory));
        _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));

        _intervalMinutes = _configuration.GetValue<int>("WorkerSettings:IntervalMinutes", 3);
        _frontendUrl = _configuration.GetValue<string>("WorkerSettings:FrontendHealthCheckUrl")
            ?? "http://localhost:5173";
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "Frontend Health Check Worker iniciado. Intervalo: {Interval} minutos. URL: {Url}",
            _intervalMinutes, _frontendUrl);

        // Aguarda 30 segundos antes da primeira execução
        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            await ExecuteHealthCheckAsync(stoppingToken);

            var delay = TimeSpan.FromMinutes(_intervalMinutes);
            _logger.LogInformation("Próxima execução em {Minutes} minutos", _intervalMinutes);
            await Task.Delay(delay, stoppingToken);
        }

        _logger.LogInformation("Frontend Health Check Worker finalizando...");
    }

    private async Task ExecuteHealthCheckAsync(CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("Executando health check no frontend: {Url}", _frontendUrl);

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.Timeout = TimeSpan.FromSeconds(30);

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var response = await httpClient.GetAsync(_frontendUrl, cancellationToken);
            stopwatch.Stop();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "✅ Frontend respondeu com sucesso! Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning(
                    "⚠️ Frontend respondeu com erro. Status: {StatusCode}, Tempo: {ElapsedMs}ms",
                    (int)response.StatusCode, stopwatch.ElapsedMilliseconds);
            }
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "❌ Erro de rede ao chamar o frontend");
        }
        catch (TaskCanceledException ex)
        {
            if (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogError(ex, "⏱️ Timeout ao chamar o frontend");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro não esperado ao executar health check");
        }
    }
}
