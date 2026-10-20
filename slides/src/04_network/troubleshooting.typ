#import "common.typ": *

#section-cover(
  [Troubleshooting],
  [the Internet does not work: what now?],
  layers: ("application", "transport", "network", "link", "physical"),
  note: [from the \ bottom up],
)

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.8 - _Basic ICMP and DNS Tools_
      - Section 9.15 - _Resolving Hostnames_
  + #uso-book
    - Section 11.5 - _Configurări de rețea_
]

// the checks, from the bottom up: (short name, layer, question, command, fix when it fails)
#let checks = (
  ([card], "link", [is the card *connected*?], "ip -br link", [plug the cable, turn the Wi-Fi on]),
  ([address], "network", [do I have an *IP address*?], "ip -br address", [DHCP failed: connect again]),
  ([gateway], "network", [do I have a *gateway*?], "ip route", [add the default gateway]),
  ([Internet], "network", [does the *Internet* answer?], "ping 8.8.8.8", [the router or the provider]),
  ([DNS], "application", [do *names* work?], "ping upb.ro", [set a DNS server]),
  ([server], "transport", [does the *server* answer?], "curl -I https://upb.ro", [the server, not my network]),
)

// the checks as a table: the number in the color of its layer, the question,
// the command and what to do when the answer is no; `shown` rows are visible
#let check-table(shown) = text(size: 10pt, table(
  columns: (22pt, 1fr, auto, auto),
  inset: (x: 6pt, y: 4pt),
  align: (center + horizon, left + horizon, left + horizon, left + horizon),
  stroke: (x, y) => if y == 0 { (bottom: 1pt + luma(150)) } else { (bottom: 0.5pt + luma(215)) },
  table.header(
    [], text(fill: luma(90))[*question*], text(fill: luma(90))[*command*], text(fill: bad-color)[*if not* 🔧]
  ),
  ..checks
    .enumerate()
    .map(((i, (name, layer, question, cmd, fix))) => {
      let c = layer-colors.at(layer)
      let cells = (
        box(width: 18pt, height: 18pt, radius: 50%, fill: c.fill, stroke: 1pt + c.stroke, align(center + horizon, text(
          size: 9pt,
          weight: "bold",
          str(i + 1),
        ))),
        question,
        raw(cmd),
        text(size: 9.5pt, fix),
      )
      if i < shown { cells } else { cells.map(x => hide(x)) }
    })
    .flatten(),
))

#slide[
  == No Internet?
  check from the *bottom up*: the first check that fails shows the problem

  #for k in range(1, checks.len() + 1) { only(k, check-table(k)) }
  #only(str(checks.len() + 1) + "-", check-table(checks.len()))
  #only(str(checks.len() + 1) + "-", place(bottom + left, block(
    width: 100%,
    note-box[💡 "Wi-Fi connected, but no Internet" is very often a *DNS* problem],
  )))
]

// // where we are: the 6 checks, the done ones with a ✓, the current one highlighted
// #let check-progress(n) = {
//   set text(size: 7.5pt)
//   stack(dir: ltr, spacing: 4pt, ..checks.enumerate().map(((i, (name, layer, ..rest))) => {
//     let c = layer-colors.at(layer)
//     let current = i + 1 == n
//     box(
//       fill: if i + 1 <= n { c.fill } else { white },
//       stroke: if current { 1.5pt + hl } else { 0.6pt + c.stroke },
//       radius: 8pt,
//       inset: (x: 6pt, y: 3pt),
//       text(weight: if current { "bold" } else { "regular" }, fill: if i + 1 <= n { black } else { luma(140) })[#if i + 1 < n [✓] else [#(i + 1)] #name],
//     )
//   }))
// }

// // a check: where we are, a terminal with the problem highlighted, what it means, how to fix it
// #let bad = (hl: bad-color.lighten(75%), bg: bad-color.lighten(93%), bar: bad-color)
// #let good = (hl: ok-color.lighten(70%), bg: ok-color.lighten(93%), bar: ok-color)
// #let check-slide(n, title, sub, lines, meaning, fix, size: 0.85em) = slide[
//   #heading(level: 2)[#n. #title]
//   #sub
//   #check-progress(n)

//   #parts-terminal(lines, hl: ((("bad",), bad), (("ok",), good)), size: size)
//   #text(size: 9.5pt, grid(
//     columns: (1fr, 1fr),
//     column-gutter: 8pt,
//     explain(colors: bad, ..meaning),
//     uncover(2, explain(colors: good, ..fix)),
//   ))
//   #v(0pt)
// ]

// #check-slide(1, [Is the Card Connected?], [the physical and the data link layers], (
//   "$ ip -br link",
//   tab((17, 15, 18), (none, "lo"), (none, "UNKNOWN"), (none, "00:00:00:00:00:00")) + ((none, "<LOOPBACK,UP,LOWER_UP>"),),
//   tab((17, 15, 18), (none, "enp0s31f6"), ("bad", "DOWN"), (none, "8c:16:45:a2:3b:91")) + ((none, "<"), ("bad", "NO-CARRIER"), (none, ",BROADCAST,MULTICAST,UP>")),
//   tab((17, 15, 18), (none, "wlp2s0"), ("bad", "DOWN"), (none, "3c:a9:f4:5e:21:7b")) + ((none, "<BROADCAST,MULTICAST>"),),
//   "$ nmcli radio wifi",
//   (("bad", "disabled"),),
// ), (
//   [❌ no card, except `lo`, is `UP` with `LOWER_UP`: no link],
//   ([`NO-CARRIER`], [the cable is not plugged in, or broken]),
//   ([`disabled`], [the Wi-Fi radio is off]),
// ), (
//   [🔧 connect the card],
//   ([cable], [plug it in (both ends), try another cable]),
//   ([Wi-Fi], [`nmcli radio wifi on`, then `nmcli device wifi connect HomeWiFi --ask`]),
// ))

// #check-slide(2, [Do I Have an Address?], [the network layer: the IP address and the mask], (
//   "$ ip -br address show enp0s31f6",
//   tab((17, 15), (none, "enp0s31f6"), (none, "UP")) + (("bad", "fe80::8e16:45ff:fea2:3b91/64"),),
// ), (
//   [❌ only an IPv6 _link local_ address: *no IPv4 address*],
//   ([why], [nobody answered the DHCP request (DHCP server down, or the card is in the wrong network)]),
//   ([`169.254.x.x`], [the same problem: the computer picked an address by itself]),
// ), (
//   [🔧 ask again, or configure it by hand],
//   ([DHCP], [`nmcli device disconnect enp0s31f6`, then `nmcli device connect enp0s31f6`]),
//   ([static], [`sudo ip address add 192.168.1.50/24 dev enp0s31f6`]),
// ))

// #check-slide(3, [Do I Have a Gateway?], [the network layer: the route to the other networks], (
//   "$ ip route",
//   "192.168.1.0/24 dev enp0s31f6 proto kernel scope link src 192.168.1.105 metric 100",
//   "$ ping -c 1 8.8.8.8",
//   ((none, "ping: connect: "), ("bad", "Network is unreachable")),
// ), (
//   [❌ no `default via ...` line: only the local network works],
//   ([why], [the gateway was not given by DHCP, or the static configuration has none]),
// ), (
//   [🔧 add the gateway],
//   ([now], [`sudo ip route add default via 192.168.1.1`]),
//   ([permanent], [_Settings_ → IPv4 → Gateway, or `routes:` in _netplan_]),
// ))

// #check-slide(4, [Does the Internet Answer?], [the network layer: the gateway, then beyond it], (
//   "$ ping -c 2 -q 192.168.1.1",
//   "--- 192.168.1.1 ping statistics ---",
//   ((none, "2 packets transmitted, 2 received, "), ("ok", "0% packet loss"), (none, ", time 1002ms")),
//   "$ ping -c 2 -q 8.8.8.8",
//   "--- 8.8.8.8 ping statistics ---",
//   ((none, "2 packets transmitted, 0 received, "), ("bad", "100% packet loss"), (none, ", time 1031ms")),
// ), (
//   [❌ the gateway answers, the Internet does not: the problem is *after* the home router],
//   ([`100% packet loss`], [the packets get to the router, but no further]),
// ), (
//   [🔧 not your computer],
//   ([router], [restart the home router, check its WAN connection]),
//   ([provider], [call the Internet provider]),
// ), size: 0.8em)

// #check-slide(5, [Does DNS Work?], [names to IP addresses], (
//   "$ ping -c 1 upb.ro",
//   ((none, "ping: upb.ro: "), ("bad", "Temporary failure in name resolution")),
//   "$ resolvectl dns",
//   "Global:",
//   ((none, "Link 2 (enp0s31f6): "), ("bad", "")),
//   "$ host upb.ro 1.1.1.1",
//   ((none, "upb.ro has address "), ("ok", "141.85.220.33")),
// ), (
//   [❌ `ping 8.8.8.8` works, names do not: *no DNS server*],
//   ([`resolvectl`], [no DNS server for the card]),
//   ([`host ... 1.1.1.1`], [asking another DNS server directly works]),
// ), (
//   [🔧 set a DNS server],
//   ([now], [`sudo resolvectl dns enp0s31f6 1.1.1.1`]),
//   ([permanent], [_Settings_ → IPv4 → DNS, or `nameservers:` in _netplan_]),
// ))

// #check-slide(6, [Does the Server Answer?], [the transport and the application layers], (
//   "$ curl -I https://upb.ro",
//   ((none, "curl: (7) "), ("bad", "Failed to connect to upb.ro port 443"), (none, " after 3002 ms")),
//   "$ curl -I https://www.kernel.org",
//   (("ok", "HTTP/2 200"),),
// ), (
//   [❌ the name works, the server does not answer on port `443`],
//   ([why], [the server is down, or a firewall blocks the port]),
//   ([other sites], [work: *my* network is fine]),
// ), (
//   [🔧 not your network],
//   ([wait], [or tell the people who run the server]),
//   ([`nc -zv upb.ro 443`], [test the port again later]),
// ))

// #slide[
//   == More Tools
//   test every layer

//   #let row(layer, cmd, what) = {
//     let c = layer-colors.at(layer)
//     (
//       table.cell(fill: c.fill, text(size: 8pt, weight: "bold", upper(layer.first()) + layer.slice(1))),
//       raw(cmd),
//       what,
//     )
//   }
//   #text(size: 10pt, table(
//     columns: (auto, auto, 1fr),
//     inset: (x: 7pt, y: 5pt),
//     align: left + horizon,
//     stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(210)) },
//     fill: (x, y) => if y == 0 { accent } else { none },
//     table.header(..([layer], [command], [it answers]).map(h => text(fill: white, weight: "bold", h))),
//     ..row("network", "ping 192.168.1.1", [does the computer answer?]),
//     ..row("transport", "nc -zv upb.ro 443", [does a program wait on this port? (`Connected`)]),
//     ..row("application", "host upb.ro", [which IP address does this name have? (DNS)]),
//     ..row("application", "curl -I https://upb.ro", [does the web server answer?]),
//   ))
//   #v(0pt)
// ]
