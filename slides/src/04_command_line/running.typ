#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Running a Command #text(size: 10pt, weight: "regular")[\ _From a line of text to a process_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.9 - _The Command Path_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.1.3 - _Funcționarea shellului_
      - Section 7.1.3.1 - _Variabila de mediu PATH_
      - Section 7.1.4 - _Comenzi interne și comenzi externe_
]

#slide[
  == Built-in and External Commands
  Not every command is a program

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === Built-in commands
    - run *inside* the shell, no new process
    - `cd`, `export`, `unset`, `jobs`, `fg`, `bg`, `type`, `exit`, ...

    #uncover("2-")[
      === External commands
      - executable files, somewhere on the disk
      - the shell needs their *path*
      - `ls`, `sort`, `grep`, `bash`, ...
    ]
  ][
    #uncover("3-")[
      ```terminal
      $ type cd
      cd is a shell builtin
      $ type sort
      sort is /usr/bin/sort
      ```
    ]
  ]

  #uncover("4-")[
    #align(center, text(size: 1.5em, weight: "bold", fill: accent)[Why must `cd`, `unset` and `exit` be built-in?])
  ]
  #uncover("5-")[
    #align(center)[
      💡 they change *the shell itself*: `cd` its current directory, `unset` its variables, `exit` stops it \
      💡 a child process can only change *itself*, never its parent
    ]
  ]
]

// ----- external commands: a path or a name -----

// `shown`, in a box as wide as the widest of `variants`, so a drawing does
// not shift when the content of a box changes from one step to the next
#let same-width(variants, shown) = context {
  let w = calc.max(..variants.map(v => measure(v).width))
  box(width: w, align(center, shown))
}

// a box of the schematics: `on` - on the route of the current example
// (orange), `kind` - "step" (an action), "ask" (a question, dashed) or
// "end" (where the shell ends up)
#let flow-box(body, on: false, kind: "step", width: auto, fill: none) = box(
  width: width,
  inset: (x: 0.5em, y: 0.45em),
  radius: if kind == "ask" { 0.8em } else { 0.3em },
  stroke: if on { 1.5pt + changed } else if kind == "ask" {
    (paint: luma(140), thickness: 0.8pt, dash: "dashed")
  } else { 0.8pt + luma(140) },
  fill: if fill != none { fill } else if kind == "end" { luma(245) } else { white },
  // only the color changes, never the weight: bold text is wider and
  // would shift the drawing between the steps
  align(center, text(fill: if on { changed } else { black }, body)),
)

// an arrow of the schematics, orange when it is on the route
#let flow-arrow(on: false, length: 1.6em, label: none, down: false) = {
  let c = if on { changed } else { luma(150) }
  let a = draw-arrow(length: length, color: c, thickness: if on { 1.8pt } else { 1.2pt })
  let l = if label == none { [] } else { text(size: 0.75em, fill: c, label) }
  if down {
    grid(columns: 2, column-gutter: 0.3em, align: horizon, rotate(90deg, reflow: true, a), l)
  } else {
    grid(rows: 2, row-gutter: 0.15em, align: center, l, a)
  }
}

// the examples that go through the decision chart, one per step:
// (the command, the route, what happens)
// routes: "abs", "rel", "builtin", "found", "missing"
#let route-examples = (
  (
    ```terminal
    $ /usr/bin/sort fruits.txt
    ```,
    "abs",
    "/usr/bin/sort",
    [an absolute path is used as it is, no search],
  ),
  (
    ```terminal
    $ ./hello
    Hello!
    ```,
    "rel",
    "/home/alice/hello",
    [`/home/alice` + `./hello` #arrow `/home/alice/hello`],
  ),
  (
    ```terminal
    $ ../tools/hello
    Hello from tools!
    ```,
    "rel",
    "/home/tools/hello",
    [`/home/alice` + `../tools/hello` #arrow `/home/tools/hello`],
  ),
  (
    ```terminal
    $ cd /tmp
    ```,
    "builtin",
    none,
    [`cd` is not a file, the shell does it itself],
  ),
  (
    ```terminal
    $ sort fruits.txt
    ```,
    "found",
    "/usr/bin/sort",
    [the first match in `PATH`: `/usr/bin/sort`],
  ),
  (
    ```terminal
    $ hello
    bash: hello: command not found
    ```,
    "missing",
    none,
    [no `hello` in ```bash $PATH```: the shell does *not* look in the current directory],
  ),
)

// the first word of the command of an example (after the `$ ` prompt)
#let first-word(example) = example.text.slice(2).split("\n").at(0).split(" ").at(0)

// the decision chart, `route` is the way the current example takes
// (none: nothing is highlighted), `word` the first word of its command,
// `file` the file that runs (none: no file)
#let route-chart(route, word, file) = {
  let reach = (
    abs: ("d1", "r1"),
    rel: ("d1", "n1", "d2", "r2"),
    builtin: ("d1", "n1", "d2", "n2", "d3", "r3"),
    found: ("d1", "n1", "d2", "n2", "d3", "n3", "p", "r4"),
    missing: ("d1", "n1", "d2", "n2", "d3", "n3", "p", "r5"),
  )
  let on(k) = route != none and k in reach.at(route)
  // the file that runs, under an end box: as wide as the widest file of
  // that box, hidden when the box is not on the route
  let file-line(k) = {
    let files = route-examples.filter(e => e.at(1) == k).map(e => e.at(2)).filter(f => f != none)
    let line(f) = text(font: mono, size: 0.8em, fill: changed, f)
    if files.len() == 0 { files = ("/bin",) }
    let shown = if route == k and file != none { line(file) } else { hide(line(files.at(0))) }
    v(0.2em)
    same-width(files.map(line), shown)
  }
  let end-box(k, body, files: true) = flow-box(
    on: on("r" + str(("abs", "rel", "builtin", "found", "missing").position(x => x == k) + 1)),
    kind: "end",
    width: 9.6em,
    if files { [#body #file-line(k)] } else { body },
  )
  set text(size: 0.82em)
  grid(
    columns: 9,
    column-gutter: 0.4em,
    row-gutter: 0.35em,
    align: center + horizon,
    // the first row: the questions, answered with "no" from left to right
    {
      let words = ("command",) + route-examples.map(e => first-word(e.at(0)))
      let word-box(on, w) = flow-box(on: on, raw(w))
      same-width(
        words.map(w => word-box(true, w)),
        word-box(route != none, if word == none { "command" } else { word }),
      )
    },
    flow-arrow(on: route != none, length: 1.3em),
    flow-box(on: on("d1"), kind: "ask")[starts with `/`?],
    flow-arrow(on: on("n1"), label: [no], length: 1.3em),
    flow-box(on: on("d2"), kind: "ask")[contains a `/`?],
    flow-arrow(on: on("n2"), label: [no], length: 1.3em),
    flow-box(on: on("d3"), kind: "ask")[a built-in#footnote[it is actually a _function_, _alias_ or _builtin_]?],
    flow-arrow(on: on("n3"), label: [no], length: 1.3em),
    // the search is always highlighted
    flow-box(on: on("p"), fill: changed-fill)[search ```bash $PATH```],
    // the second row: the "yes" answers
    [], [],
    flow-arrow(on: on("r1"), label: [yes], down: true, length: 1.4em), [],
    flow-arrow(on: on("r2"), label: [yes], down: true, length: 1.4em), [],
    flow-arrow(on: on("r3"), label: [yes], down: true, length: 1.4em), [],
    grid(
      columns: 2,
      column-gutter: 0.6em,
      flow-arrow(on: on("r4"), label: [found], down: true, length: 1.4em),
      flow-arrow(on: on("r5"), label: [missing], down: true, length: 1.4em),
    ),
    // the third row: where the shell ends up, with the file that runs
    [], [],
    grid.cell(align: center + top, end-box("abs")[*absolute path*\ used as it is]),
    [],
    grid.cell(align: center + top, end-box("rel")[*relative path*\ + current directory]),
    [],
    grid.cell(align: center + top, end-box("builtin")[*built-in*\ run *inside* the shell]),
    [],
    grid.cell(align: center + top, stack(
      dir: ttb,
      spacing: 0.4em,
      end-box("found")[*found*\ the first match],
      end-box("missing", files: false)[`command not found`],
    )),
  )
}

#slide[
  == Which File?

  #counter(footnote).update(0)

  External commands need a *path*: the shell turns the first word into a file to start

  #align(center)[
    #only(1, route-chart(none, none, none))
    #for (i, (cmd, route, file, what)) in route-examples.enumerate() {
      only(if i == route-examples.len() - 1 { str(i + 2) + "-" } else { i + 2 }, route-chart(route, first-word(cmd), file))
    }
  ]

  #v(0.2em)
  #grid(
    columns: (auto, 22em),
    column-gutter: 0.8em,
    align: (right + top, left + top),
    uncover("2-", text(size: 0.8em, fill: luma(110), style: "italic")[you type]),
    {
      set text(size: 0.85em)
      // as tall as the tallest example, so the notes below do not move
      let cmds = route-examples.map(e => e.at(0))
      context {
        let h = calc.max(..cmds.map(c => measure(block(width: 22em / 0.85, c)).height))
        block(height: h, {
          only(1, hide(cmds.at(0)))
          for (i, cmd) in cmds.enumerate() {
            only(if i == cmds.len() - 1 { str(i + 2) + "-" } else { i + 2 }, cmd)
          }
        })
      }
    },
  )

  // the explanation, larger, always at the bottom of the slide
  #v(1fr)
  #block(width: 100%)[
    #set text(size: 1.1em)
    #only(1)[💡 the current directory is `/home/alice`]
    #for (i, (cmd, route, file, what)) in route-examples.enumerate() {
      // a file runs (or the built-in): success, no file: error
      only(i + 2)[#if route == "missing" [❌] else [✅] #what]
    }
    #only(str(route-examples.len() + 2) + "-")[
      // the main idea of the slide: a large callout
      #block(
        width: 100%,
        fill: changed-fill,
        stroke: 2pt + changed,
        radius: 0.4em,
        inset: (x: 0.8em, y: 0.5em),
        align(center, text(size: 1.1em)[🐧 `exec` only starts a #text(fill: changed)[path]: turning a #text(fill: changed)[name] into a path is the job of the shell#footnote[It is actually the job of `libc`, the C library, the shell uses the `execvp` function]]),
      )
    ]
  ]
]

#let path-dirs = ("/home/alice/.local/bin", "/usr/local/bin", "/usr/bin", "/bin")
// the directory of `path-dirs` (from 1) that has `sort`
#let path-found = 3

// the state of directory `n` (from 1) while the shell checks directory
// `step`: "later" (not checked yet), "no" (checked, no `sort`), "now"
// (checked right now, no `sort`) or "yes" (`sort` is here)
#let path-state(n, step) = if n > step { "later" } else if n == path-found { "yes" } else if n < step { "no" } else { "now" }

// a down arrow between the rows of the drawing, with a short label
#let down(label) = grid(
  columns: 2,
  column-gutter: 0.5em,
  align: horizon,
  rotate(90deg, reflow: true, draw-arrow(length: 1.4em)),
  text(size: 0.75em, fill: luma(110), style: "italic", label),
)

// the value of PATH, the `:` separators in orange; while the shell checks
// directory `step`, that directory is orange too and the checked ones gray
#let path-value(step) = {
  set text(font: mono, size: 0.8em)
  let parts = ()
  for (i, d) in path-dirs.enumerate() {
    let st = path-state(i + 1, step)
    if i > 0 { parts.push(text(fill: changed, weight: "bold", ":")) }
    // the directory that is checked gets a background, not a bold font:
    // the line keeps its width on every step
    parts.push(if st == "now" or st == "yes" {
      box(fill: changed-fill, outset: (y: 3pt), radius: 2pt, text(fill: changed, d))
    } else if st == "no" { text(fill: luma(170), d) } else { d })
  }
  box(
    inset: (x: 0.7em, y: 0.5em),
    radius: 0.3em,
    fill: luma(240),
    [#text(fill: rgb("b35900"), weight: "bold")[PATH]=#parts.join()],
  )
}

// the directories of PATH, one rectangle each, with the result of the
// search under every rectangle
#let path-boxes(step) = {
  let cells = ()
  let results = ()
  for (i, d) in path-dirs.enumerate() {
    let st = path-state(i + 1, step)
    let (stroke, fill, ink) = if st == "now" or st == "yes" {
      (1.5pt + changed, changed-fill, changed)
    } else if st == "no" {
      (0.8pt + luma(200), luma(245), luma(170))
    } else {
      (0.8pt + luma(120), white, black)
    }
    cells.push(box(
      inset: (x: 0.6em, y: 0.5em),
      radius: 0.3em,
      stroke: stroke,
      fill: fill,
      text(font: mono, size: 0.8em, fill: ink, d),
    ))
    // every result cell is as wide as its widest possible content
    let no = text(fill: luma(130))[❌ no `sort`]
    let yes = text(fill: changed)[✅ #raw(d + "/sort")]
    results.push(text(size: 0.75em, same-width(
      (no, yes),
      if st == "no" or st == "now" { no } else if st == "yes" { yes } else { [] },
    )))
  }
  grid(
    columns: path-dirs.len(),
    column-gutter: 0.8em,
    row-gutter: 0.5em,
    align: center + horizon,
    ..cells,
    ..results,
  )
}

// step 1: the command, 2: PATH, 3: the directories,
// 4 .. 3 + path-found: the search, then: what the shell runs
#let path-search-steps = 3 + path-found + 1

#slide[
    == ```bash $PATH``` Search
  Where the shell looks for commands

  #align(center)[
    #set par(leading: 0.5em, spacing: 0.35em)
    #set block(spacing: 0.35em)
      ```terminal
      $ sort fruits.txt
      ```

    #uncover("2-")[
      #down[`sort` has no `/`: look it up in the environment variable `PATH`]
      // steps 2 and 3 show PATH as it is, from step 4 on the checked directory is marked
      #only("2-3", path-value(0))
      #for s in range(1, path-found + 1) {
        only(if s == path-found { str(s + 3) + "-" } else { s + 3 }, path-value(s))
      }
    ]

    #uncover("3-")[
      #down[split at every `:`]
      #only(3, path-boxes(0))
      #for s in range(1, path-found + 1) {
        only(if s == path-found { str(s + 3) + "-" } else { s + 3 }, path-boxes(s))
      }
    ]

    #uncover(str(path-search-steps) + "-")[
      #down[the first match wins]
      ```terminal
      $ /usr/bin/sort fruits.txt
      ```
    ]
  ]

  // the notes stay at the bottom, so they do not move while the drawing grows
  #place(bottom + left, block(width: 100%)[
  #set text(size: 0.9em)
  #only(1)[💡 a command name without a `/`: the shell has to find its executable file]
  #only(2)[💡 `PATH` is an environment variable: a list of directories, separated by `:`]
  #only(3)[💡 the shell splits it into directories]
  #only(4)[💡 it checks them *from left to right*: there is no `sort` in `/home/alice/.local/bin`]
  #only(5)[💡 no `sort` in `/usr/local/bin` either]
  #only(6)[💡 `/usr/bin/sort` exists: the search stops, `/bin` is never checked]
  #only("7-")[💡 the shell runs the file it found]
  ])
]
