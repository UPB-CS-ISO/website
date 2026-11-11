"""Small HTML builders for the ISO interactive lecture pages (course kit look & feel)."""
import html, re

E = html.escape


def md(s):
    """inline markup: `code`, **bold**, *em*, [[key]]"""
    out = []
    for i, part in enumerate(re.split(r"(`[^`]+`)", s)):
        if i % 2:
            out.append("<code>" + E(part[1:-1]) + "</code>")
            continue
        part = re.sub(r"\[\[(.+?)\]\]", lambda m: "<kbd>" + m.group(1) + "</kbd>", part)
        part = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", part)
        part = re.sub(r"(?<![\w*])\*(?!\s)(.+?)\*(?!\w)", r"<em>\1</em>", part)
        out.append(part)
    return "".join(out)


def p(*paras):
    return "".join(f'<p class="txt">{md(x)}</p>' for x in paras)


def ul(*items):
    return '<ul class="k">' + "".join(f"<li>{md(x)}</li>" for x in items) + "</ul>"


def why(text, items=()):
    return (f'<div class="why"><div class="eyebrow">Why it matters</div><p>{md(text)}</p>'
            + (ul(*items) if items else "") + "</div>")


def note(title, body, kind=""):
    return f'<div class="note {kind}"><h3>{md(title)}</h3><p>{md(body)}</p></div>'


def bad(title, body, fix):
    return (f'<div class="bad"><div class="eyebrow">Common mistake</div><h3>{md(title)}</h3>'
            f'<p>{md(body)}</p><p><strong>Instead:</strong> {md(fix)}</p></div>')


def win(body):
    return f'<div class="win"><b>Windows:</b> {md(body)}</div>'


def fig(inner, caption=None):
    cap = f"<figcaption>{md(caption)}</figcaption>" if caption else ""
    return f'<figure class="f">{inner}{cap}</figure>'


def duo(left, right, cls=""):
    return f'<div class="duo top {cls}"><div class="txt">{left}</div><div>{right}</div></div>'


def table(head, rows, cls=""):
    th = "".join(f"<th>{md(h)}</th>" for h in head)
    tr = "".join("<tr>" + "".join(f"<td>{md(c)}</td>" for c in r) + "</tr>" for r in rows)
    return f'<div style="overflow-x:auto"><table class="t {cls}"><tr>{th}</tr>{tr}</table></div>'


def tree(text, new=(), gone=(), here=(), source=(), changed=(), cwd=None, target=None, notes=None, caption=None):
    """an ASCII tree like the fs-tree of the slides; lines are numbered from 1"""
    notes = notes or {}
    lines = text.strip("\n").split("\n")
    w = max(len(l) for l in lines)
    out = []
    for i, l in enumerate(lines, 1):
        m = re.match(r"^([│├└─ ]*)(.*)$", l)
        branch, name = m.group(1), m.group(2)
        cls = ("n" if i in new else "g" if i in gone else "s" if i in source else
               "m" if i in changed else "h" if i in here or i == cwd else "")
        s = E(branch) + "<b>" + E(name) + "</b>"
        tail = ""
        if i == cwd:
            tail += ' <i class="cwd">📍</i>'
        if i == target:
            tail += ' <i class="cwd">🎯</i>'
        if i in new:
            tail += " +"
        if i in gone:
            tail += " −"
        if i in notes:
            tail += " " * (w - len(l) + 1) + f'<span class="an">← {E(notes[i])}</span>'
        out.append(f'<span class="{cls}">{s}{tail}</span>' if cls else s + tail)
    pre = '<pre class="tree">' + "\n".join(out) + "</pre>"
    return fig(pre, caption)


def color_cmd(cmd):
    """the colors of terminal.typ: command, -options, "strings", operators"""
    out, first = [], True
    for tok in re.findall(r'"[^"]*"|\'[^\']*\'|&&|[;|>]|\S+|\s+', cmd):
        if tok.isspace():
            out.append(tok)
        elif first:
            out.append(f'<span class="cn">{E(tok)}</span>'); first = False
        elif tok in ("&&", ";", "|"):
            out.append(f'<b>{E(tok)}</b>'); first = True
        elif tok.startswith("-"):
            out.append(f'<span class="fl">{E(tok)}</span>')
        elif tok[0] in "\"'":
            out.append(f'<span class="st">{E(tok)}</span>')
        else:
            out.append(E(tok))
    return "".join(out)


def sh(text, marks=None, caption=None):
    """a terminal: `$ ` lines are commands, `# ` after a command is a comment, the rest is output.
    marks: {line number: [(substring, 'mk'|'mk2'|'mk3'), ...]}"""
    marks = marks or {}
    out = []
    for i, l in enumerate(text.strip("\n").split("\n"), 1):
        if l.startswith("$ "):
            cmd, _, com = l[2:].partition("  #")
            body = E(cmd) if i in marks else color_cmd(cmd)
            if i in marks:   # keep the command name in its color, the marks color the parameters
                w0 = cmd.split(" ", 1)
                body = f'<span class="cn">{E(w0[0])}</span>' + (" " + E(w0[1]) if len(w0) > 1 else "")
            for sub, c in marks.get(i, []):
                body = body.replace(E(sub), f'<span class="{c}">{E(sub)}</span>', 1)
            out.append(f'<span class="p">$</span> <span class="c">{body}</span>'
                       + (f'<span class="k">  #{E(com)}</span>' if com else ""))
        else:
            out.append(f'<span class="o">{E(l)}</span>')
    pre = '<pre class="sh">' + "\n".join(out) + "</pre>"
    return f'<figure class="f" style="padding:0;border:0">{pre}<figcaption>{md(caption)}</figcaption></figure>' if caption else pre


def syn(text):
    """a SYNOPSIS line; {a:..} {b:..} {c:..} are colored like source / destination / option"""
    s = E(text)
    s = re.sub(r"\{([abc]):(.+?)\}", r'<span class="\1">\2</span>', s)
    return f'<div class="syn">{s}</div>'


def quiz(question, options, ok, expl):
    opts = "".join(f'<button type="button" class="o">{chr(65+i)}. {md(o)}</button>' for i, o in enumerate(options))
    return (f'<div class="q" data-ok="{ok}"><div class="ql">Check yourself</div><h3>{md(question)}</h3>'
            f'<div class="opts">{opts}</div><div class="fb" data-x="{E(md(expl))}"></div></div>')


def sol(summary, body):
    return f'<details class="sol"><summary>{md(summary)}</summary><div>{body}</div></details>'


def shell(cmds=(), cwd="~", title=None, missions=False, view="home"):
    a = f' data-cmds="{E("|".join(cmds))}"' if cmds else ""
    a += f' data-cwd="{E(cwd)}" data-view="{view}"'
    if title:
        a += f' data-title="{E(title)}"'
    if missions:
        a += f' data-missions="{"1" if missions is True else missions}"'
    return f'<div data-w="shell"{a}></div>'


def steps(*items):
    return '<ol class="steps">' + "".join(f"<li><span>{md(x)}</span></li>" for x in items) + "</ol>"


# ---------------------------------------------------------------- syntax highlighting
C_KW = r"\b(int|void|char|double|float|long|short|unsigned|signed|const|static|struct|return|for|while|if|else|do|switch|case|break|continue|sizeof|typedef|enum|extern)\b"


def _tok(text, rules):
    """rules: [(regex, css class or None)]; the first that matches at a position wins"""
    import re as _re
    big = _re.compile("|".join(f"(?P<g{i}>{r})" for i, (r, _) in enumerate(rules)), _re.M)
    out, pos = [], 0
    for m in big.finditer(text):
        out.append(E(text[pos:m.start()]))
        cls = rules[int(m.lastgroup[1:])][1]
        out.append(f'<span class="hl-{cls}">{E(m.group())}</span>' if cls else E(m.group()))
        pos = m.end()
    out.append(E(text[pos:]))
    return "".join(out)


def hl(text, lang):
    if lang == "c":
        return _tok(text, [(r"//[^\n]*|/\*.*?\*/", "c"), (r'"(?:\\.|[^"\\])*"|<[\w./]+\.h>', "s"),
                           (r"^[ \t]*#[ \t]*\w+", "p"), (C_KW, "k"), (r"\b\d+\b", "n"), (r"\b[A-Za-z_]\w*(?=\s*\()", "f")])
    if lang == "make":
        import re as _re
        mkv = [(r"\$\([^)]*\)", "v"), (r"\$[@<^*?]", "a"), (r"%", "a")]
        out = []
        for l in text.split("\n"):
            if l.startswith("\t"):
                m = _re.match(r"^(@?\S+)(.*)$", l[1:])
                if not m:
                    out.append(E(l)); continue
                first = _tok(m.group(1), mkv) if m.group(1).startswith("$") else f'<span class="hl-f">{E(m.group(1))}</span>'
                out.append("\t" + first + _tok(m.group(2), mkv)); continue
            c = l.find("#")
            code, com = (l[:c], f'<span class="hl-c">{E(l[c:])}</span>') if c >= 0 else (l, "")
            m = _re.match(r"^(\s*)([A-Za-z_]\w*)(\s*[:?+]?=)(.*)$", code)
            if m:
                out.append(m.group(1) + f'<span class="hl-v">{m.group(2)}</span>' + E(m.group(3)) + _tok(m.group(4), mkv) + com); continue
            m = _re.match(r"^(-?include)(\b.*)$", code)
            if m:
                out.append(f'<span class="hl-p">{m.group(1)}</span>' + _tok(m.group(2), mkv) + com); continue
            m = _re.match(r"^([^:=\s#][^:=]*?)(\s*:)([^=].*|)$", code)
            if m:
                tcls = "p" if m.group(1).startswith(".") else "t"
                out.append(f'<span class="hl-{tcls}">{_tok(m.group(1), mkv)}</span>' + E(m.group(2)) + f'<span class="hl-q">{_tok(m.group(3), mkv)}</span>' + com); continue
            out.append(E(code) + com)
        return "\n".join(out)
    if lang == "json":
        return _tok(text, [(r'"(?:\\.|[^"\\])*"(?=\s*:)', "t"), (r'"(?:\\.|[^"\\])*"', "s"), (r"\b\d[\d.]*\b|\btrue\b|\bfalse\b", "n")])
    if lang == "asm":
        return _tok(text, [(r"#[^\n]*", "c"), (r"^[.\w]+:", "t"), (r"\$\w+|%\w+", "n"), (r"^\s+[a-z]+", "k"), (r"[\w.]+@PLT", "f")])
    return E(text)
