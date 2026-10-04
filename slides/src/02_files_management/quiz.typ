#import "/src/slides.typ": *
#import "logos.typ": *

#slide[
  = 🧩 Quiz #text(size: 10pt, weight: "regular")[\ _Windows or Linux paths_]
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
  == 🧩 Path Syntax Quiz
  Windows or Linux

  #let answer(step, body) = uncover(str(step) + "-", body)

  #table(
    columns: (auto, auto, auto, 1fr),
    table.header([Path], [OS?], [Valid?], [Why?]),
    [`C:\Users\Alice\Videos\toy_story_5.mkv`],
    answer(2, windows-logo()),
    answer(2, [✅]),
    answer(2, [Uses drive letter and backslashes]),

    [`/home/alice/Movies/toy_story_5.mkv`], answer(3, linux-logo()), answer(3, [✅]), answer(3, [Starts from root `/`]),
    [`..\Videos\michael.mp4`], answer(4, windows-logo()), answer(4, [✅]), answer(4, [Relative path in Windows]),
    [`../Downloads/supergirl.mp4`], answer(5, linux-logo()), answer(5, [✅]), answer(5, [Relative path in Linux]),
    [`C:/Program Files/App`],
    answer(6, windows-logo()),
    answer(6, [✅]),
    answer(6, [Windows also accepts `/` in many cases]),

    [`~\Downloads`], answer(7, windows-logo()), answer(7, [❌]), answer(7, [`~` only expands in Linux]),
    [`~/Movies/project_hail_mary.mkv`], answer(8, linux-logo()), answer(8, [✅]), answer(8, [Home directory shortcut in Linux]),
  )
]
