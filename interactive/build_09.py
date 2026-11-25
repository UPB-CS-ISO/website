#!/usr/bin/env python3
"""Build the interactive page of lecture 09 (Network Infrastructure).

    python3 interactive/build_09.py
writes website/static/courses/09-network/index.html

The step-by-step pictures (frames on the wires, ARP, NAT, DNS, DHCP, ...) are drawn here, one SVG per step, and
shown by the generic `scene` widget of widgets09.js; the hub / switch, the mask calculator, the routing table and
the tcpdump filters are small simulators in widgets09.js; the demo terminal knows `ip`, `ping`, `nmcli`, `ss`,
`tcpdump` ... of a simulated laptop (widgets09.js, profile '09').
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from engine import *  # noqa
from page import Course, flash as flash_cards, render, REPO

OUT = os.path.join(REPO, "website/static/courses/09-network/index.html")
COURSE = Course()
chapter = COURSE.chapter
J = lambda *parts: "\n".join(parts)

# ---------------------------------------------------------------- colors
NAVY, TEAL, MUTED, INK = "#004d65", "#00838f", "#5b6b71", "#1f2d33"
BLUE, ORANGE, GREEN, RED, AMBER, GREY = ("#dae8fc", "#6c8ebf"), ("#ffe6cc", "#d79b00"), ("#d5e8d4", "#82b366"), ("#f8cecc", "#b85450"), ("#fff2cc", "#d6b656"), ("#eef1f3", "#9aa9ae")
HL, HLBG, OKC, BADC = "#e65100", "#fff3e0", "#2e7d46", "#c62828"
# one color per layer, as in the slides
LAYER = {"application": GREEN, "transport": AMBER, "network": ORANGE, "link": RED, "physical": BLUE}
_ARROWS = {"navy": NAVY, "teal": TEAL, "orange": "#d79b00", "hl": HL, "green": "#2e7d46", "red": "#b85450", "grey": "#7d8d93", "blue": "#6c8ebf"}


# ---------------------------------------------------------------- SVG helpers (as in build_03 / build_08)
def _t(x, y, s, size=15, w=400, fill=INK, a="middle", mono=False, it=False):
    fam = "'SF Mono',Menlo,Consolas,monospace" if mono else "system-ui,sans-serif"
    st = "italic " if it else ""
    return f'<text x="{x}" y="{y}" text-anchor="{a}" style="font:{st}{w} {size}px {fam}" fill="{fill}">{E(s)}</text>'


def _r(x, y, w, h, c, rx=10, sw=2, dash=False):
    d = ' stroke-dasharray="6 5"' if dash else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{c[0]}" stroke="{c[1]}" stroke-width="{sw}"{d}/>'


def _a(pts, color="navy", w=2.2, dash=False, head=True, both=False):
    d = " ".join(f"{x},{y}" for x, y in pts)
    m = f' marker-end="url(#f3-{color})"' if head else ""
    m += f' marker-start="url(#f3-{color})"' if both else ""
    da = ' stroke-dasharray="6 5"' if dash else ""
    return f'<polyline points="{d}" fill="none" stroke="{_ARROWS.get(color, color)}" stroke-width="{w}" stroke-linejoin="round"{da}{m}/>'


def _l(x1, y1, x2, y2, c="#7d8d93", w=2, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{c}" stroke-width="{w}"{d}/>'


# the arrow heads: defined once for the whole page, by widgets09.js (f3-navy, f3-hl, ...), so the many step pictures
# do not repeat them; MARKERS is the same <defs>, for rendering a figure on its own (tests)
MARKERS = "<defs>" + "".join(f'<marker id="f3-{k}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>' for k, c in _ARROWS.items()) + "</defs>"


def svgfig(w, h, body, label, cls=""):
    return f'<svg class="f3 {cls}" viewBox="0 0 {w} {h}" style="max-width:{w}px" role="img" aria-label="{E(label)}">{body}</svg>'


def tw(s, size=15, mono=False):
    """the width of a text, estimated"""
    return len(s) * size * (0.61 if mono else 0.56)


def tag(x, y, lines, c=(HLBG, HL), size=14, mono=None, pad=8, bold_first=False, anchor="middle"):
    """a box with one or more lines of text, centered on (x, y) (or its left side at x); a line is a str or
    (str, mono?, color?, weight?)"""
    L = [(l, mono if mono is not None else False, INK, 400) if isinstance(l, str) else (l + (None,) * 4)[:4] for l in lines]
    L = [(s, m, col or INK, wt or (700 if (bold_first and i == 0) else 400)) for i, (s, m, col, wt) in enumerate(L)]
    w = max(tw(s, size, m) for s, m, _, _ in L) + 2 * pad
    lh = size * 1.32
    h = lh * len(L) + pad
    x0 = x - w / 2 if anchor == "middle" else x
    b = _r(round(x0, 1), round(y - h / 2, 1), round(w, 1), round(h, 1), c, 7, 1.6)
    for i, (s, m, col, wt) in enumerate(L):
        b += _t(round(x0 + w / 2, 1), round(y - h / 2 + pad / 2 + lh * (i + 1) - size * 0.3, 1), s, size, wt, col, mono=m)
    return b


def mark(x, y, ok=True, r=11):
    """a round ✓ / ✗ badge"""
    c = OKC if ok else BADC
    p = f"M{x-5},{y} l3.5,4 l6.5,-8" if ok else f"M{x-4.5},{y-4.5} l9,9 M{x+4.5},{y-4.5} l-9,9"
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/><path d="{p}" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round"/>'


def boom(x, y, r=16):
    pts = []
    import math
    for i in range(16):
        a = math.pi * 2 * i / 16
        rr = r if i % 2 == 0 else r * 0.5
        pts.append(f"{x + rr * math.cos(a):.1f},{y + rr * math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="#ffd54f" stroke="{BADC}" stroke-width="2"/>'


# ---------------------------------------------------------------- icons: devices and computers
def icon(kind, x, y, s=1.0, on=False):
    """a small drawing of a device, centered on (x, y)"""
    st = HL if on else NAVY
    sw = 2.6 if on else 2
    if kind in ("pc", "laptop"):
        return (f'<rect x="{x-20*s}" y="{y-16*s}" width="{40*s}" height="{26*s}" rx="{3*s}" fill="#e8f1f3" stroke="{st}" stroke-width="{sw}"/>'
                f'<rect x="{x-15*s}" y="{y-11*s}" width="{30*s}" height="{16*s}" rx="1" fill="#bfdde3"/>'
                f'<path d="M{x-26*s},{y+14*s} h{52*s} l{-4*s},{5*s} h{-44*s} z" fill="{st}"/>')
    if kind == "phone":
        return (f'<rect x="{x-11*s}" y="{y-19*s}" width="{22*s}" height="{38*s}" rx="{4*s}" fill="#e8f1f3" stroke="{st}" stroke-width="{sw}"/>'
                f'<rect x="{x-7*s}" y="{y-13*s}" width="{14*s}" height="{23*s}" fill="#bfdde3"/><circle cx="{x}" cy="{y+14*s}" r="{2*s}" fill="{st}"/>')
    if kind == "tv":
        return (f'<rect x="{x-22*s}" y="{y-15*s}" width="{44*s}" height="{28*s}" rx="{2*s}" fill="#e8f1f3" stroke="{st}" stroke-width="{sw}"/>'
                f'<path d="M{x-8*s},{y+18*s} h{16*s} M{x},{y+13*s} v{5*s}" stroke="{st}" stroke-width="{sw}"/>')
    if kind == "server":
        b = f'<rect x="{x-16*s}" y="{y-22*s}" width="{32*s}" height="{44*s}" rx="{3*s}" fill="#e8f1f3" stroke="{st}" stroke-width="{sw}"/>'
        for k in range(3):
            yy = y - 14 * s + k * 13 * s
            b += f'<rect x="{x-11*s}" y="{yy}" width="{22*s}" height="{8*s}" rx="1.5" fill="#bfdde3"/><circle cx="{x+7*s}" cy="{yy+4*s}" r="{1.6*s}" fill="{OKC}"/>'
        return b
    if kind in ("hub", "switch"):
        c = BLUE if kind == "hub" else RED
        b = f'<rect x="{x-30*s}" y="{y-14*s}" width="{60*s}" height="{28*s}" rx="{6*s}" fill="{c[1]}" stroke="{HL if on else c[1]}" stroke-width="{3 if on else 1}"/>'
        if kind == "hub":
            for k in range(5):
                b += f'<circle cx="{x-18*s+k*9*s}" cy="{y}" r="{2.4*s}" fill="#fff"/>'
        else:
            b += (f'<path d="M{x-17*s},{y-5*s} h{30*s} m{-6*s},{-4*s} l{6*s},{4*s} l{-6*s},{4*s}" fill="none" stroke="#fff" stroke-width="{2*s}"/>'
                  f'<path d="M{x+17*s},{y+5*s} h{-30*s} m{6*s},{-4*s} l{-6*s},{4*s} l{6*s},{4*s}" fill="none" stroke="#fff" stroke-width="{2*s}"/>')
        return b
    if kind == "router":
        b = f'<circle cx="{x}" cy="{y}" r="{19*s}" fill="#d79b00" stroke="{HL if on else "#a86f00"}" stroke-width="{3 if on else 1.5}"/>'
        for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            b += f'<path d="M{x+dx*4*s},{y+dy*4*s} l{dx*8*s},{dy*8*s}" stroke="#fff" stroke-width="{2.2*s}" marker-end="url(#f3-wh)"/>'
        return b.replace('marker-end="url(#f3-wh)"', "") + "".join(
            f'<path d="M{x+dx*12*s-dx*4*s},{y+dy*12*s} l{dx*4*s},0 l0,{-dy*4*s}" fill="none" stroke="#fff" stroke-width="{2*s}"/>'
            for dx, dy in ((1, 1), (1, -1), (-1, 1), (-1, -1)))
    if kind == "ap":
        b = (f'<rect x="{x-22*s}" y="{y-4*s}" width="{44*s}" height="{18*s}" rx="{5*s}" fill="#6c8ebf" stroke="{HL if on else "#4a6d9e"}" stroke-width="{3 if on else 1}"/>'
             f'<path d="M{x},{y-4*s} v{-10*s}" stroke="#4a6d9e" stroke-width="{2.4*s}"/>')
        for r in (7, 13):
            b += f'<path d="M{x-r*s},{y-16*s-r*0.2*s} a{r*s},{r*s} 0 0 1 {2*r*s},0" fill="none" stroke="#6c8ebf" stroke-width="{2*s}"/>'
        b += f'<circle cx="{x}" cy="{y-15*s}" r="{2.4*s}" fill="#4a6d9e"/>'
        return b
    if kind == "cloud":
        return (f'<path d="M{x-34*s},{y+14*s} a{14*s},{14*s} 0 0 1 {4*s},{-27*s} a{18*s},{18*s} 0 0 1 {32*s},{-8*s} a{16*s},{16*s} 0 0 1 {28*s},{12*s}'
                f' a{12*s},{12*s} 0 0 1 {2*s},{23*s} z" fill="#eef4f7" stroke="{st}" stroke-width="{sw}"/>')
    raise ValueError(kind)


def node(kind, x, y, name=None, addr=None, s=1.0, on=False, below=True, nsize=15, asize=13, extra=None, ncolor=INK):
    """an icon with its name and its address(es) under (or above) it"""
    h = {"pc": 20, "laptop": 20, "phone": 20, "tv": 19, "server": 23, "hub": 15, "switch": 15, "router": 20, "ap": 15, "cloud": 16}[kind] * s
    b = icon(kind, x, y, s, on)
    lines = ([(name, nsize, 700, ncolor, False)] if name else []) + [(a, asize, 400, MUTED, True) for a in ([addr] if isinstance(addr, str) else (addr or []))]
    if extra:
        lines += [extra]
    if below:
        yy = y + h + nsize + 2
        for s_, sz, wt, col, mono in lines:
            b += _t(x, round(yy, 1), s_, sz, wt, col, mono=mono)
            yy += sz + 4
    else:
        yy = y - h - 8
        for s_, sz, wt, col, mono in reversed(lines):
            b += _t(x, round(yy, 1), s_, sz, wt, col, mono=mono)
            yy -= sz + 4
    return b


def area(x, y, w, h, name, c=NAVY, right=False):
    """a dashed rounded area: a network"""
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="#f6fafb" stroke="{c}" stroke-width="1.6" stroke-dasharray="7 5"/>'
            + _t(x + w - 12 if right else x + 12, y + 20, name, 14, 700, c, a="end" if right else "start", mono=False))


def rport(x, y, name, ip, note=None, on=False):
    """a network card of a router: a dark port on the wire, on the border of its network, its address below
    (as on the slides: one card in each network); draw it after the trails"""
    c = HL if on else "#37474f"
    b = _r(x - 22, y - 11, 44, 22, (c, c), 4, 1) + _t(x, y + 5, name, 13, 800, "#fff")
    iw = tw(ip, 13, True) + 8
    b += f'<rect x="{x - iw / 2:.1f}" y="{y + 14}" width="{iw:.1f}" height="18" fill="#fff"/>' + _t(x, y + 28, ip, 13, 600, HL if on else INK, mono=True)
    if note:
        nw = tw(note, 12) + 8
        b += f'<rect x="{x - nw / 2:.1f}" y="{y + 33}" width="{nw:.1f}" height="16" fill="#fff"/>' + _t(x, y + 45, note, 12, 400, MUTED)
    return b


def wire(a, b, c="#8a9aa0", w=3, dash=None):
    return _l(a[0], a[1], b[0], b[1], c, w, dash)


def radio(a, b):
    return _l(a[0], a[1], b[0], b[1], "#6c8ebf", 2, "5 5")


def trail(pts, color="hl", w=4.5):
    """the path a frame took, a thick colored line over the wires, with an arrow head"""
    return _a(pts, color, w)


# ---------------------------------------------------------------- field bars: frames, packets, segments
def fields_svg(fields, on=(), groups=(), width=760, inner=None, note=None):
    """fields: (key, name, size, width weight, example); on: the keys in focus; groups: (first key, last key, label)"""
    x0, y0, hgt = 6, 46, 64
    total = sum(f[3] for f in fields)
    scale = (width - 12) / total
    xs, x = {}, x0
    b = ""
    for key, name, size, wt, ex, *rest in fields:
        w = wt * scale
        xs[key] = (x, w)
        c = rest[0] if rest else BLUE
        focus = key in on
        dim = bool(on) and not focus
        fill = c[0] if not dim else "#f3f5f6"
        st = HL if focus else (c[1] if not dim else "#c7d0d4")
        b += f'<rect x="{x:.1f}" y="{y0}" width="{w:.1f}" height="{hgt}" fill="{fill}" stroke="{st}" stroke-width="{3 if focus else 1.2}"/>'
        col = INK if not dim else "#9aa9ae"
        if inner and inner[0] == key:
            x += w
            continue
        b += _t(round(x + w / 2, 1), y0 + 22, name, 14 if w > 70 else 13, 700, col)
        b += _t(round(x + w / 2, 1), y0 + 40, size, 12, 400, MUTED if not dim else "#b5c0c4")
        if ex:
            b += _t(round(x + w / 2, 1), y0 + 57, ex, 12.5, 600, (HL if focus else NAVY) if not dim else "#b5c0c4", mono=True)
        x += w
    if inner:
        k, label, c = inner
        ix, iw = xs[k]
        b += f'<rect x="{ix+6:.1f}" y="{y0+8}" width="{iw-12:.1f}" height="{hgt-16}" rx="6" fill="{c[0]}" stroke="{c[1]}" stroke-width="1.4" stroke-dasharray="5 4" opacity="{0.35 if (on and k not in on) else 1}"/>'
        b += _t(round(ix + iw / 2, 1), y0 + 30, label[0], 13, 700, INK if not (on and k not in on) else "#9aa9ae")
        b += _t(round(ix + iw / 2, 1), y0 + 47, label[1], 12, 400, MUTED if not (on and k not in on) else "#b5c0c4")
    for a, z, label in groups:
        gx = xs[a][0]
        gw = xs[z][0] + xs[z][1] - gx
        b += f'<path d="M{gx+2:.1f},{y0-8} v-8 h{gw-4:.1f} v8" fill="none" stroke="{MUTED}" stroke-width="1.4"/>'
        b += _t(round(gx + gw / 2, 1), y0 - 22, label, 13, 600, MUTED)
    if note:
        b += _t(width / 2, y0 + hgt + 24, note, 13, 400, MUTED, it=True)
    return svgfig(width, y0 + hgt + (34 if note else 10), b, "the fields of the header")


def kv(items):
    """a compact legend under a picture: `value` meaning · `value` meaning"""
    return '<p class="sc-kv">' + "".join(f"<span>{md(a)} {md(b)}</span>" for a, b in items) + "</p>"


def xtable(rows, head=None):
    """a small explanation table under a picture: (term, meaning) in md"""
    h = f"<tr><th>{md(head[0])}</th><th>{md(head[1])}</th></tr>" if head else ""
    return '<table class="t sc-xt">' + h + "".join(f"<tr><td>{md(a)}</td><td>{md(b)}</td></tr>" for a, b in rows) + "</table>"


# ---------------------------------------------------------------- the scene widget (steps drawn here, shown by widgets09.js)
def scene(title, sub, scs, badge=None, layout="side", cap=None):
    """scs: [(label, [(explanation md, picture html, state html or None), ...]), ...]
    layout: side (the state next to the picture when there is room) or stack (under it)"""
    labels = "|".join(l for l, _ in scs)
    tpl = []
    for i, (_, steps) in enumerate(scs):
        for x, pic, st in steps:
            body = f'<div class="sc-pic">{pic}</div>' + (f'<div class="sc-st">{st}</div>' if st else "")
            tpl.append(f'<template data-s="{i}" data-x="{E(md(x))}" data-c="{"two" if st else "one"}">{body}</template>')
    a = f' data-title="{E(title)}" data-sub="{E(md(sub))}" data-labels="{E(labels)}" data-layout="{layout}"'
    if badge:
        a += f' data-badge="{E(badge)}"'
    if cap:  # the largest height of the pictures, in px (the widget must fit a laptop screen)
        a += f' style="--cap:{cap}px"'
    return f'<div data-w="scene"{a}>' + "".join(tpl) + "</div>"


def w(name, **attrs):
    a = "".join(f' data-{k}="{E(str(v))}"' for k, v in attrs.items())
    return f'<div data-w="{name}"{a}></div>'


def term(missions, title, sub=None, cmds=(), side="net", variant=None):
    """the demo terminal of the lecture: the laptop, with the network commands"""
    a = f' data-profile="09" data-side="{side}" data-title="{E(title)}"' + (f' data-missions="{missions}"' if missions else "")
    # a one-line subtitle (the default of shell-ui.js takes two lines): the widget must fit a laptop screen
    a += f' data-sub="{E(md(sub or "A simulated laptop: only the commands of the lecture work. `reset` starts again."))}"'
    if cmds:
        a += f' data-cmds="{E("|".join(cmds))}"'
    if variant:
        a += f' data-variant="{variant}"'
    return f'<div data-w="shell"{a}></div>'


def term_out(lines, marks=None, caption=None):
    """a static terminal, like sh(), with parts of the output marked: marks {line: [substring, ...]}"""
    marks = marks or {}
    out = []
    for i, l in enumerate(lines.strip("\n").split("\n"), 1):
        if l.startswith("$ "):
            cmd, _, com = l[2:].partition("  #")
            out.append(f'<span class="p">$</span> <span class="c">{color_cmd(cmd)}</span>' + (f'<span class="k">  #{E(com)}</span>' if com else ""))
            continue
        s = E(l)
        for sub_ in marks.get(i, []):
            s = s.replace(E(sub_), f'<mark class="nm">{E(sub_)}</mark>', 1)
        out.append(f'<span class="o">{s}</span>')
    pre = '<pre class="sh">' + "\n".join(out) + "</pre>"
    return f'<figure class="f" style="padding:0;border:0">{pre}<figcaption>{md(caption)}</figcaption></figure>' if caption else pre


def xp(rows):
    """what the marked parts mean: a compact table"""
    return table(["", "Means"], rows, "k xp")


# ================================================================ 01 the Internet
def fig_timeline():
    ev = [("1969", "USA", ["ARPANET: 4 computers,", "universities and SRI"]), ("1971", "USA", ["e-mail, the @ sign", "(Ray Tomlinson)"]),
          ("1974", "USA", ["TCP is designed", "(Vint Cerf, Bob Kahn)"]), ("1983", "USA", ["ARPANET switches to", "TCP/IP; DNS invented"]),
          ("1991", "Switzerland", ["the World Wide Web", "(Tim Berners-Lee, CERN)"]), ("1995", "USA", ["the commercial Internet,", "NSFNET retired"]),
          ("2011", "worldwide", ["the IPv4 addresses", "run out (IANA)"])]
    b = _a([(10, 130), (812, 130)], "grey", 2.4)
    for i, (y, c, txt) in enumerate(ev):
        x = 92 + i * 106
        up = i % 2 == 0
        b += f'<circle cx="{x}" cy="130" r="6" fill="{NAVY}"/>'
        b += _l(x, 124 if up else 136, x, 92 if up else 168, NAVY, 1.2)
        b += tag(x, 84 if up else 176, [c], (HLBG, HL), 12.5, pad=6)
        y0 = 22 if up else 214
        b += _t(x, y0, y, 16, 800, NAVY)
        for k, line in enumerate(txt):
            b += _t(x, y0 + 17 + k * 16, line, 13, 600 if k == 0 else 400, INK if k == 0 else MUTED)
    return svgfig(820, 262, b, "A short history of the Internet, from ARPANET in 1969 to the end of the IPv4 addresses in 2011")


def fig_layers():
    osi = [("7. Application", "application"), ("6. Presentation", "application"), ("5. Session", "application"), ("4. Transport", "transport"),
           ("3. Network", "network"), ("2. Data Link", "link"), ("1. Physical", "physical")]
    tcp = [("Application", "application", "HTTP, DNS, SSH"), ("Transport", "transport", "TCP, UDP"), ("Internet", "network", "IP"), ("Link", "link", "Ethernet, Wi-Fi")]
    now = [("5. Application", "application"), ("4. Transport", "transport"), ("3. Network", "network"), ("2. Data Link", "link"), ("1. Physical", "physical")]
    X = (10, 300, 590)
    W, Y0, H = 170, 44, 245
    b = ""
    def stack(x, rows, title, sub=None):
        o = _t(x + W / 2, 18, title, 14.5, 800, NAVY) + (_t(x + W / 2, 35, sub, 12.5, 400, MUTED) if sub else "")
        h = H / len(rows)
        for i, r in enumerate(rows):
            c = LAYER[r[1]]
            y = Y0 + i * h
            o += f'<rect x="{x}" y="{y:.1f}" width="{W}" height="{h:.1f}" fill="{c[0]}" stroke="{c[1]}" stroke-width="1.4"/>'
            if len(r) > 2:
                o += _t(x + W / 2, round(y + h / 2 - 2, 1), r[0], 15, 700) + _t(x + W / 2, round(y + h / 2 + 15, 1), r[2], 12.5, 400, MUTED)
            else:
                o += _t(x + W / 2, round(y + h / 2 + 5, 1), r[0], 14.5, 700)
        return o
    def band(x1, n1, a1, z1, x2, n2, a2, z2, layer):
        h1, h2 = H / n1, H / n2
        c = LAYER[layer]
        pts = [(x1 + W, Y0 + a1 * h1), (x2, Y0 + a2 * h2), (x2, Y0 + (z2 + 1) * h2), (x1 + W, Y0 + (z1 + 1) * h1)]
        return f'<polygon points="{" ".join(f"{p:.1f},{q:.1f}" for p, q in pts)}" fill="{c[0]}" opacity=".55" stroke="{c[1]}" stroke-width=".8"/>'
    for a1, z1, a2, z2, l in ((0, 2, 0, 0, "application"), (3, 3, 1, 1, "transport"), (4, 4, 2, 2, "network"), (5, 6, 3, 3, "link")):
        b += band(X[0], 7, a1, z1, X[1], 4, a2, z2, l)
    for a1, z1, a2, z2, l in ((0, 0, 0, 0, "application"), (1, 1, 1, 1, "transport"), (2, 2, 2, 2, "network"), (3, 3, 3, 4, "link")):
        b += band(X[1], 4, a1, z1, X[2], 5, a2, z2, l)
    b += stack(X[0], osi, "OSI model", "ISO, 1984, 7 layers") + stack(X[1], tcp, "TCP/IP", "RFC 1122, 1989, 4 layers") + stack(X[2], now, "In practice", "5 layers: this lecture")
    return svgfig(770, 300, b, "OSI has 7 layers, TCP/IP 4; in practice we use 5: TCP/IP with the link layer split in data link and physical")


# ---- encapsulation and decapsulation, one step per action: (device, explanation, the state of each layer row)
LAYER_ROWS = [("application", "Application"), ("transport", "Transport"), ("network", "Network"), ("link", "Data Link"), ("physical", "Physical")]
DEV_NAMES = {"laptop": ["browser", "TCP", "IP", "Wi-Fi card", "radio"], "router-in": ["–", "–", "IP + routing", "Wi-Fi card", "radio"],
             "router-out": ["–", "–", "IP + routing", "WAN card", "cable"], "server": ["nginx", "TCP", "IP", "Ethernet card", "cable"]}
_DATA, _TCP, _FCS = ("data", "GET / HTTP/1.1", GREEN, 130), ("TCP header", "51034 → 443", AMBER, 120), ("FCS", "CRC", RED, 48)
_IP = ("IP header", "192.168.1.105 → 141.85.220.33", ORANGE, 228)


def _ip(v=None):
    return ("IP header", v or _IP[1], ORANGE, 228)


def _mac(v, name="Ethernet header"):
    return (name, v, RED, 150)


def enc_pic(dev, rows, cur, bits=None):
    """rows: {layer index: [(unit, state)]} with state '' | 'new' (just added) | 'check' (read now) | 'gone' (removed);
    bits: (text color, caption) for the physical row"""
    LW, RH, GAP, Y0 = 150, 40, 4, 2
    names = DEV_NAMES[dev]
    b = ""
    for i, (layer, title) in enumerate(LAYER_ROWS):
        y = Y0 + i * (RH + GAP)
        c = LAYER[layer]
        none = names[i] == "–"
        on = i == cur
        b += f'<rect x="0" y="{y}" width="{LW}" height="{RH}" rx="8" fill="{"#f3f5f6" if none else c[0]}" stroke="{HL if on else c[1]}" stroke-width="{3 if on else 1.2}" opacity="{.4 if none else 1}"/>'
        b += _t(LW / 2, y + 17, title, 14, 700, "#9aa9ae" if none else INK) + _t(LW / 2, y + 33, names[i], 12.5, 400, MUTED)
        x = LW + 14
        if i == 4 and bits:
            b += _t(x + 6, y + 20, "0110 1001 0011 1010 1100 0101 1001 0110 …", 15, 700, bits[0], a="start", mono=True) + _t(x + 6, y + 36, bits[1], 12.5, 400, MUTED, a="start")
            continue
        for (n, v, cc, ww), st in rows.get(i, []):
            gone = st == "gone"
            hot = st in ("new", "check")
            fill = "#f6f7f8" if gone else cc[0]
            stroke = HL if hot else ("#c7d0d4" if gone else cc[1])
            dash = ' stroke-dasharray="4 3"' if gone else ""
            b += f'<rect x="{x}" y="{y+2}" width="{ww}" height="{RH-4}" rx="5" fill="{fill}" stroke="{stroke}" stroke-width="{2.6 if hot else 1.2}"{dash}/>'
            b += _t(x + ww / 2, y + 16, n, 12.5, 700, "#a9b5b9" if gone else HL if hot else INK)
            b += _t(x + ww / 2, y + 31, v, 12, 600, "#b5c0c4" if gone else NAVY, mono=True)
            if st == "check":
                b += mark(x + ww - 4, y + 4, True, 8)
            x += ww
    return svgfig(LW + 700, Y0 + 5 * (RH + GAP) - 2, b, "The layers of a device and the headers each one adds or removes")


L_MAC = _mac("3c:a9:… → 70:b5:…", "Wi-Fi header")
R_MAC = _mac("a8:42:… → 2e:41:…")
S_MAC = _mac("c4:7d:… → 00:1e:…")
F = lambda *u: [(x, st) for x, st in u]
ENC = [
    # the laptop: down the stack
    ("laptop", "The browser wants a web page: `GET / HTTP/1.1`, for **nginx**, the web server at `141.85.220.33`.",
     enc_pic("laptop", {0: F((_DATA, "new"))}, 0)),
    ("laptop", "**TCP** adds its header: the **ports**, from `51034` (the browser) to `443` (nginx). Data + TCP header = a **segment**.",
     enc_pic("laptop", {0: F((_DATA, "")), 1: F((_TCP, "new"), (_DATA, ""))}, 1)),
    ("laptop", "**IP** adds its header: the **IP addresses**, from the laptop `192.168.1.105` to the server `141.85.220.33`, and a TTL of 64. A **packet**.",
     enc_pic("laptop", {0: F((_DATA, "")), 1: F((_TCP, ""), (_DATA, "")), 2: F((_ip(), "new"), (_TCP, ""), (_DATA, ""))}, 2)),
    ("laptop", "The Wi-Fi card puts the packet in a **frame**: the **MAC addresses**, from the laptop to the **home router** (the next device, not the server), and a checksum (FCS) at the end.",
     enc_pic("laptop", {0: F((_DATA, "")), 1: F((_TCP, ""), (_DATA, "")), 2: F((_ip(), ""), (_TCP, ""), (_DATA, "")), 3: F((L_MAC, "new"), (_ip(), ""), (_TCP, ""), (_DATA, ""), (_FCS, "new"))}, 3)),
    ("laptop", "The radio sends the whole frame as **bits**. Each layer only added a header: like an envelope inside an envelope.",
     enc_pic("laptop", {0: F((_DATA, "")), 1: F((_TCP, ""), (_DATA, "")), 2: F((_ip(), ""), (_TCP, ""), (_DATA, "")), 3: F((L_MAC, ""), (_ip(), ""), (_TCP, ""), (_DATA, ""), (_FCS, ""))}, 4, (HL, "the whole frame, as signals on the radio"))),
    # the home router: up to IP, then down again
    ("router-in", "The home router's Wi-Fi card turns the bits back into the frame. It computes the **FCS** again (✓ not damaged) and reads the **destination MAC** (✓ `70:b5:…`, its own), then **removes the frame** and gives the packet to IP.",
     enc_pic("router-in", {2: F((_ip(), ""), (_TCP, ""), (_DATA, "")), 3: F((L_MAC, "check"), (_ip(), ""), (_TCP, ""), (_DATA, ""), (_FCS, "check"))}, 3, (NAVY, "the frame of the laptop, received on the radio"))),
    ("router-in", "IP reads the **destination IP**: `141.85.220.33`, not one of its own. It subtracts 1 from the **TTL** (64 → 63) and looks in its **routing table**: send it to the provider's router. TCP and the data are **not opened**: a router stops at layer 3.",
     enc_pic("router-in", {2: F((_ip("TTL 63 · to 141.85.220.33"), "check"), (_TCP, ""), (_DATA, "")), 3: F((L_MAC, "gone"), (_ip(), ""), (_TCP, ""), (_DATA, ""), (_FCS, "gone"))}, 2, (NAVY, "the frame of the laptop, received on the radio"))),
    ("router-out", "Down again: the WAN card puts the **same packet** in a **new frame**, from its own MAC to the next router's, with a new FCS, and sends it on the cable. The MACs changed, the IPs did not. The 3 routers of the providers do the same.",
     enc_pic("router-out", {2: F((_ip("TTL 63 · same IPs"), ""), (_TCP, ""), (_DATA, "")), 3: F((R_MAC, "new"), (_ip("TTL 63 · same IPs"), ""), (_TCP, ""), (_DATA, ""), (_FCS, "new"))}, 3, (HL, "a new frame, as signals on the cable"))),
    # the server: up the stack
    ("server", "The server's card turns the bits into a frame: **FCS** ✓, **destination MAC** ✓ its own. The **Type** `0x0800` says *an IPv4 packet*: it **removes the frame** and gives the packet to IP.",
     enc_pic("server", {3: F((S_MAC, "check"), (_ip("TTL 60 · to 141.85.220.33"), ""), (_TCP, ""), (_DATA, ""), (_FCS, "check"))}, 3, (NAVY, "the frame of the last router, received on the cable"))),
    ("server", "IP reads the **destination IP**: `141.85.220.33` ✓, its own, so the packet stops here. The **Protocol** `6` says *a TCP segment*: IP **removes its header** and gives the segment to TCP.",
     enc_pic("server", {2: F((_ip("to 141.85.220.33 · protocol 6"), "check"), (_TCP, ""), (_DATA, "")), 3: F((S_MAC, "gone"), (_ip(), ""), (_TCP, ""), (_DATA, ""), (_FCS, "gone"))}, 2, (NAVY, "received on the cable"))),
    ("server", "TCP checks the segment, acknowledges it, and reads the **destination port**: `443` is the socket of **nginx**. It **removes its header** and hands the data to nginx.",
     enc_pic("server", {1: F((_TCP, "check"), (_DATA, "")), 2: F((_ip(), "gone"), (_TCP, ""), (_DATA, "")), 3: F((S_MAC, "gone"), (_ip(), "gone"), (_TCP, ""), (_DATA, ""), (_FCS, "gone"))}, 1, (NAVY, "received on the cable"))),
    ("server", "nginx reads exactly what the browser wrote: `GET / HTTP/1.1`. The browser and nginx talked; the layers below only carried the data, and each layer read only **its own** header.",
     enc_pic("server", {0: F((_DATA, "check")), 1: F((_TCP, "gone"), (_DATA, "")), 2: F((_ip(), "gone"), (_TCP, "gone"), (_DATA, "")), 3: F((S_MAC, "gone"), (_ip(), "gone"), (_TCP, "gone"), (_DATA, ""), (_FCS, "gone"))}, 0, (NAVY, "received on the cable"))),
]


def enc_where(step):
    """under the encapsulation picture: on which device each step happens (all the steps, the current one in orange),
    and the way the data went so far"""
    Y = 34
    D = [("laptop", 92, "laptop", "5 layers", [1, 2, 3, 4, 5]), ("ap", 300, "home router", "layers 1 – 3", [6, 7, 8]),
         ("router", 540, "3 routers", "layers 1 – 3", ["6 – 8 ×3"]), ("server", 770, "server", "5 layers", [9, 10, 11, 12])]
    here = 0 if step <= 4 else 1 if step <= 7 else 3
    b = radio((118, Y), (276, Y)) + wire((324, Y + 4), (516, Y)) + wire((564, Y), (750, Y))
    b += _t(197, Y - 10, "Wi-Fi", 12.5, 600, MUTED) + _t(420, Y - 10, "cable", 12.5, 600, MUTED) + _t(655, Y - 10, "cables", 12.5, 600, MUTED)
    legs = [((120, Y + 8), (272, Y + 8)), ((328, Y + 8), (512, Y + 8)), ((568, Y + 8), (746, Y + 8))]
    done = 0 if step < 4 else 1 if step < 7 else 2 if step == 7 else 3
    for k in range(done):
        last = k == done - 1 and step in (4, 7, 8)
        b += _a(list(legs[k]), "hl" if last else "grey", 3.4 if last else 2.4)
    cur = step + 1
    for k, (kind, x, name, sub, steps) in enumerate(D):
        on = k == here
        b += icon(kind, x, Y, 0.9, on=on) + f'<text x="{x}" y="{Y + 38}" text-anchor="middle" style="font:{800 if on else 700} 14.5px system-ui,sans-serif" fill="{HL if on else INK}">{name} <tspan style="font-weight:400" fill="{MUTED}">· {sub}</tspan></text>'
        ws = [26 if isinstance(n, int) else 70 for n in steps]
        x0 = x - (sum(ws) + 4 * (len(ws) - 1)) / 2
        for n, w_ in zip(steps, ws):
            st = ("on" if n == cur else "done" if n < cur else "todo") if isinstance(n, int) else ("done" if cur >= 9 else "todo")
            c = {"on": (HL, "#fff", HL), "done": ("#00838f", "#fff", "#00838f"), "todo": ("#fff", "#9aa9ae", "#c7d0d4")}[st]
            b += f'<rect x="{x0:.1f}" y="{Y + 48}" width="{w_}" height="22" rx="11" fill="{c[0]}" stroke="{c[2]}" stroke-width="1.4"/>' + _t(round(x0 + w_ / 2, 1), Y + 63.5, str(n), 13, 800, c[1])
            x0 += w_ + 4
    return svgfig(850, Y + 76, b, "The devices on the way and the steps on each: the laptop (1 to 5), the home router (6 to 8), the other routers (the same), the server (9 to 12)")


def fig_os():
    X0, Wd = 150, 470
    b = ""
    rows = []
    # applications
    for i, n in enumerate(["Firefox", "Thunderbird", "ssh"]):
        b += _r(X0 + i * Wd / 3 + 4, 8, Wd / 3 - 8, 40, GREEN, 6, 1.4) + _t(X0 + i * Wd / 3 + Wd / 6, 33, n, 14.5, 700)
    b += _l(X0 - 140, 62, X0 + Wd, 62, "#9aa9ae", 1.4, "6 5")
    b += tag(X0 + Wd / 2, 62, ["sockets (POSIX): socket(), connect(), send(), recv()"], ("#fff", NAVY), 12.5, mono=True, pad=6)
    b += _r(X0 + 4, 80, Wd - 8, 40, AMBER, 6, 1.4) + _t(X0 + Wd / 2, 99, "Transport", 14.5, 700) + _t(X0 + Wd / 2, 114, "TCP, UDP", 12.5, 400, MUTED)
    b += _r(X0 + 4, 120, Wd - 8, 40, ORANGE, 6, 1.4) + _t(X0 + Wd / 2, 139, "Network", 14.5, 700) + _t(X0 + Wd / 2, 154, "IP, the routing table", 12.5, 400, MUTED)
    for i, (d, ifc) in enumerate((("e1000e", "enp0s31f6"), ("iwlwifi", "wlp2s0"))):
        b += _r(X0 + i * Wd / 2 + 4, 172, Wd / 2 - 8, 44, RED, 6, 1.4) + _t(X0 + i * Wd / 2 + Wd / 4, 191, d, 14, 700, mono=True) + _t(X0 + i * Wd / 2 + Wd / 4, 208, "interface " + ifc, 12.5, 400, MUTED)
    b += _l(X0 - 140, 228, X0 + Wd, 228, "#9aa9ae", 1.4, "6 5")
    for i, (k, n) in enumerate((("pc", "Ethernet card"), ("ap", "Wi-Fi card"))):
        b += _r(X0 + i * Wd / 2 + 4, 240, Wd / 2 - 8, 52, BLUE, 6, 1.4) + _t(X0 + i * Wd / 2 + Wd / 4, 271, n, 14.5, 700)
    for y, t1 in ((22, "user space"), (78, "kernel"), (244, "hardware")):
        pass
    b += _t(X0 - 14, 56, "user space", 12.5, 700, TEAL, a="end", it=True) + _t(X0 - 14, 78, "kernel", 12.5, 700, TEAL, a="end", it=True)
    b += _t(X0 - 14, 222, "kernel", 12.5, 700, TEAL, a="end", it=True) + _t(X0 - 14, 244, "hardware", 12.5, 700, TEAL, a="end", it=True)
    for y, n in ((32, "Application"), (104, "Transport"), (144, "Network"), (198, "Data Link"), (270, "Physical + Data Link")):
        b += _t(X0 - 14, y, n, 13, 400, MUTED, a="end")
    bx = X0 + Wd + 14
    for y1, y2, t1, t2 in ((8, 48, "applications", "programs, in user space"), (80, 160, "the network stack", "one for all the cards"), (172, 216, "the drivers", "one for each card"), (240, 292, "the cards", "build and check the frames")):
        b += f'<path d="M{bx},{y1+2} h6 V{y2-2} h-6" fill="none" stroke="{HL}" stroke-width="1.6"/>'
        b += _t(bx + 14, (y1 + y2) / 2 - 2, t1, 13.5, 700, HL, a="start") + _t(bx + 14, (y1 + y2) / 2 + 15, t2, 12.5, 400, MUTED, a="start")
    return svgfig(X0 + Wd + 200, 300, b, "The network in the operating system: applications use sockets, the kernel has one network stack and one driver for each card")


page = chapter("internet", "The Internet", "A network of networks, its services and its layers", 16)
page("history", "A network of networks", "The Internet", J(
    why("Every command of this lecture (`ping`, `ip`, `nmcli`, `tcpdump`) shows one piece of the same journey: your data, cut into pieces, carried from your card, through routers, to a program on another computer. Knowing the pieces tells you **where** a problem is."),
    fig(fig_timeline(), "From four computers in 1969 to the end of the IPv4 addresses"),
    duo(p("ARPANET was funded by the US Department of Defense: four computers, **no central computer**, so it worked even if a link failed. Today the Internet is the networks of companies, universities and providers, **joined by routers**."),
        note("📜 The first message: `LO`", "29 October 1969: UCLA logs in to SRI and types `LOGIN`. `L` arrives, `O` arrives, at `G` the SRI computer crashes. The first ARPANET message was `LO`.", "blue")),
))
page("services", "Services: a server waits, a client asks", "Internet services", J(
    p("Think of the Internet as a highway: the **roads and junctions** are the infrastructure (cables, radio, routers), the **places** at the ends are the services you use (a shop, a post office), the **vans** carry your data, in pieces."),
    table(["Service", "Protocol", "Client", "Server"], [
        ("🌐 Web", "HTTP(S)", "Firefox, `curl`", "`nginx`, Apache"), ("✉️ e-mail", "SMTP, IMAP", "Thunderbird", "Postfix, Dovecot"),
        ("⌨️ remote shell", "SSH", "`ssh`", "`sshd`"), ("📖 names", "DNS", "`host`, `dig`", "BIND, Unbound"),
        ("📁 file transfer", "SFTP", "`sftp`, FileZilla", "`sshd`"), ("🕒 time", "NTP", "`chronyc`", "`chronyd`, `ntpd`")]),
    p("A **server** is a program that waits for requests; a **client** sends them. The Web is one service of the Internet, not the Internet itself."),
    quiz("Which one is a **server** program?", ["`ssh`", "`curl`", "`sshd`", "Firefox"], 2,
         "`sshd` (the `d` is for *daemon*) waits for connections; `ssh`, `curl` and Firefox are clients: they send the requests."),
))
page("layers", "Five layers, one job each", "OSI and TCP/IP", J(
    p("The network is cut into **layers**: each one does one job and offers a standard service to the layer above. OSI (a standard of 1984) has 7 layers; TCP/IP, which already ran the Internet in 1983, has 4. We use **5**: TCP/IP with the link layer split in two."),
    fig(fig_layers()),
    table(["Layer", "Its job", "Its address", "What it sends", "A device"], [
        ("5 · Application", "what the program needs: web pages, e-mail, names", "a name: `upb.ro`", "messages", "–"),
        ("4 · Transport", "delivers data from a **program** to a **program**", "a **port**: `443`", "segments", "–"),
        ("3 · Network", "finds the way **between networks**", "an **IP address**: `141.85.220.33`", "packets", "router"),
        ("2 · Data Link", "sends to a device **in the same network**", "a **MAC address**: `3c:a9:f4:5e:21:7b`", "frames", "switch, access point"),
        ("1 · Physical", "sends **bits** as signals: electricity, light, radio", "–", "bits", "cable, hub")]),
    note("The layers can be swapped", "Firefox, TCP and IP do not change when the laptop uses an Ethernet card, a Wi-Fi card or a 4G modem; and they work the same over IPv4 or IPv6. Like a van: it needs a road, not a particular road.", "blue"),
))
page("encap", "Down the stack, and up again", "Encapsulation", J(
    p("To send, the data goes **down** the layers of the laptop: each one adds its **header** in front of what it got from above. The other computer goes **up** and removes them, in reverse order."),
    scene("From the browser to nginx", "Down the laptop, through the home router, up the server: one step per action; under it, the device where it happens.", [("A web request", [(x, pic, enc_where(i)) for i, (dev, x, pic) in enumerate(ENC)])], layout="stack"),
    p("A header drawn **dashed and grey** was removed by the layer that read it. Each layer talks to **the same layer** on the other side: the browser to nginx, TCP to TCP (ports), IP to IP (addresses), the cards to the next card (MACs, hop by hop)."),
    quiz("The packet goes through 4 routers on its way to the server. What changes at every router?", ["the IP addresses", "the MAC addresses and the TTL", "the ports", "nothing"], 1,
         "Every router builds a **new frame** (new MAC addresses, for the next network) and subtracts 1 from the TTL; the IP addresses and the ports stay the same (except through NAT, later)."),
))
page("os", "The network in the operating system", "From the card to the applications", J(
    fig(fig_os(), "Two cards, two drivers, one network stack, many applications"),
    ul("each card has its own **driver**, which turns it into a **network interface**: `enp0s31f6`, `wlp2s0` (see `ip link`)",
       "the kernel has **one** network stack (TCP, UDP, IP): it picks the card with the **routing table**",
       "the applications only see **sockets**, from BSD Unix and part of POSIX (Windows has the similar *Winsock*): they do not know which card is used"),
    note("Protocols", "Firefox on Linux, Edge on Windows and Safari on an iPhone all talk to nginx on FreeBSD: every layer follows a **standard protocol** written in an RFC (HTTP: RFC 9110, TCP: RFC 9293, IP: RFC 791), so any implementation talks to any other.", "blue"),
    quiz("A laptop switches from Wi-Fi to an Ethernet cable. What has to change in Firefox?", ["Firefox must be restarted", "nothing: Firefox uses sockets, the kernel picks the card", "Firefox must load the Ethernet driver", "the TCP of Firefox"], 1,
         "The applications see only sockets; the drivers and the network stack are in the kernel, which uses the routing table to choose the card."),
))

# ================================================================ 02 link layer
def fig_mac():
    b = ""
    for i, by in enumerate(("3c", "a9", "f4", "5e", "21", "7b")):
        c = ("#e3f0f5", NAVY) if i < 3 else (HLBG, HL)
        x = 20 + i * 70
        b += _r(x, 40, 54, 46, c, 7, 1.8) + _t(x + 27, 70, by, 21, 800, INK, mono=True)
        if i < 5:
            b += _t(x + 62, 70, ":", 22, 800, MUTED)
    for x1, x2, c, t1, t2, top in ((20, 214, NAVY, "manufacturer", "(OUI, from the IEEE)", "24 bits"), (230, 424, HL, "card number", "(chosen by the maker)", "24 bits")):
        b += f'<path d="M{x1},{94} v6 H{x2} v-6 M{(x1+x2)/2},{100} v6" fill="none" stroke="{c}" stroke-width="1.8"/>'
        b += _t((x1 + x2) / 2, 124, t1, 14.5, 700, c) + _t((x1 + x2) / 2, 142, t2, 13, 400, MUTED) + _t((x1 + x2) / 2, 28, top, 13, 700, c)
    return svgfig(444, 150, b, "A MAC address: 48 bits, the first 24 name the manufacturer, the last 24 the card")


IPLINK = """$ ip -br link  # -br: brief, one line for each card
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
enp0s31f6        DOWN           8c:16:45:a2:3b:91 <NO-CARRIER,BROADCAST,MULTICAST,UP>
wlp2s0           UP             3c:a9:f4:5e:21:7b <BROADCAST,MULTICAST,UP,LOWER_UP>"""

page = chapter("link", "Network cards and MAC addresses", "The link layer: what connects a computer to a network", 10)
page("nic", "The network card and its MAC address", "Link layer", J(
    p("A **network card** (*NIC*) connects the computer to a network: a cable (**Ethernet**), radio waves (**Wi-Fi**) or the mobile network (**4G / 5G**). It sends and receives **frames**, blocks of bytes, and it has a hardware address: the **MAC address**."),
    duo(fig(fig_mac()) + sh("$ cat /sys/class/net/wlp2s0/address\n3c:a9:f4:5e:21:7b"),
        ul("**48 bits** (6 bytes), written in hexadecimal",
           "set by the manufacturer, unique by default; software can change it (phones use a **random** MAC for each Wi-Fi network, for privacy)",
           "`ff:ff:ff:ff:ff:ff` is the **broadcast** address: a frame for everyone in the network",
           "it only makes sense **in the local network**: it never leaves it")),
))
page("iplink", "`ip -br link`: the cards Linux sees", "Network interfaces", J(
    p("Linux calls a card a **network interface**. `ip -br link` lists them, one per line:"),
    term_out(IPLINK, {3: ["DOWN", "NO-CARRIER"], 4: ["wlp2s0", "LOWER_UP"]}),
    table(["Part", "Means"], [
        ("`lo`", "*loopback*: a virtual card, the computer talks to itself; no MAC address (`00:00:…`)"),
        ("`en`… `wl`… `ww`…", "the **kind** of card: Ethernet, Wi-Fi (*wireless LAN*), a 4G / 5G modem (*wireless WAN*)"),
        ("`p0s31f6`, `p2s0`", "**where** it is plugged in: PCI bus 0, slot 31, function 6"),
        ("`UP`, `DOWN`", "the **state**: can the card send data now? `UNKNOWN`: the driver does not say"),
        ("`UP` · `LOWER_UP` · `NO-CARRIER`", "the flags: turned on · cable or radio connected · no signal (no cable)"),
        ("`BROADCAST`, `MULTICAST`", "what the card can do: send to everyone, send to a group")], "k"),
    quiz("`enp0s31f6  DOWN  8c:16:45:a2:3b:91 <NO-CARRIER,BROADCAST,MULTICAST,UP>`: what is wrong?", ["the card is turned off", "no cable is plugged in", "the card has no MAC address", "the driver is missing"], 1,
         "`UP` says the card is turned on; `NO-CARRIER` says there is no signal: no cable. So it cannot send: `DOWN`."),
))


# ================================================================ 03 Ethernet
ETH = [("dst", "Destination", "6 bytes", 150, "d4:5d:64:7e:10:2a", RED), ("src", "Source", "6 bytes", 150, "8c:16:45:a2:3b:91", RED),
       ("type", "Type", "2 bytes", 74, "0x0800", RED), ("data", "Payload", "46 – 1500 bytes", 270, None, RED), ("crc", "FCS", "4 bytes", 70, "CRC-32", RED)]
ETH_G = (("dst", "type", "header: 14 bytes"), ("data", "data", "payload: 46 – 1500 bytes"), ("crc", "crc", "trailer"))


def eth_step(on, rows=None, note=None, legend=None):
    return fields_svg(ETH, on, ETH_G, inner=("data", ("IPv4 packet", "from the network layer"), ORANGE), note=note) + (xtable(rows) if rows else "") + (kv(legend) if legend else "")


ETH_STEPS = [
    ("The whole frame: **64 to 1518 bytes**. A header, the data of the layer above, a trailer.", eth_step((), [("📡", "on the cable, the card first sends 8 more bytes (*preamble*) so the receiver can synchronize; Linux and Wireshark never see them")])),
    ("The **addresses**, like on an envelope: the **destination** (one card, or `ff:ff:ff:ff:ff:ff` for all: *broadcast*) and the **source**, so the receiver can answer. A card **ignores** the frames that are not for it.", eth_step(("dst", "src"))),
    ("**Type**: what is in the payload, a hint for the receiver.", eth_step(("type", "data"), legend=[("`0x0800`", "IPv4"), ("`0x86DD`", "IPv6"), ("`0x0806`", "ARP (find the MAC of an IP address)")])),
    ("The **payload** (46 – 1500 bytes, padded if shorter) and the **FCS**: a CRC-32 of the frame; the receiver computes it again, a different value means a damaged frame, **dropped**.", eth_step(("data", "crc"))),
]


def fig_mesh():
    import math
    b = ""
    pts = [(150 + 95 * math.cos(-math.pi / 2 + k * 2 * math.pi / 5), 128 + 95 * math.sin(-math.pi / 2 + k * 2 * math.pi / 5)) for k in range(5)]
    for i in range(5):
        for j in range(i + 1, 5):
            b += wire(pts[i], pts[j], "#9aa9ae", 1.8)
    for k, (x, y) in enumerate(pts):
        b += icon("pc", round(x, 1), round(y, 1), 0.8)
    b += _t(150, 262, "5 computers: 10 cables, 4 cards in each", 14, 700, BADC)
    cx, cy = 470, 128
    for k in range(5):
        x, y = cx + 95 * math.cos(-math.pi / 2 + k * 2 * math.pi / 5), cy + 95 * math.sin(-math.pi / 2 + k * 2 * math.pi / 5)
        b += wire((cx, cy), (x, y), "#9aa9ae", 2.4) + icon("pc", round(x, 1), round(y, 1), 0.8)
    b += icon("switch", cx, cy, 0.9)
    b += _t(470, 262, "a central device: 5 cables, 1 card in each", 14, 700, OKC)
    return svgfig(620, 272, b, "Five computers connected each to each need 10 cables; with a central device, 5")


page = chapter("ethernet", "Ethernet: frames, hubs and switches", "Networks with cables", 18)
page("frame", "The Ethernet frame: a letter in an envelope", "Ethernet frame", J(
    p("What the card sends on the cable: a **frame**, with the addresses in front and a check at the end."),
    scene("An Ethernet frame", "The fields, one group at a time.", [("Ethernet frame", [(x, pic, None) for x, pic in ETH_STEPS])], layout="stack"),
))
page("cables", "One cable, two ends", "More computers", J(
    p("A cable has **two ends**: it connects exactly two cards. Both can send **at the same time** (*full duplex*), like a road with two lanes. To connect more computers, each to each:"),
    fig(fig_mesh(), "n computers need n(n-1)/2 cables: 100 computers, 4950 cables and 99 cards each"),
    p("So every network uses a **central device**: one cable and one card for each computer. The first one was the **hub**, today it is the **switch**."),
))
page("hub", "A hub repeats everything, to everyone", "Hub", J(
    p("A **hub** works on layer 1: it copies the **bits** that come in on one port to **all** the other ports. It knows nothing about MAC addresses; each card keeps only its own frames."),
    w("star", dev="hub"),
    ul("only **one** computer can send at a time, and a card sends *or* receives (**half duplex**)",
       "two at once: the signals mix, a **collision**; the rule of the hub is *CSMA/CD*: listen before sending, stop on a collision, wait a random time, try again",
       "everyone receives every frame: **no privacy**, and the bandwidth is shared by all"),
))
page("switch", "A switch learns who is on each port", "Switch", J(
    p("A **switch** works on layer 2: it reads the frames. It keeps a **MAC table**, empty at the start, and learns from the **source** address of every frame which MAC is on which port."),
    w("star", dev="switch"),
    p("Now send your own frames: back and forth between two computers, then to someone new, and watch when the switch floods and when it knows the port."),
    w("star", dev="switch", mode="free"),
    ul("destination **known**: the frame goes out on **that port only**",
       "destination unknown, or `ff:ff:ff:ff:ff:ff`: out on **all** the other ports (*flooding*, a broadcast)",
       "each port is separate: **no collisions**; two frames for the same port wait in its **queue** (a full queue drops frames)"),
))
page("vs", "Hub vs switch", "Why every network uses switches", J(
    table(["", "Hub", "Switch"], [
        ("Layer", "1 (Physical): bits", "2 (Data Link): frames"), ("Knows MAC addresses", "no", "yes, its MAC table"),
        ("Sends a frame to", "all the ports", "the destination port"), ("Collisions", "yes, CSMA/CD", "no, frames wait in a queue"),
        ("Duplex", "half", "full"), ("Bandwidth", "shared by all", "for each port"), ("Privacy", "everyone sees everything", "each one sees its own frames")]),
    quiz("A switch has just been turned on. Ana sends a frame to Carla. Which ports does it go out on?", ["only Carla's port", "all ports except Ana's", "no port: Carla is unknown, the frame is dropped", "all ports, Ana's too"], 1,
         "The MAC table is empty: Carla is unknown, so the switch floods the frame on all the other ports. It learns Ana's port from the source address; Carla's port only when Carla sends something."),
    quiz("Which frame goes out on all ports of a switch, even with a full MAC table?", ["a frame to `ff:ff:ff:ff:ff:ff`", "a frame to the switch itself", "the first frame of every computer", "a frame with a bad FCS"], 0,
         "`ff:ff:ff:ff:ff:ff` is the broadcast address: a frame for everyone, so the switch sends it on every port, like a hub."),
))


# ================================================================ 04 Wi-Fi
def fig_ap():
    b = area(330, 10, 380, 210, "one network: Wi-Fi + Ethernet", NAVY, right=True)
    ap, sw = (430, 80), (610, 80)
    for p_ in ((90, 55), (90, 175), (250, 175)):
        b += radio(p_, ap)
    b += wire(ap, sw) + wire(sw, (560, 170)) + wire(sw, (660, 170))
    b += node("laptop", 90, 55, "laptop") + node("phone", 90, 175, "phone") + node("phone", 250, 175, "tablet")
    b += node("ap", 430, 80, "access point", "a bridge", on=True) + node("switch", 610, 80, "switch")
    b += node("pc", 560, 170, "PC") + node("pc", 660, 170, "printer")
    b += tag(250, 36, ["📶 HomeWiFi   🔑 ********"], (HLBG, HL), 13)
    return svgfig(720, 232, b, "Wireless devices connect to the access point; with a cable to the switch, the access point is a bridge: one network")


def sec_svg(kind):
    ap, ph, lp, p2 = (280, 76), (100, 176), (460, 176), (280, 262)
    b = radio(ph, ap) + radio(lp, ap) + radio(p2, ap)
    for r in (26, 44, 62):
        b += f'<circle cx="{ph[0]}" cy="{ph[1]}" r="{r}" fill="none" stroke="{HL}" stroke-width="1.2" stroke-dasharray="4 4" opacity="{1.1 - r / 80:.2f}"/>'
    b += icon("ap", *ap) + _t(ap[0] + 32, ap[1] + 8, "access point", 15, 700, a="start")
    b += node("phone", *ph, "phone") + node("laptop", *lp, "laptop") + icon("phone", *p2) + _t(p2[0] - 22, p2[1] + 6, "phone 2", 15, 700, a="end")
    clear = kind == "open"
    b += tag(178, 112, ["to laptop: " + ("hello" if clear else "x7#q%…")], ((HLBG, HL) if clear else ("#eef4f7", NAVY)), 14, mono=True)
    LIGHT = {"#b26a00": "#fff0d6", "#1565c0": "#e3eefb", "#2e7d46": "#e3f1e4", "#8e24aa": "#f3e5f5"}
    def key(x, y, name, c):
        w_ = 26 + len(name) * 9
        return _r(x, y, w_, 24, (LIGHT[c], c), 5, 1.6) + _t(x + w_ / 2, y + 17, name, 13, 800, c, mono=True)
    if kind == "wep":
        for (x, y) in ((ap[0] - 70, ap[1] - 44), (ph[0] + 22, ph[1] - 44), (lp[0] + 30, lp[1] - 44), (p2[0] + 22, p2[1] - 34)):
            b += key(x, y, "K", "#b26a00")
        b += tag(ap[0] + 160, ap[1] - 50, ["one key for everyone", "breakable in minutes"], ("#fff3bf", "#f08c00"), 12.5, bold_first=True)
    if kind == "wpa":
        b += key(ph[0] + 22, ph[1] - 44, "K1", "#1565c0") + key(lp[0] + 30, lp[1] - 44, "K2", "#2e7d46") + key(p2[0] + 22, p2[1] - 34, "K3", "#8e24aa")
        b += key(ap[0] + 30, ap[1] - 50, "K1", "#1565c0") + key(ap[0] + 82, ap[1] - 50, "K2", "#2e7d46") + key(ap[0] + 134, ap[1] - 50, "K3", "#8e24aa")
        b += tag(104, 30, ["first key: the Wi-Fi password", "then a key for each device"], GREY, 12.5, bold_first=True)
    reads = kind != "wpa"
    b += tag(430, 270, ["reads: hello" if reads else "sees only: x7#q%…"], ((("#fdecea", BADC) if reads else ("#e3f1e4", OKC))), 14, mono=True)
    b += _a([(302, 266), (352, 270)], "red" if reads else "green", 1.6, head=False)
    return svgfig(560, 300, b, "The phone sends a frame to the laptop; phone 2 listens")


def sec_state(kind):
    like = "hub" if kind != "wpa" else "switch"
    c = ("#fdecea", BADC) if kind == "open" else ("#fff3bf", "#e67700") if kind == "wep" else ("#e3f1e4", OKC)
    pts = {"open": ["no password, **no key**", "every frame travels **in clear**"],
           "wep": ["**one key** for everyone, phone 2 has it too", "the WEP key can be **broken in minutes**: anyone nearby reads everything"],
           "wpa": ["the first key is the **Wi-Fi password**: every device knows it", "when a device joins, it and the AP make from it **a key for that device** (K1, K2, K3)",
                   "phone 2 has another key: it **cannot** read the frame"]}[kind]
    ic = svgfig(70, 40, icon(like, 35, 20, 1), like)
    return (f'<div class="ws-v" style="border-color:{c[1]};background:{c[0]}"><div class="ws-i">{ic}</div><div><small>the access point behaves like a</small><b style="color:{c[1]}">{like.upper()}</b>'
            f'<small>{"everyone can read everything" if like == "hub" else "each one reads only its own frames"}</small></div></div>' + ul(*pts))


WIFI = [("fc", "Control", "2 B", 62, "data", RED), ("dur", "Duration", "2 B", 66, "44 µs", RED), ("a1", "Address 1", "6 B", 96, "AP", RED),
        ("a2", "Address 2", "6 B", 96, "source", RED), ("a3", "Address 3", "6 B", 104, "destination", RED), ("seq", "Seq.", "2 B", 52, "#1234", RED),
        ("data", "Payload", "0 – 2304 B", 196, None, RED), ("crc", "FCS", "4 B", 56, "CRC-32", RED)]
WIFI_G = (("fc", "seq", "header: 24 bytes"), ("data", "data", "payload: 0 – 2304 bytes"), ("crc", "crc", "trailer"))


def wifi_step(on, rows=None):
    return fields_svg(WIFI, on, WIFI_G, inner=("data", ("type + IPv4 packet", "encrypted (WPA2 / WPA3)"), ORANGE)) + (xtable(rows) if rows else "")


WIFI_STEPS = [
    ("**Three addresses**: on Wi-Fi the frame goes **through the access point**.", wifi_step(("a1", "a2", "a3"), [("Address 1", "who receives it over the air: the **AP**"), ("Address 2", "who sends it over the air: the **source**"), ("Address 3", "the final **destination**, on the Ethernet side: the AP puts the data in an Ethernet frame for it")])),
    ("The radio needs **more control** than a cable.", wifi_step(("fc", "dur", "seq"), [("Control", "the kind of frame (data; management, like the *beacons* that announce the network; control, like *ACK*), to or from the AP, encrypted or not"), ("Duration", "how long the radio stays busy: the others wait, to avoid collisions"), ("Seq.", "the number of the frame, to recognize a frame received twice")])),
    ("The **payload** starts with the **Type** (`0x0800`: IPv4, like Ethernet), so with WPA2 / WPA3 the type is encrypted too.", wifi_step(("data",), [("🔒", "encrypted if the network has a password (WPA2, WPA3); in clear on an open network")])),
    ("The **FCS** is the same CRC-32 as Ethernet; the radio loses frames, so every frame for one device is confirmed by an **ACK**, and sent again if the ACK does not come.", wifi_step(("data", "crc"))),
]

NMCLI_DEV = """$ nmcli device status
DEVICE          TYPE      STATE                   CONNECTION
wlp2s0          wifi      connected               HomeWiFi
lo              loopback  connected (externally)  lo
p2p-dev-wlp2s0  wifi-p2p  disconnected            --
enp0s31f6       ethernet  unavailable             --"""
NMCLI_LIST = """$ nmcli device wifi list ifname wlp2s0
IN-USE  BSSID              SSID        MODE    CHAN  RATE        SIGNAL  BARS  SECURITY
*       70:B5:E8:2D:91:4D  HomeWiFi    Infra   36    540 Mbit/s  82      ****  WPA2 WPA3
        7A:15:C2:09:8E:41  Neighbours  Infra   6     130 Mbit/s  47      **    WPA2
        02:1F:6B:3D:77:10  CafeFree    Infra   11    65 Mbit/s   30      *     --
        D2:5F:0A:31:44:9E  LabGame     Ad-Hoc  1     54 Mbit/s   25      *     --"""
NMCLI_CONN = """$ nmcli device wifi connect HomeWiFi password 'my secret' ifname wlp2s0
Device 'wlp2s0' successfully activated with '6e2c8d5b-1f0a-4c3e-9b7d-2a51c0e8f913'.
$ nmcli device disconnect wlp2s0
Device 'wlp2s0' successfully disconnected.
$ nmcli device connect wlp2s0  # the saved connection: no password
Device 'wlp2s0' successfully activated with '6e2c8d5b-1f0a-4c3e-9b7d-2a51c0e8f913'."""

page = chapter("wifi", "Wi-Fi", "A network without cables", 16)
page("ap", "The access point: plugging in without a cable", "Wi-Fi access point", J(
    p("With Ethernet you plug the cable into the switch. With **Wi-Fi** you choose the network (its name, the *SSID*) and type the password: connecting to the **access point** (AP) is plugging in a *software cable*; disconnecting is pulling it out."),
    fig(fig_ap()),
    ul("all the frames of the wireless devices go **through the AP**", "with a cable to the wired network, the AP is also a **bridge**: Wi-Fi and Ethernet become **one network**"),
))
page("security", "Who can read a frame?", "Wi-Fi security", J(
    p("The radio reaches everyone nearby: every device **hears** every frame. Whether it can **read** it depends on the security of the network."),
    scene("The phone sends a frame, phone 2 listens", "Choose the security of the network.", [
        ("🔓 Open", [("**Open**: no password, no key. Phone 2 reads everything.", sec_svg("open"), sec_state("open"))]),
        ("⚠️ WEP", [("**WEP**: one key for everyone, and it can be broken. Phone 2 reads everything.", sec_svg("wep"), sec_state("wep"))]),
        ("🔒 WPA2 / WPA3", [("**WPA2 / WPA3**: the first key is the **Wi-Fi password**, the same for everyone. When a device joins, it and the AP make from it **a key for that device**. Phone 2 hears the frame but cannot read it.", sec_svg("wpa"), sec_state("wpa"))])]),
))
page("frame", "The Wi-Fi frame: three addresses", "Wi-Fi frame", J(
    p("The same idea as Ethernet, with a few more fields."),
    scene("A Wi-Fi frame, sent through the access point", "The fields, one group at a time.", [("Wi-Fi frame", [(x, pic, None) for x, pic in WIFI_STEPS])], layout="stack"),
))
page("nmcli", "Connecting with `nmcli`", "NetworkManager", J(
    p("On Fedora (and Ubuntu) the **NetworkManager** service sets up the cards; `nmcli` is its command-line client."),
    term_out(NMCLI_DEV),
    table(["Column", "Means"], [("DEVICE", "the card, the same name as in `ip link`; `p2p-dev-…` is a virtual device for *Wi-Fi Direct*"),
        ("STATE", "`connected`; `disconnected` (could connect, not used); `unavailable` (cannot: no cable); `(externally)`: set up by someone else"),
        ("CONNECTION", "the name of the **saved settings** the card uses; `--`: none")], "k"),
    term_out(NMCLI_LIST),
    table(["Column", "Means"], [("`*`", "the network the card uses now"), ("SSID, BSSID", "the name of the network, the MAC address of the access point"),
        ("MODE", "`Infra`: through an access point; `Ad-Hoc`: the devices talk directly, no AP"), ("CHAN", "the radio channel: 1 – 13 are 2.4 GHz, 36 and above 5 GHz"),
        ("SECURITY", "`WPA2 WPA3`: a key for each device; `--`: open")], "k"),
    term_out(NMCLI_CONN),
    p("`connect` saves a **connection** (with an ID): next time the card connects by itself, without the password. `ifname` chooses the card; without it, `nmcli` picks one."),
))
page("practice", "Cheat sheet and practice", "Wi-Fi with nmcli", J(
    table(["Command", "Does"], [
        ("`nmcli device status`", "the cards and their state"), ("`nmcli device wifi list`", "the Wi-Fi networks around"),
        ("`nmcli device wifi connect SSID password P`", "connect, and save the connection"), ("`nmcli device disconnect wlp2s0`", "disconnect the card; the connection stays saved"),
        ("`nmcli device connect wlp2s0`", "connect back, with the saved connection"), ("`nmcli connection show`", "the saved connections"),
        ("`nmcli connection up NAME [ifname CARD]`", "use a saved connection, on a card; `down` stops it"), ("`nmcli radio wifi off` / `on`", "turn all the Wi-Fi cards off and on")], "k"),
    term("wifi", "The laptop: Wi-Fi with nmcli", "A simulated laptop with an Ethernet and a Wi-Fi card. The panel shows what the cards are doing.", ("nmcli device status", "nmcli device wifi list")),
    sol("More: a USB Wi-Fi dongle, a wrong card", sh("""$ nmcli connection up HomeWiFi ifname wlp0s20f0u2  # the dongle in USB port 2
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/8)
$ nmcli connection up HomeWiFi ifname enp0s31f6
Error: Connection activation failed: No suitable device found for this connection (device enp0s31f6 not available because profile is not compatible with device (mismatching connection type))."""),
        ),
))

# ================================================================ 05 IP addresses
def fig_ipsplit(ip="192.168.1.105", n=24):
    bits = "".join(f"{int(o):08b}" for o in ip.split("."))
    CW, G, X0 = 19, 12, 10
    bx = lambda i: X0 + i * CW + (i // 8) * G
    b = ""
    for k, o in enumerate(ip.split(".")):
        b += _t(bx(k * 8) + 4 * CW, 24, o, 20, 800, INK)
        if k:
            b += _t(bx(k * 8) - G / 2, 24, ".", 20, 800, MUTED)
    for i, ch in enumerate(bits):
        c = ORANGE if i < n else GREEN
        b += _r(bx(i), 36, CW - 1, 26, c, 2, 1) + _t(bx(i) + (CW - 1) / 2, 54, ch, 13, 600, INK, mono=True)
    cut = bx(n) - (G / 2 if n % 8 == 0 else 0.5)
    b += _l(cut, 30, cut, 70, HL, 2.4, "5 4")
    for x1, x2, c, t1, t2 in ((bx(0), cut - 3, "#a86f00", f"network: {n} bits", "the street: the same for every device of the network"), (cut + 3, bx(31) + CW - 1, "#2e7d46", f"host: {32 - n} bits", "the house number")):
        b += f'<path d="M{x1},{70} v6 H{x2} v-6 M{(x1+x2)/2},76 v6" fill="none" stroke="{c}" stroke-width="1.8"/>'
        b += _t((x1 + x2) / 2, 100, t1, 15, 700, c) + _t((x1 + x2) / 2, 118, t2, 13, 400, MUTED)
    return svgfig(bx(31) + CW + 10, 126, b, f"The IP address {ip}: the first {n} bits are the network, the rest the host")


IPADDR = """$ ip -br address
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp0s31f6        DOWN
wlp2s0           UP             192.168.1.105/24 fe80::8d2c:41a7:3b6e:f019/64"""

IPF = [("ttl", "TTL", "1 byte", 70, "64", ORANGE), ("proto", "Protocol", "1 byte", 84, "6", ORANGE), ("sum", "Checksum", "2 bytes", 92, "0xb1e6", ORANGE),
       ("src", "Source IP", "4 bytes", 136, "192.168.1.105", ORANGE), ("dst", "Destination IP", "4 bytes", 140, "141.85.220.33", ORANGE), ("data", "Data", "any", 150, None, ORANGE)]
IPF_G = (("ttl", "dst", "header: 20 bytes, only some fields shown"), ("data", "data", "data"))


def ip_step(on, rows=None, legend=None):
    return fields_svg(IPF, on, IPF_G, inner=("data", ("TCP segment", "from the transport layer"), AMBER)) + (xtable(rows) if rows else "") + (kv(legend) if legend else "")


IP_STEPS = [
    ("The **IP addresses**: which computer sends, which computer receives.", ip_step(("src", "dst"), [("Destination", "the routers look at it to find the way"), ("Source", "where the answer goes"), ("💡", "the **same** along the whole way (except through NAT); the MACs change at every router")])),
    ("**TTL**, *time to live*: every router subtracts 1; at `0` the packet is **dropped**.", ip_step(("ttl",), [("why", "a packet caught in a loop of routers does not go around forever"), ("`ttl=60`", "what `ping` shows: started at 64 (Linux), 4 routers on the way")])),
    ("**Protocol**: what is in the data, a hint for the receiver.", ip_step(("proto", "data"), legend=[("`6`", "TCP"), ("`17`", "UDP"), ("`1`", "ICMP (`ping`, *time exceeded*)")])),
    ("A **checksum** of the header (a damaged packet is dropped), then the **data**.", ip_step(("sum", "data"), [("➕", "a few more fields, not shown: the header has at least 20 bytes")])),
]

PING = """$ ping -c 4 141.85.220.33
PING 141.85.220.33 (141.85.220.33) 56(84) bytes of data.
64 bytes from 141.85.220.33: icmp_seq=1 ttl=60 time=4.21 ms
64 bytes from 141.85.220.33: icmp_seq=2 ttl=60 time=3.98 ms
64 bytes from 141.85.220.33: icmp_seq=3 ttl=60 time=4.05 ms
64 bytes from 141.85.220.33: icmp_seq=4 ttl=60 time=4.11 ms

--- 141.85.220.33 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 3.980/4.087/4.210/0.084 ms"""

LAPTOP, PHONE, PUB, SRV = "192.168.1.105", "192.168.1.107", "203.0.113.42", "141.85.220.33"


def nat_svg(step):
    b = area(6, 50, 330, 255, "LAN, private addresses")
    lp, ph, sw, rt, cl, sv = (70, 112), (70, 236), (250, 175), (400, 175), (605, 175), (735, 175)
    b += wire(lp, sw) + wire(ph, sw) + wire(sw, rt) + wire(rt, (571, 175)) + wire((639, 175), sv)
    b += icon("switch", *sw, 0.8)
    b += node("laptop", *lp, "laptop", LAPTOP, on=step in (0, 2)) + node("phone", *ph, "phone", PHONE, on=step == 3)
    b += node("router", *rt, "home router", on=step in (1, 2, 3, 4), below=False)
    b += icon("cloud", *cl) + _t(cl[0], cl[1] + 34, "Internet", 14, 700, MUTED)
    b += node("server", *sv, "upb.ro", SRV)
    T = lambda x, y, a, b_, c=(HLBG, HL), ch=None: tag(x, y, [("from " + a, True, HL if ch == "from" else INK, 700 if ch == "from" else 400), ("to   " + b_, True, HL if ch == "to" else INK, 700 if ch == "to" else 400)], c, 13)
    G = ("#e3f1e4", OKC)
    up, down = (540, 100), (625, 266)
    if step == 0:
        b += trail([(96, 122), (232, 168)]) + T(170, 26, LAPTOP + ":51034", SRV + ":443")
    if step == 1:
        b += trail([(510, 169), (566, 169)]) + T(*up, PUB + ":51034", SRV + ":443", ch="from") + T(170, 26, LAPTOP + ":51034", SRV + ":443", ("#f3f5f6", "#9aa9ae"))
    if step == 2:
        b += trail([(566, 181), (512, 181)], "green") + T(*down, SRV + ":443", PUB + ":51034", G) + trail([(232, 180), (96, 128)], "green") + T(170, 26, SRV + ":443", LAPTOP + ":51034", G, ch="to")
    if step == 3:
        b += trail([(96, 228), (232, 182)]) + T(230, 285, PHONE + ":40877", SRV + ":443") + trail([(510, 169), (566, 169)]) + T(*up, PUB + ":40877", SRV + ":443", ch="from")
    if step == 4:
        b += trail([(566, 181), (512, 181)], "red") + T(*down, "198.51.100.7:4444", PUB + ":22", ("#fdecea", BADC)) + mark(506, 146, False)
    # its two cards: eth0 in the LAN (private), eth1 toward the Internet (public)
    b += rport(336, rt[1], "eth0", "192.168.1.1", "private") + rport(472, rt[1], "eth1", PUB, "public")
    return svgfig(792, 312, b, "NAT: the home router replaces the private source address with its public one")


def nat_state(rows, new=None, hit=None):
    tr = "".join(f'<tr class="{"ch" if i == new else "hit" if i == hit else ""}"><td><code>{a}</code></td><td><code>{b_}</code></td></tr>' for i, (a, b_) in enumerate(rows))
    return f'<div class="sc-h">The NAT table of the router</div><table class="t sc-t"><tr><th>inside (private)</th><th>outside (public)</th></tr>{tr or "<tr><td colspan=2><em>empty</em></td></tr>"}</table>'


R1 = (LAPTOP + ":51034", PUB + ":51034")
R2 = (PHONE + ":40877", PUB + ":40877")
NAT_STEPS = [
    ("The laptop sends a packet to `141.85.220.33`, from its **private** address `192.168.1.105` (and a *port*, the number of this connection: see Transport).", nat_svg(0), nat_state([])),
    ("The router **replaces the source** with its **public** address `203.0.113.42` and writes the change in its NAT table.", nat_svg(1), nat_state([R1], new=0)),
    ("The answer comes to `203.0.113.42:51034`; the table says who asked: the router puts back `192.168.1.105`. The server never saw the private address.", nat_svg(2), nat_state([R1], hit=0)),
    ("The phone goes out with **the same** public address; the router tells the answers apart by the **port** of each connection.", nat_svg(3), nat_state([R1, R2], new=1)),
    ("Someone on the Internet sends to `203.0.113.42:22`: no row in the table, the router does not know who it is for: **dropped**. From outside, nobody can start a connection to a device of the LAN.", nat_svg(4), nat_state([R1, R2])),
]


def fig_ipv6():
    gs = ["2001", "0db8", "0000", "0000", "0000", "ff00", "0042", "8329"]
    GW, G, X0 = 70, 12, 10
    b = ""
    for k, g in enumerate(gs):
        x = X0 + k * (GW + G)
        c = ORANGE if k < 4 else GREEN
        b += _r(x, 14, GW, 32, c, 5, 1.4)
        z = min(len(g) - len(g.lstrip("0")), 3)
        b += f'<text x="{x + GW/2 - 20.4}" y="37" style="font:700 17px \'SF Mono\',Menlo,Consolas,monospace"><tspan fill="#9aa9ae">{g[:z]}</tspan><tspan fill="{INK}">{g[z:]}</tspan></text>'
        if k:
            b += _t(x - G / 2, 37, ":", 18, 800, MUTED)
    for x1, x2, col, t in ((X0, X0 + 4 * (GW + G) - G, "#a86f00", "network: 64 bits"), (X0 + 4 * (GW + G), X0 + 8 * (GW + G) - G, "#2e7d46", "host: 64 bits")):
        b += f'<path d="M{x1},52 v6 H{x2} v-6" fill="none" stroke="{col}" stroke-width="1.8"/>' + _t((x1 + x2) / 2, 76, t, 14, 700, col)
    b += _t(X0, 112, "skip the leading zeros:", 14, 600, MUTED, a="start") + _t(X0 + 190, 112, "2001:db8:0:0:0:ff00:42:8329", 17, 700, INK, a="start", mono=True)
    b += _t(X0, 142, ":: for one run of zeros:", 14, 600, MUTED, a="start")
    b += f'<text x="{X0 + 190}" y="142" style="font:700 17px \'SF Mono\',Menlo,Consolas,monospace" fill="{INK}">2001:db8<tspan fill="{HL}">::</tspan>ff00:42:8329</text>'
    return svgfig(X0 + 8 * (GW + G), 152, b, "An IPv6 address: 128 bits in 8 groups of 4 hexadecimal digits, and its short forms")


PING6 = """$ ping -c 1 2a00:1450:4017:80e::200e
PING 2a00:1450:4017:80e::200e (2a00:1450:4017:80e::200e) 56 data bytes
64 bytes from 2a00:1450:4017:80e::200e: icmp_seq=1 ttl=117 time=12.4 ms
$ ping -c 1 ::1  # the loopback, like 127.0.0.1
PING ::1 (::1) 56 data bytes
64 bytes from ::1: icmp_seq=1 ttl=64 time=0.041 ms
$ ping -c 1 fe80::1%wlp2s0  # link local: say on which card
PING fe80::1%wlp2s0 (fe80::1%wlp2s0) 56 data bytes
64 bytes from fe80::1%wlp2s0: icmp_seq=1 ttl=64 time=2.31 ms"""

page = chapter("ip", "IP addresses", "The network layer: addresses, masks, packets, `ping`", 22)
page("ipv4", "An IPv4 address: a street and a house number", "IP address", J(
    p("An **IPv4 address** has **32 bits** (4 bytes), each byte written in decimal, `0` to `255`: about **4.3 billion** addresses for the whole Internet. The first bits name the **network**, the rest the **host** in that network."),
    fig(fig_ipsplit()),
    p("Where the network part ends is not fixed: here it is after 24 bits, it can be 16, or even 20, in the middle of a byte. The **mask** says where."),
))
page("mask", "The mask: which bits are the network", "Network mask", J(
    p("The mask is written as a **prefix**, the number of network bits (`192.168.1.105/24`), or like an address: `255.255.255.0` is 24 bits of `1` and 8 of `0`. Set **all the host bits** to `0`: the address of the **network**; to `1`: the **broadcast**, a packet for everyone in the network."),
    w("mask"),
    p("Two computers are in **the same network** when their network bits are the same: they talk directly. Otherwise the packet goes **through a router**."),
    quiz("`172.16.45.130/20`: which address is in the same network?", ["`172.16.50.1`", "`172.16.40.1`", "`172.16.48.1`", "`172.17.45.130`"], 1,
         "The network is `172.16.32.0/20`: from `172.16.32.0` to `172.16.47.255` (the third byte `0010 xxxx`, 32 to 47). Only `172.16.40.1` is inside."),
))
page("special", "Special addresses, and the addresses of Linux", "Special addresses", J(
    table(["Address", "Means"], [
        ("`127.0.0.0/8` (usually `127.0.0.1`)", "**loopback**, `localhost`: this computer; the packets never leave it"),
        ("`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`", "**private** networks: free for everyone at home or at work, **not routed** on the Internet"),
        ("`169.254.0.0/16`", "*link local*: nobody gave us an address, the computer picked one by itself"),
        ("`0.0.0.0`", "*any address* of this computer: a server that waits on all of them, or a computer with no address yet")], "k"),
    term_out(IPADDR, {4: ["192.168.1.105/24"]}),
    p("`ip -br address` shows the addresses of every card: the Wi-Fi card has `192.168.1.105` in the network `192.168.1.0/24`; `lo` has the loopback; `enp0s31f6` has no cable, so no address; `fe80::…` is an IPv6 address (end of the chapter)."),
))
page("packet", "The IPv4 packet", "IP packet", J(
    scene("An IPv4 packet", "Only the important fields of the header.", [("IPv4 packet", [(x, pic, None) for x, pic in IP_STEPS])], layout="stack"),
))
page("ping", "`ping`: is it there, does it answer?", "ping", J(
    p("`ping` sends an ICMP **echo request**; the computer answers with an **echo reply**. `-c 4`: only 4 times (without it, `ping` runs until [[Ctrl]] + [[C]])."),
    term_out(PING, {3: ["icmp_seq=1", "ttl=60", "time=4.21 ms"], 9: ["0% packet loss"]}),
    table(["Part", "Means"], [("`icmp_seq`", "the number of the request: a missing number is a **lost** packet"), ("`ttl=60`", "the TTL left in the answer: from 64, it passed 4 routers"),
                              ("`time`", "the round trip, there and back"), ("`packet loss`", "`0%` is good; a few lost: bad Wi-Fi or a busy network"),
                              ("`min/avg/max`", "the shortest, the average and the longest round trip")], "k"),
))
page("ipv6", "IPv6: 128 bits", "IPv6", J(
    p("IPv4 ran out of addresses in 2011. **IPv6** has **128 bits** (about 3.4 · 10³⁸ addresses), written as 8 groups of 4 hexadecimal digits."),
    fig(fig_ipv6()),
    ul("`::1` is the loopback (like `127.0.0.1`); `fe80::…` is *link local*: every card with IPv6 has one",
       "most computers have **both** IPv4 and IPv6 (*dual stack*); the layers above do not care. In this lecture we use IPv4"),
    term_out(PING6),
    p("The same `ping`; in IPv6 the TTL is called *hop limit*. A link local address needs the card: `%wlp2s0`."),
))
page("practice", "Cheat sheet and practice", "IP addresses", J(
    table(["Command", "Does"], [("`ip -br link`", "the cards, their state and MAC address"), ("`ip -br address`", "the IP addresses and masks of every card"),
                                ("`ping -c 4 ADDRESS`", "4 echo requests; lost packets, TTL, round trip"), ("`ping ::1`, `ping 127.0.0.1`", "the loopback"),
                                ("`cat /sys/class/net/CARD/address`", "the MAC address of a card")], "k"),
    term("ip", "The laptop: addresses and ping", cmds=("ip -br address", "ping -c 2 8.8.8.8")),
))

# ================================================================ 06 routing
ANA, BOG, CAR, RT1, RT2 = ("192.168.1.10", "5c:8f:2a:91:d4:07"), ("192.168.1.11", "e4:3b:71:0c:9a:52"), ("192.168.2.20", "08:d1:6e:b3:47:ac"), ("192.168.1.1", "70:b5:e8:2d:91:4c"), ("192.168.2.1", "70:b5:e8:2d:91:50")
RP = dict(ana=(60, 100), bog=(60, 214), sw1=(205, 158), rt=(390, 158), sw2=(575, 158), car=(720, 100), dan=(720, 214))


def router_svg(router=True, on=(), trails=(), tags=(), marks=(), gw=None):
    P = RP
    b = area(6, 40, 296, 262, "192.168.1.0/24") + area(478, 40, 296, 262, "192.168.2.0/24", right=True)
    b += wire(P["ana"], P["sw1"]) + wire(P["bog"], P["sw1"]) + wire(P["car"], P["sw2"]) + wire(P["dan"], P["sw2"])
    if router:
        b += wire(P["sw1"], P["rt"]) + wire(P["rt"], P["sw2"])
    for t in trails:
        b += t
    b += icon("switch", *P["sw1"], 0.8) + icon("switch", *P["sw2"], 0.8)
    short = lambda m: m[:8] + "…"
    b += node("pc", *P["ana"], "Ana", [ANA[0], short(ANA[1])], on="ana" in on) + node("pc", *P["bog"], "Bogdan", [BOG[0], short(BOG[1])], on="bog" in on)
    b += node("pc", *P["car"], "Carla", [CAR[0], short(CAR[1])], on="car" in on) + node("pc", *P["dan"], "Dan", ["192.168.2.21", "f0:9e:4a:…"], on="dan" in on)
    if router:
        b += node("router", *P["rt"], "router", on="rt" in on)
    else:
        b += f'<circle cx="{P["rt"][0]}" cy="{P["rt"][1]}" r="22" fill="none" stroke="#9aa9ae" stroke-width="1.6" stroke-dasharray="5 4"/>' + _t(P["rt"][0], P["rt"][1] + 42, "no router", 14, 700, "#9aa9ae")
    if gw is not None:
        b += tag(150, 18, ["Ana's gateway: " + (gw or "none")], (HLBG, HL) if gw else ("#fdecea", BADC), 13.5)
    if router:
        # one card in each network, on its border; the trails stop before them
        b += rport(302, P["rt"][1], "eth0", RT1[0]) + rport(478, P["rt"][1], "eth1", RT2[0])
    for x in tags:
        b += x
    for x, y, ok in marks:
        b += mark(x, y, ok)
    return svgfig(780, 306, b, "Two networks joined by a router, with one card in each")


def frame_state(rows, neigh, title="The frame Ana sends", note=None):
    # the fields side by side (one column each) and the neighbors next to them: a short strip under the picture
    fr = ("<tr>" + "".join(f'<th>{k}</th>' for k, v, ch in rows) + "</tr><tr>"
          + "".join(f'<td class="{"ch" if ch else ""}"><code>{E(v)}</code></td>' for k, v, ch in rows) + "</tr>")
    ng = "".join(f'<tr class="{"ch" if ch else ""}"><td><code>{a}</code></td><td><code>{m}</code></td></tr>' for a, m, ch in neigh) or '<tr><td colspan="2"><em>empty</em></td></tr>'
    return (f'<div class="sc-row sc-fr"><div><div class="sc-h">{title}</div><table class="t sc-t">{fr}</table></div>'
            f'<div><div class="sc-h">Ana\'s neighbors (<code>ip neigh</code>)</div><table class="t sc-t"><tr><th>IP</th><th>MAC</th></tr>{ng}</table></div></div>' + (f'<p class="sc-n sc-n2">{md(note)}</p>' if note else ""))


def FR(mto, mfrom, ito, ifrom, ttl, ch=()):
    return [("MAC to", mto, "mto" in ch), ("MAC from", mfrom, "mfrom" in ch), ("IP to", ito, "ito" in ch), ("IP from", ifrom, "ifrom" in ch), ("TTL", ttl, "ttl" in ch)]


P_ = RP
SAME = [
    ("Ana has a packet for Bogdan `192.168.1.11`. With her mask `/24` Bogdan is in **her network**: she sends the frame **directly** to him, but she needs **his MAC address**.",
     router_svg(on=("ana",), tags=[tag(170, 18, ["packet for 192.168.1.11"], (HLBG, HL), 13.5)]), frame_state(FR("???", ANA[1], BOG[0], ANA[0], "64", ("mto",)), [])),
    ("**ARP**: Ana asks **everyone** (`ff:ff:ff:ff:ff:ff`): *who has 192.168.1.11? tell 192.168.1.10*. Only Bogdan answers, and only to Ana.",
     router_svg(on=("ana", "bog"), trails=[trail([(84, 112), (190, 150)]), trail([(205, 170), (84, 206)]), trail([(230, 158), (266, 158)])],
                tags=[tag(230, 18, ["ARP, to everyone: who has 192.168.1.11?"], (HLBG, HL), 13.5), tag(390, 260, ["Bogdan, only to Ana:", "192.168.1.11 is at e4:3b:71:0c:9a:52"], ("#e3f1e4", OKC), 13)]),
     frame_state(FR(BOG[1], ANA[1], BOG[0], ANA[0], "64", ("mto",)), [(BOG[0], BOG[1], True)])),
    ("The frame goes to the switch, which delivers it to Bogdan. No router was needed.",
     router_svg(on=("bog",), trails=[trail([(84, 112), (190, 150)]), trail([(200, 172), (88, 206)])], marks=[(110, 214, True)]), frame_state(FR(BOG[1], ANA[1], BOG[0], ANA[0], "64"), [(BOG[0], BOG[1], False)])),
]
NOGW = [
    ("Carla `192.168.2.20` is in **another network**, and Ana has **no gateway**: she has no route there, so no frame is sent at all.",
     router_svg(router=False, on=("ana",), gw="", tags=[tag(390, 268, ["$ ping 192.168.2.20", "connect: Network is unreachable"], ("#fdecea", BADC), 13, mono=True)], marks=[(110, 92, False)]),
     frame_state(FR("–", ANA[1], CAR[0], ANA[0], "–", ("mto",)), [], note="Ana's routing table has only `192.168.1.0/24`: nothing matches `192.168.2.20`.")),
]
VIA = [
    ("Carla is in another network: Ana sends the packet to her **gateway**, the router `192.168.1.1`. ARP gives her the **router's MAC**; the IP destination stays Carla's.",
     router_svg(on=("ana", "rt"), gw="192.168.1.1"), frame_state(FR(RT1[1], ANA[1], CAR[0], ANA[0], "64", ("mto",)), [(RT1[0], RT1[1], True)])),
    ("Frame 1 goes to the router: **MAC to the router**, **IP to Carla**.",
     router_svg(on=("rt",), gw="192.168.1.1", trails=[trail([(84, 112), (190, 150)]), trail([(225, 158), (266, 158)])]), frame_state(FR(RT1[1], ANA[1], CAR[0], ANA[0], "64"), [(RT1[0], RT1[1], False)])),
    ("The router reads the IP destination: `192.168.2.0/24` is on its other card. It finds **Carla's MAC** (ARP) and puts the **same packet** in a **new frame**, TTL one less.",
     router_svg(on=("car",), gw="192.168.1.1", trails=[trail([(84, 112), (190, 150)], "grey", 3), trail([(225, 158), (266, 158)], "grey", 3), trail([(506, 158), (553, 158)]), trail([(590, 150), (696, 112)])], marks=[(670, 100, True)]),
     frame_state(FR(CAR[1], RT2[1], CAR[0], ANA[0], "63", ("mto", "mfrom", "ttl")), [(RT1[0], RT1[1], False)], title="The new frame, from the router",
                 note="The **MAC addresses changed**, the **IP addresses stayed the same**.")),
]

ROUTE_OUT = """$ ip route
default via 192.168.1.1 dev enp0s31f6 proto dhcp src 192.168.1.10 metric 100
192.168.1.0/24 dev enp0s31f6 proto kernel scope link src 192.168.1.10 metric 100"""
NEIGH_OUT = """$ ip neigh
192.168.1.1 dev enp0s31f6 lladdr 70:b5:e8:2d:91:4c REACHABLE
192.168.1.11 dev enp0s31f6 lladdr e4:3b:71:0c:9a:52 STALE
192.168.1.12 dev enp0s31f6  FAILED"""
TRACE = """$ traceroute -n 141.85.220.33
traceroute to 141.85.220.33 (141.85.220.33), 30 hops max, 60 byte packets
 1  192.168.1.1    1.912 ms  1.874 ms  1.851 ms
 2  10.20.0.1      3.420 ms  3.402 ms  3.389 ms
 3  * * *
 4  37.128.225.9   4.103 ms  4.087 ms  4.152 ms
 5  141.85.220.33  4.210 ms  4.198 ms  4.176 ms"""


def trace_svg(k):
    xs = (50, 230, 410, 620)
    y = 78
    b = ""
    for i in range(3):
        b += wire((xs[i], y), (xs[i + 1], y))
    b += node("laptop", xs[0], y, "my laptop", LAPTOP) + node("router", xs[1], y, "router 1", "192.168.1.1", on=k == 1) + node("router", xs[2], y, "router 2", "10.20.0.1", on=k == 2) + node("server", xs[3], y, "server", SRV, on=k == 3)
    for i in range(k):
        a, z = xs[i] + 26, xs[i + 1] - 26
        b += _a([(a, y - 8), (z, y - 8)], "hl", 3)
        b += tag((a + z) / 2, y - 32, [f"TTL {k - i}"], (HLBG, HL), 13.5)
    if k < 3:
        b += boom(xs[k] + 22, y - 26, 14)
    back = "time exceeded" if k < 3 else "port unreachable"
    b += _a([(xs[k] - 24, y + 92), (xs[0] + 24, y + 92)], "green" if k == 3 else "grey", 2, dash=True)
    b += _t((xs[0] + xs[k]) / 2, y + 86, ("router " + str(k) if k < 3 else "the server") + " answers: " + back, 13.5, 700, OKC if k == 3 else MUTED)
    return svgfig(680, y + 100, b, "traceroute sends packets with TTL 1, 2, 3, ...")


TR_LINES = [" 1  192.168.1.1    1.912 ms  1.874 ms  1.851 ms", " 2  10.20.0.1      3.420 ms  3.402 ms  3.389 ms", " 3  141.85.220.33  4.210 ms  4.198 ms  4.176 ms"]


def trace_state(k):
    lines = "\n".join(f'<span class="{"nw" if i == k - 1 else ""}">{E(l)}</span>' for i, l in enumerate(TR_LINES[:k]))
    return f'<pre class="sh sc-sh"><span class="p">$</span> <span class="c"><span class="cn">traceroute</span> <span class="fl">-n</span> 141.85.220.33</span>\n{lines}</pre>'


TRACE_STEPS = [
    ("**TTL 1**: router 1 subtracts 1, gets `0`, drops the packet and sends back an ICMP *time exceeded*: now we know **router 1**.", trace_svg(1), trace_state(1)),
    ("**TTL 2**: the packet passes router 1; router 2 drops it and answers: now we know **router 2**.", trace_svg(2), trace_state(2)),
    ("**TTL 3**: the packet reaches the server. Linux `traceroute` sends UDP to an unused port, so the server answers *port unreachable*: done. (`traceroute -I` and Windows `tracert` use `ping` packets.)", trace_svg(3), trace_state(3)),
]


def fig_routers():
    R = [(150, 60), (150, 170), (290, 40), (310, 150), (450, 70), (470, 180)]
    L = ((0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (2, 4), (3, 4), (3, 5), (4, 5), (1, 5))
    path = {(0, 3), (3, 4)}
    b = ""
    for i, j in L:
        b += wire(R[i], R[j], HL if (i, j) in path else "#9aa9ae", 4 if (i, j) in path else 2)
    b += wire((50, 60), R[0], HL, 4) + wire(R[4], (580, 70), HL, 4)
    for x, y in R:
        b += icon("router", x, y, 0.85)
    b += node("laptop", 50, 60, "home") + node("server", 580, 70, "upb.ro")
    b += _t(320, 224, "each router knows only the next hop; if a link fails, the packets take another way", 13.5, 400, MUTED)
    return svgfig(640, 232, b, "The Internet: networks joined by routers; the packets go from router to router")


page = chapter("routing", "Routing", "From one network to another: routers, `ip route`, `traceroute`, NAT", 26)
page("router", "A router joins two networks", "Router", J(
    p("A **router** is a computer with **two or more network cards**, one in each network: here `eth0` `192.168.1.1` in Ana's network and `eth1` `192.168.2.1` in Carla's. It forwards **packets** from one network to another: a hub works on layer 1 (bits), a switch on layer 2 (frames, MAC addresses), a router on **layer 3** (packets, IP addresses)."),
    scene("Ana sends a packet", "To Bogdan, in her network; to Carla, in another one.", [("Same network", SAME), ("No gateway", NOGW), ("Through the router", VIA)], layout="stack", cap=266),
    p("Ana's computer decides with its **mask**: same network, send **directly** (ARP for the destination's MAC); another network, send to the **gateway** (ARP for the router's MAC)."),
))
page("neigh", "`ip neigh`: the MACs Ana found", "Neighbors", J(
    term_out(NEIGH_OUT, {2: ["REACHABLE"], 3: ["STALE"], 4: ["FAILED"]}),
    table(["Part", "Means"], [("`192.168.1.1 … 70:b5:e8:2d:91:4c`", "the answers to Ana's ARP questions: the *neighbor table* (the *ARP cache*)"),
        ("`REACHABLE`", "used just now, it answers"), ("`STALE`", "an old entry: Ana asks again the next time she needs it"),
        ("`FAILED`", "nobody answered: there is no `192.168.1.12`; `ping` says `Destination Host Unreachable`")], "k"),
    p("Carla is not in the table: for another network Ana only needs the MAC of the **gateway**. `arp -n` is the older command, the same table."),
))
page("table", "The routing table: where does each packet go?", "Routing table", J(
    p("For every packet the kernel looks in the **routing table** and picks the **most specific** line that matches the destination: the **longest prefix**."),
    term_out(ROUTE_OUT, {2: ["default", "via 192.168.1.1"], 3: ["192.168.1.0/24"]}),
    table(["Part", "Means"], [("`192.168.1.0/24 … proto kernel`", "Ana's own network: sent **directly**; added by the kernel when the card got its address"),
                              ("`default via 192.168.1.1`", "every other address (`0.0.0.0/0`): sent to the **gateway**"), ("`dev`, `src`", "the card to use, and the address it sends from")], "k"),
    w("route"),
))
page("fails", "When `ping` fails, the error says where", "Errors", J(
    table(["The error", "Means", "Check"], [
        ("`connect: Network is unreachable`", "no route to that network: usually no **default gateway**", "`ip route`"),
        ("`Destination Host Unreachable`", "a computer of **my network** that does not answer ARP: off, or a wrong IP", "is it on? the right address?"),
        ("`100% packet loss`", "the packets leave, no answer comes: the computer is down, or a **firewall** drops `ping`", "another computer, `traceroute`")]),
    sh("""$ ping -c 1 192.168.1.20
PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.
From 192.168.1.105 icmp_seq=1 Destination Host Unreachable

--- 192.168.1.20 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms"""),
    bad("No answer to `ping` means the computer is down", "Many servers drop `ping` on purpose (a firewall): `100% packet loss`, yet the web server works.", "try the service itself (`curl`), or look where the packets stop with `traceroute`."),
))
page("internet", "The Internet: a network of routers", "Routers", J(
    fig(fig_routers()),
    table(["", "Hub", "Switch", "Access point", "Router"], [
        ("Layer", "1: bits", "2: frames", "2: frames", "3: packets"), ("Uses", "nothing", "MAC addresses", "MAC addresses", "IP addresses"),
        ("Sends to", "all the ports", "the destination port", "the destination device (radio)", "the next network"),
        ("Connects", "devices", "the devices of one network", "wireless devices to a wired network", "**different networks**")]),
))
page("traceroute", "`traceroute`: the routers on the way", "traceroute", J(
    term_out(TRACE, {3: ["192.168.1.1"], 5: ["* * *"], 7: ["141.85.220.33"]}),
    table(["Part", "Means"], [("`-n`", "show the routers by IP only (faster, no name lookups)"), ("` 1  192.168.1.1`", "one line per router (*hop*), in order: the first is the **gateway**"),
                              ("three times", "three tries, three round trips"), ("`* * *`", "a router that does not answer; it still **forwards** the packets"),
                              ("the last line", "the destination: reached after 4 routers")], "k"),
    scene("How traceroute finds the routers", "With the TTL of the IP packets (a shorter way, two routers).", [("traceroute", TRACE_STEPS)]),
    p("Not installed? `sudo dnf install traceroute` (Fedora), `sudo apt install traceroute` (Ubuntu); `tracepath` is usually there and does almost the same."),
))
page("nat", "NAT: many private addresses, one public address", "NAT", J(
    p("Private addresses are not routed on the Internet. The home router, the router between the home and the provider, has **one public address** and lets all the devices of the home out through it: it rewrites the packets (*Network Address Translation*)."),
    scene("NAT in the home router", "One connection out, the answer back, a second device.", [("NAT", NAT_STEPS)]),
    quiz("Why can't a server on the Internet open a connection to your laptop at home?", ["the laptop has no MAC address", "the NAT table of the router has no row for it, so the router drops it", "the TTL is too small", "private addresses are blocked by the laptop"], 1,
         "The router only knows where to send a packet that answers a connection started from inside. A new packet from outside matches no row: it is dropped."),
))
page("practice", "Cheat sheet and practice", "Routing", J(
    table(["Command", "Does"], [("`ip route`, `ip r`", "the routing table: `default via` is the gateway"), ("`ip neigh`, `arp -n`", "the MAC addresses found with ARP"),
                                ("`traceroute -n ADDRESS`", "the routers on the way"), ("`ping`", "`Network is unreachable` · `Destination Host Unreachable` · `100% packet loss`")], "k"),
    term("route", "The laptop: routes and routers", cmds=("ip route", "ip neigh")),
))

# ================================================================ 07 transport
def prog(x, y, name, port, on=False, w=120):
    """a program box with its port, a dark socket on its left"""
    b = _r(x, y, w, 30, GREEN if not on else (HLBG, HL), 6, 2.4 if on else 1.4) + _t(x + w / 2 + 6, y + 20, name, 14, 700)
    if port is not None:
        b += _r(x - 22, y + 6, 50, 18, ("#37474f" if not on else HL, "#37474f" if not on else HL), 3, 1) + _t(x + 3, y + 19.5, ":" + str(port), 12, 800, "#fff", mono=True)
    return b


def ports_svg(step):
    lp, rt, cl, sv = (60, 130), (230, 130), (380, 130), (540, 130)
    b = wire((lp[0] + 26, 130), rt) + wire(rt, (340, 130)) + wire((420, 130), sv)
    b += node("laptop", *lp, "laptop", LAPTOP) + node("router", *rt, "home router", PUB) + icon("cloud", *cl) + _t(cl[0], 166, "Internet", 14, 700, MUTED) + node("server", *sv, "server", SRV, on=step == 3)
    b += prog(44, 40, "browser", 51034 if step else None, on=step in (1, 5), w=110)
    for i, (n, pt) in enumerate((("sshd", 22), ("nginx", 443), ("DNS", 53))):
        b += prog(640, 70 + i * 50, n, pt, on=(pt == 443 and step >= 4), w=100)
        b += wire((566, 130), (618, 85 + i * 50), "#c3cdd1", 1.5)
    seg = lambda x, y, a, b_, c=(HLBG, HL): tag(x, y, [("to   " + a, True), ("from " + b_, True)], c, 13)
    if step == 1:
        b += trail([(86, 122), (208, 122)]) + seg(150, 230, SRV + ":443", LAPTOP + ":51034")
    if step == 2:
        b += trail([(252, 122), (515, 122)]) + seg(380, 230, SRV + ":443", PUB + ":51034") + _t(540, 40, "the IP finds the computer", 14, 700, HL)
    if step == 3:
        b += trail([(566, 130), (614, 135)]) + _t(540, 40, "the port finds the program", 14, 700, HL)
    if step == 4:
        b += trail([(515, 140), (252, 140)], "green") + seg(380, 230, PUB + ":51034", SRV + ":443", ("#e3f1e4", OKC)) + trail([(208, 140), (86, 140)], "green")
    return svgfig(760, 262, b, "The IP address finds the computer, the port finds the program")


PORTS_STEPS = [
    ("A **port** is a number, `0` – `65535`: each server program **waits** on its own port.", ports_svg(0), None),
    ("The browser sends to IP `141.85.220.33`, **port 443**. Its own port is a free one, given by the operating system: `51034`.", ports_svg(1), None),
    ("On the way, the home router puts its public address (NAT). The **IP address** finds the computer: the *building*.", ports_svg(2), None),
    ("The **port** finds the program: the *apartment*. Port `443` is nginx.", ports_svg(3), None),
    ("The answer goes back to `203.0.113.42:51034`; the home router sends it to `192.168.1.105:51034`: to the **browser**, not to another program.", ports_svg(4), None),
]


def getport_svg(step):
    b = prog(30, 20, "nginx", 443 if step >= 0 else None, on=step == 0, w=120)
    if step >= 1:
        b += prog(30, 80, "second nginx", None, on=step == 1, w=150)
    if step >= 2:
        b += prog(30, 140, "browser", 51034, on=step == 2, w=120)
    b += _r(300, 10, 230, 170, ("#eef4f7", NAVY), 10, 1.6) + _t(415, 34, "the operating system", 14, 800, NAVY)
    q = [("listen on port 443?", "✓ it is yours", OKC), ("listen on port 443?", "✗ already taken", BADC), ("connect to 141.85.220.33:443", "✓ you get port 51034", OKC)][step]
    y = [35, 95, 155][step]
    b += _a([(188, y), (296, y)], "navy", 2)
    b += _t(415, 80, q[0], 13.5, 600, INK) + _t(415, 104, q[1], 15, 800, q[2])
    b += _a([(296, y + 10), (188, y + 10)], "green" if q[2] == OKC else "red", 2)
    return svgfig(540, 190, b, "A program asks the operating system for a port")


def port_table(rows, new=None, bad=None):
    tr = "".join(f'<tr class="{"ch" if p_ == new else ""}"><td><code>{p_}</code></td><td>{n}</td><td><code>{st}</code></td></tr>' for p_, n, st in rows)
    return f'<div class="sc-h">The ports of the server, in the operating system</div><table class="t sc-t"><tr><th>port</th><th>program</th><th>state</th></tr>{tr}</table>' + (f'<p class="sc-n sc-bad">{md(bad)}</p>' if bad else "")


BASEP = [("22", "`sshd`", "LISTEN"), ("53", "DNS server", "LISTEN"), ("443", "`nginx`", "LISTEN")]
GETPORT_STEPS = [
    ("A **server** asks for its port and **listens** there. Only `root` may listen on ports below `1024`.", getport_svg(0), port_table(BASEP, new="443")),
    ("A second program asks for the **same** port: refused, `Address already in use`. One port, **one** program.", getport_svg(1), port_table(BASEP, bad="`nginx: [emerg] bind() to 0.0.0.0:443 failed (98: Address already in use)`")),
    ("A **client** does not choose: the OS gives it a **free** port from `32768` – `60999`. `ESTAB`: *established*, connected.", getport_svg(2), port_table(BASEP + [("51034", "browser", "ESTAB")], new="51034")),
]


def seq_svg(msgs, cur, left="browser", right="nginx", lsub=LAPTOP + ":51034", rsub=SRV + ":443"):
    """a message sequence: msgs = (dir '>' or '<', label, lost?)"""
    XL, XR, Y0, RH = 90, 470, 70, 46
    H = Y0 + RH * max(len(msgs), 4) + 14
    b = _t(XL, 20, left, 15, 800, NAVY) + _t(XL, 38, lsub, 12, 400, MUTED, mono=True) + _t(XR, 20, right, 15, 800, NAVY) + _t(XR, 38, rsub, 12, 400, MUTED, mono=True)
    b += _l(XL, 46, XL, H - 6, "#9aa9ae", 2) + _l(XR, 46, XR, H - 6, "#9aa9ae", 2)
    for i, (d, label, lost) in enumerate(msgs):
        if i > cur:
            break
        y1, y2 = Y0 + i * RH, Y0 + i * RH + 22
        a, z = (XL, XR) if d == ">" else (XR, XL)
        on = i == cur
        col = "hl" if on else ("green" if d == "<" else "navy")
        if lost:
            mx = (a + z) / 2
            b += _a([(a, y1), (mx, (y1 + y2) / 2)], col, 2.6 if on else 1.8, head=False) + boom(mx, (y1 + y2) / 2, 11)
        else:
            b += _a([(a, y1), (z, y2)], col, 2.6 if on else 1.8)
        b += _t(a + (10 if d == ">" else -10), y1 - 6, label, 13.5, 800 if on else 600, HL if on else INK, a="start" if d == ">" else "end", mono=True)
    return svgfig(560, H, b, "Messages between two programs, in time")


def seg_state(rows):
    return '<div class="sc-h">The current segment</div><table class="t sc-t">' + "".join(f"<tr><td>{a}</td><td>{md(b_)}</td></tr>" for a, b_ in rows) + "</table>"


TCP_M = [(">", "hello: can we talk?", False), ("<", "hello, OK", False), (">", "OK", False), (">", "GET /  (the request)", False),
         ("<", "the page, and: got it", False), (">", "goodbye", False), ("<", "goodbye too", False)]
TCP_STEPS = [
    ("The browser asks for a **connection**: *hello, can we talk?*",),
    ("nginx agrees: *hello, OK*.",),
    ("The browser confirms: *OK*. Three short messages, the **handshake**: the connection is open, and no data was sent yet.",),
    ("Now the data: the request, `GET /`.",),
    ("nginx sends the page, and confirms that the request arrived: *got it*. Every piece of data is confirmed this way.",),
    ("The browser is done: *goodbye*.",),
    ("nginx says *goodbye* too: the connection is closed.",),
]
LOST_M = [(">", "GET /  (the request)", True), (">", "GET /  (sent again)", False), ("<", "got it", False)]
LOST_STEPS = ["The request is **lost** on the way: a busy router dropped it.", "No *got it* came back in time: TCP **sends it again**, by itself.", "This time nginx confirms it. The browser never knew: TCP hid the loss."]
UDP_M = [(">", "the address of upb.ro?", False), ("<", "141.85.220.33", False)]
UDP_STEPS = ["A DNS question in **one** datagram, from port `40211` to port `53`: no connection, no hello.", "The answer, in one datagram. Two messages in all: faster than TCP."]
UDPL_M = [(">", "the address of upb.ro?", True), (">", "the address of upb.ro?  (again)", False), ("<", "141.85.220.33", False)]
UDPL_STEPS = ["The question is **lost**. UDP does nothing about it.", "The **program** (the DNS client) waited, got nothing, and **asks again** by itself.", "The answer comes."]


def udp_scene_step(m, i, x):
    return (x, seq_svg(m, i, "laptop", "DNS server", LAPTOP + ":40211", "192.168.1.1:53"), None)


UDPF = [("src", "Source Port", "2 bytes", 110, "40211", AMBER), ("dst", "Dest. Port", "2 bytes", 110, "53", AMBER), ("len", "Length", "2 bytes", 96, "41", AMBER),
        ("sum", "Checksum", "2 bytes", 100, "0x1f2b", AMBER), ("data", "Data", "any", 230, None, AMBER)]
TCPF = [("src", "Src. Port", "2 bytes", 84, "51034", AMBER), ("dst", "Dest. Port", "2 bytes", 84, "443", AMBER), ("seq", "Sequence", "4 bytes", 96, "1000", AMBER),
        ("ack", "Ack", "4 bytes", 84, "5000", AMBER), ("flags", "Flags", "1 byte", 74, "ACK", AMBER), ("sum", "Checksum", "2 bytes", 92, "0x9c41", AMBER), ("data", "Data", "any", 132, None, AMBER)]


def udp_step(on, rows=None):
    return fields_svg(UDPF, on, (("src", "sum", "header: 8 bytes"), ("data", "data", "data")), inner=("data", ("Data", "from the application"), GREEN)) + (xtable(rows) if rows else "")


def tcp_step(on, rows=None, legend=None):
    return fields_svg(TCPF, on, (("src", "sum", "header: 20 bytes, only some fields shown"), ("data", "data", "data")), inner=("data", ("Data", "from the app"), GREEN)) + (xtable(rows) if rows else "") + (kv(legend) if legend else "")


HDR_UDP = [
    ("What **UDP** does: carries one message from a program to another, **nothing more**. No connection (no *hello*, the datagram is just sent), no order, no second try: a lost datagram stays lost; in exchange, it is **fast** and **simple**.", udp_step(())),
    ("The **ports**: the destination `53` is the DNS server; the source is where the answer goes. No IP addresses here: they are in the IP packet, around it.", udp_step(("src", "dst"))),
    ("A **length** (header + data: `8 + 33 = 41` bytes) and a **checksum**: a damaged datagram is **dropped**.", udp_step(("len", "sum"))),
    ("The data of the program, sent **as it is**: no connection, no order, no second try. The program decides what to do about a loss: DNS just asks again.", udp_step(("data",))),
]
HDR_TCP = [
    ("What **TCP** does: a **reliable connection** between two programs. A *hello* first, then the data, a *goodbye* at the end; every byte has a number, so the receiver puts them back **in order**; what is not confirmed in time is **sent again**.", tcp_step(())),
    ("The **ports**, just like UDP: from the browser `51034` to nginx `443`. TCP is UDP plus what makes it reliable.", tcp_step(("src", "dst"))),
    ("**Numbers**: the **Sequence** numbers the bytes, so the receiver puts them **in order**; the **Ack** says *I got everything before this byte*. No Ack in time: the data is **sent again**.", tcp_step(("seq", "ack"))),
    ("**Flags**: what the segment does.", tcp_step(("flags",), legend=[("`SYN`", "hello, start"), ("`ACK`", "got it"), ("`FIN`", "goodbye, end"), ("`RST`", "no: refused or broken")])),
]

SS_OUT = """$ ss -tuln
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
udp   UNCONN 0      0      127.0.0.53%lo:53         0.0.0.0:*
udp   UNCONN 0      0            0.0.0.0:68         0.0.0.0:*
tcp   LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*
tcp   LISTEN 0      511          0.0.0.0:443        0.0.0.0:*
tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*"""
SSP_OUT = """$ sudo ss -tlnp
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*     users:(("systemd-resolve",pid=640,fd=19))
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*     users:(("nginx",pid=1033,fd=6))
LISTEN 0      128          0.0.0.0:22         0.0.0.0:*     users:(("sshd",pid=812,fd=3))
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*     users:(("nginx",pid=1033,fd=7))"""

page = chapter("transport", "Transport: ports, TCP and UDP", "Programs talk to programs", 22)
page("ports", "The port finds the program", "Ports", J(
    p("The transport layer has two jobs: **to which program** the data goes (the **port**), and **how** it is delivered (**TCP** or **UDP**, chosen by the program). It runs in the kernel, like IP."),
    scene("Ports", "A request to a web server, and how a program gets its port.", [("Who gets the data", PORTS_STEPS), ("Getting a port", GETPORT_STEPS)]),
))
page("standard", "Standard ports", "Every service has its usual port", J(
    duo(table(["Port", "Over", "Service"], [("`22`", "TCP", "SSH, remote shell"), ("`25`", "TCP", "SMTP, sending e-mail"), ("`53`", "UDP", "DNS"), ("`67` / `68`", "UDP", "DHCP, server / client"), ("`80`", "TCP", "HTTP, the Web"), ("`443`", "TCP", "HTTPS, the secure Web")]),
        table(["Port", "Over", "Service"], [("`123`", "UDP", "NTP, the time"), ("`143` / `993`", "TCP", "IMAP, reading e-mail"), ("`445`", "TCP", "SMB, Windows file sharing"), ("`3306`", "TCP", "MySQL / MariaDB"), ("`3389`", "TCP", "RDP, remote desktop"), ("`5432`", "TCP", "PostgreSQL")])),
    ul("`/etc/services` has the names of the ports: `ss` and `netstat` show `https` instead of `443` without `-n`",
       "`0` – `1023`: *well known*, only `root` may **listen** on them; `32768` – `60999`: given to clients"),
    quiz("A program wants to listen on port `8080`, another one on `80`. Which one needs `root`?", ["`8080`", "`80`", "both", "neither"], 1,
         "Ports below `1024` are reserved: only `root` may listen on them. `8080` is free for any user."),
))
page("tcpudp", "TCP and UDP", "Two ways to deliver", J(
    table(["", "📞 TCP", "📮 UDP"], [("like", "a phone call", "a postcard"), ("connection", "yes: first a *hello* (the handshake), then the data", "no: just send"),
        ("lost data", "sent again", "lost"), ("order", "the data arrives in order", "any order"), ("speed", "slower", "faster"),
        ("used by", "Web, SSH, e-mail", "DNS, DHCP, video calls, games")]),
    scene("TCP and UDP, message by message", "Time goes down; each arrow is one message.", [
        ("TCP connection", [(x[0], seq_svg(TCP_M, i), None) for i, x in enumerate(TCP_STEPS)]),
        ("TCP, a lost segment", [(x, seq_svg(LOST_M, i), None) for i, x in enumerate(LOST_STEPS)]),
        ("UDP question", [udp_scene_step(UDP_M, i, x) for i, x in enumerate(UDP_STEPS)]),
        ("UDP, lost", [udp_scene_step(UDPL_M, i, x) for i, x in enumerate(UDPL_STEPS)])]),
    p("Simplified: DNS also uses TCP for long answers, and the newest Web (HTTP/3) runs over UDP."),
))
page("headers", "The UDP datagram and the TCP segment", "Transport headers", J(
    scene("The transport headers", "UDP: ports and nothing more. TCP: UDP + numbers and flags.", [("UDP datagram", [(x, pic, None) for x, pic in HDR_UDP]), ("TCP segment", [(x, pic, None) for x, pic in HDR_TCP])], layout="stack"),
))
page("ss", "`ss`: who waits for data on this computer?", "Ports in Linux", J(
    term_out(SS_OUT, {5: ["127.0.0.53%lo:53"], 7: ["0.0.0.0:22"]}),
    table(["Part", "Means"], [("`-t -u -l -n`", "TCP, UDP, only the sockets that wait (*listening*), numbers not names"), ("`LISTEN`", "a TCP server waits for connections; `UNCONN`: a UDP socket (UDP has no connections)"),
                              ("`0.0.0.0:22`", "port 22, on every address of the computer"), ("`127.0.0.53%lo:53`", "port 53 only on the loopback: the local DNS cache (*systemd-resolved*)")], "k"),
    p("A **socket** is what a program uses to send and receive on a port. With `-p`, `ss` shows the program and its PID; only `root` may see the programs of other users:"),
    term_out(SSP_OUT, {4: ['"nginx",pid=1033']}),
    p("`netstat -tlnp` is the older command (*net-tools*, not installed by default on newer systems), with the same options; `ss` comes with `ip` (*iproute2*)."),
))
page("practice", "Cheat sheet and practice", "Transport", J(
    table(["Command", "Does"], [("`ss -tuln`", "the TCP and UDP ports that wait, as numbers"), ("`sudo ss -tlnp`", "… and the program of each"), ("`ss -tn`", "the TCP connections now (`ESTAB`)"),
                                ("`netstat -tlnp`", "the same, the older command"), ("`grep 443/ /etc/services`", "the name of a port")], "k"),
    term("ports", "The laptop: its ports", cmds=("ss -tuln",)),
))


# ================================================================ 08 DNS
def dns_svg(step, cached=False, short=False):
    """the laptop asks its DNS server (the resolver); the resolver asks the servers of the tree"""
    pc, rs = (60, 150), (270, 150)
    b = node("laptop", *pc, "laptop", LAPTOP, on=step in (0, 1) or (cached and step == 6))
    b += node("server", *rs, "DNS server", "the resolver", on=(step in (0, 1, 2, 3, 4, 5, 7) and not short and step != 0) or (short and step in (0, 1)) or cached)
    cards = [(".", "a root server", [("ro", "ask the ro server"), ("com", "ask the com server")], GREY),
             ("ro", "a ro server", [("upb.ro", "ask the upb.ro server"), ("gov.ro", "ask the gov.ro server")], AMBER),
             ("upb.ro", "an upb.ro server", [("upb.ro", "141.85.220.33"), ("www.upb.ro", "141.85.220.33")], GREEN)]
    def ask(a, z, q, ans=None):
        o = _a([(a[0] + 28, a[1] - 14), (z[0] - 28, z[1] - 14)], "hl", 2.4) + _t((a[0] + z[0]) / 2, a[1] - 22, q, 13, 700, HL, mono=True)
        if ans:
            o += _a([(z[0] - 28, z[1] - 2), (a[0] + 28, a[1] - 2)], "green", 2.4) + _t((a[0] + z[0]) / 2, a[1] + 16, ans, 13, 700, OKC, mono=True)
        return o
    if short:
        if step == 0:
            b += ask(pc, rs, "upb.ro?")
        if step == 1:
            b += ask(pc, rs, "upb.ro?", "141.85.220.33")
        if step == 2:
            b += node("server", 460, 150, "upb.ro", SRV, on=True) + _a([(88, 92), (432, 92)], "navy", 2.4) + _t(260, 80, "connects to 141.85.220.33", 13.5, 700, NAVY)
        return svgfig(520, 210, b, "The laptop asks its DNS server for a name, gets an address")
    for i, (k, title, rows, c) in enumerate(cards):
        y = 12 + i * 92
        on = step == 2 + i
        b += _r(470, y, 280, 80, (c[0], HL if on else c[1]), 8, 2.6 if on else 1.2) + _t(482, y + 21, title, 14, 800, a="start")
        for jj, (n, v) in enumerate(rows):
            yy = y + 44 + jj * 20
            if on and jj == 0:
                b += f'<rect x="476" y="{yy - 14}" width="268" height="19" rx="3" fill="{HLBG}"/>'
            b += _t(484, yy, n, 13, 700, INK, a="start", mono=True) + _t(578, yy, v, 13, 400, INK, a="start", mono=v[0].isdigit())
    if step == 1:
        b += ask(pc, rs, "upb.ro?")
    for i in range(3):
        if step == 2 + i:
            card = (470, 12 + i * 92 + 40)
            b += _a([(rs[0] + 26, rs[1] - 12), (card[0] - 6, card[1])], "hl", 2.4) + _a([(card[0] - 6, card[1] + 14), (rs[0] + 26, rs[1] + 4)], "green", 2.4)
    if step == 5 or step == 6:
        b += ask(pc, rs, "upb.ro?", "141.85.220.33")
    if cached and step == 6:
        b += tag(270, 60, ["in the cache: answered at once"], ("#e3f1e4", OKC), 13)
    if step == 7:
        b += tag(270, 60, ["cache: upb.ro = 141.85.220.33, for 1 hour (TTL)"], ("#e3f1e4", OKC), 13)
    return svgfig(760, 290, b, "The DNS server asks the servers of the tree, from the right of the name to the left")


DNS_SHORT = [("Computers use **IP addresses**, people use **names**. The laptop asks **its DNS server**: *what is the address of `upb.ro`?*", dns_svg(0, short=True), None),
             ("The DNS server answers with the address: `141.85.220.33`.", dns_svg(1, short=True), None),
             ("Only now does the laptop connect, to the **IP address**.", dns_svg(2, short=True), None)]
DNS_TREE = [
    ("The names are a **tree**: the root `.` knows who answers for `ro`, the `ro` servers know `upb.ro`, the `upb.ro` servers know its addresses. No server knows everything.", dns_svg(0), None),
    ("The laptop asks its DNS server, the **resolver** (usually the one of the Internet provider): *`upb.ro`?*", dns_svg(1), None),
    ("The resolver starts from the **right** of the name: it asks a **root** server, which only knows who answers for `ro`.", dns_svg(2), None),
    ("A `ro` server only knows who answers for `upb.ro`.", dns_svg(3), None),
    ("An `upb.ro` server knows the address: `141.85.220.33`.", dns_svg(4), None),
    ("The resolver gives the answer to the laptop.", dns_svg(5), None),
    ("The resolver **remembers** the answer, for a time set by the owner of the name (the **TTL** of the record).", dns_svg(7), None),
]
DNS_AGAIN = [("A minute later, the laptop (or any other computer that uses the same resolver) asks for `upb.ro` again: the answer is in the **cache**, no other server is asked.", dns_svg(6, cached=True), None)]

page = chapter("dns", "DNS", "Names instead of IP addresses", 14)
page("names", "Names instead of addresses", "DNS", J(
    p("The **Domain Name System** is the phone book of the Internet: it turns a name like `upb.ro` into an IP address."),
    scene("Finding a name", "The idea, then the whole way, then the cache.", [("The idea", DNS_SHORT), ("The whole way", DNS_TREE), ("Asked again", DNS_AGAIN)], layout="stack"),
))
page("linux", "DNS in Linux, and life without it", "host, resolvectl", J(
    duo(sh("""$ host upb.ro
upb.ro has address 141.85.220.33
upb.ro mail is handled by 0 ironport.upb.ro.
$ resolvectl dns
Global:
Link 2 (enp0s31f6):
Link 3 (wlp2s0): 192.168.1.1"""),
        ul("`host` asks the DNS server about a name; a name has several **records**: `has address` is an IPv4 address (an *A* record, *AAAA* for IPv6), `mail is handled by` the mail server (*MX*)",
           "`resolvectl dns` shows the DNS server the laptop asks: it came from DHCP (next chapter); `systemd-resolved` asks DNS for the programs (next lecture)")),
    duo(note("✅ Works without DNS", "everything with an **IP address**: `ping 8.8.8.8`, `ssh alice@192.168.1.10`, printers and shared folders by IP, names written in `/etc/hosts`, connections that were already open.", "blue"),
        note("❌ Fails without DNS", "everything with a **name**: `upb.ro` in the browser, `ping google.com`, e-mail, `dnf upgrade`. Even a site opened by IP may fail: one server hosts many sites, HTTPS certificates are for names.")),
    sh("""$ ping -c 1 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.4 ms
$ ping -c 1 google.com
ping: google.com: Temporary failure in name resolution"""),
    quiz("`ping 8.8.8.8` works, `ping google.com` says *Temporary failure in name resolution*. What is broken?", ["the Wi-Fi", "the default gateway", "DNS", "Google"], 2,
         "Packets reach the Internet (`8.8.8.8` answers), so the card, the address and the gateway work; only turning names into addresses fails: DNS."),
))
page("practice", "Cheat sheet and practice", "DNS", J(
    table(["Command", "Does"], [("`host NAME`", "the addresses (A, AAAA) and the mail server (MX) of a name"), ("`dig +short NAME`", "only the address"), ("`resolvectl dns`", "the DNS server of every card"), ("`cat /etc/hosts`", "names written by hand")], "k"),
    term("dns", "The laptop: names", cmds=("host upb.ro",)),
))


# ================================================================ 09 DHCP
def dhcp_svg(step, two=False):
    lp, ana, sw, rt, bog, r2 = (70, 70), (70, 210), (270, 140), (470, 70), (470, 210), (470, 210)
    b = wire(lp, sw) + wire(ana, sw) + wire(sw, rt) + wire(sw, bog)
    got = (not two and step >= 3) or (two and step == 4)
    addr = ("192.168.1.105/24" if not two else "10.0.0.23/24") if got else "no IP address yet"
    if two and step >= 5:
        addr = "192.168.1.105/24"
    b += node("laptop", *lp, "new laptop", addr, on=step in (0, 3), below=False)
    b += node("pc", *ana, "Ana", "192.168.1.10")
    b += icon("switch", *sw, 0.8) + _t(sw[0], sw[1] + 32, "switch", 13.5, 700)
    b += node("router", *rt, "home router", "DHCP server 192.168.1.1", on=step in (1, 2) and not two, below=False)
    if two:
        b += node("router", *r2, "second router", "DHCP server 10.0.0.1", on=step in (1, 4))
    else:
        b += node("pc", *bog, "Bogdan", "192.168.1.11")
    bc = [trail([(96, 80), (250, 132)]), trail([(250, 150), (96, 200)]), trail([(292, 132), (444, 80)]), trail([(292, 150), (444, 200)])]
    def msg(x, y, name, mac, ip, body, c=(HLBG, HL)):
        return tag(x, y, [("DHCP " + name, False, c[1], 800), ("MAC " + mac, True), ("IP  " + ip, True), body], c, 12.5)
    G, Rd = ("#e3f1e4", OKC), ("#fdecea", BADC)
    if not two:
        if step == 0:
            b += "".join(bc) + msg(270, 255, "DISCOVER", "laptop → ff:ff:…", "0.0.0.0 → 255.255.255.255", "is there a DHCP server?") + _t(108, 214, "ignores", 13, 700, MUTED, a="start") + _t(432, 214, "ignores", 13, 700, MUTED, a="end")
        if step == 1:
            b += trail([(444, 80), (292, 132)], "green") + trail([(250, 132), (96, 80)], "green") + msg(270, 255, "OFFER", "router → laptop", "192.168.1.1 → 192.168.1.105", "192.168.1.105/24, gateway and DNS .1, 24 h", G)
        if step == 2:
            b += "".join(bc[0:1] + bc[1:]) + msg(270, 255, "REQUEST", "laptop → ff:ff:…", "0.0.0.0 → 255.255.255.255", "I take 192.168.1.105 from 192.168.1.1")
        if step == 3:
            b += trail([(444, 80), (292, 132)], "green") + trail([(250, 132), (96, 80)], "green") + msg(270, 255, "ACK", "router → laptop", "192.168.1.1 → 192.168.1.105", "it is yours for 24 hours", G) + mark(112, 72, True)
    else:
        if step == 0:
            b += bc[0] + bc[2] + bc[3] + msg(270, 255, "DISCOVER", "laptop → ff:ff:…", "0.0.0.0 → 255.255.255.255", "is there a DHCP server?")
        if step == 1:
            b += trail([(444, 200), (292, 150)], "red") + trail([(250, 140), (96, 84)], "red") + msg(270, 255, "OFFER (1st)", "second router → laptop", "10.0.0.1 → 10.0.0.23", "10.0.0.23/24, gateway 10.0.0.1", Rd)
        if step == 2:
            b += trail([(444, 80), (292, 132)], "green") + msg(270, 255, "OFFER (2nd)", "router → laptop", "192.168.1.1 → 192.168.1.105", "too late: the laptop took the first one", G)
        if step == 3:
            b += bc[0] + bc[2] + bc[3] + msg(270, 255, "REQUEST", "laptop → ff:ff:…", "0.0.0.0 → 255.255.255.255", "I take 10.0.0.23 from 10.0.0.1")
        if step == 4:
            b += trail([(444, 200), (292, 150)], "red") + trail([(250, 140), (96, 84)], "red") + msg(270, 255, "ACK", "second router → laptop", "10.0.0.1 → 10.0.0.23", "it is yours", Rd)
        if step == 5:
            b += _l(300, 168, 330, 184, BADC, 3) + mark(320, 165, False) + tag(260, 268, ["DHCP snooping: only the port", "of the home router may answer"], G, 12.5) + trail([(444, 80), (292, 132)], "green") + trail([(250, 132), (96, 80)], "green")
    return svgfig(560, 300, b, "DHCP: four messages between the new laptop and the DHCP server")


def dhcp_state(n, cfg=None, bad=False):
    names = ["DISCOVER", "OFFER", "REQUEST", "ACK"]
    chips = "".join(f'<span class="dh-c{" on" if i < n else ""}{" cur" if i == n - 1 else ""}">{x}</span>' for i, x in enumerate(names))
    cfg = cfg or {}
    rows = "".join(f'<tr class="{"ch" if cfg.get(k) else ""}"><td>{k}</td><td><code>{cfg.get(k, "–")}</code></td></tr>' for k in ("address", "gateway", "DNS server", "lease"))
    return f'<div class="dh-s">{chips}</div><div class="sc-h">The laptop{" (no Internet!)" if bad else ""}</div><table class="t sc-t{" sc-bad" if bad else ""}">{rows}</table>'


OKCFG = {"address": "192.168.1.105/24", "gateway": "192.168.1.1", "DNS server": "192.168.1.1", "lease": "24 hours"}
BADCFG = {"address": "10.0.0.23/24", "gateway": "10.0.0.1", "DNS server": "10.0.0.1", "lease": "12 hours"}
DORA = [
    ("**DISCOVER**: the laptop has **no IP address** and does not know where the server is, so it asks **everyone**: a broadcast. Ana and Bogdan ignore it.", dhcp_svg(0), dhcp_state(1)),
    ("**OFFER**: only the DHCP server answers, with an **address** and a **mask**, the **gateway** and the **DNS server**.", dhcp_svg(1), dhcp_state(2)),
    ("**REQUEST**: the laptop takes the offer, **again with a broadcast**, so that every DHCP server hears its choice.", dhcp_svg(2), dhcp_state(3)),
    ("**ACK**: the server confirms. The address belongs to the laptop for **24 hours** (the *lease*); it renews it before it ends.", dhcp_svg(3), dhcp_state(4, OKCFG)),
]
TWO = [
    ("Someone plugs in a **second router**. The DISCOVER is a broadcast: it reaches **both** DHCP servers, and both answer.", dhcp_svg(0, True), dhcp_state(1)),
    ("The offer of the second router may be faster: it arrives **first**.", dhcp_svg(1, True), dhcp_state(2)),
    ("The offer of the home router arrives **second**: too late, the laptop takes the first one.", dhcp_svg(2, True), dhcp_state(2)),
    ("The laptop asks for `10.0.0.23`, with a broadcast: the home router sees it was not chosen and keeps `.105` free.", dhcp_svg(3, True), dhcp_state(3)),
    ("The laptop is now in the network of the second router: **no Internet**, or someone sees all its traffic.", dhcp_svg(4, True), dhcp_state(4, BADCFG, True)),
    ("The fix, in a managed switch: **DHCP snooping** drops the answers of the other ports; only the home router's offer arrives. The rule: **one** DHCP server in a network.", dhcp_svg(5, True), dhcp_state(4, OKCFG)),
]

NMSHOW = """$ nmcli device show wlp2s0 | grep IP4
IP4.ADDRESS[1]:                         192.168.1.105/24
IP4.GATEWAY:                            192.168.1.1
IP4.ROUTE[1]:                           dst = 192.168.1.0/24, nh = 0.0.0.0, mt = 600
IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.1.1, mt = 600
IP4.DNS[1]:                             192.168.1.1"""

page = chapter("dhcp", "DHCP", "Automatic network configuration", 14)
page("what", "Who gives a computer its address?", "DHCP", J(
    p("To reach the Internet a computer needs an **IP address and a mask**, a **default gateway** and a **DNS server**. They are set **by hand** (*static*: servers, printers) or received from a **DHCP server** (*dynamic*: everyone else). At home, the DHCP server runs on the home router."),
    scene("DHCP, message by message", "Four messages over UDP, from port 68 (the client) to port 67 (the server).", [("Four messages", DORA), ("Two DHCP servers", TWO)]),
    note("No answer?", "If no DHCP server answers, Windows and macOS pick a `169.254.x.x` address by themselves: only the local network works.", "blue"),
))
page("linux", "What the laptop received", "DHCP in Linux", J(
    term_out(NMSHOW, {2: ["192.168.1.105/24"], 3: ["192.168.1.1"], 6: ["192.168.1.1"]}),
    table(["Line", "Means"], [("`IP4.ADDRESS`", "the address and the mask"), ("`IP4.GATEWAY`", "the default gateway: the router, for every other network"), ("`IP4.ROUTE`", "the two lines of `ip route`"), ("`IP4.DNS`", "the DNS server: the router too")], "k"),
    p("The same, with the commands of the other chapters: `ip -br address`, `ip route`, `resolvectl dns`."),
    quiz("Why is the DHCP **REQUEST** a broadcast, when the laptop already knows the server?", ["the laptop has no MAC address", "so that every DHCP server hears which offer was taken", "because UDP has no unicast", "to ask the switch"], 1,
         "Several servers may have made offers; the broadcast tells all of them which one was chosen, so the others keep their addresses free."),
))


# ================================================================ 10 the home router
def home_svg(step):
    b = area(150, 14, 480, 296, "home router", "#5b6b71", right=True)
    ap, sw, rt = (260, 60), (260, 200), (555, 200)
    b += wire((60, 170), sw) + wire((60, 260), sw)
    b += node("pc", 60, 170, "PC", "192.168.1.105" if step >= 4 else None) + node("tv", 60, 260, "TV", "192.168.1.106" if step >= 4 else None)
    b += icon("switch", *sw, 0.9, on=step == 0) + _t(sw[0], sw[1] + 34, "switch", 14, 700)
    if step >= 1:
        b += radio((60, 60), ap) + node("phone", 60, 60, "phone", "192.168.1.107" if step >= 4 else None) + icon("ap", *ap, 1, on=step == 1) + _t(ap[0] + 34, ap[1] + 10, "access point", 14, 700, a="start")
    if step >= 2:
        b += wire((ap[0], ap[1] + 16), (sw[0], sw[1] - 14), HL if step == 2 else "#8a9aa0", 3) + _t(270, 132, "bridge: one network", 13, 700, HL if step == 2 else MUTED, a="start")
        b += _t(330, 300, "LAN 192.168.1.0/24, private", 13, 700, NAVY)
    if step >= 3:
        b += wire(sw, rt) + wire(rt, (690, 200)) + icon("router", *rt, 1, on=step == 3) + _t(rt[0], rt[1] + 36, "router", 14, 700) + _t(rt[0], rt[1] + 52, "192.168.1.1 | 203.0.113.42", 12, 400, MUTED, mono=True)
        b += icon("cloud", 700, 200) + _t(700, 236, "provider", 13, 700, MUTED)
    if step >= 4:
        for i, (n, k) in enumerate((("DHCP server", 4), ("DNS", 5), ("NAT", 6))):
            on = step == k
            b += _r(500, 40 + i * 34, 110, 26, ((HLBG, HL) if on else ("#fff", "#9aa9ae")), 5, 1.8 if on else 1) + _t(555, 58 + i * 34, n, 13.5, 800 if on else 500)
        b += _l(555, 140, 555, 180, "#9aa9ae", 1.4)
    if step == 5:
        b += tag(690, 110, ["upb.ro?", "forwards it to", "the provider"], (HLBG, HL), 12.5)
    if step == 6:
        b += tag(690, 110, ["leaves from", "203.0.113.42"], (HLBG, HL), 12.5)
    return svgfig(750, 316, b, "The home router: a switch, an access point, a bridge and a router in one box")


HOME_STEPS = [
    ("A **switch**: the LAN ports, for the wired devices.", home_svg(0), None),
    ("An **access point**: for the wireless devices.", home_svg(1), None),
    ("A **bridge** between them: Wi-Fi and Ethernet become **one network**, the LAN.", home_svg(2), None),
    ("A **router**, between the LAN and the provider: `192.168.1.1` inside, the **default gateway** of the home; a public address outside.", home_svg(3), None),
    ("A **DHCP server**: every device gets an address, the mask, the gateway and the DNS server `192.168.1.1`.", home_svg(4), None),
    ("**DNS**: the devices ask the router; it **forwards** the question to the provider and remembers the answers.", home_svg(5), None),
    ("**NAT**: the devices have **private** addresses; the router sends everything from its **one public** address. Add a **firewall**, and that is the box.", home_svg(6), None),
]

page = chapter("gateway", "The home router", "The box from your Internet provider: DHCP, DNS, NAT", 6)
page("box", "Four devices and three services in one box", "Home gateway", J(
    scene("Inside the home router", "Also called the *home gateway*.", [("Home router", HOME_STEPS)], layout="stack"),
    p("A Linux computer can do all of these: `dnsmasq` (DHCP and DNS), `nftables` (NAT and the firewall)."),
    quiz("At home, `ip route` says `default via 192.168.1.1` and `resolvectl dns` says `192.168.1.1`. What is `192.168.1.1`?", ["the DNS server of the provider", "the home router", "the laptop", "the access point only"], 1,
         "The home router is the gateway of the LAN and also the DNS server the devices ask (it forwards the questions); DHCP gave both addresses."),
))

# ================================================================ 11 capturing packets
CAP_ICMP = """$ sudo tcpdump -i wlp2s0 -n -t icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on wlp2s0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.1.105 > 141.85.220.33: ICMP echo request, id 7, seq 1, length 64
IP 141.85.220.33 > 192.168.1.105: ICMP echo reply, id 7, seq 1, length 64
^C
2 packets captured
2 packets received by filter
0 packets dropped by kernel"""
CAP_ARP = """$ sudo tcpdump -i wlp2s0 -n -t -e arp
3c:a9:f4:5e:21:7b > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.1.1 tell 192.168.1.105, length 28
70:b5:e8:2d:91:4c > 3c:a9:f4:5e:21:7b, ethertype ARP (0x0806), length 42: Reply 192.168.1.1 is-at 70:b5:e8:2d:91:4c, length 28"""


def fig_wireshark():
    W = 720
    b = _r(0, 0, W, 330, ("#fbfcfd", "#9aa9ae"), 8, 1.4) + f'<rect x="0" y="0" width="{W}" height="26" rx="8" fill="#e6edf0"/>'
    b += "".join(f'<circle cx="{16 + i * 16}" cy="13" r="5" fill="{c}"/>' for i, c in enumerate(("#ff5f57", "#febc2e", "#28c840"))) + _t(W / 2, 18, "Wireshark · cap.pcap", 13, 700, MUTED)
    b += _r(8, 32, W - 16, 24, ("#e3f1e4", "#82b366"), 4, 1.2) + _t(16, 49, "dns", 13.5, 700, INK, a="start", mono=True)
    rows = [("1", "0.000", "192.168.1.105", "192.168.1.1", "DNS", "query 0x1234 A upb.ro"), ("2", "0.004", "192.168.1.1", "192.168.1.105", "DNS", "response 0x1234 A 141.85.220.33")]
    y = 62
    b += f'<rect x="8" y="{y}" width="{W-16}" height="20" fill="#e6edf0"/>'
    cols = (14, 44, 104, 224, 344, 400)
    for x, h in zip(cols, ("No.", "Time", "Source", "Destination", "Proto", "Info")):
        b += _t(x, y + 15, h, 12.5, 700, INK, a="start")
    for i, r in enumerate(rows):
        yy = y + 22 + i * 20
        if i == 1:
            b += f'<rect x="8" y="{yy}" width="{W-16}" height="20" fill="#cfe3f7"/>'
        for x, v in zip(cols, r):
            b += _t(x, yy + 15, v, 12, 400, INK, a="start", mono=True)
    y = 132
    b += _l(8, y - 4, W - 8, y - 4, "#c3cdd1", 1)
    for i, (t, d) in enumerate((("Ethernet II", "Src: 70:b5:e8:2d:91:4c, Dst: 3c:a9:f4:5e:21:7b"), ("Internet Protocol Version 4", "Src: 192.168.1.1, Dst: 192.168.1.105"),
                                ("User Datagram Protocol", "Src Port: 53, Dst Port: 40211"), ("Domain Name System (response)", "upb.ro: type A, addr 141.85.220.33"))):
        c = [RED, ORANGE, AMBER, GREEN][i]
        b += f'<rect x="12" y="{y + i * 24 + 2}" width="10" height="16" fill="{c[0]}" stroke="{c[1]}"/>' + _t(30, y + i * 24 + 15, "▸ " + t + ", " + d, 12.5, 400, INK, a="start")
    y = 236
    b += _l(8, y - 4, W - 8, y - 4, "#c3cdd1", 1)
    hexl = ["0000  3c a9 f4 5e 21 7b 70 b5 e8 2d 91 4c 08 00 45 00   <.^!{p..-.L..E.", "0010  00 38 1a 2b 00 00 40 11 9c 41 c0 a8 01 01 c0 a8   .8.+..@..A......",
            "0020  01 69 00 35 9d 13 00 24 1f 2b 12 34 81 80 00 01   .i.5...$.+.4...."]
    for i, l in enumerate(hexl):
        b += _t(14, y + 16 + i * 19, l, 12, 400, INK, a="start", mono=True)
    def badge(x, y, n):
        return f'<circle cx="{x}" cy="{y}" r="11" fill="{HL}" stroke="#fff" stroke-width="2"/>' + _t(x, y + 5, str(n), 13, 800, "#fff")
    b += badge(W - 20, 44, 4) + badge(W - 20, 92, 1) + badge(W - 20, 170, 2) + badge(W - 20, 262, 3)
    return svgfig(W, 332, b, "The Wireshark window: the display filter, the packets, the layers of the selected packet, its bytes")


TROUBLE = [("1", "link", "Is the card **connected**? (physical, data link)", "`ip -br link`, `nmcli device status`", "plug in the cable, turn the Wi-Fi on, connect"),
           ("2", "network", "Do I have an **IP address**? (network)", "`ip -br address`", "DHCP failed: connect again"),
           ("3", "network", "Do I have a **gateway**? (network)", "`ip route`", "add the default gateway 📅"),
           ("4", "network", "Does the **Internet** answer? (network)", "`ping 8.8.8.8`", "the router or the provider"),
           ("5", "application", "Do **names** work? (DNS)", "`host upb.ro`", "set a DNS server 📅"),
           ("6", "transport", "Does the **server** answer? (transport, application)", "`curl -I https://upb.ro`", "the server, not my network")]

page = chapter("capture", "Capturing packets", "`tcpdump` and Wireshark: see what goes through the card", 18)
page("first", "`tcpdump`: every packet, one per line", "Capturing packets", J(
    p("`tcpdump` shows the packets that go in or out of a card. Here it waits for `ping` packets, while `ping -c 1 141.85.220.33` runs in another terminal:"),
    term_out(CAP_ICMP, {4: ["192.168.1.105 > 141.85.220.33", "ICMP echo request"], 5: ["ICMP echo reply"], 7: ["2 packets captured"]}),
    table(["Part", "Means"], [("`sudo`", "only `root` may read all the packets of a card"), ("`-i wlp2s0`", "the card to listen on"), ("`-n -t`", "numbers, not names; no time on each line"),
                              ("`icmp`", "a **filter**: only the ICMP packets"), ("`a > b`", "a packet from `a` to `b`"), ("[[Ctrl]] + [[C]]", "stops it; `dropped by kernel`: the packets `tcpdump` was too slow for, `0` is good")], "k"),
))
page("syntax", "The program, the options, the filter", "tcpdump syntax", J(
    syn("{a:sudo tcpdump} {b:[options]} {c:[filter]}"),
    p("The start is always `sudo tcpdump` (install it with `sudo dnf install tcpdump`). The **options** start with `-` and say *where* to listen and *how* to show the packets; the **filter** has no `-`, comes **last** and says *which* packets. Both are optional; all the words of a filter: `man pcap-filter`."),
    table(["Option", "Does"], [("`-D`", "list the cards `tcpdump` can listen on"), ("`-i wlp2s0`", "listen on this card; `-i any`: on all of them"),
        ("`-n`", "numbers, not names: addresses and ports"), ("`-t`", "no time at the start of each line"), ("`-e`", "the Ethernet header too: the MAC addresses"),
        ("`-v`", "more details (`-vv`, `-vvv`: even more)"), ("`-A`", "the data of each packet, as text"), ("`-c 10`", "stop after 10 packets"),
        ("`-w cap.pcap`", "save the packets in a file, show nothing"), ("`-r cap.pcap`", "read the packets from a file (no `root` needed)")], "k"),
))
page("filters", "A filter: what to look for, and its value", "tcpdump filters", J(
    table(["protocol (optional)", "direction (optional)", "type", "value"], [("`tcp` `udp` `ip` `arp` `icmp`", "`src` `dst`", "`host` `net` `port`", "an address, a network, a port")]),
    p("A protocol alone is a filter too (`icmp`, `arp`). Without a direction, `host` and `port` match **both ways**. `tcp` and `udp` go only before `port`; `ip` and `arp` only before `host` or `net`."),
    w("filter", set="prim"),
))
page("combine", "`not`, `and`, `or` and parentheses", "Combining filters", J(
    p("Join filters like words in a sentence: `not` keeps what does **not** match, `and` needs **both**, `or` **one** of them. Read `tcp dst port 443` as *TCP packets going to port 443*."),
    w("filter", set="combo"),
    bad("Parentheses without quotes", "`sudo tcpdump -n host 192.168.1.1 and (icmp or arp)` fails in bash: `(` and `)` mean something to the shell.", "put the filter in quotes: `sudo tcpdump -n 'host 192.168.1.1 and (icmp or arp)'`."),
))
page("frames", "`-e`: the frames, with their MAC addresses", "Capturing frames", J(
    p("With `-e`, `tcpdump` shows the Ethernet header too. Here ARP finds the MAC address of the gateway (each packet is **one** line in the terminal):"),
    term_out(CAP_ARP, {2: ["ff:ff:ff:ff:ff:ff", "ARP (0x0806)", "Request who-has 192.168.1.1 tell 192.168.1.105"], 3: ["Reply 192.168.1.1 is-at 70:b5:e8:2d:91:4c"]}),
    p("The question goes to **everyone** (broadcast); the gateway answers **only the laptop**. The *Type* field `0x0806` says: an ARP message, not an IP packet. `ip neigh` shows what the laptop found."),
))
page("wireshark", "Wireshark: the packets, in a window", "Wireshark", J(
    fig(fig_wireshark()),
    table(["", "Part"], [("1", "the **packets**, one per line, like `tcpdump`"), ("2", "the **layers** of the selected packet: Ethernet, IP, UDP, DNS"), ("3", "the **bytes**, as the card received them"),
                         ("4", "the **display filter**: `dns`, `ip.addr == 192.168.1.1`; not the language of `tcpdump`")]),
    p("Capture with `sudo tcpdump -i wlp2s0 -w cap.pcap` on any computer (a server has no screen), then open `cap.pcap` in Wireshark."),
))
page("practice", "Cheat sheet and practice", "Capturing packets", J(
    table(["Command", "Does"], [("`sudo tcpdump -D`", "the cards"), ("`sudo tcpdump -i wlp2s0 -n -c 5 icmp`", "5 ping packets, as numbers"),
                                ("`sudo tcpdump -n -e arp`", "ARP, with the MAC addresses"), ("`sudo tcpdump -n 'udp port 53'`", "DNS"),
                                ("`sudo tcpdump -w cap.pcap`, `tcpdump -r cap.pcap`", "save, read later (or in Wireshark)")], "k"),
    term("capture", "The laptop: capturing packets", "The laptop repeats a few packets (ARP, DNS, ping, HTTPS, SSH); `tcpdump` shows the ones your filter keeps.", ("sudo tcpdump -D",)),
))


# ================================================================ 12 troubleshooting
page = chapter("trouble", "No Internet? Troubleshooting", "What to check, from the bottom up", 14)
page("checks", "Check from the bottom up", "Troubleshooting", J(
    p("Each layer needs the ones below it: there is no point in checking DNS on a laptop without an address. Check **from the bottom up**; DNS **before** the server, since the name must be found first."),
    table(["", "The question", "The command", "If not"], [(n, q, c, f) for n, l, q, c, f in TROUBLE]),
    p("📅 how to set the gateway and the DNS server by hand: next lecture."),
    note("💡 \"Wi-Fi connected, but no Internet\"", "Check DNS early: when `ping 8.8.8.8` works but names do not, only DNS is broken.", "blue"),
))
page("lab", "The broken laptop", "Troubleshooting lab", J(
    p("Something is broken on this laptop. Run the checks, from the bottom up, then say which layer is broken. Each new problem is chosen at random."),
    term("", "Find what is broken", "Run the checks in the terminal, then answer under it. `reset` restores this problem; **New problem** picks another one.", side="trouble", variant="random"),
))


# ================================================================ flashcards
FLASH = [
    ("01", "Internet", "internet/layers", "Five layers", "Application, transport (ports), network (IP addresses), data link (MAC addresses), physical (bits)."),
    ("01", "Internet", "internet/encap", "Each layer adds a header", "Down the stack: data, segment, packet, frame, bits. The other side removes them going up."),
    ("01", "Internet", "internet/os", "Applications see sockets", "One network stack in the kernel, one driver for each card; the app does not know which card is used."),
    ("02", "Link", "link/nic", "A MAC address: 48 bits", "Manufacturer + card number; `ff:ff:ff:ff:ff:ff` is the broadcast; it never leaves the local network."),
    ("02", "Link", "link/iplink", "`NO-CARRIER`: no cable", "`ip -br link`: `UP` turned on, `LOWER_UP` connected, `NO-CARRIER` no signal."),
    ("03", "Ethernet", "ethernet/hub", "A hub repeats bits to all", "Layer 1: everyone receives everything, collisions, half duplex."),
    ("03", "Ethernet", "ethernet/switch", "A switch learns MACs", "From the source address of each frame; unknown destination or broadcast: flooding."),
    ("04", "Wi-Fi", "wifi/security", "WPA2 / WPA3: a key per device", "Open and WEP: everyone nearby reads everything, the AP is like a hub."),
    ("04", "Wi-Fi", "wifi/practice", "`nmcli` saves connections", "`device wifi connect` once with the password, then `device connect` or `connection up`."),
    ("05", "IP", "ip/mask", "The mask splits the address", "Network bits `1`, host bits `0`: `/24` = `255.255.255.0`; same network = same network bits."),
    ("05", "IP", "ip/special", "Private addresses", "`10/8`, `172.16/12`, `192.168/16`: not routed on the Internet; `127.0.0.1` is this computer."),
    ("05", "IP", "ip/packet", "TTL: one less at every router", "At `0` the packet is dropped; `ping` shows what is left."),
    ("06", "Routing", "routing/router", "MACs change, IPs stay", "Every router puts the same packet in a new frame for the next network."),
    ("06", "Routing", "routing/table", "The longest prefix wins", "`/24` directly in my network, `default` (`/0`) through the gateway; no line: `Network is unreachable`."),
    ("06", "Routing", "routing/traceroute", "`traceroute` uses the TTL", "TTL 1, 2, 3...: each router that drops one tells its address."),
    ("06", "Routing", "routing/nat", "NAT: one public address", "The home router rewrites the source of every packet going out, and remembers it for the answer."),
    ("07", "Transport", "transport/ports", "The port finds the program", "The IP address finds the computer; `443` is nginx, `22` sshd, `53` DNS."),
    ("07", "Transport", "transport/tcpudp", "TCP: a phone call; UDP: a postcard", "TCP connects first, resends lost data, keeps the order; UDP just sends."),
    ("07", "Transport", "transport/ss", "`ss -tuln`", "The ports that wait for data; `sudo ss -tlnp` adds the program."),
    ("08", "DNS", "dns/names", "DNS: a tree of servers", "The resolver asks the root, then `ro`, then `upb.ro`; the answers are cached for their TTL."),
    ("08", "DNS", "dns/linux", "IP works, names do not: DNS", "`ping 8.8.8.8` works, `ping google.com` fails: *Temporary failure in name resolution*."),
    ("09", "DHCP", "dhcp/what", "DHCP: DISCOVER, OFFER, REQUEST, ACK", "Address and mask, gateway, DNS server, for a lease; one DHCP server per network."),
    ("10", "Home router", "gateway/box", "The home router", "Switch, access point, bridge, router; DHCP, DNS forwarding, NAT, firewall."),
    ("11", "Capture", "capture/syntax", "`sudo tcpdump [options] [filter]`", "Options with `-` (`-i -n -c -e -w`), the filter last (`udp port 53`), in quotes if it has `(`."),
    ("12", "Troubleshooting", "trouble/checks", "From the bottom up", "card, address, gateway, Internet (`ping 8.8.8.8`), DNS (`host`), the server (`curl`)."),
]
page = chapter("flashcards", "Flashcards", "The ideas of the lecture, one card each", 10)
page("recap", "The ideas, in short", "Quick recap", J(
    '<p class="txt">One idea per card; the title is the idea, the text says why it matters in practice. <em>Recap</em> shows all the cards, <em>Flashcard</em> one at a time.</p>',
    flash_cards(FLASH)))

CSS = """
.pg h2{margin-top:34px}

/* ---- the interactive parts: a teal frame and a label (as in lectures 02, 03, 07 and 08) ---- */
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
.wd .wd-b.sb{grid-template-columns:minmax(0,1fr)}
.wd .wd-b.sb>div+div{border-left:0;border-top:1px solid var(--line)}
@container (min-width:840px){.wd .wd-b.sb{grid-template-columns:minmax(0,1fr) 300px}.wd .wd-b.sb>div+div{border-left:1px solid var(--line);border-top:0}}
@container (min-width:1150px){.wd .missions ol{grid-template-columns:1fr 1fr;column-gap:32px}}
.missions:not(.all):not(.fin) ol{display:block}
.missions:not(.all):not(.fin) li.ok,.missions:not(.all):not(.fin) li:not(.ok)~li{visibility:hidden;height:0;padding:0;overflow:hidden}
.missions .mall{margin-left:10px;border:1px solid #c9d5ec;background:#fff;border-radius:999px;padding:1px 10px;font-size:12px;color:var(--navy)}
.missions .mall:hover{background:#eef3fb}
.missions.fin .mall{display:none}
.missions .mnote{font-size:12px;color:var(--muted);margin-left:10px}

/* ---- step-by-step: selector and Back/Next on one bar, an orange strip, the picture ---- */
.ps-c{align-items:center;justify-content:space-between;gap:8px 16px;padding:10px 18px}
.ps-c .seg{flex:0 1 auto;min-width:0;flex-wrap:wrap}
.ps-nav{display:flex;align-items:center;gap:10px;margin-left:auto}
.ps-nav .btn{padding:7px 14px}
.ps-nav .btn[disabled]{opacity:.45;cursor:default}
.pdots{display:flex;align-items:center;gap:5px;flex-wrap:nowrap;padding:0 2px}.pdots i{flex:0 0 auto;width:9px;height:9px;border-radius:50%;background:#ccdbe0}.pdots i.dn{background:#00838f}.pdots i.on{background:#e65100;transform:scale(1.3)}
.ps-x{padding:8px 18px;background:#fff6ef;border-bottom:1px solid #f6d6bd;font-size:15px;line-height:1.45;min-height:46px}
.ps-x b,.ps-x strong{color:#c2410c}
.ps-x code{background:#fff;border:1px solid #f0d2bb;border-radius:4px;padding:0 4px}

/* ---- the scene widget: a picture per step, and the state it changes ---- */
.sc-b{display:grid;grid-template-columns:minmax(0,1fr);gap:0}
.sc-b>div{padding:8px 18px;min-width:0}
.sc-b .sc-st{border-top:1px solid var(--line);background:#fbfcfd}
@container (min-width:760px){.sc-b.side.two{grid-template-columns:minmax(0,1fr) 270px}.sc-b.side.two .sc-st{border-top:0;border-left:1px solid var(--line)}}
.sc-pic svg.f3{max-height:440px}
.sc-h{font:700 11.5px system-ui,sans-serif;letter-spacing:.7px;text-transform:uppercase;color:var(--navy);margin:2px 0 6px}
.sc-h code{text-transform:none;letter-spacing:0}
table.t.sc-t{margin:0 0 8px;font-size:13.5px;width:100%}
.sc-t td,.sc-t th{padding:4px 8px}
.sc-t td code{font-size:12.5px;white-space:normal;overflow-wrap:anywhere;background:none;padding:0}
.sc-t tr.ch td{background:#ffe6cc}.sc-t tr.ch td:first-child{color:#b35900;font-weight:700}
.sc-t tr.hit td{background:#e3f1e4}
.sc-t.sc-bad td{color:#b3261e}
.sc-row{display:flex;flex-wrap:wrap;gap:4px 22px}.sc-row>div{flex:1 1 240px;min-width:0}
.sc-n{font-size:14px;margin:4px 0 0;color:#33555f}.sc-n.sc-bad{color:#b3261e}
table.t.sc-xt{margin:8px 0 0;font-size:14px}
.sc-xt td{padding:5px 10px;vertical-align:top}
.sc-kv{display:flex;flex-wrap:wrap;gap:4px 18px;margin:8px 0 0;font-size:14.5px}.sc-kv span{white-space:nowrap}.sc-kv code{font-weight:700}.sc-xt td:first-child{white-space:nowrap;font-weight:700;color:var(--navy);width:1%}
pre.sh.sc-sh{margin:0;font-size:12.5px;white-space:pre-wrap;overflow-wrap:anywhere}
pre.sh.sc-sh .nw{color:#e65100;font-weight:700}
.ws-v{display:flex;align-items:center;gap:12px;border:2px solid;border-radius:12px;padding:8px 14px;margin:4px 0 10px}
.ws-v .ws-i{flex:0 0 70px}.ws-v small{display:block;font-size:12px;color:var(--muted)}.ws-v b{display:block;font-size:20px;letter-spacing:.5px}
.sc-st ul.k{margin:0;padding-left:18px;font-size:14px}
.dh-s{display:flex;flex-wrap:wrap;gap:4px;margin:0 0 10px}
.dh-c{font:700 11px system-ui,sans-serif;border:1px solid #c7d0d4;color:#9aa9ae;border-radius:5px;padding:3px 6px}
.dh-c.on{border-color:#d79b00;color:#8a4b00;background:#fff6ec}.dh-c.cur{background:#ffe6cc;box-shadow:0 0 0 1.5px #d79b00}

/* ---- marked parts of a static output ---- */
mark.nm{background:#ffe6cc;color:inherit;border-radius:3px;box-shadow:0 0 0 1.5px #f0b37a;padding:0 1px}
pre.sh mark.nm{color:#8a4b00}

/* ---- hub and switch ---- */
.st-c{align-items:center;gap:8px 14px;padding:10px 18px}
.st-c+.ps-x{min-height:72px}
.wd [hidden]{display:none!important}
.st-c{flex-wrap:wrap;gap:6px 14px;padding:8px 16px}
.st-c .seg button{padding:5px 8px;font-size:12.5px}
.st-c .btn{padding:6px 12px;font-size:14px;gap:6px}
.st-c .btn[disabled]{opacity:.45;cursor:default}
.st-more{flex-basis:100%;gap:6px}.st-more .chip{font-family:system-ui,sans-serif;font-size:12.5px}
.st-log{border-top:1px solid var(--line);padding:10px 18px 14px}
.st-log ol{margin:0;padding-left:24px;font-size:14px;display:grid;gap:2px;max-height:150px;overflow-y:auto}
.st-log li.on{font-weight:700;color:#b35900}.st-log li.st-none{list-style:none;margin-left:-24px;color:var(--muted);font-style:italic}
.rt-r{min-height:64px}
.st-c .seg button{padding:6px 10px}
.st-l{font:700 11.5px system-ui,sans-serif;color:var(--muted);text-transform:uppercase;letter-spacing:.6px}
.st-g{display:flex;align-items:center;gap:6px;flex-wrap:wrap}
.st-b{display:grid;grid-template-columns:minmax(0,1fr)}
.st-b>div{padding:10px 18px;min-width:0}
.st-b>div+div{border-top:1px solid var(--line);background:#fbfcfd}
@container (min-width:700px){.st-b{grid-template-columns:minmax(0,1fr) 250px}.st-b>div+div{border-top:0;border-left:1px solid var(--line)}}
.st-svg{display:block;width:100%;height:auto;max-height:330px}
.st-q{display:flex;gap:4px;margin-top:6px}.st-q i{width:22px;height:16px;border:1.5px solid #9aa9ae;border-radius:3px;background:#fff}.st-q i.f{background:#ffe6cc;border-color:#d79b00}

/* ---- mask calculator ---- */
.mk-c{align-items:center;gap:8px 14px;padding:10px 18px}
.mk-c input[type=text]{font:15px 'SF Mono',Menlo,monospace;border:1px solid #c9d5ec;border-radius:6px;padding:5px 8px;width:170px}
.mk-c input[type=range]{width:180px;accent-color:#00838f}
.mk-c label{display:flex;align-items:center;gap:8px;font-size:13px;font-weight:700;color:var(--muted)}
.mk-c .mk-n{font:800 16px 'SF Mono',Menlo,monospace;color:#e65100;min-width:38px}
.mk-b{padding:12px 18px;display:grid;gap:6px}
.mk-row{display:grid;grid-template-columns:minmax(0,1fr);gap:2px 12px;align-items:center}
@container (min-width:720px){.mk-row{grid-template-columns:92px minmax(0,1fr) 150px}}
.mk-k{font:700 12.5px system-ui,sans-serif;color:var(--muted)}
.mk-bits{display:flex;flex-wrap:wrap;gap:3px 9px}
.mk-by{display:flex;gap:1px}
.mk-by i{font:600 12.5px/20px 'SF Mono',Menlo,monospace;font-style:normal;width:14px;text-align:center;border:1px solid #d79b00;background:#ffe6cc;border-radius:2px}
.mk-by i.h{background:#d5e8d4;border-color:#82b366}
.mk-by i.cut{box-shadow:-3px 0 0 -1px #e65100}
.mk-d{font:700 14.5px 'SF Mono',Menlo,monospace;color:#004d65}
.mk-f{display:grid;grid-template-columns:minmax(0,1fr);gap:4px 18px;font-size:14.5px;margin-top:6px}
@container (min-width:720px){.mk-f{grid-template-columns:1fr 1fr}}
.mk-f b{color:var(--navy)}
.mk-same{display:flex;flex-wrap:wrap;align-items:center;gap:8px;border-top:1px solid var(--line);padding:10px 18px;font-size:14.5px}
.mk-same input{font:15px 'SF Mono',Menlo,monospace;border:1px solid #c9d5ec;border-radius:6px;padding:4px 8px;width:160px}
.mk-v.ok{color:#2e7d46;font-weight:700}.mk-v.no{color:#b3261e;font-weight:700}
.mk-err{color:#b3261e;font-size:14px}

/* ---- routing table ---- */
.rt-c{align-items:center;gap:8px 12px;padding:10px 18px}
.rt-c input[type=text]{font:15px 'SF Mono',Menlo,monospace;border:1px solid #c9d5ec;border-radius:6px;padding:5px 8px;width:170px}
.rt-c label{display:flex;align-items:center;gap:6px;font-size:13.5px}
.rt-b{padding:12px 18px}
table.t.rt-t{margin:0;font-size:14px;width:100%}
.rt-t td{vertical-align:middle}.rt-t td code{white-space:normal;background:none;padding:0}
.rt-t tr.off td{opacity:.35;text-decoration:line-through}
.rt-t tr.rt-win td{background:#ffe6cc}.rt-t tr.rt-win td:first-child{box-shadow:inset 3px 0 0 #d79b00}
.rt-t .y{color:#2e7d46;font-weight:700;white-space:nowrap}.rt-t .n{color:#b3261e;white-space:nowrap}
.rt-r{margin-top:10px;padding:8px 12px;border-radius:8px;font-size:15px;background:#e3f1e4;border:1px solid #82b366}
.rt-r.rt-bad{background:#fdecea;border-color:#b85450}

/* ---- tcpdump filters ---- */
.tf-c{display:grid;gap:8px;padding:10px 18px}
.tf-in{display:flex;flex-wrap:wrap;align-items:center;gap:6px;font:14.5px 'SF Mono',Menlo,monospace}
.tf-in b{color:#004d65}
.tf-in input{flex:1 1 240px;min-width:0;font:15px 'SF Mono',Menlo,monospace;border:1.5px solid #6c8ebf;background:#eef4fb;border-radius:6px;padding:5px 8px}
.tf-in input.tf-err{border-color:#b85450;background:#fdecea}
.tf-ch{display:flex;flex-wrap:wrap;gap:5px}
.tf-x{padding:8px 18px;border-top:1px solid var(--line);border-bottom:1px solid var(--line);font-size:14.5px;background:#f6fafa;min-height:40px}
.tf-x.tf-xbad{background:#fdecea;color:#b3261e}
.tf-why{color:#5b2a26}.chip.tf-bad{border-color:#e3a19a;color:#b3261e}
.tf-l{list-style:none;margin:0;padding:8px 18px 12px;font:12.5px/1.5 'SF Mono',Menlo,Consolas,monospace;display:grid;gap:2px}
.tf-l li{padding:2px 8px;border-radius:5px;color:#9aa9ae;white-space:pre-wrap;overflow-wrap:anywhere}
.tf-l li.m{color:#1f2d33;background:#eef4fb;box-shadow:inset 3px 0 0 #6c8ebf}

/* ---- the laptop terminals: the terminal takes the whole width (an output line of nmcli or ss fits on one line),
   the panel of the laptop goes under it, in columns ---- */
.wd .wd-b.sb.ext{grid-template-columns:minmax(0,1fr)!important}
.wd .wd-b.sb.ext>div+div{border-left:0!important;border-top:1px solid var(--line)!important}
.wd .wd-b.sb.ext .term{font-size:13px;overflow-x:auto}
.wd .wd-b.sb.ext .term .tout>div{white-space:pre;word-break:normal;overflow-wrap:normal}
.extp .nl-cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:4px 28px;align-items:start}
.extp .nl-cols .nl-h:not(:first-child){margin-top:0}
.extp .nl-cols>div>.nl-h+.nl-h,.extp .nl-cols>div>table+.nl-h{margin-top:12px}
.extp .nl-what{margin-top:0}
/* ---- the laptop panel ---- */
.extp{padding:12px 14px;font-size:13.5px}
.nl-h{font:700 11.5px system-ui,sans-serif;letter-spacing:.7px;text-transform:uppercase;color:var(--navy);margin:0 0 6px}
.nl-h:not(:first-child){margin-top:12px}
table.nl-t{width:100%;border-collapse:collapse;font-size:13px}
.nl-t td{padding:3px 6px;border-bottom:1px solid #e6edf0;vertical-align:top}
.nl-t td:first-child{font:700 12.5px 'SF Mono',Menlo,monospace;color:#004d65;white-space:nowrap}
.nl-t code{font-size:12.5px;background:none;padding:0;white-space:normal;overflow-wrap:anywhere}
.nl-up{color:#2e7d46;font-weight:700}.nl-down{color:#b3261e;font-weight:700}.nl-dim{color:#9aa9ae}
.nl-what{margin-top:12px;padding:8px 10px;border-radius:8px;background:#fff6ec;border:1px solid #f0d2bb;font-size:13.5px;line-height:1.45}
.nl-what b{color:#b35900}
.tb-ck{list-style:none;margin:0;padding:0;display:grid;gap:3px}
.tb-ck li{display:flex;gap:8px;align-items:baseline;font-size:13.5px;color:#5b6b71}
.tb-ck li i{font-style:normal;flex:0 0 18px;text-align:center}
.tb-ck li.done{color:#1f2d33}.tb-ck li.done i{color:#2e7d46}
.tb-ans{display:grid;grid-template-columns:1fr 1fr;gap:5px;margin-top:6px}
.tb-ans button{border:1px solid #c9d5ec;background:#fff;border-radius:8px;padding:6px 6px;font-size:13px;font-weight:650;color:var(--navy)}
.tb-ans button:hover{background:#eef3fb}
.tb-ans button.ok{background:#e3f1e4;border-color:#82b366;color:#2e7d46}.tb-ans button.no{background:#fdecea;border-color:#b85450;color:#b3261e}
.tb-fb{margin-top:8px;font-size:13.5px;line-height:1.45}
.tb-new{margin-top:8px}

svg.f3{display:block;width:100%;height:auto;margin:0 auto}

/* ---- tables wrap instead of scrolling sideways; terminals wrap their long lines ---- */
.pg table.t td code,.pg table.t th code{white-space:normal}
.pg table.t.k td:first-child{white-space:normal}
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

/* the terminals stay in the column (extra.css widens them for a 1180 px page; this page is wider on large screens) */
[data-w=shell]{margin-right:0!important}

/* ---- every widget fits a laptop screen (1280 x 720: ~575 px between the top and the bottom bar), no scrolling ---- */
.wd-h{padding:9px 18px}
.wd-h h3{font-size:18px}
.wd-h h3::before{display:inline-block;vertical-align:3px;margin:0 10px 0 0}
.wd-h p{margin-top:2px}
.ps-c{padding:7px 18px}
.ps-x{padding:6px 18px;line-height:1.4;min-height:0}
.sc-b>div{padding:6px 18px}
.sc-pic svg.f3{max-height:min(var(--cap,360px),calc(100vh - 330px))}
.sc-n2{margin-top:0}.sc-fr table.t.sc-t{margin-bottom:2px}.sc-fr .sc-h{margin-bottom:4px}.sc-fr>div:first-child{flex:2 1 520px}.sc-fr>div+div{flex:1 1 230px}
table.t.sc-t td.ch{background:#ffe6cc;color:#b35900}table.t.sc-t td.ch code{font-weight:700}
table.t.sc-t td,table.t.sc-t th{padding:3px 8px}
table.t.sc-t{margin-bottom:6px}
table.t.sc-xt td{padding:3px 10px}
@container (min-width:760px){.sc-b.side.two{grid-template-columns:minmax(0,1fr) 300px}}
/* hub and switch: a wider column on the right, the list of frames sent under the tables */
@container (min-width:700px){.st-b{grid-template-columns:minmax(0,1fr) 310px}}
.st-b>div{padding:8px 16px}
.st-svg{max-height:290px}
.st-c+.ps-x{min-height:0}
.st-log{padding:5px 18px 6px}
.st-lh{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:4px 12px;margin-bottom:4px}.st-lh .sc-h{margin:0}
.st-more{flex-basis:auto}
.st-log ol{font-size:13.5px;max-height:44px;gap:0}
/* the free switch: three frames of the list visible (the picture a bit smaller to make room) */
[data-mode=free] .st-log ol{max-height:66px}
[data-mode=free] .st-svg{max-height:278px}
[data-mode=free] .st-b>div{padding:6px 16px}
[data-mode=free] .st-log{padding:4px 18px 5px}[data-mode=free] .st-lh{margin-bottom:2px}
.st-fr{font-size:13px;line-height:1.35}.st-fr small{color:var(--muted)}
.sc-t td small{color:var(--muted)}
/* the filters: a denser list of packets */
.tf-c{gap:6px;padding:8px 18px}
.tf-ch .chip{padding:3px 9px;font-size:12px}
.tf-x{padding:6px 18px;min-height:0}
.tf-l{padding:6px 18px 10px;gap:1px;line-height:1.3}
.tf-l li{padding:1px 8px}
/* the laptop terminals: the terminal grows with the height of the screen, the panel and the missions are compact */
.wd.extw .cmdchips{padding:7px 18px}
.wd .wd-b.sb.ext .term{height:clamp(180px,calc(100vh - 525px),360px)}
.wd.extw .wd-f{display:none}
.wd.extw .missions{padding:8px 18px}
.extp{padding:8px 14px}
.nl-t td{padding:2px 6px}
.nl-what{padding:6px 10px}
.extp .nl-cols{grid-template-columns:repeat(auto-fit,minmax(200px,1fr))}
.tb-ck{gap:1px}
.tb-ans{grid-template-columns:repeat(3,minmax(0,1fr))}
.tb-ans button{padding:5px 6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
@container (min-width:760px){.extp .nl-cols:has(.tb-ans){grid-template-columns:minmax(0,1fr) minmax(0,1.5fr)}}
.tb-fb{margin-top:6px}
.tb-new{margin-top:6px;padding:5px 12px}
"""

META = dict(
    num="09", key="iso-09-network-v1", short="Network Infrastructure",
    title="Network Infrastructure, step by step · ISO Lecture 09",
    description="ISO Lecture 09 – Network Infrastructure: layers, MAC addresses, Ethernet, hubs and switches, Wi-Fi and nmcli, IP addresses and masks, ping, routing, traceroute and NAT, ports, TCP and UDP, DNS, DHCP, the home router, tcpdump and troubleshooting, with simulators and a demo laptop.",
    title_html="Network infrastructure, step by step:<br><span>from the card to the Internet.</span>",
    lead="How your data, cut into pieces, travels from the network card, through switches and routers, to a program on another computer, and how Linux shows every step: <code>ip</code>, <code>ping</code>, <code>nmcli</code>, <code>ss</code>, <code>tcpdump</code>.",
    features="frames and packets, step by step · hub, switch, mask, routing and filter simulators · a demo laptop with missions",
    starth="Start with the Internet.",
    maphead="From the network card to DNS, DHCP and troubleshooting.",
    how="Text, figures and the simulators were generated with Claude (Anthropic) from the slides of lecture 09 – Network Infrastructure, following the structure of the interactive lectures 02, 03, 07 and 08. The step-by-step pictures are the animations of the slides, redrawn; the demo laptop simulates the network commands of the lecture.",
    checked="The outputs of the demo laptop were checked against the terminals of the slides (ip, ping, traceroute, nmcli, ss, netstat, host, resolvectl, tcpdump); the mask calculator, the routing table and the tcpdump filters were tested on the examples of the slides. It is a teaching model, not a real network: only the commands and addresses of the lecture exist.",
)

if __name__ == "__main__":
    render(COURSE, META, OUT, js=["dev.js", "widgets09.js"], css=CSS)
