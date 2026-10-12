#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Becoming `root` #text(size: 10pt, weight: "regular")[\ `sudo`, `su` _and the_ `sudoers` _file_]
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
  ("🪄", [`sudo` is a _setuid_ program], [the `s` bit: it always runs as `root`, but it knows who started it]),
  ("📜", [is `alice` allowed?], [`sudo` reads `/etc/sudoers`: `alice` is in the group `sudo`, she may run *any* command]),
  ("🔑", [who is at the keyboard?], [it asks for the password of *`alice`* (with PAM), not the one of `root`]),
  ("⏱️", [remembered for a while], [no password again for the next 5 minutes, in the same terminal]),
  ("🚫", [not allowed], [`bob` is not in `/etc/sudoers`: `sudo` refuses and writes the attempt in the log]),
  ("📒", [everything is written down], [the log shows *who* ran *what*, *where* and *as whom*]),
)

#slide[
  == How `sudo` Works
  🛡️ a program that decides who may become `root`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.7em)
    #prompt-term(reveal: (2, 5, 5, 7, 10, 14))[```
    alice@laptop:~$ ls -l /usr/bin/sudo
    -rwsr-xr-x 1 root root 277936 /usr/bin/sudo
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
    #set text(size: 0.9em)
    #only(1)[#card(icon: sudo-notes.at(0).at(0), title: sudo-notes.at(0).at(1), sudo-notes.at(0).at(2))]
    #for (i, (icon, title, body)) in sudo-notes.slice(1).enumerate() {
      let step = i + 2
      only(if step == 6 { "6-" } else { step }, card(icon: icon, title: title, color: if step == 5 { bad-color } else { accent }, body))
    }
  ]
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

// an arrow with a small label above it
#let labeled-arrow(label, color: luma(120), length: 6em) = box(width: length, align(center)[
  #text(size: 0.8em, fill: color, label) \
  #draw-arrow(length: length, color: color)
])

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
