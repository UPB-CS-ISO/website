#import "/src/slides.typ": *
#import "common.typ": *

#set raw(tab-size: 4)

#slide[
  = A `Makefile` for a Project #text(size: 10pt, weight: "regular")[\ _The same steps for several files, a shorter `Makefile`_]
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
      - Section 6.7.1 - _Automatizarea compilării în C/C++_
  + #make-manual
    - Chapter 2 - _An Introduction to Makefiles_
    - Chapter 10 - _Using Implicit Rules_ (pattern rules, automatic variables)
]

// the files of the project, walked through like in a debugger: one array of
// marks per step of the slide (see debug-code), every file covers all 5 steps
#slide[
  == The Project
  The program of _Several Source Files_: `main.c` uses two _modules_, `lib` and `print`

  #grid(
    columns: (0.95fr, 1.07fr, 1.12fr),
    column-gutter: 0.6em,
    row-gutter: 0.5em,
    [
      #set text(size: 0.7em)
      #code-file("main.c", debug-code(((), (6,), (7,), (), ()))[```c
      #include "lib.h"
      #include "print.h"

      int main(void)
      {
          int total = sum(MAX);
          print_result("sum", total);
          return 0;
      }
      ```])
      #v(0.3em)
      #reveal-terminal(before: none, lines: (0, 0, 0, 4, 6), full: false)[```terminal
      $ gcc -c main.c
      $ gcc -c lib.c
      $ gcc -c print.c
      $ gcc main.o lib.o print.o -o app
      $ ./app
      sum = 55
      ```]
    ],
    [
      #set text(size: 0.7em)
      #code-file("lib.h", debug-code(((), (3, 4), (), (), ()))[```c
      #ifndef LIB_H
      #define LIB_H
      #define MAX 10
      int sum(int n);
      #endif
      ```])
      #code-file("lib.c", debug-code(((), (3,), (), (), ()))[```c
      #include "lib.h"

      int sum(int n)
      {
          int s = 0;
          for (int i = 1; i <= n; i++) {
              s = s + i;
          }
          return s;
      }
      ```])
    ],
    [
      #set text(size: 0.7em)
      #code-file("print.h", debug-code(((), (), (3, 4), (), ()))[```c
      #ifndef PRINT_H
      #define PRINT_H
      void print_result(const char *label,
                        int value);
      #endif
      ```])
      #code-file("print.c", debug-code(((), (), (4, 5), (), ()))[```c
      #include <stdio.h>
      #include "print.h"

      void print_result(const char *label,
                        int value)
      {
          printf("%s = %d\n", label, value);
      }
      ```])
    ],
  )

  #v(1fr)
  #set text(size: 0.85em)
  #only(1)[💡 a module is a pair of files: the `.h` *declares* what it offers, the `.c` *defines* how it works]
  #only(2)[💡 `main.c` calls `sum`: declared in `lib.h`, defined in `lib.c`, adds the numbers from 1 to `MAX`]
  #only(3)[💡 `main.c` calls `print_result`: declared in `print.h`, defined in `print.c`, uses `printf`]
  #only(4)[💡 each `.c` is *compiled* to its own `.o`, then the three `.o` files are *linked* into `app`]
  #only(5)[💡 four commands to remember and type again after every change: `make` will run them for us]
]

// the times in the cards come from a real run (`ls -l --time-style=+%H:%M:%S`):
// sources 12:09:11, first build 12:09:13, `touch print.c` 12:09:15
#let missing = [does not exist]
// a rule of the project Makefile: its target and its prerequisites marked
// (line: the line of the rule, deps: the number of prerequisites)
#let rule(line, deps: 1) = ((line, 0, "target"),) + range(1, deps + 1).map(d => (line, d, "dep"))
// the Makefile of the project, as a debug-code listing
#let proj-makefile(steps) = debug-code(steps)[```make
app: main.o lib.o print.o
	gcc main.o lib.o print.o -o app

main.o: main.c
	gcc -c main.c

lib.o: lib.c
	gcc -c lib.c

print.o: print.c
	gcc -c print.c
```]

// a card as large as a make-step card, for the steps that explain the
// Makefile instead of running make
#let card(body) = block(
  width: 100%,
  height: 11.5em,
  fill: luma(248),
  stroke: 0.8pt + luma(190),
  radius: 0.4em,
  inset: 0.7em,
  fit-check("card", text(size: 0.85em, body)),
)

// a recipe as written and as make runs it, one above the other, in a card
#let expansion(written, runs) = card({
  // more space between the lines: the boxed words have an outset
  set par(leading: 0.9em)
  let label(body) = block(above: 0em, below: 0.6em, text(size: 0.85em, fill: luma(100), body))
  label[we write]
  block(above: 0em, below: 1.2em, text(font: mono, size: 0.95em, written))
  label[`make` runs]
  block(above: 0em, below: 0em, text(font: mono, size: 0.95em, runs))
})

// the Makefile with a pattern rule, then also with variables
#let pattern-makefile(start: 1, steps) = debug-code(start: start, steps)[```make
app: main.o lib.o print.o
	gcc $^ -o $@

%.o: %.c
	gcc -c $< -o $@
```]
#let vars-makefile(start: 1, steps) = debug-code(start: start, steps)[```make
CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o
	$(CC) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
```]

// the same Makefile, with automatic variables (same lines as proj-makefile)
#let auto-makefile(start: 1, steps) = debug-code(start: start, steps)[```make
app: main.o lib.o print.o
	gcc $^ -o $@

main.o: main.c
	gcc -c $< -o $@

lib.o: lib.c
	gcc -c $< -o $@

print.o: print.c
	gcc -c $< -o $@
```]

#slide[
  == A `Makefile` for the Project
  One rule for every file we build, the `.h` files come in a later section

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.72em)
    #proj-makefile((rule(1, deps: 3) + rule(4) + rule(7) + rule(10),))
  ][
    #set text(size: 0.85em)
    - `app` is *linked* from the three object files
    - every object file is *compiled* from its `.c`
    - `make` alone builds the *first* target, `app`
  ][
    #proj-tree()
  ]
]

#slide[
  == The Project, Step by Step: a New Build
  The same steps as for `hello`, for every object file

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.7em)
    #proj-makefile((
      ((1, 0, "target"),),
      rule(1, deps: 3),
      rule(4) + (5,),
      rule(7) + (8,),
      rule(10) + (11,),
      rule(1, deps: 3) + (2,),
    ))
    #reveal-terminal(before: none, lines: (1, 1, 2, 3, 4, 5), full: false)[```terminal
    $ make
    gcc -c main.c
    gcc -c lib.c
    gcc -c print.c
    gcc main.o lib.o print.o -o app
    ```]
  ][
    #only(1, make-step(target: ("app", missing))[🎯 no target given: build the *first* one, `app`])
    #only(2, make-step(dep: ("main.o", missing), target: ("app", missing))[`app` needs `main.o`, `lib.o` and `print.o`: make them first, one by one])
    #only(3, make-step(dep: ("main.c", [12:09:11]), target: ("main.o", [12:09:13, new]), [`main.c` exists ✅, `main.o` does not exist], cmd: "gcc -c main.c"))
    #only(4, make-step(dep: ("lib.c", [12:09:11]), target: ("lib.o", [12:09:13, new]), [`lib.c` exists ✅, `lib.o` does not exist], cmd: "gcc -c lib.c"))
    #only(5, make-step(dep: ("print.c", [12:09:11]), target: ("print.o", [12:09:13, new]), [`print.c` exists ✅, `print.o` does not exist], cmd: "gcc -c print.c"))
    #only("6-", make-step(dep: ("print.o", [12:09:13]), target: ("app", [12:09:13, new]), [back to `app`: it does not exist], cmd: "gcc main.o lib.o print.o -o app"))
  ][
    #stack-steps((("app",), ("app",), ("main.o", "app"), ("lib.o", "app"), ("print.o", "app"), ("app",)))
    #for n in range(6) {
      // the files built so far (main.o from step 3, ... app on step 6)
      let k = calc.max(0, n - 1)
      let done = built.slice(0, calc.min(k, 4))
      only(if n == 5 { "6-" } else { n + 1 }, proj-tree(with: done, states: all-states(done, "built")))
    }
  ]
]

#slide[
  == The Project, Step by Step: a Modified File
  Rebuild only what changed, then shorten the `Makefile`: automatic variables, a pattern rule, variables

  #toolbox.side-by-side(columns: (195pt, 150pt, 1fr), gutter: 1em)[
    #set text(size: 0.7em)
    #proj-makefile((
      (),
      rule(1, deps: 3),
      rule(4),
      rule(7),
      rule(10) + (11,),
      rule(1, deps: 3) + (2,),
    ))
    // from step 7, the same box shows the Makefile with automatic variables
    #auto-makefile(start: 7, (
      ((2, 1, "dep"), (2, 3, "target"), (5, 2, "dep"), (5, 4, "target"), (8, 2, "dep"), (8, 4, "target"), (11, 2, "dep"), (11, 4, "target")),
      rule(1, deps: 3) + ((2, 1, "dep"), (2, 3, "target")),
      rule(4) + ((5, 2, "dep"), (5, 4, "target")),
      (5, 8, 11),
    ))
    // step 11: one pattern rule for the object files, step 12: variables
    #pattern-makefile(start: 11, (((4, 0, "target"), (4, 1, "dep"), 5),))
    #vars-makefile(start: 12, ((1, 2, 5, 8),))
    #reveal-terminal(before: none, lines: (1, 2, 2, 2, 3, 4), full: false)[```terminal
    $ touch print.c
    $ make
    gcc -c print.c
    gcc main.o lib.o print.o -o app
    ```]
  ][
    #only(1, make-step(dep: ("print.c", [12:09:15, now]))[`touch` sets the time of `print.c` to *now*, as if we edited it])
    #only(2, make-step(dep: ("main.o", [12:09:13]), target: ("app", [12:09:13]))[🎯 `app` needs `main.o`, `lib.o` and `print.o`: check them first])
    #only(3, make-step(dep: ("main.c", [12:09:11]), target: ("main.o", [12:09:13]))[`main.c` is *older* than `main.o` \ ✅ nothing to run])
    #only(4, make-step(dep: ("lib.c", [12:09:11]), target: ("lib.o", [12:09:13]))[`lib.c` is *older* than `lib.o` \ ✅ nothing to run])
    #only(5, make-step(dep: ("print.c", [12:09:15]), target: ("print.o", [12:09:15, new]), [`print.c` is *newer* than `print.o`], cmd: "gcc -c print.c"))
    #only(6, make-step(dep: ("print.o", [12:09:15]), target: ("app", [12:09:15, new]), [back to `app`: `print.o` is *newer*], cmd: "gcc main.o lib.o print.o -o app"))
    #only(7, card[
      #key-table(header: ([*variable*], [*means*]), (
        ([#tok("target", "$@")], [the *target* of the rule]),
        ([#tok("dep", "$<")], [the *first* prerequisite]),
        ([#tok("dep", "$^")], [*all* the prerequisites]),
      ), size: 1em, gap: 0.4em)
      💡 `make` fills them in, for each rule, *inside the recipe*
    ])
    #only(8, expansion(
      [gcc #tok("dep", "$^") -o #tok("target", "$@")],
      [gcc #tok("dep", "main.o lib.o print.o") -o #tok("target", "app")],
    ))
    #only(9, expansion(
      [gcc -c #tok("dep", "$<") -o #tok("target", "$@")],
      [gcc -c #tok("dep", "main.c") -o #tok("target", "main.o")],
    ))
    #only(10, card[the three recipes of the object files are now the *same*: \ `gcc -c $< -o $@`])
    #only(11, card[
      a *pattern rule*: `%` matches any name, so `%.o: %.c` means
      #set par(leading: 0.9em)
      #block(above: 0.8em)[
        #tok("target", "main.o"):#h(0.5em)#tok("dep", "main.c") \
        #tok("target", "lib.o"):#h(0.5em)#tok("dep", "lib.c") \
        #tok("target", "print.o"):#h(0.5em)#tok("dep", "print.c")
      ]
      ✅ 11 lines #arrow 5 lines
    ])
    #only("12-", expansion(
      [#tok("var", "$(CC)") #tok("var", "$(CFLAGS)") -c \$< -o \$\@],
      [#tok("var", "gcc") #tok("var", "-Wall -g") -c main.c -o main.o],
    ))
  ][
    #stack-steps(((), ("app",), ("main.o", "app"), ("lib.o", "app"), ("print.o", "app"), ("app",), ()))
    #only("-4", proj-tree(with: built, states: ("print.c": "changed")))
    #only(5, proj-tree(with: built, states: ("print.c": "changed", "print.o": "built")))
    #only("6-", proj-tree(with: built, states: ("print.c": "changed", "print.o": "built", "app": "built")))
  ]
]
