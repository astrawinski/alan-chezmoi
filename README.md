# Alan Chezmoi

This is Alan's personal `chezmoi` source. Its job is to bring a fresh
workstation under user-state management without replacing the base operating
system's normal desktop experience.

The repo is deliberately small while the rebuild path is being rediscovered.
Add durable behavior here only after the manual step has been proven on the
target machine.

## Fresh Workstation Bootstrap

Complete the base operating system install normally. The hostname should be set
during install, so do not reset it with `hostnamectl` unless the install was
completed with the wrong name.

Install `chezmoi` from the operating system's package repository, then apply
this source:

```bash
chezmoi init --apply https://github.com/astrawinski/alan-chezmoi.git
```
## First-Apply Flow

The first apply establishes the workstation baseline that is safe to manage
right now:

- basic Git identity through `~/.gitconfig`
- a local `~/README.md`
- enabled `sshd.service`
- TCP/22 allowed through UFW
- WSUB internal root CA trust
- Codex launcher
- Cavekit Codex adapter skills
- LastPass CLI
- management CLI tools: Ansible, SOPS, and Terraform
- official Microsoft Visual Studio Code from the AUR
- Flatpak and Flathub
- Zen Browser from Flathub
- Zen as the default browser
- application launcher refresh hooks

On `MacBookPro8,2` hardware, it also applies the hardware-specific desktop
workarounds needed for that laptop:

- Hyprland monitor configuration for the internal panel
- Xwayland launch wrappers for affected Chromium/Electron apps
- VS Code launchers disable GPU compositing to avoid flicker on the legacy AMD
  graphics path

Shell startup files are intentionally unmanaged. Keep the base system defaults
in place until there is a proven reason to replace them.

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
the estate. First refresh the repo-managed WSUB SSH config and known-hosts
state from the current WSUB inventory:

```bash
cd ~/src/wsub
scripts/recovery/host-ssh-install.sh --refresh-known-hosts
```

Then run the workstation-only validation:

```bash
scripts/platform/management-workstation-validate.sh --skip-estate-lightweight
```

That proves the workstation can project secrets, use the shared MinIO
Terraform state backend, produce no-change Terraform plans, and reach the PBS
hosts with the repo-managed SSH trust model.

After that passes, run the full management validation:

```bash
./scripts/platform/management-workstation-validate.sh
```

Failures from either validation path are the next bootstrap gaps. Fix them
manually first, then promote the durable part of the fix into this repo.

## Change Policy

Promote behavior into this source one piece at a time. Before adding
automation, capture:

- the exact manual command or file change that worked
- whether it is operating-system-specific
- whether it depends on secrets or login state
- whether it applies globally, to one host, or to one hardware model
