// the helpers of the network decks are shared with 05 - Network Infrastructure
#import "/src/05_network/common.typ": *

// a client and a server talking, on layers: the packet goes down the client
// stack (each layer adds its header), on the wire, and up the server stack
// (each layer removes its header). `rows` are (layer, protocol, detail) for
// each side; `q` and `a` are the parts of the question and of the answer,
// made with `part`: `level` is the layer that adds the part (0 application,
// 1 transport, 2 network, 3 data link), `layer` its color.
// Steps: 1-4 down the client, 5 the wire, 6-9 up the server, 10 the answer,
// 11 (optional) the answer reaches the client program;
// `r-top`: the highest layer that gets the packet on the server
#let talk-steps = 10
#let layer-names = (application: [Application], transport: [Transport], network: [Network], link: [Data Link])
#let part(level, layer, w, name, detail) = (level: level, layer: layer, w: w, name: name, detail: detail)
// the usual parts of a UDP message: data, UDP, IP, frame
#let udp-parts(eth, ip, udp, data) = (
  part(0, "application", 44pt, [data], data),
  part(1, "transport", 40pt, [UDP], udp),
  part(2, "network", 46pt, [IP], ip),
  part(3, "link", 36pt, [frame], eth),
)
// one part of the packet, in the color of its layer
#let pkt-part(w, layer, name, detail) = {
  let c = layer-colors.at(layer)
  box(width: w, height: 24pt, fill: c.fill, stroke: 0.8pt + c.stroke, align(center + horizon, stack(
    spacing: 2pt,
    text(size: 6.5pt, weight: "bold", name),
    text(size: 5.5pt, detail),
  )))
}
// the packet with the parts added up to layer `top`: the outer headers first
#let pkt-layers(parts, top) = {
  let shown = parts.filter(p => p.level <= top).sorted(key: p => -p.level)
  let boxes = shown.map(p => pkt-part(p.w, p.layer, p.name, p.detail))
  if top >= 3 { boxes.push(pkt-part(18pt, "link", [CRC], [✓])) }
  // rounded at the ends, like the frames of the other slides
  box(radius: 6pt, clip: true, stroke: 0.8pt + luma(120), stack(dir: ltr, ..boxes))
}
#let proto-talk(l-title, r-title, l-rows, r-rows, q, a, step, r-top: 0) = drawing(width: 470pt, height: 160pt)[
  #let (xl, xr, w) = (0pt, 340pt, 130pt)
  #let y(i) = 16pt + i * 32pt
  #let bottom = y(3) + 28pt
  #let wire-y = bottom + 12pt
  // the layer of the packet on this step, on the client (1-4) or the server (6-9)
  #let row-l = if step <= 4 { step - 1 } else if step == 11 { 0 } else { none }
  #let row-r = if step >= 6 and step <= 9 and 9 - step >= r-top { 9 - step } else { none }
  #label(xl + w / 2, 4pt, text(size: 9pt, weight: "bold", l-title))
  #label(xr + w / 2, 4pt, text(size: 9pt, weight: "bold", r-title))
  #for (x, rows, row) in ((xl, l-rows, row-l), (xr, r-rows, row-r)) {
    for (i, (layer, name, sub)) in rows.enumerate() {
      let c = layer-colors.at(layer)
      at(x, y(i), box(width: w, height: 28pt, fill: c.fill, stroke: if i == row { 1.5pt + hl } else { 0.8pt + c.stroke }, align(center + horizon, stack(
        spacing: 2pt,
        text(size: 6pt, fill: luma(90), layer-names.at(layer)),
        text(size: 8pt, weight: "bold", name),
        text(size: 6.5pt, sub),
      ))))
    }
  }
  // the wire between the two computers
  #let wire-st = 1.5pt + luma(150)
  #wire((xl + w / 2, bottom), (xl + w / 2, wire-y), stroke: wire-st)
  #wire((xl + w / 2, wire-y), (xr + w / 2, wire-y), stroke: wire-st)
  #wire((xr + w / 2, wire-y), (xr + w / 2, bottom), stroke: wire-st)
  // the way of the packet, next to the stacks
  #let (al, ar) = (xl + w + 6pt, xr - 6pt)
  #let go(a, b, color) = draw-arrow(a, b, color: color, thickness: 2pt, head: 6pt)
  #if step >= 2 and step <= 4 { go((al, y(0) + 4pt), (al, y(step - 1) + 24pt), hl) }
  #if step == 5 { go((xl + w / 2 + 6pt, wire-y), (xr + w / 2 - 6pt, wire-y), hl) }
  #if step >= 7 and step <= 9 { go((ar, bottom - 4pt), (ar, y(calc.max(9 - step, r-top)) + 4pt), hl) }
  #if step == 10 {
    go((ar, y(r-top) + 4pt), (ar, bottom - 4pt), ok-color)
    go((xr + w / 2 - 6pt, wire-y), (xl + w / 2 + 6pt, wire-y), ok-color)
    go((al, bottom - 4pt), (al, y(0) + 4pt), ok-color)
  }
  #if step == 11 { go((al, bottom - 4pt), (al, y(0) + 4pt), ok-color) }
  // the packet, between the stacks, next to its layer (or on the wire)
  #let mid = (xl + w + xr) / 2
  #if row-l != none { pin(mid, y(row-l) + 14pt, pkt-layers(if step == 11 { a } else { q }, row-l)) }
  #if row-r != none { pin(mid, y(row-r) + 14pt, pkt-layers(q, row-r)) }
  #if step == 5 { pin(mid, wire-y - 16pt, pkt-layers(q, 3)) }
  #if step == 10 { pin(mid, wire-y - 16pt, pkt-layers(a, 3)) }
]

// one step of a conversation on layers, drawn by hand: where the packet is
// now (`pos`: ("l", row), ("r", row) or ("w",) for the wire) and where it came
// from (`prev`, for the arrow); `pkt` the parts, shown up to layer `top`;
// `skip-l` / `skip-r`: the layers that are not used, drawn faded and dashed
#let talk-frame(l-title, r-title, l-rows, r-rows, pos, prev: none, pkt: none, top: 0, color: hl, skip-l: (), skip-r: ()) = drawing(width: 470pt, height: 160pt)[
  #let (xl, xr, w) = (0pt, 340pt, 130pt)
  #let y(i) = 16pt + i * 32pt
  #let bottom = y(3) + 28pt
  #let wire-y = bottom + 12pt
  #label(xl + w / 2, 4pt, text(size: 9pt, weight: "bold", l-title))
  #label(xr + w / 2, 4pt, text(size: 9pt, weight: "bold", r-title))
  #for (side, x, rows, skip) in (("l", xl, l-rows, skip-l), ("r", xr, r-rows, skip-r)) {
    for (i, (layer, name, sub)) in rows.enumerate() {
      let c = layer-colors.at(layer)
      let off = i in skip
      let on = pos == (side, i)
      at(x, y(i), box(
        width: w,
        height: 28pt,
        fill: if off { luma(250) } else { c.fill },
        stroke: if on { 1.8pt + color } else if off { (paint: luma(180), thickness: 0.8pt, dash: "dashed") } else { 0.8pt + c.stroke },
        align(center + horizon, stack(
          spacing: 2pt,
          text(size: 6pt, fill: luma(if off { 160 } else { 90 }), layer-names.at(layer)),
          text(size: 8pt, weight: "bold", fill: if off { luma(150) } else { black }, name),
          text(size: 6.5pt, fill: if off { luma(150) } else { black }, sub),
        )),
      ))
    }
  }
  // the wire between the two computers
  #let wire-st = 1.5pt + luma(150)
  #wire((xl + w / 2, bottom), (xl + w / 2, wire-y), stroke: wire-st)
  #wire((xl + w / 2, wire-y), (xr + w / 2, wire-y), stroke: wire-st)
  #wire((xr + w / 2, wire-y), (xr + w / 2, bottom), stroke: wire-st)
  // the arrow from the last place to this one, next to the stack
  #let edge(side) = if side == "l" { xl + w + 6pt } else { xr - 6pt }
  #let go(a, b) = draw-arrow(a, b, color: color, thickness: 2pt, head: 6pt)
  #if prev != none {
    if pos.at(0) == "w" {
      let (a, b) = if prev.at(0) == "l" { (xl + w / 2 + 6pt, xr + w / 2 - 6pt) } else { (xr + w / 2 - 6pt, xl + w / 2 + 6pt) }
      go((a, wire-y), (b, wire-y))
    } else if prev.at(0) == "w" {
      go((edge(pos.at(0)), bottom - 2pt), (edge(pos.at(0)), y(pos.at(1)) + 6pt))
    } else {
      let (i, j) = (prev.at(1), pos.at(1))
      let x = edge(pos.at(0))
      if j > i { go((x, y(i) + 6pt), (x, y(j) + 22pt)) } else { go((x, y(i) + 22pt), (x, y(j) + 6pt)) }
      // the layers jumped over
      let dx = if pos.at(0) == "l" { 20pt } else { -20pt }
      for k in range(calc.min(i, j) + 1, calc.max(i, j)) {
        pin(x + dx, y(k) + 14pt, text(size: 7pt, weight: "bold", fill: color)[⏭ skipped])
      }
    }
  }
  // the packet, between the stacks, next to its layer (or on the wire)
  #let mid = (xl + w + xr) / 2
  #if pkt != none {
    if pos.at(0) == "w" { pin(mid, wire-y - 16pt, pkt-layers(pkt, top)) } else { pin(mid, y(pos.at(1)) + 14pt, pkt-layers(pkt, top)) }
  }
]

