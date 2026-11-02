#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = A Pipeline, Step by Step #text(size: 10pt, weight: "regular")[\ _How the text changes from one command to the next_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.14 - _Shell Input and Output_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.5.4 - _Comunicarea prin pipe-uri_
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
]


// the kinds of commands, in the colors of "A Typical Pipeline"
#let kinds = (
  line: ([Line Filter], accent),
  search: ([Search], ok-color),
  change: ([Change Text], rgb("9a4d76")),
  compute: ([Compute], changed),
)

// the pipeline so far, the last command in orange, and the kind of the
// last command under it
#let so-far(cmds, kind) = {
  let (name, color) = kinds.at(kind)
  grid(columns: 2, column-gutter: 1em, align: horizon,
    chain(cmds),
    box(inset: (x: 0.6em, y: 0.25em), radius: 0.3em, fill: color.lighten(88%), stroke: 1pt + color,
      text(weight: "bold", fill: color, name)),
  )
}

// the text that a command writes, as a box like a file
#let output-box(lines) = file-contents("stdout", lines, size: 0.8em)

#let names = ("tail -n +2", "grep", "cut", "sort -u", "wc -l")
#let after-tail = orders.slice(1)
#let after-grep = ("alice,apple,3", "carol,apple,2", "dan,apple,1", "alice,apple,2")
#let after-cut = ("alice", "carol", "dan", "alice")
#let after-sort = ("alice", "carol", "dan")

#slide[
  == How Many Customers Ordered Apples?
  Every step adds one command to the pipeline

  #col-steps((
    (cmd-line(w("tail", kind: "cmd"), param("-n +2", means: [from line 2]), w("orders.csv")),
      so-far(names.slice(0, 1), "line"),
      ("orders.csv", orders, range(2, 8), (1,)), output-box(after-tail),
      [💡 the first line is the header (the names of the columns), not an order: skip it]),
    (cmd-line(w("grep", kind: "cmd"), param("',apple,'", color: ok-color, means: [the lines with apple])),
      so-far(names.slice(0, 2), "search"),
      ("stdin", after-tail, (1, 3, 5, 6), (2, 4)), output-box(after-grep),
      [💡 keep only the orders of apples; the commas around `apple` skip a fruit like `pineapple`]),
    (cmd-line(w("cut", kind: "cmd"), param("-d,", color: changed, means: [delimiter `,`]), param("-f1", means: [field 1])),
      so-far(names.slice(0, 3), "change"),
      ("stdin", after-grep, ()), output-box(after-cut),
      [💡 keep only the name of the customer, the first field]),
    (cmd-line(w("sort", kind: "cmd"), param("-u", means: [unique])),
      so-far(names.slice(0, 4), "line"),
      ("stdin", after-cut, (1, 4)), output-box(after-sort),
      [💡 `alice` ordered apples twice: sort the names and keep every name once]),
    (cmd-line(w("wc", kind: "cmd"), param("-l", means: [count the lines])),
      so-far(names, "compute"),
      ("stdin", after-sort, ()), output-box(("3",)),
      [✅ ```bash tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1 | sort -u | wc -l``` #arrow `3`]),
  ))
]
