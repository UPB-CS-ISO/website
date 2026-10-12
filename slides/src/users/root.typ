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

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - the kernel *skips* most of the checks for the UID `0`
    #uncover("2-")[#block[- reads and writes *any* file, sends signals to *any* process]]
    #uncover("3-")[#block[- installs software, adds users, mounts disks, changes the network]]
    #uncover("4-")[#block[- its home directory is `/root`, not `/home/root`]]
    #uncover("5-")[#block[- ⚠️ a mistake as `root` can *destroy* the whole system]]
  ][
    #uncover("2-")[
      #set text(size: 0.8em)
      ```terminal
      $ sudo cat /etc/shadow
      root:*:20737:0:99999:7:::
      ...
      $ sudo kill 812
      $ sudo rm -rf / # never do this
      ```
    ]
    #uncover("5-")[
      #card(icon: "⚠️", title: [work as a regular user], color: bad-color)[
        become `root` only for the commands that *need* it
      ]
    ]
  ]
]

#slide[
  == `root` Is Just a Name
  🏷️ the kernel checks the *UID*, not the name

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #highlight-code(("all", (1,), (2,), (1, 2)))[```
    admin:x:0:0:root:/root:/bin/bash
    toor:x:0:0:Bourne-again Superuser:/root:/bin/sh
    alice:x:1000:1000:Alice Smith,,,:/home/alice:/bin/bash
    ```]
    #align(center, text(size: 0.9em, style: "italic")[`/etc/passwd`, a renamed `root`])
  ][
    #only(1)[- `root` can be *renamed*, by editing `/etc/passwd`]
    #only(2)[- `admin` has the UID `0`: it *is* the administrator]
    #only(3)[- `toor` - a second name for UID `0`, used on some BSD systems]
    #only(4)[- two names, the *same user*: the kernel sees only `0`]

    #uncover("4-")[
      #card(icon: "⚠️", title: [do not rename `root`], color: hl)[
        many programs and scripts expect the name `root`
      ]
    ]
  ]
]
