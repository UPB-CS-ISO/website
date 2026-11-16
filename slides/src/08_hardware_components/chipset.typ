#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Chipset #text(size: 10pt, weight: "regular")[\ _Northbridge, southbridge and where they are today_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 8 - _Componente hardware_
  + #ward
    - Chapter 3 - _Devices_
      - Section 3.6 - _In-Depth: SCSI and the Linux Kernel_
]

// a device at the end of a link
#let dev(icon, body, on: false, width: 70pt) = unit(kind: "slot", width: width, height: 24pt, on: on, size: 0.6em)[#icon #body]

// the PC of the 2000s: CPU - northbridge - southbridge;
// `step` 1: all, 2: northbridge, 3: southbridge, 4: both (the chipset)
#let old-pc(step) = drawing(width: 300pt, height: 175pt, {
  let nb = step == 2 or step == 4
  let sb = step == 3 or step == 4
  at(110pt, 0pt, unit(kind: "dark", width: 80pt, height: 32pt, size: 0.7em, icon: cpu-icon)[CPU])
  link-line((150pt, 32pt), (150pt, 64pt), thick: true)
  at(156pt, 40pt, note[front side bus])
  at(102pt, 64pt, unit(width: 96pt, height: 36pt, on: nb, size: 0.65em, sub: [memory controller])[northbridge])
  link-line((198pt, 82pt), (226pt, 82pt), on: nb, thick: true)
  at(226pt, 70pt, dev("🧮", [RAM], on: nb))
  link-line((102pt, 82pt), (74pt, 82pt), on: nb, thick: true)
  at(4pt, 70pt, dev("🎮", [graphics], on: nb))
  link-line((150pt, 100pt), (150pt, 128pt))
  at(102pt, 128pt, unit(width: 96pt, height: 36pt, on: sb, size: 0.65em, sub: [slow I/O])[southbridge])
  link-line((102pt, 146pt), (74pt, 146pt), on: sb)
  at(4pt, 134pt, dev("🔌", [USB, audio], on: sb))
  link-line((198pt, 146pt), (226pt, 146pt), on: sb)
  at(226pt, 134pt, dev("💾", [disks, BIOS], on: sb))
  if step == 4 {
    at(96pt, 58pt, box(width: 108pt, height: 112pt, radius: 0.5em, stroke: (paint: changed, thickness: 1pt, dash: "dashed")))
  }
})

#slide[
  == Northbridge and Southbridge
  How a PC was built 20 years ago

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    - the CPU only computes, two chips around it do the rest
    #uncover("2-")[#block[
      - *northbridge* (north = close to the CPU): the fast parts
        - 🧮 RAM, 🎮 graphics card
    ]]
    #uncover("3-")[#block[
      - *southbridge*: the slow parts
        - 🔌 USB, 💾 disks, 🔊 audio, 🌐 network, BIOS
    ]]
    #uncover("4-")[#block[
      - the two together: the *chipset*
    ]]
  ][
    #for s in range(1, 5) { only(if s == 4 { "4-" } else { s }, old-pc(s)) }
  ]

  #v(0.2em)
  #only(1)[💡 the names come from the block diagram: the CPU drawn at the top, "north"]
  #only("5-", place(center + horizon, info(width: 320pt)[One more chip on the way][
    every byte from RAM went through the northbridge: more time for every access
  ]))
]

// a CPU package today: the cores and the northbridge in the same package;
// `step` 1: the package, 2: the northbridge, 3-: the links to it
#let modern-cpu(step) = scale(88%, reflow: true, drawing(width: 300pt, height: 175pt, {
  let nb = step >= 2
  at(60pt, 0pt, box(width: 180pt, height: 110pt, radius: 0.5em, fill: luma(240), stroke: 1pt + luma(140)))
  at(66pt, 3pt, text(size: 0.55em, fill: luma(80))[#cpu-icon CPU package (what you put in the socket)])
  at(70pt, 18pt, unit(kind: "dark", width: 74pt, height: 38pt, size: 0.6em, sub: [and caches])[🏎️ cores])
  at(156pt, 18pt, unit(kind: "dark", width: 74pt, height: 38pt, size: 0.6em, sub: [and caches])[🌱 cores])
  link-line((107pt, 56pt), (107pt, 64pt))
  link-line((193pt, 56pt), (193pt, 64pt))
  at(70pt, 64pt, unit(width: 160pt, height: 40pt, on: nb, size: 0.6em, sub: [🧮 memory controller · 🛣️ PCIe · 🖥️ display])[the northbridge])
  // links leaving the package
  let on3 = step >= 3
  link-line((70pt, 84pt), (40pt, 84pt), on: on3, thick: true)
  at(0pt, 60pt, dev("🧮", [RAM], on: on3, width: 54pt))
  at(0pt, 88pt, dev("🎮", [GPU x16], on: on3, width: 54pt))
  link-line((230pt, 84pt), (246pt, 84pt), on: on3, thick: true)
  at(246pt, 60pt, dev("💾", [SSD x4], on: on3, width: 54pt))
  at(246pt, 88pt, dev("🔌", [USB4], on: on3, width: 54pt))
  link-line((150pt, 104pt), (150pt, 140pt))
  at(156pt, 116pt, note[one link])
  at(105pt, 140pt, unit(kind: "slot", width: 90pt, height: 30pt, size: 0.6em, sub: [the old southbridge])[chipset])
}))

#slide[
  == Where Is the Northbridge Today?
  Still there: it moved *inside* the CPU package

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.78em)
    - one chip less between the CPU and RAM: faster
      - memory controller in the CPU: AMD since 2003, Intel since 2008
    #uncover("2-")[#block[
      - its jobs are the same, its names changed
        - Intel: _System Agent_, now the _SoC tile_
        - AMD Ryzen desktop (since 2019): the _I/O die_, a separate chip next to the core chips
    ]]
    #uncover("3-")[#block[
      - RAM, the graphics card, the first SSD and fast USB connect *directly* to it
    ]]
  ][
    #for s in range(1, 4) { only(if s == 3 { "3-" } else { s }, modern-cpu(s)) }
  ]

  #v(0.2em)
  #only(1)[💡 the package holds one or more pieces of silicon: cores and "uncore" (everything that is not a core)]
  #only(2)[💡 Linux still sees it: it is the `Host bridge` at address `00:00.0` in `lspci`]
  #only("3-")[💡 everything slower goes through the chipset]
]

// a PC today: the chipset and what hangs behind it;
// `step` 1: the CPU links, 2: the chipset link, 3: the chipset devices
#let new-pc(step) = scale(88%, reflow: true, drawing(width: 310pt, height: 175pt, {
  at(100pt, 0pt, unit(kind: "dark", width: 110pt, height: 50pt, size: 0.6em, icon: cpu-icon, sub: [cores + northbridge])[CPU])
  link-line((100pt, 14pt), (76pt, 14pt), on: step == 1, thick: true)
  at(6pt, 2pt, dev("🧮", [RAM], on: step == 1))
  link-line((100pt, 38pt), (76pt, 38pt), on: step == 1, thick: true)
  at(6pt, 28pt, dev("🎮", [GPU x16], on: step == 1))
  link-line((210pt, 14pt), (234pt, 14pt), on: step == 1, thick: true)
  at(234pt, 2pt, dev("💾", [SSD x4], on: step == 1))
  link-line((210pt, 38pt), (234pt, 38pt), on: step == 1, thick: true)
  at(234pt, 28pt, dev("🔌", [USB4], on: step == 1))
  // the chipset link
  link-line((155pt, 50pt), (155pt, 100pt), on: step == 2, thick: true)
  at(162pt, 62pt, text(size: 0.6em, fill: if step == 2 { changed } else { luma(100) })[*one* link \ Intel: DMI 4.0 x4 / x8 \ AMD: PCIe 4.0 x4])
  at(110pt, 100pt, unit(width: 90pt, height: 30pt, on: step == 2, size: 0.65em, sub: [Intel PCH, AMD B850 ...])[chipset])
  // devices behind the chipset
  link-line((110pt, 115pt), (76pt, 115pt), on: step == 3)
  at(6pt, 103pt, dev("🔌", [USB, SATA], on: step == 3))
  link-line((200pt, 115pt), (234pt, 115pt), on: step == 3)
  at(234pt, 103pt, dev("💾", [more M.2], on: step == 3))
  link-line((135pt, 130pt), (135pt, 155pt), on: step == 3)
  link-line((135pt, 155pt), (76pt, 155pt), on: step == 3)
  at(6pt, 143pt, dev("🌐", [Wi-Fi, LAN], on: step == 3))
  link-line((175pt, 130pt), (175pt, 155pt), on: step == 3)
  link-line((175pt, 155pt), (234pt, 155pt), on: step == 3)
  at(234pt, 143pt, dev("🔊", [audio, x1], on: step == 3))
}))

#slide[
  == The Chipset Today
  The old southbridge: more ports than the CPU has

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - the fast parts hang on the CPU
    #uncover("2-")[#block[
      - the *chipset* hangs on *one* link
        - Intel: _Platform Controller Hub_ (PCH)
        - AMD: B850, X870, ...
    ]]
    #uncover("3-")[#block[
      - it adds USB, SATA, M.2, network, audio, small PCIe slots
    ]]
  ][
    #for s in range(1, 4) { only(if s == 3 { "3-" } else { s }, new-pc(s)) }
  ]

  #v(0.2em)
  #only(1)[💡 fast things need short paths]
  #only(2)[💡 the link is a PCIe-like connection: \~8 GB/s (AMD, cheaper Intel boards) to \~16 GB/s (Intel Z boards)]
  #only("3-")[💡 most laptops: the chipset is in the CPU package (Intel) or inside the chip (AMD); an SoC has no chipset]
]

// a link drawn as a pipe: its thickness grows with the speed (GB/s), small
// white squares on it are the data flowing; `on` colors it orange
#let pipe(a, b, gbs, on: false, packets: 4) = {
  let col = if on { changed } else { luma(185) }
  place(top + left, line(start: a, end: b, stroke: (paint: col, thickness: gbs * 1.3pt, cap: "round")))
  if on {
    for k in range(packets) {
      let t = (k + 0.5) / packets
      let x = a.at(0) + (b.at(0) - a.at(0)) * t
      let y = a.at(1) + (b.at(1) - a.at(1)) * t
      place(top + left, dx: x - 2.5pt, dy: y - 2.5pt, box(width: 5pt, height: 5pt, fill: white, radius: 1pt))
    }
  }
}

// the data flow from the SSDs to the CPU: SSD A on its own link (top), SSD B
// and C through the chipset, sharing one link (bottom). The pipes are as
// thick as their speed. `step` 1: the direct path, 2: the shared path
#let data-flow(step) = drawing(width: 470pt, height: 122pt, {
  set text(size: 0.75em)
  let d = step == 1
  let c = step >= 2
  let label(on, body) = text(fill: if on { changed.darken(15%) } else { luma(110) }, body)
  let ssd(y, name, on) = at(0pt, y, unit(kind: "slot", width: 84pt, height: 24pt, on: on, size: 1em)[💾 #name])
  // the CPU on the right, where all the data goes
  at(392pt, 0pt, unit(kind: "dark", width: 78pt, height: 122pt, size: 1em, icon: cpu-icon)[CPU \ + RAM])
  // top: direct
  ssd(2pt, [SSD A], d)
  pipe((90pt, 14pt), (388pt, 14pt), 7, on: d, packets: 8)
  at(150pt, 24pt, label(d)[✅ *its own link*: 7 GB/s, full speed])
  // bottom: through the chipset
  ssd(50pt, [SSD B], c)
  ssd(92pt, [SSD C], c)
  pipe((90pt, 62pt), (196pt, 80pt), 7, on: c, packets: 3)
  pipe((90pt, 104pt), (196pt, 92pt), 7, on: c, packets: 3)
  at(200pt, 70pt, unit(width: 64pt, height: 32pt, on: c, size: 1em, sub: [\+ USB, LAN])[chipset])
  pipe((268pt, 86pt), (388pt, 86pt), 8, on: c, packets: 4)
  at(272pt, 104pt, label(c)[⚠️ *one shared link*: \~8 GB/s])
  at(96pt, 112pt, label(c)[7 + 7 = 14 GB/s in ⏳ waits])
})

#slide[
  == Direct or Through the Chipset?
  How the data flows from the SSDs to the CPU

  #only(1, data-flow(1))
  #only("2-", data-flow(2))

  #v(0.2em)
  #only(1)[💡 the first M.2 slot is wired to the CPU: a link only for this SSD]
  #only(2)[💡 the other M.2 slots, USB, network: all behind the chipset, all on one link]
  #uncover("3-", align(center, text(size: 1.25em, weight: "bold", fill: accent)[SSD B and C together could read 14 GB/s. Why only \~8?]))

  #only("4-", place(bottom + center, dy: 0.8em, info(width: 400pt)[The slowest link on the path decides the speed][
    two SSDs, one \~8 GB/s link above them: the narrowest pipe wins
  ]))
]

// a motherboard seen from above: the CPU socket with its RAM slots, the
// slots wired to the CPU and the ones behind the chipset.
// `step` 1: the board, 2: the graphics card slot, 3: the system M.2 slot,
// 4-: the chipset and the slots behind it
#let board(step) = drawing(width: 300pt, height: 178pt, {
  set text(size: 0.6em)
  let g = step == 2
  let m = step == 3
  let ch = step >= 4
  let ch-trace = if ch { (paint: changed, thickness: 2pt, dash: "dashed") } else { (paint: luma(120), thickness: 1pt, dash: "dashed") }
  let slot-fill(on) = if on { changed } else { luma(45) }
  at(0pt, 0pt, box(width: 300pt, height: 178pt, radius: 4pt, fill: pcb-fill, stroke: 1pt + pcb-stroke))
  // CPU and RAM
  at(130pt, 10pt, unit(kind: "dark", width: 64pt, height: 58pt, size: 1.2em, icon: cpu-icon)[CPU])
  for i in range(4) { at(214pt + i * 9pt, 8pt, box(width: 5pt, height: 66pt, fill: luma(45), radius: 1pt)) }
  at(206pt, 77pt, text(fill: luma(60))[RAM])
  // chipset
  at(238pt, 112pt, unit(width: 50pt, height: 40pt, on: ch, size: 1.1em)[chipset])
  // traces: CPU slots in orange when shown, chipset slots dashed gray
  wire((162pt, 68pt), (162pt, 112pt), stroke: if g { 2pt + changed } else { 1pt + luma(140) })
  wire((140pt, 68pt), (110pt, 90pt), stroke: if m { 2pt + changed } else { 1pt + luma(140) })
  wire((262pt, 112pt), (194pt, 50pt), stroke: (paint: luma(120), thickness: 1pt, dash: "dashed"))
  wire((238pt, 128pt), (150pt, 140pt), stroke: ch-trace)
  wire((250pt, 152pt), (210pt, 160pt), stroke: ch-trace)
  // M.2 slot 1 (CPU) and the first x16 slot (CPU)
  at(20pt, 86pt, box(width: 90pt, height: 10pt, radius: 1pt, fill: slot-fill(m)))
  at(24pt, 74pt, text(weight: "bold", fill: if m { changed.darken(15%) } else { black })[M.2 \#1: CPU])
  at(12pt, 112pt, box(width: 210pt, height: 9pt, radius: 1pt, fill: slot-fill(g)))
  at(16pt, 100pt, text(weight: "bold", fill: if g { changed.darken(15%) } else { black })[PCIe x16 \#1: CPU, all 16 lanes])
  // behind the chipset
  at(60pt, 136pt, box(width: 90pt, height: 10pt, radius: 1pt, fill: if ch { changed } else { luma(110) }))
  at(64pt, 124pt, text(weight: "bold", fill: if ch { changed.darken(15%) } else { luma(60) })[M.2 \#2: chipset])
  at(12pt, 160pt, box(width: 210pt, height: 9pt, radius: 1pt, fill: if ch { changed } else { luma(110) }))
  at(16pt, 148pt, text(weight: "bold", fill: if ch { changed.darken(15%) } else { luma(60) })[PCIe x16 size \#2: chipset, only x4])
})

#slide[
  == 👍 Which Slot?
  Put the fast parts on the slots wired to the CPU

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - the slots *look* the same, but are wired to different chips
    #uncover("2-")[#block[- 🎮 graphics card: the *first* x16 slot, closest to the CPU]]
    #uncover("3-")[#block[- 💾 system SSD: the *first* M.2 slot]]
    #uncover("4-")[#block[- the others hang on the chipset: fine for a second disk, Wi-Fi, a sound card]]
  ][
    #only(1, board(1))
    #only(2, board(2))
    #only(3, board(3))
    #only("4-", board(4))
  ]

  #v(0.2em)
  #only(1)[💡 a long slot is not always a fast slot: an x16 slot may have only 4 lanes wired]
  #only(2)[💡 the GPU needs the most bandwidth: 16 lanes straight to the CPU]
  #only(3)[💡 the system disk is read all the time: its own link, no sharing]
  #only("4-")[📖 the motherboard manual has a table: for each slot, CPU or chipset, and how many lanes]
]
