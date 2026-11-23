#import "common.typ": *

#section-cover([Wi-Fi], [a network without cables], layers: ("link", "physical"), note: [Wi-Fi])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.26 - _Wireless Ethernet_
    - Section 9.13 - _Network Configuration Managers_
  + #tanenbaum
    - Chapter 4 - _The Medium Access Control Sublayer_
      - Section 4.4 - _Wireless LANs_
  + #uso-book
    - Chapter 11 - _Rețelistică și Internet_
]

// radio waves around a point: dashed circles
#let waves(x, y, color: hl, radii: (22pt, 40pt, 58pt)) = for (i, r) in radii.enumerate() {
  place(top + left, dx: x - r, dy: y - r, circle(radius: r, stroke: (
    // the farther, the weaker
    paint: color.transparentize(30% + i * 15%),
    thickness: 1pt,
    dash: "dashed",
  )))
}

#slide[
  == Plugging In Without a Cable
  connecting to the access point

  #drawing(height: 140pt)[
    #let y = 62pt
    // Ethernet: the PC, the cable with its plugs, the switch
    #label(120pt, 8pt, text(size: 11pt, weight: "bold")[🔌 Ethernet])
    #wire((78pt, y), (166pt, y), stroke: (paint: luma(90), thickness: 4pt, cap: "round"))
    #for x in (74pt, 162pt) { at(x, y - 6pt, box(width: 9pt, height: 12pt, radius: 1.5pt, fill: luma(55))) }
    #host(45pt, y, "PC", size: 40pt)
    #netdev(195pt, y, "switch", name: "Switch", size: 22pt)
    #label(122pt, y + 20pt, text(size: 8pt, fill: hl, weight: "bold")[plug the cable])

    // Wi-Fi: the laptop, the radio link, the access point
    #uncover("2-")[
      #label(368pt, 8pt, text(size: 11pt, weight: "bold")[📶 Wi-Fi])
      #waves(440pt, y, radii: (24pt, 32pt, 40pt))
      // the "software cable": a dotted cable
      #wire((326pt, y), (414pt, y), stroke: (paint: hl, thickness: 3.5pt, dash: (array: (0pt, 7pt), phase: 0pt), cap: "round"))
      #tag(352pt, y + 54pt, [📶 `HomeWiFi` #h(3pt) 🔑 `********`], fill: hl-bg, stroke: 1pt + hl, size: 7.5pt)
      #host(298pt, y, "laptop", size: 40pt)
      #netdev(440pt, y, "wifi-router", name: "Access Point", size: 30pt)
      #label(352pt, y + 25pt, align(center, text(size: 8pt, fill: hl, weight: "bold")[connect to the AP \ = a *software cable*]))
    ]

    // the two are the same thing
    #uncover("2-")[#pin(243pt, y, text(size: 30pt, weight: "bold", fill: hl, "="))]
  ]

  // a note with a big emoji on the left
  #let note(e, body) = block(
    width: 100%,
    inset: (x: 10pt, y: 8pt),
    fill: ip-peach.bg,
    stroke: (left: 3pt + ip-peach.bar),
    radius: (right: 4pt),
    grid(columns: (auto, 1fr), column-gutter: 10pt, align: horizon, icon(e, size: 20pt), body),
  )
  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only(1, note("🔌")[*Ethernet*: you *plug the cable* into the switch, and the computer is *in the network*])
    #only(2, note("📶")[
      *Wi-Fi*: no cable, you *choose the network* and type the *password* \
      connecting to the AP = plugging in a *software cable* \
      disconnecting = pulling the cable out
    ])
  ]))
]

#slide[
  == Wi-Fi Access Point
  the center of a Wi-Fi network

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1em)[
    #drawing(width: 250pt, height: 195pt)[
      #let ap = (125pt, 70pt)
      #let sw = (125pt, 150pt)
      #for p in ((35pt, 30pt), (35pt, 110pt), (215pt, 30pt)) { radio(p, ap) }
      // step 2: the AP is also a bridge to the wired network
      #only("2-")[
        #wire(ap, sw)
        #wire(sw, (40pt, 170pt))
        #wire(sw, (210pt, 170pt))
        #host(40pt, 170pt, "PC", size: 20pt)
        #host(210pt, 170pt, "PC", size: 20pt)
        #netdev(..sw, "switch", size: 18pt)
        #tag(125pt, 112pt, [*bridge*: Wi-Fi #arrow-both Ethernet], fill: hl-bg, stroke: 1pt + hl, size: 7pt)
      ]
      #host(35pt, 30pt, "phone", kind: "phone", size: 24pt)
      #host(35pt, 110pt, "laptop", size: 24pt)
      #host(215pt, 30pt, "phone", kind: "phone", size: 24pt)
      #netdev(..ap, "wifi-router", name: "Access Point", size: 32pt, label-at: right, highlight: true)
      #sees-stack(200pt, 92pt, "link")
    ]
  ][
    #set text(size: 11pt)
    #block[- connects *wireless* devices]
    #block[- all the frames go *through the AP*]
    #uncover("2-")[
      #block[- with a cable to the wired network, the AP is also a *bridge*]
      #block[- Wi-Fi and Ethernet become *one network*]
    ]
  ]
]

// who can read a frame, for each kind of Wi-Fi security: the phone sends a
// frame to the AP (for the laptop), phone 2 listens
// a key with its name (K, K1, K2...), so the keys differ by name, not only by color
#let key-badge(color, name) = box(
  fill: color.lighten(75%),
  stroke: 0.8pt + color,
  radius: 3pt,
  inset: (x: 1pt, y: 1pt),
  [#icon("🔑", size: 9pt)#text(size: 6.5pt, weight: "bold", fill: color.darken(30%), name)#h(1.5pt)],
)
#let sec-kinds = (
  (
    kind: "open",
    title: [🔓 Open],
    points: ([no password, *no key*], [the frame travels *in clear*]),
    like: "hub",
  ),
  (
    kind: "wep",
    title: [⚠️ WEP],
    points: ([*one key* for everyone], [phone 2 has the key too: *it reads it*]),
    warning: [⚠️ the WEP key can be *broken in minutes*: \ anyone nearby can read everything],
    like: "hub",
  ),
  (
    kind: "wpa",
    title: [🔒 WPA2 / WPA3],
    points: ([the password only lets a device *join*], [then each device gets *its own key*], [phone 2 has another key: *it cannot read it*]),
    like: "switch",
  ),
)

// the three types of Wi-Fi network as tabs, the current one filled; only
// the colors change between the steps (same weight, same size: nothing moves)
#let sec-tabs(current) = block(width: 100%, {
  text(size: 9pt, fill: luma(90))[the *type* of the Wi-Fi network:]
  v(2pt)
  stack(dir: ltr, spacing: 4pt, ..sec-kinds.enumerate().map(((i, sk)) => {
    let on = i == current
    box(
      fill: if on { accent } else { white },
      stroke: 1pt + if on { accent } else { luma(180) },
      radius: 4pt,
      inset: (x: 5pt, y: 4pt),
      text(size: 9.5pt, weight: "bold", fill: if on { white } else { luma(140) }, sk.title),
    )
  }))
})

#slide[
  == Who Can Read It?
  it depends on the type of the network: the phone sends a frame, phone 2 listens

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1em)[
    #drawing(width: 250pt, height: 195pt)[
      #let ap = (140pt, 45pt)
      #let phone = (68pt, 115pt)
      #let laptop = (222pt, 115pt)
      #let other = (140pt, 165pt)
      #let (k-phone, k-laptop, k-other, k-all) = (rgb("e8590c"), rgb("1c7ed6"), rgb("2f9e44"), luma(110))
      #for p in (phone, laptop, other) { radio(p, ap) }
      #for (n, sk) in sec-kinds.enumerate() {
        only(n + 1, {
          waves(..phone, radii: (16pt, 32pt, 48pt, 64pt))
          // the frame in the air
          let c = if sk.kind == "open" { luma(120) } else if sk.kind == "wep" { k-all } else { k-phone }
          pin(98pt, 72pt, box(
            fill: white,
            stroke: 1pt + c,
            radius: 3pt,
            inset: (x: 3pt, y: 2pt),
            text(size: 8pt)[#icon("✉️", size: 8pt) to *laptop*: #if sk.kind == "open" [hello] else [#icon("🔒", size: 7pt) `x7#q%`]],
          ))
          // what phone 2 gets
          let reads = sk.kind != "wpa"
          let rc = if reads { bad-color } else { ok-color }
          wire((154pt, 165pt), (172pt, 165pt), stroke: 0.8pt + rc)
          pin(207pt, 165pt, box(
            fill: rc.lighten(88%),
            stroke: 1pt + rc,
            radius: 4pt,
            inset: (x: 4pt, y: 3pt),
            text(size: 8pt)[#if reads [👀 reads *hello*] else [❓ only `x7#q%`]],
          ))
        })
      }
      #host(..phone, "phone", kind: "phone", size: 24pt)
      #host(..laptop, "laptop", size: 24pt)
      #host(..other, "phone 2", kind: "phone", size: 22pt)
      #netdev(..ap, "wifi-router", size: 26pt)
      // the keys, on top of the devices
      #for (n, sk) in sec-kinds.enumerate() {
        only(n + 1, {
          // the keys
          // phone 2 has its key on the left, the bubble is on its right
          let key-at(p, c, name) = pin(p.at(0) + if p == other { -22pt } else { 22pt }, p.at(1) - 10pt, key-badge(c, name))
          if sk.kind == "wep" {
            for p in (ap, phone, laptop, other) { key-at(p, k-all, "K") }
            // the key can be broken
            pin(ap.at(0) + 66pt, ap.at(1) - 10pt, box(
              fill: rgb("fff3bf"),
              stroke: 1pt + rgb("f08c00"),
              radius: 3pt,
              inset: (x: 3pt, y: 2pt),
              text(size: 7.5pt, weight: "bold")[⚠️ breakable!],
            ))
          } else if sk.kind == "wpa" {
            key-at(phone, k-phone, "K1")
            key-at(laptop, k-laptop, "K2")
            key-at(other, k-other, "K3")
            // the AP has a key for each device
            pin(ap.at(0) + 56pt, ap.at(1), stack(
              dir: ltr,
              spacing: 1pt,
              key-badge(k-phone, "K1"),
              key-badge(k-laptop, "K2"),
              key-badge(k-other, "K3"),
            ))
          }
        })
      }
    ]
  ][
    #set text(size: 11pt)
    #for (n, sk) in sec-kinds.enumerate() {
      only(n + 1)[
        #sec-tabs(n)
        // a fixed height, so the verdict box is at the same place on every step
        #block(height: 86pt, width: 100%)[
          #for pt in sk.points { block[- #pt] }
          #if "warning" in sk {
            block(
              width: 100%,
              fill: rgb("fff3bf"),
              stroke: 1.5pt + rgb("f08c00"),
              radius: 4pt,
              inset: (x: 8pt, y: 6pt),
              text(size: 10pt, sk.warning),
            )
          }
        ]
        // the verdict: which device the AP behaves like
        #let hub = sk.like == "hub"
        // WEP: yellow, like its warning
        #let c = if sk.kind == "wep" { rgb("e67700") } else if hub { bad-color } else { ok-color }
        #align(center, box(
          fill: if sk.kind == "wep" { rgb("fff3bf") } else { c.lighten(90%) },
          stroke: 1.5pt + c,
          radius: 8pt,
          inset: (x: 12pt, y: 6pt),
          grid(
            columns: 2,
            column-gutter: 10pt,
            align: horizon,
            pic(sk.like, size: 22pt),
            align(left)[
              #text(size: 9pt, fill: luma(80))[the AP behaves like a] \
              #text(size: 15pt, weight: "bold", fill: c, upper(sk.like)) \
              #text(size: 8.5pt, fill: luma(80), if hub [everyone can read everything] else [each one reads only its own frames])
            ],
          ),
        ))
      ]
    }
  ]
]

// the fields of a Wi-Fi (802.11) data frame, sent through the access point
// to a destination on the wired side
#let wifi-fields = (
  ("fc", [Control], [2 B], 40pt, none, "data"),
  ("dur", [Duration], [2 B], 40pt, none, "44 µs"),
  ("a1", [Address 1], [6 B], 50pt, none, "AP"),
  ("a2", [Address 2], [6 B], 50pt, none, "source"),
  ("a3", [Address 3], [6 B], 56pt, none, "destination"),
  ("seq", [Seq.], [2 B], 32pt, none, "#1234"),
  ("data", [Payload], [0 - 2304 B], 138pt, "🔒", none),
  ("crc", [FCS], [4 B], 34pt, none, "CRC-32"),
)

// the data of a Wi-Fi frame: the type, then the packet, both encrypted
#let wifi-data = {
  let part(c, w, size, body) = box(width: w, fill: c.fill, stroke: 0.6pt + c.stroke, radius: 2pt, inset: (y: 2.5pt), align(center, text(size: size, body)))
  box(baseline: 40%, grid(
    columns: 2,
    column-gutter: 6pt,
    align: horizon,
    part(layer-colors.link, 26pt, 5pt)[*Type* \ `0x0800`],
    part(layer-colors.network, 60pt, 6.5pt)[*IPv4* \ packet],
  ))
}

#slide[
  == Wi-Fi Frame
  the same idea, a few more fields

  #let steps = (
    (none, none),
    (("a1", "a2", "a3"), explain(
      [*three addresses*: on Wi-Fi the frame goes *through the access point*],
      ([*Address 1*], [who receives it over the air: the *AP*]),
      ([*Address 2*], [who sends it over the air: the *source*]),
      ([*Address 3*], [the final *destination*, on the Ethernet side: the AP puts the data in an Ethernet frame for it]),
    )),
    (("fc", "dur", "seq"), explain(
      [the radio needs *more control*],
      ([*Control*], [the kind of frame (data, management like _beacons_, control like _ACK_), to or from the AP, encrypted or not]),
      ([*Duration*], [how long the radio stays busy: the others wait, to avoid collisions]),
      ([*Seq.*], [the number of the frame, to recognize a frame received twice]),
    )),
    (("data",), explain(
      [🏷️ *Type*: what is inside the frame, like on Ethernet],
      ([`0x0800`], [an IPv4 packet (the same numbers as Ethernet)]),
      ([💡], [not in the header: it starts the data (a small _LLC/SNAP_ header, 8 bytes), so it is encrypted too]),
    )),
    (("data", "crc"), explain(
      [the *data* and the *trailer*],
      ([📦 *Payload*], [the data, *encrypted* if the network has a password (WPA2, WPA3), in clear on an open network]),
      ([*FCS*], [the same CRC-32 as Ethernet; the radio loses frames, so every *unicast* frame is confirmed by an *ACK* and sent again if the ACK does not come]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #frame-drawing(
        selected: if keys == none { () } else { keys },
        fields: wifi-fields,
        groups: (("fc", "seq", [*header*: 24 bytes]), ("data", "data", [*data*, 🔒 if WPA2 / WPA3]), ("crc", "crc", [*trailer*])),
        packet: wifi-data,
        inner: (fill: luma(238), stroke: luma(110)),
        name-size: 7.5pt,
        height: 106pt,
        extra: if keys == ("data",) {
          hint-arrow(310pt, 359pt, [🏷️ a hint: what the data means], label-at: left, y1: 57pt)
        } else if keys == ("data", "crc") {
          hint-arrow(432pt, (337pt, 20pt), [✅ checks the header and the data], label-x: 180pt)
        },
      )
      #if body != none { body }
    ]
  }
]

// ---------------------------------------------------------------------------
// nmcli
// ---------------------------------------------------------------------------

// `nmcli device status`
#let dev-w = (16, 10, 24, 10)
#let dev-row(d, t, st, c) = tab(dev-w, ("dev", d), ("type", t), ("state", st), ("conn", c))
#let dev-lines = (
  "$ nmcli device status",
  dev-row("DEVICE", "TYPE", "STATE", "CONNECTION"),
  dev-row("wlp2s0", "wifi", "connected", "HomeWiFi"),
  dev-row("lo", "loopback", "connected (externally)", "lo"),
  dev-row("p2p-dev-wlp2s0", "wifi-p2p", "disconnected", "--"),
  dev-row("enp0s31f6", "ethernet", "unavailable", "--"),
)

#slide[
  == Network Devices
  Fedora: NetworkManager, the `nmcli` command

  #let steps = (
    ((), explain[*NetworkManager*: the service that sets up the network cards on Fedora (and Ubuntu); `nmcli` is its command-line client]),
    (("dev",), explain[*device*: the name of the network card, the same as in `ip link`]),
    (("type",), explain(
      [*type* of the card: `wifi`, `ethernet`, `loopback`],
      ([`wifi-p2p`], [_Wi-Fi Direct_ (phone to laptop, no AP): a virtual device NetworkManager makes for the Wi-Fi card]),
    )),
    (("state",), explain(
      [*state*: is the card connected?],
      ([`connected`], [yes, NetworkManager set it up]),
      ([`disconnected`], [could connect, but it is not used]),
      ([`unavailable`], [cannot connect: the Ethernet card has no cable]),
      ([`(externally)`], [set up by someone else: `lo` is set up by Linux]),
    )),
    (("conn",), explain(
      [*connection*: the name of the saved settings the card uses],
      ([`HomeWiFi`], [by default, the name of the Wi-Fi network]),
      ([`--`], [none]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(dev-lines, hl: ((keys, ip-peach),), size: 1em)
      #if body != none { body }
    ]
  }
]

// `nmcli device wifi list`
#let wl-w = (7, 19, 11, 7, 5, 11, 7, 5, 9)
#let wl-row(..c) = tab(wl-w, ..("in-use", "bssid", "ssid", "mode", "chan", "rate", "signal", "bars", "sec").zip(c.pos()))
#let wl-lines = (
  "$ nmcli device wifi list ifname wlp2s0",
  wl-row("IN-USE", "BSSID", "SSID", "MODE", "CHAN", "RATE", "SIGNAL", "BARS", "SECURITY"),
  // the network in use: its name is highlighted with the IN-USE column too
  wl-row("*", "70:B5:E8:2D:91:4D", "HomeWiFi", "Infra", "36", "540 Mbit/s", "82", "****", "WPA2 WPA3").map(((k, t)) => (
    if k == "ssid" { "ssid-used" } else { k },
    t,
  )),
  wl-row(" ", "7A:15:C2:09:8E:41", "Neighbours", "Infra", "6", "130 Mbit/s", "47", "**  ", "WPA2"),
  wl-row(" ", "02:1F:6B:3D:77:10", "CafeFree", "Infra", "11", "65 Mbit/s", "30", "*   ", "--"),
  wl-row(" ", "D2:5F:0A:31:44:9E", "LabGame", "Ad-Hoc", "1", "54 Mbit/s", "25", "*   ", "--"),
)

#slide[
  == Nearby Wi-Fi Networks
  what the Wi-Fi card hears around it

  #let steps = (
    ((), explain[`ifname wlp2s0`: which Wi-Fi card to use; without it, `nmcli` shows the networks seen by *all* the Wi-Fi cards]),
    (("in-use", "ssid-used"), explain[*IN-USE*: the `*` shows the network the card is connected to *now*: `HomeWiFi`]),
    (("bssid", "ssid", "ssid-used"), explain(
      [*who* is the network],
      ([*SSID*], [the name of the network]),
      ([*BSSID*], [the MAC address of the access point]),
    )),
    (("mode", "chan"), explain(
      [*how* it works],
      ([`Infra`], [_infrastructure_: everything goes through an access point]),
      ([`Ad-Hoc`], [no access point: the devices talk *directly* to each other, \ e.g. two laptops in a lab, playing a game or copying files]),
      ([*CHAN*], [the radio channel: `1` - `13` are 2.4 GHz, `36` and above 5 GHz]),
    )),
    (("sec",), explain(
      [*security*],
      ([`WPA2 WPA3`], [a key for each device, the access point accepts both]),
      ([`--`], [open: no password, anyone can read]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #parts-terminal(wl-lines, hl: ((keys, ip-peach),), size: 1em)
      #body
    ]
  }
]
