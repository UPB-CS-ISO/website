#import "/src/slides.typ": *
#import "/src/08_hardware_components/common.typ": *

// Cut from lecture 09 (Memory and Storage), kept for later.
// TRIM: why an SSD needs to know which blocks are free.

// TRIM: the same 8 blocks seen by the file system (top) and by the SSD
// (bottom). States: "used" (other files), "file" (notes.txt, orange),
// "free" (white, dashed), "stale" (deleted, but the SSD does not know: gray
// with a "?"). `step`: 1 notes.txt uses blocks 2-4, 2 `rm notes.txt`: free
// for the file system only, 3 the SSD copies the deleted data to make room,
// 4 TRIM: the SSD learns the blocks are free
#let trim-block(state) = box(
  width: 20pt,
  height: 20pt,
  radius: 2pt,
  fill: if state == "used" { accent.lighten(55%) } else if state == "file" { changed } else if state == "stale" {
    luma(200)
  } else { white },
  stroke: if state == "free" { (paint: luma(160), thickness: 0.7pt, dash: "dashed") } else { none },
  align(center + horizon, if state == "stale" { text(weight: "bold", fill: luma(90))[?] }),
)

#let trim-row(x, y, states) = for (i, st) in states.enumerate() { at(x + i * 23pt, y, trim-block(st)) }

#let trim-drawing(step) = drawing(width: 280pt, height: 112pt, {
  set text(size: 0.75em)
  let fs = if step == 1 { "file" } else { "free" }
  let ssd = if step == 1 { "file" } else if step <= 3 { "stale" } else { "free" }
  let row(mid) = ("used", "used", mid, mid, mid, "free", "free", "used")
  at(0pt, 0pt, text(weight: "bold")[🗂️ file system])
  trim-row(0pt, 14pt, row(fs))
  trim-row(0pt, 74pt, row(ssd))
  at(0pt, 98pt, text(weight: "bold")[💾 SSD])
  // the file system row: what the user did
  at(192pt, 18pt, if step == 1 [📄 `notes.txt`] else { text(fill: changed.darken(15%))[`rm notes.txt`] })
  // the SSD row
  if step == 2 { at(192pt, 78pt, [❓ still data?]) }
  if step == 3 {
    line-arrow((186pt, 84pt), (206pt, 84pt), color: changed, thickness: 1.5pt)
    trim-row(209pt, 74pt, ("stale", "stale", "stale"))
    at(196pt, 98pt, text(fill: changed.darken(15%), weight: "bold")[copied for nothing ❌])
  }
  if step >= 4 {
    line-arrow((80pt, 37pt), (80pt, 71pt), color: changed, thickness: 1.5pt)
    at(88pt, 46pt, text(fill: changed.darken(15%), weight: "bold")[TRIM: blocks 2-4 are free])
    at(192pt, 78pt, [✅ erased, ready])
  }
})

#slide[
  == ✂️ TRIM
  Telling the SSD which blocks are free

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    - flash cannot overwrite: a block is *erased* first
    #uncover("2-")[#block[- `rm` only marks the blocks free in the _file system_; the SSD is not told]]
    #uncover("3-")[#block[- to make room, the SSD moves the data it thinks is useful: the deleted file too ❌ #linebreak() extra writes: slower, wears the cells]]
    #uncover("4-")[#block[- *TRIM*: the OS tells the SSD which blocks are free ✅ nothing to copy]]
  ][
    #only(1, trim-drawing(1))
    #only(2, trim-drawing(2))
    #only(3, trim-drawing(3))
    #only("4-", trim-drawing(4))
  ]

  #v(0.4em)
  #only(1)[💡 the file `notes.txt` uses blocks 2, 3 and 4]
  #only(2)[💡 `rm` is fast because it only changes the table of the file system]
  #only(3)[💡 the SSD erases in large pieces: first it copies away what it believes is still useful]
  #only("4-")[💡 Linux sends TRIM once a week (`fstrim.timer`); `lsblk --discard` shows if a disk supports it]
]

