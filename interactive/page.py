"""The page of an interactive ISO lecture: chapters, build-time f-strings, the HTML template."""
import base64, io, json, os, re, sys
from engine import E, md
import theme

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)


def img(folder, path, alt, width=900):
    """an image from the slides (png/jpg, or the first page of a pdf), scaled down and inlined"""
    from PIL import Image
    src = os.path.join(REPO, folder, path)
    if src.endswith(".pdf"):
        import subprocess, tempfile
        tmp = tempfile.mkdtemp()
        subprocess.run(["pdftoppm", "-r", "150", "-png", "-singlefile", src, os.path.join(tmp, "p")], check=True)
        src = os.path.join(tmp, "p.png")
    im = Image.open(src)
    if im.mode in ("RGBA", "LA", "P"):
        bg = Image.new("RGB", im.size, "white"); im = im.convert("RGBA"); bg.paste(im, mask=im.split()[3]); im = bg
    im.thumbnail((width, width))
    b = io.BytesIO(); im.save(b, "JPEG", quality=82, optimize=True)
    return f'<img class="shot" alt="{E(alt)}" src="data:image/jpeg;base64,{base64.b64encode(b.getvalue()).decode()}">'


def F(t):
    """an f-string evaluated at build time in the globals of the caller, so the expressions
    may contain backslashes (Python < 3.12); t is a raw string: `\\\\` in the text is one backslash"""
    g = sys._getframe(1).f_globals
    out, i, n = [], 0, len(t)
    while i < n:
        if t[i] == "{":
            j, depth, q = i + 1, 1, None
            while depth:
                ch = t[j]
                if q:
                    if t.startswith(q, j):
                        j += len(q) - 1; q = None
                    elif ch == "\\":
                        j += 1
                elif t.startswith('"""', j) or t.startswith("'''", j):
                    q = t[j:j + 3]; j += 2
                elif ch in "\"'":
                    q = ch
                elif ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                j += 1
            out.append(str(eval(t[i + 1:j - 1], g)))
            i = j
        else:
            k = t.find("{", i)
            k = n if k < 0 else k
            out.append(t[i:k].replace("\\\\", "\\"))
            i = k
    return "".join(out)


class Course:
    def __init__(self):
        self.chapters = []   # (id, title, desc, minutes, [(page id, title, eyebrow, html)])

    def chapter(self, cid, title, desc, minutes):
        c = (cid, title, desc, minutes, [])
        self.chapters.append(c)
        return lambda pid, ptitle, eyebrow, body: c[4].append((pid, ptitle, eyebrow, body))


def flash(cards):
    out = []
    for ch, cname, link, t, b in cards:
        meta = f"{ch} · {E(cname)}"
        out.append(f'<div class="rc" data-ch="{ch}"><div class="rin"><div class="rf"><div class="rmeta">{meta}</div><div class="rt">{md(t)}</div><div class="rhint">click / Space</div></div>'
                   f'<div class="rbk"><div class="rmeta">{meta}</div><div class="rt2">{md(t)}</div><div class="rb"><p>{md(b)}</p></div><a class="rgo" href="#{link}">see the page →</a></div></div></div>')
    return '<div data-w="flash"><div class="rgrid">' + "".join(out) + "</div></div>"


def render(course, M, out, js=(), css=""):
    """M: num, key, short, title, title_html, lead, description, starth, maphead, features,
    how, checked; js: extra widget scripts (file names in this folder)"""
    rd = lambda f: open(os.path.join(HERE, f)).read()
    CH = course.chapters
    data = [{"id": c[0], "title": re.sub(r"`", "", c[1]), "desc": md(c[2]), "min": c[3],
             "pages": [{"id": pg[0], "title": re.sub(r"`", "", pg[1])} for pg in c[4]]} for c in CH]
    npages = sum(len(c[4]) for c in CH)
    mins = sum(c[3] for c in CH)
    arts = [f'<article class="pg" data-key="{c[0]}/{pid}"><div class="eyebrow">{md(eb)}</div><h1>{md(pt)}</h1>\n{body}\n</article>'
            for c in CH for pid, pt, eb, body in c[4]]
    glue = """(()=>{'use strict';
const el=(h)=>{const d=document.createElement('div');d.innerHTML=h.trim();return d.firstChild};
function bindSeg(root,name,cb){root.querySelectorAll(`[data-seg="${name}"] button`).forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll(`[data-seg="${name}"] button`).forEach(x=>x.classList.toggle('on',x===b));cb(b.dataset.v)}))}
""" + rd("flash.js") + """
const W=window.DK_W||(window.DK_W={});W.flash=wFlash;
document.querySelectorAll('[data-w]').forEach(n=>{try{W[n.dataset.w](n)}catch(e){console.error(e)}});
})();"""
    tux = rd(os.path.join(REPO, "website/static/img/tux.svg"))
    brand = tux[tux.find("<svg"):].replace("<svg ", '<svg aria-hidden="true" ', 1)
    from PIL import Image
    ic = Image.open(os.path.join(REPO, "website/static/img/tux.png")); ic.thumbnail((64, 64))
    b = io.BytesIO(); ic.save(b, "PNG", optimize=True)
    icon = base64.b64encode(b.getvalue()).decode()
    meta_js = json.dumps({"key": M["key"], "num": M["num"], "short": M["short"], "title": M["title"], "starth": M["starth"]})
    extra_js = "".join(f"<script>{rd(f)}</script>\n" for f in js)
    html_ = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{E(M['description'])}">
<title>{E(M['title'])}</title>
<link rel="icon" type="image/png" href="data:image/png;base64,{icon}">
{theme.FONT}
<style>{theme.apply(rd("base.css") + chr(10) + rd("extra.css") + chr(10) + css)}</style>
</head>
<body>
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs><marker id="ar-n" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#004d65"/></marker></defs></svg>
<header class="topbar"><div class="wrap top-inner">
<a class="brand" href="#map" aria-label="ISO, course map">{brand}<b>ISO</b><span>/ LECTURE {M['num']}</span></a>
<nav class="nav"><a class="mapbtn" href="#map"><svg viewBox="0 0 20 20" aria-hidden="true"><path d="M2 5l5-2 6 2 5-2v12l-5 2-6-2-5 2z" fill="none" stroke-width="1.6" stroke-linejoin="round"/><path d="M7 3v12M13 5v12" fill="none" stroke-width="1.6"/></svg>Course map</a><a class="hide-m" href="#all">Read it all</a></nav>
</div></header>

<main id="home">
<div class="wrap hero">
<div><div class="eyebrow">Introduction to Operating Systems</div>
<h1>{M['title_html']}</h1>
<p class="lead">{M['lead']}</p>
<div class="meta"><span><b>{len(CH)}</b> chapters · <b>{npages}</b> pages</span><span>≈ <b>{mins}</b> min</span><span>{M['features']}</span></div></div>
<div class="startcard"><div class="eyebrow">Your progress</div><h2 id="starth">{E(M['starth'])}</h2>
<p>Follow the chapters in order or pick one on the map.</p>
<div class="prog"><span id="pcount"></span><span id="ccount"></span></div><div class="track"><span id="ptrack"></span></div>
<a class="btn wide" id="startbtn" href="#"><span id="startlbl">Start the course</span><span aria-hidden="true">→</span></a>
<p class="small">Progress is saved in this browser. <a href="#" id="reset">Reset</a></p></div>
</div>
<section class="wrap mapsec">
<div class="maphead"><div><div class="eyebrow">Course map</div><h2>{M['maphead']}</h2></div>
<div class="legend"><span><i style="background:var(--teal)"></i>Current chapter</span><span><i style="background:var(--navy)"></i>Done</span></div></div>
<div class="map" id="map"></div>
<div class="about" id="about">
<div class="aibanner" role="note"><div class="aiicon" aria-hidden="true">AI</div><div><b>Study material generated with AI (Claude)</b> from the slides of ISO lecture {M['num']}, to be reviewed by the lecturers. It may contain mistakes; for the exam, the reference is the lecture and its slides. <b>Found a mistake? Open an issue on the course repository.</b></div></div>
<details class="aboutd"><summary>About this material</summary><div class="aboutg">
<div><h3>How it was made</h3><p>{M['how']}</p></div>
<div><h3>What was checked</h3><p>{M['checked']}</p></div>
<div><h3>Mistakes</h3><p>If you find one, open an issue with the page and the sentence. Version: November 2026.</p></div>
<div><h3>Sources and contributors</h3><p>Slides: USO Team, Copyright (C) 2026 Wyliodrin &amp; Politehnica Bucharest, CC-BY-SA 4.0. Bibliography: the sources listed in the slides of the lecture.{M.get('sources_extra', '')}</p></div>
</div></details></div>
</section>
</main>

<section id="chapter" hidden>
<div class="wrap crumbs"><a href="#map">Course map</a><span aria-hidden="true">/</span><span id="crumb"></span><span class="pp" id="ppos"></span></div>
<div class="wrap layout">
<aside class="side"><div class="num" id="snum"></div><h2 id="stitle"></h2><div class="tm" id="stime"></div><nav aria-label="Pages of the chapter"><ol id="smenu"></ol></nav><a class="back" href="#map">← All chapters</a><div class="chnav"><a id="chprev" href="#">‹ Previous chapter</a><a id="chnext" href="#">Next chapter ›</a></div></aside>
<div class="col" id="continut">
{chr(10).join(arts)}
</div></div>
<div class="bottombar"><div class="wrap bb">
<a class="btn ghost" id="bprev" href="#">← Back</a>
<div class="pos" id="bpos"></div>
<a class="btn" id="bnext" href="#"><span id="bnextl">Continue</span> <span aria-hidden="true">→</span></a>
</div></div>
</section>
<script>window.COURSE={json.dumps(data)};window.COURSE_META={meta_js};</script>
<script>{rd("shell-core.js")}</script>
<script>{rd("shell-ui.js")}</script>
{extra_js}<script>{glue}</script>
<script>{rd("runtime.js")}</script>
</body>
</html>
"""
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, "w").write(html_)
    print("wrote", out, len(html_) // 1024, "KB,", len(CH), "chapters,", npages, "pages")
