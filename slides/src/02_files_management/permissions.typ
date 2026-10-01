#import "/src/slides.typ": *
#import "diagram.typ": *

#slide[
  = File Types and Permissions #text(size: 10pt, weight: "regular")[\ _who can do what with a file_]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.17 - _File Modes and Permissions_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 5 - _Utilizatori_
      - Section 5.5 - _Accesul la sistemul de fișiere_
]

#slide[
  == 🗂️ File Types in Linux

  Linux treats everything as a *file*, but there are several types:

  #set text(size: 0.85em)
  #table(
    columns: (auto, auto, 1fr, auto),
    table.header([Symbol], [Type], [Description], [Example]),
    [`-`], [📄 *Regular file*], [Text, binary, images, executables], [`/etc/passwd`, `/bin/ls`],
    [`d`], [📁 *Directory*], [Contains other files or directories], [`/home`, `/usr/bin`],
    [`l`], [🔗 *Symbolic link*], [Shortcut or reference to another file], [`/lib64 → /usr/lib64`],
    [`c`], [⚙️ *Character device*], [Device file that handles data character by character], [`/dev/tty`, `/dev/null`],
    [`b`], [💾 *Block device*], [Device file that handles data in blocks], [`/dev/sda`, `/dev/loop0`],
    [`p`], [🚇 *Named pipe (FIFO)*], [Used for inter-process communication], [Custom IPC files],
    [`s`], [🌐 *Socket*], [Used for network or inter-process communication], [`/run/docker.sock`],
  )
]

#slide[
  == iNode
  file information node

  #only(1)[
    #align(center)[#image("img/permissions/inode.pdf", height: 85%)]
  ]

  #only(2)[
    #align(center)[
      #text(size: 18pt)[*🤔💭 What is missing?*]

      #image("img/permissions/inode.pdf", height: 70%)
    ]
  ]
]

#slide[
  == Directory Data
  where the file name is stored

  - _*links* iNodes to file names_
  - `.` and `..` are always present
  - the directory is a _file whose contents are read by the file system driver_

  #align(center)[#image("img/permissions/folder_data.pdf", width: 80%)]
]

#slide[
  == How Symbolic and Hard Links Work

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    === 🔗 Symbolic Link

    ```terminal
    $ ln -s the_odyssey.mkv tonight.mkv
    $ ls -l -i
    154736507 -rw-r--r--  1 ... the_odyssey.mkv
    154736548 lrwxr-xr-x  1 ... tonight.mkv -> the_odyssey.mkv
    ```

    ```
    📂 /home/alice/Movies/
    ├── 📄 the_odyssey.mkv
    └── 🔗 tonight.mkv  ➜  the_odyssey.mkv
    ```

    - `tonight.mkv` stores the *path* to the target.
    - If `the_odyssey.mkv` is deleted ❌ → the link breaks.
  ][
    === ⚓ Hard Link

    ```terminal
    $ ln the_odyssey.mkv favorite.mkv
    $ ls -l -i
    154736507 -rw-r--r--  2 ... favorite.mkv
    154736507 -rw-r--r--  2 ... the_odyssey.mkv
    ```

    ```
    📂 /home/alice/Movies/
    ├── 📄 favorite.mkv     (inode #154736507)
    └── 📄 the_odyssey.mkv  (inode #154736507)
    ```

    - Both files share the *same inode number*.
    - If `the_odyssey.mkv` is deleted 🗑️ → `favorite.mkv` still accesses the same data.
    - The data is only deleted when *all hard links* are removed.
  ]
]

#slide[
  == Names, iNodes and Data
  how the file system finds the contents of `Movies/the_odyssey.mkv`

  #ascii-art[```
   Movies/ (directory data)         inode 507                   data blocks
  ┌─────────────────┬───────┐     ┌────────────────────┐      ┌────┬────┬────┐
  │ name            │ inode │     │ type:   file       │      │ 12 │ 13 │ 14 │
  ├─────────────────┼───────┤     │ links:  1          │      └────┴────┴────┘
  │ .               │   500 │     │ size:   4.2 GB     │         ▲
  │ ..              │   100 │     │ owner:  alice      │         │
  │ the_odyssey.mkv │   507 ├────▶│ blocks: 12 13 14   ├─────────┘
  └─────────────────┴───────┘     └────────────────────┘
  ```]

  #set text(size: 12.5pt)
  #uncover("2-")[① the *directory* maps a *name* to an *inode number*]\
  #uncover("3-")[② the *inode* keeps everything about the file, *except its name*]\
  #uncover("4-")[③ the *data blocks* keep the contents]\
  #uncover("5-")[💡 a _link_ is just one more way to reach an inode]
]

#slide[
  == ⚓ Hard Link - step by step

  #reveal-terminal(before: none, lines: (1, 2, 3), full: false)[```terminal
  $ ln the_odyssey.mkv favorite.mkv
  $ rm the_odyssey.mkv
  $ rm favorite.mkv
  ```]

  #only(1)[#ascii-art[```
   Movies/                            inode 507
  ┌─────────────────┬───────┐       ┌────────────────────┐      ┌────┬────┬────┐
  │ the_odyssey.mkv │   507 ├───┬──▶│ links:  2          ├─────▶│ 12 │ 13 │ 14 │
  │ favorite.mkv    │   507 ├───┘   │ size:   4.2 GB     │      └────┴────┴────┘
  └─────────────────┴───────┘       └────────────────────┘
  ```]]
  #only(2)[#ascii-art[```
   Movies/                            inode 507
  ┌─────────────────┬───────┐       ┌────────────────────┐      ┌────┬────┬────┐
  │ favorite.mkv    │   507 ├──────▶│ links:  1          ├─────▶│ 12 │ 13 │ 14 │
  └─────────────────┴───────┘       │ size:   4.2 GB     │      └────┴────┴────┘
                                    └────────────────────┘
  ```]]
  #only("3-")[#ascii-art[```
   Movies/                            inode 507
  ┌─────────────────┬───────┐       ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐      ┌╌╌╌╌┬╌╌╌╌┬╌╌╌╌┐
  │ (empty)         │       │       ╎ links:  0  → free  ╎      ╎ 12 ╎ 13 ╎ 14 ╎ free
  └─────────────────┴───────┘       └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘      └╌╌╌╌┴╌╌╌╌┴╌╌╌╌┘
  ```]]

  #set text(size: 12.5pt)
  #only(1)[a *second name* for the *same inode*, the inode counts its names: `links: 2`]
  #only(2)[`rm` deletes a *name*, the data is still reachable through `favorite.mkv`]
  #only("3-")[the last name is gone (`links: 0`), now the inode and the blocks are *free*]
]

#slide[
  == 🔗 Symbolic Link - step by step

  #reveal-terminal(before: none, lines: (1, 3, 4, 6), full: false)[```terminal
  $ ln -s the_odyssey.mkv tonight.mkv
  $ wc -c tonight.mkv
  4509715660 tonight.mkv
  $ rm the_odyssey.mkv
  $ wc -c tonight.mkv
  wc: tonight.mkv: No such file or directory
  ```]

  #only(1)[#ascii-art[```
   Movies/                            inode 548
  ┌─────────────────┬───────┐       ┌──────────────────────────┐
  │ the_odyssey.mkv │   507 │       │ type:  symbolic link     │
  │ tonight.mkv     │   548 ├──────▶│ data:  "the_odyssey.mkv" │  ← a path, not an inode
  └─────────────────┴───────┘       └──────────────────────────┘
  ```]]
  #only(2)[#ascii-art[```
  tonight.mkv ──▶ inode 548 ──▶ "the_odyssey.mkv" ──▶ inode 507 ──▶ blocks 12 13 14
     (name)        (link)          (look up again)       (file)         (contents)
  ```]]
  #only(3)[#ascii-art[```
   Movies/                            inode 548
  ┌─────────────────┬───────┐       ┌──────────────────────────┐
  │ tonight.mkv     │   548 ├──────▶│ data:  "the_odyssey.mkv" ├──▶ ✗ no such name
  └─────────────────┴───────┘       └──────────────────────────┘
  ```]]
  #only("4-")[#ascii-art[```
  tonight.mkv ──▶ inode 548 ──▶ "the_odyssey.mkv" ──▶ ✗ not found
  ```]]

  #set text(size: 12.5pt)
  #only(1)[a *new small file* (its own inode) that keeps the *path* of the target]
  #only(2)[opening the link *follows the path*, like typing `the_odyssey.mkv` yourself]
  #only(3)[deleting the target does *not* touch the link]
  #only("4-")[the link is now _broken_ (dangling), it points to a name that does not exist]
]

#slide[
  == Hard Link vs Symbolic Link

  #table(
    columns: (auto, 1fr, 1fr),
    table.header([], [⚓ Hard Link (`ln`)], [🔗 Symbolic Link (`ln -s`)]),
    [creates], [a new *name* in a directory], [a new small *file* that keeps a *path*],
    [inode], [the *same* as the target], [a *new* one],
    [`ls -l`], [the link count grows: `2`], [type `l`, `tonight.mkv -> the_odyssey.mkv`],
    [target deleted], [✅ the data is still there], [❌ the link is broken],
    [directories], [❌ not allowed], [✅ allowed],
    [other partitions], [❌ inode numbers are per partition], [✅ it is just a path],
  )
]

#slide[
  == Read, Write, Execute

  Each file or directory has three types of permissions:

  #set text(size: 0.9em)
  #table(
    columns: (auto, auto, auto, 1fr, 1fr),
    align: (center, center, left, left, left),
    table.header([Symbol], [🔢 Octal], [Meaning], [🧾 For Files], [📁 For Directories]),
    [`r`], [4], [📖 Read], [View file contents], [List files inside the directory],
    [`w`], [2], [✏️ Write], [Modify or delete the file], [Create, delete or rename files inside],
    [`x`], [1], [⚙️ Execute], [Run the file (if executable)], [Enter the directory (`cd`) and access contents],
  )

  Example

  #reveal-terminal(before: none, lines: (1, 2, 3), full: false)[```terminal
  $ ls -l
  drwxr-xr-x  2 alice alice 4096 Sep 26 21:15 Movies
  -rw-r--r--  1 alice alice  214 Sep 28 21:40 watchlist.txt
  ```]
]

#slide[
  == Read, Write, Execute for ...
  to whom do these apply

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (auto, 1fr),
      table.header([Group], [Applies To]),
      [*u*], [👤 User (owner)],
      [*g*], [👥 Group],
      [*o*], [🌍 Others (everyone else)],
    )

    === Rules

    #uncover("2-")[- each 📄 file has an 👤 owner]
    #uncover("3-")[- each 📄 file belongs to a 👥 group]
    #uncover("4-")[- there are *other* users that are not the owner of the file and do not belong to the file's group]
  ][
    #align(center)[
      #box(fill: white, inset: 5pt, radius: 0.3em)[#image("img/permissions/permissions.png", width: 100%)]
    ]
  ]
]
