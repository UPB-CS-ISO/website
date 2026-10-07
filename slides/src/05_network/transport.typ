#import "common.typ": *

#section-cover([Transport Layer], [which program gets the data], layers: ("transport",), note: [TCP, UDP])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.16 - _The Transport Layer_
  + #tanenbaum
    - Chapter 6 - _The Transport Layer_
      - Section 6.4 - _The Internet Transport Protocols: UDP_
      - Section 6.5 - _The Internet Transport Protocols: TCP_
  + #uso-book
    - Section 11.4.2 - _Adresarea TCP_
]

// a program on the server, with its ports
#let program(y, name, ports, step: 1) = {
  layer-box(330pt, y, 130pt, 30pt, name, "application")
  for (i, p) in ports.enumerate() {
    let py = y + 15pt + (i - (ports.len() - 1) / 2) * 13pt
    pin(300pt, py, box(width: 30pt, height: 11pt, radius: 2pt, fill: luma(55), align(center + horizon, text(
      size: 7pt,
      fill: white,
      weight: "bold",
      font: "DejaVu Sans Mono",
      ":" + str(p),
    ))))
    wire((315pt, py), (330pt, py + 0pt), stroke: 1pt + luma(150))
  }
}

#slide[
  == Ports
  the IP address finds the computer, the *port* finds the program

  #drawing(height: 150pt)[
    // the server, with three programs that wait for data
    #at(270pt, 0pt, box(width: 205pt, height: 150pt, radius: 6pt, stroke: (paint: luma(150), dash: "dashed")))
    #place(top + left, dx: 278pt, dy: 4pt, text(size: 7.5pt, weight: "bold", fill: luma(80))[server `141.85.220.33`])
    #program(22pt, [`sshd` (SSH)], (22,))
    #program(64pt, [`nginx` (Web)], (80, 443))
    #program(106pt, [DNS server], (53,))
    #host(50pt, 75pt, "my PC", addr: "port 51034", size: 30pt)
    #uncover("2-")[
      #draw-arrow((80pt, 75pt), (284pt, 85pt), color: hl, thickness: 1.4pt)
      #letter(170pt, 66pt)[to `141.85.220.33` port `443`]
    ]
    #uncover("3-")[
      #draw-arrow((284pt, 93pt), (80pt, 85pt), color: ok-color, thickness: 1.4pt)
      #letter(185pt, 101pt, color: ok-color)[to my PC, port `51034`]
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1)[- a port is a number (0 - 65535), servers wait on well known ports: `22` SSH, `80` / `443` Web, `53` DNS]
    #only(2)[- 🏢 the IP address is the *building*, the port is the *apartment*]
    #only(3)[- the client gets a random port, so the answer comes back to the right program]
  ]))
]

#slide[
  == TCP and UDP
  the two transport protocols

  #text(size: 10.5pt, table(
    columns: (auto, 1fr, 1fr),
    inset: (x: 7pt, y: 5pt),
    align: left + horizon,
    stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(210)) },
    fill: (x, y) => if y == 0 { accent } else if calc.even(y) { luma(246) } else { white },
    table.header([], text(fill: white, weight: "bold")[#text(size: 1.4em, "📞") TCP], text(
      fill: white,
      weight: "bold",
    )[#text(size: 1.4em, "📮") UDP]),
    [*like*], [a phone call], [a postcard],
    [*connection*], [yes: first "hello", then the data], [no: just send],
    [*lost data*], [sent again], [lost],
    [*order*], [the data arrives in order], [any order],
    [*speed*], [slower], [faster],
    [*used by*], [Web, SSH, e-mail], [DNS, DHCP, video calls, games],
  ))
  #v(0pt)
]

#slide[
  == Ports in Linux
  who waits for data on this computer?

  #reveal-terminal(before: none, lines: (1, 7), full: false)[```terminal
  $ ss -tuln
  Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process
  udp   UNCONN 0      0          127.0.0.1:53        0.0.0.0:*
  udp   UNCONN 0      0            0.0.0.0:68        0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:443       0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*
  tcp   LISTEN 0      128          0.0.0.0:80        0.0.0.0:*
  ```]

  #uncover("2-")[
    #explain(
      [`ss` shows the *sockets*],
      ([`-t` `-u`], [TCP and UDP sockets]),
      ([`-l`], [only the ones that wait for data (*listening*)]),
      ([`-n`], [numbers, not names (`443`, not `https`)]),
      ([`0.0.0.0:22`], [port 22, on every IP address of the computer]),
      ([`127.0.0.1:53`], [port 53, only for programs of this computer]),
    )
  ]
]
