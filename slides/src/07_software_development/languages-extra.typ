#import "/src/slides.typ": *
#import "common.typ": *

// Extra section, at the end of the lecture: how an interpreter and a
// virtual machine run the code, step by step.

#slide[
  = Extra: Inside Interpreters #text(size: 10pt, weight: "regular")[\ _How does an interpreter or a virtual machine actually run the code?_]
]

// ----- inside an interpreter: bash runs hello.sh one line at a time -----

#let script = (
  "echo \"Hello!\"",
  "x=$((6 * 7))",
  "echo \"x is $x\"",
  "ech \"Bye!\"",
)

// what bash does with each line: the three stages of its loop, the
// variables it keeps and what is printed in the terminal so far
// monospace text, without the background of inline code
#let c(body) = text(font: mono, size: 0.9em, body)

#let interp-steps = (
  (
    understand: [the command #c("echo"), one argument],
    do: [print #c("Hello!")],
    vars: none,
    out: ("Hello!",),
  ),
  (
    understand: [set the variable #c("x") to 6 × 7],
    do: [compute 42, keep #c("x = 42")],
    vars: c("x = 42"),
    out: ("Hello!",),
  ),
  (
    understand: [#c("echo"), replace #c("$x") with 42],
    do: [print #c("x is 42")],
    vars: c("x = 42"),
    out: ("Hello!", "x is 42"),
  ),
  (
    understand: [the command #c("ech")],
    do: [no such command: *error!*],
    vars: c("x = 42"),
    out: ("Hello!", "x is 42"),
    error: true,
  ),
)

#let interpreter-drawing(step) = drawing(width: 460pt, height: 182pt, {
  let s = interp-steps.at(step - 1)
  let error = s.at("error", default: false)
  let hot = if error { bad-color } else { changed }
  let hot-fill = if error { bad-fill } else { changed-fill }
  let small(body, ..args) = text(size: 7.5pt, ..args, body)
  let code(body, ..args) = text(font: mono, size: 7.5pt, ..args, body)

  // ---- the script, a text file ----
  let line-y(i) = 34pt + i * 20pt
  place(top + left, dx: 0pt, dy: 0pt, small(fill: luma(90), style: "italic")[the script: just text])
  place(top + left, dx: 0pt, dy: 14pt, rect(
    width: 140pt,
    height: 100pt,
    radius: 3pt,
    fill: white,
    stroke: 0.8pt + luma(140),
  ))
  place(top + left, dx: 6pt, dy: 18pt, code(fill: luma(60), weight: "bold")[hello.sh])
  for (i, l) in script.enumerate() {
    let y = line-y(i)
    if i + 1 == step {
      place(top + left, dx: 3pt, dy: y - 2pt, rect(width: 134pt, height: 15pt, radius: 2pt, fill: hot-fill, stroke: 1pt + hot))
    }
    place(top + left, dx: 8pt, dy: y + 2pt, code(fill: luma(140), str(i + 1)))
    place(top + left, dx: 20pt, dy: y + 2pt, text(font: mono, size: 7.5pt, highlight-shell(l)))
  }

  // ---- the interpreter: a loop of three stages ----
  let bx = 165pt
  let bw = 165pt
  place(top + left, dx: bx, dy: 0pt, rect(
    width: bw,
    height: 152pt,
    radius: 6pt,
    fill: rgb("eef3f5"),
    stroke: 1.2pt + accent,
  ))
  pin(bx + bw / 2, 11pt, text(size: 9pt, weight: "bold", fill: accent)[the interpreter: #c("bash")])
  let stages = (
    ([① read the next line], code(fill: hot, script.at(step - 1))),
    ([② understand it], small(fill: hot, s.understand)),
    ([③ do it], small(fill: hot, s.do)),
  )
  let px = bx + 10pt
  let pw = 130pt
  let stage-y(i) = 24pt + i * 36pt
  for (i, (title, detail)) in stages.enumerate() {
    let y = stage-y(i)
    place(top + left, dx: px, dy: y, rect(
      width: pw,
      height: 27pt,
      radius: 4pt,
      fill: white,
      stroke: 0.8pt + accent,
    ))
    place(top + left, dx: px + 6pt, dy: y + 3pt, small(weight: "bold", fill: accent, title))
    place(top + left, dx: px + 6pt, dy: y + 14pt, detail)
    if i < 2 {
      line-arrow((px + pw / 2, y + 27pt), (px + pw / 2, stage-y(i + 1)), color: accent, head: 4pt)
    }
  }
  // the loop: after ③, back to ①
  let lx = px + pw + 9pt
  let y1 = stage-y(0) + 13pt
  let y3 = stage-y(2) + 13pt
  wire((px + pw, y3), (lx, y3), stroke: 1pt + accent)
  wire((lx, y3), (lx, y1), stroke: 1pt + accent)
  line-arrow((lx, y1), (px + pw, y1), color: accent, head: 4pt)
  pin(lx + 7pt, (y1 + y3) / 2, rotate(-90deg, reflow: true, text(size: 6.5pt, fill: accent, style: "italic")[next line]))
  // the variables, kept in the memory of bash
  place(top + left, dx: px, dy: 132pt, small(fill: luma(80))[
    variables: #if s.vars == none { text(fill: luma(150))[none yet] } else { text(fill: if step == 2 { changed } else { black }, s.vars) }
  ])

  // the current line goes into ①
  line-arrow((140pt, line-y(step - 1) + 6pt), (px, stage-y(0) + 13pt), color: hot, thickness: 1.2pt)

  // ---- the CPU, under bash: it runs the machine code of bash ----
  place(top + left, dx: bx, dy: 157pt, rect(
    width: bw,
    height: 22pt,
    radius: 4pt,
    fill: kind-colors.compiled.fill,
    stroke: 0.8pt + kind-colors.compiled.stroke,
  ))
  pin(bx + bw / 2, 168pt, small(fill: kind-colors.compiled.stroke.darken(30%))[*CPU*: runs the machine code of #c("bash")])

  // ---- the terminal ----
  let tx = 348pt
  place(top + left, dx: tx, dy: 0pt, small(fill: luma(90), style: "italic")[the terminal])
  place(top + left, dx: tx, dy: 14pt, rect(width: 112pt, height: 100pt, radius: 3pt, fill: rgb("e4eaed")))
  let out-y(i) = 22pt + i * 13pt
  for (i, o) in s.out.enumerate() {
    let new = (step == 1 and i == 0) or (step == 3 and i == 1)
    place(top + left, dx: tx + 6pt, dy: out-y(i), code(fill: if new { changed } else { luma(60) }, weight: if new { "bold" } else { "regular" }, o))
  }
  if error {
    let y = out-y(s.out.len())
    place(top + left, dx: tx + 6pt, dy: y, text(font: mono, size: 7pt, fill: bad-color, weight: "bold")[hello.sh: line 4:\ ech: command not found])
  }
  // ③ prints to the terminal (not on step 2, nothing is printed)
  if step != 2 {
    line-arrow((bx + bw, stage-y(2) + 13pt), (tx, stage-y(2) + 13pt), color: hot, thickness: 1.2pt)
  }
})

#slide[
  == How an Interpreter Works
  Read a line, understand it, do it, repeat

  #for i in range(1, 5) {
    only(if i == 4 { "4-" } else { i }, interpreter-drawing(i))
  }

  #v(1fr)
  #only(1)[💡 `bash` takes the script one line (command) at a time: *read* it, *understand* it, *do* it]
  #only(2)[💡 the variables of the script live in the memory of `bash`]
  #only(3)[💡 nothing was translated ahead: each line is understood right before it runs]
  #only(4)[💡 the typo on line 4 is found only now: lines 1 - 3 *already ran*]
  #only("5-")[
    #callout[the CPU runs only `bash`: `hello.sh` is just *data* that `bash` reads]
  ]
]

// ----- what bytecode looks like: the same line, three ways -----

// the bytecode of `total = total + i;` (total is variable 1, i is variable 2)
#let bytecode = (
  ("1b", "iload_1", [push #c("total")]),
  ("1c", "iload_2", [push #c("i")]),
  ("60", "iadd", [add the top two]),
  ("3c", "istore_1", [pop into #c("total")]),
)

#slide[
  == What is Bytecode?
  Machine code for a processor that does not exist

  #let title(body) = text(size: 0.65em, fill: luma(90), style: "italic", body)
  #let caption(body) = text(size: 0.65em, fill: luma(90), body)
  #let card(body, color: luma(140), fill: white) = box(inset: 0.5em, radius: 0.3em, fill: fill, stroke: 0.8pt + color, body)
  #align(center)[
    #grid(
      columns: 5,
      column-gutter: 0.5em,
      row-gutter: 0.35em,
      align: (x, y) => center + if y == 0 { bottom } else if y == 1 { horizon } else { top },
      // the titles
      title[source code, for people], [], title[bytecode, for the JVM], [], uncover("3-", title[machine code, for one real CPU]),
      // the code
      card(text(font: mono, size: 0.75em)[total = total + i;]),
      stack(spacing: 0.2em, arrow-label[#c("javac"), once], draw-arrow(length: 2.2em)),
      card(
        color: kind-colors.bytecode.stroke,
        fill: kind-colors.bytecode.fill.lighten(40%),
        {
          set text(size: 0.7em)
          grid(
            columns: 3,
            column-gutter: 0.7em,
            row-gutter: 0.45em,
            align: left,
            ..bytecode
              .map(((b, name, what)) => (
                text(font: mono, weight: "bold", fill: changed, b),
                text(font: mono, name),
                text(fill: luma(90), style: "italic", what),
              ))
              .flatten(),
          )
        },
      ),
      uncover("3-", text(size: 0.8em, fill: luma(110), style: "italic")[vs]),
      uncover("3-", card(
        color: kind-colors.compiled.stroke,
        fill: kind-colors.compiled.fill.lighten(40%),
        {
          set text(size: 0.7em)
          grid(
            columns: 2,
            column-gutter: 0.6em,
            row-gutter: 0.45em,
            align: (right + top, left + top),
            [*x86-64*], text(font: mono)[8b 45 fc 01 45 f8],
            [*ARM64*], text(font: mono)[e8 0b 40 b9 e9 07 40 b9\ 08 01 09 0b e8 0b 00 b9],
          )
        },
      )),
      // what each one is
      caption[text: names, expressions], [], caption[4 bytes, the *same* on every computer], [], uncover("3-", caption[*different* bytes on every CPU]),
    )
  ]

  #v(0.4em)
  #set text(size: 0.85em)
  - tiny instructions: no names, no expressions, only *push*, *add*, *pop*
  - already parsed and checked by #c("javac"): nothing is left to understand
  #uncover("2-")[
    - every instruction code is *one byte* (#text(font: mono, fill: changed)[1b], #text(font: mono, fill: changed)[60], ...), hence the name _byte_-code
  ]
  #uncover("3-")[
    - a real CPU runs only its own machine code, any JVM runs the same bytecode
  ]
  #v(1fr)
  #only("4-")[
    #callout[bytecode = machine code for an *imaginary processor*, played by the *virtual machine*]
  ]
]

// ----- running bytecode: the JVM is an interpreter for bytecode -----

// the C code of a (very) simplified JVM: one `case` for each instruction
#let vm-code = (
  "while (true) {",
  "  switch (code[pc++]) {",
  "  case 0x1b: push(var[1]); break;",
  "  case 0x1c: push(var[2]); break;",
  "  case 0x60: push(pop()+pop()); break;",
  "  case 0x3c: var[1] = pop(); break;",
  "  ...",
  "  }",
  "}",
)

// the state of the VM after each step: (stack, total, the new value)
#let vm-steps = (
  (stack: (), total: 10, pc: 0),
  (stack: (10,), total: 10, pc: 1),
  (stack: (10, 3), total: 10, pc: 2),
  (stack: (13,), total: 10, pc: 3),
  (stack: (), total: 13, pc: 4),
)

#let vm-drawing(step) = drawing(width: 465pt, height: 172pt, {
  let s = vm-steps.at(step - 1)
  // the instruction that was just executed (none on the first step)
  let done = step - 2
  let small(body, ..args) = text(size: 7.5pt, ..args, body)
  let code(body, ..args) = text(font: mono, size: 8pt, ..args, body)
  let title(x, body) = place(top + left, dx: x, dy: 0pt, small(fill: luma(90), style: "italic", body))
  let pointer(x, y) = place(top + left, dx: x, dy: y, polygon(fill: accent, (0pt, 0pt), (8pt, 4pt), (0pt, 8pt)))

  // ---- the bytecode, with the program counter ----
  let bx = 10pt
  title(bx, [the bytecode])
  place(top + left, dx: bx, dy: 14pt, rect(
    width: 92pt,
    height: 112pt,
    radius: 3pt,
    fill: kind-colors.bytecode.fill.lighten(40%),
    stroke: 0.8pt + kind-colors.bytecode.stroke,
  ))
  let row-y(i) = 24pt + i * 22pt
  for (i, (b, name, what)) in bytecode.enumerate() {
    let y = row-y(i)
    if i == done {
      place(top + left, dx: bx + 3pt, dy: y - 3.5pt, rect(width: 86pt, height: 17pt, radius: 2pt, fill: changed-fill, stroke: 1pt + changed))
    }
    place(top + left, dx: bx + 10pt, dy: y + 1pt, code(weight: "bold", fill: changed, b))
    place(top + left, dx: bx + 32pt, dy: y + 1pt, code(name))
  }
  // pc: the next instruction to run
  pointer(bx - 10pt, row-y(s.pc) + 1pt)
  pointer(bx, 136pt)
  place(top + left, dx: bx + 11pt, dy: 136pt, small(fill: accent)[#c("pc"): the next instruction])

  // ---- the stack ----
  let sx = 132pt
  title(sx, [the stack])
  let bottom = 126pt
  let slot(i) = bottom - 27pt - i * 25pt
  // an open box: the values pile up from the bottom
  let edge = 1.2pt + luma(110)
  wire((sx, 18pt), (sx, bottom), stroke: edge)
  wire((sx, bottom), (sx + 54pt, bottom), stroke: edge)
  wire((sx + 54pt, bottom), (sx + 54pt, 18pt), stroke: edge)
  for (i, v) in s.stack.enumerate() {
    let new = i == s.stack.len() - 1 and step in (2, 3, 4)
    place(top + left, dx: sx + 5pt, dy: slot(i), rect(
      width: 44pt,
      height: 22pt,
      radius: 2pt,
      fill: if new { changed-fill } else { white },
      stroke: if new { 1.2pt + changed } else { 0.8pt + luma(140) },
    ))
    pin(sx + 27pt, slot(i) + 11pt, code(weight: "bold", fill: if new { changed } else { black }, str(v)))
  }
  if s.stack.len() == 0 {
    pin(sx + 27pt, bottom - 12pt, small(fill: luma(150), style: "italic")[empty])
  }

  // ---- the variables ----
  let vx = 205pt
  title(vx, [the variables])
  let var-row(i, name, value, new: false) = {
    let y = 18pt + i * 26pt
    place(top + left, dx: vx, dy: y, rect(
      width: 70pt,
      height: 22pt,
      radius: 2pt,
      fill: if new { changed-fill } else { white },
      stroke: if new { 1.2pt + changed } else { 0.8pt + luma(140) },
    ))
    place(top + left, dx: vx + 5pt, dy: y + 7pt, code(fill: luma(140), str(i + 1)))
    place(top + left, dx: vx + 16pt, dy: y + 7pt, code(name))
    place(top + left, dx: vx + 50pt, dy: y + 7pt, code(weight: "bold", fill: if new { changed } else { black }, str(value)))
  }
  var-row(0, "total", s.total, new: step == 5)
  var-row(1, "i", 3)

  // ---- inside the JVM: a loop with a switch ----
  let cx = 285pt
  title(cx, [inside the JVM (simplified C)])
  place(top + left, dx: cx, dy: 14pt, rect(width: 180pt, height: 140pt, radius: 3pt, fill: rgb("eef3f5"), stroke: 0.8pt + accent))
  for (i, l) in vm-code.enumerate() {
    let y = 22pt + i * 14.5pt
    let on = done >= 0 and i == done + 2
    // the case of the instruction that was just executed
    if on {
      place(top + left, dx: cx + 3pt, dy: y - 3pt, rect(width: 174pt, height: 13.5pt, radius: 2pt, fill: changed-fill, stroke: 1pt + changed))
    }
    place(top + left, dx: cx + 7pt, dy: y, text(font: mono, size: 7.2pt, fill: if on { changed } else { black }, weight: if on { "bold" } else { "regular" }, l))
  }
})

#slide[
  == Running Bytecode
  The virtual machine is an interpreter, for bytecode instead of text

  #for i in range(1, 6) {
    only(if i == 5 { "5-" } else { i }, vm-drawing(i))
  }

  #v(1fr)
  #only(1)[💡 the JVM keeps the *variables* and a *stack* for the values it works with]
  #only(2)[💡 `1b` (`iload_1`): push the value of variable 1, `total`, on the stack]
  #only(3)[💡 `1c` (`iload_2`): push the value of variable 2, `i`]
  #only(4)[💡 `60` (`iadd`): pop the top two values, push their sum]
  #only(5)[💡 `3c` (`istore_1`): pop the top value into variable 1: `total` is now 13]
  #only("6-")[
    #callout[read one byte, jump to its `case`, repeat: much faster than reading and understanding text]
  ]
]
