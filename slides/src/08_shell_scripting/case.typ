#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Conditions: `case` #text(size: 10pt, weight: "regular")[\ _Compare a word with patterns_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.5.6 - _case_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.2 - _Controlul fluxului_
]

#slide[
  == `case` Syntax
  The condition is a *word*, not a command

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.95em)
    #highlight-code(("all", (1,), lines-range(2, 4), (5,), lines-range(8, 10), (11,), "all"))[```bash
case WORD in
    pattern1)
        commands
        ;;
    pattern2|pattern3)
        commands
        ;;
    *)
        commands
        ;;
esac
```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- `case` takes the *text* of `WORD` and compares it with every pattern, top to bottom]]
    #uncover("3-")[#block[- `pattern)` - the commands that run if `WORD` matches it]]
    #uncover("3-")[#block[- `;;` - the end of the branch, jump after `esac`]]
    #uncover("4-")[#block[- `|` - _or_: any of the patterns]]
    #uncover("5-")[#block[- `*` matches anything: the _default_ branch, always last, optional]]
    #uncover("6-")[#block[- `esac` - `case` backwards, the end]]
  ]

  #v(0.3em)
  #only("7-")[#one-liner(("case WORD in pattern) commands ;; pattern) commands ;; esac",), ("case $f in *.txt) echo \"text\" ;; *) echo \"other\" ;; esac",))]
]

#let case-code = "#!/bin/bash
fruit=$(head -n 1 fruits.txt)
case $fruit in
    apple|cherry)
        echo \"red\"
        ;;
    banana)
        echo \"yellow\"
        ;;
    *)
        echo \"I don't know $fruit\"
        ;;
esac"

#slide[
  == 🐞 `case` Compares Text
  No command runs for the condition

  #debug-run(case-code, command: "./color.sh", blocks: true, size: 0.92em, files: (("fruits.txt", fruits-lines),), (
    (line: 2, part: "head -n 1 fruits.txt", who: "copy", run: "head -n 1 fruits.txt", status: 0, info: [prints `banana`],
      read: (1,)),
    (line: 2, run: "fruit=banana", vars: (fruit: "banana")),
    (line: 3, info: [compares the text `banana` with the patterns, *no command runs*]),
    (line: 4, expand: "apple|cherry", info: [`banana` does not match, try the next pattern]),
    (line: 7, expand: "banana", info: [`banana` matches]),
    (line: 8, run: "echo \"yellow\"", status: 0, out: ("yellow",)),
    (line: 9, info: [`;;` - jump after `esac`, `*)` is not tried]),
    (line: 13, info: [the end of `case`, the script goes on after it]),
  ))
]

// one row of the glob table: the pattern, what it means, words it matches
// and words it does not match; it appears on subslide `step`
// #glob-row(2, "a*", [`a`, then any text], ("apple",), ("banana",))
#let glob-row(step, pattern, means, yes, no) = (
  raw(pattern, lang: "bash"), means,
  if yes.len() > 0 { text(fill: ok-color)[✅ #yes.map(x => raw(x)).join(", ")] } else [-],
  if no.len() > 0 { text(fill: fail-color)[❌ #no.map(x => raw(x)).join(", ")] } else [-],
).map(c => uncover(str(step) + "-", c))

#slide[
  == Patterns Are Globs
  The same patterns as `ls *.txt`, but they match *text*, not file names

  #block(width: 100%, {
    set text(size: 0.95em)
    set table(inset: (x: 0.5em, y: 0.35em))
    table(
      columns: (auto, 1.3fr, 1fr, 1fr),
      align: (left, left, left, left),
      table.header([*Pattern*], [*Means*], [*Matches*], [*Does not match*]),
      ..glob-row(1, "apple", [exactly this text], ("apple",), ("apples", "Apple")),
      ..glob-row(2, "a*", [`a`, then any text (or none)], ("a", "apple"), ("banana",)),
      ..glob-row(3, "*.txt", [any text, then `.txt`], ("notes.txt", ".txt"), ("notes.md",)),
      ..glob-row(4, "???", [exactly three characters], ("fig", "yes"), ("kiwi",)),
      ..glob-row(5, "[yY]*", [`y` or `Y`, then any text], ("yes", "Y"), ("no",)),
      ..glob-row(6, "apple|kiwi", [`apple` *or* `kiwi` (only in `case`)], ("apple", "kiwi"), ("cherry",)),
      ..glob-row(7, "*", [any text: the default branch], ("everything",), ()),
    )
  })

  #v(0.3em)
  #only(1)[💡 no special characters: the word must be *exactly* the same, uppercase and lowercase count]
  #only(2)[💡 `*` - any number of characters, even zero]
  #only(3)[💡 `*` can be anywhere in the pattern: here, at the start]
  #only(4)[💡 `?` - exactly *one* character, any character]
  #only(5)[💡 `[...]` - exactly one character, one of those in the brackets]
  #only(6)[💡 `|` - not a pipe here: it separates patterns that run the same branch]
  #only("7-")[
    #shell-first[`case` never looks at the disk: it only compares the text of the word with the pattern]
  ]

  // the usual mistake: reading a glob as a regular expression (lecture 6)
  #only("8-")[
    #popup[
      #align(center, text(size: 1.5em, weight: "bold", fill: fail-color)[⚠️ globs are *not* regular expressions!])
      #v(-0.2em)
      #align(center, grid(
        columns: (auto, auto, auto, auto),
        column-gutter: 0.8em,
        row-gutter: 0.6em,
        align: horizon + left,
        [*glob* (`case`)], raw("n.*"), [`n`, a *dot*, any text], text(fill: fail-color)[❌ `notes.txt`],
        [*regex* (`grep`)], raw("n.*"), [`n`, any characters], text(fill: ok-color)[✅ `notes.txt`],
      ))
      #v(-0.2em)
      #align(center, label[in a glob, `.` is a dot and `*` is any text; in a regex, `.` is any character and `*` repeats it])
    ]
  ]
]

#let order-code = "#!/bin/bash
fruit=apple
case $fruit in
    a*) echo \"starts with a\" ;;
    apple) echo \"apple\" ;;
esac
echo \"done\""

#slide[
  == 🐞 Pitfall: `a*` Comes First
  The first pattern that matches wins

  #debug-run(order-code, command: "./order.sh", blocks: true, (
    (line: 2, run: "fruit=apple", vars: (fruit: "apple")),
    (line: 3, info: [compares the text `apple` with the patterns, *top to bottom*]),
    (line: 4, expand: "a*", info: [`apple` matches `a*`],
      note: [💡 `apple` starts with `a`: this is the first match]),
    (line: 4, part: "echo \"starts with a\"", run: "echo \"starts with a\"", status: 0, out: ("starts with a",)),
    (line: 7, run: "echo \"done\"", status: 0, out: ("done",),
      note: [❌ `;;` jumps after `esac`: the branch `apple)` is never tried, it is dead code]),
  ))

  #only("6-")[
    #popup[
      #align(center, text(size: 1.5em, weight: "bold", fill: fail-color)[⚠️ the order of the patterns matters!])
      #v(-0.2em)
      #align(center, text(size: 1.1em)[`a*` also matches `apple`, so it hides the branch `apple)`])
      #v(-0.2em)
      #align(center, text(size: 1.1em)[✅ put the *specific* patterns first, `a*` after them, `*` last])
    ]
  ]
]

#let nomatch-code = "#!/bin/bash
fruit=kiwi
case $fruit in
    apple) echo \"apple\" ;;
    cherry) echo \"cherry\" ;;
esac
echo \"exit code: $?\""

#slide[
  == 🐞 When Nothing Matches
  When no pattern matches, nothing runs

  #debug-run(nomatch-code, command: "./nomatch.sh", blocks: true, (
    (line: 2, run: "fruit=kiwi", vars: (fruit: "kiwi")),
    (line: 3, info: [compares the text `kiwi` with the patterns]),
    (line: 4, expand: "apple", info: [`kiwi` does not match]),
    (line: 5, expand: "cherry", info: [`kiwi` does not match]),
    (line: 6, info: [no pattern matched, `case` ends with `0`],
      note: [💡 no branch runs - and this is *not* an error]),
    (line: 7, run: "echo \"exit code: 0\"", status: 0, out: ("exit code: 0",),
      note: [💡 add a `*)` branch, last, to catch everything else]),
  ))
]
