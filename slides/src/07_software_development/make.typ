#import "/src/slides.typ": *
#import "common.typ": *

#set raw(tab-size: 4)

#slide[
  = Building with `make` #text(size: 10pt, weight: "regular")[\ _Rebuild only what changed, a `Makefile` step by step_]
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
  == The Project
  One `main.c` and two pairs of `.h` / `.c` files

  #set text(size: 0.72em)
  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 0.8em,
    [
      `main.c`
      ```c
      #include "lib.h"
      #include "print.h"

      int main(void)
      {
          int total = sum(MAX);
          print_result("sum", total);
          return 0;
      }
      ```
    ],
    [
      `lib.h`
      ```c
      #ifndef LIB_H
      #define LIB_H
      #define MAX 10
      int sum(int n);
      #endif
      ```
      `lib.c`
      ```c
      int sum(int n)
      {
          int s = 0;
          for (int i = 1; i <= n; i++) {
              s = s + i;
          }
          return s;
      }
      ```
    ],
    [
      `print.h`
      ```c
      #ifndef PRINT_H
      #define PRINT_H
      void print_result(const char *label,
                        int value);
      #endif
      ```
      `print.c`
      ```c
      #include <stdio.h>
      #include "print.h"

      void print_result(const char *label,
                        int value)
      {
          printf("%s = %d\n", label, value);
      }
      ```
    ],
  )
]

// ----- the dependency graph -----

// the places of the files in the drawing
#let dep-pos = (
  "app": (112pt, 12pt),
  "lib.o": (30pt, 64pt),
  "main.o": (112pt, 64pt),
  "print.o": (192pt, 64pt),
  "lib.c": (20pt, 118pt),
  "lib.h": (66pt, 118pt),
  "main.c": (112pt, 118pt),
  "print.h": (158pt, 118pt),
  "print.c": (204pt, 118pt),
)

// a file of the graph, `state`: none, "changed" (we edited it), "rebuilt"
// (make built it again), "stale" (should have been rebuilt, was not)
#let dep-node(name, state) = {
  let (stroke, fill, ink) = if state == "changed" {
    (1.5pt + changed, changed-fill, changed)
  } else if state == "rebuilt" {
    (1.5pt + ok-color, ok-fill, ok-color)
  } else if state == "stale" {
    (1.5pt + bad-color, bad-fill, bad-color)
  } else {
    (0.8pt + luma(130), white, black)
  }
  box(
    inset: (x: 0.25em, y: 0.3em),
    radius: 0.2em,
    stroke: stroke,
    fill: fill,
    text(font: mono, size: 6.5pt, fill: ink, name),
  )
}

// `edges`: (prerequisite, target, style), style: "ok", "missing" (make
// does not know it), "wrong" (in the wrong place); `states`: a dictionary
// file -> state; `nodes`: the files to draw
#let dep-graph(edges, states: (:), nodes: dep-pos.keys()) = drawing(width: 225pt, height: 146pt, {
  // a legend, only for the states that appear
  let legend = (("changed", [edited]), ("rebuilt", [rebuilt]), ("stale", [should be rebuilt])).filter(((k, _)) => k in states.values())
  if legend.len() > 0 {
    pin(112pt, 139pt, legend.map(((k, l)) => box(baseline: 15%, dep-node(" ", k)) + h(0.2em) + text(size: 6.5pt, l)).join(h(0.8em)))
  }
  for (from, to, style) in edges {
    let (x1, y1) = dep-pos.at(from)
    let (x2, y2) = dep-pos.at(to)
    let (color, dash, th) = if style == "missing" {
      (luma(190), "dashed", 0.8pt)
    } else if style == "wrong" {
      (bad-color, none, 1.4pt)
    } else if style == "new" {
      (ok-color, none, 1.4pt)
    } else {
      (luma(110), none, 0.9pt)
    }
    line-arrow((x1, y1 - 8pt), (x2, y2 + 8pt), color: color, dash: dash, thickness: th)
  }
  for n in nodes {
    pin(..dep-pos.at(n), dep-node(n, states.at(n, default: none)))
  }
})

#let edges-objects = (
  ("main.o", "app", "ok"), ("lib.o", "app", "ok"), ("print.o", "app", "ok"),
  ("main.c", "main.o", "ok"), ("lib.c", "lib.o", "ok"), ("print.c", "print.o", "ok"),
)
#let edges-headers(style) = (
  ("lib.h", "main.o", style), ("print.h", "main.o", style), ("print.h", "print.o", style),
)

#slide[
  == Who Includes Whom?
  The dependencies come from the `#include` lines

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1em)[
    #only(1, dep-graph(edges-objects))
    #only("2-", dep-graph(edges-objects + edges-headers("new"), states: ("lib.h": none)))
    #align(center, text(size: 0.7em, fill: luma(100))[an arrow: _is needed to build_])
  ][
    #set text(size: 0.9em)
    #uncover("1-")[#block[
      - every `.c` becomes an `.o`
      - the `.o` files are linked into `app`
    ]]
    #uncover("2-")[#block[
      - `main.c` includes `lib.h` and `print.h`
      - `print.c` includes `print.h`
    ]]
    #uncover("3-")[#block[
      - `lib.c` includes *nothing*: it only *defines* `sum`
    ]]
  ]

  #v(1fr)
  #uncover("4-")[
    #callout[change `lib.h` #arrow rebuild `main.o` (it uses `MAX`) #arrow link `app` again]
  ]
]

#slide[
  == Building by Hand

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    ```terminal
    $ gcc -c main.c
    $ gcc -c lib.c
    $ gcc -c print.c
    $ gcc main.o lib.o print.o -o app
    $ ./app
    sum = 55
    ```
  ][
    #uncover("2-")[#block[
      - type 4 commands after every change?
      - or remember *which* ones are needed?
        - changed `print.c`: 2 commands
        - changed `lib.h`: 2 *other* commands
    ]]
    #uncover("3-")[#block[
      #v(0.5em)
      `make` reads the dependencies from a `Makefile` and runs *only* the commands that are needed
    ]]
  ]
]

#slide[
  == A Rule
  A `Makefile` is a list of rules

  #align(center)[
    #block(fill: luma(240), radius: 0.3em, inset: 0.8em, text(font: mono, size: 1.1em)[
      #text(fill: changed)[target]: #text(fill: accent)[prerequisites]\
      #box(fill: luma(200), inset: (x: 2pt), radius: 2pt, text(size: 0.7em)[TAB])#h(0.5em)recipe
    ])
  ]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("2-")[#block[
      - *target*: the file the rule builds
      - *prerequisites*: the files it is built from
      - *recipe*: the commands that build it
    ]]
    #uncover("3-")[#block[
      ⚠️ the recipe lines start with a *TAB*, not with spaces:\
      `Makefile:2: *** missing separator.  Stop.`
    ]]
  ][
    #uncover("4-")[#block[
      === `make` rebuilds a target when
      - it does not exist, or
      - a prerequisite is *newer* than it (the modification time, see `ls -l`)
    ]]
    #uncover("5-")[#block[
      - first, `make` brings the prerequisites up to date, with their own rules
      - `make` alone builds the *first* target
    ]]
  ]
]

#slide[
  == Step 1: One Rule

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    `Makefile`
    ```make
    app: main.c lib.c print.c
    	gcc main.c lib.c print.c -o app
    ```
    #uncover("2-")[
      ```terminal
      $ make
      gcc main.c lib.c print.c -o app
      $ make
      make: 'app' is up to date.
      ```
    ]
    #uncover("3-")[
      ```terminal
      $ touch print.c
      $ make
      gcc main.c lib.c print.c -o app
      ```
    ]
  ][
    #let e1 = (("main.c", "app", "ok"), ("lib.c", "app", "ok"), ("print.c", "app", "ok"))
    #only("-2", dep-graph(e1, nodes: ("app", "main.c", "lib.c", "print.c")))
    #only("3-", dep-graph(e1, nodes: ("app", "main.c", "lib.c", "print.c"), states: ("print.c": "changed", "app": "rebuilt")))
    #set text(size: 0.9em)
    #only(2)[💡 the second time nothing changed: `app` is newer than all its prerequisites]
    #only("3-")[💡 `touch` makes `print.c` newer: ❌ *all* three files are compiled again]
  ]
]

#slide[
  == Step 2: Object Files
  One rule per object file

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    `Makefile`
    ```make
    app: main.o lib.o print.o
    	gcc main.o lib.o print.o -o app

    main.o: main.c
    	gcc -c main.c

    lib.o: lib.c
    	gcc -c lib.c

    print.o: print.c
    	gcc -c print.c
    ```
    #only(2)[
      ```terminal
      $ make
      gcc -c main.c
      gcc -c lib.c
      gcc -c print.c
      gcc main.o lib.o print.o -o app
      ```
    ]
    #only("3-")[
      ```terminal
      $ touch print.c
      $ make
      gcc -c print.c
      gcc main.o lib.o print.o -o app
      ```
      ✅ only `print.c` is compiled again
    ]
  ][
    #only("-2", dep-graph(edges-objects))
    #only("3-", dep-graph(edges-objects, states: ("print.c": "changed", "print.o": "rebuilt", "app": "rebuilt")))
  ]
]

#slide[
  = Header Dependencies #text(size: 10pt, weight: "regular")[\ _Where do the `.h` files go in a `Makefile`?_]
]

#slide[
  == Step 3: The Bug
  Change a header, with the `Makefile` of step 2

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    `lib.h`
    ```c
    #define MAX 100
    ```
    #uncover("2-")[
      ```terminal
      $ make
      make: 'app' is up to date.
      $ ./app
      sum = 55
      ```
    ]
    #uncover("3-")[#block[
      ❌ 1 + 2 + ... + 100 is *5050*: the program still uses `MAX = 10`
    ]]
  ][
    #only("-3", dep-graph(edges-objects, nodes: dep-pos.keys().filter(n => n != "print.h"), states: ("lib.h": "changed")))
    #only("4-", dep-graph(edges-objects + edges-headers("missing"), states: ("lib.h": "changed", "main.o": "stale", "app": "stale")))
    #set text(size: 0.9em)
    #uncover("4-")[
      💡 the `Makefile` does not say that `main.o` needs `lib.h` (dashed): for `make`, nothing changed
    ]
  ]
]

#slide[
  == Step 4: The Wrong Place
  Add the header to the rule of `app`?

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    `Makefile`
    ```make
    app: main.o lib.o print.o lib.h
    	gcc main.o lib.o print.o -o app
    ...
    ```
    #uncover("2-")[
      ```terminal
      $ make
      gcc main.o lib.o print.o -o app
      $ ./app
      sum = 55
      ```
    ]
    #uncover("4-")[
      #callout(color: bad-color, fill: bad-fill)[a header is never a prerequisite of the executable: it is not linked, it is *compiled*]
    ]
  ][
    #let e4 = edges-objects + (("lib.h", "app", "wrong"),)
    #let n4 = dep-pos.keys().filter(n => n != "print.h")
    #only("-2", dep-graph(e4, nodes: n4, states: ("lib.h": "changed")))
    #only("3-", dep-graph(e4, nodes: n4, states: ("lib.h": "changed", "main.o": "stale", "app": "rebuilt")))
    #set text(size: 0.9em)
    #uncover("3-")[#block[
      ❌ `make` only *links* again, with the *old* `main.o`: `MAX` was compiled *into* `main.o`
    ]]
  ]
]

#slide[
  == Step 5: The Right Place
  Headers go on the rules of the *object files* whose `.c` includes them

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    `Makefile`
    #highlight-code(("all", (4,), (10,), "all"))[```make
    app: main.o lib.o print.o
    	gcc main.o lib.o print.o -o app

    main.o: main.c lib.h print.h
    	gcc -c main.c

    lib.o: lib.c
    	gcc -c lib.c

    print.o: print.c print.h
    	gcc -c print.c
    ```]
    #only("4-")[
      ```terminal
      $ make
      gcc -c main.c
      gcc main.o lib.o print.o -o app
      $ ./app
      sum = 5050
      ```
    ]
  ][
    #only("-3", dep-graph(edges-objects + edges-headers("new")))
    #only("4-", dep-graph(edges-objects + edges-headers("new"), states: ("lib.h": "changed", "main.o": "rebuilt", "app": "rebuilt")))
    #set text(size: 0.85em)
    #only(1)[💡 the headers are added only to the rules of the `.o` files]
    #only(2)[💡 `main.c` has `#include "lib.h"` and `#include "print.h"`]
    #only(3)[💡 `print.c` has `#include "print.h"`]
  ]
]

#slide[
  == Why Not `lib.o: lib.h`?
  A dependency follows the `#include`, not the file name

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    #block[
      - `lib.c` does *not* include `lib.h`
      - nothing in `lib.h` can change `lib.o`
    ]
    #uncover("2-")[
      ```terminal
      $ touch lib.h
      $ make
      gcc -c main.c
      gcc main.o lib.o print.o -o app
      ```
      ✅ `lib.c` is *not* compiled again, it would give the same `lib.o`
    ]
  ][
    #set text(size: 0.9em)
    #uncover("3-")[#block[
      `gcc` knows the real dependencies:
      ```terminal
      $ gcc -MM main.c lib.c print.c
      main.o: main.c lib.h print.h
      lib.o: lib.c
      print.o: print.c print.h
      ```
    ]]
    #uncover("4-")[#block[
      💡 `print.o` *does* depend on `print.h`, because `print.c` includes it
    ]]
  ]

  #v(1fr)
  #uncover("5-")[
    #callout[`X.o` depends on `X.c` and on *every header `X.c` includes*, directly or through other headers]
  ]
]

#slide[
  == Should `lib.c` Include `lib.h`?
  Usually yes: the compiler checks the definition against the declaration

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    `lib.c`, with a mistake
    ```c
    #include "lib.h"

    long sum(long n)
    {
        return n * (n + 1) / 2;
    }
    ```
    #uncover("3-")[#block[
      without the `#include` it compiles, and `main.c` calls it as `int sum(int)`: undefined behavior 💥
    ]]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[
      ```terminal
      $ gcc -c lib.c
      lib.c:3:6: error: conflicting types for 'sum'; have 'long int(long int)'
      lib.h:6:5: note: previous declaration of 'sum' with type 'int(int)'
      ```
    ]
    #uncover("4-")[#block[
      then, and only then, `lib.o` depends on `lib.h`:
      ```make
      lib.o: lib.c lib.h
      ```
    ]]
  ]
]

#slide[
  = A Better `Makefile` #text(size: 10pt, weight: "regular")[\ _Variables, pattern rules, automatic dependencies_]
]

#slide[
  == Step 6: Variables
  Write the compiler and its flags only once

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.78em)
    `Makefile`
    ```make
    CC = gcc
    CFLAGS = -Wall -g

    app: main.o lib.o print.o
    	$(CC) $^ -o $@

    main.o: main.c lib.h print.h
    	$(CC) $(CFLAGS) -c $<

    lib.o: lib.c
    	$(CC) $(CFLAGS) -c $<

    print.o: print.c print.h
    	$(CC) $(CFLAGS) -c $<
    ```
  ][
    #uncover("2-")[
      #key-table(header: ([*variable*], [*means*]), (
        ([ours], none),
        ([`$(CC)`], [the compiler, `gcc`]),
        ([`$(CFLAGS)`], [the flags of the compiler]),
        ([automatic], none),
        ([`$@`], [the target]),
        ([`$<`], [the *first* prerequisite]),
        ([`$^`], [*all* the prerequisites]),
      ), size: 0.85em)
    ]
    #set text(size: 0.9em)
    #uncover("3-")[#block[
      💡 in `main.o: main.c lib.h print.h`, `$<` is `main.c`: the headers are prerequisites, but they are *not* compiled
    ]]
  ]
]

#slide[
  == Step 7: A Pattern Rule
  One recipe for all the object files

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    `Makefile`
    #highlight-code(("all", (7, 8), (10, 11), (13, 14, 15), "all"))[```make
    CC = gcc
    CFLAGS = -Wall -g

    app: main.o lib.o print.o
    	$(CC) $^ -o $@

    %.o: %.c
    	$(CC) $(CFLAGS) -c $< -o $@

    main.o: main.c lib.h print.h
    print.o: print.c print.h

    .PHONY: clean
    clean:
    	rm -f *.o app
    ```]
  ][
    #set text(size: 0.85em)
    #only(1)[
      ```terminal
      $ make clean
      rm -f *.o app
      $ make
      gcc -Wall -g -c main.c -o main.o
      gcc -Wall -g -c lib.c -o lib.o
      gcc -Wall -g -c print.c -o print.o
      gcc main.o lib.o print.o -o app
      ```
    ]
    #only(2)[💡 `%.o: %.c`: *any* `X.o` is built from `X.c`, with this recipe]
    #only(3)[💡 rules without a recipe only *add* prerequisites: the headers go here; `lib.o` needs no line at all]
    #only(4)[💡 `clean` is not a file: `.PHONY` tells `make` to always run it, even if a file named `clean` exists]
    #only("5-")[
      ```terminal
      $ touch lib.h
      $ make
      gcc -Wall -g -c main.c -o main.o
      gcc main.o lib.o print.o -o app
      ```
    ]
  ]
]

#slide[
  == Bonus: Automatic Dependencies
  Let `gcc` write the header dependencies

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    `Makefile`
    #highlight-code(("all", (2,), (10,), "all"))[```make
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
    #set text(size: 0.85em)
    #only(1)[💡 no header is written by hand in this `Makefile`]
    #only(2)[💡 `-MMD`: while compiling `X.c`, `gcc` also writes `X.d`, with the headers it read]
    #only("3-")[💡 `-include`: read the `.d` files, if they exist (the `-` ignores the missing ones)]
    #uncover("4-")[
      ```terminal
      $ make
      ...
      $ cat main.d lib.d print.d
      main.o: main.c lib.h print.h
      lib.o: lib.c
      print.o: print.c print.h
      ```
      ✅ the rules we wrote by hand, never out of date
    ]
  ]
]

#slide[
  == `make` Cheat Sheet

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #key-table(header: ([*command*], [*what it does*]), (
      ([`make`], [build the first target]),
      ([`make clean`], [build the target `clean`]),
      ([`make -n`], [only *show* the commands (dry run)]),
      ([`make -B`], [build everything again]),
      ([`make -j8`], [run up to 8 recipes at the same time]),
      ([`make -C dir`], [use the `Makefile` from `dir`]),
      ([`make CC=clang`], [change a variable]),
    ), size: 0.85em)
  ][
    #set text(size: 0.9em)
    === Remember
    - a header goes on the rule of the `.o` of every `.c` that includes it
    - never on the rule of the executable
    - `make` compares *modification times*, it does not read the code
    - `make` is not only for C: the slides of this course are built with a `Makefile`
  ]
]
