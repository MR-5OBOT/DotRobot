#!/usr/bin/env bash
set -e

# 1️⃣ Install Git and OpenSSH
sudo pacman -S --needed git openssh --noconfirm

# 2️⃣ Ask for Git info
read -rp "Git user.name: " GIT_NAME
read -rp "Git user.email: " GIT_EMAIL
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# 3️⃣ Generate SSH key if it doesn't exist
KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY" -N ""
fi

# 4️⃣ Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add "$KEY"

# 5️⃣ Create simple SSH config
mkdir -p ~/.ssh
cat > ~/.ssh/config <<'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config

# 6️⃣ Show public key to add to GitHub
echo
echo "Copy this public key to GitHub:"
cat "$KEY.pub"
echo

# 7️⃣ Test connection
echo "Testing GitHub SSH connection..."
ssh -T git@github.com || true

echo
echo "✅ SSH setup complete. Add the above key to GitHub to use hub/git."
