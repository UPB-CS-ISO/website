# 02. Files Management

In the first lab you learned to move around Sway and to run your first commands in the terminal. Now it is time to
work with **files**. Everything you keep on a computer (documents, movies, programs, settings) is a file, stored
somewhere in a big tree of folders. In this lab you will learn how to **find your way** in this tree, how to **name**
any file with a **path**, and how to create, copy, move and delete files, first with commands and then with
**Yazi**, a file manager that runs in the terminal.

The most important idea of this lab is the **path**. Take your time with it: every command that works with files,
in this lab and in all the following ones, receives paths.

## Objectives

- Understand how files and folders are organized in Linux: one tree, starting from `/`
- Write **absolute** and **relative** paths, and know what `.`, `..` and `~` mean
- Calculate the absolute path from the current directory and a relative path
- Read the **manual page** of a command and understand its `SYNOPSIS`
- Navigate with `pwd`, `cd`, `ls` and `tree`
- Create, copy, move, rename and delete files and folders with `mkdir`, `touch`, `nano`, `cp`, `mv`, `rm` and `rmdir`
- Install and use **Yazi** to manage files with a few keys, including tabs

## Resources

1. *[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor
de Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)*
   - Chapter 2 - *Utilizarea sistemului de fișiere*, sections 2.1.2, 2.1.3, 2.3.1, 2.3.2, 2.3.4 and 2.3.5
2. *Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021*
   - Chapter 2 - *Basic Commands and Directory Hierarchy*, sections 2.3, 2.4, 2.5.3, 2.12, 2.13 and 2.19
3. *[Yazi - Quick Start](https://yazi-rs.github.io/docs/quick-start)*
4. *[Yazi - Installation](https://yazi-rs.github.io/docs/installation)*
5. The lecture slides: [02. Files Management](/docs/lectures/02)
6. The manual pages: `man ls`, `man cp`, `man mv`, `man rm`, `man mkdir`, `man tree`

## The File System Tree

On Windows, every drive has its own tree: `C:\`, `D:\`, and so on. On Linux there is **only one tree**, and it starts
from a single folder called the **root**, written `/`. Everything is somewhere below it: the programs, the settings,
the other disks and your own files.

```
/
├── bin/          programs (ls, cp, mv, ...)
├── etc/          system wide settings
├── home/         the users' files
│   └── student/  your home folder, also called ~
│       ├── Downloads/
│       ├── Movies/
│       └── watchlist.txt
├── tmp/          temporary files, anyone can write here
└── usr/          installed software
```

Your own files live in your **home folder**, `/home/student` (use your own user name instead of `student`).
Usually you can write **only** in your home folder and in `/tmp`.

:::info

In Linux, a **folder** and a **directory** are the same thing. The commands and the manual pages say *directory*;
the file managers usually say *folder*.

:::

:::tip

Names in Linux are **case sensitive**: `Movies`, `movies` and `MOVIES` are three different names. Windows does not
care about upper and lower case letters, Linux does.

:::

## Paths

A **path** tells the operating system **where** a file or a folder is. It is the list of folders you walk through,
separated by `/`, and at the end the name of the file.

### The Current Directory

Every terminal (and every running program) has **one current directory**: the folder where it "is" right now. When
you open a new terminal, the current directory is your home folder. The prompt shows it (`~` means your home):

```
[student@fedora ~]$ pwd
/home/student
```

`pwd` (*print working directory*) prints the current directory as an absolute path.

### Absolute Paths

An **absolute path** starts with `/`. It is the **full** address of a file, from the root down to the file, so it
works the same no matter where you are:

```
/home/student/Movies/the_odyssey.mkv
/etc/hostname
/tmp
```

Think of the full postal address of a person: country, city, street, number, name. Anyone can use it.

### Relative Paths

A **relative path** does **not** start with `/`. It starts from the **current directory**. If you are in
`/home/student`, then:

```
Movies/the_odyssey.mkv      means   /home/student/Movies/the_odyssey.mkv
watchlist.txt               means   /home/student/watchlist.txt
```

A relative path is shorter, but it **depends on where you are**: the same relative path means another file when
you are in another folder. Think of directions such as "the second door on the left": they are correct only from
where you are standing.

### `.` and `..`

Every folder has two hidden entries:

| Name | Means |
|-|-|
| `.` | the folder **itself** (the current directory) |
| `..` | the **parent** folder, one level up |

They can be used anywhere in a path, and `..` can be repeated to go up several levels. If you are in
`/home/student/Movies`:

```
/
└── home
    ├── student
    │   ├── Movies            <-- .      (you are here)
    │   │   └── the_odyssey.mkv
    │   ├── Downloads
    │   │   └── supergirl.mp4
    │   └── watchlist.txt
    └── bob
        └── notes.txt
```

| Relative path | Walk | Absolute path |
|-|-|-|
| `./the_odyssey.mkv` | stay in `Movies`, open the file | `/home/student/Movies/the_odyssey.mkv` |
| `../watchlist.txt` | up to `student`, open the file | `/home/student/watchlist.txt` |
| `../Downloads/supergirl.mp4` | up to `student`, down into `Downloads` | `/home/student/Downloads/supergirl.mp4` |
| `../../bob/notes.txt` | up to `student`, up to `home`, down into `bob` | `/home/bob/notes.txt` |

:::tip

The root has no parent: `/..` is still `/`.

:::

### From Relative to Absolute

This is how the operating system turns a relative path into an absolute one:

1. **join** the current directory, a `/` and the relative path;
2. from left to right, **drop** every `.`;
3. from left to right, every `..` **removes itself and the folder that is still left before it**.

For example, from `/home/student/Movies` the path `../Downloads/./../../bob/notes.txt` becomes:

```
/home/student/Movies/../Downloads/./../../bob/notes.txt      1. join
/home/student/Movies/../Downloads/../../bob/notes.txt        2. drop the .
/home/student/Downloads/../../bob/notes.txt                  3. Movies/.. cancel each other
/home/student/../bob/notes.txt                               3. Downloads/.. cancel each other
/home/bob/notes.txt                                          3. student/.. cancel each other
```

:::caution

A `..` does not always cancel its neighbor: it removes the last folder **still left** before it. In the example
above, the last `..` removed `student`, which was far away from it in the original path.

:::

You can check your calculation with the `realpath` command, which prints the absolute path of any path:

```
[student@fedora Movies]$ realpath ../Downloads/./../../bob/notes.txt
/home/bob/notes.txt
```

### The Home Folder: `~`

In the terminal, `~` is replaced with the path of your home folder, so `~/Movies` is `/home/student/Movies`, from
any directory. Paths that start with `~` behave like absolute paths.

:::info

`~` is a feature of the shell (the program that reads your commands). It does not work in every program: for
example, Windows and most graphical applications do not understand it.

:::

### Every File is a Path

When a command expects a **file** or a **folder**, you can give it **any path** to it: a name, a relative path, an
absolute path or a path with `~`. From `/home/student/Movies`, all these commands print the same file:

```
$ cat ../watchlist.txt
$ cat /home/student/watchlist.txt
$ cat ~/watchlist.txt
$ cat ../../student/Downloads/../watchlist.txt
```

You can also mix relative and absolute paths in the same command: `cp ../watchlist.txt /tmp/`.

## Reading the Manual

Every command has a **manual page**: `man ls`, `man cp`, and so on. Scroll with the arrow keys and
<kbd>Space</kbd>, search with <kbd>/</kbd> followed by a word and <kbd>Enter</kbd>, and quit with <kbd>q</kbd>.

The most useful part of a manual page is the `SYNOPSIS`: it shows how to call the command.

```
SYNOPSIS
       cp [OPTION]... SOURCE DEST
       cp [OPTION]... SOURCE... DIRECTORY
```

| Notation | Meaning |
|-|-|
| `[ ]` | optional |
| `...` | can repeat |
| `SOURCE`, `DEST`, `FILE`, `DIRECTORY` | a **path** (relative or absolute) |
| `-r` | a short option |
| `--recursive` | a long option, often the same as a short one |

:::caution

Always read the manual **before** searching online or asking an AI. The manual on your computer is written for the
**version installed** on your computer. An answer found online might be for another version, or simply wrong.

:::

:::tip

Most commands also print a short summary of their options with `--help`, for example `ls --help`.

:::

## Navigation

| Command | What it does |
|-|-|
| `pwd` | Prints the current directory |
| `cd <directory>` | Changes the current directory |
| `cd` or `cd ~` | Goes to your home folder |
| `cd -` | Goes back to the previous directory |
| `ls` | Lists the current directory |
| `ls <directory>` | Lists another directory |
| `ls -a` | Also lists the hidden files (names that start with `.`) |
| `ls -l` | Long listing: type, permissions, owner, size, date |
| `ls -lh` | Long listing with human readable sizes (`4.0K`, `21M`) |
| `tree` | Lists a folder and **everything inside it** |
| `tree -L 1` | Only one level deep |
| `tree -d` | Only the folders |

In the output of `ls -l`, the first letter is the **type**: `d` for a directory, `-` for a regular file.

```
$ ls -l
drwxr-xr-x  2 student student  4096 Sep 20 18:02 Downloads
drwxr-xr-x  2 student student  4096 Sep 26 21:15 Movies
-rw-r--r--  1 student student 21504 Sep 28 21:40 watchlist.txt
```

`tree` is not always installed. On Fedora install it with `sudo dnf install tree`, on Ubuntu with
`sudo apt install tree`.

## Managing Files

| Command | What it does |
|-|-|
| `mkdir <folder>` | Creates a folder |
| `mkdir -p <path>` | Creates a folder and all its missing parents |
| `touch <file>` | Creates an empty file (or only updates the date of an existing one) |
| `nano <file>` | Opens a text editor, the file is created when you save (<kbd>Ctrl</kbd>+<kbd>O</kbd> saves, <kbd>Ctrl</kbd>+<kbd>X</kbd> exits) |
| `cp <source> <destination>` | Copies a file |
| `cp <source>... <folder>` | Copies several files into a folder |
| `cp -r <folder> <destination>` | Copies a folder and everything inside it |
| `mv <source> <destination>` | Moves or **renames** a file or a folder |
| `mv <source>... <folder>` | Moves several files into a folder |
| `rmdir <folder>` | Deletes an **empty** folder |
| `rm <file>` | Deletes a file |
| `rm -r <folder>` | Deletes a folder and everything inside it |

:::info

Renaming is moving to a new name in the same folder: `mv movie.mkv project_hail_mary.mkv`.

:::

:::caution

When you give `cp` or `mv` **several** sources, the last parameter must be a **folder** that already exists.

:::

:::danger

There is **no trash** in the terminal: `rm` deletes files **permanently**, and `rm -r` deletes a whole folder with
everything inside it. Read the command twice before pressing <kbd>Enter</kbd>, and never run `rm -r` with a path you
do not fully understand.

:::

## Yazi

**Yazi** is a file manager that runs **in the terminal**. It shows your folders in three columns (the parent folder,
the current folder and a preview) and does the work of `cd`, `ls`, `mkdir`, `touch`, `cp`, `mv` and `rm` with a few
keys. It is fast and works well with Sway, because you never need the mouse.

### Installing Yazi on Fedora 44

Yazi is not in the official Fedora repositories. It is available from **COPR**, a service where Fedora users build
extra packages. Enable the Yazi COPR repository and install the package:

```
sudo dnf copr enable lihaohong/yazi
sudo dnf install yazi
```

`dnf` asks you to confirm twice: once to enable the repository, once to install the packages. It also installs a
few optional helpers that Yazi uses for previews. Check that it works:

```
yazi --version
```

:::caution

COPR repositories are **unofficial**: they are built by Fedora users, not by the Fedora project. The Yazi COPR
repository is the one listed on the [official Yazi installation page](https://yazi-rs.github.io/docs/installation).

:::

:::tip

If `dnf` says `No such command: copr`, install the plugin first with `sudo dnf install dnf5-plugins`, then run the
commands again.

If the COPR repository does not have a package for your Fedora version yet, you can build Yazi yourself with Rust's
package manager, `cargo` (it takes a few minutes):

```
sudo dnf install cargo
cargo install --force yazi-build
```

:::

### A Better Terminal for Yazi: Ghostty

Yazi works in any terminal, including `foot`, the default terminal of Sway. It looks better in a modern terminal such
as **[Ghostty](https://ghostty.org)**: Ghostty comes with the icons that Yazi uses for files and folders already
built in, and Yazi can show **previews of pictures** inside it. Installing it is optional, but recommended.

Ghostty is not in the official Fedora repositories either. Install it from its COPR repository, the one listed on the
[official Ghostty installation page](https://ghostty.org/docs/install/binary):

```
sudo dnf copr enable scottames/ghostty
sudo dnf install ghostty
```

Start it from the application launcher (<kbd>$mod</kbd> + <kbd>d</kbd>, type `ghostty`) or by running `ghostty` in
a terminal, then run `yazi` inside it.

:::tip

To open Ghostty instead of `foot` with <kbd>$mod</kbd> + <kbd>Enter</kbd>, edit your Sway configuration file
`~/.config/sway/config` (see [Modding Sway](/docs/labs/01#modding-sway) in lab 01): replace `foot` with `ghostty` in
the line `set $term foot` (or in the line `bindsym $mod+Return exec foot`), then reload the configuration with
<kbd>$mod</kbd> + <kbd>Shift</kbd> + <kbd>c</kbd>.

:::

### Using Yazi

Start it with `yazi`, or with a folder: `yazi ~/Downloads`. Quit with <kbd>q</kbd>. Press <kbd>F1</kbd> or
<kbd>~</kbd> for the help, which lists every key.

| Key | Action | Like |
|-|-|-|
| <kbd>↑</kbd> <kbd>↓</kbd> (or <kbd>k</kbd> <kbd>j</kbd>) | Choose a file | |
| <kbd>←</kbd> (or <kbd>h</kbd>) | Go to the parent folder | `cd ..` |
| <kbd>→</kbd> (or <kbd>l</kbd>) | Open the folder or the file | `cd` |
| <kbd>.</kbd> | Show / hide hidden files | `ls -a` |
| <kbd>Space</kbd> | Select a file, for several files | |
| <kbd>a</kbd> | Create a file; a name ending with `/` creates a folder | `touch`, `mkdir` |
| <kbd>r</kbd> | Rename | `mv` |
| <kbd>y</kbd> then <kbd>p</kbd> | Copy (*yank*), then paste | `cp` |
| <kbd>x</kbd> then <kbd>p</kbd> | Cut, then paste | `mv` |
| <kbd>d</kbd> | Move to the trash | |
| <kbd>D</kbd> | Delete permanently | `rm` |
| <kbd>q</kbd> | Quit | |

:::info

The <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd> keys are the same as in Sway and `vi` (see lab 01).

:::

:::caution

<kbd>d</kbd> moves files to the **trash** (`~/.local/share/Trash`), so they can be restored. <kbd>D</kbd> deletes
them **permanently**, like `rm`.

:::

### Tabs

Yazi can keep **several folders open**, one in each **tab**. Every tab has its own current directory, so tabs make
copying and moving between two folders easy.

| Key | Action |
|-|-|
| <kbd>t</kbd> then <kbd>t</kbd> | Open a new tab, in the current folder |
| <kbd>1</kbd> ... <kbd>9</kbd> | Go to tab 1 ... 9 |
| <kbd>[</kbd> <kbd>]</kbd> | Go to the previous / next tab |
| <kbd>Ctrl</kbd>+<kbd>c</kbd> | Close the current tab |

To copy a file from `~/Downloads` to `~/Movies`: open `~/Downloads` in tab 1, open a new tab with
<kbd>t</kbd> <kbd>t</kbd> and go to `~/Movies` in tab 2. Go back to tab 1 (<kbd>1</kbd>), choose the file and press
<kbd>y</kbd>, go to tab 2 (<kbd>2</kbd>) and press <kbd>p</kbd>. Use <kbd>x</kbd> instead of <kbd>y</kbd> to move it.

## Troubleshooting

| Problem | Solution |
|-|-|
| `No such file or directory` | The path is wrong. Check the current directory with `pwd`, then check the path with `ls` or `realpath`. Remember that names are case sensitive |
| `cd` says `Not a directory` | The path points to a file, not a folder |
| `rmdir` says `Directory not empty` | `rmdir` deletes only empty folders. Delete what is inside first, or use `rm -r` (carefully) |
| `cp` says `-r not specified; omitting directory` | Add `-r` to copy a folder |
| `mv` or `cp` with several files says `target ... is not a directory` | The last parameter must be an existing folder |
| `Permission denied` | You are trying to write outside your home folder (and `/tmp`) |
| `yazi: command not found` | Yazi is not installed, see [Installing Yazi on Fedora 44](#installing-yazi-on-fedora-44) |
| Yazi shows strange symbols instead of icons | The terminal font has no icons. Everything still works; for icons, use [Ghostty](#a-better-terminal-for-yazi-ghostty) |

## Exercises

The exercises are marked for the two types of lab:

* 🌱 **basic** (1 hour - **AC**): do only the exercises marked with 🌱;
* 🌳 **full** (2 hours - **CD**): do all the exercises, both 🌱 and 🌳.

Do the exercises **in order**: each one uses the files left by the previous ones.

Keep **two terminals side by side** in Sway: one to run the commands, and one where you check the result with
`tree`, `ls` or `pwd`. In the paths below, replace `student` with your user name (run `whoami` to find it).

### Setup

1. 🌱 **The practice tree**:
   1. Run these commands to create the folders and files used in the exercises (copy them from the browser with
      <kbd>Ctrl</kbd>+<kbd>C</kbd> and paste them in the terminal with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>):

      ```
      mkdir -p ~/lab02/Photos ~/lab02/Games/2026/puzzles ~/lab02/Recipes
      touch ~/lab02/books.txt ~/lab02/.secret
      touch ~/lab02/Photos/cat.jpg ~/lab02/Photos/dog.jpg
      touch ~/lab02/Games/chess.txt ~/lab02/Games/2026/puzzles/sudoku.txt
      ```

   2. Install `tree` with `sudo dnf install tree`, if it is missing.
   3. Run `tree ~/lab02`.

   **Check:** you see this tree (the order of the lines might be a little different). Keep it open in the second
   terminal, you will need it in every exercise.

   ```
   /home/student/lab02
   ├── books.txt
   ├── Games
   │   ├── 2026
   │   │   └── puzzles
   │   │       └── sudoku.txt
   │   └── chess.txt
   ├── Photos
   │   ├── cat.jpg
   │   └── dog.jpg
   └── Recipes
   ```

   <small>→ [The File System Tree](#the-file-system-tree) · [Navigation](#navigation)</small>

### Paths

If a command prints `No such file or directory`, the path is wrong: fix it and run the command again.

2. 🌱 **Where am I**: Go to the `Games` folder using an **absolute** path, then into `puzzles` using a **relative**
   path, then back to `~/lab02` with a **single** `cd` that uses only `..`. Print the current directory after every
   step.

   **Check:** you end up in `/home/student/lab02`. <small>→ [The Current Directory](#the-current-directory) · [Absolute Paths](#absolute-paths)</small>
3. 🌱 **Absolute paths**: From your home folder, show the details of `cat.jpg`, of `sudoku.txt` and of the `Recipes`
   folder **itself** (not what is inside it) with a **single** `ls` command and **absolute** paths. Look in `man ls`
   for the option that lists a folder itself.

   **Check:** you get exactly three lines, and the one of `Recipes` starts with `d`. <small>→ [Absolute Paths](#absolute-paths) · [Reading the Manual](#reading-the-manual)</small>
4. 🌱 **Relative paths**: Do the same from `~/lab02`, this time with **relative** paths. Then, from `~/lab02/Games`,
   list the contents of `Photos` and of `Recipes` with a **single** `ls` and relative paths.

   **Check:** the last command shows the two pictures and an empty `Recipes`. <small>→ [Relative Paths](#relative-paths)</small>
5. 🌱 **Going up and down**: From `~/lab02/Games/2026/puzzles`, show the details of `books.txt` and of `dog.jpg` with a
   **single** `ls` and relative paths. Then go to `Photos` with a **single** `cd`, and from there back to `puzzles`
   with another **single** `cd`, both with relative paths.

   **Check:** you end up in `/home/student/lab02/Games/2026/puzzles`. <small>→ [`.` and `..`](#-and-)</small>
6. 🌳 **Calculate**: Go to `~/lab02/Games`. Create the file `~/lab02/answers.txt` with `nano`, **without leaving**
   `Games`. In it, write the absolute path of each of these relative paths:
   * `../Photos/dog.jpg`
   * `./2026/../chess.txt`
   * `../../lab02/Recipes/.`
   * `2026/puzzles/../../../books.txt`
   * `../Games/2026/puzzles/../../../Photos/./cat.jpg`
   * `../../../../..`

   **Check:** `realpath` prints the same absolute paths as the ones you wrote. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
7. 🌳 **Tricky paths**: From `~/lab02/Photos`, calculate where `../Games/2026/./../../Photos/../Recipes` leads, and write
   each step of the calculation in `answers.txt`. Go there with a **single** `cd`. Then go back to `Photos` with a
   path that contains **exactly two** `..`.

   **Check:** you are back in `/home/student/lab02/Photos`. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
8. 🌳 **Above the root**: Go to `/` and try to go even higher. Find out, with `realpath` and `ls`, where `/../../..`
   leads. From `/`, reach `~/lab02` with a relative path that starts with `../..`.

   **Check:** `pwd` prints `/` no matter how many times you try to go up, and the last `cd` works. <small>→ [`.` and `..`](#-and-)</small>
9. 🌱 **Same file, many paths**: From `~/lab02/Games/2026`, show the details of `books.txt` with **five** different
   paths: an absolute one, one with `~`, a relative one with only `..`, a relative one that goes through `Photos`,
   and a relative one that goes through **both** `Photos` and `Recipes`.

   **Check:** all five commands print the same line. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
10. 🌳 **Home from anywhere**: List `~/lab02` from `/usr/bin`, from `/tmp` and from `/usr/share/doc`, each time with a
    **relative** path. Write in `answers.txt` how many `..` you needed each time.

    **Check:** the three commands print the same files. <small>→ [The Home Folder: `~`](#the-home-folder-)</small>
11. 🌳 **Fix the path**: Each of these commands fails. Find out why and fix it:
    * `ls ~/lab02/games/2026`
    * `cd ~/lab02/Games/chess.txt`
    * `ls ~/lab2`
    * `ls ~/lab02/Photos/cat.jpg/`
    * `cd ../lab02/Games` (run it from `~/lab02/Photos`)

    **Check:** the fixed commands print no error. <small>→ [Troubleshooting](#troubleshooting)</small>

### Navigation

12. 🌱 **Walk around**: From your home folder, go to `~/lab02/Games/2026/puzzles` with a **single** `cd` and an
    absolute path, then to `~/lab02/Recipes` with a **single** `cd` and a relative path, then home with the
    shortest command you can.

    **Check:** you end up in `/home/student`. <small>→ [Navigation](#navigation)</small>
13. 🌱 **Back and forth**: Go to `/etc`, then to `~/lab02/Recipes`. Without typing any of these two paths again, jump
    back and forth between them twice.

    **Check:** the last `pwd` prints `/home/student/lab02/Recipes`. <small>→ [Navigation](#navigation)</small>
14. 🌱 **Listing**: With a **single** `ls` command, list `~/lab02` so that you see the hidden file, can tell the files
    from the folders, and read the sizes in `K` / `M`.

    **Check:** you found `.secret`, and three folders. <small>→ [Navigation](#navigation)</small>
15. 🌱 **ls with a folder**: From your home folder, list `~/lab02/Photos`, `~/lab02/Games/2026/puzzles` and `/` with a
    **single** `ls`, **without** changing the current directory.

    **Check:** the output has three parts, one for each folder, and `pwd` still prints your home folder. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
16. 🌳 **tree**: Show the tree of `~/lab02`:
    * only the first level;
    * only the folders, but also the hidden ones;
    * with the hidden files, two levels deep.

    Then show only the folders of `/usr`, two levels deep.

    **Check:** only the last command about `~/lab02` shows `.secret`. <small>→ [Navigation](#navigation)</small>

### Managing Files

Work in `~/lab02`, and check the result with `tree ~/lab02` in the second terminal after **every** exercise.

17. 🌱 **Create files**: Create an **empty** file `groceries.txt` and a file `plan.txt` with two lines of text in it.
    Then create `soup.txt`, `pizza.txt` and `cake.txt` in `Recipes` with a **single** command, without going into
    `Recipes`.

    **Check:** `ls -l` shows size `0` for `groceries.txt`, but not for `plan.txt`; `Recipes` has the three new files. <small>→ [Managing Files](#managing-files)</small>
18. 🌱 **Create folders**: Create `Albums/2024/summer` and `Albums/2025/winter` with a **single** command.

    **Check:** `tree` shows both folders. <small>→ [Managing Files](#managing-files)</small>
19. 🌱 **Copy files**: Copy `books.txt` into `Albums`. Copy `cat.jpg` and `dog.jpg` from `Photos` into `Games` with a
    **single** command. Copy `dog.jpg` into `Albums/2025/winter` under the name `snow_dog.jpg`.

    **Check:** the two pictures are both in `Photos` and in `Games`, and `snow_dog.jpg` is in `winter`. <small>→ [Managing Files](#managing-files)</small>
20. 🌱 **Copy a folder**: Copy the whole `Games` folder to `/tmp/Games_backup`. Then run **exactly the same** command a
    second time, and find out where the second copy went. Delete **only** the second copy.

    **Check:** `tree /tmp/Games_backup` shows the same files as `tree ~/lab02/Games`, and nothing more. <small>→ [Managing Files](#managing-files)</small>
21. 🌱 **Rename and move**: Rename `groceries.txt` to `shopping.txt` and move it into `Recipes` with a **single** `mv`.
    Move `plan.txt` and `books.txt` into `Albums` with a **single** command.

    **Check:** `Recipes` has `shopping.txt`; `Albums` has `books.txt` and `plan.txt`; the only `.txt` file left in
    `~/lab02` is `answers.txt` (if you created it). <small>→ [Managing Files](#managing-files)</small>
22. 🌳 **Paths everywhere**: From `~/lab02/Games/2026`, without changing the current directory, copy `cat.jpg` from
    `Photos` into `Recipes` using **only relative** paths. Delete the copy, then copy it again using **only
    absolute** paths.

    **Check:** `Recipes` has `cat.jpg`. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
23. 🌱 **Delete**: Delete `/tmp/Games_backup/chess.txt`. Move `sudoku.txt` from `puzzles` up into `Games/2026`, then
    delete the empty `puzzles` folder. Then delete `Albums/2024` and
    everything in `Albums/2025` using **only** `rmdir` and `rm` (no `-r`).

    **Check:** `Albums` has only `books.txt` and `plan.txt`, and `Games/2026` has only `sudoku.txt`. <small>→ [Managing Files](#managing-files)</small>
24. 🌳 **Delete a folder**: Delete `/tmp/Games_backup` with everything inside it with a **single** command.

    **Check:** `ls /tmp` no longer shows `Games_backup`. <small>→ [Managing Files](#managing-files)</small>

### Yazi

Do these exercises **only with Yazi** (the key table is in [Using Yazi](#using-yazi)). Keep a terminal next to it and
check the result with `tree ~/lab02` after every exercise.

25. 🌱 **Install Yazi**: Install Yazi.

    **Check:** `yazi --version` prints a version number. <small>→ [Installing Yazi on Fedora 44](#installing-yazi-on-fedora-44)</small>
26. 🌱 **Look around**: Open `~/lab02` in Yazi. Walk down into `Albums` and back up to `~/lab02`, first with the arrow
    keys, then without them. Make the hidden file appear, then hide it again.

    **Check:** `.secret` appears and disappears. <small>→ [Using Yazi](#using-yazi)</small>
27. 🌱 **Create and rename**: In `~/lab02`, create a file `menu.txt` and an empty folder `Drafts`. Rename `menu.txt` to
    `dinner.txt`, and rename `soup.txt` in `Recipes` to `tomato_soup.txt`.

    **Check:** `tree` shows `dinner.txt`, `Drafts` and `Recipes/tomato_soup.txt`. <small>→ [Using Yazi](#using-yazi)</small>
28. 🌱 **Copy and move**: Copy `dinner.txt` into `Recipes`. Move `dog.jpg` from `Photos` into `Drafts`.

    **Check:** `dinner.txt` is both in `~/lab02` and in `Recipes`; `dog.jpg` is in `Drafts` and no longer in
    `Photos`. <small>→ [Using Yazi](#using-yazi)</small>
29. 🌳 **Several files**: Copy both pictures from `Games` into `Albums` with a **single** paste. Then move
    `tomato_soup.txt`, `pizza.txt` and `cake.txt` from `Recipes` into `Drafts` with a **single** paste.

    **Check:** `Albums` has `cat.jpg` and `dog.jpg`; `Drafts` has the three recipes. <small>→ [Using Yazi](#using-yazi)</small>
30. 🌱 **Tabs**: Open `Albums`, `Recipes` and `Drafts` in three different tabs. Without leaving any of the three
    folders:
    * copy `plan.txt` into `Recipes`;
    * move `shopping.txt` into `Albums`;
    * move `pizza.txt` and `cake.txt` back into `Recipes` (if you moved them to `Drafts` in exercise 29).

    **Check:** `Recipes` has `plan.txt`, `pizza.txt` and `cake.txt`; `Albums` has `shopping.txt`. <small>→ [Tabs](#tabs)</small>
31. 🌳 **Trash or delete**: Send `dinner.txt` (the one in `~/lab02`) to the trash, and delete `Drafts` permanently. Then,
    from the terminal, find `dinner.txt` in the trash and move it back to `~/lab02`.

    **Check:** `dinner.txt` is back in `~/lab02`, and `Drafts` is gone. <small>→ [Using Yazi](#using-yazi)</small>

### Challenge

32. 🌳 **Reorganize**: Using the terminal for half of the work and Yazi for the other half, change `~/lab02` so that
    `tree ~/lab02` prints exactly this tree (delete everything that is not in it):

    ```
    /home/student/lab02
    ├── Games
    │   ├── 2026
    │   │   └── sudoku.txt
    │   ├── cat.jpg
    │   ├── chess.txt
    │   └── dog.jpg
    ├── Notes
    │   ├── books.txt
    │   └── plan.txt
    └── Recipes
        ├── desserts
        │   └── cake.txt
        └── pizza.txt
    ```

    Try to use as **few** commands as possible, and write their number in `answers.txt` before deleting it.

    **Check:** compare your `tree ~/lab02` with the tree above, line by line (the order of the lines does not matter). <small>→ [Managing Files](#managing-files) · [Using Yazi](#using-yazi)</small>

### Harder Exercises

These exercises start from the tree of the [Challenge](#challenge). Do them only after `tree ~/lab02` shows exactly
that tree.

33. 🌳 **Exactly five**: From `~/lab02/Recipes/desserts`, write a relative path to `sudoku.txt` that contains
    **exactly five** `..` and no `.`. Use it with `ls -l`.

    **Check:** `ls -l` shows `sudoku.txt`, and `realpath` of your path prints `/home/student/lab02/Games/2026/sudoku.txt`. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
34. 🌳 **Shortest path**: Find the **shortest** relative path from `/usr/share/doc` to `~/lab02/Notes`, and the
    shortest one from `~/lab02/Notes` back to `/usr/share/doc`. Use each of them with a single `cd`.

    **Check:** after each `cd`, `pwd` prints the folder you wanted to reach. <small>→ [Relative Paths](#relative-paths)</small>
35. 🌳 **Clean up a path**: Write the **shortest** absolute path equivalent to
    `/home/../../../home/student/lab02/./Notes/../Games/2026/../../Recipes/desserts/..`, first on paper, then check it.

    **Check:** `realpath` prints the path you wrote. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
36. 🌳 **Swap**: Swap the names of `Notes/books.txt` and `Notes/plan.txt` using **only** `mv`.

    **Check:** `ls -l ~/lab02/Notes` shows that `books.txt` now has the size that `plan.txt` had before, and
    `plan.txt` is empty. <small>→ [Managing Files](#managing-files)</small>
37. 🌳 **Mirror**: Create in `/tmp/mirror` the same **folder** structure as `~/lab02` (only the folders, no files),
    with a **single** `mkdir` command.

    **Check:** `tree -d /tmp/mirror` and `tree -d ~/lab02` show the same folders. <small>→ [Managing Files](#managing-files)</small>
38. 🌳 **From far away**: Go to `/tmp`. With a **single** `mv` command and **only relative** paths, move `chess.txt`
    and `cat.jpg` from `Games` into `Recipes/desserts`. Then move them back with a single `mv`, this time from
    `~/lab02/Notes`.

    **Check:** after the first `mv`, `desserts` has three files; after the second one, `tree ~/lab02` shows the
    tree of the [Challenge](#challenge) again (with the names of exercise 36). <small>→ [Every File is a Path](#every-file-is-a-path)</small>
39. 🌳 **Backup with tabs**: With Yazi only, create the folder `~/lab02/Backup`, then copy the `Games`, `Notes` and
    `Recipes` folders into it using **two** tabs and a **single** paste. Delete `Backup` permanently at the end.

    **Check:** before deleting it, `tree ~/lab02/Backup` shows the three folders with all their files. <small>→ [Tabs](#tabs) · [Using Yazi](#using-yazi)</small>

## Wrap-up Questions

Use the **last 5 minutes** of the lab to answer these questions together with your colleagues and the teaching
assistant. There are no wrong answers for the last two.

1. What is the difference between an **absolute** and a **relative** path? How can you tell them apart at a glance?
2. What do `.`, `..` and `~` mean?
3. Why does a relative path stop working when you change the current directory?
4. How does the operating system turn a relative path into an absolute one?
5. What does `[ ]` and `...` mean in the `SYNOPSIS` of a manual page?
6. Why must the last parameter of `cp a b c` be a folder?
7. What is the difference between `rm` in the terminal and <kbd>d</kbd> in Yazi?
8. When would you use the terminal, and when Yazi?
9. What was the hardest path to calculate today?

## Extra

1. **Hidden files**: Run `ls -a ~`. Most of the hidden files and folders are settings of your programs. Find the
   folder where Yazi keeps the trash. <small>→ [Using Yazi](#using-yazi)</small>
2. **The whole tree**: Run `tree -L 1 /` and compare it with the tree in [The File System Tree](#the-file-system-tree).
   Look in `/etc` for the file that keeps the name of your computer (hint: `cat /etc/hostname` and the `hostname`
   command). <small>→ [The File System Tree](#the-file-system-tree)</small>
3. **Yazi help**: Press <kbd>F1</kbd> in Yazi and find the key that filters the files in the current folder by name.
   <small>→ [Using Yazi](#using-yazi)</small>
4. **Ghostty**: Install Ghostty, open `~/lab02/Photos` with Yazi inside it and compare it with Yazi in `foot`. Then
   make Ghostty the terminal that opens with <kbd>$mod</kbd> + <kbd>Enter</kbd>. <small>→ [A Better Terminal for Yazi: Ghostty](#a-better-terminal-for-yazi-ghostty)</small>
