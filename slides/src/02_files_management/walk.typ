#import "/src/slides.typ": *
#import "diagram.typ": *


// Helpers for the slides that walk a path in a directory tree:
// the tree with arrow notes and the step by step path examples.

// Directory tree used to explain `.` and `..`; the current directory is
// always `Movies` (line 4). `notes` maps a line number to a text drawn
// after an arrow at the right of that line.
#let dot-tree-lines = (
  "📁 /",
  "└── 📁 home",
  "    ├── 📁 alice",
  "    │   ├── 📁 Movies",
  "    │   │   └── 🎬 the_odyssey.mkv",
  "    │   ├── 📁 Downloads",
  "    │   │   └── 🎬 supergirl.mp4",
  "    │   └── 📄 watchlist.txt",
  "    └── 📁 bob",
  "        └── 📄 notes.txt",
)

// the arrow notes are drawn like code comments: grey, italic, never bold
#let dot-tree-arrow = " <-- "
#let dot-tree-comment = luma(110)

// the icons drawn larger on the current folder and the target lines
#let dot-tree-target-mark = fs-target-mark
#let dot-tree-icons = ("📁", "🎬", "📄", fs-cwd-mark, dot-tree-target-mark)
#let dot-tree-big(body) = fs-big(icons: dot-tree-icons, body)

// `big` - the lines whose emoji are drawn larger (the current folder and the target)
#let dot-tree(notes: (:), here: (), big: (4,), target: none, caption: none) = {
  let width = calc.max(..dot-tree-lines.map(l => l.clusters().len()))
  let lines = dot-tree-lines
    .enumerate()
    .map(((i, l)) => {
      let note = notes.at(str(i + 1), default: none)
      let l = if note == none { l } else { l + " " * (width - l.clusters().len()) + dot-tree-arrow + note }
      let l = if i + 1 == target { l + " " + dot-tree-target-mark } else { l }
      if i + 1 == 4 { l + " " + fs-cwd-mark } else { l }
    })

  set text(size: 0.8em)
  show raw.line: it => {
    let parts = it.text.split(dot-tree-arrow)
    let tree = parts.first()
    let tree = if it.number in big { dot-tree-big(tree) } else { tree }
    if (it.number in here) or (it.number == 4) {
      text(fill: fs-here-color, weight: "bold", tree)
    } else {
      tree
    }
    if parts.len() > 1 {
      let comment = dot-tree-arrow + parts.slice(1).join(dot-tree-arrow)
      let comment = if it.number in big { dot-tree-big(comment) } else { comment }
      text(fill: dot-tree-comment, style: "italic", weight: "regular", comment)
    }
  }
  raw(lines.join("\n"), block: true)

  if caption != none {
    v(-0.4em)
    align(center, text(size: 0.8em, style: "italic", caption))
  }
}


// Every example is a relative path walked one move at a time, starting
// from `Movies`. A move is (tree line, note at the arrow, explanation).
#let path-examples = (
  (
    path: "./the_odyssey.mkv",
    absolute: "/home/alice/Movies/the_odyssey.mkv",
    moves: (
      (4, ".", [`.` stay in `Movies`]),
      (5, "open", [open `the_odyssey.mkv` 🎯]),
    ),
    extra: [same as `the_odyssey.mkv`],
  ),
  (
    path: "../watchlist.txt",
    absolute: "/home/alice/watchlist.txt",
    moves: (
      (3, ".. (up)", [`..` go up to `alice` ⬆️]),
      (8, "open", [open `watchlist.txt` 🎯]),
    ),
    extra: none,
  ),
  (
    path: "../Downloads/supergirl.mp4",
    absolute: "/home/alice/Downloads/supergirl.mp4",
    moves: (
      (3, ".. (up)", [`..` go up to `alice` ⬆️]),
      (6, "Downloads (down)", [`Downloads` go down ⬇️]),
      (7, "open", [open `supergirl.mp4` 🎯]),
    ),
    extra: none,
  ),
  (
    path: "../../bob/notes.txt",
    absolute: "/home/bob/notes.txt",
    moves: (
      (3, ".. (up)", [`..` go up to `alice` ⬆️]),
      (2, ".. (up)", [`..` go up to `home` ⬆️]),
      (9, "bob (down)", [`bob` go down ⬇️]),
      (10, "open", [open `notes.txt` 🎯]),
    ),
    extra: none,
  ),
  (
    path: "./../Movies/./the_odyssey.mkv",
    absolute: "/home/alice/Movies/the_odyssey.mkv",
    moves: (
      (4, ".", [`.` stay in `Movies`]),
      (3, ".. (up)", [`..` go up to `alice` ⬆️]),
      (4, "back", [`Movies` go back down ⬇️]),
      (4, ".", [`.` stay in `Movies`]),
      (5, "open", [open `the_odyssey.mkv` 🎯]),
    ),
    extra: [`.` and `..` can appear _anywhere_ in a path],
  ),
  (
    path: "../Downloads/./../../bob/notes.txt",
    absolute: "/home/bob/notes.txt",
    moves: (
      (3, "..", [`..` go up to `alice` ⬆️]),
      (6, "Downloads", [`Downloads` go down ⬇️]),
      (6, ".", [`.` stay in `Downloads`]),
      (3, "..", [`..` go back up to `alice` ⬆️]),
      (2, "..", [`..` go up to `home` ⬆️]),
      (9, "bob", [`bob` go down ⬇️]),
      (10, "open", [open `notes.txt` 🎯]),
    ),
    extra: [`..` removes the last folder _still left_ in the path],
  ),
)

#let keycaps = ("1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣")

// the current directory of every example
#let path-pwd = "/home/alice/Movies"

// every `..` and the folder it removes share one color (and number)
#let path-pair-colors = (rgb("e65100"), rgb("6a1b9a"), rgb("00838f"), rgb("ad1457"))

// How an absolute path is calculated from the current directory and a
// relative path: join them with `/`, then, from left to right, every `.`
// is dropped and every `..` removes itself and the folder before it.
// Returns the parts of the joined path, the removal steps (the indices of
// the parts each step removes) and the resulting absolute path.
#let path-resolve(pwd, rel) = {
  let base = pwd.split("/").filter(p => p != "")
  let rels = rel.split("/").filter(p => p != "")
  // `pair`: none, "dot" for a dropped `.` (or a `..` at `/`), or the number of the `..` pair
  let tokens = base.map(p => (name: p, rel: false, pair: none))
  tokens += rels.map(p => (name: p, rel: true, pair: none))
  let events = ()
  let pairs = 0
  let kept = range(base.len())
  for i in range(base.len(), tokens.len()) {
    let name = tokens.at(i).name
    if name == "." or (name == ".." and kept.len() == 0) {
      tokens.at(i).pair = "dot"
      events.push((i,))
    } else if name == ".." {
      pairs += 1
      tokens.at(i).pair = pairs
      tokens.at(kept.last()).pair = pairs
      events.push((kept.last(), i))
      kept = kept.slice(0, -1)
    } else {
      kept.push(i)
    }
  }
  (tokens: tokens, events: events, result: "/" + kept.map(i => tokens.at(i).name).join("/"))
}

// number of animation steps of the calculation: join, one per removal, result
#let path-compose-steps(pwd, rel) = path-resolve(pwd, rel).events.len() + 2

// the calculation after `step` animation steps (1 = only the join is shown)
// `expected` is checked against the result, so the slide can not lie.
#let path-compose(pwd, rel, expected, step) = {
  let (tokens, events, result) = path-resolve(pwd, rel)
  assert.eq(result, expected, message: "wrong absolute path for " + rel)
  let removed = events.slice(0, calc.clamp(step - 1, 0, events.len())).flatten()

  // one monospace run per path part, no chip background, so the parts join up
  let mono(body) = text(font: "DejaVu Sans Mono", size: 0.8em, body)
  let pwd-part(body) = text(fill: fs-here-color, weight: "bold", mono(body))
  let rel-part(body) = text(fill: fs-new-color, weight: "bold", mono(body))
  let part(t) = if t.rel { rel-part("/" + t.name) } else { pwd-part("/" + t.name) }
  let joined = tokens.map(part).join()
  let resolved = tokens
    .enumerate()
    .map(((i, t)) => {
      let seg = "/" + t.name
      if i not in removed {
        part(t)
      } else if t.pair == "dot" {
        text(fill: dot-tree-comment, strike(stroke: 0.8pt + dot-tree-comment, mono(seg)))
      } else {
        let c = path-pair-colors.at(calc.rem(t.pair - 1, path-pair-colors.len()))
        highlight(
          fill: c.lighten(85%),
          radius: 2pt,
          extent: 0.5pt,
          text(fill: c, weight: "bold", strike(stroke: 0.8pt + c, mono(seg))) + super(text(fill: c, size: 0.9em, str(t.pair))),
        )
      }
    })
    .join()

  let show-if(visible, body) = if visible { body } else { hide(body) }
  grid(
    columns: (auto, auto),
    column-gutter: 0.8em,
    row-gutter: 0.5em,
    [🔗 #pwd-part("pwd") + #mono("/") + #rel-part("relative")], joined,
    ..(
      [✂️ drop `.`, each `..` removes a folder], resolved,
    ).map(c => show-if(step >= 2, c)),
    ..([🌍 absolute path], mono(result)).map(c => show-if(step >= events.len() + 2, c)),
  )
}

// The relative path of an example while it is walked: every part of the
// path is one move. The parts already walked are bold, the part of the
// current move is highlighted, the parts still to walk are grey.
#let path-parts(rel, done, current: true) = {
  let parts = rel.split("/")
  let mono(body) = text(font: "DejaVu Sans Mono", size: 0.8em, body)
  parts
    .enumerate()
    .map(((i, name)) => {
      let seg = if i == 0 { name } else { "/" + name }
      if current and i + 1 == done {
        // the separator stays outside the highlight, only the part is marked
        let sep = if i == 0 { "" } else { "/" }
        text(fill: fs-here-color, weight: "bold", mono(sep)) + highlight(
          fill: rgb("ffd54f"),
          radius: 2pt,
          extent: 1pt,
          text(fill: black, weight: "bold", mono(name)),
        )
      } else if i < done {
        text(fill: fs-here-color, weight: "bold", mono(seg))
      } else {
        text(fill: luma(140), mono(seg))
      }
    })
    .join()
}

// one example after `done` moves: the explanation on the left, the tree
// with an arrow for every move made so far on the right; one extra step
// after the last move shows the equivalent absolute path as a tip
#let path-walk(ex, done) = {
  // the steps after the last move show how the absolute path is calculated
  let tip = done - ex.moves.len()
  let done = calc.min(done, ex.moves.len())
  let notes = (:)
  let here = (4,)
  for (i, (line, note, _)) in ex.moves.slice(0, done).enumerate() {
    let key = str(line)
    let text = "(" + str(i + 1) + ") " + note
    notes.insert(key, if key in notes { notes.at(key) + " " + text } else { text })
    here.push(line)
  }

  assert.eq(ex.path.split("/").len(), ex.moves.len(), message: "one move per path part: " + ex.path)
  // the subtitle line: the whole width of the slide, so the path fits on one line
  [🗺️ from 📍 #raw(path-pwd) walk 🧾 #path-parts(ex.path, done, current: tip <= 0)]
  parbreak()

  toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[

    #for (i, (_, _, body)) in ex.moves.enumerate() {
      let line = [#keycaps.at(i) #body \ ]
      if i < done { line } else { hide(line) }
    }

  ][
    #let target = ex.moves.last().at(0)
    #dot-tree(here: here, notes: notes, big: (4, target), target: target)
  ]

  if tip > 0 {
    v(-0.4em)
    block(
      width: 100%,
      inset: (x: 0.8em, y: 0.5em),
      radius: 0.3em,
      fill: luma(245),
      stroke: (left: 2pt + fs-here-color),
    )[
      #set text(size: 0.85em)
      💡 *Tip:* #if ex.extra != none { ex.extra } else [how the absolute path is calculated]
      #path-compose(path-pwd, ex.path, ex.absolute, tip)
    ]
  }
}

// all the animation steps of several examples, one after the other
#let path-walks(examples) = {
  let subslide = 1
  for ex in examples {
    for done in range(ex.moves.len() + 1 + path-compose-steps(path-pwd, ex.path)) {
      only(subslide, path-walk(ex, done))
      subslide += 1
    }
  }
}
