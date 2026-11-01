#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Variables #text(size: 10pt, weight: "regular")[\ _Everything is text_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

// ----- the variables of the shell, drawn -----

// a variable of the shell: its name, its value, and a badge if it is
// exported; `state`: "new" (orange - changed on this step), "gone"
// (deleted: struck out, red) or none
#let var-row(name, value, exported: false, state: none) = {
  let color = if state == "new" { changed } else if state == "gone" { fail-color } else { black }
  let t(body) = if state == "gone" { strike(text(fill: color, body)) } else { text(fill: color, body) }
  box(inset: (x: 0.4em, y: 0.3em), radius: 0.2em, fill: if state == "new" { changed-fill } else { none }, {
    set text(font: mono, size: 0.85em)
    t(name)
    t(" = ")
    t("\"" + value + "\"")
    if exported {
      h(0.5em)
      box(fill: if state == "new" { changed } else { accent }, inset: (x: 0.3em, y: 0.15em), radius: 0.2em,
        text(font: "Libertinus Serif", size: 0.8em, fill: white, weight: "bold")[exported])
    }
  })
}

// a process with its variables: `title` (content), `label-text` - what
// the list is, `rows` - var-row()s, or none for an empty list
#let process-vars(title, label-text, rows, width: 100%) = block(
  width: width,
  stroke: 0.8pt + luma(150),
  radius: 0.3em,
  fill: white,
  inset: 0pt,
  clip: true,
  {
    block(width: 100%, fill: luma(235), inset: (x: 0.6em, y: 0.3em), below: 0pt, text(size: 0.8em, weight: "bold", title))
    block(width: 100%, inset: (x: 0.6em, y: 0.4em), above: 0pt, height: 2.2em, {
      label(label-text)
      h(0.6em)
      if rows == none { text(size: 0.8em, fill: luma(150), style: "italic")[none] } else { rows }
    })
  },
)

#slide[
  == Variable Syntax
  Define, use, change, delete and export a variable

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 1em)
    #highlight-code(("all", (1,), (2,), (3,), (4,), (5,), (6,), "all"))[```bash
name="alice"
echo "Hi, $name"
echo "${name}_notes.txt"
name="bob"
unset name
export name="carol"
```]
    #set text(size: 0.8em)
    #uncover("2-")[#block[- `NAME=value` - *define*, no spaces around `=`]]
    #uncover("3-")[#block[- ```bash $NAME``` - *use*: the value takes its place]]
    #uncover("4-")[#block[- ```bash ${NAME}``` - *use*, when letters follow the name]]
    #uncover("5-")[#block[- `NAME=value` again - *change* it]]
    #uncover("6-")[#block[- `unset NAME` - *delete* it]]
    #uncover("7-")[#block[- `export NAME` - *export*: put it in the _environment_]]
  ][
    // the drawing on step `i`
    #let drawing(i) = {
      let shell-rows = if i == 2 { var-row("name", "alice", state: "new") } else if i in (3, 4) {
        var-row("name", "alice")
      } else if i == 5 { var-row("name", "bob", state: "new") } else if i == 6 {
        var-row("name", "bob", state: "gone")
      } else if i >= 7 { var-row("name", "carol", exported: true, state: if i == 7 { "new" } else { none }) } else { none }
      process-vars([`bash` - the shell], [variables], shell-rows)
      v(0.4em)
      block(height: 7.5em, width: 100%, {
        if i == 3 {
          // using the variable: the shell replaces it, then runs the command
          set text(size: 0.9em)
          label[the shell replaces ```bash $name```, then runs]
          v(-0.2em)
          align(center, words(("echo", "cmd"), ("Hi, alice", "new")))
          v(-0.2em)
          terminal("$ echo \"Hi, $name\"\nHi, alice")
        } else if i == 4 {
          // the braces: where the name of the variable ends
          set text(size: 0.9em)
          label[without `{}`, the name goes on: the variable `name_notes` does not exist]
          v(-0.2em)
          terminal("$ echo \"$name_notes.txt\"\n.txt\n$ echo \"${name}_notes.txt\"\nalice_notes.txt")
        } else if i == 6 {
          set text(size: 0.9em)
          label[a deleted variable is *empty*, no error]
          v(-0.2em)
          terminal("$ echo \"Hi, $name\"\nHi, ")
        } else if i >= 7 {
          // exporting: a child process gets a copy of the environment
          align(center, [#box(rotate(90deg, reflow: true, draw-arrow(length: 1.5em, color: if i == 7 { changed } else { luma(150) }))) #h(0.4em) #box(baseline: -0.6em, label[a child process starts with a *copy* of the environment])])
          process-vars([`python3` - a child process], [environment], var-row("name", "carol", state: if i == 7 { "new" } else { none }))
        }
      })
    }
    #for i in range(1, 9) {
      only(i, drawing(i))
    }
  ]
]

#let vars-code = "#!/bin/bash
name=\"alice\"
greeting=\"Hello, $name\"
echo \"$greeting!\"
name=\"bob\"
echo \"$greeting!\""

#slide[
  == 🐞 Variables Hold Text
  ```bash NAME=value``` stores the text, ```bash $NAME``` puts it back

  #debug-run(vars-code, command: "./vars.sh", (
    (line: 2, run: "name=\"alice\"", vars: (name: "alice"),
      note: [💡 `name` holds the text `alice`]),
    (line: 3, run: "greeting=\"Hello, alice\"", vars: (greeting: "Hello, alice"),
      note: [💡 the shell replaces ```bash $name``` *now*: `greeting` holds plain text]),
    (line: 4, run: "echo \"Hello, alice!\"", status: 0, out: ("Hello, alice!",)),
    (line: 5, run: "name=\"bob\"", vars: (name: "bob")),
    (line: 6, run: "echo \"Hello, alice!\"", status: 0, out: ("Hello, alice!",),
      note: [💡 `greeting` did not change: it is text, not a formula]),
  ))
]

#slide[
  == Wrong Definitions
  A space splits the line into words

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 8, 11), full: false)[```terminal
    $ name = "alice"
    bash: name: command not found
    $ name ="alice"
    bash: name: command not found
    $ name= "alice"
    bash: alice: command not found
    $ name=alice smith
    bash: smith: command not found
    $ name="alice smith"
    $ echo "$name"
    alice smith
    ```]
  ][
    #set text(size: 0.9em)
    // how the shell splits the line on every step: the command dark, a
    // `NAME=value` before it dashed (a variable only for that command)
    #let case(chips, body) = [
      #label[the shell sees the words] \
      #v(-0.2em)
      #align(center, text(size: 1.15em, chips))
      #v(0.2em)
      #body
    ]
    #only(1)[#case(words(("name", "cmd"), "=", "alice"))[
      ❌ the command `name`, with the parameters `=` and `alice`
    ]]
    #only(2)[#case(words(("name", "cmd"), "=alice"))[
      ❌ the command `name`, with the parameter `=alice`
    ]]
    #only(3)[#case(words(("name=", "redir"), ("alice", "cmd")))[
      ❌ `name=` - an *empty* variable, only for the command `alice`
    ]]
    #only(4)[#case(words(("name=alice", "redir"), ("smith", "cmd")))[
      ❌ the space ends the value: `name=alice` only for the command `smith`
    ]]
    #only("5-")[#case(words(("name=alice smith", "new")))[
      ✅ one word: *no spaces* around `=`, the quotes keep the space in the value
    ]]
  ]

  #v(0.3em)
  #uncover("3-")[
    #shell-first[a line starts with a *command*; a `NAME=value` word before it is a variable only for that command]
  ]
]
