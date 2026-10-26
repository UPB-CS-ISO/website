#import "/src/slides.typ": *
#import "common.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#slide[
  = Special Permissions #text(size: 10pt, weight: "regular")[\ _setuid, setgid and the sticky bit_]
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
