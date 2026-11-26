#import "common.typ": *

#section-cover([Network Layer], [IP addresses], layers: ("network",), note: [IP])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Sections 9.1 - 9.3
      - Section 9.6 - _IPv6 Addresses and Networks_
      - Section 9.7 - _Basic ICMP and DNS Tools_
      - Section 9.22 - _Network Address Translation (IP Masquerading)_
  + #tanenbaum
    - Section 1.4 - _Reference Models_
    - Section 5.6 - _The Network Layer in the Internet_
  + #uso-book
    - Section 11.2.1 - _Internet Protocol (IP)_
    - Section 11.4 - _Adresarea IP. Stiva TCP/IP_
]

// ---------------------------------------------------------------------------
// IPv4
// ---------------------------------------------------------------------------

// the bits of an address written with dots, as a string of 32 `0` / `1`
#let addr-bits(addr) = addr.split(".").map(b => {
  let v = int(b)
  range(7, -1, step: -1).map(i => str(calc.rem(calc.quo(v, calc.pow(2, i)), 2))).join()
}).join()

// a string of 32 bits, written back as an address with dots
#let bits-addr(bits) = range(4).map(k => {
  let byte = bits.slice(k * 8, k * 8 + 8)
  str(byte.clusters().fold(0, (acc, b) => acc * 2 + int(b)))
}).join(".")

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
          align(center + horizon, text(size: 7.5pt, font: "DejaVu Sans Mono", fill: if dim { luma(170) } else { black }, b)),
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
      #text(size: 9pt)[#text(fill: layer-colors.network.stroke.darken(20%), weight: "bold")[24 bits of `1`]: the *network*,
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

#slide[
  == Special Addresses
  addresses with a special meaning

  #v(0.6em)
  #align(center, text(size: 11pt, table(
    columns: (auto, auto, 1fr),
    inset: 6pt,
    align: (center + horizon, left + horizon, left + horizon),
    stroke: 0.6pt + luma(170),
    table.header([], [*Address*], [*Meaning*]),
    text(size: 1.4em, "🔁"), [`127.0.0.0/8` \ (usually `127.0.0.1`)], [*loopback* (`localhost`): this computer, the packets never leave it],
    text(size: 1.4em, "🔒"), [`10.0.0.0/8` \ `172.16.0.0/12` \ `192.168.0.0/16`], [*private* networks: free for everyone at home or at work, *not routed* on the Internet],
    text(size: 1.4em, "🤷"), [`169.254.0.0/16`], [_link local_: no one gave us an address, so the computer picked one by itself],
    text(size: 1.4em, "🌐"), [`0.0.0.0`], [_any address_ of this computer: a server that waits on all its addresses, or a computer that has no address yet],
  )))
]

// `ip -br address` on the laptop: the addresses of every card
#let ip-addr = (
  "$ ip -br address",
  ((none, "lo               UNKNOWN        "), ("lo", "127.0.0.1/8"), (none, " ::1/128")),
  ((none, "enp0s31f6        "), ("down", "DOWN"), (none, "           ")),
  ((none, "wlp2s0           UP             "), ("ip4", "192.168.1.105"), ("mask", "/24"), (none, " "), ("v6", "fe80::8d2c:41a7:3b6e:f019/64")),
)

#slide[
  == Addresses in Linux
  the address and the mask of every card

  #parts-terminal(ip-addr, hl: ((("ip4", "mask", "lo", "down", "v6"), ip-peach),), size: 0.85em)
  #explain(
    [`ip -br address`: the IP addresses of every card (`-br`: _brief_, one line for each card)],
    ([`192.168.1.105`], [the IPv4 address of the Wi-Fi card `wlp2s0`]),
    ([`/24`], [the mask, as a prefix: the network is `192.168.1.0/24`]),
    ([`127.0.0.1/8`], [`lo`: the loopback, the computer itself]),
    ([`DOWN`], [`enp0s31f6` has no cable: no address]),
    ([`fe80::...`], [an *IPv6* address, later in this section]),
  )
]

// the fields of an IPv4 packet, simplified: (key, name, size, width, emoji, example)
#let ip-fields = (
  ("ttl", [TTL], [1 byte], 48pt, "⏳", "64"),
  ("proto", [Protocol], [1 byte], 60pt, "🏷️", "6"),
  ("sum", [Checksum], [2 bytes], 60pt, "✅", "0xb1e6"),
  ("src", [Source IP], [4 bytes], 94pt, "📤", "192.168.1.105"),
  ("dst", [Destination IP], [4 bytes], 94pt, "📬", "141.85.228.17"),
  ("data", [Data], [any], 84pt, "📦", none),
)

#slide[
  == IPv4 Packet
  simplified: only the important fields

  #let steps = (
    (none, none),
    (("src", "dst"), explain(
      [the *IP addresses*: which computer sends, which computer receives],
      ([📬 *Destination*], [the routers look at it to find the way]),
      ([📤 *Source*], [the computer that sent it, so the answer comes back]),
      ([💡], [the *same* along the whole way (except through NAT, later); the MACs change at every router]),
    )),
    (("ttl",), explain(
      [⏳ *TTL*: _time to live_],
      ([`-1`], [every router subtracts 1; at `0` the packet is *dropped*]),
      ([🔁], [so a packet does not go around in circles forever (`ping` shows it: `ttl=60`)]),
    )),
    (("proto", "data"), explain(
      [🏷️ *Protocol*: what is inside the packet],
      ([`6`], [a TCP segment]),
      ([`17`], [a UDP datagram]),
      ([`1`], [an *ICMP* message: small control and error messages (`ping`, _"time exceeded"_)]),
    )),
    (("sum", "data"), explain(
      [the *check* and the *data*],
      ([✅ *Checksum*], [of the header only; a damaged packet is dropped]),
      ([➕], [a few more fields, not shown here: the header has at least 20 bytes]),
    )),
  )
  #for (i, (keys, body)) in steps.enumerate() {
    only(i + 1)[
      #frame-drawing(
        selected: if keys == none { () } else { keys },
        fields: ip-fields,
        groups: (("ttl", "dst", [*header*: 20 bytes, only some fields shown]), ("data", "data", [*data*])),
        packet: [*TCP segment* \ #text(size: 6.5pt)[from the Transport layer]],
        name-size: 7.5pt,
        color: layer-colors.network,
        inner: layer-colors.transport,
        height: 106pt,
        extra: if keys != none and "proto" in keys {
          hint-arrow(96pt, 366pt, [🏷️ a hint: what the data means])
        },
      )
      #if body != none { body }
    ]
  }
]

// ---------------------------------------------------------------------------
// Testing the connection: ping
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// ping
// ---------------------------------------------------------------------------

#let ping-ok = (
  "$ ping -c 4 141.85.228.17",
  ((none, "PING "), ("ip", "141.85.228.17"), (none, " (141.85.228.17) 56(84) bytes of data.")),
  ..range(1, 5).map(i => (
    (none, "64 bytes from 141.85.228.17: "),
    ("seq", "icmp_seq=" + str(i)),
    (none, " "),
    ("ttl", "ttl=60"),
    (none, " "),
    ("time", "time=" + ("4.21", "3.98", "4.05", "4.11").at(i - 1) + " ms"),
  )),
  "",
  "--- 141.85.228.17 ping statistics ---",
  ((none, "4 packets transmitted, 4 received, "), ("loss", "0% packet loss"), (none, ", time 3005ms")),
  ((none, "rtt "), ("rtt", "min/avg/max"), (none, "/mdev = "), ("rtt", "3.980/4.087/4.210"), (none, "/0.084 ms")),
)

#slide[
  == `ping`
  is that computer there? does it answer?

  #term-steps(ping-ok, (
    (2, ("ip",), explain(
      [`ping` sends an ICMP *echo request*, the computer answers with an *echo reply*],
      ([`-c 4`], [only 4 times; without it, `ping` runs until #kbd("Ctrl") + #kbd("C")]),
      ([`141.85.228.17`], [the IP address of the computer we test]),
    )),
    (6, ("seq", "ttl", "time"), explain(
      [one line for every answer],
      ([`icmp_seq`], [the number of the request: a missing number is a *lost* packet]),
      ([`ttl`], [the TTL left in the answer: if it started at 64 (Linux), it passed through 4 routers]),
      ([`time`], [the round trip: there and back]),
    )),
    (10, ("loss", "rtt"), explain(
      [the *statistics*, at the end],
      ([`packet loss`], [`0%` is good; a few lost packets: bad Wi-Fi or a busy network]),
      ([`min/avg/max`], [the shortest, the average and the longest round trip, in ms]),
    )),
  ), summary: (("ip", "loss"), explain(
    [💡 an answer means the whole way works, *there and back*],
    ([ICMP], [part of the *network layer*: the *kernel* answers, no program and no port are needed]),
    ([`0% packet loss`], [the computer is on, and the cards, the cables or the Wi-Fi and the routers on the way work]),
  )), size: 0.82em)
]

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
  #if step >= 3 { short(100pt, [🫥 `::` for *one* run of zeros (only once)], [2001:db8#text(fill: hl)[::]ff00:42:8329]) }
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
    uncover("4-", fact("🔁", [`::1`: this computer (_loopback_), like `127.0.0.1`])),
    uncover("4-", fact("🔗", [`fe80::...`: _link local_, every card with IPv6 has one])),
    uncover("5-", fact("🤝", [*dual stack*: next to IPv4, most computers have both])),
    uncover("5-", fact("💡", [in this lecture we use *IPv4*])),
  )
  #v(0pt)
]

#let ping6 = (
  "$ ping -c 2 2a00:1450:4017:80e::200e",
  ((none, "PING "), ("ip", "2a00:1450:4017:80e::200e"), (none, " (2a00:1450:4017:80e::200e) 56 data bytes")),
  ((none, "64 bytes from 2a00:1450:4017:80e::200e: icmp_seq=1 "), ("ttl", "ttl=117"), (none, " time=12.4 ms")),
  ((none, "64 bytes from 2a00:1450:4017:80e::200e: icmp_seq=2 "), ("ttl", "ttl=117"), (none, " time=12.1 ms")),
  "$ ping -c 1 ::1",
  ((none, "PING "), ("lo", "::1"), (none, " (::1) 56 data bytes")),
  "64 bytes from ::1: icmp_seq=1 ttl=64 time=0.041 ms",
  "$ ping -c 1 fe80::1%wlp2s0",
  ((none, "PING fe80::1"), ("zone", "%wlp2s0"), (none, " (fe80::1%wlp2s0) 56 data bytes")),
  "64 bytes from fe80::1%wlp2s0: icmp_seq=1 ttl=64 time=2.31 ms",
)

#slide[
  == `ping` with IPv6
  the same command, longer addresses

  #term-steps(ping6, (
    (4, ("ip", "ttl"), explain(
      [`ping` works with IPv6 too: it sees an IPv6 address and uses IPv6],
      ([`ttl`], [in IPv6 it is called _hop limit_, the same idea]),
    )),
    (7, ("lo",), explain[`::1`: the loopback, this computer, like `127.0.0.1`]),
    (10, ("zone",), explain(
      [a _link local_ address needs the *card*: every card has an `fe80::` network],
      ([`%wlp2s0`], [send it on the Wi-Fi card]),
    )),
  ), summary: (("ip", "ttl", "lo", "zone"), explain(
    [💡 `ping` with IPv6: the same output, other addresses],
    ([`ttl`], [called _hop limit_ in IPv6]),
    ([`::1` `%wlp2s0`], [the loopback; the card, for a link local address]),
  )), size: 0.85em)
]

// ---------------------------------------------------------------------------
// Sending a packet: down through the layers
// ---------------------------------------------------------------------------

// the packet goes down: the network layer has no wire of its own, it gives
// the packet to the link layer, which puts it in a frame, which the card
// sends as bits
#slide[
  == Encapsulation
  a packet cannot travel alone: it goes in a frame

  #let net = layer-colors.network
  #let link = layer-colors.link
  #let phy = layer-colors.physical
  // the rows: network, data link, physical
  #let (y1, y2, y3, rh) = (8pt, 72pt, 136pt, 44pt)
  // the packet, the same size in both rows: it sits in the payload of the frame
  #let (px, pw, hw) = (214pt, 220pt, 124pt)
  // the destination and the source of a header, one per line
  #let to-from(to, from) = grid(
    columns: (auto, auto),
    column-gutter: 3pt,
    row-gutter: 2.5pt,
    align: left + horizon,
    [📬 *to*], to,
    [📤 *from*], from,
  )
  #let who(ip, name) = [#mono(ip, size: 6.5pt) #text(size: 6.5pt, fill: luma(90))[#name]]
  #let ip-header = box(width: hw, height: rh - 8pt, fill: net.fill, stroke: (right: 0.8pt + net.stroke), inset: (x: 4pt), align(left + horizon, text(size: 7pt)[
    *IP header* #v(-3pt)
    #to-from(who(bogdan.at(0), [Bogdan]), who(ana.at(0), [Ana]))
  ]))
  // the MAC address Ana does not know: a red empty field
  #let missing = box(width: 70pt, fill: bad-color.lighten(85%), stroke: 1.2pt + bad-color, radius: 2pt, inset: (x: 3pt, y: 1.5pt), outset: (y: 0.5pt), align(center, text(size: 7pt, fill: bad-color, weight: "bold")[??? missing]))
  #let packet = box(width: pw, height: rh - 8pt, radius: 3pt, fill: net.fill, stroke: 1pt + net.stroke, clip: true, stack(
    dir: ltr,
    ip-header,
    box(width: pw - hw, height: rh - 8pt, fill: white, align(center + horizon, text(size: 7pt)[📄 *data* \ #text(fill: luma(100))[from Transport]])),
  ))
  // a layer box on the left, highlighted when it works
  #let layer-box(y, c, name, num, on) = at(0pt, y, box(
    width: 82pt,
    height: rh,
    radius: 4pt,
    fill: if on { c.fill } else { luma(248) },
    stroke: if on { 1.5pt + c.stroke } else { 0.6pt + luma(210) },
    align(center + horizon, text(size: 8pt, fill: if on { black } else { luma(150) })[*#name* \ layer #num]),
  ))
  // an arrow down, between two rows
  #let down(x, y) = draw-arrow((x, y), (x, y + 18pt), color: hl, thickness: 2pt, head: 6pt)

  #align(center, scale(94%, reflow: true, drawing(height: 182pt)[
    #layer-box(y1, net, [Network], 3, true)
    #uncover("2-")[#layer-box(y2, link, [Data Link], 2, true)]
    #uncover("3-")[#layer-box(y3, phy, [Physical], 1, true)]
    #only(1)[#layer-box(y2, link, [Data Link], 2, false)]
    #only("1-2")[#layer-box(y3, phy, [Physical], 1, false)]

    // 1: the packet, at the network layer
    #at(px, y1 + 4pt, packet)
    #pin(455pt, y1 + rh / 2, text(size: 8pt, weight: "bold", fill: net.stroke)[packet])

    // 2: no wire up here: down to the link layer
    #uncover("2-")[
      #down(41pt, y1 + rh + 1pt)
      #draw-arrow((px + pw / 2, y1 + rh), (px + pw / 2, y2 + 2pt), color: hl, thickness: 1.5pt, head: 5pt, dash: "dashed")
    ]
    // 3: the frame around the packet
    #uncover("3-")[
      #at(98pt, y2, box(width: 374pt, height: rh, radius: 5pt, fill: link.fill, stroke: 1pt + link.stroke))
      #at(102pt, y2 + 4pt, box(width: 110pt, height: rh - 8pt, align(left + horizon, text(size: 7pt)[
        *Ethernet header* #v(-3pt)
        #to-from(missing, mono(ana.at(1), size: 6.5pt))
      ])))
      #at(px, y2 + 4pt, packet)
      #at(px + pw + 4pt, y2 + 4pt, box(width: 30pt, height: rh - 8pt, align(center + horizon, text(size: 7pt)[*FCS* \ ✅])))
      #pin(452pt, y2 - 7pt, text(size: 8pt, weight: "bold", fill: link.stroke)[frame])
    ]
    #uncover("2-")[#only(2)[#at(px, y2 + 4pt, box(width: pw, height: rh - 8pt, radius: 3pt, stroke: (paint: net.stroke, dash: "dashed"), align(center + horizon, text(size: 7.5pt, fill: luma(110))[the same packet, given to the card])))]]

    // 3 (with the frame): the card sends it as bits
    #uncover("3-")[
      #down(41pt, y2 + rh + 1pt)
      #draw-arrow((285pt, y2 + rh), (285pt, y3 + 2pt), color: hl, thickness: 1.5pt, head: 5pt, dash: "dashed")
      #at(98pt, y3 + 6pt, box(width: 374pt, height: rh - 12pt, radius: 4pt, fill: phy.fill, stroke: 1pt + phy.stroke, align(center + horizon, text(size: 8pt)[
        #mono(size: 7.5pt)[10110010 01001110 00011111 01101001 11010010 …] #h(6pt) 🔌 cable · 📶 radio
      ])))
    ]

    // the popup: the destination MAC address is missing
    #only("3-")[
      #let (bx, by, bw) = (98pt, 4pt, 112pt)
      #at(bx + 2.5pt, by + 2.5pt, box(width: bw, height: 50pt, radius: 4pt, fill: luma(0).transparentize(80%)))
      #at(bx, by, box(width: bw, height: 50pt, radius: 4pt, fill: white, stroke: 1.5pt + bad-color, inset: 5pt, align(left + horizon, text(size: 7.5pt)[
        ❓ *to which card?* \
        Ana knows Bogdan's *IP* `192.168.1.11`, but *not his MAC*
      ])))
      #draw-arrow((170pt, by + 50pt), (170pt, y2 + 15pt), color: bad-color, thickness: 1.5pt, head: 5pt)
    ]
  ]))

  #place(bottom + left, block(width: 100%, text(size: 10pt)[
    #only(1, fact("📦", [the *network layer* builds the *packet*: the IP header (who sends, who receives) and the data]))
    #only(2, fact("⬇️", [the network layer has *no wire*: it gives the packet to the layer below, the *network card*]))
    #only("3-", fact("✉️", [the *link layer* puts the packet in a *frame* (the card only knows *MAC addresses*); the *physical layer* sends it as *bits*]))
  ]))
]
