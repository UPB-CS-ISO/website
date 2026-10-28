#import "/src/slides.typ": *

// Shared drawings for this lecture, in the same style as lecture 4
// (orange for whatever is new or changed on the current step).

#let accent = rgb("004d65")
#let changed = rgb("e65100")
#let changed-fill = rgb("fff3e0")
#let ok-color = rgb("2e7d46")
#let fail-color = rgb("c62828")
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

// an exit code, with a mark, so it is not told by color alone
// #exit-code(0) - ✅ 0 (green), #exit-code(1) - ❌ 1 (red)
#let exit-code(n) = if n == 0 {
  text(fill: ok-color)[✅ #raw(str(n))]
} else {
  text(fill: fail-color)[❌ #raw(str(n))]
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

// a titled panel of the debugger
#let debug-panel(title, body, height: auto) = block(
  width: 100%,
  height: height,
  radius: 0.3em,
  stroke: 0.8pt + luma(170),
  fill: white,
  inset: 0pt,
  clip: true,
  {
    block(width: 100%, fill: luma(235), inset: (x: 0.5em, y: 0.25em), below: 0pt, text(size: 0.75em, fill: luma(80), weight: "bold", title))
    block(width: 100%, inset: (x: 0.5em, y: 0.35em), above: 0pt, body)
  },
)

// A debugger-like view of a script running, one step per subslide:
// - the code with line numbers, the line that runs now marked in orange
// - the command the shell runs on that line (after replacing the
//   variables) and its exit code
// - the variables, the ones changed on this step in orange
// - the output so far, the lines printed on this step in orange
// Every panel keeps the space of its biggest step, so nothing moves.
//
// `code`: the script, a string
// `steps`: one dictionary per subslide, with the keys
//   line    - the line that runs now (1-based)
//   run     - what the shell runs, after expansion (string, optional)
//   status  - the exit code of `run` (int, optional)
//   vars    - all the variables after this step, a dictionary (optional)
//   changed - the names of the variables changed on this step (optional)
//   out     - the lines printed on this step (array of strings, optional)
//   note    - a tip for this step, shown under the debugger (optional)
// `start`: the subslide of the first step
// `columns`: the widths of the code and of the panels
//
// #debug-run("x=1\necho $x", (
//   (line: 1, vars: (x: "1"), changed: ("x",)),
//   (line: 2, run: "echo 1", status: 0, vars: (x: "1"), out: ("1",)),
// ))
#let debug-run(code, steps, start: 1, columns: (1fr, 1fr), size: 1em, note-size: 0.9em) = {
  let lines = code.split("\n")
  // every variable that shows up, in the order it shows up
  let names = ()
  for s in steps {
    for n in s.at("vars", default: (:)).keys() {
      if n not in names { names.push(n) }
    }
  }
  let total-out = steps.map(s => s.at("out", default: ()).len()).sum()
  let has-run = steps.any(s => "run" in s)
  let has-vars = names.len() > 0

  let render(i) = {
    let s = steps.at(i)
    let cur = s.line
    let vars = s.at("vars", default: (:))
    let changed-now = s.at("changed", default: ())
    // the output: what the previous steps printed, then this step
    let old = steps.slice(0, i).map(p => p.at("out", default: ())).flatten()
    let new = s.at("out", default: ())

    set text(size: size)
    grid(
      columns: columns,
      column-gutter: 1em,
      // the code
      debug-panel([script], {
        show raw.where(block: false): it => it.lines.join()
        grid(
          columns: (0.8em, 1.4em, 1fr),
          column-gutter: (0em, 0.5em),
          inset: (x: 0.1em, y: 0.22em),
          fill: (x, y) => if y + 1 == cur { changed-fill } else { none },
          ..lines
            .enumerate()
            .map(((k, l)) => (
              if k + 1 == cur { line-marker() } else { hide(line-marker()) },
              align(right, text(font: mono, size: 0.85em, fill: luma(150), str(k + 1))),
              raw(if l == "" { " " } else { l }, lang: "bash"),
            ))
            .flatten(),
        )
      }),
      // the panels
      {
        if has-run {
          debug-panel([the shell runs], {
            show raw.where(block: false): it => it.lines.join()
            if "run" in s {
              raw(s.run, lang: "bash")
              if "status" in s [ #h(0.3em) #arrow #h(0.2em) exit code #exit-code(s.status)]
            } else {
              hide[x]
            }
          })
        }
        if has-vars {
          debug-panel([variables], {
            set text(font: mono, size: 0.8em)
            grid(
              columns: (auto, 1fr),
              column-gutter: 0.8em,
              row-gutter: 0.4em,
              ..names
                .map(n => {
                  let cell(body) = if n in vars {
                    text(fill: if n in changed-now { changed } else { black }, body)
                  } else { hide(body) }
                  (cell(n), cell(if n in vars { vars.at(n) } else { "x" }))
                })
                .flatten(),
            )
          })
        }
        debug-panel([output], {
          set text(font: mono, size: 0.8em)
          set par(leading: 0.45em)
          for l in old { text(fill: luma(80), l); linebreak() }
          for l in new { text(fill: changed, l); linebreak() }
          // keep the space of the whole output
          for _ in range(total-out - old.len() - new.len()) { hide[x]; linebreak() }
          if total-out == 0 { hide[x] }
        })
      },
    )
    if "note" in s {
      v(0.4em)
      text(size: note-size, s.note)
    }
  }

  for i in range(steps.len()) {
    only(start + i, render(i))
  }
}
