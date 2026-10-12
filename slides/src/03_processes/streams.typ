#import "/src/slides.typ": *

// Schematics of a process and where its standard streams go:
//
//   ⌨ keyboard ⟶ (0) ┌──────┐ (1) ⟶ 🖥 display
//                    │ sort │ (2) ⟶ 🖥 display
//                    └──────┘
//
// Anything that a redirect (or a pipe) changes is drawn in orange, so the
// difference between two subslides is easy to spot (and readable in black
// and white too, as changed parts are also bold and thicker).
#let stream-accent = rgb("004d65")
#let stream-changed = rgb("e65100")
#let stream-changed-fill = rgb("fff3e0")
#let stream-mono = "DejaVu Sans Mono"

#let stream-unused = luma(185)

// a device or a file at one end of a stream
// `unused` - the stream is open, but the process does not use it (dashed, gray)
// `width` - a fixed width, so a drawing does not move when the endpoint changes
#let endpoint(changed: false, unused: false, width: auto, body) = box(
  width: width,
  inset: (x: 0.5em, y: 0.4em),
  radius: 0.3em,
  stroke: if changed { 1.5pt + stream-changed } else if unused {
    (paint: stream-unused, thickness: 0.8pt, dash: "dashed")
  } else { 0.8pt + luma(150) },
  fill: if changed { stream-changed-fill } else { white },
  align(center, text(
    fill: if changed { stream-changed } else if unused { stream-unused } else { black },
    weight: if changed { "bold" } else { "regular" },
    body,
  )),
)

#let keyboard = [⌨️ keyboard]
#let display = [🖥️ display]
#let file(name) = [📄 #text(font: stream-mono, size: 0.85em, name)]

// an arrow pointing right, drawn with shapes rather than an arrow glyph
// (the glyph is missing from some fonts and shows up as a box)
#let draw-arrow(length: 2em, color: luma(120), thickness: 1.5pt) = {
  let height = 0.7em
  let mid = height / 2
  let head = 0.5em
  box(width: length, height: height, baseline: 0.1em, {
    // all the points are measured from the top left corner of the box,
    // so the line and the head are always on the same axis
    place(top + left, line(start: (0em, mid), end: (length - head + 0.05em, mid), stroke: thickness + color))
    place(top + left, polygon(
      fill: color,
      (length - head, mid - 0.3em),
      (length, mid),
      (length - head, mid + 0.3em),
    ))
  })
}

// the direction the data flows
#let flow(changed: false, unused: false) = draw-arrow(
  color: if changed { stream-changed } else if unused { stream-unused } else { luma(120) },
)

// a file descriptor: the index in the File Descriptor Table
#let fd(n, changed: false, unused: false, size: 1.5em) = box(
  baseline: 20%,
  width: size,
  height: size,
  radius: 50%,
  fill: if changed { stream-changed } else if unused { stream-unused } else { luma(90) },
  align(center + horizon, text(fill: white, weight: "bold", size: 0.8em, str(n))),
)

#let process(name) = box(
  width: 5em,
  height: 4.2em,
  fill: stream-accent,
  radius: 0.3em,
  align(center + horizon, text(fill: white, weight: "bold", font: stream-mono, size: 0.9em, name)),
)

// the connection of a redirected stream, drawn over two rows of the
// process drawing (the new endpoint is on the row above the old one):
// - `in`:  new endpoint (top) ──┐        old endpoint (bottom) ╌╌  ┌─▶ fd
//                               └─▶ fd                          ...
// - `out`: fd ─┐ ┌─▶ new endpoint (top)
//              └─┘     ╌╌ old endpoint (bottom)
// - `down`: fd ─┐  ╌╌ old endpoint (top)
//               └─▶ new endpoint (bottom)
// the old endpoint keeps a short dashed gray stub: it is not connected anymore
#let stream-row-gutter = 0.8em
// every row of a process drawing has this height, so the rerouted
// connections know where the middle of each row is
#let stream-row-height = 1.9em
#let reroute(direction, width: 2.4em) = {
  let row = stream-row-height
  let h = 2 * row + stream-row-gutter
  let y-top = row / 2
  let y-bottom = h - row / 2
  let head = 0.5em
  let c = stream-changed
  let stroke = (paint: c, thickness: 1.5pt, join: "round")
  let stub = (paint: stream-unused, thickness: 1.5pt, dash: "dashed")
  // from the row of the new endpoint to the row of the file descriptor,
  // or the other way around
  // `stub-y` is the row of the old endpoint
  let (from-y, to-y, turn-x, stub-from, stub-to, stub-y) = if direction == "in" {
    (y-top, y-bottom, width * 0.55, 0em, width * 0.35, y-bottom)
  } else if direction == "out" {
    (y-bottom, y-top, width * 0.4, width * 0.65, width, y-bottom)
  } else {
    // "down": the file descriptor is on the top row, the new endpoint below
    (y-top, y-bottom, width * 0.4, width * 0.65, width, y-top)
  }
  box(width: width, height: h, {
    place(top + left, line(start: (stub-from, stub-y), end: (stub-to, stub-y), stroke: stub))
    place(top + left, curve(
      stroke: stroke,
      curve.move((0em, from-y)),
      curve.line((turn-x, from-y)),
      curve.line((turn-x, to-y)),
      curve.line((width - head + 0.05em, to-y)),
    ))
    place(top + left, polygon(
      fill: c,
      (width - head, to-y - 0.3em),
      (width, to-y),
      (width - head, to-y + 0.3em),
    ))
  })
}

// one process with its three standard streams
// - `changed` lists the file descriptors that a redirect changed
// - `unused` lists the file descriptors that are open, but not used
// - `extra` is one more file the process opened itself, read through the
//   descriptor `extra.at(0)`, drawn under `stdin`: (fd, endpoint, changed)
// - `hide-extra` keeps the space of `extra`, without drawing it, so the
//   drawing does not move when `extra` shows up on the next subslide
// - `redirect-in` / `redirect-out`: the endpoint that replaces `stdin` /
//   `stdout`; it is drawn above the old one, which stays grayed out
// - `redirect-err`: the endpoint that replaces `stderr`, drawn under the old one
// - `opened-in`: a file that is already open (drawn where `redirect-in` would
//   be), but not connected yet: `stdin` is still the old endpoint;
//   `opened-fd` is the file descriptor it got (drawn next to it)
// - `top-row` / `bottom-row` keep the space of that row on the steps without
//   a redirect, so the drawing does not move when the redirect shows up
// - `endpoint-width` - the width of every endpoint box
#let one-process(
  name,
  stdin: keyboard,
  stdout: display,
  stderr: display,
  changed: (),
  unused: (),
  extra: none,
  hide-extra: false,
  redirect-in: none,
  redirect-out: none,
  redirect-err: none,
  opened-in: none,
  opened-fd: none,
  top-row: false,
  bottom-row: false,
  endpoint-width: 7.5em,
) = {
  let changed = (
    changed
      + if redirect-in != none { (0,) } else { () }
      + if redirect-out != none { (1,) } else { () }
      + if redirect-err != none { (2,) } else { () }
  )
  let style(n) = (changed: n in changed, unused: n in unused)
  // every endpoint has the same width, so the drawing does not move
  // between the subslides of a redirect
  let endpoint = endpoint.with(width: endpoint-width)
  let extra-cells = if extra == none { ([], [], []) } else {
    let (n, target, is-changed) = extra
    (
      endpoint(changed: is-changed, target),
      flow(changed: is-changed),
      fd(n, changed: is-changed),
    ).map(c => if hide-extra { hide(c) } else { c })
  }
  let has-top = top-row or redirect-in != none or redirect-out != none or opened-in != none
  let top-cells = if not has-top { () } else {
    (
      if redirect-in != none { endpoint(changed: true, redirect-in) } else if opened-in != none {
        endpoint(changed: true, opened-in)
      } else { hide(endpoint(keyboard)) },
      if redirect-in != none { grid.cell(rowspan: 2, reroute("in")) } else if opened-in != none and opened-fd != none {
        flow(changed: true)
      } else { [] },
      if redirect-in == none and opened-in != none and opened-fd != none { fd(opened-fd, changed: true) } else { [] },
      [], [],
      if redirect-out != none { grid.cell(rowspan: 2, reroute("out")) } else { [] },
      if redirect-out != none { endpoint(changed: true, redirect-out) } else { [] },
    )
  }
  let in-cells = if redirect-in != none {
    (endpoint(unused: true, stdin), fd(0, changed: true))
  } else {
    (endpoint(..style(0), stdin), flow(..style(0)), fd(0, ..style(0)))
  }
  let out-cells = if redirect-out != none {
    (fd(1, changed: true), endpoint(unused: true, stdout))
  } else {
    (fd(1, ..style(1)), flow(..style(1)), endpoint(..style(1), stdout))
  }
  let err-cells = if redirect-err != none {
    (fd(2, changed: true), grid.cell(rowspan: 2, reroute("down")), endpoint(unused: true, stderr))
  } else {
    (fd(2, ..style(2)), flow(..style(2)), endpoint(..style(2), stderr))
  }
  let bottom-cells = if redirect-err != none {
    ([], [], [], [], [], endpoint(changed: true, redirect-err))
  } else if bottom-row {
    ([], [], [], [], [], [], hide(endpoint(display)))
  } else { () }
  grid(
    columns: (auto, 2.4em, auto, auto, auto, 2.4em, auto),
    column-gutter: 0.4em,
    row-gutter: stream-row-gutter,
    rows: stream-row-height,
    align: center + horizon,
    ..top-cells,
    ..in-cells,
    grid.cell(rowspan: 2, process(name)),
    ..out-cells,

    ..extra-cells,
    ..err-cells,
    ..bottom-cells,
  )
}

// the pipe: a buffer kept by the kernel, written at one end, read at the other
#let pipe-buffer = box(
  inset: (x: 0.6em, y: 0.4em),
  radius: 0.3em,
  stroke: 1.5pt + stream-changed,
  fill: stream-changed-fill,
)[
  #set align(center)
  #text(fill: stream-changed, weight: "bold")[pipe] \
  #text(size: 0.65em)[_kernel buffer_]
]

// a small File Descriptor Table, `rows` are (fd, points to, changed)
// `title` replaces the default "FD Table of `name`" header
#let fd-table(name, rows, title: none) = {
  set text(size: 0.75em)
  table(
    columns: (auto, auto),
    inset: (x: 0.5em, y: 0.3em),
    align: (center, left),
    table.header(table.cell(colspan: 2, if title != none { title } else [FD Table of #text(font: stream-mono, name)])),
    ..rows
      .map(((n, target, changed)) => (
        fd(n, changed: changed, size: 1.3em),
        if changed { text(fill: stream-changed, weight: "bold", target) } else { target },
      ))
      .flatten(),
  )
}

// the contents of a text file, one line per entry; `new` lists the lines
// (from 1) that were just written, drawn in orange
#let file-contents(name, lines, new: ()) = block(
  width: 100%,
  radius: 0.3em,
  clip: true,
  stroke: 0.8pt + luma(150),
  fill: white,
)[
  #block(width: 100%, fill: luma(235), inset: (x: 0.6em, y: 0.4em), below: 0pt)[
    #set text(size: 0.85em)
    #file(name)
  ]
  #block(width: 100%, inset: (x: 0.6em, y: 0.5em), above: 0pt)[
    #set text(font: stream-mono, size: 0.8em)
    #for (i, l) in lines.enumerate() {
      if (i + 1) in new {
        text(fill: stream-changed, weight: "bold", l)
      } else { l }
      linebreak()
    }
  ]
]
