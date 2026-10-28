#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Loops: `while` #text(size: 10pt, weight: "regular")[\ _Run a command again and again, while it succeeds_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.6.2 - _while Loops_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == `while` Runs a Command
  Just like `if`: repeat the body while the command ends with `0`

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    ```bash
    while command; do
        # runs while command ends with 0
    done
    ```
    #uncover("2-")[
      ```bash
      until command; do
          # runs until command ends with 0
      done
      ```
    ]
    #uncover("4-")[
      - `break` - leave the loop
      - `continue` - go to the next round
    ]
  ][
    #set text(size: 0.72em)
    #reveal-terminal(before: none, lines: (4, 7, 9), full: false)[```terminal
    $ n=2
    $ while [ $n -gt 0 ]; do echo "$n..."; n=$((n - 1)); done
    2...
    1...
    $ until [ $n -eq 2 ]; do n=$((n + 1)); echo "$n"; done
    1
    2
    $ while $n > 0; do echo "$n..."; done
    bash: 2: command not found
    ```]
  ]

  #v(0.3em)
  #only(1)[💡 `[ $n -gt 0 ]` runs before every round, the body changes `n`]
  #only(2)[💡 `until` - the opposite: repeat while the command *fails*]
  #only("3-")[
    #shell-first[the same trap as `if`: the command `2`, its output redirected to a file named `0`]
  ]
]

#slide[
  == Commands as Conditions
  Any command works, not only `[`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #only("1")[
      ```bash
      while read fruit; do
          echo "fruit: $fruit"
      done < fruits.txt
      ```
      #terminal("$ ./fruits.sh\nfruit: banana\nfruit: apple\nfruit: cherry\n...")
    ]
    #only("2-")[
      ```bash
      while true; do
          echo "working"
          sleep 1
      done
      ```
      #terminal("$ ./work.sh\nworking\nworking\n^C")
    ]
  ][
    #set text(size: 0.9em)
    #only(1)[
      - `read fruit` - reads *one line* from `stdin` into the variable `fruit`
      - ends with `0` if it read a line, with `1` at the end of the file
      - `< fruits.txt` - the `stdin` of the *whole loop*
    ]
    #only("2-")[
      - `true` - a command that always ends with `0`
      - the loop never stops, until #kbd("Ctrl") + #kbd("C") or `break`
      - the `stubborn.sh` script of lab 4
    ]
  ]

  #v(0.5em)
  #shell-first[the loop does not know what a file is or what _forever_ is: it only runs `read` or `true`, and checks the exit code]
]

#let while-code = "#!/bin/bash
n=2
while [ $n -gt 0 ]; do
    echo \"$n...\"
    n=$((n - 1))
done
echo \"go!\""

#slide[
  == 🐞 `while`, Step by Step
  The lines that run, as a debugger shows them

  #debug-run(while-code, (
    (line: 2, run: "n=2", vars: (n: "2"), changed: ("n",),
      note: [💡 `n` is the text `2`]),
    (line: 3, run: "[ 2 -gt 0 ]", status: 0, vars: (n: "2"),
      note: [💡 the shell replaces ```bash $n``` and runs `[`: _true_, the body runs]),
    (line: 4, run: "echo \"2...\"", status: 0, vars: (n: "2"), out: ("2...",)),
    (line: 5, run: "n=1", vars: (n: "1"), changed: ("n",),
      note: [💡 `$((n - 1))` is computed and replaced by the text `1`]),
    (line: 3, run: "[ 1 -gt 0 ]", status: 0, vars: (n: "1"),
      note: [💡 `done` jumps back: the condition runs *again*, with the new value]),
    (line: 4, run: "echo \"1...\"", status: 0, vars: (n: "1"), out: ("1...",)),
    (line: 5, run: "n=0", vars: (n: "0"), changed: ("n",)),
    (line: 3, run: "[ 0 -gt 0 ]", status: 1, vars: (n: "0"),
      note: [💡 `[` ends with `1`, _false_: the loop ends]),
    (line: 7, run: "echo \"go!\"", status: 0, vars: (n: "0"), out: ("go!",),
      note: [💡 the script goes on after `done`]),
  ))
]
