/* ISO lecture 03 widgets: the process states (data-w="states") and fork / exec / exit / wait (data-w="fork") */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
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
  {f:'running',t:'waiting',b:'it reads from the disk / keyboard',w:'The data is not there yet: the process sleeps until the event arrives, it does not use the processor.'},
  {f:'waiting',t:'ready',b:'the data arrives',w:'The event happened (the disk answered, a key was pressed): the process can run again, when a processor is free.'},
  {f:'running',t:'done',b:'it calls exit',w:'The process has finished. It stays in Done, a zombie, until its parent reads the exit code.'},
  {f:'done',t:'gone',b:'the parent calls wait',w:'The parent read the exit code: the kernel frees the resources, the process disappears from ps.'},
];
function wStates(root){
  let st='new', log=[];
  const clip=(S,tx,ty)=>{const dx=tx-S.x,dy=ty-S.y,t=Math.min(66/Math.abs(dx||1e-9),32/Math.abs(dy||1e-9));return[S.x+dx*Math.min(t,1),S.y+dy*Math.min(t,1)]};
  const arrow=(a,b,bend,on,label)=>{const A=ST[a],B=ST[b];const mx=(A.x+B.x)/2+bend[0],my=(A.y+B.y)/2+bend[1];
    const [sx,sy]=clip(A,mx,my),[ex,ey]=clip(B,mx,my);
    const lx=(sx+2*mx+ex)/4,ly=(sy+2*my+ey)/4;
    return `<path d="M${sx.toFixed(1)},${sy.toFixed(1)} Q${mx},${my} ${ex.toFixed(1)},${ey.toFixed(1)}" fill="none" stroke="${on?'#e65100':'#9aa9ae'}" stroke-width="${on?3:1.8}" marker-end="url(#ar-st${on?'1':'0'})"/>`+
      `<text x="${lx+label[1]}" y="${ly+label[2]}" text-anchor="middle" style="font:${on?700:500} 12.5px system-ui,sans-serif" fill="${on?'#e65100':'#5b6b71'}">${label[0]}</text>`};
  const ARC=[['ready','running',[-70,30],['scheduled',-48,0]],['running','ready',[50,-30],['time slice',46,-4]],['running','waiting',[40,30],['waits for I/O',48,10]],['waiting','ready',[0,-46],['I/O done',0,-8]],['running','done',[0,0],['exit',22,4]]];
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>Process states</h3><p>Move one process through its states with the events that change them. The badge shows the letter <code>ps</code> prints in the <code>STAT</code> column.</p></div><span class="badge" data-r="b"></span></div>
  <div class="wd-b"><div><svg class="fig" viewBox="0 0 600 380" data-r="svg" role="img" aria-label="The process state diagram"></svg></div>
  <div><div class="ctrls st-btns" data-r="btns" style="padding:0;background:none;border:0;flex-direction:column;gap:8px"></div><p class="st-what" data-r="w"></p><ol class="st-log" data-r="log"></ol></div></div>
  <div class="wd-f"><b>ps</b> cannot tell Ready from Running: both are <code>R</code>. <code>S</code> is sleeping (waiting), <code>Z</code> a zombie.</div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  function draw(lastT){
    let g=`<defs><marker id="ar-st0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0L10,5L0,10z" fill="#9aa9ae"/></marker><marker id="ar-st1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0L10,5L0,10z" fill="#e65100"/></marker></defs>`;
    for(const[a,b,bend,lab]of ARC)g+=arrow(a,b,bend,lastT&&lastT.f===a&&lastT.t===b,lab);
    for(const[k,S]of Object.entries(ST)){const on=k===st;
      g+=`<g><rect x="${S.x-60}" y="${S.y-26}" width="120" height="52" rx="14" fill="${on?S.c:'#fff'}" stroke="${S.c}" stroke-width="${on?0:2.5}"/><text x="${S.x}" y="${S.y+6}" text-anchor="middle" style="font:700 17px system-ui,sans-serif" fill="${on?'#fff':S.c}">${S.n}</text></g>`}
    g+=`<text x="300" y="372" text-anchor="middle" style="font:13px system-ui,sans-serif" fill="#5b6b71">${st==='new'?'not created yet':st==='gone'?'removed: the parent read the exit code':''}</text>`;
    q('svg').innerHTML=g;
    const b=q('b');b.textContent=st==='new'||st==='gone'?'no process':'ps STAT: '+ST[st].ps;b.className='badge'+(st==='done'?' warn':'');
    const opts=TR.filter(t=>t.f===st);
    q('btns').innerHTML=(opts.length?opts:[{f:'gone',t:'new',b:'start again'}]).map((t,i)=>`<button type="button" class="btn ${i?'ghost':''}" data-i="${TR.indexOf(t)}">${esc(t.b)} <span aria-hidden="true">→</span></button>`).join('');
    q('btns').querySelectorAll('button').forEach(x=>x.addEventListener('click',()=>{const t=TR[+x.dataset.i];
      if(!t){st='new';log=[];q('w').textContent='';draw();return}
      st=t.t;log.push((t.f==='new'?'':ST[t.f].n+' → ')+(t.t==='gone'?'removed':ST[t.t].n)+': '+t.b);q('w').textContent=t.w;draw(t)}));
    q('log').innerHTML=log.slice(-6).map(l=>`<li>${esc(l)}</li>`).join('');
  }
  draw();
}

/* ---------- fork, exec, exit, wait on a process tree ---------- */
const P=(pid,ppid,name,st,mark)=>({pid,ppid,name,st,mark});
const SCEN={
  normal:{t:'The shell runs ls',code:['// in bash, for the command `ls`','pid = fork();','if (pid == 0) {','    execvp("ls", args);   // the child','    // ... ls runs, then exit(0)','} else {','    waitpid(pid, &status, 0);','}'],
    steps:[
      {l:0,p:[P(4100,1000,'bash','S')],x:'The shell waits for you to type a command: it is <b>sleeping</b> (S), waiting for the keyboard.'},
      {l:1,p:[P(4100,1000,'bash','R'),P(4301,4100,'bash','R','new')],x:'<code>fork</code> makes a <b>clone</b> of the shell: the same code, the same open files (0, 1, 2), a new PID <b>4301</b> whose PPID is <b>4100</b>. Both continue after <code>fork</code>.'},
      {l:3,p:[P(4100,1000,'bash','R'),P(4301,4100,'ls','R','changed')],x:'In the child, <code>fork</code> returned 0, so it calls <code>exec</code>: the loader <b>replaces</b> the executable with <code>/usr/bin/ls</code>. The PID stays 4301.'},
      {l:6,p:[P(4100,1000,'bash','S'),P(4301,4100,'ls','R')],x:'The parent calls <code>wait</code> and sleeps until the child ends; <code>ls</code> runs and writes to <code>1</code>, the display.'},
      {l:4,p:[P(4100,1000,'bash','S'),P(4301,4100,'ls','Z','changed')],x:'<code>ls</code> calls <code>exit(0)</code>: it is <b>Done</b> (a zombie for a moment), its exit code waits for the parent.'},
      {l:6,p:[P(4100,1000,'bash','R')],x:'<code>wait</code> returns with the exit code (<code>$?</code> is 0): the kernel frees the child. The shell shows the prompt again.'},
    ]},
  orphan:{t:'The parent ends first: an orphan',code:['// myapp started two workers','// ...','exit(1);          // myapp crashes','// worker and helper still run'],
    steps:[
      {l:0,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(100,10,'myapp','R'),P(200,100,'myapp-worker','R'),P(201,100,'myapp-helper','S')],x:'<code>myapp</code> (PID 100) has two children: a worker and a helper.'},
      {l:2,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(100,10,'myapp','Z','changed'),P(200,100,'myapp-worker','R','orphan'),P(201,100,'myapp-helper','S','orphan')],x:'<code>myapp</code> ends. Its children still run, but their parent is gone: they are <b>orphans</b>.'},
      {l:3,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(200,1,'myapp-worker','R','changed'),P(201,1,'myapp-helper','S','changed')],x:'The kernel <b>reparents</b> them to <code>init</code> (PID 1): their PPID is now 1. (<code>user@1000</code> read the exit code of <code>myapp</code>.)'},
      {l:3,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(200,1,'myapp-worker','Z','changed'),P(201,1,'myapp-helper','S')],x:'Later the worker exits: it is a zombie, waiting for its <b>new</b> parent.'},
      {l:3,p:[P(1,0,'systemd (init)','S'),P(10,1,'user@1000.service','S'),P(201,1,'myapp-helper','S')],x:'<code>init</code> calls <code>wait</code> for every child it adopted: the zombie is removed. This is why <code>init</code> must never stop.'},
    ]},
  zombie:{t:'The parent never calls wait: a zombie',code:['pid = fork();','if (pid == 0) {','    // the worker does its job','    exit(0);','}','// myapp forgets to call wait','for (;;) work();'],
    steps:[
      {l:0,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R')],x:'<code>myapp</code> runs.'},
      {l:0,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R'),P(4214,4213,'myapp-worker','R','new')],x:'It calls <code>fork</code>: <code>myapp-worker</code> (PID 4214) does a job.'},
      {l:3,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R'),P(4214,4213,'myapp-worker','Z','changed')],x:'The worker calls <code>exit(0)</code>: it is <b>Done</b>. <code>ps</code> shows it with <code>Z</code> and <code>&lt;defunct&gt;</code>.'},
      {l:6,p:[P(4100,4090,'bash','S'),P(4213,4100,'myapp','R'),P(4214,4213,'myapp-worker','Z')],x:'<code>myapp</code> never calls <code>wait</code>: the zombie <b>stays</b>. It does not run, but its PID and its entry in the process table stay allocated. Thousands of them fill the table.'},
      {l:6,p:[P(1,0,'systemd (init)','S'),P(4100,4090,'bash','S'),P(4214,1,'myapp-worker','Z','changed')],x:'When <code>myapp</code> itself ends, the zombie is reparented to <code>init</code> ...'},
      {l:6,p:[P(1,0,'systemd (init)','S'),P(4100,4090,'bash','S')],x:'... which calls <code>wait</code>: the zombie is finally removed.'},
    ]},
};
const SN={R:['Running','#26a6b8'],S:['Sleeping','#e0a800'],Z:['Zombie','#2c4a7a']};
function wFork(root){
  let sc=root.dataset.sc||'normal', i=0;
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>fork, exec, exit, wait</h3><p>Step through the life of a process. The tree is what <code>pstree -p</code> would show.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls"><div class="ctrl"><label>Scenario</label><div class="seg" data-seg="sc">${[["normal","a command"],["orphan","orphan"],["zombie","zombie"]].map(([v,l])=>`<button type="button" data-v="${v}" class="${v===sc?"on":""}">${l}</button>`).join("")}</div></div></div>
  <div class="wd-b"><div><div class="ptree" data-r="tree"></div></div><div><pre class="sh fkcode" data-r="code"></pre></div></div>
  <div class="wd-f fkx" data-r="x"></div>
  <div class="ctrls" style="border-top:1px solid var(--line);border-bottom:0;justify-content:space-between"><button type="button" class="btn ghost" data-r="prev">← Back</button><span class="small" data-r="pos" style="align-self:center;margin:0"></span><button type="button" class="btn" data-r="next">Next step →</button></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  function draw(){
    const S=SCEN[sc], st=S.steps[i];
    const kids=id=>st.p.filter(p=>p.ppid===id);
    const roots=st.p.filter(p=>!st.p.some(x=>x.pid===p.ppid));
    const node=(p,d)=>{const[sn,c]=SN[p.st];
      return `<div class="pnode ${p.mark||''}" style="margin-left:${d*26}px"><span class="pid">${p.pid}</span><b>${esc(p.name)}</b><span class="pst" style="background:${c}">${p.st} · ${sn}</span><span class="ppid">PPID ${p.ppid}</span>${p.mark==='orphan'?'<span class="ptag">orphan</span>':p.mark==='new'?'<span class="ptag">new</span>':''}</div>`+kids(p.pid).map(k=>node(k,d+1)).join('')};
    q('tree').innerHTML=roots.map(r=>node(r,0)).join('');
    q('code').innerHTML=S.code.map((l,k)=>`<span class="${k===st.l?'cur':''}">${esc(l)}</span>`).join('\n');
    q('x').innerHTML=st.x;
    q('pos').textContent='step '+(i+1)+' / '+S.steps.length;
    q('b').textContent=S.t;
    q('prev').disabled=i===0; q('next').disabled=i===S.steps.length-1;
  }
  root.querySelectorAll('[data-seg="sc"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="sc"] button').forEach(x=>x.classList.toggle('on',x===b));sc=b.dataset.v;i=0;draw()}));
  q('prev').addEventListener('click',()=>{if(i>0){i--;draw()}});
  q('next').addEventListener('click',()=>{if(i<SCEN[sc].steps.length-1){i++;draw()}});
  draw();
}

/* ---------- the loader: from /bin/ls to a running process ---------- */
const MEM={
  ls:['the code of ls','px'],
  libc:['libc.so.6','lb'],
  sel:['libselinux.so.1','lb'],
};
const LSTEPS=[
  {t:'exec',file:[],mem:[],act:'The shell runs <code>ls</code>: its child calls <code>exec("/bin/ls")</code>. The old program is thrown away and the <b>loader</b> starts. The memory of the process is still empty.',
   cmd:'$ file /bin/ls\n/bin/ls: ELF 64-bit executable, dynamically linked'},
  {t:'program loading',file:['load','code'],mem:['ls'],act:'<b>Program loading.</b> The loader reads <i>how to load it</i> and copies the <b>code of ls</b> into memory.'},
  {t:'library loading',file:['links'],mem:['ls','libc','sel'],act:'<b>Library loading.</b> <code>ls</code> needs two libraries. The loader finds them on the disk and loads them into the same process.',
   cmd:'$ ldd /bin/ls\n  libselinux.so.1 => /usr/lib/libselinux.so.1\n  libc.so.6 => /usr/lib/libc.so.6'},
  {t:'linking',file:['code','links'],mem:['ls','libc','sel'],link:true,act:'<b>Dynamic linking.</b> The code of <code>ls</code> calls <code>printf</code> and <code>opendir</code>, which are inside <code>libc</code>. The loader connects each call to the function in the library.'},
  {t:'execution',file:['code'],mem:['ls','libc','sel'],run:true,act:'<b>Execution.</b> The processor jumps to the start of <code>ls</code>. Its code runs, and calls the functions of the libraries.'},
];
function wLoader(root){
  let i=0;
  root.innerHTML=`<div class="wd ldw"><div class="wd-h"><div><h3>The loader, step by step</h3><p>From the file <code>/bin/ls</code> to a running <code>ls</code>.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ldsteps" data-r="dots"></div>
  <div class="ldgrid"><div class="ldfile" data-r="file"></div><div class="ldmid" data-r="mid"></div><div class="ldmem" data-r="mem"></div></div>
  <div class="wd-f ldx" data-r="x"></div>
  <div class="ldcmd" data-r="cmdw"><pre class="sh" data-r="cmd"></pre></div>
  <div class="ctrls" style="border-top:1px solid var(--line);border-bottom:0;justify-content:space-between"><button type="button" class="btn ghost" data-r="prev">← Back</button><span class="small" data-r="pos" style="align-self:center;margin:0"></span><button type="button" class="btn" data-r="next">Next step →</button></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const FP=[['load','📋 how to load it'],['code','⚙️ the code'],['links','🔗 the libraries it needs']];
  const shcolor=t=>t.split('\n').map(l=>l.startsWith('$ ')?'<span class="p">$</span> <span class="c">'+esc(l.slice(2))+'</span>':'<span class="o">'+esc(l)+'</span>').join('\n');
  function draw(){
    const S=LSTEPS[i], prev=i?LSTEPS[i-1].mem:[];
    q('dots').innerHTML=LSTEPS.map((x,k)=>`<button type="button" class="lddot ${k===i?'on':k<i?'dn':''}" data-k="${k}"><b>${k+1}</b> ${x.t}</button>`).join('');
    q('dots').querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{i=+b.dataset.k;draw()}));
    q('file').innerHTML=`<div class="ldh">📄 /bin/ls <span>the executable, on the disk</span></div>`+FP.map(([k,n])=>`<div class="ldpart ${S.file.includes(k)?'on '+k:''}"><b>${n}</b></div>`).join('');
    q('mid').innerHTML=`<div class="ldloader ${i<4?'on':''}">⚙️ loader</div><div class="ldarrow">${i===0?'exec':i<4?'→':'run'}</div>${S.run?'<div class="ldcpu">🧠 the processor runs ls</div>':''}`;
    q('mem').innerHTML=`<div class="ldh">🧠 the process <span>in memory</span></div>`+(S.mem.length?S.mem.map(k=>{const[n,c]=MEM[k];const nw=!prev.includes(k)&&i>0;
      return `<div class="ldrow ${c} ${nw?'new':''}"><b>${esc(n)}</b>${S.link&&k==='ls'?'<span class="ldgot">printf, opendir → libc.so.6</span>':''}${S.run&&k==='ls'?'<span class="ldip">◀ running</span>':''}</div>`}).join(''):'<div class="ldempty">empty</div>');
    q('x').innerHTML=S.act;
    q('cmdw').hidden=!S.cmd; if(S.cmd)q('cmd').innerHTML=shcolor(S.cmd);
    q('b').textContent=(i+1)+' / '+LSTEPS.length+' · '+S.t;
    q('pos').textContent='step '+(i+1)+' / '+LSTEPS.length;
    q('prev').disabled=i===0; q('next').disabled=i===LSTEPS.length-1;
  }
  q('prev').addEventListener('click',()=>{if(i>0){i--;draw()}});
  q('next').addEventListener('click',()=>{if(i<LSTEPS.length-1){i++;draw()}});
  draw();
}
const W=window.DK_W||(window.DK_W={});
W.states=wStates; W.fork=wFork; W.loader=wLoader;
})();
