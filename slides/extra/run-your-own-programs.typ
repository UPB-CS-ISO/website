#import "/src/slides.typ": *

// Running a program from the current directory and adding a directory to
// PATH. Written for 4. Command Line Interface (section Running a Command,
// after the `PATH` slide) and kept here for a future lecture.

#slide[
  == Run Your Own Programs
  The current directory is *not* in `PATH`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (4, 6, 10), full: false)[```terminal
    $ ls
    hello
    $ hello
    bash: hello: command not found
    $ ./hello                         # a path: no search
    Hello!
    $ mkdir -p ~/bin && mv hello ~/bin
    $ export PATH="$HOME/bin:$PATH"   # prepend ~/bin
    $ hello
    Hello!
    ```]
  ][
    #set text(size: 0.9em)
    #only(1)[💡 `hello` is in the current directory, but `.` is not one of the directories of `PATH`]
    #only(2)[💡 `./hello` is a path, the shell runs exactly that file]
    #only("3-")[
      💡 `"$HOME/bin:$PATH"` - the new directory, `:`, the old value

      💡 add the `export` to `~/.bashrc` to keep it
    ]
  ]

  #set text(size: 0.9em)
  #uncover("4-")[⚠️ `PATH=$HOME/bin` *replaces* the list: `ls` becomes `command not found`]

  #uncover("5-")[🔒 `.` is not in `PATH` on purpose: a malicious `ls` file in a downloaded folder would run instead of `/usr/bin/ls`]
]
