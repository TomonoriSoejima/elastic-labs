# Node.js + MySQL APM Project

Full-stack Node.js application with MySQL database and Elastic APM instrumentation.

## Architecture

- Node.js backend with Express
- MySQL database
- Elastic APM for monitoring
- Docker Compose setup

## Structure

```
src/          - Application source code
public/       - Static assets
docker/       - Docker configurations
db/           - Database scripts
config/       - Application config
```

## Setup

```bash
# Install dependencies
npm install

# Start all services
docker-compose up -d
```

## Services

- **App**: http://localhost:3000
- **MySQL**: localhost:3306

## Environment

Copy `.env.example` to `.env` and configure:
- Database credentials
- APM server URL
- APM secret token

## Stop

```bash
docker-compose down
```

## Notes

- MySQL data persists in Docker volume
- APM captures database queries automatically
