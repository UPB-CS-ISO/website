/* ISO demo shell: an in-memory file system and the commands of lectures 02 and 03.
   Pure logic, no DOM: the page widget and the node tests both use it. */
const ISOSH=(()=>{'use strict';
const HOME=['home','student'], USER='student';
let clock=Date.UTC(2026,8,30,14,20);           // Sep 30 2026, advances with every change
const now=()=>(clock+=60000);
const D=(c={},m)=>({t:'d',c,m:m||clock});
const F=(data='',size,m)=>({t:'f',data,s:size==null?data.length:size,m:m||clock});
const L=(target,m)=>({t:'l',target,m:m||clock});                 // a soft link
const C=(dev,maj,min)=>({t:'c',dev,maj,min,m:clock});             // a character device

const PROFILES={};                                   // extra files, added by other scripts (lecture 07)
function makeFS(profile,variant){
  const t=(mo,d,h,mi)=>Date.UTC(2026,mo,d,h,mi);
  const fs=D({
    bin:D({bash:F('',1396520),cat:F('',35280),cp:F('',141824),ls:F('',138216),mkdir:F('',80264),mv:F('',137688),pwd:F('',35400),rm:F('',59912),rmdir:F('',43464),touch:F('',96520)}),
    boot:D({'vmlinuz-6.8':F('',14753160),'initrd.img-6.8':F('',71532848),grub:D({'grub.cfg':F('# GRUB configuration\n',9120)})}),
    dev:D({null:C('null',1,3),zero:C('zero',1,5),urandom:C('urandom',1,9),tty:C('tty',5,0),pts:D({'0':C('pts',136,0)}),sda:F('',0),sda1:F('',0)}),
    etc:D({passwd:F('root:x:0:0:root:/root:/bin/bash\nstudent:x:1000:1000:Student:/home/student:/bin/bash\nbob:x:1001:1001:Bob:/home/bob:/bin/bash\n'),
      hostname:F('iso\n'),fstab:F('/dev/sda1  /  ext4  defaults  0 1\n')}),
    home:D({
      student:D({
        '.bashrc':F('# ~/.bashrc\nalias ll="ls -l"\n',3771,t(8,1,9,0)),
        Downloads:D({'supergirl.mp4':F('',734003200,t(8,20,18,2)),'michael.mp4':F('',912261120,t(8,20,18,1))},t(8,20,18,2)),
        Movies:D({'the_odyssey.mkv':F('',1610612736,t(8,26,21,15))},t(8,26,21,15)),
        'watchlist.txt':F('Project Hail Mary\n',21504,t(8,28,21,40)),
      },t(8,28,21,40)),
      bob:D({'notes.txt':F('buy popcorn\n')}),
    }),
    lib:D({'libc.so.6':F('',2125328),modules:D()}),
    media:D({cdrom:D(),usb:D()}),
    mnt:D({temp:D()}),
    opt:D({google:D({chrome:D()})}),
    proc:D({cpuinfo:F('processor\t: 0\nmodel name\t: Virtual CPU\n',0),'1':D()}),
    root:D(),
    sbin:D({fsck:F('',354000),mount:F('',59000),reboot:F('',0)}),
    sys:D({class:D({net:D({eth0:D(),lo:D()})})}),
    tmp:D(),
    usr:D({bin:D({firefox:F('',0),git:F('',4000000),python3:F('',6000000),sort:F('',120000),wc:F('',44000),head:F('',43000),tail:F('',60000),grep:F('',190000),xxd:F('',18000),ps:F('',150000),readlink:F('',40000),ln:F('',60000),perl:F('',4000000)}),lib:D(),share:D({man:D(),doc:D({bash:D({'README':F('Bash is the GNU shell\n')}),git:D({'README.md':F('Git: fast version control\n')})})})}),
    var:D({log:D({syslog:F('Sep 30 14:00 iso kernel: started\n')}),cache:D(),lib:D()}),
  });
  if(profile==='03'){                                 // the files of lecture 03
    const h=fs.c.home.c.student.c;
    h['fruits.txt']=F('cherry\napple\nbanana\n',null,t(9,12,9,10));
    h['notes.txt']=F('buy milk\ncall mom\n',null,t(9,12,9,12));
    h['unsorted.txt']=F('pear\nfig\nkiwi\nfig\napple\n',null,t(9,12,9,14));
    h.backup=D({},t(9,12,9,15));
    h.project=D({'notes.txt':F('deadline: Friday\n',null,t(9,12,9,16))},t(9,12,9,16));
  }
  if(PROFILES[profile])PROFILES[profile](fs,{D,F,L,t,HOME},variant);
  return fs;
}
const clone=n=>n.t==='d'?{t:'d',m:n.m,c:Object.fromEntries(Object.entries(n.c).map(([k,v])=>[k,clone(v)]))}:Object.assign({},n);

/* ---------- paths ---------- */
const pstr=p=>'/'+p.join('/');
const isPre=(a,b)=>a.length<=b.length&&a.every((x,i)=>x===b[i]);   // a is b or an ancestor of b
function split(cwd,p){
  let base;
  if(p==='~'||p.startsWith('~/')){base=HOME.slice();p=p.slice(1)}
  else if(p.startsWith('/'))base=[];
  else base=cwd.slice();
  for(const s of p.split('/')){
    if(s===''||s==='.')continue;
    if(s==='..'){base.pop();continue}                // `/..` is still `/`
    base.push(s);
  }
  return base;
}
function lookup(root,parts,nofollow,depth=0){        // {node, real} or {err}; follows soft links
  let n=root, real=[];
  for(let i=0;i<parts.length;i++){
    if(n.t!=='d')return{err:'Not a directory'};
    if(i===0&&parts[0]==='root'&&i<parts.length-1)return{err:'Permission denied'};
    const c=n.c[parts[i]];
    if(!c)return{err:'No such file or directory'};
    if(c.t==='l'&&(i<parts.length-1||!nofollow)){
      if(depth>=40)return{err:'Too many levels of symbolic links'};
      const r=lookup(root,split(real,c.target),false,depth+1);
      if(r.err)return r;
      n=r.node; real=r.real;
    }else{n=c;real=real.concat(parts[i])}
  }
  return{node:n,real};
}
const writable=parts=>(isPre(HOME,parts)&&parts.length>HOME.length)||(parts[0]==='tmp'&&parts.length>1);

/* ---------- words ---------- */
function words(line){                                // [{w,q}] q: quoted (no glob)
  const out=[];let cur=null,i=0;
  while(i<line.length){
    const ch=line[i];
    if(/\s/.test(ch)){if(cur){out.push(cur);cur=null}i++;continue}
    if(!cur)cur={w:'',q:false,glob:false};
    if(ch==='"'||ch==="'"){const j=line.indexOf(ch,i+1);if(j<0)return{err:'unexpected EOF while looking for matching `'+ch+"'"};let t=line.slice(i+1,j);if(ch==='"')t=t.replace(/\$\$/g,'\u0005');cur.w+=t;cur.q=true;i=j+1;continue}
    if(ch==='$'&&line[i+1]==='$'){cur.w+='\u0005';i+=2;continue}
    if(ch==='\\'&&i+1<line.length){cur.w+=line[i+1];i+=2;continue}
    if(ch==='&'&&line[i+1]==='&'||ch===';'){if(cur&&cur.w!==''||cur&&cur.q)out.push(cur);out.push({op:ch===';'?';':'&&'});cur=null;i+=ch===';'?1:2;continue}
    if(ch==='|'&&line[i+1]!=='|'){if(cur.w||cur.q)out.push(cur);out.push({op:'|'});cur=null;i++;continue}
    if((ch==='2'||ch==='&')&&cur.w===''&&!cur.q&&line[i+1]==='>'){        // 2> 2>> 2>&1 &> &>>
      let op=ch+'>',j=i+2;
      if(line[j]==='>'){op+='>';j++}
      else if(ch==='2'&&line[j]==='&'&&line[j+1]==='1'){op='2>&1';j+=2}
      out.push({op});cur=null;i=j;continue}
    if(ch==='<'){if(cur.w||cur.q)out.push(cur);out.push({op:'<'});cur=null;i++;continue}
    if(ch==='>'){if(cur.w||cur.q){out.push(cur)}const app=line[i+1]==='>';out.push({op:app?'>>':'>'});cur=null;i+=app?2:1;continue}
    if(ch==='*'||ch==='?')cur.glob=true;
    cur.w+=ch;i++;
  }
  if(cur)out.push(cur);
  return{list:out};
}
const utf8=t=>Array.from(unescape(encodeURIComponent(t)),c=>c.charCodeAt(0));
const globRe=p=>new RegExp('^'+p.replace(/[.+^${}()|[\]\\]/g,'\\$&').replace(/\*/g,'.*').replace(/\?/g,'.')+'$');
const sortNames=a=>a.sort((x,y)=>{const k=s=>s.replace(/^\.+/,'').toLowerCase();return k(x)<k(y)?-1:k(x)>k(y)?1:x<y?-1:1});

/* ---------- formatting ---------- */
const MON=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const pad=(s,n,r)=>{s=String(s);return r?s.padStart(n):s.padEnd(n)};
function hsize(b){if(b<1024)return String(b);const u=['K','M','G','T'];let v=b,i=-1;do{v/=1024;i++}while(v>=1024&&i<3);return(v<10?(Math.ceil(v*10)/10).toFixed(1):String(Math.ceil(v)))+u[i]}
const dsize=n=>n.t==='d'?4096:n.t==='l'?n.target.length:n.t==='c'?0:n.s;
function mode(parts,n){
  if(n.t==='d')return'drwxr-xr-x';
  if(n.t==='l')return'lrwxrwxrwx';
  if(n.exe)return'-rwxr-xr-x';
  if(n.t==='c')return n.dev==='pts'?'crw--w----':'crw-rw-rw-';
  if(parts[0]==='proc')return'-r--r--r--';
  if(parts[0]==='bin'||parts[0]==='sbin'||(parts[0]==='usr'&&parts[1]==='bin'))return'-rwxr-xr-x';
  return'-rw-r--r--';
}
const owner=parts=>(isPre(HOME,parts)&&parts.length>=2)||(parts[0]==='dev'&&parts[1]==='pts')||(parts[0]==='proc'&&/^(\d{4,}|self)$/.test(parts[1]||''))||(parts[0]==='tmp'&&parts.length>1)?USER:parts[0]==='home'&&parts[1]==='bob'?'bob':'root';
const fdate=m=>{const d=new Date(m);return MON[d.getUTCMonth()]+' '+pad(d.getUTCDate(),2,1)+' '+pad(d.getUTCHours(),2,1).replace(' ','0')+':'+String(d.getUTCMinutes()).padStart(2,'0')};
const links=n=>n.t==='d'?2+Object.values(n.c).filter(x=>x.t==='d').length:1;

/* ---------- manual pages (short, as in the slides) ---------- */
const MAN={
  pwd:['pwd - print the name of the current working directory','pwd [OPTION]...'],
  cd:['cd - change the current directory (a bash builtin)','cd [DIR]','no DIR: the home directory. `-`: the previous directory.'],
  ls:['ls - list directory contents','ls [OPTION]... [FILE]...','-a  include the names that start with .\n-l  long listing\n-h  sizes in K, M, G (with -l)\n-d  list a directory itself, not its contents'],
  tree:['tree - list the contents of directories in a tree-like format','tree [OPTION]... [DIRECTORY]...','-a  include hidden files\n-d  only directories\n-L n  at most n levels deep'],
  find:['find - search for files in a directory hierarchy','find [DIRECTORY]... [FILTER]...','-name PATTERN  the name matches PATTERN (* any characters, ? one character)\n-type f|d      only files | only directories\n-maxdepth n    at most n levels below the start'],
  cp:['cp - copy files and directories','cp [OPTION]... SOURCE DEST\ncp [OPTION]... SOURCE... DIRECTORY','-r  copy directories recursively'],
  mv:['mv - move (rename) files','mv [OPTION]... SOURCE DEST\nmv [OPTION]... SOURCE... DIRECTORY',''],
  mkdir:['mkdir - make directories','mkdir [OPTION]... DIRECTORY...','-p  make parent directories as needed, no error if existing'],
  touch:['touch - change file timestamps','touch [OPTION]... FILE...','a FILE that does not exist is created empty'],
  rm:['rm - remove files or directories','rm [OPTION]... [FILE]...','-r  remove directories and their contents recursively\n-f  ignore nonexistent files, never prompt'],
  rmdir:['rmdir - remove empty directories','rmdir [OPTION]... DIRECTORY...',''],
  cat:['cat - concatenate files and print on the standard output','cat [OPTION]... [FILE]...',''],
  echo:['echo - display a line of text','echo [STRING]...','echo text > file   writes the text into file\necho text >> file  appends it'],
  nano:['nano - a small text editor','nano [FILE]','Ctrl+O save, Ctrl+X exit'],
  man:['man - an interface to the system reference manuals','man PAGE',''],
  sort:['sort - sort lines of text files','sort [OPTION]... [FILE]...','-r  reverse\n-n  compare numbers\n-u  only one of the equal lines\nno FILE: read stdin'],
  wc:['wc - print newline, word, and byte counts for each file','wc [OPTION]... [FILE]...','-l  lines\n-w  words\n-c  bytes'],
  head:['head - output the first part of files','head [OPTION]... [FILE]...','-n N  the first N lines (10 by default)'],
  tail:['tail - output the last part of files','tail [OPTION]... [FILE]...','-n N  the last N lines (10 by default)'],
  grep:['grep - print lines that match patterns','grep [OPTION]... PATTERNS [FILE]...','-i  ignore case\n-v  the lines that do not match\n-c  count the lines\n-n  line numbers\n-E  extended regular expressions (a|b)\n-A N, -B N, -C N  also print N lines after, before, around each match'],
  uniq:['uniq - report or omit repeated lines','uniq [OPTION]... [INPUT]','-c  prefix lines by the number of occurrences'],
  xxd:['xxd - make a hex dump','xxd [-l LEN] [FILE]','-l LEN  stop after LEN bytes'],
  ln:['ln - make links between files','ln -s TARGET LINK_NAME','-s  make a symbolic (soft) link\n-f  remove an existing LINK_NAME'],
  readlink:['readlink - print resolved symbolic links','readlink [OPTION]... FILE...','-f  follow every link, print the absolute path'],
  ps:['ps - report a snapshot of the current processes','ps [-e] [-f] [-o FORMAT]','-e  every process\n-f  full format\n-o pid,ppid,stat,comm,cmd  the columns'],
  pstree:['pstree - display a tree of processes','pstree [-p]','-p  show the PIDs'],
  lsof:['lsof - list open files','lsof -p PID',''],
  file:['file - determine file type','file [-b] [-L] FILE...','-b  only the type, without the name\n-L  follow symbolic links'],
  clear:['clear - clear the terminal screen','clear','Ctrl+L does the same.'],
  history:['history - the commands typed in this shell (a bash builtin)','history','!N runs command N again (not in this demo).'],
  hostname:['hostname - show the name of the computer','hostname'],
  whoami:['whoami - print the name of the current user','whoami'],
  which:['which - show where a command is','which COMMAND...','searches the folders of $PATH'],
  sleep:['sleep - wait for a number of seconds','sleep NUMBER'],
  true:['true - do nothing, successfully (exit code 0)','true'],
  false:['false - do nothing, unsuccessfully (exit code 1)','false'],
  help:['help - the commands of this demo terminal','help'],
  reset:['reset - (in this demo) put the files back as they were at the start','reset'],
  man:['man - an interface to the system reference manuals','man PAGE','q quits the real man; / searches.\nSections: 1 commands, 2 system calls, 3 library functions (man 3 printf).'],
};

/* ---------- the shell ---------- */
class Shell{
  constructor(opts={}){
    this.profile=opts.profile; this.variant=opts.variant; this.root=makeFS(this.profile,this.variant); this.cwd=opts.cwd?split(HOME,opts.cwd):HOME.slice(); this.cwd0=this.cwd.slice(); this.old=null; this.hist=[];
    this.pid=4100; this.next=4300; this.procs=[];
    this.syncClock();
    if(this.profile==='03'&&clock<Date.UTC(2026,9,12,9,20))clock=Date.UTC(2026,9,12,9,20);
  }
  syncClock(){let m=0;const rec=n=>{if(n.m>m)m=n.m;if(n.t==='d')for(const k in n.c)rec(n.c[k])};rec(this.root);if(clock<=m)clock=m+60000}
  reset(){this.root=makeFS(this.profile,this.variant);this.syncClock();this.cwd=this.cwd0.slice();this.old=null;this.next=4300}
  prompt(){const p=pstr(this.cwd);const h=pstr(HOME);return USER+'@iso:'+(p===h?'~':p.startsWith(h+'/')?'~'+p.slice(h.length):p)+'$'}
  get(p){return lookup(this.root,split(this.cwd,p))}
  expand(list){                                       // glob in the last part of a word
    const out=[];
    for(const w of list){
      if(w.op){out.push(w);continue}
      if(!w.q&&(w.w==='~'||w.w.startsWith('~/')))w.w='/'+HOME.join('/')+w.w.slice(1);
      if(w.w.includes('\u0005'))w.w=w.w.replace(/\u0005/g,String(this.pid));
      if(!w.q&&/\$[A-Za-z_]/.test(w.w))w.w=w.w.replace(/\$([A-Za-z_]\w*)/g,(_,n)=>n==='HOME'?'/'+HOME.join('/'):n==='USER'?USER:n==='PWD'?pstr(this.cwd):(this.vars||{})[n]||'');
      if(!w.glob||w.q){out.push(w.w);continue}
      const i=w.w.lastIndexOf('/'), dir=i<0?'':w.w.slice(0,i+1), pat=w.w.slice(i+1);
      const r=this.get(dir||'.'); const re=globRe(pat);
      const m=r.node&&r.node.t==='d'?sortNames(Object.keys(r.node.c).filter(n=>re.test(n)&&(pat.startsWith('.')||!n.startsWith('.')))):[];
      if(m.length)m.forEach(n=>out.push(dir+n));else out.push(w.w);
    }
    return out;
  }
  run(line){                                         // -> {out, err, clear?, edit?}
    line=line.trim(); if(!line)return{seq:[]};
    this.hist.push(line);
    return this.exec(line);
  }
  exec(line){                                        // run a line, without the history
    const ws=words(line); if(ws.err)return{seq:[{err:'bash: '+ws.err}]};
    const segs=[[]],ops=[];
    for(const w of ws.list){if(w.op==='&&'||w.op===';'){ops.push(w.op);segs.push([])}else segs[segs.length-1].push(w)}
    const seq=[];let clear=false,edit=null;const procs=[];
    for(let k=0;k<segs.length;k++){
      if(!segs[k].length){if(k===segs.length-1&&ops[k-1]===';')continue;if(k<segs.length-1||ops.length){seq.push({err:"bash: syntax error near unexpected token `"+(ops[k]||ops[k-1])+"'"});break}continue}
      const r=this.pipeline(segs[k]);
      if(r.clear){clear=true;seq.length=0}
      if(r.edit)edit=r.edit;
      seq.push(...r.seq);
      procs.push(...r.procs);
      if(r.code&&ops[k]==='&&')break;
    }
    this.procs=procs;
    return{seq,clear,edit,procs};
  }
  /* where a file descriptor points: tty (the terminal), pipe, file (parts), dev (a character device) */
  target(to,mode){                                   // mode: '<' read, '>' truncate, '>>' append
    const parts=split(this.cwd,to), x=lookup(this.root,parts);
    if(x.node&&x.node.t==='c')return{k:'dev',dev:x.node.dev,name:pstr(x.real)};
    if(mode==='<'){
      if(x.err)return{err:'bash: '+to+': '+x.err};
      if(x.node.t==='d')return{err:'bash: '+to+': Is a directory'};
      return{k:'file',node:x.node,name:pstr(x.real)};
    }
    const real=x.node?x.real:parts, par=lookup(this.root,real.slice(0,-1));
    if(!par.node||par.node.t!=='d')return{err:'bash: '+to+': No such file or directory'};
    if(x.node&&x.node.t==='d')return{err:'bash: '+to+': Is a directory'};
    const pr=par.real.concat(real[real.length-1]);
    if(!writable(pr))return{err:'bash: '+to+': Permission denied'};
    let node=par.node.c[pr[pr.length-1]];
    if(!node||node.t==='l'){node=F('',null,now());par.node.c[pr[pr.length-1]]=node}
    else if(mode==='>'){node.data='';node.s=0;node.m=now()}
    return{k:'file',node,name:pstr(pr)};
  }
  label(t){return t.k==='tty'?(this.tty||'terminal'):t.k==='pipe'?'pipe':t.name}
  pipeline(list){
    const cmds=[[]];
    for(const w of list){if(w.op==='|')cmds.push([]);else cmds[cmds.length-1].push(w)}
    const seq=[],procs=[];let pipe=null,code=0,clear=false,edit=null;
    if(cmds.some(c=>!c.length))return{seq:[{err:"bash: syntax error near unexpected token `|'"}],procs,code:2};
    for(let k=0;k<cmds.length;k++){
      const words=[],red=[];
      const ex=this.expand(cmds[k]);
      for(let i=0;i<ex.length;i++){const a=ex[i];
        if(a&&a.op){
          if(a.op==='2>&1'){red.push({op:a.op});continue}
          const t=ex[i+1];if(typeof t!=='string')return{seq:seq.concat({err:"bash: syntax error near unexpected token `newline'"}),procs,code:2};
          red.push({op:a.op,to:t});i++;continue}
        words.push(a)}
      const fds={0:{k:k>0?'pipe':'tty'},1:{k:k<cmds.length-1?'pipe':'tty'},2:{k:'tty'}}, changed=new Set();
      if(k>0)changed.add(0); if(k<cmds.length-1)changed.add(1);
      let bad=null;
      for(const r of red){
        if(r.op==='2>&1'){fds[2]=fds[1];changed.add(2);continue}
        const fd=r.op==='<'?0:r.op.startsWith('2')?2:1, mode=r.op==='<'?'<':r.op.endsWith('>>')?'>>':'>';
        const t=this.target(r.to,mode); if(t.err){bad=t.err;break}
        if(r.op.startsWith('&')){fds[1]=t;fds[2]=t;changed.add(1);changed.add(2)}else{fds[fd]=t;changed.add(fd)}
      }
      if(bad){seq.push({err:bad});code=1;pipe='';continue}
      let stdin=null;
      if(fds[0].k==='pipe')stdin=pipe||'';
      else if(fds[0].k==='file')stdin=fds[0].node.data;
      else if(fds[0].k==='dev')stdin=fds[0].dev==='null'?'':fds[0].dev==='pts'?null:{dev:fds[0].dev};
      // NAME=value before the command: an environment variable for this command only; alone, for the shell
      const envOne={};while(words.length&&/^[A-Za-z_]\w*=/.test(words[0])){const w=words.shift(),i=w.indexOf('=');envOne[w.slice(0,i)]=w.slice(i+1)}
      if(!words.length){this.vars=Object.assign(this.vars||{},envOne);procs.push({pid:this.next++,cmd:'',fds:[]});continue}
      this.env=Object.assign({},this.vars||{},envOne);
      const cmd=words[0];
      const pid=this.next++;
      this.self={pid,comm:cmd||'bash',args:words,fds,opened:[]};this.isatty=fds[1].k==='tty'||fds[1].k==='dev'&&fds[1].dev==='pts';
      if(cmd!==undefined)this.root.c.proc=this.makeProc();
      let res={};
      if(cmd!==undefined){
        const args=words.slice(1), fn=this['c_'+cmd];
        this.stdin=stdin;
        if(args.includes('--help')&&MAN[cmd]&&cmd!=='cd'&&cmd!=='git')res={out:'Usage: '+MAN[cmd][1].split('\n').join('\n  or:  ')+'\n'+MAN[cmd][0]+(MAN[cmd][2]?'\n\n'+MAN[cmd][2]:'')};
        else if(fn)res=fn.call(this,args)||{};
        else if(cmd.includes('/')&&this.runFile)res=this.runFile(cmd,args)||{};
        else if(['mc','nnn','yazi','vim','vi','sudo','apt','dnf','top','htop','kill'].includes(cmd))res={err:'iso-demo: '+cmd+' is not available in this demo terminal (use your own Linux)'};
        else res={err:'bash: '+cmd+': command not found (this demo terminal only knows the commands of lectures 02 and 03, type help)',code:127};
      }
      if(res.clear)clear=true; if(res.edit)edit=res.edit;
      code=res.code!=null?res.code:res.err?1:0;
      let next='';
      const write=(t,text)=>{
        if(text==null||text==='')return;
        if(t.k==='tty'||(t.k==='dev'&&t.dev==='pts'))seq.push(res.hl&&text===res.out?{out:text,hl:res.hl}:{out:text});
        else if(t.k==='pipe')next+=text+'\n';
        else if(t.k==='file'){t.node.data+=text+'\n';t.node.s=t.node.data.length;t.node.m=now()}
      };
      write(fds[1],res.out);
      if(res.seq)for(const x of res.seq){if(x.out!=null)write(fds[1],x.out);if(x.err){const t2=fds[2];if(t2.k==='tty'||(t2.k==='dev'&&t2.dev==='pts'))seq.push({err:x.err});else write(t2,x.err)}}
      // stderr: to the terminal as an error, else like stdout
      if(res.err){const t=fds[2];if(t.k==='tty'||(t.k==='dev'&&t.dev==='pts'))seq.push({err:res.err});else write(t,res.err)}
      if(res.note)seq.push({note:res.note});
      pipe=next;
      procs.push({pid,cmd:words.join(' '),fds:[0,1,2].map(f=>({fd:f,to:this.label(fds[f]),kind:fds[f].k,changed:changed.has(f)})).concat(this.self.opened.map((n,i)=>({fd:3+i,to:n,kind:'file',opened:true})))});
    }
    return{seq,procs,code,clear,edit};
  }
  /* the command reads FILE arguments (or stdin): [{name,text}] or an error */
  inputs(files,cmd){
    const out=[],err=[];
    if(!files.length){
      if(this.stdin===null)return{wait:"iso-demo: "+cmd+" is waiting for the keyboard (stdin). In a real terminal you type the lines, then Ctrl+D; this demo cannot: give it a file, or use < or |"};
      if(typeof this.stdin==='object')return{dev:this.stdin.dev,list:[]};
      return{list:[{name:'-',text:this.stdin}]};
    }
    for(const p of files){
      const parts=split(this.cwd,p), x=lookup(this.root,parts);
      if(x.err){err.push(cmd+': '+p+': '+x.err);continue}
      if(x.node.t==='d'){err.push(cmd+': '+p+': Is a directory');continue}
      this.self.opened.push(pstr(x.real));
      if(x.node.t==='c'){if(x.node.dev==='null'){out.push({name:p,text:''});continue}return{dev:x.node.dev,list:out,err:err.join('\n')||undefined}}
      out.push({name:p,text:x.node.data});
    }
    return{list:out,err:err.join('\n')||undefined};
  }
  opts(args,allowed,cmd){                            // split options from operands
    const o={},ops=[];let end=false;
    for(let i=0;i<args.length;i++){const a=args[i];
      if(!end&&a==='--'){end=true;continue}
      if(!end&&a.startsWith('--')&&a.length>2){const n=a.slice(2);const map={all:'a',recursive:'r',force:'f',parents:'p',directory:'d','human-readable':'h'};if(map[n]&&allowed.includes(map[n])){o[map[n]]=true;continue}return{err:cmd+": unrecognized option '"+a+"'\nTry '"+cmd+" --help' for more information."}}
      if(!end&&a.startsWith('-')&&a.length>1&&a!=='-'){for(const ch of a.slice(1)){if(!allowed.includes(ch))return{err:cmd+": invalid option -- '"+ch+"'\nTry '"+cmd+" --help' for more information."};o[ch]=true;if(ch==='R')o.r=true}continue}
      ops.push(a);
    }
    return{o,ops};
  }
  fix(){                                             // the current directory was removed
    while(this.cwd.length&&!lookup(this.root,this.cwd).node)this.cwd.pop();
  }

  c_pwd(){return{out:pstr(this.cwd)}}
  c_whoami(){return{out:USER}}
  c_hostname(){return{out:'iso'}}
  c_clear(){return{out:'',clear:true}}
  c_history(){return{out:this.hist.map((h,i)=>pad(i+1,5,1)+'  '+h).join('\n')}}
  c_reset(){this.reset();return{out:'the sandbox file system was reset',clear:true}}
  c_help(){return{out:'this is a demo terminal (a simulation, not a real Linux)\ncommands: pwd cd ls tree find cp mv mkdir touch nano rm rmdir cat echo man clear history reset\n'+
    '          sort wc head tail grep uniq xxd ln readlink ps pstree lsof which sleep file\n'+
    'redirects: < > >> 2> 2>> &> 2>&1 and | pipes; $$ is the PID of the shell\n'+
    'paths: absolute (/home/student), relative (../Movies), ~ (home), . and ..\n'+
    'keys: Tab completes a name, ↑ ↓ the previous commands, Ctrl+L clears'}}
  c_man(args){
    if(!args.length)return{err:'What manual page do you want?\nFor example, try \'man man\'.'};
    const m=MAN[args[0]]; if(!m)return{err:'No manual entry for '+args[0]};
    const N=args[0].toUpperCase()+'('+(m[3]||1)+')';
    return{out:N+'                      User Commands                      '+N+'\n\nNAME\n       '+m[0]+'\n\nSYNOPSIS\n       '+m[1].split('\n').join('\n       ')+(m[2]?'\n\nDESCRIPTION\n       '+m[2].split('\n').join('\n       '):'')+'\n\n(short version for the sandbox, the real page is: man '+args[0]+' in a terminal)'};
  }
  c_echo(args){return{out:args.join(' ')}}
  c_cd(args){
    if(args.length>1)return{err:'bash: cd: too many arguments'};
    let p=args[0]; let print=false;
    if(p===undefined||p==='')p='~';
    if(p==='-'){if(!this.old)return{err:'bash: cd: OLDPWD not set'};p=pstr(this.old);print=true}
    const parts=split(this.cwd,p), r=lookup(this.root,parts);
    if(r.err)return{err:'bash: cd: '+args[0]+': '+r.err};
    if(r.node.t!=='d')return{err:'bash: cd: '+args[0]+': Not a directory'};
    if(parts[0]==='root')return{err:'bash: cd: '+args[0]+': Permission denied'};
    this.old=this.cwd; this.cwd=parts;
    return{out:print?pstr(parts):''};
  }
  lsLong(entries,h){                                  // entries: [name, parts, node]
    const sz=n=>h?hsize(dsize(n)):String(dsize(n)), w=Math.max(...entries.map(e=>e[2].t==='c'?(e[2].maj+', '+e[2].min).length:sz(e[2]).length));
    return entries.map(([name,parts,n])=>{
      return mode(parts,n)+' '+pad(links(n),2,1)+' '+pad(owner(parts),5)+' '+pad(owner(parts),5)+' '+pad(n.t==='c'?n.maj+', '+n.min:sz(n),w,1)+' '+fdate(n.m)+' '+name+(n.t==='l'?' -> '+n.target:'');
    });
  }
  c_ls(args){
    const r=this.opts(args,'alhd1R','ls'); if(r.err)return{err:r.err};
    const {o}=r, ops=r.ops.length?r.ops:['.'];
    const err=[], files=[], dirs=[];
    for(const p of ops){
      const parts=split(this.cwd,p), xl=lookup(this.root,parts,true);
      if(xl.err){err.push("ls: cannot access '"+p+"': "+xl.err);continue}
      if(xl.node.t==='l'&&(o.l||o.d)&&!p.endsWith('/')){files.push([p,parts,xl.node]);continue}
      const x=lookup(this.root,parts);
      if(x.err){err.push("ls: cannot access '"+p+"': "+x.err);continue}
      if(x.node.t!=='d'||o.d)files.push([p,parts,x.node]);
      else if(parts[0]==='root'&&parts.length===1)err.push("ls: cannot open directory '"+p+"': Permission denied");
      else dirs.push([p,parts,x.node]);
    }
    const q=n=>/[\s'"]/.test(n)?"'"+n+"'":n;
    const dc=(n,x)=>!this.color||this.isatty===false?n:x.t==='d'?'\u0001'+n+'\u0002':x.t==='l'?'\u0003'+n+'\u0002':x.t==='c'?'\u0004'+n+'\u0002':n;
    const fmt=list=>{list=list.map(e=>[dc(q(e[0]),e[2]),e[1],e[2]]);return o.l?this.lsLong(list,o.h).join('\n'):list.map(e=>e[0]).join(this.isatty===false?'\n':'  ')};
    const blocks=[];
    if(files.length)blocks.push(fmt(files));
    const many=ops.length>1;
    for(const [p,parts,n] of dirs){
      let names=sortNames(Object.keys(n.c).filter(k=>o.a||!k.startsWith('.')));
      let list=names.map(k=>[k,parts.concat(k),n.c[k]]);
      if(o.a){const par=lookup(this.root,parts.slice(0,-1)).node;list=[['.',parts,n],['..',parts.slice(0,-1),par]].concat(list)}
      let body=fmt(list);
      if(o.l){const tot=list.reduce((s,e)=>s+Math.ceil(dsize(e[2])/4096)*4,0);body='total '+(o.h?hsize(tot*1024):tot)+(body?'\n'+body:'')}
      blocks.push((many?p+':'+(body?'\n':''):'')+body);
    }
    return{out:blocks.join('\n\n'),err:err.join('\n')||undefined};
  }
  c_tree(args){
    let L=Infinity; const rest=[];
    for(let i=0;i<args.length;i++){if(args[i]==='-L'){L=parseInt(args[++i],10);if(!(L>0))return{err:'tree: Invalid level, must be greater than 0.'};continue}rest.push(args[i])}
    const r=this.opts(rest,'ad','tree'); if(r.err)return{err:r.err.replace(/\nTry.*/,'')};
    const {o}=r, ops=r.ops.length?r.ops:['.'];
    let nd=0,nf=0; const out=[];
    const walk=(n,pre,depth)=>{
      if(depth>L)return;
      const names=sortNames(Object.keys(n.c).filter(k=>(o.a||!k.startsWith('.'))&&(!o.d||n.c[k].t==='d')));
      names.forEach((k,i)=>{const last=i===names.length-1, c=n.c[k];
        out.push(pre+(last?'└── ':'├── ')+(this.color&&this.isatty!==false&&c.t==='d'?'\u0001'+k+'\u0002':this.color&&this.isatty!==false&&c.t==='l'?'\u0003'+k+'\u0002':k)+(c.t==='l'?' -> '+c.target:''));
        if(c.t==='d'){nd++;walk(c,pre+(last?'    ':'│   '),depth+1)}else nf++;
      });
    };
    for(const p of ops){
      const x=this.get(p);
      if(x.err||x.node.t!=='d'){out.push(p+(x.node?'  [error opening dir]':' [error opening dir]'));continue}
      out.push(p);nd++;walk(x.node,'',1);
    }
    out.push('');
    out.push(nd+(nd===1?' directory':' directories')+(o.d?'':', '+nf+(nf===1?' file':' files')));
    return{out:out.join('\n')};
  }
  c_find(args){
    const starts=[];let i=0;
    while(i<args.length&&!args[i].startsWith('-'))starts.push(args[i++]);
    if(!starts.length)starts.push('.');
    const f=[];let maxd=Infinity;
    while(i<args.length){const a=args[i++];
      if(a==='-name'||a==='-iname'){if(i>=args.length)return{err:"find: missing argument to `"+a+"'"};f.push({k:a,v:args[i++]})}
      else if(a==='-type'){const v=args[i++];if(v!=='f'&&v!=='d'&&v!=='l')return{err:"find: Unknown argument to -type: "+(v||'')};f.push({k:'-type',v})}
      else if(a==='-maxdepth'){maxd=parseInt(args[i++],10)}
      else return{err:"find: unknown predicate `"+a+"'"};
    }
    const ok=(name,n)=>f.every(x=>x.k==='-type'?(x.v==='d'?n.t==='d':x.v==='l'?n.t==='l':n.t==='f'):x.k==='-name'?globRe(x.v).test(name):new RegExp(globRe(x.v).source,'i').test(name));
    const out=[],err=[];
    for(const s of starts){
      const parts=split(this.cwd,s), x=lookup(this.root,parts);
      if(x.err){err.push("find: '"+s+"': "+x.err);continue}
      const base=parts.length?parts[parts.length-1]:'/';
      const rec=(n,path,name,depth)=>{
        if(ok(name,n))out.push(path);
        if(n.t==='d'&&depth<maxd){
          for(const k of sortNames(Object.keys(n.c)))rec(n.c[k],(path.endsWith('/')?path:path+'/')+k,k,depth+1);
        }
      };
      rec(x.node,s,s==='.'||s==='..'?s:base,0);
    }
    return{out:out.join('\n'),err:err.join('\n')||undefined};
  }
  c_cat(args){
    const r=this.inputs(args.filter(a=>a!=='-'),'cat');
    if(r.wait)return{note:r.wait};
    if(r.dev)return{note:'iso-demo: /dev/'+r.dev+' never ends, cat would print forever: try xxd -l 8 < /dev/'+r.dev};
    const one=r.list.length===1?r.list[0].name.replace(/^.*\//,''):'';
    const hl=/^(GNU)?[Mm]akefile$/.test(one)?'make':/\.[ch]$/.test(one)?'c':/\.json$/.test(one)?'json':null;
    return{out:r.list.map(f=>f.text.replace(/\n$/,'')).filter((t,i)=>t!==''||r.list[i].text!=='').join('\n'),err:r.err,hl};
  }
  lines(r){return r.list.flatMap(f=>f.text===''?[]:f.text.replace(/\n$/,'').split('\n'))}
  c_sort(args){
    const o=this.opts(args,'rnu','sort'); if(o.err)return{err:o.err};
    const r=this.inputs(o.ops,'sort'); if(r.wait)return{note:r.wait}; if(r.dev)return{note:'iso-demo: /dev/'+r.dev+' never ends'};
    let l=this.lines(r);
    l.sort(o.o.n?(a,b)=>parseFloat(a)-parseFloat(b)||(a<b?-1:a>b?1:0):(a,b)=>{const x=a.toLowerCase(),y=b.toLowerCase();return x<y?-1:x>y?1:a<b?-1:a>b?1:0});
    if(o.o.r)l.reverse(); if(o.o.u)l=l.filter((x,i)=>i===0||x!==l[i-1]);
    return{out:l.join('\n'),err:r.err};
  }
  c_uniq(args){
    const o=this.opts(args,'c','uniq'); if(o.err)return{err:o.err};
    const r=this.inputs(o.ops.slice(0,1),'uniq'); if(r.wait)return{note:r.wait};
    const out=[];let prev=null,n=0;
    for(const x of this.lines(r).concat([null])){if(x===prev){n++;continue}if(prev!==null)out.push(o.o.c?pad(n,7,1)+' '+prev:prev);prev=x;n=1}
    return{out:out.join('\n'),err:r.err};
  }
  c_wc(args){
    const o=this.opts(args,'lwc','wc'); if(o.err)return{err:o.err};
    const r=this.inputs(o.ops,'wc'); if(r.wait)return{note:r.wait}; if(r.dev)return{note:'iso-demo: /dev/'+r.dev+' never ends'};
    const which=o.o.l||o.o.w||o.o.c?['l','w','c'].filter(k=>o.o[k]):['l','w','c'];
    const cnt=t=>({l:(t.match(/\n/g)||[]).length,w:t.split(/\s+/).filter(Boolean).length,c:utf8(t).length});
    const rows=r.list.map(f=>({n:f.name,v:cnt(f.text)}));
    if(rows.length>1)rows.push({n:'total',v:{l:rows.reduce((a,x)=>a+x.v.l,0),w:rows.reduce((a,x)=>a+x.v.w,0),c:rows.reduce((a,x)=>a+x.v.c,0)}});
    const w=which.length===1&&rows.length===1?0:rows[0].n==='-'?7:Math.max(...rows.flatMap(x=>which.map(k=>String(x.v[k]).length)));
    return{out:rows.map(x=>which.map(k=>pad(x.v[k],w,1)).join(' ')+(x.n==='-'?'':' '+x.n)).join('\n'),err:r.err};
  }
  headtail(args,cmd){
    let n=10;const rest=[];
    for(let i=0;i<args.length;i++){const a=args[i];
      if(a==='-n'){n=parseInt(args[++i],10);continue}
      if(/^-n\d+$/.test(a)){n=parseInt(a.slice(2),10);continue}
      if(/^-\d+$/.test(a)){n=parseInt(a.slice(1),10);continue}
      if(a.startsWith('-')&&a!=='-')return{err:cmd+": invalid option -- '"+a.slice(1)+"'"};
      rest.push(a)}
    if(!(n>=0))return{err:cmd+': invalid number of lines'};
    const r=this.inputs(rest,cmd); if(r.wait)return{note:r.wait}; if(r.dev)return{note:'iso-demo: /dev/'+r.dev+' is binary and endless: try xxd -l 8 < /dev/'+r.dev};
    const many=r.list.length>1;
    return{out:r.list.map(f=>{const l=f.text===''?[]:f.text.replace(/\n$/,'').split('\n');const part=cmd==='head'?l.slice(0,n):l.slice(Math.max(0,l.length-n));return(many?'==> '+f.name+' <==\n':'')+part.join('\n')}).join('\n\n'),err:r.err};
  }
  c_head(a){return this.headtail(a,'head')}
  c_tail(a){return this.headtail(a,'tail')}
  c_grep(args){
    const o={},rest=[];let A=0,B=0;
    for(let k=0;k<args.length;k++){const a=args[k];
      let m=a.match(/^-([ABC])(\d*)$/);if(m){const n=parseInt(m[2]||args[++k],10)||0;if(m[1]!=='B')A=n;if(m[1]!=='A')B=n;continue}
      if(/^-[ivcnE]+$/.test(a)){for(const ch of a.slice(1))o[ch]=true;continue}rest.push(a)}
    if(!rest.length)return{err:"Usage: grep [OPTION]... PATTERNS [FILE]...\nTry 'grep --help' for more information.",code:2};
    let re;try{re=new RegExp(rest[0],o.i?'i':'')}catch(e){return{err:'grep: Invalid regular expression',code:2}}
    const r=this.inputs(rest.slice(1),'grep'); if(r.wait)return{note:r.wait}; if(r.dev)return{note:'iso-demo: /dev/'+r.dev+' never ends'};
    const many=r.list.length>1,out=[];let found=0;
    for(const f of r.list){const l=f.text===''?[]:f.text.replace(/\n$/,'').split('\n');let c=0;
      const hit=l.map(x=>re.test(x)!==!!o.v);c=hit.filter(Boolean).length;found+=c;
      if(!o.c){let last=-1;l.forEach((x,i)=>{
        if(!hit.slice(Math.max(0,i-A),i+B+1).some(Boolean))return;           // a match, or within -A/-B lines of one
        if((A||B)&&last>=0&&i>last+1)out.push('--');last=i;
        out.push((many?f.name+(hit[i]?':':'-'):'')+(o.n?(i+1)+(hit[i]?':':'-'):'')+x)})}
      if(o.c)out.push((many?f.name+':':'')+c)}
    return{out:out.join('\n'),err:r.err,code:r.err?2:found?0:1};
  }
  c_xxd(args){
    let n=Infinity;const rest=[];
    for(let i=0;i<args.length;i++){if(args[i]==='-l'){n=parseInt(args[++i],10);continue}rest.push(args[i])}
    const r=this.inputs(rest,'xxd'); if(r.wait)return{note:r.wait};
    let bytes;
    if(r.dev){if(n===Infinity)return{note:'iso-demo: /dev/'+r.dev+' never ends: give xxd a length, xxd -l 8'};
      bytes=Array.from({length:n},()=>r.dev==='zero'?0:Math.floor(Math.random()*256))}
    else bytes=utf8(r.list.map(f=>f.text).join('')).slice(0,n);
    const out=[];
    for(let i=0;i<bytes.length;i+=16){const b=bytes.slice(i,i+16);let hex='';
      for(let j=0;j<16;j+=2)hex+=(j<b.length?b[j].toString(16).padStart(2,'0')+(j+1<b.length?b[j+1].toString(16).padStart(2,'0'):'  '):'    ')+' ';
      out.push(i.toString(16).padStart(8,'0')+': '+hex+' '+b.map(x=>x>=32&&x<127?String.fromCharCode(x):'.').join(''))}
    return{out:out.join('\n'),err:r.err};
  }
  c_ln(args){
    const o=this.opts(args,'sfn','ln'); if(o.err)return{err:o.err};
    if(!o.o.s)return{err:'iso-demo: this demo terminal only makes soft links: ln -s TARGET LINK_NAME'};
    if(!o.ops.length)return{err:"ln: missing file operand\nTry 'ln --help' for more information."};
    const target=o.ops[0];let name=o.ops[1];
    if(o.ops.length>2)return{err:'iso-demo: give ln -s one TARGET and one LINK_NAME'};
    if(name===undefined)name=target.replace(/\/+$/,'').split('/').pop();
    let parts=split(this.cwd,name);
    const ex=lookup(this.root,parts);
    if(ex.node&&ex.node.t==='d'){parts=ex.real.concat(target.replace(/\/+$/,'').split('/').pop());name=(name.endsWith('/')?name:name+'/')+parts[parts.length-1]}
    const par=lookup(this.root,parts.slice(0,-1));
    if(!par.node||par.node.t!=='d')return{err:"ln: failed to create symbolic link '"+name+"': No such file or directory"};
    const real=par.real.concat(parts[parts.length-1]);
    if(par.node.c[real[real.length-1]]&&!o.o.f)return{err:"ln: failed to create symbolic link '"+name+"': File exists"};
    if(!writable(real))return{err:"ln: failed to create symbolic link '"+name+"': Permission denied"};
    par.node.c[real[real.length-1]]=L(target,now());par.node.m=now();
    return{};
  }
  c_readlink(args){
    const o=this.opts(args,'fe','readlink'); if(o.err)return{err:o.err};
    if(!o.ops.length)return{err:"readlink: missing operand\nTry 'readlink --help' for more information."};
    const out=[];let code=0;
    for(const p of o.ops){
      const parts=split(this.cwd,p);
      if(o.o.f||o.o.e){const x=lookup(this.root,parts);if(x.err){code=1;continue}out.push(pstr(x.real));continue}
      const x=lookup(this.root,parts,true);
      if(x.node&&x.node.t==='l')out.push(x.node.target);else code=1;
    }
    return{out:out.join('\n'),code};
  }
  c_which(args){
    const out=[];let code=0;
    for(const a of args){const d=['usr/bin','bin','sbin'].find(d=>lookup(this.root,d.split('/').concat(a)).node);if(d)out.push('/'+d+'/'+a);else code=1}
    return{out:out.join('\n'),code};
  }
  c_sleep(args){if(!args.length)return{err:"sleep: missing operand\nTry 'sleep --help' for more information."};return{note:'iso-demo: sleep '+args[0]+' would wait '+args[0]+' seconds in state S (sleeping); the demo skips the wait'}}
  /* ---------- processes ---------- */
  ptable(){
    const T=[
      {pid:1,ppid:0,stat:'Ss',comm:'systemd',cmd:'/sbin/init',tty:'?',user:'root'},
      {pid:2,ppid:0,stat:'S',comm:'kthreadd',cmd:'[kthreadd]',tty:'?',user:'root'},
      {pid:512,ppid:1,stat:'Ss',comm:'systemd-udevd',cmd:'/lib/systemd/systemd-udevd',tty:'?',user:'root'},
      {pid:640,ppid:1,stat:'Ssl',comm:'NetworkManager',cmd:'/usr/sbin/NetworkManager --no-daemon',tty:'?',user:'root'},
      {pid:1000,ppid:1,stat:'Ss',comm:'systemd',cmd:'/lib/systemd/systemd --user',tty:'?',user:USER},
      {pid:1200,ppid:1000,stat:'Sl',comm:'gnome-shell',cmd:'/usr/bin/gnome-shell',tty:'?',user:USER},
      {pid:4090,ppid:1000,stat:'Sl',comm:'gnome-terminal-',cmd:'/usr/libexec/gnome-terminal-server',tty:'?',user:USER},
      {pid:4100,ppid:4090,stat:'Ss',comm:'bash',cmd:'bash',tty:'pts/0',user:USER},
      {pid:4210,ppid:4100,stat:'S',comm:'sleep',cmd:'sleep 600',tty:'pts/0',user:USER},
      {pid:4211,ppid:4100,stat:'R',comm:'yes',cmd:'yes',tty:'pts/0',user:USER},
      {pid:4213,ppid:4100,stat:'Sl',comm:'myapp',cmd:'./myapp',tty:'pts/0',user:USER},
      {pid:4214,ppid:4213,stat:'Z',comm:'myapp-worker',cmd:'[myapp-worker] <defunct>',tty:'pts/0',user:USER},
    ];
    if(this.self)T.push({pid:this.self.pid,ppid:4100,stat:'R+',comm:this.self.comm,cmd:this.self.args.join(' '),tty:'pts/0',user:USER});
    return T;
  }
  c_ps(args){
    let all=false,full=false,cols=null;
    for(let i=0;i<args.length;i++){const a=args[i];
      if(a==='-o'){cols=(args[++i]||'').split(',');continue}
      if(a==='aux'||a==='-aux')return{note:'iso-demo: this demo knows ps, ps -e, ps -ef and ps -o pid,ppid,stat,comm,cmd'};
      if(/^-[ef]+$/.test(a)){if(a.includes('e'))all=true;if(a.includes('f'))full=true;continue}
      return{err:'error: unsupported option '+a+' (this demo knows -e, -f, -o)'}}
    const C={pid:['PID',7,1,p=>p.pid],ppid:['PPID',7,1,p=>p.ppid],stat:['STAT',4,0,p=>p.stat],comm:['COMMAND',0,0,p=>p.comm],cmd:['CMD',0,0,p=>p.cmd],args:['COMMAND',0,0,p=>p.cmd],
      tty:['TTY',8,0,p=>p.tty],time:['TIME',8,1,()=>'00:00:00'],user:['USER',8,0,p=>p.user],uid:['UID',8,0,p=>p.user],c:['C',1,1,()=>'0'],stime:['STIME',5,0,()=>'09:12']};
    if(!cols)cols=full?['uid','pid','ppid','c','stime','tty','time','cmd']:['pid','tty','time','comm'];
    if(!full&&!args.includes('-o')&&cols[3]==='comm')C.comm[0]='CMD';
    for(const c of cols)if(!C[c])return{err:'error: unknown user-defined format specifier "'+c+'"'};
    const rows=this.ptable().filter(p=>all||p.tty==='pts/0');
    const fmt=v=>cols.map((c,i)=>{const[,w,r]=C[c];const x=String(v(c));return i===cols.length-1?x:pad(x,w,r)}).join(' ');
    return{out:[fmt(c=>C[c][0])].concat(rows.map(p=>fmt(c=>C[c][3](p)))).join('\n')};
  }
  c_pstree(args){
    const p=args.includes('-p'), T=this.ptable().filter(x=>x.pid!==2&&x.stat!=='Z'||x.stat==='Z');
    const kids=id=>T.filter(x=>x.ppid===id&&x.pid!==id);
    const name=x=>x.comm+(p?'('+x.pid+')':'');
    const out=[];
    const rec=(x,pre,last,top)=>{out.push(top?name(x):pre+(last?'└─':'├─')+name(x));const k=kids(x.pid);k.forEach((c,i)=>rec(c,top?'':pre+(last?'  ':'│ '),i===k.length-1,false))};
    rec(T[0],'',true,true);
    return{out:out.join('\n')};
  }
  c_lsof(args){
    const i=args.indexOf('-p'); if(i<0||!args[i+1])return{note:'iso-demo: this demo knows lsof -p PID'};
    const pid=parseInt(args[i+1],10), P=this.ptable().find(x=>x.pid===pid);
    if(!P)return{code:1};
    const fd=pid===this.self.pid?this.self.fdList():[0,1,2].map(f=>({fd:f,to:P.tty==='pts/0'?'/dev/pts/0':'/dev/null'}));
    const rows=[['COMMAND','PID','USER','FD','TYPE','NAME']].concat([[P.comm,pid,P.user,'cwd','DIR',pid===this.pid||pid===this.self.pid?pstr(this.cwd):'/']],fd.map(f=>[P.comm,pid,P.user,f.fd+(f.fd===0?'u':f.fd<3?'u':'r'),f.to.startsWith('/dev/')?'CHR':f.to==='pipe'?'FIFO':'REG',f.to]));
    const w=rows[0].map((_,c)=>Math.max(...rows.map(r=>String(r[c]).length)));
    return{out:rows.map(r=>r.map((x,c)=>c===r.length-1?String(x):pad(x,w[c],c===1)).join(' ')).join('\n')};
  }
  /* the /proc file system, built again for every command */
  makeProc(){
    const self=this.self, sh=this;
    const fdTo=t=>t.k==='tty'?'/dev/pts/0':t.k==='pipe'?'pipe:[4242]':t.name;
    self.fdList=()=>[0,1,2].map(f=>({fd:f,to:fdTo(self.fds[f])})).concat(self.opened.map((n,i)=>({fd:3+i,to:n})));
    // the files this command will open (its FILE arguments), at 3, 4, ...
    const opens=['cat','sort','wc','head','tail','grep','uniq','xxd','ls'].includes(self.comm)?self.args.slice(1).filter(a=>!a.startsWith('-')&&!/^\d+$/.test(a)):[];
    if(self.comm==='ls'&&!opens.length)opens.push('.');
    const pre=opens.map(a=>{const x=lookup(this.root,split(this.cwd,a));return x.node?pstr(x.real):null}).filter(Boolean);
    const names={R:'R (running)',S:'S (sleeping)',Z:'Z (zombie)'};
    const proc=D({},clock);
    for(const P of this.ptable()){
      const me=P.pid===self.pid;
      const fds=D({});
      const list=me?[0,1,2].map(f=>fdTo(self.fds[f])).concat(pre):P.tty==='pts/0'?['/dev/pts/0','/dev/pts/0','/dev/pts/0']:['/dev/null','/dev/null','/dev/null'];
      list.forEach((t,i)=>fds.c[String(i)]=L(t));
      proc.c[String(P.pid)]=D({
        cmdline:F(P.cmd.replace(/ /g,'\0')+'\0',0), comm:F(P.comm+'\n',0),
        cwd:L(me||P.pid===this.pid?pstr(this.cwd):'/'), exe:L(P.comm==='bash'?'/usr/bin/bash':'/usr/bin/'+P.comm),
        environ:F('HOME=/home/'+USER+'\0USER='+USER+'\0',0), fd:fds, maps:F('55d0c0000000-55d0c0004000 r--p /usr/bin/'+P.comm+'\n',0),
        status:F('Name:\t'+P.comm+'\nUmask:\t0022\nState:\t'+(names[P.stat[0]]||P.stat)+'\nPid:\t'+P.pid+'\nPPid:\t'+P.ppid+'\nThreads:\t'+(P.stat.includes('l')?4:1)+'\n',0),
      });
    }
    proc.c.self=L(String(self.pid));
    const up=244699.78+(clock-Date.UTC(2026,8,30,14,20))/1000;
    Object.assign(proc.c,{cpuinfo:F('processor\t: 0\nmodel name\t: Virtual CPU\ncpu MHz\t\t: 2400.000\nprocessor\t: 1\nmodel name\t: Virtual CPU\n',0),
      meminfo:F('MemTotal:        4028144 kB\nMemFree:         1651832 kB\nMemAvailable:    3164732 kB\n',0),
      uptime:F(up.toFixed(2)+' '+(up*1.5).toFixed(2)+'\n',0), loadavg:F('0.42 0.37 0.31 2/312 '+self.pid+'\n',0),
      mounts:F('/dev/sda1 / ext4 rw 0 0\nproc /proc proc rw 0 0\ntmpfs /tmp tmpfs rw 0 0\n',0)});
    return proc;
  }
  c_file(args){
    const r=this.opts(args,'bL','file'); if(r.err)return{err:r.err};
    if(!r.ops.length)return{err:'Usage: file [-bL] FILE...',code:1};
    const kind=(parts,n)=>{
      if(n.t==='d')return'directory';
      if(n.t==='l')return'symbolic link to '+n.target;
      if(n.t==='c')return'character special ('+n.maj+'/'+n.min+')';
      const name=parts[parts.length-1]||'';
      if(n.meta&&n.meta.kind==='exe')return n.meta.stat?'ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked'+(n.meta.debug?', with debug_info':'')+', not stripped':'ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2'+(n.meta.debug?', with debug_info':'')+', not stripped';
      if(n.meta&&n.meta.kind==='a')return'current ar archive';
      if(n.meta&&n.meta.kind==='so')return'ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, not stripped';
      if(n.meta&&n.meta.kind==='o')return'ELF 64-bit LSB relocatable, x86-64, version 1 (SYSV)'+(n.meta.debug?', with debug_info':'')+', not stripped';
      if(/\.so(\.\d+)*$/.test(name))return'ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, stripped';
      if(['bin','sbin'].includes(parts[0])||parts[0]==='usr'&&parts[1]==='bin')return n.s?'ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, stripped':'empty';
      if(/\.mp4$/.test(name)&&!n.data)return'ISO Media, MP4 v2 [ISO 14496-14]';
      if(/\.mkv$/.test(name)&&!n.data)return'Matroska data';
      if(/^vmlinuz/.test(name))return'Linux kernel x86 boot executable bzImage';
      if(!n.data||parts[0]==='proc')return'empty';
      const txt=/[^\x00-\x7f]/.test(n.data)?'Unicode text, UTF-8 text':'ASCII text';
      if(/^#!.*\b(ba)?sh\b/.test(n.data))return'Bourne-Again shell script, '+txt+' executable';
      if(/^(GNU)?[Mm]akefile$/.test(name))return'makefile script, '+txt;
      if(/\.[chi]$/.test(name))return'C source, '+txt;
      if(/\.s$/.test(name))return'assembler source, '+txt;
      if(/\.json$/.test(name))return'JSON text data';
      if(/\.py$/.test(name))return'Python script, '+txt+' executable';
      return txt;
    };
    const out=[];
    for(const p of r.ops){
      const parts=split(this.cwd,p), x=lookup(this.root,parts,!r.o.L);
      out.push((r.o.b?'':p+': ')+(x.err?"cannot open `"+p+"' ("+x.err+")":kind(x.real||parts,x.node)));
    }
    return{out:out.join('\n')};
  }
  c_true(){return{}}
  c_false(){return{code:1}}

  c_mkdir(args){
    const r=this.opts(args,'p','mkdir'); if(r.err)return{err:r.err};
    if(!r.ops.length)return{err:"mkdir: missing operand\nTry 'mkdir --help' for more information."};
    const err=[];
    for(const p of r.ops){
      const parts=split(this.cwd,p);
      if(r.o.p){let n=this.root,bad=null;
        for(let i=0;i<parts.length;i++){const c=n.c[parts[i]];
          if(c){if(c.t!=='d'){bad='File exists';break}n=c;continue}
          if(!writable(parts.slice(0,i+1))){bad='Permission denied';break}
          n=n.c[parts[i]]=D({},now());}
        if(bad)err.push("mkdir: cannot create directory '"+p+"': "+bad);
        continue}
      const par=lookup(this.root,parts.slice(0,-1)), name=parts[parts.length-1];
      if(!parts.length||par.node&&par.node.t==='d'&&par.node.c[name])err.push("mkdir: cannot create directory '"+p+"': File exists");
      else if(!par.node||par.node.t!=='d')err.push("mkdir: cannot create directory '"+p+"': "+(par.err||'Not a directory'));
      else if(!writable(parts))err.push("mkdir: cannot create directory '"+p+"': Permission denied");
      else{par.node.c[name]=D({},now());par.node.m=now()}
    }
    return{err:err.join('\n')||undefined};
  }
  c_touch(args){
    if(!args.length)return{err:"touch: missing file operand\nTry 'touch --help' for more information."};
    const err=[];
    for(const p of args){
      const parts=split(this.cwd,p), x=lookup(this.root,parts);
      if(x.node){if(writable(parts))x.node.m=now();else err.push("touch: cannot touch '"+p+"': Permission denied");continue}
      const par=lookup(this.root,parts.slice(0,-1));
      if(!par.node||par.node.t!=='d')err.push("touch: cannot touch '"+p+"': "+(par.err||'Not a directory'));
      else if(!writable(parts))err.push("touch: cannot touch '"+p+"': Permission denied");
      else{par.node.c[parts[parts.length-1]]=F('',null,now());par.node.m=now()}
    }
    return{err:err.join('\n')||undefined};
  }
  c_nano(args){
    if(!args.length)return{err:'iso-sandbox: give nano a file name, e.g. nano todo.txt'};
    const parts=split(this.cwd,args[0]), x=lookup(this.root,parts);
    if(x.node&&x.node.t==='d')return{err:'nano: '+args[0]+' is a directory'};
    const par=lookup(this.root,parts.slice(0,-1));
    if(!par.node||par.node.t!=='d')return{err:'nano: '+args[0]+': No such file or directory'};
    return{edit:{name:args[0],parts,text:x.node?x.node.data:'',ro:!writable(parts)}};
  }
  save(parts,text){const par=lookup(this.root,parts.slice(0,-1)).node;if(!par||!writable(parts))return false;par.c[parts[parts.length-1]]=F(text,null,now());par.m=now();return true}
  c_rmdir(args){
    if(!args.length)return{err:"rmdir: missing operand\nTry 'rmdir --help' for more information."};
    const err=[];
    for(const p of args){
      const parts=split(this.cwd,p), x=lookup(this.root,parts), e=m=>err.push("rmdir: failed to remove '"+p+"': "+m);
      if(x.err)e(x.err);else if(x.node.t!=='d')e('Not a directory');
      else if(Object.keys(x.node.c).length)e('Directory not empty');
      else if(/(^|\/)\.\.?\/?$/.test(p))e('Invalid argument');
      else if(!writable(parts))e('Permission denied');
      else{delete lookup(this.root,parts.slice(0,-1)).node.c[parts[parts.length-1]]}
    }
    this.fix();
    return{err:err.join('\n')||undefined};
  }
  c_rm(args){
    const r=this.opts(args,'rRfidv','rm'); if(r.err)return{err:r.err};
    if(!r.ops.length)return r.o.f?{}:{err:"rm: missing operand\nTry 'rm --help' for more information."};
    const err=[];
    for(const p of r.ops){
      if(/(^|\/)\.\.?\/?$/.test(p)){err.push("rm: refusing to remove '.' or '..' directory: skipping '"+p+"'");continue}
      const parts=split(this.cwd,p);
      if(!parts.length){err.push(r.o.r?"rm: it is dangerous to operate recursively on '/'\nrm: use --no-preserve-root to override this failsafe":"rm: cannot remove '/': Is a directory");continue}
      const x=lookup(this.root,parts,true);
      if(x.err){if(!r.o.f)err.push("rm: cannot remove '"+p+"': "+x.err);continue}
      if(x.node.t==='d'&&!r.o.r&&!(r.o.d&&!Object.keys(x.node.c).length)){err.push("rm: cannot remove '"+p+"': Is a directory");continue}
      if(!writable(parts)){err.push("rm: cannot remove '"+p+"': Permission denied");continue}
      delete lookup(this.root,parts.slice(0,-1)).node.c[parts[parts.length-1]];
    }
    const before=pstr(this.cwd); this.fix();
    if(pstr(this.cwd)!==before)err.push('iso-sandbox: your current directory was removed, the shell moved to '+pstr(this.cwd));
    return{err:err.join('\n')||undefined};
  }
  transfer(args,move){
    const cmd=move?'mv':'cp';
    const r=this.opts(args,move?'fiv':'rRfiv',cmd); if(r.err)return{err:r.err};
    const ops=r.ops;
    if(!ops.length)return{err:cmd+": missing file operand\nTry '"+cmd+" --help' for more information."};
    if(ops.length===1)return{err:cmd+": missing destination file operand after '"+ops[0]+"'\nTry '"+cmd+" --help' for more information."};
    const dst=ops[ops.length-1], srcs=ops.slice(0,-1);
    const dparts=split(this.cwd,dst), dx=lookup(this.root,dparts);
    const dIsDir=dx.node&&dx.node.t==='d';
    if(dst.endsWith('/')&&!dIsDir)return{err:cmd+": cannot "+(move?"move '"+srcs[0]+"' to":"create regular file")+" '"+dst+"': "+(dx.node?'Not a directory':'Not a directory')};
    if(srcs.length>1&&!dIsDir)return{err:cmd+": target '"+dst+"'"+(dx.node?' is not a directory':': No such file or directory')};
    const err=[];
    for(const s of srcs){
      const sparts=split(this.cwd,s), sx=lookup(this.root,sparts,move);
      if(sx.err){err.push(cmd+": cannot stat '"+s+"': "+sx.err);continue}
      if(!move&&sx.node.t==='d'&&!r.o.r){err.push("cp: -r not specified; omitting directory '"+s+"'");continue}
      const tparts=dIsDir?dparts.concat(sparts[sparts.length-1]):dparts;
      const tshow=dIsDir?(dst.endsWith('/')?dst:dst+'/')+sparts[sparts.length-1]:dst;
      if(!sparts.length){err.push(cmd+": cannot "+(move?'move':'copy')+" '/'");continue}
      if(pstr(sparts)===pstr(tparts)){err.push(move?"mv: '"+s+"' and '"+tshow+"' are the same file":"cp: '"+s+"' and '"+tshow+"' are the same file");continue}
      if(sx.node.t==='d'&&isPre(sparts,tparts)){err.push(move?"mv: cannot move '"+s+"' to a subdirectory of itself, '"+tshow+"'":"cp: cannot copy a directory, '"+s+"', into itself, '"+tshow+"'");continue}
      const tpar=lookup(this.root,tparts.slice(0,-1));
      if(!tpar.node||tpar.node.t!=='d'){err.push(cmd+": cannot "+(move?"move '"+s+"' to":"create regular file")+" '"+tshow+"': "+(tpar.err||'Not a directory'));continue}
      if(!writable(tparts)||(move&&!writable(sparts))){err.push(cmd+": cannot "+(move?"move '"+s+"' to '"+tshow+"'":"create regular file '"+tshow+"'")+': Permission denied');continue}
      const name=tparts[tparts.length-1], ex=tpar.node.c[name];
      if(ex){
        if(ex.t==='d'&&sx.node.t!=='d'){err.push(cmd+": cannot overwrite directory '"+tshow+"' with non-directory");continue}
        if(ex.t!=='d'&&sx.node.t==='d'){err.push(cmd+": cannot overwrite non-directory '"+tshow+"' with directory '"+s+"'");continue}
        if(ex.t==='d'&&move&&Object.keys(ex.c).length){err.push("mv: cannot move '"+s+"' to '"+tshow+"': Directory not empty");continue}
      }
      if(move){delete lookup(this.root,sparts.slice(0,-1)).node.c[sparts[sparts.length-1]];tpar.node.c[name]=sx.node}
      else if(ex&&ex.t==='d'){                         // cp -r into an existing directory: merge
        const merge=(a,b)=>{for(const[k,v]of Object.entries(a.c)){if(v.t==='d'&&b.c[k]&&b.c[k].t==='d')merge(v,b.c[k]);else{const c=clone(v);stamp(c);b.c[k]=c}}};
        merge(sx.node,ex);
      }
      else{const c=clone(sx.node);stamp(c);tpar.node.c[name]=c}
      tpar.node.m=now();
    }
    if(move)this.fix();
    return{err:err.join('\n')||undefined};
  }
  c_cp(a){return this.transfer(a,false)}
  c_mv(a){return this.transfer(a,true)}
  /* the names a word could be completed to */
  complete(word){
    const i=word.lastIndexOf('/'), dir=word.slice(0,i+1), part=word.slice(i+1);
    const x=this.get(dir||'.'); if(!x.node||x.node.t!=='d')return[];
    return sortNames(Object.keys(x.node.c).filter(k=>k.startsWith(part)&&(part.startsWith('.')||!k.startsWith('.')))).map(k=>{const n=x.node.c[k];const d=n.t==='d'||n.t==='l'&&(lookup(this.root,split(this.cwd,dir+k)).node||{}).t==='d';return dir+k+(d?'/':'')});
  }
}
function stamp(n){n.m=now();if(n.t==='d')Object.values(n.c).forEach(stamp)}

/* every path in the tree, for the before / after comparison */
function paths(root){const out=new Map();const rec=(n,p)=>{if(p==='/proc')return;out.set(p,n.m+(n.t==='f'?':'+n.s:n.t==='l'?'>'+n.target:''));if(n.t==='d')for(const k in n.c)rec(n.c[k],p+'/'+k)};rec(root,'');return out}

return{Shell,makeFS,split,lookup,pstr,paths,clone,HOME,sortNames,PROFILES,words,writable,F,D,MAN,now:()=>now()};
})();
if(typeof module!=='undefined')module.exports=ISOSH;
