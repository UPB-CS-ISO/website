#import "/src/slides.typ": *
#import "common.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#slide[
  = Local Password Storage #text(size: 10pt, weight: "regular")[\ _hashes, salt and_ `/etc/shadow`]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.3 - _The /etc/shadow File_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

#slide[
  == The Passwords Database
  🔐 `/etc/shadow`, one line for every user of `/etc/passwd`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #highlight-code(("all", (1,), lines-range(2, 4), lines-range(5, 6), "all"))[```
    root:!:20737:0:99999:7:::
    daemon:*:20737:0:99999:7:::
    www-data:*:20737:0:99999:7:::
    nobody:*:20737:0:99999:7:::
    alice:$y$j9T$Xr3a…$9mQe…:20737:0:99999:7:::
    bob:$y$j9T$Lp0w…$Tz7k…:20737:0:99999:7:::
    ```]
    #align(center, text(size: 0.9em, style: "italic")[`/etc/shadow` (shortened)])
    #uncover("5-")[
      ```terminal
      $ getent shadow alice   # nothing, alice may not read it
      ```
    ]
  ][
    #set text(size: 0.9em)
    #only(1)[
      #card(icon: "🔐", title: [`/etc/shadow`])[
        - the same users as `/etc/passwd`, in the same order
        - the *hash* of the password and when it expires
        - the fields are separated by `:`
      ]
    ]
    #only(2)[
      #card(icon: "👑", title: [`root`], color: bad-color)[
        `!` - *locked*: no password works, use `sudo` instead
      ]
    ]
    #only(3)[
      #card(icon: "⚙️", title: [system users], color: luma(110))[
        `*` - they *never* had a password, nobody can log in as them
      ]
    ]
    #only(4)[
      #card(icon: "🧑", title: [regular users])[
        the *hash* of the password, never the password itself
      ]
    ]
    #only(5)[
      #card(icon: "🔒", title: [only `root` can read it], color: hl)[
        unlike `/etc/passwd`, that everyone reads
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
      the line of `alice`
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

// the parts of the line of `alice` in /etc/shadow
#let salt-text(body) = text(fill: hl, weight: "bold", body)
#let stored-text(body) = text(fill: accent, weight: "bold", body)

// the colors of the fields of a password hash
#let algo-color = rgb("6a1b9a")
#let param-color = rgb("00796b")

// the line of `alice` in /etc/shadow, in parts: (text, color of the field)
#let hash-parts = (
  ("alice:", none),
  ("$", none), ("y", algo-color),
  ("$", none), ("j9T", param-color),
  ("$", none), ("Xr3aB7tPq2LkV9sD1fGh0J", hl),
  ("$", none), ("9mQeT4bW1sZxH8cDr5Ny2kLpA7uVq3oEw6iFj0gHt1M", accent),
  (":20737:…", none),
)

#let hash-part((body, color)) = if color == none {
  text(fill: luma(90), body)
} else {
  box(fill: color.lighten(88%), outset: (y: 2pt), radius: 2pt, text(fill: color, weight: "bold", body))
}

// The line of `alice` with a dotted line from every field of the password
// hash to its name. The positions of the fields are measured, so that every
// dotted line starts right under its field.
// `step` - the names shown so far: the hash (1), the salt (2), the algorithm
// and the parameters (5), the others keep their place
// (the slide calls it with 1, 2 and then 5)
#let hash-anatomy(step) = {
  set text(size: 0.75em)
  context {
    let em = 1em.to-absolute()
    let line = text(font: mono, hash-parts.map(hash-part).join())
    let size = measure(line)
    let center(i) = measure(text(font: mono, hash-parts.slice(0, i).map(hash-part).join())).width + measure(text(font: mono, hash-part(hash-parts.at(i)))).width / 2
    let (algo-x, param-x, salt-x, hash-x) = (2, 4, 6, 8).map(center)
    // fletcher: y grows upwards, the names are below the line
    let bottom = -size.height / 2 - 0.5 * em
    let y = bottom - 4 * em
    // the names, apart from each other
    let gap = 11 * em
    let param-box = calc.max(param-x, gap * 0.75)
    let algo-box = param-box - gap
    let salt-box = calc.max(salt-x, param-box + gap)
    let hash-box = calc.max(hash-x, salt-box + gap)
    let names = (
      (algo-x, algo-box, "⚙️", [algorithm], [`y` - _yescrypt_], algo-color, 5),
      (param-x, param-box, "🎚️", [parameters], [`j9T` - the cost], param-color, 5),
      (salt-x, salt-box, "🧂", [salt], [random, for every user], hl, 2),
      (hash-x, hash-box, "🔒", [hash], [of the salt + the password], accent, 1),
    )
    diagram(
      node((size.width / 2, size.height / 2 + 1.8 * em), [🔐 #text(font: mono, weight: "bold")[/etc/shadow]], inset: 0pt),
      node((size.width / 2, 0pt), line, stroke: 0.8pt + luma(150), corner-radius: 0.3em, inset: 0.5em, shape: rect),
      ..names.map(((x, box-x, icon, title, body, color, from)) => {
        let on = step >= from
        let name = text(size: 1.15em)[#icon #text(fill: color, weight: "bold", title) \ #text(size: 0.85em, fill: luma(90), body)]
        (
          node((box-x, y), if on { name } else { hide(name) }, stroke: if on { 1pt + color } else { none }, corner-radius: 0.3em, inset: 0.5em, shape: rect),
          // starts under the field, not at the center of the line
          edge((x, bottom), (box-x, y), arrow-marks, stroke: (paint: if on { color } else { white }, thickness: arrow-thickness, dash: "dotted"), snap-to: (none, auto)),
        )
      }).flatten(),
    )
  }
}

#slide[
  == Storing a Password
  🧂 a hash, with salt, in `/etc/shadow`

  #align(center)[
    #for step in range(1, 3) {
      only(step, hash-anatomy(step))
    }
    #only("3-", hash-anatomy(5))
  ]
  #v(0.5em)

  #set text(size: 0.9em)
  - the password is never stored, only its *hash*: a *one way* function, it cannot be turned back into the password
  #uncover("2-")[#block[- a random *salt* is added to the password before hashing: two users with the same password get *different* hashes]]
  #uncover("3-")[#block[- the *algorithm* and its *parameters* are stored too: they are needed to check the password]]
]

// Checking a password: the algorithm, the parameters and the salt from
// /etc/shadow and the typed password go into the hash function, the result
// is compared with the stored hash.
// `step` - the parts drawn so far (1 - 4), the others keep their place
#let check-drawing(step, typed, computed, ok) = {
  let result-color = if ok { accent } else { bad-color }
  // a part of the drawing, shown from step `from`
  let part(pos, from, body, stroke: 0.8pt + luma(150), fill: white, ..args) = {
    let on = step >= from
    node(pos, if on { body } else { hide(body) }, stroke: if on { stroke } else { none }, fill: if on { fill } else { none }, corner-radius: 0.3em, inset: 0.5em, shape: rect, ..args)
  }
  let arrow(from-pos, to-pos, from, color: arrow-gray, ..args) = {
    let on = step >= from
    edge(from-pos, to-pos, arrow-marks, stroke: arrow-thickness + if on { color } else { white }, ..args)
  }
  let value(icon, title, body) = [#icon #text(size: 0.85em, fill: luma(110), title) \ #text(font: mono, weight: "bold", body)]

  set text(size: 0.72em)
  context {
    let em = 1em.to-absolute()
    // where the fields of the line are
    let line = text(font: mono, hash-parts.map(hash-part).join())
    let size = measure(line)
    let center(i) = measure(text(font: mono, hash-parts.slice(0, i).map(hash-part).join())).width + measure(text(font: mono, hash-part(hash-parts.at(i)))).width / 2
    let (algo-x, param-x, salt-x, hash-x) = (2, 4, 6, 8).map(center)
    // fletcher: y grows upwards, everything is below the line
    let bottom = -size.height / 2 - 0.5 * em
    let y1 = bottom - 4 * em
    let y2 = y1 - 5.2 * em
    let y3 = y2 - 4.6 * em
    let settings-x = (algo-x + param-x) / 2
    let fn-x = salt-x
    let typed-x = fn-x - 12 * em
    // an arrow from a field of the line, not from the center of the line
    let from-field(x, to, color) = arrow((x, bottom), to, 1, color: color, snap-to: (none, auto))

    diagram(
      // step 1: the line of alice, split in its fields
      node((size.width / 2, size.height / 2 + 1.6 * em), [🔐 #text(font: mono, weight: "bold")[/etc/shadow]], inset: 0pt),
      part((size.width / 2, 0pt), 1, line),
      part((settings-x, y1), 1, value("⚙️", [algorithm, parameters], [#text(fill: algo-color)[y] #text(fill: param-color)[j9T]]), stroke: 1pt + param-color),
      part((salt-x, y1), 1, value("🧂", [salt], salt-text[Xr3aB7tP…]), stroke: 1pt + hl),
      part((hash-x, y1), 1, value("🔒", [stored hash], stored-text[9mQeT4bW…]), stroke: 1pt + accent),
      from-field(settings-x, (settings-x, y1), param-color),
      from-field(salt-x, (salt-x, y1), hl),
      from-field(hash-x, (hash-x, y1), accent),
      // step 2: the typed password, hashed the same way
      part((typed-x, y2), 2, value("⌨️", [typed by the user], typed)),
      part((fn-x, y2), 2, text(fill: white)[🔢 *hash* (_yescrypt_)], stroke: none, fill: accent),
      arrow((typed-x, y2), (fn-x, y2), 2),
      arrow((settings-x, y1), (fn-x, y2), 2, color: param-color),
      arrow((salt-x, y1), (fn-x, y2), 2, color: hl),
      // step 3: a new hash
      part((fn-x, y3), 3, value("🧮", [computed hash], text(fill: result-color, computed)), stroke: 1pt + result-color),
      arrow((fn-x, y2), (fn-x, y3), 3, color: result-color),
      // step 4: compare the two hashes
      part((hash-x, y3), 4, text(size: 1.4em, weight: "bold", fill: result-color)[#if ok [=] else [≠]], stroke: 1.5pt + result-color, shape: fletcher.shapes.circle),
      arrow((fn-x, y3), (hash-x, y3), 4, color: result-color),
      arrow((hash-x, y1), (hash-x, y3), 4, color: accent),
      part((hash-x + 9 * em, y3), 4, verdict(ok, if ok [correct password] else [wrong password]), stroke: none, fill: none, inset: 0pt),
      arrow((hash-x, y3), (hash-x + 9 * em, y3), 4, color: result-color),
    )
  }
}

#slide[
  == Checking a Password
  🔍 the hash cannot be reversed, so the password is hashed again and compared

  #align(center)[
    #for step in range(1, 5) {
      only(step, check-drawing(step, "pass123", "9mQeT4bW…", true))
    }
    #only("5-", check-drawing(4, "pass124", "Zk8qP0aN…", false))
  ]

  #v(0.5em)
  #set text(size: 0.9em)
  #only(1)[1️⃣ `login` reads the line of `alice` from `/etc/shadow`: the #text(fill: algo-color, weight: "bold")[algorithm], the #text(fill: param-color, weight: "bold")[parameters], the #salt-text[salt] and the #stored-text[stored hash]]
  #only(2)[2️⃣ the typed password is hashed with the same #text(fill: algo-color, weight: "bold")[algorithm], #text(fill: param-color, weight: "bold")[parameters] and #salt-text[salt]]
  #only(3)[3️⃣ the result is a new hash, computed now]
  #only(4)[4️⃣ the same as the #stored-text[stored hash]: the password is correct, without ever storing it]
  #only("5-")[5️⃣ one wrong letter gives a completely different hash: the password is wrong]
]

// a line of a file with the hash of a password: user:hash:rest…
#let hash-line(user, rest, hash) = [#user:#box(fill: rgb("ffebee"), outset: 2pt, radius: 2pt, text(fill: bad-color, weight: "bold", hash)):#rest:…]

// the processes below, all as wide as the widest one
#let shadow-procs = (("whoami", "alice", 1000), ("cat", "bob", 1001), ("login", "root", 0))
#let proc(..args) = context {
  let w = calc.max(..shadow-procs.map(p => measure(proc-box(..p)).width))
  proc-box(..args, width: w)
}

// a file with a short note under it: who can read it
#let shadow-file(path, note, icon: "📄", lines) = align(center)[
  #db-file(path, none, none, none, icon: icon, lines)
  #v(-0.4em)
  #text(size: 0.85em, fill: luma(110), note)
]

// `on` - false: the arrow keeps its place, but it is not drawn yet
#let read-arrow(from, to, label, color: arrow-gray, on: true) = edge(from, to, arrow-marks, stroke: arrow-thickness + if on { color } else { white }, label: if on { text(fill: color, size: 0.9em, label) }, label-side: left)

// before: the hashes are in /etc/passwd, everyone can read them
#let before-drawing(step) = {
  set text(size: 0.75em)
  diagram(
    spacing: (7em, 1.6em),
    thing((0, 0), proc("whoami", "alice", 1000)),
    thing((1, 0.5), shadow-file("/etc/passwd", [🌍 everyone can read it])[
      #hash-line("alice", "1000:1000", "$y$j9T$Xr3a…") \
      #hash-line("bob", "1001:1001", "$y$j9T$Lp0w…")
    ]),
    read-arrow((0, 0), (1, 0.5), [`getpwuid()`]),
    // step 2, the other ones keep their place
    thing((0, 1), if step >= 2 { proc("cat", "bob", 1001) } else { hide(proc("cat", "bob", 1001)) }),
    read-arrow((0, 1), (1, 0.5), [copies the hashes], color: bad-color, on: step >= 2),
  )
}

// after: /etc/passwd has `x`, the hashes are in /etc/shadow
#let after-drawing(step) = {
  set text(size: 0.75em)
  diagram(
    spacing: (7em, 1.4em),
    thing((0, 0), proc("whoami", "alice", 1000)),
    thing((1, 0), shadow-file("/etc/passwd", [🌍 everyone can read it])[
      alice:#text(fill: ok-color, weight: "bold")[x]:1000:1000:… \
      bob:#text(fill: ok-color, weight: "bold")[x]:1001:1001:…
    ]),
    read-arrow((0, 0), (1, 0), [`getpwuid()`], color: ok-color),
    thing((0, 1), proc("cat", "bob", 1001)),
    thing((1, 1.5), shadow-file("/etc/shadow", [🔒 only `root` can read it], icon: "🔐")[
      #hash-line("alice", "20737", "$y$j9T$Xr3a…") \
      #hash-line("bob", "20737", "$y$j9T$Lp0w…")
    ]),
    // stopped at the file, with a cross
    edge((0, 1), (1, 1.5), marks: (none, (inherit: "x", size: 4.5, pos: 0.85)), stroke: arrow-thickness + bad-color, label: text(fill: bad-color, size: 0.9em)[denied], label-side: left),
    // step 5, the other ones keep their place
    thing((0, 2), if step >= 5 { proc("login", "root", 0) } else { hide(proc("login", "root", 0)) }),
    read-arrow((0, 2), (1, 1.5), [✅ checks], color: ok-color, on: step >= 5),
  )
}

#slide[
  == Why `/etc/shadow`?
  🔐 the hashes cannot stay in a file that everyone reads

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - `/etc/passwd` must be readable by *everyone*, for `getpwuid()`
    #uncover("2-")[#block[- in the past, the *hash* was in its second field, so anyone could copy it]]
    #uncover("3-")[#block[- the password check works for an attacker too: guess, hash, compare, *offline*]]
    #uncover("4-")[#block[- ✅ the hashes moved to `/etc/shadow`, `/etc/passwd` keeps only an `x`]]
    #uncover("5-")[#block[- only `root` reads it: `login`, `sudo` and `passwd` run as `root` to check the password]]
  ][
    #only(1, align(center, before-drawing(1)))
    #only("2-3")[
      #align(center, before-drawing(2))
      #v(0.6em)
      #set text(size: 0.75em)
      #uncover(3, card(icon: "🔨", title: [an offline attack, on `bob`'s own computer], color: bad-color)[
        hash(salt + "123456") = the stolen hash? ❌ \
        hash(salt + "password") = the stolen hash? ❌ \
        hash(salt + "pass123") = the stolen hash? ✅ \
        millions of tries per second: no log, no delay, no one sees it
      ])
    ]
    #only(4, align(center, after-drawing(4)))
    #only("5-", align(center, after-drawing(5)))
  ]
]
