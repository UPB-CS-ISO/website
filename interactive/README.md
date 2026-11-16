# Interactive lectures

Each lecture of the slides gets a single-file web page: short chapters, demo
terminals, step-by-step simulators, quizzes and flashcards. A Python script per
lecture writes the page; everything (CSS, JS, SVG) is inlined.

| Output (in `website/static/courses/`) | Built by |
|---|---|
| `index.html`, the main page: one card per lecture, with the student's progress | `build_index.py` |
| `02-files-management/index.html` | `build_02.py` |
| `03-processes/index.html` | `build_03.py` |
| `04-command-line/index.html` | `build_04.py` |
| `07-software-development/index.html` | `build_07.py` |
| `08-shell-scripting/index.html` | `build_08.py` |

The pages are **generated, not committed** (`website/static/courses` is
git-ignored). CI builds them before the website.

On the site they are reached from the **Interactive** page of the docs
(`website/docs/interactive.md`), from each lecture page (the *Interactive
lecture* box) and, inside a lecture, by clicking **ISO** in the top bar.

## Build

Needs [uv](https://docs.astral.sh/uv/) (it installs Pillow from `uv.lock`) and
poppler (`pdftoppm`).

```bash
make                       # all lectures, then the main page
uv run python build_03.py  # one lecture
make clean                 # remove the generated pages
```

Without uv, `make` falls back to `python3` (install Pillow yourself).

Open a page directly in the browser (`website/static/courses/03-processes/index.html`)
or through the website (`npm start` in `website/`, then `/courses/`).

## Files

| File | What it is |
|---|---|
| `page.py` | `Course` / `chapter` / `page`, `F()` (build-time f-strings) and `render()`: the HTML shell (top bar, hero, course map, chapters, bottom bar) |
| `engine.py` | content helpers: notes, figures, tables, terminal examples (`sh`), quizzes, steps, syntax highlighting (`hl`) |
| `base.css`, `extra.css`, `theme.py` | the shared look, in the colors of the slides |
| `runtime.js`, `flash.js` | routing (`#chapter/page`, `#map`, `#all`), progress (saved in `localStorage`), quizzes, flashcards |
| `shell-core.js`, `shell-ui.js` | the demo shell: in-memory file system, commands with `man` pages, pipes and redirects, missions; and its terminal widget |
| `shell-cli.js`, `shell-make.js`, `shell-git.js` | the shell additions of lectures 04 (variables, jobs) and 07 (`gcc`, `make`, `git`) |
| `dev.js` | the "interactive on this page" button for every lecture, and the widgets of lecture 07 |
| `widgets02.js`, `procs.js`, `widgets04.js`, `widgets07.js`, `widgets08.js` | the widgets of one lecture (02, 03, 04, 07, 08) |
| `bashrun.js` | lecture 08: a small bash interpreter (variables, `IFS`, `$( )`, `$(( ))`, `if`, `case`, loops, functions, `read`, `test`, `bc`, `expr`) that runs the scripts of the script lab and records the debugger steps |
| `build_index.py` | the main page; finds the lectures from `build_NN.py` and the docs |

`shell-core.js`, `shell-ui.js`, the CSS and `page.py` are shared by every
lecture: a change there changes all pages on the next build.

## Adding a lecture

1. Copy the newest `build_NN.py` (07 is the most complete) and set `OUT`,
   `META` (`num`, `key` for the saved progress, `short`, `title`, `lead`, ...)
   and the chapters.
2. Put the lecture's widgets in a new `widgetsNN.js` and pass it to
   `render(..., js=["dev.js", "widgetsNN.js"])`.
3. Run `make`. The main page lists the new lecture by itself.
4. In `website/docs/lectures/NN.md` (and the Romanian copy under
   `website/i18n/ro/`), add the *Interactive lecture* box (see `02.md`), and add
   a row to `website/docs/interactive.md` (and its Romanian copy).

## AI-generated content

The pages are study material generated with AI (Claude) from the slides, to be
reviewed by the lecturers. Each page says so; for the exam, the reference is the
lecture and its slides.
