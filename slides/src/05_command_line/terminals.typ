#import "/src/slides.typ": *
#import "common.typ": *
#import "tree.typ": *

#slide[
  = Terminal & Shell #text(size: 10pt, weight: "regular")[\ _How we talk to the operating system_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Sections 2.1 - 2.2 - _The Bourne Shell_, _Using the Shell_
    - Chapter 3 - _Devices_
      - Section 3.4 - _Device Name Summary_ (terminals)
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.6.1 - _Terminale_
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.1 - _Shellul. Funcționarea shellului_
    - Chapter 9 - _Pornirea sistemului_
      - Section 9.6.1 - _Pornirea terminalelor de login_
]

#slide[
  == The _Classic_ Terminal
  Many users, one computer

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #align(center)[#diagram("img/mainframe_terminals.pdf", height: 90%)]
  ][
    #v(1em)
    #uncover("2-")[#block[- one large computer (the _mainframe_), many users]]
    #uncover("3-")[#block[- every user has a *terminal*: a keyboard and a printer or a screen, *no processor*]]
    #uncover("4-")[#block[- the terminals were _TeleTypes_ (*TTY*): they send the keys to the computer and print what it sends back]]
    #uncover("5-")[#block[- 💡 Linux still calls terminals `tty`: `/dev/tty1`, `/dev/tty2`, ...]]
  ]
]

#let text-mode = (
  ```
  [PID 1]  systemd (init)
  │     # The first user-space process
  │     # started by the kernel
  ```,
  ```
  [PID 1]  systemd (init)
  │     # The first user-space process
  │     # started by the kernel
  └── [PID 20+]  agetty tty1
          # Waits for a login on /dev/tty1
  ```,
  ```
  [PID 1]  systemd (init)
  │     # The first user-space process
  │     # started by the kernel
  ├── [PID 20+]  agetty tty1
  ├── [PID 21+]  agetty tty2
  ├── [PID ...]  ...
  └── [PID 25+]  agetty tty6
          # One for every text terminal
  ```,
  ```
  [PID 1]  systemd (init)
  │     # The first user-space process
  │     # started by the kernel
  ├── [PID 20+]  login alice
  │     │   # agetty became login (exec)
  │     └── [PID 30+]  bash
  │             # alice's shell, on /dev/tty1
  ├── [PID 21+]  agetty tty2
  ├── [PID ...]  ...
  └── [PID 25+]  agetty tty6
  ```,
  ```
  [PID 1]  systemd (init)
  │     # The first user-space process
  │     # started by the kernel
  ├── [PID 20+]  login alice
  │     └── [PID 30+]  bash
  ├── [PID 21+]  agetty tty2
  ├── [PID ...]  ...
  ├── [PID 25+]  agetty tty6
  └── [PID 8+]  gdm / sddm / lightdm
          # Graphical login
  ```,
)

#slide[
  == The _Real_ Terminal

  #toolbox.side-by-side(columns: (1.2fr, 1fr), gutter: 1.5em)[
    #only("1-3")[
    #align(center)[#diagram("img/virtual_teletype.svg", height: 70%)]
    ]
    #only(4)[
    #align(center)[#diagram("img/virtual_teletype_shell.svg", height: 70%)]
    ]
    #only(5)[
      #align(center)[#diagram("img/terminal_emulator.svg", width: 100%)]
    ]

    #set text(size: 0.85em)
    - the kernel provides several _virtual terminals_: `/dev/tty1` ... `/dev/tty6`
    - they share the same screen and keyboard
    #uncover("3-")[#block[- #kbd("Alt") + #kbd("F1") ... #kbd("F6") changes the terminal]]
  ][
    #tree-text(size: 9pt)[#tree-steps(text-mode)]
    #only(4)[User `alice` logs in using `/dev/tty1`]
    #only(5)[The graphical UI is another application, using one of the terminals]]
]

#slide[
  == The _Virtual_ Terminal
  Graphical Mode Linux

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #align(center)[#diagram("img/terminal_emulator.svg", width: 100%)]

    #set text(size: 0.85em)
    _Xorg_ or _Wayland_ (display servers) take over a terminal (`/dev/tty1` or `/dev/tty2`) and draw on the screen through the framebuffer (`/dev/fb0`)
  ][
    #set text(size: 0.9em)
      === Switch Modes
      - #kbd("Ctrl") + #kbd("Alt") + #kbd("F3") ... #kbd("F6") #arrow text mode
      - #kbd("Ctrl") + #kbd("Alt") + #kbd("F1") or #kbd("F2") #arrow back to the graphical mode (#kbd("F7") on older systems)
    #uncover("2-")[
      === Console Applications
      #block[- run in a _terminal emulator_ (`kitty`, `ptyxis`, `alacritty`, ...)]
    ]
    #uncover("3-")[#block[- the terminal emulator is a *graphical* application]]
    #uncover("4-")[#block[- it provides a _pseudo terminal_, `/dev/pts/n`]]
  ]
]

#slide[
  == Terminal Emulator
  Provides a pseudo terminal

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    `kitty`, `ptyxis`, `alacritty`, ...
    #uncover("2-")[#block[1. opens `/dev/ptmx`, the kernel creates a _pseudo terminal_: a *master* (kept by the emulator) and a *slave* (`/dev/pts/n`)]]
    #uncover("3-")[#block[2. starts the shell (`fork` + `exec`) with `0`, `1` and `2` connected to `/dev/pts/n`]]
    #uncover("4-")[#block[3. the keys you press are written into the *master*, the shell reads them from `stdin`]]
    #uncover("5-")[#block[4. the shell writes into `stdout`, the emulator reads it from the *master* and draws the text in its window]]

    `bash`, `sh`, `zsh`, ...
    - only see a terminal: `/dev/pts/n`
  ][
    #align(center)[#diagram("img/pseudo_terminal.svg", height: 42%)]

    #uncover("6-")[
      #set text(size: 0.8em)
      ```terminal
      $ tty                  # the terminal of the shell
      /dev/pts/1
      $ ps                   # the processes of this terminal
          PID TTY          TIME CMD
         4011 pts/1    00:00:00 bash
         4242 pts/1    00:00:00 ps
      ```
    ]
  ]
]

#slide[
  == Shell
  Operating System Interaction

  #align(center)[
    #box(baseline: 35%, image("img/bash.png", height: 3em))
    #h(0.5em)
    #text(size: 1.2em)[_A process whose main purpose is to allow the interaction with the Operating System_]
  ]

  #v(0.5em)
  #toolbox.side-by-side(columns: (1fr, 1fr, 1fr), gutter: 1.5em)[
    #uncover("2-")[
      === ⌨️ Command Line
      - `bash`, `sh`, `zsh`, `fish`
      - `cmd`
      - `powershell`
    ]
  ][
    #uncover("3-")[
      === 🔤 Text User Interface
      - `mc`
      - `nnn`
      - `yazi`
    ]
  ][
    #uncover("4-")[
      === 🖱️ Graphical
      - `explorer.exe`, Finder, `nautilus`
      - Total Commander
      - Control Panel, Settings
    ]
  ]
]
