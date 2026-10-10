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

// the fields of an IPv4 packet, simplified: (key, name, size, width, emoji, example)
#let ip-fields = (
  ("ttl", [TTL], [1 byte], 48pt, "⏳", "64"),
  ("proto", [Protocol], [1 byte], 60pt, "🏷️", "6"),
  ("sum", [Checksum], [2 bytes], 60pt, "✅", "0xb1e6"),
  ("src", [Source IP], [4 bytes], 94pt, "📤", "192.168.1.105"),
  ("dst", [Destination IP], [4 bytes], 94pt, "📬", "141.85.220.33"),
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
      ([💡], [usually the *same* on the whole way; the MACs change at every router]),
    )),
    (("ttl",), explain(
      [⏳ *TTL*: _time to live_],
      ([`-1`], [every router subtracts 1; at `0` the packet is *dropped*]),
      ([🔁], [so a packet does not go around in circles forever (`ping` shows it: `ttl=117`)]),
    )),
    (("proto", "data"), explain(
      [🏷️ *Protocol*: what is inside the packet],
      ([`6`], [a TCP segment]),
      ([`17`], [a UDP datagram]),
      ([`1`], [an ICMP message (`ping`)]),
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
        groups: (("ttl", "dst", [*header*: 20 bytes (simplified)]), ("data", "data", [*data*])),
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

// the steps of a shell: (lines shown, highlighted parts, explanation)
#let test-steps(lines, steps, size: 0.9em) = for (i, (n, keys, body)) in steps.enumerate() {
  only(i + 1)[
    #parts-terminal(lines.slice(0, n), hl: ((keys, ip-peach),), size: size)
    #body
  ]
}

// ---------------------------------------------------------------------------
// ping
// ---------------------------------------------------------------------------

#let ping-ok = (
  "$ ping -c 4 141.85.220.33",
  ((none, "PING "), ("ip", "141.85.220.33"), (none, " (141.85.220.33) 56(84) bytes of data.")),
  ..range(1, 5).map(i => (
    (none, "64 bytes from 141.85.220.33: "),
    ("seq", "icmp_seq=" + str(i)),
    (none, " "),
    ("ttl", "ttl=57"),
    (none, " "),
    ("time", "time=" + ("4.21", "3.98", "4.05", "4.11").at(i - 1) + " ms"),
  )),
  "",
  "--- 141.85.220.33 ping statistics ---",
  ((none, "4 packets transmitted, 4 received, "), ("loss", "0% packet loss"), (none, ", time 3005ms")),
  ((none, "rtt "), ("rtt", "min/avg/max"), (none, "/mdev = "), ("rtt", "3.980/4.087/4.210"), (none, "/0.087 ms")),
)

#slide[
  == ping
  is that computer there? does it answer?

  #test-steps(ping-ok, (
    (2, ("ip",), explain(
      [`ping` sends an ICMP *echo request*, the computer answers with an *echo reply*],
      ([`-c 4`], [only 4 times; without it, `ping` runs until #box[`Ctrl+C`]]),
      ([`141.85.220.33`], [the IP address of the computer we test]),
    )),
    (6, ("seq", "ttl", "time"), explain(
      [one line for every answer],
      ([`icmp_seq`], [the number of the request: a missing number is a *lost* packet]),
      ([`ttl`], [the TTL left in the answer: it started at 64, so it passed 7 routers]),
      ([`time`], [the round trip: there and back]),
    )),
    (10, ("loss", "rtt"), explain(
      [the *statistics*, at the end],
      ([`packet loss`], [`0%` is good; a few lost packets: a bad Wi-Fi or a busy network]),
      ([`min/avg/max`], [the shortest, the average and the longest round trip, in ms]),
    )),
  ), size: 0.82em)
]

// four ways for `ping` to fail, and what each one means
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
    ),
    explain(
      [a computer in *my network*, but nobody answered with a *MAC address*],
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

#slide[
  == When ping Fails
  the error tells where the problem is

  #let bad = (hl: bad-color.lighten(75%), bg: bad-color.lighten(93%), bar: bad-color)
  #for (i, (lines, body)) in ping-fails.enumerate() {
    only(i + 1)[
      #parts-terminal(lines, hl: ((("err",), bad),), size: 0.9em)
      #body
    ]
  }
]

// NAT: the private addresses of a home behind the one public address of the router
#slide[
  == NAT
  many private addresses behind one public address

  #drawing(height: 150pt)[
    #area(5pt, 5pt, 250pt, 140pt, [LAN (private)])
    #wire((50pt, 75pt), (230pt, 75pt))
    #wire((230pt, 75pt), (400pt, 75pt))
    #host(50pt, 75pt, "PC", addr: "192.168.1.105", size: 26pt)
    #netdev(230pt, 75pt, "router", name: "router", sub: "203.0.113.42", size: 28pt, highlight: true)
    #pin(420pt, 75pt, pic("cloud", size: 50pt))
    #only(2)[#frame(140pt, 45pt)[from `192.168.1.105` \ to `141.85.220.33`]]
    #only(3)[#frame(330pt, 45pt)[from #text(fill: bad-color)[`203.0.113.42`] \ to `141.85.220.33`]]
    #only(4)[
      #frame(330pt, 110pt, color: ok-color)[from `141.85.220.33` \ to `203.0.113.42`]
      #frame(140pt, 110pt, color: ok-color)[from `141.85.220.33` \ to #text(fill: bad-color)[`192.168.1.105`]]
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 11pt)[
    #only("1-2")[- the PC sends a packet to `141.85.220.33`, from its private address]
    #only(3)[- the router *replaces* the source with its public address and remembers the connection]
    #only(4)[- the answer comes back to the router, which sends it to the PC: *private addresses are not visible on the Internet*]
  ]))
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
  == ping with IPv6
  the same command, longer addresses

  #test-steps(ping6, (
    (4, ("ip", "ttl"), explain(
      [`ping` works with IPv6 too: it sees an IPv6 address and uses IPv6],
      ([`ttl`], [in IPv6 it is called _hop limit_, the same idea]),
    )),
    (7, ("lo",), explain[`::1`: the loopback, this computer, like `127.0.0.1`]),
    (10, ("zone",), explain(
      [a _link local_ address needs the *card*: every card has an `fe80::` network],
      ([`%wlp2s0`], [send it on the Wi-Fi card]),
    )),
  ), size: 0.85em)
]
