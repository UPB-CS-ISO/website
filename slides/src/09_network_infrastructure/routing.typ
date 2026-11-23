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
  + #uso-book
    - Chapter 11 - _Rețelistică și Internet_
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
    // (the MAC addresses cut short, like in the found boxes: there is no room)
    label(192pt, 76pt, align(center, text(size: 7pt, font: "DejaVu Sans Mono")[*eth0* \ 192.168.1.1 \ #text(fill: luma(110))[70:b5:…]]))
    label(288pt, 76pt, align(center, text(size: 7pt, font: "DejaVu Sans Mono")[*eth1* \ 192.168.2.1 \ #text(fill: luma(110))[b8:27:…]]))
  }
}

// what a device found out: the MAC address for an IP address
#let mac-found(x, y, who, ip, mac, color: accent) = pin(x, y, box(
  fill: white,
  stroke: 1pt + color,
  radius: 4pt,
  inset: (x: 5pt, y: 3pt),
  text(size: 7.5pt)[🔎 #who: #raw(ip) #arrow #if mac == none { text(fill: bad-color, weight: "bold")[???] } else { raw(mac) }],
))

#slide[
  == Router
  connects two networks

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
  #let ip-ab = [Ana #arrow Bogdan]
  #let ip-ac = [Ana #arrow Carla]
  #align(center, scale(88%, reflow: true, drawing(height: 185pt)[
    #only("1-4")[#two-nets(router: false)]
    #only("5-")[#two-nets(r-highlight: true)]
    // the gateway of A: none without a router, the router after
    #only(4)[#tag(55pt, 104pt, [🚪 gateway: *none*], stroke: 1pt + bad-color, size: 7.5pt)]
    #only("5-")[#tag(55pt, 104pt, [🚪 gateway: `192.168.1.1`], fill: hl-bg, stroke: 1pt + hl, size: 7.5pt)]

    // 1 - 3: to B, in the same network
    #only(1)[#pkt(..at-a, [Ana #arrow ?], ip-ab, state: "unknown")]
    #only(2)[
      // ARP: a question for everyone, the answer only for Ana
      #tag(238pt, 36pt, [📢 ARP, to *everyone*: \ _who has `192.168.1.11`? tell `192.168.1.10`_], stroke: 1pt + hl, size: 7pt)
      #tag(238pt, 72pt, [↩️ Bogdan, only to Ana: \ _`192.168.1.11` is at `e4:3b:71:0c:9a:52`_], stroke: 1pt + ok-color, size: 7pt)
      #pkt(..at-a, [Ana #arrow *Bogdan*], ip-ab)
    ]
    #only(3)[
      #trail(a, s1, b)
      #pkt(..at-b, [Ana #arrow *Bogdan*], ip-ab)
      #ok-mark(b, dx: -26pt)
    ]

    // 4: to C, in another network, without a router
    #only(4)[
      #tag(240pt, 40pt, [🗺️ Ana: a route to `192.168.2.0/24`? #text(fill: bad-color, weight: "bold")[none]], stroke: 1pt + bad-color, size: 7.5pt)
      #pkt(..at-a, [Ana #arrow *???*], ip-ac, state: "missing")
      #pin(240pt, 97pt, icon("❌", size: 26pt))
      #tag(240pt, 130pt, text(fill: bad-color)[`Network is unreachable`], stroke: 1pt + bad-color, size: 7.5pt)
    ]

    // 5 - 7: with a router
    #only(5)[
      #mac-found(240pt, 22pt, [Ana], "192.168.1.1", "70:b5:…", color: rgb("f08c00"))
      #pkt(..at-a, [Ana #arrow *Router*], ip-ac, state: "gateway")
    ]
    #only(6)[
      #trail(a, s1, r)
      #mac-found(240pt, 18pt, [Router], "192.168.2.20", "08:d1:…", color: ok-color)
      #pkt(..at-r, [Router #arrow *Carla*], ip-ac)
    ]
    #only("7-")[
      #trail(a, s1, r)
      #trail(r, s2, c)
      #pkt(..at-c, [Router #arrow *Carla*], ip-ac)
      #ok-mark(c)
    ]
  ]))

  // what happens, one card for each step
  #let bad = (fill: bad-color.lighten(90%), stroke: bad-color)
  #let good = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📦", [Ana has a packet for Bogdan `192.168.1.11`: *the same network*]))
    #only(2, fact("🔎", [Ana asks *everyone* for the MAC address of `192.168.1.11` (_ARP_); only Bogdan answers, Ana puts his MAC on the frame]))
    #only(3, fact("✅", [the switch delivers the frame to Bogdan], c: good))
    #only(4, fact("❌", [Carla `192.168.2.20` is in *another network* and Ana has *no gateway*: no route, so no frame is sent at all], c: bad))
    #only(5, fact("🚪", [Ana sends it to her *gateway* `192.168.1.1`, the router: ARP gives her *its MAC address*, the IP is still Carla's]))
    #only(6, fact("🔁", [the router finds *Carla's MAC address* (ARP) and puts the packet in a *new frame*: the same packet, only the TTL is one less]))
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
  #counter(footnote).update(0)the MAC addresses Ana's computer has found#footnote[`arp -n`: the older command (_net-tools_), the same table]

  #let steps = (
    (2, ("ip", "mac", "ok"), explain(
      [`ip neigh`: the *neighbor table* (the _ARP cache_): the answers to Ana's ARP questions],
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
    )),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(neigh-lines, shown: n, hl: ((keys, ip-peach),), size: 0.95em)
      #body
    ]
  }
]

// ---------------------------------------------------------------------------
// The routing table
// ---------------------------------------------------------------------------

// the routing table of Ana (the Router slide), with `ip route`
#let route-lines = (
  "$ ip route",
  (("def", "default"), (none, " "), ("via", "via 192.168.1.1"), (none, " dev enp0s31f6 proto dhcp src 192.168.1.10 metric 100")),
  (("net", "192.168.1.0/24"), (none, " dev enp0s31f6 "), ("kernel", "proto kernel"), (none, " scope link src 192.168.1.10 metric 100")),
)

// which line of the routing table each packet takes: both lines match
// 192.168.1.11, the longest prefix (/24) wins; 192.168.2.20 matches only default
#let route-pick = {
  text(size: 10pt)[💡 for every packet, the kernel picks the *most specific* line: the *longest* prefix wins (`ip r` is the short form)]
  drawing(width: 480pt, height: 86pt)[
    #let (y1, y2) = (16pt, 66pt)
    #let win = 1.6pt
    // fixed widths, so the arrows meet the boxes
    #let pkt-at(y, body) = tag(66pt, y, body, fill: hl-bg, stroke: 1pt + hl, size: 8pt, width: 96pt)
    #let line-at(y, body) = tag(245pt, y, body, fill: white, stroke: 1pt + accent, size: 8pt, width: 140pt)
    #let dest-at(y, body) = tag(412pt, y, body, fill: ok-color.lighten(90%), stroke: 1pt + ok-color, size: 8pt, width: 124pt)
    // the packets
    #pkt-at(y1)[✉️ to `192.168.1.11`]
    #pkt-at(y2)[✉️ to `192.168.2.20`]
    // the lines of the routing table
    #line-at(y1)[`192.168.1.0/24`: *24* bits match]
    #line-at(y2)[`default` (`0.0.0.0/0`): *0* bits]
    // where the packet goes
    #dest-at(y1)[✅ Bogdan, *directly*]
    #dest-at(y2)[✅ the *gateway* `192.168.1.1`]
    // 192.168.1.11: both lines match, /24 wins
    #draw-arrow((118pt, y1), (172pt, y1), thickness: win)
    #draw-arrow((118pt, y1 + 5pt), (172pt, y2 - 8pt), color: luma(150), dash: "dashed")
    #label(245pt, 41pt, text(size: 6.5pt, fill: luma(110))[`192.168.1.11` matches `default` too, \ but 0 bits is shorter than 24])
    // 192.168.2.20: only default matches
    #draw-arrow((118pt, y2), (172pt, y2), thickness: win)
    #draw-arrow((318pt, y1), (347pt, y1), thickness: win)
    #draw-arrow((318pt, y2), (347pt, y2), thickness: win)
  ]
}

#slide[
  == Routing Table
  where does each packet go? on Ana's computer

  #term-steps(route-lines, (
    (3, ("net", "kernel"), explain(
      [`ip route`: the *routing table*, one line for each network the computer can reach],
      ([`192.168.1.0/24`], [Ana's own network: sent *directly*, to the MAC address of the destination (ARP)]),
      ([`proto kernel`], [added by the kernel when the card got its address]),
    )),
    (3, ("def", "via"), explain(
      [the *default route*],
      ([`default`], [every other address: `0.0.0.0/0`]),
      ([`via 192.168.1.1`], [sent to the *gateway*, the router, which knows what to do next]),
    )),
  ), summary: (("net", "def", "via"), route-pick), size: 0.85em)
]

// three ways for `ping` to fail, on the laptop `192.168.1.105`, and what each one means
#let ping-fails = (
  (
    (
      "$ ping -c 1 8.8.8.8",
      ((none, "ping: connect: "), ("err", "Network is unreachable")),
    ),
    explain(
      [no *route* to that network: usually no *default gateway*],
      ([check], [`ip route`: is there a `default via ...` line?]),
    ),
  ),
  (
    (
      "$ ping -c 1 192.168.1.20",
      "PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.",
      ((none, "From 192.168.1.105 icmp_seq=1 "), ("err", "Destination Host Unreachable")),
      "",
      "--- 192.168.1.20 ping statistics ---",
      "1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms",
    ),
    explain(
      [a computer in *my network*, but nobody answered the ARP question (no MAC address)],
      ([why], [the computer is off, or the IP address is wrong]),
    ),
  ),
  (
    (
      "$ ping -c 2 141.85.220.250",
      "PING 141.85.220.250 (141.85.220.250) 56(84) bytes of data.",
      "",
      "--- 141.85.220.250 ping statistics ---",
      ((none, "2 packets transmitted, 0 received, "), ("err", "100% packet loss"), (none, ", time 1031ms")),
    ),
    explain(
      [the packets leave, *no answer* comes back],
      ([why], [the computer is down, or a *firewall* drops `ping` (many servers do)]),
      ([💡], [no answer to `ping` does not always mean the computer is down]),
    ),
  ),
)

// the three errors side by side, for the last step
#let ping-fails-table = block(width: 100%, {
  set text(size: 10pt)
  set table(inset: (x: 6pt, y: 6pt))
  table(
    columns: (auto, 1fr, auto),
    align: left + horizon,
    stroke: (x, y) => if y == 0 { (bottom: 1pt + luma(150)) } else { (bottom: 0.5pt + luma(215)) },
    table.header(..([*the error*], [*what it means*], [*check*]).map(t => text(fill: luma(90), t))),
    text(fill: bad-color)[`Network is unreachable`], [no route: usually no default gateway], [`ip route`],
    text(fill: bad-color)[`Destination Host Unreachable`], [in my network, but no answer to ARP], [is it on? the right IP?],
    text(fill: bad-color)[`100% packet loss`], [no answer: down, or a firewall drops `ping`], [another computer, `traceroute`],
  )
})

#slide[
  == When `ping` Fails
  the error tells where the problem is

  #let bad = (hl: bad-color.lighten(75%), bg: bad-color.lighten(93%), bar: bad-color)
  #for (i, (lines, body)) in ping-fails.enumerate() {
    only(i + 1)[
      #parts-terminal(lines, hl: ((("err",), bad),), size: 0.9em)
      #body
    ]
  }
  #only(ping-fails.len() + 1)[
    #v(1em)
    #ping-fails-table
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
    #only("2-")[- each router only knows the *next hop*; if a link fails, packets take another path]
  ]))
]

// ---------------------------------------------------------------------------
// traceroute
// ---------------------------------------------------------------------------

#let trace = (
  "$ traceroute -n 141.85.228.17",
  ((none, "traceroute to 141.85.228.17 (141.85.228.17), "), ("max", "30 hops max"), (none, ", 60 byte packets")),
  ((none, " "), ("hop", "1"), (none, "  "), ("router", "192.168.1.1"), (none, "    "), ("time", "1.912 ms  1.874 ms  1.851 ms")),
  ((none, " "), ("hop", "2"), (none, "  "), ("router", "10.20.0.1"), (none, "      "), ("time", "3.420 ms  3.402 ms  3.389 ms")),
  ((none, " "), ("hop", "3"), (none, "  "), ("star", "* * *")),
  ((none, " "), ("hop", "4"), (none, "  "), ("router", "37.128.225.9"), (none, "   "), ("time", "4.103 ms  4.087 ms  4.152 ms")),
  ((none, " "), ("hop", "5"), (none, "  "), ("dest", "141.85.228.17"), (none, "  "), ("time", "4.210 ms  4.198 ms  4.176 ms")),
)

#slide[
  == `traceroute`
  which routers are on the way?

  #term-steps(trace, (
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
  ), summary: (("hop", "router", "star", "dest"), explain(
    [💡 `traceroute`: the routers on the way, in order, one per line],
    ([`1`], [the gateway `192.168.1.1`, then the routers of the provider]),
    ([`* * *`], [a router that does not answer, but still forwards]),
    ([`141.85.228.17`], [the destination, after 4 routers]),
  )), size: 0.85em)
]

#slide[
  == Hub, Switch, AP, Router
  the layer each device works on

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
    [*Medium*], [shared cable], [one cable per port], [shared radio], [one card per network],
    [*Connects*], [devices], [devices of one network], [wireless devices to a wired network], [*different networks*],
  ))
  ]
  #v(0pt)
]
