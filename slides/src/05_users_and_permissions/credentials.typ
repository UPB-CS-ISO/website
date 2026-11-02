#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Label of a Process #text(size: 10pt, weight: "regular")[\ _the credentials that the kernel checks_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.9.1 - _User IDs and User Switching_
      - Section 7.9.2 - _Process Ownership, Effective UID, Real UID, and Saved UID_
  + #link("https://man7.org/linux/man-pages/man7/credentials.7.html")[`man 7 credentials`] - the credentials of a process
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

// ----- the ID card of a process -----

// the name of a UID or GID, as on the other slides of this lecture
#let cred-name(id) = if id == 0 { "root" } else if id == 1000 { "alice" } else if id == 1001 { "bob" } else { str(id) }

// one credential: the number, and the name under it, in a tinted chip in the
// color of the user (root red, people blue)
// `on` - false grays it out, `changed` - orange, it changed on this step
#let cred-cell(id, on: true, changed: false) = {
  let color = if changed { hl } else if not on { dim } else { user-color(id) }
  box(
    width: 100%,
    inset: (y: 0.25em),
    radius: 0.3em,
    fill: if changed { hl-bg } else if not on { luma(246) } else { color.lighten(90%) },
    stroke: (if changed { 1.2pt } else { 0.6pt }) + if on or changed { color.lighten(30%) } else { luma(225) },
    align(center, text(fill: color)[
      #text(font: mono, weight: "bold", str(id)) \ #v(-0.25em) #text(size: 0.75em, cred-name(id))
    ]),
  )
}

// a small chip for a supplementary group
#let group-chip(gid, on: true) = box(
  inset: (x: 0.35em, y: 0.15em),
  outset: (y: 1pt),
  radius: 1em,
  fill: if on { accent.lighten(90%) } else { luma(246) },
  stroke: 0.6pt + if on { accent.lighten(30%) } else { luma(225) },
  text(font: mono, size: 0.85em, weight: "bold", fill: if on { accent } else { dim }, gid),
)

// The credentials of a process, as an ID card: a colored band with the
// command, the real, effective and saved UID (and GID), and the
// supplementary groups.
// - uids, gids: (real, effective, saved); gids: none - not shown
// - groups: the supplementary groups, a string "27 1000" (none - not shown)
// - focus: the columns (0 real, 1 effective, 2 saved, "groups") in focus,
//   the others are grayed out; none - everything normal
// - changed, changed-gids: the UID / GID columns that changed on this step, in orange
// - labels: show the names of the columns
// e.g. #cred-card("passwd", (1000, 0, 0), changed: (1, 2))
#let cred-card(cmd, uids, gids: none, groups: none, focus: none, changed: (), changed-gids: (), labels: true, width: auto) = {
  let on(col) = focus == none or col in focus
  let row-name(name) = text(size: 0.7em, weight: "bold", fill: luma(130), name)
  let row(name, ids, changed) = (
    row-name(name),
    ..ids.enumerate().map(((col, id)) => cred-cell(id, on: on(col), changed: col in changed)),
  )
  // the color changes with the focus, never the weight: nothing moves
  let label(col, name) = text(size: 0.7em, fill: if focus != none and col in focus { hl } else { luma(130) }, name)
  box(
    width: width,
    radius: 0.4em,
    clip: true,
    stroke: 0.8pt + accent,
    fill: white,
    // a one-column grid: the band is as wide as the card, the card as
    // wide as its content
    grid(
      columns: (auto,),
      fill: (_, y) => if y == 0 { accent } else { none },
      inset: (_, y) => if y == 0 { (x: 0.6em, y: 0.3em) } else { (x: 0.6em, y: 0.45em) },
      align(center, text(fill: white)[⚙️ #text(font: mono, weight: "bold", cmd)]),
      grid(
        columns: (auto, 3.6em, 3.6em, 3.6em),
        column-gutter: 0.35em,
        row-gutter: 0.3em,
        align: center + horizon,
        ..if labels { ([], label(0, [real]), label(1, [effective]), label(2, [saved])) },
        ..row([UID], uids, changed),
        ..if gids != none { row([GID], gids, changed-gids) },
        ..if groups != none {
          let g = on("groups")
          (
            row-name[groups],
            grid.cell(colspan: 3, groups.split(" ").map(gid => group-chip(gid, on: g)).join(h(0.3em))),
          )
        },
      ),
    ),
  )
}

#let credential-notes = (
  [🙋 *real*: _who you are_ - `whoami` and `id` read the UIDs, the programs use the real one to know who started them],
  [🔍 *effective*: _what you may do_ - the kernel compares it with the owner of a file],
  [💾 *saved*: lets a program put its rights aside for a while and take them back later],
  [👥 the groups of `alice`: `sudo` (27), `alice` (1000) and `students` (1100); a 4#super[th] UID and GID, for the _file system_, always follow the effective ones],
  [🪄 `passwd` has the `setuid` bit: its effective and saved UID are the *owner* of the file, `root`],
)

#slide[
  == The Credentials of a Process
  🪪 an ID card that the *kernel* keeps for every process

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1em)[
    #set text(size: 0.85em)
    - *real* UID - the user who *started* the process
    #uncover("2-")[#block[- *effective* UID - the one the kernel *checks*]]
    #uncover("3-")[#block[- *saved* UID - a spare copy of the effective one]]
    #uncover("4-")[#block[- the same three for the *GID*, and the *supplementary groups*]]
    #uncover("5-")[#block[- usually *all the same*, but not always]]
  ][
    #set text(size: 0.7em)
    // side by side: stacked, the two cards do not fit above the tips
    #align(center, grid(
      columns: (auto, auto),
      column-gutter: 0.8em,
      {
        for step in range(1, 5) {
          let focus = ((0,), (1,), (2,), ("groups",)).at(step - 1)
          only(step, cred-card("bash", (1000, 1000, 1000), gids: (1000, 1000, 1000), groups: "27 1000 1100", focus: focus))
        }
        only("5-", cred-card("bash", (1000, 1000, 1000), gids: (1000, 1000, 1000), groups: "27 1000 1100"))
      },
      uncover("5-", cred-card("passwd", (1000, 0, 0), gids: (1000, 1000, 1000), groups: "27 1000 1100", changed: (1, 2))),
    ))
  ]

  #v(0.4em)
  #for (i, note) in credential-notes.enumerate() {
    only(if i == credential-notes.len() - 1 { str(i + 1) + "-" } else { i + 1 }, note)
  }
]

#slide[
  == Seeing the Credentials
  👀 `ps` and `/proc` show the ID card of any process

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #reveal-terminal(before: none, lines: (3, 7, 10), full: false)[```terminal
    $ ps -o pid,ruser,euser,suser,comm -p $$
        PID RUSER    EUSER    SUSER    COMMAND
       4242 alice    alice    alice    bash
    $ grep -E '^(Uid|Gid|Groups):' /proc/$$/status
    Uid:    1000    1000    1000    1000
    Gid:    1000    1000    1000    1000
    Groups: 27 1000 1100
    $ ps -o pid,ruser,euser,suser,comm -C passwd
        PID RUSER    EUSER    SUSER    COMMAND
       4250 alice    root     root     passwd
    ```]
  ][
    #set text(size: 0.85em)
    - `ruser`, `euser`, `suser` - the *real*, *effective* and *saved* user
    #uncover("2-")[#block[- `/proc/<PID>/status`: `Uid:` and `Gid:` are real, effective, saved, file system]]
    #uncover("2-")[#block[- `Groups:` - the supplementary groups]]
    #uncover("3-")[#block[- `-C passwd` - the processes of the command `passwd`, started by `alice` in another terminal]]
  ]

  #v(0.6em)
  #only(1)[💡 `$$` is the PID of the shell itself: all three UIDs are `alice`]
  #only(2)[💡 everyone may read the `status` file of any process; the 4#super[th] number is the _file system_ UID or GID]
  #only("3-")[💡 `passwd` runs as `root` (_effective_), but the kernel still knows that `alice` started it (_real_)]
]

// ----- which credentials are checked -----

// a box that is not a process: what a process asks for
#let wish-box(body) = box(
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  align(center, body),
)

// A process asks the kernel for something: the kernel looks only at some of
// its credentials (the ones in focus), and at some of the target's.
// `checks` - one (process, action, question, target, allowed, why) per step.
// Every box is as big as the biggest one of all the steps, so the drawing
// stays in place from one step to the next; the targets hang from the top
// of their slot, so the arrow always touches them.
#let check-drawings(checks) = {
  set text(size: 0.8em)
  context {
    let size(items) = (
      width: calc.max(..items.map(x => measure(x).width)),
      height: calc.max(..items.map(x => measure(x).height)),
    )
    let slot(body, s, at: center + horizon) = box(width: s.width, height: s.height, align(at, body))
    let procs = checks.map(c => c.at(0))
    let kernel-width = size(checks.map(c => kernel-box(c.at(2)))).width
    let kernels = checks.map(c => kernel-box(c.at(2), width: kernel-width))
    let targets = checks.map(c => c.at(3))
    let verdicts = checks.map(c => verdict(c.at(4), c.at(5)))
    let (ps, ks, ts, vs) = (size(procs), size(kernels), size(targets), size(verdicts))
    let drawings = checks.enumerate().map(((i, c)) => diagram(
      spacing: (2em, 1.6em),
      thing((0, 0), slot(procs.at(i), ps, at: center + bottom)),
      step-arrow((0, 0), (0, 1), c.at(1)),
      thing((0, 1), slot(kernels.at(i), ks)),
      step-arrow((0, 1), (0, 2), none),
      thing((0, 2), slot(targets.at(i), ts, at: center + top)),
      thing((0, 2.75), slot(verdicts.at(i), vs)),
    ))
    // the labels of the arrows stick out on the right, by different
    // lengths: left-aligned in a box as wide as the widest drawing, the
    // boxes do not move sideways either
    let width = size(drawings).width
    for (i, d) in drawings.enumerate() {
      only(if i == checks.len() - 1 { str(i + 1) + "-" } else { i + 1 }, align(center, box(width: width, align(left, d))))
    }
  }
}

#let alice-cat = cred-card("cat", (1000, 1000, 1000), focus: (1,))
#let alice-bash = cred-card("bash", (1000, 1000, 1000), focus: (0, 1))
#let bob-bash = cred-card("bash", (1001, 1001, 1001), focus: (0, 1))
#let her-passwd = cred-card("passwd", (1000, 0, 0), focus: (0, 2))
#let alice-python = cred-card("python3", (1000, 1000, 1000), focus: (0, 1, 2))

#let checks = (
  (alice-cat, [`open("/etc/shadow")`], [effective UID = \ the owner of the file?], file-box("/etc/shadow", "root", "shadow", "-rw-r-----"), false, [`1000` is not `root`]),
  (alice-bash, [`kill(4250)`], [sender real or effective = \ target real or saved?], her-passwd, true, [`1000` started it]),
  (bob-bash, [`kill(4250)`], [sender real or effective = \ target real or saved?], her-passwd, false, [`1001` did not start it]),
  (alice-python, [`setuid(0)`], [is 0 one of \ its three UIDs?], wish-box[👑 become `root`, UID `0`], false, [it is not]),
)

#slide[
  == Which Credentials Are Checked
  🔍 it depends on what the process asks for

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - 📄 *open a file* - the _effective_ UID and GIDs, against the owner and group of the file
    #uncover("2-")[#block[- 📡 *send a signal* - the _real_ or _effective_ UID of the sender, against the _real_ or _saved_ UID of the target]]
    #uncover("4-")[#block[- 🔄 *change its own UIDs* - only to a UID it *already has*]]
    #uncover("4-")[#block[- 👑 only an effective UID `0` may take *any* UID]]
  ][
    #check-drawings(checks)
  ]

  #place(bottom + left)[
    #only(1)[💡 `cat` runs as `alice`, `/etc/shadow` belongs to `root`]
    #only(2)[💡 `alice` may stop the `passwd` she started, even if it runs as `root`: its _real_ UID is hers]
    #only(3)[💡 `bob` may not: none of his UIDs is a UID of that `passwd`]
    #only("4-")[💡 a process *cannot* make itself `root`]
  ]
]

// ----- how the label changes -----

// one change of the credentials: before, what happens, after, and why
// (orange arrow: the UIDs change)
#let change-row(step, before, action, after, note, color: arrow-gray) = (
  uncover(str(step) + "-", before),
  uncover(str(step) + "-", labeled-arrow(action, color: color, length: 7em)),
  uncover(str(step) + "-", after),
  uncover(str(step) + "-", align(left, note)),
)

#slide[
  == How the Label Changes
  🧬 a process gets its label from its parent

  #set text(size: 0.8em)
  #align(center, grid(
    columns: (auto, auto, auto, 1fr),
    column-gutter: 0.8em,
    row-gutter: 0.35em,
    align: center + horizon,
    ..change-row(1,
      cred-card("bash", (1000, 1000, 1000)),
      [`fork()`],
      cred-card("bash", (1000, 1000, 1000)),
      [🧬 the child gets a *copy*]),
    ..change-row(2,
      cred-card("bash", (1000, 1000, 1000), labels: false),
      [`exec("ls")`],
      cred-card("ls", (1000, 1000, 1000), labels: false),
      [➖ a regular program: *nothing* changes]),
    ..change-row(3,
      cred-card("bash", (1000, 1000, 1000), labels: false),
      [`exec("passwd")`],
      cred-card("passwd", (1000, 0, 0), changed: (1, 2), labels: false),
      [🪄 a `setuid` file: _effective_ and _saved_ become the *owner* of the file, `root`],
      color: hl),
    ..change-row(4,
      cred-card("login", (0, 0, 0), labels: false),
      [`setuid(1000)`],
      cred-card("login", (1000, 1000, 1000), changed: (0, 1, 2), labels: false),
      [👑 only `root` may: *all* the UIDs change, this is how `login`, `su` and `sudo` work],
      color: hl),
  ))

  #place(bottom + left, text(size: 1.25em)[
    #only(4)[⚠️ after `setuid(1000)` no UID is `0` any more: the process can *never* go back to `root`]
  ])
]
