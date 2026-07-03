# Dev SSH (Debian)

A glibc-based SSH server for use as a **Cursor** / **VS Code** Remote-SSH
target, with your Home Assistant config directory bind-mounted in at
`/homeassistant`.

## Why

Cursor and VS Code Remote-SSH install a Node-based "remote server" on the
machine you connect to. That server is linked against **glibc**. The common
Home Assistant SSH add-ons are built on **Alpine Linux (musl libc)**, so the
server binary can fail to launch — the tell is a repeating log line on the
SSH side:

```
connect_to 127.0.0.1 port 35879: failed.
connect_to 127.0.0.1 port 35879: failed.
...
Connection closed by <ip>
```

That means the editor opened a forwarded channel to the server's port, but the
server process died on launch so nothing was listening. This add-on runs the
SSH target on **Debian (glibc)**, so the remote server runs normally.

Because `/config` is a real **bind mount** (not a Samba/CIFS share), editing is
at local-disk speed and file-watching (inotify) works.

## Installation

1. Add this repository to Home Assistant (**Settings → Add-ons → Store → ⋮ →
   Repositories**), then install **Dev SSH (Debian)** from the store.
2. Open the **Configuration** tab and add your SSH public key(s):

   ```yaml
   authorized_keys:
     - ssh-ed25519 AAAA... you@host
   ```

3. **Start** the add-on and check the **Log** tab for
   `sshd starting on port 22222`.

## Connecting from Cursor / VS Code

Add an SSH host (Remote-SSH: *Connect to Host…*):

```
ssh root@<home-assistant-ip> -p 22222
```

Then **Open Folder → `/homeassistant`**.

The add-on listens on **port 22222** so it does not conflict with the standard
SSH add-on (port 22) if you keep both installed.

## Mounted paths

| Path             | Contents                          | Access |
|------------------|-----------------------------------|--------|
| `/homeassistant` | Home Assistant configuration      | rw     |
| `/addons`        | Local add-ons                     | rw     |
| `/share`         | Shared storage                    | rw     |
| `/addon_configs` | Per-add-on config directories     | rw     |

## Options

### `authorized_keys` (required)

A list of SSH public keys allowed to log in as `root`. Password login is
disabled; key auth only.

```yaml
authorized_keys:
  - ssh-ed25519 AAAA... laptop
  - ssh-ed25519 AAAA... desktop
```

## Notes & caveats

- Root login is **key-only**; password authentication is disabled.
- Host keys are stored in the add-on's persistent `/data`, so you won't get
  "host key changed" warnings after a restart or update.
- This add-on grants root SSH access to your Home Assistant config and add-ons.
  Only expose port 22222 on your LAN; do **not** port-forward it to the
  internet. Use a VPN (e.g. WireGuard) for remote access.
- Want more tooling on the box (node, python, build tools)? Add packages to the
  `apt-get install` line in the `Dockerfile` and rebuild the add-on.

## Support

Issues and PRs welcome at the repository. Include your Home Assistant OS
version, Supervisor version, and the add-on log when reporting a problem.
