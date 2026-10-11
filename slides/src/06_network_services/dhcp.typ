#import "common.typ": *

#section-cover([DHCP], [automatic network configuration], layers: ("application",), note: [DHCP])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.14 - _Network Configuration Managers_
      - Section 9.19 - _Understanding DHCP_
  + #uso-book
    - Section 11.5.2 - _DHCP_
    - Section 11.6 - _Configurarea rețelei în Linux_
]

#slide[
  == DHCP
  _Dynamic Host Configuration Protocol_

  - who gives a computer its IP address, mask, gateway and DNS server?
    - *static*: someone writes them by hand (servers, printers)
    - *dynamic*: a *DHCP server* gives them automatically
  - at home, the DHCP server runs on the *home router*
  - the address is *leased* for a time (e.g. 24 hours), the computer renews the lease before it expires
  - the server remembers which address it gave to which MAC address

  #uncover(2)[
    #note-box[💡 no answer from a DHCP server: Windows and macOS pick a `169.254.x.x` address, only the local network works]
  ]
]

// ---------------------------------------------------------------------------
// The DHCP exchange, in a network
// ---------------------------------------------------------------------------

// a DHCP message: the name, then the frame (MAC) carrying the packet (IP)
#let dhcp-pkt(x, y, name, mac, ip, body: none, color: hl) = {
  let net = layer-colors.network
  pin(x, y, box(
    fill: if color == hl { hl-bg } else { color.lighten(88%) },
    stroke: 1.2pt + color,
    radius: 3pt,
    inset: (x: 3pt, y: 2pt),
    stack(
      spacing: 2pt,
      text(size: 7.5pt, weight: "bold", fill: color)[#icon("✉️", size: 8pt) DHCP #name],
      text(size: 7pt)[*MAC* #mac],
      box(fill: net.fill, stroke: 0.6pt + net.stroke, radius: 2pt, inset: (x: 3pt, y: 1.5pt), text(size: 7pt)[*IP* #ip]),
      if body != none { text(size: 7pt, body) },
    ),
  ))
}
// a computer that received a broadcast but does not answer it
#let ignore-mark(p, dx: 26pt) = pin(p.at(0) + dx, p.at(1) - 4pt, text(size: 7pt, fill: luma(110))[#icon("🙈", size: 11pt) \ ignores])

// the network of the DHCP slides: a new laptop, two computers, a switch and
// the home router (the DHCP server); `rogue`: a second DHCP server
#let dhcp-pts = (
  laptop: (60pt, 55pt),
  ana: (60pt, 150pt),
  sw: (235pt, 100pt),
  router: (410pt, 55pt),
  bogdan: (410pt, 150pt),
  rogue: (235pt, 22pt),
)
#let dhcp-net(laptop-addr: "no IP address yet", rogue: false) = {
  let p = dhcp-pts
  let devices = ("laptop", "ana", "router", "bogdan") + if rogue { ("rogue",) } else { () }
  for d in devices { wire(p.at(d), p.sw) }
  host(..p.laptop, "new laptop", addr: laptop-addr, size: 26pt, below: false)
  host(..p.ana, "Ana", addr: "192.168.1.10", size: 22pt)
  host(..p.bogdan, "Bogdan", addr: "192.168.1.11", size: 22pt)
  netdev(..p.sw, "switch", size: 16pt)
  netdev(..p.router, "wifi-router", size: 26pt)
  label(p.router.at(0), p.router.at(1) + 24pt, text(size: 7pt)[*home router* \ DHCP server `192.168.1.1`])
  if rogue {
    netdev(..p.rogue, "wifi-router", size: 22pt, highlight: true)
    label(p.rogue.at(0) + 68pt, p.rogue.at(1), text(size: 7pt, fill: bad-color)[*a second router* \ DHCP server `10.0.0.1`])
  }
}
#let all-from(src, to) = to.map(d => (dhcp-pts.at(src), dhcp-pts.sw, dhcp-pts.at(d)))
#let paths(..ps) = for path in ps.pos() { trail(..path, arrows: true) }

#let mac-l = "laptop"
#let bcast = [→ `ff:ff:…`]
#let ip-bcast = [`0.0.0.0` → `255.255.255.255`]

#slide[
  == How DHCP Works

  #let p = dhcp-pts
  #align(center, scale(88%, reflow: true, drawing(height: 185pt)[
    #only("1-4")[#dhcp-net()]
    #only("5-")[#dhcp-net(laptop-addr: "192.168.1.105/24")]

    // 1: DISCOVER, a broadcast
    #only(1)[
      #dhcp-pkt(180pt, 40pt, "DISCOVER", [laptop #bcast], ip-bcast, body: [is there a DHCP server?])
    ]
    // 2: everyone receives it, only the server answers
    #only(2)[
      #paths(..all-from("laptop", ("ana", "router", "bogdan")))
      #dhcp-pkt(330pt, 40pt, "DISCOVER", [laptop #bcast], ip-bcast)
      #ok-mark(p.router)
      #ignore-mark(p.ana, dx: -30pt)
      #ignore-mark(p.bogdan)
    ]
    // 3: OFFER
    #only(3)[
      #paths((p.router, p.sw, p.laptop))
      #dhcp-pkt(180pt, 40pt, "OFFER", [router → laptop], [`192.168.1.1` → `192.168.1.105`], body: [`192.168.1.105/24`, gateway and DNS `.1`, 24 h], color: ok-color)
    ]
    // 4: REQUEST, a broadcast again
    #only(4)[
      #paths(..all-from("laptop", ("ana", "router", "bogdan")))
      #dhcp-pkt(330pt, 40pt, "REQUEST", [laptop #bcast], ip-bcast, body: [I take `192.168.1.105` from `192.168.1.1`])
    ]
    // 5: ACK
    #only("5-")[
      #paths((p.router, p.sw, p.laptop))
      #dhcp-pkt(180pt, 40pt, "ACK", [router → laptop], [`192.168.1.1` → `192.168.1.105`], body: [it is yours for 24 hours], color: ok-color)
      #ok-mark(p.laptop, dx: -30pt)
    ]
  ]))

  // what happens, one card for each step
  #let good = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📢", [*DISCOVER*: the laptop has *no IP address* and does not know where the server is, so it asks *everyone*: a broadcast]))
    #only(2, fact("🙈", [the switch delivers the broadcast to *everyone*: Ana and Bogdan ignore it, only the *DHCP server* answers]))
    #only(3, fact("🎁", [*OFFER*: the server offers an *IP address* and a *mask*, the *gateway* and the *DNS server*]))
    #only(4, fact("🙋", [*REQUEST*: the laptop takes the offer, again with a broadcast, so that *every* DHCP server hears its choice]))
    #only("5-", fact("✅", [*ACK*: the server confirms, the address belongs to the laptop for *24 hours*], c: good))
  ]))]

// the network of the two DHCP servers slide: only the laptop, the switch,
// the home router (with the Internet behind it) and a second router
#let two-pts = (
  laptop: (55pt, 100pt),
  sw: (200pt, 100pt),
  home: (345pt, 45pt),
  net: (445pt, 45pt),
  second: (345pt, 160pt),
)
#let good = ok-color
#let bad = bad-color
// a small round badge with the order in which the offers arrive
#let order-badge(x, y, body, color) = pin(x, y, box(
  fill: color,
  radius: 50%,
  inset: 3pt,
  text(size: 7.5pt, weight: "bold", fill: white, body),
))

#slide[
  == Two DHCP Servers
  someone plugs in a second router

  #let p = two-pts
  #align(center, scale(86%, reflow: true, drawing(height: 190pt)[
    #wire(p.laptop, p.sw)
    #wire(p.sw, p.home)
    #wire(p.sw, p.second)
    #wire(p.home, p.net, stroke: 1.5pt + good)
    #cloud(..p.net, [Internet], width: 62pt, height: 36pt)
    #only("1-4")[#host(..p.laptop, "new laptop", addr: "no IP address yet", size: 30pt)]
    #only(5)[#host(..p.laptop, "new laptop", addr: text(fill: bad)[10.0.0.23/24 \ gateway 10.0.0.1], size: 30pt)]
    #only("6-")[#host(..p.laptop, "new laptop", addr: text(fill: good)[192.168.1.105/24 \ gateway 192.168.1.1], size: 30pt)]
    #netdev(..p.sw, "switch", size: 18pt)
    #netdev(..p.home, "wifi-router", size: 28pt)
    #label(p.home.at(0), p.home.at(1) + 26pt, text(size: 7.5pt, fill: good)[*home router* \ DHCP server `192.168.1.1`])
    #netdev(..p.second, "wifi-router", size: 28pt)
    #label(p.second.at(0) + 78pt, p.second.at(1), align(left, text(size: 7.5pt, fill: bad)[*second router* \ DHCP server `10.0.0.1` \ no Internet]))

    // 1: the DISCOVER reaches both servers
    #only(1)[
      #trail(p.laptop, p.sw, p.home, arrows: true)
      #trail(p.sw, p.second, arrows: true)
      #dhcp-pkt(110pt, 50pt, "DISCOVER", [laptop #bcast], ip-bcast, body: [is there a DHCP server?])
    ]
    // 2: the OFFER of the second router arrives first
    #only("2-3")[
      #trail(p.second, p.sw, p.laptop, color: bad, arrows: true)
      #dhcp-pkt(150pt, 160pt, "OFFER", [second router → laptop], [`10.0.0.1` → `10.0.0.23`], body: [`10.0.0.23/24`, gateway `10.0.0.1`], color: bad)
      #order-badge(83pt, 160pt, [1st], bad)
    ]
    // 3: the OFFER of the home router arrives second
    #only(3)[
      #trail(p.home, (p.sw.at(0), p.sw.at(1) - 6pt), (p.laptop.at(0) + 16pt, p.laptop.at(1) - 6pt), color: good, arrows: true)
      #dhcp-pkt(150pt, 40pt, "OFFER", [router → laptop], [`192.168.1.1` → `192.168.1.105`], body: [`192.168.1.105/24`, gateway `192.168.1.1`], color: good)
      #order-badge(83pt, 40pt, [2nd], good)
    ]
    // 4: the REQUEST names the first server
    #only(4)[
      #trail(p.laptop, p.sw, p.home, arrows: true)
      #trail(p.sw, p.second, arrows: true)
      #dhcp-pkt(110pt, 50pt, "REQUEST", [laptop #bcast], ip-bcast, body: [I take `10.0.0.23` from `10.0.0.1`])
      #pin(p.home.at(0) - 4pt, p.home.at(1) - 28pt, text(size: 7.5pt, fill: good)[✋ not me: `.105` stays free])
    ]
    // 5: the ACK of the second router: a configuration with no Internet
    #only(5)[
      #trail(p.second, p.sw, p.laptop, color: bad, arrows: true)
      #dhcp-pkt(150pt, 160pt, "ACK", [second router → laptop], [`10.0.0.1` → `10.0.0.23`], body: [it is yours], color: bad)
      #pin(p.laptop.at(0) - 30pt, p.laptop.at(1) - 4pt, icon("❌", size: 16pt))
    ]
    // 6: DHCP snooping: the switch drops the answers of the second router
    #only("6-")[
      #trail(p.second, (p.sw.at(0) + 30pt, p.sw.at(1) + 13pt), color: bad, arrows: true, gap: 17pt)
      #pin(p.sw.at(0) + 30pt, p.sw.at(1) + 16pt, icon("⛔", size: 15pt))
      #pin(p.sw.at(0) - 55pt, p.sw.at(1) - 40pt, box(
        fill: ok-color.lighten(90%),
        stroke: 1pt + good,
        radius: 4pt,
        inset: (x: 4pt, y: 3pt),
        text(size: 7.5pt)[🛡️ *DHCP snooping*: only the port of the \ home router may answer DHCP],
      ))
      #trail(p.home, p.sw, p.laptop, color: good, arrows: true)
      #dhcp-pkt(150pt, 160pt, "ACK", [router → laptop], [`192.168.1.1` → `192.168.1.105`], body: [it is yours, for 24 hours], color: good)
      #pin(p.laptop.at(0) - 30pt, p.laptop.at(1) - 4pt, icon("✅", size: 16pt))
    ]
  ]))

  // what happens, one card for each step
  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #let bad-c = (fill: bad-color.lighten(90%), stroke: bad-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📢", [the DISCOVER is a broadcast: it reaches *both* DHCP servers, and *both* answer]))
    #only(2, fact("🏃", [the offer of the second router *may be faster* and arrives *first*], c: bad-c))
    #only(3, fact("🐢", [the offer of the home router arrives *second*: too late, the laptop takes the *first* one]))
    #only(4, fact("🙋", [the laptop takes `10.0.0.23`, with a broadcast: the home router sees it was not chosen and keeps `.105` free]))
    #only(5, fact("❌", [the laptop is in the network of the second router: *no Internet*, or someone else sees all its traffic], c: bad-c))
    #only("6-", fact("🛡️", [the rule: *one* DHCP server in a network; managed switches can block the others (_DHCP snooping_)], c: good-c))
  ]))]

#slide[
  == DHCP in Linux
  Fedora uses NetworkManager

  #text(size: 0.9em)[```terminal
  $ nmcli device show enp0s31f6 | grep IP4
  IP4.ADDRESS[1]:                         192.168.1.105/24
  IP4.GATEWAY:                            192.168.1.1
  IP4.ROUTE[1]:                           dst = 192.168.1.0/24, nh = 0.0.0.0, mt = 100
  IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.1.1, mt = 100
  IP4.DNS[1]:                             192.168.1.1
  ```]

  #uncover("2-")[
    #block[- `IP4.ADDRESS`, `IP4.GATEWAY`, `IP4.DNS`: everything the computer needs, received from DHCP]
  ]
  #v(0pt)
]
