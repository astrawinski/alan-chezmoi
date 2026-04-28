# Alan Chezmoi

This is Alan's personal `chezmoi` source. Its job is to bring a fresh
workstation under user-state management without replacing the base operating
system's normal desktop experience.

The current target is a fresh Omarchy workstation. The repo is deliberately
small while the rebuild path is being rediscovered. Add durable behavior here
only after the manual step has been proven on the target machine.

## Fresh Omarchy Bootstrap

Complete the Omarchy installer normally. The hostname is set during install, so
do not reset it with `hostnamectl` unless the install was completed with the
wrong name.

Install `chezmoi` from the Omarchy/Arch package repository, then apply this
source:

```bash
chezmoi init --apply https://github.com/astrawinski/alan-chezmoi.git
```

After a rebuild, other machines may still have the old SSH host key cached for
the workstation. Refresh that cache before connecting:

```bash
ssh-refresh-host wsub-mbp01
```

## First-Apply Flow

The first apply establishes the workstation baseline that is safe to manage
right now:

- basic Git identity through `~/.gitconfig`
- a local `~/README.md`
- enabled `sshd.service`
- TCP/22 allowed through UFW
- Codex launcher
- LastPass CLI
- management CLI tools: Ansible, SOPS, and Terraform
- Flatpak and Flathub
- Zen Browser from Flathub
- Zen as the default browser
- Omarchy launcher refresh hooks

On `MacBookPro8,2` hardware, it also applies the hardware-specific desktop
workarounds needed for that laptop:

- Hyprland monitor configuration for the internal panel
- Xwayland launch wrappers for affected Chromium/Electron apps

Shell startup files are intentionally unmanaged. Keep Omarchy's defaults in
place until there is a proven reason to replace them.

## Secrets And Repos

LastPass authentication is manual:

```bash
lpass login
```

After LastPass is authenticated, refresh workstation secrets:

```bash
refresh-workstation-secrets
```

That restores the GitHub SSH key and SOPS age key from LastPass, then runs
`sync-user-repos`. The repo sync creates `~/src`, then clones or fast-forward
pulls the management repo set:

- `wsub`
- `alan-chezmoi`
- `terraform-provider-unifi`
- `cavekit`
- `cavekit-codex`

Repo sync is also attempted during `chezmoi apply` if the GitHub SSH key is
already present. Existing non-git directories, repos with unexpected origins,
and repos with local changes are left alone.

GitHub CLI authentication is also manual:

```bash
gh auth login
```

Use GitHub.com, SSH for Git operations, skip uploading the restored SSH key,
and authenticate `gh` with the browser flow. The restored SSH key handles Git
transport; `gh` still needs its own API token.

## Management Validation

After `~/src/wsub` exists, validate that the workstation is ready to operate
the estate:

```bash
cd ~/src/wsub
./scripts/platform/management-workstation-validate.sh
```

Failures from that script are the next bootstrap gaps. Fix them manually first,
then promote the durable part of the fix into this repo.

## Change Policy

Promote behavior into this source one piece at a time. Before adding
automation, capture:

- the exact manual command or file change that worked
- whether it is Omarchy/Arch-specific
- whether it depends on secrets or login state
- whether it applies globally, to one host, or to one hardware model
