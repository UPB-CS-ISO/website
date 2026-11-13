/* ISO lecture 02 widgets: walk a path (data-w="walk"), the directories of / (data-w="fhs"),
   Windows or Linux paths (data-w="ospath"), the manual page viewer (data-w="pager") */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const C=s=>'<code>'+esc(s)+'</code>';

/* ---------- walk a path, one part at a time ---------- */
function parseTree(text){
  const nodes=[], by=new Map(), stack=[];
  text.split('\n').forEach((l,i)=>{
    if(i===0){const n={name:'/',path:[],line:0,dir:true,txt:l};nodes.push(n);by.set('',n);return}
    const m=l.match(/^([│├└─ ]*)(.*)$/), depth=m[1].length/4, name=m[2].replace(/\/$/,'');
    stack.length=depth-1;const path=stack.concat(name);stack.push(name);
    const n={name,path,line:i,dir:!/\./.test(name),txt:l};nodes.push(n);by.set(path.join('/'),n);
  });
  return{nodes,get:p=>by.get(p.join('/'))};
}
const dname=at=>at.length?at[at.length-1]:'/';
const apath=at=>'/'+at.join('/');
function walkSteps(T,raw,pwd){
  let p=raw.trim();const home=p==='~'||p.startsWith('~/');
  if(home)p='/home/alice'+p.slice(1);
  const abs=p.startsWith('/'), toks=p.split('/').filter(x=>x!=='');
  let cur=abs?[]:pwd.slice();
  const steps=[{k:'start',at:cur.slice(),abs,home}];
  for(let i=0;i<toks.length;i++){
    const t=toks[i], from=cur.slice(), here=T.get(cur);
    if(!here.dir){steps.push({k:'notdir',i,t,at:from,from,err:true});return{toks,steps,abs,home,err:true}}
    if(t==='.'){steps.push({k:'dot',i,t,at:from,from});continue}
    if(t==='..'){if(!cur.length)steps.push({k:'rootup',i,t,at:[],from});else{cur=cur.slice(0,-1);steps.push({k:'up',i,t,at:cur.slice(),from})}continue}
    const n=T.get(cur.concat(t));
    if(!n){steps.push({k:t.includes('\\')?'bslash':'missing',i,t,at:from,from,err:true});return{toks,steps,abs,home,err:true}}
    cur=cur.concat(t);steps.push({k:n.dir?'down':'open',i,t,at:cur.slice(),from});
  }
  steps.push({k:'done',at:cur.slice()});
  return{toks,steps,abs,home,err:false};
}
/* the method of the slides: glue to pwd, drop every ., each .. removes the directory before it */
function lexical(base,toks){
  const all=base.map(x=>({t:x,rel:false,at:null,pair:null})).concat(toks.map(x=>({t:x,rel:true,at:null,pair:null})));
  const kept=[];let pair=0;
  all.forEach((x,i)=>{
    if(!x.rel){kept.push(i);return}
    const step=i-base.length+1;
    if(x.t==='.'||(x.t==='..'&&!kept.length)){x.at=step;x.pair=0}
    else if(x.t==='..'){pair++;const j=kept.pop();x.at=all[j].at=step;x.pair=all[j].pair=pair}
    else kept.push(i);
  });
  return{all,res:'/'+kept.map(i=>all[i].t).join('/')};
}
function wWalk(root){
  const T=parseTree(root.dataset.tree), PWD=root.dataset.pwd.split('/').filter(Boolean);
  const SC=JSON.parse(root.dataset.paths);
  let cur=0, W=null, s=0, tip='';
  root.innerHTML=`<div class="wd wk"><div class="wd-h"><div><h3>Walk a path, one part at a time</h3><p>From 📍 <code>${esc(apath(PWD))}</code>: pick a path or type one, then press <b>Next</b>. Every part is one move in the tree.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls wk-c"><span class="chl">path</span>${SC.map((x,i)=>`<button type="button" class="chip" data-i="${i}">${esc(x.p)}</button>`).join('')}</div>
  <div class="ctrls wk-c2"><label class="wk-own"><span class="chl">or type one</span><input data-r="in" placeholder="../../bob/notes.txt" autocomplete="off" autocapitalize="off" spellcheck="false" aria-label="your own path"><button type="button" class="btn ghost" data-r="go">Walk it</button></label>
  <div class="wk-nav"><button type="button" class="btn ghost" data-r="prev">← Back</button><span class="pdots" data-r="dots"></span><button type="button" class="btn" data-r="next">Next →</button></div></div>
  <div class="wk-x" data-r="x"></div>
  <div class="wk-b"><div class="wk-l"><div class="wk-lb">the path, part by part</div><div class="wk-toks" data-r="toks"></div><div class="wk-lb" style="margin-top:10px">the same, on paper</div><div class="calcp" data-r="calc"></div></div>
  <div class="wk-r"><pre class="tree wk-tree" data-r="tree"></pre></div></div></div>`;
  const q=k=>root.querySelector(`[data-r="${k}"]`);
  function load(path,t){W=walkSteps(T,path,PWD);W.path=path;W.lex=lexical(W.abs?[]:PWD,W.toks);s=0;tip=t||'';
    root.querySelectorAll('.wk-c .chip').forEach(b=>b.classList.toggle('on',SC[+b.dataset.i].p===path));draw()}
  function text(S){
    const n=x=>C(dname(x));
    switch(S.k){
      case'start':return S.home?`<b>Start</b> <code>bash</code> replaces <code>~</code> with <code>/home/alice</code> before the command runs: the path is absolute, start at the root.`
        :S.abs?`<b>Start</b> The path starts with <code>/</code>: start at the root. The current directory does not matter.`
        :`<b>Start</b> The path does not start with <code>/</code>: start in the current directory 📍 ${C(apath(PWD))}.`;
      case'dot':return `<b>Step ${S.i+1} · <code>.</code></b> the directory itself: stay in ${n(S.at)}.`;
      case'up':return `<b>Step ${S.i+1} · <code>..</code></b> the parent: go up from ${n(S.from)} to ${n(S.at)}.`;
      case'rootup':return `<b>Step ${S.i+1} · <code>..</code></b> at the root: <code>/</code> has no parent, stay in <code>/</code>.`;
      case'down':return `<b>Step ${S.i+1} · ${C(S.t)}</b> a directory in ${n(S.from)}: go down into it.`;
      case'open':return `<b>Step ${S.i+1} · ${C(S.t)}</b> a file in ${n(S.from)}: this is the file the path names.`;
      case'missing':return `<b>Step ${S.i+1} · ${C(S.t)}</b> there is no ${C(S.t)} in ${n(S.from)}: the command fails with <i>No such file or directory</i>.`;
      case'bslash':return `<b>Step ${S.i+1} · ${C(S.t)}</b> on Linux <code>\\</code> is not a separator, so this is one long name. ${n(S.from)} has no entry with that name: <i>No such file or directory</i>.`;
      case'notdir':return `<b>Step ${S.i+1} · ${C(S.t)}</b> ${n(S.from)} is a file, it has no entries: the command fails with <i>Not a directory</i>.`;
      case'done':{const node=T.get(S.at);return `<b>Result</b> ${C(apath(S.at))}, ${node.dir?'a directory':'a file'}.`+(tip?' 💡 '+tip:'')}
    }
  }
  function draw(){
    const S=W.steps[s], last=W.steps.length-1;
    q('b').textContent=W.err&&s===last?'error':s===last?'done':`step ${s} / ${last}`;
    q('b').className='badge'+(W.err&&s===last?' bad':s===last?' ok':'');
    q('x').innerHTML=text(S);q('x').classList.toggle('err',!!S.err);
    // the parts of the path
    const ti=S.i==null?(S.k==='done'?W.toks.length:-1):S.i;
    q('toks').innerHTML=(W.home?`<span class="wk-t ${s>0||ti>=0?'dn':'on'}">~</span><span class="wk-s">→ /home/alice</span>`:'')+(W.abs&&!W.home?`<span class="wk-t root ${s===0?'on':'dn'}">/</span>`:'')
      +W.toks.map((t,i)=>(i||W.abs&&!W.home?'<span class="wk-s">/</span>':'')+`<span class="wk-t ${i===ti?(S.err?'x':'on'):i<ti?'dn':''}">${esc(t)}</span>`).join('');
    // on paper: glue, strike, result
    const L=W.lex, upto=s===last?1e9:(S.i==null?0:S.i+1);
    const glue=L.all.map(x=>`<span class="${x.rel?'r':'w'}">/${esc(x.t)}</span>`).join('');
    const red=L.all.map(x=>{const seg='/'+esc(x.t);if(x.at==null||x.at>upto)return `<span class="${x.rel?'r':'w'}">${seg}</span>`;
      return x.pair?`<s class="x${(x.pair-1)%3+1}">${seg}</s><sup class="x${(x.pair-1)%3+1}">${x.pair}</sup>`:`<s>${seg}</s>`}).join('');
    q('calc').innerHTML=`<div><div class="lb">${W.abs?'🔗 absolute: the <span class="w">pwd</span> is not used':'🔗 <span class="w">pwd</span> + / + <span class="r">relative</span>'}</div>${glue||'/'}</div>`
      +`<div><div class="lb">✂️ drop every <code>.</code>, each <code>..</code> removes the directory before it</div>${red||'/'}</div>`
      +`<div><div class="lb">🌍 absolute path</div>${s<last?'<span class="wk-q">…</span>':W.err?`<b class="wk-e">❌ ${W.steps[last].k==='notdir'?'Not a directory':'No such file or directory'}</b>`:'<b>'+esc(L.res)+'</b>'}</div>`;
    // the tree
    const lines=T.nodes.map(nd=>({nd,cls:'',notes:[]}));
    W.steps.slice(0,s+1).forEach((st,k)=>{const l=lines[T.get(st.at).line];l.cls='h';if(k&&st.i!=null)l.notes.push(`(${st.i+1}) ${st.t}`)});
    const curL=lines[T.get(S.at).line];curL.cls=S.err?'wk-xl':'wk-on';
    const pwdL=W.abs?-1:T.get(PWD).line, w=Math.max(...T.nodes.map(n=>n.txt.length));
    q('tree').innerHTML=lines.map((l,i)=>{const m=l.nd.txt.match(/^([│├└─ ]*)(.*)$/), mk=(i===pwdL?1:0)+(s===last&&!W.err&&l===curL?1:0);
      let h=esc(m[1])+'<b>'+esc(m[2])+'</b>'+(i===pwdL?' <i class="cwd">📍</i>':'')+(s===last&&!W.err&&l===curL?' <i class="cwd">🎯</i>':'');
      if(l.notes.length)h+=`<span class="an">${' '.repeat(Math.max(1,w-l.nd.txt.length+1-3*mk))}← ${esc(l.notes.join(' '))}</span>`;   // an emoji and its space: 3 columns
      return `<span class="${l.cls}">${h}</span>`}).join('\n');
    q('dots').innerHTML=W.steps.map((x,k)=>`<i class="${k===s?'on':k<s?'dn':''}"></i>`).join('');
    q('prev').disabled=s===0;q('next').disabled=s===last;
  }
  root.querySelectorAll('.wk-c .chip').forEach(b=>b.addEventListener('click',()=>{const x=SC[+b.dataset.i];q('in').value='';load(x.p,x.tip)}));
  const own=()=>{const v=q('in').value.trim();if(v)load(v,'')};
  q('go').addEventListener('click',own);
  q('in').addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();own()}});
  q('prev').addEventListener('click',()=>{if(s>0){s--;draw()}});
  q('next').addEventListener('click',()=>{if(s<W.steps.length-1){s++;draw()}});
  load(SC[0].p,SC[0].tip);
}

/* ---------- the directories below / ---------- */
function wFhs(root){
  const D=JSON.parse(root.dataset.dirs), G=JSON.parse(root.dataset.groups), lines=root.dataset.tree.split('\n');
  let top='', sel=D.findIndex(d=>d.k==='/home'), grp='', seen=new Set([sel]);
  const key=lines.map((l,i)=>{if(i===0)return D.findIndex(d=>d.k==='/');const m=l.match(/^([│├└─ ]*)(.*)$/);if(m[1].length===4)top=m[2];return D.findIndex(d=>d.k.split(', ').includes('/'+top))});
  root.innerHTML=`<div class="wd fh"><div class="wd-h"><div><h3>What every directory is for</h3><p>Click a directory in the tree. Pick a group to see which directories belong together.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls fh-c"><div class="seg" data-r="g"><button type="button" data-v="" class="on">all</button>${G.map(g=>`<button type="button" data-v="${g.id}">${esc(g.name)}</button>`).join('')}</div></div>
  <div class="fh-gx" data-r="gx"></div>
  <div class="fh-b"><div class="fh-t" data-r="tree"></div><div class="fh-card" data-r="card"></div></div></div>`;
  const q=k=>root.querySelector(`[data-r="${k}"]`);
  function draw(){
    q('tree').innerHTML=lines.map((l,i)=>{const m=l.match(/^([│├└─ ]*)(.*)$/), d=D[key[i]];
      return `<button type="button" class="fh-l${key[i]===sel?' on':''}${grp&&d.g===grp?' gr':''}${seen.has(key[i])?' sn':''}" data-i="${i}"><span>${esc(m[1])}</span><b>${esc(m[2])}</b></button>`}).join('');
    q('tree').querySelectorAll('.fh-l').forEach(b=>b.addEventListener('click',()=>{sel=key[+b.dataset.i];seen.add(sel);draw()}));
    const d=D[sel], g=G.find(x=>x.id===d.g);
    q('card').innerHTML=`<div class="fh-k">${d.k.split(', ').map(C).join(' ')}${g?`<span class="fh-tag g-${g.id}">${esc(g.name)}</span>`:''}</div><p>${d.what}</p><div class="fh-win"><b>On Windows</b> ${d.win}</div>`;
    const G1=G.find(x=>x.id===grp);
    q('gx').innerHTML=G1?`<b>${esc(G1.name)}</b>: ${D.filter(x=>x.g===grp).map(x=>x.k.split(', ').map(C).join(', ')).join(', ')} · on Windows: ${G1.win}`:'Each directory directly below <code>/</code> has one job. You do not need to memorize them, only to recognize them.';
    q('gx').className='fh-gx'+(G1?' g-'+G1.id:'');
    q('b').textContent=`${seen.size} / ${D.length} explored`;q('b').className='badge'+(seen.size===D.length?' ok':'');
  }
  q('g').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{q('g').querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));grp=b.dataset.v;draw()}));
  draw();
}

/* ---------- Windows or Linux? ---------- */
function wOspath(root){
  const R=JSON.parse(root.dataset.rows), A={win:'Windows',linux:'Linux',none:'not valid'};
  let ans={};
  root.innerHTML=`<div class="wd op"><div class="wd-h"><div><h3>Windows or Linux?</h3><p>For every path, decide which system it belongs to, or whether it works on neither.</p></div><span class="badge" data-r="b"></span></div>
  <div class="op-rows" data-r="rows"></div><div class="wd-f op-f"><span data-r="sum"></span><button type="button" class="chip" data-r="again">start again</button></div></div>`;
  const q=k=>root.querySelector(`[data-r="${k}"]`);
  function draw(){
    q('rows').innerHTML=R.map((r,i)=>{const a=ans[i];
      return `<div class="op-r${a?a===r.a?' ok':' no':''}"><code class="op-p">${esc(r.p)}</code>`+(a?`<p class="op-w">${a===r.a?'':`<span class="op-tag no">✗ ${A[a]}</span> `}<span class="op-tag ok">✓ ${A[r.a]}</span> ${r.why}</p>`
        :`<div class="op-bs">${Object.entries(A).map(([k,v])=>`<button type="button" data-i="${i}" data-v="${k}">${v}</button>`).join('')}</div>`)+'</div>'}).join('');
    q('rows').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{ans[+b.dataset.i]=b.dataset.v;draw()}));
    const n=Object.keys(ans).length, ok=Object.entries(ans).filter(([i,a])=>R[i].a===a).length;
    q('b').textContent=n?`${ok} / ${n} right`:`${R.length} paths`;q('b').className='badge'+(n===R.length?ok===n?' ok':' warn':'');
    q('sum').innerHTML=n===R.length?(ok===n?'All right. ':`${ok} of ${R.length} right. `)+'The rule: a drive letter or <code>\\</code> means Windows, <code>/</code> at the start or <code>~</code> means a Linux shell.':'Answer all of them, the explanation appears after each choice.';
  }
  q('again').addEventListener('click',()=>{ans={};draw()});
  draw();
}

/* ---------- the manual page viewer (less) ---------- */
const PMS=[
  {t:'Move one page down.',h:'Space',ok:e=>e.a==='pgdn'},
  {t:'Jump to the end of the page, then back to the beginning.',h:'G, then g',ok:(e,st)=>e.a==='top'&&st.wasEnd},
  {t:'Find the option that lists in <b>reverse</b> order. Search for what you want to do, not for an option.',h:'/reverse Enter',ok:e=>e.a==='find'&&/reverse/i.test(e.word)&&e.hit},
  {t:'Search for <code>size</code>, then press <kbd>n</kbd> until you reach the option that <b>sorts</b> by size.',h:'/size Enter, then n',ok:(e,st)=>e.a==='next'&&/^\s+-S\b/.test(st.lines[st.hitLine]||'')},
  {t:'Quit the viewer.',h:'q',ok:e=>e.a==='quit'},
];
const PHELP=`                   SUMMARY OF LESS COMMANDS (short)

  h                 this help
  q                 quit

  ↓  j  Enter       one line down
  ↑  k              one line up
  Space  f  PgDn    one page down
  b  PgUp           one page up
  g  Home  <        the beginning
  G  End  >         the end

  /word  Enter      search forward
  ?word  Enter      search backward
  n                 the next match
  N                 the previous match

                    press q to go back to the page`;
function wPager(root){
  const lines=root.dataset.text.split('\n'), name=root.dataset.name||'ls', ROWS=+(root.dataset.rows||16);
  const st={lines,top:0,word:'',dir:1,hitLine:-1,wasEnd:false,mode:'page',msg:''};
  const done=new Set();
  root.innerHTML=`<div class="wd mp"><div class="wd-h"><div><h3>Inside the manual viewer</h3><p>Click the page, then use the keys of <code>less</code>, the viewer <code>man</code> opens its pages in.</p></div><span class="badge" data-r="b"></span></div>
  <div class="mp-b"><div class="mp-l"><div class="mp-scr" tabindex="0" data-r="scr" aria-label="manual page viewer, click and use the keys"><pre data-r="view"></pre><div class="mp-st" data-r="st"><span data-r="stt"></span><input class="mp-in" data-r="in" hidden autocomplete="off" autocapitalize="off" spellcheck="false" aria-label="search for"></div></div>
  <div class="mp-keys">${[['Space','pgdn'],['b','pgup'],['↓','down'],['↑','up'],['g','top'],['G','end'],['/','search'],['n','next'],['N','prev'],['h','help'],['q','quit']].map(([k,a])=>`<button type="button" class="chip" data-a="${a}">${k}</button>`).join('')}</div></div>
  <div class="mp-r"><div class="missions mp-m"><div class="mh"><b>Missions</b> <span data-r="mc"></span><em class="mnote">press the keys yourself, the buttons are only examples</em></div><ol data-r="ml">${PMS.map((m,i)=>`<li data-i="${i}"><span class="mt">${m.t}</span> <details><summary>hint</summary>${esc(m.h)}</details></li>`).join('')}</ol></div>
  <table class="mp-kt"><tr><td><kbd>Space</kbd> <kbd>b</kbd></td><td>page down / up</td></tr><tr><td><kbd>g</kbd> <kbd>G</kbd></td><td>beginning / end</td></tr><tr><td><kbd>/</kbd> <kbd>?</kbd></td><td>search forward / backward</td></tr><tr><td><kbd>n</kbd> <kbd>N</kbd></td><td>next / previous match</td></tr><tr><td><kbd>q</kbd></td><td>quit</td></tr></table></div></div></div>`;
  const q=k=>root.querySelector(`[data-r="${k}"]`), scr=q('scr'), inp=q('in');
  const maxTop=()=>Math.max(0,lines.length-ROWS);
  const markup=l=>{let h=esc(l);
    if(/^[A-Z][A-Z ]+$/.test(l)||/^   [A-Z][a-z ]+:$/.test(l))h='<b>'+h+'</b>';
    else h=h.replace(/^(\s+)(-[\w-]+(?:, --[\w-]+)?|--[\w-]+)/,(m,a,b)=>a+'<b>'+b+'</b>');
    if(st.word){const re=new RegExp(st.word.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'gi');h=h.replace(/(<[^>]+>)|([^<]+)/g,(m,tag,txt)=>tag||txt.replace(re,x=>'<mark>'+x+'</mark>'))}
    return h};
  function draw(){
    if(st.mode==='quit'){q('view').innerHTML='<span class="mp-sh">$ man '+esc(name)+'\n$ </span><span class="mp-cur"> </span>\n\n<span class="mp-dim">The viewer is closed: you are back in the shell.\nPress Enter (or click here) to open the page again.</span>';q('stt').textContent='';q('st').className='mp-st off';}
    else if(st.mode==='help'){const h=PHELP.split('\n');q('view').innerHTML=esc(h.concat(Array(Math.max(0,ROWS-h.length)).fill('')).slice(0,ROWS).join('\n'));q('stt').textContent='HELP -- press q when done';q('st').className='mp-st';}
    else{
      const v=lines.slice(st.top,st.top+ROWS).map((l,i)=>`<span class="${st.top+i===st.hitLine?'mp-hit':''}">${markup(l)||' '}</span>`);
      while(v.length<ROWS)v.push('<span class="mp-dim">~</span>');
      q('view').innerHTML=v.join('\n');
      q('stt').textContent=st.msg||(st.top>=maxTop()?'Manual page '+name+'(1) line '+(st.top+1)+' (END)':'Manual page '+name+'(1) line '+(st.top+1)+' (press h for help or q to quit)');
      q('st').className='mp-st'+(st.msg?' msg':'');
    }
    q('mc').textContent=done.size+' / '+PMS.length;
    root.querySelectorAll('[data-r="ml"] li').forEach(li=>li.classList.toggle('ok',done.has(+li.dataset.i)));
    q('b').textContent=done.size===PMS.length?'all missions done':done.size+' / '+PMS.length+' missions';q('b').className='badge'+(done.size===PMS.length?' ok':'');
  }
  function find(dir,from){
    if(!st.word)return -1;
    const re=new RegExp(st.word.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'),'i');
    for(let i=from;i>=0&&i<lines.length;i+=dir)if(re.test(lines[i]))return i;
    return -1;
  }
  function jump(i){st.hitLine=i;st.top=Math.min(i,maxTop())}
  function act(a,real,arg){
    const ev={a};st.msg='';
    if(st.mode==='quit'){if(a==='open'||a==='down'){st.mode='page';st.top=0;st.word='';st.hitLine=-1}draw();return}
    if(st.mode==='help'){if(a==='quit')st.mode='page';draw();return}
    switch(a){
      case'down':st.top=Math.min(maxTop(),st.top+1);break;
      case'up':st.top=Math.max(0,st.top-1);break;
      case'pgdn':st.top=Math.min(maxTop(),st.top+ROWS);break;
      case'pgup':st.top=Math.max(0,st.top-ROWS);break;
      case'top':st.top=0;break;
      case'end':st.top=maxTop();break;
      case'help':st.mode='help';break;
      case'quit':st.mode='quit';break;
      case'search':openSearch(arg||'/');return;
      case'find':{st.word=arg.word;st.dir=arg.dir;const i=find(st.dir,st.dir>0?st.top+1:st.top-1);ev.word=st.word;ev.hit=i>=0;if(i<0){st.msg='Pattern not found';st.hitLine=-1}else jump(i);break}
      case'next':case'prev':{if(!st.word){st.msg='No previous regular expression';break}const d=a==='next'?st.dir:-st.dir, from=st.hitLine>=0?st.hitLine+d:(d>0?st.top+1:st.top-1);const i=find(d,from);if(i<0)st.msg='Pattern not found';else jump(i);break}
    }
    if(real)PMS.forEach((m,i)=>{if(!done.has(i)&&m.ok(ev,st))done.add(i)});
    if(a==='end'&&real)st.wasEnd=true;
    draw();
  }
  let real=true;
  function openSearch(c){if(st.mode!=='page')return;inp.hidden=false;inp.value='';inp.dataset.c=c;q('stt').textContent=c;q('st').className='mp-st srch';inp.focus({preventScroll:true})}
  inp.addEventListener('keydown',e=>{
    if(e.key==='Enter'){e.preventDefault();const w=inp.value.trim(), c=inp.dataset.c;inp.hidden=true;scr.focus({preventScroll:true});if(w)act('find',true,{word:w,dir:c==='?'?-1:1});else draw()}
    else if(e.key==='Escape'){inp.hidden=true;scr.focus({preventScroll:true});draw()}
    e.stopPropagation();
  });
  const KEYS={ArrowDown:'down',j:'down',e:'down',Enter:'down',ArrowUp:'up',k:'up',y:'up',' ':'pgdn',f:'pgdn',PageDown:'pgdn',b:'pgup',PageUp:'pgup',g:'top',Home:'top','<':'top',G:'end',End:'end','>':'end',h:'help',q:'quit',n:'next',N:'prev'};
  scr.addEventListener('keydown',e=>{
    if(e.ctrlKey||e.metaKey||e.altKey)return;
    if(st.mode==='quit'&&e.key==='Enter'){e.preventDefault();act('open',true);return}
    if((e.key==='/'||e.key==='?')&&st.mode==='page'){e.preventDefault();openSearch(e.key);return}
    const a=KEYS[e.key];if(!a)return;e.preventDefault();real=true;act(a,true);
  });
  scr.addEventListener('click',()=>{if(st.mode==='quit')act('open',true);if(inp.hidden)scr.focus({preventScroll:true})});
  root.querySelectorAll('.mp-keys .chip').forEach(b=>b.addEventListener('click',()=>{real=false;const a=b.dataset.a;if(a==='search')openSearch('/');else act(st.mode==='quit'&&a!=='quit'?'open':a,false);if(a!=='search')scr.focus({preventScroll:true})}));
  draw();
}

const W=window.DK_W||(window.DK_W={});
W.walk=wWalk; W.fhs=wFhs; W.ospath=wOspath; W.pager=wPager;
})();
