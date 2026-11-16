#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Processor Architectures #text(size: 10pt, weight: "regular")[\ _The language the processor speaks_]
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
    - Chapter 2 - _Instructions: Language of the Computer_
]

// ---------------------------------------------------------------------------
// The fetch - decode - execute loop
// ---------------------------------------------------------------------------

// a tiny program in memory: (address, content, is it code); pseudo assembly
#let program = (
  ("0x1000", "load  r0, x", true),
  ("0x1004", "add   r0, r0, 1", true),
  ("0x1008", "store r0, x", true),
  ("0x100c", "jump  0x1000", true),
  ("0x2000", "x = 5", false),
)

// a small round badge with the number of a step
#let badge(n, on: false) = box(baseline: 0.15em, circle(
  radius: 0.55em,
  fill: if on { changed } else { luma(150) },
  stroke: none,
  align(center + horizon, text(size: 0.75em, weight: "bold", fill: white, str(n))),
))

// a register: a name and a value, orange when it changes
#let register(name, value, on: false, width: 80pt) = box(
  width: width,
  height: 34pt,
  radius: 4pt,
  fill: if on { changed-fill } else { accent-fill },
  stroke: (if on { 1.5pt } else { 1pt }) + if on { changed } else { accent },
  align(center + horizon, {
    text(size: 0.55em, fill: luma(90))[register #raw(name)]
    linebreak()
    text(font: mono, size: 0.8em, weight: "bold", fill: if on { changed } else { accent }, value)
  }),
)

// The fetch - decode - execute loop, running `add r0, r0, 1`:
// RAM on the left, the CPU on the right.
// `stage`: 0 nothing yet, 1 fetch, 2 decode, 3 execute, 4 next instruction
#let cpu-loop(stage) = scale(88%, reflow: true, drawing(width: 470pt, height: 162pt, {
  let pc = if stage == 4 { 2 } else { 1 }
  let row-y(i) = 24pt + i * 26pt + (if i == 4 { 4pt } else { 0pt })
  // ---- RAM ----
  at(22pt, 0pt, box(width: 140pt, height: 162pt, radius: 0.4em, fill: white, stroke: 1.2pt + luma(120), clip: true, block(
    width: 100%,
    fill: luma(120),
    inset: (x: 0.5em, y: 0.3em),
    text(size: 0.7em, fill: white, weight: "bold")[🧮 RAM],
  )))
  for (i, (addr, content, code)) in program.enumerate() {
    let current = i == pc and stage in (1, 4)
    at(28pt, row-y(i), box(
      width: 128pt,
      height: 22pt,
      radius: 3pt,
      inset: (x: 4pt),
      fill: if current { changed-fill } else if code { white } else { luma(238) },
      stroke: if current { 1.5pt + changed } else { 0.6pt + luma(170) },
      align(horizon, {
        text(font: mono, size: 0.5em, fill: luma(130), addr)
        h(5pt)
        text(font: mono, size: 0.6em, weight: if i == 1 { "bold" } else { "regular" }, fill: if current { changed } else {
          black
        }, content)
      }),
    ))
  }
  // the pc points to an instruction in RAM
  line-arrow((2pt, row-y(pc) + 11pt), (26pt, row-y(pc) + 11pt), color: changed, thickness: 1.5pt)
  at(0pt, row-y(pc) - 2pt, text(font: mono, size: 0.55em, weight: "bold", fill: changed)[pc])

  // ---- CPU ----
  at(190pt, 0pt, box(width: 280pt, height: 162pt, radius: 0.4em, fill: white, stroke: 1.2pt + accent, clip: true, block(
    width: 100%,
    fill: accent,
    inset: (x: 0.5em, y: 0.3em),
    text(size: 0.7em, fill: white, weight: "bold")[#cpu-icon CPU],
  )))
  // the three stages and the way back
  let stage-box(n, x, icon, name) = at(x, 22pt, unit(width: 76pt, height: 26pt, on: stage == n, size: 0.65em)[
    #badge(n, on: stage == n) #icon #name
  ])
  stage-box(1, 200pt, "📥", [fetch])
  stage-box(2, 290pt, "🔍", [decode])
  stage-box(3, 380pt, "⚙️", [execute])
  line-arrow((276pt, 35pt), (289pt, 35pt))
  line-arrow((366pt, 35pt), (379pt, 35pt))
  let c4 = if stage == 4 { changed } else { luma(150) }
  wire((418pt, 48pt), (418pt, 57pt), stroke: 1.2pt + c4)
  wire((418pt, 57pt), (238pt, 57pt), stroke: 1.2pt + c4)
  line-arrow((238pt, 57pt), (238pt, 49pt), color: c4, thickness: 1.2pt)
  pin(328pt, 57pt, box(fill: white, inset: (x: 3pt), text(size: 0.55em, weight: "bold", fill: c4)[#badge(4, on: stage == 4) next: `pc + 4`, repeat]))

  // the instruction being run
  let ir-on = stage in (1, 2)
  at(200pt, 66pt, box(
    width: 150pt,
    height: 40pt,
    radius: 4pt,
    fill: if ir-on { changed-fill } else { accent-fill },
    stroke: (if ir-on { 1.5pt } else { 1pt }) + if ir-on { changed } else { accent },
    inset: 4pt,
    {
      text(size: 0.5em, fill: luma(90))[current instruction]
      linebreak()
      if stage == 0 { } else if stage == 2 {
        // decoded: the fields of the instruction
        let field(t, what) = box(stack(
          spacing: 1.5pt,
          box(inset: (x: 3pt, y: 1.5pt), radius: 2pt, fill: white, stroke: 0.6pt + changed, text(
            font: mono,
            size: 0.6em,
            weight: "bold",
            fill: changed,
            t,
          )),
          align(center, text(size: 0.45em, fill: luma(60), what)),
        ))
        field("add", [do]) + h(4pt) + field("r0", [put it in]) + h(4pt) + field("r0, 1", [add these])
      } else {
        text(font: mono, size: 0.7em, weight: "bold", fill: if ir-on { changed } else { accent }, "add r0, r0, 1")
      }
    },
  ))
  // the calculator
  at(360pt, 66pt, unit(width: 100pt, height: 40pt, on: stage == 3, size: 0.6em, sub: if stage >= 3 {
    raw("5 + 1 = 6")
  } else { [ ] })[🧮 ALU (calculator)])

  // the registers: a few named boxes inside the CPU
  at(196pt, 114pt, box(width: 268pt, height: 44pt, radius: 4pt, stroke: (paint: accent, thickness: 0.8pt, dash: "dashed")))
  at(204pt, 119pt, register("pc", program.at(pc).at(0), on: stage == 4, width: 72pt))
  at(282pt, 121pt, box(width: 80pt, height: 32pt, align(center + horizon, text(size: 0.55em, fill: accent)[
    *registers*
  ])))
  at(370pt, 119pt, register("r0", if stage >= 3 { "6" } else { "5" }, on: stage == 3, width: 86pt))

  // what moves on each step
  if stage == 1 {
    line-arrow((156pt, row-y(1) + 11pt), (199pt, 86pt), color: changed, thickness: 1.5pt)
  }
  if stage == 3 {
    line-arrow((390pt, 119pt), (390pt, 107pt), color: changed, thickness: 1.5pt)
    at(380pt, 108pt, text(size: 0.5em, weight: "bold", fill: changed)[5])
    line-arrow((440pt, 107pt), (440pt, 119pt), color: changed, thickness: 1.5pt)
    at(443pt, 108pt, text(size: 0.5em, weight: "bold", fill: changed)[6])
  }
}))

#slide[
  == The Processor (CPU)
  Runs instructions, one after the other, billions of times per second

  #only(1, cpu-loop(0))
  #only(2, cpu-loop(1))
  #only(3, cpu-loop(2))
  #only(4, cpu-loop(3))
  #only("5-", cpu-loop(4))

  #v(0.2em)
  #only(1)[💡 a program is a list of *instructions* in RAM; `pc` (_program counter_) is the register that points to the next one]
  #only(2)[#badge(1, on: true) *fetch*: copy the instruction at address `pc` from RAM into the CPU]
  #only(3)[#badge(2, on: true) *decode*: the instruction is just bytes, the CPU finds out what to do and with what]
  #only(4)[#badge(3, on: true) *execute*: the ALU computes `r0 + 1` and writes the result back to `r0`: 5 becomes 6]
  #only("5-")[#badge(4, on: true) *next*: `pc` moves to the next instruction (4 bytes further) and the loop starts again]
]

// ---------------------------------------------------------------------------
// Instruction sets
// ---------------------------------------------------------------------------

// machine code bytes, one small box per byte
#let bytes(..bs) = (
  bs
    .pos()
    .map(b => box(
    inset: (x: 2.5pt, y: 2pt),
    radius: 2pt,
    fill: white,
    stroke: 0.6pt + luma(150),
    text(font: mono, size: 0.75em, b),
  ))
    .join(h(2pt))
)

// the machine code of one ISA: the assembly line and its bytes (checked
// with an assembler / disassembler: as, objdump, capstone)
#let machine-code(isa, ins, bs) = code-file(width: 175pt, isa + " machine code")[
  #set text(size: 0.8em)
  #raw(ins) #h(1fr) #bytes(..bs)
]

// the arrows from the compiler to the machine code of the first `n` ISAs
// (rows of 40pt, 6pt apart)
#let fan(n) = box(width: 34pt, height: 132pt, {
  for i in range(n) {
    line-arrow((2pt, 66pt), (32pt, 20pt + i * 46pt), color: luma(120), thickness: 1.5pt, head: 6pt)
  }
})

// one row of the flow: the machine code for one ISA and the CPU that runs
// it, shown from step `at`
#let isa-row(at, isa, ins, bs, cpu, makers) = (
  machine-code(isa, ins, bs),
  draw-arrow(length: 2em),
  tool-box(cpu, sub: makers, width: 100pt, fill: white),
).map(c => uncover(str(at) + "-", c))

#slide[
  == The ISA
  _Instruction Set Architecture_: the instructions a processor understands, and how they look in bytes

  #set text(size: 0.9em)
  #align(center, grid(
    // fixed widths: cells shown later (uncover) must not change the layout
    columns: (auto, 2.2em, auto, 34pt, 175pt, 2.2em, 100pt),
    column-gutter: 0.3em,
    row-gutter: 6pt,
    rows: (auto, 40pt, 40pt, 40pt),
    align: center + horizon,
    [], [], [], [],
    uncover("2-", text(size: 0.75em, weight: "bold", fill: luma(90))[one machine code per ISA]),
    [],
    uncover("2-", text(size: 0.75em, weight: "bold", fill: luma(90))[runs only on]),
    grid.cell(rowspan: 3, code-file("add.c", width: 92pt)[```c a = a + 1;```]),
    grid.cell(rowspan: 3, draw-arrow(length: 2em)),
    grid.cell(rowspan: 3, tool-box("compiler", sub: [`gcc`, `clang`])),
    grid.cell(rowspan: 3, {
      only(2, fan(1))
      only(3, fan(2))
      only("4-", fan(3))
    }),
    ..isa-row(2, "x86-64", "add eax, 1", ("83", "c0", "01"), [x86-64 CPU], [Intel, AMD]),
    ..isa-row(3, "ARM", "add w0, w0, #1", ("00", "04", "00", "11"), [ARM CPU], [Apple, Qualcomm, ...]),
    ..isa-row(4, "RISC-V", "addi a0, a0, 1", ("13", "05", "15", "00"), [RISC-V CPU], [SiFive, ...]),
  ))

  #set text(size: 1em / 0.9)
  #v(0.2em)
  #only(1)[💡 the ISA is the *contract* between hardware and software: which instructions exist and how they are written in bytes]
  #only("2-4")[💡 the same line of C, three different "languages": the bytes mean nothing to the other CPUs]
  #only("5-", place(bottom + left, dy: 1em, popup(width: 190pt)[One program, one ISA][
    a program compiled for one ISA does *not* run on another: this is why you download `x86_64` or `arm64` versions
  ]))
]

// one architecture family: the name, the Linux names, where it lives (big
// icons + a few words), who builds it and its license as a colored pill
#let arch-card(name, names, icons, where, who, license, license-color) = box(
  width: 100%,
  height: 150pt,
  radius: 0.5em,
  clip: true,
  stroke: 1.2pt + accent,
  fill: white,
  {
    block(width: 100%, fill: accent, inset: (y: 0.4em), below: 0pt, align(center, text(
      size: 1.15em,
      weight: "bold",
      fill: white,
      name,
    )))
    block(height: 150pt - 1.9em, width: 100%, inset: (x: 0.6em, y: 0.5em), above: 0pt, align(center, {
      names.map(n => tag(raw(n))).join(h(0.3em))
      v(0.3em)
      text(size: 1.8em, icons)
      v(-0.2em)
      text(size: 0.85em, where)
      v(0.3em)
      text(size: 0.8em, fill: luma(90))[built by #who]
      v(1fr)
      box(
        width: 100%,
        inset: (y: 0.35em),
        radius: 1em,
        fill: license-color.lighten(85%),
        stroke: 0.8pt + license-color,
        text(size: 0.85em, weight: "bold", fill: license-color.darken(15%), license),
      )
    }))
  },
)

#slide[
  == Architectures Today
  Three families you will meet

  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.8em,
    arch-card([x86-64], ("x86_64", "amd64"), [🖥️ 💻 🗄️], [PCs and servers], [Intel, AMD], [🔒 closed], bad-color),
    uncover("2-", arch-card([ARM], ("aarch64", "arm64"), [📱 🍎 🍓 ☁️], [phones, Macs, Raspberry Pi, cloud], [Apple, Qualcomm, ...], [💰 licensed from Arm], changed)),
    uncover("3-", arch-card([RISC-V], ("riscv64",), [🔌 🎓 🧪], [microcontrollers, research], [anyone], [🆓 open], ok-color)),
  )

  #v(0.4em)
  #only(1)[💡 `x86` comes from the Intel 8086 (1978); AMD made it 64-bit (2003)]
  #only(2)[💡 almost every phone runs ARM]
  #only("3-")[💡 open like open source: anyone can build a RISC-V CPU for free]
]

// ---------------------------------------------------------------------------
// CISC and RISC
// ---------------------------------------------------------------------------

// one ISA as a panel: a title bar (name + kind of ISA), the machine code
// one instruction per line with its bytes (one box per byte, so the length
// shows) and what it does, and a footer with the totals. Both panels have the
// same height, so the footers line up.
// The bytes are real encodings (x86-64: capstone; ARM: `gcc -O2` + `objdump`,
// in memory order, little endian).
#let isa-panel(title, kind, rows, height: 116pt) = box(
  width: 100%,
  height: height,
  radius: 0.5em,
  clip: true,
  stroke: 1.2pt + accent,
  fill: white,
  {
    let total = rows.map(r => r.at(1).len()).sum()
    block(width: 100%, fill: accent, inset: (x: 0.6em, y: 0.35em), below: 0pt, {
      text(weight: "bold", fill: white, title)
      h(1fr)
      text(size: 0.8em, fill: white, kind)
    })
    block(width: 100%, height: height - 1.6em - 22pt, inset: (x: 0.6em, y: 0.5em), above: 0pt, below: 0pt, {
      set text(size: 0.8em)
      grid(
        columns: (auto, auto, 1fr),
        column-gutter: 0.7em,
        row-gutter: 0.55em,
        align: left + horizon,
        ..rows
          .map(((ins, bs, what)) => (
            raw(ins),
            bytes(..bs),
            text(size: 0.9em, fill: luma(60), what),
          ))
          .flatten(),
      )
    })
    place(bottom, block(width: 100%, height: 22pt, fill: accent-fill, stroke: (top: 0.6pt + accent), align(
      center + horizon,
      text(size: 0.8em, fill: accent)[*#rows.len()* instructions #h(1.5em) *#total* bytes],
    )))
  },
)

#slide[
  == CISC and RISC
  The same C function, compiled for two ISAs: ```c void inc(int *x) { *x = *x + 1; }```

  #v(0.3em)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 0.8em,
    isa-panel([x86-64], [CISC: complex instructions, 1 - 15 bytes], (
      ("add dword [rdi], 1", ("83", "07", "01"), [read RAM, add 1, write RAM]),
      ("ret", ("c3",), [return]),
    )),
    uncover("2-", isa-panel([ARM (AArch64)], [RISC: simple instructions, 4 bytes], (
      ("ldr w1, [x0]", ("01", "00", "40", "b9"), [read RAM]),
      ("add w1, w1, #1", ("21", "04", "00", "11"), [add 1]),
      ("str w1, [x0]", ("01", "00", "00", "b9"), [write RAM]),
      ("ret", ("c0", "03", "5f", "d6"), [return]),
    ))),
  )

  // the main idea: a large popup over the bottom of the slide
  #only("3-", place(bottom + center, dy: -0.8em, popup(width: 420pt, kind: "tip")[
    #text(size: 1.15em)[CISC or RISC? Today the line is blurry]
  ][
    #set text(size: 1.1em)
    inside, an x86-64 CPU splits each *CISC* instruction into *RISC*-like _micro-operations_
  ]))
]

// a box with a colored title bar holding the architecture, in big white
// letters, and a body below; used for the programs and for the CPU
#let arch-box(width, arch, body, color: accent) = box(
  width: width,
  radius: 4pt,
  clip: true,
  stroke: 1.2pt + color,
  fill: white,
  stack(
    block(width: 100%, fill: color, inset: (x: 4pt, y: 5pt), align(center, text(
      size: 1.25em,
      weight: "bold",
      fill: white,
      arch,
    ))),
    block(width: 100%, inset: (x: 4pt, y: 5pt), align(center, text(size: 0.9em, body))),
  ),
)

// a result under a program: a colored pill, full width
#let result(color, body) = box(
  width: 100%,
  inset: (y: 0.4em),
  radius: 1em,
  fill: color.lighten(85%),
  stroke: 0.8pt + color,
  align(center, text(size: 0.8em, weight: "bold", fill: color.darken(15%), body)),
)

#slide[
  == Which Architecture?
  The same program, downloaded for three ISAs: only one runs

  // this computer
  // light background: commands and code stay readable (never on a dark bar)
  #block(width: 100%, radius: 0.5em, fill: accent-fill, stroke: 1.2pt + accent, inset: (x: 0.8em, y: 0.4em), grid(
    columns: (1fr, auto),
    align: horizon,
    text(size: 1.1em, weight: "bold", fill: accent)[#cpu-icon this computer: ARM (64-bit)],
    box(width: 120pt, text(size: 0.9em, terminal("$ uname -m\naarch64"))),
  ))
  #v(0.4em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.8em,
    row-gutter: 0.5em,
    uncover("2-", arch-box(100%, [x86-64], [📄 `ruff-x86`], color: rgb("8e3b00"))),
    uncover("2-", arch-box(100%, [ARM], [📄 `ruff-arm`])),
    uncover("2-", arch-box(100%, [RISC-V], [📄 `ruff-riscv`], color: rgb("4a148c"))),
    uncover("3-", align(center, down-arrow(length: 0.7em))),
    uncover("3-", align(center, down-arrow(length: 0.7em))),
    uncover("3-", align(center, down-arrow(length: 0.7em))),
    uncover("3-", result(bad-color)[❌ Exec format error]),
    uncover("3-", result(ok-color)[✅ runs]),
    uncover("3-", result(bad-color)[❌ Exec format error]),
    grid.cell(colspan: 3, uncover("4-", info(width: 455pt)[🐢 Emulators: run x86-64 programs on ARM, slower][
      *macOS*: Rosetta 2 #h(0.8em) *Windows*: Prism #h(0.8em) *Linux* (e.g. NVIDIA DGX Spark): FEX, `box64`, `qemu-user` \
      a macOS _Universal binary_ holds x86-64 *and* ARM code in one file: no emulation needed
    ])),
  )

]

#slide[
  == `uname` and `file`
  Ask Linux: the ISA of the machine, and the ISA of a program

  // the architecture in the output, highlighted ("ARM aarch64" before
  // "aarch64", so it is matched as one piece)
  #block[
  #show regex("x86-64|ARM aarch64|UCB RISC-V|aarch64"): it => box(
    fill: changed-fill,
    stroke: 0.8pt + changed,
    radius: 2pt,
    outset: (x: 1pt, y: 2pt),
    text(fill: changed.darken(10%), weight: "bold", it),
  )
  #set text(size: 0.95em)
  #reveal-terminal(before: none, lines: (2, 6, 8), full: false)[```terminal
  $ uname -m
  aarch64
  $ file ruff-x86 ruff-arm ruff-riscv
  ruff-x86:   ELF 64-bit LSB pie executable, x86-64, ...
  ruff-arm:   ELF 64-bit LSB pie executable, ARM aarch64, ...
  ruff-riscv: ELF 64-bit LSB pie executable, UCB RISC-V, RVC, ...
  $ ./ruff-x86 --version
  bash: ./ruff-x86: cannot execute binary file: Exec format error
  ```]
  ]
  #v(0.3em)
  #only(1)[💡 `uname -m`: the ISA of *this machine* (`x86_64` on most PCs)]
  #only(2)[💡 `file`: reads the header of a program and tells which ISA it was compiled for]
  #only("3-", align(center, grid(
    columns: 5,
    column-gutter: 0.6em,
    align: horizon,
    code-file("ruff-x86")[#text(size: 0.8em)[x86-64 code, e.g. #bytes("83", "c0", "01", "...")]],
    draw-arrow(length: 2em, color: bad-color),
    unit(kind: "dark", icon: cpu-icon, width: 80pt, size: 0.75em, sub: [speaks only ARM])[ARM CPU],
    box(
      inset: (x: 0.6em, y: 0.4em),
      radius: 0.8em,
      fill: bad-color.lighten(88%),
      stroke: 1pt + bad-color,
      text(size: 0.8em, fill: bad-color.darken(10%))[❓ #raw("83 c0 01") ? \ *I do not understand these bytes*],
    ),
    text(size: 0.75em, fill: luma(60))[the kernel checks first: \ *Exec format error*],
  )))
]

// ---------------------------------------------------------------------------
// Cores
// ---------------------------------------------------------------------------

// the frame of a CPU chip, with its title bar, as the background of a drawing
#let chip-frame(width, height, title) = at(0pt, 0pt, box(
  width: width,
  height: height,
  radius: 0.4em,
  fill: white,
  stroke: 1.2pt + accent,
  clip: true,
  block(width: 100%, fill: accent, inset: (x: 0.5em, y: 0.3em), text(size: 0.7em, fill: white, weight: "bold")[#cpu-icon #title]),
))

// a program running on a core: a small orange tag
#let task(body) = box(inset: (x: 3pt, y: 2pt), radius: 2pt, fill: changed-fill, stroke: 0.6pt + changed, text(
  size: 0.55em,
  fill: changed.darken(15%),
  body,
))

// 1. four cores, each running a different program at the same moment
#let cores-drawing = drawing(width: 270pt, height: 150pt, {
  chip-frame(270pt, 150pt, [CPU chip with 4 cores])
  for (i, prog) in ([🌐 firefox], [🎵 music], [⌨️ bash], [🛠️ gcc]).enumerate() {
    let x = 12pt + calc.rem(i, 2) * 128pt
    let y = 30pt + calc.quo(i, 2) * 58pt
    at(x, y, unit(width: 118pt, height: 50pt, size: 0.65em, sub: [fetch, decode, execute])[core #i])
    pin(x + 59pt, y + 50pt, task[runs #prog])
  }
})

// 2. one core with two hardware threads: two programs (two `pc`s, two sets
// of registers) share the same execute units
#let smt-drawing = drawing(width: 270pt, height: 150pt, {
  chip-frame(270pt, 150pt, [one core, 2 hardware threads])
  at(12pt, 34pt, unit(width: 110pt, height: 40pt, size: 0.6em, sub: [own `pc` and registers])[thread 0])
  pin(67pt, 74pt, task[runs 🌐 firefox])
  at(12pt, 92pt, unit(width: 110pt, height: 40pt, size: 0.6em, sub: [own `pc` and registers])[thread 1])
  pin(67pt, 132pt, task[runs ⌨️ bash])
  line-arrow((124pt, 54pt), (166pt, 76pt), color: accent, thickness: 1.5pt)
  line-arrow((124pt, 112pt), (166pt, 92pt), color: accent, thickness: 1.5pt)
  at(168pt, 52pt, unit(kind: "dark", width: 90pt, height: 64pt, size: 0.6em, sub: [one set, shared])[execute units])
})

// 3. a real hybrid chip, Intel Core i9-14900K: 8 performance cores with 2
// hardware threads each, 16 efficiency cores in 4 clusters of 4 (each cluster
// shares an L2), 36 MB of L3 shared by all
#let p-cores = 8
#let e-cores = 16
#assert.eq(p-cores * 2 + e-cores, 32)
#let hybrid-drawing = drawing(width: 270pt, height: 168pt, {
  chip-frame(270pt, 168pt, [Intel Core i9-14900K])
  // P-cores: 2 rows of 4, two threads each
  at(10pt, 24pt, text(size: 0.6em, weight: "bold", fill: accent)[🏎️ 8 P-cores, 2 threads each])
  for i in range(p-cores) {
    let x = 10pt + calc.rem(i, 4) * 30pt
    let y = 36pt + calc.quo(i, 4) * 40pt
    at(x, y, box(width: 27pt, height: 36pt, radius: 3pt, fill: accent-fill, stroke: 1pt + accent, align(center + horizon, {
      text(size: 0.6em, weight: "bold", fill: accent)[P]
      v(-0.5em)
      box(width: 6pt, height: 6pt, radius: 3pt, fill: changed) + h(2pt) + box(width: 6pt, height: 6pt, radius: 3pt, fill: changed)
    })))
  }
  // E-cores: 4 clusters of 4
  at(140pt, 24pt, text(size: 0.6em, weight: "bold", fill: accent)[🌱 16 E-cores, 1 thread each])
  for c in range(4) {
    let cx = 140pt + calc.rem(c, 2) * 62pt
    let cy = 36pt + calc.quo(c, 2) * 40pt
    at(cx, cy, box(width: 58pt, height: 36pt, radius: 3pt, stroke: (paint: luma(150), thickness: 0.6pt, dash: "dashed")))
    for e in range(4) {
      at(cx + 4pt + calc.rem(e, 2) * 26pt, cy + 3pt + calc.quo(e, 2) * 16pt, box(
        width: 24pt,
        height: 14pt,
        radius: 2pt,
        fill: accent-fill,
        stroke: 0.6pt + accent,
        align(center + horizon, text(size: 0.5em, fill: accent)[E #h(0.5pt) #box(width: 4pt, height: 4pt, radius: 2pt, fill: changed)]),
      ))
    }
  }
  at(10pt, 120pt, unit(kind: "slot", width: 250pt, height: 18pt, size: 0.6em)[L3 cache: 36 MB, shared by all the cores])
  pin(135pt, 152pt, text(size: 0.65em)[#box(width: 6pt, height: 6pt, radius: 3pt, fill: changed) = one hardware thread: *8 × 2 + 16 = 32* CPUs for Linux])
})

#slide[
  == Cores and Threads
  One chip, many processors

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - *core*: a full processor inside the chip
      - 4 to 24 in a PC, hundreds in a server
    #uncover("2-")[#block[
      - *hardware threads* (_SMT_, _Hyper-Threading_): one core runs *two* programs, taking turns on the same execute units
    ]]
    #uncover("3-")[#block[
      - *hybrid* chips: two kinds of cores
        - 🏎️ _P-cores_: big and fast
        - 🌱 _E-cores_: small and frugal
    ]]
  ][
    #only(1, cores-drawing)
    #only(2, smt-drawing)
    #only("3-", hybrid-drawing)
  ]

  #v(0.2em)
  #only(1)[💡 4 cores = 4 programs running at the very same moment]
  #only(2)[💡 when one thread waits for RAM, the other one uses the core; Linux shows each thread as a CPU]
  #only("3-")[💡 24 cores, 32 threads: `nproc` says *32*; the OS puts the game on P-cores, mail sync on E-cores]
]

// what this machine has, from `lscpu -e`: 4 cores, each with its own L1,
// all sharing one L2
#let lscpu-drawing = drawing(width: 230pt, height: 62pt, {
  for i in range(4) {
    let x = i * 58pt
    at(x, 0pt, unit(width: 52pt, height: 22pt, size: 0.68em)[CPU #i #sym.eq core #i])
    at(x, 25pt, unit(kind: "slot", width: 52pt, height: 14pt, size: 0.62em)[L1 #i])
  }
  at(0pt, 44pt, unit(kind: "slot", width: 226pt, height: 16pt, on: true, size: 0.65em)[L2 0, shared by all 4 cores])
})

// the meaning of one column of `lscpu -e`
#let column(name, meaning) = (raw(name), meaning)

#slide[
  == Ask Linux: the CPUs
  `nproc` counts them, `lscpu -e` shows one line per CPU

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 8), full: false)[```terminal
    $ nproc
    4
    $ lscpu -e
    CPU NODE CLUSTER CORE L1d:L1i:L2 ONLINE
      0    0       0    0 0:0:0         yes
      1    0       0    1 1:1:0         yes
      2    0       0    2 2:2:0         yes
      3    0       0    3 3:3:0         yes
    ```]
    #v(0.3em)
    #uncover("3-", lscpu-drawing)
  ][
    #set text(size: 0.8em)
    #only(1)[
      #card([How many CPUs?])[
        how many programs can run *at the same time*: here *4* \
        Linux calls each hardware thread a *CPU*
      ]
    ]
    #only("2-")[
      #card([How to read the table])[
        #grid(
          columns: (auto, 1fr),
          column-gutter: 0.6em,
          row-gutter: 0.45em,
          ..column("CPU", [the CPU number Linux uses]),
          ..column("CORE", [the core it runs on: all different, so *1 thread per core*]),
          ..column("L1d:L1i:L2", [the caches it uses: data L1, instruction L1, L2; the *same number = shared*]),
          ..column("NODE", [the memory bank, for big servers]),
          ..column("CLUSTER", [a group of cores]),
          ..column("ONLINE", [`yes`: Linux uses it]),
        )
      ]
    ]
  ]

  #only("3-", place(bottom + right, dy: -0.2em, info(width: 225pt)[This machine][
    4 cores, 1 thread each; every core has its own L1 (`0` to `3`), all share one L2 (`0`)
  ]))
]

// a real hybrid laptop CPU (16 cores, no SMT), as `lscpu -e` shows it
#let hybrid-out = (
  "$ nproc",
  "16",
  "$ lscpu -e",
  "CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE    MAXMHZ   MINMHZ       MHZ",
  "  0    0      0    0 0:0:0:0          yes 5100.0000 400.0000 1000.2170",
  "  1    0      0    1 4:4:1:0          yes 5100.0000 400.0000 1000.0100",
  "  2    0      0    2 8:8:2:0          yes 5100.0000 400.0000  616.8610",
  "  3    0      0    3 12:12:3:0        yes 5200.0000 400.0000  620.5800",
  "  4    0      0    4 32:32:4:0        yes 4000.0000 400.0000  999.3280",
  "  5    0      0    5 34:34:4:0        yes 4000.0000 400.0000 1096.9500",
  "  6    0      0    6 36:36:4:0        yes 4000.0000 400.0000  999.9120",
  "  7    0      0    7 38:38:4:0        yes 4000.0000 400.0000  999.6950",
  "  8    0      0    8 40:40:5:0        yes 4000.0000 400.0000 1099.8380",
  "  9    0      0    9 42:42:5:0        yes 4000.0000 400.0000 1100.0770",
  " 10    0      0   10 44:44:5:0        yes 4000.0000 400.0000 1073.9640",
  " 11    0      0   11 46:46:5:0        yes 4000.0000 400.0000 1185.3230",
  " 12    0      0   12 64:64:8          yes 3700.0000 400.0000 1299.9730",
  " 13    0      0   13 66:66:8          yes 3700.0000 400.0000 1300.1600",
  " 14    0      0   14 68:68:8          yes 3700.0000 400.0000 1299.3879",
  " 15    0      0   15 70:70:8          yes 3700.0000 400.0000 1299.9460",
)
// the words to mark on the rows `from` to `to` (line numbers in hybrid-out)
#let rows-marks(from, to, f) = range(from, to + 1).map(n => f(n, hybrid-out.at(n))).flatten().chunks(2)
#let cache-of(t) = t.split(" ").filter(w => w.contains(":")).first()
#let mhz-of(t) = t.split(" ").filter(w => w.ends-with(".0000")).first()
#let mark-group(from, to) = rows-marks(from, to, (n, t) => (n, cache-of(t), n, mhz-of(t)))

// the chip of that laptop: 4 P-cores (own L2), 8 E-cores (two groups of 4,
// one L2 each), the shared L3, and 4 low-power E-cores apart, without L3.
// `on`: "p", "e", "lp" or none
#let hybrid-chip(on) = drawing(width: 200pt, height: 160pt, {
  let col(g) = if on == g { changed } else { accent }
  let core(x, y, s, g) = at(x, y, box(width: s, height: s, radius: 1.5pt, fill: col(g)))
  let l2(x, y, w, g) = at(x, y, box(width: w, height: 6pt, radius: 1pt, fill: col(g).lighten(55%), align(center + horizon, text(size: 0.4em)[L2])))
  let label(x, y, g, body) = at(x, y, text(size: 0.55em, weight: "bold", fill: if on == g { changed.darken(15%) } else { black }, body))
  // P-cores: each with its own L2
  label(0pt, 0pt, "p")[🏎️ 4 P-cores, 5.1 GHz]
  for i in range(4) { core(i * 22pt, 12pt, 18pt, "p"); l2(i * 22pt, 32pt, 18pt, "p") }
  // E-cores: two groups of 4, one L2 per group
  label(104pt, 0pt, "e")[🌱 8 E-cores, 4.0 GHz]
  for g in range(2) {
    for i in range(4) { core(104pt + i * 12pt + g * 50pt, 14pt, 10pt, "e") }
    l2(104pt + g * 50pt, 26pt, 46pt, "e")
  }
  // the L3, shared by the P-cores and the E-cores
  at(0pt, 44pt, box(width: 200pt, height: 12pt, radius: 2pt, fill: luma(225), align(center + horizon, text(size: 0.5em)[L3: shared by the P-cores and the E-cores])))
  // the low-power island
  at(40pt, 80pt, box(width: 120pt, height: 64pt, radius: 4pt, stroke: (paint: luma(140), thickness: 0.8pt, dash: "dashed")))
  label(48pt, 84pt, "lp")[🔋 4 LP E-cores, 3.7 GHz]
  for i in range(4) { core(62pt + i * 20pt, 100pt, 12pt, "lp") }
  l2(62pt, 116pt, 72pt, "lp")
  at(48pt, 128pt, text(size: 0.5em, fill: luma(90))[low-power island: no L3])
})

#slide[
  == A Hybrid Laptop CPU
  The same commands on a Panther Lake laptop (Intel Core Ultra): 16 cores of three kinds

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #set text(size: 0.5em)
    #mark-terminal(hybrid-out, (
      (19, ((1, "16"), (3, "CORE"))),
      (19, ((3, "L1d:L1i:L2:L3"), (3, "MAXMHZ")) + mark-group(4, 7)),
      (19, mark-group(8, 15)),
      (19, mark-group(16, 19)),
      (19, ((3, " MHZ"),) + range(4, 20).map(n => (n, hybrid-out.at(n).split(" ").last()))),
    ))
  ][
    #only(1, hybrid-chip(none))
    #only(2, hybrid-chip("p"))
    #only(3, hybrid-chip("e"))
    #only(4, hybrid-chip("lp"))
    #only("5-", hybrid-chip(none))
  ]

  #v(0.2em)
  #only(1)[💡 16 CPUs on 16 different cores: no Hyper-Threading here]
  #only(2)[💡 P-cores: the fastest (CPU 3 goes to 5.2 GHz), each with its own L2]
  #only(3)[💡 E-cores: slower, in two groups of 4; each group shares one L2 (`4` and `5`)]
  #only(4)[💡 LP E-cores: one L2 (`8`) and no L3 at all: they run the background work while the big cores sleep]
  #only("5-")[💡 `MHZ` is the speed right now: 600 - 1300 MHz, the cores slow down when there is little to do]
]

// a register drawn as a row of bits, grouped in bytes; `on` colors it
#let register-bits(n, cell: 5pt, color: accent) = box(stack(dir: ltr, spacing: 2pt, ..range(calc.quo(n, 8)).map(_ => box(
  stack(dir: ltr, ..range(8).map(_ => box(width: cell, height: 14pt, fill: color.lighten(80%), stroke: 0.4pt + color))),
))))

// one row: a name, the register, and right after it what its addresses reach
#let bits-row(name, n, reach, color: accent) = block(below: 0.8em, {
  box(width: 3.5em, text(weight: "bold", fill: color, name))
  register-bits(n, color: color)
  h(0.6em)
  box(baseline: -0.2em, text(size: 0.9em, reach))
})

// 16 GB of RAM as a bar, and the part a 32-bit address can reach (4 GiB)
#let ram-bar = {
  let w = 380pt
  let part = w * 4 / 16
  box(width: w, {
    stack(
      dir: ltr,
      box(width: part, height: 18pt, fill: ok-color.lighten(70%), stroke: 0.8pt + ok-color, align(center + horizon, text(
        size: 0.65em,
        weight: "bold",
        fill: ok-color.darken(20%),
      )[the first 4 GiB: reachable])),
      box(width: w - part, height: 18pt, fill: bad-color.lighten(85%), stroke: 0.8pt + bad-color, align(center + horizon, text(
        size: 0.65em,
        weight: "bold",
        fill: bad-color,
      )[❌ the rest: a 32-bit address cannot point here])),
    )
  })
}

#slide[
  == 32 or 64 bit?
  The size of a register, and so of a memory address

  #set text(size: 0.85em)
  #bits-row([32 bit], 32, [$2^32$ addresses = *4 GiB*], color: rgb("c26a2f"))
  #uncover("2-", bits-row([64 bit], 64, [$2^64$ = *16 EiB*]))
  #align(right, text(size: 0.8em, fill: luma(90), style: "italic")[one small box = one bit, grouped by 8 in bytes])

  #v(0.6em)
  #uncover("3-")[
    #align(center)[
      #text(size: 0.9em)[a laptop with *16 GB* of RAM, seen by a *32-bit* program:] \
      #v(0.2em)
      #ram-bar
    ]
  ]

  #only(2, place(bottom + center, dy: -0.2em, popup(width: 360pt, kind: "info")[64 bits on paper][
    real 64-bit CPUs use 48 to 57 address bits: 256 TiB to 128 PiB, still far more than any computer has
  ]))
  #only("4-", place(bottom + center, dy: 1em, popup(width: 400pt, kind: "info")[Today almost everything is 64-bit][
    `x86_64` / `amd64`, `aarch64` / `arm64`, `riscv64`; 32-bit lives on in microcontrollers and old programs
  ]))
]
