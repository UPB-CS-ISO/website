#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Users #text(size: 10pt, weight: "regular")[\ _the label every process runs under_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.1 - _The /etc/passwd File_
      - Section 7.9.2 - _Process Ownership, Effective UID, Real UID, and Saved UID_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

#slide[
  == What Is a User?
  👤 for the kernel, a user is just a *number*

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - a person who uses the computer: `alice`, `bob`
    #uncover("2-")[#block[- a program that runs in the background: `sshd`, `www-data`]]
    #uncover("3-")[#block[- every *process* runs under a user: a *label* that it carries all its life]]
    #uncover("4-")[#block[- the label is *inherited*: the children of a process get the same user]]
    #uncover("5-")[#block[- the kernel uses the label to decide what the process is *allowed* to do]]
  ][
    #uncover("3-")[
      #set text(size: 0.8em)
      ```terminal
      $ ps -e -o user,uid,pid,comm
      USER       UID     PID COMMAND
      root         0       1 systemd
      root         0     812 sshd
      www-data    33     904 nginx
      alice     1000    3000 bash
      alice     1000    3120 firefox
      bob       1001    3301 bash
      ```
    ]
    #uncover("4-")[
      #set text(size: 0.8em)
      #align(center)[
        #proc-box("bash", "alice", 1000) #h(0.3em) #draw-arrow(length: 1.5em) #h(0.3em) #proc-box("firefox", "alice", 1000)
      ]
    ]
  ]
]

// A process asks the kernel to do something, the kernel looks at its label.
// One request per step: (command, user, UID, what it asks, target, allowed, why)
#let requests = (
  ("cat", "alice", 1000, [`open("~/notes.txt")`], file-box("~/notes.txt", "alice", "alice", "-rw-------"), true, [`alice` owns the file]),
  ("cat", "alice", 1000, [`open("/etc/shadow")`], file-box("/etc/shadow", "root", "shadow", "-rw-r-----"), false, [`alice` may not read it]),
  ("cat", "root", 0, [`open("/etc/shadow")`], file-box("/etc/shadow", "root", "shadow", "-rw-r-----"), true, [`root` may do anything]),
  ("bash", "alice", 1000, [`kill(812)`], proc-box("sshd", "root", 0), false, [not her process]),
)

#let request-drawing(cmd, name, uid, action, target, ok, why) = {
  set text(size: 0.8em)
  align(center)[
    #proc-box(cmd, name, uid)
    #down-arrow(length: 1.3em, label: action)
    #kernel-box[is UID #uid allowed to do this?]
    #down-arrow(length: 1.3em)
    #target
    #v(0.2em)
    #verdict(ok, why)
  ]
}

#slide[
  == A User Is a Label
  🏷️ the kernel checks the label of a process for *every action*

  #toolbox.side-by-side(columns: (5fr, 4fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 8), full: false)[```terminal
    $ cat ~/notes.txt
    buy milk
    $ cat /etc/shadow
    cat: /etc/shadow: Permission denied
    $ sudo cat /etc/shadow
    root:*:20737:0:99999:7:::
    $ kill 812
    bash: kill: (812) - Operation not permitted
    ```]

    #set text(size: 1.05em)
    #only(1)[📄 the process of `cat` runs under `alice`, the file belongs to `alice`]
    #only(2)[🔒 `/etc/shadow` can be read only by `root` and the group `shadow`]
    #only(3)[👑 `sudo` runs `cat` under the user `root`, UID `0`]
    #only("4-")[⚙️ not only files: signals, ports below 1024, the clock, mounting disks ... are all checked]
  ][
    #for (i, r) in requests.enumerate() {
      only(if i == requests.len() - 1 { str(i + 1) + "-" } else { i + 1 }, request-drawing(..r))
    }
  ]
]

#slide[
  == The Properties of a User
  🪪 what the system knows about `alice`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (auto, 1fr),
      table.header([Property], [Example]),
      [*username*], [`alice`],
      [*UID* - user ID], [`1000`],
      [*full name*], [`Alice Smith`],
      [primary group (*GID*)], [`1000`],
      [home directory], [`/home/alice`],
      [shell], [`/bin/bash`],
      [password], [_a hash_, not the password],
    )
  ][
    #uncover("2-")[
      #card(icon: "🔢", title: [the UID is what matters])[
        the *kernel* only knows the *UID*\
        the username is for _humans_, it is translated to the UID by programs
      ]
    ]
    #uncover("3-")[
      #set text(size: 0.8em)
      ```terminal
      $ ls -l notes.txt
      -rw------- 1 alice alice 9 Oct 11 09:00 notes.txt
      $ ls -n notes.txt   # numbers, not names
      -rw------- 1 1000 1000 9 Oct 11 09:00 notes.txt
      ```
    ]
    #uncover("4-")[
      #card(icon: "⚠️", title: [two names, one UID], color: hl)[
        two usernames with the *same UID* are the *same user* for the kernel
      ]
    ]
  ]
]

#slide[
  == UID Ranges
  🔢 most distributions split the UIDs like this

  #table(
    columns: (auto, auto, 1fr, auto),
    table.header([UID], [Kind], [Used for], [Examples]),
    [#text(fill: bad-color, weight: "bold")[`0`]], [👑 `root`], [the administrator, *no restrictions*], [`root`],
    [#text(fill: luma(110), weight: "bold")[`1 - 999`]], [⚙️ system users], [services, they *cannot log in*], [`daemon`, `www-data`, `sshd`],
    [#text(fill: accent, weight: "bold")[`1000 -`]], [🧑 regular users], [people], [`alice`, `bob`],
    [`65534`], [🚫 `nobody`], [a user that owns *nothing*], [`nobody`],
  )

  #uncover("2-")[
    💡 a *system user* isolates a service: if `nginx` is hacked, the attacker is `www-data`, not `root`
  ]

  #uncover("3-")[
    💡 the limits are set in `/etc/login.defs` (`UID_MIN`, `SYS_UID_MAX`, ...)
  ]
]
