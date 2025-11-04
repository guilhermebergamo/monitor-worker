# Build and test Docker image locally

# Build the Docker image
docker build -t monitor-worker:latest .

# Test run the container locally
# docker run -d -p 8080:8080 --name monitor-worker-test monitor-worker:latest

Write-Host "Docker image built successfully!"
Write-Host "To run locally: docker run -d -p 8080:8080 --name monitor-worker-test monitor-worker:latest"
Write-Host "To check logs: docker logs monitor-worker-test"
Write-Host "To stop: docker stop monitor-worker-test && docker rm monitor-worker-test"