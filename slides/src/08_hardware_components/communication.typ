#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Communication #text(size: 10pt, weight: "regular")[\ _How the parts talk to each other and to the world_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 3 - _Devices_
      - Section 3.6 - _In-Depth: SCSI and the Linux Kernel_ (USB storage)
  + #uso-book
    - Chapter 8 - _Componente hardware_
  + #patterson
    - Chapter 1 - _Computer Abstractions and Technology_
]

// ---------------------------------------------------------------------------
// The map of the links in a PC
// ---------------------------------------------------------------------------

// the parts of a PC and the links between them; `on` lists the kinds of
// links drawn orange: "mem", "pcie", "usb", "sata", "screen", "net"
#let link-map(on: ()) = drawing(width: 460pt, height: 160pt, {
  let part(x, y, kind, body, w: 80pt, h: 28pt) = at(x, y, unit(
    kind: "slot",
    width: w,
    height: h,
    on: kind in on,
    size: 0.6em,
    body,
  ))
  // a link with its name above the middle
  let ln(a, b, kind, name, dx: 0pt, dy: -6pt) = {
    link-line(a, b, on: kind in on, thick: true)
    let (x1, y1) = a
    let (x2, y2) = b
    pin((x1 + x2) / 2 + dx, (y1 + y2) / 2 + dy, box(
      fill: white,
      inset: 1pt,
      text(size: 0.5em, weight: "bold", fill: if kind in on { changed } else { luma(90) }, name),
    ))
  }
  // the box of the computer
  at(-4pt, -4pt, box(width: 362pt, height: 168pt, radius: 0.5em, stroke: (paint: luma(180), thickness: 0.8pt, dash: "dashed")))
  at(366pt, 70pt, note[outside])
  at(140pt, 0pt, unit(kind: "dark", width: 90pt, height: 74pt, size: 0.65em, icon: cpu-icon, sub: [with the northbridge])[CPU])
  at(140pt, 108pt, unit(width: 90pt, height: 30pt, size: 0.65em)[chipset])
  part(0pt, 0pt, "mem")[🧮 RAM]
  part(0pt, 46pt, "pcie")[💾 NVMe SSD]
  part(0pt, 100pt, "usb")[🔌 USB ports]
  part(0pt, 132pt, "sata")[💾 SATA disk]
  part(275pt, 0pt, "pcie", w: 75pt)[🎮 GPU]
  part(275pt, 108pt, "net", w: 75pt)[📶 network card]
  part(395pt, 0pt, "screen", w: 65pt)[🖥️ monitor]
  part(395pt, 108pt, "net", w: 65pt)[🌐 router]
  ln((80pt, 14pt), (140pt, 14pt), "mem", [DDR5])
  ln((80pt, 60pt), (140pt, 60pt), "pcie", [PCIe x4])
  ln((230pt, 14pt), (275pt, 14pt), "pcie", [PCIe x16])
  ln((185pt, 74pt), (185pt, 108pt), "pcie", [DMI / PCIe], dx: 26pt, dy: 0pt)
  ln((230pt, 122pt), (275pt, 122pt), "pcie", [PCIe x1])
  ln((80pt, 114pt), (140pt, 114pt), "usb", [USB])
  link-line((140pt, 132pt), (110pt, 132pt), on: "sata" in on, thick: true)
  ln((110pt, 146pt), (80pt, 146pt), "sata", [SATA])
  link-line((110pt, 132pt), (110pt, 147pt), on: "sata" in on, thick: true)
  ln((350pt, 14pt), (395pt, 14pt), "screen", [HDMI / DP])
  ln((350pt, 122pt), (395pt, 122pt), "net", [Ethernet, Wi-Fi])
})

#slide[
  == The Links in a PC
  Every arrow on the board is a _link_ with its own name, speed and rules

  #only(1, link-map())
  #only(2, link-map(on: ("mem", "pcie")))
  #only(3, link-map(on: ("usb", "sata")))
  #only("4-", link-map(on: ("screen", "net")))

  #v(0.2em)
  #only(1)[💡 a _link_ (or _bus_) = wires + the rules to send data over them (the _protocol_)]
  #only(2)[💡 the fast links, inside the box: RAM (DDR5) and *PCIe* for the GPU, the SSD and the chipset]
  #only(3)[💡 the slower links, behind the chipset: *USB* for devices you plug in, *SATA* for older disks]
  #only("4-")[💡 links that leave the box: *HDMI* or *DisplayPort* to the screen, *Ethernet* or *Wi-Fi* to the network]
]

// ---------------------------------------------------------------------------
// Parallel and serial
// ---------------------------------------------------------------------------

// bits on a wire: small squares, 1 filled, 0 empty
#let bits(s, color: accent, size: 5pt) = (
  s
    .clusters()
    .map(b => box(width: size, height: size, radius: 1pt, fill: if b == "1" { color } else { white }, stroke: 0.5pt + color))
    .join(h(1.5pt))
)

// a parallel bus (8 wires, one bit each) or a serial link (bits one after
// the other, a pair of wires each way)
// `lanes`: 1 for one serial lane, 4 for an x4 link (4 lanes side by side)
#let link-drawing(parallel, on: false, lanes: 1) = drawing(width: 230pt, height: 78pt, {
  at(0pt, 14pt, unit(kind: "dark", width: 36pt, height: 56pt, size: 0.7em)[A])
  at(194pt, 14pt, unit(kind: "dark", width: 36pt, height: 56pt, size: 0.7em)[B])
  if parallel {
    // the bits of one byte, each on its own wire; one arrives late (skew)
    let byte = "10110010"
    for (i, b) in byte.clusters().enumerate() {
      wire((36pt, 18pt + i * 6.5pt), (194pt, 18pt + i * 6.5pt), stroke: 0.8pt + luma(150))
      at((if i == 5 { 80pt } else { 110pt }), 15.5pt + i * 6.5pt, bits(b, color: if i == 5 { bad-color } else { accent }))
    }
    pin(115pt, 6pt, note[*parallel*: 8 wires, a whole byte at a time])
    pin(85pt, 75pt, note(color: bad-color)[late bit])
  } else if lanes > 1 {
    // an x4 link: 4 lanes, each a pair of wires each way, each with its own bits
    let c = if on { changed } else { accent }
    let streams = ("0110100111010010", "1011001110100101", "1100101001101101", "0011011010011010")
    for i in range(lanes) {
      let y = 20pt + i * 13pt
      line-arrow((36pt, y), (194pt, y), color: c, thickness: 1pt, head: 4pt)
      line-arrow((194pt, y + 5pt), (36pt, y + 5pt), color: c.lighten(40%), thickness: 0.6pt, head: 3pt)
      at(46pt, y - 6pt, bits(streams.at(i), color: c, size: 4pt))
    }
    pin(115pt, 6pt, note[*x4*: 4 lanes side by side, 4× the speed])
  } else {
    let c = if on { changed } else { accent }
    line-arrow((36pt, 32pt), (194pt, 32pt), color: c, thickness: 1.2pt)
    line-arrow((194pt, 54pt), (36pt, 54pt), color: c, thickness: 1.2pt)
    at(50pt, 22pt, bits("0110100111010010", color: c))
    at(70pt, 57pt, bits("1101001011", color: c))
    pin(115pt, 6pt, note[*serial*: one _lane_ = a pair of wires each way])
  }
})

// a timing diagram of a parallel bus: 4 wires, the bytes A, B, C, ... sent
// one per clock tick; wire 2 is longer, its bits arrive `late` later. The
// receiver reads all the wires in the middle of each tick (dashed line): a
// read that still sees the previous byte on the late wire is red.
// e.g. #skew-diagram(80pt, [slow clock]) / #skew-diagram(20pt, [fast clock])
#let skew-diagram(tick, title, late: 12pt, width: 226pt, on: true) = {
  let rows = 4
  let rh = 11pt
  let lw = 46pt // the labels on the left
  let n = calc.ceil(width / tick) + 1
  let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".clusters()
  let letter(k) = if k < 0 { "·" } else { letters.at(k) }
  let fills = (accent.lighten(65%), ok-color.lighten(70%))
  box(width: lw + width, height: 24pt + rows * rh, {
    at(0pt, 0pt, text(size: 0.7em, weight: "bold", title))
    for i in range(rows) {
      let y = 14pt + i * rh
      let d = if i == 2 { late } else { 0pt }
      at(0pt, y + 1pt, text(size: 0.6em, fill: if i == 2 { bad-color } else { luma(80) })[#if i == 2 [bit #i, late] else [bit #i]])
      at(lw, y, box(width: width, height: rh - 2pt, clip: true, {
        for k in range(-1, n) {
          place(top + left, dx: k * tick + d, box(
            width: tick - 1pt,
            height: rh - 2pt,
            fill: fills.at(calc.rem(k + 2, 2)),
            pad(left: 2pt, align(left + horizon, text(size: 0.5em, letter(k)))),
          ))
        }
      }))
    }
    // the reads, in the middle of each tick
    at(lw + tick / 2 - 3pt, 17pt + rows * rh, box(fill: white, inset: (x: 1pt), text(size: 0.55em, style: "italic", fill: luma(60))[dashed: sampling time, the receiver reads here]))
    for k in range(n) {
      let x = lw + k * tick + tick / 2
      if x < lw + width {
        wire((x, 12pt), (x, 16pt + rows * rh), stroke: (paint: luma(60), thickness: 0.6pt, dash: "dashed"))
        let bad = tick / 2 < late
        if on and bad {
          at(x - 3pt, 14pt + 2 * rh + 1.5pt, circle(radius: 3pt, fill: none, stroke: 1.2pt + bad-color))
        }
      }
    }
  })
}

#slide[
  == Parallel and Serial
  Why today's links send one bit after the other

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - *parallel* (old): 8, 16, 32 wires side by side, one bit each
      - PCI, PATA (IDE), the printer port
    #uncover("2-")[#block[
      - ⚠️ faster clock = the bits of one byte no longer arrive *together*
    ]]
    #uncover("5-")[#block[
      - *serial* (today): one bit after the other, billions per second
        - PCIe, SATA, USB, Ethernet, HDMI
        #uncover("6-")[#block[- need more speed? add more *lanes*: x1, x4, x16]]
    ]]
  ][
    #link-drawing(true)
    #only(5, link-drawing(false, on: true))
    #only("6-", link-drawing(false, on: true, lanes: 4))
  ]

  #v(0.2em)
  #only(1)[💡 more wires sounds faster: a whole byte in one clock tick]
  #only(2)[💡 why? a tiny difference in wire length is enough, see the next step]
  #only(5)[💡 a serial lane can tick much faster: it carries its own timing, the receiver lines the lanes up]

  #only("3-4", place(center + horizon, popup(width: 330pt, kind: "info")[The late bit][
    #set text(size: 0.9em)
    the wires are never exactly the same: on a longer one the bit arrives *late*
    #v(0.3em)
    #skew-diagram(80pt, [✅ slow clock: every read sees one byte])
    #v(0.3em)
    #uncover(4, skew-diagram(20pt, [❌ 4× faster: the read comes first, bit 2 still holds the previous byte]))
    #uncover(4, block(above: 0.4em)[💡 at PCIe 4.0 speed a bit lasts 0.06 ns: 1 cm of extra wire is already a whole bit late])
  ]))
  #only("6-")[💡 PCIe x4 = 4 lanes; the bytes are spread over the lanes, each lane keeps its own timing]
]

// ---------------------------------------------------------------------------
// How fast is a link?
// ---------------------------------------------------------------------------

// the speeds on the slide, computed so the slide cannot lie:
// GB/s of each link, and the seconds a 1 GB file needs on it
#let pcie4-x4 = 4 * 2 // 4 lanes of ~2 GB/s
#assert.eq(pcie4-x4, 8)
#let usb10 = 10 / 8 // 10 Gb/s in GB/s
#assert.eq(usb10, 1.25)
#let usb20 = 2 * 10 / 8 // 2 lanes of 10 Gb/s
#assert.eq(usb20, 2.5)
#let gbe = 1 / 8 // 1 Gb/s in GB/s
#assert.eq(gbe, 0.125)
#let secs(gbs) = 1 / gbs // a 1 GB file
#assert.eq((secs(pcie4-x4), secs(usb10), secs(usb20), secs(gbe)), (0.125, 0.8, 0.4, 8.0))
#let speed(x) = text(weight: "bold", str(x))

#slide[
  == Link Speed
  Count the lanes, then mind the bits and the bytes

  #set text(size: 0.85em)
  #align(center, callout[
    speed of the link = *number of lanes* × speed of one lane \
    #text(size: 0.85em)[_bits_ per second: *Gb/s* (Gbps) #h(1em) _bytes_ per second: *GB/s* #h(1em) 1 byte = 8 bits]
  ])

  #v(0.3em)
  #nice-table(
    columns: (auto, auto, auto, auto, 1fr),
    size: 0.85em,
    header: ([link], [the box says], [lanes × one lane], [in bytes], [a 1 GB file]),
    rows: (
      ([💾 *NVMe SSD*], [PCIe 4.0 `x4`], [4 × \~2 GB/s], [*\~#pcie4-x4 GB/s*], [#bar(secs(pcie4-x4), 8, width: 70pt, label: [#secs(pcie4-x4) s])]),
      ([🔌 *USB 3.2 Gen 2*], [10 Gbps], [1 × 10 Gb/s], [10 / 8 = *#usb10 GB/s*], [#bar(secs(usb10), 8, width: 70pt, label: [#secs(usb10) s])]),
      ([🔌 *USB 3.2 Gen 2x2*], [20 Gbps], [*2* × 10 Gb/s], [20 / 8 = *#usb20 GB/s*], [#bar(secs(usb20), 8, width: 70pt, label: [#secs(usb20) s])]),
      ([🌐 *Ethernet*], [1 Gbps, "gigabit"], [1 × 1 Gb/s], [1 / 8 = *#gbe GB/s* = 125 MB/s], [#bar(secs(gbe), 8, width: 70pt, on: true, label: [*#secs(gbe) s*])]),
    ),
    shown: (2, 3, 3, 4),
  )

  #v(0.2em)
  #only(1)[💡 storage counts in *bytes*, cables and networks in *bits*: always check the letter b or B]
  #only(2)[💡 PCIe gives the speed of one lane in bytes: multiply by the lanes]
  #only(3)[💡 USB is sold in bits: divide by 8; "2x2" means *2 lanes* of 10 Gb/s]
  #only("4-")[💡 "gigabit" Ethernet moves only 125 MB/s: a 1 GB file needs 8 s]

  #only("5-", place(bottom + center, dy: -0.2em, info(width: 380pt)[Real transfers are a bit slower][
    each link also sends its own control data (encoding, headers), so less is left for your data
  ]))
]

// PCIe per-lane speed in GB/s, rounded, per direction: (generation, year, GB/s)
#let pcie = (("3.0", 2010, 1), ("4.0", 2017, 2), ("5.0", 2019, 4), ("6.0", 2022, 8), ("7.0", 2025, 16))

// what "x1", "x4", "x16" mean: the device and the CPU joined by 1, 4 or 16
// lanes, each lane drawn as one line (a pair of wires each way)
#let lane-links = grid(
  columns: (auto, auto, auto),
  column-gutter: 0.5em,
  row-gutter: 0.6em,
  align: left + horizon,
  ..((1, "📶", [Wi-Fi]), (4, "💾", [SSD]), (16, "🎮", [GPU]))
    .map(((n, icon, what)) => (
      text(size: 1.1em, weight: "bold", fill: changed.darken(15%), raw("x" + str(n))),
      box(width: 92pt, height: n * 2.6pt + 4pt, {
        place(top + left, box(width: 22pt, height: 100%, radius: 2pt, fill: accent.lighten(55%), align(center + horizon, text(size: 0.8em, icon))))
        place(top + right, box(width: 22pt, height: 100%, radius: 2pt, fill: accent, align(center + horizon, text(size: 0.55em, fill: white)[CPU])))
        for i in range(n) {
          place(top + left, dx: 22pt, dy: 2pt + i * 2.6pt + 0.6pt, line(length: 48pt, stroke: 1.2pt + changed))
        }
      }),
      text(size: 0.85em)[*#n* #if n == 1 [lane] else [lanes]: #what],
    ))
    .flatten(),
)

// the PCIe tree: the root complex in the CPU, its own links to the GPU,
// an SSD and the chipset, and the chipset (a switch) fanning out to more
// devices. Lines as thick as their lanes.
// `step` 1: the links of the CPU, 2: the switch and its links, 3: all
#let pcie-tree(step) = drawing(width: 282pt, height: 170pt, {
  let a = step == 1
  let b = step == 2
  let ink(on) = if on { changed } else { luma(150) }
  // a link drawn as its lanes: `n` vertical lines centered on x, from y0 to y1
  let lanes(x, y0, y1, n, on) = {
    let gap = 2.6pt
    let x0 = x - (n - 1) * gap / 2
    for i in range(n) { wire((x0 + i * gap, y0), (x0 + i * gap, y1), stroke: 1.1pt + ink(on)) }
    at(x + (n - 1) * gap / 2 + 4pt, (y0 + y1) / 2 - 5pt, text(size: 0.6em, weight: "bold", fill: if on { changed.darken(15%) } else { luma(100) }, raw("x" + str(n))))
  }
  let dev(x, y, w, body, on, sub: none) = at(x, y, unit(kind: "slot", width: w, height: 32pt, on: on, size: 0.68em, sub: sub, body))
  // the CPU, with the root complex where the links start
  at(0pt, 0pt, unit(kind: "dark", width: 282pt, height: 34pt, size: 0.75em, sub: [the *root complex* starts the links])[#cpu-icon CPU])
  // the links of the CPU, each one only for its device
  lanes(33pt, 34pt, 72pt, 16, a)
  lanes(108pt, 34pt, 72pt, 4, a)
  lanes(214pt, 34pt, 72pt, 4, a or b)
  dev(0pt, 72pt, 70pt, [🎮 GPU], a)
  dev(80pt, 72pt, 58pt, [💾 SSD], a)
  at(148pt, 72pt, unit(width: 134pt, height: 32pt, on: b, size: 0.68em, sub: [a PCIe *switch*])[chipset])
  // behind the switch
  lanes(167pt, 104pt, 136pt, 1, b)
  lanes(214pt, 104pt, 136pt, 1, b)
  lanes(258pt, 104pt, 136pt, 4, b)
  dev(148pt, 136pt, 40pt, [📶 Wi-Fi], b)
  dev(194pt, 136pt, 40pt, [🌐 LAN], b)
  dev(240pt, 136pt, 42pt, [💾 SSD 2], b)
})

#slide[
  == PCIe
  _PCI Express_: the main road inside a computer 🛣️

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - *point-to-point*: each device has *its own* link, nothing to share
    - the *root complex* in the CPU starts the links
    #uncover("2-")[#block[- a *switch* turns one link into many: the chipset is one]]
    #uncover("3-")[#block[- together: a *tree*, with the CPU at the root]]
  ][
    #only(1, pcie-tree(1))
    #only(2, pcie-tree(2))
    #only("3-", pcie-tree(3))
  ]

  #v(0.2em)
  #only(1)[💡 the old PCI was one shared bus: all the cards took turns on the same wires]
  #only(2)[💡 the devices behind a switch share its link up to the CPU]
  #only("3-")[💡 `lspci -tv` prints this tree: next slide]
]

// `lspci -tv` on a Panther Lake laptop (trimmed with "...")
#let laptop-tree = (
  "$ lspci -tv",
  "-[0000:00]-+-00.0  Intel Corporation Core Ultra Processors (Series 3) PTL-H12Xe",
  "           +-02.0  Intel Corporation Panther Lake [Arc B390]",
  "           ...",
  "           +-06.0-[01]----00.0  Sandisk Corp WD_BLACK SN7100/WD PC SN7100S M.2 2280 NVMe SSD (DRAM-less)",
  "           +-07.0-[02-2b]--",
  "           +-07.1-[2c-55]--",
  "           +-07.2-[56-7f]--",
  "           +-07.3-[80-a9]--",
  "           ...",
  "           +-0b.0  Intel Corporation Core Ultra Processors (Series 3) NPU",
  "           +-0d.0  Intel Corporation Core Ultra Processors (Series 3) Type-C Subsystem xHCI",
  "           ...",
  "           +-14.3  Intel Corporation Core Ultra Processors (Series 3) CNVi Wi-Fi",
  "           ...",
  "           \\-1f.5  Intel Corporation Core Ultra Processors (Series 3) SPI (flash) Controller",
)

#slide[
  == See the Topology
  `lspci -tv` draws the PCIe tree of a Panther Lake laptop

  #set text(size: 0.62em)
  #mark-terminal(laptop-tree, (
    (15, ((1, "[0000:00]"), (1, "00.0"), (2, "02.0"), (10, "0b.0"), (11, "0d.0"), (13, "14.3"), (15, "1f.5"))),
    (15, ((4, "06.0-[01]"), (4, "Sandisk Corp WD_BLACK SN7100/WD PC SN7100S M.2 2280 NVMe SSD (DRAM-less)"))),
    (15, ((5, "07.0-[02-2b]"), (6, "07.1-[2c-55]"), (7, "07.2-[56-7f]"), (8, "07.3-[80-a9]"))),
  ))
  #set text(size: 1em / 0.62)

  #v(0.2em)
  #only(1)[💡 bus `00`: GPU, NPU, USB, Wi-Fi, all *inside the SoC*; a laptop has no separate chipset]
  #only(2)[💡 `06.0` is a *root port*, a link out of the chip; behind it, bus `01`: the M.2 SSD]
  #only("3-")[💡 4 empty root ports for the USB-C sockets: buses `02` to `a9` wait for devices plugged in later]
]

// one cell of the speed table: lanes x one lane, shown from `at`; `mark`:
// an emoji for a known device, the cell is then orange
#let gbs-cell(v, at, mark: none) = uncover(str(at) + "-", if mark == none [#v] else {
  text(weight: "bold", fill: changed.darken(15%))[#v #mark]
})
#assert.eq(pcie.at(1).at(2) * 4, 8) // PCIe 4.0 x4: an NVMe SSD
#assert.eq(pcie.at(2).at(2) * 16, 64) // PCIe 5.0 x16: a new GPU

#slide[
  == PCIe Speeds
  Speed of a link = number of lanes × speed of one lane

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - *x4* (read "by four") = a link of *4 lanes*
    #v(0.2em)
    #lane-links
    #v(0.2em)
    #uncover("2-")[#block[- every *generation* doubles the speed of one lane]]
    #uncover("3-")[#block[- multiply: the GB/s of the whole link]]
  ][
    #nice-table(
      columns: (auto, auto, 1fr, 1fr, 1fr),
      size: 0.8em,
      header: ([PCIe], [year], [x1], [x4], [x16]),
      rows: pcie.map(((g, y, v)) => (
        uncover("2-")[*#g*],
        uncover("2-", text(fill: luma(110), str(y))),
        gbs-cell(v, 2),
        gbs-cell(v * 4, 3, mark: if g == "4.0" { "💾" }),
        gbs-cell(v * 16, 3, mark: if g == "5.0" { "🎮" }),
      )),
    )
    #align(center, text(size: 0.65em, fill: luma(110))[≈ GB/s, in each direction at the same time])
  ]

  #v(0.2em)
  #only(1)[💡 each line is one lane (a pair of wires each way); links come as x1, x2, x4, x8 or x16]
  #only(2)[💡 3.0 to 7.0: 1, 2, 4, 8, 16 GB/s for one lane]
  #only(3)[💡 the orange cells: an NVMe SSD (PCIe 4.0 x4 = 8 GB/s) and a new GPU (PCIe 5.0 x16 = 64 GB/s)]
  #only("4-")[💡 PCs today use 4.0 and 5.0; 6.0 and 7.0 start in data centers]

  #only(4, place(center + horizon, info(width: 380pt)[Old and new work together][
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 1.2em,
      [
        *an x4 card in an x16 slot* \
        #box(width: 150pt, height: 46pt, {
          // the card on top of the first 4 lanes
          place(top + left, dx: 2pt, box(width: 36pt, height: 22pt, radius: 2pt, fill: accent, align(center + horizon, text(size: 0.7em, fill: white)[x4 card])))
          // the slot with its 16 lanes
          place(top + left, dy: 24pt, box(width: 150pt, height: 12pt, radius: 2pt, fill: luma(235), stroke: 0.8pt + luma(130)))
          for i in range(16) {
            place(top + left, dx: 3pt + i * 9pt, dy: 27pt, box(width: 6pt, height: 6pt, radius: 1pt, fill: if i < 4 { changed } else { luma(190) }))
          }
          place(top + left, dy: 38pt, text(size: 0.65em)[#text(fill: changed.darken(15%))[4 lanes used] #h(0.5em) #text(fill: luma(110))[12 unused]])
        })
        #block(above: 0.3em, text(size: 0.75em)[✅ it fits and works, at x4 speed])
      ],
      [
        *a PCIe 4.0 card in a 5.0 slot* \
        #set text(size: 0.75em)
        #grid(
          columns: (auto, auto),
          column-gutter: 0.5em,
          row-gutter: 0.4em,
          align: (right + horizon, left + horizon),
          [card 4.0], bar(2, 4, width: 80pt, label: [2 GB/s]),
          [slot 5.0], bar(4, 4, width: 80pt, label: [4 GB/s]),
          [*link*], bar(2, 4, width: 80pt, on: true, label: [*2 GB/s*]),
        )
        #v(0.2em)
        ✅ it works, at the speed of the *slower* side
      ],
    )
  ]))
]

// the USB tree: the controller (a PCIe device) with its root hub, devices
// on its ports, and a hub that shares one port between more devices.
// `step` 1: the controller, 2: devices on the ports, 3: the hub, 4: all
#let usb-tree(step) = drawing(width: 290pt, height: 166pt, {
  let c = step == 1
  let d = step == 2
  let h = step == 3
  let ln(p, q, on, thick: false) = wire(p, q, stroke: (if thick { 2.2pt } else { 1.2pt }) + if on { changed } else { luma(150) })
  let dev(x, y, w, body, sub, on) = at(x, y, unit(kind: "slot", width: w, height: 30pt, on: on, size: 0.62em, sub: sub, body))
  at(0pt, 0pt, unit(kind: "dark", width: 60pt, height: 36pt, size: 0.7em, icon: cpu-icon)[CPU])
  ln((60pt, 18pt), (100pt, 18pt), c, thick: true)
  at(66pt, 6pt, text(size: 0.55em, weight: "bold", fill: if c { changed.darken(15%) } else { luma(100) })[PCIe])
  at(100pt, 0pt, unit(width: 120pt, height: 36pt, on: c, size: 0.65em, sub: [xHCI, with its *root hub*])[USB controller])
  // devices on the ports of the root hub
  ln((130pt, 36pt), (35pt, 80pt), d)
  ln((160pt, 36pt), (130pt, 80pt), d)
  ln((190pt, 36pt), (230pt, 80pt), h)
  dev(0pt, 80pt, 70pt, [⌨️ keyboard], [12 Mb/s], d)
  dev(90pt, 80pt, 80pt, [💾 USB stick], [10 Gb/s], d)
  at(195pt, 80pt, unit(width: 70pt, height: 30pt, on: h, size: 0.62em, sub: [480 Mb/s])[🔀 hub])
  // behind the hub
  ln((215pt, 110pt), (175pt, 136pt), h)
  ln((245pt, 110pt), (255pt, 136pt), h)
  dev(140pt, 136pt, 70pt, [🖱️ mouse], [12 Mb/s], h)
  dev(220pt, 136pt, 70pt, [📷 webcam], [480 Mb/s], h)
})

#slide[
  == USB
  A tree of devices, behind one controller

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - the *USB controller* is itself a PCIe device
    - its *root hub* holds the ports of the computer
    #uncover("2-")[#block[- each device talks at its *own* speed]]
    #uncover("3-")[#block[- a *hub* turns one port into many: the devices behind it *share* that port]]
    #uncover("4-")[#block[- together: a *tree*, like PCIe]]
  ][
    #only(1, usb-tree(1))
    #only(2, usb-tree(2))
    #only(3, usb-tree(3))
    #only("4-", usb-tree(4))
  ]

  #v(0.2em)
  #only(1)[💡 `lspci` shows it as `USB controller`; it sits in the chipset or in the CPU]
  #only(2)[💡 a keyboard needs only 12 Mb/s, a fast USB stick 10 Gb/s]
  #only(3)[💡 a webcam and a mouse behind a USB 2.0 hub share its 480 Mb/s]
  #only("4-")[💡 `lsusb -t` prints this tree: next slide]
]

// `lsusb` and `lsusb -t` on a Panther Lake laptop
#let laptop-usb = (
  "$ lsusb",
  "Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub",
  "Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub",
  "Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub",
  "Bus 003 Device 002: ID 32ac:0002 Framework HDMI Expansion Card",
  "Bus 003 Device 004: ID 32ac:001c Framework Laptop Webcam Module (2nd Gen)",
  "Bus 003 Device 005: ID 27c6:609c Shenzhen Goodix Technology Co.,Ltd. Goodix Fingerprint USB Device",
  "Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub",
  "$ lsusb -t",
  "/:  Bus 001.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/1p, 480M",
  "/:  Bus 002.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/4p, 20000M/x2",
  "/:  Bus 003.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/10p, 480M",
  "    |__ Port 002: Dev 002, If 0, Class=Billboard, Driver=[none], 12M",
  "    |__ Port 002: Dev 002, If 1, Class=Human Interface Device, Driver=usbhid, 12M",
  "    |__ Port 006: Dev 004, If 0, Class=Video, Driver=uvcvideo, 480M",
  "    |__ Port 006: Dev 004, If 1, Class=Video, Driver=uvcvideo, 480M",
  "    |__ Port 006: Dev 004, If 2, Class=Application Specific Interface, Driver=[none], 480M",
  "    |__ Port 007: Dev 005, If 0, Class=Vendor Specific Class, Driver=[none], 12M",
  "/:  Bus 004.Port 001: Dev 001, Class=root_hub, Driver=xhci_hcd/2p, 20000M/x2",
)

#slide[
  == USB in Linux
  `lsusb` lists the devices, `lsusb -t` draws the tree with the speeds

  #set text(size: 0.54em)
  #mark-terminal(laptop-usb, (
    (7, ((1, "2.0 root hub"), (2, "3.0 root hub"), (3, "2.0 root hub"), (7, "3.0 root hub"))),
    (7, ((4, "32ac:0002"), (4, "Framework HDMI Expansion Card"), (5, "Framework Laptop Webcam Module (2nd Gen)"), (6, "Goodix Fingerprint USB Device"))),
    (18, ((9, "480M"), (10, "20000M/x2"), (11, "480M"), (12, "12M"), (14, "480M"), (17, "12M"), (18, "20000M/x2"))),
    (18, ((12, "Class=Billboard"), (13, "Driver=usbhid"), (14, "Driver=uvcvideo"), (15, "Driver=uvcvideo"))),
  ))
  #set text(size: 1em / 0.54)

  #v(0.2em)
  #only(1)[💡 4 buses: the 2 USB controllers from `lspci`, each with a USB 2.0 and a USB 3 *root hub*]
  #only(2)[💡 `ID` = maker:product; the webcam and the fingerprint reader are *inside* the laptop, on USB]
  #only(3)[💡 `480M` = USB 2.0, `12M` is enough for a keyboard; `20000M/x2` = *2 lanes* of 10 Gb/s, as on USB Speeds]
  #only("4-")[💡 a driver per interface: `uvcvideo` = the camera; _Billboard_ = the HDMI card (DisplayPort over USB-C)]
]

// USB names and speeds: (name, also sold as, lanes, Gb/s of one lane)
#let usb = (
  ([USB 2.0], [Hi-Speed], 1, 0.48),
  ([USB 3.2 Gen 1], [USB 3.0, "USB 5Gbps"], 1, 5),
  ([USB 3.2 Gen 2], [USB 3.1, "USB 10Gbps"], 1, 10),
  ([USB 3.2 Gen 2x2], ["USB 20Gbps"], 2, 10),
  ([USB4], ["USB 40Gbps", Thunderbolt 4], 2, 20),
  ([USB4 v2], ["USB 80Gbps", Thunderbolt 5], 2, 40),
)
#assert.eq(usb.map(((n, a, l, g)) => l * g), (0.48, 5, 10, 20, 40, 80))
#let gbps(x) = if x < 1 [#int(x * 1000) Mb/s] else [#x Gb/s]

// a USB-C plug seen from the front
#let usb-c = box(width: 60pt, height: 22pt, radius: 11pt, fill: luma(200), stroke: 1pt + luma(100), align(
  center + horizon,
  box(width: 40pt, height: 6pt, radius: 3pt, fill: luma(90)),
))

#slide[
  == USB Speeds
  Speed = lanes × speed of one lane, like PCIe, but in *bits*

  #nice-table(
    columns: (auto, auto, auto, 1fr),
    size: 0.78em,
    header: ([name], [also sold as], [lanes × one lane], [speed]),
    rows: usb.map(((name, aka, l, g)) => (
      [*#name*],
      text(fill: luma(90), aka),
      if l > 1 [#text(weight: "bold", fill: changed.darken(15%))[#l] × #gbps(g)] else [#l × #gbps(g)],
      bar(l * g, 80, width: 120pt, on: l > 1, label: [*#gbps(l * g)* = #calc.round(l * g * 1000 / 8) MB/s]),
    )),
    shown: (none, none, none, 2, 2, 2),
  )

  #v(0.2em)
  #only(1)[💡 the same speed got renamed: USB 3.0 = USB 3.1 Gen 1 = USB 3.2 Gen 1; the new logos just say "USB 10Gbps"]
  #only(2)[💡 "2x2" and USB4: *2 lanes*, both pairs of wires of a USB-C cable]

  #only(3, place(center + horizon, info(width: 360pt)[USB-C is a shape, not a speed][
    #grid(
      columns: (auto, 1fr),
      column-gutter: 1em,
      align: horizon,
      usb-c,
      [a USB-C port may be USB 2.0 (480 Mb/s) or USB4 (40 Gb/s); one cable can carry 📦 data, ⚡ power up to 240 W, 🖥️ a display, 🛣️ PCIe (USB4)],
    )
  ]))
  #only("4-", place(center + horizon, info(width: 360pt)[The slowest part decides][
    #set text(size: 0.85em)
    #grid(
      columns: (auto, auto),
      column-gutter: 0.6em,
      row-gutter: 0.4em,
      align: (right + horizon, left + horizon),
      [USB stick], bar(10, 10, width: 120pt, label: [10 Gb/s]),
      [port], bar(10, 10, width: 120pt, label: [10 Gb/s]),
      [old cable], bar(0.48, 10, width: 120pt, label: [480 Mb/s (USB 2.0)]),
      [*link*], bar(0.48, 10, width: 120pt, on: true, label: [*480 Mb/s*]),
    )
    #v(0.2em)
    a device works at the speed of the slowest of: the port, the cable, itself
  ]))
]

// pixels per second of a 4K screen at 144 Hz, 30 bits per pixel, in Gb/s
#let k4-gbps = calc.round(3840 * 2160 * 144 * 30 / 1e9)
#assert.eq(k4-gbps, 36)

#slide[
  == Leaving the Box
  Screens and networks: the links that leave the box

  #set text(size: 0.78em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.6em,
    card([📺 HDMI], height: 6.5em)[
      TVs, monitors, projectors \
      #tag[2.1: 48 Gb/s] #tag[2.2: 96 Gb/s] \
      also carries sound
    ],
    card([🖥️ DisplayPort], height: 6.5em)[
      monitors \
      #tag[2.1: up to 80 Gb/s] \
      also over USB-C
    ],
    uncover("2-", card([🌐 Ethernet], height: 6.5em)[
      a cable (RJ45) \
      #tag[1 / 2.5 / 10 Gb/s] \
      stable, low latency
    ]),
    uncover("2-", card([📶 Wi-Fi 6, 6E, 7], height: 6.5em)[
      radio, wireless network \
      #tag[a few Gb/s] \
      shared by everyone around
    ]),
    uncover("3-", card([🎧 Bluetooth], height: 6.5em)[
      headphones, mice, watches \
      #tag[1 - 3 Mb/s] \
      low power, a few meters
    ]),
  )

  #set text(size: 1em / 0.78)
  #only(1)[💡 the screen decides the bandwidth: 4K at 144 Hz with 10-bit color is \~#k4-gbps Gb/s of pixels]
  #only(2)[💡 the Wi-Fi speed on the box is the best case: near the router, alone]
  #only("3-")[💡 the network cards are PCIe devices too, behind the chipset or inside the SoC]
]

// a microcontroller with a sensor on I²C, a flash chip on SPI and a laptop
// on UART; `step` selects the orange bus: 1 I²C, 2 SPI, 3 UART
#let small-buses(step) = drawing(width: 270pt, height: 150pt, {
  at(95pt, 50pt, unit(kind: "dark", width: 80pt, height: 50pt, size: 0.65em, icon: "🔌", sub: [Arduino, ESP32])[microcontroller])
  // I²C: two wires to two sensors
  let c1 = step == 1
  link-line((135pt, 50pt), (135pt, 34pt), on: c1)
  link-line((40pt, 34pt), (230pt, 34pt), on: c1)
  link-line((40pt, 34pt), (40pt, 24pt), on: c1)
  link-line((230pt, 34pt), (230pt, 24pt), on: c1)
  at(0pt, 0pt, unit(kind: "slot", width: 80pt, height: 24pt, on: c1, size: 0.6em)[🌡️ sensor `0x48`])
  at(190pt, 0pt, unit(kind: "slot", width: 80pt, height: 24pt, on: c1, size: 0.6em)[🧭 sensor `0x68`])
  pin(135pt, 26pt, text(size: 0.6em, weight: "bold", fill: if c1 { changed } else { luma(90) })[I²C])
  // SPI: a flash chip
  let c2 = step == 2
  link-line((95pt, 90pt), (60pt, 90pt), on: c2, thick: true)
  at(0pt, 78pt, unit(kind: "slot", width: 60pt, height: 24pt, on: c2, size: 0.6em)[💾 flash])
  pin(78pt, 82pt, text(size: 0.6em, weight: "bold", fill: if c2 { changed } else { luma(90) })[SPI])
  // UART: a laptop
  let c3 = step == 3
  link-line((175pt, 90pt), (210pt, 90pt), on: c3)
  at(210pt, 78pt, unit(kind: "slot", width: 60pt, height: 24pt, on: c3, size: 0.6em)[💻 laptop])
  pin(192pt, 82pt, text(size: 0.6em, weight: "bold", fill: if c3 { changed } else { luma(90) })[UART])
  // GPIO: a LED
  link-line((135pt, 100pt), (135pt, 122pt))
  at(105pt, 122pt, unit(kind: "slot", width: 60pt, height: 22pt, size: 0.6em)[💡 LED])
  pin(152pt, 112pt, text(size: 0.6em, weight: "bold", fill: luma(90))[GPIO])
})

#slide[
  == I²C, SPI, UART
  Small devices talk slowly: simple buses for sensors and microcontrollers

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.78em)
    - *I²C*: 2 wires, many devices, each with an *address*
    #uncover("2-")[#block[- *SPI*: 4 wires, faster: flash chips, small displays]]
    #uncover("3-")[#block[- *UART*: 2 wires, the serial console: text in, text out]]
    #uncover("4-")[#block[
      - *GPIO*: one pin, on or off
      - a PC uses them too: the firmware chip is on SPI, RAM modules and sensors on I²C (_SMBus_)
    ]]
  ][
    #only(1, small-buses(1))
    #only(2, small-buses(2))
    #only(3, small-buses(3))
    #only("4-", small-buses(0))
  ]

  #v(0.2em)
  #only("4-")[💡 in Linux: `/sys/bus/i2c`, `/sys/bus/spi`, `/dev/ttyS0`, `/dev/ttyUSB0`]
]
