#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Exit Codes #text(size: 10pt, weight: "regular")[\ _How a command says if it worked_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.4 - _Exit Codes_
      - Section 11.5 - _Conditionals_ (`&&` and `||`)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.5.3 - _Înlănțuirea comenzilor_
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == Exit Code
  Every process ends with a number, `0` means _success_

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - a process ends with an _exit code_ between `0` and `255`, ```c return 0;``` from `main` in C
    #uncover("2-")[#block[- ```bash $?``` - the exit code of the last command]]
    #uncover("3-")[#block[- `0` - *success*, anything else - an *error*]]
    #uncover("4-")[#block[- one way to succeed, many ways to fail: the number tells *which* error (`man grep`, `EXIT STATUS`)]]
    #uncover("6-")[#block[- `true` and `false` - commands that do nothing, just end with `0` and `1`]]
    #uncover("7-")[#block[- a script ends with ```bash exit N```]]
  ][
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 7, 11), start: 3, full: false)[```terminal
    $ grep -q kiwi fruits.txt; echo $?
    0
    $ grep -q mango fruits.txt; echo $?
    1
    $ grep apple nope.txt; echo $?
    grep: nope.txt: No such file or directory
    2
    $ true; echo $?
    0
    $ false; echo $?
    1
    ```]
  ]

  #v(0.3em)
  #only(3)[💡 `grep` - `0`: found]
  #only(4)[💡 `grep` - `1`: not found]
  #only(5)[💡 `grep` - `2`: an error, for example a missing file]
  #only("7-")[
    #shell-first[the exit code is how a command answers *yes* or *no*: the shell uses it for every decision]
  ]
]

// one row of the && / || schematic: the first command, its exit code,
// and what happens to the second one (runs or is skipped)
#let chain-row(first, op, second, code, runs) = (
  raw(first, lang: "bash"),
  exit-code(code),
  text(font: mono, weight: "bold", fill: accent, op),
  if runs { raw(second, lang: "bash") } else { text(fill: luma(160), strike(raw(second, lang: "bash"))) },
  if runs { text(fill: ok-color)[runs] } else { text(fill: luma(140))[skipped] },
)

#slide[
  == `&&` and `||`
  Run the next command depending on the exit code

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - ```bash a && b``` - run `b` only if `a` *succeeded* (`0`), _and then_
    #uncover("3-")[#block[- ```bash a || b``` - run `b` only if `a` *failed* (not `0`), _or else_]]
    #uncover("5-")[#block[- the exit code of the line is the one of the last command that ran]]
  ][
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 7), full: false)[```terminal
    $ grep -q kiwi fruits.txt && echo "we have kiwi"
    we have kiwi
    $ mkdir Movies && echo "created"
    mkdir: cannot create directory ‘Movies’: File exists
    $ grep -q mango fruits.txt || echo "no mango"
    no mango
    $ cd /home/alice/Movies || exit 1
    ```]
  ]

  #v(0.5em)
  #set text(size: 0.8em)
  #align(center, grid(
    columns: 5,
    column-gutter: 0.8em,
    row-gutter: 0.6em,
    align: horizon,
    ..chain-row("grep -q kiwi fruits.txt", "&&", "echo \"we have kiwi\"", 0, true).map(c => uncover("1-", c)),
    ..chain-row("mkdir Movies", "&&", "echo \"created\"", 1, false).map(c => uncover("2-", c)),
    ..chain-row("grep -q mango fruits.txt", "||", "echo \"no mango\"", 1, true).map(c => uncover("3-", c)),
    ..chain-row("cd /home/alice/Movies", "||", "exit 1", 0, false).map(c => uncover("4-", c)),
  ))

  #only("5-")[
    #set text(size: 1.05em)
    💡 ```bash cd dir || exit 1``` - a common line in scripts: stop if something went wrong
  ]
]
