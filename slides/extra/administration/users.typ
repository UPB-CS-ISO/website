#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Managing Users #text(size: 10pt, weight: "regular")[\ _the files, `sudo` and the special groups_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.4 - _Manipulating Users and Passwords_
      - Section 7.3.5 - _Working with Groups_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

#slide[
  == Editing the Files
  ✏️ the database is made of text files, they can be edited

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (auto, auto),
      table.header([File], [Edit it with]),
      [`/etc/passwd`], [`sudo vipw`],
      [`/etc/shadow`], [`sudo vipw -s`],
      [`/etc/group`], [`sudo vigr`],
    )
  ][
    #uncover("2-")[
      #card(icon: "🔒", title: [why not just `nano /etc/passwd`?])[
        - `vipw` and `vigr` *lock* the file, so no other program changes it at the same time
        - they *check* the file before saving it
      ]
    ]
    #uncover("3-")[
      #card(icon: "⚠️", title: [a mistake can lock you out], color: bad-color)[
        a broken `root` line means nobody can log in as `root` any more
      ]
    ]
  ]

  #uncover("4-", key("💡", [usually the *commands* are the safer way], [`useradd`, `usermod`, `groupadd` ... edit the files for you]))
]

#slide[
  == Who May Use `sudo`?
  👥 usually you do not edit the file, you join the group

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 4), full: false)[```terminal
    $ sudo usermod -aG sudo bob
    $ sudo -l -U bob
    User bob may run the following commands on laptop:
        (ALL : ALL) ALL
    ```]
  ][
    #only(1)[- `bob` joins `sudo` (`wheel` on Fedora): the rule `%sudo` gives him the rights]
    #only("2-")[- `sudo -l` lists what *you* may run, `-U` asks for another user]

    #uncover("3-")[
      #card(icon: "💡", title: [log in again])[
        `bob` must *log in again* before the new group takes effect
      ]
    ]
  ]
]

#slide[
  == Groups Give Rights
  🔑 some groups are special, joining them gives a right

  #table(
    columns: (auto, 1fr),
    table.header([Group], [Its members can]),
    [`sudo` / `wheel`], [become `root` with `sudo` (Debian, Ubuntu / Fedora, Arch)],
    [`adm`], [read the logs from `/var/log`],
    [`dialout`], [use the serial ports, `/dev/ttyUSB0` (Arduino, microcontrollers)],
    [`audio`, `video`], [use the sound card and the camera directly],
    [`docker`], [start containers, ⚠️ almost the same as being `root`],
  )

  #uncover("2-")[
    #set text(size: 0.8em)
    ```terminal
    $ ls -l /dev/ttyUSB0
    crw-rw---- 1 root dialout 188, 0 Oct 11 09:00 /dev/ttyUSB0
    ```
  ]
]
