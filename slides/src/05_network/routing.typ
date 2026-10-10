#import "common.typ": *

#section-cover([Routing], [from one network to another], layers: ("network",), note: [routers])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.4 - _Routes and the Kernel Routing Table_
      - Section 9.5 - _The Default Gateway_
      - Section 9.7 - _Basic ICMP and DNS Tools_
  + #tanenbaum
    - Section 5.2 - _Routing Algorithms_
    - Section 5.6 - _The Network Layer in the Internet_
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

// the neighbor table of Ana (the Router slide), with `ip neigh`
#let neigh-lines = (
  "$ ip neigh",
  (("ip", "192.168.1.1"), (none, " dev enp0s31f6 lladdr "), ("mac", "70:b5:e8:2d:91:4c"), (none, " "), ("ok", "REACHABLE")),
  ((none, "192.168.1.11 dev enp0s31f6 lladdr e4:3b:71:0c:9a:52 "), ("stale", "STALE")),
  ((none, "192.168.1.12 dev enp0s31f6 "), ("failed", "FAILED")),
)

#slide[
  == Neighbors
  the MAC addresses this computer found, on Ana's computer

  #let steps = (
    (2, ("ip", "mac", "ok"), explain(
      [`ip neigh`: the *neighbor table* (the _ARP cache_)],
      ([`192.168.1.1`], [the gateway (the router) has the MAC address `70:b5:e8:2d:91:4c`]),
      ([`REACHABLE`], [used just now, it answers]),
    )),
    (3, ("stale",), explain(
      [Bogdan, found some time ago],
      ([`STALE`], [an old entry: Ana asks again for the MAC address the next time she needs it]),
    )),
    (4, ("failed",), explain(
      [`192.168.1.12`: nobody answered, there is no such computer],
      ([`FAILED`], [`ping` shows `Destination Host Unreachable`]),
    )),
    (4, (), explain(
      [💡 Carla `192.168.2.20` is *not* in the table: she is in another network],
      ([why], [for another network Ana needs only the MAC address of the *gateway*]),
      ([`arp -n`], [the older command (_net-tools_), the same table]),
    )),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(neigh-lines.slice(0, n), hl: ((keys, ip-peach),), size: 0.95em)
      #body
    ]
  }
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

// the steps of a shell: (lines shown, highlighted parts, explanation)
#let test-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size)
    #body
  ]
}

// ---------------------------------------------------------------------------
// traceroute
// ---------------------------------------------------------------------------

#let trace = (
  "$ traceroute -n 141.85.220.33",
  ((none, "traceroute to 141.85.220.33 (141.85.220.33), "), ("max", "30 hops max"), (none, ", 60 byte packets")),
  ((none, " "), ("hop", "1"), (none, "  "), ("router", "192.168.1.1"), (none, "    "), ("time", "1.912 ms  1.874 ms  1.851 ms")),
  ((none, " "), ("hop", "2"), (none, "  "), ("router", "10.20.0.1"), (none, "      "), ("time", "3.420 ms  3.402 ms  3.389 ms")),
  ((none, " "), ("hop", "3"), (none, "  "), ("star", "* * *")),
  ((none, " "), ("hop", "4"), (none, "  "), ("router", "37.128.225.9"), (none, "   "), ("time", "4.103 ms  4.087 ms  4.152 ms")),
  ((none, " "), ("hop", "5"), (none, "  "), ("dest", "141.85.220.33"), (none, "  "), ("time", "4.210 ms  4.198 ms  4.176 ms")),
)

#slide[
  == traceroute
  which routers are on the way?

  #test-steps(trace, (
    (2, ("max",), explain(
      [`traceroute`: the *routers* between this computer and the destination],
      ([`-n`], [show the routers by their IP addresses only (faster)]),
      ([`30 hops max`], [it gives up after 30 routers]),
    )),
    (4, ("hop", "router", "time"), explain(
      [one line for every router (*hop*), in order],
      ([`1`], [the first router is the *gateway*, `192.168.1.1`]),
      ([`ms`], [three tries, three round trip times]),
    )),
    (5, ("star",), explain(
      [`* * *`: this router did *not* answer],
      ([💡], [many routers do not answer, but they still *forward* the packets]),
    )),
    (7, ("dest",), explain(
      [the last line is the *destination*: it was reached],
      ([install], [`sudo dnf install traceroute` (Fedora), `sudo apt install traceroute` (Ubuntu)]),
      ([`tracepath`], [usually installed already, it does almost the same]),
    )),
  ), size: 0.85em)
]

// how traceroute finds the routers: packets with TTL 1, 2, 3, ...
#let trace-drawing(k) = drawing(width: 470pt, height: 104pt)[
  #let y = 42pt
  #let xs = (35pt, 160pt, 285pt, 420pt)
  #for i in range(3) { wire((xs.at(i), y), (xs.at(i + 1), y)) }
  #host(xs.at(0), y, "my laptop", size: 26pt)
  #netdev(xs.at(1), y, "router", name: "gateway", size: 22pt)
  #netdev(xs.at(2), y, "router", name: "router", size: 22pt)
  #host(xs.at(3), y, "server", kind: "server", size: 26pt)
  // the packet goes k hops; every router subtracts 1 from its TTL
  #for i in range(k) {
    let (a, b) = (xs.at(i), xs.at(i + 1))
    draw-arrow((a + 20pt, y - 14pt), (b - 20pt, y - 14pt), color: hl, thickness: 1.8pt)
    tag((a + b) / 2, y - 25pt, [TTL #(k - i)], fill: hl-bg, stroke: 0.8pt + hl)
  }
  // the answer comes back to the laptop
  #let reached = k == 3
  #let c = if reached { ok-color } else { luma(110) }
  #draw-arrow((xs.at(k), y + 42pt), (xs.at(0), y + 42pt), color: c, thickness: 1.4pt, dash: if reached { none } else { "dashed" })
  #label((xs.at(0) + xs.at(k)) / 2, y + 52pt, text(size: 7.5pt, fill: c, if reached [✅ echo reply: the destination] else [⏱️ TTL 0: dropped, _"time exceeded"_ comes back]))
  #wire((xs.at(k), y + 34pt), (xs.at(k), y + 42pt), stroke: (paint: c, thickness: 1.4pt, dash: if reached { none } else { "dashed" }))
  #if not reached { pin(xs.at(k), y - 26pt, text(size: 12pt, "💥")) }
]

#slide[
  == How traceroute Works
  with the TTL of the IP packets

  #for k in range(1, 4) {
    only(k, trace-drawing(k))
  }

  #set text(size: 10pt)
  #only(1, fact("1️⃣", [*TTL 1*: the gateway subtracts 1, gets `0`, drops the packet and tells the sender: now we know *router 1*]))
  #only(2, fact("2️⃣", [*TTL 2*: the packet passes the gateway, the next router drops it: now we know *router 2*]))
  #only(3, fact("✅", [*TTL 3*: the packet reaches the destination, which answers: done], c: (fill: ok-color.lighten(90%), stroke: ok-color)))
]
