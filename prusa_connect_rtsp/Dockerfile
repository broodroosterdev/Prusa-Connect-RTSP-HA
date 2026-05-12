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

# The apk py3-opencv package ships dist-info metadata that confuses pip;
# remove only the metadata (the cv2 module itself is untouched), then add paho-mqtt.
RUN rm -rf /usr/lib/python3*/site-packages/opencv*.dist-info && \
    pip3 install --no-cache-dir --break-system-packages \
    --no-deps paho-mqtt

# Copy application files
COPY main.py /
COPY run.sh /
RUN chmod a+x /run.sh

CMD ["/run.sh"]
