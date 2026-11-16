#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Coprocessors #text(size: 10pt, weight: "regular")[\ _Special hardware for special jobs_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #patterson
    - Chapter 6 - _Parallel Processors from Client to Cloud_
  + #uso-book
    - Chapter 8 - _Componente hardware_
]

// ---------------------------------------------------------------------------
// Shared drawings (the same building blocks as the processor section)
// ---------------------------------------------------------------------------

// the frame of a chip, with its title bar, as the background of a drawing
#let chip(width, height, title, color: accent, x: 0pt) = at(x, 0pt, box(
  width: width,
  height: height,
  radius: 0.4em,
  fill: white,
  stroke: 1.2pt + color,
  clip: true,
  block(width: 100%, fill: color, inset: (x: 0.5em, y: 0.3em), text(size: 0.7em, fill: white, weight: "bold", title)),
))

// a job running on a unit: a small orange tag
#let job-tag(body) = box(inset: (x: 3pt, y: 2pt), radius: 2pt, fill: changed-fill, stroke: 0.6pt + changed, text(
  size: 0.6em,
  fill: changed.darken(15%),
  body,
))

// a panel with a big title, a few lines and a footer (like CISC / RISC)
#let side-panel(title, sub, footer, body, color: accent, height: 120pt) = box(
  width: 100%,
  height: height,
  radius: 0.5em,
  clip: true,
  stroke: 1.2pt + color,
  fill: white,
  {
    block(width: 100%, fill: color, inset: (x: 0.6em, y: 0.35em), below: 0pt, {
      text(size: 1.2em, weight: "bold", fill: white, title)
      h(1fr)
      text(size: 0.8em, fill: white, sub)
    })
    block(width: 100%, inset: (x: 0.6em, y: 0.5em), above: 0pt, below: 0pt, text(size: 0.8em, body))
    place(bottom, block(width: 100%, height: 22pt, fill: color.lighten(88%), stroke: (top: 0.6pt + color), align(
      center + horizon,
      text(size: 0.8em, weight: "bold", fill: color, footer),
    )))
  },
)

// ---------------------------------------------------------------------------
// Why coprocessors?
// ---------------------------------------------------------------------------

#slide[
  == Why Coprocessors?
  The CPU can do anything, but not everything fast

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.8em,
    side-panel([#cpu-icon CPU], [general purpose], [runs the OS and your programs])[
      - a few *strong* cores
      - good at code full of decisions: `if`, loops, function calls
      - can do *any* job, one step after the other
    ],
    uncover("2-", side-panel([🛠️ Coprocessor], [special purpose], [10 - 100 × faster, less energy], color: rgb("8e3b00"))[
      - many *simple* units
      - built for *one kind* of work
      - often: the same math on lots of data
    ]),
  )

  #v(0.4em)
  #uncover("3-", align(center, grid(
    columns: 6,
    column-gutter: 0.5em,
    unit(icon: "🎮", width: 66pt, height: 46pt, size: 0.75em, sub: [graphics])[GPU],
    unit(icon: "🤖", width: 66pt, height: 46pt, size: 0.75em, sub: [neural networks])[NPU],
    unit(icon: "🎬", width: 66pt, height: 46pt, size: 0.75em, sub: [video])[media],
    unit(icon: "📷", width: 66pt, height: 46pt, size: 0.75em, sub: [camera])[ISP],
    unit(icon: "🔊", width: 66pt, height: 46pt, size: 0.75em, sub: [sound, radio])[DSP],
    unit(icon: "🔒", width: 66pt, height: 46pt, size: 0.75em, sub: [keys, TPM])[security],
  )))
]

// ---------------------------------------------------------------------------
// GPU
// ---------------------------------------------------------------------------

// a grid of identical cores inside a chip frame
#let core-grid(n, cols, size, gap) = grid(
  columns: (size,) * cols,
  gutter: gap,
  ..range(n).map(_ => box(width: size, height: size, radius: 1pt, fill: accent)),
)

// a CPU chip (8 large cores) next to a GPU chip (thousands of small ones)
// `step`: 1 the CPU, 2 the GPU, 3 a picture split into pixels
#let cpu-gpu(step) = drawing(width: 460pt, height: 128pt, {
  chip(150pt, 128pt, [#cpu-icon CPU: 8 large cores])
  at(14pt, 34pt, core-grid(8, 4, 26pt, 6pt))
  at(14pt, 98pt, text(size: 0.6em)[each one: any code, decisions, \ one instruction after the other])
  if step >= 2 {
    chip(160pt, 128pt, [🎮 GPU: thousands of small cores], color: rgb("8e3b00"), x: 160pt)
    at(170pt, 34pt, core-grid(512, 32, 3pt, 1pt))
  }
  if step >= 2 { at(170pt, 98pt, text(size: 0.6em)[all run *the same instruction*, \ each on its own piece of data]) }
  if step >= 3 {
    // a picture: one pixel for each small core
    at(340pt, 20pt, text(size: 0.65em, weight: "bold")[🖼️ a 4K picture])
    for y in range(6) {
      for x in range(10) {
        at(340pt + x * 11pt, 36pt + y * 11pt, box(width: 10pt, height: 10pt, fill: rgb(40 + x * 20, 80 + y * 20, 160)))
      }
    }
    at(340pt, 104pt, text(size: 0.6em)[8.3 million pixels, \ the same math for each])
    // a few cores, each one computing one pixel
    for ((cc, cr), (px, py)) in (((29, 2), (1, 1)), ((31, 7), (4, 2)), ((30, 12), (2, 4))) {
      let (cx, cy) = (170pt + cc * 4pt, 34pt + cr * 4pt)
      at(cx - 0.5pt, cy - 0.5pt, box(width: 4pt, height: 4pt, fill: changed))
      at(340pt + px * 11pt - 0.5pt, 36pt + py * 11pt - 0.5pt, box(width: 11pt, height: 11pt, stroke: 1.2pt + changed))
      line-arrow((cx + 4pt, cy + 1.5pt), (340pt + px * 11pt - 1pt, 36pt + py * 11pt + 5pt), color: changed, thickness: 0.8pt, head: 4pt)
    }
    at(340pt, 6pt, text(size: 0.6em, weight: "bold", fill: changed.darken(15%))[one core, one pixel])
  }
})

#slide[
  == 🎮 The GPU
  _Graphics Processing Unit_: thousands of simple cores, the same work on different data

  #only(1, cpu-gpu(1))
  #only(2, cpu-gpu(2))
  #only("3-", cpu-gpu(3))

  #only("4-", place(bottom + center, dy: 0.8em, info(width: 440pt)[Not only for games][
    *graphics*: OpenGL, Vulkan, DirectX, Metal #h(0.8em) *compute*: CUDA, ROCm, oneAPI, OpenCL \
    a large GPU has more than 10 000 cores: it trains and runs most AI models
  ]))
]

// ---------------------------------------------------------------------------
// Integrated or dedicated GPU
// ---------------------------------------------------------------------------

// left: a GPU inside the CPU chip, sharing the RAM; right: a graphics card
// with its own VRAM, on PCIe. `step`: 1 integrated, 2 dedicated
#let igpu-dgpu(step) = drawing(width: 460pt, height: 160pt, {
  // integrated
  chip(200pt, 96pt, [#cpu-icon CPU chip with an integrated GPU])
  at(10pt, 28pt, core-grid(8, 4, 16pt, 4pt))
  at(110pt, 28pt, unit(width: 80pt, height: 56pt, size: 0.7em, icon: "🎮", sub: [inside the CPU])[iGPU])
  link-line((100pt, 96pt), (100pt, 108pt), thick: true)
  at(20pt, 108pt, unit(kind: "slot", width: 160pt, height: 28pt, size: 0.7em, sub: [shared by the cores and the iGPU])[🧮 RAM])
  at(0pt, 142pt, text(size: 0.65em)[✅ cheap, cool, low power: office, video, light games])
  if step >= 2 {
    // dedicated: a card in a PCIe x16 slot
    at(250pt, 0pt, box(width: 210pt, height: 118pt, radius: 0.4em, fill: luma(240), stroke: 1.2pt + rgb("8e3b00")))
    at(258pt, 4pt, text(size: 0.65em, weight: "bold", fill: rgb("8e3b00"))[graphics card])
    at(262pt, 22pt, unit(kind: "dark", width: 80pt, height: 56pt, size: 0.7em, icon: "🎮")[GPU chip])
    for i in range(4) {
      at(352pt + calc.rem(i, 2) * 50pt, 22pt + calc.quo(i, 2) * 30pt, unit(kind: "slot", width: 46pt, height: 26pt, size: 0.55em)[VRAM])
    }
    at(262pt, 88pt, text(size: 0.6em)[🌀 🌀 fans #h(1em) ⚡ 75 - 600 W])
    // the edge connector
    at(280pt, 118pt, box(width: 150pt, height: 8pt, fill: rgb("d4af37")))
    at(300pt, 128pt, text(size: 0.65em, weight: "bold")[PCIe x16 slot, to the CPU])
    at(250pt, 142pt, text(size: 0.65em)[✅ much faster, own fast memory (GDDR7): games, 3D, AI])
  }
})

#slide[
  == Integrated or Dedicated?
  A GPU inside the CPU chip, or on its own card

  #only(1, igpu-dgpu(1))
  #only("2-", igpu-dgpu(2))

  #uncover("3-")[]
  #only("3-", place(bottom + center, dy: 0.6em, info(width: 340pt)[Laptops often have both][
    the integrated GPU draws the desktop, the dedicated one wakes up when a game starts
  ]))
]

// ---------------------------------------------------------------------------
// NPU
// ---------------------------------------------------------------------------

// a small matrix of numbers, `on` colors it orange
#let matrix-box(rows, on: false) = box(
  inset: 4pt,
  radius: 3pt,
  stroke: 0.8pt + if on { changed } else { accent },
  fill: if on { changed-fill } else { accent-fill },
  grid(
    columns: rows.at(0).len(),
    column-gutter: 5pt,
    row-gutter: 4pt,
    ..rows.flatten().map(x => text(font: mono, size: 0.75em, str(x))),
  ),
)

// a 2x3 times 3x2 product, checked
#let ma = ((1, 2, 0), (3, -1, 2))
#let mb = ((2, 1), (0, 4), (1, -3))
#let mc = range(2).map(i => range(2).map(j => range(3).map(k => ma.at(i).at(k) * mb.at(k).at(j)).sum()))
#assert.eq(mc, ((2, 9), (8, -7)))

#slide[
  == 🤖 The NPU
  _Neural Processing Unit_: a small, efficient engine for running AI models

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.8em,
    side-panel([🤖 What it does], [matrix multiplications], [millions of these, every second], height: 110pt)[
      #align(center)[
        #matrix-box(ma) #h(0.2em) × #h(0.2em) #matrix-box(mb) #h(0.2em) = #h(0.2em) #matrix-box(mc, on: true)
      ]
      #v(0.2em)
      small numbers: 8-bit or 4-bit integers, not 32-bit floats
    ],
    uncover("2-", side-panel([🔋 Why not the GPU?], [much less power], [speed in TOPS: trillions of operations / s], height: 110pt)[
      it can run *all the time*:
      - blur the background in a video call
      - speech to text, photo search
      - small AI models on your laptop
    ]),
  )

  #v(0.4em)
  #uncover("3-", align(center)[
    #set text(size: 0.85em)
    #tag[Apple Neural Engine] #tag[Qualcomm Hexagon] #tag[Intel NPU] #tag[AMD XDNA] #tag[Google TPU (data centers)]
  ])

  #only("4-", place(bottom + center, dy: -0.2em, info(width: 360pt)[Running, not training][
    an NPU *runs* trained models (_inference_); training is done on data center GPUs and TPUs. Windows "Copilot+" PCs need an NPU of at least 40 TOPS
  ]))
]

// ---------------------------------------------------------------------------
// TPM
// ---------------------------------------------------------------------------

// measured boot: three boot stages, each one hashed into the TPM, and the
// disk key the TPM gives back only for the expected PCR value.
// `step`: 1 the stages and the TPM, 2 the measurements, 3 the key is
// released, 4 a changed bootloader: another PCR, the key stays locked
#let tpm-boot(step) = drawing(width: 270pt, height: 150pt, {
  let stages = (([firmware], [UEFI]), ([bootloader], [GRUB]), ([kernel], [Linux]))
  for (i, (name, sub)) in stages.enumerate() {
    let bad = step >= 4 and i == 1
    at(i * 95pt, 0pt, unit(width: 80pt, height: 32pt, size: 0.7em, on: bad, sub: if bad [GRUB, changed!] else { sub }, name))
    if i < 2 { line-arrow((i * 95pt + 80pt, 16pt), (i * 95pt + 95pt, 16pt)) }
    if step >= 2 {
      line-arrow((i * 95pt + 40pt, 32pt), (85pt + i * 50pt, 78pt), color: if bad { changed } else { accent }, dash: "dashed")
    }
  }
  if step >= 2 { at(142pt, 48pt, note[measure (hash)]) }
  at(55pt, 78pt, unit(kind: "dark", on: step >= 4, width: 160pt, height: 40pt, size: 0.7em, icon: none,
    sub: if step < 2 [PCR = 0000…] else if step < 4 [PCR = a3f1… (expected)] else [PCR = 7c02… (different)],
  )[🔒 TPM chip])
  if step >= 3 {
    at(0pt, 128pt, box(width: 270pt, align(center, text(size: 0.75em, if step < 4 [
      🔑 disk key: *released* ✅ the disk unlocks, no password
    ] else [
      🔑 disk key: *stays locked* ❌ asks for the recovery key
    ]))))
  }
})

#slide[
  == 🔒 The TPM
  _Trusted Platform Module_: a small safe for keys, that also watches the boot

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - a small *security chip* on the board, or a part of the CPU firmware (_fTPM_)
    - makes and keeps *keys*: they never leave the chip
    #uncover("2-")[#block[- *measures the boot*: a hash of every stage, kept in its _PCR_ registers]]
    #uncover("3-")[#block[- *seals* secrets: gives a key back only if the PCRs are the expected ones]]
  ][
    #only(1, tpm-boot(1))
    #only(2, tpm-boot(2))
    #only(3, tpm-boot(3))
    #only("4-", tpm-boot(4))
  ]

  #v(0.6em)
  #only(1)[💡 every PC sold with Windows since 2016 has one: TPM 2.0]
  #only(2)[💡 each stage hashes the next one *before* starting it; a PCR can only be extended, never set]
  #only(3)[💡 the disk key is _sealed_ to these PCR values: a normal boot unlocks the disk by itself]
  #only(4)[💡 a changed bootloader gives another PCR value: the key stays locked, the disk stays safe]
  #only("5-", place(bottom + center, dy: -0.2em, info(width: 400pt)[You already use it][
    Windows 11 needs a TPM 2.0 and uses it for BitLocker; on Linux, `systemd-cryptenroll --tpm2-device=auto` seals the disk key the same way
  ]))
]

// ---------------------------------------------------------------------------
// Who does the job?
// ---------------------------------------------------------------------------

// a job and the unit that does it, revealed on step `at`
#let job(icon, what, unit-name, at) = (
  text(size: 1.2em, icon),
  what,
  uncover(str(at) + "-", box(
    inset: (x: 0.4em, y: 0.2em),
    radius: 0.3em,
    fill: changed-fill,
    stroke: 0.8pt + changed,
    text(weight: "bold", fill: changed.darken(15%), unit-name),
  )),
)

#slide[
  == Who Does the Job?
  The OS and the libraries pick the right unit

  #set text(size: 0.85em)
  #align(center, grid(
    columns: (auto, auto, auto),
    column-gutter: 0.8em,
    row-gutter: 0.5em,
    align: (center + horizon, left + horizon, left + horizon),
    ..job("⌨️", [run `bash`, compile with `gcc`], [#cpu-icon CPU], 2),
    ..job("🍿", [watch a 4K movie], [🎬 media engine (video decoder)], 2),
    ..job("🕹️", [play a 3D game], [🎮 GPU], 2),
    ..job("📹", [blur the background in a video call], [🤖 NPU (or GPU)], 3),
    ..job("👆", [unlock with your fingerprint], [🔒 security processor], 3),
    ..job("🏭", [train a large language model], [🎮 thousands of data center GPUs], 3),
    ..job("⏱️", [switch a pin every millisecond, exactly], [🔌 a microcontroller (real-time coprocessor)], 3),
  ))

  #set text(size: 1em / 0.85)
  #only("3-", place(bottom + center, dy: -0.2em, info(width: 340pt)[The right unit][
    faster *and* less battery: a video decoder plays a movie with a few watts, the CPU alone would need much more
  ]))
]

// ---------------------------------------------------------------------------
// In Linux: the same three questions for every coprocessor
// ---------------------------------------------------------------------------

// one of the three inspection questions: a number, the question and the
// command that answers it; used as the plan of the inspection slides
// e.g. #question-box(1, [is it there?], "lspci")
#let question-box(n, q, cmd) = box(
  width: 128pt,
  inset: (x: 0.6em, y: 0.45em),
  radius: 0.4em,
  fill: accent-fill,
  stroke: 1.2pt + accent,
  {
    set text(size: 0.8em)
    box(baseline: 0.25em, circle(radius: 0.65em, fill: accent, align(center + horizon, text(fill: white, weight: "bold", str(n)))))
    h(0.4em)
    text(weight: "bold", q)
    linebreak()
    text(font: mono, size: 0.9em, highlight-shell(cmd))
  },
)

// one explanation next to a terminal, shown from step `at`; `n` (1-3) marks
// which of the three questions it answers, none for no number
#let explain(at, title, body, n: none) = uncover(str(at) + "-", block(
  width: 100%,
  inset: (x: 0.5em, y: 0.35em),
  radius: 0.3em,
  fill: accent-fill,
  stroke: (left: 3pt + accent),
  below: 0.4em,
  text(size: 0.8em)[#if n != none { text(fill: accent, weight: "bold", numbering("1.", n)) + h(0.3em) }*#title* #h(0.3em) #body],
))

#slide[
  == Coprocessors in Linux
  Drivers make them visible: ask the same three questions for each

  #align(center, stack(
    dir: ltr,
    spacing: 0.8em,
    question-box(1, [is it there?], "lspci"),
    question-box(2, [which driver?], "lsmod"),
    question-box(3, [what does it show?], "ls /sys/class/..."),
  ))

  #v(0.3em)
  #nice-table(
    columns: (auto, auto, auto, 1fr),
    size: 0.8em,
    header: ([unit], [in /sys/class], [device file], [driver (lsmod)]),
    rows: (
      ([🎮 *GPU*], [`drm`], [`/dev/dri/card0`], [`i915`, `xe`, `amdgpu`, `nvidia`]),
      ([🤖 *NPU*], [`accel`], [`/dev/accel/accel0`], [`intel_vpu`, `amdxdna`]),
      ([🎲 *random numbers*], [`misc/hw_random`], [`/dev/hwrng`], [`virtio_rng` (in a VM)]),
      ([🔒 *TPM*], [`tpm`], [`/dev/tpm0`], [`tpm_tis`, `tpm_crb`]),
    ),
    shown: (2, 2, 2, 2),
  )
]

#slide[
  == Inspect the GPU
  The three questions, on this VM

  #toolbox.side-by-side(columns: (8fr, 5fr), gutter: 1em)[
    #set text(size: 0.76em)
    #reveal-terminal(before: none, lines: (2, 5, 10, 12), full: false)[```terminal
    $ lspci | grep -i display
    00:0a.0 Display controller: Red Hat, Inc. Virtio GPU (rev 01)
    $ lsmod | grep gpu
    virtio_gpu             90112  0
    virtio_dma_buf         12288  1 virtio_gpu
    $ ls /sys/class/drm
    card0
    card0-Virtual-1
    renderD128
    version
    $ cat /sys/class/drm/card0-Virtual-1/status
    connected
    ```]
  ][
    #explain(1, n: 1, [it is there], [a PCI device: `Display controller` (or `VGA`, `3D`)])
    #explain(2, n: 2, [its driver], [`virtio_gpu`, a kernel module])
    #explain(3, n: 3, [its devices], [`card0` draws the screen, `renderD128` renders and computes (in `/dev/dri`)])
    #explain(4, [the screen], [`card0-Virtual-1`: a _connector_, something is plugged in])
  ]

  #only("4-", place(bottom + center, dy: -0.2em, info(width: 400pt)[Programs use it through libraries][
    Mesa, Vulkan, CUDA, ... #h(0.6em) `vulkaninfo --summary`: what the GPU supports
  ]))
]

// one GPU vendor and its tools: a colored title bar, then (command, what it
// shows) rows
#let vendor(name, color, tools) = box(
  width: 100%,
  height: 118pt,
  radius: 0.5em,
  clip: true,
  stroke: 1.2pt + color,
  fill: white,
  {
    block(width: 100%, fill: color, inset: (x: 0.6em, y: 0.35em), below: 0pt, text(size: 1.1em, weight: "bold", fill: white, name))
    block(width: 100%, inset: (x: 0.6em, y: 0.5em), above: 0pt, {
      set text(size: 0.78em)
      for (cmd, what) in tools {
        block(below: 0.55em, [#text(font: mono, highlight-shell(cmd)) \ #text(fill: luma(70), what)])
      }
    })
  },
)

#slide[
  == Watch the GPU
  Each vendor has its own tool, `nvtop` works with all of them

  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    vendor([NVIDIA], rgb("4a7a00"), (
      ("nvidia-smi", [load, memory, temperature, power, the processes; comes with the driver]),
      ("nvidia-smi -l 1", [the same, every second]),
    )),
    vendor([AMD], rgb("b3261e"), (
      ("amd-smi monitor", [load, memory, temperature, power; part of ROCm (the old one: `rocm-smi`)]),
      ("radeontop", [load of each part of the GPU, live]),
    )),
    vendor([Intel], rgb("0068b5"), (
      ("sudo intel_gpu_top", [load of each engine (3D, video, ...), live; package `intel-gpu-tools`]),
    )),
  )

  #v(0.4em)
  #uncover("2-", align(left, box(
    width: 100%,
    inset: (x: 0.8em, y: 0.5em),
    radius: 0.5em,
    fill: accent-fill,
    stroke: 1.2pt + accent,
    text(size: 0.85em)[#text(font: mono, highlight-shell("nvtop")) #h(0.6em) like `htop`, for GPUs: NVIDIA, AMD, Intel and more, with live graphs of the load and the memory of each GPU and of each process],
  )))
]

// a screenshot of nvtop on a Panther Lake laptop (1600 x 1176 px), with
// orange frames over its parts; `marks`: (x0, y0, x1, y1) in pixels
#let shot-width = 270pt
#let shot(marks) = box(width: shot-width, {
  image("img/nvtop.jpg", width: shot-width)
  let k = shot-width / 1600
  for (x0, y0, x1, y1) in marks {
    place(top + left, dx: x0 * k, dy: y0 * k, rect(width: (x1 - x0) * k, height: (y1 - y0) * k, radius: 2pt, stroke: 1.8pt + changed))
  }
})

#slide[
  == `nvtop` on a Laptop
  The integrated GPU of a Panther Lake laptop, at work

  #toolbox.side-by-side(columns: (auto, 1fr), gutter: 1em)[
    #only(1, shot(((60, 132, 1190, 172), (60, 208, 948, 250))))
    #only(2, shot(((952, 208, 1448, 250), (105, 262, 1542, 848))))
    #only("3-", shot(((48, 852, 1548, 1088),)))
  ][
    #set text(size: 0.8em)
    - an *integrated* GPU (Arc B390), in the same chip as the CPU
    - `MEM` 1.3 of *62 GiB*: it uses the system RAM (_unified memory_)
    #uncover("2-")[#block[
      - `ENC/DEC`: the *video engine*, apart from the 3D cores
      - the graph: the load over the last 40 seconds
    ]]
    #uncover("3-")[#block[
      - the processes that use the GPU now
      - `TYPE`: `Graphic` draws, `Compute` (`C`) calculates, `Both`
    ]]
  ]
]

#slide[
  == Other Coprocessors
  The NPU, security hardware and crypto inside the CPU

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.82em)
    #reveal-terminal(before: none, lines: (1, 3, 5, 9), full: false)[```terminal
    $ ls /sys/class/accel
    $ cat /sys/class/misc/hw_random/rng_current
    virtio_rng.0
    $ ls /sys/class/tpm
    tpm0
    $ grep -o -w -E 'aes|sha2|sha512' /proc/cpuinfo | sort -u
    aes
    sha2
    sha512
    ```]
  ][
    #explain(1, [🤖 NPU], [runs AI models; empty here, a laptop with an NPU shows `accel0`])
    #explain(2, [🎲 random numbers], [a hardware generator for keys and passwords: `virtio_rng` here])
    #explain(3, [🔒 TPM], [keeps keys, checks the boot: `tpm0` here, used through `/dev/tpm0`])
    #explain(4, [🔐 crypto in the CPU], [`aes`, `sha2`: instructions that encrypt and hash, no driver needed])
  ]

  #only("4-", place(bottom + center, dy: -0.2em, info(width: 400pt)[An empty folder is an answer too][
    no device: the hardware is missing, or its driver is not loaded (check with `lsmod`)
  ]))
]
