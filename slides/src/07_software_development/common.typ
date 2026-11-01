#import "/src/slides.typ": *

// Shared colors and drawings for this lecture, in the same style as the
// other decks: orange for whatever is new or changed on the current step.

#let accent = rgb("004d65")
#let changed = rgb("e65100")
#let changed-fill = rgb("fff3e0")
#let ok-color = rgb("2e7d46")
#let ok-fill = rgb("e8f5e9")
#let bad-color = rgb("c62828")
#let bad-fill = rgb("ffebee")
#let dim = luma(175)

#let mono = "DejaVu Sans Mono"

// one color per kind of language (compiled, bytecode, interpreted)
#let kind-colors = (
  compiled: (fill: rgb("dae8fc"), stroke: rgb("6c8ebf")),
  bytecode: (fill: rgb("fff2cc"), stroke: rgb("d6b656")),
  interpreted: (fill: rgb("d5e8d4"), stroke: rgb("82b366")),
)

// ---------------------------------------------------------------------------
// Bibliography
// ---------------------------------------------------------------------------

#let ward = [*Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021]
#let uso-book = [*Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]]
#let make-manual = [*Richard M. Stallman, Roland McGrath, Paul D. Smith*, _GNU Make Manual_, #link("https://www.gnu.org/software/make/manual/")[online]]
#let rust-book = [*Steve Klabnik, Carol Nichols*, _The Rust Programming Language_, #link("https://doc.rust-lang.org/book/")[online]]
#let lsp-spec = [_Language Server Protocol Specification_, #link("https://microsoft.github.io/language-server-protocol/")[online]]

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

// a white background behind the diagrams, so they read well on any theme
#let diagram(path, ..args) = box(fill: white, inset: 5pt, radius: 0.3em, image(path, ..args))

// a screenshot with a thin border and rounded corners
#let screenshot(path, ..args) = box(
  stroke: 0.5pt + luma(180),
  radius: 4pt,
  clip: true,
  image(path, ..args),
)

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

// a small arrow to use inside text, e.g. `hello.c` #arrow `hello.i`
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// a down arrow, drawn the same way
#let down-arrow(length: 1.2em, color: luma(120), thickness: 1.5pt) = rotate(
  90deg,
  reflow: true,
  draw-arrow(length: length, color: color, thickness: thickness),
)

// a file of the drawings: a small box with the name in a monospace font
#let file-box(name, sub: none, on: false, fill: white, width: auto) = box(
  width: width,
  inset: (x: 0.5em, y: 0.4em),
  radius: 0.2em,
  stroke: if on { 1.5pt + changed } else { 0.8pt + luma(140) },
  fill: if on { changed-fill } else { fill },
  align(center, {
    text(font: mono, size: 0.8em, fill: if on { changed } else { black }, name)
    if sub != none { linebreak(); text(size: 0.65em, fill: luma(100), sub) }
  }),
)

// a tool of the drawings (a program that transforms files): rounded,
// colored box
#let tool-box(name, sub: none, on: false, fill: rgb("eef3f5"), stroke: accent, width: auto) = box(
  width: width,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.6em,
  stroke: if on { 1.5pt + changed } else { 1pt + stroke },
  fill: if on { changed-fill } else { fill },
  align(center, {
    text(size: 0.85em, weight: "bold", fill: if on { changed } else { stroke }, name)
    if sub != none { linebreak(); text(size: 0.65em, fill: luma(80), sub) }
  }),
)

// a label for an arrow
#let arrow-label(body) = text(size: 0.65em, fill: luma(100), style: "italic", body)

// a row of the drawings: items separated by arrows (an item is any
// content, a label above the arrow can be given as ("label", item))
#let flow(..items, gap: 0.35em, length: 1.6em) = {
  let cells = ()
  for (i, it) in items.pos().enumerate() {
    if i > 0 {
      let (lbl, body) = if type(it) == array { it } else { (none, it) }
      cells.push(stack(spacing: 0.2em, if lbl != none { arrow-label(lbl) } else { [] }, draw-arrow(length: length)))
      cells.push(body)
    } else {
      cells.push(it)
    }
  }
  grid(columns: cells.len(), column-gutter: gap, align: center + horizon, ..cells)
}

// the main idea of a slide: a large callout
#let callout(body, color: changed, fill: changed-fill) = block(
  width: 100%,
  fill: fill,
  stroke: 2pt + color,
  radius: 0.4em,
  inset: (x: 0.8em, y: 0.5em),
  align(center, text(size: 1.05em, body)),
)

// ---------------------------------------------------------------------------
// Absolute drawings (fixed size, so nothing moves between the steps)
// ---------------------------------------------------------------------------

// a drawing area of a fixed size, centered on the slide
#let drawing(width: 440pt, height: 160pt, body) = align(center, box(width: width, height: height, align(
  left + top,
  body,
)))

// place `body` centered on the point (x, y)
#let pin(x, y, body) = context {
  let s = measure(body)
  place(top + left, dx: x - s.width / 2, dy: y - s.height / 2, body)
}

// a straight line between two points
#let wire(a, b, stroke: 1pt + luma(120)) = place(top + left, line(start: a, end: b, stroke: stroke))

// an arrow from a to b (a line with a triangle at the end)
#let line-arrow(a, b, color: luma(120), thickness: 1pt, head: 5pt, dash: none) = {
  let (x1, y1) = a
  let (x2, y2) = b
  let dx = (x2 - x1).pt()
  let dy = (y2 - y1).pt()
  let len = calc.sqrt(dx * dx + dy * dy)
  let (ux, uy) = (dx / len, dy / len)
  let h = head.pt()
  let base = (x2 - ux * h * 1pt, y2 - uy * h * 1pt)
  place(top + left, line(start: a, end: base, stroke: (paint: color, thickness: thickness, dash: dash)))
  place(top + left, polygon(
    fill: color,
    stroke: none,
    (x2, y2),
    (base.at(0) - uy * h * 0.55pt, base.at(1) + ux * h * 0.55pt),
    (base.at(0) + uy * h * 0.55pt, base.at(1) - ux * h * 0.55pt),
  ))
}

// a table of keys: (keys, what they do); a row with only the first cell
// (the second is none) is the title of a group
#let key-table(keys, size: 0.75em, gap: 0.26em, key-width: auto, header: ([*key*], [*action*])) = {
  set text(size: size)
  table(
    columns: (key-width, 1fr),
    stroke: none,
    inset: (x: 0.35em, y: gap),
    ..if header.len() > 0 { (table.header(..header),) },
    ..keys
      .map(((k, action)) => if action == none {
        (table.cell(colspan: 2, text(fill: accent, weight: "bold", k)),)
      } else {
        (k, action)
      })
      .flatten(),
  )
}

// a sequence of keys, e.g. #keys("d", "w")
#let keys(..ks) = ks.pos().map(kbd).join(h(0.15em))

