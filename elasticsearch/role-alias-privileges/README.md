# role-alias-privileges

Reproduction and fix verification for the Elasticsearch deprecation warning:

> "Granting privileges over an alias, and hence granting privileges over all the indices that the alias points to, is deprecated and will be removed in a future version of Elasticsearch. Instead define permissions exclusively on index names or index name patterns."

## Background

The warning fires when a role grants privileges on an alias but grants fewer (or no) privileges on the alias's backing indices within the same role. It does not fire simply because an alias appears in a role's `names` list.

## Requirements

- Docker
- ES 8.19.3 image: `docker pull docker.elastic.co/elasticsearch/elasticsearch:8.19.3`

## Tests

| Test | Role `names` | Expected |
|------|-------------|---------|
| A | `[".lists-helpdesk"]` only | warning fires |
| B | `[".lists-helpdesk", ".lists-helpdesk-*"]` | no warning (KB article fix) |
| C | `[".lists-helpdesk-*"]` only | no warning (alternative fix) |

Each test uses a fresh container so log windows do not overlap.

## Usage

```bash
# Run all three tests
bash test.sh

# Run a single test
bash test.sh a
bash test.sh b
bash test.sh c
```

## Fix

Add the backing index pattern alongside the alias in the same role entry. Keep the alias — removing it breaks queries that go through the alias.

```json
{
  "names": [".lists-helpdesk", ".lists-helpdesk-*"],
  "privileges": ["read", "view_index_metadata"]
}
```

## References

- KB article: https://support.elastic.co/knowledge/72407771
- SDH: elastic/sdh-elasticsearch#9950
