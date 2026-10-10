#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Foreground & Background #text(size: 10pt, weight: "regular")[\ _Run more than one process from the same shell_]
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
      - Section 4.3.3 - _Foreground și background_
      - Section 4.5.2 - _Semnale_
]

#slide[
  == Foreground and Background Process
  The terminal and the shell define this

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #align(center)[#diagram("img/fg_and_bg.svg", width: 100%)]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[
      === Foreground
      - *only one* process
      - reads the keyboard (`stdin`)
      - the shell _waits_ for it
    ]
    #uncover("3-")[
      === Background
      - *any number* of processes, called _jobs_
      - _running_ or _stopped_
      - the shell does not wait, it shows the prompt
    ]
  ]
]

// A job of `Start a Job`, drawn like the groups of `Sessions and the
// Terminal`: the job (a tinted box) with its process inside.
// `state`: "running", "stopped", "terminated" or "hidden" (keeps its space)
#let job-card(id, cmd, pid, state) = {
  let running = state != "terminated"
  let green = rgb("2e7d32")
  let card = box(
    width: 100%,
    inset: (x: 0.5em, top: 0.4em, bottom: 0.5em),
    radius: 0.5em,
    stroke: 1pt + luma(150),
    fill: rgb("eef3f5"),
    {
      align(center, text(size: 0.8em)[job *\[#id\]*])
      v(-0.3em)
      box(
        width: 100%,
        inset: (y: 0.4em),
        radius: 0.3em,
        stroke: if running { 0.8pt + luma(150) } else { (paint: luma(170), thickness: 0.8pt, dash: "dashed") },
        fill: white,
        align(center)[
          #text(font: mono, fill: if running { black } else { luma(160) }, cmd) \
          #text(size: 0.7em, fill: luma(110))[PID #pid]
        ],
      )
      v(-0.2em)
      align(center, text(size: 0.8em, fill: if state == "stopped" { changed } else if running { green } else { luma(110) }, if state == "stopped" [⏸️ stopped] else if running [🟢 running] else [❌ terminated]))
    },
  )
  if state == "hidden" { hide(card) } else { card }
}

#slide[
  == Start a Job
  Add `&` at the end: the shell starts the command and shows the prompt *right away*

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #reveal-terminal(before: none, lines: (2, 4, 7, 9), full: false)[```terminal
    $ sleep 100 &
    [1] 4242
    $ sleep 200 &
    [2] 4250
    $ jobs
    [1]-  Running     sleep 100 &
    [2]+  Running     sleep 200 &
    $ kill %1
    [1]-  Terminated  sleep 100
    ```]
  ][
    #v(0.5em)
    #align(center, text(size: 0.8em, fill: luma(100))[the jobs of this shell])
    #grid(
      columns: (1fr, 1fr),
      column-gutter: 0.6em,
      only("1-3", job-card("1", "sleep 100", "4242", "running")) + only("4-", job-card("1", "sleep 100", "4242", "terminated")),
      job-card("2", "sleep 200", "4250", "hidden") + place(top + left, only("2-", job-card("2", "sleep 200", "4250", "running"))),
    )
  ]

  #v(0.8em)
  #only(1)[💡 `[1]` is the *job ID*, it exists only in this shell, `4242` is the *PID*]
  #only(2)[💡 a second job, `[2]`: the shell does not wait, both run at the same time]
  #only(3)[💡 `jobs` lists the jobs of *this* shell: `+` the current job (the last one), `-` the previous one]
  #only("4-")[💡 `%1` means _job 1_: it works with `kill`, `fg` and `bg`, job `[2]` keeps running]
]

#slide[
  == Make a Job
  Move a foreground process to the background

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #uncover("1-")[#block[
      - run the command
        - ⚠️ redirect its output, a job still writes to the same terminal
    ]]
    #uncover("2-")[#block[
    - press #kbd("Ctrl") + #kbd("Z") (sends `SIGTSTP`)
      - 🙄 the process might ignore it]
    ]
    #uncover("3-")[#block[- find the job `ID` (`jobs`)]]
    #uncover("4-")[#block[- run `bg %ID` (sends `SIGCONT`)]]
    #uncover("5-")[#block[- run `jobs` to verify if it still runs]]
    #uncover("6-")[
      === Bring it back in the foreground
      - run `fg %ID`
    ]
  ][
    #set text(size: 0.78em)
    #reveal-terminal(before: none, lines: (1, 3, 5, 7, 9, 11), full: false)[```terminal
    $ sleep 100 > /dev/null
    ^Z
    [1]+  Stopped     sleep 100 > /dev/null
    $ jobs
    [1]+  Stopped     sleep 100 > /dev/null
    $ bg %1
    [1]+ sleep 100 > /dev/null &
    $ jobs
    [1]+  Running     sleep 100 > /dev/null &
    $ fg %1
    sleep 100 > /dev/null
    ```]
    // the job exists only while it is stopped or in the background
    #v(0.2em)
    #align(center, box(width: 42%, {
      set text(size: 1.1em)
      only(1, job-card("1", "sleep 100", "4242", "hidden"))
      only("2-3", job-card("1", "sleep 100", "4242", "stopped"))
      only("4-5", job-card("1", "sleep 100", "4242", "running"))
      only("6-", job-card("1", "sleep 100", "4242", "hidden"))
    }))
  ]
]
