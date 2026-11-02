#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Integrated Development Environments #text(size: 10pt, weight: "regular")[\ _All the tools in one application_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.6.4 - _Medii integrate de dezvoltare (IDE)_
      - Section 6.8 - _Depanarea programelor_
]

// the parts of an IDE, around the editor: (x, y, name, what)
#let ide-parts = (
  (70pt, 22pt, [build], [compiler, `make`]),
  (380pt, 22pt, [run], [one button]),
  (60pt, 80pt, [code intelligence], [errors, completion, refactoring]),
  (390pt, 80pt, [debugger], [breakpoints, variables]),
  (70pt, 138pt, [project], [files, settings]),
  (380pt, 138pt, [version control], [`git`]),
  (225pt, 150pt, [more], [GUI designer, profiler, tests]),
)

#let ide-drawing(upto) = drawing(width: 450pt, height: 168pt, {
  let mid = (225pt, 80pt)
  for (i, (x, y, name, what)) in ide-parts.enumerate() {
    if i < upto {
      wire(mid, (x, y), stroke: 1pt + luma(160))
    }
  }
  pin(..mid, box(
    width: 110pt,
    inset: 0.7em,
    radius: 0.5em,
    fill: accent,
    align(center, text(fill: white, weight: "bold")[editor\ #text(size: 7pt, weight: "regular")[the source code]]),
  ))
  for (i, (x, y, name, what)) in ide-parts.enumerate() {
    if i < upto {
      pin(x, y, tool-box(name, sub: what, on: i == upto - 1, fill: white, width: 110pt))
    }
  }
})

#slide[
  == What is an IDE?
  _Integrated Development Environment_: the editor and the development tools, in one program

  #for i in range(1, ide-parts.len() + 1) {
    only(if i == ide-parts.len() { str(i) + "-" } else { i }, ide-drawing(i))
  }

  #v(1fr)
  #only(1)[💡 the IDE runs the build (compiler, `make`, ...) and shows the errors in the code]
  #only(2)[💡 build and run with one key, the output is in a panel of the IDE]
  #only(3)[💡 the IDE *understands* the code: the type of a variable, where a function is defined, ...]
  #only(4)[💡 stop the program on a line and look at its variables, see the debugger section]
  #only(5)[💡 a project: the files of the program and how to build them]
  #only(6)[💡 see the changes, commit, push, without leaving the IDE]
  #only("7-")[💡 an editor edits text, an IDE knows *the language* and *the project*]
]

// an IDE as a card: its name, what it is for, who makes it
#let ide-card(name, what, who) = box(
  width: 100%,
  height: 3em,
  inset: (x: 0.6em, y: 0.5em),
  radius: 0.4em,
  fill: rgb("eef3f5"),
  stroke: (left: 3pt + accent),
  {
    text(weight: "bold", fill: accent, name)
    h(1fr)
    text(size: 0.75em, fill: luma(110), who)
    linebreak()
    text(size: 0.85em, what)
  },
)

#slide[
  == Examples of IDEs
  Usually made for one language or one platform

  #v(0.3em)
  #set text(size: 0.85em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    row-gutter: 0.5em,
    ide-card[Visual Studio][C++ and C\# on Windows][Microsoft],
    ide-card[IntelliJ IDEA][Java, Kotlin][JetBrains],
    ide-card[CLion, PyCharm, RustRover][C/C++, Python, Rust][JetBrains],
    ide-card[Android Studio][Android apps][Google],
    ide-card[Xcode][macOS and iOS apps, Swift][Apple],
    ide-card[Eclipse][Java, C/C++][open source],
    ide-card[Qt Creator][C++ with the Qt library][Qt],
    ide-card[Code::Blocks][C/C++, small][open source],
  )
]

// the comparison table: a row is (what, editor, IDE)
#let compare-rows = (
  ([understands], [text], [the language, the project]),
  ([languages], [any], [one or a few]),
  ([build, run, debug], [in a terminal], [buttons and panels]),
  ([resources], [✅ small, starts instantly], [❌ large, slow to start]),
  ([examples], [`vim`, `nano`, `emacs`], [Visual Studio, IntelliJ IDEA]),
)

#slide[
  == Editor or IDE?
  An editor edits text, an IDE knows the language and the project

  #v(0.5em)
  #align(center, block(width: 100%, {
    set text(size: 0.95em)
    table(
      columns: (auto, 1fr, 1.2fr),
      align: (left + horizon, center + horizon, center + horizon),
      inset: (x: 0.6em, y: 0.45em),
      stroke: none,
      fill: (x, y) => if y == 0 { none } else if x == 0 { none } else if calc.odd(y) { luma(246) } else { white },
      table.header(
        [],
        table.cell(fill: luma(225))[*Text editor*],
        table.cell(fill: accent, text(fill: white)[*IDE*]),
      ),
      ..compare-rows.map(((what, ed, ide)) => (text(fill: luma(110), style: "italic", what), ed, ide)).flatten(),
      table.hline(stroke: 0.8pt + luma(200)),
    )
  }))

  #v(1fr)
  #uncover("2-")[
    #callout[an editor + *plugins* = an IDE. How? 👉 *language servers* and *debug adapters*]
  ]
]
