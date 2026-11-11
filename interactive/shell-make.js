/* ISO demo shell, lecture 07: the project files, a small gcc and a real make (rules, times, $@ $< $^, %.o: %.c) */
(()=>{'use strict';
const S=ISOSH, {split,lookup,pstr,words,writable}=S;
const T='\t';

const HELLO_C=`#include <stdio.h>

#define TIMES 3

int main(void)
{
    // say hello a few times
    for (int i = 0; i < TIMES; i++) {
        printf("Hello, %d!\\n", i);
    }
    return 0;
}
`;
const MAIN_C=`#include "lib.h"
#include "print.h"

int main(void)
{
    int total = sum(MAX);
    print_result("sum", total);
    return 0;
}
`;
const LIB_H=`#ifndef LIB_H
#define LIB_H
#define MAX 10
int sum(int n);
#endif
`;
const LIB_C=`#include "lib.h"

int sum(int n)
{
    int s = 0;
    for (int i = 1; i <= n; i++) {
        s = s + i;
    }
    return s;
}
`;
const PRINT_H=`#ifndef PRINT_H
#define PRINT_H
void print_result(const char *label, int value);
#endif
`;
const PRINT_C=`#include <stdio.h>
#include "print.h"

void print_result(const char *label, int value)
{
    printf("%s = %d\\n", label, value);
}
`;
const MK={
  hello:`hello: hello.o
${T}gcc hello.o -o hello

hello.o: hello.c
${T}gcc -c hello.c
`,
  long:`app: main.o lib.o print.o
${T}gcc main.o lib.o print.o -o app

main.o: main.c
${T}gcc -c main.c

lib.o: lib.c
${T}gcc -c lib.c

print.o: print.c
${T}gcc -c print.c
`,
  auto:`app: main.o lib.o print.o
${T}gcc $^ -o $@

main.o: main.c
${T}gcc -c $< -o $@

lib.o: lib.c
${T}gcc -c $< -o $@

print.o: print.c
${T}gcc -c $< -o $@
`,
  short:`CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o
${T}$(CC) $^ -o $@

%.o: %.c
${T}$(CC) $(CFLAGS) -c $< -o $@
`,
  phony:`CC = gcc
CFLAGS = -Wall -g

.PHONY: all build run clean

all: build

build: app

run: build
${T}./app

app: main.o lib.o print.o
${T}$(CC) $^ -o $@

%.o: %.c
${T}$(CC) $(CFLAGS) -c $< -o $@

clean:
${T}rm -f *.o app
`,
  headers:`CC = gcc
CFLAGS = -Wall -g

app: main.o lib.o print.o
${T}$(CC) $^ -o $@

%.o: %.c
${T}$(CC) $(CFLAGS) -c $< -o $@
`,
};
S.MAKEFILES=MK;
Object.assign(S.MAN,{
  gcc:['gcc - the GNU C compiler (a driver: preprocessor, compiler, assembler, linker)','gcc [OPTION]... FILE...','-o FILE   the name of the output (default a.out)\n-c        stop after the assembler: FILE.o\n-S        stop after the compiler: FILE.s\n-E        stop after the preprocessor (prints, or -o FILE.i)\n-save-temps  keep the .i, .s and .o files\n-Wall     all the warnings\n-g        debug information, for gdb\n-O2       optimize\n-static   copy the libraries into the executable\n-shared   make a shared library (.so)\n-fPIC     code that works at any address\n-I DIR    look for #include files in DIR\n-L DIR    look for libraries in DIR\n-lNAME    link libNAME.so or libNAME.a (-lm: the math library)\n-v        show the programs gcc runs'],
  cc:['cc - the C compiler of the system (here, gcc)','cc [OPTION]... FILE...','the same options as gcc: man gcc'],
  nm:['nm - list the symbols of object files','nm FILE...','T  defined here (in the code, text)\nU  used here, undefined: another file or a library must define it'],
  objdump:['objdump - display information from object files','objdump -d FILE','-d  disassemble: the machine code, as bytes and as assembly'],
  ldd:['ldd - print the shared libraries a program needs','ldd FILE','for every library: where the loader finds it, or "not found"\nLD_LIBRARY_PATH=DIR adds DIR to the folders the loader searches'],
  ar:['ar - create and list archives (static libraries)','ar rcs LIBRARY.a FILE.o...\nar t LIBRARY.a','r  add (replace) the object files\nc  create the archive, without a warning\ns  write an index of the symbols\nt  list the files in the archive'],
  make:['make - build the targets of a Makefile, running only the recipes that are needed','make [OPTION]... [TARGET]...','no TARGET: the first target of the Makefile\n-B          rebuild everything (--always-make)\n-C DIR      run in DIR\n--debug=v   explain every decision (-d)\na target is rebuilt when it is missing or older than one of its prerequisites'],
  pico:['pico - a small text editor (here, the same as nano)','pico FILE','Ctrl+O saves, Ctrl+X exits'],
});
S.PROFILES['07']=(fs,{D,F,t},variant)=>{
  const h=fs.c.home.c.student.c;
  delete h.Downloads; delete h.Movies; delete h['watchlist.txt'];   // only the files of this lecture
  const at=(m)=>t(9,20,10,m);
  h.hello=D({'hello.c':F(HELLO_C,null,at(1)),Makefile:F(MK.hello,null,at(2))},at(2));
  h.project=D({'main.c':F(MAIN_C,null,at(3)),'lib.h':F(LIB_H,null,at(4)),'lib.c':F(LIB_C,null,at(5)),'print.h':F(PRINT_H,null,at(6)),'print.c':F(PRINT_C,null,at(7)),
    Makefile:F(MK[variant]||MK.long,null,at(8))},at(8));
};

/* ---------- gcc: checks the includes, remembers what each object defines and uses ---------- */
const includes=src=>[...src.matchAll(/^\s*#include\s+"([^"]+)"/gm)].map(m=>m[1]);
const defines=src=>Object.fromEntries([...src.matchAll(/^[ \t]*#define[ \t]+(\w+)[ \t]+(\S+)/gm)].map(m=>[m[1],m[2]]));
const KNOWN={printf:'libc',puts:'libc',malloc:'libc',sqrt:'libm'};
function syntaxError(name,src){
  const code=src.replace(/\/\/.*$/gm,'').replace(/"(\\.|[^"\\])*"/g,'""');
  let d=0;for(const ch of code){if(ch==='{')d++;if(ch==='}')d--;if(d<0)return name+": error: expected identifier or '(' before '}' token"}
  if(d>0)return name+": error: expected declaration or statement at end of input";
  return null;
}
function compile(sh,file){                            // -> {obj} or {err}
  const x=sh.get(file);
  if(x.err)return{err:'cc1: fatal error: '+file+': No such file or directory\ncompilation terminated.'};
  let src=x.node.data, defs={};
  const dir=file.includes('/')?file.slice(0,file.lastIndexOf('/')+1):'';
  for(const inc of includes(src)){
    const h=sh.get(dir+inc);
    if(h.err)return{err:file+': fatal error: '+inc+': No such file or directory\ncompilation terminated.'};
    Object.assign(defs,defines(h.node.data));
  }
  Object.assign(defs,defines(src));
  const e=syntaxError(file,src); if(e)return{err:e};
  const body=src.replace(/\/\/.*$/gm,'');
  const defd=[...body.matchAll(/^\s*(?:int|void|char|double|float)\s+\**(\w+)\s*\([^;]*\)\s*\{?\s*$/gm)].map(m=>m[1]);
  const used=[...new Set([...body.matchAll(/\b([a-z_]\w*)\s*\(/g)].map(m=>m[1]).filter(n=>!['if','for','while','return','sizeof','switch','main'].includes(n)&&!defd.includes(n)))];
  return{obj:{src:file,defs,defined:defd,used,text:src}};
}
const STDIO=['extern int printf (const char *__restrict __format, ...);','extern int puts (const char *__s);','typedef struct _IO_FILE FILE;'];
function preprocess(sh,file,src,defs){                // the .i: headers copied in, macros replaced, comments gone
  const dir=file.includes('/')?file.slice(0,file.lastIndexOf('/')+1):'';
  const out=['# 0 "'+file+'"'];
  src.split('\n').forEach((l,i)=>{
    let m=l.match(/^\s*#include\s+<stdio\.h>/);
    if(m){out.push('# 1 "/usr/include/stdio.h"');for(let k=0;k<810;k++)out.push(k<STDIO.length?STDIO[k]:k%7?'extern int __stdio_'+k+' (void);':'');out.push('# '+(i+2)+' "'+file+'"');return}
    m=l.match(/^\s*#include\s+"([^"]+)"/);
    if(m){const h=sh.get(dir+m[1]);out.push('# 1 "'+m[1]+'"');h.node.data.split('\n').forEach(x=>{if(!/^\s*#/.test(x)&&x.trim())out.push(x)});out.push('# '+(i+2)+' "'+file+'"');return}
    if(/^\s*#/.test(l)){out.push('');return}
    l=l.replace(/\/\/.*$/,'');
    for(const[k,v]of Object.entries(defs))l=l.replace(new RegExp('\\b'+k+'\\b','g'),v);
    out.push(l);
  });
  return out.join('\n');
}
function assembly(o){
  const fns=o.defined.map(f=>`${f}:\n    pushq   %rbp\n    movq    %rsp, %rbp\n    ...\n`+o.used.map(u=>`    call    ${u}${KNOWN[u]?'@PLT':''}`).join('\n')+'\n    ...\n    ret');
  return `    .file   "${o.src}"\n    .text\n    .globl  ${o.defined.join(', ')}\n`+fns.join('\n');
}
function c_gcc(args){
  let out=null,mode='link',temps=false,shared=false,stat=false;const ins=[],Ld=[],libs=[];const debug=args.includes('-g');
  for(let i=0;i<args.length;i++){const a=args[i];
    if(a==='-o'){out=args[++i];continue}
    if(a==='-c'){mode='c';continue}if(a==='-E'){mode='E';continue}if(a==='-S'){mode='S';continue}
    if(a==='-save-temps'){temps=true;continue}if(a==='-shared'){shared=true;continue}if(a==='-static'){stat=true;continue}
    if(/^-L/.test(a)){Ld.push(a.slice(2)||args[++i]);continue}
    if(/^-l/.test(a)){libs.push(a.slice(2));continue}
    if(a==='-v')return{err:'Using built-in specs.\nTarget: x86_64-linux-gnu\ngcc version 13.2.0 (demo)\n .../cc1 hello.c -o /tmp/ccA1.s\n as -o /tmp/ccB2.o /tmp/ccA1.s\n .../collect2 ... /tmp/ccB2.o -lc ...'};
    if(/^-(Wall|Wextra|g|O\d|MMD|MD|I.*|std=.*|fPIC)$/.test(a))continue;
    if(a.startsWith('-'))return{err:"gcc: error: unrecognized command-line option '"+a+"'"};
    ins.push(a)}
  if(!ins.length)return{err:'gcc: fatal error: no input files\ncompilation terminated.'};
  if(out&&ins.length>1&&mode!=='link')return{err:'gcc: fatal error: cannot specify -o with -c, -S or -E with multiple files'};
  const base=f=>f.replace(/^.*\//,'').replace(/\.c$/,'');
  const objs=[];let printed=null;
  for(const f of ins){
    if(f.endsWith('.c')){const r=compile(this,f);if(r.err)return{err:r.err};
      const o={kind:'o',debug,...r.obj};
      if(mode==='E'||temps){const txt=preprocess(this,f,this.get(f).node.data,r.obj.defs);if(mode==='E'){if(out)this.writeText(out,txt);else printed=txt;continue}this.writeText(base(f)+'.i',txt)}
      if(mode==='S'||temps){const txt=assembly(o);if(mode==='S'){this.writeText(out||base(f)+'.s',txt);continue}this.writeText(base(f)+'.s',txt)}
      if(mode==='c'||temps){const name=mode==='c'&&out?out:base(f)+'.o';if(!this.writeObj(name,o))return{err:'gcc: cannot write '+name};if(mode==='c')continue}
      objs.push(o)}
    else if(mode!=='link')return{err:'gcc: warning: '+f+': linker input file unused because linking not done'};
    else if(f.endsWith('.o')||f.endsWith('.a')){const x=this.get(f);if(x.err)return{err:'/usr/bin/ld: cannot find '+f+': No such file or directory\ncollect2: error: ld returned 1 exit status'};
      if(!x.node.meta)return{err:'/usr/bin/ld: '+f+': file format not recognized; treating as linker script\ncollect2: error: ld returned 1 exit status'};
      if(x.node.meta.kind==='a')objs.push(...x.node.meta.objs);else objs.push(x.node.meta)}
    else if(f.endsWith('.h'))continue;
    else return{err:"/usr/bin/ld: "+f+": file format not recognized\ncollect2: error: ld returned 1 exit status"};
  }
  if(mode!=='link')return printed!=null?{out:printed}:{};
  // the libraries named with -l: libNAME.so first, then libNAME.a, in the -L folders
  const sos=[];
  for(const l of libs){
    if(l==='m'||l==='c')continue;
    let found=null;
    for(const d of Ld.concat(['/usr/lib'])){for(const ext of stat?['.a']:['.so','.a']){const x=this.get(d.replace(/\/$/,'')+'/lib'+l+ext);if(x.node&&x.node.meta){found={x,ext,path:pstr(x.real)};break}}if(found)break}
    if(!found)return{err:'/usr/bin/ld: cannot find -l'+l+': No such file or directory\ncollect2: error: ld returned 1 exit status'};
    if(found.ext==='.a')objs.push(...found.x.node.meta.objs);else{sos.push({name:'lib'+l+'.so',path:found.path});objs.push(...found.x.node.meta.objs.map(o=>({...o,fromSo:'lib'+l+'.so'})))}
  }
  const defd=new Set(objs.flatMap(o=>o.defined));
  const undef=[...new Set(objs.flatMap(o=>o.used.filter(u=>!defd.has(u)&&!(KNOWN[u]==='libc'||KNOWN[u]==='libm'&&libs.includes('m')))))];
  if(shared){const name=out||'a.out';this.writeObj(name,{kind:'so',objs});return{}}
  if(!defd.has('main'))return{err:"/usr/bin/ld: /usr/lib/x86_64-linux-gnu/Scrt1.o: in function `_start':\n(.text+0x1b): undefined reference to `main'\ncollect2: error: ld returned 1 exit status"};
  if(undef.length){const o=objs.find(o=>o.used.includes(undef[0]));return{err:'/usr/bin/ld: '+o.src.replace(/\.c$/,'.o')+': in function `'+(o.defined[0]||'main')+"':\n"+o.src+':(.text+0x12): undefined reference to `'+undef[0]+"'\ncollect2: error: ld returned 1 exit status"}}
  const name=out||'a.out';
  this.writeObj(name,{kind:'exe',objs:objs.filter(o=>!o.fromSo),sos,stat,debug:debug||objs.some(o=>o.debug)});
  return{};
}
S.Shell.prototype.writeText=function(name,text){
  const parts=split(this.cwd,name), par=lookup(this.root,parts.slice(0,-1));
  if(!par.node||par.node.t!=='d'||!writable(par.real.concat(parts[parts.length-1])))return false;
  par.node.c[parts[parts.length-1]]=S.F(text+'\n',null,S.now());par.node.m=S.now();return true;
};
/* the tools around gcc: nm, objdump, ldd, ar */
const elf=(sh,f,cmd)=>{const x=sh.get(f);if(x.err)return{err:cmd+": '"+f+"': No such file"};if(!x.node.meta)return{err:cmd+': '+f+': file format not recognized'};return{m:x.node.meta}};
S.Shell.prototype.c_nm=function(args){
  const out=[];
  for(const f of args){const r=elf(this,f,'nm');if(r.err)return r;const m=r.m;
    const objs=m.kind==='o'?[m]:m.objs;
    const def=objs.flatMap(o=>o.defined), use=[...new Set(objs.flatMap(o=>o.used))].filter(u=>!def.includes(u));
    if(args.length>1)out.push('\n'+f+':');
    if(m.kind==='a')objs.forEach(o=>{out.push('\n'+o.src.replace(/\.c$/,'.o')+':');o.defined.forEach(d=>out.push('0000000000000000 T '+d));o.used.filter(u=>!o.defined.includes(u)).forEach(u=>out.push('                 U '+u))});
    else{const rows=def.map((d,i)=>[d,(m.kind==='o'?i*0x20:0x1149+i*0x30).toString(16).padStart(16,'0')+' T '+d]).concat(use.map(u=>[u,'                 U '+u+(m.kind==='exe'&&KNOWN[u]?'@GLIBC_2.34':'')]));
      rows.sort((a,b)=>a[0]<b[0]?-1:1).forEach(r=>out.push(r[1]))}
  }
  return{out:out.join('\n').replace(/^\n/,'')};
};
S.Shell.prototype.c_objdump=function(args){
  const f=args.filter(a=>!a.startsWith('-'))[0];if(!args.includes('-d')||!f)return{err:'Usage: objdump -d FILE (this demo shows the disassembly only)'};
  const r=elf(this,f,'objdump');if(r.err)return r;const o=r.m.kind==='o'?r.m:r.m.objs[0];
  return{out:'\n'+f+':     file format elf64-x86-64\n\nDisassembly of section .text:\n\n'+o.defined.map(d=>'0000000000000000 <'+d+'>:\n   0: 55                    push   %rbp\n   1: 48 89 e5              mov    %rsp,%rbp\n  ...\n'+o.used.map((u,i)=>'  '+(0x29+i*8).toString(16)+': e8 00 00 00 00        call   '+(r.m.kind==='o'?'...   # '+u+': filled in by the linker':u+'@plt')).join('\n')).join('\n\n')};
};
S.Shell.prototype.c_ldd=function(args){
  const f=args[0];if(!f)return{err:'ldd: missing file arguments'};
  const x=this.get(f);if(x.err)return{err:'ldd: '+f+': No such file or directory'};
  const m=x.node.meta;if(!m||m.kind==='o'||m.kind==='a')return{err:'\tnot a dynamic executable',code:1};
  if(m.stat)return{out:'\tnot a dynamic executable',code:1};
  const lp=(this.env&&this.env.LD_LIBRARY_PATH||'').split(':').filter(Boolean);
  const so=(m.sos||[]).map(s=>{const d=lp.map(p=>this.get(p.replace(/\/$/,'')+'/'+s.name)).find(r=>r.node);return '\t'+s.name+' => '+(d?pstr(d.real):'not found')});
  return{out:['\tlinux-vdso.so.1 (0x00007ffd3c1e0000)'].concat(so,['\tlibc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f3a1bc00000)','\t/lib64/ld-linux-x86-64.so.2 (0x00007f3a1c2e0000)']).join('\n')};
};
S.Shell.prototype.c_ar=function(args){
  const op=args[0]||'',lib=args[1],files=args.slice(2);
  if(!lib)return{err:'Usage: ar rcs LIBRARY.a FILE.o...   ar t LIBRARY.a'};
  if(/t/.test(op)){const r=elf(this,lib,'ar');if(r.err)return r;return{out:r.m.objs.map(o=>o.src.replace(/^.*\//,'').replace(/\.c$/,'.o')).join('\n')}}
  if(!/r/.test(op))return{err:'ar: this demo knows ar rcs and ar t'};
  const objs=[];for(const f of files){const r=elf(this,f,'ar');if(r.err)return{err:'ar: '+f+': No such file or directory'};objs.push(r.m)}
  this.writeObj(lib,{kind:'a',objs});return{};
};
S.Shell.prototype.writeObj=function(name,meta){
  const parts=split(this.cwd,name), par=lookup(this.root,parts.slice(0,-1));
  if(!par.node||par.node.t!=='d'||!writable(par.real.concat(parts[parts.length-1])))return false;
  const size={exe:meta.stat?651320:16800,o:1720,a:1880,so:15560}[meta.kind];
  const n=S.F('\x7fELF (demo '+meta.kind+')',size,S.now());
  n.meta=meta; n.exe=meta.kind==='exe';
  par.node.c[parts[parts.length-1]]=n; par.node.m=S.now(); return true;
};
S.Shell.prototype.c_gcc=c_gcc; S.Shell.prototype.c_cc=c_gcc;
S.Shell.prototype.c_pico=function(a){return this.c_nano(a)};
/* run an executable made by gcc */
S.Shell.prototype.runFile=function(cmd){
  const x=this.get(cmd);
  if(x.err)return{err:'bash: '+cmd+': '+x.err,code:127};
  if(x.node.t==='d')return{err:'bash: '+cmd+': Is a directory',code:126};
  if(!x.node.exe)return{err:'bash: '+cmd+': Permission denied',code:126};
  const lp=(this.env&&this.env.LD_LIBRARY_PATH||'').split(':').filter(Boolean);
  for(const so of x.node.meta.sos||[])if(!lp.some(p=>this.get(p.replace(/\/$/,'')+'/'+so.name).node))return{err:cmd+': error while loading shared libraries: '+so.name+': cannot open shared object file: No such file or directory',code:127};
  const objs=x.node.meta.objs, m=objs.find(o=>o.defined.includes('main'));
  if(/printf\("Hello/.test(m.text)){const n=parseInt(m.defs.TIMES||'3',10);return{out:Array.from({length:n},(_,i)=>'Hello, '+i+'!').join('\n')}}
  if(/sum\(MAX\)/.test(m.text)){const n=parseInt(m.defs.MAX,10);const label=(m.text.match(/print_result\("([^"]*)"/)||[,'sum'])[1];return{out:label+' = '+(n*(n+1)/2)}}
  return{out:''};
};

/* ---------- make ---------- */
function parse(text){
  const vars={},rules=[],phony=new Set();let cur=null,err=null;
  text.split('\n').forEach((l,i)=>{
    const n=i+1;
    if(err)return;
    if(l.startsWith('\t')){if(!cur){err='Makefile:'+n+': *** recipe commences before first target.  Stop.';return}cur.recipe.push({line:l.slice(1),n});return}
    const t=l.replace(/#.*$/,'');
    if(!t.trim()){return}
    if(/^\s+\S/.test(l)&&cur&&!/[:=]/.test(t)){err='Makefile:'+n+': *** missing separator.  Stop.';return}
    let m=t.match(/^\s*([A-Za-z_]\w*)\s*[:?]?=\s*(.*)$/);
    if(m&&!/^\s*[^=]*:[^=]/.test(t.replace(/:=/,'='))){vars[m[1]]=m[2].trim();cur=null;return}
    if(/^\s*-?include\b/.test(t)){cur=null;return}
    m=t.match(/^([^:]+):(.*)$/);
    if(m){const tg=m[1].trim().split(/\s+/), pre=m[2].trim().split(/\s+/).filter(Boolean);
      if(tg[0]==='.PHONY'){pre.forEach(p=>phony.add(p));cur=null;return}
      cur={targets:tg,pre,recipe:[],n};rules.push(cur);return}
    err='Makefile:'+n+': *** missing separator.  Stop.';
  });
  return{vars,rules,phony,err};
}
function expand(s,vars,auto){
  for(let k=0;k<10&&/\$\(/.test(s);k++)s=s.replace(/\$\((\w+)\)/g,(_,v)=>vars[v]!=null?vars[v]:'');
  return s.replace(/\$([@<^])/g,(_,c)=>auto[c]||'');
}
S.Shell.prototype.c_make=function(args){
  let always=false,verbose=false,dir=null;const goals=[];
  for(let i=0;i<args.length;i++){const a=args[i];if(a==='-B'||a==='--always-make')always=true;else if(a==='--debug=v'||a==='-d')verbose=true;else if(a==='-C')dir=args[++i];else if(a.startsWith('-'))return{err:'make: invalid option -- '+a.replace(/^-+/,'')};else goals.push(a)}
  const old=this.cwd; if(dir){const x=this.get(dir);if(x.err||x.node.t!=='d')return{err:'make: *** '+dir+': No such file or directory.  Stop.'};this.cwd=x.real}
  try{
  const mf=this.get('Makefile');
  if(mf.err)return{err:'make: *** No targets specified and no makefile found.  Stop.',code:2};
  const P=parse(mf.node.data); if(P.err)return{err:P.err,code:2};
  const seq=[], log=(t)=>verbose&&seq.push({out:t});
  const explicit=t=>P.rules.filter(r=>r.targets.includes(t));
  const pattern=t=>{for(const r of P.rules){const tp=r.targets[0];if(!tp.includes('%'))continue;const re=new RegExp('^'+tp.replace('.','\\.').replace('%','(.+)')+'$');const m=t.match(re);if(!m)continue;const pre=r.pre.map(p=>p.replace('%',m[1]));if(pre.every(p=>this.get(p).node||explicit(p).length))return{rule:r,pre}}return null};
  const mtime=f=>{const x=this.get(f);return x.node?x.node.m:null};
  const done=new Map();let ran=0,fail=null;
  const build=(t,depth,parent)=>{
    if(fail)return;
    if(done.has(t))return;
    const ind=' '.repeat(depth);
    log(ind+"Considering target file '"+t+"'.");
    const ex=explicit(t); let recipe=null, pre=[];
    ex.forEach(r=>{pre.push(...r.pre);if(r.recipe.length)recipe=r});
    let rule=recipe;
    if(!recipe&&!P.phony.has(t)){const p=pattern(t);if(p){pre=p.pre.concat(pre);rule={recipe:p.rule.recipe,n:p.rule.n,pre:p.pre}}}
    pre=[...new Set(pre)];
    if(!ex.length&&!rule){
      if(this.get(t).node){log(ind+' No need to remake target \''+t+"'.");done.set(t,false);return}
      fail="make: *** No rule to make target '"+t+"'"+(parent?", needed by '"+parent+"'":'')+".  Stop.";return}
    for(const p of pre){build(p,depth+1,t);if(fail)return}
    log(ind+" Finished prerequisites of target file '"+t+"'.");
    const tm=mtime(t), isPh=P.phony.has(t);
    const newer=pre.filter(p=>tm!=null&&mtime(p)!=null&&mtime(p)>tm);
    const need=always||isPh||tm==null||newer.length||pre.some(p=>done.get(p)&&P.phony.has(p)===false&&tm!=null&&mtime(p)>tm);
    if(!need){log(ind+" No need to remake target '"+t+"'.");done.set(t,false);return}
    log(ind+(tm==null&&!isPh?" File '"+t+"' does not exist.":isPh?" Target '"+t+"' is phony.":" Prerequisite '"+newer[0]+"' is newer than target '"+t+"'."));
    log(ind+"Must remake target '"+t+"'.");
    const auto={'@':t,'<':pre[0]||'','^':pre.join(' ')};
    for(const r of (rule?rule.recipe:[])){
      const line=expand(r.line,P.vars,auto);
      seq.push({out:line.replace(/^@/,'')});
      const res=this.exec(line.replace(/^[@-]/,''));
      for(const x of res.seq){if(x.out!=null)seq.push({out:x.out});if(x.err)seq.push({err:x.err})}
      const bad=res.seq.some(x=>x.err&&!/warning/.test(x.err));
      if(bad){fail='make: *** [Makefile:'+r.n+': '+t+'] Error 1';return}
      ran++;
    }
    if(rule&&!rule.recipe.length&&!isPh){}
    log(ind+"Successfully remade target file '"+t+"'.");
    done.set(t,true);
  };
  const first=P.rules.find(r=>!r.targets[0].includes('%')&&!r.targets[0].startsWith('.'));
  const gl=goals.length?goals:first?[first.targets[0]]:[];
  if(!gl.length)return{err:'make: *** No targets.  Stop.',code:2};
  for(const g of gl){
    const before=ran;build(g,0,null);
    if(fail){seq.push({err:fail});return{seq,code:2}}
    if(ran===before&&!P.phony.has(g))seq.push({out:"make: '"+g+"' is up to date."});
    else if(ran===before)seq.push({out:"make: Nothing to be done for '"+g+"'."});
  }
  return{seq};
  }finally{this.cwd=old}
};
})();
