# AGENTS.md and CLAUDE.md

An AGENTS.md holds what an agent needs before working here and cannot read from the code:

- the project's purpose and current direction, in a few lines
- how work is done: tests, commits, branches, releases
- rules and constraints, with the reason when it is not obvious
- mistakes an agent made once and would make again, written where the next one will meet them
- where current state lives (status docs, logs), not the state itself

How to write it:

- **Group rules by task.** Put a new rule under the heading of the task it applies to (Testing, Commits, Releases), one or two lines each. Update a rule in place rather than adding a second one.
- **Pick the layer:** habits for every project go in each agent's global instructions file, repo rules in the repo's AGENTS.md, rules for one directory in an AGENTS.md inside it.
- **A pointer says when to read:** "Read docs/x.md before changing Y", not a bare link.
