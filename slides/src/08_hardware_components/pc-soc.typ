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

  #for s in range(1, 8) { only(s, components(s)) }
  #only("8-", components(0))

  #only("8-", place(center + horizon, dy: 1em, popup(width: 330pt, kind: "info")[Devices and drivers][
    #set text(size: 1.15em)
    #align(center)[
      everything that is not CPU or RAM is a *device*
      #v(0.3em)
      #grid(
        columns: 5,
        column-gutter: 0.4em,
        align: horizon,
        tool-box("🐧 OS", sub: [Linux]),
        draw-arrow(length: 1.4em),
        tool-box("driver", sub: [`nvme`, `usbhid`, ...], on: true),
        draw-arrow(length: 1.4em),
        tool-box("device", sub: [SSD, keyboard, ...], fill: white),
      )
      #v(0.2em)
      #text(size: 0.85em)[the OS talks to every device through its *driver*]
    ]
  ]))
]

// a PC: separate chips and cards on a board, connected by copper traces
#let pc-drawing = drawing(width: 220pt, height: 112pt, {
  at(0pt, 0pt, box(width: 220pt, height: 112pt, radius: 4pt, fill: pcb-fill, stroke: 1pt + pcb-stroke))
  at(6pt, 3pt, text(size: 0.55em, fill: pcb-stroke, weight: "bold")[motherboard])
  let trace(a, b) = wire(a, b, stroke: 1.5pt + rgb("c9a227"))
  trace((62pt, 38pt), (92pt, 38pt))
  trace((36pt, 60pt), (36pt, 76pt))
  trace((80pt, 90pt), (130pt, 90pt))
  trace((128pt, 38pt), (160pt, 38pt))
  at(10pt, 16pt, unit(kind: "dark", width: 52pt, height: 44pt, size: 0.65em, icon: cpu-icon)[CPU])
  for i in range(3) { at(94pt + i * 12pt, 14pt, box(width: 8pt, height: 46pt, radius: 1pt, fill: white, stroke: 0.8pt + luma(130))) }
  at(92pt, 62pt, text(size: 0.5em, weight: "bold")[🧮 RAM])
  at(160pt, 16pt, unit(kind: "slot", width: 52pt, height: 44pt, size: 0.6em)[🎮 GPU \ card])
  at(10pt, 76pt, unit(kind: "slot", width: 70pt, height: 28pt, size: 0.6em)[💾 SSD])
  at(130pt, 76pt, unit(width: 50pt, height: 28pt, size: 0.6em)[chipset])
})

// an SoC: one chip with everything inside, the RAM next to it
#let soc-drawing = drawing(width: 220pt, height: 112pt, {
  at(0pt, 0pt, box(width: 220pt, height: 112pt, radius: 4pt, fill: luma(238), stroke: 1pt + luma(150)))
  at(6pt, 3pt, text(size: 0.55em, fill: luma(90), weight: "bold")[one package])
  at(10pt, 14pt, box(width: 146pt, height: 92pt, radius: 0.4em, fill: white, stroke: 1.2pt + accent, clip: true, block(
    width: 100%,
    fill: accent,
    inset: (x: 0.4em, y: 0.2em),
    text(size: 0.55em, fill: white, weight: "bold")[one chip],
  )))
  at(16pt, 32pt, unit(width: 66pt, height: 22pt, size: 0.55em)[#cpu-icon CPU])
  at(86pt, 32pt, unit(width: 64pt, height: 22pt, size: 0.55em)[🎮 GPU])
  at(16pt, 58pt, unit(width: 42pt, height: 22pt, size: 0.5em)[🤖 NPU])
  at(62pt, 58pt, unit(width: 42pt, height: 22pt, size: 0.5em)[🎬 video])
  at(108pt, 58pt, unit(width: 42pt, height: 22pt, size: 0.5em)[🔌 I/O])
  at(16pt, 84pt, unit(kind: "slot", width: 134pt, height: 17pt, size: 0.5em)[memory controller, cache])
  at(164pt, 14pt, unit(kind: "slot", width: 48pt, height: 44pt, size: 0.55em, icon: "🧮")[RAM])
  at(164pt, 62pt, unit(kind: "slot", width: 48pt, height: 44pt, size: 0.55em, icon: "🧮")[RAM])
})

// one way to build a computer: a title bar, the drawing and where it is used
#let way(title, sub, drawing, where, color: accent) = box(
  width: 100%,
  radius: 0.5em,
  clip: true,
  stroke: 1.2pt + color,
  fill: white,
  {
    block(width: 100%, fill: color, inset: (x: 0.6em, y: 0.35em), below: 0pt, {
      text(size: 1.15em, weight: "bold", fill: white, title)
      h(1fr)
      text(size: 0.8em, fill: white, sub)
    })
    block(width: 100%, inset: (x: 0.5em, y: 0.5em), above: 0pt, below: 0pt, drawing)
    block(width: 100%, fill: color.lighten(88%), stroke: (top: 0.6pt + color), inset: (y: 0.4em), above: 0pt, align(
      center,
      text(size: 0.85em, fill: color, weight: "bold", where),
    ))
  },
)

#slide[
  == Two Ways to Build It
  Many chips on a board, or one chip with almost everything

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.8em,
    way([🖥️ PC], [separate chips and cards], pc-drawing, [🖥️ desktops, 🗄️ servers, gaming laptops], color: rgb("c26a2f")),
    uncover("2-", way([📱 SoC], [System on a Chip], soc-drawing, [📱 phones, 🍎 Macs, 🍓 Raspberry Pi, 🎮 consoles])),
  )

  #only("3-", place(bottom + center, dy: 1.4em, info(width: 340pt)[And laptops?][
    more and more of them are built around an SoC
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
    #v(0.3em)
    // the same block on an Apple M chip (MacBook)
    #block(
      width: 100%,
      height: 5.6em,
      inset: (x: 0.6em, y: 0.45em),
      radius: 0.3em,
      fill: luma(238),
      stroke: (left: 3pt + luma(90)),
      {
        set text(size: 0.9em)
        let m(body) = [#text(weight: "bold", fill: luma(50))[💻 Apple M4 (MacBook):] #body]
        only(1, m[one SoC for the whole laptop])
        only(2, m[4 performance cores + 6 efficiency cores (ARM)])
        only(3, m[a 10-core GPU, a 16-core *Neural Engine* (NPU), a media engine for video])
        only("4-", m[the RAM sits *on the package*, shared by the CPU, the GPU and the NPU (_unified memory_); a *Secure Enclave* keeps the keys])
      },
    )
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

  #nice-table(
    columns: (auto, 1fr, auto),
    header: ([where], [SoC], [CPU ISA]),
    rows: (
      ([📱 *phones, tablets*], [Apple A, Snapdragon, Dimensity, Exynos], [ARM]),
      ([💻 *laptops*], [Apple M (MacBook), Snapdragon X (Windows)], [ARM]),
      ([🍓 *Raspberry Pi 5*], [Broadcom BCM2712: 4 Arm Cortex-A76 cores and a GPU], [ARM]),
      ([🎮 *PlayStation 5, Xbox Series*], [custom AMD chip, GDDR6 shared by CPU and GPU], [*x86-64*]),
      ([🎮 *Nintendo Switch 2*], [one custom NVIDIA chip], [ARM]),
    ),
    shown: (none, 2, 3, 4, 4),
  )

  #only("5-", place(bottom + center, dy: 0.8em, popup(width: 330pt, kind: "info")[Not only ARM][
    most SoCs are ARM, but the PS5 and Xbox SoCs are x86-64
  ]))
]

#slide[
  == PC or SoC?
  Upgrades and choice, or size and battery

  #nice-table(
    columns: (auto, 1fr, 1fr),
    header: ([], [🖥️ PC (motherboard)], [📱 SoC]),
    rows: (
      ([*upgrade*], [✅ change the CPU, RAM, GPU, SSD], [❌ almost nothing, the RAM is soldered]),
      ([*repair*], [✅ replace one part], [❌ replace the whole board]),
      ([*power*], [❌ 100 - 1000 W], [✅ a few W to \~100 W, long battery]),
      ([*memory*], [❌ a graphics card needs its own memory], [✅ one memory shared by everyone]),
      ([*size*], [❌ a box], [✅ a phone, a thin laptop]),
      ([*speed*], [✅ huge power for games and AI], [✅ fast links inside the chip]),
    ),
  )

  #only("2-", place(bottom + center, dy: -0.2em, popup(width: 380pt, kind: "tip")[The line blurs][
    today's x86 CPUs hold the memory controller, PCIe and a GPU; laptop chips (Intel Core Ultra, AMD Ryzen AI) are almost SoCs
  ]))
]

// a piece of data (an image to draw), as a small orange tag
#let data-tag = box(inset: (x: 3pt, y: 2pt), radius: 2pt, fill: changed-fill, stroke: 0.8pt + changed, text(
  size: 0.6em,
  weight: "bold",
  fill: changed.darken(15%),
)[🖼️ image])

// PC: CPU and GPU with separate memories, the data is copied over PCIe
#let pc-memories = drawing(width: 205pt, height: 92pt, {
  at(0pt, 0pt, unit(icon: cpu-icon, width: 70pt, height: 32pt, size: 0.7em)[CPU])
  at(125pt, 0pt, unit(icon: "🎮", width: 80pt, height: 32pt, size: 0.7em, sub: [graphics card])[GPU])
  at(0pt, 54pt, unit(kind: "slot", width: 82pt, height: 38pt, size: 0.7em)[🧮 RAM #h(0.3em) #data-tag])
  at(125pt, 54pt, unit(kind: "slot", width: 80pt, height: 38pt, size: 0.7em)[⚡ VRAM #h(0.3em) #data-tag])
  link-line((35pt, 32pt), (35pt, 54pt))
  link-line((165pt, 32pt), (165pt, 54pt))
  line-arrow((83pt, 70pt), (124pt, 70pt), color: changed, thickness: 2pt)
  pin(103pt, 60pt, text(size: 0.6em, weight: "bold", fill: changed)[copy])
  pin(103pt, 80pt, text(size: 0.55em, fill: changed)[over PCIe])
})

// SoC: one memory for everyone, nothing to copy
#let soc-memories = drawing(width: 205pt, height: 92pt, {
  at(0pt, 0pt, unit(icon: cpu-icon, width: 62pt, height: 32pt, size: 0.7em)[CPU])
  at(71pt, 0pt, unit(icon: "🎮", width: 62pt, height: 32pt, size: 0.7em)[GPU])
  at(142pt, 0pt, unit(icon: "🤖", width: 62pt, height: 32pt, size: 0.7em)[NPU])
  at(0pt, 54pt, unit(kind: "slot", width: 205pt, height: 38pt, size: 0.7em)[🧮 one RAM for all #h(0.6em) #data-tag])
  for x in (31pt, 102pt, 173pt) { link-line((x, 32pt), (x, 54pt), on: true) }
})

#slide[
  == Unified Memory
  In an SoC, the CPU and the GPU share the same RAM

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.8em,
    way([🖥️ PC], [CPU and GPU: two memories], pc-memories, [the image is copied to the GPU first], color: rgb("c26a2f")),
    uncover("2-", way([📱 SoC], [one memory for all], soc-memories, [no copy: everyone sees the same image])),
  )

  #only("3-", place(bottom + center, dy: 1.2em, popup(width: 420pt, kind: "info")[The trade-off][
    a graphics card has its own, very fast memory (_VRAM_); in an SoC the GPU shares the RAM speed and size with everyone
  ]))
]
