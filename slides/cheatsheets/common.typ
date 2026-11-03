// The common layout of the editor cheat sheets of lab 06.
// Build them from slides/ with `make cheatsheets`.

#let accent = rgb("004d65")
#let changed = rgb("e65100")
#let changed-fill = rgb("fff3e0")
#let mono = "DejaVu Sans Mono"
#let sans = ("Helvetica Neue", "Helvetica", "Liberation Sans", "Arial", "DejaVu Sans")

// a key cap, like the <kbd> of the website (see src/kbd.typ)
#let kbd-border = luma(175)
#let kbd(key) = box(
  fill: luma(250),
  stroke: (rest: 0.5pt + kbd-border, bottom: 1.3pt + kbd-border),
  radius: 2pt,
  inset: (x: 0.25em),
  outset: (y: 0.2em),
  text(font: mono, size: 0.92em, fill: luma(30), key),
)

// the keys of a row, separated by spaces: every token is drawn as key caps
// - "Esc", "Enter", "Space", "Tab": one key cap
// - "Ctrl-r", "Alt-s": a combination of key caps
// - ":wq", "/text", "?text": a command typed on the command line
// - "<c>": a placeholder (any character, a number, ...), in italics
// - anything else, like "dd" or "gg": one key cap per character
#let named = ("Esc", "Enter", "Space", "Tab", "Ctrl", "Alt", "Shift", "Backspace", "PgUp", "PgDn", "Home", "End")
#let placeholder(t) = text(style: "italic", fill: changed, t)
#let token(t) = {
  if (t.starts-with(":") or t.starts-with("/") or t.starts-with("?")) and t.len() > 1 {
    text(font: mono, size: 0.92em, fill: accent, weight: "bold", t)
  } else if t.starts-with("<") and t.ends-with(">") {
    placeholder(t.slice(1, -1))
  } else if t in named {
    kbd(t)
  } else if t.contains("-") and t.len() > 2 {
    t.split("-").map(p => if p in named { kbd(p) } else { kbd(p) }).join(text(size: 0.8em)[+])
  } else {
    // characters, with <x> placeholders inside, like "f<c>" or "<n>G"
    let out = ()
    let rest = t
    while rest.len() > 0 {
      if rest.starts-with("<") and rest.contains(">") {
        let i = rest.position(">")
        out.push(placeholder(rest.slice(1, i)))
        rest = rest.slice(i + 1)
      } else {
        let c = rest.clusters().first()
        out.push(kbd(c))
        rest = rest.slice(c.len())
      }
    }
    out.join(h(0.1em))
  }
}
// code with <x> placeholders: a shell command or a command line of the editor
#let code(t) = {
  let out = ()
  let rest = t
  while rest.len() > 0 {
    if rest.starts-with("<") and rest.contains(">") {
      let i = rest.position(">")
      out.push(placeholder(rest.slice(1, i)))
      rest = rest.slice(i + 1)
    } else {
      let i = if rest.contains("<") { rest.position("<") } else { rest.len() }
      if i == 0 { i = 1 }
      out.push(text(font: mono, size: 0.92em, fill: accent, weight: "bold", rest.slice(0, i)))
      rest = rest.slice(i)
    }
  }
  out.join()
}
// - "`hx --tutor`" (between backticks), or ":%s/a/b/g": code, spaces allowed
// - "/<text> Enter": the search is code, the keys after it are key caps
#let keys(k) = {
  if k.starts-with("`") and k.ends-with("`") {
    code(k.slice(1, -1))
  } else if k.starts-with(":") and k.len() > 1 {
    code(k)
  } else {
    let toks = k.split(" ").filter(t => t != "")
    toks.map(t => if (t.starts-with("/") or t.starts-with("?")) and t.len() > 1 { code(t) } else { token(t) }).join(h(0.25em))
  }
}

// a row: the keys (one or more, separated by "|"), and what they do
#let row(k, what) = (
  k.split(" | ").map(keys).join(text(fill: luma(120), " / ")),
  what,
)

#let card(title, ..rows, note: none) = block(
  width: 100%,
  breakable: false,
  stroke: 0.6pt + luma(190),
  radius: 4pt,
  inset: 0pt,
  clip: true,
  {
    block(width: 100%, fill: accent, inset: (x: 6pt, y: 4pt), below: 0pt,
      text(fill: white, weight: "bold", size: 9.5pt, title))
    block(inset: (x: 6pt, y: 5pt), {
      table(
        columns: (auto, 1fr),
        stroke: none,
        inset: (x: 2pt, y: 2.6pt),
        align: (left + horizon, left + horizon),
        ..rows.pos().flatten(),
      )
      if note != none {
        v(-2pt)
        text(size: 7.6pt, fill: luma(70), style: "italic", note)
      }
    })
  },
)

// a box that stands out: the most important things
#let tip(body) = block(
  width: 100%,
  breakable: false,
  fill: changed-fill,
  stroke: (left: 2.5pt + changed),
  inset: 6pt,
  radius: 2pt,
  text(size: 8.4pt, body),
)

#let sheet(name, command, tagline, tutorial, body) = {
  set page(paper: "a4", flipped: true, margin: (x: 1cm, top: 1cm, bottom: 0.8cm),
    footer: align(center, text(size: 7pt, fill: luma(120))[
      USO / ISO - Introduction to Operating Systems, UPB #h(1em) · #h(1em) lab 06, Text Processing
    ]))
  set text(font: sans, size: 9.2pt, lang: "en")
  set par(leading: 0.45em)
  grid(
    columns: (auto, 1fr, auto),
    align: (left + horizon, left + horizon, right + horizon),
    column-gutter: 10pt,
    text(size: 22pt, weight: "bold", fill: accent, name),
    text(size: 10pt, fill: luma(60))[#tagline],
    text(size: 9pt)[start: #text(font: mono, weight: "bold", fill: changed, command) #h(0.8em)
      tutorial: #text(font: mono, weight: "bold", fill: changed, tutorial)],
  )
  v(-4pt)
  line(length: 100%, stroke: 1.2pt + accent)
  v(2pt)
  columns(3, gutter: 9pt, body)
}
