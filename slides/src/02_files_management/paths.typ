#import "/src/slides.typ": *
#import "logos.typ": *

#slide[
  = Path #text(size: 10pt, weight: "regular")[\ _absolute and relative_]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.4 - _Navigating Directories_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.1.3 - _Căi relative și căi absolute_
]

#slide[
  == What Is a Path?

  A *path* tells the operating system _where a file or folder is_.

  Two main types:
  - *Absolute paths* start from the root of the file system: `/home/student/Movies/the_odyssey.mkv`
  - *Relative paths* start from your _current directory_: `Movies/the_odyssey.mkv`

  #v(1em)

  💡 every running application has one single _current directory_ at a time
]

#slide[
  == Absolute Path
  full path

  Shows the *complete location* of a file

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === #windows-logo() Windows

    Always starts from a *drive letter*

    ```
    C:\Users\Alice\Videos\the_odyssey.mkv
    D:\Trailers\avatar_fire_and_ash.mp4
    ```
  ][
    === #linux-logo() Linux (POSIX)

    Always starts from the *root directory `/`*

    ```
    /home/alice/Movies/the_odyssey.mkv
    /var/log/syslog
    /usr/bin/python3
    ```
  ]

  #uncover(2)[
    *🤔 Just think of a real world address of a person. You need:*\
    `🗄️ Country -> 📁 County -> 📁 City -> 📁 Street -> 📁 Street Number -> 📄 person`
  ]
]

#slide[
  == Relative Path
  to the current directory

  - ✅ Shorter
  - ⚠️ Depends on the current folder (_where you are_)
  - 📦 allows an application to find its own files, regardless of where it is installed (`./textures`)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === #windows-logo() Windows

    Does *NOT* start from a *drive letter*

    ```bash
    # If you're in C:\Users\Alice
    Videos\the_odyssey.mkv
    ```
  ][
    === #linux-logo() Linux (POSIX)

    Does *NOT* start from the *root directory `/`*

    ```bash
    # If you're in /home/alice
    Movies/the_odyssey.mkv
    ```
  ]

  #uncover(2)[
    *🤔 Just think of a real world address of a person _relative to your own current location_:*\
    `🧍 -> 📁 Street -> 📁 Street Number -> 📄 person`
    - in the example, you already know the `📁 Country` and the `📁 City` in which you are now
  ]
]

#slide[
  == Special Path Symbols
  in Windows and Linux (POSIX)

    #table(
      columns: (auto, auto, auto, 1fr),
      table.header([Meaning], [#windows-logo() Windows], [#linux-logo() Linux (POSIX)], [Notes]),
      [Current directory], [`.`], [`.`], [Refers to the folder you are currently in],
      [Parent directory], [`..`], [`..`], [Moves one level up in the hierarchy],
      [Directory separator], [`\`], [`/`], [Used to separate folder names in a path],
      [Root directory], [Drive + `\` (e.g. `C:\`)], [`/`], [Top-level directory in the file system],
    )

    #only("2,3")[⚠️ `\` in POSIX systems is used for escaping characters (`\n ...`)\ ]
    #only(3)[⚠️ `~` in `bash`-like (`...sh`) command interpreters is used for the _user's home folder_]
]
