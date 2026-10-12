#import "/src/slides.typ": *
#import "streams.typ": *

#slide[
  = File Descriptors #text(size: 10pt, weight: "regular")[\ _How processes access data_]
]

#slide[
  == Bibliography
  For this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 8 - _A Closer Look at Processes and Resource Utilization_
      - Section 8.2 - _Finding Open Files with lsof_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.4.1 - _Descriptori de fișiere_
      - Section 4.8 - _Anexa: Sistemul de fișiere procfs_
]

#slide[
  == File Descriptor Table
  How processes access data

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - each process has a _File Descriptor Table_
    - open files show up in the table
    - the *index* in the table is the *file descriptor*

    *Special Descriptors*
    #uncover("2-")[#block[- `0` - _keyboard_ - `stdin`]]
    #uncover("3-")[#block[- `1` - _display_ - `stdout`]]
    #uncover("4-")[#block[- `2` - _error display_ - `stderr`]]
  ][
    #align(center)[#image("img/fd/file_descriptor_table.pdf", height: 80%)]
  ]
]

#slide[
  == `sort` reads a file
  The process opens the file by itself

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (5, 5, 8), full: false)[```terminal
    $ cat fruits.txt
    cherry
    apple
    banana
    $ sort fruits.txt    # the file name is an argument
    apple
    banana
    cherry
    ```]
  ][
    #only(1)[#fd-table("sort", ((0, keyboard, false), (1, display, false), (2, display, false)))]
    #only("2-")[#fd-table("sort", (
      (0, keyboard, false),
      (1, display, false),
      (2, display, false),
      (3, file("fruits.txt"), true),
    ))]
  ]

  #align(center)[
    #only(1)[#one-process("sort", extra: (3, file("fruits.txt"), true), hide-extra: true)]
    #only(2)[#one-process("sort", extra: (3, file("fruits.txt"), true))]
    #only("3-")[#one-process("sort", extra: (3, file("fruits.txt"), true), unused: (0,))]
  ]

  #only(1)[💡 the *shell* starts `sort` with `0`, `1` and `2`, and gives it `fruits.txt` as an _argument_]
  #only(2)[💡 `sort` calls `open("fruits.txt")`, the kernel places it at the first free index: `3`]
  #only("3-")[💡 `sort` reads the lines from `3`, sorts them and writes them to `1`, the keyboard (`0`) is not used]
]
