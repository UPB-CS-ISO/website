#import "/src/slides.typ": *
#import "@preview/fletcher:0.5.8": diagram, node, edge

// Shared drawings for this lecture, in the same style as the other lectures
// (orange for whatever is new or changed on the current step).

#let accent = rgb("004d65")
#let hl = rgb("e65100") // highlighted / new
#let hl-bg = rgb("fff3e0")
#let ok-color = rgb("2e7d46")
#let bad-color = rgb("c62828")
#let dim = luma(175)

#let mono = "DejaVu Sans Mono"

#let ward = [*Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021]
#let uso-book = [*Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]]

// a note in the same style as the tips of the other lectures
#let card(icon: none, title: none, color: accent, height: auto, body) = block(
  width: 100%,
  height: height,
  inset: (x: 0.8em, y: 0.6em),
  radius: 0.3em,
  fill: luma(245),
  stroke: (left: 2pt + color),
)[
  #if title != none [#icon #text(fill: color, weight: "bold", title) #v(0.1em)]
  #body
]

// the key idea of a slide, in a card that stands out: a short title and
// one sentence (none - only the title, on one line)
#let key(icon, title, body, color: hl) = if body == none {
  block(width: 100%, inset: (x: 0.8em, y: 0.5em), radius: 0.3em, fill: luma(245), stroke: (left: 2pt + color))[
    #icon #text(fill: color, weight: "bold", title)
  ]
} else {
  card(icon: icon, title: title, color: color, body)
}

// an arrow pointing right, drawn with shapes rather than an arrow glyph
// (the glyph is missing from some fonts and shows up as a box)
#let draw-arrow(length: 2em, color: luma(150), thickness: 0.8pt) = {
  let height = 0.7em
  let mid = height / 2
  let head = 0.35em
  // an open head, like the arrows of the fletcher drawings
  box(width: length, height: height, baseline: 0.1em, {
    place(top + left, line(start: (0em, mid), end: (length, mid), stroke: thickness + color))
    let stroke = (paint: color, thickness: thickness, cap: "round")
    place(top + left, line(start: (length - head, mid - 0.25em), end: (length, mid), stroke: stroke))
    place(top + left, line(start: (length - head, mid + 0.25em), end: (length, mid), stroke: stroke))
  })
}

// a small arrow to use inside text
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// an arrow pointing down, centered, with an optional label on its right
#let down-arrow(length: 1.6em, color: luma(150), label: none) = align(center, box(height: length, {
  place(center + top, dx: -0.35em, rotate(90deg, reflow: true, draw-arrow(length: length, color: color)))
  if label != none {
    place(left + horizon, dx: 0.6em, text(size: 0.85em, fill: color, label))
  }
}))

// an arrow with a small label above it
#let labeled-arrow(label, color: luma(150), length: 6em) = box(width: length, align(center)[
  #text(size: 0.8em, fill: color, label) \
  #draw-arrow(length: length, color: color)
])

// an arrow pointing up, centered, with an optional label on its right
#let up-arrow(length: 1.6em, color: luma(150), label: none) = align(center, box(height: length, {
  place(center + top, dx: -0.35em, rotate(-90deg, reflow: true, draw-arrow(length: length, color: color)))
  if label != none {
    place(left + horizon, dx: 0.6em, text(size: 0.85em, fill: color, label))
  }
}))

// ----- users -----

// the color of a user's label: root is red, system users gray, people blue
#let user-color(uid) = if uid == 0 { bad-color } else if uid < 1000 { luma(110) } else { accent }

// the UID of a user, in the color of the user
#let uid-pill(uid, fill: white, color: auto) = box(
  fill: fill,
  inset: (x: 0.35em, y: 0.1em),
  outset: (y: 1pt),
  radius: 1em,
  text(fill: if color == auto { user-color(uid) } else { color }, weight: "bold")[UID #text(font: mono, str(uid))],
)

// the label a process runs under: 👤 name (UID)
#let user-tag(name, uid) = box(
  fill: user-color(uid),
  inset: (x: 0.45em, y: 0.2em),
  outset: (y: 1pt),
  radius: 1em,
  text(size: 0.75em, fill: white)[👤 #text(font: mono, weight: "bold", name) #uid-pill(uid)],
)

// a process with the label of its user
#let proc-box(cmd, name, uid, width: auto, stroke: 0.8pt + luma(150), fill: white) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: stroke,
  fill: fill,
  align(center)[⚙️ #text(font: mono, weight: "bold", cmd) \ #v(0.1em) #user-tag(name, uid)],
)

// a process with the label of its user and a note under it, e.g. who started it
#let proc-note-box(cmd, name, uid, note, width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  align(center)[⚙️ #text(font: mono, weight: "bold", cmd) \ #v(0.1em) #user-tag(name, uid) \ #text(size: 0.8em, fill: luma(110), note)],
)

// the kernel, the one that checks every action
#let kernel-box(body, width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  fill: accent,
  align(center, text(fill: white, size: 0.85em)[🐧 *kernel* \ #body]),
)

// ----- permissions -----

// the colors of the permission sets: u (user), g (group), o (others)
#let set-colors = (rgb("1565c0"), rgb("7b1fa2"), rgb("00897b"))
#let u-color = set-colors.at(0)
#let g-color = set-colors.at(1)
#let o-color = set-colors.at(2)

// a permission string, `-rw-r-----`: the type in gray, every set in its color
#let mode-text(mode) = {
  let s = if type(mode) == str { mode } else { mode.text }
  text(fill: luma(130), s.slice(0, 1))
  for (i, color) in set-colors.enumerate() {
    text(fill: color, s.slice(1 + 3 * i, 4 + 3 * i))
  }
}

// every permission string written in the slides, `ls -l` output included
#let mode-pattern = regex("[-dlcbps][-r][-w][-xsS][-r][-w][-xsS][-r][-w][-xtT]")

// a file with its owner, its group and its permissions (a string, or
// already drawn content)
#let file-box(path, owner, group, mode, icon: "📄", width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  align(center)[#icon #text(font: mono, weight: "bold", path) \ #text(size: 0.75em, font: mono)[#if type(mode) == str { mode-text(mode) } else { mode } #owner #group]],
)

// ✅ allowed / ❌ denied
#let verdict(ok, body) = box(
  inset: (x: 0.6em, y: 0.3em),
  radius: 0.3em,
  fill: if ok { rgb("e8f5e9") } else { rgb("ffebee") },
  stroke: 1.2pt + if ok { ok-color } else { bad-color },
  text(size: 0.85em, fill: if ok { ok-color } else { bad-color }, weight: "bold")[#if ok [✅] else [❌] #body],
)

// a box in a fletcher drawing, drawn by itself (proc-box, kernel-box ...)
#let thing(pos, body) = node(pos, body, inset: 0pt, stroke: none, shape: rect)

// an arrow between two boxes, with an optional label on its side
// the look of every arrow in the drawings: thin, with an open head
#let arrow-marks = "->"
#let arrow-thickness = 0.8pt
#let arrow-gray = luma(150)

#let step-arrow(from, to, label, color: arrow-gray) = edge(from, to, arrow-marks, stroke: arrow-thickness + color, label: if label != none { text(size: 0.9em, fill: if color == arrow-gray { luma(110) } else { color }, label) }, label-side: left)

// A process asks the kernel to do something: the kernel checks its UID and
// allows or denies the action on the target (a file, another process ...).
#let request-drawing(cmd, name, uid, action, target, ok, why) = {
  set text(size: 0.8em)
  align(center, diagram(
    spacing: (2em, 2.2em),
    thing((0, 0), proc-box(cmd, name, uid)),
    step-arrow((0, 0), (0, 1), action),
    thing((0, 1), kernel-box[is UID #uid allowed to do this?]),
    step-arrow((0, 1), (0, 2), none),
    thing((0, 2), target),
    thing((0, 2.8), verdict(ok, why)),
  ))
}

// the C library, that programs call to find the users
#let lib-box(body, width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  fill: rgb("e6eff2"),
  stroke: 0.8pt + accent,
  align(center, text(size: 0.85em)[📚 *C library* (`libc`) \ #body]),
)

// a file of the users database: its path, its permissions (none - not
// shown) and some lines
#let db-file(path, mode, owner, group, lines, icon: "📄", width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
)[
  #align(center)[#icon #text(font: mono, weight: "bold", path) #if mode != none [\ #text(size: 0.75em, font: mono)[#mode #owner #group]]]
  #v(-0.3em)
  #line(length: 100%, stroke: 0.5pt + luma(200))
  #v(-0.3em)
  #set text(font: mono, size: 0.8em)
  #lines
]

// ----- records: a line of /etc/passwd, /etc/shadow, /etc/group, ls -l -----

// The fields of one record, drawn in a row. `current` - the index of the
// field to highlight (the others are grayed out), none - every field normal.
// `sep` - the separator between the fields, a string or one per gap.
#let record(fields, current: none, sep: ":", size: 1em, colors: none) = {
  let seps = if type(sep) == str { (sep,) * (fields.len() - 1) } else { sep }
  set text(font: mono, size: size)
  let field(i, f) = {
    let on = current == none or current == i
    let color = if colors != none and colors.at(i) != none { colors.at(i) } else { none }
    let mark = if color != none { color } else { hl }
    let body = if f == "" { h(0.5em) } else { f }
    box(
      inset: (x: 0.12em, y: 0.3em),
      outset: (y: 1pt),
      radius: 2pt,
      fill: if current == i { mark.lighten(88%) } else { none },
      stroke: if current == i { 1pt + mark } else { none },
      text(
        fill: if current == i { mark } else if color != none { if on { color } else { color.lighten(45%) } } else if on { black } else { dim },
        weight: if current == i { "bold" } else { "regular" },
        body,
      ),
    )
  }
  let out = ()
  for (i, f) in fields.enumerate() {
    out.push(field(i, f))
    if i < seps.len() {
      out.push(text(fill: if current == none { luma(110) } else { dim }, seps.at(i)))
    }
  }
  box(out.join())
}

// Walks through the fields of a record, one per subslide: the record on top,
// the explanation of the current field below it.
// `notes` - one entry per field: (icon, title, body), none - the field is
// skipped; `intro` - the card of the first step, when no field is highlighted.
// `colors` - a color for every field (none - the usual orange)
#let record-walk(fields, notes, intro: none, sep: ":", size: 1em, colors: none) = {
  let has-intro = intro != none
  let start = if has-intro { 2 } else { 1 }
  if has-intro {
    only(1)[
      #align(center, record(fields, sep: sep, size: size, colors: colors))
      #v(0.6em)
      #intro
    ]
  }
  let shown = notes.enumerate().filter(((i, note)) => note != none)
  for (step, (i, (icon, title, body))) in shown.enumerate() {
    let color = if colors != none and colors.at(i) != none { colors.at(i) } else { hl }
    only(start + step)[
      #align(center, record(fields, current: i, sep: sep, size: size, colors: colors))
      #v(0.6em)
      #card(icon: icon, title: [#text(fill: luma(120), weight: "regular")[field #(i + 1)] #h(0.3em) #title], color: color, body)
    ]
  }
}

// ----- a terminal session that shows the whole prompt -----

// ```terminal blocks only know the `$ ` prompt; this one draws lines like
// `alice@laptop:~$ cmd` or `root@laptop:/etc# cmd`: the prompt in bold
// (red for a `#` prompt), the command highlighted, the rest is output.
#let prompt-pattern = regex("^([^ ]+@[^ ]+[$#]) (.*)$")

#let prompt-term-line(t) = {
  let m = t.match(prompt-pattern)
  if m == none {
    text(fill: luma(100), t)
  } else {
    let (prompt, cmd) = m.captures
    let color = if prompt.ends-with("#") { bad-color } else { accent }
    text(fill: color, weight: "bold", prompt) + " " + highlight-shell(cmd)
  }
}

// `reveal` - for every step, the number of lines shown (none - all of them)
#let prompt-term(reveal: none, body) = {
  let src = if type(body) == str { body } else { body.text }
  let draw(shown) = {
    show raw.line: line => if shown != none and line.number > shown { hide(line.text) } else { prompt-term-line(line.text) }
    raw(src, block: true)
  }
  if reveal == none {
    draw(none)
  } else {
    for (i, shown) in reveal.enumerate() {
      only(if i == reveal.len() - 1 { str(i + 1) + "-" } else { i + 1 }, draw(shown))
    }
  }
}
