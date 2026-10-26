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

// The schematic of "What Is a User?", in three layers: the users, the
// processes that run under them (a child inherits the label of its parent)
// and the kernel, that only sees the UIDs. One part per step of the slide.
#let user-schematic = {
  set text(size: 0.75em)
  let gap = 1.6em
  let layer(step, name) = uncover(step, align(right + horizon, text(size: 0.9em, fill: luma(130), style: "italic", name)))
  let who(icon, name, uid, kind) = align(center)[
    #text(size: 1.5em, icon) \
    #text(size: 0.85em, fill: luma(130), kind) \
    #user-tag(name, uid)
    #v(0.2em)
  ]
  context {
    // every process box as wide as the widest one
    let w = measure(proc-box("nginx", "www-data", 33)).width
    let proc(cmd, name, uid, ..args) = proc-box(cmd, name, uid, width: w, ..args)
    let child = stack(
      down-arrow(length: gap, color: hl, label: text(fill: hl, weight: "bold")[fork]),
      proc("firefox", "alice", 1000, stroke: 1.5pt + hl, fill: hl-bg),
    )
    // bob and www-data have no child, their arrows go straight to the kernel
    let skip = measure(child).height + gap
    grid(
      columns: (auto, auto, auto, auto),
      column-gutter: (0.6em, 1fr, 1fr),
      align: center + top,
      // step 1 & 2: people and services
      layer("1-", [users]),
      who("🧑", "alice", 1000, [person]),
      who("🧑", "bob", 1001, [person]),
      uncover("2-", who("🤖", "www-data", 33, [service])),
      // step 3: every process runs under a user
      [], ..range(3).map(_ => uncover("3-", down-arrow(length: gap))),
      layer("3-", [processes]),
      uncover("3-", proc("bash", "alice", 1000)),
      uncover("3-", proc("bash", "bob", 1001)),
      uncover("3-", proc("nginx", "www-data", 33)),
      // step 4: the child inherits the label
      [], uncover("4-", child),
      grid.cell(rowspan: 2, uncover("5-", down-arrow(length: skip))),
      grid.cell(rowspan: 2, uncover("5-", down-arrow(length: skip))),
      [], uncover("5-", down-arrow(length: gap)),
      // step 5: the kernel decides using only the UID
      layer("5-", [kernel]),
      grid.cell(colspan: 3, uncover("5-", kernel-box(width: 100%)[
        #v(0.1em)
        sees only #uid-pill(1000) #uid-pill(1001) #uid-pill(33, color: luma(90)) \
        #v(0.1em)
        and decides what each process is *allowed* to do
      ])),
    )
  }
}

#slide[
  == What Is a User?
  👤 for the kernel, a user is just a *number*: the *UID*

  #toolbox.side-by-side(columns: (3fr, 5fr), gutter: 1em)[
    #set text(size: 0.9em)
    - a user has a *name* for humans, `alice`, and a *number* for the kernel, the *UID* (_User ID_), `1000`
    #uncover("2-")[#block[- not only people: each service has its own user, `www-data` is UID `33`]]
    #uncover("3-")[#block[- every *process* carries the *UID* of its user, as a *label*, all its life]]
    #uncover("4-")[#block[- a child *inherits* the UID: `firefox`, started by `alice`'s `bash`, also has UID `1000`]]
    #uncover("5-")[#block[- the kernel ignores names, it checks the *UID* to decide what the process is *allowed* to do]]
  ][
    #user-schematic
  ]
]

// A process asks the kernel to do something, the kernel looks at its label.
// One request per step: (command, user, UID, what it asks, target, allowed, why)
#let requests = (
  ("cat", "alice", 1000, [`open("~/notes.txt")`], file-box("~/notes.txt", "alice", "alice", "-rw-------"), true, [`alice` owns the file]),
  ("cat", "alice", 1000, [`open("/etc/shadow")`], file-box("/etc/shadow", "root", "shadow", "-rw-r-----"), false, [`alice` may not read it]),
  ("bash", "alice", 1000, [`kill(812)`], proc-box("sshd", "root", 0), false, [not her process]),
)

#slide[
  == A User Is a Label (number)
  🏷️ the kernel checks the label of a process for *every action*

  #toolbox.side-by-side(columns: (5fr, 4fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 6), full: false)[```terminal
    $ cat ~/notes.txt
    buy milk
    $ cat /etc/shadow
    cat: /etc/shadow: Permission denied
    $ kill 812
    bash: kill: (812) - Operation not permitted
    ```]

    #set text(size: 1.05em)
    #only(1)[📄 the process of `cat` runs under `alice`, the file belongs to `alice`]
    #only(2)[🔒 `/etc/shadow` can be read only by `root` and the group `shadow`]
    #only("3-")[⚙️ not only files: signals, ports below 1024, the clock, mounting disks ... are all checked]
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
