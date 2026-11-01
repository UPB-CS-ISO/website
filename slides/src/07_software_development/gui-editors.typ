#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Graphical Editors #text(size: 10pt, weight: "regular")[\ _Code editors with windows, tabs and a mouse_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.6.3 - _Editoare în interfață grafică_
  + _Visual Studio Code documentation_, #link("https://code.visualstudio.com/docs")[online]
  + _VSCodium_, #link("https://vscodium.com")[online]
  + _Zed documentation_, #link("https://zed.dev/docs")[online]
]

// a small note about the modal editing of a graphical editor
#let modal-note(body) = text(size: 0.75em, fill: luma(110), body)

#slide[
  == VS Code / VSCodium

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1em)[
    #screenshot("img/gui/vscodium.png", width: 100%)
  ][
    - by Microsoft, free
    - a *browser*: built with Electron (Chromium + Node.js)
    - an *extension* for everything
    - VSCodium: the same, without telemetry

    #v(0.5em)
    #modal-note[`vim` keys: the Vim or VSCode Neovim extension]
  ]
]

#slide[
  == Zed

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1em)[
    #screenshot("img/gui/zed_lsp.png", width: 100%)
  ][
    - written in Rust
    - *not* a browser: a native app, drawn by the *GPU*, very fast
    - language servers, terminal, debugger built in

    #v(0.5em)
    #modal-note[`vim` and `helix` keys built in: `vim_mode`, `helix_mode`]
  ]
]
