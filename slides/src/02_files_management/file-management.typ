#import "/src/slides.typ": *
#import "diagram.typ": *

#slide[
  = File Management #text(size: 10pt, weight: "regular")[\ `cp`, `mv`, `mkdir`, `touch`, `nano`, `rmdir` and `rm`]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.3 - _Basic Commands_ (`cp`, `mv`, `touch`, `rm`)
      - Section 2.4 - _Navigating Directories_ (`mkdir`, `rmdir`)
      - Section 2.12 - _Text Editors_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.3.4 - _Crearea fișierelor/directoarelor_
      - Section 2.3.5 - _Copiere / mutare / redenumire / ștergere_
]

#slide[
  == `cp`
  📋 Copy Files and Directories

  ```terminal
  $ cp [options] source destination_file_or_folder
  $ cp [options] source... destination_folder
  ```

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    // smaller, so the command with two sources fits on one line
    #text(size: 0.85em)[#reveal-terminal(before: none, lines: (1, 2, 3), full: false)[```terminal
    $ cp watchlist.txt /home/alice/backup/
    $ cp Movies/the_odyssey.mkv Movies/toy_story_5.mkv backup/
    $ cp -r Movies/ /home/alice/backup/
    ```]]

    #uncover("3-")[💡 without `-r`, `cp` refuses to copy folders]

    the source is *not changed*, a new copy is created

    #fs-legend-source
  ][
    #set text(size: 0.85em)
    #only(1)[#fs-tree(
      cwd: 1,
      new: (7,),
      source: (2,),
      ```
      /home/alice
      ├── watchlist.txt
      ├── Movies/
      │   ├── the_odyssey.mkv
      │   └── toy_story_5.mkv
      └── backup/
          └── watchlist.txt
      ```,
      caption: [copy a file into a folder],
    )]
    #only(2)[#fs-tree(
      cwd: 1,
      new: (8, 9),
      source: (4, 5),
      ```
      /home/alice
      ├── watchlist.txt
      ├── Movies/
      │   ├── the_odyssey.mkv
      │   └── toy_story_5.mkv
      └── backup/
          ├── watchlist.txt
          ├── the_odyssey.mkv
          └── toy_story_5.mkv
      ```,
      caption: [several sources: the *last* parameter\ must be a *folder*],
    )]
    #only("3-")[#fs-tree(
      cwd: 1,
      new: (10, 11, 12),
      source: (3,),
      ```
      /home/alice
      ├── watchlist.txt
      ├── Movies/
      │   ├── the_odyssey.mkv
      │   └── toy_story_5.mkv
      └── backup/
          ├── watchlist.txt
          ├── the_odyssey.mkv
          ├── toy_story_5.mkv
          └── Movies/
              ├── the_odyssey.mkv
              └── toy_story_5.mkv
      ```,
      caption: [`-r` copies the folder and everything inside],
    )]
  ]
]

#slide[
  == `mv`
  📦 Move or Rename Files

  ```terminal
  $ mv [options] source destination
  $ mv [options] source... destination_folder
  ```

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #reveal-terminal(before: none, lines: (1, 2, 3, 4), full: false)[```terminal
    $ mv movie.mkv project_hail_mary.mkv
    $ mv project_hail_mary.mkv Movies/
    $ mv supergirl.mp4 michael.mp4 Movies/
    $ mv Movies/ Movies_2026/
    ```]

    💡 renaming is moving to a new name in the same folder

    #fs-legend
  ][
    #set text(size: 0.85em)
    #only(1)[#fs-tree(
      cwd: 1,
      gone: (2,),
      source: (2,),
      new: (3,),
      ```
      /home/alice
      ├── movie.mkv
      ├── project_hail_mary.mkv
      ├── supergirl.mp4
      ├── michael.mp4
      └── Movies/
          └── the_odyssey.mkv
      ```,
      caption: [rename a file],
    )]
    #only(2)[#fs-tree(
      cwd: 1,
      gone: (2,),
      source: (2,),
      new: (7,),
      ```
      /home/alice
      ├── project_hail_mary.mkv
      ├── supergirl.mp4
      ├── michael.mp4
      └── Movies/
          ├── the_odyssey.mkv
          └── project_hail_mary.mkv
      ```,
      caption: [move a file to a folder],
    )]
    #only(3)[#fs-tree(
      cwd: 1,
      gone: (2, 3),
      source: (2, 3),
      new: (7, 8),
      ```
      /home/alice
      ├── supergirl.mp4
      ├── michael.mp4
      └── Movies/
          ├── the_odyssey.mkv
          ├── project_hail_mary.mkv
          ├── supergirl.mp4
          └── michael.mp4
      ```,
      caption: [move several files to a folder],
    )]
    #only("4-")[#fs-tree(
      cwd: 1,
      gone: (2,),
      source: (2,),
      new: (3,),
      ```
      /home/alice
      ├── Movies/
      └── Movies_2026/
          ├── the_odyssey.mkv
          ├── project_hail_mary.mkv
          ├── supergirl.mp4
          └── michael.mp4
      ```,
      caption: [rename a folder, the contents stay inside],
    )]
  ]
]

#slide[
  == `mkdir`
  📁 Create Directories

  ```terminal
  $ mkdir [options] directory_name
  ```

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (1, 2), full: false)[```terminal
    $ mkdir Movies
    $ mkdir -p Movies/2026/animation
    ```]

    #uncover("2-")[💡 `-p` also creates the missing _parent_ folders]

    #fs-legend
  ][
    #only(1)[#fs-tree(
      cwd: 1,
      new: (2,),
      ```
      /home/alice
      ├── Movies/
      └── watchlist.txt
      ```,
      caption: [make a folder],
    )]
    #only("2-")[#fs-tree(
      cwd: 1,
      new: (3, 4),
      ```
      /home/alice
      ├── Movies/
      │   └── 2026/
      │       └── animation/
      └── watchlist.txt
      ```,
      caption: [`Movies/` exists, only `2026/animation/` is made],
    )]
  ]
]

#slide[
  == `touch` and `nano`
  📄 Create Files

  ```terminal
  $ touch [options] file...
  $ nano [options] [file]
  ```

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (1, 3, 4), full: false)[```terminal
    $ touch notes.txt
    $ ls -l notes.txt
    -rw-r--r-- 1 alice alice 0 Sep 30 14:20 notes.txt
    $ nano todo.txt
    ```]

    #only("-2")[💡 `touch` on a file that exists only updates its _date_]
    #only("3-")[
      ✏️ inside `nano`: #kbd("Ctrl") + #kbd("O") save, #kbd("Ctrl") + #kbd("X") exit
    ]

    #fs-legend
  ][
    #only(1)[#fs-tree(
      cwd: 1,
      new: (3,),
      ```
      /home/alice
      ├── Movies/
      ├── notes.txt
      └── watchlist.txt
      ```,
      caption: [`touch` makes an *empty* file],
    )]
    #only(2)[#fs-tree(
      cwd: 1,
      here: (3,),
      ```
      /home/alice
      ├── Movies/
      ├── notes.txt
      └── watchlist.txt
      ```,
      caption: [size `0`: there is nothing inside],
    )]
    #only("3-")[#fs-tree(
      cwd: 1,
      new: (4,),
      ```
      /home/alice
      ├── Movies/
      ├── notes.txt
      ├── todo.txt
      └── watchlist.txt
      ```,
      caption: [`nano` opens a text editor,\ the file is made when you *save*],
    )]
  ]
]

#slide[
  == `rm` and `rmdir`
  🗑️ Remove Files and Directories

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    `rm` – deletes files or directories (⚠️ *destructive*!)
    ```terminal
    $ rm [options] file_name
    ```
  ][
    `rmdir` – deletes only *empty directories*
    ```terminal
    $ rmdir [options] directory_name
    ```
  ]

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (1, 2, 3, 4), full: false)[```terminal
    $ rm dune_3_teaser.mp4
    $ rm trailer1.mp4 trailer2.mp4
    $ rm -r Trailers/
    $ rmdir Watched
    ```]

    #uncover("3-")[💡 `rmdir Trailers` fails, `Trailers` is not empty]

    #uncover("5-")[⚠️ there is no _trash_, deleting is *permanent*!]

    #fs-legend
  ][
    #set text(size: 0.85em)
    #only(1)[#fs-tree(
      cwd: 1,
      gone: (2,),
      ```
      /home/alice
      ├── dune_3_teaser.mp4
      ├── trailer1.mp4
      ├── trailer2.mp4
      ├── Trailers/
      │   ├── avatar_fire_and_ash.mp4
      │   └── the_odyssey.mp4
      └── Watched/
      ```,
      caption: [delete a file],
    )]
    #only(2)[#fs-tree(
      cwd: 1,
      gone: (2, 3),
      ```
      /home/alice
      ├── trailer1.mp4
      ├── trailer2.mp4
      ├── Trailers/
      │   ├── avatar_fire_and_ash.mp4
      │   └── the_odyssey.mp4
      └── Watched/
      ```,
      caption: [delete several files],
    )]
    #only(3)[#fs-tree(
      cwd: 1,
      gone: (2, 3, 4),
      ```
      /home/alice
      ├── Trailers/
      │   ├── avatar_fire_and_ash.mp4
      │   └── the_odyssey.mp4
      └── Watched/
      ```,
      caption: [`-r` deletes the folder and everything inside],
    )]
    #only("4-")[#fs-tree(
      cwd: 1,
      gone: (2,),
      ```
      /home/alice
      └── Watched/
      ```,
      caption: [delete an empty folder],
    )]
  ]
]
