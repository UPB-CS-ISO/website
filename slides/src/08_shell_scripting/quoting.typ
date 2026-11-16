#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Variables Expansion #text(size: 10pt, weight: "regular")[\ _How many words does a variable become?_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.2 - _Quoting and Literals_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

#slide[
  == `IFS`
  _Internal Field Separator_: where the shell cuts a value into words

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - `IFS` - a variable of the shell
    - its characters are the _separators_
    - default: *space*, *tab* and *newline*
    - used to cut an *unquoted* ```bash $NAME``` (and, later, the line `read` reads)
  ][
    #set text(size: 1.25em)
    #terminal("$ printf '%q\\n' \"$IFS\"\n$' \\t\\n'")
    #v(0.5em)
    #align(center, text(size: 0.8em, ifs-chips("space", "tab", "newline")))
  ]

  #v(0.3em)
  💡 `printf '%q'` shows the invisible characters: a space, `\t` (tab) and `\n` (newline)
]

// the three things the shell does with an unquoted variable, one per row
#let split-row(n, title, body) = grid(
  columns: (1.6em, 7em, 1fr),
  column-gutter: 0.5em,
  align: (center + horizon, left + horizon, left + horizon),
  box(fill: accent, radius: 50%, inset: 0.25em, text(fill: white, weight: "bold", size: 0.8em, str(n))),
  text(weight: "bold", fill: accent, title),
  body,
)

#slide[
  == Splitting a Variable
  An unquoted ```bash $NAME``` is cut at the characters of `IFS`

  #toolbox.side-by-side(columns: (11fr, 9fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #label[the command] \
    #raw("printf '[%s]\\n' $x", lang: "bash")
    #v(0.4em)
    #uncover("2-", split-row(1, [replace], [```bash $x``` #h(0.3em) #ifs-line("Alice   Smith:20", ())]))
    #v(0.2em)
    #uncover("3-", split-row(2, [cut at `IFS`], ifs-line("Alice   Smith:20", blank)))
    #v(0.2em)
    #uncover("4-", split-row(3, [run], words(("printf", "cmd"), "'[%s]\\n'", ("Alice", "new"), ("Smith:20", "new"))))
  ][
    #set text(size: 1.2em)
    #reveal-terminal(before: none, lines: (1, 1, 1, 4, 6), full: false)[```terminal
    $ x="Alice   Smith:20"
    $ printf '[%s]\n' $x
    [Alice]
    [Smith:20]
    $ echo $x
    Alice Smith:20
    ```]
  ]

  #v(0.3em)
  #only(1)[💡 `printf '[%s]\n'` prints every word it gets between `[ ]`, one per line]
  #only(2)[💡 first, the shell puts the *value* of `x` in its place]
  #only(3)[💡 then it cuts the value at space, tab, newline: 3 spaces in a row are *one* cut]
  #only(4)[💡 every piece is a separate word: `printf` gets 2 words]
  #only("5-")[💡 `echo` gets 2 words too, and prints them with *one* space: the 3 spaces are lost]
]

#let spaces-code = "#!/bin/bash
v=\"  a   b  \"
printf '[%s]' $v; echo
IFS=:
v=\"a b::c\"
printf '[%s]' $v; echo
unset IFS
printf '[%s]' $v; echo"

#slide[
  == 🐞 Spaces Are Special
  Many spaces are one cut, every other separator cuts

  #debug-run(spaces-code, size: 1.25em, columns: (1fr, 1fr), command: "./spaces.sh", blocks: true, (
    (line: 1, vars: (IFS: "space tab newline"), tags: (IFS: [default]),
      note: [💡 the script starts, nobody set `IFS`: it has the *default* value, space, tab and newline]),
    (line: 2, run: "v=\"  a   b  \"", vars: (v: "  a   b  ")),
    (line: 3, part: "printf '[%s]' $v", run: "printf '[%s]' a b", status: 0, out: ("[a][b]",),
      note: [💡 cut at the spaces #h(0.3em) #box(baseline: 30%, ifs-line("  a   b  ", blank)) #h(0.3em) many in a row: *one* cut, at the ends: dropped]),
    (line: 4, run: "IFS=:", vars: (IFS: ":"), tags: (IFS: none),
      note: [💡 `IFS` is not the default any more: now only `:` is a separator]),
    (line: 5, run: "v=\"a b::c\"", vars: (v: "a b::c")),
    (line: 6, part: "printf '[%s]' $v", run: "printf '[%s]' 'a b' '' c", status: 0, out: ("[a b][][c]",),
      note: [💡 cut at `:` #h(0.3em) #box(baseline: 30%, ifs-line("a b::c", (":",))) #h(0.3em) `::` makes an *empty* word, the space is a normal character]),
    (line: 7, run: "unset IFS", vars: (IFS: "space tab newline"), tags: (IFS: [not set, default]),
      note: [💡 `IFS` is deleted: when it is *not set*, the shell uses the *default* again]),
    (line: 8, part: "printf '[%s]' $v", run: "printf '[%s]' a b::c", status: 0, out: ("[a][b::c]",),
      note: [💡 cut at the space again #h(0.3em) #box(baseline: 30%, ifs-line("a b::c", blank)) #h(0.3em) `:` is a normal character]),
  ))
]

#slide[
  == Quoting and `IFS`
  `IFS` cuts an unquoted value, quotes keep it one word

  // one cell: the words the command gets, and what printf prints
  #let cell(ws, out) = block(width: 100%, {
    words(..ws)
    v(-0.3em)
    set text(size: 1em)
    terminal(out)
  })

  #align(center, text(size: 1.05em)[```bash x="Alice   Smith:20"``` #h(1.5em) ```bash printf '[%s]\n' $x``` #label[or] ```bash printf '[%s]\n' "$x"```])

  #v(0.2em)
  #grid(
    columns: (auto, 1fr, 1fr),
    column-gutter: 1.2em,
    row-gutter: 0.6em,
    align: (right + horizon, left, left),
    [], text(weight: "bold", fill: accent)[unquoted ```bash $x```], text(weight: "bold", fill: accent)[quoted ```bash "$x"```],
    [#raw("IFS") default \ #label[space, tab, newline]],
    cell((("Alice", "new"), ("Smith:20", "new")), "[Alice]\n[Smith:20]"),
    uncover("2-", cell(("Alice   Smith:20",), "[Alice   Smith:20]")),
    uncover("3-")[#raw("IFS=:")],
    uncover("3-", cell((("Alice   Smith", "new"), ("20", "new")), "[Alice   Smith]\n[20]")),
    uncover("4-", cell(("Alice   Smith:20",), "[Alice   Smith:20]")),
  )

  #v(0.2em)
  #set text(size: 0.9em)
  #only(1)[💡 unquoted: the value is cut at the characters of `IFS` - here the spaces: 2 words]
  #only(2)[💡 quoted: the value is *not* cut, `IFS` does not matter: 1 word, the spaces are kept]
  #only(3)[💡 change `IFS` and the cuts move: now at `:`, the spaces are normal characters]
  #only("4-")[#shell-first[quotes say "one word": put ```bash "$NAME"``` in quotes, unless you *want* it cut]]
]
