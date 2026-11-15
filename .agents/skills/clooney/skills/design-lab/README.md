# design-lab

Explore visual directions in a private design lab: mockups, image rounds and a phone-friendly index, ending with a decision in the project plan.

**Why:** With how easy it is to try things with AI agents, I like to experiment with designs. This puts everything together in one place that I can open from my phone: every round, every verdict and the before versions, so I can compare, pick and come back later without anything getting lost in chat.

**Use it:** before implementation, when comparing visual directions, reviewing a revision round or choosing finalists.

**Needs:** Python 3 and headless Chrome for screenshots. Tailscale is optional for phone review; without it, review on the same machine at 127.0.0.1.

## Files

- [SKILL.md](SKILL.md): lab workflow and review rules.
- [references/gallery.md](references/gallery.md): round galleries and screenshot conventions.
- [references/lab-index-example.html](references/lab-index-example.html): a sample index to copy and customise.
- [scripts/serve-lab.py](scripts/serve-lab.py): a loopback-only server with caching disabled; run with `python3`.
