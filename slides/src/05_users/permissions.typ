#import "/src/slides.typ": *
#import "common.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#slide[
  = File Permissions #text(size: 10pt, weight: "regular")[\ `r`, `w` _and_ `x` _for files and directories_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.17 - _File Modes and Permissions_
  + #uso-book
    - Chapter 5 - _Utilizatori_
      - Section 5.5
]

#let ls-fields = ("-", "rw-", "r--", "---", "1", "alice", "students", "1234", "Oct 11 09:00", "notes.txt")

#slide[
  == Who Owns a File?
  🔍 `ls -l` shows the owner, the group and the permissions

  #set text(size: 0.95em)
  #record-walk(
    ls-fields,
    sep: ("", "", "", " ", " ", " ", " ", " ", " "),
    size: 1.05em,
    // the owner and the group in the colors of their permissions
    colors: (none, u-color, g-color, o-color, none, u-color, g-color, none, none, none),
    intro: card(icon: "📄", title: [every file has])[
      - *one owner* (a user) and *one group*
      - three sets of permissions: for the *owner*, the *group* and the *others*
    ],
    // only the permissions, the owner and the group, the other fields are skipped
    (
      none,
      ("👤", [`u` - user, the owner], [`rw-` - `alice` can *read* and *write*]),
      ("👥", [`g` - group], [`r--` - the members of `students` can only *read*]),
      ("🌍", [`o` - others], [`---` - everybody else can do *nothing*]),
      none,
      ("👤", [owner], [the user that owns the file, usually the one that created it]),
      ("👥", [group], [the group of the file, usually the primary group of its creator]),
      none,
      none,
      none,
    ),
  )
]

#slide[
  == `r`, `w` and `x`
  📖 the same letters, a different meaning for directories

  #table(
    columns: (auto, auto, 1fr, 1fr),
    table.header([], [Value], [📄 For a file], [📁 For a directory]),
    [`r` - read], [`4`], [read the content (`cat`)], [*list* the names inside (`ls`)],
    [`w` - write], [`2`], [change the content], [*create*, *delete*, *rename* the files inside],
    [`x` - execute], [`1`], [run it as a program], [*enter* it (`cd`) and reach the files inside],
  )

  #uncover("2-")[
    #card(icon: "⚠️", title: [creating, renaming or deleting a file is writing the *directory*], color: hl)[
      the names of the files are kept in their directory: with `w` on a directory you can rename or delete *any* file in it, even if it is not yours
    ]
  ]
  #uncover("3-")[
    #card(icon: "💡", title: [to reach a file you need `x` on *every* directory of its path])[
      `cat /home/alice/notes.txt` needs `x` on `/`, `/home` and `/home/alice`
    ]
  ]
]

// the names kept in a directory and their files:
// (name, new name at step 2, added at step, removed at step, content of the file)
#let dir-entries = (
  ("notes.txt", "todo.txt", none, none, "buy milk"),
  ("report.pdf", none, none, 4, "%PDF-1.7"),
  ("new.txt", none, 3, none, text(fill: luma(150), style: "italic")[empty]),
)

// The directory is a file whose content is a list of names, every name
// points to a file. `step` - 1: the list, 2: rename, 3: create, 4: delete
#let dir-drawing(step) = {
  let mark(color, body) = box(fill: color.lighten(85%), outset: 2pt, radius: 2pt, text(fill: color, weight: "bold", body))
  let file-node(body, gone: false) = box(
    width: 8em, inset: (x: 0.5em, y: 0.35em), radius: 0.3em,
    stroke: if gone { (paint: luma(180), thickness: 0.8pt, dash: "dashed") } else { 0.8pt + luma(150) },
    fill: white,
    text(fill: if gone { luma(170) } else { black })[📄 #text(font: mono, size: 0.85em, body)],
  )
  let n = dir-entries.len()
  let rows = ()
  for (i, (name, renamed, added, removed, content)) in dir-entries.enumerate() {
    let present = added == none or step >= added
    let deleted = removed != none and step >= removed
    let label = if renamed != none and step >= 2 {
      box[#text(fill: dim, strike(name)) #h(0.2em) #mark(if step == 2 { hl } else { accent }, renamed)]
    } else if deleted {
      text(fill: bad-color, strike(name))
    } else if added != none and step == added {
      mark(ok-color, name)
    } else { name }
    let color = if added != none and step == added { ok-color } else if renamed != none and step == 2 { hl } else { arrow-gray }
    let file = if deleted { file-node(gone: true)[deleted] } else { file-node(content) }
    rows.push(node((0, i), if present { text(font: mono, label) } else { hide(text(font: mono, label)) }, inset: 0.3em))
    rows.push(node((2, i), if present { file } else { hide(file) }, inset: 0pt))
    rows.push(edge((0, i), (2, i), arrow-marks, stroke: arrow-thickness + if present and not deleted { color } else { white }))
  }

  set text(size: 0.8em)
  diagram(
    spacing: (2.5em, 0.4em),
    node((0, -1), [📁 #text(font: mono, weight: "bold")[project] \ #text(size: 0.8em, fill: luma(110))[a file, its content is a *list of names*]], inset: 0.3em),
    node((2, -1), [📄 *the files* \ #text(size: 0.8em, fill: luma(110))[their content is kept apart]], inset: 0.3em),
    node(enclose: ((0, -1), (0, n - 1)), stroke: 1pt + accent, fill: accent.lighten(94%), corner-radius: 0.3em, inset: 0.4em),
    ..rows,
  )
}

#let dir-notes = (
  [📋 a directory is a file the OS reads: a *list of names*, each pointing to a file \ `r` *reads* this list, `w` *changes* it, `x` *uses* it to reach a file],
  [✏️ *rename* - `w` on the directory: only the name in the list changes, the file is not touched],
  [➕ *create* - `w` on the directory: a new name is added to the list],
  [🗑️ *delete* - `w` on the directory: the name is removed from the list, even if the file is read only],
)

#slide[
  == A Directory Is a List
  📋 a file read by the OS: the list of the files inside

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.62em)
    #reveal-terminal(before: none, lines: (5, 6, 7, 9), full: false)[```terminal
    $ ls -ld project
    drwxr-xr-x 2 alice alice 4096 Oct 11 09:00 project
    $ ls -l project
    -r--r--r-- 1 alice alice  9 Oct 11 09:00 notes.txt
    -r--r--r-- 1 alice alice 58 Oct 11 09:00 report.pdf
    $ mv project/notes.txt project/todo.txt
    $ touch project/new.txt
    $ rm project/report.pdf
    rm: remove write-protected regular file 'project/report.pdf'? y
    ```]
  ][
    #for step in range(1, 5) {
      only(if step == 4 { "4-" } else { step }, align(center, dir-drawing(step)))
    }
  ]

  #v(0.5em)
  #for (i, note) in dir-notes.enumerate() {
    only(if i == 3 { "4-" } else { i + 1 }, note)
  }
  #uncover("2-")[
    #v(0.2em)
    ✅ the files are `r--r--r--`, but `alice` has `w` on `project`: it is the *list* that changes
  ]
]

// (user, UID, groups, the rule that matches, can read, can write)
#let who = (
  ("root", 0, "root", 0, true, true),
  ("alice", 1000, "alice sudo students", 1, true, true),
  ("bob", 1001, "bob students", 2, true, false),
  ("carol", 1002, "carol docker", 3, false, false),
)

// The checks of the kernel as a flowchart, with the values of the process
// and of the file: a question on every row, `yes` goes right to a result,
// `no` goes down to the next question. `match` - the rule that matches, its
// path is highlighted.
#let rules-drawing(name, uid, groups, match) = {
  let colors = (bad-color, ..set-colors)
  let code(body) = text(font: mono, body)
  // a question, then the check with the values of the process and the file
  // after the answer `yes`, the next questions are not asked any more
  let ask(i, question, check) = [#question \ #text(size: 0.8em, fill: luma(120), if i <= match { check } else [⏭️ not checked, the answer is already known])]
  let questions = (
    ask(0, [is it `root`?], [its UID #code(str(uid)) = #code("0") ?]),
    ask(1, [is it the *owner* of the file?], [its UID #code(str(uid)) = #code("1000"), the UID of `alice` ?]),
    ask(2, [is #raw(name) a member of `students`?], [the groups of #raw(name): #code(groups)]),
  )
  let results = (
    [👑 everything is allowed],
    [use `u`: #text(fill: if match == 1 { set-colors.at(0) } else { luma(170) }, code("rw-"))],
    [use `g`: #text(fill: if match == 2 { set-colors.at(1) } else { luma(170) }, code("r--"))],
    [use `o`: #text(fill: if match == 3 { set-colors.at(2) } else { luma(170) }, code("---"))],
  )
  let path-color = colors.at(match)
  let reached(i) = i <= match
  let line-stroke(on) = if on { 1pt + path-color } else { arrow-thickness + luma(210) }
  let label(body, on) = text(size: 0.8em, fill: if on { path-color } else { luma(180) }, body)
  let question(i) = node(
    (0, i + 1), text(fill: if reached(i) { black } else { luma(170) }, questions.at(i)),
    width: 17em, corner-radius: 0.3em, inset: 0.45em, shape: rect,
    stroke: if reached(i) { 0.8pt + accent } else { 0.6pt + luma(215) },
  )
  let result(pos, i) = node(
    pos, text(fill: if i == match { black } else { luma(170) }, results.at(i)),
    width: 11.5em, corner-radius: 0.3em, inset: 0.45em, shape: rect,
    stroke: if i == match { 1pt + colors.at(i) } else { 0.6pt + luma(215) },
    fill: if i == match { colors.at(i).lighten(90%) } else { none },
  )
  set text(size: 0.8em)
  diagram(
    spacing: (2em, 1.6em),
    node((0, 0), proc-box("cat notes.txt", name, uid), inset: 0pt),
    edge((0, 0), (0, 1), arrow-marks, stroke: line-stroke(true)),
    ..range(3).map(i => (
      question(i),
      result((1, i + 1), i),
      // yes: to the result
      edge((0, i + 1), (1, i + 1), arrow-marks, stroke: line-stroke(i == match), label: label([yes], i == match), label-side: left),
      // no: to the next question, or to the `o` permissions
      edge((0, i + 1), (0, i + 2), arrow-marks, stroke: line-stroke(i < match), label: label([no], i < match), label-side: right),
    )).flatten(),
    result((0, 4), 3),
  )
}

// the permissions of the file, each set in its color, the one that is used
// is highlighted
#let mode-drawing(match) = {
  let part(body, i) = {
    let color = set-colors.at(i - 1)
    box(
      inset: (x: 0.15em, y: 0.25em), outset: (y: 1pt), radius: 2pt,
      fill: if i == match { color.lighten(90%) } else { none },
      stroke: if i == match { 0.8pt + color } else { none },
      text(fill: if i == match or match == 0 { color } else { color.lighten(50%) }, body),
    )
  }
  text(font: mono, size: 1.1em)[#text(fill: dim, "-")#part("rw-", 1)#part("r--", 2)#part("---", 3)]
}

#slide[
  == Which Permissions Apply?
  ⚖️ the kernel checks *in order*, the first answer `yes` decides

  #let when(i) = if i == who.len() - 1 { str(i + 1) + "-" } else { i + 1 }
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #for (i, (name, uid, groups, match, r, wr)) in who.enumerate() {
      only(when(i), rules-drawing(name, uid, groups, match))
    }
  ][
    #align(center)[
      #file-box("notes.txt", "alice", "students", "-rw-r-----")
      #v(0.4em)
      #for (i, (name, uid, groups, match, r, wr)) in who.enumerate() {
        only(when(i))[
          #mode-drawing(match)
          #v(0.4em)
          #verdict(r, [read]) #verdict(wr, [write])
        ]
      }
    ]
    #v(0.6em)
    #uncover("5-")[
      #set text(size: 0.75em)
      #card(icon: "⚠️", title: [only one set is used], color: hl)[
        with #text(font: mono, "----rw----") the owner can do nothing, even if the group can: the owner already got `yes`
      ]
    ]
  ]
]

// the directories of `alice`, as a tree: (depth, name, mode, last child, highlighted at steps)
#let dirs-rows = (
  (0, "📁 ~", none, true, ()),
  (1, "📁 box", "drwx------", false, (1,)),
  (2, "📄 notes.txt", none, true, (1,)),
  (1, "📁 noread", "d--x------", false, (2, 3)),
  (2, "📄 secret.txt", none, true, (3,)),
  (1, "📁 noenter", "dr--------", true, (4, 5)),
  (2, "📄 secret.txt", none, true, (4,)),
)

#let dirs-tree(step) = {
  set text(font: mono, size: 0.75em)
  block(width: 100%, inset: 0.6em, radius: 0.3em, fill: luma(245), {
    for (i, (depth, name, mode, last, marked)) in dirs-rows.enumerate() {
      let prefix = if depth == 0 { "" } else if depth == 1 { if last { "└── " } else { "├── " } } else {
        // the line of the parent continues if the parent is not the last child
        let parent-last = dirs-rows.slice(0, i).rev().find(r => r.at(0) == 1).at(3)
        (if parent-last { "    " } else { "│   " }) + "└── "
      }
      let on = step in marked
      let body = [#name #if mode != none { h(0.5em); mode }]
      text(fill: luma(150), prefix)
      if on { box(fill: hl-bg, outset: 2pt, radius: 2pt, text(fill: hl, weight: "bold", body)) } else { body }
      linebreak()
    }
  })
}

#slide[
  == Directories in Practice
  📁 `r` lists, `x` enters

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.88em)
    #reveal-terminal(before: none, lines: (4, 6, 8, 11, 13), full: false)[```terminal
    $ ls -l
    drwx------ 2 alice alice 4096 Oct 11 09:00 box
    d--x------ 2 alice alice 4096 Oct 11 09:00 noread
    dr-------- 2 alice alice 4096 Oct 11 09:00 noenter
    $ ls noread
    ls: cannot open directory 'noread': Permission denied
    $ cat noread/secret.txt
    hello
    $ ls noenter
    ls: cannot access 'noenter/secret.txt': Permission denied
    secret.txt
    $ cd noenter
    bash: cd: noenter: Permission denied
    ```]
  ][
    #for step in range(1, 6) {
      only(step, dirs-tree(step))
    }
    #v(0.6em)
    #set text(size: 0.95em)
    #only(1)[📁 three directories of `alice`, with different permissions for her]
    #only(2)[🙈 `noread` has no `r`: the *names* cannot be listed]
    #only(3)[🔑 but it has `x`: a file whose name you *know* can still be opened]
    #only(4)[👀 `noenter` has `r` without `x`: the names are listed, but nothing more]
    #only(5)[🚪 without `x`: the directory cannot be *entered*]
  ]
]

#slide[
  == `chmod`
  ✏️ change the permissions, only the owner (or `root`) can do it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #card(icon: "🔤", title: [with letters])[
      *who* #text(fill: u-color)[`u`] #text(fill: g-color)[`g`] #text(fill: o-color)[`o`] `a` (all) \
      *how* `+` add, `-` remove, `=` set \
      *what* `r` `w` `x`

      #set text(size: 0.8em)
      ```terminal
      $ chmod u+x script.sh
      $ chmod g+w,o-r notes.txt
      $ chmod a=r readme.txt
      $ chmod -R g+rX project/
      ```
    ]
  ][
    #uncover("2-")[
      #card(icon: "🔢", title: [with numbers (octal)])[
        `r` = 4, `w` = 2, `x` = 1, add them for #text(fill: u-color)[`u`], #text(fill: g-color)[`g`], #text(fill: o-color)[`o`]

        #align(center)[
          #table(
            columns: 3,
            align: center,
            text(font: mono, fill: u-color, "rw-"), text(font: mono, fill: g-color, "r--"), text(font: mono, fill: o-color, "---"),
            text(fill: u-color)[4+2 = *6*], text(fill: g-color)[4 = *4*], text(fill: o-color)[*0*],
          )
        ]
        #set text(size: 0.8em)
        ```terminal
        $ chmod 640 notes.txt
        $ chmod 755 script.sh
        ```
      ]
    ]
  ]
]

#slide[
  == `chown` and `chgrp`
  🔄 change the owner and the group

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 2, 3, 5), full: false)[```terminal
    $ sudo chown bob notes.txt
    $ sudo chown bob:students notes.txt
    $ chgrp students notes.txt
    $ chown carol notes.txt
    chown: changing ownership of 'notes.txt': Operation not permitted
    ```]
  ][
    #set text(size: 0.95em)
    #only(1)[- the owner becomes `bob`]
    #only(2)[- the owner *and* the group, `user:group`]
    #only(3)[- only the group, the owner may do it, if they are a member of the new group]
    #only(4)[- only `root` can give a file to another user]

    #uncover("4-")[
      #card(icon: "💡", title: [why only `root`?], color: hl)[
        otherwise, anyone could fill the disk quota of another user, or hide what they did
      ]
    ]
  ]
]
