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
