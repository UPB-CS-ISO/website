#import "/src/slides.typ": *
#import "common.typ": *

#show: uso_slides.with(title: "Users")

#slide[
  == Bibliography

  #set text(size: 0.85em)
  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    1. #ward
      - Chapter 2 - _Basic Commands and Directory Hierarchy_
        - Section 2.17 - _File Modes and Permissions_
      - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
        - Section 7.3 - _User Management Files_
        - Section 7.4 - _getty and login_
        - Section 7.9 - _User Access Topics_
        - Section 7.10 - _Pluggable Authentication Modules_
  ][
    2. #uso-book
      - Chapter 5 - _Utilizatori_
  ]
]

#slide[
  // diatypst tracks a running header from the most recent level-2 heading;
  // an empty, non-outlined heading resets it so this slide shows no title.
  #heading(level: 2, outlined: false)[]

  #align(center + horizon)[
    #text(size: 18pt)[
      _We trust you have received the usual lecture from the local System Administrator. It usually boils down to these three things:_

      _\#1) Respect the privacy of others._ \
      _\#2) Think before you type._ \
      _\#3) With great power comes great responsibility._
    ]

    #v(0.5em)
    `sudo`, the first time you use it
  ]
]

#slide[
  == Users

  - Users
  - The Users Database
  - The `root` User
  - Becoming `root`
  - The `sudoers` File
  - The Prompt
  - Groups
  - Managing Users and Groups
  - Permissions
  - Logging In
]

#include "users.typ"
#include "database.typ"
#include "root.typ"
#include "sudo.typ"
#include "sudoers.typ"
#include "prompt.typ"
#include "groups.typ"
#include "management.typ"
#include "permissions.typ"
#include "login.typ"

#slide[
  == We talked about

  - Users
  - The Users Database
  - The `root` User
  - Becoming `root`
  - The `sudoers` File
  - The Prompt
  - Groups
  - Managing Users and Groups
  - Permissions
  - Logging In
]
