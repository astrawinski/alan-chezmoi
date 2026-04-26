# Alan Chezmoi

This is Alan's personal `chezmoi` source. It is the canonical operator note for
bringing a fresh workstation under user-state management.

The repo is intentionally minimal right now. A first apply should preserve the
fresh Omarchy environment and only add state that is deliberately managed here.
Package sets, secrets, LastPass helpers, repo sync, editor setup, desktop
settings, shell config, and app launch policy will be added back only after
they are worked out manually on the target machine.

## Fresh Omarchy Bootstrap

On a fresh `wsub-mbp01` Omarchy install:

1. Complete the Omarchy installer normally.
2. Install `chezmoi` from the Omarchy/Arch package repository.
3. Apply this source:

```bash
chezmoi init --apply https://github.com/astrawinski/alan-chezmoi.git
```

The hostname is chosen during the Omarchy install. Do not reset it during the
chezmoi bootstrap unless the install was completed with the wrong hostname.

## Current Managed Surface

This source currently manages:

- `~/.gitconfig`
- `~/README.md`

It intentionally does not manage shell startup files yet. Omarchy's defaults
should remain intact while the workstation rebuild path is being rethought.

## Rebuild Rule

Promote behavior into this repo one piece at a time. Before adding automation,
capture:

- the exact manual command or file change that worked
- whether it is Omarchy/Arch-specific
- whether it depends on secrets or login state
- whether it should apply to every workstation or only one host
