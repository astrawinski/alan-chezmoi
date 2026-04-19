# Alan Chezmoi

This is Alan's real `chezmoi` source of truth.

It is intended to support the normal new-machine flow:

1. install `lpass`
2. log into LastPass
3. install `chezmoi`
4. run `chezmoi init --apply <repo>`

The repo is designed to be public-safe:

- no secret values are committed
- secret-bearing files are rendered from LastPass at apply time
- package installation happens through `chezmoi` data plus `run_onchange_`
  scripts

## Bootstrap

On a fresh Debian machine:

```bash
chezmoi init --apply https://github.com/astrawinski/alan-chezmoi.git
```

This assumes:

- `lpass` is installed
- `lpass login` has already succeeded
- `chezmoi` is installed

## LastPass Items

This repo currently expects these LastPass entries:

- `GitHub Personal Access Token`
  - `password`
  - used for:
    - `~/.config/wsub/github-token.env`
    - `~/.config/wsub/gh/hosts.yml`

- `Codex Auth`
  - raw JSON stored in the note body
  - used for:
    - `~/.codex/auth.json`

- `WSUB API Keys`
  - raw env-style file content stored in the note body
  - used for:
    - `~/.api_keys`

- `GitHub SSH Key`
  - note fields:
    - `privateKey:`
    - `publicKey:`
  - used for:
    - `~/.ssh/id_ed25519`
    - `~/.ssh/id_ed25519.pub`

- `SOPS Age Key`
  - note fields:
    - `privateKey:`
  - used for:
    - `~/.config/sops/age/keys.txt`

## Package Installation

Package installation is driven by:

- `.chezmoidata/packages.yaml`
- `run_onchange_after_20-install-packages.sh.tmpl`

That follows the standard `chezmoi` pattern of declarative package data plus
an imperative install script.

## GNOME State

Bounded GNOME state lives under:

- `gnome/dconf/desktop-session.ini`
- `gnome/dconf/shell.ini`
- `gnome/dconf/power.ini`

It is applied only when the machine is running a GNOME session with a usable
session bus.

## Repo Shape

Important paths:

```text
.chezmoidata/packages.yaml
dot_bashrc
dot_bash_aliases
dot_profile
dot_gitconfig
dot_api_keys.tmpl
dot_ssh/config
private_dot_ssh/id_ed25519.tmpl
private_dot_ssh/id_ed25519.pub.tmpl
private_dot_config/sops/age/keys.txt.tmpl
dot_config/
  Code/User/settings.json
  mimeapps.list
  wsub/gh/config.yml
  wsub/gh/hosts.yml.tmpl
  wsub/github-token.env.tmpl
private_dot_codex/
  auth.json.tmpl
run_onchange_after_20-install-packages.sh.tmpl
run_onchange_after_30-load-gnome-dconf.sh.tmpl
gnome/dconf/
  desktop-session.ini
  shell.ini
  power.ini
```
