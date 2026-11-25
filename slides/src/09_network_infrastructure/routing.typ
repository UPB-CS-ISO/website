#import "common.typ": *

#section-cover([Routing], [from one network to another], layers: ("network",), note: [routers])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.4 - _Routes and the Kernel Routing Table_
      - Section 9.5 - _The Default Gateway_
      - Section 9.7 - _Basic ICMP and DNS Tools_
  + #tanenbaum
    - Section 5.2 - _Routing Algorithms_
    - Section 5.6 - _The Network Layer in the Internet_
  + #uso-book
    - Chapter 11 - _Rețelistică și Internet_
]

// ---------------------------------------------------------------------------
// The same network: Ana sends to Bogdan
// ---------------------------------------------------------------------------

#slide[
  == Local Network
  Ana #arrow Bogdan: the same network, no router needed

  #let (a, b, s, r) = ((55pt, 42pt), (55pt, 132pt), (135pt, 87pt), (200pt, 87pt))
  // a speech bubble: who says it, to whom, and what
  #let bubble(x, y, head, body, color) = pin(x, y, box(
    fill: white,
    stroke: 1.2pt + color,
    radius: 6pt,
    inset: (x: 6pt, y: 4pt),
    text(size: 7.5pt)[#text(fill: color, weight: "bold", head) \ #body],
  ))
  // the MAC address Ana does not know yet
  #let missing = box(fill: bad-color.lighten(85%), stroke: 1.2pt + bad-color, radius: 2pt, inset: (x: 3pt, y: 1pt), text(size: 7pt, fill: bad-color, weight: "bold")[??? missing])

  #align(center, scale(92%, reflow: true, drawing(height: 180pt)[
    #area(5pt, 3pt, 225pt, 175pt, [network `192.168.1.0/24`])
    #for p in (a, b, r) { wire(p, s) }
    #host(..a, "Ana", addr: [#ana.at(0) \ #text(fill: luma(110), ana.at(1))], size: 24pt)
    #host(..b, "Bogdan", addr: [#bogdan.at(0) \ #text(fill: luma(110), bogdan.at(1))], size: 24pt)
    #netdev(..s, "switch", size: 16pt)
    #netdev(..r, "router", name: "Router", sub: [eth0 `192.168.1.1`], size: 26pt)

    // 3: Ana asks everyone
    #only(5)[
      #trail(a, s, b, split: true)
      #trail(s, r, split: true)
      #bubble(150pt, 26pt, [📢 Ana, to everyone:], [who has `192.168.1.11`?], hl)
    ]
    // 4: only Bogdan answers, only to Ana
    #only(6)[
      #trail(b, s, a, split: true, color: ok-color)
      #bubble(160pt, 140pt, [💬 Bogdan, only to Ana:], [that is me, `e4:3b:71:0c:9a:52`], ok-color)
      #tag(200pt, 58pt, [not me: ignored], stroke: 0.8pt + luma(150), size: 6.5pt)
    ]
    // 5: the frame, to Bogdan only
    #only("7-")[
      #trail(a, s, b, split: true)
      #ok-mark(b, dx: 30pt)
    ]

    // what Ana's computer does
    #let (px, pw) = (240pt, 240pt)
    #panel(px, 3pt, pw, 66pt, [① is 192.168.1.11 in my network?], net-check(
      (([Bogdan], bogdan.at(0), "192.168.1.0"), ([Ana (me)], ana.at(0), "192.168.1.0")),
      [✅ `192.168.1.0` = `192.168.1.0`: *the same network*, send it *directly*],
      caption: [mask `/24`: the first *3 numbers* are the *network*, the last one the computer],
      from: 1,
    ))
    #uncover("4-")[#panel(px, 74pt, pw, 48pt, [② Ana's ARP table: the MACs she already knows], {
      only("4-5", align(center, stack(spacing: 4pt,
        arp-table(([], text(fill: luma(140))[_empty_])),
        text(size: 7pt)[🔎 `192.168.1.11`: #text(fill: bad-color, weight: "bold")[not found]],
      )))
      only("6-", align(center, stack(spacing: 4pt,
        arp-table((bogdan.at(0), new-val(bogdan.at(1)))),
        text(size: 7pt)[🔎 `192.168.1.11`: #text(fill: ok-color, weight: "bold")[found]],
      )))
    })]
    #panel(px, 127pt, pw, 51pt, [③ the frame Ana sends], {
      only("1-6", frame-box(missing, ana.at(1), ip-inner(bogdan.at(0), ana.at(0))))
      only("7-", frame-box(new-val(bogdan.at(1)), ana.at(1), ip-inner(bogdan.at(0), ana.at(0))))
    })
  ]))

  #let good = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("🧮", [mask `/24`: the *network* is the first 3 numbers; for Bogdan `192.168.1.11` it is `192.168.1.0`]))
    #only(2, fact("🧮", [Ana does the same with *her own* address `192.168.1.10`: also `192.168.1.0`]))
    #only(3, fact("✅", [the *same network part*: Bogdan is in Ana's network, the frame goes *directly* to him], c: good))
    #only(4, fact("📒", [the *ARP table*: the MAC addresses Ana already found (IP #arrow MAC); Bogdan is not there]))
    #only(5, fact("📢", [*ARP*: Ana asks *everyone* in the network (_broadcast_) for the MAC of `192.168.1.11`]))
    #only(6, fact("💬", [only Bogdan answers; Ana *writes his MAC* in the ARP table, for the next packets too]))
    #only(7, fact("✅", [now the frame has Bogdan's MAC: the switch delivers it *only* to him], c: good))
  ]))
]

// the neighbor table of Ana (after the Local Network slide), with `ip neigh`
#let neigh-lines = (
  "$ ip neigh",
  (("ip", "192.168.1.1"), (none, " dev enp0s31f6 lladdr "), ("mac", "70:b5:e8:2d:91:4c"), (none, " "), ("ok", "REACHABLE")),
  ((none, "192.168.1.11 dev enp0s31f6 lladdr e4:3b:71:0c:9a:52 "), ("stale", "STALE")),
  ((none, "192.168.1.12 dev enp0s31f6 "), ("failed", "FAILED")),
)

#slide[
  == Neighbors
  #counter(footnote).update(0)the MAC addresses Ana's computer has found#footnote[`arp -n`: the older command (_net-tools_), the same table]

  #let steps = (
    (2, ("ip", "mac", "ok"), explain(
      [`ip neigh`: the *neighbor table* (the _ARP cache_): the answers to Ana's ARP questions],
      ([`192.168.1.1`], [the gateway (the router) has the MAC address `70:b5:e8:2d:91:4c`]),
      ([`REACHABLE`], [used just now, it answers]),
    )),
    (3, ("stale",), explain(
      [Bogdan, found some time ago],
      ([`STALE`], [an old entry: Ana asks again for the MAC address the next time she needs it]),
    )),
    (4, ("failed",), explain(
      [`192.168.1.12`: nobody answered, there is no such computer],
      ([`FAILED`], [`ping` shows `Destination Host Unreachable`]),
    )),
  )
  #for (i, (n, keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(neigh-lines, shown: n, hl: ((keys, ip-peach),), size: 0.95em)
      #body
    ]
  }
]

// ---------------------------------------------------------------------------
// The gateway: the door out of the network
// ---------------------------------------------------------------------------

#slide[
  == Gateway
  the door out of the network

  #let (a, b, s, r, s2, c, cl) = ((50pt, 40pt), (50pt, 125pt), (135pt, 82pt), (262pt, 82pt), (390pt, 82pt), (445pt, 135pt), (262pt, 18pt))
  #align(center, scale(92%, reflow: true, drawing(height: 178pt)[
    // the two networks, one next to the other, the router between them
    #area(5pt, 3pt, 205pt, 172pt, [Ana's network `192.168.1.0/24`])
    #area(315pt, 3pt, 160pt, 172pt, [`192.168.2.0/24`], name-at: top + right)
    // the edge of the cloud, toward the router
    #let cl-edge = (262pt, 37pt)
    #for (p, q) in ((a, s), (b, s), (s, r), (r, s2), (s2, c), (r, cl-edge)) { wire(p, q) }
    #host(..a, "Ana", addr: ana.at(0), size: 22pt)
    #host(..b, "Bogdan", addr: bogdan.at(0), size: 22pt)
    #host(..c, "Carla", addr: carla.at(0), size: 22pt)
    #netdev(..s, "switch", size: 14pt)
    #netdev(..s2, "switch", size: 14pt)
    #pin(..cl, pic("cloud", size: 40pt))
    #pin(300pt, 66pt, text(size: 8pt, weight: "bold")[Router])
    // the layers the router sees: up to the Network layer (IP addresses),
    // like the hub (Physical) and the switch (Data Link)
    #sees-stack(r.at(0), r.at(1) + 21pt, "network")
    #only(1)[#netdev(..r, "router", size: 26pt)]
    #only("2-")[#netdev(..r, "router", size: 26pt, highlight: true)]

    // 1: directly only inside the network
    #only(1)[
      #trail(a, s, b, split: true, color: ok-color, gap: 21pt)
      #tag(140pt, 128pt, [✅ Bogdan: *directly* \ (ARP finds his MAC)], stroke: 1pt + ok-color, size: 7pt)
      #draw-arrow((75pt, 36pt), (198pt, 36pt), color: bad-color, thickness: 1.5pt, head: 5pt, dash: "dashed")
      #pin(210pt, 36pt, icon("❌", size: 12pt))
      #tag(160pt, 56pt, [Carla is *outside*: \ ARP does not reach her], stroke: 1pt + bad-color, size: 7pt)
    ]
    // 2: through the gateway
    #only("2-")[
      // to the card of the router in Ana's network (eth0), and from its card
      // in the other network (eth1): the trails do not pass under the cards
      #trail(a, s, (210pt, r.at(1)), split: true, gap: 23pt)
      #trail((315pt, r.at(1)), s2, c, split: true, gap: 23pt)
      // the tip stops at the edge of the cloud (the gap before the second point)
      #trail(r, (cl-edge.at(0), cl-edge.at(1) - 11pt), split: true, gap: 16pt)
      #tag(225pt, 52pt, [🚪 *gateway*], fill: hl-bg, stroke: 1.2pt + hl, size: 8pt)
    ]

    // the two network cards of the router: a port on the border of each
    // network, with its address below, like the address of a computer
    // (drawn last, over the trails)
    #router-port(210pt, r.at(1), "eth0", eth0.at(0))
    #router-port(315pt, r.at(1), "eth1", eth1.at(0))
  ]))

  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("🏠", [Ana sends *directly* only inside her network: ARP asks only the computers there]))
    #only("2-", fact("🚪", [the *gateway*: a router with a card in Ana's network (`192.168.1.1`); every other network is *through it*]))
  ]))
]

// ---------------------------------------------------------------------------
// The decision for every packet: directly, or through the gateway
// ---------------------------------------------------------------------------

#slide[
  == Which Way?
  directly or through the gateway: the decision for every packet

  // step 1 and 4: the rule; step 2: Bogdan; step 3: Carla
  #let ex = (none, "bogdan", "carla", none)
  // where things are
  #let (pk, dm, yes, no) = ((62pt, 86pt), (205pt, 86pt), (392pt, 34pt), (392pt, 138pt))
  #let (dw, dh) = (128pt, 74pt) // the diamond
  #let (cw, ch) = (168pt, 56pt) // the answers
  #let n = layer-colors.network

  // a rounded card centered on (x, y)
  #let card(p, w, h, c, body, faded: false) = pin(..p, box(
    width: w,
    height: h,
    radius: 6pt,
    fill: if faded { luma(250) } else { c.lighten(92%) },
    stroke: if faded { 0.8pt + luma(215) } else { 1.4pt + c },
    inset: (x: 7pt, y: 5pt),
    align(left + horizon, text(size: 8pt, fill: if faded { luma(170) } else { black }, body)),
  ))
  // a path: lines through the points, an arrow head at the end
  #let path(..pts, on: false) = {
    let ps = pts.pos()
    let st = if on { 2.2pt + hl } else { 1.2pt + luma(140) }
    for i in range(ps.len() - 2) { wire(ps.at(i), ps.at(i + 1), stroke: st) }
    draw-arrow(ps.at(-2), ps.at(-1), color: if on { hl } else { luma(140) }, thickness: if on { 2.2pt } else { 1.2pt }, head: 6pt)
  }

  #align(center, scale(94%, reflow: true, drawing(height: 176pt)[
    // the packet
    #for (i, e) in ex.enumerate() {
      only(i + 1, card(pk, 104pt, 50pt, accent, align(center)[
        📦 a packet for \
        #if e == none [the IP address *X*] else if e == "bogdan" [*Bogdan* \ #mono(bogdan.at(0), size: 7.5pt)] else [*Carla* \ #mono(carla.at(0), size: 7.5pt)]
      ]))
    }
    #path((pk.at(0) + 52pt, pk.at(1)), (dm.at(0) - dw / 2 - 2pt, dm.at(1)))

    // the question: a diamond
    #place(top + left, polygon(
      fill: hl-bg,
      stroke: 1.4pt + hl,
      (dm.at(0), dm.at(1) - dh / 2),
      (dm.at(0) + dw / 2, dm.at(1)),
      (dm.at(0), dm.at(1) + dh / 2),
      (dm.at(0) - dw / 2, dm.at(1)),
    ))
    #for (i, e) in ex.enumerate() {
      only(i + 1, pin(..dm, align(center, text(size: 8.5pt)[🧮 is *#if e == none [X] else if e == "bogdan" [Bogdan] else [Carla]* \ in my network?])))
    }
    // the check of the example, under the diamond
    #only(2)[#pin(pk.at(0), pk.at(1) + 42pt, text(size: 7.5pt)[his network #mono(text(weight: "bold", "192.168.1"), size: 7.5pt) #text(size: 9pt)[=] mine ✅])]
    #only(3)[#pin(pk.at(0), pk.at(1) + 42pt, text(size: 7.5pt)[her network #mono(text(weight: "bold", "192.168.2"), size: 7.5pt) #text(size: 9pt)[≠] mine #mono(text(weight: "bold", "192.168.1"), size: 7.5pt)])]

    // the two answers, with elbow arrows from the corners of the diamond
    #path((dm.at(0), dm.at(1) - dh / 2), (dm.at(0), yes.at(1)), (yes.at(0) - cw / 2 - 2pt, yes.at(1)))
    #path((dm.at(0), dm.at(1) + dh / 2), (dm.at(0), no.at(1)), (no.at(0) - cw / 2 - 2pt, no.at(1)))
    #only(2)[#path((dm.at(0), dm.at(1) - dh / 2), (dm.at(0), yes.at(1)), (yes.at(0) - cw / 2 - 2pt, yes.at(1)), on: true)]
    #only(3)[#path((dm.at(0), dm.at(1) + dh / 2), (dm.at(0), no.at(1)), (no.at(0) - cw / 2 - 2pt, no.at(1)), on: true)]
    #label(dm.at(0) + 14pt, yes.at(1) + 9pt, text(size: 8.5pt, weight: "bold", fill: ok-color)[yes])
    #label(dm.at(0) + 12pt, no.at(1) - 9pt, text(size: 8.5pt, weight: "bold", fill: hl)[no])

    #for (i, e) in ex.enumerate() {
      only(i + 1)[
        #card(yes, cw, ch, ok-color, faded: e == "carla")[
          ✅ *directly* to X \
          #text(size: 7.5pt)[ARP for *X*, the frame goes to *its MAC*] \
          #if e == "bogdan" { new-val(text(size: 7pt)[MAC to #mono(bogdan.at(1)) (Bogdan)]) }
        ]
        #card(no, cw, ch, hl, faded: e == "bogdan")[
          🚪 *through the gateway* \
          #text(size: 7.5pt)[ARP for `192.168.1.1`, the frame goes to the *router's MAC*] \
          #if e == "carla" { new-val(text(size: 7pt)[MAC to #mono(eth0.at(1)) (router)]) }
        ]
      ]
    }
  ]))

  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("🤔", [before *every* packet, the computer asks one question: is the destination in *my network*?]))
    #only(2, fact("✅", [Bogdan is in Ana's network: the frame goes *directly* to his MAC], c: (fill: ok-color.lighten(90%), stroke: ok-color)))
    #only(3, fact("🚪", [Carla is not: the frame goes to the *router's MAC*, the packet inside still says *IP to Carla*], c: (fill: hl-bg, stroke: hl)))
    #only("4-", grid(
      columns: (1fr, 1fr),
      column-gutter: 8pt,
      fact("🎯", [the *IP address*: the *final destination*, it stays the same the whole way], c: layer-colors.network),
      fact("👣", [the *MAC address*: only the *next stop* in this network, it changes at every router], c: layer-colors.link),
    ))
  ]))
]

// ---------------------------------------------------------------------------
// Router: Ana sends to Carla, through a router with three networks
// ---------------------------------------------------------------------------

#slide[
  == Routing
  Ana #arrow Carla: one router, three networks

  #let (a, r, c, d) = ((50pt, 50pt), (232pt, 52pt), (362pt, 25pt), (362pt, 79pt))
  #let eth2 = ("192.168.3.1", "70:b5:e8:2d:91:54")
  // a value with the name of its owner, in gray
  #let who(v, name) = [#mono(v, size: 6.5pt) #text(size: 6.5pt, fill: luma(110), name)]
  // the frame on one wire: the MAC addresses (link layer) and the IP addresses
  // (network layer), each with a destination and a source
  // a dotted arrow: from the sender to the receiver
  #let dots(w: 26pt, c: luma(80)) = box(width: w, height: 6pt, baseline: 0pt, {
    place(top + left, dy: 3pt, line(length: w - 6pt, stroke: (paint: c, thickness: 1.2pt, dash: "dotted")))
    place(top + left, dx: w - 6pt, polygon(fill: c, (0pt, 0pt), (6pt, 3pt), (0pt, 6pt)))
  })
  // the frame on one wire, read from left to right: who sends ⋯> who receives,
  // for the MAC addresses (link layer) and the IP addresses (network layer)
  #let frame-grid(title, mto, mfrom, ttl) = {
    let (l, n) = (layer-colors.link, layer-colors.network)
    stack(spacing: 4pt, text(size: 8pt)[✉️ *the frame on* #title #h(1fr) TTL #new-val(mono(ttl, size: 7.5pt))], grid(
      columns: (30pt, 1fr, 34pt, 1fr),
      align: (left + horizon, right + horizon, center + horizon, left + horizon),
      inset: (x: 4pt, y: 5pt),
      fill: (x, y) => if y == 0 { l.fill } else { n.fill },
      stroke: (x, y) => if y == 0 { (bottom: 2pt + white) } else { none },
      text(size: 7.5pt)[*MAC*], mfrom, dots(), mto,
      text(size: 7.5pt)[*IP*], who(ana.at(0), [Ana]), dots(), who(carla.at(0), [Carla]),
    ))
  }

  #align(center, scale(92%, reflow: true, drawing(height: 184pt)[
    // the three networks around the router
    #area(3pt, 3pt, 195pt, 102pt, [Ana's network `192.168.1.0/24`])
    #area(280pt, 3pt, 197pt, 49pt, [Carla's network `192.168.2.0/24`], name-at: top + right)
    #area(280pt, 56pt, 197pt, 49pt, [Dan's network `192.168.3.0/24`], name-at: top + right)
    #for p in (a, c, d) { wire(p, r) }
    #host(..a, "Ana", addr: ana.at(0), size: 20pt, label-size: 7pt)
    #host(..c, "Carla", addr: carla.at(0), size: 18pt, label-size: 7pt)
    #host(..d, "Dan", addr: "192.168.3.30", size: 18pt, label-size: 7pt)
    #netdev(..r, "router", size: 26pt, highlight: true)
    #label(r.at(0), r.at(1) + 24pt, text(size: 8pt, weight: "bold")[Router])

    // where the wires cross the borders of the networks: the cards of the router
    #let wire-y(p, x) = r.at(1) + (p.at(1) - r.at(1)) * ((x - r.at(0)) / (p.at(0) - r.at(0)))
    #let (p0, p1, p2) = ((198pt, wire-y(a, 198pt)), (280pt, wire-y(c, 280pt)), (280pt, wire-y(d, 280pt)))
    // the frames travel (orange on their own step, gray after): to eth0, and
    // from eth1, so they do not pass under the cards
    #only(1, trail(a, p0, split: true, gap: 18pt))
    #only("2-", trail(a, p0, split: true, gap: 18pt, color: luma(185)))
    #only(3, trail(p1, c, split: true, gap: 18pt))
    #only("4-", trail(p1, c, split: true, gap: 18pt, color: luma(185)))
    #only("3-")[#ok-mark(c, dx: 26pt)]

    // the three cards of the router, as on the Gateway slide: a port where
    // its wire crosses the border of its network (the y of the wire there);
    // eth1, the card that leads to Carla, in orange from step 2
    #router-port(..p0, "eth0", eth0.at(0), ip-dx: -8pt)
    #only(1, router-port(..p1, "eth1", eth1.at(0), ip-at: top))
    #only("2-", router-port(..p1, "eth1", eth1.at(0), ip-at: top, on: true))
    #router-port(..p2, "eth2", eth2.at(0))

    // below, centered: the frame, or the networks of the router
    #let (y0, fx, fw) = (116pt, 95pt, 290pt)
    #only(1)[#at(fx, y0, box(width: fw, frame-grid([Ana's network], new-val(who(eth0.at(1), [router])), who(ana.at(1), [Ana]), "64")))]
    #only(2)[
      // the networks of the router: only the one on eth1 matches
      #at(fx + 20pt, y0, box(width: fw - 40pt, {
        set text(size: 8pt)
        table(
          columns: (auto, 1fr, auto),
          inset: (x: 7pt, y: 4pt),
          align: left + horizon,
          stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(215)) },
          fill: (x, y) => if y == 2 { ok-color.lighten(88%) } else { none },
          table.header([*card*], [*its network*], [*has* `192.168.2.20`*?*]),
          mono[eth0], mono[192.168.1.0/24], [❌],
          mono[*eth1*], mono[*192.168.2.0/24*], [✅ send it out here],
          mono[eth2], mono[192.168.3.0/24], [❌],
        )
      }))
    ]
    #only(3)[#at(fx, y0, box(width: fw, frame-grid([Carla's network], new-val(who(carla.at(1), [Carla])), new-val(who(eth1.at(1), [router])), "63")))]
    // the summary: the two frames, one under the other
    #only("4-")[
      #at(2pt, 116pt, box(width: 476pt, {
        let (l, n) = (layer-colors.link, layer-colors.network)
        let head(c, t) = table.cell(fill: c, text(size: 7.5pt, weight: "bold", t))
        set text(size: 8pt)
        table(
          columns: (auto, 1fr, 1fr, 1fr, 1fr, auto),
          inset: (x: 5pt, y: 4pt),
          align: left + horizon,
          stroke: 0.5pt + luma(190),
          head(white, [frame on]), head(l.fill, [MAC to]), head(l.fill, [MAC from]), head(n.fill, [IP to]), head(n.fill, [IP from]), head(white, [TTL]),
          // the IP addresses are the same in both frames: one cell each
          mono(size: 7pt)[192.168.1.0/24], [router], [Ana],
          table.cell(rowspan: 2, align: center + horizon, fill: n.fill.lighten(50%))[*Carla* #text(size: 6.5pt, fill: luma(90))[(the same)]],
          table.cell(rowspan: 2, align: center + horizon, fill: n.fill.lighten(50%))[*Ana* #text(size: 6.5pt, fill: luma(90))[(the same)]],
          [64],
          mono(size: 7pt)[192.168.2.0/24], new-val[Carla], new-val[router], new-val[63],
        )
      }))
    ]
  ]))

  #let good = (fill: ok-color.lighten(90%), stroke: ok-color)
  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("1️⃣", [Carla is *not* in Ana's network: Ana sends the frame to her *gateway*, the router]))
    #only(2, fact("2️⃣", [the router reads *IP to* `192.168.2.20` (TTL one less): which of its networks has it?]))
    #only(3, fact("3️⃣", [the router puts the *same packet* in a *new frame*, to Carla's MAC (found with ARP)], c: good))
    #only("4-", fact("💡", [a router: a *new frame* for every network (new MACs), the *same packet* (the same IPs), *TTL* one less], c: layer-colors.network))
  ]))
]

// ---------------------------------------------------------------------------
// The routing table
// ---------------------------------------------------------------------------

// the routing table of Ana, with `ip route`
#let route-lines = (
  "$ ip route",
  (("def", "default"), (none, " "), ("via", "via 192.168.1.1"), (none, " dev enp0s31f6 proto dhcp src 192.168.1.10 metric 100")),
  (("net", "192.168.1.0/24"), (none, " dev enp0s31f6 "), ("kernel", "proto kernel"), (none, " scope link src 192.168.1.10 metric 100")),
)

#slide[
  == Routing Table
  where does each packet go? on Ana's computer

  #parts-terminal(route-lines, hl: ((("def", "via"), ip-peach),), size: 0.85em)
  #explain(
    [`ip route`: the *routing table*; the `default` line is the *gateway*],
    ([`default`], [every network that is *not* Ana's (`0.0.0.0/0`)]),
    ([`via 192.168.1.1`], [🚪 through the *gateway*, the router: the door out of the network]),
  )
]

// three ways for `ping` to fail, on the laptop `192.168.1.105`, and what each one means
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
      "",
      "--- 192.168.1.20 ping statistics ---",
      "1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms",
    ),
    explain(
      [a computer in *my network*, but nobody answered the ARP question (no MAC address)],
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

// the three errors side by side, for the last step
#let ping-fails-table = block(width: 100%, {
  set text(size: 10pt)
  set table(inset: (x: 6pt, y: 6pt))
  table(
    columns: (auto, 1fr, auto),
    align: left + horizon,
    stroke: (x, y) => if y == 0 { (bottom: 1pt + luma(150)) } else { (bottom: 0.5pt + luma(215)) },
    table.header(..([*the error*], [*what it means*], [*check*]).map(t => text(fill: luma(90), t))),
    text(fill: bad-color)[`Network is unreachable`], [no route: usually no default gateway], [`ip route`],
    text(fill: bad-color)[`Destination Host Unreachable`], [in my network, but no answer to ARP], [is it on? the right IP?],
    text(fill: bad-color)[`100% packet loss`], [no answer: down, or a firewall drops `ping`], [another computer, `traceroute`],
  )
})

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
  #only(ping-fails.len() + 1)[
    #v(1em)
    #ping-fails-table
  ]
]

#slide[
  == The Internet
  a network of routers

  #drawing(height: 190pt)[
    #let routers = (
      (110pt, 50pt), (110pt, 140pt), (220pt, 30pt), (240pt, 120pt), (340pt, 60pt), (360pt, 150pt),
    )
    #let links = ((0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (1, 5))
    #let path = ((0, 3), (3, 4))
    #for (i, j) in links { wire(routers.at(i), routers.at(j)) }
    #wire((30pt, 50pt), routers.at(0))
    #wire(routers.at(4), (450pt, 60pt))
    #uncover("2-")[
      #wire((30pt, 50pt), routers.at(0), stroke: 2.5pt + hl)
      #for (i, j) in path { wire(routers.at(i), routers.at(j), stroke: 2.5pt + hl) }
      #wire(routers.at(4), (450pt, 60pt), stroke: 2.5pt + hl)
    ]
    #for (i, p) in routers.enumerate() { netdev(..p, "router", size: 20pt) }
    #host(30pt, 50pt, "home", size: 24pt)
    #host(450pt, 60pt, "upb.ro", kind: "server", size: 24pt)
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1)[- networks of companies, universities and Internet Service Providers (ISP) connected by routers]
    #only("2-")[- each router only knows the *next hop*; if a link fails, packets take another path]
  ]))
]

// ---------------------------------------------------------------------------
// traceroute
// ---------------------------------------------------------------------------

#let trace = (
  "$ traceroute -n 141.85.228.17",
  ((none, "traceroute to 141.85.228.17 (141.85.228.17), "), ("max", "30 hops max"), (none, ", 60 byte packets")),
  ((none, " "), ("hop", "1"), (none, "  "), ("router", "192.168.1.1"), (none, "    "), ("time", "1.912 ms  1.874 ms  1.851 ms")),
  ((none, " "), ("hop", "2"), (none, "  "), ("router", "10.20.0.1"), (none, "      "), ("time", "3.420 ms  3.402 ms  3.389 ms")),
  ((none, " "), ("hop", "3"), (none, "  "), ("star", "* * *")),
  ((none, " "), ("hop", "4"), (none, "  "), ("router", "37.128.225.9"), (none, "   "), ("time", "4.103 ms  4.087 ms  4.152 ms")),
  ((none, " "), ("hop", "5"), (none, "  "), ("dest", "141.85.228.17"), (none, "  "), ("time", "4.210 ms  4.198 ms  4.176 ms")),
)

#slide[
  == `traceroute`
  which routers are on the way?

  #term-steps(trace, (
    (2, ("max",), explain(
      [`traceroute`: the *routers* between this computer and the destination],
      ([`-n`], [show the routers by their IP addresses only (faster)]),
      ([`30 hops max`], [it gives up after 30 routers]),
    )),
    (4, ("hop", "router", "time"), explain(
      [one line for every router (*hop*), in order],
      ([`1`], [the first router is the *gateway*, `192.168.1.1`]),
      ([`ms`], [three tries, three round trip times]),
    )),
    (5, ("star",), explain(
      [`* * *`: this router did *not* answer],
      ([💡], [many routers do not answer, but they still *forward* the packets]),
    )),
    (7, ("dest",), explain(
      [the last line is the *destination*: it was reached],
      ([install], [`sudo dnf install traceroute` (Fedora), `sudo apt install traceroute` (Ubuntu)]),
      ([`tracepath`], [usually installed already, it does almost the same]),
    )),
  ), summary: (("hop", "router", "star", "dest"), explain(
    [💡 `traceroute`: the routers on the way, in order, one per line],
    ([`1`], [the gateway `192.168.1.1`, then the routers of the provider]),
    ([`* * *`], [a router that does not answer, but still forwards]),
    ([`141.85.228.17`], [the destination, after 4 routers]),
  )), size: 0.85em)
]

// NAT: the private addresses of a home behind the one public address of the router
#slide[
  == NAT
  many private addresses behind one public address

  // a changed address: orange, with a word, not only a color
  #let changed(a) = text(fill: hl)[#raw(a) *(changed)*]
  #drawing(height: 150pt)[
    // the LAN: the devices on a switch, the router outside it, with one card
    // in the LAN (private address) and one toward the Internet (public)
    #let (sw, r) = ((140pt, 75pt), (285pt, 75pt))
    #area(5pt, 5pt, 225pt, 140pt, [LAN (private)])
    #wire((50pt, 42pt), sw)
    #wire((50pt, 108pt), sw)
    #wire(sw, r)
    // (it stops at the left edge of the cloud)
    #wire(r, (387pt, 75pt))
    #host(50pt, 42pt, "laptop", addr: "192.168.1.105", size: 24pt)
    #host(50pt, 108pt, "phone", kind: "phone", addr: "192.168.1.107", size: 22pt)
    #netdev(..sw, "switch", size: 14pt)
    #netdev(..r, "router", size: 28pt, highlight: true)
    #pin(r.at(0), r.at(1) + 26pt, text(size: 8pt, weight: "bold")[Router])
    // its two cards, as on the Gateway slide: eth0 on the border of the LAN,
    // eth1 on the wire to the Internet
    #router-port(230pt, r.at(1), "eth0", "192.168.1.1", note: [private])
    #router-port(340pt, r.at(1), "eth1", "203.0.113.42", note: [public])
    #pin(420pt, 75pt, pic("cloud", size: 50pt))
    #only(2)[#frame(145pt, 34pt)[from `192.168.1.105` \ to `141.85.228.17`]]
    // the packet before the router changed it: the same frame with a dotted
    // border, next to the new one
    #let before(x, y, body, color: hl) = tag(x, y, body, fill: hl-bg, stroke: (paint: color, thickness: 1pt, dash: "dotted"), size: 7pt)
    #only(3)[
      #before(145pt, 34pt)[from `192.168.1.105` \ to `141.85.228.17`]
      #frame(330pt, 45pt)[from #changed("203.0.113.42") \ to `141.85.228.17`]
    ]
    #only(4)[#frame(330pt, 125pt, color: ok-color)[from `141.85.228.17` \ to `203.0.113.42`]]
    #only(5)[
      #before(330pt, 125pt, color: ok-color)[from `141.85.228.17` \ to `203.0.113.42`]
      #frame(150pt, 40pt, color: ok-color)[from `141.85.228.17` \ to #changed("192.168.1.105")]
    ]
    #only(6)[
      #frame(128pt, 130pt)[from `192.168.1.107` \ to `141.85.228.17`]
      #frame(330pt, 45pt)[from #changed("203.0.113.42") \ to `141.85.228.17`]
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only("1-2", fact("📤", [the laptop sends a packet to `141.85.228.17`, from its *private* address `192.168.1.105`]))
    #only(3, fact("🔁", [the router *replaces* the source with its *public* address `203.0.113.42` and remembers the connection]))
    #only(4, fact("↩️", [the answer comes back to the *public* address `203.0.113.42`]))
    #only(5, fact("🔁", [the router puts back `192.168.1.105`: *private addresses are not visible on the Internet*]))
    #only(6, fact("🔢", [the phone goes out with *the same* public address: the router tells the answers apart by the *port* of each connection (see the Transport Layer)]))
  ]))
]

#slide[
  == Hub, Switch, AP, Router
  the layer each device works on

  #text(size: 10pt)[
  #align(center, table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    inset: 5pt,
    stroke: 0.6pt + luma(170),
    align: left + horizon,
    table.header([], align(center, pic("hub", size: 14pt)) + [*Hub*], align(center, pic("switch", size: 14pt))
      + [*Switch*], align(center, pic("wifi-router", size: 20pt)) + [*Access Point*], align(center, pic(
      "router",
      size: 20pt,
    ))
      + [*Router*]),
    [*Layer*],
    table.cell(fill: layer-colors.physical.fill)[1: bits],
    table.cell(fill: layer-colors.link.fill)[2: frames],
    table.cell(fill: layer-colors.link.fill)[2: frames],
    table.cell(fill: layer-colors.network.fill)[3: packets],

    [*Uses*], [nothing], [MAC addresses], [MAC addresses], [IP addresses],
    [*Sends to*], [all ports], [the destination port], [the destination device (radio)], [the next network],
    [*Medium*], [shared cable], [one cable per port], [shared radio], [one card per network],
    [*Connects*], [devices], [devices of one network], [wireless devices to a wired network], [*different networks*],
  ))
  ]
  #v(0pt)
]
