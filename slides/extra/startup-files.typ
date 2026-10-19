#import "/src/slides.typ": *

// How bash startup files set the variables, and how the variables are
// inherited from one process to the next (Fedora, with a note for Ubuntu).
// Written for 4. Command Line Interface and kept here for the lecture about
// users. Self-contained: include it from any deck with
// #include "/extra/startup-files.typ"

#let accent = rgb("004d65")

#let changed = rgb("e65100")

#let mono = "DejaVu Sans Mono"

// an arrow pointing right, drawn with shapes rather than an arrow glyph
// (the glyph is missing from some fonts and shows up as a box)
#let draw-arrow(length: 2em, color: luma(120), thickness: 1.5pt) = {
  let height = 0.7em
  let mid = height / 2
  let head = 0.5em
  box(width: length, height: height, baseline: 0.1em, {
    place(top + left, line(start: (0em, mid), end: (length - head + 0.05em, mid), stroke: thickness + color))
    place(top + left, polygon(
      fill: color,
      (length - head, mid - 0.3em),
      (length, mid),
      (length - head, mid + 0.3em),
    ))
  })
}

// ----- where the variables of a shell come from (Fedora) -----

#let cfg-box(body, caption: none, on: false) = box(
  inset: (x: 0.45em, y: 0.35em),
  radius: 0.3em,
  stroke: if on { 1.5pt + changed } else { 0.8pt + luma(140) },
  fill: white,
  align(center)[
    #text(font: mono, size: 0.9em, fill: if on { changed } else { black }, body)
    #if caption != none [ \ #text(size: 0.8em, fill: if on { changed } else { luma(110) }, caption)]
  ],
)
#let cfg-none(body) = box(
  inset: (x: 0.5em, y: 0.35em),
  radius: 0.3em,
  stroke: (paint: luma(150), thickness: 0.8pt, dash: "dashed"),
  text(fill: luma(110), style: "italic", body),
)
// a variable of a process: "new" (set here, orange), "env" (inherited),
// "shell" (a shell variable, not inherited by the children)
#let var-chip(name, kind) = box(
  inset: (x: 0.3em, y: 0.2em),
  outset: (y: 1pt),
  radius: 2pt,
  stroke: if kind == "new" { 1.2pt + changed } else if kind == "shell" {
    (paint: luma(140), thickness: 0.8pt, dash: "dashed")
  } else { 0.6pt + luma(150) },
  fill: white,
  text(font: mono, size: 0.85em, fill: if kind == "new" { changed } else if kind == "shell" { luma(120) } else { black }, name),
)
#let proc-box(name, caption) = align(center)[
  #box(fill: accent, radius: 0.3em, inset: (x: 0.5em, y: 0.4em), text(fill: white, weight: "bold", font: mono, size: 0.9em, name))
  #if caption != none [ \ #text(size: 0.75em, fill: luma(110), style: "italic", caption)]
]

// an arrow between two processes, pointing right: the child gets a copy
// of the environment
#let inherit-arrow(label: none) = align(center)[
  #set par(leading: 0.15em)
  #if label != none { text(size: 0.75em, fill: changed, label) } \
  #draw-arrow(length: 2.2em, color: changed, thickness: 1.8pt)
]
// a file reads the next one (or bash reads the next one: "then")
#let cfg-down(label) = align(center)[
  #grid(columns: 2, column-gutter: 0.3em, align: horizon,
    rotate(90deg, reflow: true, draw-arrow(length: 0.7em)),
    text(size: 0.75em, fill: luma(120), style: "italic", label))
]

// the variables, in the order they show up
#let login-vars(kind) = (("HOME", kind), ("USER", kind), ("SHELL", kind))
#let profile-vars(kind) = (("PATH", kind), ("LANG", kind))

// processes from left to right, each with the files it reads (top to
// bottom) and the variables it ends up with; on step `n` the parts that
// are explained are orange, the parts of later steps keep their space
#let fedora-startup(step) = {
  let vis(n, body) = if step >= n { body } else { hide(body) }
  let at(n) = step == n
  let chips(..vars) = block(width: 100%, align(center, vars.pos().map(((n, k)) => var-chip(n, k)).join(h(0.25em))))
  set text(size: 0.72em)
  set par(leading: 0.4em, spacing: 0.25em)
  set block(spacing: 0.25em)
  grid(
    columns: (11em, 3em, 16em, 3.6em, 13em, 3em, 12em),
    column-gutter: 0.2em,
    row-gutter: 0.5em,
    align: (center + top),
    // the processes
    proc-box("login", [when you log in]),
    vis(2, inherit-arrow(label: [copy])),
    vis(2, proc-box("bash -l", [login shell])),
    vis(4, inherit-arrow(label: [desktop,\ terminal])),
    vis(4, proc-box("bash", [new terminal window])),
    vis(6, inherit-arrow(label: [copy])),
    vis(6, proc-box("bash script.sh", [a script, `bash -c`])),

    // the files each one reads
    cfg-box(on: at(1), caption: [`HOME`, `USER`, `SHELL`])[/etc/passwd],
    [],
    {
      vis(2, cfg-box(on: at(2), caption: [`PATH`, and `/etc/profile.d/*.sh`:\ `LANG` from `/etc/locale.conf`])[/etc/profile])
      vis(3, [
        #cfg-down[then]
        #cfg-box(on: at(3))[\~/.bash_profile]
        #cfg-down[reads]
        #cfg-box(on: at(3), caption: [`PATH` += `~/.local/bin`])[\~/.bashrc]
        #cfg-down[reads]
        #cfg-box(on: at(3), caption: [`PS1`])[/etc/bashrc]
      ])
    },
    [],
    vis(5, [
      #cfg-box(on: at(5) or step >= 7, caption: [`PATH` += `~/.local/bin`])[\~/.bashrc]
      #cfg-down[reads]
      #cfg-box(on: at(5), caption: [`PS1`])[/etc/bashrc]
      #v(0.3em)
      #text(size: 0.85em, fill: luma(110), style: "italic")[not a login: no `/etc/profile`,\ no `~/.bash_profile`]
    ]),
    [],
    vis(6, cfg-none[no startup file]),

    // the variables of each one
    chips(..login-vars(if at(1) { "new" } else { "env" })),
    [],
    vis(2, chips(..login-vars("env"), ..profile-vars(if at(2) { "new" } else { "env" }), ("PS1", if at(3) { "new" } else { "shell" }))),
    [],
    vis(4, chips(..login-vars("env"), ..profile-vars("env"), ("PS1", if at(5) { "new" } else { "shell" }))),
    [],
    vis(6, chips(..login-vars("env"), ..profile-vars("env"))),
  )
}

#slide[
  == Startup Files (Fedora)
  How the variables are set and *inherited* from one process to the next

  #v(0.3em)
  #align(center)[
    #for (i, when) in ("1", "2", "3", "4", "5", "6", "7-").enumerate() {
      only(when, fedora-startup(i + 1))
    }
  ]

  // the notes stay at the bottom, so they do not move the drawing
  #place(bottom + left, block(width: 100%)[
    #set text(size: 0.95em)
    #only(1)[💡 `login` reads your line in `/etc/passwd`, before any shell starts]
    #only(2)[💡 a *login shell* runs `/etc/profile`: the `PATH` of the system and the scripts in `/etc/profile.d/`]
    #only(3)[💡 then `~/.bash_profile`, which reads `~/.bashrc`, which reads `/etc/bashrc`: `PS1` is a *shell variable*]
    #only(4)[💡 every child gets a *copy* of the exported variables, `PS1` is not exported]
    #only(5)[💡 a new terminal is not a login: only `~/.bashrc` (and `/etc/bashrc`), so `PS1` is set again]
    #only(6)[💡 a script reads no startup file: it only has what it inherited]
    #only("7-")[💡 to keep a variable, add `export EDITOR=nano` to `~/.bashrc`]
    #v(0.2em)
    #text(size: 0.8em, fill: luma(100))[🐧 *Ubuntu*: `~/.profile` instead of `~/.bash_profile`, `/etc/bash.bashrc` (read before `~/.bashrc`) instead of `/etc/bashrc`, `LANG` from `/etc/default/locale`]
  ])
]

