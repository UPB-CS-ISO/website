#import "common.typ": *

#slide[
  = The Internet #text(size: 10pt, weight: "regular")[\ _a network of networks_]
]

#slide[
  == Bibliography
  for this section

  + #tanenbaum
    - Chapter 1 - _Introduction_
      - Section 1.5.1 - _The Internet_
  + #uso-book
    - Chapter 11 - _Rețelistică și Internet_
      - Section 11.1 - _Servicii de Internet_
      - Section 11.2 - _Funcționarea Internetului_
]

// a flag emoji: regional indicator pairs are not caught by the template's
// emoji show rule, so they get their size here
#let flag(f) = text(size: 9pt, f)

// one event of the timeline: a dot on the line, the country where it was
// designed (highlighted) on the stem and a label above or below it
#let event(x, year, country, body, up: true, step: 1) = uncover(str(step) + "-")[
  #place(top + left, dx: x - 4pt, dy: 96pt, circle(radius: 4pt, fill: accent, stroke: none))
  #wire((x, if up { 50pt } else { 108pt }), (x, if up { 96pt } else { 150pt }), stroke: 0.6pt + accent)
  #tag(x, if up { 70pt } else { 130pt }, text(weight: "bold", fill: hl, country), stroke: 1pt + hl, size: 7.5pt)
  #pin(x, if up { 28pt } else { 174pt }, box(width: 100pt, align(center, text(size: 8pt)[
    #text(size: 9pt, weight: "bold", fill: accent, year) \
    #body
  ])))
]

#let usa = [#flag("🇺🇸") USA]

#slide[
  == #text(weight: "bold")[Internet]#text(weight: "regular")[working]
  a brief history

  #drawing(height: 195pt)[
    #draw-arrow((0pt, 100pt), (480pt, 100pt), color: luma(120), thickness: 1.5pt)
    #event(30pt, "1969", usa)[*ARPANET*: 4 computers, US universities]
    #event(95pt, "1971", usa, up: false, step: 2)[*e-mail*, the `@` sign \ #box(text(size: 7pt)[(Ray Tomlinson)])]
    #event(160pt, "1974", usa, step: 3)[*TCP/IP* is designed \ #box(text(size: 7pt)[(Vint Cerf, Bob Kahn)])]
    #event(225pt, "1983", usa, up: false, step: 4)[ARPANET switches to *TCP/IP*, *DNS* is invented]
    #event(290pt, "1991", [#flag("🇪🇺") Europe], step: 5)[the *World Wide Web* \ #box(text(size: 7pt)[(Tim Berners-Lee, CERN)])]
    #event(355pt, "1995", usa, up: false, step: 6)[the *commercial Internet*, NSFNET is retired]
    #event(420pt, "2011", [#text(size: 9pt / 0.68, "🌍") worldwide], step: 7)[the *IPv4 addresses* run out \ #box(text(size: 7pt)[(IANA)])]
  ]
]

// a node of ARPANET: name and city
#let arpa-node(p, name, city, below: true) = host(
  ..p,
  [#name \ #text(weight: "regular", size: 6.5pt, fill: luma(90), city)],
  kind: "old-pc",
  size: 24pt,
  below: below,
)

#slide[
  == ARPANET, 1969

  #toolbox.side-by-side(columns: (5fr, 4fr), gutter: 1em)[
    #set text(size: 11pt)
    - funded by the US Department of Defense
    - 4 university computers
    - *no central computer*: works even if a link fails
    #uncover("2-")[
      #v(0.5em)
      #note-box[
        #text(weight: "bold", fill: hl)[📜 Fun fact] #h(1fr) #text(size: 9pt, fill: luma(90))[29 October 1969]
        #v(-0.2em)
        UCLA logs in to SRI, types `LOGIN`
        #v(-0.2em)
        #align(center, text(size: 13pt)[
          `L` #uncover("2-")[✅] #h(0.6em) `O` #uncover("3-")[✅] #h(0.6em) #text(fill: bad-color)[`G`] #uncover("4-")[💥]
        ])
        #v(-0.2em)
        #uncover("4-")[
          #text(fill: bad-color, weight: "bold")[the SRI computer crashed!] \
          the first message ever sent: *`LO`* 😄
        ]
      ]
    ]
  ][
    #drawing(width: 230pt, height: 200pt)[
      #let sri = (45pt, 72pt)
      #let ucsb = (75pt, 150pt)
      #let ucla = (165pt, 160pt)
      #let utah = (195pt, 50pt)
      #label(140pt, 12pt, text(size: 7.5pt, fill: luma(90))[#text(size: 9pt, "🇺🇸") western USA, December 1969])
      #let link-stroke = 1.6pt + accent
      #wire(ucla, sri, stroke: link-stroke)
      #wire(ucla, ucsb, stroke: link-stroke)
      #wire(sri, ucsb, stroke: link-stroke)
      #wire(sri, utah, stroke: link-stroke)
      // the first message, UCLA to SRI
      #let on-link(t) = (ucla.at(0) + (sri.at(0) - ucla.at(0)) * t, ucla.at(1) + (sri.at(1) - ucla.at(1)) * t)
      #only(2)[#frame(..on-link(0.4))[`L`]]
      #only(3)[
        #frame(..on-link(0.75))[`L`]
        #frame(..on-link(0.4))[`O`]
      ]
      #only("4-")[
        #frame(..on-link(0.75))[`O`]
        #frame(..on-link(0.4), color: bad-color)[`G`]
      ]
      #arpa-node(sri, "SRI", "Menlo Park, CA", below: false)
      #arpa-node(ucsb, "UCSB", "Santa Barbara, CA")
      #arpa-node(ucla, "UCLA", "Los Angeles, CA")
      #arpa-node(utah, "Utah", "Salt Lake City, UT")
      #only("4-")[
        #pin(sri.at(0) + 20pt, sri.at(1) + 4pt, icon("💥", size: 22pt))
        #tag(sri.at(0), sri.at(1) + 30pt, text(weight: "bold", fill: bad-color)[crashed], stroke: 1pt + bad-color)
      ]
    ]
  ]
]

// the highway drawing: a road is a thick gray curve with a dashed middle line
#let road-stroke = (paint: luma(120), thickness: 18pt, cap: "round", join: "round")
#let marks-stroke = (paint: white, thickness: 1.2pt, dash: (5pt, 5pt), cap: "butt")
#let road(..parts) = {
  place(top + left, curve(stroke: road-stroke, ..parts))
  place(top + left, curve(stroke: marks-stroke, ..parts))
}
// a delivery van carrying a parcel; `right: true` drives it to the right
#let van(x, y, right: false) = pin(x, y, if right { scale(x: -100%, icon("🚚", size: 15pt)) } else {
  icon("🚚", size: 15pt)
})
// what the van carries
#let parcel(x, y, body, color: hl) = tag(x, y, text(weight: "bold", fill: color, body), stroke: 1pt + color, size: 8pt)
// a business at the end of a road: an emoji with its name and its server
#let business(x, y, e, name, server) = {
  pin(x, y, icon(e, size: 24pt))
  place(top + left, dx: x + 17pt, dy: y - 11pt, text(size: 9pt)[*#name* \ #text(fill: accent, server)])
}

#slide[
  == The Internet is a Highway

  #drawing(height: 150pt)[
    #let main-y = 75pt
    #let rows = (18pt, 75pt, 132pt)
    #let homes = (25pt, 75pt, 125pt)
    #let merge = 125pt
    #let fork = 225pt
    #let bend = 320pt
    #let end = 376pt
    // roads: the devices join the main road, which then splits in three branches
    #for y in homes {
      road(
        curve.move((52pt, y)),
        curve.cubic((95pt, y), (85pt, main-y), (merge, main-y)),
      )
    }
    #for y in rows {
      road(
        curve.move((fork, main-y)),
        curve.cubic((fork + 50pt, main-y), (bend - 50pt, y), (bend, y)),
        curve.line((end, y)),
      )
    }
    #road(curve.move((merge, main-y)), curve.line((fork, main-y)))
    #for (y, (name, kind)) in homes.zip((("PC", "pc"), ("laptop", "pc"), ("phone", "phone"))) {
      host(28pt, y, name, kind: kind, size: 22pt)
    }
    #for x in (merge, fork) { pin(x, main-y - 18pt, icon("🚦", size: 14pt)) }

    // the services: where the parcels go
    #uncover("2-")[
      #business(398pt, rows.at(0), "🏬", "shop", "web server")
      #business(398pt, rows.at(1), "📮", "post office", "mail server")
      #business(398pt, rows.at(2), "📇", "directory", "DNS server")
    ]

    // the delivery vans: data packets
    #uncover("3-")[
      #van(150pt, main-y, right: true)
      #van(195pt, main-y)
      #parcel(195pt, main-y + 22pt, color: ok-color)[📦 web page]
      #for (y, what) in rows.zip(([🛒 an order], [✉️ a letter], [📖 upb.ro?])) {
        van(358pt, y, right: true)
        parcel(318pt, y, what)
      }
    ]
  ]

  #let legend(e, title, body, kind) = text(size: 10.5pt)[
    #e *#title* \ #body \ #text(fill: hl, weight: "bold", kind)
  ]
  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 1em,
    legend("🛣️", [roads and 🚦 junctions], [the *Internet*: cables, routers], "Infrastructure"),
    uncover("2-", legend("🏬", [places you send things to], [the *services*: Web, e-mail, DNS], "Users")),
    uncover("3-", legend("🚚", [vans with parcels], [the *data packets*], "Transport")),
  )
]

// one row of the services table: emoji, service, protocol, client, server
#let service-row(e, name, proto, client, server) = (
  icon(e, size: 13pt),
  [*#name*],
  text(fill: accent, weight: "bold", proto),
  client,
  server,
)

#slide[
  == Services and Programs
  a *server* waits for requests, a *client* sends them

  #align(center, text(size: 10.5pt, table(
    columns: (auto, auto, auto, auto, auto),
    inset: (x: 7pt, y: 5pt),
    align: left + horizon,
    stroke: (x, y) => if y == 0 { none } else { (bottom: 0.5pt + luma(210)) },
    fill: (x, y) => if y == 0 { accent } else if calc.even(y) { luma(246) } else { white },
    table.header(
      table.cell(colspan: 2, text(fill: white, weight: "bold")[Service]),
      ..([Protocol], [#text(size: 1.4em, "💻") Client], [#text(size: 1.4em, "🗄️") Server]).map(h => text(
        fill: white,
        weight: "bold",
        h,
      )),
    ),
    ..service-row("🌐", [Web], [HTTP(S)], [Firefox, `curl`], [nginx, Apache]),
    ..service-row("✉️", [e-mail], [SMTP, IMAP], [Thunderbird], [Postfix, Dovecot]),
    ..service-row("⌨️", [remote shell], [SSH], [`ssh`], [`sshd`]),
    ..service-row("📖", [names], [DNS], [`host`, `dig`], [BIND, Unbound]),
    ..service-row("📁", [file transfer], [SFTP], [`sftp`, FileZilla], [`sshd`]),
    ..service-row("🕒", [time], [NTP], [chrony], [chrony, ntpd]),
  )))
  #v(0pt)
]

#let osi-w = 92pt
#let bracket(x, y1, y2, title, sub) = {
  wire((x, y1 + 2pt), (x, y2 - 2pt), stroke: 1.2pt + hl)
  wire((x - 5pt, y1 + 2pt), (x, y1 + 2pt), stroke: 1.2pt + hl)
  wire((x - 5pt, y2 - 2pt), (x, y2 - 2pt), stroke: 1.2pt + hl)
  place(top + left, dx: x + 6pt, dy: (y1 + y2) / 2 - 11pt, box(width: 105pt, text(size: 8pt)[
    #text(weight: "bold", fill: hl, title) \
    #sub
  ]))
}

#slide[
  == From OSI to TCP/IP

  #drawing(height: 168pt)[
    #let (x1, x2, x3) = (0pt, 130pt, 260pt)
    // OSI
    #stack-title(x1, w: osi-w)[OSI model (ISO, 1984)]
    #layer-stack(x1, w: osi-w, (
      ("7. Application", "application", none),
      ("6. Presentation", "application", none),
      ("5. Session", "application", none),
      ("4. Transport", "transport", none),
      ("3. Network", "network", none),
      ("2. Data Link", "link", none),
      ("1. Physical", "physical", none),
    ))

    // step 1: what each OSI layer does
    #only(1)[
      #for (i, body) in (
        [what the program needs: web pages, e-mail, files],
        [the format of the data: encoding, compression, encryption],
        [keeps a conversation open: start, pause, resume],
        [delivers data between *programs*, in order, nothing lost (ports)],
        [finds the way *between networks* (IP addresses, routers)],
        [sends frames to a device *in the same network* (MAC addresses)],
        [sends *bits* as signals: electricity, light, radio],
      ).enumerate() {
        let y = stack-y(7, i) + stack-h / 14
        wire((x1 + osi-w + 4pt, y), (x1 + osi-w + 14pt, y), stroke: 0.6pt + luma(150))
        place(top + left, dx: x1 + osi-w + 18pt, dy: y - 3.5pt, text(size: 8pt, body))
      }
    ]

    // TCP/IP as it was defined
    #uncover("2-")[
      #stack-join(x1, 7, x2, 4, w: osi-w, (
        ((0, 2), (0, 0), "application"),
        ((3, 3), (1, 1), "transport"),
        ((4, 4), (2, 2), "network"),
        ((5, 6), (3, 3), "link"),
      ))
      #stack-title(x2, w: osi-w)[TCP/IP (RFC 1122, 1989)]
      #layer-stack(x2, w: osi-w, (
        ("Application", "application", "HTTP, DNS, SSH"),
        ("Transport", "transport", "TCP, UDP"),
        ("Internet", "network", "IP"),
        ("Link", "link", "Ethernet, Wi-Fi"),
      ))
    ]

    // what is used today
    #uncover("3-")[
      #stack-join(x2, 4, x3, 5, w: osi-w, (
        ((0, 0), (0, 0), "application"),
        ((1, 1), (1, 1), "transport"),
        ((2, 2), (2, 2), "network"),
        ((3, 3), (3, 4), "link"),
      ))
      #stack-title(x3, w: osi-w)[in practice]
      #layer-stack(x3, w: osi-w, (
        ("5. Application", "application", none),
        ("4. Transport", "transport", none),
        ("3. Network", "network", none),
        ("2. Data Link", "link", none),
        ("1. Physical", "physical", none),
      ))
    ]

    // the highway
    #uncover("4-")[
      #let y(i) = stack-y(5, i)
      #let bx = x3 + osi-w + 10pt
      #bracket(bx, y(0), y(1), [🏬 Users], [the services: shop, post office])
      #bracket(bx, y(1), y(2), [🚚 Transport], [vans with parcels])
      #bracket(bx, y(2), y(5), [🛣️ Infrastructure], [🚦 junctions (routers) and roads (cables, radio)])
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1)[- *OSI*: a standard designed by committee, 7 layers, each one with a clear job]
    #only(2)[- *TCP/IP* was already running the Internet (since 1983): Session and Presentation are left to the applications]
    #only(3)[- today we use 5 layers: TCP/IP, with the *Link* layer split in *Data Link* and *Physical*]
    #only(4)[- the same layers as the highway: who uses it, what carries the data, what it drives on]
  ]))
]

#slide[
  == Interchangeable Layers
  each layer offers a *standard service* to the layer above, so the layers below *can be swapped*

  #drawing(height: 165pt)[
    // the stack does not change
    #layer-box(180pt, 0pt, 140pt, 25pt, "Application", "application", sub: "Firefox")
    #layer-box(180pt, 25pt, 140pt, 25pt, "Transport", "transport", sub: "TCP")
    #layer-box(180pt, 50pt, 140pt, 25pt, "Network", "network", sub: "IP")
    #iface(96pt, below: true)[standard interface: send / receive a packet]

    // the network cards that can be plugged in below it
    #let cards = (
      (115pt, pic("eth-card", size: 30pt), [*Ethernet card* \ cable]),
      (250pt, pic("wifi-card", size: 30pt), [*Wi-Fi card* \ radio]),
      (385pt, pic("modem", size: 30pt), [*4G / 5G modem* \ mobile network]),
    )
    #for (i, (x, img, name)) in cards.enumerate() {
      option-box(x, 110pt, 110pt, 54pt, stack(spacing: 3pt, img, text(size: 7.5pt, name)))
      only(i + 1, both-ways(250pt, 75pt, x, 110pt, run: 89pt))
      only(i + 1, option-box(x, 110pt, 110pt, 54pt, none, selected: true))
    }
    #label(28pt, 137pt, text(size: 7.5pt, fill: luma(90))[Data Link \ + Physical])
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only("1-3")[- Firefox, TCP and IP *do not change* when the network card changes]
    #only(4)[- 🚚 the same van drives on a highway, a country road or a bridge: it only needs a road]
  ]))
]

#slide[
  == Interchangeable Layers
  *Swapping the Network Layer*: IPv4 or IPv6, Firefox and TCP do not care

  #drawing(height: 176pt)[
    #layer-box(180pt, 0pt, 140pt, 25pt, "Application", "application", sub: "Firefox")
    #layer-box(180pt, 25pt, 140pt, 25pt, "Transport", "transport", sub: "TCP")
    #iface(71pt)[standard interface: send / receive a segment]

    // the two versions of IP
    #let ips = (
      (165pt, [*IPv4* \ `192.168.1.105`]),
      (335pt, [*IPv6* \ `2001:db8::105`]),
    )
    #for (x, body) in ips {
      place(top + left, dx: x - 65pt, dy: 84pt, box(width: 130pt, height: 36pt, fill: layer-colors.network.fill.lighten(30%), radius: 4pt))
      option-box(x, 84pt, 130pt, 36pt, text(size: 8pt, body))
    }
    // which version is used on each step: both on the last one (dual stack)
    #for (step, used) in ((0,), (1,), (0, 1)).enumerate() {
      only(step + 1, for i in used {
        let x = ips.at(i).at(0)
        // when both are used, the arrows leave the shared boxes side by side
        let mid = if used.len() == 1 { 250pt } else if i == 0 { 238pt } else { 262pt }
        both-ways(mid, 50pt, x, 84pt, run: 64pt)
        both-ways(x, 120pt, mid, 150pt, run: 132pt)
        option-box(x, 84pt, 130pt, 36pt, none, selected: true)
      })
    }
    #label(28pt, 102pt, text(size: 7.5pt, fill: luma(90))[Network])
    #iface(139pt)[standard interface: send / receive a packet]
    #layer-box(180pt, 150pt, 140pt, 25pt, "Data Link", "link", sub: "Wi-Fi card")
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only("1-2")[- the same Firefox, TCP and Wi-Fi card work over *IPv4* and over *IPv6*]
    #only(3)[- most computers today use *both* (_dual stack_): the layers above do not need to know]
  ]))
]


#slide[
  == The Network in the OS

  #drawing(height: 172pt)[
    #let x0 = 62pt
    #let w = 300pt
    #let col = w / 3
    #let cx(i) = x0 + col * (i + 0.5)
    // a border between two worlds: a dashed line, the names of the worlds on the left
    #let sep(y, above, below) = {
      wire((0pt, y), (x0 + w, y), stroke: (paint: luma(150), thickness: 1pt, dash: "dashed"))
      let name(dy, body) = place(top + left, dx: 0pt, dy: y + dy, box(width: x0 - 8pt, align(right, text(
        size: 6.5pt,
        style: "italic",
        fill: accent,
        weight: "bold",
        body,
      ))))
      name(-9pt, above)
      name(2pt, below)
    }
    // the names of the layers, on the left
    #let layer-name(y, body) = place(top + left, dx: 0pt, dy: y - 5pt, box(width: x0 - 8pt, align(
      right,
      text(size: 7.5pt, fill: luma(80), body),
    )))
    #let bx = x0 + w + 12pt

    // 1. the hardware: one card for each network
    #uncover("1-")[
      #for (i, (img, name)) in (
        (pic("eth-card", size: 22pt), [Ethernet card]),
        (pic("wifi-card", size: 22pt), [Wi-Fi card]),
        (pic("modem", size: 22pt), [4G / 5G modem]),
      ).enumerate() {
        option-box(cx(i), 130pt, col - 8pt, 42pt, stack(spacing: 2pt, img, text(size: 7pt, weight: "bold", name)))
      }
      #layer-name(151pt)[Physical]
      #bracket(bx, 130pt, 172pt, [hardware], [the network cards, with their firmware])
    ]

    // 2. the drivers: one for each card
    #uncover("2-")[
      #sep(124pt)[kernel][hardware]
      #for (i, (drv, iface)) in (("e1000e", "enp0s31f6"), ("iwlwifi", "wlp2s0"), ("qmi_wwan", "wwan0")).enumerate() {
        layer-box(x0 + col * i + 4pt, 90pt, col - 8pt, 28pt, raw(drv), "link", sub: [interface #raw(iface)])
      }
      #layer-name(104pt)[Data Link]
      #bracket(bx, 90pt, 118pt, [OS: drivers], [one for each card, in the kernel])
    ]

    // 3. the network stack of the operating system: one for all the cards
    #uncover("3-")[
      #layer-box(x0 + 4pt, 36pt, w - 8pt, 24pt, "Transport", "transport", sub: "TCP, UDP")
      #layer-box(x0 + 4pt, 60pt, w - 8pt, 24pt, "Network", "network", sub: "IP, the routing table")
      #layer-name(48pt)[Transport]
      #layer-name(72pt)[Network]
      #bracket(bx, 36pt, 84pt, [OS: network stack], [one for all the cards, in the kernel (Linux)])
    ]

    // 4. the applications
    #uncover("4-")[
      #sep(30pt)[user space][kernel]
      #tag(x0 + w / 2, 30pt, [*sockets* (POSIX): `socket()`, `connect()`, `send()`, `recv()`], size: 6pt)
      #for (i, name) in ("Firefox", "Thunderbird", "ssh").enumerate() {
        layer-box(x0 + col * i + 4pt, 0pt, col - 8pt, 24pt, name, "application")
      }
      #layer-name(12pt)[Application]
      #bracket(bx, 0pt, 24pt, [applications], [programs, in user space])
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1)[- each network has its own *hardware*]
    #only(2)[- each card has its own *driver*: it turns the card into a network interface (`ip link`)]
    #only(3)[- the kernel has *one* network stack, it picks the card with the routing table]
    #only(4)[
      - the applications only see *sockets*: they do not know which card is used
      - sockets come from BSD Unix and are part of *POSIX*, Windows has the similar *Winsock*
    ]
  ]))
]

#let interop-names = (
  ("💻", [Fedora Linux], ([Firefox], [Linux kernel], [Linux kernel], [Intel Wi-Fi driver], [Wi-Fi radio])),
  ("🖥️", [Windows], ([Edge], [Windows kernel], [Windows kernel], [Realtek driver], [Ethernet cable])),
  ("📱", [iPhone (iOS)], ([Safari], [iOS kernel], [iOS kernel], [Apple Wi-Fi driver], [Wi-Fi radio])),
)
#let interop-layers = (
  ("Application", "application"),
  ("Transport", "transport"),
  ("Network", "network"),
  ("Data Link", "link"),
  ("Physical", "physical"),
)

#slide[
  == Protocols
  different programs on different operating systems understand each other

  #drawing(height: 165pt)[
    #let row = 27pt
    #let y0 = 26pt
    #let cy(i) = y0 + row * (i + 0.5)
    // the standard protocols between the same layers
    #for (i, proto) in ([HTTP (RFC 9110)], [TCP (RFC 9293)], [IP (RFC 791)]).enumerate() {
      draw-arrow((152pt, cy(i)), (326pt, cy(i)), color: accent, thickness: 1pt, dash: "dashed")
      draw-arrow((326pt, cy(i)), (152pt, cy(i)), color: accent, thickness: 1pt, dash: "dashed")
      tag(240pt, cy(i), text(weight: "bold", fill: accent, proto), size: 7.5pt)
    }
    #wire((150pt, cy(4)), (330pt, cy(4)), stroke: 2.5pt + luma(110))
    #pin(240pt, cy(3) + 6pt, pic("cloud", size: 38pt))

    // the client changes at every step
    #for (step, (e, os, impls)) in interop-names.enumerate() {
      only(if step == 2 { "3-" } else { step + 1 })[
        #pin(75pt, 10pt, text(size: 8.5pt)[#icon(e, size: 13pt) *#os*])
        #for (i, ((name, layer), impl)) in interop-layers.zip(impls).enumerate() {
          layer-box(0pt, y0 + i * row, 150pt, row, name, layer, sub: impl)
        }
      ]
    }
    // the server stays the same
    #pin(405pt, 10pt, text(size: 8.5pt)[#icon("🗄️", size: 13pt) *web server (FreeBSD)*])
    #let server-impls = ([nginx], [FreeBSD kernel], [FreeBSD kernel], [Intel Ethernet driver], [Ethernet cable])
    #for (i, ((name, layer), impl)) in interop-layers.zip(server-impls).enumerate() {
      layer-box(330pt, y0 + i * row, 150pt, row, name, layer, sub: impl)
    }
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only("1-3")[- each layer follows a *standard protocol*, written in an RFC: any implementation can talk to any other]
    #only(4)[- 🚚 every van follows the same traffic rules, whoever built it]
  ]))
]
