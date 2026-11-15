#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Memory and Storage #text(size: 10pt, weight: "regular")[\ _Small and fast, or large and slow; lost at power off, or kept_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 1 - _The Big Picture_
      - Section 1.2 - _Hardware: Understanding Main Memory_
    - Chapter 3 - _Devices_
      - Section 3.4 - _Device Name Summary_
  + #uso-book
    - Chapter 8 - _Componente hardware_
      - Section 8.6 - _Abstractizarea dispozitivelor în Linux_
  + #patterson
    - Chapter 5 - _Large and Fast: Exploiting Memory Hierarchy_
]

// ---------------------------------------------------------------------------
// The memory hierarchy
// ---------------------------------------------------------------------------

// (name, typical size, typical latency in ns, emoji)
#let levels = (
  ("registers", "a few KiB", 0.3, "⚡"),
  ("L1 cache", "32-192 KiB / core", 1, "👆"),
  ("L2 cache", "1-4 MiB", 4, "🚶"),
  ("L3 cache", "10-128 MiB", 15, "🚪"),
  ("RAM", "8-64 GiB", 100, "☕"),
  ("NVMe SSD", "0.5-4 TB", 50000, "🛌"),
  ("hard disk", "1-30 TB", 5000000, "✉️"),
)

// "if an L1 access took one second, how long would this take?"
#let human(ns) = {
  let s = ns // 1 ns of L1 = 1 s
  if s < 60 { str(calc.round(s, digits: 1)) + " s" } else if s < 3600 {
    str(calc.round(s / 60, digits: 1)) + " minutes"
  } else if s < 86400 * 2 { str(calc.round(s / 3600)) + " hours" } else { str(calc.round(s / 86400)) + " days" }
}
#assert.eq(human(100), "1.7 minutes")
#assert.eq(human(50000), "14 hours")
#assert.eq(human(5000000), "58 days")

#let latency(ns) = if ns < 1000 [#ns ns] else if ns < 1000000 [#(ns / 1000) µs] else [#(ns / 1000000) ms]

// a pyramid, one level per row: small and fast on top
#let pyramid(shown) = {
  let h = 19pt
  let cx = 85pt
  let width(i) = 34pt + i * 22pt
  drawing(width: 450pt, height: levels.len() * h + 16pt, {
    at(190pt, 0pt, text(size: 0.65em, weight: "bold")[size])
    at(275pt, 0pt, text(size: 0.65em, weight: "bold")[access])
    at(340pt, 0pt, text(size: 0.65em, weight: "bold")[if L1 took 1 s])
    for (i, (name, size, ns, emoji)) in levels.enumerate() {
      if i < shown {
        let y = 14pt + i * h
        let (wt, wb) = (width(i), width(i + 1))
        let fill = if i < 4 { accent.lighten(i * 22%) } else if i == 4 { rgb("bac8d3") } else { luma(225) }
        at(0pt, y, polygon(
          fill: fill,
          stroke: 0.8pt + white,
          (cx - wt / 2, 0pt),
          (cx + wt / 2, 0pt),
          (cx + wb / 2, h),
          (cx - wb / 2, h),
        ))
        pin(cx, y + h / 2, text(size: 0.62em, weight: "bold", fill: if i < 3 { white } else { black }, name))
        wire((cx + wb / 2 + 4pt, y + h / 2), (185pt, y + h / 2), stroke: (paint: luma(190), thickness: 0.5pt, dash: "dotted"))
        at(190pt, y + 6pt, text(size: 0.62em, size))
        at(275pt, y + 6pt, text(size: 0.62em, latency(ns)))
        at(340pt, y + 4pt, text(size: 0.65em, weight: if i >= 4 { "bold" } else { "regular" })[#emoji #human(ns)])
      }
    }
  })
}

#slide[
  == The Memory Hierarchy
  Small and fast close to the CPU, large and slow far from it

  #only(1, pyramid(4))
  #only(2, pyramid(5))
  #only(3, pyramid(6))
  #only("4-", pyramid(7))

  #only(1)[💡 a _cache_ keeps a copy of the data used recently, inside the CPU chip]
  #only(2)[💡 RAM is lost at power off (_volatile_): a coffee break for every access]
  #only(3)[💡 storage keeps the data at power off (_persistent_)]
  #only(4)[💡 waiting for a hard disk is like waiting two months for a letter]
  #only("5-")[💡 why not all as fast as L1? a cache bit (SRAM) needs 6 transistors, a RAM bit (DRAM) 1 transistor + 1 capacitor]
]

// what a "1 TB" disk shows in GiB
#let tb-in-gib = calc.floor(1e12 / calc.pow(2, 30))
#assert.eq(tb-in-gib, 931)

#slide[
  == RAM or Storage?
  Two different jobs

  #set text(size: 0.85em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    card([🧮 Memory (RAM)])[
      - 🔌 lost at power off (_volatile_)
      - the CPU reads any *byte* directly
      - ⚡ \~100 ns, tens of GB
    ],
    uncover("2-", card([💾 Storage])[
      - 🔋 kept at power off (_persistent_)
      - read and written in *blocks* (4 KiB) by a driver
      - 🐢 µs to ms, TBs
    ]),
  )

  #set text(size: 1em / 0.85)
  #v(0.4em)
  #question(3)[I bought a 1 TB disk. Why does Linux show 931G?][
    💡 makers count $10^12$ bytes (TB), Linux counts $2^30$ bytes (GiB): $10^12 / 2^30 approx #tb-in-gib$
  ]
]

// a hard disk seen from above: the platter with its tracks, the arm and
// the head; `step` 2 colors the arm (it moves to the track)
#let hdd(step) = drawing(width: 190pt, height: 150pt, {
  at(0pt, 0pt, box(width: 190pt, height: 150pt, radius: 6pt, fill: luma(225), stroke: 1pt + luma(140)))
  // platter and tracks
  at(10pt, 10pt, circle(radius: 65pt, fill: luma(195), stroke: 1pt + luma(130)))
  for r in (55pt, 45pt, 35pt, 25pt) {
    at(75pt - r, 75pt - r, circle(radius: r, fill: none, stroke: (paint: luma(160), thickness: 0.5pt, dash: "dotted")))
  }
  // the track being read
  at(75pt - 45pt, 75pt - 45pt, circle(radius: 45pt, fill: none, stroke: (
    if step >= 2 { 1.2pt + changed } else { 0.5pt + luma(160) }
  )))
  at(65pt, 65pt, circle(radius: 10pt, fill: luma(150), stroke: none))
  // the arm, from its pivot to the head on the track
  let c = if step >= 2 { changed } else { luma(100) }
  wire((168pt, 128pt), (106pt, 43pt), stroke: 5pt + c)
  at(160pt, 120pt, circle(radius: 8pt, fill: luma(110), stroke: none))
  at(102pt, 39pt, box(width: 8pt, height: 8pt, fill: c, radius: 1pt))
  // labels
  pin(150pt, 22pt, text(size: 0.6em, weight: "bold", fill: c)[head])
  pin(33pt, 140pt, text(size: 0.6em, weight: "bold")[platter])
  pin(176pt, 98pt, text(size: 0.6em, weight: "bold", fill: c)[arm])
  pin(75pt, 92pt, text(size: 0.5em, fill: luma(60))[spins 🔄])
})

#slide[
  == Hard Disk Drive (HDD)
  Magnetic platters that spin

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - metal or glass *platters*, covered with magnetic material
      - spin at 5400 - 7200 rotations per minute
    - a moving *arm* with a read / write *head* per side
    #uncover("2-")[#block[
      - 🐢 to read, the arm moves to the track and waits for the data to pass under it: *milliseconds*
        - in order (_sequential_): 100 - 280 MB/s
        - small pieces all over the disk: very slow
    ]]
    #uncover("3-")[#block[
      - 💰 cheapest per TB, 📦 up to 30 TB and more
        - backups, NAS, data centers
    ]]
  ][
    #only(1, hdd(1))
    #only("2-", hdd(2))
  ]

  #v(0.2em)
  #only("3-")[⚠️ moving parts: an HDD does not like shocks, keep laptops with HDDs still while they work]
]

// an M.2 2280 SSD (22 x 80 mm) seen from above; `step` selects what is
// orange: 1 the flash chips, 2 the controller, 3 the connector
#let m2-ssd(step) = drawing(width: 290pt, height: 110pt, {
  // the board
  at(0pt, 20pt, box(width: 280pt, height: 72pt, radius: (right: 8pt, left: 2pt), fill: rgb("26332c"), stroke: 0.8pt + luma(60)))
  // the connector: gold fingers, with the M-key notch
  for i in range(14) {
    if i != 3 {
      at(2pt, 26pt + i * 4.5pt, box(width: 10pt, height: 3pt, fill: if step == 3 { changed } else { rgb("d4af37") }))
    }
  }
  at(272pt, 50pt, circle(radius: 5pt, fill: white, stroke: 0.8pt + luma(120)))
  // the chips
  at(22pt, 34pt, unit(kind: "dark", width: 52pt, height: 44pt, on: step == 2, size: 0.55em)[controller])
  at(84pt, 38pt, unit(kind: "slot", width: 30pt, height: 36pt, size: 0.5em)[DRAM])
  for i in range(2) {
    at(124pt + i * 68pt, 30pt, unit(kind: "slot", width: 62pt, height: 52pt, on: step == 1, size: 0.6em)[NAND \ flash])
  }
  // labels
  pin(45pt, 8pt, note(color: if step == 2 { changed } else { luma(100) })[a small CPU])
  pin(190pt, 8pt, note(color: if step == 1 { changed } else { luma(100) })[the bits live here])
  pin(30pt, 102pt, note(color: if step == 3 { changed } else { luma(100) })[M.2 connector (M key)])
  pin(220pt, 102pt, note[22 × 80 mm (M.2 2280)])
})

#slide[
  == Solid State Drive (SSD)
  Flash memory, no moving parts

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - *NAND flash* chips keep the bits as electric charge
      - ⚡ any block in *microseconds*
    #uncover("2-")[#block[
      - a *controller* manages them
        - spreads the writes (_wear leveling_)
        - `TRIM`: the OS tells it which blocks are free
    ]]
    #uncover("3-")[#block[
      - ⚠️ cells *wear out* after many writes
        - bits per cell: SLC (1), MLC (2), TLC (3), QLC (4): more bits, cheaper, slower, wears faster
    ]]
  ][
    #only(1, m2-ssd(1))
    #only(2, m2-ssd(2))
    #only("3-", m2-ssd(3))
  ]

  #v(0.2em)
  #only(1)[💡 silent, small, shock resistant]
  #only(2)[💡 the DRAM chip holds the map from block numbers to places in the flash; cheaper SSDs borrow some RAM from the PC (_HMB_)]
  #only("3-")[💡 the warranty gives the writes it survives: _TBW_ (terabytes written), e.g. 600 TBW for a 1 TB TLC SSD]
]

#slide[
  == Storage Interfaces
  The protocol matters more than the shape

  #set text(size: 0.8em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.6em,
    card([🔌 SATA], height: 7.5em)[
      made for HDDs (2003), a cable \
      #tag[\~550 MB/s] \
      HDDs, 2.5" SSDs
    ],
    uncover("2-", card([⚡ NVMe], height: 7.5em)[
      made for flash, over *PCIe*, many queues \
      #tag[7 GB/s on PCIe 4.0 x4] #tag[14 GB/s on PCIe 5.0 x4] \
      every new PC and laptop
    ]),
    uncover("3-", card([📏 M.2], height: 7.5em)[
      a *slot and card shape*, not a protocol \
      carries SATA *or* NVMe \
      desktops, laptops
    ]),
    uncover("4-", card([📱 eMMC, UFS], height: 6.5em)[
      flash soldered on the board \
      #tag[up to \~4 GB/s (UFS 4)] \
      phones, cheap laptops
    ]),
    uncover("5-", card([💳 SD card, USB stick], height: 6.5em)[
      removable \
      #tag[0.1 - 1 GB/s] \
      Raspberry Pi, cameras
    ]),
  )

  #only(3, place(bottom + right, dy: -0.5em, popup(width: 250pt)[⚠️ M.2 is not a speed][an M.2 SSD may be SATA (slow) or NVMe (fast), and some M.2 slots take only one kind: read the label and the motherboard manual]))
  #set text(size: 1em / 0.8)
  #only("5-")[💡 eMMC is the old phone flash, UFS the new one]
]

// sequential read speeds in GB/s
#let ddr5-dual = 6000e6 * 8 * 2 / 1e9 // DDR5-6000, two 64-bit channels
#assert.eq(ddr5-dual, 96.0)
#let speeds = (
  ([🐢 hard disk], 0.25, [0.25 GB/s]),
  ([🔌 SATA SSD], 0.55, [0.55 GB/s]),
  ([⚡ NVMe, PCIe 3.0], 3.5, [3.5 GB/s]),
  ([⚡ NVMe, PCIe 4.0], 7, [7 GB/s]),
  ([⚡ NVMe, PCIe 5.0], 14, [14 GB/s]),
  ([🧮 RAM, DDR5], ddr5-dual, [#ddr5-dual GB/s, off the chart]),
)

#slide[
  == How Fast?
  Sequential read speed, in GB/s

  #v(0.3em)
  #only("1-5", bar-chart(speeds, 15, width: 250pt, name-width: 8.5em, size: 1em))
  #only("6-", bar-chart(speeds, 15, width: 250pt, name-width: 8.5em, size: 1em, on: 5))

  #v(0.4em)
  #only("1-5")[💡 an NVMe SSD reads in order 15 - 50 times faster than a hard disk, small random pieces thousands of times faster]
  #only("6-")[💡 RAM is still faster, and the time to its first byte (_latency_) is hundreds of times lower]
]

#slide[
  == Storage in Linux
  Each disk is a block device in `/dev`

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    #grid(
      columns: (auto, 1fr),
      row-gutter: 0.5em,
      column-gutter: 0.5em,
      align: horizon,
      tag[`/dev/sda`], [🔌 SATA, USB (disks `a`, `b`, ...)],
      tag[`/dev/nvme0n1`], [⚡ NVMe (controller 0, namespace 1)],
      tag[`/dev/mmcblk0`], [💳 SD card, eMMC],
      tag[`/dev/vda`], [📦 virtual disk in a VM],
    )
    #v(0.4em)
    #uncover("2-")[
      - partitions: `sda1`, `nvme0n1p1`, `mmcblk0p1`
    ]
  ][
    #set text(size: 0.62em)
    #reveal-terminal(before: none, lines: (8, 12), full: false)[```terminal
    $ lsblk
    NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    vda          253:0    0   26M  1 disk
    └─vda1       253:1    0   25M  1 part
    nvme0n1      259:0    0   10G  0 disk
    ├─nvme0n1p1  259:2    0  9.9G  0 part /
    └─nvme0n1p15 259:3    0   99M  0 part /boot/efi
    nvme1n1      259:1    0   10G  0 disk /sessions
    $ lsblk -d -o NAME,SIZE,ROTA,TRAN,MODEL
    NAME    SIZE ROTA TRAN   MODEL
    vda      26M    1
    nvme0n1  10G    0 nvme   Apple Virtual NVMe Controller
    nvme1n1  10G    0 nvme   Apple Virtual NVMe Controller
    ```]
  ]

  #v(0.2em)
  #only(1)[💡 `lsblk` shows the disks, their partitions and where they are mounted]
  #only("2-")[💡 `ROTA` 1 = rotating (HDD), `TRAN` = the interface; a virtual disk may report anything (`vda`)]
]
