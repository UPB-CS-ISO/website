#import "/src/slides.typ": *
#import "/extra/text-processing-common.typ": *

// Pipelines, written for
// 4. Command Line Interface and kept here for later use. Include it from any
// deck with #include "/extra/pipelines.typ"

#slide[
  = Pipelines #text(size: 10pt, weight: "regular")[\ _Chain the commands together_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.14 - _Shell Input and Output_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 4 - _Procese_
      - Sections 4.5.3 - 4.5.4 - _Înlănțuirea comenzilor_, _Comunicarea prin pipe-uri_
    - Chapter 7 - _Interfața în linia de comandă_
      - Section 7.5 - _Prelucrare de text de bază: filtre de text și one linere_
]

#slide[
  == 🧩 Combine Commands
  The pipe operator `|`

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    #reveal-terminal(before: none, lines: (2, 4), full: false)[```terminal
    $ sort fruits.txt | uniq | wc -l   # different fruits
    4
    $ grep -i error server.log | wc -l # how many errors
    2
    ```]
  ][
    #set text(size: 0.9em)
    - the `stdout` of a command becomes the `stdin` of the next one
    - all the commands run *at the same time*
    - no temporary files
  ]

  #v(1em)
  #align(center)[
    #only(1)[#chain(("sort fruits.txt", "uniq", "wc -l"), highlight-last: false)]
    #only("2-")[#chain(("grep -i error server.log", "wc -l"), highlight-last: false)]
  ]
]

#let access-log = (
  "10.0.0.7 GET /index.html 200",
  "10.0.0.9 GET /logo.png 404",
  "10.0.0.7 GET /about.html 200",
  "10.0.0.3 GET /old.html 404",
  "10.0.0.9 GET /favicon.ico 404",
  "10.0.0.5 GET /index.html 200",
  "10.0.0.9 GET /admin 404",
  "10.0.0.3 GET /old.html 404",
)

// every step adds one command to the pipeline:
// (the command, its name in the drawing, the output, an explanation)
#let pipeline-steps = (
  ("grep ' 404$' access.log", "grep", (
    "10.0.0.9 GET /logo.png 404",
    "10.0.0.3 GET /old.html 404",
    "10.0.0.9 GET /favicon.ico 404",
    "10.0.0.9 GET /admin 404",
    "10.0.0.3 GET /old.html 404",
  ), [keep only the requests that ended with `404` (_Not Found_)]),
  ("cut -d' ' -f1", "cut", ("10.0.0.9", "10.0.0.3", "10.0.0.9", "10.0.0.9", "10.0.0.3"), [keep only the first field, the IP address]),
  ("sort", "sort", ("10.0.0.3", "10.0.0.3", "10.0.0.9", "10.0.0.9", "10.0.0.9"), [identical addresses are now next to each other]),
  ("uniq -c", "uniq", ("      2 10.0.0.3", "      3 10.0.0.9"), [count every address]),
  ("sort -nr", "sort", ("      3 10.0.0.9", "      2 10.0.0.3"), [sort by the count, numerically, in reverse order]),
  ("head -n 1", "head", ("      3 10.0.0.9",), [keep only the first line: the answer]),
)

#slide[
  == Build a Pipeline, Step by Step
  Which IP address requested the most missing pages?

  #align(center)[
    #for i in range(pipeline-steps.len()) {
      only(i + 1, chain(pipeline-steps.map(s => s.at(1)), upto: i + 1))
    }
  ]

  #toolbox.side-by-side(columns: (3fr, 2fr), gutter: 1.5em)[
    #set text(size: 0.75em)
    #for i in range(pipeline-steps.len()) {
      let cmds = pipeline-steps.slice(0, i + 1).map(s => s.at(0))
      // one command per line, continued with `\`, so the long pipeline fits
      let cmd-lines = cmds.enumerate().map(((j, c)) => {
        let line = if j == 0 { "$ " + c } else { "  | " + c }
        if j < cmds.len() - 1 { line + " \\" } else { line }
      })
      let output = pipeline-steps.at(i).at(2)
      only(i + 1)[
        #terminal((cmd-lines + output).join("\n"))
        #text(size: 1.2em)[💡 #pipeline-steps.at(i).at(3)]
      ]
    }
  ][
    #only(1)[#file-contents("access.log", access-log, size: 0.65em, new: (2, 4, 5, 7, 8), faded: (1, 3, 6))]
    #only("2-")[#file-contents("access.log", access-log, size: 0.65em)]
  ]
]

#slide[
  == 🔗 Advanced Combinations
  The most frequent words in a text

  #set text(size: 0.85em)
  ```terminal
  $ tr -cs 'A-Za-z' '\n' < story.txt | tr 'A-Z' 'a-z' | sort | uniq -c | sort -nr | head -n 3
        5 the
        3 dog
        3 cat
  ```

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (auto, 1fr),
      table.header([Command], [What it does]),
      [`tr -cs 'A-Za-z' '\n'`], [everything that is *not* a letter (`-c`) becomes a new line, squeezed (`-s`): one word per line],
      [`tr 'A-Z' 'a-z'`], [lower case, so `The` and `the` are the same word],
      [`sort | uniq -c`], [count every word],
      [`sort -nr | head -n 3`], [the 3 most frequent words],
    )
  ][
    #file-contents("story.txt", (
      "The cat and the dog.",
      "The dog sleeps, the cat runs.",
      "A dog barks at the cat.",
    ))
    #v(0.5em)
    💡 `-c` - _complement_ of the set, `-s` - _squeeze_ the repeated new lines
  ]
]

#slide[
  == 📋 Summary

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #table(
      columns: (auto, 1fr),
      table.header([Command], [Purpose]),
      [`cat`], [view or concatenate files],
      [`sort`], [sort lines],
      [`uniq`], [remove adjacent duplicates],
      [`grep`], [search for a pattern],
      [`wc`], [count lines, words, bytes],
      [`head` / `tail`], [the first / last lines],
    )
  ][
    #table(
      columns: (auto, 1fr),
      table.header([Command], [Purpose]),
      [`tac`], [reverse the order of the lines],
      [`rev`], [reverse the characters of every line],
      [`nl`], [number the lines],
      [`cut`], [extract columns],
      [`tr`], [translate or delete characters],
      [`|`], [chain them together],
    )
  ]
]

#slide[
  == 🎯 Practice
  Top IP addresses causing `404` errors

  ```terminal
  $ cat access.log | grep "404" | cut -d ' ' -f1 | sort | uniq -c | sort -nr | head
  ```

  #uncover("2-")[🤔 `cat access.log | grep ...` works, but `grep ... access.log` does the same with one process less]

  #uncover("3-")[🤔 `grep "404"` also matches lines like `GET /page404.html 200`, `grep ' 404$'` is more precise]

  #uncover("4-")[
    #ai-prompt[I am learning Linux text processing. Give me 5 exercises that use `grep`, `cut`, `sort`, `uniq`, `wc`, `head` and pipes, each with a small sample file. Do not show the solutions until I ask for them.]
  ]
]
