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

#slide[
  == Putting It Together
  Check the parameters, use a function, exit with a code

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #highlight-code(("all", lines-range(4, 7), lines-range(9, 11), (13,), lines-range(14, 18), "all"))[```bash
    #!/bin/bash
    # count.sh FRUIT FILE - how many times FRUIT is in FILE

    if [ $# -ne 2 ]; then
        echo "usage: $0 FRUIT FILE" >&2
        exit 1
    fi

    count() {
        grep -c "^$1\$" "$2"
    }

    n=$(count "$1" "$2")
    if [ "$n" -eq 0 ]; then
        echo "no $1 in $2"
    else
        echo "$n x $1"
    fi
    ```]
  ][
    #set text(size: 0.78em)
    #let session = "$ ./count.sh apple\nusage: ./count.sh FRUIT FILE\n$ echo $?\n1\n$ ./count.sh apple fruits.txt\n3 x apple\n$ ./count.sh mango fruits.txt\nno mango in fruits.txt"
    // the usage error first (steps 2 - 4), then the whole session
    #only("2-4")[#terminal(session.split("\n").slice(0, 4).join("\n"))]
    #only("5-")[#terminal(session)]
  ]

  #v(0.3em)
  #set text(size: 0.9em)
  #only(2)[💡 not 2 parameters: print how to use it on `stderr` (`>&2`) and end with an error]
  #only(3)[💡 a function that prints the number of lines that are exactly ```bash $1```]
  #only(4)[💡 capture the output of the function in `n`]
  #only("5-")[💡 decide with `[`, on the text that `grep` printed]
]
