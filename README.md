# VoltTrack Self-Hosted Deployment

Self-hosted production deployment of VoltTrack using Docker Compose.

## Overview

This directory contains everything needed to run VoltTrack on your own infrastructure:

- **Docker Compose** configuration for all services
- **Auto-configured Garage** S3-compatible storage (optional)
- **Production-ready** with health checks and proper dependencies
- **Minimal configuration** required to get started

## Architecture

VoltTrack consists of the following services:

- **postgres** - TimescaleDB for time-series data
- **redis** - Caching and pub/sub
- **auth** - Authentication service (Better Auth)
- **api** - REST API with OpenAPI documentation
- **api-worker** - Background job processor (BullMQ)
- **ws-gateway** - WebSocket server for real-time updates
- **event-bus** - Event processing service
- **client** - React-based web application
- **garage** _(optional)_ - S3-compatible object storage

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- At least 4GB RAM available
- 20GB disk space

## Quick Start

### 1. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and configure:
# - BETTER_AUTH_SECRET (generate with: openssl rand -base64 32)
# - POSTGRES_PASSWORD (use a strong password)
# - GARAGE_RPC_SECRET (if using Garage S3)
# - MAPBOX_KEY (get from https://www.mapbox.com/)
# - Public URLs (BETTER_AUTH_URL, WEBSOCKET_URL, API_URL)
```

### 2. Start Services

**Option A: Without S3 storage** (reports feature disabled)
```bash
docker compose up -d
```

**Option B: With Garage S3** (recommended)
```bash
docker compose --profile s3 up -d
```

### 3. Access VoltTrack

- **Web App**: http://localhost:3000
- **API**: http://localhost:3001
- **API Docs**: http://localhost:3001/docs
- **Redis Insight**: http://localhost:8001

### 4. Check Garage S3 Credentials

If using Garage, check the initialization logs for auto-generated credentials:

```bash
docker logs volttrack-garage-init
```

Copy the displayed credentials to your `.env` file.

## Configuration

### Required Variables

These **must** be set in your `.env` file:

```env
BETTER_AUTH_SECRET=<generate-with-openssl-rand-base64-32>
POSTGRES_PASSWORD=<secure-password>
MAPBOX_KEY=<your-mapbox-api-key>
```

### Image Version

By default, the `dev` environment images are used (built from `develop` branch). To use production images:

```env
VOLTTRACK_ENV=prd
```

Available tags:
- `dev` - Latest from develop branch
- `prd` - Latest from main branch
- Specific commit SHA for pinned versions

### Public URLs

Update these based on how you're accessing VoltTrack:

**For localhost access:**
```env
BETTER_AUTH_URL=http://localhost
API_URL=http://localhost:3001
WEBSOCKET_URL=ws://localhost:3003/ws
```

**For production with reverse proxy:**
```env
BETTER_AUTH_URL=https://volttrack.yourdomain.com
API_URL=https://api.yourdomain.com
WEBSOCKET_URL=wss://ws.yourdomain.com/ws
CORS_CONFIG={"origin": ["https://volttrack.yourdomain.com"], "credentials": true, "exposeHeaders": ["set-cookie"]}
```

### S3 Storage Options

#### Option 1: Garage (Recommended)

Included auto-configured S3-compatible storage:

```bash
# Start with Garage
docker compose --profile s3 up -d

# Check logs for credentials
docker logs volttrack-garage-init
```

Configuration in `.env`:
```env
S3_ENDPOINT=http://garage:3900
AWS_REGION=garage
FORCE_PATH_STYLE=true
```

#### Option 2: External S3

Use AWS S3, MinIO, or any S3-compatible service:

```env
S3_ENDPOINT=https://s3.amazonaws.com
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
AWS_BUCKET=volttrack-reports
AWS_REGION=us-east-1
FORCE_PATH_STYLE=false
```

Then start without the s3 profile:
```bash
docker compose up -d
```

## Production Deployment

### Reverse Proxy Setup

For production, use a reverse proxy (nginx, Traefik, Caddy) to:

- Terminate SSL/TLS
- Handle domain routing
- Implement rate limiting
- Add security headers

Example nginx configuration:

```nginx
# API
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# WebSocket
server {
    listen 443 ssl http2;
    server_name ws.yourdomain.com;
    
    location /ws {
        proxy_pass http://localhost:3003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Client
server {
    listen 443 ssl http2;
    server_name volttrack.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
    }
}
```

### Security Checklist

- [ ] Use strong, unique passwords for all services
- [ ] Generate secure random values for secrets (`openssl rand -base64 32`)
- [ ] Configure CORS to only allow your domains
- [ ] Use SSL/TLS certificates (Let's Encrypt)
- [ ] Restrict database/redis ports (don't expose publicly)
- [ ] Set up firewall rules
- [ ] Enable Docker security features (user namespaces, AppArmor)
- [ ] Regular backups of postgres and garage volumes
- [ ] Keep images updated

### Backups

Backup critical data volumes:

```bash
# Stop services
docker compose down

# Backup postgres
docker run --rm -v volttrack-self-hosted_postgres_data:/data \
  -v $(pwd)/backups:/backup alpine \
  tar czf /backup/postgres-$(date +%Y%m%d).tar.gz -C /data .

# Backup garage (if using)
docker run --rm -v volttrack-self-hosted_garage_data:/data \
  -v $(pwd)/backups:/backup alpine \
  tar czf /backup/garage-$(date +%Y%m%d).tar.gz -C /data .

# Restart services
docker compose up -d
```

### Monitoring

Monitor service health:

```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f

# Check specific service
docker compose logs -f api

# Resource usage
docker stats
```

Health check endpoints:
- API: http://localhost:3001/health
- Auth: http://localhost:3002/health
- WebSocket: http://localhost:3003/health
- Event Bus: http://localhost:3004/health

## Maintenance

### Updating Images

```bash
# Pull latest images
docker compose pull

# Recreate services with new images
docker compose up -d
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api

# Last 100 lines
docker compose logs --tail=100
```

### Restart Services

```bash
# All services
docker compose restart

# Specific service
docker compose restart api
```

### Database Migrations

Migrations run automatically on startup via the `migration` service. To run manually:

```bash
docker compose run --rm migration
```

## Troubleshooting

### Services won't start

Check logs for errors:
```bash
docker compose logs
```

Common issues:
- Port conflicts (another service using 3000-3004, 5432, 6379)
- Missing required environment variables
- Insufficient disk space or memory

### Database connection errors

Ensure postgres is healthy:
```bash
docker compose ps postgres
```

Check postgres logs:
```bash
docker compose logs postgres
```

### Garage S3 issues

Check Garage status:
```bash
docker compose exec garage garage status
```

Re-run initialization:
```bash
docker compose up -d garage-init
docker compose logs garage-init
```

### Authentication errors

Verify `BETTER_AUTH_SECRET` is set and matches across all services. Check auth service logs:
```bash
docker compose logs auth
```

## Scaling

### Horizontal Scaling

For high-traffic deployments, scale services:

```bash
# Scale API workers
docker compose up -d --scale api-worker=3

# Note: auth, ws-gateway need Redis adapter configuration for multi-instance
```

### Resource Limits

Add resource limits in `docker-compose.yaml`:

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Support

For issues and questions:

- Check the main project README: `../README.md`
- Review application logs: `docker compose logs`
- Open an issue on GitHub

## License

See the main project LICENSE file.
