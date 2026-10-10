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
    #only("4-", fact("🔌", [only now the laptop connects, to the *IP address*]))
  ]))
]

// Finding a name: the resolver asks three servers, from the right of the name
// to the left. Each server knows only its part of the tree: a small table,
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
  #let pc = (36pt, 104pt)
  #let res = (150pt, 104pt)
  #let ys = (4pt, 56pt, 108pt)

  // the name, each part in the color of the server that knows it
  #let part(body, c) = box(fill: c.fill, stroke: 0.8pt + c.stroke, radius: 3pt, inset: (x: 5pt, y: 3pt), text(font: "DejaVu Sans Mono", size: 13pt, weight: "bold", body))
  #at(10pt, 8pt, stack(dir: ltr, spacing: 3pt, part("upb", level-colors.upb), text(size: 13pt, weight: "bold", "."), part("ro", level-colors.ro), part(".", level-colors.root)))
  #at(10pt, 38pt, text(size: 7.5pt, fill: luma(80))[read from the *right*: first `.` (the root), \ then `ro`, then `upb.ro`])

  // the three servers, one for each part of the name
  #dns-card(ys.at(0), level-colors.root, [🌍 a root server `.`], (("ro", [ask the `ro` server]), ("com", [ask the `com` server])), on: step == 3, used: if step == 3 { 0 })
  #dns-card(ys.at(1), level-colors.ro, [🇷🇴 a `ro` server], (("upb.ro", [ask the `upb.ro` server]), ("gov.ro", [ask the `gov.ro` server])), on: step == 4, used: if step == 4 { 0 })
  #dns-card(ys.at(2), level-colors.upb, [🏫 a `upb.ro` server], (("upb.ro", [`141.85.220.33`]), ("www.upb.ro", [`141.85.220.33`])), on: step == 5, used: if step == 5 { 0 })

  #host(..pc, "laptop", size: 26pt)
  #host(..res, "DNS server", kind: "dns-server", addr: "the resolver", size: 26pt)

  // the questions and the answers
  #let at-card(i) = (262pt, ys.at(i) + 23pt)
  #if step == 2 { ask(pc, res, [`upb.ro`?], none) }
  #if step == 3 { ask(res, at-card(0), [`upb.ro`?], [ask the `ro` server], gap: 18pt) }
  #if step == 4 { ask(res, at-card(1), [`upb.ro`?], [ask the `upb.ro` server], gap: 18pt) }
  #if step == 5 { ask(res, at-card(2), [`upb.ro`?], [`141.85.220.33`], gap: 18pt) }
  #if step >= 6 {
    ask(pc, res, [`upb.ro`?], [`141.85.220.33`])
    pin(res.at(0), res.at(1) - 28pt, text(size: 8pt, fill: ok-color)[💾 remembered])
  }
]

#slide[
  == Finding a Name
  no server knows everything: each one knows only its part of the tree

  #for step in range(1, 6) { only(step, tree-drawing(step)) }
  #only("6-", tree-drawing(6))

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1, fact("🌳", [the names are a *tree*: the root `.` knows `ro`, `ro` knows `upb.ro`, `upb.ro` knows its addresses]))
    #only(2, fact("❓", [the laptop asks *its* DNS server, the _resolver_; the resolver does not know `upb.ro` yet]))
    #only(3, fact("🌍", [the resolver asks a *root* server, from the right of the name: it only knows who answers for `ro`]))
    #only(4, fact("🇷🇴", [the `ro` server only knows who answers for `upb.ro`]))
    #only(5, fact("🏫", [the `upb.ro` server knows the address: `141.85.220.33`]))
    #only("6-", fact("💾", [the resolver answers and *remembers* the answer: the next question is answered at once]))
  ]))
]

#slide[
  == DNS in Linux

  #reveal-terminal(before: none, lines: (3, 6), full: false)[```terminal
  $ host upb.ro
  upb.ro has address 141.85.220.33
  upb.ro mail is handled by 0 ironport.upb.ro.
  $ resolvectl dns
  Global:
  Link 3 (wlp2s0): 192.168.1.1
  ```]

  #uncover("1-")[#block[- `host` asks the DNS server for the address of a name]]
  #uncover("2-")[#block[- the DNS server comes from DHCP, Fedora keeps it in `systemd-resolved`]]
]

#let name-files = (
  "$ cat /etc/resolv.conf",
  "# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).",
  "# Do not edit.",
  ((none, "nameserver "), ("ns", "127.0.0.53")),
  "options edns0 trust-ad",
  "search .",
  "$ cat /etc/hosts",
  "# Loopback entries; do not change.",
  "# For historical reasons, localhost precedes localhost.localdomain:",
  (("host", "127.0.0.1"), (none, "   localhost localhost.localdomain localhost4 localhost4.localdomain4")),
  (("host", "::1"), (none, "         localhost localhost.localdomain localhost6 localhost6.localdomain6")),
  "# See hosts(5) for proper format and other examples:",
  "# 192.168.1.10 foo.example.org foo",
  "# 192.168.1.13 bar.example.org bar",
)

#slide[
  == Where Do Names Come From?

  #only(1)[
    #parts-terminal(name-files.slice(0, 6), hl: ((("ns",), ip-peach),), size: 0.78em)
    #explain(
      [`/etc/resolv.conf`: the DNS server the programs ask],
      ([`127.0.0.53`], [the local `systemd-resolved`, which asks the real DNS server]),
      ([`#`], [a comment: the file is written by `systemd-resolved`, do not edit it]),
    )
  ]
  #only("2-")[
    #parts-terminal(name-files, hl: ((("host",), ip-peach),), size: 0.78em)
    #explain(
      [`/etc/hosts`: names written by hand, checked *before* DNS],
      ([add], [a line `192.168.1.20 printer`, then `ping printer` works]),
    )
  ]
]

// who answers a name: the program, /etc/hosts, systemd-resolved, the DNS server;
// under each one, where it is configured
#let resolve-box(x, e, name, sub, cfg, c: layer-colors.application) = {
  at(x, 20pt, box(width: 100pt, height: 46pt, radius: 5pt, fill: c.fill, stroke: 1pt + c.stroke, align(center + horizon, stack(
    spacing: 3pt,
    text(size: 9pt, weight: "bold")[#icon(e, size: 11pt) #name],
    text(size: 7.5pt, sub),
  ))))
  at(x, 74pt, box(width: 100pt, text(size: 7.5pt, fill: luma(60), cfg)))
}
#let resolve-drawing(n) = drawing(width: 470pt, height: 150pt)[
  #let xs = (0pt, 123pt, 246pt, 369pt)
  #let boxes = (
    ("🦊", [program], [`ping`, Firefox, `ssh`], [asks with `getaddrinfo()`; the order: `/etc/nsswitch.conf`]),
    ("📒", [`/etc/hosts`], [names written by hand], [checked *first*; edit it with `sudo`]),
    ("🧭", [`systemd-resolved`], [`127.0.0.53`, remembers answers], [`/etc/resolv.conf` sends the programs here]),
    ("📖", [DNS server], [`192.168.1.1`, the router], [from *DHCP*, or set by hand with `nmcli`]),
  )
  #label(235pt, 8pt, text(size: 8pt, fill: luma(90))[🔎 `upb.ro`? each one asks the next, until one knows the answer])
  #for (i, (e, name, sub, cfg)) in boxes.enumerate() {
    if i < n {
      resolve-box(xs.at(i), e, name, sub, cfg)
      if i > 0 { draw-arrow((xs.at(i) - 21pt, 43pt), (xs.at(i) - 2pt, 43pt), color: hl, thickness: 1.4pt) }
    }
  }
  #if n >= 4 {
    draw-arrow((419pt, 120pt), (50pt, 120pt), color: ok-color, thickness: 1.4pt)
    label(235pt, 131pt, text(size: 8pt, fill: ok-color)[`141.85.220.33` comes back to the program])
  }
]

#slide[
  == Who Answers a Name?
  four places, and where each one is configured

  #for n in range(1, 4) { only(n, resolve-drawing(n)) }
  #only("4-", resolve-drawing(4))

  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("🦊", [a program does not talk to DNS itself: it asks the C library (`getaddrinfo()`)]))
    #only(2, fact("📒", [`/etc/hosts` first: a name written there never reaches DNS]))
    #only(3, fact("🧭", [then `systemd-resolved`, a local service: it remembers the answers (a *cache*)]))
    #only("4-", fact("📖", [it asks the *DNS server* of the card: usually the home router, received with DHCP]))
  ]))
]

#let dns-cfg = (
  "$ resolvectl status wlp2s0",
  "Link 3 (wlp2s0)",
  "    Current Scopes: DNS",
  ((none, "Current DNS Server: "), ("cur", "192.168.1.1")),
  ((none, "       DNS Servers: "), ("cur", "192.168.1.1")),
  "$ sudo nmcli connection modify HomeWiFi \\",
  ((none, "    "), ("dns", "ipv4.dns \"1.1.1.1 8.8.8.8\""), (none, " \\")),
  ((none, "    "), ("auto", "ipv4.ignore-auto-dns yes")),
  "$ sudo nmcli connection up HomeWiFi",
  "$ resolvectl dns wlp2s0",
  ((none, "Link 3 (wlp2s0): "), ("new", "1.1.1.1 8.8.8.8")),
  "$ sudo resolvectl dns wlp2s0 9.9.9.9",
)

#slide[
  == Configuring DNS
  see it with `resolvectl`, change it with `nmcli`

  #let steps = (
    (5, ("cur",), explain(
      [`resolvectl status`: the DNS server of each card],
      ([`192.168.1.1`], [the home router: it came with *DHCP*, together with the IP address]),
    )),
    (9, ("dns", "auto"), explain(
      [💾 *permanent*: in the NetworkManager connection],
      ([`ipv4.dns`], [one or more DNS servers, in order]),
      ([`ignore-auto-dns`], [do not use the DNS server from DHCP]),
      ([`connection up`], [use the new configuration now]),
    )),
    (11, ("new",), explain[`resolvectl dns`: the card uses the new DNS servers]),
    (12, (), explain(
      [⏳ *temporary*: `resolvectl dns` with an address changes it now, until the card reconnects],
      ([Ubuntu], [_netplan_: `nameservers: addresses: [1.1.1.1]`]),
    )),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(dns-cfg.slice(0, n), hl: ((keys, ip-peach),), size: 0.8em)
      #body
    ]
  }
]

#let resolv-edit = (
  "$ ls -l /etc/resolv.conf",
  ((none, "lrwxrwxrwx. 1 root root 39 Oct  6 09:12 /etc/resolv.conf -> "), ("link", "../run/systemd/resolve/stub-resolv.conf")),
  "$ echo \"nameserver 1.1.1.1\" | sudo tee /etc/resolv.conf",
  ((none, "nameserver "), ("new", "1.1.1.1")),
  "$ ping -c 1 upb.ro",
  ((none, "PING upb.ro ("), ("ok", "141.85.220.33"), (none, ") 56(84) bytes of data.")),
  "$ sudo nmcli connection up HomeWiFi",
  "Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/7)",
  "$ tail -n 3 /etc/resolv.conf",
  ((none, "nameserver "), ("old", "127.0.0.53")),
  "options edns0 trust-ad",
  "search .",
)

#slide[
  == Editing /etc/resolv.conf
  it works, until a service writes it again

  #let bad = (hl: bad-color.lighten(75%), bg: bad-color.lighten(93%), bar: bad-color)
  #let steps = (
    (2, ("link",), explain(
      [`/etc/resolv.conf` is a *link* to a file of `systemd-resolved`],
      ([`->`], [the service writes the real file, in `/run` (lost at reboot)]),
    )),
    (6, ("new", "ok"), explain(
      [you *can* edit it (as `root`): the change is used *now*],
      ([`1.1.1.1`], [the programs ask this DNS server directly, without `systemd-resolved`]),
    )),
    (12, ("old",), explain(
      colors: bad,
      [❌ after a reconnect (or a reboot) the file is *written again*],
      ([`127.0.0.53`], [`systemd-resolved` and NetworkManager own this file]),
    )),
    (12, (), explain(
      [🔧 to keep a DNS server: configure the service that writes the file],
      ([NetworkManager], [`nmcli connection modify ... ipv4.dns 1.1.1.1` (the slide before)]),
      ([`dns=none`], [in `/etc/NetworkManager/conf.d/`: NetworkManager leaves the file alone]),
      ([others], [`dhclient`, netplan, VPN clients may write it too]),
    )),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(resolv-edit.slice(0, n), hl: ((("old",), bad), (keys, ip-peach)), size: 0.74em)
      #body
    ]
  }
]

#slide[
  == Without DNS?

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #text(fill: ok-color, weight: "bold")[✅ works: everything that uses an IP address]
    #set text(size: 10.5pt)
    - `ping 8.8.8.8`
    - `ssh student@192.168.1.20`
    - the local network, printers, shared folders by IP
    - names written in `/etc/hosts`
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
