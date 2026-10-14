#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Command Line #text(size: 10pt, weight: "regular")[\ _How the shell reads what you type_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.10 - _Special Characters_
      - Section 2.14 - _Shell Input and Output_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.2.3 - _Variabile shell_
      - Section 7.2.4 - _Expandări_
]

// ----- one command line, from the text to the process -----

// the example: every part of a command line, in one line
#let example = "$ LANG=C sort -r \"$HOME/my notes.txt\" my\\ list.txt *.csv > sorted.txt 2> errors.txt"

// The anatomy of a command line: the words in one row, each group
// underlined, with its label in a second row (so the words always stay on
// one straight line, whatever the height of the labels).
// `groups` are (words, label, step), a group shows up on its step.
#let anatomy(groups, size: 0.84em) = {
  set text(size: size)
  let c = changed
  grid(
    columns: groups.len(),
    column-gutter: 0.6em,
    row-gutter: 0.35em,
    align: (center + bottom),
    ..groups.map(((ws, name, step)) => uncover(str(step) + "-",
      box(stroke: (bottom: 1.2pt + c), inset: (bottom: 0.35em), words(..ws))
    )),
    ..groups.map(((ws, name, step)) => uncover(str(step) + "-",
      align(center + top, text(size: 0.8em, fill: c, name))
    )),
  )
}

#slide[
  == A Command Line
  Assignments, the command, its parameters and the redirects

  #terminal(example)

  #v(0.6em)
  #align(center, anatomy((
    ((("LANG=C", "word"),), [assignments\ (optional)], 1),
    ((("sort", "cmd"),), [the command], 2),
    (("-r", "\"$HOME/my notes.txt\"", "my\\ list.txt", "*.csv"), [its parameters], 3),
    (((">", "redir"), ("sorted.txt", "redir"), ("2>", "redir"), ("errors.txt", "redir")), [redirects\ (anywhere)], 4),
  )))

  #place(bottom + left, block(width: 100%)[
    #only(1)[💡 `NAME=value` words *at the start*: variables only for this command]
    #only(2)[💡 the first word that is not an assignment is the *command*]
    #only(3)[💡 everything else is a *parameter*: options, file names, texts]
    #only("4-")[💡 a redirect (`>`, `2>`, `<`, ...) and its file name are for the shell, not for `sort`]
  ])
]

// the steps of the shell on the example:
// (step, the words of the command, what the shell set apart)
#let split-steps = (
  ([split into words], ("LANG=C", "sort", "-r", "\"$HOME/my notes.txt\"", "my\\ list.txt", "*.csv", ">", "sorted.txt", "2>", "errors.txt"), ()),
  ([set apart], ("sort", "-r", "\"$HOME/my notes.txt\"", "my\\ list.txt", "*.csv"), (("LANG=C", "new"), ("> sorted.txt", "new"), ("2> errors.txt", "new"))),
  ([replace `$NAME`, `~`], ("sort", "-r", ("\"/home/alice/my notes.txt\"", "new"), "my\\ list.txt", "*.csv"), ()),
  ([expand the globs], ("sort", "-r", "\"/home/alice/my notes.txt\"", "my\\ list.txt", ("a.csv", "new"), ("b.csv", "new")), ()),
  ([remove quotes, `\`], ("sort", "-r", ("/home/alice/my notes.txt", "new"), ("my list.txt", "new"), "a.csv", "b.csv"), ()),
  ([run], (("sort", "cmd"), "-r", "/home/alice/my notes.txt", "my list.txt", "a.csv", "b.csv"), none),
)

// the steps of the shell on a command line, one row per step:
// `steps` are (step, the words of the command, what the shell set apart:
// an array of words, or none on the last row, where `final` is shown)
#let split-grid(steps, final) = {
  set text(size: 0.74em)
  grid(
    columns: (7.5em, 1fr, 10em),
    column-gutter: 0.8em,
    row-gutter: 0.45em,
    align: (right + horizon, left + horizon, left + horizon),
    ..steps.enumerate().map(((i, (name, ws, aside))) => {
      let when = str(i + 1) + "-"
      (
        uncover(when, text(size: 1.15em, label[#(i + 1). #name])),
        // nothing set apart yet (the first step): the words get the whole row
        ..if aside != none and aside.len() == 0 and i == 0 {
          (grid.cell(colspan: 2, uncover(when, words(..ws))),)
        } else {
          (
            uncover(when, words(..ws)),
            uncover(when, if aside == none { text(fill: changed, final) } else if aside.len() > 0 { words(..aside) } else { [] }),
          )
        },
      )
    }).flatten(),
  )
}

// a slide that splits one command line, with a note for every step
#let split-slide(title, subtitle, example, steps, final, notes) = slide[
  #heading(level: 2, title)
  #subtitle

  #terminal(example)

  #v(0.2em)
  #split-grid(steps, final)

  #place(bottom + left, block(width: 100%)[
    #set text(size: 0.95em)
    #for (i, n) in notes.enumerate() {
      only(if i == notes.len() - 1 { str(i + 1) + "-" } else { i + 1 })[💡 #n]
    }
  ])
]

#split-slide(
  [Splitting a Line],
  [What the shell does, step by step, before the command starts],
  example,
  split-steps,
  [`LANG=C` only for `sort` \ `1` #arrow `sorted.txt` \ `2` #arrow `errors.txt`],
  (
    [split at the spaces, except inside quotes and after a `\`; `>` and `2>` are words of their own: 10 words],
    [the assignment (no spaces around `=`) and the redirects (`>` or `2>` + the next word) are set apart],
    [`$HOME` is replaced inside `"..."` (not inside `'...'`), the result stays *one* word],
    [`*.csv` is not quoted: the shell replaces it with the matching file names],
    [the quotes and the `\` did their job: the shell removes them],
    [the shell sets up the redirects (it creates `sorted.txt`), then starts `sort` with 5 parameters and `LANG=C`],
  ),
)

// the second example: the values of the variables on the first line;
// the assignment is at the start, where it must be, one redirect is before
// the command, one (to a variable) in the middle, the same variable in
// double and in single quotes, and a glob
#let example2 = "$ IN=\"my notes.txt\" OUT=sorted.txt OPTS=\"-u -f\"\n$ LANG=C 2> errors.txt sort \"$IN\" '$IN' > \"$OUT\" -r $OPTS -t ',' *.csv"

#let split-steps2 = (
  ([split into words], ("LANG=C", "2>", "errors.txt", "sort", "\"$IN\"", "'$IN'", ">", "\"$OUT\"", "-r", "$OPTS", "-t", "','", "*.csv"), ()),
  ([set apart], ("sort", "\"$IN\"", "'$IN'", "-r", "$OPTS", "-t", "','", "*.csv"), (("LANG=C", "new"), ("2> errors.txt", "new"), ("> \"$OUT\"", "new"))),
  ([replace `$NAME`, `~`], ("sort", ("\"my notes.txt\"", "new"), "'$IN'", "-r", ("-u -f", "new"), "-t", "','", "*.csv"), (("> \"sorted.txt\"", "new"),)),
  ([split], ("sort", "\"my notes.txt\"", "'$IN'", "-r", ("-u", "new"), ("-f", "new"), "-t", "','", "*.csv"), ()),
  ([expand the globs], ("sort", "\"my notes.txt\"", "'$IN'", "-r", "-u", "-f", "-t", "','", ("a.csv", "new"), ("b.csv", "new")), ()),
  ([remove quotes, `\`], ("sort", ("my notes.txt", "new"), ("$IN", "new"), "-r", "-u", "-f", "-t", (",", "new"), "a.csv", "b.csv"), (("> sorted.txt", "new"),)),
  ([run], (("sort", "cmd"), "my notes.txt", ("$IN", "new"), "-r", "-u", "-f", "-t", ",", "a.csv", "b.csv"), none),
)

#slide[
  == Mixed Order
  The parts can be mixed: only the assignments must be at the start

  #terminal(example2)

  #v(0.6em)
  #align(center, anatomy(size: 0.84em, (
    ((("LANG=C", "word"),), [assignment], 1),
    ((("2>", "redir"), ("errors.txt", "redir")), [redirect], 4),
    ((("sort", "cmd"),), [command], 2),
    (("\"$IN\"", "'$IN'"), [parameters], 3),
    (((">", "redir"), ("\"$OUT\"", "redir")), [redirect], 4),
    (("-r", "$OPTS", "-t", "','", "*.csv"), [parameters], 3),
  )))

  #place(bottom + left, block(width: 100%)[
    #only(1)[💡 `LANG=C` is at the start: an assignment, only for this command]
    #only(2)[💡 the first word that is not an assignment or a redirect is the *command*]
    #only(3)[💡 the parameters do not have to be together, a redirect can be between them]
    #only("4-")[💡 the redirects can be anywhere: even before the command, or between the parameters]
  ])
]

#split-slide(
  [Another Line],
  [The assignment at the start, the redirects anywhere, double and single quotes, a glob],
  example2,
  split-steps2,
  [`LANG=C` only for `sort` \ `1` #arrow `sorted.txt` \ `2` #arrow `errors.txt`],
  (
    [the first line sets `IN`, `OUT` and `OPTS`; the second one has 13 words, a redirect is even before the command],
    [the assignment (at the start) and the 2 redirects are set apart; `> "$OUT"` was in the *middle*],
    [`$IN` is replaced inside `"..."`, but *not* inside `'...'`; `$OPTS` and `$OUT` are replaced too],
    [`$OPTS` was not quoted: it becomes 2 words; `"$IN"` was quoted: `my notes.txt` stays one word],
    [`*.csv` is not quoted: the files of the current directory, `a.csv` and `b.csv`],
    [the quotes did their job: the shell removes them, `'$IN'` becomes the text `$IN`],
    [`sort` gets a file named `$IN`: it does not exist, the error goes to `errors.txt`],
  ),
)

// the targets of fd 1 and 2, `changed` is the one that a redirect just changed
#let fd-state(one, two, changed-fd: none) = {
  let line(n, target) = {
    let on = changed-fd == n
    text(fill: if on { changed } else { black })[#box(width: 0.8em, raw(str(n))) #arrow #target]
  }
  box(
    inset: (x: 0.5em, y: 0.4em),
    radius: 0.3em,
    stroke: if changed-fd != none { 1.3pt + changed } else { 0.8pt + luma(140) },
    fill: white,
    align(left)[#line(1, one) \ #line(2, two)],
  )
}
#let display = [🖥️ display]
#let all-txt = [📄 `all.txt`]

// a redirect, drawn on the arrow between two states
#let redirect-step(op) = align(center)[
  #set par(leading: 0.2em)
  #text(font: mono, size: 0.85em, fill: changed, op) \
  #draw-arrow(length: 2.4em, color: changed)
]

#slide[
  == The Order of Redirects
  The shell applies them *from left to right*

  #let case(first, cmd, op1, s1, op2, s2, result) = {
    let vis(n, body) = if first + n - 1 <= 99 { uncover(str(first + n - 1) + "-", body) } else { body }
    (
      // the span is on the cell itself, the reveal inside it
      grid.cell(colspan: 6, vis(1, block(width: 60%, terminal(cmd)))),
      vis(1, fd-state(display, display)),
      vis(2, redirect-step(op1)),
      vis(2, s1),
      vis(3, redirect-step(op2)),
      vis(3, s2),
      vis(3, text(size: 0.9em, result)),
    )
  }

  #set text(size: 0.85em)
  #grid(
    columns: (auto, auto, auto, auto, auto, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.6em,
    align: horizon,
    ..case(
      1, "$ ls /nope > all.txt 2>&1",
      "> all.txt", fd-state(all-txt, display, changed-fd: 1),
      "2>&1", fd-state(all-txt, all-txt, changed-fd: 2),
      [nothing on the display, the error is in `all.txt`],
    ),
    grid.cell(colspan: 6, v(0.5em)),
    ..case(
      4, "$ ls /nope 2>&1 > all.txt",
      "2>&1", fd-state(display, display, changed-fd: 2),
      "> all.txt", fd-state(all-txt, display, changed-fd: 1),
      [the error is on the *display*],
    ),
  )

  #place(bottom + left, block(width: 100%)[
    #set text(size: 1.1em)
    #only("-3")[💡 `2>&1` means: `2` goes where `1` goes *now*]
    #only("4-")[💡 `2>&1` is a *copy*, not a link: changing `1` later does not change `2`]
  ])
]
