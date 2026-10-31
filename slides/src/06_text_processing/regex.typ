#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Search #text(size: 10pt, weight: "regular")[\ _Regular expressions and `grep`_]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 20pt)[
      _Some people, when confronted with a problem, think "I know, I'll use regular expressions." Now they have two problems._
    ]

    #v(0.5em)
    Jamie Zawinski (one of the authors of Netscape Navigator)
  ]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.5.1 - `grep`
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.4 - _Expresii regulate_
]

#let fruits = ("banana", "apple", "cherry", "apple", "kiwi", "banana", "apple")

#slide[
  == What Is a Regular Expression
  A pattern that describes text

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - most characters match *themselves*, a few are _special_: `.` is _any character_
    #uncover("2-")[#block[- ```bash grep 'regex' file``` prints the lines that *match*]]
    #uncover("3-")[
      #block[- used by]
      #v(0.2em)
      #align(center, grid(
        columns: 3,
        column-gutter: 0.8em,
        row-gutter: 0.5em,
        align: center + top,
        [#w("grep", kind: "cmd") \ #label[search]],
        [#w("sed", kind: "cmd") \ #label[replace]],
        [#w("awk", kind: "cmd") \ #label[columns]],
        [#w("less", kind: "cmd") #w("vim", kind: "cmd") \ #label[search with #kbd("/")]],
        grid.cell(colspan: 2)[#w("Python") #w("JavaScript") #w("C") #w("Rust") ... \ #label[every programming language]],
      ))
    ]
  ][
    #set text(size: 0.85em)
    #only("1")[#regex-matches(fruits, "a.p")]
    #only("2-")[
      #regex-matches(fruits, "a.p")
      #terminal("$ grep 'a.p' fruits.txt\napple\napple\napple")
    ]
  ]

  // the shell sees the regex first: without quotes it is a glob
  #only("4-")[
    #popup(color: accent, fill: white, angle: -2deg)[
      #align(center, text(size: 1.4em, weight: "bold", fill: accent)[🐚 put the regex between `' '`])
      #v(-0.2em)
      #align(center)[#label[the files in the current directory] #h(0.3em) #text(size: 0.85em, words("banana.txt", "fruits.txt"))]
      #v(-0.2em)
      #align(center, grid(
        columns: (auto, auto, auto),
        column-gutter: 0.8em,
        row-gutter: 0.7em,
        align: horizon + left,
        [✅ ```bash grep 'ba*' fruits.txt```], label[`grep` gets], box(words(("grep", "cmd"), "ba*", "fruits.txt")),
        [❌ ```bash grep ba* fruits.txt```], label[`grep` gets], box(words(("grep", "cmd"), ("banana.txt", "new"), "fruits.txt")),
      ))
      #v(-0.2em)
      #align(center, text(size: 0.85em)[without quotes, the *shell* replaces `ba*` (a glob) with the file names, before `grep` starts])
    ]
  ]
]

// the file the examples search in
#let words = (
  "color",
  "colour",
  "cat",
  "category",
  "concatenate",
  "dog",
  "banana",
  "bat",
  "orange",
  "gal",
  "goal",
  "gooooal",
  "notes.txt",
  "2026-10-04",
  "call 0722 123 456",
)

// a regex drawn piece by piece: every special character is a colored
// chip with what it means under it, the plain text is a white chip; a
// repetition (`+`, `*`, `?`, `{n}`) and the item it repeats are joined by
// a bracket. One color for every kind of special character (orange is
// for the matches, on the right)
#let rx-kinds = (
  text: luma(120),
  anchor: accent,
  class: ok-color,
  repeat: rgb("9a4d76"),
  alt: rgb("b35900"),
  esc: rgb("555555"),
)

// what a piece means, under it
#let rx-label(body, color) = text(size: 0.95em, weight: "bold", fill: color, body)

// one piece: a string is plain text, an array is (text, kind, what it
// means), `means` can be none
#let rx-chip(p, size) = {
  let (t, kind, means) = if type(p) == str { (p, "text", none) } else { p }
  let c = rx-kinds.at(kind)
  let plain = kind == "text"
  stack(
    spacing: 0.4em,
    text(size: size, box(
      inset: (x: 0.3em, y: 0.25em),
      radius: 0.2em,
      fill: if plain { white } else { c.lighten(88%) },
      stroke: if plain { 0.6pt + luma(150) } else { 1pt + c },
      text(font: mono, weight: if plain { "regular" } else { "bold" }, fill: if plain { black } else { c }, t),
    )),
    if means != none { rx-label(means, if plain { luma(110) } else { c }) },
  )
}

// a row of pieces
#let rx-row(pieces, size) = grid(
  columns: pieces.len(),
  column-gutter: 0.45em,
  align: center + top,
  ..pieces.map(p => rx-chip(p, size)),
)

// an item and its repetition: an arrow goes from the repetition (`+`,
// `*`, `?`, `{n}`) back to the item it applies to, a bracket under them
// says what they match together
// ("group", (item, repetition), what they mean)
#let rx-group(pieces, means, size) = context {
  let gap = 0.45em.to-absolute()
  let r = rx-row(pieces, size)
  let w = measure(r).width
  let (w1, w2) = pieces.map(p => measure(rx-chip(p, size)).width)
  let x1 = w1 / 2
  let x2 = w1 + gap + w2 / 2
  let h = 1.2em.to-absolute()
  let head = 0.3em.to-absolute()
  let c = rx-kinds.repeat
  let st = 1.2pt + c
  stack(
    spacing: 0.2em,
    box(width: w, height: h, {
      place(top + left, line(start: (x2, h), end: (x2, 0pt), stroke: st))
      place(top + left, line(start: (x2, 0pt), end: (x1, 0pt), stroke: st))
      place(top + left, line(start: (x1, 0pt), end: (x1, h - head), stroke: st))
      place(top + left, polygon(fill: c, stroke: none, (x1 - head * 0.6, h - head), (x1 + head * 0.6, h - head), (x1, h)))
    }),
    r,
    box(width: w - 0.4em, height: 0.45em, stroke: (left: 1pt + c, right: 1pt + c, bottom: 1pt + c)),
    rx-label(means, c),
  )
}

// the whole regex, `size` - the size of the characters; when there is a
// repetition, every chip leaves room above it for the arrow, so all the
// chips stay on the same line
#let rx-pattern(pieces, size: 2em) = {
  let is-group(p) = type(p) == array and p.at(0) == "group"
  let arrows = pieces.any(is-group)
  align(center, grid(
    columns: pieces.len(),
    column-gutter: 0.6em,
    align: center + top,
    ..pieces.map(p => if is-group(p) {
      rx-group(p.at(1), p.at(2), size)
    } else if arrows {
      stack(spacing: 0.2em, box(height: 1.2em), rx-chip(p, size))
    } else { rx-chip(p, size) }),
  ))
}

// the matches of a regex in some lines, every part of a match in the
// color of the part of the regex that matched it (the same colors as the
// drawing): the plain text in orange, a class in green, a repetition in
// purple, ...; an anchor matches no character, it is a thin corner at its
// place, a repetition that matched nothing is a small dot. `hl` is (a regex with one capture group for every part, the
// kind of every group), the groups cover the whole match, in order
#let rx-matches(lines, hl, size: 0.8em) = block(
  width: 100%,
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  inset: (x: 0.6em, y: 0.5em),
)[
  #let (pattern, kinds) = hl
  #set text(font: mono, size: size)
  #set par(leading: 0.45em)
  #for l in lines {
    let ms = l.matches(regex(pattern))
    if ms.len() == 0 {
      text(fill: dim, l)
    } else {
      let at = 0
      for m in ms {
        if m.start > at { l.slice(at, m.start) }
        let first = true
        for (cap, kind) in m.captures.zip(kinds) {
          if cap == none { continue }
          let c = if kind == "text" { changed } else { rx-kinds.at(kind) }
          if cap == "" and kind == "anchor" {
            // a thin corner at the edge: ⌊ at the start of the match, ⌋ at
            // its end; it takes no space, the text does not move
            let tick = if first { 3pt } else { -3pt }
            box(width: 0pt, {
              place(line(start: (0pt, -0.8em), end: (0pt, 0.22em), stroke: 0.7pt + c.lighten(20%)))
              place(line(start: (0pt, 0.22em), end: (tick, 0.22em), stroke: 0.7pt + c.lighten(20%)))
            })
          } else if cap == "" {
            // a repetition that matched nothing: a small dot under the gap
            box(width: 0pt, place(dx: -1.6pt, dy: 0.15em, circle(radius: 1.6pt, fill: c)))
          } else {
            box(fill: c.lighten(82%), outset: (y: 2pt), radius: 1pt, text(fill: c, weight: "bold", cap))
          }
          first = false
        }
        at = m.end
      }
      if at < l.len() { l.slice(at) }
    }
    linebreak()
  }
]

// a regex made of parts, for #rx-matches: every part is (regex, kind)
// #rx-seq(("g", "text"), ("o*", "repeat"), ("al", "text"))
#let rx-seq(..parts) = (
  parts.pos().map(p => "(" + p.at(0) + ")").join(),
  parts.pos().map(p => p.at(1)),
)

// the examples of a slide, one on every step: on the left the command and
// the regex drawn piece by piece, on the right the matches in `words.txt`;
// a step is (the command, the regex in parts for #rx-matches, a short explanation,
// the regex in pieces, the size of the drawing); the last one stays on
// the next steps (e.g. under a popup)
// the matches were checked against the real `grep` output
#let rx-examples(steps) = {
  let at(i) = if i == steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }
  toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #for (i, (cmd, pattern, explain, pieces, size)) in steps.enumerate() {
      only(at(i))[
        #terminal("$ " + cmd)
        #v(1em)
        #rx-pattern(pieces, size: size)
        #v(1em)
        💡 #explain
      ]
    }
  ][
    #for (i, (cmd, pattern, explain, pieces, size)) in steps.enumerate() {
      only(at(i))[#rx-matches(words, pattern)]
    }
    #set text(size: 0.8em)
    _gray lines do not match, `grep` does not print them_
  ]
}

#slide[
  == Basic Regular Expressions
  Characters, anchors and classes - ```bash grep 'regex'```

  #rx-examples((
    ("grep 'cat' words.txt", rx-seq(("cat", "text")), [most characters match *themselves*: the text `cat`, anywhere in the line],
      (("cat", "text", [just letters]),), 2.4em),
    ("grep 'c.l' words.txt", rx-seq(("c", "text"), (".", "class"), ("l", "text")), [`.` is *any single character*: `col`, `cal`],
      ("c", (".", "class", [any char]), "l"), 2.4em),
    ("grep '^ca' words.txt", rx-seq(("^", "anchor"), ("ca", "text")), [`^` is the *start* of the line],
      (("^", "anchor", [line start]), "ca"), 2.4em),
    ("grep 'r$' words.txt", rx-seq(("r", "text"), ("$", "anchor")), [`$` is the *end* of the line],
      ("r", ("$", "anchor", [line end])), 2.4em),
    ("grep '[0-9]' words.txt", rx-seq(("[0-9]", "class")), [`[ ]` is *one* of the characters inside (a _class_), `0-9` is a range],
      (("[0-9]", "class", [one digit]),), 2.4em),
    ("grep '^[^c]' words.txt", rx-seq(("^", "anchor"), ("[^c]", "class")), [`[^ ]` is one character that is *not* inside],
      (("^", "anchor", [line start]), ("[^c]", "class", [not `c`])), 2.4em),
    ("grep 'go*al' words.txt", rx-seq(("g", "text"), ("o*", "repeat"), ("al", "text")), [`*` repeats the *previous item*, zero or more times: `gal`, `goal`, `gooooal`],
      ("g", ("group", ("o", ("*", "repeat", [0 or more])), [no `o`, one `o`, many `o`]), "al"), 2.4em),
    ("grep '^[a-z]*$' words.txt", rx-seq(("^", "anchor"), ("[a-z]*", "repeat"), ("$", "anchor")), [`*` after a class: any number of characters *from the class*, here the whole line is letters],
      (
        ("^", "anchor", [line start]),
        ("group", (("[a-z]", "class", [a letter]), ("*", "repeat", [0 or more])), [only letters]),
        ("$", "anchor", [line end]),
      ), 2.2em),
    ("grep '\\.' words.txt", rx-seq(("\\.", "esc")), [`\` makes the next character *literal*: a real dot, `.` alone matches every line],
      (("\\.", "esc", [a real dot]),), 2.4em),
  ))

  // the usual mistake: reading a regex as a glob (lecture 4)
  #only("10-")[
    #popup[
      #align(center, text(size: 1.5em, weight: "bold", fill: fail-color)[⚠️ `*` in a regex is *not* `*` in a glob!])
      #v(-0.2em)
      #align(center, grid(
        columns: (auto, auto, auto),
        column-gutter: 0.8em,
        row-gutter: 0.6em,
        align: horizon + left,
        [*glob* (`ls`)], raw("*"), [_any characters_],
        [*regex* (`grep`)], raw("*"), [*repeats* the previous item],
        [*regex* (`grep`)], raw(".*"), [_any characters_],
      ))
    ]
  ]
]

#slide[
  == Extended Regular Expressions
  ```bash grep -E 'regex'```, without `-E` they need a `\`: `\+`, `\?`, `\{ \}`, `\( \)`, `\|`

  #rx-examples((
    ("grep -E '[0-9]+' words.txt", rx-seq(("[0-9]+", "repeat")), [`+` repeats the previous item, *one or more* times, after a class: one or more digits],
      (("group", (("[0-9]", "class", [a digit]), ("+", "repeat", [1 or more])), [1 or more digits]),), 2.4em),
    ("grep -E 'colou?r' words.txt", rx-seq(("colo", "text"), ("u?", "repeat"), ("r", "text")), [`?` makes the previous item *optional*: zero or one time],
      ("colo", ("group", ("u", ("?", "repeat", [0 or 1])), [`u` is optional]), "r"), 2.4em),
    ("grep -E '[0-9]{4}' words.txt", rx-seq(("[0-9]{4}", "repeat")), [`{n}` repeats the previous item *exactly* `n` times],
      (("group", (("[0-9]", "class", [a digit]), ("{4}", "repeat", [4 times])), [4 digits]),), 2.4em),
    ("grep -E '[0-9]{3,4}' words.txt", rx-seq(("[0-9]{3,4}", "repeat")), [`{n,m}` repeats it *between* `n` and `m` times],
      (("group", (("[0-9]", "class", [a digit]), ("{3,4}", "repeat", [3 to 4 times])), [3 or 4 digits]),), 2.4em),
    ("grep -E '(an)+' words.txt", rx-seq(("(?:an)+", "repeat")), [`( )` makes a *group*, `+` after it repeats the whole group: `an` in `orange`, `anan` in `banana`],
      (("group", (("(an)", "class", [a group]), ("+", "repeat", [1 or more])), [`an`, `anan`, ...]),), 2.4em),
    ("grep -E 'b(an)*a' words.txt", rx-seq(("b", "text"), ("(?:an)*", "repeat"), ("a", "text")), [`*` after a group: the whole group, zero or more times, `bat` has no `an` and still matches],
      ("b", ("group", (("(an)", "class", [a group]), ("*", "repeat", [0 or more])), [no `an`, `an`, `anan`, ...]), "a"), 2.4em),
    ("grep -E 'cat|dog' words.txt", ("(cat)|(dog)", ("alt", "alt")), [`|` is *or*: one of the alternatives],
      ("cat", ("|", "alt", [or]), "dog"), 2.4em),
    ("grep -E '\\bcat\\b' words.txt", rx-seq(("\\b", "anchor"), ("cat", "text"), ("\\b", "anchor")), [`\b` is a *word edge*: only the word `cat`, not `category`],
      (("\\b", "anchor", [word edge]), "cat", ("\\b", "anchor", [word edge])), 2.4em),
  ))
]

#slide[
  == RegEx in Action
  Put the pieces together, the matches are highlighted like ```bash grep --color``` does

  #rx-examples((
    ("grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' words.txt", rx-seq(("^", "anchor"), ("[0-9]{4}", "repeat"), ("-", "text"), ("[0-9]{2}", "repeat"), ("-", "text"), ("[0-9]{2}", "repeat"), ("$", "anchor")), [a whole line that is a date],
      (
        ("^", "anchor", [start]),
        ("group", (("[0-9]", "class", none), ("{4}", "repeat", none)), [4 digits]),
        "-",
        ("group", (("[0-9]", "class", none), ("{2}", "repeat", none)), [2 digits]),
        "-",
        ("group", (("[0-9]", "class", none), ("{2}", "repeat", none)), [2 digits]),
        ("$", "anchor", [end]),
      ), 1.05em),
    ("grep '^c.*e$' words.txt", rx-seq(("^", "anchor"), ("c", "text"), (".*", "repeat"), ("e", "text"), ("$", "anchor")), [starts with `c`, *anything*, ends with `e`],
      (
        ("^", "anchor", [line start]),
        "c",
        ("group", ((".", "class", [any char]), ("*", "repeat", [0 or more])), [anything]),
        "e",
        ("$", "anchor", [line end]),
      ), 2.4em),
    ("grep -E '\\b[0-9]{3}\\b' words.txt", rx-seq(("\\b", "anchor"), ("[0-9]{3}", "repeat"), ("\\b", "anchor")), [a *number* of exactly 3 digits: `0722` has 4],
      (
        ("\\b", "anchor", [word edge]),
        ("group", (("[0-9]", "class", [a digit]), ("{3}", "repeat", [3 times])), [3 digits]),
        ("\\b", "anchor", [word edge]),
      ), 1.9em),
  ))
]

#slide[
  == `grep` Options
  Change what `grep` prints

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #table(
      columns: (auto, 1fr),
      table.header([Option], [Prints]),
      [`-n`], [the line #strong[n]umbers too],
      [`-c`], [only the #strong[c]ount of lines],
      [`-v`], [the lines that do *not* match],
      [`-i`], [_ignores_ upper / lower case],
      [`-o`], [#strong[o]nly the matching part],
      [`-q`], [nothing (_quiet_), see _exit codes_],
    )
  ][
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (3, 5, 10, 15, 16), full: false)[```terminal
    $ grep -n 'an' fruits.txt
    1:banana
    6:banana
    $ grep -c 'apple' fruits.txt
    3
    $ grep -v 'apple' fruits.txt
    banana
    cherry
    kiwi
    banana
    $ grep -o 'an' fruits.txt
    an
    an
    an
    an
    $ grep -q 'kiwi' fruits.txt
    ```]
  ]

  #only(5)[💡 `-q` prints nothing: the answer is in the _exit code_ of `grep`, the next section]
]

// all the special characters on one slide, grouped by kind, in the
// colors of the drawings; `-E` marks the ones that need `grep -E`
#let rx-sheet-row(t, kind, means, example, ere: false) = (
  align(center, rx-chip((t, kind, none), 1.15em)),
  [#means #if ere { box(inset: (x: 0.25em, y: 0.1em), radius: 0.2em, fill: luma(235), text(size: 0.75em, font: mono, weight: "bold", fill: luma(90))[-E]) }],
  text(size: 1.1em, raw(example)),
)

#let rx-sheet-card(title, kind, ..rows) = {
  let c = rx-kinds.at(kind)
  block(
    width: 100%,
    radius: 0.4em,
    stroke: 1pt + c,
    inset: (x: 0.6em, y: 0.5em),
  )[
    #text(weight: "bold", fill: c, title)
    #v(-0.3em)
    #grid(
      columns: (4.6em, 1fr, auto),
      column-gutter: 0.5em,
      row-gutter: 0.35em,
      align: horizon + left,
      ..rows.pos().flatten(),
    )
  ]
}

#slide[
  == RegEx Cheat Sheet
  Everything else matches itself, ```bash grep 'regex'``` or ```bash grep -E 'regex'```

  #set text(size: 0.78em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    row-gutter: 0.7em,
    rx-sheet-card([Characters], "class",
      rx-sheet-row(".", "class", [any single character], "c.l"),
      rx-sheet-row("[abc]", "class", [one of the characters], "c[ao]l"),
      rx-sheet-row("[0-9]", "class", [one character in the range], "[a-z]"),
      rx-sheet-row("[^abc]", "class", [one character *not* inside], "[^0-9]"),
    ),
    rx-sheet-card([Repetitions - of the previous item], "repeat",
      rx-sheet-row("*", "repeat", [0 or more times], "go*al"),
      rx-sheet-row("+", "repeat", [1 or more times], "[0-9]+", ere: true),
      rx-sheet-row("?", "repeat", [0 or 1 time], "colou?r", ere: true),
      rx-sheet-row("{n,m}", "repeat", [`n` to `m` times, `{n}` exactly `n`], "[0-9]{4}", ere: true),
    ),
    rx-sheet-card([Anchors - match a place, not a character], "anchor",
      rx-sheet-row("^", "anchor", [the start of the line], "^ca"),
      rx-sheet-row("$", "anchor", [the end of the line], "r$"),
      rx-sheet-row("\\b", "anchor", [a word edge], "\\bcat\\b"),
    ),
    rx-sheet-card([Groups, or, escape], "alt",
      rx-sheet-row("( )", "class", [a group, repeated as one item], "(an)+", ere: true),
      rx-sheet-row("|", "alt", [one of the alternatives (_or_)], "cat|dog", ere: true),
      rx-sheet-row("\\", "esc", [the next character is literal], "\\."),
    ),
  )
]
