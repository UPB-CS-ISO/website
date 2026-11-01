#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Script Parameters #text(size: 10pt, weight: "regular")[\ _The words after the name of the script_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.3 - _Special Variables_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

#slide[
  == Parameter Syntax
  The words of the command line, as variables

  #align(center)[
    #set text(size: 1.1em)
    #grid(
      columns: 4,
      column-gutter: 0.5em,
      row-gutter: 0.6em,
      align: center,
      w("./params.sh", kind: "cmd"), w("alice"), w("Alice Smith"), w("bob"),
      ..("$0", "$1", "$2", "$3").enumerate().map(((k, v)) => uncover(str(k + 2) + "-", text(fill: changed, raw(v)))),
    )
  ]

  #v(0.5em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #uncover("2-")[#block[- ```bash $0``` - the name of the script, as you typed it]]
    #uncover("3-")[#block[- ```bash $1```, ```bash $2```, ... - the parameters, ```bash ${10}``` after `9`]]
    #uncover("5-")[#block[- ```bash $#``` - how many parameters: `3`]]
    #uncover("6-")[#block[- ```bash "$@"``` - all the parameters, every one a separate word]]
  ][
    #set text(size: 0.85em)
    #uncover("2-")[#terminal("$ ./params.sh alice \"Alice Smith\" bob")]
  ]
]

#let params-code = "#!/bin/bash
echo \"script: $0\"
echo \"hello, $1 and $2\"
echo \"$# parameters\""

#slide[
  == 🐞 Script Parameters
  The words after the name of the script are ```bash $1```, ```bash $2```, ...

  #debug-run(params-code, command: "./params.sh alice bob", (
    (line: 2, run: "echo \"script: ./params.sh\"", status: 0, out: ("script: ./params.sh",),
      vars: ("$0": "./params.sh", "$1": "alice", "$2": "bob", "$#": "2"),
      note: [💡 ```bash $0``` - the name of the script, as you typed it]),
    (line: 3, run: "echo \"hello, alice and bob\"", status: 0, out: ("hello, alice and bob",),
      note: [💡 ```bash $1``` and ```bash $2``` - the first and second word after it]),
    (line: 4, run: "echo \"2 parameters\"", status: 0, out: ("2 parameters",),
      note: [💡 ```bash $#``` - how many parameters]),
  ))
]

#let show-code = "#!/bin/bash
for p in \"$@\"; do
    echo \"[$p]\"
done"

#slide[
  == 🐞 Going Over the Parameters
  ```bash "$@"``` - the parameters, every one a word

  #debug-run(show-code, command: "./show.sh \"Alice Smith\" bob", columns: (1fr, 1fr), (
    (line: 2, info: [expands to `"Alice Smith" "bob"`],
      vars: ("$1": "Alice Smith", "$2": "bob", "$#": "2"),
      note: [💡 two words, the space inside `Alice Smith` is kept]),
    (line: 2, expand: "p ", run: "p=\"Alice Smith\"", vars: (p: "Alice Smith")),
    (line: 3, run: "echo \"[Alice Smith]\"", status: 0, out: ("[Alice Smith]",)),
    (line: 2, expand: "p ", run: "p=\"bob\"", vars: (p: "bob")),
    (line: 3, run: "echo \"[bob]\"", status: 0, out: ("[bob]",)),
  ))
]

#slide[
  == Positional Parameters
  ```bash $0```, ```bash $1```, ```bash $2```, ... - the words of the command line

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    ```bash
    #!/bin/bash
    echo "script: $0"
    echo "first:  $1"
    echo "second: $2"
    echo "count:  $#"
    echo "all:    $@"
    ```
    #table(
      columns: (auto, 1fr),
      inset: (x: 0.4em, y: 0.3em),
      table.header([Variable], [Value]),
      [```bash $0```], [the name of the script, as you typed it],
      [```bash $1``` ... ```bash $9```, ```bash ${10}```], [the parameters],
      [```bash $#```], [how many parameters],
      [```bash $@```], [all the parameters],
    )
  ][
    #set text(size: 0.78em)
    #reveal-terminal(before: none, lines: (6, 12), full: false)[```terminal
    $ ./params.sh alice bob
    script: ./params.sh
    first:  alice
    second: bob
    count:  2
    all:    alice bob
    $ ./params.sh "Alice Smith" bob carol
    script: ./params.sh
    first:  Alice Smith
    second: bob
    count:  3
    all:    Alice Smith bob carol
    ```]
  ]

  #v(0.3em)
  #only(2)[
    #shell-first[the parameters are the *words* your shell made from the command line: the quotes keep `Alice Smith` one word]
  ]
]

#slide[
  == `"$@"` Keeps the Words
  Without quotes, the parameters are split again

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    ```bash
    #!/bin/bash
    # show.sh
    for p in "$@"; do
        echo "[$p]"
    done
    ```
    #terminal("$ ./show.sh \"Alice Smith\" bob\n[Alice Smith]\n[bob]")
  ][
    #set text(size: 0.8em)
    #uncover("2-")[
      ```bash
      #!/bin/bash
      # show2.sh
      for p in $@; do
          echo "[$p]"
      done
      ```
      #terminal("$ ./show2.sh \"Alice Smith\" bob\n[Alice]\n[Smith]\n[bob]")
    ]
  ]

  #v(0.3em)
  #uncover("2-")[
    #shell-first[```bash $@``` is replaced by text, and unquoted text is split at the spaces - the same rule as for any variable]
  ]
]
