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

ARG PW_REF=a3e5d12b92c00899d99acc036e0199ec3bfc01ab

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg libglib2.0-0 jq git \
    && rm -rf /var/lib/apt/lists/*

# Torch AND torchvision from the CPU wheel index (the default PyPI wheels
# target CUDA torch — mixing them breaks with "torchvision::nms does not
# exist"), then the app with the Florence-2 verification extra.
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu \
    && pip install --no-cache-dir \
    "package-watcher[unifi,ui,verify] @ git+https://github.com/EliSchleifer/hassio-package-watcher@${PW_REF}"

# Model weights download on first use; keep them in /data so they survive
# restarts and add-on updates (cleared only on uninstall).
ENV HF_HOME=/data/hf-cache

COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
