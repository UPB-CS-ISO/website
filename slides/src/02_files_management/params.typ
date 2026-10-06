#import "/src/slides.typ": *

// Colors that tie a parameter in the SYNOPSIS to the value given to it
#let param-colors = (
  source: rgb("e65100"),
  dest: rgb("6a1b9a"),
  option: rgb("00838f"),
  // a path parameter (a file or a directory), the same color as a source
  path: rgb("e65100"),
  // a filter of `find`
  filter: rgb("2e7d32"),
)
#let param-mark(color, body) = highlight(
  fill: color.lighten(82%),
  radius: 2pt,
  extent: 1pt,
  text(fill: color, weight: "bold", body),
)

// `body` with every (substring, color) of `marks` highlighted, in order;
// the text between the marks is drawn with `plain(text, is-first)`
#let param-marked(body, marks, plain) = {
  let out = ()
  let rest = body
  for (sub, color) in marks {
    let at = rest.position(sub)
    assert(at != none, message: "`" + sub + "` not found in `" + body + "`")
    out.push(plain(rest.slice(0, at), out.len() == 0))
    out.push(param-mark(color, sub))
    rest = rest.slice(at + sub.len())
  }
  out.push(plain(rest, out.len() == 0))
  out.join()
}

// A terminal block, drawn like a ```terminal``` one, where the parameters of
// some commands are highlighted with the colors of their SYNOPSIS parameters.
// `marks`: line number (as a string) -> array of (substring, color), searched
//   in the command, after the `$ ` prompt
// `shown`: only the first `shown` lines are visible (none: all of them)
#let marked-terminal(content, marks: (:), shown: none) = {
  show raw.line: line => {
    let m = marks.at(str(line.number), default: none)
    if shown != none and line.number > shown {
      hide(line.text)
    } else if m != none and line.text.starts-with("$ ") {
      [#text(fill: rgb("004d65"), weight: "bold")[\$]#h(0.5em)]
      param-marked(line.text.slice(2), m, (t, first) => highlight-shell(t, start-expect-command: first))
    } else {
      render-terminal-line(line.text)
    }
  }
  raw(content, block: true)
}

// One subslide per step: `steps` is an array of dictionaries
//   (shown: number of visible lines or none, marks: (line -> marks),
//    synopsis: marks for the synopsis line)
// the synopsis (a one-line command) is drawn above the commands with the parts
// used by the current step highlighted. The last step stays on the following
// subslides.
#let synopsis-step(steps, i, body) = {
  let frames = if i == steps.len() - 1 { (beginning: i + 1) } else { i + 1 }
  only(frames, body)
}
