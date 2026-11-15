/* ISO lecture 03 widgets: the loader (data-w="loader"), the process states (data-w="states"),
   fork / exec / exit / wait (data-w="fork"), what the shell does for a redirect or a pipe (data-w="redir");
   and the files of the demo terminal of lecture 03 */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

/* the demo terminal of lecture 03 has only the files of the lecture */
if(typeof ISOSH!=='undefined')ISOSH.PROFILES['03']=fs=>{const h=fs.c.home.c.student.c;delete h.Downloads;delete h.Movies;delete h['watchlist.txt']};

/* the missions of the redirects practice page: < > >> 2> and 2>&1 together */
if(typeof ISOSH!=='undefined'){
  const node=(sh,p)=>ISOSH.lookup(sh.root,ISOSH.split(ISOSH.HOME,p)).node;
  const data=(sh,p)=>{const n=node(sh,p);return n&&n.t==='f'?n.data:''};
  const fdTo=(sh,fd,re)=>(sh.procs||[]).some(p=>p.fds.some(f=>f.fd===fd&&re.test(f.to)));
  (window.ISO_MSETS=window.ISO_MSETS||{}).redir=[
    {t:'Sort <code>fruits.txt</code> with the file as <code>stdin</code>, not as an argument.',h:'sort < FILE',ok:sh=>fdTo(sh,0,/fruits\.txt$/)},
    {t:'Count the lines of <code>unsorted.txt</code> so that <code>wc</code> prints only the number.',h:'wc -l reads stdin, it does not know the name',ok:(sh,c,o)=>/^wc\b/.test(c)&&/^\s*5$/m.test(o)},
    {t:'Save the listing of <code>/etc</code> into <code>etc.txt</code>.',h:'>',ok:sh=>/passwd/.test(data(sh,'~/etc.txt'))},
    {t:'Add a second line to <code>log.txt</code> without deleting the first one.',h:'echo one > log.txt, then >>',ok:(sh,c)=>/>>/.test(c)&&data(sh,'~/log.txt').trim().split('\n').length>=2},
    {t:'Run <code>ls /etc /nope</code> and keep only its <b>errors</b> in <code>errors.txt</code>.',h:'2>',ok:sh=>{const d=data(sh,'~/errors.txt');return/cannot access/.test(d)&&!/passwd/.test(d)}},
    {t:'Run it again with <b>both</b> the output and the errors in <code>all.txt</code>.',h:'> all.txt 2>&1, or &>',ok:sh=>{const d=data(sh,'~/all.txt');return/cannot access/.test(d)&&/passwd/.test(d)}},
  ];
}

/* ---------- shared: Back, dots, Next ---------- */
const NAV=(dots=true)=>`<div class="ps-nav"><button type="button" class="btn ghost" data-r="prev">← Back</button>${dots?'<span class="pdots" data-r="dots" aria-hidden="true"></span>':''}<button type="button" class="btn" data-r="next">Next →</button></div>`;
function stepper(root,count,draw){
  let i=0;const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=k=>{i=Math.max(0,Math.min(count()-1,k));draw(i);
    const d=q('dots');if(d)d.innerHTML=Array.from({length:count()},(_,k)=>`<i class="${k===i?'on':k<i?'dn':''}"></i>`).join('');
    q('prev').disabled=i===0;q('next').disabled=i===count()-1};
  q('prev').addEventListener('click',()=>go(i-1));
  q('next').addEventListener('click',()=>go(i+1));
  return go;
}
/* C code with syntax highlighting (window.ISOHL of shell-ui.js, the hl-* classes of engine.hl) and the current line(s) marked */
const hlC=l=>window.ISOHL?window.ISOHL(l,'c'):esc(l);
const codeHTML=(lines,cur)=>{const on=[].concat(cur);return lines.map((l,k)=>`<span class="${on.includes(k)?'cur':''}">${hlC(l)}</span>`).join('\n')};

/* ---------- the process states ---------- */
const ST={
  ready:{n:'Ready',c:'#7cb342',ps:'R',x:120,y:70},
  running:{n:'Running',c:'#26a6b8',ps:'R',x:300,y:190},
  waiting:{n:'Waiting',c:'#e0a800',ps:'S',x:480,y:70},
  done:{n:'Done',c:'#2c4a7a',ps:'Z',x:300,y:320},
};
/* the transitions: from, to, button, what happens */
const TR=[
  {f:'new',t:'ready',b:'fork + exec',w:'The process is created: it has everything it needs and waits for a free processor.'},
  {f:'ready',t:'running',b:'the scheduler picks it',w:'A processor is free: the scheduler gives it to the process, its code runs.'},
  {f:'running',t:'ready',b:'its time slice expires',w:'After a few milliseconds the scheduler takes the processor back and gives it to another Ready process.'},
  {f:'running',t:'waiting',b:'it reads from the disk / keyboard',w:'The data is not there yet: the process <b>sleeps</b> until the event arrives, it does not use the processor.'},
  {f:'waiting',t:'ready',b:'the data arrives',w:'The event happened (the disk answered, a key was pressed): the process can run again, when a processor is free.'},
  {f:'running',t:'done',b:'it calls exit',w:'The process has finished. It stays <b>Done</b>, a zombie, until its parent reads the exit code.'},
  {f:'done',t:'gone',b:'the parent calls wait',w:'The parent read the exit code: the kernel frees the resources, the process disappears from <code>ps</code>.'},
];
function wStates(root){
  let st='new', log=[];
  const clip=(S,tx,ty)=>{const dx=tx-S.x,dy=ty-S.y,t=Math.min(66/Math.abs(dx||1e-9),32/Math.abs(dy||1e-9));return[S.x+dx*Math.min(t,1),S.y+dy*Math.min(t,1)]};
  const arrow=(a,b,bend,on,label)=>{const A=ST[a],B=ST[b];const mx=(A.x+B.x)/2+bend[0],my=(A.y+B.y)/2+bend[1];
    const [sx,sy]=clip(A,mx,my),[ex,ey]=clip(B,mx,my);
    const lx=(sx+2*mx+ex)/4,ly=(sy+2*my+ey)/4;
    return `<path d="M${sx.toFixed(1)},${sy.toFixed(1)} Q${mx},${my} ${ex.toFixed(1)},${ey.toFixed(1)}" fill="none" stroke="${on?'#e65100':'#9aa9ae'}" stroke-width="${on?3:1.8}" marker-end="url(#ar-st${on?'1':'0'})"/>`+
      `<text x="${lx+label[1]}" y="${ly+label[2]}" text-anchor="middle" style="font:${on?700:500} 16px system-ui,sans-serif" fill="${on?'#e65100':'#5b6b71'}">${label[0]}</text>`};
  const ARC=[['ready','running',[-70,30],['scheduled',-48,0]],['running','ready',[50,-30],['time slice',46,-4]],['running','waiting',[40,30],['waits for I/O',48,10]],['waiting','ready',[0,-46],['I/O done',0,-8]],['running','done',[0,0],['exit',22,4]]];
  root.innerHTML=`<div class="wd stw"><div class="wd-h"><div><h3>Process states</h3><p>Move one process through its states with the events that change them.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ps-x" data-r="w"></div>
  <div class="ps-b"><div><svg class="st-svg" viewBox="0 0 600 380" data-r="svg" role="img" aria-label="The process state diagram"></svg></div>
  <div><div class="st-btns" data-r="btns"></div><ol class="st-log" data-r="log"></ol></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  function draw(lastT){
    let g=`<defs><marker id="ar-st0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0L10,5L0,10z" fill="#9aa9ae"/></marker><marker id="ar-st1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0L10,5L0,10z" fill="#e65100"/></marker></defs>`;
    for(const[a,b,bend,lab]of ARC)g+=arrow(a,b,bend,lastT&&lastT.f===a&&lastT.t===b,lab);
    for(const[k,S]of Object.entries(ST)){const on=k===st;
      g+=`<g><rect x="${S.x-60}" y="${S.y-26}" width="120" height="52" rx="14" fill="${on?S.c:'#fff'}" stroke="${S.c}" stroke-width="${on?0:2.5}"/><text x="${S.x}" y="${S.y+6}" text-anchor="middle" style="font:700 19px system-ui,sans-serif" fill="${on?'#fff':S.c}">${S.n}</text></g>`}
    g+=`<text x="300" y="372" text-anchor="middle" style="font:16px system-ui,sans-serif" fill="#5b6b71">${st==='new'?'not created yet':st==='gone'?'removed: the parent read the exit code':''}</text>`;
    q('svg').innerHTML=g;
    const b=q('b');b.textContent=st==='new'||st==='gone'?'no process':'ps STAT: '+ST[st].ps;b.className='badge'+(st==='done'?' warn':'');
    const opts=TR.filter(t=>t.f===st);
    q('btns').innerHTML=(opts.length?opts:[{f:'gone',t:'new',b:'start again'}]).map((t,i)=>`<button type="button" class="btn ${i?'ghost':''}" data-i="${TR.indexOf(t)}">${esc(t.b)} <span aria-hidden="true">→</span></button>`).join('');
    q('btns').querySelectorAll('button').forEach(x=>x.addEventListener('click',()=>{const t=TR[+x.dataset.i];
      if(!t){st='new';log=[];q('w').innerHTML=START;draw();return}
      st=t.t;log.push((t.f==='new'?'':ST[t.f].n+' → ')+(t.t==='gone'?'removed':ST[t.t].n)+': '+t.b);q('w').innerHTML=t.w;draw(t)}));
    q('log').innerHTML=log.slice(-5).map(l=>`<li>${esc(l)}</li>`).join('');
  }
  const START='Press an event on the right. <code>ps</code> shows <code>R</code> for both Ready and Running, <code>S</code> for Waiting, <code>Z</code> for Done.';
  q('w').innerHTML=START;
  draw();
}

/* ---------- fork, exec, exit, wait on a process tree ---------- */
const P=(pid,ppid,name,st,mark)=>({pid,ppid,name,st,mark});
const SCEN={
  normal:{t:'The shell runs ls',code:['// in bash, for the command `ls`','pid = fork();','if (pid == 0) {','    execvp("ls", args);   // the child','    // ... ls runs, then exit(0)','} else {','    waitpid(pid, &status, 0);','}'],
    steps:[
      {l:0,p:[P(4100,1000,'bash','S')],x:'The shell waits for you to type a command: it is <b>sleeping</b> (S), waiting for the keyboard.'},
      {l:1,p:[P(4100,1000,'bash','R'),P(4301,4100,'bash','R','new')],x:'<code>fork</code> makes a <b>clone</b> of the shell: same code, same open files, a new PID <b>4301</b> whose PPID is <b>4100</b>.'},
      {l:3,p:[P(4100,1000,'bash','R'),P(4301,4100,'ls','R','changed')],x:'In the child <code>fork</code> returned 0, so it calls <code>exec</code>: the loader <b>replaces</b> the program with <code>/usr/bin/ls</code>. The PID stays 4301.'},
      {l:6,p:[P(4100,1000,'bash','S'),P(4301,4100,'ls','R')],x:'The parent calls <code>wait</code> and sleeps until the child ends; <code>ls</code> runs and writes to <code>1</code>, the display.'},
      {l:4,p:[P(4100,1000,'bash','S'),P(4301,4100,'ls','Z','changed')],x:'<code>ls</code> calls <code>exit(0)</code>: it is <b>Done</b>, a zombie for a moment, its exit code waits for the parent.'},
      {l:6,p:[P(4100,1000,'bash','R')],x:'<code>wait</code> returns the exit code (<code>$?</code> is 0) and the kernel frees the child. The shell prints the prompt again.'},
    ]},
  orphan:{t:'The parent ends first',code:['// myapp started two workers','// ...','exit(1);          // myapp crashes','// worker and helper still run'],
    steps:[
      {l:0,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(100,10,'myapp','R'),P(200,100,'myapp-worker','R'),P(201,100,'myapp-helper','S')],x:'<code>myapp</code> (PID 100) has two children: a worker and a helper.'},
      {l:2,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(100,10,'myapp','Z','changed'),P(200,100,'myapp-worker','R','orphan'),P(201,100,'myapp-helper','S','orphan')],x:'<code>myapp</code> ends. Its children still run, but their parent is gone: they are <b>orphans</b>.'},
      {l:3,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(200,1,'myapp-worker','R','changed'),P(201,1,'myapp-helper','S','changed')],x:'The kernel <b>reparents</b> them to <code>init</code>: their PPID is now 1. (<code>user@1000</code> read the exit code of <code>myapp</code>.)'},
      {l:3,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(200,1,'myapp-worker','Z','changed'),P(201,1,'myapp-helper','S')],x:'Later the worker exits: it is a zombie, waiting for its <b>new</b> parent.'},
      {l:3,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(201,1,'myapp-helper','S')],x:'<code>init</code> calls <code>wait</code> for every child it adopted: the zombie is removed. This is why <code>init</code> must never stop.'},
    ]},
  zombie:{t:'The parent never calls wait',code:['pid = fork();','if (pid == 0) {','    // the worker does its job','    exit(0);','}','// myapp forgets to call wait','for (;;) work();'],
    steps:[
      {l:0,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R')],x:'<code>myapp</code> runs.'},
      {l:0,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R'),P(4214,4213,'myapp-worker','R','new')],x:'It calls <code>fork</code>: <code>myapp-worker</code> (PID 4214) does a job.'},
      {l:3,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R'),P(4214,4213,'myapp-worker','Z','changed')],x:'The worker calls <code>exit(0)</code>: it is <b>Done</b>. <code>ps</code> shows it with <code>Z</code> and <code>&lt;defunct&gt;</code>.'},
      {l:6,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R'),P(4214,4213,'myapp-worker','Z')],x:'<code>myapp</code> never calls <code>wait</code>: the zombie <b>stays</b>. It does not run, but its PID and its entry in the process table stay taken.'},
      {l:6,p:[P(1,0,'systemd (init)','S'),P(4100,4090,'bash','S'),P(4214,1,'myapp-worker','Z','changed')],x:'When <code>myapp</code> itself ends, the zombie is reparented to <code>init</code> ...'},
      {l:6,p:[P(1,0,'systemd (init)','S'),P(4100,4090,'bash','S')],x:'... which calls <code>wait</code>: the zombie is finally removed.'},
    ]},
};
const SN={R:['Running','#26a6b8'],S:['Sleeping','#e0a800'],Z:['Zombie','#2c4a7a']};
function wFork(root){
  let sc=root.dataset.sc||'normal';
  root.innerHTML=`<div class="wd fkw"><div class="wd-h"><div><h3>fork, exec, exit, wait</h3><p>Step through the life of a process. The tree is what <code>pstree -p</code> would show.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><div class="seg" data-seg="sc">${[["normal","a command"],["orphan","orphan"],["zombie","zombie"]].map(([v,l])=>`<button type="button" data-v="${v}" class="${v===sc?"on":""}">${l}</button>`).join("")}</div>${NAV()}</div>
  <div class="ps-x" data-r="x"></div>
  <div class="ps-b"><div><div class="ptree" data-r="tree"></div></div><div><pre class="sh fkcode" data-r="code"></pre></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=stepper(root,()=>SCEN[sc].steps.length,i=>{
    const S=SCEN[sc], st=S.steps[i];
    const kids=id=>st.p.filter(p=>p.ppid===id);
    const roots=st.p.filter(p=>!st.p.some(x=>x.pid===p.ppid));
    const node=(p,d)=>{const[sn,c]=SN[p.st];
      return `<div class="pnode ${p.mark||''}" style="margin-left:${d*22}px"><span class="pid">${p.pid}</span><b>${esc(p.name)}</b><span class="pst" style="background:${c}">${p.st} · ${sn}</span>${p.mark==='orphan'?'<span class="ptag">orphan</span>':p.mark==='new'?'<span class="ptag">new</span>':''}<span class="ppid">PPID ${p.ppid}</span></div>`+kids(p.pid).map(k=>node(k,d+1)).join('')};
    q('tree').innerHTML=roots.map(r=>node(r,0)).join('');
    q('code').innerHTML=codeHTML(S.code,st.l);
    q('x').innerHTML=st.x;
    q('b').textContent=S.t;
  });
  root.querySelectorAll('[data-seg="sc"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="sc"] button').forEach(x=>x.classList.toggle('on',x===b));sc=b.dataset.v;go(0)}));
  go(0);
}

/* ---------- the loader: from /bin/ls to a running process ---------- */
const MEM={ls:['the code of ls','px'],libc:['libc.so.6','lb'],sel:['libselinux.so.1','lb']};
const LSTEPS=[
  {t:'exec',file:[],mem:[],act:'The child of the shell calls <code>exec("/bin/ls")</code>: the old program is thrown away and the <b>loader</b> starts. The memory is empty.',
   cmd:'$ file /bin/ls\n/bin/ls: ELF 64-bit executable, dynamically linked'},
  {t:'program',file:['load','code'],mem:['ls'],act:'<b>Program loading.</b> The loader reads <i>how to load it</i> and copies the <b>code of ls</b> into memory.'},
  {t:'libraries',file:['links'],mem:['ls','libc','sel'],act:'<b>Library loading.</b> <code>ls</code> needs two libraries: the loader finds them on the disk and loads them into the same process.',
   cmd:'$ ldd /bin/ls\n  libselinux.so.1 => /usr/lib/libselinux.so.1\n  libc.so.6 => /usr/lib/libc.so.6'},
  {t:'linking',file:['code','links'],mem:['ls','libc','sel'],link:true,act:'<b>Dynamic linking.</b> <code>ls</code> calls <code>printf</code> and <code>opendir</code>, which are in <code>libc</code>: the loader connects each call to the function.'},
  {t:'execution',file:['code'],mem:['ls','libc','sel'],run:true,act:'<b>Execution.</b> The processor jumps to the start of <code>ls</code>. Its code runs and calls the functions of the libraries.'},
];
function wLoader(root){
  let cur=0;
  root.innerHTML=`<div class="wd ldw"><div class="wd-h"><div><h3>The loader, step by step</h3><p>From the file <code>/bin/ls</code> to a running <code>ls</code>.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><div class="ldsteps" data-r="steps"></div>${NAV(false)}</div>
  <div class="ps-x" data-r="x"></div>
  <div class="ldgrid"><div><div data-r="file"></div><pre class="sh ldcmd" data-r="cmd"></pre></div><div class="ldmid" data-r="mid"></div><div data-r="mem"></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const FP=[['load','📋 how to load it'],['code','⚙️ the code'],['links','🔗 the libraries it needs']];
  const shcolor=t=>t.split('\n').map(l=>l.startsWith('$ ')?'<span class="p">$</span> <span class="c">'+esc(l.slice(2))+'</span>':'<span class="o">'+esc(l)+'</span>').join('\n');
  const go=stepper(root,()=>LSTEPS.length,i=>{cur=i;
    const S=LSTEPS[i], prev=i?LSTEPS[i-1].mem:[];
    q('steps').innerHTML=LSTEPS.map((x,k)=>`<button type="button" class="lddot ${k===i?'on':k<i?'dn':''}" data-k="${k}"><b>${k+1}</b> ${x.t}</button>`).join('');
    q('steps').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>go(+b.dataset.k)));
    q('file').innerHTML=`<div class="ldh">📄 /bin/ls <span>on the disk</span></div>`+FP.map(([k,n])=>`<div class="ldpart ${S.file.includes(k)?'on '+k:''}"><b>${n}</b></div>`).join('');
    q('mid').innerHTML=`<div class="ldloader ${i<4?'on':''}">⚙️ loader</div><div class="ldarrow">${i===0?'exec':i<4?'→':'run'}</div>${S.run?'<div class="ldcpu">🧠 the processor runs ls</div>':''}`;
    q('mem').innerHTML=`<div class="ldh">🧠 the process <span>in memory</span></div>`+(S.mem.length?S.mem.map(k=>{const[n,c]=MEM[k];const nw=!prev.includes(k)&&i>0;
      return `<div class="ldrow ${c} ${nw?'new':''}"><b>${esc(n)}</b>${S.link&&k==='ls'?'<span class="ldgot">printf, opendir → libc.so.6</span>':''}${S.run&&k==='ls'?'<span class="ldip">◀ running</span>':''}</div>`}).join(''):'<div class="ldempty">empty</div>');
    q('x').innerHTML=S.act;
    q('cmd').hidden=!S.cmd; q('cmd').innerHTML=S.cmd?shcolor(S.cmd):'';
    q('b').textContent=(i+1)+' / '+LSTEPS.length;
  });
  go(0);
}

/* ---------- what the shell does for a redirect or a pipe ---------- */
const STD=['stdin','stdout','stderr'];
const T=(n,pid,rows,mark)=>({n,pid,rows,mark});            // rows: [fd, target, 'ch' changed now | 'x' closed now]
const T0=(...more)=>[[0,'keyboard'],[1,'display'],[2,'display'],...more];
const ERR="ls: cannot access '/nope': No such file or directory";
const ETC='/etc:\nfstab\nhostname\npasswd';
const RD={
  in:{cmd:'sort < fruits.txt',code:['pid = fork();','// the child, still bash:','fd = open("fruits.txt", O_RDONLY);','dup2(fd, 0);','close(fd);','execvp("sort", ["sort"]);'],
    steps:[
      {l:0,t:[T('bash (child)',4301,T0(),'new')],x:'<code>fork</code>: the child is a copy of the shell, with a copy of its table: <code>0</code>, <code>1</code>, <code>2</code> point to the terminal.'},
      {l:2,t:[T('bash (child)',4301,T0([3,'fruits.txt','ch']))],x:'The child opens <code>fruits.txt</code> for reading. The kernel puts it at the first free index: <b>3</b>.'},
      {l:3,t:[T('bash (child)',4301,[[0,'fruits.txt','ch'],[1,'display'],[2,'display'],[3,'fruits.txt']])],x:'<code>dup2(3, 0)</code>: index <b>0</b> now points to the same file as 3. The keyboard is out of the table.'},
      {l:4,t:[T('bash (child)',4301,[[0,'fruits.txt'],[1,'display'],[2,'display'],[3,'fruits.txt','x']])],x:'<code>close(3)</code>: the copy at 3 is not needed any more.'},
      {l:5,t:[T('sort',4301,[[0,'fruits.txt'],[1,'display'],[2,'display']],'new')],out:[['display','apple\nbanana\ncherry']],x:'<code>exec</code> replaces bash with <code>sort</code>; the table stays. <code>sort</code> reads <code>0</code> as always: it gets the file and never learns its name.'},
    ]},
  out:{cmd:'ls > files.txt',code:['pid = fork();','// the child, still bash:','fd = open("files.txt", O_WRONLY|O_CREAT|O_TRUNC);','dup2(fd, 1);','close(fd);','execvp("ls", ["ls"]);'],
    steps:[
      {l:0,t:[T('bash (child)',4301,T0(),'new')],x:'<code>fork</code>: the child has a copy of the table of the shell.'},
      {l:2,t:[T('bash (child)',4301,T0([3,'files.txt','ch']))],out:[['files.txt','']],x:'The child opens <code>files.txt</code> at <b>3</b>. <code>O_CREAT</code> creates it, <code>O_TRUNC</code> <b>empties</b> it: now, before <code>ls</code> even starts.'},
      {l:3,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'files.txt','ch'],[2,'display'],[3,'files.txt']])],out:[['files.txt','']],x:'<code>dup2(3, 1)</code>: index <b>1</b>, <code>stdout</code>, now points to <code>files.txt</code>.'},
      {l:4,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'files.txt'],[2,'display'],[3,'files.txt','x']])],out:[['files.txt','']],x:'<code>close(3)</code>.'},
      {l:5,t:[T('ls',4301,[[0,'keyboard'],[1,'files.txt'],[2,'display']],'new')],out:[['display',''],['files.txt','backup\nfiles.txt\nfruits.txt\nnotes.txt\nproject\nunsorted.txt']],x:'<code>ls</code> writes to 1: the names go into the file, one per line, nothing on the display. <code>files.txt</code> is in the list: it was created before <code>ls</code> ran.'},
    ]},
  append:{cmd:'cat notes.txt >> log.txt',code:['pid = fork();','// the child, still bash:','fd = open("log.txt", O_WRONLY|O_CREAT|O_APPEND);','dup2(fd, 1);','close(fd);','execvp("cat", ["cat", "notes.txt"]);'],
    steps:[
      {l:0,t:[T('bash (child)',4301,T0(),'new')],out:[['log.txt','one\ntwo']],x:'<code>fork</code>. <code>log.txt</code> already has two lines.'},
      {l:2,t:[T('bash (child)',4301,T0([3,'log.txt','ch']))],out:[['log.txt','one\ntwo']],x:'The child opens <code>log.txt</code> at <b>3</b> with <code>O_APPEND</code> instead of <code>O_TRUNC</code>: the lines stay, every write goes at the <b>end</b>.'},
      {l:3,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'log.txt','ch'],[2,'display'],[3,'log.txt']])],out:[['log.txt','one\ntwo']],x:'<code>dup2(3, 1)</code>: <code>stdout</code> points to <code>log.txt</code>.'},
      {l:4,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'log.txt'],[2,'display'],[3,'log.txt','x']])],out:[['log.txt','one\ntwo']],x:'<code>close(3)</code>.'},
      {l:5,t:[T('cat',4301,[[0,'keyboard'],[1,'log.txt'],[2,'display']],'new')],out:[['display',''],['log.txt','one\ntwo\nbuy milk\ncall mom']],x:'<code>cat</code> writes the lines of <code>notes.txt</code> to 1: they are added after the old ones. Use <code>&gt;&gt;</code> for logs.'},
    ]},
  err:{cmd:'ls /nope 2> errors.txt',code:['pid = fork();','// the child, still bash:','fd = open("errors.txt", O_WRONLY|O_CREAT|O_TRUNC);','dup2(fd, 2);','close(fd);','execvp("ls", ["ls", "/nope"]);'],
    steps:[
      {l:0,t:[T('bash (child)',4301,T0(),'new')],x:'<code>fork</code>: the child has a copy of the table of the shell.'},
      {l:2,t:[T('bash (child)',4301,T0([3,'errors.txt','ch']))],x:'The child opens <code>errors.txt</code> at <b>3</b>, empty.'},
      {l:3,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'display'],[2,'errors.txt','ch'],[3,'errors.txt']])],x:'<code>dup2(3, 2)</code>: only index <b>2</b>, <code>stderr</code>, changes. <code>1</code> still goes to the display.'},
      {l:4,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'display'],[2,'errors.txt'],[3,'errors.txt','x']])],x:'<code>close(3)</code>.'},
      {l:5,t:[T('ls',4301,[[0,'keyboard'],[1,'display'],[2,'errors.txt']],'new')],out:[['display',''],['errors.txt',ERR]],x:'<code>ls</code> writes its error to 2: the message lands in the file, the display stays clean.'},
    ]},
  both:{cmd:'ls /etc /nope > all.txt 2>&1',code:['pid = fork();','// the child, the redirects from left to right:','fd = open("all.txt", O_WRONLY|O_CREAT|O_TRUNC);','dup2(fd, 1);  close(fd);     // > all.txt','dup2(1, 2);                  // 2>&1','execvp("ls", ["ls", "/etc", "/nope"]);'],
    steps:[
      {l:0,t:[T('bash (child)',4301,T0(),'new')],x:'<code>fork</code>. The shell applies the redirects <b>from left to right</b>.'},
      {l:2,t:[T('bash (child)',4301,T0([3,'all.txt','ch']))],x:'<code>&gt; all.txt</code>: open the file at <b>3</b> ...'},
      {l:3,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'all.txt','ch'],[2,'display'],[3,'all.txt','x']])],x:'... move it to <b>1</b> and close 3.'},
      {l:4,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'all.txt'],[2,'all.txt','ch']])],x:'<code>2&gt;&amp;1</code> is <code>dup2(1, 2)</code>: 2 points where 1 points <b>now</b>, to <code>all.txt</code>.'},
      {l:5,t:[T('ls',4301,[[0,'keyboard'],[1,'all.txt'],[2,'all.txt']],'new')],out:[['display',''],['all.txt',ERR+'\n'+ETC]],x:'Both streams go into <code>all.txt</code>. <code>&amp;&gt; all.txt</code> is the short form of the same thing.'},
    ]},
  order:{cmd:'ls /etc /nope 2>&1 > all.txt',code:['pid = fork();','// the child, the redirects from left to right:','dup2(1, 2);                  // 2>&1','fd = open("all.txt", O_WRONLY|O_CREAT|O_TRUNC);','dup2(fd, 1);  close(fd);     // > all.txt','execvp("ls", ["ls", "/etc", "/nope"]);'],
    steps:[
      {l:0,t:[T('bash (child)',4301,T0(),'new')],x:'<code>fork</code>. The same redirects as in the previous example, in the <b>other order</b>.'},
      {l:2,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'display'],[2,'display','ch']])],x:'<code>2&gt;&amp;1</code> comes first: 2 points where 1 points <b>now</b>, the display. Nothing changes.'},
      {l:3,t:[T('bash (child)',4301,T0([3,'all.txt','ch']))],x:'<code>&gt; all.txt</code>: open the file at <b>3</b> ...'},
      {l:4,t:[T('bash (child)',4301,[[0,'keyboard'],[1,'all.txt','ch'],[2,'display'],[3,'all.txt','x']])],x:'... and move it to <b>1</b>. 2 does not follow: <code>dup2</code> copied the old target, it is not a link to 1.'},
      {l:5,t:[T('ls',4301,[[0,'keyboard'],[1,'all.txt'],[2,'display']],'new')],out:[['display',ERR],['all.txt',ETC]],x:'The listing goes into the file, the error still reaches the display. Write <code>2&gt;&amp;1</code> <b>after</b> <code>&gt; file</code>.'},
    ]},
  pipe:{cmd:'ls | wc -l',code:['pipe(p);              // p[0]: read end, p[1]: write end','if (fork() == 0) {    // child 1','  dup2(p[1], 1);  close(p[0]);  close(p[1]);','  execvp("ls", ...); }','if (fork() == 0) {    // child 2','  dup2(p[0], 0);  close(p[0]);  close(p[1]);','  execvp("wc", ...); }','close(p[0]);  close(p[1]);  wait for both;'],
    steps:[
      {l:0,t:[T('bash',4100,T0([3,'pipe (read)','ch'],[4,'pipe (write)','ch']))],x:'The shell asks the kernel for a <b>pipe</b>: a buffer with two ends, placed at the first free indexes, 3 and 4.'},
      {l:1,t:[T('bash',4100,T0([3,'pipe (read)'],[4,'pipe (write)'])),T('child 1',4301,T0([3,'pipe (read)'],[4,'pipe (write)']),'new')],x:'<code>fork</code>: child 1 gets a copy of the table, both pipe ends included.'},
      {l:[2,3],t:[T('bash',4100,T0([3,'pipe (read)'],[4,'pipe (write)'])),T('ls',4301,[[0,'keyboard'],[1,'pipe (write)','ch'],[2,'display'],[3,'pipe (read)','x'],[4,'pipe (write)','x']])],x:'Child 1 puts the <b>write end</b> at 1, closes 3 and 4, and becomes <code>ls</code>.'},
      {l:[4,5,6],t:[T('bash',4100,T0([3,'pipe (read)'],[4,'pipe (write)'])),T('ls',4301,[[0,'keyboard'],[1,'pipe (write)'],[2,'display']]),T('wc -l',4302,[[0,'pipe (read)','ch'],[1,'display'],[2,'display'],[3,'pipe (read)','x'],[4,'pipe (write)','x']],'new')],x:'The same for child 2: the <b>read end</b> goes to 0, 3 and 4 are closed, it becomes <code>wc -l</code>.'},
      {l:7,t:[T('bash',4100,T0([3,'pipe (read)','x'],[4,'pipe (write)','x'])),T('ls',4301,[[0,'keyboard'],[1,'pipe (write)'],[2,'display']]),T('wc -l',4302,[[0,'pipe (read)'],[1,'display'],[2,'display']])],out:[['display','5']],x:'The shell closes its own ends and waits. Both run at the same time; when <code>ls</code> ends, <code>wc</code> reads end of file and prints the count.'},
    ]},
};
const DEF={0:'keyboard',1:'display',2:'display'};
function fdCard(t){
  const rows=t.rows.map(([fd,to,m])=>{const cls=m||(fd<3&&DEF[fd]!==to?'rd':'');
    return `<tr class="${cls}"><td>${fd}</td><td>${fd<3?STD[fd]:''}</td><td>→ ${esc(to)}</td></tr>`}).join('');
  return `<div class="fdp rd-t ${t.mark||''}"><div class="fdh"><b>${esc(t.n)}</b> <span>PID ${t.pid}</span></div><table class="fdt">${rows}</table></div>`;
}
function wRedir(root){
  let sc=RD[root.dataset.sc]?root.dataset.sc:'in';
  const list=(root.dataset.list||'in,out,append,err,both,order,pipe').split(',').filter(k=>RD[k]);
  root.innerHTML=`<div class="wd rdw"><div class="wd-h"><div><h3>What the shell does before the command runs</h3><p>Step through the calls the shell makes in the child, and watch the File Descriptor Table.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><div class="rd-cmds">${list.map(k=>`<button type="button" class="chip ${k===sc?'on':''}" data-k="${k}">${esc(RD[k].cmd)}</button>`).join('')}</div>${NAV()}</div>
  <div class="ps-x" data-r="x"></div>
  <div class="rd-b" data-r="body"><pre class="sh fkcode rd-code" data-r="code"></pre><div class="rd-tabs" data-r="tabs"></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=stepper(root,()=>RD[sc].steps.length,i=>{
    const S=RD[sc], st=S.steps[i];
    // one process: the code on the left, its table on the right; several (a pipe): the code above, the tables in a row under it
    q('body').className='rd-b '+(S.steps.some(x=>x.t.length>1)?'rd-stack':'rd-side');
    const outs=(st.out||[]).map(([to,txt])=>`<div class="rd-o ${to==='display'?'dsp':''}"><div class="rd-oh">${to==='display'?'🖥 the display':'📄 '+esc(to)}</div><pre>${txt?esc(txt):'<i>(empty)</i>'}</pre></div>`).join('');
    q('tabs').innerHTML=st.t.map(fdCard).join('')+outs;
    q('code').innerHTML=codeHTML(S.code,st.l);
    q('x').innerHTML=st.x;
    q('b').textContent='step '+(i+1)+' / '+S.steps.length;
  });
  root.querySelectorAll('.rd-cmds .chip').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('.rd-cmds .chip').forEach(x=>x.classList.toggle('on',x===b));sc=b.dataset.k;go(0)}));
  go(0);
}

const W=window.DK_W||(window.DK_W={});
W.states=wStates; W.fork=wFork; W.loader=wLoader; W.redir=wRedir;
})();
