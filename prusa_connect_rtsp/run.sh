#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json
FINGERPRINT_DIR=/data/fingerprints
STOP_FILE=/tmp/.prusa_stop
declare -a PIDS=()

mkdir -p "$FINGERPRINT_DIR"
rm -f "$STOP_FILE"

# Forward shutdown to camera processes so they can finalize timelapses
shutdown() {
    bashio::log.info "Stop signal received; shutting down cameras..."
    touch "$STOP_FILE"
    # SIGTERM all python main.py processes; their handlers do timelapse cleanup
    pkill -TERM -f "python3 -u /main.py" 2>/dev/null || true
}
trap shutdown SIGTERM SIGINT

# Test Python and dependencies
bashio::log.info "Testing Python environment..."
if ! python3 -c "import cv2; import requests; print('Dependencies OK')" 2>&1; then
    bashio::log.error "Python dependencies failed to load!"
    bashio::log.error "Try rebuilding the addon."
    exit 1
fi
bashio::log.info "Python environment ready"

# Detect MQTT broker from Home Assistant services
if bashio::services.available "mqtt"; then
    MQTT_HOST=$(bashio::services mqtt "host")
    MQTT_PORT=$(bashio::services mqtt "port")
    MQTT_USER=$(bashio::services mqtt "username")
    MQTT_PASS=$(bashio::services mqtt "password")
    bashio::log.info "MQTT broker found at ${MQTT_HOST}:${MQTT_PORT}"
    export MQTT_HOST MQTT_PORT MQTT_USER MQTT_PASS
else
    bashio::log.warning "MQTT broker not available - camera entities will not be created in Home Assistant"
    bashio::log.warning "Install Mosquitto broker addon for HA camera entity support"
fi

# Get number of cameras
CAMERAS_COUNT=$(jq '.cameras | length' $CONFIG_PATH)
bashio::log.info "Found ${CAMERAS_COUNT} camera(s) configured"

# Iterate over each camera
for (( i=0; i<CAMERAS_COUNT; i++ )); do
    CAMERA_NAME=$(jq -r ".cameras[$i].name" $CONFIG_PATH)
    CAMERA_SLUG="${CAMERA_NAME// /_}"

    # Get fingerprint from config, or auto-load/auto-generate if empty.
    # Storage is keyed by the Prusa Connect token (stable across camera renames),
    # with a one-time migration from the old camera-name-keyed file.
    TOKEN=$(jq -r ".cameras[$i].token" $CONFIG_PATH)
    FINGERPRINT=$(jq -r ".cameras[$i].fingerprint // empty" $CONFIG_PATH)
    if [ -z "$FINGERPRINT" ]; then
        TOKEN_HASH=$(printf '%s' "$TOKEN" | sha1sum | awk '{print $1}')
        TOKEN_FP_FILE="$FINGERPRINT_DIR/token_${TOKEN_HASH}.txt"
        LEGACY_FP_FILE="$FINGERPRINT_DIR/${CAMERA_SLUG}.txt"
        if [ -f "$TOKEN_FP_FILE" ]; then
            FINGERPRINT=$(cat "$TOKEN_FP_FILE")
            bashio::log.info "Using stored fingerprint for ${CAMERA_NAME}"
        elif [ -f "$LEGACY_FP_FILE" ]; then
            FINGERPRINT=$(cat "$LEGACY_FP_FILE")
            cp "$LEGACY_FP_FILE" "$TOKEN_FP_FILE"
            bashio::log.info "Migrated fingerprint for ${CAMERA_NAME} to token-keyed storage"
        else
            # Generate 40-char hex fingerprint (like SHA1 format)
            FINGERPRINT=$(cat /proc/sys/kernel/random/uuid | tr -d '-')$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 8)
            echo "$FINGERPRINT" > "$TOKEN_FP_FILE"
            bashio::log.info "Generated new fingerprint for ${CAMERA_NAME}: ${FINGERPRINT}"
        fi
    fi

    RTSP_URL=$(jq -r ".cameras[$i].rtsp_url" $CONFIG_PATH)
    UPLOAD_INTERVAL=$(jq -r ".cameras[$i].upload_interval" $CONFIG_PATH)
    ENABLE_TIMELAPSE=$(jq -r ".cameras[$i].timelapse_enabled" $CONFIG_PATH)
    TIMELAPSE_SAVE_INTERVAL=$(jq -r ".cameras[$i].timelapse_save_interval // 30" $CONFIG_PATH)
    TIMELAPSE_FPS=$(jq -r ".cameras[$i].timelapse_fps // 24" $CONFIG_PATH)
    TIMELAPSE_DIR="/share/prusa_connect_rtsp/${CAMERA_SLUG}"

    mkdir -p "$TIMELAPSE_DIR"

    bashio::log.info "-------------------------------------------"
    bashio::log.info "Camera ${i}: ${CAMERA_NAME}"
    bashio::log.info "  RTSP URL: ${RTSP_URL}"
    bashio::log.info "  Fingerprint: ${FINGERPRINT}"
    bashio::log.info "  Token: ${TOKEN:0:8}... (hidden)"
    bashio::log.info "  Upload interval: ${UPLOAD_INTERVAL}s"
    bashio::log.info "  Timelapse: ${ENABLE_TIMELAPSE}"
    bashio::log.info "-------------------------------------------"

    bashio::log.info "Starting camera: ${CAMERA_NAME}"

    # Each camera runs in its own subshell with a per-camera env snapshot and
    # an auto-restart loop, so one camera crash does not kill the others.
    (
        export CAMERA_NAME CAMERA_SLUG RTSP_URL TOKEN FINGERPRINT \
               UPLOAD_INTERVAL ENABLE_TIMELAPSE \
               TIMELAPSE_SAVE_INTERVAL TIMELAPSE_FPS TIMELAPSE_DIR
        while [ ! -f "$STOP_FILE" ]; do
            python3 -u /main.py 2>&1 | while IFS= read -r line; do
                echo "[${CAMERA_NAME}] ${line}"
            done
            [ -f "$STOP_FILE" ] && break
            bashio::log.warning "[${CAMERA_NAME}] camera process exited; restarting in 10s"
            sleep 10
        done
    ) &
    PIDS+=($!)
done

# Wait for all camera wrappers; the trap interrupts wait on SIGTERM
wait "${PIDS[@]}" 2>/dev/null || true
bashio::log.info "All cameras stopped."
