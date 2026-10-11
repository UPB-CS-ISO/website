#import "common.typ": *

#section-cover([Routing], [from one network to another], layers: ("network",), note: [routers])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.5 - _Routes and the Kernel Routing Table_
      - Section 9.6 - _The Default Gateway_
      - Section 9.22 - _Private Networks (IPv4)_
      - Section 9.23 - _Network Address Translation (IP Masquerading)_
  + #tanenbaum
    - Section 5.2 - _Routing Algorithms_
    - Section 5.6 - _The Network Layer in the Internet_
  + #uso-book
    - Section 11.4.3 - _Limita de adrese IP_
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
      #trail(a, s1, r)
      #trail(r, s2, c)
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

// two homes with the same private network, talking to the same server
#slide[
  == Why NAT?
  two homes, the same private addresses

  #drawing(height: 172pt)[
    #let homes = (
      (y: 42pt, name: "Ana", who: [Ana's home], public: "203.0.113.42"),
      (y: 130pt, name: "Bogdan", who: [Bogdan's home], public: "198.51.100.7"),
    )
    #let (cx, cy) = (300pt, 86pt)
    #let server = (430pt, 86pt)
    // the wires are dotted inside the cloud: the way through the Internet is not known
    #let dotted = (paint: luma(90), thickness: 1.2pt, dash: "dotted")
    // where the wire from (x, y) to the center enters the cloud (an ellipse)
    #let edge(x, y) = {
      let (dx, dy) = ((x - cx).pt(), (y - cy).pt())
      let t = 1 / calc.sqrt(calc.pow(dx / 39, 2) + calc.pow(dy / 20, 2))
      (cx + dx * t * 1pt, cy + dy * t * 1pt)
    }
    #for h in homes {
      area(5pt, h.y - 38pt, 190pt, 78pt, [#h.who: `192.168.1.0/24`])
      wire((45pt, h.y), (150pt, h.y))
      wire((150pt, h.y), edge(150pt, h.y))
      wire(edge(150pt, h.y), (cx, cy), stroke: dotted)
    }
    #wire((cx, cy), edge(..server), stroke: dotted)
    #wire(edge(..server), server)
    // an arrow next to the wire from p to q, moved `off` to its left
    #let along(p, q, off, color: hl) = {
      let (dx, dy) = ((q.at(0) - p.at(0)).pt(), (q.at(1) - p.at(1)).pt())
      let len = calc.sqrt(dx * dx + dy * dy)
      let (nx, ny) = (dy / len * off, -dx / len * off)
      let at-t(t) = (p.at(0) + dx * t * 1pt + nx, p.at(1) + dy * t * 1pt + ny)
      draw-arrow(at-t(0.4), at-t(0.92), color: color, thickness: 2pt, head: 6pt)
    }
    #for h in homes {
      host(45pt, h.y, h.name, addr: "192.168.1.105", size: 24pt)
      netdev(150pt, h.y, "router", name: "router", sub: if h.public != none { uncover("4-", h.public) }, size: 22pt)
    }
    #pin(cx, cy, pic("cloud", size: 50pt))
    #host(..server, "server", kind: "server", addr: "141.85.220.33", size: 28pt)

    // step 2: both packets have the same source
    #only(2)[
      #along((150pt, 42pt), edge(150pt, 42pt), -9pt)
      #along((150pt, 130pt), edge(150pt, 130pt), 9pt)
      #frame(232pt, 44pt)[from `192.168.1.105`]
      #frame(232pt, 130pt)[from `192.168.1.105`]
    ]
    // step 3: the answer: to which of them?
    #only(3)[
      #along(server, edge(..server), 9pt, color: bad-color)
      #frame(380pt, 66pt, color: bad-color)[to `192.168.1.105`]
      #pin(cx, cy - 34pt, icon("❓", size: 16pt))
      #pin(196pt, 64pt, icon("❌", size: 11pt))
      #pin(196pt, 108pt, icon("❌", size: 11pt))
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1, fact("🏠", [both homes use `192.168.1.0/24`: *private* addresses are free for everyone, so the two PCs have the *same* address]))
    #only(2, fact("📦", [Ana and Bogdan send a packet to the server: both come *from* `192.168.1.105`]))
    #only(3, fact("❓", [the answer goes *to* `192.168.1.105`, but *which one*? millions of homes have it, so Internet routers *drop* packets for private addresses], c: (fill: bad-color.lighten(92%), stroke: bad-color)))
    #only(4, fact("🌍", [why not a *public* address for every device? IPv4 has only $2^32 approx 4.3$ billion addresses, and there are many more devices: each home gets *one* public address, for its router]))
  ]))
]

// NAT: the router changes the private address of a packet into its public
// address, and back for the answer
#slide[
  == NAT
  _Network Address Translation_

  #drawing(height: 150pt)[
    #let pc = (50pt, 75pt)
    #let r = (230pt, 75pt)
    #let cl = (335pt, 75pt)
    #let server = (440pt, 75pt)
    #area(5pt, 5pt, 255pt, 140pt, [Ana's home (private): `192.168.1.0/24`])
    #wire(pc, r)
    // the wire is dotted inside the cloud: the way through the Internet is not known
    #let (c1, c2) = ((cl.at(0) - 36pt, cl.at(1)), (cl.at(0) + 36pt, cl.at(1)))
    #wire(r, c1)
    #wire(c1, c2, stroke: (paint: luma(90), thickness: 1.2pt, dash: "dotted"))
    #wire(c2, server)
    #host(..pc, "Ana", addr: "192.168.1.105", size: 26pt)
    #netdev(..r, "router", name: "router", sub: "203.0.113.42", size: 28pt, highlight: true)
    #pin(..cl, pic("cloud", size: 46pt))
    #host(..server, "server", kind: "server", addr: "141.85.220.33", size: 28pt)
    // a packet next to the wire, with an arrow showing where it goes
    #let go(p, q, body, color: hl, back: false) = {
      // above the wire going out, below coming back, clear of the cloud
      let dy = if back { 1 } else { -1 }
      let (x1, x2) = (p.at(0) + 0.25 * (q.at(0) - p.at(0)), p.at(0) + 0.75 * (q.at(0) - p.at(0)))
      draw-arrow((x1, p.at(1) + dy * 26pt), (x2, p.at(1) + dy * 26pt), color: color, thickness: 2pt, head: 6pt)
      frame((p.at(0) + q.at(0)) / 2, p.at(1) + dy * 44pt, body, color: color)
    }
    #let changed(it) = text(fill: bad-color, weight: "bold", it)
    #only(2)[#go(pc, r)[from `192.168.1.105` \ to `141.85.220.33`]]
    #only(3)[#go(r, server)[from #changed(`203.0.113.42`) \ to `141.85.220.33`]]
    #only(4)[#go(server, r, color: ok-color, back: true)[from `141.85.220.33` \ to `203.0.113.42`]]
    #only(5)[
      #go(r, pc, color: ok-color, back: true)[from `141.85.220.33` \ to #changed(`192.168.1.105`)]
      #ok-mark(pc, dx: -30pt)
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1, fact("💡", [the router has to *translate* the private addresses into its public address: *NAT* (_Network Address Translation_)], c: (fill: hl-bg, stroke: hl)))
    #only(2, fact("📤", [Ana sends a packet to the server, *from* her private address]))
    #only(3, fact("🔁", [the router *replaces the source* with its public address and remembers the change]))
    #only(4, fact("📥", [the server answers *to* the public address of the router]))
    #only(5, fact("🔁", [the router *replaces the destination* with Ana's address: private addresses never leave home], c: (fill: ok-color.lighten(90%), stroke: ok-color)))
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

// the routing table of the laptop, with `ip route`
#let route-lines = (
  "$ ip -br addr show enp0s31f6",
  ((none, "enp0s31f6        UP             "), ("addr", "192.168.1.105/24"), (none, " 2a02:2f0e:d10c::105/64 fe80::8e16:45ff:fea2:3b91/64")),
  "$ ip route",
  (
    ("def", "default"), (none, " "), ("via", "via 192.168.1.1"), (none, " "), ("dev", "dev enp0s31f6"), (none, " "),
    ("proto-d", "proto dhcp"), (none, " "), ("src", "src 192.168.1.105"), (none, " "), ("metric", "metric 100"),
  ),
  (
    ("net", "192.168.1.0/24"), (none, " "), ("dev", "dev enp0s31f6"), (none, " "), ("proto-k", "proto kernel"), (none, " "),
    ("link", "scope link"), (none, " "), ("src", "src 192.168.1.105"), (none, " "), ("metric", "metric 100"),
  ),
  "$ ip route get 192.168.2.20",
  ((none, "192.168.2.20 "), ("got", "via 192.168.1.1 dev enp0s31f6"), (none, " src 192.168.1.105 uid 1000")),
  "    cache",
)

#slide[
  == Routing Table
  where each packet goes: one line for each *route*

  #let steps = (
    (5, ("addr", "net", "dev", "link"), explain(
      [`ip route`: the *routing table*; this line is for the *local network*],
      ([`192.168.1.105/24`], [the address of the laptop, so its network is `192.168.1.0/24`]),
      ([`192.168.1.0/24`], [the local network: Bogdan `192.168.1.11` is here]),
      ([`dev enp0s31f6`], [the card the packets leave on]),
      ([`scope link`], [no gateway: the packet goes *directly* to the computer]),
    )),
    (5, ("proto-k", "src"), explain(
      [who added the route, and with which address],
      ([`proto kernel`], [added by the kernel when the card got its address `192.168.1.105/24`]),
      ([`src`], [the source address of the packets sent on this route]),
    )),
    (5, ("def", "via"), explain(
      [the *default route*: for every other address],
      ([`default`], [the same as `0.0.0.0/0`: any address, Carla or the Internet]),
      ([`via 192.168.1.1`], [send it to the *gateway*, the router]),
    )),
    (5, ("proto-d", "metric"), explain(
      [how the route got here, and its priority],
      ([`proto dhcp`], [received from the router, together with the address (_DHCP_)]),
      ([`metric 100`], [the *cost* of the route: if two routes match, the *smaller* one wins (Ethernet usually gets `100`, Wi-Fi `600`, so the cable is preferred)]),
    )),
    (8, ("got",), explain(
      [`ip route get`: which route is used for an address],
      ([`192.168.2.20`], [Carla is not in `192.168.1.0/24`, so the *default* route is used]),
      ([💡], [if more routes match, the one with the *longest mask* wins: it is the most precise]),
    )),
    (8, (), explain(
      [💡 the same table],
      ([`route -n`], [the older command (_net-tools_)]),
      ([`ip -6 route`], [the routing table for IPv6]),
    )),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(route-lines.slice(0, n), hl: ((keys, ip-peach),), size: 0.8em)
      #body
    ]
  }
]
