#import "common.typ": *

#show: sheet.with("hx", "hx <file>", [Helix: a modal editor where you *select first*, then act], "hx --tutor")

#tip[
  *Lost?* Press #kbd("Esc") two times: you are in *Normal* mode. Then #text(font: mono, weight: "bold", fill: accent)[:q!]
  #kbd("Enter") quits without saving. The mode is at the bottom left: `NOR`, `INS` or `SEL`. After #kbd("g"),
  #kbd("Space"), #kbd("m") or #kbd("z"), a popup lists the keys you can press next.
]

#card("Start, save and quit",
  row("`hx <file>`", [open a file; it is created when you save]),
  row(":w", [save (_write_)]),
  row(":w <name>", [save as another file]),
  row(":q", [quit, if nothing changed]),
  row(":wq | :x", [save and quit]),
  row(":q!", [quit and throw the changes away]),
  row(":o <file>", [open another file]),
  row("Space f", [find and open a file, by a part of its name]),
)

#card("Modes",
  row("Esc", [back to *Normal*: keys are commands]),
  row("i | a", [*Insert* before, after the selection]),
  row("I | A", [Insert at the start, end of the line]),
  row("o | O", [a new line below, above, in Insert]),
  row("v", [*Select*: the moves extend the selection]),
  row(":", [a *command*, like #text(font: mono)[:w]]),
  row("g | Space", [the _goto_ menu, the _space_ menu]),
)

#card("Move (Normal mode)",
  row("h j k l", [left, down, up, right (or the arrows)]),
  row("w | b | e", [next word, previous word, end of word: they also *select* the word]),
  row("gh | gs | gl", [start, first letter, end of the line]),
  row("gg | ge", [first line, last line]),
  row("<n>G | :g <n>", [line number _n_]),
  row("Ctrl-d | Ctrl-u", [half a screen down, up]),
  row("f<c> | t<c>", [to the next _c_, just before it (in the whole file)]),
  row("mm", [the matching bracket: `( )`, `[ ]`, `{ }`]),
)

#card("Select",
  row("x", [select the line; press it again for the next one]),
  row("%", [select the whole file]),
  row("miw | mi\"", [select inside a word, inside quotes]),
  row("s<regex> Enter", [select every match *inside* the selection]),
  row("C", [one more cursor, on the next line]),
  row(",", [keep only the main selection]),
  row(";", [shrink the selection to the cursor]),
  note: [With several selections, every command acts on all of them at once.],
)

#card("Edit the selection",
  row("d | c", [delete; delete and Insert (_change_)]),
  row("y | p | P", [copy (_yank_), paste after, before]),
  row("r<c>", [replace every selected character with _c_]),
  row("> | <", [indent, unindent]),
  row("J", [join the selected lines]),
  row("~", [switch upper and lower case]),
  row(".", [repeat the last insert]),
  row("u | U", [undo, redo]),
  row("Ctrl-c", [comment, uncomment the lines]),
)

#card("From vim to helix",
  row("x d", [delete the line (`vim`: #keys("dd"))]),
  row("w d", [delete a word (`vim`: #keys("dw"))]),
  row("e c", [change to the end of the word (`vim`: #keys("cw"))]),
  row("x y p", [copy the line, paste it below (`vim`: #keys("yy p"))]),
  row("x x x d", [delete 3 lines (`vim`: #keys("3dd"))]),
  row("ge | gl", [last line, end of line (`vim`: #keys("G"), #keys("$"))]),
  note: [`vim` says *what to do*, then *where*: #keys("dw"). Helix says *where* first and shows it selected, then
    *what*: #keys("w d").],
)

#card("Search and replace",
  row("/<text> Enter", [search forward; `?` searches backward]),
  row("n | N", [select the next, the previous match]),
  row("*", [search for the selected text]),
  row("% s <old> Enter c <new> Esc", [replace every `old` in the file with `new`]),
  row("Space /", [search in all the files of the directory]),
  note: [The text to find is a *regex*, as in `grep` and `sed`.],
)

#card("Windows and files",
  row(":sp | :vs", [split the window, horizontally, vertically]),
  row("Ctrl-w w", [go to the next window]),
  row("Space b", [pick one of the open files]),
  row(":bn | :bc", [the next open file, close this one]),
  row(":sh <cmd>", [run a shell command: #text(font: mono)[:sh ls]]),
  row("Space y | Space p", [copy to, paste from the system clipboard]),
)

#card("Settings and help",
  row("`hx --tutor` | :tutor", [the tutorial, about 30 minutes]),
  row("Space ?", [search all the commands, with their keys]),
  row(":theme <name>", [try a color theme; #kbd("Tab") lists them]),
  row(":config-open", [open your settings]),
  row("`hx --health`", [check the support for programming languages]),
  note: [Keep your settings in `~/.config/helix/config.toml`, like `theme = "onedark"`. The line numbers and the
    syntax colors are on by default. All the keys: `docs.helix-editor.com/keymap.html`.],
)
