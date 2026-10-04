#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Sessions and Terminals #text(size: 10pt, weight: "regular")[\ _How the processes of a terminal are grouped_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.3.3 - _Foreground și background_
      - Section 4.5.2 - _Semnale_
]

// Sessions, process groups and the controlling terminal, in one drawing:
// the terminal on top, the session (dashed) below it, the process groups
// (tinted boxes) inside the session, the processes inside their groups.
// The steps follow the terminal on the left:
// 1 - only the shell, 2 - a job with two processes, 3 - a job started with
// `nohup`, 4 - `ps` in the foreground, 5 - the leaders, 6 - the terminal closes.
// Every part keeps its space on every step, so nothing shifts.
// `kill`: 0 - as above, 1 - `bash` was killed (SIGKILL), 2 - and then the
// terminal closed (used with step 3, for `When bash Is Killed`)
#let session-schematic(step, kill: 0) = {
  let shown(from, body) = if step >= from { body } else { hide(body) }
  let leaders = step == 5
  let closed = step == 6
  let killed = kill >= 1
  // the terminal is shown closed (gray)
  let term-closed = closed or kill == 2
  let green = rgb("2e7d32")
  // the five columns: bash, job 1 (two columns), job 2, ps
  let (c-bash, c-job1, c-job2, c-ps) = (0.1, 0.4, 0.7, 0.9)
  // the foreground group gets the input: bash at the prompt, `ps` while it runs
  let fg = if closed or killed { none } else if step == 4 or step == 5 { "ps" } else { "bash" }

  // the ID of a session or a group
  let id(n) = text(weight: "bold", n)
  // a process: its name, its PID (or what happened to it at the end)
  // the session leader is always shown
  let sl-shown = true
  let proc(name, pid, mark: none, end: none, sl: false) = {
    let lead = (leaders and mark != none) or (sl and sl-shown)
    let badge = text(size: 0.8em, if mark == none [⭐] else { mark })
    let gone = (closed and end == "gone") or (killed and name == "bash")
    box(
      width: 100%,
      inset: (x: 0.2em, y: 0.3em),
      radius: 0.3em,
      // a leader is shown only by its emoji
      stroke: if gone { (paint: luma(170), thickness: 0.8pt, dash: "dashed") } else { 0.8pt + luma(150) },
      fill: white,
      align(center)[
        #if lead { badge } else { hide(badge) }#text(font: mono, size: 0.85em, fill: if gone { luma(160) } else { black }, name) \
        #text(size: 0.65em, fill: luma(110))[#if killed { if name == "bash" [💀 killed] else [✅ #pid] } else [#if closed and end == "ends" [❌ ] else if closed and end == "runs" [✅ ] else if gone [ended ]#pid]]
      ],
    )
  }
  // a process group: a container (not a process) around its processes
  let group(pgid, what, ..procs, fg: false) = block(
    width: 100%,
    inset: (x: 0.25em, top: 0.25em, bottom: 0.3em),
    radius: 0.5em,
    stroke: if fg { 2pt + accent } else { 1pt + luma(150) },
    fill: rgb("eef3f5"),
    {
      // two lines on every group, so all the groups have the same height
      align(center, text(size: 0.68em)[group #id(pgid) \ #text(fill: if fg { accent } else { luma(100) }, weight: if fg { "bold" } else { "regular" }, what)])
      v(0.05em)
      grid(columns: procs.pos().len(), column-gutter: 0.25em, ..procs.pos())
    },
  )
  // an arrow down at `x` (a fraction of the width) with a label on its right
  let arrow-at(x, lh, color, label: none) = {
    place(top + left, dx: x * 100% - 0.35em, rotate(90deg, reflow: true, draw-arrow(length: lh, color: color, thickness: 1.1pt)))
    if label != none {
      place(top + left, dx: x * 100% + 0.45em, dy: lh / 2 - 0.45em, text(size: 0.6em, fill: color, label))
    }
  }
  // the nohup shield, below job 2 (SIGHUP comes from bash)
  let shield(hit) = box(
    width: 100%,
    inset: (y: 0.15em),
    radius: 0.25em,
    fill: rgb("e8f5e9"),
    stroke: 1.5pt + green,
    align(center, text(size: 0.6em, fill: green)[🛡️ `nohup` #if hit [✋]]),
  )

  set block(spacing: 0.1em)
  set par(spacing: 0.1em)
  set text(size: 1.08em)
  // the controlling terminal: one for the whole session
  align(center, box(
    width: 85%,
    fill: if term-closed { luma(150) } else { accent },
    radius: 0.3em,
    inset: (x: 0.6em, y: 0.3em),
    text(fill: white, size: 0.85em)[
      🖥️ #text(font: mono, weight: "bold")[/dev/pts/0] #h(0.2em) #text(size: 0.85em, style: "italic")[#if term-closed [closed] else if killed [no session] else [the controlling terminal of session #id("3000")]] \
      #text(size: 0.8em)[🐧 the *terminal driver*, in the kernel]
    ],
  ))
  // between the terminal and the session: one link, the input, SIGHUP
  box(width: 100%, height: 1.4em, {
    if killed {
      // the session lost its terminal
      place(top + left, dx: 50%, line(start: (0pt, 0pt), end: (0pt, 1.4em), stroke: (paint: luma(170), thickness: 1pt, dash: "dotted")))
      place(top + left, dx: 50% + 0.4em, dy: 0.35em, text(size: 0.6em, fill: luma(130), style: "italic")[detached: the session has no terminal])
    } else {
      place(top + left, dx: 50%, line(start: (0pt, 0pt), end: (0pt, 1.4em), stroke: 1.2pt + accent))
    }
    if killed { }
    else if closed { arrow-at(c-bash, 1.4em, changed, label: [🐧 `SIGHUP`]) }
    else if fg == "ps" {
      arrow-at(c-ps, 1.4em, accent)
      place(top + left, dx: c-ps * 100% - 3em, dy: 0.35em, text(size: 0.6em, fill: accent)[⌨️ input])
    } else { arrow-at(c-bash, 1.4em, accent, label: [⌨️ input]) }
  })
  // the session surrounds all the groups of the terminal
  block(
    width: 100%,
    inset: (x: 0.35em, top: 0.1em, bottom: 0.5em),
    radius: 0.45em,
    stroke: (paint: accent, thickness: 1.2pt, dash: "dashed"),
    {
      // what comes from the terminal: the input, or SIGHUP for bash at the end
      set block(spacing: 0.15em)
      set par(spacing: 0.15em)
      box(width: 100%, height: 1.2em, {
        if killed { }
        else if closed { arrow-at(c-bash, 1.2em, changed) }
        else { arrow-at(if fg == "ps" { c-ps } else { c-bash }, 1.2em, accent) }
      })
      grid(
        columns: (1fr,) * 5,
        column-gutter: 0.3em,
        align: center + bottom,
        group("3000", if killed [killed] else if fg == "bash" [foreground] else [the shell], fg: fg == "bash", proc("bash", "3000", mark: [👑], end: "ends", sl: true)),
        grid.cell(colspan: 2, shown(2, group("4242", [job `[1]`], proc("sleep", "4242", mark: [⭐], end: "ends"), proc("cat", "4243", end: "ends")))),
        shown(3, group("4244", [job `[2]`], proc("sleep", "4244", mark: [⭐], end: "runs"))),
        shown(4, group("4250", if closed [ended] else [foreground], fg: fg == "ps", proc("ps", "4250", mark: [⭐], end: "gone"))),
      )
      // below the groups: bash forwards SIGHUP to its jobs (at the end),
      // job 2 is behind the nohup shield
      box(width: 100%, height: 1.9em, {
        let y = 1.55em
        let s = 1.1pt + changed
        // the shield, right under job 2
        if step >= 3 { place(top + left, dx: 60% + 0.3em, box(width: 20% - 0.6em, shield(closed))) }
        if closed {
          // from bash down, then right, to the jobs
          place(top + left, line(start: (c-bash * 100%, 0pt), end: (c-bash * 100%, y), stroke: s))
          place(top + left, line(start: (c-bash * 100%, y), end: (c-job2 * 100%, y), stroke: s))
          // up into job 1, up into the shield of job 2
          place(top + left, dx: c-job1 * 100% - 0.35em, rotate(-90deg, reflow: true, draw-arrow(length: y, color: changed, thickness: 1.1pt)))
          place(top + left, dx: c-job2 * 100% - 0.35em, dy: 0.95em, rotate(-90deg, reflow: true, draw-arrow(length: y - 0.95em, color: changed, thickness: 1.1pt)))
          place(top + left, dx: c-bash * 100% + 0.4em, dy: y - 1.05em, text(size: 0.6em, fill: changed)[`bash` forwards `SIGHUP`])
        }
      })
      // the name of the session, on its border
      place(bottom + right, dx: -0.3em, dy: 0.85em, box(fill: white, inset: (x: 0.25em, y: 0.1em), text(size: 0.7em, fill: accent)[session #id("3000")]))
    },
  )
  // the legend of the leaders
  v(0.9em)
  shown(5, align(center, text(size: 0.65em, if leaders [
    👑 *session leader*: its PID is the `SID` #h(1em) ⭐ *group leader*: its PID is the `PGID`
  ] else [
    #hide[👑 *session leader*: its PID is the `SID`]
  ])))
}

#slide[
  == Sessions and the Terminal
  How the kernel groups the processes of a terminal

  #toolbox.side-by-side(columns: (5fr, 7fr), gutter: 1em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 7, 14), full: false)[```terminal
    $ echo $$
    3000
    $ sleep 100 | cat &
    [1] 4243
    $ nohup sleep 200 > /dev/null &
    [2] 4244
    nohup: ignoring input
    $ ps -o pid,pgid,sid,stat,comm
        PID    PGID     SID STAT COMMAND
       3000    3000    3000 Ss   bash
       4242    4242    3000 S    sleep
       4243    4242    3000 S    cat
       4244    4244    3000 S    sleep
       4250    4250    3000 R+   ps
    ```]
  ][
    #for (i, when) in ("1", "2", "3", "4", "5", "6-").enumerate() {
      only(when, session-schematic(i + 1))
    }
  ]

  #set text(size: 0.85em)
  #only(1)[👑 the shell starts a new *session*: a session has *one* controlling terminal, `/dev/pts/0`\
    ⌨️ the input of the terminal goes to the *foreground* group, now `bash` (`$$` is its PID)]
  #only(2)[💡 a *process group*: one job, `sleep 100 | cat` is *one* group of two processes\
    💡 a signal (#kbd("Ctrl") + #kbd("C")) reaches the whole group]
  #only(3)[🛡️ `nohup` makes the program *ignore* `SIGHUP`: a shield against it]
  #only(4)[💡 a *session*: all the groups of one terminal, the same `SID`\
    ⌨️ only the *foreground* (`+`) reads the input, a background job that reads gets `SIGTTIN` (stopped)]
  #only(5)[⭐ the *group leader*: the first process of the group, its PID is the `PGID`\
    👑 the *session leader*: the process that started the session, its PID is the `SID`]
  #only("6-")[🐧 when the terminal closes, the *terminal driver* sends `SIGHUP` to the session leader, `bash`\
    💡 `bash` sends it to its jobs: ❌ job `[1]` ends, 🛡️ job `[2]` ignores it and keeps running]
]

#slide[
  == When `bash` Is Killed
  `SIGKILL` cannot be caught: the shell cannot forward `SIGHUP` any more

  #toolbox.side-by-side(columns: (5fr, 7fr), gutter: 1em)[
    #set text(size: 0.72em)
    // two terminals: the one of the session, and another one to kill bash
    #let caption(body) = text(size: 0.85em, fill: luma(100), style: "italic", body)
    #caption[🖥️ terminal `/dev/pts/0` (`bash`, PID 3000)#only("4-")[, closed]]
    #reveal-terminal(before: none, lines: (5,), full: false)[```terminal
    $ sleep 100 | cat &
    [1] 4243
    $ nohup sleep 200 > /dev/null &
    [2] 4244
    nohup: ignoring input
    ```]
    #v(0.1em)
    #uncover("2-", caption[🖥️ another terminal, `/dev/pts/1`])
    #reveal-terminal(start: 2, before: none, lines: (1, 6), full: false)[```terminal
    $ kill -KILL 3000
    $ ps -o pid,ppid,sid,tty,comm -s 3000
        PID    PPID     SID TT       COMMAND
       4242       1    3000 ?        sleep
       4243       1    3000 ?        cat
       4244       1    3000 ?        sleep
    ```]
  ][
    #only(1, session-schematic(3))
    #only("2-3", session-schematic(3, kill: 1))
    #only("4-", session-schematic(3, kill: 2))
  ]

  #set text(size: 0.85em)
  #only(1)[💡 two jobs in the session of `bash`, as before]
  #only(2)[💀 `SIGKILL` cannot be caught: `bash` ends at once, it cannot forward anything\
    🐧 the session leader ended: the kernel detaches the terminal from the session]
  #only(3)[💡 the jobs keep running: no controlling terminal (`TT` is `?`), their new parent is PID 1]
  #only("4-")[🔌 the terminal closes: no `SIGHUP` reaches the jobs, they keep running in the background]
]

#slide[
  == Keys and Signals
  The terminal turns some keys into signals for the *foreground* process

  #set text(size: 0.9em)
  #table(
    columns: (auto, auto, 1fr),
    table.header([Keys], [Sends], [Default action]),
    [#kbd("Ctrl") + #kbd("C")], [`SIGINT`], [_terminate_ (interrupt) the process],
    [#kbd("Ctrl") + #kbd("Z")], [`SIGTSTP`], [_stop_ the process, it becomes a stopped job],
    [#kbd("Ctrl") + #kbd("\\")], [`SIGQUIT`], [_terminate_ the process and write a core dump],
    [#kbd("Ctrl") + #kbd("D")], [no signal], [_end of file_: `stdin` has nothing more to read],
  )

  #uncover("2-")[💡 a *job* that tries to read the keyboard receives `SIGTTIN` and is _stopped_, only the foreground process can read it]

  #uncover("3-")[💡 `bg` and `fg` send `SIGCONT` to continue a stopped job]
]

// Ctrl+C and Ctrl+Z, drawn like `Sessions and the Terminal`: the key, the
// terminal (the terminal driver), the session with the shell and the
// foreground job (a group of two processes).
// Steps: 1 - a foreground job, 2 - Ctrl+C, 3 - a new foreground job,
// 4 - Ctrl+Z. Every part keeps its space on every step, so nothing shifts.
#let keys-schematic(step) = {
  let shown(from, body) = if step >= from { body } else { hide(body) }
  // the key pressed on this step (none: no key): Ctrl+C, Ctrl+\, Ctrl+Z
  let key = if step == 2 { "C" } else if step == 4 { "\\" } else if step == 6 { "Z" } else { none }
  let signal = if step == 2 { "SIGINT" } else if step == 4 { "SIGQUIT" } else if step == 6 { "SIGTSTP" } else { none }
  // the job: its PIDs and what happens to it, a new job every two steps
  let (pgid, p2) = if step <= 2 { ("4300", "4301") } else if step <= 4 { ("4310", "4311") } else { ("4320", "4321") }
  let state = if step == 2 or step == 4 { "ended" } else if step == 6 { "stopped" } else { "running" }
  let (c-bash, c-job) = (1 / 6, 2 / 3)

  // a process: its name and its PID, or what happened to it
  let proc(name, pid, hit: false, sl: false) = box(
    width: 100%,
    inset: (x: 0.2em, y: 0.3em),
    radius: 0.3em,
    stroke: if hit { 1.5pt + changed } else { 0.8pt + luma(150) },
    fill: if hit { changed-fill } else { white },
    align(center)[
      #if sl { text(size: 0.8em)[👑] }#text(font: mono, size: 0.85em, fill: if hit { changed } else { black }, name) \
      #box(height: 1em, text(size: 0.65em, fill: luma(110))[#if state == "ended" and hit [❌ ended] else if state == "stopped" and hit [⏸️ stopped] else [PID #pid]])
    ],
  )
  // a process group: a container around its processes
  let group(id, what, ..procs, fg: false) = block(
    width: 100%,
    inset: (x: 0.25em, top: 0.25em, bottom: 0.3em),
    radius: 0.5em,
    stroke: if fg { 2pt + accent } else { 1pt + luma(150) },
    fill: rgb("eef3f5"),
    {
      align(center, text(size: 0.68em)[group *#id* \ #text(fill: if fg { accent } else { luma(100) }, weight: if fg { "bold" } else { "regular" }, what)])
      v(0.05em)
      grid(columns: procs.pos().len(), column-gutter: 0.25em, ..procs.pos())
    },
  )
  // an arrow down at `x` (a fraction of the width) with a label on its left
  let arrow-at(x, lh, color, label: none) = {
    place(top + left, dx: x * 100% - 0.35em, rotate(90deg, reflow: true, draw-arrow(length: lh, color: color, thickness: 1.1pt)))
    if label != none {
      place(top + right, dx: -(1 - x) * 100% - 0.6em, dy: lh / 2 - 0.5em, text(size: 0.65em, fill: color, label))
    }
  }

  set block(spacing: 0.1em)
  set par(spacing: 0.1em)
  set text(size: 1.2em)
  // the key and what the terminal emulator makes of it
  {
    let pressed(k) = [⌨️ #kbd("Ctrl") + #kbd(k) #h(0.3em) #draw-arrow(length: 1.2em) #h(0.3em) the emulator writes the character #text(font: mono, fill: changed)[^#k]]
    align(center, box(height: 1.4em, text(size: 0.75em, if key == none { hide(pressed("C")) } else { pressed(key) })))
  }
  v(0.3em)
  // the terminal
  align(center, box(
    width: 85%,
    fill: accent,
    radius: 0.3em,
    inset: (x: 0.6em, y: 0.3em),
    text(fill: white, size: 0.85em)[
      🖥️ #text(font: mono, weight: "bold")[/dev/pts/0] #h(0.2em) #text(size: 0.85em, style: "italic")[the controlling terminal] \
      #box(height: 1.1em, text(size: 0.8em)[🐧 the *terminal driver*: #if key == none [the input goes to the foreground] else [#text(font: mono)[^#key] becomes #text(font: mono, signal)]])
    ],
  ))
  // the input, or the signal, to the foreground job
  box(width: 100%, height: 1.6em, {
    if signal != none { arrow-at(c-job, 1.6em, changed, label: [🐧 #raw(signal) to the whole group]) }
    else { arrow-at(c-job, 1.6em, accent, label: [⌨️ input]) }
  })
  // the session
  block(
    width: 100%,
    inset: (x: 0.35em, top: 0.45em, bottom: 0.5em),
    radius: 0.45em,
    stroke: (paint: accent, thickness: 1.2pt, dash: "dashed"),
    {
      grid(
        columns: (1fr, 2fr),
        column-gutter: 0.3em,
        align: center + bottom,
        group("3000", if state == "running" [waits] else [foreground again], fg: state != "running", proc("bash", "3000", sl: true)),
        group(pgid, if state == "running" [foreground] else if state == "ended" [ended] else [job `[1]`, stopped], fg: state == "running",
          proc("sleep", pgid, hit: signal != none), proc("cat", p2, hit: signal != none)),
      )
      place(bottom + right, dx: -0.3em, dy: 0.85em, box(fill: white, inset: (x: 0.25em, y: 0.1em), text(size: 0.7em, fill: accent)[session *3000*]))
    },
  )
}

#slide[
  == Ctrl+C, Ctrl+\\ and Ctrl+Z
  The terminal driver turns three keys into signals for the *foreground* group

  #toolbox.side-by-side(columns: (5fr, 7fr), gutter: 1em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 2, 4, 7), full: false)[```terminal
    $ sleep 100 | cat
    ^C
    $ sleep 200 | cat
    ^\Quit
    $ sleep 300 | cat
    ^Z
    [1]+  Stopped        sleep 300 | cat
    ```]
  ][
    // every key with a new job: the steps 1, 2, 4 and 6 of the drawing
    #for (when, k) in (("1", 1), ("2", 2), ("3", 4), ("4-", 6)) {
      only(when, keys-schematic(k))
    }
  ]

  #set text(size: 0.85em)
  #only(1)[⌨️ `sleep 100 | cat` is the *foreground* group: it gets the input, `bash` waits for it]
  #only(2)[🐧 the terminal driver sends `SIGINT` to *every* process of the foreground group\
    ❌ `sleep` and `cat` end, `bash` gets the terminal back and shows the prompt]
  #only(3)[🐧 a new job, #kbd("Ctrl") + #kbd("\\") becomes `SIGQUIT`: the whole group ends, like #kbd("Ctrl") + #kbd("C")\
    💡 it also writes a *core dump* (a copy of the memory, for debugging), if `ulimit -c` allows it]
  #only("4-")[🐧 a new job, #kbd("Ctrl") + #kbd("Z") becomes `SIGTSTP`: the whole group is *stopped*, not ended\
    💡 `bash` gets the terminal back, the group becomes job `[1]`, `fg` continues it]
]
