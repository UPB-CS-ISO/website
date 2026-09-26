# Introduction to Operating Systems (ISO) — Slides & Website

Course materials for the *Introduction to Operating Systems* class at
Politehnica Bucharest. The repository has two parts:

| Folder     | What it is                                   | Tooling                               |
|------------|----------------------------------------------|---------------------------------------|
| `slides/`  | Lecture slides, written in Typst             | [Typst](https://typst.app), `make`    |
| `website/` | Course website (lectures, labs, slide PDFs)  | [Docusaurus 3](https://docusaurus.io), Node.js |

The slides are compiled to PDF and copied into `website/static/slides/`, so the
website can link to and embed them (e.g. `/slides/iso_01_intro.pdf`).

## Prerequisites

- **Typst** (CLI) — e.g. `brew install typst`, `cargo install --locked typst-cli`,
  or `sudo snap install typst`.
- **GNU Make**
- **Node.js ≥ 18** (CI uses Node 22) and **npm**

The first slide build needs internet access: Typst downloads the
`@preview/diatypst` and `@preview/polylux` packages and caches them locally.

## Quick start: build everything

From the repository root:

```bash
./build.sh
```

This script:

1. builds all slide decks in `slides/` (`make`),
2. replaces `website/static/slides/` with the fresh PDFs,
3. installs the website dependencies, clears the Docusaurus cache and builds
   the site into `website/build/`.

Preview the result with:

```bash
cd website
npm run serve
```

## Slides

### Layout

```
slides/
├── Makefile
└── src/
    ├── slides.typ      # shared theme: `uso_slides` template (diatypst)
    ├── polylux.typ     # polylux helpers (#only, #uncover, toolbox, ...)
    ├── terminal.typ    # terminal / code-listing helpers (#reveal-terminal)
    ├── ai-prompt.typ   # AI prompt boxes
    └── 01_intro/       # one folder per lecture
        ├── main.typ    # entry point for the deck
        ├── *.typ       # sections included from main.typ
        └── img/        # images used by the deck
```

Every sub-folder of `slides/src/` is one deck. Its entry point **must** be
`main.typ`; it is compiled to `slides/build/iso_<folder>.pdf`
(e.g. `src/01_intro` → `build/iso_01_intro.pdf`).

### Build commands

Run these from `slides/`:

```bash
make               # build all decks into build/
make 01_intro      # build a single deck
make watch_01_intro  # rebuild a deck automatically on every save
make clean         # remove build/
```

Under the hood each target runs:

```bash
typst compile --root . src/<deck>/main.typ build/iso_<deck>.pdf
```

`--root .` makes absolute imports such as `#import "/src/slides.typ": *`
resolve relative to `slides/`.

### Adding a new lecture

1. Create `slides/src/NN_topic/main.typ` starting with:

   ```typst
   #import "/src/slides.typ": *

   #show: uso_slides.with(title: "NN. Topic")

   #slide[
     == First slide
     ...
   ]
   ```

2. Run `make` — the Makefile picks up the new folder automatically.
3. Link the PDF from the matching lecture page in `website/docs/lectures/`
   as `/slides/iso_NN_topic.pdf`.

## Website

The site is a Docusaurus project in `website/`:

- `docs/lectures/` — one page per lecture (links/embeds the slide PDF)
- `docs/labs/` — lab pages
- `src/pages/` — home page and standalone pages
- `static/` — static assets; `static/slides/` is **generated** (git-ignored)
- `docusaurus.config.ts`, `sidebars.ts` — site configuration

### Commands

Run these from `website/`:

```bash
npm install        # or `npm ci` for a clean, lockfile-exact install
npm start          # dev server with live reload at http://localhost:3000
npm run build      # production build into build/
npm run serve      # serve the production build locally
npm run clear      # clear the Docusaurus cache (.docusaurus/)
npm run typecheck  # TypeScript check
```

> The dev server serves slide PDFs from `static/slides/`. If the slide links
> 404 locally, build the slides first and copy them over:
>
> ```bash
> (cd slides && make && mkdir -p ../website/static/slides && cp build/*.pdf ../website/static/slides/)
> ```

## Continuous integration & deployment

GitHub Actions workflows live in `.github/workflows/`:

- **`test-deploy.yml`** — on every pull request: installs Typst, builds the
  slides, copies them into the website and runs `npm run build` to verify
  everything compiles.
- **`deploy.yml`** — on every push to `main`: same build, then publishes
  `website/build/` to the `gh-pages` branch with
  [`peaceiris/actions-gh-pages`](https://github.com/peaceiris/actions-gh-pages).
- **`labeler.yml`** — labels pull requests based on the files they touch.

There is no need to deploy manually — merging into `main` publishes the site.

## License

Slides: Copyright (C) 2026 Wyliodrin & Politehnica Bucharest, CC-BY-4.0.
