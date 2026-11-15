#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The Computer #text(size: 10pt, weight: "regular")[\ _Its main parts, and two ways to put them together_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 1 - _The Big Picture_
      - Section 1.2 - _Hardware: Understanding Main Memory_
  + #uso-book
    - Chapter 8 - _Componente hardware_
  + #patterson
    - Chapter 1 - _Computer Abstractions and Technology_
]

// the main parts of a computer around the links that connect them;
// `step` selects the orange part: 1 CPU, 2 RAM, 3 storage, 4 input,
// 5 output, 6 the links, 7 power and firmware
#let components(step) = drawing(width: 460pt, height: 168pt, {
  let part(x, y, n, icon, name, role, ex, w: 104pt) = at(x, y, unit(
    width: w,
    height: 56pt,
    on: step == n,
    size: 0.76em,
    icon: icon,
    sub: [#role \ #text(fill: luma(100))[#ex]],
    name,
  ))
  // the links in the middle
  let lc = step == 6
  link-line((10pt, 84pt), (450pt, 84pt), on: lc, thick: true)
  for x in (54pt, 172pt, 290pt, 408pt) { link-line((x, 58pt), (x, 84pt), on: lc) }
  for x in (54pt, 172pt, 290pt, 408pt) { link-line((x, 84pt), (x, 110pt), on: lc) }
  pin(113pt, 84pt, box(fill: white, inset: (x: 3pt, y: 1pt), text(size: 0.65em, weight: "bold", fill: if lc { changed } else { luma(90) })[links (buses)]))
  // above the links
  part(2pt, 4pt, 1, cpu-icon, [CPU (processor)], [runs the instructions], [4 to 24 cores])
  part(120pt, 4pt, 2, "🧮", [RAM (memory)], [the running programs], [16 GB, lost at power off])
  part(238pt, 4pt, 3, "💾", [storage], [the files], [1 TB SSD, kept at power off])
  part(356pt, 4pt, 7, "⚡", [power + firmware], [energy; starts the PC], [power supply, UEFI])
  // below the links
  part(2pt, 110pt, 4, "⌨️", [input], [data comes in], [keyboard, mouse, camera])
  part(120pt, 110pt, 5, "🖥️", [output], [data goes out], [screen, speakers])
  part(238pt, 110pt, 5, "🌐", [network], [in and out], [Wi-Fi, Ethernet])
  part(356pt, 110pt, 4, "🔌", [USB devices], [in and out], [stick, printer])
})

#slide[
  == The Main Components
  Every computer, from a phone to a server, has the same parts

  #for s in range(1, 8) { only(if s == 7 { "7-" } else { s }, components(s)) }

  #only("8-", place(bottom + center, dy: 1.6em, info(width: 430pt)[Input and output (I/O)][
    everything that is not CPU or RAM is a _device_: the OS talks to it through a *driver*
  ]))
]

#slide[
  == Two Ways to Build It
  Many chips on a board, or one chip with almost everything

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    card([🖥️ PC])[
      #set text(size: 0.85em)
      separate chips and cards (CPU, RAM, GPU, SSD), connected by a *motherboard*
    ],
    uncover("2-", card([📱 SoC: System on a Chip])[
      #set text(size: 0.85em)
      CPU, GPU, memory controller and I/O inside *one chip*, RAM right next to it
    ]),
  )

  #only("3-", place(bottom + center, dy: -0.2em, info(width: 340pt)[Which is which?][
    a desktop is a PC, a phone is an SoC, a laptop is ... more and more an SoC
  ]))
]

// A desktop motherboard seen from above; `step` selects what is orange:
// 1 the board, 2 CPU socket, 3 RAM, 4 PCIe and M.2, 5 chipset and firmware,
// 6 connectors
#let motherboard(step) = scale(88%, reflow: true, drawing(width: 280pt, height: 176pt, {
  at(0pt, 0pt, box(width: 280pt, height: 176pt, radius: 4pt, fill: pcb-fill, stroke: (
    if step == 1 { 2pt + changed } else { 1pt + pcb-stroke }
  )))
  // copper traces, to suggest the wires of the board
  for (a, b) in (
    ((116pt, 50pt), (126pt, 50pt)),
    ((80pt, 88pt), (80pt, 98pt)),
    ((80pt, 114pt), (80pt, 122pt)),
    ((134pt, 106pt), (200pt, 112pt)),
    ((170pt, 129pt), (200pt, 129pt)),
    ((222pt, 140pt), (222pt, 148pt)),
    ((244pt, 118pt), (254pt, 118pt)),
  ) { wire(a, b, stroke: 1.5pt + rgb("c9a227")) }
  at(6pt, 6pt, unit(kind: "slot", width: 30pt, height: 82pt, on: step == 6, size: 0.55em)[🔌 \ USB \ LAN \ audio \ video])
  at(44pt, 6pt, unit(width: 72pt, height: 18pt, on: step == 2, size: 0.55em)[⚡ power for the CPU])
  at(44pt, 28pt, unit(kind: "dark", width: 72pt, height: 60pt, on: step == 2, size: 0.65em, icon: cpu-icon)[CPU socket])
  for i in range(4) {
    at(126pt + i * 12pt, 6pt, box(width: 8pt, height: 82pt, radius: 1pt, fill: if step == 3 { changed-fill } else {
      white
    }, stroke: if step == 3 { 1.5pt + changed } else { 0.8pt + luma(140) }))
  }
  at(122pt, 90pt, text(size: 0.5em, weight: "bold", fill: if step == 3 { changed } else { luma(60) })[🧮 RAM slots])
  at(180pt, 6pt, unit(kind: "slot", width: 14pt, height: 60pt, on: step == 6, size: 0.5em, rotate(
    -90deg,
    reflow: true,
  )[power in]))
  at(44pt, 98pt, unit(kind: "slot", width: 90pt, height: 16pt, on: step == 4, size: 0.55em)[💾 M.2 (SSD)])
  at(10pt, 122pt, unit(kind: "slot", width: 160pt, height: 14pt, on: step == 4, size: 0.55em)[🎮 PCIe x16 (graphics card)])
  at(10pt, 146pt, unit(kind: "slot", width: 64pt, height: 14pt, on: step == 4, size: 0.5em)[PCIe x1])
  at(200pt, 96pt, unit(width: 44pt, height: 44pt, on: step == 5, size: 0.6em)[chipset])
  at(200pt, 148pt, unit(width: 44pt, height: 22pt, on: step == 5, size: 0.5em)[📜 UEFI \ flash])
  at(254pt, 96pt, unit(kind: "slot", width: 18pt, height: 44pt, on: step == 6, size: 0.5em, rotate(
    -90deg,
    reflow: true,
  )[SATA]))
  at(254pt, 148pt, unit(kind: "slot", width: 18pt, height: 22pt, on: step == 6, size: 0.45em)[front])
}))

#slide[
  == The Motherboard
  A board that holds and connects the parts of a PC

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - a *printed circuit board* (PCB): copper wires in layers of fiberglass
    #uncover("2-")[#block[- #cpu-icon *CPU socket* + its power stage]]
    #uncover("3-")[#block[- 🧮 *RAM slots* for _DIMM_ modules]]
    #uncover("4-")[#block[- 🎮 *PCIe* and 💾 *M.2* slots: graphics card, SSD]]
    #uncover("5-")[#block[- *chipset* + 📜 *firmware* chip (UEFI)]]
    #uncover("6-")[#block[- 🔌 connectors: USB, network, audio, SATA, power]]
  ][
    #for s in range(1, 7) {
      only(if s == 6 { "6-" } else { s }, motherboard(s))
    }
  ]

  #v(0.2em)
  #only(1)[💡 sizes (_form factors_): ATX 30.5 × 24.4 cm, micro-ATX 24.4 × 24.4 cm, mini-ITX 17 × 17 cm]
  #only(2)[💡 a socket fits one CPU family only, e.g. AMD `AM5`, Intel `LGA 1851`: check before you buy]
  #only(3)[💡 you can add or replace RAM modules; the board decides the type (DDR4 or DDR5) and the maximum]
  #only(4)[💡 slots let you add or change parts: this is why a PC can be upgraded]
  #only(5)[💡 the firmware starts the computer, then it starts the operating system]
  #only("6-")[💡 the back connectors are soldered on the board, the front ones are wired to the case]
]

// A System on a Chip: every block inside one die, the RAM next to it on the
// same package. `step` 1: nothing, 2: CPU cores, 3: coprocessors,
// 4: memory and I/O
#let soc(step) = scale(88%, reflow: true, drawing(width: 280pt, height: 170pt, {
  at(0pt, 0pt, box(width: 280pt, height: 170pt, radius: 5pt, fill: luma(238), stroke: 1pt + luma(150)))
  at(6pt, 3pt, text(size: 0.5em, fill: luma(90))[package])
  // the die
  at(8pt, 16pt, box(width: 196pt, height: 146pt, radius: 0.4em, fill: white, stroke: 1.2pt + accent, clip: true, block(
    width: 100%,
    fill: accent,
    inset: (x: 0.5em, y: 0.25em),
    text(size: 0.6em, fill: white, weight: "bold")[SoC: one piece of silicon],
  )))
  at(14pt, 36pt, unit(width: 90pt, height: 32pt, on: step == 2, size: 0.55em)[🏎️ CPU \ performance cores])
  at(108pt, 36pt, unit(width: 90pt, height: 32pt, on: step == 2, size: 0.55em)[🌱 CPU \ efficiency cores])
  at(14pt, 72pt, unit(width: 90pt, height: 30pt, on: step == 3, size: 0.55em)[🎮 GPU])
  at(108pt, 72pt, unit(width: 43pt, height: 30pt, on: step == 3, size: 0.55em)[🤖 NPU])
  at(155pt, 72pt, unit(width: 43pt, height: 30pt, on: step == 3, size: 0.5em)[🎬 video])
  at(14pt, 106pt, unit(width: 60pt, height: 26pt, on: step == 4, size: 0.5em)[🧮 memory \ controller])
  at(78pt, 106pt, unit(width: 60pt, height: 26pt, on: step == 4, size: 0.5em)[🔌 USB, PCIe, \ display])
  at(142pt, 106pt, unit(width: 56pt, height: 26pt, on: step == 3, size: 0.5em)[📷 camera, \ 🔊 audio])
  at(14pt, 136pt, unit(kind: "slot", width: 184pt, height: 20pt, on: step == 4, size: 0.5em)[shared cache · 🔒 security (keys, encryption)])
  // RAM on the package
  at(214pt, 22pt, unit(kind: "slot", width: 56pt, height: 64pt, on: step == 4, size: 0.55em, icon: "🧮")[RAM])
  at(214pt, 94pt, unit(kind: "slot", width: 56pt, height: 64pt, on: step == 4, size: 0.55em, icon: "🧮")[RAM])
}))

#slide[
  == System on a Chip (SoC)
  Almost the whole computer in one chip

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - one piece of silicon (_die_) with many blocks
    #uncover("2-")[#block[- #cpu-icon *CPU cores*, often two kinds]]
    #uncover("3-")[#block[- *coprocessors*: 🎮 GPU, 🤖 NPU, 🎬 video, 📷 camera]]
    #uncover("4-")[#block[- 🧮 *memory controller* and 🔌 *I/O*; the RAM is soldered right next to the chip]]
  ][
    #for s in range(1, 5) {
      only(if s == 4 { "4-" } else { s }, soc(s))
    }
  ]

  #v(0.2em)
  #only(1)[💡 the wires between the blocks are microscopic: faster and using much less power than wires on a board]
  #only(2)[💡 fast cores for work, frugal cores for the background (more in the next section)]
  #only(3)[💡 _coprocessors_: special hardware for one kind of job (later in this lecture)]
  #only("4-")[💡 the phone board holds the SoC, the storage, the modem, the power chip and the connectors]
]

#slide[
  == SoCs Around You
  Not only phones

  #set text(size: 0.78em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.8em,
    row-gutter: 0.6em,
    card([📱 Phones and tablets])[Apple A, Qualcomm Snapdragon, MediaTek Dimensity, Samsung Exynos],
    uncover("2-", card([💻 Laptops])[Apple M (MacBook), Qualcomm Snapdragon X (Windows on ARM)]),
    uncover("3-", card([🍓 Raspberry Pi 5])[Broadcom BCM2712: 4 Arm Cortex-A76 cores and a GPU, on a credit card sized board]),
    uncover("4-", card([🎮 Game consoles])[PlayStation 5, Xbox Series: one custom AMD chip with x86-64 cores and the GPU]),
  )

  #v(0.4em)
  #set text(size: 1em / 0.78)
  #only("2-3")[💡 SoCs are not only ARM: the PS5 and Xbox SoCs are x86-64 (the Nintendo Switch 2 is ARM)]
  #only("4-")[💡 the PS5 and the Xbox use one fast memory (GDDR6) for both the CPU and the GPU: _unified memory_]
]

#slide[
  == PC or SoC?
  Upgrades and choice, or size and battery

  #set text(size: 0.8em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    card([🖥️ PC (motherboard)])[
      ✅ change the CPU, RAM, GPU, SSD \
      ✅ repair: replace one part \
      ✅ huge power for games and AI \
      ❌ big, 100 - 1000 W \
      ❌ a graphics card needs its own memory
    ],
    uncover("2-", card([📱 SoC])[
      ✅ small, a few W to \~100 W, long battery \
      ✅ one memory shared by everyone \
      ✅ fast links inside the chip \
      ❌ upgrade almost nothing, RAM is soldered \
      ❌ repair: replace the whole board
    ]),
  )

  #v(0.4em)
  #set text(size: 1em / 0.8)
  #uncover("3-")[
    #tip[💡 the line blurs: today's x86 CPUs hold the memory controller, PCIe and a GPU; laptop chips (Intel Core Ultra, AMD Ryzen AI) are almost SoCs]
  ]
  #v(0.2em)
  #question(4)[Your laptop has 16 GB of RAM. Can you add 16 GB more?][💡 only if it has a free RAM slot: check this *before* you buy]
]

// CPU and GPU with separate memories (PC) or one shared memory (SoC);
// `step` 2 shows where the data goes
#let memories(unified, step) = drawing(width: 200pt, height: 125pt, {
  if not unified {
    at(0pt, 0pt, unit(icon: cpu-icon, width: 70pt, height: 40pt, size: 0.7em)[CPU])
    at(120pt, 0pt, unit(icon: "🎮", width: 80pt, height: 40pt, size: 0.7em)[GPU])
    at(0pt, 72pt, unit(kind: "slot", icon: "🧮", width: 70pt, height: 36pt, size: 0.7em)[RAM])
    at(120pt, 72pt, unit(kind: "slot", icon: "⚡", width: 80pt, height: 36pt, on: step >= 2, size: 0.7em)[VRAM])
    link-line((35pt, 40pt), (35pt, 72pt))
    link-line((160pt, 40pt), (160pt, 72pt))
    line-arrow((70pt, 90pt), (120pt, 90pt), color: if step >= 2 { changed } else { luma(150) }, thickness: 2pt)
    pin(95pt, 117pt, note(color: if step >= 2 { changed } else { luma(100) })[📋 copy over PCIe])
  } else {
    at(0pt, 0pt, unit(icon: cpu-icon, width: 60pt, height: 40pt, size: 0.7em)[CPU])
    at(70pt, 0pt, unit(icon: "🎮", width: 60pt, height: 40pt, size: 0.7em)[GPU])
    at(140pt, 0pt, unit(icon: "🤖", width: 60pt, height: 40pt, size: 0.7em)[NPU])
    at(0pt, 72pt, unit(kind: "slot", icon: "🧮", width: 200pt, height: 36pt, on: step >= 2, size: 0.7em)[one RAM for all])
    for x in (30pt, 100pt, 170pt) { link-line((x, 40pt), (x, 72pt), on: step >= 2) }
    pin(100pt, 117pt, note(color: if step >= 2 { changed } else { luma(100) })[no copy: all see the same data])
  }
})

#slide[
  == Unified Memory
  In an SoC, the CPU and the GPU share the same RAM

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #align(center, text(size: 0.85em, weight: "bold")[🖥️ PC with a graphics card])
    #only(1, memories(false, 1))
    #only("2-", memories(false, 2))
  ][
    #align(center, text(size: 0.85em, weight: "bold")[📱 SoC])
    #only(1, memories(true, 1))
    #only("2-", memories(true, 2))
  ]

  #v(0.2em)
  #only(1)[💡 a graphics card has its own, very fast memory: _VRAM_]
  #only("2-")[💡 a PC copies the data to the GPU first; an SoC does not, but the GPU shares the RAM speed and size with everyone]
]
