#import "/src/slides.typ": *

// Shared drawings for this lecture, in the same style as the stream
// drawings of lecture 3 (orange for whatever is new or changed on the
// current step).

#let accent = rgb("004d65")
#let changed = rgb("e65100")

#let changed-fill = rgb("fff3e0")

#let mono = "DejaVu Sans Mono"

// a white background behind the diagrams, so they read well on any theme
#let diagram(path, ..args) = box(fill: white, inset: 5pt, radius: 0.3em, image(path, ..args))

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

// a small arrow to use inside text, e.g. `*.txt` #arrow `notes.txt`
// (arrow glyphs are missing from some fonts and show up as boxes)
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// a device or a file at one end of a stream
#let endpoint(changed-end: false, body) = box(
  inset: (x: 0.5em, y: 0.4em),
  radius: 0.3em,
  stroke: if changed-end { 1.5pt + changed } else { 0.8pt + luma(150) },
  fill: white,
  text(fill: if changed-end { changed } else { black }, body),
)

// ----- the words of a command line (The Command Line, Quoting and Globbing) -----

// "word" - a plain word, "cmd" - the command, "new" - changed on this step,
// "redir" - a redirect, the shell keeps it for itself
#let w(t, kind: "word") = box(
  inset: (x: 0.35em, y: 0.28em),
  outset: (y: 1pt),
  radius: 2pt,
  fill: if kind == "cmd" { accent } else { white },
  stroke: if kind == "cmd" { none } else if kind == "redir" {
    (paint: changed, thickness: 1pt, dash: "dashed")
  } else if kind == "new" { 1.3pt + changed } else { 0.7pt + luma(130) },
  text(
    font: mono,
    size: 0.85em,
    fill: if kind == "cmd" { white } else if kind == "new" or kind == "redir" { changed } else { black },
    t,
  ),
)
// words("ls", ("-l", "new"), ...): a string is a plain word, an array is (text, kind)
#let words(..ws) = ws.pos().map(x => if type(x) == str { w(x) } else { w(x.at(0), kind: x.at(1)) }).join(h(0.3em))

// a row of a schematic: a small label on the left, the content on the right
#let label(body) = text(size: 0.8em, fill: luma(110), style: "italic", body)
