# Changelog

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
