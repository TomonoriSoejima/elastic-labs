#!/bin/bash
# Install Oracle Instant Client if not already installed

if [ ! -f /opt/oracle/instantclient_23_4/libclntsh.so ]; then
    echo "Installing Oracle Instant Client..."
    apt-get update -qq
    apt-get install -y wget unzip libaio1
    mkdir -p /opt/oracle
    cd /opt/oracle
    wget -q https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basiclite-linux.x64-23.4.0.24.05.zip
    unzip -q instantclient-basiclite-linux.x64-23.4.0.24.05.zip
    rm instantclient-basiclite-linux.x64-23.4.0.24.05.zip
    echo '/opt/oracle/instantclient_23_4' > /etc/ld.so.conf.d/oracle.conf
    ldconfig
    echo "Oracle Instant Client installed successfully"
else
    echo "Oracle Instant Client already installed"
fi

# Start Elastic Agent with enrollment
exec /usr/bin/tini -- /usr/local/bin/docker-entrypoint -e
