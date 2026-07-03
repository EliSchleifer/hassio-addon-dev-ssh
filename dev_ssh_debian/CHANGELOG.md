# Changelog

## 2.0.0

- Added configuration options inspired by the Advanced SSH & Web Terminal
  add-on:
  - `ssh.username` — log in as a custom user (auto-created with passwordless
    `sudo`); defaults to `root`.
  - `ssh.password` — optional password authentication (key-only by default).
  - `ssh.sftp` — toggle the SFTP subsystem.
  - `ssh.compatibility_mode` — re-enable legacy algorithms for old clients.
  - `ssh.allow_agent_forwarding`, `ssh.allow_tcp_forwarding`,
    `ssh.allow_remote_port_forwarding` — SSH forwarding controls.
  - `packages` — extra apt packages installed on start.
  - `init_commands` — shell commands run on each start before sshd launches.
- Added `sudo` to the image so custom users are usable.
- **Breaking:** `authorized_keys` moved under the new `ssh` object
  (`ssh.authorized_keys`). Update your configuration when upgrading from 1.x.

## 1.0.0

- Initial release.
- Debian (glibc) base so Cursor / VS Code Remote-SSH servers launch reliably.
- SSH server on port 22222, key-only root login.
- Bind-mounts Home Assistant config (`/homeassistant`), `/addons`, `/share`,
  and `/addon_configs`.
- Persistent SSH host keys stored in `/data`.
- Multi-arch: amd64, aarch64, armv7, i386.
