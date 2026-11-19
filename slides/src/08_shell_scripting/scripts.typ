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
      - Section 11.12 - _Including Other Files in Scripts_
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
    - a _shell script_ is a file with command lines, the shell runs them one after another
    - variables, conditions, loops and functions came later, *on top*: everything is still a command line
    - ✅ great for _gluing commands_; ❌ bad for _heavy computation_ (use Python, C, Rust, ...)
  ][
    #set text(size: 0.85em)
    #label[you type the commands, one by one]
    ```terminal
    $ mkdir -p ~/backup
    $ cp ~/notes.txt ~/backup/
    $ echo "backup done"
    backup done
    ```
    #label[or you save them in a file, `bash` runs them for you]
    ```bash
    #!/bin/bash
    mkdir -p ~/backup
    cp ~/notes.txt ~/backup/
    echo "backup done"
    ```
  ]

  #v(0.2em)
  #shell-first[ask: _what command runs here?_ #h(0.5em) #raw("[ $a -lt $b ]", lang: "bash") #h(0.3em) #draw-arrow(length: 1.5em) #h(0.3em) #words(("[", "cmd"), "2", "-lt", "3", "]")]
]

#slide[
  == Script Syntax
  A text file, one command line after another

  #toolbox.side-by-side(columns: (11fr, 9fr), gutter: 1.5em)[
    #set text(size: 1.35em)
    #highlight-code(("all", (1,), (2,), (3,), (4,), lines-range(5, 6)))[```bash
#!/bin/bash
# back up the notes
mkdir -p ~/backup
cd ~/backup; ls
cp ~/notes.txt \
   ~/backup/
```]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[- `#!/bin/bash` - the _shebang_, the first line: the program that runs the script; `bash` itself skips it, like a comment]]
    #uncover("3-")[#block[- `#` - a _comment_: `bash` ignores the rest of the line]]
    #uncover("4-")[#block[- usually *one command per line*: `bash` runs it, waits for it to end, then reads the next line]]
    #uncover("5-")[#block[- `;` - puts *two commands on one line*: `cd ~/backup; ls` runs `cd`, then `ls`]]
    #uncover("6-")[#block[- `\` as the *last character* of a line - *one command on two lines*: `cp` gets both `~/notes.txt` and `~/backup/`]]
  ]
]

#slide[
  == Running a Script
  `./backup.sh` - what happens after you press #kbd("Enter")

  #set text(size: 0.9em)
  #run-drawing(
    words(("./backup.sh", "cmd")),
    (
      ("shell", [a *path* (it has a `/`): no `PATH` search, it asks the kernel to run the file]),
      ("kernel", [checks the `x` of *the user who runs it*: `alice` owns the file, so only the owner's `x` counts #perms(x: "check")]),
      ("kernel", [*reads the first line* of the file: #shebang-boxed - run it with `/bin/bash`]),
      ("kernel", [starts a new process: #words(("/bin/bash", "cmd"), ("./backup.sh", "new"))]),
      ("bash", [runs the file, line by line - `#!/bin/bash` is a comment for it]),
    ),
    i => (
      perms: if i == 3 { "check" } else { none },
      shebang: if i in (4, 5) { "read" } else if i == 6 { "comment" } else { none },
      lines: if i == 6 { (2, 3, 4) } else { () },
    ),
    6,
    // what happens without `x`
    extra: (3, block(width: 100%, fill: fail-color.lighten(92%), stroke: (left: 3pt + fail-color), radius: (right: 0.3em), inset: 0.6em, {
      text(size: 0.85em, weight: "bold", fill: fail-color)[❌ without the owner's `x`, the kernel refuses]
      v(-0.2em)
      set text(size: 0.75em)
      terminal("$ chmod u-x backup.sh\n$ ./backup.sh\nbash: ./backup.sh: Permission denied")
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
      lines: if i == 5 { (2, 3, 4) } else { () },
    ),
    5,
  )
]

#slide[
  == Running a Script With `source`
  `source backup.sh` - your shell runs the file itself, no new process

  #set text(size: 0.9em)
  #run-drawing(
    words(("source", "cmd"), "backup.sh"),
    (
      ("shell", [`source` is a *built-in* command: no new process, the kernel is not asked to run anything]),
      ("shell", [opens `backup.sh` and reads it: `r` is enough, `x` is not needed, `#!` is not read]),
      ("shell", [runs the lines *itself*, one by one, as if you typed them - `#!/bin/bash` is a comment]),
    ),
    i => (
      perms: if i >= 3 { "skip" } else { none },
      shebang: if i == 4 { "comment" } else { none },
      lines: if i == 4 { (2, 3, 4) } else { () },
    ),
    4,
  )
]

#let go-code = "#!/bin/bash
cd ~/backup
where=\"backup\""

#slide[
  == `bash` or `source`?
  Only `source` can change your shell

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 1.05em)
    #code-panel("go.sh", go-code)
    #v(0.3em)
    #set text(size: 0.8em)
    - `bash go.sh` - a *new* `bash` moves and sets `where`, then ends: your shell did not change
    #uncover("2-")[#block[- `source go.sh` - *your* shell runs the lines: it moves, and `where` stays]]
  ][
    #set text(size: 0.95em)
    #reveal-terminal(before: none, lines: (3, 6), full: false)[```terminal
    $ bash go.sh
    $ echo "$PWD [$where]"
    /home/alice []
    $ source go.sh
    $ echo "$PWD [$where]"
    /home/alice/backup [backup]
    ```]
  ]

  #v(0.3em)
  #uncover("2-")[
    #shell-first[`source` is how `bash` reads `~/.bashrc` when it starts: `source ~/.bashrc` applies your changes without a new terminal]
  ]
]

#slide[
  == Three Ways to Run a Script
  Two new processes, and your own shell

  // the three commands side by side: one column each, the `source` column
  // framed in the theme color (the odd one out); the row of what is kept
  // after the script ends in red (lost) / green (stays)
  #let lost = table.cell(fill: fail-color.lighten(90%))[❌ lost when it ends]
  #let side(body) = text(size: 0.85em, fill: luma(90), weight: "bold", body)
  #let needs(perm, rest) = align(center, stack(spacing: 0.9em, v(0.1em), perm, rest, v(0.1em)))
  #set text(size: 0.9em)
  #table(
    columns: (auto, 1fr, 1fr, 1fr),
    inset: (x: 0.6em, y: 0.5em),
    align: (left + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => (bottom: if y == 0 { 1pt + luma(150) } else { 0.5pt + luma(210) }),
    fill: (x, y) => if x == 3 and y > 0 { accent.lighten(94%) } else if y == 0 { luma(240) } else { none },
    table.header(
      [],
      words(("./go.sh", "cmd")),
      words(("bash", "cmd"), "go.sh"),
      [#words(("source", "cmd"), "go.sh") \ #label[or `. go.sh`]],
    ),
    side[who runs the lines],
    [#actor("bash") \ #label[a new process, started by the kernel]],
    [#actor("bash") \ #label[a new process]],
    [#actor("shell") \ #label[*your* shell, no new process]],
    side[the file needs],
    // the boxed `x` and `#!` are drawn with an outset: a stack with space
    // between the lines keeps them off the line above and the text around
    needs(perms(x: "check"), [and the #h(0.35em) #shebang-boxed]),
    needs(perms(x: "skip"), [only `r`]),
    needs(perms(x: "skip"), [only `r`]),
    side[its `cd` and variables],
    lost, lost,
    table.cell(fill: ok-color.lighten(85%))[✅ *stay* in your shell],
    side[use it for],
    [every script],
    [a script without `x`],
    [`~/.bashrc`, a file of functions],
  )

  #v(0.6em)
  #align(center, text(size: 1.3em, weight: "bold", fill: accent)[What does `exit` do in a file run with `source`?])
  // the answer, as a red popup on top of the table
  #only("2-")[
    #popup(width: 22em)[
      #text(size: 1.2em, weight: "bold", fill: fail-color)[⚠️ It ends your shell]
      #v(-0.3em)
      `exit` stops the shell that runs the lines: *yours* - the terminal closes \
      💡 a file meant for `source` does not call `exit`
    ]
  ]
]

// a script in another language: the file, how you run it, and what the
// kernel runs after reading `#!`
#let other-script(file, lang, code, kernel-runs) = {
  // the code larger than the text around it
  set text(size: 1.15em)
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
  set text(size: 0.8em)
  label[the kernel runs]
  linebreak()
  kernel-runs
}

#slide[
  == Shebangs for Any Language
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
mkdir -p ~/backup
cp ~/notes.txt ~/backup/
echo \"backup done\""

#slide[
  == 🐞 A Script Runs Line by Line
  A file with command lines, the shell runs them one after another

  #debug-run(backup-code, size: 1.35em, columns: (3fr, 2fr), command: "./backup.sh", blocks: true, (
    (line: 1, expand: "/bin/bash", run: "/bin/bash ./backup.sh", info: [started by the kernel],
      note: [💡 `#!` - the program that runs the script, for `bash` the line is a comment]),
    (line: 2, run: "mkdir -p /home/alice/backup", status: 0,
      note: [💡 the shell replaces `~` before running the command, like in the terminal]),
    (line: 3, run: "cp /home/alice/notes.txt /home/alice/backup/", status: 0),
    (line: 4, run: "echo \"backup done\"", status: 0, out: ("backup done",),
      note: [💡 no more lines: the script ends]),
  ))
]
