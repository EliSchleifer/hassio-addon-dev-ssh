# Eli's Home Assistant Add-ons

A small add-on repository for Home Assistant OS / Supervised.

## Add-ons

### [Dev SSH (Debian)](./dev_ssh_debian)

A **glibc**-based SSH server intended as a Remote-SSH target for
**Cursor** and **VS Code**, with your Home Assistant config directory
bind-mounted in locally at `/homeassistant`.

Why this exists: Cursor / VS Code Remote-SSH ships a glibc-linked Node
server. The popular Alpine-based SSH add-ons (musl libc) can fail to launch
that server, producing the classic disconnect loop:

```
connect_to 127.0.0.1 port 35879: failed.   (×6-7, then) Connection closed
```

Running the SSH target on Debian (glibc) removes that failure mode, and
because `/config` is a real bind mount (not a Samba/CIFS share) editing is
fast and file-watching (inotify) works.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮** menu (top right) → **Repositories**.
3. Add this URL:

   ```
   https://github.com/elischleifer/hassio-addon-dev-ssh
   ```

4. The **Dev SSH (Debian)** add-on now appears in the store. Install it, then
   follow its documentation.

> Replace `elischleifer` throughout this repo with your own GitHub username
> before publishing.

## License

MIT — see [LICENSE](./LICENSE).
