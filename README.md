# Real-Time WebSocket Chat Application - DevOps Deployment

## Project Overview

This project demonstrates the deployment of a real-time WebSocket chat application using Docker, Docker Compose, NGINX, FastAPI, AWS EC2, GitHub Actions, Redis, Netdata, Terraform, AWS Application Load Balancer, and Auto Scaling.

The provided deployment configuration contained multiple issues related to container networking, frontend volume mounting, NGINX reverse proxy configuration, and WebSocket communication.

These issues were identified and fixed, and the application was successfully deployed on AWS.

The application supports multiple users communicating in real time through WebSocket connections.

The project was further extended with Infrastructure as Code, monitoring, load balancing, and automatic scaling.

---

## Technologies Used

- Docker
- Docker Compose
- NGINX
- FastAPI
- Uvicorn
- WebSocket
- Redis
- Netdata
- Terraform
- AWS EC2
- AWS Application Load Balancer (ALB)
- AWS Auto Scaling
- AWS Launch Templates
- AWS Security Groups
- GitHub
- GitHub Actions
- Linux / Ubuntu

---

## Architecture

```text
                         Users
                           |
                           | HTTP / WebSocket
                           v
                +-----------------------+
                | AWS Application Load  |
                | Balancer (ALB)        |
                | Port 80               |
                +-----------+-----------+
                            |
                            v
                    AWS Target Group
                            |
                 +----------+----------+
                 |                     |
                 v                     v
           +-----------+         +-----------+
           | EC2       |         | EC2       |
           | Instance  |         | ASG       |
           +-----+-----+         +-----+-----+
                 |                     |
                 +----------+----------+
                            |
                     Docker Compose
                            |
          +-----------------+-----------------+
          |                 |                 |
          v                 v                 v
      +-------+         +---------+       +---------+
      | NGINX |         | FastAPI |       | Redis   |
      | :80   |-------->| :8000   |       | :6379   |
      +-------+         +---------+       +---------+

                         Netdata
                         :19999
                            |
                     System Monitoring
```

### Infrastructure Provisioning

```text
                       Terraform
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
         EC2              ALB          Auto Scaling
                                            |
                                            v
                                      Launch Template
```

### CI/CD Deployment Flow

```text
Developer
    |
    | git push
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    | SSH
    v
AWS EC2
    |
    | git pull
    | docker compose down
    | docker compose up -d --build
    v
Application Updated Automatically
```

---

## Project Structure

```text
websocket-devops-assignment/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── app/
│   ├── main.py
│   └── requirements.txt
├── frontend/
│   └── index.html
├── docs/
│   └── architecture.md
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── alb.tf
│   ├── autoscaling.tf
│   └── .terraform.lock.hcl
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
├── .gitignore
└── README.md
```

---

# Docker Deployment

## Docker Container Setup

The application uses multiple Docker containers managed using Docker Compose.

The main services are:

```text
chat-nginx
chat-backend
chat-redis
chat-netdata
```

---

## Backend Container

The backend runs a FastAPI application using Uvicorn on port `8000`.

The application is bound to:

```text
0.0.0.0:8000
```

This allows the backend to accept connections from other containers on the Docker network.

The backend port is not required to be directly exposed to the public internet because NGINX acts as the reverse proxy.

---

## NGINX Container

NGINX runs on port `80` and performs two main tasks:

1. Serves the frontend files.
2. Reverse proxies WebSocket requests to the FastAPI backend.

The frontend directory is mounted inside the NGINX container using a read-only Docker volume.

```yaml
- ./frontend:/usr/share/nginx/html:ro
```

---

## Docker Networking

Docker Compose automatically creates an internal network for the services.

NGINX communicates with the backend using:

```text
backend:8000
```

instead of:

```text
localhost:8000
```

This is necessary because `localhost` inside the NGINX container refers to the NGINX container itself.

Docker's internal DNS resolves the `backend` service name to the backend container.

---

# NGINX Reverse Proxy

NGINX acts as the application entry point.

Users connect over HTTP and WebSocket traffic.

NGINX forwards WebSocket requests from:

```text
/ws
```

to:

```text
http://backend:8000/ws
```

---

## WebSocket Configuration

WebSocket connections require HTTP connection upgrade headers.

The following configuration was enabled in NGINX:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

This allows NGINX to maintain persistent WebSocket connections between clients and the FastAPI backend.

The application was tested using multiple browser windows, and messages were successfully delivered between connected users in real time.

---

# Issues Found and Fixed

## Issue 1: Backend Bound to Localhost

### Problem

The backend was configured to run on:

```text
127.0.0.1:8000
```

This prevented the NGINX container from communicating with the backend.

### Fix

Changed the Uvicorn host to:

```text
0.0.0.0
```

---

## Issue 2: Frontend Was Not Mounted

### Problem

The frontend volume mapping in `docker-compose.yml` was commented out.

Therefore, NGINX could not serve the application frontend.

### Fix

Added:

```yaml
- ./frontend:/usr/share/nginx/html:ro
```

---

## Issue 3: Incorrect Backend Address in NGINX

### Problem

NGINX was configured with:

```text
localhost:8000
```

Inside the NGINX container, `localhost` refers to NGINX itself and not the backend container.

### Fix

Changed the upstream address to:

```text
backend:8000
```

Docker's internal DNS resolves the backend service name.

---

## Issue 4: Missing WebSocket Upgrade Headers

### Problem

The required WebSocket headers were disabled in the original NGINX configuration.

### Fix

Enabled:

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

After this change, WebSocket connections worked correctly through NGINX.

---

# Redis Service

Redis was added as an additional Docker Compose service.

```yaml
redis:
  image: redis:7-alpine
  container_name: chat-redis
  restart: always
```

Redis runs internally on:

```text
6379
```

The Redis container was tested using:

```bash
docker exec chat-redis redis-cli ping
```

Successful response:

```text
PONG
```

This confirms that the Redis service is running correctly.

---

# Netdata Monitoring

Netdata was integrated into the Docker Compose deployment for real-time monitoring.

The Netdata service provides visibility into:

- CPU utilization
- Memory usage
- Disk utilization
- Network activity
- System health
- Container-related metrics

Netdata is exposed on:

```text
Port 19999
```

The dashboard can be accessed using:

```text
http://<EC2-PUBLIC-IP>:19999
```

Container health can be checked with:

```bash
docker compose ps
```

The deployed Netdata container was verified as healthy.

---

# Container Restart Policy

Application containers use:

```yaml
restart: always
```

This allows containers to automatically restart after a failure or Docker/server restart.

---

# Local Deployment

Clone the repository:

```bash
git clone https://github.com/namitagrawal2001/websocket-devops-assignment.git
cd websocket-devops-assignment
```

Build and start the containers:

```bash
docker compose up -d --build
```

Check containers:

```bash
docker compose ps
```

Check application logs:

```bash
docker compose logs
```

Test Redis:

```bash
docker exec chat-redis redis-cli ping
```

Open the application:

```text
http://localhost
```

Open Netdata:

```text
http://localhost:19999
```

---

# AWS EC2 Deployment

The application was successfully deployed on Ubuntu-based AWS EC2 instances.

Docker, Docker Compose, and Git are installed on the server.

Example installation:

```bash
sudo apt update
sudo apt-get install docker.io docker-compose-v2 git -y
```

Clone the repository:

```bash
git clone https://github.com/namitagrawal2001/websocket-devops-assignment.git
cd websocket-devops-assignment
```

Deploy:

```bash
docker compose up -d --build
```

Verify:

```bash
docker compose ps
```

---

# Security Groups

Security groups were configured to allow the required traffic.

The infrastructure uses ports including:

```text
22     SSH
80     HTTP
19999  Netdata Monitoring
```

The FastAPI backend port `8000` and Redis port `6379` do not need to be exposed directly to public users because application services communicate through the Docker network.

---

# CI/CD Pipeline

GitHub Actions is used to automatically deploy application changes.

The workflow is stored at:

```text
.github/workflows/deploy.yml
```

Whenever code is pushed to the `main` branch:

1. GitHub Actions starts automatically.
2. The workflow connects to the deployment EC2 server using SSH.
3. The latest repository changes are pulled.
4. Existing containers are stopped.
5. Docker images are rebuilt.
6. Containers are started using Docker Compose.
7. The updated application becomes available.

The following GitHub repository secrets are used:

```text
EC2_HOST
EC2_USER
EC2_SSH_KEY
```

Sensitive SSH credentials are stored using GitHub Secrets and are not committed to the repository.

---

# Infrastructure as Code with Terraform

Terraform was implemented to provision and manage AWS infrastructure.

Terraform configuration is stored in:

```text
terraform/
```

The Terraform configuration includes:

```text
provider.tf
variables.tf
main.tf
outputs.tf
alb.tf
autoscaling.tf
```

Terraform was initialized and validated using:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

The configuration successfully passed Terraform validation.

Infrastructure was deployed using:

```bash
terraform apply
```

Terraform provisions and manages components including:

- AWS EC2 instance
- Security groups
- Application Load Balancer
- Target group
- HTTP listener
- Launch Template
- Auto Scaling Group
- CPU-based Auto Scaling policy

---

# Application Load Balancer

An AWS Application Load Balancer was provisioned using Terraform.

The ALB accepts incoming HTTP traffic on port `80`.

Traffic flow:

```text
User
  |
  v
Application Load Balancer
  |
  v
Target Group
  |
  v
Healthy EC2 Instances
  |
  v
NGINX
  |
  v
FastAPI WebSocket Backend
```

The deployed ALB endpoint is:

```text
http://websocket-chat-alb-715401839.ap-south-1.elb.amazonaws.com
```

The real-time WebSocket chat application was successfully tested through this endpoint.

---

# Target Group Health

The ALB target group was verified using AWS CLI.

The deployed infrastructure reported two healthy targets during testing:

```text
i-05a2b6798e30917e9    healthy
i-0e90981807d183967    healthy
```

This confirms that the load balancer can successfully route requests to the registered application instances.

---

# AWS Auto Scaling

AWS Auto Scaling was implemented to provide automatic application capacity management.

The Auto Scaling Group uses:

```text
Minimum capacity: 1
Desired capacity: 1
Maximum capacity: 2
```

A Launch Template is used to create application instances.

During initialization, instances install the required software, clone the GitHub repository, and start the application through Docker Compose.

The Auto Scaling Group is connected to the same ALB target group.

---

## Auto Scaling Health

The Auto Scaling instance was verified through AWS CLI.

Example verified state:

```text
Instance: i-0e90981807d183967
Availability Zone: ap-south-1a
Lifecycle State: InService
Health Status: Healthy
```

This confirms that the Auto Scaling Group successfully launched and registered an operational EC2 instance.

---

# CPU-Based Scaling

A target tracking Auto Scaling policy was configured.

The policy monitors:

```text
ASGAverageCPUUtilization
```

Target utilization:

```text
60%
```

The configuration allows AWS Auto Scaling to adjust capacity based on CPU demand while respecting the configured minimum and maximum capacity.

---

# Live Deployment

The recommended application endpoint is the AWS Application Load Balancer:

```text
http://websocket-chat-alb-715401839.ap-south-1.elb.amazonaws.com
```

Using the ALB endpoint instead of an individual EC2 public IP allows traffic to be distributed across registered healthy instances.

Netdata monitoring is available on port `19999` of an EC2 instance where the Netdata container is running.

---

# Testing and Verification

The deployment was tested for:

- Docker image build
- Docker container health
- NGINX frontend serving
- Docker container networking
- WebSocket connection through NGINX
- Multiple simultaneous users
- Real-time message delivery
- Redis availability
- Netdata monitoring
- AWS EC2 deployment
- GitHub Actions deployment
- Terraform validation
- Terraform infrastructure deployment
- Application Load Balancer routing
- Target group health
- Auto Scaling instance creation
- Auto Scaling health checks
- WebSocket application through ALB

Two browser sessions were connected simultaneously and messages were successfully exchanged in real time.

The application was also successfully accessed through the AWS Application Load Balancer.

---

# Bonus Features Implemented

The following additional DevOps features were implemented:

### Redis

Redis was deployed as a Docker container and verified using `redis-cli ping`.

### Netdata

Netdata was deployed for real-time server and container monitoring.

### Terraform

AWS infrastructure was defined and provisioned using Infrastructure as Code.

### Application Load Balancer

An ALB was configured to distribute traffic across healthy application instances.

### Auto Scaling

An AWS Auto Scaling Group and Launch Template were configured to automatically manage application instances.

### CPU-Based Scaling

A target tracking policy was configured with a target CPU utilization of `60%`.

---

# Final Result

The originally broken deployment configuration was successfully debugged, fixed, deployed, and extended with additional DevOps infrastructure.

The final implementation provides:

- Containerized FastAPI backend
- NGINX reverse proxy
- Static frontend hosting
- WebSocket proxy support
- Docker Compose networking
- Redis service
- Netdata monitoring
- Automatic container restart
- AWS EC2 cloud deployment
- GitHub Actions CI/CD
- Terraform Infrastructure as Code
- AWS Application Load Balancer
- ALB target group health checks
- AWS Launch Template
- AWS Auto Scaling Group
- CPU-based scaling policy
- Multiple healthy EC2 targets
- Real-time WebSocket communication through the ALB

This implementation demonstrates a complete containerized deployment workflow with CI/CD, monitoring, Infrastructure as Code, load balancing, and automatic scaling.