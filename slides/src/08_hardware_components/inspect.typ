#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Inspect and Measure #text(size: 10pt, weight: "regular")[\ _What hardware do I have, and how fast is it?_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 3 - _Devices_
      - Section 3.2 - _The sysfs Device Path_
    - Chapter 8 - _A Closer Look at Processes and Resource Utilization_
  + #uso-book
    - Chapter 8 - _Componente hardware_
      - Section 8.6 - _Abstractizarea dispozitivelor în Linux_
]

// one row of the toolbox: a part, the commands for it
#let tool-row(icon, part, cmds) = (
  text(size: 1.1em, icon),
  text(weight: "bold", part),
  cmds.map(c => tag(raw(c))).join(h(0.3em)),
)

#slide[
  == The Toolbox
  One command for every part, all of them read files of the kernel

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    #grid(
      columns: (auto, auto, 1fr),
      column-gutter: 0.6em,
      row-gutter: 0.5em,
      align: (center + horizon, left + horizon, left + horizon),
      ..tool-row(cpu-icon, [CPU], ("lscpu", "nproc")),
      ..tool-row("🧮", [memory], ("free -h", "lsmem")),
      ..tool-row("💾", [storage], ("lsblk", "df -h")),
      ..tool-row("🛣️", [PCIe], ("lspci", "lspci -tv", "lspci -k")),
      ..tool-row("🔌", [USB], ("lsusb", "lsusb -t")),
      ..tool-row("🌐", [network], ("ip link", "ethtool")),
      ..tool-row("📋", [everything], ("lshw -short", "sudo dmidecode")),
    )
  ][
    #set text(size: 0.8em)
    #uncover("2-")[
      #card([📂 Where the data comes from])[
        - `/proc/cpuinfo`, `/proc/meminfo`
        - `/sys/class/...`, `/sys/bus/...`
        - the firmware tables (`dmidecode`)
      ]
    ]
  ]

  #v(0.2em)
  #only(1)[💡 most of them work as a normal user; some show more with `sudo`]
  #only("2-")[💡 the kernel finds the hardware at boot and shows it as files in `/proc` and `/sys`: the commands only read and format them]
]

// `lshw -short` on a Panther Lake laptop, as a normal user and with sudo
// (trimmed with "...")
#let lshw-user = (
  "$ lshw -short",
  "H/W path       Device        Class          Description",
  "=======================================================",
  "                             system         Computer",
  "/0                           bus            Motherboard",
  "/0/0                         memory         64GiB System memory",
  "/0/1                         processor      Intel(R) Core(TM) Ultra X9 388H",
  "/0/100                       bridge         Core Ultra Processors (Series 3) PTL-H12Xe",
  "/0/100/2                     display        Panther Lake [Arc B390]",
  "/0/100/6                     bridge         Core Ultra Processors (Series 3) PCIe Root",
  "/0/100/6/0     /dev/nvme0    storage        WD_BLACK SN7100 2TB",
  "...",
  "/0/100/b                     accelerator    Core Ultra Processors (Series 3) NPU",
  "/0/100/14.3    wlp0s20f3     network        Core Ultra Processors (Series 3) CNVi Wi-Fi",
  "...",
  "/0/100/1f.3    card0         multimedia     Core Ultra Processors (Series 3) HD Audio",
  "...",
  "/4             input12       input          PIXA3854:00 093A:1343 Touchpad",
  "...",
)
#let lshw-root = (
  "$ sudo lshw -short",
  "H/W path        Device          Class          Description",
  "==========================================================",
  "                                system         Laptop 13 Pro (Intel Core Ultra Series 3",
  "/0                              bus            FRANMJCP09",
  "/0/0                            memory         1MiB BIOS",
  "/0/4                            processor      Intel(R) Core(TM) Ultra X9 388H",
  "/0/4/5                          memory         1600KiB L1 cache",
  "/0/4/6                          memory         24MiB L2 cache",
  "/0/4/7                          memory         18MiB L3 cache",
  "/0/11/0                         memory         64GiB Synchronous 8533 MHz (0.1 ns)",
  "...",
  "/0/100/6/0/1    /dev/nvme0n1    disk           2TB NVMe disk",
  "/0/100/6/0/1/1                  volume         599MiB Windows FAT volume",
  "...",
  "/0/100/14/0     usb3            bus            xHCI Host Controller",
  "/0/100/14/0/6                   multimedia     Laptop Webcam Module (2nd Gen)",
  "/0/100/14/0/7                   generic        Goodix Fingerprint USB Device",
  "...",
)

#slide[
  == Everything at Once: `lshw`
  The hardware as a tree: the motherboard, then what hangs on each bus

  #toolbox.side-by-side(columns: (1fr, 2fr), gutter: 1em)[
    #set text(size: 0.75em)
    - `H/W path`: the place in the tree
      - `/0/100/...`: behind the bridge `100`
    #uncover("2-")[#block[- `Class`: `memory`, `processor`, `display`, `storage`, `network`, ...]]
    #uncover("3-")[#block[- with `sudo`: what the *firmware* knows: the model, the BIOS, the caches, the RAM speed]]
    #uncover("4-")[#block[- and deeper in the tree: the partitions, the USB devices]]
  ][
    #set text(size: 0.52em)
    #mark-terminal(lshw-user, (
      (18, ((1, "H/W path"), (7, "/0/100"), (8, "/0/100/2"), (9, "/0/100/6"), (10, "/0/100/6/0"), (12, "/0/100/b"), (13, "/0/100/14.3"), (15, "/0/100/1f.3"))),
      (18, ((1, "Class"), (5, "memory"), (6, "processor"), (8, "display"), (10, "storage"), (12, "accelerator"), (13, "network"), (15, "multimedia"))),
    ), keep: false)
    #mark-terminal(lshw-root, (
      (18, ((0, "sudo"), (3, "Laptop 13 Pro (Intel Core Ultra Series 3"), (5, "1MiB BIOS"), (7, "1600KiB L1 cache"), (8, "24MiB L2 cache"), (9, "18MiB L3 cache"), (10, "64GiB Synchronous 8533 MHz (0.1 ns)"))),
      (18, ((12, "/0/100/6/0/1"), (13, "/0/100/6/0/1/1"), (15, "/0/100/14/0"), (16, "/0/100/14/0/6"), (17, "/0/100/14/0/7"))),
    ), start: 3)
  ]

  #v(0.2em)
  #only(1)[💡 `bridge` `100` is the host bridge (`00:00.0` in `lspci`): everything else hangs behind it]
  #only(2)[💡 the descriptions are the same names that `lspci` shows]
  #only(3)[💡 the firmware tables (_DMI_) can only be read by root: the same data as `sudo dmidecode`]
  #only("4-")[💡 the webcam and the fingerprint reader hang on USB, the USB controller on PCIe: one tree]
]

// the real output of `free -h` (a VM with 4 GiB), drawn as a grid so one
// column (or the Swap row) can be highlighted; `on`: the column index
// (1 total ... 6 available) or "swap"
#let free-out = (
  ("", "total", "used", "free", "shared", "buff/cache", "available"),
  ("Mem:", "3.8Gi", "192Mi", "2.6Gi", "4.0Mi", "1.0Gi", "3.5Gi"),
  ("Swap:", "0B", "0B", "0B", "", "", ""),
)
#let free-view(on) = block(width: 100%, fill: luma(242), radius: 4pt, inset: (x: 0.8em, y: 0.5em), {
  set text(font: mono, size: 0.7em)
  [#text(fill: accent, weight: "bold")[\$] #highlight-shell("free -h")]
  v(0.1em)
  grid(
    columns: (auto,) * 7,
    column-gutter: 1.4em,
    row-gutter: 0.15em,
    align: (left,) + (right,) * 6,
    ..free-out
      .enumerate()
      .map(((r, row)) => row
        .enumerate()
        .map(((c, cell)) => {
          let hot = (c == on and c > 0 and r < 2) or (on == "swap" and r == 2 and cell != "")
          box(
            inset: (x: 3pt, y: 2pt),
            radius: 2pt,
            fill: if hot { changed-fill } else { none },
            stroke: if hot { 0.8pt + changed } else { none },
            text(fill: if hot { changed.darken(20%) } else { luma(90) }, weight: if r == 0 { "bold" } else { "regular" }, cell),
          )
        }))
      .flatten(),
  )
})
#assert.eq(192 / 1024 + 2.6 + 1.0, 3.7875) // used + free + buff/cache: the total (3.8Gi)

// one explanation per step, in a box of fixed height (nothing moves)
#let free-steps = (
  (1, [📦 total], [all the RAM the kernel can use: 3.8 GiB]),
  (2, [🏃 used], [taken by the processes: only 192 MiB]),
  (3, [💤 free], [not used for anything at all: 2.6 GiB]),
  (5, [📄 buff/cache], [copies of files kept in RAM, to read them again faster: 1.0 GiB]),
  (6, [✅ available], [what a new program can still get: free + the cache the kernel can drop = 3.5 GiB]),
  ("swap", [💾 Swap], [disk space used as slow extra RAM when RAM runs out; 0B: this VM has none]),
)

#slide[
  == How Much Memory? `free`
  Used, free and _available_ are not the same thing

  #for (i, (col, _, _)) in free-steps.enumerate() {
    only(if i == free-steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }, free-view(col))
  }

  #v(0.5em)
  #block(height: 3.2em, width: 100%, {
    for (i, (_, title, body)) in free-steps.enumerate() {
      only(if i == free-steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }, card(title)[#set text(size: 0.85em); #body])
    }
  })

  #v(0.2em)
  #only("5-")[💡 a "full" RAM is good: unused RAM is wasted, so Linux fills it with cache and gives it back when needed]
]

#let top-out = (
  "$ yes > /dev/null &",
  "[1] 14",
  "$ top",
  "top - 12:47:55 up 45 min,  0 users,  load average: 0.32, 0.21, 0.12",
  "Tasks:  10 total,   2 running,   8 sleeping,   0 stopped,   0 zombie",
  "%Cpu(s):  5.0 us, 20.0 sy,  0.0 ni, 75.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st",
  "MiB Mem :   3906.7 total,   2656.9 free,    182.9 used,   1067.0 buff/cache",
  "    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND",
  "     14 affecti+  20   0    5628   1452   1340 R 100.0   0.0   0:02.15 yes",
  "      1 affecti+  20   0    3188   1324   1132 S   0.0   0.0   0:00.00 bwrap",
)

#slide[
  == Who Uses the CPU? `top`
  Start a busy process and watch it

  #set text(size: 0.66em)
  #mark-terminal(top-out, (
    (1, ()),
    (9, ((7, "%CPU"), (8, "100.0"))),
    (9, ((5, "75.0 id"),)),
    (9, ()),
  ))
  #set text(size: 1em / 0.66)

  #v(0.2em)
  #only(1)[💡 `yes` prints `y` forever: a CPU-hungry job; `&` starts it in the background (job `[1]`, PID `14`)]
  #only(2)[💡 `yes` uses *100%* of a CPU: one core, all the time]
  #only(3)[💡 but the whole machine is only *25%* busy (`75.0 id` = idle): this machine has 4 CPUs]
  #only("4-")[💡 a program that uses one core does not go faster on a CPU with more cores; stop it with `kill %1`, leave `top` with #kbd("q"), try `htop`]
]

#let dd-out = (
  "$ dd if=/dev/zero of=test.img bs=1M count=1024 oflag=direct",
  "1024+0 records in",
  "1024+0 records out",
  "1073741824 bytes (1.1 GB, 1.0 GiB) copied, 0.518263 s, 2.1 GB/s",
  "$ dd if=test.img of=/dev/null bs=1M iflag=direct",
  "1024+0 records in",
  "1024+0 records out",
  "1073741824 bytes (1.1 GB, 1.0 GiB) copied, 0.486887 s, 2.2 GB/s",
  "$ rm test.img",
  "$ dd if=/dev/zero of=/dev/null bs=1M count=20000",
  "...",
  "20971520000 bytes (21 GB, 20 GiB) copied, 0.909327 s, 23.1 GB/s",
)

#slide[
  == How Fast Is the Disk? `dd`
  Write 1 GiB, read it back, compare with RAM

  #set text(size: 0.66em)
  #mark-terminal(dd-out, (
    (3, ((0, "if=/dev/zero"), (0, "of=test.img"), (0, "oflag=direct"), (3, "2.1 GB/s"))),
    (7, ((4, "if=test.img"), (4, "iflag=direct"), (7, "2.2 GB/s"))),
    (11, ((9, "of=/dev/null"), (11, "23.1 GB/s"))),
  ))
  #set text(size: 1em / 0.66)

  #v(0.2em)
  #only(1)[💡 `dd` copies blocks from `if` to `of`; `/dev/zero` gives zeros forever; `oflag=direct` skips the RAM cache: \~2.1 GB/s to the disk]
  #only(2)[💡 read back \~2.2 GB/s: a (virtual) NVMe SSD; ⚠️ without `direct` you would measure the cache, not the disk]
  #only("3-")[💡 no disk at all, only the CPU and memory: *10×* faster. Real benchmarks: `fio` (disks), `iperf3` (network)]
]

// the real output of `vmstat 1 3`, drawn as a grid so every number sits
// under its header; `on`: the group to highlight ("cmd", "procs", "io",
// "cpu") or none
#let vmstat-groups = (("procs", 2), ("memory", 4), ("swap", 2), ("io", 2), ("system", 2), ("cpu", 6))
#let vmstat-head = ("r", "b", "swpd", "free", "buff", "cache", "si", "so", "bi", "bo", "in", "cs", "us", "sy", "id", "wa", "st", "gu")
#let vmstat-rows = (
  ("3", "3", "0", "49774780", "6524", "6861976", "0", "0", "6726", "3938", "19757", "44", "6", "4", "79", "11", "0", "0"),
  ("0", "4", "0", "49774528", "6524", "6861972", "0", "0", "0", "36", "8430", "10240", "1", "2", "79", "18", "0", "0"),
  ("0", "4", "0", "49775676", "6524", "6861972", "0", "0", "0", "0", "5069", "4778", "1", "1", "80", "18", "0", "0"),
)
#assert(vmstat-rows.all(r => r.len() == vmstat-head.len()))
#let k(c) = text(font: mono, weight: "bold", fill: changed.darken(25%), c)
#let vmstat-notes = (
  procs: [#k("r") waiting for a CPU \ #k("b") blocked, waiting for the disk],
  io: [#k("bi") blocks read per second \ #k("bo") blocks written per second],
  cpu: [#k("us") programs #h(0.5em) #k("sy") the kernel #h(0.5em) #k("id") idle \ #k("wa") waiting for I/O #h(0.5em) #k("st") taken by the host #h(0.5em) #k("gu") running VMs],
)
#let vmstat-view(on) = block(width: 100%, fill: luma(242), radius: 4pt, inset: (x: 0.8em, y: 0.6em), {
  set text(font: mono)
  let hot-box(hot, body) = box(
    fill: if hot { changed-fill } else { none },
    stroke: if hot { 0.8pt + changed } else { none },
    radius: 2pt,
    outset: (x: 1.5pt, y: 1.5pt),
    text(fill: if hot { changed.darken(25%) } else { luma(100) }, weight: if hot { "bold" } else { "regular" }, body),
  )
  [#text(fill: accent, weight: "bold")[\$] #highlight-shell("vmstat") #hot-box(on == "cmd", text(fill: black)[1 3])]
  v(0.2em)
  // which group each column belongs to
  let group-of = vmstat-groups.map(((g, n)) => (g,) * n).flatten()
  // every column as wide as its longest word: the numbers line up on the right
  let widths = range(vmstat-head.len()).map(i => {
    let n = calc.max(vmstat-head.at(i).len(), ..vmstat-rows.map(r => r.at(i).len()))
    n * 0.6em + 0.1em
  })
  grid(
    columns: widths,
    column-gutter: 0.9em,
    row-gutter: 0.35em,
    align: right,
    ..vmstat-groups.map(((g, n)) => grid.cell(colspan: n, align: center, inset: (bottom: 4pt), stroke: (bottom: 0.6pt + luma(160)), hot-box(on == g, g))),
    ..vmstat-head.enumerate().map(((i, h)) => hot-box(on == group-of.at(i), h)),
    ..vmstat-rows.flatten().map(v => text(fill: luma(100), v)),
    // a note under the highlighted group, pointing up at its columns; the
    // row has a fixed height, so nothing moves between steps
    ..vmstat-groups.enumerate().map(((gi, (g, n))) => grid.cell(colspan: n, box(width: 100%, height: 4.4em, {
      if on == g {
        let note = block(
          width: if g == "cpu" { 250pt } else { 175pt },
          inset: (x: 0.6em, y: 0.45em),
          radius: 3pt,
          fill: changed-fill,
          stroke: (top: 2pt + changed, rest: 0.6pt + changed),
          {
            set text(font: "Libertinus Serif", size: 1.15em, fill: black)
            set align(left)
            set par(leading: 0.4em)
            vmstat-notes.at(g)
          },
        )
        place(top + if gi == vmstat-groups.len() - 1 { right } else { left }, dy: 4pt, note)
      }
    }))),
  )
})

#slide[
  == Over Time: `vmstat`
  One line per second: processes, memory, disk and CPU

  #set text(size: 0.74em)
  #only(1, vmstat-view("cmd"))
  #only(2, vmstat-view("procs"))
  #only(3, vmstat-view("io"))
  #only("4-", vmstat-view("cpu"))
  #set text(size: 1em / 0.74)


  #v(0.2em)
  #only(1)[💡 `1 3`: one line every second, 3 lines; the first line is the average since boot]
  #only(2)[💡 `b` = 3 to 4: some processes are blocked, waiting for the disk]
  #only(3)[💡 the first line is the average since boot; then the disk moves almost nothing, yet the processes in `b` keep waiting]
  #only("4-")[💡 `wa` = 11 to 18%: the CPUs sit idle waiting for I/O; a high `wa` or `b`: the disk is the bottleneck, a high `r`: you need more CPU]
]

#slide[
  == More Tools
  Install them when you need them

  #set text(size: 0.8em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.6em,
    card([📋 Inventory])[`inxi -F`, `hwinfo`, `sudo dmidecode -t memory`],
    card([🌡️ Temperatures])[`sensors` (`lm-sensors`), `sudo smartctl -a /dev/nvme0` (disk health)],
    card([📈 Live load])[`htop`, `btop`, `iostat -x 1` (`sysstat`), `nvtop` (GPU)],
    card([💾 Disk speed])[`fio`, `sudo hdparm -t /dev/sda`, GNOME Disks],
    card([🌐 Network speed])[`iperf3` between two machines, `ping` for latency],
    card([🔬 Deep dive])[`perf stat`: instructions, cycles, cache misses],
  )
]
