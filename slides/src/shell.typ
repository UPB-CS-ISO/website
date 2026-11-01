#import "/src/slides.typ": *

// Drawings shared by the shell lectures (6. Text Processing and
// 8. Shell Scripting), in the same style as lecture 4 (orange for whatever
// is new or changed on the current step). Not re-exported by slides.typ:
// the short names (`w`, `label`, `arrow`, ...) would clash with the
// helpers of the other decks, so a deck imports it from its common.typ:
// #import "/src/shell.typ": *

#let accent = rgb("004d65")
#let changed = rgb("e65100")
#let changed-fill = rgb("fff3e0")
#let ok-color = rgb("2e7d46")
#let fail-color = rgb("c62828")
#let dim = luma(175)

#let mono = "DejaVu Sans Mono"

// the colors of the permission sets: u (user), g (group), o (others),
// the same as in lecture 5 (users and permissions)
#let set-colors = (rgb("1565c0"), rgb("7b1fa2"), rgb("00897b"))

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

// a small arrow to use inside text, e.g. `$a+$b` #arrow `2+3`
#let arrow = draw-arrow(length: 1.2em, thickness: 1pt)

// ----- "the shell runs commands" -----

// The reminder of this lecture: bash was made to run commands, the
// programming part came later, on top of it. Use it on every slide where
// the syntax looks strange, to explain *why* it looks like that.
// #shell-first[`$a + $b` is a command line: the command is `2`]
#let shell-first(body) = block(
  width: 100%,
  fill: accent.lighten(90%),
  stroke: (left: 3pt + accent),
  radius: (right: 0.3em),
  inset: (x: 0.7em, y: 0.5em),
  text(size: 0.85em)[🐚 #body],
)

// a takeaway of a slide, as a card: a title and a small drawing
// #takeaway[the user does not need to know the language][#words(...)]
#let takeaway(title, body) = block(
  width: 100%,
  fill: accent.lighten(92%),
  stroke: (left: 3pt + accent),
  radius: (right: 0.3em),
  inset: (x: 0.8em, y: 0.5em),
  {
    text(size: 0.85em, weight: "bold", fill: accent)[🎯 #title]
    v(-0.2em)
    align(center, body)
  },
)

// ----- the files used in the examples -----

// the lines of fruits.txt, the file of the course examples
#let fruits-lines = ("banana", "apple", "cherry", "apple", "kiwi", "banana", "apple")

// a small view of a file, to keep on the side of a slide when an example
// uses it: its name on top, its lines under it, one per line (as
// `wc -l` counts them)
// `hl`: the indices of the lines to highlight (e.g. what grep found)
// #file-view("fruits.txt", fruits-lines, hl: (4,))
#let file-view(name, lines, size: 0.7em, columns: 1, hl: ()) = {
  let cols = columns
  let rows = calc.ceil(lines.len() / cols)
  // a one column grid: as wide as the file, not as the slide
  box(text(size: size, grid(
    columns: 1,
    stroke: 0.6pt + luma(170),
    fill: (x, y) => if y == 0 { luma(235) } else { white },
    inset: (x: 0.5em, y: 0.3em),
    align: left,
    text(font: mono, weight: "bold", fill: luma(80), "📄 " + name),
    grid(
      columns: cols,
      column-gutter: 1.2em,
      row-gutter: 0.35em,
      ..range(cols).map(c => stack(spacing: 0.35em, ..range(c * rows, calc.min((c + 1) * rows, lines.len())).map(k => {
        // a highlighted line: what a command (e.g. grep) found
        let t = text(font: mono, lines.at(k))
        if k in hl { box(fill: changed-fill, outset: (x: 0.3em, y: 0.15em), text(fill: changed, weight: "bold", t)) } else { t }
      }))),
    ),
  )))
}

// a popup drawn on top of the slide: a card, slightly rotated, with a
// soft shadow; put it last in the slide, inside #only(...)
// #only(3)[#popup[...]]
// `width`: needed when the body has full-width blocks (e.g. code), so
// the card and its shadow have the same size
#let popup(body, color: fail-color, fill: rgb("fff8e1"), dy: 1.5em, angle: -3deg, width: auto) = {
  let card = block(width: width, fill: fill, stroke: 2.5pt + color, radius: 0.6em, inset: (x: 1.4em, y: 0.9em), body)
  place(center + horizon, dy: dy, rotate(angle, context {
    let size = measure(card, width: if width == auto { auto } else { width })
    box({
      place(dx: 7pt, dy: 7pt, box(width: size.width, height: size.height, radius: 0.6em, fill: luma(0).transparentize(80%)))
      card
    })
  }))
}

// ----- one liners -----

// the same syntax, written on one line: `;` ends every part
// #one-liner(("if command; then commands; fi",), ("if grep -q kiwi fruits.txt; then echo kiwi; fi",))
#let one-liner(syntax, examples) = block(
  width: 100%,
  breakable: false,
  fill: accent.lighten(92%),
  stroke: (left: 3pt + accent),
  radius: (right: 0.3em),
  inset: (x: 0.7em, y: 0.4em),
  {
    show raw.where(block: false): it => it.lines.join()
    set text(size: 0.85em)
    text(size: 0.85em, weight: "bold", fill: accent)[on one line]
    text(size: 0.85em)[, `;` ends every part]
    linebreak()
    for x in syntax { raw(x, lang: "bash"); linebreak() }
    for x in examples { text(fill: luma(90))[\$ ]; raw(x, lang: "bash"); linebreak() }
  },
)

// ----- bash only -----

// a stamp in the bottom right corner of a slide: what the slide shows
// works only in bash (and zsh), not in sh; put it last in the slide
// #bash-only[`[[ ]]` and `(( ))`]
#let bash-only(what) = place(bottom + right, dy: -0.3em, rotate(-4deg, block(
  fill: white,
  stroke: 2pt + fail-color,
  radius: 0.3em,
  inset: (x: 0.7em, y: 0.4em),
  align(center)[
    #text(size: 1.05em, weight: "bold", fill: fail-color)[🐚 only in `bash` (and `zsh`)]
    #v(-0.5em)
    #text(size: 0.75em, fill: fail-color)[not in `sh`: #what]
  ],
)))

// a small inline tag, next to one thing that works only in bash
// - `{1..5}` #bash-tag
#let bash-tag = box(baseline: 15%, fill: fail-color, radius: 0.2em, inset: (x: 0.3em, y: 0.15em),
  text(size: 0.7em, weight: "bold", fill: white)[bash only])

// ----- the words of a command line (same chips as lecture 4) -----

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

// a small gray label, e.g. #label[the command]
#let label(body) = text(size: 0.8em, fill: luma(110), style: "italic", body)

// an exit code, drawn as a small receipt (a slip of paper with a torn,
// zigzag bottom edge): green for 0, red for an error; the number says it,
// not only the color; `size` - the height
// #code-badge(0), #code-badge(1, size: 1.6em)
#let code-badge(n, size: 2.3em) = {
  let color = if n == 0 { ok-color } else { fail-color }
  let w = size * 0.8
  let h = size
  let teeth = 4
  let tooth = w / teeth
  // the outline: the top and the sides straight, the bottom a zigzag
  let points = ((0pt, 0pt), (w, 0pt), (w, h))
  for k in range(teeth) {
    points.push((w - tooth * (k + 0.5), h - size * 0.08))
    points.push((w - tooth * (k + 1), h))
  }
  box(baseline: 35%, width: w, height: h, {
    place(polygon(fill: color.lighten(90%), stroke: 0.6pt + color, ..points))
    place(top + center, dy: size * 0.1, text(size: size * 0.16, fill: color, tracking: 0.05em)[EXIT])
    place(center + horizon, dy: size * 0.04, text(size: size * if str(n).len() > 2 { 0.28 } else { 0.38 }, weight: "bold", fill: color, font: mono, str(n)))
  })
}

// an exit code inside a line of text: a small receipt
// #exit-code(0), #exit-code(127)
#let exit-code(n) = code-badge(n, size: 1.7em)

// a command line drawn as word chips, the way the shell splits it: the
// quotes are removed, the command is dark (after a `|` too), a redirect (`<`, `>` and its
// file) and a `NAME=value` before the command are dashed
// #command-words("wc -l < fruits.txt")
#let command-words(cmd) = {
  // split at the spaces outside quotes, the quotes are removed
  let ws = ()
  let cur = ""
  let quoted = false
  let q = none
  for c in cmd.clusters() {
    if q != none {
      if c == q { q = none } else { cur += c }
    } else if c == "\"" or c == "'" {
      q = c
      quoted = true
    } else if c == " " {
      if cur != "" or quoted { ws.push(cur) }
      cur = ""
      quoted = false
    } else { cur += c }
  }
  if cur != "" or quoted { ws.push(cur) }
  // the kind of every word
  let out = ()
  let seen-cmd = false
  let after-redirect = false
  for x in ws {
    if after-redirect {
      out.push((x, "redir"))
      after-redirect = false
    } else if x == "|" {
      // a pipe: the next word is a new command
      out.push(x)
      seen-cmd = false
    } else if x in ("<", ">", ">>", "2>") {
      out.push((x, "redir"))
      after-redirect = true
    } else if not seen-cmd and x.match(regex("^[A-Za-z_][A-Za-z0-9_]*=")) != none {
      out.push((x, if ws.len() == 1 { "new" } else { "redir" }))
    } else if not seen-cmd {
      out.push((x, "cmd"))
      seen-cmd = true
    } else {
      out.push(x)
    }
  }
  words(..out)
}

// ----- regular expressions -----

// lines of text with the matches of a regular expression highlighted,
// the way `grep --color` shows them: lines without a match are not
// printed by `grep`, so they are grayed out
// #regex-matches(("apple", "kiwi"), "a.p")
#let regex-matches(lines, pattern, size: 0.8em) = block(
  width: 100%,
  radius: 0.3em,
  stroke: 0.8pt + luma(150),
  fill: white,
  inset: (x: 0.6em, y: 0.5em),
)[
  #set text(font: mono, size: size)
  #set par(leading: 0.45em)
  #for l in lines {
    let ms = l.matches(regex(pattern))
    if ms.len() == 0 {
      text(fill: dim, l)
    } else {
      let at = 0
      for m in ms {
        if m.start > at { l.slice(at, m.start) }
        if m.end > m.start {
          box(
            fill: changed-fill,
            outset: (y: 2pt),
            radius: 1pt,
            text(fill: changed, m.text),
          )
        }
        at = m.end
      }
      if at < l.len() { l.slice(at) }
    }
    linebreak()
  }
]

// ----- the debugger -----

// a small triangle that marks the line that runs now
#let line-marker(color: changed) = box(width: 0.6em, height: 0.7em, baseline: 0.05em, polygon(
  fill: color,
  (0em, 0em),
  (0.55em, 0.35em),
  (0em, 0.7em),
))

// a titled panel of the debugger (the variables)
#let debug-panel(title, body) = block(
  width: 100%,
  radius: 0.5em,
  stroke: 0.8pt + luma(190),
  fill: white,
  inset: 0pt,
  clip: true,
  {
    block(width: 100%, fill: luma(235), inset: (x: 0.6em, y: 0.25em), below: 0pt, text(size: 0.75em, fill: luma(80), weight: "bold", title))
    block(width: 100%, inset: (x: 0.6em, y: 0.4em), above: 0pt, body)
  },
)

// what the shell replaces in a line: ${NAME}, $(( )), $(...), $NAME,
// $1, $#, $?, $@ and ~ (marked with a dotted frame by debug-run)
// the color of an expression the shell computes (debug-run `compute`)
#let compute-fill = rgb("dcebfa")

#let expansion-pattern = regex("\$\{[^}]*\}|\$\(\(.*?\)\)|\$\([^)]*\)|\$[A-Za-z_][A-Za-z0-9_]*|\$[0-9#?@*]|~")

// A script running step by step, the way a debugger shows it, one step
// per subslide. On purpose there are no watches and no call stack, only:
// - the script, as a file (a bordered panel with its name on top), with
//   line numbers, the line that runs now marked in orange; when only a part of the line runs on this step (one command
//   of `a && b`, the inside of `$(...)`), only that command is
//   highlighted; what the shell replaces (`$name`, `~`, ...) gets a dotted frame
// - under it, the command line the shell runs on that step, *after* it
//   replaced the variables, and its exit code (this is the point of the
//   lecture: everything is a command line)
// - the variables of the script, the ones changed on this step in orange
// - the output, as a normal terminal block: how the script was started,
//   then what it printed so far, the lines printed on this step in orange
// - an optional short tip under the debugger
// Everything keeps the space of its biggest step, so nothing moves.
//
// `code`: the script, a string
// `command`: how the script was started, e.g. "./params.sh alice bob"
// `file`: the name shown on top of the script (default: from `command`)
// `blocks`: true - show what the shell runs as word chips, not as text
// `files`: the files the script uses, (name, lines) pairs, shown small
//   under the output
// `steps`: one dictionary per subslide, with the keys
//   line   - the line that runs now (1-based)
//   part   - the command that runs now, when it is only a piece of the
//            line (e.g. one side of `&&`, the inside of `$(...)`): only
//            it is highlighted, not the whole line; an array for commands
//            that run at the same time, e.g. the two sides of `|` (optional)
//   compute - an arithmetic expression the shell computes now (the
//            inside of `$(( ))` or of `(( ))`): highlighted in blue, not
//            in orange like a command (optional)
//   also   - pieces of other lines that matter on this step, an array of
//            (line, text), e.g. the `< file` after `done` (optional)
//   expand - a piece (or an array of pieces) of the line the shell
//            replaces now, a dotted frame around it; the variables, the
//            `$(...)`, `$(( ))` and `~` in what runs are framed anyway, so
//            this is for the rest (a glob, the word of `for`) (optional)
//   run    - what the shell runs, after expansion (string, optional)
//   status - the exit code of `run` (int, optional)
//   skip   - true if `run` is *not* run (e.g. after `&&`), optional
//   who    - "copy" if a copy of bash runs it (inside `$(...)`), optional
//   info   - a few words after the command, e.g. [prints `7`] (optional)
//   vars   - the variables changed on this step, a dictionary, e.g.
//            (n: "2"); the others keep their values (optional)
//   unset  - the names of the variables that disappear (optional)
//   match  - the lines of the files that contain it are highlighted
//            (what `grep` finds on this step) (optional)
//   read   - the numbers (1-based) of the lines of the files that are
//            highlighted, e.g. (1,) for what `head -n 1` reads (optional)
//   out    - the lines printed on this step (array of strings, optional)
//   note   - a tip for this step, shown under the debugger (optional)
// `start`: the subslide of the first step
// `columns`: the widths of the script and of the output
// `size`: the size of the text, `auto` - smaller for a longer script
//
// #debug-run("x=1\necho $x", command: "./x.sh", (
//   (line: 1, run: "x=1", vars: (x: "1")),
//   (line: 2, part: "$x", run: "echo 1", status: 0, out: ("1",), note: [💡 ...]),
// ))
#let debug-run(code, command: none, file: auto, blocks: false, files: (), steps, start: 1, columns: (3fr, 2fr), size: auto, note-size: 0.9em) = {
  let all-out = steps.map(s => s.at("out", default: ())).flatten()
  let session = (if command != none { ("$ " + command,) } else { () }) + all-out
  if session.len() == 0 { session = (" ",) }
  let first-out = if command != none { 2 } else { 1 }
  // big for a short script, smaller for a long one, so it fits on the slide
  if size == auto {
    let n = code.split("\n").len()
    size = if n <= 6 { 1.25em } else if n <= 8 { 1.1em } else { 0.95em }
  }
  // the name of the file: the first word of the command, without "./"
  if file == auto {
    file = if command != none { command.split(" ").first().replace(regex("^\\./"), "") } else { "script.sh" }
  }

  // the variables after every step, and every name, in the order they show up
  let names = ()
  let vars-at = ()
  let vars = (:)
  for s in steps {
    for n in s.at("unset", default: ()) { let _ = vars.remove(n, default: none) }
    for (n, v) in s.at("vars", default: (:)) {
      vars.insert(n, v)
      if n not in names { names.push(n) }
    }
    vars-at.push(vars)
  }

  // the command line the shell runs on a step
  let strip(s) = block(width: 100%, inset: (x: 0.3em), {
    set text(size: 0.85em)
    if "run" in s or "info" in s {
      text(fill: luma(110), style: "italic", if s.at("who", default: none) == "copy" [a copy of `bash` runs] else if "run" in s [the shell runs] else [the shell])
      h(0.5em)
      if "run" in s {
        let cmd = if blocks { box(command-words(s.run)) } else { raw(s.run, lang: "bash") }
        if s.at("skip", default: false) {
          text(fill: luma(150), strike(cmd))
          h(0.4em)
          text(fill: luma(110), style: "italic")[skipped]
        } else {
          cmd
        }
      }
      if "status" in s [ #h(0.3em) #box[#arrow #h(0.2em) #exit-code(s.status)]]
      if "info" in s [ #h(0.3em) #box(text(fill: luma(110), style: "italic", s.info))]
    } else {
      hide[x]
    }
  })

  let render(i) = {
    let s = steps.at(i)
    let cur = s.line
    let part = s.at("part", default: none)
    let expand = s.at("expand", default: none)
    let compute = s.at("compute", default: none)
    let also = s.at("also", default: ())
    // the output lines shown so far, and the ones printed on this step
    let old = steps.slice(0, i).map(p => p.at("out", default: ())).flatten().len()
    let new = s.at("out", default: ()).len()

    grid(
      columns: columns,
      column-gutter: 1em,
      {
        set text(size: size)
        // the script, as a file: a bordered panel with its name on top
        let lines = code.split("\n")
        debug-panel(raw(file), {
          show raw.where(block: false): it => it.lines.join()
          // the part is boxed by drawing a frame on top of the line: the
          // code is monospaced, so its place is the width of the text
          // before it
          // a part of the line, marked: `piece` - its text, `kind` -
          // "part": a command that runs, the orange of a running line
          // behind it only (the rest of the line is not highlighted);
          // "expand": something the shell replaces ($name, ~, a glob, ...),
          // a dashed frame around it. Both are drawn under the line: the
          // code is monospaced, so their place is the width of the text
          // before them
          // the marks of the current line: (start, text, kind), "part" -
          // the command that runs (highlighted), "expand" - what the shell
          // replaces (a dotted frame): the `expand` of the step, and every
          // variable, `$(...)`, `$(( ))` and `~` in the part that runs
          let marks(l) = {
            let ms = ()
            let from = 0
            let to = l.len()
            if part != none {
              // one command, or several that run at the same time (a pipe)
              let parts = if type(part) == array { part } else { (part,) }
              from = l.len()
              to = 0
              for p in parts {
                let at = l.position(p)
                assert(at != none, message: "debug-run: `" + p + "` is not in line " + str(cur))
                ms.push((at, p, "part"))
                from = calc.min(from, at)
                to = calc.max(to, at + p.len())
              }
            }
            if compute != none {
              let at = l.position(compute)
              assert(at != none, message: "debug-run: `" + compute + "` is not in line " + str(cur))
              ms.push((at, compute, "compute"))
              from = at
              to = at + compute.len()
            }
            let explicit = if expand == none { () } else if type(expand) == array { expand } else { (expand,) }
            for e in explicit {
              let at = l.position(e)
              assert(at != none, message: "debug-run: `" + e + "` is not in line " + str(cur))
              ms.push((at, e, "expand"))
            }
            for m in l.slice(from, to).matches(expansion-pattern) {
              let at = from + m.start
              if not ms.any(x => x.at(2) in ("expand", "compute") and x.at(0) <= at and at < x.at(0) + x.at(1).len()) {
                ms.push((at, m.text, "expand"))
              }
            }
            ms
          }
          // the marks are drawn under the line: the code is monospaced, so
          // the place of a mark is the width of the text before it
          let marked(l, ms) = context {
            box({
              for (at, piece, kind) in ms {
                let x = measure(raw(l.slice(0, at), lang: "bash")).width
                let size = measure(raw(piece, lang: "bash"))
                place(dx: x - 2pt, dy: -3pt, box(
                  width: size.width + 4pt,
                  height: size.height + 6pt,
                  radius: 2pt,
                  fill: if kind == "part" { changed-fill } else if kind == "compute" { compute-fill } else { none },
                  stroke: if kind == "expand" { (paint: changed, thickness: 1pt, dash: "dotted") } else { none },
                ))
              }
              raw(l, lang: "bash")
            })
          }
          grid(
            columns: (0.8em, 1.2em, 1fr),
            column-gutter: (0em, 0.6em),
            inset: (x: 0.1em, y: 0.24em),
            fill: (x, y) => if y + 1 == cur and part == none and compute == none { changed-fill } else { none },
            ..lines
              .enumerate()
              .map(((k, l)) => (
                if k + 1 == cur { line-marker() } else { hide(line-marker()) },
                align(right, text(font: mono, size: 0.75em, fill: luma(150), str(k + 1))),
                if k + 1 == cur and marks(l).len() > 0 { marked(l, marks(l)) } else if also.any(x => x.at(0) == k + 1) {
                  // a piece of another line that matters on this step
                  marked(l, also.filter(x => x.at(0) == k + 1).map(x => (l.position(x.at(1)), x.at(1), "expand")))
                } else { raw(if l == "" { " " } else { l }, lang: "bash") },
              ))
              .flatten(),
          )
        })
        // the command line of this step, in a block as high as the
        // highest of all the steps (a long command wraps), so nothing moves
        layout(area => {
          let strips = steps.map(strip)
          let h = calc.max(..strips.map(x => measure(x, width: area.width).height))
          block(height: h, above: 0.6em, strip(s))
        })
      },
      {
        set text(size: size)
        // the variables
        if names.len() > 0 {
          let vars = vars-at.at(i)
          let changed-now = s.at("vars", default: (:)).keys()
          debug-panel([variables], {
            set text(font: mono, size: 0.75em)
            // the name in bold, the value in a box: the text it holds
            // (orange, when it changed on this step)
            grid(
              columns: (auto, auto, 1fr),
              column-gutter: 0.4em,
              row-gutter: 0.35em,
              align: horizon,
              ..names
                .map(n => {
                  let now = n in changed-now
                  let shown(body) = if n in vars { body } else { hide(body) }
                  let value = if n in vars { vars.at(n) } else { "x" }
                  (
                    shown(text(weight: "bold", fill: if now { changed } else { accent }, n)),
                    shown(text(fill: luma(140), "=")),
                    shown(box(
                      inset: (x: 0.3em, y: 0.15em),
                      outset: (y: 1pt),
                      radius: 2pt,
                      fill: if now { changed-fill } else { luma(242) },
                      stroke: 0.5pt + if now { changed.lighten(40%) } else { luma(200) },
                      text(fill: if now { changed } else { black }, if value == "" { hide("x") } else { value }),
                    )),
                  )
                })
                .flatten(),
            )
          })
        }
        // the output, a normal terminal block: the lines not printed yet are
        // hidden, so the block keeps its final size
        set align(left)
        show raw.line: it => {
          let k = it.number - first-out // index in all-out
          if k < 0 or k < old {
            render-terminal-line(it.text)
          } else if k < old + new {
            text(fill: changed, it.text)
          } else {
            hide(it.text)
          }
        }
        let out = raw(session.join("\n"), lang: none, block: true)
        // the files the script uses, next to the output
        if files.len() == 0 { out } else {
          grid(columns: (1fr, auto), column-gutter: 0.5em, out,
            stack(spacing: 0.4em, ..files.map(((name, lines)) => {
              // the lines that contain `match` of the step, highlighted
              let m = s.at("match", default: none)
              let hl = if m == none { () } else { range(lines.len()).filter(k => lines.at(k).contains(m)) }
              // the lines read on this step, by their numbers
              hl += s.at("read", default: ()).map(k => k - 1)
              file-view(name, lines, size: 0.6em, hl: hl)
            })))
        }
      },
    )
    if "note" in s {
      v(0.2em)
      text(size: note-size, s.note)
    }
  }

  for i in range(steps.len()) {
    // the last step stays on the next subslides (e.g. under a popup)
    if i == steps.len() - 1 { only(str(start + i) + "-", render(i)) } else { only(start + i, render(i)) }
  }
}
