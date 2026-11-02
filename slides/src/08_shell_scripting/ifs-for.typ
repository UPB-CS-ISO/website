#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Using `IFS` with `for` #text(size: 10pt, weight: "regular")[\ _Choose where the list of words is cut_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.2 - _Quoting and Literals_
      - Section 11.6.1 - _for Loops_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == `IFS` and `for`
  Unquoted text is cut at the characters of `IFS`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 1em)
    #reveal-terminal(before: none, lines: (3, 8, 9, 9), full: false)[```terminal
    $ line="apple:kiwi:cherry"
    $ for f in $line; do echo "[$f]"; done
    [apple:kiwi:cherry]
    $ IFS=:
    $ for f in $line; do echo "[$f]"; done
    [apple]
    [kiwi]
    [cherry]
    $ unset IFS
    ```]
  ][
    #set text(size: 0.85em)
    #only(1)[
      #label[the words of the list] \
      #words("apple:kiwi:cherry")

      💡 no space in the text: *one* word, one round
    ]
    #only(2)[
      #label[the words of the list] \
      #words(("apple", "new"), ("kiwi", "new"), ("cherry", "new"))

      💡 `IFS` is now `:` for the *whole shell*: 3 words, 3 rounds
    ]
    #only("3-")[
      ⚠️ every unquoted ```bash $NAME``` that follows is cut at `:` too

      💡 `unset IFS` - back to space, tab and newline
    ]
  ]

  #only("4-")[#popup(width: 24em)[
    #text(weight: "bold", fill: fail-color)[⚠️ Not for one loop]
    #v(-0.2em)
    #set text(size: 0.8em)
    #terminal("$ IFS=: for f in $line; do echo \"[$f]\"; done\nbash: syntax error near unexpected token `do'")
    #v(-0.2em)
    #set text(size: 1.1em)
    `for` is a _keyword_, not a command: `IFS=:` cannot be put in front of it - set `IFS` before the loop, `unset` it after
  ]]
]

#let ifs-for-code = "#!/bin/bash
line=\"apple:kiwi:cherry\"
IFS=:
for f in $line; do
    echo \"[$f]\"
done
unset IFS"

#slide[
  == 🐞 `for` With `IFS`
  `IFS` decides the words of the list

  #debug-run(ifs-for-code, size: 1.25em, columns: (1fr, 1fr), command: "./fruits.sh", blocks: true, (
    (line: 1, vars: (IFS: "space tab newline"), tags: (IFS: [default]),
      note: [💡 the script starts: `IFS` has the *default* value]),
    (line: 2, run: "line=\"apple:kiwi:cherry\"", vars: (line: "apple:kiwi:cherry"),
      note: [💡 no space in the value: with the default `IFS`, it would be *one* word]),
    (line: 3, run: "IFS=:", vars: (IFS: ":"), tags: (IFS: none),
      note: [💡 set `IFS` *before* the loop: `for` is a keyword, `IFS=: for` does not work]),
    (line: 4, part: "$line", info: [cuts the value at `:` #h(0.3em) #ifs-line("apple:kiwi:cherry", (":",))],
      note: [💡 before the loop starts, the shell cuts the value at `:`: the list is `apple kiwi cherry`]),
    (line: 4, expand: "f ", run: "f=apple", vars: (f: "apple")),
    (line: 5, run: "echo \"[apple]\"", status: 0, out: ("[apple]",)),
    (line: 4, expand: "f ", run: "f=kiwi", vars: (f: "kiwi"),
      note: [💡 `done` jumps back, `f` takes the next word]),
    (line: 5, run: "echo \"[kiwi]\"", status: 0, out: ("[kiwi]",)),
    (line: 4, expand: "f ", run: "f=cherry", vars: (f: "cherry")),
    (line: 5, run: "echo \"[cherry]\"", status: 0, out: ("[cherry]",)),
    (line: 7, run: "unset IFS", vars: (IFS: "space tab newline"), tags: (IFS: [not set, default]),
      note: [💡 no more words, the loop ends; `unset IFS` - back to the default for the rest of the script]),
  ))
]

#slide[
  == `for` and `$( )`
  ```bash $(...)```, ```bash "$(...)"``` or `while read`: how many words does the loop get?

  // the session on the left; on the right the file, the output of `$(...)`
  // cut at the characters of IFS (orange), and the words the loop gets
  #let side(seps, ws, tip, what: [the output of `cat`]) = {
    set text(size: 0.85em)
    file-view("people.txt", ("Alice Smith", "Bob Jones"), size: 0.95em)
    v(0.3em)
    label(what)
    linebreak()
    ifs-line("Alice Smith\nBob Jones", seps)
    v(0.1em)
    label[the words of the list]
    linebreak()
    words(..ws)
    v(0.3em)
    tip
  }
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (5, 8, 12, 17), full: false)[```terminal
    $ for n in $(cat people.txt); do echo "[$n]"; done
    [Alice]
    [Smith]
    [Bob]
    [Jones]
    $ for n in "$(cat people.txt)"; do echo "[$n]"; done
    [Alice Smith
    Bob Jones]
    $ IFS=$'\n'
    $ for n in $(cat people.txt); do echo "[$n]"; done
    [Alice Smith]
    [Bob Jones]
    $ unset IFS
    $ while read n; do echo "[$n]"; done < people.txt
    [Alice Smith]
    [Bob Jones]
    ```]
  ][
    #only(1)[#side(blank, (("Alice", "new"), ("Smith", "new"), ("Bob", "new"), ("Jones", "new")),
      [❌ unquoted, the output is cut at *every* space and newline: 4 words, 4 rounds])]
    #only(2)[#side((), (("Alice Smith\\nBob Jones", "new"),),
      [⚠️ quoted, the whole output is *one* word, the newline inside it: 1 round])]
    #only(3)[#side(("\n",), (("Alice Smith", "new"), ("Bob Jones", "new")),
      [💡 ```bash $'\n'``` #bash-tag - a newline: now only newlines cut, 2 words - but `IFS` changed for the whole shell])]
    #only("4-")[#side(("\n",), (("Alice Smith", "new"), ("Bob Jones", "new")),
      [✅ `read` takes a *line*: `for` goes over words, to go over lines, use `while read`],
      what: [what `read` reads, cut at the newlines])]
  ]
]
