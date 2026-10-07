#import "common.typ": *

#section-cover([Link Layer], [connecting computers that are close together], layers: ("link", "physical"), note: [Ethernet, Wi-Fi])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.9 - _Understanding Kernel Network Interfaces_
  + #tanenbaum
    - Chapter 3 - _The Data Link Layer_
  + #uso-book
    - Section 8.4.3 - _Placa de rețea_
]

#slide[
  == Network Card
  _Network Interface Controller_ (NIC)

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    - the hardware that connects a computer to a network
      - *Ethernet*: a cable with an RJ-45 plug
      - *Wi-Fi*: radio waves
      - *4G / 5G*: the mobile network
    - built into the motherboard, a PCIe or a USB card
    - sends and receives *frames*: blocks of bytes
    - has a unique hardware address: the *MAC address*
  ][
    #align(center, grid(
      columns: 2,
      column-gutter: 1em,
      row-gutter: 0.5em,
      align: center,
      pic("eth-card", size: 45pt), pic("wifi-card", size: 45pt),
      text(size: 9pt)[*Ethernet* card], text(size: 9pt)[*Wi-Fi* card],
      grid.cell(colspan: 2, pic("modem", size: 45pt)),
      grid.cell(colspan: 2, text(size: 9pt)[*4G / 5G* modem]),
    ))
  ]
]

#slide[
  == MAC Address
  _Media Access Control_ address

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - *48 bits* (6 bytes), written in hexadecimal
    - set by the manufacturer of the card
      - can be changed by software
      - phones use a random MAC address for each Wi-Fi network (privacy)
    - `ff:ff:ff:ff:ff:ff` - *broadcast*, for everyone in the network
    - only makes sense *in the local network*
  ][
    #drawing(width: 220pt, height: 118pt)[
      // two halves: who made the card, and which card it is
      #let maker = (fill: rgb("e3f0f5"), stroke: accent)
      #let card = (fill: hl-bg, stroke: hl)
      #let bw = 28pt
      #let gap = 8pt
      #let bx(i) = 5pt + i * (bw + gap)
      #let y = 26pt
      // the bit counts above the halves
      #label((bx(0) + bx(2) + bw) / 2, 10pt, text(size: 7.5pt, fill: accent)[24 bits])
      #label((bx(3) + bx(5) + bw) / 2, 10pt, text(size: 7.5pt, fill: hl)[24 bits])
      #for (i, b) in ("3c", "a9", "f4", "5e", "21", "7b").enumerate() {
        let c = if i < 3 { maker } else { card }
        at(bx(i), y, box(
          width: bw,
          height: 28pt,
          radius: 4pt,
          fill: c.fill,
          stroke: 1pt + c.stroke,
          align(center + horizon, text(font: "DejaVu Sans Mono", size: 11pt, weight: "bold", b)),
        ))
        if i < 5 { label(bx(i) + bw + gap / 2, y + 14pt, text(size: 12pt, weight: "bold", fill: luma(110))[:]) }
      }
      // brackets under the halves
      #let under(x1, x2, color, body) = {
        let yb = y + 36pt
        wire((x1, yb - 4pt), (x1, yb), stroke: 1.2pt + color)
        wire((x1, yb), (x2, yb), stroke: 1.2pt + color)
        wire((x2, yb - 4pt), (x2, yb), stroke: 1.2pt + color)
        wire(((x1 + x2) / 2, yb), ((x1 + x2) / 2, yb + 4pt), stroke: 1.2pt + color)
        pin((x1 + x2) / 2, yb + 20pt, box(width: x2 - x1 + 10pt, align(center, text(size: 8pt, body))))
      }
      #under(bx(0), bx(2) + bw, accent)[*manufacturer* \ (OUI, from the IEEE)]
      #under(bx(3), bx(5) + bw, hl)[*card number* \ (chosen by the maker)]
    ]
    ```terminal
    $ cat /sys/class/net/wlp2s0/address
    3c:a9:f4:5e:21:7b
    ```
  ]
]

// ---------------------------------------------------------------------------
// More computers
// ---------------------------------------------------------------------------

// the output of `ip -br link`, cut in named parts, so each part can be
// highlighted on its own: (part, text); parts named `none` are spaces and
// punctuation
#let ip-link-cmd = "$ ip -br link    # -br means brief - show one line for each network card"
#let flags(..names) = {
  let out = ((none, "<"),)
  for (i, n) in names.pos().enumerate() {
    if i > 0 { out.push((none, ",")) }
    out.push(("f-" + lower(n), n))
  }
  out.push((none, ">"))
  out
}
#let ip-link-out = (
  (
    ("lo-name", "lo"), (none, "               "), ("state", "UNKNOWN"), (none, "        "),
    ("lo-mac", "00:00:00:00:00:00"), (none, " "), ..flags("LOOPBACK", "UP", "LOWER_UP"),
  ),
  (
    ("en", "en"), ("en-where", "p0s31f6"), (none, "        "), ("state", "DOWN"), (none, "           "),
    ("mac", "8c:16:45:a2:3b:91"), (none, " "), ..flags("NO-CARRIER", "BROADCAST", "MULTICAST", "UP"),
  ),
  (
    ("wl", "wl"), ("wl-where", "p2s0"), (none, "           "), ("state", "UP"), (none, "             "),
    ("mac", "3c:a9:f4:5e:21:7b"), (none, " "), ..flags("BROADCAST", "MULTICAST", "UP", "LOWER_UP"),
  ),
  (
    ("ww", "ww"), ("ww-where", "p0s20f0u3i12"), (none, "   "), ("state", "UP"), (none, "             "),
    ("ww-mac", "b6:3e:12:8a:04:d1"), (none, " "), ..flags("BROADCAST", "MULTICAST", "NOARP", "UP", "LOWER_UP"),
  ),
)
// the parts that are highlighted together
#let ip-link-groups = (
  name: ("lo-name", "en", "en-where", "wl", "wl-where", "ww", "ww-where"),
  kind: ("lo-name", "en", "wl", "ww"),
  where: ("en-where", "wl-where", "ww-where"),
  state: ("state",),
  mac: ("lo-mac", "mac", "ww-mac"),
  flags-state: ("f-up", "f-lower_up", "f-no-carrier"),
  flags-kind: ("f-loopback", "f-broadcast", "f-multicast", "f-noarp"),
)

#let ip-link-terminal(hl: ()) = {
  let text-of(line) = line.map(((k, t)) => t).join()
  let src = (ip-link-cmd, ..ip-link-out.map(text-of)).join("\n")
  show raw.line: it => {
    if it.number == 1 { return render-terminal-line(it.text) }
    // the same gray as the output of the other terminals (terminal.typ)
    text(fill: luma(100), for (k, t) in ip-link-out.at(it.number - 2) {
      let c = hl.find(((parts, colors)) => k != none and k in parts)
      if c != none { highlight(fill: c.at(1).hl, extent: 1pt, radius: 2pt, t) } else { t }
    })
  }
  // a bit smaller than the other terminals, so the modem line fits
  text(size: 0.92em, raw(src, block: true))
}

#slide[
  == Network Interfaces
  // the same footnote number on every step of the slide
  #counter(footnote).update(0)
  how Linux sees the network cards#footnote[the `wwp0s20f0u3i12` line shows a typical 4G modem, a real one may show different values]

  // an explanation: a title and a list of (term, meaning)
  #let steps = (
    (none, none),
    ("name", explain[*name*: what Linux calls the network card]),
    ("kind", explain(
      [the name starts with the *kind* of card],
      ([`lo`], [_loopback_: virtual, the computer talks to itself]),
      ([`en`...], [*Ethernet*]),
      ([`wl`...], [*Wi-Fi* (wireless LAN)]),
      ([`ww`...], [*4G / 5G* modem (wireless WAN)]),
    )),
    ("where", explain(
      [then *where* the card is plugged in],
      ([`p0s31f6`], [PCI bus 0, slot 31, function 6]),
      ([`p2s0`], [PCI bus 2, slot 0: the card has a single function, so there is no `f`]),
      ([`p0s20f0u3i12`], [USB: the USB controller (PCI `p0s20f0`), port 3 (`u3`), interface 12 of the modem (`i12`)]),
    )),
    ("state", explain(
      [*state*: can the card send data now?],
      ([`UP`], [yes]),
      ([`DOWN`], [no: `enp0s31f6` is turned on, but it has no cable]),
      ([`UNKNOWN`], [the driver does not say (`lo`)]),
    )),
    ("mac", explain(
      [*MAC address* of the card],
      ([`00:00:...`], [`lo` is virtual, it has no MAC address]),
      ([`b6:3e:...`], [the modem makes one up: the mobile network does not use MAC addresses]),
    )),
    ("flags-state", explain(
      [*flags*, part 1: the *state* of the card],
      ([`UP`], [turned on (`ip link set dev ... up`)]),
      ([`LOWER_UP`], [the cable or the radio is connected]),
      ([`NO-CARRIER`], [no signal: no cable plugged in]),
    )),
    ("flags-kind", explain(
      colors: ip-blue,
      [*flags*, part 2: what the card *can do*],
      ([`BROADCAST`], [can send data to everyone in the network]),
      ([`MULTICAST`], [can send data to a group of devices]),
      ([`LOOPBACK`], [it is the loopback card]),
      ([`NOARP`], [does not look up MAC addresses (ARP): the modem talks only to the mobile network]),
    )),
  )

  #for (i, (group, body)) in steps.enumerate() {
    // on the last step both kinds of flags are shown, each in its own color
    let hl = if group == none { () } else if group == "flags-kind" {
      ((ip-link-groups.flags-kind, ip-blue), (ip-link-groups.flags-state, ip-peach))
    } else { ((ip-link-groups.at(group), ip-peach),) }
    only(i + 1)[
      #ip-link-terminal(hl: hl)
      #if body != none { body }
    ]
  }
]
