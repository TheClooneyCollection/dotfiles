---
name: logo
description: Design a project logo with an image model and put it in the README. Use when the user asks for a logo, icon or wordmark.
---

Propose directions and generate concepts as you normally would; the user picks.

- **Generate images with Codex.** Its built-in image generator is the one to use. If you are not Codex, hand the generation and edits to a Codex agent.

- **Lock a master before the family.** Variants generated separately drift apart. Once the user picks an image, derive the icon, wordmark and monochrome from that exact image by editing it (recolour, add text), not by generating new ones.
- **Both themes.** A README logo needs a transparent light and dark version switched with `<picture>`. Show both on light and dark backgrounds before shipping; image models leave speckled alpha edges and broken thin text.
- **README header:** wrap the `<picture>` in `<h1 align="center">` with the project name as `alt`, so there is a real heading without the name showing twice.
- **Commit only the logo files and the README header,** staged by path and committed in the same command.
