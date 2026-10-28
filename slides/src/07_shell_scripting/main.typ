#import "/src/slides.typ": *

#show: uso_slides.with(title: "7. Shell Scripting")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 2 - _Basic Commands and Directory Hierarchy_
        - Section 2.5.1 - `grep`
      - Chapter 11 - _Introduction to Shell Scripts_
        - Section 11.1 - _Shell Script Basics_
        - Sections 11.3 - 11.7 - _Special Variables_, _Exit Codes_, _Conditionals_, _Loops_, _Command Substitution_
        - Section 11.14 - _When (Not) to Use Shell Scripts_
  ][
    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 7 - _Interfața în linia de comandă_
        - Section 7.4 - _Expresii regulate_
      - Chapter 13 - _Automatizarea sarcinilor_
        - Section 13.2 - _Dezvoltarea scripturilor_
        - Section 13.3 - _Funcționalități pentru scripturi shell_
  ]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 20pt)[
      _Some people, when confronted with a problem, think "I know, I'll use regular expressions." Now they have two problems._
    ]

    #v(0.5em)
    Jamie Zawinski (one of the authors of Netscape Navigator)
  ]
]

#slide[
  == Shell Scripting

  - Regular Expressions
  - Shell Scripts
  - Variables and Arithmetic
  - Exit Codes
  - Conditions: `if`
  - Loops: `while`
  - Loops: `for`
  - Functions
  - Script Parameters
]

#include "regex.typ"
#include "scripts.typ"
#include "variables.typ"
#include "exit-codes.typ"
#include "if.typ"
#include "while.typ"
#include "for.typ"
#include "functions.typ"
#include "parameters.typ"

#slide[
  == We talked about

  - Regular Expressions
  - Shell Scripts
  - Variables and Arithmetic
  - Exit Codes
  - Conditions: `if`
  - Loops: `while`
  - Loops: `for`
  - Functions
  - Script Parameters
]
