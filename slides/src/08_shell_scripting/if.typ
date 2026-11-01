#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Conditions: `if` #text(size: 10pt, weight: "regular")[\ _Run a command, look at its exit code_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.5 - _Conditionals_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == `if` Syntax
  The condition is a *command*

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.15em)
    #highlight-code(("all", (1,), (2,), lines-range(3, 4), lines-range(5, 6), (7,), "all", "all"))[```bash
if command; then
    commands
elif other_command; then
    commands
else
    commands
fi
```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- `if` runs the command and looks at its *exit code*]]
    #uncover("3-")[#block[- `then` - the commands that run if it ended with `0` (_true_)]]
    #uncover("4-")[#block[- `elif` - another command to try, optional, as many as needed]]
    #uncover("5-")[#block[- `else` - when no command ended with `0`, optional]]
    #uncover("6-")[#block[- `fi` - `if` backwards, the end]]
  ]

  #v(0.3em)
  #only("7-")[#one-liner(("if command; then commands; elif command; then commands; else commands; fi",), ("if grep -q kiwi fruits.txt; then echo kiwi; elif grep -q apple fruits.txt; then echo apple; fi",))]

  // the usual mistake: in the shell, 0 is true
  #only("8-")[
    #popup[
      #align(center, text(size: 1.6em, weight: "bold", fill: fail-color)[⚠️ in the shell, `0` is _true_!])
      #v(-0.2em)
      #align(center, grid(
        columns: (auto, auto, auto),
        column-gutter: 0.8em,
        row-gutter: 0.5em,
        align: horizon,
        code-badge(0, size: 2em), draw-arrow(length: 1.5em, color: ok-color), text(size: 1.2em, fill: ok-color)[*true* - success, `then` runs],
        code-badge(1, size: 2em), draw-arrow(length: 1.5em, color: fail-color), text(size: 1.2em, fill: fail-color)[*false* - an error (`1` ... `255`)],
      ))
      #v(-0.2em)
      #align(center, label[the opposite of C, where `0` is false])
    ]
  ]
]

#let kiwi-code = "#!/bin/bash
if grep -q kiwi fruits.txt; then
    echo \"we have kiwi\"
else
    echo \"no kiwi\"
fi"

#slide[
  == 🐞 `if` Runs a Command
  The condition is a command, its exit code chooses the branch

  #debug-run(kiwi-code, command: "./kiwi.sh", blocks: true, files: (("fruits.txt", fruits-lines),), (
    (line: 2, part: "grep -q kiwi fruits.txt", run: "grep -q kiwi fruits.txt", match: "kiwi", status: 0,
      note: [💡 `grep -q` prints nothing, `if` only looks at its exit code]),
    (line: 3, run: "echo \"we have kiwi\"", status: 0, out: ("we have kiwi",),
      note: [💡 `0` - found, the `then` branch runs]),
  ))
]

#let compare-code = "#!/bin/bash
a=7
b=3
if $a > $b; then
    echo \"a is bigger\"
else
    echo \"a is not bigger\"
fi"

#slide[
  == 🐞 Comparing Variables?
  What you might expect to work

  #debug-run(compare-code, command: "./compare.sh", blocks: true, (
    (line: 2, run: "a=7", vars: (a: "7")),
    (line: 3, run: "b=3", vars: (b: "3"),
      note: [💡 in C, `a > b` would be true: we expect `then`]),
    (line: 4, part: "$a > $b", run: "7 > 3", status: 127, out: ("./compare.sh: line 4: 7: command not found",),
      note: [❌ the condition is a *command line*: the command `7`, its output redirected (`>`) to a *new file* named `3`]),
    (line: 7, run: "echo \"a is not bigger\"", status: 0, out: ("a is not bigger",),
      note: [❌ *wrong*: `7` is bigger, but the condition failed - there is no program `7`]),
  ))

  // why: bash was made to run commands
  #only("5-")[
    #popup(color: accent, fill: white)[
      #align(center, text(size: 1.5em, weight: "bold", fill: accent)[🐚 `bash` was made to *run commands*])
      #v(-0.3em)
      #align(center, text(size: 1.1em)[every line is a command line: the first word is the *command*, `>` is a *redirect*])
      #v(-0.3em)
      #align(center, box(text(size: 1.2em, words(("7", "cmd"), (">", "redir"), ("3", "redir")))))
      #v(-0.3em)
      #align(center, label[comparing numbers came later: with commands (`test`, `[`) or with `(( ))`])
    ]
  ]
]
