#import "common.typ": *

#section-cover([Capturing Packets], [see what goes through the card], layers: ("link", "network"), note: [tcpdump, \ Wireshark])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 10 - _Network Applications and Services_
  + #uso-book
    - Chapter 11 - _Rețelistică și Internet_
  + #link("https://www.tcpdump.org/manpages/tcpdump.1.html")[`man tcpdump`], #link("https://www.tcpdump.org/manpages/pcap-filter.7.html")[`man pcap-filter`]
  + #link("https://www.wireshark.org/docs/wsug_html_chunked/")[Wireshark User's Guide]
]

// ---------------------------------------------------------------------------
// tcpdump: a first capture, then the syntax, the options and the filters
// ---------------------------------------------------------------------------

// the color of each kind of word of a tcpdump command line
#let cap-kinds = (program: accent, option: ip-peach.bar, filter: ip-blue.bar, op: luma(90))

// a command in the terminal colors, in a drawing or a table
#let cap-cmd(t, size: 1em, command: false) = text(font: "DejaVu Sans Mono", size: size,
  highlight-shell(t, start-expect-command: command))

// one word of a command, as a chip framed in the color of its kind
// #cap-chip("-n", "option")
#let cap-chip(t, kind, size: 1em) = box(
  fill: if kind == "op" { luma(240) } else { cap-kinds.at(kind).lighten(85%) },
  stroke: 0.8pt + cap-kinds.at(kind),
  radius: 3pt,
  inset: (x: 4pt, y: 1pt),
  outset: (y: 2pt),
  cap-cmd(t, size: size, command: kind == "program"),
)

// a slot of the syntax, underlined in the color of its kind
// #cap-slot("[options]", "option")
#let cap-slot(t, kind, size: 17pt) = box(
  stroke: (bottom: 2pt + cap-kinds.at(kind)),
  inset: (bottom: 0.25em),
  text(font: "DejaVu Sans Mono", size: size, fill: cap-kinds.at(kind), weight: "bold", t),
)

// a card under a slot of the syntax, in the color of its kind
#let cap-card(kind, body, height: 96pt) = block(
  width: 100%,
  height: height,
  fill: cap-kinds.at(kind).lighten(92%),
  stroke: (top: 3pt + cap-kinds.at(kind)),
  radius: (bottom: 4pt),
  inset: (x: 8pt, y: 7pt),
  align(left + top, text(size: 10pt, body)),
)

// the steps of a shell: (lines shown, highlighted parts, explanation); the
// space of the whole session is kept from the first step (the lines not shown
// yet are hidden), so the explanation under it does not move
#let shell-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #box(width: 100%, {
      hide(parts-terminal(lines, size: size))
      place(top + left, parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size))
    })
    #body
  ]
}

#let cap-icmp = (
  "$ sudo tcpdump -i wlp2s0 -n -t icmp",
  "tcpdump: verbose output suppressed, use -v[v]... for full protocol decode",
  "listening on wlp2s0, link-type EN10MB (Ethernet), snapshot length 262144 bytes",
  ((none, "IP "), ("ip", "192.168.1.105 > 141.85.228.17"), (none, ": "), ("icmp", "ICMP echo request"), (none, ", id 7, seq 1, length 64")),
  ((none, "IP "), ("ip", "141.85.228.17 > 192.168.1.105"), (none, ": "), ("icmp", "ICMP echo reply"), (none, ", id 7, seq 1, length 64")),
  "^C",
  (("stats", "2 packets captured"),),
  (("stats", "2 packets received by filter"),),
  (("stats", "0 packets dropped by kernel"),),
)

#slide[
  == Capturing Packets
  `tcpdump`: see every packet that goes in or out of a card

  #shell-steps(cap-icmp, (
    (3, (), explain(
      [`tcpdump` waits and shows the packets, one per line],
      ([`sudo`], [only `root` may read all the packets of a card]),
      ([`-i wlp2s0`], [the card to listen on]),
      ([`-n -t`], [numbers, not names; no time on each line]),
      ([`icmp`], [a *filter*: only the ICMP packets (`ping`)]),
    )),
    (5, ("ip", "icmp"), explain(
      [meanwhile, in another terminal: `ping -c 1 141.85.228.17`],
      ([`a > b`], [the packet goes from `a` to `b`]),
      ([`echo`], [the request, then the reply]),
    )),
    (9, ("stats",), explain(
      [#kbd("Ctrl") + #kbd("C") stops it, then `tcpdump` counts the packets],
      ([`captured`], [the packets it showed]),
      ([`dropped`], [the packets it lost, because it was too slow: `0` is good]),
    )),
  ), size: 0.88em)
]

#slide[
  == `tcpdump` Syntax
  first the program, then the options, last the filter

  #v(0.4em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 1em,
    row-gutter: 0.8em,
    align: center + bottom,
    cap-slot("sudo tcpdump", "program"),
    cap-slot("[options]", "option"),
    cap-slot("[filter]", "filter"),
    uncover("1-", cap-card("program")[
      - `sudo`: only `root` may read *every* packet of a card
      - `tcpdump`: the program
      - install: `sudo dnf install tcpdump`
    ]),
    uncover("2-", cap-card("option")[
      - start with `-`
      - *where* to listen, *how* to show the packets, *how many*
      - #cap-chip("-i wlp2s0", "option") #h(0.3em) #cap-chip("-n", "option") #h(0.3em) #cap-chip("-c 5", "option")
    ]),
    uncover("3-", cap-card("filter")[
      - no `-`, always *last*
      - *which* packets to show
      - no filter: *every* packet
      - #cap-chip("icmp", "filter") #h(0.3em) #cap-chip("port 53", "filter")
    ]),
  )

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🔑", [the start is always the same: `sudo tcpdump`]))
    #only(2, fact("⚙️", [*options* are optional: without them, `tcpdump` listens on the first card]))
    #only("3-", fact("🔍", [the *filter* is optional too; all its words: `man pcap-filter`]))
  ]))
]

// the options of tcpdump, in groups: (group, step, ((option, meaning), ...))
#let cap-options = (
  ([where to listen], 1, (
    ("-D", [list the cards `tcpdump` can listen on]),
    ("-i wlp2s0", [listen on this card; `-i any`: on all of them]),
  )),
  ([how to show a packet], 2, (
    ("-n", [numbers, not names: addresses and ports]),
    ("-t", [no time at the start of each line]),
    ("-e", [the Ethernet header too: the MAC addresses]),
    ("-v", [more details (`-vv`, `-vvv`: even more)]),
    ("-A", [the data of each packet, as text]),
  )),
  ([how many, where to keep them], 3, (
    ("-c 10", [stop after 10 packets]),
    ("-w cap.pcap", [save the packets in a file, show nothing]),
    ("-r cap.pcap", [read the packets from a file (no `root` needed)]),
  )),
)

// examples of commands, one group for each step of the options
#let cap-option-examples = (
  (2, "sudo tcpdump -i wlp2s0 -n -t -e"),
  (3, "sudo tcpdump -i wlp2s0 -n -c 10"),
  (3, "sudo tcpdump -i wlp2s0 -w cap.pcap"),
  (3, "tcpdump -n -r cap.pcap"),
)

#slide[
  == `tcpdump` Options
  pick the ones you need, in any order

  #toolbox.side-by-side(columns: (4fr, 5fr), gutter: 1.2em)[
    #block(width: 100%, {
      set text(size: 0.7em)
      set table(inset: (x: 0.45em, y: 0.24em))
      table(
        columns: (auto, 1fr),
        stroke: none,
        // diatypst makes the first row bold: it is the first group title
        ..cap-options.map(((group, s, rows)) => (
          table.cell(colspan: 2, text(fill: cap-kinds.option, weight: "bold", group)),
          ..rows.map(((o, m)) => (cap-chip(o, "option"), m)).flatten(),
        )).flatten(),
      )
    })
  ][
    #v(0.4em)
    #text(size: 0.7em)[```terminal
$ sudo tcpdump -D
1.wlp2s0 [Up, Running, Wireless, Associated]
2.any (Pseudo-device that captures on all interfaces) [Up, Running]
3.lo [Up, Running, Loopback]
4.enp0s31f6 [Up, Disconnected]
...
```]
    #set text(size: 0.75em)
    #for (s, cmd) in cap-option-examples {
      block(above: 0.5em, cap-cmd(cmd, command: true))
    }
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #fact("💡", [find the card with `-D`, listen on it with `-i`; `-w` saves the packets, `-r` reads them back])
  ]))
]

// the parts of one filter word (a primitive): the slot name, if it is
// optional, the words it may be (chips, like in the examples)
#let fchip(t) = cap-chip(t, "filter")
#let cap-filter-slots = (
  ([protocol], true, [#fchip("tcp") #fchip("udp") \ #fchip("ip") #fchip("arp")]),
  ([direction], true, [#fchip("src") #fchip("dst")]),
  ([type], false, [#fchip("host") #fchip("net") \ #fchip("port")]),
  ([value], false, [an address, \ a network, a port]),
)

// examples of filters, one part per slot (none: not used), their meaning
// and the step they show up on; the command is built from the parts
// (every one is a valid filter: tcpdump refuses e.g. `tcp host ...`)
#let cap-filter-examples = (
  (("icmp", none, none, none), [only ping (ICMP)], 1),
  ((none, none, "host", "192.168.1.1"), [to *or* from the gateway], 2),
  ((none, "src", "host", "192.168.1.105"), [only *from* my laptop], 3),
  ((none, none, "net", "141.85.0.0/16"), [to or from the UPB network], 3),
  (("udp", none, "port", "53"), [DNS: UDP, port 53], 4),
  (("tcp", "dst", "port", "443"), [TCP, *to* port 443: HTTPS], 5),
)

#slide[
  == `tcpdump` Filters
  one filter: what to look for, and its value

  #v(0.2em)
  #block(width: 100%, {
    set text(size: 0.74em)
    grid(
      columns: (auto, auto, auto, auto, 1fr),
      column-gutter: 1.2em,
      row-gutter: 0.5em,
      align: (left + horizon),
      // the slots, with the words each one may be
      ..cap-filter-slots.map(((name, optional, words)) => box(stroke: (bottom: 2pt + cap-kinds.filter), inset: (bottom: 0.3em))[
        #text(weight: "bold", fill: cap-kinds.filter, name)#if optional { text(size: 0.8em, fill: luma(120))[ (optional)] }
      ]),
      box(stroke: (bottom: 2pt + accent), inset: (bottom: 0.3em), text(weight: "bold", fill: accent)[the command]),
      ..cap-filter-slots.map(((name, optional, words)) => text(size: 0.85em, fill: luma(80), par(leading: 0.75em, words))),
      [],
      // which protocol goes with which type: tcpdump refuses the other pairs
      grid.cell(colspan: 5, text(size: 0.85em, fill: luma(80))[⚠️ a protocol goes only with some types: #fchip("tcp") #fchip("udp") only before #fchip("port"), #h(0.3em) #fchip("ip") #fchip("ip6") #fchip("arp") only before #fchip("host") or #fchip("net")]),
      // the examples, every part in its slot
      ..cap-filter-examples.map(((parts, meaning, s)) => (
        ..parts.map(p => if p == none { text(fill: luma(190))[--] } else { cap-chip(p, "filter") }),
        // the command, with the filter on the background of the filter chips
        stack(spacing: 0.45em,
          text(font: "DejaVu Sans Mono", size: 1.05em)[#text(fill: accent, weight: "bold")[\$] #highlight-shell("sudo tcpdump -n") #highlight(fill: ip-blue.hl, extent: 1pt, radius: 2pt, parts.filter(p => p != none).join(" "))],
          text(size: 0.95em, fill: luma(100), meaning),
        ),
      )).flatten(),
    )
  })

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #fact("🧱", [read it as a sentence: _TCP packets going *to* port 443_; without `src` or `dst`: *both* ways])
  ]))
]

// filters joined together: (words as (text, kind), meaning, step)
#let cap-combos = (
  ((("not", "op"), ("port 22", "filter")), [everything, except SSH], 1),
  ((("host 192.168.1.1", "filter"), ("and", "op"), ("icmp", "filter")), [ping, to or from the gateway: *both* must be true], 2),
  ((("icmp", "filter"), ("or", "op"), ("arp", "filter")), [ping or ARP: *one* is enough], 3),
  ((("host 192.168.1.1", "filter"), ("and", "op"), ("(", "op"), ("icmp", "filter"), ("or", "op"), ("arp", "filter"), (")", "op")), [ping or ARP, to or from the gateway], 4),
)

#slide[
  == Combining Filters
  `not`, `and`, `or` and parentheses, like in a sentence

  #v(0.3em)
  #block(width: 100%, {
    set text(size: 0.8em)
    grid(
      columns: (auto, 1fr),
      column-gutter: 1.4em,
      row-gutter: 0.8em,
      align: left + horizon,
      ..cap-combos.map(((ws, meaning, s)) => (
        ws.map(((t, k)) => cap-chip(t, k)).join(h(0.4em)),
        meaning,
      )).flatten(),
    )
  })

  #v(0.6em)
  #block(width: 100%, {
    set text(size: 0.8em)
    terminal("$ sudo tcpdump -n 'host 192.168.1.1 and (icmp or arp)'")
  })

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #fact("⚠️", [put the filter in `'...'` when it has `(`, `)` or `!`: the shell gives them another meaning], c: (fill: bad-color.lighten(92%), stroke: bad-color))
  ]))
]

// tcpdump prints every packet on one line; the lines are too long for the
// slide, so each one is split in two (said under the terminal)
#let cap-arp = (
  "$ sudo tcpdump -i wlp2s0 -n -t -e arp",
  "...",
  ((none, ""), ("mac", "3c:a9:f4:5e:21:7b > ff:ff:ff:ff:ff:ff"), (none, ", ethertype "), ("type", "ARP (0x0806)"), (none, ", length 42:")),
  ((none, "    "), ("ask", "Request who-has 192.168.1.1 tell 192.168.1.105"), (none, ", length 28")),
  ((none, ""), ("mac2", "70:b5:e8:2d:91:4c > 3c:a9:f4:5e:21:7b"), (none, ", ethertype ARP (0x0806), length 42:")),
  ((none, "    "), ("answer", "Reply 192.168.1.1 is-at 70:b5:e8:2d:91:4c"), (none, ", length 28")),
)
#let cap-split = text(size: 0.75em, fill: luma(110))[each packet is *one* line in the terminal, split in two here to fit]

#slide[
  == Capturing Frames
  `-e` adds the Ethernet header: here ARP finds a MAC address

  #shell-steps(cap-arp, (
    (4, ("mac", "type", "ask"), [
      #cap-split
      #explain(
        [the laptop asks *everybody*: who has `192.168.1.1`?],
        ([`-e`], [show the MAC addresses and the type of the frame]),
        ([`ff:ff:...`], [*broadcast*: every card receives it]),
        ([`0x0806`], [the *Type* field: an ARP message, not an IP packet]),
      )
    ]),
    (6, ("mac2", "answer"), [
      #cap-split
      #explain(
        [the gateway answers *only to the laptop*, with its MAC address],
        ([💡], [`ip neigh` shows what the laptop found: `192.168.1.1` is `70:b5:e8:2d:91:4c`]),
      )
    ]),
  ), size: 0.82em)
]

// the Wireshark window, with a numbered badge and an orange frame on each
// part; the parts are (top, height) as fractions of the screenshot height
#let ws-width = 270pt
#let ws-height = ws-width * 792 / 1066
#let ws-parts = (
  (0.105, 0.33), // 1. the packets
  (0.465, 0.375), // 2. the layers of the selected packet
  (0.845, 0.125), // 3. the bytes
  (0.103, 0.026), // 4. the display filter bar
)
#let ws-badge(n) = circle(radius: 7pt, fill: hl, stroke: 1pt + white, align(center + horizon, text(
  size: 8pt,
  weight: "bold",
  fill: white,
  str(n),
)))
#let ws-screen(current) = box(width: ws-width, height: ws-height, {
  place(image("img/wireshark.png", width: ws-width))
  place(rect(width: 100%, height: 100%, stroke: 0.8pt + luma(150), fill: none))
  for (i, (t0, h)) in ws-parts.enumerate() {
    let n = i + 1
    if n <= current {
      if n == current {
        place(dy: ws-height * t0, rect(width: 100%, height: ws-height * h, stroke: 2pt + hl, fill: hl.transparentize(88%)))
      }
      place(right + top, dx: if n == 4 { -60pt } else { -16pt }, dy: ws-height * t0 + (if n == 4 { -6pt } else { 4pt }), ws-badge(n))
    }
  }
})
#let ws-point(n, body) = grid(columns: (auto, 1fr), column-gutter: 6pt, align: horizon, ws-badge(n), body)

#slide[
  == Wireshark
  the packets of `tcpdump`, in a window

  #toolbox.side-by-side(columns: (auto, 1fr), gutter: 1.2em)[
    #for k in range(1, 5) { only(k, ws-screen(k)) }
  ][
    #set text(size: 10pt)
    #stack(
      spacing: 9pt,
      ws-point(1, [the *packets*, one per line, like `tcpdump`]),
      uncover("2-", ws-point(2, [the *layers* of the selected packet: Ethernet, IP, UDP, DNS])),
      uncover("3-", ws-point(3, [the *bytes*, as the card received them])),
      uncover("4-", ws-point(4, [*display filter*: `dns`, `ip.addr == 192.168.0.1`; ⚠️ not the language of `tcpdump`])),
    )
    #v(10pt)
    #fact("💾", [save with `tcpdump -w cap.pcap` on any computer, then open the file in Wireshark])
  ]
]
