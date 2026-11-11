"""The colors of the ISO slides (diatypst, title-color #004d65, and the colors of
terminal.typ, diagram.typ and params.typ) mapped onto the course kit CSS."""

# kit color -> deck color
MAP = {
    "#233254": "#004d65",   # navy: titles, headings (deck title-color)
    "#3559a6": "#006483",   # blue: links, accents (petrol, lighter)
    "#328d86": "#00838f",   # teal: current step, buttons (deck option color)
    "#216c66": "#004d65",   # dark teal: eyebrows
    "#eef7f5": "#e6edf0",   # pale: the fill of the code blocks of the slides
    "#252c38": "#1f2a2e",   # ink
    "#5c687a": "#5b6b71",   # muted
    "#dbe3eb": "#ccdbe0",   # lines
    "#f6f8fb": "#f4f7f8",   # wash
    "#936013": "#b35900",   # amber (shell-var-color)
    "#f3eadb": "#fbeee0",
    "#c0392b": "#c62828",   # red (fs-gone-color)
    "#9b3326": "#b3261e",
    "#b5651d": "#b35900",
    "#c8d4df": "#b8cdd4", "#a9cfc9": "#99c2cc", "#cfe3df": "#c4d9df", "#f3faf8": "#f1f6f8",
    "#b9d6d1": "#b8cdd4", "#9fd3cc": "#8fd0dc", "#e4ece9": "#dce7ea", "#f3f8f7": "#eef4f6",
    "#f2f5fb": "#eef3f6", "#c9d5ec": "#b8cdd4", "#f4f7fc": "#eef4f6", "#e9effa": "#e0ebef",
    "#a9c3e8": "#99c2cc", "#f7f9fd": "#f3f7f8", "#e2efed": "#dfeef1", "#d6ece9": "#d3e6eb",
    "#d9e6e3": "#d3e6eb", "#e3e9f6": "#e3edf0", "#e9eef5": "#e6edf0", "#8a96a6": "#7d8d93",
    "#1d2b4a": "#004d65", "#eef2f7": "#e6edf0", "#f3f7fc": "#eef4f6", "#eef3fb": "#e0ebef",
    "rgba(35,50,84,": "rgba(0,77,101,",
}

# rules added after the kit and extra.css
CSS = """
/* ---- ISO deck theme ---- */
h1,h2,h3,.hero h1,.pg h1{font-family:"Libertinus Serif","Linux Libertine O","Linux Libertine",Georgia,"Times New Roman",serif;letter-spacing:-.3px}
.hero h1{letter-spacing:-1px;font-weight:600}
.topbar{background:#004d65;border-bottom:0}
.brand{color:#fff}.brand span{color:#a9d3df}
.brand svg{width:34px;height:40px}
.nav a{color:#cfe6ec}
.nav a.on{color:#fff;box-shadow:0 2px #fff}
.nav a.mapbtn{background:#fff;color:#004d65}
.nav a.mapbtn svg path{stroke:#00838f}
.nav a.mapbtn:hover{background:#e6edf0}
.nav a.mapbtn.on{background:#00838f;color:#fff}.nav a.mapbtn.on svg path{stroke:#fff}
.hero h1 span{color:#00838f}
/* terminals: light, like ```terminal``` in the slides */
pre.sh{background:#e6edf0;color:#1f2a2e;border:1px solid #d3e0e5}
pre.sh .p{color:#004d65}
pre.sh .c{color:#1f2a2e;font-weight:400}
pre.sh .cn{color:#004d65;font-weight:700}
pre.sh .fl{color:#9a4d76}
pre.sh .st{color:#2e7d46}
pre.sh .o{color:#4f5b60}
pre.sh .k{color:#828282}
pre.sh .mk{background:#fde5d4;color:#e65100;font-weight:700}
pre.sh .mk2{background:#d6eef0;color:#00838f;font-weight:700}
pre.sh .mk3{background:#ecdff2;color:#6a1b9a;font-weight:700}
.syn .a{color:#e65100}.syn .b{color:#6a1b9a}.syn .c{color:#00838f}
.tcol{background:#0c0c0c;display:flex;flex-direction:column}
.tbar{display:flex;align-items:center;gap:7px;background:#2b2b2b;color:#d0d0d0;padding:7px 12px;font:600 12.5px "Ubuntu","Cantarell",system-ui,sans-serif;border-bottom:1px solid #000}
.tbar i{width:11px;height:11px;border-radius:50%;background:#5a5a5a}.tbar i:first-child{background:#e95420}
.tbar span{flex:1;text-align:center;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.tbar .demo{font:700 10.5px system-ui,sans-serif;letter-spacing:1px;color:#0c0c0c;background:#f6c343;border-radius:4px;padding:2px 6px}
.term{background:#0c0c0c;color:#d3d7cf;font-family:"Ubuntu Mono","DejaVu Sans Mono","Liberation Mono",Menlo,Consolas,monospace;font-size:13.5px}
.term .cmd{color:#d3d7cf}
.term .pr{color:#d3d7cf;font-weight:400}
.term .pu{color:#8ae234;font-weight:700}.term .pp{color:#729fcf;font-weight:700}
.term .dir{color:#729fcf;font-weight:700}
.term .lnk{color:#34e2e2;font-weight:700}.term .dev{color:#fce94f;font-weight:700}
.term .err{color:#d3d7cf}
.term .dim{color:#8a8a8a}.term .dim b{color:#fff}
.tline input{color:#d3d7cf;caret-color:#d3d7cf}
.term::-webkit-scrollbar{width:8px}.term::-webkit-scrollbar-thumb{background:#444;border-radius:4px}
.nano,.nano textarea{background:#0c0c0c;color:#d3d7cf;font-family:"Ubuntu Mono","DejaVu Sans Mono",Menlo,monospace}
.nbar{background:#d3d7cf;color:#0c0c0c}.nbar.nk b{background:#0c0c0c;color:#d3d7cf}
.v86s{background:#000}
@media (max-width:720px){.term{font-size:12px}}
.chip{border-color:#b8cdd4;color:#004d65}
.chip:hover{background:#e6edf0;border-color:#00838f}
.calcp .x1{color:#e65100;background:#fde5d4}.calcp .x2{color:#6a1b9a;background:#ecdff2}.calcp .x3{color:#00838f;background:#d6eef0}
.calcp .r{color:#2e7d46}.calcp .w{color:#004d65}
"""

FONT = '<link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Libertinus+Serif:wght@400;600;700&display=swap" rel="stylesheet">'


def apply(css):
    for a, b in MAP.items():
        css = css.replace(a, b).replace(a.upper(), b)
    return css + CSS
