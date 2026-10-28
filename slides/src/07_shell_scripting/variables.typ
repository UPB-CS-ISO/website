#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Variables and Arithmetic #text(size: 10pt, weight: "regular")[\ _Everything is text_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.7 - _Command Substitution_
      - Section 11.10 - _Important Shell Script Utilities_ (`expr`)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

#slide[
  == Defining Variables
  ```bash NAME=value```, read it with ```bash $NAME```

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 7, 9), full: false)[```terminal
    $ greeting="Hello"
    $ echo "$greeting, alice"
    Hello, alice
    $ greeting = "Hello"
    bash: greeting: command not found
    $ echo "$greetings, alice"
    , alice
    $ echo "${greeting}s, alice"
    Hellos, alice
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      - the value is *text*, there are no types
      - the shell replaces ```bash $greeting``` with its value *before* running the command
    ]
    #only(2)[
      ⚠️ *no spaces* around `=`

      #shell-first[with spaces it is a command line: the command `greeting`, with the parameters `=` and `Hello`]
    ]
    #only(3)[
      ⚠️ a misspelled or missing variable is *empty*, without any error

      💡 there is no variable `greetings`
    ]
    #only("4-")[
      💡 ```bash ${NAME}``` shows where the name ends
    ]
  ]
]

#slide[
  == Command Substitution
  ```bash $(command)``` - the output of a command, as text

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 7), full: false)[```terminal
    $ count=$(wc -l < fruits.txt)
    $ echo "$count fruits"
    7 fruits
    $ echo "today is $(date +%A)"
    today is Tuesday
    $ files=$(ls *.txt); echo $files
    fruits.txt notes.txt words.txt
    ```]
  ][
    #set text(size: 0.9em)
    - the shell runs the command, then puts its *output* in its place
    #uncover("2-")[#block[- works anywhere in a command line, not only in ```bash NAME=...```]]
    #uncover("3-")[#block[- the last _newline_ of the output is removed]]
  ]

  #v(0.5em)
  #uncover("2-")[
    #shell-first[the way to get a result from a command is to *capture its output*: commands print text]
  ]
]

#slide[
  == Adding Two Numbers?
  ```bash a=2``` and ```bash b=3```

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 7, 9), full: false)[```terminal
    $ a=2; b=3
    $ echo $a+$b
    2+3
    $ echo $a + $b
    2 + 3
    $ $a + $b
    bash: 2: command not found
    $ c=$a+$b; echo $c
    2+3
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      #label[the shell replaces the variables, `echo` receives] \
      #words(("echo", "cmd"), ("2+3", "new"))

      💡 *one* word: `$a`, the text `+`, `$b`
    ]
    #only(2)[
      #label[the shell replaces the variables, `echo` receives] \
      #words(("echo", "cmd"), ("2", "new"), ("+", "new"), ("3", "new"))

      💡 *three* words, `echo` prints them with a space between
    ]
    #only(3)[
      #label[the shell replaces the variables and runs] \
      #words(("2", "cmd"), "+", "3")

      💡 the first word is the *command*: there is no program `2`
    ]
    #only("4-")[
      💡 a variable holds *text*: `c` is the text `2+3`
    ]
  ]

  #v(0.5em)
  #uncover("3-")[
    #shell-first[bash was made to run commands, not to do math: `+` is just a character and a line always starts with a command]
  ]
]

#slide[
  == Arithmetic Expansion
  ```bash $(( expression ))``` - the shell computes it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 7, 9, 11), full: false)[```terminal
    $ a=2; b=3
    $ echo $((a + b))
    5
    $ sum=$((a * b + 1)); echo $sum
    7
    $ echo $((7 / 2))
    3
    $ echo $((2 ** 10))
    1024
    $ echo $((3.5 * 2))
    bash: 3.5 * 2: syntax error: invalid arithmetic operator (error token is ".5 * 2")
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      - inside `$(( ))` the rules are *different*: C-like math
      - spaces are allowed, `$` is not needed
    ]
    #only(2)[💡 `+ - * / % **` and `( )`, like in C]
    #only(3)[💡 *integers* only: `7 / 2` is `3`]
    #only(4)[💡 `**` is the power]
    #only("5-")[
      ⚠️ no decimals in `bash`

      💡 use the `bc` calculator: \ `echo "3.5 * 2" | bc` prints `7.0`
    ]
  ]

  #v(0.5em)
  #uncover("2-")[
    #shell-first[`$(( ))` is a small C-like language added *inside* the command line, the result is replaced back as *text*]
  ]
]

#slide[
  == The Old Way: `expr`
  A *program* that computes, before `$(( ))` existed

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (3, 5, 7, 9), full: false)[```terminal
    $ a=2; b=3
    $ expr $a + $b
    5
    $ expr $a+$b
    2+3
    $ expr $a \* $b
    6
    $ expr $a * $b
    expr: syntax error: unexpected argument ‘fruits.txt’
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[
      #words(("expr", "cmd"), ("2", "new"), ("+", "new"), ("3", "new"))

      💡 three parameters: a number, an operator, a number
    ]
    #only(2)[
      #words(("expr", "cmd"), ("2+3", "new"))

      💡 *one* parameter: nothing to compute, `expr` prints it back
    ]
    #only(3)[
      #words(("expr", "cmd"), "2", ("*", "new"), "3")

      💡 `\*`: the `*` is a character, not a glob
    ]
    #only("4-")[
      #words(("expr", "cmd"), "2", ("fruits.txt", "new"), ("notes.txt", "new"), ("...", "new"), "3")

      ⚠️ the shell *globs* `*` into the file names, before `expr` starts
    ]
  ]

  #v(0.5em)
  #uncover("4-")[
    #shell-first[the shell does not know that `expr` wants math: it expands the command line the same way for every command]
  ]
]
