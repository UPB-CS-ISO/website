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
#let link-drawing(parallel, on: false) = drawing(width: 230pt, height: 78pt, {
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
  } else {
    let c = if on { changed } else { accent }
    line-arrow((36pt, 32pt), (194pt, 32pt), color: c, thickness: 1.2pt)
    line-arrow((194pt, 54pt), (36pt, 54pt), color: c, thickness: 1.2pt)
    at(50pt, 22pt, bits("0110100111010010", color: c))
    at(70pt, 57pt, bits("1101001011", color: c))
    pin(115pt, 6pt, note[*serial*: one _lane_ = a pair of wires each way])
  }
})

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
    #uncover("3-")[#block[
      - *serial* (today): one bit after the other, billions per second
        - PCIe, SATA, USB, Ethernet, HDMI
        - need more speed? add more *lanes*
    ]]
  ][
    #link-drawing(true)
    #uncover("3-", link-drawing(false, on: true))
  ]

  #v(0.2em)
  #only(1)[💡 more wires sounds faster: a whole byte in one clock tick]
  #only(2)[💡 a tiny difference in wire length is enough: the receiver has to wait for the slowest bit]
  #only("3-")[💡 a serial lane can tick much faster, and each lane works on its own]
]

// ---------------------------------------------------------------------------
// How fast is a link?
// ---------------------------------------------------------------------------

#let pcie4-x4 = 4 * 2 // 4 lanes of ~2 GB/s
#assert.eq(pcie4-x4, 8)
#let usb10 = 10 / 8 // 10 Gb/s in GB/s
#assert.eq(usb10, 1.25)
#let gbe-1gb-file = 1 * 8 / 1 // seconds for a 1 GB file on a 1 Gb/s link
#assert.eq(gbe-1gb-file, 8.0)

#slide[
  == How Fast Is a Link?
  Count the lanes, then mind the bits and the bytes

  #set text(size: 0.85em)
  #align(center, callout[
    speed of the link = *number of lanes* × speed of one lane \
    #text(size: 0.85em)[_bits_ per second: `Gb/s` #h(1em) _bytes_ per second: `GB/s` #h(1em) 1 byte = 8 bits]
  ])

  #v(0.4em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    uncover("2-", card([💾 NVMe SSD])[
      PCIe 4.0 `x4` \
      4 lanes × \~2 GB/s \
      #sym.eq *\~#pcie4-x4 GB/s*
    ]),
    uncover("3-", card([🔌 USB 3.2 Gen 2])[
      10 Gb/s \
      10 / 8 \
      #sym.eq *#usb10 GB/s* at most
    ]),
    uncover("4-", card([🌐 1 Gb/s Ethernet])[
      a 1 GB file \
      1 GB × 8 / 1 Gb/s \
      #sym.eq *#gbe-1gb-file seconds* at least
    ]),
  )

  #v(0.3em)
  #only("3-")[💡 real transfers are a bit slower: each link also sends its own control data (encoding, headers)]
]

// PCIe per-lane speed in GB/s, rounded, per direction: (generation, year, GB/s)
#let pcie = (("3.0", 2010, 1), ("4.0", 2017, 2), ("5.0", 2019, 4), ("6.0", 2022, 8), ("7.0", 2025, 16))

// PCIe slots drawn to scale (a short key part, then the lanes), with
// their names and what usually goes in them
#let pcie-slots = grid(
  columns: (auto, auto, auto),
  column-gutter: 0.4em,
  row-gutter: 0.35em,
  align: left + horizon,
  ..((1, [📶 Wi-Fi]), (4, [💾 SSD]), (16, [🎮 GPU]))
    .map(((lanes, what)) => (
      text(size: 0.8em, weight: "bold", raw("x" + str(lanes))),
      {
        box(width: 8pt, height: 9pt, radius: 1pt, fill: white, stroke: 0.8pt + luma(120))
        h(2pt)
        box(width: 6pt + lanes * 7pt, height: 9pt, radius: 1pt, fill: white, stroke: 0.8pt + luma(120))
      },
      text(size: 0.8em, what),
    ))
    .flatten(),
)

#slide[
  == PCI Express (PCIe)
  The main road inside a computer 🛣️

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - *point-to-point*: each device has its own link
    - a link has 1, 4, 8 or 16 *lanes*
    #v(0.2em)
    #pcie-slots
    #v(0.2em)
    #uncover("2-")[#block[
      - every generation *doubles* the speed
      - old and new work together, at the speed of the slower one
    ]]
  ][
    #uncover("2-")[
      #align(center, text(size: 0.75em, weight: "bold")[≈ GB/s per lane, each direction])
      #bar-chart(
        pcie.map(((g, y, s)) => ([PCIe #g #text(fill: luma(120))[(#y)]], s, [#s (x16: #(s * 16))])),
        16,
        width: 130pt,
        name-width: 7em,
        size: 0.75em,
        start: none,
        on: 2,
      )
    ]
  ]

  #v(0.2em)
  #only(1)[💡 a `x4` card works in a `x16` slot, it uses only 4 lanes]
  #only("2-")[💡 PCs today use PCIe 4.0 and 5.0 (orange); 6.0 and 7.0 start in data centers]
]

// USB versions: (name, Gb/s)
#let usb = (
  ([USB 2.0], 0.48, [480 Mb/s]),
  ([USB 3.2 Gen 1], 5, [5 Gb/s]),
  ([USB 3.2 Gen 2], 10, [10 Gb/s]),
  ([USB 3.2 Gen 2x2], 20, [20 Gb/s]),
  ([USB4], 40, [40 Gb/s]),
  ([USB4 v2], 80, [80 Gb/s]),
)

// a USB-C plug seen from the front
#let usb-c = box(width: 60pt, height: 22pt, radius: 11pt, fill: luma(200), stroke: 1pt + luma(100), align(
  center + horizon,
  box(width: 40pt, height: 6pt, radius: 3pt, fill: luma(90)),
))

#slide[
  == USB
  One port for (almost) everything

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #bar-chart(usb, 80, width: 150pt, name-width: 7.5em, size: 0.75em, start: none)
    #align(center, text(size: 0.65em, fill: luma(100))[Thunderbolt 4 / 5: 40 / 80 Gb/s, over the same plug])
  ][
    #set text(size: 0.8em)
    #uncover("2-")[
      #align(center)[#usb-c \ #text(size: 0.8em)[*USB-C*: a *shape*, not a speed]]
    ]
    #uncover("3-")[#block[
      - one cable can carry
        - 📦 data
        - ⚡ power, up to 240 W
        - 🖥️ a display (DisplayPort)
        - 🛣️ PCIe (USB4, Thunderbolt)
    ]]
  ]

  #v(0.2em)
  #only(1)[💡 the same speed was renamed several times: USB 3.0 = USB 3.1 Gen 1 = USB 3.2 Gen 1 = "USB 5Gbps"]
  #only(2)[⚠️ a USB-C port may be USB 2.0 (480 Mb/s) or USB4 (40 Gb/s): look for the speed next to the port or on the cable]
  #only("3-")[💡 the new USB logos say the speed and the power: "USB 40Gbps", "240W"]
]

#slide[
  == USB in Linux
  `lsusb -t`: the USB tree, with the speed of every device

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - `lsusb`: one line per device
    - `lsusb -t`: as a tree
      - *root hub*: the USB controller
      - each device with its *driver* and its *speed*
    #uncover("2-")[#block[
      - `480M` = USB 2.0, `10000M` = 10 Gb/s
      - `12M`: a keyboard does not need more
    ]]
  ][
    #set text(size: 0.6em)
    #reveal-terminal(before: none, lines: (5, 10), full: false)[```terminal
    $ lsusb
    Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
    Bus 001 Device 003: ID 05ac:8106 Apple, Inc. Virtual USB Digitizer
    Bus 001 Device 002: ID 05ac:8105 Apple, Inc. Virtual USB Keyboard
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    $ lsusb -t
    /:  Bus 02.Port 1: Dev 1, Class=root_hub, Driver=xhci_hcd/8p, 10000M
    /:  Bus 01.Port 1: Dev 1, Class=root_hub, Driver=xhci_hcd/8p, 480M
        |__ Port 1: Dev 2, If 0, Class=Human Interface Device, Driver=usbhid, 12M
        |__ Port 2: Dev 3, If 0, Class=Human Interface Device, Driver=usbhid, 12M
    ```]
  ]

  #v(0.2em)
  #only(1)[💡 one USB controller (`xhci_hcd`) shows up as two root hubs: one for USB 2.0 devices, one for USB 3.x]
  #only("2-")[💡 a device works at the slowest speed of the port, the cable and itself]
]

// pixels per second of a 4K screen at 144 Hz, 30 bits per pixel, in Gb/s
#let k4-gbps = calc.round(3840 * 2160 * 144 * 30 / 1e9)
#assert.eq(k4-gbps, 36)

#slide[
  == Screens and Networks
  Links that leave the box

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
  == Small Devices Talk Slowly
  Simple buses for sensors and microcontrollers

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
