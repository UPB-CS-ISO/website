#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Links Inside Links #text(size: 10pt, weight: "regular")[\ _PCIe and USB carry all the other connections_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 3 - _Devices_
  + #uso-book
    - Chapter 8 - _Componente hardware_
]

// ---------------------------------------------------------------------------
// Controllers translate
// ---------------------------------------------------------------------------

// one translation: the link the controller hangs on (PCIe or USB), the
// controller, and the link it gives out; `on` colors it orange
// e.g. #at(0pt, 20pt, translate-row([PCIe], [🌐 network card], [Ethernet], true))
#let translate-row(from, ctrl, to, on) = {
  let ink = if on { changed } else { luma(150) }
  box(width: 225pt, height: 20pt, {
    place(top + left, box(width: 34pt, height: 20pt, radius: 3pt, fill: accent, align(center + horizon, text(size: 0.6em, weight: "bold", fill: white, from))))
    place(top + left, line-arrow((35pt, 10pt), (46pt, 10pt), color: ink, thickness: 1pt, head: 4pt))
    place(top + left, dx: 47pt, unit(kind: "slot", width: 104pt, height: 20pt, on: on, size: 0.6em, ctrl))
    place(top + left, line-arrow((152pt, 10pt), (163pt, 10pt), color: ink, thickness: 1pt, head: 4pt))
    place(top + left, dx: 164pt, box(width: 61pt, height: 20pt, radius: 10pt, fill: if on { changed-fill } else { luma(240) }, stroke: 0.8pt + ink, align(center + horizon, text(size: 0.6em, weight: "bold", fill: if on { changed.darken(15%) } else { luma(80) }, to))))
  })
}

// left: the controllers on PCIe, right: the adapters on USB.
// `step` 1: PCIe, 2: USB, 3: the USB controller is itself on PCIe
#let translate-map(step) = drawing(width: 470pt, height: 160pt, {
  let p = step == 1
  let u = step == 2
  at(0pt, 0pt, text(size: 0.7em, weight: "bold")[on PCIe: a card or a chip])
  for (i, (ctrl, to)) in (
    ([🌐 network card], [Ethernet]),
    ([📶 Wi-Fi card], [Wi-Fi]),
    ([🎮 graphics card], [HDMI, DP]),
    ([💾 SATA controller], [SATA]),
    ([🔌 USB controller], [USB]),
  ).enumerate() {
    at(0pt, 18pt + i * 27pt, translate-row([PCIe], ctrl, to, p or (step == 3 and i == 4)))
  }
  at(245pt, 0pt, text(size: 0.7em, weight: "bold")[on USB: an adapter, a dongle])
  for (i, (ctrl, to)) in (
    ([🌐 USB-Ethernet adapter], [Ethernet]),
    ([🔤 USB-serial adapter], [UART]),
    ([🎧 Bluetooth dongle], [Bluetooth]),
    ([📶 Wi-Fi stick], [Wi-Fi]),
  ).enumerate() {
    at(245pt, 18pt + i * 27pt, translate-row([USB], ctrl, to, u))
  }
  if step >= 3 {
    // the USB controller feeds the whole USB column
    line-arrow((226pt, 136pt), (242pt, 136pt), color: changed, thickness: 1.5pt)
    line-arrow((242pt, 136pt), (258pt, 124pt), color: changed, thickness: 1.5pt)
    at(262pt, 128pt, text(size: 0.65em, fill: changed.darken(15%), weight: "bold")[the USB adapters hang on \ the USB controller, on PCIe])
  }
})

#slide[
  == Controllers Translate
  Every other link hangs on PCIe or USB, through a controller

  #only(1, translate-map(1))
  #only(2, translate-map(2))
  #only("3-", translate-map(3))

  #v(0.2em)
  #only(1)[💡 a _controller_ speaks PCIe on one side and Ethernet, Wi-Fi, HDMI, SATA, ... on the other]
  #only(2)[💡 the same links again, through a small adapter on USB: plug it in, a new network card appears]
  #only("3-")[💡 follow any link back to the CPU: it always ends on PCIe]
]

// ---------------------------------------------------------------------------
// Tunnels: USB4 and Thunderbolt
// ---------------------------------------------------------------------------

// one cable between a laptop and a dock, with packets of three kinds inside;
// the dock gives each kind out on its own port.
// `step` 1: USB, 2: + DisplayPort, 3: + PCIe
#let kinds = (
  usb: (accent, [USB], 1),
  dp: (ok-color, [DisplayPort], 2),
  pcie: (changed, [PCIe], 3),
)
#let tunnel(step) = drawing(width: 470pt, height: 130pt, {
  let shown(k) = kinds.at(k).at(2) <= step
  // the laptop and the cable, both centered on y = 70pt
  at(0pt, 35pt, unit(kind: "dark", width: 70pt, height: 70pt, size: 0.75em, icon: "💻")[laptop])
  at(70pt, 58pt, box(width: 232pt, height: 24pt, radius: 12pt, fill: luma(240), stroke: 1pt + luma(140)))
  at(96pt, 40pt, text(size: 0.65em, weight: "bold")[one USB-C cable: USB4 / Thunderbolt])
  let order = ("usb", "dp", "pcie", "usb", "pcie", "dp", "pcie", "usb", "dp", "pcie", "usb")
  for (i, k) in order.enumerate() {
    if shown(k) {
      at(80pt + i * 20pt, 64pt, box(width: 14pt, height: 12pt, radius: 2pt, fill: kinds.at(k).at(0)))
    }
  }
  // the legend, under the cable
  at(80pt, 90pt, {
    set text(size: 0.6em)
    for (k, v) in kinds {
      if shown(k) {
        box(width: 9pt, height: 8pt, radius: 1.5pt, fill: v.at(0))
        h(0.3em)
        v.at(1)
        h(1em)
      }
    }
  })
  // the dock: the cable comes in on the left (y = 70pt), each kind leaves on
  // its own port on the right (y = 40, 70, 100pt)
  at(302pt, 20pt, box(width: 70pt, height: 100pt, radius: 0.35em, fill: accent-fill, stroke: 1pt + accent))
  at(308pt, 24pt, text(size: 0.65em, weight: "bold", fill: accent)[🔌 dock])
  let outs = (("dp", 40pt, [🖥️ monitor]), ("pcie", 70pt, [💾 SSD, 🎮 GPU]), ("usb", 100pt, [⌨️ keyboard]))
  for (k, y, what) in outs {
    let (c, name, at-step) = kinds.at(k)
    if shown(k) {
      // inside the dock: from the cable to the port
      wire((308pt, 70pt), (348pt, y), stroke: 1.2pt + c)
      at(348pt, y - 4pt, box(width: 18pt, height: 8pt, radius: 1.5pt, fill: c))
      // out of the dock: to the device
      line-arrow((372pt, y), (396pt, y), color: c, thickness: 1.2pt)
      at(398pt, y - 13pt, box(width: 72pt, height: 26pt, inset: (x: 3pt), radius: 3pt, stroke: 0.8pt + c, align(
        left + horizon,
        text(size: 0.55em)[#text(weight: "bold", fill: c, name) \ #what],
      )))
    }
  }
})

#slide[
  == 🚇 Tunnels
  USB4 and Thunderbolt carry other links inside one cable

  #only(1, tunnel(1))
  #only(2, tunnel(2))
  #only("3-", tunnel(3))

  #v(0.2em)
  #only(1)[💡 a fast cable carries data in small packets, like a network]
  #only(2)[💡 packets for the monitor travel next to the USB ones: one cable, one more screen]
  #only("3-")[💡 PCIe packets too: a GPU or an SSD in an external box works as if it were inside]

  #only(4, place(center + horizon, info(width: 340pt)[Docks][
    a dock is a small hub at the end of the cable: it unpacks each kind and gives it out on its own port
  ]))
]

// ---------------------------------------------------------------------------
// See them in Linux
// ---------------------------------------------------------------------------

// `lspci` on a Panther Lake laptop (trimmed with "...")
#let laptop-lspci = (
  "$ lspci",
  "00:00.0 Host bridge: Intel Corporation Core Ultra Processors (Series 3) PTL-H12Xe (rev 04)",
  "00:02.0 VGA compatible controller: Intel Corporation Panther Lake [Arc B390] (rev 04)",
  "...",
  "00:0b.0 Processing accelerators: Intel Corporation Core Ultra Processors (Series 3) NPU (rev 04)",
  "00:0d.0 USB controller: Intel Corporation Core Ultra Processors (Series 3) Type-C Subsystem xHCI (rev 01)",
  "00:0d.2 USB controller: Intel Corporation Core Ultra Processors (Series 3) Thunderbolt DMA0 (rev 01)",
  "...",
  "00:14.0 USB controller: Intel Corporation Core Ultra Processors (Series 3) Standalone xHCI Controller (rev 01)",
  "00:14.3 Network controller: Intel Corporation Core Ultra Processors (Series 3) CNVi Wi-Fi (rev 01)",
  "00:14.7 Bluetooth: Intel Corporation Core Ultra Processors (Series 3) CNVi Bluetooth (rev 01)",
  "00:15.0 Serial bus controller: Intel Corporation Core Ultra Processors (Series 3) I2C #0 (rev 01)",
  "...",
  "00:1f.3 Audio device: Intel Corporation Core Ultra Processors (Series 3) HD Audio (rev 01)",
  "00:1f.4 SMBus: Intel Corporation Core Ultra Processors (Series 3) SMBus (rev 01)",
  "00:1f.5 Serial bus controller: Intel Corporation Core Ultra Processors (Series 3) SPI (flash) Controller (rev 01)",
  "01:00.0 Non-Volatile memory controller: Sandisk Corp WD_BLACK SN7100/WD PC SN7100S M.2 2280 NVMe SSD (DRAM-less) (rev 01)",
)

#slide[
  == See the Controllers
  Each `lspci` line is a controller: PCIe on one side, something else on the other

  #set text(size: 0.58em)
  #mark-terminal(laptop-lspci, (
    (16, ((2, "VGA compatible controller"), (16, "Non-Volatile memory controller"))),
    (16, ((9, "Network controller"), (10, "Bluetooth"), (13, "Audio device"))),
    (16, ((5, "USB controller"), (6, "Thunderbolt DMA0"), (8, "USB controller"))),
    (16, ((11, "I2C #0"), (14, "SMBus"), (15, "SPI (flash) Controller"))),
    (16, ((4, "NPU"),)),
  ))
  #set text(size: 1em / 0.58)

  #v(0.2em)
  #only(1)[💡 PCIe to the 🖥️ screen (the GPU) and to 💾 flash (the NVMe SSD)]
  #only(2)[💡 PCIe to the 📶 radio (Wi-Fi, Bluetooth) and to 🔊 sound]
  #only(3)[💡 PCIe to 🔌 USB; the Thunderbolt controller carries PCIe and DisplayPort through USB-C: the tunnels]
  #only(4)[💡 even the small buses: I²C (touchpad, sensors), SMBus (RAM modules), SPI (the firmware chip)]
  #only("5-")[💡 and a coprocessor: the NPU; the kernel has a driver for each controller, the controller does the rest]
]
