#import "/src/slides.typ": *
#import "streams.typ": *
#import "forkexec.typ": fork-exec

#slide[
  = Redirects #text(size: 10pt, weight: "regular")[\ _Change where a process reads and writes_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.14 - _Shell Input and Output_
    - Chapter 3 - _Devices_
      - Section 3.1 - _Device Files_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 2 - _Utilizarea sistemului de fișiere_
      - Section 2.4 - _Redirectarea intrării sau ieșirii_
    - Chapter 4 - _Procese_
      - Section 4.4.2 - _Redirectarea în/din fișiere_
      - Sections 4.5.3 - 4.5.4 - _Înlănțuirea comenzilor_, _Comunicarea prin pipe-uri_
    - Chapter 8 - _Componente hardware_
      - Section 8.6 - _Abstractizarea dispozitivelor în Linux_
]

#slide[
  == `<` - redirect `stdin`
  The file *replaces* the keyboard as `stdin`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (1, 2, 5), full: false)[```terminal
    $ sort               # reads the keyboard, until Ctrl+D
    $ sort < fruits.txt  # reads fruits.txt
    apple
    banana
    cherry
    ```]
  ][
    // the table has 4 rows on step 2: keep that height on every step,
    // so the drawing under it does not move
    #let with-fd3 = fd-table("sort", (
      (0, keyboard, false),
      (1, display, false),
      (2, display, false),
      (3, file("fruits.txt"), true),
    ))
    #context {
      let h = measure(with-fd3).height
      only(1, box(height: h, fd-table("sort", ((0, keyboard, false), (1, display, false), (2, display, false)))))
      only(2, with-fd3)
      only((beginning: 3), box(height: h, fd-table("sort", (
        (0, file("fruits.txt"), true),
        (1, display, false),
        (2, display, false),
      ))))
    }
  ]

  // a bit smaller, so the two notes of the last step fit on the slide
  #align(center)[
    #set text(size: 0.9em)
    #only(1)[#one-process("sort", top-row: true)]
    #only(2)[#one-process("sort", opened-in: file("fruits.txt"), opened-fd: 3)]
    #only("3-")[#one-process("sort", redirect-in: file("fruits.txt"))]
  ]

  #set text(size: 0.9em)
  #only(1)[💡 `sort` reads its lines from `0` (`stdin`), which is the keyboard]
  #only(2)[💡 the *shell* opens `fruits.txt` for `sort`, it gets the first free index: `3`]
  #only(3)[
    💡 `<` *replaces* `stdin`: `0` is connected to `fruits.txt` instead of the keyboard, `3` is not needed anymore\
    💡 `sort` does not know that it reads a file, it still just reads from `0` (`stdin`)
  ]
]

#slide[
  == `>` - redirect `stdout`
  The process writes into a file instead of the display

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 3, 5), full: false)[```terminal
    $ ls                    # writes on the display
    Movies  notes.txt  todo.txt
    $ ls > files.txt        # nothing shows up
    $ ls /nope > files.txt
    ls: cannot access '/nope': No such file or directory
    ```]
  ][
    #only(1)[#fd-table("ls", ((0, keyboard, false), (1, display, false), (2, display, false)))]
    #only("2-")[#fd-table("ls", (
      (0, keyboard, false),
      (1, file("files.txt"), true),
      (2, display, false),
    ))]
  ]

  #align(center)[
    #only(1)[#one-process("ls", top-row: true)]
    #only("2-")[#one-process("ls", redirect-out: file("files.txt"))]
  ]

  #only(2)[⚠️ `>` _empties_ `files.txt` first (or creates it), use `>>` to *append* to it]
  #only("3-")[💡 only `1` (`stdout`) is redirected, errors still go to the display through `2`, use `2>` for them]
]

#slide[
  == `>>` - append to `stdout`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (1, 2, 5), full: false)[```terminal
    $ echo one > log.txt    # empty the file, then write
    $ echo two >> log.txt   # write at the end
    $ cat log.txt
    one
    two
    ```]
  ][
    #only(1)[#file-contents("log.txt", ("one",), new: (1,))]
    #only("2-")[#file-contents("log.txt", ("one", "two"), new: (2,))]
  ]

  #v(0.5em)
  #set text(size: 0.85em)
  #table(
    columns: (auto, 1fr, auto),
    align: (center, left, left),
    table.header([], [the shell opens the file with], [writes go]),
    [`>`], [`open("log.txt", O_WRONLY | O_CREAT | O_TRUNC)`], [after the file is *emptied*],
    [`>>`], [`open("log.txt", O_WRONLY | O_CREAT | O_APPEND)`], [at the *end*, always],
  )

  #only(1)[💡 `>` uses `O_TRUNC`: the file is emptied before `echo` writes `one`]
  #only(2)[💡 `>>` uses `O_APPEND` instead: nothing is deleted, the kernel moves every write to the end of the file]
  #only("3-")[💡 useful for logs: every command adds its lines, nothing is lost]
]

#slide[
  == `2>` - redirect `stderr`
  The errors go into a file instead of the display

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.8em)
    #only("-3")[#reveal-terminal(before: none, lines: (2, 3, 5), full: false)[```terminal
    $ ls /nope                # the error is on the display
    ls: cannot access '/nope': No such file or directory
    $ ls /nope 2> errors.txt  # nothing shows up
    $ cat errors.txt
    ls: cannot access '/nope': No such file or directory
    ```]]
    // the append example takes the place of the first one
    #only("4-")[```terminal
    $ ls /nope 2> errors.txt  # the first error
    $ ls /nada 2>> errors.txt # append the error
    $ cat errors.txt
    ls: cannot access '/nope': No such file or directory
    ls: cannot access '/nada': No such file or directory
    ```]
  ][
    #only(1)[#fd-table("ls", ((0, keyboard, false), (1, display, false), (2, display, false)))]
    #only("2-")[#fd-table("ls", ((0, keyboard, false), (1, display, false), (2, file("errors.txt"), true)))]
  ]

  #align(center)[
    #only(1)[#one-process("ls", bottom-row: true)]
    #only("2-")[#one-process("ls", redirect-err: file("errors.txt"))]
  ]

  #set text(size: 0.9em)
  #only(1)[💡 errors go through `2` (`stderr`), to the display]
  #only(2)[💡 `2>` *replaces* `stderr`: `2` is no longer connected to the display, it is connected to `errors.txt`]
  #only(3)[💡 `1` is not changed: `> out.txt 2> errors.txt` separates them, `&> all.txt` sends both to the same file]
  #only("4-")[💡 `2>>` *appends*, like `>>`: the first error stays, the new one is added at the end]
]

// the pipeline `ls | wc -l`, revealed one part per step:
// 1 - the pipe, 2 - `ls` writing into it, 3 - `wc` reading from it
#let pipeline = {
  let ls(body) = uncover("2-", body)
  let wc(body) = uncover("3-", body)
  set text(size: 0.85em)
  grid(
    columns: 13,
    column-gutter: 0.35em,
    row-gutter: 0.8em,
    align: center + horizon,
    ls(endpoint(keyboard)), ls(flow()), ls(fd(0)),
    grid.cell(rowspan: 2, ls(process("ls"))),
    ls(fd(1, changed: true)), ls(flow(changed: true)),
    pipe-buffer,
    wc(flow(changed: true)), wc(fd(0, changed: true)),
    grid.cell(rowspan: 2, wc(process("wc -l"))),
    wc(fd(1)), wc(flow()), wc(endpoint(display)),

    [], [], [],
    ls(fd(2)), ls(flow()), ls(endpoint(display)),
    [], [],
    wc(fd(2)), wc(flow()), wc(endpoint(display)),
  )
}

#slide[
  == `|` - pipe
  The `stdout` of a process becomes the `stdin` of the next one

  #align(center)[#pipeline]

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.9em)
    #uncover("1-")[#block[1. the *shell* creates a _pipe_, a buffer in the kernel with a _write_ end and a _read_ end]]
    #uncover("2-")[#block[2. it starts `ls` and places the _write end_ at index `1`]]
    #uncover("3-")[#block[3. it starts `wc` and places the _read end_ at index `0`]]
    #uncover("4-")[#block[4. both run *at the same time*: `wc` reads what `ls` writes, until `ls` ends (_end of file_)]]
  ][
    #uncover("4-")[
      ```terminal
      $ ls
      Movies  notes.txt  todo.txt
      $ ls | wc -l
      3
      ```
      💡 no temporary file is used
    ]
  ]
]

#fork-exec(redirect: true)

// A regular file and a character device side by side: both are read with
// `read`, but the bytes of a file come from the disk, the bytes of a
// device are made by its driver, nothing is stored on the disk.
#let file-vs-device = {
  let mono(s) = text(font: stream-mono, size: 0.85em, s)
  let small-process(name) = box(
    width: 9em,
    inset: (y: 0.45em),
    fill: stream-accent,
    radius: 0.3em,
    align(center, text(fill: white, weight: "bold", font: stream-mono, size: 0.8em, name)),
  )
  let part(changed: false, body) = box(
    width: 100%,
    inset: (x: 0.5em, y: 0.4em),
    radius: 0.3em,
    fill: if changed { stream-changed-fill } else { white },
    stroke: if changed { 1.2pt + stream-changed } else { 0.8pt + luma(150) },
    align(center, text(fill: if changed { stream-changed } else { black }, weight: if changed { "bold" } else { "regular" }, body)),
  )
  let no-disk = box(
    width: 100%,
    inset: (x: 0.5em, y: 0.4em),
    radius: 0.3em,
    stroke: (paint: stream-unused, thickness: 0.8pt, dash: "dashed"),
    align(center, text(fill: stream-unused, strike[💾 disk])),
  )
  let call(c) = align(center)[#text(size: 0.75em, mono("read()")) \ #draw-arrow(length: 2.6em, color: c)]
  let to(c) = align(center + horizon, draw-arrow(length: 1.8em, color: c))
  let caption(body) = align(center, text(size: 0.7em, fill: luma(110), style: "italic", body))
  set text(size: 0.9em)
  grid(
    columns: (auto, auto, 1fr, auto, 1fr, auto),
    column-gutter: 0.5em,
    row-gutter: 0.5em,
    align: horizon,
    // where each part is
    caption[process], [], caption[kernel], [], caption[hardware], [],
    // a regular file
    small-process("cat notes.txt"), call(luma(120)), part[file system], to(luma(120)), part[💾 disk],
    text(size: 0.8em)[the bytes are *stored*\ on the disk],
    // a character device
    small-process("xxd < /dev/zero"), call(stream-changed), part(changed: true)[driver #mono("1"), device #mono("5")],
    to(stream-unused), no-disk,
    text(size: 0.8em, fill: stream-changed)[the *driver makes*\ the bytes],
  )
}

#slide[
  == Special Files
  Devices made by the kernel, useful in redirects

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 4fr), gutter: 1.5em)[
    #highlight-code(((1, 2), (1, 3), (1, 4), "all"))[```
    /dev
    ├── null
    ├── zero
    └── urandom
    ```]
  ][
    #only(1)[
      === 🕳️ `/dev/null` - the black hole
      - everything *written* is _discarded_
      - *reading* gives _end of file_ right away
    ]
    #only(2)[
      === 0️⃣ `/dev/zero` - endless zeros
      - *reading* gives as many `0` bytes as asked
      - everything *written* is _discarded_
    ]
    #only(3)[
      === 🎲 `/dev/urandom` - endless random bytes
      - *reading* gives as many _random_ bytes as asked
      - used for keys, passwords, random file names
    ]
    #only("4-")[
      === all of them are _character devices_
      #set text(size: 0.9em)
      - `c` instead of `-` (file) or `d` (directory), *not files*: nothing is stored on the disk
      - `1, 3` - the _driver_ (major `1`) and the device (minor `3`) that answer
      #v(0.2em)
      #file-vs-device
    ]
    #set text(size: 0.9em)
    #only(1)[```terminal
    $ ls /nope 2> /dev/null   # the error is discarded
    $ cat < /dev/null         # nothing to read
    ```]
    #only(2)[```terminal
    $ xxd -l 8 < /dev/zero    # show the first 8 bytes
    00000000: 0000 0000 0000 0000            ........
    ```]
    #only(3)[```terminal
    $ xxd -l 8 < /dev/urandom
    00000000: 9f3a 51c2 07e8 b4d1            .:Q.....
    $ xxd -l 8 < /dev/urandom # different every time
    00000000: 4be0 1d77 c3a9 0f62            K..w...b
    ```]
  ]

  #align(center)[
    #set text(size: 0.9em)
    #only(1)[#one-process("ls /nope", stderr: file("/dev/null"), changed: (2,), endpoint-width: 9em)]
    #only(2)[#one-process("xxd -l 8", stdin: file("/dev/zero"), changed: (0,), endpoint-width: 9em)]
    #only(3)[#one-process("xxd -l 8", stdin: file("/dev/urandom"), changed: (0,), endpoint-width: 9em)]
  ]

  // the `ls` at the bottom of the slide, in the place of the drawing;
  // the first letter (the file type) is boxed: gray for a regular file and
  // a directory, orange for the character devices
  #only("4-")[#place(bottom + left, block(width: 100%)[
    #set align(left)
    #set text(size: 0.85em)
    #show raw.line: it => {
      let t = it.text
      if t.starts-with("$ ") {
        text(fill: stream-accent, weight: "bold", t)
      } else {
        let (kind, rest) = (t.first(), t.slice(1))
        let (c, fill) = if kind == "c" { (white, stream-changed) } else { (black, luma(200)) }
        let (listing, comment) = if rest.contains("#") { rest.split("#") } else { (rest, none) }
        box(fill: fill, outset: (x: 1pt, y: 2pt), radius: 1pt, text(fill: c, weight: "bold", kind))
        listing
        if comment != none {
          let c = if kind == "c" { stream-changed } else { luma(110) }
          // an arrow pointing left, drawn (the ← glyph is missing from some fonts)
          box(scale(x: -100%, draw-arrow(length: 1.2em, color: c, thickness: 1.2pt)))
          text(fill: c, weight: "bold", " " + comment.trim())
        }
      }
    }
    ```
    $ ls -ld /etc/hostname /dev /dev/null /dev/zero /dev/urandom
    -rw-r--r--  1 root root    7 Oct  2 09:12 /etc/hostname  # regular file
    drwxr-xr-x 18 root root 3960 Oct  2 09:12 /dev           # directory
    crw-rw-rw-  1 root root 1, 3 Oct  2 09:12 /dev/null      # character device
    crw-rw-rw-  1 root root 1, 5 Oct  2 09:12 /dev/zero      # character device
    crw-rw-rw-  1 root root 1, 9 Oct  2 09:12 /dev/urandom   # character device
    ```
  ])]
]

#slide[
  == Redirects Cheat Sheet
  Trick processes about the keyboard, display and error display

  // 20 lines, shrink them so the listing fits on one slide
  #set text(size: 0.82em)
  #set par(leading: 0.5em)
  #highlight-code(
    ((), (1, 2), (4, 5), (7, 8), (10, 11), (13, 14), (16, 17), (19, 20), "all"),
  )[```bash
  # Redirect stdout (standard output) to a file
  ls > files.txt                      # Save the list of files into files.txt

  # Append stdout to a file instead of overwriting it
  ls >> files.txt                     # Add more output to files.txt

  # Redirect stderr (standard error) to a file
  ls /nonexistent 2> errors.txt       # Save only the error message to errors.txt

  # Redirect both stdout and stderr to the same file
  ls /etc /nonexistent > all.txt 2>&1 # Combine normal output and errors into all.txt

  # Shortcut for redirecting both stdout and stderr (Bash 4+)
  ls /etc /nonexistent &> all.txt     # Equivalent to the previous command

  # Redirect stdin (standard input) from a file
  sort < input.txt                    # Read lines from input.txt and sort them

  # Redirect stdin and stdout at once
  sort < unsorted.txt > sorted.txt    # Sort contents of unsorted.txt into sorted.txt
  ```]
]

#slide[
  == Advanced Redirects
  Trick processes about the keyboard, display and error display

  #highlight-code(((), (1, 2), (4, 5), lines-range(7, 11), "all"))[```bash
  # Suppress all output (stdout and stderr)
  command > /dev/null 2>&1            # Run silently; discard all output and errors

  # Redirect stderr to stdout and pipe to another command
  command 2>&1 | grep "warning"       # Merge both streams, then search for "warning"

  # Use a heredoc (redirect stdin from inline text)
  cat <<EOF                           # 'cat' reads the next lines, up to EOF
  Hello, world!
  This is a heredoc example.
  EOF
  ```]

  #uncover(4)[💡 the lines of a heredoc are sent _as they are_ to `stdin`, a `#` there is not a comment]
]
