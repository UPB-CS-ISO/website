#import "/src/slides.typ": *

// Regular expressions, written for 4. Command Line Interface and kept here
// for later use. Self-contained: include it from any deck with
// #include "/extra/regex.typ"

#let changed = rgb("e65100")
#let changed-fill = rgb("fff3e0")
#let dim = luma(175)
#let mono = "DejaVu Sans Mono"

// an arrow pointing right, drawn with shapes rather than an arrow glyph
// (the glyph is missing from some fonts and shows up as a box)
#let draw-arrow(length: 2em, color: luma(120), thickness: 1.5pt) = {
  let height = 0.7em
  let mid = height / 2
  let head = 0.5em
  box(width: length, height: height, baseline: 0.1em, {
    place(top + left, line(start: (0em, mid), end: (length - head + 0.05em, mid), stroke: thickness + color))
    place(top + left, polygon(
      fill: color,
      (length - head, mid - 0.3em),
      (length, mid),
      (length - head, mid + 0.3em),
    ))
  })
}

// a small arrow to use inside text, e.g. `*.txt` #arrow `notes.txt`
// (arrow glyphs like #arrow are missing from some fonts and show up as boxes)
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// lines of text with the matches of a regular expression highlighted,
// the way `grep --color` shows them: lines without a match are not
// printed by `grep`, so they are grayed out
#let regex-matches(lines, pattern, size: 0.8em) = block(
  width: 100%,
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  inset: (x: 0.6em, y: 0.5em),
)[
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
        if m.end > m.start {
          box(
            fill: changed-fill,
            outset: (y: 2pt),
            radius: 1pt,
            text(fill: changed, weight: "bold", m.text),
          )
        }
        at = m.end
      }
      if at < l.len() { l.slice(at) }
    }
    linebreak()
  }
]


#slide[
  = Regular Expressions #text(size: 10pt, weight: "regular")[\ _Describe text: used by `grep`, `sed`, editors and programming languages_]
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

#let row(step, ..cells) = cells.pos().map(c => uncover(str(step) + "-", c))

#slide[
  == Regular Expressions
  Characters, anchors and classes - `grep 'regex'`

  #set text(size: 0.85em)
  #table(
    columns: (auto, 1fr, 1fr),
    table.header([Symbol], [Meaning], [Example]),
    ..row(1, [`abc`], [the characters themselves], [`cat` #arrow `cat`, `category`, `concatenate`]),
    ..row(2, [`.`], [any single character], [`a.c` #arrow `abc`, `a_c`, `a c`]),
    ..row(3, [`^`], [the start of the line], [`^a` #arrow lines that start with `a`]),
    ..row(4, [`$`], [the end of the line], [`a$` #arrow lines that end with `a`]),
    ..row(5, [`*`], [the previous item, zero or more times], [`ab*` #arrow `a`, `ab`, `abb`, ...]),
    ..row(6, [`[abc]`], [one of the characters (a _class_)], [`[aeiou]` #arrow any vowel]),
    ..row(7, [`[^abc]`], [one character that is *not* in the class], [`[^0-9]` #arrow anything but a digit]),
    ..row(8, [`\`], [_escape_, the next character is literal], [`\.` #arrow a real `.`]),
  )

  #uncover("9-")[⚠️ not the same as globbing: `*` *repeats* the previous item, `.*` means _any characters_]
]

#slide[
  == Extended Regular Expressions
  `grep -E 'regex'`

  #set text(size: 0.85em)
  #table(
    columns: (auto, 1fr, 1fr),
    table.header([Symbol], [Meaning], [Example]),
    ..row(1, [`+`], [the previous item, one or more times], [`ab+` #arrow `ab`, `abb`, ...]),
    ..row(2, [`?`], [the previous item, zero or one time], [`colou?r` #arrow `color`, `colour`]),
    ..row(3, [`{n}`, `{n,}`, `{n,m}`], [exactly `n`, at least `n`, between `n` and `m` times], [`a{2,4}` #arrow `aa`, `aaa`, `aaaa`]),
    ..row(4, [`( )`], [a group], [`(ab)+` #arrow `ab`, `abab`, ...]),
    ..row(5, [`|`], [one of the alternatives (_or_)], [`cat|dog` #arrow `cat` or `dog`]),
    ..row(6, [`\w`, `\s`, `\b`], [a word character, a whitespace, a word boundary], [`\bcat\b` #arrow only the word `cat`]),
    ..row(7, [`\d`], [a digit, *only* with `grep -P` (Perl regex)], [`\d+` #arrow `123`, `42`, ...]),
  )

  #uncover("8-")[💡 without `-E`, `grep` needs `\+`, `\?`, `\{ \}`, `\( \)` and `\|` for these]
]

#let words = (
  "color",
  "colour",
  "cat",
  "category",
  "concatenate",
  "dog",
  "2026-10-04",
  "call 0722 123 456",
)

// (the command, the same regex for Typst, a short explanation)
#let regex-steps = (
  ("grep 'cat' words.txt", "cat", [the text `cat`, anywhere in the line]),
  ("grep '^cat' words.txt", "^cat", [`cat` at the *start* of the line]),
  ("grep -E '\\bcat\\b' words.txt", "\\bcat\\b", [only the *word* `cat`]),
  ("grep -E 'colou?r' words.txt", "colou?r", [`u` is optional]),
  ("grep -E 'cat|dog' words.txt", "cat|dog", [`cat` *or* `dog`]),
  ("grep -E '[0-9]+' words.txt", "[0-9]+", [one or more digits]),
  ("grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' words.txt", "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", [a whole line that is a date]),
  ("grep '^c.*e$' words.txt", "^c.*e$", [starts with `c`, *anything*, ends with `e`]),
)

#slide[
  == Regular Expressions in Action
  The matches are highlighted, like `grep --color` does

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #for (i, (cmd, pattern, explain)) in regex-steps.enumerate() {
      only(i + 1)[
        #terminal("$ " + cmd)
        💡 #explain
      ]
    }
  ][
    #for (i, (cmd, pattern, explain)) in regex-steps.enumerate() {
      only(i + 1)[#regex-matches(words, pattern)]
    }
    #set text(size: 0.8em)
    _gray lines do not match, `grep` does not print them_
  ]
]
