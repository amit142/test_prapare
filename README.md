# Azure VM Status API

This project provides an API to check the number of running VMs in Azure.

## Features

- FastAPI application that connects to Azure
- Dockerized deployment
- Infrastructure as Code with Terraform
- CI/CD pipelines with Jenkins and Azure DevOps
- Kubernetes deployment

## Setup Instructions

### Prerequisites

- Python 3.8+
- Docker and Docker Compose
- Terraform
- Azure CLI
- Kubernetes CLI (kubectl)

### Local Development

1. Clone the repository
2. Create a virtual environment: `python -m venv venv`
3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - Unix/MacOS: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Set up environment variables:
   ```
   AZURE_SUBSCRIPTION_ID=your-subscription-id
   ```
6. Run the application: `uvicorn app:app --reload --port 5001`

### Docker Deployment

```bash
docker build -t azure-vm-status-api .
docker run -p 5001:5001 -e AZURE_SUBSCRIPTION_ID=your-subscription-id azure-vm-status-api
```

## Infrastructure

Terraform is used to provision the necessary infrastructure on Azure.

## CI/CD

The project includes both Jenkins and Azure DevOps pipeline configurations for continuous integration and deployment.

## Kubernetes

Kubernetes manifests are provided for deploying the application to a Kubernetes cluster. 