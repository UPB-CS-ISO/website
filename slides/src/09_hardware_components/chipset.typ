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
  #only("4-")[💡 every byte from RAM went through the northbridge: one more chip on the way, more time]
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

// two SSDs behind the chipset send their data up the same link;
// `step` 2 colors the path
#let bottleneck(step) = scale(88%, reflow: true, drawing(width: 230pt, height: 150pt, {
  let on = step >= 2
  at(70pt, 0pt, unit(kind: "dark", width: 90pt, height: 34pt, size: 0.65em, icon: cpu-icon)[CPU + RAM])
  line-arrow((115pt, 80pt), (115pt, 36pt), color: if on { changed } else { luma(150) }, thickness: 3pt, head: 8pt)
  at(122pt, 46pt, text(size: 0.65em, weight: "bold", fill: if on { changed } else { luma(80) })[\~8 GB/s up \ for everything])
  at(70pt, 80pt, unit(width: 90pt, height: 26pt, size: 0.65em)[chipset])
  line-arrow((50pt, 122pt), (88pt, 107pt), color: if on { changed } else { luma(150) }, thickness: 1.5pt)
  line-arrow((180pt, 122pt), (142pt, 107pt), color: if on { changed } else { luma(150) }, thickness: 1.5pt)
  at(0pt, 122pt, dev("💾", [SSD 1: 7 GB/s], on: on, width: 90pt))
  at(140pt, 122pt, dev("💾", [SSD 2: 7 GB/s], on: on, width: 90pt))
}))

#slide[
  == Direct or Through the Chipset?
  Everything behind the chipset shares one link

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - two NVMe SSDs behind the chipset, 7 GB/s each
    #uncover("2-")[#block[
      - read both at the same time: all the data goes *up* the same link
        - plus USB, network, ... at the same time
    ]]
    #uncover("4-")[
      === 👍 Rules of thumb
      - 🎮 graphics card in the *first* x16 slot (CPU)
      - 💾 system SSD in the *first* M.2 slot (CPU)
      - 📖 the motherboard manual says which slot goes where
    ]
  ][
    #only(1, bottleneck(1))
    #only("2-", bottleneck(2))
  ]

  #v(0.2em)
  #question(2)[Together they could read 14 GB/s. Why only \~8?][💡 the slowest link on the path decides the speed]
]

#slide[
  == See the Topology
  `lspci` lists the devices on the PCI Express buses

  #toolbox.side-by-side(columns: (1fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - `lspci`: one line per device
      - `bus:device.function`
      - class and maker
    #uncover("2-")[#block[
      - `lspci -tv`: as a tree
    ]]
  ][
    #set text(size: 0.62em)
    #reveal-terminal(before: none, lines: (9, 15), full: false)[```terminal
    $ lspci
    00:00.0 Host bridge: Apple Inc. Device 1a05
    00:01.0 Ethernet controller: Red Hat, Inc. Virtio network device (rev 01)
    00:05.0 Non-Volatile memory controller: Apple Inc. Device 1a09
    00:06.0 Non-Volatile memory controller: Apple Inc. Device 1a09
    ...
    00:0a.0 Display controller: Red Hat, Inc. Virtio GPU (rev 01)
    ...
    00:0e.0 USB controller: Apple Inc. Device 1a06
    $ lspci -tv
    -[0000:00]-+-00.0  Apple Inc. Device 1a05
               +-01.0  Red Hat, Inc. Virtio network device
               +-05.0  Apple Inc. Device 1a09
               +-06.0  Apple Inc. Device 1a09
    ...
    ```]
  ]

  #v(0.2em)
  #only(1)[💡 `00:00.0 Host bridge`: the northbridge, here a virtual one (a VM on a Mac, the devices are made up)]
  #only("2-")[💡 on a real PC the tree has more levels: the `PCI bridge` lines are the ports where the slots and the chipset hang]
]
