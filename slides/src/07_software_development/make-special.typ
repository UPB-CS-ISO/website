#import "/src/slides.typ": *
#import "common.typ": *

#set raw(tab-size: 4)

#slide[
  = Special Targets #text(size: 10pt, weight: "regular")[\ _Targets that are not files: `clean`, `all`, `build`, `run`_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 15 - _Development Tools_
      - Section 15.2 - _make_
  + #make-manual
    - Chapter 4 - _Writing Rules_
      - _Phony Targets_
      - _Special Built-in Target Names_
    - Chapter 16 - _Makefile Conventions_
      - _Standard Targets for Users_
]

#let missing = [does not exist]
// the Makefile of the previous section, with `clean` (`phony`: with a
// `.PHONY: clean` line); the lines of `clean` are 10-11 (11-12 with .PHONY)
#let clean-makefile(steps, phony: false) = {
  let src = "CC = gcc\nCFLAGS = -Wall -g\n\napp: main.o lib.o print.o\n\t$(CC) $^ -o $@\n\n%.o: %.c\n\t$(CC) $(CFLAGS) -c $< -o $@\n\n" + if phony { ".PHONY: clean\n" } else { "" } + "clean:\n\trm -f *.o app"
  debug-code(steps, raw(src, lang: "make", block: true))
}

#slide[
  == `clean`: a Target That Is Not a File
  It has no prerequisites and its recipe builds no file

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.7em)
    #clean-makefile((((10, 0, "target"),), ((10, 0, "target"), 11), ((10, 0, "target"), 11)))
    #reveal-terminal(before: none, lines: (1, 2, 4), full: false)[```terminal
    $ make clean
    rm -f *.o app
    $ make clean
    rm -f *.o app
    ```]
  ][
    #only(1, make-step(target: ("clean", missing))[🎯 the goal is `clean`, it has *no* prerequisites])
    #only(2, make-step(target: ("clean", missing), [there is no file named `clean`: run the recipe], cmd: "rm -f *.o app"))
    #only("3-", make-step(target: ("clean", missing), [again: still no file named `clean`, the recipe runs *every time*], cmd: "rm -f *.o app"))
  ][
    #target-stack(("clean",))
    #only(1, proj-tree(with: built))
    #only(2, proj-tree(with: built, states: all-states(built, "deleted")))
    #only("3-", proj-tree())
  ]
]

// the target `clean` and the file `clean`, side by side: the same name
#let same-name = free-card(
  grid(
    columns: 3,
    column-gutter: 0.6em,
    align: center + top,
    step-file("clean", "target", [target, in `Makefile`]),
    text(size: 1.4em, weight: "bold", fill: changed)[=],
    file-chip("clean", [file, in `project/`]),
  ),
)[the *same name*: for `make`, a target is the *file* it builds, so the target `clean` now *is* this file]

#slide[
  == A File Named `clean`
  `make` cannot tell a target from a file with the same name

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.7em)
    #clean-makefile(((), ((10, 0, "target"),), ((10, 0, "target"),), ((10, 0, "target"),)))
    #reveal-terminal(before: none, lines: (1, 1, 3, 3), full: false)[```terminal
    $ touch clean
    $ make clean
    make: 'clean' is up to date.
    ```]
  ][
    #only(1, free-card(file-chip("clean", [file, in `project/`]))[a file named `clean` appears in the folder: created by mistake, by a script, ...])
    #only(2, same-name)
    #only("3-", make-step(target: ("clean", [the file exists]))[the file `clean` exists and has no prerequisites: it is _up to date_ \ ❌ the recipe does not run])
  ][
    #only("-2", target-stack(()))
    #only("3-", target-stack(("clean",)))
    #proj-tree(with: built + ("clean",), states: ("clean": "new"))
  ]

  // a warning drawn over the slide: nothing moves when it appears
  #only("4-")[
    #place(bottom + right, dy: -0.3em, popup(width: 260pt, color: bad-color)[
      ⚠️ Nothing was deleted
    ][
      `make clean` did not run `rm`: `app` and the `.o` files are *still here*
    ])
  ]
]

#slide[
  == `.PHONY`
  Tell `make` which targets are not files

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.7em)
    #clean-makefile(phony: true, ((10,), ((11, 0, "target"), 12)))
    #uncover("2-")[
      ```terminal
      $ ls clean
      clean
      $ make clean
      rm -f *.o app
      ```
    ]
  ][
    #only(1, make-step(target: ("clean", [phony]))[`.PHONY` is a *special target*: its prerequisites are _phony_ targets, not files])
    #only("2-", make-step(target: ("clean", [phony]), [`clean` is phony: no file is checked, the recipe *always* runs], cmd: "rm -f *.o app"))
  ][
    #only(1, target-stack(()))
    #only("2-", target-stack(("clean",)))
    #only(1, proj-tree(with: built + ("clean",)))
    #only("2-", proj-tree(with: built + ("clean",), states: all-states(built, "deleted")))
  ]
]

// the Makefile with all, build and run
#let full-makefile(steps) = debug-code(steps)[```make
CC = gcc
CFLAGS = -Wall -g

.PHONY: all build run clean

all: build

build: app

run: build
	./app

app: main.o lib.o print.o
	$(CC) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o app
```]

// a phony target as a chip: orange like a target, dashed (it is not a file)
#let phony-chip(name) = box(
  stroke: (paint: changed, thickness: 1pt, dash: "dashed"),
  fill: changed-fill,
  inset: (x: 0.45em, y: 0.3em),
  radius: 0.2em,
  text(font: mono, size: 0.85em, fill: changed, name),
)

#slide[
  == `all`, `build` and `run`
  Phony targets give names to what we ask `make` to do

  #toolbox.side-by-side(columns: (170pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.62em)
    #full-makefile((
      ((4, 0, "target"), (4, 1, "dep"), (4, 2, "dep"), (4, 3, "dep"), (4, 4, "dep")),
      ((6, 0, "target"), (6, 1, "dep")),
      ((8, 0, "target"), (8, 1, "dep")),
      ((10, 0, "target"), (10, 1, "dep"), 11),
      ((19, 0, "target"), 20),
    ))
  ][
    #only(1, free-card(
      stack(dir: ltr, spacing: 0.4em, phony-chip("all"), phony-chip("build"), phony-chip("run"), phony-chip("clean")),
    )[one `.PHONY` line for *all* the targets that are not files: their recipes always run])
    #only(2, make-step(dep: ("build", [phony]), target: ("all", [phony]))[`all` is the *first* target, so `make` means `make all`; by convention, it builds *everything*])
    #only(3, make-step(dep: ("app", [a file]), target: ("build", [phony]))[`build` builds the program, `app` \ it has no recipe of its own])
    #only(4, make-step(dep: ("build", [phony]), target: ("run", [phony]), [`run` builds the program first, then starts it], cmd: "./app"))
    #only("5-", make-step(target: ("clean", [phony]), [`clean` deletes what `make` built], cmd: "rm -f *.o app"))
  ][
    // what we type and what happens, one row per step (uncover: no jumps)
    #block(
      width: 100%,
      fill: luma(248),
      stroke: 0.8pt + luma(190),
      radius: 0.4em,
      inset: 0.5em,
      {
        set text(size: 0.72em)
        let rows = (
          (2, "make", [builds `app`]),
          (3, "make build", [builds `app`]),
          (4, "make run", [builds and runs `app`]),
          (5, "make clean", [deletes what it built]),
        )
        table(
          columns: (auto, 1fr),
          inset: (x: 0.3em, y: 0.45em),
          stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
          table.header([*we type*], [*`make`*]),
          ..rows.map(((n, cmd, what)) => (
            uncover(str(n) + "-", text(font: mono, fill: accent, weight: "bold", cmd)),
            uncover(str(n) + "-", what),
          )).flatten(),
        )
      },
    )
  ]
]

#slide[
  == `make run`, Step by Step
  `app` is already built

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.56em)
    #full-makefile((
      ((10, 0, "target"), (10, 1, "dep")),
      ((8, 0, "target"), (8, 1, "dep")),
      ((13, 0, "target"), (13, 1, "dep"), (13, 2, "dep"), (13, 3, "dep")),
      ((8, 0, "target"),),
      ((10, 0, "target"), 11),
    ))
    #reveal-terminal(before: none, lines: (1, 1, 1, 1, 3), full: false)[```terminal
    $ make run
    ./app
    sum = 55
    ```]
  ][
    #only(1, make-step(dep: ("build", [phony]), target: ("run", [phony]))[🎯 the goal is `run`: it needs `build`, make it first])
    #only(2, make-step(dep: ("app", [12:09:13]), target: ("build", [phony]))[`build` needs `app`: make it first])
    #only(3, make-step(dep: ("main.o", [12:09:13]), target: ("app", [12:09:13]))[the same checks as before: the object files and `app` are up to date ✅])
    #only(4, make-step(dep: ("app", [12:09:13]), target: ("build", [phony]))[back to `build`: it has no recipe, nothing to run])
    #only("5-", make-step(dep: ("build", [phony]), target: ("run", [phony]), [back to `run`: phony, so its recipe always runs], cmd: "./app"))
  ][
    #stack-steps((("run",), ("build", "run"), ("app", "build", "run"), ("build", "run"), ("run",)))
    #proj-tree(with: built)
  ]
]

#slide[
  == Common Phony Targets
  The names other programmers expect

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #key-table(header: ([*target*], [*what it does*]), (
      ([`all`], [build everything; the *first* target, the default]),
      ([`build`], [build the program (used by many projects)]),
      ([`run`], [build and run the program]),
      ([`clean`], [delete the files `make` built]),
      ([`test`, `check`], [build and run the tests]),
      ([`install`], [copy the program into the system, e.g. `/usr/local/bin`]),
    ), size: 0.85em, gap: 0.45em)
  ][
    #set text(size: 0.9em)
    - `all`, `clean`, `install`, `check` are *GNU conventions*
    - write them in `.PHONY`
    - a phony target is always _out of date_: its recipe always runs
    #v(0.5em)
    💡 `make clean && make` builds everything from scratch, like `make -B`
  ]
]
