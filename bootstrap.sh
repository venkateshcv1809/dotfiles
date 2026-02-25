#!/bin/sh

# -e: Exit on error
set -eu

echo  "🚀 Bootstrapping Foundations..."

# --- DETECT PACKAGE MANAGER ---
if command -v apt-get >/dev/null 2>&1; then
    INSTALL="sudo apt-get install -y"
    UPDATE="sudo apt-get update"
elif command -v brew >/dev/null 2>&1; then
    INSTALL="brew install"
    UPDATE="brew update"
elif command -v dnf >/dev/null 2>&1; then
    INSTALL="sudo dnf install -y"
    UPDATE="sudo dnf check-update"
else
    # Fallback for Mac if Brew isn't there yet
    if [ "$(uname)" = "Darwin" ]; then
        echo "🍺 Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        INSTALL="brew install"
        UPDATE="brew update"
    else
        echo "❌ No supported package manager (apt, dnf, brew) found."
        exit 1
    fi
fi

# --- GIT CHECK ---
if ! command -v git >/dev/null 2>&1; then
    echo "🔗 Git not found. Installing..."
    $UPDATE && $INSTALL git
else
    echo "✅ Git is already installed."
fi

# --- ANSIBLE CHECK ---
if ! command -v ansible >/dev/null 2>&1; then
    echo "🏗️ Ansible not found. Installing..."
    $UPDATE && $INSTALL ansible
else
    echo "✅ Ansible is already installed."
fi

# --- CLONE REPOSITORY ---
DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/venkateshcv1809/dotfiles.git"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📂 Cloning dotfiles to $DOTFILES_DIR..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
else
    echo "🔄 Dotfiles directory exists. Pulling latest..."
    (cd "$DOTFILES_DIR" && git pull)
fi

# --- HANDOFF TO ANSIBLE ---
echo "🏗️ Handing off to Ansible Playbook..."
cd "$DOTFILES_DIR"

# Check if playbook exists before running
if [ -f "playbook.yml" ]; then
    ansible-playbook playbook.yml
else
    echo "⚠️ playbook.yml not found. Setup stopped at foundation."
    echo "Next step: Create your playbook.yml in the repo."
fi

echo "✨ Bootstrap phase complete."
