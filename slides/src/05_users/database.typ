#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Users Database #text(size: 10pt, weight: "regular")[\ `/etc/passwd` _and how programs read it_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.1 - _The /etc/passwd File_
      - Section 7.3.2 - _Special Users_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

#slide[
  == The Local Users Database
  📄 plain text files in `/etc`, one line for every user

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #highlight-code(("all", (1,), lines-range(2, 5), lines-range(6, 7), "all"))[```
    root:x:0:0:root:/root:/bin/bash
    daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
    www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
    sshd:x:110:65534::/run/sshd:/usr/sbin/nologin
    nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
    alice:x:1000:1000:Alice Smith,,,:/home/alice:/bin/bash
    bob:x:1001:1001:Bob Jones,,,:/home/bob:/bin/bash
    ```]
    #align(center, text(size: 0.9em, style: "italic")[`/etc/passwd` (shortened)])
  ][
    #set text(size: 0.9em)
    #only(1)[
      #card(icon: "📒", title: [`/etc/passwd`])[
        - one *user* on every line
        - the fields are separated by `:`
        - 🌍 *everyone* can read it
      ]
    ]
    #only(2)[
      #card(icon: "👑", title: [`root`], color: bad-color)[
        always the *first line*, UID `0`
      ]
    ]
    #only(3)[
      #card(icon: "⚙️", title: [system users], color: luma(110))[
        UID below `1000`, created when a service is installed

        the shell `/usr/sbin/nologin` refuses to log in
      ]
    ]
    #only(4)[
      #card(icon: "🧑", title: [regular users])[
        UID from `1000`, a home directory in `/home` and a real shell
      ]
    ]
    #only(5)[
      #card(icon: "💡", title: [the name has nothing special])[
        _passwd_ comes from the time when the *password* was kept in this file
      ]
    ]
  ]
]

#let passwd-fields = ("alice", "x", "1000", "1000", "Alice Smith,,,", "/home/alice", "/bin/bash")

#slide[
  == `/etc/passwd`
  🔍 the fields of one line

  #set text(size: 0.95em)
  #record-walk(
    passwd-fields,
    size: 1.3em,
    intro: card(icon: "📒", title: [7 fields, separated by `:`])[
      ```terminal
      $ grep alice /etc/passwd
      ```
      shows the line of `alice`
    ],
    (
      ("🏷️", [username], [the name used to log in: lowercase letters, digits, `-` and `_`]),
      ("🔒", [password], [`x` - the password is kept in `/etc/shadow`\ in the past, the *hash* of the password was here]),
      ("🔢", [UID], [the user ID, the *only* thing the kernel knows]),
      ("👥", [GID], [the ID of the *primary group* of the user]),
      ("🪪", [GECOS], [the full name, then the room, the phone numbers ... separated by `,`\ the name comes from an old operating system, _General Electric Comprehensive OS_]),
      ("🏠", [home directory], [the current directory after login, `~` and `$HOME`]),
      ("🐚", [shell], [the program started after login, `/usr/sbin/nologin` refuses the login]),
    ),
  )
]

// `whoami` shows a name: the kernel gives it the UID, libc finds the name
#let lookup-drawing = {
  set text(size: 0.75em)
  let gap = 1.6em
  grid(
    columns: (11em, auto, auto),
    column-gutter: 0em,
    row-gutter: 0.2em,
    align: center + horizon,
    // step 1: the kernel knows only the UID
    proc-box("whoami", "alice", 1000, width: 100%),
    labeled-arrow([`getuid()`], length: 5em),
    kernel-box[you run as \ UID #text(font: mono, weight: "bold")[1000]],
    // step 2: libc finds the name
    uncover("2-", down-arrow(length: gap, label: [`getpwuid(1000)`])), [], [],
    uncover("2-", lib-box(width: 100%)[who is UID `1000`?]), [], [],
    // step 3: in /etc/passwd
    uncover("3-", down-arrow(length: gap, label: [reads])), [], [],
    uncover("3-", db-file("/etc/passwd", none, none, none, width: 100%)[
      #text(fill: dim)[root:x:0:0:…] \
      #box(fill: hl-bg, outset: 2pt, radius: 2pt, text(fill: hl, weight: "bold")[alice:x:1000:1000:…])
    ]), [], [],
    // step 4: the name, on the screen
    uncover("4-", down-arrow(length: gap, label: [`"alice"`])), [], [],
    uncover("4-", box(width: 100%, fill: luma(240), inset: (x: 0.6em, y: 0.4em), radius: 0.3em, align(left, text(font: mono)[#text(fill: accent, weight: "bold")[\$] whoami \ #text(fill: hl, weight: "bold")[alice]]))), [], [],
  )
}

#slide[
  == From UID to Name
  📚 every program that shows a user name reads `/etc/passwd`, through the C library

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - the kernel gives programs only *UIDs*: `getuid()` tells `whoami` that it runs as UID `1000`
    #uncover("2-")[#block[
      - to find the *name*, the program calls a function of the C library:
        - `getpwuid(1000)` - the user with this UID
        - `getpwnam("alice")` - the user with this name
        - `getpwent()` - all the users, one by one
    ]]
    #uncover("3-")[#block[- `libc` reads `/etc/passwd` and returns a `struct passwd`: name, UID, GID, home, shell]]
    #uncover("4-")[#block[- `ls`, `ps`, `id`, `whoami`, the prompt ... all do this, so `/etc/passwd` must be readable by *everyone*]]
  ][
    #lookup-drawing
  ]

  #uncover("5-")[⚠️ never read `/etc/passwd` directly (`grep`, `cut`): the users may also come from other places]
]

// the forms of `getent passwd`, one per step
#let getent-calls = (
  ([`getent passwd alice`], [the user with this *name*]),
  ([`getent passwd 1000`], [the user with this *UID*]),
  ([`getent passwd`], [*all* the users]),
)

#let getent-table(current) = table(
  columns: (1fr, 1fr),
  fill: (_, y) => if y == current + 1 { hl-bg },
  table.header([Command], [Finds]),
  ..getent-calls.flatten(),
)

#slide[
  == `getent`
  🔎 _get entries_: finds a user, wherever it comes from

  #set text(size: 0.8em)
  #reveal-terminal(before: none, lines: (2, 4, 8), full: false)[```terminal
  $ getent passwd alice
  alice:x:1000:1000:Alice Smith,,,:/home/alice:/bin/bash
  $ getent passwd 1000
  alice:x:1000:1000:Alice Smith,,,:/home/alice:/bin/bash
  $ getent passwd
  root:x:0:0:root:/root:/bin/bash
  ...
  bob:x:1001:1001:Bob Jones,,,:/home/bob:/bin/bash
  ```]

  #set text(size: 1.1em)
  #for i in range(3) {
    only(if i == 2 { "3-" } else { i + 1 }, getent-table(i))
  }

  #uncover("3-")[✅ the same format as `/etc/passwd`: use `getent` in scripts, instead of `grep` or `cut`]
]
