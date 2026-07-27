# Real-Time WebSocket Chat Application - DevOps Deployment

## Project Overview

This project demonstrates the deployment of a real-time WebSocket chat application using Docker, Docker Compose, NGINX, AWS EC2, and GitHub Actions.

The provided deployment configuration contained multiple issues related to container networking, frontend volume mounting, NGINX reverse proxy configuration, and WebSocket communication.

These issues were identified and fixed, and the application was successfully deployed on an AWS EC2 instance.

The application supports multiple users communicating in real time through WebSocket connections.

---

## Technologies Used

- Docker
- Docker Compose
- NGINX
- FastAPI
- Uvicorn
- WebSocket
- AWS EC2
- GitHub
- GitHub Actions
- Linux / Ubuntu

---

## Architecture

```text
                         User Browser
                              |
                              | HTTP / WebSocket
                              v
                    AWS EC2 Public IP
                       Port 80
                              |
                              v
                    +-----------------+
                    |      NGINX      |
                    |    Container    |
                    |   chat-nginx    |
                    +--------+--------+
                             |
               Docker Compose Network
                             |
                             | WebSocket /ws
                             v
                    +-----------------+
                    | FastAPI Backend |
                    |    Container    |
                    |  chat-backend   |
                    |    Port 8000    |
                    +-----------------+


                    CI/CD Deployment Flow

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
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
└── README.md
```

---

## Docker Container Setup

The application uses two Docker containers.

### Backend Container

The backend runs a FastAPI application using Uvicorn on port `8000`.

The application is bound to:

```text
0.0.0.0:8000
```

This allows the backend to accept connections from other containers on the Docker network.

### NGINX Container

NGINX runs on port `80` and performs two main tasks:

1. Serves the frontend files.
2. Reverse proxies WebSocket requests to the backend container.

The frontend directory is mounted inside the NGINX container using a Docker volume.

---

## Docker Networking

Docker Compose automatically creates a network for the services.

Both:

```text
chat-nginx
chat-backend
```

run on the same Docker Compose network.

NGINX communicates with the backend using the Docker Compose service name:

```text
backend:8000
```

instead of:

```text
localhost:8000
```

This is necessary because `localhost` inside the NGINX container refers to the NGINX container itself.

---

## NGINX Reverse Proxy

NGINX acts as the public entry point for the application.

Users connect to:

```text
HTTP Port 80
```

NGINX serves the frontend and forwards WebSocket requests from:

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

This allows NGINX to maintain persistent WebSocket connections between users and the FastAPI backend.

The application was tested using multiple browser windows, and messages were successfully delivered between connected users in real time.

---

## Issues Found and Fixed

### Issue 1: Backend Bound to Localhost

**Problem**

The backend was configured to run on:

```text
127.0.0.1:8000
```

This prevented the NGINX container from communicating with the backend.

**Fix**

Changed the Uvicorn host in the Dockerfile to:

```text
0.0.0.0
```

---

### Issue 2: Frontend Was Not Mounted

**Problem**

The frontend volume mapping in `docker-compose.yml` was commented out.

Therefore, NGINX could not serve the application frontend.

**Fix**

Added:

```yaml
- ./frontend:/usr/share/nginx/html:ro
```

---

### Issue 3: Incorrect Backend Address in NGINX

**Problem**

NGINX was configured with:

```text
localhost:8000
```

Inside the NGINX container, `localhost` refers to NGINX itself and not the backend container.

**Fix**

Changed the upstream address to:

```text
backend:8000
```

Docker's internal DNS resolves the `backend` service name.

---

### Issue 4: Missing WebSocket Upgrade Headers

**Problem**

The required WebSocket headers were disabled in the original NGINX configuration.

**Fix**

Enabled:

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

After the fix, WebSocket connections worked correctly through NGINX.

---

## Container Restart Policy

Both containers use:

```yaml
restart: always
```

This ensures the application containers automatically restart if they crash or when the Docker service/server restarts.

---

## Local Deployment

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

Check logs:

```bash
docker compose logs
```

Open:

```text
http://localhost
```

---

## AWS EC2 Deployment

The application was deployed on an Ubuntu AWS EC2 instance.

### Security Group

The following inbound ports were configured:

```text
22  - SSH
80  - HTTP
443 - HTTPS
```

The backend port `8000` is not exposed publicly because communication between NGINX and the backend occurs through the Docker network.

### Server Setup

Install Docker:

```bash
sudo apt update
sudo apt-get install docker.io -y
```

Install Docker Compose:

```bash
sudo apt-get install docker-compose-v2 -y
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

---

## CI/CD Pipeline

GitHub Actions is used to automatically deploy new changes to AWS EC2.

The workflow is stored at:

```text
.github/workflows/deploy.yml
```

### CI/CD Flow

Whenever code is pushed to the `main` branch:

1. GitHub Actions starts automatically.
2. The workflow connects to AWS EC2 using SSH.
3. The server pulls the latest code from GitHub.
4. Existing containers are stopped.
5. Docker images are rebuilt.
6. Containers are started again.
7. The updated application becomes available through the EC2 public IP.

The following GitHub repository secrets are used:

```text
EC2_HOST
EC2_USER
EC2_SSH_KEY
```

Sensitive SSH credentials are stored in GitHub Secrets and are not committed to the repository.

---

## Live Deployment

The application is deployed on AWS EC2 and accessible through the server's public IP:

```text
http://13.126.253.239
```

> Note: The public IP may change if the EC2 instance is stopped and started unless an Elastic IP is assigned.

---

## Testing

The deployment was tested for:

- Docker container health
- NGINX frontend serving
- Docker container networking
- WebSocket connection through NGINX
- Multiple simultaneous users
- Real-time message delivery
- AWS EC2 public access
- GitHub Actions deployment

Two browser sessions were connected simultaneously and messages were successfully exchanged in real time.

---

## Final Result

The originally broken deployment configuration was successfully debugged and fixed.

The final application now provides:

- Containerized FastAPI backend
- NGINX reverse proxy
- Static frontend hosting
- WebSocket proxy support
- Docker Compose networking
- Automatic container restart
- AWS EC2 cloud deployment
- Public application access
- Automated GitHub Actions CI/CD deployment