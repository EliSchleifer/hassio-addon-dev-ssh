# Changelog

## 1.0.0

- Initial release.
- Debian (glibc) base so Cursor / VS Code Remote-SSH servers launch reliably.
- SSH server on port 22222, key-only root login.
- Bind-mounts Home Assistant config (`/homeassistant`), `/addons`, `/share`,
  and `/addon_configs`.
- Persistent SSH host keys stored in `/data`.
- Multi-arch: amd64, aarch64, armv7, i386.
