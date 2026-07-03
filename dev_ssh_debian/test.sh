#!/usr/bin/env bash
#
# Integration tests for the Dev SSH (Debian) add-on.
# Requires: Docker, ssh, ssh-keygen
#
# Usage: ./test.sh
#
set -euo pipefail

IMAGE="dev-ssh-debian:test"
CONTAINER="dev-ssh-test"
TEST_DIR=$(mktemp -d)
TEST_KEY="${TEST_DIR}/key"
OPTIONS="${TEST_DIR}/options.json"
SSH_PORT=22223  # avoid clashing with anything on 22222
PASS=0
FAIL=0

# --- helpers ---

cleanup() {
    docker rm -f "${CONTAINER}" &>/dev/null || true
    rm -rf "${TEST_DIR}"
}
trap cleanup EXIT

log()  { printf "\n\033[1;34m==> %s\033[0m\n" "$*"; }
pass() { printf "  \033[32m✓ %s\033[0m\n" "$*"; PASS=$((PASS + 1)); }
fail() { printf "  \033[31m✗ %s\033[0m\n" "$*"; FAIL=$((FAIL + 1)); }

check() {
    local desc="$1"; shift
    if "$@" &>/dev/null; then
        pass "${desc}"
    else
        fail "${desc}"
    fi
}

check_output() {
    local desc="$1" expected="$2"; shift 2
    local output
    output=$("$@" 2>/dev/null) || true
    if echo "${output}" | grep -qF "${expected}"; then
        pass "${desc}"
    else
        fail "${desc} (expected '${expected}', got '${output}')"
    fi
}

write_options() {
    cat > "${OPTIONS}"
}

start_container() {
    docker rm -f "${CONTAINER}" &>/dev/null || true
    docker run -d --name "${CONTAINER}" \
        -p "${SSH_PORT}:22222" \
        -v "${TEST_DIR}:/data" \
        "${IMAGE}" >/dev/null
    # wait for sshd to be ready
    for i in $(seq 1 30); do
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
              -o BatchMode=yes -o ConnectTimeout=1 \
              -i "${TEST_KEY}" -p "${SSH_PORT}" nobody@localhost true &>/dev/null; then
            break
        fi
        # even a refused-auth error means sshd is up
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
              -o BatchMode=yes -o ConnectTimeout=1 \
              -p "${SSH_PORT}" nobody@localhost true 2>&1 | grep -q "Permission denied"; then
            break
        fi
        sleep 0.5
    done
}

run_ssh() {
    local user="$1"; shift
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o BatchMode=yes -i "${TEST_KEY}" \
        -p "${SSH_PORT}" "${user}@localhost" "$@" 2>/dev/null
}

container_logs() {
    docker logs "${CONTAINER}" 2>&1
}

# --- setup ---

log "Setting up"
ssh-keygen -t ed25519 -f "${TEST_KEY}" -N "" -q
PUBKEY=$(cat "${TEST_KEY}.pub")
echo "  test dir: ${TEST_DIR}"
echo "  ssh port: ${SSH_PORT}"

log "Building image"
docker build -t "${IMAGE}" . >/dev/null 2>&1
pass "docker build succeeded"

# ============================================================
# Test 1: Root login with SSH key
# ============================================================
log "Test: root login with SSH key"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check "can SSH as root" run_ssh root true
check_output "whoami returns root" "root" run_ssh root whoami
check_output "Debian bookworm base" "bookworm" run_ssh root cat /etc/os-release
check_output "run.sh exists" "/run.sh" run_ssh root ls /run.sh
check_output "sshd_config has PermitRootLogin prohibit-password" "PermitRootLogin prohibit-password" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "sshd_config has PasswordAuthentication no" "PasswordAuthentication no" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "log shows correct user" "login user: root" container_logs

# ============================================================
# Test 2: Non-root user creation
# ============================================================
log "Test: non-root user creation"

# clear persisted host keys so they regenerate
rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "devuser",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check "can SSH as devuser" run_ssh devuser true
check_output "whoami returns devuser" "devuser" run_ssh devuser whoami
check_output "has home directory" "/home/devuser" run_ssh devuser getent passwd devuser
check_output "passwordless sudo works" "root" run_ssh devuser sudo whoami
check_output "authorized_keys has correct perms" "600" \
    run_ssh devuser stat -c %a /home/devuser/.ssh/authorized_keys
check_output ".ssh dir has correct perms" "700" \
    run_ssh devuser stat -c %a /home/devuser/.ssh
check_output "log shows user creation" "creating login user 'devuser'" container_logs

# ============================================================
# Test 3: Password authentication enabled
# ============================================================
log "Test: password authentication config"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "secret123",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check_output "sshd_config has PasswordAuthentication yes" "PasswordAuthentication yes" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "sshd_config has PermitRootLogin yes" "PermitRootLogin yes" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "log shows password enabled" "password authentication enabled" container_logs

# ============================================================
# Test 4: Forwarding options
# ============================================================
log "Test: forwarding options"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": true,
    "allow_remote_port_forwarding": true,
    "allow_tcp_forwarding": true
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check_output "AllowAgentForwarding yes" "AllowAgentForwarding yes" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "AllowTcpForwarding yes" "AllowTcpForwarding yes" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "GatewayPorts yes" "GatewayPorts yes" \
    run_ssh root cat /etc/ssh/sshd_config

# now test all disabled
rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check_output "AllowAgentForwarding no" "AllowAgentForwarding no" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "AllowTcpForwarding no" "AllowTcpForwarding no" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "GatewayPorts no" "GatewayPorts no" \
    run_ssh root cat /etc/ssh/sshd_config

# ============================================================
# Test 5: SFTP subsystem
# ============================================================
log "Test: SFTP subsystem"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": true,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check_output "SFTP subsystem enabled" "Subsystem sftp /usr/lib/openssh/sftp-server" \
    run_ssh root cat /etc/ssh/sshd_config

# ============================================================
# Test 6: Compatibility mode
# ============================================================
log "Test: compatibility mode"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": true,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check_output "legacy KexAlgorithms present" "diffie-hellman-group1-sha1" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "legacy Ciphers present" "aes128-cbc" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "legacy MACs present" "hmac-sha1" \
    run_ssh root cat /etc/ssh/sshd_config
check_output "log shows compat mode" "compatibility mode" container_logs

# ============================================================
# Test 7: Init commands
# ============================================================
log "Test: init commands"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": ["touch /tmp/init-test-marker", "echo hello-from-init"]
}
EOF

start_container

check "init command created marker file" run_ssh root test -f /tmp/init-test-marker
check_output "init command logged" "hello-from-init" container_logs
check_output "log shows running init_commands" "running init_commands" container_logs

# ============================================================
# Test 8: Persistent host keys
# ============================================================
log "Test: persistent host keys across restarts"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

# grab the host key fingerprint
FP1=$(run_ssh root ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | awk '{print $2}')
check "host keys saved to /data/ssh" test -f "${TEST_DIR}/ssh/ssh_host_ed25519_key"

# restart — keys should persist
docker restart "${CONTAINER}" >/dev/null
sleep 2
for i in $(seq 1 20); do
    run_ssh root true &>/dev/null && break
    sleep 0.5
done

FP2=$(run_ssh root ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | awk '{print $2}')
if [ "${FP1}" = "${FP2}" ] && [ -n "${FP1}" ]; then
    pass "host key fingerprint persisted across restart"
else
    fail "host key fingerprint changed (${FP1} -> ${FP2})"
fi

# ============================================================
# Test 9: No credentials warning
# ============================================================
log "Test: warning when no credentials configured"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": [],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": [],
  "init_commands": []
}
EOF

start_container

check_output "warns about no credentials" "no authorized_keys and no password" container_logs

# ============================================================
# Test 10: Extra packages
# ============================================================
log "Test: extra packages install"

rm -rf "${TEST_DIR}/ssh"

write_options <<EOF
{
  "ssh": {
    "username": "root",
    "password": "",
    "authorized_keys": ["${PUBKEY}"],
    "sftp": false,
    "compatibility_mode": false,
    "allow_agent_forwarding": false,
    "allow_remote_port_forwarding": false,
    "allow_tcp_forwarding": false
  },
  "packages": ["tree"],
  "init_commands": []
}
EOF

start_container

check "tree binary installed" run_ssh root which tree
check_output "log shows package install" "installing extra packages" container_logs

# ============================================================
# Summary
# ============================================================
echo
log "Results: ${PASS} passed, ${FAIL} failed"
if [ "${FAIL}" -gt 0 ]; then
    exit 1
fi
