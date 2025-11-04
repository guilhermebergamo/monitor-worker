# Monitor Worker - Azure Container Apps

Worker Service em .NET 9 que executa health checks periódicos em um frontend para mantê-lo "aquecido" e monitorar sua disponibilidade.

## � Deploy Automático via GitHub Actions

### **Configuração Inicial (faça uma vez apenas):**

1. **Configure os Secrets no GitHub:**
   - Vá para `Settings > Secrets and variables > Actions`
   - Adicione o secret `AZURE_CREDENTIALS_DEV` (veja arquivo GITHUB_SETUP.md)
   - Adicione a variável `FRONTEND_URL_DEV` com valor: `https://white-river-0f9f4b40f.3.azurestaticapps.net`

2. **Configure as branches:**
   ```bash
   git checkout -b develop
   git push origin develop
   ```

### **Deploy Automático:**

- **Push na branch `develop`** → Deploy automático no ambiente DEV
- **Push na branch `main`** → Deploy no ambiente PROD (quando configurado)

## 📋 Pré-requisitos Locais

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Docker](https://www.docker.com/get-started) (opcional, para testes locais)

## 🏗️ Deploy Manual Passo a Passo

### 1. Criar Resource Group
```bash
az group create --name monitor-worker-rg --location eastus
```

### 2. Deploy da Infraestrutura
```bash
az deployment group create \
  --resource-group monitor-worker-rg \
  --template-file azure/main.bicep \
  --parameters azure/main.parameters.json \
  --parameters frontendUrl="https://seu-frontend.azurestaticapps.net"
```

### 3. Build e Push da Imagem
```bash
# Obter nome do registry
REGISTRY_NAME=$(az deployment group show \
  --resource-group monitor-worker-rg \
  --name main \
  --query "properties.outputs.containerRegistryName.value" -o tsv)

# Login no ACR
az acr login --name $REGISTRY_NAME

# Build e push da imagem
REGISTRY_SERVER=$(az acr show --name $REGISTRY_NAME --query "loginServer" -o tsv)
docker build -t $REGISTRY_SERVER/monitor-worker:latest .
docker push $REGISTRY_SERVER/monitor-worker:latest
```

### 4. Atualizar Container App
```bash
az containerapp update \
  --name monitor-worker \
  --resource-group monitor-worker-rg \
  --image $REGISTRY_SERVER/monitor-worker:latest
```

## 🛠️ Desenvolvimento Local

### Build local
```powershell
.\build-local.ps1
```

### Executar localmente
```bash
docker run -d -p 8080:8080 \
  -e WorkerSettings__FrontendHealthCheckUrl="http://localhost:3000" \
  -e WorkerSettings__IntervalMinutes="1" \
  --name monitor-worker-local \
  monitor-worker:latest
```

### Ver logs
```bash
docker logs -f monitor-worker-local
```

## 📊 Monitoramento

### Ver logs no Azure
```bash
az containerapp logs show \
  --name monitor-worker \
  --resource-group monitor-worker-rg \
  --follow
```

### Métricas no Portal
1. Acesse o [Azure Portal](https://portal.azure.com)
2. Navegue até Resource Groups > monitor-worker-rg
3. Clique no Container App "monitor-worker"
4. Vá para "Logs" ou "Metrics"

## ⚙️ Configuração

### Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|---------|
| `WorkerSettings__FrontendHealthCheckUrl` | URL do frontend para monitorar | `https://your-frontend.azurestaticapps.net` |
| `WorkerSettings__IntervalMinutes` | Intervalo entre checks em minutos | `5` |
| `ASPNETCORE_ENVIRONMENT` | Ambiente de execução | `Production` |

### Personalizar Configurações

Edite o arquivo `azure/main.parameters.json`:

```json
{
  "parameters": {
    "frontendUrl": {
      "value": "https://seu-frontend.azurestaticapps.net"
    },
    "intervalMinutes": {
      "value": 3
    }
  }
}
```

## 🔄 CI/CD com GitHub Actions

### Configurar Secrets

1. Crie um Service Principal:
```bash
az ad sp create-for-rbac --name "monitor-worker-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/monitor-worker-rg \
  --sdk-auth
```

2. Adicione o output como secret `AZURE_CREDENTIALS` no GitHub

3. Adicione a variável `FRONTEND_URL` no GitHub

### Deploy Automático

O deploy será executado automaticamente a cada push na branch `main`.

## 📁 Estrutura do Projeto

```
📦 monitor-worker/
├── 📂 azure/                    # Infraestrutura como código
│   ├── main.bicep              # Template Bicep principal
│   └── main.parameters.json    # Parâmetros do Bicep
├── 📂 .github/workflows/       # CI/CD
│   └── deploy.yml              # GitHub Actions workflow
├── 📂 MonitorBackend.Worker/   # Código fonte
│   ├── Program.cs              # Ponto de entrada
│   ├── Worker.cs               # Lógica do worker
│   └── *.json                  # Configurações
├── Dockerfile                  # Containerização
├── .dockerignore              # Exclusões do Docker
├── deploy.ps1                 # Script de deploy
├── build-local.ps1           # Build local
└── README.md                  # Esta documentação
```

## 🐛 Troubleshooting

### Container não inicia
```bash
# Verificar logs
az containerapp logs show --name monitor-worker --resource-group monitor-worker-rg

# Verificar configuração
az containerapp show --name monitor-worker --resource-group monitor-worker-rg
```

### Problemas de conectividade
```bash
# Testar health check manual
curl -v https://seu-frontend.azurestaticapps.net

# Verificar DNS
nslookup seu-frontend.azurestaticapps.net
```

### Rebuild da imagem
```bash
# Forçar rebuild
az containerapp update \
  --name monitor-worker \
  --resource-group monitor-worker-rg \
  --image $REGISTRY_SERVER/monitor-worker:$(date +%s)
```

## 💰 Estimativa de Custos

- **Container Apps**: ~$15-30/mês (0.25 vCPU, 0.5GB RAM)
- **Container Registry**: ~$5/mês (Basic tier)
- **Log Analytics**: ~$2-5/mês (dados básicos)

**Total estimado**: ~$22-40/mês

## 📞 Suporte

Para dúvidas ou problemas:
1. Verificar logs com `az containerapp logs show`
2. Consultar documentação do [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
3. Criar issue neste repositório