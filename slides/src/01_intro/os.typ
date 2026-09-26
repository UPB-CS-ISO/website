#import "/src/slides.typ": *

#slide[
  = Operating System #text(size: 10pt, weight: "regular")[\ _the purpose of an OS_]
]

#slide[
  == The Main Role of an Operating System

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #only("2,3")[
      *Allow Portability*
      - provides a hardware independent API
      - applications should run on any hardware
    ]

    #only(3)[
      *Resources Management and Isolation*
      - allow applications to access resources
      - prevent applications from accessing hardware directly
      - isolate applications
    ]
  ][
    #align(center)[#image("img/os/os.pdf", width: 90%)]
  ]
]

#slide[
  == Desktop and Server Operating Systems — abstractions

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #only("2,3")[
      *Actions*
      - _Applications_
      - use the _Processor_ and _Accelerators_ (GPU, Neural Engine, etc)
    ]

    #only(3)[
      *Data*
      - everything is a file
      - peripherals are viewed as files (_POSIX_)
        - `/dev/input/keyboard` - keyboard
        - `/dev/fb` - screen (framebuffer)
        - `/dev/sda` - Disk Drive A (first)
    ]
  ][
    #align(center)[#image("img/os/abstractions.pdf", width: 90%)]
  ]
]

#slide[
  == Embedded Operating Systems

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    *Actions*
    - Simple _applications_
    - use the _Processor_ and _Accelerators_ (Crypto Engines, Neural Engine, etc)

    *Peripheral*
    - provide a hardware independent API
    - prevent processes from accessing the peripheral

    _usually_ the applications and the kernel are compiled together into a *single binary*
  ][
    #align(center)[#image("img/os/embedded_os.pdf", width: 90%)]
  ]
]

#slide[
  == The OS Stack

  // kernel / libc / libraries / basic tools (commands) / applications

  #align(center)[#image("img/os/os_stack.pdf", width: 60%)]
]

#slide[
  == Application Examples

  #table(
    columns: (auto, 1fr, 1fr, 1fr),
    table.header([What it does], [Windows], [Linux], [macOS]),
    [Desktop], [`explorer.exe`], [#link("https://gitlab.gnome.org/GNOME/nautilus")[`nautilus`]], [Finder],
    [Applications], [`taskbar.exe`], [#link("https://gitlab.gnome.org/GNOME/gnome-shell")[`gnome-shell`]], [Dock],
    [Files], [`explorer.exe`], [#link("https://gitlab.gnome.org/GNOME/nautilus")[`nautilus`]], [Finder],
    [Settings],
    [`start ms-settings:`],
    [#link("https://gitlab.gnome.org/GNOME/gnome-control-center")[`gnome-control-center`]],
    [System Settings],

    [Commands], [`cmd.exe` or `powershell.exe`], [`bash` or `zsh`], [`bash` or `zsh`],
    [Documents], [`powerpoint.exe`], [#link("https://www.libreoffice.org")[`libreoffice`]], [Pages],
    [Edit Code], [`code.exe`], [`code`], [`code`],
    [Terminal#footnote[Third party recommendations for Linux and macOS are #link("https://sw.kovidgoyal.net/kitty/")[Kitty], #link("https://alacritty.org")[Alacritty] and #link("https://ghostty.org")[Ghostty]]], [_handled by the OS_], [#link("https://gitlab.gnome.org/chergert/ptyxis")[`ptyxis`]], [Terminal],
  )
]

#slide[
  = Where can we see the OS
]

#slide[
  == Where can we see the OS

  #only(1)[
    #align(center)[
      #image("img/os/linuxboot.png", height: 75%)

      #image("img/distributions/linux.png", height: 10%)
      *During Boot*
    ]
  ]

  #only(2)[
    #align(center)[
      #image("img/os/bluescreen.png", height: 75%)
      #image("img/distributions/windows.jpg", height: 10%)
      *Blue Screen (BSoD)*
    ]
  ]

  #only(3)[


    #align(center)[
      #image("img/os/kernelpanic.jpg", height: 75%)
      #image("img/distributions/linux.png", height: 10%)
      *Linux Kernel Panic*
    ]
  ]

  #only(4)[

    #align(center)[
      #image("img/os/kernelpanic_macos.jpg", height: 75%)
      #image("img/distributions/linux.png", height: 10%)
      *macOS Kernel Panic*
    ]
  ]
]

#slide[
  == Where can we see the OS

  #table(
    columns: 3,
    table.header([During Boot], [Blue Screen (BSoD)], [Kernel Panic]),
    [#image("img/os/linuxboot.png", width: 90%)],
    [#image("img/os/bluescreen.png", width: 90%)],
    [
      #image("img/os/kernelpanic.jpg", width: 90%)
      #image("img/os/kernelpanic_macos.jpg", width: 90%)
    ],
  )
]

#slide[
  == The Kernel

  - is a collection of applications that run in privileged mode
  - one _main application_ and several _utilities apps_

  #only(2)[

    #align(center)[#image("img/os/kernel_times.png", height: 80%)]
    #place(bottom + right)[
      #image("img/distributions/windows.jpg", height: 10%)
      *Windows Task Manager*
    ]
  ]

  #only(3)[
    #align(center)[#image("img/os/htop.png", height: 80%)]
    #place(bottom + right)[
      #image("img/distributions/linux.png", height: 10%)
      *`htop`*
    ]
  ]
]
