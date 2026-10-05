#import "/src/slides.typ": *
#import "diagram.typ": *
#import "walk.typ": *

// the examples where `.` and `..` are not only at the start of the path;
// a separate section keeps the progress dots from running into the title
#slide[
  = Tricky Paths #text(size: 10pt, weight: "regular")[\ `.` _and_ `..` _anywhere in the path_]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.4 - _Navigating Directories_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.1.3 - _Căi relative și căi absolute_
]

#slide[
  == Tricky Paths

  #path-walks(path-examples.slice(4))
]
