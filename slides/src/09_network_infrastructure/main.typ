#import "/src/slides.typ": *
#import "common.typ": ward, tanenbaum, uso-book

#show: uso_slides.with(title: "9. Network Infrastructure")
// commands written as inline code get the terminal colors (`ping 8.8.8.8`)
#show: shell-commands.with(extra: (
  "ping", "ip", "nmcli", "traceroute", "tcpdump", "tshark", "curl", "resolvectl", "dnf", "ss", "netstat",
))

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
    - Network Layer
      - IP addresses, `ping`
    - Routing
      - ARP, gateway, routers, `traceroute`, NAT
    #colbreak()
    - Transport Layer
      - ports, TCP, UDP
    - DNS
      - names instead of IP addresses
    - DHCP
      - automatic network configuration
    - Home Gateway
      - DHCP, DNS, NAT
    - Capturing Packets
      - `tcpdump`, Wireshark
    - Troubleshooting
      - no Internet? what to check
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
#include "transport.typ"
#include "dns.typ"
#include "dhcp.typ"
#include "gateway.typ"
#include "capture.typ"
#include "troubleshooting.typ"

#slide[
  == We talked about

  - The Internet, Internet services and the network layers
  - Link Layer: network cards, MAC addresses
  - Ethernet: frames, hubs and switches
  - Wi-Fi: frames, access points, network types, the networks around with `nmcli`
  - Network Layer: IPv4 addresses, masks, `ping`, frames, IPv6
  - Routing: ARP, the gateway, routers, `traceroute`, NAT
  - Transport Layer: ports, TCP and UDP
  - DNS: names instead of IP addresses, the tree of DNS servers
  - DHCP: the IP address, mask, gateway and DNS server, received automatically
  - Home Gateway: switch, access point, router; DHCP, DNS and NAT
  - Capturing Packets: `tcpdump`, Wireshark
  - Troubleshooting: no Internet? what to check, from the bottom up
]
