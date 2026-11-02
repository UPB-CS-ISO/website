#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Debug Adapters #text(size: 10pt, weight: "regular")[\ _One program that drives a debugger, for every editor_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #dap-spec
    - _Overview_
  + _Debugging with GDB_, #link("https://sourceware.org/gdb/current/onlinedocs/gdb")[online]
    - _Debugger Adapter Protocol_
]

// ----- m x n versus m + n -----

#let mn-drawing(with-dap) = many-to-many(
  with-dap,
  editors: ("vim", "emacs", "VS Code", "Zed", "helix"),
  chips: ("gdb", "lldb", "Python", "Go", "JS"),
  servers: (
    ([`gdb -i=dap`], "gdb"),
    ("lldb-dap", "lldb"),
    ("debugpy", "Python"),
    ("dlv dap", "Go"),
    ("js-debug", "JavaScript"),
  ),
  protocol: "DAP",
  client: [DAP client],
  server: [debug adapter],
  note: [a plugin for each debugger, in each editor],
  before: [*5 × 5 = 25* plugins, each one drives `gdb`, `lldb`, ... in its own way],
  after: [*5 + 5 = 10*: every editor and every debugger talk through the same interface],
)

#slide[
  == The Same Problem
  Every editor wants to drive every debugger

  #only(1, mn-drawing(false))
  #only("2-", mn-drawing(true))

  #v(1fr)
  #only(1)[💡 every debugger has its own commands: `break` in `gdb`, `breakpoint set` in `lldb`]
  #only("2-")[
    #callout[the _Debug Adapter Protocol_ (DAP, Microsoft, 2016): the editor asks, the *debug adapter* answers]
  ]
]

// the editor starts the adapter, the adapter starts the program, step by step:
// 1. only the editor, 2. it starts the adapter, 3. the two pipes,
// 4. the adapter starts the program and controls it
#let editor-adapter-processes(step) = drawing(width: 440pt, height: 92pt, {
  let (ex, ax, px, y) = (60pt, 225pt, 385pt, 44pt)
  let starts = (paint: luma(120), thickness: 1pt, dash: "dashed")
  if step >= 2 {
    // the editor starts the adapter (above)
    place(top + left, line(start: (ex, y - 17pt), end: (ex, 8pt), stroke: starts))
    place(top + left, line(start: (ex, 8pt), end: (ax, 8pt), stroke: starts))
    line-arrow((ax, 8pt), (ax, y - 18pt), color: luma(120))
    pin((ex + ax) / 2, 0pt, text(size: 8pt, fill: luma(90))[starts it: a *child* of the editor])
  }
  if step >= 3 {
    // two pipes, one in each direction
    line-arrow((ex + 48pt, y - 6pt), (ax - 48pt, y - 6pt), color: accent, thickness: 1.5pt, head: 6pt)
    pin((ex + ax) / 2, y - 14pt, text(size: 7.5pt, fill: accent)[requests])
    line-arrow((ax - 48pt, y + 6pt), (ex + 48pt, y + 6pt), color: changed, thickness: 1.5pt, head: 6pt)
    pin((ex + ax) / 2, y + 14pt, text(size: 7.5pt, fill: changed)[answers, events])
  }
  if step >= 4 {
    // the adapter starts the program (below) and controls it
    place(top + left, line(start: (ax, y + 17pt), end: (ax, 84pt), stroke: starts))
    place(top + left, line(start: (ax, 84pt), end: (px, 84pt), stroke: starts))
    line-arrow((px, 84pt), (px, y + 18pt), color: luma(120))
    pin((ax + px) / 2, 91pt, text(size: 8pt, fill: luma(90))[starts it: a *child* of the adapter])
    line-arrow((ax + 48pt, y), (px - 40pt, y), color: accent, thickness: 1.5pt, head: 6pt)
    pin((ax + px) / 2 - 4pt, y - 9pt, text(size: 7.5pt, fill: accent)[`ptrace`])
  }
  pin(ex, y, tool-box([editor], sub: [VSCodium, Zed, `hx`], width: 96pt))
  if step >= 2 {
    pin(ax, y, tool-box([`lldb-dap`], sub: [adapter + debugger], width: 96pt, on: step == 2 or step == 3))
  } else {
    pin(ex, 10pt, text(size: 9pt, fill: luma(60))[#kbd("F5"): start debugging])
  }
  if step >= 4 {
    pin(px, y, file-box([app], sub: [the program], width: 80pt, on: true))
  }
})

#slide[
  == What is a Debug Adapter?
  A program that speaks DAP and drives a debugger: a child process of the editor

  #only(1, editor-adapter-processes(1))
  #only(2, editor-adapter-processes(2))
  #only(3, editor-adapter-processes(3))
  #only("4-", editor-adapter-processes(4))

  #set text(size: 0.9em)
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    === How it starts
    + you start debugging in the editor
    + #uncover("2-")[the editor *starts* the adapter, e.g. `lldb-dap`]
    + #uncover("3-")[two *pipes* connect them, as for LSP]
    + #uncover("4-")[the adapter *starts* `app` and controls it with `ptrace`]
  ][
    #uncover("5-")[#block[
      === The adapter knows
      - *breakpoints*
      - *continue*, *step*
      - the *call stack*
      - the *variables*
      - *evaluate* an expression
    ]]
  ]
]

// a small editor showing lib.c, step by step:
// 1. a breakpoint is asked for, 2. it is set (red dot),
// 3-4. the program stopped on line 5, 5. the variables are shown
#let dap-editor(step) = {
  let code = "int sum(int n)\n{\n    int s = 0;\n    for (int i = 1; i <= n; i++) {\n        s = s + i;\n    }\n    return s;\n}"
  // the gutter: line numbers and the breakpoint on line 5
  show raw.line: it => {
    box(width: 0.9em, if it.number == 5 {
      box(baseline: -0.1em, circle(
        radius: 0.27em,
        fill: if step >= 2 { bad-color } else { none },
        stroke: 0.8pt + if step >= 2 { bad-color } else { luma(150) },
      ))
    })
    box(width: 1.3em, text(fill: luma(160))[#it.number])
    if it.number == 5 and step >= 3 {
      box(fill: rgb("fff3c4"), outset: (x: 2pt, y: 2pt), it.body)
    } else { it.body }
  }
  block(width: 100%, stroke: 0.8pt + luma(160), radius: 0.3em, clip: true, {
    // the tab
    block(width: 100%, fill: luma(235), inset: (x: 0.5em, y: 0.3em), below: 0pt, text(size: 0.8em, font: mono)[lib.c])
    // the code
    block(width: 100%, inset: (x: 0.4em, y: 0.4em), below: 0pt, raw(code, lang: "c", block: true))
    // the status line: what the program does
    block(width: 100%, fill: luma(235), inset: (x: 0.5em, y: 0.3em), text(size: 0.8em, font: mono, {
      [app: ]
      if step >= 3 { text(fill: accent, weight: "bold")[paused] } else [running]
    }))
  })
}

#slide[
  == A Conversation with `lldb-dap`
  Requests, responses and events

  #let msg = protocol-msg.with(server: [adapter])

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    #only(1, dap-editor(1))
    #only(2, dap-editor(2))
    #only("3-4", dap-editor(3))
    #only("5-", dap-editor(5))
    #uncover("5-")[#text(size: 0.9em, fill: accent)[*Variables*: `n = 10`, `s = 0`, `i = 1`]]
  ][
    #only("1-2")[
      #text(size: 0.85em, weight: "bold", fill: accent)[Requests: a question and its answer, the same `seq`]
      #msg(true, "request", "setBreakpoints", (
        "seq:         3",
        "source:      /home/student/project/lib.c",
        "breakpoints: [ line 5 ]",
      ))
      #uncover("2-", msg(false, "response", "the answer to request 3", (
        "request_seq: 3",
        "success:     true",
        "breakpoints: [ line 5, verified ]",
      )))
    ]
    #only(3)[
      #text(size: 0.85em, weight: "bold", fill: luma(90))[Events: something happened, no answer]
      #msg(false, "event", "stopped", (
        "reason:   breakpoint",
        "threadId: 1",
      ))
    ]
    #only("4-")[
      #text(size: 0.85em, weight: "bold", fill: accent)[Requests: a question and its answer, the same `seq`]
      #msg(true, "request", "variables", (
        "seq:                9",
        "variablesReference: 1001",
      ))
      #uncover("5-", msg(false, "response", "the answer to request 9", (
        "request_seq: 9",
        "variables:   n = 10   (int)",
        "             s = 0    (int)",
        "             i = 1    (int)",
      )))
    ]
  ]

  #v(1fr)
  #only(1)[💡 you click next to line 5: the editor asks for a breakpoint (DAP counts lines from 1)]
  #only(2)[💡 the adapter set it in `lldb`: the breakpoint is _verified_, the dot turns red]
  #only(3)[💡 `app` reached line 5: the adapter tells the editor, which highlights the line]
  #only(4)[💡 the editor asks for the local variables of `sum` (`1001` came from earlier requests)]
  #only("5-")[💡 the editor shows them in the _Variables_ panel]
]

// the parts of vscodium_debug.png (1600 x 1000 pixels) that each step frames
#let vscodium-marks = (
  ((346, 170, 26, 24), (48, 912, 300, 24)), // the breakpoint: the dot, the list
  ((418, 170, 1050, 24), (48, 652, 300, 90)), // stopped: the line, the call stack
  ((48, 92, 300, 88),), // the variables
  ((705, 36, 192, 30),), // the buttons
)

#let vscodium-debug(step) = marked-screenshot(
  "img/gui/vscodium_debug.png",
  size: (1600, 1000),
  marks: vscodium-marks.at(step - 1),
  width: 100%,
)

#slide[
  == What You Get
  `lldb` in VSCodium (CodeLLDB) and in `nvim` (`nvim-dap`)

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #for i in range(1, vscodium-marks.len() + 1) {
      only(i, vscodium-debug(i))
    }
    // nvim_dap.png (1716 x 904 pixels): the breakpoint and the stopped line,
    // the call stack, the variables, the buttons
    #only("5-", marked-screenshot(
      "img/editors/nvim_dap.png",
      size: (1716, 904),
      marks: ((576, 118, 1138, 32), (0, 150, 568, 142), (0, 372, 568, 116), (592, 650, 336, 34)),
      width: 100%,
    ))
  ][
    #set text(size: 0.9em)
    #only(1)[
      === Breakpoints
      - click next to a line: `setBreakpoints`
      - the red dot on line 5, the list at the bottom left
    ]
    #only(2)[
      === Stopped
      - the `stopped` event: line 5 is highlighted
      - `stackTrace`: the _Call Stack_, `sum` called by `main`
    ]
    #only(3)[
      === Variables
      - `scopes` + `variables`: the _Variables_ panel
      - `n`, `s`, `i` of `sum`, here in the 3#super[rd] iteration
    ]
    #only(4)[
      === Buttons
      - the toolbar at the top: continue, step over, step into, step out, restart, stop
      - one DAP request for each button
    ]
    #only("5-")[
      === The same protocol, in a terminal
      - `nvim` + the `nvim-dap` plugin + `lldb-dap`
      - the same answers: the breakpoint, the stopped line, the call stack, the variables, the buttons
    ]
  ]
]

#slide[
  == Debug Adapters
  Install the adapter, the editor starts it
  #counter(footnote).update(0)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #table(
      columns: (auto, 1fr),
      inset: 0.4em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*language*], [*debug adapter*]),
      [C, C++, Rust], [`lldb-dap`, CodeLLDB, `gdb -i=dap`#footnote[`gdb` speaks DAP itself since version 14: `-i=dap` (_interpreter_) replaces its command line with DAP]],
      [Python], [`debugpy`],
      [Go], [`dlv dap` (Delve)],
      [JavaScript, TypeScript], [`js-debug`],
    )
  ][
    ⚠️ the adapter needs the *debug information*: compile with `-g`
    ```terminal
    $ gcc -g main.c lib.c print.c -o app
    ```
    ⚠️ the editor must know *what* to start: the path of `app`, its arguments, ... a _launch configuration_
  ]
]
