#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Pipelines #text(size: 10pt, weight: "regular")[\ _Chain the commands together_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.14 - _Shell Input and Output_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Sections 4.5.3 - 4.5.4 - _Înlănțuirea comenzilor_, _Comunicarea prin pipe-uri_
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
]

// access.log: the address, the request and the status of the answer
#let access-log = (
  "10.0.0.7 GET /index.html 200",
  "10.0.0.9 GET /logo.png 404",
  "10.0.0.7 GET /about.html 200",
  "10.0.0.3 GET /old.html 404",
  "10.0.0.9 GET /favicon.ico 404",
  "10.0.0.5 GET /index.html 200",
  "10.0.0.9 GET /admin 404",
  "10.0.0.3 GET /old.html 404",
)

// the text between the commands of a pipeline: a small box with lines,
// `new` draws it in orange (it was just made)
#let text-box(lines, new: false) = box(
  inset: (x: 0.45em, y: 0.4em),
  radius: 0.3em,
  stroke: if new { 1.3pt + changed } else { 0.8pt + luma(150) },
  fill: if new { changed-fill } else { white },
  {
    set text(font: mono, size: 0.88em, fill: if new { changed } else { black })
    set par(leading: 0.4em)
    align(left, lines.map(l => [#l]).join(linebreak()))
  },
)

// a command of the pipeline between two texts: the command, with the pipe
// before it (not for the first one), and under it an arrow, the way the
// text flows; `new` draws it in orange
#let flow-cmd(cmd, first: false, new: false) = {
  let c = if new { changed } else { luma(120) }
  stack(
    spacing: 0.35em,
    // a box: the command must not wrap
    box({
      if not first { text(fill: c, weight: "bold", font: mono)[| ] }
      box(process(cmd.replace(" ", "\u{00A0}"), new: new))
    }),
    draw-arrow(length: 2.4em, color: c),
  )
}

// the steps of the pipeline: (the command, the text it writes)
#let flow-steps = (
  ("cat fruits.txt", fruits-lines),
  ("sort", ("apple", "apple", "apple", "banana", "banana", "cherry", "kiwi")),
  ("uniq -c", ("3 apple", "2 banana", "1 cherry", "1 kiwi")),
  ("sort -nr", ("3 apple", "2 banana", "1 kiwi", "1 cherry")),
)

#slide[
  == What Is a Pipeline
  The text flows through the pipes, every command changes it

  // for every command: the command (with its pipe), the text it writes;
  // step i shows the first i commands, the others keep their space
  #let n = flow-steps.len()
  #for upto in range(1, n + 1) {
    only(if upto == n { str(n) + "-" } else { upto }, align(center, {
      let cells = ()
      for (i, (cmd, out)) in flow-steps.enumerate() {
        let shown = i < upto
        let is-new = i == upto - 1
        let part = (flow-cmd(cmd, first: i == 0, new: is-new), text-box(out, new: is-new))
        for x in part { cells.push(if shown { x } else { hide(x) }) }
      }
      grid(columns: cells.len(), column-gutter: 0.25em, align: center + horizon, ..cells)
    }))
  }

  #v(0.6em)
  // the shell runs the same pipeline as the drawing, one more command every step
  #only(1)[#terminal("$ cat fruits.txt")]
  #only(2)[#terminal("$ cat fruits.txt | sort")]
  #only(3)[#terminal("$ cat fruits.txt | sort | uniq -c")]
  #only("4-")[#terminal("$ cat fruits.txt | sort | uniq -c | sort -nr")]

  #only(1)[💡 `cat` writes the text of `fruits.txt`]
  #only(2)[💡 `sort` reads it from the pipe: the same lines, in order]
  #only(3)[💡 `uniq -c` - every line once, with how many times it showed up]
  #only("4-")[💡 `sort -nr` - the most frequent first: every command does *one* small thing, the pipeline does the job]
]

// a stage of a typical pipeline: what it does and its commands
#let stage(title, what, cmds, example, color) = block(
  width: 100%,
  height: 5.6em,
  radius: 0.4em,
  stroke: 1.2pt + color,
  fill: color.lighten(92%),
  inset: (x: 0.5em, y: 0.5em),
  align(center)[
    #text(weight: "bold", fill: color, title) \
    #text(size: 0.75em, style: "italic", what)
    #v(0.2em)
    #text(size: 0.8em, cmds)
  ],
)

#slide[
  == A Typical Pipeline
  Which addresses asked for missing pages, and how many times?

  #let stages = (
    stage([Line Filters], [which lines, in which order], [`cat` `head` `tail` \ `sort` `uniq` ...], "tail -n 1000 access.log", accent),
    stage([Search], [the lines that match], [`grep`], "grep ' 404$'", ok-color),
    stage([Column Filters], [which parts of a line], [`cut` `tr` `sed` `rev` `nl`], "cut -d' ' -f1", rgb("9a4d76")),
    stage([Compute], [count or group], [`wc` `uniq -c` `awk`], "sort | uniq -c", changed),
  )
  #let pipe = text(size: 1.4em, weight: "bold", fill: luma(120), font: mono)[|]
  #grid(
    columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr),
    column-gutter: 0.4em,
    align: horizon,
    ..range(4).map(i => {
      let s = uncover(str(i + 1) + "-", stages.at(i))
      if i == 0 { (s,) } else { (uncover(str(i + 1) + "-", pipe), s) }
    }).flatten(),
  )

  // the command line, syntax highlighted, the part of the current step
  // framed in the color of its kind
  #let parts = (
    ("tail -n 1000 access.log", accent),
    ("grep ' 404$'", ok-color),
    ("cut -d' ' -f1", rgb("9a4d76")),
    ("sort | uniq -c", changed),
  )
  // as in a terminal: one command per line, continued with `\`
  #let command-line(step) = block(width: 100%, fill: luma(240), radius: 0.3em, inset: (x: 0.7em, y: 0.55em), {
    set text(font: mono, size: 0.9em)
    set par(leading: 0.5em)
    for (i, (t, c)) in parts.enumerate() {
      if i == 0 { text(fill: accent, weight: "bold")[\$ ] } else { text(fill: shell-op-color)[#h(1.2em)| ] }
      if i == step - 1 {
        box(fill: c.lighten(80%), stroke: 1.2pt + c, radius: 0.2em, inset: (x: 0.2em), outset: (y: 0.25em), highlight-shell(t))
      } else {
        highlight-shell(t)
      }
      if i < parts.len() - 1 { text(fill: shell-op-color)[ \\] }
      linebreak()
    }
  })

  // the text after every step
  #let outputs = (
    access-log,
    access-log.filter(l => l.ends-with(" 404")),
    access-log.filter(l => l.ends-with(" 404")).map(l => l.split(" ").at(0)),
    ("2 10.0.0.3", "3 10.0.0.9"),
  )

  // the output of every step has another height: the row keeps the height
  // of the tallest one, so the command line stays in the same place
  #let out-box(step) = file-contents("stdout", outputs.at(step - 1), size: 0.7em)
  #v(0.5em)
  #for step in range(1, 5) {
    only(if step == 4 { "4-" } else { step }, context {
      let tallest = calc.max(..range(1, 5).map(st => measure(out-box(st), width: 200pt).height))
      grid(
        columns: (1.2fr, auto, 1fr),
        rows: (tallest,),
        column-gutter: 0.8em,
        align: horizon,
        command-line(step),
        draw-arrow(color: parts.at(step - 1).at(1)),
        out-box(step),
      )
    })
  }
]
