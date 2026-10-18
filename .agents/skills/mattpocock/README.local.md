# Matt Pocock's skills

Vendored from https://github.com/mattpocock/skills (MIT; see LICENSE).
Upstream directories are preserved under `skills/<category>/<name>`.
Skill contents and category READMEs are unmodified; `upstream.json` records
per-skill revisions and file hashes. This file, `upstream.json` and `installations.json` are local metadata.

The three clients link individual skill directories here. Invocation names stay
unchanged, including upstream model-invocation policy in `agents/openai.yaml`.
Our maintenance skill lives alongside this collection at
`../maintain-mattpocock-skills/`, and its script is `.bin/mattpocock-skills`.

From the dotfiles root:

```sh
.bin/mattpocock-skills                 # read-only check of installed skills
.bin/mattpocock-skills list            # all available upstream skills
.bin/mattpocock-skills installed       # offline per-agent installation manifest
.bin/mattpocock-skills diff            # local vs upstream patches
.bin/mattpocock-skills update skills/productivity/grilling --ref COMMIT
.bin/mattpocock-skills import skills/engineering/SKILL-NAME --ref COMMIT
```

Checks fetch upstream on demand; nothing is scheduled. Check/diff exit codes:
0 = unchanged, 1 = differences, 2 = error. Import/update are explicit, reject
local edits and link collisions, and never commit or push. Missing client links
are recreated on update. New upstream skills are listed, not silently imported.
After importing more skills, allow their three client links in `.gitignore`.

`installations.json` records this collection's skill names, link paths, source
paths and relative symlink targets for codex, codex-2nd and claude, including our
local maintenance skill. Import/update refresh it; check/diff detect drift.
For cleanup, verify each recorded link still points at its recorded source,
then unlink only the selected client's entries. Shared sources remain available
to the other agents. The inventory is not a live filesystem report. Import/update
currently targets all three agents and recreates removed upstream links.
