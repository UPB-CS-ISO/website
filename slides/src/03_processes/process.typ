#import "/src/slides.typ": *
#import "tree.typ": *
#import "streams.typ": draw-arrow, stream-accent, stream-changed, stream-changed-fill, stream-mono

// a white background behind the diagrams, so they read well on any theme
#let diagram(path, ..args) = box(fill: white, inset: 5pt, radius: 0.3em, image(path, ..args))

#slide[
  = Process #text(size: 10pt, weight: "regular")[\ _From a file to an action_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 1 - _The Big Picture_
      - Section 1.3.1 - _Process Management_
    - Chapter 6 - _How User Space Starts_
      - Sections 6.2 - 6.3 - _Identifying Your init_, _systemd_
    - Chapter 8 - _A Closer Look at Processes and Resource Utilization_
      - Section 8.1 - _Tracking Processes_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Sections 4.1 - 4.3 - _Programe și procese_, _Resursele și atributele unui proces_, _Ierarhia de procese_
      - Section 4.9 - _Anexa: Internele pornirii unui proces. Loading_
    - Chapter 9 - _Pornirea sistemului_
      - Section 9.6 - _Pornirea init și a serviciilor de startup în Linux_
]

// A small executable file, drawn next to the loader diagram: a document
// (with a folded corner) holding its three parts. The parts that the current
// loading step uses are colored, the others are faded.
// `used` - some of "load", "code", "links".
#let small-executable(used) = {
  let mono(s) = text(font: stream-mono, size: 0.8em, s)
  let corner = 1.2em
  let outline = 1.2pt + luma(120)
  let part(key, fill, ink, pad, body) = {
    let on = key in used
    block(
      width: 100%,
      inset: (x: 0.5em, y: pad),
      radius: 0.35em,
      fill: if on { fill } else { luma(246) },
      stroke: if on { none } else { (paint: luma(205), thickness: 0.8pt, dash: "dashed") },
      below: 0.45em,
      align(center + horizon, text(
        fill: if on { ink } else { luma(175) },
        weight: if on { "bold" } else { "regular" },
        body,
      )),
    )
  }
  set text(size: 0.85em)
  v(1.2em)
  box(width: 100%, {
    // the page of the document, with its top right corner folded
    block(
      width: 100%,
      inset: (x: 0.7em, top: 0.6em, bottom: 0.25em),
      fill: white,
      stroke: outline,
      radius: (top-left: 0.4em, bottom-left: 0.4em, bottom-right: 0.4em),
    )[
      #align(center, text(weight: "bold")[📄 #mono("/bin/ls")])
      #v(-0.2em)
      #part("load", luma(85), white, 0.55em)[📋 how to load it]
      #part("code", stream-accent, white, 1.3em)[⚙️ the actual code]
      #part("links", stream-changed-fill, stream-changed, 0.55em)[🔗 links to libraries]
    ]
    // the folded corner: hide the corner of the page, draw the fold
    place(top + right, polygon(fill: white, (0pt, 0pt), (corner, 0pt), (corner, corner)))
    place(top + right, dx: 0pt, polygon(
      fill: luma(225),
      stroke: outline,
      (0pt, 0pt),
      (0pt, corner),
      (corner, corner),
    ))
  })
  v(-0.2em)
  align(center, text(size: 0.85em, fill: luma(110))[_Executable File_])
}

// An arrow pointing at a part of the loader diagram, placed over the image.
// `x`, `y` - where the tip of the arrow is, as a fraction of the image;
// `from` - the side the arrow comes from: "top" or "right".
#let pointer(x, y, from: "top") = {
  let length = 2.4em
  let a = draw-arrow(length: length, color: stream-changed, thickness: 2.5pt)
  if from == "top" {
    place(top + left, dx: x * 100% - 0.35em, dy: y * 100% - length, rotate(90deg, reflow: true, a))
  } else {
    place(top + left, dx: x * 100%, dy: y * 100% - 0.35em, scale(x: -100%, reflow: true, a))
  }
}

#slide[
  == Executable vs Process
  _Files_ to _actions_

  📁 one executable file ➡️ multiple processes ⚙️⚙️...⚙️

  #align(center)[#diagram("img/process/program-proc.pdf", height: 65%)]
]

#slide[
  == Loading an Executable

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1.5em)[
    #v(2em)
    #align(center)[
      #box(fill: white, inset: 5pt, radius: 0.3em)[
        #image("img/process/loader-actions.pdf", width: 100%)
        // the arrow shows the part of the loading explained on each step
        #only(2, pointer(0.205, 0.55))
        #only(3, pointer(0.40, 0.33, from: "right"))
        #only(4, pointer(0.56, 0.53))
        #only("5-", pointer(0.78, 0.47))
      ]
    ]
  ][
    #only(1)[
      #align(center)[
        #box(stroke: (paint: luma(120), dash: "dotted"), inset: 5pt, radius: 0.3em)[
          #image("img/os/os_stack.pdf", width: 100%)
        ]
      ]
    ]
    // from step 2, the parts of the executable file used by each step
    #only(2)[#small-executable("load")]
    #only(3)[#small-executable(("links",))]
    #only(4)[#small-executable(("code", "links"))]
    #only("5-")[#small-executable(("code",))]
  ]

  #set text(size: 0.9em)
  #only(1)[💡 the *loader* turns the program file into a running process, in a few steps]
  #only(2)[💡 *program loading*: the loader reads the executable and copies its code and data into memory]
  #only(3)[💡 *library loading*: it finds the libraries the program needs (`libc.so.6`, ...) and loads them too]
  #only(4)[💡 *runtime dynamic linking*: it connects the program's calls to the functions inside the libraries]
  #only(
    "5-",
  )[💡 *execution*: the processor jumps to the start of the program, the code of the program and of the libraries runs]
]

#slide[
  == Process' Resources

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === Identification
    - _PID_: #strong[P]rocess #strong[ID]
    - _PPID_: #strong[P]arent #strong[P]rocess #strong[ID]

    === ⚙️ Actions
    - one or multiple threads executing in parallel

    === 💾 Data
    - access to files
      - actual files
      - peripheral files (`/dev/...`)

    === 🧠 Memory
    - code
    - variables
  ][
    #align(center)[#diagram("img/process/process_resources.pdf", width: 85%)]
  ]
]

// the colors of the states in the process states diagram
#let state(name, color) = text(fill: color, weight: "bold", name)
#let ready = state("Ready", rgb("7cb342"))
#let running = state("Running", rgb("26a6b8"))
#let waiting = state("Waiting", rgb("e0a800"))
#let done = state("Done", rgb("2c4a7a"))

// where each state box is in the diagram, as fractions of the image:
// (x, y, width, height) of the box, and its color
#let state-boxes = (
  ready: ((0.273, 0.093, 0.200, 0.122), rgb("7cb342")),
  waiting: ((0.769, 0.093, 0.199, 0.122), rgb("e0a800")),
  running: ((0.516, 0.479, 0.199, 0.122), rgb("26a6b8")),
  done: ((0.516, 0.849, 0.199, 0.122), rgb("2c4a7a")),
)

// the process states diagram, with the box of the state `current`
// ("ready", "running", "waiting", "done") filled with its color
#let states-diagram(current) = box(fill: white, inset: 5pt, radius: 0.3em, layout(size => {
  let width = size.width
  let height = width * 760 / 1313 // the size of the image, in pixels
  image("img/process/process-states.pdf", width: width)
  if current != none {
    let ((x, y, w, h), color) = state-boxes.at(current)
    // see-through, so the name of the state stays readable
    place(top + left, dx: x * width, dy: y * height, rect(
      width: w * width,
      height: h * height,
      radius: 0.012 * width,
      fill: color.transparentize(55%),
    ))
  }
}))

// A `ps` listing where the processes in one state are highlighted with
// the color of that state: only the state (the first letter of `STAT`)
// and the command, the other letters of `STAT` stay plain;
// `hl` is the letter of the state ("S", "R", "Z")
#let ps-listing(hl, body) = {
  let colors = (R: rgb("26a6b8"), S: rgb("e0a800"), Z: rgb("2c4a7a"))
  // where the STAT column starts, taken from the header line
  let at = body.text.split("\n").find(l => l.contains("STAT")).position("STAT")
  show raw.line: it => {
    let t = it.text
    if t.starts-with("$ ") {
      return render-terminal-line(t)
    }
    if t.contains("STAT") or t.trim() == "..." or t.len() <= at {
      return text(fill: luma(100), t)
    }
    let letter = t.slice(at).first()
    if hl == letter and letter in colors {
      let c = colors.at(letter)
      // PID | state letter | the other letters of STAT | command
      let (pid, rest) = (t.slice(0, at), t.slice(at + 1))
      let (flags, command) = (rest.slice(0, 4), rest.slice(4))
      text(fill: c, weight: "bold", pid + letter)
      text(fill: luma(150), flags)
      text(fill: c, weight: "bold", command)
    } else {
      text(fill: luma(150), t)
    }
  }
  body
}

#let ps-example = ```
$ ps -e -o pid,stat,comm
    PID STAT COMMAND
      1 Ss   systemd
    ...
   4100 Ss   bash
   4210 S    sleep
   4211 R    yes
   4213 Sl   myapp
   4214 Z    myapp-worker <defunct>
   4220 R+   ps
```

#slide[
  == Process States

  #toolbox.side-by-side(columns: (11fr, 9fr), gutter: 1em)[
    #align(center + horizon)[
      #only(1)[#states-diagram("ready")]
      #only(2)[#states-diagram("running")]
      #only(3)[#states-diagram("waiting")]
      #only("4-")[#states-diagram("done")]
    ]
  ][
    #set text(size: 1em)
    #only("1-2")[#ps-listing("R", ps-example)]
    #only(3)[#ps-listing("S", ps-example)]
    #only("4-")[#ps-listing("Z", ps-example)]
  ]

  #v(0.5em)
  #only(1)[
    #ready - has everything it needs, waits for a free *processor* \
    in `ps` it is `R`, like #running: `ps` cannot tell them apart
  ]
  #only(2)[
    #running - its code runs on a processor; when its _time slice_ expires, it goes back to #ready \
    `R` in `ps`: `yes` computes all the time, `ps` runs while it makes the list
  ]
  #only(3)[
    #waiting - waits for an *event*: data from the disk, a key press, a network packet; it does not use the processor \
    `S` (_sleeping_) in `ps`: `bash` waits for you to type, `sleep` waits for its timer
  ]
  #only("4-")[
    #done - it has finished (`exit`), it waits for the parent to read its _exit code_ \
    `Z` (_zombie_#footnote[_zombie_ processes are explained later, in _Zombie Process_]) in `ps`: `myapp-worker` has finished, but its parent, `myapp`, has not read its exit code yet
  ]
]


#slide[
  == Creating a Process
  Forking a parent and loading an executable

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #uncover("2-")[The parent process calls `fork` - _makes a *clone* of the parent_]

    #uncover("3-")[from now on we have *two identical processes*]

    *Child*
    #uncover("4-")[#block[1. Calls `exec` - _replaces the executable_]]
    #uncover("5-")[#block[2. Eventually calls `exit` (or `return` in `main`) and returns an _exit code_]]

    *Parent*
    #uncover("6-")[#block[1. Does other work or _may wait_ for the child process]]
    #uncover("7-")[#block[2. Eventually calls `wait` to read the _exit code_ of the child]]
  ][
    #align(center)[#diagram("img/process/fork-exec.pdf", height: 80%)]
  ]
]

#let linux-boot = (
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  └── [PID 1]  systemd (called init)
        # The first user-space process started by the kernel
        # Responsible for initializing the rest of the system
        # Mounts filesystems, starts targets, and manages services
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
        # Internal kernel helpers for scheduling, I/O, and interrupts
        # These run in the background as part of the kernel itself
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     │       # Handles dynamic device detection (e.g., USB, disks)
  │
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     ├── [PID 5+]  NetworkManager (or systemd-networkd)
  │     │       # Configures and manages network interfaces
  │
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     ├── [PID 5+]  NetworkManager (or systemd-networkd)
  │     ├── [PID 8+]  gdm / sddm / lightdm (optional)
  │     │       # Display manager - starts graphical login session
  │
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     ├── [PID 5+]  NetworkManager (or systemd-networkd)
  │     ├── [PID 8+]  gdm / sddm / lightdm (optional)
  │     └── [PID 10+]  user@1000.service
  │             # Per-user systemd instance
  │             # Manages user-level services after login
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     ├── [PID 5+]  NetworkManager (or systemd-networkd)
  │     ├── [PID 8+]  gdm / sddm / lightdm (optional)
  │     └── [PID 10+]  user@1000.service
  │             ├── [PID 11+]  bash / zsh / fish
  │             │       # User’s shell process after login
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     ├── [PID 5+]  NetworkManager (or systemd-networkd)
  │     ├── [PID 8+]  gdm / sddm / lightdm (optional)
  │     └── [PID 10+]  user@1000.service
  │             ├── [PID 11+]  bash / zsh / fish
  │             ├── [PID 12+]  Xorg / Wayland
  │             │       # Graphical display server (for GUI sessions)
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
  ```
  [kernel]  interrupt handler / scheduler
  │   # The kernel’s first process (part of the kernel itself)
  │   # Manages CPU scheduling and idling
  │
  ├── [PID 1]  systemd (called init)
  │     ├── [PID 3+]  systemd-udevd
  │     ├── [PID 5+]  NetworkManager (or systemd-networkd)
  │     ├── [PID 8+]  gdm / sddm / lightdm (optional)
  │     └── [PID 10+]  user@1000.service
  │             ├── [PID 11+]  bash / zsh / fish
  │             ├── [PID 12+]  Xorg / Wayland
  │             └── [PID 13+]  gnome-shell / plasma / sway
  │                     # User’s desktop environment or window manager
  └── [PID ...]  kernel threads (kthreadd, kworker, ksoftirqd, etc.)
  ```,
)

#slide[
  == How Linux Starts
  The first process

  #tree-text(size: 12pt)[#tree-steps(linux-boot)]

  #place(bottom + right, dy: -1em)[
    #uncover((beginning: linux-boot.len() + 1))[
      #block(fill: rgb("fff3e0"), inset: 0.8em, radius: 0.3em)[
        === ⚠️ `init` cannot stop!
        or the whole system will panic!
      ]
    ]
  ]
]

#let orphan = (
  ```
  [PID 1]  systemd (init)
  │     # PID 1: init, adopts orphaned processes
  │     │
  │     ├── [PID 10+]  user@1000.service
  │     │     │
  │     │     ├── [PID 100]  myapp
  │     │     │     # Application master process
  │     │     │     │
  │     │     │     ├── [PID 200]  myapp-worker
  │     │     │     │     # Worker doing background jobs
  │     │     │     └── [PID 201]  myapp-helper
  │     │     │           # Helper process
  ...
  ```,
  ```
  [PID 1]  systemd (init)
  │     # PID 1: init, adopts orphaned processes
  │     │
  │     ├── [PID 10+]  user@1000.service
  │     ...
  ├── [PID 200]  myapp-worker    <-- reparented
  │     # Was child of PID 100; now adopted by PID 1
  ├── [PID 201]  myapp-helper    <-- reparented
  │     # Also adopted by PID 1
  ...
  ```,
)

#slide[
  == 😕 Orphan Process
  What happens when the parent process ends

  - child processes remain without a parent
  - orphan processes are _reparented_ to `init` (PID 1)

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1.5em)[
    #tree-text(size: 10pt)[#tree-steps(orphan)]
  ][
    #only(2)[💡 `myapp` (PID 100) has ended]

    #uncover(3)[
      === ⚠️ `init` has to be *present* to be able to reparent processes
      or the whole system will panic!
    ]
  ]
]

#slide[
  == 🧟 Zombie Process
  And this is why `init` cannot stop

  #uncover("2-")[#block[
    - the process will stay in `Done` and will *wait for the parent* to _read its return code_ (`wait`)
  ]]
  #uncover("3-")[#block[- the system will *keep all the process' resources allocated* while in `Done`]]

  // the same size as before: half of the height, the width follows the image
  #align(center)[#layout(size => box(width: size.height * 0.5 * 1313 / 760)[
    #only(1)[#states-diagram(none)]
    #only("2-")[#states-diagram("done")]
  ])]

  #uncover("4-")[#block[
    - until the parent reads the return code of the child, *resources* stay *allocated*, *but not used*: 🧟 zombie
  ]]
]

#slide[
  == 😕 Orphan and 🧟 Zombie ⁉️
  Uses up resources

  #v(2em)
  #align(center)[
    #text(size: 20pt)[⚠️ `init` has to be *present* to be able to reparent processes]

    or the whole system will be full of 🧟 zombies
  ]
]

#slide[
  #heading(level: 2, outlined: false)[]

  #text(size: 50pt)[
    #align(center + horizon)[
      🐧 + 🧟 = 🛑 #text(size: 10pt, weight: "regular")[\ _Linux does not like *permanent* zombies, so it just panics when `init` stops._]
    ]
  ]]
