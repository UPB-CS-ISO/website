#import "/src/slides.typ": *
#import "common.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#slide[
  = Salted Hashes #text(size: 10pt, weight: "regular")[\ _why every password gets a salt_]
]

#let salt-text(body) = text(fill: hl, weight: "bold", body)
#let stored-text(body) = text(fill: accent, weight: "bold", body)

// a line of a file with the hash of a password: user:hash:rest…
#let hash-line(user, rest, hash) = [#user:#box(fill: rgb("ffebee"), outset: 2pt, radius: 2pt, text(fill: bad-color, weight: "bold", hash)):#rest:…]

// a file with a short note under it: who can read it
#let shadow-file(path, note, icon: "📄", lines) = align(center)[
  #db-file(path, none, none, none, icon: icon, lines)
  #v(-0.4em)
  #text(size: 0.85em, fill: luma(110), note)
]

// A table of hashes computed in advance: without salt, a stolen hash is
// only looked up in it; with salt, it is not there.
// `step` - 1: the table, 2: the hashes without salt, 3: the hashes with salt,
// the lookup finds a row that is not the password, 4: the password is wrong
#let table-rows = (
  ("e10adc39…", "123456"),
  ("5f4dcc3b…", "password"),
  ("d8578edf…", "qwerty"),
  ("32250170…", "pass123"),
  ("9mQeT4bW…", "dragon"),
)

#let lookup-drawing(step) = {
  let found = step == 2
  // with salt: a false hit
  let false-hit = step >= 3
  let table = db-file("hashes.txt", none, none, none, icon: "📖")[
    #for (hash, password) in table-rows {
      let match = (found and password == "pass123") or (false-hit and password == "dragon")
      let row = [#hash #text(fill: luma(130))[→] #text(weight: "bold", password)]
      if match {
        box(fill: hl-bg, outset: 2pt, radius: 2pt, text(fill: hl, weight: "bold", row))
      } else {
        row
      }
      linebreak()
    }
    #text(fill: luma(130))[… millions of passwords]
  ]
  // the stolen lines, the hashes in red
  let stolen-file(step) = if step <= 2 {
    shadow-file("/etc/shadow", [🧂 without salt], icon: "🔐")[
      #hash-line("alice", "20737", "32250170…") \
      #hash-line("bob", "20737", "32250170…")
    ]
  } else {
    shadow-file("/etc/shadow", [🧂 with salt], icon: "🔐")[
      #hash-line("alice", "20737", [#text(fill: luma(110), weight: "regular")[\$y\$j9T\$]#salt-text[Xr3a…]#text(fill: luma(110), weight: "regular")[\$]9mQe…]) \
      #hash-line("bob", "20737", [#text(fill: luma(110), weight: "regular")[\$y\$j9T\$]#salt-text[Lp0w…]#text(fill: luma(110), weight: "regular")[\$]Tz7k…])
    ]
  }
  // red: the attacker found the password, green: the password is safe
  let outcome(color, fill, body) = box(inset: (x: 0.6em, y: 0.3em), radius: 0.3em, fill: fill, stroke: 1.2pt + color, text(size: 0.85em, fill: color, weight: "bold", body))
  let result = if step <= 2 {
    outcome(bad-color, rgb("ffebee"), [🔓 `alice` and `bob`: `pass123`, nothing hashed])
  } else if step == 3 {
    outcome(hl, hl-bg, [🔎 `alice`: `dragon`?])
  } else {
    outcome(ok-color, rgb("e8f5e9"), [🛡️ `dragon`: wrong password])
  }
  let on = step >= 2
  // as wide as the widest file, so that the drawing does not move
  let stolen = context box(width: calc.max(..(2, 3).map(i => measure(stolen-file(i)).width)), stolen-file(step))
  let attacked = align(center)[
    #stolen
    #v(0.6em)
    #result
  ]

  set text(size: 0.85em)
  diagram(
    spacing: 7em,
    thing((0, 0), align(center)[
      #table
      #v(-0.4em)
      #text(size: 0.85em, fill: luma(110))[⏱️ computed once, *before* the attack]
    ]),
    thing((1, 0), if on { attacked } else { hide(attacked) }),
    edge((1, 0), (0, 0), arrow-marks, stroke: arrow-thickness + if on { hl } else { white }, label: if on { text(size: 0.9em, fill: hl)[🔎 look up #if false-hit [`9mQe…`]] }, label-side: right),
  )
}

#slide[
  == Why the Salt?
  📖 a table of hashes, computed in advance

  #align(center)[
    #only(1, lookup-drawing(1))
    #only(2, lookup-drawing(2))
    #only(3, lookup-drawing(3))
    #only("4-", lookup-drawing(4))
  ]
  #v(0.3em)

  #set text(size: 0.9em)
  #only("1-2")[
    - an attacker hashes millions of common passwords *once* and keeps a table: hash #arrow password
    #uncover(2)[#block[- without salt, a stolen hash is only *looked up*: no hashing, every user with the same password at once]]
  ]
  #only(3)[
    - with salt, the attacker looks up `alice`'s hash `9mQe…` and the table gives `dragon`
  ]
  #only(4)[
    #card(icon: "🧂", title: [the table was computed *without* the salt: its password is wrong], color: ok-color)[
      #let hashed(salt, password) = [hash(#if salt != none [#salt-text(salt) + ]#password)]
      #grid(
        columns: 3,
        column-gutter: 1em,
        row-gutter: 0.45em,
        [📖 the table], hashed(none, `dragon`), [\= `9mQe…`],
        [⌨️ `login`], hashed(`Xr3a…`, `dragon`), [\= #text(fill: bad-color, weight: "bold")[`Zk8q…`] ≠ `9mQe…` ❌],
      )
      #v(0.2em)
      `login` always adds the salt: a new table would be needed for *every salt*
    ]
  ]
]
