# illustrate-post

Illustrates a blog post or doc with images from several models at once, laid out side by side in one HTML gallery so you pick instead of iterate.

**Why:** I wanted to see the best work from both Claude and an image model before picking a post's images. This has Claude draw the precise diagrams while an image model tries a few consistent styles on every image, all on one page, so I pick per image and mix freely.

**Use it:** ask for images, illustrations, diagrams or a hero image for a post or doc.

## What it does

1. Reads the post and proposes the images: what each shows, where it goes, diagram or mood. Nothing is generated until you approve.
2. Makes the variants in parallel, in a gitignored temp folder:
   - Claude draws the diagrams as SVG, where labels and numbers must be exact, with a dark twin of each, and checks every one rendered.
   - An image model makes every concept in 3 or 4 style families, each one a consistent set.
3. Builds one gallery page: a section per image, a card per variant, filters, a lightbox, light and dark, works on a phone. Serves it locally.
4. Each producer lists its own weak spots, and you get the gallery link with those notes. You pick per image, mixing producers and styles; an image you nearly like gets edited rather than regenerated.
5. Copies only the picks into the repo and wires them into the post: centred and narrower than the text, SVG diagrams switching with the site's light and dark theme. Builds, checks both themes and commits.

## Needs

An agent with image generation, such as [Codex](https://github.com/openai/codex), for the styled variants. `rsvg-convert` (librsvg) to check SVG diagrams. Python 3 to serve the gallery.

## Files

- [SKILL.md](SKILL.md): the agent's steps.
- [gallery.html](gallery.html): the gallery template.
