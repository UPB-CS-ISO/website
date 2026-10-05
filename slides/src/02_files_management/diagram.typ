#import "/src/slides.typ": *

// ASCII directory trees that show what a command does to the file system.
//
// #fs-tree(new: (3,), gone: (2,), ```
//   /home/alice
//   ├── a.txt
//   └── b.txt
//   ```)
//
// The tree is a raw block (or a string), one line of the tree per line.
//
// Lines are numbered from 1:
// - `new`  - created by the command (bold green, marked with `+`)
// - `gone` - removed by the command (red, struck through, marked with `-`)
// - `source` - the entries a command reads, copies or moves (bold orange;
//              a moved entry is also in `gone` and stays red, struck through)
// - `here` - the entries a command looks at (bold)
// - `cwd`  - the line of the current directory, marked with 📍
// Other lines are drawn normally. The marks keep the meaning readable
// without relying on color alone (e.g. on a black and white print).
#let fs-new-color = rgb("2e7d46")
#let fs-gone-color = rgb("c62828")
#let fs-here-color = rgb("004d65")
#let fs-source-color = rgb("e65100")

#let fs-cwd-mark = "📍"
#let fs-target-mark = "🎯"

// Marks (and icons) drawn larger than the text around them, without
// changing the line height (so the │ lines still touch) or the width
// (so the columns stay aligned). The trees use different text sizes, so
// the icons are scaled to one absolute size: the same in every tree.
#let fs-big-size = 13pt
#let fs-big-icon(icon) = context box(
  height: 0.7em,
  scale(fs-big-size / text.size * 100%, reflow: false, icon),
)

// replace every icon from `icons` in the string `body` by its big version
#let fs-big(icons: (fs-cwd-mark, fs-target-mark), body) = {
  let parts = (body,)
  for icon in icons {
    parts = parts.map(p => if p in icons { (p,) } else { p.split(icon).intersperse(icon) }).flatten()
  }
  parts.map(p => if p in icons { fs-big-icon(p) } else { p }).join()
}

#let fs-tree(new: (), gone: (), here: (), source: (), cwd: none, caption: none, tree) = {
  let tree = if type(tree) == content { tree.text } else { tree }
  let lines = tree.split("\n")
  let width = calc.max(..lines.map(l => l.clusters().len()))
  let marked = lines
    .enumerate()
    .map(((i, l)) => {
      let pad = " " * (width - l.clusters().len())
      let l = if i + 1 == cwd { l + " " + fs-cwd-mark } else { l }
      let l = if (i + 1) in new {
        l + pad + "  +"
      } else if (i + 1) in gone {
        l + pad + "  -"
      } else {
        l
      }
      l
    })
    .join("\n")

  show raw.line: it => {
    let line = fs-big(it.text)
    if it.number in new {
      text(fill: fs-new-color, weight: "bold", line)
    } else if it.number in gone {
      // strike through only the name, not the tree branches in front of it
      // nor the padding and the `-` mark after it
      let m = it.text.match(regex("^([│├└─ ]*)(.*?)(\\s+-)?$"))
      let (branch, name, mark) = m.captures.map(c => if c == none { "" } else { c })
      text(fill: fs-gone-color, fs-big(branch) + strike(fs-big(name)) + mark)
    } else if it.number in source {
      text(fill: fs-source-color, weight: "bold", line)
    } else if it.number in here {
      text(fill: fs-here-color, weight: "bold", line)
    } else {
      line
    }
  }
  raw(marked, block: true)

  if caption != none {
    v(-0.4em)
    align(center, text(size: 0.8em, style: "italic", caption))
  }
}

// legend for the colors / marks used by fs-tree
#let fs-legend = text(size: 0.7em)[
  #fs-cwd-mark current directory
  #h(1em)
  #text(fill: fs-new-color, weight: "bold")[`+` created]
  #h(1em)
  #text(fill: fs-gone-color)[#strike[`-` removed]]
]

// the same legend with the source mark, for commands that have a source (cp, mv)
#let fs-legend-source = text(size: 0.7em)[
  #fs-cwd-mark current directory
  #h(1em)
  #text(fill: fs-source-color, weight: "bold")[source]
  #h(1em)
  #text(fill: fs-new-color, weight: "bold")[`+` created]
  #h(1em)
  #text(fill: fs-gone-color)[#strike[`-` removed]]
]

// Box-drawing ASCII art (│ ┌ ─ ┐ ...): lines must touch vertically, so the
// line box spans the whole glyph (ascender to descender) with no extra gap.
// #ascii-art[```
// ┌───┐
// │ a │
// └───┘
// ```]
#let ascii-art(size: 8pt, body) = {
  set text(size: size, top-edge: "ascender", bottom-edge: "descender")
  set par(leading: 0pt)
  body
}
