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
  ("hello.i", [C, preprocessed], "-E"),
  ("hello.s", [assembly], "-S"),
  ("hello.o", [object file], "-c"),
  ("hello", [executable], ""),
)
// (tool, the program gcc runs)
#let pipe-tools = (
  ([preprocessor], "cpp"),
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
    let fb = stack(
      spacing: 0.3em,
      file-box(f, sub: what, on: file-on, width: 62pt),
      if flags and flag != none {
        text(font: mono, size: 0.62em, fill: if file-on { changed } else { luma(110) })[gcc #flag]
      } else { text(size: 0.62em)[ ] },
    )
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

#slide[
  == Four Steps
  `gcc hello.c -o hello` runs all of them, one after the other

  #v(0.8em)
  #for i in range(1, 5) {
    only(i, pipeline(on: i, upto: i))
  }
  #only("5-", pipeline())


  #v(1fr)
  #only(1)[💡 *preprocessor*: copies the `#include` files, replaces the `#define`s, removes the comments]
  #only(2)[💡 *compiler*: translates C to *assembly*, the text form of the CPU instructions]
  #only(3)[💡 *assembler*: translates assembly to *machine code*, an object file]
  #only(4)[💡 *linker*: puts the object files and the libraries together, into an executable]
  #only("5-")[💡 every option *stops* after one step: `-E`, `-S`, `-c`; the temporary files go to `/tmp`]
]

#slide[
  == The Example

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    `hello.c`
    ```c
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
  ][
    #uncover("2-")[
      ```terminal
      $ gcc hello.c -o hello
      $ ./hello
      Hello, 0!
      Hello, 1!
      Hello, 2!
      ```
    ]
    #uncover("3-")[#block[
      - `#include` and `#define`: for the *preprocessor*
      - the comment: for us
      - `printf` is not written here, it is in the C library (`libc`)
    ]]
  ]
]

#slide[
  == 1. Preprocessor: `gcc -E`
  #pipeline(on: 1, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    ```terminal
    $ gcc -E hello.c -o hello.i
    $ wc -l hello.c hello.i
       12 hello.c
      825 hello.i
    $ grep printf hello.i | head -1
    extern int printf (const char *__restrict __format, ...);
    ```
  ][
    #set text(size: 0.9em)
    #uncover("2-")[
      `tail hello.i`
      ```c
      # 5 "hello.c"
      int main(void)
      {

          for (int i = 0; i < 3; i++) {
              printf("Hello, %d!\n", i);
          }
          return 0;
      }
      ```
    ]
  ]

  #v(1fr)
  #only(1)[💡 `#include <stdio.h>` is replaced by the whole `stdio.h`: 800 lines of declarations, among them `printf`]
  #only("2-")[💡 `TIMES` became `3`, the comment is gone; `# 5 "hello.c"` tells the compiler the original line, for the error messages]
]

#slide[
  == 2. Compiler: `gcc -S`
  #pipeline(on: 2, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    ```terminal
    $ gcc -S hello.c
    $ ls
    hello.c  hello.s
    ```
    #uncover("2-")[#block[
      - *assembly*: one line per CPU instruction, still a text file
      - for *one* processor: this is x86-64
      - the loop became a compare (`cmpl`) and a jump (`jle`)
      - `printf` is only *called*, its code is not here
    ]]
  ][
    #set text(size: 0.75em)
    `hello.s` (excerpt)
    ```asm
    .LC0:
        .string "Hello, %d!\n"
    main:
        ...
        movl    $0, -4(%rbp)
        jmp     .L2
    .L3:
        ...
        leaq    .LC0(%rip), %rax
        movq    %rax, %rdi
        call    printf@PLT
        addl    $1, -4(%rbp)
    .L2:
        cmpl    $2, -4(%rbp)
        jle     .L3
    ```
  ]
]

#slide[
  == 3. Assembler: `gcc -c`
  #pipeline(on: 3, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    ```terminal
    $ gcc -c hello.c
    $ file hello.o
    hello.o: ELF 64-bit LSB relocatable, x86-64, ...
    $ nm hello.o
    0000000000000000 T main
                     U printf
    ```
    #uncover("2-")[#block[
      - an *object file*: machine code, not runnable yet
      - `T main`: defined here (in the _text_ section)
      - `U printf`: used here, *undefined*
    ]]
  ][
    #uncover("3-")[
      #set text(size: 0.8em)
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
    ]
    #uncover("4-")[
      💡 `e8` is `call`, the address of `printf` is still `00 00 00 00`: the *linker* will fill it in
    ]
  ]
]

#slide[
  == 4. Linker: `gcc`
  #pipeline(on: 4, flags: false)

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    ```terminal
    $ gcc hello.o -o hello
    $ file hello
    hello: ELF 64-bit LSB pie executable, x86-64, dynamically linked, ...
    $ nm hello | grep -E 'main|printf'
    0000000000001149 T main
                     U printf@GLIBC_2.2.5
    ```
  ][
    #set text(size: 0.85em)
    #uncover("2-")[
      ```terminal
      $ ldd hello
      linux-vdso.so.1 (0x00007fbadcce3000)
      libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
      /lib64/ld-linux-x86-64.so.2
      ```
    ]
    #uncover("3-")[#block[
      - the linker joins the object files and the startup code
      - `printf` stays in `libc.so.6`, a *shared library*: the loader (`ld-linux`) finds it when the program starts
    ]]
  ]
]

#slide[
  == Several Source Files
  Compile each file to an object file, then link them together

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    ```terminal
    $ gcc -c main.c
    $ gcc -c lib.c
    $ gcc -c print.c
    $ gcc main.o lib.o print.o -o app
    $ ./app
    sum = 55
    ```
    #uncover("2-")[#block[
      💡 change `print.c`: compile *only* `print.c` again, then link
    ]]
  ][
    #set text(size: 0.9em)
    #uncover("3-")[
      ```terminal
      $ gcc main.o print.o -o app
      /usr/bin/ld: main.o: in function `main':
      main.c:(.text+0x12): undefined reference to `sum'
      collect2: error: ld returned 1 exit status
      ```
    ]
    #uncover("4-")[#block[
      - `main.c` compiled fine: `lib.h` *declares* `sum`
      - the linker needs the *definition*, from `lib.o`
      - `ld`: a *linker* error, not a compiler error
    ]]
  ]
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

#slide[
  == Inside the Compiler
  Many languages, many processors, one compiler

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #align(center, diagram("img/book/comp-backend-frontend.svg", height: 72%))
    #text(size: 0.7em)[from the USO book]
  ][
    #set text(size: 0.9em)
    - a *front end* per language: C, C++, D, Rust, ...
    - translates to an *intermediate representation* (IR)
    - optimizes the IR, the same for all languages
    - a *back end* per processor: x86-64, ARM, RISC-V, ...
    #uncover("2-")[#block[
      #v(0.5em)
      === Examples
      - GCC: C, C++, Fortran, Ada, Go, D, ...
      - LLVM: `clang` (C, C++), `rustc`, `swiftc`, `zig`
    ]]
  ]
]
