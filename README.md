# Alan Chezmoi

This is Alan's real `chezmoi` source of truth.

It is intended to support the normal new-machine flow:

1. install `chezmoi`
2. run `chezmoi init --apply <repo>`
3. let the first apply install `lpass`
4. if you rebuilt a known host, refresh its SSH host key:
   `ssh-refresh-host <host>`
5. run `lpass login`
6. run `refresh-workstation-secrets`

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
ssh-refresh-host <host>
lpass login
refresh-workstation-secrets
```

When a rotatable local secret changes on one machine and you want to publish the
new value back into LastPass for later restore on other machines:

```bash
update-workstation-secrets codex
update-workstation-secrets onedrive
update-workstation-secrets api-keys
```

The first apply is expected to succeed before LastPass login. Secret rendering
is intentionally deferred until `lpass login` succeeds and the explicit
refresh helper runs. Managed `~/src` repo checkouts are also retried from that
same secret-refresh step, after the GitHub SSH key and SSH config have been
restored.

For public GitHub repos, the first apply now falls back to an unauthenticated
HTTPS bootstrap clone when SSH clone fails on a fresh machine, then resets the
configured `origin` back to the intended SSH URL. That keeps first-run repo
sync from depending on the GitHub SSH key while preserving the normal SSH
remote shape after clone. The public bootstrap also seeds `github.com` into
`~/.ssh/known_hosts` before repo sync so first-run SSH clone attempts do not
stop on a host-trust prompt.

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

- `WSUB/secret-codex-auth`
  - raw `~/.codex/auth.json` content stored in the note body
  - used for:
    - `~/.codex/auth.json`
  - optional; only needed if you want Codex auth restored onto fresh machines
    through the LastPass-backed secret-refresh path

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
- `.chezmoidata/repos.yaml`
- `.chezmoidata/vscode.yaml`
- `run_once_before_10-install-lastpass-cli.sh.tmpl`
- `run_onchange_before_20-configure-third-party-apt-sources.sh.tmpl`
- `run_onchange_after_20-install-packages.sh.tmpl`
- `run_onchange_after_21-install-discord.sh.tmpl`
- `run_onchange_after_25-install-vscode-extensions.sh.tmpl`
- `run_onchange_after_26-install-npm-global-tools.sh.tmpl`
- `run_onchange_after_27-enable-ssh-agent.sh.tmpl`
- `run_onchange_after_28-sync-user-repos.sh.tmpl`

That follows the standard `chezmoi` pattern of declarative package and editor
data plus imperative install scripts.

The workstation source also enables the stock user-level `ssh-agent.socket` on
Linux so rebuilds do not depend on incidental session state for the OpenSSH
agent path.

Global npm tools are declared in `.chezmoidata/packages.yaml` under:

- `packages.linux.npm_global_tools`

That keeps non-apt CLI tools like `codex` out of the Debian package model.

Tracked repo checkouts are declared in `.chezmoidata/repos.yaml`. On Linux this
repo ensures `~/src` exists and converges these checkouts:

- `wsub`
- `cavekit`
- `terraform-provider-unifi`

The sync surface is:

- `~/.local/bin/sync-user-repos`

It runs during `chezmoi apply` on a best-effort basis and is retried
automatically after `refresh-workstation-secrets`, when the GitHub SSH key has
been refreshed. Existing unexpected directories or repos with the wrong origin
are warned about and left alone instead of being rewritten.

The SSH host-key refresh surface is:

- `~/.local/bin/ssh-refresh-host`

Use it after reinstalling a known machine whose SSH host key has changed:

```bash
ssh-refresh-host wsub-mbp01
```

The secret-update surface is:

- `~/.local/bin/update-workstation-secrets`

It pushes selected local secret state back into LastPass so later
`refresh-workstation-secrets` runs on other machines can pull the updated
value down. The first version intentionally supports only:

- `codex`
- `onedrive`
- `api-keys`
- `all`

It does not currently rewrite GitHub PAT, SSH keys, or `age` keys.

Normal operator flow should not need `sync-user-repos` directly. Treat it as a
repair command if a managed checkout is missing or the automatic retry could
not complete during bootstrap. `alan-chezmoi` itself is intentionally excluded
from this list when you are using `chezmoi` natively, because the real source
of truth is `chezmoi source-path` rather than a sibling `~/src` clone.

Linux package data is split into:

- `apt_core_common`
  - core command-line packages shared across machines
- `apt_gui_common`
  - desktop-neutral GUI packages shared across machines
- `external_deb_common`
  - official Debian packages fetched directly from an upstream download endpoint
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
- directly-installed external Debian packages
- role packages for the current host
- desktop-family packages for `{{ .chezmoi.hostname }}`
- host-specific extra packages

That keeps host blocks small and avoids duplicating shared package intent
across multiple machines.

Third-party GUI packages are split deliberately:

- `brave-browser`, `code`, and `signal-desktop`
  - installed through apt after `chezmoi` configures their upstream apt sources
- `discord`
  - installed from the vendor `.deb` download instead of pretending it is part
    of the normal Debian apt surface

`chezmoi` itself is not part of the apt package model here. It is expected to
arrive through the bootstrap path first, and the package-install phase then
converges the rest of the workstation package set.

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

That `--host` mode only swaps the **modeled overlay**. It still compares
against the packages and extensions installed on the machine where you run the
script. It is useful for previewing or reviewing another host contract, but it
is not proof of what is actually installed on that other host.

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
.chezmoidata/repos.yaml
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
run_onchange_before_20-configure-third-party-apt-sources.sh.tmpl
run_onchange_after_20-install-packages.sh.tmpl
run_onchange_after_21-install-discord.sh.tmpl
run_onchange_after_25-install-vscode-extensions.sh.tmpl
run_onchange_after_26-install-npm-global-tools.sh.tmpl
run_onchange_after_27-enable-ssh-agent.sh.tmpl
run_onchange_after_28-sync-user-repos.sh.tmpl
run_onchange_after_30-load-gnome-dconf.sh.tmpl
dot_local/bin/executable_refresh-workstation-secrets.tmpl
dot_local/bin/executable_sync-user-repos.tmpl
gnome/dconf/
  desktop-session.ini
  shell.ini
  power.ini
```
