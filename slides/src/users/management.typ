#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Managing Users and Groups #text(size: 10pt, weight: "regular")[\ _files and commands_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.4 - _Manipulating Users and Passwords_
      - Section 7.3.5 - _Working with Groups_
      - Section 7.9.4 - _Using Libraries for User Information_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

#slide[
  == Who Am I?
  🔍 commands that only *read*, any user can run them

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (2, 4, 6, 9, 11), full: false)[```terminal
    $ whoami
    alice
    $ id
    uid=1000(alice) gid=1000(alice) groups=1000(alice),27(sudo),1100(students)
    $ groups bob
    bob : bob students
    $ who
    alice    tty1    2026-10-11 08:55
    bob      pts/0   2026-10-11 09:02 (10.0.0.7)
    $ getent passwd bob
    bob:x:1001:1001:Bob Jones,,,:/home/bob:/bin/bash
    ```]
  ][
    #only(1)[#card(icon: "🙋", title: [`whoami`])[the name of the user of the *current process*]]
    #only(2)[#card(icon: "🪪", title: [`id [user]`])[the *whole label*: UID, primary GID and the supplementary groups]]
    #only(3)[#card(icon: "👥", title: [`groups [user]`])[only the names of the groups]]
    #only(4)[#card(icon: "🖥️", title: [`who`, `w`])[who is logged in now, on which terminal, from where\ `last` - who logged in before]]
    #only(5)[#card(icon: "📚", title: [`getent passwd [user]`])[asks the *users database*: the local files #emph[and] the network (see _Logging In_)]]
  ]
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
      [`/etc/gshadow`], [`sudo vigr -s`],
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

  #uncover("4-")[💡 usually the *commands* on the next slide are the safer way]
]

#slide[
  == The Commands
  🛠️ they edit the files for you, they need `root`

  #set text(size: 0.9em)
  #table(
    columns: (auto, 1fr, 1fr),
    table.header([], [Users], [Groups]),
    [➕ create], [`useradd -m bob` - `adduser bob` (Debian)], [`groupadd students`],
    [✏️ change], [`usermod`, `chsh` (shell), `chfn` (full name)], [`groupmod`],
    [👥 membership], [`usermod -aG students bob`], [`gpasswd -a bob students` \ `gpasswd -d bob students`],
    [🔑 password], [`passwd bob`], [`gpasswd students`],
    [🗑️ delete], [`userdel -r bob` (`-r` also the home)], [`groupdel students`],
  )

  #uncover("2-")[
    💡 a user may run `passwd` and `chsh` without `sudo`, *only* for themselves
  ]
]

#slide[
  == Creating a User
  🧑 from nothing to logged in

  #toolbox.side-by-side(columns: (5fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #reveal-terminal(before: none, lines: (1, 5, 6, 7, 9, 10), full: false)[```terminal
    $ sudo useradd -m -c "Bob Jones" -s /bin/bash bob
    $ sudo passwd bob
    New password:
    Retype new password:
    passwd: password updated successfully
    $ sudo groupadd students
    $ sudo usermod -aG students bob
    $ id bob
    uid=1001(bob) gid=1001(bob) groups=1001(bob),1100(students)
    $ sudo userdel -r bob
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[`-m` creates `/home/bob`, `-c` the full name, `-s` the shell]
    #only(2)[sets the password, the hash goes in `/etc/shadow`]
    #only(3)[a new group, the next free GID]
    #only(4)[`-a` *appends* `students` to the groups of `bob`]
    #only(5)[the new label of `bob`]
    #only(6)[deletes `bob` and his home directory]

    #uncover("4-")[
      #card(icon: "⚠️", title: [never forget `-a`], color: bad-color)[
        `usermod -G students bob` *replaces* all the supplementary groups of `bob` with `students`
      ]
    ]
  ]
]

#slide[
  == The Label Is Set at Login
  ⏳ a running process does not see the new groups

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 3, 5, 6), full: false)[```terminal
    $ sudo usermod -aG dialout alice
    $ id -nG alice
    alice sudo students dialout
    $ id -nG
    alice sudo students
    $ newgrp dialout
    ```]
  ][
    #only(1)[- `alice` is added to `dialout`]
    #only(2)[- `id alice` reads the *database*: `dialout` is there]
    #only(3)[- `id` without a user shows the label of the *current shell*: no `dialout`]
    #only(4)[- `newgrp` starts a new shell with the group, or *log out* and log in again]

    #uncover("3-")[
      #card(icon: "🏷️", title: [the label of a process])[
        UID, GID and the supplementary groups are copied to the process at *login*, its children inherit them
      ]
    ]
  ]
]
