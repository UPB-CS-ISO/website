#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Groups #text(size: 10pt, weight: "regular")[\ _rights for several users at once_]
]

#slide[
  == Bibliography
  for this section

  + #ward
    - Chapter 7 - _System Configuration: Logging, System Time, Batch Jobs, and Users_
      - Section 7.3.5 - _Working with Groups_
  + #uso-book
    - Chapter 5 - _Utilizatori_
]

// who is in which group: (group, GID, members), a member is (user, primary)
#let users-list = ("alice", "bob", "carol")
#let groups-list = (
  ("alice", 1000, ("alice": true)),
  ("bob", 1001, ("bob": true)),
  ("carol", 1002, ("carol": true)),
  ("students", 1100, ("alice": false, "bob": false)),
  ("sudo", 27, ("alice": false)),
  ("docker", 998, ("carol": false)),
)

#slide[
  == Groups and Users
  👥 a group is a *set of users* that share the same rights

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    - every group has a *name* and a *GID*
    #uncover("2-")[#block[- every user has *one primary group* (the GID in `/etc/passwd`), usually a group with the same name as the user, only for them]]
    #uncover("3-")[#block[- and any number of *supplementary groups*]]
  ][
    #set text(size: 0.9em)
    #let cell(group, user) = {
      let (name, gid, members) = group
      if user in members {
        let primary = members.at(user)
        uncover(if primary { "2-" } else { "3-" }, if primary [⭐] else [●])
      } else []
    }
    #table(
      columns: (auto, auto) + (1fr,) * users-list.len(),
      align: (left, right) + (center,) * users-list.len(),
      table.header([Group], [GID], ..users-list.map(u => [👤 #raw(u)])),
      ..groups-list.map(g => (raw(g.at(0)), raw(str(g.at(1))), ..users-list.map(u => cell(g, u)))).flatten(),
    )
    #align(center, text(size: 0.8em)[⭐ primary group #h(1em) ● supplementary group])
  ]
]

#let group-fields = ("students", "x", "1100", "alice,bob")

#slide[
  == `/etc/group`
  📒 the local groups database

  #set text(size: 0.95em)
  #record-walk(
    group-fields,
    size: 1.35em,
    intro: card(icon: "📒", title: [4 fields, separated by `:`])[
      ```terminal
      $ grep students /etc/group   # only the local file
      $ getent group students      # the groups database
      ```
      🌍 everyone can read it, `getent` asks the network too, like `getent passwd`
    ],
    (
      ("🏷️", [group name], [the name of the group]),
      ("🔒", [password], [`x` - almost never used]),
      ("🔢", [GID], [the group ID, the kernel uses the GID]),
      ("👥", [members], [the users that have this group as a *supplementary* group, separated by `,`\ ⚠️ the users that have it as *primary* group are not listed here]),
    ),
  )
]
