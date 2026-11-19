#import "/src/slides.typ": *
#import "/src/shell.typ": *

// Drawings of this lecture only; the ones shared with 6. Text Processing
// (word chips, exit codes, the debugger, ...) are in /src/shell.typ.

// ----- parameters -----

// the words of a call and the parameters they become: the command, and
// under every word after it its name, $1, $2, ...; then $#
// #param-map("greet", ("alice",))
#let param-map(cmd, args) = box(baseline: 30%, grid(
  columns: args.len() + 2,
  column-gutter: 0.4em,
  row-gutter: 0.3em,
  align: center + horizon,
  w(cmd, kind: "cmd"), ..args.map(a => w(a, kind: "new")), [#h(0.4em) #raw("$#") = #raw(str(args.len()))],
  [], ..range(args.len()).map(k => text(size: 0.85em, fill: changed, raw("$" + str(k + 1)))), [],
))

// ----- read and IFS -----

// what `read` puts in every variable: under every value, the name of the
// variable (orange); an empty value is drawn as ""
// #read-map(("Alice", "Mary Smith"), ("first", "last"))
#let read-map(values, names) = grid(
  columns: names.len(),
  column-gutter: 0.6em,
  row-gutter: 0.3em,
  align: center + horizon,
  ..values.map(v => if v == "" { text(fill: luma(150), raw("\"\"")) } else { w(v) }),
  ..names.map(n => text(size: 0.85em, fill: changed, raw(n))),
)

// a line of text, character by character, the separators (the characters
// of `IFS` in `seps`) in orange, a space drawn as a dot and a newline as
// \n so they can be seen
// #ifs-line("alice,Alice Smith", (",",))
#let ifs-line(line, seps) = box(stroke: 0.6pt + luma(150), radius: 0.2em, inset: (x: 0.3em, y: 0.25em), {
  set text(font: mono, size: 0.9em)
  for c in line.clusters() {
    if c in seps {
      box(fill: changed-fill, outset: (y: 0.15em), text(fill: changed, weight: "bold", if c == " " { "·" } else if c == "\n" { "\\n" } else { c }))
    } else {
      // a newline is drawn as \n, so the line stays one line
      if c == "\n" { text(fill: luma(140), "\\n") } else { c }
    }
  }
})

// the characters of IFS, as chips: ("space", "tab", "newline") or (",",)
#let ifs-chips(..cs) = [#raw("IFS") #h(0.2em) #words(..cs.pos().map(c => (c, "new")))]

// the default IFS: space, tab and newline
#let blank = (" ", "\t", "\n")

// ----- files -----

// a script shown on a slide, in the same frame as the script of the
// debugger: its name in the title bar, the code under it
// #code-panel("show.sh", "#!/bin/bash\nfor p in \"$@\"; do\n    echo \"[$p]\"\ndone")
// `hl`: the numbers (1-based) of the lines to mark in orange, e.g. the
// lines changed on this step
#let code-panel(name, code, hl: ()) = debug-panel(raw(name), {
  // inline raw is wrapped in a box by the template, which would break the lines apart
  show raw.where(block: false): it => it.lines.join()
  for (k, l) in code.split("\n").enumerate() {
    block(width: 100%, above: 0pt, below: 0pt, inset: (y: 0.2em), outset: (x: 0.3em),
      fill: if k + 1 in hl { changed-fill } else { none }, raw(l, lang: "bash"))
  }
})

// ----- running a script: the command line, then what happens (sections Shell Scripts and source) -----

// who does a step: the shell and bash in the theme color, the kernel in
// the kernel color of the diagrams

#let actor(name) = {
  let kernel = name == "kernel"
  box(
    width: 3.6em,
    fill: if kernel { rgb("ffe6cc") } else { accent },
    stroke: if kernel { 0.8pt + rgb("d79b00") } else { none },
    inset: (y: 0.25em),
    radius: 0.2em,
    align(center, text(size: 0.8em, weight: "bold", fill: if kernel { rgb("8a5a00") } else { white }, name)),
  )
}

// the permissions of a file, every set in the color of lecture 5;
// `x`: "check" - only the `x` of the owner (the user who runs the script)
// boxed, the group and others grayed out: the kernel checks one set only;
// "skip" - all crossed out, else plain

#let perms(x: none) = {
  let (u, g, o) = set-colors
  let xs(color, owner) = if x == "check" and owner {
    box(stroke: 0.8pt + changed.lighten(45%), fill: changed-fill, outset: (x: 1.5pt, y: 2.5pt), radius: 2pt, text(fill: color, weight: "bold")[x])
  } else if x == "skip" { text(fill: luma(170), strike[x]) } else { text(fill: color)[x] }
  // on "check", the sets the kernel does not look at are gray
  let other(color) = if x == "check" { luma(175) } else { color }
  text(font: mono)[#text(fill: luma(130))[-]#text(fill: u)[rw]#xs(u, true)#text(fill: other(g))[r-]#xs(other(g), false)#text(fill: other(o))[r-]#xs(other(o), false)]
}

// the `#!` of the first line, boxed

#let shebang-boxed = text(size: 0.8em)[#box(stroke: 1pt + changed.lighten(30%), fill: changed-fill, outset: (x: 1.5pt, y: 3pt), radius: 2pt, text(font: mono, fill: changed, weight: "bold")[\#!])#text(font: mono)[/bin/bash]]

// The command line on top, then, under it, the steps that run it, one
// per subslide: every step is a row (who - what), the row of the current
// step on an orange background. On the right, the script file and the
// output.
// `typed`: the command line (word chips)
// `rows`: one (actor, content) per step, the first one shows on step 2
// `file`: a function (step) -> (perms: none | "check" | "skip",
//         shebang: none | "read" | "comment", lines: highlighted lines)
// `out`: the step from which the output shows
// `extra`: (step, content) - shown instead of the output on that step

#let run-drawing(typed, rows, file, out, extra: none) = {
  let n = rows.len() + 1
  let lines = ("mkdir -p ~/backup", "cp ~/notes.txt ~/backup/", "echo \"backup done\"")
  let render(i) = {
    let f = file(i)
    grid(
      columns: (3fr, 2fr),
      column-gutter: 1.5em,
      {
        // the command line
        block(width: 100%, inset: 0.5em, radius: 0.3em, fill: if i == 1 { changed-fill } else { none }, below: 0pt, {
          label[you type] + h(0.6em) + text(size: 1.2em, typed)
        })
        // the steps, a small arrow down before each one (under the badges)
        let down(active) = block(above: 0pt, below: 0pt, inset: (left: 0.5em), box(width: 3.6em * 0.9, align(center,
          rotate(90deg, reflow: true, draw-arrow(length: 0.9em, color: if active { changed } else { luma(160) }, thickness: 1.2pt)))))
        for (k, (who, what)) in rows.enumerate() {
          let step = k + 2
          if i >= step { down(i == step) } else { hide(down(false)) }
          let body = block(width: 100%, inset: (x: 0.5em, y: 0.3em), radius: 0.3em, above: 0pt, below: 0pt,
            fill: if i == step { changed-fill } else { none },
            grid(columns: (auto, 1fr), column-gutter: 0.6em, align: horizon, actor(who), what))
          if i >= step { body } else { hide(body) }
        }
      },
      {
        set text(size: 1.15em)
        debug-panel(raw("backup.sh"), {
          show raw.where(block: false): it => it.lines.join()
          block(width: 100%, above: 0pt, below: 0.4em, inset: (y: 0.3em), stroke: (bottom: 0.5pt + luma(200)),
            [#label[permissions] #h(0.4em) #perms(x: f.at("perms", default: none))])
          let first = f.at("shebang", default: none)
          block(width: 100%, above: 0pt, below: 0pt, inset: (x: 0.2em, y: 0.25em),
            fill: if first == "read" { changed-fill } else { none },
            if first == "read" { shebang-boxed + h(1fr) + text(size: 0.8em, fill: changed, weight: "bold")[the kernel reads it] } else if first == "comment" { text(fill: luma(170), raw("#!/bin/bash")) } else { raw("#!/bin/bash", lang: "bash") })
          for (k, l) in lines.enumerate() {
            block(width: 100%, above: 0pt, below: 0pt, inset: (x: 0.2em, y: 0.25em),
              fill: if k + 2 in f.at("lines", default: ()) { changed-fill } else { none },
              raw(l, lang: "bash"))
          }
        })
        let o = debug-panel([output], {
          set text(font: mono, size: 0.9em)
          text(fill: changed)[backup done]
        })
        if extra != none and i == extra.at(0) { extra.at(1) } else if i >= out { o } else { hide(o) }
      },
    )
  }
  for i in range(1, n + 1) {
    only(i, render(i))
  }
}
