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
  == `while` Syntax
  Repeat while a *command* ends with `0`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.4em)
    #highlight-code(("all", (1,), (2,), (3,), lines-range(4, 6), "all", "all"))[```bash
while command; do
    commands
done
until command; do
    commands
done
```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- `while` runs the command *before every round*, and looks at its exit code]]
    #uncover("3-")[#block[- `do` - the _body_, runs while the command ends with `0`]]
    #uncover("4-")[#block[- `done` - jump back to the command]]
    #uncover("5-")[#block[- `until` - the opposite: repeat while the command does *not* end with `0`]]
  ]

  #v(0.3em)
  #only(6)[💡 inside the body: `break` - leave the loop, `continue` - go to the next round]
  #only("7-")[#one-liner(("while command; do commands; done", "until command; do commands; done"), ("while [ $n -gt 0 ]; do n=$((n - 1)); done",))]
]

#let while-code = "#!/bin/bash
n=2
while [ $n -gt 0 ]; do
    echo \"$n...\"
    n=$((n - 1))
done
echo \"go!\""

#slide[
  == 🐞 `while`
  Run the body again and again, while the condition command ends with `0`

  #debug-run(while-code, size: 1.35em, columns: (3fr, 2fr), command: "./countdown.sh", blocks: true, (
    (line: 2, run: "n=2", vars: (n: "2")),
    (line: 3, part: "[ $n -gt 0 ]", run: "[ 2 -gt 0 ]", status: 0,
      note: [💡 `0`, _true_: the body runs]),
    (line: 4, run: "echo \"2...\"", status: 0, out: ("2...",)),
    (line: 5, run: "n=1", vars: (n: "1"),
      note: [💡 ```bash $((n - 1))``` is computed, `n` is now the text `1`]),
    (line: 3, part: "[ $n -gt 0 ]", run: "[ 1 -gt 0 ]", status: 0,
      note: [💡 `done` jumps back: the condition runs *again*, with the new value]),
    (line: 4, run: "echo \"1...\"", status: 0, out: ("1...",)),
    (line: 5, run: "n=0", vars: (n: "0")),
    (line: 3, part: "[ $n -gt 0 ]", run: "[ 0 -gt 0 ]", status: 1,
      note: [💡 `1`, _false_: the loop ends]),
    (line: 7, run: "echo \"go!\"", status: 0, out: ("go!",),
      note: [💡 the script goes on after `done`]),
  ))
]

#let until-code = "#!/bin/bash
n=0
until [ $n -eq 2 ]; do
    n=$((n + 1))
    echo \"$n\"
done
echo \"done\""

#slide[
  == 🐞 `until`
  Run the body again and again, while the condition command does *not* end with `0`

  #debug-run(until-code, size: 1.35em, columns: (3fr, 2fr), command: "./count.sh", blocks: true, (
    (line: 2, run: "n=0", vars: (n: "0")),
    (line: 3, part: "[ $n -eq 2 ]", run: "[ 0 -eq 2 ]", status: 1,
      note: [💡 not `0`, _false_: `until` runs the body]),
    (line: 4, run: "n=1", vars: (n: "1")),
    (line: 5, run: "echo 1", status: 0, out: ("1",)),
    (line: 3, part: "[ $n -eq 2 ]", run: "[ 1 -eq 2 ]", status: 1,
      note: [💡 `done` jumps back: still not `0`, the body runs again]),
    (line: 4, run: "n=2", vars: (n: "2")),
    (line: 5, run: "echo 2", status: 0, out: ("2",)),
    (line: 3, part: "[ $n -eq 2 ]", run: "[ 2 -eq 2 ]", status: 0,
      note: [💡 `0`, _true_: `until` stops - the opposite of `while`]),
    (line: 7, run: "echo done", status: 0, out: ("done",)),
  ))
]

#let read-code = "#!/bin/bash
while read fruit; do
    echo \"buy $fruit\"
done < shopping.txt
echo \"done\""

#slide[
  == 🐞 `while read`
  Read a file, one line in every round

  #debug-run(read-code, size: 1.35em, columns: (11fr, 9fr), command: "./shop.sh", blocks: true, files: (("shopping.txt", ("apple", "kiwi")),), (
    (line: 2, part: "read fruit", also: ((4, "< shopping.txt"),), run: "read fruit < shopping.txt", match: "apple", status: 0, vars: (fruit: "apple"), info: [reads `apple`],
      note: [💡 `< shopping.txt` after `done` is the `stdin` of the *whole loop*: `read` takes one line from it, into `fruit`]),
    (line: 3, run: "echo \"buy apple\"", status: 0, out: ("buy apple",)),
    (line: 2, part: "read fruit", also: ((4, "< shopping.txt"),), run: "read fruit < shopping.txt", match: "kiwi", status: 0, vars: (fruit: "kiwi"), info: [reads `kiwi`],
      note: [💡 the next line of the file]),
    (line: 3, run: "echo \"buy kiwi\"", status: 0, out: ("buy kiwi",)),
    (line: 2, part: "read fruit", also: ((4, "< shopping.txt"),), run: "read fruit < shopping.txt", status: 1, vars: (fruit: ""), info: [end of the file],
      note: [💡 no more lines: `read` ends with `1`, the loop ends]),
    (line: 5, run: "echo \"done\"", status: 0, out: ("done",)),
  ))
]

#let csv-code = "#!/bin/bash
while IFS=, read user name; do
    echo \"$user: $name\"
done < people.csv
echo \"done\""

#slide[
  == 🐞 `while IFS=, read`
  Read a file with fields separated by `,`

  #debug-run(csv-code, size: 1.15em, columns: (1fr, 1fr), command: "./people.sh", blocks: true, files: (("people.csv", ("alice,Alice Smith", "bob,Bob Jones")),), (
    (line: 2, part: "IFS=, read user name", also: ((4, "< people.csv"),), run: "IFS=, read user name < people.csv", match: "alice,", status: 0,
      vars: (user: "alice", name: "Alice Smith"), info: [reads `alice,Alice Smith`],
      note: [💡 cut only at `,`: the space in `Alice Smith` stays, `name` takes it all]),
    (line: 3, run: "echo \"alice: Alice Smith\"", status: 0, out: ("alice: Alice Smith",)),
    (line: 2, part: "IFS=, read user name", also: ((4, "< people.csv"),), run: "IFS=, read user name < people.csv", match: "bob,", status: 0,
      vars: (user: "bob", name: "Bob Jones"), info: [reads `bob,Bob Jones`],
      note: [💡 the next line of the file]),
    (line: 3, run: "echo \"bob: Bob Jones\"", status: 0, out: ("bob: Bob Jones",)),
    (line: 2, part: "IFS=, read user name", also: ((4, "< people.csv"),), run: "IFS=, read user name < people.csv", status: 1,
      vars: (user: "", name: ""), info: [end of the file],
      note: [💡 no more lines: `read` ends with `1`, the loop ends]),
    (line: 5, run: "echo \"done\"", status: 0, out: ("done",)),
  ))
]

#slide[
  == The Pitfalls of `while`
  The loop only runs a command and looks at its exit code

  // the session takes the width (its lines are long), the file next to it,
  // what goes wrong under it
  #grid(columns: (1fr, auto), column-gutter: 0.8em, [
    #set text(size: 0.95em)
    #reveal-terminal(before: none, lines: (2, 7, 9, 11), full: false)[```terminal
    $ n=2; while $n > 0; do echo "$n..."; done
    bash: 2: command not found
    $ n=2; while [ $n -gt 0 ]; do echo "$n..."; done
    2...
    2...
    2...
    ^C
    $ c=0; cat fruits.txt | while read f; do c=$((c+1)); done; echo $c
    0
    $ c=0; while read f; do c=$((c+1)); done < fruits.txt; echo $c
    7
    ```]
  ], uncover("3-", file-view("fruits.txt", fruits-lines)))
  #[
    #set text(size: 0.85em)
    #only(1)[
      #label[the shell sees the words] #h(0.5em) #words(("2", "cmd"), (">", "redir"), ("0", "redir")) \
      ❌ `$n > 0` is a command line: the command `2`, its output redirected to a *new file* named `0`
    ]
    #only(2)[
      ❌ the body never changes `n`: the condition is always true, the loop runs *forever*, until #kbd("Ctrl") + #kbd("C") \
      💡 change the variable in the body: ```bash n=$((n - 1))```
    ]
    #only(3)[
      ❌ after a `|`, the loop runs in a *copy* of the shell: `c` changes in the copy, the script still sees `0`
    ]
    #only("4-")[
      ✅ with `< fruits.txt` after `done`, the loop runs in the shell itself: `c` is `7`
    ]
  ]
]
