#import "/src/slides.typ": *
#import "common.typ": *

#set raw(tab-size: 4)

// ---------------------------------------------------------------------------
// What is make
// ---------------------------------------------------------------------------

#slide[
  = Building with `make` #text(size: 10pt, weight: "regular")[\ _Automate the build: run only the commands that are needed_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 15 - _Development Tools_
      - Section 15.2 - _make_
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.6.7 - _Automatizarea procesului de dezvoltare_
      - Section 6.7.1 - _Automatizarea compilării în C/C++_
  + #make-manual
    - Chapter 2 - _An Introduction to Makefiles_
    - Chapter 10 - _Using Implicit Rules_ (pattern rules, automatic variables)
]

#slide[
  == What Is `make`?
  A tool that _automates_ the build

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    - written in 1976 at Bell Labs, by Stuart Feldman; Linux uses *GNU Make*
    - reads a `Makefile` from the current directory
    - a `Makefile` says, for every file
      - what it is *built from*
      - *which commands* build it
    - `make` looks at the *modification time* of the files and runs only the commands that are needed
    - not only for C: the slides of this course are built with a `Makefile`
  ][
    #v(1em)
    #align(center, flow(
      stack(spacing: 0.6em, file-box("Makefile", sub: [the rules]), file-box("main.c ...", sub: [the files, with times])),
      tool-box("make", sub: [what is older?]),
      stack(spacing: 0.3em, text(font: mono, size: 0.65em)[gcc -c print.c], text(font: mono, size: 0.65em)[gcc ... -o app]),
    ))
  ]
]

// ---------------------------------------------------------------------------
// The syntax, with hello.c
// ---------------------------------------------------------------------------

// a rule in a box, the target orange, the prerequisites blue, then the
// recipe: one line per command, each starting with a TAB (marked)
#let rule-box(target, prerequisites, ..commands) = box(fill: luma(240), radius: 0.3em, inset: 0.8em, align(left, text(font: mono, size: 0.95em, {
  [#text(fill: changed, target): #text(fill: accent, prerequisites)]
  for cmd in commands.pos() {
    linebreak()
    box(fill: luma(200), inset: (x: 2pt), radius: 2pt, text(size: 0.7em)[TAB])
    h(0.5em)
    cmd
  }
})))

#slide[
  == A Rule
  A `Makefile` is a list of rules

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #rule-box[target][prerequisites][command 1][command 2][...]
    #v(1em)
    #uncover("2-", rule-box[hello][hello.c][#highlight-shell("gcc -c hello.c")][#highlight-shell("gcc hello.o -o hello")])
  ][
    - #text(fill: changed)[*target*]: the file to build
    - #text(fill: accent)[*prerequisites*]: the files it is built from
    - *recipe*: the commands that build it, one per line, each starting with a TAB
    #v(1em)
    #uncover("2-", block(
      width: 100%,
      fill: luma(248),
      stroke: 0.8pt + luma(190),
      radius: 0.4em,
      inset: 0.7em,
      {
        set par(leading: 0.8em)
        set text(size: 0.9em)
        [for example: #h(0.3em)]
        tok("target", "hello")
        [#h(0.3em) is built from #h(0.3em)]
        tok("dep", "hello.c")
        [#h(0.3em) with *two* commands, run in order]
      },
    ))
  ]

  // the TAB pitfall, over the slide: nothing moves when it appears
  #only("3-")[
    #place(bottom + right, dy: -0.3em, popup(width: 300pt, color: bad-color)[
      ⚠️ The recipe starts with a TAB, not with spaces
    ][
      // the 4 spaces drawn as dots, so they can be seen
      #let dots = text(fill: bad-color, weight: "bold")[····]
      #block(fill: luma(240), radius: 0.3em, inset: 0.5em, width: 100%, text(font: mono, size: 0.9em)[
        hello.o: hello.c \
        #dots;gcc -c hello.c #h(1fr) #text(font: "DejaVu Sans", size: 0.8em, fill: bad-color, style: "italic")[4 spaces, not a TAB]
      ])
      #set text(size: 0.9em)
      ```terminal
      $ make
      Makefile:2: *** missing separator.  Stop.
      ```
      💡 set the editor to keep TABs in a `Makefile`
    ])
  ]
]

#slide[
  == A `Makefile` with Two Targets
  The `hello.c` program of the previous section

  #toolbox.side-by-side(columns: (165pt, 165pt, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #debug-code((((1, 0, "target"), (1, 1, "dep"), (4, 0, "target"), (4, 1, "dep")),))[```make
    hello: hello.o
    	gcc hello.o -o hello

    hello.o: hello.c
    	gcc -c hello.c
    ```]
  ][
    #set text(size: 0.9em)
    - `hello` is *linked* from `hello.o`
    - `hello.o` is *compiled* from `hello.c`
    - `make` alone builds the *first* target, `hello`
  ][
    #project-tree("hello", ("Makefile", "hello.c"), rows: 4)
  ]
]

// the times of the hello files (a real run, `ls -l --time-style=+%H:%M:%S`)
#let t-first = ("Makefile": "11:41:08", "hello.c": "11:41:08", "hello.o": "11:41:10", "hello": "11:41:11")
#let t-touch = t-first + ("hello.c": "11:41:13")
#let t-after = t-touch + ("hello.o": "11:41:13", "hello": "11:41:13")
#let hello-files = ("Makefile", "hello.c")
// the marks of the two rules: line 1 (hello: hello.o), line 4 (hello.o: hello.c)
#let rule-1 = ((1, 0, "target"), (1, 1, "dep"))
#let rule-4 = ((4, 0, "target"), (4, 1, "dep"))
#let missing = [does not exist]

#slide[
  == `make`, Step by Step: a New Build
  Nothing is built yet

  #toolbox.side-by-side(columns: (165pt, 165pt, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #debug-code((((1, 0, "target"),), rule-1, ((4, 1, "dep"),), rule-4, (5,), rule-1, (2,)))[```make
    hello: hello.o
    	gcc hello.o -o hello

    hello.o: hello.c
    	gcc -c hello.c
    ```]
    #reveal-terminal(before: none, lines: (1, 1, 1, 1, 2, 2, 3), full: false)[```terminal
    $ make
    gcc -c hello.c
    gcc hello.o -o hello
    ```]
  ][
    #only(1, make-step(target: ("hello", missing))[🎯 no target given: build the *first* one, `hello`])
    #only(2, make-step(dep: ("hello.o", missing), target: ("hello", missing))[`hello` needs `hello.o`, which has its own rule: make it first])
    #only(3, make-step(dep: ("hello.c", [11:41:08]), target: ("hello.o", missing))[`hello.c` has no rule: the file must exist \ ✅ it exists])
    #only(4, make-step(dep: ("hello.c", [11:41:08]), target: ("hello.o", missing))[`hello.o` does not exist: run the recipe])
    #only(5, make-step(dep: ("hello.c", [11:41:08]), target: ("hello.o", [11:41:10, new]), [`hello.o` is built], cmd: "gcc -c hello.c"))
    #only(6, make-step(dep: ("hello.o", [11:41:10]), target: ("hello", missing))[back to `hello`: it does not exist, run the recipe])
    #only("7-", make-step(dep: ("hello.o", [11:41:10]), target: ("hello", [11:41:11, new]), [`hello` is built], cmd: "gcc hello.o -o hello"))
  ][
    #stack-steps((
      ("hello",),
      ("hello.o", "hello"),
      ("hello.c", "hello.o", "hello"),
      ("hello.o", "hello"),
      ("hello.o", "hello"),
      ("hello",),
      ("hello",),
    ))
    #only("-4", project-tree("hello", hello-files, times: t-first, rows: 4))
    #only("5-6", project-tree("hello", hello-files + ("hello.o",), times: t-first, states: ("hello.o": "built"), rows: 4))
    #only("7-", project-tree("hello", hello-files + ("hello.o", "hello"), times: t-first, states: ("hello.o": "built", "hello": "built"), rows: 4))
  ]
]

#slide[
  == `make`, Step by Step: Up to Date
  Run `make` again, right after the first build

  #toolbox.side-by-side(columns: (165pt, 165pt, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #debug-code((((1, 0, "target"),), rule-1, ((4, 1, "dep"),), rule-4, rule-1))[```make
    hello: hello.o
    	gcc hello.o -o hello

    hello.o: hello.c
    	gcc -c hello.c
    ```]
    // the first build stays on the screen, as in a real terminal
    #reveal-terminal(start: 0, before: none, lines: (3, 4, 4, 4, 4, 5), full: false)[```terminal
    $ make
    gcc -c hello.c
    gcc hello.o -o hello
    $ make
    make: 'hello' is up to date.
    ```]
  ][
    #only(1, make-step(target: ("hello", [11:41:11]))[🎯 no target given: build the *first* one, `hello`])
    #only(2, make-step(dep: ("hello.o", [11:41:10]), target: ("hello", [11:41:11]))[`hello` needs `hello.o`, which has its own rule: check it first])
    #only(3, make-step(dep: ("hello.c", [11:41:08]), target: ("hello.o", [11:41:10]))[`hello.c` has no rule: the file must exist \ ✅ it exists])
    #only(4, make-step(dep: ("hello.c", [11:41:08]), target: ("hello.o", [11:41:10]))[`hello.c` is *older* than `hello.o` \ ✅ nothing to run])
    #only("5-", make-step(dep: ("hello.o", [11:41:10]), target: ("hello", [11:41:11]))[back to `hello`: `hello.o` is *older* than `hello` \ ✅ nothing to run, `hello` is up to date])
  ][
    #stack-steps((
      ("hello",),
      ("hello.o", "hello"),
      ("hello.c", "hello.o", "hello"),
      ("hello.o", "hello"),
      ("hello",),
    ))
    #project-tree("hello", hello-files + ("hello.o", "hello"), times: t-first, rows: 4)
  ]
]

#slide[
  == `make`, Step by Step: a Modified File
  Change the source file and build again

  #toolbox.side-by-side(columns: (165pt, 165pt, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #debug-code(((), rule-1, ((4, 1, "dep"),), rule-4, (5,), rule-1, (2,)))[```make
    hello: hello.o
    	gcc hello.o -o hello

    hello.o: hello.c
    	gcc -c hello.c
    ```]
    #reveal-terminal(before: none, lines: (1, 2, 2, 2, 3, 3, 4), full: false)[```terminal
    $ touch hello.c   # as if edited
    $ make
    gcc -c hello.c
    gcc hello.o -o hello
    ```]
  ][
    #only(1, make-step(dep: ("hello.c", [11:41:13, now]))[`touch` sets the time of `hello.c` to *now*, as if we edited it])
    #only(2, make-step(dep: ("hello.o", [11:41:10]), target: ("hello", [11:41:11]))[🎯 `hello` needs `hello.o`, which has its own rule: make it first])
    #only(3, make-step(dep: ("hello.c", [11:41:13]), target: ("hello.o", [11:41:10]))[`hello.c` has no rule: the file must exist \ ✅ it exists])
    #only(4, make-step(dep: ("hello.c", [11:41:13]), target: ("hello.o", [11:41:10]))[`hello.c` is *newer* than `hello.o`: run the recipe])
    #only(5, make-step(dep: ("hello.c", [11:41:13]), target: ("hello.o", [11:41:13, new]), [`hello.o` is built again], cmd: "gcc -c hello.c"))
    #only(6, make-step(dep: ("hello.o", [11:41:13]), target: ("hello", [11:41:11]))[back to `hello`: `hello.o` is now *newer*, run the recipe])
    #only("7-", make-step(dep: ("hello.o", [11:41:13]), target: ("hello", [11:41:13, new]), [`hello` is built again], cmd: "gcc hello.o -o hello"))
  ][
    #stack-steps((
      (),
      ("hello.o", "hello"),
      ("hello.c", "hello.o", "hello"),
      ("hello.o", "hello"),
      ("hello.o", "hello"),
      ("hello",),
      ("hello",),
    ))
    #let files = hello-files + ("hello.o", "hello")
    #only("-4", project-tree("hello", files, times: t-touch, states: ("hello.c": "changed"), rows: 4))
    #only("5-6", project-tree("hello", files, times: t-touch + ("hello.o": "11:41:13"), states: ("hello.c": "changed", "hello.o": "built"), rows: 4))
    #only("7-", project-tree("hello", files, times: t-after, states: ("hello.c": "changed", "hello.o": "built", "hello": "built"), rows: 4))
  ]
]

#slide[
  == How `make` Decides
  A summary of the steps: `make --debug=v` prints them

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    === to make a target
    #only("1-")[#block[1. *push* it on the target stack]]
    #only("1-")[#block[2. make each *prerequisite* first, in the same way]]
    #only("2-")[#block[3. missing, or a prerequisite is *newer*? #arrow run the recipe]]
    #only("3-")[#block[4. otherwise it is _up to date_: nothing to run]]
    #only("4-")[#block[5. *pop* it, back to the target below]]
    #v(0.5em)
    #uncover("4-")[💡 `make` reads only the *times* of the files, never the code]
  ][
    #set text(size: 0.6em)
    // the lines of the step are marked, the others stay as they are
    #let marks = (
      "Considering target file '[^']+'",
      "(Prerequisite '[^']+' is newer than target '[^']+'|Must remake target '[^']+')",
      "No need to remake target '[^']+'",
      "Successfully remade target file '[^']+'",
    )
    #for (i, m) in marks.enumerate() {
      let when = if i == marks.len() - 1 { str(i + 1) + "-" } else { i + 1 }
      only(when, {
        show regex(m): it => box(fill: changed-fill, outset: (y: 1.5pt), text(fill: changed, it))
        ```terminal
        $ touch hello.c
        $ make --debug=v
        ...
        Considering target file 'hello'.
          Considering target file 'hello.o'.
            Considering target file 'hello.c'.
             Finished prerequisites of target file 'hello.c'.
            No need to remake target 'hello.c'.
           Finished prerequisites of target file 'hello.o'.
           Prerequisite 'hello.c' is newer than target 'hello.o'.
          Must remake target 'hello.o'.
        gcc -c hello.c
          Successfully remade target file 'hello.o'.
         Finished prerequisites of target file 'hello'.
         Prerequisite 'hello.o' is newer than target 'hello'.
        Must remake target 'hello'.
        gcc hello.o -o hello
        Successfully remade target file 'hello'.
        ```
      })
    }
  ]

  #v(1fr)
  #uncover("5-")[
    #callout[the indentation is the *target stack*: one level for every target `make` is working on]
  ]
]
