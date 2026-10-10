#import "/src/slides.typ": *

#slide[
  = Signals #text(size: 10pt, weight: "regular")[\ _notifications for the processes_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.16 - _Listing and Manipulating Processes_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Section 4.5.2 - _Semnale_
]

#slide[
  == Signals
  ✉️ the OS sends a message to a process

  #toolbox.side-by-side(columns: (1fr, 2fr), gutter: 1.5em)[
    - a message sent from the OS to a process
    - a number
    - may have an _extra payload number_
  ][
    *List of signals*
    #set text(size: 0.8em)
    #reveal-terminal(before: none, lines: (1, 9, 13), full: false)[```terminal
    $ kill -l # sends a signal, does not kill a process
     1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL
     5) SIGTRAP      6) SIGABRT      7) SIGBUS       8) SIGFPE
     9) SIGKILL     10) SIGUSR1     11) SIGSEGV     12) SIGUSR2
    13) SIGPIPE     14) SIGALRM     15) SIGTERM     16) SIGSTKFLT
    17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
    21) SIGTTIN     22) SIGTTOU     23) SIGURG      24) SIGXCPU
    25) SIGXFSZ     26) SIGVTALRM   27) SIGPROF     28) SIGWINCH
    29) SIGIO       30) SIGPWR      31) SIGSYS      34) SIGRTMIN
    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3  38) SIGRTMIN+4
    39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
    43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12
    ...             64) SIGRTMAX
    ```]
  ]
]

#slide[
  == Handling Signals
  override the default signal handler

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    When a ✉️ signal arrives, the process will

    #uncover("2-")[#block[
      1. 🛑 stop whatever it is doing
      2. 🚥 execute
        - the *default action* (_if no signal handler is registered_)
    ]]
    #uncover("3-")[#block(above: 0.4em, inset: (left: 1.6em))[
      - OR the *signal handler* and continue its task
    ]]

    #uncover("4-")[
      #set text(size: 0.85em)
      ```bash
      trap function_name SIGNAL
      ```
      ```c
      #include <signal.h>
      void handler(int signum) { /* ... */ }
      signal(SIGINT, handler);
      ```
    ]
  ][
    #set text(size: 0.85em)
    #highlight-code(
      ((1, 11, 12, 13, 14), (16,), lines-range(3, 6), (8, 9)),
    )[```bash
    #!/bin/bash

    # the signal handler
    function no_interruptions_please () {
        echo "No interruptions please"
    }

    # register the signal handler
    trap no_interruptions_please SIGINT

    while true; do
      echo "working"
      sleep 1
    done

    # exit (default action for SIGINT)
    ```]

  ]

  #place(bottom + right)[
    #set text(size: 0.8em)
    #only(2)[💡 #kbd("Ctrl") + #kbd("C") sends `SIGINT`, the default action stops the script]
    #only("4-")[💡 #kbd("Ctrl") + #kbd("C") now prints the message, the script keeps working]
  ]
]

#slide[
  == 🚥 Default Signal Actions

  #table(
    columns: (auto, 1fr),
    table.header([Default Action], [Description]),
    [*Terminate*], [Immediately ends the process. Can usually be caught or ignored.],
    [*Terminate (Unblockable)*], [Ends the process and *cannot* be caught, blocked, or ignored (`SIGKILL`).],
    [*Core Dump*], [Terminates the process *and creates a core dump* for debugging.],
    [*Stop*], [Suspends the process until it receives `SIGCONT`.],
    [*Stop (Unblockable)*], [Suspends the process, and *cannot* be caught or ignored (`SIGSTOP`).],
    [*Continue*], [Resumes a process that was previously stopped.],
    [*Ignore*], [Signal is discarded; no effect on the process.],
  )
]

// one table for half of the signals, small enough to fit on a slide
// (wrapped in a block, so the smaller text does not leak into the page header)
#let signals-table(..rows) = block(width: 100%, {
  set text(size: 0.78em)
  set table(inset: (x: 0.4em, y: 0.22em))
  table(
    columns: (auto, auto, auto, 1fr),
    align: (center, left, left, left),
    table.header([*\#*], [*Signal*], [*Default Action*], [*Description*]),
    ..rows,
  )
})

#slide[
  == ✉️ Linux Signals: Default Actions (1/2)

  #signals-table(
    [1], [`SIGHUP`], [Terminate], [Hangup detected on controlling terminal],
    [2], [`SIGINT`], [Terminate], [Interrupt from keyboard (#kbd("Ctrl") + #kbd("C"))],
    [3], [`SIGQUIT`], [Core Dump], [Quit from keyboard (#kbd("Ctrl") + #kbd("\\"))],
    [4], [`SIGILL`], [Core Dump], [Illegal instruction],
    [5], [`SIGTRAP`], [Core Dump], [Trace/breakpoint trap],
    [6], [`SIGABRT`], [Core Dump], [Abort signal from `abort()`],
    [7], [`SIGBUS`], [Core Dump], [Bus error (bad memory access)],
    [8], [`SIGFPE`], [Core Dump], [Floating-point exception],
    [9], [`SIGKILL`], [Terminate (Unblockable)], [Kill signal],
    [10], [`SIGUSR1`], [Terminate], [User-defined signal 1],
    [11], [`SIGSEGV`], [Core Dump], [Invalid memory reference],
    [12], [`SIGUSR2`], [Terminate], [User-defined signal 2],
    [13], [`SIGPIPE`], [Terminate], [Broken pipe],
    [14], [`SIGALRM`], [Terminate], [Timer signal from `alarm()`],
    [15], [`SIGTERM`], [Terminate], [Termination signal],
    [16], [`SIGSTKFLT`], [Terminate], [Stack fault on coprocessor (unused)],
  )
]

#slide[
  == ✉️ Linux Signals: Default Actions (2/2)

  #signals-table(
    [17], [`SIGCHLD`], [Ignore], [Child stopped or terminated],
    [18], [`SIGCONT`], [Continue], [Continue if stopped],
    [19], [`SIGSTOP`], [Stop (Unblockable)], [Stop process],
    [20], [`SIGTSTP`], [Stop], [Stop from terminal (#kbd("Ctrl") + #kbd("Z"))],
    [21], [`SIGTTIN`], [Stop], [Background read from tty],
    [22], [`SIGTTOU`], [Stop], [Background write to tty],
    [23], [`SIGURG`], [Ignore], [Urgent condition on socket],
    [24], [`SIGXCPU`], [Core Dump], [CPU time limit exceeded],
    [25], [`SIGXFSZ`], [Core Dump], [File size limit exceeded],
    [26], [`SIGVTALRM`], [Terminate], [Virtual timer expired],
    [27], [`SIGPROF`], [Terminate], [Profiling timer expired],
    [28], [`SIGWINCH`], [Ignore], [Window resize signal],
    [29], [`SIGIO`], [Terminate], [I/O now possible],
    [30], [`SIGPWR`], [Terminate], [Power failure],
    [31], [`SIGSYS`], [Core Dump], [Bad system call],
    [34–64], [`SIGRTMIN`–`SIGRTMAX`], [Terminate], [Real-time signals (implementation-defined)],
  )
]
