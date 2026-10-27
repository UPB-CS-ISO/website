#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Prompt #text(size: 10pt, weight: "regular")[\ _who am I?_]
]

#slide[
  == Bibliography
  for this section

  + #uso-book
    - Chapter 5 - _Utilizatori_
    - Chapter 7 - _Interfața în linia de comandă_
]

// the parts of the prompt: (escape, meaning, value for alice, value for root, color)
#let prompt-parts = (
  ("\\u", [the *user*], "alice", "root", rgb("00838f")),
  ("\\h", [the *host* name], "laptop", "laptop", rgb("6a1b9a")),
  ("\\w", [the current directory], "~/Movies", "/etc", rgb("2e7d46")),
  ("\\$", [`$` for users, `#` for UID `0`], "$", "#", bad-color),
)

// the prompt, with the part `current` (an index, none - all) in its color
#let prompt-line(values, current: none) = {
  let seps = ("@", ":", "", " ")
  let out = ()
  for (i, part) in prompt-parts.enumerate() {
    let color = part.at(4)
    let on = current == none or current == i
    out.push(text(fill: if on { color } else { dim }, weight: "bold", values.at(i)))
    out.push(text(fill: if current == none { black } else { dim }, seps.at(i)))
  }
  text(font: mono, size: 1.3em, out.join())
}

#slide[
  == How the Prompt Shows the User
  🐚 `bash` builds the prompt from the variable `PS1`

  #let n = prompt-parts.len()
  #set smartquote(enabled: false)
  #align(center)[
    #for i in range(n + 2) {
      let current = if i == 0 or i > n { none } else { i - 1 }
      only(i + 1)[
        #text(font: mono, size: 1.1em)[PS1='#for (j, p) in prompt-parts.enumerate() {
          let sep = ("@", ":", "", " ").at(j)
          text(fill: if current == none or current == j { p.at(4) } else { dim }, weight: "bold", p.at(0))
          sep
        }']
        #v(0.6em)
        #prompt-line(prompt-parts.map(p => p.at(2)), current: current)
        #v(0.3em)
        #if i == n + 1 { prompt-line(prompt-parts.map(p => p.at(3))) } else { hide(prompt-line(prompt-parts.map(p => p.at(3)))) }
      ]
    }
  ]

  #v(0.5em)
  #table(
    columns: (auto, 1fr, auto, auto),
    table.header([Escape], [Meaning], [`alice`], [`root`]),
    ..prompt-parts.enumerate().map(((i, (esc, meaning, a, r, color))) => (
      text(font: mono, fill: color, weight: "bold", esc), meaning, raw(a), raw(r),
    ).map(c => uncover(str(i + 2) + "-", c))).flatten(),
  )
]

#slide[
  == Do Not Trust the Prompt
  🎭 the prompt is just *text*, any user can change it

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #prompt-term(reveal: (1, 3, 5, 7))[```
    alice@laptop:~$ PS1='root@laptop:~# '
    root@laptop:~# whoami
    alice
    root@laptop:~# id
    uid=1000(alice) gid=1000(alice) groups=1000(alice)
    root@laptop:~# cat /etc/shadow
    cat: /etc/shadow: Permission denied
    ```]
  ][
    #only(1)[- `alice` sets her prompt to look like `root`]
    #only(2)[- `whoami` asks the *kernel*: the shell runs as `alice`]
    #only(3)[- `id` shows the whole label: UID, GID and groups]
    #only(4)[- the kernel still checks the *UID*: `alice` is not `root`]

    #uncover("2-")[
      #card(icon: "✅", title: [ask the kernel], color: ok-color)[
        `whoami` and `id` show the *real* label of the process
      ]
    ]
  ]
]
