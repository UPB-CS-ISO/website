#import "common.typ": *

#slide[
  = Home Gateway #text(size: 10pt, weight: "regular")[\ _the box from your Internet provider_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.22 - _Private Networks (IPv4)_
      - Section 9.23 - _Network Address Translation (IP Masquerading)_
  + #uso-book
    - Section 11.4.3 - _Limita de adrese IP_
]

// the inside of a home gateway, revealed step by step: four devices (1 - 4),
// then the services that run on its router (5 - 8)
#let svc-badge(y, e, name, on) = at(246pt, y, box(
  width: 72pt,
  height: 15pt,
  radius: 3pt,
  fill: if on { hl-bg } else { white },
  stroke: if on { 1.4pt + hl } else { 0.8pt + luma(160) },
  align(center + horizon, text(size: 7.5pt, weight: if on { "bold" } else { "regular" })[#icon(e, size: 9pt) #name]),
))

#slide[
  == Home Router
  four devices in one box, and the services of its router

  #drawing(height: 182pt)[
    #let ap = (170pt, 22pt)
    #let br = (170pt, 66pt)
    #let sw = (170pt, 110pt)
    #let rt = (282pt, 110pt)
    #area(110pt, 5pt, 268pt, 172pt, [home router], color: luma(100), name-at: bottom + right)

    // 1. switch: the LAN ports, for the wired devices
    #wire((40pt, 95pt), sw)
    #wire((40pt, 145pt), sw)
    #host(40pt, 95pt, "PC", size: 20pt)
    #host(40pt, 145pt, "TV", kind: "old-pc", size: 20pt)
    #netdev(..sw, "switch", name: "switch", sub: "LAN ports", size: 16pt)

    // 2. access point
    #uncover("2-")[
      #radio((40pt, 22pt), ap)
      #host(40pt, 22pt, "phone", kind: "phone", size: 22pt)
      #netdev(..ap, "wifi-router", name: "access point", size: 24pt, label-at: right)
    ]

    // 3. bridge: between the access point and the switch, one network
    #uncover("3-")[
      #wire((170pt, 34pt), (170pt, 59pt))
      #wire((170pt, 73pt), (170pt, 103pt))
      #netdev(..br, "bridge", name: "bridge", size: 16pt, label-at: right)
      #tag(170pt, 162pt, text(fill: accent)[*LAN* `192.168.1.0/24`, private], size: 7pt)
    ]

    // 4. router: connected to the switch, between the LAN and the provider (WAN)
    #uncover("4-")[
      #wire((192pt, 110pt), (267pt, 110pt))
      #wire((298pt, 110pt), (412pt, 110pt))
      #netdev(..rt, "router", name: "router", size: 26pt)
      // the two addresses of the router, on the wire of each network
      #label(230pt, 101pt, text(size: 6.5pt)[LAN `192.168.1.1`])
      #label(336pt, 101pt, text(size: 6.5pt)[WAN `203.0.113.42`])
      #pin(438pt, 110pt, pic("cloud", size: 40pt))
      #label(438pt, 140pt, text(size: 7pt)[Internet \ provider (ISP)])
    ]

    // 5 - 8: the services of the router
    #uncover("5-")[
      #for (i, (e, name)) in (("🎫", [DHCP server]), ("📖", [DNS]), ("🔀", [NAT])).enumerate() {
        for step in range(5, 8) { only(step, svc-badge(30pt + i * 17pt, e, name, step == 5 + i)) }
        only("8-", svc-badge(30pt + i * 17pt, e, name, false))
      }
    ]
    // 5. DHCP: every device got its address from the router
    #only(5)[
      #host(40pt, 22pt, "phone", kind: "phone", size: 22pt, addr: "192.168.1.107", color: ok-color)
      #host(40pt, 95pt, "PC", size: 20pt, addr: "192.168.1.105", color: ok-color)
      #host(40pt, 145pt, "TV", kind: "old-pc", size: 20pt, addr: "192.168.1.106", color: ok-color)
    ]
    // 6. DNS: the router asks the DNS server of the provider
    #only(6)[
      #tag(438pt, 72pt, text(fill: hl)[`upb.ro`? \ asks the provider], stroke: 0.8pt + hl, size: 6.5pt)
    ]
    // 7. NAT: everything leaves from the public address
    #only(7)[
      #tag(438pt, 72pt, text(fill: hl)[leaves from \ `203.0.113.42`], stroke: 0.8pt + hl, size: 6.5pt)
    ]
  ]

  #let fs = (
    ("🔌", [a *switch*: the LAN ports, for the wired devices]),
    ("📶", [an *access point*: for the wireless devices]),
    ("🌉", [a *bridge* between the access point and the switch: Wi-Fi and Ethernet become *one network*, the LAN]),
    ("🔀", [a *router*, connected to the switch: one address in the LAN (home), one in the WAN (the provider)]),
    ("🎫", [*DHCP server*: every device gets an address, the mask, the gateway and the DNS server `192.168.1.1`]),
    ("📖", [*DNS*: the devices ask the router, it asks the DNS server of the provider and remembers the answers]),
    ("🔀", [*NAT*: the devices have *private* addresses, the router sends everything from its *one public* address]),
  )
  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #for (i, (e, body)) in fs.enumerate() { only(i + 1, fact(e, body)) }
    #only("8-", fact("🛡️", [and a *firewall*; a Linux computer can do all of these: `dnsmasq` (DHCP, DNS), `nftables` (NAT)]))
  ]))
]
