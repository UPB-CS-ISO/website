/* ISO demo shell, lecture 07: git in ~/project.
   A small model of git: a commit is a snapshot (path -> text) with parents, the index is a snapshot,
   the working tree is the folder of the demo shell. GitHub is a second set of branches (remote),
   origin/* is what the last fetch saw. Pure logic, plus the side panel of the git terminal. */
(()=>{'use strict';
const S=ISOSH, {split,lookup}=S;
const REPO=['home','student','project'], URL='git@github.com:student/project.git', WEB='github.com:student/project.git';
const README0='# project\n\nThe sum of 1 + 2 + ... + MAX, for the ISO lab.\n';
const IGNORE0='# files made by the build\n*.o\napp\n';
/* colors in the terminal (shell-ui maps them to spans): green, red, yellow, end */
const GR='\u0006', RD='\u0007', YL='\u000e', EN='\u0002';

/* the project of lecture 07 (shell-make.js), plus the files of the repository */
const P0=S.PROFILES['07'];
S.PROFILES['07']=(fs,h,variant)=>{
  P0(fs,h,variant==='git'?'short':variant);
  if(variant!=='git')return;
  const p=fs.c.home.c.student.c.project, at=h.t(9,14,9,50);
  p.c['README.md']=h.F(README0,null,at); p.c['.gitignore']=h.F(IGNORE0,null,at);
  p.c['.git']=h.D({HEAD:h.F('ref: refs/heads/main\n',null,at),config:h.F('[remote "origin"]\n\turl = '+URL+'\n[branch "main"]\n\tremote = origin\n[pull]\n\trebase = false\n',null,at)},at);
};

/* ---------- small helpers ---------- */
const hx=s=>{let a=0x811c9dc5,b=0x9747b28c;for(let i=0;i<s.length;i++){const c=s.charCodeAt(i);a=Math.imul(a^c,0x01000193)>>>0;b=Math.imul(b^c,0x5bd1e995)>>>0;b=(b^(b>>>13))>>>0}return a.toString(16).padStart(8,'0')+b.toString(16).padStart(8,'0')};
const lines=t=>t==null||t===''?[]:t.replace(/\n$/,'').split('\n');
const text=ls=>ls.length?ls.join('\n')+'\n':'';
const keys=(...o)=>[...new Set(o.flatMap(x=>Object.keys(x||{})))].sort();
const globRe=p=>new RegExp('^'+p.replace(/[.+^${}()|[\]\\]/g,'\\$&').replace(/\*/g,'[^/]*').replace(/\?/g,'.')+'$');
const pl=(n,w)=>n+' '+w+(n===1?'':'s');
const MON=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'], DAY=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const date=t=>{const d=new Date(t);return DAY[d.getUTCDay()]+' '+MON[d.getUTCMonth()]+' '+d.getUTCDate()+' '+String(d.getUTCHours()).padStart(2,'0')+':'+String(d.getUTCMinutes()).padStart(2,'0')+':00 2026 +0300'};

/* the line diff (LCS): [[op, line, i, j]], op ' ' '-' '+' */
function ldiff(a,b){
  const n=a.length,m=b.length,L=[];for(let i=0;i<=n;i++)L.push(new Uint16Array(m+1));
  for(let i=n-1;i>=0;i--)for(let j=m-1;j>=0;j--)L[i][j]=a[i]===b[j]?L[i+1][j+1]+1:Math.max(L[i+1][j],L[i][j+1]);
  const ops=[];let i=0,j=0;
  while(i<n||j<m){
    if(i<n&&j<m&&a[i]===b[j]){ops.push([' ',a[i],i,j]);i++;j++}
    else if(i<n&&(j===m||L[i+1][j]>=L[i][j+1])){ops.push(['-',a[i],i,j]);i++}
    else{ops.push(['+',b[j],i,j]);j++}
  }
  return ops;
}
const nstat=(a,b)=>{const o=ldiff(lines(a),lines(b));return[o.filter(x=>x[0]==='+').length,o.filter(x=>x[0]==='-').length]};
function unified(a,b,name,color){
  const A=lines(a),B=lines(b),ops=ldiff(A,B),C=3;
  const ch=ops.map((o,k)=>o[0]!==' '?k:-1).filter(k=>k>=0);
  if(!ch.length)return '';
  const c=(code,t)=>color?code+t+EN:t;
  const hunks=[];let s=Math.max(0,ch[0]-C),e=Math.min(ops.length,ch[0]+C+1);
  for(const k of ch.slice(1)){if(k-C<=e)e=Math.min(ops.length,k+C+1);else{hunks.push([s,e]);s=Math.max(0,k-C);e=Math.min(ops.length,k+C+1)}}
  hunks.push([s,e]);
  const out=[c(YL,'diff --git a/'+name+' b/'+name)];
  if(a==null)out.push(c(YL,'new file mode 100644'));if(b==null)out.push(c(YL,'deleted file mode 100644'));
  out.push(c(YL,a==null?'--- /dev/null':'--- a/'+name),c(YL,b==null?'+++ /dev/null':'+++ b/'+name));
  for(const[s,e]of hunks){const seg=ops.slice(s,e);
    const ol=seg.filter(o=>o[0]!=='+').length, nl=seg.filter(o=>o[0]!=='-').length;
    out.push(c(YL,`@@ -${ol?seg[0][2]+1:seg[0][2]},${ol} +${nl?seg[0][3]+1:seg[0][3]},${nl} @@`));
    seg.forEach(o=>out.push(o[0]==='+'?c(GR,'+'+o[1]):o[0]==='-'?c(RD,'-'+o[1]):' '+o[1]))}
  return out.join('\n');
}
/* the changes of `other` against `base`: [{s,e,ls}] base[s..e) becomes ls */
function changes(base,other){
  const out=[];let cur=null;
  for(const o of ldiff(base,other)){
    if(o[0]===' '){if(cur){out.push(cur);cur=null}continue}
    if(!cur)cur={s:o[2],e:o[2],ls:[]};
    if(o[0]==='-')cur.e=o[2]+1;else cur.ls.push(o[1]);
  }
  if(cur)out.push(cur);
  return out;
}
/* a three-way merge of one file: {t} or {t, conflict:true} with the markers of git */
function merge3(b,o,t,oname,tname){
  if(o===t)return{t:o};if(b===o)return{t};if(b===t)return{t:o};
  if(o==null||t==null)return{t:o==null?t:o,conflict:true,kind:'modify/delete'};
  const B=lines(b),co=changes(B,lines(o)).map(c=>({...c,w:'o'})),ct=changes(B,lines(t)).map(c=>({...c,w:'t'}));
  const all=co.concat(ct).sort((x,y)=>x.s-y.s||x.e-y.e);
  const groups=[];
  for(const c of all){const g=groups[groups.length-1];if(g&&c.s<=g.e){g.cs.push(c);g.e=Math.max(g.e,c.e)}else groups.push({s:c.s,e:c.e,cs:[c]})}
  const apply=(g,w)=>{const r=[];let p=g.s;for(const c of g.cs.filter(c=>c.w===w)){r.push(...B.slice(p,c.s),...c.ls);p=c.e}r.push(...B.slice(p,g.e));return r};
  const out=[];let p=0,conflict=false;
  for(const g of groups){
    out.push(...B.slice(p,g.s));p=g.e;
    const ro=apply(g,'o'),rt=apply(g,'t'),ws=new Set(g.cs.map(c=>c.w));
    if(ws.size===1||ro.join('\n')===rt.join('\n'))out.push(...(ws.has('o')?ro:rt));
    else{conflict=true;out.push('<<<<<<< '+oname,...ro,'=======',...rt,'>>>>>>> '+tname)}
  }
  out.push(...B.slice(p));
  return{t:text(out),conflict};
}

/* ---------- the repository ---------- */
function newGit(sh){
  const G={commits:{},ord:0,clock:Date.UTC(2026,9,14,7,0),br:{},head:'main',up:new Set(['main']),origin:{},remote:{},
    index:{},known:new Set(),merging:null,unmerged:new Set(),cfg:{},col:0,note:'',hot:''};
  sh.git=G;
  const w=readWT(sh)||{};
  const c0=mk(G,{'README.md':README0,'.gitignore':IGNORE0},[],'Initial commit','teacher','main');
  const c1=mk(G,w,[c0],'Add the sum program','teacher','main');
  G.br.main=G.origin.main=G.remote.main=c1; G.index=Object.assign({},w);
  G.hot='init';
  G.note='A copy of the repository from GitHub (<code>git clone</code>): two commits, on <code>main</code>. Try <code>git status</code> and <code>git log</code>.';
  return G;
}
const git=sh=>sh.git||newGit(sh);
function mk(G,tree,p,msg,by,branch){
  G.clock+=7*60000;
  const full=(hx(msg+'|'+p.join(',')+'|'+G.ord)+hx('t'+G.ord+msg)+hx(by+G.ord)).slice(0,40);
  const id=full.slice(0,7);
  G.commits[id]={id,full,p,msg,tree:Object.assign({},tree),by,ord:G.ord++,branch,time:G.clock};
  if(by!=='colleague')G.known.add(id);
  return id;
}
const reach=(G,id)=>{const s=new Set(),st=id?[id]:[];while(st.length){const x=st.pop();if(s.has(x))continue;s.add(x);st.push(...G.commits[x].p)}return s};
const anc=(G,a,b)=>reach(G,b).has(a);                  // a is b or an ancestor of b
const base=(G,a,b)=>{const A=reach(G,a);return[...reach(G,b)].filter(x=>A.has(x)).sort((x,y)=>G.commits[y].ord-G.commits[x].ord)[0]};
const htree=G=>G.br[G.head]?G.commits[G.br[G.head]].tree:{};
const count=(G,a,b)=>{const A=reach(G,a);return[...reach(G,b)].filter(x=>!A.has(x)).length};   // commits in b, not in a

/* the working tree: the files of ~/project, without .git and the ignored files */
function ignores(dir){const g=dir.c['.gitignore'];return(g&&g.t==='f'?g.data:'').split('\n').map(l=>l.trim()).filter(l=>l&&!l.startsWith('#')).map(l=>globRe(l.replace(/^\/|\/$/g,'')))}
const ignored=(res,path)=>res.some(r=>r.test(path)||r.test(path.replace(/^.*\//,'')));
function readWT(sh,all){
  const x=lookup(sh.root,REPO);if(!x.node||x.node.t!=='d')return null;
  const res=ignores(x.node),out={};
  const rec=(d,pre)=>{for(const[k,n]of Object.entries(d.c)){if(!pre&&k==='.git')continue;const p=pre+k;
    if(n.t==='d')rec(n,p+'/');else if(n.t==='f'&&(all||!ignored(res,p)))out[p]=n.data}};
  rec(x.node,'');return out;
}
function writeWT(sh,path,data){
  let d=lookup(sh.root,REPO).node;const ps=path.split('/');
  for(const s of ps.slice(0,-1)){if(!d.c[s]||d.c[s].t!=='d')d.c[s]=S.D({},S.now());d=d.c[s]}
  if(data==null)delete d.c[ps[ps.length-1]];else d.c[ps[ps.length-1]]=S.F(data,null,S.now());
}
const isPre=(a,b)=>a.length<=b.length&&a.every((x,i)=>x===b[i]);
const rel=(sh,arg)=>{const p=split(sh.cwd,arg);return isPre(REPO,p)?p.slice(REPO.length).join('/'):null};
function setHEAD(sh,G){const g=lookup(sh.root,REPO.concat('.git')).node;if(g&&g.t==='d')g.c.HEAD=S.F('ref: refs/heads/'+G.head+'\n',null,S.now())}

/* ---------- status ---------- */
function state(sh,G){
  const H=htree(G),I=G.index,W=readWT(sh)||{};
  const staged=[],unstaged=[],untracked=[];
  for(const p of keys(H,I))if(H[p]!==I[p]&&!G.unmerged.has(p))staged.push([p,H[p]==null?'new file':I[p]==null?'deleted':'modified']);
  for(const p of keys(I))if(!G.unmerged.has(p)){if(W[p]==null)unstaged.push([p,'deleted']);else if(W[p]!==I[p])unstaged.push([p,'modified'])}
  for(const p of keys(W))if(I[p]==null&&!G.unmerged.has(p))untracked.push(p);
  return{H,I,W,staged,unstaged,untracked,unmerged:[...G.unmerged].sort()};
}
function tracking(G,b){
  const o=G.origin[b];if(!G.up.has(b)||!o)return null;
  return{o:'origin/'+b,ahead:count(G,o,G.br[b]),behind:count(G,G.br[b],o)};
}
function statusText(sh,G,short,color){
  const s=state(sh,G),c=(k,t)=>color?k+t+EN:t,out=[];
  if(short){
    const m={modified:'M','new file':'A',deleted:'D'},X={},Y={};
    s.staged.forEach(([p,k])=>X[p]=m[k]);s.unstaged.forEach(([p,k])=>Y[p]=m[k]);
    keys(X,Y).forEach(p=>out.push(c(GR,X[p]||' ')+c(RD,Y[p]||' ')+' '+p));
    s.unmerged.forEach(p=>out.push(c(RD,'UU')+' '+p));s.untracked.forEach(p=>out.push(c(RD,'??')+' '+p));
    return out.join('\n');
  }
  out.push('On branch '+G.head);
  const t=tracking(G,G.head);
  if(t){if(!t.ahead&&!t.behind)out.push("Your branch is up to date with '"+t.o+"'.");
    else if(t.ahead&&!t.behind)out.push("Your branch is ahead of '"+t.o+"' by "+pl(t.ahead,'commit')+'.','  (use "git push" to publish your local commits)');
    else if(!t.ahead)out.push("Your branch is behind '"+t.o+"' by "+pl(t.behind,'commit')+', and can be fast-forwarded.','  (use "git pull" to update your local branch)');
    else out.push("Your branch and '"+t.o+"' have diverged,",'and have '+t.ahead+' and '+t.behind+' different commits each, respectively.','  (use "git pull" if you want to integrate the remote branch with yours)')}
  if(G.merging)out.push(s.unmerged.length?'\nYou have unmerged paths.\n  (fix conflicts and run "git commit")\n  (use "git merge --abort" to abort the merge)':'\nAll conflicts fixed but you are still merging.\n  (use "git commit" to conclude merge)');
  if(s.staged.length)out.push('\nChanges to be committed:\n  (use "git restore --staged <file>..." to unstage)\n'+s.staged.map(([p,k])=>c(GR,'\t'+(k+':').padEnd(12)+p)).join('\n'));
  if(s.unmerged.length)out.push('\nUnmerged paths:\n  (use "git add <file>..." to mark resolution)\n'+s.unmerged.map(p=>c(RD,'\tboth modified:   '+p)).join('\n'));
  if(s.unstaged.length)out.push('\nChanges not staged for commit:\n  (use "git add <file>..." to update what will be committed)\n  (use "git restore <file>..." to discard changes in working directory)\n'+s.unstaged.map(([p,k])=>c(RD,'\t'+(k+':').padEnd(12)+p)).join('\n'));
  if(s.untracked.length)out.push('\nUntracked files:\n  (use "git add <file>..." to include in what will be committed)\n'+s.untracked.map(p=>c(RD,'\t'+p)).join('\n'));
  if(!s.staged.length&&!s.unmerged.length&&!G.merging){
    if(s.unstaged.length)out.push('\nno changes added to commit (use "git add" and/or "git commit -a")');
    else if(s.untracked.length)out.push('\nnothing added to commit but untracked files present (use "git add" to track)');
    else out.push('\nnothing to commit, working tree clean')}
  return out.join('\n');
}

/* ---------- moving the working tree from one commit to another ---------- */
function blocked(sh,G,from,to){                       // the files with local changes that the move would overwrite
  const s=state(sh,G),dirty=new Set(s.staged.map(x=>x[0]).concat(s.unstaged.map(x=>x[0])));
  const bad=keys(from,to).filter(p=>from[p]!==to[p]&&dirty.has(p));
  const unt=s.untracked.filter(p=>to[p]!=null&&to[p]!==s.W[p]);
  return{bad,unt};
}
function move(sh,G,from,to){
  const I=Object.assign({},to);
  for(const p of keys(G.index,from))if(G.index[p]!==from[p])I[p]=G.index[p];      // staged changes stay
  for(const p of keys(I))if(I[p]==null)delete I[p];
  for(const p of keys(from,to))if(from[p]!==to[p])writeWT(sh,p,to[p]);
  G.index=I;
}
const stopMsg=(b,what)=>b.bad.length?'error: Your local changes to the following files would be overwritten by '+what+':\n'+b.bad.map(p=>'\t'+p).join('\n')+'\nPlease commit your changes or stash them before you '+(what==='checkout'?'switch branches':'merge')+'.\nAborting'
  :'error: The following untracked working tree files would be overwritten by '+what+':\n'+b.unt.map(p=>'\t'+p).join('\n')+'\nPlease move or remove them before you '+(what==='checkout'?'switch branches':'merge')+'.\nAborting';
function diffstat(G,a,b){
  const ps=keys(a,b).filter(p=>a[p]!==b[p]);if(!ps.length)return '';
  let ins=0,del=0;const w=Math.max(...ps.map(p=>p.length));
  const rows=ps.map(p=>{const[i,d]=nstat(a[p],b[p]);ins+=i;del+=d;return ' '+p.padEnd(w)+' | '+String(i+d).padStart(2)+' '+'+'.repeat(Math.min(i,20))+'-'.repeat(Math.min(d,20))});
  const cm=ps.filter(p=>a[p]==null).map(p=>' create mode 100644 '+p).concat(ps.filter(p=>b[p]==null).map(p=>' delete mode 100644 '+p));
  return rows.concat(' '+pl(ps.length,'file')+' changed'+(ins?', '+pl(ins,'insertion')+'(+)':'')+(del?', '+pl(del,'deletion')+'(-)':''),cm).join('\n');
}

/* ---------- the graph: lanes for the panel and for git log --graph ---------- */
function layout(G,ids,tips){                           // ids: newest first; tips: [[name, id, kind]]
  const row={},lane={},kind={},iv=[];ids.forEach((id,i)=>row[id]=i);
  const chains=[];
  const take=(id,k)=>{const ch=[];let x=id;while(x&&row[x]!=null&&lane[x]==null){ch.push(x);lane[x]=-1;x=G.commits[x].p[0]}if(ch.length)chains.push([ch,k])};
  for(const[,id,k]of tips)take(id,k);
  for(const id of ids)if(lane[id]==null)take(id,'other');
  chains.forEach(([ch,k],ci)=>{
    let top=Math.min(...ch.map(x=>row[x]));
    ids.forEach((id,i)=>G.commits[id].p.slice(1).forEach(p=>{if(ch.includes(p))top=Math.min(top,i+.5)}));
    const last=ch[ch.length-1],fp=G.commits[last].p[0];
    const bot=ci===0?ids.length:fp!=null&&row[fp]!=null?row[fp]-.5:row[last];
    let l=ci===0?0:1;while(iv[l]&&iv[l].some(([t,b])=>top<=b+.25&&bot>=t-.25))l++;
    (iv[l]=iv[l]||[]).push([top,bot,last]);ch.forEach(x=>{lane[x]=l;kind[x]=k});
  });
  return{lane,kind,iv,n:Math.max(1,iv.length)};
}
function asciiGraph(G,ids,L,label){
  const n=L.n,act=(l,r)=>(L.iv[l]||[]).some(([t,b])=>r>=t&&r<=b);
  const out=[];
  ids.forEach((id,i)=>{
    const l=L.lane[id];
    out.push(Array.from({length:n},(_,k)=>k===l?'*':act(k,i)?'|':' ').join(' ').replace(/\s+$/,'')+' '+label(id));
    L.iv.forEach((ivs,k)=>ivs.forEach(([t,b,last])=>{
      let j=null,ch;
      if(t===i+.5){j=l;ch=Array.from({length:2*n},(_,x)=>x%2===0&&x/2!==k&&act(x/2,i+.5)?'|':' ');ch[2*Math.min(k,j)+1]=k>j?'\\':'/'}
      else if(b===i+.5&&k>0){const p=G.commits[last].p[0];j=L.lane[p];ch=Array.from({length:2*n},(_,x)=>x%2===0&&x/2!==k&&act(x/2,i+.5)?'|':' ');ch[2*Math.min(k,j)+1]=k>j?'/':'\\'}
      if(ch)out.push(ch.join('').replace(/\s+$/,''));
    }));
  });
  return out.join('\n');
}
function decor(G,id,color){
  const r=[];
  if(G.br[G.head]===id)r.push('HEAD -> '+G.head);
  Object.keys(G.br).sort().forEach(b=>{if(b!==G.head&&G.br[b]===id)r.push(b)});
  Object.keys(G.origin).sort().forEach(b=>{if(G.origin[b]===id)r.push('origin/'+b)});
  return r.length?(color?YL+' ('+EN:' (')+r.join(', ')+(color?YL+')'+EN:')'):'';
}
const resolve=(G,ref)=>{if(!ref)return null;if(ref==='HEAD')return G.br[G.head];if(G.br[ref])return G.br[ref];
  const m=ref.match(/^(?:origin|remotes\/origin|refs\/remotes\/origin)\/(.+)$/);if(m&&G.origin[m[1]])return G.origin[m[1]];
  const h=ref.match(/^(.+?)(~(\d*))?$/);
  if(h&&h[2]){let x=resolve(G,h[1]);for(let k=0;x&&k<(+h[3]||1);k++)x=G.commits[x].p[0];return x||null}
  if(/^[0-9a-f]{4,40}$/.test(ref)){const c=Object.values(G.commits).find(c=>c.full.startsWith(ref)&&G.known.has(c.id));return c?c.id:null}
  return null};

/* ---------- git ---------- */
const NOTE={
  status:'<code>git status</code> only looks, it changes nothing. Read its hints: they say what to do next.',
};
function cmdGit(sh,args){
  const G=git(sh),color=sh.color&&sh.isatty!==false;
  const c=(k,t)=>color?k+t+EN:t;
  const sub=args[0],a=args.slice(1);
  const say=n=>{G.note=n};
  G.hot='';
  if(!sub||sub==='help'||sub==='--help')return{out:'usage: git <command> [<args>]\n\nthe commands of this demo:\n   status     what changed, and what to do next   (-s: short)\n   diff       the changes not staged yet         (--staged: the staged ones)\n   add        put changes in the staging area     (git add FILE, git add .)\n   restore    undo changes in a file              (--staged: unstage)\n   commit     save the staged changes             (git commit -m "message", -a)\n   log        the history                         (--oneline --graph --all)\n   show       a commit and its changes\n   branch     list, create (git branch NAME) or delete (-d NAME) branches\n   switch     go to a branch                      (-c NAME: a new one)\n   merge      join a branch into this one         (--abort)\n   fetch      download the commits from GitHub\n   pull       fetch, then merge\n   push       send your commits to GitHub         (-u origin BRANCH)\n   remote -v  where GitHub is'};
  if(sub==='--version'||sub==='version')return{out:'git version 2.47.0 (demo)'};
  if(sub==='clone')return{err:"fatal: destination path 'project' already exists and is not an empty directory.\n(this demo starts with "+URL+" already cloned in ~/project: cd ~/project)",code:128};
  if(sub==='config'){if(a.length>=2&&!a[0].startsWith('-')){G.cfg[a[0]]=a.slice(1).join(' ');return{}}if(a.length===1)return G.cfg[a[0]]!=null?{out:G.cfg[a[0]]}:{code:1};return{out:Object.entries(G.cfg).map(([k,v])=>k+'='+v).join('\n')}}
  const x=lookup(sh.root,REPO);
  if(!x.node||!x.node.c['.git']||!isPre(REPO,sh.cwd)){
    if(sub==='init')return{err:'(this demo has one repository: ~/project; cd ~/project)'};
    return{err:'fatal: not a git repository (or any of the parent directories): .git'+(x.node?'\n(the repository of this demo is ~/project: cd ~/project)':''),code:128};
  }
  if(sub==='init')return{out:'Reinitialized existing Git repository in /home/student/project/.git/'};
  if(sub==='remote'){return{out:a.includes('-v')?'origin\t'+URL+' (fetch)\norigin\t'+URL+' (push)':'origin'}}

  if(sub==='status'){const short=a.includes('-s')||a.includes('--short');say(NOTE.status);return{out:statusText(sh,G,short,color)}}

  if(sub==='add'){
    if(!a.length)return{err:"Nothing specified, nothing added.\nhint: Maybe you wanted to say 'git add .'?"};
    const W=readWT(sh)||{},ALL=readWT(sh,true)||{},specs=a.filter(s=>!s.startsWith('-')),force=a.includes('-f');
    if(a.includes('-A')||a.includes('--all'))specs.push('.');
    const done=[],ign=[];
    for(const sp of specs){
      const r=rel(sh,sp);if(r===null)return{err:"fatal: "+sp+": '"+sp+"' is outside repository at '/home/student/project'",code:128};
      const m=p=>r===''||p===r||p.startsWith(r+'/');
      const cand=keys(W,G.index).filter(m);
      if(!cand.length){const ig=Object.keys(ALL).filter(m);if(ig.length&&!force){ign.push(...ig);continue}
        if(ig.length){ig.forEach(p=>{G.index[p]=ALL[p];done.push(p)});continue}
        return{err:"fatal: pathspec '"+sp+"' did not match any files",code:128}}
      for(const p of cand){if(W[p]!=null)G.index[p]=W[p];else delete G.index[p];G.unmerged.delete(p);done.push(p)}
    }
    if(ign.length)return{err:'The following paths are ignored by one of your .gitignore files:\n'+ign.join('\n')+'\nhint: Use -f if you really want to add them.\n(.gitignore says: do not keep the files made by the build)',code:1};
    G.hot='stage';
    say(G.merging&&!G.unmerged.size?'All the conflicts are marked as solved. <code>git commit</code> ends the merge.':'The change is now in the <b>staging area</b>: it goes in the next commit. <code>git status</code> shows it in green.');
    return{};
  }

  if(sub==='restore'){
    const staged=a.includes('--staged')||a.includes('-S'),specs=a.filter(s=>!s.startsWith('-'));
    if(!specs.length)return{err:'fatal: you must specify path(s) to restore',code:128};
    const H=htree(G),W=readWT(sh)||{};
    for(const sp of specs){const r=rel(sh,sp);const m=p=>r===''||p===r||p.startsWith(r+'/');
      const cand=keys(staged?H:{},G.index,staged?{}:W).filter(m);
      if(!cand.length)return{err:"error: pathspec '"+sp+"' did not match any file(s) known to git",code:1};
      for(const p of cand){if(staged){if(H[p]!=null)G.index[p]=H[p];else delete G.index[p]}else if(G.index[p]!=null)writeWT(sh,p,G.index[p])}}
    G.hot=staged?'stage':'wd';
    say(staged?'Unstaged: the change is back in the working directory only.':'The file is back as it was in the staging area: your change is <b>lost</b>.');
    return{};
  }

  if(sub==='diff'){
    const staged=a.includes('--staged')||a.includes('--cached'),stat=a.includes('--stat');
    const specs=a.filter(s=>!s.startsWith('-')).map(s=>rel(sh,s));
    const A=staged?htree(G):G.index,W=readWT(sh)||{},B=staged?G.index:Object.fromEntries(Object.keys(G.index).map(p=>[p,W[p]]));
    const ps=keys(A,B).filter(p=>A[p]!==B[p]&&!G.unmerged.has(p)&&(!specs.length||specs.some(r=>r===''||p===r||p.startsWith(r+'/'))));
    say(staged?'<code>git diff --staged</code>: what the next commit will change.':'<code>-</code> lines were removed, <code>+</code> lines were added. <code>git diff</code> shows the changes <b>not staged</b> yet; <code>git diff --staged</code> the staged ones.');
    if(stat)return{out:diffstat(G,A,B)};
    return{out:ps.map(p=>unified(A[p],B[p],p,color)).join('\n')};
  }

  if(sub==='commit'){
    let msg=null,all=false,amend=false;
    for(let i=0;i<a.length;i++){const w=a[i];
      if(w==='-m'||w==='--message'){msg=a[++i];continue}
      if(/^-[a-z]*m$/.test(w)){if(w.includes('a'))all=true;msg=a[++i];continue}
      if(w==='-a'||w==='--all'){all=true;continue}
      if(w==='--amend'){amend=true;continue}
      if(w.startsWith('-'))return{err:'error: unknown option `'+w.replace(/^-+/,'')+"'"};
      return{err:"error: pathspec '"+w+"' did not match any file(s) known to git\n(the message goes after -m, in quotes: git commit -m \"Fix the label\")",code:1}}
    if(amend)return{err:'(git commit --amend is not in this demo)'};
    if(G.unmerged.size)return{err:"error: Committing is not possible because you have unmerged files.\nhint: Fix them up in the work tree, and then use 'git add/rm <file>'\nhint: as appropriate to mark resolution and make a commit.\nfatal: Exiting because of an unresolved conflict.",code:128};
    if(all){const W=readWT(sh)||{};for(const p of Object.keys(G.index)){if(W[p]==null)delete G.index[p];else G.index[p]=W[p]}}
    if(msg==null&&G.merging)msg=G.merging.msg;
    if(msg==null)return{err:'Aborting commit due to empty commit message.\n(a real git opens an editor for the message; here, give it with -m: git commit -m "Print the total")',code:1};
    const H=htree(G),same=keys(H,G.index).every(p=>H[p]===G.index[p]);
    if(same&&!G.merging){say('Nothing is staged: <code>git add</code> the files first.');return{out:statusText(sh,G,false,color),code:1}}
    const par=[G.br[G.head]].concat(G.merging?[G.merging.other]:[]);
    const id=mk(G,G.index,par,msg,'you',G.head);
    G.br[G.head]=id;const wasMerge=!!G.merging;G.merging=null;
    G.hot='repo';
    say(wasMerge?'The <b>merge commit</b> has two parents. Now <code>git push</code> it.':'A new <b>commit</b> in your <b>local repository</b>. Only your computer has it: GitHub gets it with <code>git push</code>.');
    return{out:'['+G.head+' '+id+'] '+msg+(wasMerge?'':'\n'+diffstat(G,H,G.index))};
  }

  if(sub==='log'||sub==='show'){
    if(sub==='show'){
      const id=resolve(G,a.find(s=>!s.startsWith('-'))||'HEAD');if(!id)return{err:"fatal: ambiguous argument '"+a[0]+"': unknown revision",code:128};
      const C=G.commits[id],P=C.p[0]?G.commits[C.p[0]].tree:{};
      say('<code>git show</code>: one commit, and what it changed against its parent.');
      return{out:c(YL,'commit '+C.full)+decor(G,id,color)+(C.p.length>1?'\nMerge: '+C.p.join(' '):'')+'\nAuthor: '+(C.by==='colleague'?'Ana Pop <ana@upb.ro>':C.by==='teacher'?'ISO Team <iso@upb.ro>':'Student <student@iso>')+'\nDate:   '+date(C.time)+'\n\n    '+C.msg+(C.p.length>1?'':'\n\n'+keys(P,C.tree).filter(p=>P[p]!==C.tree[p]).map(p=>unified(P[p],C.tree[p],p,color)).join('\n'))};
    }
    let one=false,graph=false,allr=false,n=Infinity;const refs=[];
    for(let i=0;i<a.length;i++){const w=a[i];if(w==='--oneline')one=true;else if(w==='--graph')graph=true;else if(w==='--all')allr=true;else if(w==='-n')n=+a[++i];else if(/^-\d+$/.test(w))n=+w.slice(1);else if(w.startsWith('-'))continue;else refs.push(w)}
    const starts=allr?Object.values(G.br).concat(Object.values(G.origin)):refs.length?refs.map(r=>resolve(G,r)):[G.br[G.head]];
    if(starts.some(s=>!s))return{err:"fatal: ambiguous argument '"+refs.find(r=>!resolve(G,r))+"': unknown revision or path not in the working tree.",code:128};
    const set=new Set();starts.forEach(s=>reach(G,s).forEach(x=>set.add(x)));
    const ids=[...set].sort((x,y)=>G.commits[y].ord-G.commits[x].ord).slice(0,n);
    const label=id=>{const C=G.commits[id];return one?c(YL,id)+decor(G,id,color)+' '+C.msg:c(YL,'commit '+C.full)+decor(G,id,color)};
    say(graph?'Each <code>*</code> is a commit, newest on top; the lines join a commit to its parents.':'The history, newest first. A commit is only here if <b>your</b> repository has it: run <code>git fetch</code> to see what GitHub has.');
    if(one){
      if(graph){const L=layout(G,ids,tipsOf(G,false));return{out:asciiGraph(G,ids,L,label)}}
      return{out:ids.map(label).join('\n')};
    }
    const full=id=>{const C=G.commits[id];return label(id)+(C.p.length>1?'\nMerge: '+C.p.join(' '):'')+'\nAuthor: '+(C.by==='colleague'?'Ana Pop <ana@upb.ro>':C.by==='teacher'?'ISO Team <iso@upb.ro>':'Student <student@iso>')+'\nDate:   '+date(C.time)+'\n\n    '+C.msg+'\n'};
    if(graph){const L=layout(G,ids,tipsOf(G,false));return{out:asciiGraph(G,ids,L,id=>c(YL,id)+decor(G,id,color)+' '+G.commits[id].msg)}}
    return{out:ids.map(full).join('\n')};
  }

  if(sub==='branch'){
    const del=a.find(w=>w==='-d'||w==='-D'||w==='--delete'),names=a.filter(w=>!w.startsWith('-'));
    if(del){const b=names[0];if(!b)return{err:'fatal: branch name required',code:128};
      if(!G.br[b])return{err:"error: branch '"+b+"' not found",code:1};
      if(b===G.head)return{err:"error: cannot delete branch '"+b+"' used by worktree at '/home/student/project'",code:1};
      if(del!=='-D'&&!anc(G,G.br[b],G.br[G.head]))return{err:"error: the branch '"+b+"' is not fully merged.\nhint: If you are sure you want to delete it, run 'git branch -D "+b+"'",code:1};
      const was=G.br[b];delete G.br[b];G.up.delete(b);G.hot='repo';say('The branch name is gone. Its commits stay, if another branch reaches them.');return{out:'Deleted branch '+b+' (was '+was+').'}}
    if(names.length){const b=names[0];if(G.br[b])return{err:"fatal: a branch named '"+b+"' already exists",code:128};
      if(!/^[\w][\w./-]*$/.test(b))return{err:"fatal: '"+b+"' is not a valid branch name",code:128};
      const at=names[1]?resolve(G,names[1]):G.br[G.head];if(!at)return{err:"fatal: not a valid object name: '"+names[1]+"'",code:128};
      G.br[b]=at;G.hot='repo';say('A new branch <code>'+b+'</code>, on the same commit. You are still on <code>'+G.head+'</code>: <code>git switch '+b+'</code> goes there.');return{}}
    const ls=Object.keys(G.br).sort().map(b=>b===G.head?'* '+c(GR,b):'  '+b);
    if(a.includes('-a')||a.includes('-r'))(a.includes('-r')?ls.splice(0):0,Object.keys(G.origin).sort().forEach(b=>ls.push('  '+c(RD,'remotes/origin/'+b))));
    say('<code>*</code> marks the branch you are on (<code>HEAD</code>).');
    return{out:ls.join('\n')};
  }

  if(sub==='switch'||sub==='checkout'){
    if(sub==='checkout'&&(a[0]==='--'||a.length&&!a[0].startsWith('-')&&!G.br[a[0]]&&!G.origin[a[0]]&&rel(sh,a[0])!==null&&(readWT(sh)||{})[rel(sh,a[0])]!=null))return cmdGit(sh,['restore'].concat(a.filter(w=>w!=='--')));
    const create=a.includes('-c')||a.includes('-b')||a.includes('--create'),name=a.filter(w=>!w.startsWith('-'))[0];
    if(!name)return{err:'fatal: missing branch or commit argument',code:128};
    if(G.merging)return{err:'fatal: cannot switch branch while merging\nConsider "git merge --abort" or "git commit".',code:128};
    if(create){if(G.br[name])return{err:"fatal: a branch named '"+name+"' already exists",code:128};
      if(!/^[\w][\w./-]*$/.test(name))return{err:"fatal: '"+name+"' is not a valid branch name",code:128};
      G.br[name]=G.br[G.head];G.head=name;setHEAD(sh,G);G.hot='repo';
      say('A <b>branch</b> is a name for a commit. You are on <code>'+name+'</code> now: new commits move it forward, <code>main</code> stays where it is.');
      return{out:"Switched to a new branch '"+name+"'"}}
    if(name===G.head)return{out:"Already on '"+name+"'"+(tracking(G,name)?'\n'+statusText(sh,G,false,false).split('\n')[1]:'')};
    let extra='';
    if(!G.br[name]){if(!G.origin[name]){return{err:sub==='switch'?"fatal: invalid reference: "+name+(name==='feature'?'\n(create it: git switch -c feature)':''):"error: pathspec '"+name+"' did not match any file(s) known to git",code:128}}
      G.br[name]=G.origin[name];G.up.add(name);extra="branch '"+name+"' set up to track 'origin/"+name+"'.\n"}
    const from=htree(G),to=G.commits[G.br[name]].tree,b=blocked(sh,G,from,to);
    if(b.bad.length||b.unt.length){if(extra)delete G.br[name];return{err:stopMsg(b,'checkout'),code:1}}
    move(sh,G,from,to);G.head=name;setHEAD(sh,G);G.hot='wd';
    const gone=keys(from).filter(p=>to[p]==null),come=keys(to).filter(p=>from[p]==null);
    say('On <code>'+name+'</code>: the folder now has the files of its last commit'+(gone.length?'; <code>'+gone.join('</code>, <code>')+'</code> disappeared (it is on another branch)':'')+(come.length?'; <code>'+come.join('</code>, <code>')+'</code> appeared':'')+'.');
    return{out:extra+"Switched to branch '"+name+"'"};
  }

  if(sub==='fetch'){const r=fetch(G);G.hot=r?'repo':'';say(r?'<code>origin/main</code> moved to what GitHub has. Your <code>main</code> did not move: <code>git merge origin/main</code> (or <code>git pull</code>) brings the commits in.':'GitHub has nothing new.');return r?{err:r}:{}}

  if(sub==='merge'||sub==='pull'){
    if(a.includes('--abort')){if(!G.merging)return{err:'fatal: There is no merge to abort (MERGE_HEAD missing).',code:128};
      const H=htree(G),W=readWT(sh)||{};for(const p of keys(W,H))if(W[p]!==H[p]&&(G.index[p]!==H[p]||G.unmerged.has(p)))writeWT(sh,p,H[p]);
      G.index=Object.assign({},H);G.merging=null;G.unmerged.clear();G.hot='wd';say('The merge is cancelled: everything is as before <code>git merge</code>.');return{}}
    if(G.merging)return{err:'error: Merging is not possible because you have unmerged files.\nhint: Fix them up in the work tree, and then use \'git add/rm <file>\'\nhint: as appropriate to mark resolution and make a commit.\nfatal: Exiting because of an unresolved conflict.',code:128};
    let ref,msg,pre='';
    if(sub==='pull'){
      if(!G.up.has(G.head)||!G.remote[G.head])return{err:'There is no tracking information for the current branch.\nPlease specify which branch you want to merge with.\n\n    git pull origin '+G.head+'\n\nIf you wish to set tracking information for this branch you can do so with:\n\n    git branch --set-upstream-to=origin/'+G.head+' '+G.head+'\n(or push it first: git push -u origin '+G.head+')',code:1};
      pre=fetch(G);pre=pre?pre+'\n':'';ref='origin/'+G.head;msg="Merge branch '"+G.head+"' of "+WEB.replace('.git','');
    }else{ref=a.find(w=>!w.startsWith('-'));if(!ref)return{err:'fatal: No remote for the current branch.\n(name the branch to merge: git merge feature)',code:128};
      msg=/^origin\//.test(ref)?"Merge remote-tracking branch '"+ref+"'":"Merge branch '"+ref+"'"+(G.head!=='main'?' into '+G.head:'')}
    const t=resolve(G,ref),h=G.br[G.head];
    if(!t)return{err:'merge: '+ref+' - not something we can merge'+(ref==='feature'?'\n(create the branch first: git switch -c feature)':''),code:1};
    if(anc(G,t,h)){say(sub==='pull'?'Nothing new on GitHub.':'<code>'+G.head+'</code> already has every commit of <code>'+ref+'</code>.');return{out:pre+'Already up to date.'}}
    const H=htree(G),T=G.commits[t].tree;
    if(anc(G,h,t)){
      const b=blocked(sh,G,H,T);if(b.bad.length||b.unt.length)return{out:pre+'Updating '+h+'..'+t,err:stopMsg(b,'merge'),code:1};
      move(sh,G,H,T);G.br[G.head]=t;G.hot='repo';
      say('<b>Fast-forward</b>: <code>'+G.head+'</code> had no commits of its own, so it just moved forward to <code>'+ref+'</code>. No merge commit is needed.');
      return{out:pre+'Updating '+h+'..'+t+'\nFast-forward\n'+diffstat(G,H,T)};
    }
    const B=G.commits[base(G,h,t)].tree,M={},conf=[],kinds={};
    for(const p of keys(B,H,T)){const r=merge3(B[p],H[p],T[p],'HEAD',ref);if(r.t!=null)M[p]=r.t;if(r.conflict){conf.push(p);kinds[p]=r.kind||'content'}}
    const b=blocked(sh,G,H,M);if(b.bad.length||b.unt.length)return{out:pre,err:stopMsg(b,'merge'),code:1};
    for(const p of keys(H,M))if(H[p]!==M[p])writeWT(sh,p,M[p]);
    const auto=keys(B,H,T).filter(p=>B[p]!=null&&H[p]!==B[p]&&T[p]!==B[p]).map(p=>'Auto-merging '+p);
    if(conf.length){
      G.index=Object.assign({},H);for(const p of keys(M))if(!conf.includes(p))G.index[p]=M[p];for(const p of keys(H))if(M[p]==null&&!conf.includes(p))delete G.index[p];
      G.merging={other:t,msg};G.unmerged=new Set(conf);G.hot='wd';
      say('⚠️ <b>Conflict</b>: both sides changed the same lines of <code>'+conf.join('</code>, <code>')+'</code>. Open it (<code>pico '+conf[0]+'</code>), keep the right lines, delete the markers <code>&lt;&lt;&lt;&lt;&lt;&lt;&lt;</code> <code>=======</code> <code>&gt;&gt;&gt;&gt;&gt;&gt;&gt;</code>, then <code>git add '+conf[0]+'</code> and <code>git commit</code>.');
      return{out:pre+auto.join('\n'),err:conf.map(p=>'CONFLICT ('+kinds[p]+'): Merge conflict in '+p).join('\n')+'\nAutomatic merge failed; fix conflicts and then commit the result.',code:1};
    }
    G.index=Object.assign({},M);
    const id=mk(G,M,[h,t],msg,'you',G.head);G.br[G.head]=id;G.hot='repo';
    say((sub==='pull'?'GitHub and you both had new commits, so <code>git pull</code> made a <b>merge commit</b>, with two parents. ':'A <b>merge commit</b>, with two parents: <code>'+G.head+'</code> now has the work of <code>'+ref+'</code> too. ')+(sub==='pull'?'Now <code>git push</code> works.':''));
    return{out:pre+(auto.length?auto.join('\n')+'\n':'')+"Merge made by the 'ort' strategy.\n"+diffstat(G,H,M)};
  }

  if(sub==='push'){
    const up=a.includes('-u')||a.includes('--set-upstream'),ws=a.filter(w=>!w.startsWith('-'));
    if(ws[0]&&ws[0]!=='origin')return{err:"fatal: '"+ws[0]+"' does not appear to be a git repository\nfatal: Could not read from remote repository.\n(the remote of this demo is origin: git push origin "+G.head+')',code:128};
    const b=ws[1]||G.head;
    if(!G.br[b])return{err:"error: src refspec "+b+" does not match any\nerror: failed to push some refs to '"+WEB+"'",code:1};
    if(!ws[1]&&!G.up.has(b))return{err:'fatal: The current branch '+b+' has no upstream branch.\nTo push the current branch and set the remote as upstream, use\n\n    git push --set-upstream origin '+b+'\n\n(or the short form: git push -u origin '+b+')',code:128};
    const R=G.remote[b],L=G.br[b],head='To '+WEB+'\n';
    if(R===L){say('GitHub already has all your commits: <code>git commit</code> something new first.');return{out:'Everything up-to-date'}}
    if(R&&!anc(G,R,L)){const known=G.known.has(R);
      say('⚠️ <b>Rejected</b>: GitHub has a commit that you do not have (a colleague pushed it). <code>git pull</code> brings it and merges it, then <code>git push</code> again.');
      return{out:head.trim(),err:' ! [rejected]        '+b+' -> '+b+(known?' (non-fast-forward)':' (fetch first)')+"\nerror: failed to push some refs to '"+WEB+"'\n"+(known?'hint: Updates were rejected because the tip of your current branch is behind\nhint: its remote counterpart. Integrate the remote changes (e.g.\nhint: \'git pull ...\') before pushing again.':"hint: Updates were rejected because the remote contains work that you do not\nhint: have locally. This is usually caused by another repository pushing to\nhint: the same ref. Integrate the remote changes (e.g. 'git pull ...')\nhint: before pushing again."),code:1}}
    G.remote[b]=G.origin[b]=L;if(up)G.up.add(b);G.hot='remote';
    say('GitHub has your commits now: your colleagues get them with <code>git pull</code>. <b>Commit</b> saves on your computer, <b>push</b> shares.');
    return{out:head+(R?'   '+R+'..'+L+'  '+b+' -> '+b:' * [new branch]      '+b+' -> '+b)+(up&&!R?"\nbranch '"+b+"' set up to track 'origin/"+b+"'.":'')};
  }
  if(['stash','rebase','reset','revert','cherry-pick','tag','blame','bisect','rm','mv'].includes(sub))return{err:'(git '+sub+' is not in this demo; try git help)'};
  return{err:"git: '"+sub+"' is not a git command. See 'git help'.",code:1};
}
function fetch(G){
  const out=[];
  for(const[b,id]of Object.entries(G.remote)){
    if(G.origin[b]===id)continue;
    reach(G,id).forEach(x=>G.known.add(x));
    out.push(G.origin[b]?'   '+G.origin[b]+'..'+id+'  '+b.padEnd(10)+' -> origin/'+b:' * [new branch]      '+b.padEnd(10)+' -> origin/'+b);
    G.origin[b]=id;
  }
  return out.length?'From '+WEB.replace('.git','')+'\n'+out.join('\n'):'';
}
/* a colleague pushes a commit to GitHub */
const COL=[
  {msg:'Add build instructions',f:'README.md',ed:t=>t+'\n## Build\n\n    make\n    ./app\n'},
  {msg:'Add the authors',f:'AUTHORS',ed:()=>'Ana Pop\nStudent\n'},
  {msg:'Explain MAX',f:'README.md',ed:t=>t+'\nTo sum more numbers, change MAX in lib.h.\n'},
];
function colleague(sh){
  const G=git(sh),k=COL[G.col++%COL.length],par=G.remote.main,T=Object.assign({},G.commits[par].tree);
  T[k.f]=k.ed(T[k.f]||'');
  const id=mk(G,T,[par],k.msg,'colleague','main');G.remote.main=id;G.hot='remote';
  G.note='A colleague (Ana) pushed <code>'+id+'</code> “'+k.msg+'” to GitHub. Your computer does not know it yet: <code>git fetch</code> or <code>git pull</code> brings it.';
  return{id,msg:k.msg,f:k.f};
}

S.Shell.prototype.c_git=function(args){return cmdGit(this,args)};
const R0=S.Shell.prototype.reset;S.Shell.prototype.reset=function(){R0.call(this);this.git=null};
const H0=S.Shell.prototype.c_help;
S.Shell.prototype.c_help=function(){const r=H0.call(this);if(this.profile==='07')r.out+='\nlecture 07: gcc nm objdump ldd ar file make'+(this.variant==='git'?' git (git help)':'');return r};

/* ---------- the side panel of the git terminal ---------- */
function tipsOf(G,withRemote){
  const t=[['main',G.br.main,'main'],['origin/main',G.origin.main,'origin']];
  if(withRemote)t.push(['GitHub',G.remote.main,'remote']);
  Object.keys(G.br).sort().filter(b=>b!=='main').forEach(b=>t.push([b,G.br[b],'branch']));
  Object.keys(G.origin).sort().filter(b=>b!=='main').forEach(b=>t.push(['origin/'+b,G.origin[b],'origin']));
  if(withRemote)Object.keys(G.remote).sort().filter(b=>b!=='main').forEach(b=>t.push(['GitHub '+b,G.remote[b],'remote']));
  return t.filter(x=>x[1]);
}
const LC={main:'#004d65',branch:'#8e24aa',origin:'#00838f',remote:'#c77800',other:'#7d8d93'};
function graphHTML(G){
  const vis=new Set(G.known);Object.values(G.remote).forEach(id=>reach(G,id).forEach(x=>vis.add(x)));
  const ids=[...vis].sort((x,y)=>G.commits[y].ord-G.commits[x].ord);
  const L=layout(G,ids,tipsOf(G,true)),RH=30,DX=18,X0=12,row={};ids.forEach((id,i)=>row[id]=i);
  const X=id=>X0+L.lane[id]*DX,Y=id=>row[id]*RH+RH/2,W=X0*2+(L.n-1)*DX;
  let lines='',dots='';
  ids.forEach(id=>{const C=G.commits[id],x=X(id),y=Y(id);
    C.p.forEach((p,k)=>{if(row[p]==null)return;const px=X(p),py=Y(p),col=LC[L.kind[k===0&&px!==x?id:p]];
      const dash=!G.known.has(id)?' stroke-dasharray="3 3"':'';
      let d;
      if(px===x)d=`M${x},${y}V${py}`;
      else if(k===0)d=py-y>RH?`M${x},${y}V${py-RH}C${x},${py-RH/2} ${px},${py-RH/2} ${px},${py}`:`M${x},${y}C${x},${(y+py)/2} ${px},${(y+py)/2} ${px},${py}`;
      else d=py-y>RH?`M${x},${y}C${x},${y+RH/2} ${px},${y+RH/2} ${px},${y+RH}V${py}`:`M${x},${y}C${x},${(y+py)/2} ${px},${(y+py)/2} ${px},${py}`;
      lines+=`<path d="${d}" fill="none" stroke="${col}" stroke-width="2"${dash}/>`});
    const ghost=!G.known.has(id),isHead=G.br[G.head]===id,col=LC[L.kind[id]];
    dots+=(isHead?`<circle cx="${x}" cy="${y}" r="8.5" fill="none" stroke="#e65100" stroke-width="2"/>`:'')+`<circle cx="${x}" cy="${y}" r="5.5" fill="${ghost?'#fff':col}" stroke="${col}" stroke-width="2"${ghost?' stroke-dasharray="2 2"':''}/>`});
  const svg=`<svg class="glanes" width="${W}" height="${ids.length*RH}" viewBox="0 0 ${W} ${ids.length*RH}" aria-hidden="true">${lines}${dots}</svg>`;
  const pill=(t,k,tip)=>`<span class="gpill ${k}" title="${tip}">${t}</span>`;
  const rows=ids.map(id=>{const C=G.commits[id],ps=[];
    if(G.br[G.head]===id)ps.push(pill('HEAD → '+G.head,'h','the branch you are on'));
    Object.keys(G.br).sort().forEach(b=>{if(b!==G.head&&G.br[b]===id)ps.push(pill(b,b==='main'?'m':'b','a local branch'))});
    Object.keys(G.origin).sort().forEach(b=>{if(G.origin[b]===id)ps.push(pill('origin/'+b,'o','where your computer last saw GitHub'))});
    Object.keys(G.remote).sort().forEach(b=>{if(G.remote[b]===id&&G.origin[b]!==id)ps.push(pill('☁ GitHub'+(b==='main'?'':' '+b),'r','where GitHub really is now'))});
    const ghost=!G.known.has(id);
    return `<div class="grow${ghost?' ghost':''}" style="height:${RH}px">${ps.join('')}<code class="gid">${id}</code><span class="gmsg" title="${C.msg.replace(/"/g,'&quot;')}">${C.msg.replace(/&/g,'&amp;').replace(/</g,'&lt;')}</span>${C.by==='colleague'?'<span class="gby">Ana</span>':''}${ghost?'<span class="gby">only on GitHub</span>':''}</div>`}).join('');
  return `<div class="ggr" style="--lw:${W}px">${svg}<div class="grows">${rows}</div></div>`;
}
function panel(sh,el,api){
  const G=git(sh),s=state(sh,G),e=t=>String(t).replace(/&/g,'&amp;').replace(/</g,'&lt;');
  const sig=JSON.stringify([s.staged,s.unstaged,s.untracked,s.unmerged]);
  if(api.last&&api.last.sig!==sig&&!G.hot){
    const lc=(sh.hist[sh.hist.length-1]||'');
    if(!/^git\b/.test(lc)){G.hot='wd';G.note=s.unstaged.length||s.untracked.length?'You changed the <b>working directory</b>. <code>git status</code> and <code>git diff</code> show it; <code>git add</code> puts it in the staging area.':'The working directory is back as in the staging area.'}
  }
  const fl=(p,k,cls)=>`<span class="gf ${cls}">${e(p)}<i>${k}</i></span>`;
  const wd=s.unmerged.map(p=>fl(p,'conflict','x')).concat(s.unstaged.map(([p,k])=>fl(p,k,k==='deleted'?'d':'m')),s.untracked.map(p=>fl(p,'untracked','u')));
  const st=s.staged.map(([p,k])=>fl(p,k,k==='deleted'?'d':k==='new file'?'n':'s'));
  const t=tracking(G,G.head),H=G.br[G.head],ahead=t&&t.ahead?`<span class="gtag a">${t.ahead} to push ↓</span>`:'',behind=t&&t.behind?`<span class="gtag b">${t.behind} to pull</span>`:'';
  const Rm=G.remote.main,newer=count(G,G.br.main,Rm);
  const box=(k,title,sub,body)=>`<div class="gbox${G.hot===k?' hot':''}" data-k="${k}"><div class="gk"><b>${title}</b><span>${sub}</span></div><div class="gv">${body}</div></div>`;
  const arr=(t)=>`<div class="garr">${t}</div>`;
  el.innerHTML=`<div class="gnote" role="status"><b>What happened</b> ${G.note||'Type a git command.'}</div>
  <div class="gplaces">
  ${box('wd','Working directory','the files in ~/project',wd.length?wd.join(''):'<i class="gnone">no changes</i>')}
  ${arr('<code>git add</code> ↓')}
  ${box('stage','Staging area','what the next commit will save',st.length?st.join(''):'<i class="gnone">empty</i>')}
  ${arr('<code>git commit</code> ↓')}
  ${box('repo','Local repository','the commits on your computer',`<span class="gref">${e(G.head)}</span> → <code>${H}</code> ${ahead}${behind}${G.merging?'<span class="gtag x">merging</span>':''}`)}
  ${arr('<code>git push</code> ↓ &nbsp; ↑ <code>git pull</code>')}
  ${box('remote','GitHub (remote)','shared with the team',`<span class="gref">main</span> → <code>${Rm}</code> ${newer?`<span class="gtag b">${newer} new, not on your computer</span>`:''}<button type="button" class="gcol" data-r="col">👤 A colleague pushes</button>`)}
  </div>
  <div class="ghist"><div class="ghh"><b>History</b><span>newest on top · a dot is a commit, a line joins it to its parent</span></div>${graphHTML(G)}</div>`;
  el.querySelector('[data-r="col"]').addEventListener('click',()=>{const r=colleague(sh);api.print('<span class="dim"># meanwhile, on the computer of a colleague:\n#   git commit -m "'+e(r.msg)+'"   ('+e(r.f)+')\n#   git push          → GitHub has '+r.id+'</span>');api.draw()});
  api.last={sig};
  G.hot='';
}
(window.ISO_SIDE||(window.ISO_SIDE={})).git={draw:panel};

/* ---------- the missions of the git terminal ---------- */
const mine=G=>Object.values(G.commits).filter(c=>c.by==='you');
(window.ISO_MSETS||(window.ISO_MSETS={})).git=[
  {t:'See the state of the repository.',h:'git status',ok:(sh,c)=>/^git\s+status/.test(c)},
  {t:'Change <code>main.c</code>: replace <code>"sum"</code> with <code>"total"</code> (<code>pico main.c</code>), then look at the change with <code>git diff</code>.',h:'pico main.c, Ctrl+O, Ctrl+X, git diff',ok:(sh,c,o)=>/^git\s+diff/.test(c)&&/^\+.*total/m.test(o)},
  {t:'Save the change in a commit: first stage it, then commit it with a message.',h:'git add main.c, then git commit -m "Print the total"',ok:sh=>sh.git&&mine(sh.git).some(x=>/total/.test(x.tree['main.c']||''))},
  {t:'Send your commit to GitHub.',h:'git status says: ahead by 1 commit. git push',ok:sh=>sh.git&&mine(sh.git).some(x=>reach(sh.git,sh.git.remote.main).has(x.id))},
  {t:'Click <b>👤 A colleague pushes</b>, commit another change of your own and push it: GitHub rejects it.',h:'edit, git add, git commit -m "...", git push',ok:(sh,c,o)=>/^git\s+push/.test(c)&&/\[rejected\]/.test(o)},
  {t:'Bring the colleague\'s commit with <code>git pull</code>, then push again.',h:'git pull, then git push',ok:sh=>{const G=sh.git;return!!G&&Object.values(G.commits).some(x=>x.by==='colleague'&&reach(G,G.remote.main).has(x.id))&&mine(G).some(x=>x.p.length>1&&reach(G,G.remote.main).has(x.id))}},
  {t:'Make a branch <code>feature</code>, commit a change on it, go back to <code>main</code> and merge it.',h:'git switch -c feature; edit; git commit -am "..."; git switch main; git merge feature',ok:(sh,c)=>{const G=sh.git;return!!G&&G.head==='main'&&/^git\s+merge/.test(c)&&mine(G).some(x=>x.branch!=='main'&&reach(G,G.br.main).has(x.id))}},
];
window.ISOGIT={git,cmdGit,colleague,merge3,unified,state,layout};
})();
