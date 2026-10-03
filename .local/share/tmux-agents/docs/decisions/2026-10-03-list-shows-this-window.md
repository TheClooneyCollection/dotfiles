# The agent list shows this window's sub agents

**Context.** With several projects open, `prefix + a` listed every sub agent from every window, so the ones for the work in front of the user were hard to find.

**Decision.** The list opens on the sub agents that belong to the window it was opened from: an agent belongs to a window if its own pane, or the pane of any agent up its parent chain, is in that window. So a split sub agent in this window counts, and so do hidden sub agents spawned by agents here, and their sub agents. `ctrl-t` switches between "this window" and "all windows"; the prompt says which. It always opens on "this window" (not remembered), and coming back from an agent's popup keeps the view it came from. `ctrl-a` still switches between sub agents and every named pane, within the current scope. The closed section follows the scope too: in "this window" it lists closed sub agents whose recorded parent is an agent of this window.

**Why.** The list is mostly used to check on the work in front of the user; everything else is one key away.
