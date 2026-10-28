#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Functions #text(size: 10pt, weight: "regular")[\ _Commands you define yourself_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.7 - _Command Substitution_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.3 - _Funcții_
]

#slide[
  == Defining a Function
  A new command, made of other commands

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    ```bash
    greet() {
        echo "Hello, $1!"
    }
    ```
    - called like any command: `greet alice`
    #uncover("2-")[#block[- the parameters are ```bash $1```, ```bash $2```, ..., their count ```bash $#```]]
    #uncover("3-")[#block[- the `()` are *always empty*: there is no list of parameters]]
    #uncover("4-")[#block[- `function greet { ... }` - the same thing]]
  ][
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 10), full: false)[```terminal
    $ greet alice
    Hello, alice!
    $ greet
    Hello, !
    $ type greet
    greet is a function
    greet ()
    {
        echo "Hello, $1!"
    }
    ```]
  ]

  #v(0.3em)
  #only(2)[💡 a missing parameter is just *empty*, no error]
  #only("3-")[
    #shell-first[a function is called exactly like a program: the command name, then the words - so it gets its parameters the same way a script does]
  ]
]

#slide[
  == Returning a Value
  `return` sets the *exit code*, the result is the *output*

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (4, 7, 10), full: false)[```terminal
    $ add() { echo $(( $1 + $2 )); }
    $ sum=$(add 2 3)
    $ echo "sum is $sum"
    sum is 5
    $ big() { return 300; }
    $ big; echo $?
    44
    $ f() { return 5; }
    $ x=$(f); echo "[$x] $?"
    [] 5
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 the function *prints* the result, ```bash $(...)``` captures it, like for any command]
    #only(2)[⚠️ `return N` is an exit code: `0` - `255`, `300` becomes `300 % 256 = 44`]
    #only("3-")[💡 `return 5` prints nothing: the output is empty, only ```bash $?``` is `5`]
  ]

  #v(0.3em)
  #uncover("3-")[
    #shell-first[a function is a command, and commands have two ways to answer: an *exit code* (yes / no) and an *output* (text)]
  ]
]

#slide[
  == Local Variables
  Variables are *global*, unless you say `local`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (3, 6), full: false)[```terminal
    $ setname() { name="bob"; }
    $ name=alice; setname; echo $name
    bob
    $ setname2() { local name="bob"; }
    $ name=alice; setname2; echo $name
    alice
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[⚠️ the function changed the variable of the script]
    #only("2-")[💡 `local` - the variable exists only inside the function]
  ]
]

#let func-code = "#!/bin/bash
greet() {
    echo \"Hello, $1!\"
    return 0
}
greet alice
greet bob
echo \"status $?\""

#slide[
  == 🐞 Functions, Step by Step
  The lines that run, as a debugger shows them

  #debug-run(func-code, (
    (line: 6, run: "greet alice", vars: ("$1": "alice"), changed: ("$1",),
      note: [💡 lines 2 - 5 only *define* `greet`, the call jumps into it with ```bash $1``` = `alice`]),
    (line: 3, run: "echo \"Hello, alice!\"", status: 0, vars: ("$1": "alice"), out: ("Hello, alice!",)),
    (line: 4, run: "return 0", status: 0, vars: ("$1": "alice"),
      note: [💡 back to the line after the call, ```bash $1``` is the one of the script again]),
    (line: 7, run: "greet bob", vars: ("$1": "bob"), changed: ("$1",)),
    (line: 3, run: "echo \"Hello, bob!\"", status: 0, vars: ("$1": "bob"), out: ("Hello, bob!",)),
    (line: 4, run: "return 0", status: 0, vars: ("$1": "bob")),
    (line: 8, run: "echo \"status 0\"", status: 0, out: ("status 0",),
      note: [💡 ```bash $?``` is the exit code of `greet bob`, set by `return 0`]),
  ))
]
