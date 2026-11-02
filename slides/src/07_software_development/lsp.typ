#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Language Servers #text(size: 10pt, weight: "regular")[\ _One program that understands a language, for every editor_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #lsp-spec
    - _Overview_
  + _clangd documentation_, #link("https://clangd.llvm.org")[online]
    - _Getting started_ (`compile_commands.json`)
]

// ----- m x n versus m + n -----

#let mn-drawing(with-lsp) = many-to-many(
  with-lsp,
  editors: ("vim", "emacs", "VS Code", "Zed", "helix"),
  chips: ("C", "Rust", "Python", "Go", "Java"),
  servers: (("clangd", "C"), ("rust-analyzer", "Rust"), ("pyright", "Python"), ("gopls", "Go"), ("jdtls", "Java")),
  protocol: "LSP",
  client: [LSP client],
  server: [LSP server],
  note: [a plugin for each language, in each editor],
  before: [*5 × 5 = 25* plugins, each one writes its own C parser, Rust parser, ...],
  after: [*5 + 5 = 10*: every editor and every server talk through the same interface],
)

#slide[
  == The Problem
  Every editor wants to understand every language

  #only(1, mn-drawing(false))
  #only("2-", mn-drawing(true))

  #v(1fr)
  #only(1)[💡 understanding C means: parse it, follow the `#include`s, know the types, ... a compiler front end]
  #only("2-")[
    #callout[the _Language Server Protocol_ (LSP, Microsoft, 2016): the editor asks, the *language server* answers]
  ]
]

// the editor starts the server, step by step:
// 1. only the editor, 2. it starts the server, 3. the two pipes
#let editor-server-processes(step) = drawing(width: 440pt, height: 80pt, {
  let (ex, sx, y) = (90pt, 350pt, 48pt)
  if step >= 2 {
    // the parent starts the child
    let starts = (paint: luma(120), thickness: 1pt, dash: "dashed")
    place(top + left, line(start: (ex, y - 17pt), end: (ex, 10pt), stroke: starts))
    place(top + left, line(start: (ex, 10pt), end: (sx, 10pt), stroke: starts))
    line-arrow((sx, 10pt), (sx, y - 18pt), color: luma(120))
    pin(220pt, 2pt, text(size: 8.5pt, fill: luma(90))[starts it (`fork` + `exec`): `clangd` is a *child process* of the editor])
  }
  if step >= 3 {
    // two pipes, one in each direction
    line-arrow((ex + 58pt, y - 6pt), (sx - 58pt, y - 6pt), color: accent, thickness: 1.5pt, head: 6pt)
    pin(220pt, y - 15pt, text(size: 8.5pt, fill: accent)[pipe to `stdin`: the code, questions])
    line-arrow((sx - 58pt, y + 6pt), (ex + 58pt, y + 6pt), color: changed, thickness: 1.5pt, head: 6pt)
    pin(220pt, y + 15pt, text(size: 8.5pt, fill: changed)[pipe from `stdout`: answers, errors])
  }
  pin(ex, y, tool-box([`hx`], sub: [the editor, the _parent_], width: 106pt))
  if step >= 2 {
    pin(sx, y, tool-box([`clangd`], sub: [the server, the _child_], width: 106pt, on: true))
  } else {
    pin(ex, 14pt, text(size: 10pt, fill: luma(60))[`$ hx main.c`])
  }
})

#slide[
  == What is a Language Server?
  A separate program that understands one language: a child process of the editor

  #only(1, editor-server-processes(1))
  #only(2, editor-server-processes(2))
  #only("3-", editor-server-processes(3))

  #set text(size: 0.9em)
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    === How it starts
    + you run `hx main.c`
    + #uncover("2-")[`hx` sees a C file and *starts* `clangd`]
    + #uncover("3-")[two *pipes* connect them]
    + #uncover("4-")[`hx` sends the code as you type, and *shows* the answers]
    + #uncover("4-")[`clangd` crashes? `hx` keeps working]
  ][
    #uncover("5-")[#block[
      === The server knows
      - *diagnostics*, while you type
      - *completion*, *hover*
      - *go to definition*, *references*
      - *rename*, *format*
    ]]
  ]
]

// a small editor showing main.c, step by step:
// 1. the file is open, 2. `totl` is underlined, 3-4. the cursor is on `sum`
#let lsp-editor(step) = {
  let code = "#include \"lib.h\"\n#include \"print.h\"\n\nint main(void)\n{\n    int total = sum(MAX);\n    print_result(\"sum\", totl);\n    return 0;\n}"
  // a block cursor on the `s` of `sum`, like in helix
  let cursor(it) = box(fill: accent, outset: (y: 1.5pt), text(fill: white, weight: "bold")[s]) + it.text.slice(1)
  // the line numbers, the cursor (line 6) and the error (line 7)
  show raw.line: it => {
    box(width: 1.5em, text(fill: luma(160))[#it.number])
    if it.number == 6 and step >= 3 {
      show "sum": cursor
      it.body
    } else if it.number == 7 and step == 2 {
      show "totl": underline.with(stroke: 1.5pt + bad-color, offset: 2pt)
      it.body
    } else { it.body }
  }
  block(width: 100%, stroke: 0.8pt + luma(160), radius: 0.3em, clip: true, {
    // the tab
    block(width: 100%, fill: luma(235), inset: (x: 0.5em, y: 0.3em), below: 0pt, text(size: 0.8em, font: mono)[main.c])
    // the code
    block(width: 100%, inset: (x: 0.4em, y: 0.4em), below: 0pt, raw(code, lang: "c", block: true))
    // the status line, with the position of the cursor
    block(width: 100%, fill: luma(235), inset: (x: 0.5em, y: 0.3em), text(size: 0.8em, font: mono, {
      [NOR]
      h(1fr)
      if step >= 3 { text(fill: accent, weight: "bold")[6:17] } else [1:1]
    }))
  })
}

#slide[
  == A Conversation with `clangd`
  Notifications and requests

  #let msg = protocol-msg.with(server: [`clangd`])

  #toolbox.side-by-side(columns: (5fr, 6fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #only(1, lsp-editor(1))
    #only(2, lsp-editor(2))
    #only("3-", lsp-editor(3))
    #only("3-")[#text(size: 0.9em, fill: accent)[the cursor: line 6, column 17 \ LSP counts from 0: `line 5`, `character 16`]]
  ][
    #only("1-2")[
      #text(size: 0.85em, weight: "bold", fill: luma(90))[Notifications: something happened, no answer]
      #msg(true, "notification", "textDocument/didOpen", (
        "uri:  file:///home/student/project/main.c",
        "text: \"#include \\\"lib.h\\\"\\n#include ...\"  (the whole file)",
      ))
      #uncover("2-", msg(false, "notification", "textDocument/publishDiagnostics", (
        "uri:     file:///home/student/project/main.c",
        "range:   line 6, characters 24 - 28",
        "message: \"Use of undeclared identifier 'totl';",
        "          did you mean 'total'?\"",
      )))
    ]
    #only("3-")[
      #text(size: 0.85em, weight: "bold", fill: accent)[Requests: a question and its answer, the same `id`]
      #msg(true, "request", "textDocument/hover", (
        "id:       2",
        "uri:      file:///home/student/project/main.c",
        "position: line 5, character 16",
      ))
      #uncover("4-", msg(false, "answer", "the answer to request 2", (
        "id: 2",
        "function sum -> int",
        "int sum(int n), provided by \"lib.h\"",
      )))
    ]
  ]

  #v(1fr)
  #only(1)[💡 the editor opened `main.c`: it sends the whole text (and `didChange` after every edit)]
  #only(2)[💡 when it finishes checking, the server sends the errors: the editor underlines `totl`]
  #only(3)[💡 the cursor is on `sum` and you press #kbd("Space") #kbd("k"): the editor asks what is there]
  #only("4-")[💡 the editor shows the answer in a popup]
]

#slide[
  == What You Get
  `clangd` in `helix` (built in) and in VSCodium (an extension)

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #only(1, screenshot("img/editors/helix_lsp.png", width: 100%))
    #only(2, screenshot("img/editors/helix_hover.png", width: 100%))
    #only(3, screenshot("img/editors/helix_complete.png", width: 100%))
    #only("4-", screenshot("img/gui/vscodium_lsp.png", width: 100%))
  ][
    #set text(size: 0.9em)
    #only(1)[
      === Diagnostics
      - the red dot: an error on line 7
      - the message and the fix, while you type, before compiling
    ]
    #only(2)[
      === Hover
      #kbd("Space") #kbd("k") on `sum`:
      - its type and parameters
      - the header it comes from
      - its comment from `lib.h`
    ]
    #only(3)[
      === Completion
      typing `print_r`:
      - the server knows `print_result` from `print.h`
      - with its parameters
    ]
    #only("4-")[
      === The same server
      - VSCodium with the `clangd` extension: the same hover, from the same `clangd`
      - the gray `n:` is an _inlay hint_: the name of the parameter
    ]
  ]
]

#slide[
  == Language Servers
  Install the server, the editor finds it in `PATH`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #table(
      columns: (auto, 1fr),
      inset: 0.4em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*language*], [*server*]),
      [C, C++], [`clangd`],
      [Rust], [`rust-analyzer`],
      [Python], [`pyright`, `basedpyright`, `pylsp`],
      [Go], [`gopls`],
      [Java], [`jdtls`],
      [JavaScript, TypeScript], [`typescript-language-server`],
      [`bash`], [`bash-language-server`],
      [Typst], [`tinymist`],
    )
  ][
    #uncover("2-")[
      ```terminal
      $ hx --health c
      Configured language servers:
        ✓ clangd: /usr/bin/clangd
      ```
    ]
    #uncover("3-")[#block[
      ⚠️ `clangd` needs the flags of the compiler (`-I`, `-D`, ...), from a `compile_commands.json` file:
    ]]
    #uncover("4-")[
      ```terminal
      $ bear -- make
      ```
      #text(size: 0.8em)[`bear` watches the build and writes `compile_commands.json`]
    ]
  ]
]
