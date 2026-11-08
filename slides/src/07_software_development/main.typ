#import "/src/slides.typ": *
#import "common.typ": ward, uso-book, make-manual, lsp-spec, dap-spec, pro-git, shell-commands

#show: uso_slides.with(title: "7. Software Development")
// command lines in inline code get the terminal colors
#show: shell-commands

#slide[
  == Bibliography

  #text(size: 11pt)[
    #columns(2)[
      + #ward
        - Chapter 15 - _Development Tools_
          - Section 15.1 - _The C Compiler_
          - Section 15.2 - _make_
          - Section 15.4 - _Scripting Languages_
          - Section 15.5 - _Java_
      + #uso-book
        - Chapter 6 - _Dezvoltarea aplicațiilor_
      #colbreak()
      3. #make-manual
        - Chapter 2 - _An Introduction to Makefiles_
      + #lsp-spec
      + #dap-spec
      + #pro-git
        - Chapters 1 - 3
    ]
  ]
  #v(0pt)
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 18pt)[
      _Everyone knows that debugging is twice as hard as writing a program in the first place. So if you're as clever as you can be when you write it, how will you ever debug it?_
    ]

    #v(0.5em)
    Brian Kernighan and P. J. Plauger, _The Elements of Programming Style_
  ]
]

#slide[
  == Software Development

  #text(size: 12pt)[
    #columns(2)[
      - Compiled & Interpreted Languages
        - compiler, interpreter, bytecode
      - Integrated Development Environments
      - Language Servers
      - Debuggers
      - Debug Adapters
      - The C Compilation Pipeline
        - preprocessor, compiler, assembler, linker
      #colbreak()
      - Building with `make`
        - rules, step by step
      - A `Makefile` for a Project
        - automatic variables, pattern rules
      - Special Targets
        - `.PHONY`, `clean`, `all`, `run`
      - Header Dependencies
      - Version Control with Git
        - commits, commit vs push, branches
      - From an Editor to an IDE
        - LSP + DAP
    ]
  ]
]

#include "languages.typ"
#include "ide.typ"
#include "lsp.typ"
#include "debugger.typ"
#include "dap.typ"
#include "compiling.typ"
#include "make.typ"
#include "make-project.typ"
#include "make-special.typ"
#include "make-headers.typ"
#include "git.typ"
#include "editor-ide.typ"

#slide[
  == We talked about

  #text(size: 12pt)[
    #columns(2)[
      - Compiled & Interpreted Languages
        - compiler, interpreter, bytecode
      - Integrated Development Environments
      - Language Servers
      - Debuggers
      - Debug Adapters
      - The C Compilation Pipeline
        - preprocessor, compiler, assembler, linker
      #colbreak()
      - Building with `make`
        - rules, step by step
      - A `Makefile` for a Project
        - automatic variables, pattern rules
      - Special Targets
        - `.PHONY`, `clean`, `all`, `run`
      - Header Dependencies
      - Version Control with Git
        - commits, commit vs push, branches
      - From an Editor to an IDE
        - LSP + DAP
    ]
  ]
]
