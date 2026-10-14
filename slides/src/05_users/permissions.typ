#import "/src/slides.typ": *
#import "common.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#slide[
  = File Permissions #text(size: 10pt, weight: "regular")[\ `r`, `w` _and_ `x` _for files and directories_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.17 - _File Modes and Permissions_
  + #uso-book
    - Chapter 5 - _Utilizatori_
      - Section 5.5
]

#let ls-fields = ("-", "rw-", "r--", "---", "1", "alice", "students", "1234", "Oct 11 09:00", "notes.txt")

#slide[
  == Who Owns a File?
  🔍 `ls -l` shows the owner, the group and the permissions

  #set text(size: 0.95em)
  #record-walk(
    ls-fields,
    sep: ("", "", "", " ", " ", " ", " ", " ", " "),
    size: 1.05em,
    // the owner and the group in the colors of their permissions
    colors: (none, u-color, g-color, o-color, none, u-color, g-color, none, none, none),
    intro: card(icon: "📄", title: [every file has])[
      - *one owner* (a user) and *one group*
      - three sets of permissions: for the *owner*, the *group* and the *others*
    ],
    // only the permissions, the owner and the group, the other fields are skipped
    (
      none,
      ("👤", [`u` - user, the owner], [`rw-` - `alice` can *read* and *write*]),
      ("👥", [`g` - group], [`r--` - the members of `students` can only *read*]),
      ("🌍", [`o` - others], [`---` - everybody else can do *nothing*]),
      none,
      ("👤", [owner], [the user that owns the file, usually the one that created it]),
      ("👥", [group], [the group of the file, usually the primary group of its creator]),
      none,
      none,
      none,
    ),
  )
]

#slide[
  == `r`, `w` and `x`
  📖 the same letters, a different meaning for directories

  #table(
    columns: (auto, auto, 1fr, 1fr),
    table.header([], [Value], [📄 For a file], [📁 For a directory]),
    [`r` - read], [`4`], [read the content (`cat`)], [*list* the names inside (`ls`)],
    [`w` - write], [`2`], [change the content], [*create*, *delete*, *rename* the files inside],
    [`x` - execute], [`1`], [run it as a program], [*enter* it (`cd`) and reach the files inside],
  )

  #uncover("2-")[
    #card(icon: "⚠️", title: [deleting a file is writing the *directory*], color: hl)[
      the name of a file is kept in its directory: with `w` on a directory you can delete *any* file in it, even if it is not yours
    ]
  ]
  #uncover("3-")[
    #card(icon: "💡", title: [to reach a file you need `x` on *every* directory of its path])[
      `cat /home/alice/notes.txt` needs `x` on `/`, `/home` and `/home/alice`
    ]
  ]
]

// (user, UID, groups, the rule that matches, can read, can write)
#let who = (
  ("root", 0, "root", 0, true, true),
  ("alice", 1000, "alice sudo students", 1, true, true),
  ("bob", 1001, "bob students", 2, true, false),
  ("carol", 1002, "carol docker", 3, false, false),
)

// The checks of the kernel as a flowchart, with the values of the process
// and of the file: a question on every row, `yes` goes right to a result,
// `no` goes down to the next question. `match` - the rule that matches, its
// path is highlighted.
#let rules-drawing(name, uid, groups, match) = {
  let colors = (bad-color, ..set-colors)
  let code(body) = text(font: mono, body)
  // a question, then the check with the values of the process and the file
  // after the answer `yes`, the next questions are not asked any more
  let ask(i, question, check) = [#question \ #text(size: 0.8em, fill: luma(120), if i <= match { check } else [⏭️ not checked, the answer is already known])]
  let questions = (
    ask(0, [is it `root`?], [its UID #code(str(uid)) = #code("0") ?]),
    ask(1, [is it the *owner* of the file?], [its UID #code(str(uid)) = #code("1000"), the UID of `alice` ?]),
    ask(2, [is #raw(name) a member of `students`?], [the groups of #raw(name): #code(groups)]),
  )
  let results = (
    [👑 everything is allowed],
    [use `u`: #text(fill: if match == 1 { set-colors.at(0) } else { luma(170) }, code("rw-"))],
    [use `g`: #text(fill: if match == 2 { set-colors.at(1) } else { luma(170) }, code("r--"))],
    [use `o`: #text(fill: if match == 3 { set-colors.at(2) } else { luma(170) }, code("---"))],
  )
  let path-color = colors.at(match)
  let reached(i) = i <= match
  let line-stroke(on) = if on { 1pt + path-color } else { arrow-thickness + luma(210) }
  let label(body, on) = text(size: 0.8em, fill: if on { path-color } else { luma(180) }, body)
  let question(i) = node(
    (0, i + 1), text(fill: if reached(i) { black } else { luma(170) }, questions.at(i)),
    width: 17em, corner-radius: 0.3em, inset: 0.45em, shape: rect,
    stroke: if reached(i) { 0.8pt + accent } else { 0.6pt + luma(215) },
  )
  let result(pos, i) = node(
    pos, text(fill: if i == match { black } else { luma(170) }, results.at(i)),
    width: 11.5em, corner-radius: 0.3em, inset: 0.45em, shape: rect,
    stroke: if i == match { 1pt + colors.at(i) } else { 0.6pt + luma(215) },
    fill: if i == match { colors.at(i).lighten(90%) } else { none },
  )
  set text(size: 0.8em)
  diagram(
    spacing: (2em, 1.6em),
    node((0, 0), proc-box("cat notes.txt", name, uid), inset: 0pt),
    edge((0, 0), (0, 1), arrow-marks, stroke: line-stroke(true)),
    ..range(3).map(i => (
      question(i),
      result((1, i + 1), i),
      // yes: to the result
      edge((0, i + 1), (1, i + 1), arrow-marks, stroke: line-stroke(i == match), label: label([yes], i == match), label-side: left),
      // no: to the next question, or to the `o` permissions
      edge((0, i + 1), (0, i + 2), arrow-marks, stroke: line-stroke(i < match), label: label([no], i < match), label-side: right),
    )).flatten(),
    result((0, 4), 3),
  )
}

// the permissions of the file, each set in its color, the one that is used
// is highlighted
#let mode-drawing(match) = {
  let part(body, i) = {
    let color = set-colors.at(i - 1)
    box(
      inset: (x: 0.15em, y: 0.25em), outset: (y: 1pt), radius: 2pt,
      fill: if i == match { color.lighten(90%) } else { none },
      stroke: if i == match { 0.8pt + color } else { none },
      text(fill: if i == match or match == 0 { color } else { color.lighten(50%) }, body),
    )
  }
  text(font: mono, size: 1.1em)[#text(fill: dim, "-")#part("rw-", 1)#part("r--", 2)#part("---", 3)]
}

#slide[
  == Which Permissions Apply?
  ⚖️ the kernel checks *in order*, the first answer `yes` decides

  #let when(i) = if i == who.len() - 1 { str(i + 1) + "-" } else { i + 1 }
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #for (i, (name, uid, groups, match, r, wr)) in who.enumerate() {
      only(when(i), rules-drawing(name, uid, groups, match))
    }
  ][
    #align(center)[
      #file-box("notes.txt", "alice", "students", "-rw-r-----")
      #v(0.4em)
      #for (i, (name, uid, groups, match, r, wr)) in who.enumerate() {
        only(when(i))[
          #mode-drawing(match)
          #v(0.4em)
          #verdict(r, [read]) #verdict(wr, [write])
        ]
      }
    ]
    #v(0.6em)
    #uncover("5-")[
      #set text(size: 0.75em)
      #card(icon: "⚠️", title: [only one set is used], color: hl)[
        with #text(font: mono, "----rw----") the owner can do nothing, even if the group can: the owner already got `yes`
      ]
    ]
  ]
]

// a permission string in the colors of u, g and o, the letter at `at` is
// marked: the special bit in place of the `x`
#let mark-mode(mode, at) = text(font: mono, {
  for (i, ch) in mode.clusters().enumerate() {
    let color = if i == 0 { luma(130) } else { set-colors.at(calc.div-euclid(i - 1, 3)) }
    if i == at {
      box(fill: color.lighten(85%), outset: (y: 2pt), radius: 2pt, text(fill: color, weight: "bold", ch))
    } else {
      text(fill: color, ch)
    }
  }
})

// what a special letter means: the real permission under it, and the bit
#let decode(mode, at, bit, color) = {
  let ch = mode.clusters().at(at)
  let real = mode.clusters().enumerate().map(((i, c)) => if i != at { c } else if ch == "s" or ch == "t" { "x" } else { "-" }).join()
  box[#mark-mode(real, at) #text(size: 0.85em)[\+ #text(fill: color, weight: "bold", bit)]]
}

#slide[
  == Special Permissions
  ✨ three more bits, shown in place of an `x`

  #let none-yet = text(fill: luma(160))[-]
  #set text(size: 0.9em)
  #table(
    columns: (auto, auto, auto, 1fr, 1fr),
    table.header([], [`ls -l` shows], [the rights are], [📄 On a file], [📁 On a directory]),
    [🪄 #text(fill: u-color)[*setuid*]], [#mark-mode("-rwsr-xr-x", 3) \ #text(size: 0.8em)[`/usr/bin/passwd`]], decode("-rwsr-xr-x", 3, "setuid", u-color),
      [runs as the *owner* of the file, not as the user who starts it], none-yet,
    uncover("2-")[👥 #text(fill: g-color)[*setgid*]], uncover("2-")[#mark-mode("drwxrwsr-x", 6) \ #text(size: 0.8em)[`/srv/project`]], uncover("2-", decode("drwxrwsr-x", 6, "setgid", g-color)),
      uncover("2-")[runs with the *group* of the file], uncover("2-")[the new files get the *group* of the directory, not of their creator],
    uncover("3-")[📌 #text(fill: o-color)[*sticky*]], uncover("3-")[#mark-mode("drwxrwxrwt", 9) \ #text(size: 0.8em)[`/tmp`]], uncover("3-", decode("drwxrwxrwt", 9, "sticky", o-color)),
      uncover("3-", none-yet), uncover("3-")[in a directory everyone can write, you can delete or rename *only your own* files],
  )

  #uncover("4-")[
    💡 a capital `S` or `T`: the bit is set, but the `x` under it is not
    #v(0.2em)
    #align(center)[
      #mark-mode("-rwSr--r--", 3) #h(0.4em) means #h(0.4em) #decode("-rwSr--r--", 3, "setuid", u-color)
      #h(2.5em)
      #mark-mode("drwxrwxrwT", 9) #h(0.4em) means #h(0.4em) #decode("drwxrwxrwT", 9, "sticky", o-color)
    ]
  ]
]

#slide[
  == Directories in Practice
  📁 `r` lists, `x` enters

  #toolbox.side-by-side(columns: (5fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.88em)
    #reveal-terminal(before: none, lines: (4, 6, 8, 11, 13, 15), full: false)[```terminal
    $ ls -l
    drwx------ 2 alice alice 4096 Oct 11 09:00 box
    d--x------ 2 alice alice 4096 Oct 11 09:00 noread
    dr-------- 2 alice alice 4096 Oct 11 09:00 noenter
    $ ls noread
    ls: cannot open directory 'noread': Permission denied
    $ cat noread/secret.txt
    hello
    $ ls noenter
    ls: cannot access 'noenter/secret.txt': Permission denied
    secret.txt
    $ cd noenter
    bash: cd: noenter: Permission denied
    $ ls -ld /tmp
    drwxrwxrwt 18 root root 4096 Oct 11 09:00 /tmp
    ```]
  ][
    #set text(size: 0.95em)
    #only(1)[📁 three directories of `alice`, with different permissions for her]
    #only(2)[🙈 `noread` has no `r`: the *names* cannot be listed]
    #only(3)[🔑 but it has `x`: a file whose name you *know* can still be opened]
    #only(4)[👀 `noenter` has `r` without `x`: the names are listed, but nothing more]
    #only(5)[🚪 without `x`: the directory cannot be *entered*]
    #only(6)[📌 `/tmp`: everyone can write, the `t` (_sticky bit_) lets you delete *only your own* files]
  ]
]

#slide[
  == `chmod`
  ✏️ change the permissions, only the owner (or `root`) can do it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #card(icon: "🔤", title: [with letters])[
      *who* #text(fill: u-color)[`u`] #text(fill: g-color)[`g`] #text(fill: o-color)[`o`] `a` (all) \
      *how* `+` add, `-` remove, `=` set \
      *what* `r` `w` `x`

      #set text(size: 0.8em)
      ```terminal
      $ chmod u+x script.sh
      $ chmod g+w,o-r notes.txt
      $ chmod a=r readme.txt
      $ chmod -R g+rX project/
      ```
    ]
  ][
    #uncover("2-")[
      #card(icon: "🔢", title: [with numbers (octal)])[
        `r` = 4, `w` = 2, `x` = 1, add them for #text(fill: u-color)[`u`], #text(fill: g-color)[`g`], #text(fill: o-color)[`o`]

        #align(center)[
          #table(
            columns: 3,
            align: center,
            text(font: mono, fill: u-color, "rw-"), text(font: mono, fill: g-color, "r--"), text(font: mono, fill: o-color, "---"),
            text(fill: u-color)[4+2 = *6*], text(fill: g-color)[4 = *4*], text(fill: o-color)[*0*],
          )
        ]
        #set text(size: 0.8em)
        ```terminal
        $ chmod 640 notes.txt
        $ chmod 755 script.sh
        ```
      ]
    ]
  ]
]

#slide[
  == `chown` and `chgrp`
  🔄 change the owner and the group

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 2, 3, 5), full: false)[```terminal
    $ sudo chown bob notes.txt
    $ sudo chown bob:students notes.txt
    $ chgrp students notes.txt
    $ chown carol notes.txt
    chown: changing ownership of 'notes.txt': Operation not permitted
    ```]
  ][
    #set text(size: 0.95em)
    #only(1)[- the owner becomes `bob`]
    #only(2)[- the owner *and* the group, `user:group`]
    #only(3)[- only the group, the owner may do it, if they are a member of the new group]
    #only(4)[- only `root` can give a file to another user]

    #uncover("4-")[
      #card(icon: "💡", title: [why only `root`?], color: hl)[
        otherwise, anyone could fill the disk quota of another user, or hide what they did
      ]
    ]
  ]
]

// setuid at work: `alice` runs a program owned by root with the `s` bit,
// the new process runs as root. One row per program: the program, the new
// process, what it does and its target. `from` - the step of the row, the
// target is shown one step later
#let setuid-row(step, from, program, process, action, target) = {
  let shown(at, body) = if step >= at { body } else { hide(body) }
  let arrow(from-pos, to-pos, at, label, color: arrow-gray, dash: none) = edge(
    from-pos, to-pos, arrow-marks,
    stroke: (paint: if step >= at { color } else { white }, thickness: arrow-thickness, dash: dash),
    label: if step >= at { text(size: 0.85em, fill: if color == arrow-gray { luma(110) } else { color }, label) },
    label-side: left,
  )
  set text(size: 0.8em)
  align(center, diagram(
    spacing: (4.6em, 3em),
    // the shell, then the program file it reads, the new process, its work
    thing((0, 0), shown(from, proc-box("bash", "alice", 1000))),
    thing((1, 0), shown(from + 1, file-box(program, "root", "root", mark-mode("-rwsr-xr-x", 3), icon: "📄"))),
    arrow((0, 0), (1, 0), from + 1, [reads \ the file], dash: "dotted"),
    thing((2, 0), shown(from + 2, process)),
    arrow((1, 0), (2, 0), from + 2, [`s`: as `root`], color: u-color),
    thing((3, 0), shown(from + 3, target)),
    arrow((2, 0), (3, 0), from + 3, action),
  ))
}

// a command started by another program: the syntax colors, without the `$`
#let started-command(line) = box(
  fill: accent.lighten(90%), inset: (x: 0.4em, y: 0.25em), radius: 0.2em,
  text(font: mono, size: 1.25em, highlight-shell(line)),
)

#slide[
  == `setuid` at Work
  🪄 the `s` bit (_setuid_): the program runs as its *owner*, not as the user who starts it

  // the prompt from step `from`, the command after it one step later
  #let command(step, from, line) = {
    set text(size: 0.8em)
    let term = prompt-term(if step > from { "alice@laptop:~$ " + line } else { "alice@laptop:~$ " })
    if step >= from { term } else { hide(term) }
  }
  #let rows(step) = {
    command(step, 1, "passwd")
    setuid-row(step, 1, "/usr/bin/passwd",
      proc-note-box("passwd", "root", 0, [started by `alice`]),
      [writes], file-box("/etc/shadow", "root", "shadow", "-rw-r-----", icon: "🔐"))
    v(0.4em)
    command(step, 5, "sudo cat /etc/shadow")
    setuid-row(step, 5, "/usr/bin/sudo",
      proc-note-box("sudo", "root", 0, [started by `alice`]),
      [starts], proc-note-box("cat", "root", 0, started-command("cat /etc/shadow")))
  }
  #for step in range(1, 9) {
    only(if step == 8 { "8-" } else { step }, rows(step))
  }

  #v(0.3em)
  #only(1)[🐚 `alice` has a shell, `bash`, that runs as her]
  #only(2)[⌨️ she types `passwd`: `bash` reads the program file `/usr/bin/passwd`]
  #only(3)[🪄 the file belongs to `root` and has the `s` bit: the new process runs as `root`]
  #only(4)[✍️ as `root`, `passwd` may write her new hash in `/etc/shadow`]
  #only(5)[🐚 the same shell of `alice`]
  #only(6)[⌨️ she types `sudo cat /etc/shadow`: `bash` reads `/usr/bin/sudo`]
  #only(7)[🛡️ `/usr/bin/sudo` is setuid `root` too: `sudo` runs as `root`]
  #only("8-")[✅ `sudo` checks `/etc/sudoers` and `alice`'s password, then starts `cat /etc/shadow` as `root`]
]

#slide[
  == Do Not Use `+s`
  ☠️ a setuid `root` program is *very dangerous*

  #align(center)[
    #v(0.5em)
    #box(text(size: 2.4em)[☠️]) #h(0.4em)
    #text(size: 1.6em, fill: bad-color, weight: "bold")[never add `+s` to a program of `root`]
    #h(0.4em) #box(text(size: 2.4em)[☠️])
    #v(0.3em)
    #text(size: 1.1em)[it runs as its owner, `root`, for *everyone*: one bug, and *anyone* becomes `root`]

    #v(0.6em)
    #uncover("2-")[
      #box(
        width: 75%, inset: 0.8em, radius: 0.4em,
        fill: bad-color.lighten(90%), stroke: 2pt + bad-color,
      )[
        #grid(
          columns: (auto, 1fr),
          column-gutter: 1em,
          align: horizon,
          box(text(size: 2.6em)[💀]),
          align(left)[
            #text(font: mono, size: 1.1em)[-rwsr-xr-x root root /usr/bin/bash] \
            #text(fill: bad-color, weight: "bold")[a setuid `bash`: every user gets a `root` shell]
          ],
        )
      ]
    ]

    #v(0.4em)
    #uncover("3-")[
      ⚠️ on *your* program it is risky too: whoever runs it acts as *you*, with your files
      #v(0.2em)
      ✅ leave the `s` bit to the programs made for it: `sudo`, `passwd`, `su`
    ]
  ]
]

// every action of a process is an access to a file, checked with rwxst:
// (what the process wants, the letter that decides, the file)
#let file-rights = (
  ([📖 read data], "r", file-box("/home/alice/notes.txt", "alice", "students", "-rw-r-----")),
  ([⚙️ change a setting], "w", file-box("/etc/hosts", "root", "root", "-rw-r--r--")),
  ([▶️ run a program], "x", file-box("/usr/bin/apt", "root", "root", "-rwxr-xr-x")),
  ([👑 run as `root`], "s", file-box("/usr/bin/sudo", "root", "root", mark-mode("-rwsr-xr-x", 3))),
  ([🔌 use a device], "rw", file-box("/dev/ttyUSB0", "root", "dialout", "crw-rw----", icon: "🔌")),
  ([🗑️ delete in `/tmp`], "t", file-box("/tmp", "root", "root", mark-mode("drwxrwxrwt", 9), icon: "📁")),
)

#slide[
  == Everything Is a File
  🗂️ data, settings, programs and devices: every right is a right on a file

  #align(center, {
    set text(size: 0.68em)
    let n = file-rights.len()
    let middle = (n - 1) / 2
    // what the process wants, with the letter that decides
    let action(body, letter) = box(
      inset: (x: 0.5em, y: 0.35em), radius: 1em, stroke: 0.6pt + luma(180), fill: luma(248),
    )[#body #h(0.3em) #box(inset: (x: 0.3em, y: 0.1em), radius: 0.2em, fill: accent.lighten(85%), text(font: mono, weight: "bold", fill: accent, letter))]
    diagram(
      spacing: (2.4em, 0.3em),
      thing((0, middle), proc-box("a process", "alice", 1000)),
      thing((1, middle), kernel-box[checks #text(font: mono, weight: "bold")[r w x s t]]),
      step-arrow((0, middle), (1, middle), none),
      ..file-rights.enumerate().map(((i, (wish, letter, file))) => (
        thing((2, i), action(wish, letter)),
        thing((3, i), file),
        step-arrow((1, middle), (2, i), none),
        step-arrow((2, i), (3, i), none),
      )).flatten(),
    )
  })

  #v(0.2em)
  #let chip(letter, color) = box(
    inset: (x: 0.45em, y: 0.2em), outset: (y: 2pt), radius: 0.25em,
    fill: color.lighten(85%), stroke: 0.6pt + color,
    text(font: mono, weight: "bold", fill: color, letter),
  )
  #set text(size: 0.9em)
  #align(center, box(width: 85%, card(icon: "💡", title: [a plain Linux system has no other privileges])[
    every right is one of #chip("r", accent) #chip("w", accent) #chip("x", accent) #chip("s", u-color) #chip("t", o-color) on a file #h(1fr) 👑 only `root` skips the checks
  ]))
]
