#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Compute #text(size: 10pt, weight: "regular")[\ _Count and combine_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
]

// fruits.txt, the file of the course examples (fruits-lines in shell.typ)
#let fruits = fruits-lines

#slide[
  == `wc`
  🔢 Word count: lines, words and bytes

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 8, 10), full: false)[```terminal
    $ wc fruits.txt
     7  7 44 fruits.txt
    $ wc -l fruits.txt         # lines
    7 fruits.txt
    $ wc -w fruits.txt         # words
    7 fruits.txt
    $ wc -c fruits.txt         # bytes
    44 fruits.txt
    $ wc -l < fruits.txt       # reads stdin
    7
    ```]
  ][
    #file-contents("fruits.txt", fruits)
  ]

  #set text(size: 0.9em)
  #only(1)[💡 the output is `lines  words  bytes  file`]
  #only("2-4")[💡 the options select what to count]
  #only("5-")[💡 when it reads `stdin`, `wc` does not know the name of the file, it prints only the number]
]

// orders.csv: who ordered which fruit, and how many (as in the pipeline example)
#let orders = (
  "name,fruit,count",
  "alice,apple,3",
  "bob,kiwi,1",
  "carol,apple,2",
  "alice,banana,5",
  "dan,apple,1",
  "alice,apple,2",
)

// a sum drawn as chips: the values of the field, `+` between them, `=` the
// result in orange
#let sum-line(values, result, size: 1.5em, sign: "+") = {
  let chip(t, color, fill) = text(size: size, box(inset: (x: 0.3em, y: 0.22em), radius: 0.2em, stroke: 1pt + color, fill: fill,
    text(font: mono, weight: "bold", fill: color, t)))
  let op(t) = text(size: size, weight: "bold", fill: luma(110), font: mono, t)
  let cells = ()
  for (i, v) in values.enumerate() {
    if i > 0 { cells.push(op(sign)) }
    cells.push(chip(v, accent, white))
  }
  cells.push(op("="))
  cells.push(chip(result, changed, changed-fill))
  align(center, grid(columns: cells.len(), column-gutter: 0.3em, align: horizon, ..cells))
}

#slide[
  == What Is `awk`
  A small language for text split into fields

  #cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter]), awk-cond("condition", means: [which lines]), awk-action("{ action }", means: [what to do with them]), awk-end("END { action }", means: [once, at the end]), w("file"))

  #v(0.6em)
  #uncover("2-")[
    #field-line(("alice", "apple", "3"), ",", size: 1.6em, names: ("$1", "$2", "$3"))
    #v(0.2em)
    #align(center)[the whole line is `$0`]
  ]

  #v(0.4em)
  #uncover("3-")[
    #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
      - `awk` reads the lines one by one, splits each one into *fields*
      - for every line: if the *condition* is true, run the *action*
      - no condition: every line; no action: print the line
    ][
      #table(
        columns: (auto, 1fr),
        stroke: none,
        inset: (x: 0.4em, y: 0.25em),
        table.header([*in `awk`*], [*means*]),
        [`$1`, `$2`, ...], [the fields],
        [`NF`], [the number of fields],
        [`NR`], [the number of the line],
        [`s += $3`], [variables start at `0`],
      )
    ]
  ]
]

#slide[
  == `awk`
  🧮 Compute with the fields of every line

  #col-steps((
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-action("{ s += $3 }", means: [every line: add field 3]), awk-end("END { print s }", means: [at the end: print]), w("orders.csv")),
      sum-line(("3", "1", "2", "5", "1", "2"), "14"),
      ("orders.csv", orders, range(2, 8), (1,)), file-contents("stdout", ("14",), size: 1em),
      [💡 `$3` is field 3, like ```bash cut -f3```; `s` starts at `0`; the header `count` is not a number, it adds `0`]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-cond("NR > 1", means: [from line 2]), awk-action("{ s += $3; n++ }", means: [add, count]), awk-end("END { print s / n }", means: [at the end: the average]), w("orders.csv"), size: 0.95em),
      sum-line(("14", "6"), "2.33333", sign: "/"),
      ("orders.csv", orders, range(2, 8), (1,)), file-contents("stdout", ("2.33333",), size: 1em),
      [💡 `NR` is the number of the line: skip the header; `n` counts the orders, 14 / 6 = 2.33]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-cond("$2 == \"apple\"", means: [only the apples]), awk-action("{ s += $3 }", means: [add field 3]), awk-end("END { print s }", means: [at the end: print]), w("orders.csv")),
      sum-line(("3", "2", "1", "2"), "8"),
      ("orders.csv", orders, (2, 4, 6, 7), (1, 3, 5)), file-contents("stdout", ("8",), size: 1em),
      [💡 a condition before `{ }`: only the lines where field 2 is `apple`; `awk` can search, cut and compute]),
  ))
]

#slide[
  == `awk` Conditions
  Combine them, match a regex, use several of them

  #col-steps((
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-cond("$2 == \"apple\" && $3 >= 2", means: [apples *and* at least 2]), awk-action("{ s += $3 }", means: [add field 3]), awk-end("END { print s }", means: [at the end]), size: 0.95em),
      sum-line(("3", "2", "2"), "7"),
      ("orders.csv", orders, (2, 4, 7), (1, 3, 5, 6)), file-contents("stdout", ("7",), size: 1em),
      [💡 `&&` - and, `||` - or, `!` - not, as in C; `dan` ordered only 1 apple, so he is skipped]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-cond("$2 ~ /an/", means: [field 2 matches the regex `an`]), awk-action("{ print $1, $2 }", means: [print fields 1 and 2]), size: 0.95em),
      field-line(("alice", "banana", "5"), ",", size: 1.3em, selected: (1, 2), names: ("$1", "$2", "$3")),
      ("orders.csv", orders, (5,), (1, 2, 3, 4, 6, 7)), file-contents("stdout", ("alice banana",), size: 1em),
      [💡 `~` - matches a regex (see _Search_), `!~` - does not match; ```bash print $1, $2``` puts a space between them]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-cond("$2 == \"apple\"", means: [apples]), awk-action("{ a += $3 }", means: [add to `a`]), awk-cond("$2 == \"banana\"", means: [bananas]), awk-action("{ b += $3 }", means: [add to `b`]), awk-end("END { print a, b }", means: [at the end]), size: 0.82em),
      grid(columns: 2, column-gutter: 2.5em, align: center + horizon, [#sum-line(("3", "2", "1", "2"), "8", size: 1.2em) #text(weight: "bold", fill: ok-color)[a: apples]], [#sum-line(("5",), "5", size: 1.2em) #text(weight: "bold", fill: ok-color)[b: bananas]]),
      ("orders.csv", orders, (2, 4, 5, 6, 7), (1, 3)), file-contents("stdout", ("8 5",), size: 1em),
      [💡 every line is checked against *every* pair: two sums in one pass over the file]),
  ))
]
