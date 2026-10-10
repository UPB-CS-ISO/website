#import "/src/slides.typ": *
#import "streams.typ": fd, draw-arrow, stream-accent, stream-changed, stream-changed-fill, stream-mono, stream-unused

// A process drawn as a card: what the kernel keeps about it.
//
//   ┌ bash ─────── PID 100 ┐
//   │ program   /bin/bash  │
//   │ memory    ...        │
//   │ FD table  (0)(1)(2)  │
//   │ fork()    → 101      │
//   └──────────────────────┘
//
// `changed` lists the rows that are different from the previous step
// (drawn in orange): "pid", "program", "memory", "fds", "note".
// `done` grays the whole card out (the process has ended).
// `fd-changed` lists the file descriptors drawn in orange (a redirect
// changed them), `fd-note` says where they point to now.
#let proc-card(
  name: "",
  pid: 0,
  ppid: none,
  program: "",
  memory: [],
  note: none,
  changed: (),
  done: false,
  fd-changed: (),
  fd-note: none,
) = {
  let ink(key, body) = if done {
    text(fill: stream-unused, body)
  } else if key in changed {
    text(fill: stream-changed, weight: "bold", body)
  } else { body }
  let mono(s) = text(font: stream-mono, size: 0.85em, s)
  let header-fill = if done { stream-unused } else if "program" in changed { stream-changed } else { stream-accent }
  let pid-text = [PID #pid] + if ppid != none [ · PPID #ppid]

  block(
    width: 100%,
    radius: 0.3em,
    clip: true,
    stroke: if done { (paint: stream-unused, thickness: 0.8pt, dash: "dashed") } else { 0.8pt + luma(150) },
    fill: white,
  )[
    #block(width: 100%, fill: header-fill, inset: (x: 0.6em, y: 0.45em), below: 0pt)[
      #text(fill: white, weight: "bold", font: stream-mono, size: 0.9em, name)
      #h(1fr)
      #text(fill: white, size: 0.8em, if "pid" in changed { strong(pid-text) } else { pid-text })
    ]
    // same height on every step, whatever the rows contain
    #block(width: 100%, height: 5.6em, inset: (x: 0.6em, y: 0.5em), above: 0pt)[
      #set text(size: 0.8em)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 0.8em,
        row-gutter: 0.6em,
        align: (left + horizon, left + horizon),
        ink("program", [program]), ink("program", mono(program)),
        ink("memory", [memory]), ink("memory", memory),
        ink("fds", [FD table]),
        if done { ink("fds", [_freed_]) } else {
          let c(n) = "fds" in changed or n in fd-changed
          [#fd(0, changed: c(0), size: 1.3em) #fd(1, changed: c(1), size: 1.3em) #fd(2, changed: c(2), size: 1.3em)]
          if fd-note != none [#h(0.4em) #text(fill: stream-changed, weight: "bold", fd-note)]
        },
        ..if note != none { (ink("note", note.at(0)), ink("note", note.at(1))) },
      )
    ]
  ]
}

// the arrow from the parent to the child, labeled with the system call
#let call-arrow(label, changed: true) = {
  let c = if changed { stream-changed } else { luma(120) }
  align(center + horizon)[
    #text(font: stream-mono, size: 0.75em, weight: "bold", fill: c, label) \
    #draw-arrow(length: 2.4em, color: c)
  ]
}

#let bash-card(note: none, changed: ()) = proc-card(
  name: "bash",
  pid: 100,
  program: "/bin/bash",
  memory: [`bash` code, shell variables],
  note: note,
  changed: changed,
)

// a system call a process makes on *itself* (`exec`, `waitpid`, `exit`):
// a loop that leaves the top of the card and comes back into it
#let self-call(label, changed: true) = {
  let c = if changed { stream-changed } else { luma(120) }
  let w = 3.2em
  let lh = 1.3em
  align(center, box(height: lh + 0.2em)[
    #box(baseline: -0.2em, text(font: stream-mono, size: 0.75em, weight: "bold", fill: c, label))
    #h(0.3em)
    #box(width: w, height: lh, {
      place(curve(
        stroke: 1.5pt + c,
        curve.move((0.4em, lh)),
        curve.cubic((0.4em, -0.4em), (w - 0.4em, -0.4em), (w - 0.4em, lh - 0.35em)),
      ))
      // the arrow head, pointing down, into the card
      place(polygon(
        fill: c,
        (w - 0.75em, lh - 0.45em),
        (w - 0.05em, lh - 0.45em),
        (w - 0.4em, lh + 0.05em),
      ))
    })
  ])
}

// one step of the schematic: the parent, the arrow and the child,
// with the calls each process makes on itself drawn above it
// (the row above is always there, so the cards do not move between steps)
#let fork-step(parent, arrow, child, parent-call: none, child-call: none) = grid(
  columns: (1fr, auto, 1fr),
  column-gutter: 1em,
  row-gutter: 0.1em,
  align: (center + bottom, center + horizon, center + bottom),
  if parent-call == none { hide(self-call("x")) } else { parent-call },
  [],
  if child-call == none { hide(self-call("x")) } else { child-call },
  parent, arrow, child,
)

// where `1` points to after the redirect
#let to-file = [`1` #draw-arrow(length: 1.2em, color: stream-changed, thickness: 1.2pt) `files.txt`]

// The fork / exec slide, `redirect: true` adds the step where the clone
// performs the redirect (`ls -l > files.txt`) before `exec`.
#let fork-exec(redirect: false) = {
  let command = if redirect { "ls -l > files.txt" } else { "ls -l" }
  // after the redirect, `1` of the child points to `files.txt`
  let fds = if redirect { (fd-changed: (1,), fd-note: to-file) } else { (:) }

  let parent-starts = fork-step(
    bash-card(note: ([next], [`fork()`])),
    hide(call-arrow("fork()")),
    hide(bash-card()),
  )
  let forked = fork-step(
    bash-card(note: ([`fork()`], [returned `101`]), changed: ("note",)),
    call-arrow("fork()"),
    proc-card(
      name: "bash",
      pid: 101,
      ppid: 100,
      program: "/bin/bash",
      memory: [a *copy* of the parent's],
      note: ([`fork()`], [returned `0`]),
      changed: ("pid", "note"),
    ),
  )
  let redirected = fork-step(
    bash-card(note: ([`fork()`], [returned `101`])),
    call-arrow("fork()", changed: false),
    child-call: self-call("open() dup2()"),
    proc-card(
      name: "bash",
      pid: 101,
      ppid: 100,
      program: "/bin/bash",
      memory: [a *copy* of the parent's],
      note: ([redirect], [`> files.txt`]),
      changed: ("note",),
      ..fds,
    ),
  )
  let execed = fork-step(
    bash-card(note: ([`waitpid()`], [waits for `101`]), changed: ("note",)),
    call-arrow("fork()", changed: false),
    parent-call: self-call("waitpid()"),
    child-call: self-call("exec()"),
    proc-card(
      name: "ls",
      pid: 101,
      ppid: 100,
      program: "/bin/ls",
      memory: [`ls` code and data],
      note: ([arguments], [`ls`, `-l`]),
      changed: ("program", "memory", "note"),
      ..fds,
    ),
  )
  let exited = fork-step(
    bash-card(note: ([`waitpid()`], [exit code `0`]), changed: ("note",)),
    call-arrow("fork()", changed: false),
    parent-call: self-call("waitpid()"),
    child-call: self-call("exit(0)", changed: false),
    proc-card(
      name: "ls",
      pid: 101,
      ppid: 100,
      program: "/bin/ls",
      memory: [_freed_],
      note: ([exit code], [`0`]),
      done: true,
    ),
  )

  let notes = (
    [💡 the *parent* (`bash`) wants to start `ls -l`, it calls `fork()`],
    [💡 `fork` makes a *clone*: same program, memory and FD table, only the *PID* differs\
      `fork` returns *twice*: the child's PID to the parent and `0` to the child\
      ⚠️ if `fork` fails, it returns `-1` and there is *no child*],
    ..if redirect {
      ([💡 the *clone* (still `bash`) performs the *redirects*: it opens `files.txt` and places it at index `1` with `dup2`\
        only the child's FD table changes, the parent still writes to the display],)
    },
    if redirect {
      [💡 the child calls `exec`, which *replaces* its program and memory, but keeps the *PID* and the *FD table*: `ls` writes to `files.txt`\
        meanwhile, the parent calls `waitpid` and waits for the child\
        ⚠️ `exec` returns *only if it fails*: the child prints the error and exits]
    } else {
      [💡 the child calls `exec`, which *replaces* its program and memory, but keeps the *PID* and the *FD table*\
        meanwhile, the parent calls `waitpid` and waits for the child\
        ⚠️ `exec` returns *only if it fails*: the child prints the error and exits]
    },
    [💡 `ls` calls `exit(0)`, the parent's `waitpid` returns with the exit code `0`\
      until the parent reads it, the child stays a 🧟 _zombie_],
  )
  let steps = (parent-starts, forked, ..if redirect { (redirected,) }, execed, exited)

  let code = if redirect {
    ```c
    pid_t pid = fork();
    if (pid < 0) { perror("fork"); exit(1); } // no child
    if (pid == 0) {                            // child
        int fd = open("files.txt",
                      O_WRONLY | O_CREAT | O_TRUNC, 0644);
        dup2(fd, 1); close(fd);                // 1 -> files.txt
        execlp("ls", "ls", "-l", NULL);
        perror("execlp"); exit(127);           // exec failed
    }
    int status;                                // parent
    waitpid(pid, &status, 0);
    printf("exit code %d\n", WEXITSTATUS(status));
    ```
  } else {
    ```c
    pid_t pid = fork();
    if (pid < 0) { perror("fork"); exit(1); } // no child
    if (pid == 0) {                            // child
        execlp("ls", "ls", "-l", NULL);
        perror("execlp"); exit(127);           // exec failed
    }
    int status;                                // parent
    waitpid(pid, &status, 0);
    printf("exit code %d\n", WEXITSTATUS(status));
    ```
  }
  let code-steps = if redirect {
    ((1,), (1, 2, 3), (4, 5, 6), (7, 8, 11), (10, 11, 12))
  } else {
    ((1,), (1, 2, 3), (4, 5, 6, 8), (7, 8, 9))
  }

  slide[
    == #if redirect [`fork`, redirect, `exec`] else [How `fork` and `exec` work]
    The shell runs #raw(command)

    #block(width: 100%, above: 0.4em, below: 0.8em)[
      #set text(size: 0.95em)
      // the cards keep the same place on every step, only their contents change
      #for (i, step) in steps.enumerate() {
        if i == steps.len() - 1 { only((beginning: i + 1), step) } else { only(i + 1, step) }
      }
    ]

    #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
      #set text(size: 0.8em)
      #for (i, note) in notes.enumerate() {
        if i == notes.len() - 1 { only((beginning: i + 1), note) } else { only(i + 1, note) }
      }
    ][
      #set text(size: 0.66em)
      #set par(leading: 0.42em)
      #highlight-code(code-steps, code)
    ]
  ]
}

