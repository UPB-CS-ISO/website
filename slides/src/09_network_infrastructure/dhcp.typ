#import "common.typ": *

#section-cover([DHCP], [automatic network configuration], layers: ("application",), note: [DHCP])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.13 - _Network Configuration Managers_
      - Section 9.18 - _Understanding DHCP_
  + #tanenbaum
    - Section 5.6.4 - _Internet Control Protocols_
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
// the home router (the DHCP server)
#let dhcp-pts = (
  laptop: (60pt, 55pt),
  ana: (60pt, 150pt),
  sw: (235pt, 100pt),
  router: (410pt, 55pt),
  bogdan: (410pt, 150pt),
)
#let dhcp-net(laptop-addr: "no IP address yet") = {
  let p = dhcp-pts
  let devices = ("laptop", "ana", "router", "bogdan")
  for d in devices { wire(p.at(d), p.sw) }
  host(..p.laptop, "new laptop", addr: laptop-addr, size: 26pt, below: false)
  host(..p.ana, "Ana", addr: "192.168.1.10", size: 22pt)
  host(..p.bogdan, "Bogdan", addr: "192.168.1.11", size: 22pt)
  netdev(..p.sw, "switch", name: "switch", size: 16pt, label-at: top)
  netdev(..p.router, "wifi-router", size: 26pt)
  label(p.router.at(0), p.router.at(1) + 24pt, text(size: 7pt)[*home router* \ DHCP server `192.168.1.1`])
}
#let all-from(src, to) = to.map(d => (dhcp-pts.at(src), dhcp-pts.sw, dhcp-pts.at(d)))
// (`split`: the pieces stop before the switch, so the lines do not hide it)
#let paths(..ps) = for path in ps.pos() { trail(..path, split: true) }

// who sends to whom, with a drawn arrow (arrow characters are missing from the fonts)
#let to(a, b) = [#a #arrow #b]
#let bcast = [#arrow `ff:ff:…`]
#let ip-bcast = to([`0.0.0.0`], [`255.255.255.255`])

// the four messages in a row, the first `n` in color
#let dhcp-strip(n) = {
  let names = ("DISCOVER", "OFFER", "REQUEST", "ACK")
  let chip(i, name) = box(
    fill: if i < n { hl-bg } else { white },
    stroke: 0.8pt + if i < n { hl } else { luma(190) },
    radius: 3pt,
    inset: (x: 3pt, y: 2pt),
    text(size: 7pt, weight: "bold", fill: if i < n { black } else { luma(150) }, name),
  )
  names.enumerate().map(((i, name)) => chip(i, name)).join(h(0.3em) + arrow + h(0.3em))
}

#slide[
  == How DHCP Works
  four messages, over UDP: from port `68` (the client) to port `67` (the server)

  #let p = dhcp-pts
  #align(center, scale(88%, reflow: true, drawing(height: 185pt)[
    #only("1-4")[#dhcp-net()]
    #only("5-")[#dhcp-net(laptop-addr: "192.168.1.105/24")]
    // the four messages, the ones sent so far in color
    #for n in range(1, 5) { only(n, pin(235pt, 178pt, dhcp-strip(n))) }
    #only("5-", pin(235pt, 178pt, dhcp-strip(4)))

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
      #dhcp-pkt(180pt, 40pt, "OFFER", to([router], [laptop]), to([`192.168.1.1`], [`192.168.1.105`]), body: [`192.168.1.105/24`, gateway and DNS `.1`, 24 h], color: ok-color)
    ]
    // 4: REQUEST, a broadcast again
    #only(4)[
      #paths(..all-from("laptop", ("ana", "router", "bogdan")))
      #dhcp-pkt(330pt, 40pt, "REQUEST", [laptop #bcast], ip-bcast, body: [I take `192.168.1.105` from `192.168.1.1`])
    ]
    // 5: ACK
    #only("5-")[
      #paths((p.router, p.sw, p.laptop))
      #dhcp-pkt(180pt, 40pt, "ACK", to([router], [laptop]), to([`192.168.1.1`], [`192.168.1.105`]), body: [it is yours for 24 hours], color: ok-color)
      #ok-mark(p.laptop, dx: -30pt)
    ]
  ]))

  // what happens, one card for each step
  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("📢", [*DISCOVER*: the laptop has *no IP address* and does not know where the server is, so it asks *everyone*: a broadcast]))
    #only(2, fact("🙈", [the switch delivers the broadcast to *everyone*: Ana and Bogdan ignore it, only the *DHCP server* answers]))
    #only(3, fact("🎁", [*OFFER*: the server offers an *IP address* and a *mask*, the *gateway* and the *DNS server*]))
    #only(4, fact("🙋", [*REQUEST*: the laptop takes the offer, again with a broadcast, so that *every* DHCP server hears its choice]))
    #only("5-", fact("✅", [*ACK*: the server confirms, the address belongs to the laptop for *24 hours*], c: good-c))
  ]))]

// what the laptop received from DHCP, as NetworkManager shows it
#let dhcp-show = (
  "$ nmcli device show wlp2s0 | grep IP4",
  (("addr", "IP4.ADDRESS[1]:"), (none, "                         "), ("addr", "192.168.1.105/24")),
  (("gw", "IP4.GATEWAY:"), (none, "                            "), ("gw", "192.168.1.1")),
  ((none, "IP4.ROUTE[1]:                           dst = 192.168.1.0/24, nh = 0.0.0.0, mt = 600"),),
  ((none, "IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.1.1, mt = 600"),),
  (("dns", "IP4.DNS[1]:"), (none, "                             "), ("dns", "192.168.1.1")),
)

#slide[
  == DHCP in Linux
  what the laptop received, as NetworkManager shows it

  #only(1, parts-terminal(dhcp-show, size: 0.8em))
  #only("2-", parts-terminal(dhcp-show, hl: ((("addr", "gw", "dns"), ip-peach),), size: 0.8em))

  #uncover("2-", text(size: 0.85em, explain(
    [everything the computer needs, received from DHCP],
    ([`IP4.ADDRESS`], [the IP address and the mask (`/24`)]),
    ([`IP4.GATEWAY`], [the default gateway: the router, for every other network]),
    ([`IP4.DNS`], [the DNS server: here the router too]),
  )))
  #uncover("3-", text(size: 0.85em)[💡 the same, with other commands: `ip -br address`, `ip route`, `resolvectl dns`])
]
