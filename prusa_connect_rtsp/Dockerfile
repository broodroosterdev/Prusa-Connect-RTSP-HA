ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install system dependencies and Python packages from Alpine repos
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-opencv \
    py3-numpy \
    py3-requests \
    ffmpeg \
    jq \
    bash \
    libstdc++ \
    libgomp

# Fix broken opencv version string that causes pip to crash, then install paho-mqtt
RUN find /usr/lib/python3* -path "*/opencv*METADATA" -exec \
    sed -i 's/^Version: python-4\.12\.0/Version: 4.12.0/' {} \; && \
    pip3 install --no-cache-dir --break-system-packages paho-mqtt

# Copy application files
COPY main.py /
COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]