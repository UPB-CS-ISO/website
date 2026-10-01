#import "/src/slides.typ": *
#import "diagram.typ": *

#slide[
  = Navigation #text(size: 10pt, weight: "regular")[\ `pwd`, `cd`, `ls`, `tree` and `find`]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.3.1 - `ls`
      - Section 2.4.1 - `cd`
      - Section 2.5.3 - `pwd`
      - Section 2.5.6 - `find`
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.3.1 - _Afișarea și schimbarea directorului curent_
      - Section 2.3.2 - _Listarea fișierelor_
]

#slide[
  == `pwd`
  Print Working Directory - 📍
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    Shows the *absolute path* of your *current directory*

    ```terminal
    $ pwd
    ```

    #v(0.5em)

    ```
    [alice@computer: ~/Movies] $ pwd
    /home/alice/Movies
    ```

    #uncover("2-")[
      🤔 mind the prompt `[alice@computer: ~/Movies] $`\
      it already shows the current directory
    ]
  ][
    #fs-tree(
      here: (1, 2, 3, 4),
      cwd: 4,
      caption: [`pwd` prints the path from `/` to #fs-cwd-mark],
      ```
      /
      └── home
          └── alice
              ├── Movies
              └── Downloads
      ```,
    )
  ]
]

#let cd-tree(at, caption) = fs-tree(here: (at,), cwd: at, caption: caption, ```
  /
  └── home
      └── alice
          ├── Movies
          └── Downloads
  ```)

#slide[
  == `cd`
  📁 Change (Current) Directory

    ```terminal
    $ cd [directory]    # `[directory]` means that the `directory` parameter is optional
    ```

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (1, 2, 4, 6, 7, 8), full: false)[```terminal
    $ cd /home/alice/Downloads  # absolute path
    $ cd ../Movies              # relative path
    $ cd -                      # previous directory
    /home/alice/Downloads
    $ cd -
    /home/alice/Movies
    $ cd ~                      # home directory
    $ cd                        # home directory
    ```]

    #uncover("3-")[🔁 `cd -` goes where you were *before* the last `cd`]

    #uncover("4-")[⚠️ `cd -` is *not* "back": it switches between two directories]
  ][
    #only(1)[#cd-tree(5, [absolute: start from `/`, go down])]
    #only(2)[#cd-tree(4, [`..` goes up to `alice`, then into `Movies`])]
    #only(3)[#cd-tree(5, [`cd -` goes to `Downloads`, where we were\ before, and prints its path])]
    #only(4)[#cd-tree(4, [`cd -` again goes to `Movies`,\ not to the directory before `Downloads`])]
    #only(5)[#cd-tree(3, [`~` is the home directory of the user,\ `/home/alice`])]
    #only("6-")[#cd-tree(3, [no parameter, go to the home directory])]
  ]
]

#slide[
  == `ls`
  📂 Listing Files and Directories

  ```terminal
  $ ls [options] [directory]
  ```

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (2, 4, 6, 10, 14), full: false)[```terminal
    $ ls
    Downloads  Movies  watchlist.txt
    $ ls Movies
    the_odyssey.mkv
    $ ls -a
    .  ..  .bashrc  Downloads  Movies  watchlist.txt
    $ ls -l
    drwxr-xr-x  2 alice alice  4096 Sep 20 18:02 Downloads
    drwxr-xr-x  2 alice alice  4096 Sep 26 21:15 Movies
    -rw-r--r--  1 alice alice 21504 Sep 28 21:40 watchlist.txt
    $ ls -lh
    drwxr-xr-x  2 alice alice 4.0K Sep 20 18:02 Downloads
    drwxr-xr-x  2 alice alice 4.0K Sep 26 21:15 Movies
    -rw-r--r--  1 alice alice  21K Sep 28 21:40 watchlist.txt
    ```]
  ][
    #let tree = ```
    ~ (/home/alice)
    ├── .bashrc
    ├── Downloads
    ├── Movies
    │   └── the_odyssey.mkv
    └── watchlist.txt
    ```
    #only(1)[#fs-tree(here: (3, 4, 6), cwd: 1, caption: [only the entries of the directory,\ not what is inside `Movies`], tree)]
    #only(2)[#fs-tree(here: (4, 5), cwd: 1, caption: [a directory as parameter:\ list what is _inside_ `Movies`], tree)]
    #only(3)[#fs-tree(here: (2, 3, 4, 6), cwd: 1, caption: [names starting with `.` are _hidden_], tree)]
    // the same tree with the type letter that `ls -l` prints for every entry it lists
    #let typed-tree = ```
    ~ (/home/alice)
    ├── .bashrc
    ├── Downloads        d
    ├── Movies           d
    │   └── the_odyssey.mkv
    └── watchlist.txt    -
    ```
    #only(4)[#fs-tree(here: (3, 4, 6), cwd: 1, caption: [1#super[st] letter: `d` directory, `-` file\ then permissions, owner, size, date], typed-tree)]
    #only("5-")[#fs-tree(here: (3, 4, 6), cwd: 1, caption: [sizes in `K`, `M`, `G` instead of bytes], typed-tree)]

    #item-by-item(start: 3)[
    - `-a` - include hidden files (_`.` files_)
    - `-l` - long listing
    - `-h` - human-readable sizes (with `-l`)
    ]
  ]
]

#slide[
  == `tree`
  🌳 List a Directory and Everything Inside

  ```terminal
  $ tree [options] [directory]
  ```

  // every step: the command and what it prints, in /home/alice
  #let tree-steps = (
    ```terminal
    $ tree
    .
    ├── Downloads
    │   └── supergirl.mp4
    ├── Movies
    │   └── the_odyssey.mkv
    └── watchlist.txt

    2 directories, 3 files
    ```,
    ```terminal
    $ tree Movies
    Movies
    └── the_odyssey.mkv

    0 directories, 1 file
    ```,
    ```terminal
    $ tree -L 1
    .
    ├── Downloads
    ├── Movies
    └── watchlist.txt

    2 directories, 1 file
    ```,
    ```terminal
    $ tree -d
    .
    ├── Downloads
    └── Movies

    2 directories
    ```,
    ```terminal
    $ tree -a -L 1
    .
    ├── .bashrc
    ├── Downloads
    ├── Movies
    └── watchlist.txt

    2 directories, 2 files
    ```,
  )

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (i, step) in tree-steps.enumerate() {
      let frames = if i == tree-steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }
      only(frames, step)
    }
  ][
    `ls` lists _one_ directory, `tree` also goes *inside* every directory

    #uncover("2-")[`Movies` - only what is inside this directory]

    #uncover("3-")[`-L 1` - only 1 level deep]

    #uncover("4-")[`-d` - only directories]

    #uncover("5-")[`-a` - include hidden files]

  ]

  #align(bottom)[
    #text(size: 0.8em)[📦 not installed by default? Ubuntu: `sudo apt install tree` #h(1em) Fedora: `sudo dnf install tree`]
  ]
]

#slide[
  == `find`
  🔍 Search for Files and Directories

  ```terminal
  $ find [directory...] [conditions]
  ```

  // every step: the command and what it prints, in /home/alice
  #let find-steps = (
    ```terminal
    $ find Movies
    Movies
    Movies/the_odyssey.mkv
    ```,
    ```terminal
    $ find . -name "*.mkv"
    ./Movies/the_odyssey.mkv
    ```,
    ```terminal
    $ find . -type d
    .
    ./Downloads
    ./Movies
    ```,
    ```terminal
    $ find ~ -name watchlist.txt
    /home/alice/watchlist.txt
    ```,
  )

  #let tree = ```
  ~ (/home/alice)
  ├── Downloads
  │   └── supergirl.mp4
  ├── Movies
  │   └── the_odyssey.mkv
  └── watchlist.txt
  ```

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (i, step) in find-steps.enumerate() {
      let frames = if i == find-steps.len() - 1 { str(i + 1) + "-" } else { i + 1 }
      only(frames, step)
    }

    #uncover("2-")[`-name` - by name, `*` means _any characters_]

    #uncover("3-")[`-type d` - only directories, `-type f` - only files]

    #uncover("4-")[every result is a path that starts with the directory you gave]
  ][
    #only(1)[#fs-tree(here: (4, 5), cwd: 1, caption: [the directory and everything inside it], tree)]
    #only(2)[#fs-tree(here: (5,), cwd: 1, caption: [search all of `.`, keep the names\ that end with `.mkv`], tree)]
    #only(3)[#fs-tree(here: (1, 2, 4), cwd: 1, caption: [only the directories], tree)]
    #only("4-")[#fs-tree(here: (6,), cwd: 1, caption: [start from an absolute path,\ get absolute paths], tree)]
  ]
]
