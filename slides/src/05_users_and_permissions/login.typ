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
      - Section 7.9.4 - _Using Libraries for User Information_
  + #link("https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html")[`man 5 nsswitch.conf`] - where the C library looks for the users
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
          # is the password right?
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
  ("✅", [the check], [`login` finds `alice`#footnote[`login` asks the C library (`getpwnam()`, `getspnam()`), that may also find the users on a network server], hashes the password with the salt from `/etc/shadow` and compares]),
  ("🏷️", [the label], [a child of `login` sets the *GID*, the *groups* and the *UID* of `alice`\ ⚠️ after `setuid` it can *never* go back to `root`]),
  ("🐚", [the shell], [it changes to the home directory and runs the *shell* from `/etc/passwd`\ every program `alice` starts inherits the label]),
)

// the processes of the login, one drawing per step; every box keeps its
// place, the ones of the next steps are hidden
#let login-drawing(step) = {
  let shown(from, body) = if step >= from { body } else { hide(body) }
  let arrow(from-pos, to-pos, from, label) = edge(from-pos, to-pos, arrow-marks, stroke: arrow-thickness + if step >= from { arrow-gray } else { white }, label: if step >= from { text(size: 0.9em, fill: luma(110), label) }, label-side: left)
  let reads(to, from) = edge((1, 0), to, arrow-marks, stroke: (paint: if step >= from { arrow-gray } else { white }, thickness: arrow-thickness, dash: "dotted"))
  let parent = if step == 1 { proc-box("agetty", "root", 0) } else { proc-box("login", "root", 0) }
  let child = if step >= 5 { proc-box("bash", "alice", 1000) } else { proc-box("login", "alice", 1000) }
  let file(icon, path) = box(inset: (x: 0.5em, y: 0.4em), radius: 0.3em, stroke: 0.8pt + luma(150), fill: white)[#icon #text(font: mono, weight: "bold", path)]
  set text(size: 0.85em)
  align(center, diagram(
    spacing: (3em, 2.2em),
    thing((0, 0), proc-box("systemd", "root", 0)),
    thing((1, 0), parent),
    arrow((0, 0), (1, 0), 1, [starts]),
    // step 3: login checks the password
    thing((0.3, 1), shown(3, file("📄", "/etc/passwd"))),
    thing((1.7, 1), shown(3, file("🔐", "/etc/shadow"))),
    reads((0.3, 1), 3),
    reads((1.7, 1), 3),
    // step 4: the child gets the label of alice
    thing((2, 0), shown(4, child)),
    arrow((1, 0), (2, 0), 4, [`fork`]),
  ))
}

#slide[
  == Logging In Locally
  🖥️ a text terminal, `/dev/tty1`

  #counter(footnote).update(0)

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #for (i, tree) in login-trees.enumerate() {
      only(i + 1, {
        show raw.line: it => if it.text.trim().starts-with("#") { text(fill: luma(120), style: "italic", it.text) } else {
          show "user: alice": set text(fill: accent, weight: "bold")
          show "user: root": set text(fill: bad-color, weight: "bold")
          it
        }
        // every tree as tall as the longest one, so the drawing below stays in place
        block(height: 9.5em, tree)
      })
    }
    #v(0.5em)
    #for step in range(1, 6) {
      only(if step == 5 { "5-" } else { step }, login-drawing(step))
    }
  ][
    #set text(size: 0.9em)
    #for (i, (icon, title, body)) in login-notes.enumerate() {
      only(i + 1, card(icon: icon, title: title, body))
    }
  ]

  #v(1fr)
  #key("💡", [a graphical login (`gdm`, `sddm`) and `ssh` do the *same steps*], none)
]

// where the C library finds a user: login asks, nsswitch.conf says where to
// look, the places are asked in order, the answer goes back to login.
// `step` - the parts drawn so far, the others keep their place
#let nss-drawing(step) = {
  let on(from) = step >= from
  let shown(from, body) = if on(from) { body } else { hide(body) }
  let arrow(from-pos, to-pos, from, label, color: arrow-gray, dash: none, side: left, bend: 0deg) = edge(
    from-pos, to-pos, arrow-marks,
    stroke: (paint: if on(from) { color } else { white }, thickness: 1pt, dash: dash),
    // the label keeps its place when hidden, so the drawing does not move
    label: if label != none {
      let l = text(size: 0.85em, fill: if color == arrow-gray { luma(100) } else { color }, label)
      if on(from) { l } else { hide(l) }
    },
    label-side: side,
    bend: bend,
  )
  // a numbered badge, the order in which the places are asked
  let badge(n, color) = box(inset: (x: 0.35em, y: 0.15em), radius: 1em, fill: color, text(fill: white, weight: "bold", size: 0.85em, str(n)))
  let place-box(icon, title, body, color) = box(
    width: 14em, inset: (x: 0.6em, y: 0.5em), radius: 0.3em, stroke: 1.2pt + color, fill: color.lighten(92%),
    align(center)[#icon #text(fill: color, weight: "bold", title) \ #text(size: 0.8em, fill: luma(90), body)],
  )
  let conf = box(
    width: 14em, inset: (x: 0.6em, y: 0.5em), radius: 0.3em, stroke: 1.2pt + hl, fill: hl-bg,
    align(center)[📋 #text(font: mono, weight: "bold")[/etc/nsswitch.conf] \ #text(size: 0.8em, fill: luma(90))[where to look, and in which order]],
  )
  let local = place-box("📄", [local files], [`/etc/passwd`, `/etc/shadow`, `/etc/group`], accent)
  let network = place-box("🌐", [a server in the network], [LDAP, Active Directory ...], g-color)

  set text(size: 0.9em)
  diagram(
    spacing: (6.5em, 1.6em),
    // step 1: login asks the C library
    thing((0, 0), proc-box("login", "root", 0)),
    thing((1, 0), lib-box(width: 9em)[who is `alice`?]),
    arrow((0, 0), (1, 0), 1, [`getpwnam("alice")`]),
    // step 2: the C library reads where to look
    thing((1, 1.4), shown(2, conf)),
    arrow((1, 1.4), (1, 0), 2, [reads], color: hl, dash: "dotted", side: right),
    // steps 3 and 4: the places, in order
    thing((2, -0.6), shown(3, local)),
    arrow((1, 0), (2, -0.6), 3, badge(1, accent), color: accent),
    thing((2, 0.6), shown(4, network)),
    arrow((1, 0), (2, 0.6), 4, badge(2, g-color), color: g-color, side: right),
    // step 4: the answer goes back to login
    arrow((1, 0), (0, 0), 4, [✅ `alice`: UID `1000`, home, shell], color: ok-color, side: right, bend: -40deg),
  )
}

#let nss-notes = (
  [⚙️ `login` does not open the files: it asks the *C library* for the user],
  [📋 the C library reads `/etc/nsswitch.conf`: the *places* where users are kept],
  [📄 usually the *local files* first: `/etc/passwd`, `/etc/shadow`, `/etc/group`],
  [🌐 then, in a university or a company, a *server* in the network that keeps the accounts],
)

#slide[
  == Where Are the Users?
  🔎 `login` asks the C library, the C library knows where to look

  #align(center)[
    #for step in range(1, 5) {
      only(if step == 4 { "4-" } else { step }, nss-drawing(step))
    }
  ]

  #v(0.4em)
  #for (i, note) in nss-notes.enumerate() {
    only(if i == 3 { "4-" } else { i + 1 }, note)
  }
  #v(1fr)
  #uncover("4-", key("💡", [`id`, `ls -l`, `getent`, `sudo` ... all ask the *same* C library: they all see the same users], none))
]
