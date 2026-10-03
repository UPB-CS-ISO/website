// Everything needed to render ```terminal fenced blocks as a shell session:
// a hand-rolled shell syntax highlighter plus the `terminal`/`render-terminal`/
// `reveal-terminal` entry points. Split out of slides.typ so the terminal
// rendering logic can be read/edited on its own.
#import "polylux.typ": only

// We can't use Typst's built-in raw(lang: "bash") engine for the command
// portion of a terminal line, because emitting another `raw(...)` element
// re-triggers diatypst's own show raw.where(...) rules (that's what caused
// the earlier background/rounding mismatches), so instead this tokenizes
// the string by hand and colors each token with plain text() spans, never
// raw().
#let shell-command-color = rgb("004d65")
#let shell-flag-color = rgb("9a4d76")
#let shell-string-color = rgb("2e7d46")
#let shell-var-color = rgb("b35900")
#let shell-op-color = rgb("555555")
#let shell-comment-color = luma(130)

// Order matters: more specific alternatives (quoted strings, assignments,
// $variables) must come before the generic word fallback so it doesn't
// swallow them. The fallback excludes "$" so a $VAR embedded mid-token
// (e.g. the second half of "bin:$PATH") still gets tokenized on its own.
#let shell-token-pattern = regex("\"[^\"]*\"|'[^']*'|\\$\\{[^}]*\\}|\\$[A-Za-z_][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_]*=\"[^\"]*\"|[A-Za-z_][A-Za-z0-9_]*='[^']*'|[A-Za-z_][A-Za-z0-9_]*=[^ \t$]*|\\|\\||&&|[|;&<>]+|#.*|--?[A-Za-z0-9][A-Za-z0-9._=-]*|[ \t]+|\\$|[^ \t$]+")

// Tokens that chain another command onto the line: after one of these, the
// next word is a new command name (and gets the bold "command" color)
// rather than a plain argument.
#let shell-command-separators = ("&&", "||", ";", "|", "&")
// Redirections don't start a new command, so they don't reset that state.
#let shell-redirections = (">>", ">", "<<", "<")

// Matches a leading environment-variable assignment/attribution, e.g. the
// `FOO=` in `FOO=bar ./run.sh` or `export FOO=bar`.
#let shell-assignment-pattern = regex("^[A-Za-z_][A-Za-z0-9_]*=")

// `start-expect-command: false` is for a `\`-continuation line: it's still
// arguments to the command from the previous physical line, not a new one,
// so the first token on it shouldn't get bolded as a command name.
#let highlight-shell(cmd, start-expect-command: true) = {
  let tokens = cmd.matches(shell-token-pattern)
  // true while we're still waiting for the next "real" command name -
  // true at the start of the line (unless continuing one) and reset after
  // &&, ||, ;, | or &.
  let expect-command = start-expect-command
  let in-comment = false
  let out = ()
  for m in tokens {
    let t = m.text
    if in-comment {
      out.push(text(fill: shell-comment-color, style: "italic", t))
    } else if t.trim() == "" {
      out.push(text(t))
    } else if t.starts-with("#") {
      in-comment = true
      out.push(text(fill: shell-comment-color, style: "italic", t))
    } else if t == "\\" {
      // trailing line-continuation marker
      out.push(text(fill: shell-op-color, weight: "bold", t))
    } else if t in shell-command-separators {
      out.push(text(fill: shell-op-color, weight: "bold", t))
      expect-command = true
    } else if t in shell-redirections {
      out.push(text(fill: shell-op-color, weight: "bold", t))
    } else if t.match(shell-assignment-pattern) != none {
      // Env var attribution: color the name, leave the value on its own
      // (quoted values still get the string color).
      let eq = t.match(regex("=")).start
      let name = t.slice(0, eq)
      let value = t.slice(eq + 1)
      out.push(text(fill: shell-var-color, weight: "bold", name))
      out.push(text("="))
      if value.starts-with("\"") or value.starts-with("'") {
        out.push(text(fill: shell-string-color, value))
      } else {
        out.push(text(value))
      }
    } else if expect-command {
      out.push(text(fill: shell-command-color, weight: "bold", t))
      expect-command = false
    } else if t.starts-with("\"") or t.starts-with("'") {
      out.push(text(fill: shell-string-color, t))
    } else if t.starts-with("$") {
      out.push(text(fill: shell-var-color, t))
    } else if t.starts-with("-") {
      out.push(text(fill: shell-flag-color, t))
    } else if t.contains(regex("^[|;&<>]+$")) {
      out.push(text(fill: shell-op-color, weight: "bold", t))
    } else {
      out.push(text(t))
    }
  }
  out.join()
}

// Shared per-line rendering for a "fully visible" terminal line: a line
// starting with "$ " gets a bold, theme-colored prompt and its command
// syntax-highlighted; a `\`-continuation of the previous line is
// highlighted the same way but without a prompt (it's still command
// input, not output); any other line is shown as plain (dimmed) output.
// Used by both render-terminal (below) and reveal-terminal's "current"
// window, so the two stay visually identical.
#let render-terminal-line(t, is-continuation: false) = if t.starts-with("$ ") [
  #text(fill: rgb("004d65"), weight: "bold")[\$]#h(0.5em)#highlight-shell(t.slice(2))
] else if is-continuation [
  #highlight-shell(t, start-expect-command: false)
] else [
  #text(fill: luma(100))[#t]
]

// A line continues onto the next physical line when it ends with a
// backslash, e.g.
// $ docker run --rm -it \
//     -v $(pwd):/app \
//     image:tag
// A trailing `#comment` after the backslash is allowed and ignored for
// this check (it's common to annotate the continuation itself, e.g.
// `cmd \ # explain the backslash`), so we tokenize the line the same way
// highlight-shell does and look at the last non-whitespace, non-comment
// token rather than just the raw trailing characters.
#let shell-continues(line-text) = {
  let tokens = line-text.matches(shell-token-pattern)
  let i = tokens.len() - 1
  while i >= 0 and (tokens.at(i).text.trim() == "" or tokens.at(i).text.starts-with("#")) {
    i -= 1
  }
  i >= 0 and tokens.at(i).text == "\\"
}

// Fenced ```terminal``` blocks are rendered as a shell session using the
// exact same background and style diatypst gives a normal fenced code
// block: the original raw block is returned with a custom per-line show
// rule laid on top. It must not emit a new raw(...) inside this show rule:
// the default `raw` text size (0.8em) would then apply twice (0.64em) and
// fenced blocks would be smaller than #reveal-terminal blocks.
#let render-terminal(it) = {
  let src-lines = it.text.split("\n")
  show raw.line: line => {
    let is-cont = line.number > 1 and shell-continues(src-lines.at(line.number - 2))
    render-terminal-line(line.text, is-continuation: is-cont)
  }
  it
}

// Convenience for calling it as a function instead of a fenced block, e.g.
// #terminal("$ ls -la\ndrwxr-xr-x ...")
#let terminal(content) = raw(content, lang: "terminal", block: true)

// polylux's own #reveal-code doesn't work on ```terminal blocks: it sets
// its own `show raw.line` rule to gray-out/hide lines per subslide, but
// render-terminal's `show raw.line` rule (registered more locally, when
// the lang:"terminal" show rule fires) always wins over it, so reveal-code
// never gets a chance to hide/gray anything - every subslide just shows
// the whole block, fully highlighted, unchanged (verified empirically).
//
// This reimplements reveal-code's before/current/after windowing logic
// directly against our own single raw(..., block: true) call, so the two
// concerns (progressive reveal, and prompt/command highlighting) compose
// instead of fighting over the same show rule. Same call syntax as
// #reveal-code: named args, then either a ```terminal fenced body...
// #reveal-terminal(lines: (1, 2))[```terminal
// $ ls -la
// $ cd /tmp && echo done
// ```]
// ...or a plain string like #terminal() takes, for when building the
// command text programmatically is more convenient than a literal fence:
// #reveal-terminal("$ ls -la\n$ cd /tmp && echo done", lines: (1, 2))
#let reveal-terminal(
  start: 1,
  lines: (),
  before: gray,
  after: hide,
  full: true,
  body,
) = {
  let content = if type(body) == str {
    body
  } else if type(body) == content and body.func() == raw {
    body.text
  } else {
    panic("reveal-terminal expects a plain string or a ```terminal fenced code block")
  }

  let src-lines = content.split("\n")
  let is-cont-at(n) = n > 1 and shell-continues(src-lines.at(n - 2))
  let windows = (0,) + lines
  // `before`/`after` accept a color (flatten the line to it), `hide`, or
  // `none` to keep the line exactly as normal (full "$ " prompt/command
  // syntax highlighting) - e.g. `before: none` to leave already-revealed
  // lines looking untouched instead of graying them out.
  let (before-action, after-action) = (before, after).map(c => {
    if c == none {
      line => render-terminal-line(line.text, is-continuation: is-cont-at(line.number))
    } else if type(c) == color {
      it => text(fill: c, it.text)
    } else if c == hide {
      hide
    } else {
      panic("Illegal mode: " + str(c))
    }
  })

  let render-window(from, to) = {
    show raw.line: line => {
      if line.number <= from {
        before-action(line)
      } else if line.number > to {
        after-action(line)
      } else {
        render-terminal-line(line.text, is-continuation: is-cont-at(line.number))
      }
    }
    raw(content, lang: none, block: true)
  }

  let steps = windows.windows(2)
  for (idx, (from, to)) in steps.enumerate() {
    if full or idx < steps.len() - 1 {
      only(start + idx, render-window(from, to))
    } else {
      // without `full`, the last step stays on the following subslides
      // (e.g. while an #uncover under the terminal is revealed)
      only((beginning: start + idx), render-window(from, to))
    }
  }
  if full {
    only((beginning: start + windows.len() - 1), render-window(0, content.split("\n").len()))
  }
}
