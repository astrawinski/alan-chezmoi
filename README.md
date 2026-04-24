# Alan Chezmoi

This is Alan's real `chezmoi` source of truth for roaming user state.

It is designed to be public-safe:

- no secret values are committed
- secret-bearing files are restored from LastPass on demand
- package, editor, and repo state are converged through checked-in `chezmoi`
  data and scripts

The intended boundary is:

- WSUB owns machine bootstrap and identity
- this repo owns Alan's user environment after the machine is reachable

## Normal Flow

On a fresh Debian machine:

```bash
chezmoi init --apply https://github.com/astrawinski/alan-chezmoi.git
```

Then:

```bash
ssh-refresh-host <host>   # only if you rebuilt a known host
lpass login
refresh-workstation-secrets
```

That gives you the normal two-stage model:

1. the first `chezmoi` apply installs baseline packages, editors, and helpers
2. `refresh-workstation-secrets` restores the secret-bearing files after
   LastPass login succeeds

The first apply is expected to work before LastPass login. Secret rendering is
intentionally deferred until the explicit refresh step.

## WSUB Laptop Rebuild Flow

For WSUB-managed management workstations, this repo is only the later
user-environment half of the rebuild path.

The full flow is:

1. from a trusted management workstation with a `wsub` checkout, rebuild the
   installer media
2. boot the target laptop from that media and complete the Debian install
3. SSH into the fresh machine and run `workstation-bootstrap`
4. let `workstation-bootstrap` install `chezmoi` and run the first apply from
   this repo
5. log into LastPass
6. run `refresh-workstation-secrets`
7. rerun `chezmoi update` if the post-secret handoff tells you to

In practical terms, the operator flow after the Debian install looks like:

```bash
ssh-refresh-host <host>   # only if this is a rebuilt known machine
ssh <host>
workstation-bootstrap
lpass login
refresh-workstation-secrets
chezmoi update
```

What WSUB owns:

- installer media
- machine identity and hostname correction
- `workstation-bootstrap`
- the handoff into this repo

What this repo owns:

- user packages
- shell/editor state
- roaming secret restore
- managed `~/src` checkouts

This split is intentional. WSUB gets the machine to a usable user-owned
handoff point; `alan-chezmoi` takes over from there.

## Secret Model

Secret flow is deliberately one-way by default:

- `refresh-workstation-secrets`
  - LastPass -> local machine

For rotatable local auth state that you want to publish back into LastPass for
later restore on other machines, this repo also provides:

- `update-workstation-secrets`
  - local machine -> LastPass

That gives you a clean push/pull model:

```bash
update-workstation-secrets codex
update-workstation-secrets onedrive
update-workstation-secrets api-keys
```

Then, on another machine:

```bash
lpass login
refresh-workstation-secrets
```

`update-workstation-secrets` intentionally supports only:

- `codex`
- `onedrive`
- `api-keys`
- `all`

It does not currently rewrite GitHub PAT, SSH keys, or `age` keys.

## LastPass Items

This repo currently expects these LastPass entries under `WSUB/`:

- `secret-github-pat`
  - stored as the item password
  - restores:
    - `~/.config/wsub/github-token.env`
    - `~/.config/wsub/gh/hosts.yml`

- `secret-github-ssh`
  - note fields:
    - `privateKey:`
    - `publicKey:`
  - restores:
    - `~/.ssh/id_ed25519`
    - `~/.ssh/id_ed25519.pub`
    - `~/.ssh/config`

- `secret-sops-age`
  - note field:
    - `privateKey:`
  - restores:
    - `~/.config/sops/age/keys.txt`

- `secret-api-keys`
  - raw env-style content in the note body
  - restores:
    - `~/.api_keys`
  - optional

- `secret-codex-auth`
  - raw `~/.codex/auth.json` content in the note body
  - restores:
    - `~/.codex/auth.json`
  - optional

- `secret-onedrive-refresh-token`
  - stored as the item password
  - restores:
    - `~/.config/onedrive/refresh_token`
  - optional

## Bootstrap Behavior

The first apply installs the baseline user environment:

- packages
- VS Code extensions
- global npm tools
- `cavekit-codex` checkout plus Codex skill install via `skills add`
- user-level `ssh-agent.socket`
- helper scripts
- repo sync scaffolding

Secret-bearing files are not restored until:

```bash
lpass login
refresh-workstation-secrets
```

After secret refresh, the managed repo-sync helper is retried so private GitHub
checkouts can settle once SSH credentials exist.

For public GitHub repos, the bootstrap path is intentionally tolerant:

- try SSH clone first
- if SSH auth is not ready yet, fall back to unauthenticated HTTPS clone
- once secrets exist later, reset `origin` back to the intended SSH URL

The public bootstrap also seeds `github.com` into `~/.ssh/known_hosts` so the
first clone attempt does not stop on an SSH host-trust prompt.

## Operator Surfaces

Important day-to-day helpers:

- `ssh-refresh-host`
  - refreshes the local known-hosts entry for a rebuilt machine
  - example:
    ```bash
    ssh-refresh-host wsub-mbp01
    ```

- `refresh-workstation-secrets`
  - restores LastPass-backed secret files onto the current machine

- `update-workstation-secrets`
  - updates selected LastPass items from current local state

- `sync-user-repos`
  - repairs managed `~/src` checkouts if needed
  - normal operator flow should not need this directly

## Packages, Editors, and Repo Sync

Package and editor installation is driven by:

- `.chezmoidata/packages.yaml`
- `.chezmoidata/repos.yaml`
- `.chezmoidata/vscode.yaml`
- `run_once_before_10-install-lastpass-cli.sh.tmpl`
- `run_onchange_before_20-configure-third-party-apt-sources.sh.tmpl`
- `run_onchange_after_20-install-packages.sh.tmpl`
- `run_onchange_after_21-install-discord.sh.tmpl`
- `run_onchange_after_22-install-sops.sh.tmpl`
- `run_onchange_after_25-install-vscode-extensions.sh.tmpl`
- `run_onchange_after_26-install-npm-global-tools.sh.tmpl`
- `run_onchange_after_27-enable-ssh-agent.sh.tmpl`
- `run_onchange_after_28-sync-user-repos.sh.tmpl`
- `run_after_29-install-cavekit-codex.sh.tmpl`
- `run_onchange_after_30-load-gnome-dconf.sh.tmpl`

The Linux package model is split into:

- `apt_core_common`
- `apt_gui_common`
- `external_deb_common`
- `role_packages`
- `desktop_packages`
- `hosts`

Hosts should stay small. They describe only host-specific deltas such as:

- `desktop_family`
- `roles`
- `apt_extra`

That keeps shared intent in reusable package groups instead of repeating it
per machine.

Global npm tools live under:

- `packages.linux.npm_global_tools`

That keeps non-apt CLI tools like `codex` out of the Debian package model.

Tracked repo checkouts live under:

- `.chezmoidata/repos.yaml`

On Linux this repo converges:

- `~/src/wsub`
- `~/src/cavekit-codex`
- `~/src/terraform-provider-unifi`

`alan-chezmoi` itself is intentionally excluded from that list when using
`chezmoi` natively, because the real source of truth is `chezmoi source-path`,
not a sibling clone under `~/src`.

## Third-Party Package Notes

This repo deliberately treats some package families specially:

- `brave-browser`, `code`, and `signal-desktop`
  - installed through vendor apt sources configured by `chezmoi`

- `discord`
  - installed from the vendor `.deb`

- `sops`
  - installed through a dedicated release-binary path rather than pretending it
    is part of the normal Debian apt surface on every machine

- `lastpass-cli`
  - built locally on Debian with upstream Debian packaging metadata and
    `DEB_BUILD_OPTIONS=nocheck`

## Drift Review

To review live workstation drift before promoting it into repo truth:

```bash
./scripts/drift-inbox.sh
```

It compares the current machine against:

- modeled apt packages for the current host overlay
- modeled global npm tools in `packages.linux.npm_global_tools`
- curated VS Code extension ids in `.chezmoidata/vscode.yaml`

It reports:

- packages installed locally but not modeled
- modeled packages not installed locally
- global npm tools installed locally but not modeled
- modeled global npm tools not installed locally
- VS Code extensions installed locally but not modeled
- modeled VS Code extensions not installed locally

To preview another host overlay from the current machine:

```bash
./scripts/drift-inbox.sh --host wsub-mbp01
```

That swaps only the modeled overlay. It does not prove what is actually
installed on the other machine.

## GNOME State

Bounded GNOME state lives under:

- `gnome/dconf/desktop-session.ini`
- `gnome/dconf/shell.ini`
- `gnome/dconf/power.ini`

It is only applied when:

- the current host overlay declares `desktop_family: gnome`
- a GNOME session is active
- a usable session bus exists

## Repo Shape

Important paths:

```text
.chezmoidata/packages.yaml
.chezmoidata/repos.yaml
.chezmoidata/vscode.yaml
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
dot_local/bin/executable_refresh-workstation-secrets.tmpl
dot_local/bin/executable_update-workstation-secrets
dot_local/bin/executable_ssh-refresh-host
dot_local/bin/executable_sync-user-repos.tmpl
run_once_before_10-install-lastpass-cli.sh.tmpl
run_onchange_before_20-configure-third-party-apt-sources.sh.tmpl
run_onchange_after_20-install-packages.sh.tmpl
run_onchange_after_21-install-discord.sh.tmpl
run_onchange_after_22-install-sops.sh.tmpl
run_onchange_after_25-install-vscode-extensions.sh.tmpl
run_onchange_after_26-install-npm-global-tools.sh.tmpl
run_onchange_after_27-enable-ssh-agent.sh.tmpl
run_onchange_after_28-sync-user-repos.sh.tmpl
run_onchange_after_30-load-gnome-dconf.sh.tmpl
gnome/dconf/
  desktop-session.ini
  shell.ini
  power.ini
```
