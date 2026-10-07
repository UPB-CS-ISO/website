#import "common.typ": *

#section-cover([Wi-Fi], [a network without cables])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.26 - _Wireless Ethernet_
  + #tanenbaum
    - Chapter 4 - _The Medium Access Control Sublayer_
      - Section 4.4 - _Wireless LANs_
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
  == Plugging In, Without a Cable
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
      #tag(352pt, y + 54pt, [📶 `Home` #h(3pt) 🔑 `********`], fill: hl-bg, stroke: 1pt + hl, size: 7.5pt)
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
    #only(2, note("📶")[*Wi-Fi*: no cable to plug in, you *choose the network* and type the *password*: connecting to the access point is a *software cable*, made by the programs of the laptop and of the AP; *disconnecting* is pulling the cable out])
  ]))
]

// the fields of a Wi-Fi (802.11) data frame, sent through the access point
// to a destination on the wired side
#let wifi-fields = (
  ("fc", [Control], [2 B], 50pt, none, "data, to AP"),
  ("dur", [Duration], [2 B], 46pt, none, "44 µs"),
  ("a1", [Address 1], [6 B], 66pt, none, "AP"),
  ("a2", [Address 2], [6 B], 66pt, none, "source"),
  ("a3", [Address 3], [6 B], 66pt, none, "destination"),
  ("seq", [Seq.], [2 B], 38pt, none, "#1234"),
  ("data", [Payload], [0 - 2304 B], 78pt, "📦", none),
  ("crc", [FCS], [4 B], 36pt, none, "CRC"),
)

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
      ([*Duration*], [how long the radio stays busy: the others wait (collision avoidance)]),
      ([*Seq.*], [the number of the frame, to recognize a frame received twice]),
    )),
    (("data", "crc"), explain(
      [the *data* and the *trailer*],
      ([📦 *Payload*], [the data, *encrypted* if the network has a password (WPA2, WPA3), in clear on an open network; it starts with a small header that holds the type, like Ethernet's Type]),
      ([*FCS*], [the same CRC as Ethernet; the radio loses frames, so every frame is confirmed by an *ACK* and sent again if the ACK does not come]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #frame-drawing(
        selected: if keys == none { () } else { keys },
        fields: wifi-fields,
        groups: (("fc", "seq", [*header*: 24 bytes]), ("data", "data", [*data*]), ("crc", "crc", [*trailer*])),
        packet: [*IPv4* \ #text(size: 6.5pt)[usually encrypted]],
        name-size: 7.5pt,
      )
      #if body != none { body }
    ]
  }
]

#slide[
  == Wi-Fi Access Point

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
    #only(1)[
      #block[- connects *wireless* devices]
      #block[- all the frames go *through the AP*]
    ]
    #only("2-")[
      #block[- with a cable to the wired network, the AP is also a *bridge*]
      #block[- Wi-Fi and Ethernet become *one network*]
    ]
  ]
]

// who can read a frame, for each kind of Wi-Fi security: the phone sends a
// frame to the AP (for the laptop), phone 2 listens
#let key-badge(color) = box(
  fill: color.lighten(75%),
  stroke: 0.8pt + color,
  radius: 3pt,
  inset: (x: 1pt, y: 1pt),
  icon("🔑", size: 9pt),
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
    points: ([each device gets *its own key* when it joins], [phone 2 has another key: *it cannot read it*]),
    like: "switch",
  ),
)

#slide[
  == Who Can Read It?
  the phone sends a frame, phone 2 listens

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
          let key-at(p, c) = pin(p.at(0) + if p == other { -20pt } else { 20pt }, p.at(1) - 10pt, key-badge(c))
          if sk.kind == "wep" {
            for p in (ap, phone, laptop, other) { key-at(p, k-all) }
            // the key can be broken
            pin(ap.at(0) + 52pt, ap.at(1) - 10pt, box(
              fill: rgb("fff3bf"),
              stroke: 1pt + rgb("f08c00"),
              radius: 3pt,
              inset: (x: 3pt, y: 2pt),
              text(size: 7.5pt, weight: "bold")[⚠️ breakable!],
            ))
          } else if sk.kind == "wpa" {
            key-at(phone, k-phone)
            key-at(laptop, k-laptop)
            key-at(other, k-other)
            // the AP has a key for each device
            pin(ap.at(0) + 42pt, ap.at(1), stack(
              dir: ltr,
              spacing: 1pt,
              key-badge(k-phone),
              key-badge(k-laptop),
              key-badge(k-other),
            ))
          }
        })
      }
    ]
  ][
    #set text(size: 11pt)
    #for (n, sk) in sec-kinds.enumerate() {
      only(n + 1)[
        // a fixed height, so the verdict box is at the same place on every step
        #block(height: 118pt, width: 100%)[
          #text(size: 13pt, weight: "bold", sk.title)
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
          inset: (x: 12pt, y: 8pt),
          grid(
            columns: 2,
            column-gutter: 10pt,
            align: horizon,
            pic(sk.like, size: 22pt),
            align(left)[
              #text(size: 9pt, fill: luma(80))[the AP behaves like a] \
              #text(size: 15pt, weight: "bold", fill: c, upper(sk.like))
            ],
          ),
        ))
        #align(center, text(size: 9.5pt, fill: luma(80), if hub [everyone can read everything] else [each one reads only its own frames]))
      ]
    }
  ]
]

// ---------------------------------------------------------------------------
// nmcli
// ---------------------------------------------------------------------------

// `nmcli device status`
#let dev-w = (11, 10, 24, 10)
#let dev-row(d, t, st, c) = tab(dev-w, ("dev", d), ("type", t), ("state", st), ("conn", c))
#let dev-lines = (
  "$ nmcli device status",
  dev-row("DEVICE", "TYPE", "STATE", "CONNECTION"),
  dev-row("wlp2s0", "wifi", "connected", "HomeWiFi"),
  dev-row("enp0s31f6", "ethernet", "unavailable", "--"),
  dev-row("lo", "loopback", "connected (externally)", "lo"),
)

#slide[
  == Network Devices
  Fedora: NetworkManager, the `nmcli` command

  #let steps = (
    ((), none),
    (("dev",), explain[*device*: the name of the network card, the same as in `ip link`]),
    (("type",), explain[*type* of the card: `wifi`, `ethernet`, `loopback`]),
    (("state",), explain(
      [*state*: is the card connected?],
      ([`connected`], [yes, NetworkManager set it up]),
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
  wl-row("*", "3C:A9:F4:11:22:33", "HomeWiFi", "Infra", "36", "540 Mbit/s", "82", "****", "WPA2 WPA3").map(((k, t)) => (
    if k == "ssid" { "ssid-used" } else { k },
    t,
  )),
  wl-row(" ", "7A:15:C2:09:8E:41", "Neighbours", "Infra", "6", "130 Mbit/s", "47", "**  ", "WPA2"),
  wl-row(" ", "02:1F:6B:3D:77:10", "CafeFree", "Infra", "11", "65 Mbit/s", "30", "*   ", "--"),
  wl-row(" ", "D2:5F:0A:31:44:9E", "LabGame", "Ad-Hoc", "1", "54 Mbit/s", "25", "*   ", "--"),
)

#slide[
  == Wi-Fi Networks Around

  #let steps = (
    ((), explain[`ifname wlp2s0`: which Wi-Fi card to use; without it, nmcli shows the networks seen by *all* the Wi-Fi cards]),
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

// `nmcli device wifi connect`, disconnect, connect back, radio off and on
#let uuid = "6e2c8d5b-1f0a-4c3e-9b7d-2a51c0e8f913"
#let activated = ((none, "Device '"), ("dev", "wlp2s0"), (none, "' successfully activated with '"), ("uuid", uuid), (none, "'."))
#let con-steps = (
  (
    lines: ("$ nmcli device wifi connect HomeWiFi password 'my secret' ifname wlp2s0", activated),
    keys: ("dev", "uuid"),
    body: explain(
      [*connect* the card `wlp2s0` to the `HomeWiFi` network],
      ([`ifname wlp2s0`], [which Wi-Fi card to use; without it, nmcli picks the Wi-Fi card for you]),
      ([`6e2c8d5b-...`], [a *connection* is saved, with this ID: next time the card connects by itself]),
    ),
  ),
  (
    // the same shell, continued after the connect
    lines: (
      "$ nmcli device wifi connect HomeWiFi password 'my secret' ifname wlp2s0",
      activated,
      "$ nmcli device disconnect wlp2s0",
      ((none, "Device '"), ("dev2", "wlp2s0"), (none, "' successfully "), ("off", "disconnected"), (none, ".")),
    ),
    keys: ("dev2", "off"),
    body: explain(
      [*disconnect* the card],
      ([`wlp2s0`], [here the name of the card is *required*]),
      ([`disconnected`], [only this card; the connection stays saved]),
    ),
  ),
  (
    lines: ("$ nmcli device connect wlp2s0", activated),
    keys: ("dev", "uuid"),
    body: explain(
      [*connect back*],
      ([`wlp2s0`], [here the name of the card is *required*]),
      ([`6e2c8d5b-...`], [the same saved connection: no password needed]),
    ),
  ),
  (
    lines: (
      "$ nmcli connection show",
      ..(
        ("NAME", "UUID", "TYPE", "DEVICE"),
        ("HomeWiFi", uuid, "wifi", "wlp2s0"),
        ("lo", "8d3b5f0e-6a41-4d2c-9e7b-1c0a2f4d6e85", "loopback", "lo"),
        ("CafeFree", "3f1d7c92-b5e4-4a08-8c6d-9e2f0a1b7c43", "wifi", "--"),
        ("Wired connection 1", "b7e2a419-0c5d-3f86-a1e4-6d9c2b8f0e57", "ethernet", "--"),
      ).map(((n, u, t, d)) => tab((20, 38, 10, 7), ("name", n), (none, u), (none, t), ("device", d))),
    ),
    keys: ("name", "device"),
    body: explain(
      [the *saved connections*],
      ([*NAME*], [the name to use in commands]),
      ([*DEVICE*], [the card that uses it now; `--`: not in use]),
    ),
  ),
  (
    lines: (
      "$ nmcli connection up CafeFree ifname wlp2s0",
      ((none, "Connection "), ("ok", "successfully activated"), (none, " (D-Bus active path:")),
      ((none, "/org/freedesktop/NetworkManager/ActiveConnection/7)"),),
    ),
    keys: ("ok",),
    body: explain(
      [*pick* a saved connection],
      ([`up CafeFree`], [connect with the saved connection `CafeFree`; `down` disconnects it]),
      ([`ifname wlp2s0`], [which Wi-Fi card to use; without it, nmcli picks the Wi-Fi card for you]),
    ),
  ),
  (
    lines: (
      "$ nmcli connection up HomeWiFi ifname wlp0s20f0u2",
      ((none, "Connection "), ("ok", "successfully activated"), (none, " (D-Bus active path:")),
      ((none, "/org/freedesktop/NetworkManager/ActiveConnection/8)"),),
    ),
    keys: ("ok",),
    body: explain(
      [the same connection on *another Wi-Fi card*],
      ([`wlp0s20f0u2`], [a second Wi-Fi card, on USB: it works]),
    ),
  ),
  (
    lines: (
      "$ nmcli connection up HomeWiFi ifname enp0s31f6",
      ((none, "Error: Connection activation failed: No suitable device"),),
      ((none, "found for this connection (device enp0s31f6 not available"),),
      ((none, "because profile is not compatible with device"),),
      ((none, "("), ("bad", "mismatching connection type"), (none, "))."),),
    ),
    keys: ("bad",),
    body: explain(
      [the same connection on the *Ethernet card*],
      ([`enp0s31f6`], [refused: a Wi-Fi connection needs a Wi-Fi card]),
    ),
  ),
  (
    lines: (
      "$ nmcli radio wifi off",
      "$ nmcli radio wifi",
      (("radio", "disabled"),),
      "$ nmcli radio wifi on",
    ),
    keys: ("radio",),
    body: explain(
      [turn the Wi-Fi *radio* off and on],
      ([`radio wifi`], [no card name: *all* the Wi-Fi cards, like airplane mode]),
      ([`disabled`], [the radio is off]),
    ),
  ),
)

// the steps of a slide: a terminal and an explanation for each step
#let con-slide(steps) = for (i, st) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(st.lines, hl: ((st.keys, ip-peach),), size: 1em)
    #st.body
  ]
}

#slide[
  == Connecting to Wi-Fi

  #con-slide(con-steps.slice(0, 2))
]

#slide[
  == Reconnecting to Wi-Fi
  to the previously connected network

  #con-slide(con-steps.slice(2, 3))
]

#slide[
  == Listing Connections

  #con-slide(con-steps.slice(3, 4))
]

#slide[
  == Activating Connection

  #con-slide(con-steps.slice(4))
]
