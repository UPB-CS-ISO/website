#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Quoting, Escaping and Globbing #text(size: 10pt, weight: "regular")[\ _Special characters and file name patterns_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 2 - _Basic Commands and Directory Hierarchy_
      - Section 2.4.2 - _Shell Globbing ("Wildcards")_
      - Section 2.10 - _Special Characters_
    - Chapter 11 - _Introduction to Shell Scripts_
      - Section 11.2 - _Quoting and Literals_
  + *Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici*, _Utilizarea Sistemelor de Operare_, Printech 2021, #link("https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf")[download]
    - Chapter 7 - _Interfața în linia de comandă_
      - Sections 7.2.4 - 7.2.5 - _Expandări_, _Escaping_
]

// what `echo` receives for a few ways of writing the same text, with
// NAME="Alice   Smith": (what you type, the words echo gets, why)
#let receive-rows = (
  ("echo $NAME", ("Alice", "Smith"), [no quotes: replaced, then split at the spaces]),
  ("echo \"$NAME\"", ("Alice   Smith",), [double quotes: replaced, *one* word, spaces kept]),
  ("echo '$NAME'", ("$NAME",), [single quotes: *nothing* is replaced]),
  ("echo \\$NAME", ("$NAME",), [`\$`: the `$` is just a character]),
  ("echo my\\ file.txt", ("my file.txt",), [`\ `: the space does not split]),
  ("echo \"\\$NAME is $NAME\"", ("$NAME is Alice   Smith",), [inside `"..."`, `\$` is a `$`, `$NAME` is replaced]),
  ("echo \"it's\" 'say \"hi\"'", ("it's", "say \"hi\""), [each kind of quotes protects the other one]),
  ("echo 'a\\b'", ("a\\b",), [inside `'...'`, `\` is just a character]),
)

// rows of "you type", then the command (`echo`) and the words it gets,
// with a short explanation; one row per step
// `rows` are (what you type, the words echo gets, why)
#let received(rows, size: 0.8em, gutter: 0.5em) = {
  set text(size: size)
  grid(
    columns: (auto, auto, auto, 1fr),
    column-gutter: 0.8em,
    row-gutter: gutter,
    align: (left + horizon, center + horizon, left + horizon, left + horizon),
    text(fill: luma(110), style: "italic")[you type], [], text(fill: luma(110), style: "italic")[the command and its parameters], [],
    ..rows.enumerate().map(((i, (cmd, got, why))) => {
      let when = str(i + 1) + "-"
      (
        uncover(when, box(fill: luma(235), radius: 0.3em, inset: (x: 0.5em, y: 0.35em),
          text(font: mono, size: 0.9em)[#text(fill: accent, weight: "bold")[\$] #highlight-shell(cmd)])),
        uncover(when, arrow),
        uncover(when, words(("echo", "cmd"), ..got.map(g => (g, "new")))),
        uncover(when, text(size: 0.95em, why)),
      )
    }).flatten(),
  )
}

#slide[
  == Quoting and Escaping
  With ```bash NAME="Alice   Smith"```: the quotes and the `\` are gone, only the words are left

  #v(0.3em)
  #received(receive-rows)
]

// what `echo` gets for some globs, in the directory listed on the slide
// (bash, with `shopt -s globstar` for `**`)
#let glob-rows = (
  ("echo *.txt", ("notes.txt", "todo.txt"), [`*`: any characters, or none]),
  ("echo photo?.png", ("photo1.png", "photo2.png", "photo3.png", "photoA.png"), [`?`: exactly one character]),
  ("echo photo[12].png", ("photo1.png", "photo2.png"), [`[12]`: one of these characters]),
  ("echo photo[0-9].png", ("photo1.png", "photo2.png", "photo3.png"), [`[0-9]`: one in the range]),
  ("echo photo[!0-9].png", ("photoA.png",), [`[!0-9]`: one *not* in it]),
  ("echo docs/**/*.txt", ("docs/2026/exam.txt", "docs/plan.txt"), [`**`: any directories (`globstar`)]),
  ("echo {a,b,c}.pdf", ("a.pdf", "b.pdf", "c.pdf"), [`{ }`: a word for each, file or not]),
  ("echo *.pdf", ("*.pdf",), [no match: kept (`bash`), error (`zsh`)]),
)
#slide[
  == Globing
  Patterns for file names, replaced by the shell with the matching files

  #block(text(size: 0.85em, terminal("$ ls\ndocs  notes.txt  photo1.png  photo2.png  photo3.png  photoA.png  report.md  todo.txt")))

  #received(glob-rows, size: 0.76em, gutter: 0.35em)
]
