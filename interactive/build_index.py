#!/usr/bin/env python3
"""Build the main page of the interactive lectures: one card per lecture, with its progress.

    python3 interactive/build_index.py
writes website/static/courses/index.html (the "ISO" link of every lecture page goes here).
Lectures are found from build_NN.py (their META and COURSE); a lecture of the docs without
a build file is listed as "coming soon", with a link to its notes.
"""
import base64, glob, importlib.util, io, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from engine import E
from page import HERE, REPO
import theme

OUT = os.path.join(REPO, "website/static/courses/index.html")


def lectures():
    """[(num, title, meta or None, folder, chapters, pages, minutes)] for every lecture of the docs"""
    built = {}
    for b in sorted(glob.glob(os.path.join(HERE, "build_[0-9][0-9].py"))):
        spec = importlib.util.spec_from_file_location(os.path.basename(b)[:-3], b)
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        CH = m.COURSE.chapters
        built[m.META["num"]] = (m.META, os.path.basename(os.path.dirname(m.OUT)),
                                len(CH), sum(len(c[4]) for c in CH), sum(c[3] for c in CH))
    out = []
    for d in sorted(glob.glob(os.path.join(REPO, "website/docs/lectures/[0-9][0-9].md"))):
        num = os.path.basename(d)[:2]
        desc = re.search(r"^description:\s*(.+)$", open(d).read(), re.M)
        title = desc.group(1).strip() if desc else f"Lecture {num}"
        if num in built:
            M, folder, nc, npg, mins = built[num]
            out.append((num, title, M, folder, nc, npg, mins))
        else:
            out.append((num, title, None, None, 0, 0, 0))
    return out


CSS = """
.hub-hero{padding:56px 0 30px;max-width:820px}
.hub-hero h1{font-size:clamp(38px,5vw,62px);font-weight:600;margin:16px 0 18px}
.hub-hero h1 span{color:var(--blue)}
.hub-sum{display:flex;gap:18px;flex-wrap:wrap;margin-top:20px;font-size:13px;color:var(--muted)}
.hub-sum b{color:var(--navy);font-weight:650}
.hub-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(330px,1fr));gap:22px;padding:8px 0 56px}
.hub-c{display:flex;flex-direction:column;border:1px solid var(--line);border-radius:var(--r);padding:24px 24px 22px;background:#fff;text-decoration:none;color:inherit;box-shadow:0 10px 30px rgba(35,50,84,.06);transition:transform .15s,box-shadow .15s,border-color .15s}
a.hub-c:hover{transform:translateY(-3px);border-color:var(--teal);box-shadow:0 14px 34px rgba(35,50,84,.12)}
.hub-top{display:flex;align-items:center;justify-content:space-between;gap:12px}
.hub-num{width:46px;height:46px;border-radius:50%;display:grid;place-items:center;background:var(--navy);color:#fff;font-weight:700;font-size:16px;flex:none}
.hub-c.done .hub-num{background:var(--teal)}
.hub-tag{font-size:11px;text-transform:uppercase;letter-spacing:1.3px;font-weight:750;color:var(--teal-d);background:var(--pale);border-radius:20px;padding:4px 10px}
.hub-c.done .hub-tag{background:var(--teal);color:#fff}
.hub-c h2{margin:18px 0 8px;font-size:25px}
.hub-c p{color:var(--muted);font-size:15px;line-height:1.55}
.hub-mt{font-size:13px;color:var(--muted);margin-top:14px}.hub-mt b{color:var(--navy);font-weight:650}
.hub-f{font-size:13px;color:var(--ink);margin-top:6px}
.hub-pr{margin-top:auto;padding-top:20px}
.hub-pr .prog{margin:0 0 7px}
.hub-go{display:flex;justify-content:space-between;align-items:center;margin-top:16px;font-weight:650;color:var(--navy);font-size:15px}
a.hub-c:hover .hub-go{color:var(--teal-d)}
.hub-c.soon{background:var(--wash);box-shadow:none;border-style:dashed}
.hub-c.soon .hub-num{background:#b8c6cb}
.hub-c.soon .hub-tag{background:#fff;color:var(--muted)}
.hub-c.soon h2{color:var(--muted)}
.hub-c.soon a{font-size:14px;margin-top:auto;padding-top:18px}
.hub-foot{border-top:1px solid var(--line);padding:22px 0 40px;font-size:13px;color:var(--muted)}
@media (max-width:720px){.hub-grid{grid-template-columns:1fr}.hub-hero{padding-top:36px}}
"""


def card(num, title, M, folder, nc, npg, mins):
    if M is None:
        return (f'<div class="hub-c soon"><div class="hub-top"><div class="hub-num">{num}</div><span class="hub-tag">Coming soon</span></div>'
                f'<h2>{E(title)}</h2><p>The interactive version of this lecture is not ready yet.</p>'
                f'<a href="/docs/lectures/{num}">Read the lecture notes →</a></div>')
    return (f'<a class="hub-c" href="{folder}/index.html" data-key="{E(M["key"])}" data-total="{npg}">'
            f'<div class="hub-top"><div class="hub-num">{num}</div><span class="hub-tag">Lecture {num}</span></div>'
            f'<h2>{E(M["short"])}</h2><p>{E(M["lead"])}</p>'
            f'<div class="hub-mt"><b>{nc}</b> chapters · <b>{npg}</b> pages · ≈ <b>{mins}</b> min</div>'
            f'<div class="hub-f">{E(M["features"][0].upper() + M["features"][1:])}</div>'
            f'<div class="hub-pr"><div class="prog"><span class="hub-pc">Not started</span><span></span></div><div class="track"><span></span></div>'
            f'<div class="hub-go"><span class="hub-gl">Start the lecture</span><span aria-hidden="true">→</span></div></div></a>')


JS = """(()=>{'use strict';
let all=0,started=0;
document.querySelectorAll('a.hub-c[data-key]').forEach(a=>{
  let d={};try{d=JSON.parse(localStorage.getItem(a.dataset.key)||'{}')||{}}catch(e){}
  const n=Object.keys(d).filter(k=>d[k]).length, t=+a.dataset.total, p=Math.min(n,t);
  a.querySelector('.track span').style.width=(100*p/t)+'%';
  a.querySelector('.hub-pc').textContent=p?`${p} / ${t} pages done`:'Not started';
  if(p){started++;a.querySelector('.hub-gl').textContent=p>=t?'Review the lecture':'Continue'}
  if(p>=t){a.classList.add('done');a.querySelector('.hub-tag').textContent='Done'}
  all++;
});
const s=document.getElementById('hubprog');
if(s&&started)s.innerHTML=`<b>${started}</b> of ${all} started in this browser`;
})();"""


def build():
    L = lectures()
    ready = [x for x in L if x[2]]
    tux = open(os.path.join(REPO, "website/static/img/tux.svg")).read()
    brand = tux[tux.find("<svg"):].replace("<svg ", '<svg aria-hidden="true" ', 1)
    from PIL import Image
    ic = Image.open(os.path.join(REPO, "website/static/img/tux.png")); ic.thumbnail((64, 64))
    b = io.BytesIO(); ic.save(b, "PNG", optimize=True)
    icon = base64.b64encode(b.getvalue()).decode()
    rd = lambda f: open(os.path.join(HERE, f)).read()
    html_ = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="The interactive lectures of Introduction to Operating Systems (ISO, UPB): chapters, demo terminals, simulators, quizzes and flashcards.">
<title>Interactive lectures · ISO</title>
<link rel="icon" type="image/png" href="data:image/png;base64,{icon}">
{theme.FONT}
<style>{theme.apply(rd("base.css") + chr(10) + rd("extra.css") + chr(10) + CSS)}</style>
</head>
<body>
<header class="topbar"><div class="wrap top-inner">
<a class="brand" href="index.html" aria-label="ISO, all interactive lectures">{brand}<b>ISO</b><span>/ INTERACTIVE LECTURES</span></a>
<nav class="nav"><a href="/docs/category/lectures">Lectures</a><a class="hide-m" href="/docs/category/labs">Labs</a><a href="/">Course site</a></nav>
</div></header>
<main class="wrap">
<section class="hub-hero">
<div class="eyebrow">Introduction to Operating Systems</div>
<h1>Interactive lectures:<br><span>read, try and check yourself.</span></h1>
<p class="lead">Each lecture as short pages, with demo terminals you can type in, step-by-step simulators, quizzes and flashcards. Pick a lecture to start or continue.</p>
<div class="hub-sum"><span><b>{len(ready)}</b> of {len(L)} lectures ready</span><span><b>{sum(x[5] for x in ready)}</b> pages · ≈ <b>{sum(x[6] for x in ready)}</b> min</span><span id="hubprog">Progress is saved in this browser</span></div>
</section>
<section class="hub-grid" aria-label="Lectures">
{chr(10).join(card(*x) for x in L)}
</section>
<footer class="hub-foot">Study material generated with AI (Claude) from the slides of the lectures, to be reviewed by the lecturers; for the exam, the reference is the lecture and its slides. Slides: USO Team, Copyright (C) 2026 Wyliodrin &amp; Politehnica Bucharest, CC-BY-SA 4.0. Found a mistake? <a href="https://github.com/upb-cs-iso/upb-cs-iso.github.io/issues">Open an issue</a>.</footer>
</main>
<script>{JS}</script>
</body>
</html>
"""
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w").write(html_)
    print("wrote", OUT, len(html_) // 1024, "KB,", len(ready), "of", len(L), "lectures")


if __name__ == "__main__":
    build()
