#import "common.typ": *

#section-cover([Network Layer], [connecting networks], layers: ("network",), note: [IP])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Sections 9.1 - 9.6
  + #tanenbaum
    - Section 1.4 - _Reference Models_
    - Section 5.6 - _The Network Layer in the Internet_
  + #uso-book
    - Section 11.2.1 - _Internet Protocol (IP)_
    - Section 11.4 - _Adresarea IP. Stiva TCP/IP_
]

// ---------------------------------------------------------------------------
// IPv4
// ---------------------------------------------------------------------------

// the bits of an address written with dots, as a string of 32 `0` / `1`
#let addr-bits(addr) = addr.split(".").map(b => {
  let v = int(b)
  range(7, -1, step: -1).map(i => str(calc.rem(calc.quo(v, calc.pow(2, i)), 2))).join()
}).join()

// a string of 32 bits, written back as an address with dots
#let bits-addr(bits) = range(4).map(k => {
  let byte = bits.slice(k * 8, k * 8 + 8)
  str(byte.clusters().fold(0, (acc, b) => acc * 2 + int(b)))
}).join(".")

// The 32 bits of an IP address, with the bytes in decimal above them.
// With `n`, the first `n` bits are the network (in the color of the network
// layer) and the rest the host, with a dashed line where they split.
#let split-drawing(ip, n: none) = drawing(width: 470pt, height: 76pt)[
  #let (x0, cw, gap, rh) = (64pt, 10pt, 7pt, 18pt)
  #let bit-x(i) = x0 + i * cw + calc.floor(i / 8) * gap
  #let net = layer-colors.network
  #let host = layer-colors.application
  #for (k, d) in ip.split(".").enumerate() {
    label(bit-x(k * 8) + 4 * cw, 8pt, text(size: 14pt, weight: "bold", d))
  }
  #for k in range(1, 4) { label(bit-x(k * 8) - gap / 2, 8pt, text(size: 14pt, weight: "bold", ".")) }
  #for (i, b) in addr-bits(ip).clusters().enumerate() {
    let c = if n == none { (fill: luma(248), stroke: luma(160)) } else if i < n { net } else { host }
    at(bit-x(i), 22pt, box(
      width: cw,
      height: rh,
      fill: c.fill,
      stroke: 0.5pt + c.stroke,
      align(center + horizon, text(size: 8pt, font: "DejaVu Sans Mono", b)),
    ))
  }
  #if n != none {
    let cut = if calc.rem(n, 8) == 0 { bit-x(n) - gap / 2 } else { bit-x(n) - 0.5pt }
    place(top + left, line(start: (cut, 20pt), end: (cut, 50pt), stroke: (paint: hl, thickness: 2pt, dash: "dashed")))
    let bracket(x1, x2, color, body) = {
      let yb = 54pt
      wire((x1, yb - 4pt), (x1, yb), stroke: 1.2pt + color)
      wire((x1, yb), (x2, yb), stroke: 1.2pt + color)
      wire((x2, yb - 4pt), (x2, yb), stroke: 1.2pt + color)
      wire(((x1 + x2) / 2, yb), ((x1 + x2) / 2, yb + 4pt), stroke: 1.2pt + color)
      label((x1 + x2) / 2, yb + 13pt, text(size: 9pt, body))
    }
    bracket(bit-x(0), cut - 2pt, net.stroke, [🛣️ *network*: #n bits])
    bracket(cut + 2pt, bit-x(31) + cw, host.stroke, [🏠 *host*: #(32 - n) bits])
  }
]

// a small card with an emoji on the left, for the facts under a drawing
#let fact(e, body, c: (fill: luma(247), stroke: luma(215))) = block(
  width: 100%,
  inset: (x: 8pt, y: 6pt),
  radius: 4pt,
  fill: c.fill,
  stroke: 0.6pt + c.stroke,
  grid(columns: (auto, 1fr), column-gutter: 8pt, align: (center + horizon, left + horizon), icon(e, size: 15pt), body),
)

#slide[
  == IP Address
  version 4 (IPv4)

  #only(1, split-drawing("192.168.1.105"))
  #only(2, split-drawing("192.168.1.105", n: 24))
  #only(3, split-drawing("192.168.1.105", n: 16))
  #only("4-", split-drawing("192.168.1.105", n: 20))

  #set text(size: 10pt)
  #let net = layer-colors.network
  #let host = layer-colors.application
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 8pt,
    row-gutter: 6pt,
    fact("📏", [*32 bits* = 4 bytes, each byte written as a decimal number, from `0` to `255`]),
    fact("🌍", [$2^32 approx$ *4.3 billion* addresses for the whole Internet]),
    uncover("2-", fact("🛣️", [*network*: the street, the same for all the devices in the network], c: net)),
    uncover("2-", fact("🏠", [*host*: the house number, different for every device in the network], c: host)),
    uncover("3-", fact("✂️", [the network part is *not* always 24 bits: here it is *16*])),
    uncover("4-", fact("📐", [it can end *inside a byte*: here it is *20*])),
  )
  #v(0pt)
]

// The IP address, the mask and the network, bit by bit, for a prefix `/n`.
// Step 1 shows the IP address, step 2 the mask, step 3 the network.
// The network bits (the first `n`) are in the color of the network layer,
// the host bits in another color; a dashed line marks where the mask ends.
#let mask-drawing(ip, n) = {
  let mask = range(32).map(i => if i < n { "1" } else { "0" }).join()
  let ip-b = addr-bits(ip)
  let net-b = range(32).map(i => if i < n { ip-b.at(i) } else { "0" }).join()
  let bc-b = range(32).map(i => if i < n { ip-b.at(i) } else { "1" }).join()
  drawing(width: 470pt, height: 128pt)[
    #let (x0, cw, gap, rh) = (40pt, 10pt, 7pt, 15pt)
    #let bit-x(i) = x0 + i * cw + calc.floor(i / 8) * gap
    #let net = layer-colors.network
    #let host = layer-colors.application
    #let strip(y, bits, dec, name, faded: false) = {
      label(x0 - 34pt, y + rh / 2, text(size: 8pt, weight: "bold", name))
      for (i, b) in bits.clusters().enumerate() {
        let c = if i < n { net } else { host }
        let dim = faded and i >= n
        at(bit-x(i), y, box(
          width: cw,
          height: rh,
          fill: if dim { luma(245) } else { c.fill },
          stroke: 0.5pt + if dim { luma(210) } else { c.stroke },
          align(center + horizon, text(size: 7.5pt, font: "DejaVu Sans Mono", fill: if dim { luma(170) } else { black }, b)),
        ))
      }
      at(bit-x(32) + 4pt, y + 2pt, text(size: 8.5pt, font: "DejaVu Sans Mono", weight: "bold", dec))
    }
    // where the mask ends: between two bytes, or inside a byte
    #let cut = if calc.rem(n, 8) == 0 { bit-x(n) - gap / 2 } else { bit-x(n) - 0.5pt }
    #tag(cut, 6pt, text(weight: "bold", "/" + str(n)), fill: hl-bg, stroke: 1pt + hl, size: 8pt)
    // the bytes, in decimal, above the IP address
    #for (k, d) in ip.split(".").enumerate() {
      label(bit-x(k * 8) + 4 * cw, 20pt, text(size: 9pt, weight: "bold", d))
    }
    #strip(28pt, ip-b, ip, [IP])
    #uncover("2-")[#strip(48pt, mask, bits-addr(mask), [mask])]
    #uncover("3-")[#strip(68pt, net-b, bits-addr(net-b), text(fill: hl)[network])]
    #uncover("4-")[#strip(88pt, bc-b, bits-addr(bc-b), text(fill: hl)[broadcast])]
    #place(top + left, line(start: (cut, 26pt), end: (cut, 106pt), stroke: (paint: hl, thickness: 2pt, dash: "dashed")))
    // the two parts
    #let bracket(x1, x2, color, body) = {
      let yb = 110pt
      wire((x1, yb - 4pt), (x1, yb), stroke: 1.2pt + color)
      wire((x1, yb), (x2, yb), stroke: 1.2pt + color)
      wire((x2, yb - 4pt), (x2, yb), stroke: 1.2pt + color)
      wire(((x1 + x2) / 2, yb), ((x1 + x2) / 2, yb + 4pt), stroke: 1.2pt + color)
      label((x1 + x2) / 2, yb + 13pt, text(size: 9pt, body))
    }
    #bracket(bit-x(0), cut - 2pt, net.stroke, [*network*: #n bits])
    #bracket(cut + 2pt, bit-x(31) + cw, host.stroke, [*host*: #(32 - n) bits])
  ]
}

// a big address (or prefix) in a colored box, with a caption under it;
// the caption may be wider than the box, it does not move the boxes apart
#let big-chip(body, c, caption, size: 24pt) = context {
  let chip = box(
    fill: c.fill,
    stroke: 1pt + c.stroke,
    radius: 4pt,
    inset: (x: 8pt, y: 6pt),
    text(font: "DejaVu Sans Mono", size: size, weight: "bold", body),
  )
  let w = measure(chip).width
  box(stack(
    spacing: 4pt,
    chip,
    box(width: w, height: 11pt, place(top + center, box(width: 300pt, align(center, text(size: 9pt, caption))))),
  ))
}

// the bits of a mask `/n`, the `1` bits in the color of the network layer,
// the `0` bits in another color
#let mask-bits(n) = {
  let bits = range(32).map(i => {
    let b = if i < n { "1" } else { "0" }
    let c = if i < n { layer-colors.network.stroke.darken(20%) } else { layer-colors.application.stroke.darken(20%) }
    let dot = if calc.rem(i, 8) == 7 and i < 31 { text(fill: luma(120), ".") }
    text(fill: c, b) + dot
  })
  text(font: "DejaVu Sans Mono", size: 15pt, weight: "bold", bits.join())
}

#slide[
  == Network Mask
  which bits of the address are the network

  #let ip-c = layer-colors.physical
  #let mask-c = (fill: hl-bg, stroke: hl)
  #align(center)[
    #big-chip("192.168.1.105", ip-c, [IP address])#big-chip("/24", mask-c, [mask as a *prefix*: the number of `1` bits])
    #uncover("2-")[
      #v(-2pt)
      #text(size: 10pt, fill: luma(90))[the same thing, written in the other format]
      #v(-2pt)
      #big-chip("192.168.1.105", ip-c, [IP address])
      #h(14pt)
      #big-chip("255.255.255.0", mask-c, [mask written like an address])
    ]
    #uncover("3-")[
      #v(-2pt)
      #mask-bits(24)
      #v(-8pt)
      #text(size: 9pt)[#text(fill: layer-colors.network.stroke.darken(20%), weight: "bold")[24 bits of `1`]: the *network*,
        #text(fill: layer-colors.application.stroke.darken(20%), weight: "bold")[8 bits of `0`]: the *host*]
    ]
  ]

  #v(0pt)
]

// the statements under a mask drawing, one for each step: what the mask is,
// the network address, the addresses in the network, and two examples
#let mask-facts(mask, network, broadcast, devices, same, other) = {
  set text(size: 10pt)
  let row(step, term, body) = uncover(step, block(below: 0.5em, grid(
    columns: (62pt, 1fr),
    text(weight: "bold", term), body,
  )))
  row("2-", [mask], mask)
  row("3-", [network], [all the host bits `0` = #network: the address of the network itself])
  row("4-", [broadcast], [all the host bits `1` = #broadcast: a packet for *everyone* in the network])
  row("5-", [devices], devices)
  row("5-", [examples], [#same: ✅ *the same* network #h(1em) #other: ❌ *another* network, through a router])
}

#slide[
  == Network Mask /24
  the mask ends at the end of a byte (a multiple of 8)

  #mask-drawing("192.168.1.105", 24)

  #mask-facts(
    [24 bits of `1` = `255.255.255.0`],
    [`192.168.1.0`],
    [`192.168.1.255`],
    [`192.168.1.1` to `192.168.1.254`: *254* devices],
    [`192.168.1.20`],
    [`192.168.2.20`],
  )
  #v(0pt)
]

#slide[
  == Network Mask /20
  the mask ends in the middle of a byte (not a multiple of 8)

  #mask-drawing("172.16.45.130", 20)

  #mask-facts(
    [20 bits of `1` = `255.255.240.0` (`11110000` = `240`)],
    [`172.16.32.0`],
    [`172.16.47.255`],
    [`172.16.32.1` to `172.16.47.254`: *4094* devices],
    [`172.16.40.1`],
    [`172.16.50.1`],
  )
  #v(0pt)
]

#slide[
  == Special Addresses

  #v(1em)
  #align(center, text(size: 12pt, table(
    columns: (auto, auto, 1fr),
    inset: 7pt,
    align: (center + horizon, left + horizon, left + horizon),
    stroke: 0.6pt + luma(170),
    table.header([], [*Address*], [*Meaning*]),
    text(size: 1.4em, "🔁"), [`127.0.0.1`], [*loopback* (`localhost`): this computer, the packets never leave it],
    text(size: 1.4em, "🔒"), [`10.0.0.0/8` \ `172.16.0.0/12` \ `192.168.0.0/16`], [*private* networks: not used on the Internet, free for everyone at home or at work],
    text(size: 1.4em, "🤷"), [`169.254.0.0/16`], [_link local_: no one gave us an address, so the computer picked one by itself],
  )))
]

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

#let two-nets(r-highlight: false, router: true) = {
  area(5pt, 5pt, 157pt, 175pt, [network `192.168.1.0/24`])
  area(318pt, 5pt, 157pt, 175pt, [network `192.168.2.0/24`], name-at: top + right)
  let a = (45pt, 55pt)
  let b = (45pt, 140pt)
  let s1 = (130pt, 97pt)
  let r = (240pt, 97pt)
  let s2 = (350pt, 97pt)
  let c = (435pt, 55pt)
  let d = (435pt, 140pt)
  for p in (a, b) { wire(p, s1) }
  for p in (c, d) { wire(p, s2) }
  if router {
    wire(s1, r)
    wire(r, s2)
  }
  host(..a, "Ana", addr: [192.168.1.10 \ #text(fill: luma(110))[5c:8f:2a:91:d4:07]], size: 24pt)
  host(..b, "Bogdan", addr: [192.168.1.11 \ #text(fill: luma(110))[e4:3b:71:0c:9a:52]], size: 24pt)
  host(..c, "Carla", addr: [192.168.2.20 \ #text(fill: luma(110))[08:d1:6e:b3:47:ac]], size: 24pt)
  host(..d, "Dan", addr: [192.168.2.21 \ #text(fill: luma(110))[f0:9e:4a:c2:16:3d]], size: 24pt)
  netdev(..s1, "switch", size: 16pt)
  netdev(..s2, "switch", size: 16pt)
  if router {
    netdev(..r, "router", name: "Router", size: 30pt, highlight: r-highlight)
    sees-stack(r.at(0), r.at(1) + 36pt, "network")
    // the two cards of the router, each one in its own network
    label(192pt, 80pt, align(center, text(size: 5pt, font: "DejaVu Sans Mono")[*eth0* \ 192.168.1.1 \ #text(fill: luma(110))[70:b5:e8:2d:91:4c]]))
    label(288pt, 80pt, align(center, text(size: 5pt, font: "DejaVu Sans Mono")[*eth1* \ 192.168.2.1 \ #text(fill: luma(110))[b8:27:c4:6a:0e:93]]))
  }
}

// a thick arrow along the wire from p to q, a bit shorter at both ends
#let hop(p, q, color: hl, from: 0.2, to: 0.8) = {
  let at-t(t) = (p.at(0) + (q.at(0) - p.at(0)) * t, p.at(1) + (q.at(1) - p.at(1)) * t)
  draw-arrow(at-t(from), at-t(to), color: color, thickness: 2.4pt, head: 7pt)
}

// a frame (layer 2, MAC addresses) carrying a packet (layer 3, IP addresses);
// the color of the frame says what the sender knows about the MAC address:
// "unknown" not yet, "found" found, "missing" not found, "gateway" the gateway's
#let mac-states = (
  unknown: (fill: luma(245), stroke: luma(150)),
  found: (fill: ok-color.lighten(88%), stroke: ok-color),
  missing: (fill: bad-color.lighten(88%), stroke: bad-color),
  gateway: (fill: rgb("fff3bf"), stroke: rgb("f08c00")),
)
#let pkt(x, y, mac, ip, state: "found") = {
  let c = mac-states.at(state)
  let net = layer-colors.network
  pin(x, y, box(
    fill: c.fill,
    stroke: 1.2pt + c.stroke,
    radius: 3pt,
    inset: (x: 3pt, y: 2pt),
    stack(
      spacing: 2pt,
      text(size: 7.5pt)[#icon("✉️", size: 8pt) *MAC* #mac],
      box(fill: net.fill, stroke: 0.6pt + net.stroke, radius: 2pt, inset: (x: 3pt, y: 1.5pt), text(size: 7.5pt)[*IP* #ip]),
    ),
  ))
}
// the path already traveled: a dashed line through the points
#let trail(..pts) = {
  let ps = pts.pos()
  for i in range(ps.len() - 1) {
    wire(ps.at(i), ps.at(i + 1), stroke: (paint: hl, thickness: 2.5pt, dash: "dashed", cap: "round"))
  }
}
// the middle of a wire
#let mid(p, q) = ((p.at(0) + q.at(0)) / 2, (p.at(1) + q.at(1)) / 2)
#let ok-mark(p, dx: 26pt) = pin(p.at(0) + dx, p.at(1) - 4pt, icon("✅", size: 14pt))

// what a device found out: the MAC address for an IP address
#let mac-found(x, y, who, ip, mac, color: accent) = pin(x, y, box(
  fill: white,
  stroke: 1pt + color,
  radius: 4pt,
  inset: (x: 5pt, y: 3pt),
  text(size: 7.5pt)[🔎 #who: #raw(ip) → #if mac == none { text(fill: bad-color, weight: "bold")[???] } else { raw(mac) }],
))

#slide[
  == Router

  #let (a, b, s1, r, s2, c) = ((45pt, 55pt), (45pt, 140pt), (130pt, 97pt), (240pt, 97pt), (350pt, 97pt), (435pt, 55pt))
  // where the packet is drawn, next to each device
  #let (at-a, at-s1, at-b, at-r, at-s2, at-c) = (
    (108pt, 42pt),
    (130pt, 124pt),
    (108pt, 140pt),
    (240pt, 50pt),
    (350pt, 124pt),
    (372pt, 42pt),
  )
  #let ip-ab = [Ana → Bogdan]
  #let ip-ac = [Ana → Carla]
  #align(center, scale(96%, reflow: true, drawing(height: 185pt)[
    #only("1-4")[#two-nets(router: false)]
    #only("5-")[#two-nets(r-highlight: true)]
    // the gateway of A: none without a router, the router after
    #only(4)[#tag(55pt, 104pt, [🚪 gateway: *none*], stroke: 1pt + bad-color, size: 7.5pt)]
    #only("5-")[#tag(55pt, 104pt, [🚪 gateway: `192.168.1.1`], fill: hl-bg, stroke: 1pt + hl, size: 7.5pt)]

    // 1 - 3: to B, in the same network
    #only(1)[#pkt(..at-a, [Ana → ?], ip-ab, state: "unknown")]
    #only(2)[
      #mac-found(240pt, 40pt, [Ana], "192.168.1.11", "e4:3b:…", color: ok-color)
      #pkt(..at-a, [Ana → *Bogdan*], ip-ab)
    ]
    #only(3)[
      #trail(a, s1, b)
      #pkt(..at-b, [Ana → *Bogdan*], ip-ab)
      #ok-mark(b, dx: -26pt)
    ]

    // 4: to C, in another network, without a router
    #only(4)[
      #mac-found(240pt, 40pt, [Ana], "192.168.2.20", none, color: bad-color)
      #pkt(..at-a, [Ana → *???*], ip-ac, state: "missing")
      #pin(240pt, 97pt, icon("❌", size: 26pt))
      #tag(240pt, 130pt, text(fill: bad-color)[`Network is unreachable`], stroke: 1pt + bad-color, size: 7.5pt)
    ]

    // 5 - 7: with a router
    #only(5)[
      #mac-found(240pt, 22pt, [Ana], "192.168.1.1", "70:b5:…", color: rgb("f08c00"))
      #pkt(..at-a, [Ana → *Router*], ip-ac, state: "gateway")
    ]
    #only(6)[
      #trail(a, s1, r)
      #mac-found(240pt, 18pt, [Router], "192.168.2.20", "08:d1:…", color: ok-color)
      #pkt(..at-r, [Router → *Carla*], ip-ac)
    ]
    #only("7-")[
      #trail(a, s1, r, s2, c)
      #pkt(..at-c, [Router → *Carla*], ip-ac)
      #ok-mark(c)
    ]
  ]))

  // what happens, one card for each step
  #let bad = (fill: bad-color.lighten(90%), stroke: bad-color)
  #let good = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📦", [Ana has a packet for Bogdan `192.168.1.11`: *the same network*]))
    #only(2, fact("🔎", [Ana gets *the MAC address of Bogdan* and puts it on the frame]))
    #only(3, fact("✅", [the switch delivers the frame to Bogdan], c: good))
    #only(4, fact("❌", [Carla `192.168.2.20` is in *another network*: Ana cannot get her MAC address], c: bad))
    #only(5, fact("🚪", [Ana sends it to her *gateway* `192.168.1.1`, the router: she gets *its MAC address*, the IP is still Carla's]))
    #only(6, fact("🔁", [the router gets *the MAC address of Carla* and puts the *same packet* in a *new frame*]))
    #only(7, fact("✅", [Carla gets the packet: the MAC addresses changed, the IP addresses *stayed the same*], c: good))
    #only("8-", grid(
      columns: (1fr, 1fr),
      column-gutter: 8pt,
      fact("🔌", [a computer with *two or more* network cards, *one in each network*], c: layer-colors.network),
      fact("📬", [forwards *packets* from one network to another: *layer 3*], c: layer-colors.network),
    ))
  ]))
]

#slide[
  == The Internet
  a network of routers

  #drawing(height: 190pt)[
    #let routers = (
      (110pt, 50pt), (110pt, 140pt), (220pt, 30pt), (240pt, 120pt), (340pt, 60pt), (360pt, 150pt),
    )
    #let links = ((0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (1, 5))
    #let path = ((0, 3), (3, 4))
    #for (i, j) in links { wire(routers.at(i), routers.at(j)) }
    #wire((30pt, 50pt), routers.at(0))
    #wire(routers.at(4), (450pt, 60pt))
    #uncover("2-")[
      #wire((30pt, 50pt), routers.at(0), stroke: 2.5pt + hl)
      #for (i, j) in path { wire(routers.at(i), routers.at(j), stroke: 2.5pt + hl) }
      #wire(routers.at(4), (450pt, 60pt), stroke: 2.5pt + hl)
    ]
    #for (i, p) in routers.enumerate() { netdev(..p, "router", size: 20pt) }
    #host(30pt, 50pt, "home", size: 24pt)
    #host(450pt, 60pt, "upb.ro", kind: "server", size: 24pt)
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1)[- networks of companies, universities and Internet Service Providers (ISP) connected by routers]
    #only("2-")[- each router only knows the *next hop*, if a link fails, packets take another path]
  ]))
]

#slide[
  == Hub, Switch, AP, Router

  #text(size: 10pt)[
  #align(center, table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    inset: 5pt,
    stroke: 0.6pt + luma(170),
    align: left + horizon,
    table.header([], align(center, pic("hub", size: 14pt)) + [*Hub*], align(center, pic("switch", size: 14pt))
      + [*Switch*], align(center, pic("wifi-router", size: 20pt)) + [*Access Point*], align(center, pic(
      "router",
      size: 20pt,
    ))
      + [*Router*]),
    [*Layer*],
    table.cell(fill: layer-colors.physical.fill)[1: bits],
    table.cell(fill: layer-colors.link.fill)[2: frames],
    table.cell(fill: layer-colors.link.fill)[2: frames],
    table.cell(fill: layer-colors.network.fill)[3: packets],

    [*Uses*], [nothing], [MAC addresses], [MAC addresses], [IP addresses],
    [*Sends to*], [all ports], [the destination port], [the destination device (radio)], [the next network],
    [*Medium*], [shared cable], [one cable per port], [shared radio], [one per network],
    [*Connects*], [devices], [devices of one network], [wireless devices to a wired network], [*different networks*],
  ))
  ]
  #v(0pt)
]

#slide[
  == IPv6
  the next version of IP

  - IPv4 has only 4.3 billion addresses, they *ran out* in 2011
  - IPv6: *128 bits*, $2^128 approx 3.4 times 10^38$ addresses
  - written as 8 groups of 4 hexadecimal digits
    - `2001:0db8:0000:0000:0000:0000:0000:0001`
    - leading zeros and one run of zero groups can be skipped: `2001:db8::1`
  - `::1` - loopback, `fe80::/10` - link local
  - works *next to* IPv4 (_dual stack_), most computers have both

  #note-box[💡 in this lecture we use IPv4]
]
