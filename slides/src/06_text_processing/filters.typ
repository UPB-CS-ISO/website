#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Line Filters #text(size: 10pt, weight: "regular")[\ _Work with whole lines: `cat`, `tac`, `head`, `tail`, `sort`, `uniq`_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.2.2 - `cat`
      - Section 2.5 - _Intermediate Commands_ (`head`, `tail`, `sort`)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
]

// fruits.txt, the file of the course examples (fruits-lines in shell.typ)
#let fruits = fruits-lines
#let numbers = ("10", "9", "100", "2")
#let fruits-sorted = fruits.sorted()
#let server-log = ("GET /index.html 200", "GET /logo.png 404", "GET /about.html 200")

// the input of `uniq` in a pipeline: the output of `sort`
#let sorted-header = [#text(font: mono)[sort fruits.txt] #text(font: mono, weight: "bold", fill: changed)[|]]

// every line stays where it is
#let same(n) = range(n).map(i => (i, i))

// ----- the slides -----

#slide[
  == `cat`
  🐱 Concatenate and display files

  #col-steps((
    (cmd-line(w("cat", kind: "cmd"), w("fruits.txt")),
      line-map(height: 123pt, ((file("fruits.txt"), fruits),), "cat fruits.txt", fruits, same(7)),
      none, none,
      [💡 display the contents of a file: every line, as it is, in the same order]),
    (cmd-line(w("cat", kind: "cmd"), w("fruits.txt"), param("veggies.txt", color: changed, means: [a second file])),
      line-map(height: 123pt, ((file("fruits.txt"), fruits), (file("veggies.txt"), ("tomato", "carrot"))), "cat fruits.txt veggies.txt",
        fruits + ("tomato", "carrot"), same(9), new: (7, 8), row: 9pt, size: 7.5pt, out-width: 175pt),
      none, none,
      [💡 several files, one after the other: _concatenate_ them]),
    (cmd-line(w("cat", kind: "cmd"), param("no file", color: luma(100), means: [reads the keyboard])),
      line-map(height: 123pt, (([⌨️ keyboard], ("Hello world", "This is live input")),), "cat",
        ("Hello world", "Hello world", "This is live input", "This is live input"), ((0, 1), (1, 3)), after: ("^D",)),
      none, none,
      [💡 no file: reads `stdin`, every line you type is printed back (orange), until #kbd("Ctrl") + #kbd("D")]),
  ))
]

#slide[
  == `tac`
  🔄 `cat` backwards: the last line first

  #col-steps((
    (cmd-line(w("tac", kind: "cmd"), w("fruits.txt")),
      line-map(((file("fruits.txt"), fruits),), "tac fruits.txt", fruits.rev(), range(7).map(i => (i, 6 - i)), colored: true),
      none, none,
      [💡 the same lines, in the *reverse order*; every line stays as it is (`rev` reverses the characters, see _Column Filters_)]),
  ))
]

#slide[
  == `head` and `tail`
  🔝 The first and 🔚 the last lines

  #col-steps((
    (cmd-line(w("head", kind: "cmd"), param("-n 3", means: [3 lines]), w("fruits.txt")),
      line-map(height: 106pt, ((file("fruits.txt"), fruits),), "head -n 3 fruits.txt", fruits.slice(0, 3), same(3), new: (0, 1, 2)),
      none, none,
      [💡 the *first* lines; `-n` - how many, without it *10*]),
    (cmd-line(w("tail", kind: "cmd"), param("-n 2", means: [2 lines]), w("fruits.txt")),
      line-map(height: 106pt, ((file("fruits.txt"), fruits),), "tail -n 2 fruits.txt", fruits.slice(5), ((5, 0), (6, 1))),
      none, none,
      [💡 the *last* lines; `-n` - how many, without it *10*]),
    (cmd-line(w("head", kind: "cmd"), param("-n 5", means: [lines 1-5]), w("fruits.txt"), pipe-sym, w("tail", kind: "cmd"), param("-n 1", color: changed, means: [the last of them])),
      line-map(height: 106pt, ((file("fruits.txt"), fruits),), "head -n 5 fruits.txt | tail -n 1", ("kiwi",), ((4, 0),), out-width: 190pt, gap: 50pt),
      none, none,
      [💡 combine them to extract a line from the middle: the *5th* line]),
    (cmd-line(w("tail", kind: "cmd"), param("-f", color: changed, means: [follow]), w("server.log")),
      line-map(height: 106pt, ((file("server.log"), server-log),), "tail -f server.log", server-log, same(3), in-new: (2,), new: (2,), in-width: 130pt),
      none, none,
      [💡 `tail -f` keeps the file open and prints the new lines as they are written, until #kbd("Ctrl") + #kbd("C")]),
  ))
]

#slide[
  == `sort`
  🔤 Sort lines alphabetically or numerically

  #col-steps((
    (cmd-line(w("sort", kind: "cmd"), w("fruits.txt")),
      line-map(height: 106pt, ((file("fruits.txt"), fruits),), "sort fruits.txt", fruits-sorted,
        ((1, 0), (3, 1), (6, 2), (0, 3), (5, 4), (2, 5), (4, 6))),
      none, none,
      [💡 in alphabetical order; `sort -r` - in _reverse_ order]),
    (cmd-line(w("sort", kind: "cmd"), param("-u", means: [unique]), w("fruits.txt")),
      line-map(height: 106pt, ((file("fruits.txt"), fruits),), "sort -u fruits.txt", ("apple", "banana", "cherry", "kiwi"),
        ((1, 0), (3, 0), (6, 0), (0, 1), (5, 1), (2, 2), (4, 3))),
      none, none,
      [💡 `-u` - every line only once (_unique_): the same lines become one]),
    (cmd-line(w("sort", kind: "cmd"), w("numbers.txt")),
      line-map(height: 106pt, ((file("numbers.txt"), numbers),), "sort numbers.txt", ("10", "100", "2", "9"),
        ((0, 0), (2, 1), (3, 2), (1, 3))),
      none, none,
      [⚠️ numbers are sorted as text, character by character: `"100"` comes before `"2"`, as `1` < `2`]),
    (cmd-line(w("sort", kind: "cmd"), param("-n", color: changed, means: [as numbers]), w("numbers.txt")),
      line-map(height: 106pt, ((file("numbers.txt"), numbers),), "sort -n numbers.txt", ("2", "9", "10", "100"),
        ((3, 0), (1, 1), (0, 2), (2, 3))),
      none, none,
      [💡 `-n` - by the value of the number; `sort -t, -k2 -n` sorts by the *2#super[nd] field*, fields separated by `,`]),
  ))
]

#slide[
  == `uniq`
  🔁 Filter out *adjacent* repeated lines

  #col-steps((
    (cmd-line(w("uniq", kind: "cmd"), w("fruits.txt")),
      line-map(height: 106pt, out-width: 175pt, ((file("fruits.txt"), fruits),), "uniq fruits.txt", fruits, same(7)),
      none, none,
      [⚠️ `uniq` only compares a line with the *previous* one: no two `apple` lines are next to each other, nothing is removed]),
    (cmd-line(w("sort", kind: "cmd"), w("fruits.txt"), pipe-sym, w("uniq", kind: "cmd")),
      line-map(height: 106pt, out-width: 175pt, ((sorted-header, fruits-sorted),), "sort fruits.txt | uniq", ("apple", "banana", "cherry", "kiwi"),
        ((0, 0), (1, 0), (2, 0), (3, 1), (4, 1), (5, 2), (6, 3))),
      none, none,
      [💡 `sort` first, so the identical lines are next to each other]),
    (cmd-line(w("sort", kind: "cmd"), w("fruits.txt"), pipe-sym, w("uniq", kind: "cmd"), param("-c", color: changed, means: [count])),
      line-map(height: 106pt, out-width: 175pt, ((sorted-header, fruits-sorted),), "sort fruits.txt | uniq -c",
        ("      3 apple", "      2 banana", "      1 cherry", "      1 kiwi"),
        ((0, 0), (1, 0), (2, 0), (3, 1), (4, 1), (5, 2), (6, 3)), new: (0, 1, 2, 3)),
      none, none,
      [💡 `-c` - how many times every line shows up]),
    (cmd-line(w("sort", kind: "cmd"), w("fruits.txt"), pipe-sym, w("uniq", kind: "cmd"), param("-d", color: changed, means: [only repeated])),
      line-map(height: 106pt, out-width: 175pt, ((sorted-header, fruits-sorted),), "sort fruits.txt | uniq -d", ("apple", "banana"),
        ((0, 0), (1, 0), (2, 0), (3, 1), (4, 1))),
      none, none,
      [💡 `-d` - only the lines that are repeated; `cherry` and `kiwi` show up once, they are dropped]),
  ))
]
