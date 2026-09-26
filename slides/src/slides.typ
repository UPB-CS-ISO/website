#import "@preview/diatypst:0.9.3": *
#import "polylux.typ": *
#import "terminal.typ": *
#import "ai-prompt.typ": *

// Two-column layouts use polylux's own #toolbox.side-by-side(columns: (..),
// gutter: 1.5em)[left][right] directly at the call site instead of a local
// wrapper, e.g. #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[left][right]

#let uso_slides(content, title: none, date: none) = {
  if date == none {
    date = datetime.today().display()
  }

  show: slides.with(
    title: "Introduction to Operating Systems", // Required
    subtitle: title,
    date: date,
    authors: ("Alexandru Radovici, PhD", "Ioana Culic, PhD"),

    // Optional Styling (for more and explanation of options take a look at the typst universe)
    ratio: 16 / 9,
    layout: "medium",
    title-color: rgb("004d65"),
    toc: false,
    count: "dot-section",
    theme: "normal",
    footer-subtitle: "Copyright (C) 2026 Wyliodrin & Politehnica Bucharest, CC-BY-40",
  )

  // use numbering only up to section level 2, required for dot-section
  set heading(numbering: (..num) => if num.pos().len() == 2 {
    num.pos().map(str).join(".")
  } else { "" })

  // render fenced ```terminal``` blocks as a shell session (see above)
  show raw.where(lang: "terminal"): render-terminal

  content
}
