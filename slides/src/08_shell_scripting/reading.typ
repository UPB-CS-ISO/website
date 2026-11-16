#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Reading Input #text(size: 10pt, weight: "regular")[\ _Ask the user while the script runs_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.13 - _Reading User Input_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3 - _Funcționalități pentru scripturi shell_
]

#slide[
  == `read` Syntax
  Read one line from `stdin` into variables

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.35em)
    #highlight-code(("all", (1,), (2,), (3,), (4,), (5,), "all"))[```bash
read NAME
read -p "Your name: " NAME
read first last
read -r line
read -s password
```]
  ][
    #set text(size: 0.85em)
    #uncover("2-")[#block[- `read` - a *built-in*: waits for a line (until #kbd("Enter")), puts it in `NAME`]]
    #uncover("3-")[#block[- `-p` - write a _prompt_ (a question) first]]
    #uncover("4-")[#block[- several names - the line is *cut at `IFS`*, one word for every variable]]
    #uncover("5-")[#block[- `-r` - _raw_: keep the `\` characters as they are]]
    #uncover("6-")[#block[- `-s` - _silent_: do not show what the user types]]
  ]

  #v(0.3em)
  #only("7-")[💡 `read` ends with `0` if it read a line, with `1` at the end of the input (#kbd("Ctrl") + #kbd("D")) - `while read` (_Loops_) stops on it]
]


#slide[
  == `IFS=: read`
  `IFS` changes only for this `read`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #label[the first line of `/etc/passwd`] \
    #ifs-line("root:x:0:0:root:/root:/bin/bash", (":",))
  ][
    #set text(size: 0.85em)
    #uncover("2-")[
      #label[the shell sees] \
      #command-words("IFS=: read user x uid rest < /etc/passwd")
    ]
  ]
  #[
    #set text(size: 1.15em)
    #reveal-terminal(before: none, lines: (2, 7), full: false)[```terminal
    $ head -n 1 /etc/passwd
    root:x:0:0:root:/root:/bin/bash
    $ IFS=: read user x uid rest < /etc/passwd
    $ echo "$user has UID $uid"
    root has UID 0
    $ echo "$rest"
    0:root:/root:/bin/bash
    ```]
  ]

  #v(0.3em)
  #uncover("2-")[
    #shell-first[`NAME=value` before a command - a variable *only for that command*: after `read`, `IFS` is back to space, tab, newline]
  ]
]

#let hello-code = "#!/bin/bash
read -p \"Full name: \" first last
echo \"$last, $first\"
IFS=: read -p \"Date: \" d m y
echo \"$y-$m-$d\""

#slide[
  == 🐞 `read`
  The script stops and waits for the keyboard

  #debug-run(hello-code, size: 1em, columns: (3fr, 2fr), command: "./hello.sh", blocks: true, (
    (line: 2, run: "read -p \"Full name: \" first last", status: 0, out: ("Full name: Alice Mary Smith",),
      vars: (first: "Alice", last: "Mary Smith"), info: [reads `Alice Mary Smith`],
      note: [💡 `read` writes the question, then *waits* for a line: the user types `Alice Mary Smith` and #kbd("Enter")]),
    (line: 3, run: "echo \"Mary Smith, Alice\"", status: 0, out: ("Mary Smith, Alice",),
      note: [💡 cut at the spaces, one word for every variable, the *last* takes the rest #h(0.4em) #box(baseline: 35%, read-map(("Alice", "Mary Smith"), ("first", "last")))]),
    (line: 4, part: "IFS=: read -p \"Date: \" d m y", run: "IFS=: read -p \"Date: \" d m y", status: 0, out: ("Date: 2:11:2026",),
      vars: (d: "2", m: "11", y: "2026"), info: [reads `2:11:2026`],
      note: [💡 `IFS=:` only for this `read`: the line is cut at `:` #h(0.4em) #box(baseline: 35%, ifs-line("2:11:2026", (":",)))]),
    (line: 5, run: "echo \"2026-11-2\"", status: 0, out: ("2026-11-2",),
      note: [💡 after `read`, `IFS` is back to space, tab and newline]),
  ))
]

#slide[
  == The Pitfalls of `read`
  `read` changes the line a little, unless you ask it not to

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    #reveal-terminal(before: none, lines: (6, 12, 14), full: false)[```terminal
    $ cat path.txt
    C:\new\temp
    $ read p < path.txt; echo "$p"
    C:newtemp
    $ read -r p < path.txt; echo "$p"
    C:\new\temp
    $ cat -A spaces.txt
       two  spaces  $
    $ read l < spaces.txt; echo "[$l]"
    [two  spaces]
    $ IFS= read -r l < spaces.txt; echo "[$l]"
    [   two  spaces  ]
    $ echo "Alice Smith" | read first last; echo "[$first]"
    []
    ```]
  ][
    #set text(size: 0.85em)
    #only(1)[
      ❌ without `-r`, `read` treats `\` as an escape and removes it

      ✅ `read -r` keeps the line as it is
    ]
    #only(2)[
      ❌ the spaces at the start and at the end are cut (they are in `IFS`)

      ✅ `IFS=` (empty) for `read`: nothing is cut
    ]
    #only("3-")[
      ❌ after a `|`, `read` runs in a *copy* of the shell: `first` is set in the copy, then lost

      ✅ use `< file`: `read` runs in the shell itself
    ]
  ]

  #v(0.3em)
  #uncover("3-")[💡 to read a line *exactly* as it is: ```bash IFS= read -r line```]
]
