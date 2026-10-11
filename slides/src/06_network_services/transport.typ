#import "common.typ": *

#section-cover([Transport Layer], [programs talk to programs], layers: ("transport",), note: [TCP, UDP, \ ports])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.17 - _The Transport Layer_
  + #tanenbaum
    - Chapter 6 - _The Transport Layer_
      - Section 6.4 - _The Internet Transport Protocols: UDP_
      - Section 6.5 - _The Internet Transport Protocols: TCP_
  + #uso-book
    - Section 11.4.2 - _Adresarea TCP_
]

// ---------------------------------------------------------------------------
// Who talks to whom
// ---------------------------------------------------------------------------

// one stack of layers, at x: (layer, name in this stack)
#let talk-stack(x, rows, w: 118pt) = for (i, (layer, name)) in rows.enumerate() {
  layer-box(x, 8pt + i * 30pt, w, 26pt, name, layer, size: 8pt)
}
// the conversation between the two stacks on row i: a double arrow and a label
#let talk(i, body, color: luma(110)) = {
  let y = 21pt + i * 30pt
  draw-arrow((126pt, y), (344pt, y), color: color, thickness: 1.5pt, dash: "dashed")
  draw-arrow((344pt, y), (126pt, y), color: color, thickness: 1.5pt, dash: "dashed")
  label(235pt, y - 8pt, text(size: 7.5pt, fill: color, body))
}

#slide[
  == Who Talks to Whom?

  #let left-rows = (
    ("application", [browser]),
    ("transport", [TCP / UDP, port `51034`]),
    ("network", [IP `192.168.1.105`]),
    ("link", [driver + card, MAC]),
    ("physical", [Wi-Fi radio]),
  )
  #let right-rows = (
    ("application", [`nginx` (web server)]),
    ("transport", [TCP / UDP, port `443`]),
    ("network", [IP `141.85.220.33`]),
    ("link", [driver + card, MAC]),
    ("physical", [cable]),
  )
  #v(10pt)
  #drawing(width: 470pt, height: 160pt)[
    #label(59pt, -2pt, text(size: 8pt, weight: "bold")[my laptop])
    #label(411pt, -2pt, text(size: 8pt, weight: "bold")[server])
    #talk-stack(0pt, left-rows)
    #talk-stack(352pt, right-rows)
    // the data really travels only down, on the wire, and up
    #wire((118pt, 141pt), (352pt, 141pt), stroke: 2pt + luma(90))
    #label(235pt, 135pt, text(size: 7.5pt, fill: luma(80))[the data really travels here: through the networks, the routers])
    #uncover("2-")[
      #talk(3, [the *network cards*: frames, MAC addresses, hop by hop])
      #talk(2, [the *computers*: packets, IP addresses])
    ]
    #uncover("3-")[#talk(1, [which *program* gets the data, and *how*: TCP or UDP], color: hl)]
    #uncover("4-")[#talk(0, [🗨️ the *programs* talk to each other], color: ok-color)]
  ]

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🔌", [the data goes *down* the stack, travels on the cables and the radio, and goes *up* the other stack]))
    #only(2, fact("🖥️", [the *computers* talk on the network and data link layers: the operating system and the *drivers*]))
    #only(3, fact("🚚", [the *transport layer* connects a *program* to a *program*, not a computer to a computer]))
    #only("4-", fact("🗨️", [the browser talks to the web server: the layers below only *carry* their messages], c: good-c))
  ]))
]

#slide[
  == Two Jobs
  of the transport layer

  #let job(e, title, body) = block(
    width: 100%,
    height: 150pt,
    inset: 10pt,
    radius: 6pt,
    fill: layer-colors.transport.fill.lighten(40%),
    stroke: 1pt + layer-colors.transport.stroke,
    [#text(size: 13pt, weight: "bold")[#icon(e, size: 16pt) #title] #v(4pt) #text(size: 10.5pt, body)],
  )
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    job("🚚", [*How* to deliver], [
      the *delivery* of the data, chosen by the program:
      - 📞 *TCP*: a connection, nothing lost, in order (Web, SSH)
      - 📮 *UDP*: no connection, fast, may lose data (DNS, games, calls)
    ]),
    uncover("2-", job("🚪", [*To which* program], [
      the *port* chooses the program (the service) on the computer:
      - `22` SSH, `80` / `443` Web, `53` DNS
      - the IP address finds the computer, the port finds the program
    ])),
  )
  #v(0pt)
]

// ---------------------------------------------------------------------------
// Ports
// ---------------------------------------------------------------------------

// a program and the port it waits on (a dark socket on the left of the box)
#let prog(x, y, name, port, w: 96pt, hl-it: false) = {
  layer-box(x, y, w, 22pt, name, "application", highlight: hl-it)
  pin(x - 14pt, y + 11pt, box(width: 28pt, height: 12pt, radius: 2pt, fill: if hl-it { hl } else { luma(55) }, align(
    center + horizon,
    text(size: 7pt, fill: white, weight: "bold", font: "DejaVu Sans Mono", ":" + str(port)),
  )))
}
// a segment on its way: the IP addresses (network) and the ports (transport)
#let seg(x, y, ip-to, ip-from, port-to, port-from, color: hl) = pin(x, y, box(
  fill: if color == hl { hl-bg } else { color.lighten(88%) },
  stroke: 1.2pt + color,
  radius: 3pt,
  inset: 2.5pt,
  grid(
    columns: 2,
    column-gutter: 2pt,
    align: horizon,
    icon("✉️", size: 10pt),
    text(size: 6.5pt, table(
      columns: 3,
      inset: (x: 2.5pt, y: 2pt),
      align: left + horizon,
      stroke: (x, y) => if y == 0 { none } else { 0.6pt + (layer-colors.network.stroke, layer-colors.transport.stroke).at(y - 1) },
      fill: (x, y) => if y == 0 { none } else { (layer-colors.network.fill, layer-colors.transport.fill).at(y - 1) },
      [], text(fill: luma(90))[to], text(fill: luma(90))[from],
      [*IP*], raw(ip-to), raw(ip-from),
      [*port*], raw(port-to), raw(port-from),
    )),
  ),
))
// the envelope on the wire, and a piece of its route
#let env(x, to, y: 79pt, color: hl) = {
  pin(x, y, icon("✉️", size: 12pt))
  pin(x, y - 20pt, box(
    fill: white,
    stroke: 0.8pt + color,
    radius: 2pt,
    inset: (x: 2.5pt, y: 1.5pt),
    text(size: 6.5pt, font: "DejaVu Sans Mono", fill: color, weight: "bold", to),
  ))
}
#let leg(x1, x2, color: hl, done: false) = draw-arrow(
  (x1, 79pt),
  (x2, 79pt),
  color: if done { color.lighten(55%) } else { color },
  thickness: 2.4pt,
  head: 7pt,
)

#slide[
  == Ports
  the IP address finds the computer, the *port* finds the program

  #drawing(width: 470pt, height: 165pt)[
    // my laptop
    #at(0pt, 0pt, box(width: 150pt, height: 160pt, radius: 6pt, stroke: (paint: luma(150), dash: "dashed")))
    #place(top + left, dx: 8pt, dy: 4pt, text(size: 7.5pt, weight: "bold", fill: luma(80))[my laptop `192.168.1.105`])
    // the server
    #at(300pt, 0pt, box(width: 170pt, height: 160pt, radius: 6pt, stroke: (paint: luma(150), dash: "dashed")))
    #place(top + left, dx: 308pt, dy: 4pt, text(size: 7.5pt, weight: "bold", fill: luma(80))[server `141.85.220.33`])
    // the network between them
    #wire((150pt, 79pt), (300pt, 79pt), stroke: 2pt + luma(150))
    #cloud(225pt, 79pt, [Internet], width: 60pt, height: 30pt)

    #let srv-x = 378pt
    #prog(srv-x, 28pt, [`sshd` (SSH)], 22, w: 84pt)
    #prog(srv-x, 68pt, [`nginx` (Web)], 443, w: 84pt)
    #prog(srv-x, 108pt, [DNS server], 53, w: 84pt)
    #only("2-")[#prog(40pt, 68pt, [browser], 51034, hl-it: true)]
    #only(1)[#prog(40pt, 68pt, [browser], 51034)]

    // the route: laptop -> Internet -> server -> nginx, and back
    #only(2)[
      #leg(140pt, 176pt)
      #env(186pt, "141.85.220.33:443")
      #seg(76pt, 124pt, "141.85.220.33", "192.168.1.105", "443", "51034")
    ]
    #only(3)[
      #at(300pt, 0pt, box(width: 170pt, height: 160pt, radius: 6pt, stroke: 2pt + layer-colors.network.stroke))
      #leg(140pt, 192pt, done: true)
      #leg(258pt, 284pt)
      #env(294pt, "141.85.220.33:443")
      #seg(225pt, 124pt, "141.85.220.33", "192.168.1.105", "443", "51034")
    ]
    #only(4)[
      #prog(srv-x, 68pt, [`nginx` (Web)], 443, w: 84pt, hl-it: true)
      #leg(140pt, 192pt, done: true)
      #leg(258pt, 298pt, done: true)
      #leg(302pt, 330pt)
      #env(340pt, "141.85.220.33:443")
      #seg(225pt, 124pt, "141.85.220.33", "192.168.1.105", "443", "51034")
    ]
    #only("5-")[
      #prog(srv-x, 68pt, [`nginx` (Web)], 443, w: 84pt, hl-it: true)
      #leg(348pt, 302pt, color: ok-color)
      #leg(298pt, 258pt, color: ok-color)
      #leg(192pt, 154pt, color: ok-color)
      #env(144pt, "192.168.1.105:51034", color: ok-color)
      #seg(76pt, 124pt, "192.168.1.105", "141.85.220.33", "51034", "443", color: ok-color)
    ]
  ]

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🚪", [a port is a number (0 - 65535): each server program *waits* on its own port]))
    #only(2, fact("✉️", [the browser sends: to *IP* `141.85.220.33`, *port* `443`; its own port is a random one, `51034`]))
    #only(3, fact("🏢", [the *IP address* finds the computer: the *building*]))
    #only(4, fact("🚪", [the *port* finds the program: the *apartment*, `443` is `nginx`]))
    #only("5-", fact("↩️", [the answer goes back to port `51034`: to the browser, not to another program], c: good-c))
  ]))
]

// ---------------------------------------------------------------------------
// How a program gets a port
// ---------------------------------------------------------------------------

// the port table of the operating system, with the rows shown on this step
#let port-table(rows, new: none) = {
  set text(size: 8pt)
  table(
    columns: (44pt, 70pt, 62pt),
    inset: 4pt,
    align: (center, left, left),
    stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(200)) },
    fill: (x, y) => if y == 0 { accent } else if rows.at(y - 1).at(0) == new { hl-bg } else { none },
    table.header(..([port], [program], [state]).map(t => text(fill: white, weight: "bold", t))),
    ..rows.map(((port, prog, state)) => (raw(str(port)), prog, raw(state))).flatten(),
  )
}

#slide[
  == How a Program Gets a Port
  it asks the operating system

  #let base = ((22, [`sshd`], "LISTEN"), (53, [DNS server], "LISTEN"))
  #let ng = (443, [`nginx`], "LISTEN")
  #let br = (51034, [browser], "ESTAB")
  // a request (to the right) and, if given, the answer (back, below it)
  #let ask(y, q, a: none, color: ok-color) = {
    draw-arrow((112pt, y), (262pt, y), color: hl, thickness: 1.5pt)
    label(187pt, y - 8pt, text(size: 8pt, fill: hl, q))
    if a != none {
      draw-arrow((262pt, y + 12pt), (112pt, y + 12pt), color: color, thickness: 1.5pt)
      label(187pt, y + 22pt, text(size: 8pt, fill: color, a))
    }
  }
  #drawing(width: 470pt, height: 160pt)[
    #layer-box(0pt, 10pt, 105pt, 26pt, [`nginx`], "application")
    #uncover("3-")[#layer-box(0pt, 62pt, 105pt, 26pt, [a second `nginx`], "application")]
    #uncover("4-")[#layer-box(0pt, 114pt, 105pt, 26pt, [browser], "application")]
    // the operating system, with its port table: a row is added when the
    // operating system answers, and it is highlighted on that step
    #at(268pt, 0pt, box(width: 202pt, height: 158pt, radius: 6pt, fill: luma(245), stroke: 1pt + luma(150)))
    #place(top + left, dx: 276pt, dy: 4pt, text(size: 8pt, weight: "bold")[operating system: the ports])
    #place(top + left, dx: 278pt, dy: 20pt, {
      only(1, port-table(base))
      only(2, port-table(base + (ng,), new: 443))
      only("3-4", port-table(base + (ng,)))
      only("5-", port-table(base + (ng, br), new: 51034))
    })
    #only(1)[#ask(17pt, [I want to listen to port `443`])]
    #only(2)[#ask(17pt, [I want to listen to port `443`], a: [✅ it is yours])]
    #only(3)[#ask(69pt, [I want to listen to port `443`], a: [❌ already taken], color: bad-color)]
    #only(4)[#ask(121pt, [I want to talk to `141.85.220.33:443`])]
    #only("5-")[#ask(121pt, [I want to talk to `141.85.220.33:443`], a: [✅ you get port `51034`])]
  ]

  #let bad-c = (fill: bad-color.lighten(90%), stroke: bad-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🚪", [a *server* asks the operating system for a port; ports below `1024` only for `root`]))
    #only(2, fact("📝", [the port is free: the operating system *writes it in the table*, `nginx` waits there]))
    #only(3, fact("❌", [a second program asks for the *same* port: it is in the table, refused, one port has *one* program], c: bad-c))
    #only(4, fact("🎲", [a *client* does not choose a port: it only says where it wants to go]))
    #only("5-", fact("📝", [the operating system picks a *free* port, `51034`, and *writes it in the table*]))
  ]))
]

#slide[
  == TCP and UDP
  the two transport protocols

  #text(size: 10.5pt, table(
    columns: (auto, 1fr, 1fr),
    inset: (x: 7pt, y: 5pt),
    align: left + horizon,
    stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(210)) },
    fill: (x, y) => if y == 0 { accent } else if calc.even(y) { luma(246) } else { white },
    table.header([], text(fill: white, weight: "bold")[#text(size: 1.4em, "📞") TCP], text(
      fill: white,
      weight: "bold",
    )[#text(size: 1.4em, "📮") UDP]),
    [*like*], [a phone call], [a postcard],
    [*connection*], [yes: first "hello", then the data], [no: just send],
    [*lost data*], [sent again], [lost],
    [*order*], [the data arrives in order], [any order],
    [*speed*], [slower], [faster],
    [*used by*], [Web, SSH, e-mail], [DNS, DHCP, video calls, games],
  ))
  #v(0pt)
]

// ---------------------------------------------------------------------------
// The headers: UDP and TCP
// ---------------------------------------------------------------------------

// a header of the transport layer, drawn like the Ethernet frame
#let segment-drawing(selected, fields, header, payload) = frame-drawing(
  selected: selected,
  fields: fields,
  groups: ((fields.first().at(0), fields.at(fields.len() - 2).at(0), header), ("data", "data", [*data*])),
  packet: payload,
  name-size: 7.5pt,
  color: layer-colors.transport,
  inner: layer-colors.application,
)

#let udp-fields = (
  ("src", [Source Port], [2 bytes], 84pt, "📤", "40211"),
  ("dst", [Destination Port], [2 bytes], 96pt, "📬", "53"),
  ("len", [Length], [2 bytes], 64pt, "📏", "41"),
  ("sum", [Checksum], [2 bytes], 72pt, "✅", "0x1f2b"),
  ("data", [Data], [up to 65 507 bytes], 124pt, "🗨️", none),
)

#slide[
  == UDP Datagram
  the simple one: ports, and nothing more

  #let steps = (
    (none, none),
    (("src", "dst"), explain(
      [the *ports*: which program sends, which program receives],
      ([📬 *Destination*], [the program that gets the data: `53` is the DNS server]),
      ([📤 *Source*], [the program that sent it, so the answer comes back to it]),
      ([💡], [the IP addresses are not here: they are in the IP packet, around it]),
    )),
    (("len", "sum"), explain(
      [a *length* and a *check*],
      ([📏 *Length*], [header + data, in bytes: `8 + 33 = 41`]),
      ([✅ *Checksum*], [the receiver checks it: a damaged datagram is *dropped*]),
    )),
    (("data",), explain(
      [the *data* of the program, sent *as it is*],
      ([📮], [no connection, no order, no second try: a lost datagram stays lost]),
      ([🎯], [the program decides what to do: DNS just asks again]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #segment-drawing(
        if keys == none { () } else { keys },
        udp-fields,
        [*header*: 8 bytes],
        [*Data* \ #text(size: 6.5pt)[from the application]],
      )
      #if body != none { body }
    ]
  }
]

// packets in time: the sender and the receiver, each with a line going down
// (time), and the packets between them as sloped arrows
#let (seq-l, seq-r) = (95pt, 375pt)
#let seq-ends(l-name, r-name, h) = {
  for (x, body) in ((seq-l, l-name), (seq-r, r-name)) {
    place(top + left, line(start: (x, 26pt), end: (x, h), stroke: (paint: luma(160), thickness: 1pt, dash: "dashed")))
    pin(x, 12pt, box(fill: layer-colors.application.fill, stroke: 0.8pt + layer-colors.application.stroke, radius: 3pt, inset: (x: 8pt, y: 5pt), text(size: 9pt, weight: "bold", body)))
  }
  label(seq-l - 58pt, 40pt, text(size: 7pt, fill: luma(120))[time ↓])
}
// a numbered packet
#let pkt-chip(n, color: hl) = box(width: 15pt, height: 15pt, radius: 2pt, fill: color.lighten(85%), stroke: 1pt + color, align(
  center + horizon,
  text(size: 8.5pt, weight: "bold", fill: color, str(n)),
))
// packet n leaves the sender at y1 and arrives at the receiver at y2
// (or gets lost on the way)
#let fly(y1, y2, n, color: hl, lost: false) = {
  let (mx, my) = ((seq-l + seq-r) / 2, (y1 + y2) / 2)
  let end = if lost { (mx, my) } else { (seq-r, y2) }
  draw-arrow((seq-l, y1), end, color: color, thickness: 1.4pt, head: 6pt, dash: if lost { "dashed" } else { none })
  if lost { pin(mx + 10pt, my, icon("❌", size: 12pt)) }
  // the number of the packet, on the sender's side, when it leaves
  pin(seq-l - 14pt, y1, pkt-chip(n, color: color))
}
// what the program on the receiver gets, next to its line
#let got(y, ..ns, color: ok-color) = pin(seq-r + 14pt + ns.pos().len() * 9pt, y, stack(
  dir: ltr,
  spacing: 3pt,
  ..ns.pos().map(n => pkt-chip(n, color: color)),
))

#slide[
  == UDP Example
  send and hope: _best effort_

  #drawing(width: 470pt, height: 175pt)[
    #seq-ends([sender], [receiver], 172pt)
    #fly(44pt, 74pt, 1)
    #fly(64pt, 134pt, 2)
    #fly(84pt, 104pt, 3)
    #fly(104pt, 134pt, 4, color: bad-color, lost: true)
    #uncover("2-")[
      #got(74pt, 1)
      #got(104pt, 3)
      #got(134pt, 2)
      #label(seq-r + 40pt, 158pt, text(size: 8pt, fill: bad-color)[`4` never comes])
    ]
  ]

  #let bad-c = (fill: bad-color.lighten(90%), stroke: bad-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📮", [the sender sends 4 packets, one after the other, like *postcards*: no connection, no _"got it"_]))
    #only(2, fact("🤷", [the receiver gets `1` `3` `2`: packet `2` came *late*, packet `4` is *lost*, and nobody sends it again], c: bad-c))
  ]))
]

#let tcp-fields = (
  ("src", [Source Port], [2 bytes], 60pt, "📤", "51034"),
  ("dst", [Dest. Port], [2 bytes], 56pt, "📬", "443"),
  ("seq", [Sequence], [4 bytes], 68pt, "🔢", "1000"),
  ("ack", [Ack], [4 bytes], 60pt, "👍", "5000"),
  ("flags", [Flags], [2 bytes], 60pt, "🚩", "ACK"),
  ("sum", [Checksum], [2 bytes], 60pt, "✅", "0x9c41"),
  ("data", [Data], [any], 76pt, "🗨️", none),
)

#slide[
  == TCP Segment
  simplified: only the important fields

  #let steps = (
    (none, none),
    (("src", "dst"), explain(
      [the *ports*, just like UDP],
      ([📬 📤], [from the browser `51034`, to the web server `443`]),
    )),
    (("seq", "ack"), explain(
      [*numbers*, so nothing is lost and everything is in order],
      ([🔢 *Sequence*], [the number of the first byte here: the receiver puts the data *in order*]),
      ([👍 *Ack*], [_"I got everything up to here"_; no answer in time, the data is *sent again*]),
    )),
    (("flags",), explain(
      [🚩 *Flags*: what the segment does],
      ([`SYN`], [start a connection: _"hello"_]),
      ([`ACK`], [the *Ack* number is valid: _"I got it"_]),
      ([`FIN`], [end the connection: _"goodbye"_]),
    )),
    (("sum", "data"), explain(
      [the *check* and the *data*],
      ([✅ *Checksum*], [like UDP: a damaged segment is dropped, and then sent again]),
      ([➕], [a few more fields, not shown here: the header has at least 20 bytes]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #segment-drawing(
        if keys == none { () } else { keys },
        tcp-fields,
        [*header*: 20 bytes (simplified)],
        [*Data* \ #text(size: 6.5pt)[from the application]],
      )
      #if body != none { body }
    ]
  }
]

#slide[
  == TCP Example
  a channel: everything arrives, in order

  #drawing(width: 470pt, height: 175pt)[
    #seq-ends([sender], [receiver], 172pt)
    #fly(44pt, 74pt, 1)
    #fly(60pt, 90pt, 2)
    #fly(76pt, 106pt, 3, color: bad-color, lost: true)
    #fly(92pt, 122pt, 4)
    // the cache of the receiver: the packets wait here, in their place,
    // until the ones before them have arrived
    #let cache(slots, title-color: accent) = {
      at(seq-r + 10pt, 50pt, box(width: 84pt, inset: 5pt, radius: 4pt, fill: luma(246), stroke: 1pt + luma(160), stack(
        spacing: 5pt,
        text(size: 7.5pt, weight: "bold", fill: luma(80))[receiver's cache],
        stack(dir: ltr, spacing: 3pt, ..slots.map(((n, c)) => if n == none {
          box(width: 15pt, height: 15pt, radius: 2pt, stroke: (paint: bad-color, thickness: 1pt, dash: "dashed"), align(
            center + horizon,
            text(size: 8pt, fill: bad-color)[?],
          ))
        } else { pkt-chip(n, color: c) })),
      )))
    }
    // what the program reads from the cache: only the packets in order
    #let reads(..ns) = {
      label(seq-r + 52pt, 104pt, text(size: 7.5pt, fill: luma(80))[the program reads])
      at(seq-r + 13pt, 112pt, stack(dir: ltr, spacing: 3pt, ..ns.pos().map(n => pkt-chip(n, color: ok-color))))
    }
    #only(1)[
      #cache(((1, ok-color), (2, ok-color), (none, none), (4, luma(140))))
      #reads(1, 2)
      #label(seq-r + 52pt, 140pt, text(size: 7.5pt, fill: luma(110))[`4` waits for `3`])
    ]
    #only("2-")[
      #label(seq-l - 52pt, 120pt, text(size: 7.5pt, fill: luma(90))[⏱ no _"got it"_ \ for `3`])
      #fly(136pt, 160pt, 3, color: accent)
      #label(seq-l - 40pt, 136pt, text(size: 8pt, fill: accent)[again])
      #cache(((1, ok-color), (2, ok-color), (3, accent), (4, ok-color)))
      #reads(1, 2, 3, 4)
    ]
  ]

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📞", [`3` is lost: `4` *waits* in the cache, the program reads only `1` `2`]))
    #only(2, fact("🔁", [no _"got it"_ for `3`: the sender *sends it again*, now the program reads `3` `4`, in order], c: good-c))
  ]))
]

#let port-list(rows) = text(size: 10.5pt, table(
  columns: (auto, auto, 1fr),
  inset: (x: 7pt, y: 3.5pt),
  align: left + horizon,
  stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(210)) },
  fill: (x, y) => if y == 0 { accent } else if calc.even(y) { luma(246) } else { white },
  table.header(..([port], [over], [service]).map(h => text(fill: white, weight: "bold", h))),
  ..rows.map(((port, proto, name)) => (text(weight: "bold", raw(port)), proto, name)).flatten(),
))

#slide[
  == Standard Ports
  every service has its usual port

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    port-list((
      ("22", "TCP", [SSH, remote shell]),
      ("25", "TCP", [SMTP, sending e-mail]),
      ("53", "UDP", [DNS, names to IP addresses]),
      ("67 / 68", "UDP", [DHCP, server / client]),
      ("80", "TCP", [HTTP, the Web]),
      ("443", "TCP", [HTTPS, the secure Web]),
    )),
    port-list((
      ("123", "UDP", [NTP, the time]),
      ("143 / 993", "TCP", [IMAP, reading e-mail]),
      ("445", "TCP", [SMB, Windows file sharing]),
      ("3306", "TCP", [MySQL / MariaDB]),
      ("5432", "TCP", [PostgreSQL]),
      ("3389", "TCP", [RDP, remote desktop]),
    )),
  )

  #v(2pt)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    uncover("2-", fact("📖", [`/etc/services`: the names of the ports, shown by `ss` and `netstat` without `-n`])),
    uncover("3-", fact("🔢", [`0` - `1023`: well known, only `root` may use them; above: any program, and clients])),
  )
]

#slide[
  == Ports in Linux
  who waits for data on this computer?

  #reveal-terminal(before: none, lines: (1, 7), full: false)[```terminal
  $ ss -tuln
  Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process
  udp   UNCONN 0      0          127.0.0.1:53        0.0.0.0:*
  udp   UNCONN 0      0            0.0.0.0:68        0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:443       0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:80        0.0.0.0:*
  ```]

  #uncover("2-")[
    #explain(
      [`ss` shows the *sockets*],
      ([`-t` `-u`], [TCP and UDP sockets]),
      ([`-l`], [only the ones that wait for data (*listening*)]),
      ([`-n`], [numbers, not names (`443`, not `https`)]),
      ([`0.0.0.0:22`], [port 22, on every IP address of the computer]),
      ([`127.0.0.1:53`], [port 53, only for programs of this computer]),
    )
  ]
]

// `ss` and `netstat`, with the program of each port
#let ss-p = (
  "$ sudo ss -tlnp",
  ((none, "State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process"),),
  ((none, "LISTEN 0      128          0.0.0.0:"), ("port", "22"), (none, "        0.0.0.0:*    "), ("prog", "users:((\"sshd\",pid=812,fd=3))")),
  ((none, "LISTEN 0      511          0.0.0.0:"), ("port", "443"), (none, "       0.0.0.0:*    "), ("prog", "users:((\"nginx\",pid=1033,fd=6))")),
)
#let netstat-p = (
  "$ sudo netstat -tlnp",
  ((none, "Active Internet connections (only servers)"),),
  ((none, "Proto Recv-Q Send-Q Local Address    Foreign Address  State   PID/Program name"),),
  ((none, "tcp        0      0 0.0.0.0:"), ("port", "22"), (none, "       0.0.0.0:*        LISTEN  "), ("prog", "812/sshd")),
  ((none, "tcp        0      0 0.0.0.0:"), ("port", "443"), (none, "      0.0.0.0:*        LISTEN  "), ("prog", "1033/nginx")),
)

#slide[
  == Which Program?
  `ss` (newer) and `netstat` (older), with the same options

  #only(1)[
    #parts-terminal(ss-p, hl: ((("port", "prog"), ip-peach),), size: 0.85em)
    #explain(
      [`-p`: the *program* that owns the socket, and its PID],
      ([`sudo`], [only `root` may see the programs of the other users]),
    )
  ]
  #only("2-")[
    #parts-terminal(netstat-p, hl: ((("port", "prog"), ip-peach),), size: 0.85em)
    #explain(
      [`netstat`: the same, an older command],
      ([_net-tools_], [the package, not installed by default on newer systems]),
      ([`ss`], [newer (_iproute2_, like `ip`), faster, installed everywhere]),
    )
  ]
]
