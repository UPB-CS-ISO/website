#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Quoting #text(size: 10pt, weight: "regular")[\ _How many words does the shell make?_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.2 - _Quoting and Literals_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 13 - _Automatizarea sarcinilor_
      - Section 13.3.1 - _Variabile_
]

#slide[
  == Quoting `$( )`
  ```bash $(...)``` or ```bash "$(...)"```: how many words does `for` get?

  // one case: the loop, the words the shell makes, what it prints
  #let case(title, loop, chips, out) = block(width: 100%, {
    text(weight: "bold", fill: accent, title)
    linebreak()
    text(size: 0.85em, raw(loop, lang: "bash"))
    v(-0.2em)
    label[the words of the list]
    linebreak()
    box(chips)
    v(-0.2em)
    set text(size: 0.8em)
    terminal(out)
  })

  #grid(
    columns: (auto, 1fr, 1fr, 1fr),
    column-gutter: 1em,
    file-view("people.txt", ("Alice Smith", "Bob Jones"), size: 0.75em),
    case([❌ without quotes],
      "for n in $(cat people.txt); do echo \"[$n]\"; done",
      words("Alice", "Smith", "Bob", "Jones"),
      "[Alice]\n[Smith]\n[Bob]\n[Jones]"),
    uncover("2-", case([⚠️ with quotes],
      "for n in \"$(cat people.txt)\"; do echo \"[$n]\"; done",
      words("Alice Smith⏎Bob Jones"),
      "[Alice Smith\nBob Jones]")),
    uncover("3-", case([✅ one line at a time],
      "while read n; do echo \"[$n]\"; done < people.txt",
      [#label[`read` takes a line:] #words("Alice Smith") #words("Bob Jones")],
      "[Alice Smith]\n[Bob Jones]")),
  )

  #v(0.3em)
  #set text(size: 0.9em)
  #only(1)[💡 unquoted, the output is split at *every* space and newline: 4 words, 4 rounds]
  #only(2)[💡 quoted, the whole output is *one* word: 1 round]
  #only("3-")[💡 `for` goes over *words*; to go over *lines*, use `while read`]
]

#slide[
  == Quoting a Glob
  `*.txt` or `"*.txt"`: does the shell look for files?

  // one case: the loop, the words the shell makes, what it prints
  #let case(title, loop, chips, out) = block(width: 100%, {
    text(weight: "bold", fill: accent, title)
    linebreak()
    text(size: 0.85em, raw(loop, lang: "bash"))
    v(-0.2em)
    label[the words of the list]
    linebreak()
    box(chips)
    v(-0.2em)
    set text(size: 0.8em)
    terminal(out)
  })

  #label[the files in the current directory] #h(0.4em) #text(size: 0.85em, words("fruits.txt", "notes.txt", "words.txt"))

  #grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 1em,
    case([✅ without quotes],
      "for f in *.txt; do echo \"[$f]\"; done",
      words(("fruits.txt", "new"), ("notes.txt", "new"), ("words.txt", "new")),
      "[fruits.txt]\n[notes.txt]\n[words.txt]"),
    uncover("2-", case([❌ with quotes],
      "for f in \"*.txt\"; do echo \"[$f]\"; done",
      words("*.txt"),
      "[*.txt]")),
    uncover("3-", case([⚠️ no file matches],
      "for f in *.pdf; do echo \"[$f]\"; done",
      words("*.pdf"),
      "[*.pdf]")),
  )

  #v(0.3em)
  #set text(size: 0.9em)
  #only(1)[💡 the shell replaces the glob with the matching file names: 3 words, 3 rounds]
  #only(2)[💡 in quotes, `*` is just a character: the text `*.txt`, 1 round]
  #only("3-")[💡 no `.pdf` file: the glob stays as it is, the loop runs *once* with the text `*.pdf`]
]
