#!/usr/bin/env python3
"""Build the interactive page of lecture 04 (Command Line Interface).

    python3 interactive/build_04.py
writes website/static/courses/04-command-line/index.html
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa
from engine import _tok
from page import F, Course, flash as flash_cards, render, REPO

OUT = os.path.join(REPO, "website/static/courses/04-command-line/index.html")
COURSE = Course()
chapter = COURSE.chapter


def term(cmds=(), missions=None, title=None, side=None, sub=None, cwd="~"):
    """a demo terminal with the files of lecture 04; side: jobs, vars, path (lecture 04 panels) or None (the file tree)"""
    a = f' data-profile="04" data-cwd="{E(cwd)}"'
    if side:
        a += f' data-side="{side}"'
    if cmds:
        a += f' data-cmds="{E("|".join(cmds))}"'
    if missions:
        a += f' data-missions="{missions}"'
    if title:
        a += f' data-title="{E(title)}"'
    if sub:
        a += f' data-sub="{E(sub)}"'
    return f'<div data-w="shell"{a}></div>'


def w(name, sc=None, lst=None):
    a = f' data-sc="{sc}"' if sc else ""
    a += f' data-list="{lst}"' if lst else ""
    return f'<div data-w="{name}"{a}></div>'


def bash(text):
    """a bash script, highlighted with the hl-* classes"""
    return '<pre class="sh lx-src">' + _tok(text.strip("\n"), [
        (r"(?:^|(?<=\s))#[^\n]*", "c"), (r"\"(?:\\.|[^\"\\])*\"|'[^']*'", "s"), (r"\$\{?[A-Za-z_?$!#]\w*\}?", "v"),
        (r"\b(?:function|while|do|done|if|then|else|fi|for|in|true|false)\b", "k"),
        (r"\b(?:echo|sleep|trap|export|kill|cd)\b", "f"), (r"\bSIG[A-Z]+\b", "n")]) + "</pre>"


def words(*ws):
    """word boxes like the slides: a string is a word, (text, kind): cmd, asg, rd, nw"""
    out = []
    for x in ws:
        t, k = (x, "") if isinstance(x, str) else x
        out.append(f'<span class="lx-w {k}">{E(t)}</span>')
    return "".join(out)


def anatomy(groups):
    """the parts of a command line, each underlined with its name: [(words, label, kind)]"""
    cells = "".join(f'<span class="an-g an-{k}"><span class="an-w">{words(*ws)}</span><span class="an-l">{md(lab)}</span></span>' for ws, lab, k in groups)
    return f'<div class="an">{cells}</div>'


# ---------------------------------------------------------------- the figures of the slides, redrawn as SVG
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
    defs = "".join(f'<marker id="f3-{k}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>' for k, c in _ARROWS.items())
    return (f'<svg class="f3 {cls}" viewBox="0 0 {w} {h}" style="max-width:{w}px" role="img" aria-label="{E(label)}">'
            f'<defs>{defs}</defs>{body}</svg>')


def fig_mainframe():
    b = _r(330, 10, 200, 96, ("#e8eef1", NAVY), 10) + _t(430, 42, "mainframe", 17, 700, NAVY) + _t(430, 64, "the only processor,", 14, fill=MUTED) + _t(430, 83, "memory and disks", 14, fill=MUTED)
    b += _r(40, 30, 170, 56, GREY) + _t(125, 63, "disks", 15, 600) + _a([(212, 58), (328, 58)], "navy", 2, head=False)
    b += _r(650, 30, 170, 56, GREY) + _t(735, 63, "tape drive", 15, 600) + _a([(532, 58), (648, 58)], "navy", 2, head=False)
    b += _a([(430, 106), (430, 140)], "orange", 2.4, head=False) + f'<line x1="95" y1="140" x2="710" y2="140" stroke="#d79b00" stroke-width="2.4"/>'
    for k in range(4):
        x = 30 + k * 205
        b += _a([(x + 65, 140), (x + 65, 160)], "orange", 2.4)
        b += _r(x, 162, 130, 74, ("#fff", MUTED), 8) + f'<rect x="{x + 12}" y="{172}" width="106" height="40" rx="4" fill="#1f2d33"/>'
        b += _t(x + 22, 190, "$ ls", 13, fill="#8ae234", a="start", mono=True) + _t(x + 22, 206, "notes.txt", 13, fill="#e6edf5", a="start", mono=True)
        b += _t(x + 65, 230, "⌨ keyboard", 12, fill=MUTED)
        b += _t(x + 65, 258, f"terminal {k + 1} · tty{k + 1}", 14, 700, NAVY)
    b += _t(430, 290, "a terminal: a keyboard and a screen (or a printer), no processor", 14, fill=MUTED)
    return svgfig(860, 300, b, "One mainframe, many terminals")


def fig_two():
    b = _r(20, 20, 470, 250, ("#eef1f3", MUTED), 12) + f'<rect x="20" y="20" width="470" height="34" rx="12" fill="{MUTED}"/>' + _t(255, 43, "foot", 15, 700, "#fff")
    b += f'<rect x="38" y="66" width="434" height="186" rx="6" fill="#1f2d33"/>'
    for i, (p, c) in enumerate([("student@iso:~$ ", "pwd"), ("", "/home/student"), ("student@iso:~$ ", "echo $SHELL"), ("", "/bin/bash"), ("student@iso:~$ ", "_")]):
        b += _t(54, 94 + i * 30, p + c, 15, fill="#7fd1c6" if p else "#e6edf5", a="start", mono=True)
    b += _r(560, 20, 280, 110, ORANGE) + _t(700, 50, "the terminal: foot", 16, 700) + _t(700, 75, "the window, the font, the colors", 14, fill=MUTED) + _t(700, 96, "reads the keyboard,", 14, fill=MUTED) + _t(700, 115, "draws the text", 14, fill=MUTED)
    b += _r(560, 160, 280, 110, GREEN) + _t(700, 190, "the shell: bash", 16, 700) + _t(700, 215, "the text inside: the prompt,", 14, fill=MUTED) + _t(700, 236, "the commands and their output;", 14, fill=MUTED) + _t(700, 255, "it runs the commands", 14, fill=MUTED)
    b += _a([(558, 60), (492, 40)], "orange", 2, dash=True) + _a([(558, 210), (474, 160)], "green", 2, dash=True)
    return svgfig(860, 290, b, "The terminal and the shell are two programs")


def fig_fgbg():
    b = _r(250, 14, 360, 96, ("#e0f2f1", TEAL), 14) + _t(430, 40, "foreground: only one", 16, 700, TEAL)
    b += _r(355, 52, 150, 44, GREEN) + _t(430, 80, "running", 15, 700, "#2e7d46")
    b += _r(230, 210, 400, 120, ("#eef3f5", NAVY), 14) + _t(430, 236, "background: the jobs, any number", 16, 700, NAVY)
    b += _r(255, 254, 150, 50, GREEN) + _t(330, 285, "running", 15, 700, "#2e7d46")
    b += _r(455, 254, 150, 50, AMBER) + _t(530, 285, "stopped", 15, 700, "#8a6d00")
    b += _t(80, 50, "cmd", 16, 700, mono=True) + _a([(110, 45), (248, 45)], "teal", 2.4)
    b += _t(70, 296, "cmd &", 16, 700, mono=True) + _a([(118, 291), (253, 291)], "navy", 2.4)
    b += _a([(612, 62), (720, 62), (720, 279), (607, 279)], "orange", 2.4) + _t(730, 150, "Ctrl+Z", 15, 700, "#b35900", "start", True) + _t(730, 172, "SIGTSTP", 14, 600, "#b35900", "start", True)
    b += _a([(455, 300), (407, 300)], "green", 2.4) + _t(430, 322, "bg · SIGCONT", 13, 600, "#2e7d46", mono=True)
    b += _a([(254, 266), (190, 266), (190, 86), (352, 86)], "teal", 2.4) + _t(180, 170, "fg", 15, 700, TEAL, "end", True) + _t(180, 190, "SIGCONT", 13, 600, TEAL, "end", True)
    return svgfig(860, 340, b, "Foreground and background: cmd, cmd &, Ctrl+Z, bg, fg")


# ---------------------------------------------------------------- 01 terminal and shell
page = chapter("terminal", "Terminal and shell", "From the teletype to the terminal emulator; what a shell is", 16)
page("classic", "The classic terminal: a keyboard and a screen", "Many users, one computer", F(r"""
{why("Every command you type goes through a **terminal** to a **shell**. They are two different programs, and knowing which one does what explains `Ctrl+C`, `/dev/pts/0` and why closing a window can stop your programs.")}
{fig(fig_mainframe(), "one large computer, the *mainframe*, and many terminals: they send the keys and print what the computer sends back")}
{ul("the old terminals were *TeleTypes*, **TTY**: a keyboard and a printer, later a screen, but **no processor**", "everything ran on the mainframe, the terminals only moved text in and out", "Linux still calls terminals `tty`: `/dev/tty1`, `/dev/tty2`, ... are files in `/dev`")}
"""))
page("vt", "Virtual terminals: `/dev/tty1` ... `/dev/tty6`", "Text mode", F(r"""
<p class="txt">Your computer has one screen and one keyboard, but the kernel offers several <b>virtual terminals</b> on them. At start-up, a program waits for a login on each one; after the login, it becomes your shell.</p>
{w("tty", "boot")}
{note("The graphical interface uses a terminal too", "The display server (*Xorg* or *Wayland*) takes over `tty1` or `tty2` and draws through the framebuffer, `/dev/fb0`. `Ctrl+Alt+F3` ... `F6` switch to a text terminal, `Ctrl+Alt+F1` or `F2` back.", "blue")}
"""))
page("shell", "Terminal and shell: two programs", "The terminal emulator and the shell", F(r"""
<p class="txt">A <b>shell</b> is a process whose main job is to let you talk to the operating system. In a graphical session, its text is shown by a <b>terminal emulator</b>, another program.</p>
{fig(fig_two(), "`foot` (or `kitty`, `ptyxis`, `alacritty`) is the window; `bash` (or `zsh`, `fish`) is what runs inside it")}
{w("tty", "pty")}
<div class="duo top"><div>
{sh('''$ tty  # the terminal of the shell
/dev/pts/0
$ ps  # the processes of this terminal
    PID TTY          TIME CMD
   4100 pts/0    00:00:00 bash
   4300 pts/0    00:00:00 ps''')}
</div><div>
{table(["Kind of shell", "Examples"], [("command line", "`bash`, `sh`, `zsh`, `fish`, `cmd`, `powershell`"), ("text user interface", "`mc`, `nnn`, `yazi`"), ("graphical", "Explorer, Finder, `nautilus`, the Settings")])}
</div></div>
{quiz("You close the window of `foot`. Which program ended first?", ["`bash`: it closed the window", "`foot`, the terminal emulator; the shell loses its terminal", "the kernel ends both at the same time", "nothing ends, `bash` keeps the window"], 1,
      "The window belongs to the terminal emulator. When it closes, the pseudo terminal goes away and the kernel tells the shell with a signal, `SIGHUP` (chapter *Sessions and terminals*).")}
"""))

# ---------------------------------------------------------------- 02 signals
page = chapter("signals", "Signals", "Notifications the kernel sends to processes", 14)
page("what", "Signals: a message for a process", "✉️ A number from the kernel", F(r"""
<p class="txt">A <b>signal</b> is a short message the operating system sends to a process: just a <b>number</b> (sometimes with one more number as payload). <code>Ctrl+C</code>, closing a window and <code>kill</code> all send one; <code>kill -l</code> lists them. When it arrives, the process runs the <b>default action</b> of the signal, or its own handler (next page).</p>
{w("sig")}
{note("Exit code 128 + the signal number", "A process ended by a signal has the exit code 128 + N: `130` after `Ctrl+C` (2), `137` after `kill -9`, `143` after `kill` (15).", "blue")}
"""))
TRAPSRC = """#!/bin/bash

# the signal handler
function no_interruptions_please () {
    echo "No interruptions please"
}

# register the signal handler
trap no_interruptions_please SIGINT

while true; do
  echo "working"
  sleep 1
done"""
page("trap", "`trap`: your own handler", "Handling signals", F(r"""
<p class="txt">When a signal arrives, the process stops what it does and runs the <b>default action</b>, or, if it registered one, its own <b>signal handler</b>; after a handler it goes on with its work. In bash: <code>trap FUNCTION SIGNAL</code>.</p>
{w("trap")}
<div class="duo top"><div>
<h3>The same in C</h3>
<pre class="sh lx-src">{hl('''#include <signal.h>

void handler(int signum) { /* ... */ }

signal(SIGINT, handler);''', "c")}</pre>
</div><div>
{ul("`SIGKILL` and `SIGSTOP` can never be caught, blocked or ignored: the last resort when a program does not listen", "`trap '' SIGINT` (an empty handler) **ignores** the signal", "programs use handlers to clean up: delete temporary files, save the work, then exit")}
</div></div>
{quiz("A script has `trap cleanup SIGTERM`. Which command still ends it, with no cleanup?", ["`kill PID`", "`kill -TERM PID`", "`kill -KILL PID`", "`Ctrl+C`, which sends `SIGTERM`"], 2,
      "`kill` sends `SIGTERM` by default, which runs `cleanup`. `SIGKILL` (`-9`) cannot be caught: the kernel ends the process. `Ctrl+C` sends `SIGINT`, not `SIGTERM`.")}
"""))

# ---------------------------------------------------------------- 03 jobs
page = chapter("jobs", "Foreground and background", "Run more than one process from the same shell", 18)
page("fgbg", "Foreground and background", "One in front, any number behind", F(r"""
{why("A command that takes minutes (a download, a build, a server) does not have to block your terminal: put it in the background and keep working. The same keys and commands bring it back.")}
{fig(fig_fgbg(), "`cmd` runs in the foreground, `cmd &` in the background; `Ctrl+Z` stops the foreground process, `bg` and `fg` continue it")}
<div class="duo top"><div>
<h3>Foreground</h3>
{ul("**only one** process (or pipeline)", "it reads the keyboard (`stdin`)", "the shell **waits** for it")}
</div><div>
<h3>Background</h3>
{ul("**any number** of processes, called **jobs**", "*running* or *stopped*", "the shell does not wait: it shows the prompt")}
</div></div>
"""))
page("amp", "`&`: start a job", "Run in the background", F(r"""
<p class="txt">Add <code>&amp;</code> at the end: the shell starts the command and shows the prompt <b>right away</b>. It prints the <b>job ID</b> and the PID.</p>
{w("sess", "amp")}
{bad("A job still writes to your terminal", "`ls -R / &` fills the screen while you type: the background only frees the keyboard, not the display.", "redirect the output of a job: `find / -name '*.log' > logs.txt 2> /dev/null &`.")}
"""))
page("ctrlz", "`Ctrl+Z`, `bg`, `fg`: move a job", "From the foreground to the background and back", F(r"""
<p class="txt">Forgot the <code>&amp;</code>? Stop the foreground process with <code>Ctrl+Z</code>, then let it continue in the background with <code>bg</code>. <code>fg</code> brings a job back to the foreground.</p>
{w("sess", "ctrlz")}
"""))
page("practice", "Cheat sheet and practice", "Jobs in the demo terminal", F(r"""
{table(["You type", "What happens", "Signal"], [
    ("`cmd &`", "starts a job in the background: `[1] 4300`", ""), ("`jobs`", "the jobs of this shell: `+` current, `-` previous", ""),
    ("`Ctrl+Z`", "stops the foreground process, it becomes a job", "`SIGTSTP`"), ("`Ctrl+C`", "ends the foreground process", "`SIGINT`"),
    ("`bg %1`", "job 1 continues in the background", "`SIGCONT`"), ("`fg %1`", "job 1 comes to the foreground", "`SIGCONT`"),
    ("`kill %1`", "ends job 1", "`SIGTERM`"), ("`kill -9 %1`, `kill -KILL 4300`", "ends it, no way to refuse", "`SIGKILL`")], "k")}
<p class="txt">In this terminal <code>sleep</code> really waits. <code>Ctrl+C</code>, <code>Ctrl+Z</code> and <code>Ctrl+\\</code> work as keys and as buttons; the panel shows the session, one line per process group.</p>
{term(["sleep 100 &", "sleep 200 &", "jobs", "kill %1", "ps -o pid,pgid,sid,stat,comm"], missions="jobs04", side="jobs", title="Try it: jobs", sub="A simulated terminal where sleep really waits. The panel shows the session: the groups, the foreground, the jobs. Ctrl+C, Ctrl+Z and Ctrl+\\ work in the terminal and as buttons.")}
"""))

# ---------------------------------------------------------------- 04 sessions
page = chapter("sessions", "Sessions and terminals", "How the processes of a terminal are grouped", 16)
page("session", "Sessions, groups and the controlling terminal", "How the kernel groups the processes of a terminal", F(r"""
<p class="txt">The kernel groups the processes of a terminal in two levels: a <b>process group</b> is one job, a <b>session</b> is all the groups of one terminal. One group is in the <b>foreground</b>: only it gets the keys.</p>
{w("sess", "session")}
"""))
page("killed", "When `bash` is killed", "`SIGKILL` cannot be caught", F(r"""
<p class="txt">Normally <code>bash</code> forwards <code>SIGHUP</code> to its jobs when the terminal closes. If <code>bash</code> is killed with <code>SIGKILL</code>, it cannot forward anything.</p>
{w("sess", "kill")}
{quiz("You start `nohup ./backup.sh > backup.log &` and close the terminal. What happens to the script?", ["it ends: the terminal sends `SIGHUP` to every process", "it keeps running: `nohup` makes it ignore `SIGHUP`", "it is stopped until you open a new terminal", "it ends, because its output was the terminal"], 1,
      "`nohup` makes the program ignore `SIGHUP`, so the hangup that `bash` forwards to its jobs does nothing. Its output was redirected to a file, so it does not need the terminal any more.")}
"""))
page("keys", "`Ctrl+C`, `Ctrl+\\` and `Ctrl+Z`", "Keys and signals", F(r"""
<p class="txt">The <b>terminal driver</b> in the kernel turns some keys into signals for the <b>whole foreground group</b>.</p>
{table(["Keys", "Sends", "Default action"], [("`Ctrl+C`", "`SIGINT`", "*terminate* (interrupt) the process"), ("`Ctrl+Z`", "`SIGTSTP`", "*stop* the process, it becomes a stopped job"),
    ("`Ctrl+\\`", "`SIGQUIT`", "*terminate* it and write a core dump"), ("`Ctrl+D`", "no signal", "*end of file*: `stdin` has nothing more to read")])}
{w("sess", "keys")}
{note("Only the foreground reads the keyboard", "A job that tries to read the keyboard gets `SIGTTIN` and is stopped. `bg` and `fg` send `SIGCONT` to continue a stopped job.", "blue")}
"""))

# ---------------------------------------------------------------- 05 environment
page = chapter("env", "Environment variables", "Settings that every process inherits", 20)
ENVT = '<div class="cx-vt"><div class="fdh"><b>bash</b> · PID 4100 · environment</div><table class="cx-t">' + "".join(
    f"<tr><td>{n}</td><td>{E(v)}</td></tr>" for n, v in [("HOME", "/home/student"), ("USER", "student"), ("SHELL", "/bin/bash"), ("PATH", "/home/student/.local/bin:/usr/local/bin:/usr/bin:/bin"), ("LANG", "en_US.UTF-8"), ("PWD", "/home/student")]) + "</table></div>"
page("env", "The environment: `NAME=value` texts", "Every process has one", F(r"""
<div class="duo top"><div>
{ul("every process has a list of `NAME=value` texts: its **environment**", "a process **receives** it from its parent: `fork` copies it, `exec` keeps it", "programs read it to configure themselves: `getenv(\"HOME\")` in C, `$HOME` in bash", "the names are in **UPPER CASE**, by convention")}
{sh('''$ printenv HOME  # one variable
/home/student
$ echo "I am $USER"  # the shell replaces $USER
I am student
$ env  # all of them''')}
</div><div>{ENVT}</div></div>
"""))
page("inherit", "Inherited by the children", "A copy, never a link", F(r"""
<p class="txt">Every process starts with a <b>copy</b> of the environment of its parent. A process passes variables <b>down</b> to its children, never <b>up</b>.</p>
{w("env", "inherit")}
{quiz("A script runs `cd /tmp` and `export PATH=/tmp`, then ends. In the shell that started it:", ["the current directory and `PATH` changed", "only `PATH` changed", "nothing changed: the script was a child, it changed its own copies", "only the current directory changed"], 2,
      "The script runs in a child process. Its current directory and its environment are its own; when it ends, they are gone. To change your shell, run the commands in it: `source script.sh`.")}
"""))
page("export", "`export`: shell variables and environment variables", "Only the exported ones are passed on", F(r"""
<p class="txt"><code>NAME=value</code> creates a <b>shell variable</b>: only this shell has it. <code>export NAME</code> makes it an <b>environment variable</b>: the children get a copy.</p>
{w("env", "export")}
{bad("Spaces around `=`", "`GREETING = hello` runs a command named `GREETING` with two parameters: `bash: GREETING: command not found`.", "no spaces: `GREETING=hello`; quotes for a value with spaces: `GREETING=\"hello world\"`.")}
"""))
page("defined", "Defined by the shell", "Already there when the prompt shows up", F(r"""
{table(["Variable", "Value", "Defined in (Fedora)"], [
    ("`HOME`, `USER`, `SHELL`", "the home directory, the user, the shell", "`/etc/passwd`, read by `login`"),
    ("`PWD`, `OLDPWD`", "the current and the previous directory", "the shell, at every `cd` (`cd -` uses `OLDPWD`)"),
    ("`PATH`", "where the commands are", "`/etc/profile`, then `~/.bashrc` adds `~/.local/bin`"),
    ("`LANG`", "the language", "`/etc/locale.conf`, read by `/etc/profile.d/lang.sh`"),
    ("`PS1`", "how the prompt looks, a **shell variable**", "`/etc/bashrc`, read by every interactive shell")])}
<p class="txt">The startup files are shell scripts: they run <code>export NAME=value</code> (or <code>NAME=value</code> for <code>PS1</code>).</p>
<h2>Special parameters</h2>
<div class="duo top"><div>
{ul("`$?`: the exit code of the last command (`0` means *success*)", "`$$`: the PID of the shell", "`$!`: the PID of the last job started with `&`", "they are set by the shell; you can only read them")}
</div><div>
{sh('''$ ls /nope
ls: cannot access '/nope': No such file or directory
$ echo $?  # ls failed: not 0
2
$ echo $?  # the exit code of echo
0
$ echo $$
4100''')}
</div></div>
"""))
page("once", "`NAME=value command`: only for one command", "Defined in the command line", F(r"""
{table(["Syntax", "Defines"], [("`NAME=value`", "a **shell variable**, only for this shell"), ("`export NAME=value`", "an **environment variable**, for this shell and every command started after it"),
    ("`NAME=value command`", "an environment variable **only for** `command`, the shell does not keep it"), ("`unset NAME`", "deletes the variable")])}
<div class="duo top"><div>
{sh('''$ date +%H:%M
11:47
$ TZ=Asia/Tokyo date +%H:%M  # only for this date
18:47
$ echo "[$TZ]"  # the shell does not have it
[]''')}
</div><div>
{ul("`TZ` (the time zone) is set only in the environment of this `date` process", "handy to change a setting once: `LANG=C sort fruits.txt` sorts by the byte values, upper case first")}
</div></div>
"""))
page("practice", "Cheat sheet and practice", "Variables in the demo terminal", F(r"""
{term(["echo $HOME", "GREETING=hello", "bash -c 'echo \"child: $GREETING\"'", "export GREETING", "TZ=Asia/Tokyo date +%H:%M", "env"], missions="env04", side="vars", title="Try it: shell and environment variables", sub="The panel shows the variables of your bash (shell only or environment) and the environment the last child got.")}
"""))

# ---------------------------------------------------------------- 06 command line
page = chapter("cmdline", "The command line", "How the shell reads what you type", 18)
page("parts", "A command line: assignments, command, parameters, redirects", "The parts of a line", F(r"""
<p class="txt">Before the command starts, the shell cuts the line into parts. Only the <b>assignments</b> must be at the start; the <b>redirects</b> can be anywhere.</p>
{sh('$ LANG=C sort -r "$HOME/my notes.txt" my\\ list.txt *.csv > sorted.txt 2> errors.txt')}
{anatomy([(["LANG=C"], "assignments (optional)", "asg"), ([("sort", "cmd")], "the command", "cmd"), (["-r", '"$HOME/my notes.txt"', "my\\ list.txt", "*.csv"], "its parameters", "par"), ([(">", "rd"), ("sorted.txt", "rd"), ("2>", "rd"), ("errors.txt", "rd")], "redirects (anywhere)", "rd")])}
{ul("`NAME=value` words **at the start**: variables only for this command", "the first word that is not an assignment or a redirect is the **command**", "everything else is a **parameter**: options, file names, texts", "a redirect (`>`, `2>`, `<`) and its file name are for the shell, not for `sort`")}
<h2>Mixed order</h2>
{sh('''$ IN="my notes.txt" OUT=sorted.txt OPTS="-u -f"
$ LANG=C 2> errors.txt sort "$IN" '$IN' > "$OUT" -r $OPTS -t ',' *.csv''')}
{anatomy([(["LANG=C"], "assignment", "asg"), ([("2>", "rd"), ("errors.txt", "rd")], "redirect", "rd"), ([("sort", "cmd")], "command", "cmd"), (['"$IN"', "'$IN'"], "parameters", "par"), ([(">", "rd"), ('"$OUT"', "rd")], "redirect", "rd"), (["-r", "$OPTS", "-t", "','", "*.csv"], "parameters", "par")])}
"""))
page("split", "Splitting a line, step by step", "What the shell does before the command starts", F(r"""
<p class="txt">The shell works on the line in a fixed order: it splits it into words, sets the assignments and redirects apart, replaces the variables, splits the results, expands the globs, removes the quotes, and only then starts the command.</p>
{w("split")}
"""))
page("order", "The order of redirects", "From left to right", F(r"""
<p class="txt">The shell applies the redirects <b>from left to right</b>. <code>2&gt;&amp;1</code> means: <code>2</code> goes where <code>1</code> goes <b>now</b>. It is a copy, not a link: changing <code>1</code> later does not change <code>2</code>.</p>
{sh('''$ ls /etc /nope > all.txt 2>&1  # nothing on the display
$ ls /etc /nope 2>&1 > all.txt  # the error is on the display
ls: cannot access '/nope': No such file or directory''')}
{w("order")}
"""))

# ---------------------------------------------------------------- 07 quoting and globbing
page = chapter("quoting", "Quoting, escaping and globbing", "Special characters and file name patterns", 16)
page("quotes", "Quotes and `\\`: what the command receives", "Quoting and escaping", F(r"""
<p class="txt">Spaces, <code>$</code>, <code>*</code> and the quotes are special for the shell. The quotes and the <code>\</code> tell it to treat them as plain characters; then the shell removes them: the command only gets the words.</p>
{ul("`'...'` single quotes: **nothing** inside is special", "`\"...\"` double quotes: `$NAME` is replaced, the result stays **one** word, the spaces are kept", "`\\` before a character: that one character is plain")}
{w("argv", "quote")}
"""))
page("globs", "Globs: patterns for file names", "Globbing", F(r"""
<p class="txt">An unquoted <code>*</code>, <code>?</code> or <code>[...]</code> is a pattern: the shell replaces it with the names of the matching files, sorted, <b>before</b> the command starts. The command never sees the pattern.</p>
{w("argv", "glob")}
{bad("Quote a pattern that is for the command", "`find . -name *.txt` is expanded by the shell first: `find` gets `-name fruits.txt my list.txt ...` and fails.", "`find . -name '*.txt'`: the quotes keep the `*` for `find`.")}
"""))
page("practice", "Cheat sheet and practice", "Quotes and globs in the demo terminal", F(r"""
{table(["Write", "The command gets", "Why"], [
    ("`echo $NAME`", "`Alice` `Smith`", "replaced, then split"), ("`echo \"$NAME\"`", "`Alice   Smith`", "one word"), ("`echo '$NAME'`", "`$NAME`", "nothing replaced"),
    ("`echo \\$NAME`", "`$NAME`", "the `$` is plain"), ("`echo *.txt`", "the `.txt` files", "glob"), ("`echo '*.txt'`", "`*.txt`", "a quoted pattern stays"),
    ("`echo {1..3}`", "`1` `2` `3`", "braces, files or not")], "k")}
{term(["NAME=\"Alice   Smith\"", "echo $NAME", "echo \"$NAME\"", "echo *.txt", "ls -d photo?.png", "echo {a,b,c}.pdf"], missions="quote04", title="Try it: quotes and globs", sub="A simulated terminal with the files of the lecture. reset starts again.")}
"""))

# ---------------------------------------------------------------- 08 running a command
page = chapter("run", "Running a command", "From a line of text to a process", 16)
page("builtin", "Built-in and external commands", "Not every command is a program", F(r"""
<div class="duo top"><div>
<h3>Built-in commands</h3>
{ul("run **inside** the shell, no new process", "`cd`, `export`, `unset`, `jobs`, `fg`, `bg`, `type`, `exit`, `echo`")}
<h3>External commands</h3>
{ul("executable files, somewhere on the disk", "the shell needs their **path**", "`ls`, `sort`, `grep`, `bash`")}
</div><div>
{sh('''$ type cd
cd is a shell builtin
$ type sort
sort is /usr/bin/sort''')}
</div></div>
{quiz("Why must `cd`, `unset` and `exit` be built into the shell?", ["they are faster that way", "they change the shell itself, and a child process can only change itself", "there is no file for them on the disk", "only `root` could run them as programs"], 1,
      "`cd` changes the current directory of the shell, `unset` its variables, `exit` stops it. A separate program would be a child process: it would change its own directory and variables, then end, and the shell would not see anything.")}
"""))
page("which", "Which file? A path, a builtin or a `PATH` search", "How the shell finds the program", F(r"""
<p class="txt">For an external command the shell needs a <b>path</b>. A first word with a <code>/</code> is a path already; a plain name is looked up in the directories of the <code>PATH</code> variable, <b>from left to right</b>.</p>
{w("route")}
<div class="lx-callout">🐧 <code>exec</code> only starts a <b>path</b>: turning a <b>name</b> into a path is the job of the shell (of the C library, in fact: the shell calls <code>execvp</code>).</div>
"""))
page("practice", "`which`, `type` and practice", "The PATH in the demo terminal", F(r"""
<div class="duo top"><div>
{sh('''$ which sort  # the PATH search, without running sort
/usr/bin/sort
$ which -a sort  # every match, in the order of PATH
/usr/bin/sort
/bin/sort
$ which cd  # nothing found: no output
$ echo $?
1''')}
</div><div>
{ul("`which` prints the file the shell would run", "`-a` prints every match", "`which` is an *external* command: it only searches `PATH`, it does not know the builtins; `type cd` asks the shell itself", "the current directory is **not** in `PATH`: that is why you run `./hello`")}
</div></div>
{term(["type cd sort", "which -a sort", "hello", "./hello", "echo $PATH"], missions="path04", side="path", title="Try it: the PATH search", sub="The panel shows how bash found the file of the last command: a path, a builtin, or the directories of PATH, checked from left to right.")}
"""))

# ---------------------------------------------------------------- 09 flashcards
FLASH = [
    ("01", "Terminal", "terminal/classic", "A terminal moves text, the computer runs the programs", "The old TTYs had no processor; Linux still names terminals `/dev/tty1`, `/dev/pts/0`."),
    ("01", "Terminal", "terminal/shell", "The terminal and the shell are two programs", "`foot` draws the window and reads the keys; `bash` runs the commands. They talk through a pseudo terminal, `/dev/pts/N`."),
    ("02", "Signals", "signals/what", "A signal is a number sent to a process", "`Ctrl+C` is `SIGINT` (2), `kill` sends `SIGTERM` (15), `kill -9` sends `SIGKILL`."),
    ("02", "Signals", "signals/trap", "`SIGKILL` and `SIGSTOP` cannot be caught", "Every other signal can run a handler (`trap` in bash, `signal()` in C) instead of its default action."),
    ("02", "Signals", "signals/what", "Exit code 128 + N: ended by signal N", "`130` after `Ctrl+C`, `137` after `kill -9`, `143` after `kill`."),
    ("03", "Jobs", "jobs/amp", "`&` starts a job, the prompt comes back at once", "`[1]` is the job ID of this shell, the other number is the PID. `%1` names the job for `kill`, `fg`, `bg`."),
    ("03", "Jobs", "jobs/ctrlz", "`Ctrl+Z` stops, it does not end", "The process becomes a stopped job; `bg` continues it in the background, `fg` in the foreground (both send `SIGCONT`)."),
    ("03", "Jobs", "jobs/amp", "A job still writes to your terminal", "Only the keyboard is freed; redirect the output of long jobs."),
    ("04", "Sessions", "sessions/session", "A job is a process group", "`sleep 100 | cat` is one group of two processes: `Ctrl+C` reaches both. Its first process is the group leader."),
    ("04", "Sessions", "sessions/session", "Closing the terminal sends `SIGHUP`", "To the session leader, `bash`, which forwards it to its jobs. `nohup` makes a program ignore it."),
    ("04", "Sessions", "sessions/keys", "Only the foreground group gets the keys", "A background job that reads the keyboard gets `SIGTTIN` and is stopped."),
    ("05", "Environment", "env/inherit", "Children get a copy of the environment", "Changes in a child never reach the parent: a script cannot change the `PATH` of your shell."),
    ("05", "Environment", "env/export", "`NAME=value` is not passed to children", "It is a shell variable. `export NAME` makes it an environment variable."),
    ("05", "Environment", "env/once", "`NAME=value command` sets it only for that command", "`TZ=Asia/Tokyo date`, `LANG=C sort`: the shell itself does not keep it."),
    ("05", "Environment", "env/export", "No spaces around `=`", "`A = 1` runs a command named `A`."),
    ("06", "Command line", "cmdline/split", "The shell expands, the command receives words", "Variables, globs and quotes are gone before the command starts; it only sees the final words."),
    ("06", "Command line", "cmdline/order", "`2>&1` copies where `1` points now", "Write it after `> file`; the redirects are applied from left to right."),
    ("07", "Quoting", "quoting/quotes", "Double quotes keep a value as one word", "`\"$NAME\"` keeps the spaces; unquoted `$NAME` is split at them. Single quotes replace nothing."),
    ("07", "Globbing", "quoting/globs", "Globs are expanded by the shell", "`ls *.txt`: `ls` gets the names. Quote a pattern meant for the command: `find -name '*.txt'`."),
    ("08", "Running", "run/builtin", "`cd` must be a builtin", "A child process cannot change the current directory of its parent."),
    ("08", "Running", "run/which", "A name is searched in `PATH`, from left to right", "The first match wins; the current directory is not searched: `./hello`."),
]
page = chapter("flashcards", "Flashcards", "The ideas of the lecture, one card each", 10)
page("recap", "The ideas, in short", "Quick recap", F(r"""
<p class="txt">One idea per card; the title is the idea, the text says why it matters in practice. <em>Recap</em> shows all the cards, <em>Flashcard</em> one at a time.</p>
{flash_cards(FLASH)}
"""))

CSS = """
.pg h2{margin-top:34px}

/* ---- the interactive parts: a teal frame and a label (as in the other lectures) ---- */
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
.wd .wd-b.sb.ext .term{height:340px}
@container (min-width:840px){.wd .wd-b.sb{grid-template-columns:minmax(0,1fr) 300px}.wd .wd-b.sb>div+div{border-left:1px solid var(--line);border-top:0}}
@container (min-width:900px){.wd .wd-b.sb.ext{grid-template-columns:minmax(0,1fr) minmax(360px,.85fr)}.wd .wd-b.sb.ext .term{height:440px}}
@container (min-width:1150px){.wd .missions ol{grid-template-columns:1fr 1fr;column-gap:32px}}
.shellw .cmdchips{padding:10px 20px}
.extp{display:flex;flex-direction:column;gap:10px;font-size:13.5px;min-width:0;padding:12px 14px}
/* the jobs terminal: the session next to the terminal (under it on narrow screens), one mission at a time below */
[data-side=jobs]{container:jobs/inline-size}
[data-side=jobs] .wd .wd-b.sb.ext{grid-template-columns:minmax(0,1fr)}
[data-side=jobs] .wd .wd-b.sb.ext>div+div{border-left:0;border-top:1px solid var(--line)}
[data-side=jobs] .wd .wd-b.sb.ext .term{height:280px}
[data-side=jobs] .extp{padding:12px 14px;gap:8px}
[data-side=jobs] .wd-f{display:none}
.cx-jl{display:flex;flex-direction:column;gap:8px;min-width:0}
[data-side=jobs] .cx-note{padding:6px 10px;font-size:13px}
[data-side=jobs] .wd .wd-b.sb.ext{align-items:start}
[data-side=jobs] .sx-t small{display:none}
[data-side=jobs] .sx-s{padding:8px}
[data-side=jobs] .sx-gs{display:flex;flex-direction:column;gap:5px}
[data-side=jobs] .sx-g{flex:0 0 auto;flex-direction:row;flex-wrap:wrap;align-items:center;gap:4px 8px;padding:4px 8px}
[data-side=jobs] .sx-gh{flex:0 0 150px;flex-direction:row;align-items:baseline;gap:6px;text-align:left;white-space:nowrap}
[data-side=jobs] .sx-ps{flex:1 1 auto;flex-wrap:wrap;gap:4px}
[data-side=jobs] .sx-p{flex:0 0 auto;flex-direction:row;align-items:baseline;gap:5px;padding:2px 7px}
[data-side=jobs] .sx-nh{margin:0}
[data-side=jobs] .sx-gn{margin-left:auto;white-space:nowrap}
[data-side=jobs] .sx-l{min-height:24px;padding:3px 10px}
[data-side=jobs] .sx-lg{margin-top:10px;font-size:11px}
[data-side=jobs] .wd-h p{display:none}
@container jobs (min-width:860px){
 [data-side=jobs] .wd .wd-b.sb.ext{grid-template-columns:minmax(0,1.08fr) minmax(0,1fr)}
 [data-side=jobs] .wd .wd-b.sb.ext>div+div{border-top:0;border-left:1px solid var(--line)}
 [data-side=jobs] .wd .wd-b.sb.ext .term{height:380px}
}

.cx-fg .tline .pr{visibility:hidden}
.term .cx-sig{color:#fcaf3e;font-weight:700}

/* ---- the side panels of the demo terminal ---- */
.cx-note{border-left:4px solid #e65100;background:#fff6ef;border-radius:0 10px 10px 0;padding:8px 12px;font-size:13.5px;line-height:1.5}
.cx-note>.cx-nh{display:block;font-size:10.5px;letter-spacing:1.3px;text-transform:uppercase;color:#c2410c}
.cx-keys{display:flex;flex-wrap:wrap;align-items:center;gap:6px}
.cx-keys span{font-size:12.5px;color:var(--muted);margin-right:2px}
.cx-keys .btn{padding:5px 11px;font:700 12.5px "SF Mono",Menlo,monospace}
.cx-keys .btn[disabled]{opacity:.4;cursor:default}
.cx-vt{border:1px solid #c8d6dd;border-radius:10px;overflow:hidden;background:#fff}
.cx-vt .fdh{background:#dae8fc;color:#004d65;padding:5px 10px;font-size:13px}
.cx-vt.kid .fdh{background:#d5e8d4;color:#2e5d1f}
.cx-t{width:100%;border-collapse:collapse;font:12.5px/1.35 "SF Mono",Menlo,Consolas,monospace;table-layout:fixed}
.cx-t td{padding:4px 8px;border-top:1px solid #eef2f4;overflow-wrap:anywhere;vertical-align:top}
.cx-t td:first-child{width:32%;font-weight:700;color:#004d65}
.cx-t td:nth-child(3){width:30%;text-align:right}
.cx-t tr.ch td{background:#ffe6cc;color:#b35900}
.cx-t tr.sv td{color:#6b7c82;font-style:italic}
.cx-t tr.x td{background:#fdecea;color:#b3261e;text-decoration:line-through}
.cx-tag{display:inline-block;font:700 10.5px system-ui,sans-serif;border-radius:999px;padding:2px 7px;white-space:nowrap;font-style:normal}
.cx-tag.env{background:#d5e8d4;color:#2e5d1f}.cx-tag.sh{background:#eef1f3;color:#5b6b71;border:1px dashed #9aa9ae}.cx-tag.one{background:#ffe6cc;color:#b35900}
.cx-arr{font-size:12.5px;color:#b35900;text-align:center}
.cx-hint{font-size:12.5px;color:var(--muted);font-style:italic}
.cx-route{border:1.5px solid #d79b00;background:#fffaf3;border-radius:10px;padding:8px 12px;line-height:1.5}
.cx-ph{font-size:12px;font-weight:700;color:var(--navy);letter-spacing:.5px}
.cx-path{margin:0;padding-left:22px;display:grid;gap:5px}
.cx-path li{border:1px solid #c8d6dd;border-radius:8px;padding:5px 9px;background:#fff;display:flex;flex-wrap:wrap;justify-content:space-between;gap:2px 8px}
.cx-path li code{background:none;padding:0;overflow-wrap:anywhere}
.cx-path li span{font-size:12px;color:var(--muted)}
.cx-path li.ok{border-color:#82b366;background:#f1f8ee}.cx-path li.ok span{color:#2e7d46;font-weight:700}
.cx-path li.no{background:#f6f8f9;color:#9aa9ae}

/* ---- a session: the terminal, the session, the groups, the processes ---- */
.sx{display:flex;flex-direction:column;gap:0;font-size:13px}
.sx-t{background:#004d65;color:#fff;border-radius:10px;padding:7px 12px;display:flex;flex-wrap:wrap;gap:2px 10px;align-items:baseline}
.sx-t b{font:700 13.5px "SF Mono",Menlo,monospace}.sx-t span{font-style:italic;font-size:12.5px;opacity:.9}.sx-t small{flex-basis:100%;font-size:11.5px;opacity:.85}
.sx-t.sx-closed,.sx-t.sx-detached{background:#8a969b}
.sx-l{min-height:30px;margin-left:24px;border-left:2px solid #004d65;padding:5px 10px;font-size:12px;color:#004d65}
.sx-l.sig{border-left:3px solid #e65100;color:#b35900;font-weight:700}
.sx-l .dt{color:#8a969b;font-style:italic}
.sx-s{border:1.5px dashed #004d65;border-radius:12px;padding:10px;position:relative}
.sx-sn{position:absolute;right:10px;bottom:-9px;background:#fff;padding:0 6px;font-size:11.5px;font-weight:700;color:#004d65}
.sx-gs{display:flex;flex-wrap:wrap;gap:8px;align-items:stretch}
.sx-g{flex:1 1 120px;min-width:0;border:1.5px solid #9aa9ae;border-radius:10px;background:#eef3f5;padding:6px;display:flex;flex-direction:column;gap:5px}
.sx-g.fg{border:2.5px solid #004d65}
.sx-g.hit{border-color:#d79b00;box-shadow:0 0 0 2px #ffe6cc}
.sx-g.sx-stop{background:#fff8e1}.sx-g.sx-end,.sx-g.sx-killed{background:#f4f6f7;border-style:dashed}
.sx-gh{display:flex;flex-direction:column;align-items:center;text-align:center;line-height:1.25}
.sx-gh b{font-size:12px}.sx-gh span{font-size:11.5px;color:#4a5b61}
.sx-ps{display:flex;gap:5px}
.sx-p{flex:1 1 0;min-width:0;border:1px solid #9aa9ae;border-radius:7px;background:#fff;padding:4px 3px;display:flex;flex-direction:column;align-items:center;text-align:center}
.sx-p b{font:700 12.5px "SF Mono",Menlo,monospace;overflow-wrap:anywhere}.sx-p span{font-size:11px;color:#5b6b71}
.sx-p.hit{border:1.5px solid #d79b00;background:#fff3e0}.sx-p.hit b{color:#b35900}
.sx-p.gone{border-style:dashed}.sx-p.gone b{color:#8a969b}
.sx-nh{font-style:normal;font-size:10.5px;font-weight:700;color:#2e7d32;background:#e8f5e9;border:1px solid #2e7d32;border-radius:999px;padding:0 6px;margin-top:2px}
.sx-gn{font-size:11.5px;text-align:center;color:#b35900;font-weight:600}
.sx-lg{margin-top:14px;font-size:12px;color:#4a5b61;text-align:center}

/* ---- the step widgets: selector and Back/Next on one bar, an orange strip, the picture ---- */
.ps-c{align-items:center;justify-content:space-between;gap:8px 16px;padding:10px 18px}
.ps-nav{display:flex;align-items:center;gap:10px;margin-left:auto}
.ps-nav .btn{padding:8px 14px}
.ps-nav .btn[disabled]{opacity:.45;cursor:default}
.pdots{display:flex;gap:6px;flex-wrap:wrap;max-width:150px}.pdots i{width:9px;height:9px;border-radius:50%;background:#ccdbe0}.pdots i.dn{background:#00838f}.pdots i.on{background:#e65100;transform:scale(1.3)}
.ps-x{padding:8px 18px;background:#fff6ef;border-bottom:1px solid #f6d6bd;font-size:15px;line-height:1.45;min-height:48px}
.ps-x b{color:#c2410c}
pre.sh.fkcode{font-size:13px;margin:0;white-space:pre-wrap}
.fkcode .cur{background:#ffe6cc;font-weight:700;border-radius:3px;border-left:3px solid #d79b00;margin-left:-3px}
.lx-cap{font-size:12.5px;color:var(--muted);font-weight:600}
.lx-side,.lx-one,.lx-inh{display:grid;grid-template-columns:minmax(0,1fr);gap:14px;padding:14px 18px;align-items:start}
@container (min-width:700px){.lx-side{grid-template-columns:minmax(0,1fr) minmax(0,1.15fr)}.lx-inh{grid-template-columns:minmax(0,1fr) 90px minmax(0,1fr);align-items:center}}
.lx-hid{visibility:hidden}
pre.sh.lx-t{margin:0;font-size:12.5px;line-height:1.5;white-space:pre-wrap;overflow-wrap:anywhere}
.lx-t .lx-l{display:block;min-height:1.5em;padding-left:2.2ch;text-indent:-2.2ch}
.lx-t .lx-new{background:#fff3e0;border-left:3px solid #d79b00;margin-left:-3px}
.lx-mk{background:#e65100;color:#fff;border-radius:3px;padding:0 2px}
.lx-chips{display:flex;flex-wrap:wrap;gap:6px;flex:1 1 300px;min-width:0}
.lx-btns{display:flex;flex-wrap:wrap;gap:8px}.lx-btns .btn{padding:7px 12px}.lx-btns .btn[disabled]{opacity:.4;cursor:default}
pre.sh.lx-src{font-size:13px;white-space:pre-wrap}
.lx-off{opacity:.55}

/* the terminals */
pre.tree.lx-tree{margin:0;font-size:12.5px}
.lx-tree b.nw{color:#e65100}.lx-tree i{color:#8a969b}
.lx-scr{background:#1f2d33;border:6px solid #5b6b71;border-radius:10px;min-height:120px;padding:10px 12px}
.lx-scr pre{margin:0;color:#e6edf5;font:13px/1.5 "SF Mono",Menlo,monospace;white-space:pre-wrap}
.lx-scr.gui{background:linear-gradient(135deg,#2b5876,#4e4376)}
.lx-ttys{display:flex;flex-wrap:wrap;gap:5px;margin-top:10px}
.lx-tty{border:1px solid #c8d6dd;border-radius:8px;padding:3px 8px;background:#fff;display:flex;flex-direction:column;align-items:center;font-size:12px;min-width:56px}
.lx-tty b{font:700 12px "SF Mono",Menlo,monospace;color:#004d65}.lx-tty i{font-style:normal;color:var(--muted);font-size:11px}
.lx-tty.on{border-color:#d79b00;background:#fff3e0}
.lx-k{font-size:12.5px;color:var(--muted);margin-top:8px}
svg.pty{max-height:372px}

/* trap */
.lx-term{background:#1f2d33;border-radius:10px;overflow:hidden}
.lx-term .tbar{display:flex;gap:6px;align-items:center;padding:6px 10px;background:#2c3e45;color:#9fb3ba;font-size:12px}
.lx-term .tbar i{width:10px;height:10px;border-radius:50%;background:#5b6b71}
.lx-term pre{margin:0;height:250px;overflow-y:auto;padding:10px 12px;color:#e6edf5;font:13px/1.5 "SF Mono",Menlo,monospace;white-space:pre-wrap}
.lx-term .p{color:#7fd1c6;font-weight:700}
.lx-cur{animation:lxb 1s steps(1) infinite}@keyframes lxb{50%{opacity:0}}

/* the environment */
.lx-arr{display:flex;flex-direction:column;align-items:center;color:#b35900;font-weight:700}.lx-arr span{font-size:26px;line-height:1}
.lx-ph{border:1px dashed #c8d6dd;border-radius:10px;padding:20px;text-align:center;color:var(--muted);font-size:13px}
.lx-down{margin:8px 0;padding:6px 10px;border-left:3px solid #e65100;font-size:12.5px;line-height:1.5}
.lx-argv{display:flex;align-items:flex-start;gap:6px;margin-top:5px}
.lx-argv>span{display:flex;flex-direction:column;align-items:center;min-width:0}
.lx-argv>span:last-child{flex:1 1 auto;align-items:flex-start}
.lx-argv .lx-w{margin:0}
.lx-argv i{font-style:normal;font-size:11px;color:var(--muted);white-space:nowrap}
.lx-argv>span:last-child i{white-space:normal}
.lx-outl{font-size:12.5px;margin-top:8px}
.lx-o{font:700 12.5px "SF Mono",Menlo,monospace;color:#b35900;border:1.5px solid #e65100;border-radius:5px;padding:1px 6px}

/* the words of a command line */
.lx-w{display:inline-block;font:13px/1.3 "SF Mono",Menlo,Consolas,monospace;border:1px solid #9aa9ae;border-radius:4px;padding:3px 6px;margin:2px 4px 2px 0;background:#fff;white-space:pre-wrap;overflow-wrap:anywhere;max-width:100%}
.lx-w.cmd{background:#004d65;color:#fff;border-color:#004d65}
.lx-w.cmd0{border:1.5px solid #004d65;color:#004d65;font-weight:700}
.lx-w.nw{border:1.5px solid #e65100;color:#b35900}
.lx-w.rd{border:1.3px dashed #e65100;color:#b35900}
.lx-w.asg{border:1.3px dashed #82b366;color:#2e7d46}
.lx-w.gone{border-style:dashed;color:#9aa9ae;text-decoration:line-through}
.lx-w.nm{border:1.5px dashed #9aa9ae}
.lx-w i{color:#9aa9ae}
.lx-in{display:flex;align-items:center;gap:8px;margin:12px 18px 0;background:#1f2d33;border-radius:8px;padding:6px 12px;flex-wrap:wrap}
.lx-in .p{color:#7fd1c6;font-weight:700;font-family:"SF Mono",Menlo,monospace}
.lx-in input{flex:1 1 200px;min-width:0;background:none;border:0;color:#fff;font:14px "SF Mono",Menlo,monospace;outline:none}
.lx-vars{font-size:11.5px;color:#9fb3ba}
.lx-in[hidden],pre.sh.lx-line[hidden]{display:none}
pre.sh.lx-line{margin:12px 18px 0;font-size:13px;white-space:pre-wrap;overflow-wrap:anywhere}
.lx-rows{padding:8px 18px 14px;display:flex;flex-direction:column;gap:4px}
.lx-row{display:grid;grid-template-columns:minmax(0,1fr);gap:2px 12px;align-items:center;padding:1px 6px;border-radius:8px}
.lx-row .lx-w{margin:1px 4px 1px 0;padding:2px 6px}
@container (min-width:760px){.lx-row{grid-template-columns:150px minmax(0,1fr) minmax(0,190px)}}
.lx-row.now{background:#fff6ef;box-shadow:inset 3px 0 0 #e65100}
.lx-rl{font-size:12.5px;color:var(--muted);font-style:italic}
.lx-row.now .lx-rl{color:#b35900;font-weight:700;font-style:normal}
.lx-ra{min-width:0}
.lx-fin{font-size:12.5px;color:#b35900;line-height:1.5}
.lx-ab{padding:0 0 14px}
.lx-ab pre.sh.lx-line{white-space:pre-wrap}
.lx-got{margin:12px 18px 0;padding:10px 12px;border:1.5px solid #c8d6dd;border-radius:10px;background:#fbfcfd}
.lx-got .lx-cap{display:block;margin-bottom:4px}
.lx-why{margin:10px 18px 0;font-size:14.5px}
.lx-err{color:#b3261e;font-size:13.5px}
.lx-ac .lx-chips{flex-basis:100%}
.an{display:flex;flex-wrap:wrap;gap:10px 14px;align-items:flex-end;margin:12px 0 18px}
.an-g{display:inline-flex;flex-direction:column;align-items:center;gap:4px;min-width:0;max-width:100%}
.an-w{border-bottom:2px solid #e65100;padding-bottom:4px;display:flex;flex-wrap:wrap;justify-content:center}
.an-l{font-size:12.5px;color:#b35900;text-align:center}
.an-asg .an-w{border-color:#82b366}.an-asg .an-l{color:#2e7d46}
.an-cmd .an-w{border-color:#004d65}.an-cmd .an-l{color:#004d65}
.an-par .an-w{border-color:#9aa9ae}.an-par .an-l{color:#5b6b71}
.lx-callout{border:2px solid #e65100;background:#fff3e0;border-radius:12px;padding:12px 18px;margin:20px 0;font-size:16px;text-align:center}


/* ---- the signals ---- */
.sg-f{flex:0 1 420px}
.sg-b{display:grid;grid-template-columns:minmax(0,1fr);gap:14px;padding:14px 18px;align-items:start}
@container (min-width:720px){.sg-b{grid-template-columns:minmax(0,1.3fr) minmax(0,1fr)}}
.sg-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:5px}
.sg-c{position:relative;display:flex;align-items:baseline;gap:6px;text-align:left;border:1px solid #d3dde2;border-left:5px solid var(--c);border-radius:7px;background:#fff;padding:4px 16px 4px 7px;min-width:0;transition:.12s}
.sg-c b{font:700 11px system-ui,sans-serif;color:var(--muted);min-width:14px;text-align:right}
.sg-c span{font:600 12.5px "SF Mono",Menlo,Consolas,monospace;color:#1f2d33;overflow-wrap:anywhere}
.sg-c i{position:absolute;top:4px;right:5px;font-style:normal;font-size:11px;color:#e65100}
.sg-c:hover{background:var(--f)}
.sg-c.on{background:var(--f);border-color:var(--c);box-shadow:0 0 0 2px var(--c)}
.sg-c.dim{opacity:.3}
.sg-d{border:1.5px solid #c8d6dd;border-radius:12px;padding:12px 14px;background:#fbfcfd;font-size:14px;line-height:1.45}
.sg-h{display:flex;gap:12px;align-items:center;margin-bottom:8px}
.sg-n{flex:0 0 auto;min-width:46px;height:46px;padding:0 6px;border-radius:12px;background:#004d65;color:#fff;display:grid;place-items:center;font:800 17px system-ui,sans-serif}
.sg-h div b{display:block;font:700 17px "SF Mono",Menlo,monospace;color:#004d65}.sg-h div span{color:var(--muted);font-size:14px}
.sg-d dl{display:grid;grid-template-columns:96px minmax(0,1fr);gap:4px 10px;margin:8px 0 0}
.sg-d dt{font-size:12.5px;font-weight:700;color:var(--navy);padding-top:2px}
.sg-d dd{margin:0}
.sg-a{display:inline-block;font:700 12px system-ui,sans-serif;color:var(--c);background:var(--f);border:1px solid var(--c);border-radius:999px;padding:1px 9px;margin-right:4px}
@container (max-width:460px){.sg-d dl{grid-template-columns:minmax(0,1fr)}.sg-d dt{padding-top:6px}}

/* which file runs */
.rt{padding:14px 18px;display:flex;flex-direction:column;gap:12px}
.rt-flow{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:10px;align-items:start}
.rt-col{display:flex;flex-direction:column;align-items:stretch;gap:4px;text-align:center}
.rt-b,.rt-q,.rt-e{border:1.5px solid #9aa9ae;border-radius:8px;padding:7px 6px;font-size:13px;background:#fff;line-height:1.35;overflow-wrap:anywhere}
.rt-q{border-style:dashed;border-radius:16px}
.rt-b.cmd{font:700 14px "SF Mono",Menlo,monospace;color:#004d65}
.rt-b.srch{background:#fff3e0}
.rt-e{background:#f4f6f7;color:#5b6b71;font-size:12.5px}
.rt-e code{display:block;margin-top:3px;font-size:11.5px;color:#b35900;background:none}
.rt-y{font-size:12px;color:#9aa9ae}.rt-y.on{color:#e65100;font-weight:700}
.rt .dn{border-color:#00838f;color:#004d65}
.rt .now{border:2.5px solid #e65100;background:#fff3e0;color:#b35900;font-weight:700}
.rt-path{display:flex;flex-wrap:wrap;align-items:center;gap:4px}
.rt-path>b{color:#e65100}
.rt-d{display:inline-flex;flex-direction:column;align-items:center;border:1px solid #c8d6dd;border-radius:8px;padding:3px 8px;background:#fff;max-width:100%}
.rt-d code{background:none;font-size:12.5px;overflow-wrap:anywhere}
.rt-d i{font-style:normal;font-size:11.5px;min-height:14px}
.rt-d.no{background:#f4f6f7;color:#9aa9ae}.rt-d.ok{border-color:#82b366;background:#f1f8ee}.rt-d.ok i{color:#2e7d46;font-weight:700}
.rt-d.now{border:2px solid #e65100}
.rt pre.sh.lx-line{margin:0}

/* ---- the order of redirects: File Descriptor Tables ---- */
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

svg.f3{display:block;width:100%;height:auto;margin:0 auto}

/* ---- tables wrap instead of scrolling sideways; terminals and trees wrap their long lines ---- */
.pg table.t td code,.pg table.t th code{white-space:normal}
.pg table.t.k td:first-child{white-space:normal}
.pg pre.sh{white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:hidden}
.pg pre.tree{white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:hidden}
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
    num="04", key="iso-04-cli-v1", short="Command Line",
    title="The command line, step by step · ISO Lecture 04",
    description="ISO Lecture 04 – Command Line Interface: terminals and shells, signals, foreground and background jobs, sessions, environment variables, how bash reads a command line, quoting, globbing and the PATH search, with a demo terminal.",
    title_html="The command line, step by step:<br><span>from a key to a process.</span>",
    lead="What a terminal and a shell are, how signals, jobs and sessions work, and what bash does with a line before the command starts: variables, quotes, globs and the PATH search.",
    features="step-by-step simulators · demo terminal with jobs and missions",
    starth="Start with the terminal and the shell.",
    maphead="From a key on the keyboard to a running process.",
    how="Text, figures, the simulators and the demo terminal were generated with Claude (Anthropic) from the slides of lecture 04 – Command Line Interface, following the structure of the interactive DEEA modules. The diagrams of the slides were redrawn.",
    checked="The command line simulator follows the order of the bash expansions (braces, ~, $NAME, word splitting, globs, quote removal) and was tested against the examples of the slides. The demo terminal simulates the jobs (sleep really waits), the signals of the keys, the PATH search and the variables; its messages follow bash and GNU coreutils. Its process list is simulated.",
)

if __name__ == "__main__":
    render(COURSE, META, OUT, js=["dev.js", "shell-cli.js", "widgets04.js"], css=CSS)
