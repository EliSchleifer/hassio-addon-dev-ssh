# Changelog

## 0.3.0

- Scrub-and-mark clip authoring: pick a camera, start time, and window, then
  scrub a thumbnail timeline (cheap downscaled snapshots — no video download),
  click frames to mark In/Out, zoom to refine, and pull only the selected
  short range as the fixture clip.

## 0.2.1

- Fix: the image now pins the app code to an exact commit instead of `@main`,
  so a rebuild actually pulls the intended code. Previously Docker reused the
  cached `pip install @main` layer on rebuild, shipping stale code (the camera
  discovery / Protect auto-discovery from 0.2.0 never took effect).

## 0.2.0

- Discover the cameras you already have in Home Assistant: the fixture UI's
  camera list is populated from your `camera.*` entities via the HA Core API
  (no `unifi` block needed just to see them).
- Auto-discover UniFi Protect credentials from the HA Protect integration, so
  recorded-clip pull works without re-entering NVR credentials. Mounts the HA
  config directory read-only to read the stored config entry.

## 0.1.0

- Initial release: CPU-only package / new-object detection for fixed Unifi
  Protect cameras, with an evidence bundle for LLM verification.
- Built-in fixture-authoring Web UI, exposed in the Home Assistant sidebar via
  ingress. The detection service starts automatically once a real camera is
  configured.
