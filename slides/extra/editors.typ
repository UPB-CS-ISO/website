#slide[
  == File Editors
  ✏️ for text files

  - the operating system does not support _editing files_
  - each file type has several applications that can edit it
  - POSIX provides text file editors

  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 1em,
    align: center,
    [
      _Very Basic_
      #image("img/navigation/nano.png", height: 40%)
      `pico` / #link("https://www.nano-editor.org")[`nano`]
    ],
    [
      _What professionals use_
      #image("img/navigation/nvim.png", height: 40%)
      `vi` / #link("https://www.vim.org")[`vim`] / #link("https://neovim.io")[`nvim`]
    ],
    [
      _New runner up_
      #image("img/navigation/helix.png", height: 40%)
      #link("https://helix-editor.com")[`helix`]
    ],
  )
]
