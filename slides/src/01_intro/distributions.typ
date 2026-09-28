#import "/src/slides.typ": *

#slide[
  = Distribution #text(size: 10pt, weight: "regular")[\ _what an OS is from the user's point of view_]
]

#slide[
  == Meet the _Mainframe_

  #toolbox.side-by-side(columns: (3fr, 1fr))[
    #only("1-2")[
      #image("img/distributions/mainframe_single_terminal.pdf")
    ]
    #only("3-")[
      #image("img/distributions/mainframe_terminals.pdf")
    ]
  ][
    *Size:* a full room\
    #only("1-2")[
      *IO:* remote terminal\
      *Users:* single\
      *Programs:* one batch job
    ]
    #only("3-")[
      *IO:* remote terminals\
      *Users:* multiple
      *Programs:* multiple
    ]

    #only("2,3")[
      #align(center)[
        #text(size: 20pt)[🗑️]\
        Waste of compute power
      ]
    ]

    #only(3)[
      #align(center + bottom)[
        #text(size: 30pt)[🚥]\
        The need for an Operating System\
        \
        _UNIX_
      ]
    ]
  ]
]

#slide[
  == UNIX

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    Mainframes provide a lot of hardware
    - need to be shared by several users
    - each user has a terminal connected to the mainframe
    - run several programs in parallel

    #image("img/distributions/mainframe_terminals.pdf", height: 50%)

    #only(4)[
      🔒 Is open source up to version _UNIX System III_
    ]
  ][
    Ken Thompson & Dennis Ritchie (Bell Labs, AT&T)

    #align(center)[#image("img/distributions/ritchie_thompson.jpg", width: 90%)]

    #item-by-item(start: 2)[
      - Denis Ritchie writes C
      - together with Ken Thompson use C to write UNIX.
    ]
  ]
]

#slide[
  == The POSIX Standard

  #counter(footnote).update(0)

  _Portable Operating System Interface_ (ISO 9945)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    Defines:
    - how an OS should work (_everything is a file_)
    - how the C API looks like (ex `stdio.h`, `unistd.h`)
    - what commands (basic software) should be available

    #only("2-")[
      Allows:
      - applications to be portable
        - _in C/C++ source code format only_
    ]

    #only(3)[
      === When UNIX became closed source ->
    ]
  ][

    #only(3)[
      UC *Berkeley Software Distribution (BSD)*

      #table(
        columns: 4,
        table.header([FreeBSD], [Darwin], [OpenBSD], [NetBSD]),
        [#image("img/distributions/freebsd.png", height: 1.1cm)],
        [#image("img/distributions/macos.png", height: 1.1cm)],
        [#image("img/distributions/openbsd.png", height: 1.1cm)],
        [#image("img/distributions/netbsd.png", height: 1.1cm)],
      )

      New kernels

      #table(
        columns: 3,
        table.header([*Minix*], [*Linux*], [*RedoxOS*#footnote[Partially POSIX compliant]]),
        [#image("img/distributions/minix.png", height: 1.1cm)],
        [#image("img/distributions/linux.png", height: 1.1cm)],
        [#align(center)[#image("img/distributions/redoxos.png", height: 1.1cm)]],
      )
    ]
  ]
]

#slide[
  == GNU Software

  #counter(footnote).update(0)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    Basic _UNIX_ commands and software *rewritten*
    #item-by-item(start: 2)[
      - startup software (`init`)
      - most of what we call today _coreutils_
      - C Compiler -> GNU Compiler Collection (#link("https://gcc.gnu.org")[`gcc`])
        - C and C++ standard libraries
        - `flex` / `yacc`
      - X Windows System (#link("https://www.x.org/wiki/")[`x11`])
    ]

    #only(6)[
      *Modern Software*
      - _coreutils_ are being rewritten in Rust (#link("https://uutils.github.io")[_uutils_])#footnote[Used by Ubuntu starting with 26.04]
      - `gcc` is being slowly replaced by #link("https://llvm.org")[LLVM]
      - `x11` is being replaced by #link("https://wayland.freedesktop.org")[Wayland]
    ]
  ][
    _Richard Stallman_ (MIT)

    #align(center)[
      #grid(
        columns: (1fr, 1fr),
        gutter: 1em,
        image("img/distributions/richard_stallman.jpg", width: 90%), image("img/distributions/gnu.png", width: 60%),
      )
    ]

    His vision is that software should be:
    - free to share and modify
    - #link("https://www.gnu.org/licenses/gpl-3.0.en.html")[GPL] and #link("https://www.gnu.org/licenses/lgpl-3.0.en.html")[LGPL] licenses
      - allows selling and modifying
      - modified code must be relicensed under GPL
  ]
]

#slide[
  == POSIX Distributions _Tree_
  #align(center + horizon)[#image("img/distributions/unix_tree.svg", height: 100%)]
]

#slide[
  == The Linux Kernel

  #toolbox.side-by-side(columns: (2fr, 1fr), gutter: 1.5em)[

    #align(center)[#image("img/distributions/linus_torvalds.jpeg", height: 70%)]
    === _Linus Torvalds_ (University of Helsinki)

    #item-by-item()[
      - did not agree with A. Tannenbaum about how Minix should work
      - wrote his own 👨‍💻 _POSIX compliant_ OS, called it Linu#strong[x]
    ]
  ][
    #only(3)[
      - is the actual operating system
      - invisible to the user
        - except when it boots 🏁 and panics 😱
      - 25 mil line of code (LOC)
      - manages all the system resources

      #align(center)[
        #image("img/distributions/linux.png", height: 40%)

        Meet _Tux_
      ]
    ]
  ]
]

#slide[
  == GNU/Linux = ❤️
  GNU Software on top of the Linux kernel

  #align(center)[#image("img/distributions/os_timeline.png", width: 90%)]

  #item-by-item(start: 2)[
    - GNU Hurd 👷🚧🏗️ (_work in progress for many many years_)
    - The Linux kernel 🐧 still is the _temporary replacement_
  ]
]

#slide[
  == Base Distributions
  The main Linux distributions that started it

  _Took the Linux kernel, added the GNU libraries and tools and wrote a package manager to install software_

  #table(
    columns: (auto, auto, auto, auto, auto, auto),
    table.header([], [Name], [Tagline], [Package Format], [Package Manager], [Release Year]),
    [#image("img/distributions/slackware.png", height: 0.6cm)],
    [#link("http://www.slackware.com")[Slackware]],
    [_Oldest distribution_],
    [`tgz`],
    [`pkgtool`],
    [1993],

    [#image("img/distributions/debian.png", height: 0.6cm)],
    [#link("https://www.debian.org")[Debian]],
    [_Free Software_],
    [`deb`],
    [`apt` / `dpkg`],
    [1993],

    [#image("img/distributions/red-hat.svg", height: 0.6cm)],
    [#link("https://www.redhat.com")[Red Hat Linux]],
    [_Enterprise_],
    [`rpm`],
    [`dnf` / `rpm`],
    [1995],
  )

  These are the base for most of the modern distributions that we have today.
]

#slide[
  == Modern Distributions

  #table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    table.header([], [Name], [Tagline], [Parent], [Package\ Format], [Package\ Manager], [Release]),
    [#image("img/distributions/opensuse.png", height: 0.6cm)],
    [#link("https://www.suse.com")[SUSE Linux]],
    [_Enterprise-grade Linux_],
    [_Originally Slackware, later RPM-based_],
    [`rpm`],
    [`zypper`, `yast`],
    [1994],

    [#image("img/distributions/arch.png", height: 0.6cm)],
    [#link("https://archlinux.org")[ArchLinux]],
    [_Minimal Linux_],
    [N/A],
    [`pkg.tar.zst`],
    [`pacman`],
    [2002],

    [#image("img/distributions/fedora.png", height: 0.6cm)],
    [#link("https://www.redhat.com")[Fedora]],
    [_Desktop Linux_],
    [_Red Hat Linux renamed_],
    [`rpm`],
    [`dnf` / `rpm`],
    [2003],

    [#image("img/distributions/ubuntu.png", height: 0.6cm)],
    [#link("https://www.ubuntu.org")[Ubuntu]],
    [_Linux for Humans_],
    [Debian],
    [`deb` and `snap`],
    [`apt` / `dpkg` and `snap`],
    [2004],

    [#image("img/distributions/opensuse.png", height: 0.6cm)],
    [#link("https://www.opensuse.org")[openSUSE]],
    [_Stable, usable Linux for everyone_],
    [SUSE Linux],
    [`rpm`],
    [`zypper`, `rpm`],
    [2005],
  )
]

#slide[
  == Most Used Linux Distribution?

  #uncover(2)[
    #align(center)[#image("img/distributions/android.png", height: 100%)]
  ]
]

#slide[
  == Non GNU Distributions
  They use Linux, but most of the software is not from GNU

  #table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    table.header([], [Distribution], [Tagline], [Parent], [Package Format], [Package Manager], [Release Year]),
    [#image("img/distributions/android.png", height: 0.6cm)],
    [#link("https://source.android.com")[Android]],
    [_Mobile Linux platform_],
    [Linux kernel (AOSP)],
    [`.apk` (only Android apps) \ `.aab` (only Android apps) \ `.apex` (libraries)],
    [AOSP tools (not typical package manager)],
    [2008],

    [#image("img/distributions/chromeos.svg", height: 0.6cm)],
    [#link("https://chromeos.google")[ChromeOS]],
    [_The cloud-first OS_],
    [Gentoo Linux],
    [Custom (`.crx`, `.apk`, others)],
    [`portage`, `cros_sdk`, Flatpak (via Crostini)],
    [2011],
  )
]
