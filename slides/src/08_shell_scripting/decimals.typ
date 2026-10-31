#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Operators and Decimals #text(size: 10pt, weight: "regular")[\ _What `(( ))` can compute, and what it cannot_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.10 - _Important Shell Script Utilities_ (`expr`)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

#slide[
  == The Operators of `(( ))`
  The C operators, on integers

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #block(width: 100%, {
      set text(size: 0.75em)
      set table(inset: (x: 0.45em, y: 0.3em))
      table(
        columns: (auto, 1fr, auto),
        table.header([*Operators*], [*Meaning*], [*Example*]),
        [`+ - * /`], [add, subtract, multiply, divide], [```bash $((7 / 2))``` #arrow `3`],
        [`%` `**` #bash-tag], [remainder, power], [```bash $((2 ** 10))``` #arrow `1024`],
        [`< <= > >=` \ `== !=`], [compare: `1` - true, `0` - false], [```bash $((3 > 2))``` #arrow `1`],
        [`&& || !`], [and, or, not], [```bash $((1 && 0))``` #arrow `0`],
        [`& | ^ ~ << >>`], [bits], [```bash $((1 << 4))``` #arrow `16`],
        [`= += -= *= /=` \ `++ --` #bash-tag], [change a variable], [```bash ((x += 2))``` #bash-tag],
        [`c ? a : b`], [`a` if `c` is true, else `b`], [```bash $((5 > 3 ? 10 : 20))``` #arrow `10`],
        [`( )`], [group], [```bash $(( (2 + 3) * 4 ))``` #arrow `20`],
      )
    })
  ][
    #uncover("2-")[
      #set text(size: 0.8em)
      #text(weight: "bold", fill: fail-color)[⚠️ no decimals]
      #terminal("$ echo $((3.5 * 2))\nbash: 3.5 * 2: syntax error: invalid arithmetic operator (error token is \".5 * 2\")")
    ]
    #uncover("3-")[
      #set text(size: 0.8em)
      #text(weight: "bold", fill: ok-color)[✅ use the `bc` calculator]
      #terminal("$ echo \"3.5 * 2\" | bc\n7.0")
    ]
  ]

  #v(0.3em)
  #set text(size: 0.9em)
  #only(1)[💡 the same operators as in C, but only on *integers*]
  #only(2)[💡 `3.5` is not a number for the shell: the error is at `.5`]
  #only("3-")[💡 `bc` is a *program*: it reads the expression from `stdin`, prints the result]
]

#let bc-code = "#!/bin/bash
price=3.5
count=2
total=$(echo \"$price * $count\" | bc)
echo \"total: $total\"
whole=$(echo \"$total / 1\" | bc)
echo \"times 10: $((whole * 10))\""

#slide[
  == 🐞 Decimals With `bc`
  The shell builds the text of the expression, `bc` computes it

  #debug-run(bc-code, command: "./total.sh", blocks: true, columns: (2fr, 1fr), size: 1.1em, (
    (line: 2, run: "price=3.5", vars: (price: "3.5"),
      note: [💡 for the shell, `3.5` is just text]),
    (line: 3, run: "count=2", vars: (count: "2")),
    (line: 4, part: ("echo \"$price * $count\"", "bc"), who: "copy", run: "echo \"3.5 * 2\" | bc", status: 0, info: [prints `7.0`],
      note: [💡 `echo` and `bc` run *at the same time*: `echo` writes `3.5 * 2` in the pipe, `bc` reads it, computes and prints the result]),
    (line: 4, run: "total=7.0", vars: (total: "7.0"),
      note: [💡 the output of `bc` takes the place of ```bash $(...)```, as text]),
    (line: 5, run: "echo \"total: 7.0\"", status: 0, out: ("total: 7.0",)),
    (line: 6, part: ("echo \"$total / 1\"", "bc"), who: "copy", run: "echo \"7.0 / 1\" | bc", status: 0, info: [prints `7`],
      note: [💡 back to an integer: by default, `bc` divides with *no decimals*]),
    (line: 6, run: "whole=7", vars: (whole: "7")),
    (line: 7, compute: "$((whole * 10))", info: [computes `7 * 10` = `70`],
      note: [💡 an integer again: ```bash $(( ))``` can use it]),
    (line: 7, run: "echo \"times 10: 70\"", status: 0, out: ("times 10: 70",)),
  ))
]
