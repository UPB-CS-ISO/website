#import "common.typ": *

#section-cover([Network Layer], [IP addresses], layers: ("network",), note: [IP])

#slide[
  == Bibliography
  for this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Sections 9.1 - 9.4
      - Section 9.7 - _IPv6 Addresses and Networks_
      - Section 9.10 - _Understanding Kernel Network Interfaces_
      - Section 9.26 - _Ethernet, IP, ARP, and NDP_
  + #tanenbaum
    - Section 1.4 - _Reference Models_
    - Section 5.6 - _The Network Layer in the Internet_
  + #uso-book
    - Section 11.2.1 - _Internet Protocol (IP)_
    - Section 11.4 - _Adresarea IP. Stiva TCP/IP_
    - Section 11.5.1 - _Interfețe de rețea. Investigația configurației_
    - Section 11.6.7 - _Configurarea temporară. Comanda ip_
]

// ---------------------------------------------------------------------------
// IPv4
// ---------------------------------------------------------------------------

// the bits of an address written with dots, as a string of 32 `0` / `1`
#let addr-bits(addr) = (
  addr
    .split(".")
    .map(b => {
      let v = int(b)
      range(7, -1, step: -1).map(i => str(calc.rem(calc.quo(v, calc.pow(2, i)), 2))).join()
    })
    .join()
)

// a string of 32 bits, written back as an address with dots
#let bits-addr(bits) = (
  range(4)
    .map(k => {
      let byte = bits.slice(k * 8, k * 8 + 8)
      str(byte.clusters().fold(0, (acc, b) => acc * 2 + int(b)))
    })
    .join(".")
)

// The 32 bits of an IP address, with the bytes in decimal above them.
// With `n`, the first `n` bits are the network (in the color of the network
// layer) and the rest the host, with a dashed line where they split.
#let split-drawing(ip, n: none) = drawing(width: 470pt, height: 76pt)[
  #let (x0, cw, gap, rh) = (64pt, 10pt, 7pt, 18pt)
  #let bit-x(i) = x0 + i * cw + calc.floor(i / 8) * gap
  #let net = layer-colors.network
  #let host = layer-colors.application
  #for (k, d) in ip.split(".").enumerate() {
    label(bit-x(k * 8) + 4 * cw, 8pt, text(size: 14pt, weight: "bold", d))
  }
  #for k in range(1, 4) { label(bit-x(k * 8) - gap / 2, 8pt, text(size: 14pt, weight: "bold", ".")) }
  #for (i, b) in addr-bits(ip).clusters().enumerate() {
    let c = if n == none { (fill: luma(248), stroke: luma(160)) } else if i < n { net } else { host }
    at(bit-x(i), 22pt, box(
      width: cw,
      height: rh,
      fill: c.fill,
      stroke: 0.5pt + c.stroke,
      align(center + horizon, text(size: 8pt, font: "DejaVu Sans Mono", b)),
    ))
  }
  #if n != none {
    let cut = if calc.rem(n, 8) == 0 { bit-x(n) - gap / 2 } else { bit-x(n) - 0.5pt }
    place(top + left, line(start: (cut, 20pt), end: (cut, 50pt), stroke: (paint: hl, thickness: 2pt, dash: "dashed")))
    let bracket(x1, x2, color, body) = {
      let yb = 54pt
      wire((x1, yb - 4pt), (x1, yb), stroke: 1.2pt + color)
      wire((x1, yb), (x2, yb), stroke: 1.2pt + color)
      wire((x2, yb - 4pt), (x2, yb), stroke: 1.2pt + color)
      wire(((x1 + x2) / 2, yb), ((x1 + x2) / 2, yb + 4pt), stroke: 1.2pt + color)
      label((x1 + x2) / 2, yb + 13pt, text(size: 9pt, body))
    }
    bracket(bit-x(0), cut - 2pt, net.stroke, [🛣️ *network*: #n bits])
    bracket(cut + 2pt, bit-x(31) + cw, host.stroke, [🏠 *host*: #(32 - n) bits])
  }
]

#slide[
  == IP Address
  version 4 (IPv4)

  #only(1, split-drawing("192.168.1.105"))
  #only(2, split-drawing("192.168.1.105", n: 24))
  #only(3, split-drawing("192.168.1.105", n: 16))
  #only("4-", split-drawing("192.168.1.105", n: 20))

  #set text(size: 10pt)
  #let net = layer-colors.network
  #let host = layer-colors.application
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 8pt,
    row-gutter: 6pt,
    fact("📏", [*32 bits* = 4 bytes, each byte written as a decimal number, from `0` to `255`]),
    fact("🌍", [$2^32 approx$ *4.3 billion* addresses for the whole Internet]),

    uncover("2-", fact("🛣️", [*network*: the street, the same for all the devices in the network], c: net)),
    uncover("2-", fact("🏠", [*host*: the house number, different for every device in the network], c: host)),

    uncover("3-", fact("✂️", [the network part is *not* always 24 bits: here it is *16*])),
    uncover("4-", fact("📐", [it can end *inside a byte*: here it is *20*])),
  )
  #v(0pt)
]

// The IP address, the mask and the network, bit by bit, for a prefix `/n`.
// Step 1 shows the IP address, step 2 the mask, step 3 the network.
// The network bits (the first `n`) are in the color of the network layer,
// the host bits in another color; a dashed line marks where the mask ends.
#let mask-drawing(ip, n) = {
  let mask = range(32).map(i => if i < n { "1" } else { "0" }).join()
  let ip-b = addr-bits(ip)
  let net-b = range(32).map(i => if i < n { ip-b.at(i) } else { "0" }).join()
  let bc-b = range(32).map(i => if i < n { ip-b.at(i) } else { "1" }).join()
  drawing(width: 470pt, height: 128pt)[
    #let (x0, cw, gap, rh) = (40pt, 10pt, 7pt, 15pt)
    #let bit-x(i) = x0 + i * cw + calc.floor(i / 8) * gap
    #let net = layer-colors.network
    #let host = layer-colors.application
    #let strip(y, bits, dec, name, faded: false) = {
      label(x0 - 34pt, y + rh / 2, text(size: 8pt, weight: "bold", name))
      for (i, b) in bits.clusters().enumerate() {
        let c = if i < n { net } else { host }
        let dim = faded and i >= n
        at(bit-x(i), y, box(
          width: cw,
          height: rh,
          fill: if dim { luma(245) } else { c.fill },
          stroke: 0.5pt + if dim { luma(210) } else { c.stroke },
          align(center + horizon, text(
            size: 7.5pt,
            font: "DejaVu Sans Mono",
            fill: if dim { luma(170) } else { black },
            b,
          )),
        ))
      }
      at(bit-x(32) + 4pt, y + 2pt, text(size: 8.5pt, font: "DejaVu Sans Mono", weight: "bold", dec))
    }
    // where the mask ends: between two bytes, or inside a byte
    #let cut = if calc.rem(n, 8) == 0 { bit-x(n) - gap / 2 } else { bit-x(n) - 0.5pt }
    #tag(cut, 6pt, text(weight: "bold", "/" + str(n)), fill: hl-bg, stroke: 1pt + hl, size: 8pt)
    // the bytes, in decimal, above the IP address
    #for (k, d) in ip.split(".").enumerate() {
      label(bit-x(k * 8) + 4 * cw, 20pt, text(size: 9pt, weight: "bold", d))
    }
    #strip(28pt, ip-b, ip, [IP])
    #uncover("2-")[#strip(48pt, mask, bits-addr(mask), [mask])]
    #uncover("3-")[#strip(68pt, net-b, bits-addr(net-b), text(fill: hl)[network])]
    #uncover("4-")[#strip(88pt, bc-b, bits-addr(bc-b), text(fill: hl)[broadcast])]
    #place(top + left, line(start: (cut, 26pt), end: (cut, 106pt), stroke: (paint: hl, thickness: 2pt, dash: "dashed")))
    // the two parts
    #let bracket(x1, x2, color, body) = {
      let yb = 110pt
      wire((x1, yb - 4pt), (x1, yb), stroke: 1.2pt + color)
      wire((x1, yb), (x2, yb), stroke: 1.2pt + color)
      wire((x2, yb - 4pt), (x2, yb), stroke: 1.2pt + color)
      wire(((x1 + x2) / 2, yb), ((x1 + x2) / 2, yb + 4pt), stroke: 1.2pt + color)
      label((x1 + x2) / 2, yb + 13pt, text(size: 9pt, body))
    }
    #bracket(bit-x(0), cut - 2pt, net.stroke, [*network*: #n bits])
    #bracket(cut + 2pt, bit-x(31) + cw, host.stroke, [*host*: #(32 - n) bits])
  ]
}

// a big address (or prefix) in a colored box, with a caption under it;
// the caption may be wider than the box, it does not move the boxes apart
#let big-chip(body, c, caption, size: 24pt) = context {
  let chip = box(
    fill: c.fill,
    stroke: 1pt + c.stroke,
    radius: 4pt,
    inset: (x: 8pt, y: 6pt),
    text(font: "DejaVu Sans Mono", size: size, weight: "bold", body),
  )
  let w = measure(chip).width
  box(stack(
    spacing: 4pt,
    chip,
    box(width: w, height: 11pt, place(top + center, box(width: 300pt, align(center, text(size: 9pt, caption))))),
  ))
}

// the bits of a mask `/n`, the `1` bits in the color of the network layer,
// the `0` bits in another color
#let mask-bits(n) = {
  let bits = range(32).map(i => {
    let b = if i < n { "1" } else { "0" }
    let c = if i < n { layer-colors.network.stroke.darken(20%) } else { layer-colors.application.stroke.darken(20%) }
    let dot = if calc.rem(i, 8) == 7 and i < 31 { text(fill: luma(120), ".") }
    text(fill: c, b) + dot
  })
  text(font: "DejaVu Sans Mono", size: 15pt, weight: "bold", bits.join())
}

#slide[
  == Network Mask
  which bits of the address are the network

  #let ip-c = layer-colors.physical
  #let mask-c = (fill: hl-bg, stroke: hl)
  #align(center)[
    #big-chip("192.168.1.105", ip-c, [IP address])#big-chip("/24", mask-c, [mask as a *prefix*: the number of `1` bits])
    #uncover("2-")[
      #v(-2pt)
      #text(size: 10pt, fill: luma(90))[the same thing, written in the other format]
      #v(-2pt)
      #big-chip("192.168.1.105", ip-c, [IP address])
      #h(14pt)
      #big-chip("255.255.255.0", mask-c, [mask written like an address])
    ]
    #uncover("3-")[
      #v(-2pt)
      #mask-bits(24)
      #v(-8pt)
      #text(
        size: 9pt,
      )[#text(fill: layer-colors.network.stroke.darken(20%), weight: "bold")[24 bits of `1`]: the *network*,
        #text(fill: layer-colors.application.stroke.darken(20%), weight: "bold")[8 bits of `0`]: the *host*]
    ]
  ]

  #v(0pt)
]

// the statements under a mask drawing, one for each step: what the mask is,
// the network address, the addresses in the network, and two examples
#let mask-facts(mask, network, broadcast, devices, same, other) = {
  set text(size: 10pt)
  let row(step, term, body) = uncover(step, block(below: 0.5em, grid(
    columns: (62pt, 1fr),
    text(weight: "bold", term), body,
  )))
  row("2-", [mask], mask)
  row("3-", [network], [all the host bits `0` = #network: the address of the network itself])
  row("4-", [broadcast], [all the host bits `1` = #broadcast: a packet for *everyone* in the network])
  row("5-", [devices], devices)
  row("5-", [examples], [#same: ✅ *the same* network #h(1em) #other: ❌ *another* network, through a router])
}

#slide[
  == Network Mask /24
  the mask ends at the end of a byte (a multiple of 8)

  #mask-drawing("192.168.1.105", 24)

  #mask-facts(
    [24 bits of `1` = `255.255.255.0`],
    [`192.168.1.0`],
    [`192.168.1.255`],
    [`192.168.1.1` to `192.168.1.254`: *254* devices],
    [`192.168.1.20`],
    [`192.168.2.20`],
  )
  #v(0pt)
]

#slide[
  == Network Mask /20
  the mask ends in the middle of a byte (not a multiple of 8)

  #mask-drawing("172.16.45.130", 20)

  #mask-facts(
    [20 bits of `1` = `255.255.240.0` (`11110000` = `240`)],
    [`172.16.32.0`],
    [`172.16.47.255`],
    [`172.16.32.1` to `172.16.47.254`: *4094* devices],
    [`172.16.40.1`],
    [`172.16.50.1`],
  )
  #v(0pt)
]

// the fields of an IPv4 packet, simplified: (key, name, size, width, emoji, example)
#let ip-fields = (
  ("ttl", [TTL], [1 byte], 48pt, "⏳", "64"),
  ("proto", [Protocol], [1 byte], 60pt, "🏷️", "6"),
  ("sum", [Checksum], [2 bytes], 60pt, "✅", "0xb1e6"),
  ("src", [Source IP], [4 bytes], 94pt, "📤", "192.168.1.105"),
  ("dst", [Destination IP], [4 bytes], 94pt, "📬", "141.85.220.33"),
  ("data", [Data], [any], 84pt, "📦", none),
)

// #slide[
//   == IPv4 Packet
//   simplified: only the important fields

//   #let steps = (
//     (none, none),
//     (("src", "dst"), explain(
//       [the *IP addresses*: which computer sends, which computer receives],
//       ([📬 *Destination*], [the routers look at it to find the way]),
//       ([📤 *Source*], [the computer that sent it, so the answer comes back]),
//       ([💡], [usually the *same* on the whole way; the MACs change at every router]),
//     )),
//     (("ttl",), explain(
//       [⏳ *TTL*: _time to live_],
//       ([`-1`], [every router subtracts 1; at `0` the packet is *dropped*]),
//       ([🔁], [so a packet does not go around in circles forever (`ping` shows it: `ttl=117`)]),
//     )),
//     (("proto", "data"), explain(
//       [🏷️ *Protocol*: what is inside the packet],
//       ([`6`], [a TCP segment]),
//       ([`17`], [a UDP datagram]),
//       ([`1`], [an ICMP message (`ping`)]),
//     )),
//     (("sum", "data"), explain(
//       [the *check* and the *data*],
//       ([✅ *Checksum*], [of the header only; a damaged packet is dropped]),
//       ([➕], [a few more fields, not shown here: the header has at least 20 bytes]),
//     )),
//   )
//   #for (i, (keys, body)) in steps.enumerate() {
//     only(i + 1)[
//       #frame-drawing(
//         selected: if keys == none { () } else { keys },
//         fields: ip-fields,
//         groups: (("ttl", "dst", [*header*: 20 bytes (simplified)]), ("data", "data", [*data*])),
//         packet: [*Data* \ #text(size: 6.5pt)[TCP, UDP, ICMP, ...]],
//         name-size: 7.5pt,
//         color: layer-colors.network,
//         inner: layer-colors.transport,
//         height: 106pt,
//         extra: if keys != none and "proto" in keys {
//           hint-arrow(96pt, 366pt, [🏷️ a hint: what the data means])
//         },
//       )
//       #if body != none { body }
//     ]
//   }
// ]

// an IPv6 address in 8 groups of 16 bits (4 hexadecimal digits);
// `step` 2 dims the leading zeros, step 3 also marks the run of zero groups
#let ipv6-drawing(step) = drawing(width: 470pt, height: 112pt)[
  #let groups = ("2001", "0db8", "0000", "0000", "0000", "ff00", "0042", "8329")
  #let (x0, gw, gap) = (8pt, 50pt, 8pt)
  #let gx(k) = x0 + k * (gw + gap)
  #let net = layer-colors.network
  #let host = layer-colors.application
  #for (k, g) in groups.enumerate() {
    let c = if k < 4 { net } else { host }
    // the leading zeros (at most 3: one digit always stays)
    let z = calc.min(g.len() - g.trim("0", at: start).len(), 3)
    let digits = if step >= 2 {
      text(fill: luma(185), g.slice(0, z)) + g.slice(z)
    } else { g }
    let zero-run = step >= 3 and k in (2, 3, 4)
    let st = if zero-run { (paint: hl, thickness: 1.6pt, dash: "dashed") } else { 0.8pt + c.stroke }
    at(gx(k), 4pt, box(width: gw, height: 22pt, radius: 2pt, fill: c.fill, stroke: st, align(
      center + horizon,
      text(size: 11pt, font: "DejaVu Sans Mono", weight: "bold", digits),
    )))
    if k > 0 { label(gx(k) - gap / 2, 15pt, text(size: 12pt, weight: "bold", ":")) }
  }
  // the two halves
  #let bracket(x1, x2, color, body) = {
    let yb = 32pt
    wire((x1, yb), (x1, yb + 4pt), stroke: 1.2pt + color)
    wire((x1, yb + 4pt), (x2, yb + 4pt), stroke: 1.2pt + color)
    wire((x2, yb), (x2, yb + 4pt), stroke: 1.2pt + color)
    label((x1 + x2) / 2, yb + 14pt, text(size: 9pt, body))
  }
  #bracket(gx(0), gx(3) + gw, net.stroke, [🛣️ *network*: 64 bits])
  #bracket(gx(4), gx(7) + gw, host.stroke, [🏠 *host*: 64 bits])
  // the shorter ways to write it
  #let short(y, caption, body) = {
    at(x0, y - 6pt, text(size: 9pt, caption))
    pin(285pt, y, text(size: 13pt, font: "DejaVu Sans Mono", weight: "bold", body))
  }
  #if step >= 2 { short(76pt, [✂️ skip the *leading zeros*], [2001:db8:0:0:0:ff00:42:8329]) }
  #if step >= 3 { short(100pt, [🫥 `::` for *one* run of zeros], [2001:db8#text(fill: hl)[::]ff00:42:8329]) }
]

#slide[
  == IPv6
  the next version of IP: 128 bits

  #only(1, ipv6-drawing(1))
  #only(2, ipv6-drawing(2))
  #only("3-", ipv6-drawing(3))

  #set text(size: 9.5pt)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 6pt,
    row-gutter: 6pt,
    fact("📏", [*128 bits*: 8 groups of 16 bits, in *hexadecimal*]),
    fact("🌍", [$2^128 approx 3.4 dot 10^38$ addresses; IPv4 *ran out* in 2011]),
    uncover("5-", fact("🤝", [*dual stack*: next to IPv4, most computers have both])),

    uncover("4-", fact("🔁", [`::1`: this computer (_loopback_), like `127.0.0.1`])),
    uncover("4-", fact("🔗", [`fe80::...`: _link local_, every card has one])),
    uncover("5-", fact("💡", [in this lecture we use *IPv4*])),
  )
  #v(0pt)
]

// ---------------------------------------------------------------------------
// The addresses of the network cards: ip addr
// ---------------------------------------------------------------------------

// the steps of a shell: (lines shown, highlighted parts, explanation)
#let addr-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size)
    #body
  ]
}

// the same laptop as `ip -br link`, now with a cable: the Ethernet card is connected, the Wi-Fi card is not
#let addr-br = (
  "$ ip -br addr    # -br means brief - show one line for each network card",
  (
    ("name", "lo"),
    (none, "               "),
    ("state", "UNKNOWN"),
    (none, "        "),
    ("v4", "127.0.0.1/8"),
    (none, " "),
    ("v6", "::1/128"),
  ),
  (
    ("name", "enp0s31f6"),
    (none, "        "),
    ("state", "UP"),
    (none, "             "),
    ("v4", "192.168.1.105/24"),
    (none, " "),
    ("v6", "2a02:2f0e:d10c::105/128"),
    (none, " "),
    ("v6", "fe80::8e16:45ff:fea2:3b91/64"),
  ),
  (("name", "wlp2s0"), (none, "           "), ("down", "DOWN")),
)

#slide[
  == IP Addresses
  the IP addresses of every card

  #addr-steps(
    addr-br,
    (
      (
        4,
        ("name", "state"),
        explain(
          [`ip addr` (or `ip a`): like `ip link`, plus the *IP addresses*],
          ([`enp0s31f6`], [the name of the card and its state: now with a cable, so it is `UP`, and the Wi-Fi card is `DOWN`]),
        ),
      ),
      (
        4,
        ("v4",),
        explain(
          [the *IPv4* addresses, with the *mask*],
          ([`192.168.1.105/24`], [the address of the Ethernet card, in the network `192.168.1.0/24`]),
          ([`127.0.0.1/8`], [the loopback: this computer]),
        ),
      ),
      (
        4,
        ("v6",),
        explain(
          [the *IPv6* addresses: a card can have *more* of them],
          ([`2a02:...`], [a *global* address, it can be used on the Internet]),
          ([`fe80::...`], [the _link local_ address, every card has one]),
        ),
      ),
      (
        4,
        ("down",),
        explain(
          [`wlp2s0` has *no address*],
          ([`DOWN`], [the Wi-Fi card is not connected to any network: it does not get an address]),
        ),
      ),
    ),
    size: 0.76em,
  )
]

#let addr-show = (
  "$ ip addr show enp0s31f6",
  (
    (none, "2: enp0s31f6: <BROADCAST,MULTICAST,UP,LOWER_UP> "),
    ("mtu", "mtu 1500"),
    (none, " qdisc fq_codel state UP group default qlen 1000"),
  ),
  ((none, "    "), ("mac", "link/ether 8c:16:45:a2:3b:91"), (none, " "), ("brd-mac", "brd ff:ff:ff:ff:ff:ff")),
  (
    (none, "    "),
    ("v4", "inet 192.168.1.105/24"),
    (none, " "),
    ("brd", "brd 192.168.1.255"),
    (none, " "),
    ("scope", "scope global"),
    (none, " "),
    ("dyn", "dynamic"),
    (none, " noprefixroute enp0s31f6"),
  ),
  ((none, "       "), ("lft", "valid_lft 85912sec preferred_lft 85912sec")),
  (
    (none, "    "),
    ("v6", "inet6 2a02:2f0e:d10c::105/128"),
    (none, " "),
    ("scope6", "scope global"),
    (none, " dynamic noprefixroute"),
  ),
  "       valid_lft 86234sec preferred_lft 14234sec",
  (
    (none, "    "),
    ("v6", "inet6 fe80::8e16:45ff:fea2:3b91/64"),
    (none, " "),
    ("scope6", "scope link"),
    (none, " noprefixroute"),
  ),
  "       valid_lft forever preferred_lft forever",
)

#slide[
  == Card Details
  `ip addr show` and the name of the card

  #addr-steps(
    addr-show,
    (
      (
        2,
        ("mtu",),
        explain(
          [the first line is the same as in `ip link`],
          (
            [`mtu 1500`],
            [_Maximum Transmission Unit_: the largest payload of a frame, 1500 bytes for Ethernet and Wi-Fi],
          ),
        ),
      ),
      (
        3,
        ("mac", "brd-mac"),
        explain(
          [the *link layer*],
          ([`link/ether`], [the MAC address of the card]),
          ([`brd`], [the broadcast MAC address: every card in the network]),
        ),
      ),
      (
        4,
        ("v4", "brd", "scope"),
        explain(
          [the *IPv4 address* (`inet`)],
          ([`brd 192.168.1.255`], [the *broadcast* address: the last address of the network, for every computer in it]),
          ([`scope global`], [a normal address, it can be used to talk to other networks]),
        ),
      ),
      (
        5,
        ("dyn", "lft"),
        explain(
          [where the address comes from],
          ([`dynamic`], [received automatically from the router (_DHCP_), for a limited time]),
          ([`valid_lft`], [the address can be used for 85912 more seconds (almost a day), then it is renewed]),
        ),
      ),
      (
        9,
        ("v6", "scope6"),
        explain(
          [the *IPv6 addresses* (`inet6`)],
          ([`scope global`], [can be used on the Internet]),
          ([`scope link`], [only inside this network: the _link local_ `fe80::` address]),
        ),
      ),
    ),
    size: 0.78em,
  )
]

// // the neighbor table of the laptop, with `ip neigh`
// #let neigh-lines = (
//   "$ ip neigh",
//   (
//     ("ip", "192.168.1.1"),
//     (none, " dev enp0s31f6 lladdr "),
//     ("mac", "70:b5:e8:2d:91:4c"),
//     (none, " "),
//     ("ok", "REACHABLE"),
//   ),
//   ((none, "192.168.1.11 dev enp0s31f6 lladdr e4:3b:71:0c:9a:52 "), ("stale", "STALE")),
//   ((none, "192.168.1.12 dev enp0s31f6 "), ("failed", "FAILED")),
//   // the same table with the older command
//   "$ arp -n    # deprecated, from net-tools",
//   "Address          HWtype  HWaddress          Flags Mask  Iface",
//   ((none, "192.168.1.1      ether   70:b5:e8:2d:91:4c  "), ("flag", "C"), (none, "           enp0s31f6")),
//   ((none, "192.168.1.11     ether   e4:3b:71:0c:9a:52  "), ("flag", "C"), (none, "           enp0s31f6")),
//   ((none, "192.168.1.12             "), ("inc", "(incomplete)"), (none, "                   enp0s31f6")),
// )

// #slide[
//   == Neighbors
//   the MAC addresses this computer found

//   #let steps = (
//     (
//       2,
//       ("ip", "mac", "ok"),
//       explain(
//         [`ip neigh`: the *neighbor table* (the _ARP cache_)],
//         ([`192.168.1.1`], [the router of the network has the MAC address `70:b5:e8:2d:91:4c`]),
//         ([`REACHABLE`], [used just now, it answers]),
//       ),
//     ),
//     (
//       3,
//       ("stale",),
//       explain(
//         [`192.168.1.11`, found some time ago],
//         ([`STALE`], [an old entry: the computer asks again for the MAC address the next time it needs it]),
//       ),
//     ),
//     (
//       4,
//       ("failed",),
//       explain(
//         [`192.168.1.12`: nobody answered, there is no such computer],
//         ([`FAILED`], [`ping` shows `Destination Host Unreachable`]),
//       ),
//     ),
//     (
//       4,
//       (),
//       explain(
//         [💡 only computers of *the same network* (`192.168.1.0/24`) are in the table],
//         ([why], [MAC addresses are used only inside a network; the next section shows how packets leave it]),
//       ),
//     ),
//     (
//       9,
//       ("flag", "inc"),
//       explain(
//         [`arp -n`: the *deprecated* command (_net-tools_), the same table],
//         ([`-n`], [show the IP addresses as numbers, do not look up their names]),
//         ([`C`], [_complete_: the MAC address is known]),
//         ([`(incomplete)`], [nobody answered, like `FAILED`]),
//       ),
//     ),
//   )
//   #for (i, (n, keys, body)) in steps.enumerate() {
//     only(i + 1)[
//       #parts-terminal(neigh-lines.slice(0, n), hl: ((keys, ip-peach),), size: if n > 4 { 0.85em } else { 0.95em })
//       #body
//     ]
//   }
// ]
