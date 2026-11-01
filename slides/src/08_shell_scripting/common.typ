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
