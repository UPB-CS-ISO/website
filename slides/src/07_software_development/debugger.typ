#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Debuggers #text(size: 10pt, weight: "regular")[\ _Stop the program and look inside_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.8 - _Depanarea programelor_
  + _Debugging with GDB_, #link("https://sourceware.org/gdb/current/onlinedocs/gdb")[online]
]

#slide[
  == What is a Debugger?
  A program that runs *another program* under its control

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("1-")[#block[
      === Instead of `printf`
      - *breakpoints*: stop at a line or a function
      - *step*: run one line at a time
      - *inspect*: variables, memory, the call stack
      - *watchpoints*: stop when a variable changes
      - *change* a variable and continue
    ]]
  ][
    #uncover("2-")[#block[
      === Debuggers
      - `gdb`, the GNU debugger
      - `lldb`, from LLVM (the `clang` project)
      - the Visual Studio debugger, on Windows
    ]]
  ]

]

// gdb controls app through the kernel, step by step:
// 1. gdb, 2. it starts app (its child), 3. ptrace, 4. a breakpoint stops app
#let ptrace-drawing(step) = drawing(width: 440pt, height: 146pt, {
  let (gx, ax, by) = (100pt, 340pt, 56pt) // gdb, app, the middle of the boxes
  let (ky, kh) = (116pt, 28pt) // the kernel
  // the kernel
  place(top + left, dx: 0pt, dy: ky, box(width: 440pt, height: kh, radius: 0.4em, fill: rgb("ffe6cc"), stroke: 1pt + rgb("d79b00")))
  pin(220pt, ky + kh / 2, text(size: 8.5pt, fill: rgb("8a5a00"))[
    #if step >= 3 [*kernel*: reads and writes the memory and the registers of `app`, stops and continues it] else [*kernel*]
  ])
  pin(26pt, by - 26pt, text(size: 7pt, fill: luma(120), style: "italic")[user space])
  if step >= 2 {
    // gdb starts app
    let starts = (paint: luma(120), thickness: 1pt, dash: "dashed")
    place(top + left, line(start: (gx, by - 17pt), end: (gx, 14pt), stroke: starts))
    place(top + left, line(start: (gx, 14pt), end: (ax, 14pt), stroke: starts))
    line-arrow((ax, 14pt), (ax, by - 18pt), color: luma(120))
    pin(220pt, 6pt, text(size: 8pt, fill: luma(90))[`fork` + `exec`: `app` is a *child* of `gdb`])
  }
  if step >= 3 {
    // gdb asks, the kernel does it to app
    line-arrow((gx - 22pt, by + 18pt), (gx - 22pt, ky - 2pt), color: accent, thickness: 1.5pt, head: 6pt)
    pin(gx - 58pt, (by + ky) / 2, text(size: 8pt, fill: accent)[`ptrace(...)`])
    line-arrow((ax - 22pt, ky - 2pt), (ax - 22pt, by + 18pt), color: accent, thickness: 1.5pt, head: 6pt)
  }
  if step >= 4 {
    // app hits the breakpoint, the kernel stops it and tells gdb
    line-arrow((ax + 22pt, by + 18pt), (ax + 22pt, ky - 2pt), color: changed, thickness: 1.5pt, head: 6pt)
    pin(ax + 66pt, (by + ky) / 2, text(size: 8pt, fill: changed)[at the breakpoint])
    line-arrow((gx + 22pt, ky - 2pt), (gx + 22pt, by + 18pt), color: changed, thickness: 1.5pt, head: 6pt)
    pin(gx + 56pt, (by + ky) / 2, text(size: 8pt, fill: changed)[it stopped])
  }
  pin(gx, by, tool-box([`gdb`], sub: [the debugger, the _parent_], width: 110pt))
  if step >= 2 {
    pin(ax, by, tool-box([`app`], sub: if step >= 4 [stopped at `sum`] else [the program, the _child_], width: 110pt, on: step == 2 or step >= 4))
  } else {
    pin(gx, 22pt, text(size: 9pt, fill: luma(60))[`$ gdb ./app`])
  }
})

#slide[
  == How Does a Debugger Work?
  🐧 On Linux, the debugger is the *parent* of the program and controls it with `ptrace`

  #only(1, ptrace-drawing(1))
  #only(2, ptrace-drawing(2))
  #only(3, ptrace-drawing(3))
  #only("4-", ptrace-drawing(4))

  #v(1fr)
  #only(1)[💡 `gdb` starts the program itself]
  #only(2)[💡 `fork` + `exec`: `app` is a *child* of `gdb`, stopped before its first instruction]
  #only(3)[💡 the `ptrace` system call: `gdb` asks the kernel to read and write `app`, to stop it and continue it]
  #only("4-")[💡 `app` reaches the breakpoint: the kernel stops it and tells `gdb`]
]

// a gdb session: "(gdb) " lines are commands, "$ " lines are shell
// commands, the rest is output; only the first `upto` lines are shown,
// the others keep their space
#let gdb-session(src, upto: none, window: 12) = {
  let all = src.split("\n")
  let last = if upto == none { all.len() } else { upto }
  let first = calc.max(0, last - window)
  let shown = all.slice(first, last)
  // pad to `window` lines, so the block keeps its height
  while shown.len() < window { shown.push(" ") }
  set align(left)
  show raw.line: l => {
    if l.text.starts-with("(gdb) ") [
      #text(fill: accent, weight: "bold")[(gdb)] #text(weight: "bold", l.text.slice(6))
    ] else if l.text.starts-with("$ ") {
      render-terminal-line(l.text)
    } else [
      #text(fill: luma(100), l.text)
    ]
  }
  raw(shown.join("\n"), block: true)
}

#let lib-c = ```c
int sum(int n)
{
    int s = 0;
    for (int i = 1; i <= n; i++) {
        s = s + i;
    }
    return s;
}
```

#let session = "$ gdb -q ./app
Reading symbols from ./app...
(gdb) break sum
Breakpoint 1 at 0x1188: file lib.c, line 3.
(gdb) run
Starting program: /home/student/project/app
Breakpoint 1, sum (n=10) at lib.c:3
3           int s = 0;
(gdb) print n
$1 = 10"

// (the last line of the session shown, the current lines of lib.c for
// debug-code, () for none, the note)
#let session-steps = (
  (2, (), [start the program *under* `gdb`, it does not run yet]),
  (4, (3,), [`break`: a *breakpoint* at the function `sum`, i.e. at the first line of its body, line 3]),
  (8, (3,), [`run`: the program starts and stops at the breakpoint, *before* line 3 runs]),
  (10, (1, 3), [`print`: the value of a variable, or of any C expression (`n * 2`)]),
)

#slide[
  == A `gdb` Session
  `app` is built with `-g`

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1em)[
    // small enough that the `for` line does not wrap
    #set text(size: 0.8em)
    #debug-code(name: "lib.c", session-steps.map(s => s.at(1)), lib-c)
  ][
    #set text(size: 0.92em)
    #for (i, (upto, _, _)) in session-steps.enumerate() {
      only(i + 1, gdb-session(session, upto: upto, window: 10))
    }
  ]

  #v(1fr)
  #for (i, (_, _, note)) in session-steps.enumerate() {
    only(i + 1)[💡 #note]
  }
]

// gdb's text user interface (gdb -tui), drawn as a terminal: the source
// window (B+ a breakpoint, > the next line to run, highlighted), the status
// line and the command window; e.g. #gdb-tui(3, ("(gdb) run",))
#let gdb-tui(current, commands, width: 54) = {
  let pad(s, n) = s + " " * calc.max(0, n - s.clusters().len())
  let src = lib-c.text.split("\n") + ("",)
  let rows = ()
  rows.push(("┌─lib.c" + "─" * (width - 8) + "┐", false))
  for (i, code) in src.enumerate() {
    let n = i + 1
    let mark = (if n == 3 { "B+" } else { "  " }) + (if n == current { ">" } else { " " })
    let num = if code == "" and n > 8 { "" } else { str(n) }
    let body = pad(" " + mark + pad("", 4 - num.len()) + num + "  " + code, width - 2)
    rows.push(("│" + body + "│", n == current))
  }
  rows.push(("└" + "─" * (width - 2) + "┘", false))
  // the address of the first instruction of each line (gcc -O0, x86-64,
  // PIE loaded at 0x555555554000): sum starts at 0x117d, line 3 is +0xb
  // (gdb: "Breakpoint 1 at 0x1188"), line 4 is +0x12, line 5 is +0x1b
  let pc = ("3": "0x555555555188", "4": "0x55555555518f", "5": "0x555555555198").at(str(current))
  rows.push((pad("native process 6201 In: sum", width - 24) + pad("L" + str(current), 6) + "PC: " + pc, false))
  block(width: 100%, fill: rgb("1e1e1e"), radius: 0.3em, inset: 0.5em, {
    set text(font: mono, size: 0.52em, fill: luma(225), top-edge: "ascender", bottom-edge: "descender")
    set par(leading: 0em)
    for (r, on) in rows {
      if on {
        // the current line: inverse video, like gdb
        let (left, mid, right) = (r.clusters().first(), r.clusters().slice(1, -1).join(), r.clusters().last())
        block(spacing: 0em, left + box(fill: luma(225), text(fill: black, mid)) + right)
      } else {
        block(spacing: 0em, r)
      }
    }
    v(0.3em)
    // a fixed number of lines, so the block keeps its height
    for c in commands + (" ",) * calc.max(0, 7 - commands.len()) {
      block(spacing: 0em, if c.starts-with("(gdb) ") {
        text(fill: rgb("7fb7c9"), weight: "bold")[(gdb)] + " " + text(weight: "bold", c.slice(6))
      } else { text(fill: luma(170), c) })
    }
  })
}

#let tui-commands = (
  "(gdb) break sum",
  "Breakpoint 1 at 0x1188: file lib.c, line 3.",
  "(gdb) run",
  "Starting program: /home/student/project/app",
  "Breakpoint 1, sum (n=10) at lib.c:3",
)

#slide[
  == `gdb` with a Text Interface
  `gdb -tui`: the code above, the commands below

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    - start it with `gdb -tui ./app`, or press #kbd("Ctrl") + #kbd("X") #kbd("A") in `gdb`
    - the *source window* follows the program
      - `B+` a breakpoint
      - `>` the next line to run
    - the *command window*: the same commands as before
  ][
    #only(1, gdb-tui(3, tui-commands))
    #only(2, gdb-tui(4, tui-commands + ("(gdb) next",)))
    #only("3-", gdb-tui(5, tui-commands + ("(gdb) next", "(gdb) next")))
  ]

  #v(1fr)
  #only(1)[💡 stopped at the breakpoint: the source window shows *where*]
  #only("2-")[💡 `next`: the `>` moves, no need to print the line in the command window]
]

// what -g adds to the executable, step by step:
// 1. gcc: only machine code, 2. gcc -g: + the debug information
#let debug-info-drawing(step) = drawing(width: 440pt, height: 140pt, {
  let g = step >= 2
  let y = 70pt
  // lib.c -> the compiler -> app
  pin(36pt, y, file-box([lib.c], sub: [the source], width: 66pt))
  line-arrow((72pt, y), (104pt, y), color: luma(120))
  pin(146pt, y, tool-box(if g [`gcc -g`] else [`gcc`], sub: [the compiler], width: 76pt, on: g))
  line-arrow((188pt, y), (222pt, y), color: luma(120))
  // app: the machine code, and with -g the debug information
  let (ax, aw) = (226pt, 214pt)
  place(top + left, dx: ax, dy: 4pt, box(width: aw, height: 132pt, radius: 0.5em, fill: white, stroke: 1pt + luma(120)))
  pin(ax + aw / 2, 14pt, text(size: 9pt, font: mono, weight: "bold")[app])
  // the machine code: one bar for each instruction, those of line 5 marked
  let (mx, mw) = (ax + 10pt, 84pt)
  place(top + left, dx: mx, dy: 26pt, box(width: mw, height: 104pt, radius: 0.3em, fill: luma(240)))
  pin(mx + mw / 2, 34pt, text(size: 7pt, fill: luma(90))[machine code])
  for k in range(10) {
    let on = g and k >= 6 and k <= 9
    place(top + left, dx: mx + 8pt, dy: 44pt + k * 8pt, box(width: mw - 16pt, height: 4.5pt, radius: 1pt, fill: if on { changed } else { luma(165) }))
  }
  // the debug information
  let (dx, dw) = (ax + 104pt, 100pt)
  if g {
    place(top + left, dx: dx, dy: 26pt, box(width: dw, height: 104pt, radius: 0.3em, fill: changed-fill, stroke: 1.5pt + changed))
    pin(dx + dw / 2, 36pt, text(size: 7.5pt, fill: changed, weight: "bold")[\+ debug information])
    let entry(y, body) = place(top + left, dx: dx + 6pt, dy: y, box(width: dw - 12pt, text(size: 7pt, body)))
    entry(52pt)[*lines*: line 5 of `lib.c` is #text(fill: changed)[these instructions]]
    entry(80pt)[*variables*: `s` is an `int`, on the stack]
    entry(104pt)[*functions*: `sum` starts here]
    // line 5 points to its instructions
    line-arrow((dx + 4pt, 66pt), (mx + mw - 6pt, 102pt), color: changed)
  } else {
    pin(dx + dw / 2, 82pt, text(size: 8pt, fill: luma(130), style: "italic")[no lines, \ no variable names])
  }
})

#slide[
  == Debug Information
  What the debugger needs, and `-g` adds

  #only(1, debug-info-drawing(1))
  #only("2-", debug-info-drawing(2))

  #v(1fr)
  #uncover("3-")[
    // a language and how to ask for the debug information
    #let lang(name, cmd) = box(inset: (x: 0.5em, y: 0.3em), radius: 0.3em, stroke: 0.8pt + accent, fill: rgb("eef3f5"))[*#name* #cmd]
    #set text(size: 0.8em)
    #align(center, stack(dir: ltr, spacing: 0.8em,
      lang[C][`gcc -g`], lang[Rust][`cargo build`], lang[Go][`go build`], lang[Java][`javac -g`],
    ))
  ]
  #only(1)[💡 without it, `app` is only machine code: the debugger cannot show lines or variables]
  #only(2)[💡 `-g` adds a map from the machine code back to the source]
  #only("3-")[💡 a _debug_ build adds it, a _release_ build usually does not]
]
