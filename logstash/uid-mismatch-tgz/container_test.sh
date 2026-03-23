#!/bin/bash
# Runs inside the Docker container.
# Sets up a fake logstash binary owned by uid=992 (as extracted from the
# Elastic tar.gz), then tests execution as uid=1002 (Case A / production)
# and uid=992 (Case B / fresh RPM env).

mkdir -p /usr/share/logstash/bin
printf '#!/bin/bash\necho "Logstash started successfully"\n' > /usr/share/logstash/bin/logstash
chmod 750 /usr/share/logstash/bin/logstash
chown 992:992 /usr/share/logstash/bin/logstash

echo "File on disk (same in both cases):"
ls -lan /usr/share/logstash/bin/logstash
echo ""

echo "======================================================"
echo " CASE A: Production  ->  logstash = uid=1002 (VUP env)"
echo "======================================================"
useradd -u 1002 -M -s /bin/bash logstash
id logstash
runuser -u logstash -- /usr/share/logstash/bin/logstash \
  && echo "Result: OK" \
  || echo "Result: FAILED (Permission denied)"

echo ""
echo "======================================================"
echo " CASE B: Repro env   ->  logstash = uid=992 (RPM default)"
echo "======================================================"
userdel logstash 2>/dev/null
useradd -u 992 -M -s /bin/bash logstash
id logstash
runuser -u logstash -- /usr/share/logstash/bin/logstash \
  && echo "Result: OK" \
  || echo "Result: FAILED"
