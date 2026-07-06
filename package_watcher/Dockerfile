# Home Assistant add-on wrapper around the package-watcher service.
#
# HA builds a repository add-on with THIS directory as the build context, so
# the image can't COPY repo-root files (pyproject.toml, package_watcher/, ...).
# Instead we install the package straight from Git.
#
# IMPORTANT: pin to an exact commit (PW_REF), not @main. Supervisor rebuilds
# with Docker's layer cache on, and the `RUN pip install` layer is keyed by the
# command string — with @main that string never changes, so a rebuild reuses
# the stale cached layer instead of re-pulling. Bumping PW_REF each release
# changes the RUN command, forcing a fresh install, and pins the build
# reproducibly. Keep PW_REF in sync with the add-on version bump.
#
# Uses a Debian python base (not the Alpine HA base) because opencv wheels
# need glibc; `init: false` in config.yaml means no s6 overlay is required.
FROM python:3.12-slim

ARG PW_REF=60f9961df9463f6ccf0567b1862b287d580ce4bc

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg libglib2.0-0 jq git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    "package-watcher[unifi,ui] @ git+https://github.com/EliSchleifer/hassio-package-watcher@${PW_REF}"

COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
