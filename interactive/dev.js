/* ISO lecture 07 widgets: the C pipeline (data-w="pipe"), make (data-w="make"); the git terminal is in shell-git.js */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
/* syntax highlighting (the same classes as the Python one) */
const tok=(text,rules)=>{const big=new RegExp(rules.map(([r],i)=>'(?<g'+i+'>'+r+')').join('|'),'gm');let out='',pos=0,m;
  while((m=big.exec(text))){if(!m[0]){big.lastIndex++;continue}out+=esc(text.slice(pos,m.index));const i=+Object.keys(m.groups).find(k=>m.groups[k]!==undefined).slice(1);const c=rules[i][1];out+=c?'<span class="hl-'+c+'">'+esc(m[0])+'</span>':esc(m[0]);pos=m.index+m[0].length}
  return out+esc(text.slice(pos))};
const HL={
  c:[[String.raw`//[^\n]*|/\*[\s\S]*?\*/`,'c'],[String.raw`"(?:\\.|[^"\\])*"|<[\w./]+\.h>`,'s'],[String.raw`^[ \t]*#[ \t]*\w+`,'p'],[String.raw`\b(?:int|void|char|const|return|for|while|if|else|extern)\b`,'k'],[String.raw`\b\d+\b`,'n'],[String.raw`\b[A-Za-z_]\w*(?=\s*\()`,'f']],
  asm:[[String.raw`#[^\n]*`,'c'],[String.raw`^[.\w]+:`,'t'],[String.raw`\$\w+|%\w+`,'n'],[String.raw`^\s+[a-z]+`,'k'],[String.raw`[\w.]+@PLT`,'f']],
  make:[[String.raw`#[^\n]*`,'c'],[String.raw`^\.PHONY`,'p'],[String.raw`^[A-Za-z_]\w*(?=\s*=)`,'v'],[String.raw`^[^\s:#=][^:=\n]*(?=:)`,'t'],[String.raw`\$\(\w+\)`,'v'],[String.raw`\$[@<^]`,'a'],['%','a']],
};
const hl=(t,l)=>window.ISOHL&&l!=='none'?window.ISOHL(t,l):HL[l]?tok(t,HL[l]):esc(t);
const shc=t=>t.split('\n').map(l=>l.startsWith('$ ')?(()=>{const[c,com]=l.slice(2).split(/\s{2,}#/);return '<span class="p">$</span> <span class="c">'+esc(c)+'</span>'+(com?'<span class="k">  #'+esc(com)+'</span>':'')})():'<span class="o">'+esc(l)+'</span>').join('\n');

/* ---------- the C compilation pipeline ---------- */
const SRC=`#include <stdio.h>

#define TIMES 3

int main(void)
{
    // say hello a few times
    for (int i = 0; i < TIMES; i++) {
        printf("Hello, %d!\\n", i);
    }
    return 0;
}`;
const PSTEPS=[
  {f:'hello.c',k:'C source',tool:null,show:SRC,lang:'c',
   cmd:'$ gcc hello.c -o hello  # the four steps at once\n$ ./hello\nHello, 0!\nHello, 1!\nHello, 2!',
   t:'The source',x:'What you write: C, as text. <code>#include</code> and <code>#define</code> are orders for the preprocessor. <code>printf</code> is not written here: it is in the C library.'},
  {f:'hello.i',k:'C, expanded',tool:'preprocessor',flag:'-E',lang:'c',show:'extern int printf (const char *__restrict __format, ...);\n/* ... 800 more lines from stdio.h ... */\n\nint main(void)\n{\n\n    for (int i = 0; i < 3; i++) {\n        printf("Hello, %d!\\n", i);\n    }\n    return 0;\n}',
   cmd:'$ gcc -E hello.c -o hello.i\n$ wc -l hello.c hello.i\n   12 hello.c\n  825 hello.i',
   t:'Step 1 · the preprocessor',x:'Copies <code>stdio.h</code> in (800 lines, the declaration of <code>printf</code> among them), replaces <code>TIMES</code> with <code>3</code>, drops the comment. The result is still C, still text.'},
  {f:'hello.s',k:'assembly',tool:'compiler',flag:'-S',lang:'asm',show:'main:\n    ...\n    movl    $0, -4(%rbp)      # i = 0\n    jmp     .L2\n.L3:\n    ...\n    call    printf@PLT        # only a call\n    addl    $1, -4(%rbp)      # i++\n.L2:\n    cmpl    $2, -4(%rbp)      # i <= 2 ?\n    jle     .L3',
   cmd:'$ gcc -S hello.c\n$ ls\nhello.c  hello.s',
   t:'Step 2 · the compiler',x:'Translates C to <b>assembly</b>: one line per CPU instruction, for <b>one</b> processor (here x86-64). The loop became a compare (<code>cmpl</code>) and a jump (<code>jle</code>). <code>printf</code> is only <i>called</i>: its code is not here.'},
  {f:'hello.o',k:'object file',tool:'assembler',flag:'-c',lang:'none',show:'0000000000000000 <main>:\n   4: 55               push %rbp\n   5: 48 89 e5         mov  %rsp,%rbp\n  ...\n  29: e8 00 00 00 00   call ???   # printf: not known yet\n  2e: 83 45 fc 01      addl $0x1,-0x4(%rbp)',
   cmd:'$ gcc -c hello.c\n$ file hello.o\nhello.o: ELF 64-bit LSB relocatable, x86-64\n$ nm hello.o\n0000000000000000 T main\n                 U printf',
   t:'Step 3 · the assembler',x:'Turns the assembly into <b>machine code</b>: an <b>object file</b>, not runnable yet. <code>nm</code> shows <code>T main</code> (defined here) and <code>U printf</code> (used, but <b>undefined</b>): the call still goes to address <code>00 00 00 00</code>.'},
  {f:'hello',k:'executable',tool:'linker',flag:'',lang:'none',show:null,cmd:null,
   t:'Step 4 · the linker',x:'Joins the object files with the libraries and fills in the address of every function: the call to <code>printf</code> now goes somewhere.'},
];
const LINK={
  dynamic:{cmd:'$ gcc hello.o -o hello\n$ file hello\nhello: ELF 64-bit ..., dynamically linked\n$ ldd hello\nlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6\n$ ls -sh hello\n12K hello',
    show:'hello  (12K)\n├── main         the code of hello.c\n└── printf  ──▶  in libc.so.6, loaded when hello starts',
    x:'<b>Dynamic</b> (the default): <code>printf</code> stays in <code>libc.so.6</code>, connected when the program starts. A small file; one copy of libc for every program.'},
  static:{cmd:'$ gcc -static hello.o -o hello-static\n$ file hello-static\nhello-static: ELF 64-bit ..., statically linked\n$ ldd hello-static\nnot a dynamic executable\n$ ls -sh hello-static\n636K hello-static',
    show:'hello-static  (636K)\n├── main         the code of hello.c\n└── printf       copied from libc.a, inside the file',
    x:'<b>Static</b> (<code>-static</code>): the code of <code>printf</code>, and of what it needs, is copied into the file. Runs without libc installed, but 50 times larger.'},
};
function wPipe(root){
  let i=0, ln='dynamic';
  root.innerHTML=`<div class="wd pipe"><div class="wd-h"><div><h3>From hello.c to an executable</h3><p>One <code>gcc hello.c -o hello</code> runs four programs, one after the other. Click a file or an arrow, or use <b>Next</b>.</p></div><span class="badge" data-r="b"></span></div>
  <div class="pflow" data-r="flow"></div>
  <div class="pdrv"><span>gcc is only a <i>driver</i>: it runs <code>cc1</code> (steps 1 and 2), <code>as</code> (3) and <code>ld</code> (4). <code>gcc -v</code> shows them.</span></div>
  <div class="pexp"><div><div class="pst" data-r="t"></div><p data-r="x"></p></div><div class="seg" data-seg="ln" data-r="lk" hidden><button type="button" data-v="dynamic" class="on">dynamic (default)</button><button type="button" data-v="static">static (-static)</button></div></div>
  <div class="ppanes"><div><div class="ppf" data-r="fn"></div><pre class="sh ppcode" data-r="show"></pre></div><div><div class="ppf">in a terminal</div><pre class="sh" data-r="cmd"></pre></div></div>
  <div class="pnav"><button type="button" class="btn ghost" data-r="prev">← Back</button><span class="pdots" data-r="dots"></span><button type="button" class="btn" data-r="next">Next step →</button></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  function draw(){
    const S=PSTEPS[i], st=k=>k===i?'on':k<i?'dn':'todo';
    q('flow').innerHTML=PSTEPS.map((p,k)=>(p.tool?`<button type="button" class="parr ${k===i?'on':k<i?'dn':''}" data-k="${k}" aria-label="step ${k}: ${p.tool}"><span class="pt">${p.tool}</span><span class="pl"></span><code>gcc${p.flag?' '+p.flag:''}</code></button>`:'')+
      `<button type="button" class="pcard ${st(k)}" data-k="${k}"><b>${k===4&&ln==='static'?'hello-static':p.f}</b><span>${p.k}</span></button>`).join('');
    q('flow').querySelectorAll('[data-k]').forEach(b=>b.addEventListener('click',()=>{i=+b.dataset.k;draw()}));
    const L=i===4?LINK[ln]:null;
    q('lk').hidden=i!==4;
    q('t').textContent=S.t;
    q('x').innerHTML=S.x+(L?' '+L.x:'');
    q('fn').innerHTML=`inside <b>${i===4&&ln==='static'?'hello-static':S.f}</b> · ${S.k}`;
    q('show').innerHTML=L?esc(L.show):hl(S.show,S.lang);
    q('cmd').innerHTML=shc(L?L.cmd:S.cmd);
    q('b').textContent=i===0?'the source':'step '+i+' / 4';
    q('dots').innerHTML=PSTEPS.map((p,k)=>`<i class="${k===i?'on':k<i?'dn':''}"></i>`).join('');
    q('prev').disabled=i===0; q('next').disabled=i===PSTEPS.length-1;
  }
  root.querySelectorAll('[data-seg="ln"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="ln"] button').forEach(x=>x.classList.toggle('on',x===b));ln=b.dataset.v;draw()}));
  q('prev').addEventListener('click',()=>{if(i>0){i--;draw()}});
  q('next').addEventListener('click',()=>{if(i<PSTEPS.length-1){i++;draw()}});
  draw();
}

/* ---------- make: which rules run, and why ---------- */
const MKF={
  none:{name:'headers missing',text:'CC = gcc\nCFLAGS = -Wall -g\n\napp: main.o lib.o print.o\n\t$(CC) $^ -o $@\n\n%.o: %.c\n\t$(CC) $(CFLAGS) -c $< -o $@',
    deps:{app:['main.o','lib.o','print.o'],'main.o':['main.c'],'lib.o':['lib.c'],'print.o':['print.c']}},
  wrong:{name:'lib.h on app (wrong)',text:'CC = gcc\nCFLAGS = -Wall -g\n\napp: main.o lib.o print.o lib.h\n\t$(CC) $^ -o $@\n\n%.o: %.c\n\t$(CC) $(CFLAGS) -c $< -o $@',
    deps:{app:['main.o','lib.o','print.o','lib.h'],'main.o':['main.c'],'lib.o':['lib.c'],'print.o':['print.c']}},
  right:{name:'headers on the .o (right)',text:'CC = gcc\nCFLAGS = -Wall -g\n\napp: main.o lib.o print.o\n\t$(CC) $^ -o $@\n\n%.o: %.c\n\t$(CC) $(CFLAGS) -c $< -o $@\n\nmain.o: lib.h print.h\nlib.o: lib.h\nprint.o: print.h',
    deps:{app:['main.o','lib.o','print.o'],'main.o':['main.c','lib.h','print.h'],'lib.o':['lib.c','lib.h'],'print.o':['print.c','print.h']}},
};
const SRCS=['main.c','lib.c','print.c','lib.h','print.h'], OBJS=['main.o','lib.o','print.o','app'];
function wMake(root){
  let mk=root.dataset.mk||'none', clock, t, max, maxMain, maxApp, last=new Set(), out;
  const reset=()=>{clock=5;t={'main.c':1,'lib.c':2,'print.c':3,'lib.h':4,'print.h':5};max=10;maxMain=null;maxApp=null;last=new Set();out='$ ls\nlib.c  lib.h  main.c  Makefile  print.c  print.h'};
  reset();
  const seg=(name,opts,on)=>`<div class="seg" data-seg="${name}">${opts.map(([v,l])=>`<button type="button" data-v="${v}" class="${v===on?'on':''}">${l}</button>`).join('')}</div>`;
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>make, step by step</h3><p>Edit a file, then run <code>make</code>: it compares the modification times and runs only the rules that are needed. <code>lib.h</code> defines <code>MAX</code>; <code>app</code> prints 1 + 2 + ... + MAX.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls"><div class="ctrl"><label>Makefile</label>${seg('mk',Object.entries(MKF).map(([k,v])=>[k,v.name]),mk)}</div></div>
  <div class="ctrls mkbtns"><span class="chl">edit:</span>${SRCS.map(f=>`<button type="button" class="chip" data-e="${f}">${f}${f==='lib.h'?' (MAX)':''}</button>`).join('')}<span class="chl" style="margin-left:10px">run:</span><button type="button" class="chip run" data-c="make">make</button><button type="button" class="chip run" data-c="app">./app</button><button type="button" class="chip run" data-c="clean">make clean</button><button type="button" class="chip" data-c="reset">start again</button></div>
  <div class="wd-b"><div><div class="ppf"><b>Makefile</b></div><pre class="sh mkfile" data-r="mf"></pre><div class="ppf" style="margin-top:12px"><b>the files</b> · newer files have a larger time</div><div class="mkfiles" data-r="files"></div></div>
  <div><pre class="sh mkout" data-r="out"></pre></div></div>
  <div class="wd-f" data-r="x"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  let note='';
  function make(){
    const D=MKF[mk].deps, ran=[], why=[];
    const build=tg=>{
      for(const p of D[tg]||[])if(D[p])build(p);
      const pre=D[tg]||[];
      const missing=t[tg]==null, newer=pre.filter(p=>t[p]!=null&&t[tg]!=null&&t[p]>t[tg]);
      if(missing||newer.length){
        clock++;t[tg]=clock;
        if(tg==='app'){ran.push('gcc '+pre.join(' ')+' -o app');maxApp=maxMain}
        else{ran.push('gcc -Wall -g -c '+pre[0]+' -o '+tg);if(tg==='main.o')maxMain=max}
        why.push(missing?`<b>${tg}</b> was missing`:`<b>${tg}</b> is older than ${newer.map(x=>'<code>'+x+'</code>').join(', ')}`);
        last.add(tg);
      }
    };
    last=new Set();build('app');
    out='$ make\n'+(ran.length?ran.join('\n'):"make: 'app' is up to date.");
    note=ran.length?'Rebuilt: '+why.join('; ')+'.':'Nothing to do: every target is newer than its prerequisites.';
    if(mk==='wrong'&&ran.length===1&&last.has('app')&&last.size===1)note+=' ⚠️ Only <code>app</code> was linked again: <code>lib.h</code> on <code>app</code> does not recompile <code>main.o</code>.';
  }
  function draw(){
    q('mf').innerHTML=hl(MKF[mk].text,'make');
    const order=SRCS.concat(OBJS);
    q('files').innerHTML=order.map(f=>`<div class="mkf ${t[f]==null?'miss':''} ${last.has(f)?'new':''} ${SRCS.includes(f)?'src':'gen'}"><code>${f}</code><span>${t[f]==null?'missing':'time '+t[f]}</span>${f==='lib.h'?`<em>MAX ${max}</em>`:''}${f==='main.o'&&maxMain!=null?`<em>built with MAX ${maxMain}</em>`:''}</div>`).join('');
    q('out').innerHTML=shc(out);
    q('x').innerHTML=note||'Start with <b>make</b>: nothing is built yet.';
    const okapp=t.app!=null&&maxApp===max;
    q('b').textContent=t.app==null?'app not built':okapp?'app up to date':'app uses MAX '+maxApp+'!';
    q('b').className='badge'+(t.app==null?' off':okapp?' ok':' bad');
  }
  root.querySelectorAll('[data-seg="mk"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="mk"] button').forEach(x=>x.classList.toggle('on',x===b));mk=b.dataset.v;note='Makefile changed: run <b>make</b> again. (The files stay as they are.)';draw()}));
  root.querySelectorAll('[data-e]').forEach(b=>b.addEventListener('click',()=>{const f=b.dataset.e;clock++;t[f]=clock;last=new Set([f]);
    if(f==='lib.h'){max=max===10?100:10;out=`$ vim lib.h   # #define MAX ${max}`;note=`<code>lib.h</code> changed: <code>MAX</code> is now ${max}. Every <code>.c</code> that includes it should be compiled again.`}
    else{out=`$ vim ${f}   # edit`;note=`<code>${f}</code> is now newer than the files built from it.`}draw()}));
  root.querySelectorAll('[data-c]').forEach(b=>b.addEventListener('click',()=>{const c=b.dataset.c;
    if(c==='make')make();
    else if(c==='app'){if(t.app==null){out='$ ./app\nbash: ./app: No such file or directory';note='Build it first.'}else{const n=maxApp;out='$ ./app\nsum = '+(n*(n+1)/2);note=maxApp===max?'The right result for MAX '+max+'.':`⚠️ Wrong: <code>lib.h</code> says MAX ${max}, but <code>main.o</code> was compiled with MAX ${maxApp}. The correct sum is ${max*(max+1)/2}.`}last=new Set()}
    else if(c==='clean'){OBJS.forEach(f=>delete t[f]);maxMain=maxApp=null;last=new Set();out='$ make clean\nrm -f *.o app';note='Only the sources are left: the next <b>make</b> builds everything.'}
    else if(c==='reset'){reset();note=''}
    draw()}));
  draw();
}

/* ---------- compiled or interpreted: when is the mistake found? ---------- */
const LG=[
  {id:'c',name:'C',kind:'compiled',by:'gcc, then the CPU',file:'steps.c',pre:['#include <stdio.h>','int main(void) {'],post:['}'],
   st:i=>`    printf("Step ${i}\\n");`,cmd:['$ gcc steps.c -o steps','$ ./steps'],
   scan:'gcc first reads the whole file'},
  {id:'py',name:'Python',kind:'bytecode + VM',by:'python3',file:'steps.py',pre:[],post:[],
   st:i=>`print("Step ${i}")`,cmd:['$ python3 steps.py'],
   scan:'python3 first compiles the whole file to bytecode'},
  {id:'sh',name:'bash',kind:'interpreted',by:'bash',file:'steps.sh',pre:[],post:[],
   st:i=>`echo "Step ${i}"`,cmd:['$ bash steps.sh'],scan:null},
];
const LGS={
  ok:{label:'no mistake',edit:null,
    x:'All three print the same. <b>C</b> was translated once, before running: <code>steps</code> is machine code. <b>python3</b> compiled the whole file to bytecode first, then ran it. <b>bash</b> read and ran one line at a time.'},
  syntax:{label:'a typo: an extra )',edit:{c:'    printf("Step 3\\n"));',py:'print("Step 3"))',sh:'echo "Step 3")'},
    x:'<b>gcc</b> and <b>python3</b> read the whole file before running anything, so they stop before the first line runs. <b>bash</b> had already run lines 1 and 2 when it reached the typo.'},
  name:{label:'a misspelled name',edit:{c:'    prinf("Step 3\\n");',py:'prnt("Step 3")',sh:'ehco "Step 3"'},
    x:'<b>gcc</b> checks every name before it makes the program: nothing runs. <b>Python</b> looks a name up only when its line runs: two lines ran first. <b>bash</b> does not even stop: it prints the error and goes on with line 4.'},
  stale:{label:'edited, not rebuilt',edit:{c:'    printf("Done\\n");',py:'print("Done")',sh:'echo "Done"'},line:4,
    x:'Line 4 now says <i>Done</i>, but <code>./steps</code> is the machine code of the <b>old</b> file: it still prints <i>Step 4</i>. Python and bash read the source every time, so they see the change. Compile again (or <code>make</code>) after every change.'},
};
function lgScript(L,sc){                               // -> {lines, ev:[...]} for one language and one scenario
  const S=LGS[sc],ln=S.line||3;
  const body=[1,2,3,4].map(i=>S.edit&&i===ln?S.edit[L.id]:L.st(i));
  const lines=L.pre.concat(body,L.post),off=L.pre.length;      // statement i is on line off+i (1-based)
  const ev=[],out=k=>'Step '+k;
  const runAll=(from,fn)=>{for(let i=from;i<=4;i++){const r=fn(i);ev.push(Object.assign({t:'line',n:off+i},r));if(r.stop)return}};
  if(L.id==='c'){
    if(sc==='stale'){ev.push({t:'cmd',s:'$ ./steps',note:'no gcc: the old executable'});runAll(1,i=>({o:out(i)}));ev.push({t:'end',k:'warn',s:'ran the old code'});return{lines,ev}}
    ev.push({t:'cmd',s:L.cmd[0]},{t:'scan',s:L.scan});
    if(sc==='syntax'){ev.push({t:'err',n:off+3,s:"steps.c:"+(off+3)+":23: error: expected ';' before ')' token"},{t:'end',k:'early',s:'found before running · 0 lines ran'});return{lines,ev}}
    if(sc==='name'){ev.push({t:'err',n:off+3,s:"steps.c:"+(off+3)+":5: error: implicit declaration of function 'prinf'; did you mean 'printf'?"},{t:'end',k:'early',s:'found before running · 0 lines ran'});return{lines,ev}}
    ev.push({t:'cmd',s:L.cmd[1]});runAll(1,i=>({o:sc==='stale'&&i===4?'Done':out(i)}));ev.push({t:'end',k:'ok',s:'4 lines ran'});return{lines,ev};
  }
  ev.push({t:'cmd',s:L.cmd[0]});
  if(L.id==='py'){
    ev.push({t:'scan',s:L.scan});
    if(sc==='syntax'){ev.push({t:'err',n:3,s:'  File "steps.py", line 3\n    print("Step 3"))\n                   ^\nSyntaxError: unmatched \')\''},{t:'end',k:'early',s:'found before running · 0 lines ran'});return{lines,ev}}
    runAll(1,i=>sc==='name'&&i===3?{e:'Traceback (most recent call last):\n  File "steps.py", line 3, in <module>\n    prnt("Step 3")\nNameError: name \'prnt\' is not defined. Did you mean: \'print\'?',stop:true}:{o:sc==='stale'&&i===4?'Done':out(i)});
    ev.push(sc==='name'?{t:'end',k:'late',s:'found when line 3 ran · 2 lines ran'}:{t:'end',k:'ok',s:'4 lines ran'});return{lines,ev};
  }
  ev.push({t:'scan',s:null});
  runAll(1,i=>sc==='syntax'&&i===3?{e:"steps.sh: line 3: syntax error near unexpected token `)'\nsteps.sh: line 3: `echo \"Step 3\")'",stop:true}
    :sc==='name'&&i===3?{e:'steps.sh: line 3: ehco: command not found'}:{o:sc==='stale'&&i===4?'Done':out(i)});
  ev.push(sc==='syntax'?{t:'end',k:'late',s:'found at line 3 · 2 lines ran'}:sc==='name'?{t:'end',k:'late',s:'error at line 3, then went on with line 4'}:{t:'end',k:'ok',s:'4 lines ran'});
  return{lines,ev};
}
const lgHL=(t,id)=>tok(t,id==='c'?[[String.raw`"(?:\\.|[^"\\])*"`,'s'],[String.raw`^#\w+|<[\w.]+>`,'p'],[String.raw`\b(?:int|void|return)\b`,'k'],[String.raw`\b[A-Za-z_]\w*(?=\()`,'f']]
  :[[String.raw`"(?:\\.|[^"\\])*"`,'s'],[String.raw`^\w+`,'f']]);
function wLangs(root){
  let sc='ok',timer=null;
  root.innerHTML=`<div class="wd lgw"><div class="wd-h"><div><h3>When is the mistake found?</h3><p>The same four lines in C, Python and bash. Pick a mistake, then <b>Run</b>: watch who reads the whole file first, and how many lines run before the error.</p></div><span class="badge" data-r="b">ready</span></div>
  <div class="ctrls lgc"><div class="ctrl"><label>Line 3 has</label><div class="seg" data-seg="sc">${Object.entries(LGS).map(([k,v])=>`<button type="button" data-v="${k}" class="${k===sc?'on':''}">${v.label}</button>`).join('')}</div></div><button type="button" class="btn" data-r="run">▶ Run all three</button></div>
  <div class="lgcols" data-r="cols"></div>
  <div class="wd-f lgx" data-r="x"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const cols=()=>LG.map(L=>{const r=lgScript(L,sc);return{L,r}});
  function paint(){
    const S=LGS[sc];
    q('cols').innerHTML=cols().map(({L,r})=>`<div class="lgcol" data-l="${L.id}"><div class="lgh"><b>${L.name}</b><span class="lgk ${L.id}">${L.kind}</span></div>
      <div class="lgph"><span class="lgp" data-p="tr">${L.scan?'1 · translate all':'1 · no translation'}</span><span class="lgp" data-p="run">2 · run</span></div>
      <div class="lgsrc"><div class="srch">${L.file}</div><pre>${r.lines.map((l,i)=>`<span class="lgl${S.edit&&i===L.pre.length+(S.line||3)-1?' le':''}" data-n="${i+1}"><i>${i+1}</i>${lgHL(l,L.id)||' '}</span>`).join('')}</pre></div>
      <pre class="sh lgout" data-r="o-${L.id}"></pre><div class="lgres" data-r="r-${L.id}"></div></div>`).join('');
    q('x').innerHTML=S.x;q('b').textContent='ready';q('b').className='badge';
  }
  function run(){
    clearTimeout(timer);paint();
    const runs=cols().map(({L,r})=>({L,ev:r.ev,k:0,col:root.querySelector(`.lgcol[data-l="${L.id}"]`)}));
    const fast=matchMedia('(prefers-reduced-motion: reduce)').matches;
    q('b').textContent='running';q('b').className='badge warn';q('run').disabled=true;
    const step=()=>{
      let busy=false;
      for(const R of runs){
        if(R.k>=R.ev.length)continue;busy=true;
        const e=R.ev[R.k++],o=R.col.querySelector('.lgout'),add=(t,c)=>{o.insertAdjacentHTML('beforeend',`<span class="${c}">${esc(t)}</span>\n`)};
        R.col.querySelectorAll('.lgl.now').forEach(x=>x.classList.remove('now'));
        if(e.t==='cmd'){add(e.s,'c');if(e.note)add('# '+e.note,'k')}
        else if(e.t==='scan'){const p=R.col.querySelector('[data-p="tr"]');p.classList.add(e.s?'on':'skip');if(e.s){R.col.querySelectorAll('.lgl').forEach(x=>x.classList.add('scan'));add('# '+e.s,'k')}else add('# nothing to translate: bash starts at once','k')}
        else if(e.t==='line'){R.col.querySelectorAll('.lgl.scan').forEach(x=>x.classList.remove('scan'));R.col.querySelector('[data-p="tr"]').classList.replace('on','dn');R.col.querySelector('[data-p="run"]').classList.add('on');
          const l=R.col.querySelector(`.lgl[data-n="${e.n}"]`);l.classList.add(e.e?'lx':'now','ran');if(e.o)add(e.o,'o');if(e.e)add(e.e,'e')}
        else if(e.t==='err'){R.col.querySelectorAll('.lgl.scan').forEach(x=>x.classList.remove('scan'));R.col.querySelector(`.lgl[data-n="${e.n}"]`).classList.add('lx');R.col.querySelector('[data-p="tr"]').classList.replace('on','px');R.col.querySelector('[data-p="run"]').classList.add('skip');add(e.s,'e')}
        else if(e.t==='end'){const d=R.col.querySelector('.lgres');d.className='lgres '+e.k;d.textContent=e.s;R.col.querySelector('[data-p="run"]').classList.replace('on','dn')}
      }
      if(busy)timer=setTimeout(step,fast?0:650);else{q('b').textContent='done';q('b').className='badge ok';q('run').disabled=false}
    };
    step();
  }
  root.querySelectorAll('[data-seg="sc"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="sc"] button').forEach(x=>x.classList.toggle('on',x===b));sc=b.dataset.v;clearTimeout(timer);q('run').disabled=false;paint()}));
  q('run').addEventListener('click',run);
  paint();
}

/* ---------- make the interactive parts easy to find ---------- */
document.addEventListener('pageshown',e=>{
  const art=e.detail;if(!art)return;
  const ws=[...art.querySelectorAll('.wd')];
  if(ws.length&&!art.querySelector('.tryjump')){
    const names=ws.map(w=>{const h=w.querySelector('.wd-h h3');return h?h.textContent:''});
    const b=document.createElement('button');b.type='button';b.className='tryjump';
    b.innerHTML='<span class="tj-i" aria-hidden="true">▶</span><span>'+(ws.length>1?ws.length+' interactive parts on this page: ':'Interactive on this page: ')+'<b>'+esc(names[0])+'</b>'+(ws.length>1?' and more':'')+'</span><span aria-hidden="true">↓</span>';
    b.addEventListener('click',()=>{ws[0].scrollIntoView({behavior:'smooth',block:'start'});const t=ws[0].querySelector('input');if(t)setTimeout(()=>t.focus({preventScroll:true}),450)});
    const h=art.querySelector('h1');h.after(b);
  }
  // the pages of the chapter that have an interactive part
  document.querySelectorAll('#smenu a').forEach(a=>{const k=a.getAttribute('href').slice(1),p=document.querySelector(`article.pg[data-key="${k}"]`);
    if(p&&p.querySelector('.wd')&&!a.querySelector('.tri'))a.insertAdjacentHTML('beforeend','<i class="tri" title="interactive">▶</i>')});
});

const W=window.DK_W||(window.DK_W={});
W.pipe=wPipe; W.make=wMake; W.langs=wLangs;
})();
