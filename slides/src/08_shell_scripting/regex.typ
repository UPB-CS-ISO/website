#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Regular Expressions #text(size: 10pt, weight: "regular")[\ _Patterns that describe text, used by `grep`_]
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
  A pattern that describes a piece of text

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - a _regular expression_ (_regex_) describes what a piece of text looks like
    #uncover("2-")[#block[- `grep 'regex' file` prints the lines that *contain* a match]]
    #uncover("3-")[#block[- most characters match themselves, a few are _special_: `.` means _any character_]]
    #uncover("4-")[#block[- used by `grep`, `sed`, `less`, `vim`, and every programming language]]
    #uncover("5-")[
      ⚠️ not the same as _globbing_
      - a glob matches *file names*, the shell expands it
      - a regex matches *text*, the program (`grep`) uses it
    ]
  ][
    #set text(size: 0.85em)
    #only("1")[#regex-matches(fruits, "an")]
    #only("2")[
      #regex-matches(fruits, "an")
      #terminal("$ grep 'an' fruits.txt\nbanana\nbanana")
    ]
    #only("3-")[
      #regex-matches(fruits, "a.p")
      #terminal("$ grep 'a.p' fruits.txt\napple\napple\napple")
    ]
  ]

  #v(0.5em)
  #uncover("5-")[
    #shell-first[always put the regex in *single quotes*: `*`, `?`, `[ ]` and `$` are special for the shell too, and the shell runs first]
  ]
]

#let row(step, ..cells) = cells.pos().map(c => uncover(str(step) + "-", c))

#slide[
  == Basic Regular Expressions
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

  #uncover("9-")[⚠️ in a glob `*` means _any characters_, in a regex `*` *repeats* the previous item: _any characters_ is `.*`]
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
    ..row(3, [`{n}`, `{n,m}`], [exactly `n`, between `n` and `m` times], [`a{2,4}` #arrow `aa`, `aaa`, `aaaa`]),
    ..row(4, [`( )`], [a group], [`(ab)+` #arrow `ab`, `abab`, ...]),
    ..row(5, [`|`], [one of the alternatives (_or_)], [`cat|dog` #arrow `cat` or `dog`]),
    ..row(6, [`\b`], [a word boundary], [`\bcat\b` #arrow only the word `cat`]),
  )

  #uncover("7-")[💡 without `-E`, `grep` needs `\+`, `\?`, `\{ \}`, `\( \)` and `\|` for these]
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
// the matches were checked against the real `grep` output
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

  #only(5)[💡 `-q` prints nothing: the answer is in the _exit code_ of `grep`, we use it in scripts]
]
