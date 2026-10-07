// "How Computers Talk": two computers and two routers, the way of the data
// through the layers and the peer layers. Put on hold from lecture 05
// (05_network/internet.typ); include it with #include "/extra/how-computers-talk.typ"
#import "/src/05_network/common.typ": *

// the stacks of two computers and two routers between them
#let talk-hosts = (0pt, 402pt)
#let talk-routers = (148pt, 266pt)
#let talk-y0 = 34pt
#let talk-row = 26pt
#let talk-cy(i) = talk-y0 + talk-row * (i + 0.5)

#slide[
  == How Computers Talk

  #drawing(height: 178pt)[
    #let host-layers = (
      ("Application", "application", none),
      ("Transport", "transport", none),
      ("Network", "network", none),
      ("Data Link", "link", none),
      ("Physical", "physical", none),
    )
    // cables between the physical layers
    #for (a, b) in ((78pt, 148pt), (214pt, 266pt), (332pt, 402pt)) {
      wire((a, talk-cy(4)), (b, talk-cy(4)), stroke: 2.5pt + luma(90))
    }
    #for x in talk-hosts { layer-stack(x, host-layers, w: 78pt, y0: talk-y0, h: 5 * talk-row, size: 7.5pt) }
    #for x in talk-routers {
      layer-stack(x, host-layers.slice(2), w: 66pt, y0: talk-y0 + 2 * talk-row, h: 3 * talk-row, size: 7.5pt)
      pin(x + 33pt, talk-y0 + 5 * talk-row + 10pt, text(size: 8pt)[#icon("🚦", size: 11pt) *router*])
    }
    #pin(39pt, 14pt, text(size: 8.5pt)[#icon("💻", size: 13pt) *my PC*])
    #pin(441pt, 14pt, text(size: 8.5pt)[#icon("🏬", size: 13pt) *shop* (web server)])

    // step 2: the way of the data
    #only("2")[
      #let s = 1.8pt + hl
      #place(top + left, curve(
        stroke: (paint: hl, thickness: 1.8pt, join: "round"),
        curve.move((70pt, talk-cy(0))),
        curve.line((70pt, talk-cy(4))),
        curve.line((154pt, talk-cy(4))),
        curve.line((154pt, talk-cy(2) + 8pt)),
        curve.line((208pt, talk-cy(2) + 8pt)),
        curve.line((208pt, talk-cy(4))),
        curve.line((272pt, talk-cy(4))),
        curve.line((272pt, talk-cy(2) + 8pt)),
        curve.line((326pt, talk-cy(2) + 8pt)),
        curve.line((326pt, talk-cy(4))),
        curve.line((410pt, talk-cy(4))),
      ))
      #draw-arrow((410pt, talk-cy(4)), (410pt, talk-cy(0)), color: hl, thickness: 1.8pt)
    ]

    // step 3: each layer talks to the same layer on the other side
    #only("3")[
      #let peer(x1, x2, i, body) = {
        draw-arrow((x1, talk-cy(i)), (x2, talk-cy(i)), color: accent, thickness: 1pt, dash: "dashed")
        draw-arrow((x2, talk-cy(i)), (x1, talk-cy(i)), color: accent, thickness: 1pt, dash: "dashed")
        if body != none { tag((x1 + x2) / 2, talk-cy(i), body, size: 7pt) }
      }
      #peer(80pt, 400pt, 0, [HTTP: 🛒 the order])
      #peer(80pt, 400pt, 1, [TCP: 🚚 the van])
      #for (a, b) in ((80pt, 146pt), (216pt, 264pt), (334pt, 400pt)) {
        peer(a, b, 2, none)
        peer(a, b, 3, none)
      }
    ]
  ]

  #place(bottom + left, block(width: 100%, text(size: 10.5pt)[
    #only(1)[- computers have *all* the layers, routers only need the lower 3]
    #only(2)[- the data goes *down* my stack, *up* to the Network layer of each router, *up* the server's stack]
    #only(3)[- each layer talks to *the same layer* on the other side: a junction only reads the address]
  ]))
]
