#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Column Filters #text(size: 10pt, weight: "regular")[\ _Lines split into fields and characters: `cut`, `tr`, `sed`, `rev`, `nl`_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
  + the manual: ```bash man cut```
]

// fruits.txt, the file of the course examples (fruits-lines in shell.typ)
#let fruits = fruits-lines

#let students = ("name,age,city", "Alice,30,Paris", "Bob,25,London", "Carol,22,Bucharest")
#let people = ("Alice 30 Paris", "Bob   25 London")

// ----- the slides -----

#slide[
  == What Is a Column
  A line split into #text(fill: accent, weight: "bold")[fields] by a #text(fill: changed, weight: "bold")[delimiter]

  #col-steps((
    (none, field-line(("Alice", "30", "Paris"), ","),
      ("students.csv", students, 2), none,
      [💡 a *CSV* file (_comma-separated values_): every line is a row of a table, the `,` separates the columns]),
    (none, field-line(("10.0.0.9", "GET", "/logo.png", "404"), "␣", size: 1.3em),
      ("access.log", ("10.0.0.7 GET /index.html 200", "10.0.0.9 GET /logo.png 404"), 2), none,
      [💡 a log file: a *space* separates the fields; `/etc/passwd` uses `:`, many programs a *tab*]),
    (none, field-line(("Bob", "", "", "25", "London"), "␣", size: 1.4em),
      ("people.txt", people, 2), none,
      [⚠️ *every* space is a delimiter: two spaces next to each other have an *empty* field between them, `25` is field *4*]),
    (none, char-line("banana"),
      ("fruits.txt", fruits.slice(0, 3), 1), none,
      [💡 no delimiter at all: the columns are the *positions* of the characters, from `1`]),
  ))
]

#slide[
  == `cut`
  ✂️ Keep some fields or some characters of every line

  #col-steps((
    (cut-line(param("-d,", color: changed, means: [delimiter `,`]), param("-f1,3", means: [fields 1 and 3]), w("students.csv")),
      field-line(("Alice", "30", "Paris"), ",", selected: (1, 3)),
      ("students.csv", students, 2), "$ cut -d, -f1,3 students.csv\nname,city\nAlice,Paris\nBob,London\nCarol,Bucharest",
      [💡 `-d` - how the line is split, `-f` - which fields to keep, printed with the same delimiter]),
    (cut-line(param("-d,", color: changed, means: [delimiter `,`]), param("-f2", means: [field 2]), w("students.csv")),
      field-line(("Alice", "30", "Paris"), ",", selected: (2,)),
      ("students.csv", students, 2), "$ cut -d, -f2 students.csv\nage\n30\n25\n22",
      [💡 `-f2-3` - the fields 2 to 3, `-f2-` - from field 2 to the end]),
    (cut-line(param("-d' '", color: changed, means: [delimiter space]), param("-f4", means: [field 4]), w("people.txt")),
      field-line(("Bob", "", "", "25", "London"), "␣", size: 1.4em, selected: (4,)),
      ("people.txt", people, 2), "$ cut -d' ' -f4 people.txt\n\n25",
      [⚠️ `Alice` has only 3 fields: an empty line; `tr` fixes this, next]),
    (cut-line(param("-c1-3", means: [characters 1 to 3]), w("fruits.txt")),
      char-line("banana", selected: (1, 2, 3)),
      ("fruits.txt", fruits.slice(0, 3), 1), "$ cut -c1-3 fruits.txt\nban\napp\nche\n...",
      [💡 `-c` counts the *characters*, there is no delimiter]),
  ))
]

#slide[
  == `tr`
  🔡 Translate, delete or squeeze characters

  #col-steps((
    (cmd-line(w("tr", kind: "cmd"), param("a-z", means: [set 1]), param("A-Z", color: changed, means: [set 2]), param("<", color: luma(100), means: [only `stdin`]), w("fruits.txt")),
      char-map("banana".clusters().map(c => (c, upper(c)))),
      ("fruits.txt", fruits.slice(0, 3), 1), "$ tr a-z A-Z < fruits.txt\nBANANA\nAPPLE\nCHERRY",
      [💡 set 1 #arrow set 2, at the *same position*: `a` #arrow `A`, `b` #arrow `B`, ...; `tr` reads only `stdin`]),
    (cmd-line(w("echo", kind: "cmd"), w("call 0722"), pipe-sym, w("tr", kind: "cmd"), param("-d", means: [delete]), param("0-9", means: [the digits])),
      char-map("call 0722".clusters().map(c => (c, if c in "0123456789" { none } else { c }))),
      none, "$ echo 'call 0722' | tr -d 0-9\ncall ",
      [💡 `-d` - one set: its characters are *deleted*, the others stay, the space too]),
    (cmd-line(w("echo", kind: "cmd"), w("too   many"), pipe-sym, w("tr", kind: "cmd"), param("-s", means: [squeeze]), param("' '", means: [the space])),
      char-map(("t", "o", "o", " ", " ", " ", "m", "a", "n", "y").enumerate().map(((i, c)) => (c, if c == " " and i > 3 { none } else { c }))),
      none, "$ echo 'too   many' | tr -s ' '\ntoo many",
      [💡 `-s` - a *run* of the same character becomes only one: the first space stays, the others go]),
  ))
]

#slide[
  == Squeeze the Spaces, then `cut`
  The example with more spaces, again

  #col-steps((
    (cut-line(param("-d' '", color: changed, means: [delimiter space]), param("-f2", means: [field 2]), w("people.txt")),
      field-line(("Bob", "", "", "25", "London"), "␣", size: 1.4em, selected: (2,)),
      ("people.txt", people, 2), "$ cut -d' ' -f2 people.txt\n30\n",
      [⚠️ for `Bob`, field 2 is the *empty* field between the first two spaces]),
    (cmd-line(w("tr", kind: "cmd"), param("-s", means: [squeeze]), param("' '", means: [the space]), w("<"), w("people.txt")),
      char-map(("B", "o", "b", " ", " ", " ", "2", "5", " ", "L", "o", "n", "d", "o", "n").enumerate().map(((i, c)) => (c, if c == " " and i in (4, 5) { none } else { c })), size: 1.3em),
      ("people.txt", people, 2), "$ tr -s ' ' < people.txt\nAlice 30 Paris\nBob 25 London",
      [💡 squeeze the spaces: one space between the fields, no more empty fields]),
    (cmd-line(w("tr", kind: "cmd"), w("-s"), w("' '"), w("<"), w("people.txt"), pipe-sym, w("cut", kind: "cmd"), param("-d' '", color: changed, means: [delimiter space]), param("-f2", means: [field 2])),
      field-line(("Bob", "25", "London"), "␣", size: 1.6em, selected: (2,)),
      ("people.txt", people, 2), "$ tr -s ' ' < people.txt | cut -d' ' -f2\n30\n25",
      [✅ squeeze first, then `cut`: every line has the same fields]),
  ))
]

// the expression of `sed`: 's/find/replace/flags', every part with what it
// means, in the colors of `tr`: what is found blue, what replaces it orange
#let sed-expr(find, repl, flags: none) = {
  let sep(t) = text(font: mono, weight: "bold", fill: luma(110), t)
  let cells = (sep("'"), param("s", color: luma(100), means: [substitute]), sep("/"),
    param(find, means: [find (a regex)]), sep("/"),
    param(repl, color: changed, means: [replace with]), sep("/"))
  if flags != none { cells.push(param(flags, color: ok-color, means: [every match])) }
  cells.push(sep("'"))
  grid(columns: cells.len(), column-gutter: 0.15em, align: center + top, ..cells)
}

#slide[
  == `sed`
  ✏️ Substitute: replace the text that matches a regex

  #col-steps((
    (cmd-line(w("echo", kind: "cmd"), w("apple and apple pie"), pipe-sym, w("sed", kind: "cmd"), sed-expr("apple", "pear")),
      char-map((("apple", "pear"), (" and ", " and "), ("apple", "apple"), (" pie", " pie"))),
      none, "$ echo 'apple and apple pie' | sed 's/apple/pear/'\npear and apple pie",
      [💡 only the *first* match of every line is replaced; `tr` changes characters, `sed` changes words]),
    (cmd-line(w("echo", kind: "cmd"), w("apple and apple pie"), pipe-sym, w("sed", kind: "cmd"), sed-expr("apple", "pear", flags: "g")),
      char-map((("apple", "pear"), (" and ", " and "), ("apple", "pear"), (" pie", " pie"))),
      none, "$ echo 'apple and apple pie' | sed 's/apple/pear/g'\npear and pear pie",
      [💡 `g` - _global_: every match of the line is replaced]),
    (cmd-line(w("echo", kind: "cmd"), w("call 0722 123 456"), pipe-sym, w("sed", kind: "cmd"), w("-E"), sed-expr("[0-9]+", "N", flags: "g")),
      char-map((("call", "call"), (" ", " "), ("0722", "N"), (" ", " "), ("123", "N"), (" ", " "), ("456", "N"))),
      none, "$ echo 'call 0722 123 456' | sed -E 's/[0-9]+/N/g'\ncall N N N",
      [💡 the text to find is a *regex* (see _Search_), `-E` - extended, as ```bash grep -E```]),
    (cmd-line(w("sed", kind: "cmd"), sed-expr(",", "␣", flags: "g"), w("students.csv")),
      char-map((("Alice", "Alice"), (",", " "), ("30", "30"), (",", " "), ("Paris", "Paris"))),
      ("students.csv", students.slice(0, 3), 2), "$ sed 's/,/ /g' students.csv\nname age city\nAlice 30 Paris\nBob 25 London",
      [💡 change the delimiter of the columns: `,` becomes a space]),
  ))
]

// `rev`: the characters of a line, numbered, and under them the same
// characters in the reverse order, with their old positions
#let rev-line(s, size: 1.25em) = {
  let cs = s.clusters()
  let n = cs.len()
  let chip(c, color, fill) = text(size: size, box(inset: (x: 0.25em, y: 0.25em), radius: 0.2em, stroke: 0.8pt + color, fill: fill, text(font: mono, fill: if fill == white { black } else { color }, c)))
  let num(i, color) = text(weight: "bold", fill: color, str(i))
  align(center, grid(
    columns: n,
    column-gutter: 0.15em,
    row-gutter: 0.2em,
    align: center + horizon,
    ..range(n).map(i => num(i + 1, accent)),
    ..cs.map(c => chip(c, accent, white)),
    grid.cell(colspan: n, rotate(90deg, reflow: true, draw-arrow(length: 0.8em, color: changed))),
    ..cs.rev().map(c => chip(c, changed, changed-fill)),
    ..range(n).map(i => num(n - i, changed)),
  ))
}

// `nl`: every line gets a new first column, its number, then a tab
#let nl-lines(lines, size: 1.2em) = {
  let chip(t, color, fill, mono-font: true) = text(size: size, box(inset: (x: 0.3em, y: 0.22em), radius: 0.2em, stroke: 0.8pt + color, fill: fill,
    text(font: mono, fill: if fill == white { black } else { color }, t)))
  let tab = text(size: size, box(inset: (x: 0.3em, y: 0.22em), radius: 0.2em, stroke: 1pt + changed, fill: changed-fill,
    text(size: 0.6em, weight: "bold", fill: changed)[tab]))
  align(center, grid(
    columns: 3,
    column-gutter: 0.25em,
    row-gutter: 0.25em,
    align: (center + horizon, center + horizon, left + horizon),
    ..lines.enumerate().map(((i, l)) => (chip(str(i + 1), changed, changed-fill), tab, chip(l, accent, white))).flatten(),
  ))
}

#slide[
  == `rev`
  🔄 Reverse the characters of every line

  #col-steps((
    (cmd-line(w("rev", kind: "cmd"), w("fruits.txt")),
      rev-line("banana"),
      ("fruits.txt", fruits.slice(0, 3), 1), "$ rev fruits.txt\nananab\nelppa\nyrrehc",
      [💡 every line is reversed, character by character; the *order of the lines* stays (that is `tac`)]),
  ))
]

#slide[
  == `nl`
  🔢 Number the lines

  #col-steps((
    (cmd-line(w("nl", kind: "cmd"), w("fruits.txt")),
      nl-lines(fruits.slice(0, 3)),
      ("fruits.txt", fruits.slice(0, 3), 1), "$ nl fruits.txt\n     1\tbanana\n     2\tapple\n     3\tcherry",
      [💡 _number lines_: a *new first column*, the number of the line, then a tab]),
  ))
]
