#import "/src/slides.typ": *
#import "common.typ": ward, tanenbaum, uso-book
// the layers and the network in the OS, from 05 - Network Infrastructure
#import "/src/05_network/internet.typ": highway-slide, osi-slide, os-slide

#show: uso_slides.with(title: "6. Network Services")

#slide[
  == Bibliography

  #text(size: 11pt)[
  #columns(2)[
    + #ward
      - Chapter 9 - _Understanding Your Network and Its Configuration_
    + #tanenbaum
      - Chapter 5 - _The Network Layer_
      - Chapter 6 - _The Transport Layer_
      - Section 7.1 - _DNS, the Domain Name System_
    + #uso-book
      - Chapter 11 - _Rețelistică și Internet_
  ]
  ]
  #v(0pt)
]

// a reminder of the previous lecture
#highway-slide()
#osi-slide()
#os-slide()

#slide[
  == Outline

  #text(size: 12pt)[
  #columns(2)[
    - Transport Layer
      - ports, TCP, UDP
    - DNS
      - names and IP addresses
    - DHCP
    #colbreak()
    - Network Configuration
      - temporary and permanent
    - Troubleshooting
      - no Internet? from the bottom up
    - Home Gateway
      - DHCP, DNS, NAT
  ]
  ]
  #v(0pt)
]

#include "transport.typ"
// #include "config.typ"
#include "dns.typ"
#include "dhcp.typ"
#include "netconfig.typ"
#include "troubleshooting.typ"
#include "gateway.typ"

#slide[
  == We talked about

  - Transport Layer: ports, TCP and UDP
  - DNS: names instead of IP addresses
  - DHCP
  - Network configuration: temporary and permanent, static and dynamic
  - Troubleshooting: no Internet? check from the bottom up
  - The home gateway: switch, access point, router; DHCP, DNS and NAT
]
