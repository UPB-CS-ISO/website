#import "common.typ": *

#section-cover([DNS], [names instead of IP addresses], layers: ("application",), note: [DNS])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.15 - _Resolving Hostnames_
  + #tanenbaum
    - Section 7.1 - _DNS, the Domain Name System_
  + #uso-book
    - Section 11.2.2 - _Nume în Internet. DNS_
]

// a question from a to b (above the line) and its answer from b to a (below it)
#let ask(a, b, q, ans, gap: 22pt, off: 5pt, ans-off: 10pt) = {
  let (dx, dy) = ((b.at(0) - a.at(0)).pt(), (b.at(1) - a.at(1)).pt())
  let len = calc.sqrt(dx * dx + dy * dy)
  let (ux, uy) = (dx / len, dy / len)
  let move(p, s, o) = (p.at(0) + (ux * s.pt() - uy * o.pt()) * 1pt, p.at(1) + (uy * s.pt() + ux * o.pt()) * 1pt)
  let mid = ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2)
  draw-arrow(move(a, gap, -off), move(b, -gap, -off), color: hl, thickness: 1.4pt)
  pin(..move(mid, 0pt, -off - 10pt), box(fill: white, inset: 1.5pt, text(size: 7pt, fill: hl, q)))
  if ans != none {
    draw-arrow(move(b, -gap, off), move(a, gap, off), color: ok-color, thickness: 1.4pt)
    pin(..move(mid, 0pt, off + ans-off), box(fill: white, inset: 1.5pt, text(size: 7pt, fill: ok-color, ans)))
  }
}
#let ring(p, size: 34pt) = pin(..p, box(width: size, height: size, radius: 50%, stroke: 1.5pt + hl))

#slide[
  == DNS
  _Domain Name System_, the phone book of the Internet

  #let (pc, dns, web) = ((45pt, 105pt), (235pt, 35pt), (425pt, 105pt))
  #drawing(width: 470pt, height: 160pt)[
    #host(..pc, "laptop", addr: "192.168.1.105", size: 30pt)
    #host(..dns, "DNS server", kind: "dns-server", addr: "192.168.1.1", size: 28pt)
    #host(..web, "upb.ro", kind: "server", addr: "141.85.220.33", size: 30pt)
    #only(2, ask(pc, dns, [`upb.ro`?], none))
    #only("3-", ask(pc, dns, [`upb.ro`?], [`141.85.220.33`]))
    #only("4-")[
      #draw-arrow((pc.at(0) + 26pt, pc.at(1)), (web.at(0) - 26pt, web.at(1)), color: accent, thickness: 1.4pt)
      #label(235pt, 115pt, text(size: 7.5pt, fill: accent)[connect to `141.85.220.33`])
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🏷️", [computers use *IP addresses*, people use *names*]))
    #only(2, fact("❓", [the laptop asks a *DNS server*: what is the IP address of `upb.ro`?]))
    #only(3, fact("📖", [the DNS server answers with the address]))
    #only("4-", fact("🔌", [only now does the laptop connect to the *IP address*]))
  ]))
]

// #slide[
//   == What DNS Knows
//   more than addresses: each name has *records*

//   #let records = (
//     ("A", [the *IPv4 address* of the name], [`upb.ro` → `141.85.220.33`],
//       [the browser asks for it, then connects to `141.85.220.33`]),
//     ("AAAA", [the *IPv6 address* of the name], [`google.com` → `2a00:1450:4007:817::200e`],
//       [the same, for IPv6; a name can have both, `upb.ro` has only `A`]),
//     ("MX", [the *mail server* of the domain], [`upb.ro` → `ironport.upb.ro`],
//       [an e-mail to `someone@upb.ro` is sent to this server]),
//     ("NS", [the *DNS servers* of the domain], [`upb.ro` → `pub.pub.ro`, `pub2.pub.ro`],
//       [the servers that know all the records of `upb.ro`: the `ro` server sends you to them]),
//     ("CNAME", [another name for the same thing (_alias_)], [`www.github.com` → `github.com`],
//       [_"ask for_ `github.com` _instead"_: the resolver asks again, for the real name]),
//     ("TXT", [any text: e-mail rules, proof of owning the domain], [`upb.ro` → `"v=spf1 ..."`],
//       [_SPF_: which servers may send e-mail as `@upb.ro`, against spam]),
//     ("PTR", [the *name* of an address (backwards)], [`8.8.8.8` → `dns.google`],
//       [from an address to a name: used in logs, by mail servers, by `traceroute`]),
//   )
//   #let rec-table(on) = text(size: 9.5pt, table(
//     columns: (auto, 1fr, auto),
//     inset: (x: 7pt, y: 3.5pt),
//     align: left + horizon,
//     stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(210)) },
//     fill: (x, y) => if y == 0 { accent } else if y - 1 == on { hl-bg } else if calc.even(y) { luma(246) } else { white },
//     table.header(..([record], [what it says], [example]).map(h => text(fill: white, weight: "bold", h))),
//     ..records.map(((t, what, ex, why)) => (text(weight: "bold", raw(t)), what, ex)).flatten(),
//   ))
//   #for (i, (t, what, ex, why)) in records.enumerate() {
//     only(i + 1)[
//       #rec-table(i)
//       #v(2pt)
//       #fact("💡", [#raw(t): #why])
//     ]
//   }
//   #only(records.len() + 1)[
//     #rec-table(none)
//     #v(2pt)
//     #fact("⏳", [every record also has a *TTL*: how long others may remember it])
//   ]
// ]

// // Finding a name: the resolver asks three servers, from the right of the name
// // to the left. Each server knows only its part of the tree: a small table,
// // the row used on a step is highlighted.
// #let level-colors = (
//   root: (fill: luma(238), stroke: luma(120)),
//   ro: layer-colors.transport,
//   upb: layer-colors.application,
// )
// #let dns-card(y, c, title, rows, on: false, used: none) = at(262pt, y, box(
//   width: 206pt,
//   height: 46pt,
//   radius: 4pt,
//   fill: c.fill.lighten(50%),
//   stroke: if on { 1.8pt + hl } else { 0.8pt + c.stroke },
//   inset: (x: 6pt, y: 4pt),
//   stack(
//     spacing: 3pt,
//     text(size: 8pt, weight: "bold", title),
//     text(size: 7pt, table(
//       columns: (52pt, 1fr),
//       inset: (x: 3pt, y: 1.5pt),
//       stroke: none,
//       fill: (x, y) => if y == used { hl-bg } else { none },
//       ..rows.map(((n, a)) => (raw(n), a)).flatten(),
//     )),
//   ),
// ))
// #let tree-drawing(step) = drawing(width: 470pt, height: 158pt)[
//   #let pc = (36pt, 104pt)
//   #let res = (150pt, 104pt)
//   #let ys = (4pt, 56pt, 108pt)

//   // the name, each part in the color of the server that knows it
//   #let part(body, c) = box(fill: c.fill, stroke: 0.8pt + c.stroke, radius: 3pt, inset: (x: 5pt, y: 3pt), text(font: "DejaVu Sans Mono", size: 13pt, weight: "bold", body))
//   #at(10pt, 8pt, stack(dir: ltr, spacing: 3pt, part("upb", level-colors.upb), text(size: 13pt, weight: "bold", "."), part("ro", level-colors.ro), part(".", level-colors.root)))
//   #at(10pt, 38pt, text(size: 7.5pt, fill: luma(80))[read from the *right*: first `.` (the root), \ then `ro`, then `upb.ro`])

//   // the three servers, one for each part of the name
//   #dns-card(ys.at(0), level-colors.root, [🌍 a root DNS server `.` #h(1fr) `198.41.0.4`], (("ro", [ask the `ro` DNS server `192.162.16.18`]), ("com", [ask the `com` DNS server `192.5.6.30`])), on: step == 3, used: if step == 3 { 0 })
//   #dns-card(ys.at(1), level-colors.ro, [🇷🇴 a `ro` DNS server #h(1fr) `192.162.16.18`], (("upb.ro", [ask the `upb.ro` DNS server `141.85.128.1`]), ("gov.ro", [ask the `gov.ro` DNS server `193.151.29.206`])), on: step == 4, used: if step == 4 { 0 })
//   #dns-card(ys.at(2), level-colors.upb, [🏫 a `upb.ro` DNS server #h(1fr) `141.85.128.1`], (("upb.ro", [`141.85.220.33`, TTL `8640` s]), ("www.upb.ro", [`141.85.220.33`, TTL `8640` s])), on: step == 5, used: if step == 5 { 0 })

//   #host(..pc, "laptop", size: 26pt)
//   #host(..res, "DNS server", kind: "dns-server", addr: "the resolver", size: 26pt)

//   // the questions and the answers
//   #let at-card(i) = (262pt, ys.at(i) + 23pt)
//   #if step == 2 { ask(pc, res, [`upb.ro`?], none) }
//   #if step == 3 { ask(res, at-card(0), [`upb.ro`?], [ask the `ro` DNS server \ `192.162.16.18`], gap: 18pt) }
//   #if step == 4 { ask(res, at-card(1), [`upb.ro`?], [ask the `upb.ro` DNS server \ `141.85.128.1`], gap: 18pt, ans-off: 20pt) }
//   #if step == 5 { ask(res, at-card(2), [`upb.ro`?], [`141.85.220.33`], gap: 18pt) }
//   #if step >= 6 {
//     ask(pc, res, [`upb.ro`?], [`141.85.220.33`])
//     pin(res.at(0), res.at(1) - 28pt, text(size: 8pt, fill: ok-color)[💾 remembered for `8640` s])
//   }
// ]

// #slide[
//   == Finding a Name
//   no server knows everything: each one knows only its part of the tree

//   #for step in range(1, 6) { only(step, tree-drawing(step)) }
//   #only("6-", tree-drawing(6))

//   #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
//     #only(1, fact("🌳", [the names are a *tree*: the root `.` knows `ro`, `ro` knows `upb.ro`, `upb.ro` knows its addresses]))
//     #only(2, fact("❓", [the laptop asks *its* DNS server, the _resolver_; the resolver does not know `upb.ro` yet]))
//     #only(3, fact("🌍", [the *root servers* are the top of the tree: 13 names (`a` to `m.root-servers.net`), with copies all over the world; every resolver knows them, they only know who answers for `ro`, `com`, ...]))
//     #only(4, fact("🇷🇴", [the `ro` server only knows who answers for `upb.ro`: it gives its *IP address*, not its name (a name would need one more question)]))
//     #only(5, fact("🏫", [the `upb.ro` server knows the address, `141.85.220.33`, and how long others may remember it: the *TTL*]))
//     #only("6-", fact("💾", [the resolver *remembers* the answer for its *TTL* (_time to live_), set by the `upb.ro` server: `8640` s, 2.4 hours; then it asks again]))
//   ]))
// ]

#let dns-linux = (
  "$ host upb.ro",
  ((none, "upb.ro has address "), ("addr", "141.85.220.33")),
  ((none, "upb.ro mail is handled by 0 "), ("mx", "ironport.upb.ro.")),
  "$ resolvectl dns",
  (("global", "Global:"),),
  ((none, ""), ("link", "Link 2 (enp0s31f6)"), (none, ": "), ("srv", "192.168.1.1")),
)

#slide[
  == DNS in Linux
  ask for a name, see which DNS server is used

  #let steps = (
    (
      3,
      ("addr", "mx"),
      explain(
        [`host`: asks the DNS server for a name, shows the answer in short],
        ([`141.85.220.33`], [the address (the `A` record)]),
        ([`ironport.upb.ro.`], [the mail server (the `MX` record)]),
      ),
    ),
    (
      6,
      ("global", "link", "srv"),
      explain(
        [`resolvectl` talks to `systemd-resolved`, the local service that asks DNS for the programs],
        ([`dns`], [show the DNS server that *each network card* uses]),
        ([`Global:`], [a DNS server for all the cards: none here]),
        ([`Link 2 (enp0s31f6)`], [the Ethernet card asks `192.168.1.1`, the router; it came with *DHCP*]),
      ),
    ),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(dns-linux.slice(0, n), hl: ((keys, ip-peach),), size: 0.95em)
      #body
    ]
  }
]

// // `dig`: the answer of a DNS server, only the important lines
// #let dig-local = (
//   "$ dig upb.ro    # only the important lines are shown",
//   ((none, ";; ->>HEADER<<- opcode: QUERY, "), ("status", "status: NOERROR"), (none, ", id: 48510")),
//   ";; QUESTION SECTION:",
//   ((none, ";"), ("q", "upb.ro.            IN  A")),
//   ";; ANSWER SECTION:",
//   (
//     ("name", "upb.ro."),
//     (none, "         "),
//     ("ttl", "6858"),
//     (none, "  IN  "),
//     ("type", "A"),
//     (none, "   "),
//     ("addr", "141.85.220.33"),
//   ),
//   ((none, ";; "), ("time", "Query time: 0 msec")),
//   ((none, ";; "), ("server", "SERVER: 127.0.0.53#53(127.0.0.53) (UDP)")),
// )
// #let dig-other = (
//   "$ dig @1.1.1.1 upb.ro    # only the important lines are shown",
//   ";; ANSWER SECTION:",
//   ((none, "upb.ro.         "), ("ttl2", "8640"), (none, "  IN  A   141.85.220.33")),
//   ((none, ";; "), ("time2", "Query time: 48 msec")),
//   ((none, ";; "), ("server2", "SERVER: 1.1.1.1#53(1.1.1.1) (UDP)")),
//   "$ dig +short upb.ro MX",
//   (("mx", "0 ironport.upb.ro."),),
// )

// #slide[
//   == `dig`
//   ask a DNS server, see its answer

//   #let steps = (
//     (
//       dig-local,
//       ("status",),
//       explain(
//         [`dig` asks for a name and shows what the DNS server answered],
//         ([`NOERROR`], [the name exists; a name that does not exist gives `NXDOMAIN`]),
//       ),
//     ),
//     (
//       dig-local,
//       ("q",),
//       explain(
//         [the *question*],
//         ([`upb.ro.`], [the name; the `.` at the end is the root of the tree]),
//         ([`A`], [the kind of record: an IPv4 address]),
//       ),
//     ),
//     (
//       dig-local,
//       ("ttl", "type", "addr"),
//       explain(
//         [the *answer*],
//         ([`141.85.220.33`], [the address of `upb.ro`]),
//         ([`6858`], [the TTL: seconds left in the cache (it started at `8640`)]),
//       ),
//     ),
//     (
//       dig-local,
//       ("server", "time"),
//       explain(
//         [who answered, and how fast],
//         ([`127.0.0.53#53`], [`systemd-resolved`, on port `53`, over UDP]),
//         ([`0 msec`], [it was already in the cache: no question went on the network]),
//       ),
//     ),
//     (
//       dig-other.slice(0, 5),
//       ("server2", "time2", "ttl2"),
//       explain(
//         [`@` chooses the DNS server to ask],
//         ([`@1.1.1.1`], [ask Cloudflare's DNS server directly, not `systemd-resolved`]),
//         ([`48 msec`], [the question went on the Internet]),
//         ([`8640`], [a fresh answer: the whole TTL]),
//       ),
//     ),
//     (
//       dig-other,
//       ("mx",),
//       explain(
//         [another kind of record, only the answer],
//         ([`MX`], [the mail server of `upb.ro`: `ironport.upb.ro`]),
//         ([`+short`], [no sections, only the answer]),
//       ),
//     ),
//   )
//   #for (i, (lines, keys, body)) in steps.enumerate() {
//     only(i + 1)[
//       #parts-terminal(lines, hl: ((keys, ip-peach),), size: 0.95em)
//       #body
//     ]
//   }
// ]

#slide[
  == Without DNS?

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #text(fill: ok-color, weight: "bold")[✅ works: everything that uses an IP address]
    #set text(size: 10.5pt)
    - `ping 8.8.8.8`
    - `ssh student@192.168.1.20`
    - the local network, printers, shared folders by IP
    - connections that were already open
  ][
    #uncover("2-")[
      #text(fill: bad-color, weight: "bold")[❌ fails: everything that uses a name]
      #set text(size: 10.5pt)
      - opening `upb.ro` in the browser
      - `ping google.com`, e-mail, `dnf upgrade`
      - websites opened by IP may not work: one server hosts many sites, HTTPS certificates are for *names*
    ]
  ]

  #uncover("3-")[
    ```terminal
    $ ping -c 1 8.8.8.8
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.4 ms
    $ ping -c 1 google.com
    ping: google.com: Temporary failure in name resolution
    ```
  ]
]
