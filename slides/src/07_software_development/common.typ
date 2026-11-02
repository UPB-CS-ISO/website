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
#let dap-spec = [_Debug Adapter Protocol Specification_, #link("https://microsoft.github.io/debug-adapter-protocol/")[online]]
#let pro-git = [*Scott Chacon, Ben Straub*, _Pro Git_, 2#super[nd] Edition, Apress, 2014, #link("https://git-scm.com/book/en/v2")[online]]

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

// a screenshot with orange frames around the parts the slide talks about
// - size: the size of the image in pixels, marks: (x, y, width, height) in pixels
// e.g. #marked-screenshot("img/gui/x.png", size: (1600, 1000), marks: ((48, 70, 300, 110),), width: 100%)
#let marked-screenshot(path, size: (1, 1), marks: (), color: changed, width: 100%) = box(
  width: width,
  stroke: 0.5pt + luma(180),
  radius: 4pt,
  clip: true,
  layout(region => {
    let (iw, ih) = size
    let k = region.width / iw // the length of one pixel of the image
    image(path, width: region.width)
    for (x, y, w, h) in marks {
      place(top + left, dx: x * k, dy: y * k, rect(width: w * k, height: h * k, stroke: 2pt + color, radius: 2pt))
    }
  }),
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

// a source file: a frame with a title bar holding the file name, the code
// below it (the code block keeps its own style, the frame clips its corners)
// e.g. #code-file("hello.c")[```c int main(void) { ... }```]
#let code-file(name, body) = block(
  width: 100%,
  stroke: 1pt + luma(160),
  radius: 0.4em,
  clip: true,
  stack(
    block(
      width: 100%,
      fill: luma(225),
      inset: (x: 0.7em, y: 0.35em),
      text(font: mono, size: 0.8em, weight: "bold", fill: luma(60), name),
    ),
    block(width: 100%, body),
  ),
)

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

// a popup card drawn over the slide: a colored (default orange) title bar, a white body and a
// soft shadow; `width` must be absolute (the shadow is sized from the card)
// usage: #place(bottom + right, popup(width: 300pt)[Title][body])
#let popup(width: 300pt, color: changed, title, body) = {
  let card = block(
    width: width, fill: white, stroke: 1.5pt + color, radius: 0.5em, clip: true,
    stack(
      block(width: 100%, fill: color, inset: (x: 0.8em, y: 0.4em),
        text(fill: white, weight: "bold", size: 0.85em, title)),
      block(width: 100%, inset: (x: 0.8em, y: 0.6em), text(size: 0.8em, body)),
    ),
  )
  context {
    let h = measure(card).height
    box(width: width + 5pt, height: h + 5pt, {
      place(top + left, dx: 5pt, dy: 5pt,
        rect(width: width, height: h, radius: 0.5em, fill: black.transparentize(80%), stroke: none))
      place(top + left, card)
    })
  }
}

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

// ---------------------------------------------------------------------------
// Protocols (LSP, DAP)
// ---------------------------------------------------------------------------

// m editors x n tools: without a protocol (a plugin for every pair) or with
// one (every editor and every tool plug into the same interface)
// - editors: the names on the left
// - chips: what each plugin supports, drawn without the protocol
// - servers: (name, sub) of the programs on the right, drawn with the protocol
// - protocol, client, server: the labels of the interface
// - note, before, after: captions (above, below without / with the protocol)
// e.g. #many-to-many(true, editors: ("vim",), chips: ("C",),
//        servers: (("clangd", "C"),), protocol: "LSP", ...)
#let many-to-many(
  with-protocol,
  editors: (),
  chips: (),
  servers: (),
  protocol: "LSP",
  client: [],
  server: [],
  note: [],
  before: [],
  after: [],
) = drawing(width: 440pt, height: 182pt, {
  let ys = range(editors.len()).map(i => 16pt + i * 32pt)
  let (xl, xr) = (40pt, 400pt)
  if not with-protocol {
    // every editor carries its own plugin for every tool
    pin(264pt, -5pt, text(size: 7pt, fill: changed, note))
    for a in ys {
      place(top + left, dx: 0pt, dy: a - 14pt, box(width: 424pt, height: 28pt, radius: 0.4em, fill: luma(248), stroke: (paint: luma(190), thickness: 0.6pt, dash: "dashed")))
      for (j, l) in chips.enumerate() {
        pin(140pt + j * 62pt, a, box(
          width: 54pt,
          height: 22pt,
          radius: 0.2em,
          fill: changed-fill,
          stroke: 0.8pt + changed,
          align(center + horizon, text(size: 9pt, fill: changed, weight: "bold")[#l]),
        ))
      }
    }
    pin(220pt, 172pt, text(size: 8pt, fill: changed, before))
  } else {
    // the protocol is an interface: editors plug in on one side, servers on the other
    let (cx, bw) = (220pt, 46pt) // center and width of the interface
    let (bl, br) = (cx - bw / 2, cx + bw / 2)
    let srv-left = xr - 10pt - 42pt
    let cable = (paint: accent, thickness: 2pt, cap: "round")
    // a plug: a body and two prongs, pointing towards the interface
    let plug(x, y, dir) = {
      // dir = 1: plugs in from the left, dir = -1: from the right
      let (body-w, body-h, prong) = (9pt, 14pt, 5pt)
      let bx = if dir == 1 { x - prong - body-w } else { x + prong }
      place(top + left, dx: bx, dy: y - body-h / 2, box(width: body-w, height: body-h, radius: 2pt, fill: accent))
      let px = if dir == 1 { x - prong } else { x }
      for d in (-3.5pt, 3.5pt) {
        place(top + left, dx: px, dy: y + d - 1pt, box(width: prong, height: 2pt, fill: luma(110)))
      }
    }
    for a in ys {
      place(top + left, line(start: (xl + 32pt, a), end: (bl - 14pt, a), stroke: cable))
      place(top + left, line(start: (br + 14pt, a), end: (srv-left, a), stroke: cable))
    }
    // the interface: a strip of sockets
    place(top + left, dx: bl, dy: 0pt, box(width: bw, height: 160pt, radius: 0.5em, fill: rgb("eef3f5"), stroke: 1.5pt + accent))
    for a in ys {
      for (x, dir) in ((bl, 1), (br, -1)) {
        plug(x, a, dir)
      }
    }
    pin(cx, 80pt, rotate(-90deg, reflow: true, text(size: 15pt, fill: accent, weight: "bold", tracking: 2pt, protocol)))
    pin((xl + 32pt + bl) / 2, ys.at(0) - 8pt, text(size: 6.5pt, fill: luma(100), style: "italic", client))
    pin((br + srv-left) / 2, ys.at(0) - 8pt, text(size: 6.5pt, fill: luma(100), style: "italic", server))
    pin(220pt, 172pt, text(size: 8pt, fill: accent, after))
  }
  for (i, e) in editors.enumerate() {
    pin(xl, ys.at(i), file-box(e, width: 64pt))
  }
  if with-protocol {
    for (i, (name, sub)) in servers.enumerate() {
      pin(xr - 10pt, ys.at(i), tool-box(name, sub: sub, width: 84pt))
    }
  }
})

// one protocol message, as a card
// - to-server: true from the editor to the server, false the other way
// - kind: "notification" (LSP) / "event" (DAP): no answer; "request" (has an id), "answer" / "response"
// - method: the name of the message, body: its fields, one string per line
// - server: the name of the other side
// e.g. #protocol-msg(true, "request", "textDocument/hover", ("id: 2",), server: [`clangd`])
#let protocol-msg(to-server, kind, method, body, server: [server]) = block(
  width: 100%,
  fill: if to-server { rgb("eef3f5") } else { changed-fill },
  stroke: 0.8pt + if to-server { accent } else { changed },
  radius: 0.4em,
  inset: 0.5em,
  below: 0.5em,
  {
    text(size: 0.8em, weight: "bold", fill: if to-server { accent } else { changed })[
      #if to-server [editor #sym.arrow #server] else [#server #sym.arrow editor]: #raw(method)
    ]
    h(1fr)
    box(
      fill: if kind in ("event", "notification") { luma(120) } else { accent },
      radius: 0.6em,
      inset: (x: 0.45em, y: 0.15em),
      text(size: 0.6em, fill: white, weight: "bold", kind),
    )
    block(above: 0.4em, text(font: mono, size: 0.7em, raw(body.join("\n"), block: true)))
  },
)

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

// ---------------------------------------------------------------------------
// make: drawings shared by the two make sections
// ---------------------------------------------------------------------------

// the files of a project, drawn like the output of `tree`
// - root: the folder, files: the files in it (sorted like `ls`)
// - states: file -> "changed" (we edited it, orange), "new" (we created it,
//   orange), "built" (make created or rebuilt it, green), "deleted" (red),
//   or a custom (color, fill, note) array
// - times: file -> its modification time, shown next to the name
// - rows: the number of file lines to reserve (empty lines at the end), so
//   the drawing keeps the same height while files appear or disappear
// e.g. #project-tree("hello", ("Makefile", "hello.c", "hello.o"),
//        states: ("hello.o": "built"), times: ("hello.o": "11:41:10"), rows: 4)
#let project-tree(root, files, states: (:), times: (:), rows: 0) = {
  let files = files.sorted()
  let style = (
    changed: (changed, changed-fill, [edited]),
    built: (ok-color, ok-fill, [built]),
    deleted: (bad-color, bad-fill, [deleted]),
    new: (changed, changed-fill, [new file]),
  )
  let cells = ()
  for (i, f) in files.enumerate() {
    let branch = if i == files.len() - 1 { "└── " } else { "├── " }
    let st = states.at(f, default: none)
    let (ink, fill, note) = if st == none { (black, none, []) } else if type(st) == array { st } else {
      style.at(st)
    }
    let name = box(fill: fill, outset: (x: 1pt, y: 1.5pt), radius: 1pt, text(fill: ink, f))
    cells.push(text(fill: luma(150), branch) + name)
    cells.push(text(fill: if st in ("changed", "built") { ink } else { luma(110) }, times.at(f, default: "")))
    cells.push(text(font: "DejaVu Sans", size: 0.85em, style: "italic", fill: ink, note))
  }
  for _ in range(files.len(), rows) {
    cells += ([ ], [], [])
  }
  block(
    fill: luma(248),
    stroke: 0.6pt + luma(190),
    radius: 0.3em,
    inset: (x: 0.6em, y: 0.5em),
    text(font: mono, size: 0.6em, {
      text(weight: "bold", fill: accent, root + "/")
      v(0.35em, weak: true)
      grid(columns: 3, column-gutter: 0.7em, row-gutter: 0.42em, ..cells)
    }),
  )
}

// the files of the project
#let sources = ("lib.c", "lib.h", "main.c", "print.c", "print.h")
#let objects = ("main.o", "lib.o", "print.o")
#let built = objects + ("app",)
// the project tree: `with` are the files besides the sources and the
// Makefile, the drawing always reserves room for the whole project
#let proj-tree(with: (), states: (:), times: (:), makefile: true, extra-rows: 0) = project-tree(
  "project",
  (if makefile { ("Makefile",) } else { () }) + sources + with,
  states: states,
  times: times,
  rows: 11 + extra-rows,
)

// a listing shown like in a debugger: line numbers in a gutter and, on each
// step, the current line(s) marked with an arrow and a colored bar; the
// other lines stay as they are (nothing is grayed out)
// - steps: one array of marks per step, () for no current line; a mark is
//   - a line number: the whole line is current (e.g. a recipe that runs)
//   - (line, word, role): the line is current and its word number `word`
//     (from 0, the words are separated by spaces, a final `:` is not
//     marked) is boxed: role "dep" (blue, a prerequisite) or "target"
//     (orange, a target)
// - start: the step of the first entry (like highlight-code)
// - name: the title bar (code-file); auto: "Makefile" for a make listing
// e.g. #debug-code(((1,), ((4, 0, "target"), (4, 1, "dep")), (5,)))[```make ...```]
#let debug-code(start: 1, name: auto, steps, body) = {
  // a Makefile listing gets a title bar with its name, like code-file
  let name = if name != auto { name } else if body.func() == raw and body.at("lang", default: none) == "make" { "Makefile" } else { none }
  // the arrow of the current line, drawn (an arrow glyph may be missing)
  let marker = box(baseline: 0.05em, polygon(fill: changed, stroke: none, (0pt, 0pt), (0.5em, 0.3em), (0pt, 0.6em)))
  let role-color = (dep: accent, target: changed)
  for (idx, marks) in steps.enumerate() {
    let lines = marks.map(m => if type(m) == int { m } else { m.at(0) })
    let listing = {
      show raw.line: it => {
        let on = it.number in lines
        let words = marks.filter(m => type(m) == array and m.at(0) == it.number)
        // with boxed words, the line is written again from its text
        let line = if words.len() == 0 { it.body } else {
          let k = -1
          let parts = ()
          for p in it.text.replace("\t", "    ").split(" ") {
            if p == "" { parts.push([]); continue }
            k += 1
            let m = words.find(w => w.at(1) == k)
            if m == none { parts.push(p); continue }
            let (name, colon) = if p.ends-with(":") { (p.slice(0, -1), ":") } else { (p, "") }
            let c = role-color.at(m.at(2))
            parts.push(box(fill: c, outset: (x: 1.5pt, y: 2pt), radius: 2pt, text(fill: white, name)) + colon)
          }
          parts.join(" ")
        }
        box(
          width: 100%,
          fill: if on { changed-fill } else { none },
          outset: (y: 0.2em),
          {
            box(width: 1.1em, align(right, text(fill: luma(150), str(it.number))))
            h(0.35em)
            box(width: 0.8em, if on { marker })
            line
          },
        )
      }
      body
    }
    only(start + idx, if name == none { listing } else { code-file(name, listing) })
  }
}

// the stack of targets make is working on, like the call stack of a
// debugger: the target it is at on top (orange, with the arrow), below it
// the targets waiting for it; `rows` lines are reserved so the panel keeps
// its height
// e.g. #target-stack(("hello.o", "hello"))
#let target-stack(frames, rows: 3) = block(
  width: 100%,
  fill: luma(248),
  stroke: 0.6pt + luma(190),
  radius: 0.3em,
  inset: (x: 0.6em, y: 0.5em),
  text(size: 0.6em, {
    text(weight: "bold", fill: accent)[target stack]
    v(0.35em, weak: true)
    let marker = box(baseline: 0.05em, polygon(fill: changed, stroke: none, (0pt, 0pt), (0.5em, 0.3em), (0pt, 0.6em)))
    let cells = ()
    for (i, f) in frames.enumerate() {
      let top = i == 0
      cells.push(if top { marker } else { [] })
      cells.push(box(
        width: 100%,
        fill: if top { changed-fill } else { none },
        outset: (y: 1.5pt),
        text(font: mono, fill: if top { changed } else { black }, f)
          + if i == frames.len() - 1 { text(fill: luma(130), style: "italic")[ (goal)] },
      ))
    }
    for _ in range(frames.len(), rows) { cells += ([], text(font: mono, sym.space.nobreak)) }
    if frames.len() == 0 { cells.at(1) = text(fill: luma(130), style: "italic")[empty: `make` is not running] }
    grid(columns: (0.8em, 1fr), row-gutter: 0.45em, ..cells)
  }),
)

// one target stack per step: the last one stays on the following steps
#let stack-steps(stacks) = for (i, st) in stacks.enumerate() {
  let when = if i == stacks.len() - 1 { str(i + 1) + "-" } else { i + 1 }
  only(when, target-stack(st))
}

// a file in a make-step card: its name (colored by role) and its state
// below (a time, "does not exist", ...)
#let step-file(name, role, state) = stack(
  spacing: 0.35em,
  box(
    fill: (dep: accent, target: changed).at(role),
    inset: (x: 0.45em, y: 0.3em),
    radius: 0.2em,
    text(font: mono, size: 0.85em, fill: white, name),
  ),
  text(size: 0.7em, fill: luma(80), state),
)

// what make does on one step, as a card next to the Makefile: the
// dependency -> target connection it looks at (each with its time or
// state), what it decides and the command it runs
// - dep, target: (name, state) or none
// - verdict: the decision, cmd: the command that runs (none: nothing runs)
// e.g. #make-step(dep: ("hello.c", "11:41:08"), target: ("hello.o", "does not exist"),
//        [`hello.o` does not exist], cmd: "gcc -c hello.c")
// the body of a fixed-height card; fails the build if the body does not
// fit, so a long text cannot silently overflow the card
#let fit-check(name, body) = layout(size => {
  let h = measure(body, width: size.width).height
  assert(h <= size.height, message: name + " overflows its box by " + repr(h - size.height))
  body
})

#let make-step(dep: none, target: none, verdict, cmd: none) = block(
  width: 100%,
  height: 11.5em,
  fill: luma(248),
  stroke: 0.8pt + luma(190),
  radius: 0.4em,
  inset: 0.7em,
  fit-check("make-step " + repr(verdict).clusters().slice(0, calc.min(80, repr(verdict).clusters().len())).join(), {
    let files = ()
    if dep != none { files.push(step-file(dep.at(0), "dep", dep.at(1))) }
    if dep != none and target != none {
      files.push(stack(spacing: 0.3em, arrow-label[needed for], draw-arrow(length: 3em)))
    }
    if target != none { files.push(step-file(target.at(0), "target", target.at(1))) }
    align(center, grid(columns: files.len(), column-gutter: 0.6em, align: center + top, ..files))
    v(0.6em)
    set text(size: 0.85em)
    verdict
    if cmd != none {
      v(0.5em)
      text(size: 0.85em, fill: luma(100))[runs]
      v(0.2em, weak: true)
      block(
        width: 100%,
        fill: ok-fill,
        stroke: 1pt + ok-color,
        inset: (x: 0.4em, y: 0.3em),
        radius: 0.2em,
        // the command highlighted like in a terminal; never break a line
        // after the "-" of an option
        text(font: mono, size: 0.85em, {
          show "-": "-\u{2060}"
          highlight-shell(cmd)
        }),
      )
    }
  }),
)

// ----- the dependency graphs -----

// a file of the graphs, `state`: none, "changed" (we edited it), "rebuilt"
// (make built it again), "stale" (should have been rebuilt, was not),
// "missing" (the file does not exist yet)
#let dep-node(name, state) = {
  let (stroke, fill, ink) = if state == "changed" {
    (1.5pt + changed, changed-fill, changed)
  } else if state == "rebuilt" {
    (1.5pt + ok-color, ok-fill, ok-color)
  } else if state == "stale" {
    (1.5pt + bad-color, bad-fill, bad-color)
  } else if state == "missing" {
    ((paint: luma(170), thickness: 0.8pt, dash: "dashed"), white, luma(150))
  } else {
    (0.8pt + luma(130), white, black)
  }
  box(
    inset: (x: 0.25em, y: 0.3em),
    radius: 0.2em,
    stroke: stroke,
    fill: fill,
    text(font: mono, size: 6.5pt, fill: ink, name),
  )
}

// the legend of a graph, only for the states that appear
#let dep-legend(states) = {
  let legend = (
    ("changed", [edited]),
    ("rebuilt", [built]),
    ("stale", [should be rebuilt]),
    ("missing", [does not exist]),
  ).filter(((k, _)) => k in states.values())
  legend.map(((k, l)) => box(baseline: 15%, dep-node(" ", k)) + h(0.2em) + text(size: 6.5pt, l)).join(h(0.8em))
}

// the places of the files of the project
#let dep-pos = (
  "app": (112pt, 12pt),
  "lib.o": (30pt, 64pt),
  "main.o": (112pt, 64pt),
  "print.o": (192pt, 64pt),
  "lib.c": (20pt, 118pt),
  "lib.h": (66pt, 118pt),
  "main.c": (112pt, 118pt),
  "print.h": (158pt, 118pt),
  "print.c": (204pt, 118pt),
)

// `edges`: (prerequisite, target, style), style: "ok", "missing" (make
// does not know it), "wrong" (in the wrong place), "new" (just added);
// `states`: a dictionary file -> state; `nodes`: the files to draw
#let dep-graph(edges, states: (:), nodes: dep-pos.keys()) = drawing(width: 225pt, height: 146pt, {
  if states.len() > 0 {
    pin(112pt, 139pt, dep-legend(states))
  }
  for (from, to, style) in edges {
    let (x1, y1) = dep-pos.at(from)
    let (x2, y2) = dep-pos.at(to)
    let (color, dash, th) = if style == "missing" {
      (luma(190), "dashed", 0.8pt)
    } else if style == "wrong" {
      (bad-color, none, 1.4pt)
    } else if style == "new" {
      (ok-color, none, 1.4pt)
    } else {
      (luma(110), none, 0.9pt)
    }
    line-arrow((x1, y1 - 8pt), (x2, y2 + 8pt), color: color, dash: dash, thickness: th)
  }
  for n in nodes {
    pin(..dep-pos.at(n), dep-node(n, states.at(n, default: none)))
  }
})

#let edges-objects = (
  ("main.o", "app", "ok"), ("lib.o", "app", "ok"), ("print.o", "app", "ok"),
  ("main.c", "main.o", "ok"), ("lib.c", "lib.o", "ok"), ("print.c", "print.o", "ok"),
)
#let edges-headers(style) = (
  ("lib.h", "main.o", style), ("print.h", "main.o", style), ("print.h", "print.o", style),
)
// the graph without the headers (they are not in the Makefile yet)
#let no-headers = dep-pos.keys().filter(n => not n.ends-with(".h"))
// a state for each of the files
#let all-states(files, state) = files.map(f => (f, state)).to-dict()

// a file of the folder, drawn differently from a target (orange outline)
#let file-chip(name, label) = stack(
  spacing: 0.35em,
  box(
    fill: changed-fill,
    stroke: 1pt + changed,
    inset: (x: 0.45em, y: 0.3em),
    radius: 0.2em,
    text(font: mono, size: 0.85em, fill: changed, name),
  ),
  text(size: 0.7em, fill: luma(80), label),
)

// a card like make-step, with any drawing on top
#let free-card(top, body) = block(
  width: 100%,
  height: 11.5em,
  fill: luma(248),
  stroke: 0.8pt + luma(190),
  radius: 0.4em,
  inset: 0.7em,
  fit-check("free-card", {
    align(center, top)
    v(0.6em)
    text(size: 0.85em, body)
  }),
)

// a word of a recipe, boxed like in debug-code: "target" orange, "dep" blue,
// "var" green (a variable and its value)
#let tok(role, s) = box(
  fill: (dep: accent, target: changed, var: ok-color).at(role),
  outset: (x: 1.5pt, y: 2pt),
  radius: 2pt,
  text(font: mono, fill: white, s),
)

// ---------------------------------------------------------------------------
// Shell commands in the text
// ---------------------------------------------------------------------------

// the programs whose commands are highlighted when written as inline code
// (`make`, `make clean`, `gcc -c main.c`), like the commands of a terminal
#let shell-programs = (
  "make", "gcc", "clang", "cc", "touch", "ls", "cat", "rm", "cp", "mv", "mkdir", "cd",
  "echo", "gdb", "lldb", "objdump", "nm", "ldd", "file", "vim", "nvim", "hx", "code",
  "git", "bear", "less", "sudo", "apt", "wc", "grep", "head", "tail", "which", "man",
  "bash", "sh", "python3", "java", "javac", "node", "strace", "readelf",
)
// a command: a known program, alone or with arguments, or ./program
#let is-shell-command(t) = {
  // a prompt in front ("$ gdb ./app") is allowed
  let t = if t.starts-with("$ ") { t.slice(2) } else { t }
  t.split(" ").first() in shell-programs or t.starts-with("./")
}
// show rules: inline code that is a command line is highlighted with the
// terminal colors (the theme still draws the inline code background)
// usage, once, after the template: #show: shell-commands
#let shell-commands(body) = {
  show raw.where(block: false, lang: none): it => if is-shell-command(it.text) {
    // color the line of this inline code, the element itself is kept
    show raw.line: l => if l.text.starts-with("$ ") { render-terminal-line(l.text) } else { highlight-shell(l.text) }
    it
  } else { it }
  body
}
