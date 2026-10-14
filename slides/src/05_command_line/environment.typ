#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Environment Variables #text(size: 10pt, weight: "regular")[\ _Settings that every process inherits_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.8 - _Environment and Shell Variables_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.2.3 - _Variabile shell_
]

// The variables of a process, drawn like the File Descriptor Table of
// lecture 3. Every row is (name, value, style), where style is
// "env" - an environment variable,
// "new" - an environment variable that was just added or changed (orange),
// "shell" - a shell variable, not exported: children do not get it (dashed, gray),
// "hidden" - keeps the space of the row, without drawing it
#let env-table(name, rows, title: none, width: auto) = {
  set text(size: 0.75em)
  let cell(style, body) = {
    let fill = if style == "new" { changed } else if style == "shell" { luma(150) } else { black }
    let content = text(
      font: mono,
      fill: fill,
      weight: if style == "new" { "bold" } else { "regular" },
      style: if style == "shell" { "italic" } else { "normal" },
      body,
    )
    if style == "hidden" { hide(content) } else { content }
  }
  box(width: width, table(
    columns: (auto, 1fr),
    align: left,
    inset: (x: 0.5em, y: 0.3em),
    stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
    fill: (x, y) => if y == 0 { luma(235) } else { white },
    table.header(table.cell(colspan: 2, if title != none { title } else [variables of #text(font: mono, name)])),
    ..rows
      .map(((n, v, style)) => (
        cell(style, n),
        cell(style, v + if style == "shell" { "   (shell only)" } else { "" }),
      ))
      .flatten(),
  ))
}

#let alice-env = (
  ("HOME", "/home/alice", "env"),
  ("USER", "alice", "env"),
  ("SHELL", "/bin/bash", "env"),
  ("PATH", "/usr/local/bin:/usr/bin:/bin", "env"),
  ("LANG", "en_US.UTF-8", "env"),
  ("PWD", "/home/alice/Movies", "env"),
)

#slide[
  == Environment Variables
  ```bash NAME=value``` texts that are part of every process

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - every process has a list of ```bash NAME=value``` texts, its _environment_
    #uncover("2-")[#block[- a process *receives* it from its parent: `fork` copies it, `exec` keeps it]]
    #uncover("3-")[#block[- programs read it to configure themselves: ```c getenv("HOME")``` in C, ```bash $HOME``` in `bash`]]
    #uncover("4-")[#block[- the names are written in *UPPER CASE*, by convention]]
  ][
    #env-table("bash", alice-env, width: 100%)

    #uncover("5-")[
      #set text(size: 0.8em)
      ```terminal
      $ printenv HOME    # one variable
      /home/alice
      $ echo "I am $USER" # the shell expands $USER
      I am alice
      $ env              # all the variables
      ```
    ]
  ]
]

#let inherit(child-rows, parent-rows: alice-env.slice(0, 4), arrow: true) = grid(
  columns: (1fr, auto, 1fr),
  column-gutter: 1em,
  align: (center + horizon),
  env-table("bash", parent-rows, width: 100%),
  {
    let a = align(center)[
      #text(size: 0.75em, font: mono)[fork + exec] \
      #draw-arrow(length: 3em, color: changed)
    ]
    // hidden, not left out, so the tables do not shift when it shows up
    if arrow { a } else { hide(a) }
  },
  env-table("sort", child-rows, width: 100%),
)

#slide[
  == Inherited by the Children
  Every process starts with a *copy* of the environment of its parent

  #only(1)[#inherit(alice-env.slice(0, 4).map(((n, v, s)) => (n, v, "hidden")), arrow: false)]
  #only(2)[#inherit(alice-env.slice(0, 4).map(((n, v, s)) => (n, v, "new")))]
  #only("3-")[#inherit((
    ("HOME", "/home/alice", "env"),
    ("USER", "alice", "env"),
    ("SHELL", "/bin/bash", "env"),
    ("PATH", "/tmp", "new"),
  ))]

  #v(1em)
  #set text(size: 0.9em)
  #only(1)[💡 `bash` has its own environment, like every process]
  #only(2)[💡 the shell starts `sort`: the child gets a *copy* of all the environment variables]
  #only("3-")[
    The child process can change *its own copy* using ```c setenv("PATH", "/tmp")``` or ```bash PATH=/tmp```, the parent does not see the change

    💡 a process can only pass variables *down* to its children, never *up* to its parent
  ]
]

// What `bash -c 'echo "child: $GREETING"'` does, drawn for the steps of
// the `export` slide: your shell (with its variables) starts a new bash,
// which gets a copy of the *environment* and runs the text after `-c`.
// Every part keeps its space on every step, so nothing shifts.
#let bash-c-schematic(step) = {
  let proc(name, caption) = align(center)[
    #box(fill: accent, radius: 0.3em, inset: (x: 0.6em, y: 0.45em), text(fill: white, weight: "bold", font: mono, size: 0.85em, name))
    #v(-0.4em)
    #text(size: 0.7em, fill: luma(110), style: "italic", caption)
  ]
  let argv(t) = box(stroke: 0.6pt + luma(150), fill: white, radius: 2pt, inset: (x: 0.3em, y: 0.25em), outset: (y: 1pt), text(font: mono, size: 0.75em, t))
  // the variables of your shell
  let greeting = if step <= 3 { "shell" } else if step == 4 { "new" } else { "env" }
  // the child runs on steps 3 and 5
  let child-runs = step == 3 or step >= 5
  let shown(body) = if child-runs { body } else { hide(body) }
  let has-greeting = step >= 5

  set text(size: 0.85em)
  grid(
    columns: (5.5em, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.5em,
    align: (center + horizon, left + horizon),
    proc("bash", [your shell]),
    env-table("bash", (("HOME", "/home/alice", "env"), ("GREETING", "hello", greeting)), width: 100%),

    shown(rotate(90deg, reflow: true, draw-arrow(length: 7em, color: changed))),
    shown(block[
      #text(size: 0.8em)[`fork` + `exec` a new `bash`, its parameters:] \
      #text(size: 0.88em, words(("bash", "cmd"), "-c", "echo \"child: $GREETING\"")) \
      #text(size: 0.75em, fill: luma(110))[*single quotes*: your shell does not expand `$GREETING`]
    ]),

    shown(proc("bash -c", [the child])),
    shown(env-table("bash -c ...", (
      ("HOME", "/home/alice", "env"),
      ("GREETING", "hello", if has-greeting { "new" } else { "hidden" }),
    ), title: [environment of #text(font: mono)[bash -c] (a copy)], width: 100%)),

    [],
    shown(block[
      #text(size: 0.8em)[expands `$GREETING` with *its own* variables, runs `echo`:] \
      #endpoint(changed-end: true)[#text(font: mono, size: 0.85em)[#if has-greeting [child: hello] else [child:]]]
      #draw-arrow(length: 1.4em)
      #endpoint[🖥️ display]
    ]),
  )
}

#slide[
  == `export`
  Shell variables and environment variables: only the *exported* ones are passed to the children

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 3, 8, 9, 11), full: false)[```terminal
    $ GREETING=hello    # a shell variable
    $ echo $GREETING
    hello

    # run a new bash instance that runs
    #  echo "child: $GREETING" - mind the '...'
    $ bash -c 'echo "child: $GREETING"'
    child:
    $ export GREETING   # an environment variable
    $ bash -c 'echo "child: $GREETING"'
    child: hello
    ```]
  ][
    #for (i, when) in ("1", "2", "3", "4", "5-").enumerate() {
      only(when, bash-c-schematic(i + 1))
    }
  ]

  #set text(size: 0.9em)
  #only(1)[💡 ```bash NAME=value``` makes a *shell variable*: it exists only inside this shell]
  #only(2)[💡 ```bash $NAME``` is replaced by its value, by the shell, before the command starts]
  #only(3)[💡 the child (```bash bash -c```) does *not* receive it, it is not part of the environment]
  #only(4)[💡 `export` marks it as an *environment variable*]
  #only("5-")[💡 every child started from now on receives a copy\
    💡 `export NAME=value` does both at once, `unset NAME` deletes it]
]

#slide[
  == Defined by the Shell
  Variables that are already there when the prompt shows up

  #set text(size: 0.85em)
  #table(
    columns: (auto, 1fr, 1.3fr),
    inset: (x: 0.5em, y: 0.45em),
    table.header([Variable], [Value], [Defined in (Fedora)]),
    [`HOME`, `USER`, `SHELL`], [the home directory, the user, the shell], [`/etc/passwd`, read by `login` when you log in],
    [`PWD`, `OLDPWD`], [the current and the previous directory], [the shell itself, at every `cd` (used by `cd -`)],
    [`PATH`], [where commands are], [`/etc/profile`, then `~/.bashrc` adds `~/.local/bin` and `~/bin`],
    [`LANG`], [the language], [`/etc/locale.conf`, read by `/etc/profile.d/lang.sh`],
    [`PS1`], [what the prompt looks like, a *shell variable*], [`/etc/bashrc`, read again by every interactive shell],
  )

  #set text(size: 1.1em)
  💡 the startup files are shell scripts: they run `export NAME=value` (or `NAME=value` for `PS1`)
]

#slide[
  == Special Parameters
  Set by the shell, they can only be read

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    - `$?` - the exit code of the last command (`0` means _success_)
    - `$$` - the PID of the shell
    - `$!` - the PID of the last job started with `&`
  ][
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 8), full: false)[```terminal
    $ ls /nope
    ls: cannot access '/nope': No such file or directory
    $ echo $?
    2
    $ echo $?    # exit code of echo
    0
    $ echo $$
    4011
    ```]
  ]

  #only(2)[💡 `ls` failed: the exit code is not `0`]
  #only(3)[💡 `$?` changes after *every* command]
]

#slide[
  == Defined in the Command Line

  #table(
    columns: (auto, 1fr),
    table.header([Syntax], [Defines]),
    [```bash NAME=value```], [a *shell variable*, only for this shell],
    [```bash export NAME=value```], [an *environment variable*, for this shell and every command started after it],
    [```bash NAME=value command```], [an environment variable *only for* `command`, the shell does not keep it],
    [```bash unset NAME```], [deletes the variable],
  )

  #toolbox.side-by-side(columns: (5fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (2, 4, 6, 8), full: false)[```terminal
    $ date +%H:%M
    11:47
    $ TZ=Asia/Tokyo date +%H:%M   # only for this date
    17:47
    $ echo "[$TZ]"                # the shell does not have it
    []
    $ GREETING = hello
    bash: GREETING: command not found
    ```]
  ][
    #only(2)[💡 `TZ` (time zone) is set only in the environment of this `date` process]
    #only(3)[💡 useful to change a setting just once, e.g. `LANG=C sort names.txt`]
    #only("4-")[
      ⚠️ *no spaces* around `=`: the shell thinks `GREETING` is a command

      💡 use quotes for spaces in the value: `NAME="two words"`
    ]
  ]
]
