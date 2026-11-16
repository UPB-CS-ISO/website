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

// where a time goes on the log-scale chart: 0 for 0.1 s, `w` for 10^7 s
// (8 decades); the value is the human time in s (1 ns of L1 = 1 s)
#let log-x(t, w) = (calc.log(t) + 1) / 8 * w
#assert.eq(log-x(1, 160pt), 20pt)

// a pyramid, one level per row: small and fast on top; next to it the size,
// the real access time and a log-scale bar of "if L1 took 1 s", with
// gridlines at 1 s, 1 min, 1 h, 1 day and 1 month. `shown`: levels drawn,
// `new`: the level added on this step (orange bar), none for no level
#let pyramid(shown, new: none) = {
  let h = 20pt
  let top = 18pt
  let cx = 80pt
  let width(i) = 30pt + i * 20pt
  let x0 = 278pt // where the chart starts
  let cw = 155pt // width of 8 decades
  let ticks = (([1 s], 1), ([1 min], 60), ([1 h], 3600), ([1 day], 86400), ([1 month], 2592000))
  drawing(width: 484pt, height: top + levels.len() * h + 14pt, {
    set text(size: 0.75em)
    at(172pt, 0pt, text(weight: "bold")[size])
    at(232pt, 0pt, text(weight: "bold")[real time])
    at(x0, 0pt, text(weight: "bold", fill: changed.darken(15%))[if L1 took 1 second ...])
    // the gridlines of the chart, always there (nothing moves)
    for (label, t) in ticks {
      let x = x0 + log-x(t, cw)
      wire((x, top - 2pt), (x, top + levels.len() * h + 2pt), stroke: (paint: luma(200), thickness: 0.5pt, dash: "dashed"))
      pin(x, top + levels.len() * h + 8pt, text(size: 0.85em, fill: luma(110), label))
    }
    for (i, (name, size, ns, emoji)) in levels.enumerate() {
      if i < shown {
        let y = top + i * h
        let (wt, wb) = (width(i), width(i + 1))
        let fill = if i < 4 { accent.lighten(i * 22%) } else if i == 4 { rgb("bac8d3") } else { luma(215) }
        at(0pt, y, polygon(
          fill: fill,
          stroke: 0.8pt + white,
          (cx - wt / 2, 0pt),
          (cx + wt / 2, 0pt),
          (cx + wb / 2, h),
          (cx - wb / 2, h),
        ))
        pin(cx, y + h / 2, text(weight: "bold", fill: if i < 3 { white } else { black }, name))
        at(172pt, y, box(height: h, align(horizon, size)))
        at(232pt, y, box(height: h, align(horizon, latency(ns))))
        // the bar and the human time after it
        let bw = calc.max(log-x(ns, cw), 3pt)
        let slow = i >= 4
        let on = i == new
        at(x0, y + 4pt, box(width: bw, height: h - 8pt, radius: (right: 2pt), fill: if on { changed } else { fill }, stroke: if on or i < 3 { none } else { 0.5pt + luma(140) }))
        at(x0 + bw + 4pt, y, box(height: h, align(horizon, text(weight: if slow { "bold" } else { "regular" }, fill: if on { changed.darken(15%) } else { black })[#emoji #human(ns)])))
      }
    }
  })
}

#slide[
  == The Memory Hierarchy
  Small and fast close to the CPU, large and slow far from it

  #only(1, pyramid(4))
  #only(2, pyramid(5, new: 4))
  #only(3, pyramid(6, new: 5))
  #only(4, pyramid(7, new: 6))
  #only("5-", pyramid(7))

  #only(1)[💡 a _cache_ keeps a copy of the data used recently, inside the CPU chip]
  #only(2)[💡 RAM is lost at power off (_volatile_): a coffee break for every access]
  #only(3)[💡 storage keeps the data at power off (_persistent_)]
  #only(4)[💡 waiting for a hard disk is like waiting two months for a letter]
  #only("5-", place(bottom + center, dy: 0.8em, info(width: 420pt)[Why not all as fast as L1?][
    a cache bit (SRAM) needs 6 transistors, a RAM bit (DRAM) only 1 + a capacitor: fast memory is big and expensive, so there is little of it
  ]))
]

// what a "1 TB" disk shows in GiB
#let tb-in-gib = calc.floor(1e12 / calc.pow(2, 30))
#assert.eq(tb-in-gib, 931)
#let tb-in-tib = calc.round(1e12 / calc.pow(2, 40), digits: 2)
#assert.eq(tb-in-tib, 0.91)

// a grid of memory cells: `cols` x `rows` squares of `c` (gap 2pt);
// `on`: the cells drawn orange (array of (col, row)), `off`: all cells empty
// (dashed), as after a power off
#let cells(cols, rows, c: 13pt, on: (), off: false) = {
  for r in range(rows) {
    for col in range(cols) {
      let hot = on.contains((col, r))
      at(col * (c + 2pt), r * (c + 2pt), box(
        width: c,
        height: c,
        radius: 1.5pt,
        fill: if off { white } else if hot { changed } else { accent.lighten(55%) },
        stroke: if off { (paint: luma(170), thickness: 0.6pt, dash: "dashed") } else { none },
      ))
    }
  }
}

// a panel of the RAM or Storage drawing: a frame with a title bar
#let mem-panel(x, title, color: accent) = at(x, 0pt, box(
  width: 235pt,
  height: 140pt,
  radius: 0.4em,
  clip: true,
  stroke: 1.2pt + color,
  block(width: 100%, fill: color, inset: (x: 0.5em, y: 0.3em), text(size: 1.15em, weight: "bold", fill: white, title)),
))

// RAM (the CPU reads one byte) next to storage (the CPU asks a driver for a
// whole block). `step`: 1 RAM, 2 storage, 3 power off: RAM is empty, the
// disk keeps its data
#let ram-storage(step) = drawing(width: 484pt, height: 140pt, {
  set text(size: 0.8em)
  let off = step >= 3
  // RAM: the CPU reads any byte directly
  mem-panel(0pt, [🧮 Memory (RAM)])
  at(10pt, 42pt, unit(kind: "dark", width: 50pt, height: 34pt, size: 1em)[#cpu-icon CPU])
  at(95pt, 30pt, cells(8, 4, on: ((0, 2),), off: off))
  if not off { line-arrow((60pt, 66pt), (93pt, 66pt), color: changed, thickness: 1.5pt) }
  at(10pt, 96pt, [reads *any byte*, directly])
  at(10pt, 109pt, [⚡ \~100 ns #h(0.8em) 📏 tens of GB])
  at(10pt, 122pt, if off [🔌 power off: *all lost* ❌ (_volatile_)] else [#hide[🔌]])
  // storage: through a driver, a whole block at a time
  if step >= 2 {
    mem-panel(249pt, [💾 Storage (SSD, disk)], color: rgb("8e3b00"))
    at(259pt, 42pt, unit(kind: "dark", width: 50pt, height: 34pt, size: 1em)[#cpu-icon CPU])
    line-arrow((309pt, 59pt), (322pt, 59pt))
    at(323pt, 42pt, unit(width: 50pt, height: 34pt, size: 1em, sub: [kernel])[driver])
    line-arrow((373pt, 59pt), (386pt, 59pt), color: changed, thickness: 1.5pt)
    at(388pt, 30pt, cells(6, 4, on: range(6).map(c => (c, 1))))
    at(386pt, 44pt, box(width: 92pt, height: 17pt, radius: 2pt, stroke: 1.2pt + changed))
    at(259pt, 96pt, [reads and writes a *block* (4 KiB) at a time])
    at(259pt, 109pt, [🐢 µs to ms #h(0.8em) 📏 TBs])
    if off { at(259pt, 122pt, [🔌 power off: *kept* ✅ (_persistent_)]) }
  }
})

#slide[
  == RAM or Storage?
  Two different jobs

  #only(1, ram-storage(1))
  #only(2, ram-storage(2))
  #only("3-", ram-storage(3))

  #v(0.4em)
  #uncover("4-", align(center, text(size: 1.25em, weight: "bold", fill: accent)[I bought a 1 TB disk. Why does Linux show 931G?]))

  #only("5-", place(center + horizon, info(width: 360pt)[Two ways to count][
    makers count *TB* = $10^12$ bytes, Linux counts *TiB* = $2^40$ bytes \
    1 TB = $10^12 \/ 2^40 approx #tb-in-tib$ TiB = #tb-in-gib GiB, shown as #tb-in-gib\G
  ]))
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

// a cell of the M.2 column: orange from step 3 (only the color changes)
#let m2(body) = [#only("1-2", body)#only("3-", text(fill: changed.darken(15%), weight: "bold", body))]
#let no = text(fill: luma(170))[-]

#slide[
  == Storage Interfaces
  Two separate questions: how it talks (_protocol_), and what you plug in (_shape_)

  #nice-table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    size: 0.8em,
    header: ([protocol #h(0.3em) | #h(0.3em) shape], [🗄️ drive + cable], [📏 M.2 card], [📌 soldered], [💳 removable]),
    rows: (
      ([🔌 *SATA* \ made for HDDs, \~550 MB/s], [HDDs, 2.5" SSDs], m2[M.2 SATA SSD], no, no),
      ([⚡ *NVMe* over PCIe \ made for flash, 7 - 14 GB/s], [U.2 (servers)], m2[most new SSDs], [some laptops], no),
      ([📱 *eMMC*, *UFS* \ up to \~4 GB/s], no, no, [phones, cheap laptops], no),
      ([💳 *SD*, *USB* \ 0.1 - 1 GB/s], no, no, no, [SD card, USB stick]),
    ),
    shown: (none, 2, 4, 4),
  )

  #only(1)[💡 SATA: the old protocol, from the time of the hard disks (2003)]
  #only(2)[💡 NVMe talks to the CPU over PCIe, with many queues in parallel: made for fast flash]
  #only(3)[💡 the same M.2 shape carries SATA *or* NVMe: see the next slide]
  #only("4-")[💡 eMMC is the old phone flash, UFS the new one]
]

// an M.2 card seen from above, the connector on the left. `keys`: the
// notches cut in the connector, "B" (top) and / or "M" (bottom); `on`: the
// notches and the label are orange
#let m2-card(x, y, keys, name, on: false) = {
  let ink = if on { changed } else { luma(120) }
  at(x, y, box(width: 150pt, height: 42pt, radius: (right: 6pt, left: 1pt), fill: rgb("26332c")))
  // gold fingers, 12 of them; a key removes two
  let cut = (B: (2, 3), M: (8, 9))
  let gone = keys.map(k => cut.at(k)).flatten()
  for i in range(12) {
    if i not in gone { at(x + 1pt, y + 2pt + i * 3.2pt, box(width: 9pt, height: 2.4pt, fill: rgb("d4af37"))) }
  }
  for k in keys {
    let r = cut.at(k).at(0)
    at(x - 1pt, y + 1.6pt + r * 3.2pt, box(width: 7pt, height: 6.6pt, fill: white, stroke: (right: 1pt + ink, y: 1pt + ink)))
    at(x - 34pt, y + 1pt + r * 3.2pt, text(size: 0.75em, weight: "bold", fill: ink)[#k key])
  }
  // the chips
  at(x + 22pt, y + 9pt, box(width: 30pt, height: 24pt, radius: 2pt, fill: accent))
  for j in range(2) { at(x + 60pt + j * 40pt, y + 6pt, box(width: 34pt, height: 30pt, radius: 2pt, fill: luma(60))) }
  at(x + 136pt, y + 16pt, circle(radius: 4pt, fill: white))
  at(x + 158pt, y + 6pt, box(width: 95pt, text(size: 0.75em, fill: if on { changed.darken(15%) } else { black }, name)))
}

#let m2-cards(step) = drawing(width: 285pt, height: 120pt, {
  m2-card(36pt, 4pt, ("B", "M"), on: step >= 2)[*M.2 SATA SSD* \ SATA: \~550 MB/s]
  m2-card(36pt, 70pt, ("M",), on: step >= 2)[*M.2 NVMe SSD* \ PCIe x4: 7 - 14 GB/s]
})

#slide[
  == 📏 What Is M.2?
  A shape and a slot, not a speed

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - a small *card*, 22 mm wide, in several lengths: 2242, 2260, *2280* (22 × 80 mm)
    - same size, same screw, very different speeds
    #uncover("2-")[#block[
      - the *notches* (_keys_) show what the card speaks
        - *B + M* key: usually SATA, slow
        - *M* key: NVMe, fast
    ]]
  ][
    #only(1, m2-cards(1))
    #only("2-", m2-cards(2))
  ]

  #v(0.4em)
  #only(1)[💡 the name "M.2" says nothing about the speed]
  #only(2)[💡 look at the connector: two notches (B + M) or one (M)]
  #only("3-", place(bottom + center, dy: -0.2em, popup(width: 380pt)[Check the slot too][
    an M.2 slot on the motherboard may take NVMe only, or NVMe and SATA: read the manual before you buy
  ]))
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
