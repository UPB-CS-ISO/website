#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = From an Editor to an IDE #text(size: 10pt, weight: "regular")[\ _Language servers + debug adapters_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #lsp-spec
  + _Debug Adapter Protocol_, #link("https://microsoft.github.io/debug-adapter-protocol/")[online]
  + _VSCodium / VS Code documentation_, _Debugging_, _Tasks_, #link("https://code.visualstudio.com/docs/debugtest/debugging")[online]
]

#slide[
  == Debug Adapter Protocol
  The same idea as LSP, for debuggers

  #align(center)[
    #grid(
      columns: 5,
      column-gutter: 0.6em,
      align: center + horizon,
      tool-box([editor], sub: [the DAP _client_], width: 90pt),
      stack(spacing: 0.2em, arrow-label[DAP (JSON)], draw-arrow(length: 4em, color: accent)),
      tool-box([debug adapter], sub: [CodeLLDB, `lldb-dap`, ...], width: 100pt, on: true),
      stack(spacing: 0.2em, arrow-label[controls], draw-arrow(length: 3em)),
      tool-box([debugger], sub: [`lldb`, `gdb`], width: 80pt),
    )
  ]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("2-")[#block[
      - _DAP_, Microsoft, 2016, like LSP
      - the editor says: _set a breakpoint at `lib.c:5`_, _step_, _what are the variables?_
      - the *adapter* translates to the commands of the real debugger
    ]]
  ][
    #uncover("3-")[
      #set text(size: 0.85em)
      #table(
        columns: (auto, 1fr),
        inset: 0.35em,
        stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
        table.header([*language*], [*debug adapter*]),
        [C, C++, Rust], [CodeLLDB, `lldb-dap`, `gdb -i=dap`],
        [Python], [`debugpy`],
        [Go], [`dlv dap` (Delve)],
        [JavaScript], [`js-debug`],
      )
    ]
  ]
]

// the parts of an editor that make it an IDE: (x, y, name, what, protocol)
#let ide-plugins = (
  (75pt, 40pt, [language server], [`clangd`], [LSP]),
  (375pt, 40pt, [debug adapter], [CodeLLDB #arrow `lldb`], [DAP]),
  (75pt, 140pt, [build task], [`make`], [_task_]),
  (375pt, 140pt, [terminal], [`bash`], [_pty_]),
)

#let editor-ide(upto) = drawing(width: 450pt, height: 180pt, {
  let mid = (225pt, 90pt)
  for (i, (x, y, name, what, proto)) in ide-plugins.enumerate() {
    if i < upto {
      wire(mid, (x, y), stroke: 1.2pt + accent)
      let (mx, my) = ((mid.at(0) + x) / 2, (mid.at(1) + y) / 2)
      pin(mx, my, box(fill: white, inset: 2pt, text(size: 7.5pt, fill: accent, weight: "bold", proto)))
    }
  }
  pin(..mid, box(
    width: 105pt,
    inset: 0.7em,
    radius: 0.5em,
    fill: accent,
    align(center, text(fill: white, weight: "bold")[text editor\ #text(size: 7pt, weight: "regular")[VSCodium, Zed, helix, nvim]]),
  ))
  for (i, (x, y, name, what, proto)) in ide-plugins.enumerate() {
    if i < upto {
      pin(x, y, tool-box(name, sub: what, on: i == upto - 1, fill: white, width: 120pt))
    }
  }
})

#slide[
  == Editor + Plugins = IDE

  #for i in range(1, ide-plugins.len() + 1) {
    only(if i == ide-plugins.len() { str(i) + "-" } else { i }, editor-ide(i))
  }

  #v(1fr)
  #only(1)[💡 the *language server* understands the code: errors, completion, go to definition]
  #only(2)[💡 the *debug adapter* drives the debugger: breakpoints, variables, call stack]
  #only(3)[💡 a *task* runs the build, the editor reads the errors from its output]
  #only("4-")[💡 every part is a separate program, the editor only shows the results: an IDE made of pieces]
]

#slide[
  == VSCodium as a C IDE
  `clangd` + CodeLLDB extensions, `make` as a task

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #screenshot("img/gui/vscodium_debug.png", height: 5.2cm)
    #text(size: 0.7em)[stopped at the breakpoint on line 5 of `lib.c`: the variables `n`, `s`, `i` and the call stack `sum` #arrow `main`]
  ][
    #set text(size: 0.62em)
    #only(1)[
      `.vscode/tasks.json`
      ```json
      {
        "version": "2.0.0",
        "tasks": [{
          "label": "make",
          "type": "shell",
          "command": "make",
          "problemMatcher": ["$gcc"]
        }]
      }
      ```
    ]
    #only("2-")[
      `.vscode/launch.json`
      ```json
      {
        "version": "0.2.0",
        "configurations": [{
          "type": "lldb",
          "request": "launch",
          "name": "Debug app",
          "program": "${workspaceFolder}/app",
          "preLaunchTask": "make"
        }]
      }
      ```
    ]
  ]
]

#slide[
  == LSP and DAP in Editors

  #set text(size: 0.9em)
  #align(center)[
    #table(
      columns: (auto, 1fr, 1fr),
      align: (left + horizon, center + horizon, center + horizon),
      inset: 0.45em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*editor*], [*language servers (LSP)*], [*debuggers (DAP)*]),
      [VS Code / VSCodium], [an extension per language], [an extension per debugger],
      [Zed], [built in], [built in],
      [`helix`], [built in], [built in, experimental],
      [`neovim`], [built in (`vim.lsp`)], [plugin: `nvim-dap`],
      [`emacs`], [built in (`eglot`)], [package: `dape`],
      [`vim`], [plugin: `vim-lsp`, `coc.nvim`], [plugin: `vimspector`],
    )
  ]

  #uncover("2-")[
    ```terminal
    $ hx --health c
    Configured language servers:
      ✓ clangd: /usr/bin/clangd
    Configured debug adapter:
      ✘ 'lldb-dap' not found in $PATH
    ```
  ]
]
