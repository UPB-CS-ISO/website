// "Building a Command": from a question to a tcpdump command, piece by piece.
// Removed from lecture 09 (09_network_infrastructure/capture.typ); an idea for the interactive
// lecture (a command builder). Include it with #include "/extra/tcpdump-builder.typ"
#import "/src/09_network_infrastructure/common.typ": *
#import "/src/09_network_infrastructure/capture.typ": cap-kinds, cap-cmd

// a tcpdump command line, built part by part: the parts stay on one
// straight line, each underlined in the color of its kind, with its label
// below (in a second row, so the words never move); `parts` are
// (text, kind, label, step), a part shows up from its step on
// #cap-builder((("sudo", "program", [as `root`], 1), ("-n", "option", [numbers], 2)))
#let cap-builder(parts, size: 16pt) = grid(
  columns: parts.len(),
  column-gutter: 0.75em,
  row-gutter: 0.45em,
  align: center + bottom,
  ..parts.map(((t, kind, name, step)) => uncover(str(step) + "-", box(
    stroke: (bottom: 2pt + cap-kinds.at(kind)),
    inset: (bottom: 0.25em),
    cap-cmd(t, size: size, command: kind == "program"),
  ))),
  ..parts.map(((t, kind, name, step)) => uncover(str(step) + "-",
    align(center + top, text(size: 10pt, fill: cap-kinds.at(kind), name)))),
)

#slide[
  == Building a Command
  from a question to a command, piece by piece

  #only("1-3")[
    #fact("❓", [*Which DNS questions does my laptop send?* Show only 5 of them, with numbers])
    #v(1.4em)
    #align(center, cap-builder((
      ("sudo", "program", [as `root`], 1),
      ("tcpdump", "program", [the program], 1),
      ("-i wlp2s0", "option", [on the \ Wi-Fi card], 2),
      ("-n", "option", [numbers], 2),
      ("-c 5", "option", [only 5], 2),
      ("udp dst port 53", "filter", [UDP, *to* port 53: \ to a DNS server], 3),
    )))
  ]
  #only("4-")[
    #fact("❓", [*Save the web traffic* (HTTPS) of the Wi-Fi card, to open it later in Wireshark])
    #v(1.4em)
    #align(center, cap-builder((
      ("sudo", "program", [as `root`], 4),
      ("tcpdump", "program", [the program], 4),
      ("-i wlp2s0", "option", [on the \ Wi-Fi card], 5),
      ("-w web.pcap", "option", [into a file], 5),
      ("tcp port 443", "filter", [TCP, port 443: \ HTTPS], 6),
    )))
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only((1, 4), fact("🔑", [the start: `sudo tcpdump`]))
    #only((2, 5), fact("⚙️", [the options: *where* to listen, *how* to show, *how many*, *where* to keep them]))
    #only((3, 6), fact("🔍", [the filter, last: *which* packets]))
  ]))
]
