#import "common.typ": *

#section-cover([Troubleshooting], [the Internet does not work: what now?], layers: ("application", "transport", "network", "link", "physical"), note: [from the \ bottom up])

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 9 - _Understanding Your Network and Its Configuration_
      - Section 9.7 - _Basic ICMP and DNS Tools_
      - Section 9.14 - _Resolving Hostnames_
  + #uso-book
    - Section 11.5 - _Configurări de rețea_
]

// the checks, from the bottom up: (short name, layer (its color), question,
// command, fix when it fails, the layers as words, the fix is taught in the
// next lecture); deck 10 uses the first two fields and `check-table`
#let checks = (
  ([card], "link", [is the card *connected*?], "ip -br link", [plug in the cable, turn the Wi-Fi on], [physical, data link], false),
  ([address], "network", [do I have an *IP address*?], "ip -br address", [DHCP failed: connect again], [network], false),
  ([gateway], "network", [do I have a *gateway*?], "ip route", [add the default gateway], [network], true),
  ([Internet], "network", [does the *Internet* answer?], "ping 8.8.8.8", [the router or the provider], [network], false),
  ([DNS], "application", [do *names* work?], "host upb.ro", [set a DNS server], [application (DNS)], true),
  ([server], "transport", [does the *server* answer?], "curl -I https://upb.ro", [the server, not my network], [transport, application], false),
)

// the checks as a table: the number in the color of its layer, the question
// with its layers in words, the command and what to do when the answer is no;
// `shown` rows are visible; `later`: mark the fixes taught in the next lecture
#let check-table(shown, later: false) = text(size: 10pt, table(
  columns: (22pt, 1fr, auto, auto),
  inset: (x: 6pt, y: 3pt),
  align: (center + horizon, left + horizon, left + horizon, left + horizon),
  stroke: (x, y) => if y == 0 { (bottom: 1pt + luma(150)) } else { (bottom: 0.5pt + luma(215)) },
  table.header([], text(fill: luma(90))[*question* (layer)], text(fill: luma(90))[*command*], text(fill: bad-color)[*if not* 🔧]),
  ..checks.enumerate().map(((i, (name, layer, question, cmd, fix, words, next))) => {
    let c = layer-colors.at(layer)
    let cells = (
      box(width: 18pt, height: 18pt, radius: 50%, fill: c.fill, stroke: 1pt + c.stroke, align(center + horizon, text(
        size: 9pt,
        weight: "bold",
        str(i + 1),
      ))),
      [#question #h(0.3em) #text(size: 8pt, fill: luma(100))[(#words)]],
      box(fill: luma(240), radius: 2pt, inset: (x: 3pt, y: 2pt), outset: (y: 1pt), text(
        font: "DejaVu Sans Mono",
        size: 9pt,
        highlight-shell(cmd),
      )),
      text(size: 9.5pt)[#fix#if later and next [ 📅]],
    )
    if i < shown { cells } else { cells.map(x => hide(x)) }
  }).flatten(),
))

#slide[
  == No Internet?
  check from the *bottom up*; DNS before the server: the name must be found first

  #for k in range(1, checks.len() + 1) { only(k, check-table(k, later: true)) }
  #only(str(checks.len() + 1) + "-", check-table(checks.len(), later: true))
  #uncover("3-", text(size: 9pt, fill: luma(90))[📅 how to do it by hand: next lecture])
  #only(str(checks.len() + 1) + "-", place(bottom + left, block(width: 100%, text(size: 10pt, note-box[💡 "Wi-Fi connected, but no Internet": check DNS early, `ping 8.8.8.8` works but names do not]))))
]
