# Emacs Config

This is a lightweight Emacs config built to keep the parts of the Spacemacs UX
that mattered most while dropping the framework weight.

## Philosophy

The guiding idea is:

- keep `init.el` as the real entry point
- keep startup explicit and understandable
- keep the package set small
- preserve the useful interaction model from Spacemacs
- avoid turning the config back into a distribution

Concretely, that means:

- modal editing with `evil`
- a Space leader key with `which-key`
- Magit as the main Git interface
- a small set of hand-written modules under `lisp/`
- no Spacemacs layers, no large framework machinery, no hidden abstraction

This config is trying to feel like a personal editor again, not an operating
system.

## High-Level Features

Implemented so far:

- `evil` + `evil-collection`
- Spacemacs-style leader keys via `general`
- `which-key` leader menus
- `magit`
- `vertico`, `orderless`, `marginalia`, `consult`
- `helm`, `helm-flx`, `helm-ls-git` for the older file-picking workflow
- vendored `spacemacs-dark` theme loaded as early as possible
- a lightweight custom mode line
- a dedicated first-boot package install screen
- an alternate launcher for the archived Spacemacs setup

Examples of preserved muscle memory:

- `SPC SPC` for `M-x`
- `SPC f f` for tracked Git files
- `SPC f F` for general file finding
- `SPC f s` save
- `SPC f e d` open `init.el`
- `SPC f e r` reload config
- `SPC g g` Magit
- `SPC q q` quit Emacs
- `SPC 0` delete other windows
- `SPC 1` delete current window
- `SPC 9` zen

## Folder Structure

```text
~/.emacs.d/
├── early-init.el          # Early startup plumbing, startup silence, early theme load.
├── init.el                # Main entry point and module loader.
├── custom.el              # Customize output only.
├── README.md              # This document.
└── lisp/
    ├── bootstrap.el       # First-boot package installation UI and logic.
    ├── completion.el      # Helm plus minibuffer completion/search tools.
    ├── core.el            # Editor defaults and persistence behavior.
    ├── evil-setup.el      # Evil modal editing and Ex behavior.
    ├── git-setup.el       # Magit behavior and Git entrypoints.
    ├── keys.el            # Leader keys and custom editor commands.
    ├── modeline.el        # Custom mode line faces and layout.
    ├── theme.el           # Theme module entry point; early load happens in early-init.el.
    ├── ui.el              # Generic UI behavior like line numbers and parens.
    └── vendor/
        └── spacemacs-theme/  # Vendored Spacemacs theme files.
```

## Early Theming

One of the main startup UX problems with a package-installed theme is a flash of
unstyled Emacs before the theme becomes available.

Spacemacs avoids much of this by owning more of startup:

- it vendors the theme
- it sets theme-related load paths early
- it controls startup UI closely

This config borrows that idea in a smaller form:

1. The Spacemacs theme files are vendored under:
   - `lisp/vendor/spacemacs-theme/`

2. `early-init.el` adds that directory to:
   - `load-path`
   - `custom-theme-load-path`

3. `early-init.el` calls:
   - `(load-theme 'spacemacs-dark t)`

That means the first frame and the bootstrap installer can appear with the
theme already active instead of flashing the default Emacs colors first.

The vendored theme was synced against the locally installed ELPA copy so we are
not intentionally carrying an older variant.

## Bootstrap Flow

The first-boot installer is intentionally visible.

If required packages are missing:

- package archives are refreshed
- a full-screen `*bootstrap*` buffer appears
- package progress is shown explicitly
- newly installed packages are activated immediately

This borrows the idea of the Spacemacs startup/install buffer without importing
the full Spacemacs startup framework.

## File Finding

There are two file-finding paths on purpose:

- `SPC f f`
  - tracked Git files only
  - implemented with `helm-ls-git`
  - tuned to behave like the old compact repo-file picker

- `SPC f F`
  - general file finding
  - implemented with `helm-find-files`

The config also keeps the newer minibuffer stack:

- `vertico`
- `orderless`
- `marginalia`
- `consult`

So the config intentionally uses both Helm and modern minibuffer tools, because
they serve different parts of the old workflow well.

## Archived Spacemacs Setup

The older Spacemacs setup still exists for reference:

- distribution checkout:
  - `~/.emacs.d.spacemacs-2026-05-22`
- archived user config:
  - `~/.archive/.spacemacs.d`

There is also a launcher script:

- `~/.bin/spacemacs`

That launcher uses Emacs `--init-directory` support so Spacemacs can still be
run without replacing the current lightweight config.

## Reloading

Useful commands:

- `SPC f e d` open `init.el`
- `SPC f e r` reload config

Reloading is good for most Lisp/config changes, but a full Emacs restart is
still safer after startup-path changes, package bootstrap changes, or theme
loading changes.

## Maintenance Notes

- Keep `init.el` short and readable.
- Prefer putting new behavior into a focused module under `lisp/`.
- Keep generated/editor-local state out of version control.
- When borrowing from old Spacemacs behavior, port the idea, not the framework.
- If a new package adds significant complexity, justify it against the original
  goal of staying lightweight.
