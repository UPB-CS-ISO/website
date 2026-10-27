#import "/src/slides.typ": *
#import "common.typ": *

#show: uso_slides.with(title: "Administration")

// every permission string, `-rw-r-----`, in the colors of u, g and o
#show mode-pattern: it => mode-text(it.text)

#slide[
  == Administration

  - The `sudoers` File
  - Managing Users
]

#include "sudoers.typ"
#include "users.typ"

#slide[
  == We talked about

  - The `sudoers` File
  - Managing Users
]
