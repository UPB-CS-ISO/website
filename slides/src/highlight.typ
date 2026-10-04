#import "polylux.typ": only

// Step-by-step line *highlighting* for a fenced code block: every step
// shows the whole block, but only the listed lines keep their normal look,
// the rest are grayed out. Unlike polylux's #reveal-code nothing is hidden,
// which is what we want when walking through an existing listing
// (a directory tree, a man page, ...).
//
// `steps` is an array with one entry per subslide; each entry is either
// "all" (nothing grayed out) or an array of 1-based line numbers.
// #highlight-code(("all", (1,), (2, 3), "all"))[```rust ...```]
// `offset` is added to the block's own line numbers before matching them
// against `steps`, so one listing can be split over several blocks (e.g.
// two columns) while `steps` keeps using the line numbers of the whole
// listing.
#let highlight-code(start: 1, offset: 0, dim: luma(175), steps, body) = {
  for (idx, s) in steps.enumerate() {
    only(start + idx)[
      #show raw.line: it => if s == "all" or (it.number + offset) in s {
        it.body
      } else {
        text(fill: dim, it.text)
      }
      #body
    ]
  }
}

// line numbers from..to (inclusive), for use inside `steps`
#let lines-range(from, to) = range(from, to + 1)
