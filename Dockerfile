# Use the official .NET 9 runtime as base image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

# Use the .NET 9 SDK for building
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY MonitorBackend.Worker/MonitorBackend.Worker.csproj MonitorBackend.Worker/
RUN dotnet restore MonitorBackend.Worker/MonitorBackend.Worker.csproj

# Copy all source files
COPY . .

# Build the application
WORKDIR /src/MonitorBackend.Worker
RUN dotnet build MonitorBackend.Worker.csproj -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish MonitorBackend.Worker.csproj -c Release -o /app/publish

# Final stage
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Create a non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

ENTRYPOINT ["dotnet", "MonitorBackend.Worker.dll"]