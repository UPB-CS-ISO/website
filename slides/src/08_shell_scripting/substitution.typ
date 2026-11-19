#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Command Substitution #text(size: 10pt, weight: "regular")[\ _The output of a command, as text_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.7 - _Command Substitution_
      - Section 11.11 - _Subshells_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.2.2 - _Subshelluri_
      - Section 7.2.4 - _Expandări_
]

// ----- command substitution, drawn -----

// a line of bash with one part boxed in orange, e.g. the `$(command)`
#let boxed-line(before, part, after) = {
  show raw.where(block: false): it => it.lines.join()
  raw(before, lang: "bash")
  box(stroke: 1pt + changed.lighten(30%), fill: changed-fill, outset: (x: 1.5pt, y: 3pt), radius: 2pt, raw(part, lang: "bash"))
  raw(after, lang: "bash")
}

// The shell runs a line with a `$(...)`, drawn as a loop: the shell (top)
// starts a copy of itself (bottom left), the copy runs the command, its
// output is captured (bottom right) and goes back up, into the line.
// `before` + `part` + `after` - the line, the `part` boxed;
// `inner` - the command in the copy (word chips); `result` - the line
// after the replacement; `phase`: none, "read", "child", "back", "done"
#let subst-drawing(before, part, after, inner, result, phase) = {
  let show-if(c, body) = if c { body } else { hide(body) }
  let on(p) = phase == p
  let reached(..ps) = phase in ps.pos()
  let proc(title, body, active) = block(
    width: 100%,
    stroke: if active { 1pt + changed.lighten(45%) } else { 0.8pt + luma(150) },
    fill: if active { changed-fill } else { white },
    radius: 0.3em,
    inset: (x: 0.6em, y: 0.45em),
    {
      text(size: 0.75em, weight: "bold", fill: if active { changed } else { luma(80) }, title)
      v(-0.3em)
      body
    },
  )
  let vertical(angle, active, t) = align(center, [
    #box(rotate(angle, reflow: true, draw-arrow(length: 1.6em, color: if active { changed } else { luma(160) }, thickness: 1.5pt)))
    #h(0.2em)
    #box(baseline: -0.5em, label(t))
  ])
  grid(
    columns: (2fr, auto, 1fr),
    column-gutter: 0.5em,
    row-gutter: 0.4em,
    align: horizon,
    // the shell, with the line before and after the replacement
    grid.cell(colspan: 3, proc([`bash` - the shell], {
      text(size: 1.1em, boxed-line(before, part, after))
      linebreak()
      show-if(on("done"), [#label[then runs] #h(0.3em) #box(text(size: 1.1em, result))])
    }, reached("read", "done"))),
    // the arrows: down - starts the copy, up - the output goes back
    show-if(reached("child", "back", "done"), vertical(90deg, on("child"), [starts a *copy* of itself])),
    [],
    show-if(reached("back", "done"), vertical(-90deg, on("back") or on("done"), [as *text*])),
    // the copy of the shell, and its output
    show-if(reached("child", "back", "done"), proc([`bash` - a copy (a _subshell_)], box(text(size: 1.05em, inner)), on("child"))),
    show-if(reached("child", "back", "done"), [#label[`stdout`] #draw-arrow(length: 1.5em, color: if on("child") { changed } else { luma(160) })]),
    show-if(reached("back", "done"), proc([captured], text(font: mono, size: 1.05em, fill: changed)[output], on("back"))),
  )
}

#slide[
  == Command Substitution Syntax
  ```bash $(command)``` - replaced by the output of the command

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 1.15em)
    #highlight-code(("all", (1,), (1,), (1,), (1,), (2,), (3,), "all"))[```bash
VAR=$(command arg1 arg2)
command1 $(command2 arg)
VAR=`command arg1 arg2`
```]
    #set text(size: 0.7em)
    #uncover("2-")[#block[- ```bash $(command)``` - run the command, put its *output* in its place]]
    #uncover("6-")[#block[- anywhere in a command line, also inside `"..."`]]
    #uncover("7-")[#block[- #raw("`command`", lang: "bash") - the old way to write it]]
  ][
    #let line1 = ("VAR=", "$(command arg1 arg2)", "", words(("command", "cmd"), "arg1", "arg2"),
      [#raw("VAR=", lang: "bash")#text(font: mono, fill: changed)[output]])
    #let line2 = ("command1 ", "$(command2 arg)", "", words(("command2", "cmd"), "arg"),
      words(("command1", "cmd"), ("output", "new")))
    #let line3 = ("VAR=", "`command arg1 arg2`", "", words(("command", "cmd"), "arg1", "arg2"),
      [#raw("VAR=", lang: "bash")#text(font: mono, fill: changed)[output]])
    #only(1)[#subst-drawing(..line1, none)]
    #only(2)[#subst-drawing(..line1, "read")]
    #only(3)[#subst-drawing(..line1, "child")]
    #only(4)[#subst-drawing(..line1, "back")]
    #only(5)[#subst-drawing(..line1, "done")]
    #only(6)[#subst-drawing(..line2, "done")]
    #only("7-")[#subst-drawing(..line3, "done")]
  ]

  #v(0.3em)
  #set text(size: 0.9em)
  #only(2)[💡 before running the line, the shell finds the ```bash $(...)```]
  #only(3)[💡 it starts a *copy of itself* (a _subshell_) that runs the command, with its parameters]
  #only(4)[💡 the output of the command is *captured*, not shown, the last _newline_ is removed]
  #only(5)[💡 the output takes the place of ```bash $(...)```, as text, then the line runs]
  #only(6)[💡 here the output becomes the *parameters* of `command1`]
  #only("7-")[💡 a copy of the shell: a variable changed inside ```bash $(...)``` does not change in the script]
]

#let subst-code = "#!/bin/bash
count=$(wc -l < fruits.txt)
today=$(date +%A)
echo \"$count fruits on $today\"
files=$(ls *.txt)
echo $files"

#slide[
  == 🐞 Command Substitution
  ```bash $(command)``` is replaced by the output of the command

  #debug-run(subst-code, size: 1.05em, columns: (11fr, 9fr), command: "./fruits.sh", blocks: true, files: (("fruits.txt", fruits-lines),), (
    (line: 2, part: "wc -l < fruits.txt", who: "copy", run: "wc -l < fruits.txt", status: 0, info: [prints `7`],
      note: [💡 first, a copy of `bash` runs the command, its output is captured, nothing reaches the screen]),
    (line: 2, run: "count=7", vars: (count: "7"),
      note: [💡 then the output takes the place of ```bash $(...)```, the shell runs the line]),
    (line: 3, part: "date +%A", who: "copy", run: "date +%A", status: 0, info: [prints `Thursday`]),
    (line: 3, run: "today=Thursday", vars: (today: "Thursday")),
    (line: 4, run: "echo \"7 fruits on Thursday\"", status: 0, out: ("7 fruits on Thursday",),
      note: [💡 commands give a result by printing it: capture their output]),
    (line: 5, part: "ls *.txt", who: "copy", run: "ls fruits.txt notes.txt words.txt", status: 0, info: [prints 3 lines],
      note: [💡 the copy expands `*.txt` and runs `ls`: one name per line, captured]),
    (line: 5, run: "files=\"fruits.txt\\nnotes.txt\\nwords.txt\"", vars: (files: "fruits.txt\nnotes.txt\nwords.txt")),
    (line: 6, run: "echo fruits.txt notes.txt words.txt", status: 0, out: ("fruits.txt notes.txt words.txt",),
      note: [💡 unquoted, the _newlines_ of `$files` separate words, like spaces: `echo` gets three parameters]),
  ))
]

#slide[
  == Measuring a Variable
  `wc` counts the text it gets from a pipe

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 1em)
    #reveal-terminal(before: none, lines: (3, 5, 8, 11), full: false)[```terminal
    $ name="Alice Smith"
    $ echo "$name" | wc -c
    12
    $ echo -n "$name" | wc -c
    11
    $ fruits=$(sort -u fruits.txt)
    $ echo "$fruits" | wc -l
    4
    $ x=""
    $ echo "$x" | wc -l
    1
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[`wc -c` counts the characters: `Alice Smith` has `11`, but `echo` adds a newline at the end: `12`]
    #only(2)[`echo -n` - no newline: `11`, the length of the text \ #v(0.3em) 💡 `bash` can also count by itself: ```bash ${#name}``` is `11`]
    #only(3)[`wc -l` counts the lines: `fruits` holds one fruit per line, `apple`, `banana`, `cherry`, `kiwi`: `4`]
    #only("4-")[⚠️ an *empty* variable still gives `1`: `echo` prints the newline anyway \ #v(0.3em) check that it is not empty first]
  ]

  #v(0.3em)
  #uncover("2-")[
    #shell-first[`wc` does not see the variable, only the *text* that `echo` prints: the newline of `echo` counts too]
  ]
]
