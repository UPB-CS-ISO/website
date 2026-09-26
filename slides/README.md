# Slides

Lecture slides for *Introduction to Operating Systems*, written in
[Typst](https://typst.app) using the
[diatypst](https://typst.app/universe/package/diatypst) theme and
[polylux](https://typst.app/universe/package/polylux) for animations.

Each deck compiles to a PDF in `build/`, which gets copied into the website
(`website/static/slides/`) — see the [top-level README](../README.md).

## Requirements

- **Typst CLI** — `brew install typst`, `cargo install --locked typst-cli`
  or `sudo snap install typst`
- **GNU Make**
- Internet access on the first build: Typst downloads `@preview/diatypst:0.9.3`
  and `@preview/polylux:0.4.0` and caches them.
- The `DejaVu Sans Mono` font (used by AI prompt boxes). Typst falls back to
  another font if it's missing.

## Building

```bash
make                  # build every deck into build/
make 01_intro         # build a single deck
make watch_01_intro   # rebuild a deck on every save (typst watch)
make clean            # remove build/
```

Each deck `src/<deck>/main.typ` becomes `build/iso_<deck>.pdf`, e.g.
`src/01_intro` → `build/iso_01_intro.pdf`. Under the hood:

```bash
typst compile --root . src/<deck>/main.typ build/iso_<deck>.pdf
```

`--root .` makes absolute imports like `/src/slides.typ` resolve relative to
this folder, so always run `make` (or `typst`) from `slides/`.

To publish the PDFs on the website locally:

```bash
make && mkdir -p ../website/static/slides && cp build/*.pdf ../website/static/slides/
```

## Layout

```
slides/
├── Makefile
└── src/
    ├── slides.typ      # course template: uso_slides (theme, colors, authors, footer)
    ├── polylux.typ     # re-exports polylux (#only, #uncover, #toolbox, ...)
    ├── terminal.typ    # ```terminal blocks: shell highlighting + #reveal-terminal
    ├── ai-prompt.typ   # #ai-prompt and #ai-prompt-overlay boxes
    └── 01_intro/       # one folder per lecture
        ├── main.typ    # deck entry point
        ├── *.typ       # sections pulled in with #include
        └── img/        # images for this deck
```

Every sub-folder of `src/` is treated as a deck, so keep only lecture folders
there.

## Adding a lecture

1. Create `src/NN_topic/main.typ`:

   ```typst
   #import "/src/slides.typ": *

   #show: uso_slides.with(title: "NN. Topic")

   #slide[
     == First slide
     Some content
   ]

   #include "section.typ"   // optional: split long decks into files
   ```

   `uso_slides` also takes `date:` (defaults to today).

2. Run `make NN_topic` (the Makefile picks up new folders automatically).
3. Link `/slides/iso_NN_topic.pdf` from the matching page in
   `website/docs/lectures/`.

## Writing slides

Everything below is available after `#import "/src/slides.typ": *`.

**Slides and headings** — `#slide[ == Title ... ]`. Level-2 headings are
numbered and drive the dot-section progress indicator.

**Animations (polylux)**

```typst
#only(2)[shown only on step 2]
#uncover("2-")[appears from step 2 on, reserves space before]
#toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[left][right]
```

**Terminal sessions** — use a `terminal` fenced block. Lines starting with
`$ ` are commands (prompt + syntax highlighting), a trailing `\` continues a
command on the next line, everything else is shown as output.

````typst
```terminal
$ ls -la /tmp
total 0
$ echo "hello" | wc -c
6
```
````

To reveal it line by line, wrap it in `#reveal-terminal` (same arguments as
polylux's `#reveal-code`, which does not work with terminal blocks):

````typst
#reveal-terminal(lines: (1, 3))[```terminal
$ ls -la /tmp
total 0
$ echo "hello" | wc -c
6
```]
````

`#terminal("$ ls\nfile.txt")` builds the same block from a string.

**AI prompts** — a boxed prompt students can copy into an AI assistant:

```typst
#ai-prompt[Explain what a process is in one paragraph.]
#ai-prompt(title: "Prompt idea")[...]

// drawn on top of the slide; put it last in the #slide body
#only(2)[#ai-prompt-overlay(at: bottom + right, width: 45%)[...]]
```

## Changing the theme

Edit `uso_slides` in `src/slides.typ` — course title, authors, colors,
aspect ratio and footer are set there and apply to every deck.
