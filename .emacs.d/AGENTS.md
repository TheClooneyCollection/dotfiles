# AGENTS.md

Notes for AI agents working in this Emacs config.

## Adding a package

Two places must stay in sync:

1. `lisp/bootstrap.el` — add the package symbol to `bootstrap-packages`. This drives the visible first-boot install UI and batches `package-refresh-contents` into a single call.
2. The relevant module under `lisp/` (e.g. `languages.el`, `completion.el`) — add the `use-package` form.

`use-package-always-ensure` is on, so step 2 alone would technically install the package on demand. We still list it in `bootstrap.el` so a fresh clone gets a clean, ordered, progress-tracked first boot instead of silent ad-hoc installs.

## Layout

- `init.el` — entry point. Loads modules in responsibility order.
- `lisp/bootstrap.el` — first-boot package install UI.
- `lisp/{core,ui,theme,modeline,completion,docs,languages,evil-setup,git-setup,keys}.el` — feature modules.
- `custom.el` — Customize output, gitignored.
