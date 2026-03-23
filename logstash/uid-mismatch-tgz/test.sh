#!/bin/bash
# Reproduces: Logstash fails to start after tar.gz upgrade when the logstash
# user UID on the target system differs from the UID baked into the archive.
#
# Elastic tar.gz archives preserve the UID from the build environment (992).
# If the target system already has UID 992 taken by another account, the
# logstash user is created with the next available UID (e.g. 1002).
# Files extracted from the archive are then owned by numeric UID 992, which
# is NOT the logstash user on that system -- causing Permission denied.
#
# Usage (Docker required):
#   bash test.sh

set -e
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

docker run --rm -v "$SCRIPT_DIR/container_test.sh:/tmp/container_test.sh" ubuntu:22.04 bash /tmp/container_test.sh
