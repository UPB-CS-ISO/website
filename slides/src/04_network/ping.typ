#import "common.typ": *

#section-cover([Testing the Network], [is it there? which way?], layers: ("network",), note: [`ping`])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.8 - _Basic ICMP and DNS Tools_
  + #tanenbaum
    - Section 5.6.4 - _Internet Control Protocols_
  + #link("https://man7.org/linux/man-pages/man8/ping.8.html")[`man ping`]
]

#slide[
  == Hub, Switch, AP, Router

  #text(size: 10pt)[
    #align(center, table(
      columns: (auto, 1fr, 1fr, 1fr, 1fr),
      inset: 5pt,
      stroke: 0.6pt + luma(170),
      align: left + horizon,
      table.header(
        [],
        align(center, pic("hub", size: 14pt)) + [*Hub*],
        align(center, pic("switch", size: 14pt)) + [*Switch*],
        align(center, pic("wifi-router", size: 20pt)) + [*Access Point*],
        align(center, pic(
          "router",
          size: 20pt,
        ))
          + [*Router*],
      ),
      [*Layer*],
      table.cell(fill: layer-colors.physical.fill)[1: bits],
      table.cell(fill: layer-colors.link.fill)[2: frames],
      table.cell(fill: layer-colors.link.fill)[2: frames],
      table.cell(fill: layer-colors.network.fill)[3: packets],

      [*Uses*], [nothing], [MAC addresses], [MAC addresses], [IP addresses],
      [*Sends to*], [all ports], [the destination port], [the destination device (radio)], [the next network],
      [*Medium*], [shared cable], [one cable per port], [shared radio], [one per network],
      [*Connects*], [devices], [devices of one network], [wireless devices to a wired network], [*different networks*],
    ))
  ]
  #v(0pt)
]

// the steps of a shell: (lines shown, highlighted parts, explanation)
#let test-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size)
    #body
  ]
}

// ---------------------------------------------------------------------------
// ping
// ---------------------------------------------------------------------------

#let ping-ok = (
  "$ ping -c 4 141.85.220.33",
  ((none, "PING "), ("ip", "141.85.220.33"), (none, " (141.85.220.33) 56(84) bytes of data.")),
  ..range(1, 5).map(i => (
    (none, "64 bytes from 141.85.220.33: "),
    ("seq", "icmp_seq=" + str(i)),
    (none, " "),
    ("ttl", "ttl=60"),
    (none, " "),
    ("time", "time=" + ("4.21", "3.98", "4.05", "4.11").at(i - 1) + " ms"),
  )),
  "",
  "--- 141.85.220.33 ping statistics ---",
  ((none, "4 packets transmitted, 4 received, "), ("loss", "0% packet loss"), (none, ", time 3005ms")),
  ((none, "rtt "), ("rtt", "min/avg/max"), (none, "/mdev = "), ("rtt", "3.980/4.087/4.210"), (none, "/0.084 ms")),
)

#slide[
  == `ping`
  is that computer there? does it answer?

  #test-steps(
    ping-ok,
    (
      (
        2,
        ("ip",),
        explain(
          [`ping` sends an ICMP *echo request*, the computer answers with an *echo reply*],
          ([`-c 4`], [only 4 times; without it, `ping` runs until #box[`Ctrl+C`]]),
          ([`141.85.220.33`], [the IP address of the computer we test]),
        ),
      ),
      (
        6,
        ("seq", "ttl", "time"),
        explain(
          [one line for every answer],
          ([`icmp_seq`], [the number of the request: a missing number is a *lost* packet]),
          ([`ttl`], [the TTL left in the answer: it started at 64, so it passed 4 routers]),
          ([`time`], [the round trip: there and back]),
        ),
      ),
      (
        10,
        ("loss", "rtt"),
        explain(
          [the *statistics*, at the end],
          ([`packet loss`], [`0%` is good; a few lost packets: a bad Wi-Fi or a busy network]),
          ([`min/avg/max`], [the shortest, the average and the longest round trip, in ms]),
        ),
      ),
    ),
    size: 0.82em,
  )
]

// four ways for `ping` to fail, and what each one means
#let ping-fails = (
  (
    (
      "$ ping -c 1 8.8.8.8",
      ((none, "ping: connect: "), ("err", "Network is unreachable")),
    ),
    explain(
      [no *route* to that network: usually no *default gateway*],
      ([check], [`ip route`: is there a `default via ...` line?]),
    ),
  ),
  (
    (
      "$ ping -c 1 192.168.1.20",
      "PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.",
      ((none, "From 192.168.1.105 icmp_seq=1 "), ("err", "Destination Host Unreachable")),
    ),
    explain(
      [a computer in *my network*, but nobody answered with a *MAC address*],
      ([why], [the computer is off, or the IP address is wrong]),
    ),
  ),
  (
    (
      "$ ping -c 2 141.85.220.250",
      "PING 141.85.220.250 (141.85.220.250) 56(84) bytes of data.",
      "",
      "--- 141.85.220.250 ping statistics ---",
      ((none, "2 packets transmitted, 0 received, "), ("err", "100% packet loss"), (none, ", time 1031ms")),
    ),
    explain(
      [the packets leave, *no answer* comes back],
      ([why], [the computer is down, or a *firewall* drops `ping` (many servers do)]),
      ([💡], [no answer to `ping` does not always mean the computer is down]),
    ),
  ),
)

#slide[
  == When `ping` Fails
  the error tells where the problem is

  #let bad = (hl: bad-color.lighten(75%), bg: bad-color.lighten(93%), bar: bad-color)
  #for (i, (lines, body)) in ping-fails.enumerate() {
    only(i + 1)[
      #parts-terminal(lines, hl: ((("err",), bad),), size: 0.9em)
      #body
    ]
  }
]

// #let ping6 = (
//   "$ ping -c 2 2a00:1450:4017:80e::200e",
//   ((none, "PING "), ("ip", "2a00:1450:4017:80e::200e"), (none, " (2a00:1450:4017:80e::200e) 56 data bytes")),
//   ((none, "64 bytes from 2a00:1450:4017:80e::200e: icmp_seq=1 "), ("ttl", "ttl=117"), (none, " time=12.4 ms")),
//   ((none, "64 bytes from 2a00:1450:4017:80e::200e: icmp_seq=2 "), ("ttl", "ttl=117"), (none, " time=12.1 ms")),
//   "$ ping -c 1 ::1",
//   ((none, "PING "), ("lo", "::1"), (none, " (::1) 56 data bytes")),
//   "64 bytes from ::1: icmp_seq=1 ttl=64 time=0.041 ms",
//   "$ ping -c 1 fe80::1%enp0s31f6",
//   ((none, "PING fe80::1"), ("zone", "%enp0s31f6"), (none, " (fe80::1%enp0s31f6) 56 data bytes")),
//   "64 bytes from fe80::1%enp0s31f6: icmp_seq=1 ttl=64 time=0.41 ms",
// )

// #slide[
//   == `ping` with IPv6
//   the same command, longer addresses

//   #test-steps(ping6, (
//     (4, ("ip", "ttl"), explain(
//       [`ping` works with IPv6 too: it sees an IPv6 address and uses IPv6],
//       ([`ttl`], [in IPv6 it is called _hop limit_, the same idea]),
//     )),
//     (7, ("lo",), explain[`::1`: the loopback, this computer, like `127.0.0.1`]),
//     (10, ("zone",), explain(
//       [a _link local_ address needs the *card*: every card has an `fe80::` network],
//       ([`%enp0s31f6`], [send it on the Ethernet card]),
//     )),
//   ), size: 0.85em)
// ]

// ---------------------------------------------------------------------------
// traceroute
// ---------------------------------------------------------------------------

// #let trace = (
//   "$ traceroute -n 141.85.220.33",
//   ((none, "traceroute to 141.85.220.33 (141.85.220.33), "), ("max", "30 hops max"), (none, ", 60 byte packets")),
//   (
//     (none, " "),
//     ("hop", "1"),
//     (none, "  "),
//     ("router", "192.168.1.1"),
//     (none, "    "),
//     ("time", "1.912 ms  1.874 ms  1.851 ms"),
//   ),
//   (
//     (none, " "),
//     ("hop", "2"),
//     (none, "  "),
//     ("router", "10.20.0.1"),
//     (none, "      "),
//     ("time", "3.420 ms  3.402 ms  3.389 ms"),
//   ),
//   ((none, " "), ("hop", "3"), (none, "  "), ("star", "* * *")),
//   (
//     (none, " "),
//     ("hop", "4"),
//     (none, "  "),
//     ("router", "37.128.225.9"),
//     (none, "   "),
//     ("time", "4.103 ms  4.087 ms  4.152 ms"),
//   ),
//   (
//     (none, " "),
//     ("hop", "5"),
//     (none, "  "),
//     ("dest", "141.85.220.33"),
//     (none, "  "),
//     ("time", "4.210 ms  4.198 ms  4.176 ms"),
//   ),
// )

// #slide[
//   == `traceroute`
//   which routers are on the way?

//   #test-steps(
//     trace,
//     (
//       (
//         2,
//         ("max",),
//         explain(
//           [`traceroute`: the *routers* between this computer and the destination],
//           ([`-n`], [show the routers by their IP addresses only (faster)]),
//           ([`30 hops max`], [it gives up after 30 routers]),
//         ),
//       ),
//       (
//         4,
//         ("hop", "router", "time"),
//         explain(
//           [one line for every router (*hop*), in order],
//           ([`1`], [the first router is the *gateway*, `192.168.1.1`]),
//           ([`ms`], [three tries, three round trip times]),
//         ),
//       ),
//       (
//         5,
//         ("star",),
//         explain(
//           [`* * *`: this router did *not* answer],
//           ([💡], [many routers do not answer, but they still *forward* the packets]),
//         ),
//       ),
//       (
//         7,
//         ("dest",),
//         explain(
//           [the last line is the *destination*: it was reached],
//           ([install], [`sudo dnf install traceroute` (Fedora), `sudo apt install traceroute` (Ubuntu)]),
//           ([`tracepath`], [usually installed already, it does almost the same]),
//         ),
//       ),
//     ),
//     size: 0.85em,
//   )
// ]

// // how traceroute finds the routers: packets with TTL 1, 2, 3, ...
// #let trace-drawing(k) = drawing(width: 470pt, height: 104pt)[
//   #let y = 42pt
//   #let xs = (35pt, 160pt, 285pt, 420pt)
//   #for i in range(3) { wire((xs.at(i), y), (xs.at(i + 1), y)) }
//   #host(xs.at(0), y, "my laptop", size: 26pt)
//   #netdev(xs.at(1), y, "router", name: "gateway", size: 22pt)
//   #netdev(xs.at(2), y, "router", name: "router", size: 22pt)
//   #host(xs.at(3), y, "server", kind: "server", size: 26pt)
//   // the packet goes k hops; every router subtracts 1 from its TTL
//   #for i in range(k) {
//     let (a, b) = (xs.at(i), xs.at(i + 1))
//     draw-arrow((a + 20pt, y - 14pt), (b - 20pt, y - 14pt), color: hl, thickness: 1.8pt)
//     tag((a + b) / 2, y - 25pt, [TTL #(k - i)], fill: hl-bg, stroke: 0.8pt + hl)
//   }
//   // the answer comes back to the laptop
//   #let reached = k == 3
//   #let c = if reached { ok-color } else { luma(110) }
//   #draw-arrow((xs.at(k), y + 42pt), (xs.at(0), y + 42pt), color: c, thickness: 1.4pt, dash: if reached { none } else {
//     "dashed"
//   })
//   #label((xs.at(0) + xs.at(k)) / 2, y + 52pt, text(
//     size: 7.5pt,
//     fill: c,
//     if reached [✅ echo reply: the destination] else [⏱️ TTL 0: dropped, _"time exceeded"_ comes back],
//   ))
//   #wire((xs.at(k), y + 34pt), (xs.at(k), y + 42pt), stroke: (
//     paint: c,
//     thickness: 1.4pt,
//     dash: if reached { none } else { "dashed" },
//   ))
//   #if not reached { pin(xs.at(k), y - 26pt, text(size: 12pt, "💥")) }
// ]

// #slide[
//   == How `traceroute` Works
//   with the TTL of the IP packets

//   #for k in range(1, 4) {
//     only(k, trace-drawing(k))
//   }

//   #set text(size: 10pt)
//   #only(1, fact(
//     "1️⃣",
//     [*TTL 1*: the gateway subtracts 1, gets `0`, drops the packet and tells the sender: now we know *router 1*],
//   ))
//   #only(2, fact("2️⃣", [*TTL 2*: the packet passes the gateway, the next router drops it: now we know *router 2*]))
//   #only(3, fact("✅", [*TTL 3*: the packet reaches the destination, which answers: done], c: (
//     fill: ok-color.lighten(90%),
//     stroke: ok-color,
//   )))
// ]
