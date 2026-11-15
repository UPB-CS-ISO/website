#import "/src/slides.typ": *

// Shared colors and drawings for this lecture, in the same style as the
// other decks: teal (the theme color) for the parts, orange for whatever the
// current step talks about, gray for what is not important right now.

#let accent = rgb("004d65")
#let accent-fill = rgb("eef3f5")
#let changed = rgb("e65100")
#let changed-fill = rgb("fff3e0")
#let ok-color = rgb("2e7d46")
#let ok-fill = rgb("e8f5e9")
#let bad-color = rgb("c62828")
#let bad-fill = rgb("ffebee")
#let dim = luma(175)
#let pcb-fill = rgb("e3efe3")
#let pcb-stroke = rgb("5b8c5a")

#let mono = "DejaVu Sans Mono"

// ---------------------------------------------------------------------------
// Bibliography
// ---------------------------------------------------------------------------

#let ward = [*Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021]
#let uso-book = [*Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]]
#let patterson = [*David A. Patterson, John L. Hennessy*, _Computer Organization and Design RISC-V Edition_, 2#super[nd] Edition, Morgan Kaufmann, 2020]

// ---------------------------------------------------------------------------
// Arrows (drawn with shapes: arrow glyphs are missing from some fonts)
// ---------------------------------------------------------------------------

// an arrow pointing right, inline
#let draw-arrow(length: 2em, color: luma(120), thickness: 1.5pt) = {
  let height = 0.7em
  let mid = height / 2
  let head = 0.5em
  box(width: length, height: height, baseline: 0.1em, {
    place(top + left, line(start: (0em, mid), end: (length - head + 0.05em, mid), stroke: thickness + color))
    place(top + left, polygon(fill: color, (length - head, mid - 0.3em), (length, mid), (length - head, mid + 0.3em)))
  })
}

// a small arrow to use inside text, e.g. `x86-64` #arrow `aarch64`
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// a down arrow, drawn the same way
#let down-arrow(length: 1.2em, color: luma(120), thickness: 1.5pt) = rotate(
  90deg,
  reflow: true,
  draw-arrow(length: length, color: color, thickness: thickness),
)

// ---------------------------------------------------------------------------
// Absolute drawings (fixed size, so nothing moves between the steps)
// ---------------------------------------------------------------------------

// a drawing area of a fixed size, centered on the slide
// e.g. #drawing(width: 300pt, height: 120pt)[#at(10pt, 10pt, unit[CPU])]
#let drawing(width: 440pt, height: 160pt, body) = align(center, box(width: width, height: height, align(
  left + top,
  body,
)))

// place `body` with its top left corner at (x, y)
#let at(x, y, body) = place(top + left, dx: x, dy: y, body)

// place `body` centered on the point (x, y)
#let pin(x, y, body) = context {
  let s = measure(body)
  place(top + left, dx: x - s.width / 2, dy: y - s.height / 2, body)
}

// a plain line from a to b (a bus, a wire, a trace on the board)
#let wire(a, b, stroke: 1.5pt + luma(150)) = place(top + left, line(start: a, end: b, stroke: stroke))

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

// a link between two parts, orange when `on` (the link the step talks about)
#let link-line(a, b, on: false, thick: false) = wire(a, b, stroke: (
  if on { (if thick { 3pt } else { 2pt }) + changed } else { (if thick { 2.5pt } else { 1.5pt }) + luma(150) }
))

// a gray italic label (next to an arrow, under a drawing)
#let note(body, color: luma(100)) = text(size: 0.65em, fill: color, style: "italic", body)

// ---------------------------------------------------------------------------
// Parts of the drawings
// ---------------------------------------------------------------------------

// a hardware part: a rounded box with an optional emoji, a name and a small
// line below. `kind`: "unit" (teal, a part that computes), "dark" (filled
// teal, the main part), "slot" (white, a connector or a place for a part),
// "ghost" (dashed gray, not there). `on: true` draws it orange: the part the
// current step talks about. Only the colors change between steps.
// e.g. #unit(icon: cpu-icon, width: 70pt, height: 40pt, on: true, sub: [4 cores])[CPU]
#let unit(icon: none, sub: none, on: false, kind: "unit", width: auto, height: auto, size: 0.8em, body) = {
  let (fill, stroke, ink) = if on { (changed-fill, 1.5pt + changed, changed.darken(15%)) } else if kind == "dark" {
    (accent, 1pt + accent, white)
  } else if kind == "slot" { (white, 0.8pt + luma(140), black) } else if kind == "ghost" {
    (white, (paint: luma(170), thickness: 0.8pt, dash: "dashed"), luma(150))
  } else { (accent-fill, 1pt + accent, accent) }
  box(
    width: width,
    height: height,
    radius: 0.35em,
    fill: fill,
    stroke: stroke,
    inset: (x: 0.3em, y: 0.25em),
    align(center + horizon, text(size: size, {
      if icon != none { text(size: 1.3em, icon); linebreak() }
      text(weight: "bold", fill: ink, body)
      if sub != none { linebreak(); text(size: 0.8em, fill: if kind == "dark" and not on { white } else { luma(80) }, sub) }
    })),
  )
}

// a card: a colored title bar and a white body (like the cards of lecture 3)
// e.g. #card([📱 SoC], width: 100%)[- one chip]
#let card(title, width: 100%, height: auto, on: false, color: accent, body) = block(
  width: width,
  height: height,
  radius: 0.4em,
  clip: true,
  stroke: 1.2pt + if on { changed } else { color },
  fill: white,
  {
    block(width: 100%, fill: if on { changed } else { color }, inset: (x: 0.6em, y: 0.35em), below: 0pt, text(
      fill: white,
      weight: "bold",
      title,
    ))
    block(width: 100%, inset: (x: 0.6em, y: 0.5em), above: 0pt, body)
  },
)

// a small colored tag, e.g. #tag[x86-64] or #tag(color: changed)[new]
#let tag(body, color: accent) = box(
  inset: (x: 0.35em, y: 0.15em),
  outset: (y: 0.1em),
  radius: 0.25em,
  fill: color.lighten(85%),
  stroke: 0.6pt + color,
  text(size: 0.8em, fill: color.darken(20%), body),
)

// a tip (good to know, not an error): a light orange note with a left bar
#let tip(body) = block(
  width: 100%,
  inset: (x: 0.7em, y: 0.45em),
  fill: changed-fill,
  stroke: (left: 3pt + changed),
  radius: (right: 3pt),
  body,
)

// the main idea of a slide: a large centered callout
#let callout(body, color: changed, fill: changed-fill) = block(
  width: 100%,
  fill: fill,
  stroke: 2pt + color,
  radius: 0.4em,
  inset: (x: 0.8em, y: 0.5em),
  align(center, text(size: 1.05em, body)),
)

// a popup card drawn over the slide: a colored (default red) title bar, a
// white body and a soft shadow; `width` must be absolute. No inline code in
// the title (unreadable on the colored bar).
// e.g. #place(bottom + right, popup(width: 260pt)[⚠️ Title][body])
#let popup(width: 300pt, color: bad-color, title, body) = {
  let card = block(width: width, fill: white, stroke: 1.5pt + color, radius: 0.5em, clip: true, stack(
    block(width: 100%, fill: color, inset: (x: 0.8em, y: 0.4em), text(fill: white, weight: "bold", size: 0.85em, title)),
    block(width: 100%, inset: (x: 0.8em, y: 0.6em), text(size: 0.8em, body)),
  ))
  context {
    let h = measure(card).height
    box(width: width + 5pt, height: h + 5pt, {
      place(top + left, dx: 5pt, dy: 5pt, rect(
        width: width,
        height: h,
        radius: 0.5em,
        fill: black.transparentize(80%),
        stroke: none,
      ))
      place(top + left, card)
    })
  }
}

// a question in big letters, then the answer from step `from` + 1
// e.g. #question(3)[Why?][💡 because]
#let question(from, q, a) = {
  uncover(str(from) + "-", align(center, text(size: 1.25em, weight: "bold", fill: accent, q)))
  v(0.2em)
  uncover(str(from + 1) + "-", align(center, a))
}

// a horizontal bar of a chart: `value` of `max` fills `width`; an arrow tip
// when the value does not fit; `on` colors it orange
#let bar(value, max, width: 200pt, height: 0.85em, on: false, color: accent, label: none) = box(baseline: 0.15em, {
  let w = calc.min(value / max, 1) * width
  box(width: w, height: height, fill: if on { changed } else { color.lighten(60%) }, radius: (right: 2pt))
  if value > max {
    box(width: 0.6em, height: height, polygon(
      fill: if on { changed } else { color.lighten(60%) },
      (0pt, 0pt),
      (0.6em, height / 2),
      (0pt, height),
    ))
  }
  if label != none { h(0.4em) + text(size: 0.85em, weight: if on { "bold" } else { "regular" }, label) }
})

// a bar chart: rows of (name, value, label); row i appears on step
// `start + i` (or all at once with `start: none`); `on`: the orange row
#let bar-chart(rows, max, width: 220pt, start: 1, on: none, name-width: 8em, size: 0.8em) = block({
  set text(size: size)
  grid(
    columns: (name-width, 1fr),
    row-gutter: 0.45em,
    align: (right + horizon, left + horizon),
    column-gutter: 0.6em,
    ..rows
      .enumerate()
      .map(((i, r)) => {
        let (name, value, label) = r
        let show-at = if start == none { "1-" } else { str(start + i) + "-" }
        (uncover(show-at, name), uncover(show-at, bar(value, max, width: width, on: on == i, label: label)))
      })
      .flatten(),
  )
})

// ---------------------------------------------------------------------------
// Files and tools, drawn like in lecture 07 (Software Development)
// ---------------------------------------------------------------------------

// a source file: a frame with a gray title bar holding the file name, the
// code below it. e.g. #code-file("add.c")[```c a = a + 1;```]
#let code-file(name, body, width: auto) = box(
  width: width,
  stroke: 1pt + luma(160),
  radius: 0.4em,
  clip: true,
  stack(
    block(width: 100%, fill: luma(225), inset: (x: 0.7em, y: 0.35em), text(
      font: mono,
      size: 0.8em,
      weight: "bold",
      fill: luma(60),
      name,
    )),
    block(width: 100%, fill: white, inset: (x: 0.7em, y: 0.5em), body),
  ),
)

// a tool (a program that transforms files) or a processor: a rounded,
// colored box with a bold name and a small line below
// e.g. #tool-box("compiler", sub: [`gcc`, `clang`])
#let tool-box(name, sub: none, on: false, fill: accent-fill, stroke: accent, width: auto) = box(
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

// an arrow with an optional label above it, for the flows
#let flow-arrow(label: none, length: 1.6em, color: luma(120)) = stack(
  spacing: 0.2em,
  if label != none { note(label) } else { [] },
  draw-arrow(length: length, color: color),
)

// an info popup: like `popup`, in the theme color, for explanations that
// appear on one step next to what they explain
// e.g. #only(2, place(bottom + right, info(width: 220pt)[Title][body]))
#let info(width: 220pt, title, body) = popup(width: width, color: accent, [ℹ️ #title], body)

// a small drawn chip (a square with pins), used as the CPU icon instead of an
// emoji; it takes the color of the text around it
// e.g. #cpu-icon CPU, or #unit(icon: cpu-icon)[CPU]
#let cpu-icon = box(width: 1em, height: 1em, baseline: 0.15em, context {
  let c = text.fill
  let s = 0.09em
  place(top + left, dx: 0.2em, dy: 0.2em, rect(width: 0.6em, height: 0.6em, radius: 0.08em, stroke: s + c))
  place(top + left, dx: 0.38em, dy: 0.38em, rect(width: 0.24em, height: 0.24em, fill: c, stroke: none))
  for i in range(3) {
    let p = 0.3em + i * 0.2em
    place(top + left, line(start: (p, 0.02em), end: (p, 0.2em), stroke: s + c))
    place(top + left, line(start: (p, 0.8em), end: (p, 0.98em), stroke: s + c))
    place(top + left, line(start: (0.02em, p), end: (0.2em, p), stroke: s + c))
    place(top + left, line(start: (0.8em, p), end: (0.98em, p), stroke: s + c))
  }
})
