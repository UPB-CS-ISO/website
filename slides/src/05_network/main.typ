#import "/src/slides.typ": *
#import "common.typ": ward, tanenbaum, uso-book

#show: uso_slides.with(title: "5. Network")

#slide[
  == Bibliography

  #text(size: 11pt)[
  #columns(2)[
    + #ward
      - Chapter 9 - _Understanding Your Network and Its Configuration_
    + #tanenbaum
      - Chapter 1 - _Introduction_
      - Chapter 4 - _The Medium Access Control Sublayer_
      - Chapter 5 - _The Network Layer_
      - Section 7.1 - _DNS, the Domain Name System_
    + #uso-book
      - Chapter 11 - _Rețelistică și Internet_
  ]
  ]
  #v(0pt)
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #text(size: 20pt)[
    #align(center + horizon)[
      _There is no place like_ `127.0.0.1`
    ]
  ]
  #v(0pt)
]

#slide[
  == Outline

  #text(size: 12pt)[
  #columns(2)[
    - The Internet
    - Link Layer
      - network cards, MAC addresses
    - Ethernet
      - frames, hubs, switches
    - Wi-Fi
      - frames, access points
    #colbreak()
    - Network Layer
      - IP addresses, routers
    - Transport Layer
      - ports, TCP, UDP
    - Home Gateway
    - Connecting to the Internet
    - DHCP
    - Network Configuration
  ]
  ]
  #v(0pt)
]

#include "internet.typ"
#include "link.typ"
#include "ethernet.typ"
#include "wifi.typ"
#include "network.typ"
// #include "transport.typ"
#include "gateway.typ"
// #include "config.typ"
#include "dhcp.typ"
#include "netconfig.typ"

#slide[
  == We talked about

  - The Internet, Internet services and the network layers
  - Link Layer: network cards, MAC addresses
  - Ethernet: frames, hubs and switches
  - Wi-Fi: frames, access points, connecting with `nmcli`
  - Network Layer: IPv4 addresses, masks, routers
  - Transport Layer: ports, TCP and UDP
  - The home gateway and NAT
  - What a computer needs for the Internet: IP address and mask, gateway, DNS
  - DHCP
  - Network configuration: temporary and permanent, static and dynamic
]
