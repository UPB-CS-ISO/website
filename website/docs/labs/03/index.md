# 03. Processes and Redirects

In the second lab you learned to find your way in the file system tree and to work with files and directories. In this
lab you will learn to **redirect** what a command reads and writes: you will save the output of a command into a file,
keep the errors apart and give a command a file instead of the keyboard. Then you will put many files together into
**archives**, and make them smaller by **compressing** them, with `tar`, `gzip`, `bzip2`, `xz` and `zip`. At the end
you will **inspect processes**: the running programs, through the files that the kernel makes for them in `/proc`, and
with `top`, `htop` and `btop`.

The most important idea of this lab is that a command reads from its **standard input** and writes to its **standard
output**, without knowing what is behind them: the keyboard, the display, a file or another command. The shell decides,
and a redirect is how you tell it.

## Objectives

- Understand the **standard input**, the **standard output** and the **standard error** of a command
- **Redirect** the output, the errors and the input of a command with `>`, `>>`, `2>`, `2>>`, `&>` and `<`
- Connect commands with **pipes** (`|`), count repeated lines with `sort` and `uniq`, and use the special files
  `/dev/null`, `/dev/zero` and `/dev/urandom`
- **Compress** and decompress files with `gzip`, `bzip2` and `xz`
- Create, list and extract **archives** with `tar`, uncompressed or compressed (`.tar.gz`, `.tar.bz2`, `.tar.xz`), and
  with `zip`
- Find out the type of an archive with `file`
- List processes with `ps` and find their **PID** and **PPID**
- **Inspect** a process through its directory in `/proc`: its state, its command, its current directory and its open
  files
- Watch the processes live with `top`, `htop` and `btop`

## Resources

1. _[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor de
   Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)_
   - Chapter 2 - _Utilizarea sistemului de fișiere_, section 2.4
   - Chapter 4 - _Procese_, sections 4.2, 4.4, 4.7 and 4.8
2. _Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021_
   - Chapter 2 - _Basic Commands and Directory Hierarchy_, sections 2.14, 2.16 and 2.18
   - Chapter 8 - _A Closer Look at Processes and Resource Utilization_, sections 8.1 and 8.2
3. _[htop](https://htop.dev)_ and _[btop](https://github.com/aristocratos/btop)_
4. The lecture slides: [03. Processes](/docs/lectures/03)
5. The manual pages: `man sort`, `man uniq`, `man tar`, `man gzip`, `man bzip2`, `man xz`, `man zip`, `man unzip`,
   `man ps`, `man proc`, `man top`, `man htop`, `man hier` (the directories of the system), and `man bash` (search for `REDIRECTION`)

## Standard Input, Output and Error

Every running command has a list of the files it has open, the **File Descriptor Table**. The **index** in this table is
the **file descriptor**, and the first three are always there:

| File descriptor | Name                          | The command uses it to   | Redirect | By default, in a terminal   |
| --------------- | ----------------------------- | ------------------------ | -------- | --------------------------- |
| `0`             | `stdin`, the standard input   | read its input           | `<`      | comes from the **keyboard** |
| `1`             | `stdout`, the standard output | write its results        | `>`      | goes to the **display**     |
| `2`             | `stderr`, the standard error  | write its error messages | `2>`     | goes to the **display**     |

A command reads its input from `0`, writes its results to `1` and its error messages to `2`. It does not know what is
behind them. Before it starts the command, the shell can connect any of them to a **file**: this is a **redirect**.

## Redirects

| Redirect               | What it does                                                                   |
| ---------------------- | ------------------------------------------------------------------------------ |
| `command > file`       | Writes the output (`1`) into `file`. The file is **emptied** first, or created |
| `command >> file`      | **Appends** the output to the end of `file`                                    |
| `command 2> file`      | Writes the errors (`2`) into `file`                                            |
| `command 2>> file`     | Appends the errors to the end of `file`                                        |
| `command > out 2> err` | The output into `out`, the errors into `err`                                   |
| `command &> file`      | Both the output and the errors into `file`                                     |
| `command > file 2>&1`  | The same, written in the older way: "`2` goes where `1` goes"                  |
| `command < file`       | Reads the input (`0`) from `file`, instead of the keyboard                     |

:::danger

`>` **empties** the file before the command starts, even if the command fails. `ls > notes.txt` deletes everything that
was in `notes.txt`. Use `>>` when you want to keep the old content.

:::

### Output: `>` and `>>`

```shell-session
[student@fedora lab03]$ ls Music > list.txt
[student@fedora lab03]$ cat list.txt
jazz.mp3
pop.mp3
rock.mp3
[student@fedora lab03]$ echo "--- end ---" >> list.txt
[student@fedora lab03]$ cat list.txt
jazz.mp3
pop.mp3
rock.mp3
--- end ---
[student@fedora lab03]$ echo "new" > list.txt
[student@fedora lab03]$ cat list.txt
new
```

- `ls Music > list.txt` printed nothing on the display: its output went into `list.txt`, which was created.
- `>>` added a line at the end of the file.
- The last `>` emptied the file and wrote only `new`.

### Errors: `2>` and `2>>`

Error messages are written to `2`, not to `1`. A `>` alone does **not** redirect them:

```shell-session
[student@fedora lab03]$ ls Music /nope > list.txt
ls: cannot access '/nope': No such file or directory
[student@fedora lab03]$ ls Music /nope > list.txt 2> errors.txt
[student@fedora lab03]$ cat errors.txt
ls: cannot access '/nope': No such file or directory
[student@fedora lab03]$ ls /nada 2>> errors.txt
[student@fedora lab03]$ cat errors.txt
ls: cannot access '/nope': No such file or directory
ls: cannot access '/nada': No such file or directory
[student@fedora lab03]$ ls Music /nope &> all.txt
[student@fedora lab03]$ cat all.txt
ls: cannot access '/nope': No such file or directory
Music:
jazz.mp3
pop.mp3
rock.mp3
```

- With `> list.txt`, the list went into the file, but the error still appeared on the display.
- With `2> errors.txt`, the error went into its own file, and `2>>` added a second error at the end of it.
- With `&>`, both the list and the error went into the same file.

### Input: `<`

`<` gives a command a file **instead of the keyboard**. The command reads its input from `0` and does not know that it
is a file:

```shell-session
[student@fedora lab03]$ sort < fruits.txt
apple
apple
apple
banana
banana
cherry
kiwi
[student@fedora lab03]$ wc -l fruits.txt
7 fruits.txt
[student@fedora lab03]$ wc -l < fruits.txt
7
```

- `sort` read the lines from `fruits.txt` and printed them in alphabetical order.
- `wc -l fruits.txt` counted the lines of a file that it **opened by itself**, so it knows its name and prints it.
- With `<`, the shell opened the file and gave it to `wc` as its input: `wc` does not know any name, so it prints only
  the number.

:::tip

Run `sort` without anything: it reads from the keyboard. Type a few words, one per line, then press
<kbd>Ctrl</kbd>+<kbd>D</kbd> (_end of input_): `sort` prints them in order. In the same way, `cat > notes.txt` saves
everything you type into `notes.txt`, until you press <kbd>Ctrl</kbd>+<kbd>D</kbd>.

:::

### Pipes: `|`

A **pipe** connects the **output** (`1`) of a command to the **input** (`0`) of the next one, without any file in
between:

```shell-session
[student@fedora lab03]$ ls /usr/bin | wc -l
1843
[student@fedora lab03]$ ls -l /usr/bin | less
```

- `ls /usr/bin | wc -l` counted the programs in `/usr/bin`: `ls` wrote the names, one per line, and `wc -l` counted
  the lines.
- `ls -l /usr/bin | less` showed the long list one screen at a time, instead of letting it run off the screen.

| Command       | What it does with its input                                        |
| ------------- | ------------------------------------------------------------------ |
| `sort`        | Sorts the lines in alphabetical order                              |
| `uniq`        | Removes the lines that repeat the line right above them            |
| `wc -l`       | Counts the lines                                                   |
| `head -n <N>` | Keeps the first `N` lines                                          |
| `head -c <N>` | Keeps the first `N` bytes                                          |
| `tail -n <N>` | Keeps the last `N` lines                                           |
| `grep <text>` | Keeps the lines that contain `text`                                |
| `less`        | Shows it one screen at a time, like `man` (quit with <kbd>q</kbd>) |

#### Searching for a text: `grep`

`grep` prints only the lines that contain a text. It reads the files given as parameters, or its input when there are
none, so it works at the end of a pipe too:

```shell-session
[student@fedora lab03]$ grep apple fruits.txt
apple
apple
apple
[student@fedora lab03]$ grep -c apple fruits.txt
3
[student@fedora lab03]$ grep -i APPLE fruits.txt
apple
apple
apple
[student@fedora lab03]$ grep student /etc/group
wheel:x:10:student
student:x:1000:
[student@fedora lab03]$ ps | grep bash
   2817 pts/0    00:00:00 bash
```

- `grep apple fruits.txt` printed the three lines of `fruits.txt` that contain `apple`; `-c` only counted them.
- `-i` ignores the difference between upper and lower case letters.
- `grep student /etc/group` showed the groups of `student`: its own group, and `wheel`, the group of the users that
  are allowed to use `sudo`.
- `ps | grep bash` kept only the line of `bash` from the list of `ps`.

| Option | What it does                                                        |
| ------ | ------------------------------------------------------------------- |
| `-i`   | Ignores upper and lower case                                        |
| `-c`   | Prints only how many lines contain the text                         |
| `-v`   | Prints the lines that do **not** contain the text                   |
| `-n`   | Prints the line number in front of every line it finds              |
| `-r`   | Searches in all the files of a directory, and of its subdirectories |

:::tip

Put the text between quotes when it has spaces: `grep 'model name' /proc/cpuinfo`.

:::

#### Repeated Lines: `uniq`

`uniq` removes a line when it is the same as the line **right above it**. It compares only neighbor lines, so it is
almost always used after `sort`, which puts the same lines next to each other:

```shell-session
[student@fedora lab03]$ uniq fruits.txt
banana
apple
cherry
apple
kiwi
banana
apple
[student@fedora lab03]$ sort fruits.txt | uniq
apple
banana
cherry
kiwi
[student@fedora lab03]$ sort fruits.txt | uniq -c
      3 apple
      2 banana
      1 cherry
      1 kiwi
[student@fedora lab03]$ sort fruits.txt | uniq -c | sort -nr
      3 apple
      2 banana
      1 kiwi
      1 cherry
[student@fedora lab03]$ sort fruits.txt | uniq -d
apple
banana
```

- `uniq fruits.txt` changed nothing: in `fruits.txt`, no line is the same as the one above it.
- After `sort`, the three `apple` lines are together, and `uniq` kept only one of them.
- `-c` wrote in front of every line how many times it appeared.
- `sort -nr` sorted these lines by the number in front of them (`-n`), from the largest (`-r`): the most frequent line
  is the first one.
- `-d` printed only the lines that appear more than once.

| Option    | What it does                                                                                          |
| --------- | ----------------------------------------------------------------------------------------------------- |
| `uniq -c` | Prints in front of every line how many times it appears (**c**ount)                                   |
| `uniq -d` | Prints only the lines that appear more than once (**d**uplicates)                                     |
| `uniq -u` | Prints only the lines that appear exactly once (**u**nique)                                           |
| `uniq -i` | Ignores upper and lower case                                                                          |
| `sort -n` | Sorts by the **n**umber at the beginning of the line, not alphabetically (`10` after `9`, not before) |
| `sort -r` | Sorts in **r**everse order                                                                            |
| `sort -u` | Sorts and removes the repeated lines, the same as `sort \| uniq`                                      |

:::caution

Without `sort`, `uniq` removes only the repeated lines that are **next to each other**. `uniq fruits.txt` still has
three `apple` lines.

:::

### Special Files

The kernel makes some **special files** in `/dev`. They are not stored on the disk: a driver in the kernel answers
when a command reads or writes them.

| File           | Reading gives                             | Writing                     | Used for                                                                   |
| -------------- | ----------------------------------------- | --------------------------- | -------------------------------------------------------------------------- |
| `/dev/null`    | nothing: _end of file_ right away         | everything is **discarded** | throwing away output you don't want: `find /etc -name passwd 2> /dev/null` |
| `/dev/zero`    | bytes with the value `0`, **without end** | everything is discarded     | creating a file of a given size: `head -c 1M /dev/zero > zeros.bin`        |
| `/dev/urandom` | **random** bytes, **without end**         | allowed, but not needed     | random data, keys and passwords: `head -c 16 /dev/urandom \| xxd`          |

```shell-session
[student@fedora lab03]$ find /etc -name passwd 2> /dev/null
/etc/pam.d/passwd
/etc/passwd
[student@fedora lab03]$ head -c 8 /dev/zero | xxd
00000000: 0000 0000 0000 0000                      ........
[student@fedora lab03]$ head -c 8 /dev/urandom | xxd
00000000: 9f3a 51c2 07e8 b4d1                      .:Q.....
```

- `2> /dev/null` threw away the `Permission denied` messages of `find`.
- `head -c 8` kept the first 8 bytes, and `xxd` showed them in hexadecimal: zeros, then random bytes (different every
  time).

## Archives and Compression

An **archive** is a single file that holds many files and directories, together with their names, their dates and
their permissions. **Compression** makes a file smaller, by writing the same information with fewer bytes. On Linux, the
two are usually done by different programs: `tar` makes the archive, and `gzip`, `bzip2` or `xz` compress it. `zip`
does both at once.

### Compressing One File: `gzip`, `bzip2` and `xz`

The three compressors work in the same way: they replace a file with a compressed one, with an extension added at the
end, and they put it back when you decompress it.

| Compress       | Decompress                         | Extension |                                          |
| -------------- | ---------------------------------- | --------- | ---------------------------------------- |
| `gzip <file>`  | `gunzip <file>.gz` or `gzip -d`    | `.gz`     | the fastest, compresses the least        |
| `bzip2 <file>` | `bunzip2 <file>.bz2` or `bzip2 -d` | `.bz2`    | slower, compresses more                  |
| `xz <file>`    | `unxz <file>.xz` or `xz -d`        | `.xz`     | the slowest, usually compresses the most |

| Option        | Means (the same for all three)                                                         |
| ------------- | -------------------------------------------------------------------------------------- |
| `-k`          | **keep** the original file                                                             |
| `-c`          | write the result to the standard output, to use with `>` or `\|`: the original is kept |
| `-v`          | **verbose**: print how much smaller the file got                                       |
| `-1` ... `-9` | from the fastest (`-1`) to the best compression (`-9`)                                 |

```shell-session
[student@fedora lab03]$ gzip -k numbers.txt
[student@fedora lab03]$ bzip2 -k numbers.txt
[student@fedora lab03]$ xz -k numbers.txt
[student@fedora lab03]$ ls -l numbers.txt*
-rw-r--r--. 1 student student 108894 Oct  6 10:12 numbers.txt
-rw-r--r--. 1 student student  25147 Oct  6 10:12 numbers.txt.bz2
-rw-r--r--. 1 student student  45016 Oct  6 10:12 numbers.txt.gz
-rw-r--r--. 1 student student   4948 Oct  6 10:12 numbers.txt.xz
[student@fedora lab03]$ rm numbers.txt
[student@fedora lab03]$ unxz -k numbers.txt.xz
[student@fedora lab03]$ wc -l numbers.txt
20000 numbers.txt
```

- With `-k`, each compressor kept `numbers.txt` and made a compressed copy of it.
- The same file became 45 KB with `gzip`, 25 KB with `bzip2` and less than 5 KB with `xz`.
- After deleting `numbers.txt`, `unxz -k` put it back from `numbers.txt.xz`, with all its 20000 lines.

:::caution

Without `-k`, `gzip numbers.txt` **deletes** `numbers.txt` and leaves only `numbers.txt.gz`. This is the normal
behavior of all three compressors.

:::

With `-v`, the three compressors print how well they compressed, but **not** in the same way:

```shell-session
[student@fedora lab03]$ gzip -v -k numbers.txt
numbers.txt:	 58.7% -- created numbers.txt.gz
[student@fedora lab03]$ bzip2 -v -k numbers.txt
  numbers.txt:  4.330:1,  1.847 bits/byte, 76.91% saved, 108894 in, 25147 out.
[student@fedora lab03]$ xz -v -k numbers.txt
numbers.txt (1/1)
  100 %         4,948 B / 106.3 KiB = 0.045
```

| Compressor | Prints                                                                                                                           | Better compression means |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `gzip -v`  | how much it **saved**, as a percentage: `58.7%`                                                                                  | a **larger** percentage  |
| `bzip2 -v` | how much it **saved** (`76.91% saved`), and the sizes before (`in`) and after (`out`)                                            | a **larger** percentage  |
| `xz -v`    | the new size, the old size and the **ratio** between them: `0.045` means the new file is 4.5% of the old one, so 95.5% was saved | a **smaller** ratio      |

The `100 %` that `xz` prints is **not** the compression: it is how much of the file it has read so far, and it always
ends at `100 %`.

:::info

A compressor works on **one** file. It cannot put a directory or several files together: this is the job of `tar`.

:::

### Archives: `tar`

`tar` (_tape archive_) puts files and directories together into a single file, usually called `.tar`. Its options are
letters, written together, and the most used ones are:

| Letter           | Long form                 | Means                                                                                |
| ---------------- | ------------------------- | ------------------------------------------------------------------------------------ |
| `c`              | `--create`                | **create** an archive                                                                |
| `t`              | `--list`                  | lis**t** the content of an archive                                                   |
| `x`              | `--extract`               | e**x**tract an archive                                                               |
| `r`              | `--append`                | add files at the end of an archive (not for compressed archives)                     |
| `v`              | `--verbose`               | **verbose**: print the name of every file                                            |
| `f <archive>`    | `--file <archive>`        | the name of the archive **file**                                                     |
| `-C <directory>` | `--directory <directory>` | change to `directory` first: extract the archive there, or take the files from there |

:::tip

Every `tar` command has **exactly one** of `c`, `t`, `x` and `r`: what to do. The other letters change how it is done.
The letters are written together, without a `-` (`tar cvf`, the old style, or `tar -cvf`). Put `f` **last**: the word
right after the letters is the name of the archive. `-C` is written apart, with its own `-`.

:::

| Command                              | What it does                                                                                    |
| ------------------------------------ | ----------------------------------------------------------------------------------------------- |
| `tar cvf music.tar Music fruits.txt` | Creates `music.tar` with the directory `Music`, everything inside it, and the file `fruits.txt` |
| `tar tf music.tar`                   | Lists the content of `music.tar`                                                                |
| `tar tvf music.tar`                  | Lists the content with the details: permissions, owner, size and date                           |
| `tar xvf music.tar`                  | Extracts `music.tar` in the current directory                                                   |
| `tar xvf music.tar -C /tmp/extract`  | Extracts it in `/tmp/extract` (the directory must exist)                                        |
| `tar xvf music.tar Music/jazz.mp3`   | Extracts only one file, with the name it has in the archive                                     |
| `tar rvf music.tar numbers.txt`      | Adds `numbers.txt` at the end of the archive                                                    |

:::caution

`tar x` **overwrites** the files that already exist, without asking. Extract into an empty directory with `-C` when you
are not sure what is in the archive.

:::

```shell-session
[student@fedora lab03]$ tar cvf music.tar Music fruits.txt
Music/
Music/jazz.mp3
Music/pop.mp3
Music/rock.mp3
fruits.txt
[student@fedora lab03]$ tar tf music.tar
Music/
Music/jazz.mp3
Music/pop.mp3
Music/rock.mp3
fruits.txt
[student@fedora lab03]$ mkdir /tmp/extract
[student@fedora lab03]$ tar xvf music.tar -C /tmp/extract
Music/
Music/jazz.mp3
Music/pop.mp3
Music/rock.mp3
fruits.txt
[student@fedora lab03]$ file music.tar
music.tar: POSIX tar archive (GNU)
```

- `tar cvf` created the archive and printed every file it put in it, the directory `Music` with everything inside it.
- `tar tf` listed the content without extracting anything.
- `tar xvf ... -C /tmp/extract` recreated the same files in `/tmp/extract`: `/tmp/extract/Music/jazz.mp3`, and so on.
- `file` looked inside the archive and found that it is a `tar` archive.

:::caution

Do not forget the name of the archive after `f`. `tar cvf Music` tries to create an archive called `Music` and stops
with `Cowardly refusing to create an empty archive`. Worse, `tar cvf fruits.txt Music` **overwrites** `fruits.txt` with
an archive.

:::

:::info

A `.tar` archive is **not** compressed. It is as large as all its files together, plus a little: for every file and
directory, `tar` adds 512 bytes with its name, permissions, owner and date, and it fills the end of every file up to a
multiple of 512 bytes.

:::

### Compressed Archives: `.tar.gz`, `.tar.bz2` and `.tar.xz`

`tar` can compress the archive, with one more letter. It runs `gzip`, `bzip2` or `xz` for you:

| Letter | Compressor | Extension             | Example                        |
| ------ | ---------- | --------------------- | ------------------------------ |
| `z`    | `gzip`     | `.tar.gz` or `.tgz`   | `tar czvf music.tar.gz Music`  |
| `j`    | `bzip2`    | `.tar.bz2` or `.tbz2` | `tar cjvf music.tar.bz2 Music` |
| `J`    | `xz`       | `.tar.xz` or `.txz`   | `tar cJvf music.tar.xz Music`  |

To **list** or **extract** a compressed archive, you do not need the letter: `tar` finds out the compression by
itself.

```shell-session
[student@fedora lab03]$ tar cf all.tar Music numbers.txt
[student@fedora lab03]$ tar czf all.tar.gz Music numbers.txt
[student@fedora lab03]$ tar cjf all.tar.bz2 Music numbers.txt
[student@fedora lab03]$ tar cJf all.tar.xz Music numbers.txt
[student@fedora lab03]$ ls -l all.*
-rw-r--r--. 1 student student 112640 Oct  6 10:20 all.tar
-rw-r--r--. 1 student student  25333 Oct  6 10:20 all.tar.bz2
-rw-r--r--. 1 student student  45234 Oct  6 10:20 all.tar.gz
-rw-r--r--. 1 student student   5692 Oct  6 10:20 all.tar.xz
[student@fedora lab03]$ file all.*
all.tar:     POSIX tar archive (GNU)
all.tar.bz2: bzip2 compressed data, block size = 900k
all.tar.gz:  gzip compressed data, from Unix, original size modulo 2^32 112640
all.tar.xz:  XZ compressed data, checksum CRC64
[student@fedora lab03]$ tar tvf all.tar.xz
drwxr-xr-x student/student   0 2026-10-06 10:12 Music/
-rw-r--r-- student/student   0 2026-10-06 10:12 Music/jazz.mp3
-rw-r--r-- student/student   0 2026-10-06 10:12 Music/pop.mp3
-rw-r--r-- student/student   0 2026-10-06 10:12 Music/rock.mp3
-rw-r--r-- student/student 108894 2026-10-06 10:12 numbers.txt
```

- The four archives hold the same files. The `.tar` is a little larger than the files themselves; the compressed ones
  are much smaller, `xz` the smallest.
- `file` recognized every type from the content, not from the extension.
- `tar tvf` listed the `.tar.xz` archive without being told it is compressed with `xz`.

:::tip

A compressed archive is a `.tar` archive compressed as a single file: `all.tar.gz` is exactly what you get with
`tar cf all.tar ...` followed by `gzip all.tar`. This is why it has two extensions.

:::

### Zip Archives: `zip` and `unzip`

`zip` archives and compresses in one step, and its archives open on every operating system, including Windows and
macOS.

| Command                             | What it does                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------------------ |
| `zip music.zip Music/*`             | Creates `music.zip` with the files in `Music`                                              |
| `zip -r music.zip Music fruits.txt` | Creates `music.zip` with the directory `Music`, **everything** inside it, and `fruits.txt` |
| `zip -u music.zip numbers.txt`      | Adds `numbers.txt` to the archive, or updates it if it changed                             |
| `zip -sf music.zip`                 | Lists the names in the archive                                                             |
| `unzip -l music.zip`                | Lists the content, with sizes and dates                                                    |
| `unzip music.zip`                   | Extracts the archive in the current directory                                              |
| `unzip music.zip -d /tmp/unzipped`  | Extracts it in `/tmp/unzipped` (the directory is created)                                  |
| `unzip music.zip fruits.txt`        | Extracts only one file                                                                     |

:::info

When `zip` is given an archive name, it creates the archive if it doesn’t exist. If the archive already exists, `zip` updates it: files not yet in the archive are added, files with the same path are replaced, and all other existing entries are left unchanged.

:::

```shell-session
[student@fedora lab03]$ zip -r music.zip Music fruits.txt
  adding: Music/ (stored 0%)
  adding: Music/jazz.mp3 (stored 0%)
  adding: Music/pop.mp3 (stored 0%)
  adding: Music/rock.mp3 (stored 0%)
  adding: fruits.txt (deflated 40%)
[student@fedora lab03]$ unzip -l music.zip
Archive:  music.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  10-06-2026 10:12   Music/
        0  10-06-2026 10:12   Music/jazz.mp3
        0  10-06-2026 10:12   Music/pop.mp3
        0  10-06-2026 10:12   Music/rock.mp3
       44  10-06-2026 10:12   fruits.txt
---------                     -------
       44                     5 files
```

`zip` printed how much it compressed every file: the empty `.mp3` files were stored as they are, and `fruits.txt`
became 40% smaller.

:::caution

Without `-r`, `zip music.zip Music` puts only the **empty** directory in the archive, not the files inside it.

:::

:::info

`zip` creates `music.zip` only if it does not exist yet. If the archive already exists, `zip` **adds** to it the files
that are not in it, and **replaces** the ones that have the same name (it prints `updating:` instead of `adding:` for
them). The files that are already in the archive stay there. To start from an empty archive, delete the old one first.

:::

### Which One to Use

| Format     | Archive and compress with | Extract with | Use it for                                                             |
| ---------- | ------------------------- | ------------ | ---------------------------------------------------------------------- |
| `.tar`     | `tar cf`                  | `tar xf`     | putting files together, without compressing them                       |
| `.tar.gz`  | `tar czf`                 | `tar xf`     | the most common archive on Linux, fast                                 |
| `.tar.bz2` | `tar cjf`                 | `tar xf`     | smaller archives, older programs                                       |
| `.tar.xz`  | `tar cJf`                 | `tar xf`     | the smallest archives, for example the source code of the Linux kernel |
| `.zip`     | `zip -r`                  | `unzip`      | files you send to people who use Windows or macOS                      |

:::tip

Not sure what an archive is? Run `file` on it. The extension is only part of the name: `file` looks at the content.

:::

## Inspecting Processes

A **program** is a file on the disk, for example `/usr/bin/sleep`. When you run it, the operating system loads it into
memory and it becomes a **process**. Every process has a number, the **PID** (_Process ID_), and remembers the PID of
the process that started it, its **parent**: the **PPID** (_Parent Process ID_).

### Listing Processes: `ps`

| Command           | What it shows                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------------ |
| `echo $$`         | The PID of the current shell                                                                     |
| `ps`              | The processes of the current terminal                                                            |
| `ps -f`           | The same processes, with more columns: `UID`, `PID`, `PPID`, the start time and the full command |
| `ps -e`           | **All** the processes of the system (**e**very process)                                          |
| `ps -ef`          | **All** the processes of the system, with the columns of `-f`                                    |
| `ps -p <PID>`     | Only the process with this PID                                                                   |
| `ps -o <columns>` | Only the columns you choose, for example `ps -o pid,ppid,stat,cmd`                               |
| `ps --no-headers` | Without the first line, the one with the names of the columns                                    |
| `pgrep <name>`    | Only the PIDs of the processes whose name **contains** `name`                                    |

The columns that `ps` prints, and the names you give to `-o` to choose them:

| Column          | Name for `-o` | What it shows                                                                                                                                                                                                                                            |
| --------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `UID` or `USER` | `user`        | The user that owns the process                                                                                                                                                                                                                           |
| `PID`           | `pid`         | The number of the process                                                                                                                                                                                                                                |
| `PPID`          | `ppid`        | The number of its parent                                                                                                                                                                                                                                 |
| `C`             | `c`           | How much of the processor it uses, as a percentage                                                                                                                                                                                                       |
| `STIME`         | `stime`       | When it started                                                                                                                                                                                                                                          |
| `TTY`           | `tty`         | The terminal it runs in (`pts/0`, `pts/1`, ...); `?` for the processes that have no terminal                                                                                                                                                             |
| `TIME`          | `time`        | How much processor time it has used so far, not how long it has been running                                                                                                                                                                             |
| `STAT`          | `stat`        | Its state: `S`, `R`, `T` or `Z`, from the [table of states](#the-proc-file-system) below, followed by some details (for example `s` for the first process of a session, like a shell, and `+` for a process that runs in the foreground of its terminal) |
| `CMD`           | `cmd`         | The full command line, with its parameters                                                                                                                                                                                                               |
| `COMMAND`       | `comm`        | Only the name of the program, without its parameters                                                                                                                                                                                                     |

```shell-session
[student@fedora ~]$ ps -o pid,ppid,stat,cmd
    PID    PPID STAT CMD
   2817    2790 Ss   bash
   3110    2817 R+   ps -o pid,ppid,stat,cmd
```

- The shell, `bash`, waits for a command (`S`) and is the first process of its session (`s`).
- `ps` runs (`R`) in the foreground of the terminal (`+`), and its parent is `bash`.

```shell-session
[student@fedora ~]$ echo $$
2817
[student@fedora ~]$ ps -f
UID          PID    PPID  C STIME TTY          TIME CMD
student     2817    2790  0 10:02 pts/0    00:00:00 bash
student     3105    2817  0 10:15 pts/0    00:00:00 ps -f
```

- The shell of this terminal is `bash`, with the PID `2817`, the same number as `$$`.
- `ps` is a process too, started by `bash`: its PPID is `2817`. Every time you run it, it gets a new PID.

To have a process to look at, open a **second terminal** and start a command that keeps running, for example
`sleep 1000` (it waits for 1000 seconds). Find it from the first terminal:

```shell-session
[student@fedora ~]$ pgrep sleep
3150
[student@fedora ~]$ ps -f -p 3150
UID          PID    PPID  C STIME TTY          TIME CMD
student     3150    2905  0 10:16 pts/1    00:00:00 sleep 1000
```

`sleep` runs in the other terminal (`pts/1`), and its parent, `2905`, is the `bash` of that terminal. When you are done
with it, stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd> in its terminal.

### The `/proc` File System

The kernel shows every process as a **directory** in `/proc`, named after its PID, for example for the `sleep` above it will be `/proc/3150`.
Like the special files, these files are not on the disk: the kernel makes up their content when you read them.
`/proc/self` is always the directory of the process that reads it, and `/proc/$$` is the one of your shell.

| File                  | What it shows                                                                   |
| --------------------- | ------------------------------------------------------------------------------- |
| `/proc/<PID>/status`  | The name, the state, the PID, the PPID, the owner and the memory of the process |
| `/proc/<PID>/cmdline` | The command line, with the words separated by `\0` bytes instead of spaces      |
| `/proc/<PID>/cwd`     | A link to the **current directory** of the process                              |
| `/proc/<PID>/exe`     | A link to the **program** that runs                                             |
| `/proc/<PID>/fd/`     | The **File Descriptor Table**: one link for every open file                     |
| `/proc/<PID>/environ` | The environment variables, separated by `\0` bytes                              |
| `/proc/<PID>/maps`    | How the program and its libraries are placed in memory                          |

```shell-session
[student@fedora ~]$ head -n 7 /proc/3150/status
Name:	sleep
Umask:	0022
State:	S (sleeping)
Tgid:	3150
Ngid:	0
Pid:	3150
PPid:	2905
[student@fedora ~]$ ls -l /proc/3150/exe /proc/3150/cwd
lrwxrwxrwx. 1 student student 0 Oct  6 10:17 /proc/3150/cwd -> /home/student
lrwxrwxrwx. 1 student student 0 Oct  6 10:17 /proc/3150/exe -> /usr/bin/sleep
[student@fedora ~]$ cat -v /proc/3150/cmdline
sleep^@1000^@
[student@fedora ~]$ ls -l /proc/3150/fd
total 0
lrwx------. 1 student student 64 Oct  6 10:17 0 -> /dev/pts/1
lrwx------. 1 student student 64 Oct  6 10:17 1 -> /dev/pts/1
lrwx------. 1 student student 64 Oct  6 10:17 2 -> /dev/pts/1
```

- `status` shows that `sleep` is waiting (`S`), and that its parent is `2905`.
- `exe` points to the program, `/usr/bin/sleep`, and `cwd` to the directory where it was started.
- `cmdline` separates the words with `\0` bytes, which are invisible: `cat -v` shows them as `^@`.
- `0`, `1` and `2` point to `/dev/pts/1`: the second terminal, which is both its keyboard and its display.

The letter in the `State` line (and in the `STAT` column of `ps`) is the **state** of the process:

| Letter | State              | Means                                                   |
| ------ | ------------------ | ------------------------------------------------------- |
| `R`    | Running or Ready   | Runs on a processor, or waits for one                   |
| `S`    | Sleeping (waiting) | Waits for something: a key, a timer, data from a pipe   |
| `T`    | Stopped            | Paused, for example with <kbd>Ctrl</kbd>+<kbd>Z</kbd>   |
| `Z`    | Zombie             | Finished, but its parent has not read its exit code yet |

`/proc` also has files about the whole system:

| File            | What it shows                                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `/proc/cpuinfo` | The processors, one block for each of them                                                                                                 |
| `/proc/meminfo` | The memory, in kB: `MemTotal`, `MemFree`, `MemAvailable`, ...                                                                              |
| `/proc/uptime`  | Two numbers: the seconds since the system started, then the seconds the processors were idle (added up for all of them)                    |
| `/proc/loadavg` | The **load** in the last 1, 5 and 15 minutes, then the processes that are now in the Running state / all processes, and the last PID given |
| `/proc/version` | The version of the kernel, and the compiler that built it                                                                                  |

:::info

The PIDs and the paths above are different on your computer: use the ones that `pgrep` and `ps` print for you. You can
read the files of your own processes; for the processes of other users, most of them say `Permission denied`.

:::

### `top`

`top` shows the processes **live**, like the _Task Manager_ of Windows. It updates the list every few seconds, with the
processes that use the most processor time at the top.

```
top - 10:30:12 up  1:28,  1 user,  load average: 0.08, 0.12, 0.10
Tasks: 248 total,   1 running, 247 sleeping,   0 stopped,   0 zombie
%Cpu(s):  1.3 us,  0.7 sy,  0.0 ni, 97.9 id,  0.0 wa,  0.1 hi,  0.0 si,  0.0 st
MiB Mem :   3911.4 total,   1873.2 free,   1245.6 used,    1042.9 buff/cache
MiB Swap:   3911.0 total,   3911.0 free,      0.0 used.    2665.8 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1718 student   20   0 1186420  98340  61200 S   1.3   2.5   0:12.41 sway
   2790 student   20   0  318264  41212  30124 S   0.3   1.0   0:02.03 foot
      1 root      20   0   49736  38544  10208 S   0.0   1.0   0:02.31 systemd
```

- The first lines are a summary of the system: the time since it started, the load, how many processes are in every
  state, the use of the processors and of the memory.
- Below, every process has its PID, its owner (`USER`), its memory (`RES`, in KB), its state (`S`), the share of the
  processor and of the memory it uses, and its command.

| Key          | Action                                                                       |
| ------------ | ---------------------------------------------------------------------------- |
| <kbd>P</kbd> | Sort by processor use (the default)                                          |
| <kbd>M</kbd> | Sort by memory use                                                           |
| <kbd>T</kbd> | Sort by the processor time used so far                                       |
| <kbd>c</kbd> | Show the full command line                                                   |
| <kbd>u</kbd> | Show only the processes of a user (type the name and press <kbd>Enter</kbd>) |
| <kbd>1</kbd> | Show every processor on its own line                                         |
| <kbd>V</kbd> | Show the processes as a tree                                                 |
| <kbd>h</kbd> | Help                                                                         |
| <kbd>q</kbd> | Quit                                                                         |

:::tip

`top -b -n 1` prints the list only **once**, without updating it, so you can redirect it: `top -b -n 1 > top.txt`.

:::

### `htop`

`htop` does the same job as `top`, but with colors, bars for every processor, and menus at the bottom of the screen.
Start it with `htop` and quit with <kbd>q</kbd> or <kbd>F10</kbd>.

![htop](./htop.png)

At the top, `htop` shows a bar for every processor (`0` and `1`), the memory (`Mem`) and the swap (`Swp`), the number of
tasks, the load average and the uptime. Below them is the list of processes, one per line, and at the bottom the menu
with the function keys. In the image above, the list shows only the processes of `student` (<kbd>u</kbd>) as a tree
(<kbd>F5</kbd>): the terminal (`foot`) runs four `bash` shells, and each of them runs a command (the third one runs the
pipeline `sleep 800 | sleep 900`). The chosen process is `sleep 1000`.

| Key                            | Action                                                                                             | Like                                 |
| ------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------ |
| <kbd>↑</kbd> <kbd>↓</kbd>      | Choose a process                                                                                   |                                      |
| <kbd>F3</kbd> or <kbd>/</kbd>  | **Search**: jump to the next process whose command contains a text (press again for the next one)  | `pgrep`                              |
| <kbd>F4</kbd> or <kbd>\\</kbd> | **Filter**: show only the processes whose command contains a text (<kbd>Esc</kbd> shows all again) |                                      |
| <kbd>F5</kbd> or <kbd>t</kbd>  | Show the processes as a tree                                                                       | <kbd>V</kbd> in `top`                |
| <kbd>F6</kbd>                  | Choose the column to sort by                                                                       |                                      |
| <kbd>P</kbd> / <kbd>M</kbd>    | Sort by processor use / memory use / processor time                                                | <kbd>P</kbd> / <kbd>M</kbd> in `top` |
| <kbd>u</kbd>                   | Show only the processes of a user, chosen from a list                                              | <kbd>u</kbd> in `top`                |
| <kbd>l</kbd>                   | Show the open files of the chosen process                                                          | `ls -l /proc/<PID>/fd`               |
| <kbd>F2</kbd>                  | Setup: choose the columns and the colors                                                           |                                      |
| <kbd>F1</kbd> or <kbd>h</kbd>  | Help                                                                                               |                                      |
| <kbd>q</kbd> or <kbd>F10</kbd> | Quit                                                                                               |                                      |

:::tip

`htop` also shows the **threads** of the processes, in green. Press <kbd>H</kbd> to hide them and the list becomes much
shorter.

:::

### `btop`

`btop` is a newer program of the same kind. Its screen is split into boxes: the processors with a graph of their use,
the memory and the disks, the network, and the list of processes. Start it with `btop` and quit with <kbd>q</kbd>.

| Key                            | Action                                                         |
| ------------------------------ | -------------------------------------------------------------- |
| <kbd>↑</kbd> <kbd>↓</kbd>      | Choose a process                                               |
| <kbd>Enter</kbd>               | Show the details of the chosen process                         |
| <kbd>f</kbd> or <kbd>/</kbd>   | Show only the processes that match a text (filter)             |
| <kbd>e</kbd>                   | Show the processes as a tree                                   |
| <kbd>←</kbd> <kbd>→</kbd>      | Choose the column to sort by                                   |
| <kbd>r</kbd>                   | Reverse the sorting order                                      |
| <kbd>1</kbd> ... <kbd>4</kbd>  | Show or hide the boxes: processors, memory, network, processes |
| <kbd>Esc</kbd> or <kbd>m</kbd> | Menu                                                           |
| <kbd>h</kbd> or <kbd>F1</kbd>  | Help                                                           |
| <kbd>q</kbd>                   | Quit                                                           |

## Troubleshooting

| Problem                                                     | Solution                                                                                                                                                                                              |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bash: <command>: command not found`                        | The program is not installed: install it with `sudo dnf install <package>` on Fedora, or with `sudo apt install <package>` on Debian and Ubuntu; the package usually has the same name as the command |
| The error still shows on the display after `>`              | Errors go to `2`: use `2>` or `&>`                                                                                                                                                                    |
| A file is empty after a redirect                            | `>` empties the file first: use `>>` to append                                                                                                                                                        |
| A command waits and does nothing                            | It reads from the keyboard: type the input and press <kbd>Ctrl</kbd>+<kbd>D</kbd>, or stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd>                                                                       |
| `gzip: numbers.txt.gz already exists`                       | The compressed file is already there: delete it, or add `-f` to overwrite it                                                                                                                          |
| The original file disappeared after `gzip`                  | Normal: use `-k` to keep it, or decompress it with `gunzip`                                                                                                                                           |
| `tar: Cowardly refusing to create an empty archive`         | The name of the archive after `f` is missing                                                                                                                                                          |
| `tar: ...: Not found in archive`                            | The name is wrong: list the archive with `tar tf` and copy the name exactly                                                                                                                           |
| `tar: /tmp/extract: Cannot open: No such file or directory` | The directory given to `-C` must exist: create it with `mkdir`                                                                                                                                        |
| A `zip` archive has a directory, but not its files          | Add `-r`                                                                                                                                                                                              |
| `No such file or directory` in `/proc/<PID>`                | The process has finished, or the PID is wrong: check it with `pgrep` or `ps`                                                                                                                          |
| `Permission denied` in `/proc/<PID>`                        | The process belongs to another user                                                                                                                                                                   |

## Exercises

The exercises get harder as you go:

- 🧪 [First Steps](#first-steps) (exercises 1 - 32) goes once through **everything** in this lab, with easy exercises;
- 🏠 [Going Further](#going-further) (exercises 33 - 47) has harder exercises;
- 📝 [Challenges](#challenges) (exercises 48 - 54) has the hardest ones.

Every exercise needs only the **practice tree** from exercise 1, and creates by itself all the other files it uses.
Run the commands in `~/lab03`, unless the exercise says otherwise. If you change or delete a file of the practice
tree, run the commands from exercise 1 again to get it back.

Some exercises ask for things that the lab does not show you, for example an option that is not in the tables
above. Find it in the **manual page** of the command (`man <command>`), as explained in
[Searching in a Manual Page](/docs/labs/02#searching-in-a-manual-page) in lab 02.

Many exercises use the **files of the system**, from `/etc`, `/usr`, `/var`, `/proc` and `/dev`, so that you also get to
know how a Linux system is organized. To find out what a directory is for, look in `man hier`; to find out what a file
in `/etc` contains, look in section 5 of the manual, for example `man 5 passwd`, `man 5 shells` or `man 5 os-release`.

Keep **two terminals side by side** in Sway: the first one to run the commands, and the second one to run the commands
that you inspect, or to check the results. Many exercises use the PID of a process: it is different on your computer,
use the one that `pgrep` or `ps` prints for you.

:::danger

Do not use `sudo` to look at processes. The files in `/proc` are made by the kernel: read them, but do not try to
change them.

:::

### 🧪 First Steps {/* #first-steps */}

1. **The practice tree**:
   1. run these commands to create the files used in the exercises (copy them from the browser with
      <kbd>Ctrl</kbd>+<kbd>C</kbd> and paste them in the terminal with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>):

      ```bash
      mkdir -p ~/lab03/Music ~/lab03/Photos ~/lab03/Reports ~/lab03/Archives
      touch ~/lab03/Music/jazz.mp3 ~/lab03/Music/rock.mp3 ~/lab03/Music/pop.mp3
      touch ~/lab03/Photos/cat.jpg ~/lab03/Photos/dog.jpg
      printf 'banana\napple\ncherry\napple\nkiwi\nbanana\napple\n' > ~/lab03/fruits.txt
      seq 1 20000 > ~/lab03/numbers.txt
      ```

   2. go to `~/lab03` and run `tree`;
   3. count the lines of `fruits.txt` and `numbers.txt` with `wc -l`.

   **Check:** you see the four directories, the five empty files, `fruits.txt` and `numbers.txt`; `wc -l` prints `7`
   and `20000`. <small>→ [Navigation](/docs/labs/02#navigation)</small>

**Redirects**

2. **The root of the system**:
   1. save the tree of `/`, only one level deep, into `Reports/system.txt` (look in `man tree` for the option that
      limits how deep `tree` goes);
   2. print `Reports/system.txt` with `cat`.

   **Check:** `tree` printed nothing on the display, and the file shows the main directories of the system: `boot`,
   `dev`, `etc`, `home`, `proc`, `tmp`, `usr` and `var`; `bin` is a link to `usr/bin`. <small>→ [Output](#output--and-)</small>

3. **Append and overwrite**:
   1. save the tree of `/usr`, one level deep, into `Reports/tree.txt`;
   2. **append** the tree of `/var`, one level deep, to `Reports/tree.txt`, and print the file;
   3. **overwrite** `Reports/tree.txt` with the tree of `/home`, one level deep, and print the file again.

   **Check:** after the append, the file has both trees: `/usr` with `bin`, `lib` and `share`, then `/var` with
   `cache`, `lib` and `log`; after the overwrite, it has only the tree of `/home`, with `student`. <small>→ [Output](#output--and-)</small>

4. **Errors apart**:
   1. with a **single** `ls -a` command, list `/etc/skel` (the files copied into the home directory of every new user)
      and `/root` (the home directory of the administrator), so that the list goes into `Reports/list.txt` and the
      error into `Reports/errors.txt`;
   2. print the two files.

   **Check:** nothing appears on the display when you run `ls`; `Reports/list.txt` has `.bashrc` and `.bash_profile`,
   and `Reports/errors.txt` has a `Permission denied` for `/root`. <small>→ [Errors](#errors-2-and-2)</small>

5. **Append errors**:
   1. run `ls /root` and save its error into `Reports/errors.txt`, overwriting the file;
   2. print `/etc/shadow` (the file with the passwords of the users) with `cat`, and **append** its error to
      `Reports/errors.txt`;
   3. print `Reports/errors.txt`.

   **Check:** `Reports/errors.txt` has two lines, one for `/root` and one for `/etc/shadow`: only `root` can read
   them. <small>→ [Errors](#errors-2-and-2)</small>

6. **The users and the groups**:
   1. copy `/etc/passwd` (the list of the users) into `Reports/users.txt`, using `cat` and a redirect, not `cp`;
   2. copy `/etc/group` (the list of the groups) into `Reports/groups.txt` in the same way;
   3. count the lines of the two copies and of the two originals with `wc -l`.

   **Check:** every copy has the same number of lines as its original. <small>→ [Output](#output--and-)</small>

7. **Everything in one file**:
   1. run `ls -a /etc/skel /root` so that both the list and the error go into `Reports/all.txt`, using `&>`, and print
      the file;
   2. run the same command again, this time with the older way, `> Reports/all.txt 2>&1` (see the
      [table of redirects](#redirects)), and print the file again.

   **Check:** both times, `Reports/all.txt` has the error for `/root` and the files of `/etc/skel`, and nothing
   appears on the display when you run `ls`. <small>→ [Redirects](#redirects)</small>

8. **Silence**:
   1. search `/etc` and `/usr` for files called `os-release` with `find`, and throw the errors away so that you do not
      see any `Permission denied` message;
   2. print the content of `/etc/os-release` (the file that describes your distribution) with `cat`.

   **Check:** `find` prints only two paths, `/etc/os-release` and `/usr/lib/os-release`; `/etc/os-release` has the
   name and the version of your distribution, `Fedora Linux`. <small>→ [Special Files](#special-files)</small>

9. **Input from a file**:
   1. sort `/etc/shells` (the list of the shells installed in the system) with `sort`, giving it the file with `<`;
   2. count the lines of `/etc/passwd` with `wc -l`, giving it the name of the file as a parameter;
   3. count them again, this time giving the file with `<`.

   **Check:** the shells in `/bin` come before the ones in `/usr/bin`; both counts are the same, but only the first
   `wc` prints the name of the file. <small>→ [Input](#input-)</small>

10. **Type a file**:
    1. run `cat` with a redirect, so that what you type goes into `Reports/todo.txt`;
    2. type three lines, then press <kbd>Ctrl</kbd>+<kbd>D</kbd> at the beginning of a new line to end the input;
    3. print `Reports/todo.txt`.

    **Check:** `cat Reports/todo.txt` prints the three lines you typed. <small>→ [Input](#input-)</small>

11. **Pipes**:
    1. count the programs in `/usr/bin` with `ls`, `wc -l` and a pipe;
    2. count the entries in `/etc` (the configuration of the system) in the same way;
    3. show the long list of `/etc` (`ls -l`) one screen at a time, with `less`.

    **Check:** there are more than a thousand programs and a few hundred entries in `/etc`; `less` stops after every
    screen, and you quit it with <kbd>q</kbd>. <small>→ [Pipes](#pipes-)</small>

12. **Search with grep**:
    1. show the line of your user, `student`, from `/etc/passwd` (the list of the users);
    2. count the lines of `/etc/passwd` that contain `nologin`: these are the users of the services, which cannot log
       in;
    3. list the programs in `/usr/bin` whose name contains `zip`.

    **Check:** your line ends with `/home/student:/bin/bash`; most of the users have `nologin`; the list of programs
    has `gzip` and `gunzip`. <small>→ [Searching for a Text](#searching-for-a-text-grep)</small>

13. **Repeated lines**:
    1. run `uniq fruits.txt` and find out why it does not remove anything;
    2. print every fruit from `fruits.txt` only once;
    3. print every fruit with the number of times it appears, the most frequent first;
    4. print only the fruits that appear exactly once (look in `man uniq`).

    **Check:** `uniq fruits.txt` prints the same 7 lines, because no line is the same as the one above it; after
    `sort`, you get 4 fruits, `3 apple` is the first line of the count, and only `cherry` and `kiwi` appear exactly
    once. <small>→ [Repeated Lines](#repeated-lines-uniq)</small>

14. **Zeros and random bytes**:
    1. show the first 16 bytes of `/dev/zero` in hexadecimal, with `head` and `xxd`;
    2. show the first 16 bytes of `/dev/urandom` in the same way, and run the command twice.

    **Check:** the bytes of `/dev/zero` are all zeros; the bytes of `/dev/urandom` are different every time you run the
    command. <small>→ [Special Files](#special-files)</small>

**Processes**

15. **My shell**:
    1. print the PID of your shell;
    2. list the processes of the terminal with all the columns of `-f`;
    3. show only the `Name`, `State`, `Pid` and `PPid` lines of the `/proc/<PID>/status` file of your shell, using
       `grep` (put the PID of your shell instead of `<PID>`).

    **Check:** `ps` and `status` show the same PID and PPID for `bash`, and its state is `S`. <small>→ [Listing Processes](#listing-processes-ps) · [The `/proc` File System](#the-proc-file-system)</small>

16. **Inspect a process**:
    1. in the second terminal, run `sleep 1000`;
    2. in the first terminal, find the PID of `sleep` with `pgrep`;
    3. print its `/proc/<PID>/status` file;
    4. print its command line, from `/proc/<PID>/cmdline`, with `cat -v`;
    5. find out its program and its current directory, from the links `/proc/<PID>/exe` and `/proc/<PID>/cwd`;
    6. stop `sleep` with <kbd>Ctrl</kbd>+<kbd>C</kbd> in the second terminal.

    **Check:** the state is `S`, the command line is `sleep^@1000^@`, the program is `/usr/bin/sleep`, and the current directory
    is the one of the second terminal. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

17. **Open files**:
    1. list the File Descriptor Table of your shell, from `/proc/$$/fd`;
    2. in the second terminal, run `sleep 1000`;
    3. in the first terminal, find the PID of `sleep` and list its File Descriptor Table;
    4. stop `sleep` with <kbd>Ctrl</kbd>+<kbd>C</kbd> and try to list its table again.

    **Check:** `0`, `1` and `2` point to a `/dev/pts/...` file, a different one for each terminal; after
    <kbd>Ctrl</kbd>+<kbd>C</kbd>, `/proc/<PID>` no longer exists. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

18. **The system**: Find out about your computer using only the files in `/proc`:
    1. the model of the processor: the `model name` lines of `/proc/cpuinfo` (use `grep`);
    2. how many processors you have: count the `processor` lines of `/proc/cpuinfo`;
    3. the total memory: the `MemTotal` line of `/proc/meminfo`;
    4. for how many seconds the system has been running: the first number in `/proc/uptime`;
    5. the version of the kernel: `/proc/version`.

    **Check:** the number of processors is the same as the one printed by `nproc`, the time matches the `up` part of
    `uptime`, and the version of the kernel is the same as `uname -r`. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

19. **top and htop**:
    1. start `top`, sort the processes by memory, then by processor, and quit;
    2. start `htop`, find your `bash` with a search, show the processes as a tree, and quit.

    **Check:** `top` shows the `Tasks` line with the number of processes in every state; in the tree of `htop`, your
    `bash` is under the terminal. <small>→ [top](#top) · [htop](#htop)</small>

**Archives and compression**

20. **Three compressors**:
    1. delete `numbers.txt.gz`, `numbers.txt.bz2` and `numbers.txt.xz`, if they exist;
    2. compress `numbers.txt` with `gzip`, with `bzip2` and with `xz`, keeping the original file every time;
    3. compare the sizes of the four files with `ls -l`.

    **Check:** you have `numbers.txt`, `numbers.txt.gz`, `numbers.txt.bz2` and `numbers.txt.xz`, and the `.xz` file is
    the smallest. <small>→ [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>

21. **How much smaller**:
    1. delete `numbers.txt.gz`, `numbers.txt.bz2` and `numbers.txt.xz`, if they exist;
    2. compress `numbers.txt` with `gzip`, with `bzip2` and with `xz`, keeping the original file, so that each of them
       prints **how much** smaller the file got (look in their manual pages for the option that prints more details).

    **Check:** `gzip` and `bzip2` printed how much they **saved**, as a percentage, and the one of `bzip2` is larger;
    `xz` printed a **ratio** instead (about `0.045`, the new size divided by the old one), so it saved about 95%, the
    most of the three. <small>→ [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>

22. **Decompress**:
    1. delete `numbers.txt.gz` and `numbers.txt.bz2`, if they exist;
    2. compress `numbers.txt` with `gzip`, **without** keeping the original, and check with `ls` that `numbers.txt` is
       gone;
    3. get `numbers.txt` back from `numbers.txt.gz`;
    4. compress `numbers.txt` with `bzip2`, keeping the original, then delete `numbers.txt`;
    5. get `numbers.txt` back from `numbers.txt.bz2`, this time keeping the compressed file.

    **Check:** `wc -l numbers.txt` prints `20000` both times; `numbers.txt.gz` is gone (`gunzip` deleted it, like
    `gzip` deletes the original), but `numbers.txt.bz2` still exists. <small>→ [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>

23. **What kind of file**:
    1. delete `numbers.txt.bz2` and `numbers.txt.xz`, if they exist;
    2. compress `numbers.txt` with `bzip2` and with `xz`, keeping the original;
    3. find out the types of `numbers.txt`, `numbers.txt.bz2` and `numbers.txt.xz`, with a **single** `file` command;
    4. delete `numbers.txt.bz2` and `numbers.txt.xz`;
    5. find out the type of `/usr/share/man/man1/ls.1.gz`, the manual page of `ls`.

    **Check:** `file` says `ASCII text`, `bzip2 compressed data` and `XZ compressed data`, and `gzip compressed data`
    for `ls.1.gz`: the manual pages are stored compressed with `gzip`, and `man` decompresses them when you read
    them. <small>→ [Which One to Use](#which-one-to-use)</small>

24. **A tar archive**:
    1. create `Archives/music.tar` with the directories `Music` and `Photos` and the file `fruits.txt`;
    2. list the content of the archive;
    3. find out the type of the archive with `file`.

    **Check:** the archive has `Music/`, `Photos/`, the five empty files and `fruits.txt`, and `file` says
    `POSIX tar archive`. <small>→ [Archives](#archives-tar)</small>

25. **Extract**:
    1. create `Archives/music.tar` with `Music`, `Photos` and `fruits.txt` (if it already exists, `tar` overwrites it);
    2. create the directory `/tmp/extract`;
    3. extract `Archives/music.tar` into `/tmp/extract`.

    **Check:** `tree /tmp/extract` shows `Music`, `Photos` and `fruits.txt`, with the same files as in `~/lab03`. <small>→ [Archives](#archives-tar)</small>

26. **Only one file**:
    1. create `Archives/music.tar` with `Music`, `Photos` and `fruits.txt`;
    2. create the directory `/tmp/single`;
    3. extract only `Photos/dog.jpg` from `Archives/music.tar` into `/tmp/single`.

    **Check:** `tree /tmp/single` shows `Photos/dog.jpg`, and nothing else. <small>→ [Archives](#archives-tar)</small>

27. **Add a file**:
    1. create `Archives/music.tar` with `Music`, `Photos` and `fruits.txt`;
    2. add `numbers.txt` to `Archives/music.tar`, without creating the archive again;
    3. list the archive with the details of every file.

    **Check:** `numbers.txt` is the last file in the list, with the size `108894`. <small>→ [Archives](#archives-tar)</small>

28. **Compressed archives**:
    1. create `Archives/all.tar` with `Music`, `Photos` and `numbers.txt`;
    2. create `Archives/all.tar.gz`, `Archives/all.tar.bz2` and `Archives/all.tar.xz`, each with the same three
       entries, compressed with `gzip`, `bzip2` and `xz`;
    3. compare the sizes of the four archives with `ls -l`.

    **Check:** the `.tar` is the largest and the `.tar.xz` the smallest. <small>→ [Compressed Archives](#compressed-archives-targz-tarbz2-and-tarxz)</small>

29. **List compressed archives**:
    1. create `Archives/all.tar.gz`, `Archives/all.tar.bz2` and `Archives/all.tar.xz`, each with `Music`, `Photos` and
       `numbers.txt`;
    2. list the content of each archive, **without** telling `tar` how it is compressed;
    3. find out the types of the three archives with `file`.

    **Check:** all three lists are the same; `file` shows a different compression for each of them. <small>→ [Compressed Archives](#compressed-archives-targz-tarbz2-and-tarxz)</small>

30. **Extract compressed archives**:
    1. create `Archives/all.tar.gz`, `Archives/all.tar.bz2` and `Archives/all.tar.xz`, each with `Music`, `Photos` and
       `numbers.txt`;
    2. create the directories `/tmp/gz`, `/tmp/bz2` and `/tmp/xz`;
    3. extract each archive into its own directory: the `.tar.gz` into `/tmp/gz`, the `.tar.bz2` into `/tmp/bz2` and
       the `.tar.xz` into `/tmp/xz`;
    4. show the three directories with `tree`.

    **Check:** the trees of the three directories are the same. <small>→ [Compressed Archives](#compressed-archives-targz-tarbz2-and-tarxz)</small>

31. **A zip archive**:
    1. delete `Archives/all.zip`, if it exists (`zip` would update it, not create it again);
    2. create `Archives/all.zip` with `Music`, `Photos` and `numbers.txt`, with everything inside the directories;
    3. list the content of the archive;
    4. extract it into `/tmp/unzipped`.

    **Check:** `unzip -l` lists 8 entries, and `tree /tmp/unzipped` shows `Music` with three files, `Photos` with two
    files, and `numbers.txt`. <small>→ [Zip Archives](#zip-archives-zip-and-unzip)</small>

32. **Update a zip archive**:
    1. delete `Archives/all.zip`, if it exists;
    2. create `Archives/all.zip` with `Music`, `Photos` and `numbers.txt`, with everything inside the directories;
    3. add `fruits.txt` to `Archives/all.zip`;
    4. list the files in the archive with `zip -sf`;
    5. extract only `fruits.txt` from the archive into `/tmp/fruit`.

    **Check:** `zip -sf Archives/all.zip` lists `fruits.txt` as the last file, and `/tmp/fruit` has only `fruits.txt`. <small>→ [Zip Archives](#zip-archives-zip-and-unzip)</small>

### 🏠 Going Further {/* #going-further */}

33. **Order matters**:
    1. run `ls /etc/skel /root > Reports/a.txt 2>&1` and print `Reports/a.txt`;
    2. run `ls /etc/skel /root 2>&1 > Reports/b.txt` and print `Reports/b.txt`;
    3. find out why the error is in `a.txt`, but not in `b.txt`.

    **Check:** the second command printed the error on the display. The shell reads the redirects from left to right,
    and `2>&1` makes `2` go where `1` goes **at that moment**. <small>→ [Redirects](#redirects)</small>

34. **See and save**: In a **single** command line, save the list of the programs in `/usr/bin` into
    `Reports/programs.txt` **and** count them (look in `man tee` for the command that writes its input both to a file
    and to its output).

    **Check:** the number printed is the same as `wc -l < Reports/programs.txt`. <small>→ [Pipes](#pipes-)</small>

35. **Redirects seen from inside**:
    1. in the second terminal, run `sleep 900 < ~/lab03/fruits.txt > /tmp/out.txt 2> /dev/null`;
    2. in the first terminal, find the PID of `sleep` and list its File Descriptor Table;
    3. stop `sleep` with <kbd>Ctrl</kbd>+<kbd>C</kbd> in the second terminal.

    **Check:** `0` points to `fruits.txt`, `1` to `/tmp/out.txt` and `2` to `/dev/null`: the shell changed the table
    before `sleep` started. <small>→ [The `/proc` File System](#the-proc-file-system) · [Redirects](#redirects)</small>

36. **A pipe seen from inside**:
    1. in the second terminal, run `sleep 800 | sleep 900`;
    2. in the first terminal, find the PIDs of the two `sleep` processes (look in `man pgrep` for the option that also
       prints the command line, so you can tell them apart);
    3. list the File Descriptor Tables of both processes;
    4. stop them with <kbd>Ctrl</kbd>+<kbd>C</kbd> in the second terminal.

    **Check:** `1` of `sleep 800` and `0` of `sleep 900` point to the same `pipe:[...]`, with the same number. <small>→ [The `/proc` File System](#the-proc-file-system) · [Pipes](#pipes-)</small>

37. **What does less read**:
    1. in the second terminal, open `/etc/services` (the list of the network services and their ports) with `less`;
    2. in the first terminal, find the PID of `less`;
    3. list the files that `less` has open, and print its command line and its current directory, using `/proc`;
    4. quit `less` with <kbd>q</kbd>.

    **Check:** besides `0`, `1` and `2`, `less` has `/etc/services` open, at file descriptor `3` or higher. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

38. **Where is the other shell**:
    1. in the second terminal, go to `~/lab03/Music` and print the PID of the shell;
    2. in the first terminal, find the current directory of that shell, using `/proc`;
    3. open its `environ` file with `less` and find the value of the `HOME` variable (the `\0` bytes between the
       variables show up as `^@`; search with <kbd>/</kbd>).

    **Check:** `cwd` points to `/home/student/lab03/Music`, and `environ` has `HOME=/home/student`. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

39. **Save top**:
    1. run `top` so that it prints its list only **once** and does not update it (see the tip in [top](#top));
    2. keep only the first 15 lines of its output, and save them into `Reports/top.txt`, in the same command line.

    **Check:** `Reports/top.txt` has 15 lines, starting with the summary of `top`. <small>→ [top](#top) · [Pipes](#pipes-)</small>

40. **htop in depth**: In `htop`:
    1. hide the threads;
    2. show only your processes;
    3. sort them by memory;
    4. choose your `bash` and show its open files;
    5. add the `PPID` column, from the setup menu (<kbd>F2</kbd>).

    **Check:** the open files of `bash` are the same as in `ls -l /proc/$$/fd`, and the `PPID` of `bash` is the PID of
    the terminal. <small>→ [htop](#htop)</small>

41. **Whose processes**:
    1. count the processes of `root` with `ps`, `wc -l` and a pipe (look in `man ps` for the option that selects the
       processes of a user, and use `--no-headers`, so that `wc -l` does not also count the line with the names of the
       columns);
    2. count your own processes in the same way;
    3. count them again, without `--no-headers`.

    **Check:** `root` has many more processes than `student`: most of the system runs as `root`. Without
    `--no-headers`, each number is larger by one. <small>→ [Listing Processes](#listing-processes-ps) · [Pipes](#pipes-)</small>

42. **Who runs the processes**:
    1. list all the processes of the system with `ps`, printing only the column of the user, without the header line;
    2. in the same command line, using `sort` and `uniq`, print every user only once, with the number of its processes
       in front of it, the user with the most processes first.

    **Check:** the first line is `root`, with the same number as `ps -u root --no-headers | wc -l`, and `student` is
    among the first lines; the numbers added up are the same as `ps -e --no-headers | wc -l`. <small>→ [Listing Processes](#listing-processes-ps) · [Repeated Lines](#repeated-lines-uniq)</small>

43. **Big files**:
    1. create `Archives/zeros.bin` with the first 10 MB of `/dev/zero`, using `head` (look in `man head` for the option
       that prints a number of bytes instead of lines);
    2. create `Archives/random.bin` with the first 10 MB of `/dev/urandom`, in the same way;
    3. compress both files with `xz`, keeping the originals;
    4. compare the sizes of the four files with `ls -lh`;
    5. delete the four files: they are big.

    **Check:** `zeros.bin.xz` is a few KB, `random.bin.xz` is still about 10 MB: random data cannot be compressed. <small>→ [Special Files](#special-files) · [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>

44. **Compress into another file**: Compress `/etc/services` (the list of the network services) without copying it
    and without changing `/etc`: use the option `-c`, which writes the compressed data to the standard output, and a
    redirect.
    1. compress it with `gzip` into `Archives/services.gz`;
    2. compress it with `bzip2` into `Archives/services.bz2`;
    3. compress it with `xz` into `Archives/services.xz`;
    4. put `time` in front of each of the three commands, and compare the times and the sizes of the files.

    **Check:** the three files exist, `/etc/services` is unchanged, `xz` makes the smallest file and takes the longest. <small>→ [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>

45. **Read without extracting**: Look in `man gzip` and `man xz` for the commands that print the content of a
    compressed file, without creating any new file.
    1. compress `/etc/services` with `gzip -c` into `Archives/services.gz`, and with `xz -c` into
       `Archives/services.xz`;
    2. print the content of `Archives/services.gz`;
    3. count the lines of `Archives/services.xz`;
    4. print the first 20 lines of the compressed manual page `/usr/share/man/man1/ls.1.gz`.

    **Check:** the count is the same as `wc -l < /etc/services`; the manual page is a text file with formatting
    commands, lines that start with `.`, like `.TH` and `.SH`. <small>→ [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>

46. **Compression from the name**:
    1. create `Archives/photos.tar.bz2` with `Photos`, without telling `tar` the compressor: let it choose the
       compressor from the extension of the archive (look in `man tar` for this option);
    2. find out the type of the archive with `file`.

    **Check:** `file Archives/photos.tar.bz2` says `bzip2 compressed data`. <small>→ [Compressed Archives](#compressed-archives-targz-tarbz2-and-tarxz)</small>

47. **Without the full path**:
    1. create `/tmp/doc.tar.gz` with the directory `/usr/share/doc/bash` (the documentation of `bash`), so that the names
       in the archive start with `bash/` and not with `usr/share/doc/` (look in `man tar` for the option that changes the
       directory before adding the files);
    2. list the content of the archive.

    **Check:** `tar tf /tmp/doc.tar.gz` lists names that start with `bash/`. <small>→ [Archives](#archives-tar)</small>

### 📝 Challenges {/* #challenges */}

48. **Count with /proc**:
    1. count the directories in `/proc` whose name is a number;
    2. count the processes of the system with `ps -e --no-headers` and `wc -l`;
    3. compare the two numbers.

    **Check:** the two numbers are almost the same: every process is a directory in `/proc`. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

49. **The shells of the users**: Every line of `/etc/passwd` has 7 fields separated by `:`, and the last one is the
    shell of the user.
    1. print only the shell of every user (look in `man cut` for the options that choose the separator and keep only
       one field of every line);
    2. in the same command line, print every shell only once, with the number of users that have it, the most used
       first;
    3. print only the shells that are used by more than one user.

    **Check:** `/usr/sbin/nologin` is the first line, with most of the users; `/sbin/nologin` is the same program
    (`/sbin` is a link to `usr/sbin`), but `uniq` compares only the text, so it counts it on its own line; `/bin/bash`
    is used by `root` and `student`; the numbers added up are the same as `wc -l < /etc/passwd`. <small>→ [Repeated Lines](#repeated-lines-uniq) · [Pipes](#pipes-)</small>

50. **Who has the file open**:
    1. in the second terminal, open `/etc/hosts` (the names of the computers that the system knows without asking the
       network) with `less`;
    2. in the first terminal, find the file descriptor that points to `/etc/hosts`, **without** using `pgrep` or `ps`:
       search `/proc/*/fd` with `find` (look in `man find` for the test that checks where a symbolic link points to),
       and throw away the `Permission denied` errors for the processes of other users;
    3. check with `ps -p` that the number in the path that `find` prints is the PID of `less`;
    4. quit `less` with <kbd>q</kbd>.

    **Check:** `find` prints a path like `/proc/3402/fd/4`, and `ps -p 3402` shows `less`. <small>→ [The `/proc` File System](#the-proc-file-system)</small>

51. **Back up the configuration**:
    1. create `/tmp/etc.tar.gz` with the whole `/etc` directory (the configuration of the system), **except**
       `/etc/pki` (the certificates), and save the errors of `tar` into `Reports/etc-errors.txt` (look in `man tar` for
       the option that leaves files out of the archive);
    2. count the files in the archive;
    3. count the errors in `Reports/etc-errors.txt`.

    **Check:** `tar tf /tmp/etc.tar.gz` lists `etc/passwd` and `etc/os-release`, but nothing from `etc/pki`;
    `Reports/etc-errors.txt` has a `Permission denied` for every file that only `root` can read, like `/etc/shadow`.
    Its first line is ``tar: Removing leading `/' from member names``: this is not an error, `tar` only tells you
    that it saves `/etc/passwd` as `etc/passwd`, so that the archive can be extracted anywhere, not only over `/etc`.
    Do not count it with the errors. <small>→ [Compressed Archives](#compressed-archives-targz-tarbz2-and-tarxz)</small>

52. **Strip a directory**:
    1. create `Archives/all.tar.gz` with `Music`, `Photos` and `numbers.txt`;
    2. create the directory `/tmp/flat`;
    3. extract `Archives/all.tar.gz` into `/tmp/flat` so that the files of `Music` and `Photos` end up directly in
       `/tmp/flat`, without their directories (look in `man tar` for the option that removes directories from the
       beginning of the names).

    **Check:** `tree /tmp/flat` shows the five empty files directly under `/tmp/flat`, but **not** `numbers.txt`.
    `--strip-components=1` removes the first part of every name: `Music/jazz.mp3` becomes `jazz.mp3`, but
    `numbers.txt` is in the top directory of the archive, so nothing is left of its name, and `tar` does not extract
    it (the same happens to the names `Music/` and `Photos/`). <small>→ [Archives](#archives-tar)</small>

53. **Archives through a pipe**:
    1. create `/tmp/music.tar.gz` with the directory `Music`, in a single command line: `tar` writes the archive, **not
       compressed**, to its standard output (an archive file named `-` means the standard output), `gzip` compresses it
       in a pipe, and a redirect saves it;
    2. create the directory `/tmp/piped`;
    3. extract `/tmp/music.tar.gz` into `/tmp/piped` in another pipe: `gunzip -c` decompresses it to its standard
       output, and `tar` reads the archive from its standard input (an archive file named `-` means the standard input).

    **Check:** `file /tmp/music.tar.gz` says `gzip compressed data`, and `tree /tmp/piped` shows `Music`. <small>→ [Pipes](#pipes-) · [Compressed Archives](#compressed-archives-targz-tarbz2-and-tarxz)</small>

54. **Clean up**: With a **single** `rm` command, delete everything that the exercises create in `/tmp`, without any
    error for the ones you did not create (look in `man rm`):
    1. the directories `/tmp/extract`, `/tmp/single`, `/tmp/gz`, `/tmp/bz2`, `/tmp/xz`, `/tmp/unzipped`, `/tmp/fruit`,
       `/tmp/flat` and `/tmp/piped`;
    2. the files `/tmp/out.txt`, `/tmp/doc.tar.gz`, `/tmp/etc.tar.gz` and `/tmp/music.tar.gz`.

    **Check:** `rm` prints nothing, and `ls /tmp` no longer shows them. <small>→ [Managing Files](/docs/labs/02#managing-files)</small>

## Wrap-up Questions

Use the **last 5 minutes** of the lab to answer these questions together with your colleagues and the teaching
assistant. There are no wrong answers for the last two.

1. What are the file descriptors `0`, `1` and `2`, and where do they point to in a terminal?
2. What is the difference between `>` and `>>`? And between `>` and `2>`?
3. Why does `wc -l < file` not print the name of the file?
4. What is the difference between an **archive** and a **compressed** file? Why does a `.tar.gz` have two extensions?
5. When would you use `.tar.xz`, and when `.zip`?
6. What is the difference between a **program** and a **process**? What are the **PID** and the **PPID**?
7. Where are the files in `/proc` stored?
8. What can you find out about a process from `/proc` that `ps` does not show?
9. When would you use `top`, and when `htop` or `btop`?
10. Which redirect or archive format will you use most often?

## Extra

1. **The memory of a process**: Print `/proc/$$/maps` with `less`. Find the lines of `/usr/bin/bash` and of `libc.so.6`:
   this is how the loader placed the program and its libraries in memory. <small>→ [The `/proc` File System](#the-proc-file-system)</small>
2. **Zstandard**: Fedora also has `zstd`, a newer compressor. Compress `numbers.txt` with it and compare the size and the
   time with `gzip` and `xz`; then create a `.tar.zst` archive (look in `man tar` for the option that compresses the archive with `zstd`). <small>→ [Compressing One File](#compressing-one-file-gzip-bzip2-and-xz)</small>
3. **Archive managers**: Open an archive with `yazi` (lab 02): it shows the content of `.tar.gz` and `.zip` archives as a preview. <small>→ [Yazi](/docs/labs/02#yazi)</small>
4. **htop settings**: Press <kbd>F2</kbd> in `htop` and change the meters at the top of the screen. <small>→ [htop](#htop)</small>
