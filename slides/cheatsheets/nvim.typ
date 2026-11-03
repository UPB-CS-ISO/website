#import "common.typ": *
#import "vi.typ": *

#show: sheet.with("nvim", "nvim <file>", [Neovim: `vim`, with better defaults and Lua settings], ":Tutor")

#lost
#start("nvim")
#modes
#move
#edit
#operators
#copy
#visual
#search
#windows

#card("Only in Neovim",
  row("`nvim +Tutor`", [start the tutorial; #text(font: mono)[:Tutor] from inside]),
  row(":checkhealth", [find out what is missing or broken]),
  row("Ctrl-l", [hide the highlight of the matches]),
  row("gcc | gc", [comment the line, the selection (0.10 and later)]),
  row("\"+y | \"+p", [copy to, paste from the system clipboard]),
  row(":terminal", [a shell inside the editor]),
  row("Ctrl-\\ Ctrl-n", [leave the Insert mode of the terminal]),
  note: [The system clipboard needs `wl-clipboard` on Sway (Wayland).],
)

#card("Settings and help",
  row(":set number", [show the line numbers (`nonumber` hides)]),
  row(":help <topic>", [the manual: #text(font: mono)[:help :s], #text(font: mono)[:help dd]]),
  row(":help nvim-defaults", [what Neovim does differently from `vim`]),
  row(":q", [close the help window]),
  note: [Keep your settings in `~/.config/nvim/init.lua`, like `vim.opt.number = true`. The colors of the
    syntax are on by default.],
)
