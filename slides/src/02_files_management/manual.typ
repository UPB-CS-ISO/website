#import "/src/slides.typ": *
#import "diagram.typ": *

// a note in the same style as the tips of the other sections
#let card(icon: none, title: none, color: rgb("004d65"), height: auto, body) = block(
  width: 100%,
  height: height,
  inset: (x: 0.8em, y: 0.6em),
  radius: 0.3em,
  fill: luma(245),
  stroke: (left: 2pt + color),
)[
  #if title != none [#icon #text(fill: color, weight: "bold", title) #v(0.1em)]
  #body
]

#slide[
  = Manual #text(size: 10pt, weight: "regular")[\ `man` _and paths as parameters_]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.13 - _Getting Online Help_
]

// colors that tie a word of the manual page to its explanation
#let man-colors = (a: rgb("00838f"), b: rgb("e65100"), c: rgb("6a1b9a"))
#let man-mark(color, body) = highlight(
  fill: color.lighten(80%),
  radius: 2pt,
  extent: 1pt,
  text(fill: color, weight: "bold", body),
)
// a word in the explanation, in the same color as in the page
#let man-key(color, body) = man-mark(color, raw(body))

// Every step of the `man` slide: the lines of the page to highlight, the
// words to mark in them (substring, color), and the explanation card.
#let man-steps = (
  (
    lines: "all",
    marks: (),
    icon: "📖",
    title: [a manual page],
    body: [
      ```terminal
      $ man pwd
      ```
      opens the manual page of `pwd`

      every page has the *same parts*, in the same order
    ],
  ),
  (
    lines: (1, 28),
    marks: (("PWD(1)", man-colors.a), ("User Commands", man-colors.b)),
    icon: "🏷️",
    title: [header and footer],
    body: [
      #man-key(man-colors.a, "PWD(1)") the name and the _section_ of the page

      #man-key(man-colors.b, "User Commands") the name of section `1`
    ],
  ),
  (
    lines: lines-range(3, 4),
    marks: (("pwd", man-colors.a),),
    icon: "🪪",
    title: [NAME],
    body: [
      #man-key(man-colors.a, "pwd") and what it is, *in one line*
    ],
  ),
  (
    lines: lines-range(6, 7),
    marks: (("[OPTION]", man-colors.a), ("...", man-colors.b)),
    icon: "✍️",
    title: [SYNOPSIS],
    body: [
      *how to call it*

      #man-key(man-colors.a, "[ ]") is optional

      #man-key(man-colors.b, "...") can repeat
    ],
  ),
  (
    lines: lines-range(9, 16),
    marks: (("--logical", man-colors.c), ("--physical", man-colors.c), ("--help", man-colors.c), ("-L", man-colors.a), ("-P", man-colors.a)),
    icon: "📝",
    title: [DESCRIPTION],
    body: [
      *what it does*, in detail, and every option

      #man-key(man-colors.a, "-P") a short option

      #man-key(man-colors.c, "--physical") a long option, same meaning
    ],
  ),
  (
    lines: lines-range(18, 19),
    marks: (("0", man-colors.a),),
    icon: "🚦",
    title: [EXIT STATUS],
    body: [
      #man-key(man-colors.a, "0") means *success*

      anything else is an _error_
    ],
  ),
  (
    lines: lines-range(21, 23),
    marks: (("$ cd /home/alice/Movies && pwd", man-colors.a), ("/home/alice/Movies", man-colors.b)),
    icon: "🧪",
    title: [EXAMPLES],
    body: [
      #man-key(man-colors.a, "$ ...") a command to try

      #man-key(man-colors.b, "/home/...") what it prints
    ],
  ),
  (
    lines: lines-range(25, 26),
    marks: (("cd(1)", man-colors.a), ("ls(1)", man-colors.b)),
    icon: "🔗",
    title: [SEE ALSO],
    body: [
      *related pages*

      #man-key(man-colors.a, "cd(1)") the page of `cd`, section `1`
    ],
  ),
  (
    lines: "all",
    marks: (),
    icon: "⌨️",
    title: [inside the viewer],
    body: [
      #kbd("↑") #kbd("↓") #kbd("Space") scroll

      #kbd("/") _word_ #kbd("Enter") search

      #kbd("q") quit
    ],
  ),
)

// `body` with every occurrence of the (substring, color) marks highlighted
#let man-marked(body, marks) = {
  let out = ()
  let rest = body
  while rest.len() > 0 {
    // the mark that starts first (the longest one when several start together)
    let best = none
    for (sub, color) in marks {
      let at = rest.position(sub)
      if at != none and (best == none or at < best.at or (at == best.at and sub.len() > best.sub.len())) {
        best = (at: at, sub: sub, color: color)
      }
    }
    if best == none {
      out.push(rest)
      rest = ""
    } else {
      out.push(rest.slice(0, best.at))
      out.push(man-mark(best.color, best.sub))
      rest = rest.slice(best.at + best.sub.len())
    }
  }
  out.join()
}

// the manual page with the lines of `step` highlighted
#let man-page(step, body) = {
  let is-heading(t) = t.len() > 0 and t.match(regex("^[A-Z][A-Z ]*$")) != none
  show raw.line: it => {
    let current = step.lines == "all" or it.number in step.lines
    if not current {
      text(fill: luma(175), weight: if is-heading(it.text) { "bold" } else { "regular" }, it.text)
    } else if is-heading(it.text) {
      text(fill: rgb("004d65"), weight: "bold", it.text)
    } else {
      man-marked(it.text, step.marks)
    }
  }
  body
}

// the explanation of one step
#let man-card(step) = block(
  width: 100%,
  inset: (x: 0.8em, y: 0.7em),
  radius: 0.3em,
  fill: luma(245),
  stroke: (left: 2pt + rgb("004d65")),
)[
  #text(size: 1.1em)[#step.icon #text(fill: rgb("004d65"), weight: "bold", step.title)]
  #v(0.2em)
  #step.body
]

#slide[
  == `man`
  📖 Manual Pages - `man pwd` (shortened to fit the slide)

  #let page = ```
  PWD(1)                        User Commands                        PWD(1)

  NAME
         pwd - print the name of the current working directory

  SYNOPSIS
         pwd [OPTION]...

  DESCRIPTION
         Prints the absolute path of the current working directory,
         starting from the root directory /.
         -L, --logical
                keep the symbolic links that are part of the path
         -P, --physical
                replace symbolic links with the directories they point to
         --help show a short help text and exit

  EXIT STATUS
         0 on success, any other value if an error occurred

  EXAMPLES
         $ cd /home/alice/Movies && pwd
         /home/alice/Movies

  SEE ALSO
         cd(1), ls(1)

  shortened for this slide        2026                               PWD(1)
  ```

  #toolbox.side-by-side(columns: (3fr, 1.1fr), gutter: 1.2em)[
    #set text(size: 7pt)
    #set par(leading: 0.4em)
    #for (idx, step) in man-steps.enumerate() {
      only(idx + 1, man-page(step, page))
    }
  ][
    #set text(size: 0.85em)
    #for (idx, step) in man-steps.enumerate() {
      only(idx + 1, man-card(step))
    }
  ]
]

// Every command that receives a file or a directory receives a *path* to it.
// The tree used by the next slides: the current directory is `Movies`
// (line 5) and the file used in the examples is `watchlist.txt` (line 7).
#let path-param-tree(here, caption, target: 7) = {
  let lines = (
    "/",
    "└── home",
    "    └── alice",
    "        ├── Downloads",
    "        ├── Movies",
    "        │   └── the_odyssey.mkv",
    "        └── watchlist.txt",
  )
  set text(size: 0.85em)
  fs-tree(
    here: here,
    cwd: 5,
    caption: caption,
    lines.enumerate().map(((i, l)) => if i + 1 == target { l + " " + fs-target-mark } else { l }).join("\n"),
  )
}

#slide[
  == Files are Paths
  📂 commands receive paths, not just names

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[

    #let forms = (
      ("🏷️", [a *name*], "the_odyssey.mkv"),
      ("↩️", [a *relative path*], "../watchlist.txt"),
      ("🌍", [an *absolute path*], "/home/alice/watchlist.txt"),
      ("🏠", [a path with `~`], "~/watchlist.txt"),
    )
    #grid(
      columns: (auto, auto, 1fr),
      column-gutter: 0.6em,
      row-gutter: 1em,
      align: horizon,
      ..forms
        .enumerate()
        .map(((i, (icon, kind, example))) => (icon, kind, raw(example)).map(c => uncover(str(i + 2) + "-", c)))
        .flatten(),
    )

  ][
    #only(1)[#path-param-tree((5,), [we are in `/home/alice/Movies`], target: 8)]
    #only(2)[#path-param-tree((5, 6), [in the current directory], target: 6)]
    #only(3)[#path-param-tree((3, 5, 7), [from the current directory])]
    #only(4)[#path-param-tree((1, 2, 3, 7), [from the root `/`])]
    #only(5)[#path-param-tree((3, 7), [from the home directory `/home/alice`])]
  ]
  #align(bottom)[
    When a command expects a *file* or a *directory*, it accepts *any path* to it
  ]
]

#slide[
  == Same File, Many Paths
  🎯 all these commands open the *same file*

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (2, 4, 6, 8), full: false)[```terminal
    $ cat ../watchlist.txt
    Project Hail Mary
    $ cat /home/alice/watchlist.txt
    Project Hail Mary
    $ cat ~/watchlist.txt
    Project Hail Mary
    $ cat ../../alice/Downloads/../watchlist.txt
    Project Hail Mary
    ```]

    #text(size: 0.8em)[💡 `cat` prints the content of a file]
  ][
    // for every command: the tree lines to highlight and how its path becomes absolute
    #let same-file = (
      ((3, 5, 7), "↩️", [relative path], [joined to `/home/alice/Movies`]),
      ((1, 2, 3, 7), "🌍", [absolute path], [starts from the root `/`]),
      ((3, 7), "🏠", [home directory], [`~` is `/home/alice`]),
      ((2, 3, 4, 5, 7), "🌀", [a detour], [through `Downloads` and back]),
    )
    #for (i, (here, icon, title, how)) in same-file.enumerate() {
      let frames = if i == same-file.len() - 1 { str(i + 1) + "-" } else { i + 1 }
      only(frames)[
        #path-param-tree(here, none)
        #if title != none { card(icon: icon, title: title, how) }
      ]
    }
  ]
]

// Colors that tie a parameter in the SYNOPSIS to the value given to it
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

// the SYNOPSIS lines, the commands and, for every command, what to highlight
// (manual page, its SYNOPSIS line)
#let manual-synopsis = (
  ("CD(1)", "cd [DIR]"),
  ("LS(1)", "ls [OPTION]... [FILE]..."),
  ("CP(1)", "cp [OPTION]... SOURCE DEST"),
  ("MV(1)", "mv [OPTION]... SOURCE DEST"),
  ("MKDIR(1)", "mkdir [OPTION]... DIRECTORY..."),
  ("RM(1)", "rm [OPTION]... [FILE]..."),
)
#let manual-commands = (
  (
    command: "cp ../watchlist.txt /tmp/",
    line: 3,
    synopsis: (("SOURCE", param-colors.source), ("DEST", param-colors.dest)),
    marks: (("../watchlist.txt", param-colors.source), ("/tmp/", param-colors.dest)),
    relative: ("../watchlist.txt",),
  ),
  (
    command: "mv /tmp/watchlist.txt ~/Downloads/",
    line: 4,
    synopsis: (("SOURCE", param-colors.source), ("DEST", param-colors.dest)),
    marks: (("/tmp/watchlist.txt", param-colors.source), ("~/Downloads/", param-colors.dest)),
    relative: (),
  ),
  (
    command: "ls -l ~/Documents ../Downloads",
    line: 2,
    synopsis: (("[OPTION]...", param-colors.option), ("[FILE]...", param-colors.source)),
    marks: (("-l", param-colors.option), ("~/Documents", param-colors.source), ("../Downloads", param-colors.source)),
    relative: ("../Downloads",),
  ),
)

// The SYNOPSIS sections of the manual pages, drawn like the page on the
// `man` slide: a bold heading, then every line with the page it comes from.
// `current`: the index of the command being explained, none for no highlight
#let manual-synopsis-block(current) = {
  let width = calc.max(..manual-synopsis.map(((page, _)) => page.len())) + 2
  let lines = manual-synopsis.map(((page, synopsis)) => page + " " * (width - page.len()) + synopsis)
  show raw.line: line => {
    if line.number == 1 {
      return text(fill: rgb("004d65"), weight: "bold", line.text)
    }
    let (page, synopsis) = manual-synopsis.at(line.number - 2)
    let label = text(fill: luma(150), line.text.slice(0, width))
    if current != none and line.number - 1 == manual-commands.at(current).line {
      label + param-marked(synopsis, manual-commands.at(current).synopsis, (t, _) => t)
    } else {
      label + synopsis
    }
  }
  raw((("SYNOPSIS",) + lines).join("\n"), block: true)
}

// the first `shown` commands, drawn like a ```terminal``` block;
// `relative`: highlight only the relative paths of every command
#let manual-commands-block(shown, current, relative: false) = {
  show raw.line: line => {
    let i = line.number - 1
    let c = manual-commands.at(i)
    if i >= shown {
      hide(line.text)
    } else if relative {
      [#text(fill: rgb("004d65"), weight: "bold")[\$]#h(0.5em)]
      let marks = c.relative.map(r => (r, param-colors.source))
      param-marked(c.command, marks, (t, first) => highlight-shell(t, start-expect-command: first))
    } else if i == current {
      [#text(fill: rgb("004d65"), weight: "bold")[\$]#h(0.5em)]
      param-marked(c.command, c.marks, (t, first) => highlight-shell(t, start-expect-command: first))
    } else {
      render-terminal-line(line.text)
    }
  }
  raw(manual-commands.map(c => "$ " + c.command).join("\n"), block: true)
}

#slide[
  == Paths in the Manual
  📖 usually `FILE`, `DIR`, `SOURCE`, `DEST` is a path

  #let steps = manual-commands.len()
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[

    #only(1)[#manual-synopsis-block(none)]
    #for i in range(steps) {
      only(i + 2, manual-synopsis-block(i))
    }
    #only((beginning: steps + 2))[#manual-synopsis-block(none)]
  ][
    #uncover("2-")[
      relative and absolute paths can be *mixed* in the same command

      #for i in range(steps) {
        only(i + 2, manual-commands-block(i + 1, i))
      }
      // the last step: only the relative paths, next to the warning about them
      #only((beginning: steps + 2))[#manual-commands-block(steps, none, relative: true)]
    ]
  ]
    #uncover(str(steps + 2) + "-")[
      #card(icon: "⚠️", title: [relative paths], color: param-colors.source)[
        a *relative* path depends on _where you are_ when you run the command
      ]
    ]
]

#slide[
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 24pt)[⚠️ _read the manual_]

    always read the manual *before using AI and searching online* for commands that you want to use

    #v(1em)
    #set align(left)
    #set text(size: 0.9em)
    // same height and the same parts (title, command, text) in every card
    #let h = 9em
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 1em,
      only("2-")[
      #card(icon: "1️⃣", title: [the manual], height: h)[
        ```terminal
        $ man ls
        ```
        written for the *version installed* on your computer
      ]],
      only("3-")[
      #card(icon: "2️⃣", title: [the short help], height: h)[
        ```terminal
        $ ls --help
        ```
        a summary of the options, for most commands
      ]],
      only(4)[
      #card(icon: "3️⃣", title: [search online, ask AI], color: luma(120), height: h)[
        ```
        🔎 web   🤖 AI
        ```
        might be for *another version* or *wrong*, check the manual
      ]
      ],
    )
  ]
]
