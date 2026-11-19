#!/usr/bin/env python3
"""Build the interactive page of lecture 08 (Shell Scripting).

    python3 interactive/build_08.py
writes website/static/courses/08-shell-scripting/index.html

The debuggers (data-w="dbg") are the `debug-run` steps of the slides, ported one to one; the script labs run
the scripts in bashrun.js, a small bash interpreter of the page.
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa
from engine import _tok
from page import Course, flash as flash_cards, render, REPO

OUT = os.path.join(REPO, "website/static/courses/08-shell-scripting/index.html")
COURSE = Course()
chapter = COURSE.chapter
J = lambda *parts: "\n".join(parts)

# ---------------------------------------------------------------- bash highlighting (the same as ISOBASH.hl)
KW = {"if", "then", "elif", "else", "fi", "for", "in", "do", "done", "while", "until", "case", "esac", "function", "select", "time"}
CMDS = set("echo printf read test expr bc seq cat wc head tail grep date ls cp mv rm mkdir touch chmod sort uniq cut tr local export unset "
           "return exit break continue shift cd pwd type sleep true false bash python3 node env whoami basename dirname set source trap mktemp".split())
DOLLAR = re.compile(r"\$(?:\{[^}]*\}|\(\(|\(|[A-Za-z_]\w*|[0-9#?@*$!])")


def hlb(text):
    res = []
    for l in text.split("\n"):
        o, i, n, cmd, asg = [], 0, len(l), True, False
        span = lambda c, s: f'<span class="hl-{c}">{E(s)}</span>'
        while i < n:
            c = l[i]
            if c == "#" and (i == 0 or l[i - 1] in " \t;"):
                o.append(span("p" if i == 0 and l.startswith("#!") else "c", l[i:])); break
            if c == "'":
                e = l.find("'", i + 1); j = n if e < 0 else e + 1
                o.append(span("s", l[i:j])); i = j; cmd = False; continue
            if c == '"':
                j, buf, parts = i + 1, '"', []
                while j < n and l[j] != '"':
                    if l[j] == "\\":
                        buf += l[j:j + 2]; j += 2; continue
                    m = DOLLAR.match(l, j) if l[j] == "$" else None
                    if m and not m.group().endswith("("):
                        parts += [("s", buf), ("v", m.group())]; buf = ""; j = m.end(); continue
                    buf += l[j]; j += 1
                buf += '"' if j < n else ""; j = min(n, j + 1); parts.append(("s", buf))
                o.append("".join(span(k, s) for k, s in parts if s)); i = j; cmd = False; continue
            if c == "$":
                m = DOLLAR.match(l, i)
                if m:
                    d = m.group(); o.append(span("p" if d.endswith("(") else "v", d)); i += len(d)
                    if d.endswith("("):
                        cmd = not d.endswith("((")
                    continue
            if cmd and (c == "[" or c.isdigit()) and (i == 0 or l[i - 1] in " \t;|&("):
                wd = re.match(r"[^\s;|&()<>]+", l[i:]).group()
                o.append(span("k" if wd == "[[" else "f", wd)); i += len(wd); cmd = False; continue
            m = re.match(r"[A-Za-z_][\w-]*", l[i:])
            if m and (i == 0 or not re.match(r"[\w$]", l[i - 1])):
                w = m.group()
                if l[i + len(w):i + len(w) + 1] == "=" and re.fullmatch(r"[A-Za-z_]\w*", w):
                    asg = cmd; o.append(span("v", w)); i += len(w); cmd = False; continue
                if w in KW and (cmd or w in ("in", "do")):
                    o.append(span("k", w)); i += len(w); cmd = w not in ("for", "case", "in"); continue
                if cmd and (w in CMDS or (re.fullmatch(r"[a-z_][\w-]*", w) and l[i + len(w):].startswith("()"))):
                    o.append(span("f", w)); i += len(w); cmd = False; continue
                cmd = False
                o.append(E(w)); i += len(w); continue
            m = re.match(r"\d+", l[i:])
            if m and (i == 0 or l[i - 1] in " \t=(,") and re.match(r"($|[\s;|&)<>])", l[i + len(m.group()):]):
                o.append(span("n", m.group())); i += len(m.group()); cmd = False; continue
            if c in ";|&({`":
                cmd = True; asg = False; o.append(E(c)); i += 1; continue
            if c.isspace() and asg:
                cmd, asg = True, False
            if not c.isspace() and c != "!":
                cmd = False
            o.append(E(c)); i += 1
        res.append("".join(o))
    return "\n".join(res)


def bash(text, name=None):
    """a script, highlighted; name: the file name on top"""
    head = f'<div class="b8name">{E(name)}</div>' if name else ""
    return f'<div class="b8src">{head}<pre class="sh">{hlb(text.strip(chr(10)))}</pre></div>'


def code(text, lang):
    """a short Python or JavaScript file"""
    rules = {"python": [(r"#[^\n]*", "c"), (r'f?"(?:\\.|[^"\\])*"', "s"), (r"\b(?:def|return|import|for|in|if|else|print)\b", "k"), (r"\{[^}]*\}", "v")],
             "js": [(r"//[^\n]*", "c"), (r"`[^`]*`|\"[^\"]*\"", "s"), (r"\b(?:const|let|function|return)\b", "k"), (r"\bconsole\.log\b", "f")]}[lang]
    lines = text.strip("\n").split("\n")
    first = f'<span class="hl-p">{E(lines[0])}</span>'
    return '<pre class="sh">' + first + "\n" + _tok("\n".join(lines[1:]), rules) + "</pre>"


_table = table


def table(head, rows, cls=""):
    """engine.table, the code in the cells highlighted as bash"""
    import html as _h
    return re.sub(r"<code>(.*?)</code>", lambda m: "<code>" + hlb(_h.unescape(m.group(1))) + "</code>", _table(head, rows, cls), flags=re.S)


def chips(*ws):
    """word chips like the slides: a string, or (text, kind): cmd, new, asg, redir"""
    out = []
    for x in ws:
        t, k = (x, "") if isinstance(x, str) else x
        out.append(f'<span class="w8 {k}">{E(t) if t else "<i>&quot;&quot;</i>"}</span>')
    return "".join(out)


def shell_first(text):
    return f'<div class="b8first"><b class="b8sh" aria-hidden="true">$_</b><p>{md(text)}</p></div>'


def oneliner(note, syntax, example, out):
    """the same construct, written on one line: the rule, the syntax and a run in a terminal"""
    return (f'<div class="b8one"><h3>The same, on one line</h3><p>{md(note)}</p>'
            f'<pre class="sh">{hlb(syntax)}</pre>'
            f'<pre class="sh"><span class="p">$</span> <span class="c">{hlb(example)}</span>' + "".join(f'\n<span class="o">{E(l)}</span>' for l in out.split(chr(10))) + '</pre></div>')


# ---------------------------------------------------------------- the widgets
def _attr(d):
    return E(json.dumps(d, ensure_ascii=True, separators=(",", ":")))


def S(line, **kw):
    """a step of the debugger, the keys of debug-run (slides/src/shell.typ); out: lines, '!' marks an error"""
    if "out" in kw:
        kw["o"] = "".join(("\u0001" + x[1:] + "\n\u0002") if x.startswith("!") else x + "\n" for x in kw.pop("out"))
    kw["line"] = line
    return kw


def sc(label, code_, cmd, steps, files=None, init=None, file=None):
    d = dict(label=label, code=code_.strip("\n"), cmd=cmd, steps=steps)
    if files:
        d["files"] = files
    if init:
        d["init"] = init
    if file:
        d["file"] = file
    return d


def dbg(title, scs, sub=None):
    d = dict(title=title, sc=scs)
    if sub:
        d["sub"] = sub
    return f'<div data-w="dbg" data-d="{_attr(d)}"></div>'


def pit(title, cases, sub=None, try_=None, wh=None, files=None):
    """cases: (chip label, typed pieces (str, or [str] for the mistake), words, terminal, ok, explanation)"""
    d = dict(title=title, sc=[dict(l=c[0], typed=[p if isinstance(p, str) else [p[0]] for p in c[1]], words=c[2], out=c[3], ok=c[4], x=c[5], **(c[6] if len(c) > 6 else {})) for c in cases])
    if wh:
        d["wh"] = wh
    if files:
        d["files"] = files
    if sub:
        d["sub"] = sub
    if try_:
        d["try"] = try_
    return f'<div data-w="pit" data-d="{_attr(d)}"></div>'


def lab(setname, src, name, args="", kb=None, files=None, ex=None, title=None):
    a = f' data-set="{setname}" data-name="{E(name)}" data-src="{E(src.strip(chr(10)))}" data-args="{E(args)}"'
    if kb is not None:
        a += f' data-kb="1" data-input="{E(kb)}"'
    if files:
        a += f' data-files="{",".join(files)}"'
    if ex:
        a += f' data-ex="{_attr([dict(label=l, src=s.strip(chr(10)), **o) for l, s, *rest in ex for o in [rest[0] if rest else {}]])}"'
    if title:
        a += f' data-title="{E(title)}"'
    return f'<div data-w="lab"{a}></div>'


def split_w(modes="unq,q", ifs="def,colon", pre=None, names=None, title=None, sub=None):
    a = f' data-modes="{modes}" data-ifs="{ifs}"'
    if pre:
        a += f' data-pre="{_attr(pre)}"'
    if names:
        a += f' data-names="{E(names)}"'
    if title:
        a += f' data-title="{E(title)}"'
    if sub:
        a += f' data-sub="{E(sub)}"'
    return f'<div data-w="split"{a}></div>'


def w(name):
    return f'<div data-w="{name}"></div>'


IFS0 = {"IFS": {"v": "space tab newline", "tag": "default"}}
FRUITS = ["banana", "apple", "cherry", "apple", "kiwi", "banana", "apple"]

# ---------------------------------------------------------------- the figures, redrawn as SVG
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


def fig_outcode():
    """a function prints its output and ends with an exit code: two different roads"""
    b = _r(10, 92, 170, 76, ("#e8f1f3", NAVY), 10) + _t(95, 120, "a command", 14, 700, NAVY) + _t(95, 148, "greet alice", 16, 700, mono=True)
    # the output
    b += _a([(180, 110), (240, 60), (282, 60)], "orange", 2.4) + _t(222, 40, "prints", 14, 600, "#b35900")
    b += _r(284, 22, 222, 76, ORANGE) + _t(395, 48, "the output, on stdout", 14, 700, "#8a4b00") + _t(395, 78, "Hello, alice!", 16, 700, "#b35900", mono=True)
    b += _a([(506, 60), (632, 60)], "orange", 2.4) + _t(569, 50, "goes to", 14, 400, MUTED)
    b += _r(634, 14, 216, 92, ("#fff", "#d79b00"), 10) + _t(742, 40, "the screen, or a variable", 13.5, 700, "#8a4b00") + _t(742, 66, "Hello, alice!", 14, 400, INK, mono=True) + _t(742, 92, "msg=$(greet alice)", 13.5, 600, NAVY, mono=True)
    # the exit code
    b += _a([(180, 150), (240, 200), (282, 200)], "green", 2.4) + _t(222, 236, "ends with", 14, 600, "#2e7d46")
    b += _r(284, 162, 222, 76, GREEN) + _t(395, 188, "the exit code: 0 – 255", 14, 700, "#2e7d46") + '<circle cx="395" cy="215" r="15" fill="#2e7d46"/>' + _t(395, 221, "0", 16, 800, "#fff", mono=True)
    b += _a([(506, 200), (632, 200)], "green", 2.4) + _t(569, 190, "checked by", 14, 400, MUTED)
    b += _r(634, 154, 216, 92, ("#fff", "#82b366"), 10) + _t(742, 180, "success or error?", 14, 700, "#2e7d46") + _t(742, 206, "if  &&  ||  $?", 14, 600, INK, mono=True) + _t(742, 232, "greet alice && echo ok", 13.5, 600, NAVY, mono=True)
    return svgfig(860, 256, b, "A command prints its output and ends with an exit code")


def param_map(cmd, args, names=None):
    names = names or [f"${k + 1}" for k in range(len(args))]
    cells = f'<div><span class="w8 cmd">{E(cmd)}</span><b>$0</b></div>' + "".join(f'<div><span class="w8">{E(a)}</span><b>{E(n)}</b></div>' for a, n in zip(args, names))
    return f'<div class="b8pm">{cells}<div class="b8pmn"><code>$#</code> = <code>{len(args)}</code></div></div>'


# ================================================================ 01 shell scripts
BACKUP = """#!/bin/bash
echo "backing up"
mkdir -p ~/backup
cp notes.txt ~/backup/
echo "done\""""
page = chapter("scripts", "Shell scripts", "Command lines, saved in a file: `#!`, `chmod +x`, `./script.sh`", 16)
page("commands", "The shell runs commands", "A programming language, added on top", J(
    why("A script automates what you would type: backups, building a project, renaming 300 files. Every line of it is still a **command line**: words, separated by spaces. Remembering this explains almost every mistake of this lecture."),
    duo(sh("""$ mkdir -p ~/backup
$ cp ~/notes.txt ~/backup/
$ echo "backup done"
backup done""", caption="you type the commands, one by one"),
        bash("""#!/bin/bash
mkdir -p ~/backup
cp ~/notes.txt ~/backup/
echo "backup done\"""", "backup.sh") + '<p class="small">or you save them in a file, and <code>bash</code> runs them for you</p>'),
    ul("the shell was made to **run commands**: read a line, split it into words, run the command",
       "a *shell script* is a file with command lines; the shell runs them one after another",
       "variables, conditions, loops and functions were added **on top**: everything is still a command line"),
    '<div class="trio">'
    f'<div class="panel b8card"><h3><b class="b8sh" aria-hidden="true">$_</b> Ask: what command runs here?</h3><p class="cap"><code>[ $a -lt $b ]</code> is the command <code>[</code>:</p><p>{chips(("[", "cmd"), "2", "-lt", "3", "]")}</p></div>'
    f'<div class="panel b8card ok"><h3>✅ Great for gluing commands</h3><p>{chips(("mkdir", "cmd"))} → {chips(("cp", "cmd"))} → {chips(("echo", "cmd"))}</p></div>'
    '<div class="panel b8card no"><h3>❌ Bad for heavy computation</h3><p class="cap">Integers only, slow. Use Python, C, Rust, ... for that.</p></div></div>',
))
page("syntax", "Script syntax", "`#!`, `#`, `;` and `\\`", J(
    p("A script is a text file: one command line after another, run from top to bottom."),
    duo(bash("""#!/bin/bash
# backup.sh - back up the notes
mkdir -p ~/backup
cd ~/backup; ls
cp ~/notes.txt \\
   ~/backup/""", "backup.sh"),
        table(["Part", "What it is"], [
            ("`#!/bin/bash`", "the *shebang*: the program that runs the file; for `bash` it is just a comment"),
            ("`# ...`", "a comment, until the end of the line"),
            ("one line", "one command line"),
            ("`;`", "several commands on the same line"),
            ("`\\` at the end", "the command line goes on, on the next line")], "k")),
    dbg("A script runs line by line", [sc("backup.sh", BACKUP, "./backup.sh", [
        S(1, expand="/bin/bash", run="/bin/bash ./backup.sh", info="started by the kernel", note="`#!` – the program that runs the script; for `bash` the line is a comment."),
        S(2, run='echo "backing up"', status=0, out=["backing up"]),
        S(3, run="mkdir -p /home/student/backup", status=0, note="The shell replaces `~` before running the command, like in the terminal."),
        S(4, run="cp notes.txt /home/student/backup/", status=0),
        S(5, run='echo "done"', status=0, out=["done"], note="No more lines: the script ends.")], files={"notes.txt": ["buy milk", "call mom"]})]),
))
page("run", "`./backup.sh` or `bash backup.sh`", "Running a script", J(
    p("`./backup.sh` asks the **kernel** to run the file: it needs `x` and reads `#!`. `bash backup.sh` runs `bash`, which only reads the file."),
    sh("""$ chmod +x backup.sh  # once: the execute permission
$ ./backup.sh
backing up
done
$ bash backup.sh  # no x needed
backing up
done"""),
    w("runsc"),
    bad("`backup.sh` instead of `./backup.sh`", "Without a `/`, the shell searches the name in `PATH`, and the current folder is not in `PATH`: `bash: backup.sh: command not found`.", "write the path, `./backup.sh`, or run `bash backup.sh`."),
))
GO = """#!/bin/bash
cd ~/backup
where="backup\""""
page("source", "`source backup.sh`: in your own shell", "Running a script with `source`", J(
    p("`source backup.sh` (or `. backup.sh`) starts **no new process**: your shell reads the file and runs its lines itself, as if you typed them. What the file changes stays in your shell."),
    '<div data-w="runsc" data-list="source,bash"></div>',
    duo(bash(GO, "go.sh"),
        sh('$ bash go.sh\n$ echo "$PWD [$where]"\n/home/student []\n$ source go.sh\n$ echo "$PWD [$where]"\n/home/student/backup [backup]')),
    table(["Command", "Who runs the lines", "It needs", "The `cd` and the variables"], [
        ("`./go.sh`", "a new `bash`, started by the kernel", "`x` and the shebang", "lost when it ends"),
        ("`bash go.sh`", "a new `bash`", "`r`", "lost when it ends"),
        ("`source go.sh`, `. go.sh`", "**your** shell", "`r`", "**stay** in your shell")]),
    bad("`exit` in a file run with `source`", "It ends **your** shell, and the terminal closes.",
        "use `source` only for files that must change your shell (`~/.bashrc`, a file of functions), and leave `exit` out of them."),
    quiz("`go.sh` runs `cd ~/backup`. After which command is **your** shell in `~/backup`?", ["`./go.sh`", "`bash go.sh`", "`source go.sh`", "`sh go.sh`"], 2,
         "Only `source` runs the lines in your shell; the others start a new process, whose `cd` is lost when it ends."),
))
page("shebang", "The shebang, for any language", "`#!/usr/bin/python3`, `#!/usr/bin/env node`", J(
    p("The kernel runs the program written after `#!`, with the file as its parameter. The same `chmod +x` and `./name` work for any language."),
    duo(code('''#!/usr/bin/python3
name = "alice"
print(f"Hello, {name}!")''', "python") + sh("$ ./hello.py\nHello, alice!") + f'<p class="small">the kernel runs {chips(("/usr/bin/python3", "cmd"), ("./hello.py", "new"))}</p>',
        code('''#!/usr/bin/env node
const name = "alice";
console.log(`Hello, ${name}!`);''', "js") + sh("$ ./hello.js\nHello, alice!") + f'<p class="small">the kernel runs {chips(("/usr/bin/env", "cmd"), "node", ("./hello.js", "new"))}</p>'),
    note("`/usr/bin/env node`", "`env` searches `node` in `PATH`: useful when you do not know where it is installed.", "blue"),
    shell_first("You do not need to know the language of a script: `./backup.sh`, `./hello.py` and `./hello.js` all run the same way."),
    quiz("`notes.sh` has no `x` permission. Which command still runs it?", ["`./notes.sh`", "`bash notes.sh`", "`notes.sh`", "none, `chmod +x` is needed first"], 1,
         "`bash notes.sh` runs `bash` (which has `x`); `bash` only reads the file. `./notes.sh` asks the kernel to run the file itself, which needs `x`."),
))
page("practice", "Cheat sheet and practice", "Shell scripts", J(
    table(["Write", "Means"], [
        ("`#!/bin/bash`", "the first line: the program that runs the file"), ("`# text`", "a comment"),
        ("`cmd1; cmd2`", "two commands on one line"), ("`cmd \\`", "the line goes on below"),
        ("`chmod +x s.sh`, `./s.sh`", "run the file: the kernel reads `#!`"), ("`bash s.sh`", "run `bash`, the script is its parameter"),
        ("`source s.sh`, `. s.sh`", "run the lines in this shell: its `cd` and variables stay")], "k"),
    lab("scripts", BACKUP, "./backup.sh", files=["notes.txt", "fruits.txt", "lib.sh"]),
))

# ================================================================ 02 variables
VARS = """#!/bin/bash
name="alice"
greeting="Hello, $name"
echo "$greeting!"
name="bob"
echo "$greeting!\""""
page = chapter("vars", "Variables", "Everything is text: define, use, change, delete, export", 14)
page("syntax", "Define, use, change, delete, export", "Variable syntax", J(
    p("`NAME=value` stores the text, `$NAME` puts it back in a command line. **No spaces** around `=`."),
    dbg("A variable, typed in a terminal", [sc("in a terminal", """name="alice"
echo "Hi, $name"
echo "${name}_notes.txt"
name="bob"
unset name
export name="carol\"""", "", [
        S(1, run="name=alice", vars={"name": "alice"}, note="`NAME=value` – **define**: the shell keeps the text `alice`."),
        S(2, run='echo "Hi, alice"', status=0, out=["Hi, alice"], note="`$NAME` – **use**: the shell replaces it with the value, then runs `echo`."),
        S(3, run='echo "alice_notes.txt"', status=0, out=["alice_notes.txt"], note="`${NAME}` – when letters follow: without `{}`, `$name_notes` would be a variable that does not exist, and the line would print `.txt`."),
        S(4, run="name=bob", vars={"name": "bob"}, note="`NAME=value` again – **change** it."),
        S(5, run="unset name", status=0, unset=["name"], note="`unset NAME` – **delete** it. A deleted variable is just **empty**: `echo \"Hi, $name\"` prints `Hi, `, no error."),
        S(6, run='export name="carol"', status=0, vars={"name": "carol"}, tags={"name": "exported"}, note="`export` – put it in the *environment*: a child process (`python3`, another script) starts with a **copy** of it.")],
        file="typed in bash")], sub="Six commands typed one after another: what the shell keeps, and what it runs."),
))
page("text", "A variable holds text, not a formula", "Replaced when the line runs", J(
    p("The shell replaces `$name` **when the line runs**. `greeting` keeps the text it got then, not the recipe."),
    dbg("Variables hold text", [sc("vars.sh", VARS, "./vars.sh", [
        S(2, run='name="alice"', vars={"name": "alice"}, note="`name` holds the text `alice`."),
        S(3, run='greeting="Hello, alice"', vars={"greeting": "Hello, alice"}, note="The shell replaces `$name` **now**: `greeting` holds plain text."),
        S(4, run='echo "Hello, alice!"', status=0, out=["Hello, alice!"]),
        S(5, run='name="bob"', vars={"name": "bob"}),
        S(6, run='echo "Hello, alice!"', status=0, out=["Hello, alice!"], note="`greeting` did not change: it is text, not a formula.")])]),
))
page("wrong", "Wrong definitions: a space splits the line", "No spaces around `=`", J(
    p("A line starts with a **command**. A `NAME=value` word before it is a variable **only for that command**."),
    pit("What does the shell see?", [
        ("name = alice", ["", ["name = "], '"alice"'], [["name", "cmd"], ["=", ""], ["alice", ""]], '$ name = "alice"\n!bash: name: command not found', False,
         "The command `name`, with the parameters `=` and `alice`."),
        ("name =alice", ["", ["name ="], '"alice"'], [["name", "cmd"], ["=alice", ""]], '$ name ="alice"\n!bash: name: command not found', False,
         "The command `name`, with the parameter `=alice`."),
        ("name= alice", ["", ["name= "], '"alice"'], [["name=", "asg"], ["alice", "cmd"]], '$ name= "alice"\n!bash: alice: command not found', False,
         "`name=` – an **empty** variable, only for the command `alice`."),
        ("name=alice smith", ["name=alice", [" smith"]], [["name=alice", "asg"], ["smith", "cmd"]], "$ name=alice smith\n!bash: smith: command not found", False,
         "The space ends the value: `name=alice` is a variable only for the command `smith`."),
        ("$name=alice", ["", ["$name"], "=alice"], [["bob=alice", "cmd"]], "$ name=bob\n$ $name=alice\n!bash: bob=alice: command not found", False,
         "`$` is for **using** a variable, not for defining it. The shell replaces `$name` first: `bob=alice` is no longer an assignment (bash looks for `NAME=` before it replaces anything), it is the name of a command. With `name` empty, the command is `=alice`."),
        ("$name = alice", ["", ["$name = "], "alice"], [["bob", "cmd"], ["=", ""], ["alice", ""]], "$ name=bob\n$ $name = alice\n!bash: bob: command not found", False,
         "Both mistakes at once: `$name` is replaced by its value, and the spaces make three words – the command `bob`, with the parameters `=` and `alice`. With `name` empty, the word disappears and the command is `=`."),
        ('name="alice smith"', ["name=", ['"alice smith"']], [["name=alice smith", "new"]], '$ name="alice smith"\n$ echo "$name"\nalice smith', True,
         "One word: **no spaces** around `=`, the quotes keep the space in the value.")],
        try_=dict(v="$name=alice", vars={"name": "bob"}, note="`name=bob` is already set. The dashed chip is a variable only for the command; the dark one is the command.")),
))
page("count", "Measuring a variable: `wc -c` and `wc -l`", "`wc` counts the text it gets from a pipe", J(
    p("`wc` does not see the variable, only the **text** that `echo` prints into the pipe, and the newline of `echo` counts too."),
    sh("""$ name="Alice Smith"
$ echo "$name" | wc -c
12
$ echo -n "$name" | wc -c
11
$ fruits=$(sort -u fruits.txt)
$ echo "$fruits" | wc -l
4"""),
    table(["Write", "Gives"], [
        ("`echo \"$name\" | wc -c`", "the characters, **and** the newline of `echo`: `12`"),
        ("`echo -n \"$name\" | wc -c`", "the length of the text: `11` (`-n`: no newline)"),
        ("`echo \"${#name}\"`", "the same `11`, counted by `bash` itself"),
        ("`echo \"$fruits\" | wc -l`", "the lines: `4`, one fruit per line")], "k"),
    bad("An empty variable is one line", "With `x=\"\"`, `echo \"$x\" | wc -l` prints `1`: `echo` prints the newline anyway.", "check that the variable is not empty first."),
))
page("practice", "Cheat sheet and practice", "Variables", J(
    table(["Write", "Means"], [
        ("`name=\"alice\"`", "define or change, no spaces around `=`"), ("`$name`, `\"$name\"`", "the value takes its place"),
        ("`${name}_notes`", "the name ends at `}`"), ("`unset name`", "delete: it is empty after"),
        ("`export name`", "put it in the environment of the child processes"), ("`name=value cmd`", "a variable only for `cmd`")], "k"),
    lab("vars", 'name="alice"\necho "Hi, $name"', "./vars.sh"),
))

# ================================================================ 03 words and IFS
SPACES = """#!/bin/bash
v="  a   b  "
printf '[%s]' $v; echo
IFS=:
v="a b::c"
printf '[%s]' $v; echo
unset IFS
printf '[%s]' $v; echo"""
page = chapter("words", "Words and IFS", "How many words does a variable become?", 14)
page("ifs", "`IFS`: where the shell cuts", "*Internal Field Separator*", J(
    p("`IFS` is a variable of the shell; its characters are the **separators**. By default: space, tab and newline. The shell uses it to cut an **unquoted** `$NAME` (and, later, the line that `read` reads)."),
    duo(sh("""$ printf '%q\\n' "$IFS"
$' \\t\\n'"""), f'<p class="txt"><code>printf \'%q\'</code> shows the invisible characters: a space, <code>\\t</code> (tab), <code>\\n</code> (newline).</p><p>{chips("IFS")} = {chips(("space", "new"), ("tab", "new"), ("newline", "new"))}</p>'),
))
page("split", "An unquoted `$x` is cut at `IFS`", "Splitting a variable", J(
    p("Before running `printf '[%s]\\n' $x`, the shell does three things:"),
    steps("**replace**: `$x` becomes its value, `Alice   Smith:20`",
          "**cut**: the value is cut at the characters of `IFS` (by default: space, tab, newline); every piece becomes a separate word",
          "**run**: `printf` gets the words `Alice` and `Smith:20`"),
    sh("""$ x="Alice   Smith:20"
$ printf '[%s]\\n' $x
[Alice]
[Smith:20]
$ echo $x
Alice Smith:20"""),
    p("`printf '[%s]\\n'` prints every word it gets between `[ ]`, one per line. `echo` also gets 2 words and prints them with **one** space: the 3 spaces are lost."),
    '<h2>Two kinds of separators</h2>',
    p("The characters of `IFS` do not all cut the same way. **Space, tab and newline are the exception**: they are *blanks*, and the shell treats them gently."),
    table(["In `IFS`", "Several in a row", "At the start or the end", "Example"], [
        ("**space, tab, newline** (the blanks)", "**one** cut: `a   b` → `a` `b`", "**dropped**: `␣␣a␣b␣␣` → `a` `b`", "`IFS` default, `x=\"  a   b  \"` → `[a][b]`"),
        ("**any other character**, e.g. `:` `,`", "**every one** cuts: `a::b` → `a` `\"\"` `b`, an **empty** word in the middle", "at the start: an empty first word, `:a` → `\"\"` `a`; at the end: nothing, `a:` → `a`", "`IFS=:`, `x=\"a b::c\"` → `[a b][][c]`")]),
    p("A blank that is **not** in `IFS` is a normal character: with `IFS=:`, the space in `a b` does not cut, `a b` stays one word."),
    split_w("unq", "def,colon", ["Alice   Smith:20", "  a   b  ", "a b::c", ":a:b:"], title="Cut a value at IFS",
            sub="Type a value and choose `IFS`: the separators are orange, every piece is a word. Compare the spaces with `:`."),
))
page("spaces", "Spaces are special", "Many spaces are one cut", J(
    p("The two kinds of separators in one script: first the blanks (many in a row are one cut, the ends are dropped), then `:` (every one cuts, `::` makes an empty word)."),
    dbg("Spaces are special", [sc("spaces.sh", SPACES, "./spaces.sh", [
        S(1, vars={"IFS": "space tab newline"}, tags={"IFS": "default"}, note="The script starts, nobody set `IFS`: it has the **default** value, space, tab and newline."),
        S(2, run='v="  a   b  "', vars={"v": "  a   b  "}),
        S(3, part="printf '[%s]' $v", run="printf '[%s]' a b", status=0, out=["[a][b]"], note="Cut at the spaces: many in a row are **one** cut, at the ends they are dropped."),
        S(4, run="IFS=:", vars={"IFS": ":"}, tags={"IFS": None}, note="`IFS` is not the default any more: now only `:` is a separator."),
        S(5, run='v="a b::c"', vars={"v": "a b::c"}),
        S(6, part="printf '[%s]' $v", run="printf '[%s]' 'a b' '' c", status=0, out=["[a b][][c]"], note="Cut at `:` – `::` makes an **empty** word, the space is a normal character."),
        S(7, run="unset IFS", vars={"IFS": "space tab newline"}, tags={"IFS": "not set, default"}, note="`IFS` is deleted: when it is **not set**, the shell uses the default again."),
        S(8, part="printf '[%s]' $v", run="printf '[%s]' a b::c", status=0, out=["[a][b::c]"], note="Cut at the space again: `:` is a normal character.")])]),
))
page("quotes", "Quotes keep one word", "Quoting and `IFS`", J(
    p("`IFS` cuts an **unquoted** value. Quoted, `\"$x\"` is always **one** word, whatever `IFS` is, with its spaces."),
    split_w("unq,q", "def,colon,comma,empty", ["Alice   Smith:20", "  a   b  ", "a b::c", "alice,Alice Smith"], title="Unquoted or quoted?"),
    shell_first("Quotes say \"one word\": write `\"$NAME\"` in quotes, unless you **want** it cut."),
    quiz("`x=\"a  b\"`. How many words does `printf '[%s]' \"$x\"` get after the format?", ["0", "1", "2", "3"], 1,
         "Quoted: one word, `a  b`, with both spaces. Unquoted it would be 2 words, `a` and `b`."),
))
page("practice", "Cheat sheet and practice", "Words and IFS", J(
    table(["Write", "The words"], [
        ("`$x`", "the value, cut at the characters of `IFS`"), ("`\"$x\"`", "the value, one word, the spaces kept"),
        ("`IFS=:`", "now only `:` cuts, for the whole script"), ("`unset IFS`", "back to space, tab, newline"),
        ("`printf '[%s]\\n' $x`", "shows every word between `[ ]`"), ("`printf '%q\\n' \"$IFS\"`", "shows the invisible characters")], "k"),
    lab("words", "x=\"Alice   Smith:20\"\nprintf '[%s]\\n' $x", "./words.sh"),
))

# ================================================================ 04 reading input
HELLO = """#!/bin/bash
read -p "Full name: " first last
echo "$last, $first"
IFS=: read -p "Date: " d m y
echo "$y-$m-$d\""""
page = chapter("read", "Reading input", "`read`, `-p`, `-r`, `IFS=: read`", 14)
page("syntax", "`read`: one line from `stdin` into variables", "`read` syntax", J(
    p("`read` is a **built-in** of the shell: it waits for a line (until [[Enter]]) and puts it in variables."),
    table(["Write", "Means"], [
        ("`read NAME`", "waits for a line, puts the whole line in `NAME`"),
        ("`read -p \"Your name: \" NAME`", "`-p`: writes a *prompt* (a question) first"),
        ("`read first last`", "several names: the line is **cut** at `IFS`, one word for every variable, the last one takes the rest"),
        ("`read -r line`", "`-r`, *raw*: keeps the `\\` characters as they are"),
        ("`read -s password`", "`-s`, *silent*: does not show what the user types")], "k b8nw"),
    note("`read` has an exit code too", "`0` if it read a line, `1` at the end of the input ([[Ctrl]] + [[D]]): `while read` (in *Loops*) stops on it.", "blue"),
))
page("ifs", "`IFS=: read`: `IFS` only for this `read`", "Fields separated by `:`", J(
    p("`NAME=value` before a command is a variable **only for that command**: after `read`, `IFS` is back to space, tab, newline."),
    sh("""$ head -n 1 /etc/passwd
root:x:0:0:root:/root:/bin/bash
$ IFS=: read user x uid rest < /etc/passwd
$ echo "$user has UID $uid"
root has UID 0
$ echo "$rest"
0:root:/root:/bin/bash"""),
    split_w("read", "colon,def", ["root:x:0:0:root:/root:/bin/bash", "Alice Mary Smith", "2:11:2026"], names="user x uid rest",
            title="What read puts in every variable", sub="One word for every variable; the **last** one takes the rest of the line."),
    pit("IFS=: before another command", [
        ("IFS=: printf", ["", ["IFS=: "], "printf '[%s]\\n' $x"], [["IFS=:", "asg"], ["printf", "cmd"], ["[%s]\\n", ""], ["Bob", "new"], ["Jones:20", "new"]],
         "$ x=\"Bob   Jones:20\"\n$ IFS=: printf '[%s]\\n' $x\n[Bob]\n[Jones:20]", False,
         "The shell cuts `$x` **before** it starts `printf`, with its own `IFS`, the default: the spaces cut, `:` does not. `IFS=:` reaches only `printf`, which never cuts anything. `read` is different: it cuts the line **it** reads, while it runs, so it sees `IFS=:`."),
        ("IFS=:; printf", ["", ["IFS=:; "], "printf '[%s]\\n' $x; unset IFS"], [["printf", "cmd"], ["[%s]\\n", ""], ["Bob   Jones", "new"], ["20", "new"]],
         "$ IFS=:; printf '[%s]\\n' $x; unset IFS\n[Bob   Jones]\n[20]", True,
         "`IFS=:` on its own changes the `IFS` of the shell, so the shell cuts `$x` at `:`. `unset IFS` goes back to the default.")],
        sub="`IFS=: read` works; the same `IFS=:` before `printf` does not.", wh="the words the shell gives to the command"),
))
page("debug", "The script waits for the keyboard", "🐞 `read`", J(
    dbg("read", [sc("hello.sh", HELLO, "./hello.sh", [
        S(2, run='read -p "Full name: " first last', status=0, out=["Full name: Alice Mary Smith"], vars={"first": "Alice", "last": "Mary Smith"}, info="reads `Alice Mary Smith`",
          note="`read` writes the question, then **waits** for a line: the user types `Alice Mary Smith` and Enter."),
        S(3, run='echo "Mary Smith, Alice"', status=0, out=["Mary Smith, Alice"], note="Cut at the spaces, one word for every variable: the **last** one, `last`, takes the rest."),
        S(4, part='IFS=: read -p "Date: " d m y', run='IFS=: read -p "Date: " d m y', status=0, out=["Date: 2:11:2026"], vars={"d": "2", "m": "11", "y": "2026"}, info="reads `2:11:2026`",
          note="`IFS=:` only for this `read`: the line is cut at `:`."),
        S(5, run='echo "2026-11-2"', status=0, out=["2026-11-2"], note="After `read`, `IFS` is back to space, tab and newline.")])], sub="The user types two lines: `Alice Mary Smith`, then `2:11:2026`."),
))
page("pitfalls", "The pitfalls of `read`", "`-r`, `IFS=`, and pipes", J(
    p("By default, `read` does not give you the line exactly as it is in the file. It changes it in two ways, and each one has its own fix:"),
    table(["The line in the file", "`read l` gives", "Why", "The fix"], [
        ("`C:\\new\\temp`", "`C:newtemp`", "`\\` is an escape for `read`: it removes it", "`-r` (*raw*): keep the `\\`"),
        ("`   two  spaces  `", "`two  spaces`", "the spaces at the start and at the end are in `IFS`: `read` cuts them", "`IFS=` (empty), only for this `read`: nothing is cut")], "k b8nw"),
    p("Both fixes together read a line **exactly** as it is: `IFS= read -r line`. A third trap is not about the text: after a `|`, `read` runs in a copy of the shell and its variables are lost."),
    pit("read changes the line", [
        ("without -r", ["", ["read p"], " < path.txt; echo \"$p\""], [["C:newtemp", "new"]], "$ cat path.txt\nC:\\new\\temp\n$ read p < path.txt; echo \"$p\"\nC:newtemp", False,
         "Without `-r`, `read` treats `\\` as an escape and removes it."),
        ("read -r", ["", ["read -r p"], " < path.txt; echo \"$p\""], [["C:\\new\\temp", "new"]], "$ read -r p < path.txt; echo \"$p\"\nC:\\new\\temp", True,
         "`read -r` keeps the line as it is."),
        ("spaces cut", ["", ["read l"], " < spaces.txt; echo \"[$l]\""], [["two  spaces", "new"]], "$ cat spaces.txt\n   two  spaces  \n$ read l < spaces.txt; echo \"[$l]\"\n[two  spaces]", False,
         "The spaces at the start and at the end are cut: they are in `IFS`."),
        ("IFS= read -r", ["", ["IFS= read -r l"], " < spaces.txt; echo \"[$l]\""], [["   two  spaces  ", "new"]], "$ IFS= read -r l < spaces.txt; echo \"[$l]\"\n[   two  spaces  ]", True,
         "`IFS=` (empty) only for this `read`: nothing is cut."),
        ("after a pipe", ['echo "Alice Smith" ', ["| read first last"], '; echo "[$first]"'], [["first = \"\"", "new"]], '$ echo "Alice Smith" | read first last; echo "[$first]"\n[]', False,
         "After a `|`, `read` runs in a **copy** of the shell: `first` is set in the copy, then lost. Use `< file`: `read` runs in the shell itself.")],
        sub="Pick a line: what the variable gets, and the terminal.", wh="what `read` puts in the variable"),
))
page("practice", "Cheat sheet and practice", "Reading input", J(
    table(["Write", "Means"], [
        ("`read x`", "one line from `stdin` into `x`"), ("`read -p \"Q: \" x`", "ask first"), ("`read a b`", "cut at `IFS`, the last gets the rest"),
        ("`IFS=: read a b c`", "cut at `:`, only for this `read`"), ("`IFS= read -r line`", "the line exactly as it is"), ("`read x < file`", "the first line of a file")], "k"),
    lab("read", 'read -p "Your name: " name\necho "Hello, $name!"', "./hello.sh", kb="alice\n2:11:2026", files=["fruits.txt", "path.txt", "spaces.txt"]),
))

# ================================================================ 05 command substitution
SUBST = """#!/bin/bash
count=$(wc -l < fruits.txt)
today=$(date +%A)
echo "$count fruits on $today\""""
page = chapter("subst", "Command substitution", "`$(command)`: the output of a command, as text", 12)
page("syntax", "`$(command)`: replaced by the output", "Command substitution syntax", J(
    duo(bash("""VAR=$(command arg1 arg2)
command1 $(command2 arg)
VAR=`command arg1 arg2`"""), ul("`$(command)` – run the command, put its **output** in its place",
                                   "anywhere in a command line, also inside `\"...\"`", "<code>&#96;command&#96;</code> – the old way to write it")),
    w("subst"),
    note("A copy of the shell", "The command runs in a *subshell*: a variable changed inside `$(...)` does not change in the script.", "warn"),
))
page("debug", "Command substitution, step by step", "🐞 `$(...)`", J(
    dbg("Command substitution", [sc("fruits.sh", SUBST, "./fruits.sh", [
        S(2, part="wc -l < fruits.txt", who="copy", run="wc -l < fruits.txt", status=0, info="prints `7`", note="First, a copy of `bash` runs the command; its output is captured, nothing reaches the screen."),
        S(2, run="count=7", vars={"count": "7"}, note="Then the output takes the place of `$(...)` and the shell runs the line."),
        S(3, part="date +%A", who="copy", run="date +%A", status=0, info="prints `Thursday`"),
        S(3, run="today=Thursday", vars={"today": "Thursday"}),
        S(4, run='echo "7 fruits on Thursday"', status=0, out=["7 fruits on Thursday"])], files={"fruits.txt": FRUITS})]),
))
page("words", "The output becomes words", "Newlines separate words", J(
    sh("""$ count=$(wc -l < fruits.txt)
$ echo "$count fruits"
7 fruits
$ echo "today is $(date +%A)"
today is Thursday
$ files=$(ls *.txt); echo $files
fruits.txt notes.txt words.txt"""),
    p("The output of `ls` has one name per line. Unquoted, the *newlines* of the output separate words, like spaces: `echo` gets 3 words."),
    shell_first("The way to get a result from a command is to **capture its output**: commands print text."),
    quiz("What does `x=$(echo hi; echo there)` put in `x`?", ["`hi there`", "`hi` and a newline and `there`", "`hi`", "`there`"], 1,
         "The whole output, as text: `hi`, a newline, `there`. Only the **last** newline is removed."),
))
page("practice", "Cheat sheet and practice", "Command substitution", J(
    table(["Write", "Means"], [
        ("`x=$(cmd)`", "the output of `cmd` in `x`, the last newline removed"), ("`echo \"... $(cmd) ...\"`", "anywhere in a line, also in quotes"),
        ("`for w in $(cat f)`", "unquoted: the output is cut into words"), ("<code>x=&#96;cmd&#96;</code>", "the old syntax")], "k"),
    lab("subst", 'count=$(wc -l < fruits.txt)\necho "$count fruits"', "./fruits.sh"),
))

# ================================================================ 06 arithmetic
NAIVE = """#!/bin/bash
a=2
b=3
sum=$a+$b
echo $sum
$a + $b"""
EXPR = """#!/bin/sh
a=2
b=3
sum=$(expr $a + $b)
echo $sum"""
ARITH = """#!/bin/bash
a=2
b=3
sum=$((a + b))
echo "sum is $sum"
echo $((a * b + 1))
echo "$a + $b = $((a + b))\""""
BC = """#!/bin/bash
price=3.5
count=2
total=$(echo "$price * $count" | bc)
echo "total: $total"
whole=$(echo "$total / 1" | bc)
echo "times 10: $((whole * 10))\""""
page = chapter("arith", "Arithmetic", "`expr`, `(( ))`, `$(( ))` and decimals with `bc`", 24)
page("naive", "Adding two numbers?", "What you might expect to work", J(
    dbg("Adding two numbers?", [sc("math.sh", NAIVE, "./math.sh", [
        S(2, run="a=2", vars={"a": "2"}), S(3, run="b=3", vars={"b": "3"}),
        S(4, run="sum=2+3", vars={"sum": "2+3"}, note="❌ The variables are replaced, `+` is just a character: `sum` holds the **text** `2+3`."),
        S(5, run="echo 2+3", status=0, out=["2+3"], note="❌ `echo` prints the text, nothing was computed."),
        S(6, run="2 + 3", status=127, out=["!./math.sh: line 6: 2: command not found"], note="❌ A line starts with a **command**: the shell looks for a program named `2`.")])]),
))
page("text", "Text, not numbers", "`a=2` and `b=3`", J(
    pit("What does the shell see?", [
        ("echo $a+$b", ["echo ", ["$a+$b"]], [["echo", "cmd"], ["2+3", "new"]], "$ a=2; b=3\n$ echo $a+$b\n2+3", False, "**One** word: `$a`, the text `+`, `$b`."),
        ("echo $a + $b", ["echo ", ["$a + $b"]], [["echo", "cmd"], ["2", "new"], ["+", "new"], ["3", "new"]], "$ echo $a + $b\n2 + 3", False, "**Three** words, `echo` prints them with a space between."),
        ("$a + $b", [["$a"], " + $b"], [["2", "cmd"], ["+", ""], ["3", ""]], "$ $a + $b\n!bash: 2: command not found", False, "The first word is the **command**: there is no program `2`."),
        ("c=$a+$b", ["c=", ["$a+$b"]], [["c=2+3", "new"]], "$ c=$a+$b; echo $c\n2+3", False, "A variable holds **text**: `c` is the text `2+3`.")],
        try_=dict(v="echo $a+$b", vars={"a": "2", "b": "3"}, note="`a=2` and `b=3` are already set.")),
    shell_first("bash was made to run commands, not to do math: `+` is just a character and a line always starts with a command."),
))
page("expr", "`expr`: a program that computes", "Works in every shell", J(
    dbg("Computing with expr", [sc("expr.sh", EXPR, "./expr.sh", [
        S(2, run="a=2", vars={"a": "2"}), S(3, run="b=3", vars={"b": "3"}),
        S(4, part="expr $a + $b", who="copy", run="expr 2 + 3", status=0, info="prints `5`", note="`expr` gets three parameters: a number, an operator, a number. It computes and **prints** the result."),
        S(4, run="sum=5", vars={"sum": "5"}, note="Command substitution puts the output of `expr` in `sum`."),
        S(5, run="echo 5", status=0, out=["5"], note="`#!/bin/sh`: `expr` works even in shells that have no arithmetic of their own.")])]),
))
page("exprpit", "`expr` pitfalls", "The shell expands the parameters first", J(
    pit("What does expr get?", [
        ("expr $a + $b", ["expr ", ["$a + $b"]], [["expr", "cmd"], ["2", "new"], ["+", "new"], ["3", "new"]], "$ a=2; b=3\n$ expr $a + $b\n5", True, "Three parameters: a number, an operator, a number."),
        ("expr $a+$b", ["expr ", ["$a+$b"]], [["expr", "cmd"], ["2+3", "new"]], "$ expr $a+$b\n2+3", False, "**One** parameter: nothing to compute, `expr` prints it back."),
        ("expr $a \\* $b", ["expr $a ", ["\\*"], " $b"], [["expr", "cmd"], ["2", ""], ["*", "new"], ["3", ""]], "$ expr $a \\* $b\n6", True, "`\\*`: the `*` is a character, not a glob."),
        ("expr $a * $b", ["expr $a ", ["*"], " $b"], [["expr", "cmd"], ["2", ""], ["fruits.txt", "new"], ["notes.txt", "new"], ["words.txt", "new"], ["3", ""]],
         "$ expr $a * $b\n!expr: syntax error: unexpected argument ‘fruits.txt’", False, "The shell **globs** `*` into the file names, before `expr` starts.")],
        try_=dict(v="expr $a * $b", vars={"a": "2", "b": "3"}, note="The folder has `fruits.txt`, `notes.txt` and `words.txt`.")),
    shell_first("The shell does not know that `expr` wants math: it expands the command line the same way for every command."),
))
page("syntax", "`(( ))` and `$(( ))`: the shell computes", "Arithmetic syntax", J(
    duo(bash("""((n = n - 1))
((count++))
sum=$((a + b))
echo $((a * 2 + 1))"""), ul("`(( expression ))` – a **command** that computes: the C operators, `( )`, variables **without** `$`",
                               "`=`, `+=`, `-=`, `++`, `--` change a variable",
                               "`$(( expression ))` – like `$( command )`, but the shell computes and puts the **result** in its place, as text",
                               "anywhere in a command line, also inside `\"...\"`")),
    note("⚠️ Integers only!", "`$((7 / 2))` is `3`: no `3.5`, no `0.5`. `(( ))` as a command, `++` and `--` exist only in `bash` (and `zsh`).", "warn"),
    dbg("Arithmetic", [sc("math.sh", ARITH, "./math.sh", [
        S(2, run="a=2", vars={"a": "2"}), S(3, run="b=3", vars={"b": "3"}),
        S(4, compute="$((a + b))", info="computes `2 + 3` = `5`", note="Inside `$(( ))` the shell itself does math; the variables need no `$`."),
        S(4, run="sum=5", vars={"sum": "5"}, note="The result takes its place, as text."),
        S(5, run='echo "sum is 5"', status=0, out=["sum is 5"]),
        S(6, compute="$((a * b + 1))", info="computes `2 * 3 + 1` = `7`"),
        S(6, run="echo 7", status=0, out=["7"]),
        S(7, compute="$((a + b))", info="computes `2 + 3` = `5`", note="Anywhere in a command line, also inside `\"...\"`."),
        S(7, run='echo "2 + 3 = 5"', status=0, out=["2 + 3 = 5"], note="One parameter for `echo`: the text, with the variables and the result in it.")])],
        sub="No program is started: the shell computes inside `$(( ))` (blue)."),
))
page("compare", "`$( )` or `$(( ))`?", "One parenthesis runs a command, two compute", J(
    duo(f'<h3>command substitution</h3>{sh("$ echo $(a+b)" + chr(10) + "bash: a+b: command not found")}<p class="small">a copy of <code>bash</code> runs {chips(("a+b", "cmd"))}: it is not a program, it prints nothing; then the shell runs {chips(("echo", "cmd"))}</p>',
        f'<h3>arithmetic</h3>{sh("$ echo $((a+b))" + chr(10) + "5")}<p class="small">inside <code>(( ))</code>, <code>a</code> is the value of <code>a</code>; the shell computes <code>2 + 3</code>, no program starts; then it runs {chips(("echo", "cmd"), ("5", "new"))}</p>'),
    shell_first("`$(command)` – the **output** of a command; `$((expression))` – the **result** of a computation. With the program `expr`, they agree: `$(expr $a + $b)` ≡ `$((a+b))` → `5`."),
))
page("bc", "Decimals with `bc`", "The shell builds the text, `bc` computes", J(
    p("`bc` is a calculator **program**: it reads the expression from `stdin` and prints the result. The shell only builds the text of the expression."),
    sh("""$ echo "7 / 2" | bc  # scale=0: no decimals
3
$ echo "scale=2; 7 / 2" | bc  # 2 decimals
3.50
$ echo "7 / 2" | bc -l  # -l: scale=20 and the math functions
3.50000000000000000000
$ echo "sqrt(2)" | bc -l
1.41421356237309504880"""),
    p("`scale` is the number of decimals `bc` keeps after a division; it starts at `0`. Set it in the text you send (`scale=2;`), or start `bc -l`: `scale=20`, plus `s()`, `c()`, `a()`, `l()`, `e()` (sine, cosine, arctangent, logarithm, exponential)."),
    dbg("Decimals with bc", [sc("total.sh", BC, "./total.sh", [
        S(2, run="price=3.5", vars={"price": "3.5"}, note="For the shell, `3.5` is just text."),
        S(3, run="count=2", vars={"count": "2"}),
        S(4, part=['echo "$price * $count"', "bc"], who="copy", run='echo "3.5 * 2" | bc', status=0, info="prints `7.0`", note="`echo` and `bc` run **at the same time**: `echo` writes `3.5 * 2` in the pipe, `bc` reads it, computes and prints the result."),
        S(4, run="total=7.0", vars={"total": "7.0"}, note="The output of `bc` takes the place of `$(...)`, as text."),
        S(5, run='echo "total: 7.0"', status=0, out=["total: 7.0"]),
        S(6, part=['echo "$total / 1"', "bc"], who="copy", run='echo "7.0 / 1" | bc', status=0, info="prints `7`", note="Back to an integer: by default, `bc` divides with **no decimals**."),
        S(6, run="whole=7", vars={"whole": "7"}),
        S(7, compute="$((whole * 10))", info="computes `7 * 10` = `70`", note="An integer again: `$(( ))` can use it."),
        S(7, run='echo "times 10: 70"', status=0, out=["times 10: 70"])])]),
    quiz("What does `echo $((10 / 4))` print?", ["`2.5`", "`2`", "`3`", "an error"], 1, "Integer division: the decimals are cut, `2`. With `bc`: `echo \"scale=2; 10/4\" | bc` prints `2.50`."),
))
page("ops", "The operators of `(( ))`", "The C operators, on integers", J(
    table(["Operators", "Meaning", "Example"], [
        ("`+ - * /`", "add, subtract, multiply, divide", "`$((7 / 2))` → `3`"), ("`%` `**`", "remainder, power (bash)", "`$((2 ** 10))` → `1024`"),
        ("`< <= > >= == !=`", "compare: `1` true, `0` false", "`$((3 > 2))` → `1`"), ("`&& || !`", "and, or, not", "`$((1 && 0))` → `0`"),
        ("`& | ^ ~ << >>`", "bits", "`$((1 << 4))` → `16`"), ("`= += -= ++ --`", "change a variable (bash)", "`((x += 2))`"),
        ("`c ? a : b`", "`a` if `c` is true, else `b`", "`$((5 > 3 ? 10 : 20))` → `10`"), ("`( )`", "group", "`$(( (2 + 3) * 4 ))` → `20`")], "k"),
    w("calc"),
))
page("practice", "Cheat sheet and practice", "Arithmetic", J(
    table(["Write", "Means"], [
        ("`$a+$b`", "just text: `2+3`"), ("`$(expr $a + $b)`", "the program `expr` computes; `\\*` for multiply"),
        ("`$((a + b))`", "the shell computes, the result as text"), ("`((n++))`, `((x += 2))`", "a command that changes a variable"),
        ("`$((7 / 2))`", "`3`: integers only"), ("`$(echo \"3.5 * 2\" | bc)`", "decimals: the program `bc`"), ("`echo \"scale=2; 7 / 2\" | bc`, `bc -l`", "decimals after a division: `3.50`")], "k"),
    lab("arith", 'a=7\nb=2\necho "$a + $b = $((a + b))"', "./math.sh"),
))

# ================================================================ 07 if, test, [
KIWI = """#!/bin/bash
if grep -q kiwi fruits.txt; then
    echo "we have kiwi"
else
    echo "no kiwi"
fi"""
COMPARE = """#!/bin/bash
a=7
b=3
if $a > $b; then
    echo "a is bigger"
else
    echo "a is not bigger"
fi"""
TEST = """#!/bin/bash
a=2
b=3
if test $a -lt $b; then
    echo "a is smaller"
fi"""
BRACKET_OK = """#!/bin/bash
a=2
b=3
if [ $a -lt $b ]; then
    echo "a is smaller"
else
    echo "a is not smaller"
fi"""
BRACKET = """#!/bin/bash
a=2
b=3
if [$a -lt $b]; then
    echo "a is smaller"
else
    echo "a is not smaller"
fi"""
KIND = """#!/bin/bash
name=fruits.txt
if [ -d "$name" ]; then
    echo "a directory"
elif [ -f "$name" ]; then
    echo "a file"
else
    echo "not found"
fi
echo "done\""""
page = chapter("if", "Conditions: `if`, `test` and `[`", "Run a command, look at its exit code", 24)
page("syntax", "`if` runs a command", "The condition is a command", J(
    p("The condition of `if` is not an expression, it is a **command**: `if` runs it and looks at its exit code."),
    duo(bash("""if command; then
    commands
elif other_command; then
    commands
else
    commands
fi"""), ul("`if` runs the command and looks at its **exit code**", "`then` – the commands that run if it ended with `0` (*true*)",
           "`elif` – another command to try, optional, as many as needed", "`else` – when no command ended with `0`, optional", "`fi` – `if` backwards, the end")),
    '<div class="b8zero"><b>⚠️ In the shell, <code>0</code> is <i>true</i>!</b><div><span class="db-ec ok">0</span> <i>true</i> – success, <code>then</code> runs</div><div><span class="db-ec bad">1</span> <i>false</i> – a warning or an error (<code>1</code> … <code>255</code>)</div><p class="small">the opposite of C, where <code>0</code> is false</p></div>',
    oneliner("A `;` takes the place of the newline before `then`, `elif`, `else` and `fi`.", "if command; then commands; else commands; fi", "if grep -q kiwi fruits.txt; then echo \"we have kiwi\"; fi", "we have kiwi"),
))
page("kiwi", "The exit code chooses the branch", "🐞 `if`", J(
    dbg("if runs a command", [
        sc("kiwi.sh", KIWI, "./kiwi.sh", [
            S(2, part="grep -q kiwi fruits.txt", run="grep -q kiwi fruits.txt", match="kiwi", status=0, note="`grep -q` prints nothing: `if` only looks at its exit code."),
            S(3, run='echo "we have kiwi"', status=0, out=["we have kiwi"], note="`0` – found: the `then` branch runs.")], files={"fruits.txt": FRUITS}),
        sc("compare.sh – wrong", COMPARE, "./compare.sh", [
            S(2, run="a=7", vars={"a": "7"}), S(3, run="b=3", vars={"b": "3"}, note="In C, `a > b` would be true: we expect `then`."),
            S(4, part="$a > $b", run="7 > 3", status=127, out=["!./compare.sh: line 4: 7: command not found"], note="❌ The condition is a **command line**: the command `7`, its output redirected (`>`) to a **new file** named `3`."),
            S(7, run='echo "a is not bigger"', status=0, out=["a is not bigger"], note="❌ **Wrong**: `7` is bigger, but the condition failed – there is no program `7`. Comparing came later: with commands (`test`, `[`) or with `(( ))`.")])]),
))
page("test", "`test` and `[`: commands that compare", "`-lt`, `-eq`, `-f` …", J(
    p("`test` checks a condition and only sets its exit code. `<` and `>` are redirects, so the comparisons are **options**."),
    duo(table(["Test", "True (`0`) if"], [
        ("`N -eq M`, `-ne`", "the numbers are **eq**ual, **n**ot **e**qual"), ("`N -lt M`, `-le`", "**l**ess **t**han, **l**ess or **e**qual"),
        ("`N -gt M`, `-ge`", "**g**reater **t**han, **g**reater or **e**qual"), ("`S = T`, `S != T`", "the texts are equal, different"),
        ("`-z S`, `-n S`", "the text is empty, not empty"), ("`-e F`, `-f F`, `-d F`", "`F` exists, is a file, is a directory"),
        ("`! E`, `E -a E`, `E -o E`", "not, and, or")], "k"),
        sh("""$ a=2; b=3
$ test $a -lt $b; echo $?
0
$ test $a -gt $b; echo $?
1
$ type -a [
[ is a shell builtin
[ is /usr/bin/[
$ [ $a -lt $b ]; echo $?
0""") + f'<p class="small">the shell sees {chips(("[", "cmd"), "2", "-lt", "3", ("]", "new"))}: <code>[</code> is <code>test</code>, and <code>]</code> is just its last parameter</p>'),
    dbg("Comparing with test and [", [
        sc("test $a -lt $b", TEST, "./smaller.sh", [
            S(2, run="a=2", vars={"a": "2"}), S(3, run="b=3", vars={"b": "3"}),
            S(4, part="test $a -lt $b", run="test 2 -lt 3", status=0, note="The command `test`, with three parameters: `2 < 3` is true, it ends with `0`."),
            S(5, run='echo "a is smaller"', status=0, out=["a is smaller"])]),
        sc("[ $a -lt $b ]", BRACKET_OK, "./smaller.sh", [
            S(2, run="a=2", vars={"a": "2"}), S(3, run="b=3", vars={"b": "3"}),
            S(4, part="[ $a -lt $b ]", run="[ 2 -lt 3 ]", status=0, note="The same test, written with `[`: the command `[` gets four parameters, `2` `-lt` `3` `]`. The `]` is just the last one; `2 < 3` is true, it ends with `0`."),
            S(5, run='echo "a is smaller"', status=0, out=["a is smaller"], note="`0`: the `then` branch runs. Spaces around `[` and `]` are required: they are separate words.")]),
        sc("[$a -lt $b] – wrong", BRACKET, "./smaller.sh", [
            S(2, run="a=2", vars={"a": "2"}), S(3, run="b=3", vars={"b": "3"}),
            S(4, part="[$a -lt $b]", run="[2 -lt 3]", status=127, out=["!./smaller.sh: line 4: [2: command not found"], note="❌ The first word is `[2`: there is no such command. With spaces, the words are `[` `2` `-lt` `3` `]`."),
            S(7, run='echo "a is not smaller"', status=0, out=["a is not smaller"], note="❌ The condition failed, so the `else` branch runs: the answer is **wrong**.")])]),
))
page("elif", "`if`, `elif`, `else`", "The first command that ends with `0` wins", J(
    dbg("if, elif, else", [sc("kind.sh", KIND, "./kind.sh", [
        S(2, run="name=fruits.txt", vars={"name": "fruits.txt"}),
        S(3, part='[ -d "$name" ]', run="[ -d fruits.txt ]", status=1, note="The condition is the **command** `[`: not a directory, it ends with `1`, *false*."),
        S(5, part='[ -f "$name" ]', run="[ -f fruits.txt ]", status=0, note="So `elif` runs its command: a file, `0`, *true*."),
        S(6, run='echo "a file"', status=0, out=["a file"], note="Only this branch runs, `else` is skipped."),
        S(10, run='echo "done"', status=0, out=["done"], note="After `fi`, the script goes on.")])]),
))
page("pitfalls", "The pitfalls of `[`", "`[` only sees words", J(
    pit("What does [ get?", [
        ("[$a -lt $b]", [["[$a"], " -lt ", ["$b]"]], [["[2", "cmd"], ["-lt", ""], ["3]", ""]], "$ [$a -lt $b]; echo $?\n!bash: [2: command not found\n127", False, "**No space** after `[`: the command is named `[2`."),
        ("[ $a -lt $b", ["[ $a -lt $b", ["  "]], [["[", "cmd"], ["2", ""], ["-lt", ""], ["3", ""]], "$ [ $a -lt $b; echo $?\n!bash: [: missing `]'\n2", False, "**No** `]`: `[` checks that its last parameter is `]`."),
        ("[ $a-lt$b ]", ["[ ", ["$a-lt$b"], " ]"], [["[", "cmd"], ["2-lt3", "new"], ["]", ""]], "$ [ $a-lt$b ]; echo $?\n0", False, "**No spaces** around `-lt`: one word, *\"is the text `2-lt3` not empty?\"* – always true."),
        ('[ $x = "abc" ]', ["[ ", ["$x"], ' = "abc" ]'], [["[", "cmd"], ["=", ""], ["abc", ""], ["]", ""]], '$ [ $x = "abc" ]; echo $?\n!bash: [: =: unary operator expected\n2', False, "An **empty variable**, without quotes, disappears: `[` gets 3 parameters."),
        ('[ "$x" = "abc" ]', ["[ ", ['"$x"'], ' = "abc" ]'], [["[", "cmd"], ["", "new"], ["=", ""], ["abc", ""], ["]", ""]], '$ [ "$x" = "abc" ]; echo $?\n1', True, "With quotes, an empty variable is still a word.")],
        sub="`a=2`, `b=3` and `x=\"\"` (empty).", try_=dict(v='[ $x = "abc" ]', vars={"a": "2", "b": "3", "x": ""}, note="`a=2`, `b=3`, `x=\"\"` are set.")),
    shell_first("The shell splits the line into words **before** `[` starts; `[` cannot know what you meant: spaces everywhere, and quote the variables, `\"$x\"`."),
))
page("modern", "`[[ ]]` and `(( ))`", "Real syntax for conditions, added later", J(
    sh("""$ if [[ $a -lt $b ]]; then echo "smaller"; fi
smaller
$ if (( a < b )); then echo "smaller"; fi
smaller"""),
    ul("`[[ ... ]]` – like `[`, but a *keyword* of `bash`: no word splitting, `$x` may be empty",
       "`(( ... ))` – the C-like math of `$(( ))`, as a condition: not `0` is *true*"),
    shell_first("Finally a C-like condition: the shell does not split `(( ))` into words, so `<` is not a redirect there. Both exist only in `bash` (and `zsh`)."),
    quiz("Which line prints `yes` when `a=7` and `b=10`?", ["`if $a < $b; then echo yes; fi`", "`if [ $a -lt $b ]; then echo yes; fi`", "`if [ $a < $b ]; then echo yes; fi`", "`if [$a -lt $b]; then echo yes; fi`"], 1,
         "Only B: `[` with four parameters and `]`. A runs the command `7` with `<` a redirect; C redirects too; D runs the command `[7`."),
))
page("practice", "Cheat sheet and practice", "Conditions", J(
    table(["Write", "Means"], [
        ("`if cmd; then ...; fi`", "`then` runs if `cmd` ends with `0`"), ("`elif cmd; then`, `else`", "the next try, the rest"),
        ("`[ \"$a\" -lt \"$b\" ]`", "the program `[`: spaces everywhere, `]` last"), ("`[ -f f ]`, `[ -d d ]`, `[ -z \"$x\" ]`", "a file, a folder, an empty text"),
        ("`[[ $a -lt $b ]]`", "bash: no splitting"), ("`(( a < b ))`", "bash: C-like, on integers")], "k"),
    lab("cond", KIWI.replace("#!/bin/bash\n", ""), "./kiwi.sh"),
))

# ================================================================ 08 case
CASE = """#!/bin/bash
fruit=$(head -n 1 fruits.txt)
case $fruit in
    apple|cherry)
        echo "red"
        ;;
    banana)
        echo "yellow"
        ;;
    *)
        echo "I don't know $fruit"
        ;;
esac"""
ORDER = """#!/bin/bash
fruit=apple
case $fruit in
    a*) echo "starts with a" ;;
    apple) echo "apple" ;;
esac
echo "done\""""
NOMATCH = """#!/bin/bash
fruit=kiwi
case $fruit in
    apple) echo "apple" ;;
    cherry) echo "cherry" ;;
esac
echo "exit code: $?\""""
page = chapter("case", "Conditions: `case`", "Compare a word with patterns", 14)
page("syntax", "`case`: the condition is a word", "`case` syntax", J(
    duo(bash("""case WORD in
    pattern1)
        commands
        ;;
    pattern2|pattern3)
        commands
        ;;
    *)
        commands
        ;;
esac"""), ul("`case` takes the **text** of `WORD` and compares it with every pattern, top to bottom",
             "`pattern)` – the commands that run if `WORD` matches it; `;;` – the end of the branch, jump after `esac`",
             "`|` – *or*: any of the patterns", "`*` matches anything: the *default* branch, always last, optional", "`esac` – `case` backwards, the end")),
    oneliner("No newline is needed: the branches end with `;;`.", "case WORD in pattern) commands ;; pattern) commands ;; esac", 'f=notes.txt; case $f in *.txt) echo "text" ;; *) echo "other" ;; esac', "text"),
))
page("debug", "`case` compares text", "🐞 `case`", J(
    dbg("case compares text", [
        sc("color.sh", CASE, "./color.sh", [
            S(2, part="head -n 1 fruits.txt", who="copy", run="head -n 1 fruits.txt", status=0, info="prints `banana`", read=[1]),
            S(2, run="fruit=banana", vars={"fruit": "banana"}),
            S(3, info="compares the text `banana` with the patterns, **no command runs**", note="No command runs for the condition: `case` only compares text."),
            S(4, expand="apple|cherry", info="`banana` does not match, try the next pattern"),
            S(7, expand="banana", info="`banana` matches"),
            S(8, run='echo "yellow"', status=0, out=["yellow"]),
            S(9, info="`;;` – jump after `esac`, `*)` is not tried"),
            S(13, info="the end of `case`, the script goes on after it")], files={"fruits.txt": FRUITS}),
        sc("a* comes first", ORDER, "./order.sh", [
            S(2, run="fruit=apple", vars={"fruit": "apple"}),
            S(3, info="compares the text `apple` with the patterns, **top to bottom**"),
            S(4, expand="a*", info="`apple` matches `a*`", note="`apple` starts with `a`: this is the first match."),
            S(4, part='echo "starts with a"', run='echo "starts with a"', status=0, out=["starts with a"]),
            S(7, run='echo "done"', status=0, out=["done"], note="❌ `;;` jumps after `esac`: the branch `apple)` is never tried, it is dead code. Put the **specific** patterns first, `a*` after them, `*` last.")]),
        sc("nothing matches", NOMATCH, "./nomatch.sh", [
            S(2, run="fruit=kiwi", vars={"fruit": "kiwi"}),
            S(3, info="compares the text `kiwi` with the patterns"),
            S(4, expand="apple", info="`kiwi` does not match"),
            S(5, expand="cherry", info="`kiwi` does not match"),
            S(6, info="no pattern matched, `case` ends with `0`", note="No branch runs – and this is **not** an error."),
            S(7, run='echo "exit code: 0"', status=0, out=["exit code: 0"], note="Add a `*)` branch, last, to catch everything else.")])]),
))
page("globs", "Patterns are globs", "The same patterns as `ls *.txt`, on text", J(
    p("The patterns of `case` are **globs**, like `ls *.txt`, but they match the **text** of the word: `case` never looks at the disk."),
    w("globs"),
    bad("Globs are not regular expressions", "In a glob, `.` is a dot and `*` is any text; in a regex (`grep`, lecture 6), `.` is any character and `*` repeats it. `n.*` as a glob does not match `notes.txt` – no dot after `n`; as a regex it does.",
        "in `case`, write `n*` for \"starts with `n`\"."),
))
page("practice", "Cheat sheet and practice", "`case`", J(
    table(["Pattern", "Matches"], [
        ("`apple`", "exactly `apple`"), ("`a*`", "`a`, then any text"), ("`*.txt`", "any text ending in `.txt`"), ("`???`", "exactly three characters"),
        ("`[yY]*`", "`y` or `Y`, then any text"), ("`apple|kiwi`", "either (only in `case`)"), ("`*`", "anything: the default, last")], "k"),
    lab("case", 'answer="Yes"\ncase $answer in\n    apple|cherry) echo "red" ;;\n    banana) echo "yellow" ;;\nesac', "./answer.sh"),
))

# ================================================================ 09 while
WHILE = """#!/bin/bash
n=2
while [ $n -gt 0 ]; do
    echo "$n..."
    n=$((n - 1))
done
echo "go!\""""
UNTIL = """#!/bin/bash
n=0
until [ $n -eq 2 ]; do
    n=$((n + 1))
    echo "$n"
done
echo "done\""""
READ = """#!/bin/bash
while read fruit; do
    echo "buy $fruit"
done < shopping.txt
echo "done\""""
CSV = """#!/bin/bash
while IFS=, read user name; do
    echo "$user: $name"
done < people.csv
echo "done\""""
page = chapter("while", "Loops: `while`", "Run a command again and again, while it succeeds", 16)
page("syntax", "`while` and `until`", "Repeat while a command ends with `0`", J(
    duo(bash("""while command; do
    commands
done
until command; do
    commands
done"""), ul("`while` runs the command **before every round** and looks at its exit code", "`do` – the *body*, runs while the command ends with `0`",
             "`done` – jump back to the command", "`until` – the opposite: repeat while the command does **not** end with `0`",
             "inside the body: `break` leaves the loop, `continue` goes to the next round")),
    oneliner("A `;` takes the place of the newline before `do` and before `done`.", "while command; do commands; done", "n=3; while [ $n -gt 0 ]; do echo $n; n=$((n - 1)); done", "3\n2\n1"),
))
page("debug", "Again and again", "🐞 `while`, `until`", J(
    dbg("while and until", [
        sc("while", WHILE, "./countdown.sh", [
            S(2, run="n=2", vars={"n": "2"}),
            S(3, part="[ $n -gt 0 ]", run="[ 2 -gt 0 ]", status=0, note="`0`, *true*: the body runs."),
            S(4, run='echo "2..."', status=0, out=["2..."]),
            S(5, run="n=1", vars={"n": "1"}, note="`$((n - 1))` is computed, `n` is now the text `1`."),
            S(3, part="[ $n -gt 0 ]", run="[ 1 -gt 0 ]", status=0, note="`done` jumps back: the condition runs **again**, with the new value."),
            S(4, run='echo "1..."', status=0, out=["1..."]),
            S(5, run="n=0", vars={"n": "0"}),
            S(3, part="[ $n -gt 0 ]", run="[ 0 -gt 0 ]", status=1, note="`1`, *false*: the loop ends."),
            S(7, run='echo "go!"', status=0, out=["go!"], note="The script goes on after `done`.")]),
        sc("until", UNTIL, "./count.sh", [
            S(2, run="n=0", vars={"n": "0"}),
            S(3, part="[ $n -eq 2 ]", run="[ 0 -eq 2 ]", status=1, note="Not `0`, *false*: `until` runs the body."),
            S(4, run="n=1", vars={"n": "1"}), S(5, run="echo 1", status=0, out=["1"]),
            S(3, part="[ $n -eq 2 ]", run="[ 1 -eq 2 ]", status=1, note="`done` jumps back: still not `0`, the body runs again."),
            S(4, run="n=2", vars={"n": "2"}), S(5, run="echo 2", status=0, out=["2"]),
            S(3, part="[ $n -eq 2 ]", run="[ 2 -eq 2 ]", status=0, note="`0`, *true*: `until` stops – the opposite of `while`."),
            S(7, run="echo done", status=0, out=["done"])])]),
))
page("read", "`while read`: a file, line by line", "One line in every round", J(
    p("`< file` after `done` is the `stdin` of the **whole loop**: every `read` takes the next line; at the end of the file `read` ends with `1` and the loop stops."),
    dbg("while read", [
        sc("shop.sh", READ, "./shop.sh", [
            S(2, part="read fruit", also=[[4, "< shopping.txt"]], run="read fruit < shopping.txt", match="apple", status=0, vars={"fruit": "apple"}, info="reads `apple`",
              note="`< shopping.txt` after `done` is the `stdin` of the **whole loop**: `read` takes one line from it, into `fruit`."),
            S(3, run='echo "buy apple"', status=0, out=["buy apple"]),
            S(2, part="read fruit", also=[[4, "< shopping.txt"]], run="read fruit < shopping.txt", match="kiwi", status=0, vars={"fruit": "kiwi"}, info="reads `kiwi`", note="The next line of the file."),
            S(3, run='echo "buy kiwi"', status=0, out=["buy kiwi"]),
            S(2, part="read fruit", also=[[4, "< shopping.txt"]], run="read fruit < shopping.txt", status=1, vars={"fruit": ""}, info="end of the file", note="No more lines: `read` ends with `1`, the loop ends."),
            S(5, run='echo "done"', status=0, out=["done"])], files={"shopping.txt": ["apple", "kiwi"]}),
        sc("IFS=, read", CSV, "./people.sh", [
            S(2, part="IFS=, read user name", also=[[4, "< people.csv"]], run="IFS=, read user name < people.csv", match="alice,", status=0, vars={"user": "alice", "name": "Alice Smith"}, info="reads `alice,Alice Smith`",
              note="Cut only at `,`: the space in `Alice Smith` stays, `name` takes it all."),
            S(3, run='echo "alice: Alice Smith"', status=0, out=["alice: Alice Smith"]),
            S(2, part="IFS=, read user name", also=[[4, "< people.csv"]], run="IFS=, read user name < people.csv", match="bob,", status=0, vars={"user": "bob", "name": "Bob Jones"}, info="reads `bob,Bob Jones`", note="The next line of the file."),
            S(3, run='echo "bob: Bob Jones"', status=0, out=["bob: Bob Jones"]),
            S(2, part="IFS=, read user name", also=[[4, "< people.csv"]], run="IFS=, read user name < people.csv", status=1, vars={"user": "", "name": ""}, info="end of the file", note="No more lines: `read` ends with `1`, the loop ends."),
            S(5, run='echo "done"', status=0, out=["done"])], files={"people.csv": ["alice,Alice Smith", "bob,Bob Jones"]})]),
))
page("pitfalls", "The pitfalls of `while`", "The loop only runs a command", J(
    pit("What goes wrong?", [
        ("while $n > 0", ["n=2; while ", ["$n > 0"], '; do echo "$n..."; done'], [["2", "cmd"], [">", "redir"], ["0", "redir"]], 'n=2; while $n > 0; do echo "$n..."; done\n!bash: 2: command not found', False,
         "`$n > 0` is a command line: the command `2`, its output redirected to a **new file** named `0`."),
        ("forever", ["n=2; while [ $n -gt 0 ]; do ", ['echo "$n..."'], "; done"], [["[", "cmd"], ["2", ""], ["-gt", ""], ["0", ""], ["]", ""]], 'n=2; while [ $n -gt 0 ]; do echo "$n..."; done\n2...\n2...\n2...\n^C', False,
         "The body never changes `n`: the condition is always true, the loop runs **forever**, until [[Ctrl]] + [[C]]. Change the variable in the body: `n=$((n - 1))`."),
        ("cat | while", ["c=0; ", ["cat fruits.txt |"], " while read f; do c=$((c+1)); done; echo $c"], [["cat", "cmd"], ["fruits.txt", ""], ["|", "redir"], ["while read f; do c=$((c+1)); done", "new"]], "$ c=0; cat fruits.txt | while read f; do c=$((c+1)); done; echo $c\n0", False,
         "After a `|`, the loop (orange) runs in a **copy** of the shell: `c` changes in the copy, the script still sees `0`.", dict(wh="the pipeline: two parts, each in its own process")),
        ("done < file", ["c=0; while read f; do c=$((c+1)); ", ["done < fruits.txt"], "; echo $c"], [["while read f; do c=$((c+1)); done", "new"], ["<", "redir"], ["fruits.txt", "redir"]], "$ c=0; while read f; do c=$((c+1)); done < fruits.txt; echo $c\n7", True,
         "With `< fruits.txt` after `done`, the loop (orange) runs in the shell itself, with the file as its `stdin`: `c` is `7`.", dict(wh="one command: the loop, its stdin from the file"))], sub="Pick a line: what goes wrong, and the fix."),
))
page("practice", "Cheat sheet and practice", "`while`", J(
    table(["Write", "Means"], [
        ("`while cmd; do ...; done`", "repeat while `cmd` ends with `0`"), ("`until cmd; do ...; done`", "repeat while it does not"),
        ("`while read l; do ...; done < f`", "the lines of a file, in the shell itself"), ("`while IFS=, read a b`", "the fields of a CSV"),
        ("`break`, `continue`", "leave the loop, the next round")], "k"),
    lab("while", WHILE.replace("#!/bin/bash\n", ""), "./countdown.sh", files=["fruits.txt", "shopping.txt", "notes.txt"]),
))

# ================================================================ 10 for
FOR = """#!/bin/bash
for fruit in apple kiwi cherry; do
    echo "I like $fruit"
done
echo "done\""""
GLOB = """#!/bin/bash
for f in *.txt; do
    echo "file: $f"
done"""
SEQ = """#!/bin/bash
n=3
for i in $(seq 1 $n); do
    echo "round $i"
done
echo "done\""""
IFSFOR = """#!/bin/bash
line="apple:kiwi:cherry"
IFS=:
for f in $line; do
    echo "[$f]"
done
unset IFS"""
page = chapter("for", "Loops: `for`", "Once for every word", 20)
page("syntax", "`for`: once for every word", "`for` syntax", J(
    duo(bash("""for NAME in word1 word2 word3; do
    commands
done
for f in *.txt; do ...; done
for w in $(cat fruits.txt); do ...; done
for i in {1..5}; do ...; done"""), ul("the variable `NAME` takes every word after `in`, one by one", "`do` – the body, runs once for every word, with `$NAME` the word",
                                      "`done` – go back and take the next word", "the words can come from a **glob**, from the **output** of a command, or from *brace expansion* (bash)")),
    oneliner("A `;` takes the place of the newline before `do` and before `done`.", "for NAME in word1 word2; do commands; done", 'for f in apple kiwi; do echo "I like $f"; done', "I like apple\nI like kiwi"),
))
page("debug", "Once for every word", "🐞 `for`", J(
    dbg("for", [
        sc("a list", FOR, "./fruits.sh", [
            S(2, expand="apple", run="fruit=apple", vars={"fruit": "apple"}, note="`fruit` takes the first word."),
            S(3, run='echo "I like apple"', status=0, out=["I like apple"]),
            S(2, expand="kiwi", run="fruit=kiwi", vars={"fruit": "kiwi"}, note="`done` jumps back, `fruit` takes the next word."),
            S(3, run='echo "I like kiwi"', status=0, out=["I like kiwi"]),
            S(2, expand="cherry", run="fruit=cherry", vars={"fruit": "cherry"}),
            S(3, run='echo "I like cherry"', status=0, out=["I like cherry"]),
            S(5, run='echo "done"', status=0, out=["done"], note="No more words, the loop ends.")]),
        sc("a glob", GLOB, "./files.sh", [
            S(2, expand="*.txt", run="for f in fruits.txt notes.txt words.txt; do", info="the loop bash runs", note="Before the loop starts, the shell replaces the glob `*.txt` with the file names: the loop bash really runs is `for f in fruits.txt notes.txt words.txt`."),
            S(2, run="f=fruits.txt", vars={"f": "fruits.txt"}), S(3, run='echo "file: fruits.txt"', status=0, out=["file: fruits.txt"]),
            S(2, run="f=notes.txt", vars={"f": "notes.txt"}), S(3, run='echo "file: notes.txt"', status=0, out=["file: notes.txt"]),
            S(2, run="f=words.txt", vars={"f": "words.txt"}), S(3, run='echo "file: words.txt"', status=0, out=["file: words.txt"], note="`for` only sees words: it does not know they are files.")])]),
))
page("seq", "Counting with a step", "`seq`, `{1..10..3}`, `for (( ))`", J(
    sh("""$ for i in $(seq 1 3 10); do echo -n "$i "; done; echo
1 4 7 10
$ n=5; for i in $(seq 1 $n); do echo -n "$i "; done; echo
1 2 3 4 5"""),
    ul("`seq first step last` – a **program** that prints the numbers; it works with variables: `seq` runs **after** the shell replaced them",
       "`{1..10..3}` (bash) – the shell writes them, but **not** with variables: `{1..$n}` stays as it is",
       "`for ((i = 1; i <= 10; i += 3)); do ...; done` (bash) – a C-like `for`"),
    dbg("Counting with seq", [sc("rounds.sh", SEQ, "./rounds.sh", [
        S(2, run="n=3", vars={"n": "3"}),
        S(3, part="seq 1 $n", who="copy", run="seq 1 3", status=0, info="prints `1`, `2`, `3`, one per line", note="First, a copy of `bash` runs `seq`; its output takes the place of `$(...)`."),
        S(3, part="$(seq 1 $n)", run="for i in 1 2 3; do", info="the loop bash runs", note="The output of `seq`, `1`, `2`, `3` one per line, takes the place of `$(...)`; unquoted, the newlines separate words. The loop bash really runs is `for i in 1 2 3`."),
        S(3, run="i=1", vars={"i": "1"}, expand="i ", note="`i` takes the first word, `1`."),
        S(4, run='echo "round 1"', status=0, out=["round 1"]),
        S(3, run="i=2", vars={"i": "2"}, expand="i ", note="`done` jumps back, `i` takes the next word – `seq` does not run again."),
        S(4, run='echo "round 2"', status=0, out=["round 2"]),
        S(3, run="i=3", vars={"i": "3"}, expand="i "),
        S(4, run='echo "round 3"', status=0, out=["round 3"]),
        S(6, run='echo "done"', status=0, out=["done"], note="No more words, the loop ends.")])]),
))
page("ifs", "`IFS` and `for`", "Choose where the list is cut", J(
    p("The list of `for` is cut at the characters of `IFS`, like any unquoted text. `for` is a *keyword*, not a command: `IFS=: for ...` is a syntax error. Set `IFS` **before** the loop and `unset` it after."),
    sh("""$ line="apple:kiwi:cherry"
$ for f in $line; do echo "[$f]"; done
[apple:kiwi:cherry]
$ IFS=: for f in $line; do echo "[$f]"; done
bash: syntax error near unexpected token `do'"""),
    dbg("for with IFS", [sc("fruits.sh", IFSFOR, "./fruits.sh", [
        S(1, vars={"IFS": "space tab newline"}, tags={"IFS": "default"}, note="The script starts: `IFS` has the **default** value."),
        S(2, run='line="apple:kiwi:cherry"', vars={"line": "apple:kiwi:cherry"}, note="No space in the value: with the default `IFS`, it would be **one** word."),
        S(3, run="IFS=:", vars={"IFS": ":"}, tags={"IFS": None}, note="Set `IFS` **before** the loop."),
        S(4, part="$line", run="for f in apple kiwi cherry; do", info="the loop bash runs", note="Before the loop starts, the shell replaces `$line` and cuts the value at `:`: the loop bash really runs is `for f in apple kiwi cherry`."),
        S(4, expand="f ", run="f=apple", vars={"f": "apple"}), S(5, run='echo "[apple]"', status=0, out=["[apple]"]),
        S(4, expand="f ", run="f=kiwi", vars={"f": "kiwi"}, note="`done` jumps back, `f` takes the next word."), S(5, run='echo "[kiwi]"', status=0, out=["[kiwi]"]),
        S(4, expand="f ", run="f=cherry", vars={"f": "cherry"}), S(5, run='echo "[cherry]"', status=0, out=["[cherry]"]),
        S(7, run="unset IFS", vars={"IFS": "space tab newline"}, tags={"IFS": "not set, default"}, note="No more words, the loop ends; `unset IFS` – back to the default for the rest of the script.")])]),
))
page("lines", "`for` goes over words, not lines", "`$(...)`, `\"$(...)\"` or `while read`", J(
    pit("How many rounds?", [
        ("$(cat)", ["for n in ", ["$(cat people.txt)"], '; do echo "[$n]"; done'], [["Alice", "new"], ["Smith", "new"], ["Bob", "new"], ["Jones", "new"]],
         '$ for n in $(cat people.txt); do echo "[$n]"; done\n[Alice]\n[Smith]\n[Bob]\n[Jones]', False, "Unquoted, the output is cut at **every** space and newline: 4 words, 4 rounds."),
        ('"$(cat)"', ["for n in ", ['"$(cat people.txt)"'], '; do echo "[$n]"; done'], [["Alice Smith\nBob Jones", "new"]],
         '$ for n in "$(cat people.txt)"; do echo "[$n]"; done\n[Alice Smith\nBob Jones]', False, "Quoted, the whole output is **one** word, the newline inside it: 1 round."),
        ("IFS=$'\\n'", [["IFS=$'\\n'"], '; for n in $(cat people.txt); do echo "[$n]"; done'], [["Alice Smith", "new"], ["Bob Jones", "new"]],
         "$ IFS=$'\\n'\n$ for n in $(cat people.txt); do echo \"[$n]\"; done\n[Alice Smith]\n[Bob Jones]\n$ unset IFS", True, "`$'\\n'` (bash) is a newline: now only newlines cut, 2 words – but `IFS` changed for the whole shell."),
        ("while read", ["", ["while read n"], '; do echo "[$n]"; done < people.txt'], [["Alice Smith", "new"], ["Bob Jones", "new"]],
         '$ while read n; do echo "[$n]"; done < people.txt\n[Alice Smith]\n[Bob Jones]', True, "`read` takes a **line**: `for` goes over words; to go over lines, use `while read`.", dict(wh="the lines `read` takes, one per round"))],
        sub="`people.txt` has two lines. The chips are the words of the list: one round for every chip.", wh="the words of the list: one round each", files={"people.txt": ["Alice Smith", "Bob Jones"]}),
))
page("practice", "Cheat sheet and practice", "`for`", J(
    table(["Write", "The words of the list"], [
        ("`for f in a b c`", "the words you wrote"), ("`for f in *.txt`", "the file names"), ("`for w in $(cmd)`", "the output, cut at `IFS`"),
        ("`for i in $(seq 1 3 10)`", "`1 4 7 10`"), ("`for i in {1..5}`", "`1 2 3 4 5` (bash, no variables)"), ("`for ((i = 0; i < 3; i++))`", "C-like (bash)")], "k"),
    lab("for", FOR.replace("#!/bin/bash\n", ""), "./fruits.sh", files=["fruits.txt", "notes.txt", "words.txt", "people.txt"]),
))

# ================================================================ 11 functions
FUNC = """#!/bin/bash
greet() {
    if [ $# -eq 0 ]; then
        return 1
    fi
    echo "Hello, $1!"
}
greet alice && echo "ok"
greet || echo "nobody to greet\""""
LOCAL = """#!/bin/bash
update() {
    local name="bob"
    count=1
}
name="alice"
count=0
update
echo "$name $count\""""
ADD = """#!/bin/bash
add() {
    echo $(( $1 + $2 ))
}
full_name() {
    echo "$2, $1"
}
sum=$(add 2 3)
name=$(full_name Alice Smith)
echo "$name: $sum\""""
DIVIDE = """#!/bin/bash
divide() {
    if [ $2 -eq 0 ]; then
        return 1
    fi
    echo $(( $1 / $2 ))
}
q=$(divide 7 2)
echo "7 / 2 = $q, exit code $?"
q=$(divide 7 0)
echo "7 / 0 = $q, exit code $?\""""
page = chapter("func", "Functions", "Commands you define yourself", 20)
page("syntax", "A function is a new command", "Function syntax", J(
    duo(bash("""greet() {
    local who="$1"
    echo "Hello, $who!"
    return 0
}
greet alice""") + sh("""$ greet alice
Hello, alice!
$ greet
Hello, !"""), ul("`name() {` – the start, the `()` are **always empty**", "the **parameters**, the words after the name in the call: `$1` is the first one, `$2` the second, ...; `$#` is how many there are", "`local` – a variable only for the function",
                 "`return N` – leave the function with the **exit code** `N`, like `exit` for a script", "`}` – the end: the function is now defined",
                 "call it **like any command**: the name, then the words; a missing parameter is just empty")),
    shell_first("A function is called exactly like a program: the command name, then the words – so it gets its parameters the same way a script does. Define it **before** calling it."),
))
page("debug", "Parameters, exit code, `local`", "🐞 Functions", J(
    dbg("Functions", [
        sc("greet.sh", FUNC, "./greet.sh", [
            S(2, run="greet() { ... }", note="Lines 2 – 7 only **define** the command `greet`: nothing runs."),
            S(8, part="greet alice", run="greet alice", vars={"$1": "alice", "$#": "1"}, note="Called like any command: the words after the name are its parameters, `$1` = `alice` (the first word) and `$#` = `1` (how many). See them in the variables."),
            S(3, part="[ $# -eq 0 ]", also=[[8, "alice"]], run="[ 1 -eq 0 ]", status=1, note="`[ $# -eq 0 ]` asks *\"did the call have no parameters?\"*: `$#` is `1` (one word after `greet`), so the test is false, `1`, and `return 1` is skipped."),
            S(6, also=[[8, "alice"]], run='echo "Hello, alice!"', status=0, out=["Hello, alice!"], note="No `return`: `greet` ends with the exit code of its last command, `0`."),
            S(8, part='echo "ok"', run='echo "ok"', status=0, unset=["$1", "$#"], out=["ok"], note="`greet` ended with `0`: `&&` runs the next command."),
            S(9, part="greet", run="greet", vars={"$#": "0"}, note="No words after the name: `$#` = `0`, and there is no `$1`."),
            S(3, part="[ $# -eq 0 ]", run="[ 0 -eq 0 ]", status=0),
            S(4, run="return 1", status=1, note="`return 1`: leave the function with the exit code `1`, an error."),
            S(9, part='echo "nobody to greet"', run='echo "nobody to greet"', status=0, unset=["$#"], out=["nobody to greet"], note="`greet` ended with `1`: `||` runs the next command – a function answers like any command.")]),
        sc("local", LOCAL, "./update.sh", [
            S(2, run="update() { ... }", note="Lines 2 – 5 only define the function."),
            S(6, run="name=alice", vars={"name": "alice"}), S(7, run="count=0", vars={"count": "0"}),
            S(8, run="update"),
            S(3, run="local name=bob", vars={"name (local)": "bob"}, note="`local`: a **new** `name`, inside the function – the one of the script is not touched."),
            S(4, run="count=1", vars={"count": "1"}, note="No `local`: `count` is the variable of the script, *global*."),
            S(9, run='echo "alice 1"', status=0, unset=["name (local)"], out=["alice 1"], note="The local `name` is gone with the function; the global `count` keeps `1`.")])]),
))
page("output", "Output or exit code", "A command prints, and ends with an exit code", J(
    p("A function, like any command, has two ways to answer: the **output** (text, the data) and the **exit code** (success or error). The data is *printed* and captured with `$(...)`; `return N` is not the data."),
    fig(fig_outcode(), "the data: `echo` it, the caller captures it, `sum=$(add 2 3)`; success or error: `return N`"),
    dbg("Returning a value", [sc("values.sh", ADD, "./values.sh", [
        S(2, note="Lines 2 – 7 only **define** `add` and `full_name`: nothing runs."),
        S(8, part="add 2 3", who="copy", run="add 2 3", note="Inside `$(...)`: a copy of `bash` calls the function, its output will be captured."),
        S(3, compute="$(( $1 + $2 ))", also=[[8, "2"], [8, "3"]], vars={"$1": "2", "$2": "3"}, who="copy", info="computes `2 + 3` = `5`"),
        S(3, also=[[8, "2"], [8, "3"]], run="echo 5", status=0, who="copy", info="prints `5`, captured", note="The number is **printed**, as text – not shown on the screen: `$(...)` takes it."),
        S(8, run="sum=5", vars={"sum": "5"}, unset=["$1", "$2"]),
        S(9, part="full_name Alice Smith", who="copy", run="full_name Alice Smith"),
        S(6, also=[[9, "Alice"], [9, "Smith"]], vars={"$1": "Alice", "$2": "Smith"}, run='echo "Smith, Alice"', status=0, who="copy", info="prints `Smith, Alice`, captured", note="A number or a text: for the shell, both are just **text**."),
        S(9, run='name="Smith, Alice"', vars={"name": "Smith, Alice"}, unset=["$1", "$2"]),
        S(10, run='echo "Smith, Alice: 5"', status=0, out=["Smith, Alice: 5"])]),
        sc("data and an error", DIVIDE, "./divide.sh", [
            S(2, run="divide() { ... }", note="Lines 2 – 7 only **define** `divide`. It answers in both ways: the result is **printed**, an error is an **exit code**."),
            S(8, part="divide 7 2", who="copy", run="divide 7 2", vars={"$1": "7", "$2": "2"}, note="A copy of `bash` calls the function: `$1` = `7`, `$2` = `2`."),
            S(3, part="[ $2 -eq 0 ]", also=[[8, "2"]], run="[ 2 -eq 0 ]", status=1, who="copy", note="`2` is not `0`: false, `return 1` is skipped."),
            S(6, compute="$(( $1 / $2 ))", also=[[8, "7"], [8, "2"]], who="copy", info="computes `7 / 2` = `3`"),
            S(6, run="echo 3", status=0, who="copy", info="prints `3`, captured", note="The last command ended with `0`: so does the function."),
            S(8, run="q=3", vars={"q": "3"}, unset=["$1", "$2"], note="Two answers: the output `3` is in `q`, the exit code `0` is in `$?`."),
            S(9, run='echo "7 / 2 = 3, exit code 0"', status=0, out=["7 / 2 = 3, exit code 0"]),
            S(10, part="divide 7 0", who="copy", run="divide 7 0", vars={"$1": "7", "$2": "0"}),
            S(3, part="[ $2 -eq 0 ]", also=[[10, "0"]], run="[ 0 -eq 0 ]", status=0, who="copy", note="Dividing by `0`: the test is true, `then` runs."),
            S(4, run="return 1", status=1, who="copy", info="prints nothing", note="`return 1`: the function ends **now**, with the exit code `1` – an error. It printed nothing."),
            S(10, run='q=""', vars={"q": ""}, unset=["$1", "$2"], note="`q` is **empty**: there was no output. `$?` is `1`: the exit code of the function."),
            S(11, run='echo "7 / 0 = , exit code 1"', status=0, out=["7 / 0 = , exit code 1"], note="The data and the error travel separately: check the exit code with `if` or `||` before you use the data.")])]),
))
page("pitfalls", "Function pitfalls", "It prints and ends with an exit code, nothing more", J(
    pit("What goes wrong?", [
        ("return 300", ["big() { ", ["return 300"], "; }; big; echo $?"], [["$? = 44", "new"]], "$ big() { return 300; }; big; echo $?\n44\n$ big() { echo 300; }; n=$(big); echo $n\n300", False,
         "An exit code is only `0` – `255`: `300` becomes `300 % 256 = 44`. **Print** numbers, capture them with `$(...)`."),
        ("x=$(f) with return", ["f() { ", ["return 5"], "; }; x=$(f); echo \"[$x] $?\""], [["x = \"\"", "new"], ["$? = 5", ""]], '$ f() { return 5; }; x=$(f); echo "[$x] $?"\n[] 5\n$ f() { echo 5; }; x=$(f); echo "[$x] $?"\n[5] 0', False,
         "`return 5` prints nothing: `x` is **empty**, only `$?` is `5`. `return` is not the data: **print** the data."),
        ("called too early", [["welcome alice"], '; welcome() { echo "Hi, $1!"; }'], [["welcome", "cmd"], ["alice", ""]], '$ welcome alice; welcome() { echo "Hi, $1!"; }\n!bash: welcome: command not found', False,
         "Called **before** it is defined: the shell does not know the command `welcome` yet. Define the functions at the top of the script.", dict(wh="the shell sees the words")),
        ("$(set_x)", ["set_x() { x=1; }; x=0; y=", ["$(set_x)"], "; echo $x"], [["x = 0", "new"]], "$ set_x() { x=1; }; x=0; y=$(set_x); echo $x\n0\n$ set_x() { x=1; }; x=0; set_x; echo $x\n1", False,
         "`$(...)` runs the function in a **copy** of `bash`: the `x` it sets is lost. Call it directly; a function in `$(...)` can only *print*.")],
        sub="Pick a line: what goes wrong, and the fix under it in the terminal.", wh="what you get"),
))
page("practice", "Cheat sheet and practice", "Functions", J(
    table(["Write", "Means"], [
        ("`name() { ...; }`", "define a command, before calling it"), ("`name a b`", "call it: `$1`, `$2`, `$#`, `\"$@\"` inside"),
        ("`local x=1`", "a variable only for the function"), ("`return N`", "leave with the exit code `N` (0 – 255)"),
        ("`echo result` + `r=$(name)`", "give back data: print it, capture it"), ("`name && ...`, `if name; then`", "use its exit code")], "k"),
    lab("func", 'greet() {\n    echo "Hello, $1!"\n}\ngreet alice', "./greet.sh"),
))

# ================================================================ 12 parameters
PARAMS = """#!/bin/bash
echo "script: $0"
echo "hello, $1 and $2"
echo "$# parameters\""""
SHOW = """#!/bin/bash
for p in "$@"; do
    echo "[$p]"
done"""
page = chapter("params", "Script parameters", "The words after the name of the script", 14)
page("syntax", "`$0`, `$1`, `$2`, ..., `$#`", "Parameter syntax", J(
    p("The words of the command line become variables of the script."),
    sh('$ ./params.sh alice "Alice Smith" bob'),
    param_map("./params.sh", ["alice", "Alice Smith", "bob"]),
    table(["Variable", "Value"], [
        ("`$0`", "the name of the script, as you typed it"), ("`$1`, `$2`, ... `${10}`", "the parameters"),
        ("`$#`", "how many parameters: `3`"), ("`\"$@\"`", "all the parameters, every one a separate word")], "k"),
    dbg("Script parameters", [sc("params.sh", PARAMS, "./params.sh alice bob", [
        S(2, run='echo "script: ./params.sh"', status=0, out=["script: ./params.sh"], vars={"$0": "./params.sh", "$1": "alice", "$2": "bob", "$#": "2"}, note="`$0` – the name of the script, as you typed it."),
        S(3, run='echo "hello, alice and bob"', status=0, out=["hello, alice and bob"], note="`$1` and `$2` – the first and second word after it."),
        S(4, run='echo "2 parameters"', status=0, out=["2 parameters"], note="`$#` – how many parameters.")])]),
    shell_first("The parameters are the **words** your shell made from the command line: the quotes keep `Alice Smith` one word."),
))
page("all", "`\"$@\"` keeps the words", "Going over the parameters", J(
    p("`\"$@\"` is every parameter, each one a separate word. Without quotes, `$@` is text, cut again at `IFS` – the same rule as for any variable."),
    duo(bash(SHOW, "show.sh") + sh('$ ./show.sh "Alice Smith" bob\n[Alice Smith]\n[bob]'),
        bash(SHOW.replace('"$@"', "$@"), "show2.sh") + sh('$ ./show2.sh "Alice Smith" bob\n[Alice]\n[Smith]\n[bob]')),
    dbg("Going over the parameters", [sc("show.sh", SHOW, './show.sh "Alice Smith" bob', [
        S(2, info='expands to `"Alice Smith"` `"bob"`', vars={"$1": "Alice Smith", "$2": "bob", "$#": "2"}, note="Two words: the space inside `Alice Smith` is kept."),
        S(2, expand="p ", run='p="Alice Smith"', vars={"p": "Alice Smith"}), S(3, run='echo "[Alice Smith]"', status=0, out=["[Alice Smith]"]),
        S(2, expand="p ", run='p="bob"', vars={"p": "bob"}), S(3, run='echo "[bob]"', status=0, out=["[bob]"])])]),
    quiz('`./s.sh "a b" c` – what is `$#`?', ["1", "2", "3", "4"], 1, "Two words after the name: `a b` (one word, quoted) and `c`."),
))
page("practice", "Cheat sheet and practice", "Script parameters", J(
    table(["Write", "Means"], [
        ("`$0`", "the name of the script"), ("`$1` ... `$9`, `${10}`", "the parameters"), ("`$#`", "how many"),
        ("`\"$@\"`", "all of them, every one a word"), ("`shift`", "drop `$1`, the others move down"), ("`exit 1`", "stop the script with an error")], "k"),
    lab("params", PARAMS.replace("#!/bin/bash\n", ""), "./params.sh", args='alice "Alice Smith" bob'),
))

# ================================================================ 13 handling errors, 14 strict mode, 15 trap
TIDY = """#!/bin/bash
# clean up the photos
cd photoz
rm -f *.tmp
echo "photos cleaned\""""
TIDY_E = TIDY.replace("cd photoz", "set -e\ncd photoz")
TIDY_OR = TIDY.replace("cd photoz", "cd photoz || exit 1")
TIDY_IF = TIDY.replace("cd photoz", 'if ! cd photoz; then\n    echo "no photoz folder" >&2\n    exit 1\nfi')
SAVE = """#!/bin/bash
# save the photos
mkdir -p backup || exit 1
cd photos || exit 1
cp *.jpeg ../backup/ || exit 1
echo "photos saved\""""
CLEAN = """#!/bin/bash
set -u
dir=~/backup
rm -r "$dri"/*"""
MANGO = """#!/bin/bash
set -e
tmp=$(mktemp)
trap 'rm -f "$tmp"; echo "removed $tmp"' EXIT
trap 'echo "failed at line $LINENO" >&2' ERR
sort fruits.txt > "$tmp"
grep -q mango "$tmp"
echo "found a mango\""""
TMP = "/tmp/tmp.vQuc2eoya6"
GREET = """#!/bin/bash
set -u
echo "Hello, $1!\""""
GREET_CHECKED = """#!/bin/bash
set -u
if [ $# -eq 0 ]; then
    echo "usage: $0 <NAME>" >&2
    exit 1
fi
echo "Hello, $1!\""""
CD_ERR = "./tidy.sh: line {}: cd: photoz: No such file or directory"

page = chapter("errors", "Handling errors", "When a command fails: the script goes on, unless you check it", 8)
page("goes-on", "A failed command does not stop the script", "After an error", J(
    p("When a command fails, `bash` prints its error and runs the next line, as in the terminal. A script that goes on can do the right thing in the wrong place."),
    dbg("A script goes on after an error", [sc("tidy.sh", TIDY, "./tidy.sh", [
        S(3, run="cd photoz", status=1, out=["!" + CD_ERR.format(3)], note="`cd` fails: the folder is `photos`, not `photoz`."),
        S(4, expand="*.tmp", run="rm -f *.tmp", status=0, note="`rm` runs anyway, in `/home/student`: it deletes the `.tmp` files of the **wrong** folder."),
        S(5, run='echo "photos cleaned"', status=0, out=["photos cleaned"], note="The script ends with `0`, the exit code of `echo`: whoever ran it thinks that it worked.")])]),
))
page("check", "Check it yourself: `||` and `if !`", "Run something only when a command fails", J(
    p("`||` and `if !` run something only when a command fails: the script can stop there, with an exit code that says it failed."),
    dbg("Check it yourself", [
        sc("cd || exit 1", TIDY_OR, "./tidy.sh", [
            S(3, part="cd photoz", run="cd photoz", status=1, out=["!" + CD_ERR.format(3)], note="`cd` fails, so `||` runs the command after it."),
            S(3, part="exit 1", run="exit 1", status=1, info="the script ends",
              note="`exit 1` ends the script with `1`: `rm` never runs, and the caller knows that it failed.")]),
        sc("if ! cd", TIDY_IF, "./tidy.sh", [
            S(3, part="! cd photoz", run="cd photoz", status=1, out=["!" + CD_ERR.format(3)], note="`!` turns the exit code around: `cd` failed, so the condition is true."),
            S(4, run='echo "no photoz folder" >&2', status=0, out=["!no photoz folder"], note="Your own message, to the error output (`>&2`)."),
            S(5, run="exit 1", status=1, info="the script ends", note="Then `exit 1`: the script ends there, `rm` never runs.")]),
    ], sub="Pick a way to check `cd`, then step through it."),
    bash(SAVE, "save.sh"),
    bad("A check after every command", "Every command that may fail needs its own `|| exit 1`, and one is easy to forget.", "let `bash` check all of them: strict mode, in the next chapter."),
))

page = chapter("strict", "Strict mode", "`set -e`, `set -u` and `set -o pipefail`", 14)
page("set-e", "`set -e`: stop at the first error", "*errexit*", J(
    p("`set -e`, on a line near the top of the script, stops the script at the **first command that fails**, with the exit code of that command."),
    dbg("set -e", [sc("tidy.sh", TIDY_E, "./tidy.sh", [
        S(3, run="set -e", status=0, info="turns on `errexit`", note="`set` changes the options of the shell that runs the script."),
        S(4, run="cd photoz", status=1, info="the script stops", out=["!" + CD_ERR.format(4)],
          note="Nobody checks the exit code of `cd`: lines 5 and 6 never run, and the script ends with `1`.")])]),
))
page("checked", "When `set -e` does not stop", "A checked failure is allowed", J(
    p("A command whose exit code is **checked** may fail: `set -e` lets it fail, and the script goes on. That is how you allow a failure."),
    table(["Line, with `set -e`", "When its first command fails"], [
        ("`cd photoz`", "🛑 the script stops"),
        ("`cd photoz || exit 2`", "`exit 2` runs: you choose the exit code"),
        ("`grep -q mango fruits.txt || echo \"none\"`", "✅ `echo` runs, the script goes on"),
        ("`if grep -q mango fruits.txt; then`", "✅ `if` runs `else`; the same for `while` and `until`"),
        ("`! grep -q mango fruits.txt`", "✅ the script goes on")], "k"),
    bad("`((n++))` stops the script", "With `set -e`, `n=0; ((n++))` computes the old value of `n`, `0`: `((...))` ends with `1`, and the script stops without a message.",
        "count with `n=$((n + 1))`."),
    quiz("With `set -e`, which line stops the script when `grep` finds nothing?", ["`grep -q kiwi f.txt || echo none`", "`if grep -q kiwi f.txt; then echo yes; fi`", "`grep -q kiwi f.txt`", "`! grep -q kiwi f.txt`"], 2,
         "Only the bare `grep` is not checked: `||`, `if` and `!` look at its exit code, so `set -e` lets it fail."),
))
page("set-u", "`set -u`: unset variables are errors", "*nounset*", J(
    p("Without `set -u`, a variable that is not set is an empty text, and a typo in its name goes unnoticed. With `set -u`, it is an error that stops the script."),
    dbg("set -u", [
        sc("without set -u", CLEAN.replace("set -u\n", ""), "./clean.sh", [
            S(2, run="dir=/home/student/backup", vars={"dir": "/home/student/backup"}),
            S(3, part='rm -r "$dri"/*', run="rm -r /*", info="⚠️ deletes every file you may delete",
              note="A typo: `dri` is not set, so `\"$dri\"/*` is `/*`. Do not run this!")]),
        sc("with set -u", CLEAN, "./clean.sh", [
            S(2, run="set -u", status=0, info="turns on `nounset`"),
            S(3, run="dir=/home/student/backup", vars={"dir": "/home/student/backup"}),
            S(4, part="$dri", info="the script stops", out=["!./clean.sh: line 4: dri: unbound variable"],
              note="`dri` is not set: the script stops **before** `rm` runs, with `1`.")]),
    ], sub="The same typo, without and with `set -u`."),
    "<h2>" + md("`set -u` and the parameters") + "</h2>",
    p("`$1` is not set when the script gets no parameters: `set -u` stops the script with an error that does not help the user. `$#` is always set: check it **before** you use `$1`."),
    dbg("set -u and $1", [
        sc("no check", GREET, "./greet.sh", [
            S(2, run="set -u", status=0, info="turns on `nounset`"),
            S(3, part="$1", info="the script stops", out=["!./greet.sh: line 3: $1: unbound variable"],
              note="No parameters: `$1` is **not set**, and `set -u` stops the script with `1`.")]),
        sc("check $# first", GREET_CHECKED, "./greet.sh", [
            S(2, run="set -u", status=0, info="turns on `nounset`"),
            S(3, part="[ $# -eq 0 ]", run="[ 0 -eq 0 ]", status=0, vars={"$#": "0"}, note="`$#` is always set: here `0`."),
            S(4, run='echo "usage: ./greet.sh <NAME>" >&2', status=0, out=["!usage: ./greet.sh <NAME>"], note="Say how to run the script, on the error output."),
            S(5, run="exit 1", status=1, info="the script ends", note="Then end with `1`: line 7, with `$1`, never runs.")]),
    ], sub="`./greet.sh`, without parameters."),
))
page("pipefail", "`set -o pipefail`", "A pipe fails when any of its commands fails", J(
    p("A pipe ends with the exit code of its **last** command: when `grep` fails but `wc` works, `set -e` does not see the error. With `pipefail`, the pipe ends with the exit code of the last command that failed."),
    sh("$ grep kiwi nope.txt | wc -l\ngrep: nope.txt: No such file or directory\n0\n$ echo $?\n0\n$ set -o pipefail\n$ grep kiwi nope.txt | wc -l\ngrep: nope.txt: No such file or directory\n0\n$ echo $?\n2"),
))
page("all", "All three: `set -euo pipefail`", "Strict mode, on the line after the shebang", J(
    table(["Option", "Name", "What it does"], [
        ("`set -e`", "*errexit*", "stops at the first command that fails, outside a condition"),
        ("`set -u`", "*nounset*", "a variable that is not set is an error, not an empty text"),
        ("`set -o pipefail`", "*pipefail*", "a pipe fails when **any** of its commands fails"),
        ("`set -x`", "*xtrace*", "prints every command before it runs, like `bash -x`")], "k"),
    p("`set +e` (with `+`) turns an option off again. Start your scripts with the first three: a mistake stops the script, it does not go on in the wrong place."),
    bash("#!/bin/bash\nset -euo pipefail\nmkdir -p ~/backup\ncp ~/notes.txt ~/backup/", "backup.sh"),
))
page("practice", "Cheat sheet and practice", "Strict mode", J(
    table(["Write", "Means"], [
        ("`cmd || exit 1`", "end the script when `cmd` fails"), ("`set -e`", "stop at the first command that fails"),
        ("`set -u`", "a variable that is not set is an error"), ("`set -o pipefail`", "a pipe fails when any of its commands fails"),
        ("`set -euo pipefail`", "the three, on the line after the shebang")], "k"),
    lab("errors", TIDY, "./tidy.sh", files=["fruits.txt", "notes.txt", "lib.sh"], ex=[("set -e", TIDY_E)]),
))

TRAP_SYNTAX = ('<div class="b8pm">'
               '<div><span class="w8 cmd">trap</span><b>the command</b></div>'
               '<div><span class="w8 new">\'rm -f "$tmp"\'</span><b>what to run, in single quotes</b></div>'
               '<div><span class="w8">EXIT</span><b>when to run it</b></div></div>')
page = chapter("trap", "Cleaning up: `trap`", "Commands that run when the script ends", 10)
page("syntax", "`trap` syntax", "Remember commands now, run them later", J(
    TRAP_SYNTAX,
    ul("`trap` runs **nothing** now: `bash` **remembers** the commands",
       "the single quotes keep `$tmp` as it is: it is replaced when the trap runs",
       "`trap -p` lists the traps, `trap - EXIT` forgets one"),
    table(["When", "The commands run"], [
        ("`EXIT`", "when the script ends, however it ends: after the last line, at `exit`, or stopped by `set -e`"),
        ("`ERR`", "after every command that fails, where `set -e` would stop")], "k"),
))
page("debug", "When the traps run", "🐞 `trap`", J(
    dbg("When the traps run", [sc("mango.sh", MANGO, "./mango.sh", [
        S(2, run="set -e", status=0, info="turns on `errexit`"),
        S(3, part="mktemp", who="copy", run="mktemp", status=0, info="prints the name",
          note="`mktemp` creates a new, **empty** file with a unique name in `/tmp`, and prints its name."),
        S(3, run="tmp=" + TMP, vars={"tmp": TMP}, note="`tmp` keeps the name of the temporary file."),
        S(4, run="trap 'rm -f \"$tmp\"; echo \"removed $tmp\"' EXIT", status=0, info="nothing runs now",
          note="`bash` **remembers** the commands, for when the script ends; the single quotes keep `$tmp` for then."),
        S(5, run="trap 'echo \"failed at line $LINENO\" >&2' ERR", status=0, info="nothing runs now",
          note="Remembered too, for after a command that fails."),
        S(6, run="sort fruits.txt > " + TMP, status=0, note="`sort` writes the sorted fruits into the temporary file."),
        S(7, run="grep -q mango " + TMP, status=1, note="There is no `mango`: `grep` ends with `1`."),
        S(5, part='echo "failed at line $LINENO" >&2', run='echo "failed at line 7" >&2', status=0, out=["!failed at line 7"],
          note="A command failed: first, the `ERR` trap runs – `$LINENO` is `7`, the line of `grep`."),
        S(7, info="`set -e` stops the script", note="Nobody checks the exit code of `grep`: `set -e` stops the script, line 8 never runs."),
        S(4, part='rm -f "$tmp"', run="rm -f " + TMP, status=0, note="The script ends: now the `EXIT` trap runs, and deletes the temporary file."),
        S(4, part='echo "removed $tmp"', run='echo "removed ' + TMP + '"', status=0, out=["removed " + TMP],
          note="The script ends with `1`, the exit code of `grep`; with a `mango`, the same `EXIT` trap runs after line 8.")],
        files={"fruits.txt": FRUITS})]),
))
page("practice", "Cheat sheet and practice", "`trap`", J(
    table(["Write", "Means"], [
        ("`trap '...' EXIT`", "run at the end, however the script ends"), ("`trap '...' ERR`", "run after every command that fails"),
        ("`trap -p`", "list the traps"), ("`trap - EXIT`", "forget a trap"), ("`tmp=$(mktemp)`", "a new, empty temporary file")], "k"),
    lab("trap", MANGO, "./mango.sh", files=["fruits.txt", "notes.txt"]),
))

# ================================================================ flashcards
FLASH = [
    ("01", "Scripts", "scripts/commands", "Everything is a command line", "Variables, `if`, loops were added on top of a shell that runs commands: ask *what command runs here?*"),
    ("01", "Scripts", "scripts/run", "`./s.sh` needs `x`, `bash s.sh` does not", "With `./`, the kernel runs the file and reads `#!`; with `bash`, the script is only a parameter."),
    ("01", "Scripts", "scripts/source", "`source s.sh` runs in your shell", "No new process: its `cd` and its variables stay; an `exit` in it closes your terminal."),
    ("02", "Variables", "vars/wrong", "No spaces around `=`", "`name = alice` runs the command `name`; `name= alice` runs `alice` with an empty `name`."),
    ("02", "Variables", "vars/text", "A variable holds text", "`$name` is replaced when the line runs: `greeting` keeps the text, not a formula."),
    ("03", "IFS", "words/spaces", "An unquoted `$x` is cut at `IFS`", "Many spaces are one cut; `::` with `IFS=:` makes an empty word."),
    ("03", "IFS", "words/quotes", "`\"$x\"` is always one word", "Quote variables unless you want them cut."),
    ("04", "read", "read/syntax", "The last variable takes the rest", "`read first last` on `Alice Mary Smith` puts `Mary Smith` in `last`."),
    ("04", "read", "read/pitfalls", "`IFS= read -r line`", "Reads a line exactly: no backslash removed, no space cut."),
    ("04", "read", "read/ifs", "`IFS=: printf ... $x` does not cut at `:`", "The shell cuts `$x` before the command starts; only `read` uses `IFS` itself, on the line it reads."),
    ("05", "$( )", "subst/syntax", "`$(cmd)` is the output, as text", "It runs in a copy of bash; the last newline is removed."),
    ("06", "Arithmetic", "arith/text", "`$a+$b` is the text `2+3`", "Compute with `$((a + b))` or with the program `expr`."),
    ("06", "Arithmetic", "arith/syntax", "Integers only", "`$((7 / 2))` is `3`; for decimals use the program `bc`."),
    ("07", "if", "if/syntax", "`0` is true", "`if` runs a command: exit code `0` runs `then`, anything else is false."),
    ("07", "[", "if/test", "`[` is a program", "It needs spaces around every word and `]` as its last parameter."),
    ("07", "[", "if/pitfalls", "Quote the variables in `[`", "An empty `$x` disappears: `[ = abc ]` is an error, `[ \"\" = abc ]` is not."),
    ("08", "case", "case/globs", "`case` patterns are globs", "`*` is any text, `?` one character; not regular expressions."),
    ("08", "case", "case/debug", "The first match wins", "`;;` jumps after `esac`: put the specific patterns first, `*` last."),
    ("09", "while", "while/read", "`while read ...; done < file`", "Reads a file line by line, in the shell itself."),
    ("09", "while", "while/pitfalls", "A pipe runs the loop in a copy", "`cat f | while ...` loses the variables; use `< f` after `done`."),
    ("10", "for", "for/lines", "`for` goes over words", "To go over lines, use `while read`."),
    ("11", "Functions", "func/output", "Print the data, return the status", "`sum=$(add 2 3)` captures the output; `return` is only `0` – `255`."),
    ("11", "Functions", "func/debug", "`local` keeps a variable inside", "Without it, a function changes the variables of the script."),
    ("12", "Parameters", "params/all", "`\"$@\"` keeps the words", "Unquoted `$@` is cut again at `IFS`."),
    ("13", "Errors", "errors/goes-on", "A script goes on after an error", "A failed command prints its error, then `bash` runs the next line: check it with `||`, or use `set -e`."),
    ("14", "Strict mode", "strict/checked", "`set -e` lets a checked command fail", "The condition of `if` and `while`, a command before `||` or `&&`, and `! cmd` do not stop the script."),
    ("14", "Strict mode", "strict/all", "`set -euo pipefail`", "Stop at the first failed command, at a variable that is not set, and at a failed command of a pipe."),
    ("15", "trap", "trap/syntax", "`trap '...' EXIT` cleans up", "`trap` remembers the commands; they run however the script ends: delete the temporary files of `mktemp` there."),
]
page = chapter("flashcards", "Flashcards", "The ideas of the lecture, one card each", 10)
page("recap", "The ideas, in short", "Quick recap", J(
    '<p class="txt">One idea per card; the title is the idea, the text says why it matters in practice. <em>Recap</em> shows all the cards, <em>Flashcard</em> one at a time.</p>',
    flash_cards(FLASH)))

CSS = """
.pg h2{margin-top:34px}

/* ---- the interactive parts: a teal frame and a label (as in lectures 02, 03 and 07) ---- */
.wd{container-type:inline-size;border:2px solid #00838f;border-radius:16px;box-shadow:0 0 0 5px #e3f2f3,0 14px 34px rgba(0,77,101,.08);margin:34px 0}
.wd-h{background:linear-gradient(100deg,#dcefF1,#eef6f7 70%);align-items:center;padding:12px 20px}
.wd-h h3::before{content:"\\25B6  Interactive";display:block;width:max-content;font:800 10.5px/1 system-ui,sans-serif;letter-spacing:1.4px;text-transform:uppercase;color:#fff;background:#00838f;border-radius:999px;padding:5px 10px;margin-bottom:7px}
.wd-h p{color:#33555f}
.tryjump{display:inline-flex;align-items:center;gap:10px;margin:-6px 0 20px;padding:7px 16px 7px 7px;border:1.5px solid #00838f;border-radius:999px;background:#f0f8f9;color:#004d65;font-size:14px;text-align:left;max-width:100%}
.tryjump:hover{background:#dcefF1}
.tryjump b{color:#00838f}
.tryjump .tj-i{flex:0 0 26px;height:26px;border-radius:50%;background:#00838f;color:#fff;display:grid;place-items:center;font-size:10px}
.side .tri{font-style:normal;font-size:9px;color:#00838f;margin-left:auto;align-self:center;padding-left:6px}
.side li a.on .tri{color:#004d65}
.chip.on{background:#004d65;color:#fff;border-color:#004d65}
.chl{font-size:12.5px;font-weight:700;color:var(--muted);margin-right:6px;align-self:center}

/* ---- step-by-step: selector and Back/Next on one bar, an orange strip, the picture ---- */
.ps-c{align-items:center;justify-content:space-between;gap:8px 16px;padding:10px 18px}
.ps-c .seg{flex:0 1 auto;min-width:0;flex-wrap:wrap}
.ps-nav{display:flex;align-items:center;gap:10px;margin-left:auto}
.ps-nav .btn{padding:7px 14px}
.ps-nav .btn[disabled]{opacity:.45;cursor:default}
.pdots{display:flex;align-items:center;gap:5px;flex-wrap:nowrap;padding:0 2px}.pdots i{flex:0 0 auto}.pdots i{width:9px;height:9px;border-radius:50%;background:#ccdbe0}.pdots i.dn{background:#00838f}.pdots i.on{background:#e65100;transform:scale(1.3)}
.pcount{font-size:13px;font-weight:700;color:var(--navy);white-space:nowrap}
.ps-x{padding:8px 18px;background:#fff6ef;border-bottom:1px solid #f6d6bd;font-size:15px;line-height:1.45;min-height:46px}
.ps-x b{color:#c2410c}
.ps-x code,.db-info code{background:#fff;border:1px solid #f0d2bb;border-radius:4px;padding:0 4px}

/* ---- the words of a command line, as chips ---- */
.w8{display:inline-block;font:600 13.5px/1.25 'SF Mono',Menlo,Consolas,monospace;padding:3px 8px;margin:3px 5px 3px 0;border:1.5px solid #9aa9ae;border-radius:6px;background:#fff;color:#1f2d33;white-space:pre-wrap;overflow-wrap:anywhere;vertical-align:middle}
.w8.cmd{background:#004d65;border-color:#004d65;color:#fff}
.w8.new{background:#ffe6cc;border-color:#d79b00;color:#8a4b00}
.w8.asg{border-style:dashed;border-color:#00838f;color:#00727c;background:#eef8f9}
.w8.redir{background:#f3e8f7;border-color:#9a4d76;color:#6a1b9a}
.w8 i{color:#9aa9ae;font-style:normal}
.w8.new i{color:#b35900}

/* ---- static scripts ---- */
.b8src{margin:0 0 14px}
.b8src pre.sh{margin:0}
.b8name{display:inline-block;font:700 12.5px 'SF Mono',Menlo,monospace;color:#004d65;background:#dae8fc;border-radius:8px 8px 0 0;padding:3px 12px}
.b8name+pre.sh{border-top-left-radius:0}
.b8first{display:flex;gap:12px;align-items:flex-start;border-left:4px solid #004d65;background:#eef4f7;border-radius:0 10px 10px 0;padding:12px 18px;margin:18px 0;max-width:900px}
.b8first b{line-height:1.2}
.b8sh{display:inline-block;flex:0 0 auto;font:800 13px/1 'SF Mono',Menlo,Consolas,monospace;color:#7fd1c6;background:#1d2740;border-radius:6px;padding:5px 7px;vertical-align:middle}.b8first p{margin:0;font-size:15.5px}
.b8one{border:1px solid #cfe3df;border-left:4px solid #00838f;background:#f6fafa;border-radius:0 10px 10px 0;padding:12px 18px;margin:20px 0;max-width:900px;display:grid;gap:8px}
.b8one h3{font-size:15px;color:var(--teal-d);margin:0}
.b8one p{margin:0;font-size:15px}
.b8one pre.sh{margin:0;font-size:13.5px}
.b8card h3{font-size:15px}.b8card.ok h3{color:#2e7d46}.b8card.no h3{color:#b3261e}
.b8zero{border:2px solid #b85450;background:#fff8f6;border-radius:12px;padding:12px 18px;margin:18px 0;max-width:560px}
.b8zero>b{display:block;color:#b3261e;font-size:17px;margin-bottom:6px}
.b8zero>div{display:flex;align-items:center;gap:10px;margin:6px 0;font-size:15px}
.b8pm{display:flex;flex-wrap:wrap;gap:6px 14px;align-items:flex-start;margin:14px 0}
.b8pm>div{display:flex;flex-direction:column;align-items:center}
.b8pm>div b{font:700 13px 'SF Mono',Menlo,monospace;color:#e65100}
.b8pm .b8pmn{align-self:center;font-size:15px}

/* ---- the debugger ---- */
.db-b{display:grid;grid-template-columns:minmax(0,1fr)}
.db-b>div{padding:12px 16px;min-width:0}
.db-b>div+div{border-top:1px solid var(--line)}
@container (min-width:720px){.db-b{grid-template-columns:minmax(0,1.2fr) minmax(0,1fr)}.db-b>div+div{border-top:0;border-left:1px solid var(--line)}}
.db-fh{display:flex;justify-content:space-between;gap:10px;font-size:12px;color:var(--muted);background:#eef1f3;border:1px solid #d3dde1;border-bottom:0;border-radius:8px 8px 0 0;padding:4px 10px}
.db-fh b{color:var(--navy);font:700 12.5px 'SF Mono',Menlo,monospace}
pre.db-code{margin:0;border:1px solid #d3dde1;border-radius:0 0 8px 8px;background:#fbfcfd;font:13.5px/1.5 'SF Mono',Menlo,Consolas,monospace;padding:5px 0;white-space:pre-wrap;overflow-wrap:anywhere;max-height:300px;overflow-y:auto;color:#1f2d33}
pre.db-code[hidden]{display:none}
.db-ln{display:grid;grid-template-columns:30px minmax(0,1fr);padding-right:8px}
.db-ln>b{color:#9aa9ae;font-weight:400;text-align:right;padding-right:10px;user-select:none}
.db-ln.cur{background:#fff3e6;box-shadow:inset 3px 0 0 #d79b00}
.db-ln.cur>b{color:#b35900;font-weight:700}
mark.db-part{background:#ffd3a6;color:inherit;border-radius:3px;box-shadow:0 0 0 1.5px #d79b00;font-weight:700}
mark.db-cmp{background:#dcebfa;color:inherit;border-radius:3px;box-shadow:0 0 0 1.5px #6c8ebf;font-weight:700}
mark.db-exp{background:transparent;color:inherit;outline:1.5px dotted #b35900;outline-offset:1px;border-radius:2px}
mark.db-also{background:#ffe6cc;color:inherit;border-radius:3px}
.db-run{display:flex;flex-wrap:wrap;align-items:center;gap:6px 8px;margin-top:10px;padding:7px 10px;border-radius:8px;background:#f4f7f8;border:1px solid #dbe4e7;min-height:44px;font-size:14px}
.db-run[hidden]{display:none}
.db-lab{font:700 11px system-ui,sans-serif;letter-spacing:.6px;text-transform:uppercase;color:var(--muted)}
.db-who{font:700 11.5px system-ui,sans-serif;color:#fff;background:#00838f;border-radius:999px;padding:2px 9px}
code.db-cmd{font:600 13.5px 'SF Mono',Menlo,monospace;background:#fff;border:1px solid #d3dde1;border-radius:6px;padding:2px 8px;white-space:pre-wrap;overflow-wrap:anywhere;color:#1f2d33}
.db-ec{display:inline-block;font:800 13px 'SF Mono',Menlo,monospace;border-radius:999px;padding:2px 9px;color:#fff;background:#2e7d46}.db-ec.bad{background:#b3261e}
.db-run .db-ec::before{content:"exit code ";font:600 11px system-ui,sans-serif}
.db-info{color:#33555f}
.db-h{font:700 11px system-ui,sans-serif;letter-spacing:.8px;text-transform:uppercase;color:var(--navy);margin:0 0 5px}
.db-h:not(:first-child){margin-top:12px}
table.db-vt{width:100%;border-collapse:collapse;font-size:13.5px}
.db-vt td{padding:3px 8px;border-bottom:1px solid #e6edf0;vertical-align:top}
.db-vt td:first-child{font:700 13px 'SF Mono',Menlo,monospace;color:#9a4d76;white-space:nowrap;width:1%}
.db-vt code{font-size:13px;white-space:pre-wrap;overflow-wrap:anywhere;background:none;padding:0}
.db-vt code i{color:#9aa9ae;font-style:normal}
.db-vt em{font-size:12px;color:var(--muted)}
.db-vt tr.ch td{background:#ffe6cc}.db-vt tr.ch td:first-child{color:#b35900}
.db-vt tr.x td{background:#fdecea;text-decoration:line-through;color:#b3261e}.db-vt tr.x td:first-child{color:#b3261e}
.db-none{color:var(--muted);font-size:13px;font-style:italic;margin:0}
pre.db-out{margin:0;background:#1d2740;color:#e6edf5;border:0;border-radius:8px;padding:7px 12px;font:13px/1.45 'SF Mono',Menlo,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;min-height:58px;max-height:170px;overflow-y:auto}
.db-out .db-pr{color:#7fd1c6;font-weight:700}
.db-out .db-none{color:#8a9bb5}
.db-new{color:#ffc27a;font-weight:700}
.db-err{color:#ff9e93}
.db-st{color:#8a9bb5}
.db-files{display:flex;flex-wrap:wrap;gap:8px;margin-top:10px}
.db-file{border:1px solid #d3dde1;border-radius:8px;overflow:hidden;font-size:12.5px;min-width:120px;background:#fff}
.db-file>div{background:#eef1f3;padding:3px 10px;font:700 12px 'SF Mono',Menlo,monospace;color:var(--navy)}
.db-file pre{margin:0;padding:4px 10px;font:12.5px/1.45 'SF Mono',Menlo,monospace;white-space:pre-wrap}
.db-file pre span.on{background:#ffe6cc;color:#b35900;font-weight:700}
.dbg .db-files .db-file pre{max-height:none}

/* ---- the script lab ---- */
.lb-c{align-items:center;gap:8px 10px;padding:10px 18px}
.lb-c .btn{padding:7px 14px}
.lb-c .btn[hidden]{display:none}
.lb-reset{border:0;background:none;color:var(--muted);text-decoration:underline;font-size:13px;padding:4px}
.lb-nav{margin-left:auto}.lb-nav[hidden]{display:none}
.lb-x[hidden]{display:none}
.lb-ed{position:relative;border:1px solid #d3dde1;border-radius:0 0 8px 8px;background:#fbfcfd}
.lb-ed[hidden]{display:none}
.lb-ed pre,.lb-ed textarea{margin:0;padding:8px 12px 8px 14px;font:13.5px/1.5 'SF Mono',Menlo,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;tab-size:4;border:0;width:100%;box-sizing:border-box;letter-spacing:0}
.lb-ed pre{position:absolute;left:0;top:0;right:0;overflow:hidden;pointer-events:none;color:#1f2d33;background:none}
.lb-ed textarea{position:relative;display:block;background:transparent;color:transparent;caret-color:#004d65;resize:none;outline:0;min-height:150px;overflow:hidden}
.lb-ed textarea:focus{box-shadow:inset 0 0 0 2px #00838f;border-radius:0 0 8px 8px}
.lb-ed textarea::selection{background:rgba(0,131,143,.25);color:transparent}
.lb-args{display:flex;align-items:center;gap:6px;margin-top:8px;font:13.5px 'SF Mono',Menlo,monospace}
.lb-args .db-pr{color:#00838f;font-weight:700}
.lb-args code{background:none;padding:0;color:#004d65;font-weight:700}
.lb-args input{flex:1;min-width:0;border:1px solid #d3dde1;border-radius:6px;padding:4px 8px;font:13.5px 'SF Mono',Menlo,monospace}
.lb-kb{display:block;margin-top:8px;font-size:12.5px;color:var(--muted)}
.lb-kb span{display:block;margin-bottom:3px}
.lb-kb textarea{width:100%;box-sizing:border-box;border:1px solid #d3dde1;border-radius:6px;padding:4px 8px;font:13px/1.45 'SF Mono',Menlo,monospace;resize:none;overflow:hidden;white-space:pre-wrap;overflow-wrap:anywhere;min-height:32px}
.lab .missions li .mt code{font-size:13px}
.missions:not(.all):not(.fin) ol{display:block}
.missions:not(.all):not(.fin) li.ok,.missions:not(.all):not(.fin) li:not(.ok)~li{visibility:hidden;height:0;padding:0;overflow:hidden}
.missions .mall{margin-left:10px;border:1px solid #c9d5ec;background:#fff;border-radius:999px;padding:1px 10px;font-size:12px;color:var(--navy)}
.missions .mall:hover{background:#eef3fb}
.missions.fin .mall{display:none}
.missions .mnote{font-size:12px;color:var(--muted);margin-left:10px}

/* ---- IFS ---- */
.sp-c{align-items:flex-end;gap:10px 18px;padding:10px 18px}
.sp-c>div{display:flex;align-items:center;flex-wrap:wrap;gap:4px}
.sp-v{display:flex;flex-direction:column;gap:3px;font-size:12px;font-weight:700;color:var(--muted);flex:1 1 340px;min-width:0;max-width:520px}
.sp-v textarea{font:15px/1.45 'SF Mono',Menlo,monospace;border:1px solid #c9d5ec;border-radius:6px;padding:4px 8px;width:100%;resize:none;white-space:pre-wrap;overflow-wrap:anywhere;overflow:hidden;box-sizing:border-box;min-height:32px}
.gl-in input{font:15px 'SF Mono',Menlo,monospace;border:1px solid #c9d5ec;border-radius:6px;padding:4px 8px;width:270px;max-width:100%;box-sizing:border-box}
.sp-pre{display:flex;flex-wrap:wrap;gap:5px;align-items:center;flex-basis:100%}
.sp-pre .chip{white-space:pre}
.sp-b{padding:12px 18px;display:grid;gap:10px}
.sp-row{display:grid;grid-template-columns:minmax(0,1fr);gap:4px;align-items:center}
@container (min-width:620px){.sp-row{grid-template-columns:150px minmax(0,1fr)}}
.sp-k{font:700 12.5px 'SF Mono',Menlo,monospace;color:var(--muted)}
.sp-row.sp-rd{grid-template-columns:minmax(0,1fr);gap:8px}
code.sp-cmd{display:block;width:max-content;max-width:100%;font-size:14.5px;white-space:nowrap;overflow-x:auto;background:#e6edf0;border:1px solid #d3e0e5;border-radius:6px;padding:4px 10px}
.sp-line{display:inline-flex;flex-wrap:wrap;border:1px solid #c4d3d8;border-radius:6px;padding:3px 5px;background:#fff}
.sp-line span{display:inline-block;min-width:.66em;text-align:center;font:600 16px/1.4 'SF Mono',Menlo,monospace;padding:0 1px}
.sp-line span.ws{color:#9aa9ae}
.sp-line span.sep{background:#ffe6cc;color:#b35900;border-radius:3px;box-shadow:0 0 0 1px #d79b00}
.sp-map{display:flex;flex-wrap:wrap;gap:4px 10px}
.sp-map>span{display:inline-flex;flex-direction:column;align-items:center}
.sp-map b{font:700 12.5px 'SF Mono',Menlo,monospace;color:#e65100}
pre.sh.sp-sh{margin:0;font-size:13px;white-space:pre-wrap}

/* ---- the shell sees the words ---- */
.pw-chips{display:flex;flex-wrap:wrap;gap:5px;flex:1 1 300px;min-width:0}
.pw-b{display:grid;grid-template-columns:minmax(0,1fr);gap:12px;padding:12px 18px}
@container (min-width:700px){.pw-b{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}}
.pw-t{display:flex;gap:8px;align-items:center;margin-bottom:12px}
.pw-t code{font-size:15px;background:none;padding:0;white-space:pre-wrap;overflow-wrap:anywhere}
.pw-t u{text-decoration:none;border-radius:3px;padding:1px 0;white-space:pre}
.pw-t u.bad{background:#fde3df;box-shadow:inset 0 -2.5px 0 #b3261e}
.pw-t u.good{background:#e3f1e4;box-shadow:inset 0 -2.5px 0 #2e7d46}
.pw-mk{font-size:18px}
pre.sh.pw-sh{margin:0;font-size:13px;white-space:pre-wrap;overflow-wrap:anywhere}
pre.sh .db-err{color:#b3261e}
.pw-files{margin:0 0 12px}
.pw-files .db-file{display:inline-block;min-width:150px;vertical-align:top;margin-right:8px}
.pw-files .db-file pre{font-size:13.5px}
.pw-try{border-top:1px solid var(--line);padding:12px 18px;display:grid;gap:8px}
.pw-try label{display:flex;flex-wrap:wrap;align-items:center;gap:8px;font-size:12.5px;font-weight:700;color:var(--muted)}
.pw-try input{flex:1 1 260px;font:15px 'SF Mono',Menlo,monospace;border:1px solid #c9d5ec;border-radius:6px;padding:5px 9px}
.pw-try p{margin:0}

/* ---- running a script ---- */
.rs-b{display:grid;grid-template-columns:minmax(0,1fr);gap:14px;padding:12px 18px}
@container (min-width:720px){.rs-b{grid-template-columns:minmax(0,1.25fr) minmax(0,1fr)}}
.rs-typed{margin-bottom:8px}.rs-typed code{font-size:13px}
.rs-steps{list-style:none;margin:0;padding:0;display:grid;gap:5px}
.rs-steps li{display:grid;grid-template-columns:62px minmax(0,1fr);gap:8px;align-items:center;padding:5px 8px;border-radius:8px;font-size:14.5px;border:1px solid transparent}
.rs-steps li.todo{opacity:.3}
.rs-steps li.on{background:#fff3e6;border-color:#f0c79c}
.rs-a{font:700 11.5px system-ui,sans-serif;text-align:center;border-radius:6px;padding:3px 0;color:#fff;background:#00838f}
.rs-a.kernel{background:#ffe6cc;color:#8a5a00;box-shadow:inset 0 0 0 1px #d79b00}
.rs-a.you{background:#eef1f3;color:#5b6b71}
.rs-f{display:block;margin-bottom:10px}
.rs-f>div{display:flex;justify-content:space-between;align-items:center;gap:8px}
.rs-perm{font-size:13px;background:none;padding:0}
.rs-perm b.chk{color:#b35900;background:#ffe6cc;box-shadow:0 0 0 1.5px #d79b00;border-radius:2px}
.rs-perm s{color:#9aa9ae}
.rs-perm b.no{color:#b3261e;background:#fde3df;border-radius:2px}
.rs-f pre>span{display:block;padding:0 4px;border-radius:3px}
.rs-f pre span.bang{background:#ffe6cc;font-weight:700}.rs-f pre span.bang b{color:#b35900;box-shadow:0 0 0 1.5px #d79b00;border-radius:2px}
.rs-f pre span.bang em{font:700 11px system-ui,sans-serif;color:#b35900;margin-left:6px}
.rs-f pre span.dim{color:#9aa9ae}.rs-f pre span.dim *{color:#9aa9ae!important}
.rs-f pre span.run{background:#ffe6cc}
pre.rs-out{min-height:72px}

/* ---- $( ) ---- */
.sb-b{padding:12px 18px;display:grid;gap:6px}
.sb-box{border:1.5px solid #c4d3d8;border-radius:10px;padding:7px 12px;background:#fff;min-width:0}
.sb-box.on{border-color:#d79b00;background:#fff6ec}
.sb-box.hid,.sb-mid.hid,.sb-row.hid,.sb-ar.hid{visibility:hidden}
.sb-t{font-size:12px;font-weight:700;color:var(--muted);margin-bottom:4px}
.sb-box.on .sb-t{color:#b35900}
code.sb-line{font-size:15px;background:none;padding:0;white-space:pre-wrap;overflow-wrap:anywhere}
.sb-then{margin-top:6px;display:flex;flex-wrap:wrap;align-items:center;gap:6px}
.sb-mid{display:flex;justify-content:space-between;gap:10px;padding:0 20px;font-size:13.5px;color:var(--muted)}
.sb-ar.on{color:#b35900}
.sb-row{display:grid;grid-template-columns:minmax(0,1fr);gap:6px;align-items:center}
@container (min-width:620px){.sb-row{grid-template-columns:minmax(0,1fr) auto minmax(0,1fr)}}
.sb-pipe{font:600 12px 'SF Mono',Menlo,monospace;color:var(--muted);text-align:center}
.sb-box pre{margin:0;font:600 14px/1.4 'SF Mono',Menlo,monospace;color:#b35900;white-space:pre-wrap}
.sb-nl{font-size:12px;font-style:italic;color:var(--muted)}
pre.sh.sb-sh{margin:4px 0 0;font-size:13px}

/* ---- case patterns ---- */
.gl-in{display:flex;flex-direction:column;gap:3px;font-size:12px;font-weight:700;color:var(--muted)}
.gl-b{display:grid;grid-template-columns:minmax(0,1fr);gap:12px;padding:12px 18px}
@container (min-width:760px){.gl-b{grid-template-columns:minmax(0,1.3fr) minmax(0,1fr)}}
table.gl-t{margin:0;font-size:14px}
.gl-t tr.pick td{background:#ffe6cc}
.gl-t td.y{color:#2e7d46;white-space:nowrap}.gl-t td.n{color:#b3261e}
.gl-t td b{font-size:12px;color:#b35900;margin-left:4px}
pre.sh.gl-code{margin:0;font-size:13px}
.gl-code .cur{background:#ffe6cc;font-weight:700;border-left:3px solid #d79b00;margin-left:-3px}
.gl-rx{font-size:14px;display:grid;gap:4px}

/* ---- $(( )) and bc ---- */
.ca-b{display:grid;grid-template-columns:minmax(0,1fr);gap:12px;padding:12px 18px}
@container (min-width:620px){.ca-b{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}}
.ca-b pre.sh{margin:0;font-size:13.5px;white-space:pre-wrap;overflow-wrap:anywhere;min-height:84px}
.ca-x{border-top:1px solid #f6d6bd;border-bottom:0}
.ca-bh{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:6px}
.ca-bh .seg button{padding:3px 9px;font-size:12px;text-transform:none;letter-spacing:0}
.ca-in{flex:1 1 260px;max-width:420px}.ca-in input{width:100%}

svg.f3{display:block;width:100%;height:auto;margin:0 auto}

/* ---- tables wrap instead of scrolling sideways; terminals wrap their long lines ---- */
.pg table.t td code,.pg table.t th code{white-space:normal}
.pg table.t.k td:first-child{white-space:normal}
.pg table.t.b8nw td:first-child{white-space:nowrap}
.pg table.t.b8nw td:first-child code,.pg table.t.b8nw td:nth-child(2)>code:only-child{white-space:pre}
.pg pre.sh{white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:hidden}
@media (max-width:520px){.pg table.t{font-size:13px}.pg table.t th,.pg table.t td{padding:7px 6px}.pg table.t td,.pg table.t th{overflow-wrap:anywhere}}

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
    num="08", key="iso-08-scripting-v1", short="Shell Scripting",
    title="Shell Scripting, step by step · ISO Lecture 08",
    description="ISO Lecture 08 – Shell Scripting: scripts, variables, IFS, read, $(...), arithmetic, if, test and [, case, while, for, functions and parameters, with a script debugger and a script lab that runs bash in the page.",
    title_html="Shell scripting, step by step:<br><span>everything is a command line.</span>",
    lead="Command lines saved in a file, and the bits of programming bash added on top of them: variables, conditions, loops and functions. Every script runs in a debugger, line by line, the way the slides show it.",
    features="script debugger · script lab with missions · IFS and pattern simulators",
    starth="Start with shell scripts.",
    maphead="From a file of commands to functions and parameters.",
    how="Text, figures and the simulators were generated with Claude (Anthropic) from the slides of lecture 08 – Shell Scripting, following the structure of the interactive lectures 02, 03 and 07. The debuggers are the step-by-step runs of the slides; the script lab runs scripts in a small bash interpreter written for this page.",
    checked="The interpreter of the script lab was tested on every script and terminal session of the slides (outputs, exit codes, error messages, IFS splitting, read, $(...), $(( )), bc, expr, test and [, case, loops, functions, \"$@\"). It is a teaching model, not bash: only the commands of the lecture exist, and there are no real processes.",
)

if __name__ == "__main__":
    render(COURSE, META, OUT, js=["dev.js", "bashrun.js", "widgets08.js"], css=CSS)
