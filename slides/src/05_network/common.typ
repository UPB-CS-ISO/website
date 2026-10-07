#import "/src/slides.typ": *

// Colors
#let accent = rgb("004d65")
#let hl = rgb("e65100") // highlighted / new
#let hl-bg = rgb("fff3e0")
#let ok-color = rgb("2e7d46")
#let bad-color = rgb("c62828")
#let dim = luma(175)

// One color per network layer (same palette as the TCP/IP stack drawing)
#let layer-colors = (
  physical: (fill: rgb("dae8fc"), stroke: rgb("6c8ebf")),
  link: (fill: rgb("f8cecc"), stroke: rgb("b85450")),
  network: (fill: rgb("ffe6cc"), stroke: rgb("d79b00")),
  transport: (fill: rgb("fff2cc"), stroke: rgb("d6b656")),
  application: (fill: rgb("d5e8d4"), stroke: rgb("82b366")),
)

// ---------------------------------------------------------------------------
// Drawing helpers. A drawing is a box of a fixed size; everything inside it
// is placed at absolute coordinates (in pt, from the top left corner), so
// nothing moves between the steps of a slide.
// ---------------------------------------------------------------------------

// a drawing area of a fixed size, centered on the slide
#let drawing(width: 480pt, height: 190pt, body) = align(center, box(width: width, height: height, align(
  left + top,
  body,
)))

// place `body` centered on the point (x, y)
#let pin(x, y, body) = context {
  let s = measure(body)
  place(top + left, dx: x - s.width / 2, dy: y - s.height / 2, body)
}

// place `body` with its top left corner at (x, y)
#let at(x, y, body) = place(top + left, dx: x, dy: y, body)

// a straight wire between two points
#let wire(a, b, stroke: 1.2pt + luma(90)) = place(top + left, line(start: a, end: b, stroke: stroke))

// a radio link (dashed wire)
#let radio(a, b, color: luma(90)) = wire(a, b, stroke: (paint: color, thickness: 1pt, dash: "dashed"))

// an arrow from a to b (a line with a triangle at the end)
#let draw-arrow(a, b, color: accent, thickness: 1.2pt, head: 5pt, dash: none) = {
  let (x1, y1) = a
  let (x2, y2) = b
  let dx = (x2 - x1).pt()
  let dy = (y2 - y1).pt()
  let len = calc.sqrt(dx * dx + dy * dy)
  let (ux, uy) = (dx / len, dy / len)
  let h = head.pt()
  // the line stops at the base of the head
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

// an inline arrow, for text and tables (arrow characters are missing from
// the slide fonts)
#let arrow = box(width: 1.1em, height: 0.6em, baseline: -0.05em, {
  place(left + horizon, line(length: 0.8em, stroke: 0.09em + black))
  place(right + horizon, polygon(fill: black, (0em, -0.22em), (0.32em, 0em), (0em, 0.22em)))
})
#let arrow-both = box(width: 1.3em, height: 0.6em, baseline: -0.05em, {
  place(center + horizon, line(length: 0.7em, stroke: 0.09em + black))
  place(right + horizon, polygon(fill: black, (0em, -0.22em), (0.32em, 0em), (0em, 0.22em)))
  place(left + horizon, polygon(fill: black, (0.32em, -0.22em), (0em, 0em), (0.32em, 0.22em)))
})

// an emoji of a given size (the template shrinks emoji to 0.68em of the text)
#let icon(e, size: 18pt) = box(width: size * 1.2, height: size, align(center + horizon, text(size: size / 0.68, e)))

// a computer (or any end device): an emoji with a name and an address
// below it. `color` changes only the colors, never the size.
// an icon from img/ (adapted from the USO book drawings), `size` is its height
#let pic(name, size: 22pt) = image("img/" + name + ".svg", height: size)

// a computer (or any end device): an icon with a name and an address
// below (or above) it. `color` changes only the colors, never the size.
#let host(x, y, name, kind: "pc", addr: none, color: black, size: 28pt, label-size: 8pt, below: true) = {
  pin(x, y, if kind.len() > 4 and kind.starts-with("emoji") { icon(kind.slice(5), size: size) } else {
    box(fill: white, pic(kind, size: size))
  })
  let lbl = box(width: 90pt, align(center, stack(
    spacing: 2pt,
    text(size: label-size, weight: "bold", fill: color, name),
    if addr != none { text(size: label-size - 1pt, font: "DejaVu Sans Mono", fill: color, addr) },
  )))
  if below {
    place(top + left, dx: x - 45pt, dy: y + size / 2 + 1pt, lbl)
  } else {
    context {
      let h = measure(lbl).height
      place(top + left, dx: x - 45pt, dy: y - size / 2 - 1pt - h, lbl)
    }
  }
}

// a network device drawn with its icon (hub, switch, router, wifi-router)
#let netdev(x, y, kind, name: none, sub: none, size: 24pt, label-at: bottom, highlight: false) = {
  pin(x, y, box(
    stroke: if highlight { 1.5pt + hl } else { none },
    fill: white,
    radius: 3pt,
    inset: 2pt,
    pic(kind, size: size),
  ))
  if name != none {
    let lbl = align(center, stack(spacing: 2pt, text(size: 8pt, weight: "bold", name), if sub != none {
      text(size: 6.5pt, sub)
    }))
    if label-at == bottom { pin(x, y + size / 2 + 10pt, lbl) } else if label-at == top {
      pin(x, y - size / 2 - 10pt, lbl)
    } else if label-at == right {
      context {
        let w = measure(lbl).width
        let iw = measure(pic(kind, size: size)).width
        pin(x + iw / 2 + w / 2 + 4pt, y, lbl)
      }
    } else {
      context {
        let w = measure(lbl).width
        let iw = measure(pic(kind, size: size)).width
        pin(x - iw / 2 - w / 2 - 4pt, y, lbl)
      }
    }
  }
}

// a network device (hub, switch, router, ...): a rounded box, colored
// after the layer it works on
#let device(x, y, name, layer: "link", width: 60pt, height: 22pt, sub: none, highlight: false) = {
  let c = layer-colors.at(layer)
  pin(x, y, box(
    width: width,
    height: height,
    radius: 4pt,
    fill: c.fill,
    stroke: if highlight { 1.5pt + hl } else { 1pt + c.stroke },
    align(center + horizon, stack(
      spacing: 2pt,
      text(size: 8pt, weight: "bold", name),
      if sub != none { text(size: 6.5pt, sub) },
    )),
  ))
}

// a small label (packet, frame, note) centered on (x, y)
#let tag(x, y, body, fill: white, stroke: 0.8pt + accent, size: 7.5pt, width: auto) = pin(x, y, box(
  fill: fill,
  stroke: stroke,
  radius: 2pt,
  inset: (x: 3pt, y: 2pt),
  width: width,
  align(center, text(size: size, body)),
))

// a frame / packet traveling on a wire
#let frame(x, y, body, color: hl) = tag(x, y, body, fill: hl-bg, stroke: 1pt + color, size: 7pt)

// plain text centered on (x, y)
#let label(x, y, body, size: 8pt, fill: black, weight: "regular") = pin(x, y, text(
  size: size,
  fill: fill,
  weight: weight,
  body,
))

// a cloud (the Internet, an ISP network, ...)
#let cloud(x, y, name, width: 70pt, height: 40pt) = pin(x, y, box(
  width: width,
  height: height,
  radius: 50%,
  fill: luma(245),
  stroke: 1pt + luma(150),
  align(center + horizon, stack(spacing: 2pt, icon("🌐", size: 12pt), text(size: 7pt, weight: "bold", name))),
))
#let cloud-pic(x, y, size: 50pt) = pin(x, y, pic("cloud", size: size))

// a dashed area that groups devices (a network)
#let area(x, y, w, h, name, color: accent, name-at: top + left) = {
  place(top + left, dx: x, dy: y, rect(
    width: w,
    height: h,
    radius: 6pt,
    stroke: (paint: color, thickness: 0.8pt, dash: "dashed"),
  ))
  place(top + left, dx: x, dy: y, box(width: w, height: h, inset: 3pt, align(name-at, text(
    size: 7.5pt,
    fill: color,
    weight: "bold",
    name,
  ))))
}

// the highlighted box style used for notes
#let note-box(body) = block(
  width: 100%,
  inset: (x: 0.6em, y: 0.4em),
  radius: 0.3em,
  stroke: 1pt + hl,
  body,
)

// Bibliography helpers
#let ward = [*Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021]
#let tanenbaum = [*Andrew S. Tanenbaum, David J. Wetherall*, _Computer Networks_, 5#super[th] Edition, Pearson, 2011]
#let uso-book = [*Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]]


// a row of header fields (frame, packet, ...): each item is
// (name, width, layer, size) where size is a small text under the name
#let field(name, width, layer: "link", sub: none, height: 30pt, highlight: false) = {
  let c = if layer == none { (fill: white, stroke: luma(120)) } else { layer-colors.at(layer) }
  box(
    width: width,
    height: height,
    fill: c.fill,
    stroke: if highlight { 1.5pt + hl } else { 0.8pt + c.stroke },
    align(center + horizon, stack(
      spacing: 3pt,
      text(size: 8pt, weight: "bold", name),
      if sub != none { text(size: 6.5pt, sub) },
    )),
  )
}
#let fields(..items) = stack(dir: ltr, ..items.pos())

// Layer stacks (OSI, TCP/IP). A stack is a list of layers (name, layer color,
// sub text) drawn at x, all layers share the stack height equally.
#let stack-top = 24pt
#let stack-h = 140pt
#let stack-y(n, i, y0: stack-top, h: stack-h) = y0 + h * i / n
#let layer-stack(x, layers, w: 100pt, y0: stack-top, h: stack-h, size: 8pt, highlight: ()) = {
  let n = layers.len()
  for (i, (name, layer, sub)) in layers.enumerate() {
    let c = layer-colors.at(layer)
    place(top + left, dx: x, dy: stack-y(n, i, y0: y0, h: h), box(
      width: w,
      height: h / n,
      fill: c.fill,
      stroke: 0.8pt + c.stroke,
      align(center + horizon, stack(
        spacing: 2pt,
        text(size: size, weight: "bold", name),
        if sub != none { text(size: 6.5pt, sub) },
      )),
    ))
  }
}
// bands joining the layers of a stack (n1 layers at x1) to the layers of the
// next one (n2 layers at x2): `pairs` are ((first, last), (first, last), color)
#let stack-join(x1, n1, x2, n2, pairs, w: 100pt) = for (a, b, layer) in pairs {
  place(top + left, polygon(
    fill: layer-colors.at(layer).fill.lighten(40%),
    stroke: none,
    (x1 + w, stack-y(n1, a.at(0)) + 1pt),
    (x2, stack-y(n2, b.at(0)) + 1pt),
    (x2, stack-y(n2, b.at(1) + 1) - 1pt),
    (x1 + w, stack-y(n1, a.at(1) + 1) - 1pt),
  ))
}
#let stack-title(x, body, w: 100pt) = pin(x + w / 2, 9pt, text(size: 8.5pt, weight: "bold", fill: accent, body))

// The 5 layers, drawn small on the cover of a section, with the layers the
// section talks about highlighted (`layers`: keys of `layer-colors`) and an
// optional `note` next to them.
#let section-stack(layers, note: none) = {
  let all = (
    ("application", "5. Application"),
    ("transport", "4. Transport"),
    ("network", "3. Network"),
    ("link", "2. Data Link"),
    ("physical", "1. Physical"),
  )
  let w = 110pt
  let h = 22pt
  box(width: w + 72pt, height: 5 * h, {
    for (i, (key, name)) in all.enumerate() {
      let on = key in layers
      let c = layer-colors.at(key)
      place(top + left, dy: i * h, box(
        width: w,
        height: h,
        fill: if on { c.fill } else { luma(246) },
        stroke: 0.8pt + if on { c.stroke } else { luma(210) },
        align(center + horizon, text(size: 9pt, weight: if on { "bold" } else { "regular" }, fill: if on {
          black
        } else { luma(170) }, name)),
      ))
    }
    // an orange outline around the highlighted layers
    let idx = all.enumerate().filter(((i, (k, n))) => k in layers).map(((i, x)) => i)
    if idx.len() > 0 {
      let (a, b) = (calc.min(..idx), calc.max(..idx))
      place(top + left, dx: -2pt, dy: a * h - 2pt, rect(
        width: w + 4pt,
        height: (b - a + 1) * h + 4pt,
        radius: 3pt,
        stroke: 2pt + hl,
      ))
      if note != none {
        place(top + left, dx: w + 10pt, dy: (a + b + 1) * h / 2 - 7pt, text(size: 8.5pt, weight: "bold", fill: hl, note))
      }
    }
  })
}

// the cover of a section: its title, a subtitle and the stack with the
// layers it talks about
// (the stack goes inside the heading: diatypst draws a section heading as a
// full page, anything after it would not be on that page)
#let section-cover(title, subtitle, layers: (), note: none) = slide[
  = #grid(
    columns: (1fr, auto),
    align: (left + horizon, horizon),
    column-gutter: 1em,
    [#title \ #block(above: 0.4em, text(size: 10pt, weight: "regular", par(leading: 0.45em, emph(subtitle))))],
    if layers.len() > 0 { text(weight: "regular", section-stack(layers, note: note)) },
  )
]

// ---------------------------------------------------------------------------
// Helpers of the link layer sections (Link Layer, Ethernet, Wi-Fi)
// ---------------------------------------------------------------------------

// a frame travelling on a cable: a small letter with who it is for
#let letter(x, y, body, color: hl) = pin(x, y, box(
  fill: if color == hl { hl-bg } else { color.lighten(88%) },
  stroke: 1pt + color,
  radius: 4pt,
  inset: (x: 4pt, y: 2.5pt),
  text(size: 7.5pt)[#icon("✉️", size: 8pt) #body],
))

// the highlight colors: peach for most parts, blue for the second kind of
// flags (what the card can do), so the two kinds of flags look different
#let ip-peach = (hl: rgb("ffd8a8"), bar: rgb("f0a050"), bg: rgb("fffaf4"))
#let ip-blue = (hl: rgb("c9e2f2"), bar: rgb("4f93c0"), bg: rgb("f3f8fc"))

// the terminal with some parts highlighted with a background: `hl` is a list
// of (parts, colors)

// an explanation: a title and a list of (term, meaning); the terms look
// like the highlighted parts of the output, so they are easy to match
#let explain(title, colors: ip-peach, ..rows) = {
  let chip(it) = box(
    fill: colors.hl,
    inset: (x: 2.5pt),
    outset: (y: 2pt),
    radius: 2pt,
    text(font: "DejaVu Sans Mono", size: 0.9em, fill: luma(40), it.text),
  )
  block(
    width: 100%,
    inset: (x: 10pt, y: 7pt),
    fill: colors.bg,
    stroke: (left: 3pt + colors.bar),
    radius: (right: 4pt),
  )[
    #title
    #if rows.pos().len() > 0 {
      v(-0.3em)
      grid(
        columns: (auto, 1fr),
        column-gutter: 0.9em,
        row-gutter: 0.5em,
        ..rows.pos().map(((term, meaning)) => ({ show raw.where(block: false): chip; term }, meaning)).flatten(),
      )
    }
  ]
}

// the fields of an Ethernet frame: (key, name, size, width, emoji, example)
#let frame-fields = (
  ("dst", [Destination MAC], [6 bytes], 96pt, "📬", "8c:16:45:a2:3b:91"),
  ("src", [Source MAC], [6 bytes], 96pt, "📤", "3c:a9:f4:5e:21:7b"),
  ("type", [Type], [2 bytes], 48pt, "🏷️", "0x0800"),
  ("data", [Payload], [46 - 1500 bytes], 144pt, "📦", none),
  ("crc", [CRC], [4 bytes], 56pt, "✅", "a3 5f 0c 19"),
)

// the frame, with the fields in `selected` outlined in orange
#let frame-drawing(
  selected: (),
  fields: frame-fields,
  groups: (("dst", "type", [*header*: 14 bytes]), ("data", "data", [*data*]), ("crc", "crc", [*trailer*])),
  packet: [*IPv4 packet* \ #text(size: 6.5pt)[from the Network layer]],
  name-size: 8pt,
) = drawing(height: 98pt, width: 440pt)[
  #let (y, h) = (24pt, 46pt)
  #let c = layer-colors.link
  #let xs = fields.fold((0pt,), (acc, f) => acc + (acc.last() + f.at(3),))
  #let x-of(key) = xs.at(fields.position(f => f.at(0) == key))
  #let end-of(key) = x-of(key) + fields.find(f => f.at(0) == key).at(3)

  // the groups above the frame: header, data, trailer
  #let group(x1, x2, body) = {
    wire((x1 + 1pt, y - 6pt), (x1 + 1pt, y - 10pt), stroke: 0.8pt + luma(130))
    wire((x1 + 1pt, y - 10pt), (x2 - 1pt, y - 10pt), stroke: 0.8pt + luma(130))
    wire((x2 - 1pt, y - 10pt), (x2 - 1pt, y - 6pt), stroke: 0.8pt + luma(130))
    pin((x1 + x2) / 2, y - 17pt, box(fill: white, inset: (x: 3pt), text(size: 7.5pt, fill: luma(80), body)))
  }
  #for (k1, k2, body) in groups { group(x-of(k1), end-of(k2), body) }

  // the frame: one bar with rounded ends, the payload holds a packet of the layer above
  #place(top + left, dx: 0pt, dy: y, box(width: xs.last(), height: h, radius: 6pt, fill: c.fill, stroke: 1pt + c.stroke, clip: true, {
    for (i, (key, name, size, w, e, ex)) in fields.enumerate() {
      let x = xs.at(i)
      if i > 0 { place(top + left, dx: x, line(length: h, angle: 90deg, stroke: 0.8pt + c.stroke)) }
      if key == "data" {
        place(top + left, dx: x, box(width: w, height: h, fill: white))
        place(top + left, dx: x + 6pt, dy: 6pt, box(
          width: w - 12pt,
          height: h - 12pt,
          radius: 3pt,
          fill: layer-colors.network.fill,
          stroke: (paint: layer-colors.network.stroke, thickness: 0.8pt, dash: "dashed"),
          align(center + horizon, text(size: 7.5pt)[#icon(e, size: 9pt) #packet]),
        ))
      } else {
        place(top + left, dx: x, box(width: w, height: h, align(center + horizon, stack(
          spacing: 4pt,
          text(size: name-size, weight: "bold")[#if e != none { icon(e, size: 9pt) } #name],
          text(size: 6.5pt, font: "DejaVu Sans Mono", fill: luma(70), ex),
        ))))
      }
    }
  }))

  // the sizes, below the frame
  #for (i, (key, name, size, w, e, ex)) in fields.enumerate() {
    place(top + left, dx: xs.at(i), dy: y + h + 6pt, box(width: w, align(center, text(
      size: 7.5pt,
      fill: luma(100),
      if key == "data" { [*payload*: #size] } else { size },
    ))))
  }

  // when some fields are selected, the other ones fade out a little and the
  // selected ones get a thin orange line under them
  #if selected.len() > 0 {
    for (i, (key, name, size, w, e, ex)) in fields.enumerate() {
      let first = i == 0
      let last = i == fields.len() - 1
      if key in selected {
        place(top + left, dx: xs.at(i) + 3pt, dy: y + h + 2pt, line(length: w - 6pt, stroke: (
          paint: hl,
          thickness: 2pt,
          cap: "round",
        )))
      } else {
        place(top + left, dx: xs.at(i), dy: y, box(
          width: w,
          height: h,
          fill: white.transparentize(35%),
          radius: (left: if first { 6pt } else { 0pt }, right: if last { 6pt } else { 0pt }),
        ))
      }
    }
  }
]

// a box of the layer drawings: name in bold, what implements it below
#let layer-box(x, y, w, h, name, layer, sub: none, size: 8pt, highlight: false) = {
  let c = layer-colors.at(layer)
  at(x, y, box(
    width: w,
    height: h,
    fill: c.fill,
    stroke: if highlight { 1.5pt + hl } else { 0.8pt + c.stroke },
    align(center + horizon, stack(
      spacing: 2pt,
      text(size: size, weight: "bold", name),
      if sub != none { text(size: 7pt, sub) },
    )),
  ))
}

// the drawings of interchangeable layers
#let iface-stroke = (paint: luma(150), thickness: 1pt, dash: "dashed")
// a standard interface between two layers: a dashed line with its name above it
#let iface(y, body, below: false) = {
  wire((20pt, y), (460pt, y), stroke: iface-stroke)
  place(top + left, dx: 20pt, dy: if below { y + 3pt } else { y - 11pt }, text(
    size: 7pt,
    style: "italic",
    fill: luma(80),
    body,
  ))
}
// a link that goes both ways between (x1, y1) (bottom of the upper box) and
// (x2, y2) (top of the lower box): down, a horizontal run at `run` with
// rounded corners, down again; a clean arrowhead at each end, the tips stop
// just before the boxes. The interface line goes just below `run`, so the
// arrow crosses it straight down.
#let both-ways(x1, y1, x2, y2, run: none, color: accent) = {
  let gap = 1.5pt
  let len = 7pt
  let half = 4pt
  let (t1, t2) = (y1 + gap, y2 - gap)
  let (b1, b2) = (t1 + len, t2 - len)
  let run = if run == none { (b1 + b2) / 2 } else { run }
  let r = calc.min(4pt, calc.abs(x2 - x1) / 2)
  let dir = if x2 > x1 { 1 } else { -1 }
  let path = if x1 == x2 {
    (curve.move((x1, b1 - 0.5pt)), curve.line((x2, b2 + 0.5pt)))
  } else {
    (
      curve.move((x1, b1 - 0.5pt)),
      curve.line((x1, run - r)),
      curve.quad((x1, run), (x1 + dir * r, run)),
      curve.line((x2 - dir * r, run)),
      curve.quad((x2, run), (x2, run + r)),
      curve.line((x2, b2 + 0.5pt)),
    )
  }
  place(top + left, curve(stroke: (paint: color, thickness: 1.4pt, cap: "butt", join: "round"), ..path))
  place(top + left, polygon(fill: color, (x1, t1), (x1 - half, b1), (x1 + half, b1)))
  place(top + left, polygon(fill: color, (x2, t2), (x2 - half, b2), (x2 + half, b2)))
}
// the options of a swappable layer: one box per option, the selected one in orange
#let option-box(x, y, w, h, body, selected: false) = place(top + left, dx: x - w / 2, dy: y, box(
  width: w,
  height: h,
  radius: 4pt,
  stroke: if selected { 1.5pt + hl } else { 0.8pt + luma(190) },
  inset: 4pt,
  align(center + horizon, body),
))

// the layers a network device "sees": a small stack under the device, with
// the layers it understands in color and the others in gray. `level` is the
// highest layer it understands (a key of `layer-colors`)
#let sees-stack(x, y, level, w: 62pt, row: 8.5pt) = {
  let all = (
    ("application", "Application"),
    ("transport", "Transport"),
    ("network", "Network"),
    ("link", "Data Link"),
    ("physical", "Physical"),
  )
  let hi = all.position(((k, n)) => k == level)
  for (i, (key, name)) in all.enumerate() {
    let on = i >= hi
    let c = layer-colors.at(key)
    place(top + left, dx: x - w / 2, dy: y + i * row, box(
      width: w,
      height: row,
      fill: if on { c.fill } else { luma(247) },
      stroke: 0.6pt + if on { c.stroke } else { luma(215) },
      align(center + horizon, text(size: 5.5pt, weight: if on { "bold" } else { "regular" }, fill: if on {
        black
      } else { luma(150) }, name)),
    ))
  }
  // two eyes next to the highest layer it sees
  pin(x + w / 2 + 10pt, y + hi * row + row / 2, icon("👀", size: 12pt))
}

// A terminal where parts of the output are highlighted with a background,
// like the `ip -br link` slide. `lines` is a list where each element is
// either a command (a string starting with "$ ") or an output line made of
// (key, text) parts; parts with the key `none` are never highlighted.
// `hl` is a list of (keys, colors).
#let parts-terminal(lines, hl: (), size: 0.92em) = {
  let text-of(l) = if type(l) == str { l } else { l.map(((k, t)) => t).join() }
  let src = lines.map(text-of).join("\n")
  show raw.line: it => {
    let l = lines.at(it.number - 1)
    // a command continued from the line above (it ended with `\`)
    let prev = if it.number > 1 { lines.at(it.number - 2) } else { none }
    let is-cont = type(prev) == str and shell-continues(prev)
    if type(l) == str { return render-terminal-line(it.text, is-continuation: is-cont) }
    text(fill: luma(100), for (k, t) in l {
      let c = hl.find(((keys, colors)) => k != none and k in keys)
      if c != none { highlight(fill: c.at(1).hl, extent: 1pt, radius: 2pt, t) } else { t }
    })
  }
  text(size: size, raw(src, block: true))
}

// An output line of a table: `cells` are (key, text), each one padded with
// spaces to its width from `widths`
// (empty cells are never highlighted)
#let tab(widths, ..cells) = cells.pos().zip(widths).fold((), (acc, ((k, t), w)) => {
  acc + ((if t.trim() == "" { none } else { k }, t), (none, " " * calc.max(1, w - t.clusters().len())))
})
