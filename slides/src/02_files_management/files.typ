#import "/src/slides.typ": *
#import "logos.typ": *

#slide[
  = Files #text(size: 10pt, weight: "regular")[\ _how the file system is laid out_]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.19 - _Linux Directory Hierarchy Essentials_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.1.2 - _Structura ierarhică a sistemului de fișiere_
]

#slide[
  == Windows Layout

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    - Hierarchical structure starting from *drive letters* (`C:\`, `D:\`, etc.)
    - Each partition is an *independent file system*
    - Uses *backslashes (`\`)* and is *case-insensitive* by default
  ][
    ```
    C:\
    ├── Windows
    │   ├── system32
    │   └── ...
    ├── Program Files
    │   ├── App1
    │   └── App2
    ├── Users
    │   ├── Alice
    │   ├── Bob
    │   └── Public
    └── Temp
    ```
  ]
]

#slide[
  == Linux (POSIX) Layout

  #align(center)[
    #box(fill: white, inset: 5pt, radius: 0.3em)[#image("img/files/linux_fs.png", height: 75%)]
  ]

  ⚠️ no drive letters, *one single root*
]

// the Windows equivalent of a Linux folder, shown under its explanation
#let windows-eq(body) = block(
  width: 100%,
  inset: (x: 0.8em, y: 0.5em),
  radius: 0.3em,
  fill: luma(245),
  stroke: (left: 2pt + rgb("0078d4")),
)[#windows-logo() *Windows* \ #body]

// one entry per subslide: the tree lines to highlight and what to say about them
#let layout-steps = (
  ("all", [
    === The file system tree
    - every file and folder lives under *one single root* `/`
    - each folder has a _job_: programs, configuration, user data ...
    #windows-eq[one tree *per drive*: `C:\`, `D:\`, ... every partition gets a drive letter]
  ]),
  ((1,), [
    === `/` - root
    - the top of the hierarchy, the start of every absolute path
    - other partitions and disks are _mounted_ in folders below it
    #windows-eq[`C:\` - the root of the drive Windows is installed on]
  ]),
  ((2, 18), [
    === `/bin` and `/sbin` - essential programs
    - `/bin` - commands for everyone: `ls`, `cp`, `mv`, `cat`
    - `/sbin` - commands for the administrator: `mount`, `fsck`, `reboot`
    - 💡 on modern distributions they point to `/usr/bin` and `/usr/sbin`
    #windows-eq[`C:\Windows\System32` - `cmd.exe`, `notepad.exe`, `diskpart.exe`]
  ]),
  ((3,), [
    === `/boot` - starting the system
    - the kernel: `vmlinuz-6.x`
    - the initial RAM disk: `initrd.img-6.x`
    - the boot loader configuration: `grub/grub.cfg`
    #windows-eq[
      - the EFI partition (`\EFI\Microsoft\Boot\bootmgfw.efi`)
      - `C:\Windows\Boot`]
  ]),
  ((4,), [
    === `/dev` - devices
    - peripherals seen as files, created by the kernel
    - `/dev/sda` - the first disk, `/dev/sda1` - its first partition
    - `/dev/null` - discards everything written to it
    - `/dev/tty` - the current terminal
    #windows-eq[no folder, devices have special names: `\\.\PhysicalDrive0`, `COM1`, `NUL`]
  ]),
  ((5,), [
    === `/etc` - configuration
    - system wide settings, usually *text files*
    - `/etc/passwd` - the users
    - `/etc/hostname` - the name of the computer
    - `/etc/fstab` - what partitions to mount and where
    #windows-eq[The _Windows Registry_ (`HKEY_LOCAL_MACHINE`, ...)]
  ]),
  ((6,7,8), [
    === `/home` - the users' files
    - one folder for every user: `/home/alice`
    - documents, downloads, `Movies`, settings (`.bashrc`)
    - 🔒 a user can usually write *only* in their own folder
    #windows-eq[
      - `C:\Users\Ana` - `Videos`, `Downloads`, `Documents`
      - `C:\Users\Student`
      ]
  ]),
  ((9,), [
    === `/lib` - libraries
    - code shared by the programs in `/bin` and `/sbin`
    - `libc.so.6` - the C standard library
    - `/lib/modules/6.x/` - kernel modules (drivers)
    #windows-eq[
      - dynamic libraries `.dll` files in `C:\Windows\System32`
      - drivers in `C:\Windows\System32\drivers`
    ]
  ]),
  (lines-range(10, 12), [
    === `/media` - removable media
    - USB sticks, CDs, SD cards are mounted here _automatically_
    - `/media/alice/USB_STICK/`
    #windows-eq[a new drive letter: `E:\`, `F:\`]
  ]),
  (lines-range(13, 14), [
    === `/mnt` - temporary mounts
    - the administrator mounts file systems here _manually_
    - `mount /dev/sdb1 /mnt/temp`
    #windows-eq[a drive letter, or a volume mounted in an empty NTFS folder (_Disk Management_)]
  ]),
  ((15,), [
    === `/opt` - optional applications
    - third party applications that keep all their files together
    - `/opt/google/chrome/`
    #windows-eq[`C:\Program Files\Google\Chrome`]
  ]),
  ((16, 19), [
    === `/proc` and `/sys` - virtual file systems
    - generated by the kernel in memory, *not stored on disk*
    - `/proc/cpuinfo` - the processor, `/proc/1234/` - a running process
    - `/sys/class/net/` - the network interfaces
    #windows-eq[no files, the same information comes from
      - _Task Manager_
      - _Device Manager_
      - PowerShell (`Get-Process`)
    ]
  ]),
  ((17,), [
    === `/root` - the administrator's home
    - the home folder of the `root` user
    - ⚠️ not the same as `/`, the root of the file system
    #windows-eq[`C:\Users\Administrator`]
  ]),
  ((20,), [
    === `/tmp` - temporary files
    - every user and application can write here
    - 🧹 usually emptied when the system restarts
    #windows-eq[
      - `C:\Users\Alice\AppData\Local\Temp` (`%TEMP%`)
      - `C:\Windows\Temp`
      ]
  ]),
  (lines-range(21, 24), [
    === `/usr` - installed software
    - `/usr/bin` - most of the programs: `firefox`, `python3`, `git`
    - `/usr/lib` - their libraries
    - `/usr/share` - icons, documentation, _manual pages_
    #windows-eq[
      - `C:\Program Files`
      - `C:\Program Files (x86)`
    ]
  ]),
  ((25,), [
    === `/var` - data that changes
    - files that grow while the system is running
    - `/var/log/` - logs, `/var/cache/` - caches
    - `/var/lib/` - application data (e.g. databases)
    #windows-eq[`C:\ProgramData` for application data, `C:\Windows\Logs` and the _Event Viewer_ for logs]
  ]),
  ("all", [
    === In short
    #table(
      columns: (auto, 1fr, 1fr),
      table.header([], [#linux-logo() Linux], [#windows-logo() Windows]),
      [programs], [`/bin`, `/sbin`, `/usr`, `/opt`], [`C:\Windows`, `C:\Program Files`],
      [configuration], [`/etc`], [Registry],
      [user data], [`/home`, `/root`], [`C:\Users`],
      [changing data], [`/var`, `/tmp`], [`C:\ProgramData`, `%TEMP%`],
      [virtual], [`/dev`, `/proc`, `/sys`], [_no files_],
    )
  ]),
)

#slide[
  == Linux (POSIX) Layout Explained

  #toolbox.side-by-side(columns: (1fr, 3fr), gutter: 2em)[
    // 23 lines, shrink them so the whole tree fits in one column
    #set text(size: 8.5pt)
    #set par(leading: 0.45em)
    #highlight-code(layout-steps.map(s => s.at(0)))[```
    /
    ├── bin
    ├── boot
    ├── dev
    ├── etc
    ├── home
    │   ├── ana
    │   └── student
    ├── lib
    ├── media
    │   ├── cdrom
    │   └── usb
    ├── mnt
    │   └── temp
    ├── opt
    ├── proc
    ├── root
    ├── sbin
    ├── sys
    ├── tmp
    ├── usr
    │   ├── bin
    │   ├── lib
    │   └── share
    └── var
    ```]
  ][
    #for (idx, s) in layout-steps.enumerate() {
      only(idx + 1, s.at(1))
    }
  ]
]
