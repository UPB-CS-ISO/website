#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Permissions #text(size: 10pt, weight: "regular")[\ `r`, `w` _and_ `x` _for files and directories_]
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
    intro: card(icon: "📄", title: [every file has])[
      - *one owner* (a user) and *one group*
      - three sets of permissions: for the *owner*, the *group* and the *others*
    ],
    (
      ("🗂️", [type], [`-` file, `d` directory, `l` symbolic link, `c` / `b` device ...]),
      ("👤", [`u` - user, the owner], [`rw-` - `alice` can *read* and *write*]),
      ("👥", [`g` - group], [`r--` - the members of `students` can only *read*]),
      ("🌍", [`o` - others], [`---` - everybody else can do *nothing*]),
      ("🔗", [links], [how many names (hard links) the file has]),
      ("👤", [owner], [the user that owns the file, usually the one that created it]),
      ("👥", [group], [the group of the file, usually the primary group of its creator]),
      ("📏", [size], [in bytes]),
      ("📅", [modified], [the last time the content changed]),
      ("🏷️", [name], [the name of the file]),
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
    #card(icon: "⚠️", title: [deleting a file is writing the *directory*], color: hl)[
      the name of a file is kept in its directory: with `w` on a directory you can delete *any* file in it, even if it is not yours
    ]
  ]
  #uncover("3-")[
    #card(icon: "💡", title: [to reach a file you need `x` on *every* directory of its path])[
      `cat /home/alice/notes.txt` needs `x` on `/`, `/home` and `/home/alice`
    ]
  ]
]

// the rules of the kernel, in order; the first one that matches wins
#let rules = (
  ([UID is `0`?], [`root`, *everything* is allowed]),
  ([UID is the *owner*?], [use the `u` permissions]),
  ([one of the *groups* is the group of the file?], [use the `g` permissions]),
  ([otherwise], [use the `o` permissions]),
)

// (user, UID, groups, the rule that matches, can read, can write)
#let who = (
  ("root", 0, "root", 0, true, true),
  ("alice", 1000, "alice sudo students", 1, true, true),
  ("bob", 1001, "bob students", 2, true, false),
  ("carol", 1002, "carol docker", 3, false, false),
)

#let rules-drawing(match) = {
  set text(size: 0.85em)
  for (i, (question, answer)) in rules.enumerate() {
    let state = if i < match { "no" } else if i == match { "yes" } else { "skip" }
    block(
      width: 100%,
      inset: (x: 0.6em, y: 0.4em),
      radius: 0.3em,
      fill: if state == "yes" { hl-bg } else { white },
      stroke: if state == "yes" { 1.5pt + hl } else { 0.8pt + luma(170) },
      text(fill: if state == "skip" { dim } else { black })[
        #box(width: 1.5em)[*#(i + 1).*] #question #h(1fr)
        #if state == "no" [#text(fill: luma(120))[no #arrow next]] else if state == "yes" [#text(fill: hl, weight: "bold")[yes:] #answer]
      ],
    )
  }
}

#slide[
  == Which Permissions Apply?
  ⚖️ the kernel checks the rules *in order*, the first one that matches wins

  #toolbox.side-by-side(columns: (4fr, 2fr), gutter: 1.2em)[
    #let when(i) = if i == who.len() - 1 { str(i + 1) + "-" } else { i + 1 }
    #for (i, w) in who.enumerate() {
      only(when(i), rules-drawing(w.at(3)))
    }
  ][
    #align(center)[
      #file-box("notes.txt", "alice", "students", "-rw-r-----")
      #v(0.5em)
      #let when(i) = if i == who.len() - 1 { str(i + 1) + "-" } else { i + 1 }
      #for (i, (name, uid, groups, match, r, wr)) in who.enumerate() {
        only(when(i))[
          #user-tag(name, uid) \
          #text(size: 0.7em, font: mono)[groups: #groups]
          #v(0.3em)
          #verdict(r, [read]) #verdict(wr, [write])
        ]
      }
    ]
  ]

  #uncover("5-")[
    #card(icon: "⚠️", title: [only *one* set is used], color: hl)[
      with `----rw----` the *owner* can do nothing, even if the group can read and write: the rule `2` already matched
    ]
  ]
]

#slide[
  == Directories in Practice
  📁 `r` lists, `x` enters

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #reveal-terminal(before: none, lines: (2, 5, 7, 10, 13), full: false)[```terminal
    $ ls -ld box
    drwxr-xr-x 2 alice alice 4096 Oct 11 09:00 box
    $ chmod u-r box
    $ ls box
    ls: cannot open directory 'box': Permission denied
    $ cat box/secret.txt
    hello
    $ chmod u+r,u-x box
    $ cd box
    bash: cd: box: Permission denied
    $ ls box
    ls: cannot access 'box/secret.txt': Permission denied
    secret.txt
    $ ls -ld /tmp
    drwxrwxrwt 18 root root 4096 Oct 11 09:00 /tmp
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[- `alice` has `rwx` on `box`]
    #only(2)[- without `r`: the *names* cannot be listed]
    #only(3)[- with `x`, a file whose name you *know* can still be opened]
    #only(4)[- without `x`: the directory cannot be *entered*]
    #only(5)[- `r` without `x`: the names are listed, but nothing more]
    #only(6)[- `/tmp`: everyone can write, the `t` (_sticky bit_) lets you delete *only your own* files]
  ]
]

#slide[
  == `chmod`
  ✏️ change the permissions, only the owner (or `root`) can do it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #card(icon: "🔤", title: [with letters])[
      *who* `u` `g` `o` `a` (all) \
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
        `r` = 4, `w` = 2, `x` = 1, add them for `u`, `g`, `o`

        #align(center)[
          #table(
            columns: 3,
            align: center,
            [`rw-`], [`r--`], [`---`],
            [4+2 = *6*], [4 = *4*], [*0*],
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

#slide[
  == Running as Another User
  🪄 the `s` bit (_setuid_): the program runs as its *owner*

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    ```terminal
    $ ls -l /usr/bin/passwd /etc/shadow
    -rwsr-xr-x 1 root root   64152 /usr/bin/passwd
    -rw-r----- 1 root shadow  1563 /etc/shadow
    ```
  ][
    - `alice` cannot write `/etc/shadow`
    #uncover("2-")[#block[- but `passwd` must change her hash in it]]
    #uncover("3-")[#block[- the `s` in place of `x`: `passwd` runs as `root`, the owner of the program]]
    #uncover("4-")[#block[- 💡 `passwd` itself makes sure `alice` only changes *her* password]]
  ]
]
