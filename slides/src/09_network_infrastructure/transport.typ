#import "common.typ": *

#section-cover([Transport Layer], [programs talk to programs], layers: ("transport",), note: [TCP, UDP, \ ports])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.16 - _The Transport Layer_
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
  the layers of two computers

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
    ("network", [IP `141.85.228.17`]),
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
    #only(2, fact("🖥️", [the *computers* talk on the network and data link layers: the kernel and the *drivers*]))
    #only(3, fact("🚚", [the *transport layer* (in the kernel too) connects a *program* to a *program*, not a computer to a computer]))
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
// (`port: none`: no port yet, no socket drawn)
#let prog(x, y, name, port, w: 96pt, hl-it: false) = {
  layer-box(x, y, w, 22pt, name, "application", highlight: hl-it)
  if port != none { pin(x - 14pt, y + 11pt, box(width: 28pt, height: 12pt, radius: 2pt, fill: if hl-it { hl } else { luma(55) }, align(
    center + horizon,
    text(size: 7pt, fill: white, weight: "bold", font: "DejaVu Sans Mono", ":" + str(port)),
  ))) }
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
    #place(top + left, dx: 308pt, dy: 4pt, text(size: 7.5pt, weight: "bold", fill: luma(80))[server `141.85.228.17`])
    // the network between them
    #wire((150pt, 79pt), (300pt, 79pt), stroke: 2pt + luma(150))
    #cloud(225pt, 79pt, [Internet], width: 60pt, height: 30pt)

    #let srv-x = 378pt
    #prog(srv-x, 28pt, [`sshd` (SSH)], 22, w: 84pt)
    #prog(srv-x, 68pt, [`nginx` (Web)], 443, w: 84pt)
    #prog(srv-x, 108pt, [DNS server], 53, w: 84pt)
    #only("2-")[#prog(40pt, 68pt, [browser], 51034, hl-it: true)]
    #only(1)[#prog(40pt, 68pt, [browser], none)]

    // the route: laptop -> Internet -> server -> nginx, and back
    #only(2)[
      #leg(140pt, 176pt)
      #env(186pt, "141.85.228.17:443")
      #seg(76pt, 124pt, "141.85.228.17", "192.168.1.105", "443", "51034")
    ]
    #only(3)[
      #at(300pt, 0pt, box(width: 170pt, height: 160pt, radius: 6pt, stroke: 2pt + layer-colors.network.stroke))
      #leg(140pt, 192pt, done: true)
      #leg(258pt, 284pt)
      #env(294pt, "141.85.228.17:443")
      #seg(225pt, 124pt, "141.85.228.17", "203.0.113.42", "443", "51034")
    ]
    #only(4)[
      #prog(srv-x, 68pt, [`nginx` (Web)], 443, w: 84pt, hl-it: true)
      #leg(140pt, 192pt, done: true)
      #leg(258pt, 298pt, done: true)
      #leg(302pt, 330pt)
      #env(340pt, "141.85.228.17:443")
      #seg(225pt, 124pt, "141.85.228.17", "203.0.113.42", "443", "51034")
    ]
    #only("5-")[
      #prog(srv-x, 68pt, [`nginx` (Web)], 443, w: 84pt, hl-it: true)
      #leg(348pt, 302pt, color: ok-color)
      #leg(298pt, 258pt, color: ok-color)
      #leg(192pt, 154pt, color: ok-color)
      #env(144pt, "192.168.1.105:51034", color: ok-color)
      #seg(225pt, 124pt, "203.0.113.42", "141.85.228.17", "51034", "443", color: ok-color)
    ]
  ]

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🚪", [a port is a number (0 - 65535): each server program *waits* on its own port]))
    #only(2, fact("✉️", [the browser sends: to *IP* `141.85.228.17`, *port* `443`; its own port is a free one from the OS, `51034`]))
    #only(3, fact("🏢", [the *IP address* finds the computer: the *building*; on the way, the home router put its public address `203.0.113.42` (NAT)]))
    #only(4, fact("🚪", [the *port* finds the program: the *apartment*, `443` is `nginx`]))
    #only("5-", fact("↩️", [the answer goes to `203.0.113.42:51034`, the home router sends it to `192.168.1.105:51034`: to the browser, not to another program], c: good-c))
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
      ("3389", "TCP", [RDP, remote desktop]),
      ("5432", "TCP", [PostgreSQL]),
    )),
  )

  #v(2pt)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 14pt,
    uncover("2-", fact("📖", [`/etc/services`: the names of the ports, shown by `ss` and `netstat` without `-n`])),
    uncover("3-", fact("🔢", [`0`–`1023`: _well known_, only `root` may *listen* on them; `32768`–`60999`: given to clients])),
  )
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
  == Getting a Port
  a program asks the operating system

  #let base = ((22, [`sshd`], "LISTEN"), (53, [DNS server], "LISTEN"))
  #let ng = (443, [`nginx`], "LISTEN")
  #let br = (51034, [browser], "ESTAB")
  // a request (to the right) and the answer (back, below it)
  #let ask(y, q, a, color: ok-color) = {
    draw-arrow((112pt, y), (262pt, y), color: hl, thickness: 1.5pt)
    label(187pt, y - 8pt, text(size: 8pt, fill: hl, q))
    draw-arrow((262pt, y + 12pt), (112pt, y + 12pt), color: color, thickness: 1.5pt)
    label(187pt, y + 22pt, text(size: 8pt, fill: color, a))
  }
  #drawing(width: 470pt, height: 160pt)[
    #layer-box(0pt, 10pt, 105pt, 26pt, [`nginx`], "application")
    #uncover("2-")[#layer-box(0pt, 62pt, 105pt, 26pt, [a second `nginx`], "application")]
    #uncover("3-")[#layer-box(0pt, 114pt, 105pt, 26pt, [browser], "application")]
    // the operating system, with its port table
    #at(268pt, 0pt, box(width: 202pt, height: 158pt, radius: 6pt, fill: luma(245), stroke: 1pt + luma(150)))
    #place(top + left, dx: 276pt, dy: 4pt, text(size: 8pt, weight: "bold")[operating system: the ports])
    #place(top + left, dx: 278pt, dy: 20pt, {
      only(1, port-table(base + (ng,), new: 443))
      only(2, port-table(base + (ng,)))
      only("3-", port-table(base + (ng, br), new: 51034))
    })
    #only(1)[#ask(17pt, [I want to listen to port `443`], [✅ it is yours])]
    #only(2)[#ask(69pt, [I want to listen to port `443`], [❌ already taken], color: bad-color)]
    #only("3-")[#ask(121pt, [I want to talk to `141.85.228.17:443`], [✅ you get port `51034`])]
  ]

  #let bad-c = (fill: bad-color.lighten(90%), stroke: bad-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🚪", [a *server* asks for its port and *listens* there; only `root` may listen on ports below `1024`]))
    #only(2, fact("❌", [a second program asks for the *same* port: refused, one port has *one* program], c: bad-c))
    #only("3-", fact("🎲", [a *client* does not choose: the operating system gives it a *free* port from `32768`–`60999`, here `51034`; `ESTAB`: _established_, connected]))
  ]))
]

#slide[
  == TCP and UDP
  the two transport protocols

  #counter(footnote).update(0)

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
    [*connection*], [yes: first a "hello" (the _handshake_), then the data], [no: just send],
    [*lost data*], [sent again], [lost],
    [*order*], [the data arrives in order], [any order],
    [*speed*], [slower], [faster],
    [*used by*], [Web, SSH, e-mail], [DNS, DHCP, video calls, games#footnote[simplified: DNS also uses TCP for long answers, and the newest Web (HTTP/3) runs over UDP]],
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
  ("len", [Length], [2 bytes], 64pt, "📏", "32"),
  ("sum", [Checksum], [2 bytes], 72pt, "✅", "0x1f2b"),
  ("data", [Data], [up to 65 507 bytes], 124pt, "🗨️", none),
)

#slide[
  == UDP Datagram
  the simple one: ports, and nothing more; the example: a DNS question

  #let steps = (
    (none, explain(
      [🔎 what *UDP* does: carries one message from a program to another, *nothing more*],
      ([📮 *no connection*], [no _"hello"_: the datagram is just sent]),
      ([🎲 *no order*], [the datagrams may arrive in any order]),
      ([💨 *no second try*], [a lost datagram stays lost; in exchange, it is *fast* and *simple*]),
    )),
    (("data",), explain(
      [🔎 an example: a *DNS question*, sent over *UDP*],
      ([`upb.ro`?], [a program asks the DNS server for the IP address of `upb.ro`]),
      ([💡], [DNS uses UDP: a short question, a short answer, no connection needed]),
    )),
    (("src", "dst"), explain(
      [the *ports*: which program sends, which program receives],
      ([📬 *Destination*], [the program that gets the data: `53`, the port of the DNS server]),
      ([📤 *Source*], [the program that sent it, so the answer comes back to it]),
      ([💡], [the IP addresses are not here: they are in the IP packet, around it]),
    )),
    (("len", "sum"), explain(
      [a *length* and a *check*],
      ([📏 *Length*], [header + data, in bytes: `8 + 24 = 32` (the DNS question for `upb.ro` has 24 bytes)]),
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
        [*DNS question* \ #text(size: 6.5pt)[`upb.ro`?]],
      )
      #if body != none { body }
    ]
  }
]

#let tcp-fields = (
  ("src", [Source Port], [2 bytes], 60pt, "📤", "51034"),
  ("dst", [Dest. Port], [2 bytes], 56pt, "📬", "443"),
  ("seq", [Sequence], [4 bytes], 68pt, "🔢", "1000"),
  ("ack", [Ack], [4 bytes], 60pt, "👍", "5000"),
  ("flags", [Flags], [1 byte], 60pt, "🚩", "ACK"),
  ("sum", [Checksum], [2 bytes], 60pt, "✅", "0x9c41"),
  ("data", [Data], [any], 76pt, "🗨️", none),
)

#slide[
  == TCP Segment
  simplified: only the important fields

  #let steps = (
    (none, explain(
      [🔎 what *TCP* does: a *reliable connection* between two programs (the browser and the web server)],
      ([📞 *connection*], [first a _"hello"_, then the data, at the end a _"goodbye"_]),
      ([🔢 *in order*], [every byte has a number: the receiver puts the bytes back in order]),
      ([🔁 *nothing lost*], [the receiver confirms what it got; what is not confirmed in time is *sent again*]),
    )),
    (("src", "dst"), explain(
      [the *ports*, just like UDP],
      ([📬 📤], [from the browser `51034`, to the web server `443`]),
    )),
    (("seq", "ack"), explain(
      [*numbers*, so nothing is lost and everything is in order],
      ([🔢 *Sequence*], [the number of the first byte here: the receiver puts the data *in order*]),
      ([👍 *Ack*], [the next byte I expect: _"I got everything before it"_; no Ack in time, the data is *sent again*]),
    )),
    (("flags",), explain(
      [🚩 *Flags*: what the segment does],
      ([`SYN`], [start a connection: _"hello"_]),
      ([`ACK`], [the *Ack* number is valid: _"I got it"_]),
      ([`FIN`], [end the connection: _"goodbye"_]),
      ([`RST`], [_"no"_: refuse or break a connection (nobody listens on that port)]),
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
        [*header*: 20 bytes, only some fields shown],
        [*Data* \ #text(size: 6.5pt)[from the application]],
      )
      #if body != none { body }
    ]
  }
]

// ---------------------------------------------------------------------------
// All the layers: each one puts what it gets from above in its own box
// ---------------------------------------------------------------------------

#slide[
  == All the Layers
  each layer adds its own header in front

  #let (app, tr, net, link) = (layer-colors.application, layer-colors.transport, layer-colors.network, layer-colors.link)
  // the rows, one for each layer
  #let (rh, gap) = (38pt, 8pt)
  #let row-y(i) = 1pt + i * (rh + gap)
  // the columns: every box is right under the same box of the row above
  #let (xe, xi, xt, xd, xf, xend) = (104pt, 176pt, 270pt, 364pt, 452pt, 478pt)
  // the boxes of one row, from the outside in: (x1, x2, color, header);
  // each one is a rounded box, the next one sits inside it, 3pt smaller on
  // every side but the left, where the header of the outer box is
  #let nest(i, boxes) = for (k, (x1, x2, c, head)) in boxes.enumerate() {
    let pad = k * 3pt
    let next-x = if k + 1 < boxes.len() { boxes.at(k + 1).at(0) } else { x2 }
    at(x1, row-y(i) + pad, box(width: x2 - x1, height: rh - 2 * pad, radius: 4pt, fill: c.fill, stroke: 0.9pt + c.stroke))
    at(x1, row-y(i) + pad, box(width: next-x - x1, height: rh - 2 * pad, inset: (x: 5pt), align(left + horizon, text(size: 6.5pt, head))))
  }
  // (from #arrow to: the sender, then the receiver)
  #let data-head = align(center)[📄 `GET /index.html`]
  #let tcp-head = [*TCP header* \ port `51034` #arrow `443`]
  #let ip-head = [*IP header* \ `192.168.1.105` \ #arrow `141.85.228.17`]
  // the Ethernet header: first the MAC address is missing, then ARP finds it
  #let missing = box(fill: bad-color.lighten(85%), stroke: 1pt + bad-color, radius: 2pt, inset: (x: 2pt, y: 1pt), text(fill: bad-color, weight: "bold")[???])
  #let eth-missing = [*Ethernet header* \ MAC to #missing]
  #let eth-head = [*Ethernet header* \ MAC to #new-val[router]]
  #let data(x2) = (xd, x2, app, data-head)
  // a layer box on the left, colored once it works
  #let layer-row(i, c, name, on) = at(0pt, row-y(i), box(
    width: 88pt,
    height: rh,
    radius: 4pt,
    fill: if on { c.fill } else { luma(248) },
    stroke: if on { 1.2pt + c.stroke } else { 0.6pt + luma(210) },
    align(center + horizon, text(size: 8pt, fill: if on { black } else { luma(150) }, weight: "bold", name)),
  ))
  // what the layer calls its box, in the empty space left of it
  #let unit(i, x, body, c) = pin(x - 26pt, row-y(i) + rh / 2, text(size: 7.5pt, weight: "bold", fill: c.stroke, body))
  // an arrow down, from one row to the next
  #let down(i, x) = draw-arrow((x, row-y(i) + rh + 1pt), (x, row-y(i + 1) - 1pt), color: hl, thickness: 1.5pt, head: 5pt)

  #align(center, scale(94%, reflow: true, drawing(height: 178pt)[
    #for (i, (c, name)) in ((app, [Application]), (tr, [Transport]), (net, [Network]), (link, [Data Link])).enumerate() {
      only(str(i + 1) + "-", layer-row(i, c, name, true))
      if i > 0 { only("-" + str(i), layer-row(i, c, name, false)) }
    }

    // 1: the browser's data, and where it goes: the browser chooses the
    // destination IP address and port (the socket), not only the data
    #nest(0, (data(xf),))
    #let (sx1, sx2) = (190pt, 350pt)
    #at(sx1, row-y(0) + 5pt, box(width: sx2 - sx1, height: rh - 10pt, radius: 4pt, fill: white, stroke: 1pt + app.stroke, inset: (x: 5pt), align(left + horizon, text(size: 6.5pt)[
      🔌 *the browser asks:* \
      connect to `141.85.228.17` port `443`
    ])))
    // the browser's choices go down to two layers: the port to the
    // transport layer, the IP address to the network layer
    // (drawn at the end, on top of the boxes)
    #let tell(x, i) = draw-arrow((x, row-y(0) + rh - 5pt), (x, row-y(i) - 0.5pt), color: app.stroke, thickness: 1.2pt, head: 5pt)
    // 2: the transport layer puts the ports in front: a segment
    #uncover("2-")[
      #down(0, (xd + xf) / 2)
      #nest(1, ((xt, xf, tr, tcp-head), data(xf - 3pt)))
      #unit(1, xt, [segment], tr)
    ]
    // 3: the network layer puts the IP addresses in front: a packet
    #uncover("3-")[
      #down(1, (xt + xf) / 2)
      #nest(2, ((xi, xf, net, ip-head), (xt, xf - 3pt, tr, tcp-head), data(xf - 6pt)))
      #unit(2, xi, [packet], net)
    ]
    // 4: the link layer puts the MAC addresses in front, and the FCS after: a frame
    #uncover("4-")[
      #down(2, (xi + xf) / 2)
      #only(4, nest(3, ((xe, xend, link, eth-missing), (xi, xf, net, ip-head), (xt, xf - 3pt, tr, tcp-head), data(xf - 6pt))))
      #only("5-", nest(3, ((xe, xend, link, eth-head), (xi, xf, net, ip-head), (xt, xf - 3pt, tr, tcp-head), data(xf - 6pt))))
      #pin((xf + xend) / 2, row-y(3) + rh / 2, text(size: 6.5pt, weight: "bold")[FCS])
      #pin(xe + 58pt, row-y(3) - 6pt, text(size: 7.5pt, weight: "bold", fill: link.stroke)[frame])
    ]
    // 4 - 5: the popup, over the empty part of the Transport row: which MAC
    // address? then ARP finds it (the server is in another network: the
    // MAC address of the gateway)
    #let popup(c, body) = {
      at(102pt, row-y(1) - 2pt, box(width: 98pt, height: 44pt, radius: 4pt, fill: luma(0).transparentize(82%)))
      at(100pt, row-y(1) - 4pt, box(width: 98pt, height: 44pt, radius: 4pt, fill: white, stroke: 1.4pt + c, inset: 5pt, align(left + horizon, text(size: 6.5pt, body))))
      draw-arrow((124pt, row-y(1) + 40pt), (124pt, row-y(3) + 22pt), color: c, thickness: 1.3pt, head: 5pt)
    }
    #uncover("2-")[#tell(325pt, 1)]
    #uncover("3-")[#tell(215pt, 2)]
    #only(4, popup(bad-color)[❓ *to which card?* \ the server `141.85.228.17` is in *another network*])
    #only(5, popup(ok-color)[📢 *ARP*: who has `192.168.1.1`, the *gateway*? \ ↩️ the router: `70:b5:e8:2d:91:4c`])
    // 6: the idea, as a popup over the drawing
    #only("6-")[
      #let (px, py, pw, ph) = (118pt, row-y(1) + 6pt, 250pt, 62pt)
      #at(px + 3pt, py + 3pt, box(width: pw, height: ph, radius: 6pt, fill: luma(0).transparentize(80%)))
      #at(px, py, box(width: pw, height: ph, radius: 6pt, fill: white, stroke: 1.6pt + hl, inset: 8pt, align(left + horizon, grid(
        columns: (auto, 1fr),
        column-gutter: 7pt,
        align: horizon,
        icon("🔁", size: 18pt),
        text(size: 9pt)[each layer puts what it gets *from above* in its own box; the server opens the boxes in *reverse order*],
      ))))
    ]
  ]))

  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("📄", [the *browser* has *data* (a request for a page) and says *where*: the IP address and the port of the server]))
    #only(2, fact("🚪", [the *transport layer* adds the *ports*: `443` from the browser, `51034` given by the operating system]))
    #only(3, fact("🌍", [the *network layer* adds the *IP addresses*: the destination, also from the browser, and the laptop's own]))
    #only(4, fact("✉️", [the *link layer* adds the *MAC addresses*, but which card is the next stop?], c: (fill: bad-color.lighten(92%), stroke: bad-color)))
    #only(5, fact("📢", [another network: ARP finds the MAC address of the *gateway*, the router], c: (fill: ok-color.lighten(90%), stroke: ok-color)))
  ]))
]

#slide[
  == Ports in Linux
  who waits for data on this computer?

  ```terminal
  $ ss -tuln
  Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
  udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*
  udp   UNCONN 0      0            0.0.0.0:68         0.0.0.0:*
  tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*
  tcp   LISTEN 0      511          0.0.0.0:443        0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*
  tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*
  ```

  #block[
    #set text(size: 0.92em)
    #explain(
      [`ss` shows the *sockets*: a socket is what a program uses to send and receive on a port],
      ([`-t` `-u` `-l` `-n`], [TCP, UDP, only the ones that wait for data (_listening_), numbers not names (`443`, not `https`)]),
      ([`LISTEN`], [a TCP server waits for connections; `UNCONN`: a UDP socket (UDP has no connections)]),
      ([`0.0.0.0:22`], [port 22, on every IP address of the computer]),
      ([`127.0.0.53%lo:53`], [port 53, only on the loopback: the local DNS cache (_systemd-resolved_)]),
    )
  ]
]

// `ss` and `netstat`, with the program of each port
#let ss-p = (
  "$ sudo ss -tlnp",
  ((none, "State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process"),),
  ((none, "LISTEN 0      511          0.0.0.0:"), ("port", "443"), (none, "        0.0.0.0:*     "), ("prog", "users:((\"nginx\",pid=1033,fd=6))")),
  ((none, "LISTEN 0      128          0.0.0.0:"), ("port", "22"), (none, "         0.0.0.0:*     "), ("prog", "users:((\"sshd\",pid=812,fd=3))")),
)
#let netstat-p = (
  "$ sudo netstat -tlnp",
  ((none, "Active Internet connections (only servers)"),),
  ((none, "Proto Recv-Q Send-Q Local Address    Foreign Address  State   PID/Program name"),),
  ((none, "tcp        0      0 0.0.0.0:"), ("port", "443"), (none, "      0.0.0.0:*        LISTEN  "), ("prog", "1033/nginx")),
  ((none, "tcp        0      0 0.0.0.0:"), ("port", "22"), (none, "       0.0.0.0:*        LISTEN  "), ("prog", "812/sshd")),
)

#slide[
  == Which Program?
  `ss` (newer) and `netstat` (older), with the same options

  #parts-terminal(ss-p, hl: ((("port", "prog"), ip-peach),), size: 0.8em)
  #uncover("2-")[#parts-terminal(netstat-p, hl: ((("port", "prog"), ip-peach),), size: 0.8em)]
  #set text(size: 0.92em)
  #explain(
    [`-p`: the *program* that owns the socket, and its PID],
    ([`sudo`], [only `root` may see the programs of the other users]),
    (uncover("2-")[`netstat`], uncover("2-")[the same, an older command (_net-tools_), not installed by default on newer systems]),
    (uncover("2-")[`ss`], uncover("2-")[newer (_iproute2_, like `ip`), faster, installed everywhere]),
  )
]
