#import "/src/slides.typ": *

#show: uso_slides.with(title: "8. Shell Scripting")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 2 - _Basic Commands and Directory Hierarchy_
        - Section 2.8 - _Environment and Shell Variables_
      - Chapter 11 - _Introduction to Shell Scripts_
        - Sections 11.1 - 11.8 - from _Shell Script Basics_ to _Temporary File Management_
        - Sections 11.10 - 11.14 - from _Utilities_ to _When (Not) to Use Shell Scripts_
  ][
    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 7 - _Interfața în linia de comandă_
        - Sections 7.2.2 - 7.2.5 - _Subshelluri_, _Variabile shell_, _Expandări_, _Escaping_
      - Chapter 13 - _Automatizarea sarcinilor_
        - Sections 13.1 - 13.3 - from _Perspective pentru scripting_ to _Funcții_
        - Sections 13.4.1, 13.4.2 - _Robustețe_, _Lizibilitate_
  ]
]

#slide[
  == Shell Scripting

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - Shell Scripts
    - Variables
    - Variable Expansion
    - Reading Input
    - Command Substitution
    - Arithmetic
    - Operators and Decimals
    - Conditions: `if`
    - Conditions: `test` and `[`
  ][
    - Conditions: `case`
    - Loops: `while`
    - Loops: `for`
    - Using `IFS` With `for`
    - Functions
    - Script Parameters
    - Handling Errors
    - Strict Mode
    - Cleaning Up: `trap`
  ]
]

#include "scripts.typ"
#include "variables.typ"
#include "quoting.typ"
#include "reading.typ"
#include "substitution.typ"
#include "arithmetic.typ"
#include "decimals.typ"
#include "if.typ"
#include "test.typ"
#include "case.typ"
#include "while.typ"
#include "for.typ"
#include "ifs-for.typ"
#include "functions.typ"
#include "parameters.typ"
#include "errors.typ"
#include "strict.typ"
#include "trap.typ"

#slide[
  == We talked about

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - Shell Scripts
    - Variables
    - Variable Expansion
    - Reading Input
    - Command Substitution
    - Arithmetic
    - Operators and Decimals
    - Conditions: `if`
    - Conditions: `test` and `[`
  ][
    - Conditions: `case`
    - Loops: `while`
    - Loops: `for`
    - Using `IFS` With `for`
    - Functions
    - Script Parameters
    - Handling Errors
    - Strict Mode
    - Cleaning Up: `trap`
  ]
]
