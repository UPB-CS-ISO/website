#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Arithmetic #text(size: 10pt, weight: "regular")[\ _Math in a language made of text_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.10 - _Important Shell Script Utilities_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

#let naive-code = "#!/bin/bash
a=2
b=3
sum=$a+$b
echo $sum
$a + $b"

#slide[
  == 🐞 Adding Two Numbers?
  What you might expect to work

  #debug-run(naive-code, size: 1.25em, columns: (2fr, 3fr), command: "./math.sh", blocks: true, (
    (line: 2, run: "a=2", vars: (a: "2")),
    (line: 3, run: "b=3", vars: (b: "3")),
    (line: 4, run: "sum=2+3", vars: (sum: "2+3"),
      note: [❌ the variables are replaced, `+` is just a character: `sum` holds the *text* `2+3`]),
    (line: 5, run: "echo 2+3", status: 0, out: ("2+3",),
      note: [❌ `echo` prints the text, nothing was computed]),
    (line: 6, run: "2 + 3", status: 127, out: ("./math.sh: line 6: 2: command not found",),
      note: [❌ a line starts with a *command*: the shell looks for a program named `2`]),
  ))
]

#slide[
  == Text, Not Numbers
  ```bash a=2``` and ```bash b=3```

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.3em)
    #reveal-terminal(before: none, lines: (3, 5, 7, 9), full: false)[```terminal
    $ a=2; b=3
    $ echo $a+$b
    2+3
    $ echo $a + $b
    2 + 3
    $ $a + $b
    bash: 2: command not found
    $ c=$a+$b; echo $c
    2+3
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      #label[the shell replaces the variables, `echo` receives] \
      #words(("echo", "cmd"), ("2+3", "new"))

      💡 *one* word: `$a`, the text `+`, `$b`
    ]
    #only(2)[
      #label[the shell replaces the variables, `echo` receives] \
      #words(("echo", "cmd"), ("2", "new"), ("+", "new"), ("3", "new"))

      💡 *three* words, `echo` prints them with a space between
    ]
    #only(3)[
      #label[the shell replaces the variables and runs] \
      #words(("2", "cmd"), "+", "3")

      💡 the first word is the *command*: there is no program `2`
    ]
    #only("4-")[
      💡 a variable holds *text*: `c` is the text `2+3`
    ]
  ]

  #v(0.5em)
  #uncover("3-")[
    #shell-first[bash was made to run commands, not to do math: `+` is just a character and a line always starts with a command]
  ]
]

#slide[
  == Arithmetic Syntax
  The shell computes only inside `(( ))`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.35em)
    #highlight-code(((1,), (2,), (3,), (4,), "all"))[```bash
((n = n - 1))
((count++))
sum=$((a + b))
echo $((a * 2 + 1))
```]
    #uncover("3-")[
      #set text(size: 0.65em)
      #v(0.3em)
      #grid(
        columns: (auto, auto, auto),
        column-gutter: 0.6em,
        row-gutter: 0.6em,
        align: horizon,
        raw("$( command )", lang: "bash"), draw-arrow(length: 1.5em), [the *output* of the command],
        raw("$(( expression ))", lang: "bash"), draw-arrow(length: 1.5em, color: changed), [the *result* of the expression],
      )
    ]
  ][
    #set text(size: 0.9em)
    #uncover("1-")[#block[- ```bash (( expression ))``` - a *command* that computes: C-like operators `+ - * / % **`, `( )`, variables without `$`]]
    #uncover("2-")[#block[- `=`, `+=`, `-=`, `++`, `--` change a variable]]
    #uncover("3-")[#block[- ```bash $(( expression ))``` - like ```bash $( command )```, but for an expression: the shell computes it and puts the *result* in its place, as text]]
    #uncover("4-")[#block[- anywhere in a command line, also inside `"..."`]]
  ]

  #bash-only[`(( ))` as a command, `++`, `--`]

  // the warning, as a popup on top of the slide, with a soft shadow
  #only("5-")[
    #let card = block(
      fill: rgb("fff8e1"),
      stroke: 2.5pt + fail-color,
      radius: 0.6em,
      inset: (x: 1.4em, y: 0.9em),
      align(center)[
        #text(size: 1.8em, weight: "bold", fill: fail-color)[⚠️ integers only!]
        #v(-0.3em)
        #text(size: 1.2em)[```bash $((7 / 2))``` is `3` #h(1em) no `3.5`, no `0.5`]
      ],
    )
    #place(center + horizon, dy: 1.5em, rotate(-3deg, context {
      let size = measure(card)
      box({
        place(dx: 7pt, dy: 7pt, box(width: size.width, height: size.height, radius: 0.6em, fill: luma(0).transparentize(80%)))
        card
      })
    }))
  ]
]

#let arith-code = "#!/bin/bash
a=2
b=3
sum=$((a + b))
echo \"sum is $sum\"
echo $((a * b + 1))
echo \"$a + $b = $((a + b))\""

#slide[
  == 🐞 Arithmetic
  The shell computes inside ```bash $(( ))```, no program is started

  #debug-run(arith-code, size: 1.35em, columns: (3fr, 2fr), command: "./math.sh", (
    (line: 2, run: "a=2", vars: (a: "2")),
    (line: 3, run: "b=3", vars: (b: "3")),
    (line: 4, compute: "$((a + b))", info: [computes `2 + 3` = `5`],
      note: [💡 inside ```bash $(( ))``` the shell itself does math, the variables need no `$`]),
    (line: 4, run: "sum=5", vars: (sum: "5"),
      note: [💡 the result takes its place, as text]),
    (line: 5, run: "echo \"sum is 5\"", status: 0, out: ("sum is 5",)),
    (line: 6, compute: "$((a * b + 1))", info: [computes `2 * 3 + 1` = `7`]),
    (line: 6, run: "echo 7", status: 0, out: ("7",)),
    (line: 7, compute: "$((a + b))", info: [computes `2 + 3` = `5`],
      note: [💡 anywhere in a command line, also inside `"..."`]),
    (line: 7, run: "echo \"2 + 3 = 5\"", status: 0, out: ("2 + 3 = 5",),
      note: [💡 one parameter for `echo`: the text, with the variables and the result in it]),
  ))
]

#slide[
  == `$( )` or `$(( ))`?
  One parenthesis runs a command, two compute

  // one side of the comparison: what you type, what happens, what runs
  #let side(title, typed, steps, runs, out) = [
    #text(weight: "bold", fill: accent, title)
    #v(-0.2em)
    #align(center, text(size: 1.4em, typed))
    #v(-0.2em)
    #for (who, what) in steps [
      #label(who) #h(0.3em) #what \
    ]
    #label[then the shell runs] #h(0.3em) #box(runs)
    #v(-0.2em)
    #set text(size: 1.1em)
    #terminal(out)
  ]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 2em)[
    #side([command substitution],
      raw("echo $(a+b)", lang: "bash"),
      (([a copy of `bash` runs], words(("a+b", "cmd"))),
       ([it prints], [nothing, `a+b` is not a program])),
      words(("echo", "cmd")),
      "$ echo $(a+b)\nbash: a+b: command not found\n")
  ][
    #uncover("2-")[
      #side([arithmetic],
        raw("echo $((a+b))", lang: "bash"),
        (([no `$` needed], [inside `(( ))`, `a` means the value of `a`]),
         ([the shell computes], [`2 + 3` = `5`, no program is started])),
        words(("echo", "cmd"), ("5", "new")),
        "$ echo $((a+b))\n5")
    ]
  ]

  #v(0.3em)
  #only("3-")[
    #takeaway[```bash $(command)``` - the *output* of a command, ```bash $((expression))``` - the *result* of a computation][]
  ]
]
