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
- Find files anywhere in a folder tree with `find`
- Read text files with `cat` and `nano`
- Create, copy, move, rename and delete files and folders with `mkdir`, `touch`, `nano`, `cp`, `mv`, `rm` and `rmdir`
- Install and use **Yazi** to manage files with a few keys, including tabs

## Resources

1. *[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor
de Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)*
   - Chapter 2 - *Utilizarea sistemului de fișiere*, sections 2.1.2, 2.1.3, 2.3.1, 2.3.2, 2.3.4 and 2.3.5
2. *Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021*
   - Chapter 2 - *Basic Commands and Directory Hierarchy*, sections 2.3, 2.4, 2.5.3, 2.5.6, 2.12, 2.13 and 2.19
3. *[Yazi - Quick Start](https://yazi-rs.github.io/docs/quick-start)*
4. *[Yazi - Installation](https://yazi-rs.github.io/docs/installation)*
5. The lecture slides: [02. Files Management](/docs/lectures/02)
6. The manual pages: `man ls`, `man cp`, `man mv`, `man rm`, `man mkdir`, `man tree`, `man find`

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

```shell-session
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

```shell-session
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
| `cat <file>` | Prints the content of a file |
| `cd <directory>` | Changes the current directory |
| `cd` or `cd ~` | Goes to your home folder |
| `cd -` | Goes to the previous directory (where you were before the last `cd`) |
| `ls` | Lists the current directory |
| `ls <directory>` | Lists another directory |
| `ls -a` | Also lists the hidden files (names that start with `.`) |
| `ls -l` | Long listing: type, permissions, owner, size, date |
| `ls -lh` | Long listing with human readable sizes (`4.0K`, `21M`) |
| `tree` | Lists a folder and **everything inside it** |
| `tree -L 1` | Only one level deep |
| `tree -d` | Only the folders |

In the output of `ls -l`, the first letter is the **type**: `d` for a directory, `-` for a regular file.

```shell-session
$ ls -l
drwxr-xr-x  2 student student  4096 Sep 20 18:02 Downloads
drwxr-xr-x  2 student student  4096 Sep 26 21:15 Movies
-rw-r--r--  1 student student 21504 Sep 28 21:40 watchlist.txt
```

`tree` is not always installed. On Fedora install it with `sudo dnf install tree`, on Ubuntu with
`sudo apt install tree`.

### Examples

The examples use this home folder. The prompt shows the name of the current directory (`~` is your home):

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

`pwd` printed the absolute path of the current directory: first the home folder, then, after `cd Movies`, the
`Movies` folder inside it. The prompt shows only the last part of it (`~`, then `Movies`).

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
* `cd` alone went back to the home folder.

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

For example, with three folders:

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

Do not confuse `cd -` with `cd ..`, either:

| Command | Goes to | Pressed twice |
|---------|---------|---------------|
| `cd -` | the directory you were in before the last `cd` | you are back where you started |
| `cd ..` | the parent of the current directory, one level up the tree | you are two levels up |
| a browser's Back | the previous page, then the one before it, and so on | the shell has no such command |

:::tip

`cd -` is very useful when you work in two folders at the same time, for example to copy files from one to the other.

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
drwxr-xr-x  2 student student  4096 Sep 20 18:02 Downloads
drwxr-xr-x  2 student student  4096 Sep 26 21:15 Movies
-rw-r--r--  1 student student 21504 Sep 28 21:40 watchlist.txt
[student@fedora ~]$ ls -lh watchlist.txt
-rw-r--r--  1 student student 21K Sep 28 21:40 watchlist.txt
```

* `ls` listed the current directory. It does **not** show what is inside `Movies`.
* `ls Movies` listed the `Movies` folder, without changing the current directory.
* `ls -a` also listed the hidden entries: `.bashrc`, and `.` and `..`, which are in every folder.
* `ls -l` listed one entry per line: the type (`d` folder, `-` file), the permissions, the owner, the size in
  bytes, the date and the name.
* `ls -lh watchlist.txt` showed the details of only one file, with the size as `21K` instead of `21504`.

#### `tree`

```shell-session
[student@fedora ~]$ tree
.
├── Downloads
│   └── supergirl.mp4
├── Movies
│   └── the_odyssey.mkv
└── watchlist.txt

2 directories, 3 files
[student@fedora ~]$ tree -L 1
.
├── Downloads
├── Movies
└── watchlist.txt

2 directories, 1 file
[student@fedora ~]$ tree -d Movies
Movies

0 directories
```

* `tree` showed the current directory and **everything inside it**, and counted the folders and files.
* `tree -L 1` stopped after the first level, like `ls`.
* `tree -d Movies` showed only the folders inside `Movies`, and there are none.

## Finding Files: `find`

`ls` and `tree` show you what is in a folder. When you know the **name** of a file but not **where** it is, use
`find`. It walks through a folder and through everything inside it, and prints the path of every entry that
matches what you ask for.

```
find [folder...] [tests]
```

| Command | What it does |
|-|-|
| `find` | Prints every file and folder below the current directory |
| `find <folder>` | Prints every file and folder below `<folder>` |
| `find <folder> -name '<name>'` | Only the entries called `<name>` |
| `find <folder> -name '*.txt'` | Only the entries whose name ends with `.txt` (`*` means "any characters") |
| `find <folder> -iname '<name>'` | Like `-name`, but upper and lower case letters are the same |
| `find <folder> -type f` | Only the files |
| `find <folder> -type d` | Only the folders |
| `find <folder> -maxdepth 1` | Only one level deep, like `ls` |

The tests can be combined: `find ~ -type f -name '*.txt'` finds only the **files** whose name ends with `.txt`.

:::caution

Always put the name after `-name` between quotes (`'*.txt'`). Without quotes, the shell might replace `*.txt` with
the names of the files in the current directory before `find` even starts.

:::

### Examples

Using the same home folder as in the [Navigation examples](#examples):

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
[student@fedora Movies]$ find .. -maxdepth 1 -type d
..
../Downloads
../Movies
```

* `find Movies` printed the folder itself and everything inside it.
* `find . -name '*.mp4'` searched the current directory (`.`) and everything below it, and found one file.
* `find ~ -name '*.mp4'` found the same file, but printed an **absolute** path: `find` builds every path from the
  folder you give it. A relative start gives relative paths, an absolute start gives absolute paths.
* From `Movies`, `find .. -name watchlist.txt` searched the parent folder and printed `../watchlist.txt`, a relative
  path that works from `Movies`.
* `find .. -maxdepth 1 -type d` printed only the folders of the first level of `..`, including `..` itself.

:::tip

`find` also finds the **hidden** files, without any option. The order of the results might be different on your
computer.

:::

:::info

When `find` searches a folder that you are not allowed to read (for example in `/etc`), it prints
`Permission denied` for it and continues. You can ignore these messages.

:::

## Viewing Text Files: `cat` and `nano`

Most files in Linux, especially the settings in `/etc`, are **text files**: you can read them. There are two easy
ways to look inside a text file: `cat` and `nano`.

### `cat`

`cat` prints the whole content of one or more files in the terminal, and then the prompt comes back:

```shell-session
[student@fedora ~]$ cat /etc/hostname
fedora
[student@fedora ~]$ cat watchlist.txt
The Odyssey
Project Hail Mary
[student@fedora ~]$ cat /etc/hostname watchlist.txt
fedora
The Odyssey
Project Hail Mary
[student@fedora ~]$ cat notes.txt
[student@fedora ~]$
```

* `cat /etc/hostname` printed the content of the file: the name of the computer, on a single line.
* `cat watchlist.txt` printed a file from the current directory, using a relative path.
* With several files, `cat` printed them one after another, with nothing in between.
* `notes.txt` is empty, so `cat` printed nothing at all.

`cat` is perfect for **short** files. For a long file, the beginning scrolls off the screen: scroll back with
<kbd>Shift</kbd>+<kbd>Page Up</kbd>, or open the file with `nano` instead.

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
| `nano` (or `nano -v`) | The file is long, you want to scroll or search in it, or you want to change it |

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

### Examples

The examples continue one after another, starting from the same home folder as in [Navigation](#navigation).

#### `mkdir`

```shell-session
[student@fedora ~]$ mkdir Series
[student@fedora ~]$ mkdir Series
mkdir: cannot create directory 'Series': File exists
[student@fedora ~]$ mkdir Series/2025/comedy
mkdir: cannot create directory 'Series/2025/comedy': No such file or directory
[student@fedora ~]$ mkdir -p Series/2025/comedy
```

* The first `mkdir Series` created the empty folder `/home/student/Series`.
* The second one failed: the folder already exists.
* `mkdir Series/2025/comedy` failed, because `Series/2025` does not exist yet, and `mkdir` creates only the last
  folder of the path.
* `mkdir -p` created `2025` and then `comedy` inside it. With `-p`, it is not an error if a folder already exists.

#### `touch`

```shell-session
[student@fedora ~]$ touch notes.txt
[student@fedora ~]$ ls -l notes.txt
-rw-r--r--  1 student student 0 Oct  1 10:15 notes.txt
[student@fedora ~]$ touch watchlist.txt
[student@fedora ~]$ ls -l watchlist.txt
-rw-r--r--  1 student student 21504 Oct  1 10:16 watchlist.txt
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

* `cp watchlist.txt Series/` copied the file into the `Series` folder, with the same name: `Series/watchlist.txt`.
* `cp watchlist.txt backup.txt` made a copy with **another name**, in the same folder.
* With **several** sources, `cp` copied all of them into the last parameter, the folder `Series`.
* `cp Movies Movies_backup` refused to copy a folder.
* `cp -r` copied the folder and everything inside it: `Movies_backup/the_odyssey.mkv`.

:::caution

If the destination folder **already exists**, `cp -r Movies Movies_backup` copies `Movies` **inside** it, as
`Movies_backup/Movies`. Run the same command twice and look at the result with `tree`.

:::

#### `mv`

```shell-session
[student@fedora ~]$ mv backup.txt old_watchlist.txt
[student@fedora ~]$ mv old_watchlist.txt Series/
[student@fedora ~]$ mv notes.txt Series/notes_2025.txt
[student@fedora ~]$ mv Series/watchlist.txt Series/supergirl.mp4 Downloads/
```

* `mv backup.txt old_watchlist.txt` **renamed** the file: same folder, new name.
* `mv old_watchlist.txt Series/` **moved** the file into `Series`, with the same name.
* `mv notes.txt Series/notes_2025.txt` moved the file and renamed it, in a single command.
* With several sources, `mv` moved all of them into the last parameter, the folder `Downloads`. A file that already
  exists there with the same name is replaced, without any question.

#### `rmdir`

```shell-session
[student@fedora ~]$ rmdir Series/2025/comedy
[student@fedora ~]$ rmdir Series
rmdir: failed to remove 'Series': Directory not empty
```

* `rmdir Series/2025/comedy` deleted the empty folder `comedy`.
* `rmdir Series` failed: `Series` still has files and the folder `2025` inside it.

#### `rm`

```shell-session
[student@fedora ~]$ rm Series/notes_2025.txt
[student@fedora ~]$ rm Movies_backup
rm: cannot remove 'Movies_backup': Is a directory
[student@fedora ~]$ rm -r Movies_backup
```

* `rm Series/notes_2025.txt` deleted the file, **permanently**.
* `rm Movies_backup` refused to delete a folder.
* `rm -r Movies_backup` deleted the folder and everything inside it.

## Yazi

**Yazi** is a file manager that runs **in the terminal**. It shows your folders in three columns (the parent folder,
the current folder and a preview) and does the work of `cd`, `ls`, `mkdir`, `touch`, `cp`, `mv` and `rm` with a few
keys. It is fast and works well with Sway, because you never need the mouse.

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
as **[Ghostty](https://ghostty.org)**: Ghostty comes with the icons that Yazi uses for files and folders already
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

### Paths

:::tip
If a command prints `No such file or directory`, the path is wrong: fix it and run the command again.
:::

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
    absolute path, then to `~/lab02/Recipes` with a **single** `cd` and a relative path. Go back to `puzzles` with
    `cd -`, then home with the shortest command you can.

    **Check:** `cd -` prints `/home/student/lab02/Games/2026/puzzles`, and you end up in `/home/student`. <small>→ [Navigation](#navigation)</small>
13. 🌱 **Back and forth**: Go to `/etc`, then to `~/lab02/Recipes`. Using only `cd -`, jump back and forth between
    them twice. Then, from `Recipes`, list `/etc`; jump to `/etc` with `cd -` and, from there, list `Recipes` with a
    relative path.

    **Check:** each `cd -` prints the folder it went to, and the last `pwd` prints `/etc`. <small>→ [The Previous Directory: `cd -`](#the-previous-directory-cd--)</small>
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

### Finding Files

17. 🌱 **Find by name**: Find `sudoku.txt` twice: once searching from `~/lab02` with a relative start, once from your
    home folder with an absolute start.

    **Check:** the first command prints `./Games/2026/puzzles/sudoku.txt` and the second one
    `/home/student/lab02/Games/2026/puzzles/sudoku.txt`. <small>→ [Finding Files](#finding-files-find)</small>
18. 🌱 **Find by extension**: With a **single** `find`, find all the pictures (`.jpg`) in `~/lab02`. Then all the
    `.txt` files.

    **Check:** you get `cat.jpg` and `dog.jpg`, then `books.txt`, `chess.txt` and `sudoku.txt` (and `answers.txt`,
    if you created it). <small>→ [Finding Files](#finding-files-find)</small>
19. 🌱 **Files or folders**: Find only the folders in `~/lab02`, then only the files.

    **Check:** the folders are `.`, `Games`, `2026`, `puzzles`, `Photos` and `Recipes`; the files include the hidden
    `.secret`. <small>→ [Finding Files](#finding-files-find)</small>
20. 🌱 **Use what you found**: From `~/lab02/Recipes`, find `chess.txt` searching from `..`, then copy it into `/tmp`
    using the path that `find` printed.

    **Check:** `ls /tmp` shows `chess.txt`. <small>→ [Finding Files](#finding-files-find) · [Every File is a Path](#every-file-is-a-path)</small>
21. 🌳 **Not too deep**: Find the `.txt` files of `~/lab02` that are at most **two** levels deep.

    **Check:** `books.txt` and `chess.txt` appear, but not `sudoku.txt`. <small>→ [Finding Files](#finding-files-find)</small>
22. 🌳 **Somewhere in the system**: Find the file called `hostname` in `/etc`, and every file whose name starts with
    `passwd` in `/etc`. Ignore the `Permission denied` messages.

    **Check:** the results include `/etc/hostname` and `/etc/passwd`. <small>→ [Finding Files](#finding-files-find)</small>

### Exploring the System

These exercises use real files of the operating system, outside your home folder. You can **read** most of them, but
you cannot change them: they belong to the administrator (`root`).

:::danger

Never use `sudo` in these exercises. Without it, you cannot break anything; with it, a typing mistake in `/etc` can
stop the computer from starting.

:::

23. 🌱 **Which Linux**: Print the content of `/etc/os-release` with `cat`, then open it in `nano` in view mode and
    search for `VERSION` with <kbd>Ctrl</kbd>+<kbd>W</kbd>.

    **Check:** the lines `NAME=` and `VERSION_ID=` show `Fedora` and `44`. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
24. 🌱 **The name of the computer**: Print the content of `/etc/hostname`, then run the `hostname` command.

    **Check:** both print the same name. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
25. 🌱 **The users**: Print `/etc/passwd`, the list of the users of the system, and find the line of your user (it
    starts with your user name; on some lab computers the accounts come from a central server, then look for the
    line of `root`). Copy the file to `/tmp/users.txt` and change the copy with `nano`.

    **Check:** `ls -l /etc/passwd /tmp/users.txt` shows that only the copy was changed (look at the dates). <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano) · [Managing Files](#managing-files)</small>
26. 🌱 **The shells**: Print `/etc/shells`, the list of the shells installed. Then show the details of
    `/usr/bin/bash`, the shell that runs in your terminal.

    **Check:** `/usr/bin/bash` is in the list, and `ls -l` shows a file (first letter `-`) of about 1 MB. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano) · [Every File is a Path](#every-file-is-a-path)</small>
27. 🌱 **Programs are files**: Show the details of the `ls` program itself, `/usr/bin/ls`. Then find every program in
    `/usr/bin` whose name starts with `mk`.

    **Check:** `mkdir` is one of them. <small>→ [Finding Files](#finding-files-find)</small>
28. 🌳 **Settings of the package manager**: Find, somewhere in `/etc`, the file called `dnf.conf` (the settings of
    `dnf`, the program that installs packages). Print it using the path that `find` printed.

    **Check:** the file is `/etc/dnf/dnf.conf`, and its first line is `[main]`. <small>→ [Finding Files](#finding-files-find) · [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
29. 🌳 **Look, do not touch**: Try to create `/etc/test.txt`, to save `/etc/hostname` from `nano` after adding a letter
    (exit **without** saving after the error), and to delete `/etc/hostname` (if `rm` asks
    `remove write-protected regular file?`, answer `y`).

    **Check:** every attempt prints `Permission denied`, and `/etc/hostname` is unchanged. <small>→ [Troubleshooting](#troubleshooting)</small>
30. 🌳 **Names of computers**: Print `/etc/hosts`, the file that gives names to network addresses, and find the
    line with `localhost`. Then open it with `nano -v` and search for `localhost` with <kbd>Ctrl</kbd>+<kbd>W</kbd>.

    **Check:** the line starts with `127.0.0.1`, the address of your own computer. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
31. 🌳 **The kernel**: Find the files of the kernel in `/boot` (their names start with `vmlinuz`), then show their
    details with human readable sizes.

    **Check:** you find at least one `vmlinuz-...` file, of a few MB. <small>→ [Finding Files](#finding-files-find) · [Navigation](#navigation)</small>
32. 🌳 **Logs**: List `/var/log`, the folder where the system keeps its logs, and try to print one of the files there.
    Find one that you are allowed to read, and one that you are not.

    **Check:** for one of them you get `Permission denied`. <small>→ [Viewing Text Files](#viewing-text-files-cat-and-nano)</small>
33. 🌳 **Moving around the system**: From `/usr/share/doc`, go to `/etc` with the **shortest** relative path, then to
    `/var/log` with another relative path, and back to `/usr/share/doc` with a third one. Jump to `/var/log` with
    `cd -`.

    **Check:** after each `cd`, `pwd` prints the folder you wanted to reach. <small>→ [Relative Paths](#relative-paths) · [The Previous Directory: `cd -`](#the-previous-directory-cd--)</small>

### Managing Files

Work in `~/lab02`, and check the result with `tree ~/lab02` in the second terminal after **every** exercise.

34. 🌱 **Create files**: Create an **empty** file `groceries.txt` and a file `plan.txt` with two lines of text in it.
    Then create `soup.txt`, `pizza.txt` and `cake.txt` in `Recipes` with a **single** command, without going into
    `Recipes`.

    **Check:** `ls -l` shows size `0` for `groceries.txt`, but not for `plan.txt`; `Recipes` has the three new files. <small>→ [Managing Files](#managing-files)</small>
35. 🌱 **Create folders**: Create `Albums/2024/summer` and `Albums/2025/winter` with a **single** command.

    **Check:** `tree` shows both folders. <small>→ [Managing Files](#managing-files)</small>
36. 🌱 **Copy files**: Copy `books.txt` into `Albums`. Copy `cat.jpg` and `dog.jpg` from `Photos` into `Games` with a
    **single** command. Copy `dog.jpg` into `Albums/2025/winter` under the name `snow_dog.jpg`.

    **Check:** the two pictures are both in `Photos` and in `Games`, and `snow_dog.jpg` is in `winter`. <small>→ [Managing Files](#managing-files)</small>
37. 🌱 **Copy a folder**: Copy the whole `Games` folder to `/tmp/Games_backup`. Then run **exactly the same** command a
    second time, and find out where the second copy went. Delete **only** the second copy.

    **Check:** `tree /tmp/Games_backup` shows the same files as `tree ~/lab02/Games`, and nothing more. <small>→ [Managing Files](#managing-files)</small>
38. 🌱 **Rename and move**: Rename `groceries.txt` to `shopping.txt` and move it into `Recipes` with a **single** `mv`.
    Move `plan.txt` and `books.txt` into `Albums` with a **single** command.

    **Check:** `Recipes` has `shopping.txt`; `Albums` has `books.txt` and `plan.txt`; the only `.txt` file left in
    `~/lab02` is `answers.txt` (if you created it). <small>→ [Managing Files](#managing-files)</small>
39. 🌳 **Paths everywhere**: From `~/lab02/Games/2026`, without changing the current directory, copy `cat.jpg` from
    `Photos` into `Recipes` using **only relative** paths. Delete the copy, then copy it again using **only
    absolute** paths.

    **Check:** `Recipes` has `cat.jpg`. <small>→ [Every File is a Path](#every-file-is-a-path)</small>
40. 🌱 **Delete**: Delete `/tmp/Games_backup/chess.txt`. Move `sudoku.txt` from `puzzles` up into `Games/2026`, then
    delete the empty `puzzles` folder. Then delete `Albums/2024` and
    everything in `Albums/2025` using **only** `rmdir` and `rm` (no `-r`).

    **Check:** `Albums` has only `books.txt` and `plan.txt`, and `Games/2026` has only `sudoku.txt`. <small>→ [Managing Files](#managing-files)</small>
41. 🌳 **Delete a folder**: Delete `/tmp/Games_backup` with everything inside it with a **single** command.

    **Check:** `ls /tmp` no longer shows `Games_backup`. <small>→ [Managing Files](#managing-files)</small>

### Yazi

Do these exercises **only with Yazi** (the key table is in [Using Yazi](#using-yazi)). Keep a terminal next to it and
check the result with `tree ~/lab02` after every exercise.

42. 🌱 **Install Yazi**: Install Yazi.

    **Check:** `yazi --version` prints a version number. <small>→ [Installing Yazi on Fedora 44](#installing-yazi-on-fedora-44)</small>
43. 🌱 **Look around**: Open `~/lab02` in Yazi. Walk down into `Albums` and back up to `~/lab02`, first with the arrow
    keys, then without them. Make the hidden file appear, then hide it again.

    **Check:** `.secret` appears and disappears. <small>→ [Using Yazi](#using-yazi)</small>
44. 🌱 **Create and rename**: In `~/lab02`, create a file `menu.txt` and an empty folder `Drafts`. Rename `menu.txt` to
    `dinner.txt`, and rename `soup.txt` in `Recipes` to `tomato_soup.txt`.

    **Check:** `tree` shows `dinner.txt`, `Drafts` and `Recipes/tomato_soup.txt`. <small>→ [Using Yazi](#using-yazi)</small>
45. 🌱 **Copy and move**: Copy `dinner.txt` into `Recipes`. Move `dog.jpg` from `Photos` into `Drafts`.

    **Check:** `dinner.txt` is both in `~/lab02` and in `Recipes`; `dog.jpg` is in `Drafts` and no longer in
    `Photos`. <small>→ [Using Yazi](#using-yazi)</small>
46. 🌳 **Several files**: Copy both pictures from `Games` into `Albums` with a **single** paste. Then move
    `tomato_soup.txt`, `pizza.txt` and `cake.txt` from `Recipes` into `Drafts` with a **single** paste.

    **Check:** `Albums` has `cat.jpg` and `dog.jpg`; `Drafts` has the three recipes. <small>→ [Using Yazi](#using-yazi)</small>
47. 🌱 **Tabs**: Open `Albums`, `Recipes` and `Drafts` in three different tabs. Without leaving any of the three
    folders:
    * copy `plan.txt` into `Recipes`;
    * move `shopping.txt` into `Albums`;
    * move `pizza.txt` and `cake.txt` back into `Recipes` (if you moved them to `Drafts` in exercise 46).

    **Check:** `Recipes` has `plan.txt`, `pizza.txt` and `cake.txt`; `Albums` has `shopping.txt`. <small>→ [Tabs](#tabs)</small>
48. 🌳 **Trash or delete**: Send `dinner.txt` (the one in `~/lab02`) to the trash, and delete `Drafts` permanently. Then,
    from the terminal, find `dinner.txt` in the trash and move it back to `~/lab02`.

    **Check:** `dinner.txt` is back in `~/lab02`, and `Drafts` is gone. <small>→ [Using Yazi](#using-yazi)</small>

### Challenge

49. 🌳 **Reorganize**: Using the terminal for half of the work and Yazi for the other half, change `~/lab02` so that
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

50. 🌳 **Exactly five**: From `~/lab02/Recipes/desserts`, write a relative path to `sudoku.txt` that contains
    **exactly five** `..` and no `.`. Use it with `ls -l`.

    **Check:** `ls -l` shows `sudoku.txt`, and `realpath` of your path prints `/home/student/lab02/Games/2026/sudoku.txt`. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
51. 🌳 **Shortest path**: Find the **shortest** relative path from `/usr/share/doc` to `~/lab02/Notes`, and the
    shortest one from `~/lab02/Notes` back to `/usr/share/doc`. Use each of them with a single `cd`, then jump
    between the two folders twice more with `cd -` only.

    **Check:** after each `cd`, `pwd` prints the folder you wanted to reach. <small>→ [Relative Paths](#relative-paths)</small>
52. 🌳 **Clean up a path**: Write the **shortest** absolute path equivalent to
    `/home/../../../home/student/lab02/./Notes/../Games/2026/../../Recipes/desserts/..`, first on paper, then check it.

    **Check:** `realpath` prints the path you wrote. <small>→ [From Relative to Absolute](#from-relative-to-absolute)</small>
53. 🌳 **Swap**: Swap the names of `Notes/books.txt` and `Notes/plan.txt` using **only** `mv`.

    **Check:** `ls -l ~/lab02/Notes` shows that `books.txt` now has the size that `plan.txt` had before, and
    `plan.txt` is empty. <small>→ [Managing Files](#managing-files)</small>
54. 🌳 **Mirror**: Create in `/tmp/mirror` the same **folder** structure as `~/lab02` (only the folders, no files),
    with a **single** `mkdir` command.

    **Check:** `tree -d /tmp/mirror` and `tree -d ~/lab02` show the same folders. <small>→ [Managing Files](#managing-files)</small>
55. 🌳 **From far away**: Go to `/tmp`. With a **single** `mv` command and **only relative** paths, move `chess.txt`
    and `cat.jpg` from `Games` into `Recipes/desserts`. Then move them back with a single `mv`, this time from
    `~/lab02/Notes`.

    **Check:** after the first `mv`, `desserts` has three files; after the second one, `tree ~/lab02` shows the
    tree of the [Challenge](#challenge) again (with the names of exercise 53). <small>→ [Every File is a Path](#every-file-is-a-path)</small>
56. 🌳 **Backup with tabs**: With Yazi only, create the folder `~/lab02/Backup`, then copy the `Games`, `Notes` and
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
