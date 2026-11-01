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
  == `for` Syntax
  Once for every word of a list

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 1em)
    #highlight-code(("all", (1,), (2,), (3,), (4,), (5,), (6,), "all"))[```bash
for NAME in word1 word2 word3; do
    commands
done
for f in *.txt; do ...; done
for w in $(cat fruits.txt); do ...; done
for i in {1..5}; do ...; done
```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- the variable `NAME` takes every word after `in`, one by one]]
    #uncover("3-")[#block[- `do` - the _body_, runs once for every word, with ```bash $NAME``` the word]]
    #uncover("4-")[#block[- `done` - go back and take the next word]]
    #uncover("5-")[#block[- the words can come from a _glob_]]
    #uncover("6-")[#block[- or from the output of a command]]
    #uncover("7-")[#block[- or from _brace expansion_ #bash-tag]]
  ]

  #only("8-")[#one-liner(("for NAME in word1 word2; do commands; done",), ("for f in apple kiwi; do echo \"I like $f\"; done",))]
]

#let for-code = "#!/bin/bash
for fruit in apple kiwi cherry; do
    echo \"I like $fruit\"
done
echo \"done\""

#slide[
  == 🐞 `for`
  Run the body once for every word of the list

  #debug-run(for-code, command: "./fruits.sh", (
    (line: 2, expand: "apple", run: "fruit=apple", vars: (fruit: "apple"),
      note: [💡 `fruit` takes the first word]),
    (line: 3, run: "echo \"I like apple\"", status: 0, out: ("I like apple",)),
    (line: 2, expand: "kiwi", run: "fruit=kiwi", vars: (fruit: "kiwi"),
      note: [💡 `done` jumps back, `fruit` takes the next word]),
    (line: 3, run: "echo \"I like kiwi\"", status: 0, out: ("I like kiwi",)),
    (line: 2, expand: "cherry", run: "fruit=cherry", vars: (fruit: "cherry")),
    (line: 3, run: "echo \"I like cherry\"", status: 0, out: ("I like cherry",)),
    (line: 5, run: "echo \"done\"", status: 0, out: ("done",),
      note: [💡 no more words, the loop ends]),
  ))
]

#let glob-code = "#!/bin/bash
for f in *.txt; do
    echo \"file: $f\"
done"

#slide[
  == 🐞 `for` With a Glob
  The shell makes the list of words first

  #debug-run(glob-code, command: "./files.sh", (
    (line: 2, expand: "*.txt", info: [expands `*.txt` to `fruits.txt notes.txt words.txt`],
      note: [💡 before the loop starts, the shell replaces the glob with the file names]),
    (line: 2, expand: "f ", run: "f=fruits.txt", vars: (f: "fruits.txt")),
    (line: 3, run: "echo \"file: fruits.txt\"", status: 0, out: ("file: fruits.txt",)),
    (line: 2, expand: "f ", run: "f=notes.txt", vars: (f: "notes.txt")),
    (line: 3, run: "echo \"file: notes.txt\"", status: 0, out: ("file: notes.txt",)),
    (line: 2, expand: "f ", run: "f=words.txt", vars: (f: "words.txt")),
    (line: 3, run: "echo \"file: words.txt\"", status: 0, out: ("file: words.txt",),
      note: [💡 `for` only sees words, it does not know they are files]),
  ))
]

#slide[
  == Counting With a Step
  Make the list of numbers first, with `seq`

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - `seq first step last` - a *program* that prints the numbers
    #uncover("2-")[#block[- it works with variables: `seq` runs *after* the shell replaced them]]
    #uncover("3-")[#block[- the output of `seq` becomes the words of `for`]]
  ][
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4), full: false)[```terminal
    $ for i in $(seq 1 3 10); do echo -n "$i "; done; echo
    1 4 7 10
    $ n=5; for i in $(seq 1 $n); do echo -n "$i "; done; echo
    1 2 3 4 5
    ```]
  ]

  #v(0.3em)
  #uncover("3-")[
    #shell-first[`for` still goes over *words*: a command (`seq`) writes the numbers]
  ]
  #uncover("4-")[
    #set text(size: 0.85em)
    💡 `bash` can also write them: `{1..10..3}` #bash-tag - but not with variables, `{1..$n}` stays as it is \
    💡 and it has a C-like `for`: ```bash for ((i = 1; i <= 10; i += 3)); do ...; done``` #bash-tag
  ]
]

#let seq-code = "#!/bin/bash
n=3
for i in $(seq 1 $n); do
    echo \"round $i\"
done
echo \"done\""

#slide[
  == 🐞 Counting With `seq`
  `seq` writes the numbers, `for` goes over them

  #debug-run(seq-code, command: "./rounds.sh", blocks: true, (
    (line: 2, run: "n=3", vars: (n: "3")),
    (line: 3, part: "seq 1 $n", who: "copy", run: "seq 1 3", status: 0, info: [prints `1`, `2`, `3`, one per line],
      note: [💡 first, a copy of `bash` runs `seq`, its output takes the place of ```bash $(...)```]),
    (line: 3, run: "i=1", vars: (i: "1"), expand: "i ",
      note: [💡 the list is now the words `1 2 3`: `i` takes the first one]),
    (line: 4, run: "echo \"round 1\"", status: 0, out: ("round 1",)),
    (line: 3, run: "i=2", vars: (i: "2"), expand: "i ",
      note: [💡 `done` jumps back, `i` takes the next word - `seq` does not run again]),
    (line: 4, run: "echo \"round 2\"", status: 0, out: ("round 2",)),
    (line: 3, run: "i=3", vars: (i: "3"), expand: "i in"),
    (line: 4, run: "echo \"round 3\"", status: 0, out: ("round 3",)),
    (line: 6, run: "echo done", status: 0, out: ("done",),
      note: [💡 no more words, the loop ends]),
  ))
]
