# Dotfiles

Stow packages plus a bootstrap script. Tools are installed with [mise](https://mise.jdx.dev/). Shell plugins are loaded with [sheldon](https://sheldon.cli.rs/).

## Install

Managed mode keeps this repository at `~/dotfiles` and symlinks configuration into `$HOME`:

```sh
git clone https://github.com/venkateshcv1809/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
```

If you already have a checkout somewhere else (for example `~/.dotfiles`), run `bootstrap.sh` from that tree. The script uses the directory it lives in and does not clone a second copy.

Non-interactive (every package, no login-shell change):

```sh
curl -fsSL https://raw.githubusercontent.com/venkateshcv1809/dotfiles/main/bootstrap.sh | bash -s -- --all
```

Standalone mode copies files into `$HOME` and removes the temporary clone:

```sh
./bootstrap.sh --standalone
```

`--replace` moves conflicting files to a sibling `.bak-<timestamp>` instead of leaving them in place.

After install, open a new terminal or run `exec zsh` (or `exec bash`) so mise and sheldon pick up PATH.

## Layout

Each top-level directory is a GNU Stow package. Shared pieces:

| Path | Role |
| --- | --- |
| `shell/` | POSIX `env.sh` and `aliases.sh` |
| `bash/`, `zsh/` | Shell rc that sources the shared files, then mise + sheldon |
| `mise/` | Global mise settings |
| `*/.config/mise/conf.d/` | Per-package tool versions |
| `sheldon/` | Plugin lists; other packages drop fragments into `sheldon/{zsh,bash}.d` |
| `fonts/` | MesloLGS Nerd Font files plus fontconfig (`monospace` → Meslo) |

Required packages: `mise`, `sheldon`, `shell`, `bash`. Everything else is optional (default yes at the prompt, always yes with `--all`).

The `fonts` package is the single place for the terminal typeface: files under `~/.local/share/fonts`, and `fontconfig` preferring **MesloLGS Nerd Font** for `monospace`. Bootstrap only runs `fc-cache`. Apps that ignore fontconfig need their own font setting.
