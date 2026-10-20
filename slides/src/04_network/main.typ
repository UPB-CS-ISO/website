#import "/src/slides.typ": *
#import "common.typ": tanenbaum, uso-book, ward

#show: uso_slides.with(title: "5. Introduction to Networking")

#slide[
  == Bibliography

  #text(size: 11pt)[
    #columns(2)[
      + #ward
        - Chapter 9 - _Understanding Your Network and Its Configuration_
      + #tanenbaum
        - Chapter 1 - _Introduction_
        - Chapter 3 - _The Data Link Layer_
        - Chapter 4 - _The Medium Access Control Sublayer_
        - Chapter 5 - _The Network Layer_
        - Chapter 6 - _The Transport Layer_
        - Section 7.1 - _DNS, the Domain Name System_
      #colbreak()
      3. #uso-book
        - Chapter 8 - _Componente hardware_
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
        - hubs, switches
      - Wi-Fi
        - access points, `nmcli`
      - Network Layer
        - IP addresses, IPv6, `ip addr`
      - Routing
        - routers, `ip route`
      #colbreak()
      - Testing the Network
        - `ping`
      - Transport Layer
        - ports, TCP, UDP
      - DNS and DHCP
      - Network Configuration
        - temporary and permanent
      - Troubleshooting
    ]
  ]
  #v(0pt)
]

#include "internet.typ"
#include "link.typ"
#include "ethernet.typ"
#include "wifi.typ"
#include "network.typ"
#include "routing.typ"
#include "ping.typ"
// #include "capture.typ"
#include "transport.typ"
#include "dns.typ"
#include "dhcp.typ"
// #include "netconfig.typ"
#include "troubleshooting.typ"

#slide[
  == We talked about

  - The Internet, Internet services and the network layers
  - Link Layer: network cards, MAC addresses
  - Ethernet: hubs and switches
  - Wi-Fi: access points, connecting with `nmcli`
  - Network Layer: IPv4 addresses, masks, IPv6, `ip addr`
  - Routing: routers, the routing table
  - Testing the network: `ping`
  - Transport Layer: ports, TCP and UDP
  - DNS: names instead of IP addresses; DHCP
  - Network configuration: temporary and permanent, static and dynamic
  - Troubleshooting: no Internet? check from the bottom up
]
