// A keyboard key, styled like Docusaurus' <kbd> element: a light key cap with
// a thin border and a slightly thicker bottom edge, in a monospace font.
// #kbd("q"), #kbd("Ctrl") + #kbd("C"), #kbd("↑")
//
// The vertical padding is an `outset`, not an `inset`: it only grows the key
// cap around the letter and does not take part in the layout, so the letter
// always sits on the baseline of the surrounding text (no `baseline` shift
// needed, which behaves differently between Typst versions).
#let kbd-border = luma(175)

#let kbd(key) = box(
  fill: luma(250),
  stroke: (rest: 0.5pt + kbd-border, bottom: 1.5pt + kbd-border),
  radius: 2.5pt,
  inset: (x: 0.3em),
  outset: (y: 0.25em),
  text(font: "DejaVu Sans Mono", size: 0.8em, fill: luma(40), key),
)
