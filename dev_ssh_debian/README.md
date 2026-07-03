# Dev SSH (Debian)

glibc SSH target for Cursor / VS Code Remote-SSH, with the Home Assistant
config directory bind-mounted locally at `/homeassistant`.

See [DOCS.md](./DOCS.md) for full documentation and rationale.

## Quick start

1. Install from the repository store.
2. Add your SSH public key under **Configuration → `authorized_keys`**.
3. Start the add-on.
4. Connect: `ssh root@<ha-ip> -p 22222`, then open `/homeassistant`.
