#import "/src/slides.typ": *

// Process trees that grow (or change) from one subslide to the next,
// the Typst version of Slidev's `magic-move`.
//
// #tree-steps((
//   ```
//   [PID 0]  swapper
//   ```,
//   ```
//   [PID 0]  swapper
//   └── [PID 1]  systemd
//   ```,
// ))
//
// Every entry is one subslide. A line that was not in the previous step
// (ignoring the │ ├ └ ─ branches in front of it, so a └── that turns into
// a ├── does not count) is drawn bold, in the theme color. Lines whose
// text starts with `#` are comments and are drawn in gray italic.
#let tree-new-color = rgb("004d65")
#let tree-comment-color = luma(130)

// the text of a line without the tree branches in front of it
#let tree-strip(line) = line.trim(regex("[│├└─ ]+"), at: start)

#let tree-steps(start: 1, last-stays: true, steps) = {
  let steps = steps.map(s => if type(s) == content { s.text } else { s })
  for (idx, step) in steps.enumerate() {
    let prev = if idx == 0 {
      // nothing is new on the first step
      step.split("\n").map(tree-strip)
    } else {
      steps.at(idx - 1).split("\n").map(tree-strip)
    }
    let when = if last-stays and idx == steps.len() - 1 {
      (beginning: start + idx)
    } else {
      start + idx
    }
    only(when)[
      #show raw.line: it => {
        let name = tree-strip(it.text)
        let is-new = name != "" and not (name in prev)
        let is-comment = name.starts-with("#")
        let style = if is-comment { "italic" } else { "normal" }
        if is-new {
          text(fill: tree-new-color, weight: "bold", style: style, it.text)
        } else if is-comment {
          text(fill: tree-comment-color, style: style, it.text)
        } else {
          it.text
        }
      }
      #raw(step, block: true)
    ]
  }
}

// Box-drawing trees: the │ lines must touch vertically, so the line box
// spans the whole glyph with no extra gap between the lines.
#let tree-text(size: 8pt, body) = {
  set text(size: size, top-edge: "ascender", bottom-edge: "descender")
  set par(leading: 0pt)
  body
}
