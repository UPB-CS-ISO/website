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
  == Function Syntax
  Define a new command

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1em)
    #highlight-code(("all", (1,), (2,), (3,), (4,), (5,), (6,), "all", "all", "all"))[```bash
greet() {
    local who="$1"
    echo "Hello, $who!"
    return 0
}
greet alice
```]
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (4,), start: 9, full: false)[```terminal
    $ greet alice
    Hello, alice!
    $ greet
    Hello, !
    ```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- `name() {` - the start, the `()` are *always empty*]]
    #uncover("3-")[#block[- inside: ```bash $1```, ```bash $2```, ... the parameters, ```bash $#``` how many; `local` - a variable only for the function]]
    #uncover("4-")[#block[- the _body_: any commands]]
    #uncover("5-")[#block[- `return N` - leave the function with the *exit code* `N` #exit-code(0), like `exit` for a script]]
    #uncover("6-")[#block[- `}` - the end, the function is now defined]]
    #uncover("7-")[#block[- call it *like any command*: the name, then the words]]
  ]

  #v(0.3em)
  #set text(size: 0.9em)
  #only(8)[💡 define it *before* calling it, `function greet { ... }` is the same thing #bash-tag]
  #only("9-")[
    💡 called like any command; a missing parameter is just *empty*, no error
    #shell-first[a function is called exactly like a program: the command name, then the words - so it gets its parameters the same way a script does]
  ]

  // bash runs commands: a function is one more command
  #only("10-")[
    #popup(color: accent, fill: white, angle: -2deg)[
      #align(center)[
        #text(size: 1.3em, weight: "bold", fill: accent)[🐚 `bash` runs *commands*] \
        #text(size: 1.1em)[a function is a command, defined by the script]
        #v(0.2em)
        #text(size: 1.1em)[a command only *prints* text and ends with an *exit code* #exit-code(0)]
      ]
    ]
  ]
]

#let func-code = "#!/bin/bash
greet() {
    if [ $# -eq 0 ]; then
        return 1
    fi
    echo \"Hello, $1!\"
}
greet alice && echo \"ok\"
greet || echo \"nobody to greet\""

#slide[
  == 🐞 Functions
  A new command: it gets parameters and ends with an exit code

  #debug-run(func-code, command: "./greet.sh", blocks: true, (
    (line: 2, run: "greet() { ... }",
      note: [💡 lines 2 - 7 only *define* the command `greet`, nothing runs]),
    (line: 8, part: "greet alice", run: "greet alice",
      note: [💡 called like any command, the words after the name become its parameters: #param-map("greet", ("alice",))]),
    (line: 3, part: "[ $# -eq 0 ]", also: ((8, "alice"),), run: "[ 1 -eq 0 ]", status: 1, vars: ("$1": "alice", "$#": "1"),
      note: [💡 inside the function: ```bash $1``` and ```bash $#``` come from the call]),
    (line: 6, also: ((8, "alice"),), run: "echo \"Hello, alice!\"", status: 0, out: ("Hello, alice!",),
      note: [💡 no `return`: `greet` ends with the exit code of its last command, `0`]),
    (line: 8, part: "echo \"ok\"", run: "echo \"ok\"", status: 0, unset: ("$1", "$#"), out: ("ok",),
      note: [💡 `greet` ended with `0`: `&&` runs the next command]),
    (line: 9, part: "greet", run: "greet",
      note: [💡 no words after the name, no parameters: #param-map("greet", ())]),
    (line: 3, part: "[ $# -eq 0 ]", run: "[ 0 -eq 0 ]", status: 0, vars: ("$#": "0")),
    (line: 4, run: "return 1", status: 1,
      note: [💡 `return 1`: leave the function with the exit code `1`, an error]),
    (line: 9, part: "echo \"nobody to greet\"", run: "echo \"nobody to greet\"", status: 0, unset: ("$#",), out: ("nobody to greet",),
      note: [💡 `greet` ended with `1`: `||` runs the next command - a function answers like any command]),
  ))
]

#let local-code = "#!/bin/bash
update() {
    local name=\"bob\"
    count=1
}
name=\"alice\"
count=0
update
echo \"$name $count\""

#slide[
  == 🐞 Local Variables
  `local` - a variable that exists only while the function runs

  #debug-run(local-code, command: "./update.sh", blocks: true, (
    (line: 2, run: "update() { ... }",
      note: [💡 lines 2 - 5 only define the function]),
    (line: 6, run: "name=alice", vars: (name: "alice")),
    (line: 7, run: "count=0", vars: (count: "0")),
    (line: 8, run: "update"),
    (line: 3, run: "local name=bob", vars: ("name (local)": "bob"),
      note: [💡 `local`: a *new* `name`, inside the function - the one of the script is not touched]),
    (line: 4, run: "count=1", vars: (count: "1"),
      note: [💡 no `local`: `count` is the variable of the script, *global*]),
    (line: 9, run: "echo \"alice 1\"", status: 0, unset: ("name (local)",), out: ("alice 1",),
      note: [💡 the local `name` is gone with the function, the global `count` keeps `1`]),
  ))
]

#slide[
  == Output or Exit Code
  `bash` runs commands: a command only *prints* and ends with an *exit code*

  // a box of the drawing: a title on top, the content under it
  #let part(title, body, color: accent) = block(stroke: 1pt + color.lighten(30%), radius: 0.35em, inset: (x: 0.7em, y: 0.5em), fill: white,
    align(center)[#text(size: 0.75em, weight: "bold", fill: color, title) \ #body])
  #let to(t, color: luma(130)) = align(center + horizon)[#text(size: 0.75em, fill: luma(110), style: "italic", t) \ #draw-arrow(length: 2.2em, color: color, thickness: 1.5pt)]

  #v(0.5em)
  #align(center, grid(
    columns: 5,
    column-gutter: 0.6em,
    row-gutter: 1.2em,
    align: center + horizon,
    // the command
    grid.cell(rowspan: 2, part([a function, a command], text(size: 1.2em, words(("greet", "cmd"), "alice")))),
    // the output
    to([prints]),
    part([the *output*: text on `stdout`], text(font: mono, fill: changed)[Hello, alice!]),
    to([goes to]),
    part([the screen, or a variable], [
      #text(font: mono, size: 0.9em)[Hello, alice!] \
      #raw("msg=$(greet alice)", lang: "bash")
    ]),
    // the exit code
    to([ends with], color: ok-color),
    part([the *exit code*: `0` - `255`], code-badge(0, size: 2.2em), color: ok-color),
    to([is checked by], color: ok-color),
    part([success or error?], [`if`, `&&`, `||`, ```bash $?``` \ #raw("greet alice && echo ok", lang: "bash")], color: ok-color),
  ))

  #v(0.8em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    block(width: 100%, inset: 0.5em, radius: 0.3em, fill: changed-fill)[
      #text(weight: "bold", fill: changed)[the data, the result] - `echo` it, the caller captures it: ```bash sum=$(add 2 3)```
    ],
    block(width: 100%, inset: 0.5em, radius: 0.3em, fill: ok-color.lighten(88%))[
      #text(weight: "bold", fill: ok-color)[success or error] - ```bash return N``` - *not* the data
    ],
  )
]

#let add-code = "#!/bin/bash
add() {
    echo $(( $1 + $2 ))
}
full_name() {
    echo \"$2, $1\"
}
sum=$(add 2 3)
name=$(full_name Alice Smith)
echo \"$name: $sum\""

#slide[
  == 🐞 Returning a Value
  The function *prints* the result, ```bash $(...)``` captures it as text

  #debug-run(add-code, command: "./values.sh", blocks: true, size: 0.88em, columns: (5fr, 3fr), (
    (line: 2, note: [💡 lines 2 - 7 only *define* `add` and `full_name`, nothing runs]),
    (line: 8, part: "add 2 3", who: "copy", run: "add 2 3",
      note: [💡 inside ```bash $(...)```: a copy of `bash` calls the function, its output will be captured]),
    (line: 3, compute: "$(( $1 + $2 ))", also: ((8, "2"), (8, "3")), vars: ("$1": "2", "$2": "3"), info: [computes `2 + 3` = `5`]),
    (line: 3, also: ((8, "2"), (8, "3")), run: "echo 5", status: 0, info: [prints `5`, captured],
      note: [💡 the number is *printed*, as text - not shown on the screen, ```bash $(...)``` takes it]),
    (line: 8, run: "sum=5", vars: (sum: "5"), unset: ("$1", "$2")),
    (line: 9, part: "full_name Alice Smith", who: "copy", run: "full_name Alice Smith"),
    (line: 6, also: ((9, "Alice"), (9, "Smith")), vars: ("$1": "Alice", "$2": "Smith"), run: "echo \"Smith, Alice\"", status: 0, info: [prints `Smith, Alice`, captured],
      note: [💡 a number or a text: for the shell, both are just *text*]),
    (line: 9, run: "name=\"Smith, Alice\"", vars: (name: "Smith, Alice"), unset: ("$1", "$2")),
    (line: 10, run: "echo \"Smith, Alice: 5\"", status: 0, out: ("Smith, Alice: 5",)),
  ))
]

#slide[
  == Function Pitfalls
  A function is a command: it prints and ends with an exit code, nothing more

  // one pitfall: the wrong command line, its problem highlighted in red,
  // and the correct one, the fix highlighted in green, each with what it
  // prints (pieces: text, or (text, true) for the highlighted part)
  #let line(pieces, color) = {
    show raw.where(block: false): it => it.lines.join()
    box(text(size: 1.25em, pieces.map(p => if type(p) == array {
      box(fill: color.lighten(88%), outset: (y: 3pt), radius: 2pt,
        underline(stroke: 2pt + color, offset: 4pt, raw(p.at(0), lang: "bash")))
    } else { raw(p, lang: "bash") }).join()))
  }
  #let out(t) = box(fill: luma(235), inset: (x: 0.6em, y: 0.35em), radius: 0.3em, text(font: mono, size: 1.05em, fill: luma(80), t))
  #let pitfall(wrong, wrong-out, right, right-out, body) = {
    grid(
      columns: (auto, 1fr),
      column-gutter: 0.8em,
      row-gutter: 0.5em,
      align: (center + horizon, left + horizon),
      text(size: 1.4em)[❌], line(wrong, fail-color),
      [], [#arrow #out(wrong-out)],
      grid.cell(colspan: 2, v(0.3em)),
      text(size: 1.4em)[✅], line(right, ok-color),
      [], [#arrow #out(right-out)],
    )
    v(0.6em)
    text(size: 1.1em, body)
  }

  #only(1)[#pitfall(
    ("big() { ", ("return 300", true), "; }; big; echo $?"), "44",
    ("big() { ", ("echo 300", true), "; }; n=", ("$(big)", true), "; echo $n"), "300")[
    ❌ an exit code is only `0` - `255`: `300` becomes `300 % 256 = 44` \
    💡 *print* numbers, capture them with ```bash $(...)```
  ]]
  #only(2)[#pitfall(
    ("f() { ", ("return 5", true), "; }; ", ("x=$(f)", true), "; echo \"[$x] $?\""), "[] 5",
    ("f() { ", ("echo 5", true), "; }; x=$(f); echo \"[$x] $?\""), "[5] 0")[
    ❌ `return 5` prints nothing: `x` is *empty*, only ```bash $?``` is #exit-code(5) \
    💡 `return` is not the data: *print* the data
  ]]
  #only(3)[#pitfall(
    (("welcome alice", true), "; welcome() { echo \"Hi, $1!\"; }"), "bash: welcome: command not found",
    ("welcome() { echo \"Hi, $1!\"; }; ", ("welcome alice", true)), "Hi, alice!")[
    ❌ called *before* it is defined: the shell does not know the command `welcome` yet \
    💡 define the functions at the top of the script
  ]]
  #only("4-")[#pitfall(
    ("set_x() { x=1; }; x=0; y=", ("$(set_x)", true), "; echo $x"), "0",
    ("set_x() { x=1; }; x=0; ", ("set_x", true), "; echo $x"), "1")[
    ❌ ```bash $(...)``` runs the function in a *copy* of `bash`: the `x` it sets is lost \
    💡 call it directly, a function called in ```bash $(...)``` can only *print*
  ]]
]
