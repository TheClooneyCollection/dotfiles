# The status-bar chip stays global

**Decision.** The chip keeps showing sub agents from every window; it isn't scoped to the current window like the agent list.

**Why.** The chip is one value (`@chip`) that a single background process pushes to every client at up to 10 frames a second, while "this window" differs per client. Scoping it would mean one chip per client and window, at real cost. A global chip is also how the user learns that an agent elsewhere needs them. Revisit if it gets noisy.
