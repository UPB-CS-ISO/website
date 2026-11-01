#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Compiled & Interpreted Languages #text(size: 10pt, weight: "regular")[\ _Who turns the source code into machine code, and when?_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 15 - _Development Tools_
      - Section 15.4 - _Scripting Languages_
      - Section 15.5 - _Java_
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.2 - _Limbaje de programare_
      - Sections 6.3 - 6.5 - _Limbaje compilate_, _Limbaje interpretate_, _Limbaje hibride_
]

// a language name in a colored chip, colored by the way it runs
#let chip(name, kind) = {
  let c = kind-colors.at(kind)
  box(
    inset: (x: 0.45em, y: 0.25em),
    radius: 0.3em,
    fill: c.fill,
    stroke: 0.8pt + c.stroke,
    text(size: 9pt, weight: "bold", name),
  )
}

#slide[
  == Machine Code
  A program is a text file, the processor does not understand text

  #v(0.5em)
  #align(center)[
    #grid(
      columns: 3,
      column-gutter: 1.5em,
      align: center + horizon,
      [
        #text(size: 0.8em, fill: luma(110), style: "italic")[source code (text), what we write]
        ```c
        for (int i = 0; i < 3; i++) {
            printf("Hello, %d!\n", i);
        }
        ```
      ],
      uncover("2-")[
        #text(size: 2em, weight: "bold", fill: changed)[?]
        #v(-0.8em)
        #draw-arrow(length: 3em, color: changed)
      ],
      [
        #text(size: 0.8em, fill: luma(110), style: "italic")[machine code (bytes), what the CPU runs]
        #block(fill: luma(240), radius: 0.3em, inset: 0.6em, align(left, text(font: mono, size: 0.75em)[
          55 48 89 e5 48 83 ec 10\
          c7 45 fc 00 00 00 00 eb\
          1d 8b 45 fc 89 c6 48 8d\
          05 00 00 00 00 48 89 c7\
          ...
        ]))
      ],
    )
  ]

  #v(1fr)
  #only(1)[💡 every processor has its own *instruction set*: x86-64, ARM64, RISC-V, ...]
  #only(2)[💡 someone has to *translate* the source code to machine code: *who* does it and *when*?]
  #only("3-")[
    #callout[
      a *compiler* translates *before* the program runs #h(1em) | #h(1em) an *interpreter* translates *while* it runs
    ]
  ]
]

#slide[
  == Compiled Languages
  Translate everything once, run the result many times

  #align(center)[
    #flow(
      file-box("hello.c", sub: [source code]),
      tool-box("compiler", sub: [`gcc`, `clang`, `rustc`]),
      (
        [once],
        file-box("hello", sub: [machine code], on: true),
      ),
      ([many times], tool-box("CPU", fill: kind-colors.compiled.fill, stroke: kind-colors.compiled.stroke)),
    )
  ]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("2-")[
      ```terminal
      $ gcc hello.c -o hello
      $ ./hello
      Hello, 0!
      Hello, 1!
      Hello, 2!
      $ file hello
      hello: ELF 64-bit LSB pie executable
      ```
    ]
  ][
    #set text(size: 0.9em)
    #uncover("3-")[#block[
      ✅ *fast*: the CPU runs the program directly\
      ✅ errors are found *before* running\
      ✅ ship only the executable, not the source
    ]]
    #uncover("4-")[#block[
      ❌ one executable per *processor* and *OS*\
      ❌ compile again after *every* change
    ]]
    #uncover("5-")[
      #v(0.3em)
      #chip("C", "compiled") #chip("C++", "compiled") #chip("Rust", "compiled") #chip("Go", "compiled") #chip("Zig", "compiled") #chip("Fortran", "compiled")
    ]
  ]
]

// ----- drawings: an interpreter (or a VM) is a loop that runs on the CPU -----

// a file with a few lines in it, `on` is the line that is being read
#let lines-file(x, y, w, name, lines, on: none, fill: white, stroke: luma(140), line-h: 13pt) = {
  let h = 22pt + lines.len() * line-h
  place(top + left, dx: x, dy: y, rect(width: w, height: h, radius: 3pt, fill: fill, stroke: 0.8pt + stroke))
  place(top + left, dx: x + 6pt, dy: y + 5pt, text(font: mono, size: 7.5pt, weight: "bold", fill: luma(60), name))
  for (i, l) in lines.enumerate() {
    let ly = y + 20pt + i * line-h
    if i == on {
      place(top + left, dx: x + 3pt, dy: ly - 2.5pt, rect(width: w - 6pt, height: line-h - 1pt, radius: 2pt, fill: changed-fill, stroke: 1pt + changed))
    }
    place(top + left, dx: x + 7pt, dy: ly, text(font: mono, size: 7pt, l))
  }
}

// the program that runs the code: a box with a loop of stages (read the
// next line or instruction, ..., do it), sitting on the CPU that runs it
#let machine-loop(x, w, title, sub, stages, cpu: [*CPU*: runs its machine code]) = context {
  let h = 56pt
  place(top + left, dx: x, dy: 0pt, rect(width: w, height: h, radius: 6pt, fill: changed-fill, stroke: 1.5pt + changed))
  pin(x + w / 2, 10pt, text(size: 8.5pt)[#text(weight: "bold", fill: changed, title) #text(size: 0.8em, fill: luma(90), sub)])
  // the stages, in a row, with arrows between them
  let gap = 14pt
  let widths = stages.map(s => measure(text(size: 7.5pt, s)).width + 12pt)
  let total = widths.sum() + gap * (stages.len() - 1)
  let sx = x + (w - total) / 2
  let y = 19pt
  let centers = ()
  for (i, s) in stages.enumerate() {
    place(top + left, dx: sx, dy: y, rect(width: widths.at(i), height: 16pt, radius: 8pt, fill: white, stroke: 0.8pt + changed))
    pin(sx + widths.at(i) / 2, y + 8pt, text(size: 7.5pt, s))
    centers.push(sx + widths.at(i) / 2)
    if i < stages.len() - 1 {
      line-arrow((sx + widths.at(i), y + 8pt), (sx + widths.at(i) + gap, y + 8pt), color: changed, head: 4pt)
    }
    sx += widths.at(i) + gap
  }
  // and back to the first one
  let (first, last) = (centers.first(), centers.last())
  let ly = y + 23pt
  wire((last, y + 16pt), (last, ly), stroke: 1pt + changed)
  wire((last, ly), (first, ly), stroke: 1pt + changed)
  line-arrow((first, ly), (first, y + 16pt), color: changed, head: 4pt)
  pin((first + last) / 2, ly + 5.5pt, text(size: 6.5pt, fill: changed, style: "italic")[repeat])
  // the CPU, under it (none: no CPU bar)
  if cpu != none {
    place(top + left, dx: x, dy: h + 4pt, rect(
      width: w,
      height: 17pt,
      radius: 4pt,
      fill: kind-colors.compiled.fill,
      stroke: 0.8pt + kind-colors.compiled.stroke,
    ))
    pin(x + w / 2, h + 12.5pt, text(size: 7pt, fill: kind-colors.compiled.stroke.darken(35%), cpu))
  }
}

#let interpreter-picture = drawing(width: 440pt, height: 80pt, {
  let small(body) = text(size: 6.5pt, fill: luma(100), style: "italic", body)
  // the script: just text
  lines-file(0pt, 2pt, 112pt, "hello.sh", (
    highlight-shell("echo \"Hello!\""),
    highlight-shell("x=$((6 * 7))"),
    highlight-shell("echo \"x is $x\""),
  ), on: 1)
  pin(56pt, 71pt, small[source code (text)])
  line-arrow((112pt, 39pt), (150pt, 27pt), color: changed, thickness: 1.2pt)
  pin(130pt, 46pt, small[one line\ at a time])
  // the interpreter
  machine-loop(152pt, 180pt, [interpreter], text(font: mono)[bash], ([read the line], [understand it], [do it]), cpu: [*CPU*: runs the interpreter, not the script])
  // what the script prints
  line-arrow((332pt, 27pt), (355pt, 27pt), color: luma(120))
  place(top + left, dx: 357pt, dy: 2pt, rect(width: 83pt, height: 50pt, radius: 3pt, fill: rgb("e4eaed")))
  place(top + left, dx: 363pt, dy: 8pt, text(font: mono, size: 7pt, fill: luma(60))[Hello!])
  pin(398pt, 60pt, small[output])
})

// the bytecode of `total = total + i;` (total is variable 1, i is variable 2)
// with `jit: true`, the code that runs often (hot) is compiled by the JIT
// to machine code, that the CPU runs directly
#let bytecode-picture(jit: false) = drawing(width: 450pt, height: 84pt, {
  let small(body) = text(size: 6.5pt, fill: luma(100), style: "italic", body)
  lines-file(0pt, 12pt, 92pt, "Hello.java", (text(size: 6.5pt)[total = total + i;],))
  pin(46pt, 56pt, small[source code])
  line-arrow((92pt, 34pt), (108pt, 34pt))
  pin(127pt, 34pt, tool-box("javac"))
  line-arrow((146pt, 34pt), (164pt, 34pt))
  pin(155pt, 26pt, small[once])
  // the bytecode: one byte for every instruction
  let bc = (("1b", "iload_1"), ("1c", "iload_2"), ("60", "iadd"), ("3c", "istore_1"))
  lines-file(
    166pt,
    0pt,
    82pt,
    "Hello.class",
    bc.map(((b, n)) => [#text(weight: "bold", fill: changed, b) #h(0.3em) #n]),
    fill: kind-colors.bytecode.fill.lighten(30%),
    stroke: kind-colors.bytecode.stroke,
    line-h: 11pt,
  )
  pin(207pt, 75pt, small[bytecode: 1 byte = 1 instruction])
  if not jit {
    line-arrow((248pt, 27pt), (276pt, 27pt))
    pin(262pt, 19pt, small[every run])
    // the virtual machine
    machine-loop(278pt, 172pt, [virtual machine], text(font: mono)[java], ([read an instruction], [do it]), cpu: [*CPU*: runs the VM, not the bytecode])
  } else {
    // the slow way: the VM interprets the code that runs rarely
    line-arrow((248pt, 16pt), (283pt, 13pt))
    pin(266pt, 7pt, small[rare code])
    place(top + left, dx: 285pt, dy: 0pt, rect(width: 165pt, height: 26pt, radius: 5pt, fill: white, stroke: 1pt + accent))
    pin(367pt, 13pt, text(size: 7.5pt)[#text(weight: "bold", fill: accent)[virtual machine]: read, do (_slow_)])
    // the fast way: the JIT compiles the hot code once
    line-arrow((248pt, 46pt), (283pt, 44pt), color: changed, thickness: 1.2pt)
    pin(266pt, 53pt, small[#text(fill: changed)[*hot* code]])
    pin(305pt, 44pt, tool-box("JIT", on: true))
    line-arrow((325pt, 44pt), (343pt, 44pt), color: changed, thickness: 1.2pt)
    place(top + left, dx: 345pt, dy: 32pt, rect(width: 105pt, height: 24pt, radius: 3pt, fill: kind-colors.compiled.fill, stroke: 1pt + kind-colors.compiled.stroke))
    pin(397pt, 44pt, text(font: mono, size: 7pt)[8b 45 fc 01 45 f8])
    // the CPU, under the machine code: it runs it directly (_fast_)
    place(top + left, dx: 285pt, dy: 60pt, rect(
      width: 165pt,
      height: 17pt,
      radius: 4pt,
      fill: kind-colors.compiled.fill,
      stroke: 0.8pt + kind-colors.compiled.stroke,
    ))
    pin(367pt, 68.5pt, text(size: 7pt, fill: kind-colors.compiled.stroke.darken(35%))[*CPU*: runs the machine code directly (_fast_)])
  }
})

#slide[
  == Interpreted Languages
  A program (the interpreter) reads the source and does what it says

  #interpreter-picture

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("2-")[
      ```terminal
      $ ./hello.sh
      Hello, 0!
      Hello, 1!
      Hello, 2!
      $ file hello.sh
      hello.sh: Bourne-Again shell script
      $ file /bin/bash
      /bin/bash: ELF 64-bit LSB pie executable
      ```
    ]
  ][
    #set text(size: 0.9em)
    #uncover("3-")[#block[
      ✅ *portable*: runs wherever the interpreter runs\
      ✅ edit and run, no build step
    ]]
    #uncover("4-")[#block[
      ❌ *slower*: the source is translated at every run\
      ❌ errors are found only when that line *runs*\
      ❌ ship the source code
    ]]
    #uncover("5-")[
      #v(0.3em)
      #chip("bash", "interpreted") #chip("sh", "interpreted") #chip("zsh", "interpreted") #chip("classic BASIC", "interpreted")
    ]
  ]
]

#slide[
  == Bytecode and Virtual Machines
  Hybrid languages: compile to an *intermediate* code, then interpret it

  #only("1-3", bytecode-picture())
  #only("4-", bytecode-picture(jit: true))

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #only("1-2")[
      #uncover("2-")[
        ```terminal
        $ javac Hello.java
        $ file Hello.class
        Hello.class: compiled Java class data, version 65.0
        $ java Hello
        Hello, 0!
        ...
        ```
      ]
    ]
    #only("3-")[
      ```terminal
      $ javap -c Hello
      ...
        10: iload_1
        11: iload_2
        12: iadd
        13: istore_1
      ...
      ```
    ]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[
      - bytecode: machine code for an _imaginary_ CPU, the VM
      - the same `.class` file runs on any OS and CPU with a JVM
    ]]
    #uncover("4-")[#block[
      - *JIT* (_just in time_): the VM compiles the code that runs often to real machine code
    ]]
    #uncover("5-")[
      #chip("Java", "bytecode") #chip("Kotlin", "bytecode") #chip("C#", "bytecode") #chip("Python", "bytecode") #chip("JavaScript", "bytecode")
    ]
  ]
]

// python3, node, deno and chrome: one program that holds a compiler and a
// virtual machine (and, for JavaScript, a JIT)
#let engines-picture(js: false) = drawing(width: 460pt, height: 96pt, {
  let small(body, ..args) = text(size: 6.5pt, fill: luma(100), style: "italic", ..args, body)
  let pill(x, y, w, body, fill: white, stroke: accent) = {
    place(top + left, dx: x - w / 2, dy: y - 9pt, rect(width: w, height: 18pt, radius: 9pt, fill: fill, stroke: 0.8pt + stroke))
    pin(x, y, text(size: 7pt, body))
  }
  let row(y, file, names, sub, jit: false) = {
    // the source file: this is what you run
    place(top + left, dx: 0pt, dy: y - 14pt, rect(width: 62pt, height: 28pt, radius: 3pt, fill: white, stroke: 0.8pt + luma(140)))
    pin(31pt, y - 5pt, text(font: mono, size: 7.5pt, weight: "bold", file))
    pin(31pt, y + 7pt, small[source code])
    line-arrow((62pt, y), (80pt, y))
    // the program that runs it
    place(top + left, dx: 82pt, dy: y - 17pt, rect(width: 378pt, height: 34pt, radius: 6pt, fill: changed-fill, stroke: 1.5pt + changed))
    pin(124pt, y, stack(spacing: 4pt, text(font: mono, size: 7.5pt, weight: "bold", fill: changed, names), small(sub)))
    pill(190pt, y, 46pt, [compiler])
    line-arrow((213pt, y), (226pt, y), head: 4pt)
    pill(254pt, y, 54pt, [bytecode], fill: kind-colors.bytecode.fill, stroke: kind-colors.bytecode.stroke)
    line-arrow((281pt, y), (292pt, y), head: 4pt)
    pill(321pt, y, 56pt, [VM: read, do])
    if jit {
      line-arrow((349pt, y), (360pt, y), color: changed, head: 4pt)
      pill(377pt, y, 32pt, text(weight: "bold", fill: changed)[JIT], stroke: changed)
      line-arrow((393pt, y), (403pt, y), color: changed, head: 4pt)
      pill(429pt, y, 50pt, [machine code], fill: kind-colors.compiled.fill, stroke: kind-colors.compiled.stroke)
    }
  }
  row(17pt, "total.py", [python3], [CPython])
  if js {
    row(56pt, "total.js", [node, deno,\ chrome], [all use V8], jit: true)
  }
  // the CPU runs these programs, they run the source
  place(top + left, dx: 82pt, dy: 78pt, rect(
    width: 378pt,
    height: 17pt,
    radius: 4pt,
    fill: kind-colors.compiled.fill,
    stroke: 0.8pt + kind-colors.compiled.stroke,
  ))
  pin(271pt, 86.5pt, text(size: 7pt, fill: kind-colors.compiled.stroke.darken(35%))[*CPU*: runs #text(font: mono)[python3], #text(font: mono)[node], ... (compiled programs), not your source])
})

#slide[
  == Python is Compiled Too
  ... to bytecode, automatically, every time you start it

  #only("1", engines-picture())
  #only("2-", engines-picture(js: true))

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #only(1)[
      #set text(size: 0.9em)
      ```terminal
      $ cat total.py
      total = total + i
      $ python3 -m dis total.py
        LOAD_NAME     0 (total)
        LOAD_NAME     1 (i)
        BINARY_OP     0 (+)
        STORE_NAME    0 (total)
      ```
    ]
    #only("2-")[
      #set text(size: 0.8em)
      ```terminal
      $ cat total.js
      function add(total, i) { return total + i }
      add(10, 3)
      $ node --print-bytecode \
        --print-bytecode-filter=add total.js
        0b 04      Ldar a1
        3b 03 00   Add a0, [0]
        ae         Return
      ```
    ]
  ][
    #set text(size: 0.85em)
    - `python3` compiles the source to *bytecode* (cached in `__pycache__`), then its VM runs it
    #uncover("2-")[
      - `node`, `deno` and `chrome` share the *V8* engine, that also JIT-compiles the hot code
    ]
    #uncover("3-")[
      #callout[you run the source, but *not* line by line]
    ]
  ]
]

// ----- the big picture: when does the translation happen? -----

#let spectrum-columns = (
  (x: 55pt, kind: "compiled", langs: ("C", "C++", "Rust", "Go", "Zig", "Fortran"), what: [native executable]),
  (x: 170pt, kind: "bytecode", langs: ("Java", "Kotlin", "C#"), what: [bytecode file + VM]),
  (x: 290pt, kind: "bytecode", langs: ("JavaScript", "Python", "Ruby", "PHP", "Perl"), what: [source, bytecode in memory]),
  (x: 400pt, kind: "interpreted", langs: ("bash", "sh", "zsh"), what: [source, one command at a time]),
)

#let spectrum(upto) = drawing(width: 450pt, height: 176pt, {
  // on top: what you gain going to each side
  let emoji(e) = box(move(dy: -0.15em, text(size: 12pt, e)))
  let gain = 8pt
  line-arrow((90pt, gain), (10pt, gain), color: kind-colors.compiled.stroke, thickness: 2pt, head: 7pt)
  place(top + left, dx: 96pt, dy: gain - 6.5pt, text(size: 8.5pt, fill: kind-colors.compiled.stroke.darken(30%))[#emoji("🚀") *runs faster*])
  place(top + right, dx: -86pt, dy: gain - 6.5pt, text(size: 8.5pt, fill: kind-colors.interpreted.stroke.darken(40%))[*easier to change and debug* #emoji("🐞")])
  line-arrow((370pt, gain), (445pt, gain), color: kind-colors.interpreted.stroke, thickness: 2pt, head: 7pt)
  // the axis: a bar from blue (compiled) to green (interpreted)
  let y = 128pt
  place(top + left, dx: 10pt, dy: y - 3pt, rect(
    width: 435pt,
    height: 6pt,
    radius: 3pt,
    fill: gradient.linear(kind-colors.compiled.stroke, kind-colors.bytecode.stroke, kind-colors.interpreted.stroke),
  ))
  place(top + left, dx: 10pt, dy: y + 22pt, text(size: 7.5pt, fill: luma(90))[*before* it runs (ahead of time)])
  place(top + right, dx: -5pt, dy: y + 22pt, text(size: 7.5pt, fill: luma(90))[*while* it runs])
  pin(225pt, y + 28pt, text(size: 8pt, fill: luma(60))[*from left to right:* _when_ is the code translated to machine code?])
  for (i, col) in spectrum-columns.enumerate() {
    if i < upto {
      // the chips, stacked from the axis up
      let n = col.langs.len()
      for (j, l) in col.langs.enumerate() {
        pin(col.x, y - 15pt - (n - 1 - j) * 18pt, chip(l, col.kind))
      }
      pin(col.x, y + 11pt, text(size: 7pt, fill: luma(60), col.what))
    }
  }
})

// on top of the big picture: the language does not decide, the program
// that runs it does
#let implementation-note = {
  let emoji(e, size: 1.4em) = box(move(dy: -0.12em, text(size: size, e)))
  // one way to run a language: an emoji, the program and what it does
  let way(e, name, kind, what) = box(
    width: 100%,
    inset: (x: 0.6em, y: 0.35em),
    radius: 0.4em,
    fill: kind-colors.at(kind).fill.lighten(30%),
    align(left)[#emoji(e) #h(0.2em) #text(font: mono, size: 0.95em, weight: "bold", name) #h(0.2em) #text(fill: luma(70), what)],
  )
  // a language and two programs that run it in different ways
  let lang(name, kind, ways) = box(
    width: 100%,
    inset: 0.6em,
    radius: 0.5em,
    fill: white,
    stroke: 0.6pt + luma(215),
    stack(spacing: 0.4em, align(center, chip(name, kind)), ..ways),
  )
  box(
    width: 78%,
    inset: (x: 1.2em, y: 0.9em),
    radius: 0.7em,
    fill: rgb("f7f9fa"),
    stroke: 1pt + luma(185),
    align(center)[
      #text(size: 1.1em)[#emoji("🤔", size: 1.5em) #h(0.2em) a *language* is not compiled or interpreted ...]\
      #text(size: 1.1em)[... the *program that runs it* is #h(0.2em) #emoji("💡", size: 1.5em)]
      #v(0.3em)
      #set text(size: 0.8em)
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 1em,
        lang("C", "compiled", (
          way("⚙️", "gcc", "compiled", [compiles it]),
          way("📜", "picoc", "interpreted", [interprets it]),
        )),
        lang("Python", "bytecode", (
          way("⚙️", "nuitka", "compiled", [compiles it]),
          way("📜", "python3", "bytecode", [interprets its bytecode]),
        )),
      )
    ],
  )
}

#slide[
  == The Big Picture
  The line between _compiled_ and _interpreted_ is blurry

  #for i in range(1, 5) {
    only(i, spectrum(i))
  }
  #only("5-")[
    #block(width: 100%, {
      spectrum(4)
      // dim the drawing, the note goes on top
      place(top + left, rect(width: 100%, height: 100%, fill: white.transparentize(15%)))
      place(center + horizon, implementation-note)
    })
  ]

  #v(1fr)
  #only(1)[💡 compiled to a *native executable*: the CPU runs it directly]
  #only(2)[💡 compiled to a *bytecode file*: a virtual machine (JVM, .NET) runs it, with a JIT]
  #only(3)[💡 you run the *source*, the interpreter compiles it to bytecode when it starts]
  #only(4)[💡 shells really read and run one command at a time]
]

// one row of the comparison: the question, the two answers and which
// side is better ("compiled", "interpreted" or none, when it depends)
#let compare-rows = (
  ([When is the code translated?], [once, before it runs], [every time it runs], none),
  ([How fast does it run?], [fast], [slower (a JIT helps)], "compiled"),
  ([When do you find errors?], [before it runs], [only when that line runs], "compiled"),
  ([You changed the code?], [compile again, then run], [run it right away], "interpreted"),
  ([Another CPU or OS?], [compile again for it], [runs if it has the interpreter], "interpreted"),
  ([What do you give to users?], [the executable], [the source (or bytecode)], none),
  ([Good for], [OS, drivers, games, tools], [scripts, web, data science], none),
)

#slide[
  == Compiled vs Interpreted
  Neither is better: it depends on what you need

  #set text(size: 0.92em)
  #let answer(body, side, better) = {
    if better == none {
      table.cell(body)
    } else if better == side {
      table.cell(fill: ok-fill)[✅ #body]
    } else {
      table.cell[❌ #body]
    }
  }
  #align(center)[
    #table(
      columns: (auto, 1fr, 1fr),
      align: (left + horizon, center + horizon, center + horizon),
      inset: (x: 0.6em, y: 0.5em),
      stroke: (x, y) => if y > 0 { (top: 0.5pt + luma(215)) },
      table.header(
        [],
        table.cell(fill: kind-colors.compiled.fill)[
          #text(size: 1.15em, weight: "bold", fill: kind-colors.compiled.stroke.darken(30%))[Compiled]
          #h(0.4em) #chip("C", "compiled") #chip("Rust", "compiled") #chip("Go", "compiled")
        ],
        table.cell(fill: kind-colors.interpreted.fill)[
          #text(size: 1.15em, weight: "bold", fill: kind-colors.interpreted.stroke.darken(40%))[Interpreted]
          #h(0.4em) #chip("bash", "interpreted") #chip("Python", "bytecode") #chip("JS", "bytecode")
        ],
      ),
      ..compare-rows
        .map(((q, c, i, better)) => (
          text(fill: luma(90), style: "italic", q),
          answer(c, "compiled", better),
          answer(i, "interpreted", better),
        ))
        .flatten(),
    )
  ]

  #v(1fr)
  #uncover(2)[
    #let take(emoji, kind, name, body) = box(
      width: 100%,
      inset: (x: 0.8em, y: 0.35em),
      radius: 0.4em,
      fill: kind-colors.at(kind).fill,
      stroke: 1.5pt + kind-colors.at(kind).stroke,
      align(center, grid(columns: 2, column-gutter: 0.5em, align: horizon, move(dy: -0.25em, text(size: 2.4em, emoji)), text(size: 1.1em)[#name: *#body*])),
    )
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 1em,
      take("🚀", "compiled", [compiled], [faster to run]),
      take("✍️", "interpreted", [interpreted], [faster to write and change]),
    )
    #v(0.3em)
  ]
]
