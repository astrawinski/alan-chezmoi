# Alan Chezmoi

This is Alan's real `chezmoi` source of truth.

It is intended to support the normal new-machine flow:

1. install `chezmoi`
2. run `chezmoi init --apply <repo>`
3. let the first apply install `lpass`
4. run `lpass login`
5. run `refresh-workstation-secrets`

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

Then:

```bash
lpass login
refresh-workstation-secrets
```

The first apply is expected to succeed before LastPass login. Secret rendering
is intentionally deferred until `lpass login` succeeds and the explicit
refresh helper runs.

## LastPass Items

This repo currently expects these LastPass entries:

- `WSUB/secret-github-pat`
  - `password`
  - used for:
    - `~/.config/wsub/github-token.env`
    - `~/.config/wsub/gh/hosts.yml`

- `WSUB/secret-api-keys`
  - raw env-style file content stored in the note body
  - used for:
    - `~/.api_keys`
  - optional; only needed if you actually use shared env-style API keys

- `WSUB/secret-onedrive-refresh-token`
  - `password`
  - used for:
    - `~/.config/onedrive/refresh_token`
  - optional; only needed on hosts that actually use the OneDrive client

- `WSUB/secret-github-ssh`
  - note fields:
    - `privateKey:`
    - `publicKey:`
  - used for:
    - `~/.ssh/id_ed25519`
    - `~/.ssh/id_ed25519.pub`
    - `~/.ssh/config`

- `WSUB/secret-sops-age`
  - note fields:
    - `privateKey:`
  - used for:
    - `~/.config/sops/age/keys.txt`

## Package Installation

Package installation is driven by:

- `.chezmoidata/packages.yaml`
- `.chezmoidata/vscode.yaml`
- `run_once_before_10-install-lastpass-cli.sh.tmpl`
- `run_onchange_after_20-install-packages.sh.tmpl`
- `run_onchange_after_25-install-vscode-extensions.sh.tmpl`
- `run_onchange_after_26-install-npm-global-tools.sh.tmpl`

That follows the standard `chezmoi` pattern of declarative package and editor
data plus imperative install scripts.

Global npm tools are declared in `.chezmoidata/packages.yaml` under:

- `packages.linux.npm_global_tools`

That keeps non-apt CLI tools like `codex` out of the Debian package model.

Linux package data is split into:

- `apt_core_common`
  - core command-line packages shared across machines
- `apt_gui_common`
  - desktop-neutral GUI packages shared across machines
- `role_packages`
  - reusable package groups keyed by workstation intent
- `desktop_packages`
  - package groups keyed by desktop family
- `hosts`
  - additive host-specific deltas keyed by hostname

Hosts should only describe what is unique to that host, for example:

- `desktop_family`
- `roles`
- `apt_extra`

The install hook merges:

- core CLI packages
- GUI-common packages
- role packages for the current host
- desktop-family packages for `{{ .chezmoi.hostname }}`
- host-specific extra packages

That keeps host blocks small and avoids duplicating shared package intent
across multiple machines.

The LastPass CLI package is built locally on Linux with:

- upstream `lastpass-cli`
- Debian build metadata shipped by upstream
- `DEB_BUILD_OPTIONS=nocheck`

The `nocheck` override is intentional because the upstream package test suite
is currently failing on Debian 13 even though the package build itself
completes successfully.

## Drift Review

To review live workstation drift before promoting it into repo truth:

```bash
./scripts/drift-inbox.sh
```

That compares the current host against:

- modeled apt packages for the current host overlay
- modeled global npm tools in `packages.linux.npm_global_tools`
- curated VS Code extension ids in `.chezmoidata/vscode.yaml`

It reports:

- manual packages installed locally but not modeled yet
- modeled packages that are not installed locally
- global npm tools installed locally but not modeled yet
- modeled global npm tools that are not installed locally
- VS Code extensions installed locally but not modeled yet
- modeled VS Code extensions that are not installed locally

To review a different host overlay from the current machine:

```bash
./scripts/drift-inbox.sh --host wsub-mbp01
```

## Secret Rendering

LastPass-backed files are rendered by:

- `~/.local/bin/refresh-workstation-secrets`

That helper:

- is installed by `chezmoi`
- requires `lpass` to be installed and logged in
- renders the secret-bearing files on demand
- can be rerun any time after LastPass items change

## GNOME State

Bounded GNOME state lives under:

- `gnome/dconf/desktop-session.ini`
- `gnome/dconf/shell.ini`
- `gnome/dconf/power.ini`

It is applied only when:

- the current host overlay declares `desktop_family: gnome`
- the machine is running a GNOME session
- a usable session bus is present

## Repo Shape

Important paths:

```text
.chezmoidata/packages.yaml
.chezmoi.toml.tmpl
dot_bashrc
dot_bash_aliases
dot_profile
dot_gitconfig
dot_config/
  Code/User/settings.json
  mimeapps.list
  onedrive/config
  wsub/gh/config.yml
run_once_before_10-install-lastpass-cli.sh.tmpl
run_onchange_after_20-install-packages.sh.tmpl
run_onchange_after_25-install-vscode-extensions.sh.tmpl
run_onchange_after_26-install-npm-global-tools.sh.tmpl
run_onchange_after_30-load-gnome-dconf.sh.tmpl
dot_local/bin/executable_refresh-workstation-secrets.tmpl
gnome/dconf/
  desktop-session.ini
  shell.ini
  power.ini
```
