import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# 06. Text Processing

In the fifth lab you learned which user runs every program, and who may read and write every file. In this lab you
will work with what is **inside** most of these files: **text**. You will meet the **filters**, small commands that
read lines and write lines: `cat`, `head`, `tail` and `sort` work with whole lines, `grep` finds the lines that match a
**regular expression**, `cut`, `tr` and `sed` change the inside of every line, and `wc` and `awk` count and compute.
You will join them into **pipelines** that answer a question in one line, find out if a command worked from its
**exit code**, and chain commands with `&&` and `||`. At the end, you will meet the three kinds of
terminal editors, `nano`, `vim` and Emacs, and start learning one of them.

The most important idea of this lab is that text is the **common language** of the commands. Every filter reads lines
of text, does **one** small thing with them, and writes lines of text, so the output of any filter can be the input of
any other one. Pipes join filters into a **pipeline**: each command hands its text to the next one, a step closer to
the answer, and the last one prints it. Besides its text, every command also gives back a number, its **exit code**,
which tells the shell if it worked.

## Objectives

- Understand what a **filter** is, and build a **pipeline** of filters that answers a question
- Show, reverse and cut out lines with `cat`, `tac`, `head` and `tail`
- Sort lines with `sort`, as text, as numbers and by a field, and count the repeated lines with `uniq`
- Write **regular expressions**, basic and extended, and search with them with `grep`
- Cut **fields** and characters out of every line with `cut`, and reverse or number the lines with `rev` and `nl`
- Change, delete and squeeze characters with `tr`, and replace text with `sed`
- Count lines, words and characters with `wc`, and compute sums and averages with `awk`
- Find out if a command worked from its **exit code**, and chain commands with `&&` and `||`
- Edit a text file in the terminal with `nano` and with `vim`, start learning `vim`, `nvim`, `hx` or `emacs`, and choose
  the editor that other programs open with `EDITOR`

## Resources

1. _[Razvan Deaconescu, Razvan Rughinis, Mihai Carabas, Alexandru Radovici, Utilizarea Sistemelor de
   Operare, Printech 2021](https://github.com/systems-cs-pub-ro/carte-uso/releases/download/uso-ed1-2021/uso.pdf)_
   - Chapter 4 - _Procese_, sections 4.5.3 and 4.5.4
   - Chapter 6 - _Dezvoltarea aplicațiilor_, sections 6.6.1 and 6.6.2
   - Chapter 7 - _Interfața în linia de comandă_, sections 7.4 and 7.5
   - Chapter 13 - _Automatizarea sarcinilor_, section 13.3.2
2. _Brian Ward, How LINUX Works, 3rd Edition, No Starch Press, 2021_
   - Chapter 2 - _Basic Commands and Directory Hierarchy_, sections 2.2.2, 2.5 and 2.14
   - Chapter 11 - _Introduction to Shell Scripts_, sections 11.4 and 11.5
3. _[The GNU Awk User's Guide](https://www.gnu.org/software/gawk/manual/gawk.html)_ and `vimtutor`, the 30 minutes
   tutorial of `vim`
4. The lecture slides: [06. Text Processing](/docs/lectures/06)
5. The manual pages: `man cat`, `man tac`, `man head`, `man tail`, `man sort`, `man uniq`, `man grep`, `man 7 regex`,
   `man cut`, `man tr`, `man sed`, `man rev`, `man nl`, `man wc`, `man awk`, `man column`, `man jq`, `man nano`,
   `man vim` and `man bash` (search for `Pipelines`, `Lists` and `edit-and-execute-command`)

## Fedora and Ubuntu

The lab computers run **Fedora** with **Sway**, and the examples come from them. At home you may also use **Ubuntu**:
the commands of this lab are the same, with a few differences:

|                          | Fedora                                      | Ubuntu                                                 |
| ------------------------ | ------------------------------------------- | ------------------------------------------------------ |
| the prompt               | `[student@fedora ~]$`                       | `student@ubuntu:~$`                                    |
| the program behind `awk` | GNU `awk` (`gawk`)                          | `mawk`, a smaller `awk`: this lab works the same on it |
| `vim` and `vimtutor`     | if missing: `sudo dnf install vim-enhanced` | if missing: `sudo apt install vim`                     |
| install Helix (`hx`)     | `sudo dnf install helix`                    | `sudo snap install --classic helix`                    |
| install `jq`             | `sudo dnf install jq`                       | `sudo apt install jq`                                  |
| `EDITOR`                 | `/usr/bin/nano`                             | not set: each program picks its own editor             |

## Filters

A **filter** is a command that reads text, does **one** job with it, and writes the result to its standard output. It
reads the files that it gets as parameters or, when it gets none, its standard input. In
[Pipes](/docs/labs/03#pipes-) in lab 03 you joined a few of them with `|`: `sort fruits.txt | uniq -c`. A chain of
commands joined by pipes is a **pipeline**.

Think of an assembly line in a factory: every worker does **one** small job on the piece, and passes it on. A filter
does not know what is before it or after it: only its input and its output.

The filters of this lab do four kinds of jobs, and a typical pipeline uses them in this order:

| Kind             | What it does                                 | Commands                                     |
| ---------------- | -------------------------------------------- | -------------------------------------------- |
| **line filters** | chooses which lines to keep, and their order | `cat`, `tac`, `head`, `tail`, `sort`, `uniq` |
| **search**       | keeps the lines that match a pattern         | `grep`                                       |
| **change text**  | changes what is inside every line            | `cut`, `tr`, `sed`, `rev`, `nl`              |
| **compute**      | turns the lines into a count, a sum, ...     | `wc`, `uniq -c`, `awk`                       |

![A typical pipeline](./images/pipeline.svg)

```shell-session
[student@fedora lab06]$ grep ' 404$' access.log | cut -d' ' -f1 | sort | uniq -c
      2 10.0.0.3
      3 10.0.0.9
```

- `grep` kept the lines that end with `404`, the requests for pages that do not exist; `cut` kept only the first
  field, the address; `sort | uniq -c` counted every address. Each command is explained in the sections below.

:::tip

**Build a pipeline one command at a time**

Run the first command and look at its output. Then press <kbd>↑</kbd>, add `|` and the next command, and look again:
each step should bring the text a little closer to the answer. While you work, add `| head` at the end to see only the
first lines of a long output, and remove it when you are done.

:::

:::info

_"Write programs that do one thing and do it well. Write programs to work together. Write programs to handle text
streams, because that is a universal interface."_ (Doug McIlroy, the inventor of the Unix pipe)

:::

All the commands of a pipeline run **at the same time**, each one in its own process, and the text flows between them
while they run. The exercises at home and the challenges need the details: they are in
[How a Pipeline Runs](#how-a-pipeline-runs).

## Line Filters

The line filters work with **whole lines**: they choose which lines to keep and in which order, but do not change
them. The examples use the files that [exercise 1](#first-steps) creates in `~/lab06`; `fruits.txt` has 7 lines:
`banana`, `apple`, `cherry`, `apple`, `kiwi`, `banana` and `apple`.

### Showing a File: `cat` and `tac`

You met `cat` in [lab 02](/docs/labs/02#cat). Its options show what you cannot see in the text:

| Command         | What it does                                                                             |
| --------------- | ---------------------------------------------------------------------------------------- |
| `cat <FILE>...` | prints the files, one after another (_concatenate_)                                      |
| `cat`           | with no file, prints what it reads from the keyboard, until <kbd>Ctrl</kbd>+<kbd>D</kbd> |
| `cat -n <FILE>` | numbers every line                                                                       |
| `cat -A <FILE>` | shows the invisible characters: a tab as `^I`, the end of every line as `$`              |
| `tac <FILE>`    | prints the lines in the **reverse** order, the last one first                            |

```shell-session
[student@fedora lab06]$ tac fruits.txt
apple
banana
kiwi
apple
cherry
apple
banana
[student@fedora lab06]$ printf 'a\tb \n' | cat -A
a^Ib $
```

- `tac` printed the same 7 lines, from the last one to the first one.
- `cat -A` showed the tab between `a` and `b`, and the space at the end of the line, before the `$`.

### The First and the Last Lines: `head` and `tail`

| Command               | What it prints                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------ |
| `head -n <N> <FILE>`  | the first `N` lines; without `-n`, the first 10                                                        |
| `head -n -<N> <FILE>`  | all the lines, except the last `N` lines;                                                        |
| `tail -n <N> <FILE>`  | the last `N` lines; without `-n`, the last 10                                                          |
| `tail -n +<N> <FILE>` | the lines **from** line `N` to the end: `-n +2` skips only the first line                                                                |
| `tail -f <FILE>`      | the last lines, then every new line written to the file, until <kbd>Ctrl</kbd>+<kbd>C</kbd> (_follow_) |

```shell-session
[student@fedora lab06]$ head -n 3 fruits.txt
banana
apple
cherry
[student@fedora lab06]$ head -n 5 fruits.txt | tail -n 1
kiwi
[student@fedora lab06]$ tail -n +2 students.csv
Alice,30,Paris
Bob,25,London
Carol,22,Bucharest
```

- `head -n 5 | tail -n 1` kept the first 5 lines, then the last of them: the 5th line.
- `tail -n +2` skipped the first line of `students.csv`, the **header** with the names of the columns.

:::tip

`tail -f` is how administrators watch a **log**, a file where a program adds a line for everything it does. Leave it
running in a terminal, and you see every new line the moment it is written.

:::

### Sorting: `sort`

`sort` prints the lines in alphabetical order. The options change what it compares:

| Option       | What it does                                                        |
| ------------ | ------------------------------------------------------------------- |
| `-r`         | in the **reverse** order                                            |
| `-n`         | compares the lines as **numbers**: `9` before `10`                  |
| `-u`         | prints every line only **once** (_unique_)                          |
| `-t <C>`     | the fields are separated by the character `C` (the default: spaces) |
| `-k <N>,<N>` | sorts by field `N` only; `-k 2,2n`: by field `2`, as a number; `-k 2`: from field `2` to the end  |

```shell-session
[student@fedora lab06]$ sort numbers.txt
10
100
2
9
[student@fedora lab06]$ sort -n numbers.txt
2
9
10
100
[student@fedora lab06]$ sort -t, -k 2,2n students.csv
name,age,city
Carol,22,Bucharest
Bob,25,London
Alice,30,Paris
```

- Without `-n`, `sort` compared the numbers as text, character by character: `100` came before `2`, because `1` is
  before `2`.
- `-t, -k 2,2n` sorted the lines of `students.csv` by the second field, the age, as a number. The header has no
  number in that field, so it counts as `0` and stays first.

:::caution

Without `-n`, numbers are sorted as **text**: `100` before `2`. Use `-n` whenever the lines start with a number, or
`-k` with `n` when the number is in another field.

:::

### Counting Repeated Lines: `uniq`

You met `uniq` in [Repeated Lines](/docs/labs/03#repeated-lines-uniq) in lab 03: it compares a line only with the
line **right above it**, so it comes after `sort`. Together with `sort -nr` and `head`, it finds the most frequent
lines:

```shell-session
[student@fedora lab06]$ sort fruits.txt | uniq -c | sort -nr | head -n 2
      3 apple
      2 banana
```

- `sort | uniq -c` counted every fruit, `sort -nr` put the largest count first, and `head -n 2` kept the top two.

| Option    | What it prints                                  |
| --------- | ----------------------------------------------- |
| `uniq -c` | every line once, with how many times it appears |
| `uniq -d` | only the lines that appear more than once       |
| `uniq -u` | only the lines that appear exactly once         |

## Regular Expressions

A **regular expression** (_regex_) is a pattern that describes some text. For example, `c.l` means "a `c`, then any
character, then an `l`": it matches `col` in `color` and `cal` in `call`. Most programs that search text understand
regular expressions: `grep`, `sed` and `awk`, the search with <kbd>/</kbd> in `less`, `man` and `vim`, and almost
every programming language.

Think of a description of a person that you give to a friend at the station: you do not know the name, but "tall,
with a red hat" finds the right person in the crowd. A regex finds the lines that match the description.

`grep '<REGEX>' <FILE>` prints the lines that contain a match of the regex. The examples use `words.txt`:

```text
color
colour
cat
category
concatenate
dog
banana
bat
orange
gal
goal
gooooal
Cat
UPB
x86
notes.txt
2026-10-04
call 0722 123 456
```

:::caution

**A regex is not a glob**

The `*` of a glob (see [Globbing](/docs/labs/04#globbing) in lab 04) means "any characters"; in a regex, `*` means
"the previous item, any number of times", and "any characters" is `.*`. Always put the regex between **single
quotes**: without them, the shell may expand it as a glob, before `grep` starts. If the current directory has a file
`banana.txt`, `grep ba* fruits.txt` becomes `grep banana.txt fruits.txt`.

:::

### Basic Regular Expressions

| Regex    | Matches (It means)                                              | Example  | Matches in `words.txt` (Lines of `words.txt` it matches)                 |
| -------- | ---------------------------------------------------- | -------- | --------------------------------------- |
| `abc`    | the text `abc`, anywhere in the line                 | `cat`    | `cat`, `category`, `concatenate`        |
| `.`      | **any** single character                             | `c.l`    | `color`, `colour`, `call ...`           |
| `^`      | the **start** of the line                            | `^ca`    | `cat`, `category`, `call ...`           |
| `$`      | the **end** of the line                              | `r$`     | `color`, `colour`                       |
| `[abc]`  | **one** of the characters inside (a **class**)       | `[0-9]`  | `x86`, `2026-10-04`, `call ...`         |
| `[^abc]` | one character that is **not** inside; `^` means _not_ only right after `[`                 | `^[^c]`  | every line that does not start with `c` |
| `*`      | the **previous** item, **0 or more** times           | `go*al`  | `gal`, `goal`, `gooooal`                |
| `.*`     | any characters, or none                              | `^c.*e$` | `concatenate`                           |
| `\`      | the next character is plain text: `\.` is a real dot | `\.`     | `notes.txt`                             |

```shell-session
[student@fedora lab06]$ grep 'go*al' words.txt
gal
goal
gooooal
[student@fedora lab06]$ grep '^[a-z]*$' words.txt | wc -l
12
[student@fedora lab06]$ grep '.' words.txt | wc -l
18
[student@fedora lab06]$ grep '\.' words.txt
notes.txt
```

- `go*al` matched a `g`, any number of `o`, even none, then `al`.
- `^[a-z]*$` matched the lines that have only lowercase letters, from the start to the end: 12 of them.
- `.` alone matched **every** line that is not empty; `\.` matched only the line with a real dot.

### Extended Regular Expressions

With `grep -E`, five more characters are special: `+`, `?`, `{ }`, `( )` and `|`, and they make the regex shorter. The
table also shows `\b`, which GNU `grep` understands with or without `-E`:

| Regex | Matches                                                   | Example    | Matches in `words.txt`                  |
| ----- | --------------------------------------------------------- | ---------- | --------------------------------------- |
| `+`   | the previous item, **1 or more** times                    | `[0-9]+`   | `x86`, `2026-10-04`, `call ...`         |
| `?`   | the previous item, **0 or 1** time: it is optional        | `colou?r`  | `color`, `colour`                       |
| `{n}` | the previous item, exactly `n` times; `{n,m}`: `n` to `m` | `[0-9]{4}` | `2026-10-04`, `call 0722 ...`           |
| `( )` | a **group**, repeated as one item                         | `b(an)*a`  | `banana`, `bat`                         |
| `\|`  | one of the alternatives (_or_)                            | `cat\|dog` | `cat`, `category`, `concatenate`, `dog` |
| `\b`  | a **word edge**: the start or the end of a word           | `\bcat\b`  | only `cat`                              |

```shell-session
[student@fedora lab06]$ grep -E 'colou?r' words.txt
color
colour
[student@fedora lab06]$ grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' words.txt
2026-10-04
[student@fedora lab06]$ grep -E '\b[0-9]{3}\b' words.txt
call 0722 123 456
```

- `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` matched a line that is **only** a date: 4 digits, `-`, 2 digits, `-`, 2 digits.
- `\b[0-9]{3}\b` matched a number of exactly 3 digits, `123`; without the `\b`, it would match inside `0722` and
  `2026` too.

:::info

Without `-E`, `grep` uses the **basic** regular expressions, where `+`, `?`, `{`, `(` and `|` are plain characters
(`\+`, `\?`, ... are special instead). Use `-E` whenever you need one of them. The whole list is in `man 7 regex`.

:::

:::tip

**A playground for regular expressions**

[regex101.com](https://regex101.com) colors the matches while you type the regex, and explains every part of it in
plain words. Paste `words.txt` as the _test string_ and keep the `m` flag on, so that `^` and `$` match at every line,
as in `grep`. Its default flavor, PCRE2, understands all the regular expressions of this lab; check the final one with
`grep` anyway.

:::

### `grep` Options

| Option | What it does                                                                             |
| ------ | ---------------------------------------------------------------------------------------- |
| `-E`   | uses the **extended** regular expressions                                                |
| `-i`   | ignores upper and lower case                                                             |
| `-v`   | prints the lines that do **not** match                                                   |
| `-n`   | prints the number of every line in front of it                                           |
| `-c`   | prints only the number of matching lines; a line with two matches counts once                                                         |
| `-o`   | prints only the **matching part**, every match on its own line                           |
| `-w`   | matches only whole **words**, like `\b...\b` around the regex                                             |
| `-q`   | prints nothing (_quiet_): the answer is in its exit code (see [Exit Codes](#exit-codes)) |
| `-r`   | searches all the files of a directory, and of its subdirectories                         |

```shell-session
[student@fedora lab06]$ grep -n 'an' fruits.txt
1:banana
6:banana
[student@fedora lab06]$ grep -o -E '[0-9]+' words.txt
86
2026
10
04
0722
123
456
[student@fedora lab06]$ grep -v -c 'apple' fruits.txt
4
```

- `-n` showed that `banana` is on the lines `1` and `6`.
- `-o` printed every number of `words.txt` on its own line, without the rest of the line.
- `-v -c` counted the lines that do **not** contain `apple`.

## Change Text

### Fields and Delimiters

Many text files are **tables**: every line is a row, and a character, the **delimiter**, splits it into
**fields**, the columns. The fields are numbered from `1`.

| File                                      | A line                                                | The delimiter |
| ----------------------------------------- | ----------------------------------------------------- | ------------- |
| a **CSV** file (_comma-separated values_) | `Alice,30,Paris`                                      | `,`           |
| `/etc/passwd` (lab 05)                    | `student:x:1000:1000:Student:/home/student:/bin/bash` | `:`           |
| a log file, `access.log`                  | `10.0.0.9 GET /logo.png 404`                          | a space       |
| many programs                             | the fields are aligned in columns                     | a **tab**     |

![Fields and delimiters](./images/fields.svg)

:::caution

**Every** delimiter splits. In `Bob   25 London`, with three spaces after `Bob`, there are two **empty** fields
between the spaces, and `25` is field `4`, not `2`.

:::

### Cutting Columns: `cut`

| Command                   | What it prints                                                         |
| ------------------------- | ---------------------------------------------------------------------- |
| `cut -d<C> -f<N> <FILE>`  | field `N` of every line; the fields are separated by the character `C` |
| `cut -d<C> -f1,3`         | fields 1 and 3, separated by the same `C`, in the order of the line: `-f3,1` also prints field 1 first |
| `cut -d<C> -f2-4`, `-f2-` | fields 2 to 4; from field 2 to the end                                 |
| `cut -f<N>`               | without `-d`, the delimiter is the **tab**; a line with no tab is printed whole, whatever `N` is |
| `cut -c<N>-<M> <FILE>`    | the characters `N` to `M` of every line, counted from `1`              |

```shell-session
[student@fedora lab06]$ cut -d, -f1 students.csv
name
Alice
Bob
Carol
[student@fedora lab06]$ cut -d, -f2- students.csv
age,city
30,Paris
25,London
22,Bucharest
[student@fedora lab06]$ cut -d' ' -f2 people.txt
30

9
102
47
```

- `-d, -f1` printed the first field, the names; `-f2-` printed everything from the second field on.
- The second line of `people.txt` is `Bob   25 London`: for `Bob`, field `2` is the empty field between the first two
  spaces, so `cut` printed an empty line. `tr`, in the next section, fixes it.

### Changing Characters: `tr`

`tr` (_translate_) changes single **characters**, not words. It reads **only** its standard input: give it a file
with `<` or with a pipe.

| Command            | What it does                                                                            | Example                         |
| ------------------ | --------------------------------------------------------------------------------------- | ------------------------------- |
| `tr <SET1> <SET2>` | changes every character of `SET1` into the character at the **same position** in `SET2` | `tr abc xyz`: `cab` → `zxy`     |
| `tr -d <SET>`      | **deletes** every character of `SET`                                                    | `tr -d a`: `banana` → `bnn`     |
| `tr -s <SET>`      | **squeezes** a run of the same character of `SET` into one                              | `tr -s o`: `gooooal` → `goal`   |

A set is a list of characters, `aeiou`, or a range, `a-z`, `0-9`; `'\n'` is the end of a line and `'\t'` a tab.

```shell-session
[student@fedora lab06]$ tr a-z A-Z < fruits.txt | head -n 2
BANANA
APPLE
[student@fedora lab06]$ echo 'call 0722 123 456' | tr -d 0-9
call
[student@fedora lab06]$ tr -s ' ' < people.txt | cut -d' ' -f2
30
25
9
102
47
[student@fedora lab06]$ echo "$PATH" | tr : '\n'
/home/student/.local/bin
/home/student/bin
/usr/local/bin
/usr/bin
...
```

- `a-z` and `A-Z` have the same length: `a` became `A`, `b` became `B`, and so on.
- `-d 0-9` deleted the digits; the spaces stayed.
- `tr -s ' '` left one space between the fields of `people.txt`, so `cut` found the age of `Bob` in field `2`.
- `tr : '\n'` put every directory of `PATH` (lab 04) on its own line.

### Replacing Text: `sed`

`sed` (_stream editor_) changes the text as it passes through, like a worker on the assembly line: it reads a line,
changes it, prints it, and goes on to the next one. The file itself does not change. Unlike `tr`, `sed` works with
words and regular expressions, not with single characters. Its most used command is `s` (_substitute_), which replaces
the text that a regex matches:

```text
sed 's/<REGEX>/<NEW TEXT>/<FLAGS>' <FILE>
```

| Written as         | What it does                                                       |
| ------------------ | ------------------------------------------------------------------ |
| `s/apple/pear/`    | replaces the **first** match of every line                         |
| `s/apple/pear/g`   | replaces **every** match of the line (_global_)                    |
| `s/apple/pear/gi`  | the same, ignoring upper and lower case                            |
| `sed -E 's/...//'` | the regex is an **extended** one, as for `grep -E`                 |
| `s/apple//g`       | the new text is empty: deletes the matches                         |
| `s\|/usr\|/opt\|`  | any character can separate the parts: useful when the text has `/` |

```shell-session
[student@fedora lab06]$ echo 'apple and apple pie' | sed 's/apple/pear/'
pear and apple pie
[student@fedora lab06]$ echo 'apple and apple pie' | sed 's/apple/pear/g'
pear and pear pie
[student@fedora lab06]$ echo 'call 0722 123 456' | sed -E 's/[0-9]+/N/g'
call N N N
[student@fedora lab06]$ sed 's/,/ /g' students.csv
name age city
Alice 30 Paris
Bob 25 London
Carol 22 Bucharest
```

- Without `g`, only the first `apple` changed.
- `[0-9]+` matched each number, and every match became `N`.
- `sed` printed the changed text; `students.csv` itself did **not** change.

:::danger

`sed -i` writes the result **back into the file**, instead of printing it. There is no undo: run the command without
`-i` first, and look at the output.

:::

### Reversing and Numbering: `rev` and `nl`

| Command      | What it does                                                                            |
| ------------ | --------------------------------------------------------------------------------------- |
| `rev <FILE>` | reverses the **characters** of every line; the order of the lines stays (that is `tac`) |
| `nl <FILE>`  | adds a first column with the number of the line, and a tab; empty lines get no number   |

```shell-session
[student@fedora lab06]$ rev fruits.txt | head -n 2
ananab
elppa
[student@fedora lab06]$ echo /usr/share/doc/bash | rev | cut -d/ -f1 | rev
bash
```

- `cut` cannot count fields from the end. `rev` put the last field first, `cut -f1` took it, and the second `rev`
  turned it back.

## Counting and Computing

### Counting: `wc`

`wc` (_word count_) counts the lines, the words and the bytes:

| Option | What it counts                                                             |
| ------ | -------------------------------------------------------------------------- |
| `-l`   | the **lines**                                                              |
| `-w`   | the **words**: the groups of characters separated by spaces                |
| `-c`   | the **bytes**                                                              |
| `-m`   | the **characters**: a letter like `ș` takes 2 bytes, but it is 1 character |

```shell-session
[student@fedora lab06]$ wc fruits.txt
 7  7 44 fruits.txt
[student@fedora lab06]$ wc -l < fruits.txt
7
[student@fedora lab06]$ echo 'mașină' | wc -c -m
      7       9
```

- Without options, `wc` printed the lines, the words and the bytes, then the name of the file.
- With `<`, `wc` did not know the name of the file (see [Input](/docs/labs/03#input-) in lab 03): it printed only the
  number.
- `mașină` and the end of the line are 7 characters, but 9 bytes: `ș` and `ă` take two bytes each.

### Computing: `awk`

`awk` is a small programming language for tables. An `awk` program is a list of **conditions**, each with an
**action** between `{ }`: for every line, `awk` splits it into fields and runs the action of every condition that is
true for the line. A condition is optional; `END` is a condition that is true once, after the last line.

![An awk program](./images/awk.svg)

| Written as                 | What it is                                                                  |
| -------------------------- | --------------------------------------------------------------------------- |
| `-F,`                      | the delimiter is `,`; without `-F`, any run of spaces and tabs              |
| `$1`, `$2`, ..., `$NF`     | the fields; `$NF` is the last one, not to be confused with `NF`; `$0` is the whole line |
| `NF`, `NR`                 | the number of fields of the line; the number of the line, from `1`                   |
| `==`, `!=`, `<`, `>=`, ... | compare two values: numbers as numbers, text as text; text goes between `"`: `$2 == "apple"`                       |
| `~ /regex/`, `!~ /regex/`  | matches, does not match a regex                                             |
| `&&`, `\|\|`, `!`          | and, or, not                                                                |
| `{ print $1, $3 }`         | prints fields 1 and 3, separated by a space; `print $1 $3`, without the `,`, prints `alice3` |
| `{ s += $3; n++ }`         | adds field 3 to the variable `s`, and adds 1 to `n`; variables start at `0` |

The examples use `orders.csv`, a header and 6 orders:

```text
name,fruit,count
alice,apple,3
bob,kiwi,1
carol,apple,2
alice,banana,5
dan,apple,1
alice,apple,2
```

```shell-session
[student@fedora lab06]$ awk -F, '{ s += $3 } END { print s }' orders.csv
14
[student@fedora lab06]$ awk -F, 'NR > 1 { s += $3; n++ } END { print s / n }' orders.csv
2.33333
[student@fedora lab06]$ awk -F, '$2 == "apple" { s += $3 } END { print s }' orders.csv
8
[student@fedora lab06]$ awk -F, '$2 ~ /an/ { print $1, $2 }' orders.csv
alice banana
[student@fedora lab06]$ awk '{ print NF, $NF }' people.txt
3 Paris
3 London
3 Rome
3 Oslo
3 Madrid
```

- The first program added field 3 of every line, and printed the sum at the end; the header `count` is not a number,
  so it added `0`.
- `NR > 1` skipped the header, and `n` counted the orders: 14 / 6 = 2.33333.
- `$2 == "apple"` added only the apples; `$2 ~ /an/` printed the orders whose fruit contains `an`.
- Without `-F`, `awk` split `Bob   25 London` at the **run** of spaces: 3 fields, no empty ones.

:::tip

Put the `awk` program between **single quotes**: `$1` and `$3` are for `awk`, not for the shell.

:::

## A Pipeline, Step by Step

How many customers ordered apples? Build the pipeline one command at a time, and look at the text after every step:

```shell-session
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,'
alice,apple,3
carol,apple,2
dan,apple,1
alice,apple,2
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1
alice
carol
dan
alice
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1 | sort -u
alice
carol
dan
[student@fedora lab06]$ tail -n +2 orders.csv | grep ',apple,' | cut -d, -f1 | sort -u | wc -l
3
```

- `tail -n +2` skipped the header, and `grep ',apple,'` kept the orders of apples; the commas around `apple` skip a
  fruit like `pineapple`.
- `cut` kept the names; `alice` ordered apples twice, so `sort -u` kept every name once; `wc -l` counted them.

## Exit Codes

Every command ends with a number between `0` and `255`, its **exit code**: `0` means **success**, any other number an
error. The shell keeps the exit code of the last command in `$?` (see
[Special Parameters](/docs/labs/04#special-parameters---and-) in lab 04). The manual page of a command says what its
numbers mean, in the section `EXIT STATUS`:

| `grep` ends with | When                                           |
| ---------------- | ---------------------------------------------- |
| `0`              | it found at least one line                     |
| `1`              | it found nothing                               |
| `2`              | an error: for example, the file does not exist |

```shell-session
[student@fedora lab06]$ grep -q kiwi fruits.txt
[student@fedora lab06]$ echo $?
0
[student@fedora lab06]$ grep -q mango fruits.txt
[student@fedora lab06]$ echo $?
1
[student@fedora lab06]$ grep kiwi nope.txt
grep: nope.txt: No such file or directory
[student@fedora lab06]$ echo $?
2
```

- `grep -q` printed nothing; its exit code said if it found `kiwi`, `0`, or not, `1`.

| Command    | What it does                                        |
| ---------- | --------------------------------------------------- |
| `true`     | nothing; it ends with `0`                           |
| `false`    | nothing; it ends with `1`                           |
| `exit <N>` | ends the shell, or a script, with the exit code `N` |

A command killed by a signal (lab 04) ends with `128` plus the number of the signal: <kbd>Ctrl</kbd>+<kbd>C</kbd>
(`SIGINT`, `2`) gives `130`.

### Chaining Commands: `&&` and `||`

| Written as | What it does                                                          |
| ---------- | --------------------------------------------------------------------- |
| `a ; b`    | runs `a`, then `b`, whether `a` worked or not; like two separate lines                                |
| `a && b`   | runs `b` only if `a` ended with `0`: "`a`, **and then** `b`"          |
| `a \|\| b` | runs `b` only if `a` did **not** end with `0`: "`a`, **or else** `b`" |

```shell-session
[student@fedora lab06]$ grep -q kiwi fruits.txt && echo 'kiwi found'
kiwi found
[student@fedora lab06]$ grep -q mango fruits.txt && echo 'mango found'
[student@fedora lab06]$ grep -q mango fruits.txt || echo 'no mango'
no mango
[student@fedora lab06]$ mkdir -p backup && cp fruits.txt backup/ && echo 'saved'
saved
```

- `&&` skipped `echo 'mango found'`, because `grep` ended with `1`; `||` ran `echo 'no mango'` for the same reason.
- `cp` ran only after `mkdir` worked, and `echo` only after `cp` worked.

:::caution

`a && b || c` is **not** "if `a`, then `b`, else `c`": the shell reads it from left to right, so `c` also runs when
`a` works but `b` fails. It is safe when `b` cannot fail, like `echo`.

`a && b || c` is **not** "if `a`, then `b`, else `c`". The shell reads it from left to right, and `||` looks at the
exit code of the last command that ran before it: when `a` works, that is `b`. So `c` also runs when `a` works but `b` fails: `true && false || echo C` prints `C`. You can use `a && b || c` as "if
`a`, then `b`, else `c`" only when `b` cannot fail, like `echo`: then `c` runs only when `a` fails.
:::

### The Exit Code of a Pipeline

The exit code of a pipeline is the exit code of its **last** command:

```shell-session
[student@fedora lab06]$ cut -d, -f2 orders.csv | grep -q kiwi && echo 'kiwi ordered' || echo 'no kiwi'
kiwi ordered
[student@fedora lab06]$ cut -d, -f2 nope.csv | sort
cut: nope.csv: No such file or directory
[student@fedora lab06]$ echo $?
0
```

- In the first line, `grep -q` found `kiwi` in the column of the fruits: the pipeline ended with `0`.
- In the second, `cut` failed, but `sort`, the last command, worked: the pipeline ended with `0`. The error message is
  on the screen, but `$?`, `&&` and `||` see only the `0`. [How a Pipeline Runs](#how-a-pipeline-runs) shows how to
  catch the failure.

## Text Editors

You edit text files all the time: settings in `/etc` and in `~/.config`, programs, notes. On a server, over the
network, or on a virtual terminal (lab 04), there is no window: you need an editor that runs **inside the terminal**.

Terminal editors come in three kinds. In a **simple** editor, `nano`, what you type goes into the text. In a **modal**
editor, `vim`, `nvim` or Helix (`hx`), the keys are commands, and you type text only in one of its modes. Emacs is in
between: what you type goes into the text, as in `nano`, but every command is a **chord**, keys held down together,
and it can do almost anything. Think of it as a much more powerful `nano`.

### Simple: `nano` {/* #nano */}

You met `nano` in [lab 02](/docs/labs/02#nano); it is the default editor of Fedora and Ubuntu. The bottom of the
screen lists its keys: `^` means <kbd>Ctrl</kbd> and `M-` means <kbd>Alt</kbd>. All of them are in the `nano` tab of
[The Keys of Each Editor](#the-keys-of-each-editor).

### Modal: `vim`, `nvim` and `hx` {/* #vim */}

`vim` (_Vi IMproved_) is **modal**: the same key does different things in different **modes**. It starts in the
**Normal** mode, where every key is a **command**: <kbd>j</kbd> does not type a `j`, it moves the cursor down, and
<kbd>x</kbd> deletes a character. To type text, press <kbd>i</kbd> to enter the **Insert** mode; press <kbd>Esc</kbd>
to go back to the Normal mode. It takes some time to get used to, but it is also the strength of `vim`: when you edit,
you spend most of the time moving and changing text, not typing it, and in the Normal mode every letter is a command,
with no <kbd>Ctrl</kbd> to hold.

![The modes of vim](./images/vim-modes.svg)

| Mode         | What the keys do                                                       | Enter it with                                         | The last line shows                 |
| ------------ | ---------------------------------------------------------------------- | ----------------------------------------------------- | ----------------------------------- |
| Normal       | move, delete, copy, paste                                              | <kbd>Esc</kbd>, from any other mode                   | nothing                             |
| Insert       | type text                                                              | from Normal: <kbd>i</kbd>, <kbd>a</kbd>, <kbd>o</kbd> | `-- INSERT --`                      |
| Command line | type a command: save, quit, replace; <kbd>Enter</kbd> runs it          | <kbd>:</kbd> (or <kbd>/</kbd> to search)              | `:` (or `/`) and what you type      |
| Visual       | select text, then act on it: <kbd>d</kbd> deletes, <kbd>y</kbd> copies | <kbd>v</kbd> (characters), <kbd>V</kbd> (lines)       | `-- VISUAL --`, `-- VISUAL LINE --` |

`vi`, the ancestor of `vim`, is on every Unix system; `nvim` (Neovim) is a newer `vim`, with the same keys. Helix
(`hx`) is modal too, but you **select first, then act**: <kbd>x</kbd> selects the line, then <kbd>d</kbd> deletes it
(in `vim`, <kbd>d</kbd><kbd>d</kbd> does both). Helix knows the programming languages without any settings.

:::tip

**Lost in `vim`?**

Look at the last line to know the mode. Press <kbd>Esc</kbd> a few times to get back to the Normal mode, then type
`:q!` and <kbd>Enter</kbd> to quit without saving. `vimtutor` teaches the rest in 30 minutes.

:::

### Chorded: `emacs` {/* #emacs */}

Emacs has no modes: what you type goes into the text. Every command is a **chord**: <kbd>Ctrl</kbd>+<kbd>X</kbd>
<kbd>Ctrl</kbd>+<kbd>S</kbd> saves, <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd> quits. Its manual writes
<kbd>Ctrl</kbd> as `C-` and <kbd>Alt</kbd> as `M-` (_Meta_): `C-x C-s`. Start it with `emacs -nw` (_no window_) to
keep it in the terminal, and press <kbd>Ctrl</kbd>+<kbd>G</kbd> to cancel a command that you started by mistake.

### The Keys of Each Editor

The same actions in the four editors: choose the tab of the editor you use.

<Tabs groupId="editor">
<TabItem value="nano" label="nano">

| Action                        | Keys                                                                                             |
| ----------------------------- | ------------------------------------------------------------------------------------------------ |
| open a file                   | `nano <FILE>`                                                                                    |
| type text                     | type it                                                                                          |
| save                          | <kbd>Ctrl</kbd>+<kbd>O</kbd> (_write out_), then <kbd>Enter</kbd> to keep the name               |
| quit                          | <kbd>Ctrl</kbd>+<kbd>X</kbd>; if the file changed, it asks to save: <kbd>Y</kbd> or <kbd>N</kbd> |
| quit without saving           | <kbd>Ctrl</kbd>+<kbd>X</kbd>, then <kbd>N</kbd>                                                  |
| cancel a command              | <kbd>Ctrl</kbd>+<kbd>C</kbd>                                                                     |
| undo, redo                    | <kbd>Alt</kbd>+<kbd>U</kbd>, <kbd>Alt</kbd>+<kbd>E</kbd>                                         |
| search, the next match        | <kbd>Ctrl</kbd>+<kbd>W</kbd> (_where is_), <kbd>Alt</kbd>+<kbd>W</kbd>                           |
| cut the line                  | <kbd>Ctrl</kbd>+<kbd>K</kbd>                                                                     |
| copy the line                 | <kbd>Alt</kbd>+<kbd>6</kbd>                                                                      |
| paste                         | <kbd>Ctrl</kbd>+<kbd>U</kbd>                                                                     |
| the first line, the last line | <kbd>Alt</kbd>+<kbd>\\</kbd>, <kbd>Alt</kbd>+<kbd>/</kbd>                                        |
| go to a line, by its number   | <kbd>Ctrl</kbd>+<kbd>\_</kbd>                                                                    |
| replace                       | <kbd>Ctrl</kbd>+<kbd>\\</kbd>                                                                    |
| the tutorial                  | none: the bottom of the screen lists the keys                                                    |

</TabItem>
<TabItem value="vim" label="vim / nvim">

| Action                        | Keys                                                                        |
| ----------------------------- | --------------------------------------------------------------------------- |
| open a file                   | `vim <FILE>`, `nvim <FILE>`                                                 |
| type text                     | <kbd>i</kbd> (the Insert mode), then <kbd>Esc</kbd> back to the Normal mode |
| save                          | `:w`                                                                        |
| quit                          | `:q`; `:wq` saves and quits                                                 |
| quit without saving           | `:q!`                                                                       |
| cancel a command              | <kbd>Esc</kbd>                                                              |
| undo, redo                    | <kbd>u</kbd>, <kbd>Ctrl</kbd>+<kbd>R</kbd>                                  |
| search, the next match        | <kbd>/</kbd>`text` <kbd>Enter</kbd>, <kbd>n</kbd>                           |
| cut the line                  | <kbd>d</kbd><kbd>d</kbd>                                                    |
| copy the line                 | <kbd>y</kbd><kbd>y</kbd> (_yank_)                                           |
| paste                         | <kbd>p</kbd>, below the current line                                        |
| the first line, the last line | <kbd>g</kbd><kbd>g</kbd>, <kbd>G</kbd>                                      |
| go to a line, by its number   | `:42` goes to line 42                                                       |
| replace                       | `:%s/old/new/g`, like `sed`: `old` is a regex, `%` means all the lines      |
| the tutorial                  | `vimtutor`; in `nvim`, `:Tutor`                                             |

More keys of the Normal mode:

| Keys                                                               | Action                                  |
| ------------------------------------------------------------------ | --------------------------------------- |
| <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd>, or the arrows | left, down, up, right                   |
| <kbd>w</kbd>, <kbd>b</kbd>                                         | the next word, the previous word        |
| <kbd>0</kbd>, <kbd>$</kbd>                                         | the start, the end of the line          |
| <kbd>a</kbd>                                                       | the Insert mode, after the cursor       |
| <kbd>o</kbd>, <kbd>O</kbd>                                         | a new line below, above, in Insert mode |
| <kbd>x</kbd>                                                       | delete a character                      |

A number in front of a command repeats it: <kbd>5</kbd><kbd>j</kbd> goes 5 lines down,
<kbd>3</kbd><kbd>d</kbd><kbd>d</kbd> deletes 3 lines. The keys <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd>
are the ones of Sway, from [lab 01](/docs/labs/01).

</TabItem>
<TabItem value="hx" label="hx">

| Action                        | Keys                                                                                                                                 |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| open a file                   | `hx <FILE>`                                                                                                                          |
| type text                     | <kbd>i</kbd> (the Insert mode), then <kbd>Esc</kbd> back to the Normal mode                                                          |
| save                          | `:w`                                                                                                                                 |
| quit                          | `:q`; `:wq` saves and quits                                                                                                          |
| quit without saving           | `:q!`                                                                                                                                |
| cancel a command              | <kbd>Esc</kbd>                                                                                                                       |
| undo, redo                    | <kbd>u</kbd>, <kbd>U</kbd>                                                                                                           |
| search, the next match        | <kbd>/</kbd>`text` <kbd>Enter</kbd>, <kbd>n</kbd>                                                                                    |
| cut the line                  | <kbd>x</kbd> selects the line, <kbd>d</kbd> cuts it                                                                                  |
| copy the line                 | <kbd>x</kbd>, then <kbd>y</kbd>                                                                                                      |
| paste                         | <kbd>p</kbd>, after the selection                                                                                                    |
| the first line, the last line | <kbd>g</kbd><kbd>g</kbd>, <kbd>g</kbd><kbd>e</kbd>                                                                                   |
| go to a line, by its number   | `:goto 42`                                                                                                                           |
| replace                       | <kbd>%</kbd> selects the file, <kbd>s</kbd>`old` <kbd>Enter</kbd> selects every match, <kbd>c</kbd>`new` <kbd>Esc</kbd> changes them |
| the tutorial                  | `hx --tutor`                                                                                                                         |

After <kbd>g</kbd> or <kbd>Space</kbd>, Helix shows a menu with the keys that can follow.

</TabItem>
<TabItem value="emacs" label="emacs">

| Action                        | Keys                                                                                                                       |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| open a file                   | `emacs -nw <FILE>`                                                                                                         |
| type text                     | type it                                                                                                                    |
| save                          | <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>S</kbd>                                                                  |
| quit                          | <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd>                                                                  |
| quit without saving           | <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd>, then <kbd>n</kbd> and `yes`                                     |
| cancel a command              | <kbd>Ctrl</kbd>+<kbd>G</kbd>                                                                                               |
| undo, redo                    | <kbd>Ctrl</kbd>+<kbd>/</kbd>; to redo, <kbd>Ctrl</kbd>+<kbd>G</kbd>, then <kbd>Ctrl</kbd>+<kbd>/</kbd>                     |
| search, the next match        | <kbd>Ctrl</kbd>+<kbd>S</kbd>, then <kbd>Ctrl</kbd>+<kbd>S</kbd> again                                                      |
| cut the line                  | <kbd>Ctrl</kbd>+<kbd>A</kbd> (the start of the line), then <kbd>Ctrl</kbd>+<kbd>K</kbd> twice                              |
| copy the line                 | cut it, then <kbd>Ctrl</kbd>+<kbd>Y</kbd> pastes it back; the next <kbd>Ctrl</kbd>+<kbd>Y</kbd> pastes a copy              |
| paste                         | <kbd>Ctrl</kbd>+<kbd>Y</kbd> (_yank_)                                                                                      |
| the first line, the last line | <kbd>Alt</kbd>+<kbd>&lt;</kbd>, <kbd>Alt</kbd>+<kbd>&gt;</kbd>                                                             |
| go to a line, by its number   | <kbd>Alt</kbd>+<kbd>G</kbd> <kbd>G</kbd>, then the number                                                                  |
| replace                       | <kbd>Alt</kbd>+<kbd>%</kbd> `old` <kbd>Enter</kbd> `new` <kbd>Enter</kbd>, then <kbd>!</kbd> replaces all the next matches |
| the tutorial                  | <kbd>Ctrl</kbd>+<kbd>H</kbd> <kbd>T</kbd>                                                                                  |

</TabItem>
</Tabs>

### The Default Editor: `EDITOR`

Some programs open an editor for you, on a temporary file: they wait until you save and quit, then read what you
wrote. To know **which** editor to start, they read the environment variable **`EDITOR`**
([Environment Variables](/docs/labs/04#environment-variables) in lab 04). A few of them look first at **`VISUAL`**, an
older name for the same choice: if it is set, it wins.

| Program                                                                 | What it opens in the editor                                       |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `bash`, the keys <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>E</kbd> | the command you are typing; `bash` runs it when the editor quits |
| `less`, the key <kbd>v</kbd>                                            | the file you are reading                                          |
| `sudoedit <FILE>`                                                       | a copy of a system file, put back in place when the editor quits |
| `crontab -e`                                                            | the list of the commands that run on a schedule                   |
| `git commit`                                                            | the message of the commit (lab 07)                                |

```shell-session
[student@fedora ~]$ echo "[$EDITOR] [$VISUAL]"
[/usr/bin/nano] []
[student@fedora ~]$ export EDITOR=vim
[student@fedora ~]$ echo 'export EDITOR=vim' >> ~/.bashrc
```

- `echo` showed that Fedora chose `nano`, and that `VISUAL` is empty (Ubuntu: both are empty, and each program picks
  its own editor).
- `export EDITOR=vim` chose `vim` for the programs started from this terminal, until you close it.
- `echo ... >> ~/.bashrc` added the same line at the end of `~/.bashrc` (the settings of `bash`, read by every new
  terminal).

:::caution

Use `>>`, not `>`: `> ~/.bashrc` replaces the whole file with that one line, and the settings that were in it are lost.

:::

## How a Pipeline Runs

:::note

**Going deeper**

You do not need this section for the exercises of the lab, the 🧪 First Steps. Read it at home: the 🏠 Going Further
exercises and the 📝 Challenges use it.

:::

For a pipeline, the shell starts **every** command at the same time, each as a child process, and joins them with
**pipes**. A pipe is a small buffer in the kernel: the output (`1`) of a command writes into it, and the input (`0`)
of the next command reads from it. Think of a tube between two workers: the first one drops pieces in at one end, the
second takes them out at the other.

![How a pipeline runs](./images/pipeline-processes.svg)

| What happens                                               | The result                                                               |
| ---------------------------------------------------------- | ------------------------------------------------------------------------ |
| the pipe is **empty**, and the next command wants to read  | it waits until there is text                                             |
| the pipe is **full** (64 KiB)                              | the writer waits until the reader takes some text out                    |
| the writer **ends**                                        | the reader gets the _end of file_, and can finish                        |
| the reader **ends** before the writer                      | at its next write, the writer gets the signal `SIGPIPE` (`13`), and ends |
| <kbd>Ctrl</kbd>+<kbd>C</kbd>, <kbd>Ctrl</kbd>+<kbd>Z</kbd> | they go to **all** the commands: the pipeline is **one** job (lab 04)    |

```shell-session
[student@fedora lab06]$ yes | head -n 3
y
y
y
[student@fedora lab06]$ echo "${PIPESTATUS[@]}"
141 0
```

- `yes` prints `y` without end; `head` ended after 3 lines, and `yes` got `SIGPIPE` at its next write:
  `128 + 13 = 141`.
- `PIPESTATUS` is a variable of `bash` with the exit codes of **every** command of the last pipeline; `$?` has only
  the last one.

The pipes of a process are in its directory in `/proc` (see
[The `/proc` File System](/docs/labs/03#the-proc-file-system) in lab 03): `readlink /proc/<PID>/fd/1` prints
`pipe:[48211]` when output `1` goes to a pipe; both ends of the same pipe have the same number.

| Setting                | What it does                                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `set -o pipefail`      | the exit code of a pipeline is the one of the **rightmost command that failed**, or `0` if none failed; `set +o pipefail` turns it off |
| `grep --line-buffered` | `grep` writes every line at once; without it, when its output is a pipe, it waits until it has 4 KiB of text       |

```shell-session
[student@fedora lab06]$ set -o pipefail
[student@fedora lab06]$ cut -d, -f2 nope.csv | sort
cut: nope.csv: No such file or directory
[student@fedora lab06]$ echo $?
1
[student@fedora lab06]$ set +o pipefail
```

- With `pipefail`, the failure of `cut` was not hidden any more: the pipeline ended with `1`.

## Troubleshooting

| Problem                                                   | Solution                                                                                                                   |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| A command waits, and the prompt does not come back        | It reads the keyboard: you forgot the file, or the `<`. Press <kbd>Ctrl</kbd>+<kbd>D</kbd> or <kbd>Ctrl</kbd>+<kbd>C</kbd> |
| `tr: extra operand ‘fruits.txt’`                          | `tr` reads only its input: `tr a-z A-Z < fruits.txt`                                                                       |
| `sort` puts `100` before `2`                              | It sorts as text: add `-n`, or `n` after `-k`                                                                              |
| `uniq` leaves repeated lines                              | They are not next to each other: `sort` first                                                                              |
| `cut` prints empty lines, or the wrong field              | There are several delimiters in a row: squeeze them with `tr -s`, or use `awk`                                             |
| `cut -f2` prints the whole line                           | Without `-d`, the delimiter is the tab, and the line has none: give the delimiter with `-d`                                |
| `cut: the delimiter must be a single character`           | `-d` takes one character: `-d,`, `-d' '`, `-d:`                                                                            |
| `grep` finds lines that you did not expect                | `.` and `*` are special in a regex: write `\.` for a real dot, `\*` for a real star                                        |
| `grep: warning: stray \ before d`                         | `\d` is not a digit in `grep`: use `[0-9]`                                                                                 |
| `grep -E 'a+'` works but `grep 'a+'` finds nothing        | In basic regexes, `+` is a plain character: use `-E`                                                                       |
| `grep` with `*` finds strange results, or the wrong files | The regex is not between single quotes, and the shell expanded it as a glob                                                |
| ``sed: -e expression #1, char 8: unknown option to `s'``  | The text has a `/`: use another separator, `s\|/usr\|/opt\|`                                                               |
| `awk -F, '{ print $2 }'` prints empty lines               | The delimiter is wrong: look at a line with `cat -A`, and give the right one with `-F`                                     |
| `awk "{ print $1 }"` prints whole lines                   | Between double quotes, the shell replaced `$1` with nothing: use single quotes                                             |
| `vim` writes letters in strange places, or does not type  | You are in the wrong mode: press <kbd>Esc</kbd>, then <kbd>i</kbd> to type                                                 |
| `E37: No write since last change (add ! to override)`     | `vim` does not quit without saving: `:wq` saves, `:q!` throws the changes away                                             |
| `vim: command not found`                                  | Use `vi`, or install `vim-enhanced` (Ubuntu: `vim`)                                                                        |
| `jq: error ... Cannot index array with "city"`            | The file is a list: take its elements first, `.[] \| .city`                                                                |

## Exercises

- 🧪 [First Steps](#first-steps) (exercises 1 - 14): one idea at a time, in the order of the lab, to do in the lab;
- 🏠 [Going Further](#going-further) (exercises 15 - 34): longer exercises, to do at home; some of them look at how
  the commands of a pipeline run together, explained in [How a Pipeline Runs](#how-a-pipeline-runs);
- 📝 [Challenges](#challenges) (exercises 35 - 41): the hardest ones, like the ones at the exam.

:::danger

The filters only print: the files change only with `>`, `sed -i` or an editor. Before you write the result over a
file, look at it on the screen, and never redirect the output of a command into its own input file:
`sort f.txt > f.txt` leaves `f.txt` empty, because the shell empties the file for `>` before `sort` starts reading it.

:::

### 🧪 First Steps {/* #first-steps */}

Do these exercises in order, during the lab. Each one starts with what it wants you to achieve, and tries **one** idea
from the lab: read the section linked under its goal if you get stuck. Run the commands in `~/lab06`, unless the
exercise says otherwise.

1. **The practice tree**: Create the files that the other exercises use, in `~/lab06`.

    1. run these commands (copy them from the browser with <kbd>Ctrl</kbd>+<kbd>C</kbd> and paste them in the terminal
       with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd>):

       ```bash
       mkdir -p ~/lab06
       cd ~/lab06
       printf '%s\n' banana apple cherry apple kiwi banana apple > fruits.txt
       printf '%s\n' 10 9 100 2 > numbers.txt
       printf '%s\n' color colour cat category concatenate dog banana bat orange \
           gal goal gooooal Cat UPB x86 notes.txt 2026-10-04 'call 0722 123 456' > words.txt
       printf '%s\n' name,age,city Alice,30,Paris Bob,25,London Carol,22,Bucharest > students.csv
       printf '%s\n' 'Alice 30 Paris' 'Bob   25 London' 'Carol 9 Rome' 'Dave 102 Oslo' 'Erin 47 Madrid' > people.txt
       printf '%s\n' name,fruit,count alice,apple,3 bob,kiwi,1 carol,apple,2 \
           alice,banana,5 dan,apple,1 alice,apple,2 > orders.csv
       cat > access.log << 'END'
       10.0.0.7 GET /index.html 200
       10.0.0.9 GET /logo.png 404
       10.0.0.7 GET /about.html 200
       10.0.0.3 GET /old.html 404
       10.0.0.9 GET /favicon.ico 404
       10.0.0.5 GET /index.html 200
       10.0.0.9 GET /admin 404
       10.0.0.3 GET /old.html 404
       END
       ```

    2. list the files of `~/lab06`.

    <details className="reveal">
    <summary>Check</summary>

    1. The commands print nothing.
    2. `access.log`, `fruits.txt`, `numbers.txt`, `orders.csv`, `people.txt`, `students.csv` and `words.txt`.

    </details>

**Line filters**

2. **Both ends of a file**: Look at parts of a file, without printing all of it.
    <small>→ [Showing a File](#showing-a-file-cat-and-tac) · [The First and the Last Lines](#the-first-and-the-last-lines-head-and-tail)</small>

    1. print `fruits.txt` with the number of every line; then print it from the last line to the first;
    2. print only the 5th line of `fruits.txt`;
    3. print `students.csv` without its header;
    4. create the empty file `live.log`; in a second terminal, follow it; in the first terminal, add the line `first`
       to it; stop following it.

    <details className="reveal">
    <summary>Hint</summary>

    `man cat`: search for `number`; `man tail`: search for `+NUM` and for `follow`; add a line with `echo` and `>>`
    (lab 03).

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. The lines are numbered `1` to `7`; from the last line, the file starts with `apple` and ends with `banana`.
    2. `kiwi`.
    3. The output starts with `Alice,30,Paris`.
    4. `first` appears in the second terminal the moment you add it.

    </details>

3. **Sort and count**: Put lines in the right order, and find the lines that repeat.
    <small>→ [Sorting: `sort`](#sorting-sort) · [Counting Repeated Lines](#counting-repeated-lines-uniq)</small>

    1. sort `numbers.txt` as text, then as numbers, then as numbers from the largest;
    2. print the students of `students.csv`, without the header, from the oldest to the youngest;
    3. print every fruit of `fruits.txt` once, then only the fruits that appear exactly once;
    4. print the most frequent fruit, with how many times it appears, with **one** pipeline.

    <details className="reveal">
    <summary>Hint</summary>

    `man sort`: search for `field-separator` and for `KEYDEF`; `man uniq`: search for `unique`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `10 100 2 9`, then `2 9 10 100`, then `100 10 9 2`.
    2. `Alice`, `Bob`, `Carol`.
    3. `apple`, `banana`, `cherry` and `kiwi`; then only `cherry` and `kiwi`.
    4. `3 apple`.

    **Why:** as text, `100` comes before `2` because `1` comes before `2`, whatever follows it.

    </details>

**Regular expressions**

4. **Regular expressions**: Describe lines with a pattern, find them in `words.txt`, and see why a regex needs quotes.
    <small>→ [Basic Regular Expressions](#basic-regular-expressions) · [Extended Regular Expressions](#extended-regular-expressions) · [Regular Expressions](#regular-expressions)</small>

    For steps 1 - 4, **first** write the regex on paper, then check it with `grep`:

    1. find the lines that end with `l`;
    2. find the lines that have exactly three characters, all of them lowercase letters;
    3. find the lines that have a `g`, **one** or more `o`, then `al`;
    4. find the lines that are exactly `cat` or exactly `dog`;
    5. create the empty file `cat.txt`; **first** guess what `grep ca* words.txt` and `grep 'ca*' words.txt` print,
       then run them; delete `cat.txt`.

    <details className="reveal">
    <summary>Hint</summary>

    The tables of [Basic Regular Expressions](#basic-regular-expressions) and
    [Extended Regular Expressions](#extended-regular-expressions); for step 2, think of `^` and `$`. For step 5, print
    the words that `grep` receives with `echo grep ca* words.txt`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `gal`, `goal`, `gooooal`.
    2. `cat`, `dog`, `bat`, `gal`, but not `Cat`, `UPB` or `x86`.
    3. `goal` and `gooooal`, but not `gal`.
    4. `cat` and `dog`, but not `category`.
    5. `grep ca* words.txt` prints nothing; `grep 'ca*' words.txt` prints `color`, `colour`, `cat`, `category`,
       `concatenate` and `call 0722 123 456`.

    **Why:** without quotes, the shell turned `ca*` into `cat.txt`, and `grep` searched for the text `cat.txt`; with
    quotes, `grep` got `ca*`, a `c` and any number of `a`, even none.

    </details>

5. **`grep` options**: Make `grep` print exactly what you need: other lines, the line numbers, or only a number.
    <small>→ [`grep` Options](#grep-options)</small>

    1. print the settings of `/etc/login.defs` (lab 05), without the comments (the lines that start with `#`) and
       without the empty lines; then count them;
    2. print the line of the `UMASK` setting, with its line number;
    3. count the lines of `words.txt` that contain `cat`; then print only those where `cat` is a whole word, in
       lowercase or in capital letters.

    <details className="reveal">
    <summary>Hint</summary>

    `man grep`: search for `invert`, `line-number`, `word-regexp` and `ignore-case`; an empty line is `^$`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. Lines like `UID_MIN 1000`, a few dozen of them.
    2. One line, with its number and a `:` in front: `UMASK` is `022`.
    3. `3`; then `cat` and `Cat`.

    </details>

**Change text**

6. **Columns and characters**: Keep only some fields of every line with `cut`, and change characters with `tr`.
    <small>→ [Cutting Columns: `cut`](#cutting-columns-cut) · [Changing Characters: `tr`](#changing-characters-tr)</small>

    1. print the names and the cities of `students.csv`, without the header;
    2. print the name and the shell of every user, from the users database;
    3. print `fruits.txt` in capital letters; then print the fruits without their vowels;
    4. print the age of every person in `people.txt`, with `tr` and `cut`; then print the people from the youngest to
       the oldest;
    5. print the directories of your `PATH`, one per line.

    <details className="reveal">
    <summary>Hint</summary>

    `man cut`: search for `delimiter` and `fields`; `/etc/passwd` has 7 fields, separated by `:`, and `getent passwd`
    prints all the users (lab 05). `man tr`: search for `delete` and `squeeze`; `tr` reads only its input.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `Alice,Paris`, `Bob,London`, `Carol,Bucharest`.
    2. Lines like `student:/bin/bash`.
    3. `BANANA`, `APPLE`, `CHERRY`, ...; then `bnn`, `ppl`, `chrry`, `ppl`, `kw`, `bnn`, `ppl`.
    4. `30`, `25`, `9`, `102`, `47`; then `Carol`, `Bob`, `Alice`, `Erin`, `Dave`.
    5. One directory per line, among them `/usr/bin`.

    **Why:** for `cut`, every space is a delimiter, so `tr -s ' '` must squeeze the spaces of `Bob   25` first; sorted
    as text, `Dave` (`102`) would come first and `Carol` (`9`) last.

    </details>

7. **Replace text**: Change words and parts of lines with `sed`, without changing the files.
    <small>→ [Replacing Text: `sed`](#replacing-text-sed) · [Reversing and Numbering](#reversing-and-numbering-rev-and-nl)</small>

    1. replace `apple` with `pear` in `fruits.txt`; then check that `fruits.txt` did not change;
    2. print `students.csv` with tabs instead of commas, then cut its second column **without** `-d`;
    3. print the line `notes.txt` of `words.txt` without its extension;
    4. print your home directory with `/home` replaced by `/users`; then print only the name of the current directory,
       with `pwd`, `rev` and `cut`.

    <details className="reveal">
    <summary>Hint</summary>

    [Replacing Text: `sed`](#replacing-text-sed); `\t` is a tab; for step 4, use another separator than `/`, and
    remember that `cut` cannot count the fields from the end.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `pear` three times; `fruits.txt` still has `apple`.
    2. `age`, `30`, `25`, `22`.
    3. `notes`.
    4. `/users/student`; then `lab06`.

    </details>

**Counting and computing**

8. **Count and compute**: Count the lines and the characters of a text with `wc`, and answer questions about the orders
    of `orders.csv` with `awk`.
    <small>→ [Counting: `wc`](#counting-wc) · [Computing: `awk`](#computing-awk)</small>

    1. count the lines, the words and the bytes of `words.txt`; then only its lines, without the name of the file;
    2. count the characters and the bytes of `Iași`;
    3. compute how many fruits `alice` ordered in total;
    4. compute the average count of the orders of apples;
    5. print the name and the UID of the users whose UID is at least `1000`, from the users database.

    <details className="reveal">
    <summary>Hint</summary>

    `man wc`: search for `chars`. [Computing: `awk`](#computing-awk) has all you need; the UID is field 3 of the users
    database.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `18 21 128 words.txt`, then `18`.
    2. `5` characters, but `6` bytes.
    3. `10`.
    4. `2`.
    5. `student 1000`, and also `nobody 65534`.

    **Why:** `Iași` and the end of the line are 5 characters, but `ș` takes 2 bytes.

    </details>

**A pipeline**

9. **Read a log**: Answer questions about the requests of `access.log`, with pipelines that you build one command at a
    time.
    <small>→ [A Pipeline, Step by Step](#a-pipeline-step-by-step) · [Filters](#filters)</small>

    1. print how many times each page (the third field) was asked for, the most requested first, with its place in the
       ranking (`1`, `2`, ...) in front;
    2. print the addresses that asked for a page that does not exist (status `404`), each once;
    3. count the requests that ended with `404`.

    <details className="reveal">
    <summary>Hint</summary>

    [A Pipeline, Step by Step](#a-pipeline-step-by-step); look at the output after every command. The ranking is a
    line number: `man nl`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. 6 lines, numbered `1` to `6`: `/index.html` and `/old.html` first, with `2`; the others with `1`.
    2. `10.0.0.3` and `10.0.0.9`.
    3. `5`.

    </details>

**Exit codes**

10. **Did it work?**: Read the exit code of a command, and run a command only if another one worked, or failed.
    <small>→ [Exit Codes](#exit-codes) · [Chaining Commands](#chaining-commands--and-)</small>

    1. **first** guess the exit code of each command, then check it: `grep -q apple fruits.txt`,
       `grep -q mango fruits.txt`, `grep apple nope.txt`, `ls /nope`, `true` and `false`;
    2. print `found` only if `cherry` is in `fruits.txt`; then print `missing` only if `mango` is **not** in it;
    3. create the directory `save` and, only if that worked, copy `orders.csv` into it, with **one** line; run the
       same line again.

    <details className="reveal">
    <summary>Hint</summary>

    [Exit Codes](#exit-codes) and [Chaining Commands](#chaining-commands--and-); `man ls`: search for `Exit status`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `0`, `1`, `2`, `2`, `0`, `1`.
    2. `found`, then `missing`.
    3. The first time, nothing is printed; the second time, `mkdir` fails with `File exists`, and `cp` does not run.

    </details>

11. **The exit code of a pipeline**: Find out which command of a pipeline gives the exit code of the whole pipeline.
    <small>→ [The Exit Code of a Pipeline](#the-exit-code-of-a-pipeline)</small>

    For each pipeline, **first** guess its exit code, then run it and print `$?`:

    1. `grep mango fruits.txt | wc -l`;
    2. `wc -l fruits.txt | grep -q mango`;
    3. `grep apple nope.txt | sort`.

    <details className="reveal">
    <summary>Check</summary>

    1. `0`, and the exit code is `0`.
    2. Nothing, and the exit code is `1`.
    3. An error of `grep`, and the exit code is `0`.

    **Why:** a pipeline ends with the exit code of its **last** command: in lines 1 and 3, the failure of `grep` is
    hidden.

    </details>

**Text editors**

12. **Two editors**: Write a file with `nano`, then change it with `vim`.
    <small>→ [`nano`](#nano) · [`vim`](#vim)</small>

    1. with `nano`, create `todo.txt` with three lines: `buy milk`, `learn vim` and `call bob`; cut the last line and
       paste it above the first one; save and exit;
    2. open `todo.txt` with `vim`; delete the line `learn vim`, then undo; add the line `practice awk` at the end;
       replace `milk` with `bread`, with a command; save and quit;
    3. open it again, delete a line, and quit **without** saving; print `todo.txt`.

    <details className="reveal">
    <summary>Hint</summary>

    The `nano` and `vim` tabs of [The Keys of Each Editor](#the-keys-of-each-editor); in `vim`, always look at the last
    line to know the mode.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `todo.txt` has `call bob`, `buy milk` and `learn vim`.
    3. `todo.txt` has 4 lines: `call bob`, `buy bread`, `learn vim` and `practice awk`.

    </details>

13. **Your editor**: Choose `vim`, `nvim` (Neovim), `hx` (Helix) or `emacs`, and start learning it with its own
    tutorial, for 10 minutes. You will continue the tutorial at home, in [exercise 15](#going-further).
    <small>→ [Text Editors](#text-editors) · [The Keys of Each Editor](#the-keys-of-each-editor)</small>

    1. choose one of the four editors, and install it if it is missing:

       | Editor  | On Fedora                       | On Ubuntu                           | The tutorial                      |
       | ------- | ------------------------------- | ----------------------------------- | --------------------------------- |
       | `vim`   | `sudo dnf install vim-enhanced` | `sudo apt install vim`              | `vimtutor`                        |
       | `nvim`  | `sudo dnf install neovim`       | `sudo apt install neovim`           | `nvim +Tutor`                     |
       | `hx`    | `sudo dnf install helix`        | `sudo snap install --classic helix` | `hx --tutor`                      |
       | `emacs` | `sudo dnf install emacs`        | `sudo apt install emacs`            | `emacs -nw -f help-with-tutorial` |

    2. start its tutorial, and follow it for 10 minutes: it is a text file that you change while you read it;
    3. remember the lesson where you stopped, and quit the tutorial without saving.

    <details className="reveal">
    <summary>Hint</summary>

    Every tutorial starts with how to move and how to quit; the tab of your editor in
    [The Keys of Each Editor](#the-keys-of-each-editor) has the same keys on one page.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. The editor prints its version with `--version`.
    2. The tutorial opens inside the editor, at its first lesson; after 10 minutes you can move and quit without
       looking at it.

    </details>

14. **The default editor**: Make the programs that open an editor for you open the editor you chose in exercise 13.
    <small>→ [The Default Editor: `EDITOR`](#the-default-editor-editor)</small>

    1. choose your editor as the default editor, only for this terminal;
    2. type `echo one two`, **without** pressing <kbd>Enter</kbd>, open the line in the editor, add ` three` at its
       end, save and quit.

    <details className="reveal">
    <summary>Hint</summary>

    `man bash`: search for `edit-and-execute-command`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `echo $EDITOR` prints the name of your editor.
    2. The line opens in your editor; when the editor quits, `bash` runs it and prints `one two three`.

    </details>

### 🏠 Going Further {/* #going-further */}

Each exercise starts with its **goal**; you choose the commands. At the end, check the goal itself, not only that each
command worked. The exercises use the files of `~/lab06` from the First Steps.

15. **Your editor, the essentials**: Go on with the tutorial of the editor you chose in exercise 13, until you know
    enough to use it every day, then use it on a real file.
    <small>→ [Text Editors](#text-editors) · [The Keys of Each Editor](#the-keys-of-each-editor)</small>

    1. install the editor if it is missing on your computer:

       | Editor  | On Fedora                       | On Ubuntu                           | The tutorial                      |
       | ------- | ------------------------------- | ----------------------------------- | --------------------------------- |
       | `vim`   | `sudo dnf install vim-enhanced` | `sudo apt install vim`              | `vimtutor`                        |
       | `nvim`  | `sudo dnf install neovim`       | `sudo apt install neovim`           | `nvim +Tutor`                     |
       | `hx`    | `sudo dnf install helix`        | `sudo snap install --classic helix` | `hx --tutor`                      |
       | `emacs` | `sudo dnf install emacs`        | `sudo apt install emacs`            | `emacs -nw -f help-with-tutorial` |

    2. start its tutorial again, go to the lesson where you stopped in the lab, and follow it up to the end of these
       lessons; you do not need the rest of the tutorial yet:
       - `vim`, `nvim`: lessons 1 - 6, until you know `o`, `y` and `p` (lesson 7 is about help and settings);
       - `hx`: chapters 1 - 6, until you know the replace command, <kbd>r</kbd>;
       - `emacs`: the sections up to _Searching_, included;
    3. quit the tutorial without saving;
    4. open `todo.txt` from exercise 12 with your editor, add the line `use vim` (or `use nvim`, `use hx`,
       `use emacs`) at the end, save and quit; print `todo.txt`.

    <details className="reveal">
    <summary>Hint</summary>

    Every tutorial starts with how to move and how to quit; the tab of your editor in
    [The Keys of Each Editor](#the-keys-of-each-editor) has the same keys on one page.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. The editor prints its version with `--version`.
    2. You can move, insert, delete, copy, paste, undo, search, save and quit without looking at the tutorial.
    4. `todo.txt` ends with the line of your editor, after `practice awk`.

    </details>

**Line filters and search**

16. **Your favorite commands**: You have used the terminal for six weeks. Find out which 5 commands you run most
    often.
    <small>→ [Counting Repeated Lines](#counting-repeated-lines-uniq) · [Computing: `awk`](#computing-awk)</small>

    1. print the history of your shell, and find the field that holds the name of the command;
    2. print the 5 most used commands, each with how many times you ran it, the most used first.

    <details className="reveal">
    <summary>Hint</summary>

    `help history`; every line of `history` starts with a number.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. The name of the command is the second field, after the number of the line.
    2. 5 lines like `   42 ls`, with the counts going down; `ls` and `cd` are usually near the top.

    **Why:** the commands of the other open terminals are missing: each terminal adds its commands to
    `~/.bash_history` only when it is closed.

    </details>

17. **The largest programs**: The disk of your computer is almost full. Find the 5 largest files in `/usr/bin`, with
    sizes that are easy to read.
    <small>→ [Sorting: `sort`](#sorting-sort) · [Computing: `awk`](#computing-awk)</small>

    1. list `/usr/bin` in the long format, and sort the lines by the size, the 5th field, as a number; keep the 5
       largest;
    2. print only their size and their name;
    3. do it again with the sizes written as `2.1M`, and sort them correctly.

    <details className="reveal">
    <summary>Hint</summary>

    `man sort`: search for `KEYDEF` and for `human`; `man ls`: search for `human`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. 5 lines of `ls -l`, the largest file first.
    2. 5 lines, each with a size in bytes and a name.
    3. The same 5 files as in step 1, in the same order, with sizes like `2.1M`.

    **Why:** `sort -n` alone would read `900K` as `900` and `2.1M` as `2.1`, and think that `900K` is the larger one.

    </details>

18. **A sign-up form**: A form saved everything people typed, without checking it. Keep only the valid phone numbers
    and e-mail addresses.
    <small>→ [Extended Regular Expressions](#extended-regular-expressions) · [`grep` Options](#grep-options)</small>

    Create `contacts.txt`:

    ```bash
    cat > ~/lab06/contacts.txt << 'END'
    0722123456
    0722 123 456
    +40722123456
    072212345
    07221234567
    0312345678
    ana.pop@upb.ro
    bob@gmail
    carol@@yahoo.com
    dave_99@stud.upb.ro
    erin@example.com
    END
    ```

    1. print the mobile phone numbers: `07` and 8 more digits, nothing else on the line;
    2. accept also the numbers written with `+4` in front;
    3. print the e-mail addresses: lowercase letters, digits, `.` or `_`, then **one** `@`, then a domain of lowercase
       letters and dots, which ends with a `.` and some letters;
    4. count the lines that are neither a phone number, as in step 2, nor an e-mail address, with **one** `grep`.

    <details className="reveal">
    <summary>Hint</summary>

    [Extended Regular Expressions](#extended-regular-expressions); a `+` that is a plain character is written `\+`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `0722123456`.
    2. `0722123456` and `+40722123456`.
    3. `ana.pop@upb.ro`, `dave_99@stud.upb.ro` and `erin@example.com`.
    4. `6`.

    </details>

**Columns and computing**

19. **Names from the secretary**: The secretary exported the names as `Popescu, Ana`, but the new system wants
    `Ana Popescu`, and an address for every student.
    <small>→ [Replacing Text: `sed`](#replacing-text-sed) · [Changing Characters: `tr`](#changing-characters-tr)</small>

    Create `names.txt` with `printf '%s\n' 'Popescu, Ana' 'Ionescu, Mihai' 'Georgescu, Ioana' > names.txt`:

    1. print every name as `Ana Popescu`, with **one** `sed`;
    2. sort the result by the first name;
    3. print an e-mail address for every student, like `ana.popescu@upb.ro`, all in lowercase.

    <details className="reveal">
    <summary>Hint</summary>

    `man sed`: search for `\1`; in an extended regex, `( )` keeps what it matched, and `\1`, `\2` put it back in the
    new text.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `Ana Popescu`, `Mihai Ionescu`, `Ioana Georgescu`.
    2. `Ana Popescu`, `Ioana Georgescu`, `Mihai Ionescu`.
    3. `ana.popescu@upb.ro`, `mihai.ionescu@upb.ro`, `ioana.georgescu@upb.ro`.

    </details>

20. **The words of the manual**: Which words does the manual of `bash` use most, and how many different words does it
    have?
    <small>→ [Changing Characters: `tr`](#changing-characters-tr) · [Counting Repeated Lines](#counting-repeated-lines-uniq)</small>

    1. print the text of `man bash`, one word per line: every run of characters that are not letters becomes one end
       of line;
    2. make all the words lowercase, and print the 10 most frequent ones, with their counts;
    3. count the different words.

    <details className="reveal">
    <summary>Hint</summary>

    `man tr`: search for `complement`; the manual page, sent into a pipe, is plain text.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. One word per line, with no spaces and no punctuation.
    2. `the` is the first, by far; small words like `a`, `is`, `to` and `of` follow.
    3. A few thousand different words.

    </details>

21. **The memory of the browser**: Your computer is slow, and you suspect Firefox. Find out how much memory all its
    processes use together.
    <small>→ [Computing: `awk`](#computing-awk) · [Listing Processes](/docs/labs/03#listing-processes-ps)</small>

    Open Firefox with a few tabs, then:

    1. list the memory (`RSS`) and the whole command line of every process, and keep only the ones of Firefox; count
       them;
    2. add up their memory, and print it in MiB;
    3. print the 3 processes of the system that use the most memory.

    <details className="reveal">
    <summary>Hint</summary>

    `man ps`: search for `rss` (the unit is KiB) and for `args`; a tab of Firefox is a process too, whose name is not
    `firefox`, but whose command line has it. `grep firefox` has `firefox` in its own command line, so it finds itself;
    `grep '[f]irefox'` matches the same processes, but not itself.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. Several processes, one for every few tabs.
    2. A few hundred MiB.
    3. Firefox is usually among them.

    </details>

22. **The exam grades**: The teaching assistant needs a report of the exam, from a file of grades.
    <small>→ [Computing: `awk`](#computing-awk)</small>

    Create `grades.csv` with
    `printf '%s\n' name,grade ana,9 bob,4 carol,7 dave,10 erin,3 grace,5 mallory,6 > grades.csv`, then compute, with
    `awk`:

    1. how many students passed (a grade of at least `5`);
    2. the average of all the grades, and the average of the students who passed;
    3. the largest grade, and the student who got it;
    4. the names of the students who did not pass, in alphabetical order.

    <details className="reveal">
    <summary>Hint</summary>

    Skip the header in every step, with `NR > 1`: `awk` compares the text `grade` with a number as text, so it would
    pass, and even become the largest grade. A variable can remember the largest value so far:
    `NR > 1 && $2 > max { max = $2 }`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `5`.
    2. `6.28571` and `7.4`.
    3. `dave 10`.
    4. `bob` and `erin`.

    </details>

23. **An audit of the users**: Write the report of the users of the system, as an administrator would do it each
    month.
    <small>→ [Computing: `awk`](#computing-awk) · [Cutting Columns: `cut`](#cutting-columns-cut)</small>

    From the users database:

    1. print every shell and how many users have it, the most used first;
    2. count the system users (a UID from `1` to `999`);
    3. print the name and the home directory of the regular users (a UID from `1000` to `60000`).

    <details className="reveal">
    <summary>Hint</summary>

    `man login.defs`: search for `UID_MAX`; `awk` conditions can use `&&`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `nologin` is the most used shell.
    2. A few dozen system users.
    3. `student` and every user from lab 05 that is still there, each with a home directory in `/home`.

    **Why:** `nobody` (`65534`) is not a regular user: its UID is larger than `UID_MAX`.

    </details>

24. **From JSON to a table**: A weather service answers in **JSON**, the text format of most web services, not in
    lines. Turn its answer into lines that the filters can use, and into a table that you can read.
    <small>→ [Filters](#filters) · [Sorting: `sort`](#sorting-sort)</small>

    Create `weather.json`:

    ```bash
    cat > ~/lab06/weather.json << 'END'
    [
      {"city": "Bucharest", "temp": 12, "sky": "sunny"},
      {"city": "Cluj", "temp": 7, "sky": "rain"},
      {"city": "Iasi", "temp": 9, "sky": "cloudy"},
      {"city": "Timisoara", "temp": 14, "sky": "sunny"},
      {"city": "Constanta", "temp": 15, "sky": "wind"}
    ]
    END
    ```

    1. print `students.csv` as a table, with the columns aligned, with `column`;
    2. install `jq` if it is missing (`sudo dnf install jq`; Ubuntu: `sudo apt install jq`), then print `weather.json`
       with `jq`, indented and in color;
    3. print only the names of the cities, one per line, without quotes;
    4. print the cities where the sky is `sunny`, each with its temperature; then only the warmest city;
    5. print the city, the temperature and the sky of every city, as a table with the columns aligned.

    <details className="reveal">
    <summary>Hint</summary>

    `man column`: search for `table` and `separator`. In `jq`, `.` is the whole input, `.[]` every element of a list,
    `.city` a field, and `|` passes the result on, as in the shell; `-r` prints text without quotes. `man jq`: search
    for `select` and for `String interpolation`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `name   age  city`, then `Alice  30   Paris`, ..., with the columns aligned.
    2. The same 5 cities, every field on its own line, indented.
    3. `Bucharest`, `Cluj`, `Iasi`, `Timisoara`, `Constanta`.
    4. `Bucharest 12` and `Timisoara 14`; then `Constanta` (`15`).
    5. 5 lines, from `Bucharest  12  sunny` to `Constanta  15  wind`, with the columns aligned.

    **Why:** `jq` turns JSON into lines, and from there every filter of the lab works; `column` only changes how the
    lines look.

    </details>

**Exit codes**

25. **Predict the chain**: Learn to read `&&` and `||` without running the commands.
    <small>→ [Chaining Commands](#chaining-commands--and-)</small>

    **First** write down, on paper, what each line prints, then check:

    1. `true && echo A || echo B`
    2. `false && echo A || echo B`
    3. `true || echo A && echo B`
    4. `false || false && echo C; echo $?`
    5. `true && false || echo D`

    <details className="reveal">
    <summary>Check</summary>

    1. `A`.
    2. `B`.
    3. `B`.
    4. Nothing, then `1`.
    5. `D`.

    **Why:** the shell reads from left to right, and each `&&` or `||` looks at the exit code of the last command that
    ran before it: in line 5, `D` is printed although the first command worked.

    </details>

26. **What the numbers mean**: Find out what the exit codes say, besides "success" and "error".
    <small>→ [Exit Codes](#exit-codes) · [Signals](/docs/labs/04#signals)</small>

    1. find in the manual what `ls` means by `1` and by `2`, and produce each of them;
    2. start `sleep 100`, stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd>, and print its exit code; do it again, but end it
       with `kill` from another terminal, then with `kill -9`;
    3. run `bash -c 'exit 42'` and print its exit code; then `bash -c 'exit 300'`.

    <details className="reveal">
    <summary>Hint</summary>

    `man ls`: search for `Exit status`; hide the long output of `ls -R` with `> /dev/null 2>&1`; `kill -l 15` prints
    the name of signal `15`; an exit code is one byte.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `ls /nope` ends with `2`; `ls -R /etc` ends with `1`, because some directories inside it cannot be read.
    2. `130` (`128 + 2`, `SIGINT`), `143` (`128 + 15`, `SIGTERM`), then `137` (`128 + 9`, `SIGKILL`).
    3. `42`, then `44`.

    **Why:** `300` does not fit in one byte, and only `300 - 256` is kept.

    </details>

27. **A careful change**: You must change `kiwi` into `mango` in `orders.csv`, directly in the file. Do it so that you
    can always go back.
    <small>→ [Chaining Commands](#chaining-commands--and-) · [Replacing Text: `sed`](#replacing-text-sed)</small>

    1. with **one** line: copy `orders.csv` to `orders.bak`; only if the copy worked, change the file with `sed -i`;
       print `changed` if both worked, or `not changed` otherwise;
    2. check the content of both files;
    3. run the same line again, but copy into `/nope/orders.bak`;
    4. put the original `orders.csv` back, from `orders.bak`.

    <details className="reveal">
    <summary>Hint</summary>

    [Replacing Text: `sed`](#replacing-text-sed) and [Chaining Commands](#chaining-commands--and-).

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `changed`.
    2. `orders.csv` has `bob,mango,1`, and `orders.bak` has `bob,kiwi,1`.
    3. An error of `cp`, then `not changed`: `sed` did not run.
    4. `grep -c kiwi orders.csv` prints `1`.

    </details>

**How a pipeline runs**

28. **The processes of a pipeline**: See that the commands of a pipeline run together, as one job.
    <small>→ [How a Pipeline Runs](#how-a-pipeline-runs) · [Foreground and Background](/docs/labs/04#foreground-and-background)</small>

    1. in the second terminal, print the PID of the shell, then run `sleep 300 | sleep 301 | cat`;
    2. in the first terminal, show the tree of processes of the second shell, with the PIDs; list these processes with
       their PID, PPID, process group, state and name;
    3. stop the pipeline with <kbd>Ctrl</kbd>+<kbd>Z</kbd>, and list them again; continue it with `fg`, and end it
       with <kbd>Ctrl</kbd>+<kbd>C</kbd>.

    <details className="reveal">
    <summary>Hint</summary>

    `man pstree`: search for `pid`; `man ps`: search for `pgid` and for `state`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. A number, the PID of the shell; the pipeline does not give the prompt back.
    2. The three commands are children of the same `bash`, and they have the same process group: the PID of the first
       `sleep`. They are all `S` (waiting).
    3. After <kbd>Ctrl</kbd>+<kbd>Z</kbd>, all three are `T` (stopped); <kbd>Ctrl</kbd>+<kbd>C</kbd> ends all three.

    </details>

29. **Follow the pipe**: Find the pipe between two commands in `/proc`.
    <small>→ [How a Pipeline Runs](#how-a-pipeline-runs) · [The `/proc` File System](/docs/labs/03#the-proc-file-system)</small>

    1. in the second terminal, run `sleep 300 | cat`;
    2. in the first terminal, find the PIDs of `sleep` and `cat`, and print where the inputs (`0`) and the outputs
       (`1`) of both lead;
    3. end the pipeline.

    <details className="reveal">
    <summary>Hint</summary>

    `man pgrep`; `man readlink`; the file descriptors of a process are in `/proc/<PID>/fd` (lab 03).

    </details>

    <details className="reveal">
    <summary>Check</summary>

    2. The output of `sleep` and the input of `cat` are the same `pipe:[...]`, with the same number; the input of
       `sleep` and the output of `cat` are the terminal, `/dev/pts/...`.

    </details>

30. **Who ends first**: Find out what happens to a command whose reader stopped reading.
    <small>→ [How a Pipeline Runs](#how-a-pipeline-runs)</small>

    For each line, **first** guess the exit codes of the two commands, then print them with `PIPESTATUS`:

    1. `yes | head -n 3`;
    2. `seq 5 | sleep 2`;
    3. `seq 100000 | sleep 2`.

    <details className="reveal">
    <summary>Hint</summary>

    `kill -l 13`; `seq 100000 | wc -c` tells how much text `seq` writes; the pipe holds 64 KiB.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. `141 0`: `yes` got `SIGPIPE`.
    2. `0 0`: the 5 short lines fit in the pipe, and `seq` ended before `sleep`.
    3. `141 0`: about 575 KiB do not fit, so `seq` waited for a reader; when `sleep` ended without reading, `seq` got
       `SIGPIPE`.

    </details>

31. **A failure in the middle**: Every night, a pipeline counts the customers of the shop. One night the file was
    missing, and the report said `0`, with no error. Make the pipeline tell the truth.
    <small>→ [How a Pipeline Runs](#how-a-pipeline-runs) · [The Exit Code of a Pipeline](#the-exit-code-of-a-pipeline)</small>

    1. run `cut -d, -f1 nope.csv | sort -u | wc -l`; then, with **one** `echo`, print its exit code and the exit codes
       of every command;
    2. add `&& echo ok || echo failed` after the pipeline;
    3. turn on `pipefail`, and run step 2 again; then turn it off.

    <details className="reveal">
    <summary>Hint</summary>

    [How a Pipeline Runs](#how-a-pipeline-runs); `echo` is a command too: after it, `$?` and `PIPESTATUS` describe the
    `echo`, not the pipeline.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    1. An error of `cut`, then `0`; the exit code is `0`, but `PIPESTATUS` is `1 0 0`.
    2. `ok`.
    3. `failed`.

    </details>

32. **Watch a live log**: Watch the requests that end with `404` while they arrive, and only their addresses.
    <small>→ [How a Pipeline Runs](#how-a-pipeline-runs) · [The First and the Last Lines](#the-first-and-the-last-lines-head-and-tail)</small>

    1. in the second terminal, follow `live.log` and keep only the lines that contain `404`;
    2. in the first terminal, add the line `10.0.0.9 GET /x 404` to `live.log`, then the line `10.0.0.7 GET / 200`;
    3. in the second terminal, add `cut` at the end, to keep only the address; add another `404` line;
    4. fix the pipeline of step 3, so that the address appears right away.

    <details className="reveal">
    <summary>Hint</summary>

    [How a Pipeline Runs](#how-a-pipeline-runs); `man grep`: search for `line-buffered`.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    2. Only the `404` line appears, right away.
    3. Nothing appears.
    4. With `grep --line-buffered`, the address appears at once.

    **Why:** in step 3, the output of `grep` goes into a pipe, and `grep` waits until it has 4 KiB of text.

    </details>

**Text editors**

33. **Your editor on a real file**: Change a file with the editor you learned in exercises 13 and 15, without retyping
    the lines that stay.
    <small>→ [Text Editors](#text-editors) · [The Keys of Each Editor](#the-keys-of-each-editor)</small>

    1. copy `students.csv` to `class.csv`, and open it with your editor;
    2. add the line `Dave,27,Cluj` at the end;
    3. copy the line of `Bob` and paste the copy under it; change the copy into `Erin,24,Iasi`;
    4. replace every `,` with `;`, in **one** command; save, quit, and print the file.

    <details className="reveal">
    <summary>Hint</summary>

    Choose your editor:

    <Tabs groupId="editor">
    <TabItem value="vim" label="vim">

    | Step | Keys |
    | --- | --- |
    | open the file | `vim class.csv` |
    | add a line at the end | <kbd>G</kbd> goes to the last line, <kbd>o</kbd> opens a new line below; type it, <kbd>Esc</kbd> |
    | copy a line and paste it below | on `Bob`: <kbd>y</kbd><kbd>y</kbd> copies the line, <kbd>p</kbd> pastes it below |
    | change a whole line | on the copy: <kbd>c</kbd><kbd>c</kbd> deletes the text of the line; type the new one, <kbd>Esc</kbd> |
    | replace in the whole file | `:%s/,/;/g`; `:s` without `%` changes only the current line |
    | save and quit | `:wq` |

    </TabItem>
    <TabItem value="nvim" label="nvim">

    Neovim has the keys of `vim`.

    | Step | Keys |
    | --- | --- |
    | open the file | `nvim class.csv` |
    | add a line at the end | <kbd>G</kbd> goes to the last line, <kbd>o</kbd> opens a new line below; type it, <kbd>Esc</kbd> |
    | copy a line and paste it below | on `Bob`: <kbd>y</kbd><kbd>y</kbd> copies the line, <kbd>p</kbd> pastes it below |
    | change a whole line | on the copy: <kbd>c</kbd><kbd>c</kbd> deletes the text of the line; type the new one, <kbd>Esc</kbd> |
    | replace in the whole file | `:%s/,/;/g`; `:s` without `%` changes only the current line |
    | save and quit | `:wq` |

    </TabItem>
    <TabItem value="hx" label="hx">

    | Step | Keys |
    | --- | --- |
    | open the file | `hx class.csv` |
    | add a line at the end | <kbd>g</kbd><kbd>e</kbd> goes to the last line, <kbd>o</kbd> opens a new line below; type it, <kbd>Esc</kbd> |
    | copy a line and paste it below | on `Bob`: <kbd>x</kbd> selects the line, <kbd>y</kbd> copies it, <kbd>p</kbd> pastes it below |
    | change a whole line | on the copy: <kbd>x</kbd> selects the line, <kbd>_</kbd> leaves out its end, <kbd>c</kbd> deletes it; type the new one, <kbd>Esc</kbd> |
    | replace in the whole file | <kbd>%</kbd> selects the whole file, <kbd>s</kbd> `,` <kbd>Enter</kbd> selects every `,` in it, <kbd>r</kbd><kbd>;</kbd> replaces all of them |
    | save and quit | `:wq` |

    </TabItem>
    <TabItem value="emacs" label="emacs">

    | Step | Keys |
    | --- | --- |
    | open the file | `emacs -nw class.csv` |
    | add a line at the end | <kbd>Alt</kbd>+<kbd>&gt;</kbd> goes to the end of the file; type it |
    | copy a line and paste it below | at the start of `Bob` (<kbd>Ctrl</kbd>+<kbd>A</kbd>): <kbd>Ctrl</kbd>+<kbd>K</kbd> twice cuts the line, <kbd>Ctrl</kbd>+<kbd>Y</kbd> twice pastes it back, and a copy |
    | change a whole line | on the copy (<kbd>Ctrl</kbd>+<kbd>P</kbd> goes up), at its start: <kbd>Ctrl</kbd>+<kbd>K</kbd> cuts the text; type the new one |
    | replace in the whole file | <kbd>Alt</kbd>+<kbd>&lt;</kbd> goes to the start, <kbd>Alt</kbd>+<kbd>%</kbd> `,` <kbd>Enter</kbd> `;` <kbd>Enter</kbd> asks for every match; <kbd>!</kbd> replaces all of them |
    | save and quit | <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>S</kbd>, then <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>Ctrl</kbd>+<kbd>C</kbd> |

    </TabItem>
    </Tabs>

    </details>

    <details className="reveal">
    <summary>Check</summary>

    4. `class.csv` has 6 lines: `name;age;city`, `Alice;30;Paris`, `Bob;25;London`, `Erin;24;Iasi`,
       `Carol;22;Bucharest` and `Dave;27;Cluj`.

    </details>

**Clean up**

34. **Clean up**: Leave your home directory as it was before the lab.
    <small>→ [How a Pipeline Runs](#how-a-pipeline-runs)</small>

    1. delete `~/lab06`;
    2. if `set -o pipefail` is still on in a shell, close that terminal.

    <details className="reveal">
    <summary>Check</summary>

    1. `ls ~` does not show `lab06`.
    2. In a new terminal, `set -o | grep pipefail` prints `pipefail off`.

    </details>

### 📝 Challenges {/* #challenges */}

These exercises are like the ones at the exam. Each one gives you a **result** to reach, but not the steps: you decide
the commands. Each one ends with the **Check** that will be used to grade it. Some of them need
[How a Pipeline Runs](#how-a-pipeline-runs).

All the challenges start from the same setup, the one you will find at the exam: the directory `~/exam` with five
files. `web.log` has one request per line, with 7 fields separated by a space: the address, the date, the time, the
method, the page, the status and the number of bytes sent. `stock.json` is a JSON list, for `jq` (the first
command installs it; Ubuntu: `sudo apt install jq`). Copy and run these commands before the first challenge; run
them again to get the original files back:

```bash
command -v jq > /dev/null || sudo dnf install -y jq
mkdir -p ~/exam
cd ~/exam
cat > web.log << 'END'
10.0.0.7 2026-11-02 10:15:01 GET /index.html 200 5120
10.0.0.9 2026-11-02 10:15:04 GET /logo.png 404 0
10.0.0.7 2026-11-02 10:15:09 GET /about.html 200 2048
10.0.0.3 2026-11-02 10:16:12 GET /old.html 404 0
10.0.0.9 2026-11-02 10:16:30 GET /favicon.ico 404 0
10.0.0.5 2026-11-02 10:17:45 POST /login 200 512
10.0.0.9 2026-11-02 10:18:02 GET /admin 403 0
10.0.0.3 2026-11-02 10:18:40 GET /old.html 404 0
10.0.0.12 2026-11-02 11:02:11 GET /index.html 200 5120
10.0.0.5 2026-11-02 11:03:27 GET /exam.pdf 200 734003
10.0.0.9 2026-11-02 11:04:51 POST /login 401 0
10.0.0.9 2026-11-02 11:04:53 POST /login 401 0
10.0.0.9 2026-11-02 11:04:55 POST /login 401 0
10.0.0.7 2026-11-02 11:20:00 GET /index.html 200 5120
10.0.0.12 2026-11-02 12:01:10 GET /exam.pdf 200 734003
10.0.0.7 2026-11-02 12:30:44 GET /contact.html 200 1024
10.0.0.5 2026-11-02 12:31:02 POST /login 401 0
END
printf '%s\n' 'B 123 ABC' 'B 12 XYZ' 'IF 07 UPB' 'CJ 123 ABC' 'IS 99 ab' 'b 100 USO' \
    'TM 05 LNX' 'B1 23 ABC' 'AG 7 OOO' > plates.txt
printf '%s\n' name,lab,exam ana,4.5,3.5 bob,2,1.5 carol,3,4 dave,5,4.5 erin,1.5,2 \
    grace,3.5,1 mallory,4,2.5 > grades.csv
printf '%s\n' '# the settings of the exam server' port=8080 '# host=localhost' \
    host=0.0.0.0 debug=true users=ana,bob,carol > settings.conf
cat > stock.json << 'END'
[
  {"name": "keyboard", "price": 120, "qty": 4},
  {"name": "mouse", "price": 45, "qty": 10},
  {"name": "monitor", "price": 900, "qty": 0},
  {"name": "cable", "price": 12, "qty": 30},
  {"name": "webcam", "price": 250, "qty": 2}
]
END
```

When you are done with all the challenges, remove everything with `rm -rf ~/exam`.

35. **The busiest addresses**: Find who uses the server most, and how much it sends.
    <small>→ [Filters](#filters) · [Computing: `awk`](#computing-awk)</small>

    With **one** pipeline for each:

    1. print the 3 addresses with the most requests, each with its number of requests, the busiest first;
    2. print the total number of bytes that the server sent;
    3. print the number of bytes sent to `10.0.0.12`.

    <details className="reveal">
    <summary>Check</summary>

    1. The output is exactly:

       ```text
             6 10.0.0.9
             4 10.0.0.7
             3 10.0.0.5
       ```

    2. `1486950`.
    3. `739123`.

    </details>

36. **Who guesses passwords**: A failed login is a `POST` request for `/login` that ends with `401`. Find the addresses
    that failed to log in at least 3 times, and how busy the server was in every hour.
    <small>→ [Computing: `awk`](#computing-awk) · [Cutting Columns: `cut`](#cutting-columns-cut)</small>

    1. print every address with at least 3 failed logins, with its number of failures;
    2. print the number of requests of every hour, in the order of the hours.

    <details className="reveal">
    <summary>Check</summary>

    1. Exactly `      3 10.0.0.9` (`10.0.0.5` failed only once).
    2. The output is exactly:

       ```text
             8 10
             6 11
             3 12
       ```

    </details>

37. **Car plates**: Keep only the valid car plates of `plates.txt`, with **one** `grep` and **one** regular expression.
    <small>→ [Extended Regular Expressions](#extended-regular-expressions)</small>

    A valid plate has, separated by single spaces:

    - the county: `B` (Bucharest), or two capital letters;
    - a number: 2 or 3 digits for `B`, exactly 2 digits for the other counties;
    - three capital letters.

    Nothing else may be on the line.

    <details className="reveal">
    <summary>Check</summary>

    - The command prints exactly `B 123 ABC`, `B 12 XYZ`, `IF 07 UPB` and `TM 05 LNX`;
    - the same command with `-c` prints `4`.

    </details>

38. **The final grades**: `grades.csv` has, for every student, the grade of the lab and the grade of the exam. The
    final grade is their sum. A student passes with a final grade of at least `5` **and** an exam grade of at least
    `2.5`.
    <small>→ [Computing: `awk`](#computing-awk) · [Sorting: `sort`](#sorting-sort)</small>

    With **one** pipeline, print the name and the final grade of every student who passed, the largest grade first.

    <details className="reveal">
    <summary>Check</summary>

    - The output is exactly `dave 9.5`, `ana 8`, `carol 7` and `mallory 6.5`;
    - `grace` (`4.5`), `bob` and `erin` are not printed.

    </details>

39. **The stock of the shop**: `stock.json` has the products of a shop, with their price and their quantity. Report
    the value of the stock: the price times the quantity.
    <small>→ [Filters](#filters) · [Sorting: `sort`](#sorting-sort)</small>

    1. with **one** pipeline, print the name and the value of every product in stock (a quantity larger than `0`), the
       largest value first, as a table with the columns aligned by `column`;
    2. print the total value of the stock, as one number.

    <details className="reveal">
    <summary>Check</summary>

    1. The output is exactly:

       ```text
       webcam    500
       keyboard  480
       mouse     450
       cable     360
       ```

    2. `1790`.

    </details>

40. **Predict the exit codes**: Predict what each line prints and its exit codes, then prove each answer.
    <small>→ [Exit Codes](#exit-codes) · [Chaining Commands](#chaining-commands--and-) · [How a Pipeline Runs](#how-a-pipeline-runs)</small>

    In `~/exam`, **first** fill in the table on paper; then run each line, followed by `echo $?`, or by
    `echo "${PIPESTATUS[@]}"` for lines 4 and 6:

    | Line                                                                       | Prints | Exit code(s) |
    | -------------------------------------------------------------------------- | ------ | ------------ |
    | 1. `grep -c ' 404 ' web.log`                                               |        |              |
    | 2. `grep -c ' 500 ' web.log`                                               |        |              |
    | 3. `grep -q ' 500 ' web.log && echo yes \|\| echo no`                      |        |              |
    | 4. `cut -d' ' -f1 web.log nope.log \| sort -u \| wc -l`                    |        |              |
    | 5. the same line, after `set -o pipefail`                                  |        |              |
    | 6. `yes \| head -n 1 > /dev/null`                                          |        |              |
    | 7. `mkdir -p backup && cp nope.log backup/ && echo saved \|\| echo failed` |        |              |

    Turn `pipefail` off after line 5.

    <details className="reveal">
    <summary>Check</summary>

    |     | Prints                          | Exit code(s)                                           |
    | --- | ------------------------------- | ------------------------------------------------------ |
    | 1.  | `4`                             | `0`                                                    |
    | 2.  | `0`                             | `1`: `grep` found nothing, even if it printed a number |
    | 3.  | `no`                            | `0`, the exit code of `echo no`                        |
    | 4.  | an error of `cut`, then `5`     | `1 0 0`: `cut` failed, but read `web.log`              |
    | 5.  | an error of `cut`, then `5`     | `1`                                                    |
    | 6.  | nothing                         | `141 0`: `yes` got `SIGPIPE`                           |
    | 7.  | an error of `cp`, then `failed` | `0`, the exit code of `echo failed`                    |

    </details>

41. **Configure with `vim`**: Change `settings.conf` with `vim` only, without retyping the lines that stay.
    <small>→ [`vim`](#vim)</small>

    At the end, the file must have exactly these lines, in this order:

    ```text
    port=80
    host=0.0.0.0
    debug=false
    users=ana,bob,carol,dave
    timeout=30
    ```

    <details className="reveal">
    <summary>Hint</summary>

    In `vim`, `:help :g` explains how to run a command, like `d`, on every line that matches a regex; `:help A`
    explains how to add text at the end of a line.

    </details>

    <details className="reveal">
    <summary>Check</summary>

    - `cat -A settings.conf` prints the 5 lines, each ending with `$`, with no spaces before the `$` and no empty
      lines.

    </details>

## Wrap-up Questions

Use the **last 5 minutes** of the lab to answer these questions together with your colleagues and the teaching
assistant. There are no wrong answers for the last two.

1. What is a **filter**? Why can the output of any filter be the input of any other one?
2. Why does `uniq` need `sort` before it? Why does `sort` put `100` before `2`, and how do you fix it?
3. What is the difference between `*` in a **glob** and `*` in a **regular expression**? Why do you put a regex
   between single quotes?
4. When do you use `cut`, and when `awk`? What happens to `cut` when the fields are separated by several spaces?
5. What is the difference between `tr` and `sed`?
6. What does the **exit code** `0` mean? What do `&&` and `||` do with it?
7. Which exit code does a pipeline have? What can it hide?
8. How do you quit `vim` without saving?
9. Which filter surprised you most today?
10. Which editor will you use from now on, and why?
