#import "/src/slides.typ": *

// Drawings shared by the text processing slides (filters.typ and
// pipelines.typ), written for 4. Command Line Interface and kept here for
// later use, in the same style as the stream drawings of lecture 3.

// Shared drawings for this lecture, in the same style as the stream
// drawings of lecture 3 (theme color for processes, orange for whatever is
// new or changed on the current step).
#let accent = rgb("004d65")

#let changed = rgb("e65100")

#let changed-fill = rgb("fff3e0")

#let dim = luma(175)

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

// a process, `new` draws it in orange (it was just added)
#let process(name, new: false, faded: false) = box(
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.3em,
  fill: if new { changed } else if faded { luma(235) } else { accent },
  text(
    fill: if faded { luma(150) } else { white },
    weight: "bold",
    font: mono,
    size: 0.8em,
    name,
  ),
)

// a device or a file at one end of a stream
#let endpoint(changed-end: false, body) = box(
  inset: (x: 0.5em, y: 0.4em),
  radius: 0.3em,
  stroke: if changed-end { 1.5pt + changed } else { 0.8pt + luma(150) },
  fill: if changed-end { changed-fill } else { white },
  text(fill: if changed-end { changed } else { black }, body),
)

#let keyboard = [⌨️ keyboard]

#let display = [🖥️ display]

#let file(name) = [📄 #text(font: mono, size: 0.85em, name)]

// a pipe between two processes, drawn as an arrow labeled `|`
#let pipe-arrow(new: false) = {
  let c = if new { changed } else { luma(120) }
  box(baseline: 0.1em)[
    #set align(center)
    #set par(leading: 0.2em)
    #text(fill: c, weight: "bold", font: mono, size: 0.75em)[|] \
    #draw-arrow(length: 1.8em, color: c)
  ]
}

// a pipeline: `cmds` are the commands, only the first `upto` are drawn
// (the others keep their space, so the drawing does not move), the last
// drawn one is orange when `highlight-last` is true
#let chain(cmds, upto: none, highlight-last: true) = {
  let upto = if upto == none { cmds.len() } else { upto }
  let cells = ()
  for (i, c) in cmds.enumerate() {
    let shown = i < upto
    let is-new = highlight-last and i == upto - 1
    if i > 0 {
      let a = pipe-arrow(new: is-new)
      cells.push(if shown { a } else { hide(a) })
    }
    let p = process(c, new: is-new)
    cells.push(if shown { p } else { hide(p) })
  }
  box(cells.join(h(0.3em)))
}

// the contents of a text file, one line per entry; `new` lists the lines
// (from 1) drawn in orange, `faded` the lines drawn in light gray
#let file-contents(name, lines, new: (), faded: (), size: 0.8em) = block(
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
    #set text(font: mono, size: size)
    #set par(leading: 0.45em)
    #for (i, l) in lines.enumerate() {
      if (i + 1) in new {
        text(fill: changed, weight: "bold", l)
      } else if (i + 1) in faded {
        text(fill: dim, l)
      } else { l }
      linebreak()
    }
  ]
]
