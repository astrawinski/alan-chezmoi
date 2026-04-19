# Alan User-State Bootstrap Seed

This directory is the checked-in bootstrap seed for Alan's roaming user state.

It is intentionally shaped like a `chezmoi` source tree so WSUB can seed a new
local user-state checkout before a separately owned external user-state repo is
available.

It is not intended to remain Alan's durable source of truth once that external
repo exists. WSUB should eventually copy this tree only as an initial seed and
then follow the external `workstation_user_state_origin_url`.

Current first-slice ownership:

- shell dotfiles
- Git config
- VS Code user settings
- browser default MIME state
- GitHub auth file paths
- Codex auth file path
- `.api_keys`
- bounded GNOME dconf subtree files
- Syncthing and portable-backup intent
- developer `wsub` checkout intent
- manual follow-up and secret-backed-state annotations

Later slices:

- browser/session auth and broader personal secret decisions

Current GNOME roaming state scope:

- `gnome/dconf/desktop-session.ini`
- `gnome/dconf/shell.ini`
- `gnome/dconf/power.ini`
- bounded exported `dconf` subtree content, not raw `~/.config/dconf/user`

Current Linux package manifest scope:

- `packages/packages.yaml`
- `desktop.enabled` and `desktop.family` for bounded Linux desktop intent
- `apt_packages` for narrow extra apt package names
- `package_classes` for clearly personal WSUB-known package classes

Current roaming portable-state intent scope:

- `intent/portable-state.yaml`
- Syncthing enablement and service enablement
- retained portable-backup enablement, default scope, and named group
  selections

Current roaming repo-checkout intent scope:

- `intent/repo-checkout.yaml`
- whether the profile-mapped user should receive a personal `~/src/wsub`
  checkout for developer work

Current roaming annotation scope:

- `notes/manual-follow-up.yaml`
- manual app follow-up notes
- secret-backed-state reminders that remain intentionally outside automated
  restore

Current supported desktop families:

- `gnome`

Current allowed package classes:

- `browser`
- `codex_cli`
- `container_runtime`
- `developer_tooling`
- `discord`
- `document_tooling`
- `remote_access`
- `signal`

Expected minimum tree shape:

```text
dot_bashrc
dot_bash_aliases
dot_profile
dot_gitconfig
dot_api_keys
dot_config/
  Code/User/settings.json
  mimeapps.list
  wsub/gh/config.yml
  wsub/gh/hosts.yml
  wsub/github-token.env
private_dot_codex/
  auth.json
intent/
  portable-state.yaml
  repo-checkout.yaml
notes/
  manual-follow-up.yaml
packages/
  packages.yaml
gnome/dconf/
  desktop-session.ini
  shell.ini
  power.ini
```
