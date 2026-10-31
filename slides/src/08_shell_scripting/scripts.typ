#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Shell Scripts #text(size: 10pt, weight: "regular")[\ _Command lines, saved in a file_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.1 - _Shell Script Basics_
      - Section 11.14 - _When (Not) to Use Shell Scripts_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.1 - _Perspective pentru scripting_
      - Section 13.2 - _Dezvoltarea scripturilor_
]

#slide[
  == The Shell Runs Commands
  A programming language was added later, on top of it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - the shell was made to *run commands*: read a line, split it into words, run the command
    #uncover("2-")[#block[- a _shell script_ is a file with command lines, the shell runs them one after another]]
    #uncover("3-")[#block[- variables, conditions, loops and functions were added *on top* of this]]
    #uncover("4-")[#block[- so *everything* is still a command line: words, separated by spaces]]
  ][
    #set text(size: 0.75em)
    #label[you type the commands, one by one]
    ```terminal
    $ mkdir -p ~/backup
    $ cp ~/notes.txt ~/backup/
    $ echo "backup done"
    backup done
    ```
    #uncover("2-")[
      #label[or you save them in a file, `bash` runs them for you]
      ```bash
      #!/bin/bash
      mkdir -p ~/backup
      cp ~/notes.txt ~/backup/
      echo "backup done"
      ```
    ]
  ]

  // a card at the bottom of the slide: a colored mark on the left, a title
  #let card(color, title, body) = block(
    width: 100%,
    height: 100%,
    fill: color.lighten(92%),
    stroke: (left: 3pt + color),
    radius: (right: 0.3em),
    inset: (x: 0.6em, y: 0.45em),
  )[
    #text(size: 0.8em, weight: "bold", fill: color, title)
    #v(-0.3em)
    #set text(size: 0.8em)
    #align(center + horizon, body)
  ]

  #v(-0.2em)
  #block(height: 4.6em, grid(
    columns: (1.25fr, 1fr, 1fr),
    column-gutter: 0.8em,
    uncover("4-", card(accent)[🐚 ask: _what command runs here?_][
      #raw("[ $a -lt $b ]", lang: "bash") #h(0.3em) #draw-arrow(length: 1.5em) #h(0.3em)
      #words(("[", "cmd"), "2", "-lt", "3", "]")
    ]),
    uncover("5-", card(ok-color)[✅ great for _gluing commands_][
      #words(("mkdir", "cmd")) #draw-arrow(length: 1em) #words(("cp", "cmd")) #draw-arrow(length: 1em) #words(("echo", "cmd"))
    ]),
    uncover("5-", card(fail-color)[❌ bad for _heavy computation_][
      integers only, slow \
      #text(size: 0.9em)[use Python, C, Rust, ...]
    ]),
  ))
]

#slide[
  == Script Syntax
  A text file, one command line after another

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 1.15em)
    #highlight-code(("all", (1,), (2,), (3,), (4,), lines-range(5, 6), "all"))[```bash
#!/bin/bash
# backup.sh - back up the notes
mkdir -p ~/backup
cd ~/backup; ls
cp ~/notes.txt \
   ~/backup/
```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- `#!/bin/bash` - the _shebang_: the program that runs the file, for `bash` it is just a comment]]
    #uncover("3-")[#block[- `#` - a _comment_, until the end of the line]]
    #uncover("4-")[#block[- one command line on every line]]
    #uncover("5-")[#block[- `;` - several commands on the same line]]
    #uncover("6-")[#block[- `\` at the end - the command line goes on, on the next line]]
  ]
]

// ----- running a script: the command line, then what happens -----

// who does a step: the shell and bash in the theme color, the kernel in
// the kernel color of the diagrams

#let actor(name) = {
  let kernel = name == "kernel"
  box(
    width: 3.6em,
    fill: if kernel { rgb("ffe6cc") } else { accent },
    stroke: if kernel { 0.8pt + rgb("d79b00") } else { none },
    inset: (y: 0.25em),
    radius: 0.2em,
    align(center, text(size: 0.8em, weight: "bold", fill: if kernel { rgb("8a5a00") } else { white }, name)),
  )
}

// the permissions of a file, every set in the color of lecture 5;
// `x`: "check" - the `x` letters boxed, "skip" - crossed out, else plain

#let perms(x: none) = {
  let (u, g, o) = set-colors
  let xs(color) = if x == "check" {
    box(stroke: 0.8pt + changed.lighten(45%), fill: changed-fill, outset: (x: 1.5pt, y: 2.5pt), radius: 2pt, text(fill: color, weight: "bold")[x])
  } else if x == "skip" { text(fill: luma(170), strike[x]) } else { text(fill: color)[x] }
  text(font: mono)[#text(fill: luma(130))[-]#text(fill: u)[rw]#xs(u)#text(fill: g)[r-]#xs(g)#text(fill: o)[r-]#xs(o)]
}

// the `#!` of the first line, boxed

#let shebang-boxed = text(size: 0.8em)[#box(stroke: 1pt + changed.lighten(30%), fill: changed-fill, outset: (x: 1.5pt, y: 3pt), radius: 2pt, text(font: mono, fill: changed, weight: "bold")[\#!])#text(font: mono)[/bin/bash]]

// The command line on top, then, under it, the steps that run it, one
// per subslide: every step is a row (who - what), the row of the current
// step on an orange background. On the right, the script file and the
// output.
// `typed`: the command line (word chips)
// `rows`: one (actor, content) per step, the first one shows on step 2
// `file`: a function (step) -> (perms: none | "check" | "skip",
//         shebang: none | "read" | "comment", lines: highlighted lines)
// `out`: the step from which the output shows
// `extra`: (step, content) - shown instead of the output on that step

#let run-drawing(typed, rows, file, out, extra: none) = {
  let n = rows.len() + 1
  let lines = ("echo \"backing up\"", "mkdir -p ~/backup", "cp notes.txt ~/backup/", "echo \"done\"")
  let render(i) = {
    let f = file(i)
    grid(
      columns: (3fr, 2fr),
      column-gutter: 1.5em,
      {
        // the command line
        block(width: 100%, inset: 0.5em, radius: 0.3em, fill: if i == 1 { changed-fill } else { none }, below: 0pt, {
          label[you type] + h(0.6em) + text(size: 1.2em, typed)
        })
        // the steps, a small arrow down before each one (under the badges)
        let down(active) = block(above: 0pt, below: 0pt, inset: (left: 0.5em), box(width: 3.6em * 0.9, align(center,
          rotate(90deg, reflow: true, draw-arrow(length: 0.9em, color: if active { changed } else { luma(160) }, thickness: 1.2pt)))))
        for (k, (who, what)) in rows.enumerate() {
          let step = k + 2
          if i >= step { down(i == step) } else { hide(down(false)) }
          let body = block(width: 100%, inset: (x: 0.5em, y: 0.3em), radius: 0.3em, above: 0pt, below: 0pt,
            fill: if i == step { changed-fill } else { none },
            grid(columns: (auto, 1fr), column-gutter: 0.6em, align: horizon, actor(who), what))
          if i >= step { body } else { hide(body) }
        }
      },
      {
        debug-panel(raw("backup.sh"), {
          show raw.where(block: false): it => it.lines.join()
          block(width: 100%, above: 0pt, below: 0.4em, inset: (y: 0.3em), stroke: (bottom: 0.5pt + luma(200)),
            [#label[permissions] #h(0.4em) #perms(x: f.at("perms", default: none))])
          let first = f.at("shebang", default: none)
          block(width: 100%, above: 0pt, below: 0pt, inset: (x: 0.2em, y: 0.25em),
            fill: if first == "read" { changed-fill } else { none },
            if first == "read" { shebang-boxed + h(1fr) + text(size: 0.8em, fill: changed, weight: "bold")[the kernel reads it] } else if first == "comment" { text(fill: luma(170), raw("#!/bin/bash")) } else { raw("#!/bin/bash", lang: "bash") })
          for (k, l) in lines.enumerate() {
            block(width: 100%, above: 0pt, below: 0pt, inset: (x: 0.2em, y: 0.25em),
              fill: if k + 2 in f.at("lines", default: ()) { changed-fill } else { none },
              raw(l, lang: "bash"))
          }
        })
        let o = debug-panel([output], {
          set text(font: mono, size: 0.9em)
          text(fill: changed)[backing up]
          linebreak()
          text(fill: changed)[done]
        })
        if extra != none and i == extra.at(0) { extra.at(1) } else if i >= out { o } else { hide(o) }
      },
    )
  }
  for i in range(1, n + 1) {
    only(i, render(i))
  }
}

#slide[
  == Running a Script
  `./backup.sh` - what happens after you press #kbd("Enter")

  #set text(size: 0.9em)
  #run-drawing(
    words(("./backup.sh", "cmd")),
    (
      ("shell", [a *path* (it has a `/`): no `PATH` search, it asks the kernel to run the file]),
      ("kernel", [checks the permission: #perms(x: "check") - `x` is required]),
      ("kernel", [*reads the first line* of the file: #shebang-boxed - run it with `/bin/bash`]),
      ("kernel", [starts a new process: #words(("/bin/bash", "cmd"), ("./backup.sh", "new"))]),
      ("bash", [runs the file, line by line - `#!/bin/bash` is a comment for it]),
    ),
    i => (
      perms: if i == 3 { "check" } else { none },
      shebang: if i in (4, 5) { "read" } else if i == 6 { "comment" } else { none },
      lines: if i == 6 { (2, 3, 4, 5) } else { () },
    ),
    6,
    // what happens without `x`
    extra: (3, block(width: 100%, fill: fail-color.lighten(92%), stroke: (left: 3pt + fail-color), radius: (right: 0.3em), inset: 0.6em, {
      text(size: 0.85em, weight: "bold", fill: fail-color)[❌ without `x`, the kernel refuses]
      v(-0.2em)
      set text(size: 0.75em)
      terminal("$ chmod -x backup.sh\n$ ./backup.sh\nbash: ./backup.sh: Permission denied")
    })),
  )
]

#slide[
  == Running a Script With `bash`
  `bash backup.sh` - `bash` is the program, the script is a parameter

  #set text(size: 0.9em)
  #run-drawing(
    words(("bash", "cmd"), "backup.sh"),
    (
      ("shell", [a *name*: finds `/bin/bash` in `PATH`, asks the kernel to run it]),
      ("kernel", [checks the `x` of `/bin/bash`, *not* of `backup.sh`: `chmod +x` is not required]),
      ("kernel", [starts a new process: #words(("/bin/bash", "cmd"), "backup.sh") - the file is not opened by the kernel, `#!` is not read]),
      ("bash", [opens `backup.sh` and runs it, line by line - `#!/bin/bash` is just a comment]),
    ),
    i => (
      perms: if i >= 3 { "skip" } else { none },
      shebang: if i == 5 { "comment" } else { none },
      lines: if i == 5 { (2, 3, 4, 5) } else { () },
    ),
    5,
  )
]

// a script in another language: the file, how you run it, and what the
// kernel runs after reading `#!`
#let other-script(file, lang, code, kernel-runs) = {
  debug-panel(raw(file), {
    show raw.where(block: false): it => it.lines.join()
    let ls = code.split("\n")
    // the first line: `#!` boxed, like on the previous slides
    block(width: 100%, above: 0pt, below: 0pt, inset: (y: 0.2em), fill: changed-fill,
      text(size: 0.8em)[#box(stroke: 1pt + changed.lighten(30%), fill: white, outset: (x: 1.5pt, y: 3pt), radius: 2pt, text(font: mono, fill: changed, weight: "bold")[\#!])#text(font: mono)[#ls.at(0).slice(2)]])
    for l in ls.slice(1) {
      block(width: 100%, above: 0pt, below: 0pt, inset: (y: 0.2em), raw(l, lang: lang))
    }
  })
  v(0.3em)
  terminal("$ ./" + file + "\nHello, alice!")
  v(0.2em)
  label[the kernel runs]
  linebreak()
  kernel-runs
}

#slide[
  == The Shebang, for Any Language
  The kernel runs the program written after `#!`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 2em)[
    #set text(size: 0.85em)
    #other-script("hello.py", "python",
      "#!/usr/bin/python3\nname = \"alice\"\nprint(f\"Hello, {name}!\")",
      words(("/usr/bin/python3", "cmd"), ("./hello.py", "new")))
  ][
    #set text(size: 0.85em)
    #uncover("2-")[
      #other-script("hello.js", "js",
        "#!/usr/bin/env node\nconst name = \"alice\";\nconsole.log(`Hello, ${name}!`);",
        words(("/usr/bin/env", "cmd"), "node", ("./hello.js", "new")))
    ]
  ]

  #only(1)[💡 a Python script: after `chmod +x`, it runs like any program]
  #only(2)[💡 `/usr/bin/env node` - `env` searches `node` in `PATH`, useful when you do not know where it is installed]
  #only(3)[
    #takeaway[you do not need to know the language: every script runs the same way][
      #grid(
        columns: 3,
        column-gutter: 2.5em,
        align: center + horizon,
        ..(("./backup.sh", "bash"), ("./hello.py", "Python"), ("./hello.js", "JavaScript")).map(((f, l)) =>
          [#words((f, "cmd")) #h(0.3em) #label[#l]]),
      )
    ]
  ]
]

#let backup-code = "#!/bin/bash
echo \"backing up\"
mkdir -p ~/backup
cp notes.txt ~/backup/
echo \"done\""

#slide[
  == 🐞 A Script Runs Line by Line
  A file with command lines, the shell runs them one after another

  #debug-run(backup-code, command: "./backup.sh", (
    (line: 1, expand: "/bin/bash", run: "/bin/bash ./backup.sh", info: [started by the kernel],
      note: [💡 `#!` - the program that runs the script, for `bash` the line is a comment]),
    (line: 2, run: "echo \"backing up\"", status: 0, out: ("backing up",)),
    (line: 3, run: "mkdir -p /home/alice/backup", status: 0,
      note: [💡 the shell replaces `~` before running the command, like in the terminal]),
    (line: 4, run: "cp notes.txt /home/alice/backup/", status: 0),
    (line: 5, run: "echo \"done\"", status: 0, out: ("done",),
      note: [💡 no more lines: the script ends]),
  ))
]
