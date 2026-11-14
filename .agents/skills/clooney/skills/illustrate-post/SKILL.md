---
name: illustrate-post
description: Illustrate a blog post or doc with image variants from several models, shown side by side in one HTML gallery for the user to pick from. Use when the user asks for images, illustrations, diagrams or a hero image for a post or doc, or wants image options to choose from.
---

Several producers each make a **variant** of every **concept** (one image slot in the post); the user picks per concept from one gallery, mixing producers and styles freely. Nothing enters the repo until they pick.

1. **Plan.** Read the post and propose the concepts: what each image shows, where it goes, and whether it is a diagram (exact labels, numbers, real data) or a mood or hero image, and whether it carries text. Name who makes what. Done: the user approved the list; nothing is generated before that.
2. **Produce, in parallel,** into a gitignored folder: `.temp/<topic>-images/<variant>/NN-<concept>.<ext>`. Check `.gitignore` covers it.
   - **Diagrams: hand-drawn SVG by Claude.** Self-contained, with its own background card, plus `<title>` and `<desc>`. Make a dark twin, `NN-<concept>-dark.svg`: remap the palette, keep the meaning of each colour readable. Render both to PNG (`rsvg-convert`), look at them, fix overlaps and clipped text, repeat. CSS `text { fill }` beats a `fill=` attribute, so colour single elements with `style="fill:..."`.
   - **Every concept: an image model** (Codex's image tool, or another agent's; without one, hand this to an agent that has it). Ask for 3 or 4 clearly different style families, each applied to every concept so a family is a coherent set; leave the rest of the art direction open. Save each family's prompts in `<variant>/prompts.json`.
   - Generated images: no logos or trademarks, generic devices, no personal details. Text follows the plan, concept by concept. Models garble it, so ask for short, explicit wording, verify every word and number, and regenerate anything garbled.

   Done: every producer delivered its files.
3. **Gallery.** Copy [gallery.html](gallery.html) into the folder and fill its `concepts` and `variants` lists. Serve it with `python3 -m http.server <spare port> --bind 127.0.0.1`. To browse from another device, offer the user's private network (e.g. `tailscale serve`) and ask first. Done: the URL loads and every image shows.
4. **Review and pick.** Each producer lists its own weak spots. Send the user the gallery link with those notes. When they like an image's composition but want a change, edit that image (an image edit with it as the reference) rather than generating a new one. Done: the user picked one image per concept.
5. **Land the picks.** Copy only the chosen images into the repo (check whether it keeps images in Git LFS) and wire them into the post:
   - Show images narrower than the text column and centred, around 560px, a hero around 640px. A hero can close the post too.
   - An SVG with a dark twin goes in as two `<img>`, one per theme, swapped by one shared CSS rule keyed on the site's theme selector or `prefers-color-scheme`.
   - Image pipelines may rasterise SVGs (JPEG with black corners); route SVGs around the transform.

   Build, then look at the post in both themes and commit. Ask before pushing. Done: the build passes, both themes look right, and only the picks are committed.
