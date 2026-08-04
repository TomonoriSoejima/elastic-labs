FROM elastic/elastic-agent:9.3.0

USER root

# Install Oracle dependencies (RHEL-based image uses microdnf)
RUN microdnf install -y libaio wget unzip && \
    microdnf clean all

# Download and install Oracle Instant Client
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    wget https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basiclite-linux.x64-23.4.0.24.05.zip && \
    unzip instantclient-basiclite-linux.x64-23.4.0.24.05.zip && \
    rm instantclient-basiclite-linux.x64-23.4.0.24.05.zip && \
    echo "/opt/oracle/instantclient_23_4" > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

# Set environment variables
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_23_4:$LD_LIBRARY_PATH

USER elastic-agent
