#import "/src/slides.typ": *

#show: uso_slides.with(title: "1. Introduction")

#slide[
  == Welcome
  to the _Introduction to Operating Systems_ class

  *You will learn, understand and experiment*
  - how operating systems work
  - how basic POSIX (Linux) commands work
  - how to use the Linux *command line*
  - the history of Linux
  - how use the development tools

  *We expect*
  - to come to class
  - ask a lot of questions
]

#include "team.typ"
#include "admin.typ"

#slide[
  == Notation

  - _name_ - this is a name
  - *important* - this is important
  - `command` - this is a command or a part of a source code

  Code
  #reveal-terminal(before: none, lines: (1, 2, 6))[```terminal
  $ command arguments
  this is what the command wrote
  $ command2 arguments placed \ # mind the \ that splits the command over multiple lines
             using multiple \
             lines
  ```]

  #only(4)[
    #quote(block: true)[`$` signifies that the user can write a command, but is *not part of the command*.]
  ]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #text(size: 20pt)[
    #align(center + horizon)[
      _If you can't explain it simply, you don't understand it well enough_
    ]

    #align(right)[
      -- Albert Einstein
    ]
  ]
]

#slide[
  == Bibliography

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
]

#include "os.typ"
#include "vm.typ"
#include "distributions.typ"

#slide[
  == We talked about

  - What an Operating System is
  - The Operating System Stack
  - Virtual Machines
  - History of Linux
  - Distributions
]
