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
  }
})

#slide[
  == Graphics Processing Unit (GPU)
  Thousands of simple cores doing the same thing on different data

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
  == Integrated or Dedicated GPU?
  Inside the CPU chip, or on its own card

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
  == Neural Processing Unit (NPU)
  A small, efficient engine for running AI models

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
    ..job("🍿", [watch a 4K movie], [🎬 media engine (video decoder)], 3),
    ..job("🕹️", [play a 3D game], [🎮 GPU], 4),
    ..job("📹", [blur the background in a video call], [🤖 NPU (or GPU)], 5),
    ..job("👆", [unlock with your fingerprint], [🔒 security processor], 6),
    ..job("🏭", [train a large language model], [🎮 thousands of data center GPUs], 7),
  ))

  #set text(size: 1em / 0.85)
  #only("8-", place(bottom + center, dy: -0.2em, info(width: 340pt)[The right unit][
    faster *and* less battery: a video decoder plays a movie with a few watts, the CPU alone would need much more
  ]))
]

// ---------------------------------------------------------------------------
// In Linux
// ---------------------------------------------------------------------------

#slide[
  == Coprocessors in Linux
  Drivers make them visible as devices

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    #reveal-terminal(before: none, lines: (5, 6), full: false)[```terminal
    $ ls /sys/class/drm
    card0
    card0-Virtual-1
    renderD128
    version
    $ ls /sys/class/accel
    ```]
  ][
    #set text(size: 0.8em)
    #card([🎮 GPU: the DRM subsystem])[
      - `/dev/dri/card0`: the display
      - `/dev/dri/renderD128`: rendering and compute
      - `card0-Virtual-1`: the virtual screen of this VM
    ]
    #v(0.3em)
    #uncover("2-", card([🤖 NPU: the accel subsystem])[
      - `/dev/accel/accel0` (Linux 6.2+)
      - empty here: this VM has no NPU
    ])
  ]

  #only("3-", place(bottom + center, dy: -0.2em, info(width: 380pt)[Programs use them through libraries][
    Mesa, Vulkan, CUDA, OpenVINO, ... #h(1em) watch them with `nvtop`, `intel_gpu_top`, `nvidia-smi`
  ]))
]

// one explanation next to a terminal: a bold title and a line, shown from
// step `at`
#let explain(at, title, body) = uncover(str(at) + "-", block(
  width: 100%,
  inset: (x: 0.5em, y: 0.35em),
  radius: 0.3em,
  fill: accent-fill,
  stroke: (left: 3pt + accent),
  below: 0.4em,
  text(size: 0.8em)[*#title* #h(0.3em) #body],
))

#slide[
  == Inspect the GPU
  Find it, its driver and the screen it draws on

  #toolbox.side-by-side(columns: (8fr, 5fr), gutter: 1em)[
    #set text(size: 0.76em)
    #reveal-terminal(before: none, lines: (2, 5, 7, 11), full: false)[```terminal
    $ lspci | grep -i display
    00:0a.0 Display controller: Red Hat, Inc. Virtio GPU (rev 01)
    $ lsmod | grep gpu
    virtio_gpu             90112  0
    virtio_dma_buf         12288  1 virtio_gpu
    $ cat /sys/class/drm/card0-Virtual-1/status
    connected
    $ head -3 /sys/class/drm/card0-Virtual-1/modes
    1280x800
    4096x2160
    4096x2160
    ```]
  ][
    #explain(1, [the GPU], [is a PCI device: `Display controller` (or `VGA`, `3D`)])
    #explain(2, [its driver], [`virtio_gpu`, a kernel module (`nvidia`, `amdgpu`, `i915`, `xe` on a PC)])
    #explain(3, [the screen], [a _connector_ of `card0`: something is plugged in])
    #explain(4, [the modes], [the resolutions the screen accepts])
  ]

  #only("5-", place(bottom + center, dy: -0.2em, info(width: 400pt)[On a real PC][
    `vulkaninfo --summary`: what the GPU supports #h(0.6em) watch it at work: next slide
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
  == Watch the GPU at Work
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

#slide[
  == Inspect Other Coprocessors
  Security hardware, and crypto inside the CPU

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.82em)
    #reveal-terminal(before: none, lines: (4, 5, 9), full: false)[```terminal
    $ cat /sys/class/misc/hw_random/rng_current
    virtio_rng.0
    $ lsmod | grep rng
    virtio_rng             12288  0
    $ ls /sys/class/tpm
    $ grep -o -w -E 'aes|sha2|sha512' /proc/cpuinfo | sort -u
    aes
    sha2
    sha512
    ```]
  ][
    #explain(1, [🎲 random numbers], [a hardware generator for keys and passwords: `virtio_rng` here])
    #explain(2, [🔒 TPM], [keeps keys, checks the boot; empty here: this VM has none, a PC shows `tpm0`])
    #explain(3, [🔐 crypto in the CPU], [`aes`, `sha2`: instructions that encrypt and hash, a small "coprocessor" inside every core])
  ]

  #only("4-", place(bottom + center, dy: -0.2em, info(width: 400pt)[And the NPU?][
    `ls /dev/accel` lists it; its driver is `intel_vpu` (Intel) or `amdxdna` (AMD): check with `lsmod`
  ]))
]
