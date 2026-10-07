#import "common.typ": *

#slide[
  = DHCP #text(size: 10pt, weight: "regular")[\ _automatic network configuration_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.13 - _Network Configuration Managers_
      - Section 9.18 - _Understanding DHCP_
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

// one message of the DHCP exchange: an arrow between the two lifelines
#let dhcp-msg(n, y, right, name, body) = uncover(str(n) + "-")[
  #let (x1, x2) = if right { (95pt, 385pt) } else { (385pt, 95pt) }
  #draw-arrow((x1, y), (x2, y), color: if right { hl } else { ok-color })
  #label(240pt, y - 9pt, text(size: 8pt)[*#name* #h(0.3em) #body])
]

#slide[
  == How DHCP Works
  four messages

  #drawing(height: 170pt)[
    #host(70pt, 20pt, "client", addr: "no address yet", size: 22pt, below: false)
    #netdev(410pt, 10pt, "wifi-router", size: 22pt)
    #label(410pt, 32pt, text(size: 7pt)[*DHCP server* \ `192.168.1.1`])
    #wire((70pt, 48pt), (70pt, 168pt), stroke: (paint: luma(120), dash: "dashed"))
    #wire((410pt, 48pt), (410pt, 168pt), stroke: (paint: luma(120), dash: "dashed"))
    #dhcp-msg(1, 68pt, true, "DISCOVER", [(broadcast): is there a DHCP server?])
    #dhcp-msg(2, 98pt, false, "OFFER", [take `192.168.1.105/24`, gateway and DNS `.1`, 24 h])
    #dhcp-msg(3, 128pt, true, "REQUEST", [(broadcast): I want `192.168.1.105`])
    #dhcp-msg(4, 158pt, false, "ACK", [it is yours for 24 hours])
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    - the client has no IP address and does not know the server: it sends *broadcasts* (`ff:ff:ff:ff:ff:ff`, `255.255.255.255`)
  ]))
]

#slide[
  == DHCP in Linux
  Fedora uses NetworkManager

  #text(size: 0.9em)[```terminal
  $ nmcli device show wlp2s0 | grep IP4
  IP4.ADDRESS[1]:                         192.168.1.105/24
  IP4.GATEWAY:                            192.168.1.1
  IP4.ROUTE[1]:                           dst = 192.168.1.0/24, nh = 0.0.0.0, mt = 600
  IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.1.1, mt = 600
  IP4.DNS[1]:                             192.168.1.1
  ```]

  #uncover("2-")[
    #block[- `IP4.ADDRESS`, `IP4.GATEWAY`, `IP4.DNS`: everything the computer needs, received from DHCP]
  ]
  #v(0pt)
]
