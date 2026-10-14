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

// the groups of alice: the database, the old shell and the new one
#let label-drawing(step) = {
  let chip(name, new: false) = box(
    inset: (x: 0.35em, y: 0.15em), outset: (y: 1pt), radius: 1em,
    fill: if new { hl-bg } else { luma(235) },
    stroke: if new { 1pt + hl } else { none },
    text(font: mono, size: 0.9em, fill: if new { hl } else { black }, weight: if new { "bold" } else { "regular" }, name),
  )
  let groups(with-new) = [#chip("alice") #chip("sudo") #chip("students") #if with-new { chip("dialout", new: true) }]
  let shell(title, with-new, gone: false) = box(
    inset: (x: 0.6em, y: 0.45em), radius: 0.3em, fill: white,
    stroke: if gone { (paint: luma(190), thickness: 0.8pt, dash: "dashed") } else { 0.8pt + luma(150) },
  )[
    #set text(fill: luma(170)) if gone
    #align(center)[⚙️ #text(font: mono, weight: "bold", "bash") #text(size: 0.85em, fill: luma(110), if gone [🚪 logged out] else { title }) \ #v(0.1em) #if gone { text(fill: luma(170))[👤 #text(font: mono, weight: "bold", "alice")] } else { user-tag("alice", 1000) } \ #v(0.1em) #groups(with-new)]
  ]
  let shown(from, body) = if step >= from { body } else { hide(body) }
  let copy(to, from, label) = edge((0.5, 0), to, arrow-marks, stroke: (paint: if step >= from { arrow-gray } else { white }, thickness: arrow-thickness, dash: "dashed"), label: if step >= from { text(size: 0.85em, fill: luma(110), label) }, label-side: right)

  set text(size: 0.72em)
  align(center, diagram(
    spacing: (1.5em, 3.2em),
    thing((0.5, 0), box(inset: (x: 0.6em, y: 0.45em), radius: 0.3em, stroke: 0.8pt + luma(150), fill: white)[
      📒 #text(font: mono, weight: "bold", "/etc/group") \ #text(size: 0.85em, fill: luma(110))[the groups of `alice`] \ #v(0.1em) #groups(true)
    ]),
    // the shell from before the change, closed at step 4
    thing((0, 1), shell([old], false, gone: step >= 4)),
    copy((0, 1), 1, [at the *old* login]),
    // the shell after a new login
    thing((1, 1), shown(4, shell([new], true))),
    copy((1, 1), 4, [at the *new* login]),
  ))
}

#slide[
  == The Label Is Set at Login
  🔁 new groups need a new login

  #toolbox.side-by-side(columns: (4fr, 5fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    #prompt-term(reveal: (1, 3, 5, 8, 10))[```
    alice@laptop:~$ sudo usermod -aG dialout alice
    alice@laptop:~$ id -nG alice
    alice sudo students dialout
    alice@laptop:~$ id -nG
    alice sudo students
    alice@laptop:~$ logout
    laptop login: alice
    Password:
    alice@laptop:~$ id -nG
    alice sudo students dialout
    ```]

    #set text(size: 1.15em)
    #only(1)[➕ `alice` is added to `dialout`, in `/etc/group`]
    #only(2)[📒 `id alice` reads the *database*: `dialout` is there]
    #only(3)[🏷️ `id` alone shows the label of the *running shell*: its groups were copied at login, *before* the change]
    #only(4)[🚪 *log out* and log in again: `login` reads the database again]
    #only("5-")[✅ the new shell has `dialout`, and so will every program it starts]

    #uncover("4-")[
      #card(icon: "⚠️", title: [closing a shell is not enough], color: bad-color)[
        a new terminal window is started by the *same* login, so it gets the *old* groups
      ]
    ]
  ][
    #for step in range(1, 6) {
      only(if step == 5 { "5-" } else { step }, label-drawing(step))
    }
  ]
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
