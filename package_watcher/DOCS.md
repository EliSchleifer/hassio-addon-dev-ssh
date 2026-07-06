# Package Watcher

CPU-only package / new-object detection for fixed Unifi Protect cameras, with
a built-in fixture-authoring Web UI (opens in the Home Assistant sidebar via
ingress).

Full project docs, detection details, and configuration reference:
https://github.com/EliSchleifer/hassio-package-watcher

## First run

1. Start the add-on once. It writes a starter config to the add-on
   configuration folder (`/config/config.yaml` by default) and comes up with
   the Web UI available immediately (**Open Web UI** / sidebar).
2. Edit `config.yaml` — replace the placeholder camera with your camera's
   `rtsps://…:7441/…` stream URL (Protect → camera → Settings → Advanced →
   RTSP).
3. Restart. Once a real camera is configured, the detection service starts
   automatically alongside the UI.

## Options

| Option | Default | Meaning |
|---|---|---|
| `config_path` | `/config/config.yaml` | watcher config (cameras, sinks, detector) |
| `fixtures_path` | `/config/fixtures` | where authored fixture cases are stored |

The image installs the code from
[`hassio-package-watcher`](https://github.com/EliSchleifer/hassio-package-watcher)
at build time, so rebuilding the add-on picks up the latest release.
