#import "common.typ": *

#section-cover([Ethernet], [networks with cables: hubs and switches])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.8 - _The Physical Layer and Ethernet_
  + #tanenbaum
    - Chapter 4 - _The Medium Access Control Sublayer_
      - Section 4.3 - _Ethernet_
      - Section 4.8 - _Data Link Layer Switching_
  + #uso-book
    - Section 11.3 - _Echipamente de rețea_
]

#slide[
  == Ethernet Frame
  what the network card sends: like a letter in an envelope

  #let steps = (
    (none, none),
    (("dst", "src"), explain(
      [the *addresses*, like on an envelope],
      ([📬 *Destination*], [who should receive the frame: one card, or `ff:ff:ff:ff:ff:ff` for every card (_broadcast_)]),
      ([📤 *Source*], [who sent the frame, so the receiver can answer]),
      ([💡], [a network card *ignores* the frames that are not for it]),
    )),
    (("type",), explain(
      [🏷️ *Type*: what is inside the frame],
      ([`0x0800`], [an IPv4 packet]),
      ([`0x86DD`], [an IPv6 packet]),
      ([`0x0806`], [an ARP message (find the MAC address of an IP address)]),
    )),
    (("data", "crc"), explain(
      [the *data* and the *trailer*],
      ([📦 *Payload*], [46 to 1500 bytes, usually a packet of the layer above; shorter data is padded]),
      ([✅ *CRC*], [a checksum of the whole frame; the receiver computes it again, if it is different the frame was damaged and is *dropped*]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #frame-drawing(selected: if keys == none { () } else { keys })
      #if body != none { body }
    ]
  }
]

// an envelope: a frame with the addresses written on it
#let envelope(x, y, to, from, color: hl) = pin(x, y, box(
  fill: if color == hl { hl-bg } else { color.lighten(88%) },
  stroke: 1.2pt + color,
  radius: 4pt,
  inset: (x: 6pt, y: 4pt),
  grid(
    columns: 2,
    column-gutter: 5pt,
    align: horizon,
    icon("✉️", size: 14pt),
    text(size: 7pt)[*to:* #raw(to) \ *from:* #raw(from)],
  ),
))

#slide[
  == Two Computers
  connected with a cable

  #drawing(height: 145pt)[
    #let (xa, xb, y) = (60pt, 420pt, 62pt)
    #let (pa, pb) = (xa + 30pt, xb - 30pt)
    // the cable, with a plug at each end
    #wire((pa, y), (pb, y), stroke: (paint: luma(90), thickness: 4pt, cap: "round"))
    #for x in (pa - 4pt, pb - 4pt) { at(x, y - 6pt, box(width: 9pt, height: 12pt, radius: 1.5pt, fill: luma(55))) }
    #host(xa, y, "A", addr: "3c:a9:f4:5e:21:7b", size: 42pt)
    #host(xb, y, "B", addr: "8c:16:45:a2:3b:91", size: 42pt)

    // step 1: one cable, two ends
    #only(1)[
      #for x in (pa, pb) { draw-arrow((x, y - 30pt), (x, y - 9pt), color: hl, thickness: 1pt) }
      #label(pa, y - 37pt, text(size: 7.5pt, fill: hl, weight: "bold")[end 1])
      #label(pb, y - 37pt, text(size: 7.5pt, fill: hl, weight: "bold")[end 2])
      // a third computer has nowhere to plug in
      #wire((240pt, y + 4pt), (240pt, y + 40pt), stroke: (paint: luma(160), thickness: 1.5pt, dash: "dashed"))
      #pin(240pt, y + 22pt, icon("❌", size: 12pt))
      #host(240pt, y + 56pt, "C", size: 26pt, color: luma(150))
    ]

    // steps 2 - 3: the frame travels from A to B, leaving a trail behind
    #let to-b = "8c:16:45:a2:3b:91"
    #let from-a = "3c:a9:f4:5e:21:7b"
    #for (i, x) in (180pt, 330pt).enumerate() {
      only(i + 2, {
        wire((pa + 8pt, y), (x, y), stroke: (paint: hl, thickness: 4pt, cap: "round"))
        pin(x, y, circle(radius: 4pt, fill: hl, stroke: none))
        envelope(x, y - 26pt, to-b, from-a)
      })
    }
    // step 3: B checks the address, the frame is for it
    #only(3)[#pin(xb + 32pt, y - 22pt, icon("✅", size: 14pt))]

    // step 4: full duplex, one way for each direction
    #only(4)[
      #draw-arrow((pa + 10pt, y - 7pt), (pb - 10pt, y - 7pt), color: hl, thickness: 1.4pt)
      #draw-arrow((pb - 10pt, y + 7pt), (pa + 10pt, y + 7pt), color: ok-color, thickness: 1.4pt)
      #envelope(240pt, y - 30pt, "B", "A")
      #envelope(240pt, y + 30pt, "A", "B", color: ok-color)
    ]
  ]

  // a note with a big emoji on the left, in the same panel as the explanations
  #let note(e, body) = block(
    width: 100%,
    inset: (x: 10pt, y: 8pt),
    fill: ip-peach.bg,
    stroke: (left: 3pt + ip-peach.bar),
    radius: (right: 4pt),
    grid(columns: (auto, 1fr), column-gutter: 10pt, align: horizon, icon(e, size: 20pt), body),
  )
  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1, note("🔌")[a cable has *two ends*: it connects *exactly two* devices, there is no place for a third one])
    #only(2, note("✉️")[A sends a *frame*: the destination is the MAC address of *B*, the source is the MAC address of *A*])
    #only(3, note("✅")[B finds *its own* MAC address on the frame, so it keeps it])
    #only(4, note("🛣️")[*full duplex*: like a road with two lanes, the cable has separate wires for each direction, both computers can send at the same time])
  ]))

]

#slide[
  == More Computers?
  connect every computer to every other one

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #drawing(width: 220pt, height: 185pt)[
      #let pts = range(5).map(i => {
        let a = -90deg + i * 72deg
        (110pt + 72pt * calc.cos(a), 95pt + 72pt * calc.sin(a))
      })
      // the point on the way from computer i to computer j, `d` away from i
      #let toward(i, j, d) = {
        let (x1, y1) = pts.at(i)
        let (x2, y2) = pts.at(j)
        let (dx, dy) = ((x2 - x1).pt(), (y2 - y1).pt())
        let len = calc.sqrt(dx * dx + dy * dy)
        (x1 + dx / len * d, y1 + dy / len * d)
      }
      // one cable for each pair, plugged in a network card at each end
      #for i in range(5) {
        for j in range(i + 1, 5) { wire(toward(i, j, 16pt), toward(j, i, 16pt), stroke: 1.1pt + luma(110)) }
      }
      #for (i, p) in pts.enumerate() { host(..p, "ABCDE".at(i), below: i != 0, size: 24pt) }
      #uncover("2-")[
        #for i in range(5) {
          for j in range(5) {
            if i != j { pin(..toward(i, j, 16pt), box(width: 6pt, height: 6pt, radius: 1pt, fill: rgb("eb6a38"), stroke: 0.6pt + white)) }
          }
        }
      ]
    ]
  ][
    #set text(size: 10.5pt)
    #uncover("2-")[
      #block[- 5 computers: *10 cables*, \ *4 network cards* #box(width: 6pt, height: 6pt, radius: 1pt, fill: rgb("eb6a38")) in each]
    ]
    #uncover("3-")[
      #block[- 100 computers: *4950 cables*, \ *99 network cards* in each #icon("😱", size: 11pt)]
    ]
    #uncover("4-")[
      #block[- $n$ computers: $(n (n-1)) / 2$ cables]
    ]
    #uncover("5-")[
      #v(0.3em)
      #block(
        width: 100%,
        inset: (x: 8pt, y: 8pt),
        fill: ip-peach.bg,
        stroke: (left: 3pt + ip-peach.bar),
        radius: (right: 4pt),
        grid(
          columns: (auto, 1fr),
          column-gutter: 8pt,
          align: horizon,
          // a small star: one central device, one cable for each computer
          box(width: 78pt, height: 70pt, {
            let c = (39pt, 35pt)
            for k in range(5) {
              let a = -90deg + k * 72deg
              let p = (39pt + 30pt * calc.cos(a), 35pt + 27pt * calc.sin(a))
              wire(c, p, stroke: 1pt + luma(110))
              pin(..p, box(fill: ip-peach.bg, pic("pc", size: 13pt)))
            }
            pin(..c, box(fill: ip-peach.bg, pic("switch", size: 11pt)))
          }),
          [
            #text(size: 11pt)[💡 use a *central device*:] \
            *one cable* and *one card* \ for each computer
          ],
        ),
      )
    ]
  ]
]

// the star used by the hub and switch slides
#let star-hosts = (
  (name: "Ana", p: (40pt, 45pt), mac: "5c:8f:2a:91:d4:07", below: false),
  (name: "Bogdan", p: (40pt, 150pt), mac: "e4:3b:71:0c:9a:52", below: true),
  (name: "Carla", p: (250pt, 45pt), mac: "08:d1:6e:b3:47:ac", below: false),
  (name: "Dan", p: (250pt, 150pt), mac: "f0:9e:4a:c2:16:3d", below: true),
)
#let center-pt = (145pt, 97pt)
#let star-w = 290pt
// a mark (accepted / dropped) next to host i
#let host-mark(i, ok) = {
  let (x, y) = star-hosts.at(i).p
  pin(x + (if x < 145pt { -26pt } else { 26pt }), y, icon(if ok { "✅" } else { "❌" }, size: 12pt))
}
// the point at fraction t of the wire from host i to the center
#let on-wire(i, t) = {
  let (x, y) = star-hosts.at(i).p
  let (cx, cy) = center-pt
  (x + (cx - x) * t, y + (cy - y) * t)
}

#let star(name, layer: "physical", sub: none, ports: false, width: 400pt) = {
  for h in star-hosts { wire(h.p, center-pt, stroke: 1.6pt + luma(120)) }
  for (i, h) in star-hosts.enumerate() {
    host(..h.p, h.name, addr: h.mac, below: h.below)
  }
  netdev(..center-pt, if layer == "physical" { "hub" } else { "switch" }, name: name, size: 30pt)
  // the layers the device sees
  sees-stack(center-pt.at(0), center-pt.at(1) + 34pt, layer)
  // the ports of the switch: a small numbered socket where each cable plugs in
  if ports {
    for i in range(4) {
      let (px, py) = on-wire(i, 0.62)
      pin(px, py, box(width: 13pt, height: 11pt, radius: 2pt, fill: luma(55), align(
        center + horizon,
        text(size: 6.5pt, fill: white, weight: "bold", str(i + 1)),
      )))
    }
  }
}

// the path of a frame in the star: a thick arrow on the wire of the sender,
// going into the device, and one on the wire of each receiver, going out
#let flow-in(i, color: hl) = draw-arrow(on-wire(i, 0.18), on-wire(i, 0.56), color: color, thickness: 2.6pt, head: 7pt)
#let flow-out(i, color: hl) = draw-arrow(on-wire(i, 0.56), on-wire(i, 0.18), color: color, thickness: 2.6pt, head: 7pt)
// the frame: an envelope with its destination MAC address, next to the wire
// of the sender (on the outer side, so it does not cover the arrow);
// `dst` is the index of the destination host, or "all" for a broadcast
#let flow-frame(i, dst, color: hl) = {
  let (x, y) = star-hosts.at(i).p
  let (cx, cy) = center-pt
  let (dx, dy) = ((cx - x).pt(), (cy - y).pt())
  let len = calc.sqrt(dx * dx + dy * dy)
  // the normal of the wire, pointing away from the center line
  let (nx, ny) = (dy / len, -dx / len)
  if (ny < 0) != (y < cy) { (nx, ny) = (-nx, -ny) }
  let (px, py) = on-wire(i, 0.42)
  let mac = if dst == "all" { "ff:ff:ff:ff:ff:ff" } else { star-hosts.at(dst).mac }
  pin(px + nx * 15pt, py + ny * 15pt, box(
    fill: if color == hl { hl-bg } else { color.lighten(88%) },
    stroke: 1pt + color,
    radius: 3pt,
    inset: (x: 3pt, y: 2pt),
    text(size: 8pt)[#icon("✉️", size: 8pt) to #text(font: "DejaVu Sans Mono", size: 7.5pt, mac.slice(0, 5) + "…")],
  ))
}
#let flow(from, to, dst, color: hl) = {
  flow-in(from, color: color)
  for j in to { flow-out(j, color: color) }
  flow-frame(from, dst, color: color)
}
// everyone except `i`
#let others(i) = range(4).filter(j => j != i)

#slide[
  == Hub
  a repeater with many ports

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: star-w, height: 195pt)[
      #star("HUB", sub: "Layer 1")
      #only(2)[#flow(0, (), 2)]
      #only(3)[
        #flow(0, others(0), 2)
        #host-mark(1, false)
        #host-mark(2, true)
        #host-mark(3, false)
      ]
    ]
  ][
    #set text(size: 11pt)
    #uncover("2-")[#block[- Ana sends a frame to Carla]]
    #uncover("3-")[
      #block[- the hub sends it on *all* ports]
      #block[- only Carla keeps it]
      #note-box[a hub copies *bits*, \ it knows no MAC addresses]
    ]
  ]
]

#slide[
  == Hub Broadcast

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: star-w, height: 195pt)[
      #star("HUB", sub: "Layer 1")
      #only(1)[#flow(0, (), "all")]
      #only(2)[
        #flow(0, others(0), "all")
        #for i in others(0) { host-mark(i, true) }
      ]
    ]
  ][
    #set text(size: 11pt)
    #block[- Ana sends a *broadcast*: \ to `ff:ff:ff:ff:ff:ff`]
    #uncover("2-")[
      #block[- the hub sends it on *all* ports]
      #block[- *everyone* keeps it]
    ]
  ]
]

#slide[
  == Collision
  two computers send at the same time

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: star-w, height: 195pt)[
      #star("HUB", sub: "Layer 1")
      #only(2)[
        #flow(0, (), 2)
        #flow(3, (), 1, color: accent)
      ]
      #only(3)[
        #for i in range(4) { flow-out(i, color: bad-color) }
        #pin(center-pt.at(0), center-pt.at(1) - 24pt, icon("💥", size: 24pt))
      ]
    ]
  ][
    #set text(size: 11pt)
    #uncover("2-")[#block[- Ana and Dan send *at the same time*]]
    #uncover("3-")[#block[- the signals mix: a *collision*, everyone receives garbage]]
    #uncover("4-")[#block[- *CSMA/CD*: wait a random time, try again]]
  ]
]

#slide[
  == Why Hubs are Bad

  - only *one computer* can send at a time
  - *half duplex*: send or receive, not both
  - the bandwidth is *shared* by everyone
  - *no privacy*: everyone receives all the frames

  #uncover(2)[
    #note-box[💡 hubs were replaced by *switches*]
  ]
]

// ---------------------------------------------------------------------------
// Switch
// ---------------------------------------------------------------------------

// the MAC address table of the switch on a given step: each row is
// (mac, port, step it is learned on); the row learned on this step is highlighted
#let mac-table(rows, step) = {
  set text(size: 9pt)
  let shown = rows.filter(r => r.at(2) <= step)
  table(
    columns: (88pt, 36pt),
    inset: 5pt,
    align: (left, center),
    stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(200)) },
    fill: (x, y) => if y == 0 { accent } else if shown.at(y - 1).at(2) == step { hl-bg } else { none },
    table.header(text(fill: white, weight: "bold")[MAC address], text(fill: white, weight: "bold")[Port]),
    ..shown.map(((mac, port, s)) => (raw(mac), [#port])).flatten(),
  )
}

#let full-table = mac-table(
  (("5c:8f:2a:...", 1, 0), ("e4:3b:71:...", 2, 0), ("08:d1:6e:...", 3, 0), ("f0:9e:4a:...", 4, 0)),
  99,
)

#slide[
  == Switch
  a hub that understands frames

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: star-w, height: 195pt)[
      #star("SWITCH", layer: "link", sub: "Layer 2", ports: true)
      #only(2)[#flow(0, (), 2)]
      #only(3)[
        #flow(0, (2,), 2)
        #host-mark(2, true)
      ]
    ]
  ][
    #set text(size: 11pt)
    #block[- a *MAC table*: which computer is on which port]
    #full-table
    #uncover("2-")[#block[- Ana sends a frame to Carla]]
    #uncover("3-")[#block[- Carla is on port 3: \ the switch sends it *only* there]]
  ]
]

#slide[
  == Switch Broadcast

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: star-w, height: 195pt)[
      #star("SWITCH", layer: "link", sub: "Layer 2", ports: true)
      #only(1)[#flow(0, (), "all")]
      #only(2)[
        #flow(0, others(0), "all")
        #for i in others(0) { host-mark(i, true) }
      ]
    ]
  ][
    #set text(size: 11pt)
    #block[- Ana sends a *broadcast*: \ to `ff:ff:ff:ff:ff:ff`]
    #uncover("2-")[
      #block[- the switch sends it on *all* ports, like a hub]
      #block[- *everyone* keeps it]
    ]
  ]
]

#slide[
  == Switch Queues

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #drawing(width: star-w, height: 195pt)[
      #star("SWITCH", layer: "link", sub: "Layer 2", ports: true)
      // the queue (buffer) of port 3
      #let slot(i, full: false) = at(196pt + i * 18pt, 90pt, box(
        width: 16pt,
        height: 14pt,
        radius: 2pt,
        fill: if full { hl-bg } else { white },
        stroke: 1pt + if full { accent } else { luma(150) },
        if full { align(center + horizon, icon("✉️", size: 8pt)) },
      ))
      #for i in range(3) { slot(i) }
      #label(222pt, 82pt, text(size: 7pt, weight: "bold", fill: luma(80))[queue of port 3])
      #only(1)[
        #flow(0, (2,), 2)
        #flow(1, (3,), 3, color: accent)
      ]
      #only(2)[
        #flow(0, (), 2)
        #flow(1, (), 2, color: accent)
      ]
      #only(3)[
        #flow(0, (2,), 2)
        #slot(0, full: true)
      ]
      #only(4)[
        #flow-out(2, color: accent)
        #flow-frame(2, 2, color: accent)
      ]
    ]
  ][
    #set text(size: 11pt)
    #block[- each port is separate: *no collisions*]
    #uncover("2-")[#block[- Ana *and* Bogdan send to Carla]]
    #uncover("3-")[#block[- Bogdan's frame waits in a *queue*]]
    #uncover("5-")[#block[- queue full: the frame is *dropped*]]
  ]
]

#slide[
  == Hub vs Switch

  #text(size: 12pt)[
  #align(center, table(
    columns: (auto, 1fr, 1fr),
    inset: 6pt,
    stroke: 0.6pt + luma(150),
    table.header([], [*Hub*], [*Switch*]),
    [*Layer*], [1 (Physical): bits], [2 (Data Link): frames],
    [*Understands MAC*], [no], [yes, has a MAC address table],
    [*Sends a frame to*], [all ports], [only the destination port],
    [*Collisions*], [yes], [no, frames wait in a queue],
    [*Duplex*], [half], [full],
    [*Bandwidth*], [shared by all], [for each port],
    [*Privacy*], [everyone sees everything], [each one sees its own frames],
  ))
  ]
  #v(0pt)
]
