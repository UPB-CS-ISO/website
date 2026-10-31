#import "/src/slides.typ": *
#import "/src/shell.typ": *

// Drawings of this lecture; the ones shared with 8. Shell Scripting (word
// chips, exit codes, the debugger, regex matches, ...) are in
// /src/shell.typ. The streams are drawn in the same style as lecture 3
// (theme color for processes, orange for whatever is new or changed on the
// current step).

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


// ---------------------------------------------------------------------------
// Text editors (moved from the Software Development deck)
// ---------------------------------------------------------------------------

#let uso-book = [*Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]]

// a screenshot with a thin border and rounded corners
#let screenshot(path, ..args) = box(
  stroke: 0.5pt + luma(180),
  radius: 4pt,
  clip: true,
  image(path, ..args),
)

// the main idea of a slide: a large callout
#let callout(body, color: changed, fill: changed-fill) = block(
  width: 100%,
  fill: fill,
  stroke: 2pt + color,
  radius: 0.4em,
  inset: (x: 0.8em, y: 0.5em),
  align(center, text(size: 1.05em, body)),
)

// a small colored tag, e.g. #tag[compiled]
#let tag(body, color: accent) = box(
  inset: (x: 0.35em, y: 0.15em),
  outset: (y: 0.1em),
  radius: 0.25em,
  fill: color.lighten(85%),
  stroke: 0.6pt + color,
  text(size: 0.75em, fill: color.darken(20%), body),
)

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

// a key chord, e.g. #ctrl("O") is Ctrl + O
#let ctrl(k) = [#kbd("Ctrl") + #kbd(k)]

#let alt(k) = [#kbd("Alt") + #kbd(k)]

// a sequence of keys, e.g. #keys("d", "w")
#let keys(..ks) = ks.pos().map(kbd).join(h(0.15em))

// an arrow glyph, in a font that has it (the slide font does not)
#let arr(a, color: changed) = text(font: mono, fill: color, weight: "bold", a)

// the arrows of a row of keys, e.g. #arrows("←↓↑→")
#let arrows(s, color: changed) = s.clusters().map(a => arr(a, color: color)).join(h(0.5em))

// a key cap like #kbd, highlighted: the key that is pressed right now
#let kbd-on(key) = box(
  fill: changed,
  stroke: (rest: 0.5pt + changed.darken(20%), bottom: 1.5pt + changed.darken(30%)),
  radius: 2.5pt,
  inset: (x: 0.3em),
  outset: (y: 0.25em),
  text(font: "DejaVu Sans Mono", size: 0.8em, fill: white, weight: "bold", key),
)

// movement keys drawn as large key caps, each with its arrow under it,
// e.g. #move-keys(("h", "←"), ("j", "↓"), ("k", "↑"), ("l", "→"));
// `on` is the key pressed right now (highlighted, the others are dimmed)
#let move-keys(..pairs, size: 18pt, on: none) = {
  set text(size: size)
  let ps = pairs.pos()
  grid(
    columns: ps.len(),
    column-gutter: 0.5em,
    row-gutter: 0.55em,
    align: center,
    ..ps.map(((k, a)) => if k == on { kbd-on(k) } else { kbd(k) }),
    grid.cell(colspan: ps.len(), text(size: 0.45em, fill: luma(110), style: "italic")[or the arrow keys]),
    ..ps.map(((k, a)) => if k == on { kbd-on(a) } else { kbd(a) }),
  )
}

// ----- the drawings of the column filters (and of the pipeline example) -----

// a field is a white chip with its number under it (blue), a delimiter is
// an orange chip; `cut` keeps the dark fields, the others are faded

// one line split into fields: `delim` - the delimiter as it is drawn (e.g.
// "␣" for a space); an empty field ("") is a dashed chip; `selected` - the
// numbers of the fields that `cut` keeps, none - all are drawn the same
#let field-line(fields, delim, size: 1.5em, selected: none, names: none) = {
  let cells = ()
  for (i, f) in fields.enumerate() {
    let n = i + 1
    if i > 0 {
      cells.push(text(size: size, box(inset: (x: 0.15em, y: 0.25em), radius: 0.2em, fill: changed-fill, stroke: 1pt + changed,
        text(font: mono, weight: "bold", fill: changed, delim))))
    }
    let on = selected != none and n in selected
    let off = selected != none and not on
    let empty = f == ""
    cells.push(stack(spacing: 0.3em,
      text(size: size, box(
        inset: (x: 0.3em, y: 0.25em),
        radius: 0.2em,
        fill: if on { accent } else { white },
        stroke: if empty { (paint: if off { luma(180) } else { accent }, thickness: 1pt, dash: "dashed") } else if off { 0.6pt + luma(190) } else { 0.8pt + accent },
        text(font: mono, fill: if on { white } else if off { luma(170) } else { black }, if empty { hide("M") } else { f }),
      )),
      text(weight: "bold", fill: if off { luma(170) } else { accent })[#if names == none [#n] else { raw(names.at(i)) }#if empty [ #text(weight: "regular", style: "italic")[empty]]],
    ))
  }
  align(center, grid(columns: cells.len(), column-gutter: 0.25em, align: center + top, ..cells))
}

// one line split into characters, numbered from 1; `selected` - the
// positions that `cut -c` keeps
#let char-line(s, size: 1.6em, selected: none) = align(center, grid(
  columns: s.clusters().len(),
  column-gutter: 0.15em,
  align: center + top,
  ..s.clusters().enumerate().map(((i, c)) => {
    let on = selected != none and (i + 1) in selected
    let off = selected != none and not on
    stack(spacing: 0.3em,
      text(size: size, box(inset: (x: 0.25em, y: 0.25em), radius: 0.2em,
        fill: if on { accent } else { white },
        stroke: if off { 0.6pt + luma(190) } else { 0.8pt + accent },
        text(font: mono, fill: if on { white } else if off { luma(170) } else { black }, c))),
      text(weight: "bold", fill: if off { luma(170) } else { accent }, str(i + 1)),
    )
  }),
))

// what `tr` does to every character: the characters on top, what they
// become under them; `pairs` - (the character, what it becomes, none if
// it is deleted); a character from the set is blue, what it becomes is
// orange, a deleted one is struck out and crossed
#let char-map(pairs, size: 1.3em) = {
  let show-c(c) = if c == " " { "␣" } else { c }
  let chip(c, stroke, fill, color, strike-it: false) = text(size: size, box(
    inset: (x: 0.22em, y: 0.22em), radius: 0.2em, stroke: stroke, fill: fill,
    text(font: mono, fill: color, if strike-it { strike(stroke: 1.5pt + fail-color, show-c(c)) } else { show-c(c) }),
  ))
  // a cross drawn with lines: the ✕ glyph is missing from the slide fonts
  let cross = box(width: 0.7em, height: 0.7em, {
    place(line(start: (0%, 0%), end: (100%, 100%), stroke: 1.8pt + fail-color))
    place(line(start: (100%, 0%), end: (0%, 100%), stroke: 1.8pt + fail-color))
  })
  let down(color, thickness) = rotate(90deg, reflow: true, draw-arrow(length: 0.9em, color: color, thickness: thickness))
  let tops = ()
  let mids = ()
  let bottoms = ()
  for (c, out) in pairs {
    let hit = out != c
    tops.push(if hit { chip(c, 1.2pt + accent, accent.lighten(85%), accent, strike-it: out == none) } else { chip(c, 0.6pt + luma(170), white, luma(120)) })
    mids.push(if out == none { cross } else if hit { down(changed, 1.5pt) } else { down(luma(200), 0.8pt) })
    bottoms.push(if out == none { [] } else if hit { chip(out, 1.2pt + changed, changed-fill, changed) } else { chip(out, 0.6pt + luma(170), white, black) })
  }
  align(center, grid(
    columns: pairs.len(),
    column-gutter: 0.18em,
    row-gutter: 0.25em,
    align: center + horizon,
    ..tops, ..mids, ..bottoms,
  ))
}

// a parameter of a command, as a chip with what it means under it
#let param(t, color: accent, means: none) = stack(spacing: 0.3em,
  box(inset: (x: 0.35em, y: 0.28em), radius: 0.2em, fill: color.lighten(88%), stroke: 1pt + color,
    text(font: mono, weight: "bold", fill: color, t)),
  if means != none { text(size: 0.7em, weight: "bold", fill: color, means) },
)

// a command line: the words and the parameters, in a row
#let cmd-line(..ps, size: 1.1em) = align(center, text(size: size, grid(
  columns: ps.pos().len(),
  column-gutter: 0.35em,
  align: center + top,
  ..ps.pos(),
)))
#let cut-line(..ps) = cmd-line(w("cut", kind: "cmd"), ..ps)
#let pipe-sym = text(fill: changed, weight: "bold", font: mono, size: 1.2em)[|]

// one step of an example, always the same layout: the command on top, the
// drawing in the middle, the input and the output under it, the note at
// the bottom; `input` - (the file name, its lines, the line drawn), or
// none; `output` - the terminal
#let col-step(cmd, drawing, input, output, note) = {
  if cmd != none { cmd; v(0.5em) }
  align(center, drawing)
  v(0.5em)
  set text(size: 0.9em)
  // `at` - the line (or the lines) drawn, in orange; a 4th item are the
  // lines drawn faded; `output` - a string is a terminal, else content
  let hl(at) = if type(at) == array { at } else { (at,) }
  let out(o) = if type(o) == str { text(size: 1.05em, terminal(o)) } else { o }
  if input != none and output != none {
    let (name, lines, at, ..rest) = input
    grid(
      columns: (1fr, auto, 1fr),
      column-gutter: 1em,
      align: horizon,
      file-contents(name, lines, new: hl(at), faded: rest.at(0, default: ()), size: 0.8em),
      draw-arrow(),
      out(output),
    )
  } else if input != none {
    let (name, lines, at, ..rest) = input
    align(center, box(width: 60%, align(left, text(size: 1.15em, file-contents(name, lines, new: hl(at), faded: rest.at(0, default: ()), size: 0.85em)))))
  } else if output != none {
    align(center, box(width: 85%, align(left, out(output))))
  }
  v(0.3em)
  note
}

// ----- the drawings of the line filters -----

// an arrow of `line-map`: an S-shaped curve from a (a dot) to b (the
// head), leaving and arriving horizontally, so the arrows that cross are
// easy to follow (the straight ones all crossed in one point for `tac`);
// a white halo under the line separates it from the arrows it crosses
#let link-arrow(a, b, color: changed, thickness: 1.4pt, head: 5pt) = {
  let (x1, y1) = a
  let (x2, y2) = b
  let end = x2 - head
  let d = (end - x1) * 0.5
  let path(paint, t) = place(top + left, curve(
    stroke: (paint: paint, thickness: t, cap: "round"),
    curve.move((x1, y1)),
    curve.cubic((x1 + d, y1), (end - d, y2), (end, y2)),
  ))
  path(white, thickness + 2.5pt)
  path(color, thickness)
  place(top + left, dx: x1 - 1.6pt, dy: y1 - 1.6pt, circle(radius: 1.6pt, fill: color, stroke: none))
  place(top + left, polygon(fill: color, stroke: none,
    (x2, y2), (end, y2 - head * 0.6), (end, y2 + head * 0.6)))
}


// what a line filter does with whole lines: the input on the left (one or
// more files, or the keyboard), the terminal on the right, and an arrow
// from every input line to the output line it becomes; the column filters
// draw one line, the line filters draw the whole file
// - `inputs` - ((header, lines), ...), e.g. ((file("fruits.txt"), fruits),)
// - `cmd` - the command, the first line of the terminal
// - `outs` - the output lines, as the real terminal prints them
// - `links` - (i, j): input line i becomes output line j (both from 0, the
//   input lines counted over all the inputs); several lines may go to the
//   same output line (`uniq`), a line with no link is dropped (faded, as the
//   fields `cut` does not keep)
// - `new` - output lines drawn orange even if they stay in place
// - `in-new` - input lines drawn orange (e.g. a line added to a log)
// - `after` - terminal lines after the output, drawn gray (e.g. "^D")
// - `colored` - every input line gets its own color, used by its arrow and
//   by the output line it becomes: to follow the lines when all of them
//   move and the arrows cross (`tac`)
// - `height` - the minimum height: the same on every step of a slide, so
//   the note under the drawing does not move
// an arrow (and its output line) is orange when the line moves, gray when it
// stays where it was
// #line-map(((file("fruits.txt"), fruits),), "tac fruits.txt", fruits.rev(),
//   range(7).map(i => (i, 6 - i)))
#let line-map(inputs, cmd, outs, links, new: (), in-new: (), after: (), row: 11.5pt, size: 8.5pt,
  in-width: 120pt, out-width: 150pt, gap: 85pt, height: 0pt, colored: false) = {
  let palette = (rgb("1565c0"), rgb("c62828"), rgb("2e7d46"), rgb("7b1fa2"), rgb("e65100"), rgb("00838f"), rgb("8d6e00"))
  let line-color(i) = palette.at(calc.rem(i, palette.len()))
  // the input line of every output line (the first one, if several)
  let source(j) = links.find(((i, jj)) => jj == j).at(0, default: none)
  let pad = row * 0.4
  let head = row * 1.3
  let card-gap = 4pt
  let n-in = inputs.map(((h, ls)) => ls.len()).sum()
  let linked = links.map(((i, j)) => i)
  let some-dropped = range(n-in).any(i => i not in linked)
  let moved(i, j) = i != j or j in new
  let hot = links.filter(((i, j)) => moved(i, j)).map(((i, j)) => j) + new

  // the input cards, one under the other, and where every line is (y)
  let cards = ()
  let in-y = ()
  let y = 0pt
  let k = 0
  for (header, ls) in inputs {
    let h = head + 2 * pad + ls.len() * row
    let body = block(width: in-width, height: h, radius: 0.3em, clip: true, stroke: 0.8pt + luma(150), fill: white, {
      block(width: 100%, height: head, fill: luma(235), inset: (x: 0.5em), below: 0pt,
        align(horizon, text(size: size, header)))
      v(pad)
      for (n, l) in ls.enumerate() {
        let i = k + n
        let color = if colored and i in linked { line-color(i) } else if i in in-new { changed } else if not some-dropped { black } else if i in linked { accent } else { dim }
        block(height: row, above: 0pt, below: 0pt, inset: (x: 0.6em),
          align(horizon, text(font: mono, size: size, fill: color, weight: if some-dropped and i in linked { "bold" } else { "regular" }, l)))
      }
    })
    cards.push((y, body))
    for n in range(ls.len()) { in-y.push(y + head + pad + (n + 0.5) * row) }
    y += h + card-gap
    k += ls.len()
  }
  let in-h = y - card-gap

  // the terminal: the command, the output lines, the lines after them
  let rows = outs.len() + after.len() + 1
  let out-h = 2 * pad + rows * row
  let out-y(j) = pad + (j + 1.5) * row
  let term = block(width: out-width, height: out-h, radius: 0.3em, fill: rgb("e6edf0"), inset: (x: 0.6em, y: pad), {
    set text(font: mono, size: size)
    block(height: row, above: 0pt, below: 0pt, align(horizon, render-terminal-line("$ " + cmd)))
    for (j, l) in outs.enumerate() {
      block(height: row, above: 0pt, below: 0pt, align(horizon, text(fill: if colored and source(j) != none { line-color(source(j)) } else if j in hot { changed } else { luma(100) }, l)))
    }
    for l in after {
      block(height: row, above: 0pt, below: 0pt, align(horizon, text(fill: luma(150), l)))
    }
  })

  let total-h = calc.max(in-h, out-h, height)
  // center the shorter side
  let dy-in = (total-h - in-h) / 2
  let dy-out = (total-h - out-h) / 2
  box(width: in-width + gap + out-width, height: total-h, {
    for (cy, c) in cards { place(top + left, dy: dy-in + cy, c) }
    place(top + left, dx: in-width + gap, dy: dy-out, term)
    // the gray arrows first, so the orange ones are drawn on top
    for hot-pass in (false, true) {
      for (i, j) in links {
        if moved(i, j) == hot-pass {
          link-arrow(
            (in-width + 4pt, dy-in + in-y.at(i)),
            (in-width + gap - 3pt, dy-out + out-y(j)),
            color: if colored { line-color(i) } else if hot-pass { changed } else { luma(150) },
            thickness: if hot-pass { 1.4pt } else { 1pt },
          )
        }
      }
    }
  })
}

// the steps of a slide, one after the other; the last one stays
#let col-steps(steps) = for (i, s) in steps.enumerate() {
  only(if i == steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }, col-step(..s))
}

// the parts of an `awk` command, always in the same colors (as on the
// "What Is awk" slide): the delimiter orange, a condition green, an
// action blue, the END block purple
#let awk-delim(t, means: none) = param(t, color: changed, means: means)
#let awk-cond(t, means: none) = param(t, color: ok-color, means: means)
#let awk-action(t, means: none) = param(t, color: accent, means: means)
#let awk-end(t, means: none) = param(t, color: rgb("9a4d76"), means: means)
