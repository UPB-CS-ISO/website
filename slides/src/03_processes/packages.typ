#import "/src/slides.typ": *
#import "streams.typ": draw-arrow, stream-accent, stream-mono, stream-changed, stream-changed-fill

#slide[
  = Installing Applications #text(size: 10pt, weight: "regular")[\ _App repositories_]
]

#slide[
  == Bibliography
  For this section

  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 3 - _Pachete software_
      - Section 3.1 - _Pachete software_
      - Section 3.2 - _Gestiunea pachetelor_
      - Section 3.3 - _Gestiunea pachetelor în Linux_
]

// the logos of the distributions, the same images as in lecture 01
#let distro-logo(name, height: 1em) = box(
  baseline: 15%,
  image("/src/01_intro/img/distributions/" + name + ".png", height: height),
)

// a card of the schematic: a colored header and a body;
// `on` draws the card in orange
#let card(title, width: 11em, on: false, body) = block(
  width: width,
  radius: 0.35em,
  clip: true,
  stroke: 1.5pt + if on { stream-changed } else { luma(150) },
  fill: white,
)[
  #block(width: 100%, fill: if on { stream-changed } else { stream-accent }, inset: (x: 0.6em, y: 0.4em), below: 0pt)[
    #text(fill: white, weight: "bold", title)
  ]
  #block(width: 100%, inset: 0.6em, above: 0pt, body)
]

// an arrow between two cards, with what happens on it
#let card-arrow(label, on: false) = {
  let c = if on { stream-changed } else { luma(130) }
  align(center)[
    #text(size: 0.7em, fill: c, weight: "bold", label) \
    #draw-arrow(length: 2.6em, color: c, thickness: 2pt)
  ]
}

// Packages drawn as a graph: an arrow goes from a package to a package
// it needs. Positions are in em, measured from the top left corner of a
// drawing of `size` (width, height).
#let graph-node-half = 0.6 // half of the height of a node

// a node of the graph, centered at `at` (x, y)
#let graph-node(name, at, size, on: false) = place(
  center + horizon,
  dx: (at.at(0) - size.at(0) / 2) * 1em,
  dy: (at.at(1) - size.at(1) / 2) * 1em,
  box(
    inset: (x: 0.45em, y: 0.3em),
    radius: 0.25em,
    fill: if on { stream-changed-fill } else { luma(242) },
    stroke: 1pt + if on { stream-changed } else { luma(175) },
    text(font: stream-mono, size: 0.8em, fill: if on { stream-changed } else { black }, name),
  ),
)

// an arrow from the bottom of the node at `a` to the top of the node at `b`;
// `dotted` draws the line of the arrow dotted
#let graph-edge(a, b, on: false, dotted: false) = {
  let c = if on { stream-changed } else { luma(150) }
  let (x1, y1) = (a.at(0), a.at(1) + graph-node-half)
  let (x2, y2) = (b.at(0), b.at(1) - graph-node-half)
  let (dx, dy) = (x2 - x1, y2 - y1)
  let len = calc.sqrt(dx * dx + dy * dy)
  let (ux, uy) = (dx / len, dy / len)
  let (head, half) = (0.45, 0.22)
  let (bx, by) = (x2 - ux * head, y2 - uy * head)
  let pt(x, y) = (x * 1em, y * 1em)
  let stroke = if dotted { (paint: c, thickness: 1.5pt, dash: "dotted") } else { 1.2pt + c }
  place(top + left, line(start: pt(x1, y1), end: pt(bx, by), stroke: stroke))
  place(top + left, polygon(
    fill: c,
    pt(x2, y2),
    pt(bx - uy * half, by + ux * half),
    pt(bx + uy * half, by - ux * half),
  ))
}

// a drawing for a graph: `nodes` are (name, (x, y), on),
// `edges` are (from, to, on), with the positions of the nodes;
// `dotted` draws all the arrows dotted
#let package-graph(size, nodes, edges, dotted: false) = box(width: size.at(0) * 1em, height: size.at(1) * 1em, {
  for (a, b, on) in edges { graph-edge(a, b, on: on, dotted: dotted) }
  for (name, at, on) in nodes { graph-node(name, at, size, on: on) }
})

// the repository: three applications and the packages they need;
// `on` - highlight `cowsay` and what it needs
#let repository-graph(on: false) = {
  let size = (12.4, 5.0)
  let (cowsay, git, firefox) = ((2.2, 0.8), (6.4, 0.8), (10.4, 0.8))
  let (perl, gtk3) = ((4.3, 4.2), (10.4, 4.2))
  package-graph(
    size,
    (("cowsay", cowsay, on), ("git", git, false), ("firefox", firefox, false), ("perl", perl, on), ("gtk3", gtk3, false)),
    ((cowsay, perl, on), (git, perl, false), (firefox, gtk3, false)),
  )
}

// what `cowsay` brings to the system: itself and what it needs
#let installed-graph = {
  let size = (8, 5.0)
  let (cowsay, perl) = ((4, 0.8), (4, 4.2))
  package-graph(size, (("cowsay", cowsay, true), ("perl", perl, true)), ((cowsay, perl, true),), dotted: true)
}

// Where an application comes from: the repository of the distribution,
// the package manager that downloads it, the system it is installed on.
// `step` - 1: a package, 2: the repository, 3: the package manager installs it
#let repository-flow(step) = {
  let mono(s) = text(font: stream-mono, size: 0.85em, s)
  set text(size: 0.9em)
  let repository = card([🌐 Repository], width: 14em, on: step == 2)[
    #align(center)[#repository-graph(on: step == 1)]
    #align(center, text(size: 0.8em, fill: luma(110), style: "italic")[
      an arrow: _needs_ \
      ... thousands more, checked and signed
    ])
  ]
  let manager = card([⚙️ Package manager], width: 11.5em, on: step == 3)[
    #set par(leading: 0.8em)
    #distro-logo("fedora", height: 1.6em) #h(0.3em) #mono("dnf") · #mono(".rpm") \
    #distro-logo("ubuntu", height: 1.3em) #h(0.3em) Ubuntu #mono("apt") · #mono(".deb")
    #v(0.2em)
    #text(size: 0.8em, fill: luma(90))[search, download, check, install, update, remove]
  ]
  let system = card([💻 Your system], width: 10.5em)[
    #set par(leading: 0.9em)
    #let installed = align(center)[
      #installed-graph
      #text(size: 0.8em, fill: stream-changed, style: "italic")[`perl` is a _dependency_]
    ]
    #if step >= 3 { installed } else {
      hide(installed)
      place(center + horizon, text(fill: luma(140), style: "italic")[not installed yet])
    }
  ]
  grid(
    columns: 5,
    column-gutter: 0.5em,
    align: center + horizon,
    repository, card-arrow([download], on: step == 3), manager, card-arrow([install], on: step == 3), system,
  )
}

#slide[
  == App Repositories
  The Linux app store, long before the app stores

  #uncover("1-")[#block[- applications come as *packages*: the program, its files and the list of packages it needs (_dependencies_)]]
  #uncover("2-")[#block[- the distribution keeps them in a *repository*: a server with thousands of checked and signed packages]]
  #uncover("3-")[#block[- the *package manager* searches, downloads, installs, updates and removes them, dependencies included]]

  #v(0.3em)
  #align(center)[
    #only(1)[#repository-flow(1)]
    #only(2)[#repository-flow(2)]
    #only("3-")[#repository-flow(3)]
  ]
]

#slide[
  == Fedora: `dnf`
  Search and install `cowsay`
  #place(top + right, dy: -1.1em, distro-logo("fedora", height: 2em))

  #reveal-terminal(before: none, lines: (5, 10), full: false)[```terminal
  $ dnf search cowsay
  Matched fields: name (exact)
   cowsay.noarch     Configurable speaking/thinking cow
  Matched fields: name
   xcowsay.x86_64    Displays a cute cow and message on your desktop
  $ sudo dnf install cowsay
  Package Arch   Version        Repository      Size
  Installing:
   cowsay noarch 0:3.8.4-5.fc44 fedora      80.5 KiB
  Is this ok [y/N]: y
  ```]

  #set text(size: 0.9em)
  #only(1)[💡 `dnf search` looks for the name in the repositories: `cowsay` is in the `fedora` repository]
  #only("2-")[💡 installing changes the system for all the users: it needs `sudo` (the _administrator_), and asks before it starts]
]

#slide[
  == Ubuntu: `apt`
  Search and install `cowsay`
  #place(top + right, dy: -0.9em, distro-logo("ubuntu", height: 1.8em))

  #reveal-terminal(before: none, lines: (5, 10), full: false)[```terminal
  $ apt search cowsay
  cowsay/noble 3.03+dfsg2-8 all
    configurable talking cow
  xcowsay/noble 1.6-1build2 amd64
    Graphical configurable talking cow
  $ sudo apt install cowsay
  The following NEW packages will be installed:
    cowsay libgdbm-compat4t64 libgdbm6t64 libperl5.38t64
    libtext-charwidth-perl netbase perl perl-modules-5.38
  Do you want to continue? [Y/n] y
  ```]

  #set text(size: 0.9em)
  #only(1)[💡 the same idea, another package manager: `apt search` looks in the Ubuntu repositories (`noble` is Ubuntu 24.04)]
  #only("2-")[💡 `cowsay` is written in Perl: `apt` installs the *dependencies* too, `perl` and its libraries]
]

// the system after `cowsay` is installed, removed, ...: `cowsay` and
// `perl` are drawn only if given, `on` lists the highlighted ones
#let system-graph(shown, on) = {
  let size = (8, 5.0)
  let (cowsay, perl) = ((4, 0.8), (4, 4.2))
  let nodes = (("cowsay", cowsay), ("perl", perl)).filter(n => n.at(0) in shown)
  package-graph(
    size,
    nodes.map(((name, at)) => (name, at, name in on)),
    if "cowsay" in shown { ((cowsay, perl, "cowsay" in on),) } else { () },
    dotted: true,
  )
}

#slide[
  == Dependencies Are Packages Too
  After installing `cowsay`, `perl` is on the system

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (3, 5, 8), full: false)[```terminal
    $ which cowsay perl
    /usr/games/cowsay
    /usr/bin/perl
    $ perl -e 'print "hello from perl\n"'
    hello from perl
    $ sudo apt remove cowsay
    The following packages will be REMOVED:
      cowsay
    ```]
  ][
    #set text(size: 1.15em)
    #align(center)[#card([💻 Your system], width: 9em)[
      #align(center)[
        #only(1)[#system-graph(("cowsay", "perl"), ("cowsay", "perl"))]
        #only(2)[#system-graph(("cowsay", "perl"), ("perl",))]
        #only("3-")[#system-graph(("perl",), ("perl",))]
      ]
    ]]
  ]

  #set text(size: 0.9em)
  #only(1)[💡 `apt` installed both: `cowsay`, and `perl` because `cowsay` needs it]
  #only(2)[💡 `perl` is a normal package: you, or any other program, can use it *by itself*]
  #only("3-")[💡 removing `cowsay` does not remove `perl`; `sudo apt autoremove` removes the dependencies that nothing needs anymore]
]

#slide[
  == Package Managers Cheat Sheet
  Fedora and Ubuntu

  #set text(size: 0.9em)
  #align(center)[#table(
    columns: (auto, auto, auto),
    inset: (x: 0.8em, y: 0.5em),
    table.header([], [#distro-logo("fedora", height: 1.9em)], [#distro-logo("ubuntu", height: 1.4em) Ubuntu]),
    [search], [`dnf search NAME`], [`apt search NAME`],
    [details], [`dnf info NAME`], [`apt show NAME`],
    [install], [`sudo dnf install NAME`], [`sudo apt install NAME`],
    [remove], [`sudo dnf remove NAME`], [`sudo apt remove NAME`],
    [remove unused dependencies], [`sudo dnf autoremove`], [`sudo apt autoremove`],
    [update everything], [`sudo dnf upgrade`], [`sudo apt update` \ `sudo apt upgrade`],
  )]

  #v(0.5em)
  💡 `apt update` only refreshes the list of packages, `apt upgrade` installs the new versions; `dnf` refreshes the list by itself
]
