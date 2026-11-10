#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = The C Compilation Pipeline #text(size: 10pt, weight: "regular")[\ _From `hello.c` to an executable, in four steps_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #ward
    - Chapter 15 - _Development Tools_
      - Section 15.1 - _The C Compiler_
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.3 - _Limbaje compilate_
      - Section 6.7.1 - _C / C++_
]

// the pipeline: (file, what it contains, the option that stops there)
#let pipe-files = (
  ("hello.c", [C source], none),
  ("hello.i", [preprocessed], "-E"),
  ("hello.s", [assembly], "-S"),
  ("hello.o", [object file], "-c"),
  ("hello", [executable], ""),
)
// (tool, the program gcc runs): `cc1` does both the preprocessor and the
// compiler steps, in one run (`gcc -v` shows only `cc1`, `as`, `collect2`)
#let pipe-tools = (
  ([preprocessor], "cc1"),
  ([compiler], "cc1"),
  ([assembler], "as"),
  ([linker], "ld"),
)

// the pipeline drawing, step `on` (1 - 4) is highlighted, `upto` hides
// the steps after it (they keep their space)
#let pipeline(on: none, upto: 4, flags: true) = {
  let cells = ()
  for (i, (f, what, flag)) in pipe-files.enumerate() {
    let file-on = on != none and i == on
    let shown = i <= upto
    let fbx = file-box(f, sub: what, on: file-on, width: 62pt)
    // without the flags, no line under the files: the drawing stays short
    let fb = if not flags { fbx } else {
      stack(
        spacing: 0.3em,
        fbx,
        if flag != none {
          text(font: mono, size: 0.62em, fill: if file-on { changed } else { luma(110) })[gcc #flag]
        } else { text(size: 0.62em)[ ] },
      )
    }
    cells.push(if shown { fb } else { hide(fb) })
    if i < pipe-tools.len() {
      let (tool, prog) = pipe-tools.at(i)
      let t-on = on != none and i + 1 == on
      let c = if t-on { changed } else { accent }
      let ar = stack(
        spacing: 0.2em,
        text(size: 0.6em, weight: "bold", fill: c, tool),
        draw-arrow(length: 3.2em, color: c),
        text(font: mono, size: 0.6em, fill: c, prog + if i == 3 { " + libc" } else { "" }),
      )
      cells.push(if i + 1 <= upto { ar } else { hide(ar) })
    }
  }
  align(center, grid(columns: cells.len(), column-gutter: 0.25em, align: center + horizon, ..cells))
}

// the programs gcc runs for the four steps, as chips joined by arrows:
// `cc1` does the first two steps (preprocessor + compiler) in one run
#let gcc-programs = (
  ([preprocessor + compiler], "cc1"),
  ([assembler], "as"),
  ([linker], "ld"),
)
#let gcc-steps = {
  let cells = ()
  for (i, (tool, prog)) in gcc-programs.enumerate() {
    cells.push(stack(
      spacing: 0.3em,
      box(fill: changed-fill, stroke: 1pt + changed, radius: 0.25em, inset: (x: 0.5em, y: 0.3em),
        text(font: mono, weight: "bold", fill: changed, prog)),
      text(size: 0.75em, fill: luma(90), tool),
    ))
    if i < gcc-programs.len() - 1 {
      // pushed down to the middle of the chips
      cells.push(pad(top: 0.45em, draw-arrow(length: 1.4em, color: changed)))
    }
  }
  align(center, grid(columns: cells.len(), column-gutter: 0.3em, align: center + top, ..cells))
}

#let hello-c = ```c
#include <stdio.h>

#define TIMES 3

int main(void)
{
    // say hello a few times
    for (int i = 0; i < TIMES; i++) {
        printf("Hello, %d!\n", i);
    }
    return 0;
}
```

#slide[
  == The Example
  A small C program, compiled and run

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #code-file("hello.c", hello-c)
  ][
    ```terminal
    $ gcc hello.c -o hello
    $ ./hello
    Hello, 0!
    Hello, 1!
    Hello, 2!
    ```
    - `#include` and `#define`: for the *preprocessor*
    - the comment: for us
    - `printf` is not written here, it is in the C library (`libc`)
  ]

  // popup, placed over the slide: nothing moves when it appears
  #only(2)[
    #place(bottom + right, dy: -0.3em, popup(width: 330pt)[
      🔍 Behind the scenes
    ][
      `gcc hello.c -o hello` does *four* steps, with *three* programs
      #v(0.3em)
      #gcc-steps
    ])
  ]
]

#slide[
  == 0. The C Source: `hello.c`
  One command, four steps

  #pipeline(on: 0, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #code-file("hello.c", hello-c)
  ][
    #set text(size: 0.8em)
    ```terminal
    $ gcc hello.c -o hello
    $ ./hello
    Hello, 0!
    Hello, 1!
    Hello, 2!
    ```
  ]

  #v(1fr)
  💡 behind one `gcc` command, *four* steps: `cc1` does the first two, `as` and `ld` the others
]

#slide[
  == 1. Preprocessor: `gcc -E`
  Copies the `#include` files, replaces the `#define`s, removes the comments

  #pipeline(on: 1, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    ```terminal
    $ gcc -E hello.c -o hello.i
    $ wc -l hello.c hello.i
       12 hello.c
      825 hello.i
    $ grep printf hello.i | head -1
    extern int printf (const char *__restrict __format, ...);
    ```
  ][
    #set text(size: 0.8em)
    #code-file("hello.i (the last lines)")[```c
    # 5 "hello.c"
    int main(void)
    {

        for (int i = 0; i < 3; i++) {
            printf("Hello, %d!\n", i);
        }
        return 0;
    }
    ```]
  ]

  #v(1fr)
  💡 `stdio.h` is copied in (800 lines, `printf` among them), `TIMES` became `3`, the comment is gone
]

#slide[
  == 2. Compiler: `gcc -S`
  Translates C to *assembly*, the text form of the CPU instructions

  #pipeline(on: 2, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    ```terminal
    $ gcc -S hello.c
    $ ls
    hello.c  hello.s
    ```
    - *assembly*: one line per CPU instruction, still a text file
    - for *one* processor: this is x86-64
    - the loop became a compare (`cmpl`) and a jump (`jle`)
    - `printf` is only *called*, its code is not here
  ][
    #set text(size: 0.68em)
    #code-file("hello.s (excerpt)")[```asm
    main:
        ...
        movl    $0, -4(%rbp)
        jmp     .L2
    .L3:
        ...
        call    printf@PLT
        addl    $1, -4(%rbp)
    .L2:
        cmpl    $2, -4(%rbp)
        jle     .L3
    ```]
  ]
]

#slide[
  == 3. Assembler: `gcc -c`
  Translates assembly to *machine code*: an object file

  #pipeline(on: 3, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    ```terminal
    $ gcc -c hello.c
    $ file hello.o
    hello.o: ELF 64-bit LSB relocatable, x86-64, ...
    $ nm hello.o
    0000000000000000 T main
                     U printf
    ```
    - an *object file*: machine code, not runnable yet
    - `T main`: defined here (in the _text_ section)
    - `U printf`: used here, *undefined*
  ][
    #set text(size: 0.72em)
    ```terminal
    $ objdump -d hello.o
    0000000000000000 <main>:
       4: 55               push %rbp
       5: 48 89 e5         mov  %rsp,%rbp
      ...
      24: b8 00 00 00 00   mov  $0x0,%eax
      29: e8 00 00 00 00   call 2e <main+0x2e>
      2e: 83 45 fc 01      addl $0x1,-0x4(%rbp)
    ```
    💡 `e8` is `call`, to address `00 00 00 00`: the *linker* fills in `printf`
  ]
]

// an option that matters, marked in a terminal block; use it as a show rule
// on the exact token, e.g. #show regex("^-static$"): mark-option
// (`^...$`: the whole token, so `hello-static` is not marked)
#let mark-option(it) = box(
  fill: changed-fill, stroke: 1pt + changed, radius: 2pt,
  inset: (x: 2pt), outset: (y: 2pt),
  text(fill: changed, weight: "bold", it),
)

// the takeaway of a slide, softer than a callout: a light background and
// an orange bar on the left
#let takeaway(body) = block(
  width: 100%,
  fill: changed-fill.lighten(30%),
  stroke: (left: 3pt + changed),
  radius: (right: 0.3em),
  inset: (x: 0.8em, y: 0.45em),
  text(size: 0.85em, body),
)

// what the linker does: joins hello.o and the startup code (Scrt1.o) into
// hello; libc.so.6 is only checked for printf, it is loaded when hello runs
#let linker-drawing = drawing(width: 290pt, height: 150pt, {
  let gray = luma(120)
  // inputs on the left, ld in the middle, the executable on the right
  pin(48pt, 28pt, file-box("hello.o", sub: [`main`, calls `printf`], width: 96pt))
  pin(48pt, 82pt, file-box("Scrt1.o", sub: [startup code], width: 96pt))
  pin(145pt, 55pt, tool-box("ld", sub: [linker]))
  pin(245pt, 55pt, file-box("hello", sub: [`_start` + `main`], on: true, width: 82pt))
  pin(145pt, 132pt, file-box("libc.so.6", sub: [`printf`, ...], width: 82pt))
  // the object files go into the executable
  line-arrow((98pt, 34pt), (122pt, 49pt), color: gray)
  line-arrow((98pt, 76pt), (122pt, 61pt), color: gray)
  line-arrow((168pt, 55pt), (202pt, 55pt), color: changed, thickness: 1.5pt)
  // libc: checked by ld, loaded at run time (dashed: not copied)
  line-arrow((145pt, 114pt), (145pt, 76pt), color: gray, dash: "dashed")
  pin(110pt, 108pt, arrow-label[has `printf`?])
  line-arrow((220pt, 76pt), (188pt, 120pt), color: gray, dash: "dashed")
  pin(250pt, 104pt, arrow-label[loaded at run time])
})

#slide[
  == 4. Linker: `gcc`
  Puts the object files and the libraries together, into an executable

  #pipeline(on: 4, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    ```terminal
    $ gcc hello.o -o hello
    $ file hello
    hello: ELF 64-bit ..., dynamically linked, ...
    $ ldd hello
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
    ...
    ```
  ][
    // drawn 290pt x 150pt: at most 80% (120pt tall), less if the column is narrower
    #layout(size => scale(calc.min(80%, size.width / 290pt * 100%), origin: top + left, reflow: true, linker-drawing))
  ]

  #v(1fr)
  #takeaway[💡 `printf` is *not copied*: it stays in `libc.so.6`, a *shared library*]
]

// the same, linked statically: ld copies printf (and what it needs) from
// libc.a into the executable, nothing is loaded at run time
#let static-linker-drawing = drawing(width: 290pt, height: 150pt, {
  let gray = luma(120)
  pin(48pt, 28pt, file-box("hello.o", sub: [`main`, calls `printf`], width: 96pt))
  pin(48pt, 82pt, file-box("crt1.o", sub: [startup code], width: 96pt))
  pin(145pt, 55pt, tool-box("ld", sub: [linker]))
  pin(240pt, 55pt, file-box("hello-static", sub: [`_start` + `main` \ + `printf`, ...], on: true, width: 96pt))
  pin(145pt, 132pt, file-box("libc.a", sub: [`printf`, ... (archive)], width: 96pt))
  line-arrow((98pt, 34pt), (122pt, 49pt), color: gray)
  line-arrow((98pt, 76pt), (122pt, 61pt), color: gray)
  line-arrow((168pt, 55pt), (190pt, 55pt), color: changed, thickness: 1.5pt)
  // libc.a: solid, its code is copied into the executable
  line-arrow((145pt, 114pt), (145pt, 76pt), color: changed, thickness: 1.5pt)
  pin(118pt, 100pt, arrow-label[copied in])
  pin(240pt, 106pt, align(center, arrow-label[nothing to load \ at run time]))
})

#slide[
  == Static Executable: `gcc -static`
  Copies the library code into the executable

  #pipeline(on: 4, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    #show regex("^-static$"): mark-option
    ```terminal
    $ gcc -static hello.o -o hello-static
    $ file hello-static
    hello-static: ELF 64-bit ..., statically linked, ...
    $ ldd hello-static
    not a dynamic executable
    $ ls -sh hello hello-static
      12K hello  636K hello-static
    ```
  ][
    #layout(size => scale(calc.min(80%, size.width / 290pt * 100%), origin: top + left, reflow: true, static-linker-drawing))
  ]

  #v(1fr)
  #takeaway[💡 runs *without* `libc.so.6`, but *every program* carries its own copy of `printf`]
]

// our own static library: ar packs lib.o into libsum.a; ld copies sum
// from it into app, nothing is loaded at run time
#let static-lib-drawing = drawing(width: 290pt, height: 150pt, {
  let gray = luma(120)
  pin(48pt, 28pt, file-box("lib.o", sub: [`sum`], width: 96pt))
  pin(145pt, 28pt, tool-box("ar", sub: [archive]))
  pin(245pt, 28pt, file-box("libsum.a", sub: [`lib.o`, ...], on: true, width: 82pt))
  line-arrow((98pt, 28pt), (122pt, 28pt), color: gray)
  line-arrow((168pt, 28pt), (202pt, 28pt), color: changed, thickness: 1.5pt)
  pin(48pt, 110pt, file-box("main.o", sub: [calls `sum`], width: 96pt))
  pin(145pt, 110pt, tool-box("ld", sub: [`-lsum`]))
  pin(245pt, 110pt, file-box("app", sub: [`main` + `sum`], width: 82pt))
  line-arrow((98pt, 110pt), (122pt, 110pt), color: gray)
  line-arrow((168pt, 110pt), (202pt, 110pt), color: gray)
  // the code of sum is copied into app (solid)
  line-arrow((225pt, 46pt), (165pt, 92pt), color: changed, thickness: 1.5pt)
  pin(232pt, 68pt, arrow-label[copied in])
})

#slide[
  == Static Library: `ar`
  Our own `.a`, an archive of object files, copied into every program

  #pipeline(on: 4, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.8em)
    #show regex("^(ar|rcs|-lsum)$"): mark-option
    ```terminal
    $ gcc -c lib.c -o lib.o
    $ ar rcs libsum.a lib.o
    $ ar t libsum.a
    lib.o
    $ gcc main.o -L. -lsum -o app
    $ ./app
    sum: 55
    ```
  ][
    #layout(size => scale(calc.min(80%, size.width / 290pt * 100%), origin: top + left, reflow: true, static-lib-drawing))
  ]

  #v(1fr)
  #takeaway[💡 `app` runs without `libsum.a`; change `lib.c`: rebuild `libsum.a` *and* link `app` again]
]

// our own shared library: ld -shared turns lib.o into libsum.so; app only
// records that it needs libsum.so, the loader finds it when app runs
#let shared-linker-drawing = drawing(width: 290pt, height: 150pt, {
  let gray = luma(120)
  pin(48pt, 28pt, file-box("lib.o", sub: [`sum`, `-fPIC`], width: 96pt))
  pin(145pt, 28pt, tool-box("ld", sub: [`-shared`]))
  pin(245pt, 28pt, file-box("libsum.so", sub: [`sum`], on: true, width: 82pt))
  line-arrow((98pt, 28pt), (122pt, 28pt), color: gray)
  line-arrow((168pt, 28pt), (202pt, 28pt), color: changed, thickness: 1.5pt)
  pin(48pt, 110pt, file-box("main.o", sub: [calls `sum`], width: 96pt))
  pin(145pt, 110pt, tool-box("ld", sub: [`-lsum`]))
  pin(245pt, 110pt, file-box("app", sub: [`main`, needs `libsum.so`], width: 82pt))
  line-arrow((98pt, 110pt), (122pt, 110pt), color: gray)
  line-arrow((168pt, 110pt), (202pt, 110pt), color: gray)
  // app is not given a copy: libsum.so is loaded at run time (dashed)
  line-arrow((245pt, 46pt), (245pt, 90pt), color: gray, dash: "dashed")
  pin(245pt, 68pt, arrow-label[loaded at run time])
})

#slide[
  == Shared Library: `gcc -shared`
  Our own `.so`, loaded by every program that uses it

  #pipeline(on: 4, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.72em)
    #show regex("^-(shared|fPIC|lsum)$"): mark-option
    ```terminal
    $ gcc -fPIC -c lib.c -o lib.o
    $ gcc -shared lib.o -o libsum.so
    $ gcc main.o -L. -lsum -o app
    $ ldd app
    libsum.so => not found
    $ LD_LIBRARY_PATH=. ./app
    sum: 55
    ```
  ][
    #layout(size => scale(calc.min(80%, size.width / 290pt * 100%), origin: top + left, reflow: true, shared-linker-drawing))
  ]

  #v(1fr)
  #v(-0.4em)
  #text(size: 0.75em)[⚠️ the loader looks for `libsum.so` only in the system folders (`/usr/lib`, ...): *install* it there, or point to it with `LD_LIBRARY_PATH`]
  #v(-0.4em)
  #takeaway[💡 change `lib.c`, rebuild `libsum.so`: every program gets the new code *without* linking again]
]

// a timeline of two builds of app (main.c, lib.c, print.c), animated one
// gcc command per step:
// - all: true  -> `gcc main.c lib.c print.c`: step 1 the first build, 2 the
//   edit of print.c, 3 the rebuild, every file again (red: main.c and lib.c
//   did not change)
// - all: false -> `gcc -c` for each file: steps 1-4 the first build, 5 the
//   edit, 6-7 the rebuild, only print.c (orange), main.o and lib.o are kept
//   (dashed, gray)
// the two versions use the same scale, so the rebuilds can be compared
#let build-timeline(all: false) = drawing(width: 440pt, height: 146pt, {
  let bh = 18pt
  // kind: "first", "on" (orange, needed), "bad" (red, not needed), "kept"
  let bar(x, y, w, body, kind: "first") = place(top + left, dx: x, dy: y - bh / 2, box(
    width: w, height: bh, radius: 3pt,
    fill: (first: rgb("eef3f5"), on: changed-fill, bad: bad-fill, kept: none).at(kind),
    stroke: (
      first: 1pt + accent,
      on: 1.2pt + changed,
      bad: 1.2pt + bad-color,
      kept: (paint: luma(160), thickness: 0.8pt, dash: "dashed"),
    ).at(kind),
    align(center + horizon, text(font: mono, size: 7.5pt,
      fill: (first: accent, on: changed, bad: bad-color, kept: luma(140)).at(kind), body)),
  ))
  // shown from step `n` on (uncover: it keeps its space)
  let at(n, body) = uncover(str(n) + "-", body)
  for (name, y) in (("main.c", 24pt), ("lib.c", 48pt), ("print.c", 72pt), ("link", 96pt)) {
    place(top + left, dx: 0pt, dy: y - 6pt, text(font: mono, size: 9pt, name))
  }
  // first build: everything, one after the other
  // the step of each part (one gcc command per step)
  let (s-main, s-lib, s-print, s-app, s-edit) = if all { (1, 1, 1, 1, 2) } else { (1, 2, 3, 4, 5) }
  at(s-main, bar(62pt, 24pt, 42pt, "main.o"))
  at(s-lib, bar(107pt, 48pt, 42pt, "lib.o"))
  at(s-print, bar(152pt, 72pt, 42pt, "print.o"))
  at(s-app, bar(197pt, 96pt, 32pt, "app"))
  at(s-app, pin(146pt, 116pt, arrow-label[first build: every file]))
  // the change
  at(s-edit, wire((245pt, 12pt), (245pt, 106pt), stroke: (paint: changed, thickness: 1pt, dash: "dashed")))
  at(s-edit, pin(245pt, 5pt, text(size: 7.5pt, fill: changed, weight: "bold")[edit `print.c`]))
  if all {
    at(3, bar(262pt, 24pt, 42pt, "main.o", kind: "bad"))
    at(3, bar(307pt, 48pt, 42pt, "lib.o", kind: "bad"))
    // main.o and lib.o did not change: crossed out, wasted work
    let cross = (paint: bad-color.transparentize(45%), thickness: 1pt)
    for (x, y) in ((262pt, 24pt), (307pt, 48pt)) {
      at(3, wire((x + 2pt, y - bh / 2 + 2pt), (x + 40pt, y + bh / 2 - 2pt), stroke: cross))
      at(3, wire((x + 2pt, y + bh / 2 - 2pt), (x + 40pt, y - bh / 2 + 2pt), stroke: cross))
    }
    at(3, place(top + left, dx: 354pt, dy: 17pt, text(size: 7pt, fill: bad-color, weight: "bold")[
      `main.c`, `lib.c` did not \ change: wasted work
    ]))
    at(3, bar(352pt, 72pt, 42pt, "print.o", kind: "on"))
    at(3, bar(397pt, 96pt, 32pt, "app", kind: "on"))
    at(3, pin(345pt, 116pt, text(size: 0.65em, fill: bad-color, style: "italic")[rebuild: every file *again*]))
  } else {
    at(6, bar(262pt, 24pt, 42pt, "main.o", kind: "kept"))
    at(6, bar(262pt, 48pt, 42pt, "lib.o", kind: "kept"))
    at(6, bar(262pt, 72pt, 42pt, "print.o", kind: "on"))
    at(7, bar(307pt, 96pt, 32pt, "app", kind: "on"))
    at(7, pin(290pt, 116pt, arrow-label[rebuild: only `print.c`]))
  }
  // time
  line-arrow((62pt, 134pt), (436pt, 134pt), color: luma(120))
  place(top + left, dx: 405pt, dy: 136pt, arrow-label[time])
})

// the timeline, centered, at most 90%, smaller if the slide is narrower
#let fit-timeline(all: false) = layout(size => align(center, scale(
  calc.min(90%, size.width / 440pt * 100%), origin: top, reflow: true, build-timeline(all: all),
)))

#slide[
  == Compile Everything, Every Time?
  `gcc` with a list of source files compiles *all* of them, every time

  #fit-timeline(all: true)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    // every .c file in a command is marked: it is compiled
    #show regex("^\w+\.c$"): mark-option
    #reveal-terminal(before: none, lines: (1,), full: false)[```terminal
    $ gcc main.c lib.c print.c -o app
    ```]
  ][
    #set text(size: 0.75em)
    #show regex("^\w+\.c$"): mark-option
    #reveal-terminal(start: 2, before: none, lines: (1, 2), full: false)[```terminal
    $ vim print.c                # edit
    $ gcc main.c lib.c print.c -o app
    ```]
  ]

  #v(1fr)
  #uncover("3-")[
    #takeaway[💡 the Linux kernel has over 30 000 `.c` files: compiling all of them again takes many minutes, for one changed file]
  ]
]

#slide[
  == Several Source Files
  Compile each file to an object file, then link them together

  #fit-timeline(all: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.75em)
    #reveal-terminal(before: none, lines: (1, 2, 3, 4), full: false)[```terminal
    $ gcc -c main.c
    $ gcc -c lib.c
    $ gcc -c print.c
    $ gcc main.o lib.o print.o -o app
    ```]
  ][
    #set text(size: 0.75em)
    #reveal-terminal(start: 5, before: none, lines: (1, 2, 3), full: false)[```terminal
    $ vim print.c                # edit
    $ gcc -c print.c
    $ gcc main.o lib.o print.o -o app
    ```]
  ]
]

// one kind of build error, a row of the error table below: the problem,
// who reports it (the stage of the pipeline) and the fix on the left, the
// terminal (as wide as possible, so it can be large) on the right
#let error-row(n, what, who, session, fix) = (
  uncover(str(n) + "-")[
    *#what* \
    #text(size: 0.75em, fill: luma(90))[#who] \
    #text(size: 0.75em)[✅ #fix]
  ],
  uncover(str(n) + "-", block(width: 100%, {
    set text(size: 1em)
    // the error message itself, in red
    show regex("(fatal )?error: .*|undefined reference to .*"): set text(fill: bad-color, weight: "bold")
    // a warning: the build goes on, but the program may be wrong
    show regex("warning: .*"): set text(fill: changed, weight: "bold")
    session
  })),
)

#slide[
  == Build Errors
  Who reports the error tells you what is wrong

  #table(
    columns: (auto, 1fr),
    align: (left + horizon, left + horizon),
    inset: (x: 0.4em, y: 0.4em),
    stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
    table.header([*problem*], [*error*]),
    ..error-row(1, [missing `.h`], [preprocessor, `gcc -E`], ```terminal
    $ gcc -c main.c
    main.c: fatal error: lib.h: No such file or directory
    ```, [fix `#include` or `-I dir`]),
    ..error-row(2, [missing prototype], [compiler, `gcc -S`], ```terminal
    $ gcc -c main.c      # GCC 14 and later: an error
    main.c: warning: implicit declaration of function ‘sum’
    ```, [declare it in `lib.h`]),
    ..error-row(3, [missing `.o`], [linker, `ld`], ```terminal
    $ gcc main.o print.o -o app
    main.c:(.text+0x12): undefined reference to `sum'
    ```, [add `lib.o`]),
    ..error-row(4, [missing library], [linker, `ld`], ```terminal
    $ gcc root.o -o root
    root.c:(.text+0x18): undefined reference to `sqrt'
    ```, [add `-lm` (`libm`)]),
  )

]

#slide[
  == Stop After Each Step

  #set text(size: 0.9em)
  #align(center)[
    #table(
      columns: (auto, auto, auto, auto),
      align: (left + horizon, left + horizon, left + horizon, left + horizon),
      inset: 0.5em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([*command*], [*stops after*], [*writes*], [*look at it with*]),
      [`gcc -E hello.c -o hello.i`], [preprocessor], [`hello.i`, C], [`less`],
      [`gcc -S hello.c`], [compiler], [`hello.s`, assembly], [`less`],
      [`gcc -c hello.c`], [assembler], [`hello.o`, object file], [`nm`, `objdump -d`],
      [`gcc hello.o -o hello`], [linker], [`hello`, executable], [`file`, `ldd`, `./hello`],
    )
  ]

  #uncover("2-")[
    ```terminal
    $ gcc -save-temps hello.c -o hello
    $ ls
    hello  hello.c  hello.i  hello.o  hello.s
    ```
  ]
  #uncover("3-")[
    💡 `gcc` is a _driver_: `gcc -v` shows the programs it runs, `cc1`, `as` and `collect2` (which runs `ld`)
  ]
]
