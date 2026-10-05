#import "/src/slides.typ": *

#show: uso_slides.with(title: "2. Files Management")

#slide[
  == Bibliography

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
    - Chapter 4 - _Disks and Filesystems_
      - Sections 4.1 and 4.2
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Sections 2.1 - 2.3
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #text(size: 20pt)[
    #align(center + horizon)[
      _Best file compression around_

      `DEL *.*` = _100% compression_
    ]
  ]
]

#include "files.typ"
#include "paths.typ"
#include "walking-path.typ"
#include "tricky-paths.typ"
#include "manual.typ"
#include "navigation.typ"
#include "file-management.typ"
#include "file-managers.typ"

#slide[
  == We talked about

  - File System Layout
  - Paths
  - Manual Pages
  - Navigation
  - File Management
  - File Managers
]
