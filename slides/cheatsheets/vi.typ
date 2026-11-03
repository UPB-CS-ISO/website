// The cards that vim and nvim share: the keys are the same.
#import "common.typ": *

#let lost = tip[
  *Lost?* Press #kbd("Esc") two times: you are in *Normal* mode. Then #text(font: mono, weight: "bold", fill: accent)[:q!]
  #kbd("Enter") quits without saving. The last line of the screen tells the mode: `-- INSERT --`, `-- VISUAL --`, or
  nothing for Normal.
]

#let start(exe) = card("Start, save and quit",
  row("`" + exe + " <file>`", [open a file; it is created when you save]),
  row(":w", [save (_write_)]),
  row(":w <name>", [save as another file]),
  row(":q", [quit, if nothing changed]),
  row(":wq | :x | ZZ", [save and quit]),
  row(":q! | ZQ", [quit and throw the changes away]),
  row(":e <file>", [open another file]),
)

#let modes = card("Modes",
  row("Esc", [back to *Normal*: keys are commands]),
  row("i | a", [*Insert* before, after the cursor]),
  row("I | A", [Insert at the start, end of the line]),
  row("o | O", [a new line below, above, in Insert]),
  row("v | V | Ctrl-v", [*Visual*: characters, lines, a block]),
  row(": | / | ?", [*Command line*: a command, a search]),
  row("R", [Replace: type over the text]),
)

#let move = card("Move (Normal mode)",
  row("h j k l", [left, down, up, right (or the arrows)]),
  row("w | b | e", [next word, previous word, end of word]),
  row("0 | ^ | $", [start, first letter, end of the line]),
  row("gg | G", [first line, last line]),
  row("<n>G | :<n>", [line number _n_]),
  row("Ctrl-d | Ctrl-u", [half a screen down, up]),
  row("f<c> | t<c>", [to the next _c_ on the line, just before it]),
  row("%", [the matching bracket: `( )`, `[ ]`, `{ }`]),
  note: [A number repeats a move: #keys("5j") goes 5 lines down.],
)

#let edit = card("Edit (Normal mode)",
  row("x", [delete the character under the cursor]),
  row("r<c>", [replace one character with _c_]),
  row("dd | D", [delete the line, delete to the end of it]),
  row("cc | C", [change the line, change to the end of it]),
  row("J", [join the next line to this one]),
  row(">> | <<", [indent, unindent the line]),
  row("~", [switch upper and lower case]),
  row(".", [repeat the last change]),
  row("u | Ctrl-r", [undo, redo]),
)

#let operators = card("Operator + motion",
  row("d<motion>", [*delete*: #keys("dw") a word, #keys("d$") to the end]),
  row("c<motion>", [*change*: delete, then Insert: #keys("cw")]),
  row("y<motion>", [*yank* (copy): #keys("yw"), #keys("yy") the line]),
  row("<n>dd | d<n>w", [a count: #keys("3dd") deletes 3 lines]),
  row("diw | ci\"", [inside a word, inside quotes]),
  note: [The grammar of `vim`: an *operator*, then *where*. Learn the moves once, use them with every operator.],
)

#let copy = card("Copy and paste",
  row("yy | y$", [copy the line, copy to the end of it]),
  row("p | P", [paste after, before the cursor]),
  row("dd p", [move a line down: cut it, paste it below]),
  note: [`d` and `c` also copy what they delete: they work as _cut_.],
)

#let visual = card("Visual mode",
  row("v | V", [start selecting characters, lines]),
  row("d | y | c", [delete, copy, change the selection]),
  row("> | <", [indent, unindent the selected lines]),
  row("gv", [select the last selection again]),
)

#let search = card("Search and replace",
  row("/<text> Enter", [search forward; `?` searches backward]),
  row("n | N", [the next, the previous match]),
  row("* | #", [the word under the cursor, forward, backward]),
  row(":noh", [hide the highlight of the matches]),
  row(":s/old/new/", [replace the first match of the line]),
  row(":%s/old/new/g", [replace every match, in all the lines]),
  row(":%s/old/new/gc", [the same, asking each time]),
  note: [The text to find is a *regex*, as in `grep` and `sed`.],
)

#let windows = card("Windows and files",
  row(":sp | :vsp", [split the window, horizontally, vertically]),
  row("Ctrl-w w", [go to the next window]),
  row("Ctrl-w h", [the window to the left (#keys("j k l") too)]),
  row(":ls | :bn", [list the open files, go to the next one]),
  row(":!<cmd>", [run a shell command: #text(font: mono)[:!ls]]),
)

#let settings = card("Settings and help",
  row(":set number", [show the line numbers (`nonumber` hides)]),
  row(":syntax on", [colors for programs]),
  row(":help <topic>", [the manual: #text(font: mono)[:help :s], #text(font: mono)[:help dd]]),
  row(":q", [close the help window]),
  note: [Keep your settings in `~/.vimrc`, one per line, without the `:`.],
)
