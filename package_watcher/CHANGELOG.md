# Changelog

## 0.4.3

- Backtest engine reworked to a true fast/slow reference: the baseline
  tracks lighting every sample, pending candidates keep their pre-arrival
  pixels, and a candidate confirms only if it stays put AND its pixels are
  still between samples — creeping shadows can no longer become hits.
- Reference-ghost filter (regions where something left no longer read as
  arrivals).
- Verifier status is shown under the 2nd-stage selector, so whether
  Florence is actually configured/loaded is visible at a glance.

## 0.4.2

- Backtest cards show the before/after comparison pair (the baseline
  snapshot each sample was diffed against), so noise candidates explain
  themselves.
- Per-camera watch zones: draw a rectangle over a live snapshot — or import
  a smart/motion zone already configured on the camera in Protect — and
  everything outside it is ignored by backtests AND the live watcher.
  Stored in zones.yaml next to config.yaml.

## 0.4.1

- Backtest results group all candidate boxes from one sample into a single
  card (numbered boxes on one frame with per-box verdicts) instead of
  repeating the same timestamp per box.
- Backtest display failures now surface in the status line instead of
  leaving a blank results area.
- Password managers no longer try to autofill the date/time pickers.

## 0.4.0

- **Person-gated detection** (`detector.mode: person_gated`): compares the
  clean scene after a person's visit against the clean scene before it —
  people can't false-positive by definition. Person presence comes from
  Protect smart detections; fixture clips import their person windows
  automatically when pulled.
- **Second-stage vision verification**: Florence-2 runs locally on CPU and
  captions each candidate crop — verdicts on every event (`verification:`),
  in the wizard, and in backtests. Enable with `verifier: {backend: florence}`
  in the watcher config; model (~0.5 GB) downloads on first use into /data.
- **Backtest a day**: pick a camera, date, and interval (5–30 min) in the UI —
  one snapshot per interval is compared with the previous person-free one and
  candidate packages stream in with where-in-frame + the model's caption.
  Also as a CLI: `package-watcher backtest`.
- Wizard rework: modal flow (Source → Expectation → Verify & save), live
  scrubber with ±1/5/30 s stepping, draw-the-expected-region on the clip,
  watch clips inline, reopen/edit saved cases, mm:ss times everywhere.
- Fixtures are real clips only (synthetic scenes removed); clips stay local.
- Detector shape priors reject tall/upright person-shaped blobs.

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
