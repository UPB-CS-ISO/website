#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Conditions: `if` #text(size: 10pt, weight: "regular")[\ _Run a command, look at its exit code_]
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
  == `if` Runs a Command
  The condition is a *command*: exit code `0` means _true_

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    ```bash
    if command; then
        # runs if command ended with 0
    elif other_command; then
        # runs if other_command ended with 0
    else
        # runs otherwise
    fi
    ```
    #uncover("3-")[
      💡 `fi` is `if` written backwards, `elif` and `else` are optional
    ]
  ][
    #set text(size: 0.85em)
    #uncover("2-")[
      ```bash
      if grep -q kiwi fruits.txt; then
          echo "we have kiwi"
      else
          echo "no kiwi"
      fi
      ```
      #terminal("$ ./kiwi.sh\nwe have kiwi")
    ]
  ]

  #v(0.3em)
  #only(2)[💡 `grep -q` prints nothing, `if` only looks at its exit code]
  #only("3-")[
    #shell-first[`if` does not compute anything: it *runs* the command and checks `$?`, like `&&` and `||`]
  ]
]

#slide[
  == A C-like Condition?
  ```bash a=2; b=3``` - is `a` bigger than `b`?

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (3, 5, 6), full: false)[```terminal
    $ if $a > $b; then echo "yes"; else echo "no"; fi
    bash: 2: command not found
    no
    $ ls 3
    3
    $ cat 3
    ```]
  ][
    #set text(size: 0.9em)
    #label[the condition is the command line] \
    #words(("$a", "cmd"), (">", "redir"), ("$b", "redir"))

    #uncover("2-")[
      #label[after replacing the variables] \
      #words(("2", "cmd"), (">", "redir"), ("3", "redir"))
      - runs the command `2`: not found, exit code `127`, _false_
      - `> 3` - its output goes to a *new file* named `3`
    ]
  ]

  #v(0.3em)
  #only(1)[💡 it looks right, it even prints something that makes sense]
  #only(2)[💡 `>` is a *redirect*, not a comparison]
  #only("3-")[
    #shell-first[`if` takes a command line, so `>` means what it always means in a command line: write the output to a file]
  ]
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
    #reveal-terminal(before: none, lines: (2, 4, 6, 8), full: false)[```terminal
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

#slide[
  == `[` Is a Program
  `[ ... ]` is `test`, with a `]` at the end - nicer to read

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.72em)
    #reveal-terminal(before: none, lines: (4, 6, 8, 11, 14), full: false)[```terminal
    $ type -a [
    [ is a shell builtin
    [ is /usr/bin/[
    [ is /bin/[
    $ ls -l /usr/bin/[
    -rwxr-xr-x 1 root root 55744 Aug 25 18:09 /usr/bin/[
    $ [ $a -lt $b ]; echo $?
    0
    $ [$a -lt $b]; echo $?
    bash: [2: command not found
    127
    $ [ $a -lt $b; echo $?
    bash: [: missing `]'
    2
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 a built-in command of `bash`, and a program too, for the other shells]
    #only(2)[💡 a real executable file, named `[`]
    #only(3)[
      #words(("[", "cmd"), "2", "-lt", "3", ("]", "new"))

      💡 `]` is just the *last parameter* of `[`
    ]
    #only(4)[
      #words(("[2", "cmd"), "-lt", "3]")

      ⚠️ *spaces are mandatory*: without them the command is named `[2`
    ]
    #only("5-")[
      ⚠️ `[` checks that its last parameter is `]`
    ]
  ]

  #v(0.3em)
  #uncover("5-")[
    #shell-first[`if [ $a -lt $b ]` looks like C, but it is the command `[` with four parameters]
  ]
]

#slide[
  == Spaces and Quotes Matter
  `[` only sees *words*

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 5, 7), full: false)[```terminal
    $ [ $a-lt$b ]; echo $?
    0
    $ x=""
    $ [ $x = "abc" ]
    bash: [: =: unary operator expected
    $ [ "$x" = "abc" ]; echo $?
    1
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      #words(("[", "cmd"), ("2-lt3", "new"), "]")

      ⚠️ one word: _"is the text `2-lt3` not empty?"_ - always true
    ]
    #only(2)[
      #words(("[", "cmd"), "=", "abc", "]")

      ⚠️ the empty variable disappears, `[` gets 3 parameters
    ]
    #only("3-")[
      #words(("[", "cmd"), ("\"\"", "new"), "=", "abc", "]")

      💡 with quotes, an empty variable is still a word
    ]
  ]

  #v(0.5em)
  #uncover("3-")[
    #shell-first[the shell splits the line into words *before* `[` starts, `[` cannot know what you meant: always quote the variables, ```bash "$x"```]
  ]
]

#slide[
  == `[[ ]]` and `(( ))`
  Later, `bash` added real syntax for conditions

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - `[[ ... ]]` - like `[`, but a _keyword_ of `bash`: no word splitting, ```bash $x``` may be empty
    #uncover("2-")[#block[- `(( ... ))` - the C-like math of `$(( ))`, as a condition: not `0` is _true_]]
    #uncover("3-")[#block[- they work only in `bash` (and `zsh`), not in `sh`]]
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
]

#let if-code = "#!/bin/bash
age=20
if [ $age -ge 18 ]; then
    echo \"adult\"
else
    echo \"minor\"
fi
echo \"done\""

#slide[
  == 🐞 `if`, Step by Step
  The lines that run, as a debugger shows them

  #debug-run(if-code, (
    (line: 2, run: "age=20", vars: (age: "20"), changed: ("age",),
      note: [💡 a variable, the text `20`]),
    (line: 3, run: "[ 20 -ge 18 ]", status: 0, vars: (age: "20"),
      note: [💡 the shell replaces ```bash $age``` and runs the command `[`: it ends with `0`, _true_]),
    (line: 4, run: "echo \"adult\"", status: 0, vars: (age: "20"), out: ("adult",),
      note: [💡 the `then` branch runs, the `else` branch is skipped]),
    (line: 8, run: "echo \"done\"", status: 0, vars: (age: "20"), out: ("done",),
      note: [💡 after `fi`, the script goes on]),
  ))
]
