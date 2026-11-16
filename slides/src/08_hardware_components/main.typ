#import "/src/slides.typ": *
#import "common.typ": *

#show: uso_slides.with(title: "8. Hardware Components")

#slide[
  == Bibliography

  #set text(size: 0.8em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
      - Chapter 1 - _The Big Picture_
        - Section 1.2 - _Hardware: Understanding Main Memory_
      - Chapter 3 - _Devices_
        - Section 3.4 - _Device Name Summary_
        - Section 3.6 - _In-Depth: SCSI and the Linux Kernel_

    2. *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
      - Chapter 8 - _Componente hardware_
  ][
    3. *David A. Patterson, John L. Hennessy*, _Computer Organization and Design RISC-V Edition_, 2#super[nd] Edition, Morgan Kaufmann, 2020
      - Chapter 1 - _Computer Abstractions and Technology_
      - Chapter 2 - _Instructions: Language of the Computer_
      - Chapter 5 - _Large and Fast: Exploiting Memory Hierarchy_
      - Chapter 6 - _Parallel Processors from Client to Cloud_
  ]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 20pt)[_Hardware: the parts of a computer that can be kicked._]

    #v(0.5em)
    Jeff Pesis (computing folklore)
  ]
]

#slide[
  == Hardware Components

  - The Computer: PC and SoC
  - How It Boots
  - Processor Architectures
  - Coprocessors
  - Memory and Storage
  - The Chipset
  - Communication
  - Links Inside Links
  - Single-Board Computers
  - Inspect and Measure
]

#include "pc-soc.typ"
#include "boot.typ"
#include "cpu.typ"
#include "coprocessors.typ"
#include "storage.typ"
#include "chipset.typ"
#include "communication.typ"
#include "tunnels.typ"
#include "boards.typ"
#include "inspect.typ"

#slide[
  == We talked about

  - The Computer: PC and SoC
  - How It Boots
  - Processor Architectures
  - Coprocessors
  - Memory and Storage
  - The Chipset
  - Communication
  - Links Inside Links
  - Single-Board Computers
  - Inspect and Measure
]
