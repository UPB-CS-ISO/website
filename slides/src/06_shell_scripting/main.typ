#import "/src/slides.typ": *

#show: uso_slides.with(title: "6. Shell Scripting")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 11 - _Introduction to Shell Scripts_
        - Section 11.1 - _Shell Script Basics_
        - Sections 11.3 - 11.7 - _Special Variables_, _Exit Codes_, _Conditionals_, _Loops_, _Command Substitution_
        - Section 11.14 - _When (Not) to Use Shell Scripts_
  ][
    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 13 - _Automatizarea sarcinilor_
        - Section 13.2 - _Dezvoltarea scripturilor_
        - Section 13.3 - _Funcționalități pentru scripturi shell_
  ]
]

#slide[
  == Shell Scripting

  - Shell Scripts
  - Variables
  - Variables Expansion
  - Reading Input: `read` and `IFS`
  - Command Substitution
  - Arithmetic
  - Conditions: `if`
  - Conditions: `test` and `[`
  - Conditions: `case`
  - Loops: `while`
  - Loops: `for`
  - Using `IFS` with `for`
  - Script Parameters
]

#include "scripts.typ"
#include "variables.typ"
#include "quoting.typ"
#include "reading.typ"
#include "substitution.typ"
#include "arithmetic.typ"
#include "if.typ"
#include "test.typ"
#include "case.typ"
#include "while.typ"
#include "for.typ"
#include "ifs-for.typ"
#include "parameters.typ"

#slide[
  == We talked about

  - Shell Scripts
  - Variables
  - Variables Expansion
  - Reading Input: `read` and `IFS`
  - Command Substitution
  - Arithmetic
  - Conditions: `if`
  - Conditions: `test` and `[`
  - Conditions: `case`
  - Loops: `while`
  - Loops: `for`
  - Using `IFS` with `for`
  - Script Parameters
]
