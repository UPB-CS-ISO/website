#import "/src/slides.typ": *

#show: uso_slides.with(title: "4. Command Line Interface")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 2 - _Basic Commands and Directory Hierarchy_
        - Sections 2.1 - 2.2 - _The Bourne Shell_, _Using the Shell_
        - Section 2.4.2 - _Shell Globbing ("Wildcards")_
        - Sections 2.8 - 2.10 - _Environment and Shell Variables_, _The Command Path_, _Special Characters_
        - Section 2.16 - _Listing and Manipulating Processes_
      - Chapter 3 - _Devices_
        - Section 3.4 - _Device Name Summary_ (terminals)
      - Chapter 11 - _Introduction to Shell Scripts_
        - Section 11.2 - _Quoting and Literals_
  ][
    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 4 - _Procese_
        - Section 4.3.3 - _Foreground și background_
        - Sections 4.5.2, 4.6.1
      - Chapter 7 - _Interfața în linia de comandă_
        - Sections 7.1, 7.2.3 - 7.2.5
      - Chapter 9 - _Pornirea sistemului_
        - Section 9.6.1 - _Pornirea terminalelor de login_
  ]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 20pt)[
      _It was a mistake to think that GUIs ever would, could, or even should, eliminate CLIs._
    ]

    #v(0.5em)
    Jeffrey Snover (architect of Windows PowerShell)
  ]
]

#slide[
  == Command Line Interface

  - Terminal & Shell
  - Foreground & Background
  - Sessions and Terminals
  - Signals
  - Environment Variables
  - The Command Line
  - Quoting, Escaping and Globbing
  - Running a Command
]

#include "terminals.typ"
#include "signals.typ"
#include "jobs.typ"
#include "sessions.typ"
#include "environment.typ"
#include "cmdline.typ"
#include "quoting.typ"
#include "running.typ"

#slide[
  == We talked about

  - Terminal & Shell
  - Foreground & Background
  - Sessions and Terminals
  - Signals
  - Environment Variables
  - The Command Line
  - Quoting, Escaping and Globbing
  - Running a Command
]
