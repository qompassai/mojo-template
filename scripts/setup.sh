#Dev setup
#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/dev/my_mojo_project"
cd "$HOME/dev/my_mojo_project"

chezmoi apply --source="$HOME/.local/share/chezmoi" --destination="$HOME" --include='dot_profile.d/30-mojo.sh'

for f in mojo.toml mojoproject.toml pixi.toml; do
    if [[ ! -f "$f" ]]; then
        chezmoi cat "$f" > "$f"
        echo "📝 Created $f from template"
    fi
done

if command -v pixi &>/dev/null; then
    pixi sync
    echo "🚀 pixi environment synced."
fi

mkdir -p "$HOME/.hold/captain"
chmod 700 "$HOME/.hold"
chmod 700 "$HOME/.hold/captain"

if command -v pass &>/dev/null; then
    echo "🔐 Pass is installed. Initializing vault structure."
    pass init "$USER"
    echo "Place your private keys securely with: pass insert hold/ssh/your_key_name"
fi

# ─── SSH Modular Setup ───
mkdir -p "$HOME/.ssh/config.d"

# Create master config
cat <<EOF > "$HOME/.ssh/config"
Include ~/.ssh/config.d/*.conf
EOF

# Create config.d snippets
cat <<EOF > "$HOME/.ssh/config.d/00-global.conf"
Host *
    AddKeysToAgent yes
    AddressFamily any
    BatchMode no
    Compression yes
    ConnectTimeout 5
    ControlMaster auto
    ControlPath ~/.ssh/control:%h:%p:%r
    ControlPersist 10m
    ForwardAgent no
    ForwardX11 no
    HashKnownHosts yes
    IdentityAgent /run/user/1000/ssh-agent.socket
    IPQoS lowdelay throughput
    PermitLocalCommand yes
    SetEnv TERM=xterm-256color
    SetEnv LC_TERMINAL=xterm-256color
    StrictHostKeyChecking accept-new
    TCPKeepAlive yes
    UpdateHostKeys yes
    VerifyHostKeyDNS yes
    UserKnownHostsFile ~/.ssh/known_hosts
EOF

cat <<EOF > "$HOME/.ssh/config.d/10-cluster.conf"
Host caffe* doppio harbor* pensare* primo
    User phaedrus

Host harbor
    HostName harbor
    Port 2342
    IdentityFile ~/.hold/captain/pr2ha

Host pensare
    HostName pensare
    Port 2342
    IdentityFile ~/.hold/captain/pensare
EOF

cat <<EOF > "$HOME/.ssh/config.d/20-github.conf"
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.hold/captain/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    KexAlgorithms curve25519-sha256@libssh.org,curve25519-sha256
EOF

cat <<EOF > "$HOME/.ssh/config.d/30-gitlab.conf"
Host gitlab.com
    HostName gitlab.com
    User git
    Port 22
    IdentityFile ~/.hold/captain/id_ed25519
    IdentitiesOnly yes
    KexAlgorithms curve25519-sha256@libssh.org,curve25519-sha256
    StrictHostKeyChecking accept-new
    ControlMaster no
EOF

cat <<EOF > "$HOME/.ssh/config.d/40-localcommand.conf"
Host *
    LocalCommand \$HOME/.local/bin/.pw-ssh.sh %h
EOF

chmod 600 "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config.d/"*.conf

if pgrep -u "$USER" ssh-agent >/dev/null; then
    echo "🔄 SSH agent detected, configs ready."
fi
