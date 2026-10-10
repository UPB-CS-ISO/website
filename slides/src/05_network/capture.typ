#import "common.typ": *

#section-cover([Capturing Packets], [see what goes through the card], layers: ("link", "network"), note: [tcpdump, \ Wireshark])

#slide[
  == Bibliography
  for this section

  + #link("https://www.tcpdump.org/manpages/tcpdump.1.html")[`man tcpdump`]
  + #link("https://www.wireshark.org/docs/wsug_html_chunked/")[Wireshark User's Guide]
]

// the steps of a shell: (lines shown, highlighted parts, explanation)
#let shell-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size)
    #body
  ]
}

// ---------------------------------------------------------------------------
// Capturing packets: tcpdump, Wireshark
// ---------------------------------------------------------------------------

#let cap-icmp = (
  "$ sudo tcpdump -i wlp2s0 -n -t icmp",
  "tcpdump: verbose output suppressed, use -v[v]... for full protocol decode",
  "listening on wlp2s0, link-type EN10MB (Ethernet), snapshot length 262144 bytes",
  ((none, "IP "), ("ip", "192.168.1.105 > 141.85.220.33"), (none, ": "), ("icmp", "ICMP echo request"), (none, ", id 7, seq 1, length 64")),
  ((none, "IP "), ("ip", "141.85.220.33 > 192.168.1.105"), (none, ": "), ("icmp", "ICMP echo reply"), (none, ", id 7, seq 1, length 64")),
  "^C",
  "2 packets captured",
)

#slide[
  == Capturing Packets
  `tcpdump`: see every packet that goes in or out of a card

  #shell-steps(cap-icmp, (
    (3, (), explain(
      [`tcpdump` waits and shows the packets, one per line],
      ([`sudo`], [only `root` may read all the packets of a card]),
      ([`-i wlp2s0`], [the card to listen on]),
      ([`-n -t`], [numbers, not names; no time on each line]),
      ([`icmp`], [a *filter*: only the ICMP packets (`ping`)]),
    )),
    (5, ("ip", "icmp"), explain(
      [meanwhile, in another terminal: `ping -c 1 141.85.220.33`],
      ([`a > b`], [the packet goes from `a` to `b`]),
      ([`echo`], [the request, then the reply]),
    )),
    (7, (), explain(
      [`Ctrl+C` stops it],
      ([`-w ping.pcap`], [save the packets in a file; `tcpdump -r ping.pcap` reads them again]),
      ([install], [`sudo dnf install tcpdump`, `sudo apt install tcpdump`]),
    )),
  ), size: 0.78em)
]

#let cap-arp = (
  "$ sudo tcpdump -i wlp2s0 -n -t -e arp",
  ((none, ""), ("mac", "3c:a9:f4:5e:21:7b > ff:ff:ff:ff:ff:ff"), (none, ", ethertype "), ("type", "ARP (0x0806)"), (none, ", length 42:")),
  ((none, "    "), ("ask", "Request who-has 192.168.1.1 tell 192.168.1.105"), (none, ", length 28")),
  ((none, ""), ("mac2", "a4:2b:b0:1c:9e:44 > 3c:a9:f4:5e:21:7b"), (none, ", ethertype ARP (0x0806), length 42:")),
  ((none, "    "), ("answer", "Reply 192.168.1.1 is-at a4:2b:b0:1c:9e:44"), (none, ", length 28")),
)

#slide[
  == Capturing Frames
  `-e`: the Ethernet header too, here ARP finds a MAC address

  #shell-steps(cap-arp, (
    (3, ("mac", "type", "ask"), explain(
      [the laptop asks *everybody*: who has `192.168.1.1`?],
      ([`-e`], [show the MAC addresses and the type of the frame]),
      ([`ff:ff:...`], [*broadcast*: every card receives it]),
      ([`0x0806`], [the *Type* field: an ARP message, not an IP packet]),
    )),
    (5, ("mac2", "answer"), explain(
      [the gateway answers *only to the laptop*, with its MAC address],
      ([💡], [`ip neigh` shows what the laptop found: `192.168.1.1` is `a4:2b:b0:1c:9e:44`]),
    )),
  ), size: 0.82em)
]

#slide[
  == Wireshark
  packet capture, with windows

  #set text(size: 10pt)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 8pt,
    row-gutter: 6pt,
    fact("🦈", [*Wireshark* captures like `tcpdump`, and splits every packet into its *layers*: the frame, the IP packet, the data]),
    fact("💾", [`sudo tcpdump -i wlp2s0 -w cap.pcap` on any computer, then open `cap.pcap` in Wireshark]),
    uncover("2-", fact("🔍", [*filters*: `icmp`, `arp`, `ip.addr == 192.168.1.1`, `eth.addr == ff:ff:ff:ff:ff:ff`])),
    uncover("2-", fact("⌨️", [`tshark`: Wireshark in the terminal; install: `sudo dnf install wireshark`])),
    uncover("3-", fact("🔒", [capture only *your own* network: other people's traffic is private], c: (fill: bad-color.lighten(92%), stroke: bad-color))),
    uncover("3-", fact("💡", [encrypted data stays *encrypted*: you see the addresses, not the content])),
  )
  #v(0pt)
]
