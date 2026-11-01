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

#slide[
  == Examples of IDEs
  Usually made for one language or one platform

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.72em)
    #table(
      columns: (auto, 1fr),
      inset: 0.32em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*IDE*], [*for*]),
      [Visual Studio], [C++, C\# on Windows (Microsoft)],
      [IntelliJ IDEA], [Java, Kotlin (JetBrains)],
      [CLion, PyCharm, RustRover], [C/C++, Python, Rust (JetBrains)],
      [Android Studio], [Android apps (Google, based on IntelliJ)],
      [Xcode], [macOS and iOS apps, Swift (Apple)],
      [Eclipse], [Java, C/C++ (open source)],
      [Qt Creator], [C++ with the Qt library],
      [Code::Blocks], [C/C++ (open source, small)],
    )
  ][
    #uncover("2-")[
      #align(center, screenshot("img/book/xcode-interface.png", height: 5cm))
      #text(size: 0.7em)[Xcode: the window of the application is drawn with the mouse, the IDE writes the code (from the USO book)]
    ]
  ]
]

#slide[
  == Editor or IDE?

  #set text(size: 0.95em)
  #align(center)[
    #table(
      columns: (auto, 1fr, 1fr),
      align: (left, center, center),
      inset: 0.5em,
      table.header([], [*Text editor*], [*IDE*]),
      [understands], [text], [the language and the project],
      [languages], [any], [one or a few],
      [build, run, debug], [in a terminal], [buttons and panels],
      [resources], [✅ small, starts instantly], [❌ large, slow to start],
      [examples], [`vim`, `nano`, `emacs`], [Visual Studio, IntelliJ, Xcode],
    )
  ]

  #v(1fr)
  #uncover("2-")[
    #callout[Today the line is blurry: with the right *plugins*, an editor becomes an IDE. How? 👉 *language servers* and *debug adapters*]
  ]
]
