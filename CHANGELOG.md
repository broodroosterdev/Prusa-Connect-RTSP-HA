# Changelog

## [1.5.0] - 2026-05-14

### Fixed

- Changed camera url to `https://connect.prusa3d.com/c/snapshot`

## [1.4.0] - 2026-05-12

### Fixed

- MQTT discovery: pass `CallbackAPIVersion.VERSION1` to `paho_mqtt.Client()` so initialization no longer fails silently on paho-mqtt 2.x
- Timelapse `.mp4` is now written to `/share/prusa_connect_rtsp/<camera>/` instead of the container's working directory
- Timelapse video is now produced on `SIGTERM` (HA Supervisor stop), not only on `SIGINT`/keyboard interrupt
- One camera crash no longer kills the whole add-on; each camera runs in its own auto-restart wrapper
- Briefly unreachable RTSP camera at startup is retried with backoff instead of exiting the add-on
- Fingerprint storage is now keyed by `sha1(token)` instead of the camera name, so renaming a camera no longer invalidates its Prusa Connect registration; a one-shot migration copies any legacy name-keyed file forward

### Added

- Camera name is now registered with Prusa Connect via `PUT /c/info` on each startup, replacing the ineffective `camera-name` snapshot header
- `image: ghcr.io/dariber/prusa-connect-rtsp-ha-{arch}` field in `config.yaml` (commented; enable after first GHCR publish)

### Changed

- `docker-build.yml` image name corrected to `dariber/prusa-connect-rtsp-ha`; version tag now derived from `config.yaml`
- `sync-upstream.yml` writes upstream snapshot to `.upstream/main.py` for manual diffing rather than clobbering the diverged fork
- Removed unused `requirements.txt` (Dockerfile installs deps via apk and a direct `pip` call)
- Dockerfile only removes `opencv*.dist-info` metadata rather than the broader `opencv*` glob

## [1.3.1] - 2026-02-26

### Added

- MQTT camera discovery: cameras now appear as Home Assistant camera entities
- Auto-detect MQTT broker from Home Assistant services
- DOCS.md in addon directory for proper documentation link in HA UI

### Fixed

- Timelapse frames no longer wiped on addon restart; cleanup only after successful video creation
- "Weitere Informationen" link now points to addon documentation instead of GitHub

### Changed

- Removed `homeassistant_api` for improved security rating

## [1.2.0] - 2025-12-08

### Added

- Detailed logging showing camera configuration on startup
- Python output prefixed with camera name for multi-camera setups
- Visual separators in logs for easier reading

## [1.1.0] - 2025-12-08

### Added

- Auto-generate camera fingerprints (no manual setup required)
- Fingerprints persist in `/data/fingerprints/` across restarts

### Changed

- Fingerprint field is now optional in configuration
- Simplified documentation and setup process

## [1.0.0] - 2025-12-08

### Added

- Initial release
- Multi-camera support with array-based configuration
- Password-protected token fields in Home Assistant UI
- Timelapse frame capture and video generation
- GitHub Actions workflow for automated upstream sync
- Full documentation and translations
