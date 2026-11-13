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


def redir(*scs):
    """the step-by-step widget: what the shell does for a redirect or a pipe; the first command line is shown first"""
    return f'<div data-w="redir" data-sc="{scs[0]}" data-list="{",".join(scs)}"></div>'


# ---------------------------------------------------------------- the figures of the slides, redrawn as SVG
# the colors of the labs: blue = a process / headers, orange = active / a file, green = loader / done, red = device
NAVY, TEAL, MUTED, INK = "#004d65", "#00838f", "#5b6b71", "#1f2d33"
BLUE, ORANGE, GREEN, RED, AMBER, GREY = ("#dae8fc", "#6c8ebf"), ("#ffe6cc", "#d79b00"), ("#d5e8d4", "#82b366"), ("#f8cecc", "#b85450"), ("#fff2cc", "#d6b656"), ("#eef1f3", "#9aa9ae")
_ARROWS = {"navy": NAVY, "teal": TEAL, "orange": "#d79b00", "green": "#82b366", "red": "#b85450", "grey": "#7d8d93"}


def _t(x, y, s, size=15, w=400, fill=INK, a="middle", mono=False):
    fam = "'SF Mono',Menlo,Consolas,monospace" if mono else "system-ui,-apple-system,sans-serif"
    return f'<text x="{x}" y="{y}" text-anchor="{a}" style="font:{w} {size}px {fam}" fill="{fill}">{E(s)}</text>'


def _r(x, y, w, h, c, rx=10, sw=2, dash=False):
    d = ' stroke-dasharray="6 5"' if dash else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{c[0]}" stroke="{c[1]}" stroke-width="{sw}"{d}/>'


def _a(pts, color="navy", w=2.2, dash=False, head=True):
    d = " ".join(f"{x},{y}" for x, y in pts)
    m = f' marker-end="url(#f3-{color})"' if head else ""
    da = ' stroke-dasharray="6 5"' if dash else ""
    return f'<polyline points="{d}" fill="none" stroke="{_ARROWS[color]}" stroke-width="{w}" stroke-linejoin="round"{da}{m}/>'


def svgfig(w, h, body, label, cls=""):
    """an inline SVG at its natural size (never wider), scaled down on small screens"""
    defs = "".join(f'<marker id="f3-{k}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>' for k, c in _ARROWS.items())
    return (f'<svg class="f3 {cls}" viewBox="0 0 {w} {h}" style="max-width:{w}px" role="img" aria-label="{E(label)}">'
            f'<defs>{defs}</defs>{body}</svg>')


def fig_program():
    b = _r(20, 85, 190, 90, ORANGE) + _t(115, 118, "/usr/bin/bash", 16, 700, mono=True) + _t(115, 142, "an executable file", 14, fill=MUTED) + _t(115, 160, "on the disk", 14, fill=MUTED)
    b += _a([(210, 130), (300, 130)], "orange", head=False) + _a([(300, 45), (300, 215)], "orange", head=False) + _t(255, 120, "exec", 14, 700, "#b35900")
    for k, (pid, y) in enumerate([(4100, 17), (4180, 102), (4230, 187)]):
        b += _a([(300, y + 28), (328, y + 28)], "orange")
        b += _r(330, y, 250, 56, BLUE) + _t(345, y + 24, f"bash · PID {pid}", 15, 700, NAVY, "start") + _t(345, y + 44, "its own memory and open files", 13, fill=MUTED, a="start")
    return svgfig(600, 260, b, "One executable file, three processes started from it")


def fig_abstractions():
    b = ""
    for k, name in enumerate(["firefox", "bash", "sort"]):
        x = 20 + k * 280
        b += _r(x, 10, 260, 100, GREEN, 12) + _t(x + 130, 32, f"process: {name}", 15, 700)
        b += _r(x + 15, 44, 110, 52, ORANGE, 8) + _t(x + 70, 75, "threads", 14, 600)
        b += _r(x + 135, 44, 110, 52, BLUE, 8) + _t(x + 190, 75, "open files", 14, 600)
        b += _a([(x + 130, 112), (x + 130, 152)], "grey", 1.8)
    b += f'<line x1="10" y1="130" x2="850" y2="130" stroke="{MUTED}" stroke-width="1.5" stroke-dasharray="7 6"/>'
    b += _t(16, 124, "user mode", 13, 600, MUTED, "start") + _t(844, 148, "kernel mode", 13, 600, MUTED, "end")
    b += _r(20, 155, 820, 130, ("#f5f8f9", NAVY), 14) + _t(430, 178, "kernel", 16, 700, NAVY)
    b += _r(40, 190, 380, 80, ORANGE) + _t(230, 222, "process", 18, 700) + _t(230, 248, "the abstraction for actions: runs code", 14, fill=MUTED)
    b += _r(440, 190, 380, 80, BLUE) + _t(630, 222, "file", 18, 700) + _t(630, 248, "the abstraction for data: stores bytes", 14, fill=MUTED)
    for k, (n, sub) in enumerate([("processor", "runs the threads"), ("memory", "code and variables"), ("disk", "files and folders"), ("devices", "keyboard, display, network")]):
        x = 20 + k * 210
        b += _a([(x + 95, 287), (x + 95, 318)], "grey", 1.8)
        b += _r(x, 320, 190, 62, GREY) + _t(x + 95, 346, n, 15, 700) + _t(x + 95, 367, sub, 13, fill=MUTED)
    return svgfig(860, 392, b, "Processes and files: the abstractions the kernel builds on top of the hardware")


def fig_resources():
    b = _r(10, 10, 540, 320, GREEN, 14) + _t(280, 36, "a process: bash", 17, 700) + _t(280, 58, "PID 4100 · PPID 4090", 14, 600, NAVY, mono=True)
    b += _r(30, 74, 240, 176, ORANGE) + _t(150, 98, "threads: the actions", 15, 700)
    for k, n in enumerate(["main", "worker 1", "worker 2"]):
        b += _r(45, 110 + k * 44, 210, 34, ("#fff", "#d79b00"), 7, 1.5) + _t(60, 132 + k * 44, n, 14, 600, a="start")
    b += _r(290, 74, 240, 176, BLUE) + _t(410, 98, "File Descriptor Table", 15, 700)
    for k, (fd, to) in enumerate([("0", "keyboard"), ("1", "display"), ("2", "display (errors)"), ("3", "notes.txt")]):
        y = 108 + k * 34
        b += _r(305, y, 30, 28, ("#fff", "#6c8ebf"), 5, 1.5) + _t(320, y + 19, fd, 14, 700, NAVY, mono=True)
        b += _r(341, y, 174, 28, ("#fff", "#6c8ebf"), 5, 1.5) + _t(352, y + 19, to, 14, a="start")
    b += _r(30, 264, 500, 50, ("#fff", "#9aa9ae")) + _t(280, 295, "memory: the code and the variables", 15, 600)
    return svgfig(560, 340, b, "What a process has: an ID, threads, a File Descriptor Table and memory")


def fig_fork():
    b = _r(90, 10, 340, 44, BLUE) + _t(260, 38, "parent: bash (PID 4100)", 15, 700, NAVY)
    b += _a([(260, 54), (260, 84)], "navy")
    b += _r(190, 86, 140, 42, ("#e0f2f1", TEAL)) + _t(260, 113, "fork()", 16, 700, TEAL, mono=True)
    b += _a([(190, 107), (110, 107), (110, 150)], "teal") + _a([(330, 107), (410, 107), (410, 150)], "teal")
    b += _t(150, 99, "parent", 15, 600, TEAL) + _t(372, 99, "child", 15, 600, TEAL)
    b += _r(40, 152, 140, 172, AMBER) + _t(110, 228, "wait()", 16, 700, "#8a6d00", mono=True) + _t(110, 254, "sleeps until", 15, fill=MUTED) + _t(110, 273, "the child ends", 15, fill=MUTED)
    b += _r(340, 152, 140, 42, GREEN) + _t(410, 179, 'exec("ls")', 15, 700, "#2e7d46", mono=True)
    b += _a([(410, 194), (410, 216)], "green")
    b += _r(340, 218, 140, 42, ("#fff", "#9aa9ae")) + _t(410, 245, "ls runs", 15)
    b += _a([(410, 260), (410, 280)], "grey")
    b += _r(340, 282, 140, 42, RED) + _t(410, 309, "exit(0)", 15, 700, "#9c2f2b", mono=True)
    b += _a([(110, 324), (110, 364)], "orange") + _a([(410, 324), (410, 364)], "red", dash=True) + _t(418, 350, "exit code", 15, 600, "#9c2f2b", "start")
    b += _r(40, 366, 440, 44, BLUE) + _t(260, 394, "parent continues: $? is 0", 15, 700, NAVY)
    return svgfig(520, 420, b, "fork, exec, exit and wait")


def fig_fdtable():
    b = _r(10, 10, 250, 250, GREEN, 14) + _t(135, 36, "a process", 16, 700) + _t(135, 58, "File Descriptor Table", 14, 600, NAVY)
    rows = [("0", "stdin"), ("1", "stdout"), ("2", "stderr"), ("3", "")]
    for k, (fd, n) in enumerate(rows):
        y = 74 + k * 42
        b += _r(25, y, 32, 32, BLUE, 6, 1.5) + _t(41, y + 22, fd, 15, 700, NAVY, mono=True)
        b += _r(63, y, 182, 32, ("#fff", "#6c8ebf"), 6, 1.5) + _t(76, y + 22, n or "an open file", 14, fill=INK if n else MUTED, a="start")
    b += _r(300, 10, 330, 250, ("#f5f8f9", NAVY), 14, dash=True) + _t(465, 36, "kernel: the open files", 15, 700, NAVY)
    b += _r(320, 56, 290, 88, RED) + _t(465, 84, "/dev/pts/0", 15, 700, mono=True) + _t(465, 106, "the terminal, a device:", 14, fill=MUTED) + _t(465, 125, "keyboard and display", 14, fill=MUTED)
    b += _r(320, 160, 290, 84, ORANGE) + _t(465, 188, "notes.txt", 15, 700, mono=True) + _t(465, 210, "a regular file", 14, fill=MUTED) + _t(465, 229, "read, position 0", 14, fill=MUTED)
    for k, ty in enumerate([78, 100, 122]):
        b += _a([(247, 90 + k * 42), (318, ty)], "navy", 1.8)
    b += _a([(247, 216), (318, 205)], "orange", 1.8)
    return svgfig(640, 270, b, "The File Descriptor Table: each index points to a file the kernel keeps open")


def fig_loader():
    b = _r(20, 92, 150, 70, BLUE) + _t(95, 122, "program file", 15, 700, NAVY) + _t(95, 145, "/bin/ls", 14, mono=True)
    b += _a([(170, 127), (318, 127)], "navy", 2.5) + _t(244, 117, "program loading", 13, 600, NAVY)
    b += _r(320, 8, 180, 54, ORANGE) + _t(410, 31, "libraries", 15, 700) + _t(410, 51, "libc.so.6, ...", 13, mono=True)
    b += _a([(410, 62), (410, 95)], "orange", 2.5) + _t(420, 84, "library loading", 13, 600, "#b35900", "start")
    b += _r(320, 97, 180, 60, GREEN) + _t(410, 133, "loader", 17, 700, "#2e7d46")
    b += _a([(500, 127), (638, 127)], "green", 2.5) + _t(569, 117, "dynamic linking", 13, 600, "#2e7d46")
    b += _r(640, 87, 220, 80, GREY) + _t(750, 117, "execution", 16, 700) + _t(750, 138, "the code of the program", 13, fill=MUTED) + _t(750, 156, "and of the libraries", 13, fill=MUTED)
    for x1, x2, n in [(20, 620, "load time"), (640, 860, "execution time")]:
        b += f'<path d="M{x1},188 V198 H{x2} V188" fill="none" stroke="{INK}" stroke-width="2"/>' + _t((x1 + x2) // 2, 222, n, 15, 700)
    return svgfig(880, 232, b, "The loader: program loading, library loading, dynamic linking, execution")

# ---------------------------------------------------------------- 01 packages
page = chapter("packages", "Installing applications", "Packages, repositories, `dnf` and `apt`", 12)
page("repos", "App repositories", "The Linux app store, long before the app stores", F(r"""
{why("Every program you use in the labs is installed from the repository of your distribution. Knowing what a package and a dependency are explains why `apt` asks for `sudo`, why it installs ten packages for one, and why removing a program leaves others behind.")}
<div class="trio">
<div class="panel"><h3>🌐 Repository</h3><p class="cap">A server of the distribution with thousands of checked and signed <b>packages</b>: a program, its files and the list of packages it needs (<em>dependencies</em>): <code>cowsay</code> → <code>perl</code>.</p></div>
<div class="panel"><h3>⚙️ Package manager</h3><p class="cap">Searches, downloads, installs, updates and removes packages, dependencies included. Fedora: <code>dnf</code> (<code>.rpm</code>). Ubuntu: <code>apt</code> (<code>.deb</code>).</p></div>
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
{ul("an **executable** is a file on the disk: `/bin/ls`", "a **process** is a running instance of it, with its own memory, open files and PID",
    "one executable can run as **many processes** at the same time: three terminals running `bash` are three processes of `/usr/bin/bash`",
    "peripherals are files too (POSIX): `/dev/sda` the first disk, `/dev/input/...` the keyboard, `/dev/fb0` the screen")}
{fig(fig_program(), "one executable file, several processes")}
{fig(fig_abstractions(), "processes (with threads and open files) on top of the kernel, which hides the hardware")}
"""))

page("loading", "Loading an executable", "The loader", F(r"""
<p class="txt">An executable file holds three things: how to load it, the code, and the list of libraries it needs. After <code>exec</code>, the <b>loader</b> uses all three to turn the file into a running process, in four steps: program loading, library loading, dynamic linking, execution.</p>
<div data-w="loader"></div>
{sol("The whole picture", fig(fig_loader()))}
"""))

page("resources", "What a process has", "PID, PPID, threads, files, memory", F(r"""
{fig(fig_resources(), "**PID** and **PPID** identify it; **threads** run its code in parallel; the **File Descriptor Table** lists its open files and devices; **memory** holds the code and the variables")}
<div class="duo top"><div>
{sh('''$ echo $$  # the PID of the shell
4100
$ ps -o pid,ppid,comm
    PID    PPID COMMAND
   4100    4090 bash
   4301    4100 ps''')}
</div><div><p class="txt"><code>$$</code> is the PID of the shell. <code>ps</code> is a child of the shell: its PPID is the PID of <code>bash</code>.</p></div></div>
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
</div><div>{fig(fig_fork())}</div></div>
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
{tree(BOOT, here=(3,))}
<div class="duo top"><div>
{ul("the kernel starts **one** user-space process, `init`, with **PID 1**; on most distributions it is `systemd`",
    "`init` starts the services: devices, network, the login screen, then your session",
    "every other process descends from it: `pstree` shows the whole family",
    "the kernel also runs its own threads (`kthreadd`, `kworker`), shown in brackets in `ps`")}
{note("`init` cannot stop", "If PID 1 ends, the kernel *panics*: the whole system stops. The next chapter shows why.", "warn")}
</div><div>
{sh('''$ pstree -p
systemd(1)
├─systemd-udevd(512)
├─NetworkManager(640)
└─systemd(1000)
  └─gnome-terminal-(4090)
    └─bash(4100)
      └─pstree(4301)''')}
</div></div>
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
{ul("each process has a **File Descriptor Table**; every open file has an entry, and the **index** in the table is the *file descriptor*",
    "`0` (`stdin`), `1` (`stdout`) and `2` (`stderr`) are open from the start; in a terminal all three point to it: the keyboard, the display, the display for errors",
    "a file the process opens goes at the first free index")}
{fig(fig_fdtable(), "the table is in the process, the open files are kept by the kernel")}
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
page = chapter("redirects", "Redirects", "`<`, `>`, `>>`, `2>`, `2>&1`", 18)
page("in", "`<`: a file instead of the keyboard", "Redirect stdin", F(r"""
<p class="txt">A command reads from <code>0</code> and writes to <code>1</code> and <code>2</code>. A <b>redirect</b> tells the shell to point one of them to a file, in the child, <b>before</b> it starts the command. The command does not know.</p>
{sh('''$ sort  # reads the keyboard, until Ctrl+D
$ sort < fruits.txt  # reads fruits.txt
apple
banana
cherry''')}
{redir("in")}
{bad("`sort fruits.txt` and `sort < fruits.txt` are the same", "The output is, the mechanism is not. With an argument, `sort` opens the file itself (at `3`) and knows its name; with `<` the shell opens it at `0` and `sort` only sees a stream. That is why `wc -l fruits.txt` prints the name and `wc -l < fruits.txt` does not.", "use `<` for commands that only read `stdin`, or when the name must not appear.")}
"""))
page("out", "`>` and `>>`: a file instead of the display", "Redirect stdout", F(r"""
<p class="txt"><code>&gt;</code> points <code>1</code> to a file and <b>empties</b> it first; <code>&gt;&gt;</code> keeps what is there and writes at the <b>end</b>.</p>
{sh('''$ ls > files.txt  # nothing on the display
$ cat files.txt  # files.txt existed before ls ran
backup
files.txt
fruits.txt
notes.txt
project
unsorted.txt
$ echo one > log.txt  # empty the file, then write
$ echo two >> log.txt  # write at the end''')}
{redir("out", "append")}
{note("`>` empties the file before the command runs", "`sort fruits.txt > fruits.txt` leaves an empty file: the shell truncates `fruits.txt` before `sort` reads it. Write to another file, then rename it.", "warn")}
"""))
page("err", "`2>` and `2>&1`: the errors", "Redirect stderr", F(r"""
<p class="txt">Errors go to <code>2</code>, so <code>&gt;</code> alone still shows them. <code>2&gt;</code> sends them to a file; <code>2&gt;&amp;1</code> sends them where <code>1</code> points <b>at that moment</b>, so the order of the redirects matters.</p>
{sh('''$ ls /nope 2> errors.txt  # nothing shows up
$ ls /etc /nope > all.txt 2>&1  # both into one file
$ ls /etc /nope &> all.txt  # the same, shorter''')}
{redir("err", "both", "order")}
"""))
page("practice", "Cheat sheet and practice", "All the redirects", F(r"""
{table(["Redirect", "Example", "What it does"], [
    ("`<`", "`sort < input.txt`", "stdin from a file"),
    ("`>`", "`ls > files.txt`", "stdout into a file, emptied first"), ("`>>`", "`ls >> files.txt`", "stdout at the end of a file"),
    ("`2>`", "`ls /nope 2> errors.txt`", "only the errors into a file"), ("`> f 2>&1`, `&> f`", "`ls /etc /nope &> all.txt`", "stdout and stderr into the same file"),
    ("`< a > b`", "`sort < unsorted.txt > sorted.txt`", "both at once"), ("`> /dev/null 2>&1`", "`command > /dev/null 2>&1`", "run silently, discard everything")], "k")}
{term(["sort < fruits.txt", "ls /etc /nope", "cat errors.txt", "ls -l"], missions="redir", side="fd", title="Try it: redirects")}
{sol("Heredoc: several lines as stdin", sh('''$ cat <<EOF
Hello, world!
This is a heredoc example.
EOF''') + '<p class="small">The lines up to <code>EOF</code> are sent <em>as they are</em> to <code>stdin</code>; a <code>#</code> there is not a comment. The demo terminal does not do heredocs.</p>')}
"""))

# ---------------------------------------------------------------- 08 pipes and devices
page = chapter("pipes", "Pipes and special files", "`|`, `/dev/null`, `/dev/zero`, `/dev/urandom`", 14)
page("pipe", "`|`: pipe", "The stdout of one process is the stdin of the next", F(r"""
<div class="duo top"><div>
{steps("the shell creates a *pipe*: a buffer in the kernel with a write end and a read end",
       "it starts `ls` with the **write end** at index `1`", "it starts `wc` with the **read end** at index `0`",
       "both run **at the same time**: `wc` reads what `ls` writes, until `ls` ends (*end of file*)")}
</div><div>
{sh('''$ ls
backup  fruits.txt  notes.txt  project  unsorted.txt
$ ls | wc -l
5''')}
<p class="small">No temporary file is used. <code>ls</code> prints one name per line when its <code>1</code> is not a terminal.</p>
</div></div>
{redir("pipe", "out")}
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
.pg h2{margin-top:34px}

/* ---- the interactive parts: a teal frame and a label (as in lectures 02 and 07) ---- */
.wd{container-type:inline-size;border:2px solid #00838f;border-radius:16px;box-shadow:0 0 0 5px #e3f2f3,0 14px 34px rgba(0,77,101,.08);margin:34px 0}
.wd-h{background:linear-gradient(100deg,#dcefF1,#eef6f7 70%);align-items:center;padding:14px 20px}
.wd-h h3::before{content:"\\25B6  Interactive";display:block;width:max-content;font:800 10.5px/1 system-ui,sans-serif;letter-spacing:1.4px;text-transform:uppercase;color:#fff;background:#00838f;border-radius:999px;padding:5px 10px;margin-bottom:7px}
.wd-h p{color:#33555f}
.tryjump{display:inline-flex;align-items:center;gap:10px;margin:-6px 0 20px;padding:7px 16px 7px 7px;border:1.5px solid #00838f;border-radius:999px;background:#f0f8f9;color:#004d65;font-size:14px;text-align:left;max-width:100%}
.tryjump:hover{background:#dcefF1}
.tryjump b{color:#00838f}
.tryjump .tj-i{flex:0 0 26px;height:26px;border-radius:50%;background:#00838f;color:#fff;display:grid;place-items:center;font-size:10px}
.side .tri{font-style:normal;font-size:9px;color:#00838f;margin-left:auto;align-self:center;padding-left:6px}
.side li a.on .tri{color:#004d65}
.chip.on{background:#004d65;color:#fff;border-color:#004d65}

/* ---- the demo terminal: its side panel goes next to it only when there is room for both ---- */
[data-w=shell]{margin-right:0!important}
.wd .wd-b.sb{grid-template-columns:minmax(0,1fr)}
.wd .wd-b.sb>div+div{border-left:0;border-top:1px solid var(--line)}
@container (min-width:840px){.wd .wd-b.sb{grid-template-columns:minmax(0,1fr) 300px}.wd .wd-b.sb>div+div{border-left:1px solid var(--line);border-top:0}}
@container (min-width:1150px){.wd .missions ol{grid-template-columns:1fr 1fr;column-gap:32px}}
.shellw .cmdchips{padding:10px 20px}

/* ---- the step-by-step widgets: selector and Back/Next on one bar, an orange strip, the picture ---- */
.ps-c{align-items:center;justify-content:space-between;gap:8px 16px;padding:10px 18px}
.ps-c .seg{flex:0 1 380px;min-width:0}
.ps-nav{display:flex;align-items:center;gap:10px;margin-left:auto}
.ps-nav .btn{padding:8px 14px}
.ps-nav .btn[disabled]{opacity:.45;cursor:default}
.pdots{display:flex;gap:6px;flex-wrap:wrap;max-width:150px}.pdots i{width:9px;height:9px;border-radius:50%;background:#ccdbe0}.pdots i.dn{background:#00838f}.pdots i.on{background:#e65100;transform:scale(1.3)}
.ps-x{padding:8px 18px;background:#fff6ef;border-bottom:1px solid #f6d6bd;font-size:15px;line-height:1.45;min-height:48px}
.ps-x b{color:#c2410c}
.ps-b{display:grid;grid-template-columns:minmax(0,1fr)}
.ps-b>div{padding:14px 18px;min-width:0}
.ps-b>div+div{border-top:1px solid var(--line)}
@container (min-width:680px){.ps-b{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}.ps-b>div+div{border-top:0;border-left:1px solid var(--line)}}
pre.sh.fkcode{font-size:13px;margin:0;white-space:pre-wrap}
.fkcode .cur{background:#ffe6cc;font-weight:700;border-radius:3px;box-shadow:0 0 0 2px #ffe6cc;border-left:3px solid #d79b00;margin-left:-3px}
.fkcode .cur .hl-c{color:#8a6a3d}

/* ---- the process states ---- */
.st-svg{display:block;width:100%;max-width:560px;max-height:330px;margin:0 auto}
.st-btns{display:flex;flex-direction:column;gap:8px}
.st-btns .btn{justify-content:space-between;width:100%}
.st-log{font-size:13px;color:var(--muted);padding-left:20px;margin:12px 0 0}
@container (min-width:680px){.stw .ps-b{grid-template-columns:minmax(0,1.4fr) minmax(0,1fr)}}

/* ---- fork, exec, exit, wait ---- */
.ptree{display:flex;flex-direction:column;gap:6px}
.pnode{display:flex;flex-wrap:wrap;align-items:center;gap:4px 8px;border:1px solid var(--line);border-radius:9px;padding:6px 10px;background:#fff;font-size:14px}
.pnode .pid{font:700 12.5px "SF Mono",Menlo,monospace;color:#004d65;background:#dae8fc;border-radius:5px;padding:1px 6px}
.pnode .pst{font:700 11px system-ui,sans-serif;color:#fff;border-radius:999px;padding:2px 8px}
.pnode .ppid{font:12px "SF Mono",Menlo,monospace;color:var(--muted);margin-left:auto}
.pnode .ptag{font:700 11px system-ui,sans-serif;color:#b35900;background:#ffe6cc;border-radius:999px;padding:2px 8px}
.pnode.new,.pnode.changed{border-color:#d79b00;background:#fffaf3;box-shadow:0 0 0 2px #ffe6cc}
.pnode.orphan{border-style:dashed;border-color:#d79b00}

/* ---- the loader ---- */
.ldsteps{display:flex;flex-wrap:wrap;gap:6px;flex:1 1 300px;min-width:0}
.lddot{border:1px solid var(--line);background:#fff;border-radius:999px;padding:4px 11px;font-size:13px;font-weight:650;color:var(--navy)}
.lddot b{display:inline-grid;place-items:center;width:18px;height:18px;border-radius:50%;background:#e6edf0;font-size:11px;margin-right:4px}
.lddot.on{background:#ffe6cc;color:#b35900;border-color:#d79b00}.lddot.on b{background:#d79b00;color:#fff}
.lddot.dn b{background:#00838f;color:#fff}
.ldgrid{display:grid;grid-template-columns:minmax(0,1fr);gap:12px;padding:14px 18px;align-items:start}
@container (min-width:680px){.ldgrid{grid-template-columns:minmax(0,1fr) 120px minmax(0,1.3fr)}}
.ldh{font-size:13px;font-weight:700;color:var(--navy);margin-bottom:8px}.ldh span{font-weight:400;color:var(--muted);margin-left:6px}
.ldpart{border:1px dashed #c4d3d8;border-radius:9px;padding:7px 12px;margin-bottom:6px;color:#9aa9ae;background:#f8fafb}
.ldpart b{display:block;font-size:14px}
.ldpart.on{border-style:solid;border-color:#d79b00;background:#ffe6cc;color:#b35900}
.ldmid{display:flex;flex-direction:row;justify-content:center;align-items:center;gap:8px;text-align:center}
@container (min-width:680px){.ldmid{flex-direction:column;padding-top:30px}}
.ldloader{border:2px solid #82b366;border-radius:10px;padding:6px 10px;font-weight:700;color:#4d7a2e;background:#fff;opacity:.45}
.ldloader.on{opacity:1;background:#d5e8d4}
.ldarrow{font:700 12.5px "SF Mono",Menlo,monospace;color:#e65100}
.ldcpu{font-size:12.5px;font-weight:700;color:#00838f;border:2px solid #00838f;border-radius:10px;padding:6px 8px}
.ldrow{display:flex;flex-wrap:wrap;gap:2px 8px;align-items:baseline;border-left:5px solid #b8cdd4;background:#fff;border-radius:6px;padding:6px 10px;margin-bottom:6px;box-shadow:0 0 0 1px var(--line)}
.ldrow b{font:600 14px "SF Mono",Menlo,monospace;color:var(--ink)}
.ldrow.px{border-left-color:#004d65}.ldrow.lb{border-left-color:#e65100}
.ldrow.new{box-shadow:0 0 0 2px #d79b00;background:#fffaf3;animation:ldin .35s ease-out}
@keyframes ldin{from{transform:translateX(12px);opacity:.5}to{transform:none;opacity:1}}
.ldgot{font-size:12px;font-weight:700;color:#b35900;background:#ffe6cc;border-radius:4px;padding:1px 6px}
.ldip{font-size:12px;font-weight:700;color:#00838f}
.ldempty{font-size:13px;color:var(--muted);font-style:italic;border:1px dashed var(--line);border-radius:8px;padding:10px}
pre.sh.ldcmd{font-size:12px;margin:8px 0 0;white-space:pre-wrap;overflow-wrap:anywhere}
pre.sh.ldcmd[hidden]{display:none}

/* ---- what the shell does for a redirect or a pipe ---- */
.rd-cmds{display:flex;flex-wrap:wrap;gap:6px;flex:1 1 360px;min-width:0}
.rd-b{display:grid;grid-template-columns:minmax(0,1fr);gap:12px;padding:12px 18px;align-items:start}
.rd-tabs{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:10px;align-items:start}
@container (min-width:700px){.rd-side{grid-template-columns:minmax(0,1.1fr) minmax(0,1fr)}}
.rd-t .fdt td{padding:3px 7px}
.rd-t.new{box-shadow:0 0 0 2px #d79b00}
.rd-t .fdh span{margin-left:6px}
.fdt tr.ch td{background:#ffe6cc;color:#b35900;font-weight:700}.fdt tr.ch td:first-child{color:#b35900}
.fdt tr.rd td{background:#eef6f7;color:#004d65;font-weight:600}
.fdt tr.x td{background:#fdecea;color:#b3261e;text-decoration:line-through}.fdt tr.x td:first-child{color:#b3261e}
.rd-o{border:1.5px dashed #82b366;border-radius:8px;background:#f6fbf4;overflow:hidden}
.rd-o.dsp{border-color:#9aa9ae;background:#f6f8f9}
.rd-oh{font-size:12.5px;font-weight:700;color:#2e7d46;padding:5px 10px;border-bottom:1px dashed #b9d7a8}
.rd-o.dsp .rd-oh{color:var(--navy);border-color:#d0dade}
.rd-o pre{margin:0;padding:6px 10px;font:12.5px/1.4 "SF Mono",Menlo,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}
.rd-o pre i{color:var(--muted)}
pre.sh.rd-code{font-size:12.5px;line-height:1.45;padding:8px 14px}

.fdstatic{max-width:420px}
svg.f3{display:block;width:100%;height:auto;margin:0 auto}

/* ---- tables wrap instead of scrolling sideways; terminals and trees wrap their long lines ---- */
.pg table.t td code,.pg table.t th code{white-space:normal}
.pg table.t.k td:first-child{white-space:normal}
.pg pre.sh{white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:hidden}
.pg pre.tree{white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:hidden}
.pg .syn{white-space:pre-wrap;overflow-wrap:anywhere}
@media (max-width:520px){.pg table.t{font-size:13px}.pg table.t th,.pg table.t td{padding:7px 6px}.pg table.t td,.pg table.t th{overflow-wrap:anywhere;hyphens:auto}}
@media (max-width:720px){.pg pre.tree{font-size:11.5px}}

/* ---- wide monitors: a wider page, the widgets use the room ---- */
@media (min-width:1500px){
 .wrap{width:min(1640px,calc(100% - 96px))}
 .layout{grid-template-columns:250px minmax(0,1fr);gap:56px}
 .pg>p,.pg .txt,.pg ul.k{max-width:940px}
 .why{max-width:1040px}.q,details.sol{max-width:980px}
 .duo{gap:40px}
 .hero{grid-template-columns:1.6fr 1fr}
}
@media (min-width:1900px){
 body{font-size:18px}
 .wrap{width:min(1840px,calc(100% - 140px))}
 .layout{grid-template-columns:270px minmax(0,1fr);gap:64px}
}
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
    checked="The demo terminal was tested against the examples of the slides (redirects, pipes, links, /proc); its messages follow GNU coreutils and bash. Its process list and /proc are simulated. The redirect simulator follows what bash does in the child: the redirects from left to right with open, dup2 and close, then exec.",
)

if __name__ == "__main__":
    render(COURSE, META, OUT, js=["dev.js", "procs.js"], css=CSS)
