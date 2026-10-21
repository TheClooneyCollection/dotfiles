# Matt Pocock's skills

Vendored from https://github.com/mattpocock/skills (MIT; see LICENSE).
Upstream directories are preserved under `skills/<category>/<name>`.
Skill contents and invocation metadata are unmodified. This file is local metadata.

Managed as the `mattpocock` source by `.bin/skill-manager`. Source configuration,
pinned commits, file hashes and per-agent installation choices live in
`.config/skill-manager/`; see its README for usage and cleanup. Client links point
at individual skill directories here. Default first imports install to Claude,
Codex and codex-2nd; explicit selections persist through updates.

```sh
.bin/skill-manager check --source mattpocock
.bin/skill-manager installed --source mattpocock
.bin/skill-manager diff --source mattpocock
```

The old `.bin/mattpocock-skills` command forwards to this manager. The generic
maintenance skill is `.agents/skills/local/maintain-skills/SKILL.md`.
