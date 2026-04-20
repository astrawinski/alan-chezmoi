# Alan Chezmoi

This is Alan's real `chezmoi` source of truth.

It is intended to support the normal new-machine flow:

1. install `chezmoi`
2. run `chezmoi init --apply <repo>`
3. let the first apply install `lpass`
4. run `lpass login`
5. run `chezmoi apply` again so secrets render

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
chezmoi apply
```

The first apply is expected to succeed before LastPass login. Secret rendering
is intentionally deferred until `lpass login` succeeds and a later
`chezmoi apply` runs.

## LastPass Items

This repo currently expects these LastPass entries:

- `WSUB/GitHub Personal Access Token`
  - `password`
  - used for:
    - `~/.config/wsub/github-token.env`
    - `~/.config/wsub/gh/hosts.yml`

- `WSUB/API Keys`
  - raw env-style file content stored in the note body
  - used for:
    - `~/.api_keys`
  - optional; only needed if you actually use shared env-style API keys

- `WSUB/GitHub SSH Key`
  - note fields:
    - `privateKey:`
    - `publicKey:`
  - used for:
    - `~/.ssh/id_ed25519`
    - `~/.ssh/id_ed25519.pub`
    - `~/.ssh/config`

- `WSUB/SOPS Age Key`
  - note fields:
    - `privateKey:`
  - used for:
    - `~/.config/sops/age/keys.txt`

## Package Installation

Package installation is driven by:

- `.chezmoidata/packages.yaml`
- `run_once_before_10-install-lastpass-cli.sh.tmpl`
- `run_onchange_after_20-install-packages.sh.tmpl`

That follows the standard `chezmoi` pattern of declarative package data plus
imperative install scripts.

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

## Secret Rendering

LastPass-backed files are rendered by:

- `run_after_40-render-lastpass-secrets.sh.tmpl`

That hook is intentionally tolerant:

- if `lpass` is not installed yet, it exits cleanly
- if `lpass` is not logged in yet, it exits cleanly
- after `lpass login`, a normal `chezmoi apply` renders the secret-bearing
  files

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
  wsub/gh/config.yml
run_once_before_10-install-lastpass-cli.sh.tmpl
run_onchange_after_20-install-packages.sh.tmpl
run_onchange_after_30-load-gnome-dconf.sh.tmpl
run_after_40-render-lastpass-secrets.sh.tmpl
gnome/dconf/
  desktop-session.ini
  shell.ini
  power.ini
```
