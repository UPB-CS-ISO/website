/* ISO lecture 04 widgets: the terminals (data-w="tty"), trap (data-w="trap"), sessions and jobs (data-w="sess"),
   environment variables (data-w="env"), splitting a command line (data-w="split"), what a command receives
   (data-w="argv") and which file runs (data-w="route"). Needs shell-core.js and shell-cli.js (ISOCLI). */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const X=window.ISOCLI;

/* ---------- shared: Back, dots, Next (as in lecture 03) ---------- */
const NAV=()=>`<div class="ps-nav"><button type="button" class="btn ghost" data-r="prev">← Back</button><span class="pdots" data-r="dots" aria-hidden="true"></span><button type="button" class="btn" data-r="next">Next →</button></div>`;
function stepper(root,count,draw){
  let i=0;const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=k=>{i=Math.max(0,Math.min(count()-1,k));draw(i);
    const d=q('dots');if(d)d.innerHTML=Array.from({length:count()},(_,k)=>`<i class="${k===i?'on':k<i?'dn':''}"></i>`).join('');
    q('prev').disabled=i===0;q('next').disabled=i===count()-1};
  q('prev').addEventListener('click',()=>go(i-1));
  q('next').addEventListener('click',()=>go(i+1));
  return go;
}
const chips=(list,cur,lab)=>`<div class="lx-chips">${list.map(k=>`<button type="button" class="chip ${k===cur?'on':''}" data-k="${esc(k)}">${esc(lab(k))}</button>`).join('')}</div>`;
const onChips=(root,cb)=>root.querySelectorAll('.lx-chips .chip').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('.lx-chips .chip').forEach(x=>x.classList.toggle('on',x===b));cb(b.dataset.k)}));

/* bash, highlighted with the hl-* classes */
function bashHL(l){
  const rules=[[String.raw`(?:^|(?<=\s))#.*$`,'c'],[String.raw`"(?:\\.|[^"\\])*"|'[^']*'`,'s'],[String.raw`\$\{?[A-Za-z_?$!#]\w*\}?`,'v'],
    [String.raw`\b(?:function|while|do|done|if|then|else|fi|for|in|true|false)\b`,'k'],[String.raw`\b(?:echo|sleep|trap|export|kill|cd)\b`,'f'],[String.raw`\bSIG[A-Z]+\b|\b\d+\b`,'n']];
  const big=new RegExp(rules.map(([r],i)=>'(?<g'+i+'>'+r+')').join('|'),'g');let out='',pos=0,m;
  while((m=big.exec(l))){if(!m[0]){big.lastIndex++;continue}out+=esc(l.slice(pos,m.index));const i=+Object.keys(m.groups).find(k=>m.groups[k]!==undefined).slice(1);out+='<span class="hl-'+rules[i][1]+'">'+esc(m[0])+'</span>';pos=m.index+m[0].length}
  return out+esc(l.slice(pos));
}
window.ISOBASH=bashHL;
/* a terminal: the first n lines shown (the others keep their space), the lines from `from` marked as new */
function termHTML(lines,n,from,marks){
  return lines.map((l,k)=>{
    let h=l.startsWith('$ ')?'<span class="p">$</span> <span class="c">'+esc(l.slice(2))+'</span>':l.startsWith('#')?'<span class="k">'+esc(l)+'</span>':'<span class="o">'+esc(l)+'</span>';
    for(const[mk,sub]of (marks||[]))if(mk===k)h=h.replace(esc(sub),'<b class="lx-mk">'+esc(sub)+'</b>');
    return `<span class="lx-l${k>=n?' lx-hid':''}${k>=from&&k<n?' lx-new':''}">${h}</span>`}).join('');
}

/* ================================================================ the terminals: text mode, the pseudo terminal */
const BOOT=[
  {t:['[PID 1]  systemd (init)','│     # the first user-space process,','│     # started by the kernel'],scr:'booting …',on:0,x:'The kernel starts one user-space process, <code>systemd</code> (PID 1). It starts everything else.'},
  {t:['[PID 1]  systemd (init)','│     # the first user-space process,','│     # started by the kernel','└── [PID 20+]  agetty tty1','        # waits for a login on /dev/tty1'],scr:'Welcome to tty1\nlogin: _',on:1,x:'<code>agetty</code> opens <code>/dev/tty1</code>, a <b>virtual terminal</b> of the kernel, and asks for a user name.'},
  {t:['[PID 1]  systemd (init)','│     # the first user-space process,','│     # started by the kernel','├── [PID 20+]  agetty tty1','├── [PID 21+]  agetty tty2','├── [PID ...]  ...','└── [PID 25+]  agetty tty6','        # one for every text terminal'],scr:'Welcome to tty1\nlogin: _',on:6,x:'One <code>agetty</code> for every virtual terminal: they share the screen and the keyboard. <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd> … <kbd>F6</kbd> switches between them.'},
  {t:['[PID 1]  systemd (init)','│     # the first user-space process,','│     # started by the kernel','├── [PID 20+]  login student','│     │   # agetty became login (exec)','│     └── [PID 30+]  bash','│             # the shell of student, on /dev/tty1','├── [PID 21+]  agetty tty2','├── [PID ...]  ...','└── [PID 25+]  agetty tty6'],scr:'Welcome to tty1\nlogin: student\nPassword:\n$ _',on:1,sh:true,x:'You log in: <code>agetty</code> <b>becomes</b> <code>login</code> (<code>exec</code>), which checks the password and starts your shell on <code>/dev/tty1</code>.'},
  {t:['[PID 1]  systemd (init)','│     # the first user-space process,','│     # started by the kernel','├── [PID 20+]  login student','│     └── [PID 30+]  bash','├── [PID 21+]  agetty tty2','├── [PID ...]  ...','├── [PID 25+]  agetty tty6','└── [PID 8+]  gdm / sddm / lightdm','        # the graphical login'],scr:'🖼  the graphical login (gdm)',on:2,gui:true,sh:true,x:'The graphical interface is one more program: the display server takes one of the terminals (<code>tty1</code> or <code>tty2</code>) and draws on the screen.'},
];
const PTY=[
  {h:['master','slave','m-p'],x:'<code>foot</code> (the terminal emulator) opens <code>/dev/ptmx</code>: the kernel creates a <b>pseudo terminal</b>, a pair of ends: the <b>master</b>, kept by <code>foot</code>, and the <b>slave</b>, <code>/dev/pts/0</code>.',scr:''},
  {h:['bash','fds','a-fx'],x:'<code>foot</code> starts <code>bash</code> (<code>fork</code> + <code>exec</code>) with <code>0</code>, <code>1</code> and <code>2</code> on the slave, <code>/dev/pts/0</code>. <code>bash</code> only sees a terminal.',scr:'$ _'},
  {h:['kb','a-kf','a-fm'],x:'You type <code>ls</code> and <kbd>Enter</kbd>: <code>foot</code> gets the keys and <b>writes</b> them into the master.',scr:'$ ls'},
  {h:['a-ms','a-sb','bash'],x:'The kernel passes them from the master to the slave: <code>bash</code> reads <code>ls\\n</code> from <code>0</code>, its <code>stdin</code>.',scr:'$ ls'},
  {h:['ls','a-bl','a-ls','a-sm'],x:'<code>bash</code> starts <code>ls</code>, a child with the same <code>0</code>, <code>1</code>, <code>2</code>. <code>ls</code> writes the names to <code>1</code>: into the slave, and the kernel passes them to the master.',scr:'$ ls'},
  {h:['a-mf','screen'],x:'<code>foot</code> <b>reads</b> them from the master and draws the text in its window, with its font and colors. <code>ls</code> has ended, <code>bash</code> writes the next prompt the same way.',scr:'$ ls\nhello  notes.txt  todo.txt\n$ _'},
];
function ptySVG(h,scr){
  const on=k=>h.includes(k);
  const C={blue:['#dae8fc','#6c8ebf'],green:['#d5e8d4','#82b366'],grey:['#eef1f3','#5b6b71'],white:['#fff','#9aa9ae']};
  const box=(k,x,y,w,ht,c,o={})=>`<rect x="${x}" y="${y}" width="${w}" height="${ht}" rx="10" fill="${on(k)?'#ffe6cc':C[c][0]}" stroke="${on(k)?'#d79b00':C[c][1]}" stroke-width="${on(k)?3:2}"${o.dash?' stroke-dasharray="6 5"':''}${o.op?' opacity="'+o.op+'"':''}/>`;
  const T=(x,y,s,o={})=>`<text x="${x}" y="${y}" text-anchor="${o.a||'middle'}" style="font:${o.w||400} ${o.z||15}px ${o.m?"'SF Mono',Menlo,Consolas,monospace":'system-ui,-apple-system,sans-serif'}" fill="${o.f||'#1f2d33'}"${o.op?' opacity="'+o.op+'"':''}>${esc(s)}</text>`;
  const A=(k,pts,lab,lx,ly,a)=>{const c=on(k);return `<polyline points="${pts}" fill="none" stroke="${c?'#e65100':'#9aa9ae'}" stroke-width="${c?3:2}" stroke-linejoin="round" marker-end="url(#x4-${c?'o':'g'})"/>`+(lab?T(lx,ly,lab,{z:13,a:a||'middle',f:c?'#b35900':'#5b6b71',w:c?700:500}):'')};
  const lines=scr.split('\n'), lsOn=on('ls');
  return `<svg class="f3 pty" viewBox="0 0 880 372" style="max-width:880px" role="img" aria-label="the terminal emulator foot, the pseudo terminal of the kernel (master and slave) and the shell bash">
  <defs>${[['o','#e65100'],['g','#9aa9ae']].map(([k,c])=>`<marker id="x4-${k}" viewBox="0 0 10 10" refX="9" refY="5" markerUnits="userSpaceOnUse" markerWidth="11" markerHeight="11" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${c}"/></marker>`).join('')}</defs>
  ${box('screen',20,14,360,178,'grey')}<path d="M30,14 h340 a10,10 0 0 1 10,10 v18 h-360 v-18 a10,10 0 0 1 10,-10 z" fill="${on('screen')?'#d79b00':'#5b6b71'}"/>${T(200,34,'foot · the terminal emulator',{z:14,w:700,f:'#fff'})}
  <rect x="34" y="52" width="332" height="126" rx="6" fill="#1f2d33"/>${lines.map((l,i)=>T(48,78+i*24,l,{a:'start',m:true,z:14,f:l.startsWith('$')?'#7fd1c6':'#e6edf5'})).join('')}
  ${box('bash',470,34,186,82,'green')}${T(563,60,'bash · PID 4100',{w:700})}${T(563,80,'the shell',{z:13,f:'#5b6b71'})}${T(563,103,'0, 1, 2 → /dev/pts/0',{m:true,z:12.5,f:on('fds')?'#b35900':'#5b6b71',w:on('fds')?700:400})}
  ${box('ls',690,34,170,82,'green',lsOn?{}:{dash:true,op:.45})}${T(775,60,'ls · PID 4301',{w:700,op:lsOn?1:.45})}${T(775,80,'a child of bash',{z:13,f:'#5b6b71',op:lsOn?1:.45})}${T(775,103,'the same 0, 1, 2',{m:true,z:12.5,f:'#5b6b71',op:lsOn?1:.45})}
  ${A('a-fx','382,75 466,75','fork + exec',424,64)}
  ${A('a-bl','658,75 686,75','',0,0)}
  <rect x="190" y="212" width="680" height="150" rx="14" fill="#fff6ef" stroke="#f2c49b" stroke-width="1.5"/>${T(856,350,'🐧 the kernel: a pseudo terminal',{a:'end',z:13,w:700,f:'#b35900'})}
  ${on('m-p')?'<rect x="200" y="252" width="650" height="84" rx="12" fill="none" stroke="#e65100" stroke-width="2" stroke-dasharray="7 5"/>':''}
  ${box('master',210,262,200,64,'blue')}${T(310,289,'master',{w:700})}${T(310,310,'/dev/ptmx · kept by foot',{z:12.5,f:'#33555f'})}
  ${box('slave',560,262,280,64,'blue')}${T(700,289,'slave',{w:700})}${T(700,310,'/dev/pts/0 · the terminal of bash',{z:12.5,f:'#33555f'})}
  ${A('a-ms','412,280 556,280','input →',484,272)}
  ${A('a-sm','558,308 414,308','← output',484,324)}
  ${box('kb',20,290,150,46,'white')}${T(95,319,'⌨ keyboard',{z:14})}
  ${A('a-kf','95,288 95,196','keys',103,246,'start')}
  ${A('a-fm','262,194 262,258','writes the keys',254,207,'end')}
  ${A('a-mf','350,260 350,196','reads the output',358,207,'start')}
  ${A('a-sb','600,260 600,120','stdin (0)',592,196,'end')}
  ${A('a-ls','775,120 775,258','stdout (1)',783,196,'start')}
  </svg>`;
}
function wTty(root){
  const sc=root.dataset.sc==='pty'?'pty':'boot';
  const S=sc==='boot'?BOOT:PTY;
  root.innerHTML=`<div class="wd lxw"><div class="wd-h"><div><h3>${sc==='boot'?'Text mode: from the kernel to your shell':'A key, from the keyboard to bash and back'}</h3><p>${sc==='boot'?'Step through the start of the system: the process tree on the left, the screen on the right.':'The terminal emulator and the shell are two programs: they talk through a pseudo terminal.'}</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><span class="lx-cap">${sc==='boot'?'the virtual terminals of the kernel':'foot · /dev/pts/0 · bash'}</span>${NAV()}</div>
  <div class="ps-x" data-r="x"></div><div class="${sc==='boot'?'lx-side':'lx-one'}" data-r="body"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  let prev=[];
  stepper(root,()=>S.length,i=>{
    const st=S[i];q('x').innerHTML=st.x;q('b').textContent='step '+(i+1)+' / '+S.length;
    if(sc==='pty'){q('body').innerHTML=ptySVG(st.h,st.scr);return}
    const old=i?S[i-1].t.map(l=>l.replace(/^[│├└─ ]+/,'')):st.t.map(l=>l.replace(/^[│├└─ ]+/,''));
    const tree=st.t.map(l=>{const n=l.replace(/^[│├└─ ]+/,''),br=l.slice(0,l.length-n.length);const cm=n.startsWith('#');const nw=i&&!old.includes(n)&&!cm;
      return esc(br)+(cm?'<i>'+esc(n)+'</i>':nw?'<b class="nw">'+esc(n)+'</b>':esc(n))}).join('\n');
    const ttys=[1,2,3,4,5,6].map(k=>{const what=i===0?'':k===1?(st.sh?'bash':'agetty'):k===2&&st.gui?'gdm':i>=2||k===1?'agetty':'';
      return `<span class="lx-tty${k===1&&!st.gui||k===2&&st.gui?' on':''}"><b>tty${k}</b>${what?'<i>'+what+'</i>':''}</span>`}).join('');
    q('body').innerHTML=`<pre class="tree lx-tree">${tree}</pre><div><div class="lx-scr${st.gui?' gui':''}"><pre>${esc(st.scr)}</pre></div><div class="lx-ttys">${ttys}</div><p class="lx-k"><kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd> … <kbd>F6</kbd>: a text terminal · <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F1</kbd> or <kbd>F2</kbd>: back to the graphical one</p></div>`;
  })(0);
}

/* ================================================================ trap: a script that handles SIGINT */
const TRAP={
  int:['#!/bin/bash','','# the signal handler','function no_interruptions_please () {','    echo "No interruptions please"','}','','# register the signal handler','trap no_interruptions_please SIGINT','','while true; do','  echo "working"','  sleep 1','done'],
  both:['#!/bin/bash','','# the signal handlers','function no_interruptions_please () {','    echo "No interruptions please"','}','function no_quitting () {','    echo "Quit? No, thank you"','}','','# register the signal handlers','trap no_interruptions_please SIGINT','trap no_quitting SIGQUIT','','while true; do','  echo "working"','  sleep 1','done'],
};
TRAP.none=TRAP.int;
const TRAPM={none:'The <code>trap</code> line is a comment: <code>SIGINT</code> keeps its default action. Press <b>Run</b>.',int:'The script registers a handler for <code>SIGINT</code>. Press <b>Run</b>.',both:'The script registers a handler for <code>SIGINT</code> and one for <code>SIGQUIT</code>. Press <b>Run</b>.'};
function wTrap(root){
  let md='int',timer=null,state='idle',out=[],cur=[],tickN=0,code=null;
  root.innerHTML=`<div class="wd lxw trapw"><div class="wd-h"><div><h3>Run the script, then press Ctrl+C or Ctrl+\\</h3><p>Pick which signals the script traps: a <code>trap</code> runs a handler instead of the default action.</p></div><span class="badge" data-r="b">not started</span></div>
  <div class="ctrls ps-c"><div class="seg" data-seg="t"><button type="button" data-v="none">no trap</button><button type="button" class="on" data-v="int">trap SIGINT</button><button type="button" data-v="both">trap SIGINT + SIGQUIT</button></div>
  <div class="lx-btns"><button type="button" class="btn" data-r="run">▶ Run ./work.sh</button><button type="button" class="btn ghost" data-s="INT">Ctrl+C</button><button type="button" class="btn ghost" data-s="QUIT">Ctrl+\\</button><button type="button" class="btn ghost" data-s="KILL">kill -KILL</button></div></div>
  <div class="ps-x" data-r="x">${TRAPM.int}</div>
  <div class="lx-side"><pre class="sh fkcode lx-code" data-r="code"></pre><div><div class="lx-term"><div class="tbar"><i></i><i></i><i></i><span>student@iso: ~</span></div><pre data-r="out"></pre></div></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const L=()=>TRAP[md], at=t=>L().findIndex(l=>l.includes(t));
  const range=fn=>{const a=at('function '+fn);return[a,a+1,a+2]};
  const code_=()=>{q('code').innerHTML=L().map((l,k)=>{const off=md==='none'&&/^trap /.test(l);return `<span class="${cur.includes(k)?'cur':''}${off?' lx-off':''}">${off?'<span class="hl-c">'+esc('# '+l)+'</span>':bashHL(l)}</span>`}).join('\n')};
  const paint=()=>{code_();const o=q('out');o.innerHTML=out.map(l=>l.startsWith('$ ')?'<span class="p">$</span> '+esc(l.slice(2)):esc(l)).join('\n')+(state==='run'?'':'\n<span class="p">$</span> <span class="lx-cur">_</span>');o.scrollTop=o.scrollHeight;
    const b=q('b');b.textContent=state==='run'?'running · PID 4300':state==='idle'?'not started':'ended · $? = '+code;b.className='badge'+(state==='run'?' ok':state==='idle'?' off':' bad');
    root.querySelectorAll('[data-s]').forEach(x=>x.disabled=state!=='run');q('run').disabled=state==='run';
    root.querySelectorAll('[data-seg="t"] button').forEach(x=>x.disabled=state==='run')};
  const stop=(c,line,x)=>{clearInterval(timer);timer=null;state='end';code=c;cur=[];if(line)out.push(line);q('x').innerHTML=x;paint()};
  const back=()=>setTimeout(()=>{if(state==='run'){cur=[at('echo "working"')];paint()}},800);
  const tick=()=>{tickN++;out.push('working');const e=at('echo "working"');cur=[e];paint();setTimeout(()=>{if(state==='run'&&cur[0]===e){cur=[e+1];paint()}},350)};
  const sleepDied=sig=>'./work.sh: line '+(at('sleep 1')+1)+': '+(4300+tickN)+' '+sig+'  sleep 1';
  q('run').addEventListener('click',()=>{out=['$ ./work.sh'];state='run';code=null;tickN=0;
    q('x').innerHTML='The script runs in the <b>foreground</b>: the loop prints <code>working</code>, then <code>sleep 1</code> waits. Try the keys.';
    tick();timer=setInterval(tick,1000)});
  root.querySelectorAll('[data-s]').forEach(b=>b.addEventListener('click',()=>{
    const s=b.dataset.s;if(state!=='run')return;
    if(s==='INT'&&md!=='none'){out.push('^CNo interruptions please');cur=range('no_interruptions_please');
      q('x').innerHTML='🐧 <code>SIGINT</code> went to the whole foreground group. <code>sleep</code> has no handler: it ends. The script has one: the <b>handler</b> runs, then the loop goes on with the next <code>echo</code>. The script did not stop.';paint();back();return}
    if(s==='INT')return stop(130,'^C','No handler: <code>sleep</code> and the script both get <code>SIGINT</code>, whose <b>default action</b> is <i>Term</i>: both end. Exit code <code>130</code> = 128 + 2 (the number of <code>SIGINT</code>).');
    if(s==='QUIT'&&md==='both'){out.push('^\\'+sleepDied('Quit (core dumped)'));out.push('Quit? No, thank you');cur=range('no_quitting');
      q('x').innerHTML='🐧 <code>SIGQUIT</code> went to the whole foreground group. <code>sleep</code> has no handler: it ends with a core dump, and bash reports it. Then the script runs <b>its handler</b> for <code>SIGQUIT</code>, <code>no_quitting</code>, and the loop goes on. A <code>trap</code> is the only way to make bash <b>react</b> to <code>SIGQUIT</code>.';
      paint();back();return}
    if(s==='QUIT'){out.push('^\\'+sleepDied('Quit (core dumped)'));cur=[at('sleep 1')];
      q('x').innerHTML='🐧 <code>SIGQUIT</code> went to the whole foreground group: the script <b>and</b> its <code>sleep</code>. <code>sleep</code> has the default action, <i>Core</i>: it ends with a core dump. The script is a <code>bash</code>, and bash <b>ignores</b> <code>SIGQUIT</code> unless it has a <code>trap</code> for it: it only reports how its child ended, and the loop goes on. To end the script: <kbd>Ctrl</kbd>+<kbd>C</kbd> without the trap, or <code>kill -KILL</code>.';
      paint();back();return}
    if(s==='KILL'){out.push('Killed');return stop(137,'','<code>SIGKILL</code> from another terminal cannot be caught or ignored: no handler runs, the kernel ends the process. <code>137</code> = 128 + 9.')}
  }));
  root.querySelectorAll('[data-seg="t"] button').forEach(b=>b.addEventListener('click',()=>{if(state==='run')return;root.querySelectorAll('[data-seg="t"] button').forEach(x=>x.classList.toggle('on',x===b));md=b.dataset.v;state='idle';out=[];cur=[];
    q('x').innerHTML=TRAPM[md];paint()}));
  paint();
}

/* ================================================================ sessions, groups, jobs */
const PR=(n,pid,o={})=>Object.assign({n,pid},o);
const GR=(pgid,label,procs,o={})=>Object.assign({pgid,label,procs},o);
const BASH=(lab,o={})=>GR(4100,lab,[PR('bash',4100,Object.assign({sl:true},o.p||{}))],o);
const SES={
  amp:{t:'Start a job',lines:['$ sleep 100 &','[1] 4242','$ sleep 200 &','[2] 4250','$ jobs','[1]-  Running                 sleep 100 &','[2]+  Running                 sleep 200 &','$ kill %1','[1]-  Terminated              sleep 100'],
    steps:[
      {n:2,x:'<code>&amp;</code>: bash starts <code>sleep</code> in a new group and does <b>not</b> wait. <code>[1]</code> is the <b>job ID</b> (only in this shell), <code>4242</code> the <b>PID</b>.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1] · running',[PR('sleep',4242)])]}},
      {n:4,x:'A second job, <code>[2]</code>: both run at the same time, the prompt is back right away.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1] · running',[PR('sleep',4242)]),GR(4250,'job [2] · running',[PR('sleep',4250)])]}},
      {n:7,x:'<code>jobs</code> lists the jobs of <b>this</b> shell: <code>+</code> the current job (the last one), <code>-</code> the previous one.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1]- · running',[PR('sleep',4242)]),GR(4250,'job [2]+ · running',[PR('sleep',4250)])]}},
      {n:9,x:'<code>%1</code> means <i>job 1</i>: <code>kill %1</code> sends <code>SIGTERM</code> to its group. It works with <code>kill</code>, <code>fg</code> and <code>bg</code>; job <code>[2]</code> keeps running.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1] · ended',[PR('sleep',4242,{sub:'❌ Terminated',gone:true,hit:true})],{state:'end',hit:true}),GR(4250,'job [2]+ · running',[PR('sleep',4250)])]}},
    ]},
  ctrlz:{t:'Make a job',lines:['$ sleep 100 > /dev/null','^Z','[1]+  Stopped                 sleep 100 > /dev/null','$ jobs','[1]+  Stopped                 sleep 100 > /dev/null','$ bg %1','[1]+ sleep 100 > /dev/null &','$ jobs','[1]+  Running                 sleep 100 > /dev/null &','$ fg %1','sleep 100 > /dev/null'],
    steps:[
      {n:1,x:'The command runs in the <b>foreground</b>: its group reads the keyboard, bash waits. Its output is redirected: a job still writes to the same terminal.',m:{input:'⌨ input → group 4242',groups:[BASH('waits'),GR(4242,'<b>foreground</b>',[PR('sleep',4242)],{fg:true})]}},
      {n:3,x:'<kbd>Ctrl</kbd>+<kbd>Z</kbd> sends <code>SIGTSTP</code>: the group is <b>stopped</b> and becomes job <code>[1]</code>. bash takes the terminal back. (A program may ignore <code>SIGTSTP</code>.)',m:{sig:'⌨ Ctrl+Z → 🐧 SIGTSTP to group 4242',groups:[BASH('<b>foreground</b> again',{fg:true}),GR(4242,'job [1]+ · stopped',[PR('sleep',4242,{hit:true,sub:'⏸ stopped'})],{state:'stop',hit:true})]}},
      {n:5,x:'<code>jobs</code> shows its job ID: <code>1</code>.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1]+ · stopped',[PR('sleep',4242,{sub:'⏸ stopped'})],{state:'stop'})]}},
      {n:7,x:'<code>bg %1</code> sends <code>SIGCONT</code>: the job runs again, in the <b>background</b>.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1]+ · running',[PR('sleep',4242,{hit:true})],{hit:true})]}},
      {n:9,x:'<code>jobs</code> checks that it still runs.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),GR(4242,'job [1]+ · running',[PR('sleep',4242)])]}},
      {n:11,x:'<code>fg %1</code> brings it back to the <b>foreground</b>: it gets the keyboard, bash waits for it again.',m:{input:'⌨ input → group 4242',groups:[BASH('waits'),GR(4242,'<b>foreground</b>',[PR('sleep',4242,{hit:true})],{fg:true,hit:true})]}},
    ]},
  session:{t:'Sessions and the terminal',lines:['$ echo $$','4100','$ sleep 100 | cat &','[1] 4243','$ nohup sleep 200 > /dev/null &','[2] 4244','nohup: ignoring input','$ ps -o pid,pgid,sid,stat,comm','    PID    PGID     SID STAT COMMAND','   4100    4100    4100 Ss   bash','   4242    4242    4100 S    sleep','   4243    4242    4100 S    cat','   4244    4244    4100 S    sleep','   4250    4250    4100 R+   ps'],
    steps:(()=>{const J1=(o={})=>GR(4242,'job [1]',[PR('sleep',4242,o.a||{}),PR('cat',4243,o.b||{})],o.g||{}),J2=(o={})=>GR(4244,'job [2]',[PR('sleep',4244,Object.assign({nohup:true},o.a||{}))],o.g||{});
      return[
      {n:2,x:'👑 The shell started a new <b>session</b>; a session has <b>one</b> controlling terminal, <code>/dev/pts/0</code>. ⌨ The input goes to the <b>foreground</b> group, now <code>bash</code> (<code>$$</code> is its PID).',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true})]}},
      {n:4,x:'A <b>process group</b> is one job: <code>sleep 100 | cat</code> is <b>one</b> group of two processes. A signal from a key reaches the whole group.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),J1()]}},
      {n:7,x:'🛡 <code>nohup</code> makes the program <b>ignore</b> <code>SIGHUP</code>: a shield for when the terminal closes.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true}),J1(),J2()]}},
      {n:14,mk:[[13,'R+']],x:'A <b>session</b>: all the groups of one terminal, the same <code>SID</code>. Only the <b>foreground</b> group reads the input: <code>+</code> in <code>STAT</code>. A background job that reads gets <code>SIGTTIN</code> and is stopped.',m:{input:'⌨ input → group 4250 (ps)',groups:[BASH('waits'),J1(),J2(),GR(4250,'<b>foreground</b>',[PR('ps',4250)],{fg:true})]}},
      {n:14,mk:[[9,'Ss']],x:'⭐ The <b>group leader</b>: its PID is the <code>PGID</code>. 👑 The <b>session leader</b>: the process that started the session, its PID is the <code>SID</code>, <code>s</code> in <code>STAT</code>.',m:{legend:true,input:'⌨ input → group 4250 (ps)',groups:[BASH('waits'),J1(),J2(),GR(4250,'<b>foreground</b>',[PR('ps',4250)],{fg:true})]}},
      {n:14,x:'🐧 You close the window: the <b>terminal driver</b> sends <code>SIGHUP</code> to the session leader, <code>bash</code>. <code>bash</code> sends it to its jobs: ❌ job <code>[1]</code> ends, 🛡 job <code>[2]</code> ignores it and keeps running.',
        m:{term:{state:'closed',text:'closed'},sig:'🐧 SIGHUP → bash (the session leader)',groups:[BASH('forwards SIGHUP to its jobs',{hit:true,p:{sub:'❌ ends'}}),J1({a:{sub:'❌ SIGHUP',gone:true,hit:true},b:{sub:'❌ ended',gone:true},g:{state:'end',hit:true,note:'ended'}}),J2({a:{sub:'✅ runs'},g:{note:'✋ ignores SIGHUP'}})]}},
      ]})()},
  kill:{t:'When bash is killed',lines:['$ sleep 100 | cat &','[1] 4243','$ nohup sleep 200 > /dev/null &','[2] 4244','nohup: ignoring input','# in another terminal, /dev/pts/1:','$ kill -KILL 4100','$ ps -o pid,ppid,sid,tty,comm -s 4100','    PID    PPID     SID TT       COMMAND','   4242       1    4100 ?        sleep','   4243       1    4100 ?        cat','   4244       1    4100 ?        sleep'],
    steps:(()=>{const J=(t,o={})=>[GR(4242,'job [1]',[PR('sleep',4242,{sub:t}),PR('cat',4243,{sub:t})]),GR(4244,'job [2]',[PR('sleep',4244,{nohup:true,sub:t})])];
      return[
      {n:5,x:'Two jobs in the session of <code>bash</code>, as before.',m:{input:'⌨ input → bash',groups:[BASH('<b>foreground</b>',{fg:true})].concat(J())}},
      {n:7,x:'💀 <code>SIGKILL</code> cannot be caught: <code>bash</code> ends at once, it cannot forward anything. 🐧 The session leader ended: the kernel <b>detaches</b> the terminal from the session.',m:{term:{state:'detached',text:'no session'},groups:[BASH('killed',{state:'killed',hit:true,p:{sub:'💀 killed',gone:true,hit:true}})].concat(J())}},
      {n:12,x:'The jobs keep running: no controlling terminal (<code>TT</code> is <code>?</code>), their new parent is PID 1, <code>systemd</code>.',m:{term:{state:'detached',text:'no session'},groups:[BASH('killed',{state:'killed',p:{sub:'💀 killed',gone:true}})].concat(J('PPID 1 · TT ?'))}},
      {n:12,x:'🔌 The window closes: no <code>SIGHUP</code> reaches the jobs, they keep running in the background. <code>kill -KILL</code> on a shell leaves its jobs behind.',m:{term:{state:'closed',text:'closed'},groups:[BASH('killed',{state:'killed',p:{sub:'💀 killed',gone:true}})].concat(J('✅ runs'))}},
      ]})()},
  keys:{t:'Ctrl+C, Ctrl+\\ and Ctrl+Z',lines:['$ sleep 100 | cat','^C','$ sleep 200 | cat','^\\Quit (core dumped)','$ sleep 300 | cat','^Z','[1]+  Stopped                 sleep 300 | cat'],
    steps:(()=>{const J=(g,lab,o={})=>GR(g,lab,[PR('sleep',g,o.p||{}),PR('cat',g+1,o.p||{})],o.g||{});
      return[
      {n:1,x:'⌨ <code>sleep 100 | cat</code> is the <b>foreground</b> group: it gets the input, <code>bash</code> waits for it.',m:{input:'⌨ input → group 4300',groups:[BASH('waits'),J(4300,'<b>foreground</b>',{g:{fg:true}})]}},
      {n:2,x:'🐧 The terminal driver turns <kbd>Ctrl</kbd>+<kbd>C</kbd> (the character <code>^C</code>) into <code>SIGINT</code> for <b>every</b> process of the foreground group: <code>sleep</code> and <code>cat</code> end, <code>bash</code> shows the prompt.',m:{sig:'⌨ Ctrl+C → 🐧 SIGINT to the whole group 4300',groups:[BASH('<b>foreground</b> again',{fg:true}),J(4300,'ended',{p:{sub:'❌ ended',hit:true,gone:true},g:{state:'end',hit:true}})]}},
      {n:3,x:'A new foreground job, a new group.',m:{input:'⌨ input → group 4310',groups:[BASH('waits'),J(4310,'<b>foreground</b>',{g:{fg:true}})]}},
      {n:4,x:'<kbd>Ctrl</kbd>+<kbd>\\</kbd> becomes <code>SIGQUIT</code>: the whole group ends, like with <kbd>Ctrl</kbd>+<kbd>C</kbd>, and writes a <b>core dump</b> (a copy of the memory, for debugging) if <code>ulimit -c</code> allows it.',m:{sig:'⌨ Ctrl+\\ → 🐧 SIGQUIT to the whole group 4310',groups:[BASH('<b>foreground</b> again',{fg:true}),J(4310,'ended',{p:{sub:'❌ core dumped',hit:true,gone:true},g:{state:'end',hit:true}})]}},
      {n:5,x:'One more foreground job.',m:{input:'⌨ input → group 4320',groups:[BASH('waits'),J(4320,'<b>foreground</b>',{g:{fg:true}})]}},
      {n:7,x:'<kbd>Ctrl</kbd>+<kbd>Z</kbd> becomes <code>SIGTSTP</code>: the group is <b>stopped</b>, not ended. <code>bash</code> takes the terminal back; the group is now job <code>[1]</code>, <code>fg</code> continues it.',m:{sig:'⌨ Ctrl+Z → 🐧 SIGTSTP to the whole group 4320',groups:[BASH('<b>foreground</b> again',{fg:true}),J(4320,'job [1]+ · stopped',{p:{sub:'⏸ stopped',hit:true},g:{state:'stop',hit:true}})]}},
      ]})()},
};
function wSess(root){
  const sc=SES[root.dataset.sc]?root.dataset.sc:'session', S=SES[sc];
  root.innerHTML=`<div class="wd lxw sessw"><div class="wd-h"><div><h3>${esc(S.t)}, step by step</h3><p>The terminal on the left; on the right the session of the terminal, its process groups and the processes inside them.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><span class="lx-cap">bash · PID 4100 · on /dev/pts/0</span>${NAV()}</div>
  <div class="ps-x" data-r="x"></div><div class="lx-side lx-ses"><pre class="sh lx-t" data-r="t"></pre><div data-r="m"></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  stepper(root,()=>S.steps.length,i=>{const st=S.steps[i],from=i?S.steps[i-1].n:0;
    q('t').innerHTML=termHTML(S.lines,st.n,from===st.n?st.n:from,st.mk);q('x').innerHTML=st.x;q('b').textContent='step '+(i+1)+' / '+S.steps.length;
    q('m').innerHTML=X.sess(Object.assign({sid:4100},st.m))})(0);
}

/* ================================================================ environment variables */
const ENV0=[['HOME','/home/student'],['USER','student'],['SHELL','/bin/bash'],['PATH','/usr/local/bin:/usr/bin:/bin'],['LANG','en_US.UTF-8'],['PWD','/home/student']];
const vtab=(title,rows)=>`<div class="cx-vt"><div class="fdh">${title}</div><table class="cx-t">${rows.map(([n,v,s])=>`<tr class="${s==='new'?'ch':s==='shell'?'sv':s==='hide'?'lx-hid':''}"><td>${esc(n)}</td><td>${esc(v)}</td><td>${s==='shell'?'<span class="cx-tag sh">shell only</span>':s==='hide'?'':'<span class="cx-tag env">environment</span>'}</td></tr>`).join('')}</table></div>`;
const EXP_LINES=['$ GREETING=hello','$ echo $GREETING','hello',"$ bash -c 'echo \"child: $GREETING\"'",'child:','$ export GREETING',"$ bash -c 'echo \"child: $GREETING\"'",'child: hello'];
const EXP=[
  {n:1,g:'shell',kid:false,x:'<code>NAME=value</code> makes a <b>shell variable</b>: it exists only inside this shell.'},
  {n:3,g:'shell',kid:false,x:'<code>$GREETING</code> is replaced by its value by the shell, before <code>echo</code> starts.'},
  {n:5,g:'shell',kid:'',x:'The child, a new <code>bash</code> started with <code>-c</code>, does <b>not</b> get it: it is not part of the environment. Single quotes: your shell does not replace <code>$GREETING</code>, the child does, with <b>its own</b> variables.'},
  {n:6,g:'new',kid:false,x:'<code>export</code> marks it as an <b>environment variable</b>.'},
  {n:8,g:'env',kid:'hello',x:'Every child started from now on gets a copy. <code>export NAME=value</code> does both at once, <code>unset NAME</code> deletes it.'},
];
const INH=[
  {x:'<code>bash</code> has its own environment, like every process: a list of <code>NAME=value</code> texts.',kid:null},
  {x:'The shell starts <code>sort</code> (<code>fork</code> + <code>exec</code>): the child gets a <b>copy</b> of all the environment variables.',kid:ENV0.map(([n,v])=>[n,v,'new'])},
  {x:'The child changes <b>its own copy</b> (<code>setenv("PATH", "/tmp")</code> in C, <code>PATH=/tmp</code> in bash): the parent does not see it. A process passes variables <b>down</b> to its children, never <b>up</b>.',kid:ENV0.map(([n,v])=>n==='PATH'?[n,'/tmp','new']:[n,v,'env'])},
];
function wEnv(root){
  const sc=root.dataset.sc==='inherit'?'inherit':'export';
  root.innerHTML=`<div class="wd lxw envw"><div class="wd-h"><div><h3>${sc==='export'?'export: who gets the variable':'Inherited by the children'}</h3><p>${sc==='export'?'The commands on the left; the variables of your shell and of its child on the right.':'The environment of bash and the copy its child gets.'}</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><span class="lx-cap">${sc==='export'?'GREETING: a shell variable, then an environment variable':'fork + exec copies the environment'}</span>${NAV()}</div>
  <div class="ps-x" data-r="x"></div><div class="${sc==='export'?'lx-side':'lx-inh'}" data-r="body"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const S=sc==='export'?EXP:INH;
  stepper(root,()=>S.length,i=>{const st=S[i];q('x').innerHTML=st.x;q('b').textContent='step '+(i+1)+' / '+S.length;
    if(sc==='inherit'){
      q('body').innerHTML=vtab('<b>bash</b> · PID 4100 · environment',ENV0.map(([n,v])=>[n,v,'env']))+`<div class="lx-arr${st.kid?'':' lx-hid'}"><code>fork + exec</code><span>→</span></div>`+(st.kid?vtab('<b>sort</b> · PID 4301 · environment (a copy)',st.kid):'<div class="lx-ph">no child yet</div>');return}
    const from=i?S[i-1].n:0;
    const kid=st.kid!==false;
    q('body').innerHTML=`<pre class="sh lx-t">${termHTML(EXP_LINES,st.n,from)}</pre><div>${vtab('<b>bash</b> · PID 4100 · your shell',[['HOME','/home/student','env'],['GREETING','hello',st.g]])}
      <div class="lx-down${kid?'':' lx-hid'}"><div><code>fork + exec</code>: a new <code>bash</code>, with <b>3 parameters</b>:</div><div class="lx-argv"><span><span class="lx-w cmd">bash</span><i>argv[0]</i></span><span><span class="lx-w">-c</span><i>argv[1]</i></span><span><span class="lx-w">echo "child: $GREETING"</span><i>argv[2]: one word, the text to run</i></span></div></div>
      <div class="${kid?'':'lx-hid'}">${vtab('<b>bash -c</b> · PID 4302 · the child (a copy)',[['HOME','/home/student','env']].concat(st.kid==='hello'?[['GREETING','hello','new']]:[]))}
      <div class="lx-outl">its <code>echo</code> writes: <span class="lx-o">child: ${esc(st.kid||'')}</span> → 🖥 display</div></div></div>`;
  })(0);
}

/* ================================================================ splitting a command line */
const VARS={HOME:'/home/student',USER:'student',IN:'my notes.txt',OUT:'sorted.txt',OPTS:'-u -f',NAME:'Alice   Smith'};
let FSH=null;
const fsh=()=>FSH||(FSH=new ISOSH.Shell({profile:'04'}));
const ctx=(vars)=>{const sh=fsh(),c=X.fsCtx(sh,n=>n==='?'?'0':n==='$'?'4100':vars[n]);c.globstar=true;return c};
const SPL={
  ex1:{line:'LANG=C sort -r "$HOME/my notes.txt" my\\ list.txt *.csv > sorted.txt 2> errors.txt',
    notes:['Split at the spaces, except inside quotes and after a <code>\\</code>; <code>&gt;</code> and <code>2&gt;</code> are words of their own: <b>10 words</b>.',
      'The assignment (no spaces around <code>=</code>) and the redirects (<code>&gt;</code> or <code>2&gt;</code> + the next word) are <b>set apart</b>: they are for the shell, not for <code>sort</code>.',
      '<code>$HOME</code> is replaced inside <code>"..."</code> (not inside <code>\'...\'</code>); the result stays <b>one</b> word.',
      'Nothing to split: <code>$HOME</code> was inside double quotes.',
      '<code>*.csv</code> is not quoted: the shell replaces it with the matching file names.',
      'The quotes and the <code>\\</code> did their job: the shell <b>removes</b> them.',
      'The shell sets up the redirects (it creates <code>sorted.txt</code>), then starts <code>sort</code> with <b>5 parameters</b> and <code>LANG=C</code> in its environment.']},
  ex2:{line:'LANG=C 2> errors.txt sort "$IN" \'$IN\' > "$OUT" -r $OPTS -t \',\' *.csv',pre:'IN="my notes.txt" OUT=sorted.txt OPTS="-u -f"',
    notes:['<b>13 words</b>; a redirect is even <b>before</b> the command. (The line before set <code>IN</code>, <code>OUT</code> and <code>OPTS</code>.)',
      'The assignment (at the start) and the 2 redirects are set apart; <code>&gt; "$OUT"</code> was in the <b>middle</b>.',
      '<code>$IN</code> is replaced inside <code>"..."</code>, but <b>not</b> inside <code>\'...\'</code>; <code>$OPTS</code> and <code>$OUT</code> are replaced too.',
      '<code>$OPTS</code> was not quoted: it becomes <b>2 words</b>; <code>"$IN"</code> was quoted: <code>my notes.txt</code> stays one word.',
      '<code>*.csv</code> is not quoted: the files of the current directory, <code>a.csv</code> and <code>b.csv</code>.',
      'The quotes did their job: the shell removes them, <code>\'$IN\'</code> becomes the text <code>$IN</code>.',
      '<code>sort</code> gets a file named <code>$IN</code>: it does not exist, the error goes to <code>errors.txt</code>.']},
};
const STEPN=['split into words','set apart','replace {a,b} ~ $NAME','split the results','expand the globs','remove quotes, \\','run'];
const wbox=(t,k)=>`<span class="lx-w${k?' '+k:''}">${t===''?'<i>(empty)</i>':esc(t)}</span>`;
function autoNotes(A){
  const n=[],code=s=>'<code>'+esc(s)+'</code>';
  n.push('Split at the spaces, except inside quotes and after a <code>\\</code>: <b>'+A.st1.length+' word'+(A.st1.length>1?'s':'')+'</b>.');
  n.push(A.asg.length||A.red.length?'Set apart: '+[A.asg.length?A.asg.length+' assignment'+(A.asg.length>1?'s':'')+' (only for this command)':'',A.red.length?A.red.length+' redirect'+(A.red.length>1?'s':'')+' (for the shell)':''].filter(Boolean).join(' and ')+'.':'Nothing to set apart: no <code>NAME=value</code> at the start, no redirect.');
  const xs=[];A.s3.forEach(w=>w.pcs.forEach(p=>{if(p.x)xs.push(code(p.src)+' → '+(p.s?code(p.s):'<i>nothing</i>'))}));
  const br=A.s3.filter(w=>w.pcs.some(p=>p.br)).length;
  n.push(xs.length||br?(br?'Braces made '+br+' words. ':'')+(xs.length?[...new Set(xs)].join(', ')+'.':''):'Nothing to replace: no <code>$NAME</code>, <code>~</code> or <code>{a,b}</code> outside single quotes.');
  const sp=A.s4.filter(w=>w.nw).length, gone=A.s4.filter(w=>w.gone).length;
  n.push(sp||gone?(sp?'The results of unquoted <code>$NAME</code> are split at the spaces: '+sp+' words. ':'')+(gone?gone+' word'+(gone>1?'s were':' was')+' empty and unquoted: gone.':''):'Nothing to split: every replaced value was quoted, or had no spaces.');
  const gl=A.s5.filter(w=>w.gl).length,nm=A.s5.filter(w=>w.nomatch).map(w=>code(w.w));
  n.push(gl?'The unquoted patterns became '+gl+' file name'+(gl>1?'s':'')+'.'+(nm.length?' '+nm.join(', ')+' matched nothing: kept as it is.':''):nm.length?nm.join(', ')+' matched nothing: bash keeps it as it is (zsh would stop with an error).':'Nothing to expand: no unquoted <code>*</code>, <code>?</code> or <code>[...]</code>.');
  const rq=A.s6.filter(w=>w.nw).length;
  n.push(rq?'The quotes and the <code>\\</code> did their job: removed.':'No quotes to remove.');
  const c=A.argv[0];
  n.push(c==null?'No command: only the assignments and the redirects, for the shell itself.':'The shell starts '+code(c)+' with <b>'+(A.argv.length-1)+' parameter'+(A.argv.length===2?'':'s')+'</b>'+(A.asg.length?', '+A.asg.map(a=>code(a.name+'='+a.value)).join(' ')+' only in its environment':'')+'.');
  return n;
}
function wSplit(root){
  let sc='ex1',own='echo "$USER: $HOME" ~/docs/*.txt';
  const list=(root.dataset.list||'ex1,ex2,own').split(',');
  const lab={ex1:'example 1',ex2:'example 2',own:'your line'};
  root.innerHTML=`<div class="wd lxw splitw"><div class="wd-h"><div><h3>What the shell does with a line</h3><p>Step through the work the shell does before the command starts. Every row is one step; orange is what changed.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c">${chips(list,sc,k=>lab[k])}${NAV()}</div>
  <div class="lx-in" data-r="own" hidden><span class="p">$</span><input data-r="inp" spellcheck="false" autocomplete="off" aria-label="a command line"><span class="lx-vars">IN, OUT, OPTS, NAME are set</span></div>
  <pre class="sh lx-line" data-r="line"></pre>
  <div class="ps-x" data-r="x"></div><div class="lx-rows" data-r="rows"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  let A=null,notes=[];
  const build=()=>{
    const line=sc==='own'?own:SPL[sc].line;
    q('line').innerHTML=(sc==='ex2'?'<span class="p">$</span> <span class="c">'+esc(SPL.ex2.pre)+'</span>\n':'')+(sc==='own'?'':'<span class="p">$</span> <span class="c">'+esc(line)+'</span>');
    q('line').hidden=sc==='own';q('own').hidden=sc!=='own';
    A=X.analyze(line,ctx(VARS));
    if(A.err){notes=[];return}
    notes=sc==='own'?autoNotes(A):SPL[sc].notes;
  };
  const go=stepper(root,()=>A&&!A.err?7:1,i=>{
    q('b').textContent=A&&!A.err?'step '+(i+1)+' / 7':'';
    if(!A||A.err){q('rows').innerHTML='';q('x').innerHTML=A&&A.err==='empty'?'Type a command line.':A&&A.open?'The '+esc(A.open)+' is not closed: a real bash would show <code>&gt;</code> and wait for the rest of the line.':'bash: '+esc(A?A.err:'');return}
    q('x').innerHTML=notes[i]+(A.more&&i===0?' <i>(only the first command is shown, up to <code>'+esc(A.more)+'</code>)</i>':'');
    const rd=(r,k)=>wbox(r,k);
    const rows=[
      [A.st1.map(w=>wbox(w.w)).join(''),''],
      [A.st2.map((w,k)=>wbox(w.w,k===0?'cmd0':'')).join(''),A.asg.map(a=>wbox(a.raw,'asg')).join('')+A.red.map(r=>rd(r.raw,'rd')).join('')],
      [A.s3.map((w,k)=>wbox(w.w,w.nw?'nw':'')).join(''),A.red.filter(r=>r.changed).map(r=>rd(r.rawX,'rd nw')).join('')],
      [A.s4.filter(w=>!w.gone).map(w=>wbox(w.w,w.nw?'nw':'')).join('')+A.s4.filter(w=>w.gone).map(w=>wbox(w.from,'gone')).join(''),''],
      [A.s5.map(w=>wbox(w.w,w.gl?'nw':w.nomatch?'nm':'')).join(''),''],
      [A.s6.map(w=>wbox(w.w,w.nw?'nw':'')).join(''),A.red.filter(r=>r.raw!==r.op+' '+r.to&&r.to!=null).map(r=>rd(r.op+' '+r.to,'rd nw')).join('')],
      [A.argv.map((w,k)=>wbox(w,k===0?'cmd':'')).join(''),'<span class="lx-fin">'+(A.asg.map(a=>esc(a.name+'='+a.value)+' only for '+esc(A.argv[0]||'the shell')).concat(A.red.map(r=>r.op==='2>&1'?'2 → where 1 points':(/^(<|0<)$/.test(r.op)?'0':/^2/.test(r.op)?'2':/^&/.test(r.op)?'1, 2':'1')+' → '+esc(r.to))).join('<br>')||'no redirects: 0, 1, 2 → the terminal')+'</span>'],
    ];
    q('rows').innerHTML=rows.map(([w,a],k)=>`<div class="lx-row${k>i?' lx-hid':''}${k===i?' now':''}"><span class="lx-rl">${k+1}. ${esc(STEPN[k])}</span><span class="lx-rw">${w}</span><span class="lx-ra">${a}</span></div>`).join('');
  });
  onChips(root,k=>{sc=k;build();go(sc==='own'?6:0);if(sc==='own')q('inp').focus({preventScroll:true})});
  q('inp').value=own;q('inp').addEventListener('input',e=>{own=e.target.value;build();go(6)});
  build();go(0);
}

/* ================================================================ what the command receives */
const ARGV={
  quote:{ctx:'NAME="Alice   Smith"',rows:[
    ['echo $NAME','no quotes: replaced, then split at the spaces'],['echo "$NAME"','double quotes: replaced, <b>one</b> word, the spaces kept'],
    ["echo '$NAME'",'single quotes: <b>nothing</b> is replaced'],['echo \\$NAME','<code>\\$</code>: the <code>$</code> is just a character'],
    ['echo my\\ file.txt','<code>\\ </code>: the space does not split'],['echo "\\$NAME is $NAME"','inside <code>"..."</code>, <code>\\$</code> is a <code>$</code>, <code>$NAME</code> is replaced'],
    ['echo "it\'s" \'say "hi"\'','each kind of quotes protects the other one'],["echo 'a\\b'",'inside <code>\'...\'</code>, <code>\\</code> is just a character']]},
  glob:{ctx:'',rows:[
    ['echo *.txt','<code>*</code>: any characters, or none; a name with a space stays <b>one</b> word'],['echo photo?.png','<code>?</code>: exactly one character'],
    ['echo photo[12].png','<code>[12]</code>: one of these characters'],['echo photo[0-9].png','<code>[0-9]</code>: one in the range'],
    ['echo photo[!0-9].png','<code>[!0-9]</code>: one <b>not</b> in it'],['echo docs/**/*.txt','<code>**</code>: any directories (<code>shopt -s globstar</code>)'],
    ['echo {a,b,c}.pdf','<code>{ }</code>: a word for each, file or not'],['echo *.pdf','no match: kept as it is (<code>bash</code>), an error (<code>zsh</code>)']]},
};
function wArgv(root){
  const md=root.dataset.sc==='glob'?'glob':'quote',D=ARGV[md];let cur=D.rows[0][0];
  const sh=fsh(),ls=sh.run('ls').seq.map(x=>(x.out||'').replace(/[\u0001-\u0007]/g,'')).join('');
  root.innerHTML=`<div class="wd lxw argvw"><div class="wd-h"><div><h3>${md==='quote'?'What does echo receive?':'Which files does the pattern match?'}</h3><p>Pick a line or type your own: the boxes are the words the command receives, after the shell is done.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c lx-ac">${chips(D.rows.map(r=>r[0]),cur,k=>k)}</div>
  <div class="lx-ab">${md==='quote'?'<pre class="sh lx-line"><span class="p">$</span> <span class="c">NAME="Alice   Smith"</span></pre>':'<pre class="sh lx-line"><span class="p">$</span> <span class="c">ls</span>\n<span class="o">'+esc(ls)+'</span></pre>'}
  <div class="lx-in"><span class="p">$</span><input data-r="inp" spellcheck="false" autocomplete="off" aria-label="a command line"></div>
  <div class="lx-got"><span class="lx-cap">the command and its parameters</span><div data-r="w"></div></div><p class="lx-why" data-r="why"></p></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const draw=()=>{const A=X.analyze(cur,ctx(VARS));const row=D.rows.find(r=>r[0]===cur);
    if(A.err){q('w').innerHTML='<span class="lx-err">'+(A.open?'the '+esc(A.open)+' is not closed: bash would wait for the rest (it shows <code>&gt;</code>)':esc(A.err==='empty'?'type a command':'bash: '+A.err))+'</span>';q('why').innerHTML='';q('b').textContent='';return}
    q('w').innerHTML=A.argv.map((w,k)=>wbox(w,k===0?'cmd':'nw')).join('')||'<i>no command</i>';
    q('b').textContent=(A.argv.length-1)+' parameter'+(A.argv.length===2?'':'s');
    q('why').innerHTML=row?'💡 '+row[1]:'💡 '+autoNotes(A).filter((n,k)=>k===2||k===4).join(' ')};
  onChips(root,k=>{cur=k;q('inp').value=k;draw()});
  q('inp').value=cur;q('inp').addEventListener('input',e=>{cur=e.target.value;root.querySelectorAll('.lx-chips .chip').forEach(x=>x.classList.toggle('on',x.dataset.k===cur));draw()});
  draw();
}

/* ================================================================ which file runs? */
const RT=[
  {c:'/usr/bin/sort fruits.txt',o:'apple\nbanana\nCherry\nDate'},{c:'./hello',o:'Hello!'},{c:'../tools/hello',o:'Hello from tools!'},
  {c:'cd /tmp',o:''},{c:'sort fruits.txt',o:'apple\nbanana\nCherry\nDate'},{c:'hello',o:'bash: hello: command not found'},
];
const PATHD=['/home/student/.local/bin','/usr/local/bin','/usr/bin','/bin'];
function routeSteps(cmd){
  const name=(cmd.trim().split(/\s+/)[0]||'');if(!name)return null;
  const sh=fsh(),C=X.cli(sh);const s=[{at:'cmd',x:'The shell looks at the first word: <code>'+esc(name)+'</code>. Which file does it start?'}];
  if(name.startsWith('/')){s.push({at:'q1',yes:true,x:'It starts with <code>/</code>: an <b>absolute path</b>, used as it is, no search.'});s.push({at:'abs',file:name,x:'✅ <code>exec</code> starts <code>'+esc(name)+'</code>.'});return s}
  s.push({at:'q1',x:'Does it start with <code>/</code>? No.'});
  if(name.includes('/')){const f='/'+ISOSH.split(sh.cwd,name).join('/');s.push({at:'q2',yes:true,x:'It contains a <code>/</code>: a <b>relative path</b>, from the current directory <code>/home/student</code>.'});s.push({at:'rel',file:f,x:'✅ <code>/home/student</code> + <code>'+esc(name)+'</code> → <code>'+esc(f)+'</code>.'});return s}
  s.push({at:'q2',x:'Does it contain a <code>/</code>? No: it is just a <b>name</b>.'});
  if(['cd','echo','pwd','export','unset','jobs','fg','bg','kill','type','exit','alias','trap','history','true','false'].includes(name)||C.alias[name]){s.push({at:'q3',yes:true,x:'<code>'+esc(name)+'</code> is '+(C.alias[name]?'an <b>alias</b>':'a <b>builtin</b>')+' of the shell.'});s.push({at:'builtin',x:'✅ The shell runs it <b>itself</b>: no new process, no file.'});return s}
  s.push({at:'q3',x:'Is it a builtin (or an alias, a function)? No: it must be a <b>file</b>.'});
  s.push({at:'path',k:-1,x:'<code>PATH</code> is an environment variable: a list of directories separated by <code>:</code>. The shell checks them <b>from left to right</b>.'});
  for(let k=0;k<PATHD.length;k++){const p=PATHD[k]+'/'+name,ok=!!ISOSH.lookup(sh.root,ISOSH.split(sh.cwd,p)).node;
    s.push({at:'path',k,ok,x:ok?'<code>'+esc(p)+'</code> exists: the search <b>stops</b>, the first match wins'+(k<PATHD.length-1?' (<code>'+PATHD.slice(k+1).join('</code>, <code>')+'</code> are never checked)':'')+'.':'No <code>'+esc(name)+'</code> in <code>'+esc(PATHD[k])+'</code>.'});
    if(ok){s.push({at:'found',k,file:p,x:'✅ The shell starts <code>'+esc(p)+'</code>.'});return s}}
  s.push({at:'missing',k:PATHD.length,x:'❌ Not in any directory of <code>PATH</code>: <b>command not found</b>. The shell does <b>not</b> look in the current directory.'});
  return s;
}
function wRoute(root){
  let cur=RT[0].c,S=routeSteps(cur);
  root.innerHTML=`<div class="wd lxw routew"><div class="wd-h"><div><h3>Which file does the shell start?</h3><p>Pick a command (the current directory is <code>/home/student</code>) and step through the questions the shell asks.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c">${chips(RT.map(r=>r.c).concat(['your own']),cur,k=>k.split(' ')[0])}${NAV()}</div>
  <div class="lx-in" data-r="own" hidden><span class="p">$</span><input data-r="inp" spellcheck="false" autocomplete="off" aria-label="a command" value="ls"></div>
  <div class="ps-x" data-r="x"></div><div class="rt" data-r="c"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const ORD=['cmd','q1','q2','q3','path'];
  const go=stepper(root,()=>S?S.length:1,i=>{
    if(!S){q('c').innerHTML='';q('x').innerHTML='Type a command.';q('b').textContent='';return}
    const st=S[i],seen=S.slice(0,i+1);q('x').innerHTML=st.x;q('b').textContent='step '+(i+1)+' / '+S.length;
    const was=a=>seen.some(x=>x.at===a), now=a=>st.at===a, yes=a=>seen.some(x=>x.at===a&&x.yes);
    const name=S[0].x.match(/<code>(.*?)<\/code>/)[1];
    const cls=a=>now(a)?' now':was(a)?' dn':'';
    const end=(a,t,f)=>`<div class="rt-e${now(a)?' now':was(a)?' dn':''}">${t}${f?`<code class="${now(a)||was(a)?'':'lx-hid'}">${esc(f)}</code>`:''}</div>`;
    const fileOf=a=>{const z=S.find(x=>x.at===a);return z&&z.file};
    const q3yes=yes('q3');
    q('c').innerHTML=`<div class="rt-flow">
      <div class="rt-col"><div class="rt-b cmd${cls('cmd')}">${name}</div></div>
      <div class="rt-col"><div class="rt-q${cls('q1')}">starts with <code>/</code>?</div><div class="rt-y${yes('q1')?' on':''}">yes ↓</div>${end('abs','<b>absolute path</b><br>used as it is',fileOf('abs')||'/usr/bin/sort')}</div>
      <div class="rt-col"><div class="rt-q${cls('q2')}">contains a <code>/</code>?</div><div class="rt-y${yes('q2')?' on':''}">yes ↓</div>${end('rel','<b>relative path</b><br>+ the current directory',fileOf('rel')||'/home/student/hello')}</div>
      <div class="rt-col"><div class="rt-q${cls('q3')}">a builtin?</div><div class="rt-y${q3yes?' on':''}">yes ↓</div>${end('builtin','<b>builtin</b><br>runs <b>inside</b> the shell')}</div>
      <div class="rt-col"><div class="rt-b srch${cls('path')}${was('found')||was('missing')?' dn':''}">search <code>$PATH</code></div><div class="rt-y${was('found')||was('missing')?' on':''}">↓</div>${end('found','<b>found</b>: the first match',fileOf('found')||'/usr/bin/sort')}${end('missing','<code>command not found</code>')}</div>
    </div>
    <div class="rt-path${was('path')?'':' lx-hid'}"><span class="lx-cap">PATH=</span>${PATHD.map((d,k)=>{const c=seen.find(x=>x.at==='path'&&x.k===k);return `<span class="rt-d${c?c.ok?' ok':' no':''}${st.at==='path'&&st.k===k?' now':''}"><code>${esc(d)}</code><i>${c?c.ok?'✓ '+esc(name):'✗':''}</i></span>`}).join('<b>:</b>')}</div>
    ${i===S.length-1?(()=>{const r=RT.find(r=>r.c===cur);const out=r?r.o:'';return `<pre class="sh lx-line"><span class="p">$</span> <span class="c">${esc(cur)}</span>${out?'\n<span class="o">'+esc(out)+'</span>':''}</pre>`})():''}`;
  });
  const set=c=>{cur=c;S=routeSteps(c);go(0)};
  onChips(root,k=>{q('own').hidden=k!=='your own';if(k==='your own'){set(q('inp').value);q('inp').focus({preventScroll:true})}else set(k)});
  q('inp').addEventListener('input',e=>set(e.target.value));
  go(0);
}

/* ================================================================ the order of redirects (fd tables, as in lecture 03) */
const ERR="ls: cannot access '/nope': No such file or directory",ETC='/etc:\nfstab\nhostname\npasswd';
const K0=[[0,'keyboard'],[1,'display'],[2,'display']];
const RO={
  both:{cmd:'ls /etc /nope > all.txt 2>&1',code:['pid = fork();','// the child, the redirects from left to right:','fd = open("all.txt", O_WRONLY|O_CREAT|O_TRUNC);','dup2(fd, 1);  close(fd);     // > all.txt','dup2(1, 2);                  // 2>&1','execvp("ls", ["ls", "/etc", "/nope"]);'],
    steps:[
      {l:0,n:'bash (child)',rows:K0,x:'<code>fork</code>: the child has a copy of the table of the shell. It applies the redirects <b>from left to right</b>.'},
      {l:2,n:'bash (child)',rows:K0.concat([[3,'all.txt','ch']]),x:'<code>&gt; all.txt</code>: open the file at <b>3</b> ...'},
      {l:3,n:'bash (child)',rows:[[0,'keyboard'],[1,'all.txt','ch'],[2,'display'],[3,'all.txt','x']],x:'... move it to <b>1</b> and close 3.'},
      {l:4,n:'bash (child)',rows:[[0,'keyboard'],[1,'all.txt'],[2,'all.txt','ch']],x:'<code>2&gt;&amp;1</code> is <code>dup2(1, 2)</code>: 2 points where 1 points <b>now</b>, to <code>all.txt</code>.'},
      {l:5,n:'ls',rows:[[0,'keyboard'],[1,'all.txt'],[2,'all.txt']],out:[['display',''],['all.txt',ERR+'\n'+ETC]],x:'Both streams go into <code>all.txt</code>, nothing on the display. <code>&amp;&gt; all.txt</code> is the short form.'},
    ]},
  order:{cmd:'ls /etc /nope 2>&1 > all.txt',code:['pid = fork();','// the child, the redirects from left to right:','dup2(1, 2);                  // 2>&1','fd = open("all.txt", O_WRONLY|O_CREAT|O_TRUNC);','dup2(fd, 1);  close(fd);     // > all.txt','execvp("ls", ["ls", "/etc", "/nope"]);'],
    steps:[
      {l:0,n:'bash (child)',rows:K0,x:'<code>fork</code>. The same redirects, in the <b>other order</b>.'},
      {l:2,n:'bash (child)',rows:[[0,'keyboard'],[1,'display'],[2,'display','ch']],x:'<code>2&gt;&amp;1</code> comes first: 2 points where 1 points <b>now</b>, the display. Nothing changes.'},
      {l:3,n:'bash (child)',rows:K0.concat([[3,'all.txt','ch']]),x:'<code>&gt; all.txt</code>: open the file at <b>3</b> ...'},
      {l:4,n:'bash (child)',rows:[[0,'keyboard'],[1,'all.txt','ch'],[2,'display'],[3,'all.txt','x']],x:'... and move it to <b>1</b>. 2 does not follow: <code>dup2</code> copied the old target, it is not a link to 1.'},
      {l:5,n:'ls',rows:[[0,'keyboard'],[1,'all.txt'],[2,'display']],out:[['display',ERR],['all.txt',ETC]],x:'The listing goes into the file, the error still reaches the display. Write <code>2&gt;&amp;1</code> <b>after</b> <code>&gt; file</code>.'},
    ]},
};
function wOrder(root){
  let sc='both';const STD=['stdin','stdout','stderr'];
  root.innerHTML=`<div class="wd lxw"><div class="wd-h"><div><h3>The redirects, from left to right</h3><p>Step through the calls the shell makes in the child, and watch the File Descriptor Table.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c">${chips(Object.keys(RO),sc,k=>RO[k].cmd)}${NAV()}</div>
  <div class="ps-x" data-r="x"></div><div class="rd-b rd-side"><pre class="sh fkcode rd-code" data-r="code"></pre><div class="rd-tabs" data-r="tabs"></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=stepper(root,()=>RO[sc].steps.length,i=>{const S=RO[sc],st=S.steps[i];
    q('code').innerHTML=S.code.map((l,k)=>`<span class="${k===st.l?'cur':''}">${window.ISOHL?window.ISOHL(l,'c'):esc(l)}</span>`).join('\n');
    const rows=st.rows.map(([fd,to,m])=>`<tr class="${m||(fd<3&&to!==(fd?'display':'keyboard')?'rd':'')}"><td>${fd}</td><td>${fd<3?STD[fd]:''}</td><td>→ ${esc(to)}</td></tr>`).join('');
    q('tabs').innerHTML=`<div class="fdp rd-t${i===0||st.n==='ls'?' new':''}"><div class="fdh"><b>${esc(st.n)}</b> <span>PID 4301</span></div><table class="fdt">${rows}</table></div>`+(st.out||[]).map(([to,t])=>`<div class="rd-o ${to==='display'?'dsp':''}"><div class="rd-oh">${to==='display'?'🖥 the display':'📄 '+esc(to)}</div><pre>${t?esc(t):'<i>(empty)</i>'}</pre></div>`).join('');
    q('x').innerHTML=st.x;q('b').textContent='step '+(i+1)+' / '+S.steps.length});
  onChips(root,k=>{sc=k;go(0)});
  go(0);
}

/* ================================================================ the signals of Linux: click one */
const ACT={Term:['ends the process','#b85450','#f8cecc'],Core:['ends the process and writes a core dump (a copy of its memory, for debugging)','#8e44ad','#ecdcf3'],
  Stop:['suspends the process until it gets SIGCONT','#b8860b','#fff2cc'],Cont:['continues the process, if it was stopped','#2e7d46','#d5e8d4'],Ign:['nothing: the signal is discarded','#5b6b71','#eef1f3']};
// [number, name, default action, title, what it means, who sends it, can it be caught, common]
const SG=[
  [1,'SIGHUP','Term','Hangup','The controlling terminal was closed (the line was “hung up”). Daemons, which have no terminal, often use it to mean “read your configuration file again”.','the terminal driver when the window closes; bash forwards it to its jobs; <code>kill -HUP PID</code>',1,1],
  [2,'SIGINT','Term','Interrupt from the keyboard','The user wants to stop the program that runs in the foreground.','<kbd>Ctrl</kbd>+<kbd>C</kbd>, to the whole foreground group; <code>kill -INT PID</code>',1,1],
  [3,'SIGQUIT','Core','Quit from the keyboard','Like <code>SIGINT</code>, but the process also leaves a core dump, to see where it was.','<kbd>Ctrl</kbd>+<kbd>\\</kbd>; <code>kill -QUIT PID</code>',1,1],
  [4,'SIGILL','Core','Illegal instruction','The processor found an instruction it does not know: a corrupted program or one built for another processor.','the kernel, after the processor fault',1,0],
  [5,'SIGTRAP','Core','Trace / breakpoint trap','A breakpoint was hit. Debuggers like <code>gdb</code> catch it to stop the program on a line.','the kernel, for a debugger',1,0],
  [6,'SIGABRT','Core','Abort','The program found a bug in itself and gave up: <code>abort()</code>, a failed <code>assert()</code>.','the program itself, with <code>abort()</code>',1,0],
  [7,'SIGBUS','Core','Bus error','A bad memory access, e.g. to a file mapped in memory that became shorter.','the kernel',1,0],
  [8,'SIGFPE','Core','Arithmetic error','An error in a computation, most often an integer division by zero.','the kernel, after the processor fault',1,0],
  [9,'SIGKILL','Term','Kill','End the process now. It <b>cannot be caught, blocked or ignored</b>: the last resort for a program that does not listen.','<code>kill -9 PID</code>, <code>kill -KILL PID</code>; the kernel when memory runs out (the OOM killer)',0,1],
  [10,'SIGUSR1','Term','User-defined signal 1','No fixed meaning: each program decides. <code>dd</code> prints its progress, many servers reopen their log files.','<code>kill -USR1 PID</code>',1,0],
  [11,'SIGSEGV','Core','Segmentation fault','The program used memory that is not its own: a bad pointer, an array index out of bounds. The famous “Segmentation fault (core dumped)”.','the kernel',1,1],
  [12,'SIGUSR2','Term','User-defined signal 2','A second signal with no fixed meaning, for the program to use.','<code>kill -USR2 PID</code>',1,0],
  [13,'SIGPIPE','Term','Broken pipe','The process wrote into a pipe that nobody reads any more. In <code>yes | head -1</code>, <code>yes</code> ends this way after <code>head</code> exits.','the kernel, at the write',1,1],
  [14,'SIGALRM','Term','Alarm clock','A timer set by the program with <code>alarm()</code> expired.','the kernel, for <code>alarm()</code>',1,0],
  [15,'SIGTERM','Term','Termination','The polite way to ask a process to end: it can save its work and clean up first. The default signal of <code>kill</code>.','<code>kill PID</code>; <code>systemd</code> when it stops a service, at shutdown',1,1],
  [16,'SIGSTKFLT','Term','Stack fault','A fault of the math coprocessor stack. Not used by Linux any more.','nobody, today',1,0],
  [17,'SIGCHLD','Ign','Child stopped or ended','A child process ended or was stopped. The parent can catch it and call <code>wait</code>, so no zombies are left.','the kernel, to the parent',1,1],
  [18,'SIGCONT','Cont','Continue','A stopped process continues. It cannot be blocked from continuing, a handler only runs after.','<code>fg</code>, <code>bg</code>; <code>kill -CONT PID</code>',1,1],
  [19,'SIGSTOP','Stop','Stop','Suspend the process. Like <code>SIGKILL</code>, it <b>cannot be caught, blocked or ignored</b>.','<code>kill -STOP PID</code>; debuggers',0,1],
  [20,'SIGTSTP','Stop','Stop from the terminal','The user wants to pause the foreground program; unlike <code>SIGSTOP</code>, a program may handle or ignore it.','<kbd>Ctrl</kbd>+<kbd>Z</kbd>, to the whole foreground group',1,1],
  [21,'SIGTTIN','Stop','Background read from the terminal','A background job tried to read the keyboard: only the foreground may, so it is stopped.','the terminal driver',1,0],
  [22,'SIGTTOU','Stop','Background write to the terminal','A background job tried to write to the terminal (only when the terminal is set with <code>stty tostop</code>) or to change its settings.','the terminal driver',1,0],
  [23,'SIGURG','Ign','Urgent data on a socket','Out-of-band data arrived on a network connection.','the kernel',1,0],
  [24,'SIGXCPU','Core','CPU time limit exceeded','The process used more processor time than its limit (<code>ulimit -t</code>).','the kernel',1,0],
  [25,'SIGXFSZ','Core','File size limit exceeded','The process tried to make a file larger than its limit (<code>ulimit -f</code>).','the kernel',1,0],
  [26,'SIGVTALRM','Term','Virtual timer expired','A timer that counts only the time the process itself runs expired.','the kernel, for <code>setitimer()</code>',1,0],
  [27,'SIGPROF','Term','Profiling timer expired','A timer used by profilers, to measure where a program spends its time.','the kernel, for profilers',1,0],
  [28,'SIGWINCH','Ign','Window size changed','The terminal window was resized: full-screen programs (<code>nano</code>, <code>top</code>) catch it and redraw.','the terminal driver, when the emulator changes the size',1,0],
  [29,'SIGIO','Term','I/O possible','A file descriptor is ready to read or write, for programs that asked to be told.','the kernel',1,0],
  [30,'SIGPWR','Term','Power failure','The power supply is failing (sent by UPS tools): time to shut down cleanly.','the UPS software, to <code>init</code>',1,0],
  [31,'SIGSYS','Core','Bad system call','The program made a system call that does not exist, or one that a sandbox forbids.','the kernel',1,0],
  ['34–64','SIGRTMIN … SIGRTMAX','Term','Real-time signals','31 signals with no fixed meaning, for applications. Unlike the others, they queue up: if ten are sent, ten arrive, in order.','programs, with <code>sigqueue()</code>',1,0],
];
function wSig(root){
  let cur=1,flt='all';
  root.innerHTML=`<div class="wd lxw sigw"><div class="wd-h"><div><h3>The signals of Linux: click one</h3><p>What each signal means, who sends it and what the process does by default. ★ the ones you will meet most.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><span class="lx-cap">default action:</span><div class="seg sg-f" data-seg="f">${['all','Term','Core','Stop','Cont','Ign'].map(k=>`<button type="button" data-v="${k}" class="${k==='all'?'on':''}">${k}</button>`).join('')}</div></div>
  <div class="sg-b"><div class="sg-grid" data-r="g"></div><div class="sg-d" data-r="d" aria-live="polite"></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const draw=()=>{
    q('g').innerHTML=SG.map((s,i)=>{const a=ACT[s[2]];return `<button type="button" class="sg-c${i===cur?' on':''}${flt!=='all'&&s[2]!==flt?' dim':''}" data-i="${i}" style="--c:${a[1]};--f:${a[2]}"><b>${s[0]}</b><span>${s[1].replace(' … ','…')}</span>${s[7]?'<i>★</i>':''}</button>`}).join('');
    const s=SG[cur],a=ACT[s[2]],n=typeof s[0]==='number'?s[0]:null;
    q('d').innerHTML=`<div class="sg-h"><span class="sg-n">${s[0]}</span><div><b class="sg-name">${s[1]}</b><span>${s[3]}</span></div></div>
      <p>${s[4]}</p>
      <dl><dt>Sent by</dt><dd>${s[5]}</dd>
      <dt>Default action</dt><dd><span class="sg-a" style="--c:${a[1]};--f:${a[2]}">${s[2]}${s[2]==='Term'&&!s[6]?' · cannot be caught':s[2]==='Stop'&&!s[6]?' · cannot be caught':''}</span> ${a[0]}</dd>
      <dt>A handler?</dt><dd>${s[6]?'yes: <code>trap HANDLER '+(n?s[1]:'SIGRTMIN')+'</code> in bash, <code>signal()</code> in C, or ignore it with <code>trap \'\' '+(n?s[1]:'SIGRTMIN')+'</code>':'<b>no</b>: it cannot be caught, blocked or ignored'}</dd>
      ${n?`<dt>Send it</dt><dd><code>kill -${s[1].slice(3)} PID</code> or <code>kill -${n} PID</code></dd>`:''}
      ${n&&['Term','Core'].includes(s[2])?`<dt>Exit code</dt><dd>if it ends the process: 128 + ${n} = <code>${128+n}</code></dd>`:''}</dl>`;
    q('b').textContent=s[1].split(' ')[0];
    root.querySelectorAll('.sg-c').forEach(b=>b.addEventListener('click',()=>{cur=+b.dataset.i;draw()}));
  };
  root.querySelectorAll('[data-seg="f"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="f"] button').forEach(x=>x.classList.toggle('on',x===b));flt=b.dataset.v;
    if(flt!=='all'&&SG[cur][2]!==flt)cur=SG.findIndex(s=>s[2]===flt&&s[7])>=0?SG.findIndex(s=>s[2]===flt&&s[7]):SG.findIndex(s=>s[2]===flt);draw()}));
  draw();
}

const W=window.DK_W||(window.DK_W={});
W.tty=wTty;W.trap=wTrap;W.sess=wSess;W.env=wEnv;W.split=wSplit;W.argv=wArgv;W.route=wRoute;W.order=wOrder;W.sig=wSig;
})();
