#import "/src/slides.typ": *
#import "walk.typ": *

#slide[
  = Walking a Path #text(size: 10pt, weight: "regular")[\ _from relative to absolute_]
]

#slide[
  == `.` and `..`
  🧭 where am I, where is my parent

  #toolbox.side-by-side(columns: (2fr, 3fr), gutter: 1.5em)[
    Every directory has two _hidden_ entries:
    - 📍 `.` - the directory *itself*
    - ⬆️ `..` - its *parent* directory

    #uncover("2-")[
      🔁 `..` can be chained, each one goes *one level up*
    ]

    #uncover("3-")[
      ⚠️ `/..` is still `/`, the root has no parent
    ]
  ][
    #only(1)[#dot-tree(
      here: (3, 4),
      notes: ("3": ".. (parent)", "4": ". (current)"),
      caption: [we are in `/home/alice/Movies`],
    )]
    #only("2-")[#dot-tree(
      here: (1, 2, 3, 4),
      notes: ("1": "../../..", "2": "../..", "3": ".. (parent)", "4": ". (current)"),
      caption: [every `..` climbs one more level],
    )]
  ]
]

#slide[
  == Walking a Path

  #path-walks(path-examples.slice(0, 4))
]
