#import "/src/slides.typ": *
#import "diagram.typ": *
#import "params.typ": *

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

  #let c = param-colors
  #let cp-synopsis = "$ cp [option]... source destination_file_or_directory
$ cp [option]... source... destination_directory"
  #let cp-commands = "$ cp watchlist.txt /home/alice/backup/
$ cp Movies/the_odyssey.mkv Movies/toy_story_5.mkv backup/
$ cp -r Movies/ /home/alice/backup/"
  // every step: the parameters of the current command and the matching parts
  // of the synopsis (line -> marks)
  #let cp-steps = (
    (
      marks: (("watchlist.txt", c.source), ("/home/alice/backup/", c.dest)),
      synopsis: ("1": (("source", c.source), ("destination_file_or_directory", c.dest))),
    ),
    (
      marks: (("Movies/the_odyssey.mkv", c.source), ("Movies/toy_story_5.mkv", c.source), ("backup/", c.dest)),
      synopsis: ("2": (("source...", c.source), ("destination_directory", c.dest))),
    ),
    (
      marks: (("-r", c.option), ("Movies/", c.source), ("/home/alice/backup/", c.dest)),
      synopsis: ("1": (("[option]...", c.option), ("source", c.source), ("destination_file_or_directory", c.dest))),
    ),
  )

  #for (k, st) in cp-steps.enumerate() {
    synopsis-step(cp-steps, k, marked-terminal(cp-synopsis, marks: st.synopsis))
  }

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    // smaller, so the command with two sources fits on one line
    #text(size: 0.85em)[#for (k, st) in cp-steps.enumerate() {
      synopsis-step(cp-steps, k, marked-terminal(cp-commands, shown: k + 1, marks: (str(k + 1): st.marks)))
    }]

    #uncover("3-")[💡 without `-r`, `cp` refuses to copy directories]

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
      caption: [copy a file into a directory],
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
      caption: [several sources: the *last* parameter\ must be a *directory*],
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
      caption: [`-r` copies the directory and everything inside],
    )]
  ]
]

#slide[
  == `mv`
  📦 Move or Rename Files

  #let c = param-colors
  #let mv-synopsis = "$ mv [option]... source destination
$ mv [option]... source... destination_directory"
  #let mv-commands = "$ mv movie.mkv project_hail_mary.mkv
$ mv project_hail_mary.mkv Movies/
$ mv supergirl.mp4 michael.mp4 Movies/
$ mv Movies/ Movies_2026/"
  #let one = (("source", c.source), ("destination", c.dest))
  #let mv-steps = (
    (marks: (("movie.mkv", c.source), ("project_hail_mary.mkv", c.dest)), synopsis: ("1": one)),
    (marks: (("project_hail_mary.mkv", c.source), ("Movies/", c.dest)), synopsis: ("1": one)),
    (
      marks: (("supergirl.mp4", c.source), ("michael.mp4", c.source), ("Movies/", c.dest)),
      synopsis: ("2": (("source...", c.source), ("destination_directory", c.dest))),
    ),
    (marks: (("Movies/", c.source), ("Movies_2026/", c.dest)), synopsis: ("1": one)),
  )

  #for (k, st) in mv-steps.enumerate() {
    synopsis-step(mv-steps, k, marked-terminal(mv-synopsis, marks: st.synopsis))
  }

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #for (k, st) in mv-steps.enumerate() {
      synopsis-step(mv-steps, k, marked-terminal(mv-commands, shown: k + 1, marks: (str(k + 1): st.marks)))
    }

    💡 renaming is moving to a new name in the same directory

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
      caption: [move a file to a directory],
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
      caption: [move several files to a directory],
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
      caption: [rename a directory, the contents stay inside],
    )]
  ]
]

#slide[
  == `mkdir`
  📁 Create Directories

  #let c = param-colors
  #let mkdir-synopsis = "$ mkdir [option]... directory..."
  #let mkdir-commands = "$ mkdir Movies
$ mkdir -p Movies/2026/animation"
  #let mkdir-steps = (
    (marks: (("Movies", c.path),), synopsis: (("directory...", c.path),)),
    (
      marks: (("-p", c.option), ("Movies/2026/animation", c.path)),
      synopsis: (("[option]...", c.option), ("directory...", c.path)),
    ),
  )

  #for (k, st) in mkdir-steps.enumerate() {
    synopsis-step(mkdir-steps, k, marked-terminal(mkdir-synopsis, marks: ("1": st.synopsis)))
  }

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in mkdir-steps.enumerate() {
      synopsis-step(mkdir-steps, k, marked-terminal(mkdir-commands, shown: k + 1, marks: (str(k + 1): st.marks)))
    }

    #uncover("2-")[💡 `-p` also creates the missing _parent_ directories]

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
      caption: [make a directory],
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

  #let c = param-colors
  #let create-synopsis = "$ touch [option]... file...
$ nano [option]... [file]"
  #let create-commands = "$ touch notes.txt
$ ls -l notes.txt
-rw-r--r-- 1 alice alice 0 Sep 30 14:20 notes.txt
$ nano todo.txt"
  // `ls -l` only shows the result of `touch`: nothing to highlight
  #let create-steps = (
    (shown: 1, line: 1, marks: (("notes.txt", c.path),), synopsis: ("1": (("file...", c.path),))),
    (shown: 3, line: 2, marks: (), synopsis: (:)),
    (shown: 4, line: 4, marks: (("todo.txt", c.path),), synopsis: ("2": (("[file]", c.path),))),
  )

  #for (k, st) in create-steps.enumerate() {
    synopsis-step(create-steps, k, marked-terminal(create-synopsis, marks: st.synopsis))
  }

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in create-steps.enumerate() {
      synopsis-step(create-steps, k, marked-terminal(create-commands, shown: st.shown, marks: (str(st.line): st.marks)))
    }

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

  #let c = param-colors
  #let rm-commands = "$ rm dune_3_teaser.mp4
$ rm trailer1.mp4 trailer2.mp4
$ rm -r Trailers/
$ rmdir Watched"
  // every step: the parameters of the current command and the matching parts
  // of the synopsis of `rm` and of `rmdir`
  #let rm-steps = (
    (marks: (("dune_3_teaser.mp4", c.path),), rm: (("file...", c.path),), rmdir: ()),
    (marks: (("trailer1.mp4", c.path), ("trailer2.mp4", c.path)), rm: (("file...", c.path),), rmdir: ()),
    (marks: (("-r", c.option), ("Trailers/", c.path)), rm: (("[option]...", c.option), ("file...", c.path)), rmdir: ()),
    (marks: (("Watched", c.path),), rm: (), rmdir: (("directory...", c.path),)),
  )

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    `rm` - deletes files or directories (⚠️ *destructive*!)
    #for (k, st) in rm-steps.enumerate() {
      synopsis-step(rm-steps, k, marked-terminal("$ rm [option]... file...", marks: ("1": st.rm)))
    }
  ][
    `rmdir` - deletes only *empty directories*
    #for (k, st) in rm-steps.enumerate() {
      synopsis-step(rm-steps, k, marked-terminal("$ rmdir [option]... directory...", marks: ("1": st.rmdir)))
    }
  ]

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #for (k, st) in rm-steps.enumerate() {
      synopsis-step(rm-steps, k, marked-terminal(rm-commands, shown: k + 1, marks: (str(k + 1): st.marks)))
    }

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
      caption: [`-r` deletes the directory and everything inside],
    )]
    #only("4-")[#fs-tree(
      cwd: 1,
      gone: (2,),
      ```
      /home/alice
      └── Watched/
      ```,
      caption: [delete an empty directory],
    )]
  ]
]
