#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Logging In #text(size: 10pt, weight: "regular")[\ _how a process gets the label of a user_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.4 - _getty and login_
      - Section 7.9.3 - _User Identification, Authentication, and Authorization_
      - Section 7.10 - _Pluggable Authentication Modules_
  + #uso-book
    - Chapter 9 - _Pornirea sistemului_
      - Section 9.6.1 - _Pornirea terminalelor de login_
]

// the process tree while alice logs in on /dev/tty1, one tree per step
#let login-trees = (
  ```
  [PID 1]  systemd             user: root
  └── [PID 20]  agetty tty1    user: root
          # prints "login:" and reads the name
  ```,
  ```
  [PID 1]  systemd             user: root
  └── [PID 20]  login alice    user: root
          # agetty became login (exec)
          # reads the password
  ```,
  ```
  [PID 1]  systemd             user: root
  └── [PID 20]  login alice    user: root
          # PAM: is the password right?
          #   /etc/passwd  - alice, UID 1000
          #   /etc/shadow  - the hash
  ```,
  ```
  [PID 1]  systemd             user: root
  └── [PID 20]  login alice    user: root
        │   # fork
        └── [PID 30]  login    user: alice
                # setgid(1000), initgroups()
                # setuid(1000)
  ```,
  ```
  [PID 1]  systemd             user: root
  └── [PID 20]  login alice    user: root
        └── [PID 30]  bash     user: alice
                # exec /bin/bash in /home/alice
                # HOME, USER, SHELL are set
  ```,
)

#let login-notes = (
  ("⌨️", [the name], [`agetty` waits on the terminal, as `root`, for a user name]),
  ("🔑", [the password], [`agetty` *becomes* `login` (`exec`), still `root`, it asks for the password]),
  ("✅", [the check], [`login` asks *PAM* to check: find `alice`, hash the password with the salt from `/etc/shadow`, compare]),
  ("🏷️", [the label], [a child of `login` sets the *GID*, the *groups* and the *UID* of `alice`\ ⚠️ after `setuid` it can *never* go back to `root`]),
  ("🐚", [the shell], [it changes to the home directory and runs the *shell* from `/etc/passwd`\ every program `alice` starts inherits the label]),
)

#slide[
  == Logging In Locally
  🖥️ a text terminal, `/dev/tty1`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #for (i, tree) in login-trees.enumerate() {
      only(i + 1, {
        show raw.line: it => if it.text.trim().starts-with("#") { text(fill: luma(120), style: "italic", it.text) } else {
          show "user: alice": set text(fill: accent, weight: "bold")
          show "user: root": set text(fill: bad-color, weight: "bold")
          it
        }
        tree
      })
    }
  ][
    #set text(size: 0.9em)
    #for (i, (icon, title, body)) in login-notes.enumerate() {
      only(i + 1, card(icon: icon, title: title, body))
    }
  ]

  #align(bottom)[
    💡 a graphical login (`gdm`, `sddm`) and `ssh` do the *same steps*
  ]
]

#slide[
  == NSS and PAM
  🧩 two libraries every login program uses

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #card(icon: "📚", title: [NSS - _Name Service Switch_])[
      *where* to look for users and groups

      #set text(size: 0.8em)
      ```terminal
      $ grep -E '^(passwd|group)' /etc/nsswitch.conf
      passwd:   files systemd sss
      group:    files systemd sss
      ```
      `files` - `/etc/passwd`, `sss` - the network

      used by `ls -l`, `id`, `getent`, `ps` ...
    ]
  ][
    #uncover("2-")[
      #card(icon: "🔐", title: [PAM - _Pluggable Authentication Modules_], color: hl)[
        *how* to check who you are

        #set text(size: 0.8em)
        ```terminal
        $ ls /etc/pam.d/
        login  sshd  sudo  passwd  gdm-password ...
        ```
        one file for every program: password, fingerprint, a code from the phone ...

        used by `login`, `sudo`, `ssh`, `passwd` ...
      ]
    ]
  ]

  #uncover("3-")[
    💡 the login programs do not read `/etc/shadow` themselves, so new ways to log in only need a new *module*
  ]
]

// one computer of the domain
#let pc(name, active: false) = box(
  inset: (x: 0.5em, y: 0.3em),
  radius: 0.3em,
  stroke: if active { 1.5pt + hl } else { 0.8pt + luma(150) },
  fill: if active { hl-bg } else { white },
  text(size: 0.8em)[🖥️ #text(font: mono, name)],
)

#let domain-drawing(step) = {
  let active = step >= 2
  grid(
    columns: (auto, 1fr, auto),
    column-gutter: 0.8em,
    align: horizon,
    stack(dir: ttb, spacing: 0.4em, pc("lab-01", active: active), pc("lab-02"), pc("lab-..."), pc("lab-30")),
    {
      set text(size: 0.75em)
      if step >= 2 [#align(center)[#text(fill: hl)[is this alice's password?] \ #draw-arrow(length: 100%, color: hl)]]
      if step >= 3 [#align(center)[#rotate(180deg, draw-arrow(length: 100%, color: ok-color)) \ #text(fill: ok-color)[yes, a 🎟️ ticket + UID, groups, home]]]
    },
    box(
      inset: 0.6em,
      radius: 0.3em,
      fill: accent,
      text(fill: white, size: 0.85em)[
        🏢 *domain controller* \
        #v(0.2em)
        📒 *directory* (LDAP) - users, groups \
        🎟️ *Kerberos* - passwords, tickets
      ],
    ),
  )
}

#slide[
  == Logging In with a Domain
  🏢 one account, any computer of the organization

  #only(1, domain-drawing(1))
  #only(2, domain-drawing(2))
  #only("3-", domain-drawing(3))
  #v(0.5em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - a lab with 30 computers: create `alice` on *each* of them?
    #uncover("2-")[#block[- the users and groups are kept on a *server*, the domain controller]]
    #uncover("3-")[#block[- every computer asks the server when someone logs in]]
  ][
    #uncover("4-")[
      #table(
        columns: (auto, 1fr),
        table.header([], [Domain]),
        [🪟 Windows], [_Active Directory_: `UPB\alice`],
        [🐧 Linux], [_FreeIPA_, _Samba_, an _Active Directory_],
      )
    ]
  ]
]

#slide[
  == Domain Login on Linux
  🔌 `sssd` talks to the domain controller

  #domain-drawing(3)
  #v(0.3em)
  #toolbox.side-by-side(columns: (3fr, 1fr), gutter: 1em)[
    #set text(size: 0.7em)
    #reveal-terminal(before: none, lines: (1, 3, 5), full: false)[```terminal
    $ grep apopescu /etc/passwd
    $ getent passwd apopescu
    apopescu:*:1385401103:1385400513:Alice Popescu:/home/apopescu:/bin/bash
    $ id -nG apopescu
    domain users students lab-users
    ```]
  ][
    #set text(size: 0.85em)
    #only(1)[- ❓ `apopescu` is *not* in `/etc/passwd`]
    #only(2)[- 📚 NSS asks `sss`: the domain knows her, with a large UID]
    #only("3-")[- 👥 her groups come from the domain too]
  ]
]

#slide[
  == Local or Domain?
  ⚖️ the same steps, a different database

  #table(
    columns: (auto, 1fr, 1fr),
    table.header([], [🖥️ Local], [🏢 Domain]),
    [users and groups], [`/etc/passwd`, `/etc/group`], [the directory (LDAP), on the server],
    [the password is checked], [by `pam_unix`, with `/etc/shadow`], [by the server (Kerberos), through `pam_sss`],
    [the account works on], [*one* computer], [*every* computer of the domain],
    [without network], [✅ works], [only with a *cached* login, if `alice` logged in before],
    [home directory], [`/home/alice`], [created at the first login, or on a network disk (NFS)],
    [managed by], [`useradd`, `usermod` ...], [the administrators of the domain],
  )

  #uncover("2-")[
    💡 after the check, both end the same: `setgid`, `setuid`, `exec` the shell, the *label* is set
  ]
]
