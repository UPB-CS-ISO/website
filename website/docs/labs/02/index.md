# 02. Files Management

In the first lab you learned to move around Sway and to run your first commands in the terminal. Now it is time to
work with **files** and **directories**. Everything you keep on a computer (documents, movies, programs, settings) is a file, stored
somewhere in a big tree of directories. In this lab you will learn how to **find your way** in this tree, how to **name**
any file with a **path**, and how to create, copy, move and delete files, first with commands and then with
**Yazi**, a file manager that runs in the terminal.

The most important idea of this lab is the **path**. Take your time with it: every command that works with files,
in this lab and in all the following ones, receives paths.

## Objectives

- Understand how files and directories are organized in Linux: one tree, starting from `/`
- Write **absolute** and **relative** paths, and know what `.`, `..` and `~` mean
- Calculate the absolute path from the current directory and a relative path
- Read the **manual page** of a command and understand its `SYNOPSIS`
- Navigate with `pwd`, `cd`, `ls` and `tree`, and type less with **TAB completion**
- Find files anywhere in a directory tree with `find`
- Read text files with `cat` and `nano`, and find out the type of any file with `file`
- Create, copy, move, rename and delete files and directories with `mkdir`, `touch`, `nano`, `cp`, `mv`, `rm` and `rmdir`
- Work with names that contain spaces and other special characters
- Install and use **Yazi** to manage files with a few keys, including tabs

## Resources

1. *[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor
de Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)*
   - Chapter 2 - *Utilizarea sistemului de fișiere*, sections 2.1.2, 2.1.3, 2.3.1, 2.3.2, 2.3.4 and 2.3.5
2. *Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021*
   - Chapter 2 - *Basic Commands and Directory Hierarchy*, sections 2.3, 2.4, 2.5.3, 2.5.5, 2.5.6, 2.12, 2.13 and 2.19
3. *[Yazi - Quick Start](https://yazi-rs.github.io/docs/quick-start)*
4. *[Yazi - Installation](https://yazi-rs.github.io/docs/installation)*
5. The lecture slides: [02. Files Management](/docs/lectures/02)
6. The manual pages: `man ls`, `man cp`, `man mv`, `man rm`, `man mkdir`, `man tree`, `man find`, `man file`

## The File System Tree

On Windows, every drive has its own tree: `C:\`, `D:\`, and so on. On Linux there is **only one tree**, and it starts
from a single directory called the **root**, written `/`. Everything is somewhere below it: the programs, the settings,
the other disks and your own files.

```
/
├── bin/          programs (ls, cp, mv, ...)
├── etc/          system wide settings
├── home/         the users' files
│   └── student/  your home directory, also called ~
│       ├── Downloads/
│       ├── Movies/
│       └── watchlist.txt
├── tmp/          temporary files, anyone can write here
└── usr/          installed software
```

Your own files live in your **home directory**, `/home/student` (use your own user name instead of `student`).
Usually you can write **only** in your home directory and in `/tmp`.

:::tip

Names in Linux are **case sensitive**: `Movies`, `movies` and `MOVIES` are three different names. Windows does not
care about upper and lower case letters, Linux does.

:::

## Paths

A **path** tells the operating system **where** a file or a directory is. It is the list of directories you walk through,
separated by `/`, and at the end the name of the file.

### The Current Directory

Every terminal (and every running program) has **one current directory**: the directory where it "is" right now. When
you open a new terminal, the current directory is your home directory. The prompt shows it (`~` means your home):

```shell-session
[student@fedora ~]$ pwd
/home/student
```

`pwd` (*print working directory*) prints the current directory as an absolute path.

### Absolute Paths

An **absolute path** starts with `/`. It is the **full** address of a file, from the root down to the file, so it
works the same no matter where you are:

```
/home/student/Movies/the_odyssey.mkv
/etc/hosts
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
you are in another directory. Think of directions such as "the second door on the left": they are correct only from
where you are standing.

### `.` and `..`

Every directory has two hidden entries:

| Name | Means |
|-|-|
| `.` | the directory **itself** (the current directory) |
| `..` | the **parent** directory, one level up |

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
3. from left to right, every `..` **removes itself and the directory that is still left before it**.

For example, from `/home/student/Movies` the path `../Downloads/./../../bob/notes.txt` becomes:

```
/home/student/Movies/../Downloads/./../../bob/notes.txt      1. join
/home/student/Movies/../Downloads/../../bob/notes.txt        2. drop the .
/home/student/Downloads/../../bob/notes.txt                  3. Movies/.. cancel each other
/home/student/../bob/notes.txt                               3. Downloads/.. cancel each other
/home/bob/notes.txt                                          3. student/.. cancel each other
```

:::caution

A `..` does not always cancel its neighbor: it removes the last directory **still left** before it. In the example
above, the last `..` removed `student`, which was far away from it in the original path.

:::

You can check your calculation with the `realpath` command, which prints the absolute path of any path:

```shell-session
[student@fedora Movies]$ realpath ../Downloads/./../../bob/notes.txt
/home/bob/notes.txt
```

### The Home Directory: `~`

In the terminal, `~` is replaced with the path of your home directory, so `~/Movies` is `/home/student/Movies`, from
any directory. Paths that start with `~` behave like absolute paths.

:::info

`~` is a feature of the shell (the program that reads your commands). It does not work in every program: for
example, Windows and most graphical applications do not understand it.

:::

### Every File is a Path

When a command expects a **file** or a **directory**, you can give it **any path** to it: a name, a relative path, an
absolute path or a path with `~`. From `/home/student/Movies`, all these commands print the same file:

```shell-session
$ cat ../watchlist.txt
$ cat /home/student/watchlist.txt
$ cat ~/watchlist.txt
$ cat ../../student/Downloads/../watchlist.txt
```

You can also mix relative and absolute paths in the same command: `cp ../watchlist.txt /tmp/`.

## Reading the Manual

Every command has a **manual page**: `man ls`, `man cp`, and so on. Scroll with the arrow keys and
<kbd>Space</kbd>, jump to the beginning or the end of the page with <kbd>g</kbd> and <kbd>G</kbd>, see all the
keys with <kbd>h</kbd>, and quit with <kbd>q</kbd>.

A manual page has several parts: `NAME` (what the command does, in one line), `SYNOPSIS` (how to call it),
`DESCRIPTION` (what it does and **all its options**, one after another) and, at the end, `SEE ALSO` (related
commands). The most useful part of a manual page is the `SYNOPSIS`: it shows how to call the command.

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

### Searching in a Manual Page

A manual page is long: `man ls` has more than 200 lines. Do not read it from the top, **search** in it:

| Key | What it does |
|-|-|
| <kbd>/</kbd> `word` <kbd>Enter</kbd> | Searches **forward** for `word` and jumps to the first line that contains it |
| <kbd>n</kbd> | Jumps to the **next** match |
| <kbd>N</kbd> | Jumps to the **previous** match |
| <kbd>?</kbd> `word` <kbd>Enter</kbd> | Searches **backward**, towards the beginning of the page |

When you search, `man` **highlights** every match on the screen. The search is case sensitive: `/Size` does not find
`size`.

For example, say you want `ls` to list the files in **reverse** order, but you do not know the option:

1. Run `man ls`.
2. Type <kbd>/</kbd>, then `reverse`, and press <kbd>Enter</kbd>. The page jumps to the first line that contains
   `reverse`:

   ```
          -r, --reverse
                 reverse order while sorting
   ```

3. This is what you were looking for: the option is `-r` (or the long one, `--reverse`). If the first match is not
   what you need, press <kbd>n</kbd> until you find it.
4. Press <kbd>q</kbd> and try it: `ls -r`.

How to search well:

* **Search for what you want to do**, not for the option, since you do not know it yet: `size`, `hidden`, `reverse`,
  `directories`, `sort`, `time`. The manual is in English, so search for English words.
* **Try other words** if you find nothing: `size`, then `human`, then `bytes`.
* **Read the lines around** every match, a word can appear in many options. Press <kbd>n</kbd> to go to the next one.
* **Jump to an option you already know**: in the manual, an option starts its line, after a few spaces. To jump to
  the description of `-l`, search for `^ *-l`: `^` means "the start of the line" and ` *` means "any number of
  spaces". Searching only for `-l` also stops at every place where `-l` is just mentioned.

:::caution

Always read the manual **before** searching online or asking an AI. The manual on your computer is written for the
**version installed** on your computer. An answer found online might be for another version, or simply wrong.

:::

:::tip

Most commands also print a short summary of their options with `--help`, for example `ls --help`.

:::

## TAB Completion

You do not have to type the full names of files, directories and commands. Type the first letters and press
<kbd>Tab</kbd>:

* if only **one** name starts with those letters, the shell writes the rest of it for you;
* if **several** names start with them, nothing happens: press <kbd>Tab</kbd> a **second** time to see all of them,
  type one or two more letters and press <kbd>Tab</kbd> again.

| You type | You press | The shell |
|-|-|-|
| `cd Mo` | <kbd>Tab</kbd> | completes it to `cd Movies/` (only `Movies` starts with `Mo`) |
| `cat wa` | <kbd>Tab</kbd> | completes it to `cat watchlist.txt` |
| `ls /etc/host` | <kbd>Tab</kbd> <kbd>Tab</kbd> | shows all the names that start with `host`, for example `host.conf  hosts` |
| `ls /etc/she` | <kbd>Tab</kbd> | completes it to `ls /etc/shells` |
| `whoa` | <kbd>Tab</kbd> | completes the **command** to `whoami` |
| `ls --recu` | <kbd>Tab</kbd> | completes the **option** to `ls --recursive` |

Completion works for every part of a path: `cd /us`<kbd>Tab</kbd>`sh`<kbd>Tab</kbd>`do`<kbd>Tab</kbd> becomes
`cd /usr/share/doc/`.

:::tip

Use <kbd>Tab</kbd> all the time: it is faster, and it does not make typing mistakes. If <kbd>Tab</kbd> completes
nothing, even when you press it twice, then **no name** starts with what you typed: the path is wrong.

:::

## Navigation

| Command | What it does |
|-|-|
| `pwd` | Prints the full path of the directory you're in ("print working directory") |
| `cat <file>` | Prints a file's entire contents to the screen |
| `cd <directory>` | Changes the current directory |
| `cd` or `cd ~` | Goes to your home directory |
| `cd -` | Goes to the previous directory (where you were before the last `cd`) |
| `ls` | Lists the current directory |
| `ls <path>` | if `<path>` is a directory, list the directory's contents / if `<path>` is a file, list the details of the file |
| `ls -a` | Also lists the hidden files (names that start with `.`) |
| `ls -l` | Long format listing: type, permissions, owner, size, last modified date |
| `tree` | Lists a directory and **everything inside it**, as a tree |
| `tree -L <number of levels>` | Only `<number of levels>` level deep |

In the output of `ls -l`, the first letter is the **type**: `d` for a directory, `-` for a regular file. On Fedora,
the permissions end with a `.`: it shows that the file has an SELinux label, you can ignore it for now. The first
line, `total`, is the space used by the listed files, in blocks of 1 KB.

```shell-session
$ ls -l
total 32
drwxr-xr-x. 2 student student  4096 Sep 20 18:02 Downloads
drwxr-xr-x. 2 student student  4096 Sep 26 21:15 Movies
-rw-r--r--. 1 student student 21504 Sep 28 21:40 watchlist.txt
```

:::info
`tree` is not always installed. On Fedora install it with `sudo dnf install tree`, on Ubuntu with
`sudo apt install tree`.
:::

### Examples

The examples use this home directory. The prompt shows the name of the current directory (`~` is your home):

```
/home/student
├── .bashrc
├── Downloads
│   └── supergirl.mp4
├── Movies
│   └── the_odyssey.mkv
└── watchlist.txt
```

#### `pwd`

```shell-session
[student@fedora ~]$ pwd
/home/student
[student@fedora ~]$ cd Movies
[student@fedora Movies]$ pwd
/home/student/Movies
```

`pwd` printed the absolute path of the current directory: first the home directory, then, after `cd Movies`, the
`Movies` directory inside it. The prompt shows only the last part of it (`~`, then `Movies`).

#### `cd`

```shell-session
[student@fedora ~]$ cd Movies
[student@fedora Movies]$ cd ../Downloads
[student@fedora Downloads]$ cd /etc
[student@fedora etc]$ cd -
/home/student/Downloads
[student@fedora Downloads]$ cd
[student@fedora ~]$
```

* `cd Movies` went into `Movies`, using a relative path (from `~`).
* `cd ../Downloads` went up to `/home/student`, then down into `Downloads`.
* `cd /etc` went to `/etc`, using an absolute path.
* `cd -` went to the previous directory (`/etc`, where we were before the last `cd`), and printed its path.
* `cd` alone went back to the home directory.

#### The Previous Directory: `cd -`

The shell remembers the directory you were in **before** the last `cd`. `cd -` goes there and prints its path:

```shell-session
[student@fedora ~]$ cd /etc
[student@fedora etc]$ cd ~/Movies
[student@fedora Movies]$ cd -
/etc
[student@fedora etc]$
```

:::caution
`cd -` is **not** a "back" button. A browser's Back button remembers every page you visited, and pressing it again
takes you one more step into the past. The shell remembers only **one** directory, and `cd -` is itself a `cd`, so it
replaces that directory with the one you just left. Pressing it again takes you **forward**, to where you came from.
:::

For example, with three directories:

```shell-session
[student@fedora ~]$ cd /etc
[student@fedora etc]$ cd /tmp
[student@fedora tmp]$ cd ~/Movies
[student@fedora Movies]$ cd -
/tmp
[student@fedora tmp]$ cd -
/home/student/Movies
[student@fedora Movies]$ cd -
/tmp
```

* After `cd /etc`, `cd /tmp` and `cd ~/Movies`, the previous directory is `/tmp`. `/etc` is already forgotten.
* The first `cd -` went to `/tmp`, and the previous directory became `Movies`.
* The second `cd -` did **not** go back to `/etc`. It went to `Movies`, and the previous directory became `/tmp` again.
* From now on, `cd -` only switches between `/tmp` and `Movies`, like the "previous channel" button of a TV remote.

:::caution
Do not confuse `cd -` with `cd ..`, either:

| Command | Goes to | Pressed twice |
|---------|---------|---------------|
| `cd -` | the directory you were in before the last `cd` | you are back where you started |
| `cd ..` | the parent of the current directory, one level up the tree | you are two levels up |
| a browser's Back | the previous page, then the one before it, and so on | the shell has no such command |
:::

:::tip

`cd -` is very useful when you work in two directories at the same time, for example to copy files from one to the other.

:::

#### `ls`

```shell-session
[student@fedora ~]$ ls
Downloads  Movies  watchlist.txt
[student@fedora ~]$ ls Movies
the_odyssey.mkv
[student@fedora ~]$ ls -a
.  ..  .bashrc  Downloads  Movies  watchlist.txt
[student@fedora ~]$ ls -l
total 32
drwxr-xr-x. 2 student student  4096 Sep 20 18:02 Downloads
drwxr-xr-x. 2 student student  4096 Sep 26 21:15 Movies
-rw-r--r--. 1 student student 21504 Sep 28 21:40 watchlist.txt
[student@fedora ~]$ ls -l watchlist.txt
-rw-r--r--. 1 student student 21504 Sep 28 21:40 watchlist.txt
```

* `ls` listed the current directory. It does **not** show what is inside `Movies`.
* `ls Movies` listed the `Movies` directory, without changing the current directory.
* `ls -a` also listed the hidden entries: `.bashrc`, and `.` and `..`, which are in every directory.
* `ls -l` listed one entry per line: the type (`d` directory, `-` file), the permissions, the owner, the size in
  bytes, the date and the name.
* `ls -l watchlist.txt` showed the details of only one file.

#### `tree`

```shell-session
[student@fedora ~]$ tree
.
├── Downloads
│   └── supergirl.mp4
├── Movies
│   └── the_odyssey.mkv
└── watchlist.txt

3 directories, 3 files
[student@fedora ~]$ tree -L 1
.
├── Downloads
├── Movies
└── watchlist.txt

3 directories, 1 file
```

* `tree` showed the current directory and **everything inside it**, and counted the directories and files. The
  count includes the directory it started from, `.`, so there are **3** directories.
* `tree -L 1` stopped after the first level, like `ls`.

## Finding Files: `find`

`ls` and `tree` show you what is in a directory. When you know the **name** of a file but not **where** it is, use
`find`. It walks through a directory and through everything inside it, and prints the path of every entry that
matches what you ask for.

```
find [directory...] [tests]
```

| Command | What it does |
|-|-|
| `find` | Prints every file and directory below the current directory |
| `find <directory>` | Lists everything inside `<directory>`, including subdirectories |
| `find <directory> -name '<name>'` | Only entries whose name is exactly `<name>` |
| `find <directory> -name '*.txt'` | Only the entries whose name ends with `.txt` (`*` means "any characters") |
| `find <directory> -type f` | Only the files |
| `find <directory> -type d` | Only the directories |

:::tip
The tests can be combined, for example:`find ~ -type f -name '*.txt'` finds only the **files** whose name ends with `.txt`.
:::

:::caution

Always put the name after `-name` between quotes (`'*.txt'`). Without quotes, the shell might replace `*.txt` with
the names of the files in the current directory before `find` even starts.

:::

### Examples

Using the same home directory as in the [Navigation examples](#examples):

```shell-session
[student@fedora ~]$ find Movies
Movies
Movies/the_odyssey.mkv
[student@fedora ~]$ find . -name '*.mp4'
./Downloads/supergirl.mp4
[student@fedora ~]$ find ~ -name '*.mp4'
/home/student/Downloads/supergirl.mp4
[student@fedora ~]$ cd Movies
[student@fedora Movies]$ find .. -name watchlist.txt
../watchlist.txt
[student@fedora Movies]$ find .. -type d
..
../Downloads
../Movies
```

* `find Movies` printed the directory itself and everything inside it.
* `find . -name '*.mp4'` searched the current directory (`.`) and everything below it, and found one file.
* `find ~ -name '*.mp4'` found the same file, but printed an **absolute** path: `find` builds every path from the
  directory you give it. A relative start gives relative paths, an absolute start gives absolute paths.
* From `Movies`, `find .. -name watchlist.txt` searched the parent directory and printed `../watchlist.txt`, a relative
  path that works from `Movies`.
* `find .. -type d` printed only the directories of `..`, including `..` itself.

:::tip

`find` also finds the **hidden** files, without any option. The order of the results might be different on your
computer.

:::

:::info

When `find` searches a directory that you are not allowed to read (for example in `/etc`), it prints
`Permission denied` for it and continues. You can ignore these messages.

:::

## Viewing Text Files: `cat` and `nano`

Most files in Linux, especially the settings in `/etc`, are **text files**: you can read them edit them using a text editor. There are two easy
ways to look inside a text file: `cat` and `nano`.

### `cat`

`cat` prints the whole content of one or more files in the terminal, and then the prompt comes back:

```shell-session
[student@fedora ~]$ cat /etc/machine-id
4c8e1f0a9d2b4e7f8a6c3b5d1e0f2a9c
[student@fedora ~]$ cat watchlist.txt
The Odyssey
Project Hail Mary
[student@fedora ~]$ cat /etc/machine-id watchlist.txt
4c8e1f0a9d2b4e7f8a6c3b5d1e0f2a9c
The Odyssey
Project Hail Mary
[student@fedora ~]$ cat notes.txt
[student@fedora ~]$
```

* `cat /etc/machine-id` printed the content of the file: a number that is different on every installation of
  Linux, on a single line.
* `cat watchlist.txt` printed a file from the current directory, using a relative path.
* With several files, `cat` printed them one after another, with nothing in between.
* `notes.txt` is empty, so `cat` printed nothing at all.

:::tip
`cat` is perfect for **short** files. For a long file, the beginning scrolls off the screen: scroll back with
<kbd>Shift</kbd>+<kbd>Page Up</kbd>, or open the file with `nano` instead.
:::

:::caution

Use `cat` only for **text** files. A program or a picture (for example `cat /usr/bin/ls`) prints strange symbols and
can mess up the terminal. If this happens, type `reset` and press <kbd>Enter</kbd> (even if you cannot see what you
type), or close the terminal and open a new one.

:::

### `nano`

`nano` is the text editor from [Managing Files](#managing-files), but you can also use it only to **read** a file.
It shows the file one screen at a time, and it is comfortable for long files:

```shell-session
[student@fedora ~]$ nano /etc/os-release
```

| Key | Action |
|-|-|
| arrow keys, <kbd>Page Up</kbd>, <kbd>Page Down</kbd> | Scroll through the file |
| <kbd>Ctrl</kbd>+<kbd>W</kbd> | Search for a word |
| <kbd>Ctrl</kbd>+<kbd>X</kbd> | Exit (if you changed something, answer `N` to exit without saving) |

To be sure that you do not change the file by mistake, open it in **view mode**, where `nano` does not let you type:
`nano -v /etc/os-release`.

:::info

You can open the system files from `/etc` with `nano` and read them, but you cannot save them: `nano` says
`Permission denied`. Exit without saving.

:::

### `cat` or `nano`?

| Use | When |
|-|-|
| `cat` | The file is short, and you want to see it all at once, in the terminal |
| `nano` | The file is long, you want to scroll or search in it, or you want to edit it |
| `nano -v` | You prefer nano's interface but want read-only mode, so you can't change anything by accident |

### What Kind of File: `file`

The extension (`.txt`, `.jpg`, `.mkv`) is only **part of the name**: Linux does not need it, and it can lie. `file`
looks **inside** a file and tells you what it really is (if `file` is missing, install it with
`sudo dnf install file`):

```shell-session
[student@fedora ~]$ file watchlist.txt notes.txt Movies /etc/hosts
watchlist.txt: ASCII text
notes.txt:     empty
Movies:        directory
/etc/hosts:    ASCII text
[student@fedora ~]$ file /usr/bin/bash
/usr/bin/bash: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, ...
[student@fedora ~]$ cp /etc/hosts photo.jpg
[student@fedora ~]$ file photo.jpg
photo.jpg: ASCII text
```

* `watchlist.txt` and `/etc/hosts` are **text** files: you can read them with `cat` or `nano`.
* `notes.txt` is **empty**, and `Movies` is a **directory**.
* `/usr/bin/bash` is an **ELF executable**, a program: do not `cat` it (the output above is shortened).
* `photo.jpg` is called like a picture, but `file` shows that it is text: the extension does not change what is
  inside.

:::tip

Not sure if you can `cat` a file? Run `file` first: if the answer contains `text`, you can.

:::

## Managing Files

| Command | What it does |
|-|-|
| `mkdir <directory>` | Creates a directory |
| `mkdir -p <path>` | Creates a directory and any missing parents (no error if it already exists) |
| `touch <file>` | Creates an empty file, or updates the "last modified" date of an existing one |
| `nano <file>` | Opens a text editor, the file is created when you save (<kbd>Ctrl</kbd>+<kbd>O</kbd> saves, <kbd>Ctrl</kbd>+<kbd>X</kbd> exits) |
| `cp <source> <destination>` | Copies a file |
| `cp <source>... <directory>` | Copies one or more files into a directory |
| `cp -r <directory> <destination>` | Copies a directory and everything inside it |
| `mv <source> <destination>` | Moves or **renames** a file or a directory |
| `mv <source>... <directory>` | Moves one or more files or directories into a directory |
| `rmdir <directory>` | Deletes an **empty** directory |
| `rm <file>` | Deletes a file |
| `rm -r <directory>` | Deletes a directory and **everything** inside it |

:::info

Renaming is moving to a new name in the same directory: `mv movie.mkv project_hail_mary.mkv`.

:::

:::caution

When you give `cp` or `mv` **several** sources, the last parameter must be a **directory** that already exists.

:::

:::danger

There is **no trash** in the terminal: `rm` deletes files **permanently**, and `rm -r` deletes a whole directory with
everything inside it. Read the command twice before pressing <kbd>Enter</kbd>, and **never** run `rm -r` with a path you
do not fully understand.

:::

### Names with Spaces and Special Characters

The shell splits a command into **words** at every space. A name that contains a space becomes **two** parameters:

```shell-session
[student@fedora ~]$ touch shopping list.txt
[student@fedora ~]$ ls
Downloads  list.txt  Movies  shopping  watchlist.txt
```

`touch` received two names, `shopping` and `list.txt`, and created two files. To give a name with spaces as **one**
parameter, put it between **quotes**, or put a `\` before every space:

```shell-session
[student@fedora ~]$ rm shopping list.txt
[student@fedora ~]$ touch "shopping list.txt"
[student@fedora ~]$ ls -l shopping\ list.txt
-rw-r--r--. 1 student student 0 Sep 29 10:12 'shopping list.txt'
[student@fedora ~]$ rm 'shopping list.txt'
```

* `rm shopping list.txt` deleted the two files created by mistake.
* `"shopping list.txt"`, `'shopping list.txt'` and `shopping\ list.txt` are the **same** name. <kbd>Tab</kbd> completion adds the
  `\` for you.
* `ls` shows the name between quotes, so you can see that the space is part of the name.

Other characters also mean something to the shell: `*`, `?`, `$`, `!`, `&`, `;`, `|`, `<`, `>`, `(`, `)`, `#`,
`'`, `"` and `\`. Put names that contain them between **single** quotes, for example `touch 'rock & roll.txt'`
(between double quotes, `$` and `!` still have a special meaning). For a name with a `'` in it, use double quotes:
`touch "it's mine.txt"`.

A name that starts with `-` looks like an **option**:

```shell-session
[student@fedora ~]$ touch -list.txt
touch: invalid option -- 'l'
Try 'touch --help' for more information.
[student@fedora ~]$ touch ./-list.txt
[student@fedora ~]$ rm ./-list.txt
```

Quotes do not help here, as the name still starts with `-`. `./-list.txt` is another **path** to the same file, and
it does not start with `-`.

:::tip

Name your own files using only letters, digits, `.`, `_` and `-` (but not at the start): `shopping_list.txt` instead of
`shopping list.txt`. They are much easier to use in the terminal.

:::

### Examples

The examples continue one after another, starting from the same home directory as in [Navigation](#navigation).

#### `mkdir`

```shell-session
[student@fedora ~]$ mkdir Series
[student@fedora ~]$ mkdir Series
mkdir: cannot create directory 'Series': File exists
[student@fedora ~]$ mkdir Series/2025/comedy
mkdir: cannot create directory 'Series/2025/comedy': No such file or directory
[student@fedora ~]$ mkdir -p Series/2025/comedy
```

* The first `mkdir Series` created the empty directory `/home/student/Series`.
* The second one failed: the directory already exists.
* `mkdir Series/2025/comedy` failed, because `Series/2025` does not exist yet, and `mkdir` creates only the last
  directory of the path.
* `mkdir -p` created `2025` and then `comedy` inside it. With `-p`, it is not an error if a directory already exists.

#### `touch`

```shell-session
[student@fedora ~]$ touch notes.txt
[student@fedora ~]$ ls -l notes.txt
-rw-r--r--. 1 student student 0 Oct  1 10:15 notes.txt
[student@fedora ~]$ touch watchlist.txt
[student@fedora ~]$ ls -l watchlist.txt
-rw-r--r--. 1 student student 21504 Oct  1 10:16 watchlist.txt
```

* `touch notes.txt` created a new, **empty** file: its size is `0`.
* `touch watchlist.txt` did not change the file, which already existed. It only changed its date to the current
  time.

#### `nano`

```shell-session
[student@fedora ~]$ nano notes.txt
```

`nano` opened `notes.txt` in a text editor, inside the terminal. Type some text, save it with
<kbd>Ctrl</kbd>+<kbd>O</kbd> and <kbd>Enter</kbd>, and exit with <kbd>Ctrl</kbd>+<kbd>X</kbd>. If the file did not
exist, `nano` creates it when you save. The bottom of the screen lists the keys: `^` means <kbd>Ctrl</kbd>.

#### `cp`

```shell-session
[student@fedora ~]$ cp watchlist.txt Series/
[student@fedora ~]$ cp watchlist.txt backup.txt
[student@fedora ~]$ cp Downloads/supergirl.mp4 Movies/the_odyssey.mkv Series/
[student@fedora ~]$ cp Movies Movies_backup
cp: -r not specified; omitting directory 'Movies'
[student@fedora ~]$ cp -r Movies Movies_backup
```

* `cp watchlist.txt Series/` copied the file into the `Series` directory, with the same name: `Series/watchlist.txt`.
* `cp watchlist.txt backup.txt` made a copy with **another name**, in the same directory.
* With **several** sources, `cp` copied all of them into the last parameter, the directory `Series`.
* `cp Movies Movies_backup` refused to copy a directory.
* `cp -r` copied the directory and everything inside it: `Movies_backup/the_odyssey.mkv`.

:::caution

If the destination directory **already exists**, `cp -r Movies Movies_backup` copies `Movies` **inside** it, as
`Movies_backup/Movies`. Run the same command twice and look at the result with `tree`.

:::

#### `mv`

```shell-session
[student@fedora ~]$ mv backup.txt old_watchlist.txt
[student@fedora ~]$ mv old_watchlist.txt Series/
[student@fedora ~]$ mv notes.txt Series/notes_2025.txt
[student@fedora ~]$ mv Series/watchlist.txt Series/supergirl.mp4 Downloads/
```

* `mv backup.txt old_watchlist.txt` **renamed** the file: same directory, new name.
* `mv old_watchlist.txt Series/` **moved** the file into `Series`, with the same name.
* `mv notes.txt Series/notes_2025.txt` moved the file and renamed it, in a single command.
* With several sources, `mv` moved all of them into the last parameter, the directory `Downloads`. A file that already
  exists there with the same name is replaced, without any question.

#### `rmdir`

```shell-session
[student@fedora ~]$ rmdir Series/2025/comedy
[student@fedora ~]$ rmdir Series
rmdir: failed to remove 'Series': Directory not empty
```

* `rmdir Series/2025/comedy` deleted the empty directory `comedy`.
* `rmdir Series` failed: `Series` still has files and the directory `2025` inside it.

#### `rm`

```shell-session
[student@fedora ~]$ rm Series/notes_2025.txt
[student@fedora ~]$ rm Movies_backup
rm: cannot remove 'Movies_backup': Is a directory
[student@fedora ~]$ rm -r Movies_backup
```

* `rm Series/notes_2025.txt` deleted the file, **permanently**.
* `rm Movies_backup` refused to delete a directory.
* `rm -r Movies_backup` deleted the directory and everything inside it.

## Yazi

**Yazi** is a file manager that runs **in the terminal**. It shows your directories in three columns (the parent directory,
the current directory and a preview) and does the work of `cd`, `ls`, `mkdir`, `touch`, `cp`, `mv` and `rm` with a few
keys. It is fast and works well with Sway, because you never need the mouse.

![Yazi](./yazi.png)

### Installing Yazi on Fedora 44

Yazi is not in the official Fedora repositories. It is available from **COPR**, a service where Fedora users build
extra packages. Enable the Yazi COPR repository and install the package:

```bash
sudo dnf copr enable lihaohong/yazi
sudo dnf install yazi
```

`dnf` asks you to confirm twice: once to enable the repository, once to install the packages. It also installs a
few optional helpers that Yazi uses for previews. Check that it works:

```bash
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

```bash
sudo dnf install cargo
cargo install --force yazi-build
```

:::

### A Better Terminal for Yazi: Ghostty

Yazi works in any terminal, including `foot`, the default terminal of Sway. It looks better in a modern terminal such
as **[Ghostty](https://ghostty.org)**: Ghostty comes with the icons that Yazi uses for files and directories already
built in, and Yazi can show **previews of pictures** inside it. Installing it is optional, but recommended.

Ghostty is not in the official Fedora repositories either. Install it from its COPR repository, the one listed on the
[official Ghostty installation page](https://ghostty.org/docs/install/binary):

```bash
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

Start it with `yazi`, or with a directory: `yazi ~/Downloads`. Quit with <kbd>q</kbd>. Press <kbd>F1</kbd> or
<kbd>~</kbd> for the help, which lists every key.

| Key | Action | Like |
|-|-|-|
| <kbd>↑</kbd> <kbd>↓</kbd> (or <kbd>k</kbd> <kbd>j</kbd>) | Choose a file | |
| <kbd>←</kbd> (or <kbd>h</kbd>) | Go to the parent directory | `cd ..` |
| <kbd>→</kbd> (or <kbd>l</kbd>) | Open the directory or the file | `cd` |
| <kbd>.</kbd> | Show / hide hidden files/directories | `ls -a` |
| <kbd>Space</kbd> | Select a file, for several files | |
| <kbd>a</kbd> | Create a file; a name ending with `/` creates a directory | `touch`, `mkdir` |
| <kbd>r</kbd> | Rename | `mv` |
| <kbd>y</kbd> then <kbd>p</kbd> | Copy (*yank*), then paste | `cp` |
| <kbd>x</kbd> then <kbd>p</kbd> | Cut, then paste | `mv` |
| <kbd>d</kbd> | Move to the trash | |
| <kbd>D</kbd> | Delete permanently | `rm` |
| <kbd>q</kbd> | Quit | |

:::info

  The <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd> keys are the same as in Sway and `vi` (see [Default Keybindings](/docs/labs/01#default-keybindings) in lab 01).

:::

:::caution

<kbd>d</kbd> moves files to the **trash** (`~/.local/share/Trash`), so they can be restored. <kbd>D</kbd> deletes
them **permanently**, like `rm`.

:::

### Tabs

Yazi can keep **several directories open**, one in each **tab**. Every tab has its own current directory, so tabs make
copying and moving between two directories easy.

| Key | Action |
|-|-|
| <kbd>t</kbd> then <kbd>t</kbd> | Open a new tab, in the current directory |
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
| `cd` says `Not a directory` | The path points to a file, not a directory |
| `rmdir` says `Directory not empty` | `rmdir` deletes only empty directories. Delete what is inside first, or use `rm -r` (carefully) |
| `cp` says `-r not specified; omitting directory` | Add `-r` to copy a directory |
| `mv` or `cp` with several files says `target ... is not a directory` | The last parameter must be an existing directory |
| A name with spaces became several files | Put the name between quotes: `touch "shopping list.txt"` |
| `invalid option` for a file whose name starts with `-` | Use a path that does not start with `-`: `./-list.txt` |
| `Permission denied` | You are trying to write outside your home directory (and `/tmp`) |
| `yazi: command not found` | Yazi is not installed, see [Installing Yazi on Fedora 44](#installing-yazi-on-fedora-44) |
| Yazi shows strange symbols instead of icons | The terminal font has no icons. Everything still works; for icons, use [Ghostty](#a-better-terminal-for-yazi-ghostty) |

## Exercises

The exercises get harder as you go:

* [First Steps](#first-steps) (exercises 1 - 34) goes once through **everything** in this lab, with easy exercises;
* [Going Further](#going-further) (exercises 35 - 53) has harder exercises;
* [Challenges](#challenges) (exercises 54 - 62) has the hardest ones.

The exercises are also marked for the two types of lab:

* 🌱 **basic** (1 hour - **AC**): do only the exercises marked with 🌱 (exercises 1 - 34);
* 🌳 **full** (2 hours - **CD**): do all the exercises, both 🌱 and 🌳.

Do the exercises **in order**: each one uses the files left by the previous ones.

Some exercises ask for things that the lab does not show you, for example an option that is not in the tables
above. Find it in the **manual page** of the command (`man <command>`), as explained in
[Searching in a Manual Page](#searching-in-a-manual-page): search for words that describe what you need.

Keep **two terminals side by side** in Sway: one to run the commands, and one where you check the result with
`tree ~/lab02`, `ls` or `pwd` after **every** exercise. In the paths below, replace `student` with your user name
(run `whoami` to find it).

:::tip

If a command prints `No such file or directory`, the path is wrong: fix it and run the command again.

:::

:::danger

Some exercises use real files of the operating system, outside your home directory. You can **read** most of them,
but you cannot change them: they belong to the administrator (`root`). Never use `sudo` in these exercises. Without
it, you cannot break anything; with it, a typing mistake in `/etc` can stop the computer from starting.

:::

### First Steps

1. 🌱 **The practice tree**:
   1. Run these commands to create the directories and files used in the exercises (copy them from the browser with
      <kbd>Ctrl</kbd>+<kbd>C</kbd> and paste them in the terminal with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>):

      ```bash
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
2. 🌱 **Where am I**: Go to the `Games` directory using an **absolute** path, then into `puzzles` using a **relative**
   path, then back to `~/lab02` with a **single** `cd` that uses only `..`. Print the current directory after every
   step.

   **Check:** you end up in `/home/student/lab02`. <small>→ [The Current Directory](#the-current-directory) · [Absolute Paths](#absolute-paths)</small>
3. 🌱 **Absolute paths**: From your home directory, show the details of `cat.jpg`, of `sudoku.txt` and of the `Recipes`
   directory **itself** (not what is inside it) with a **single** `ls` command and **absolute** paths. Look in `man ls`
   for the option that lists a directory itself (🔍 search for `contents`).

   **Check:** you get exactly three lines, and the one of `Recipes` starts with `d`. <small>→ [Absolute Paths](#absolute-paths) · [Reading the Manual](#reading-the-manual)</small>
4. 🌱 **Relative paths**: Do the same from `~/lab02`, this time with **relative** paths. Then, from `~/lab02/Games`,
   list the contents of `Photos` and of `Recipes` with a **single** `ls` and relative paths.

   **Check:** the last command shows the two pictures and an empty `Recipes`. <small>→ [Relative Paths](#relative-paths)</small>
5. 🌱 **Going up and down**: From `~/lab02/Games/2026/puzzles`, show the details of `books.txt` and of `dog.jpg` with a
   **single** `ls` and relative paths. Then go to `Photos` with a **single** `cd`, and from there back to `puzzles`
   with another **single** `cd`, both with relative paths.

   **Check:** you end up in `/home/student/lab02/Games/2026/puzzles`. <small>→ [`.` and `..`](#-and-)</small>
6. 🌱 **Same file, many paths**: From `~/lab02/Games/2026`, show the details of `books.txt` with **five** different
   paths: an absolute one, one with `~`, a relative one with only `..`, a relative one that goes through `Photos`,
   and a relative one that goes through **both** `Photos` and `Recipes`.

   **Check:** all five commands print the same line. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
7. 🌱 **Walk around**: From your home directory, go to `~/lab02/Games/2026/puzzles` with a **single** `cd` and an
   absolute path, then to `~/lab02/Recipes` with a **single** `cd` and a relative path. Go back to `puzzles` with
   `cd -`, then home with the shortest command you can.

   **Check:** `cd -` prints `/home/student/lab02/Games/2026/puzzles`, and you end up in `/home/student`. <small>→ [Navigation](#navigation)</small>
8. 🌱 **Back and forth**: Go to `/etc`, then to `~/lab02/Recipes`. Using only `cd -`, jump back and forth between
   them twice. Then, from `Recipes`, list `/etc`; jump to `/etc` with `cd -` and, from there, list `Recipes` with a
   relative path.

   **Check:** each `cd -` prints the directory it went to, and the last `pwd` prints `/etc`. <small>→ [The Previous Directory: `cd -`](#the-previous-directory-cd--)</small>
9. 🌱 **Listing**: With a **single** `ls` command, list `~/lab02` so that you see the hidden file, can tell the files
   from the directories, and read the sizes in `K` / `M` (look in `man ls`, 🔍 search for `sizes`
   and read every match).

   **Check:** you found `.secret`, and three directories. <small>→ [Navigation](#navigation) · [Reading the Manual](#reading-the-manual)</small>
10. 🌱 **ls with a directory**: From your home directory, list `~/lab02/Photos`, `~/lab02/Games/2026/puzzles` and `/` with a
    **single** `ls`, **without** changing the current directory.

    **Check:** the output has three parts, one for each directory, and `pwd` still prints your home directory. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
11. 🌱 **First look with tree**: Show the tree of `~/lab02` only **one** level deep, then the whole tree with a `/`
    after the name of every directory (look in `man tree`, 🔍 search for `Append`).

    **Check:** the first command shows `Games`, `Photos` and `Recipes`, but not `chess.txt`; in the second one, every
    directory ends with `/`. <small>→ [Navigation](#navigation) · [Reading the Manual](#reading-the-manual)</small>
12. 🌱 **Type less**: Press <kbd>Tab</kbd> after typing **at most three letters** of every name:
    * go to `/usr/share/doc`;
    * from there, show the details of `~/lab02/Games/2026/puzzles/sudoku.txt`;
    * find out which names in `/etc` start with `pass`, without running any command.

    **Check:** `pwd` prints `/usr/share/doc`, `ls -l` shows `sudoku.txt`, and <kbd>Tab</kbd> <kbd>Tab</kbd> shows
    `passwd` and `passwd-`. <small>→ [TAB Completion](#tab-completion)</small>
13. 🌱 **Find by name**: Find `sudoku.txt` twice: once searching from `~/lab02` with a relative start, once from your
    home directory with an absolute start.

    **Check:** the first command prints `./Games/2026/puzzles/sudoku.txt` and the second one
    `/home/student/lab02/Games/2026/puzzles/sudoku.txt`. <small>→ [Finding Files](#finding-files-find)</small>
14. 🌱 **Find by extension**: With a **single** `find`, find all the pictures (`.jpg`) in `~/lab02`. Then all the
    `.txt` files.

    **Check:** you get `cat.jpg` and `dog.jpg`, then `books.txt`, `chess.txt` and `sudoku.txt`. <small>→ [Finding Files](#finding-files-find)</small>
15. 🌱 **Files or directories**: Find only the directories in `~/lab02`, then only the files.

    **Check:** the directories are `.`, `Games`, `2026`, `puzzles`, `Photos` and `Recipes`; the files include the hidden
    `.secret`. <small>→ [Finding Files](#finding-files-find)</small>
16. 🌱 **Use what you found**: From `~/lab02/Recipes`, find `chess.txt` searching from `..`, then copy it into `/tmp`
    using the path that `find` printed.

    **Check:** `ls /tmp` shows `chess.txt`. <small>→ [Finding Files](#finding-files-find) · [Every File is a Path](#every-file-is-a-path)</small>
17. 🌱 **Which Linux**: Print the content of `/etc/os-release` with `cat`, with the **number** of every line in front of it
    (look in `man cat`, 🔍 search for `number`). Then open it in `nano` in view mode and search for `VERSION` with <kbd>Ctrl</kbd>+<kbd>W</kbd>.

    **Check:** the lines `NAME=` and `VERSION_ID=` show `Fedora` and `44`, and every line starts with its number. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano) · [Reading the Manual](#reading-the-manual)</small>
18. 🌱 **The identity of the computer**: Print the content of `/etc/machine-id`, the number that identifies this
    installation of Linux. Then run `hostnamectl`, which prints information about the computer.

    **Check:** the `Machine ID` line of `hostnamectl` shows the same number as the file. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
19. 🌱 **The users**: Print `/etc/passwd`, the list of the users of the system, and find the line of your user (it
    starts with your user name; on some lab computers the accounts come from a central server, then look for the
    line of `root`). Copy the file to `/tmp/users.txt` and change the copy with `nano`.

    **Check:** `ls -l /etc/passwd /tmp/users.txt` shows that only the copy was changed (look at the dates). <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano) · [Managing Files](#managing-files)</small>
20. 🌱 **The shells**: Print `/etc/shells`, the list of the shells installed. Then show the details of
    `/usr/bin/bash`, the shell that runs in your terminal.

    **Check:** `/usr/bin/bash` is in the list, and `ls -l` shows a file (first letter `-`) of about 1 MB. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano) · [Every File is a Path](#every-file-is-a-path)</small>
21. 🌱 **Programs are files**: Show the details of the `ls` program itself, `/usr/bin/ls`. Then find every program in
    `/usr/bin` whose name starts with `mk`.

    **Check:** `mkdir` is one of them. <small>→ [Finding Files](#finding-files-find)</small>
22. 🌱 **What is this file**: With a **single** `file` command, find out the type of `/etc/hosts`, `/usr/bin/ls`,
    `/boot` and `~/lab02/Photos/cat.jpg`.

    **Check:** `/etc/hosts` is text, `/usr/bin/ls` is an `ELF` executable, `/boot` is a directory, and `cat.jpg` is
    `empty`, even if its name ends with `.jpg`. <small>→ [What Kind of File](#what-kind-of-file-file)</small>
23. 🌱 **Create files**: Create an **empty** file `groceries.txt` and a file `plan.txt` with two lines of text in it.
    Then create `soup.txt`, `pizza.txt` and `cake.txt` in `Recipes` with a **single** command, without going into
    `Recipes`.

    **Check:** `ls -l` shows size `0` for `groceries.txt`, but not for `plan.txt`; `Recipes` has the three new files. <small>→ [Managing Files](#managing-files)</small>
24. 🌱 **Create directories**: Create `Albums/2024/summer` and `Albums/2025/winter` with a **single** command.

    **Check:** `tree` shows both directories. <small>→ [Managing Files](#managing-files)</small>
25. 🌱 **Copy files**: Copy `books.txt` into `Albums`. Copy `cat.jpg` and `dog.jpg` from `Photos` into `Games` with a
    **single** command, and make `cp` print the name of every file it copies (look in
    `man cp`, 🔍 search for `explain`). Copy `dog.jpg` into `Albums/2025/winter` under the name `snow_dog.jpg`.

    **Check:** `cp` printed a line like `'Photos/cat.jpg' -> 'Games/cat.jpg'` for each picture; the two pictures are both
    in `Photos` and in `Games`, and `snow_dog.jpg` is in `winter`. <small>→ [Managing Files](#managing-files) · [Reading the Manual](#reading-the-manual)</small>
26. 🌱 **Copy a directory**: Copy the whole `Games` directory to `/tmp/Games_backup`. Then run **exactly the same** command a
    second time, and find out where the second copy went. Delete **only** the second copy.

    **Check:** `tree /tmp/Games_backup` shows the same files as `tree ~/lab02/Games`, and nothing more. <small>→ [Managing Files](#managing-files)</small>
27. 🌱 **Rename and move**: Rename `groceries.txt` to `shopping.txt` and move it into `Recipes` with a **single** `mv`.
    Move `plan.txt` and `books.txt` into `Albums` with a **single** command.

    **Check:** `Recipes` has `shopping.txt`; `Albums` has `books.txt` and `plan.txt`; no `.txt` file is left directly
    in `~/lab02`. <small>→ [Managing Files](#managing-files)</small>
28. 🌱 **Delete**: Delete `/tmp/Games_backup/chess.txt`. Move `sudoku.txt` from `puzzles` up into `Games/2026`, then
    delete the empty `puzzles` directory. Then delete `Albums/2024` and
    everything in `Albums/2025` using **only** `rmdir` and `rm` (no `-r`). Make `rm` **ask you** before it deletes every
    file (look in `man rm`, 🔍 search for `prompt`).

    **Check:** `rm` asked `remove regular empty file ...?` before every file; `Albums` has only `books.txt` and
    `plan.txt`, and `Games/2026` has only `sudoku.txt`. <small>→ [Managing Files](#managing-files) · [Reading the Manual](#reading-the-manual)</small>
29. 🌱 **Spaces in names**: In `~/lab02/Recipes`, create the directory `Shopping Lists` and, inside it, the files
    `week 1.txt` and `week 2.txt` with a **single** command. Copy `week 1.txt` to `/tmp`, and rename `week 2.txt` to
    `last week.txt`. At the end, delete the whole `Shopping Lists` directory.

    **Check:** `ls /tmp` shows `'week 1.txt'`; before the last step `Shopping Lists` has `week 1.txt` and
    `last week.txt`, and after it `Recipes` no longer has `Shopping Lists`. <small>→ [Names with Spaces and Special Characters](#names-with-spaces-and-special-characters)</small>
30. 🌱 **Install Yazi**: Install Yazi.

    **Check:** `yazi --version` prints a version number. <small>→ [Installing Yazi on Fedora 44](#installing-yazi-on-fedora-44)</small>
31. 🌱 **Look around**: Open `~/lab02` in Yazi. Walk down into `Albums` and back up to `~/lab02`, first with the arrow
    keys, then without them. Make the hidden file appear, then hide it again.

    **Check:** `.secret` appears and disappears. <small>→ [Using Yazi](#using-yazi)</small>
32. 🌱 **Create and rename**: With Yazi only, in `~/lab02`, create a file `menu.txt` and an empty directory `Drafts`. Rename `menu.txt` to
    `dinner.txt`, and rename `soup.txt` in `Recipes` to `tomato_soup.txt`.

    **Check:** `tree` shows `dinner.txt`, `Drafts` and `Recipes/tomato_soup.txt`. <small>→ [Using Yazi](#using-yazi)</small>
33. 🌱 **Copy and move**: With Yazi only, copy `dinner.txt` into `Recipes`. Move `dog.jpg` from `Photos` into `Drafts`.

    **Check:** `dinner.txt` is both in `~/lab02` and in `Recipes`; `dog.jpg` is in `Drafts` and no longer in
    `Photos`. <small>→ [Using Yazi](#using-yazi)</small>
34. 🌱 **Tabs**: With Yazi only, open `Albums`, `Recipes` and `Drafts` in three different tabs. Without leaving any of the three
    directories:
    * copy `plan.txt` into `Recipes`;
    * move `shopping.txt` into `Albums`.

    **Check:** `plan.txt` is both in `Albums` and in `Recipes`; `shopping.txt` is in `Albums` and no longer in `Recipes`. <small>→ [Tabs](#tabs)</small>

### Going Further

35. 🌳 **Calculate**: Go to `~/lab02/Games`. Create the file `~/lab02/answers.txt` with `nano`, **without leaving**
    `Games`. In it, write the absolute path of each of these relative paths:
    * `../Photos/cat.jpg`
    * `./2026/../chess.txt`
    * `../../lab02/Recipes/.`
    * `2026/../../Albums/books.txt`
    * `../Games/2026/../../Photos/./cat.jpg`
    * `../../../../..`

    **Check:** `realpath` prints the same absolute paths as the ones you wrote. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
36. 🌳 **Above the root**: Go to `/` and try to go even higher. Find out, with `realpath` and `ls`, where `/../../..`
    leads. From `/`, reach `~/lab02` with a relative path that starts with `../..`.

    **Check:** `pwd` prints `/` no matter how many times you try to go up, and the last `cd` works. <small>→ [`.` and `..`](#-and-)</small>
37. 🌳 **Home from anywhere**: List `~/lab02` from `/usr/bin`, from `/tmp` and from `/usr/share/doc`, each time with a
    **relative** path. Write in `answers.txt` how many `..` you needed each time. Then let `realpath` calculate, for
    each of the three directories, the relative path from it to `~/lab02` (look in `man realpath`, 🔍 search for
    `relative`).

    **Check:** the three commands print the same files, and `realpath` prints the same relative paths as yours. <small>→ [The Home Directory: `~`](#the-home-directory-) · [Reading the Manual](#reading-the-manual)</small>
38. 🌳 **Fix the path**: Each of these commands fails. Find out why and fix it:
    * `ls ~/lab02/games/2026`
    * `cd ~/lab02/Games/chess.txt`
    * `ls ~/lab2`
    * `ls ~/lab02/Photos/cat.jpg/`
    * `cd ../lab02/Games` (run it from `~/lab02/Photos`)

    **Check:** the commands print no error. <small>→ [Troubleshooting](#troubleshooting)</small>
39. 🌳 **More tree**: Show the tree of `~/lab02` (look in `man tree` for the options):
    * only the directories, but also the hidden ones (🔍 search for `only` and for `hidden`);
    * with the hidden files, two levels deep;
    * with the size of every file, in `K` / `M`, and the directories listed **before** the files (🔍 search for
      `human` and for `before`).

    Then show only the directories of `/usr`, two levels deep.

    **Check:** only the second command shows `.secret`; in the third one, every name has its size in brackets, like `[4.0K]`, in
    front of it, and in every directory the subdirectories come first. <small>→ [Navigation](#navigation) · [Reading the Manual](#reading-the-manual)</small>
40. 🌳 **Not too deep**: Find the `.txt` files of `~/lab02` that are at most **two** levels deep (look in `man find`,
    🔍 search for `levels`). Then find all the **empty** files in `~/lab02` (🔍 search for `empty`).

    **Check:** `chess.txt` and the files in `Albums` and `Recipes` appear, but not `sudoku.txt`; the empty files
    include `chess.txt` and `cat.jpg`, but not `plan.txt`. <small>→ [Finding Files](#finding-files-find) · [Reading the Manual](#reading-the-manual)</small>
41. 🌳 **Somewhere in the system**: Find the file called `hosts` in `/etc`, and every file whose name starts with
    `passwd` in `/etc`. Ignore the `Permission denied` messages. Then find, in `/usr/share/doc`, the files called
    `readme`, written with **any** upper or lower case letters: `README`, `Readme`, ... (look in `man find`, 🔍 search
    for `insensitive`).

    **Check:** the results include `/etc/hosts` and `/etc/passwd`, and the last command finds many files called
    `README`. <small>→ [Finding Files](#finding-files-find) · [Reading the Manual](#reading-the-manual)</small>
42. 🌳 **Settings of the package manager**: Find, somewhere in `/etc`, the file called `dnf.conf` (the settings of
    `dnf`, the program that installs packages). Print it using the path that `find` printed.

    **Check:** the file is `/etc/dnf/dnf.conf`, and it has a line `[main]`. <small>→ [Finding Files](#finding-files-find) · [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
43. 🌳 **Names of computers**: Print `/etc/hosts`, the file that gives names to network addresses, and find the
    line with `localhost`. Then open it with `nano -v` and search for `localhost` with <kbd>Ctrl</kbd>+<kbd>W</kbd>.

    **Check:** the line starts with `127.0.0.1`, the address of your own computer. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
44. 🌳 **The kernel**: Find the files of the kernel in `/boot` (their names start with `vmlinuz`), then show their
    details with the sizes in `M` (look in `man ls`, 🔍 search for `sizes`).

    **Check:** you find at least one `vmlinuz-...` file, of a few MB. <small>→ [Finding Files](#finding-files-find) · [Navigation](#navigation) · [Reading the Manual](#reading-the-manual)</small>
45. 🌳 **Logs**: List the details of `/var/log`, the directory where the system keeps its logs, with the files changed
    most **recently** at the top (look in `man ls`, 🔍 search for `newest`). Try to print some of the text files there (check them with
    `file` first): find one that you are allowed to read, and one that you are not.

    **Check:** the dates go from the newest to the oldest, and for one of the files you get `Permission denied`. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano) · [Reading the Manual](#reading-the-manual)</small>
46. 🌳 **Look, do not touch**: Try to create `/etc/test.txt`, to save `/etc/hosts` from `nano` after adding a letter
    (exit **without** saving after the error), and to delete `/etc/hosts` (if `rm` asks
    `remove write-protected regular file?`, answer `y`).

    **Check:** every attempt prints `Permission denied`, and `/etc/hosts` is unchanged. <small>→ [Troubleshooting](#troubleshooting)</small>
47. 🌳 **Moving around the system**: From `/usr/share/doc`, go to `/etc` with the **shortest** relative path, then to
    `/var/log` with another relative path, and back to `/usr/share/doc` with a third one. Jump to `/var/log` with
    `cd -`.

    **Check:** after each `cd`, `pwd` prints the directory you wanted to reach. <small>→ [Relative Paths](#relative-paths) · [The Previous Directory: `cd -`](#the-previous-directory-cd--)</small>
48. 🌳 **The extension lies**: Copy `/usr/bin/ls` to `/tmp/song.mp3` and `/etc/hosts` to `/tmp/program`, and find out
    what they really are. Then run `/tmp/song.mp3 ~/lab02`. Delete both copies at the end.

    **Check:** `song.mp3` is an `ELF` executable and `program` is text; `/tmp/song.mp3 ~/lab02` lists `~/lab02`, exactly
    like `ls ~/lab02`. <small>→ [What Kind of File](#what-kind-of-file-file)</small>
49. 🌳 **Paths everywhere**: From `~/lab02/Games/2026`, without changing the current directory, copy `cat.jpg` from
    `Photos` into `Recipes` using **only relative** paths. Delete the copy, then copy it again using **only
    absolute** paths.

    **Check:** `Recipes` has `cat.jpg`. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
50. 🌳 **Delete a directory**: Delete `/tmp/Games_backup` with everything inside it with a **single** command, and make
    `rm` print everything it deletes (look in `man rm`, 🔍 search for `explain`).

    **Check:** the last line printed by `rm` is `removed directory '/tmp/Games_backup'`, and `ls /tmp` no longer
    shows it. <small>→ [Managing Files](#managing-files) · [Reading the Manual](#reading-the-manual)</small>
51. 🌳 **Strange names**: In `/tmp`, create the files `rock & roll.txt`, `price $5.txt`, `it's here.txt` and
    `-help.txt`. Check the names with `ls -l`, then delete the four files, with one `rm` for each of them.

    **Check:** `ls -l /tmp` shows the four names exactly as above, and none of them at the end. <small>→ [Names with Spaces and Special Characters](#names-with-spaces-and-special-characters)</small>
52. 🌳 **Several files**: With Yazi only, copy both pictures from `Games` into `Albums` with a **single** paste. Then move
    `tomato_soup.txt`, `pizza.txt` and `cake.txt` from `Recipes` into `Drafts` with a **single** paste, and move
    `pizza.txt` and `cake.txt` back into `Recipes` with another **single** paste.

    **Check:** `Albums` has `cat.jpg` and `dog.jpg`; `Drafts` has `dog.jpg` and `tomato_soup.txt`; `Recipes` has
    `pizza.txt` and `cake.txt`. <small>→ [Using Yazi](#using-yazi)</small>
53. 🌳 **Trash or delete**: With Yazi only, send `dinner.txt` (the one in `~/lab02`) to the trash, and delete `Drafts` permanently. Then,
    from the terminal, find `dinner.txt` in the trash and move it back to `~/lab02`.

    **Check:** `dinner.txt` is back in `~/lab02`, and `Drafts` is gone. <small>→ [Using Yazi](#using-yazi)</small>

### Challenges

54. 🌳 **Tricky paths**: From `~/lab02/Photos`, calculate where `../Games/2026/./../../Photos/../Recipes` leads, and write
    each step of the calculation in `answers.txt`. Go there with a **single** `cd`. Then go back to `Photos` with a
    path that contains **exactly two** `..`.

    **Check:** you are back in `/home/student/lab02/Photos`. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
55. 🌳 **Reorganize**: Using the terminal for half of the work and Yazi for the other half, change `~/lab02` so that
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

:::info
Exercises 56 - 62 start from the tree of exercise 55: do them only after `tree ~/lab02` shows
exactly that tree.
:::

56. 🌳 **Exactly five**: From `~/lab02/Recipes/desserts`, write a relative path to `sudoku.txt` that contains
    **exactly five** `..` and no `.`. Use it with `ls -l`.

    **Check:** `ls -l` shows `sudoku.txt`, and `realpath` of your path prints `/home/student/lab02/Games/2026/sudoku.txt`. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
57. 🌳 **Shortest path**: Find the **shortest** relative path from `/usr/share/doc` to `~/lab02/Notes`, and the
    shortest one from `~/lab02/Notes` back to `/usr/share/doc`. Use each of them with a single `cd`, then jump
    between the two directories twice more with `cd -` only.

    **Check:** after each `cd`, `pwd` prints the directory you wanted to reach. <small>→ [Relative Paths](#relative-paths)</small>
58. 🌳 **Clean up a path**: Write the **shortest** absolute path equivalent to
    `/home/../../../home/student/lab02/./Notes/../Games/2026/../../Recipes/desserts/..`, first on paper, then check it.

    **Check:** `realpath` prints the path you wrote. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
59. 🌳 **Swap**: Swap the names of `Notes/books.txt` and `Notes/plan.txt` using **only** `mv`.

    **Check:** `ls -l ~/lab02/Notes` shows that `books.txt` now has the size that `plan.txt` had before, and
    `plan.txt` is empty. <small>→ [Managing Files](#managing-files)</small>
60. 🌳 **Mirror**: Create in `/tmp/mirror` the same **directory** structure as `~/lab02` (only the directories, no files),
    with a **single** `mkdir` command that prints every directory it creates (look in `man mkdir`, 🔍 search
    for `message`).

    **Check:** `mkdir` printed a `created directory` line for every directory, and the trees of `/tmp/mirror`
    and `~/lab02` have the same directories. <small>→ [Managing Files](#managing-files) · [Reading the Manual](#reading-the-manual)</small>
61. 🌳 **From far away**: Go to `/tmp`. With a **single** `mv` command and **only relative** paths, move `chess.txt`
    and `cat.jpg` from `Games` into `Recipes/desserts`. Then move them back with a single `mv`, this time from
    `~/lab02/Notes`.

    **Check:** after the first `mv`, `desserts` has three files; after the second one, `tree ~/lab02` shows the
    tree of exercise 55 again (with the names of exercise 59). <small>→ [Every File is a Path](#every-file-is-a-path)</small>
62. 🌳 **Backup with tabs**: With Yazi only, create the directory `~/lab02/Backup`, then copy the `Games`, `Notes` and
    `Recipes` directories into it using **two** tabs and a **single** paste. Delete `Backup` permanently at the end.

    **Check:** before deleting it, `tree ~/lab02/Backup` shows the three directories with all their files. <small>→ [Tabs](#tabs) · [Using Yazi](#using-yazi)</small>

## Wrap-up Questions

Use the **last 5 minutes** of the lab to answer these questions together with your colleagues and the teaching
assistant. There are no wrong answers for the last two.

1. What is the difference between an **absolute** and a **relative** path? How can you tell them apart at a glance?
2. What do `.`, `..` and `~` mean?
3. Why does a relative path stop working when you change the current directory?
4. How does the operating system turn a relative path into an absolute one?
5. What does `[ ]` and `...` mean in the `SYNOPSIS` of a manual page?
6. Why must the last parameter of `cp a b c` be a directory?
7. What is the difference between `rm` in the terminal and <kbd>d</kbd> in Yazi?
8. When would you use the terminal, and when Yazi?
9. What was the hardest path to calculate today?

## Extra

1. **Hidden files**: Run `ls -a ~`. Most of the hidden files and directories are settings of your programs. Find the
   directory where Yazi keeps the trash. <small>→ [Using Yazi](#using-yazi)</small>
2. **The whole tree**: Run `tree -L 1 /` and compare it with the tree in [The File System Tree](#the-file-system-tree).
   Find in `/etc` the file that says which Linux this is, and print it (hint: its name ends with `release`). <small>→ [The File System Tree](#the-file-system-tree)</small>
3. **Yazi help**: Press <kbd>F1</kbd> in Yazi and find the key that filters the files in the current directory by name.
   <small>→ [Using Yazi](#using-yazi)</small>
4. **Ghostty**: Install Ghostty, open `~/lab02/Photos` with Yazi inside it and compare it with Yazi in `foot`. Then
   make Ghostty the terminal that opens with <kbd>$mod</kbd> + <kbd>Enter</kbd>. <small>→ [A Better Terminal for Yazi: Ghostty](#a-better-terminal-for-yazi-ghostty)</small>
