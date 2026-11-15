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

#slide[
  == Everything at Once: `lshw`
  The hardware as a tree: the motherboard, then what hangs on each bus

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - `H/W path`: the place in the tree
      - `/0/100/...`: behind the bridge `100`
    - `Class`: `processor`, `memory`, `storage`, `network`, `display`, ...
    #uncover("2-")[#block[
      - ⚠️ as a normal user it shows less: run it with `sudo`
    ]]
  ][
    #set text(size: 0.58em)
    #reveal-terminal(before: none, lines: (19,), full: false)[```terminal
    $ lshw -short
    WARNING: you should run this program as super-user.
    H/W path    Device   Class          Description
    ===============================================
                         system         Computer
    /0                   bus            Motherboard
    /0/0                 processor      cpu
    ...
    /0/3                 processor      cpu
    /0/4                 memory         4GiB System memory
    /0/100               bridge         Apple Inc.
    /0/100/1             network        Virtio network device
    /0/100/5    nvme1    storage        Apple Virtual NVMe Controller
    /0/100/5/1  nvme1n1  disk           NVMe disk
    ...
    /0/100/a    fb0      display        Virtio GPU
    /0/100/e             bus            Apple Inc.
    /2          input1   input          Apple Inc. Virtual USB Keyboard
    ...
    ```]
  ]

  #v(0.2em)
  #only(1)[💡 `bridge` `100` is the host bridge, the northbridge of this (virtual) machine: everything else hangs behind it]
  #only("2-")[💡 `sudo dmidecode` adds what the firmware knows: RAM modules, serial numbers, the BIOS version]
]

#slide[
  == How Much Memory? `free`
  Used, free and _available_ are not the same thing

  #set text(size: 0.75em)
  #reveal-terminal(before: none, lines: (4,), full: false)[```terminal
  $ free -h
                 total        used        free      shared  buff/cache   available
  Mem:           3.8Gi       192Mi       2.6Gi       4.0Mi       1.0Gi       3.5Gi
  Swap:             0B          0B          0B
  ```]

  #set text(size: 1em / 0.75)
  #v(0.3em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    card([🏃 used])[#set text(size: 0.75em); taken by the processes],
    uncover("2-", card([📄 buff/cache])[#set text(size: 0.75em); copies of files kept in RAM, to read them again faster]),
    uncover("3-", card([✅ available])[#set text(size: 0.75em); what a new program can still get: `free` + the cache the kernel can drop]),
  )

  #v(0.2em)
  #only("3-")[💡 a "full" RAM is good: unused RAM is wasted, so Linux fills it with cache and gives it back when needed]
]

#slide[
  == Who Uses the CPU? `top`
  Start a busy process and watch it

  #set text(size: 0.66em)
  #reveal-terminal(before: none, lines: (2, 11), full: false)[```terminal
  $ yes > /dev/null &
  [1] 14
  $ top
  top - 12:47:55 up 45 min,  0 users,  load average: 0.32, 0.21, 0.12
  Tasks:  10 total,   2 running,   8 sleeping,   0 stopped,   0 zombie
  %Cpu(s):  5.0 us, 20.0 sy,  0.0 ni, 75.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
  MiB Mem :   3906.7 total,   2656.9 free,    182.9 used,   1067.0 buff/cache

      PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
       14 affecti+  20   0    5628   1452   1340 R 100.0   0.0   0:02.15 yes
        1 affecti+  20   0    3188   1324   1132 S   0.0   0.0   0:00.00 bwrap
  ```]

  #set text(size: 1em / 0.66)
  #v(0.2em)
  #only(1)[💡 `yes` prints `y` forever: a CPU-hungry job; `&` starts it in the background (job `[1]`, PID `14`)]
  #only(2)[💡 `yes` uses *100%* = one core all the time, but `%Cpu(s)` shows *25%* busy (`75.0 id`): this machine has 4 CPUs]
  #only("3-")[💡 a program that uses one core does not go faster on a CPU with more cores; stop it with `kill %1`, leave `top` with #kbd("q"), try `htop`]
]

#slide[
  == How Fast Is the Disk? `dd`
  Write 1 GiB, read it back, compare with RAM

  #set text(size: 0.66em)
  #reveal-terminal(before: none, lines: (4, 9, 12), full: false)[```terminal
  $ dd if=/dev/zero of=test.img bs=1M count=1024 oflag=direct
  1024+0 records in
  1024+0 records out
  1073741824 bytes (1.1 GB, 1.0 GiB) copied, 0.518263 s, 2.1 GB/s
  $ dd if=test.img of=/dev/null bs=1M iflag=direct
  1024+0 records in
  1024+0 records out
  1073741824 bytes (1.1 GB, 1.0 GiB) copied, 0.486887 s, 2.2 GB/s
  $ rm test.img
  $ dd if=/dev/zero of=/dev/null bs=1M count=20000
  ...
  20971520000 bytes (21 GB, 20 GiB) copied, 0.909327 s, 23.1 GB/s
  ```]

  #set text(size: 1em / 0.66)
  #v(0.2em)
  #only(1)[💡 `dd` copies blocks from `if` to `of`; `/dev/zero` gives zeros forever; `oflag=direct` skips the RAM cache and writes to the disk]
  #only(2)[💡 read back \~2.2 GB/s: a (virtual) NVMe SSD; ⚠️ without `direct` you would measure the cache, not the disk]
  #only("3-")[💡 no disk at all, only the CPU and memory: *10×* faster. Real benchmarks: `fio` (disks), `iperf3` (network)]
]

#slide[
  == Over Time: `vmstat`
  One line per second: processes, memory, disk and CPU

  #set text(size: 0.68em)
  #reveal-terminal(before: none, lines: (6,), full: false)[```terminal
  $ vmstat 1 3
  procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
   r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
   1  0      0 2735332  42764 1035596    0    0   155   147  180  270  1  1 98  0  0
   0  0      0 2735720  42764 1035624    0    0     0  1396  512  216  0  0 100  0  0
   0  0      0 2737220  42764 1035624    0    0     0     0   87   76  0  0 100  0  0
  ```]

  #set text(size: 1em / 0.68)
  #v(0.3em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.6em,
    uncover("2-", card([🏃 procs])[#set text(size: 0.75em); `r`: waiting for a CPU \ `b`: waiting for the disk]),
    uncover("3-", card([💾 io])[#set text(size: 0.75em); `bi` / `bo`: blocks read / written per second]),
    uncover("4-", card([#cpu-icon cpu])[#set text(size: 0.75em); `us` programs, `sy` kernel, `id` idle, `wa` waiting for I/O]),
  )

  #v(0.2em)
  #only("4-")[💡 a high `wa` or `b`: the disk is the bottleneck; a high `r`: you need more CPU]
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
