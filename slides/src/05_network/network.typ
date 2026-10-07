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

#let octet-box(x, dec, bin, layer: none) = {
  at(x, 0pt, field(text(size: 14pt, dec), 100pt, layer: layer, height: 28pt))
  at(x, 32pt, box(width: 100pt, align(center, text(size: 9pt, font: "DejaVu Sans Mono", bin))))
}

#slide[
  == IP Address
  version 4 (IPv4)

  #drawing(height: 95pt)[
    #at(10pt, 10pt)[
      #octet-box(0pt, "192", "11000000", layer: "network")
      #octet-box(115pt, "168", "10101000", layer: "network")
      #octet-box(230pt, "1", "00000001", layer: "network")
      #octet-box(345pt, "105", "01101001", layer: "application")
      #for x in (104pt, 219pt, 334pt) { at(x, 8pt, text(size: 16pt, weight: "bold", ".")) }
    ]
    #uncover("2-")[
      #wire((10pt, 68pt), (340pt, 68pt), stroke: 1pt + layer-colors.network.stroke)
      #label(175pt, 80pt, [*network*: the street])
      #wire((355pt, 68pt), (455pt, 68pt), stroke: 1pt + layer-colors.application.stroke)
      #label(405pt, 80pt, [*host*: the number])
    ]
  ]

  - *32 bits* (4 bytes), written as 4 decimal numbers (0 - 255): `192.168.1.105`
  - $2^32 approx 4.3$ billion addresses
  #uncover("2-")[#block[- two parts: the *network* and the *host* (the device in that network)]]
  #uncover("3-")[#block[- how many bits are the network? the *network mask* says it]]
]

#let bits-row(name, bits, dec, n: 24, color: black) = {
  let groups = bits.split(".")
  let cells = ()
  for (g, byte) in groups.enumerate() {
    let s = for (i, b) in byte.clusters().enumerate() {
      let pos = g * 8 + i
      text(fill: if pos < n { layer-colors.network.stroke.darken(20%) } else { layer-colors.application.stroke.darken(20%) }, b)
    }
    cells.push(s)
  }
  (text(weight: "bold", fill: color, name), ..cells, text(fill: color, dec))
}

#slide[
  == Network Mask
  which bits are the network

  #text(size: 10pt)[
  #align(center, table(
    columns: 6,
    stroke: none,
    inset: (x: 5pt, y: 4pt),
    align: (left, center, center, center, center, left),
    ..bits-row("IP address", "11000000.10101000.00000001.01101001", raw("192.168.1.105")).map(c => text(
      font: "DejaVu Sans Mono",
      c,
    )),
    ..bits-row("Mask /24", "11111111.11111111.11111111.00000000", raw("255.255.255.0")).map(c => uncover(
      "2-",
      text(font: "DejaVu Sans Mono", c),
    )),
    table.hline(stroke: 0.8pt),
    ..bits-row("Network (AND)", "11000000.10101000.00000001.00000000", raw("192.168.1.0"), color: hl).map(c => uncover(
      "3-",
      text(font: "DejaVu Sans Mono", c),
    )),
  ))

  #uncover("2-")[#block[- the mask has `1` for the network bits: `/24` = 24 bits of `1` = `255.255.255.0`]]
  #uncover("3-")[#block[- network address = IP address *AND* mask: `192.168.1.0/24`]]
  #uncover("4-")[
    #block[- `192.168.1.20` is in *the same network*: talk to it directly (layer 2)]
    #block[- `192.168.2.20` is in *another network*: go through a *router*]
  ]
  ]
  #v(0pt)
]

#slide[
  == Network Mask /20
  the mask can end in the middle of a byte

  // the 32 bits as small cells, grouped in bytes; the network bits (the first
  // `n`) in the color of the network layer, the host bits in another color
  #drawing(width: 470pt, height: 110pt)[
    #let n = 20
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
    // the bytes, in decimal, above the IP address
    #for (k, d) in ("172", "16", "45", "130").enumerate() {
      label(bit-x(k * 8) + 4 * cw, 10pt, text(size: 9pt, weight: "bold", d))
    }
    #strip(20pt, "10101100000100000010110110000010", "172.16.45.130", [IP])
    #uncover("2-")[#strip(42pt, "11111111111111111111000000000000", "255.255.240.0", [mask])]
    #uncover("3-")[#strip(64pt, "10101100000100000010000000000000", "172.16.32.0", text(fill: hl)[network], faded: true)]
    // the cut, after bit 20, in the middle of the third byte
    #let cut = bit-x(n) - 0.5pt
    #place(top + left, line(start: (cut, 14pt), end: (cut, 86pt), stroke: (paint: hl, thickness: 2pt, dash: "dashed")))
    #tag(cut, 7pt, text(weight: "bold", "/20"), fill: hl-bg, stroke: 1pt + hl, size: 8pt)
    // the two parts
    #let bracket(x1, x2, color, body) = {
      let yb = 90pt
      wire((x1, yb - 4pt), (x1, yb), stroke: 1.2pt + color)
      wire((x1, yb), (x2, yb), stroke: 1.2pt + color)
      wire((x2, yb - 4pt), (x2, yb), stroke: 1.2pt + color)
      wire(((x1 + x2) / 2, yb), ((x1 + x2) / 2, yb + 4pt), stroke: 1.2pt + color)
      label((x1 + x2) / 2, yb + 13pt, text(size: 9pt, body))
    }
    #bracket(bit-x(0), bit-x(n) - 2pt, net.stroke, [*network*: 20 bits])
    #bracket(bit-x(n) + 1pt, bit-x(31) + cw, host.stroke, [*host*: 12 bits])
  ]

  #set text(size: 10.5pt)
  #uncover("2-")[#block[- `/20`: 20 bits of `1`, the third byte is `11110000` = `240`, the mask is `255.255.240.0`]]
  #uncover("3-")[#block[- network: `172.16.45.130` *AND* `255.255.240.0` = `172.16.32.0/20`]]
  #uncover("4-")[
    #block[- 12 host bits: `172.16.32.0` - `172.16.47.255`, $2^12 - 2 = 4094$ devices]
    #block[- `172.16.40.1` is in *the same network*, `172.16.50.1` is in *another network*]
  ]
  #v(0pt)
]

#slide[
  == Special Addresses

  #text(size: 10.5pt)[
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #table(
      columns: 2,
      inset: 5pt,
      stroke: 0.6pt + luma(170),
      table.header([*Address*], [*Meaning*]),
      [`192.168.1.0`], [the network itself],
      [`192.168.1.255`], [*broadcast*: all hosts of the network],
      [`192.168.1.1` - `.254`], [hosts: $2^8 - 2 = 254$ addresses],
      [`127.0.0.1`], [*loopback* (`localhost`): this computer],
      [`10.0.0.0/8` \ `172.16.0.0/12` \ `192.168.0.0/16`], [*private* networks: not used on the Internet, free for everyone at home],
      [`169.254.0.0/16`], [_link local_: no one gave us an address],
    )
  ][
    #table(
      columns: 3,
      inset: 5pt,
      stroke: 0.6pt + luma(170),
      table.header([*Prefix*], [*Mask*], [*Hosts*]),
      [`/8`], [`255.0.0.0`], [16 777 214],
      [`/16`], [`255.255.0.0`], [65 534],
      [`/24`], [`255.255.255.0`], [254],
      [`/30`], [`255.255.255.252`], [2],
    )
  ]
  ]
  #v(0pt)
]

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

#let two-nets(r-highlight: false) = {
  area(5pt, 5pt, 175pt, 175pt, [network `192.168.1.0/24`])
  area(300pt, 5pt, 175pt, 175pt, [network `192.168.2.0/24`], name-at: top + right)
  let a = (45pt, 55pt)
  let b = (45pt, 140pt)
  let s1 = (130pt, 97pt)
  let r = (240pt, 97pt)
  let s2 = (350pt, 97pt)
  let c = (435pt, 55pt)
  let d = (435pt, 140pt)
  for p in (a, b) { wire(p, s1) }
  for p in (c, d) { wire(p, s2) }
  wire(s1, r)
  wire(r, s2)
  host(..a, "A", addr: "192.168.1.10", size: 24pt)
  host(..b, "B", addr: "192.168.1.11", size: 24pt)
  host(..c, "C", addr: "192.168.2.20", size: 24pt)
  host(..d, "D", addr: "192.168.2.21", size: 24pt)
  netdev(..s1, "switch", size: 16pt)
  netdev(..s2, "switch", size: 16pt)
  netdev(..r, "router", name: "Router", size: 30pt, highlight: r-highlight)
  sees-stack(r.at(0), r.at(1) + 36pt, "network")
  label(192pt, 80pt, text(size: 6pt, font: "DejaVu Sans Mono")[eth0 \ 192.168.1.1])
  label(288pt, 80pt, text(size: 6pt, font: "DejaVu Sans Mono")[eth1 \ 192.168.2.1])
}

#slide[
  == Router
  connects networks

  #drawing(height: 185pt)[#two-nets(r-highlight: true)]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    - a computer with *two or more* network cards, one (and one IP address) *in each network*
    - forwards *packets* from one network to another: works on *layer 3*
  ]))
]

#slide[
  == Sending a Packet
  from A to C

  #drawing(height: 185pt)[
    #two-nets()
    #only(3)[
      #frame(240pt, 30pt, [MAC: A #arrow Router \ IP: A #arrow C])
      #draw-arrow((60pt, 50pt), (200pt, 85pt), color: hl)
    ]
    #only(4)[
      #frame(240pt, 30pt, [#text(fill: bad-color)[MAC: Router #arrow C] \ IP: A #arrow C])
      #draw-arrow((280pt, 85pt), (420pt, 50pt), color: hl)
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1)[- A wants to send a packet to `192.168.2.20`]
    #only(2)[- A: `192.168.2.20` is not in my network, I send it to my *gateway*, `192.168.1.1`]
    #only(3)[- A puts the packet in a frame for the *MAC of the router* (found with ARP: _who has 192.168.1.1?_)]
    #only(4)[- the router puts the packet in a *new frame* for C: the MAC addresses change at every hop, the IP addresses *stay the same*]
  ]))
]

#slide[
  == Routing Table
  where to send each packet

  #reveal-terminal(before: none, lines: (1, 3), full: false)[```terminal
  $ ip route
  default via 192.168.1.1 dev wlp2s0 proto dhcp src 192.168.1.105 metric 600
  192.168.1.0/24 dev wlp2s0 proto kernel scope link src 192.168.1.105 metric 600
  ```]

  #uncover("2-")[
    #block[- `192.168.1.0/24 dev wlp2s0` - my network: send *directly* on the `wlp2s0` card]
  ]
  #uncover("3-")[
    #block[- `default via 192.168.1.1` - everything else: send to the *default gateway* (the router)]
    #note-box[💡 a computer usually has a single router, the *default gateway*, routers have bigger tables]
  ]
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
