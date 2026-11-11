#!/usr/bin/env python3
"""Build the interactive page of lecture 03 (Processes).

    python3 interactive/build_03.py
writes website/static/courses/03-processes/index.html
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa
from page import F, Course, flash as flash_cards, render, REPO
import page as _page

OUT = os.path.join(REPO, "website/static/courses/03-processes/index.html")
COURSE = Course()
chapter = COURSE.chapter


def img(path, alt, width=900):
    return _page.img("slides/src/03_processes/img", path, alt, width)


def term(cmds=(), missions=None, title=None, side="tree", cwd="~"):
    """a demo terminal with the files of lecture 03"""
    a = f' data-profile="03" data-side="{side}" data-cwd="{E(cwd)}"'
    if cmds:
        a += f' data-cmds="{E("|".join(cmds))}"'
    if missions:
        a += f' data-missions="{missions}"'
    if title:
        a += f' data-title="{E(title)}"'
    return f'<div data-w="shell"{a}></div>'


def fdtab(name, rows):
    """a File Descriptor Table like the slides: [(fd, points to, changed)]"""
    std = ["stdin", "stdout", "stderr"]
    tr = "".join(f'<tr class="{"ch" if ch else ""}"><td>{fd}</td><td>{std[fd] if fd < 3 else "opened"}</td><td>→ {md(to)}</td></tr>' for fd, to, ch in rows)
    return f'<div class="fdp fdstatic"><div class="fdh"><b>{E(name)}</b> · File Descriptor Table</div><table class="fdt">{tr}</table></div>'


STD = [(0, "keyboard", False), (1, "display", False), (2, "display", False)]

# ---------------------------------------------------------------- 01 packages
page = chapter("packages", "Installing applications", "Packages, repositories, `dnf` and `apt`", 12)
page("repos", "App repositories", "The Linux app store, long before the app stores", F(r"""
{why("Every program you use in the labs is installed from the repository of your distribution. Knowing what a package and a dependency are explains why `apt` asks for `sudo`, why it installs ten packages for one, and why removing a program leaves others behind.")}
{ul("applications come as **packages**: the program, its files and the list of packages it needs (*dependencies*)",
    "the distribution keeps them in a **repository**: a server with thousands of checked and signed packages",
    "the **package manager** searches, downloads, installs, updates and removes them, dependencies included")}
<div class="trio">
<div class="panel"><h3>🌐 Repository</h3><p class="cap"><code>cowsay</code>, <code>git</code>, <code>firefox</code> ... and what each one needs: <code>cowsay</code> → <code>perl</code>, <code>firefox</code> → <code>gtk3</code>. Checked and signed by the distribution.</p></div>
<div class="panel"><h3>⚙️ Package manager</h3><p class="cap">Fedora: <code>dnf</code>, packages <code>.rpm</code>. Ubuntu: <code>apt</code>, packages <code>.deb</code>. Search, download, check, install, update, remove.</p></div>
<div class="panel"><h3>💻 Your system</h3><p class="cap">After <code>install cowsay</code>: <code>cowsay</code> and its dependency <code>perl</code>.</p></div>
</div>
<div class="duo top"><div>
<h3>Fedora: <code>dnf</code></h3>
{sh('''$ dnf search cowsay
Matched fields: name (exact)
 cowsay.noarch     Configurable speaking/thinking cow
$ sudo dnf install cowsay
Package Arch   Version        Repository      Size
Installing:
 cowsay noarch 0:3.8.4-5.fc44 fedora      80.5 KiB
Is this ok [y/N]: y''')}
</div><div>
<h3>Ubuntu: <code>apt</code></h3>
{sh('''$ apt search cowsay
cowsay/noble 3.03+dfsg2-8 all
  configurable talking cow
$ sudo apt install cowsay
The following NEW packages will be installed:
  cowsay libgdbm-compat4t64 libgdbm6t64 libperl5.38t64
  libtext-charwidth-perl netbase perl perl-modules-5.38
Do you want to continue? [Y/n] y''')}
</div></div>
{note("Why `sudo`", "Installing changes the system for **all** the users, so it needs the administrator. The package manager shows what it will install and asks before it starts. `noble` is the name of Ubuntu 24.04.", "blue")}
"""))

page("deps", "Dependencies are packages too", "`cowsay` needs `perl`", F(r"""
<div class="duo top"><div>
{sh('''$ which cowsay perl
/usr/games/cowsay
/usr/bin/perl
$ perl -e 'print "hello from perl\n"'
hello from perl
$ sudo apt remove cowsay
The following packages will be REMOVED:
  cowsay''')}
</div><div>
{ul("`cowsay` is written in Perl: `apt` installed both", "`perl` is a normal package: you, or any other program, can use it **by itself**", "removing `cowsay` does **not** remove `perl`; `sudo apt autoremove` removes the dependencies nothing needs anymore")}
</div></div>
<h2>Cheat sheet</h2>
{table(["", "Fedora", "Ubuntu"], [
    ("search", "`dnf search NAME`", "`apt search NAME`"), ("details", "`dnf info NAME`", "`apt show NAME`"),
    ("install", "`sudo dnf install NAME`", "`sudo apt install NAME`"), ("remove", "`sudo dnf remove NAME`", "`sudo apt remove NAME`"),
    ("remove unused dependencies", "`sudo dnf autoremove`", "`sudo apt autoremove`"),
    ("update everything", "`sudo dnf upgrade`", "`sudo apt update` then `sudo apt upgrade`")])}
{note("`apt update` is not an upgrade", "`apt update` only refreshes the **list** of packages; `apt upgrade` installs the new versions. `dnf` refreshes the list by itself.", "warn")}
{quiz("You removed `cowsay`. Is `perl` still installed?", ["no, `apt` removes the dependencies with it", "yes, until `sudo apt autoremove` removes it (if nothing else needs it)", "only if you installed it before `cowsay`", "no, `perl` was part of the `cowsay` package"], 1,
      "Dependencies are separate packages. `remove` takes out only the package you name; `autoremove` cleans the dependencies no installed package needs.")}
"""))

# ---------------------------------------------------------------- 02 process
page = chapter("process", "Programs and processes", "From a file to an action: loading, PID, resources", 14)
page("program", "Executable vs. process", "Files to actions", F(r"""
{why("The operating system offers two abstractions: **files** for data and **processes** for actions. Every command you type becomes a process; most of the tools in this lecture (`ps`, redirects, `/proc`) look at or change one.")}
<div class="duo top"><div>
{ul("an **executable** is a file on the disk: `/bin/ls`", "a **process** is a running instance of it, with its own memory, open files and PID",
    "one executable can run as **many processes** at the same time: three terminals running `bash` are three processes of `/usr/bin/bash`",
    "peripherals are files too (POSIX): `/dev/sda` the first disk, `/dev/input/...` the keyboard, `/dev/fb0` the screen")}
</div><div>{fig(img("process/program-proc.pdf", "One executable, several processes", 700), "one executable file, several processes")}</div></div>
{fig(img("os/abstractions.pdf", "The abstractions of the operating system", 900), "applications (processes, with threads) on top of the kernel, which hides the processor, the memory and the devices")}
"""))

page("loading", "Loading an executable", "The loader", F(r"""
{fig(img("process/loader-actions.pdf", "The steps of the loader", 900))}
<div data-w="loader"></div>
{steps("**program loading**: the loader reads the executable and copies its code and data into memory",
       "**library loading**: it finds the libraries the program needs (`libc.so.6`, ...) and loads them too",
       "**runtime dynamic linking**: it connects the calls of the program to the functions inside the libraries",
       "**execution**: the processor jumps to the start of the program; the code of the program and of the libraries runs")}
<p class="txt">An executable file holds three things: how to load it, the actual code, and the links to the libraries it needs.</p>
"""))

page("resources", "What a process has", "PID, PPID, threads, files, memory", F(r"""
<div class="duo top"><div>
{table(["", "Resource"], [
    ("🪪 identification", "**PID** (Process ID), **PPID** (the PID of its parent)"),
    ("⚙️ actions", "one or more **threads**, running in parallel"),
    ("💾 data", "open files: real files and devices (`/dev/...`)"),
    ("🧠 memory", "the code and the variables")])}
{sh('''$ echo $$  # the PID of the shell
4100
$ ps -o pid,ppid,comm
    PID    PPID COMMAND
   4100    4090 bash
   4301    4100 ps''')}
<p class="small"><code>ps</code> is a child of the shell: its PPID is the PID of <code>bash</code>.</p>
</div><div>{fig(img("process/process_resources.pdf", "The resources of a process", 600))}</div></div>
{quiz("You open three terminals and run `bash` in each. How many `bash` executables and how many `bash` processes are there?",
      ["3 executables, 3 processes", "1 executable, 3 processes", "1 executable, 1 process with 3 threads", "3 executables, 1 process"], 1,
      "There is one file, `/usr/bin/bash`. Each terminal starts its own process from it, with its own PID.")}
"""))

# ---------------------------------------------------------------- 03 states
page = chapter("states", "Process states", "Ready, Running, Waiting, Done and the `ps` letters", 12)
page("states", "Process states", "From Ready to Done", F(r"""
{why("Most processes spend their life *waiting*: for you to type, for the disk, for the network. The state explains why a computer with 300 processes is not slow, and what the `R`, `S` and `Z` in `ps` mean.")}
<div data-w="states"></div>
<div class="duo top"><div>
{table(["State", "Meaning", "ps"], [
    ("Ready", "has everything it needs, waits for a free **processor**", "`R`"),
    ("Running", "its code runs; when its *time slice* ends it goes back to Ready", "`R`"),
    ("Waiting", "waits for an **event**: disk data, a key, a network packet; it does not use the processor", "`S`"),
    ("Done", "has finished (`exit`), waits for the parent to read its *exit code*", "`Z`")])}
</div><div>
{sh('''$ ps -e -o pid,stat,comm
    PID STAT COMMAND
      1 Ss   systemd
   4100 Ss   bash
   4210 S    sleep
   4211 R    yes
   4213 Sl   myapp
   4214 Z    myapp-worker <defunct>
   4220 R+   ps''')}
<p class="small"><code>bash</code> waits for you to type, <code>sleep</code> for its timer; <code>yes</code> computes all the time. The other letters: <code>s</code> session leader, <code>l</code> several threads, <code>+</code> in the foreground.</p>
</div></div>
{quiz("`ps` shows `S` for a text editor you are not typing in. Is something wrong?", ["yes, it is stuck", "no, it waits for a key press and uses no processor", "yes, it should be `R`", "no, `S` means it is a system process"], 1,
      "`S` is sleeping: waiting for an event. An idle program should sleep; an `R` that never changes is a process that computes all the time.")}
"""))

# ---------------------------------------------------------------- 04 fork / exec
page = chapter("fork", "fork and exec", "How a process is created, how Linux starts", 14)
page("fork-exec", "Creating a process", "`fork`, `exec`, `exit`, `wait`", F(r"""
{why("Every process except the first one is created by another process. The shell runs each command with the same four calls, so redirects, the PPID and zombies all come from this mechanism.")}
<div class="duo top r"><div>
{steps("the parent calls `fork`: it makes a **clone** of itself, from now on there are **two identical processes**",
       "the child calls `exec`: it **replaces** its executable with another one (same PID)",
       "the child eventually calls `exit` (or returns from `main`) with an *exit code*",
       "the parent does other work or **waits**; it calls `wait` to read the exit code of the child")}
</div><div>{fig(img("process/fork-exec.pdf", "fork, exec, exit, wait", 420))}</div></div>
<div data-w="fork" data-sc="normal"></div>
{quiz("After `fork`, which of these is **different** in the child?", ["the code", "the open files (0, 1, 2)", "the PID", "the current directory"], 2,
      "The child is a clone: same code, same open files, same current directory. It gets a new PID, and its PPID is the PID of the parent.")}
"""))

BOOT = """[kernel]  interrupt handler / scheduler
│
├── [PID 1]  systemd (init)
│     ├── [PID 3+]  systemd-udevd           devices (USB, disks)
│     ├── [PID 5+]  NetworkManager          network interfaces
│     ├── [PID 8+]  gdm / sddm / lightdm    graphical login
│     └── [PID 10+] user@1000.service       your services, after login
│             ├── [PID 11+] bash / zsh / fish
│             ├── [PID 12+] Xorg / Wayland
│             └── [PID 13+] gnome-shell / plasma / sway
└── [PID ...]  kernel threads (kthreadd, kworker, ...)"""
page("boot", "How Linux starts", "The first process", F(r"""
<div class="duo top w14"><div>{tree(BOOT, here=(3,))}</div><div>
{ul("the kernel starts **one** user-space process, `init`, with **PID 1**; on most distributions it is `systemd`",
    "`init` starts the services: devices, network, the login screen, then your session",
    "every other process descends from it: `pstree` shows the whole family",
    "the kernel also runs its own threads (`kthreadd`, `kworker`), shown in brackets in `ps`")}
{note("`init` cannot stop", "If PID 1 ends, the kernel *panics*: the whole system stops. The next chapter shows why.", "warn")}
</div></div>
{sh('''$ pstree -p
systemd(1)
├─systemd-udevd(512)
├─NetworkManager(640)
└─systemd(1000)
  └─gnome-terminal-(4090)
    └─bash(4100)
      └─pstree(4301)''')}
"""))

# ---------------------------------------------------------------- 05 orphans and zombies
page = chapter("orphan", "Orphans and zombies", "When the parent ends first, or never waits", 10)
page("orphan", "Orphan processes", "The parent ends first", F(r"""
{ul("when a parent ends, its children keep running without a parent: they are **orphans**",
    "the kernel **reparents** them to `init` (PID 1): their PPID becomes 1",
    "`init` calls `wait` for them when they end")}
<div data-w="fork" data-sc="orphan"></div>
"""))
page("zombie", "Zombie processes", "The parent never calls wait", F(r"""
{ul("a process that has finished stays **Done** until its parent reads its exit code with `wait`",
    "meanwhile the system keeps its PID and its entry in the process table: allocated, but not used, a 🧟 **zombie** (`Z`, `<defunct>` in `ps`)",
    "a zombie cannot be killed: it is already dead; only its parent calling `wait`, or the parent ending, removes it")}
<div data-w="fork" data-sc="zombie"></div>
{note("🐧 + 🧟 = 🛑", "Without `init` there is nobody to adopt orphans and nobody to `wait` for them: the system would fill with zombies. Linux does not allow it: it panics when `init` stops.", "warn")}
{quiz("`ps` shows hundreds of `<defunct>` processes with the same PPID. Whom do you fix?", ["the zombies, with `kill`", "the parent: it never calls `wait`", "`init`, it should adopt them", "nothing, they use no resources"], 1,
      "Zombies are already dead, `kill` does nothing to them. Their parent forgets to read the exit codes; when it ends, `init` adopts and reaps them.")}
"""))

# ---------------------------------------------------------------- 06 fd
page = chapter("fd", "File descriptors", "How a process reads and writes", 14)
page("table", "The File Descriptor Table", "How processes access data", F(r"""
{why("A process never writes *to the display* or reads *from the keyboard* by name: it writes to `1` and reads from `0`. The shell decides what those numbers point to, and that is the whole trick behind redirects and pipes.")}
<div class="duo top"><div>
{ul("each process has a **File Descriptor Table**", "every open file has an entry; the **index** in the table is the *file descriptor*", "a new file goes at the first free index")}
{table(["fd", "name", "points to, by default"], [("`0`", "`stdin`", "the keyboard"), ("`1`", "`stdout`", "the display"), ("`2`", "`stderr`", "the display, for errors")])}
</div><div>{fig(img("fd/file_descriptor_table.pdf", "The File Descriptor Table of a process", 600))}</div></div>
"""))
page("sort", "`sort` opens a file", "The process opens the file by itself", F(r"""
<div class="duo top"><div>
{sh('''$ cat fruits.txt
cherry
apple
banana
$ sort fruits.txt  # the file name is an argument
apple
banana
cherry''')}
{steps("the shell starts `sort` with `0`, `1` and `2`, and gives it `fruits.txt` as an *argument*",
       "`sort` calls `open(\"fruits.txt\")`; the kernel places it at the first free index: `3`",
       "`sort` reads the lines from `3`, sorts them and writes them to `1`; the keyboard (`0`) is not used")}
</div><div>{fdtab("sort fruits.txt", STD + [(3, "`fruits.txt`", True)])}</div></div>
{term(["cat fruits.txt", "sort fruits.txt", "wc -l fruits.txt", "ls -l /proc/self/fd"], missions="fd", side="fd", title="Try it: the table of every command")}
"""))

# ---------------------------------------------------------------- 07 redirects
page = chapter("redirects", "Redirects", "`<`, `>`, `>>`, `2>`, `&>`", 18)
page("in", "`<`: redirect stdin", "A file replaces the keyboard", F(r"""
<div class="duo top"><div>
{sh('''$ sort  # reads the keyboard, until Ctrl+D
$ sort < fruits.txt  # reads fruits.txt
apple
banana
cherry''')}
{ul("without a file name `sort` reads `0`, the keyboard", "with `< fruits.txt` the **shell** opens the file and puts it at `0` before it starts `sort`", "`sort` does not know: it reads `0`, as always")}
</div><div>{fdtab("sort < fruits.txt", [(0, "`fruits.txt`", True), (1, "display", False), (2, "display", False)])}</div></div>
{bad("`sort fruits.txt` and `sort < fruits.txt` are the same", "The output is, the mechanism is not. With an argument, `sort` opens the file itself (at `3`) and knows its name; with `<` the shell opens it at `0` and `sort` only sees a stream. That is why `wc -l fruits.txt` prints the name and `wc -l < fruits.txt` does not.", "use `<` for commands that only read `stdin`, or when the name must not appear.")}
{term(["sort < fruits.txt", "wc -l < unsorted.txt", "sort"], missions="redir-in", side="fd", title="Try it: <")}
"""))
page("out", "`>` and `>>`: redirect stdout", "The display is replaced by a file", F(r"""
<div class="duo top"><div>
{sh('''$ ls > files.txt  # nothing on the display
$ cat files.txt
Movies
notes.txt
todo.txt
$ echo one > log.txt  # empty the file, then write
$ echo two >> log.txt  # write at the end
$ cat log.txt
one
two''')}
</div><div>{fdtab("ls > files.txt", [(0, "keyboard", False), (1, "`files.txt`", True), (2, "display", False)])}
{table(["", "the shell opens the file with", "writes go"], [("`>`", "`O_WRONLY | O_CREAT | O_TRUNC`", "after the file is **emptied**"), ("`>>`", "`O_WRONLY | O_CREAT | O_APPEND`", "at the **end**, always")])}
</div></div>
{note("`>` empties the file first", "Even before the command runs: `sort fruits.txt > fruits.txt` leaves an empty file, because the shell truncates `fruits.txt` before `sort` reads it. Use `>>` for logs, so every command adds its lines.", "warn")}
"""))
page("err", "`2>`: redirect stderr", "Errors into a file", F(r"""
<div class="duo top"><div>
{sh('''$ ls /nope  # the error is on the display
ls: cannot access '/nope': No such file or directory
$ ls /nope 2> errors.txt  # nothing shows up
$ ls /nada 2>> errors.txt  # append the error
$ ls /etc /nope > all.txt 2>&1  # both, into one file
$ ls /etc /nope &> all.txt  # the same, shorter''')}
</div><div>{fdtab("ls /nope 2> errors.txt", [(0, "keyboard", False), (1, "display", False), (2, "`errors.txt`", True)])}
{ul("only `1` (`stdout`) changes with `>`; errors still reach the display through `2`", "`> out.txt 2> errors.txt` separates them", "`2>&1` makes `2` point where `1` points **now**: write it after `> all.txt`")}
</div></div>
{term(["ls /etc", "ls /nope", "cat errors.txt", "ls -l"], missions="redir-out", side="fd", title="Try it: > >> 2> &>")}
"""))
page("cheat", "Redirects cheat sheet", "Trick processes about the keyboard and the display", F(r"""
{table(["Redirect", "Example", "What it does"], [
    ("`>`", "`ls > files.txt`", "stdout into a file, emptied first"), ("`>>`", "`ls >> files.txt`", "stdout at the end of a file"),
    ("`2>`", "`ls /nonexistent 2> errors.txt`", "only the errors into a file"), ("`> f 2>&1`", "`ls /etc /nope > all.txt 2>&1`", "stdout and stderr into the same file"),
    ("`&>`", "`ls /etc /nope &> all.txt`", "the same, shorter (bash)"), ("`<`", "`sort < input.txt`", "stdin from a file"),
    ("`< a > b`", "`sort < unsorted.txt > sorted.txt`", "both at once"), ("`> /dev/null 2>&1`", "`command > /dev/null 2>&1`", "run silently, discard everything"),
    ("`2>&1 |`", "`command 2>&1 | grep warning`", "merge both streams, then search them")], "k")}
<h3>Heredoc</h3>
{sh('''$ cat <<EOF
Hello, world!
This is a heredoc example.
EOF''')}
<p class="small">The lines up to <code>EOF</code> are sent <em>as they are</em> to <code>stdin</code>; a <code>#</code> there is not a comment. (The demo terminal does not do heredocs.)</p>
"""))

# ---------------------------------------------------------------- 08 pipes and devices
page = chapter("pipes", "Pipes and special files", "`|`, `/dev/null`, `/dev/zero`, `/dev/urandom`", 14)
page("pipe", "`|`: pipe", "The stdout of one process is the stdin of the next", F(r"""
<div class="duo top"><div>
{steps("the shell creates a *pipe*: a buffer in the kernel with a write end and a read end",
       "it starts `ls` with the **write end** at index `1`", "it starts `wc` with the **read end** at index `0`",
       "both run **at the same time**: `wc` reads what `ls` writes, until `ls` ends (*end of file*)")}
{sh('''$ ls
Movies  notes.txt  todo.txt
$ ls | wc -l
3''')}
<p class="small">No temporary file is used. <code>ls</code> prints one name per line when its <code>1</code> is not a terminal.</p>
</div><div>{fdtab("ls", [(0, "keyboard", False), (1, "pipe (write end)", True), (2, "display", False)])}<div class="pipeline">│ pipe ▼</div>{fdtab("wc -l", [(0, "pipe (read end)", True), (1, "display", False), (2, "display", False)])}</div></div>
{term(["ls | wc -l", "sort unsorted.txt | uniq -c", "cat fruits.txt | grep an", "ls /nope 2>&1 | grep cannot"], missions="pipe", side="fd", title="Try it: pipes")}
"""))
page("devices", "Special files", "Devices made by the kernel", F(r"""
<div class="trio">
<div class="panel"><h3>🕳️ <code>/dev/null</code></h3><p class="cap">everything <b>written</b> is discarded; <b>reading</b> gives end of file right away. <code>ls /nope 2&gt; /dev/null</code> hides the error.</p></div>
<div class="panel"><h3>0️⃣ <code>/dev/zero</code></h3><p class="cap"><b>reading</b> gives as many <code>0</code> bytes as asked; writes are discarded.</p></div>
<div class="panel"><h3>🎲 <code>/dev/urandom</code></h3><p class="cap"><b>reading</b> gives as many random bytes as asked: keys, passwords, random names.</p></div>
</div>
{sh('''$ xxd -l 8 < /dev/zero  # the first 8 bytes
00000000: 0000 0000 0000 0000                      ........
$ xxd -l 8 < /dev/urandom  # different every time
00000000: 9f3a 51c2 07e8 b4d1                      .:Q.....
$ ls -l /dev/null /dev/zero /dev/urandom
crw-rw-rw- 1 root root 1, 3 Oct 12 09:12 /dev/null
crw-rw-rw- 1 root root 1, 5 Oct 12 09:12 /dev/zero
crw-rw-rw- 1 root root 1, 9 Oct 12 09:12 /dev/urandom''')}
{ul("`c`: *character devices*, not files: nothing is stored on the disk", "`1, 3`: the *driver* (major `1`) and the device (minor `3`) that answer the `read`")}
{term(["ls /nope 2> /dev/null", "cat < /dev/null", "xxd -l 8 < /dev/zero", "xxd -l 8 < /dev/urandom"], missions="dev", side="fd", title="Try it: /dev")}
"""))

# ---------------------------------------------------------------- 09 links
page = chapter("links", "Soft links", "Shortcuts to files and folders", 16)
page("shortcut", "A shortcut", "`ln -s`", F(r"""
{why("Links are everywhere in a Linux system: `/bin` is a link to `/usr/bin` on modern distributions, `/proc/self` is a link, and most configuration of services is turned on by creating one.")}
{syn("ln -s {a:TARGET} {b:LINK_NAME}")}
<div class="duo top"><div>
{sh('''$ ln -s notes.txt shortcut.txt  # create the link
$ ls -l
-rw-r--r-- 1 student student 18 Oct 12 09:12 notes.txt
lrwxrwxrwx 1 student student  9 Oct 12 09:15 shortcut.txt -> notes.txt
$ cat shortcut.txt  # reads notes.txt
buy milk
call mom
$ readlink shortcut.txt
notes.txt''')}
</div><div>
{ul("`ln -s` creates a **soft link** (*symbolic link*): a shortcut to `TARGET`", "`l`: the type is *link*, `ls -l` shows where it points", "the link does **not** hold the data, it holds a **path**: its size is `9`, the length of `notes.txt`", "the target can be a file or a folder, the path absolute (`/usr/share/doc`) or relative")}
</div></div>
<h2>Following links</h2>
<div class="duo top"><div>
{sh('''$ ln -s shortcut.txt link.txt  # a link to a link
$ cat link.txt
buy milk
call mom
$ ln -s /usr/share/doc docs
$ ls docs/  # into the folder
bash  git''')}
</div><div>
{ul("a link can point to **another link**: the kernel follows them all, until it finds a real file", "a link to a folder works like the folder: `ls`, `cd`", "a loop (`a -> b`, `b -> a`) never reaches a file: *Too many levels of symbolic links*", "`ls -l`, `readlink` and `rm` do **not** follow: they work on the link itself")}
</div></div>
{term(["ls -l", "ln -s notes.txt shortcut.txt", "ls -l", "readlink shortcut.txt", "ln -s a b", "ln -s b a", "cat a"], missions="links", title="Try it: soft links")}
"""))
page("broken", "Broken links and relative paths", "Where the path starts", F(r"""
<div class="duo top"><div>
{sh('''$ rm notes.txt  # delete the target
$ ls -l shortcut.txt
lrwxrwxrwx 1 student student 9 Oct 12 09:15 shortcut.txt -> notes.txt
$ cat shortcut.txt
cat: shortcut.txt: No such file or directory''')}
</div><div>{ul("deleting the target does **not** delete the links to it", "the link still holds its path, but nothing is there: the link is **broken**", "`ln -s` does not check that the target exists")}</div></div>
<h2>A relative target starts from the folder of the link</h2>
<div class="duo top"><div>
{sh('''$ cd /home/student
$ ln -s notes.txt backup/wrong.txt  # from backup/
$ cat backup/wrong.txt
cat: backup/wrong.txt: No such file or directory
$ ln -s ../notes.txt backup/right.txt  # go up
$ cat backup/right.txt
buy milk''')}
</div><div>
{tree('''/home/student
├── notes.txt
└── backup
    ├── wrong.txt -> notes.txt
    └── right.txt -> ../notes.txt''', gone=(4,), new=(5,), caption="`wrong.txt` looks for `backup/notes.txt`")}
{note("Write a relative target as if you were in the folder of the link", "Not from your current directory: the kernel resolves the path when the link is *used*, starting from where the link is.", "warn")}
</div></div>
<h2>Moving links</h2>
{table(["you move", "relative link (`rel.txt -> notes.txt`)", "absolute link (`abs.txt -> /home/student/project/notes.txt`)"], [
    ("the **link** alone, to another folder", "breaks: the path now starts from the new folder", "still works"),
    ("the whole **folder**, link and target together", "still works: they moved together", "breaks: it points to the old place")])}
<p class="txt"><em>Relative</em> links for files that travel together (a project, an archive); <em>absolute</em> links for files that stay in place (<code>/usr/share/doc</code>, <code>/etc/...</code>).</p>
{quiz("You run `ln -s notes.txt backup/n.txt` from your home directory, where `notes.txt` is. Does `cat backup/n.txt` work?", ["yes, `notes.txt` is in the current directory", "no, the link looks for `backup/notes.txt`", "yes, `ln` stores the absolute path", "no, links to files in another folder are not allowed"], 1,
      "The target is stored exactly as you typed it and resolved from the folder of the link, `backup/`. The right target is `../notes.txt`.")}
"""))

# ---------------------------------------------------------------- 10 /proc
page = chapter("proc", "The /proc folder", "Look inside the processes", 14)
page("proc", "`/proc`: the process file system", "Virtual files made by the kernel", F(r"""
<div class="duo top"><div>
{tree('''/proc
├── 1         systemd
├── 4100      bash
├── 4321      ...
├── self      -> the process that reads it
├── cpuinfo
├── meminfo
├── uptime
└── ...''')}
</div><div>
{sh('''$ ls -l /proc/uptime  # the size is 0
-r--r--r-- 1 root root 0 Oct 12 09:12 /proc/uptime
$ cat /proc/uptime  # but it has contents
244699.78 368114.32
$ readlink /proc/self  # the PID of readlink
4325''')}
</div></div>
{ul("`/proc` is a *virtual* file system: every process has a folder named after its **PID**", "**nothing** is stored on the disk: the kernel writes the contents when a process **reads** the file", "`/proc/self` is the folder of the process that reads it: `ls /proc/self` lists the folder of `ls`")}
"""))
page("pid", "Inside a process", "`/proc/<PID>`", F(r"""
<div class="duo top"><div>
{tree('''/proc/4321
├── cmdline   the arguments
├── comm      the name
├── cwd       -> the current folder
├── environ   the environment variables
├── exe       -> the executable file
├── fd/       the File Descriptor Table
├── maps      the memory map
└── status    PID, PPID, state, ...''')}
</div><div>
{sh('''$ cat /proc/self/status
Name:     cat
State:    R (running)
Pid:      4330
PPid:     4100
Threads:  1
$ echo $$  # the PID of the shell
4100
$ ls -l /proc/self/fd
lrwx------ 1 student student 64 Oct 12 09:12 0 -> /dev/pts/0
lrwx------ 1 student student 64 Oct 12 09:12 1 -> /dev/pts/0
lrwx------ 1 student student 64 Oct 12 09:12 2 -> /dev/pts/0
lr-x------ 1 student student 64 Oct 12 09:12 3 -> /proc/4331/fd''')}
</div></div>
{ul("the `PPid` of `cat` is the shell: the shell called `fork` and `exec` to start it",
    "`0`, `1` and `2` point to `/dev/pts/0`, the terminal: it is both the keyboard and the display",
    "`ls` opened the folder it lists at the first free index, `3`; a redirect changes these links: with `> out.txt`, `1` points to `out.txt`",
    "`ps`, `top`, `pstree` and `lsof -p PID` do not ask the kernel directly: they **read** `/proc`; only the owner (or `root`) can look inside `fd/`")}
{term(["echo $$", "cat /proc/self/status", "ls -l /proc/self/fd", "ls -l /proc/self/fd > out.txt", "cat out.txt", "ps -e -o pid,stat,comm", "pstree -p", "head -3 /proc/meminfo"], missions="proc", side="fd", title="Try it: /proc")}
"""))

# ---------------------------------------------------------------- 11 flashcards
FLASH = [
    ("01", "Packages", "packages/repos", "Software comes from the repository of the distribution", "The package manager (`dnf`, `apt`) downloads checked and signed packages; it needs `sudo` because it changes the system for everyone."),
    ("01", "Packages", "packages/deps", "Installing one package can install ten", "Dependencies are packages too. `remove` keeps them; `autoremove` cleans the ones nothing needs."),
    ("01", "Packages", "packages/deps", "`apt update` only refreshes the list", "`apt upgrade` installs the new versions; run both to update an Ubuntu system."),
    ("02", "Processes", "process/program", "One executable, many processes", "Every terminal running `bash` is a separate process of the same file, with its own PID, memory and open files."),
    ("02", "Processes", "process/resources", "Every process knows its parent", "The PPID is the PID of the process that created it; for a command you type, it is the shell."),
    ("03", "States", "states/states", "Most processes are sleeping", "`S` in `ps` means waiting for an event; it uses no processor. A process always in `R` computes all the time."),
    ("03", "States", "states/states", "`ps` cannot tell Ready from Running", "Both are `R`: the difference lasts a few milliseconds, the scheduler switches them all the time."),
    ("04", "fork / exec", "fork/fork-exec", "A command runs as fork, then exec", "The shell clones itself, the clone replaces its executable; that is why a command inherits the open files of the shell."),
    ("04", "fork / exec", "fork/boot", "PID 1 is `init`, and it cannot stop", "It starts everything else and adopts the orphans; if it ends, the kernel panics."),
    ("05", "Zombies", "orphan/zombie", "A zombie waits for its parent", "It has finished but its exit code was not read. You fix the parent, not the zombie: `kill` cannot kill what is already dead."),
    ("05", "Orphans", "orphan/orphan", "Orphans are adopted by `init`", "When a parent ends first, its children get PPID 1, and `init` calls `wait` for them."),
    ("06", "File descriptors", "fd/table", "A process reads `0` and writes `1` and `2`", "It does not know what they are: the shell decides, before the command starts."),
    ("06", "File descriptors", "fd/sort", "A file opened by the process gets the first free index", "`sort fruits.txt` opens the file at `3`; you can see it in `/proc/PID/fd`."),
    ("07", "Redirects", "redirects/out", "`>` empties the file before the command runs", "`sort f > f` leaves `f` empty. Use another file, or `>>` to append."),
    ("07", "Redirects", "redirects/err", "Errors go to `2`, not to `1`", "`> out.txt` still shows the errors; `2>` catches them, `&>` catches both."),
    ("07", "Redirects", "redirects/err", "`2>&1` copies where `1` points now", "Write it after `> file`: `> all.txt 2>&1`. Before it, `2` would stay on the display."),
    ("08", "Pipes", "pipes/pipe", "A pipe connects two processes running at the same time", "No temporary file: the kernel buffer passes the stdout of one to the stdin of the next."),
    ("08", "Special files", "pipes/devices", "`/dev/null` swallows everything", "Redirect output or errors there to silence a command; reading it gives end of file."),
    ("09", "Links", "links/shortcut", "A soft link stores a path, not the data", "Deleting the target breaks the link; deleting the link leaves the target alone."),
    ("09", "Links", "links/broken", "A relative target starts from the folder of the link", "`ln -s notes.txt backup/n.txt` points to `backup/notes.txt`; write `../notes.txt`."),
    ("10", "/proc", "proc/pid", "`/proc` is the kernel talking", "Nothing there is on disk; `ps`, `pstree` and `lsof` just read and format it."),
]
page = chapter("flashcards", "Flashcards", "The ideas of the lecture, one card each", 10)
page("recap", "The ideas, in short", "Quick recap", F(r"""
<p class="txt">One idea per card; the title is the idea, the text says why it matters in practice. <em>Recap</em> shows all the cards, <em>Flashcard</em> one at a time.</p>
{flash_cards(FLASH)}
"""))

CSS = """
.ldsteps{gap:6px;padding:12px 22px}
.lddot{border:1px solid var(--line);background:#fff;border-radius:999px;padding:5px 12px;font-size:13px;font-weight:650;color:var(--navy)}
.lddot b{display:inline-grid;place-items:center;width:18px;height:18px;border-radius:50%;background:#e6edf0;font-size:11px;margin-right:4px}
.lddot.on{background:#004d65;color:#fff;border-color:#004d65}.lddot.on b{background:#fff;color:#004d65}
.lddot.dn b{background:#00838f;color:#fff}
.ldgrid{display:grid;grid-template-columns:1fr 130px 1.4fr;gap:14px;padding:18px 22px;align-items:start}
.ldh{font-size:13px;font-weight:700;color:var(--navy);margin-bottom:8px}.ldh span{font-weight:400;color:var(--muted);margin-left:6px}
.ldpart{border:1px dashed #c4d3d8;border-radius:9px;padding:9px 12px;margin-bottom:8px;color:#9aa9ae;background:#f8fafb}
.ldpart b{display:block;font-size:14px}.ldpart span{font-size:12.5px}
.ldpart.on{border-style:solid;color:#fff}.ldpart.on.load{background:#555}.ldpart.on.code{background:#004d65}.ldpart.on.links{background:#fde5d4;color:#c2410c;border-color:#e65100}
.ldmid{display:flex;flex-direction:column;align-items:center;gap:8px;padding-top:30px;text-align:center}
.ldloader{border:2px solid #7cb342;border-radius:10px;padding:8px 10px;font-weight:700;color:#7cb342;background:#fff;opacity:.45}
.ldloader.on{opacity:1;background:#f1f8e9}
.ldarrow{font:700 12.5px "SF Mono",Menlo,monospace;color:#e65100}
.ldcpu{font-size:12.5px;font-weight:700;color:#26a6b8;border:2px solid #26a6b8;border-radius:10px;padding:6px 8px}
.ldrow{display:flex;flex-wrap:wrap;gap:2px 8px;align-items:baseline;border-left:5px solid #b8cdd4;background:#fff;border-radius:6px;padding:6px 10px;margin-bottom:6px;box-shadow:0 0 0 1px var(--line)}
.ldrow code{background:none;padding:0;font-size:12px;color:var(--muted)}.ldrow code.pm{color:#004d65;font-weight:700}
.ldrow b{font:600 13px "SF Mono",Menlo,monospace;color:var(--ink)}
.ldrow .d{flex-basis:100%;font-size:12px;color:var(--muted)}
.ldrow.px{border-left-color:#004d65}.ldrow.pd{border-left-color:#00838f}.ldrow.lb{border-left-color:#e65100}.ldrow.ld{border-left-color:#7cb342}.ldrow.st,.ldrow.hp{border-left-color:#e0a800}
.ldrow.new{box-shadow:0 0 0 2px #e65100;animation:ldin .35s ease-out}
@keyframes ldin{from{transform:translateX(12px);opacity:.5}to{transform:none;opacity:1}}
.ldgot{font-size:12px;font-weight:700;color:#c2410c;background:#fde5d4;border-radius:4px;padding:1px 6px}
.ldip{font-size:12px;font-weight:700;color:#26a6b8}
.ldempty{font-size:13px;color:var(--muted);font-style:italic;border:1px dashed var(--line);border-radius:8px;padding:10px}
.ldx{font-size:15px;color:var(--ink)}
.ldcmd{padding:0 22px 16px}
.ldcmd[hidden]{display:none}
.ldrow b{font-size:14px}
@media (max-width:980px){.ldgrid{grid-template-columns:1fr}.ldmid{flex-direction:row;padding-top:0;justify-content:center}}

.fdstatic{max-width:420px}
.st-what{font-size:15px;margin:12px 0 6px;min-height:3em}
.st-log{font-size:13px;color:var(--muted);padding-left:20px;margin:0}
.st-btns .btn{justify-content:space-between;width:100%}
.ptree{display:flex;flex-direction:column;gap:6px}
.pnode{display:flex;flex-wrap:wrap;align-items:center;gap:6px 8px;border:1px solid var(--line);border-radius:9px;padding:7px 10px;background:#fff;font-size:14px;position:relative}
.pnode .pid{font:700 12.5px "SF Mono",Menlo,monospace;color:#004d65;background:#e6edf0;border-radius:5px;padding:1px 6px}
.pnode .pst{font:700 11px system-ui,sans-serif;color:#fff;border-radius:999px;padding:2px 8px}
.pnode .ppid{font:12px "SF Mono",Menlo,monospace;color:var(--muted);margin-left:auto}
.pnode .ptag{font:700 11px system-ui,sans-serif;color:#c2410c;background:#fde5d4;border-radius:999px;padding:2px 8px}
.pnode.new,.pnode.changed{border-color:#e65100;box-shadow:0 0 0 2px #fde5d4}
.pnode.orphan{border-style:dashed;border-color:#e65100}
.fkcode{font-size:13px}.fkcode .cur{background:#fde5d4;color:#c2410c;font-weight:700;border-radius:3px}
.fkx{font-size:15px;color:var(--ink)}
"""

META = dict(
    num="03", key="iso-03-proc-v1", short="Processes",
    title="Processes, step by step · ISO Lecture 03",
    description="ISO Lecture 03 – Processes: packages, processes and their states, fork and exec, orphans and zombies, file descriptors, redirects, pipes, soft links and /proc, with a demo terminal.",
    title_html="Processes, step by step:<br><span>from a file to an action.</span>",
    lead="How programs are installed and turned into processes, what states a process goes through, and how the shell connects processes to files, devices and each other.",
    features="process simulators · demo terminal with missions",
    starth="Start with installing applications.",
    maphead="From packages to the files inside a process.",
    how="Text, figures, the simulators and the demo terminal were generated with Claude (Anthropic) from the slides of lecture 03 – Processes, following the structure of the interactive DEEA modules. The diagrams are the ones of the slides.",
    checked="The demo terminal was tested against the examples of the slides (redirects, pipes, links, /proc); its messages follow GNU coreutils and bash. Its process list and /proc are simulated.",
)

if __name__ == "__main__":
    render(COURSE, META, OUT, js=["procs.js"], css=CSS)
