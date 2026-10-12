#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Users Database #text(size: 10pt, weight: "regular")[\ `/etc/passwd` _and_ `/etc/shadow`]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.1 - _The /etc/passwd File_
      - Section 7.3.2 - _Special Users_
      - Section 7.3.3 - _The /etc/shadow File_
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

#slide[
  == Why `/etc/shadow` Exists
  🔐 the passwords cannot stay in a file that everyone reads

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.95em)
    - every process must translate UIDs into names (`ls -l`, `ps`, the prompt)
    #uncover("2-")[#block[- so `/etc/passwd` must be readable by *everyone*]]
    #uncover("3-")[#block[- the file stored a *hash* of the password, not the password, but ...]]
    #uncover("4-")[#block[- anyone could *copy* the hashes and try millions of passwords per second on their own computer]]
    #uncover("5-")[#block[- ✅ the hashes moved to `/etc/shadow`, that only `root` reads]]
  ][
    #set text(size: 0.8em)
    #uncover("2-")[
      ```terminal
      $ ls -l /etc/passwd /etc/shadow
      -rw-r--r-- 1 root root   2969 /etc/passwd
      -rw-r----- 1 root shadow 1563 /etc/shadow
      ```
    ]
    #uncover("4-")[
      #card(icon: "🔨", title: [an offline attack], color: bad-color)[
        hash("123456"), hash("password"), hash("alice2006") ... \
        compare every result with the stolen hash
      ]
    ]
    #uncover("5-")[
      #card(icon: "🔢", title: [a hash])[
        a *one way* function: easy to compute from the password, impossible to turn back into the password
      ]
    ]
  ]
]

#let shadow-fields = ("alice", "$y$j9T$Xr3…$9mQ…", "20737", "0", "99999", "7", "", "", "")

#slide[
  == `/etc/shadow`
  🔍 the fields of one line

  #set text(size: 0.95em)
  #record-walk(
    shadow-fields,
    size: 1.25em,
    intro: card(icon: "🔐", title: [9 fields, separated by `:`])[
      ```terminal
      $ sudo grep alice /etc/shadow
      ```
      only `root` can read it, so we need `sudo`
    ],
    (
      ("🏷️", [username], [the same name as in `/etc/passwd`]),
      ("🔢", [password hash], [`$algorithm$salt$hash`, `$y$` is _yescrypt_, `$6$` is _SHA-512_\ `!` or `*` - the account is *locked*, no password can log in]),
      ("📅", [last change], [the day of the last password change, counted from 1 January 1970: `20737` is 11 October 2026]),
      ("⏳", [minimum age], [days before the password can be changed again]),
      ("⌛", [maximum age], [days after which the password *must* be changed, `99999` - never]),
      ("⚠️", [warning], [days before the expiry when the user is warned]),
      ("💤", [inactive], [days after the expiry when the account is still usable, empty - no limit]),
      ("🚫", [expire date], [the day when the account is disabled, empty - never]),
      ("🧩", [reserved], [not used]),
    ),
  )
]

#slide[
  == The Salt
  🧂 the same password, a different hash

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - a random *salt* is added to the password before hashing
    #uncover("2-")[#block[- two users with the same password get *different* hashes]]
    #uncover("3-")[#block[- an attacker cannot use a list of hashes computed in advance]]
    #uncover("4-")[#block[- checking a password: take the salt from `/etc/shadow`, hash again, *compare*]]
  ][
    #set text(size: 0.75em)
    #uncover("2-")[
      #card(icon: "🔑", title: [`alice` and `bob`, both with `pass123`])[
        #text(font: mono)[alice:\$y\$j9T\$#text(fill: hl, weight: "bold")[Xr3a]…\$#text(fill: accent, weight: "bold")[9mQe]…]

        #text(font: mono)[bob:\$y\$j9T\$#text(fill: hl, weight: "bold")[Lp0w]…\$#text(fill: accent, weight: "bold")[Tz7k]…]
      ]
    ]
    #uncover("4-")[
      #card(icon: "✅", title: [checking a password], color: ok-color)[
        hash(#text(fill: hl)[salt] + password) #h(0.3em) = #h(0.3em) the #text(fill: accent)[stored hash] ?
      ]
    ]
  ]
]
