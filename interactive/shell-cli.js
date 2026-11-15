/* ISO lecture 04 (Command Line Interface):
   - ISOCLI: how bash reads a command line (words, quotes, $NAME, ~, {a,b}, splitting, globs), used by the widgets
   - the demo terminal of lecture 04 (data-profile="04"): shell and environment variables, export, jobs (&, Ctrl+Z,
     Ctrl+C, fg, bg, kill), the PATH search (type, which, ./hello), its side panels (jobs, vars, path) and missions.
   Additive: the shell changes only for the profile '04'. */
(()=>{'use strict';
const S=typeof ISOSH!=='undefined'?ISOSH:null;
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const HOMEP='/home/student';

/* ================================================================ 1. the lexer
   a word: {t:'w', raw, segs:[{q, s, g}]}; q: 'n' unquoted, 'e' an escaped character (\x), 's' inside '...',
   'd' inside "..." (expanded), 'D' an escaped character inside "..."; g: the number of the pair of quotes
   an operator: {t:'op', v}: | || && ; & and the redirects < > >> 2> 2>> &> &>> 2>&1 >&2 */
function lex(line){
  const toks=[];let cur=null,i=0,g=0;
  const W=()=>cur||(cur={t:'w',raw:'',segs:[]});
  const add=(q,s,raw,gg)=>{const w=W();w.raw+=raw;const l=w.segs[w.segs.length-1];
    if(l&&l.q===q&&l.g===gg&&q!=='e'&&q!=='D')l.s+=s;else w.segs.push({q,s,g:gg})};
  const end=()=>{if(cur){toks.push(cur);cur=null}};
  while(i<line.length){
    const c=line[i];
    if(c===' '||c==='\t'||c==='\n'){end();i++;continue}
    if(c==='#'&&!cur)break;
    if('|&;<>'.includes(c)){
      let fd='';
      if(cur&&(c==='>'||c==='<')&&cur.segs.length===1&&cur.segs[0].q==='n'&&/^\d$/.test(cur.raw)){fd=cur.raw;cur=null}
      end();
      const r=line.slice(i), m=fd?r.match(/^(>>|>&\d|>|<)/):r.match(/^(&>>|&>|&&|\|\||>>|>&\d|[|&;<>])/);
      let v=fd+m[1];
      v={'1>':'>','1>>':'>>','1>&2':'>&2','0<':'<'}[v]||v;
      toks.push({t:'op',v,raw:fd+m[1]});i+=m[1].length;continue}
    if(c==="'"){const j=line.indexOf("'",i+1);if(j<0)return{err:"unexpected EOF while looking for matching `''",open:"'"};
      g++;const s=line.slice(i+1,j);W().raw+="'";if(s)add('s',s,s,g);else W().segs.push({q:'s',s:'',g});W().raw+="'";i=j+1;continue}
    if(c==='"'){g++;W().raw+='"';let j=i+1,empty=true;
      while(j<line.length&&line[j]!=='"'){
        if(line[j]==='\\'&&j+1<line.length&&'$`"\\'.includes(line[j+1])){add('D',line[j+1],'\\'+line[j+1],g);j+=2}
        else{add('d',line[j],line[j],g);j++}
        empty=false}
      if(j>=line.length)return{err:'unexpected EOF while looking for matching `"\'',open:'"'};
      if(empty)W().segs.push({q:'d',s:'',g});
      W().raw+='"';i=j+1;continue}
    if(c==='\\'){if(i+1<line.length){add('e',line[i+1],'\\'+line[i+1],0);i+=2}else{add('n','\\','\\',0);i++}continue}
    add('n',c,c,0);i++;
  }
  end();
  return{toks};
}

/* ================================================================ 2. one simple command: assignments, redirects, words */
const isAsg=w=>w.t==='w'&&w.segs.length>0&&w.segs[0].q==='n'&&/^[A-Za-z_]\w*=/.test(w.segs[0].s);
function parts(toks){
  const asg=[],red=[],words=[];
  for(let k=0;k<toks.length;k++){const t=toks[k];
    if(t.t==='op'){
      if(t.v==='2>&1'||t.v==='>&2'){red.push({op:t.v});continue}
      const n=toks[k+1];if(!n||n.t!=='w')return{err:"syntax error near unexpected token `"+(n?n.v:'newline')+"'"};
      red.push({op:t.v,w:n});k++;continue}
    if(!words.length&&isAsg(t)){asg.push(t);continue}
    words.push(t)}
  return{asg,red,words};
}
// NAME=value: the name and the segments of the value
function splitAsg(w){const s0=w.segs[0],i=s0.s.indexOf('=');const rest=s0.s.slice(i+1);
  return{name:s0.s.slice(0,i),segs:(rest?[{q:'n',s:rest,g:0}]:[]).concat(w.segs.slice(1))}}

/* ================================================================ 3. the expansions
   a piece: {q, s, g, x: came from $NAME or ~, br: came from braces, gl: a file name from a glob} */
function braces(segs){
  for(let k=0;k<segs.length;k++){const sg=segs[k];if(sg.q!=='n')continue;
    const re=/\{([^{}]*)\}/g;let m;
    while((m=re.exec(sg.s))){
      if(m.index>0&&sg.s[m.index-1]==='$')continue;
      const b=m[1];let alts=null,r;
      if(b.includes(','))alts=b.split(',');
      else if((r=b.match(/^(-?\d+)\.\.(-?\d+)$/))){const a=+r[1],z=+r[2],d=a<=z?1:-1;alts=[];for(let v=a;d>0?v<=z:v>=z;v+=d)alts.push(String(v))}
      else if((r=b.match(/^([a-zA-Z])\.\.([a-zA-Z])$/))){const a=r[1].charCodeAt(0),z=r[2].charCodeAt(0),d=a<=z?1:-1;alts=[];for(let v=a;d>0?v<=z:v>=z;v+=d)alts.push(String.fromCharCode(v))}
      if(!alts)continue;
      const pre=sg.s.slice(0,m.index),post=sg.s.slice(m.index+m[0].length);
      return alts.flatMap(a=>braces(segs.slice(0,k).concat([{q:'n',s:pre+a+post,g:0,br:true}],segs.slice(k+1))));
    }
  }
  return[segs];
}
function params(segs,ctx){
  const out=[];
  segs.forEach((sg,k)=>{
    if(sg.q!=='n'&&sg.q!=='d'){out.push(Object.assign({},sg));return}
    let s=sg.s;
    if(sg.q==='n'&&k===0&&(s==='~'||s.startsWith('~/'))){out.push({q:'n',s:ctx.home,g:0,x:true,src:'~'});s=s.slice(1)}
    const re=/\$(\{([A-Za-z_]\w*)\}|([A-Za-z_]\w*)|([?$!#0]))/g;let m,last=0;
    while((m=re.exec(s))){
      if(m.index>last)out.push({q:sg.q,s:s.slice(last,m.index),g:sg.g,br:sg.br});
      const v=ctx.get(m[2]||m[3]||m[4]);
      out.push({q:sg.q,s:v==null?'':String(v),g:sg.g,x:true,src:m[0]});last=re.lastIndex}
    if(last<s.length||!s.length&&sg.q==='d')out.push({q:sg.q,s:s.slice(last),g:sg.g,br:sg.br});
  });
  return out;
}
function fsplit(pieces){
  const words=[];let cur=[];
  const flush=()=>{if(cur.length)words.push(cur);cur=[]};
  for(const p of pieces){
    if(p.q==='n'&&p.x){const bits=p.s.split(/[ \t\n]+/);
      bits.forEach((b,i)=>{if(i>0)flush();if(b!=='')cur.push(Object.assign({},p,{s:b,sp:bits.length>1}))})}
    else cur.push(p);
  }
  flush();
  return words;
}
const hasGlob=w=>w.some(p=>p.q==='n'&&!p.gl&&/[*?]|\[[^\]]+\]/.test(p.s));
function globRx(chars){                               // chars: [{c, sp}] -> RegExp source
  let r='';
  for(let i=0;i<chars.length;i++){const{c,sp}=chars[i];
    if(sp&&c==='*'){r+='[^/]*';continue}
    if(sp&&c==='?'){r+='[^/]';continue}
    if(sp&&c==='['){let j=i+1,body='';
      if(chars[j]&&(chars[j].c==='!'||chars[j].c==='^')){body='^';j++}
      let k=j;while(k<chars.length&&!(chars[k].c===']'&&k>j))k++;
      if(k<chars.length){body+=chars.slice(j,k).map(x=>x.c==='\\'?'\\\\':x.c).join('');r+='['+body+']';i=k;continue}}
    r+=c.replace(/[.+^${}()|[\]\\*?]/g,'\\$&');
  }
  return r;
}
function glob(w,ctx){
  const chars=[];for(const p of w){for(const c of p.s)chars.push({c,sp:p.q==='n'})}
  const comps=[[]];for(const ch of chars){if(ch.c==='/')comps.push([]);else comps[comps.length-1].push(ch)}
  const abs=comps.length>1&&comps[0].length===0; if(abs)comps.shift();
  const dirOnly=comps.length>1&&comps[comps.length-1].length===0; if(dirOnly)comps.pop();
  const C=comps.map(cs=>{const txt=cs.map(x=>x.c).join(''),special=cs.some(x=>x.sp&&/[*?[]/.test(x.c));
    if(!special)return{lit:txt};
    if(ctx.globstar&&txt==='**'&&cs.every(x=>x.sp))return{star2:true};
    return{re:new RegExp('^'+globRx(cs)+'$'),dot:txt.startsWith('.')}});
  const res=[];
  const join=(pre,n)=>pre===''?(abs?'/'+n:n):pre.endsWith('/')?pre+n:pre+'/'+n;
  const walk=(pre,k)=>{
    if(k===C.length){if(pre!==''&&(!dirOnly||ctx.isDir(pre)))res.push(pre);return}
    const c=C[k], dir=pre===''?(abs?'/':'.'):pre;
    if(c.lit!=null){const p=join(pre,c.lit);if(k===C.length-1?ctx.exists(p):ctx.isDir(p))walk(p,k+1);return}
    const names=ctx.list(dir);if(!names)return;
    if(c.star2){walk(pre,k+1);for(const n of names)if(!n.startsWith('.')&&ctx.isDir(join(pre,n)))walk2(join(pre,n),k);return}
    for(const n of names){if(n.startsWith('.')&&!c.dot)continue;if(!c.re.test(n))continue;
      const p=join(pre,n);if(k===C.length-1)res.push(p);else if(ctx.isDir(p))walk(p,k+1)}
  };
  const walk2=(pre,k)=>{walk(pre,k+1);const names=ctx.list(pre)||[];for(const n of names)if(!n.startsWith('.')&&ctx.isDir(join(pre,n)))walk2(join(pre,n),k)};
  walk(abs?'':'',0);
  const out=[...new Set(res)].map(p=>dirOnly?p+'/':p);
  const key=s=>s.toLowerCase();
  out.sort((a,b)=>key(a)<key(b)?-1:key(a)>key(b)?1:a<b?-1:1);
  return out;
}
const unq=w=>w.map(p=>p.s).join('');
// a word as it is written at this stage: the quotes that are still there
function render(w){
  let out='',open=null;
  const close=()=>{if(open){out+=open.q;open=null}};
  for(const p of w){
    const q=p.q==='s'?"'":(p.q==='d'||p.q==='D')?'"':null;
    if(q&&open&&(open.g!==p.g||open.q!==q))close();
    if(!q)close();
    if(q&&!open){out+=q;open={g:p.g,q}}
    out+=p.q==='e'||p.q==='D'?'\\'+p.s:p.s;
  }
  close();
  return out;
}

/* the whole line, stage by stage (for the widget), or only the result (for the shell) */
function analyze(line,ctx){
  const L=lex(line);if(L.err)return{err:L.err,open:L.open};
  const toks=L.toks;if(!toks.length)return{err:'empty'};
  const sepAt=toks.findIndex(t=>t.t==='op'&&['|','||','&&',';','&'].includes(t.v));
  const one=sepAt<0?toks:toks.slice(0,sepAt);
  const P=parts(one);if(P.err)return{err:P.err};
  const asg=P.asg.map(w=>{const a=splitAsg(w);return{name:a.name,raw:w.raw,value:unq(params(a.segs,ctx)),valueRaw:render(params(a.segs,ctx))}});
  const red=P.red.map(r=>{if(!r.w)return{op:r.op,raw:r.op};const pc=params(r.w.segs,ctx);const g=hasGlob(pc)?glob(pc,ctx):[];
    return{op:r.op,raw:r.op+' '+r.w.raw,rawX:r.op+' '+render(pc),to:g.length===1?g[0]:unq(pc),changed:pc.some(p=>p.x)}});
  // the stages of the words
  const st1=one.map(t=>({w:t.t==='op'?t.raw:t.raw}));
  const st2=P.words.map(t=>({w:t.raw}));
  const s3=[],s4=[],s5=[],s6=[];
  for(const t of P.words){
    for(const b of braces(t.segs)){
      const pc=params(b,ctx);
      s3.push({w:render(pc),nw:pc.some(p=>p.x||p.br),pcs:pc});
    }
  }
  for(const x of s3){const ws=fsplit(x.pcs);
    if(!ws.length)s4.push({w:'',gone:true,from:x.w});
    ws.forEach(w=>s4.push({w:render(w),nw:ws.length>1||w.some(p=>p.sp),pcs:w}))}
  for(const x of s4){if(x.gone)continue;
    if(hasGlob(x.pcs)){const m=glob(x.pcs,ctx);if(m.length){m.forEach(n=>s5.push({w:n,nw:true,pcs:[{q:'n',s:n,gl:true}],gl:true}));continue}
      s5.push({w:x.w,pcs:x.pcs,nomatch:true});continue}
    s5.push({w:x.w,pcs:x.pcs})}
  for(const x of s5){const v=unq(x.pcs);s6.push({w:v,nw:!x.gl&&v!==x.w})}
  const argv=s6.map(x=>x.w);
  return{toks:one,more:sepAt>=0?toks[sepAt].v:null,asg,red,st1,st2,s3,s4,s5,s6,argv,words:P.words};
}
/* the result only: {asg:[[n,v]], red:[{op,to}], argv, plain0} or {err} (the demo shell) */
function expandCmd(toks,ctx){
  const P=parts(toks);if(P.err)return{err:P.err};
  const asg=P.asg.map(w=>{const a=splitAsg(w);return[a.name,unq(params(a.segs,ctx))]});
  const red=[];
  for(const r of P.red){if(!r.w){red.push({op:r.op});continue}
    const pc=params(r.w.segs,ctx);let to=unq(pc);
    if(hasGlob(pc)){const g=glob(pc,ctx);if(g.length>1)return{err:r.w.raw+': ambiguous redirect'};if(g.length)to=g[0]}
    red.push({op:r.op,to})}
  const argv=[];
  for(const t of P.words)for(const b of braces(t.segs))for(const w of fsplit(params(b,ctx))){
    if(hasGlob(w)){const g=glob(w,ctx);if(g.length){argv.push(...g);continue}}
    argv.push(unq(w))}
  const plain0=P.words.length>0&&P.words[0].segs.every(s=>s.q==='n');
  return{asg,red,argv,plain0};
}
/* a file system context for the expansions, from a demo shell */
function fsCtx(sh,get){
  const node=p=>S.lookup(sh.root,S.split(sh.cwd,p)).node;
  return{home:HOMEP,get,globstar:sh.cli?sh.cli.globstar:false,
    list:p=>{const n=node(p);return n&&n.t==='d'?Object.keys(n.c):null},
    isDir:p=>{const n=node(p);return!!n&&n.t==='d'},exists:p=>!!node(p)};
}

/* ================================================================ 4. a session drawn as boxes (the jobs panel and the session widget)
   model: {term:{name, state:'open'|'closed'|'detached', text}, input:'text' or null, sig:'text' or null,
           groups:[{pgid, label, fg, state:'run'|'stop'|'end'|'killed'|'gone', hit, note, procs:[{n, pid, sub, lead, sl, nohup, hit, gone}]}],
           sid, legend} */
function sess(m){
  const T=m.term||{};
  const grp=g=>`<div class="sx-g${g.fg?' fg':''}${g.hit?' hit':''} sx-${g.state||'run'}"><div class="sx-gh"><b>group ${esc(g.pgid)}</b><span>${g.label||''}</span></div>
    <div class="sx-ps">${g.procs.map(p=>`<div class="sx-p${p.hit?' hit':''}${p.gone?' gone':''}"><b>${p.sl?'👑 ':p.lead&&m.legend?'⭐ ':''}${esc(p.n)}</b><span>${p.sub||'PID '+p.pid}</span>${p.nohup?'<i class="sx-nh">🛡 nohup</i>':''}</div>`).join('')}</div>${g.note?`<div class="sx-gn">${g.note}</div>`:''}</div>`;
  return `<div class="sx">
  <div class="sx-t sx-${T.state||'open'}"><b>🖥 ${esc(T.name||'/dev/pts/0')}</b> <span>${T.text||'the controlling terminal of session '+esc(m.sid||'4100')}</span><small>🐧 the terminal driver, in the kernel</small></div>
  <div class="sx-l${m.sig?' sig':''}">${m.sig?'<span>'+m.sig+'</span>':m.input?'<span class="in">'+m.input+'</span>':'<span class="dt">'+(T.state==='open'?'':'no link: the session has no terminal')+'</span>'}</div>
  <div class="sx-s"><div class="sx-gs">${m.groups.map(grp).join('')}</div><div class="sx-sn">session ${esc(m.sid||'4100')}</div></div>
  ${m.legend?'<div class="sx-lg">👑 <b>session leader</b>: its PID is the SID · ⭐ <b>group leader</b>: its PID is the PGID</div>':''}</div>`;
}

const ISOCLI={lex,parts,analyze,expandCmd,glob,render,sess,fsCtx,esc};
window.ISOCLI=ISOCLI;
if(!S){if(typeof module!=='undefined')module.exports=ISOCLI;return}

/* ================================================================ 5. the demo terminal of lecture 04 */
const P=S.Shell.prototype;
S.PROFILES['04']=(fs,{D,F,t})=>{
  const T=t(10,9,10,0), h=fs.c.home.c.student.c;
  delete h.Downloads;delete h.Movies;delete h['watchlist.txt'];
  const X=(d)=>{const n=F(d,null,T);n.exe=true;return n};
  Object.assign(h,{
    '.local':D({bin:D({},T)},T),
    'a.csv':F('3,cherry\n1,apple\n',null,T),'b.csv':F('2,banana\n',null,T),
    docs:D({'plan.txt':F('1. read the slides\n2. do the lab\n',null,T),'2026':D({'exam.txt':F('exam: January\n',null,T)},T)},T),
    'fruits.txt':F('banana\nCherry\napple\nDate\n',null,T),
    hello:X('#!/bin/bash\necho "Hello!"\n'),
    'my list.txt':F('pears\nfigs\n',null,T),'my notes.txt':F('buy milk\ncall mom\n',null,T),
    'notes.txt':F('lab 04: jobs and signals\n',null,T),
    'photo1.png':F('',20480,T),'photo2.png':F('',19456,T),'photo3.png':F('',22528,T),'photoA.png':F('',18432,T),
    'report.md':F('# Report\n',null,T),'todo.txt':F('learn bash\n',null,T),
  });
  fs.c.home.c.tools=D({hello:X('#!/bin/bash\necho "Hello from tools!"\n')},T);
  const ub=fs.c.usr.c.bin.c, b=fs.c.bin.c;
  for(const n of ['ls','cat','cp','mv','rm','mkdir','rmdir','touch','pwd','echo','kill','tree','find','man','nano','file','sleep','date','env','printenv','tty','which','nohup','uniq','clear','pstree','lsof','whoami','hostname','bash','true','false'])if(!ub[n])ub[n]=F('',30000,T);
  b.sort=F('',120000,T);
  fs.c.usr.c.local=D({bin:D({},T)},T);
};
const BUILTIN=new Set(['cd','echo','pwd','export','unset','jobs','fg','bg','kill','type','exit','help','history','true','false','alias','shopt','trap','reset']);
const SYS=p=>p[0]==='bin'||p[0]==='sbin'||p[0]==='usr'&&(p[1]==='bin'||p[1]==='local'&&p[2]==='bin');
const SIGS=['','HUP','INT','QUIT','ILL','TRAP','ABRT','BUS','FPE','KILL','USR1','SEGV','USR2','PIPE','ALRM','TERM','STKFLT','CHLD','CONT','STOP','TSTP','TTIN','TTOU','URG','XCPU','XFSZ','VTALRM','PROF','WINCH','IO','PWR','SYS'];
const KILL_L=(()=>{const n=[];for(let i=1;i<=31;i++)n.push([i,'SIG'+SIGS[i]]);n.push([34,'SIGRTMIN']);for(let i=1;i<=15;i++)n.push([34+i,'SIGRTMIN+'+i]);for(let i=14;i>=1;i--)n.push([64-i,'SIGRTMAX-'+i]);n.push([64,'SIGRTMAX']);
  const out=[];for(let i=0;i<n.length;i+=5)out.push(n.slice(i,i+5).map(([k,s])=>(String(k).padStart(2)+') '+s).padEnd(16)).join('').trimEnd());return out.join('\n')})();
const sigName=s=>{s=String(s).toUpperCase().replace(/^SIG/,'');if(/^\d+$/.test(s))return SIGS[+s]||null;return SIGS.includes(s)&&s?s:null};

function cli(sh){
  if(sh.cli)return sh.cli;
  sh.cli={vars:{HOME:HOMEP,USER:'student',SHELL:'/bin/bash',PATH:HOMEP+'/.local/bin:/usr/local/bin:/usr/bin:/bin',LANG:'en_US.UTF-8',PWD:'/'+sh.cwd.join('/'),PS1:'\\u@\\h:\\w\\$ '},
    exp:new Set(['HOME','USER','SHELL','PATH','LANG','PWD']),alias:{ll:'ls -l'},code:0,bg:null,jobs:[],order:[],fg:null,ev:new Set(),
    globstar:false,live:false,what:'',changed:new Set(),last:null,child:null,depth:0,nf:[]};
  return sh.cli;
}
const ctxOf=sh=>{const C=cli(sh);return fsCtx(sh,n=>n==='?'?String(C.code):n==='$'?String(sh.pid):n==='!'?(C.bg==null?'':String(C.bg)):n==='#'?'0':n==='0'?'bash':C.vars[n])};
const envOf=C=>{const e={};for(const n of C.exp)if(C.vars[n]!=null)e[n]=C.vars[n];return e};

/* ---------- jobs ---------- */
const now=()=>Date.now();
const alive=j=>/^(Running|Stopped)/.test(j.state);
const live=C=>C.jobs.filter(alive);
function marks(C){const o=C.order.filter(j=>C.jobs.includes(j)&&!j.told);const m=new Map();if(o.length)m.set(o[o.length-1],'+');if(o.length>1)m.set(o[o.length-2],'-');return m}
const nextId=C=>Math.max(0,...C.jobs.filter(j=>!j.told).map(j=>j.id),C.fg&&C.fg.id?C.fg.id:0)+1;
const touch=(C,j)=>{C.order=C.order.filter(x=>x!==j).concat(j)};
function fmtJob(j,mk,l){const st=j.state==='Running'?'Running':j.state;return '['+j.id+']'+(mk||' ')+'  '+(l?j.pgid+' ':'')+st.padEnd(24)+j.cmd+(j.state==='Running'?' &':'')}
function tick(sh){
  const C=cli(sh),t=now();let ch=false;
  for(const j of C.jobs)if(j.state==='Running'&&j.end!=null&&j.end<=t){j.state='Done';ch=true}
  if(C.fg&&C.fg.end!=null&&C.fg.end<=t){C.fg=null;C.code=0;C.what='The foreground job ended by itself: bash shows the prompt again.';ch=true}
  return ch;
}
function notify(sh){
  const C=cli(sh);if(C.depth)return[];
  const m=marks(C),out=[];
  for(const j of C.jobs.slice().sort((a,b)=>a.id-b.id)){if(!j.told&&!alive(j)){out.push({out:fmtJob(j,m.get(j))});j.told=true}else if(j.stopNote){out.push({out:fmtJob(j,m.get(j))});j.stopNote=false}}
  C.jobs=C.jobs.filter(j=>!j.told);C.order=C.order.filter(j=>C.jobs.includes(j));
  return out;
}
function findJob(C,spec,cmd){
  const L=C.jobs.filter(j=>!j.told);
  if(spec==null||spec==='%%'||spec==='%+'||spec==='%'){const o=C.order.filter(j=>L.includes(j));return o.length?o[o.length-1]:{err:'bash: '+cmd+': current: no such job'}}
  if(spec==='%-'){const o=C.order.filter(j=>L.includes(j));return o.length>1?o[o.length-2]:{err:'bash: '+cmd+': %-: no such job'}}
  const m=spec.match(/^%?(\d+)$/);
  const j=m?L.find(x=>x.id===+m[1]):L.find(x=>x.cmd.startsWith(spec.replace(/^%/,'')));
  return j||{err:'bash: '+cmd+': '+spec+': no such job'};
}
const STATE={TERM:'Terminated',INT:'Interrupt',HUP:'Hangup',KILL:'Killed',QUIT:'Quit (core dumped)',USR1:'User defined signal 1',USR2:'User defined signal 2',ALRM:'Alarm clock',PIPE:'Broken pipe',ABRT:'Aborted (core dumped)',SEGV:'Segmentation fault (core dumped)'};
function signal(C,j,sig){
  if(['STOP','TSTP','TTIN','TTOU'].includes(sig)){if(j.state==='Running'){j.left=Math.max(0,j.end-now());j.end=null;j.state=sig==='STOP'?'Stopped (signal)':'Stopped';j.stopNote=true;touch(C,j)}return 'stopped'}
  if(sig==='CONT'){if(/^Stopped/.test(j.state)){j.state='Running';j.end=now()+(j.left||0)}return 'continued'}
  if(['CHLD','WINCH','URG'].includes(sig))return 'ignored';
  if(sig==='HUP'&&j.nohup)return 'ignored (nohup)';
  j.state=STATE[sig]||'Terminated';return 'ended';
}
function startJob(sh,ex,text,bg){
  const C=cli(sh);let dur=0,nohup=false;const seq=[];
  for(const e of ex){let a=e.argv;if(a[0]==='nohup'){nohup=true;a=a.slice(1);seq.push({err:e.red.some(r=>/^(>|>>|&>|&>>)$/.test(r.op))?'nohup: ignoring input':"nohup: ignoring input and appending output to 'nohup.out'"});if(!e.red.some(r=>/^(>|>>|&>|&>>)$/.test(r.op)))sh.target('nohup.out','>>')}
    if(a[0]==='sleep'){const m=String(a[1]||'').match(/^(\d+(?:\.\d+)?)([smh]?)$/);if(!m)return{seq:[{err:a[1]==null?"sleep: missing operand\nTry 'sleep --help' for more information.":"sleep: invalid time interval '"+a[1]+"'"}],code:1};
      dur=Math.max(dur,+m[1]*({s:1,m:60,h:3600}[m[2]]||1))}
    for(const r of e.red)if(r.to!=null){const t=sh.target(r.to,r.op==='<'?'<':/>>$/.test(r.op)?'>>':'>');if(t.err)return{seq:[{err:t.err}],code:1}}}
  const procs=ex.map(e=>{const a=e.argv[0]==='nohup'?e.argv.slice(1):e.argv;return{pid:sh.next++,name:a[0]||'?',args:a.join(' '),nohup}});
  const j={id:0,cmd:text,procs,pgid:procs[0].pid,state:'Running',end:now()+dur*1000,left:null,nohup};
  if(bg){j.id=nextId(C);C.jobs.push(j);touch(C,j);C.bg=procs[procs.length-1].pid;C.code=0;
    C.what=`bash started <code>${esc(text)}</code> in the <b>background</b>: job <b>[${j.id}]</b>, process group <b>${j.pgid}</b>${procs.length>1?' ('+procs.length+' processes)':''}. It did not wait: the prompt is back.`;
    return{seq:[{out:'['+j.id+'] '+C.bg}].concat(seq),code:0}}
  C.fg=j;C.what=`<code>${esc(text)}</code> runs in the <b>foreground</b>: its group gets the keyboard, bash waits for it. Press <b>Ctrl+C</b> or <b>Ctrl+Z</b>.`;
  return{seq,code:0};
}
/* a key pressed in the terminal: INT (Ctrl+C), TSTP (Ctrl+Z), QUIT (Ctrl+\) */
function key(sh,k){
  const C=cli(sh),j=C.fg;
  if(!j){if(k==='INT'){C.what='Ctrl+C at the prompt: bash only drops the line you were typing.';return{out:'^C'}}return{}}
  C.fg=null;C.ev.add(k);if(j.viaFg)C.ev.add('fg'+k);
  if(k==='TSTP'){j.id=j.id||nextId(C);j.left=Math.max(0,j.end-now());j.end=null;j.state='Stopped';j.told=false;C.jobs.push(j);touch(C,j);C.code=148;
    C.what=`🐧 The terminal driver turned Ctrl+Z into <b>SIGTSTP</b> for the foreground group <b>${j.pgid}</b>: it is <b>stopped</b>, not ended, and became job <b>[${j.id}]</b>. bash has the terminal back.`;
    return{out:'^Z\n['+j.id+']+  '+'Stopped'.padEnd(24)+j.cmd}}
  C.code=k==='INT'?130:131;
  C.what=`🐧 The terminal driver turned ${k==='INT'?'Ctrl+C into <b>SIGINT</b>':'Ctrl+\\ into <b>SIGQUIT</b>'} for <b>every</b> process of the foreground group <b>${j.pgid}</b>: they ended (exit code ${C.code}). bash shows the prompt.`;
  return{out:k==='INT'?'^C':'^\\Quit (core dumped)'};
}

/* ---------- running a line ---------- */
const ex0=P.exec, pt0=P.ptable, ps0=P.c_ps, which0=P.c_which, cd0=P.c_cd, help0=P.c_help, reset0=P.reset, sort0=P.c_sort, sleep0=P.c_sleep, ls0=P.c_ls;
P.exec=function(line){return this.profile==='04'?run04(this,line):ex0.call(this,line)};
P.reset=function(){reset0.call(this);if(this.profile==='04'){const l=this.cli&&this.cli.live;delete this.cli;cli(this).live=l}};
function run04(sh,line){
  const C=cli(sh);if(!C.depth){C.changed=new Set();C.what='';tick(sh)}
  if(C.fg&&!C.depth)return{seq:[{note:'iso-demo: '+C.fg.cmd+' is running in the foreground: bash waits for it and does not read commands. Press Ctrl+C to end it or Ctrl+Z to stop it (or wait '+Math.ceil((C.fg.end-now())/1000)+' s).'}],procs:sh.procs};
  const L=lex(line);if(L.err){C.code=2;return{seq:[{err:'bash: '+L.err}].concat(L.open?[{note:'iso-demo: a real bash would show > and wait for the closing '+L.open+' on the next line'}]:[])}}
  const items=[];let cur=[];
  for(const t of L.toks){if(t.t==='op'&&['&&','||',';','&'].includes(t.v)){if(!cur.length){C.code=2;return{seq:[{err:"bash: syntax error near unexpected token `"+t.v+"'"}]}}items.push({toks:cur,sep:t.v});cur=[]}else cur.push(t)}
  if(cur.length)items.push({toks:cur,sep:''});
  const seq=[];let clear=false,edit=null,procs=[];
  for(let k=0;k<items.length;k++){
    const prev=k?items[k-1].sep:'';
    if(prev==='&&'&&C.code!==0)continue; if(prev==='||'&&C.code===0)continue;
    const text=items[k].toks.map(t=>t.raw).join(' ');
    const r=pipe04(sh,items[k].toks,items[k].sep==='&'&&!C.depth,text);
    if(r.clear){clear=true;seq.length=0}
    if(r.edit)edit=r.edit;
    seq.push(...(r.seq||[]));procs.push(...(r.procs||[]));
    C.code=r.code||0;
  }
  sh.procs=procs;
  seq.push(...notify(sh));
  return{seq,clear,edit,procs};
}
function resolve(sh,name,env){
  const C=cli(sh);
  if(name.includes('/'))return{route:name.startsWith('/')?'abs':'rel',file:'/'+S.split(sh.cwd,name).join('/')};
  if(C.alias[name])return{route:'alias',text:C.alias[name]};
  if(BUILTIN.has(name))return{route:'builtin'};
  const dirs=(env.PATH==null?'':env.PATH).split(':'),checked=[];
  for(const d of dirs){const dir=d===''?'.':d, p=(dir.endsWith('/')?dir:dir+'/')+name, x=S.lookup(sh.root,S.split(sh.cwd,p));
    const ok=!!x.node&&x.node.t!=='d';checked.push([d,ok]);
    if(ok)return{route:'found',file:'/'+x.real.join('/'),node:x.node,real:x.real,checked,dirs}}
  return{route:'missing',checked,dirs};
}
function pipe04(sh,toks,bg,text){
  const C=cli(sh),cmds=[[]];
  for(const t of toks){if(t.t==='op'&&t.v==='|')cmds.push([]);else cmds[cmds.length-1].push(t)}
  if(cmds.some(c=>!c.length))return{seq:[{err:"bash: syntax error near unexpected token `|'"}],code:2};
  const ctx=ctxOf(sh),ex=[];
  for(const c of cmds){const e=expandCmd(c,ctx);if(e.err)return{seq:[{err:'bash: '+e.err}],code:1};ex.push(e)}
  // only NAME=value (and redirects): variables of the shell itself
  if(ex.length===1&&!ex[0].argv.length){
    for(const[n,v]of ex[0].asg){C.vars[n]=v;C.changed.add(n);if(n==='PATH')C.last=null}
    for(const r of ex[0].red)if(r.to!=null){const t=sh.target(r.to,r.op==='<'?'<':/>>$/.test(r.op)?'>>':'>');if(t.err)return{seq:[{err:t.err}],code:1}}
    if(ex[0].asg.length){const n=ex[0].asg.map(a=>a[0]),e=n.filter(x=>C.exp.has(x));
      C.what=e.length===n.length?`<code>${n.join(', ')}</code> changed. ${e.length>1?'They are':'It is'} exported: the children started from now on get the new value.`
        :`<code>${n.filter(x=>!C.exp.has(x)).join(', ')}</code>: a <b>shell variable</b>, only this bash has it. The children do not get it until you <code>export</code> it.`}
    return{seq:[],procs:[],code:0}}
  for(const e of ex)if(e.argv.length&&e.plain0&&C.alias[e.argv[0]]){e.argv=C.alias[e.argv[0]].split(/\s+/).concat(e.argv.slice(1));e.alias=true}
  const hasSleep=ex.some(e=>{const a=e.argv[0]==='nohup'?e.argv.slice(1):e.argv;return a[0]==='sleep'});
  if(hasSleep&&(bg||C.live))return startJob(sh,ex,text,bg);
  // the PATH search, the way bash does it, for every command of the pipeline
  const env=envOf(C);
  C.nf=[];
  ex.forEach((e,i)=>{
    if(!e.argv.length)return;
    const name=e.argv[0],envC=Object.assign({},env,Object.fromEntries(e.asg)),r=resolve(sh,name,envC);
    if(i===0)C.last=Object.assign({name,alias:e.alias},r);
    if(r.route==='found'){
      const base=r.real[r.real.length-1];
      if(/^#!/.test(r.node.data||''))e.argv[0]=r.file;
      else if(sh['c_'+base]&&SYS(r.real))e.argv[0]=base;
      else{e.argv[0]='__na';C.nf.push(name)}
    }else if(r.route==='missing'){e.argv[0]='__nf';C.nf.push(name)}
  });
  // the words for the pipeline of the core shell (already expanded: quoted, so it does not expand them again)
  const list=[];
  ex.forEach((e,i)=>{if(i)list.push({op:'|'});
    for(const[n,v]of e.asg)list.push({w:n+'='+v,q:true});
    for(const a of e.argv)list.push({w:a,q:true});
    for(const r of e.red){if(r.op==='>&2'){list.push({op:'2>&1'});continue}list.push({op:r.op});if(r.to!=null)list.push({w:r.to,q:true})}});
  const keep=sh.vars;sh.vars=env;
  let r;try{r=P.pipeline.call(sh,list)}finally{sh.vars=keep}
  const lastE=ex[ex.length-1],c0=lastE.argv[0];
  if(c0&&!BUILTIN.has(c0)&&!['__nf','__na'].includes(c0))C.child={cmd:lastE.argv.join(' '),env:Object.assign({},sh.env),one:lastE.asg.map(a=>a[0]),pid:(r.procs[r.procs.length-1]||{}).pid};
  if(!C.whatSet&&ex[0].asg.length&&c0&&!BUILTIN.has(c0))C.what=`<code>${ex[0].asg.map(a=>a[0]+'='+esc(a[1])).join(' ')}</code> is only in the environment of <code>${esc(ex[0].argv[0].replace(/^.*\//,''))}</code>: bash does not keep it.`;
  C.whatSet=false;
  if(bg){const id=nextId(C),pid=(r.procs[r.procs.length-1]||{}).pid||sh.next++;
    const j={id,cmd:text,procs:r.procs.map(p=>({pid:p.pid,name:p.cmd.split(' ')[0]})),pgid:(r.procs[0]||{}).pid,state:r.code?'Exit '+r.code:'Done',end:0};
    C.jobs.push(j);touch(C,j);C.bg=pid;r.seq.unshift({out:'['+id+'] '+pid})}
  return r;
}

/* ---------- the builtins and commands of lecture 04 ---------- */
const only04=(name,fn)=>{const old=P[name];P[name]=function(a){return this.profile==='04'?fn.call(this,a,cli(this)):old?old.call(this,a):{err:'bash: '+name.slice(2)+': command not found',code:127}}};
P.c___nf=function(){const n=cli(this).nf.shift();return{err:'bash: '+n+': command not found',code:127}};
P.c___na=function(){const n=cli(this).nf.shift();return{err:'iso-demo: '+n+' is not available in this demo terminal',code:126}};
only04('c_export',function(a,C){
  if(!a.length||a[0]==='-p')return{out:[...C.exp].filter(n=>C.vars[n]!=null).sort().map(n=>'declare -x '+n+'="'+C.vars[n]+'"').join('\n')};
  let un=false;const err=[];
  for(const x of a){if(x==='-n'){un=true;continue}
    const m=x.match(/^([A-Za-z_]\w*)(?:=([\s\S]*))?$/);if(!m){err.push("bash: export: `"+x+"': not a valid identifier");continue}
    if(m[2]!=null)C.vars[m[1]]=m[2];
    if(un)C.exp.delete(m[1]);else C.exp.add(m[1]);C.changed.add(m[1])}
  const n=a.filter(x=>x!=='-n').map(x=>x.split('=')[0]);
  C.what=un?`<code>${n.join(', ')}</code> is a shell variable again: the children do not get it.`:`<code>${n.join(', ')}</code> is now an <b>environment variable</b>: every child started from now on gets a copy.`;C.whatSet=true;
  return{err:err.join('\n')||undefined,code:err.length?1:0};
});
only04('c_unset',function(a,C){for(const n of a){if(n.startsWith('-'))continue;delete C.vars[n];C.exp.delete(n);C.changed.add(n)}
  C.what=`<code>${a.filter(n=>!n.startsWith('-')).join(', ')}</code> deleted, from the shell and from the environment of the next children.`;C.whatSet=true;return{}});
only04('c_env',function(a){if(a.length)return{note:'iso-demo: this demo knows env without parameters; to set a variable for one command write NAME=value command'};
  return{out:Object.entries(this.env||{}).map(([k,v])=>k+'='+v).join('\n')}});
only04('c_printenv',function(a){const e=this.env||{};if(!a.length)return{out:Object.entries(e).map(([k,v])=>k+'='+v).join('\n')};
  const out=a.filter(n=>e[n]!=null).map(n=>e[n]);return{out:out.join('\n'),code:out.length===a.length?0:1}});
only04('c_cd',function(a,C){const old='/'+this.cwd.join('/'),r=cd0.call(this,a);if(!r.err){C.vars.OLDPWD=old;C.vars.PWD='/'+this.cwd.join('/');if(!C.exp.has('OLDPWD'))C.exp.add('OLDPWD')}return r});
only04('c_alias',function(a,C){if(!a.length)return{out:Object.entries(C.alias).map(([k,v])=>'alias '+k+"='"+v+"'").join('\n')};
  const err=[];for(const x of a){const m=x.match(/^([\w.-]+)=([\s\S]*)$/);if(m)C.alias[m[1]]=m[2];else if(!C.alias[x])err.push('bash: alias: '+x+': not found')}
  const show=a.filter(x=>!x.includes('=')&&C.alias[x]).map(x=>'alias '+x+"='"+C.alias[x]+"'");return{out:show.join('\n'),err:err.join('\n')||undefined}});
only04('c_shopt',function(a,C){
  if(a[0]==='-s'||a[0]==='-u'){if(a[1]!=='globstar')return{err:'iso-demo: this demo knows only shopt -s globstar and shopt -u globstar'};C.globstar=a[0]==='-s';return{}}
  return{out:'globstar       \t'+(C.globstar?'on':'off')}});
only04('c_trap',function(){return{note:'iso-demo: trap is for scripts: try it in the widget of the page "trap: your own handler"'}});
only04('c_exit',function(a,C){if(live(C).some(j=>/^Stopped/.test(j.state))&&!C.warned){C.warned=true;return{err:'There are stopped jobs.',code:1}}
  return{note:'iso-demo: exit would end this bash and close the terminal; the kernel would send SIGHUP to the session (see the chapter Sessions and terminals)'}});
only04('c_jobs',function(a,C){
  const l=a.includes('-l'),p=a.includes('-p'),m=marks(C);
  const out=C.jobs.slice().sort((x,y)=>x.id-y.id).map(j=>p?String(j.pgid):fmtJob(j,m.get(j),l));
  for(const j of C.jobs){if(!alive(j))j.told=true;j.stopNote=false}
  C.jobs=C.jobs.filter(j=>!j.told);
  C.what=C.jobs.length?'<code>jobs</code> lists the jobs of <b>this</b> shell: <b>+</b> the current job (used by <code>fg</code> and <code>bg</code> without a parameter), <b>-</b> the previous one.':'No jobs: nothing runs in the background, nothing is stopped.';C.whatSet=true;
  return{out:out.join('\n')};
});
only04('c_fg',function(a,C){
  const j=findJob(C,a[0],'fg');if(j.err)return{err:j.err,code:1};
  C.jobs=C.jobs.filter(x=>x!==j);C.order=C.order.filter(x=>x!==j);
  if(/^Stopped/.test(j.state)){j.state='Running';j.end=now()+(j.left||0)}
  j.viaFg=true;C.ev.add('fg');
  if(!C.live){C.what='The job is in the foreground: the demo skips the wait.';return{out:j.cmd}}
  C.fg=j;C.what=`Job <b>[${j.id}]</b> is in the <b>foreground</b> again (bash sent it <b>SIGCONT</b> if it was stopped): it gets the keyboard, bash waits.`;C.whatSet=true;
  return{out:j.cmd};
});
only04('c_bg',function(a,C){
  const j=findJob(C,a[0],'bg');if(j.err)return{err:j.err,code:1};
  if(j.state==='Running')return{err:'bash: bg: job '+j.id+' already in background'};
  j.state='Running';j.end=now()+(j.left||0);touch(C,j);C.ev.add('bg');
  C.what=`bash sent <b>SIGCONT</b> to group <b>${j.pgid}</b>: job <b>[${j.id}]</b> runs again, in the <b>background</b>.`;C.whatSet=true;
  return{out:'['+j.id+']+ '+j.cmd+' &'};
});
only04('c_kill',function(a,C){
  if(!a.length)return{err:'kill: usage: kill [-s sigspec | -n signum | -sigspec] pid | jobspec ... or kill -l [sigspec]',code:2};
  if(a[0]==='-l'||a[0]==='-L'){if(a[1]){const s=sigName(a[1]);return s?{out:/^\d+$/.test(a[1])?s:String(SIGS.indexOf(s))}:{err:'bash: kill: '+a[1]+': invalid signal specification',code:1}}return{out:KILL_L}}
  let sig='TERM',i=0;
  if(a[0]==='-s'||a[0]==='-n'){sig=sigName(a[1]||'');i=2}else if(/^-/.test(a[0])){sig=sigName(a[0].slice(1));i=1}
  if(!sig)return{err:'bash: kill: '+(a[i-1]||'').replace(/^-/,'')+': invalid signal specification',code:1};
  const err=[],done=[];
  for(const t of a.slice(i)){
    let j=null;
    if(t.startsWith('%')){j=findJob(C,t,'kill');if(j.err){err.push(j.err);continue}}
    else if(/^\d+$/.test(t)){const n=+t;
      if(n===this.pid||n===4100){if(sig==='KILL'||sig==='HUP'){err.push('iso-demo: SIG'+sig+' would end this bash at once and close the terminal (see the page "When bash is killed")');continue}
        done.push('bash ignored SIG'+sig+' (an interactive shell does)');continue}
      j=C.jobs.find(x=>!x.told&&x.procs.some(p=>p.pid===n))||(C.fg&&C.fg.procs.some(p=>p.pid===n)?C.fg:null);
      if(!j){if([1,1000].includes(n))err.push('bash: kill: ('+n+') - Operation not permitted');else if(n===4090)err.push('iso-demo: 4090 is the terminal emulator: killing it would close this window');else err.push('bash: kill: ('+n+') - No such process');continue}}
    else{err.push('bash: kill: '+t+': arguments must be process or job IDs');continue}
    const r=signal(C,j,sig);done.push('job ['+j.id+'] (group '+j.pgid+'): '+r);
  }
  C.what=done.length?`<code>kill</code> sent <b>SIG${sig}</b>: ${done.join('; ')}.`:C.what;C.whatSet=true;
  return{err:err.join('\n')||undefined,code:err.length?1:0};
});
only04('c_type',function(a,C){
  const all=a.includes('-a'),t=a.includes('-t'),out=[],err=[];
  for(const n of a.filter(x=>!/^-[at]+$/.test(x))){
    const r=[];
    if(C.alias[n])r.push(t?'alias':n+' is aliased to `'+C.alias[n]+"'");
    if(BUILTIN.has(n)&&n!=='reset')r.push(t?'builtin':n+' is a shell builtin');
    if(n.includes('/')){if(S.lookup(this.root,S.split(this.cwd,n)).node)r.push(t?'file':n+' is '+n)}
    else for(const d of (C.vars.PATH||'').split(':')){const p=(d||'.')+'/'+n,x=S.lookup(this.root,S.split(this.cwd,p));if(x.node&&x.node.t!=='d'){r.push(t?'file':n+' is '+(d?p.replace(/\/\//g,'/'):'./'+n));if(!all)break}}
    if(!r.length){if(!t)err.push('bash: type: '+n+': not found');continue}
    out.push(...(all?r:r.slice(0,1)));
  }
  return{out:out.join('\n'),err:err.join('\n')||undefined,code:err.length?1:0};
});
only04('c_which',function(a){
  const all=a.includes('-a'),out=[];let code=0;const PATH=(this.env||{}).PATH||'';
  for(const n of a.filter(x=>x!=='-a')){
    if(n.includes('/')){const x=S.lookup(this.root,S.split(this.cwd,n));if(x.node&&x.node.t!=='d')out.push(n);else code=1;continue}
    let f=0;for(const d of PATH.split(':')){if(!d)continue;const p=d.replace(/\/$/,'')+'/'+n,x=S.lookup(this.root,S.split(this.cwd,p));if(x.node&&x.node.t!=='d'){out.push(p);f++;if(!all)break}}
    if(!f)code=1}
  return{out:out.join('\n'),code};
});
only04('c_tty',function(){return this.stdin===null?{out:'/dev/pts/0'}:{out:'not a tty',code:1}});
only04('c_date',function(a){
  const tz=(this.env||{}).TZ||'Europe/Bucharest',d=new Date();let f;
  try{f=new Intl.DateTimeFormat('en-US',{timeZone:tz,hourCycle:'h23',year:'numeric',month:'short',day:'2-digit',weekday:'short',hour:'2-digit',minute:'2-digit',second:'2-digit',timeZoneName:'short'})}
  catch(e){f=new Intl.DateTimeFormat('en-US',{timeZone:'UTC',hourCycle:'h23',year:'numeric',month:'short',day:'2-digit',weekday:'short',hour:'2-digit',minute:'2-digit',second:'2-digit',timeZoneName:'short'})}
  const P=Object.fromEntries(f.formatToParts(d).map(x=>[x.type,x.value]));
  const mo=String(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'].indexOf(P.month)+1).padStart(2,'0');
  const Z=(P.timeZoneName||'UTC').replace(/^GMT\+2$/,'EET').replace(/^GMT\+3$/,'EEST').replace(/^GMT\+9$/,'JST');
  const map={H:P.hour,M:P.minute,S:P.second,Y:P.year,m:mo,d:P.day,e:String(+P.day).padStart(2),a:P.weekday,b:P.month,Z,T:P.hour+':'+P.minute+':'+P.second,F:P.year+'-'+mo+'-'+P.day,'%':'%'};
  if(a[0]&&a[0].startsWith('+'))return{out:a[0].slice(1).replace(/%(.)/g,(m,c)=>map[c]!=null?map[c]:m)};
  if(a.length)return{err:"date: invalid date '"+a[0]+"'",code:1};
  return{out:P.weekday+' '+P.month+' '+map.e+' '+map.T+' '+Z+' '+P.year};
});
only04('c_nohup',function(a){if(!a.length)return{err:"nohup: missing operand\nTry 'nohup --help' for more information.",code:125};
  const r=this.exec(a.map(x=>"'"+x.replace(/'/g,"'\\''")+"'").join(' '));return{seq:[{err:'nohup: ignoring input'}].concat(r.seq||[])}});
only04('c_sort',function(a){if((this.env||{}).LANG!=='C'&&(this.env||{}).LC_ALL!=='C')return sort0.call(this,a);
  const o=this.opts(a,'rnu','sort');if(o.err)return{err:o.err};const r=this.inputs(o.ops,'sort');if(r.wait)return{note:r.wait};
  let l=this.lines(r).sort((x,y)=>x<y?-1:x>y?1:0);if(o.o.r)l.reverse();if(o.o.u)l=l.filter((x,i)=>i===0||x!==l[i-1]);return{out:l.join('\n'),err:r.err}});
only04('c_ls',function(a){const r=ls0.call(this,a);if(r.err&&/cannot access/.test(r.err))r.code=2;return r});
only04('c_sleep',function(a,C){if(!a.length)return{err:"sleep: missing operand\nTry 'sleep --help' for more information."};return{}});
/* a child bash: a copy of the environment, nothing else */
function child(sh,fn){
  const C=cli(sh);if(C.depth>4)return{err:'iso-demo: too many shells inside shells',code:1};
  const save={vars:C.vars,exp:C.exp,code:C.code,alias:C.alias,fg:C.fg,last:C.last,child:C.child,what:C.what,pid:sh.pid,self:sh.self,procs:sh.procs,changed:C.changed,nf:C.nf};
  const env=Object.assign({},sh.env||{});
  C.vars=env;C.exp=new Set(Object.keys(env));C.alias={};C.fg=null;C.depth++;C.changed=new Set();sh.pid=sh.self?sh.self.pid:sh.pid;
  let r;try{r=fn()}finally{C.depth--;const code=C.code;Object.assign(C,{vars:save.vars,exp:save.exp,alias:save.alias,fg:save.fg,last:save.last,child:save.child,changed:save.changed,nf:save.nf});C.code=save.code;sh.pid=save.pid;sh.self=save.self;sh.procs=save.procs;r.code=code}
  return r;
}
function script(sh,node){
  const seq=[];
  for(const l of node.data.split('\n').slice(1)){if(!l.trim()||l.trim().startsWith('#'))continue;const r=run04(sh,l);seq.push(...(r.seq||[]).filter(x=>!x.note))}
  return{seq};
}
only04('c_bash',function(a,C){
  if(a[0]==='-c'){if(a[1]==null)return{err:'bash: -c: option requires an argument',code:2};
    const n=Object.keys(this.env||{}).length;
    const r=child(this,()=>{const x=run04(this,a[1]);return{seq:x.seq}});
    C.what=`A child <code>bash</code> (PID ${this.self.pid}) started with a <b>copy</b> of the environment (${n} variables) and ran <code>${esc(a[1])}</code>. Shell variables that were not exported are not in it.`;C.whatSet=true;
    return{seq:r.seq,code:r.code}}
  if(a[0]){const x=S.lookup(this.root,S.split(this.cwd,a[0]));if(!x.node)return{err:'bash: '+a[0]+': No such file or directory',code:127};
    return child(this,()=>script(this,x.node))}
  return{note:"iso-demo: a new interactive bash is not part of this demo: use bash -c 'COMMANDS'"};
});
P.runFile=(old=>function(cmd,args){
  if(this.profile!=='04')return old?old.call(this,cmd,args):{err:'bash: '+cmd+': No such file or directory',code:127};
  const x=S.lookup(this.root,S.split(this.cwd,cmd));
  if(x.err)return{err:'bash: '+cmd+': '+x.err,code:127};
  if(x.node.t==='d')return{err:'bash: '+cmd+': Is a directory',code:126};
  const base=x.real[x.real.length-1];
  if(/^#!/.test(x.node.data||'')){if(!x.node.exe)return{err:'bash: '+cmd+': Permission denied',code:126};return child(this,()=>script(this,x.node))}
  if(SYS(x.real)&&this['c_'+base]&&!BUILTIN.has(base)||SYS(x.real)&&['echo','pwd','kill','true','false'].includes(base))return this['c_'+base](args);
  if(!x.node.exe&&!SYS(x.real))return{err:'bash: '+cmd+': Permission denied',code:126};
  return{err:'iso-demo: '+cmd+' is a program this demo terminal cannot run',code:126};
})(P.runFile);

/* ---------- ps for lecture 04: the groups and the session ---------- */
P.ptable=function(){
  if(this.profile!=='04')return pt0.call(this);
  const C=cli(this),U='student';
  const T=[{pid:1,ppid:0,pgid:1,sid:1,stat:'Ss',comm:'systemd',cmd:'/sbin/init',tty:'?',user:'root'},
    {pid:1000,ppid:1,pgid:1000,sid:1000,stat:'Ss',comm:'systemd',cmd:'/usr/lib/systemd/systemd --user',tty:'?',user:U},
    {pid:4090,ppid:1000,pgid:4090,sid:4090,stat:'Ssl',comm:'foot',cmd:'foot',tty:'?',user:U},
    {pid:4100,ppid:4090,pgid:4100,sid:4100,stat:'Ss',comm:'bash',cmd:'bash',tty:'pts/0',user:U}];
  for(const j of live(C).concat(C.fg?[C.fg]:[]))for(const p of j.procs)T.push({pid:p.pid,ppid:4100,pgid:j.pgid,sid:4100,stat:(/^Stopped/.test(j.state)?'T':'S')+(j===C.fg?'+':''),comm:p.name,cmd:p.args||p.name,tty:'pts/0',user:U});
  if(this.self&&this.self.pid!==4100)T.push({pid:this.self.pid,ppid:4100,pgid:this.self.pid,sid:4100,stat:'R+',comm:this.self.comm.replace(/^.*\//,''),cmd:this.self.args.join(' '),tty:'pts/0',user:U});
  return T;
};
only04('c_ps',function(a){
  let all=false,full=false,cols=null,sid=null;
  for(let i=0;i<a.length;i++){const x=a[i];
    if(x==='-o'){cols=(a[++i]||'').split(',');continue}
    if(x==='-s'){sid=+a[++i];continue}
    if(x==='aux'||x==='-aux'||x==='ax')return{note:'iso-demo: this demo knows ps, ps -e, ps -f, ps -o COLUMNS and ps -s SID'};
    if(/^-[efA]+$/.test(x)){if(/[eA]/.test(x))all=true;if(x.includes('f'))full=true;continue}
    return{err:'error: unsupported option '+x+' (this demo knows -e, -f, -o, -s)'}}
  const pad=(s,n,r)=>{s=String(s);return r?s.padStart(n):s.padEnd(n)};
  const K={pid:['PID',7,1,p=>p.pid],ppid:['PPID',7,1,p=>p.ppid],pgid:['PGID',7,1,p=>p.pgid],sid:['SID',7,1,p=>p.sid],stat:['STAT',4,0,p=>p.stat],comm:['COMMAND',0,0,p=>p.comm],cmd:['CMD',0,0,p=>p.cmd],args:['COMMAND',0,0,p=>p.cmd],
    tty:['TTY',8,0,p=>p.tty],tt:['TT',8,0,p=>p.tty],time:['TIME',8,1,()=>'00:00:00'],user:['USER',8,0,p=>p.user],uid:['UID',8,0,p=>p.user],c:['C',1,1,()=>'0'],stime:['STIME',5,0,()=>'09:12']};
  if(!cols)cols=full?['uid','pid','ppid','c','stime','tty','time','cmd']:['pid','tty','time','comm'];
  const k=Object.assign({},K);if(!full&&!a.includes('-o'))k.comm=['CMD',0,0,p=>p.comm];
  for(const c of cols)if(!k[c])return{err:'error: unknown user-defined format specifier "'+c+'"'};
  const rows=this.ptable().filter(p=>sid!=null?p.sid===sid:all||p.tty==='pts/0');
  const fmt=v=>cols.map((c,i)=>{const[,w,r]=k[c];const x=String(v(c));return i===cols.length-1?x:pad(x,w,r)}).join(' ');
  return{out:[fmt(c=>k[c][0])].concat(rows.map(p=>fmt(c=>k[c][3](p)))).join('\n')};
});
only04('c_help',function(){return{out:'this is a demo terminal (a simulation, not a real Linux)\n'+
  'variables: NAME=value  export  unset  env  printenv  echo $NAME  $? $$ $!  bash -c \'...\'\n'+
  'jobs:      sleep N &  jobs  fg  bg  kill  nohup  ps -o pid,pgid,sid,stat,comm  (Ctrl+C, Ctrl+Z, Ctrl+\\)\n'+
  'commands:  type  which  ./hello  alias  shopt -s globstar  date  tty\n'+
  'files:     ls cd pwd cat cp mv rm mkdir touch tree find sort wc head tail grep\n'+
  'quotes "..." \'...\' and \\, globs * ? [..] {a,b} **, redirects < > >> 2> &> 2>&1, pipes |, ; && ||'}});
Object.assign(S.MAN,{
  export:['export - mark variables as environment variables (a bash builtin)','export NAME[=VALUE]...\nexport -p\nexport -n NAME','the children started after it get a copy of NAME\n-p  list the exported variables\n-n  make NAME a shell variable again'],
  unset:['unset - delete variables (a bash builtin)','unset NAME...'],
  env:['env - print the environment','env','NAME=value lines, one for every environment variable'],
  printenv:['printenv - print all or part of the environment','printenv [NAME]...'],
  jobs:['jobs - list the jobs of this shell (a bash builtin)','jobs [-l] [-p]','-l  also the PIDs\n-p  only the PIDs\n+ the current job, - the previous one'],
  fg:['fg - move a job to the foreground (a bash builtin)','fg [%JOB]','sends SIGCONT if the job is stopped; no JOB: the current one (+)'],
  bg:['bg - continue a stopped job in the background (a bash builtin)','bg [%JOB]','sends SIGCONT'],
  kill:['kill - send a signal to a process or a job (a bash builtin)','kill [-SIGNAL] PID|%JOB...\nkill -l','-SIGNAL  a name (-TERM, -KILL, -STOP, -CONT) or a number (-9); TERM by default\n-l       list the signals\n%1       job 1 of this shell'],
  type:['type - how the shell runs a name (a bash builtin)','type [-a] [-t] NAME...','alias, shell builtin or the file found in PATH\n-a  every match\n-t  only the kind: alias, builtin, file'],
  which:['which - locate a command','which [-a] COMMAND...','searches the directories of $PATH, from left to right\n-a  print every match, not only the first\nnothing found: no output, exit status 1'],
  tty:['tty - print the file name of the terminal connected to standard input','tty'],
  date:['date - print the date and the time','date [+FORMAT]','%H hour, %M minute, %S second, %Y year, %m month, %d day, %Z time zone\nTZ=Asia/Tokyo date  the time in Tokyo'],
  nohup:['nohup - run a command immune to hangups','nohup COMMAND [ARG]...','the command ignores SIGHUP: it keeps running when the terminal closes'],
  bash:['bash - GNU Bourne-Again SHell','bash [-c STRING] [FILE]','-c STRING  run the commands of STRING in a new bash (a child process)'],
  alias:['alias - define or show aliases (a bash builtin)','alias [NAME[=VALUE]]...','alias ll=\'ls -l\''],
  shopt:['shopt - shell options (a bash builtin)','shopt [-s|-u] OPTION','-s globstar  ** matches any directories\n-u globstar  turn it off'],
  exit:['exit - exit the shell (a bash builtin)','exit [N]'],
  sleep:['sleep - wait for a number of seconds','sleep NUMBER[s|m|h]','in this terminal it really waits: add & to run it in the background'],
});

/* ================================================================ 6. the side panels */
const sideNote=(C,dflt)=>C.what||dflt?`<div class="cx-note" role="status"><b class="cx-nh">What happened</b> ${C.what||dflt}</div>`:'';
function jobsModel(sh){
  const C=cli(sh),m=marks(C),t=now();
  const left=j=>j.state==='Running'&&j.end!=null?'⏳ '+Math.max(0,Math.ceil((j.end-t)/1000))+' s':/^Stopped/.test(j.state)?'⏸ stopped':'';
  const groups=[{pgid:4100,label:C.fg?'the shell, waits':'<b>foreground</b>',fg:!C.fg,procs:[{n:'bash',pid:4100,sl:true}]}];
  const js=live(C).slice().sort((a,b)=>a.id-b.id);if(C.fg)js.push(C.fg);
  for(const j of js){const fg=j===C.fg;
    groups.push({pgid:j.pgid,label:fg?'<b>foreground</b>':'job ['+j.id+']'+(m.get(j)||''),fg,state:/^Stopped/.test(j.state)?'stop':'run',note:left(j),
      procs:j.procs.map(p=>({n:p.name,pid:p.pid,lead:p.pid===j.pgid,nohup:p.nohup}))})}
  return{sid:4100,input:C.fg?'⌨ input → group '+C.fg.pgid+' (foreground)':'⌨ input → bash (foreground)',groups,legend:true};
}
const SIDE=window.ISO_SIDE||(window.ISO_SIDE={});
SIDE.jobs={draw(sh,el,api){
  const C=cli(sh);C.live=true;
  const w=el.closest('.wd');if(w)w.classList.toggle('cx-fg',!!C.fg);
  el.innerHTML=`<div class="cx-jl">`+sideNote(C,'Start a job: <code>sleep 100 &amp;</code>. The session shows its group.')+`<div class="cx-keys"><span>keys for the foreground:</span>${[['INT','Ctrl+C'],['TSTP','Ctrl+Z'],['QUIT','Ctrl+\\']].map(([k,l])=>`<button type="button" class="btn${C.fg||k==='INT'?'':' ghost'}" data-k="${k}"${C.fg||k==='INT'?'':' disabled'}>${l}</button>`).join('')}</div></div>`+sess(jobsModel(sh));
  const press=k=>{const r=key(sh,k);if(r.out)api.print('<span class="cx-sig">'+esc(r.out)+'</span>','');const i=w&&w.querySelector('[data-r="in"]');if(i&&k==='INT')i.value='';api.draw()};
  el.querySelectorAll('[data-k]').forEach(b=>b.addEventListener('click',()=>{press(b.dataset.k);const i=w&&w.querySelector('[data-r="in"]');if(i)i.focus({preventScroll:true})}));
  if(w&&!w._cx){w._cx=true;
    const i=w.querySelector('[data-r="in"]');
    if(i)i.addEventListener('keydown',e=>{if(!e.ctrlKey)return;const k=e.key==='c'||e.key==='C'?'INT':e.key==='z'||e.key==='Z'?'TSTP':e.key==='\\'?'QUIT':null;if(!k)return;if(k==='INT'&&!C.fg&&getSelection().toString())return;e.preventDefault();press(k)});
    const t=setInterval(()=>{if(!document.body.contains(w)){clearInterval(t);return}const ch=tick(sh);if(ch||C.fg||C.jobs.some(j=>j.state==='Running'))api.draw()},1000);
  }
}};
SIDE.vars={draw(sh,el){
  const C=cli(sh),names=Object.keys(C.vars);
  const row=n=>`<tr class="${C.changed.has(n)?'ch':''}${C.exp.has(n)?'':' sv'}"><td>${esc(n)}</td><td>${esc(C.vars[n])}</td><td><span class="cx-tag ${C.exp.has(n)?'env':'sh'}">${C.exp.has(n)?'environment':'shell only'}</span></td></tr>`;
  const gone=[...C.changed].filter(n=>C.vars[n]==null);
  const ch=C.child;
  el.innerHTML=sideNote(C,C.child?'':'Create a variable: <code>GREETING=hello</code>.')+`<div class="cx-vt"><div class="fdh"><b>bash</b> · PID 4100 · its variables</div><table class="cx-t">${names.map(row).join('')}${gone.map(n=>`<tr class="x"><td>${esc(n)}</td><td colspan="2">deleted</td></tr>`).join('')}</table></div>`+
  (ch?`<div class="cx-arr">fork + exec ↓ a <b>copy</b> of the environment</div><div class="cx-vt kid"><div class="fdh"><b>${esc(ch.cmd.length>34?ch.cmd.slice(0,32)+'…':ch.cmd)}</b>${ch.pid?' · PID '+ch.pid:''} · the last child</div><table class="cx-t">${Object.entries(ch.env).map(([k,v])=>`<tr class="${ch.one.includes(k)?'ch':''}"><td>${esc(k)}</td><td>${esc(v)}</td><td>${ch.one.includes(k)?'<span class="cx-tag one">only this command</span>':''}</td></tr>`).join('')}</table></div>`:'<p class="cx-hint">Run an external command (<code>printenv</code>, <code>bash -c \'...\'</code>): the environment it got shows up here.</p>');
}};
SIDE.path={draw(sh,el){
  const C=cli(sh),L=C.last,dirs=(C.vars.PATH||'').split(':');
  let route='<p class="cx-hint">Run a command: the panel shows how bash found the file to start.</p>';
  if(L){const n=`<code>${esc(L.name)}</code>`;
    route=`<div class="cx-route"><b>${n}</b> → `+({abs:'starts with <code>/</code>: an <b>absolute path</b>, used as it is: <code>'+esc(L.file)+'</code>',
      rel:'contains a <code>/</code>: a <b>relative path</b>, from the current directory: <code>'+esc(L.file)+'</code>',
      alias:'an <b>alias</b>: replaced with <code>'+esc(L.text||'')+'</code>',builtin:'a <b>builtin</b>: bash runs it itself, no new process, no file',
      found:'searched in <code>PATH</code>, the <b>first match</b> wins: <code>'+esc(L.file)+'</code>',missing:'not in any directory of <code>PATH</code>: <b>command not found</b> (the current directory is not searched)'})[L.route]+'</div>'}
  const ck=L&&L.checked?new Map(L.checked.map(([d,ok])=>[d,ok])):new Map();
  el.innerHTML=sideNote(C,'')+route+`<div class="cx-ph">PATH, from left to right</div><ol class="cx-path">${dirs.map(d=>{const has=ck.has(d),ok=ck.get(d);
    return `<li class="${has?ok?'ok':'no':''}"><code>${esc(d||'(empty: .)')}</code><span>${has?ok?'✓ '+esc(L.name)+' is here':'✗ no '+esc(L.name):L&&L.route==='found'?'not checked':''}</span></li>`}).join('')}</ol>`;
}};

/* ================================================================ 7. the missions */
const node=(sh,p)=>S.lookup(sh.root,S.split(S.HOME,p)).node;
const M=window.ISO_MSETS||(window.ISO_MSETS={});
M.jobs04=[
  {t:'Start <code>sleep 100</code> in the <b>background</b>.',h:'add & at the end',ok:(sh,c)=>/&\s*$/.test(c)&&/^\s*sleep\b/.test(c)&&cli(sh).jobs.some(j=>/sleep/.test(j.cmd)&&j.state==='Running')},
  {t:'Start a second one, <code>sleep 200 &amp;</code>, then list the jobs of this shell.',h:'jobs',ok:(sh,c,o)=>/^jobs\b/.test(c)&&/^\[2\]/m.test(o)},
  {t:'End job <code>[1]</code> using its <b>job ID</b>, not its PID.',h:'kill %1',ok:(sh,c,o)=>/^kill\b.*%1\b/.test(c)&&/^\[1\].*(Terminated|Killed|Interrupt)/m.test(o)},
  {t:'Run <code>sleep 60</code> in the <b>foreground</b>, stop it with <kbd>Ctrl</kbd>+<kbd>Z</kbd>, then look at it with <code>jobs</code>.',h:'sleep 60, Ctrl+Z (the key or the button), jobs',ok:(sh,c,o)=>/^jobs\b/.test(c)&&/Stopped/.test(o)&&cli(sh).ev.has('TSTP')},
  {t:'Let the stopped job continue in the <b>background</b>.',h:'bg %N (or bg: the current job)',ok:(sh,c)=>/^bg\b/.test(c)&&cli(sh).ev.has('bg')},
  {t:'Bring a job back to the <b>foreground</b>, end it with <kbd>Ctrl</kbd>+<kbd>C</kbd>, then print the exit code.',h:'fg %N, Ctrl+C, echo $?',ok:(sh,c,o)=>cli(sh).ev.has('fgINT')&&/^echo\s+\$\?/.test(c)&&/^130$/m.test(o)},
  {t:'Show the process group and the session of every process of this terminal.',h:'ps -o pid,pgid,sid,stat,comm',ok:(sh,c,o)=>/^ps\b/.test(c)&&/PGID/.test(o)&&/SID/.test(o)},
];
M.env04=[
  {t:'Print the value of <code>HOME</code> with <code>echo</code>.',h:'echo $HOME',ok:(sh,c,o)=>/\$\{?HOME/.test(c)&&/\/home\/student/.test(o)},
  {t:'Create a shell variable <code>GREETING=hello</code> and check that a child does <b>not</b> get it.',h:"GREETING=hello, then bash -c 'echo \"child: $GREETING\"'",ok:(sh,c,o)=>{const C=cli(sh);return C.vars.GREETING!=null&&!C.exp.has('GREETING')&&/^bash\s+-c/.test(c)&&/^child: ?$/m.test(o)}},
  {t:'<code>export</code> it, then run the same <code>bash -c</code> again.',h:'export GREETING',ok:(sh,c,o)=>{const C=cli(sh);return C.exp.has('GREETING')&&/^bash\s+-c/.test(c)&&o.includes('child: '+C.vars.GREETING)}},
  {t:'Print the hour in Tokyo with <code>date +%H:%M</code>, without giving the shell a <code>TZ</code> variable.',h:'TZ=Asia/Tokyo date +%H:%M',ok:(sh,c)=>/^TZ=\S+\s+date\b/.test(c)&&cli(sh).vars.TZ==null},
  {t:'Sort <code>fruits.txt</code> in byte order, with <code>LANG=C</code> only for <code>sort</code>.',h:'LANG=C sort fruits.txt',ok:(sh,c,o)=>/LANG=C\s+sort/.test(c)&&/^Cherry\nDate\napple\nbanana$/m.test(o)},
  {t:'Run a command that fails, then print its exit code.',h:'ls /nope, then echo $?',ok:(sh,c,o)=>/^echo\s+\$\?/.test(c)&&/^[1-9]\d*$/m.test(o)},
  {t:'Delete <code>GREETING</code>.',h:'unset',ok:(sh,c)=>/^unset\b.*GREETING/.test(c)&&cli(sh).vars.GREETING==null},
];
M.quote04=[
  {t:'Create an empty file named <code>my file.txt</code>, with the space.',h:'touch "my file.txt" (or my\\ file.txt)',ok:sh=>!!node(sh,'~/my file.txt')},
  {t:'Print the text <code>$HOME</code> itself, not its value.',h:"single quotes, or \\$",ok:(sh,c,o)=>/^\$HOME$/m.test(o)},
  {t:'Print <code>it\'s</code> with <code>echo</code>.',h:"double quotes around it, or it\\'s",ok:(sh,c,o)=>/^it's$/m.test(o)},
  {t:'Print the photos that have a <b>digit</b> after <code>photo</code>.',h:'[0-9]',ok:(sh,c,o)=>/photo1\.png photo2\.png photo3\.png/.test(o)&&!/photoA/.test(o)},
  {t:'Turn on <code>globstar</code> and print every <code>.txt</code> file under <code>docs</code>.',h:'shopt -s globstar, then echo docs/**/*.txt',ok:(sh,c,o)=>/docs\/2026\/exam\.txt/.test(o)&&/docs\/plan\.txt/.test(o)},
  {t:'Create <code>a.pdf</code>, <code>b.pdf</code> and <code>c.pdf</code> with <b>one</b> <code>touch</code>.',h:'braces: {a,b,c}.pdf',ok:(sh,c)=>/\{/.test(c)&&['a','b','c'].every(x=>!!node(sh,'~/'+x+'.pdf'))},
];
M.path04=[
  {t:'Ask the shell what <code>cd</code> and <code>sort</code> are, with one command.',h:'type cd sort',ok:(sh,c,o)=>/^type\b/.test(c)&&/cd is a shell builtin/.test(o)&&/sort is \//.test(o)},
  {t:'Print <b>every</b> <code>sort</code> of <code>PATH</code>, in the order of the search.',h:'which -a sort',ok:(sh,c,o)=>/\/usr\/bin\/sort\n\/bin\/sort/.test(o)},
  {t:'Run the <code>hello</code> script of your home directory.',h:'hello alone is not found: ./hello',ok:(sh,c,o)=>/\//.test(c)&&/^Hello!$/m.test(o)},
  {t:'Run the <code>hello</code> of <code>/home/tools</code> with a <b>relative</b> path.',h:'../tools/hello',ok:(sh,c,o)=>/^\.\.?\//.test(c)&&/Hello from tools!/.test(o)},
  {t:'Make <code>hello</code> work <b>without</b> a path: copy it into the first directory of <code>PATH</code>.',h:'cp hello ~/.local/bin/, then hello',ok:(sh,c,o)=>/^hello\b/.test(c)&&/^Hello!$/m.test(o)},
  {t:'Set <code>PATH=/tmp</code>: now <code>ls</code> is not found. Run it anyway.',h:'with its absolute path: /bin/ls',ok:(sh,c)=>cli(sh).vars.PATH==='/tmp'&&/^\/(usr\/)?bin\/ls\b/.test(c)},
];
Object.assign(ISOCLI,{cli,key,tick,jobsModel,run04});
if(typeof module!=='undefined')module.exports=ISOCLI;
})();
