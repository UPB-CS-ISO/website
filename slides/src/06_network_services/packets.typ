#import "common.typ": *

#section-cover([Following a Packet], [through all the layers, and back], layers: ("application", "transport", "network", "link"), note: [DNS, DHCP, \ `ping`])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.3 - _Network Layers_
  + #tanenbaum
    - Section 1.4 - _Reference Models_
]

#slide[
  == A DNS Question
  the packet goes down, on the wire, and up

  #let client = (
    ("application", [DNS client (`dig`)], [asks for `upb.ro`]),
    ("transport", [UDP], [port `40211`]),
    ("network", [IP], [`192.168.1.105`]),
    ("link", [Ethernet / Wi-Fi], [the card of the laptop]),
  )
  #let server = (
    ("application", [DNS server], [knows `upb.ro`]),
    ("transport", [UDP], [port `53`]),
    ("network", [IP], [`192.168.1.1`]),
    ("link", [Ethernet / Wi-Fi], [the card of the router]),
  )
  #let q = udp-parts([to the router], [`.105` → `.1`], [`40211` → `53`], [`upb.ro`?])
  #let a = udp-parts([to the laptop], [`.1` → `.105`], [`53` → `40211`], [`141.85.220.33`])
  #for step in range(1, talk-steps + 1) {
    only(step, proto-talk([💻 the laptop], [📡 the home router], client, server, q, a, step))
  }

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("❓", [the DNS client writes the question: this is the *data*]))
    #only(2, fact("🚪", [*UDP* adds its header in front: the ports, `40211` → `53`]))
    #only(3, fact("🏠", [*IP* adds its header: the addresses, `192.168.1.105` → `192.168.1.1`]))
    #only(4, fact("✉️", [the card puts everything in a *frame*: MAC addresses in front, the CRC at the end]))
    #only(5, fact("🔌", [the frame travels on the cable or the radio, to the router]))
    #only(6, fact("✉️", [the card of the router checks the CRC and *removes* the frame]))
    #only(7, fact("🏠", [*IP*: the address is `192.168.1.1`, it is mine; it removes its header]))
    #only(8, fact("🚪", [*UDP*: port `53` is the DNS server; it removes its header]))
    #only(9, fact("📖", [the DNS server gets only the *data*: the question `upb.ro`?]))
    #only(10, fact("↩️", [the answer goes back the same way, with the addresses and the ports *swapped*], c: good-c))
  ]))
]

#slide[
  == A DHCP Request
  the packet goes down, on the wire, and up

  #let client = (
    ("application", [DHCP client], [needs an address]),
    ("transport", [UDP], [port `68`]),
    ("network", [IP], [`0.0.0.0`: no address yet]),
    ("link", [Ethernet / Wi-Fi], [the card of the laptop]),
  )
  #let server = (
    ("application", [DHCP server], [gives addresses]),
    ("transport", [UDP], [port `67`]),
    ("network", [IP], [`192.168.1.1`]),
    ("link", [Ethernet / Wi-Fi], [the card of the router]),
  )
  #let q = udp-parts([to `ff:ff:...`], [`0.0.0.0` → all], [`68` → `67`], [an address?])
  #let a = udp-parts([to `ff:ff:...`], [`.1` → all], [`67` → `68`], [take `.105`])
  #for step in range(1, talk-steps + 1) {
    only(step, proto-talk([💻 the new laptop], [📡 the home router], client, server, q, a, step))
  }

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("❓", [the DHCP client writes the question: _give me an IP address_]))
    #only(2, fact("🚪", [*UDP* adds its header in front: the ports, `68` → `67`]))
    #only(3, fact("📢", [*IP* adds its header: from `0.0.0.0` (no address yet) to `255.255.255.255`, everyone]))
    #only(4, fact("✉️", [the card puts everything in a *frame* to `ff:ff:ff:ff:ff:ff`: every card gets it]))
    #only(5, fact("🔌", [the broadcast frame reaches *every* computer in the network, the router too]))
    #only(6, fact("✉️", [the card of the router checks the CRC and *removes* the frame]))
    #only(7, fact("🏠", [*IP*: `255.255.255.255` is for everyone, so for me too; it removes its header]))
    #only(8, fact("🚪", [*UDP*: port `67` is the DHCP server; it removes its header]))
    #only(9, fact("📖", [the DHCP server gets only the *data*: the request for an address]))
    #only(10, fact("↩️", [the answer goes back, to everyone again: _take_ `192.168.1.105`], c: good-c))
  ]))
]

#slide[
  == A `ping`
  only down to the network layer: no transport, no program on the router

  #let client = (
    ("application", [`ping`], [builds the ICMP message]),
    ("transport", [nothing], [ICMP has no ports]),
    ("network", [IP], [`192.168.1.105`]),
    ("link", [Ethernet / Wi-Fi], [the card of the laptop]),
  )
  #let server = (
    ("application", [no program], [nobody is needed here]),
    ("transport", [nothing], [no ports]),
    ("network", [IP + ICMP], [`192.168.1.1`: the kernel answers]),
    ("link", [Ethernet / Wi-Fi], [the card of the router]),
  )
  #let q = (
    part(0, "network", 62pt, [ICMP], [echo request]),
    part(2, "network", 46pt, [IP], [`.105` → `.1`]),
    part(3, "link", 36pt, [frame], [to the router]),
  )
  #let a = (
    part(0, "network", 62pt, [ICMP], [echo reply]),
    part(2, "network", 46pt, [IP], [`.1` → `.105`]),
    part(3, "link", 36pt, [frame], [to the laptop]),
  )
  // (where, from where, packet, up to layer, color)
  #let g = ok-color
  #let steps = (
    (("l", 0), none, q, 0, hl),
    (("l", 2), ("l", 0), q, 2, hl),
    (("l", 3), ("l", 2), q, 3, hl),
    (("w",), ("l", 3), q, 3, hl),
    (("r", 3), ("w",), q, 3, hl),
    (("r", 2), ("r", 3), q, 2, hl),
    (("r", 2), none, a, 2, g),
    (("r", 3), ("r", 2), a, 3, g),
    (("w",), ("r", 3), a, 3, g),
    (("l", 3), ("w",), a, 3, g),
    (("l", 2), ("l", 3), a, 2, g),
    (("l", 0), ("l", 2), a, 0, g),
  )
  #for (i, (pos, prev, pkt, top, color)) in steps.enumerate() {
    only(i + 1, talk-frame([💻 the laptop], [📡 the home router], client, server, pos, prev: prev, pkt: pkt, top: top, color: color, skip-l: (1,), skip-r: (0, 1)))
  }

  #let good-c = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("❓", [`ping 192.168.1.1` builds an ICMP *echo request*: _are you there?_]))
    #only(2, fact("⏭️", [the *transport* layer is *skipped*: ICMP has no ports, IP adds its header `192.168.1.105` → `192.168.1.1`]))
    #only(3, fact("✉️", [the card puts everything in a *frame*, to the MAC address of the router]))
    #only(4, fact("🔌", [the frame travels on the cable or the radio, to the router]))
    #only(5, fact("✉️", [the card of the router checks the CRC and *removes* the frame]))
    #only(6, fact("⚡", [*IP* sees an ICMP echo request: it does not go up, there is no port and no program]))
    #only(7, fact("↩️", [the *network layer* of the router writes the *echo reply* itself: `ping` works even if no server runs there], c: good-c))
    #only(8, fact("✉️", [the card of the router puts the reply in a frame, to the laptop], c: good-c))
    #only(9, fact("🔙", [the frame travels back on the cable or the radio], c: good-c))
    #only(10, fact("✉️", [the card of the laptop checks the CRC and removes the frame], c: good-c))
    #only(11, fact("🏠", [*IP*: the packet is for `192.168.1.105`, it carries an ICMP echo reply], c: good-c))
    #only(12, fact("📬", [transport *skipped* again: the kernel gives the reply to `ping`, which prints `64 bytes from 192.168.1.1: time=1.2 ms`], c: good-c))
  ]))
]
