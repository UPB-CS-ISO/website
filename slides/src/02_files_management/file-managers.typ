#import "/src/slides.typ": *
#import "diagram.typ": *

#slide[
  = File Managers #text(size: 10pt, weight: "regular")[\ `mc`, `nnn` _and_ `yazi`]
]

#slide[
  == File Management Software

  - #link("https://midnight-commander.org")[Midnight Commander] (`mc`)
  - #link("https://github.com/jarun/nnn")[n#super[3]] - _The unorthodox terminal file manager_ (`nnn`)
  - #link("https://yazi-rs.github.io")[Yazi] - _⚡️ Blazing fast terminal file manager written in Rust, based on async I/O._ (`yazi`)

  #v(1fr)

  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 1em,
    align: center + horizon,
    image("img/navigation/mc.png", width: 100%),
    image("img/navigation/nnn.png", width: 100%),
    image("img/navigation/yazi.png", width: 100%),
  )

  #v(1fr)
]

// a yazi tab label, the active tab is filled
#let yazi-tab(n, name, active) = box(
  inset: (x: 0.5em, y: 0.25em),
  radius: 2pt,
  fill: if active { rgb("004d65") } else { luma(225) },
  text(fill: if active { white } else { black }, weight: "bold")[#n #name],
)

// one tab: its label and the directory it shows
#let yazi-pane(n, name, active, tree) = [
  #yazi-tab(n, name, active)
  #v(-0.5em)
  #tree
]

#slide[
  == `yazi`
  🦆 a terminal file manager: the file commands with a few keys

  // (keys, what they do, the command that does the same); a row with
  // only the first cell is the title of a group
  #let keys = (
    ([move], none, none),
    ([#kbd("↑") #kbd("↓")], [choose a file], none),
    ([#kbd("←") / #kbd("→")], [parent directory / open], [`cd`]),
    ([#kbd(".")], [show hidden files], [`ls -a`]),
    ([manage files], none, none),
    ([#kbd("Space")], [select, for several files], none),
    ([#kbd("a")], [create a file, `name/` for a directory], [`touch`, `mkdir`]),
    ([#kbd("r")], [rename], [`mv`]),
    ([#kbd("y") then #kbd("p")], [copy, then paste], [`cp`]),
    ([#kbd("x") then #kbd("p")], [cut, then paste], [`mv`]),
    ([#kbd("d")], [move to the trash], none),
    ([#kbd("D")], [delete permanently], [`rm`]),
    ([tabs], none, none),
    ([#kbd("t") #kbd("t")], [open a new tab], none),
    ([#kbd("1") ... #kbd("9")], [go to a tab], none),
    ([#kbd("[") #kbd("]")], [previous / next tab], none),
  )

  // the copy and move between two tabs: the active tab, the two trees and
  // what is done in this step
  #let downloads(..args) = fs-tree(cwd: 1, ..args, ```
  ~/Downloads
  ├── supergirl.mp4
  └── michael.mp4
  ```)
  #let movies(..args) = fs-tree(cwd: 1, ..args, ```
  ~/Movies
  └── the_odyssey.mkv
  ```)
  #let tab-steps = (
    (1, downloads(), movies(), [#kbd("t") #kbd("t") a *new tab*, each tab has its own _current directory_ 📍]),
    (1, downloads(source: (2,)), movies(), [in tab `1`: #kbd("Space") select `supergirl.mp4`, #kbd("y") copy]),
    (2, downloads(source: (2,)), movies(), [#kbd("2") go to tab `2`]),
    (
      2,
      downloads(),
      fs-tree(cwd: 1, new: (2,), ```
      ~/Movies
      ├── supergirl.mp4
      └── the_odyssey.mkv
      ```),
      [#kbd("p") paste: a *copy*, like `cp`],
    ),
    (
      2,
      downloads(gone: (3,)),
      fs-tree(cwd: 1, new: (2,), ```
      ~/Movies
      ├── michael.mp4
      ├── supergirl.mp4
      └── the_odyssey.mkv
      ```),
      [#kbd("1") #kbd("x") cut `michael.mp4`, #kbd("2") #kbd("p") paste: *moved*, like `mv`],
    ),
  )

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.7em)
    #table(
      columns: (auto, 1fr, auto),
      stroke: none,
      inset: (x: 0.35em, y: 0.28em),
      table.header([*key*], [*action*], [*like*]),
      ..keys
        .map(((k, action, cmd)) => if action == none {
          (table.cell(colspan: 3, text(fill: rgb("004d65"), weight: "bold", k)),)
        } else {
          (k, action, if cmd == none { [] } else { cmd })
        })
        .flatten(),
    )
  ][
    #only(1)[
      #image("img/navigation/yazi.png", width: 100%)

      run `yazi`, #kbd("q") to quit, #kbd("~") for help
    ]
    #for (i, (active, dl, mv, what)) in tab-steps.enumerate() {
      let frames = if i == tab-steps.len() - 1 { str(i + 2) + "-" } else { i + 2 }
      only(frames)[
        #set text(size: 0.8em)
        #yazi-pane(1, "Downloads", active == 1, dl)
        #yazi-pane(2, "Movies", active == 2, mv)
        #text(size: 1.1em, what)

        #fs-legend-source
      ]
    }
  ]
]
