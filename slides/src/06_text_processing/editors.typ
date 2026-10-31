#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Text Editors #text(size: 10pt, weight: "regular")[\ _Writing code is editing text files_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.6.1 - _Scrierea codului sursă_
      - Section 6.6.2 - _Editoare în mod text_
  + the built-in tutorials
    - `vimtutor` - 30 minutes of `vim`
    - `hx --tutor` - the `helix` tutorial
    - #ctrl("h") then #kbd("t") inside `emacs`
]

#slide[
  == Terminal Editors

  #grid(
    columns: (1fr, 1fr, 1fr, 1fr),
    gutter: 0.6em,
    align: center + top,
    [
      #screenshot("img/editors/nano.png", width: 100%)
      #link("https://www.nano-editor.org")[`nano`] \
      #text(size: 0.75em)[_very basic_, the keys are listed at the bottom]
    ],
    uncover("2-")[
      #screenshot("img/editors/vim.png", width: 100%)
      `vi` / #link("https://www.vim.org")[`vim`] / #link("https://neovim.io")[`nvim`] \
      #text(size: 0.75em)[_modal_, available everywhere]
    ],
    uncover("3-")[
      #screenshot("img/editors/emacs.png", width: 100%)
      #link("https://www.gnu.org/software/emacs/")[`emacs`] \
      #text(size: 0.75em)[key chords, extensible in Lisp]
    ],
    uncover("4-")[
      #screenshot("img/editors/helix.png", width: 100%)
      #link("https://helix-editor.com")[`helix`] (`hx`) \
      #text(size: 0.75em)[_modal_, select first, then act]
    ],
  )

  #v(1fr)
  #only(1)[💡 `nano` (a free clone of `pico`): what you see is what you get, the default editor on many distributions]
  #only(2)[💡 `vi` (1976), `vim` (_Vi IMproved_, 1991), `neovim` (2014): the keys work in `less`, `man`, browsers and IDEs]
  #only(3)[💡 `emacs` (1976): not modal, every command is a #kbd("Ctrl") or #kbd("Alt") chord]
  #only("4-")[💡 `helix` (2021, written in Rust): `vim`-like, with a language server client built in]
]

#slide[
  == `nano`
  The keys are always on the screen: `^` means #kbd("Ctrl"), `M-` means #kbd("Alt")

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #screenshot("img/editors/nano.png", width: 100%)
    ```terminal
    $ nano main.c
    ```
  ][
    #key-table(size: 0.7em, (
      ([move], none),
      ([#kbd("←") #kbd("↓") #kbd("↑") #kbd("→")], [the arrow keys: #arrows("←↓↑→")]),
      ([#ctrl("A") / #ctrl("E")], [start / end of the line]),
      ([files], none),
      ([#ctrl("O")], [save (_write out_)]),
      ([#ctrl("X")], [exit]),
      ([edit], none),
      ([#ctrl("K")], [cut the line]),
      ([#ctrl("U")], [paste]),
      ([#alt("U")], [undo]),
      ([search], none),
      ([#ctrl("W")], [search (_where is_)]),
      ([#ctrl("\\")], [search and replace]),
      ([#ctrl("_")], [go to a line]),
    ))
  ]
]

// ----- vim -----

// a mode of the vim drawing
#let mode-box(name, sub, on: false) = box(
  width: 82pt,
  inset: (y: 0.45em),
  radius: 0.5em,
  stroke: if on { 1.5pt + changed } else { 1pt + accent },
  fill: if on { changed-fill } else { rgb("eef3f5") },
  align(center)[
    #text(size: 9pt, weight: "bold", fill: if on { changed } else { accent }, name) \
    #text(size: 7pt, fill: luma(80), sub)
  ],
)

#let key-label(body) = box(fill: white, inset: 1pt, text(size: 7.5pt, body))

#let vim-modes(on) = drawing(width: 250pt, height: 175pt, {
  let n = (125pt, 88pt)
  let i = (125pt, 18pt)
  let c = (42pt, 158pt)
  let v = (208pt, 158pt)
  // normal <-> insert
  line-arrow((112pt, 72pt), (112pt, 35pt), color: accent)
  line-arrow((138pt, 35pt), (138pt, 72pt), color: accent)
  pin(84pt, 54pt, key-label[#kbd("i") #kbd("a") #kbd("o")])
  pin(162pt, 54pt, key-label[#kbd("Esc")])
  // normal <-> command line
  line-arrow((95pt, 105pt), (58pt, 140pt), color: accent)
  line-arrow((40pt, 140pt), (80pt, 103pt), color: accent)
  pin(95pt, 128pt, key-label[#kbd(":") #kbd("/")])
  pin(30pt, 115pt, key-label[#kbd("Enter") #kbd("Esc")])
  // normal <-> visual
  line-arrow((155pt, 105pt), (192pt, 140pt), color: accent)
  line-arrow((210pt, 140pt), (170pt, 103pt), color: accent)
  pin(156pt, 128pt, key-label[#kbd("v") #kbd("V")])
  pin(218pt, 115pt, key-label[#kbd("Esc")])
  pin(..n, mode-box([Normal], [move, delete, copy, paste], on: on == "normal"))
  pin(..i, mode-box([Insert], [type text], on: on == "insert"))
  pin(..c, mode-box([Command line], [`:w`, `:q`, `/text`], on: on == "command"))
  pin(..v, mode-box([Visual], [select text], on: on == "visual"))
})

// the last line of a vim screenshot (760 x 90 pixels), with the mode
// underlined from pixel `from` to pixel `to` and a label after it
#let mode-line(path, from, to, label, dashed: false) = box(width: 75%, radius: 4pt, clip: true, {
  image(path, width: 100%)
  let x(px) = px / 760 * 100%
  place(top + left, dx: x(from), dy: 88%, line(
    length: x(to - from),
    stroke: (paint: changed, thickness: 1.2pt, dash: if dashed { "dashed" } else { none }),
  ))
  place(top + left, dx: x(to) + 0.6em, dy: 52%, text(size: 0.75em, fill: changed, weight: "bold")[#arr("←") #label])
})

#slide[
  == `vim` is Modal
  The same key does different things in different _modes_

  #toolbox.side-by-side(columns: (5fr, 6fr), gutter: 1em)[
    #only(1, vim-modes("normal"))
    #only(2, vim-modes("insert"))
    #only(3, vim-modes("command"))
    #only("4-", vim-modes("visual"))
  ][
    #only(1)[
      #screenshot("img/editors/vim_normal.png", width: 100%)
      #v(-0.4em)
      #align(center, mode-line("img/editors/vim_normal_line.png", 22, 229, [empty: Normal], dashed: true))
      #v(-0.3em)
      #text(size: 0.75em)[*Normal*: the last line is empty, the cursor is on a character]
    ]
    #only(2)[
      #screenshot("img/editors/vim_insert.png", width: 100%)
      #v(-0.4em)
      #align(center, mode-line("img/editors/vim_insert_line.png", 22, 229, [mode]))
      #v(-0.3em)
      #text(size: 0.75em)[*Insert*: `-- INSERT --` on the last line, the typed text goes into the file]
    ]
    #only(3)[
      #screenshot("img/editors/vim_command.png", width: 100%)
      #v(-0.4em)
      #align(center, mode-line("img/editors/vim_command_line.png", 22, 92, [command line]))
      #v(-0.3em)
      #text(size: 0.75em)[*Command line*: the cursor moves to the last line, #kbd("Enter") runs `:wq`]
    ]
    #only("4-")[
      #screenshot("img/editors/vim_visual.png", width: 100%)
      #v(-0.4em)
      #align(center, mode-line("img/editors/vim_visual_line.png", 22, 320, [mode]))
      #v(-0.3em)
      #text(size: 0.75em)[*Visual*: `-- VISUAL LINE --`, lines 6 and 7 are selected]
    ]
  ]

  #v(1fr)
  #only(1)[💡 `vim` starts in *Normal* mode: the keys are *commands*, #kbd("d") does not type a `d`, it deletes]
  #only(2)[💡 #kbd("i") inserts before the cursor, #kbd("a") appends after it, #kbd("o") opens a new line; #kbd("Esc") goes back]
  #only(3)[💡 #kbd(":") starts a command, e.g. `:w` save, `:q` quit, `:wq` both, `:q!` quit without saving]
  #only(4)[💡 #kbd("v") selects characters, #kbd("V") whole lines; then #kbd("d") deletes or #kbd("y") copies the selection]
  #only("5-")[💡 always look at the *last line* to know the mode; lost? press #kbd("Esc") a few times: Normal mode]
]

// ----- moving in vim -----

#let main-c-lines = (
  "#include \"lib.h\"",
  "#include \"print.h\"",
  "",
  "int main(void)",
  "{",
  "    int total = sum(MAX);",
  "    print_result(\"sum\", total);",
  "    return 0;",
  "}",
)

// main.c with a block cursor at `at` = (row, column), from 0, and the
// previous place of the cursor `from`, drawn as an orange outline
#let cursor-code(at, from: none) = block(
  fill: luma(240),
  radius: 0.3em,
  inset: 0.6em,
  width: 100%,
  text(font: mono, size: 0.75em, {
    for (r, l) in main-c-lines.enumerate() {
      let chars = l.clusters()
      let n = calc.max(chars.len(), if at.at(0) == r { at.at(1) + 1 } else { 0 })
      box(width: 2em, text(fill: luma(150), str(r + 1)))
      for c in range(n) {
        let ch = if c < chars.len() { chars.at(c) } else { " " }
        if (r, c) == at {
          box(fill: changed, outset: (y: 2pt), text(fill: white, ch))
        } else if from != none and (r, c) == from {
          box(stroke: 1pt + changed, outset: (y: 1.5pt), ch)
        } else { ch }
      }
      linebreak()
    }
  }),
)

// (keys, cursor, explanation)
#let move-steps = (
  (none, (5, 4), [Normal mode, the cursor is on `int`, line 6]),
  ("l", (5, 5), [#kbd("l") or #kbd("→") one character to the right]),
  ("j", (6, 5), [#kbd("j") or #kbd("↓") one line down, the same column]),
  ("k", (5, 5), [#kbd("k") or #kbd("↑") one line up]),
  ("h", (5, 4), [#kbd("h") or #kbd("←") one character to the left]),
  ("w", (5, 8), [#kbd("w") #arr("→") to the next *word*: `total`]),
  ("$", (5, 24), [#kbd("$") #arr("→") to the end of the line]),
  ("0", (5, 0), [#kbd("0") #arr("←") to the start of the line]),
  ("G", (8, 0), [#kbd("G") #arr("↓") to the last line]),
  ("gg", (0, 0), [#keys("g", "g") #arr("↑") to the first line]),
)

#slide[
  == Moving in `vim`
  In Normal mode, the hands stay on the letters

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #for (i, (k, _, _)) in move-steps.enumerate() {
      only(if i == move-steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }, align(
        center,
        move-keys(("h", "←"), ("j", "↓"), ("k", "↑"), ("l", "→"), on: k),
      ))
    }
    #v(0.4em)
    #set text(size: 0.85em)
    - #kbd("h") is the leftmost, #kbd("l") the rightmost
    - a count repeats a move: #keys("5", "j") is 5 lines down
    - #kbd("h") #kbd("j") #kbd("k") #kbd("l") also work in `less`, `man`, `helix`, and in VS Code and Zed with their `vim` modes
  ][
    #for (i, (k, at, note)) in move-steps.enumerate() {
      let from = if i > 0 { move-steps.at(i - 1).at(1) } else { none }
      only(if i == move-steps.len() - 1 { str(i + 1) + "-" } else { i + 1 })[
        // the key pressed at this step, large and highlighted
        #let arrow-of = (h: "←", j: "↓", k: "↑", l: "→")
        #let pressed = if k == none { hide(text(size: 18pt, kbd-on("g"))) } else if k in arrow-of {
          text(size: 18pt)[#kbd-on(k) #text(size: 0.5em, fill: luma(110))[or] #kbd-on(arrow-of.at(k))]
        } else {
          text(size: 18pt, k.clusters().map(kbd-on).join(h(0.25em)))
        }
        #grid(
          columns: (auto, auto),
          column-gutter: 0.6em,
          align: horizon,
          text(size: 0.8em, fill: luma(110))[#if k == none [start] else [pressed:]], pressed,
        )
        #v(0.2em)
        #cursor-code(at, from: from)
        #note
      ]
    }
  ]
]

#slide[
  == `vim` Survival Keys
  In Normal mode

  // one group of keys: a card with the same key column width everywhere
  #let group(..rows) = key-table(size: 0.9em, gap: 0.38em, key-width: 6em, header: (), rows.pos())
  // all the groups as a grid of cards, all of the same size
  #let card-grid(columns: 3, ..groups) = layout(size => {
    let gutter = 0.8em
    let w = (size.width - gutter * (columns - 1)) / columns
    let card(body, height: auto) = block(
      width: w,
      height: height,
      fill: accent.lighten(95%),
      stroke: 0.6pt + accent.lighten(75%),
      radius: 0.4em,
      inset: (x: 0.4em, y: 0.15em),
      body,
    )
    let h = calc.max(..groups.pos().map(g => measure(card(g)).height))
    grid(columns: columns, gutter: gutter, ..groups.pos().map(g => card(g, height: h)))
  })

  #card-grid(
    group(
      ([save and quit], none),
      ([`:w`], [save]),
      ([`:q`], [quit]),
      ([`:wq`], [save and quit]),
      ([`:q!`], [quit, don't save]),
    ),
    group(
      ([move], none),
      ([#keys("h", "j", "k", "l")], [#arrows("←↓↑→")]),
      ([#keys("←", "↓", "↑", "→")], [also work]),
      ([#kbd("w") / #kbd("b")], [next / prev word]),
      ([#kbd("0") / #kbd("$")], [start / end of line]),
      ([#keys("g", "g") / #kbd("G")], [first / last line]),
    ),
    group(
      ([edit], none),
      ([#kbd("x")], [delete a char]),
      ([#keys("d", "d")], [delete the line]),
      ([#kbd("u")], [undo]),
      ([#ctrl("R")], [redo]),
    ),
    group(
      ([insert text], none),
      ([#kbd("i") / #kbd("a")], [before / after]),
      ([#kbd("o") / #kbd("O")], [new line #arr("↓") / #arr("↑")]),
      ([#kbd("Esc")], [back to Normal]),
    ),
    group(
      ([search], none),
      ([`/text`], [search forward]),
      ([#kbd("n") / #kbd("N")], [next / prev match]),
      ([#keys("4", "2", "G")], [go to line 42]),
    ),
    group(
      ([copy and paste], none),
      ([#kbd("v")], [select (_Visual_)]),
      ([#kbd("y") / #kbd("d")], [copy / cut]),
      ([#kbd("p")], [paste]),
    ),
  )
]

// a line of code with a block cursor at `at` (from 0), and an optional
// range `sel` (from, to) that is highlighted
#let code-line(s, at: none, sel: none, color: changed) = {
  let chars = s.clusters()
  box(fill: luma(240), inset: (x: 0.5em, y: 0.4em), radius: 0.3em, text(font: mono, size: 0.8em, {
    for (i, ch) in chars.enumerate() {
      let in-sel = sel != none and i >= sel.at(0) and i < sel.at(1)
      if i == at {
        box(fill: black, outset: (y: 2pt), text(fill: white, ch))
      } else if in-sel {
        box(fill: color.lighten(70%), outset: (y: 2pt), ch)
      } else { ch }
    }
    if at != none and at >= chars.len() { box(fill: black, outset: (y: 2pt), " ") }
  }))
}

// the parts of an editor command, one color for each role
#let role-colors = (
  verb: changed,
  count: rgb("7b1fa2"),
  motion: accent,
  object: ok-color,
  select: rgb("ad1457"),
)
#let role-names = (
  verb: "verb",
  count: "count",
  motion: "motion",
  object: "text object",
  select: "selection",
)

// a word of the explanation, in the color of its role, e.g. #role("verb")[d]elete
#let role(r, body) = text(fill: role-colors.at(r), weight: "bold", body)

// the name of a role as a colored pill, e.g. #pill("verb")
#let pill(r, body: auto) = {
  let c = role-colors.at(r)
  box(
    fill: c.lighten(85%),
    stroke: 1pt + c,
    radius: 0.3em,
    inset: (x: 0.45em, y: 0.2em),
    outset: (y: 0.1em),
    text(fill: c.darken(15%), weight: "bold", if body == auto { role-names.at(r) } else { body }),
  )
}

// a part of a command: its keys, underlined in the color of the role,
// with the name of the role under them
#let part(r, body, label: auto) = {
  let c = role-colors.at(r)
  stack(
    dir: ttb,
    spacing: 0.3em,
    box(stroke: (bottom: 2pt + c), inset: (x: 0.1em, bottom: 0.35em), body),
    text(size: 0.6em, fill: c.darken(10%), weight: "bold", if label == auto { role-names.at(r) } else { label }),
  )
}

// a command split in its parts, e.g. #sentence(part("verb", kbd("d")), part("motion", kbd("w")))
#let sentence(..parts) = {
  let ps = parts.pos()
  grid(columns: ps.len(), column-gutter: 0.3em, align: center + top, ..ps)
}

#slide[
  == The Language of `vim`
  A command is a sentence:

  #align(center, text(size: 1.15em)[
    #pill("verb") #h(0.3em) + #h(0.3em) #pill("count", body: "(count)") #h(0.3em) + #h(0.3em) #pill("motion") #h(0.2em) or #h(0.2em) #pill("object")
  ])

  #set text(size: 0.9em)
  #align(center)[
    #table(
      columns: (auto, 1fr, auto, auto),
      align: (center + horizon, left + horizon, left + horizon, left + horizon),
      inset: (x: 0.45em, y: 0.35em),
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*keys*], [*meaning*], [*before*], [*after*]),
      sentence(part("verb", kbd("d")), part("motion", kbd("w"))),
      [#role("verb")[d]elete a #role("motion")[w]ord],
      code-line("int total = sum(MAX);", at: 4, sel: (4, 10)),
      code-line("int = sum(MAX);", at: 4),

      uncover("2-", sentence(part("verb", kbd("d")), part("count", kbd("3")), part("motion", kbd("w")))),
      uncover("2-")[#role("verb")[d]elete #role("count")[3] #role("motion")[w]ords],
      uncover("2-", code-line("int total = sum(MAX);", at: 4, sel: (4, 15))),
      uncover("2-", code-line("int (MAX);", at: 4)),

      uncover("3-", sentence(part("verb", kbd("c")), part("motion", kbd("$")))),
      uncover("3-")[#role("verb")[c]hange to #role("motion")[line end]],
      uncover("3-", code-line("int total = sum(MAX);", at: 12, sel: (12, 21))),
      uncover("3-", [#code-line("int total = ", at: 12) #tag[Insert]]),

      uncover("4-", sentence(part("verb", kbd("c")), part("object", keys("i", "\"")))),
      uncover("4-")[#role("verb")[c]hange #role("object")[*i*\nside `"`]],
      uncover("4-", code-line("print_result(\"sum\", total);", at: 15, sel: (14, 17))),
      uncover("4-", [#code-line("print_result(\"\", total);", at: 14) #tag[Insert]]),

      uncover("5-", sentence(part("verb", kbd("y")), part("object", keys("i", "(")))),
      uncover("5-")[#role("verb")[y]ank (copy) #role("object")[inside `()`]],
      uncover("5-", code-line("int total = sum(MAX);", at: 16, sel: (16, 19))),
      uncover("5-")[`MAX` is copied, #kbd("p") pastes it],
    )
  ]

  #v(1fr)
  #uncover("6-")[
    #callout[verbs: #kbd("d") delete, #kbd("c") change, #kbd("y") yank, #kbd(">") indent #h(0.6em) | #h(0.6em) doubled, it acts on the line: #keys("d", "d"), #keys("y", "y"), #keys(">", ">")]
  ]
]

#slide[
  == `emacs`
  Not modal: commands are key chords, `C-` is #kbd("Ctrl"), `M-` is #kbd("Alt") (_Meta_)

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #screenshot("img/editors/emacs.png", width: 100%)
    ```terminal
    $ emacs -nw main.c
    ```
  ][
    #key-table(size: 0.7em, (
      ([move], none),
      ([#ctrl("B") / #ctrl("F")], [#arrows("←→") _back_ / _forward_]),
      ([#ctrl("P") / #ctrl("N")], [#arrows("↑↓") _previous_ / _next_ line]),
      ([#ctrl("A") / #ctrl("E")], [start / end of the line]),
      ([files], none),
      ([#ctrl("X") #ctrl("F")], [open a file]),
      ([#ctrl("X") #ctrl("S")], [save]),
      ([#ctrl("X") #ctrl("C")], [quit]),
      ([edit], none),
      ([#ctrl("K")], [cut (_kill_) to the end of the line]),
      ([#ctrl("Y")], [paste (_yank_)]),
      ([#ctrl("/")], [undo]),
      ([other], none),
      ([#ctrl("S")], [search]),
      ([#ctrl("G")], [cancel the current command]),
      ([#alt("X")], [run any command by name]),
    ))
  ]
]

#slide[
  == `helix`
  Like `vim`, but *select first*, then act

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    // step 2: the menu that helix shows after Space (a subset of it),
    // drawn over the screenshot, in the colors of the default theme
    #let space-menu = box(
      fill: rgb("281733"),
      stroke: 0.6pt + rgb("5a5977"),
      inset: (x: 0.6em, y: 0.5em),
      text(font: mono, size: 5.5pt, fill: rgb("dbbfef"), {
        align(center, text(fill: white, weight: "bold")[Space])
        v(0.2em)
        grid(
          columns: 2,
          align: left,
          column-gutter: 1em,
          row-gutter: 0.45em,
          ..(
            ("f", "Open file picker"),
            ("b", "Open buffer picker"),
            ("s", "Open symbol picker"),
            ("a", "Perform code action"),
            ("y", "Yank selections to clipboard"),
            ("p", "Paste clipboard after selections"),
            ("/", "Global search in workspace folder"),
            ("k", "Show docs for item under cursor"),
            ("r", "Rename symbol"),
            ("c", "Comment/uncomment selections"),
            ("?", "Open command palette"),
          )
            .map(((k, d)) => (text(fill: white, k), d))
            .flatten(),
        )
      }),
    )
    #box({
      screenshot("img/editors/helix.png", width: 100%)
      only(2, place(bottom + right, dx: -1.5%, dy: -10.5%, space-menu))
    })
    #text(size: 0.75em)[#alternatives[#kbd("w") selected the word `total`: you *see* what the next command will change][#kbd-on("Space") opens a menu: the next key picks the command]]
  ][
    #set text(size: 0.85em)
    #table(
      columns: (1fr, auto, auto),
      align: (left + horizon, center + horizon, center + horizon),
      inset: 0.35em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([], [*vim*], [*helix*]),
      [move #arrows("←↓↑→")], [#keys("h", "j", "k", "l")], [#keys("h", "j", "k", "l")],
      [delete a word], [#keys("d", "w")], [#keys("w", "d")],
      [delete the line], [#keys("d", "d")], [#keys("x", "d")],
      [change inside `"`], [#keys("c", "i", "\"")], [#keys("m", "i", "\"", "c")],
      [select the next match], [], [#keys("*", "n")],
      [one cursor per match], [], [#keys("%", "s")],
      [add a cursor below], [], [#kbd("C")],
      [go to definition], [_LSP setup_], [#keys("g", "d")],
      [show documentation], [_LSP setup_], [#alternatives[#keys("Space", "k")][#kbd-on("Space")#h(0.15em)#kbd("k")]],
      [save / quit], [`:w` `:q`], [`:w` `:q`],
    )
    #text(size: 0.85em)[#alternatives[#kbd("Space")][#kbd-on("Space")] opens a menu with all the commands]
  ]
]

#slide[
  == The Language of `helix`
  A command is: first *select*, then *act* on the selection

  #align(center, text(size: 1.15em)[
    #pill("motion") #h(0.2em) or #h(0.2em) #pill("object") #h(0.2em) or #h(0.2em) #pill("select") #h(0.5em) #draw-arrow(length: 1.6em) #h(0.5em) #pill("verb")
  ])

  #set text(size: 0.85em)
  #let sel-cell(..lines) = stack(spacing: 0.3em, ..lines.pos())
  #align(center)[
    #table(
      columns: (auto, 1fr, auto, auto),
      align: (center + horizon, left + horizon, left + horizon, left + horizon),
      inset: (x: 0.45em, y: 0.35em),
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*keys*], [*meaning*], [*selected*], [*after*]),
      sentence(part("motion", kbd("w")), part("verb", kbd("d"))),
      [select a #role("motion")[w]ord, #role("verb")[d]elete it],
      code-line("int total = sum(MAX);", at: 9, sel: (4, 10)),
      code-line("int = sum(MAX);", at: 4),

      uncover("2-", sentence(part("motion", keys("t", ";")), part("verb", kbd("d")))),
      uncover("2-")[select #role("motion")[*t*\ill `;`], #role("verb")[d]elete it],
      uncover("2-", code-line("int total = sum(MAX);", at: 19, sel: (4, 20))),
      uncover("2-", code-line("int ;", at: 4)),

      uncover("3-", sentence(
        part("select", kbd("v"), label: "extend"),
        part("motion", keys("w", "w")),
        part("verb", kbd("d")),
      )),
      uncover("3-")[#role("select")[*v*\isual] #role("motion")[2 words], #role("verb")[d]elete],
      uncover("3-", code-line("int total = sum(MAX);", at: 11, sel: (4, 12))),
      uncover("3-", code-line("int sum(MAX);", at: 4)),

      uncover("4-", sentence(part("object", keys("m", "i", "\"")), part("verb", kbd("c")))),
      uncover("4-")[#role("object")[*m*\atch *i*\nside `"`], #role("verb")[c]hange],
      uncover("4-", code-line("print_result(\"sum\", total);", at: 16, sel: (14, 17))),
      uncover("4-", [#code-line("print_result(\"\", total);", at: 14) #tag[Insert]]),

      uncover("5-", sentence(
        part("select", kbd("%"), label: "file"),
        part("select", [#kbd("s") `total` #kbd("⏎")], label: "each match"),
        part("verb", kbd("c")),
      )),
      uncover("5-")[#role("select")[every `total`] in the file, #role("verb")[c]hange all],
      uncover("5-", sel-cell(
        code-line("int total = sum(MAX);", at: 8, sel: (4, 9)),
        code-line("print_result(\"sum\", total);", at: 24, sel: (20, 25)),
      )),
      uncover("5-", sel-cell(
        code-line("int count = sum(MAX);", at: 8),
        code-line("print_result(\"sum\", count);", at: 24),
      )),
    )
  ]

  #v(1fr)
  #uncover("6-")[
    #callout[`vim`: #role("verb")[verb] then #role("motion")[motion] (#keys("d", "w")) #h(0.6em) | #h(0.6em) `helix`: #role("motion")[selection] then #role("verb")[verb] (#keys("w", "d")): you see what will change]
  ]
]
