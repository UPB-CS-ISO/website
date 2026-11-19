#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Strict Mode #text(size: 10pt, weight: "regular")[\ _`set -e`, `set -u` and `set -o pipefail`_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.4 - _Exit Codes_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.4.1 - _Robustețe_
]

#let tidy-code = "#!/bin/bash
# clean up the photos
cd photoz
rm -f *.tmp
echo \"photos cleaned\""

#let tidy-e-code = tidy-code.replace("cd photoz", "set -e\ncd photoz")

#slide[
  == 🐞 `set -e`: Stop at the First Error
  The first command that fails ends the script, with its exit code

  #debug-run(tidy-e-code, size: 1.2em, columns: (11fr, 9fr), command: "./tidy.sh", blocks: true, (
    (line: 3, run: "set -e", status: 0, info: [turns on _errexit_],
      note: [💡 `set` changes the options of the shell that runs the script]),
    (line: 4, run: "cd photoz", status: 1, info: [the script stops], out: ("./tidy.sh: line 4: cd: photoz: No such file or directory",),
      note: [💡 nobody checks the exit code of `cd`: lines 5 and 6 never run, the script ends with #exit-code(1)]),
  ))
]

// a line of a script, with set -e: what happens when its first command
// fails; `stops`: true if the script stops (🛑), false if it goes on (✅)
#let errexit-row(code, stops, what) = (
  raw(code, lang: "bash"),
  if stops [🛑 *stops*] else [✅ goes on],
  what,
)

#slide[
  == When `set -e` Does Not Stop
  A command whose exit code is *checked* may fail

  #set text(size: 0.85em)
  #table(
    columns: (auto, auto, 1fr),
    inset: (x: 0.5em, y: 0.4em),
    align: (left, left, left),
    table.header([*Line, with `set -e`*], [*If it fails*], [*Why*]),
    ..errexit-row("cd photoz", true, [nobody checks the exit code of `cd`]),
    ..errexit-row("cd photoz || exit 2", true, [with your exit code, `2`: `||` checks `cd`]),
    ..errexit-row("grep -q mango fruits.txt || echo \"none\"", false, [`||` checks `grep`, `echo` runs]),
    ..errexit-row("if grep -q mango fruits.txt; then", false, [the condition of `if`, `while`, `until` may fail]),
    ..errexit-row("! grep -q mango fruits.txt", false, [`!` checks it and turns the exit code around]),
  )

  #v(0.4em)
  #only(1)[💡 that is how you allow a failure: check it]

  #only("2-")[
    #popup(width: 21em)[
      #text(size: 1.1em, weight: "bold", fill: fail-color)[⚠️ A count that stops the script]
      #v(-0.2em)
      #set text(size: 0.9em)
      ```bash
      set -e
      n=0
      ((n++))
      echo "n is $n"
      ```
      #v(-0.3em)
      `((n++))` computes the *old* value of `n`, `0`: it ends with #exit-code(1), and the script stops in silence \
      💡 count with ```bash n=$((n + 1))```
    ]
  ]
]

#let clean-code = "#!/bin/bash
set -u
dir=~/backup
rm -r \"$dri\"/*"

#slide[
  == `set -u`: Unset Variables Are Errors
  A typo in a name is not an empty text

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.05em)
    // step 1: the line with the typo; then `set -u` and the line where it stops
    #only(1)[#code-panel("clean.sh", clean-code.replace("set -u\n", ""), hl: (3,))]
    #only("2-")[#code-panel("clean.sh", clean-code, hl: (2, 4))]
  ][
    #set text(size: 0.9em)
    #only(1)[
      #label[without `set -u`, `$dri` is empty, the shell runs]
      #v(-0.2em)
      #text(size: 1.2em, words(("rm", "cmd"), "-r", ("/*", "new")))
      #v(0.2em)
      ⚠️ it deletes every file under `/` that `alice` may delete: her whole home
    ]
    #only("2-")[
      #label[with `set -u`, the script stops before `rm` runs]
      #terminal("$ ./clean.sh\n./clean.sh: line 4: dri: unbound variable\n$ echo $?\n1")
    ]
  ]
]

#let greet-code = "#!/bin/bash
set -u
echo \"Hello, $1!\""

#let greet-checked = "#!/bin/bash
set -u
if [ $# -eq 0 ]; then
    echo \"usage: $0 <NAME>\" >&2
    exit 1
fi
echo \"Hello, $1!\""

#slide[
  == `set -u` and the Parameters
  `$1` is not set when the script gets no parameters: check `$#` first

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1em)
    #only(1)[#code-panel("greet.sh", greet-code, hl: (3,))]
    #only("2-")[#code-panel("greet.sh", greet-checked, hl: (3, 4, 5, 6))]
  ][
    #set text(size: 0.95em)
    #only(1)[
      #terminal("$ ./greet.sh alice\nHello, alice!\n$ ./greet.sh\n./greet.sh: line 3: $1: unbound variable")
      #v(0.3em)
      #text(size: 0.85em)[❌ without parameters, `$1` is *not set*: `set -u` stops the script with an error that does not help the user]
    ]
    #only("2-")[
      #terminal("$ ./greet.sh alice\nHello, alice!\n$ ./greet.sh\nusage: ./greet.sh <NAME>\n$ echo $?\n1")
      #v(0.3em)
      #text(size: 0.85em)[✅ `$#` is always set: check it *before* you use `$1`, and say how to run the script]
    ]
  ]
]

#slide[
  == `set -o pipefail`
  A pipe fails when *any* of its commands fails

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - a pipe ends with the exit code of its *last* command (lecture 6)
    #uncover("2-")[#block[- `grep` fails, `wc` works: the pipe ends with #exit-code(0), so `set -e` does not see the error]]
    #uncover("3-")[#block[- `pipefail` - the exit code of the last command that *failed*: #exit-code(2), from `grep`]]
  ][
    #set text(size: 0.95em)
    #reveal-terminal(before: none, lines: (3, 5, 11), full: false)[```terminal
    $ grep kiwi nope.txt | wc -l
    grep: nope.txt: No such file or directory
    0
    $ echo $?
    0
    $ set -o pipefail
    $ grep kiwi nope.txt | wc -l
    grep: nope.txt: No such file or directory
    0
    $ echo $?
    2
    ```]
  ]
]

#slide[
  == All Three: `set -euo pipefail`
  Three options, on the line after the shebang

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #table(
      columns: (auto, auto, 1fr),
      inset: (x: 0.5em, y: 0.4em),
      table.header([*Option*], [*Name*], [*What it does*]),
      [`set -e`], [_errexit_], [stops at the first command that fails, outside a condition],
      [`set -u`], [_nounset_], [a variable that is not set is an error],
      [`set -o pipefail`], [_pipefail_], [a pipe fails when any of its commands fails],
      [`set -x`], [_xtrace_], [prints every command before it runs, like `bash -x`],
    )
    #v(0.3em)
    - `set +e` - with `+`, turns the option off again
  ][
    #set text(size: 1.2em)
    #uncover("2-")[
      #code-panel("backup.sh", "#!/bin/bash\nset -euo pipefail\nmkdir -p ~/backup\ncp ~/notes.txt ~/backup/")
    ]
  ]

  #v(0.5em)
  #uncover("2-")[
    #takeaway[start your scripts like this][
      #raw("set -euo pipefail", lang: "bash") #h(0.3em) #draw-arrow(length: 1.5em) #h(0.3em)
      a mistake stops the script, it does not go on in the wrong place
    ]
  ]
]
