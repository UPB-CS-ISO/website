#import "/src/slides.typ": *
#import "streams.typ": *

// A soft link drawn as a small file: the header has its name, the body
// has its contents, which is just a path.
//
//   ┌ 🔗 shortcut.txt ┐
//   │ notes.txt       │
//   └─────────────────┘
//
// `changed` draws it in orange (the link the current step talks about).
#let link-box(name, target, changed: false, width: 10em) = block(
  width: width,
  radius: 0.3em,
  clip: true,
  stroke: if changed { 1.5pt + stream-changed } else { 0.8pt + luma(150) },
  fill: white,
)[
  #block(width: 100%, fill: if changed { stream-changed-fill } else { luma(235) }, inset: (x: 0.6em, y: 0.4em), below: 0pt)[
    #set text(size: 0.85em)
    🔗 #text(font: stream-mono, size: 0.85em, name)
  ]
  #block(width: 100%, inset: (x: 0.6em, y: 0.5em), above: 0pt)[
    #set text(size: 0.8em)
    #text(fill: luma(110), style: "italic")[path:] #text(font: stream-mono, fill: if changed { stream-changed } else { black }, weight: if changed { "bold" } else { "regular" }, target)
  ]
]

// a file that does not exist (anymore): dashed and gray
#let missing-file(name) = box(
  inset: (x: 0.6em, y: 0.6em),
  radius: 0.3em,
  stroke: (paint: stream-unused, thickness: 0.8pt, dash: "dashed"),
  text(fill: stream-unused)[📄 #text(font: stream-mono, size: 0.85em, strike(name)) \ #text(size: 0.8em, style: "italic")[does not exist]],
)

// a folder at the end of a link
#let folder(name) = endpoint(width: 11em)[📁 #text(font: stream-mono, size: 0.85em, name)]

// links (and the file at the end) drawn left to right, with an arrow
// between them: the path the kernel follows
#let follow(..parts, color: luma(120)) = {
  let parts = parts.pos()
  let cells = ()
  for (i, p) in parts.enumerate() {
    if i > 0 { cells.push(draw-arrow(length: 2.2em, color: color)) }
    cells.push(p)
  }
  grid(columns: cells.len(), column-gutter: 0.6em, align: horizon, ..cells)
}

// Colors that tie a parameter in the SYNOPSIS to the value given to it,
// the same as in the manual slides of lecture 02
#let param-colors = (
  source: rgb("e65100"),
  dest: rgb("6a1b9a"),
  option: rgb("00838f"),
)
#let param-mark(color, body) = highlight(
  fill: color.lighten(82%),
  radius: 2pt,
  extent: 1pt,
  text(fill: color, weight: "bold", body),
)

// `body` with every (substring, color) of `marks` highlighted, in order;
// the text between the marks is drawn with `plain(text, is-first)`
#let param-marked(body, marks, plain) = {
  let out = ()
  let rest = body
  for (sub, color) in marks {
    let at = rest.position(sub)
    assert(at != none, message: "`" + sub + "` not found in `" + body + "`")
    out.push(plain(rest.slice(0, at), out.len() == 0))
    out.push(param-mark(color, sub))
    rest = rest.slice(at + sub.len())
  }
  out.push(plain(rest, out.len() == 0))
  out.join()
}

// the SYNOPSIS of `ln`, drawn like the manual page; `marked` highlights
// the parameters
#let ln-synopsis = "ln [OPTION]... [-T] TARGET LINK_NAME"
#let ln-synopsis-marks = (
  ("[OPTION]...", param-colors.option),
  ("TARGET", param-colors.source),
  ("LINK_NAME", param-colors.dest),
)
#let ln-synopsis-block(marked: false) = {
  let label = "LN(1)  "
  show raw.line: line => {
    if line.number == 1 {
      return text(fill: rgb("004d65"), weight: "bold", line.text)
    }
    text(fill: luma(150), label)
    if marked { param-marked(ln-synopsis, ln-synopsis-marks, (t, _) => t) } else { ln-synopsis }
  }
  raw("SYNOPSIS\n" + label + ln-synopsis, block: true)
}

// One line of `ls -l`: the first letter (the file type) is boxed, orange
// for a link, gray for anything else, and the `-> target` of a link is
// highlighted.
#let ls-entry(t) = {
  let (kind, rest) = (t.first(), t.slice(1))
  let (c, fill) = if kind == "l" { (white, stream-changed) } else { (black, luma(200)) }
  box(fill: fill, outset: (x: 1pt, y: 2pt), radius: 1pt, text(fill: c, weight: "bold", kind))
  let at = rest.position(" -> ")
  if at == none {
    text(fill: luma(100), rest)
  } else {
    text(fill: luma(100), rest.slice(0, at + 1))
    param-mark(stream-changed, rest.slice(at + 1))
  }
}

// A terminal where the `ls -l` lines are drawn with `ls-entry`; only the
// first `shown` lines are visible (the others keep their space).
// `marks` highlights the parameters of the first command, like the SYNOPSIS.
#let link-terminal(src, shown, marks: none) = {
  show raw.line: line => {
    let t = line.text
    if line.number > shown {
      hide(t)
    } else if t.starts-with("$ ") {
      if line.number == 1 and marks != none {
        [#text(fill: rgb("004d65"), weight: "bold")[\$]#h(0.5em)]
        param-marked(t.slice(2), marks, (x, first) => highlight-shell(x, start-expect-command: first))
      } else {
        render-terminal-line(t)
      }
    } else if t.match(regex("^[-dlc][rwx-]{9} ")) != none {
      ls-entry(t)
    } else {
      text(fill: luma(100), t)
    }
  }
  raw(src, block: true)
}

// `link-terminal` revealed step by step: `steps` are the visible lines
#let link-terminal-steps(src, steps, marks: none) = {
  for (i, n) in steps.enumerate() {
    let when = if i == steps.len() - 1 { (beginning: i + 1) } else { i + 1 }
    only(when, link-terminal(src, n, marks: if i == 0 { marks } else { none }))
  }
}

#slide[
  = Soft Links #text(size: 10pt, weight: "regular")[\ _Shortcuts to files and folders_]
]

#slide[
  == Bibliography
  For this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.17.2 - _Working with Symbolic Links_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.3.4.1 - _Crearea legăturilor simbolice_
]

#slide[
  == A Shortcut
  A file that points to another file

  #only(1)[#ln-synopsis-block(marked: true)]
  #only("2-")[#ln-synopsis-block()]

  #link-terminal-steps(
    "$ ln -s notes.txt shortcut.txt   # create the link
$ ls -l
-rw-r--r-- 1 alice alice 18 Oct 12 09:12 notes.txt
lrwxrwxrwx 1 alice alice  9 Oct 12 09:12 shortcut.txt -> notes.txt
$ cat shortcut.txt               # reads notes.txt
buy milk
call mom",
    (1, 4, 7),
    marks: (("-s", param-colors.option), ("notes.txt", param-colors.source), ("shortcut.txt", param-colors.dest)),
  )

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #align(center)[#follow(
      link-box("shortcut.txt", "notes.txt", changed: true),
      box(width: 9em, file-contents("notes.txt", ("buy milk", "call mom"))),
    )]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 `ln -s` creates a *soft link* (_symbolic link_) `LINK_NAME`: a *shortcut* to `TARGET`]
    #only(2)[💡 `l` - the type is _link_, and `ls -l` shows where it points: `-> notes.txt`]
    #only("3-")[💡 using the link uses the *target*: `cat` reads the lines of `notes.txt`]
  ]
]

#slide[
  == The Contents of a Link
  Just a path to a file or a folder

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (2, 5), full: false)[```terminal
    $ readlink shortcut.txt
    notes.txt
    $ ln -s /usr/share/doc docs
    $ readlink docs
    /usr/share/doc
    ```]
  ][
    #set text(size: 0.9em)
    #uncover("1-")[#block[- the link does *not* hold the data, it holds a *path*]]
    #uncover("1-")[#block[- the size of `shortcut.txt` is `9`: the length of the text `notes.txt`]]
    #uncover("2-")[#block[- the target can be a *file* or a *folder*]]
    #uncover("2-")[#block[- the path can be _absolute_ (`/usr/share/doc`) or _relative_ to the folder of the link (`notes.txt`)]]
  ]

  #v(0.5em)
  #align(center)[
    #only(1)[#follow(link-box("shortcut.txt", "notes.txt", changed: true), box(width: 9em, file-contents("notes.txt", ("buy milk", "call mom"))))]
    #only("2-")[#follow(link-box("docs", "/usr/share/doc", changed: true), folder("/usr/share/doc"))]
  ]
]

#slide[
  == Following Links
  The kernel reads the path and opens the target instead

  #reveal-terminal(before: none, lines: (4, 6), full: false)[```terminal
  $ ln -s shortcut.txt link.txt    # a link to a link
  $ cat link.txt
  buy milk
  call mom
  $ ls docs/                       # into the folder
  bash  coreutils  git  ...
  ```]

  #toolbox.side-by-side(columns: (3fr, 1fr), gutter: 1.5em)[
    #align(center)[
      #only(1)[#follow(
        link-box("link.txt", "shortcut.txt", changed: true),
        link-box("shortcut.txt", "notes.txt", changed: true),
        box(width: 9em, file-contents("notes.txt", ("buy milk", "call mom"))),
        color: stream-changed,
      )]
      #only("2-")[#follow(link-box("docs", "/usr/share/doc", changed: true), folder("/usr/share/doc"), color: stream-changed)]
    ]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 a link can point to *another link*: the kernel follows them all, until it finds a real file]
    #only("2-")[💡 a link to a folder works like the folder: `ls`, `cd`]
  ]
]

#slide[
  == Following Links
  Loops, and commands that do not follow

  #reveal-terminal(before: none, lines: (4, 7), full: false)[```terminal
  $ ln -s a b                      # b -> a
  $ ln -s b a                      # a -> b, a loop
  $ cat a
  cat: a: Too many levels of symbolic links
  $ rm link.txt                    # deletes only the link
  $ cat shortcut.txt
  buy milk
  ```]

  #toolbox.side-by-side(columns: (3fr, 1fr), gutter: 1.5em)[
    #align(center)[
      #only(1)[#follow(
        ..(("a", "b"), ("b", "a"), ("a", "b")).map(((l, t)) => link-box(l, t, changed: true, width: 6em)),
        [...],
        color: stream-changed,
      )]
      #only("2-")[#follow(link-box("shortcut.txt", "notes.txt"), box(width: 9em, file-contents("notes.txt", ("buy milk", "call mom"))))]
    ]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 a loop never gets to a real file: the kernel gives up after a few links]
    #only("2-")[⚠️ `ls -l`, `readlink` and `rm` do *not* follow: they work on the *link itself*]
  ]
]

#slide[
  == Broken Links
  The target is gone, the link stays

  #link-terminal-steps(
    "$ rm notes.txt                   # delete the target
$ ls -l
lrwxrwxrwx 1 alice alice 12 Oct 12 09:12 link.txt -> shortcut.txt
lrwxrwxrwx 1 alice alice  9 Oct 12 09:12 shortcut.txt -> notes.txt
$ cat shortcut.txt
cat: shortcut.txt: No such file or directory",
    (1, 4, 6),
  )

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #align(center)[#follow(
      link-box("shortcut.txt", "notes.txt"),
      missing-file("notes.txt"),
      color: stream-unused,
    )]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 deleting the target does *not* delete the links to it]
    #only(2)[💡 the links still hold their paths, but `notes.txt` does not exist: the link is *broken*]
    #only("3-")[
      💡 following a broken link fails\
      ⚠️ `ln -s` does not check that the target exists
    ]
  ]
]
