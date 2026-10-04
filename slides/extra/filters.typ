#import "/src/slides.typ": *
#import "/extra/text-processing-common.typ": *

// Text processing commands (cat, sort, uniq, grep, wc, head, tail, tac, rev, nl, cut, tr), written for
// 4. Command Line Interface and kept here for later use. Include it from any
// deck with #include "/extra/filters.typ"

#slide[
  = Text Processing #text(size: 10pt, weight: "regular")[\ _Small commands for text files_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Sections 2.2.2 - 2.2.3 - `cat`, _Standard Input and Standard Output_
      - Section 2.5 - _Intermediate Commands_ (`grep`, `head`, `tail`, `sort`)
      - Section 2.14 - _Shell Input and Output_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.4 - _Redirectarea intrării sau ieșirii_
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
]

#slide[
  == Redirects and Pipes
  A short reminder from _3. Processes_

  #set text(size: 0.9em)
  #table(
    columns: (auto, 1fr),
    table.header([Syntax], [What the shell does]),
    [`cmd < file`], [`stdin` (`0`) reads `file` instead of the keyboard],
    [`cmd > file`], [`stdout` (`1`) writes into `file` (emptied first)],
    [`cmd >> file`], [`stdout` (`1`) writes at the *end* of `file`],
    [`cmd 2> file`], [`stderr` (`2`) writes into `file`],
    [`cmd &> file`], [both `stdout` and `stderr` write into `file`],
    [`cmd1 | cmd2`], [the `stdout` of `cmd1` becomes the `stdin` of `cmd2`],
  )

  💡 the commands do not know about redirects, they just use `0`, `1` and `2`
]

#slide[
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 24pt)[_Do one thing well, and chain them together._]
  ]
]

#slide[
  == Filters
  Read text, change it, write it

  #align(center)[
    #grid(
      columns: 5,
      column-gutter: 0.6em,
      align: center + horizon,
      grid(
        rows: 2,
        row-gutter: 0.4em,
        endpoint[📄 files given as parameters],
        uncover("2-", endpoint(changed-end: true)[#keyboard (`stdin`), if no file]),
      ),
      draw-arrow(),
      process("sort"),
      draw-arrow(),
      endpoint[#display (`stdout`)],
    )
  ]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - read the *files* given in the command line, e.g. `sort fruits.txt`
    #uncover("2-")[#block[- if *no file* is given, they read the *keyboard* (`stdin`)]]
    #uncover("3-")[#block[- type the lines, then press #kbd("Ctrl") + #kbd("D") to signal the _end of file_]]
    #uncover("4-")[#block[- they write the result on the *display* (`stdout`), so they can be chained with `|`]]
  ][
    #set text(size: 0.9em)
    #reveal-terminal(before: none, lines: (1, 4, 5, 8), full: false)[```terminal
    $ sort         # no file: reads the keyboard
    pear
    apple
    orange
    ^D
    apple
    orange
    pear
    ```]
  ]
]

#let fruits = ("pear", "apple", "orange", "banana", "apple")

#slide[
  == `cat`
  🐱 Concatenate and display files

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #only(1)[```terminal
    $ cat fruits.txt
    pear
    apple
    orange
    banana
    apple
    ```]
    #only(2)[```terminal
    $ cat fruits.txt veggies.txt   # one after the other
    pear
    apple
    orange
    banana
    apple
    tomato
    carrot
    ```]
    #only("3-")[```terminal
    $ cat                          # no file: the keyboard
    Hello world
    Hello world
    This is live input
    This is live input
    ^D
    ```]
  ][
    #file-contents("fruits.txt", fruits)
    #uncover("2-")[#file-contents("veggies.txt", ("tomato", "carrot"))]
  ]

  #only(1)[💡 display the contents of a file]
  #only(2)[💡 display several files, one after the other: _concatenate_ them]
  #only("3-")[💡 every line you type is printed back, until #kbd("Ctrl") + #kbd("D")]
]

#slide[
  == `sort`
  🔤 Sort lines alphabetically or numerically

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #only("-3")[#reveal-terminal(before: none, lines: (6, 12, 17), full: false)[```terminal
    $ sort fruits.txt
    apple
    apple
    banana
    orange
    pear
    $ sort -r fruits.txt       # reverse
    pear
    orange
    banana
    apple
    apple
    $ sort -u fruits.txt       # unique
    apple
    banana
    orange
    pear
    ```]]
    #only("4-")[```terminal
    $ sort numbers.txt         # as text
    10
    100
    2
    9
    $ sort -n numbers.txt      # as numbers
    2
    9
    10
    100
    ```]
  ][
    #only("-3")[#file-contents("fruits.txt", fruits)]
    #only("4-")[#file-contents("numbers.txt", ("10", "9", "100", "2"))]
  ]

  #set text(size: 0.9em)
  #only(4)[⚠️ without `-n`, numbers are sorted as text: `"100"` comes before `"2"`, as `1` < `2`]
  #only("5-")[💡 `sort -t, -k2 -n students.csv` sorts by the *second* field, fields separated by `,`]
]

#let basket = ("apple", "apple", "pear", "pear", "apple", "banana")

#slide[
  == `uniq`
  🔁 Filter out *adjacent* repeated lines

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (5, 9, 13, 16), full: false)[```terminal
    $ uniq basket.txt
    apple
    pear
    apple
    banana
    $ sort basket.txt | uniq
    apple
    banana
    pear
    $ sort basket.txt | uniq -c   # count
          3 apple
          1 banana
          2 pear
    $ sort basket.txt | uniq -d   # only repeated
    apple
    pear
    ```]
  ][
    #only(1)[#file-contents("basket.txt", basket, new: (1, 3, 5, 6), faded: (2, 4))]
    #only("2-")[#file-contents("basket.txt", basket)]
  ]

  #set text(size: 0.9em)
  #only(1)[⚠️ `uniq` only compares a line with the *previous* one: the third `apple` is printed again]
  #only(2)[💡 `sort` first, so the identical lines are next to each other]
  #only(3)[💡 `-c` - how many times every line shows up]
  #only("4-")[💡 `-d` - only the lines that are repeated]
]

#let server-log = (
  "INFO  server started",
  "WARN  disk almost full",
  "ERROR cannot open config.txt",
  "INFO  user alice logged in",
  "error connection refused",
  "INFO  user bob logged in",
)

#slide[
  == `grep`
  🔍 Print the lines that match a pattern (a _regular expression_)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #reveal-terminal(before: none, lines: (2, 5, 7, 11, 14), full: false)[```terminal
    $ grep ERROR server.log
    ERROR cannot open config.txt
    $ grep -i error server.log     # ignore case
    ERROR cannot open config.txt
    error connection refused
    $ grep -c INFO server.log      # count
    3
    $ grep -v INFO server.log      # invert
    WARN  disk almost full
    ERROR cannot open config.txt
    error connection refused
    $ grep -n user server.log      # line numbers
    4:INFO  user alice logged in
    6:INFO  user bob logged in
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[#file-contents("server.log", server-log, new: (3,), faded: (1, 2, 4, 5, 6))]
    #only(2)[#file-contents("server.log", server-log, new: (3, 5), faded: (1, 2, 4, 6))]
    #only(3)[#file-contents("server.log", server-log, new: (1, 4, 6), faded: (2, 3, 5))]
    #only(4)[#file-contents("server.log", server-log, new: (2, 3, 5), faded: (1, 4, 6))]
    #only("5-")[#file-contents("server.log", server-log, new: (4, 6), faded: (1, 2, 3, 5))]

    #only("6-")[
      #set text(size: 0.9em)
      - `-E` - extended regex: `grep -E '^(WARN|ERROR)'`
      - `-r` - search all the files in a directory
      - `-w` - match whole words only
    ]
  ]
]

#slide[
  == `wc`
  🔢 Word count: lines, words and bytes

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 8, 10), full: false)[```terminal
    $ wc fruits.txt
     5  5 31 fruits.txt
    $ wc -l fruits.txt         # lines
    5 fruits.txt
    $ wc -w fruits.txt         # words
    5 fruits.txt
    $ wc -c fruits.txt         # bytes
    31 fruits.txt
    $ wc -l < fruits.txt       # reads stdin
    5
    ```]
  ][
    #file-contents("fruits.txt", fruits)
  ]

  #set text(size: 0.9em)
  #only(1)[💡 the output is `lines  words  bytes  file`]
  #only("2-4")[💡 the options select what to count]
  #only("5-")[💡 when it reads `stdin`, `wc` does not know the name of the file, it prints only the number]
]

#let numbered = range(1, 13).map(i => "line " + str(i))

#slide[
  == `head` and `tail`
  🔝 The first and 🔚 the last lines

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (4, 7, 9, 11, 12), full: false)[```terminal
    $ head -n 3 lines.txt
    line 1
    line 2
    line 3
    $ tail -n 2 lines.txt
    line 11
    line 12
    $ head lines.txt | wc -l          # 10 by default
    10
    $ head -n 5 lines.txt | tail -n 1 # the 5th line
    line 5
    $ tail -f server.log              # follow
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[#file-contents("lines.txt", numbered, new: (1, 2, 3), size: 0.7em)]
    #only(2)[#file-contents("lines.txt", numbered, new: (11, 12), size: 0.7em)]
    #only(3)[#file-contents("lines.txt", numbered, new: range(1, 11), size: 0.7em)]
    #only(4)[#file-contents("lines.txt", numbered, new: (5,), size: 0.7em)]
    #only("5-")[#file-contents("lines.txt", numbered, size: 0.7em)]
  ]

  #set text(size: 0.9em)
  #only(3)[💡 without `-n`, both show *10* lines]
  #only(4)[💡 combine them to extract a line from the middle]
  #only("5-")[💡 `tail -f` keeps the file open and prints the new lines as they are written, until #kbd("Ctrl") + #kbd("C")]
]

#slide[
  == `tac`, `rev` and `nl`
  🔄 Reverse the lines, reverse the characters, number the lines

  #toolbox.side-by-side(columns: (1fr, 1fr, 1fr, 1fr), gutter: 1em)[
    #file-contents("fruits.txt", fruits)
  ][
    #uncover("2-")[
      #set text(size: 0.85em)
      ```terminal
      $ tac fruits.txt
      apple
      banana
      orange
      apple
      pear
      ```
      💡 `cat` backwards
    ]
  ][
    #uncover("3-")[
      #set text(size: 0.85em)
      ```terminal
      $ rev fruits.txt
      raep
      elppa
      egnaro
      ananab
      elppa
      ```
      💡 every line is reversed
    ]
  ][
    #uncover("4-")[
      #set text(size: 0.85em)
      ```terminal
      $ nl fruits.txt
           1  pear
           2  apple
           3  orange
           4  banana
           5  apple
      ```
      💡 _number lines_
    ]
  ]
]

#let students = ("name,age,city", "Alice,30,Paris", "Bob,25,London", "Carol,22,Bucharest")

#slide[
  == `cut`
  ✂️ Extract columns (fields) or characters

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (5, 10, 16), full: false)[```terminal
    $ cut -d, -f1,3 students.csv
    name,city
    Alice,Paris
    Bob,London
    Carol,Bucharest
    $ cut -d, -f2 students.csv
    age
    30
    25
    22
    $ cut -c1-3 fruits.txt
    pea
    app
    ora
    ban
    app
    ```]
  ][
    #only("-2")[#file-contents("students.csv", students)]
    #only("3-")[#file-contents("fruits.txt", fruits)]
  ]

  #set text(size: 0.9em)
  #only(1)[💡 `-d,` - the fields are separated by `,` (the _delimiter_, a tab by default), `-f1,3` - fields 1 and 3]
  #only(2)[💡 `-f2` - only the second field]
  #only("3-")[💡 `-c1-3` - the characters 1 to 3 of every line]
]

#slide[
  == `tr`
  🔡 Translate or delete characters

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (6, 8, 10), full: false)[```terminal
    $ tr a-z A-Z < fruits.txt              # translate
    PEAR
    APPLE
    ORANGE
    BANANA
    APPLE
    $ echo 'call 0722 123 456' | tr -d 0-9  # delete
    call
    $ echo 'too    many   spaces' | tr -s ' ' # squeeze
    too many spaces
    ```]
  ][
    #file-contents("fruits.txt", fruits)
  ]

  #set text(size: 0.9em)
  ⚠️ `tr` does *not* accept file names, it only reads `stdin`: use `<` or a pipe

  #only(1)[💡 every character from the first set is replaced by the one at the same position in the second set]
  #only(2)[💡 `-d` - delete the characters in the set]
  #only("3-")[💡 `-s` - squeeze: a run of the same character becomes only one]
]
