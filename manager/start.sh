#!/bin/sh
set -eu

SSH_DIR="/home/manager/.ssh"
SSH_KEY="/run/ssh/private/id_ed25519"
mkdir -p "$SSH_DIR"

if [ -f "$SSH_KEY" ]; then
    cp "$SSH_KEY" /tmp/manager_id_ed25519
    chmod 600 /tmp/manager_id_ed25519
    cat > "$SSH_DIR/config" <<'EOF'
Host ej1 ej2 ej3
    User runner
    Port 2222
    IdentityFile /tmp/manager_id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    RequestTTY force
    LogLevel ERROR
EOF
    chmod 600 "$SSH_DIR/config"
else
    echo "No se encontro la clave SSH en $SSH_KEY" >&2
    exit 1
fi

python3 /app/monitor.py &

exec nginx -g "daemon off;"
