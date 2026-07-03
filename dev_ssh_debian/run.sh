#!/usr/bin/env bash
set -e

OPTIONS=/data/options.json
HOSTKEY_DIR=/data/ssh
SSHD_CONFIG=/etc/ssh/sshd_config

# --- helper to read a single option with a sane fallback ---
opt() {
    # opt <jq-filter> <default>
    local value
    value=$(jq -r "$1 // empty" "${OPTIONS}" 2>/dev/null || true)
    if [ -z "${value}" ]; then
        echo "$2"
    else
        echo "${value}"
    fi
}

if [ ! -f "${OPTIONS}" ]; then
    echo "[dev-ssh] WARNING: ${OPTIONS} not found; using built-in defaults."
    echo "{}" > "${OPTIONS}"
fi

USERNAME=$(opt '.ssh.username' 'root')
PASSWORD=$(opt '.ssh.password' '')
SFTP=$(opt '.ssh.sftp' 'false')
COMPAT=$(opt '.ssh.compatibility_mode' 'false')
AGENT_FWD=$(opt '.ssh.allow_agent_forwarding' 'false')
REMOTE_FWD=$(opt '.ssh.allow_remote_port_forwarding' 'false')
TCP_FWD=$(opt '.ssh.allow_tcp_forwarding' 'false')

# --- install any extra apt packages requested in the options ---
PACKAGES=$(jq -r '.packages[]? // empty' "${OPTIONS}" 2>/dev/null | tr '\n' ' ')
if [ -n "${PACKAGES// /}" ]; then
    echo "[dev-ssh] installing extra packages: ${PACKAGES}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    # shellcheck disable=SC2086
    apt-get install -y --no-install-recommends ${PACKAGES}
    rm -rf /var/lib/apt/lists/*
fi

# --- resolve the login user, creating it if it isn't root ---
if [ "${USERNAME}" != "root" ]; then
    if ! id "${USERNAME}" >/dev/null 2>&1; then
        echo "[dev-ssh] creating login user '${USERNAME}'"
        useradd --create-home --shell /bin/bash "${USERNAME}"
        # passwordless sudo so the account is useful on a dev box
        mkdir -p /etc/sudoers.d
        echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"
        chmod 440 "/etc/sudoers.d/${USERNAME}"
    fi
    HOME_DIR=$(getent passwd "${USERNAME}" | cut -d: -f6)
else
    HOME_DIR=/root
fi
SSH_DIR="${HOME_DIR}/.ssh"

# --- authorized keys pulled from the add-on options ---
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
: > "${SSH_DIR}/authorized_keys"
jq -r '.ssh.authorized_keys[]? // empty' "${OPTIONS}" >> "${SSH_DIR}/authorized_keys"
chmod 600 "${SSH_DIR}/authorized_keys"
chown -R "${USERNAME}:${USERNAME}" "${SSH_DIR}" 2>/dev/null || true

# --- optional password authentication ---
if [ -n "${PASSWORD}" ]; then
    echo "${USERNAME}:${PASSWORD}" | chpasswd
    echo "[dev-ssh] password authentication enabled for '${USERNAME}'"
elif [ "${USERNAME}" != "root" ]; then
    # no password provided: lock it so only key auth works
    passwd -l "${USERNAME}" >/dev/null 2>&1 || true
fi

if [ ! -s "${SSH_DIR}/authorized_keys" ] && [ -z "${PASSWORD}" ]; then
    echo "[dev-ssh] WARNING: no authorized_keys and no password set in add-on"
    echo "[dev-ssh]          options; you won't be able to log in until you"
    echo "[dev-ssh]          add one under Configuration → ssh."
fi

# --- persistent host keys so Cursor doesn't warn on every restart ---
mkdir -p "${HOSTKEY_DIR}"
if ls "${HOSTKEY_DIR}"/ssh_host_* >/dev/null 2>&1; then
    cp "${HOSTKEY_DIR}"/ssh_host_* /etc/ssh/
else
    ssh-keygen -A
    cp /etc/ssh/ssh_host_* "${HOSTKEY_DIR}/"
fi

# --- build sshd_config from the options ---
# set (or add) a keyword in sshd_config
set_sshd() {
    local key="$1" val="$2"
    if grep -qiE "^#?[[:space:]]*${key}\b" "${SSHD_CONFIG}"; then
        sed -i "s|^#\?[[:space:]]*${key}\b.*|${key} ${val}|I" "${SSHD_CONFIG}"
    else
        echo "${key} ${val}" >> "${SSHD_CONFIG}"
    fi
}

bool() { [ "$1" = "true" ] && echo "yes" || echo "no"; }

# root login: allow password if a password was provided, otherwise key-only
if [ "${USERNAME}" = "root" ]; then
    if [ -n "${PASSWORD}" ]; then
        set_sshd PermitRootLogin yes
    else
        set_sshd PermitRootLogin prohibit-password
    fi
fi

if [ -n "${PASSWORD}" ]; then
    set_sshd PasswordAuthentication yes
else
    set_sshd PasswordAuthentication no
fi
set_sshd PubkeyAuthentication yes

# forwarding
set_sshd AllowAgentForwarding "$(bool "${AGENT_FWD}")"
set_sshd AllowTcpForwarding "$(bool "${TCP_FWD}")"
set_sshd GatewayPorts "$(bool "${REMOTE_FWD}")"

# sftp subsystem
if [ "${SFTP}" = "true" ]; then
    set_sshd Subsystem "sftp /usr/lib/openssh/sftp-server"
else
    sed -i 's|^\([[:space:]]*Subsystem[[:space:]]\+sftp.*\)|#\1|I' "${SSHD_CONFIG}"
fi

# compatibility mode: re-enable legacy algorithms for old clients
if [ "${COMPAT}" = "true" ]; then
    echo "[dev-ssh] compatibility mode: enabling legacy algorithms"
    {
        echo "KexAlgorithms +diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1"
        echo "Ciphers +aes128-cbc,aes192-cbc,aes256-cbc,3des-cbc"
        echo "MACs +hmac-sha1,hmac-sha1-96"
        echo "HostKeyAlgorithms +ssh-rsa,ssh-dss"
        echo "PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss"
    } >> "${SSHD_CONFIG}"
fi

# --- run any user-supplied init commands before starting sshd ---
if jq -e '(.init_commands // []) | length > 0' "${OPTIONS}" >/dev/null 2>&1; then
    echo "[dev-ssh] running init_commands"
    while IFS= read -r cmd; do
        [ -z "${cmd}" ] && continue
        echo "[dev-ssh] \$ ${cmd}"
        bash -c "${cmd}" || echo "[dev-ssh] WARNING: init command failed: ${cmd}"
    done < <(jq -r '.init_commands[]? // empty' "${OPTIONS}")
fi

echo "[dev-ssh] sshd starting on port 22222 (login user: ${USERNAME})"
echo "[dev-ssh] Home Assistant config is mounted at /homeassistant"
exec /usr/sbin/sshd -D -e -p 22222
