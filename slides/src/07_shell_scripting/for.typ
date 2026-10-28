#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Loops: `for` #text(size: 10pt, weight: "regular")[\ _Once for every word_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.6.1 - _for Loops_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == `for` Goes Over Words
  The variable takes every word of the list, one after another

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    ```bash
    for NAME in word1 word2 ...; do
        # runs once for every word,
        # $NAME is the word
    done
    ```
    #uncover("2-")[#block[- the words can come from anything that makes words:]]
    #uncover("3-")[#block[- a _glob_]]
    #uncover("4-")[#block[- the output of a command, ```bash $(...)```]]
  ][
    #set text(size: 0.78em)
    #reveal-terminal(before: none, lines: (4, 8, 10), start: 2, full: false)[```terminal
    $ for fruit in apple kiwi cherry; do echo "I like $fruit"; done
    I like apple
    I like kiwi
    I like cherry
    $ for f in *.txt; do echo "file: $f"; done
    file: fruits.txt
    file: notes.txt
    file: words.txt
    $ for w in $(cat fruits.txt); do echo -n "$w "; done; echo
    banana apple cherry apple kiwi banana apple
    ```]
  ]

  #v(0.3em)
  #uncover("3-")[
    #shell-first[`for` does not know about files or lines: the shell expands the line first (globs, variables, ```bash $(...)```), then `for` gets *words*]
  ]
]

#let for-code = "#!/bin/bash
for fruit in apple kiwi cherry; do
    echo \"I like $fruit\"
done
echo \"done\""

#slide[
  == 🐞 `for`, Step by Step
  The lines that run, as a debugger shows them

  #debug-run(for-code, (
    (line: 2, run: "for fruit in apple kiwi cherry", vars: (fruit: "apple"), changed: ("fruit",),
      note: [💡 the first word goes into `fruit`]),
    (line: 3, run: "echo \"I like apple\"", status: 0, vars: (fruit: "apple"), out: ("I like apple",)),
    (line: 2, run: "for fruit in apple kiwi cherry", vars: (fruit: "kiwi"), changed: ("fruit",),
      note: [💡 `done` jumps back, `fruit` gets the next word]),
    (line: 3, run: "echo \"I like kiwi\"", status: 0, vars: (fruit: "kiwi"), out: ("I like kiwi",)),
    (line: 2, run: "for fruit in apple kiwi cherry", vars: (fruit: "cherry"), changed: ("fruit",)),
    (line: 3, run: "echo \"I like cherry\"", status: 0, vars: (fruit: "cherry"), out: ("I like cherry",)),
    (line: 5, run: "echo \"done\"", status: 0, vars: (fruit: "cherry"), out: ("done",),
      note: [💡 no more words, the loop ends - `fruit` keeps the last word]),
  ))
]

#slide[
  == Counting With a Step
  Make the list of numbers first

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - `{1..10..3}` - _brace expansion_: from `1` to `10`, step `3`
    #uncover("2-")[#block[- `seq 1 3 10` - a *program* that prints the numbers: first, step, last]]
    #uncover("3-")[#block[⚠️ `{1..$n}` does not work: braces are expanded *before* the variables]]
    #uncover("4-")[#block[- `seq` works with variables, it runs after they are replaced]]
  ][
    #set text(size: 0.78em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 8), full: false)[```terminal
    $ for i in {1..10..3}; do echo -n "$i "; done; echo
    1 4 7 10
    $ for i in $(seq 1 3 10); do echo -n "$i "; done; echo
    1 4 7 10
    $ n=10; for i in {1..$n}; do echo "$i"; done
    {1..10}
    $ for i in $(seq 1 $n); do echo -n "$i "; done; echo
    1 2 3 4 5 6 7 8 9 10
    ```]
  ]

  #v(0.3em)
  #uncover("3-")[
    #shell-first[`for` still goes over *words*: someone has to write the numbers - the shell (`{ }`) or a command (`seq`)]
  ]
]

#slide[
  == The C-like `for`
  ```bash for (( init; condition; step ))``` - the math of `$(( ))`

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    ```bash
    for ((i = 0; i < 6; i += 2)); do
        echo "i is $i"
    done
    ```
    - `i = 0` - runs once, at the start
    - `i < 6` - checked before every round
    - `i += 2` - the _step_, after every round
  ][
    #set text(size: 0.78em)
    #reveal-terminal(before: none, lines: (4, 6), full: false)[```terminal
    $ for ((i = 0; i < 6; i += 2)); do echo "i is $i"; done
    i is 0
    i is 2
    i is 4
    $ for ((i = 10; i > 0; i -= 4)); do echo -n "$i "; done; echo
    10 6 2
    ```]
  ]

  #v(0.3em)
  #uncover("2-")[
    #shell-first[added later to `bash`, `(( ))` is not split into words: `<` is a comparison here, not a redirect]
  ]
]

#let step-code = "#!/bin/bash
for ((i = 0; i < 6; i += 2)); do
    echo \"i is $i\"
done
echo \"done\""

#slide[
  == 🐞 C-like `for`, Step by Step
  The lines that run, as a debugger shows them

  #debug-run(step-code, (
    (line: 2, run: "((i = 0)); ((i < 6))", status: 0, vars: (i: "0"), changed: ("i",),
      note: [💡 _init_ once, then the _condition_: `0 < 6` is true]),
    (line: 3, run: "echo \"i is 0\"", status: 0, vars: (i: "0"), out: ("i is 0",)),
    (line: 2, run: "((i += 2)); ((i < 6))", status: 0, vars: (i: "2"), changed: ("i",),
      note: [💡 the _step_, then the _condition_ again]),
    (line: 3, run: "echo \"i is 2\"", status: 0, vars: (i: "2"), out: ("i is 2",)),
    (line: 2, run: "((i += 2)); ((i < 6))", status: 0, vars: (i: "4"), changed: ("i",)),
    (line: 3, run: "echo \"i is 4\"", status: 0, vars: (i: "4"), out: ("i is 4",)),
    (line: 2, run: "((i += 2)); ((i < 6))", status: 1, vars: (i: "6"), changed: ("i",),
      note: [💡 `6 < 6` is false, `(( ))` ends with `1`: the loop ends]),
    (line: 5, run: "echo \"done\"", status: 0, vars: (i: "6"), out: ("done",)),
  ))
]
