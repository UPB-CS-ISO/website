#import "/src/slides.typ": *
#import "diagram.typ": *
#import "params.typ": *

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

  #let c = param-colors
  #let cd-synopsis = "$ cd [directory]    # `[directory]` means that the `directory` parameter is optional"
  #let cd-commands = "$ cd /home/alice/Downloads  # absolute path
$ cd ../Movies              # relative path
$ cd -                      # previous directory
/home/alice/Downloads
$ cd -
/home/alice/Movies
$ cd ~                      # home directory
$ cd                        # home directory"
  // every step: the visible lines, the current command and its directory
  #let cd-steps = (
    (shown: 1, line: 1, dir: "/home/alice/Downloads"),
    (shown: 2, line: 2, dir: "../Movies"),
    (shown: 4, line: 3, dir: "-"),
    (shown: 6, line: 5, dir: "-"),
    (shown: 7, line: 7, dir: "~"),
    (shown: 8, line: 8, dir: none),
  )

  #for (k, st) in cd-steps.enumerate() {
    synopsis-step(cd-steps, k, marked-terminal(cd-synopsis,
      marks: if st.dir == none { (:) } else { ("1": (("[directory]", c.path),)) }))
  }

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in cd-steps.enumerate() {
      synopsis-step(cd-steps, k, marked-terminal(cd-commands, shown: st.shown,
        marks: if st.dir == none { (:) } else { (str(st.line): ((st.dir, c.path),)) }))
    }

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

  #let c = param-colors
  #let ls-synopsis = "$ ls [option]... [file]..."
  #let ls-commands = "$ ls
Downloads  Movies  watchlist.txt
$ ls watchlist.txt Movies
watchlist.txt

Movies:
the_odyssey.mkv
$ ls -a
.  ..  .bashrc  Downloads  Movies  watchlist.txt
$ ls -l -h ~
drwxr-xr-x  2 alice alice 4.0K Sep 20 18:02 Downloads
drwxr-xr-x  2 alice alice 4.0K Sep 26 21:15 Movies
-rw-r--r--  1 alice alice  21K Sep 28 21:40 watchlist.txt"
  // every step: the visible lines, the current command, its parameters and
  // the matching parts of the synopsis
  #let ls-steps = (
    (shown: 2, line: 1, marks: (), synopsis: ()),
    (shown: 7, line: 3, marks: (("watchlist.txt", c.path), ("Movies", c.path)), synopsis: (("[file]...", c.path),)),
    (shown: 9, line: 8, marks: (("-a", c.option),), synopsis: (("[option]...", c.option),)),
    (shown: 13, line: 10, marks: (("-l", c.option), ("-h", c.option), ("~", c.path)), synopsis: (("[option]...", c.option), ("[file]...", c.path))),
  )

  #for (k, st) in ls-steps.enumerate() {
    synopsis-step(ls-steps, k, marked-terminal(ls-synopsis, marks: ("1": st.synopsis)))
  }

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in ls-steps.enumerate() {
      synopsis-step(ls-steps, k, marked-terminal(ls-commands, shown: st.shown, marks: (str(st.line): st.marks)))
    }
  ][
    #let tree = ```
    ~ (/home/alice)
    ├── .bashrc
    ├── Downloads
    │   └── supergirl.mp4
    ├── Movies
    │   └── the_odyssey.mkv
    └── watchlist.txt
    ```
    #only(1)[#fs-tree(here: (3, 5, 7), cwd: 1, caption: [only the entries of the directory,\ not what is inside `Movies`], tree)]
    #only(2)[#fs-tree(here: (5, 6, 7), cwd: 1, caption: [a file is listed by its name,\ a directory by what is _inside_ it], tree)]
    #only(3)[#fs-tree(here: (2, 3, 5, 7), cwd: 1, caption: [names starting with `.` are _hidden_], tree)]
    // the same tree with the type letter that `ls -l` prints for every entry it lists
    #let typed-tree = ```
    ~ (/home/alice)
    ├── .bashrc
    ├── Downloads        d
    │   └── supergirl.mp4
    ├── Movies           d
    │   └── the_odyssey.mkv
    └── watchlist.txt    -
    ```
    #only("4-")[#fs-tree(here: (3, 5, 7), cwd: 1, caption: [1#super[st] letter: `d` directory, `-` file,\ sizes in `K`, `M`, `G` instead of bytes], typed-tree)]

    #uncover("3-")[`-a` - include hidden files (_`.` files_)]

    #uncover("4-")[`-l` - long listing, `-h` - human-readable sizes]

    #uncover("4-")[💡 `ls -l -h ~` is the same as `ls -lh ~`]
  ]
]

#slide[
  == `tree`
  🌳 List a Directory and Everything Inside

  #let c = param-colors
  #let tree-synopsis = "$ tree [option]... [directory]..."
  // every step: the command and what it prints, in /home/alice, its parameters
  // and the matching parts of the synopsis
  #let tree-steps = (
    (
      text: "$ tree
.
├── Downloads
│   └── supergirl.mp4
├── Movies
│   └── the_odyssey.mkv
└── watchlist.txt

3 directories, 3 files",
      marks: (),
      synopsis: (),
    ),
    (
      text: "$ tree Movies Downloads
Movies
└── the_odyssey.mkv
Downloads
└── supergirl.mp4

2 directories, 2 files",
      marks: (("Movies", c.path), ("Downloads", c.path)),
      synopsis: (("[directory]...", c.path),),
    ),
    (
      text: "$ tree -L 1
.
├── Downloads
├── Movies
└── watchlist.txt

3 directories, 1 file",
      marks: (("-L 1", c.option),),
      synopsis: (("[option]...", c.option),),
    ),
    (
      text: "$ tree -d
.
├── Downloads
└── Movies

3 directories",
      marks: (("-d", c.option),),
      synopsis: (("[option]...", c.option),),
    ),
    (
      text: "$ tree -a -L 1 ~
/home/alice
├── .bashrc
├── Downloads
├── Movies
└── watchlist.txt

3 directories, 2 files",
      marks: (("-a", c.option), ("-L 1", c.option), ("~", c.path)),
      synopsis: (("[option]...", c.option), ("[directory]...", c.path)),
    ),
  )

  #for (k, st) in tree-steps.enumerate() {
    synopsis-step(tree-steps, k, marked-terminal(tree-synopsis, marks: ("1": st.synopsis)))
  }

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in tree-steps.enumerate() {
      synopsis-step(tree-steps, k, marked-terminal(st.text, marks: ("1": st.marks)))
    }
  ][
    `ls` lists _one_ directory, `tree` also goes *inside* every directory

    #uncover("2-")[`Movies Downloads` - only what is inside these directories]

    #uncover("3-")[`-L 1` - only 1 level deep]

    #uncover("4-")[`-d` - only directories]

    #uncover("5-")[`-a` - include hidden files, `~` - list the home directory]

  ]

  #align(bottom)[
    #text(size: 0.8em)[📦 not installed by default? Ubuntu: `sudo apt install tree` #h(1em) Fedora: `sudo dnf install tree`]
  ]
]

#slide[
  == `find`
  🔍 Search for Files and Directories

  #let c = param-colors
  #let find-synopsis = "$ find [directory]... [filter]..."
  // every step: the command and what it prints, in /home/alice, its parameters
  // and the matching parts of the synopsis
  #let find-steps = (
    (
      text: "$ find Movies
Movies
Movies/the_odyssey.mkv",
      marks: (("Movies", c.path),),
      synopsis: (("[directory]...", c.path),),
    ),
    (
      text: "$ find . -name \"*.mkv\"
./Movies/the_odyssey.mkv",
      marks: ((".", c.path), ("-name \"*.mkv\"", c.filter)),
      synopsis: (("[directory]...", c.path), ("[filter]...", c.filter)),
    ),
    (
      text: "$ find Movies Downloads -type f
Movies/the_odyssey.mkv
Downloads/supergirl.mp4",
      marks: (("Movies", c.path), ("Downloads", c.path), ("-type f", c.filter)),
      synopsis: (("[directory]...", c.path), ("[filter]...", c.filter)),
    ),
    (
      text: "$ find ~ -type f -name \"*.txt\"
/home/alice/watchlist.txt",
      marks: (("~", c.path), ("-type f", c.filter), ("-name \"*.txt\"", c.filter)),
      synopsis: (("[directory]...", c.path), ("[filter]...", c.filter)),
    ),
  )

  #for (k, st) in find-steps.enumerate() {
    synopsis-step(find-steps, k, marked-terminal(find-synopsis, marks: ("1": st.synopsis)))
  }

  #let tree = ```
  ~ (/home/alice)
  ├── Downloads
  │   └── supergirl.mp4
  ├── Movies
  │   └── the_odyssey.mkv
  └── watchlist.txt
  ```

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in find-steps.enumerate() {
      synopsis-step(find-steps, k, marked-terminal(st.text, marks: ("1": st.marks)))
    }

    #uncover("2-")[`-name` - by name, `*` means _any characters_]

    #uncover("3-")[`-type f` - only files, `-type d` - only directories]

    #uncover("4-")[several filters: a result must match *all* of them]
  ][
    #only(1)[#fs-tree(here: (4, 5), cwd: 1, caption: [the directory and everything inside it], tree)]
    #only(2)[#fs-tree(here: (5,), cwd: 1, caption: [search all of `.`, keep the names\ that end with `.mkv`], tree)]
    #only(3)[#fs-tree(here: (3, 5), cwd: 1, caption: [only the files, in both directories], tree)]
    #only("4-")[#fs-tree(here: (6,), cwd: 1, caption: [start from an absolute path,\ get absolute paths], tree)]
  ]
]
