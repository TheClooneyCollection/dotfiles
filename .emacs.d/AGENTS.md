# AGENTS.md

Notes for AI agents working in this Emacs config.

## Adding a package

Two places must stay in sync:

1. `lisp/bootstrap.el` — add the package symbol to `bootstrap-packages`. This drives the visible first-boot install UI and batches `package-refresh-contents` into a single call.
2. The relevant module under `lisp/` (e.g. `languages.el`, `completion.el`) — add the `use-package` form.

`use-package-always-ensure` is on, so step 2 alone would technically install the package on demand. We still list it in `bootstrap.el` so a fresh clone gets a clean, ordered, progress-tracked first boot instead of silent ad-hoc installs.

For packages that are no longer on MELPA, use `:vc` on the `use-package` form (Emacs 30+) and skip the `bootstrap-packages` entry — bootstrap only handles archive installs.

## Layout

- `init.el` — entry point. Loads modules in responsibility order.
- `lisp/bootstrap.el` — first-boot package install UI.
- `lisp/funcs.el` — interactive helpers used by keybindings. Anything `keys.el` calls lives here.
- `lisp/{core,ui,theme,modeline,completion,docs,languages,evil-setup,git-setup,keys}.el` — feature modules.
- `lisp/keys.el` — leader-map only. No `defun`s. If you reach for one, put it in `funcs.el` and `(require 'funcs)`.
- `custom.el` — Customize output, gitignored.

## Recreating Spacemacs commands

When porting a Spacemacs binding (e.g. `SPC *`, `SPC s p`, `SPC f f`), **always check the Spacemacs source first** instead of guessing or inventing a replacement:

- The reference checkout lives at `~/.emacs.d.spacemacs-2026-05-22/`.
- `grep -rn '"<key>"' ~/.emacs.d.spacemacs-2026-05-22/layers/` to find the leader binding.
- Follow the symbol it maps to into `~/.emacs.d.spacemacs-2026-05-22/layers/.../funcs.el` and read the actual implementation, including the variables it dynamically lets (e.g. `helm-ag-insert-at-point`, `helm-ag-base-command`).
- Prefer using the **same upstream package** Spacemacs uses (e.g. `helm-ag` for `SPC *`). If it's been pulled from MELPA, install it from a still-hosted source with `use-package :vc` (e.g. `helm-ag` lives at `github.com/emacsattic/helm-ag`). Do not substitute a sibling package (`helm-grep-ag`, `consult-ripgrep`) and try to make it look the same — the behavior will diverge in ways the screenshots will catch.
- Port small, then diff against the Spacemacs UX (results layout, modeline, no-result behavior). If they differ, you're using the wrong package or missing a `let`-binding.

## TDD with Emacs

Use ERT (built in). Workflow:

1. Put tests under `test/` next to `lisp/` (e.g. `test/funcs-test.el`).
2. Each file `(require 'ert)` and the module under test, then `(ert-deftest my-name () ...)`.
3. Run from the project root in batch mode:

   ```sh
   emacs -Q --batch \
     -L lisp -L test \
     -l ert \
     -l test/funcs-test.el \
     -f ert-run-tests-batch-and-exit
   ```

   Exit status is non-zero on any failure, so this drops into CI/precommit cleanly. `-Q` skips your init, which is what you want — tests should not depend on the running config.

4. Iterate inside Emacs with `M-x ert RET t RET` (run all) or `M-x ert-run-tests-interactively`. Re-eval the `defun` and the `ert-deftest`, then re-run; no restart needed.

5. For code that touches helm/consult/minibuffer UI, prefer extracting the pure logic into a helper and unit-testing that. Driving the minibuffer from ERT is possible (`ert-simulate-keys`, `execute-kbd-macro`) but brittle — keep the I/O at the edges.

Red → green → refactor as usual. If a bug reaches the user, write the failing ERT test first, then fix.
