#import "/src/slides.typ": *
#import "common.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#slide[
  = Exit Codes #text(size: 10pt, weight: "regular")[\ _How a command says if it worked_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.4 - _Exit Codes_
      - Section 11.5 - _Conditionals_ (`&&` and `||`)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.5.3 - _Înlănțuirea comenzilor_
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == Exit Code Syntax
  A number, `0` for _success_

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 1.15em)
    #highlight-code(((1,), (2,), (3,), (4,), (5,), (6,), "all", "all"))[```bash
grep -q kiwi fruits.txt
echo $?
true
false
exit 0
exit 1
```]
  ][
    #set text(size: 0.85em)
    // every command ends with a number
    #grid(
      columns: (auto, auto, auto),
      column-gutter: 0.6em,
      align: horizon,
      words(("grep", "cmd"), "-q", "kiwi", "fruits.txt"),
      [#label[ends with] #draw-arrow(length: 1.5em, color: ok-color)],
      code-badge(0, size: 2em),
    )
    #v(0.2em)
    // the numbers: one success, many errors
    #grid(
      columns: (1fr, 4fr),
      inset: 0.4em,
      fill: (ok-color.lighten(85%), fail-color.lighten(88%)),
      stroke: 0.8pt + luma(170),
      align(center)[*`0`* \ ✅ success],
      align(center)[*`1` ... `255`* \ ❌ an error - the number says *which* (```bash man grep```)],
    )
    // the shell keeps it in $?
    #uncover("2-")[
      #block(stroke: 0.8pt + luma(150), radius: 0.3em, inset: 0.4em, width: 100%)[
        ```bash $?``` = #code-badge(0, size: 1.4em) #h(0.5em) #label[the shell keeps it, until the next command]
      ]
    ]
    // commands that only end with 0 or 1
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 0.6em,
      uncover("3-")[#block(width: 100%, inset: 0.4em, radius: 0.3em, stroke: 0.8pt + luma(170))[#words(("true", "cmd")) #arrow does nothing, #code-badge(0, size: 1.4em)]],
      uncover("4-")[#block(width: 100%, inset: 0.4em, radius: 0.3em, stroke: 0.8pt + luma(170))[#words(("false", "cmd")) #arrow does nothing, #code-badge(1, size: 1.4em)]],
    )
    // a script ends with exit
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 0.6em,
      uncover("5-")[#block(width: 100%, inset: 0.4em, radius: 0.3em, fill: ok-color.lighten(85%))[```bash exit 0``` #arrow the script ends, #code-badge(0, size: 1.4em)]],
      uncover("6-")[#block(width: 100%, inset: 0.4em, radius: 0.3em, fill: fail-color.lighten(88%))[```bash exit 1``` #arrow the script ends, #code-badge(1, size: 1.4em)]],
    )
  ]

  #v(0.3em)
  #set text(size: 0.9em)
  #only(1)[💡 every command ends with an _exit code_, `0` - `255`: ```bash grep -q``` found `kiwi`, `0`]
  #only(2)[💡 ```bash $?``` - the exit code of the last command, it changes after *every* command]
  #only(3)[💡 `true` - a command that does nothing, it only ends with `0`]
  #only(4)[💡 `false` - a command that does nothing, it only ends with `1`]
  #only(5)[💡 ```bash exit 0``` - end the script with _success_]
  #only(6)[💡 ```bash exit 1``` (or `2`, `3`, ...) - end the script with an _error_]
  #only("7-")[💡 `exit` without a number - the exit code of the last command]

  // where the exit code comes from in a C program
  #only("8-")[
    #popup(color: accent, fill: white, dy: 0.5em, angle: 2deg, width: 24em)[
      #text(weight: "bold", fill: accent)[the same number as the `return` of `main` in C]
      #v(-0.2em)
      #grid(
        columns: (auto, auto, auto),
        column-gutter: 0.8em,
        align: horizon,
        [```c
int main(void) {
    ...
    return 0;
}
```],
        [#label[the process ends with] #draw-arrow(length: 1.5em, color: ok-color)],
        code-badge(0),
      )
    ]
  ]
]

#let exit-code-script = "#!/bin/bash
grep -q kiwi fruits.txt
echo \"kiwi: $?\"
grep -q mango fruits.txt
echo \"mango: $?\""

#slide[
  == 🐞 Exit Codes
  Every command ends with a number, `0` means _success_, ```bash $?``` holds it

  #debug-run(exit-code-script, command: "./check.sh", files: (("fruits.txt", fruits-lines),), (
    (line: 2, run: "grep -q kiwi fruits.txt", match: "kiwi", status: 0,
      note: [💡 `kiwi` is in the file: `grep` ends with `0`]),
    (line: 3, run: "echo \"kiwi: 0\"", status: 0, vars: ("$?": "0"), out: ("kiwi: 0",),
      note: [💡 ```bash $?``` - the exit code of the command before, `grep`]),
    (line: 4, run: "grep -q mango fruits.txt", match: "mango", status: 1, vars: ("$?": "0"),
      note: [💡 ```bash $?``` is now the exit code of `echo`; `mango` is not in the file: `grep` ends with `1`]),
    (line: 5, run: "echo \"mango: 1\"", status: 0, vars: ("$?": "1"), out: ("mango: 1",),
      note: [💡 ```bash $?``` - `1`, the exit code of `grep`]),
  ))
]

// ----- the flow of && and || -----

// a command of the flow chart, as word chips; a skipped one, struck out

#let flow-cmd(pos, cmd, name, skipped: false, code: none) = node(pos,
  if skipped { text(fill: luma(160), strike(raw(cmd))) } else [#box(command-words(cmd))#if code != none [ #h(0.2em) #exit-code(code)]],
  name: name, inset: 0pt, stroke: none)
// the question: did the command end with 0?

#let flow-test(pos, name) = node(pos, text(size: 0.8em)[ended \ with `0`?], name: name, shape: fletcher.shapes.diamond,
  fill: luma(245), stroke: 0.8pt + luma(130), inset: 0.35em)
// the end of the line: the shell goes on with the next line

#let flow-end(pos, name) = node(pos, text(size: 0.8em, fill: luma(100), style: "italic")[done], name: name,
  stroke: (paint: luma(150), dash: "dashed", thickness: 0.6pt), radius: 0.3em, inset: 0.4em)
// an arrow of the flow chart: yes (green), no (red) or plain; a branch
// that is not taken (`off`) is light gray and thin

#let flow-arrow(from, to, kind: none, bend: 0deg, off: false) = {
  let color = if off { luma(205) } else if kind == "yes" { ok-color } else if kind == "no" { fail-color } else { luma(130) }
  edge(from, to, "-|>", stroke: (if off { 0.6pt } else { 1pt }) + color, bend: bend,
    label: if kind == "yes" { text(size: 0.75em, fill: color)[yes] } else if kind == "no" { text(size: 0.75em, fill: color)[no] } else { none },
    label-side: left)
}

// a && b: b only if a ended with 0; `taken` - "yes" or "no", the branch
// that runs in an example (none: both are drawn the same); `code` - the
// exit code of a in the example, a receipt next to it

#let flow-and(a, b, taken: none, code: none) = diagram(spacing: (2.6em, 1.4em),
  flow-cmd((0, 0), a, <a>, code: code), flow-arrow(<a>, <t>),
  flow-test((1, 0), <t>), flow-arrow(<t>, <b>, kind: "yes", off: taken == "no"),
  flow-cmd((2, 0), b, <b>, skipped: taken == "no"), flow-arrow(<b>, <e>, off: taken == "no"),
  flow-end((3, 0), <e>), flow-arrow(<t>, <e>, kind: "no", bend: -40deg, off: taken == "yes"),
)

// a || b: b only if a did not end with 0

#let flow-or(a, b, taken: none, code: none) = diagram(spacing: (2.6em, 1.4em),
  flow-cmd((0, 0), a, <a>, code: code), flow-arrow(<a>, <t>),
  flow-test((1, 0), <t>), flow-arrow(<t>, <b>, kind: "no", off: taken == "yes"),
  flow-cmd((2, 0), b, <b>, skipped: taken == "yes"), flow-arrow(<b>, <e>, off: taken == "yes"),
  flow-end((3, 0), <e>), flow-arrow(<t>, <e>, kind: "yes", bend: -40deg, off: taken == "no"),
)

// a && b || c: the test after b decides for c, and so does the one after a

#let flow-chain(a, b, c) = diagram(spacing: (1.9em, 1.4em),
  flow-cmd((0, 0), a, <a>), flow-arrow(<a>, <t1>),
  flow-test((1, 0), <t1>), flow-arrow(<t1>, <b>, kind: "yes"),
  flow-cmd((2, 0), b, <b>), flow-arrow(<b>, <t2>),
  flow-test((3, 0), <t2>), flow-arrow(<t2>, <c>, kind: "no"),
  flow-cmd((4, 0), c, <c>), flow-arrow(<c>, <e>),
  flow-end((5, 0), <e>),
  flow-arrow(<t2>, <e>, kind: "yes", bend: -35deg),
  flow-arrow(<t1>, <c>, kind: "no", bend: 30deg),
)

#slide[
  == `&&` and `||` Syntax
  Run a command depending on the exit code of the one before

  #set text(size: 1.05em)
  #highlight-code(((1,), (2,), (3,), "all"))[```bash
command1 && command2
command1 || command2
mkdir Movies && cd Movies || echo "failed"
```]

  #v(0.2em)
  #block(height: 7.5em, width: 100%, {
    set text(size: 0.95em)
    only(1, align(center, flow-and("command1", "command2")))
    only(2, align(center, flow-or("command1", "command2")))
    only("3-", align(center, flow-chain("mkdir Movies", "cd Movies", "echo failed")))
  })

  #set text(size: 0.85em)
  #only(1)[💡 ```bash a && b``` - `b` runs only if `a` ended with `0`, _and then_]
  #only(2)[💡 ```bash a || b``` - `b` runs only if `a` did *not* end with `0`, _or else_]
  #only("3-")[💡 they chain, from left to right: `echo` runs if `mkdir` *or* `cd` failed]
]

#let chain-script = "#!/bin/bash
grep -q kiwi fruits.txt && echo \"kiwi\"
grep -q mango fruits.txt && echo \"mango\"
grep -q mango fruits.txt || echo \"no mango\""

#slide[
  == 🐞 `&&` and `||`
  The exit code of the first command decides if the second one runs

  #debug-run(chain-script, command: "./chain.sh", columns: (2fr, 1fr), size: 1.05em, files: (("fruits.txt", fruits-lines),), (
    (line: 2, part: "grep -q kiwi fruits.txt", run: "grep -q kiwi fruits.txt", match: "kiwi", status: 0),
    (line: 2, part: "echo \"kiwi\"", run: "echo \"kiwi\"", status: 0, out: ("kiwi",),
      note: [💡 `0` - `&&` runs the next command]),
    (line: 3, part: "grep -q mango fruits.txt", run: "grep -q mango fruits.txt", status: 1,
      note: [💡 not `0` - `&&` skips `echo "mango"`, the shell goes to the next line]),
    (line: 4, part: "grep -q mango fruits.txt", run: "grep -q mango fruits.txt", status: 1),
    (line: 4, part: "echo \"no mango\"", run: "echo \"no mango\"", status: 0, out: ("no mango",),
      note: [💡 not `0` - `||` runs it]),
  ))
]

// ----- a pipeline and its exit code -----

// orders.csv: who ordered which fruit, and how many (as in "A Pipeline, Step by Step")
#let orders = (
  "name,fruit,count",
  "alice,apple,3",
  "bob,kiwi,1",
  "carol,apple,2",
  "alice,banana,5",
  "dan,apple,1",
  "alice,apple,2",
)
#let fruit-column = orders.map(l => l.split(",").at(1))

// the text that a command writes, as a box like a file
#let output-box(lines) = file-contents("stdout", lines, size: 0.8em)

// the pipeline and its exit code: the one of the last command, `grep -q`
#let pipeline-code(code) = grid(columns: 3, column-gutter: 0.6em, align: horizon,
  chain(("cut", "grep -q")),
  [#label[the pipeline ends with] #draw-arrow(length: 1.5em, color: if code == 0 { ok-color } else { fail-color })],
  code-badge(code, size: 2.4em))

// the exit code of the pipeline and what `&&` and `||` run after it: the
// command that runs in orange, the one that is skipped struck out
#let and-or(code, yes, no) = {
  let ok = code == 0
  let run(t) = box(inset: (x: 0.4em, y: 0.25em), radius: 0.2em, stroke: 1pt + changed, fill: changed-fill, text(font: mono, fill: changed, weight: "bold", t))
  let skip(t) = box(inset: (x: 0.4em, y: 0.25em), radius: 0.2em, stroke: 0.6pt + luma(190), text(font: mono, fill: luma(170), strike(t)))
  let op(t, on) = text(font: mono, weight: "bold", size: 1.2em, fill: if on { if t == "&&" { ok-color } else { fail-color } } else { luma(180) }, t)
  grid(columns: 4, column-gutter: 0.6em, row-gutter: 0.5em, align: horizon,
    grid.cell(rowspan: 2, code-badge(code, size: 2.4em)),
    op("&&", ok), draw-arrow(length: 1.2em, color: if ok { ok-color } else { luma(200) }), if ok { run(yes) } else { skip(yes) },
    op("||", not ok), draw-arrow(length: 1.2em, color: if ok { luma(200) } else { fail-color }), if ok { skip(no) } else { run(no) },
  )
}

#let and-sym = text(font: mono, weight: "bold", fill: ok-color)[&&]
#let or-sym = text(font: mono, weight: "bold", fill: fail-color)[||]

#slide[
  == The Exit Code of a Pipeline
  The exit code of the *last* command

  #col-steps((
    (cmd-line(w("cut", kind: "cmd"), param("-d,", color: changed, means: [delimiter `,`]), param("-f2", means: [the fruit]), w("orders.csv")),
      field-line(("alice", "apple", "3"), ",", selected: (2,), size: 1.3em),
      ("orders.csv", orders, ()), output-box(fruit-column),
      [💡 keep only the fruit column: we look for a _fruit_, not for a name]),
    (cmd-line(w("cut", kind: "cmd"), w("..."), pipe-sym, w("grep", kind: "cmd"), param("-q", means: [quiet]), param("kiwi", color: ok-color, means: [the fruit])),
      pipeline-code(0),
      ("stdin", fruit-column, (3,)), output-box(()),
      [💡 `-q` (_quiet_) prints nothing, it only ends with `0` - found; the pipeline ends with the exit code of `grep`]),
    (cmd-line(text(fill: luma(110))[_the pipeline_], and-sym, w("echo", kind: "cmd"), w("kiwi ordered"), or-sym, w("echo", kind: "cmd"), w("no kiwi")),
      and-or(0, "echo 'kiwi ordered'", "echo 'no kiwi'"),
      none, "$ cut -d, -f2 orders.csv | grep -q kiwi \\\n  && echo 'kiwi ordered' || echo 'no kiwi'\nkiwi ordered",
      [✅ `kiwi` is in the column: the exit code is `0`, `&&` runs]),
    (cmd-line(w("cut", kind: "cmd"), w("..."), pipe-sym, w("grep", kind: "cmd"), param("-q", means: [quiet]), param("mango", color: fail-color, means: [the fruit])),
      pipeline-code(1),
      ("stdin", fruit-column, ()), output-box(()),
      [💡 no `mango` in the column: `grep` ends with `1`, so does the pipeline]),
    (cmd-line(text(fill: luma(110))[_the pipeline_], and-sym, w("echo", kind: "cmd"), w("mango ordered"), or-sym, w("echo", kind: "cmd"), w("no mango")),
      and-or(1, "echo 'mango ordered'", "echo 'no mango'"),
      none, "$ cut -d, -f2 orders.csv | grep -q mango \\\n  && echo 'mango ordered' || echo 'no mango'\nno mango",
      [💡 the exit code is `1`: `&&` skips its command, `||` runs]),
  ))
]
