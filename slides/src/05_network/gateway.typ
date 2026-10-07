#import "common.typ": *

#slide[
  = Home Gateway #text(size: 10pt, weight: "regular")[\ _the box from your Internet provider_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.21 - _Private Networks (IPv4)_
      - Section 9.22 - _Network Address Translation (IP Masquerading)_
  + #uso-book
    - Section 11.4.3 - _Limita de adrese IP_
]

// the inside of a home gateway, revealed step by step
#slide[
  == Home Router
  four devices in one box

  #drawing(height: 172pt)[
    #let sw = (175pt, 138pt)
    #let ap = (175pt, 45pt)
    #let br = (255pt, 100pt)
    #let rt = (345pt, 100pt)
    #area(130pt, 5pt, 260pt, 165pt, [home gateway], color: luma(100), name-at: bottom + right)

    // 1. switch
    #wire((40pt, 100pt), sw)
    #wire((40pt, 145pt), sw)
    #host(40pt, 100pt, "PC", size: 20pt, below: false)
    #host(40pt, 145pt, "TV", kind: "old-pc", size: 20pt, label-size: 7pt)
    #netdev(..sw, "switch", name: "switch", sub: "LAN ports", size: 16pt, label-at: top)

    // 2. access point
    #uncover("2-")[
      #radio((40pt, 35pt), ap)
      #host(40pt, 35pt, "phone", kind: "phone", size: 22pt)
      #netdev(..ap, "wifi-router", name: "access point", size: 26pt, label-at: top)
    ]

    // 3. bridge
    #uncover("3-")[
      #wire((205pt, 45pt), br)
      #wire((205pt, 138pt), br)
      #device(..br, "bridge", sub: "192.168.1.1", layer: "link", width: 60pt, height: 34pt)
      #label(255pt, 135pt, text(fill: accent, size: 7pt)[*LAN* `192.168.1.0/24` \ private])
    ]

    // 4. router
    #uncover("4-")[
      #wire(br, rt)
      #wire(rt, (440pt, 100pt))
      #netdev(..rt, "router", name: "router", size: 28pt)
      #label(390pt, 70pt, text(fill: accent, size: 7pt)[*WAN* \ `203.0.113.42` \ public])
      #pin(445pt, 100pt, pic("cloud", size: 45pt))
      #label(445pt, 130pt, text(size: 7pt)[Internet \ provider (ISP)])
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1)[- a *switch* for the wired devices]
    #only(2)[- an *access point* for the wireless devices]
    #only(3)[- a *bridge* that joins Wi-Fi and Ethernet in *one network*, the LAN]
    #only(4)[- a *router* with two networks: the LAN (home) and the WAN (provider)]
  ]))
]

#slide[
  == Home Router Services

  - *DHCP server*: gives addresses to the devices in the LAN
  - *DNS server*: forwards name questions to the DNS servers of the ISP
  - *firewall*: blocks connections from the Internet to the LAN
  - *NAT* (_Network Address Translation_)
    - the ISP gives a *single public* IP address for the whole home
    - all the devices in the LAN use *private* addresses (`192.168.x.x`)

  #uncover(2)[
    #note-box[💡 a Linux computer can do all of these: a bridge (`br0`), a router (`ip_forward`), an access point (`hostapd`), NAT (`nftables`), DHCP and DNS (`dnsmasq`)]
  ]
]

#slide[
  == NAT
  many private addresses behind one public address

  #drawing(height: 150pt)[
    #area(5pt, 5pt, 250pt, 140pt, [LAN (private)])
    #wire((50pt, 75pt), (230pt, 75pt))
    #wire((230pt, 75pt), (400pt, 75pt))
    #host(50pt, 75pt, "PC", addr: "192.168.1.105", size: 26pt)
    #netdev(230pt, 75pt, "router", name: "router", sub: "203.0.113.42", size: 28pt, highlight: true)
    #pin(420pt, 75pt, pic("cloud", size: 50pt))
    #only(2)[#frame(140pt, 45pt)[from `192.168.1.105:51034` \ to `141.85.220.33:443`]]
    #only(3)[#frame(330pt, 45pt)[from #text(fill: bad-color)[`203.0.113.42:51034`] \ to `141.85.220.33:443`]]
    #only(4)[
      #frame(330pt, 110pt, color: ok-color)[from `141.85.220.33:443` \ to `203.0.113.42:51034`]
      #frame(140pt, 110pt, color: ok-color)[from `141.85.220.33:443` \ to #text(fill: bad-color)[`192.168.1.105:51034`]]
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only("1-2")[- the PC sends a packet to `upb.ro`, from its private address]
    #only(3)[- the router *replaces* the source with its public address and remembers the connection]
    #only(4)[- the answer comes back to the router, which sends it to the PC: *private addresses are not visible on the Internet*]
  ]))
]
