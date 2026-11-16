/* ISO lecture 08 (Shell Scripting): a small bash interpreter, pure logic, no DOM.
   It runs a script the way bash does (words, quotes, IFS, $(...), $((...)), if, while, until, for, case,
   functions, local, read, test and [, [[ ]], (( )), pipes, redirects) on a few files kept in memory, and records
   a step for every command it runs, the way the debugger of the slides shows it: the line, the part of the line
   that runs, the command line after the expansions, its exit code, the variables that changed and the output.
   Used by the script lab and the small simulators of widgets08.js, and by the node tests. */
const ISOBASH=(()=>{'use strict';
const HOMEP='/home/student', DEFIFS=' \t\n';
class BErr extends Error{constructor(m,status,kind){super(m);this.status=status==null?1:status;this.kind=kind}}
class Flow{constructor(kind,n,status){this.kind=kind;this.n=n||1;this.status=status||0}}

/* ================================================================ the files */
const POOL={
  'fruits.txt':'banana\napple\ncherry\napple\nkiwi\nbanana\napple\n',
  'notes.txt':'buy milk\ncall mom\n',
  'words.txt':'hello\nworld\n',
  'shopping.txt':'apple\nkiwi\n',
  'people.csv':'alice,Alice Smith\nbob,Bob Jones\n',
  'people.txt':'Alice Smith\nBob Jones\n',
  'path.txt':'C:\\new\\temp\n',
  'spaces.txt':'   two  spaces  \n',
  'scores.txt':'alice 7\nbob 9\ncarol 4\n',
  '/etc/passwd':'root:x:0:0:root:/root:/bin/bash\nstudent:x:1000:1000:Student:/home/student:/bin/bash\n',
};
class FS{
  constructor(files){this.f=new Map();this.d=new Set();this.x=new Set();this.cwd='';
    for(const[k,v]of Object.entries(files||{}))if(v===null)this.d.add(k);else this.f.set(k,v)}
  rel(p){
    if(p==='~'||p===HOMEP)return '';
    if(p.startsWith('~/'))p=HOMEP+p.slice(1);
    let parts;
    if(p.startsWith(HOMEP+'/'))parts=p.slice(HOMEP.length+1).split('/');
    else if(p.startsWith('/'))return p.replace(/\/+$/,'')||'/';
    else parts=(this.cwd?this.cwd.split('/'):[]).concat(p.split('/'));
    const out=[];for(const x of parts){if(!x||x==='.')continue;if(x==='..')out.pop();else out.push(x)}
    return out.join('/');
  }
  isDir(p){const r=this.rel(p);if(r===''||r==='/'||r==='/etc'||r==='/tmp'||r==='/home')return true;if(this.d.has(r))return true;for(const k of this.f.keys())if(k.startsWith(r+'/'))return true;for(const k of this.d)if(k.startsWith(r+'/'))return true;return false}
  isFile(p){return p==='/dev/null'||this.f.has(this.rel(p))}
  read(p){if(p==='/dev/null')return '';const r=this.rel(p);return this.f.has(r)?this.f.get(r):null}
  write(p,s,app){if(p==='/dev/null')return;const r=this.rel(p);if(this.isDir(p))throw new BErr(p+': Is a directory');
    const dir=r.includes('/')?r.slice(0,r.lastIndexOf('/')):'';if(dir&&!r.startsWith('/')&&!this.isDir(dir))throw new BErr(p+': No such file or directory');
    this.f.set(r,(app&&this.f.has(r)?this.f.get(r):'')+s)}
  list(dir){const r=dir==null?this.cwd:this.rel(dir), pre=r?r+'/':'', set=new Set();
    for(const k of [...this.f.keys(),...this.d])if(!k.startsWith('/')&&k.startsWith(pre)&&k.length>pre.length)set.add(k.slice(pre.length).split('/')[0]);
    return [...set].sort(cmpName)}
  dump(){const o={};for(const k of[...this.f.keys()].sort())o[k]=this.f.get(k);for(const k of this.d)o[k]=null;return o}
}
const cmpName=(a,b)=>{const x=a.replace(/^\./,'').toLowerCase(),y=b.replace(/^\./,'').toLowerCase();return x<y?-1:x>y?1:a<b?-1:a>b?1:0};

/* ================================================================ the lexer
   a word: {t:'w', raw, plain (no quotes, no $), segs:[{k:'l', s, q} text | {k:'v', name, op, arg, q} $NAME |
   {k:'c', src, q} $(...) | {k:'a', src, q} $((...)) | {k:'t'} ~]}, an operator: {t:'op', v}, (( )): {t:'ar', src} */
function lex(src,line0){
  const toks=[];let i=0,line=line0||1,dbl=false;const n=src.length;
  const SYN=m=>{throw Object.assign(new BErr(m,2,'syntax'),{line})};
  const newl=(a,b)=>{for(let k=a;k<b;k++)if(src[k]==='\n')line++};
  function matchParen(j){let d=1;
    while(j<n){const c=src[j];
      if(c==='\\'){j+=2;continue}
      if(c==="'"){const k=src.indexOf("'",j+1);j=k<0?n:k+1;continue}
      if(c==='"'){j++;while(j<n&&src[j]!=='"'){if(src[j]==='\\')j++;j++}j++;continue}
      if(c==='(')d++;else if(c===')'){d--;if(!d)return j}
      j++}
    SYN("unexpected EOF while looking for matching `)'")}
  function matchArith(j){let d=0;
    while(j<n){const c=src[j];if(c==='(')d++;else if(c===')'){if(d===0&&src[j+1]===')')return j;d--}j++}
    SYN("unexpected EOF while looking for matching `))'")}
  function dollar(j,q){
    const c=src[j+1];
    if(c==='('&&src[j+2]==='('){const e=matchArith(j+3);return[{k:'a',src:src.slice(j+3,e),q},e+2]}
    if(c==='('){const e=matchParen(j+2);return[{k:'c',src:src.slice(j+2,e),q},e+1]}
    if(c==='{'){const e=src.indexOf('}',j+2);if(e<0)SYN("unexpected EOF while looking for matching `}'");
      const b=src.slice(j+2,e);let m;
      if((m=/^#([A-Za-z_]\w*|[0-9@#*])$/.exec(b)))return[{k:'v',name:m[1],op:'#',q},e+1];
      if((m=/^([A-Za-z_]\w*|[0-9]+|[@#*?$])(?:(:?[-=+?])([\s\S]*))?$/.exec(b)))return[{k:'v',name:m[1],op:m[2],arg:m[3],q},e+1];
      return[{k:'v',name:'',bad:'${'+b+'}',q},e+1]}
    const m=/^[A-Za-z_]\w*/.exec(src.slice(j+1,j+80));
    if(m)return[{k:'v',name:m[0],q},j+1+m[0].length];
    if(c&&/[0-9#?@*$!-]/.test(c))return[{k:'v',name:c,q},j+2];
    if(c==="'"&&!q){let k=j+2,s='';
      while(k<n&&src[k]!=="'"){if(src[k]==='\\'&&k+1<n){const d=src[k+1];s+=({n:'\n',t:'\t',r:'\r',a:'\x07',e:'\x1b','\\':'\\',"'":"'",'"':'"'})[d]??('\\'+d);k+=2}else s+=src[k++]}
      if(k>=n)SYN("unexpected EOF while looking for matching `''");
      return[{k:'l',s,q:true},k+1]}
    return null}
  function word(){
    const s=i,segs=[];let plain=true;
    const lit=(t,q)=>{const l=segs[segs.length-1];if(l&&l.k==='l'&&l.q===q)l.s+=t;else segs.push({k:'l',s:t,q})};
    while(i<n){
      const c=src[i];
      if(c===' '||c==='\t'||c==='\n'||c==='\r')break;
      if(!dbl&&';&|()<>'.includes(c))break;
      if(dbl&&c===';')break;
      if(c==="'"){plain=false;const e=src.indexOf("'",i+1);if(e<0)SYN("unexpected EOF while looking for matching `''");
        segs.push({k:'l',s:src.slice(i+1,e),q:true});newl(i,e);i=e+1;continue}
      if(c==='"'){plain=false;i++;segs.push({k:'l',s:'',q:true});
        while(i<n&&src[i]!=='"'){const d=src[i];
          if(d==='\\'&&'$`"\\\n'.includes(src[i+1])){if(src[i+1]==='\n')line++;else lit(src[i+1],true);i+=2;continue}
          if(d==='$'){const r=dollar(i,true);if(r){segs.push(r[0]);newl(i,r[1]);i=r[1];continue}}
          if(d==='`'){const e=src.indexOf('`',i+1);if(e<0)SYN("unexpected EOF while looking for matching ``'");segs.push({k:'c',src:src.slice(i+1,e),q:true});i=e+1;continue}
          if(d==='\n')line++;
          lit(d,true);i++}
        if(i>=n)SYN('unexpected EOF while looking for matching `"\'');
        i++;continue}
      if(c==='\\'){if(src[i+1]==='\n'){i+=2;line++;continue}plain=false;lit(src[i+1]||'',true);i+=2;continue}
      if(c==='$'){const r=dollar(i,false);if(r){plain=false;segs.push(r[0]);newl(i,r[1]);i=r[1];continue}}
      if(c==='`'){plain=false;const e=src.indexOf('`',i+1);if(e<0)SYN("unexpected EOF while looking for matching ``'");segs.push({k:'c',src:src.slice(i+1,e),q:false});i=e+1;continue}
      if(c==='~'&&i===s&&(i+1>=n||/[\s/;|&)]/.test(src[i+1]))){plain=false;segs.push({k:'t'});i++;continue}
      lit(c,false);i++}
    return{t:'w',segs,raw:src.slice(s,i),plain,s,e:i};
  }
  while(i<n){
    const c=src[i];
    if(c==='\\'&&src[i+1]==='\n'){i+=2;line++;continue}
    if(c===' '||c==='\t'||c==='\r'){i++;continue}
    if(c==='\n'){toks.push({t:'nl',line,s:i,e:i+1});line++;i++;continue}
    if(c==='#'){while(i<n&&src[i]!=='\n')i++;continue}
    if(!dbl&&c==='('&&src[i+1]==='('){const l0=line,e=matchArith(i+2);toks.push({t:'ar',src:src.slice(i+2,e),line:l0,s:i,e:e+2});newl(i,e);i=e+2;continue}
    if(!dbl){const m=/^(?:;;|&&|\|\||&>>|&>|<<<|[0-9]?>>|[0-9]?>&[0-9-]|[0-9]?>|[0-9]?<|;|&|\||\(|\))/.exec(src.slice(i,i+4));
      if(m){toks.push({t:'op',v:m[0],line,s:i,e:i+m[0].length});i+=m[0].length;continue}}
    const l0=line,w=word();w.line=l0;
    if(w.plain&&w.raw==='[[')dbl=true;else if(dbl&&w.plain&&w.raw===']]')dbl=false;
    toks.push(w);
  }
  return toks;
}

/* ================================================================ the parser */
const REDIR=/^(?:[0-9]?>>|[0-9]?>&[0-9-]|[0-9]?>|[0-9]?<|&>>|&>|<<<)$/;
const STOPK=['then','elif','else','fi','do','done','esac','}','in'];
function parse(src,line0){
  let toks;
  try{toks=lex(src,line0)}catch(e){if(e.kind==='syntax')return{T:'list',items:[],error:e};throw e}
  let p=0;
  const lastLine=toks.length?toks[toks.length-1].line:(line0||1);
  const pk=(k=0)=>toks[p+k]||{t:'eof',line:lastLine,s:src.length,e:src.length};
  const isK=(t,v)=>t.t==='w'&&t.plain&&t.raw===v;
  const isOp=(t,v)=>t.t==='op'&&t.v===v;
  const err=t=>{const v=t.t==='eof'?null:t.t==='nl'?'newline':t.t==='op'?t.v:t.t==='ar'?'((':t.raw;
    throw Object.assign(new BErr(v==null?'syntax error: unexpected end of file':"syntax error near unexpected token `"+v+"'",2,'syntax'),{line:t.line})};
  const nl=()=>{while(pk().t==='nl')p++};
  const expect=v=>{const t=pk();if(isK(t,v)){p++;return t}err(t)};
  const need=l=>{if(!l.items.length)err(pk());return l};
  function clist(stops){
    const items=[];nl();
    for(;;){const t=pk();
      if(t.t==='eof')break;
      if(t.t==='w'&&t.plain&&stops.includes(t.raw))break;
      if(t.t==='op'&&stops.includes(t.v))break;
      items.push(andor());
      const s=pk();
      if(isOp(s,';')||isOp(s,'&')){p++;nl();continue}
      if(s.t==='nl'){nl();continue}
      break}
    return{T:'list',items}}
  function andor(){const first=pipeline(),rest=[];
    while(isOp(pk(),'&&')||isOp(pk(),'||')){const op=pk().v;p++;nl();rest.push({op,node:pipeline()})}
    return rest.length?{T:'andor',first,rest,line:first.line,s:first.s,e:rest[rest.length-1].node.e}:first}
  function pipeline(){let bang=null;if(isK(pk(),'!')){bang=pk();p++}
    const cmds=[command()];
    while(isOp(pk(),'|')){p++;nl();cmds.push(command())}
    let node=cmds.length>1?{T:'pipe',cmds,line:cmds[0].line,s:cmds[0].s,e:cmds[cmds.length-1].e}:cmds[0];
    if(node.T==='pipe')node.src=src.slice(node.s,node.e);
    if(bang)node={T:'not',node,line:bang.line,s:bang.s,e:node.e};
    return node}
  function command(){
    const t=pk();
    if(t.t==='ar'){p++;return redirs({T:'arith',src:t.src,line:t.line,s:t.s,e:t.e})}
    if(t.t==='w'&&t.plain){
      switch(t.raw){
        case 'if':return redirs(ifc());
        case 'while':case 'until':return redirs(whilec());
        case 'for':return redirs(forc());
        case 'case':return redirs(casec());
        case '{':{p++;const body=need(clist(['}']));const e=expect('}');return redirs({T:'group',body,line:t.line,s:t.s,e:e.e,eLine:e.line})}
        case 'function':{p++;const nm=pk();if(nm.t!=='w')err(nm);p++;if(isOp(pk(),'(')){p++;if(!isOp(pk(),')'))err(pk());p++}nl();return funcdef(nm,t)}
      }
      if(STOPK.includes(t.raw))err(t);
      if(isOp(pk(1),'(')&&/^[A-Za-z_][\w-]*$/.test(t.raw)){p+=2;if(!isOp(pk(),')'))err(pk());p++;nl();return funcdef(t,t)}
    }
    if(isOp(t,'(')){p++;const body=need(clist([')']));const e=pk();if(!isOp(e,')'))err(e);p++;return redirs({T:'sub',body,line:t.line,s:t.s,e:e.e})}
    return simple()}
  function funcdef(nm,t0){const b=pk();if(!isK(b,'{')&&!isOp(b,'('))err(b);const body=command();return{T:'func',name:nm.raw,body,line:t0.line,s:t0.s,e:body.e,eLine:body.eLine,redirs:[]}}
  function redirOne(node){const t=pk();if(t.t==='op'&&REDIR.test(t.v)){p++;let w=null;if(!/&[0-9-]$/.test(t.v)){w=pk();if(w.t!=='w')err(w);p++;node.e=w.e}else node.e=t.e;node.redirs.push({op:t.v,w});return true}return false}
  function redirs(node){node.redirs=node.redirs||[];while(redirOne(node));node.src=src.slice(node.s,node.e);return node}
  function simple(){
    const t0=pk();const n={T:'simple',asg:[],words:[],redirs:[],line:t0.line,s:t0.s,e:t0.s};
    for(;;){if(redirOne(n))continue;
      const t=pk();if(t.t!=='w')break;
      if(!n.words.length&&/^[A-Za-z_]\w*\+?=/.test(t.raw)&&t.segs[0].k==='l'&&!t.segs[0].q){n.asg.push(t);p++;n.e=t.e;continue}
      n.words.push(t);p++;n.e=t.e}
    if(!n.asg.length&&!n.words.length&&!n.redirs.length)err(pk());
    n.src=src.slice(n.s,n.e);return n}
  function ifc(){const t0=pk();p++;const clauses=[];
    const c=need(clist(['then']));expect('then');const b=need(clist(['elif','else','fi']));clauses.push({cond:c,body:b,line:t0.line});
    let els=null;
    for(;;){const t=pk();
      if(isK(t,'elif')){p++;const c2=need(clist(['then']));expect('then');const b2=need(clist(['elif','else','fi']));clauses.push({cond:c2,body:b2,line:t.line});continue}
      if(isK(t,'else')&&!els){p++;els=need(clist(['fi']));els.line=t.line;continue}
      const f=expect('fi');return{T:'if',clauses,els,line:t0.line,s:t0.s,e:f.e,eLine:f.line}}}
  function whilec(){const t0=pk();p++;const cond=need(clist(['do']));expect('do');const body=need(clist(['done']));const d=expect('done');
    return{T:'while',until:t0.raw==='until',cond,body,line:t0.line,s:t0.s,e:d.e,eLine:d.line}}
  function forc(){const t0=pk();p++;
    if(pk().t==='ar'){const a=pk();p++;if(isOp(pk(),';'))p++;nl();expect('do');const body=need(clist(['done']));const d=expect('done');
      const parts=a.src.split(';');return{T:'cfor',init:parts[0]||'',cond:parts[1]||'',step:parts[2]||'',src:a.src,body,line:t0.line,s:t0.s,e:d.e,eLine:d.line}}
    const nm=pk();if(nm.t!=='w'||!/^[A-Za-z_]\w*$/.test(nm.raw))err(nm);p++;
    let words=null;const save=p;nl();
    if(isK(pk(),'in')){p++;words=[];while(pk().t==='w'){words.push(pk());p++}if(isOp(pk(),';')||pk().t==='nl')p++;else err(pk())}
    else{p=save;if(isOp(pk(),';'))p++}
    nl();expect('do');const body=need(clist(['done']));const d=expect('done');
    return{T:'for',name:nm.raw,words,body,line:t0.line,s:t0.s,e:d.e,eLine:d.line}}
  function casec(){const t0=pk();p++;const w=pk();if(w.t!=='w')err(w);p++;nl();expect('in');nl();const items=[];
    for(;;){const t=pk();
      if(isK(t,'esac')){p++;return{T:'case',word:w,items,line:t0.line,s:t0.s,e:t.e,eLine:t.line}}
      if(t.t==='eof')err(t);
      if(isOp(t,'('))p++;
      const pats=[],pl=pk().line;
      for(;;){const pw=pk();if(pw.t!=='w')err(pw);p++;pats.push(pw);if(isOp(pk(),'|')){p++;continue}break}
      if(!isOp(pk(),')'))err(pk());p++;
      const body=clist(['esac',';;']);
      const endLine=pk().line;
      if(isOp(pk(),';;'))p++;
      nl();items.push({pats,body,line:pl,endLine})}}
  const items=[];let error=null;nl();
  while(pk().t!=='eof'){
    try{const it=andor();it.endLine=toks[p-1].line;items.push(it);
      const s=pk();
      if(isOp(s,';')||isOp(s,'&')){p++;nl();continue}
      if(s.t==='nl'){nl();continue}
      if(s.t==='eof')break;
      err(s)}
    catch(e){if(e.kind==='syntax'){error=e;break}throw e}}
  return{T:'list',items:error?items.filter(it=>it.endLine<error.line):items,error};
}
const PCACHE=new Map();
const parseC=(src,line)=>{const k=line+'\u0000'+src;if(!PCACHE.has(k)){if(PCACHE.size>400)PCACHE.clear();PCACHE.set(k,parse(src,line))}return PCACHE.get(k)};

/* ================================================================ small helpers */
const isWS=c=>c===' '||c==='\t'||c==='\n';
const isInt=s=>/^\s*[-+]?\d+\s*$/.test(s);
function shq(s){                                         // printf %q
  if(s==='')return "''";
  if(/^[A-Za-z0-9_./,:=+@%^-]+$/.test(s))return s;
  if(/[\x00-\x1f\x7f]/.test(s))return "$'"+s.replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/\n/g,'\\n').replace(/\t/g,'\\t').replace(/\r/g,'\\r').replace(/\x1b/g,'\\E')+"'";
  return s.replace(/[^A-Za-z0-9_./,:=+@%^-]/g,'\\$&');
}
function qv(v){return v===''?'""':/[\s'"\\$`|&;<>()*?[\]#~]/.test(v)?'"'+v.replace(/(["\\$`])/g,'\\$1')+'"':v}
function ifsDesc(v){if(v==='')return '';const nm={' ':'space','\t':'tab','\n':'newline'};return [...v].map(c=>nm[c]||c).join(nm[v[0]]?' ':'')}
function globRx(chars){                                  // [{c, g: special}] -> regex source
  let r='';
  for(let i=0;i<chars.length;i++){const{c,g}=chars[i];
    if(g&&c==='*'){r+='[\\s\\S]*';continue}
    if(g&&c==='?'){r+='[\\s\\S]';continue}
    if(g&&c==='['){let j=i+1,neg=false;if(j<chars.length&&(chars[j].c==='!'||chars[j].c==='^')){neg=true;j++}
      let k=j;if(k<chars.length&&chars[k].c===']')k++;while(k<chars.length&&chars[k].c!==']')k++;
      if(k<chars.length){const body=chars.slice(j,k).map(x=>x.c).join('').replace(/\\/g,'\\\\').replace(/\]/g,'\\]');r+='['+(neg?'^':'')+body+']';i=k;continue}}
    r+=c.replace(/[.*+?^${}()|[\]\\/]/g,'\\$&')}
  return r}
function braces(s){                                    // {1..5} {1..10..3} {a,b} in an unquoted word
  const m=/^([\s\S]*?)\{([^{}]*)\}([\s\S]*)$/.exec(s);if(!m)return[s];
  const[,pre,body,post]=m;let items=null,r;
  if((r=/^(-?\d+)\.\.(-?\d+)(?:\.\.(-?\d+))?$/.exec(body))){const a=+r[1],b=+r[2],st=Math.abs(+(r[3]||1))||1;items=[];if(a<=b)for(let v=a;v<=b&&items.length<5000;v+=st)items.push(String(v));else for(let v=a;v>=b&&items.length<5000;v-=st)items.push(String(v))}
  else if((r=/^([a-zA-Z])\.\.([a-zA-Z])$/.exec(body))){items=[];const a=r[1].charCodeAt(0),b=r[2].charCodeAt(0);for(let v=a;a<=b?v<=b:v>=b;v+=a<=b?1:-1)items.push(String.fromCharCode(v))}
  else if(body.includes(','))items=body.split(',');
  if(!items)return[s];
  return items.flatMap(it=>braces(pre+it+post))}
const patRx=s=>new RegExp('^'+globRx([...s].map(c=>({c,g:true})))+'$');

/* ---- decimal numbers for bc: {n: BigInt, s: digits after the point} ---- */
const P10=k=>10n**BigInt(k);
const dnum=str=>{const m=/^(\d*)(?:\.(\d*))?$/.exec(str);const ip=m[1]||'0',fp=m[2]||'';return{n:BigInt(ip+fp),s:fp.length}};
const dfix=(a,s)=>s>=a.s?a.n*P10(s-a.s):a.n/P10(a.s-s);
function dfmt(a){if(a.s===0)return a.n.toString();const neg=a.n<0n;let t=(neg?-a.n:a.n).toString().padStart(a.s+1,'0');
  const ip=t.slice(0,-a.s),fp=t.slice(-a.s);return(neg?'-':'')+(ip==='0'?'':ip)+'.'+fp}
function isqrt(n){if(n<2n)return n;let x=BigInt(Math.floor(Math.sqrt(Number(n))))||1n;for(;;){const y=(x+n/x)>>1n;if(y>=x&&y-x<=1n){while(y*y>n&&false);break}x=y}while(x*x>n)x--;while((x+1n)*(x+1n)<=n)x++;return x}
/* bc -l: s c a l e on fixed-point numbers X / 10^S */
function mathlib(f,X,S){
  const ONE=P10(S),abs=v=>v<0n?-v:v,sq=v=>isqrt(v*ONE);
  const exp=x=>{let k=0;while(abs(x)>ONE/2n){x/=2n;k++}let sum=ONE,term=ONE;for(let i=1n;;i++){term=term*x/ONE/i;if(!term)break;sum+=term}while(k--)sum=sum*sum/ONE;return sum};
  const atan=x=>{let k=0n;while(abs(x)>ONE/2n){x=x*ONE/(ONE+sq(ONE+x*x/ONE));k++}let sum=0n,term=x;const x2=x*x/ONE;for(let i=1n,sg=1n;term;i+=2n,sg=-sg){sum+=sg*term/i;term=term*x2/ONE}return sum*(1n<<k)};
  if(f==='e')return exp(X);
  if(f==='a')return atan(X);
  if(f==='l'){if(X<=0n)throw 'log';let k=0n;while(X>2n*ONE||X<ONE/2n){X=sq(X);k++}const y=(X-ONE)*ONE/(X+ONE),y2=y*y/ONE;let sum=0n,term=y;for(let i=1n;term;i+=2n){sum+=term/i;term=term*y2/ONE}return 2n*sum*(1n<<k)}
  const pi2=8n*atan(ONE/2n)+8n*atan(ONE/3n);let x=X%pi2;
  const x2=x*x/ONE;let sum=0n,term=f==='s'?x:ONE;
  for(let k=1n;term;k++){sum+=term;term=f==='s'?-term*x2/ONE/((2n*k)*(2n*k+1n)):-term*x2/ONE/((2n*k-1n)*(2n*k))}
  return sum}
function bcEval(text,lib){                               // the bc calculator: returns {out, err}; lib: bc -l
  let scale=lib?20:0;const vars={};let out='',err='';
  const lines=text.split('\n');
  lines.forEach((ln,li)=>{
    for(const stmt0 of ln.replace(/#.*|\/\*.*?\*\//g,'').split(';')){const stmt=stmt0.trim();if(!stmt)continue;
      const toks=[];const re=/\s+|(\d+\.?\d*|\.\d+)|([a-z_][a-z0-9_]*)|(&&|\|\||<=|>=|==|!=|\^|[-+*/%()=<>!])/y;let i=0,bad=false;
      while(i<stmt.length){re.lastIndex=i;const m=re.exec(stmt);if(!m){bad=true;break}if(m[1]!==undefined)toks.push({t:'n',v:m[1]});else if(m[2]!==undefined)toks.push({t:'id',v:m[2]});else if(m[3]!==undefined)toks.push({t:'op',v:m[3]});i=re.lastIndex}
      if(bad){err+='(standard_in) '+(li+1)+': syntax error\n';continue}
      let p=0;const pk=()=>toks[p];
      const fail=()=>{throw 'syntax'};
      const num=t=>dnum(t.v);
      const add=(a,b,neg)=>{const s=Math.max(a.s,b.s);return{n:dfix(a,s)+(neg?-1n:1n)*dfix(b,s),s}};
      const mul=(a,b)=>{const full=a.s+b.s,s=Math.min(full,Math.max(scale,a.s,b.s));return{n:dfix({n:a.n*b.n,s:full},s),s}};
      const div=(a,b)=>{if(b.n===0n)throw 'zero';return{n:(a.n*P10(b.s+scale))/(b.n*P10(a.s)),s:scale}};
      const mod=(a,b)=>{const q=div(a,b);const prod=mul(q,b);return add(a,prod,true)};
      const pow=(a,b)=>{const e=Number(dfix(b,0));if(e<0){const one={n:1n,s:0};let r=one;for(let k=0;k<-e;k++)r=mul(r,a);return div(one,r)}let r={n:1n,s:0};for(let k=0;k<e;k++)r={n:r.n*a.n,s:r.s+a.s};const s=Math.min(a.s*e,Math.max(scale,a.s));return{n:dfix(r,s),s}};
      const prim=()=>{const t=pk();if(!t)fail();
        if(t.t==='op'&&t.v==='('){p++;const v=orE();if(!pk()||pk().v!==')')fail();p++;return v}
        if(t.t==='op'&&t.v==='-'){p++;const v=prim();return{n:-v.n,s:v.s}}
        if(t.t==='n'){p++;return num(t)}
        if(t.t==='id'&&toks[p+1]&&toks[p+1].v==='('&&(t.v==='sqrt'||t.v==='length'||(lib&&/^[sclae]$/.test(t.v)))){p+=2;const v=orE();if(!pk()||pk().v!==')')fail();p++;
          if(t.v==='length')return{n:BigInt(dfmt(v).replace(/[-.]/g,'').replace(/^0+(?=\d)/,'').length||1),s:0};
          if(t.v==='sqrt'){if(v.n<0n)throw 'sqrt';const sc=Math.max(scale,v.s);return{n:isqrt(v.n*P10(2*sc-v.s)),s:sc}}
          return{n:mathlib(t.v,dfix(v,scale+12)*P10(0),scale+12)/P10(12),s:scale}}
        if(t.t==='id'){p++;if(t.v==='scale')return{n:BigInt(scale),s:0};return vars[t.v]||{n:0n,s:0}}
        fail()};
      const powE=()=>{const a=prim();if(pk()&&pk().v==='^'){p++;return pow(a,powE())}return a};
      const prod=()=>{let a=powE();while(pk()&&'*/%'.includes(pk().v)&&pk().t==='op'){const o=toks[p++].v,b=powE();a=o==='*'?mul(a,b):o==='/'?div(a,b):mod(a,b)}return a};
      const sum=()=>{let a=prod();while(pk()&&(pk().v==='+'||pk().v==='-')&&pk().t==='op'){const o=toks[p++].v,b=prod();a=add(a,b,o==='-')}return a};
      const cmpv=(a,b)=>{const s=Math.max(a.s,b.s),x=dfix(a,s),y=dfix(b,s);return x<y?-1:x>y?1:0};
      const B1=v=>({n:v?1n:0n,s:0});
      const rel=()=>{let a=sum();while(pk()&&pk().t==='op'&&['<','>','<=','>=','==','!='].includes(pk().v)){const o=toks[p++].v,b=sum(),c=cmpv(a,b);a=B1({'<':c<0,'>':c>0,'<=':c<=0,'>=':c>=0,'==':c===0,'!=':c!==0}[o])}return a};
      const notE=()=>{if(pk()&&pk().v==='!'){p++;return B1(notE().n===0n)}return rel()};
      const andE=()=>{let a=notE();while(pk()&&pk().v==='&&'){p++;const b=notE();a=B1(a.n!==0n&&b.n!==0n)}return a};
      const orE=()=>{let a=andE();while(pk()&&pk().v==='||'){p++;const b=andE();a=B1(a.n!==0n||b.n!==0n)}return a};
      try{
        if(toks.length>=2&&toks[0].t==='id'&&toks[1].v==='='){p=2;const v=orE();if(p<toks.length)fail();if(toks[0].v==='scale')scale=Number(dfix(v,0));else vars[toks[0].v]=v;continue}
        const v=orE();if(p<toks.length)fail();out+=dfmt(v)+'\n'}
      catch(e){if(e==='sqrt')err+='Runtime error (func=(main), adr=4): Square root of a negative number\n';else if(e==='log')err+='Runtime error: log of a number <= 0\n';else if(e==='zero')err+='Runtime error (func=(main), adr=5): Divide by zero\n';else err+='(standard_in) '+(li+1)+': syntax error\n'}
    }});
  return{out,err}}

/* ================================================================ arithmetic: $(( )) and (( )) */
function arithParse(src){
  const toks=[];const re=/\s+|(0[xX][0-9a-fA-F]+|[0-9]+)|([A-Za-z_]\w*)|(\*\*=|<<=|>>=|\*\*|\+\+|--|<=|>=|==|!=|&&|\|\||<<|>>|\+=|-=|\*=|\/=|%=|&=|\|=|\^=|[-+*/%<>=!~&|^?:(),])/y;
  let i=0;
  while(i<src.length){re.lastIndex=i;const m=re.exec(src);
    if(!m||m.index!==i)throw{ar:'syntax error: invalid arithmetic operator (error token is "'+src.slice(i)+'")'};
    if(m[1]!==undefined)toks.push({t:'n',v:m[1],at:i});else if(m[2]!==undefined)toks.push({t:'id',v:m[2],at:i});else if(m[3]!==undefined)toks.push({t:'op',v:m[3],at:i});
    i=re.lastIndex}
  let p=0;
  const pk=()=>toks[p], rest=()=>p<toks.length?src.slice(toks[p].at):'';
  const opIs=(...v)=>pk()&&pk().t==='op'&&v.includes(pk().v);
  const operand=()=>{throw{ar:'syntax error: operand expected (error token is "'+rest()+'")'}};
  function comma(){let a=assign();while(opIs(',')){p++;a={k:'comma',a,b:assign()}}return a}
  function assign(){const t=pk(),t2=toks[p+1];
    if(t&&t.t==='id'&&t2&&t2.t==='op'&&/^(=|\*\*=|[-+*/%&|^]=|<<=|>>=)$/.test(t2.v)){p+=2;return{k:'asg',op:t2.v,n:t.v,b:assign()}}
    return tern()}
  function tern(){const c=bin(0);if(opIs('?')){p++;const a=assign();if(!opIs(':'))throw{ar:"syntax error: `:' expected for conditional expression (error token is \""+rest()+'")'};p++;const b=assign();return{k:'tern',c,a,b}}return c}
  const LV=[['||'],['&&'],['|'],['^'],['&'],['==','!='],['<','<=','>','>='],['<<','>>'],['+','-'],['*','/','%']];
  function bin(l){if(l===LV.length)return pw();let a=bin(l+1);while(opIs(...LV[l])){const t=toks[p++];const b=bin(l+1);a={k:'bin',op:t.v,a,b,at:toks[p-1]?t.at+t.v.length:t.at}}return a}
  function pw(){const a=un();if(opIs('**')){p++;return{k:'bin',op:'**',a,b:pw()}}return a}
  function un(){if(opIs('-','+','!','~')){const o=toks[p++].v;return{k:'un',op:o,a:un()}}
    if(opIs('++','--')){const o=toks[p++].v;const id=pk();if(!id||id.t!=='id')operand();p++;return{k:'pre',op:o,n:id.v}}
    return post()}
  function post(){const t=pk();if(!t)operand();
    if(t.t==='n'){p++;return{k:'num',v:t.v}}
    if(t.t==='id'){p++;if(opIs('++','--'))return{k:'post',op:toks[p++].v,n:t.v};return{k:'var',n:t.v}}
    if(t.t==='op'&&t.v==='('){p++;const e=comma();if(!opIs(')'))throw{ar:"syntax error: missing `)' (error token is \""+rest()+'")'};p++;return e}
    operand()}
  if(!toks.length)return{k:'num',v:'0'};
  const e=comma();
  if(p<toks.length)throw{ar:'syntax error in expression (error token is "'+rest()+'")'};
  e.src=src;return e;
}

/* ================================================================ the shell */
class Sh{
  constructor(o){
    this.name=o.name||'./script.sh';this.pos=[this.name].concat(o.args||[]);
    this.vars=new Map();
    for(const[k,v]of Object.entries({HOME:HOMEP,USER:'student',PATH:'/usr/local/bin:/usr/bin:/bin',PWD:HOMEP,SHELL:'/bin/bash'}))this.vars.set(k,{v,x:true});
    this.vars.set('IFS',{v:DEFIFS,x:false,init:true});
    for(const[k,v]of Object.entries(o.vars||{}))this.vars.set(k,{v:String(v),x:false});
    this.funcs=new Map();this.frames=[];this.status=0;this.fs=o.fs;this.T=o.T;this.depth=0;this.loops=0;this.line=1;this.substStatus=0;this.inter=!!o.inter;
  }
  clone(){const c=Object.create(Sh.prototype);Object.assign(c,this);
    c.vars=new Map([...this.vars].map(([k,v])=>[k,Object.assign({},v)]));c.funcs=new Map(this.funcs);c.pos=this.pos.slice();
    c.frames=this.frames.map(f=>({saved:new Map(f.saved),locals:new Set(f.locals)}));c.depth=this.depth+1;return c}
  ifs(){const e=this.vars.get('IFS');return e?e.v:DEFIFS}
  get(n){const e=this.vars.get(n);return e?e.v:undefined}
  setVar(n,v){if(n==='IFS')this.T.showIFS=true;else this.T.show.add(n);const e=this.vars.get(n);this.vars.set(n,{v:String(v),x:e?e.x:false})}
  errl(io,m){io.err((this.inter?'bash: ':this.name+': line '+this.line+': ')+m+'\n')}
  tick(){if(++this.T.ops>20000)throw new Flow('limit')}

  /* ---- the debugger: a step after every command, the variables compared with the previous step ---- */
  snap(){
    const T=this.T,m=new Map();
    if(T.showPos){if(T.show0)m.set('$0',{v:this.pos[0]});for(let k=1;k<this.pos.length;k++)m.set('$'+k,{v:this.pos[k]});m.set('$#',{v:String(this.pos.length-1)})}
    if(T.showIFS){const e=this.vars.get('IFS');m.set('IFS',e?{v:ifsDesc(e.v),tag:e.init?'default':null}:{v:'space tab newline',tag:'not set, default'})}
    const locals=new Map();this.frames.forEach(f=>{for(const n of f.locals)if(!locals.has(n))locals.set(n,f)});
    for(const n of T.show){
      if(locals.has(n)){const g=locals.get(n).saved.get(n);if(g)m.set(n,{v:g.v,tag:g.x?'exported':null});const c=this.vars.get(n);if(c)m.set(n+' (local)',{v:c.v})}
      else{const e=this.vars.get(n);if(e)m.set(n,{v:e.v,tag:e.x?'exported':null})}}
    return m}
  emit(st){
    const T=this.T;if(T.quiet)return;
    if(T.steps.length>=T.max)throw new Flow('limit');
    const snap=this.snap(),vars={},unset=[],tags={};
    for(const[k,o]of snap){const p=T.prev.get(k);if(!p||p.v!==o.v)vars[k]=o.v;if((p?p.tag||null:null)!==(o.tag||null))tags[k]=o.tag||null}
    for(const k of T.prev.keys())if(!snap.has(k))unset.push(k);
    T.prev=snap;
    const s=Object.assign({},st);
    if(Object.keys(vars).length)s.vars=vars;if(unset.length)s.unset=unset;if(Object.keys(tags).length)s.tags=tags;
    const o=T.term.slice(T.last);T.last=T.term.length;if(o)s.o=o;
    if(this.depth>0&&!s.who)s.who='copy';
    for(const k of Object.keys(s))if(s[k]===undefined)delete s[k];
    T.steps.push(s)}

  /* ---- expansions ---- */
  param(g){
    const n=g.name;let v;
    if(g.bad)throw new BErr(g.bad+': bad substitution');
    if(/^[0-9]+$/.test(n))v=this.pos[+n];
    else if(n==='#')v=String(this.pos.length-1);
    else if(n==='?')v=String(this.status);
    else if(n==='@'||n==='*')v=this.pos.slice(1).join(' ');
    else if(n==='$')v='4100';else if(n==='!')v='';else if(n==='-')v='hB';
    else if(n==='RANDOM')v=String((this.T.rnd=(this.T.rnd*1103515245+12345)%32768));
    else if(n==='LINENO')v=String(this.line);
    else v=this.get(n);
    if(g.op==='#')return String((v||'').length);
    if(g.op){const empty=v==null||(g.op[0]===':'&&v==='');const o=g.op.replace(':','');const arg=this.expandText(g.arg||'');
      if(o==='-')return empty?arg:v;
      if(o==='='){if(empty){this.setVar(n,arg);return arg}return v}
      if(o==='+')return empty?'':arg;
      if(o==='?'){if(empty)throw new BErr(n+': '+(arg||'parameter null or not set'));return v}}
    return v==null?'':v}
  expandText(s){if(!/[$`]/.test(s))return s;const w=lex('"'+s.replace(/(["\\])/g,'\\$1')+'"',this.line)[0];return w?this.expand(w,null,'str'):''}
  subst(src,io){
    const prog=parseC(src,this.line);const c=this.clone();let buf='';
    const io2={in:io?io.in:null,out:s=>{buf+=s},err:io?io.err:(s=>{this.T.term+='\u0001'+s+'\u0002'}),tty:false};
    try{c.exec(prog,io2)}catch(f){if(f instanceof Flow){if(f.kind==='limit')throw f;c.status=f.status}else throw f}
    if(prog.error){c.line=prog.error.line;c.errl(io2,prog.error.message);c.status=2}
    this.substStatus=c.status;
    return buf.replace(/\n+$/,'')}
  arith(src){
    let ast;
    try{ast=arithParse(src)}catch(e){if(e.ar)throw new BErr(src.trim()+': '+e.ar);throw e}
    try{return this.ev(ast,0)}catch(e){if(e.ar)throw new BErr(src.trim()+': '+e.ar);throw e}}
  avar(n,d){const v=this.get(n);if(v==null||v.trim()==='')return 0n;if(isInt(v))return BigInt(v.trim());if(d>8)throw{ar:'expression recursion level exceeded'};
    let ast;try{ast=arithParse(v.trim())}catch(e){if(e.ar)throw new BErr(v.trim()+': '+e.ar);throw e}return this.ev(ast,d+1)}
  ev(x,d){
    const W=v=>BigInt.asIntN(64,v);
    const B=(o,a,b,at)=>{switch(o){
      case '+':return W(a+b);case '-':return W(a-b);case '*':return W(a*b);
      case '/':case '%':if(b===0n)throw{ar:'division by 0 (error token is "'+(at!=null?x.src.slice(at).trim():'')+'")'};return o==='/'?a/b:a%b;
      case '**':if(b<0n)throw{ar:'exponent less than 0'};return W(a**b);
      case '<<':return W(a<<b);case '>>':return a>>b;case '&':return a&b;case '|':return a|b;case '^':return a^b;
      case '<':return a<b?1n:0n;case '<=':return a<=b?1n:0n;case '>':return a>b?1n:0n;case '>=':return a>=b?1n:0n;case '==':return a===b?1n:0n;case '!=':return a!==b?1n:0n}};
    switch(x.k){
      case 'num':return x.v.startsWith('0x')||x.v.startsWith('0X')?BigInt(x.v):x.v.length>1&&x.v[0]==='0'?BigInt('0o'+x.v):BigInt(x.v);
      case 'var':return this.avar(x.n,d);
      case 'un':{const a=this.ev(x.a,d);return x.op==='-'?W(-a):x.op==='+'?a:x.op==='!'?(a?0n:1n):~a}
      case 'pre':{const v=this.avar(x.n,d)+(x.op==='++'?1n:-1n);this.setVar(x.n,String(v));return v}
      case 'post':{const v=this.avar(x.n,d);this.setVar(x.n,String(v+(x.op==='++'?1n:-1n)));return v}
      case 'asg':{let b=this.ev(x.b,d);if(x.op!=='=')b=B(x.op.slice(0,-1),this.avar(x.n,d),b);this.setVar(x.n,String(b));return b}
      case 'tern':return this.ev(x.c,d)?this.ev(x.a,d):this.ev(x.b,d);
      case 'comma':this.ev(x.a,d);return this.ev(x.b,d);
      case 'bin':if(x.op==='&&')return this.ev(x.a,d)&&this.ev(x.b,d)?1n:0n;if(x.op==='||')return this.ev(x.a,d)||this.ev(x.b,d)?1n:0n;
        {const a=this.ev(x.a,d),b=this.ev(x.b,d);x.src=x.src||'';return B(x.op,a,b,x.at)}
    }}
  arithDisp(ex){return ex.trim().replace(/\s+/g,' ').replace(/[A-Za-z_]\w*(?!\s*(?:[-+*/%&|^]|<<|>>)?=(?!=)|\s*\+\+|\s*--)/g,n=>{const v=this.get(n);return v!=null&&isInt(v)?v.trim():v==null||v===''?'0':n})}
  arithExp(src){
    const ex=this.expandText(src),disp=this.arithDisp(ex);
    const r=this.arith(ex);
    this.emit({line:this.line,compute:'$(('+src+'))',info:'computes `'+disp+'` = `'+r+'`'});
    return r}
  expand(w,io,mode){
    if(mode==null&&w.segs.length&&w.segs.every(g=>g.k==='l'&&!g.q)&&/\{[^{}]*(,|\.\.)[^{}]*\}/.test(w.raw)){const b=braces(w.raw);if(b.length>1||b[0]!==w.raw)return b}
    const chars=[];let atZero=false;const fb=new Set();
    const push=(s,sp,gl,q)=>{if(q&&s==='')chars.push({c:'',sp:false,gl:false});for(const c of s)chars.push({c,sp,gl})};
    for(const g of w.segs){
      if(g.k==='l'){push(g.s,false,!g.q,g.q);continue}
      if(g.k==='t'){push(HOMEP,false,false);continue}
      let val;
      if(g.k==='v'){
        if(g.name==='@'&&g.q&&!g.op&&mode!=='str'){const ps=this.pos.slice(1);if(!ps.length){atZero=true;continue}
          ps.forEach((p,k)=>{if(k)fb.add(chars.length);push(p,false,false,true)});continue}
        val=this.param(g)}
      else if(g.k==='c')val=this.subst(g.src,io);
      else if(g.k==='a')val=String(this.arithExp(g.src));
      push(val,!g.q,!g.q,g.q)}
    if(mode==='str')return chars.map(x=>x.c).join('');
    if(mode==='pat')return chars;
    if(atZero&&!chars.length)return[];
    const ifs=this.ifs(),N=chars.length,delim=k=>chars[k].sp&&chars[k].c!==''&&ifs.includes(chars[k].c);
    const fields=[];let cur=[],started=false,i=0;
    while(i<N){
      if(fb.has(i)){fields.push(cur);cur=[];started=false}
      if(delim(i)){let j=i,nw=0;while(j<N&&delim(j)&&!(j>i&&fb.has(j))){if(!isWS(chars[j].c))nw++;j++}
        const atStart=!fields.length&&!started,atEnd=j===N;
        if(nw===0){if(!atStart&&!atEnd){fields.push(cur);cur=[];started=false}}
        else{fields.push(cur);cur=[];started=false;for(let k=1;k<nw;k++)fields.push([])}
        i=j;continue}
      cur.push(chars[i]);started=true;i++}
    if(started)fields.push(cur);
    const out=[];
    for(const f of fields){const s=f.map(x=>x.c).join('');
      if(f.some(x=>x.gl&&/[*?[]/.test(x.c))){const rx=new RegExp('^'+globRx(f.map(x=>({c:x.c,g:x.gl})))+'$');
        const hits=this.globList(s).filter(p=>rx.test(p)&&!(p.split('/').pop().startsWith('.')&&!s.split('/').pop().startsWith('.')));
        if(hits.length){out.push(...hits.sort(cmpName));continue}}
      out.push(s)}
    return out}
  globList(pat){const fs=this.fs,depth=pat.split('/').length-1;const all=[];
    for(const k of [...fs.f.keys(),...fs.d]){if(k.startsWith('/'))continue;const parts=k.split('/');
      for(let l=1;l<=parts.length;l++){const pre=parts.slice(0,l).join('/');const rel=fs.cwd?(pre.startsWith(fs.cwd+'/')?pre.slice(fs.cwd.length+1):null):pre;if(rel!=null&&rel.split('/').length-1===depth&&!all.includes(rel))all.push(rel)}}
    return all}
  patChars(w,io){return this.expand(w,io,'pat').map(x=>({c:x.c,g:x.gl}))}
  patMatch(w,io,text){return new RegExp('^'+globRx(this.patChars(w,io))+'$').test(text)}
  dispFields(w,f){
    const am=/^([A-Za-z_]\w*)=/.exec(w.raw);if(am&&f.length===1&&f[0].startsWith(am[1]+'='))return[am[1]+'='+qv(f[0].slice(am[1].length+1))];
    const qc=(/["']/.exec(w.raw)||[])[0];
    if(f.length===1&&qc&&!w.plain)return[qc==="'"?"'"+f[0]+"'":'"'+f[0]+'"'];
    return f.map(x=>x===''?"''":/[\s"'\\$`|&;<>()]/.test(x)?'"'+x+'"':x)}

  /* ---- redirects ---- */
  redirIO(rs,io){
    const o=Object.assign({},io);
    for(const r of rs){const m=/^([0-9]?)(>>|>&|>|<<<|<|&>>|&>)(.*)$/.exec(r.op),fd=m[1],op=m[2];
      const t=r.w?this.expand(r.w,io,'str'):null;
      if(op==='<'){const d=this.fs.read(t);if(d==null)throw new BErr(t+': '+(this.fs.isDir(t)?'Is a directory':'No such file or directory'));o.in={data:d,pos:0}}
      else if(op==='<<<')o.in={data:t+'\n',pos:0};
      else if(op==='>&'){if(m[3]==='1')o.err=o.out;else if(m[3]==='2')o.out=o.err}
      else{const app=op.includes('>>');this.fs.write(t,'',true);if(!app)this.fs.write(t,'');const w=s=>this.fs.write(t,s,true);
        if(op[0]==='&'){o.out=w;o.err=w;o.tty=false}else if(fd==='2')o.err=w;else{o.out=w;o.tty=false}}}
    return o}
  redirText(rs,io){return rs.map(r=>' '+r.op+(r.w?(r.op.endsWith('>')||r.op.endsWith('<')?' ':'')+this.expand(r.w,io,'str'):'')).join('')}

  /* ---- execution ---- */
  exec(n,io){
    switch(n.T){
      case 'list':{let s=this.status;for(const it of n.items)s=this.exec(it,io);return s}
      case 'andor':{let s=this.exec(n.first,io);for(const r of n.rest)if(r.op==='&&'?s===0:s!==0)s=this.exec(r.node,io);return this.status=s}
      case 'not':{const s=this.exec(n.node,io);return this.status=s?0:1}
      case 'pipe':return this.pipe(n,io);
      case 'simple':return this.simple(n,io,false);
    }
    let io2=io;
    if(n.redirs&&n.redirs.length){this.line=n.line;try{io2=this.redirIO(n.redirs,io)}catch(e){if(e instanceof BErr){this.errl(io,e.message);this.emit({line:n.line,part:n.src.split('\n')[0],status:1});return this.status=1}throw e}}
    return this.compound(n,io2)}
  loop(fn){this.loops++;try{return fn()}finally{this.loops--}}
  body(n,io){                                            // runs a loop body: true to stop the loop
    try{return[this.exec(n,io),false]}
    catch(f){if(f instanceof Flow&&(f.kind==='break'||f.kind==='continue')){if(f.n>1){f.n--;throw f}return[0,f.kind==='break']}throw f}}
  compound(n,io){
    switch(n.T){
      case 'group':return this.exec(n.body,io);
      case 'sub':{const c=this.clone();try{c.exec(n.body,io)}catch(f){if(f instanceof Flow&&f.kind!=='limit')c.status=f.status;else throw f}return this.status=c.status}
      case 'arith':{this.line=n.line;this.tick();let r,st;
        const ex=this.expandText(n.src),disp=this.arithDisp(ex);
        try{r=this.arith(ex);st=r!==0n?0:1}catch(e){if(e instanceof BErr){this.errl(io,e.message);this.emit({line:n.line,part:'(('+n.src+'))',status:1});return this.status=1}throw e}
        this.emit({line:n.line,part:'(('+n.src+'))',compute:'(('+n.src+'))',info:'computes `'+disp+'` = `'+r+'`',status:st});
        return this.status=st}
      case 'if':{for(const cl of n.clauses){if(this.exec(cl.cond,io)===0)return this.exec(cl.body,io)}if(n.els)return this.exec(n.els,io);return this.status=0}
      case 'while':return this.loop(()=>{let s=0;for(;;){this.tick();const c=this.exec(n.cond,io);if(n.until?c===0:c!==0)break;const[r,stop]=this.body(n.body,io);s=r;if(stop)break}return this.status=s});
      case 'for':{this.line=n.line;let list;
        if(n.words){list=[];let ex=false;
          try{for(const w of n.words){if(!w.plain||/[*?[]/.test(w.raw))ex=true;list.push(...this.expand(w,io))}}
          catch(e){if(e instanceof BErr){this.errl(io,e.message);return this.status=1}throw e}
          if(ex){const one=n.words.length===1&&/[*?[]/.test(n.words[0].raw)&&n.words[0].plain;
            this.emit({line:n.line,part:n.words.map(w=>w.raw).join(' '),info:(one?'expands `'+n.words[0].raw+'` to ':'the list: ')+(list.length?list.map(x=>'`'+x+'`').join(' '):'*no words*')})}}
        else{list=this.pos.slice(1);this.emit({line:n.line,info:'no `in`: the parameters, '+(list.length?list.map(x=>'`'+x+'`').join(' '):'*none*')})}
        return this.loop(()=>{let s=0;for(const v of list){this.tick();this.setVar(n.name,v);this.emit({line:n.line,run:n.name+'='+qv(v)});const[r,stop]=this.body(n.body,io);s=r;if(stop)break}return this.status=s})}
      case 'cfor':{this.line=n.line;
        const A=(src,what)=>{if(!src.trim())return 1n;const ex=this.expandText(src),disp=this.arithDisp(ex);const r=this.arith(ex);this.emit({line:n.line,part:src.trim(),compute:src.trim(),info:what==='cond'?'`'+disp+'` is '+(r?'true':'false'):'computes `'+disp+'` = `'+r+'`'});return r};
        try{return this.loop(()=>{let s=0;A(n.init);for(;;){this.tick();if(!A(n.cond,'cond'))break;const[r,stop]=this.body(n.body,io);s=r;if(stop)break;A(n.step)}return this.status=s})}
        catch(e){if(e instanceof BErr){this.errl(io,e.message);return this.status=1}throw e}}
      case 'case':{this.line=n.line;let w;
        try{w=this.expand(n.word,io,'str')}catch(e){if(e instanceof BErr){this.errl(io,e.message);return this.status=1}throw e}
        this.emit({line:n.line,part:n.word.raw,info:'compares the text `'+w+'` with the patterns'});
        for(const it of n.items){this.tick();const k=it.pats.findIndex(p=>this.patMatch(p,io,w));
          this.emit({line:it.line,part:it.pats.map(p=>p.raw).join('|'),info:k>=0?'`'+w+'` matches `'+it.pats[k].raw+'`':'`'+w+'` does not match'});
          if(k>=0)return it.body.items.length?this.exec(it.body,io):(this.status=0)}
        this.emit({line:n.eLine,info:'no pattern matched: no branch runs, `case` ends with `0`'});
        return this.status=0}
      case 'func':this.funcs.set(n.name,n);this.emit({line:n.line,run:n.name+'() { ... }',info:'defines the command `'+n.name+'`, nothing runs'});return this.status=0;
    }
    return 0}
  pipe(n,io){
    this.line=n.line;let data=null,st=0;const disp=[];
    const parts=n.cmds.map((c,k)=>{const sub=this.clone();return{c,sub}});
    parts.forEach(({c,sub},k)=>{
      const last=k===parts.length-1;let buf='';
      const io2={in:data==null?io.in:{data,pos:0},out:last?io.out:(s=>{buf+=s}),err:io.err,tty:last?io.tty:false};
      try{if(c.T==='simple'){const r=sub.simple(c,io2,true);st=r;disp.push(sub.lastRun||c.src)}else{st=sub.exec(c,io2);disp.push(c.src)}}
      catch(f){if(f instanceof Flow&&f.kind!=='limit')st=f.status;else throw f}
      data=buf});
    this.status=st;
    this.emit({line:n.line,part:n.cmds.map(c=>c.src),run:disp.join(' | '),status:st});
    return st}
  simple(n,io,inPipe){
    this.tick();this.line=n.line;
    if(n.words.length&&n.words[0].plain&&n.words[0].raw==='[[')return this.dbl(n,io,inPipe);
    const step=st=>{if(!inPipe)this.emit(Object.assign({line:n.line,part:n.src},st))};
    let fields=[],disp=[];
    this.substStatus=0;
    try{for(const w of n.words){const f=this.expand(w,io);fields.push(...f);disp.push(...this.dispFields(w,f))}}
    catch(e){if(e instanceof BErr){this.errl(io,e.message);step({status:1});return this.status=1}throw e}
    if(!fields.length){
      const shown=[];
      try{for(const a of n.asg){const{name,val,app}=this.asgVal(a,io);this.setVar(name,app?(this.get(name)||'')+val:val);shown.push(name+'='+qv(this.get(name)))}
        if(n.redirs.length)this.redirIO(n.redirs,io)}
      catch(e){if(e instanceof BErr){this.errl(io,e.message);step({status:1});return this.status=1}throw e}
      this.lastRun=shown.join(' ')||n.src;
      step({run:this.lastRun});
      return this.status=this.substStatus}
    const name=fields[0],args=fields.slice(1);
    const saved=[];let io2=io,st=0,pre='';
    try{
      for(const a of n.asg){const{name:vn,val}=this.asgVal(a,io);saved.push([vn,this.vars.get(vn)]);this.vars.set(vn,{v:val,x:true});pre+=vn+'='+qv(val)+' '}
      io2=n.redirs.length?this.redirIO(n.redirs,io):io}
    catch(e){if(e instanceof BErr){for(const[k,v]of saved.reverse()){if(v)this.vars.set(k,v);else this.vars.delete(k)}this.errl(io,e.message);step({status:1});return this.status=1}throw e}
    const run=pre+disp.join(' ')+this.redirText(n.redirs,io);this.lastRun=run;
    let printed='';if(this.depth>0&&!io2.tty){const o=io2.out;io2=Object.assign({},io2,{out:s=>{printed+=s;o(s)}})}
    this.T.note=null;
    const restore=()=>{for(const[k,v]of saved.reverse()){if(v)this.vars.set(k,v);else this.vars.delete(k)}};
    if(this.funcs.has(name)){step({run});try{st=this.call(name,args,io2)}finally{restore()}return this.status=st}
    const fn=BUILTIN[name]||EXT[name];
    try{
      if(fn)st=fn.call(this,args,io2,{name,line:n.line});
      else if(name.includes('/')){st=127;if(this.fs.isFile(name)||this.fs.isDir(name)){this.errl(io2,name+': Permission denied');st=126}else this.errl(io2,name+': No such file or directory')}
      else{this.errl(io2,name+': command not found');st=127}}
    catch(e){
      if(e instanceof Flow&&e.kind!=='limit'){restore();this.status=e.status;step(e.kind==='return'||e.kind==='exit'?{run,status:e.status}:{run});throw e}
      if(e instanceof BErr){this.errl(io2,e.message);st=e.status}else{restore();throw e}}
    restore();
    this.status=st;
    let info=this.T.note;this.T.note=null;
    if(printed){const l=printed.replace(/\n$/,'').split('\n');info=(info?info+', ':'')+'prints '+(l.length>3?l.slice(0,3).map(x=>'`'+x+'`').join(', ')+' …':l.map(x=>'`'+x+'`').join(', '))}
    step(info?{run,status:st,info}:{run,status:st});
    return st}
  asgVal(a,io){const raw=a.raw,i=raw.indexOf('='),app=raw[i-1]==='+';const name=raw.slice(0,app?i-1:i);
    const w={segs:a.segs.map(x=>Object.assign({},x)),raw:raw.slice(i+1)};const s0=w.segs[0];s0.s=s0.s.slice(i+1);
    if(s0.s===''&&w.segs.length>1)w.segs.shift();
    if(w.segs[0]&&w.segs[0].k==='l'&&!w.segs[0].q&&w.segs[0].s.startsWith('~')&&(w.segs[0].s.length===1||w.segs[0].s[1]==='/')){w.segs[0].s=w.segs[0].s.slice(1);w.segs.unshift({k:'t'})}
    return{name,val:this.expand(w,io,'str'),app}}
  call(name,args,io){
    const f=this.funcs.get(name);const savedPos=this.pos;this.pos=[this.pos[0]].concat(args);
    this.frames.push({saved:new Map(),locals:new Set()});
    if(this.frames.length>60){this.frames.pop();this.pos=savedPos;throw new BErr(name+': maximum function nesting level exceeded (60)')}
    let st=0;
    try{st=this.exec(f.body,io)}
    catch(e){if(e instanceof Flow&&e.kind==='return')st=e.status;else throw e}
    finally{const fr=this.frames.pop();for(const[k,v]of fr.saved){if(v)this.vars.set(k,v);else this.vars.delete(k)}this.pos=savedPos}
    return this.status=st}
  dbl(n,io,inPipe){
    const ws=n.words.slice(1),end=ws.findIndex(w=>w.plain&&w.raw===']]');
    const step=st=>{if(!inPipe)this.emit(Object.assign({line:n.line,part:n.src},st))};
    if(end<0||end!==ws.length-1){this.errl(io,end<0?"syntax error: `]]' expected":"syntax error near `"+ws[end+1].raw+"'");step({status:2});return this.status=2}
    const t=ws.slice(0,end);let p=0;const R=k=>t[k]&&t[k].plain?t[k].raw:null;const shown=[];
    const val=w=>{const v=this.expand(w,io,'str');shown.push(qv(v));return v};
    const UN=['-z','-n','-e','-f','-d','-r','-w','-x','-s'],BI=['==','=','!=','<','>','-eq','-ne','-lt','-le','-gt','-ge','=~'];
    const orE=()=>{let v=andE();while(R(p)==='||'){p++;shown.push('||');const w=andE();v=v||w}return v};
    const andE=()=>{let v=notE();while(R(p)==='&&'){p++;shown.push('&&');const w=notE();v=v&&w}return v};
    const notE=()=>{if(R(p)==='!'){p++;shown.push('!');return !notE()}return prim()};
    const prim=()=>{
      if(R(p)==='('){p++;shown.push('(');const v=orE();if(R(p)!==')')throw new BErr("syntax error in conditional expression",2);p++;shown.push(')');return v}
      if(UN.includes(R(p))&&t[p+1]){const o=R(p);p++;shown.push(o);return this.un(o,val(t[p++]))}
      if(t[p+1]&&BI.includes(R(p+1))){const x=val(t[p]),o=R(p+1);shown.push(o);p+=2;const yw=t[p++];if(!yw)throw new BErr('unexpected argument to conditional binary operator',2);
        if(o==='=='||o==='='||o==='!='){shown.push(qv(this.expand(yw,io,'str')));const m=this.patMatch(yw,io,x);return o==='!='?!m:m}
        if(o==='=~'){const y=this.expand(yw,io,'str');shown.push(y);return new RegExp(y).test(x)}
        const y=val(yw);
        if(o==='<')return x<y;if(o==='>')return x>y;
        const a=this.arith(x||'0'),b=this.arith(y||'0');return{'-eq':a===b,'-ne':a!==b,'-lt':a<b,'-le':a<=b,'-gt':a>b,'-ge':a>=b}[o]}
      if(t[p]){return val(t[p++])!==''}
      throw new BErr('unexpected end of conditional expression',2)};
    let st;
    try{const v=orE();if(p<t.length)throw new BErr("syntax error near `"+t[p].raw+"'",2);st=v?0:1}
    catch(e){if(e instanceof BErr){this.errl(io,e.message);st=e.status}else throw e}
    this.lastRun='[[ '+shown.join(' ')+' ]]';step({run:this.lastRun,status:st});
    return this.status=st}
  un(o,x){const fs=this.fs;switch(o){case '-z':return x==='';case '-n':return x!=='';case '-e':return fs.isFile(x)||fs.isDir(x);case '-f':return fs.isFile(x);case '-d':return fs.isDir(x);
    case '-r':case '-w':return fs.isFile(x)||fs.isDir(x);case '-x':return fs.isDir(x)||fs.x.has(fs.rel(x));case '-s':return(fs.read(x)||'')!==''}return false}
  bin(x,o,y){
    if(o==='='||o==='==')return x===y;if(o==='!=')return x!==y;if(o==='<')return x<y;if(o==='>')return x>y;
    for(const v of[x,y])if(!isInt(v))throw new BErr(v+': integer expression expected',2);
    const a=BigInt(x.trim()),b=BigInt(y.trim());
    return{'-eq':a===b,'-ne':a!==b,'-lt':a<b,'-le':a<=b,'-gt':a>b,'-ge':a>=b}[o]}
  testEval(a){
    const UN=new Set(['-z','-n','-e','-f','-d','-r','-w','-x','-s','-L','-h']),BI=new Set(['=','==','!=','-eq','-ne','-lt','-le','-gt','-ge','<','>']);
    const n=a.length;
    if(n===0)return false;
    if(n===1)return a[0]!=='';
    if(n===2){if(a[0]==='!')return a[1]==='';if(UN.has(a[0]))return this.un(a[0],a[1]);throw new BErr(a[0]+': unary operator expected',2)}
    if(n===3){if(BI.has(a[1]))return this.bin(a[0],a[1],a[2]);if(a[1]==='-a')return a[0]!==''&&a[2]!=='';if(a[1]==='-o')return a[0]!==''||a[2]!=='';
      if(a[0]==='!')return !this.testEval(a.slice(1));if(a[0]==='('&&a[2]===')')return a[1]!=='';throw new BErr(a[1]+': binary operator expected',2)}
    if(n===4){if(a[0]==='!')return !this.testEval(a.slice(1));if(a[0]==='('&&a[3]===')')return this.testEval(a.slice(1,3))}
    let p=0;
    const orE=()=>{let v=andE();while(a[p]==='-o'){p++;const w=andE();v=v||w}return v};
    const andE=()=>{let v=notE();while(a[p]==='-a'){p++;const w=notE();v=v&&w}return v};
    const notE=()=>{if(a[p]==='!'){p++;return !notE()}return prim()};
    const prim=()=>{if(a[p]==='('){p++;const v=orE();if(a[p]!==')')throw new BErr("`)' expected",2);p++;return v}
      if(UN.has(a[p])&&p+1<a.length){const o=a[p],x=a[p+1];p+=2;return this.un(o,x)}
      if(p+2<a.length&&BI.has(a[p+1])){const x=a[p],o=a[p+1],y=a[p+2];p+=3;return this.bin(x,o,y)}
      if(p<a.length)return a[p++]!=='';throw new BErr('argument expected',2)};
    const v=orE();if(p<a.length)throw new BErr('too many arguments',2);return v}
  inputs(files,io,cmd){
    if(!files.length)return[{name:'',data:io.in?this.readAll(io.in):''}];
    const out=[];for(const f of files){if(f==='-'){out.push({name:'-',data:io.in?this.readAll(io.in):''});continue}
      const d=this.fs.read(f);if(d==null){io.err(cmd+': '+f+': '+(this.fs.isDir(f)?'Is a directory':'No such file or directory')+'\n');out.push(null)}else out.push({name:f,data:d})}
    return out}
  readAll(st){if(st.kb){const d=st.data.slice(st.pos);st.pos=st.data.length;if(d)this.T.term+=d.endsWith('\n')?d:d+'\n';return d}const d=st.data.slice(st.pos);st.pos=st.data.length;return d}
}

/* ================================================================ builtins (inside bash) */
const lines=d=>{const l=d.split('\n');if(l[l.length-1]==='')l.pop();return l};
const BUILTIN={
  echo(a,io){let nl=true,e=false;while(a.length&&/^-[neE]+$/.test(a[0])){for(const c of a[0].slice(1)){if(c==='n')nl=false;if(c==='e')e=true;if(c==='E')e=false}a=a.slice(1)}
    let s=a.join(' ');if(e)s=s.replace(/\\(.)/g,(m,c)=>({n:'\n',t:'\t','\\':'\\',a:'\x07',r:'\r',e:'\x1b'})[c]??m);io.out(s+(nl?'\n':''));return 0},
  printf(a,io){
    if(!a.length){this.errl(io,'printf: usage: printf [-v var] format [arguments]');return 2}
    const fmt=a[0],args=a.slice(1);let k=0,out='',st=0;
    const once=()=>{let r='',i=0,used=false;
      while(i<fmt.length){const c=fmt[i];
        if(c==='\\'){const d=fmt[i+1];r+=({n:'\n',t:'\t','\\':'\\',a:'\x07',r:'\r','"':'"'})[d]??('\\'+(d||''));i+=2;continue}
        if(c==='%'){const m=/^%([-+ 0#]*)(\d*)(?:\.(\d+))?([sdiqcxXobf%])/.exec(fmt.slice(i));if(!m){r+=c;i++;continue}
          i+=m[0].length;if(m[4]==='%'){r+='%';continue}
          const has=k<args.length,arg=has?args[k]:'';if(has)used=true;k++;let v;
          switch(m[4]){
            case 's':v=m[3]!=null?arg.slice(0,+m[3]):arg;break;
            case 'q':v=shq(arg);break;
            case 'c':v=arg[0]||'';break;
            case 'd':case 'i':if(arg===''&&!has)v='0';else if(!isInt(arg)){this.errl(io,'printf: '+arg+': invalid number');st=1;v='0'}else v=String(BigInt(arg.trim()));break;
            case 'f':v=(Number(arg)||0).toFixed(m[3]!=null?+m[3]:6);break;
            case 'x':case 'X':case 'o':case 'b':{const nn=isInt(arg)?Number(arg):0;v=nn.toString(m[4]==='o'?8:m[4]==='b'?2:16);if(m[4]==='X')v=v.toUpperCase();break}}
          const w=+m[2]||0;if(v.length<w)v=m[1].includes('-')?v.padEnd(w):v.padStart(w,m[1].includes('0')&&m[4]!=='s'?'0':' ');
          r+=v;continue}
        r+=c;i++}
      return[r,used]};
    for(;;){const[r,u]=once();out+=r;if(!u||k>=args.length)break}
    io.out(out);return st},
  read(a,io){
    let raw=false,prompt=null,silent=false;const names=[];
    for(let i=0;i<a.length;i++){const x=a[i];
      if(/^-[rsp]+$/.test(x)){if(x.includes('r'))raw=true;if(x.includes('s'))silent=true;if(x.includes('p'))prompt=a[++i]??''}
      else if(x==='-n'||x==='-t'||x==='-d'||x==='-a'){i++}
      else names.push(x)}
    for(const nm of names)if(!/^[A-Za-z_]\w*$/.test(nm)){this.errl(io,"read: `"+nm+"': not a valid identifier");return 1}
    const st=io.in;
    if(prompt!=null&&st&&st.kb)this.T.term+=prompt;
    let line=null,eof=false;
    if(st&&st.pos<st.data.length){
      const take=()=>{const j=st.data.indexOf('\n',st.pos);let l;if(j<0){l=st.data.slice(st.pos);st.pos=st.data.length;eof=true}else{l=st.data.slice(st.pos,j);st.pos=j+1}return l};
      line=take();
      if(!raw)while(/(^|[^\\])(\\\\)*\\$/.test(line)&&st.pos<st.data.length)line=line.slice(0,-1)+take()}
    if(st&&st.kb){if(line!=null)this.T.term+=(silent?'':line)+'\n';else if(prompt!=null)this.T.term+='\n'}
    if(line==null){this.T.note='end of the input: no line';for(const nm of names.length?names:['REPLY'])this.setVar(nm,'');return 1}
    this.T.note='reads `'+line+'`';
    const ch=[];for(let i=0;i<line.length;i++){if(!raw&&line[i]==='\\'&&i+1<line.length){ch.push({c:line[i+1],e:true});i++}else ch.push({c:line[i],e:false})}
    if(!names.length){this.setVar('REPLY',ch.map(x=>x.c).join(''));return eof?1:0}
    const ifs=this.ifs(),D=x=>!x.e&&ifs.includes(x.c),Wd=x=>D(x)&&isWS(x.c);
    let i=0;const N=ch.length;
    while(i<N&&Wd(ch[i]))i++;
    names.forEach((nm,k)=>{
      if(k===names.length-1){let j=N;while(j>i&&Wd(ch[j-1]))j--;this.setVar(nm,ch.slice(i,j).map(x=>x.c).join(''));i=N;return}
      let s='';while(i<N&&!D(ch[i]))s+=ch[i++].c;
      if(i<N){while(i<N&&Wd(ch[i]))i++;if(i<N&&D(ch[i])&&!isWS(ch[i].c)){i++;while(i<N&&Wd(ch[i]))i++}}
      this.setVar(nm,s)});
    return eof?1:0},
  test(a,io,c){
    if(c.name==='['){if(a[a.length-1]!==']'){this.errl(io,"[: missing `]'");return 2}a=a.slice(0,-1)}
    try{return this.testEval(a)?0:1}catch(e){if(e instanceof BErr){this.errl(io,c.name+': '+e.message);return 2}throw e}},
  true(){return 0},false(){return 1},':'(){return 0},
  local(a,io){if(!this.frames.length){this.errl(io,'local: can only be used in a function');return 1}
    const f=this.frames[this.frames.length-1];
    for(const x of a){const i=x.indexOf('='),nm=i<0?x:x.slice(0,i);if(!/^[A-Za-z_]\w*$/.test(nm)){this.errl(io,"local: `"+x+"': not a valid identifier");return 1}
      if(!f.locals.has(nm)){f.saved.set(nm,this.vars.get(nm));f.locals.add(nm);this.vars.delete(nm)}
      this.T.show.add(nm);this.vars.set(nm,{v:i<0?(this.get(nm)||''):x.slice(i+1),x:false})}
    return 0},
  export(a){for(const x of a){const i=x.indexOf('='),nm=i<0?x:x.slice(0,i);const e=this.vars.get(nm);this.vars.set(nm,{v:i<0?(e?e.v:''):x.slice(i+1),x:true});if(nm==='IFS')this.T.showIFS=true;else this.T.show.add(nm)}return 0},
  unset(a){for(const x of a){if(x==='-v')continue;if(x==='-f'){continue}if(a[0]==='-f'){this.funcs.delete(x);continue}this.vars.delete(x)}return 0},
  shift(a,io){const k=a.length?+a[0]:1;if(k>this.pos.length-1)return 1;this.pos.splice(1,k);return 0},
  return(a,io){if(!this.frames.length){this.errl(io,"return: can only `return' from a function or sourced script");return 1}
    if(a.length&&!isInt(a[0])){this.errl(io,'return: '+a[0]+': numeric argument required');throw new Flow('return',1,2)}
    throw new Flow('return',1,Number(BigInt.asUintN(8,BigInt(a.length?a[0].trim():this.status))))},
  exit(a,io){if(a.length&&!isInt(a[0])){this.errl(io,'exit: '+a[0]+': numeric argument required');throw new Flow('exit',1,2)}
    throw new Flow('exit',1,Number(BigInt.asUintN(8,BigInt(a.length?a[0].trim():this.status))))},
  break(a,io){if(!this.loops){this.errl(io,"break: only meaningful in a `for', `while', or `until' loop");return 0}throw new Flow('break',a.length?+a[0]:1)},
  continue(a,io){if(!this.loops){this.errl(io,"continue: only meaningful in a `for', `while', or `until' loop");return 0}throw new Flow('continue',a.length?+a[0]:1)},
  cd(a,io){const d=a[0]||'~';if(!this.fs.isDir(d)){this.errl(io,'cd: '+d+': No such file or directory');return 1}const r=this.fs.rel(d);if(r.startsWith('/')){this.errl(io,'cd: the demo stays in your home directory');return 1}this.fs.cwd=r;this.vars.set('PWD',{v:HOMEP+(r?'/'+r:''),x:true});return 0},
  pwd(a,io){io.out(HOMEP+(this.fs.cwd?'/'+this.fs.cwd:'')+'\n');return 0},
  type(a,io){let st=0;const all=a.includes('-a');
    for(const x of a.filter(v=>v!=='-a'&&v!=='-t')){
      const out=[];if(this.funcs.has(x))out.push(x+' is a function');if(['if','then','else','elif','fi','for','while','until','do','done','case','esac','in','function','[[',']]','{','}','!'].includes(x))out.push(x+' is a shell keyword');
      if(BUILTIN[x])out.push(x+' is a shell builtin');if(EXT[x]||x==='['||x==='test')out.push(x+' is /usr/bin/'+x);if(all&&(x==='['||x==='test'))out.push(x+' is /bin/'+x);
      if(!out.length){this.errl(io,'type: '+x+': not found');st=1;continue}
      io.out((all?out:out.slice(0,1)).join('\n')+'\n')}
    return st},
};
BUILTIN['[']=BUILTIN.test;

/* ================================================================ programs (outside bash) */
const EXT={
  cat(a,io){let show=false,num=false;const files=[];for(const x of a){if(/^-[AEe]+$/.test(x))show=true;else if(x==='-n')num=true;else files.push(x)}
    let st=0;for(const f of this.inputs(files,io,'cat')){if(!f){st=1;continue}let d=f.data;
      if(show)d=d.replace(/\t/g,'^I').replace(/\n/g,'$\n');if(num){let k=0;d=lines(d).map(l=>String(++k).padStart(6)+'\t'+l).join('\n')+'\n'}io.out(d)}
    return st},
  wc(a,io){const fl=a.filter(x=>/^-[lwcm]+$/.test(x)).join(''),files=a.filter(x=>!/^-[lwcm]+$/.test(x));
    const want=fl?['l','w','c'].filter(k=>fl.includes(k)||(k==='c'&&fl.includes('m'))):['l','w','c'];
    const rows=[],tot={l:0,w:0,c:0};let st=0;
    for(const f of this.inputs(files,io,'wc')){if(!f){st=1;continue}const c={l:(f.data.match(/\n/g)||[]).length,w:(f.data.match(/\S+/g)||[]).length,c:unescape(encodeURIComponent(f.data)).length};
      for(const k in tot)tot[k]+=c[k];rows.push([c,f.name])}
    if(files.length>1)rows.push([tot,'total']);
    const wd=want.length===1&&rows.length===1?1:Math.max(1,...rows.map(([c])=>Math.max(...want.map(k=>String(c[k]).length))));
    io.out(rows.map(([c,nm])=>want.map(k=>String(c[k]).padStart(wd)).join(' ')+(nm?' '+nm:'')).join('\n')+(rows.length?'\n':''));return st},
  head(a,io){return this.T.headtail.call(this,a,io,'head')},
  tail(a,io){return this.T.headtail.call(this,a,io,'tail')},
  grep(a,io){let q=false,c=false,v=false,i=false,n=false,w=false,x=false;const rest=[];
    for(const y of a){if(/^-[qcvinwxE]+$/.test(y)){q=q||y.includes('q');c=c||y.includes('c');v=v||y.includes('v');i=i||y.includes('i');n=n||y.includes('n');w=w||y.includes('w');x=x||y.includes('x')}else rest.push(y)}
    if(!rest.length){io.err('Usage: grep [OPTION]... PATTERNS [FILE]...\n');return 2}
    let src=rest[0].replace(/\\([(){}|+?])/g,'$1');if(w)src='\\b(?:'+src+')\\b';if(x)src='^(?:'+src+')$';
    let rx;try{rx=new RegExp(src,i?'i':'')}catch(e){io.err('grep: Unmatched ( or \\(\n');return 2}
    const files=rest.slice(1);let found=false,err=false,out='';
    for(const f of this.inputs(files,io,'grep')){if(!f){err=true;continue}let cnt=0;
      lines(f.data).forEach((l,k)=>{if(rx.test(l)!==v){cnt++;found=true;if(!q&&!c)out+=(files.length>1?f.name+':':'')+(n?(k+1)+':':'')+l+'\n'}});
      if(c&&!q)out+=(files.length>1?f.name+':':'')+cnt+'\n'}
    if(!q)io.out(out);return err&&!(q&&found)?2:found?0:1},
  sort(a,io){const r=a.some(x=>/^-\w*r/.test(x)),nm=a.some(x=>/^-\w*n/.test(x)),u=a.some(x=>/^-\w*u/.test(x));let st=0,all=[];
    for(const f of this.inputs(a.filter(x=>!x.startsWith('-')),io,'sort')){if(!f){st=2;continue}all.push(...lines(f.data))}
    all.sort(nm?(x,y)=>(parseFloat(x)||0)-(parseFloat(y)||0)||cmpName(x,y):cmpName);if(r)all.reverse();if(u)all=all.filter((l,k)=>!k||l!==all[k-1]);
    io.out(all.map(l=>l+'\n').join(''));return st},
  uniq(a,io){const c=a.includes('-c'),d=a.includes('-d');const f=this.inputs(a.filter(x=>!x.startsWith('-')),io,'uniq')[0];if(!f)return 1;
    const out=[];for(const l of lines(f.data)){const p=out[out.length-1];if(p&&p.l===l)p.n++;else out.push({l,n:1})}
    io.out(out.filter(x=>!d||x.n>1).map(x=>(c?String(x.n).padStart(7)+' ':'')+x.l+'\n').join(''));return 0},
  cut(a,io){let d='\t',fl=null;const files=[];for(let i=0;i<a.length;i++){const x=a[i];if(x==='-d')d=a[++i];else if(x.startsWith('-d'))d=x.slice(2);else if(x==='-f')fl=a[++i];else if(x.startsWith('-f'))fl=x.slice(2);else files.push(x)}
    if(!fl){io.err('cut: you must specify a list of bytes, characters, or fields\n');return 1}
    const pick=n=>fl.split(',').some(r=>{const m=/^(\d*)(-?)(\d*)$/.exec(r);if(!m)return false;const lo=+(m[1]||1),hi=m[2]?+(m[3]||1e9):lo;return n>=lo&&n<=hi});
    let st=0;for(const f of this.inputs(files,io,'cut')){if(!f){st=1;continue}io.out(lines(f.data).map(l=>l.includes(d)?l.split(d).filter((x,k)=>pick(k+1)).join(d):l).map(l=>l+'\n').join(''))}return st},
  tr(a,io){const del=a[0]==='-d',s=a.filter(x=>x!=='-d');const ex=t=>(t||'').replace(/(.)-(.)/g,(m,x,y)=>{let r='';for(let c=x.charCodeAt(0);c<=y.charCodeAt(0);c++)r+=String.fromCharCode(c);return r}).replace(/\\n/g,'\n');
    const A=ex(s[0]),B=ex(s[1]);const d=io.in?this.readAll(io.in):'';
    io.out([...d].map(c=>{const k=A.indexOf(c);return k<0?c:del?'':B[Math.min(k,B.length-1)]||''}).join(''));return 0},
  date(a,io){const f=(a.find(x=>x.startsWith('+'))||'+%a %b %d %H:%M:%S EET %Y').slice(1);
    const M={A:'Thursday',a:'Thu',B:'November',b:'Nov',d:'12',e:'12',m:'11',Y:'2026',y:'26',H:'10',M:'00',S:'00',j:'316',u:'4',w:'4',F:'2026-11-12',T:'10:00:00',s:'1794470400','%':'%',n:'\n'};
    io.out(f.replace(/%(.)/g,(m,c)=>M[c]??m)+'\n');return 0},
  seq(a,io){const n=a.filter(x=>!/^-[sw]/.test(x));if(!n.length){io.err("seq: missing operand\nTry 'seq --help' for more information.\n");return 1}
    const bad=n.find(x=>!/^[-+]?\d+(\.\d+)?$/.test(x));if(bad){io.err("seq: invalid floating point argument: ‘"+bad+"’\nTry 'seq --help' for more information.\n");return 1}
    const[f,inc,l]=n.length===1?['1','1',n[0]]:n.length===2?[n[0],'1',n[1]]:n;const F=+f,I=+inc,L=+l;
    if(I===0){io.err("seq: invalid Zero increment value: ‘"+inc+"’\n");return 1}
    const dec=Math.max(...[f,inc].map(x=>(x.split('.')[1]||'').length));let out='';
    for(let v=F,k=0;I>0?v<=L+1e-9:v>=L-1e-9;v=F+(++k)*I){if(k>10000)break;out+=v.toFixed(dec)+'\n'}
    io.out(out);return 0},
  expr(a,io){
    if(!a.length){io.err("expr: missing operand\nTry 'expr --help' for more information.\n");return 2}
    let p=0;const E=m=>{throw{e:m}};const I=s=>/^[-+]?\d+$/.test(s);
    const prim=()=>{if(p>=a.length)E('syntax error: missing argument after ‘'+a[p-1]+'’');const t=a[p++];
      if(t==='('){const v=orE();if(a[p]!==')')E("syntax error: expecting ')' after ‘"+a[p-1]+"’");p++;return v}
      if(t==='length'&&p<a.length)return String(prim().length);return t};
    const mul=()=>{let x=prim();while(['*','/','%'].includes(a[p])){const o=a[p++],y=prim();if(!I(x)||!I(y))E('non-integer argument');const X=BigInt(x),Y=BigInt(y);if((o==='/'||o==='%')&&Y===0n)E('division by zero');x=String(o==='*'?X*Y:o==='/'?X/Y:X%Y)}return x};
    const add=()=>{let x=mul();while(a[p]==='+'||a[p]==='-'){const o=a[p++],y=mul();if(!I(x)||!I(y))E('non-integer argument');x=String(o==='+'?BigInt(x)+BigInt(y):BigInt(x)-BigInt(y))}return x};
    const cmp=()=>{let x=add();while(['<','<=','=','==','!=','>=','>'].includes(a[p])){const o=a[p++],y=add();const c=I(x)&&I(y)?(BigInt(x)<BigInt(y)?-1:BigInt(x)>BigInt(y)?1:0):(x<y?-1:x>y?1:0);
      x={'<':c<0,'<=':c<=0,'=':c===0,'==':c===0,'!=':c!==0,'>=':c>=0,'>':c>0}[o]?'1':'0'}return x};
    const andE=()=>{let x=cmp();while(a[p]==='&'){p++;const y=cmp();x=(x!==''&&x!=='0'&&y!==''&&y!=='0')?x:'0'}return x};
    const orE=()=>{let x=andE();while(a[p]==='|'){p++;const y=andE();x=(x!==''&&x!=='0')?x:(y!==''&&y!=='0')?y:'0'}return x};
    try{const r=orE();if(p<a.length)E('syntax error: unexpected argument ‘'+a[p]+'’');io.out(r+'\n');return r===''||r==='0'?1:0}
    catch(e){if(e.e){io.err('expr: '+e.e+'\n');return 2}throw e}},
  bc(a,io){const lib=a.some(x=>/^-\w*l/.test(x)||x==='--mathlib');const ins=this.inputs(a.filter(x=>!x.startsWith('-')),io,'bc');let st=0;
    for(const f of ins){if(!f){st=1;continue}const r=bcEval(f.data,lib);io.out(r.out);if(r.err){io.err(r.err)}}return st},
  ls(a,io){const files=a.filter(x=>!x.startsWith('-')),long=a.some(x=>/^-\w*l/.test(x));let st=0;const out=[];
    const show=list=>{if(long)out.push(...list.map(([nm,p])=>{const d=this.fs.isDir(p),s=d?4096:(this.fs.read(p)||'').length,x=this.fs.x.has(this.fs.rel(p));return(d?'drwxr-xr-x':x?'-rwxr-xr-x':'-rw-r--r--')+' 1 student student '+String(s).padStart(4)+' Nov 12 10:00 '+nm}));else out.push(io.tty?list.map(x=>x[0]).join('  '):list.map(x=>x[0]).join('\n'))};
    if(!files.length)show(this.fs.list().map(n=>[n,n]));
    for(const f of files){if(this.fs.isDir(f))show(this.fs.list(f).map(n=>[n,f.replace(/\/$/,'')+'/'+n]));else if(this.fs.isFile(f))show([[f,f]]);else{io.err("ls: cannot access '"+f+"': No such file or directory\n");st=2}}
    io.out(out.filter(x=>x!=='').map(x=>x+'\n').join(''));return st},
  touch(a){for(const f of a)if(!f.startsWith('-')&&!this.fs.isFile(f))this.fs.write(f,'');return 0},
  mkdir(a,io){let st=0;for(const d of a.filter(x=>!x.startsWith('-'))){if(this.fs.isDir(d)){if(!a.includes('-p')){io.err("mkdir: cannot create directory ‘"+d+"’: File exists\n");st=1}continue}this.fs.d.add(this.fs.rel(d))}return st},
  cp(a,io){const f=a.filter(x=>!x.startsWith('-'));if(f.length<2){io.err('cp: missing destination file operand\n');return 1}const dst=f.pop();let st=0;
    for(const s of f){const d=this.fs.read(s);if(d==null){io.err("cp: cannot stat '"+s+"': No such file or directory\n");st=1;continue}
      try{this.fs.write(this.fs.isDir(dst)?dst.replace(/\/$/,'')+'/'+s.split('/').pop():dst,d)}catch(e){io.err("cp: cannot create regular file '"+dst+"': No such file or directory\n");st=1}}return st},
  mv(a,io){const r=EXT.cp.call(this,a,io);if(!r)for(const s of a.filter(x=>!x.startsWith('-')).slice(0,-1))this.fs.f.delete(this.fs.rel(s));return r},
  rm(a,io){let st=0;for(const f of a.filter(x=>!x.startsWith('-'))){if(!this.fs.f.delete(this.fs.rel(f))&&!a.some(x=>/^-\w*f/.test(x))){io.err("rm: cannot remove '"+f+"': No such file or directory\n");st=1}}return st},
  chmod(a){const m=a[0]||'';for(const f of a.slice(1)){const r=this.fs.rel(f);if(/\+x|7|5/.test(m))this.fs.x.add(r);else if(/-x/.test(m))this.fs.x.delete(r)}return 0},
  sleep(){return 0},
  whoami(a,io){io.out('student\n');return 0},
  basename(a,io){io.out((a[0]||'').replace(/\/+$/,'').split('/').pop().replace(a[1]&&a[0].endsWith(a[1])?new RegExp(a[1].replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+'$'):/$^/,'')+'\n');return 0},
  dirname(a,io){const p=(a[0]||'').replace(/\/+$/,'');io.out((p.includes('/')?p.slice(0,p.lastIndexOf('/'))||'/':'.')+'\n');return 0},
};
function headtail(a,io,cmd){let n=10;const files=[];
  for(let i=0;i<a.length;i++){const x=a[i];if(x==='-n')n=+a[++i];else if(/^-n\d+$/.test(x))n=+x.slice(2);else if(/^-\d+$/.test(x))n=+x.slice(1);else files.push(x)}
  let st=0;for(const f of this.inputs(files,io,cmd)){if(!f){st=1;continue}const l=lines(f.data);io.out((cmd==='head'?l.slice(0,n):l.slice(Math.max(0,l.length-n))).map(x=>x+'\n').join(''))}return st}

/* ================================================================ the public functions */
function newT(src,o){return{steps:[],term:'',last:0,prev:new Map(),show:new Set(),max:o.maxSteps||500,ops:0,quiet:!!o.quiet,rnd:42,headtail,
  showIFS:/\bIFS\b/.test(src),showPos:/\$\{?[0-9#@*]/.test(src)||!!(o.args&&o.args.length),show0:/\$\{?0/.test(src)}}
function pickFiles(o){if(o.files&&!Array.isArray(o.files))return o.files;const names=o.files||['fruits.txt','notes.txt','words.txt'];const f={};for(const n of names.concat(['/etc/passwd']))if(POOL[n]!=null)f[n]=POOL[n];return f}
/* run a script: {name, args, input (the keyboard), files (names from POOL or {name: text}), maxSteps}
   -> {steps, init, term, status, files, vars, limit} */
function run(src,o={}){
  const T=newT(src,o);const fs=new FS(pickFiles(o));if(o.exec)for(const x of o.exec)fs.x.add(x);
  const sh=new Sh({name:o.name||'./script.sh',args:o.args||[],fs,T,vars:o.vars});
  const kb={data:o.input||'',pos:0,kb:true};
  const io={in:kb,out:s=>{T.term+=s},err:s=>{T.term+='\u0001'+s+'\u0002'},tty:true};
  const prog=parse(src,1);
  const init={};const s0=sh.snap();T.prev=s0;for(const[k,v]of s0)init[k]=v;
  let status=0,limit=false;
  try{status=sh.exec(prog,io)}
  catch(f){if(f instanceof Flow){if(f.kind==='limit'){limit=true;T.term+='\u0001[demo] stopped after '+T.steps.length+' steps: an endless loop?\n\u0002'}else status=f.status}else throw f}
  if(prog.error&&!limit){sh.line=prog.error.line;sh.errl(io,prog.error.message);status=2;try{sh.emit({line:prog.error.line,info:'a syntax error: bash stops here',status:2})}catch(e){}}
  if(T.term.length>T.last&&T.steps.length){const l=T.steps[T.steps.length-1];l.o=(l.o||'')+T.term.slice(T.last);T.last=T.term.length}
  const vars={};for(const[k,v]of sh.snap())vars[k]=v.v;
  return{steps:T.steps,init,term:T.term,status,files:fs.dump(),vars,limit,sh}}
/* one command line typed at the prompt (after a hidden prelude): the words the shell makes and the output */
function line(text,o={}){
  const T=newT(text,o);T.quiet=true;const fs=new FS(pickFiles(o));
  const sh=new Sh({name:'bash',fs,T,inter:true,vars:o.vars});
  const io={in:{data:o.input||'',pos:0,kb:true},out:s=>{T.term+=s},err:s=>{T.term+='\u0001'+s+'\u0002'},tty:true};
  const prog=parse(text,1);
  const chips=[];
  if(!prog.error&&prog.items.length===1){let n=prog.items[0];
    if(n.T==='simple'){try{const c=sh.clone();c.T=Object.assign({},T,{quiet:true,term:''});
        for(const a of n.asg){const v=c.asgVal(a,null);chips.push({t:v.name+'='+v.val,k:'asg'})}
        let first=true;n.words.forEach(w=>c.expand(w,null).forEach(f=>{chips.push({t:f,k:first?'cmd':''});first=false}));
        if(chips.length&&!chips.some(x=>x.k==='cmd')){}
        for(const r of n.redirs){chips.push({t:r.op,k:'redir'});if(r.w)chips.push({t:c.expand(r.w,null,'str'),k:'redir'})}}
      catch(e){}}}
  let status=0;
  try{status=sh.exec(prog,io)}catch(f){if(f instanceof Flow)status=f.status;else throw f}
  if(prog.error){io.err('bash: '+prog.error.message+'\n');status=2}
  return{chips,term:T.term,status,files:fs.dump()}}
/* cut a value at the characters of IFS, like an unquoted $x */
function split(value,ifs){const T=newT('',{});T.quiet=true;const sh=new Sh({fs:new FS({}),T});sh.vars.set('IFS',{v:ifs,x:false});sh.vars.set('x',{v:value,x:false});
  return sh.expand(lex('$x')[0],null)}
/* what read puts in every variable */
function readSplit(lineText,ifs,names,raw){const T=newT('',{});T.quiet=true;const sh=new Sh({fs:new FS({}),T});sh.vars.set('IFS',{v:ifs,x:false});
  BUILTIN.read.call(sh,(raw?['-r']:[]).concat(names),{in:{data:lineText+'\n',pos:0},out:()=>{},err:()=>{}});return names.map(n=>sh.get(n))}
/* $(( expression )) with some variables: {value} or {error} */
function calc(expr,vars){const T=newT('',{});T.quiet=true;const sh=new Sh({fs:new FS({}),T,vars});
  try{const ex=sh.expandText(expr);const v=sh.arith(ex);const after={};for(const k of Object.keys(vars||{}))after[k]=sh.get(k);return{value:String(v),vars:after}}
  catch(e){if(e instanceof BErr)return{error:'bash: '+e.message};throw e}}
function bc(text,lib){return bcEval(text,lib)}
/* the words of a line, quotes removed, nothing expanded (the parameters typed after ./script.sh) */
function words(t){try{return lex(t,1).filter(x=>x.t==='w').map(w=>w.segs.map(g=>g.k==='l'?g.s:g.k==='t'?HOMEP:'').join(''))}catch(e){return t.split(/\s+/).filter(Boolean)}}
/* syntax highlighting of bash, with the hl-* classes of engine.hl */
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const KW=new Set(['if','then','elif','else','fi','for','in','do','done','while','until','case','esac','function','select','time']);
const CMDS=new Set(['echo','printf','read','test','expr','bc','seq','cat','wc','head','tail','grep','date','ls','cp','mv','rm','mkdir','touch','chmod','sort','uniq','cut','tr','local','export','unset','return','exit','break','continue','shift','cd','pwd','type','sleep','true','false','bash','python3','node','env','whoami','basename','dirname']);
function hl(text){
  return text.split('\n').map(l=>{
    let o='',i=0;const n=l.length;let cmdPos=true,asg=false;
    const span=(c,s)=>'<span class="hl-'+c+'">'+esc(s)+'</span>';
    const dollar=j=>{const m=/^\$(?:\{[^}]*\}|\(\(|\(|[A-Za-z_]\w*|[0-9#?@*$!])/.exec(l.slice(j));return m?m[0]:null};
    while(i<n){const c=l[i];
      if(c==='#'&&(i===0||/[\s;]/.test(l[i-1]))){o+=span(l.startsWith('#!')&&i===0?'p':'c',l.slice(i));break}
      if(c==="'"){const e=l.indexOf("'",i+1),j=e<0?n:e+1;o+=span('s',l.slice(i,j));i=j;cmdPos=false;continue}
      if(c==='"'){let j=i+1,buf='"';o+='';const parts=[];
        while(j<n&&l[j]!=='"'){if(l[j]==='\\'){buf+=l.slice(j,j+2);j+=2;continue}
          const d=l[j]==='$'?dollar(j):null;if(d&&!d.endsWith('(')){parts.push(['s',buf]);buf='';parts.push(['v',d]);j+=d.length;continue}buf+=l[j++]}
        buf+=j<n?'"':'';j=Math.min(n,j+1);parts.push(['s',buf]);o+=parts.filter(p=>p[1]).map(p=>span(p[0],p[1])).join('');i=j;cmdPos=false;continue}
      if(c==='$'){const d=dollar(i);if(d){o+=span(d.endsWith('(')?'p':'v',d);i+=d.length;if(d.endsWith('('))cmdPos=!d.endsWith('((');continue}}
      if(cmdPos&&(c==='['||/\d/.test(c))&&(i===0||/[\s;|&(]/.test(l[i-1]))){const w=/^[^\s;|&()<>]+/.exec(l.slice(i))[0];o+=span(w==='[['?'k':'f',w);i+=w.length;cmdPos=false;continue}
      const m=/^[A-Za-z_][\w-]*/.exec(l.slice(i));
      if(m&&(i===0||!/[\w$]/.test(l[i-1]))){const w=m[0];
        if(l[i+w.length]==='='&&/^[A-Za-z_]\w*$/.test(w)){asg=cmdPos;o+=span('v',w);i+=w.length;cmdPos=false;continue}
        if(KW.has(w)&&(cmdPos||w==='in'||w==='do')){o+=span('k',w);i+=w.length;cmdPos=w!=='for'&&w!=='case'&&w!=='in';continue}
        if(cmdPos&&(CMDS.has(w)||/^[a-z_][\w-]*$/.test(w)&&l.slice(i+w.length).startsWith('()'))){o+=span('f',w);i+=w.length;cmdPos=false;continue}
        if(cmdPos&&w)cmdPos=false;
        o+=esc(w);i+=w.length;continue}
      const num=/^\d+/.exec(l.slice(i));
      if(num&&(i===0||/[\s=(,]/.test(l[i-1]))&&/^($|[\s;|&)<>])/.test(l.slice(i+num[0].length))){o+=span('n',num[0]);i+=num[0].length;cmdPos=false;continue}
      if(c===';'||c==='|'||c==='&'||c==='('||c==='{'||c==='`'){cmdPos=true;asg=false;o+=esc(c);i++;continue}
      if(/\s/.test(c)&&asg){cmdPos=true;asg=false}
      if(!/\s/.test(c))cmdPos=c==='!'?cmdPos:false;
      o+=esc(c);i++}
    return o}).join('\n')}
return{run,line,parse,lex,words,split,readSplit,calc,bc,patRx,shq,ifsDesc,hl,POOL,qv};
})();
if(typeof module!=='undefined')module.exports=ISOBASH;
if(typeof window!=='undefined')window.ISOBASH=ISOBASH;
