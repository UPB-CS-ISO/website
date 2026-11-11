/* ISO lecture 07, more widgets: make step by step (data-w="makestep"), static vs shared libraries (data-w="libs"),
   a language server (data-w="lsp") and a debug adapter (data-w="dap") */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const hlC=t=>esc(t).replace(/(&quot;|")(.*?)(")/g,'<span class="hl-s">"$2"</span>').replace(/\b(int|void|return|for)\b/g,'<span class="hl-k">$1</span>').replace(/^(#include)/,'<span class="hl-p">$1</span>');
const seg=(name,opts,on)=>`<div class="seg" data-seg="${name}">${opts.map(([v,l])=>`<button type="button" data-v="${v}" class="${v===on?'on':''}">${l}</button>`).join('')}</div>`;
const bindSeg=(root,name,cb)=>root.querySelectorAll(`[data-seg="${name}"] button`).forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll(`[data-seg="${name}"] button`).forEach(x=>x.classList.toggle('on',x===b));cb(b.dataset.v)}));

/* ====================================================================== make, step by step */
const fmt=s=>{const h=10+Math.floor(s/3600),m=Math.floor(s%3600/60),x=s%60;return String(h).padStart(2,'0')+':'+String(m).padStart(2,'0')+':'+String(x).padStart(2,'0')};
const MKP={
  hello:{goal:'hello',file:'~/hello',R:{hello:{pre:['hello.o'],cmd:'gcc hello.o -o hello'},'hello.o':{pre:['hello.c'],cmd:'gcc -c hello.c'}},
    sc:{first:{l:'first make',T:{'hello.c':120},did:'Nothing is built yet: only <code>hello.c</code> and the <code>Makefile</code>.'},
        again:{l:'make again',T:{'hello.c':120,'hello.o':310,hello:311},did:'Right after a <code>make</code>: every file is built.'},
        touch:{l:'after touch hello.c',T:{'hello.c':750,'hello.o':310,hello:311},did:'<code>touch hello.c</code> gave <code>hello.c</code> a new time: it is newer than <code>hello.o</code>.'}}},
  project:{goal:'app',file:'~/project',R:{app:{pre:['main.o','lib.o','print.o'],cmd:'gcc main.o lib.o print.o -o app'},'main.o':{pre:['main.c'],cmd:'gcc -c main.c'},'lib.o':{pre:['lib.c'],cmd:'gcc -c lib.c'},'print.o':{pre:['print.c'],cmd:'gcc -c print.c'}},
    sc:{first:{l:'first make',T:{'main.c':60,'lib.c':61,'print.c':62},did:'Nothing is built yet: only the sources and the <code>Makefile</code>.'},
        again:{l:'make again',T:{'main.c':60,'lib.c':61,'print.c':62,'main.o':300,'lib.o':301,'print.o':302,app:303},did:'Right after a <code>make</code>: every file is built.'},
        touch:{l:'after touch print.c',T:{'main.c':60,'lib.c':61,'print.c':900,'main.o':300,'lib.o':301,'print.o':302,app:303},did:'<code>touch print.c</code>: <code>print.c</code> is now newer than <code>print.o</code>.'},
        rm:{l:'after rm main.o',T:{'main.c':60,'lib.c':61,'print.c':62,'lib.o':301,'print.o':302,app:303},did:'<code>rm main.o</code>: the object file is gone.'}}},
};
function makeSteps(P,sc){
  const R=P.R,T=Object.assign({},P.sc[sc].T),steps=[],stack=[],ran=[],state={},hot=new Set();
  let clock=1200;
  const snap=o=>steps.push(Object.assign({stack:stack.slice(),T:Object.assign({},T),ran:ran.slice(),state:Object.assign({},state),hot:new Set(hot)},o));
  snap({flow:[],t:null,x:P.sc[sc].did+' You type <code>make</code>: no target is named, so <code>make</code> builds the <b>first</b> target of the <code>Makefile</code>, <code>'+P.goal+'</code>.',check:null,run:null});
  const visit=t=>{
    const r=R[t];stack.unshift(t);state[t]='st';
    snap({flow:['start','pre'],t,x:'<code>make '+t+'</code>: before anything else, make every prerequisite of <code>'+t+'</code>: <code>'+r.pre.join('</code>, <code>')+'</code>. '+(r.pre.some(p=>R[p])?'They have rules of their own, so <code>make</code> goes down: the stack grows.':''),check:null,run:null});
    for(const p of r.pre){
      if(R[p]){visit(p);continue}
      stack.unshift(p);state[p]='leaf';
      snap({flow:['norule'],t:p,ft:t,x:'<code>'+t+'</code> needs <code>'+p+'</code>, which has no rule: the file must exist, and it does.',check:{k:'exists',a:p},run:null});
      stack.shift();
    }
    const newer=r.pre.filter(p=>T[t]!=null&&T[p]>T[t]);
    if(T[t]==null){ran.push(r.cmd);T[t]=++clock;state[t]='rb';
      snap({flow:['start','exist','en','run'],t,x:'<code>'+t+'</code> does not exist: <code>make</code> runs its recipe. Then <code>'+t+'</code> leaves the stack.',check:{k:'missing',a:t},run:{cmd:r.cmd,after:t+' is now '+fmt(T[t])}})}
    else if(newer.length){const old=T[t];ran.push(r.cmd);T[t]=++clock;state[t]='rb';newer.forEach(p=>hot.add(p+'>'+t));
      snap({flow:['start','exist','ey','newer','ny','run'],t,x:'<code>'+newer[0]+'</code> is newer than <code>'+t+'</code>: <code>'+t+'</code> was built from an older version. <code>make</code> runs its recipe.',check:{k:'newer',a:newer[0],ta:T[newer[0]],b:t,tb:old},run:{cmd:r.cmd,after:t+' is now '+fmt(T[t])}})}
    else{state[t]='ok';const p=r.pre.reduce((a,b)=>T[a]>T[b]?a:b);
      snap({flow:['start','exist','ey','newer','nn','up'],t,x:'Every prerequisite is older than <code>'+t+'</code>: it is <b>up to date</b>, nothing to run.',check:{k:'older',a:p,ta:T[p],b:t,tb:T[t]},run:null})}
    stack.shift();
  };
  visit(P.goal);
  snap({flow:[],t:null,x:ran.length?'The stack is empty: <code>'+P.goal+'</code> is up to date and <code>make</code> stops. It ran '+ran.length+' command'+(ran.length>1?'s':'')+'; run <code>make</code> again and it runs none.':'The stack is empty and nothing ran: <code>make: \''+P.goal+'\' is up to date.</code>',check:null,run:null,end:true});
  return steps;
}
function flowSVG(t,on){
  const T=t||'T',c=k=>on.includes(k)?' on':'';
  const tx=(x,y,s,cls)=>`<text x="${x}" y="${y}" class="${cls||''}">${s}</text>`;
  const arr=k=>`url(#m${on.includes(k)?'fo':'fa'})`;
  return `<svg class="mkflow" viewBox="0 0 362 366" role="img" aria-label="how make decides">
  <defs><marker id="mfa" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#9aa9ae"/></marker><marker id="mfo" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#e65100"/></marker></defs>
  <g class="n${c('start')}"><rect x="40" y="3" width="180" height="34" rx="10"/>${tx(130,26,'make '+esc(T),'b')}</g>
  <path class="e${c('start')}" d="M130,37V50" marker-end="${arr('start')}"/>
  <g class="n${c('pre')}"><rect x="8" y="52" width="244" height="50" rx="10"/>${tx(130,73,'first, make every')}${tx(130,93,'prerequisite of '+esc(T))}</g>
  <g class="n nr${c('norule')}"><rect x="264" y="45" width="94" height="64" rx="10"/>${tx(311,64,'no rule?','s')}${tx(311,82,'then the file','s')}${tx(311,100,'must exist','s')}</g>
  <path class="e d${c('norule')}" d="M252,77H262"/>
  <path class="e${c('exist')}" d="M130,102V114" marker-end="${arr('exist')}"/>
  <g class="n${c('exist')}"><polygon points="130,116 234,156 130,196 26,156"/>${tx(130,151,'does the file')}${tx(130,171,esc(T)+' exist?')}</g>
  <path class="e${c('ey')}" d="M130,196V214" marker-end="${arr('ey')}"/>${tx(142,209,'yes','l'+c('ey'))}
  <g class="n${c('newer')}"><polygon points="130,216 238,256 130,296 22,256"/>${tx(130,251,'is a prerequisite')}${tx(130,271,'newer than '+esc(T)+'?')}</g>
  <path class="e${c('nn')}" d="M130,296V312" marker-end="${arr('nn')}"/>${tx(142,307,'no','l'+c('nn'))}
  <g class="n up${c('up')}"><rect x="20" y="314" width="220" height="48" rx="10"/>${tx(130,334,esc(T)+' is up to date:')}${tx(130,354,'nothing to run')}</g>
  <path class="e${c('en')}" d="M234,156H307V176" marker-end="${arr('en')}"/>${tx(244,146,'no','l'+c('en'))}
  <path class="e${c('ny')}" d="M238,256H307V236" marker-end="${arr('ny')}"/>${tx(246,246,'yes','l'+c('ny'))}
  <g class="n run${c('run')}"><rect x="258" y="178" width="100" height="56" rx="10"/>${tx(308,201,'run the')}${tx(308,221,'recipe')}</g>
  </svg>`;
}
function treeSVG(P,S){
  const R=P.R,lv={},kids={},order=[];
  const walk=(t,d)=>{lv[t]=Math.max(lv[t]||0,d);kids[t]=(R[t]?R[t].pre:[]);if(!kids[t].length&&!order.includes(t))order.push(t);kids[t].forEach(k=>walk(k,d+1))};
  walk(P.goal,0);
  const SL=104,W=Math.max(1,order.length)*SL,x={};
  const px=t=>{if(x[t]!=null)return x[t];if(!kids[t].length)return x[t]=SL/2+order.indexOf(t)*SL;const xs=kids[t].map(px);return x[t]=(Math.min(...xs)+Math.max(...xs))/2};
  px(P.goal);
  const depth=Math.max(...Object.values(lv)),H=depth*66+50,y=t=>4+lv[t]*66;
  let e='',n='';
  for(const t of Object.keys(lv))for(const k of kids[t]){const h=S.hot.has(k+'>'+t);e+=`<path class="te${h?' hot':''}" d="M${x[k]},${y(k)-2}L${x[t]},${y(t)+44}" marker-end="url(#mt${h?'o':'g'})"/>`}
  for(const t of Object.keys(lv)){const st=S.state[t]||'',cur=S.t===t,tm=S.T[t];
    n+=`<g class="tn ${st}${cur?' cur':''}${tm==null?' miss':''}"><rect x="${x[t]-46}" y="${y(t)}" width="92" height="42" rx="7"/><text x="${x[t]}" y="${y(t)+18}" class="nm">${t}</text><text x="${x[t]}" y="${y(t)+34}" class="tm">${tm==null?'missing':fmt(tm)}</text></g>`}
  return `<svg class="mktree" viewBox="0 0 ${W} ${H}" style="max-width:${W*1.2}px" role="img" aria-label="the dependency tree"><defs><marker id="mtg" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#9aa9ae"/></marker><marker id="mto" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#e65100"/></marker></defs>${e}${n}</svg>`;
}
function wMakeStep(root){
  const P=MKP[root.dataset.p||'hello'];let sc='first',i=0,S=makeSteps(P,sc);
  root.innerHTML=`<div class="wd mks"><div class="wd-h"><div><h3>What <code>make</code> does, step by step</h3><p>Press <b>Next</b>. Left: the rule <code>make</code> follows for every target; middle: the files and their times; right: what it compares and runs.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls mkc"><div class="ctrl"><label>In ${P.file}</label>${seg('sc',Object.entries(P.sc).map(([k,v])=>[k,v.l]),sc)}</div><div class="mknav"><button type="button" class="btn ghost" data-r="prev">←</button><span class="pdots" data-r="dots"></span><button type="button" class="btn" data-r="next">Next →</button></div></div>
  <div class="mksx" data-r="x"></div>
  <div class="mksb"><div class="mksf" data-r="flow"></div>
    <div class="mkt"><div class="mkl">the files, with their times</div><div data-r="tree"></div></div>
    <div class="mksr">
      <div class="mkl">target stack <i>(top on the left)</i></div><div class="mkst" data-r="st"></div>
      <div class="mkl">what make checks</div><div class="mkck" data-r="ck"></div>
      <div class="mkl">what it runs</div><div class="mkrn" data-r="rn"></div>
      <pre class="sh mkterm" data-r="term"></pre>
    </div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const fbox=(f,t,cls)=>`<span class="mkfb ${cls||''}"><code>${f}</code><i>${t==null?'missing':fmt(t)}</i></span>`;
  function draw(){
    const s=S[i];
    q('x').innerHTML=`<b>${i+1}.</b> ${s.x}`;
    q('flow').innerHTML=flowSVG(s.ft||s.t,s.flow);
    q('tree').innerHTML=treeSVG(P,s);
    q('st').innerHTML=s.stack.length?s.stack.map((t,k)=>`<span class="mkpill${k===0?' top':''}">${t}</span>`).join(''):'<i class="mknone">(empty)</i>';
    const c=s.check;
    q('ck').innerHTML=!c?'<i class="mknone">nothing yet</i>':c.k==='exists'?fbox(c.a,s.T[c.a],'hot')+' <span class="mkv ok">exists, no rule</span>':c.k==='missing'?fbox(c.a,null,'hot')+' <span class="mkv">does not exist</span>'
      :c.k==='newer'?fbox(c.a,c.ta,'hot')+' <span class="mkv">is newer than →</span> '+fbox(c.b,c.tb):fbox(c.a,c.ta)+' <span class="mkv ok">is older than →</span> '+fbox(c.b,c.tb,'okb');
    q('rn').innerHTML=s.run?`<code class="mkcmd">${esc(s.run.cmd)}</code><i class="mknone">${esc(s.run.after)}</i>`:s.end?`<span class="mkdone">${s.ran.length?'done':'nothing: up to date'}</span>`:'<i class="mknone">nothing</i>';
    q('term').innerHTML='<span class="p">$</span> <span class="c">make</span>\n'+s.ran.map(r=>'<span class="o">'+esc(r)+'</span>').join('\n')+(s.end&&!s.ran.length?'<span class="o">make: \''+P.goal+'\' is up to date.</span>':'');
    q('dots').innerHTML=S.map((_,k)=>`<i class="${k===i?'on':k<i?'dn':''}"></i>`).join('');
    q('b').textContent='step '+(i+1)+' / '+S.length;
    q('prev').disabled=i===0;q('next').disabled=i===S.length-1;
  }
  bindSeg(root,'sc',v=>{sc=v;S=makeSteps(P,sc);i=0;draw()});
  q('prev').addEventListener('click',()=>{if(i>0){i--;draw()}});
  q('next').addEventListener('click',()=>{if(i<S.length-1){i++;draw()}});
  draw();
}

/* ====================================================================== static vs shared library */
function wLibs(root){
  let G;
  const reset=()=>{G={v:1,a:true,so:true,stat:1,note:'Two copies of the same program: <b>app-static</b> was linked with <code>libsum.a</code>, <b>app</b> with <code>libsum.so</code>. Version 1 of <code>sum</code> has a bug: it stops one number too early. Run them.',out:{s:'',d:''}}};
  reset();
  const res=v=>v===1?'sum = 45   (wrong: 1 + ... + 9)':'sum = 55';
  root.innerHTML=`<div class="wd libw"><div class="wd-h"><div><h3>Static or shared: what happens when the library changes?</h3><p>Click the actions in any order and run both programs after each one.</p></div><span class="badge" data-r="b">sum v1</span></div>
  <div class="ctrls mkbtns"><span class="chl">do:</span><button type="button" class="chip run" data-a="run">▶ run both</button><button type="button" class="chip" data-a="fix">fix the bug, rebuild the library</button><button type="button" class="chip" data-a="relink">link app-static again</button><button type="button" class="chip" data-a="del">delete the library files</button><button type="button" class="chip" data-a="reset">start again</button></div>
  <div class="libcols"><div class="libc" data-c="s"></div><div class="libc" data-c="d"></div></div>
  <div class="wd-f lgx" data-r="x"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const box=(n,sub,cls)=>`<div class="lbox ${cls||''}"><code>${n}</code><span>${sub}</span></div>`;
  function draw(){
    const s=root.querySelector('[data-c="s"]'),d=root.querySelector('[data-c="d"]');
    s.innerHTML=`<div class="lgh"><b>app-static</b><span class="lgk c">static · libsum.a</span></div>
      <div class="lpic">${box('app-static','main + <b>sum v'+G.stat+'</b> copied in','exe')}<span class="lnk">${G.a?'built from':'was built from'}</span>${box('libsum.a',G.a?'sum v'+G.v:'deleted',G.a?'lib':'gone')}</div>
      <p class="lcap">The code of <code>sum</code> is <b>inside</b> the executable, copied when it was linked. The <code>.a</code> is not needed to run it.</p>
      <pre class="sh lout">${G.out.s}</pre>`;
    d.innerHTML=`<div class="lgh"><b>app</b><span class="lgk py">shared · libsum.so</span></div>
      <div class="lpic">${box('app','main + "<b>needs libsum.so</b>"','exe')}<span class="lnk">loads, at every start</span>${box('libsum.so',G.so?'sum v'+G.v:'deleted',G.so?'lib so':'gone')}</div>
      <p class="lcap">The executable only <b>names</b> the library; the loader opens <code>libsum.so</code> each time <code>app</code> starts, and every program shares that one copy.</p>
      <pre class="sh lout">${G.out.d}</pre>`;
    q('x').innerHTML=G.note;q('b').textContent='library: '+(G.a||G.so?'sum v'+G.v:'deleted');
  }
  const run=()=>{
    G.out.s='<span class="p">$</span> <span class="c">./app-static</span>\n<span class="o">'+res(G.stat)+'</span>';
    G.out.d='<span class="p">$</span> <span class="c">./app</span>\n'+(G.so?'<span class="o">'+res(G.v)+'</span>':'<span class="e">./app: error while loading shared libraries: libsum.so: cannot open shared object file: No such file or directory</span>');
  };
  root.querySelectorAll('[data-a]').forEach(b=>b.addEventListener('click',()=>{const a=b.dataset.a;
    if(a==='run'){run();G.note=!G.so?'<b>app-static</b> still runs: its copy of <code>sum</code> is inside it. <b>app</b> cannot even start: the loader looks for <code>libsum.so</code> and does not find it.':G.stat!==G.v?'<b>app</b> already has the fix: it loads the new <code>libsum.so</code> at every start. <b>app-static</b> still prints 45: it carries its old copy of <code>sum</code> until you <b>link it again</b>.':G.v===2?'Both print 55: both have version 2 of <code>sum</code>.':'Both print 45: both use version 1 of <code>sum</code>, with the bug.'}
    else if(a==='fix'){G.v=2;G.a=G.so=true;G.out={s:'<span class="p">$</span> <span class="c">gcc -c lib.c &amp;&amp; ar rcs libsum.a lib.o</span>',d:'<span class="p">$</span> <span class="c">gcc -fPIC -c lib.c &amp;&amp; gcc -shared lib.o -o libsum.so</span>'};G.note='The bug is fixed in <code>lib.c</code> and both libraries are rebuilt. The programs were <b>not</b> touched. Run them: which one has the fix?'}
    else if(a==='relink'){if(!G.a){G.out.s='<span class="p">$</span> <span class="c">gcc main.o print.o libsum.a -o app-static</span>\n<span class="e">/usr/bin/ld: cannot find -lsum: No such file or directory</span>';G.note='No <code>libsum.a</code>, nothing to copy from: rebuild the library first.'}
      else{G.stat=G.v;G.out.s='<span class="p">$</span> <span class="c">gcc main.o print.o libsum.a -o app-static</span>';G.note='The linker copied the <b>current</b> <code>sum</code> (v'+G.v+') into <b>app-static</b>. A static library reaches a program only through a new link.'}}
    else if(a==='del'){G.a=G.so=false;G.out={s:'<span class="p">$</span> <span class="c">rm libsum.a</span>',d:'<span class="p">$</span> <span class="c">rm libsum.so</span>'};G.note='Both library files are gone, like on a computer where the library is not installed. Run both programs.'}
    else if(a==='reset')reset();
    draw()}));
  draw();
}

/* ====================================================================== the message log of LSP and DAP */
function mlog(items){
  return items.map(m=>m.k==='os'?`<div class="ml os${m.n?' new':''}"><span class="mla">${m.d==='r'?'⤵':'⤴'}</span><span>${m.t}</span></div>`
    :`<div class="ml ${m.d}${m.n?' new':''}"><span class="mla">${m.d==='r'?'→':'←'}</span><span class="mlk ${m.k}">${m.k}</span><b>${esc(m.t)}</b>${m.id!=null?`<span class="mlid">id ${m.id}</span>`:''}<code>${esc(JSON.stringify(m.b))}</code></div>`).join('');
}
function logPane(title,a,b,note){return `<div class="mlp"><div class="mlh"><span><b>${a}</b> ⇄ <b>${b}</b></span><span>${note}</span></div><div class="mlb" data-r="log"></div></div>`}

/* ====================================================================== a language server */
const MAINC=['#include "lib.h"','#include "print.h"','','int main(void)','{','    int total = sum(MAX);','    print_result("sum", total);','    return 0;','}'];
const URI='file:///home/student/project/main.c';
function wLsp(root){
  let L,id,log,ver;
  const reset=()=>{L=MAINC.slice();id=1;ver=1;log=[];
    log.push({d:'r',k:'notification',t:'textDocument/didOpen',b:{textDocument:{uri:URI,languageId:'c',version:1,text:'#include "lib.h"\n…'}},n:1},
      {d:'l',k:'notification',t:'textDocument/publishDiagnostics',b:{uri:URI,diagnostics:[]},n:1});
    G={squig:null,pop:null,note:'You opened <code>main.c</code>: <code>hx</code> started <code>clangd</code> (a child process, two pipes) and sent it the whole file. No errors: an empty list of <i>diagnostics</i>.'}};
  let G;reset();
  root.innerHTML=`<div class="wd lspw"><div class="wd-h"><div><h3>The editor and the language server</h3><p>Do something in the editor; on the right, the JSON messages that go through the pipes between <code>hx</code> and <code>clangd</code>.</p></div><span class="badge">LSP</span></div>
  <div class="ctrls mkbtns"><span class="chl">in the editor:</span><button type="button" class="chip" data-a="typo">type <code>totl</code> instead of <code>total</code></button><button type="button" class="chip" data-a="fix">fix it</button><button type="button" class="chip" data-a="hover">hover on <code>sum</code></button><button type="button" class="chip" data-a="comp">type <code>print_</code>, ask for completion</button><button type="button" class="chip" data-a="def">go to the definition of <code>sum</code></button><button type="button" class="chip" data-a="reset">start again</button></div>
  <div class="dapb"><div class="ed"><div class="edh">main.c — hx</div><pre class="edc" data-r="code"></pre><div class="edst" data-r="st"></div></div>${logPane('','hx (editor)','clangd (server)','pipes: stdin → · ← stdout')}</div>
  <div class="wd-f lgx" data-r="x"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const send=(...ms)=>{log.forEach(m=>m.n=0);ms.forEach(m=>{m.n=1;log.push(m)});log=log.slice(-12)};
  function draw(){
    q('code').innerHTML=L.map((l,k)=>{let h=hlC(l);
      if(G.squig&&G.squig.line===k)h=h.replace('totl','<u class="sq">totl</u>');
      if(G.def&&k===5)h=h.replace(/\bsum\b/,'<u class="lk">sum</u>');
      if(G.pop&&G.pop.line===k)h=h.replace(G.pop.at,`<span class="popw">${G.pop.at}<span class="pop">${G.pop.html}</span></span>`);
      return `<span class="lgl${G.squig&&G.squig.line===k?' lx':''}"><i>${k+1}</i>${h||' '}</span>`}).join('');
    q('st').innerHTML=G.squig?'<span class="sqm">● 1 error</span> 7:26 use of undeclared identifier \'totl\'; did you mean \'total\'?':G.def?'↪ opened <b>lib.c</b>, line 3: <code>int sum(int n)</code>':'<span class="okm">✓ no errors</span>';
    q('log').innerHTML=mlog(log);q('log').scrollTop=q('log').scrollHeight;
    q('x').innerHTML=G.note;
  }
  root.querySelectorAll('[data-a]').forEach(b=>b.addEventListener('click',()=>{const a=b.dataset.a;G.pop=null;G.def=false;
    if(a==='typo'){L[6]='    print_result("sum", totl);';ver++;send({d:'r',k:'notification',t:'textDocument/didChange',b:{textDocument:{uri:URI,version:ver},contentChanges:[{range:{start:{line:6,character:24},end:{line:6,character:29}},text:'totl'}]}},
        {d:'l',k:'notification',t:'textDocument/publishDiagnostics',b:{uri:URI,diagnostics:[{range:{start:{line:6,character:25}},severity:1,message:"use of undeclared identifier 'totl'; did you mean 'total'?"}]}});
      G.squig={line:6};G.note='Every key you type is sent as <code>didChange</code> (only the change). <code>clangd</code> compiles the file in its head and answers with <code>publishDiagnostics</code>: the editor underlines <code>totl</code>, <b>before</b> you run <code>gcc</code>. Note: LSP counts lines from 0, line 6 is the 7th.'}
    else if(a==='fix'){L[6]=MAINC[6];ver++;send({d:'r',k:'notification',t:'textDocument/didChange',b:{textDocument:{uri:URI,version:ver},contentChanges:[{range:{start:{line:6,character:24}},text:'total'}]}},{d:'l',k:'notification',t:'textDocument/publishDiagnostics',b:{uri:URI,diagnostics:[]}});
      G.squig=null;G.note='Fixed: the new list of diagnostics is empty, the red line goes away. Notifications get no answer: they have no <code>id</code>.'}
    else if(a==='hover'){const i=++id;send({d:'r',k:'request',t:'textDocument/hover',id:i,b:{textDocument:{uri:URI},position:{line:5,character:17}}},{d:'l',k:'response',t:'result',id:i,b:{contents:{kind:'markdown',value:'function sum\n→ int\nParameters: int n\nint sum(int n)\nDeclared in lib.h'}}});
      G.pop={line:5,at:'sum',html:'<b>function sum</b><br><code>int sum(int n)</code><br><i>declared in lib.h</i>'};G.note='A <b>request</b> has an <code>id</code>; the answer with the same <code>id</code> is the <b>response</b>. The editor knows nothing about C: the server read <code>lib.h</code> and found the declaration.'}
    else if(a==='comp'){const i=++id;send({d:'r',k:'request',t:'textDocument/completion',id:i,b:{textDocument:{uri:URI},position:{line:6,character:10}}},{d:'l',k:'response',t:'result',id:i,b:{items:[{label:'print_result',detail:'void (const char *label, int value)'}]}});
      G.pop={line:6,at:'print_result',html:'<b>print_result</b> <i>void (const char *, int)</i>'};G.note='Completion: the server knows every file of the project, so it offers <code>print_result</code> from <code>print.h</code>.'}
    else if(a==='def'){const i=++id;send({d:'r',k:'request',t:'textDocument/definition',id:i,b:{textDocument:{uri:URI},position:{line:5,character:17}}},{d:'l',k:'response',t:'result',id:i,b:{uri:'file:///home/student/project/lib.c',range:{start:{line:2,character:4}}}});
      G.def=true;G.note='<i>Go to definition</i>: the answer is a file and a position; the editor opens <code>lib.c</code> there (line 2 for LSP is line 3 for you).'}
    else if(a==='reset')reset();
    draw()}));
  draw();
}

/* ====================================================================== a debug adapter */
const LIBC=['#include "lib.h"','','int sum(int n)','{','    int s = 0;','    for (int i = 1; i <= n; i++) {','        s = s + i;','    }','    return s;','}'];
const CODEL=[5,6,7,9];                                  // the lines where a breakpoint can go
function dapTrace(){                                    // the lines that run, with the variables before each one
  const t=[{l:5,v:{n:10,s:'?'}}];let s=0;t.push({l:6,v:{n:10,s:0}});
  for(let i=1;i<=10;i++){t.push({l:7,v:{n:10,s,i}});s+=i;t.push({l:6,v:{n:10,s,i:i+1}})}
  t.push({l:9,v:{n:10,s}});return t;
}
function wDap(root){
  const TR=dapTrace();let G;
  const reset=()=>{G={bp:new Set(),pos:-1,run:false,done:false,seq:1,log:[],out:'',note:'Click in the gutter, left of a line number, to put a <b>breakpoint</b> (lines 5, 6, 7 or 9). Then <b>▶ Start</b>.'}};
  reset();
  root.innerHTML=`<div class="wd dapw"><div class="wd-h"><div><h3>The editor and the debug adapter</h3><p>Set a breakpoint, start, step: on the right, the DAP messages between the editor and <code>lldb-dap</code>, and what the adapter does to <code>app</code> with <code>ptrace</code>.</p></div><span class="badge" data-r="b">not running</span></div>
  <div class="ctrls mkbtns"><span class="chl">toolbar:</span><button type="button" class="chip run" data-a="start">▶ Start / Continue (F5)</button><button type="button" class="chip run" data-a="next">⤼ Step over (F10)</button><button type="button" class="chip" data-a="stop">■ Stop</button><button type="button" class="chip" data-a="reset">start again</button></div>
  <div class="dapb"><div class="ed"><div class="edh">lib.c — VSCodium</div><pre class="edc gut" data-r="code"></pre>
    <div class="dpan"><div><div class="dph">Variables</div><div data-r="vars"></div></div><div><div class="dph">Call stack</div><div data-r="stack"></div></div></div>
    <div class="edst" data-r="st"></div></div>
  ${logPane('','editor','lldb-dap (adapter)','requests →, ← responses and events')}</div>
  <div class="wd-f lgx" data-r="x"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const send=(...ms)=>{G.log.forEach(m=>m.n=0);ms.forEach(m=>{m.n=1;G.log.push(m)});G.log=G.log.slice(-14)};
  const req=(t,b)=>({d:'r',k:'request',t,id:G.seq++,b});
  const resp=(t,b)=>({d:'l',k:'response',t,b});
  const ev=(t,b)=>({d:'l',k:'event',t,b});
  const os=(t,d)=>({k:'os',t,d:d||'r'});
  const stopAt=(reason)=>{const p=TR[G.pos];
    send(ev('stopped',{reason,threadId:1}),os('the kernel stopped <code>app</code> and told <code>lldb-dap</code> (<code>waitpid</code>)','l'),req('stackTrace',{threadId:1}),resp('stackTrace',{stackFrames:[{name:'sum',line:p.l,source:{name:'lib.c'}},{name:'main',line:6,source:{name:'main.c'}}]}),
      req('scopes',{frameId:0}),req('variables',{variablesReference:1}),os('<code>ptrace(PTRACE_PEEKDATA)</code>: read the variables in the memory of <code>app</code>'),resp('variables',{variables:Object.entries(p.v).map(([k,v])=>({name:k,value:String(v)}))}))};
  const finish=()=>{G.run=false;G.done=true;G.pos=-1;G.out='sum = 55';send(os('<code>app</code> runs to its end'),ev('output',{category:'stdout',output:'sum = 55\n'}),ev('exited',{exitCode:0}),ev('terminated',{}))};
  function cont(from){for(let k=from;k<TR.length;k++)if(G.bp.has(TR[k].l)){G.pos=k;return true}return false}
  function draw(){
    const p=G.pos>=0?TR[G.pos]:null;
    q('code').innerHTML=LIBC.map((l,k)=>{const n=k+1;return `<span class="lgl${p&&p.l===n?' now':''}" data-n="${n}"><b class="bp${G.bp.has(n)?' on':''}${CODEL.includes(n)?' ok':''}" title="breakpoint"></b><i>${n}</i>${hlC(l)||' '}</span>`}).join('');
    q('code').querySelectorAll('.bp.ok').forEach(b=>b.addEventListener('click',()=>{const n=+b.parentNode.dataset.n;G.bp.has(n)?G.bp.delete(n):G.bp.add(n);const ls=[...G.bp].sort((a,b)=>a-b);
      send(req('setBreakpoints',{source:{path:'/home/student/project/lib.c'},breakpoints:ls.map(l=>({line:l}))}),resp('setBreakpoints',{breakpoints:ls.map(l=>({verified:true,line:l}))}));
      G.note='The editor sends <b>all</b> the breakpoints of the file in one <code>setBreakpoints</code>; the adapter answers <i>verified</i> and the dot turns red.'+(G.run?' (<code>app</code> is running: the adapter writes a trap instruction into its memory with <code>ptrace</code>.)':'');draw()}));
    q('vars').innerHTML=p?Object.entries(p.v).map(([k,v])=>`<div class="dv"><code>${k}</code> = <b>${v}</b></div>`).join(''):'<i class="mknone">—</i>';
    q('stack').innerHTML=p?'<div class="dv on">sum <i>lib.c:'+p.l+'</i></div><div class="dv">main <i>main.c:6</i></div>':'<i class="mknone">—</i>';
    q('st').innerHTML=G.run?'⏸ paused in <code>sum</code>, line '+p.l:G.done?'<span class="okm">app exited (code 0)</span> · output: <code>'+G.out+'</code>':'not running';
    q('log').innerHTML=mlog(G.log);q('log').scrollTop=q('log').scrollHeight;
    q('x').innerHTML=G.note;q('b').textContent=G.run?'paused':G.done?'exited':'not running';q('b').className='badge'+(G.run?' warn':G.done?' ok':'');
  }
  root.querySelectorAll('[data-a]').forEach(b=>b.addEventListener('click',()=>{const a=b.dataset.a;
    if(a==='reset'){reset();draw();return}
    if(a==='start'){
      if(!G.run){G.done=false;G.log.forEach(m=>m.n=0);
        send(req('launch',{program:'/home/student/project/app',stopOnEntry:false}),os('<code>fork</code> + <code>exec</code>: <code>app</code> starts as a child of <code>lldb-dap</code>, under <code>ptrace</code>'),resp('launch',{}),ev('initialized',{}),req('configurationDone',{}),os('<code>ptrace(PTRACE_CONT)</code>: let <code>app</code> run'));
        if(cont(0)){G.run=true;stopAt('breakpoint');G.note='<b>Start</b> is a <code>launch</code> request: the adapter starts <code>app</code> under <code>ptrace</code>. <code>app</code> hits the breakpoint: the <code>stopped</code> event comes, then the editor asks for the <b>stack</b> and the <b>variables</b> to fill its panels.'}
        else{finish();G.note='No breakpoint: <code>app</code> ran to its end. The adapter forwards its output and the <code>exited</code> event. Put a breakpoint first.'}}
      else{send(req('continue',{threadId:1}),resp('continue',{}),os('<code>ptrace(PTRACE_CONT)</code>'));
        if(cont(G.pos+1)){stopAt('breakpoint');G.note='<b>Continue</b>: <code>app</code> runs until it hits a breakpoint again; the loop came back to line '+TR[G.pos].l+'. Look at <code>i</code> and <code>s</code>.'}
        else{finish();G.note='No more breakpoints on the way: <code>app</code> ran to its end.'}}}
    else if(a==='next'){if(!G.run){G.note='<b>Step over</b> works only while <code>app</code> is paused: <b>▶ Start</b> first, with a breakpoint.'}
      else{send(req('next',{threadId:1}),resp('next',{}),os('<code>ptrace</code>: run until the next line'));
        if(G.pos+1<TR.length){G.pos++;stopAt('step');G.note='<b>Step over</b> is the <code>next</code> request: one line runs, then a <code>stopped</code> event with <i>reason: step</i>, and the panels are asked again.'}
        else{finish();G.note='<code>sum</code> returned and <code>app</code> ran to its end.'}}}
    else if(a==='stop'){if(G.run||G.log.length){send(req('disconnect',{terminateDebuggee:true}),os('<code>kill(app, SIGKILL)</code>'),resp('disconnect',{}),ev('terminated',{}));G.run=false;G.pos=-1;G.note='<b>Stop</b>: the adapter kills <code>app</code>. The breakpoints stay in the editor.'}}
    draw()}));
  draw();
}

const W=window.DK_W||(window.DK_W={});
W.makestep=wMakeStep; W.libs=wLibs; W.lsp=wLsp; W.dap=wDap;
})();
