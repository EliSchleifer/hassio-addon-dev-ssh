#!/usr/bin/env bash
set -e

OPTIONS=/data/options.json
SSH_DIR=/root/.ssh
HOSTKEY_DIR=/data/ssh

# --- authorized keys pulled from the add-on options ---
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
: > "${SSH_DIR}/authorized_keys"
if [ -f "${OPTIONS}" ]; then
    jq -r '.authorized_keys[]? // empty' "${OPTIONS}" >> "${SSH_DIR}/authorized_keys"
fi
chmod 600 "${SSH_DIR}/authorized_keys"

if [ ! -s "${SSH_DIR}/authorized_keys" ]; then
    echo "[dev-ssh] WARNING: no authorized_keys set in add-on options;"
    echo "[dev-ssh]          you won't be able to log in until you add one."
fi

# --- persistent host keys so Cursor doesn't warn on every restart ---
mkdir -p "${HOSTKEY_DIR}"
if ls "${HOSTKEY_DIR}"/ssh_host_* >/dev/null 2>&1; then
    cp "${HOSTKEY_DIR}"/ssh_host_* /etc/ssh/
else
    ssh-keygen -A
    cp /etc/ssh/ssh_host_* "${HOSTKEY_DIR}/"
fi

# --- harden: key-only root login ---
sed -i 's/#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

echo "[dev-ssh] sshd starting on port 22222"
echo "[dev-ssh] Home Assistant config is mounted at /homeassistant"
exec /usr/sbin/sshd -D -e -p 22222
