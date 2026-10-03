#import "/src/slides.typ": *

#show: uso_slides.with(title: "3. Processes")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 1 - _The Big Picture_
        - Section 1.3.1 - _Process Management_
      - Chapter 2 - _Basic Commands and Directory Hierarchy_
        - Section 2.14 - _Shell Input and Output_
        - Section 2.16 - _Listing and Manipulating Processes_
      - Chapter 3 - _Devices_
        - Section 3.1 - _Device Files_
      - Chapter 6 - _How User Space Starts_
        - Sections 6.1 - 6.6
      - Chapter 8 - _A Closer Look at Processes and Resource Utilization_
        - Sections 8.1 - 8.3
  ][
    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 2 - _Utilizarea sistemului de fișiere_
        - Section 2.4 - _Redirectarea intrării sau ieșirii_
      - Chapter 4 - _Procese_
        - Sections 4.1 - 4.5, 4.8 - 4.9
      - Chapter 8 - _Componente hardware_
        - Section 8.6 - _Abstractizarea dispozitivelor în Linux_
      - Chapter 9 - _Pornirea sistemului_
        - Section 9.6 - _Pornirea init și a serviciilor de startup în Linux_
  ]
]

#slide[
  == Processes

  - Process
  - PID
  - Process Loading
  - Process States
  - `fork` and `exec`
  - File descriptors and redirects
  - How Linux starts
]

#slide[
  == Operating System — abstractions

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    *Actions*
    - _Applications_
    - use the _Processor_ and _Accelerators_ (GPU, Neural Engine, etc)

    *Data*
    - everything is a file
    - peripherals are viewed as files (_POSIX_)
      - `/dev/input/keyboard` - keyboard
      - `/dev/fb` - screen (framebuffer)
      - `/dev/sda` - Disk Drive A (first)
  ][
    #align(center)[#image("img/os/abstractions.pdf", width: 90%)]
  ]
]

#include "process.typ"
#include "fd.typ"
#include "redirects.typ"

#slide[
  == We talked about

  - Process
  - PID
  - Process Loading
  - Process States
  - `fork` and `exec`
  - File descriptors and redirects
  - How signals work
  - How Linux starts
]
