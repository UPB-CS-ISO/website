#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Handling Errors #text(size: 10pt, weight: "regular")[\ _When a command fails_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.4 - _Exit Codes_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.4.1 - _Robustețe_
]

#let tidy-code = "#!/bin/bash
# clean up the photos
cd photoz
rm -f *.tmp
echo \"photos cleaned\""

#slide[
  == 🐞 After an Error
  A failed command prints its error, then `bash` runs the next line

  #debug-run(tidy-code, size: 1.2em, columns: (11fr, 9fr), command: "./tidy.sh", blocks: true, (
    (line: 3, run: "cd photoz", status: 1, out: ("./tidy.sh: line 3: cd: photoz: No such file or directory",),
      note: [💡 `cd` fails: the folder is `photos`, not `photoz`]),
    (line: 4, expand: "*.tmp", run: "rm -f *.tmp", status: 0,
      note: [⚠️ `rm` runs anyway, in `/home/alice`: it deletes the `.tmp` files of the *wrong* folder]),
    (line: 5, run: "echo \"photos cleaned\"", status: 0, out: ("photos cleaned",),
      note: [⚠️ the script ends with #exit-code(0), the exit code of `echo`: whoever ran it thinks it worked]),
  ))
]

// three ways to check the commands yourself, one per step: the script
// (the lines that changed in orange), what it prints, and why
#let checked = (
  (
    "tidy.sh",
    "#!/bin/bash\n# clean up the photos\ncd photoz || exit 1\nrm -f *.tmp\necho \"photos cleaned\"",
    (3,),
    "$ ./tidy.sh\n./tidy.sh: line 3: cd: photoz: No such file or directory\n$ echo $?\n1",
    [`||` runs `exit 1` only when `cd` fails: the script ends there, `rm` never runs],
  ),
  (
    "tidy.sh",
    "#!/bin/bash\n# clean up the photos\nif ! cd photoz; then\n    echo \"no photoz folder\" >&2\n    exit 1\nfi\nrm -f *.tmp\necho \"photos cleaned\"",
    (3, 4, 5, 6),
    "$ ./tidy.sh\n./tidy.sh: line 3: cd: photoz: No such file or directory\nno photoz folder\n$ echo $?\n1",
    [`if !` - when `cd` fails, print your own message first (to the error output, `>&2`), then `exit 1`],
  ),
  (
    "save.sh",
    "#!/bin/bash\n# save the photos\nmkdir -p backup || exit 1\ncd photos || exit 1\ncp *.jpeg ../backup/ || exit 1\necho \"photos saved\"",
    (3, 4, 5),
    none,
    [⚠️ *every* command that may fail needs its own check - and one is easy to forget],
  ),
)

#slide[
  == Check It Yourself
  `||` and `if !` run something only when a command fails

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.95em)
    #for (k, (name, code, hl, _, _)) in checked.enumerate() {
      only(k + 1, code-panel(name, code, hl: hl))
    }
  ][
    #for (k, (_, _, _, out, why)) in checked.enumerate() {
      only(k + 1, {
        block(text(size: 0.85em)[💡 #why])
        if out != none { text(size: 0.95em, terminal(out)) }
        else {
          v(0.5em)
          shell-first[`bash` can check *every* command for you: strict mode, in the next section]
        }
      })
    }
  ]
]

