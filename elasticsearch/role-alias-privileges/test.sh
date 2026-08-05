#!/usr/bin/env bash
# Tests for the alias-based index privileges deprecation warning.
#
# Each test gets a fresh ES container so log windows are clean.
# Requires: docker pull docker.elastic.co/elasticsearch/elasticsearch:8.19.3
#
# Usage:
#   bash test.sh            # run all three tests
#   bash test.sh a          # run only Test A
#   bash test.sh b          # run only Test B
#   bash test.sh c          # run only Test C

set -euo pipefail

ES="http://localhost:9200"
AUTH="elastic:changeme"
RUN=${1:-all}

q() {
  local method=$1 path=$2 body=${3:-}
  if [[ -n "$body" ]]; then
    curl -s -u "$AUTH" -H "Content-Type: application/json" -X "$method" "$ES$path" -d "$body"
  else
    curl -s -u "$AUTH" -X "$method" "$ES$path"
  fi
}

start_es() {
  local name=$1
  docker rm -f "$name" 2>/dev/null || true
  docker run -d \
    --name "$name" \
    -p 9200:9200 \
    -e "discovery.type=single-node" \
    -e "ELASTIC_PASSWORD=changeme" \
    -e "xpack.security.enabled=true" \
    -e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
    docker.elastic.co/elasticsearch/elasticsearch:8.19.3 > /dev/null

  echo -n "  Waiting for ES"
  for i in $(seq 1 40); do
    if curl -s -u "$AUTH" "$ES/_cluster/health" 2>/dev/null | grep -q '"status"'; then
      echo " ready."
      return
    fi
    echo -n "."
    sleep 3
  done
  echo " TIMEOUT" && exit 1
}

stop_es() {
  docker rm -f "$1" > /dev/null 2>&1 || true
}

setup_index_and_alias() {
  q PUT "/.lists-helpdesk-000001" \
    '{"settings":{"number_of_shards":1,"number_of_replicas":0}}' > /dev/null
  q POST "/_aliases" \
    '{"actions":[{"add":{"index":".lists-helpdesk-000001","alias":".lists-helpdesk"}}]}' > /dev/null
  q POST "/.lists-helpdesk-000001/_doc" '{"test":"doc"}' > /dev/null
}

create_user_with_role() {
  local role=$1
  q PUT "/_security/user/test_ntt" \
    "{\"password\":\"password123!\",\"roles\":[\"$role\"]}" > /dev/null
}

trigger() {
  # Two requests through the alias as test_ntt — enough to surface the warning
  curl -s -u "test_ntt:password123!" \
    -H "Content-Type: application/json" \
    -X GET "$ES/.lists-helpdesk/_search" \
    -d '{"query":{"match_all":{}}}' > /dev/null
  curl -s -u "test_ntt:password123!" \
    -H "Content-Type: application/json" \
    -X GET "$ES/.lists-helpdesk/_search" \
    -d '{"query":{"match_all":{}}}' > /dev/null
}

check_log() {
  local container=$1
  sleep 3
  local hits
  hits=$(docker logs "$container" 2>&1 | grep -c "alias.*deprecat\|deprecat.*alias" || true)
  if [[ "$hits" -gt 0 ]]; then
    echo "  RESULT: WARNING PRESENT ($hits line(s))"
    docker logs "$container" 2>&1 \
      | grep -i "alias" | grep -i "deprecat" \
      | sed 's/^/    /'
  else
    echo "  RESULT: no alias deprecation warning"
  fi
}

run_test() {
  local label=$1 container=$2 names=$3 expected=$4
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " $label"
  echo " names: $names"
  echo " expected: $expected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  start_es "$container"
  setup_index_and_alias
  q PUT "/_security/role/test_role" \
    "{\"indices\":[{\"names\":$names,\"privileges\":[\"read\",\"view_index_metadata\"]}]}" > /dev/null
  create_user_with_role "test_role"
  trigger
  check_log "$container"
  stop_es "$container"
}

case "$RUN" in
  a|all)
    run_test \
      "TEST A — alias only (broken)" \
      "es-test-a" \
      '[ ".lists-helpdesk" ]' \
      "warning fires"
    ;;& # fall through when RUN=all
  b|all)
    run_test \
      "TEST B — alias + index pattern (KB article fix)" \
      "es-test-b" \
      '[ ".lists-helpdesk", ".lists-helpdesk-*" ]' \
      "no warning"
    ;;&
  c|all)
    run_test \
      "TEST C — index pattern only, no alias in role" \
      "es-test-c" \
      '[ ".lists-helpdesk-*" ]' \
      "no warning"
    ;;
esac

echo ""
echo "Done."
