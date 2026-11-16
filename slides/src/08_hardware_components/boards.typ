#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Single-Board Computers #text(size: 10pt, weight: "regular")[\ _An SoC, some RAM and the connectors on one small board_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 8 - _Componente hardware_
]

// A photo of a Raspberry Pi 5 (960 x 640 px) with orange frames over its
// parts; `marks`: (x0, y0, x1, y1) in pixels of the photo
#let pi-width = 228pt
#let pi-photo(marks) = box(width: pi-width, {
  image("img/raspberry-pi-5.jpg", width: pi-width)
  let k = pi-width / 960
  for (x0, y0, x1, y1) in marks {
    place(top + left, dx: x0 * k, dy: y0 * k, rect(width: (x1 - x0) * k, height: (y1 - y0) * k, radius: 2pt, stroke: 2pt + changed))
  }
})
#let pi-soc = ((282, 280, 462, 458),)
#let pi-ram = ((290, 145, 448, 265),)
#let pi-rp1 = ((557, 180, 688, 308), (745, 28, 933, 192), (745, 208, 933, 378), (702, 392, 928, 568), (105, 38, 618, 100), (507, 420, 613, 568))
#let pi-rest = ((102, 524, 208, 608), (259, 522, 338, 608), (392, 522, 471, 608), (46, 220, 98, 362), (26, 258, 50, 334), (85, 400, 175, 475))

#slide[
  == The Raspberry Pi 5
  An SoC on a small board

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1em)[
    #set text(size: 0.8em)
    - *BCM2712*: the SoC, with the CPU, the GPU and the video decoder
    #uncover("2-")[#block[- 🧮 *RAM*: one chip next to the SoC, 1 to 16 GB]]
    #uncover("3-")[#block[- *RP1*: a second chip for the slow I/O, on a PCIe x4 link: USB, Ethernet, GPIO, camera]]
    #uncover("4-")[#block[- the SoC itself drives the 2 HDMI ports, the SD card and a small PCIe connector (for an NVMe SSD)]]
  ][
    #only(1, pi-photo(pi-soc))
    #only(2, pi-photo(pi-ram))
    #only(3, pi-photo(pi-rp1))
    #only("4-", pi-photo(pi-rest))
    #align(right, text(size: 0.45em, fill: luma(120))[Photo: SparkFun Electronics, CC BY 2.0, via Wikimedia Commons (cropped)])
  ]

  #v(0.2em)
  #only(1)[💡 the whole computer is the SoC (under the metal lid); the board only brings power and connectors]
  #only(2)[💡 the RAM is a separate chip here, not on the SoC package: on a phone it often sits on top of the SoC]
  #only(3)[💡 RP1 works like the old *southbridge*: the slow ports, behind one link]
  #only("4-")[💡 5 V comes in over USB-C, a power chip (_PMIC_) shares it out; the SD card slot is underneath]
]

// a photo of the Arduino UNO Q (933 x 700 px) with orange frames, like the Pi
#let q-width = 205pt
#let q-photo(marks, back: false) = box(width: q-width, {
  image(if back { "img/arduino-uno-q-back.jpg" } else { "img/arduino-uno-q.jpg" }, width: q-width)
  let k = q-width / 933
  for (x0, y0, x1, y1) in marks {
    place(top + left, dx: x0 * k, dy: y0 * k, rect(width: (x1 - x0) * k, height: (y1 - y0) * k, radius: 2pt, stroke: 2pt + changed))
  }
})
#let q-linux = ((396, 240, 548, 388), (386, 112, 560, 238))
#let q-arduino = ((272, 48, 832, 94), (376, 608, 832, 652), (428, 410, 756, 608), (796, 450, 860, 530))
// on the back: the STM32 microcontroller; the eMMC and the two expansion connectors
#let q-stm32 = ((308, 474, 398, 564),)
#let q-back = ((248, 280, 390, 436), (156, 122, 224, 584), (686, 122, 758, 584))
#let q-io = ((66, 166, 174, 282), (228, 208, 304, 274), (140, 402, 282, 594), (636, 174, 722, 274))

#slide[
  == The Arduino UNO Q
  Two computers on one board: Linux and a microcontroller

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1em)[
    #set text(size: 0.78em)
    - 🐧 *Linux side*: the Qualcomm *QRB2210* SoC (4 Cortex-A53, a GPU) and its RAM
    #uncover("2-")[#block[- 🔌 *Arduino side*: the classic UNO pins, an LED matrix, a _Qwiic_ (I²C) connector]]
    #uncover("3-")[#block[- they are driven by an STM32 *microcontroller*, on the back]]
    #uncover("4-")[#block[- one *USB-C* for power, data and a screen; Wi-Fi + Bluetooth; a power chip]]
    #uncover("5-")[#block[- on the back: the *eMMC* storage and two connectors for cameras, displays and audio]]
  ][
    #only(1, q-photo(q-linux))
    #only(2, q-photo(q-arduino))
    #only(3, q-photo(q-stm32, back: true))
    #only(4, q-photo(q-io))
    #only("5-", q-photo(q-back, back: true))
    #align(right, text(size: 0.45em, fill: luma(120))[Photos: Arduino])
  ]

  #v(0.2em)
  #only(1)[💡 the SoC runs Debian Linux: programs in Python, a web browser on the board]
  #only(2)[💡 the same pins as the classic Arduino UNO: the old add-on boards (_shields_) still fit]
  #only(3)[💡 the STM32 is a *real-time coprocessor*: Linux hands it the pins, it answers in microseconds]
  #only(4)[💡 a small chip turns the USB-C port into DisplayPort: plug in a screen and it is a tiny PC]
  #only("5-")[💡 the storage is a separate chip (Kingston eMMC), like an SSD soldered on the board]
]

// one board in the comparison: a card of fixed height with (label, value) rows
#let board-card(title, rows, color: accent) = card(title, height: 9.4em, color: color)[
  #set text(size: 0.85em)
  #grid(
    columns: (auto, 1fr),
    column-gutter: 0.5em,
    row-gutter: 0.7em,
    ..rows.map(((k, v)) => (text(weight: "bold", fill: luma(90), k), v)).flatten(),
  )
]

#slide[
  == Two Boards, Two Jobs
  The same idea: an SoC on a small board

  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    board-card([🍓 Raspberry Pi 5], (
      ([SoC], [Broadcom BCM2712]),
      ([CPU], [4 × Cortex-A76]),
      ([extra], [VideoCore VII GPU]),
      ([RAM], [1 - 16 GB]),
      ([for], [a small, cheap PC]),
    ), color: rgb("c51a4a")),
    uncover("2-", board-card([🔌 Arduino UNO Q], (
      ([SoC], [Qualcomm QRB2210]),
      ([CPU], [4 × Cortex-A53 + an STM32 *microcontroller* (real-time coprocessor)]),
      ([extra], [Adreno GPU]),
      ([RAM], [2 GB, 16 GB eMMC]),
      ([for], [Linux + real-time pins]),
    ), color: rgb("008184"))),
  )

  #v(0.3em)
  #only(1)[💡 the Pi: a general-purpose computer, the reference for SoC boards]
  #only("2-")[💡 the UNO Q: two processors on one board: Linux runs the programs, the microcontroller drives the pins on time]
]

