# {{PROJECT_NAME}} agent workflow

{{DESCRIPTION}}

- Work from the repository root with relative paths. Run `git` directly, never through `git -C` or after a `cd` elsewhere.
- `README.md` is for people: what the project is, why, its status, how to try it and how to contribute. Technical detail goes in `docs/`, one topic per file under the matching folder (`docs/technical/`, `docs/development/`, `docs/product/`, `docs/research/` for research records, `docs/decisions/` for decisions, see [Decisions](#decisions)), with a one-line entry in that folder's `README.md`, which is its index. A new folder gets its own `README.md` and a line in [docs/README.md](docs/README.md). Name each file after its topic (`docs/technical/save-format.md`) so it can be found by name or search.
- Keep docs concise and practical. Open each doc with a short summary. When agents are likely to repeat a mistake, add a short note in the doc they will read for that task.
- Record every idea the user raises in [docs/product/ideas.md](docs/product/ideas.md), with its status and outcome.
- Track source and docs only: build output, generated files, screenshots and secrets stay out of Git.
- Run tests in the background, without opening windows or taking focus. Tests advance an injected clock instead of waiting on wall time, and wait for conditions with a generous deadline.

## Decisions

Standing decisions, which apply to every task:

- None yet.

Area decisions are indexed by area in [docs/decisions/README.md](docs/decisions/README.md): before working in an area, read its entries there. The areas:

- None yet.

Areas grow with the project. Record a new decision as its own file there; when no area fits, add one here as `` `area`: what it covers ``. A standing decision also gets a line in this section.

## Git

- Conventional commits: `feat(scope): ...`, `fix(scope): ...`, `docs`, `chore`, `test`, `refactor`. Imperative subject, lower case after the colon.
- Keep `main` linear. Work on a branch, rebase it onto `main`, and land it with `git merge --ff-only`.
- Push only when the user asks. After a significant change or several commits since the last push, ask the user whether to push.

## Versioning

{{VERSIONING}}

{{CHANGELOG}}
