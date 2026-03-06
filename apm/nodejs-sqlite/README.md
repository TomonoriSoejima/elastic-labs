# Node.js + SQLite Docker APM

Lightweight Node.js application with SQLite and Elastic APM in Docker.

## Architecture

- Node.js backend
- SQLite database (file-based)
- Elastic APM monitoring
- Docker containerized

## Structure

```
src/          - Application source code
db/           - SQLite database files
```

## Setup & Run

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f
```

## Access

**App**: http://localhost:3000

## Stop

```bash
docker-compose down
```

## Development

Run locally without Docker:
```bash
npm install
npm start
```

## Notes

- SQLite database stored in `db/` directory
- Lightweight alternative to MySQL setup
- Good for testing APM with embedded databases
