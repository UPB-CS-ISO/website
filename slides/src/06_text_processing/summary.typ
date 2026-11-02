#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Compute #text(size: 10pt, weight: "regular")[\ _Count and combine_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.10 - _Important Shell Script Utilities_ (`awk`)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
  + the manuals: ```bash man wc```, ```bash man awk```
]

// fruits.txt, the file of the course examples (fruits-lines in shell.typ)
#let fruits = fruits-lines

// what `wc` prints, as chips with what they are under them, as
// `field-line` draws the fields: the counts that an option keeps are dark,
// the others faded; `name` - the name of the file, none when `wc` reads
// `stdin` (a dashed chip: there is no name to print)
// #wc-counts(("7", "7", "44"), name: "fruits.txt", selected: (1,))
#let wc-counts(counts, name: none, selected: none, labels: ("lines", "words", "bytes")) = {
  let chip(t, on, off, dashed: false) = text(size: 1.5em, box(
    inset: (x: 0.3em, y: 0.25em),
    radius: 0.2em,
    fill: if on { accent } else { white },
    stroke: if dashed { (paint: luma(160), thickness: 1pt, dash: "dashed") } else if off { 0.6pt + luma(190) } else { 0.8pt + accent },
    text(font: mono, fill: if on { white } else if off { luma(170) } else { black }, if dashed { hide("stdin") } else { t }),
  ))
  let cells = ()
  for (i, c) in counts.enumerate() {
    let on = selected != none and i in selected
    let off = selected != none and not on
    cells.push(stack(spacing: 0.3em, chip(c, on, off),
      text(weight: "bold", fill: if off { luma(170) } else { accent }, labels.at(i))))
  }
  cells.push(stack(spacing: 0.3em, chip(if name == none { "" } else { name }, false, false, dashed: name == none),
    text(weight: "bold", fill: luma(110))[#if name == none [_no name_] else [the file]]))
  align(center, grid(columns: cells.len(), column-gutter: 0.6em, align: center + top, ..cells))
}

#slide[
  == `wc`
  🔢 Word count: lines, words and bytes

  #col-steps((
    (cmd-line(w("wc", kind: "cmd"), w("fruits.txt")),
      wc-counts(("7", "7", "44"), name: "fruits.txt"),
      ("fruits.txt", fruits, ()), "$ wc fruits.txt\n 7  7 44 fruits.txt",
      [💡 _word count_: the lines, the words, the bytes, then the name of the file]),
    (cmd-line(w("wc", kind: "cmd"), param("-l", color: changed, means: [lines]), w("fruits.txt")),
      wc-counts(("7", "7", "44"), name: "fruits.txt", selected: (0,)),
      ("fruits.txt", fruits, range(1, 8)), "$ wc -l fruits.txt\n7 fruits.txt",
      [💡 `-l` - only the number of *lines*: 7 fruits]),
    (cmd-line(w("echo", kind: "cmd"), w("apple and apple pie"), pipe-sym, w("wc", kind: "cmd"), param("-w", color: changed, means: [words])),
      field-line(("apple", "and", "apple", "pie"), "␣", size: 1.3em),
      none, "$ echo 'apple and apple pie' | wc -w\n4",
      [💡 `-w` - the *words*: groups of characters separated by spaces; from `stdin`, no file name]),
    (cmd-line(w("wc", kind: "cmd"), param("-c", color: changed, means: [bytes]), w("fruits.txt")),
      wc-counts(("7", "7", "44"), name: "fruits.txt", selected: (2,)),
      ("fruits.txt", fruits, ()), "$ wc -c fruits.txt\n44 fruits.txt",
      [💡 `-c` - the *bytes*: 37 letters and 7 _newlines_ (one at the end of every line), 44]),
    (cmd-line(w("wc", kind: "cmd"), param("-l", color: changed, means: [lines]), param("<", color: luma(100), means: [`stdin`]), w("fruits.txt")),
      wc-counts(("7",), selected: (0,)),
      ("fruits.txt", fruits, range(1, 8)), "$ wc -l < fruits.txt\n7",
      [💡 the shell opens `fruits.txt`, `wc` reads `stdin`: it does not know the name of the file, it prints only the number]),
  ))
]


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

  #cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter]), awk-quote, awk-cond("condition", means: [which lines]), awk-action("{ action }", means: [what to do with them]), awk-end("END { action }", means: [once, at the end]), awk-quote, w("file"))

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
        [`s`, `n`], [variables: empty, `0` in a sum],
      )
    ]
  ]
]

#slide[
  == `awk`
  🧮 Compute with the fields of every line

  #col-steps((
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-quote, awk-action("{ s += $3 }", means: [every line: add field 3]), awk-end("END { print s }", means: [at the end: print]), awk-quote, w("orders.csv")),
      sum-line(("3", "1", "2", "5", "1", "2"), "14"),
      ("orders.csv", orders, range(2, 8), (1,)), file-contents("stdout", ("14",), size: 1em),
      [💡 `$3` is field 3, like ```bash cut -f3```; the program is in `'...'`, so the shell does not change `$3`]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-quote, awk-cond("NR > 1", means: [from line 2]), awk-action("{ s += $3; n++ }", means: [add, count]), awk-end("END { print s / n }", means: [at the end: the average]), awk-quote, w("orders.csv"), size: 0.95em),
      sum-line(("14", "6"), "2.33333", sign: "/"),
      ("orders.csv", orders, range(2, 8), (1,)), file-contents("stdout", ("2.33333",), size: 1em),
      [💡 `NR` is the number of the line: skip the header; `n` counts the orders, 14 / 6 = 2.33]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-quote, awk-cond("$2 == \"apple\"", means: [only the apples]), awk-action("{ s += $3 }", means: [add field 3]), awk-end("END { print s }", means: [at the end: print]), awk-quote, w("orders.csv"), size: 0.95em),
      sum-line(("3", "2", "1", "2"), "8"),
      ("orders.csv", orders, (2, 4, 6, 7), (1, 3, 5)), file-contents("stdout", ("8",), size: 1em),
      [💡 a condition before `{ }`: only the lines where field 2 is `apple`; `awk` can search, cut and compute]),
  ))
]

#slide[
  == `awk` Conditions
  Combine them, match a regex, use several of them

  #col-steps((
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-quote, awk-cond("$2 == \"apple\" && $3 >= 2", means: [apples *and* at least 2]), awk-action("{ s += $3 }", means: [add field 3]), awk-end("END { print s }", means: [at the end]), awk-quote, size: 0.95em),
      sum-line(("3", "2", "2"), "7"),
      ("orders.csv", orders, (2, 4, 7), (1, 3, 5, 6)), file-contents("stdout", ("7",), size: 1em),
      [💡 `&&` - and, `||` - or, `!` - not, as in C; `dan` ordered only 1 apple, so he is skipped]),
    (cmd-line(w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-quote, awk-cond("$2 ~ /an/", means: [field 2 matches the regex `an`]), awk-action("{ print $1, $2 }", means: [print fields 1 and 2]), awk-quote, size: 0.95em),
      field-line(("alice", "banana", "5"), ",", size: 1.3em, selected: (1, 2), names: ("$1", "$2", "$3")),
      ("orders.csv", orders, (5,), (1, 2, 3, 4, 6, 7)), file-contents("stdout", ("alice banana",), size: 1em),
      [💡 `~` - matches a regex (see _Search_), `!~` - does not match; ```bash print $1, $2``` puts a space between them]),
    // two pairs: the second one under the first (a newline inside the quotes
    // is fine for `awk`), the sum of each pair next to it
    (align(center, text(size: 0.9em, grid(columns: 9, column-gutter: 0.35em, row-gutter: 0.3em, align: center + top,
        w("awk", kind: "cmd"), awk-delim("-F,", means: [delimiter `,`]), awk-quote, awk-cond("$2 == \"apple\"", means: [apples]), awk-action("{ a += $3 }", means: [add to `a`]), [], [],
        h(0.3em), align(left, sum-line(("3", "2", "1", "2"), "8", size: 0.85em)),
        [], [], [], awk-cond("$2 == \"banana\"", means: [bananas]), awk-action("{ b += $3 }", means: [add to `b`]), awk-end("END { print a, b }", means: [at the end]), awk-quote,
        h(0.3em), align(left, sum-line(("5",), "5", size: 0.85em))))),
      none,
      ("orders.csv", orders, (2, 4, 5, 6, 7), (1, 3)), file-contents("stdout", ("8 5",), size: 1em),
      [💡 every line is checked against *every* pair: two sums in one pass over the file]),
  ))
]
