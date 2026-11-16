---
name: design-lab
description: Run a private design lab for a project, with throwaway mockups and image rounds on one phone-friendly index the user reviews on their phone or the same machine, ending in a decision recorded in the plan. Use when the user wants to explore visual directions, themes, mockups, covers or image options before building, asks for a lab, a gallery, a revision round or a finalists view, or says 设计实验室 / 出几版看看.
---

# Design lab

The lab answers "which direction?" before any real code. Its output is a decision written in the plan doc, never production code. Everything in it is throwaway.

## Rules

- **Private and uncommitted.** The lab lives in a gitignored, build-ignored drafts folder (e.g. `local-drafts/lab/`). Check both ignores before the first file. Nothing in it reaches git, a build, a push or a message to another project.
- **Serve only what is visual.** The served root holds the index plus symlinks to mockup and image folders; never drafts, notes, `.temp`, `.env` or secrets. Bind to 127.0.0.1 with caching off. If a tailnet is available, use `tailscale serve` for phone review; otherwise review on the same machine at 127.0.0.1. Never bind to 0.0.0.0 or substitute a public tunnel.
- **Never overwrite a reviewed version.** A revision is a new folder next to the old one (`x-r2`, `x-r3`, `paper-contrast-a/b/c`, `dark-aurora`, `dark-indigo`). The user compares against what they saw.
- **Phone first.** Check every page at 390px: one column, no horizontal scroll. Every mockup in light and dark unless it is declared single-scheme. Record body and label contrast ratios (aim for 7:1 body text) in each round's notes.
- **Verdicts are the user's words.** Badges: Loved, Approved, To review, To pick, Not picked, Dropped, On hold. Never mark anything approved, picked or dropped unless the user said so; quote them in the note. If a verdict is ambiguous ("aurora indigo": one palette or two?), confirm before recording it.
- **Image rounds.** Unless the user gives an art direction, let the model choose and vary styles. Save every prompt in `prompts.json`. No text, logos, trademarks or personal details in images. Note the target crop ratio (e.g. 100:56) and check each image in that crop. Record each rejected round with the user's reason ("too close to X's style") so the next round avoids it.
- **In an agent chain:** the main relays verdicts as notices and revision asks as requests; answer each revision round with one batched reply holding all links.

## Ops

1. **Start the lab.** Run [scripts/serve-lab.py](scripts/serve-lab.py) `<lab dir> [port]` in the background. With a tailnet, optionally run `tailscale serve --bg --https=<port> <port>` for phone review; otherwise use `http://127.0.0.1:<port>` on the same machine. Done: the tailnet URL loads the index on the phone, or the loopback URL loads it locally; in either case, a reload after an edit shows the edit.
2. **Create the index once.** Copy [references/lab-index-example.html](references/lab-index-example.html) to `<lab dir>/index.html` and replace its sample rows. One row per experiment of any kind (mockups, image rounds, covers): title, date, status, note with verdicts, thumbnail. Done: every experiment the user has seen is a row.
3. **Add an experiment or round.** Build it in its own folder, symlink it into the lab root, add or update its row. Done: the row links to it, its thumbnail loads, and it passes the phone and light/dark checks.
4. **Build a gallery** for a round with several items, following [references/gallery.md](references/gallery.md). Done: it opens with "To pick / review", every item shows what changed since the user's last review and a stable ID with Copy ID, the round landing page lists every item with its ID, and links work.
5. **Record each verdict** in the gallery badge, the index row and the plan doc in the same step. Done: the three agree.
6. **Finalists view** once most items have verdicts: only final picks, no before or unpicked versions, plus a compare mode (same page across all finalists, light/dark, desktop/phone) for choosing a default. Done: linked from the gallery top and the index.
7. **Close out.** Write the decisions in the plan doc, mark everything else Not picked or On hold with the reason, and hand the agreed plan to implementation. Done: no row is left "waiting" without saying what it waits for.

## Failure modes seen

- **Stale cache hid new rows.** The fix is the no-store server; never serve the lab with a caching server.
- **The index showed only one kind of experiment.** Image rounds and mockups both need rows; nothing reviewed may exist only in chat.
- **A "kept" verdict assumed from silence.** Without the user's words it stays To review.
- **Copying instead of taking inspiration.** When the user points at a reference style, ask what to keep from it; a round that copies the reference gets rejected.
- **Agents left to decide the art direction** produced rounds nobody picked. After two unpicked rounds, stop and ask the user for direction instead of generating more.
