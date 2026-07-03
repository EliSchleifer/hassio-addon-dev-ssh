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
   ssh:
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

All options are optional except that you need **either** an authorized key
**or** a password to be able to log in. A full example:

```yaml
ssh:
  username: root
  password: ""
  authorized_keys:
    - ssh-ed25519 AAAA... laptop
    - ssh-ed25519 AAAA... desktop
  sftp: false
  compatibility_mode: false
  allow_agent_forwarding: false
  allow_remote_port_forwarding: false
  allow_tcp_forwarding: false
packages:
  - python3
  - build-essential
init_commands:
  - echo "hello from init"
```

> **Upgrading from 1.x:** `authorized_keys` moved under the new `ssh` object.
> Change your old top-level `authorized_keys:` list to `ssh:` → `authorized_keys:`
> as shown above.

### `ssh.username`

The user you log in as. Defaults to `root`, which is what Cursor / VS Code
Remote-SSH expects and what has full access to the mounted paths. If you set a
different name, the add-on creates that account (with passwordless `sudo`) on
start.

### `ssh.password`

Optional password for `ssh.username`. Leave empty (the default) for key-only
login, which is strongly recommended. Setting a password enables password
authentication and, for `root`, `PermitRootLogin yes`.

### `ssh.authorized_keys`

A list of SSH public keys allowed to log in as `ssh.username`.

```yaml
ssh:
  authorized_keys:
    - ssh-ed25519 AAAA... laptop
    - ssh-ed25519 AAAA... desktop
```

### `ssh.sftp`

Enable the SFTP subsystem (`false` by default). Turn this on if you want to use
SFTP-based file transfer or tools that rely on it.

### `ssh.compatibility_mode`

Re-enable legacy key-exchange, cipher, MAC, and host-key algorithms for older
SSH clients (`false` by default). Only enable this if a client cannot connect
otherwise — it weakens security.

### `ssh.allow_agent_forwarding`

Allow SSH agent forwarding (`AllowAgentForwarding`, `false` by default).

### `ssh.allow_tcp_forwarding`

Allow TCP port forwarding — local (`-L`) and remote (`-R`) tunnels
(`AllowTcpForwarding`, `false` by default).

### `ssh.allow_remote_port_forwarding`

Allow forwarded remote ports to bind to non-localhost addresses
(`GatewayPorts`, `false` by default). Requires `allow_tcp_forwarding` to be
useful.

### `packages`

A list of extra Debian (apt) packages installed each time the add-on starts.
Handy for adding language runtimes or build tools without editing the
`Dockerfile`.

```yaml
packages:
  - python3
  - python3-pip
  - build-essential
```

### `init_commands`

Shell commands run once on each start, **before** the SSH server launches. Use
these for one-off setup such as installing global npm packages or configuring
git.

```yaml
init_commands:
  - git config --global user.email you@example.com
  - npm install -g pnpm
```

## Notes & caveats

- Login is **key-only** by default; password authentication turns on only when
  you set `ssh.password`.
- Host keys are stored in the add-on's persistent `/data`, so you won't get
  "host key changed" warnings after a restart or update.
- This add-on grants SSH access to your Home Assistant config and add-ons.
  Only expose port 22222 on your LAN; do **not** port-forward it to the
  internet. Use a VPN (e.g. WireGuard) for remote access.
- Want more tooling on the box (node, python, build tools)? Add them to the
  `packages` option (installed on start) or to the `apt-get install` line in the
  `Dockerfile` (baked into the image) and rebuild the add-on.

## Support

Issues and PRs welcome at the repository. Include your Home Assistant OS
version, Supervisor version, and the add-on log when reporting a problem.
