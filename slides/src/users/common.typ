#import "/src/slides.typ": *

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

// a small arrow to use inside text
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// an arrow pointing down, centered, with an optional label on its right
#let down-arrow(length: 1.6em, color: luma(120), label: none) = align(center, box(height: length, {
  place(center + top, dx: -0.35em, rotate(90deg, reflow: true, draw-arrow(length: length, color: color, thickness: 1.2pt)))
  if label != none {
    place(left + horizon, dx: 0.6em, text(size: 0.85em, fill: color, label))
  }
}))

// ----- users -----

// the color of a user's label: root is red, system users gray, people blue
#let user-color(uid) = if uid == 0 { bad-color } else if uid < 1000 { luma(110) } else { accent }

// the label a process runs under: 👤 name (UID)
#let user-tag(name, uid) = box(
  fill: user-color(uid),
  inset: (x: 0.45em, y: 0.2em),
  outset: (y: 1pt),
  radius: 1em,
  text(size: 0.75em, fill: white)[👤 #text(font: mono, weight: "bold", name) #text(size: 0.9em)[UID #uid]],
)

// a process with the label of its user
#let proc-box(cmd, name, uid, width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  align(center)[⚙️ #text(font: mono, weight: "bold", cmd) \ #v(0.1em) #user-tag(name, uid)],
)

// the kernel, the one that checks every action
#let kernel-box(body, width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  fill: accent,
  align(center, text(fill: white, size: 0.85em)[🐧 *kernel* \ #body]),
)

// a file with its owner, its group and its permissions
#let file-box(path, owner, group, mode, icon: "📄", width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  align(center)[#icon #text(font: mono, weight: "bold", path) \ #text(size: 0.75em, font: mono)[#mode #owner #group]],
)

// ✅ allowed / ❌ denied
#let verdict(ok, body) = box(
  inset: (x: 0.6em, y: 0.3em),
  radius: 0.3em,
  fill: if ok { rgb("e8f5e9") } else { rgb("ffebee") },
  stroke: 1.2pt + if ok { ok-color } else { bad-color },
  text(size: 0.85em, fill: if ok { ok-color } else { bad-color }, weight: "bold")[#if ok [✅] else [❌] #body],
)

// ----- records: a line of /etc/passwd, /etc/shadow, /etc/group, ls -l -----

// The fields of one record, drawn in a row. `current` - the index of the
// field to highlight (the others are grayed out), none - every field normal.
// `sep` - the separator between the fields, a string or one per gap.
#let record(fields, current: none, sep: ":", size: 1em) = {
  let seps = if type(sep) == str { (sep,) * (fields.len() - 1) } else { sep }
  set text(font: mono, size: size)
  let field(i, f) = {
    let on = current == none or current == i
    let body = if f == "" { h(0.5em) } else { f }
    box(
      inset: (x: 0.12em, y: 0.3em),
      outset: (y: 1pt),
      radius: 2pt,
      fill: if current == i { hl-bg } else { none },
      stroke: if current == i { 1pt + hl } else { none },
      text(fill: if current == i { hl } else if on { black } else { dim }, weight: if current == i { "bold" } else { "regular" }, body),
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
// `notes` - one entry per field: (icon, title, body); `intro` - the card of
// the first step, when no field is highlighted.
#let record-walk(fields, notes, intro: none, sep: ":", size: 1em) = {
  let has-intro = intro != none
  let start = if has-intro { 2 } else { 1 }
  if has-intro {
    only(1)[
      #align(center, record(fields, sep: sep, size: size))
      #v(0.6em)
      #intro
    ]
  }
  for (i, (icon, title, body)) in notes.enumerate() {
    only(start + i)[
      #align(center, record(fields, current: i, sep: sep, size: size))
      #v(0.6em)
      #card(icon: icon, title: [#text(fill: luma(120), weight: "regular")[field #(i + 1)] #h(0.3em) #title], color: hl, body)
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
