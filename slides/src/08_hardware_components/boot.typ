#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = How It Boots #text(size: 10pt, weight: "regular")[\ _From pressing the power button to the login screen_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 5 - _How the Linux Kernel Boots_
    - Chapter 6 - _How User Space Starts_
]

// ---------------------------------------------------------------------------
// The boot chain
// ---------------------------------------------------------------------------

// one stage of a boot chain: an emoji, a name, where it lives; `on` orange
#let stage(x, icon, name, where, on, width: 68pt) = at(x, 0pt, unit(
  kind: if on { "unit" } else { "slot" },
  on: on,
  width: width,
  height: 68pt,
  size: 0.85em,
  icon: icon,
  sub: where,
  name,
))

// a chain of stages, left to right, with arrows; `on`: the index shown
// orange (each stage starts the next one)
#let chain(stages, on, width: 72pt, gap: 8pt) = drawing(width: stages.len() * (width + gap) - gap, height: 70pt, {
  for (i, (icon, name, where)) in stages.enumerate() {
    let x = i * (width + gap)
    stage(x, icon, name, where, i == on, width: width)
    if i < stages.len() - 1 {
      line-arrow((x + width + 1pt, 34pt), (x + width + gap - 1pt, 34pt), color: if i == on { changed } else { luma(140) }, thickness: 1.2pt, head: 4pt)
    }
  }
})

// what the current stage does: a light box with an orange bar, of fixed
// height so nothing moves between steps
#let explain-box(body, height: 4.6em) = block(
  width: 100%,
  height: height,
  inset: (x: 0.8em, y: 0.6em),
  radius: 0.3em,
  fill: changed-fill,
  stroke: (left: 3pt + changed),
  body,
)

#let pc-boot = (
  ("⚡", [power on], [the CPU wakes up]),
  ("📜", [firmware], [UEFI or BIOS, in a flash chip]),
  ("🥾", [bootloader], [GRUB, on the disk]),
  ("🐧", [kernel], [Linux, in `/boot`]),
  ("⚙️", [init], [systemd, PID 1]),
  ("🔑", [login], [a login screen]),
)

#slide[
  == From Power to Login
  Each stage loads the next one into RAM and starts it

  #for i in range(pc-boot.len()) {
    only(if i == pc-boot.len() - 1 { str(i + 1) + "-" } else { i + 1 }, chain(pc-boot, i))
  }

  #v(0.8em)
  #explain-box({
    only(1)[the RAM is empty, there is no operating system yet; the CPU starts at a fixed address, wired to the *firmware* chip]
    only(2)[the *firmware* tests the hardware (_POST_), sets up the RAM, finds a disk it can boot from and starts the *bootloader* on it]
    only(3)[the *bootloader* shows a menu (several kernels, Windows, ...) and loads the *kernel* and a small first file system (_initramfs_) into RAM]
    only(4)[the *kernel* starts the drivers, finds the hardware, mounts the root file system `/` and starts the first process]
    only(5)[*init* (`systemd`, PID 1) starts the services: the network, the logs, the graphical interface]
    only("6-")[finally, a *login* screen or a text prompt: the system is ready]
  })

  #only("6-")[💡 a chain: each stage is small and knows just enough to start the next one ("pull yourself up by your bootstraps")]
]

// ---------------------------------------------------------------------------
// BIOS or UEFI
// ---------------------------------------------------------------------------

// what the firmware reads from the disk: BIOS, the first 512 bytes (raw
// code); UEFI, a program stored as a file
#let boot-disk(uefi) = box(width: 215pt, height: 74pt, {
  place(top + left, box(width: 215pt, height: 74pt, radius: 6pt, fill: luma(240), stroke: 1pt + luma(140)))
  place(top + left, dx: 6pt, dy: 4pt, text(size: 0.7em, fill: luma(90))[💾 the disk])
  if not uefi {
    place(top + left, dx: 8pt, dy: 22pt, box(width: 56pt, height: 44pt, radius: 3pt, fill: changed-fill, stroke: 1.2pt + changed, align(
      center + horizon,
      text(size: 0.72em, weight: "bold", fill: changed.darken(15%))[first \ 512 bytes],
    )))
    place(top + left, dx: 74pt, dy: 30pt, text(size: 0.72em, fill: luma(80))[raw code at a fixed place: \ no files, no names])
  } else {
    place(top + left, dx: 10pt, dy: 22pt, {
      set text(size: 0.72em, font: mono)
      set par(leading: 0.5em)
      [📁 EFI \ #h(1em) 📁 fedora \ #h(2em) #box(fill: changed-fill, stroke: 1.2pt + changed, radius: 2pt, outset: (x: 2pt, y: 1.5pt), text(weight: "bold", fill: changed.darken(15%))[📄 grubx64.efi])]
    })
    place(top + left, dx: 132pt, dy: 30pt, text(size: 0.72em, fill: luma(80))[a program, \ stored as a *file*])
  }
})

#slide[
  == BIOS or UEFI?
  The firmware of a PC, old and new

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === 👴 BIOS (1981)
    #boot-disk(false)
    #set text(size: 0.85em)
    - runs the *first 512 bytes* of the disk
    - 16-bit, text setup screen
  ][
    #uncover("2-")[
      === 🆕 UEFI (PCs since \~2011)
      #boot-disk(true)
      #set text(size: 0.85em)
      - understands *files*: runs a program from the disk
      - 64-bit, graphics, mouse, network boot
    ]
  ]

  #v(0.3em)
  #only(1)[💡 everybody still says "BIOS", even when the computer has UEFI]
  #only(2)[💡 UEFI is a small operating system of its own: it runs before yours]
  #only("3-", place(bottom + center, dy: -0.2em, info(width: 380pt)[Secure Boot][
    UEFI runs only bootloaders *signed* with a trusted key: malware cannot replace GRUB; Linux distributions use a small signed loader, _shim_
  ]))
]

// ---------------------------------------------------------------------------
// SoC: boot ROM, SPL, U-Boot
// ---------------------------------------------------------------------------

#let soc-boot = (
  ("🔒", [boot ROM], [inside the SoC, cannot change]),
  ("🪜", [SPL], [small first stage, sets up the RAM]),
  ("🥾", [U-Boot], [the bootloader]),
  ("🐧", [kernel], [\+ the _device tree_]),
)

#slide[
  == Booting an SoC
  Phones, routers, boards: a tiny program in the chip, then U-Boot

  #for i in range(soc-boot.len()) {
    only(if i == soc-boot.len() - 1 { str(i + 1) + "-" } else { i + 1 }, chain(soc-boot, i, width: 96pt, gap: 18pt))
  }

  #v(0.5em)
  #explain-box(height: 3.4em, {
    only(1)[the *boot ROM* is burned into the SoC: it looks for code on the SD card, the eMMC or the SPI flash, using only the small RAM inside the chip]
    only(2)[the *SPL* (_Secondary Program Loader_) is tiny: it starts the external RAM, then loads U-Boot into it]
    only(3)[*U-Boot* is the bootloader of most boards: it loads the kernel from the SD card, the eMMC or the network]
    only("4-")[the *kernel* gets a _device tree_ (`.dtb`), a file that lists the hardware: many parts of an SoC cannot be asked, like on PCIe or USB]
  })

  // the same step on a Raspberry Pi 5
  #block(
    width: 100%,
    height: 4.2em,
    inset: (x: 0.8em, y: 0.5em),
    radius: 0.3em,
    fill: rgb("fde8ee"),
    stroke: (left: 3pt + rgb("c51a4a")),
    {
      set text(size: 0.9em)
      let pi(body) = [#text(weight: "bold", fill: rgb("c51a4a"))[🍓 Raspberry Pi 5:] #body]
      only(1, pi[the boot ROM of the BCM2712 chip reads the next stage from a small *EEPROM* chip on the board])
      only(2, pi[the *bootloader in the EEPROM* starts the RAM and finds the system (SD card, NVMe, USB, network); on a Pi 1 to 3 the file `bootcode.bin` on the SD card does this; a Pi 4 or 5 first looks for `recovery.bin`, to rewrite the EEPROM])
      only(3, pi[no U-Boot by default: the EEPROM bootloader reads `config.txt` and loads the kernel itself])
      only("4-", pi[the kernel `kernel_2712.img` with `bcm2712-rpi-5-b.dtb`; `dtoverlay=` lines in `config.txt` add the boards you plug on top (_HATs_)])
    },
  )

]

// ---------------------------------------------------------------------------
// In Linux
// ---------------------------------------------------------------------------

#slide[
  == See the Boot in Linux
  A few commands that look back at how this boot went

  #nice-table(
    columns: (auto, 1fr),
    size: 0.82em,
    header: ([command], [what it shows]),
    rows: (
      ([`ls /sys/firmware/efi`], [exists: the system booted with UEFI; missing: BIOS]),
      ([`sudo efibootmgr`], [the boot entries of the UEFI firmware, in order]),
      ([`ls /boot`], [the kernels (`vmlinuz-...`) and their _initramfs_ (`initrd.img-...`)]),
      ([`cat /proc/cmdline`], [the parameters the bootloader gave to the kernel]),
      ([`sudo dmesg | less`], [the messages of the kernel, from the first second]),
      ([`systemd-analyze`], [how long each stage took: firmware, loader, kernel, user space]),
    ),
    shown: (none, none, 2, 2, 3, 3),
  )

  #v(0.2em)
  #only(1)[💡 `/sys/firmware` is what the firmware left for the kernel to read]
  #only(2)[💡 GRUB reads its menu from `/boot/grub/grub.cfg`; change it with `/etc/default/grub` and `sudo update-grub`]
  #only("3-")[💡 `systemd-analyze blame`: which service made the boot slow]
]
