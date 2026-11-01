#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Shell Scripts #text(size: 10pt, weight: "regular")[\ _Command lines, saved in a file_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.1 - _Shell Script Basics_
      - Section 11.14 - _When (Not) to Use Shell Scripts_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.1 - _Perspective pentru scripting_
      - Section 13.2 - _Dezvoltarea scripturilor_
]

#slide[
  == The Shell Runs Commands
  A programming language was added later, on top of it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - the shell was made to *run commands*: read a line, split it into words, run the command
    #uncover("2-")[#block[- a _shell script_ is a file with command lines, the shell runs them one after another]]
    #uncover("3-")[#block[- variables, conditions, loops and functions were added *on top* of this]]
    #uncover("4-")[#block[- so *everything* is still a command line: words, separated by spaces]]
  ][
    #uncover("2-")[
      #set text(size: 0.85em)
      ```bash
      #!/bin/bash
      # backup.sh - back up the notes
      mkdir -p ~/backup
      cp ~/notes.txt ~/backup/
      echo "backup done"
      ```
    ]
  ]

  #v(0.5em)
  #uncover("4-")[
    #shell-first[when the syntax of a script looks strange, ask yourself: *what command does the shell run here?*]
  ]
  #uncover("5-")[
    #set text(size: 0.85em)
    💡 great for _gluing commands together_, a bad choice for heavy computation - use Python, C, Rust, ... for that
  ]
]

#slide[
  == My First Script
  A text file, with the right to execute it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 8, 10), full: false)[```terminal
    $ cat hello.sh
    #!/bin/bash
    echo "Hello, $USER!"
    $ ./hello.sh
    bash: ./hello.sh: Permission denied
    $ chmod +x hello.sh
    $ ./hello.sh
    Hello, alice!
    $ bash hello.sh
    Hello, alice!
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      - write it with any text editor (`nano`, `vim`, ...)
      - the first line, `#!/bin/bash`, says which program runs the script
    ]
    #only(2)[💡 a new file has no _execute_ (`x`) permission]
    #only(3)[💡 `chmod +x` adds the permission, now it runs like any other program]
    #only("4-")[
      💡 or start `bash` yourself and give it the file, the permission is not needed

      💡 `./` is needed: the current directory is not in `PATH`
    ]
  ]
]

#slide[
  == The Shebang
  `#!` - who runs the script

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - `#!` (_hash-bang_, _shebang_) - the first two characters of the file
    #uncover("2-")[#block[- the *kernel* reads the line and runs that program, with the script as a parameter]]
    #uncover("3-")[#block[- for the shell, the line is just a comment (`#`)]]
    #uncover("4-")[#block[- works for any interpreter: `#!/usr/bin/python3`, `#!/usr/bin/env node`]]
  ][
    #set text(size: 0.9em)
    #label[you type]
    #align(center)[#words(("./hello.sh", "cmd"), "alice")]
    #uncover("2-")[
      #align(center)[#rotate(90deg, reflow: true, draw-arrow(length: 2em, color: changed))]
      #label[the kernel runs]
      #align(center)[#words(("/bin/bash", "cmd"), ("./hello.sh", "new"), "alice")]
    ]
  ]
]
