#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The `sudoers` File #text(size: 10pt, weight: "regular")[\ _who may run what as_ `root`]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.20 - _Running Commands as the Superuser_
  + #link("https://www.sudo.ws/docs/man/sudoers.man/")[`man 5 sudoers`] - the manual page of the file
]

// one card for every step of the file: (lines, icon, title, color, body)
#let file-steps = (
  ("all", "📍", [`/etc/sudoers`], accent, [
    the rules of `sudo`: *who* may run *what* as `root`

    #set text(size: 0.85em)
    ```terminal
    $ ls -l /etc/sudoers
    -r--r----- 1 root root 1800 /etc/sudoers
    ```
    only `root` can read it, nobody writes it directly
  ]),
  ((1,), "🧹", [`env_reset`], accent, [
    the command starts with a *clean* environment: only a few safe variables (`TERM`, `HOME`, `USER` ...) are kept

    💡 the variables of `alice` cannot change how a program of `root` behaves
  ]),
  ((2,), "📧", [`mail_badpass`], accent, [
    a *wrong password* sends an e-mail to the administrator: who tried, when and what command
  ]),
  ((3,), "🛣️", [`secure_path`], accent, [
    the `PATH` used to find the command, instead of the `PATH` of `alice`

    💡 a program called `ls` in `~/bin` is never run as `root` by mistake
  ]),
  ((4,), "🖥️", [`use_pty`], accent, [
    the command runs in its *own* (pseudo) terminal

    💡 a program left in the background cannot type commands in the terminal of `alice` after `sudo` ends
  ]),
  ((6, 7), "👑", [the first rule], accent, [
    `root` may do anything, of course
  ]),
  ((9, 10), "👥", [the administrators], hl, [
    every member of the group `sudo` may run *any* command as `root` \
    Fedora and Arch use the group `wheel`

    👉 let's read this line
  ]),
  ((12,), "📁", [more files], accent, [
    every file in `/etc/sudoers.d/` is read too \
    ⚠️ `@includedir` (the old form is `#includedir`) is *not* a comment
  ]),
)

#slide[
  == The `sudoers` File
  📍 `/etc/sudoers` - the same place on every distribution (Ubuntu's, shortened)

  #toolbox.side-by-side(columns: (7fr, 4fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    ```terminal
    $ sudo cat /etc/sudoers
    ```
    #v(-0.3em)
    #highlight-code(file-steps.map(s => s.at(0)))[```
    Defaults  env_reset
    Defaults  mail_badpass
    Defaults  secure_path="/usr/sbin:/usr/bin:/sbin:/bin"
    Defaults  use_pty

    # User privilege specification
    root    ALL=(ALL:ALL) ALL

    # Allow members of group sudo to execute any command
    %sudo   ALL=(ALL:ALL) ALL

    @includedir /etc/sudoers.d
    ```]
  ][
    #set text(size: 0.85em)
    #for (i, (lines, icon, title, color, body)) in file-steps.enumerate() {
      only(i + 1, card(icon: icon, title: title, color: color, body))
    }
    #uncover(str(2) + "-" + str(5))[
      #set text(size: 0.85em)
      💡 more settings in `man 5 sudoers`, e.g. `timestamp_timeout=15`: remember the password 15 minutes (the default is 5)
    ]
  ]
]

// ----- the sudoers rules: every part of a rule has its own color, the
// same in the rule and in its plain English translation -----

#let rule-colors = (
  who: rgb("00838f"),
  where: rgb("6a1b9a"),
  user: hl,
  group: rgb("8d6e63"),
  pass: bad-color,
  what: ok-color,
)

// A rule or a sentence is an array of pieces: a plain string, or a
// (text, key) pair drawn in the color of `key`. `current` - the key to
// highlight (the other keys are grayed out), none - all of them colored.
#let colored(pieces, current: none, mono-font: false) = {
  let out = ()
  for p in pieces {
    if type(p) == str or type(p) == content {
      out.push(text(fill: if mono-font { luma(110) } else { black }, p))
    } else {
      let (t, key) = p
      let color = rule-colors.at(key)
      if current == key {
        out.push(highlight(fill: color.lighten(85%), radius: 2pt, extent: 2pt, text(fill: color, weight: "bold", t)))
      } else {
        out.push(text(fill: if current == none { color } else { dim }, weight: "bold", t))
      }
    }
  }
  if mono-font { text(font: mono, out.join()) } else { out.join() }
}

#let rule(pieces, current: none) = colored(pieces, current: current, mono-font: true)

// the rule of the administrators, from /etc/sudoers, and how to read it
#let full-rule = (("%sudo", "who"), " ", ("ALL", "where"), "=(", ("ALL", "user"), ":", ("ALL", "group"), ") ", ("ALL", "what"))
#let full-say = (
  ("every member of sudo", "who"), " may run, ", ("on any computer", "where"), ", as ", ("any user", "user"), " and ",
  ("any group", "group"), ", ", ("any command", "what"),
)

// one explanation for every part of a rule: (key, question, body)
#let rule-parts = (
  ("who", [👤 who?], [
    `%sudo` - every member of the group `sudo` #h(1fr) `alice` - one user #h(1fr) `ALL` - everybody
  ]),
  ("where", [🖥️ on which computer?], [
    `lab-01` - only on the computer called `lab-01` #h(1fr) `ALL` - on any computer \
    💡 the same file can be copied on all the computers of a lab
  ]),
  ("user", [🎭 as which user?], [
    `(root)` - only as `root` #h(1fr) `(www-data)` - only as `www-data` #h(1fr) `(ALL)` - as anyone \
    💡 `sudo` runs as `root`, `sudo -u bob` chooses another user
  ]),
  ("group", [👥 as which group?], [
    `sudo -g students` runs the command with the group `students` \
    💡 it may be missing: `(root)` alone does not allow changing the group
  ]),
  ("what", [⚙️ which commands?], [
    `/usr/bin/apt` - `apt`, with *any* arguments #h(1fr) `ALL` - any command \
    `/usr/bin/systemctl restart nginx` - *exactly* these arguments \
    💡 always the *full path*: `sudo` does not trust `PATH`
  ]),
)

#slide[
  == Reading a `sudoers` Rule
  📜 *who* may run *what*, *where* and *as whom*

  #let n = rule-parts.len()
  #for step in range(n + 2) {
    let current = if step == 0 or step > n { none } else { rule-parts.at(step - 1).at(0) }
    only(step + 1)[
      #align(center)[
        #text(size: 0.85em, fill: luma(110))[📄 `/etc/sudoers`, line 10]
        #v(-0.2em)
        #text(size: 1.9em, rule(full-rule, current: current))
        #v(0.3em)
        #text(size: 1em, colored(full-say, current: current))
      ]
      #v(0.6em)
      #if current != none {
        let (key, question, body) = rule-parts.at(step - 1)
        card(icon: none, title: question, color: rule-colors.at(key), body)
      } else if step == 0 {
        card(icon: "📜", title: [the line that makes `alice` an administrator])[
          read it like a sentence: *who*, on which *computer*, then `=` and, in `( )`, *as whom*, at the end the *commands*
        ]
      } else {
        card(icon: "👑", title: [the rule of the administrators])[
          `alice` is a member of `sudo`: she may do *anything* `root` can do, with *her* password
        ]
      }
    ]
  }
]

// more rules, each with its translation
#let examples = (
  (
    (("alice", "who"), " ", ("ALL", "where"), "=(", ("ALL", "user"), ":", ("ALL", "group"), ") ", ("ALL", "what")),
    (("alice", "who"), " may run ", ("anything", "what"), ", ", ("on any computer", "where"), ", as ", ("any user", "user"), " and ", ("any group", "group"), " (she does not need to be in sudo)"),
  ),
  (
    (("alice", "who"), " ", ("ALL", "where"), "=(", ("root", "user"), ") ", ("NOPASSWD:", "pass"), " ", ("/usr/bin/apt", "what")),
    (("alice", "who"), " may run ", ("apt", "what"), ", ", ("on any computer", "where"), ", ", ("only as root", "user"), ", ", ("without a password", "pass")),
  ),
  (
    (("bob", "who"), " ", ("lab-01", "where"), "=(", ("root", "user"), ") ", ("/usr/bin/systemctl restart nginx", "what")),
    (("bob", "who"), " may ", ("restart nginx, nothing else", "what"), ", ", ("only on lab-01", "where"), ", ", ("as root", "user")),
  ),
  (
    (("carol", "who"), " ", ("ALL", "where"), "=(", ("www-data", "user"), ") ", ("/usr/bin/php", "what")),
    (("carol", "who"), " may run ", ("php", "what"), ", ", ("on any computer", "where"), ", ", ("only as www-data, not as root", "user")),
  ),
)

#slide[
  == Rules in Plain English
  🗣️ every rule is a sentence

  #set text(size: 0.9em)
  #for (i, (r, say)) in examples.enumerate() {
    uncover(str(i + 1) + "-")[
      #block(
        width: 100%,
        inset: (x: 0.8em, y: 0.5em),
        radius: 0.3em,
        fill: luma(245),
        below: 0.4em,
      )[
        #text(size: 1.05em, rule(r)) \
        #v(0.1em)
        #text(size: 0.9em)[#arrow #h(0.3em) #colored(say)]
      ]
    ]
  }

  #uncover(str(examples.len() + 1) + "-")[
    #text(size: 0.9em)[💡 `NOPASSWD:` in front of the commands: `sudo` does not ask for the password \
      ⚖️ when several rules match, the *last* one wins]
  ]
]

// the rules used by the quiz, as colored pieces
#let quiz-rules = (
  (("%sudo", "who"), " ", ("ALL", "where"), "=(", ("ALL", "user"), ":", ("ALL", "group"), ") ", ("ALL", "what")),
  (("alice", "who"), " ", ("ALL", "where"), "=(", ("root", "user"), ") ", ("NOPASSWD:", "pass"), " ", ("/usr/bin/apt", "what")),
  (("bob", "who"), " ", ("lab-01", "where"), "=(", ("root", "user"), ") ", ("/usr/bin/systemctl restart nginx", "what")),
  (("carol", "who"), " ", ("ALL", "where"), "=(", ("www-data", "user"), ") ", ("/usr/bin/php", "what")),
)

// a rule: dimmed, or colored with the parts in `bad` marked as not matching
#let quiz-rule(pieces, active: true, bad: ()) = {
  let out = ()
  for p in pieces {
    if type(p) == str {
      out.push(text(fill: if active { luma(110) } else { luma(195) }, p))
    } else {
      let (t, key) = p
      if not active {
        out.push(text(fill: luma(195), t))
      } else if key in bad {
        out.push(highlight(fill: bad-color.lighten(85%), radius: 2pt, extent: 2pt, text(fill: bad-color, weight: "bold", strike(t))))
      } else {
        out.push(text(fill: rule-colors.at(key), weight: "bold", t))
      }
    }
  }
  text(font: mono, out.join())
}

// the rules, `current` (a rule index) highlighted, none - all of them colored
#let quiz-file(current: none, bad: ()) = block(
  width: 100%,
  inset: (x: 0.6em, y: 0.5em),
  radius: 0.3em,
  fill: luma(245),
  {
    set par(leading: 0.5em)
    for (i, r) in quiz-rules.enumerate() {
      let on = current == none or current == i
      box(
        width: 100%,
        inset: (x: 0.4em, y: 0.2em),
        radius: 0.25em,
        fill: if current == i { white } else { none },
        [#box(width: 1.4em, if current == i [👉] else { text(fill: luma(150), size: 0.85em, str(i + 1)) }) #quiz-rule(r, active: on, bad: if current == i { bad } else { () })],
      )
      linebreak()
    }
  },
)

// one attempt: the prompt and the command, the rule it is checked against,
// and the parts of the rule: (key, question, what alice gives, the rule, ok)
#let attempts = (
  (
    prompt: "alice@laptop:~$ sudo apt install htop",
    output: "Reading package lists... Done",
    rule: 1,
    checks: (
      ("who", [who], [`alice`], [`alice`], true),
      ("where", [where], [`laptop`], [`ALL`], true),
      ("user", [as whom], [`root`], [`(root)`], true),
      ("what", [what], [`/usr/bin/apt install htop`], [`/usr/bin/apt`, any arguments], true),
      ("pass", [password], [], [`NOPASSWD:`], true),
    ),
    ok: true,
    why: [rules 1 and 2 match, the *last* one wins: `apt` runs as `root`, *no password* is asked],
  ),
  (
    prompt: "alice@laptop:~$ sudo nano /etc/hosts",
    output: "[sudo] password for alice:",
    rule: 0,
    checks: (
      ("who", [who], [`alice`, a member of `sudo`], [`%sudo`], true),
      ("where", [where], [`laptop`], [`ALL`], true),
      ("user", [as whom], [`root`], [`(ALL:ALL)`], true),
      ("what", [what], [`/usr/bin/nano /etc/hosts`], [`ALL`], true),
    ),
    ok: true,
    why: [rule 2 is only for `apt`, but rule 1 matches: `nano` runs as `root` after the password of `alice`],
  ),
  (
    prompt: "bob@lab-01:~$ sudo systemctl restart nginx",
    output: "[sudo] password for bob:",
    rule: 2,
    checks: (
      ("who", [who], [`bob`], [`bob`], true),
      ("where", [where], [`lab-01`], [`lab-01`], true),
      ("user", [as whom], [`root`], [`(root)`], true),
      ("what", [what], [`/usr/bin/systemctl restart nginx`], [*exactly* the same], true),
    ),
    ok: true,
    why: [rule 3 matches: `nginx` is restarted after the password of `bob`],
  ),
  (
    prompt: "bob@lab-01:~$ sudo systemctl stop nginx",
    output: "[sudo] password for bob:\nSorry, user bob is not allowed to execute '/usr/bin/systemctl stop nginx' as root on lab-01.",
    rule: 2,
    checks: (
      ("who", [who], [`bob`], [`bob`], true),
      ("where", [where], [`lab-01`], [`lab-01`], true),
      ("user", [as whom], [`root`], [`(root)`], true),
      ("what", [what], [`/usr/bin/systemctl stop nginx`], [`/usr/bin/systemctl restart nginx`], false),
    ),
    ok: false,
    why: [the rule allows *only* `restart nginx`, not other arguments],
  ),
  (
    prompt: "bob@lab-02:~$ sudo systemctl restart nginx",
    output: "[sudo] password for bob:\nSorry, user bob is not allowed to execute '/usr/bin/systemctl restart nginx' as root on lab-02.",
    rule: 2,
    checks: (
      ("who", [who], [`bob`], [`bob`], true),
      ("where", [where], [`lab-02`], [`lab-01`], false),
      ("user", [as whom], [`root`], [`(root)`], true),
      ("what", [what], [`/usr/bin/systemctl restart nginx`], [*exactly* the same], true),
    ),
    ok: false,
    why: [the same command, but rule 3 is *only* for the computer `lab-01`],
  ),
  (
    prompt: "carol@laptop:~$ sudo -u www-data php run.php",
    output: "[sudo] password for carol:",
    rule: 3,
    checks: (
      ("who", [who], [`carol`], [`carol`], true),
      ("where", [where], [`laptop`], [`ALL`], true),
      ("user", [as whom], [`www-data` (`-u`)], [`(www-data)`], true),
      ("what", [what], [`/usr/bin/php run.php`], [`/usr/bin/php`, any arguments], true),
    ),
    ok: true,
    why: [rule 4 matches: `php` runs as `www-data`, *not* as `root`],
  ),
  (
    prompt: "carol@laptop:~$ sudo php run.php",
    output: "[sudo] password for carol:\nSorry, user carol is not allowed to execute '/usr/bin/php run.php' as root on laptop.",
    rule: 3,
    checks: (
      ("who", [who], [`carol`], [`carol`], true),
      ("where", [where], [`laptop`], [`ALL`], true),
      ("user", [as whom], [`root` (no `-u`)], [`(www-data)`], false),
      ("what", [what], [`/usr/bin/php run.php`], [`/usr/bin/php`, any arguments], true),
    ),
    ok: false,
    why: [without `-u`, `sudo` runs as `root`: rule 4 allows only `www-data`],
  ),
)

// the command and what the terminal prints: the error of `sudo` in red
#let attempt-term(a) = {
  show raw.line: line => if line.number == 1 {
    prompt-term-line(line.text)
  } else if line.text.starts-with("Sorry") {
    text(fill: bad-color, weight: "bold", line.text)
  } else {
    text(fill: luma(100), line.text)
  }
  raw(a.prompt + "\n" + a.output, block: true)
}

// the emoji of every part of a rule
#let part-icons = (who: "👤", where: "🖥️", user: "🎭", group: "👥", what: "⚙️", pass: "🔑")

// the comparison of an attempt with its rule, part by part
#let checks-table(checks) = table(
  columns: (auto, 1.2fr, 1fr, auto),
  inset: (x: 0.45em, y: 0.28em),
  align: horizon,
  stroke: (x, y) => if y > 1 { (top: 0.4pt + luma(225)) } else { none },
  table.header(
    [], text(size: 0.85em, fill: luma(130))[💻 the command], text(size: 0.85em, fill: luma(130))[📜 the rule], [],
  ),
  ..checks.map(((key, question, given, wanted, ok)) => (
    [#part-icons.at(key) #text(fill: rule-colors.at(key), question)],
    given,
    text(fill: if ok { rule-colors.at(key) } else { bad-color }, wanted),
    text(size: 0.9em, if ok [✅] else [❌]),
  )).flatten(),
)

// the result of an attempt: an emoji, a word and the reason
#let result-note(ok, why) = {
  let color = if ok { ok-color } else { bad-color }
  block(inset: (left: 0.8em), stroke: (left: 1.5pt + color))[
    #text(size: 1.4em)[#if ok [✅] else [🚫]] #h(0.2em) #text(size: 1.2em, weight: "bold", fill: color)[#if ok [allowed] else [refused]]
    #v(0.1em)
    #why
  ]
}

#slide[
  == Will `sudo` Allow It?
  🧩 `alice` is in `sudo`, `bob` and `carol` are not

  #set text(size: 0.8em)
  #only(1)[
    #set text(size: 1.15em)
    #quiz-file()
    #v(0.4em)
    - 👤 `alice` is a member of the group `sudo`, `bob` and `carol` are not
    - 🖥️ `laptop`, `lab-01` and `lab-02` all have this same `/etc/sudoers`
    #v(0.4em)
    🤔 for every command: which rule matches, and does *every part* of it match?
  ]
  #for (i, a) in attempts.enumerate() {
    let bad = a.checks.filter(c => not c.at(4)).map(c => c.at(0))
    only(i + 2)[
      #quiz-file(current: a.rule, bad: bad)
      #v(-0.2em)
      #attempt-term(a)
      #v(-0.3em)
      #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
        #checks-table(a.checks)
      ][
        #v(0.8em)
        #result-note(a.ok, a.why)
      ]
    ]
  }
]

// what happens after a typo in /etc/sudoers: (icon, text), one per step
#let broken-chain = (
  ("✏️", [edited with `nano` \ a *typo* is saved]),
  ("💥", [`sudo` reads the file \ it *cannot* understand it]),
  ("🚫", [`sudo` refuses to run \ for *everyone*]),
  ("🔒", [`root` has no password \ *nobody* can fix the file]),
)

#slide[
  == Why `visudo`?
  ⚠️ `/etc/sudoers` must never be edited with a normal editor

  #block(
    width: 100%,
    inset: (x: 1.2em, y: 0.9em),
    radius: 0.5em,
    fill: rgb("ffebee"),
    stroke: 1.5pt + bad-color,
  )[
    #set text(size: 1.1em)
    #text(size: 1.1em, weight: "bold", fill: bad-color)[one mistake in `/etc/sudoers` can lock *everybody* out of `root`]
    #v(0.5em)
    #grid(
      columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr),
      column-gutter: 0.5em,
      align: center + horizon,
      ..broken-chain.enumerate().map(((i, (icon, body))) => {
        let cell = uncover(str(i + 1) + "-")[#text(size: 2.4em, icon) \ #v(0.2em) #text(size: 0.9em, body)]
        if i == 0 { (cell,) } else { (uncover(str(i + 1) + "-", draw-arrow(length: 1.6em, color: bad-color)), cell) }
      }).flatten(),
    )
  ]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("3-")[
      #set text(size: 0.8em)
      ```terminal
      $ sudo whoami
      sudo: parse error in /etc/sudoers near line 25
      sudo: no valid sudoers sources found, quitting
      ```
    ]
  ][
    #uncover("5-")[
      #card(icon: "✅", title: [`visudo` checks the file *before* saving it], color: ok-color)[
        a broken file never reaches `/etc/sudoers`
      ]
    ]
  ]
]

#slide[
  == `visudo`
  ✏️ the only safe way to edit the `sudoers` file

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 3, 4, 7), full: false)[```terminal
    $ sudo visudo
    /etc/sudoers:25:12: syntax error
    What now? e
    $ sudo visudo -f /etc/sudoers.d/students
    $ sudo visudo -c
    /etc/sudoers: parsed OK
    /etc/sudoers.d/students: parsed OK
    ```]
  ][
    #only(1)[- opens a *copy* of `/etc/sudoers` in an editor and *locks* the file]
    #only(2)[- before saving, it *checks* the file: on an error, #kbd("e") edits again, #kbd("x") throws the changes away]
    #only(3)[- `-f` edits another file, e.g. a new rule in `/etc/sudoers.d/`]
    #only(4)[- `-c` only checks all the files]

  ]
]
