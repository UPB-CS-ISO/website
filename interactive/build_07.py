#!/usr/bin/env python3
"""Build the interactive page of lecture 07 (Software Development).

    python3 interactive/build_07.py
writes website/static/courses/07-software-development/index.html
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa
from page import F, Course, flash as flash_cards, render, REPO
import page as _page

OUT = os.path.join(REPO, "website/static/courses/07-software-development/index.html")
COURSE = Course()
chapter = COURSE.chapter


def img(path, alt, width=900):
    return _page.img("slides/src/07_software_development/img", path, alt, width)


def src(text, name=None, lang=None):
    """a source file (C, Makefile, JSON), with its name above, syntax highlighted"""
    head = f'<div class="srch">{E(name)}</div>' if name else ""
    if lang is None:
        n = (name or "").split()[0] if name else ""
        lang = "make" if "Makefile" in (name or "") else "json" if n.endswith(".json") else "c"
    return f'<div class="srcb">{head}<pre>{hl(text.strip(chr(10)), lang)}</pre></div>'


HELLO = r"""#include <stdio.h>

#define TIMES 3

int main(void)
{
    // say hello a few times
    for (int i = 0; i < TIMES; i++) {
        printf("Hello, %d!\n", i);
    }
    return 0;
}"""
MAIN_C = """#include "lib.h"
#include "print.h"

int main(void)
{
    int total = sum(MAX);
    print_result("sum", total);
    return 0;
}"""
LIB_H = """#ifndef LIB_H
#define LIB_H
#define MAX 10
int sum(int n);
#endif"""
LIB_C = """#include "lib.h"

int sum(int n)
{
    int s = 0;
    for (int i = 1; i <= n; i++) {
        s = s + i;
    }
    return s;
}"""
PRINT_H = """#ifndef PRINT_H
#define PRINT_H
void print_result(const char *label,
                  int value);
#endif"""
PRINT_C = r"""#include <stdio.h>
#include "print.h"

void print_result(const char *label,
                  int value)
{
    printf("%s = %d\n", label, value);
}"""

def mterm(variant, cwd, missions, cmds, title, sub=None, side=None):
    """the demo terminal with the files of lecture 07 (~/hello, ~/project with a Makefile variant, or a git repository)"""
    extra = (f' data-sub="{E(sub)}"' if sub else "") + (f' data-side="{side}"' if side else "")
    return (f'<div data-w="shell" data-profile="07" data-variant="{variant}" data-cwd="{E(cwd)}" data-missions="{missions}"'
            f' data-cmds="{E("|".join(cmds))}" data-title="{E(title)}"{extra}></div>')


TAB = chr(9)
MKH = f"""hello: hello.o
{TAB}gcc hello.o -o hello

hello.o: hello.c
{TAB}gcc -c hello.c"""
MK_LONG = f"""app: main.o lib.o print.o
{TAB}gcc main.o lib.o print.o -o app

main.o: main.c
{TAB}gcc -c main.c

lib.o: lib.c
{TAB}gcc -c lib.c

print.o: print.c
{TAB}gcc -c print.c"""
MK_AUTO = f"""app: main.o lib.o print.o
{TAB}gcc $^ -o $@

main.o: main.c
{TAB}gcc -c $< -o $@

lib.o: lib.c
{TAB}gcc -c $< -o $@

print.o: print.c
{TAB}gcc -c $< -o $@"""
MK_PAT = f"""app: main.o lib.o print.o
{TAB}gcc $^ -o $@

%.o: %.c
{TAB}gcc -c $< -o $@"""
MK_SHORT = f"""CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o
{TAB}$(CC) $^ -o $@

%.o: %.c
{TAB}$(CC) $(CFLAGS) -c $< -o $@"""
MK_PHONY = f"""CC = gcc
CFLAGS = -Wall -g

.PHONY: all build run clean

all: build

build: app

run: build
{TAB}./app

app: main.o lib.o print.o
{TAB}$(CC) $^ -o $@

%.o: %.c
{TAB}$(CC) $(CFLAGS) -c $< -o $@

clean:
{TAB}rm -f *.o app"""
MK_MMD = f"""CC = gcc
CFLAGS = -Wall -g -MMD
OBJS = main.o lib.o print.o

app: $(OBJS)
{TAB}$(CC) $^ -o $@

%.o: %.c
{TAB}$(CC) $(CFLAGS) -c $< -o $@

-include $(OBJS:.o=.d)"""

ERRS = [('pp', '1 · preprocessor', 'main.c:1:10: fatal error: lib.h: No such file or directory', 'The `#include`d file is not found: a wrong name, or a folder missing (`-I dir`).'), ('cc', '2 · compiler', "main.c:6:17: error: implicit declaration of function 'sum' [-Wimplicit-function-declaration]", '`sum` is used, but nothing declared it: the `#include "lib.h"` is missing. (An error since GCC 14.)'), ('ld', '4 · linker', "/usr/bin/ld: main.o: in function `main':\nmain.c:(.text+0x13): undefined reference to `sum'", 'Every file compiled, but no object file **defines** `sum`: `lib.o` is missing from the command.'), ('ld', '4 · linker', "/usr/bin/ld: calc.o: in function `main':\ncalc.c:(.text+0x2a): undefined reference to `sqrt'", 'The function is in a library that is not linked: add `-lm` (the math library).')]


def errcards():
    return '<div class="errs">' + ''.join(
        f'<div class="errc {k}"><span class="est">{st}</span><pre>{E(m)}</pre><p>{md(w)}</p></div>' for k, st, m, w in ERRS) + '</div>'


ERRCARDS_HTML = errcards()

# ---------------------------------------------------------------- 01 languages
def lrow(kind, langs, src_, before, after, cls):
    """one row of the map: who translates, before or while the program runs"""
    return (f'<div class="lm-row {cls}"><div class="lm-k"><b>{kind}</b><span>{langs}</span></div>'
            f'<div class="lm-src"><code>{src_}</code></div><div class="lm-z lm-b">{before}</div><div class="lm-go" aria-hidden="true"></div>'
            f'<div class="lm-z lm-w">{after}</div></div>')


LMAP = ('<figure class="lmap"><div class="lm-row lm-head"><div></div><div>you write</div><div>before it runs</div><div class="lm-go">▶ run</div><div>every time it runs</div></div>'
        + lrow("Compiled", "C, C++, Rust, Go", "hello.c",
               '<span class="lm-t"><code>gcc</code> compiler</span><span class="lm-a">→</span><span class="lm-f mc"><code>hello</code> machine code</span>',
               '<span class="lm-cpu">the CPU runs it directly</span>', "c")
        + lrow("Bytecode + VM", "Java, C#, Python, JavaScript", "Hello.java",
               '<span class="lm-t"><code>javac</code></span><span class="lm-a">→</span><span class="lm-f bc"><code>.class</code> bytecode</span>',
               '<span class="lm-t"><code>java</code> VM + JIT</span><span class="lm-a">→</span><span class="lm-cpu">CPU</span>', "v")
        + lrow("Interpreted", "bash, sh", "hello.sh", '<span class="lm-none">nothing</span>',
               '<span class="lm-t"><code>bash</code>, line by line</span><span class="lm-a">→</span><span class="lm-cpu">CPU</span>', "i")
        + '<figcaption>A compiler is a translator who translates the whole book once, before anyone reads it. An interpreter translates sentence by sentence, every time someone reads it.</figcaption></figure>')

page = chapter("languages", "Compiled and interpreted", "Who turns the source into machine code, and when", 18)
page("machine", "Machine code", "What the CPU runs", F(r"""
{why("The processor only runs machine code. When your source is translated (before it runs, or while it runs) decides how fast the program is, when you see its mistakes, and what you give to the people who use it.")}
<div class="duo top"><div>
{src('''for (int i = 0; i < 3; i++) {
    printf("Hello, %d!\\n", i);
}''', "what you write: source code, text")}
</div><div>
<div class="srcb"><div class="srch">what the CPU runs: machine code, bytes (x86-64)</div><pre>c7 45 fc 00 00 00 00   <span class="hl-c"># i = 0</span>
eb 1d                  <span class="hl-c"># jump to the test</span>
...
e8 00 00 00 00         <span class="hl-c"># call printf</span>
83 45 fc 01            <span class="hl-c"># i++</span>
83 7d fc 02            <span class="hl-c"># i &lt;= 2 ?</span>
7e dd                  <span class="hl-c"># if yes, jump back</span></pre></div>
</div></div>
{ul("every processor family has its own *instruction set*: these bytes mean nothing to an ARM64 or a RISC-V CPU", "so the source must be **translated** to the machine code of this CPU: *who* does it, and *when*?")}
<h2>Three answers</h2>
{LMAP}
<div class="duo top"><div>
{sh('''$ gcc hello.c -o hello  # once
$ ./hello  # as many times as you want
Hello, 0!
$ file hello
hello: ELF 64-bit LSB pie executable, x86-64''')}
<p class="small">The executable is machine code: it runs without <code>gcc</code>, but only on x86-64 Linux.</p>
</div><div>
{sh('''$ bash hello.sh  # read again, every time
Hello, 0!
$ file hello.sh /bin/bash
hello.sh:  Bourne-Again shell script, ASCII text
/bin/bash: ELF 64-bit LSB pie executable, x86-64''')}
<p class="small">The script is only text: the CPU runs <code>bash</code>, and <code>bash</code> does what the script says.</p>
</div></div>
"""))
page("errors", "When is the mistake found?", "Try it", F(r"""
<p class="txt">The clearest difference shows up when the code has a mistake. A compiler reads <b>all</b> of the file before anything runs; an interpreter finds a mistake only when it reaches that line.</p>
<div data-w="langs"></div>
{table(["Line 3 has", "C (`gcc`)", "Python (`python3`)", "bash"], [
    ("a typo (`)`)", "error, **nothing** runs", "`SyntaxError`, **nothing** runs", "lines 1, 2 run, then the error"),
    ("a misspelled name", "error, **nothing** runs", "lines 1, 2 run, then `NameError`", "lines 1, 2 run, an error, **then line 4**"),
    ("a change, not rebuilt", "runs the **old** code", "runs the new code", "runs the new code")], "k")}
{note("Why it matters", "A compiled program cannot crash on a typo: it would not have been built. A script can stop halfway, after it has already done part of its work (deleted some files, written half a report). Test every branch of a script, not only the first lines.", "warn")}
"""))
page("interpreted", "Bytecode and virtual machines", "The middle way", F(r"""
<div class="duo top"><div>
{ul("`javac` compiles **once**, to *bytecode*: machine code for an imaginary CPU", "the **virtual machine** (`java`) runs the bytecode on any OS and CPU it is installed on: *write once, run anywhere*", "**JIT** (*just in time*): the VM watches which code runs often and compiles it to real machine code, while the program runs")}
</div><div>
{sh('''$ javac Hello.java
$ file Hello.class
Hello.class: compiled Java class data
$ java Hello
Hello, 0!''')}
</div></div>
<h2>Python and JavaScript are compiled too</h2>
<div class="duo top"><div>
{ul("you run the source, `python3 total.py`, but `python3` first compiles **all** of the file to bytecode, then its VM runs it", "that is why a `SyntaxError` anywhere stops the script before its first line runs", "the bytecode of imported modules is kept in `__pycache__/`, so the next run starts faster", "`node`, `deno` and Chrome share the V8 engine, which JIT-compiles the code that runs often")}
</div><div>
{sh('''$ cat total.py
total = total + i
$ python3 -m dis total.py  # the bytecode
  LOAD_NAME     0 (total)
  LOAD_NAME     1 (i)
  BINARY_OP     0 (+)
  STORE_NAME    0 (total)''')}
</div></div>
<p class="txt">Only shells really read and run one command at a time.</p>
"""))
page("big-picture", "Compiled vs. interpreted", "The big picture", F(r"""
{table(["", "**Compiled** (C, C++, Rust, Go)", "**Bytecode + VM** (Java, C#, Python, JavaScript)", "**Interpreted** (bash, sh)"], [
    ("translated", "once, before it runs", "to bytecode, then by the VM (and the JIT)", "every time, line by line"),
    ("speed", "fast", "slower; the JIT helps", "slow"),
    ("mistakes found", "syntax, types, names: before it runs", "syntax before it runs, the rest when the line runs", "when the line runs"),
    ("you changed the code", "compile again, then run", "run it", "run it"),
    ("another CPU or OS", "compile again for it", "runs where the VM is installed", "runs where the interpreter is"),
    ("you give users", "the executable", "the bytecode or the source", "the source")])}
{note("A language is not compiled or interpreted", "The program that runs it is: C can be compiled by `gcc` or interpreted by `picoc`; Python can be run by `python3` (bytecode) or compiled to an executable by `nuitka`.", "blue")}
{quiz("You change one line of a C program and run `./app`. What happens?", ["it runs the new line: `./app` reads the source", "it runs the old code, until you compile again", "it fails: the source is newer", "the terminal asks you to compile"], 1,
      "The executable is the machine code made from the **old** source. Compile again (or run `make`) to get the change.")}
{quiz("A Python script prints two lines, then stops with `NameError` on line 3. Was line 3 compiled?", ["no, Python never compiles", "yes: the whole file was compiled to bytecode before line 1 ran; the name is looked up only when line 3 runs", "only line 3 was compiled", "no, a `NameError` is found by the compiler"], 1,
      "The compiler checked the **syntax** of the whole file (a typo would have stopped it at once). Whether `prnt` exists is only checked when that line runs.")}
"""))

# ---------------------------------------------------------------- 02 IDE
page = chapter("ide", "IDEs", "All the tools in one application", 8)
page("ide", "What is an IDE?", "Integrated Development Environment", F(r"""
{why("An IDE puts the editor, the build, the debugger and `git` in one window. Knowing which part does what lets you use any of them, or build the same setup from a plain editor.")}
<div class="duo top"><div>
{table(["Part", "What it does"], [
    ("build", "runs the compiler or `make`, shows the errors in the code"), ("run", "one key, the output in a panel"),
    ("code intelligence", "the type of a variable, where a function is defined, completion, refactoring"),
    ("debugger", "stop on a line, look at the variables"), ("project", "the files of the program and how to build them"),
    ("version control", "the changes, commit, push, inside the IDE")])}
</div><div>{fig(img("book/xcode-interface.png", "Xcode", 700), "Xcode: the editor in the middle, the project on the left, the debugger below")}</div></div>
{table(["", "Text editor", "IDE"], [
    ("understands", "text", "the language and the project"), ("languages", "any", "one or a few"),
    ("build, run, debug", "in a terminal", "buttons and panels"), ("resources", "small, starts at once", "large, slow to start"),
    ("examples", "`vim`, `nano`, `emacs`, `helix`", "Visual Studio, IntelliJ IDEA, CLion, Xcode, Eclipse, Qt Creator, Code::Blocks")])}
{note("An editor + plugins = an IDE", "How? With *language servers* and *debug adapters*: the next chapters.", "blue")}
"""))

# ---------------------------------------------------------------- 03 LSP
page = chapter("lsp", "Language servers", "One program that understands a language, for every editor", 10)
page("lsp", "The Language Server Protocol", "LSP", F(r"""
<div class="duo top"><div>
<h3>The problem</h3>
{ul("to understand C, an editor must parse it, follow the `#include`s and know the types: the work of a compiler", "5 editors × 5 languages = **25** plugins, each with its own C parser", "with one protocol, 5 + 5 = **10** programs: every editor talks to every server")}
{note("LSP (Microsoft, 2016)", "The editor asks, the **language server** answers: `clangd` for C/C++, `rust-analyzer`, `pyright`, `gopls` ...", "blue")}
</div><div>
<h3>How it starts</h3>
{steps("you run `hx main.c`", "the editor sees a C file and **starts** `clangd`: `fork` + `exec`, a *child process*", "two **pipes** connect them: the code and questions to its `stdin`, answers and errors from its `stdout`", "you type, the editor sends the changes and shows the answers", "`clangd` crashes? the editor keeps working")}
</div></div>
<h2>A conversation</h2>
<p class="txt">Three kinds of messages, all JSON: a <b>notification</b> (no answer: <i>I opened main.c</i>), a <b>request</b> with an <code>id</code> (<i>what is under the cursor?</i>) and the <b>response</b> with the same <code>id</code>.</p>
<div data-w="lsp"></div>
<div class="duo top"><div>{fig(img("editors/helix_hover.png", "hover in helix", 700), "**hover**: the type of `sum` and the header it comes from")}</div><div>{fig(img("editors/helix_complete.png", "completion in helix", 700), "**completion**: the server knows every file of the project")}</div></div>
<p class="small">Also from the server: the errors while you type (<em>diagnostics</em>), <em>go to definition</em>, <em>rename</em> in every file.</p>
"""))

# ---------------------------------------------------------------- 04 debuggers
page = chapter("debug", "Debuggers", "Stop the program and look inside", 12)
page("gdb", "What is a debugger?", "Instead of printf", F(r"""
{why("`printf` shows what you guessed to print. A debugger stops the program where you want and shows everything: variables, the call stack, memory. Most bugs are found faster this way.")}
<div class="duo top"><div>
{ul("**breakpoints**: stop at a line or a function", "**step**: run one line at a time", "**inspect**: variables, memory, the call stack", "**watchpoints**: stop when a variable changes", "**change** a variable and continue")}
<p class="small">Debuggers: <code>gdb</code> (GNU), <code>lldb</code> (LLVM), the Visual Studio debugger.</p>
<h3>How it works</h3>
{steps("`gdb` starts the program itself: `fork` + `exec`, `app` is its *child*, stopped before its first instruction", "the `ptrace` system call: `gdb` asks the kernel to read and write the memory and registers of `app`, to stop and continue it", "`app` reaches the breakpoint: the kernel stops it and tells `gdb`")}
</div><div>
{sh('''$ gdb -q ./app
Reading symbols from ./app...
(gdb) break sum
Breakpoint 1 at 0x1188: file lib.c, line 3.
(gdb) run
Breakpoint 1, sum (n=10) at lib.c:3
3           int s = 0;
(gdb) print n
$1 = 10
(gdb) next
4           for (int i = 1; i <= n; i++) {''')}
<p class="small"><code>gdb -tui</code> (or <kbd>Ctrl</kbd>+<kbd>X</kbd> <kbd>A</kbd>) shows the source above the commands: <code>B+</code> a breakpoint, <code>&gt;</code> the next line to run.</p>
</div></div>
{bad("Debugging a program built without `-g`", "Without *debug information* the executable is only machine code: `gdb` cannot show lines or variable names.", "compile with `gcc -g` (a *debug* build); a *release* build usually leaves it out. Rust (`cargo build`), Go and `javac -g` add it too.")}
"""))

# ---------------------------------------------------------------- 05 DAP
page = chapter("dap", "Debug adapters", "One program that drives a debugger, for every editor", 8)
page("dap", "The Debug Adapter Protocol", "DAP", F(r"""
<div class="duo top"><div>
{ul("the same problem as LSP: every debugger has its own commands (`break` in `gdb`, `breakpoint set` in `lldb`)", "**DAP** (Microsoft, 2016): the editor asks, the **debug adapter** answers", "the editor starts the adapter (e.g. `lldb-dap`), two pipes connect them, as for LSP", "the adapter starts `app` and controls it with `ptrace`, like `gdb`")}
</div><div>{fig(img("gui/vscodium_debug.png", "Debugging in VSCodium", 700), "VSCodium: the breakpoint, the stopped line, the variables and the call stack, all from DAP")}</div></div>
<div data-w="dap"></div>
{table(["Language", "Debug adapter"], [("C, C++, Rust", "`lldb-dap`, CodeLLDB, `gdb -i=dap` (gdb 14+)"), ("Python", "`debugpy`"), ("Go", "`dlv dap` (Delve)"), ("JavaScript, TypeScript", "`js-debug`")])}
"""))

# ---------------------------------------------------------------- 06 compiling
page = chapter("compile", "The C compilation pipeline", "Preprocessor, compiler, assembler, linker", 18)
page("pipeline", "From hello.c to an executable", "Four steps", F(r"""
{why("Every build error comes from one of the four steps: a missing header from the preprocessor, a type error from the compiler, an *undefined reference* from the linker. Know the step, and the message makes sense.")}
<div data-w="pipe"></div>
<h2>Stop after any step</h2>
{table(["Stop after", "Command", "You get", "Look at it with"], [
    ("1. preprocessor", "`gcc -E hello.c -o hello.i`", "`hello.i`, C text", "`wc -l`, `tail`"), ("2. compiler", "`gcc -S hello.c`", "`hello.s`, assembly", "`cat`"),
    ("3. assembler", "`gcc -c hello.c`", "`hello.o`, an object file", "`nm`, `objdump -d`, `file`"), ("4. linker", "`gcc hello.o -o hello`", "`hello`, the executable", "`file`, `ldd`, `./hello`")], "k")}
<p class="small"><code>gcc -save-temps hello.c -o hello</code> keeps all of them: <code>hello.i</code>, <code>hello.s</code>, <code>hello.o</code>.</p>
{mterm("long", "~/hello", "cc-pipe", ["cat hello.c", "gcc -E hello.c -o hello.i", "tail hello.i", "gcc -S hello.c", "gcc -c hello.c", "nm hello.o"], "Build hello.c step by step")}
"""))
page("libraries", "Libraries", "Static and shared", F(r"""
<p class="txt">A <b>library</b> is a file of compiled functions, ready for other programs: <code>printf</code> is in the C library, <code>sqrt</code> in the math library. The two kinds differ in <b>when</b> the code of the library joins the program: when it is <b>linked</b> (static) or every time it <b>starts</b> (shared).</p>
<figure class="libpic"><div class="lpc"><div class="lph">Static library <code>libsum.a</code></div>
<div class="lps"><span class="lst">1. build the library</span><div class="lpr"><span class="lb o"><code>lib.o</code><i>sum</i></span><span class="lt">ar rcs</span><span class="lb a"><code>libsum.a</code><i>an archive of .o files</i></span></div></div>
<div class="lps"><span class="lst">2. link the program</span><div class="lpr"><span class="lb o"><code>main.o</code><i>U sum</i></span><span class="lt">gcc -L. -lsum</span><span class="lb x"><code>app</code><i>main + <b>sum, copied in</b></i></span></div></div>
<div class="lps"><span class="lst">3. run</span><div class="lpr"><span class="lb x"><code>app</code><i>has everything</i></span><span class="lt n">needs nothing else</span></div></div>
<p>a new <code>libsum.a</code> reaches <code>app</code> only through a new link</p></div>
<div class="lpc"><div class="lph">Shared library <code>libsum.so</code></div>
<div class="lps"><span class="lst">1. build the library</span><div class="lpr"><span class="lb o"><code>lib.o</code><i>sum, -fPIC</i></span><span class="lt">gcc -shared</span><span class="lb s"><code>libsum.so</code><i>a separate file</i></span></div></div>
<div class="lps"><span class="lst">2. link the program</span><div class="lpr"><span class="lb o"><code>main.o</code><i>U sum</i></span><span class="lt">gcc -L. -lsum</span><span class="lb x"><code>app</code><i>main + <b>needs libsum.so</b></i></span></div></div>
<div class="lps"><span class="lst">3. run, every time</span><div class="lpr"><span class="lb x"><code>app</code><i>main</i></span><span class="lt">the loader opens</span><span class="lb s"><code>libsum.so</code><i>one copy for all</i></span></div></div>
<p>a new <code>libsum.so</code> changes <code>app</code> at its next start</p></div></figure>
<div data-w="libs"></div>
{table(["", "**Static** (`libNAME.a`)", "**Shared** (`libNAME.so`, the default)"], [
    ("the linker", "**copies** the functions into the executable", "only writes down that the executable needs the library"),
    ("when the program starts", "nothing to load", "the **loader** (`ld-linux-x86-64.so.2`) finds and loads the `.so`"),
    ("a new version of the library", "link every program again", "every program uses it at its next start"),
    ("the library is not installed", "the program still runs", "*error while loading shared libraries*"),
    ("size", "every program has its own copy (`hello-static`: 636K)", "one copy for all (`hello`: 12K)")])}
<h2>The commands</h2>
{table(["Command", "What it does"], [
    ("`ar rcs libsum.a lib.o`", "a static library from `lib.o`; `ar t libsum.a` lists what is inside"),
    ("`gcc -fPIC -c lib.c`, then `gcc -shared lib.o -o libsum.so`", "a shared library (`-fPIC`: code that works at any address)"),
    ("`gcc main.o print.o -L. -lsum -o app`", "link with `libsum`: `-L.` looks in this folder; `.so` is preferred to `.a`"),
    ("`ldd app`", "the shared libraries `app` needs, and where the loader finds them"),
    ("`LD_LIBRARY_PATH=. ./app`", "run `app`, and let the loader also look in `.`")], "k")}
{mterm("long", "~/project", "cc-libs", ["gcc -c main.c lib.c print.c", "ar t libsum.a", "file libsum.a libsum.so", "ldd app", "ls -l"], "Libraries")}
"""))
page("files", "Several files and build errors", "Compile once, link often", F(r"""
<div class="duo top"><div>
{sh('''$ gcc -c main.c
$ gcc -c lib.c
$ gcc -c print.c
$ gcc main.o lib.o print.o -o app
$ vim print.c  # edit
$ gcc -c print.c  # only this one
$ gcc main.o lib.o print.o -o app''')}
</div><div>
{ul("compile each `.c` to its own `.o`, then **link** them into `app`", "after a change, compile again **only** the file that changed, then link again", "in a big project this saves minutes on every build; remembering what changed is the job of `make`")}
</div></div>
<h2>Which step complains?</h2>
<p class="txt">The first words of the message tell the step: <code>file.c:line:column:</code> comes from the preprocessor or the compiler, <code>/usr/bin/ld:</code> from the linker.</p>
{ERRCARDS_HTML}
{mterm("long", "~/project", "cc-files", ["ls", "gcc -c main.c", "nm main.o", "gcc main.o lib.o print.o -o app", "./app", "file main.o app"], "Several files")}
{quiz("`gcc main.o print.o -o app` fails with `undefined reference to 'sum'`. Which step complains?", ["the preprocessor", "the compiler", "the assembler", "the linker"], 3,
      "Every object file compiled fine; only when joining them is `sum` nowhere to be found. Add `lib.o`.")}
"""))

# ---------------------------------------------------------------- 07 make
page = chapter("make", "Building with make", "Rules, how make runs them, the short Makefile", 36)
page("rules", "A Makefile", "Rules: target, prerequisites, recipe", F(r"""
{why("`make` runs only the commands that are needed, in the right order. Almost every C project (and these slides) is built with a `Makefile`; its mistakes, like a forgotten header, give programs that run with old code.")}
<div class="duo top"><div>
{src(MKH, "~/hello/Makefile")}
{ul("a `Makefile` is a list of **rules**, one for every file that is built", "**target**: the file to build, before the `:`", "**prerequisites**: the files it is built from, after the `:`", "**recipe**: the commands that build it, on the next lines, each starting with a **TAB**")}
</div><div>
{ul("`hello: hello.o`: `hello` is built from `hello.o`, by linking it", "`make` reads the `Makefile` of the current directory and builds the **first** target, here `hello`; `make hello.o` builds only that one", "it compares the **modification times** of the files (`ls -l`) and runs a recipe only when the target is older than what it is built from")}
{bad("Spaces instead of a TAB", "`Makefile:2: *** missing separator.  Stop.`: the recipe line starts with spaces.", "set the editor to keep TABs in a `Makefile`.")}
</div></div>
<div data-w="makestep" data-p="hello"></div>
{mterm("hello", "~/hello", "mk-hello", ["cat Makefile", "make", "./hello", "touch hello.c", "ls -l"], "make in ~/hello", "You are in <code>~/hello</code>, with <code>hello.c</code> and the <code>Makefile</code> above. <code>pico hello.c</code> edits a file: <kbd>Ctrl</kbd>+<kbd>O</kbd> saves, <kbd>Ctrl</kbd>+<kbd>X</kbd> exits.")}
"""))
page("run", "How make runs the targets", "Step by step", F(r"""
<div class="duo top"><div>
<p class="txt">The project: <code>main.c</code> calls <code>sum</code> from <code>lib.c</code> and <code>print_result</code> from <code>print.c</code>. Each <code>.c</code> is compiled to its own <code>.o</code>, and the three <code>.o</code> files are linked into <code>app</code>.</p>
{steps("start from the goal: the first target (`app`), or the one you name (`make lib.o`)",
       "make **every prerequisite first**, the same way: the stack of targets grows",
       "a prerequisite with no rule must exist as a file, else *No rule to make target*",
       "run the recipe only if the target is **missing** or **older** than a prerequisite",
       "a command fails? `make` stops: *Error 1*")}
</div><div>
{src(MK_LONG, "~/project/Makefile")}
</div></div>
<div data-w="makestep" data-p="project"></div>
{note("make reads only the times", "It never looks inside the files: `touch` (a new modification time) is enough to rebuild. `make --debug=v` prints every decision: *Considering target file ...*, *Prerequisite 'print.c' is newer than target 'print.o'*, *Must remake target ...*.", "blue")}
{mterm("long", "~/project", "mk-run", ["make", "make", "touch print.c", "make --debug=v", "ls -l"], "make in ~/project")}
"""))
page("short", "A shorter Makefile", "From four rules to `%.o: %.c`", F(r"""
<p class="txt">The three <code>.o</code> rules are the same, only the names change. Three steps make the <code>Makefile</code> shorter; <code>make</code> runs exactly the same commands.</p>
<h3>1. Automatic variables: <code>$@</code>, <code>$&lt;</code>, <code>$^</code></h3>
<div class="duo top"><div>{src(MK_AUTO, "Makefile")}</div><div>
{ul("in a recipe, `$@` is the **target**, `$<` the **first prerequisite**, `$^` **all** the prerequisites", "`make` fills them in for each rule, before it runs the command: `gcc -c $< -o $@` becomes `gcc -c main.c -o main.o`", "now the three `.o` rules have the same recipe")}
</div></div>
{table(["", "Means", "In `main.o: main.c`", "In `app: main.o lib.o print.o`"], [
    ("`$@`", "the target", "`main.o`", "`app`"), ("`$<`", "the first prerequisite", "`main.c`", "`main.o`"), ("`$^`", "all the prerequisites", "`main.c`", "`main.o lib.o print.o`")])}
<h3>2. A pattern rule: <code>%.o: %.c</code></h3>
<div class="duo top"><div>{src(MK_PAT, "Makefile")}</div><div>
{ul("`%` matches any name: `%.o: %.c` says *any `.o` is built from the `.c` with the same name*", "to make `lib.o`, `make` finds no rule named `lib.o`, tries the pattern with `%` = `lib`, and checks that `lib.c` exists", "the recipe is the same for all of them, thanks to `$<` and `$@`", "a new `util.c`? add `util.o` to `app`, nothing else")}
</div></div>
<h3>3. Variables: <code>CC</code> and <code>CFLAGS</code></h3>
<div class="duo top"><div>{src(MK_SHORT, "~/project/Makefile")}</div><div>
{ul("`NAME = value` defines a variable, `$(NAME)` uses it", "`CC`: the compiler, `CFLAGS`: its options (`-Wall` all warnings, `-g` debug information)", "change the compiler or the options in **one** place", "`make` prints the commands *after* filling in the variables: `gcc -Wall -g -c main.c -o main.o`")}
{note("The Makefile is not a prerequisite", "Change `CFLAGS` and `make` says *up to date*: the `.o` files are newer than the `.c` files. `make -B` (or `make clean`, then `make`) rebuilds everything with the new options.", "warn")}
</div></div>
{mterm("short", "~/project", "mk-short", ["cat Makefile", "make", "touch lib.c", "make", "make -B"], "The short Makefile")}
"""))
page("phony", "Special targets", "`clean`, `all`, `run`, `.PHONY`", F(r"""
<div class="duo top"><div>
{src(MK_PHONY, "~/project/Makefile")}
</div><div>
{ul("`clean`, `all`, `build`, `run` are targets that are **not files**", "`all: build` and `build: app` have no recipe: they only name what to build", "`run: build` first builds, then runs `./app`", "if a file named `clean` existed, `make clean` would say *up to date* and **delete nothing**", "`.PHONY` tells `make` they are not files: their recipe always runs", "`all`, `clean`, `install`, `check` are GNU conventions")}
<p class="small"><code>make clean &amp;&amp; make</code> builds everything from scratch, like <code>make -B</code>.</p>
</div></div>
{mterm("phony", "~/project", "mk-phony", ["make run", "make clean", "ls", "touch clean", "make clean"], "Phony targets")}
"""))
page("headers", "Header dependencies", "Where do the .h files go?", F(r"""
<div class="duo top"><div>
{tree('''app
├── main.o
│   ├── main.c
│   ├── lib.h
│   └── print.h
├── lib.o
│   ├── lib.c
│   └── lib.h
└── print.o
    ├── print.c
    └── print.h''', here=(4, 5, 8, 11))}
</div><div>
{ul("`main.o` is built from `main.c` **and** from the two headers it `#include`s", "`lib.h` is needed by **two** object files: `main.o` and `lib.o`", "the short `Makefile` lists only the `.c` files: change `MAX` in `lib.h`, and `make` says *up to date*: `app` still prints 55, not 5050")}
{src(MAIN_C, "main.c")}
</div></div>
{bad("`lib.h` on `app`", "`app: main.o lib.o print.o lib.h` only links again: `main.o` keeps the old `MAX`, still 55 (and `gcc` gets `lib.h` in `$^`).", "a header goes on the rule of every `.o` whose `.c` includes it, never on the executable.")}
{src('''main.o: lib.h print.h
lib.o: lib.h
print.o: print.h''', "the fix: add these lines to the Makefile")}
{mterm("headers", "~/project", "mk-headers", ["make", "cat lib.h", "pico lib.h", "./app"], "The header bug")}
<div class="duo top"><div>
<h3>Bonus: automatic dependencies</h3>
{src(MK_MMD, "Makefile")}
</div><div>
{sh('''$ cat main.d lib.d print.d
main.o: main.c lib.h print.h
lib.o: lib.c lib.h
print.o: print.c print.h''')}
<p class="small"><code>-MMD</code>: <code>gcc</code> writes the headers each file includes into a <code>.d</code> file, and the <code>Makefile</code> includes them. (Not in the demo terminal.)</p>
</div></div>
<h2>The same bug, in pictures</h2>
<p class="txt">Pick a <code>Makefile</code>, change <code>lib.h</code> and run <code>make</code>: the boxes show which files are rebuilt and with which <code>MAX</code>.</p>
<div data-w="make" data-mk="none"></div>
"""))

# ---------------------------------------------------------------- 08 git
page = chapter("git", "Version control with Git", "Commits, commit vs. push, branches", 18)
page("git", "What is Git?", "Save points for your code", F(r"""
{why("Every lab and homework is handed in through a Git repository, and every software team works with one. Git keeps every version, shows who changed what, and lets several people change the same code.")}
<div class="duo top"><div>
{ul("a **version control system**: keeps the *history* of the files", "go back to any version, see **who** changed **what** and **why**", "**distributed**: every copy has the whole history", "written in 2005 by Linus Torvalds, for Linux", "the folder with the files and their history is a **repository** (*repo*)")}
</div><div>
{ul("a **commit** is a snapshot of the files, with a message and an author: a save point, like in a game", "every commit points to its **parent**: the chain is the *history* (`git log --oneline`)", "a **branch** is a name for a commit that moves forward with every new commit; `HEAD` is the branch you are on")}
</div></div>
<h2>Four places</h2>
{table(["Place", "What is there", "Command that moves a change to the next place"], [
    ("working directory", "the files you edit", "`git add` picks what goes in the commit"),
    ("staging area", "the next commit", "`git commit` saves it in the local repository"),
    ("local repository", "the history, on **your computer**", "`git push` sends it to the remote"),
    ("remote repository", "GitHub, GitLab ..., **shared**", "`git pull` brings the others' commits")])}
{note("Commit is not push", "`git commit` saves only on your computer: your colleagues (and your teacher) do not see it. `git status` says *Your branch is ahead of 'origin/main' by 1 commit* until you `git push`.", "warn")}
"""))
page("try", "Git in a terminal", "Try it", F(r"""
<p class="txt">A clone of a project from GitHub, in <code>~/project</code>. Type the <code>git</code> commands; the panel next to the terminal shows where your changes are and how the history grows. Follow the missions below the terminal.</p>
{mterm("git", "~/project", "git", ["git status", "git diff", "git add main.c", 'git commit -m "Print the total"', "git push", "git pull", "git log --oneline --graph --all", "git switch -c feature"], "git, step by step", "A terminal simulated in this page, with a small model of git and of GitHub. <code>pico main.c</code> edits a file; <b>👤 A colleague pushes</b> plays your teammate; <code>reset</code> starts again.", side="git")}
"""))
page("commands", "A few commands", "Git cheat sheet", F(r"""
{table(["Command", "What it does"], [
    ("`git clone <url>`", "copy a remote repository"), ("`git init`", "a new repository, here"), ("`git status`", "what changed, what to do next"),
    ("`git add <file>`", "stage a change"), ("`git commit -m \"...\"`", "save a snapshot"), ("`git push`", "send the commits"), ("`git pull`", "get the others' commits"),
    ("`git log --oneline`", "the history"), ("`git diff`", "the changes not staged yet"), ("`git branch`", "list the branches"),
    ("`git switch -c <name>`", "a new branch, go to it"), ("`git switch <name>`", "go to a branch"), ("`git merge <name>`", "merge it into this branch")], "k")}
{quiz("You committed your homework but the teacher does not see it. What is missing?", ["`git add`", "`git push`", "`git pull`", "`git merge`"], 1,
      "A commit lives in your local repository; `git push` sends it to the remote, where others can see it.")}
"""))

# ---------------------------------------------------------------- 09 editor to IDE
page = chapter("editor", "From an editor to an IDE", "LSP + DAP + tasks + git", 10)
page("setup", "Editor + plugins = IDE", "Configure the project", F(r"""
<div class="duo top"><div>
{ul("the **language server** understands the code, the editor asks it through LSP", "the **debug adapter** drives the debugger, through DAP", "a **task** runs the build, the editor reads the errors from its output", "the editor runs `git` and shows the changes next to the code")}
{table(["Editor", "LSP", "DAP"], [("VSCodium / VS Code", "built in", "built in"), ("`helix`", "built in", "built in (experimental)"), ("`nvim`", "built in", "the `nvim-dap` plugin"), ("`vim`", "a plugin", "a plugin")])}
</div><div>
{src('''{
  "version": "2.0.0",
  "tasks": [{
    "label": "make",
    "type": "shell",
    "command": "make",
    "problemMatcher": ["$gcc"]
  }]
}''', ".vscode/tasks.json")}
{src('''{
  "version": "0.2.0",
  "configurations": [{
    "type": "lldb",
    "request": "launch",
    "name": "Debug app",
    "program": "${workspaceFolder}/app",
    "preLaunchTask": "make"
  }]
}''', ".vscode/launch.json")}
<p class="small"><kbd>F5</kbd>: the <code>make</code> task builds <code>app</code>, then the debugger starts it. <code>.vscode/</code> is a hidden folder in the root of the project: commit it, and everyone gets the same build and debug setup.</p>
</div></div>
{bad("Trusting every folder", "Opening a project can **run code**: the language server and tasks the folder's settings name, and for Rust, `rust-analyzer` builds the project and runs its `build.rs` as soon as the folder opens.", "open unknown code in *restricted mode* (do not trust the folder): you can read and edit it, nothing from it runs.")}
"""))

# ---------------------------------------------------------------- 10 flashcards
FLASH = [
    ("01", "Languages", "languages/machine", "The CPU runs only machine code", "Something must translate the source: a compiler before it runs, or an interpreter / VM while it runs."),
    ("01", "Languages", "languages/interpreted", "Python is compiled to bytecode too", "`python3` compiles the whole file first, so a syntax error anywhere stops it before the first line runs."),
    ("01", "Languages", "languages/big-picture", "After a change, a C program must be compiled again", "The executable is made from the old source: run `make`, then the program."),
    ("01", "Languages", "languages/errors", "A compiler finds a typo before anything runs", "An interpreter (`bash`) runs the lines before it first: a script can stop halfway."),
    ("02", "IDE", "ide/ide", "An IDE is an editor that knows the language and the project", "Build, run, debug and git in one window; an editor with LSP and DAP plugins does the same."),
    ("03", "LSP", "lsp/lsp", "The language server is a child process of the editor", "They talk through pipes; if `clangd` crashes, the editor keeps working."),
    ("04", "Debuggers", "debug/gdb", "Compile with `-g` to debug", "Without debug information the debugger has no lines and no variable names."),
    ("04", "Debuggers", "debug/gdb", "A breakpoint stops before the line runs", "At `Breakpoint 1 ... line 3`, line 3 has not run yet: `next` runs it."),
    ("05", "DAP", "dap/dap", "Every debugger button is one DAP request", "The editor does not know `gdb` or `lldb`: the adapter translates."),
    ("06", "Pipeline", "compile/pipeline", "`gcc` runs four programs", "Preprocessor, compiler, assembler, linker: each error message comes from one of them."),
    ("06", "Pipeline", "compile/files", "*undefined reference* is a linker error", "The code compiled; an object file or a library (`-lm`) is missing from the link."),
    ("06", "Libraries", "compile/libraries", "Shared libraries are found when the program starts", "`ldd` shows them; *not found* means the loader cannot find the `.so`."),
    ("07", "make", "make/run", "make compares times, not contents", "A target is rebuilt when it is missing or older than a prerequisite."),
    ("07", "make", "make/short", "`%.o: %.c` builds every object file", "With `$<` (the `.c`) and `$@` (the `.o`) one rule replaces one rule per file."),
    ("07", "make", "make/rules", "A recipe line starts with a TAB", "Spaces give *missing separator*."),
    ("07", "make", "make/phony", "`clean` and `run` go in `.PHONY`", "Otherwise a file named `clean` makes `make clean` do nothing."),
    ("07", "make", "make/headers", "A header goes on every `.o` that includes it", "Else `make` does not rebuild after a change in the header and the program runs with old values."),
    ("08", "Git", "git/git", "A commit is local until you push", "`git status` tells you when your branch is ahead of `origin/main`."),
    ("08", "Git", "git/try", "Pull before you push", "If a colleague pushed first, your push is rejected until you integrate their commits."),
    ("08", "Git", "git/git", "A branch is a name for a commit", "New commits move it forward; `git switch` changes the files in the folder."),
    ("09", "Editor", "editor/setup", "Commit `.vscode/` with the project", "Everyone gets the same build task and debug configuration."),
    ("09", "Editor", "editor/setup", "Opening a folder can run its code", "Trust only projects you know; use restricted mode for the others."),
]
page = chapter("flashcards", "Flashcards", "The ideas of the lecture, one card each", 10)
page("recap", "The ideas, in short", "Quick recap", F(r"""
<p class="txt">One idea per card; the title is the idea, the text says why it matters in practice. <em>Recap</em> shows all the cards, <em>Flashcard</em> one at a time.</p>
{flash_cards(FLASH)}
"""))

CSS = """
.srcb{border:1px solid var(--line);border-radius:10px;overflow:hidden;background:#f8fafb;margin:8px 0}
.srch{font:12px "SF Mono",Menlo,Consolas,monospace;color:var(--muted);background:#fff;border-bottom:1px solid var(--line);padding:5px 12px}
.srcb pre{margin:0;padding:10px 14px;font:13px/1.5 "SF Mono",Menlo,Consolas,"DejaVu Sans Mono",monospace;color:#1f2a2e;overflow-x:auto;tab-size:8}
.pg h2{margin-top:34px}

/* ---- the interactive parts: a teal frame and a label, they cannot be missed ---- */
.wd{container-type:inline-size;border:2px solid #00838f;border-radius:16px;box-shadow:0 0 0 5px #e3f2f3,0 14px 34px rgba(0,77,101,.08);margin:34px 0}
.wd-h{background:linear-gradient(100deg,#dcefF1,#eef6f7 70%);align-items:center}
.wd-h h3::before{content:"\\25B6  Interactive";display:block;width:max-content;font:800 10.5px/1 system-ui,sans-serif;letter-spacing:1.4px;text-transform:uppercase;color:#fff;background:#00838f;border-radius:999px;padding:5px 10px;margin-bottom:8px}
.wd-h p{color:#33555f}
.tryjump{display:inline-flex;align-items:center;gap:10px;margin:-6px 0 20px;padding:7px 16px 7px 7px;border:1.5px solid #00838f;border-radius:999px;background:#f0f8f9;color:#004d65;font-size:14px;text-align:left;max-width:100%}
.tryjump:hover{background:#dcefF1}
.tryjump b{color:#00838f}
.tryjump .tj-i{flex:0 0 26px;height:26px;border-radius:50%;background:#00838f;color:#fff;display:grid;place-items:center;font-size:10px}
.side .tri{font-style:normal;font-size:9px;color:#00838f;margin-left:auto;align-self:center;padding-left:6px}
.side li a.on .tri{color:#004d65}
.term .gr{color:#8ae234}.term .rd{color:#ef2929}.term .yl{color:#fce94f}
[data-w=shell]{margin-right:0!important}

/* ---- the demo terminal: its side panel goes next to it only when there is room for both ---- */
.wd .wd-b.sb{grid-template-columns:minmax(0,1fr)}
.wd .wd-b.sb>div+div{border-left:0;border-top:1px solid var(--line)}
.wd .wd-b.sb.ext .term{height:380px}
@container (min-width:840px){.wd .wd-b.sb{grid-template-columns:minmax(0,1fr) 300px}.wd .wd-b.sb>div+div{border-left:1px solid var(--line);border-top:0}}
@container (min-width:900px){.wd .wd-b.sb.ext{grid-template-columns:minmax(0,1fr) minmax(380px,.9fr)}.wd .wd-b.sb.ext .term{height:600px}}
@container (min-width:1150px){.wd .missions ol{grid-template-columns:1fr 1fr;column-gap:32px}}

/* ---- the C pipeline ---- */
.pflow{display:grid;grid-template-columns:minmax(0,.9fr) repeat(4,minmax(86px,1fr) minmax(0,.9fr));align-items:center;padding:24px 22px 12px}
.pcard{border:1.5px solid #b8cdd4;border-radius:12px;background:#fff;padding:12px 6px;display:flex;flex-direction:column;align-items:center;gap:3px;min-width:0;transition:box-shadow .15s,border-color .15s}
.pcard b{font:700 14px/1.2 "SF Mono",Menlo,Consolas,monospace;color:#004d65;overflow-wrap:anywhere;text-align:center}
.pcard span{font-size:11.5px;color:var(--muted);line-height:1.2;text-align:center}
.pcard.todo{border-style:dashed;background:#fafcfc}.pcard.todo b{color:#7d8d93}
.pcard.dn{background:#eef4f6}
.pcard.on{border-color:#e65100;background:#fff6ef;box-shadow:0 0 0 3px #fde5d4}.pcard.on b{color:#c2410c}
.pcard:hover,.parr:hover .pl{border-color:#00838f}
.parr{border:0;background:none;padding:0 4px;display:flex;flex-direction:column;align-items:stretch;gap:5px;min-width:0;text-align:center}
.parr .pt{font-size:11.5px;font-weight:700;color:#7d8d93;line-height:1.2}
.parr .pl{height:2px;background:#b8cdd4;position:relative;margin-right:8px}
.parr .pl::after{content:"";position:absolute;right:-8px;top:-5px;border-style:solid;border-width:6px 0 6px 9px;border-color:transparent transparent transparent #b8cdd4}
.parr code{font-size:11px;background:none;padding:0;color:#7d8d93}
.parr.dn .pt,.parr.dn code{color:#00838f}.parr.dn .pl{background:#00838f}.parr.dn .pl::after{border-left-color:#00838f}
.parr.on .pt,.parr.on code{color:#e65100}.parr.on .pl{background:#e65100;height:3px}.parr.on .pl::after{border-left-color:#e65100}
.pdrv{margin:0 22px;padding:8px 0 14px;font-size:12.5px;color:var(--muted);text-align:center;border-top:2px dotted #ccdbe0}
.pexp{display:flex;gap:18px;align-items:center;justify-content:space-between;padding:14px 22px;background:#fff6ef;border-top:1px solid #f6d6bd;border-bottom:1px solid #f6d6bd}
.pst{font-weight:700;font-size:15px;color:#c2410c;margin-bottom:2px}
.pexp p{font-size:15px;max-width:780px}
.pexp .seg{flex:0 0 auto}.pexp .seg[hidden]{display:none}
.ppanes{display:grid;grid-template-columns:minmax(0,1fr);gap:14px;padding:16px 22px}
.ppanes>div{min-width:0}
.ppf{font-size:12.5px;color:var(--muted);margin-bottom:6px}.ppf b{color:var(--navy);font-family:"SF Mono",Menlo,monospace}
.ppcode{min-height:200px}
.pnav{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:12px 22px;border-top:1px solid var(--line);background:var(--wash)}
.pnav .btn{padding:10px 16px}.pnav .btn[disabled]{opacity:.45;cursor:default}
.pdots{display:flex;gap:8px}.pdots i{width:9px;height:9px;border-radius:50%;background:#ccdbe0}.pdots i.dn{background:#00838f}.pdots i.on{background:#e65100;transform:scale(1.3)}
@container (min-width:760px){.ppanes{grid-template-columns:minmax(0,1.1fr) minmax(0,1fr)}}
@container (max-width:719px){
 .pflow{grid-template-columns:minmax(0,1fr);padding:16px}
 .parr{flex-direction:row;align-items:center;justify-content:center;gap:10px;padding:2px 0}
 .parr .pl{width:2px;height:24px;margin:0 0 8px}
 .parr .pl::after{right:-5px;top:auto;bottom:-8px;border-width:9px 6px 0 6px;border-color:#b8cdd4 transparent transparent transparent}
 .parr.dn .pl::after{border-color:#00838f transparent transparent transparent}.parr.on .pl::after{border-color:#e65100 transparent transparent transparent}
 .pcard{flex-direction:row;justify-content:center;gap:10px;padding:9px}
 .pexp{flex-direction:column;align-items:stretch}
 .pnav .btn{padding:9px 12px}
}

/* ---- the make simulator ---- */
.mkbtns{gap:6px;align-items:center;padding:12px 22px}
.chip.run{background:#004d65;color:#fff;border-color:#004d65}.chip.run:hover{background:#00838f}
.mkfile{font-size:12.5px;tab-size:4}
.mkfiles{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:6px}
.mkf{border:1px solid var(--line);border-radius:8px;padding:6px 9px;background:#fff;font-size:12.5px;display:flex;flex-direction:column}
.mkf code{background:none;padding:0;font-weight:700}.mkf span{color:var(--muted)}.mkf em{font-style:normal;font-size:11.5px;color:#b35900;font-weight:700}
.mkf.gen{background:#f4f7f8}.mkf.miss{border-style:dashed;opacity:.55}.mkf.new{border-color:#e65100;box-shadow:0 0 0 2px #fde5d4}
.mkout{min-height:120px}
.wd .wd-b{grid-template-columns:minmax(0,1fr)}
.wd .wd-b>div+div{border-left:0;border-top:1px solid var(--line)}
@container (min-width:760px){.wd .wd-b:not(.sb){grid-template-columns:minmax(0,1fr) minmax(0,1fr)}.wd .wd-b:not(.sb)>div+div{border-left:1px solid var(--line);border-top:0}}

/* ---- the git panel ---- */
.extp{display:flex;flex-direction:column;gap:12px;font-size:13.5px;min-width:0}
.gnote{border-left:4px solid #e65100;background:#fff6ef;border-radius:0 10px 10px 0;padding:8px 12px;font-size:13.5px;line-height:1.5}
.gnote>b{display:block;font-size:10.5px;letter-spacing:1.3px;text-transform:uppercase;color:#c2410c}
.gplaces{display:flex;flex-direction:column}
.gbox{display:grid;grid-template-columns:118px minmax(0,1fr);gap:4px 10px;align-items:center;border:1.5px solid var(--line);border-radius:10px;background:#fff;padding:7px 10px;min-height:46px}
.gk b{display:block;font-size:13px;color:#004d65;line-height:1.2}.gk span{display:block;font-size:11px;color:var(--muted);line-height:1.25}
.gv{display:flex;flex-wrap:wrap;gap:4px 6px;align-items:center;min-width:0}
.gv>code{font-size:11.5px;color:#b35900;background:none;padding:0}
.gbox.hot{border-color:#e65100;box-shadow:0 0 0 3px #fde5d4;animation:ghot 1.4s ease-out}
@keyframes ghot{from{background:#ffe6d2}to{background:#fff}}
.garr{font-size:11.5px;color:#00838f;padding:3px 0 3px 30px;font-weight:600}
.garr code{font-size:11px;background:#e0f2f1;color:#00695c}
.gf{display:inline-flex;align-items:baseline;gap:5px;font:600 12px "SF Mono",Menlo,Consolas,monospace;padding:2px 7px;border-radius:6px;background:#eef3f6;color:#1f2a2e}
.gf i{font:500 10.5px system-ui,sans-serif;font-style:normal;opacity:.85}
.gf.m{background:#fdecd9;color:#a14b00}.gf.n,.gf.s{background:#e3f1e6;color:#2e7d46}.gf.d{background:#fde4e2;color:#b3261e}.gf.u{background:#eef0f2;color:#5b6b71}.gf.x{background:#c62828;color:#fff}
.gnone{color:#9aa9ae;font-size:12px}
.gref{font:700 12px "SF Mono",Menlo,monospace;color:#004d65}
.gtag{font-size:11px;font-weight:700;border-radius:999px;padding:1px 8px;white-space:nowrap}.gtag.a{background:#fde5d4;color:#c2410c}.gtag.b{background:#fff3cd;color:#8a6100}.gtag.x{background:#c62828;color:#fff}
.gcol{margin-left:auto;border:1px solid #e0a800;background:#fff8e1;color:#7a5600;border-radius:999px;padding:3px 10px;font-size:12px;font-weight:650;white-space:nowrap}
.gcol:hover{background:#ffecb3}
.ghist{border:1.5px solid var(--line);border-radius:10px;background:#fff;overflow:hidden;min-width:0}
.ghh{display:flex;gap:4px 10px;align-items:baseline;flex-wrap:wrap;padding:7px 10px;border-bottom:1px solid var(--line);background:#f4f7f8}
.ghh b{font-size:13px;color:#004d65}.ghh span{font-size:11px;color:var(--muted)}
.ggr{position:relative;max-height:330px;overflow:auto;padding:4px 0}
.glanes{position:absolute;left:4px;top:4px}
.grows{padding-left:calc(var(--lw) + 10px);padding-right:8px}
.grow{display:flex;align-items:center;gap:5px;white-space:nowrap;min-width:0;font-size:12.5px}
.grow.ghost .gmsg,.grow.ghost .gid{opacity:.65}
.gid{font-size:11.5px;background:none;padding:0;color:#b35900;flex:0 0 auto}
.gmsg{overflow:hidden;text-overflow:ellipsis;min-width:0;flex:1 1 auto}
.gby{font-size:10.5px;color:#8a6100;background:#fff3cd;border-radius:4px;padding:0 5px;flex:0 0 auto}
.gpill{flex:0 0 auto;font:700 10.5px/1 system-ui,sans-serif;border-radius:999px;padding:4px 7px;color:#fff;background:#004d65}
.gpill.h{background:#e65100}.gpill.b{background:#8e24aa}.gpill.o{background:#fff;color:#00838f;box-shadow:inset 0 0 0 1.5px #00838f}.gpill.r{background:#c77800}
@container (max-width:520px){.gbox{grid-template-columns:minmax(0,1fr)}.gcol{margin-left:0}}

/* ---- compiled / interpreted: the map and the race ---- */
.lmap{border:1px solid var(--line);border-radius:var(--r);background:#fff;padding:10px 14px 14px;margin:14px 0;container-type:inline-size}
.lm-row{display:grid;grid-template-columns:128px 88px minmax(0,1.2fr) 34px minmax(0,1fr);align-items:center;gap:0 10px;padding:10px 0;border-top:1px solid #eef3f5}
.lm-head{border-top:0;padding:2px 0 6px;font-size:11px;font-weight:750;letter-spacing:1px;text-transform:uppercase;color:var(--muted)}
.lm-head .lm-go{color:#e65100;display:flex;justify-content:center;white-space:nowrap;letter-spacing:.5px}
.lm-k b{display:block;color:var(--navy);font-size:15px}.lm-k span{font-size:12px;color:var(--muted)}
.lm-src code{font-size:12.5px}
.lm-z{display:flex;flex-wrap:wrap;align-items:center;gap:6px;min-height:40px;padding:6px 8px;border-radius:10px}
.lm-b{background:#eef4f6}.lm-w{background:#fff6ef}
.lm-row .lm-go{align-self:stretch;position:relative}
.lm-row:not(.lm-head) .lm-go::before{content:"";position:absolute;left:50%;top:-11px;bottom:-11px;border-left:2px dashed #e65100}
.lm-t{font-size:13px;font-weight:650;color:#004d65;background:#fff;border:1.5px solid #b8cdd4;border-radius:8px;padding:3px 8px}
.lm-t code{font-size:12px}
.lm-f{font-size:12.5px;border-radius:8px;padding:3px 8px;color:#fff}.lm-f code{background:none;color:#fff;padding:0}
.lm-f.mc{background:#004d65}.lm-f.bc{background:#8e24aa}
.lm-cpu{font-size:12.5px;font-weight:700;color:#c2410c}
.lm-a{color:#7d8d93;font-weight:700}
.lm-none{font-size:12.5px;color:#9aa9ae;font-style:italic}
.lmap figcaption{font-size:13.5px;color:var(--muted);margin-top:10px;border-top:1px solid #eef3f5;padding-top:10px}
@container (max-width:680px){
 .lm-head{display:none}
 .lm-row{grid-template-columns:minmax(0,1fr);gap:6px}
 .lm-row .lm-go{display:none}
 .lm-b::before{content:"before it runs:";font-size:11px;color:var(--muted);width:100%}
 .lm-w::before{content:"every time it runs:";font-size:11px;color:var(--muted);width:100%}
}
.lgc{align-items:end}.lgc .ctrl{flex:1 1 420px}.lgc .seg{flex-wrap:wrap}.lgc .btn[disabled]{opacity:.5;cursor:default}
.lgcols{display:grid;grid-template-columns:minmax(0,1fr)}
.lgcol{padding:14px 18px;display:flex;flex-direction:column;gap:8px;min-width:0}
.lgcol+.lgcol{border-top:1px solid var(--line)}
.lgh{display:flex;align-items:center;justify-content:space-between;gap:8px}.lgh b{font-size:17px;color:var(--navy)}
.lgk{font-size:11px;font-weight:750;letter-spacing:.8px;text-transform:uppercase;border-radius:999px;padding:3px 9px;color:#fff}
.lgk.c{background:#004d65}.lgk.py{background:#8e24aa}.lgk.sh{background:#c2410c}
.lgph{display:flex;gap:6px;flex-wrap:wrap}
.lgp{font-size:11.5px;font-weight:650;border:1.5px solid var(--line);border-radius:999px;padding:2px 9px;color:var(--muted);background:#fff}
.lgp.on{border-color:#e65100;color:#c2410c;background:#fff6ef}.lgp.dn{border-color:#00838f;color:#00838f}.lgp.px{border-color:#c62828;background:#c62828;color:#fff}.lgp.skip{border-style:dashed;opacity:.6;text-decoration:line-through}
.lgsrc{border:1px solid var(--line);border-radius:10px;overflow:hidden;background:#f8fafb}
.lgsrc pre{margin:0;padding:6px 0;font:13px/1.55 "SF Mono",Menlo,Consolas,monospace;overflow-x:auto}
.lgl{display:block;padding:0 10px 0 0;white-space:pre;transition:background .2s}
.lgl i{display:inline-block;width:28px;text-align:right;margin-right:10px;color:#9aa9ae;font-style:normal}
.lgl.le{box-shadow:inset 3px 0 #e0a800}
.lgl.scan{background:#e0f2f1}
.lgl.ran i{color:#00838f}
.lgl.now{background:#fde5d4}
.lgl.lx{background:#fde4e2}.lgl.lx i{color:#c62828;font-weight:700}
pre.sh.lgout{min-height:118px;font-size:12.5px;white-space:pre-wrap;word-break:break-word;overflow-x:hidden}
.lgout .e{color:#c62828;font-weight:600}
.lgres{font-size:12.5px;font-weight:700;border-radius:8px;padding:5px 10px;background:var(--wash);color:var(--muted);min-height:29px}
.lgres.early{background:#e0f2f1;color:#00695c}.lgres.late{background:#fde4e2;color:#b3261e}.lgres.ok{background:#eef4f6;color:#004d65}.lgres.warn{background:#fff3cd;color:#8a6100}
.lgx{font-size:14.5px;color:var(--ink);line-height:1.55}
@container (min-width:860px){.lgcols{grid-template-columns:repeat(3,minmax(0,1fr))}.lgcol+.lgcol{border-top:0;border-left:1px solid var(--line)}}

/* ---- build errors: cards that wrap, no horizontal scroll ---- */
.errs{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,380px),1fr));gap:12px;margin:14px 0 24px}
.errc{border:1px solid var(--line);border-left:5px solid #7d8d93;border-radius:10px;background:#fff;padding:12px 14px;min-width:0;display:flex;flex-direction:column;gap:8px}
.errc.pp{border-left-color:#00838f}.errc.cc{border-left-color:#8e24aa}.errc.ld{border-left-color:#e65100}
.est{align-self:start;font-size:11px;font-weight:750;letter-spacing:1px;text-transform:uppercase;border-radius:999px;padding:3px 9px;color:#fff;background:#7d8d93}
.errc.pp .est{background:#00838f}.errc.cc .est{background:#8e24aa}.errc.ld .est{background:#e65100}
.errc pre{margin:0;padding:8px 10px;border-radius:8px;background:#fdf1f0;color:#b3261e;font:12.5px/1.5 "SF Mono",Menlo,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}
.errc p{font-size:14.5px;line-height:1.5}

/* ---- libraries: the picture and the what-if widget ---- */
.libpic{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,340px),1fr));gap:14px;margin:16px 0}
.lpc{border:1px solid var(--line);border-radius:var(--r);background:#fff;padding:12px 14px;display:flex;flex-direction:column;gap:10px;min-width:0}
.lph{font-weight:700;color:var(--navy);font-size:15.5px}
.lpc>p{font-size:13.5px;color:#8a6100;background:#fff8e1;border-radius:8px;padding:6px 10px}
.lps{display:flex;flex-direction:column;gap:5px}
.lst{font-size:11px;font-weight:750;letter-spacing:1px;text-transform:uppercase;color:var(--muted)}
.lpr{display:flex;flex-wrap:wrap;align-items:center;gap:6px}
.lb{display:inline-flex;flex-direction:column;border:1.5px solid #b8cdd4;border-radius:8px;padding:4px 9px;background:#fff;line-height:1.25}
.lb code{background:none;padding:0;font-weight:700;color:#004d65}.lb i{font-style:normal;font-size:11.5px;color:var(--muted)}
.lb.a{border-color:#004d65;background:#eef4f6}.lb.s{border-color:#8e24aa;background:#f6eef8}.lb.s code{color:#6a1b9a}
.lb.x{border-color:#e65100;background:#fff6ef}.lb.x code{color:#c2410c}.lb b{color:inherit;font-weight:700}
.lt{font:600 11.5px "SF Mono",Menlo,monospace;color:#00838f;display:inline-flex;align-items:center;gap:4px}
.lt::after{content:"→";font-family:system-ui,sans-serif;font-weight:700}
.lt.n{color:var(--muted);font-family:system-ui,sans-serif;font-style:italic}.lt.n::after{content:""}
.libcols{display:grid;grid-template-columns:minmax(0,1fr)}
.libc{padding:14px 18px;display:flex;flex-direction:column;gap:10px;min-width:0}
.libc+.libc{border-top:1px solid var(--line)}
@container (min-width:760px){.libcols{grid-template-columns:repeat(2,minmax(0,1fr))}.libc+.libc{border-top:0;border-left:1px solid var(--line)}}
.lpic{display:flex;flex-wrap:wrap;align-items:center;gap:8px}
.lbox{display:flex;flex-direction:column;border:1.5px solid #b8cdd4;border-radius:9px;padding:6px 10px;line-height:1.3;background:#fff}
.lbox code{background:none;padding:0;font-weight:700}.lbox span{font-size:12px;color:var(--muted)}.lbox b{color:#c2410c}
.lbox.exe{border-color:#e65100;background:#fff6ef}.lbox.lib{border-color:#004d65;background:#eef4f6}.lbox.so{border-color:#8e24aa;background:#f6eef8}
.lbox.gone{border-style:dashed;opacity:.55}.lbox.gone code{text-decoration:line-through}
.lnk{font-size:11.5px;color:var(--muted);font-style:italic}
.lcap{font-size:13.5px;color:var(--muted);line-height:1.5}
pre.sh.lout{min-height:70px;font-size:12.5px;white-space:pre-wrap;overflow-wrap:anywhere}
pre.sh .e{color:#c62828;font-weight:600}

/* ---- make, step by step: three columns, short enough for a laptop screen ---- */
.mkc{align-items:center;padding:10px 18px;gap:10px 20px}.mkc .ctrl{flex:1 1 360px}.mkc .seg{flex-wrap:wrap}
.mknav{display:flex;align-items:center;gap:10px;flex:0 0 auto}
.mknav .btn{padding:9px 14px}.mknav .btn[disabled]{opacity:.45;cursor:default}
.mksx{padding:9px 18px;background:#fff6ef;border-bottom:1px solid #f6d6bd;font-size:14.5px;line-height:1.45;min-height:48px}
.mksx>b{color:#c2410c}
.mksb{display:grid;grid-template-columns:minmax(0,1fr);gap:12px 18px;padding:12px 18px;align-items:start}
@container (min-width:600px){.mksb{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}.mksr{grid-column:1/-1}}
@container (min-width:860px){.mksb{grid-template-columns:minmax(0,.95fr) minmax(0,1fr) minmax(0,1.05fr)}.mksr{grid-column:auto}}
.mksf{display:flex;justify-content:center;align-items:flex-start;min-width:0}
.mkflow{width:100%;max-width:340px;max-height:280px;height:auto}
.mks .wd-h{padding:12px 18px}.mks .wd-h h3::before{margin-bottom:5px}
.mkc .ctrl{flex-direction:row;align-items:center;gap:10px}.mkc .ctrl label{white-space:nowrap}
.mkflow .n rect,.mkflow .n polygon{fill:#fff;stroke:#9aa9ae;stroke-width:1.6}
.mkflow text{font:16px system-ui,"Avenir Next",sans-serif;fill:#33444a;text-anchor:middle}
.mkflow text.b{font-weight:700;font-family:"SF Mono",Menlo,monospace;font-size:16px;fill:#004d65}
.mkflow text.s{font-size:13.5px;fill:#7d8d93;font-style:italic}
.mkflow text.l{font-size:14px;fill:#7d8d93;font-style:italic;text-anchor:start}
.mkflow text.l.on{fill:#e65100;font-weight:700}
.mkflow .nr rect{stroke-dasharray:4 3}
.mkflow .e{fill:none;stroke:#9aa9ae;stroke-width:1.6}.mkflow .e.d{stroke-dasharray:3 3}
.mkflow .e.on{stroke:#e65100;stroke-width:2.6}
.mkflow .n.on rect,.mkflow .n.on polygon{stroke:#e65100;stroke-width:2.6;fill:#fff6ef}
.mkflow .up rect{fill:#f2f8f1;stroke:#82b366}.mkflow .up.on rect{fill:#d5e8d4;stroke:#2e7d46}
.mkflow .run rect{fill:#fff8f0;stroke:#d79b00}.mkflow .run.on rect{fill:#ffe6cc;stroke:#e65100}
.mkt{display:flex;flex-direction:column;gap:6px;min-width:0}
.mksr{display:grid;grid-template-columns:minmax(0,1fr);gap:4px;min-width:0}
.mksr .mkl{margin-top:6px}.mksr .mkl:first-child{margin-top:0}
.mkl{font-size:11px;font-weight:750;letter-spacing:1px;text-transform:uppercase;color:var(--muted)}.mkl i{font-weight:500;text-transform:none;letter-spacing:0}
.mktree{width:100%;height:auto;max-height:250px;display:block;margin:0 auto}
.mktree .te{stroke:#9aa9ae;stroke-width:1.6}.mktree .te.hot{stroke:#e65100;stroke-width:2.6}
.mktree .tn rect{fill:#fff;stroke:#9aa9ae;stroke-width:1.6}
.mktree .tn .nm{font:700 13px "SF Mono",Menlo,monospace;fill:#1f2a2e;text-anchor:middle}
.mktree .tn .tm{font:11.5px "SF Mono",Menlo,monospace;fill:#7d8d93;text-anchor:middle}
.mktree .tn.miss rect{stroke-dasharray:4 3;fill:#fafcfc}.mktree .tn.miss .nm{fill:#9aa9ae}
.mktree .tn.st rect{stroke:#e65100;stroke-dasharray:5 3}
.mktree .tn.leaf rect{fill:#eef4f6;stroke:#6c8ebf}
.mktree .tn.rb rect{fill:#ffe6cc;stroke:#d79b00}.mktree .tn.rb .nm{fill:#b35900}.mktree .tn.rb .tm{fill:#b35900;font-weight:700}
.mktree .tn.ok rect{fill:#d5e8d4;stroke:#82b366}
.mktree .tn.cur rect{stroke:#e65100;stroke-width:3;stroke-dasharray:none}
.mkst{display:flex;flex-wrap:wrap;gap:6px;min-height:28px;align-items:center}
.mkpill{font:700 13px "SF Mono",Menlo,monospace;border:1.5px solid #9aa9ae;border-radius:7px;padding:4px 10px;background:#fff;color:#1f2a2e}
.mkpill.top{border-color:#d79b00;background:#ffe6cc;color:#b35900}
.mkck,.mkrn{display:flex;flex-wrap:wrap;align-items:center;gap:6px 8px;min-height:38px}
.mkfb{display:inline-flex;flex-direction:column;align-items:center;border:1.5px solid #9aa9ae;border-radius:7px;padding:3px 10px;background:#fff;line-height:1.3}
.mkfb code{background:none;padding:0;font-weight:700}.mkfb i{font:11.5px "SF Mono",Menlo,monospace;font-style:normal;color:var(--muted)}
.mkfb.hot{border-color:#d79b00;background:#ffe6cc}.mkfb.hot code,.mkfb.hot i{color:#b35900}.mkfb.okb{border-color:#82b366;background:#eef6ed}
.mkv{font-size:13px;font-weight:700;color:#d79b00}.mkv.ok{color:#2e7d46}
.mkcmd{font-size:13px;background:#ffe6cc;color:#b35900;border:1.5px solid #d79b00;border-radius:7px;padding:4px 10px;font-weight:700}
.mknone{font-size:12.5px;color:#9aa9ae;font-style:italic}
.mkdone{font-size:13px;font-weight:700;color:#2e7d46;background:#d5e8d4;border-radius:7px;padding:4px 10px}
pre.sh.mkterm{margin-top:8px;min-height:64px;max-height:120px;overflow-y:auto;font-size:12px;padding:8px 12px;white-space:pre-wrap}

/* ---- LSP and DAP: an editor and the message log ---- */
.dapb{display:grid;grid-template-columns:minmax(0,1fr);gap:0}
.dapb>*{min-width:0}
@container (min-width:860px){.dapb{grid-template-columns:minmax(0,1fr) minmax(0,1.05fr)}.dapb>.mlp{border-left:1px solid var(--line);border-top:0}}
.ed{padding:14px 18px;display:flex;flex-direction:column;gap:8px}
.edh{font:12px "SF Mono",Menlo,monospace;color:#d3d7cf;background:#2b2b2b;border-radius:8px 8px 0 0;padding:6px 12px;margin-bottom:-8px}
.edc{margin:0;background:#1e1e1e;color:#d4d4d4;border-radius:0 0 8px 8px;padding:8px 0;font:13px/1.6 "SF Mono",Menlo,Consolas,monospace;overflow:visible}
.edc .lgl{display:block;white-space:pre;padding-right:10px;position:relative}
.edc .lgl i{display:inline-block;width:28px;text-align:right;margin-right:12px;color:#6e7681;font-style:normal}
.edc .hl-k{color:#569cd6;font-weight:400}.edc .hl-s{color:#ce9178}.edc .hl-p{color:#c586c0;font-weight:400}
.edc .lgl.now{background:#4b4a1e}.edc .lgl.now i{color:#ffd700}
.edc .lgl.lx{background:#3a1e1e}
u.sq{text-decoration:underline wavy #f14c4c;text-underline-offset:3px}
u.lk{text-decoration:underline #4fc1ff;color:#4fc1ff}
.popw{position:relative;background:#264f78}
.pop{position:absolute;left:0;top:calc(100% + 4px);z-index:3;white-space:normal;width:max-content;max-width:260px;background:#252526;color:#d4d4d4;border:1px solid #454545;border-radius:6px;padding:7px 10px;font:12.5px/1.45 system-ui,sans-serif;box-shadow:0 6px 18px rgba(0,0,0,.35)}
.pop code{background:#333;color:#9cdcfe}.pop i{color:#9da5b4}
.edst{font-size:12.5px;color:var(--muted);background:var(--wash);border-radius:8px;padding:6px 10px;min-height:32px}
.sqm{color:#c62828;font-weight:700}.okm{color:#2e7d46;font-weight:700}
.edc.gut .bp{display:inline-block;width:12px;height:12px;border-radius:50%;margin:0 0 -1px 8px;vertical-align:middle}
.edc.gut .bp.ok{cursor:pointer;box-shadow:inset 0 0 0 1.5px #555}
.edc.gut .bp.ok:hover{box-shadow:inset 0 0 0 1.5px #e51400;background:rgba(229,20,0,.35)}
.edc.gut .bp.on{background:#e51400;box-shadow:none}
.edc.gut .lgl i{width:22px;margin-right:12px}
.dpan{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}
.dpan>div{border:1px solid var(--line);border-radius:8px;background:#fff;padding:6px 10px;min-height:74px}
.dph{font-size:11px;font-weight:750;letter-spacing:1px;text-transform:uppercase;color:var(--muted);margin-bottom:4px}
.dv{font-size:13px;font-family:"SF Mono",Menlo,monospace}.dv code{background:none;padding:0;color:#6a1b9a}.dv b{color:#004d65}
.dv.on{font-weight:700;color:#c2410c}.dv i{font-style:normal;color:var(--muted);font-weight:400}
.mlp{display:flex;flex-direction:column;border-top:1px solid var(--line);min-width:0}
.mlh{display:flex;justify-content:space-between;flex-wrap:wrap;gap:4px 12px;padding:10px 16px;background:var(--wash);border-bottom:1px solid var(--line);font-size:13px;color:var(--navy)}
.mlh span+span{font-size:11.5px;color:var(--muted)}
.mlb{padding:8px 12px;display:flex;flex-direction:column;gap:6px;max-height:430px;overflow-y:auto;min-height:220px}
.ml{display:grid;grid-template-columns:22px auto auto 1fr;align-items:baseline;gap:2px 7px;font-size:12.5px;border-radius:8px;padding:5px 8px;background:#f8fafb;border:1px solid #eef3f5}
.ml.l{background:#f3f8f7}
.ml.new{border-color:#e65100;background:#fff6ef}
.ml .mla{font-weight:800;color:#00838f;font-size:14px}.ml.l .mla{color:#8e24aa}
.ml b{font:700 12.5px "SF Mono",Menlo,monospace;color:#004d65;overflow-wrap:anywhere}
.mlk{font-size:10px;font-weight:750;letter-spacing:.8px;text-transform:uppercase;border-radius:999px;padding:2px 7px;color:#fff;background:#7d8d93}
.mlk.request{background:#006483}.mlk.response{background:#2e7d46}.mlk.event,.mlk.notification{background:#c77800}
.mlid{font-size:11px;color:var(--muted);justify-self:start}
.ml code{grid-column:2/-1;font-size:11.5px;background:none;padding:0;color:#4f5b60;white-space:pre-wrap;overflow-wrap:anywhere}
.ml.os{grid-template-columns:22px 1fr;background:none;border:1px dashed #ccdbe0;color:var(--muted);font-size:12px;font-style:italic}
.ml.os.new{border-color:#e65100}

/* ---- tables: wrap instead of scrolling sideways ---- */
.pg table.t td code,.pg table.t th code{white-space:normal}
.pg table.t.k td:first-child{white-space:normal}
/* terminals and source files wrap their long lines instead of scrolling sideways */
.pg pre.sh,.pg .srcb pre,.pg .errc pre{white-space:pre-wrap;overflow-wrap:anywhere;overflow-x:hidden}
.pg .srcb pre{tab-size:4}
@media (max-width:520px){.pg table.t{font-size:13px}.pg table.t th,.pg table.t td{padding:7px 6px}.pg table.t td,.pg table.t th{overflow-wrap:anywhere;hyphens:auto}}

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
    num="07", key="iso-07-dev-v1", short="Software Development",
    title="Software Development, step by step · ISO Lecture 07",
    description="ISO Lecture 07 – Software Development: compiled and interpreted languages, IDEs, language servers, debuggers, the C compilation pipeline, make and Git, with simulators.",
    title_html="Software development, step by step:<br><span>from source code to a shared project.</span>",
    lead="How source code becomes a running program, the tools that help you write and debug it, how make rebuilds only what changed, and how Git keeps the history and shares it.",
    features="interactive: the C pipeline, demo terminals for gcc, make and git",
    starth="Start with compiled and interpreted languages.",
    maphead="From the source to the build, the debugger and Git.",
    how="Text, figures and the simulators were generated with Claude (Anthropic) from the slides of lecture 07 – Software Development, following the structure of the interactive DEEA modules.",
    checked="The outputs shown come from the slides. The make simulator follows the rules of GNU Make (modification times); the git terminal models status, diff, add, commit, log, branches, merge (with conflicts), fetch, pull and push, not every case of Git.",
)

if __name__ == "__main__":
    render(COURSE, META, OUT, js=["dev.js", "widgets07.js", "shell-make.js", "shell-git.js"], css=CSS)
