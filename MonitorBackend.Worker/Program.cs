using MonitorBackend.Worker;

var builder = Host.CreateApplicationBuilder(args);

// Registra HttpClientFactory
builder.Services.AddHttpClient();

// Registra o Worker Service
builder.Services.AddHostedService<FrontendHealthCheckWorker>();

// Configuração de logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

var host = builder.Build();
host.Run();
