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
  + #dap-spec
  + _VSCodium / VS Code documentation_, _Tasks_, _Debugging_, #link("https://code.visualstudio.com/docs/debugtest/debugging")[online]
]

// what an IDE has built in, and the separate program an editor uses
// instead: (part of an IDE, what it does, program, example, how they talk)
#let ide-pieces = (
  ([code intelligence], [errors, completion], [language server], [`clangd`], [LSP]),
  ([debugger], [breakpoints, variables], [debug adapter], [`lldb-dap`], [DAP]),
  ([build], [compile, show the errors], [task], [`make`], [_runs it_]),
  ([version control], [changes, commits], [`git`], [the usual command], [_runs it_]),
)

#let pieces-drawing(upto) = drawing(width: 440pt, height: 150pt, {
  let (lx, rx) = (80pt, 360pt) // the IDE parts, the programs
  pin(lx, 6pt, text(size: 8pt, fill: luma(100), style: "italic")[built into an IDE])
  pin(rx, 6pt, text(size: 8pt, fill: luma(100), style: "italic")[in an editor: a separate program])
  for (i, (part, what, prog, ex, proto)) in ide-pieces.enumerate() {
    let y = 30pt + i * 35pt
    pin(lx, y, tool-box(part, sub: what, fill: white, stroke: luma(120), width: 140pt))
    if i < upto {
      let on = i == upto - 1
      line-arrow((lx + 74pt, y), (rx - 74pt, y), color: if on { changed } else { accent }, thickness: 1.2pt)
      pin(220pt, y - 7pt, text(size: 7.5pt, fill: if on { changed } else { accent }, weight: "bold", proto))
      pin(rx, y, tool-box(prog, sub: ex, on: on, width: 140pt))
    }
  }
})

#slide[
  == Editor + Plugins = IDE
  Every part of an IDE is a separate program, the editor only shows the results

  #for i in range(1, ide-pieces.len() + 1) {
    only(if i == ide-pieces.len() { str(i) + "-" } else { i }, pieces-drawing(i))
  }

  #v(1fr)
  #only(1)[💡 the *language server* understands the code, the editor asks it through LSP]
  #only(2)[💡 the *debug adapter* drives the debugger, the editor asks it through DAP]
  #only(3)[💡 a *task* runs the build, the editor reads the errors from its output]
  #only("4-")[💡 the editor runs `git` and shows the changes next to the code]
]

#let tasks-json = "{
  \"version\": \"2.0.0\",
  \"tasks\": [{
    \"label\": \"make\",
    \"type\": \"shell\",
    \"command\": \"make\",
    \"problemMatcher\": [\"$gcc\"]
  }]
}"

#let launch-json = "{
  \"version\": \"0.2.0\",
  \"configurations\": [{
    \"type\": \"lldb\",
    \"request\": \"launch\",
    \"name\": \"Debug app\",
    \"program\": \"${workspaceFolder}/app\",
    \"preLaunchTask\": \"make\"
  }]
}"

// a JSON file, with the lines that contain `mark` framed in orange
#let json-file(name, src, mark: none) = {
  show raw.line: it => if mark != none and it.text.contains(mark) {
    box(fill: changed-fill, stroke: 1pt + changed, outset: (x: 2pt, y: 1.5pt), radius: 2pt, it)
  } else { it }
  text(size: 0.9em, fill: luma(110), raw(name))
  raw(src, lang: "json", block: true)
}

// a piece of JSON in a small orange frame, for the link at the bottom
#let json-chip(src) = box(fill: changed-fill, stroke: 1pt + changed, inset: (x: 0.5em, y: 0.35em), radius: 0.3em, raw(src, lang: "json"))

#slide[
  == Configure the Project
  Two files tell the editor how to build and how to debug

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === Build: a _task_
    #set text(size: 0.72em)
    #only(1, json-file(".vscode/tasks.json", tasks-json))
    #only("2-", json-file(".vscode/tasks.json", tasks-json, mark: "\"label\""))
  ][
    #uncover("2-")[#block[
      === Debug: a _launch configuration_
      #set text(size: 0.72em)
      #json-file(".vscode/launch.json", launch-json, mark: "\"preLaunchTask\"")
    ]]
  ]

  #v(1fr)
  #uncover("2-")[
    #set text(size: 0.8em)
    #align(center, flow(
      [`launch.json`: #json-chip("\"preLaunchTask\": \"make\"")],
      ([runs the task], [#json-chip("\"label\": \"make\""): `tasks.json`]),
      length: 3em,
    ))
  ]
  #v(0.3em)
  #only(1)[💡 a task has a name, its `label`; `problemMatcher`: the editor reads the `gcc` errors]
  #only(2)[💡 #kbd("F5"): first the `make` task builds `app`, then the debugger starts it]
  #only("3-")[💡 `launch.json` is not only for VSCodium]

  // a popup: the editors that read .vscode/launch.json
  #only("3-")[#place(center + horizon, block(
    width: 70%,
    fill: white,
    stroke: 2pt + changed,
    radius: 0.6em,
    inset: (x: 1.1em, y: 0.9em),
    {
      set align(left)
      text(weight: "bold", fill: changed)[📂 `.vscode/launch.json` is read by]
      v(0.2em)
      set text(size: 0.9em)
      table(
        columns: (auto, 1fr),
        align: left + horizon,
        inset: (x: 0.4em, y: 0.4em),
        stroke: (x, y) => (bottom: 0.4pt + luma(220)),
        [*VS Code, VSCodium*], [its own file],
        [*Zed*], [if there is no `.zed/debug.json`],
        [*`neovim`* + `nvim-dap`], [the configurations, but not `preLaunchTask`: run `make` yourself first],
      )
    },
  ))]
]

// the project folder, with the folders of two editors: (indent, name, note, editor folder?)
#let project-tree = (
  (0, "project/", none, false),
  (1, ".vscode/", [VSCodium], true),
  (2, "tasks.json", [build], true),
  (2, "launch.json", [debug], true),
  (1, ".zed/", [Zed], true),
  (2, "debug.json", [debug], true),
  (1, "Makefile", none, false),
  (1, "main.c  lib.c  lib.h  ...", none, false),
)

#slide[
  == Editor Settings in the Project
  The settings of one editor, saved inside the project
  #counter(footnote).update(0)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - a *hidden* folder: its name starts with `.`
    - in the root folder of the project
    - only for *this* project and *this* editor
    #v(0.3em)
    #table(
      columns: (auto, 1fr),
      inset: 0.4em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*editor*], [*folder*]),
      [VS Code, VSCodium], [`.vscode/`],
      [Zed], [`.zed/`],
      [`helix`], [`.helix/`],
      [JetBrains IDEs], [`.idea/`],
      [`vim`, `neovim`], [a file: `.exrc`, `.nvim.lua`#footnote[read only if the `exrc` option is on; `neovim` asks first if you trust the file. `nvim-dap` can also read `.vscode/launch.json`]],
    )
  ][
    #block(width: 100%, fill: luma(246), radius: 0.4em, inset: 0.8em, {
      set text(size: 0.8em)
      for (level, name, note, on) in project-tree {
        block(spacing: 0.55em, {
          h(level * 1.2em)
          text(font: mono, fill: if on { changed } else { black }, weight: if name.ends-with("/") { "bold" } else { "regular" }, name)
          if note != none { h(0.6em); text(size: 0.85em, fill: luma(120), style: "italic", note) }
        })
      }
    })
    💡 commit it with `git`: the same build and debug setup for everyone
  ]
]

#slide[
  == LSP and DAP in Editors
  Most editors speak both protocols

  #v(0.3em)
  #align(center, block(width: 100%, {
    set text(size: 0.9em)
    table(
      columns: (auto, 1fr, 1fr),
      align: (left + horizon, center + horizon, center + horizon),
      inset: (x: 0.6em, y: 0.38em),
      stroke: none,
      fill: (x, y) => if y == 0 { accent } else if calc.odd(y) { luma(246) } else { white },
      table.header(
        text(fill: white)[*editor*],
        text(fill: white)[*language servers (LSP)*],
        text(fill: white)[*debug adapters (DAP)*],
      ),
      [VS Code / VSCodium], [an extension per language], [an extension per debugger],
      [Zed], [built in], [built in],
      [`helix`], [built in], [built in, experimental],
      [`neovim`], [built in], [plugin: `nvim-dap`],
      [`emacs`], [built in: `eglot`], [package: `dape`],
      [`vim`], [plugin: `vim-lsp`], [plugin: `vimspector`],
      table.hline(stroke: 0.8pt + luma(200)),
    )
  }))

  #v(1fr)
  #only(1)[💡 _built in_: the editor speaks the protocol, you only install the server or the adapter]
  #only("2-")[
    #callout[install `clangd` and `lldb-dap` once, then use them from *any* editor you like]
  ]
]
