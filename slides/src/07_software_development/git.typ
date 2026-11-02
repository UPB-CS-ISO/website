#import "/src/slides.typ": *
#import "common.typ": *

// the hashes and outputs come from a real run (git 2.34, user Alice):
// 7cbb829 Add main.c, e5f6e0f Add the Makefile, c845fb9 Fix typo,
// then 7bf49e7 Add lib.c (lib.c + lib.h, on feature), 979fd82 Fix a bug
// (main.c, on main), a421fff Merge branch 'feature'

// ---------------------------------------------------------------------------
// The layout of the git slides: the explanation on the left, the picture on
// the right; under them, on the same line, the files of the project (left)
// and the commands we type (right)
// ---------------------------------------------------------------------------

// what happened to a file, for #project-tree: (color, fill, note)
#let edited = (changed, changed-fill, [edited])
#let added = (changed, changed-fill, [new file])
#let staged = (accent, rgb("e1edf1"), [staged])
#let committed = (ok-color, ok-fill, [committed])
#let not-pushed = (changed, changed-fill, [not pushed])
#let pushed = (ok-color, ok-fill, [pushed])
#let pulled = (ok-color, ok-fill, [pulled])
#let merged = (ok-color, ok-fill, [merged])

// the two columns of a slide: the text with the tree under it (left), the
// picture with the commands under it (right)
// e.g. #git-grid([- bullets], drawing, only(1, git-tree(...)), only(1, git-cmd("$ git add main.c")))
#let git-grid(columns: (1fr, 1fr), body, picture, tree, cmds) = grid(
  columns: columns,
  column-gutter: 1.5em,
  align: (left + top, center + top),
  stack(spacing: 0.8em, body, tree),
  stack(spacing: 0.8em, picture, align(left, cmds)),
)

// the commands of a step, as a small terminal
#let git-cmd(cmds) = block(width: 100%, text(size: 0.85em, terminal(cmds)))

// the rows of a popup: a large icon, then its text
// e.g. #icon-rows((("💾", [*commit* = save]), ("📤", [*push* = share])))
#let icon-rows(rows) = grid(
  columns: (auto, 1fr),
  column-gutter: 0.7em,
  row-gutter: 0.7em,
  align: (center + horizon, left + horizon),
  ..rows.map(((icon, body)) => (text(size: 1.8em, icon), text(size: 1.2em, body))).flatten(),
)

// the files of the project, drawn larger than in the make slides: on these
// slides the tree is half of the picture
// e.g. #git-tree("project", ("main.c",), states: ("main.c": edited))
#let git-tree(..args) = block(text(size: 1.4em, project-tree(..args)))

// ---------------------------------------------------------------------------
// Drawings for the commit graphs
// ---------------------------------------------------------------------------

// a commit: a circle, its short hash and message below it, drawn centered
// on (x, y) of a #drawing; `on` marks the commit made on this step
// e.g. #commit-node(40pt, 60pt, "7cbb829", "Add main.c", on: true)
#let commit-node(x, y, hash, message, on: false) = {
  pin(x, y, circle(
    radius: 9pt,
    fill: if on { changed-fill } else { rgb("eef3f5") },
    stroke: if on { 1.5pt + changed } else { 1pt + accent },
  ))
  // white behind the hash, so the orange one hides the black one below it
  pin(x, y + 17pt, box(fill: white, outset: 1pt, text(font: mono, size: 0.55em, fill: if on { changed } else { black }, hash)))
  pin(x, y + 29pt, box(fill: white, outset: 1pt, text(size: 0.55em, fill: luma(90), message)))
}

// a commit drawn normal, and orange (over it) on the steps it is new
// e.g. #commit-at(35pt, 20pt, "7cbb829", "Add main.c", new: "1-2")
#let commit-at(x, y, hash, message, new: none) = {
  commit-node(x, y, hash, message)
  if new != none { only(new, commit-node(x, y, hash, message, on: true)) }
}

// the arrow from a commit to its parent (from the edge of one circle to the
// edge of the other)
#let parent-arrow(child, parent) = {
  let (x1, y1) = child
  let (x2, y2) = parent
  let dx = (x2 - x1).pt()
  let dy = (y2 - y1).pt()
  let len = calc.sqrt(dx * dx + dy * dy)
  let r = 11
  line-arrow(
    (x1 + dx / len * r * 1pt, y1 + dy / len * r * 1pt),
    (x2 - dx / len * r * 1pt, y2 - dy / len * r * 1pt),
    color: luma(120),
  )
}

// a branch label; the current branch (HEAD) gets an orange HEAD chip next
// to it, so it is not marked by color alone
// e.g. #pin(110pt, 140pt, branch-label("main", head: true))
#let branch-label(name, head: false) = stack(
  dir: ltr,
  spacing: 3pt,
  ..if head {
    (box(fill: changed, inset: (x: 0.3em, y: 0.25em), radius: 0.2em, text(
      font: mono,
      size: 0.5em,
      weight: "bold",
      fill: white,
      "HEAD",
    )),)
  },
  box(fill: accent, inset: (x: 0.4em, y: 0.25em), radius: 0.2em, text(
    font: mono,
    size: 0.55em,
    weight: "bold",
    fill: white,
    name,
  )),
)

#slide[
  = Version Control with Git #text(size: 10pt, weight: "regular")[\ _Save points for your code_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #pro-git
    - Chapter 1 - _Getting Started_
      - Section 1.1 - _About Version Control_
      - Section 1.3 - _What is Git?_
    - Chapter 2 - _Git Basics_
      - Sections 2.1 - 2.3, 2.5
    - Chapter 3 - _Git Branching_
      - Section 3.1 - _Branches in a Nutshell_
]

#slide[
  == What Is Git
  A program that remembers every version of a project

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #set text(size: 0.85em)
    - a *version control system*: keeps the _history_ of the files
    - go back to any version, see *who* changed *what* and *why*
    - many people work on the *same code* at the same time
    - *distributed*: every copy has the whole history
    - written in 2005 by _Linus Torvalds_, for Linux
  ][
    #set text(size: 0.85em)
    ❌ *Without git*
    #git-tree("Desktop", ("project.zip", "project_final.zip", "project_final_v2.zip"))
    #v(0.4em)
    #uncover("2-")[
      ✅ *With git*
      #git-tree("project", (".git/", "Makefile", "main.c"), states: (
        ".git/": (accent, none, [the whole history]),
      ))
    ]
  ]

  #v(1fr)
  #only("1-2")[💡 the folder with the files and their history is a *repository* (_repo_)]

  // where the repositories are shared, as a popup in the middle of the
  // slide, on its own step (overlay: last in the body)
  #only(3, place(center + horizon, popup(width: 320pt)[Sharing a repository][
    #icon-rows((
      ("☁️", [websites that keep git repositories, for free]),
      ("🌐", [_GitHub_, _GitLab_, _Codeberg_, _Bitbucket_, ...]),
      ("⚠️", [git ≠ GitHub: git works without them]),
    ))
  ]))
]

#slide[
  == Commits
  A commit is a snapshot of the whole project, with a message

  #git-grid(
    {
      set text(size: 0.85em)
      [- a *commit* saves the state of *all* the files]
      [- its id is the *hash*: `7cbb829`]
      [- it has an author, a date and a *message*]
      [- it points to its *parent*, the commit before it]
    },
    drawing(width: 230pt, height: 70pt, {
      let c1 = (35pt, 20pt)
      let c2 = (115pt, 20pt)
      let c3 = (195pt, 20pt)
      commit-at(..c1, "7cbb829", "Add main.c", new: 1)
      uncover("2-", {
        parent-arrow(c2, c1)
        commit-at(..c2, "e5f6e0f", "Add the Makefile", new: 2)
      })
      uncover("3-", {
        parent-arrow(c3, c2)
        commit-at(..c3, "c845fb9", "Fix typo", new: "3-")
      })
    }),
    {
      only(1, git-tree("project", ("main.c",), states: ("main.c": added), rows: 2))
      only(2, git-tree("project", ("Makefile", "main.c"), states: ("Makefile": added), rows: 2))
      only("3-", git-tree("project", ("Makefile", "main.c"), states: ("main.c": edited), rows: 2))
    },
    {
      only(1, git-cmd("$ git add main.c\n$ git commit -m \"Add main.c\""))
      only(2, git-cmd("$ git add Makefile\n$ git commit -m \"Add the Makefile\""))
      only("3-", git-cmd("$ git add main.c\n$ git commit -m \"Fix typo\""))
    },
  )

  #v(1fr)
  #only(1)[💡 like a save point in a game: you can always come back to it]
  #only(2)[💡 the arrow goes from a commit to its parent]
  #only("3-")[💡 the chain of commits is the *history*: `git log --oneline` shows it]
]

#slide[
  == Branches
  A branch is a name that points to a commit

  #let files = ("Makefile", "main.c")
  #let lib = ("lib.c", "lib.h")
  #git-grid(
    columns: (2fr, 3fr),
    {
      set text(size: 0.85em)
      [- a *branch* is a label that moves]
      [- `HEAD`: the branch you are on]
      [- a commit moves *this* branch]
      [- work on a branch, `main` stays safe]
      [- *merge* brings the work into `main`]
    },
    drawing(width: 280pt, height: 112pt, {
      let a = (25pt, 64pt)
      let b = (95pt, 64pt)
      let f = (170pt, 15pt)
      let m = (170pt, 64pt)
      let g = (250pt, 64pt)
      commit-at(..a, "e5f6e0f", "Add the Makefile")
      parent-arrow(b, a)
      commit-at(..b, "c845fb9", "Fix typo")
      parent-arrow(f, b)
      commit-at(..f, "7bf49e7", "Add lib.c", new: 1)
      uncover("2-", {
        parent-arrow(m, b)
        commit-at(..m, "979fd82", "Fix a bug", new: 2)
      })
      uncover("3-", {
        parent-arrow(g, m)
        parent-arrow(g, f)
        commit-at(..g, "a421fff", "Merge 'feature'", new: "3-")
      })
      // the labels move: one placement per step (placed, they take no space)
      only(1, pin(b.at(0), 104pt, branch-label("main")))
      only(2, pin(m.at(0), 104pt, branch-label("main", head: true)))
      only("3-", pin(g.at(0), 104pt, branch-label("main", head: true)))
      only(1, pin(f.at(0) + 55pt, 15pt, branch-label("feature", head: true)))
      only("2-", pin(f.at(0) + 45pt, 15pt, branch-label("feature")))
    }),
    {
      only(1, git-tree("project", files + lib, states: ("lib.c": added, "lib.h": added), rows: 4))
      only(2, git-tree("project", files, states: ("main.c": edited), rows: 4))
      only("3-", git-tree("project", files + lib, states: ("lib.c": merged, "lib.h": merged), rows: 4))
    },
    {
      only(1, git-cmd("$ git switch -c feature\n$ git add lib.c lib.h\n$ git commit -m \"Add lib.c\""))
      only(2, git-cmd("$ git switch main\n$ git commit -am \"Fix a bug\""))
      only("3-", git-cmd("$ git merge feature"))
    },
  )

  #v(1fr)
  #only(1)[💡 `git switch -c` makes a branch and moves `HEAD` to it]
  #only(2)[💡 back on `main`, `lib.c` and `lib.h` are not in the folder]
  #only("3-")[💡 the merge commit has two parents; `main` now has `lib.c` too]
]

#slide[
  == From the Editor to the Server
  A change goes through four places

  // the four places in a row; on its step(s), the orange box is drawn over
  // the gray one (same size, so nothing moves)
  #let stage(name, sub, steps) = box(width: 100%, {
    tool-box(name, sub: sub, width: 100%)
    only(steps, place(top + left, tool-box(name, sub: sub, on: true, width: 100%)))
  })
  // an arrow with the command that moves the change above it
  #let step-arrow(cmd) = stack(
    spacing: 0.25em,
    text(font: mono, size: 0.6em, fill: accent, weight: "bold", cmd),
    draw-arrow(length: 2.6em),
  )
  #block(width: 100%, {
    set text(size: 0.8em)
    grid(
      columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr),
      column-gutter: 0.4em,
      align: center + horizon,
      stage("working directory", [the files you edit], 1),
      step-arrow("git add"),
      stage("staging area", [the next commit], 2),
      step-arrow("git commit"),
      stage("local repository", [`.git/`, your computer], 3),
      step-arrow("git push"),
      stage("remote repository", [GitHub, GitLab, ...], "4-"),
    )
  })

  #v(0.6em)
  #let files = ("Makefile", "main.c")
  #git-grid(
    {
      set text(size: 0.85em)
      [- you *edit* the files]
      uncover("2-")[#block[- `git add`: pick what goes in the commit]]
      uncover("3-")[#block[- `git commit`: save in the *local* repository]]
      uncover("4-")[#block[- `git push`: send to the *remote*]]
      uncover("5-")[#block[- `git pull`: get the others' commits]]
    },
    // here the picture is the row above: commands and tree on the right
    align(left, {
      only(1, git-cmd("(edit main.c in the editor)"))
      only(2, git-cmd("$ git add main.c"))
      only(3, git-cmd("$ git commit -m \"Fix typo\""))
      only(4, git-cmd("$ git push"))
      only("5-", git-cmd("$ git pull"))
      v(0.4em)
      only(1, git-tree("project", files, states: ("main.c": edited), rows: 3))
      only(2, git-tree("project", files, states: ("main.c": staged), rows: 3))
      only(3, git-tree("project", files, states: ("main.c": committed), rows: 3))
      only(4, git-tree("project", files, states: ("main.c": pushed), rows: 3))
      only("5-", git-tree("project", files + ("lib.c",), states: ("main.c": pushed, "lib.c": pulled), rows: 3))
    }),
    [],
    [],
  )

  #v(1fr)
  #only("1-3")[💡 the first three places are on *your computer*; `git status` shows what is in each]
  #only(4)[💡 the remote is *shared*: now your colleagues can get your commit]
  #only("5-")[💡 a colleague pushed `lib.c`, `git pull` brought it]
]

#slide[
  == Commit vs Push
  A commit stays on your computer until you push it

  #grid(
    columns: (2fr, 3fr),
    column-gutter: 1.5em,
    row-gutter: 0.8em,
    {
      set text(size: 0.85em)
      [=== `git commit`]
      [- saves a snapshot in the *local* repository]
      [- works *offline*, only you see it]
      [=== `git push`]
      [- sends the commits to the *remote*]
      [- now the others can `git pull` them]
    },
    stack(spacing: 0.6em, block(width: 100%, text(size: 0.7em)[
      #reveal-terminal(before: none, lines: (8, 11, 11), full: false)[```terminal
      $ git add main.c
      $ git commit -m "Fix typo"
      [main c845fb9] Fix typo
       1 file changed, 1 insertion(+), 1 deletion(-)
      $ git status
      On branch main
      Your branch is ahead of 'origin/main' by 1 commit.
        (use "git push" to publish your local commits)
      $ git push
      To github.com:alice/project.git
         e5f6e0f..c845fb9  main -> main
      ```]
    ]), {
      only(1, git-tree("project", ("Makefile", "main.c"), states: ("main.c": not-pushed)))
      only("2-", git-tree("project", ("Makefile", "main.c"), states: ("main.c": pushed)))
    }),
  )

  #v(1fr)
  #only(2)[💡 `e5f6e0f..c845fb9`: the server moved `main` to your commit]
  #only(1)[💡 _ahead by 1 commit_: `c845fb9` is only on your computer, the server does not have it]

  // the takeaway, as a popup in the middle of the slide, on its own step
  // (overlay: last in the body)
  #only(3, place(center + horizon, popup(width: 320pt)[Commit vs Push][
    #icon-rows((
      ("💾", [*commit* = save, on your computer]),
      ("📤", [*push* = share, on the server]),
      ("⚠️", [not pushed: your colleagues do not see it]),
    ))
  ]))
]

#slide[
  == A Few Commands
  Enough for a project

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #key-table(header: ([*command*], [*what it does*]), (
      ([Start], none),
      ([`git clone <url>`], [copy a remote repository]),
      ([`git init`], [new repository, here]),
      ([Every day], none),
      ([`git status`], [what changed, what next]),
      ([`git add <file>`], [stage a change]),
      ([`git commit -m "..."`], [save a snapshot]),
      ([`git push`], [send the commits]),
      ([`git pull`], [get the others' commits]),
    ), size: 0.75em)
  ][
    #key-table(header: ([*command*], [*what it does*]), (
      ([Look], none),
      ([`git log --oneline`], [the history]),
      ([`git diff`], [changes not staged yet]),
      ([Branches], none),
      ([`git branch`], [list the branches]),
      ([`git switch -c <name>`], [new branch, go to it]),
      ([`git switch <name>`], [go to a branch]),
      ([`git merge <name>`], [merge it into this branch]),
    ), size: 0.75em)
  ]

  #v(1fr)
  💡 `git status` is always safe: it tells you what to do next
]
