# Alan Chezmoi

Minimal public-safe chezmoi starting point.

This repo is intentionally small. It should not encode workstation package
sets, secret-refresh policy, LastPass helpers, repo sync, editor convergence,
desktop settings, app launch policy, or host-specific assumptions until those
choices are reintroduced deliberately.

## Fresh Omarchy Bootstrap

On a fresh `wsub-mbp01` Omarchy install:

```bash
sudo hostnamectl hostname wsub-mbp01
sudo pacman -Syu --needed curl git ca-certificates
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
chezmoi init --apply https://github.com/astrawinski/alan-chezmoi.git
```

This first apply should only install the tiny defaults that are intentionally
managed now. Omarchy's shell setup, secrets, LastPass, package sets, repo sync,
editor setup, desktop config, and app launch policy are intentionally manual
until they are redesigned.

## Rebuild Rule

Add one behavior at a time. Before adding automation, write down:

- the exact manual command that worked
- whether it is OS-specific
- whether it depends on secrets
- whether it should run on every host or only one host
