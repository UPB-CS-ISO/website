#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Cleaning Up: `trap` #text(size: 10pt, weight: "regular")[\ _Commands that run when the script ends_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.8 - _Temporary File Management_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.4.1 - _Robustețe_
]

#slide[
  == 🧹 `trap` Syntax
  Remember commands now, run them later

  // the three words of a trap, a label under each one
  #align(center)[
    #set text(size: 1.15em)
    #grid(
      columns: 3,
      column-gutter: 0.6em,
      row-gutter: 0.5em,
      align: center,
      w("trap", kind: "cmd"), w("'rm -f \"$tmp\"'", kind: "new"), w("EXIT"),
      uncover("2-", label[the command]),
      uncover("3-", label[what to run, in single quotes]),
      uncover("4-", label[when to run it]),
    )
  ]

  #v(0.4em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #uncover("2-")[#block[- `trap` runs *nothing* now: `bash` *remembers* the commands]]
    #uncover("3-")[#block[- the single quotes keep `$tmp` as it is: it is replaced when the trap runs]]
    #uncover("5-")[#block[- `trap -p` lists the traps, `trap - EXIT` forgets one]]  ][
    #set text(size: 0.8em)
    #uncover("4-")[
      #table(
        columns: (auto, 1fr),
        inset: (x: 0.5em, y: 0.4em),
        table.header([*When*], [*The commands run*]),
        [`EXIT`], [when the script ends, however it ends: after the last line, at `exit`, or stopped by `set -e`],
        [`ERR`], [after every command that fails, where `set -e` would stop],
      )
    ]
  ]
]

// ----- when the traps run: mango.sh in the debugger -----

#let mango-code = "#!/bin/bash
set -e
tmp=$(mktemp)
trap 'rm -f \"$tmp\"; echo \"removed $tmp\"' EXIT
trap 'echo \"failed at line $LINENO\" >&2' ERR
sort fruits.txt > \"$tmp\"
grep -q mango \"$tmp\"
echo \"found a mango\""

#let tmp-name = "/tmp/tmp.7gIFP38nMM"

#slide[
  == 🐞 When the Traps Run
  `ERR` after a command that fails, `EXIT` when the script ends

  #debug-run(mango-code, size: 0.85em, columns: (5fr, 3fr), command: "./mango.sh", blocks: true, (
    (line: 2, run: "set -e", status: 0, info: [turns on _errexit_]),
    (line: 3, part: "mktemp", who: "copy", run: "mktemp", status: 0, info: [prints the name],
      note: [💡 `mktemp` creates a new, *empty* file with a unique name in `/tmp`, and prints its name]),
    (line: 3, run: "tmp=" + tmp-name, vars: (tmp: tmp-name),
      note: [💡 `tmp` keeps the name of the temporary file]),
    (line: 4, run: "trap 'rm -f \"$tmp\"; echo \"removed $tmp\"' EXIT", status: 0, info: [nothing runs now],
      note: [💡 `bash` *remembers* the commands, for when the script ends; the single quotes keep `$tmp` for then]),
    (line: 5, run: "trap 'echo \"failed at line $LINENO\" >&2' ERR", status: 0, info: [nothing runs now],
      note: [💡 remembered too, for after a command that fails]),
    (line: 6, run: "sort fruits.txt > " + tmp-name, status: 0,
      note: [💡 `sort` writes the sorted fruits into the temporary file]),
    (line: 7, run: "grep -q mango " + tmp-name, status: 1,
      note: [💡 there is no `mango`: `grep` ends with #exit-code(1)]),
    (line: 5, part: "echo \"failed at line $LINENO\" >&2", run: "echo \"failed at line 7\" >&2", status: 0, out: ("failed at line 7",),
      note: [💡 a command failed: first, the `ERR` trap runs - `$LINENO` is `7`, the line of `grep`]),
    (line: 7, info: [`set -e` stops the script],
      note: [💡 nobody checks the exit code of `grep`: `set -e` stops the script, line 8 never runs]),
    (line: 4, part: "rm -f \"$tmp\"", run: "rm -f " + tmp-name, status: 0,
      note: [💡 the script ends: now the `EXIT` trap runs, and deletes the temporary file]),
    (line: 4, part: "echo \"removed $tmp\"", run: "echo \"removed " + tmp-name + "\"", status: 0, out: ("removed " + tmp-name,),
      note: [💡 the script ends with #exit-code(1), the exit code of `grep`; with a `mango`, the same `EXIT` trap runs after line 8]),
  ))
]
