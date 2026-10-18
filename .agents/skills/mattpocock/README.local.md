# Matt Pocock's skills

Vendored from https://github.com/mattpocock/skills (MIT; see LICENSE).
Upstream directories are preserved under `skills/<category>/<name>`.
Skill contents and category READMEs are unmodified; `upstream.json` records
per-skill revisions and file hashes. This file and the manifest are local metadata.

The three clients link individual skill directories here. Invocation names stay
unchanged, including upstream model-invocation policy in `agents/openai.yaml`.
Our maintenance skill lives alongside this collection at
`../maintain-mattpocock-skills/`, and its script is `.bin/mattpocock-skills`.

From the dotfiles root:

```sh
.bin/mattpocock-skills                 # read-only check of installed skills
.bin/mattpocock-skills list            # all available upstream skills
.bin/mattpocock-skills diff            # local vs upstream patches
.bin/mattpocock-skills update skills/productivity/grilling --ref COMMIT
.bin/mattpocock-skills import skills/engineering/SKILL-NAME --ref COMMIT
```

Checks fetch upstream on demand; nothing is scheduled. Check/diff exit codes:
0 = unchanged, 1 = differences, 2 = error. Import/update are explicit, reject
local edits and link collisions, and never commit or push. Missing client links
are recreated on update. New upstream skills are listed, not silently imported.
After importing more skills, allow their three client links in `.gitignore`.
