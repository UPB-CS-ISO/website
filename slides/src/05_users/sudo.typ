#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Becoming `root` #text(size: 10pt, weight: "regular")[\ `sudo` _and_ `su`]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.20 - _Running Commands as the Superuser_
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.9.1 - _User IDs and User Switching_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

// the same request, without and with `sudo`
#let shadow-file = file-box("/etc/shadow", "root", "shadow", "-rw-r-----")
#let sudo-requests = (
  ("cat", "alice", 1000, [`open("/etc/shadow")`], shadow-file, false, [`alice` may not read it]),
)

// with `sudo`: the `sudo` process runs as root and starts `cat` as root
#let sudo-drawing = {
  set text(size: 0.8em)
  diagram(
    spacing: (3em, 2.2em),
    // like proc-box, with a note: who started it
    thing((0, 0), box(
      inset: (x: 0.6em, y: 0.45em),
      radius: 0.3em,
      stroke: 0.8pt + luma(150),
      fill: white,
      align(center)[⚙️ #text(font: mono, weight: "bold", "sudo") \ #v(0.1em) #user-tag("root", 0) \ #text(size: 0.8em, fill: luma(110))[started by `alice`]],
    )),
    thing((1, 0), proc-box("cat", "root", 0)),
    step-arrow((0, 0), (1, 0), [starts]),
    thing((1, 1), kernel-box[is UID 0 allowed to do this?]),
    step-arrow((1, 0), (1, 1), [`open()`]),
    thing((1, 2), shadow-file),
    step-arrow((1, 1), (1, 2), none),
    thing((1, 2.8), verdict(true, [`root` may do anything])),
  )
}

#slide[
  == `sudo` Changes the Label
  👑 the same command, under another UID

  #toolbox.side-by-side(columns: (5fr, 4fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4), full: false)[```terminal
    $ cat /etc/shadow
    cat: /etc/shadow: Permission denied
    $ sudo cat /etc/shadow
    root:*:20737:0:99999:7:::
    ```]

    #set text(size: 1.05em)
    #only(1)[🔒 `cat` runs under `alice`, UID `1000`: `/etc/shadow` can be read only by `root` and the group `shadow`]
    #only("2-")[👑 `sudo` runs as `root`, UID `0`, and starts `cat` under the same user: the kernel allows everything to UID `0`]
  ][
    #only(1, request-drawing(..sudo-requests.at(0)))
    #only("2-", sudo-drawing)
  ]
]

#slide[
  == `sudo` and `su`
  🔑 two ways to run commands as `root`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #card(icon: "🛡️", title: [`sudo` - run one command as `root`])[
      ```terminal
      $ sudo dnf install htop
      [sudo] password for alice:
      ```
      - asks for *your* password
      - only the users allowed in `/etc/sudoers`
      - every command is written in a log
    ]
  ][
    #uncover("2-")[
      #card(icon: "🔄", title: [`su` - switch user, start a shell], color: hl)[
        ```terminal
        $ su -
        Password:
        ```
        - asks for the password of *`root`*
        - everyone who uses it must know that password
        - nothing tells *who* became `root`
      ]
    ]
  ]

  #uncover("3-")[
    💡 on some systems (Ubuntu, macOS) `root` has *no password* (`!` in `/etc/shadow`), only `sudo` works
  ]
]

#let sudo-notes = (
  [🔑 `sudo` asks for the password of *`alice`*, not the one of `root`],
  [📜 `/etc/sudoers` says who may become `root`: `alice` may, so `whoami` runs as `root`],
  [⏱️ no password again for the next 5 minutes, in the same terminal],
  [🚫 `bob` is not in `/etc/sudoers`: `sudo` refuses, `whoami` never starts],
  [📒 every attempt is written in the log: *who* ran *what*, *as whom*],
)

// what `sudo` does, one drawing per step; every box keeps its place
#let how-sudo-drawing(step) = {
  let user = if step == 4 { "bob" } else { "alice" }
  let ok = step != 4
  let shown(from, body) = if step >= from { body } else { hide(body) }
  let arrow(from-pos, to-pos, label, color: arrow-gray, on: true, dash: none) = edge(
    from-pos, to-pos, arrow-marks,
    stroke: (paint: if on { color } else { white }, thickness: arrow-thickness, dash: dash),
    label: if on and label != none { text(size: 0.9em, fill: if color == arrow-gray { luma(110) } else { color }, label) },
    label-side: left,
  )
  let plain(body, stroke: 0.8pt + luma(150), dash: none) = box(inset: (x: 0.6em, y: 0.45em), radius: 0.3em, stroke: (paint: stroke.paint, thickness: stroke.thickness, dash: dash), fill: white, align(center, body))

  let sudo-box = plain[⚙️ #text(font: mono, weight: "bold")[sudo whoami] \ #text(size: 0.8em, fill: luma(110))[started by #raw(user)]]
  let password = if step == 3 {
    plain(stroke: 0.8pt + accent)[⏱️ remembered \ #text(size: 0.8em, fill: luma(110))[no password]]
  } else {
    plain(stroke: 0.8pt + accent)[🔑 password \ #text(size: 0.8em, fill: luma(110))[of #raw(user)]]
  }
  let sudoers = plain[📜 #text(font: mono, weight: "bold")[/etc/sudoers] \ #text(size: 0.8em, fill: luma(110))[who may become `root`]]
  let answer = verdict(ok, if ok [#raw(user) may] else [#raw(user) may not])
  let child = if ok { proc-box("whoami", "root", 0) } else { plain(stroke: 0.8pt + luma(170), dash: "dashed", text(fill: luma(150))[⚙️ `whoami` \ #text(size: 0.85em)[never starts]]) }
  let log = plain[📒 *the log* \ #text(size: 0.8em, fill: luma(110))[`journalctl -t sudo`]]

  set text(size: 0.85em)
  diagram(
    spacing: (2.5em, 2.2em),
    thing((0, 0), sudo-box),
    thing((1, 0), shown(1, password)),
    arrow((0, 0), (1, 0), [asks]),
    thing((0, 1), shown(2, sudoers)),
    arrow((0, 0), (0, 1), [may #raw(user)?], on: step >= 2),
    thing((1, 1), shown(2, answer)),
    thing((0, 2), shown(2, child)),
    arrow((0, 1), (0, 2), if ok [starts] else [refuses], color: if ok { ok-color } else { bad-color }, on: step >= 2),
    thing((1, 2), shown(5, log)),
    arrow((0, 1), (1, 2), [writes], on: step >= 5, dash: "dotted"),
  )
}

#slide[
  == Who can use `sudo`
  🛡️ a program that decides who may become `root`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.7em)
    #prompt-term(reveal: (2, 3, 5, 8, 12))[```
    alice@laptop:~$ sudo whoami
    [sudo] password for alice:
    root
    alice@laptop:~$ sudo whoami
    root
    bob@laptop:~$ sudo whoami
    [sudo] password for bob:
    bob is not in the sudoers file.
    alice@laptop:~$ sudo journalctl -t sudo
    alice : TTY=pts/0 ; USER=root ; COMMAND=/usr/bin/whoami
    alice : TTY=pts/0 ; USER=root ; COMMAND=/usr/bin/whoami
    bob : user NOT in sudoers ; TTY=pts/1 ; USER=root ; ...
    ```]
  ][
    #for step in range(1, 6) {
      only(if step == 5 { "5-" } else { step }, align(center, how-sudo-drawing(step)))
    }
  ]

  #v(0.8em)
  #for (i, note) in sudo-notes.enumerate() {
    only(if i == 4 { "5-" } else { i + 1 }, note)
  }
]

#slide[
  == Using `sudo`
  🧰 the options you will need

  // a command, highlighted like in the terminal
  #let cmd(c) = text(font: mono, size: 0.9em, highlight-shell(c))
  #table(
    columns: (auto, 1fr),
    table.header([Command], [What it does]),
    cmd("sudo command"), [runs `command` as `root`],
    cmd("sudo -u bob command"), [runs `command` as `bob`],
    cmd("sudo -E command"), [keeps *your* environment variables (no `env_reset`), e.g. `http_proxy`],
    cmd("sudo -i"), [starts a *login shell* of `root`: `root`'s home and variables],
    cmd("sudo -s"), [starts a shell as `root`, in the current directory],
    cmd("sudo -l"), [lists the commands you may run],
    cmd("sudo -k"), [forgets the password now, the next `sudo` asks again],
    cmd("sudo !!"), [runs the *previous* command again, with `sudo` (a `bash` trick)],
  )
]

// a process that never starts
#let ghost-box(body) = box(
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: (paint: luma(170), thickness: 0.8pt, dash: "dashed"),
  align(center, text(fill: luma(150), body)),
)

#let hosts-file = file-box("/etc/hosts", "root", "root", "-rw-r--r--")

// `sudo echo ... >> /etc/hosts`: bash opens the file, as alice
#let trap-drawing = {
  set text(size: 1.05em)
  grid(
    columns: (auto, auto, auto),
    column-gutter: 0.5em,
    row-gutter: 0.6em,
    align: center + horizon,
    proc-box("bash", "alice", 1000),
    labeled-arrow([opens it for `>>`], color: bad-color),
    hosts-file,
    ghost-box[⚙️ `sudo echo ...` \ #text(size: 0.85em)[never starts]],
    [],
    verdict(false, [`Permission denied`]),
  )
}

// `echo ... | sudo tee -a /etc/hosts`: tee opens the file, as root
#let tee-drawing = {
  set text(size: 1.05em)
  grid(
    columns: (auto, auto, auto, auto, auto),
    column-gutter: 0.5em,
    row-gutter: 0.4em,
    align: center + horizon,
    proc-box("echo", "alice", 1000),
    labeled-arrow([🚰 the text, \ through the pipe], color: accent),
    proc-box("tee -a", "root", 0),
    labeled-arrow([writes, appends], color: ok-color),
    hosts-file,
    [], [],
    down-arrow(length: 1.2em, label: [a copy]),
    [], verdict(true, [the line is added]),
    [], [],
    text(size: 0.9em)[🖥️ the terminal],
  )
}

#slide[
  == The Redirect Trap
  🪤 `sudo` runs the *command*, not the whole line

  #set text(size: 0.9em)
  #reveal-terminal(before: none, lines: (2, 4), full: false)[```terminal
  $ sudo echo "192.168.1.20 printer" >> /etc/hosts
  bash: /etc/hosts: Permission denied
  $ echo "192.168.1.20 printer" | sudo tee -a /etc/hosts
  192.168.1.20 printer
  ```]

  #v(0.3em)
  #only(1)[
    #align(center, trap-drawing)
    #v(0.3em)
    💡 the *shell* of `alice` opens the file for `>>`, *before* `sudo` starts: the redirect is not part of the command
  ]
  #only("2-")[
    #align(center, tee-drawing)
    #v(0.3em)
    💡 `tee` writes its input to a file *and* to the screen, `sudo` runs it as `root`, so `tee` opens the file \
    `-a` *appends*, like `>>` (without `-a`, `tee` replaces the whole file)
  ]
]
