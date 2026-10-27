#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The `root` User #text(size: 10pt, weight: "regular")[\ _the administrator, UID 0_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.9.1 - _User IDs and User Switching_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

#slide[
  == The `root` User
  👑 the user with the UID `0`

  #toolbox.side-by-side(columns: (5fr, 4fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - the kernel *skips* most of the checks for the UID `0`
    #uncover("2-")[#block[- reads and writes *any* file, sends signals to *any* process]]
    #uncover("3-")[#block[- installs software, adds users, mounts disks, changes the network]]
    #uncover("4-")[#block[- its home directory is `/root`, not `/home/root`]]
    #uncover("5-")[#block[- ⚠️ a mistake as `root` can *destroy* the whole system]]
  ][
    #uncover("2-")[
      #set text(size: 0.8em)
      #prompt-term[```
      root@laptop:~# cat /etc/shadow
      root:!:20737:0:99999:7:::
      ...
      root@laptop:~# kill 812
      root@laptop:~# rm -rf /   # never do this
      ```]
    ]
    #uncover("5-")[
      #card(icon: "⚠️", title: [work as a regular user], color: bad-color)[
        #set text(size: 0.85em)
        become `root` only when a command *needs* it
      ]
    ]
  ]
]

// a line of /etc/passwd for UID 0: `mark` - "name" or "uid", the field to highlight
#let mark-box(body) = box(fill: hl-bg, outset: 2pt, radius: 2pt, text(fill: hl, weight: "bold", body))
#let uid0-line(name, gecos, shell, mark: none) = {
  let m(field, body) = if mark == field { mark-box(body) } else { body }
  [#m("name", name):x:#m("uid", "0"):0:#gecos:/root:#shell]
}

// /etc/passwd at every step
#let renamed-passwd(step) = {
  set text(font: mono, size: 0.8em)
  let mark = if step == 4 { "uid" } else if step <= 2 { "name" } else { none }
  block(width: 100%, fill: luma(245), inset: 0.7em, radius: 0.3em)[
    #if step == 1 { uid0-line("root", "root", "/bin/bash", mark: mark) } else if step == 2 { uid0-line([#text(fill: dim, strike("root"))#h(0.3em)admin], "root", "/bin/bash", mark: mark) } else { uid0-line("admin", "root", "/bin/bash", mark: mark) } \
    #let toor = uid0-line("toor", "Bourne-again Superuser", "/bin/sh", mark: if step == 3 { "name" } else { mark })
    #if step >= 3 { toor } else { hide(toor) } \
    #text(fill: dim)[alice:x:1000:1000:…:/home/alice:/bin/bash]
  ]
}

#slide[
  == `root` Is Just a Name
  🏷️ the kernel checks the *UID*, not the name

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for step in range(1, 5) {
      only(step, renamed-passwd(step))
    }
    #align(center, text(size: 0.8em, style: "italic")[`/etc/passwd`])
  ][
    #only(1)[- `root` is only the *name* of the UID `0`, the first field of `/etc/passwd`]
    #only(2)[- it can be *renamed*: change the name in `/etc/passwd` and in `/etc/shadow`]
    #only(3)[- `toor` - a second name for UID `0`, used on some BSD systems]
    #only(4)[- two names, the *same user*: the kernel sees only `0`]

    #uncover("4-")[
      #card(icon: "⚠️", title: [do not rename `root`], color: hl)[
        many programs and scripts expect the name `root`
      ]
    ]
  ]
]
