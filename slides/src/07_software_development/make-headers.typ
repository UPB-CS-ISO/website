#import "/src/slides.typ": *
#import "common.typ": *

#set raw(tab-size: 4)

#slide[
  = Header Dependencies #text(size: 10pt, weight: "regular")[\ _Where do the `.h` files go in a `Makefile`?_]
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
      - _Generating Prerequisites Automatically_
  + #link("https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html")[_GCC Manual_], _Options Controlling the Preprocessor_ (`-MM`, `-MMD`)
]

// the times in the cards come from a real run (`ls -l --time-style=+%H:%M:%S`):
// sources 12:35:55, build 12:35:57, `lib.h` edited 12:35:59, rebuilt 12:36:00
#let cols = (195pt, 150pt, 1fr)
// a rule of the Makefile: its target and its prerequisites marked
#let rule(line, deps: 1, from: 1) = ((line, 0, "target"),) + range(from, from + deps).map(d => (line, d, "dep"))
// the Makefile of the previous sections (8 lines)
#let hdr-makefile(steps) = debug-code(steps)[```make
CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o
	$(CC) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
```]
// lib.h added to the rule of app
#let wrong-makefile(steps) = debug-code(steps)[```make
CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o lib.h
	$(CC) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
```]
// the headers on the rules of the object files
#let right-makefile(steps) = debug-code(steps)[```make
CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o
	$(CC) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

main.o: lib.h print.h
lib.o: lib.h
print.o: print.h
```]
// the edit of lib.h
#let lib-h-edited = ("lib.h": "changed")

// the dependency graph of app: app on top, the object files in the middle,
// the .c and .h files at the bottom; an arrow means "is needed to build"
// - upto: the branches drawn (1: main.o, 2: + lib.o, 3: + print.o)
// - path: mark lib.h -> main.o, lib.o -> app (what a change of lib.h rebuilds)
#let include-graph(upto: 3, path: false) = drawing(width: 420pt, height: 170pt, {
  // name: (x, y, kind, branch); lib.h and print.h are needed by two object
  // files, they are drawn with the first branch that needs them
  let nodes = (
    "app": (210pt, 18pt, "target", 1),
    "lib.o": (70pt, 85pt, "target", 2),
    "main.o": (210pt, 85pt, "target", 1),
    "print.o": (350pt, 85pt, "target", 3),
    "lib.c": (40pt, 150pt, "source", 2),
    "lib.h": (130pt, 150pt, "header", 1),
    "main.c": (210pt, 150pt, "source", 1),
    "print.h": (290pt, 150pt, "header", 1),
    "print.c": (380pt, 150pt, "source", 3),
  )
  // (from, to, branch)
  let edges = (
    ("main.o", "app", 1), ("main.c", "main.o", 1), ("lib.h", "main.o", 1), ("print.h", "main.o", 1),
    ("lib.o", "app", 2), ("lib.c", "lib.o", 2), ("lib.h", "lib.o", 2),
    ("print.o", "app", 3), ("print.c", "print.o", 3), ("print.h", "print.o", 3),
  )
  // what a change of lib.h rebuilds
  let on-path = ("lib.h", "main.o", "lib.o", "app")
  for (from, to, br) in edges {
    if br <= upto {
      let (x1, y1, ..) = nodes.at(from)
      let (x2, y2, ..) = nodes.at(to)
      let hot = path and from in on-path and to in on-path
      // the arrows end spread along the bottom of the target, not on one point
      line-arrow((x1, y1 - 11pt), (x2 + (x1 - x2) * 0.18, y2 + 11pt), color: if hot { changed } else { luma(130) }, thickness: if hot { 2pt } else { 0.9pt }, head: if hot { 7pt } else { 5pt })
    }
  }
  let style = (
    target: (changed-fill, changed, changed),
    header: (rgb("eef3f5"), accent, accent),
    source: (white, luma(130), black),
  )
  for (name, (x, y, kind, br)) in nodes {
    if br <= upto {
      let (fill, stroke, ink) = style.at(kind)
      let hot = path and name in on-path
      pin(x, y, box(
        fill: if hot { changed } else { fill },
        stroke: 1pt + stroke,
        inset: (x: 0.5em, y: 0.35em),
        radius: 0.25em,
        text(font: mono, size: 9pt, fill: if hot { white } else { ink }, name),
      ))
    }
  }
  // the legend
  pin(385pt, 15pt, align(left, text(size: 7pt)[
    #box(width: 0.8em, height: 0.8em, fill: changed-fill, stroke: 0.8pt + changed) built by `make` \
    #box(width: 0.8em, height: 0.8em, fill: rgb("eef3f5"), stroke: 0.8pt + accent) header \
    #box(width: 0.8em, height: 0.8em, fill: white, stroke: 0.8pt + luma(130)) source
  ]))
  pin(60pt, 30pt, arrow-label[arrow: _is needed to build_])
})

// under a source file: what its object file needs, as chips and a sentence
#let include-note(deps, target, body) = block(
  width: 100%,
  fill: luma(248),
  stroke: 0.8pt + luma(190),
  radius: 0.4em,
  inset: 0.6em,
  {
    let chip(name, fill, stroke, ink) = box(
      fill: fill, stroke: 1pt + stroke, inset: (x: 0.4em, y: 0.25em), radius: 0.2em,
      text(font: mono, size: 0.9em, fill: ink, name),
    )
    align(center, {
      deps.map(d => chip(d, if d.ends-with(".h") { rgb("eef3f5") } else { white }, if d.ends-with(".h") { accent } else { luma(130) }, if d.ends-with(".h") { accent } else { black })).join(h(0.3em))
      h(0.3em)
      box(baseline: -0.1em, draw-arrow(length: 1.2em))
      h(0.3em)
      chip(target, changed-fill, changed, changed)
    })
    v(0.4em)
    text(size: 1.15em, body)
  },
)

// the three source files, side by side, with their #include lines marked
#slide[
  == Who Includes Whom?
  The dependencies come from the `#include` lines of every `.c` file

  #set text(size: 0.57em)
  #grid(
    columns: (1.1fr, 1fr, 1.15fr),
    column-gutter: 0.8em,
    [
      #code-file("main.c", debug-code(((1, 2), (1, 2), (1, 2)))[```c
      #include "lib.h"
      #include "print.h"

      int main(void)
      {
          int total = sum(MAX);
          print_result("sum", total);
          return 0;
      }
      ```])
      #include-note(("main.c", "lib.h", "print.h"), "main.o")[two `#include` lines: two headers]
    ],
    [
      #code-file("lib.h")[```c
      #ifndef LIB_H
      #define LIB_H
      #define MAX 10
      int sum(int n);
      #endif
      ```]
      #code-file("lib.c", debug-code(((), (1,), (1,)))[```c
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
      #uncover("2-", include-note(("lib.c", "lib.h"), "lib.o")[`lib.c` includes its *own* header: good practice])
    ],
    [
      #code-file("print.h")[```c
      #ifndef PRINT_H
      #define PRINT_H
      void print_result(const char *label,
                        int value);
      #endif
      ```]
      #code-file("print.c", debug-code(((), (), (2,)))[```c
      #include <stdio.h>
      #include "print.h"

      void print_result(const char *label,
                        int value)
      {
          printf("%s = %d\n", label, value);
      }
      ```])
      #uncover("3-", include-note(("print.c", "print.h"), "print.o")[`<stdio.h>` is a system header, it does not change])
    ],
  )
]

#slide[
  == The Dependency Tree
  What `make` must know to rebuild the right files

  #only(1, include-graph(upto: 1))
  #only(2, include-graph(upto: 2))
  #only(3, include-graph(upto: 3))
  #only("4-", include-graph(path: true))

  #v(1fr)
  #set text(size: 0.9em)
  #only(1)[💡 `main.o` is built from `main.c` and from the two headers it includes]
  #only(2)[💡 `lib.o` is built from `lib.c` and `lib.h`: `lib.h` is needed by *two* object files]
  #only(3)[💡 `print.h` is also needed by two object files: `main.o` and `print.o`]
  #only("4-")[
    #callout[change `lib.h` #arrow compile `main.o` and `lib.o` again #arrow link `app` again; `print.o` is kept]
  ]
]

#slide[
  == The Bug
  Change a header, with the `Makefile` of the previous sections

  #toolbox.side-by-side(columns: cols, gutter: 1em)[
    #set text(size: 0.7em)
    #hdr-makefile(((), rule(4, deps: 3), rule(7), rule(4, deps: 3), ()))
    #reveal-terminal(before: none, lines: (0, 1, 1, 2, 4), full: false)[```terminal
    $ make
    make: 'app' is up to date.
    $ ./app
    sum = 55
    ```]
  ][
    #only(1, free-card(file-chip("lib.h", [12:35:59, edited]))[we change `lib.h`: \ `#define MAX 100`])
    #only(2, make-step(dep: ("main.o", [12:35:57]), target: ("app", [12:35:57]))[🎯 `app` needs `main.o`, `lib.o` and `print.o`: check them first])
    #only(3, make-step(dep: ("main.c", [12:35:55]), target: ("main.o", [12:35:57]))[`main.c` is *older* than `main.o` ✅ \ `lib.h` is not in the rule: `make` does not look at it])
    #only("4-", make-step(dep: ("print.o", [12:35:57]), target: ("app", [12:35:57]))[back to `app`: all the object files are older \ ✅ `app` is up to date, nothing to run])
  ][
    #stack-steps(((), ("app",), ("main.o", "app"), ("app",), ()))
    #proj-tree(with: built, states: lib-h-edited)
  ]

  #only("5-")[
    #place(bottom + right, dy: -0.3em, popup(width: 280pt, color: bad-color)[
      ⚠️ Wrong result: 1 + 2 + ... + 100 is 5050
    ][
      `main.o` depends on `lib.h` (`main.c` includes it), but the `Makefile` does not say so: `make` does not compile `main.o` again, it still has `MAX = 10`
    ])
  ]
]

#slide[
  == The Wrong Place
  Add the header to the rule of `app`?

  #toolbox.side-by-side(columns: cols, gutter: 1em)[
    #set text(size: 0.7em)
    #wrong-makefile((rule(4, deps: 4), rule(7), rule(4, deps: 4) + (5,), ()))
    #reveal-terminal(before: none, lines: (0, 1, 2, 4), full: false)[```terminal
    $ make
    gcc main.o lib.o print.o lib.h -o app
    $ ./app
    sum = 55
    ```]
  ][
    #only(1, make-step(dep: ("lib.h", [12:35:59]), target: ("app", [12:35:57]))[we add `lib.h` to the prerequisites of `app`])
    #only(2, make-step(dep: ("main.c", [12:35:55]), target: ("main.o", [12:35:57]))[`main.c` is *older* than `main.o` ✅ \ nothing to run])
    #only("3-", make-step(dep: ("lib.h", [12:35:59]), target: ("app", [new]), [back to `app`: `lib.h` is *newer*, link again], cmd: "gcc main.o lib.o print.o lib.h -o app"))
  ][
    #stack-steps(((), ("main.o", "app"), ("app",), ()))
    #only("-2", proj-tree(with: built, states: lib-h-edited))
    #only("3-", proj-tree(with: built, states: lib-h-edited + ("app": "built")))
  ]

  #only("4-")[
    #place(bottom + right, dy: -0.3em, popup(width: 280pt, color: bad-color)[
      ⚠️ Still 55: only app was linked again
    ][
      `app` needs `lib.h` only *through* `main.o` and `lib.o`: the header goes on *their* rules. `main.o` was not compiled again, it still has `MAX = 10`
    ])
  ]
]

#slide[
  == The Right Place
  Headers go on the rules of the *object files* whose `.c` includes them

  #toolbox.side-by-side(columns: cols, gutter: 1em)[
    #set text(size: 0.66em)
    #right-makefile((
      rule(10, deps: 2) + rule(11) + rule(12),
      rule(4, deps: 3),
      rule(7) + rule(10, deps: 2) + (8,),
      rule(7) + rule(11) + (8,),
      rule(7) + rule(12),
      rule(4, deps: 3) + (5,),
      (),
    ))
    #reveal-terminal(before: none, lines: (0, 1, 2, 3, 3, 4, 6), full: false)[```terminal
    $ make
    gcc -Wall -g -c main.c -o main.o
    gcc -Wall -g -c lib.c -o lib.o
    gcc main.o lib.o print.o -o app
    $ ./app
    sum = 5050
    ```]
  ][
    #only(1, free-card(stack(dir: ltr, spacing: 0.4em, file-chip("lib.h", []), file-chip("print.h", [])))[three rules *without a recipe*: they only *add* prerequisites, the recipe still comes from `%.o: %.c`])
    #only(2, make-step(dep: ("main.o", [12:35:57]), target: ("app", [12:35:57]))[🎯 `app` needs `main.o`, `lib.o` and `print.o`: check them first])
    #only(3, make-step(dep: ("lib.h", [12:35:59]), target: ("main.o", [12:36:00, new]), [`lib.h` is *newer* than `main.o`], cmd: "gcc -Wall -g -c main.c -o main.o"))
    #only(4, make-step(dep: ("lib.h", [12:35:59]), target: ("lib.o", [12:36:00, new]), [`lib.h` is *newer* than `lib.o`], cmd: "gcc -Wall -g -c lib.c -o lib.o"))
    #only(5, make-step(dep: ("print.h", [12:35:55]), target: ("print.o", [12:35:57]))[`print.c` and `print.h` are *older* than `print.o` ✅ \ nothing to run])
    #only(6, make-step(dep: ("main.o", [12:36:00]), target: ("app", [12:36:00, new]), [back to `app`: `main.o` is *newer*], cmd: "gcc main.o lib.o print.o -o app"))
    #only("7-", free-card(step-file("app", "target", [sum = 5050]))[✅ `main.o` was compiled with `MAX = 100`, the result is right])
    // a tip, not an error: where the dependency comes from
    #uncover("7-", block(
      above: 0.6em,
      width: 100%,
      fill: changed-fill.lighten(30%),
      stroke: (left: 3pt + changed),
      radius: (right: 0.3em),
      inset: (x: 0.6em, y: 0.45em),
      text(size: 0.72em)[💡 *Tip*: a dependency follows the `#include`, not the file name: `lib.o` depends on `lib.h` *because* `lib.c` includes it],
    ))
  ][
    #stack-steps(((), ("app",), ("main.o", "app"), ("lib.o", "app"), ("print.o", "app"), ("app",), ()))
    #only("-2", proj-tree(with: built, states: lib-h-edited))
    #only(3, proj-tree(with: built, states: lib-h-edited + ("main.o": "built")))
    #only("4-5", proj-tree(with: built, states: lib-h-edited + ("main.o": "built", "lib.o": "built")))
    #only("6-", proj-tree(with: built, states: lib-h-edited + ("main.o": "built", "lib.o": "built", "app": "built")))
  ]

]

#slide[
  == Bonus: Automatic Dependencies
  Let `gcc` write the header dependencies

  #toolbox.side-by-side(columns: cols, gutter: 1em)[
    #set text(size: 0.68em)
    #debug-code(((2,), (3, 11), (11,)))[```make
    CC = gcc
    CFLAGS = -Wall -g -MMD
    OBJS = main.o lib.o print.o

    app: $(OBJS)
    	$(CC) $^ -o $@

    %.o: %.c
    	$(CC) $(CFLAGS) -c $< -o $@

    -include $(OBJS:.o=.d)

    .PHONY: clean
    clean:
    	rm -f *.o *.d app
    ```]
  ][
    #only(1, free-card(flow(file-chip("main.c", []), step-file("gcc", "dep", [`-MMD`]), file-chip("main.d", []), gap: 0.25em, length: 1.2em))[`-MMD`: while compiling `X.c`, `gcc` also writes `X.d`, with the headers it read])
    #only(2, free-card(file-chip("main.d lib.d print.d", []))[`$(OBJS:.o=.d)` is `main.d lib.d print.d` \ `-include` reads them, if they exist (the `-` ignores the missing ones)])
    #only("3-", free-card[
      #set text(size: 0.75em)
      ```terminal
      $ cat main.d lib.d print.d
      main.o: main.c lib.h print.h
      lib.o: lib.c lib.h
      print.o: print.c print.h
      ```
    ][
      #set par(leading: 0.8em)
      #set text(size: 0.8em)
      `make` sees, in place of line 11: \
      // a rule as boxes: the target, a colon, the prerequisites
      #let rule-toks(target, ..deps) = tok("target", target) + h(0.3em) + [:] + h(0.6em) + deps.pos().map(d => tok("dep", d)).join(h(0.6em))
      #rule-toks("main.o", "main.c", "lib.h", "print.h") \
      #rule-toks("lib.o", "lib.c", "lib.h") \
      #rule-toks("print.o", "print.c", "print.h")
    ])
  ][
    #let deps = ("main.d", "lib.d", "print.d")
    #proj-tree(with: built + deps, states: all-states(deps, "built"), extra-rows: 3)
  ]
]

#slide[
  == `make` Cheat Sheet

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #key-table(header: ([*command*], [*what it does*]), (
      ([`make`], [build the first target]),
      ([`make print.o`], [build the target `print.o`]),
      ([`make clean`], [build the target `clean`]),
      ([`make -n`], [only *show* the commands (dry run)]),
      ([`make -B`], [build everything again]),
      ([`make -j8`], [run up to 8 recipes at the same time]),
      ([`make -C dir`], [use the `Makefile` from `dir`]),
      ([`make CC=clang`], [change a variable]),
      ([`make --debug=v`], [show every decision, indented by the target stack]),
    ), size: 0.8em)
  ][
    #set text(size: 0.9em)
    === Remember
    - a target is rebuilt when it is *missing* or *older* than a prerequisite
    - `$@` the target, `$<` the first prerequisite, `$^` all of them
    - a header goes on the rule of the `.o` of every `.c` that includes it, never on the executable
    - `make` compares *modification times*, it does not read the code
    - targets that are not files (`all`, `run`, `clean`) go in `.PHONY`
  ]
]
