// A visually distinctive block for AI prompts that students can copy and
// paste into an AI assistant. Deliberately not styled like diatypst's own
// #quote(block: true) (teal left-bar, plain text) or the ```terminal blocks
// (grey code background) - a different accent color plus a labeled,
// icon-marked header make it read as its own category of content at a
// glance, rather than blending in with either.
#let ai-prompt-color = rgb("6d28d9")
#let ai-prompt-bg = rgb("f6f1ff")

// Shared header + body content for both variants below.
#let ai-prompt-content(title, body) = [
  #text(fill: ai-prompt-color, weight: "bold", size: 0.75em, tracking: 0.1em)[🤖 #upper(title)]
  #v(0.45em)
  #text(font: "DejaVu Sans Mono", size: 0.95em)[#body]
]

// #ai-prompt[Write a bash script that ...] - mirrors #quote(block: true)'s
// bracket-body call syntax, sitting inline in the normal flow (pushes
// following content down). `title` overrides the small header label, e.g.
// #ai-prompt(title: "Prompt idea")[...]
#let ai-prompt(title: "AI Prompt", body) = {
  v(4pt, weak: true)
  block(
    width: 100%,
    fill: ai-prompt-bg,
    inset: (x: 1.1em, y: 0.85em),
    radius: 0.6em,
    stroke: (left: 3pt + ai-prompt-color),
  )[#ai-prompt-content(title, body)]
  v(4pt, weak: true)
}

// Same distinctive look as #ai-prompt, but placed *on top* of whatever is
// already on the slide instead of taking its own spot in the normal flow -
// e.g. to have an AI-prompt suggestion "pop up" over content that's already
// shown, typically timed with polylux's #only()/#uncover(). Typst paints in
// document order, so put this call *last* in the #slide[...] body: it then
// draws over everything written above it, wherever the two overlap.
// `at` is a Typst alignment (default: dead center of the slide); `width`
// is relative to the slide, e.g. `width: 45%` for a smaller corner card.
// #ai-prompt-overlay[Explain ... in one sentence.]
// #only(2)[#ai-prompt-overlay(at: bottom + right, width: 45%)[...]]
#let ai-prompt-overlay(title: "AI Prompt", at: center + horizon, width: 65%, body) = {
  place(
    at,
    block(
      width: width,
      fill: ai-prompt-bg,
      inset: (x: 1.1em, y: 0.85em),
      radius: 0.6em,
      stroke: 1.5pt + ai-prompt-color,
    )[#ai-prompt-content(title, body)],
  )
}
