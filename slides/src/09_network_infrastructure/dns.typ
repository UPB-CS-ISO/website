#import "common.typ": *

#section-cover([DNS], [names instead of IP addresses], layers: ("application",), note: [DNS])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.14 - _Resolving Hostnames_
  + #tanenbaum
    - Section 7.1 - _DNS, the Domain Name System_
  + #uso-book
    - Section 11.2.2 - _Nume în Internet. DNS_
]

// a question from a to b (above the line) and its answer from b to a (below it)
#let ask(a, b, q, ans, gap: 22pt, off: 5pt) = {
  let (dx, dy) = ((b.at(0) - a.at(0)).pt(), (b.at(1) - a.at(1)).pt())
  let len = calc.sqrt(dx * dx + dy * dy)
  let (ux, uy) = (dx / len, dy / len)
  let move(p, s, o) = (p.at(0) + (ux * s.pt() - uy * o.pt()) * 1pt, p.at(1) + (uy * s.pt() + ux * o.pt()) * 1pt)
  let mid = ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2)
  draw-arrow(move(a, gap, -off), move(b, -gap, -off), color: hl, thickness: 1.4pt)
  pin(..move(mid, 0pt, -off - 10pt), box(fill: white, inset: 1.5pt, text(size: 7pt, fill: hl, q)))
  if ans != none {
    draw-arrow(move(b, -gap, off), move(a, gap, off), color: ok-color, thickness: 1.4pt)
    pin(..move(mid, 0pt, off + 10pt), box(fill: white, inset: 1.5pt, text(size: 7pt, fill: ok-color, ans)))
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
    #host(..web, "upb.ro", kind: "server", addr: "141.85.228.17", size: 30pt)
    #only(2, ask(pc, dns, [`upb.ro`?], none))
    #only("3-", ask(pc, dns, [`upb.ro`?], [`141.85.228.17`]))
    #only("4-")[
      #draw-arrow((pc.at(0) + 26pt, pc.at(1)), (web.at(0) - 26pt, web.at(1)), color: accent, thickness: 1.4pt)
      #label(235pt, 115pt, text(size: 7.5pt, fill: accent)[connect to `141.85.228.17`])
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🏷️", [computers use *IP addresses*, people use *names*]))
    #only(2, fact("❓", [the laptop asks *its* DNS server (at home, the router): what is the IP address of `upb.ro`?]))
    #only(3, fact("📖", [the DNS server answers with the address]))
    #only("4-", fact("🔌", [only now does the laptop connect, to the *IP address*]))
  ]))
]

// Finding a name: the laptop asks the home router, the router forwards the
// question to the resolver of the provider, and the resolver asks three
// servers, from the right of the name to the left. Each server knows only its part of the tree: a small table,
// the row used on a step is highlighted.
#let level-colors = (
  root: (fill: luma(238), stroke: luma(120)),
  ro: layer-colors.transport,
  upb: layer-colors.application,
)
#let dns-card(y, c, title, rows, on: false, used: none) = at(262pt, y, box(
  width: 206pt,
  height: 46pt,
  radius: 4pt,
  fill: c.fill.lighten(50%),
  stroke: if on { 1.8pt + hl } else { 0.8pt + c.stroke },
  inset: (x: 6pt, y: 4pt),
  stack(
    spacing: 3pt,
    text(size: 8pt, weight: "bold", title),
    text(size: 7pt, table(
      columns: (52pt, 1fr),
      inset: (x: 3pt, y: 1.5pt),
      stroke: none,
      fill: (x, y) => if y == used { hl-bg } else { none },
      ..rows.map(((n, a)) => (raw(n), a)).flatten(),
    )),
  ),
))
#let tree-drawing(step) = drawing(width: 470pt, height: 158pt)[
  #let pc = (24pt, 104pt)
  #let rt = (104pt, 104pt)
  #let res = (190pt, 104pt)
  #let ys = (4pt, 56pt, 108pt)

  // the name, each part in the color of the server that knows it
  #let part(body, c) = box(fill: c.fill, stroke: 0.8pt + c.stroke, radius: 3pt, inset: (x: 5pt, y: 3pt), text(font: "DejaVu Sans Mono", size: 13pt, weight: "bold", body))
  #at(10pt, 8pt, stack(dir: ltr, spacing: 3pt, part("upb", level-colors.upb), text(size: 13pt, weight: "bold", "."), part("ro", level-colors.ro), part(".", level-colors.root)))
  #at(10pt, 38pt, text(size: 7.5pt, fill: luma(80))[read from the *right*: first `.` (the root), \ then `ro`, then `upb.ro`])

  // the three servers, one for each part of the name
  #dns-card(ys.at(0), level-colors.root, [🌍 a root server `.`], (("ro", [ask the `ro` server]), ("com", [ask the `com` server])), on: step == 3, used: if step == 3 { 0 })
  #dns-card(ys.at(1), level-colors.ro, [🇷🇴 a `ro` server], (("upb.ro", [ask `pub.pub.ro`, ...]), ("gov.ro", [ask `ns1.stsisp.ro`, ...])), on: step == 4, used: if step == 4 { 0 })
  #dns-card(ys.at(2), level-colors.upb, [🏫 `pub.pub.ro`: a name server of `upb.ro`], (("upb.ro", [`141.85.228.17`]), ("www.upb.ro", [`141.85.228.17`])), on: step == 5, used: if step == 5 { 0 })

  #host(..pc, "laptop", size: 24pt)
  #host(..rt, "home router", kind: "wifi-router", addr: "192.168.1.1", size: 22pt)
  // the resolver, with its label above and to the left: its questions leave
  // to the right (up and down), the answers of the router come from the left
  #pin(..res, box(fill: white, pic("dns-server", size: 26pt)))
  #place(top + left, dx: 110pt, dy: 64pt, box(width: 86pt, align(right, stack(
    spacing: 2pt,
    text(size: 8pt, weight: "bold")[resolver],
    text(size: 7pt, font: "DejaVu Sans Mono")[of the provider],
  ))))

  // the questions and the answers
  #let at-card(i) = (262pt, ys.at(i) + 23pt)
  #if step == 2 {
    ask(pc, rt, [`upb.ro`?], none, gap: 16pt)
    ask(rt, res, [`upb.ro`?], none, gap: 16pt)
  }
  #if step == 3 { ask(res, at-card(0), [`upb.ro`?], [ask the `ro` server], gap: 18pt) }
  #if step == 4 { ask(res, at-card(1), [`upb.ro`?], [ask `pub.pub.ro`], gap: 18pt) }
  #if step == 5 { ask(res, at-card(2), [`upb.ro`?], [`141.85.228.17`], gap: 18pt) }
  #if step >= 6 {
    ask(pc, rt, [`upb.ro`?], [✅], gap: 16pt)
    ask(rt, res, [`upb.ro`?], [✅], gap: 16pt)
    pin(res.at(0), res.at(1) + 24pt, text(size: 7.5pt, fill: ok-color)[💾 remembered])
    pin(rt.at(0), rt.at(1) - 30pt, text(size: 7.5pt, fill: ok-color)[💾 remembered])
    at(0pt, 142pt, text(size: 7.5pt, fill: ok-color)[✅ `upb.ro` is `141.85.228.17`])
  }
]

#slide[
  == Finding a Name
  no server knows everything: each one knows only its part of the tree

  #for step in range(1, 6) { only(step, tree-drawing(step)) }
  #only("6-", tree-drawing(6))

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🌳", [the names are a *tree*: the root `.` knows the servers of `ro`, `ro` knows the *name servers* of `upb.ro`, and they know its addresses]))
    #only(2, fact("❓", [the laptop asks the home router; the router only *forwards* the question to the DNS server of the provider, the _resolver_]))
    #only(3, fact("🌍", [the resolver asks a *root* server, from the right of the name: it only knows who answers for `ro`]))
    #only(4, fact("🇷🇴", [the `ro` server knows only the *name servers* of `upb.ro` (_NS_ records), chosen by its owner: here UPB's own, often a provider such as Cloudflare]))
    #only(5, fact("🏫", [`pub.pub.ro`, a name server of `upb.ro`, knows the address: `141.85.228.17`]))
    #only("6-", fact("💾", [the answer comes back; the resolver and the router *remember* it for a time set by the owner of the name (the _TTL_), so the next question is answered at once]))
  ]))
]

#slide[
  == DNS in Linux
  ask for a name, see which DNS server the laptop asks

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #reveal-terminal(before: none, lines: (3, 7), full: false)[```terminal
    $ host upb.ro
    upb.ro has address 141.85.228.17
    upb.ro mail is handled by 0 ironport.upb.ro.
    $ resolvectl dns
    Global:
    ...
    Link 3 (wlp2s0): 192.168.1.1
    ```]
  ][
    #set text(size: 0.85em)
    #uncover("1-")[#block[
      - `host` asks the DNS server about a name
      - a name has several _records_:
        - `has address`: an IPv4 address (an *A* record; *AAAA* for IPv6)
        - `mail is handled by`: the mail server of the name (*MX*)
        - `host -t ns upb.ro`: its name servers (*NS*), `pub.pub.ro` and `pub2.pub.ro`
    ]]
    #uncover("2-")[#block[
      - `resolvectl dns` shows the DNS server the laptop asks
        - it came from DHCP (next)
        - `resolvectl` talks to `systemd-resolved`, the service that asks DNS for the programs (next lecture)
    ]]
  ]
]

#slide[
  == Without DNS?
  addresses still work, names do not

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #text(fill: ok-color, weight: "bold")[✅ works: everything that uses an IP address]
    #set text(size: 10.5pt)
    - `ping 8.8.8.8`
    - `ssh alice@192.168.1.10`
    - the local network, printers, shared folders by IP
    - names written by hand in the file `/etc/hosts` (next lecture)
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
