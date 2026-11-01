#import "/src/slides.typ": *
#import "common.typ": *

#slide[
  = Building with `cargo` #text(size: 10pt, weight: "regular")[\ _The build system and package manager of Rust_]
]

#slide[
  == Bibliography
  For this section

  #set text(size: 0.9em)
  + #rust-book
    - Chapter 1.3 - _Hello, Cargo!_
    - Chapter 7 - _Packages, Crates, and Modules_
  + _The Cargo Book_, #link("https://doc.rust-lang.org/cargo/")[online]
]

#slide[
  == A New Project
  `cargo` creates the files, with a fixed layout

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    ```terminal
    $ cargo new sum
        Creating binary (application) `sum` package
    $ cd sum
    $ ls -A
    .git  .gitignore  Cargo.toml  src
    $ ls src
    main.rs
    ```
    #uncover("3-")[
      `src/main.rs`
      ```rust
      fn main() {
          println!("Hello, world!");
      }
      ```
    ]
  ][
    #uncover("2-")[
      `Cargo.toml`, the _manifest_
      ```toml
      [package]
      name = "sum"
      version = "0.1.0"
      edition = "2024"

      [dependencies]
      ```
      #set text(size: 0.9em)
      - *what* to build, not *how*: no rules, no commands
      - also a `git` repository
    ]
  ]
]

#slide[
  == The Same Program in Rust
  Modules instead of headers

  #set text(size: 0.74em)
  #grid(
    columns: (37fr, 28fr, 35fr),
    column-gutter: 0.8em,
    [
      `src/main.rs`
      ```rust
      mod print;
      mod sum;

      fn main() {
          let total = sum::sum(sum::MAX);
          print::print_result("sum", total);
      }
      ```
    ],
    [
      `src/sum.rs`
      ```rust
      pub const MAX: i32 = 10;

      pub fn sum(n: i32) -> i32 {
          let mut s = 0;
          for i in 1..=n {
              s = s + i;
          }
          s
      }
      ```
    ],
    [
      `src/print.rs`
      ```rust
      pub fn print_result(
          label: &str,
          value: i32,
      ) {
          println!("{label} = {value}");
      }
      ```
    ],
  )

  #v(1fr)
  #uncover("2-")[
    #callout[`mod sum;` means: the file `src/sum.rs`; the compiler reads the modules itself, there are no `.h` files to keep in sync]
  ]
]

#slide[
  == `cargo build` and `cargo run`

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.9em)
    ```terminal
    $ cargo build
       Compiling sum v0.1.0 (/home/student/sum)
        Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.36s
    $ cargo run
        Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.01s
         Running `target/debug/sum`
    sum = 55
    ```
    #uncover("2-")[
      ```terminal
      $ touch src/print.rs
      $ cargo build
         Compiling sum v0.1.0 (/home/student/sum)
      ```
    ]
  ][
    #set text(size: 0.9em)
    #uncover("2-")[#block[
      - like `make`, `cargo` compares modification times
      - `run` builds, if needed, then runs
    ]]
    #uncover("3-")[
      ```terminal
      $ cat target/debug/sum.d
      /home/student/sum/target/debug/sum: /home/student/sum/src/main.rs /home/student/sum/src/print.rs /home/student/sum/src/sum.rs
      ```
      💡 a `.d` file, the same format as `gcc -MMD`: the compiler writes the dependencies
    ]
  ]
]

#slide[
  == Dependencies
  Libraries (_crates_) from #link("https://crates.io")[crates.io]

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.2em)[
    #set text(size: 0.85em)
    ```terminal
    $ cargo add rand
        Updating crates.io index
          Adding rand v0.10.3 to dependencies
    ```
    #uncover("2-")[
      `Cargo.toml`
      ```toml
      [dependencies]
      rand = "0.10.3"
      ```
      `src/main.rs`
      ```rust
      let n = rand::random_range(1..=sum::MAX);
      print::print_result("n", n);
      print::print_result("sum", sum::sum(n));
      ```
    ]
  ][
    #set text(size: 0.85em)
    #uncover("3-")[
      ```terminal
      $ cargo run
           Locking 8 packages to latest Rust 1.97.0 compatible versions
         Compiling libc v0.2.191
         Compiling getrandom v0.4.3
         ...
         Compiling rand v0.10.3
         Compiling sum v0.1.0 (/home/student/sum)
          Finished `dev` profile [...] in 2.64s
           Running `target/debug/sum`
      n = 8
      sum = 36
      ```
    ]
    #uncover("4-")[
      💡 `rand` needs other crates: `cargo` downloads and builds all of them; the exact versions go into `Cargo.lock`
    ]
  ]
]

#slide[
  == `make` vs `cargo`

  #set text(size: 0.85em)
  #align(center)[
    #table(
      columns: (auto, 1fr, 1fr),
      align: (left + horizon, left + horizon, left + horizon),
      inset: 0.45em,
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + luma(150)) } else { (bottom: 0.4pt + luma(220)) },
      table.header([], [*`make`* (C)], [*`cargo`* (Rust)]),
      [we write], [the rules and the commands], [only the name and the dependencies],
      [file dependencies], [by hand, or `gcc -MMD`], [found by the compiler],
      [libraries], [`apt install libfoo-dev`, then `-lfoo`], [`cargo add foo`],
      [build / run], [`make`, `./app`], [`cargo build`, `cargo run`],
      [other commands], [the targets we write: `make clean`], [`cargo test`, `check`, `fmt`, `clippy`, `doc`, `clean`],
      [languages], [any: C, LaTeX, these slides], [only Rust],
    )
  ]

  #uncover("2-")[
    💡 the same idea elsewhere: CMake, Meson (C/C++), `go build` (Go), Maven, Gradle (Java), `npm` (JavaScript), `uv`, `pip` (Python)
  ]
]

#slide[
  == `cargo` Cheat Sheet

  #toolbox.side-by-side(columns: (1fr, 1fr), gutter: 1.5em)[
    #key-table(header: ([*command*], [*what it does*]), (
      ([`cargo new name`], [create a project]),
      ([`cargo build`], [build into `target/debug/`]),
      ([`cargo build --release`], [optimized, into `target/release/`]),
      ([`cargo run`], [build and run]),
      ([`cargo check`], [only check for errors, faster]),
    ), size: 0.85em)
  ][
    #key-table(header: ([*command*], [*what it does*]), (
      ([`cargo test`], [build and run the tests]),
      ([`cargo add crate`], [add a dependency]),
      ([`cargo fmt`], [format the code]),
      ([`cargo clippy`], [lints: suggestions for better code]),
      ([`cargo clean`], [remove `target/`]),
    ), size: 0.85em)
  ]
]
