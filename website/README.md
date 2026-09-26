# Website

The course website, built with [Docusaurus 3](https://docusaurus.io/) and
published at <https://linux-101.wyliodrin.com>.

> For building the slides and the whole project in one go, see the
> [top-level README](../README.md) (`./build.sh` from the repository root).

## Requirements

- Node.js ≥ 22
- npm (the project uses `package-lock.json`; don't use yarn)

## Installation

```bash
npm install     # or `npm ci` for a clean, lockfile-exact install
```

## Local development

```bash
npm start
```

Starts a dev server at <http://localhost:3000> with live reload.

The lecture pages link to slide PDFs under `/slides/`, which are served from
`static/slides/`. That folder is generated and git-ignored, so build the slides
first if the links 404:

```bash
cd ../slides && make && mkdir -p ../website/static/slides && cp build/*.pdf ../website/static/slides/
```

## Build

```bash
npm run build   # static site into build/
npm run serve   # preview the production build locally
```

The build fails on broken links (`onBrokenLinks: 'throw'`), so missing slide
PDFs or pages will be caught here.

Other useful scripts:

```bash
npm run clear      # clear the Docusaurus cache (.docusaurus/)
npm run typecheck  # TypeScript check
```

## Project layout

- `docs/lectures/` — one page per lecture (links/embeds the slide PDF)
- `docs/labs/` — lab pages
- `src/pages/` — home page and standalone pages
- `src/components/`, `src/css/` — React components and styles
- `static/` — static assets (`static/slides/` is generated)
- `docusaurus.config.ts`, `sidebars.ts` — site configuration

## Deployment

Deployment is automatic: every push to `main` runs
`.github/workflows/deploy.yml`, which builds the slides and the site and
publishes `build/` to the `gh-pages` branch with the custom domain
`linux-101.wyliodrin.com`. Pull requests are build-checked by
`.github/workflows/test-deploy.yml`. There's no need to run `npm run deploy`.
