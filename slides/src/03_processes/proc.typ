#import "/src/slides.typ": *
#import "streams.typ": *

#slide[
  = The `/proc` Folder #text(size: 10pt, weight: "regular")[\ _Look inside the processes_]
]

#slide[
  == Bibliography
  For this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 4 - _Disks and Filesystems_
      - Section 4.2.12 - _Special-Purpose Filesystems_
    - Chapter 8 - _A Closer Look at Processes and Resource Utilization_
      - Section 8.1 - _Tracking Processes_
      - Section 8.2 - _Finding Open Files with lsof_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.2.2 - _Utilitare pentru urmărirea proceselor_
      - Section 4.8 - _Anexa: Sistemul de fișiere procfs_
]

#slide[
  == `/proc` - the process file system
  Files made by the kernel, when they are read

  #toolbox.side-by-side(columns: (1fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #highlight-code((lines-range(2, 6), (10,), (7,)), start: 1)[```
    /proc
    ├── 1         # systemd
    ├── 2         # kthreadd
    ├── ...
    ├── 4100      # bash
    ├── 4321      # ...
    ├── self
    ├── cpuinfo
    ├── meminfo
    ├── uptime
    └── ...
    ```]
  ][
    #reveal-terminal(start: 2, before: none, lines: (4, 6), full: false)[```terminal
    $ ls -l /proc/uptime    # the size is 0
    -r--r--r-- 1 root root 0 Oct 12 09:12 /proc/uptime
    $ cat /proc/uptime      # but it has contents
    244699.78 368114.32
    $ readlink /proc/self   # the PID of readlink
    4325
    ```]
  ]

  #set text(size: 0.9em)
  #uncover("1-")[#block[- `/proc` is a _virtual_ file system: every process has a folder, its name is the *PID*]]
  #uncover("2-")[#block[- *nothing* is stored on the disk: the *kernel* writes the contents when a process *reads* the file]]
  #uncover("3-")[#block[- `/proc/self` - the folder of the process that reads it: `ls /proc/self` lists the folder of `ls`]]
]

#slide[
  == `/proc/<PID>` - inside a process
  The resources of a process, as files

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #highlight-code(((9,), (2, 3, 6), (4, 7), (5, 8), "all"))[```
    /proc/4321
    ├── cmdline   # the arguments
    ├── comm      # the name
    ├── cwd       # -> the current folder
    ├── environ   # the environment variables
    ├── exe       # -> the executable file
    ├── fd/       # the File Descriptor Table
    ├── maps      # the memory map
    └── status    # PID, PPID, state, ...
    ```]
  ][
    #only(1)[
      === 🪪 Identification
      - `status` has the _PID_, the _PPID_ and the _state_ of the process
    ]
    #only(2)[
      === 📄 The program
      - `exe` - a link to the executable that was loaded (`exec`)
      - `cmdline` - the arguments it got
      - `comm` - its name
    ]
    #only(3)[
      === 💾 Data
      - `fd/` - one link for every open file descriptor
      - `cwd` - a link to the current folder
    ]
    #only(4)[
      === 🧠 Memory
      - `maps` - where the code, the libraries and the variables are in memory
      - `environ` - the environment variables
    ]
    #only("5-")[
      ```terminal
      $ readlink /proc/self/exe
      /usr/bin/readlink
      $ cd /tmp
      $ readlink /proc/self/cwd
      /tmp
      ```
    ]
  ]
]

#slide[
  == `/proc/<PID>/status`
  What the kernel knows about a process

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (10, 12), full: false)[```terminal
    $ cat /proc/self/status
    Name:     cat
    Umask:    0022
    State:    R (running)
    ...
    Pid:      4330
    PPid:     4100
    ...
    Threads:  1
    ...
    $ echo $$     # the PID of the shell
    4100
    ```]
  ][
    #set text(size: 0.9em)
    #uncover("1-")[#block[- `State` - one of the _process states_]]
    #uncover("1-")[#block[- `Threads` - how many threads run in parallel]]
    #uncover("2-")[#block[- the `PPid` of `cat` is the shell: the shell called `fork` and `exec` to start it]]
  ]

  #v(1em)
  #only("3-")[💡 `ps`, `top` and `pstree` do not ask the kernel directly: they *read the files* in `/proc`]
]

#slide[
  == `/proc/<PID>/fd` - the File Descriptor Table
  Every open file descriptor is a link

  // the `lsof` example replaces the `ls` one in the same place
  #only("1-2")[#reveal-terminal(before: none, lines: (5, 6))[```terminal
  $ ls -l /proc/self/fd
  total 0
  lrwx------ 1 alice alice 64 Oct 12 09:12 0 -> /dev/pts/0
  lrwx------ 1 alice alice 64 Oct 12 09:12 1 -> /dev/pts/0
  lrwx------ 1 alice alice 64 Oct 12 09:12 2 -> /dev/pts/0
  lr-x------ 1 alice alice 64 Oct 12 09:12 3 -> /proc/4331/fd
  ```]]
  #only("3-")[```terminal
  $ lsof -p 4100     # the open files of the shell (PID 4100)
  COMMAND  PID USER   FD  TYPE DEVICE SIZE/OFF NODE NAME
  ...
  bash    4100 alice  0u  CHR  136,0      0t0    3 /dev/pts/0
  bash    4100 alice  1u  CHR  136,0      0t0    3 /dev/pts/0
  bash    4100 alice  2u  CHR  136,0      0t0    3 /dev/pts/0
  ```]

  #toolbox.side-by-side(columns: (1fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.95em)
    #only(1)[#fd-table("ls", (
      (0, file("/dev/pts/0"), false),
      (1, file("/dev/pts/0"), false),
      (2, file("/dev/pts/0"), false),
    ))]
    #only(2)[#fd-table("ls", (
      (0, file("/dev/pts/0"), false),
      (1, file("/dev/pts/0"), false),
      (2, file("/dev/pts/0"), false),
      (3, file("/proc/4331/fd"), true),
    ))]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 `0`, `1` and `2` point to `/dev/pts/0`, the _terminal_: it is both the keyboard and the display]
    #only(2)[💡 `ls` opened the folder it lists, at the first free index: `3`, just like `sort` opened `fruits.txt`]
  ]

  #set text(size: 0.9em)
  #only("3-")[
    💡 `lsof -p <PID>` lists the same information: it reads `/proc/<PID>/fd`\
    ⚠️ only the *owner* of the process (or `root`) can look inside its `fd/`\
    💡 a redirect changes these links: with `> out.txt`, `1` points to `out.txt`
  ]
]

#slide[
  == `/proc` - the whole system
  Not only processes

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #highlight-code(((2,), (3,), (4, 5), (6,), "all"))[```
    /proc
    ├── cpuinfo   # the processors
    ├── meminfo   # the memory
    ├── uptime    # seconds since boot
    ├── loadavg   # how busy the system is
    └── mounts    # the mounted file systems
    ```]

    #uncover(5)[💡 most of the system tools just *read* `/proc` and format the result nicely]
  ][
    #set text(size: 0.85em)
    #table(
      columns: (auto, auto),
      inset: (x: 0.6em, y: 0.4em),
      table.header([file], [shown by]),
      [`/proc/cpuinfo`], [`lscpu`],
      [`/proc/meminfo`], [`free`],
      [`/proc/uptime`, `/proc/loadavg`], [`uptime`],
      [`/proc/mounts`], [`mount`],
    )
    #set text(size: 1em / 0.85)
    ```terminal
    $ head -3 /proc/meminfo
    MemTotal:       65296068 kB
    MemFree:        10651832 kB
    MemAvailable:   53764732 kB
    ```
  ]
]
