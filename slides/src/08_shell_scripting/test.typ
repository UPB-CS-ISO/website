#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Conditions: `test` and `[` #text(size: 10pt, weight: "regular")[\ _Commands that compare_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.5 - _Conditionals_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == `test`
  A command that checks a condition and only sets its exit code

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #table(
      columns: (auto, 1fr),
      table.header([Test], [True (`0`) if]),
      [`N -eq M`, `-ne`], [the numbers are #strong[eq]ual, #strong[n]ot #strong[e]qual],
      [`N -lt M`, `-le`], [#strong[l]ess #strong[t]han, #strong[l]ess or #strong[e]qual],
      [`N -gt M`, `-ge`], [#strong[g]reater #strong[t]han, #strong[g]reater or #strong[e]qual],
      [`S = T`, `S != T`], [the texts are equal, different],
      [`-z S`, `-n S`], [the text is empty, not empty],
      [`-e F`, `-f F`, `-d F`], [`F` exists, is a file, is a directory],
      [`! E`, `E -a E`, `E -o E`], [not, and, or],
    )
  ][
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 7, 9), full: false)[```terminal
    $ a=2; b=3
    $ test $a -lt $b; echo $?
    0
    $ test $a -gt $b; echo $?
    1
    $ test -f fruits.txt; echo $?
    0
    $ if test $a -lt $b; then echo "smaller"; fi
    smaller
    ```]
  ]

  #v(0.3em)
  #only(1)[💡 `2 -lt 3`: true, `test` ends with `0`]
  #only(2)[💡 `2 -gt 3`: false, `test` ends with `1`]
  #only("4-")[
    #shell-first[`<` and `>` are redirects, so the comparisons are *options*: `-lt`, `-gt`, ...]
  ]
]

#let test-code = "#!/bin/bash
a=2
b=3
if test $a -lt $b; then
    echo \"a is smaller\"
fi"

#slide[
  == 🐞 Comparing With `test`
  `test` compares, it only sets its exit code

  #debug-run(test-code, command: "./smaller.sh", blocks: true, (
    (line: 2, run: "a=2", vars: (a: "2")),
    (line: 3, run: "b=3", vars: (b: "3")),
    (line: 4, part: "test $a -lt $b", run: "test 2 -lt 3", status: 0,
      note: [💡 the command `test`, with three parameters: `2 < 3` is true, it ends with `0`]),
    (line: 5, run: "echo \"a is smaller\"", status: 0, out: ("a is smaller",)),
  ))
]

#slide[
  == `[` Is a Program
  `[ ... ]` is `test`, with a `]` at the end - nicer to read

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.72em)
    #reveal-terminal(before: none, lines: (4, 6, 9), full: false)[```terminal
    $ type -a [
    [ is a shell builtin
    [ is /usr/bin/[
    [ is /bin/[
    $ ls -l /usr/bin/[
    -rwxr-xr-x 1 root root 55744 Aug 25 18:09 /usr/bin/[
    $ a=2; b=3
    $ [ $a -lt $b ]; echo $?
    0
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 a built-in command of `bash`, and a program too, for the other shells]
    #only(2)[💡 a real executable file, named `[`]
    #only("3-")[
      #label[the shell sees the words] \
      #words(("[", "cmd"), "2", "-lt", "3", ("]", "new"))

      💡 the command `[`, with four parameters: `]` is just the *last parameter*
    ]
  ]

  #v(0.3em)
  #uncover("3-")[
    #shell-first[`if [ $a -lt $b ]` looks like C, but it is the command `[` with four parameters]
  ]
]

#slide[
  == The Pitfalls of `[`
  `[` only sees *words*

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.72em)
    #reveal-terminal(before: none, lines: (4, 7, 9, 12, 14), full: false)[```terminal
    $ a=2; b=3; x=""
    $ [$a -lt $b]; echo $?
    bash: [2: command not found
    127
    $ [ $a -lt $b; echo $?
    bash: [: missing `]'
    2
    $ [ $a-lt$b ]; echo $?
    0
    $ [ $x = "abc" ]; echo $?
    bash: [: =: unary operator expected
    2
    $ [ "$x" = "abc" ]; echo $?
    1
    ```]
  ][
    #set text(size: 0.9em)
    // what you typed, the mistake underlined (pieces: plain text and
    // (text, true) for the mistake), then how the shell splits the line
    #let typed(color: fail-color, ..pieces) = block(below: 0.8em, {
      show raw.where(block: false): it => it.lines.join()
      label[you typed]
      h(0.4em)
      text(size: 1.1em, pieces.pos().map(p => if type(p) == array {
        underline(stroke: 2pt + color, offset: 3pt, raw(p.at(0), lang: "bash"))
      } else { raw(p, lang: "bash") }).join())
    })
    #let case(chips, body) = [
      #label[the shell sees the words] \
      #v(-0.2em)
      #align(center, text(size: 1.1em, chips))
      #v(0.2em)
      #body
    ]
    #only(1)[#typed(("[$a", true), " -lt ", ("$b]", true))
      #case(words(("[2", "cmd"), "-lt", "3]"))[
      ❌ *no space* after `[`: the command is named `[2`
    ]]
    #only(2)[#typed("[ $a -lt $b", ("  ", true))
      #case(words(("[", "cmd"), "2", "-lt", "3"))[
      ❌ *no* `]`: `[` checks that its last parameter is `]`
    ]]
    #only(3)[#typed("[ ", ("$a-lt$b", true), " ]")
      #case(words(("[", "cmd"), ("2-lt3", "new"), "]"))[
      ❌ *no spaces* around `-lt`: one word, _"is the text `2-lt3` not empty?"_ - always true
    ]]
    #only(4)[#typed("[ ", ("$x", true), " = \"abc\" ]")
      #case(words(("[", "cmd"), "=", "abc", "]"))[
      ❌ an *empty variable*, without quotes, disappears: `[` gets 3 parameters
    ]]
    #only("5-")[#typed(color: ok-color, "[ ", ("\"$x\"", true), " = \"abc\" ]")
      #case(words(("[", "cmd"), ("\"\"", "new"), "=", "abc", "]"))[
      ✅ with quotes, an empty variable is still a word
    ]]
  ]

  #v(0.3em)
  #uncover("5-")[
    #shell-first[the shell splits the line into words *before* `[` starts, `[` cannot know what you meant: spaces everywhere, and quote the variables, ```bash "$x"```]
  ]
]

#let bracket-code = "#!/bin/bash
a=2
b=3
if [$a -lt $b]; then
    echo \"a is smaller\"
else
    echo \"a is not smaller\"
fi"

#slide[
  == 🐞 `[` Needs Spaces
  Without them, `[` is glued to the next word

  #debug-run(bracket-code, command: "./smaller.sh", blocks: true, (
    (line: 2, run: "a=2", vars: (a: "2")),
    (line: 3, run: "b=3", vars: (b: "3")),
    (line: 4, part: "[$a -lt $b]", run: "[2 -lt 3]", status: 127, out: ("./smaller.sh: line 4: [2: command not found",),
      note: [❌ the first word is `[2`: there is no such command - with spaces, the words are `[` `2` `-lt` `3` `]`]),
    (line: 7, run: "echo \"a is not smaller\"", status: 0, out: ("a is not smaller",),
      note: [❌ the condition failed, so the `else` branch runs: the answer is *wrong*]),
  ))
]

#let if-code = "#!/bin/bash
age=15
if [ $age -ge 18 ]; then
    echo \"adult\"
elif [ $age -ge 13 ]; then
    echo \"teenager\"
else
    echo \"child\"
fi
echo \"done\""

#slide[
  == 🐞 `if`, `elif`, `else`
  The first command that ends with `0` chooses the branch

  #debug-run(if-code, command: "./age.sh", (
    (line: 2, run: "age=15", vars: (age: "15")),
    (line: 3, part: "[ $age -ge 18 ]", run: "[ 15 -ge 18 ]", status: 1,
      note: [💡 the condition is the *command* `[`: it ends with `1`, _false_]),
    (line: 5, part: "[ $age -ge 13 ]", run: "[ 15 -ge 13 ]", status: 0,
      note: [💡 so `elif` runs its command: `0`, _true_]),
    (line: 6, run: "echo \"teenager\"", status: 0, out: ("teenager",),
      note: [💡 only this branch runs, `else` is skipped]),
    (line: 10, run: "echo \"done\"", status: 0, out: ("done",),
      note: [💡 after `fi`, the script goes on]),
  ))
]

#slide[
  == `[[ ]]` and `(( ))`
  Later, `bash` added real syntax for conditions

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - `[[ ... ]]` - like `[`, but a _keyword_ of `bash`: no word splitting, ```bash $x``` may be empty
    #uncover("2-")[#block[- `(( ... ))` - the C-like math of `$(( ))`, as a condition: not `0` is _true_]]
  ][
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 4), full: false)[```terminal
    $ if [[ $a -lt $b ]]; then echo "smaller"; fi
    smaller
    $ if (( a < b )); then echo "smaller"; fi
    smaller
    ```]
  ]

  #v(0.5em)
  #uncover("2-")[
    #shell-first[finally a C-like condition: because the shell does not split `(( ))` into words, `<` is not a redirect here]
  ]

  #bash-only[`[[ ]]` and `(( ))`]
]
