#!/usr/bin/env bash

# bootstrap.sh - Install the dotfiles.
set -euo pipefail

# ------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--all] [--standalone] [--replace] [--help]
  curl -fsSL https://raw.githubusercontent.com/venkateshcv1809/dotfiles/main/bootstrap.sh | bash -s -- --all

With no flags, a terminal asks for the mode. Enter selects managed.
  managed       Keep ~/dotfiles and symlink configuration with Stow.
  standalone    Copy configuration into $HOME. This run's temporary clone is removed.

  --all         No prompts: every package. Managed unless --standalone.
                Does not change the login shell.
  --standalone  Select standalone mode.
  --replace     Move a conflicting file to a sibling .bak-<timestamp>.
  --help        Print this usage and exit.

A pipe has no terminal, so pass flags after bash -s --.
Existing files stay unless confirmed, or --replace is set.
EOF
}

# ------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------
REPO_URL="https://github.com/venkateshcv1809/dotfiles.git"

# required is always installed. ask prompts, default yes.
PACKAGES=(
  mise:required
  sheldon:required
  shell:required
  bash:required
  zsh:ask
  starship:ask
  git:ask
  lazygit:ask
  bat:ask
  eza:ask
  zoxide:ask
  fd:ask
  fzf:ask
  ripgrep:ask
  nvim:ask
  tmux:ask
  xxh:ask
  typescript:ask
  python:ask
  go:ask
  rust:ask
  zig:ask
)

# Tools this script requires. zsh is installed later if that package is selected.
PREREQS=(git curl)

# Managed mode requires Stow.
PREREQS_managed=(stow)

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME

# ------------------------------------------------------------------------
# Run state
# ------------------------------------------------------------------------
AUTO_YES=0
REPLACE=0
CREATED_TEMP=0
MODE=""
DOTFILES=""
ZSH_APPLIED=0
BASH_APPLIED=0
SHELDON_APPLIED=0
STAMP="$(date +%Y%m%d-%H%M%S)"

# ------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------
log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------------
# Prompts
# ------------------------------------------------------------------------
is_tty() { [[ -t 0 && -t 1 ]]; }

ask() {
  local prompt="$1" reply
  if ((AUTO_YES)); then
    log "$prompt -> y"
    return 0
  fi
  is_tty || die "no TTY; re-run with --all or --standalone"
  read -r -p "$prompt [Y/n] " reply || true
  case "${reply:-y}" in
    y|Y|yes|YES|"") return 0 ;;
    *) return 1 ;;
  esac
}

ask_replace() {
  local prompt="$1" reply
  if ((REPLACE)); then
    log "$prompt -> y"
    return 0
  fi
  if ((AUTO_YES)); then
    log "$prompt -> n"
    return 1
  fi
  is_tty || return 1
  read -r -p "$prompt [y/N] " reply || true
  case "${reply:-n}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------
parse_args() {
  while (($#)); do
    case "$1" in
      --all) AUTO_YES=1 ;;
      --standalone) MODE=standalone ;;
      --replace) REPLACE=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done
}

choose_mode() {
  local reply
  if [[ -n "$MODE" ]]; then
    :
  elif ((AUTO_YES)); then
    MODE=managed
  else
    is_tty || die "no TTY; pass --all or --standalone"
    printf 'Install mode:\n'
    printf '  [m] managed     keep ~/dotfiles and symlink with stow\n'
    printf '  [s] standalone  copy configs into $HOME (a temp clone is removed afterward)\n'
    read -r -p "Mode [m]: " reply || true
    case "${reply:-managed}" in
      managed|m|M) MODE=managed ;;
      standalone|s|S) MODE=standalone ;;
      *) die "unknown mode: $reply" ;;
    esac
  fi
  case "$MODE" in
    managed|standalone) ;;
    *) die "unknown mode: $MODE" ;;
  esac
}

# ------------------------------------------------------------------------
# Prerequisites
# ------------------------------------------------------------------------
os_id() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux)
      if [[ ! -r /etc/os-release ]]; then
        printf 'linux\n'
        return
      fi
      # shellcheck disable=SC1091
      . /etc/os-release
      printf '%s\n' "${ID:-linux}"
      ;;
    *) printf '%s\n' "$(uname -s | tr '[:upper:]' '[:lower:]')" ;;
  esac
}

detect_package_manager() {
  local release_os="$1"
  local manager="none"
  if [[ "$release_os" == "macos" ]]; then
    manager="brew"
  elif [[ "$(uname -s)" == "Linux" ]]; then
    if [[ -r /etc/os-release ]]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      case "${ID:-}:${ID_LIKE:-}" in
        ubuntu*|debian*|*:ubuntu*|*:debian*) manager="apt" ;;
        arch*|*:arch*) manager="pacman" ;;
        fedora*|rhel*|*:fedora*|*:rhel*) manager="dnf" ;;
      esac
    fi
  fi
  printf '%s\n' "$manager"
}

prepare_package_manager() {
  local manager="$1"
  case "$manager" in
    brew) ensure_macos_brew ;;
    apt) require_command apt-get ;;
    pacman) require_command pacman ;;
    dnf) require_command dnf ;;
  esac
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "$1 is not available"
  fi
}

# brew stays off PATH until shellenv.
ensure_macos_brew() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return
  fi
  log "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    die "Homebrew installed but brew was not found on PATH"
  fi
}

# brew and the distro package managers use the same names as PREREQS.
install_system_packages() {
  local os="$1" manager="$2"
  shift 2
  case "$manager" in
    brew)
      log "installing with brew: $*"
      brew install "$@"
      ;;
    apt)
      log "installing with apt: $*"
      apt_install "$@"
      ;;
    pacman)
      log "installing with pacman: $*"
      pacman_install "$@"
      ;;
    dnf)
      log "installing with dnf: $*"
      dnf_install "$@"
      ;;
    *)
      die "$os has no package installer in this script; install $* and re-run"
      ;;
  esac
}

apt_install() {
  local sudo=""
  if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      die "sudo is required to install apt packages"
    fi
    sudo="sudo"
  fi
  if [[ -n "$sudo" ]]; then
    sudo apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  else
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  fi
}

pacman_install() {
  local sudo=""
  if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      die "sudo is required to install pacman packages"
    fi
    sudo="sudo"
  fi
  if [[ -n "$sudo" ]]; then
    sudo pacman -S --noconfirm --needed "$@"
  else
    pacman -S --noconfirm --needed "$@"
  fi
}

dnf_install() {
  local sudo=""
  if [[ "$(id -u)" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      die "sudo is required to install dnf packages"
    fi
    sudo="sudo"
  fi
  if [[ -n "$sudo" ]]; then
    sudo dnf install -y "$@"
  else
    dnf install -y "$@"
  fi
}

install_prereqs() {
  local os="$1" manager="$2" pkg
  local -a required=() missing=()
  required=("${PREREQS[@]}")
  if [[ "$MODE" == "managed" ]]; then
    required+=("${PREREQS_managed[@]}")
  fi
  for pkg in "${required[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done
  if ((${#missing[@]})); then
    install_system_packages "$os" "$manager" "${missing[@]}"
  else
    log "required tools already installed"
  fi
  for pkg in "${required[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      die "$pkg is required"
    fi
  done
}

# ------------------------------------------------------------------------
# Checkout
# ------------------------------------------------------------------------
checkout_at() {
  local root="$1"
  [[ -f "$root/bootstrap.sh" && -d "$root/shell" && -d "$root/mise" ]]
}

checkout_root() {
  local src="${BASH_SOURCE[0]:-}"
  local root
  [[ -n "$src" && -f "$src" ]] || return 1
  root="$(CDPATH= cd -P -- "$(dirname -- "$src")" && pwd)" || return 1
  checkout_at "$root" || return 1
  printf '%s\n' "$root"
}

ensure_checkout() {
  local root dest
  if root="$(checkout_root)"; then
    DOTFILES="$root"
    return
  fi
  if [[ -z "$REPO_URL" ]]; then
    die "REPO_URL is empty; set it at the top of bootstrap.sh before cloning"
  fi
  if [[ "$MODE" == "managed" ]]; then
    dest="$HOME/dotfiles"
    if checkout_at "$dest"; then
      log "reusing $dest"
      DOTFILES="$dest"
      return
    fi
    if [[ -e "$dest" ]]; then
      die "$dest exists and is not a dotfiles checkout"
    fi
    log "cloning into $dest"
    git clone -- "$REPO_URL" "$dest"
    DOTFILES="$dest"
    return
  fi
  dest="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX")"
  log "cloning into $dest"
  if ! git clone -- "$REPO_URL" "$dest"; then
    rm -rf "$dest"
    die "git clone failed"
  fi
  : >"$dest/.bootstrap-temp-clone"
  CREATED_TEMP=1
  DOTFILES="$dest"
}

is_temp_path() {
  local p="$1" tmp="${TMPDIR:-/tmp}"
  tmp="${tmp%/}"
  case "$p" in
    "$tmp"/*|/tmp/*|/private/tmp/*|/var/folders/*|/private/var/folders/*) return 0 ;;
    *) return 1 ;;
  esac
}

cleanup_temp() {
  local root="${DOTFILES:-}"
  [[ "${CREATED_TEMP:-0}" -eq 1 ]] || return 0
  if [[ -z "$root" || ! -f "$root/.bootstrap-temp-clone" ]]; then
    warn "keeping checkout ${root:-unknown}; this run did not create it"
    return 0
  fi
  if ! is_temp_path "$root"; then
    warn "keeping $root; refusing to delete a checkout outside a temp directory"
    return 0
  fi
  log "removing temporary clone $root"
  rm -rf "$root"
}

# ------------------------------------------------------------------------
# Mise
# ------------------------------------------------------------------------
ensure_mise() {
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
  if command -v mise >/dev/null 2>&1; then
    log "mise already installed ($(mise --version 2>/dev/null | head -n1))"
    return
  fi
  log "installing mise"
  curl -fsSL https://mise.run | sh
  command -v mise >/dev/null 2>&1 || die "mise installed but not found at $HOME/.local/bin/mise"
}

# ------------------------------------------------------------------------
# Packages
# ------------------------------------------------------------------------
select_packages() {
  local spec name mode
  SELECTED=()
  for spec in "${PACKAGES[@]}"; do
    name="${spec%%:*}"
    mode="${spec##*:}"
    case "$mode" in
      required) SELECTED+=("$name") ;;
      ask)
        if ask "Install $name?"; then
          SELECTED+=("$name")
        fi
        ;;
      *) die "unknown package mode for $name: $mode (use required or ask)" ;;
    esac
  done
}

canon() {
  local path="$1" target dir hops=0
  while [[ -L "$path" ]]; do
    hops=$((hops + 1))
    if ((hops > 20)); then
      return 1
    fi
    target="$(readlink "$path")" || return 1
    if [[ "$target" == /* ]]; then
      path="$target"
    else
      path="$(dirname -- "$path")/$target"
    fi
  done
  dir="$(dirname -- "$path")"
  [[ -d "$dir" ]] || return 1
  dir="$(CDPATH= cd -P -- "$dir" && pwd)" || return 1
  printf '%s/%s\n' "$dir" "$(basename -- "$path")"
}

# Print the path that blocks dest. Return 1 when dest is free or already this checkout.
conflict_path() {
  local src="$1" dest="$2" path src_c dest_c
  path="$(dirname -- "$dest")"
  while [[ "$path" == "$HOME"/* ]]; do
    if [[ -e "$path" || -L "$path" ]]; then
      if [[ ! -d "$path" ]]; then
        printf '%s\n' "$path"
        return 0
      fi
    fi
    path="$(dirname -- "$path")"
  done
  if [[ -e "$dest" || -L "$dest" ]]; then
    src_c="$(canon "$src" || true)"
    dest_c="$(canon "$dest" || true)"
    if [[ -n "$src_c" && "$src_c" == "$dest_c" ]]; then
      return 1
    fi
    printf '%s\n' "$dest"
    return 0
  fi
  return 1
}

backup_path() {
  local dest="$1" bak="${1}.bak-${STAMP}"
  if [[ -e "$bak" || -L "$bak" ]]; then
    bak="${bak}-$$"
  fi
  mv "$dest" "$bak" || die "could not move $dest"
  log "moved $dest -> $bak"
}

apply_package() {
  local pkg="$1" src rel dest conflict
  local -a conflicts=()
  local -a replace=()
  local i=0 skip=0 seen=0

  [[ -d "$DOTFILES/$pkg" ]] || die "package directory missing: $pkg"

  while IFS= read -r -d '' src; do
    rel="${src#"$DOTFILES/$pkg"/}"
    dest="$HOME/$rel"
    conflict="$(conflict_path "$src" "$dest" || true)"
    [[ -n "$conflict" ]] || continue
    seen=0
    i=0
    while ((i < ${#conflicts[@]})); do
      if [[ "${conflicts[i]}" == "$conflict" ]]; then
        seen=1
        break
      fi
      i=$((i + 1))
    done
    if ((seen == 0)); then
      conflicts+=("$conflict")
    fi
  done < <(find "$DOTFILES/$pkg" -type f -print0)

  i=0
  while ((i < ${#conflicts[@]})); do
    if ask_replace "Replace ${conflicts[i]}? It will be moved to ${conflicts[i]}.bak-${STAMP}"; then
      replace+=("y")
    else
      replace+=("n")
      skip=1
      warn "leaving ${conflicts[i]} in place"
    fi
    i=$((i + 1))
  done

  if [[ "$MODE" == "managed" && "$skip" -eq 1 ]]; then
    warn "skipping stow of $pkg; conflicts remain"
    return 1
  fi

  i=0
  while ((i < ${#conflicts[@]})); do
    if [[ "${replace[i]}" == "y" ]]; then
      backup_path "${conflicts[i]}"
    fi
    i=$((i + 1))
  done

  if [[ "$MODE" == "managed" ]]; then
    log "stowing $pkg"
    # Stow 2.4 stows nothing when -- comes before the package name.
    stow -R -v -t "$HOME" -d "$DOTFILES" "$pkg" || die "stow failed for $pkg"
    return 0
  fi

  while IFS= read -r -d '' src; do
    rel="${src#"$DOTFILES/$pkg"/}"
    dest="$HOME/$rel"
    conflict="$(conflict_path "$src" "$dest" || true)"
    if [[ -n "$conflict" ]]; then
      warn "not copying $dest"
      continue
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
      continue
    fi
    mkdir -p "$(dirname -- "$dest")" || die "could not create $(dirname -- "$dest")"
    cp -p "$src" "$dest" || die "copy failed: $dest"
  done < <(find "$DOTFILES/$pkg" -type f -print0)

  if [[ "$skip" -eq 1 ]]; then
    warn "$pkg copied except conflicting files"
    return 1
  fi
  log "copied $pkg"
  return 0
}

# ------------------------------------------------------------------------
# Login environment
# ------------------------------------------------------------------------
trust_and_install_mise() {
  local f
  if [[ -f "$XDG_CONFIG_HOME/mise/config.toml" ]]; then
    mise -y trust "$XDG_CONFIG_HOME/mise/config.toml"
  fi
  if [[ -d "$XDG_CONFIG_HOME/mise/conf.d" ]]; then
    for f in "$XDG_CONFIG_HOME/mise/conf.d/"*.toml; do
      [[ -e "$f" ]] || continue
      mise -y trust "$f"
    done
  fi
  log "installing mise tools"
  if ! mise install -y; then
    warn "mise install failed; a tool may have no build for $(uname -m). Continuing."
  fi
}

ensure_rc_snippet() {
  local file="$1" snippet="$2"
  local begin="# >>> dotfiles >>>"
  local end="# <<< dotfiles <<<"
  local tmp
  mkdir -p "$(dirname -- "$file")"
  if [[ -f "$file" ]] && grep -Fxq "$begin" "$file"; then
    tmp="$(mktemp)"
    BEGIN="$begin" END="$end" SNIPPET="$snippet" awk '
      BEGIN { b = ENVIRON["BEGIN"]; e = ENVIRON["END"]; s = ENVIRON["SNIPPET"] }
      $0 == b {
        print b
        print s
        print e
        skip = 1
        next
      }
      skip && $0 == e { skip = 0; next }
      !skip { print }
    ' "$file" >"$tmp"
    mv "$tmp" "$file"
    return
  fi
  if [[ -f "$file" ]] && grep -Fqx "$snippet" "$file"; then
    return
  fi
  log "updating $file"
  printf '\n%s\n%s\n%s\n' "$begin" "$snippet" "$end" >>"$file"
}

wire_shell_rc() {
  if [[ "$ZSH_APPLIED" -eq 1 ]]; then
    ensure_rc_snippet \
      "${ZDOTDIR:-$HOME}/.zshrc" \
      '[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshrc.global" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshrc.global"'
  fi
  if [[ "$BASH_APPLIED" -eq 1 ]]; then
    ensure_rc_snippet \
      "$HOME/.bashrc" \
      '[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/shell/bashrc.global" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/shell/bashrc.global"'
  fi
}

# Add the shared gitconfig include unless ~/.config/git/config already exists.
ensure_git_include() {
  local xdg="$XDG_CONFIG_HOME/git/config"
  local file="$HOME/.gitconfig"
  local snippet='path = ~/.config/git/global.gitconfig'
  if [[ -e "$xdg" || -L "$xdg" ]]; then
    log "leaving $xdg unchanged"
    return
  fi
  if [[ -f "$file" ]] && grep -Fq "$snippet" "$file"; then
    return
  fi
  log "updating $file"
  printf '\n[include]\n\t%s\n' "$snippet" >>"$file"
}

lock_sheldon() {
  local shell
  if [[ "$SHELDON_APPLIED" -ne 1 ]]; then
    warn "sheldon package is not in place; skipping sheldon lock"
    return
  fi
  if ! command -v sheldon >/dev/null 2>&1; then
    warn "sheldon is not on PATH; skipping sheldon lock"
    return
  fi
  for shell in zsh bash; do
    log "locking sheldon plugins ($shell)"
    sheldon \
      --config-file "$XDG_CONFIG_HOME/sheldon/${shell}-plugins.toml" \
      --data-dir "$XDG_DATA_HOME/sheldon/$shell" \
      lock || warn "sheldon lock failed for $shell; continuing"
  done
}

maybe_chsh_zsh() {
  local zsh_path
  if ((AUTO_YES)); then
    log "leaving login shell unchanged (${SHELL:-unknown}); run chsh interactively if you want zsh"
    return
  fi
  if [[ "$ZSH_APPLIED" -ne 1 ]]; then
    return
  fi
  zsh_path="$(command -v zsh)"
  [[ -n "$zsh_path" ]] || return
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    log "login shell is already zsh ($zsh_path)"
    return
  fi
  ask "Set login shell to zsh ($zsh_path)?" || return
  if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
    warn "$zsh_path is not in /etc/shells; add it (with sudo) before chsh can succeed"
  fi
  log "changing login shell to $zsh_path"
  chsh -s "$zsh_path" || warn "chsh failed; run: chsh -s $zsh_path"
}

# ------------------------------------------------------------------------
# Entry
# ------------------------------------------------------------------------
ensure_package_system_deps() {
  local os="$1" manager="$2"
  local -a extra=()
  local name
  for name in "${SELECTED[@]}"; do
    case "$name" in
      zsh)
        if ! command -v zsh >/dev/null 2>&1; then
          extra+=(zsh)
        fi
        ;;
      nvim)
        if command -v make >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; then
          continue
        fi
        case "$manager" in
          apt) extra+=(build-essential) ;;
          brew) extra+=(make) ;;
          pacman) extra+=(base-devel) ;;
          dnf) extra+=(gcc make) ;;
        esac
        ;;
    esac
  done
  if ((${#extra[@]})); then
    install_system_packages "$os" "$manager" "${extra[@]}"
  fi
}

main() {
  parse_args "$@"
  choose_mode
  local os pkg manager
  os="$(os_id)"
  manager="$(detect_package_manager "$os")"
  prepare_package_manager "$manager"
  log "mode: $MODE"
  log "os: $os"
  log "package manager: $manager"
  log "arch: $(uname -m)"
  install_prereqs "$os" "$manager"
  ensure_checkout
  log "dotfiles: $DOTFILES"

  # Real directories so the first package does not symlink the whole directory.
  mkdir -p \
    "$XDG_CONFIG_HOME" \
    "$XDG_CONFIG_HOME/shell" \
    "$XDG_CONFIG_HOME/sheldon/zsh.d" \
    "$XDG_CONFIG_HOME/sheldon/bash.d" \
    "$XDG_CONFIG_HOME/mise/conf.d" \
    "$XDG_DATA_HOME" \
    "$XDG_STATE_HOME" \
    "$HOME/.local/bin"

  ensure_mise

  select_packages
  ensure_package_system_deps "$os" "$manager"
  for pkg in "${SELECTED[@]}"; do
    if apply_package "$pkg"; then
      case "$pkg" in
        zsh) ZSH_APPLIED=1 ;;
        bash) BASH_APPLIED=1 ;;
        sheldon) SHELDON_APPLIED=1 ;;
      esac
    fi
  done

  trust_and_install_mise
  wire_shell_rc
  ensure_git_include
  lock_sheldon
  maybe_chsh_zsh
  cleanup_temp

  log "done"
  printf '\nOpen a new terminal (or run: exec zsh) so mise + sheldon pick up the new PATH.\n'
}

main "$@"
