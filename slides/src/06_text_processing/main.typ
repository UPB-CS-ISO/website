#import "/src/slides.typ": *

#show: uso_slides.with(title: "6. Text Processing")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 2 - _Basic Commands and Directory Hierarchy_
        - Sections 2.2.2 - 2.2.3 - `cat`, _Standard Input and Standard Output_
        - Section 2.5 - _Intermediate Commands_
        - Section 2.14 - _Shell Input and Output_
      - Chapter 11 - _Introduction to Shell Scripts_
        - Sections 11.4 - 11.5 - _Exit Codes_, _Conditionals_
  ][
    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 2 - _Utilizarea sistemului de fișiere_
        - Section 2.4 - _Redirectarea intrării sau ieșirii_
      - Chapter 4 - _Procese_
        - Sections 4.5.3 - 4.5.4 - _Înlănțuirea comenzilor_, _Comunicarea prin pipe-uri_
      - Chapter 7 - _Interfața în linia de comandă_
        - Sections 7.4 - 7.5 - _Expresii regulate_, _Prelucrare de text de bază_
      - Chapter 13 - _Automatizarea sarcinilor_
        - Section 13.3.2 - _Controlul fluxului_
  ]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 20pt)[
      _Write programs that do one thing and do it well. Write programs to work together. Write programs to handle text streams, because that is a universal interface._
    ]

    #v(0.5em)
    Doug McIlroy (the inventor of the Unix pipe)
  ]
]

#slide[
  == Text Processing

  - Pipelines
  - Line Filters
    - `cat`, `tac`, `head`, `tail`, `sort`, `uniq`
  - Search
    - regular expressions, `grep`
  - Column Filters
    - `cut`, `tr`, `sed`, `rev`, `nl`
  - Compute
    - `wc`, `awk`
  - A Pipeline, Step by Step
  - Exit Codes
  - Text Editors
    - `nano`, `vim`, `emacs`, `helix`
]

#include "pipelines.typ"
#include "filters.typ"
#include "regex.typ"
#include "columns.typ"
#include "summary.typ"
#include "example.typ"
#include "exit-codes.typ"
#include "editors.typ"

#slide[
  == We talked about

  - Pipelines
  - Line Filters
    - `cat`, `tac`, `head`, `tail`, `sort`, `uniq`
  - Search
    - regular expressions, `grep`
  - Column Filters
    - `cut`, `tr`, `sed`, `rev`, `nl`
  - Compute
    - `wc`, `awk`
  - A Pipeline, Step by Step
  - Exit Codes
  - Text Editors
    - `nano`, `vim`, `emacs`, `helix`
]
