# Oracle + Elastic Agent Lab

Pre-configured Docker environment for testing Oracle integrations with Elastic Agent.

## Features

- **Oracle Database 23c Free** (gvenzl/oracle-free:23-slim)
- **Custom Elastic Agent 9.3.0** with Oracle Instant Client 23.4 baked in
- Monitoring user with all required grants pre-configured
- No runtime installation needed - Oracle client persists across container restarts

## Quick Start

```bash
# Build custom agent image (one time)
docker build --platform linux/amd64 -t elastic-agent-oracle:9.3.0 .

# Start the lab
docker-compose up -d

# Wait for Oracle to be healthy (~30 seconds)
docker-compose ps

# Test Oracle connection
docker exec oracle-test sqlplus elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1 <<< "SELECT 'Connected!' FROM dual;"
```

## Configuration

### Oracle Database
- **Host:** localhost:1521
- **PDB:** FREEPDB1
- **SYS password:** OracleTest123
- **Monitoring user:** elastic_monitor / ElasticMon123
- **Character set:** AL32UTF8

### Monitoring User Grants
The `elastic_monitor` user has:
- `SELECT_CATALOG_ROLE`
- SELECT on `SYS.DBA_DATA_FILES`, `SYS.DBA_TEMP_FILES`
- SELECT on `DBA_FREE_SPACE`, `DBA_TABLESPACE_USAGE_METRICS`, `DBA_TABLESPACES`, `DBA_TEMP_FREE_SPACE`
- SELECT on 11 V_$ views (SYSMETRIC, SYSTEM_EVENT, SESSION, DATABASE, INSTANCE, etc.)

### Elastic Agent
- **Version:** 9.3.0
- **Oracle Client:** Instant Client 23.4 basiclite
- **Library Path:** `/opt/oracle/instantclient_23_4`
- **Platform:** linux/amd64 (required for Oracle client compatibility on ARM Macs)

## Testing Queries

```bash
# Quick test - count tablespaces
docker exec oracle-test bash -c "echo 'SELECT COUNT(*) FROM dba_tablespaces;' | sqlplus -s elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1"

# Run SQL files from host machine (pipe method)
cat analysis/tablespace-query.sql | docker exec -i oracle-test sqlplus -s elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1
```

**Note:** The `@filename` syntax in sqlplus looks for files **inside** the container's filesystem. Since SQL files are on your host machine, use the pipe method shown above to execute them.

## Customization

### Fleet Enrollment
To enroll the agent with Fleet, update `docker-compose.yml`:

```yaml
environment:
  - FLEET_URL=https://your-fleet-server:443
  - FLEET_ENROLLMENT_TOKEN=your-token-here
  - FLEET_INSECURE=1  # Use 0 for production with valid certs
```

### Oracle Version
The monitoring user creation script is in `scripts/create-user-manual.sql`. 
Run it manually after the database starts:

```bash
docker exec -it oracle-test sqlplus sys/OracleTest123@localhost:1521/FREEPDB1 as sysdba @/path/to/create-user-manual.sql
```

## Architecture

```
┌─────────────────────────┐     ┌──────────────────────────┐
│  Elastic Agent          │────▶│  Oracle Database 23c     │
│  (custom image)         │     │  (FREEPDB1)              │
│                         │     │                          │
│  - Oracle Client 23.4   │     │  - User: elastic_monitor │
│  - libaio1              │     │  - Port: 1521            │
│  - LD_LIBRARY_PATH set  │     │  - Enterprise Manager    │
└─────────────────────────┘     │    Port: 5500            │
                                └──────────────────────────┘
```

## Cleanup

```bash
# Stop containers
docker-compose down

# Remove volumes (deletes database data)
docker-compose down -v

# Remove custom image
docker rmi elastic-agent-oracle:9.3.0
```

## Notes

- Oracle data persists in Docker volume `oracle-data`
- On ARM Macs, `platform: linux/amd64` is required (Oracle doesn't provide ARM64 Linux client)
- Oracle Instant Client is baked into the image - no installation at startup
- Client library verified with `ldconfig -p | grep oracle`

## Troubleshooting

**Oracle not starting:**
```bash
docker logs oracle-test
```

**Agent connection issues:**
```bash
docker logs elastic-agent-test
```

**Verify Oracle client:**
```bash
docker exec elastic-agent-test bash -c "ldconfig -p | grep oracle"
```
