#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Debuggers #text(size: 10pt, weight: "regular")[\ _Stop the program and look inside_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #uso-book
    - Chapter 6 - _Dezvoltarea aplicațiilor_
      - Section 6.8 - _Depanarea programelor_
  + _Debugging with GDB_, #link("https://sourceware.org/gdb/current/onlinedocs/gdb")[online]
]

#slide[
  == What is a Debugger?
  A program that runs *another program* under its control

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #uncover("1-")[#block[
      === Instead of `printf`
      - *breakpoints*: stop at a line or a function
      - *step*: run one line at a time
      - *inspect*: variables, memory, the call stack
      - *watchpoints*: stop when a variable changes
      - *change* a variable and continue
    ]]
  ][
    #uncover("2-")[#block[
      === Debug information
      the CPU runs machine code, but we think in *lines* and *variables*: compile with `-g`
    ]]
    #uncover("3-")[
      ```terminal
      $ gcc -g main.c lib.c print.c -o app
      $ file app
      app: ELF 64-bit LSB pie executable, ..., with debug_info
      ```
    ]
    #uncover("4-")[#block[
      debuggers: `gdb` (GNU), `lldb` (LLVM), the Visual Studio debugger
    ]]
  ]

  #v(1fr)
  #uncover("5-")[
    #callout[🐧 on Linux the debugger is the *parent* of the program and controls it with the `ptrace` system call]
  ]
]

// a gdb session: "(gdb) " lines are commands, "$ " lines are shell
// commands, the rest is output; only the first `upto` lines are shown,
// the others keep their space
#let gdb-session(src, upto: none, window: 12) = {
  let all = src.split("\n")
  let last = if upto == none { all.len() } else { upto }
  let first = calc.max(0, last - window)
  let shown = all.slice(first, last)
  // pad to `window` lines, so the block keeps its height
  while shown.len() < window { shown.push(" ") }
  set align(left)
  show raw.line: l => {
    if l.text.starts-with("(gdb) ") [
      #text(fill: accent, weight: "bold")[(gdb)] #text(weight: "bold", l.text.slice(6))
    ] else if l.text.starts-with("$ ") {
      render-terminal-line(l.text)
    } else [
      #text(fill: luma(100), l.text)
    ]
  }
  raw(shown.join("\n"), block: true)
}

#let lib-c = ```c
int sum(int n)
{
    int s = 0;
    for (int i = 1; i <= n; i++) {
        s = s + i;
    }
    return s;
}
```

#let session1 = "$ gdb -q ./app
Reading symbols from ./app...
(gdb) break sum
Breakpoint 1 at 0x1188: file lib.c, line 3.
(gdb) run
Starting program: /home/student/project/app
Breakpoint 1, sum (n=10) at lib.c:3
3           int s = 0;
(gdb) backtrace
#0  sum (n=10) at lib.c:3
#1  0x000055555555515f in main () at main.c:6
(gdb) next
4           for (int i = 1; i <= n; i++) {
(gdb) next
5               s = s + i;
(gdb) next
4           for (int i = 1; i <= n; i++) {
(gdb) print s
$1 = 1"

// (the last line of the session shown, the lines of lib.c highlighted, the note)
#let session1-steps = (
  (2, "all", [start the program *under* `gdb`, it does not run yet]),
  (4, (1,), [a *breakpoint* at the function `sum`, i.e. at its first line]),
  (8, (3,), [`run`: the program starts and stops at the breakpoint, *before* line 3 runs]),
  (11, (3,), [`backtrace`: who called whom, `main` (line 6 of `main.c`) called `sum`]),
  (17, (4, 5), [`next` runs one line, here twice around the loop]),
  (19, (5,), [`print` shows a variable: `s` is 1 after the first `s = s + i`]),
)

#slide[
  == A `gdb` Session
  `app` is built with `-g` (shortened)

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1em)[
    #text(size: 0.8em, fill: luma(110))[`lib.c`]
    #highlight-code(session1-steps.map(s => s.at(1)))[#lib-c]
  ][
    #set text(size: 0.92em)
    #for (i, (upto, _, _)) in session1-steps.enumerate() {
      only(i + 1, gdb-session(session1, upto: upto))
    }
  ]

  #v(1fr)
  #for (i, (_, _, note)) in session1-steps.enumerate() {
    only(i + 1)[💡 #note]
  }
]

#let session2 = "(gdb) watch s
Hardware watchpoint 2: s
(gdb) continue
Old value = 1
New value = 3
(gdb) continue
Old value = 3
New value = 6
(gdb) info locals
i = 3
s = 6
(gdb) set var s = 100
(gdb) delete 2
(gdb) finish
Run till exit from #0  sum (n=10) at lib.c:4
Value returned is $1 = 149
(gdb) continue
sum = 149
[Inferior 1 (process 6201) exited normally]"

#let session2-steps = (
  (2, (5,), [a *watchpoint*: stop every time `s` changes (the CPU helps: _hardware_ watchpoint)]),
  (8, (5,), [`continue` runs until the next stop: `s` went from 1 to 3, then to 6]),
  (11, (4, 5), [`info locals`: all the local variables]),
  (13, (5,), [*change* a variable, the program goes on with it; `delete` the watchpoint]),
  (16, (7,), [`finish`: run until `sum` returns, the result is 149, not 55]),
  (19, "all", [the program uses the value we set: `sum = 149`]),
)

#slide[
  == Watch and Change
  The same session, continued (shortened)

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1em)[
    #text(size: 0.8em, fill: luma(110))[`lib.c`]
    #highlight-code(session2-steps.map(s => s.at(1)))[#lib-c]
  ][
    #set text(size: 0.92em)
    #for (i, (upto, _, _)) in session2-steps.enumerate() {
      only(i + 1, gdb-session(session2, upto: upto))
    }
  ]

  #v(1fr)
  #for (i, (_, _, note)) in session2-steps.enumerate() {
    only(i + 1)[💡 #note]
  }
]

#slide[
  == `gdb` Commands
  Most commands have a one-letter short form

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #key-table(header: ([*command*], [*what it does*]), (
      ([run the program], none),
      ([`run` (`r`)], [start it, with arguments: `run a b`]),
      ([`continue` (`c`)], [go on until the next stop]),
      ([`next` (`n`)], [one line, *over* function calls]),
      ([`step` (`s`)], [one line, *into* function calls]),
      ([`finish`], [until the current function returns]),
      ([`quit` (`q`)], [exit `gdb`]),
    ))
  ][
    #key-table(header: ([*command*], [*what it does*]), (
      ([stop], none),
      ([`break` (`b`) `sum`], [at a function]),
      ([`break lib.c:5`], [at a line]),
      ([`watch s`], [when a variable changes]),
      ([look], none),
      ([`print` (`p`) `s * 2`], [any C expression]),
      ([`backtrace` (`bt`)], [the call stack]),
      ([`info locals`], [the local variables]),
      ([`set var s = 0`], [change a variable]),
    ))
  ]
]

#slide[
  == Debuggers in an IDE
  The same operations, with buttons

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.2em)[
    #screenshot("img/book/codeblocks-debug.png", width: 100%)
    #text(size: 0.7em)[Code::Blocks stopped at a breakpoint (from the USO book)]
  ][
    #set text(size: 0.9em)
    - click next to a line: a *breakpoint*
    - the *variables* and the *call stack* are always on the screen
    - buttons for `continue`, `next`, `step`, `finish`

    #uncover("2-")[
      #v(0.5em)
      💡 the IDE does not debug the program itself: it runs `gdb` or `lldb` and talks to it
    ]
  ]
]
