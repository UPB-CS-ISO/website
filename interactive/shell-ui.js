/* ISO sandbox widgets: the mini shell (data-w="shell") and a real Linux in v86 (data-w="linux") */
(()=>{'use strict';
const {Shell,lookup,paths,clone,HOME,sortNames}=ISOSH;
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const el=h=>{const d=document.createElement('div');d.innerHTML=h.trim();return d.firstChild};

/* ---------- missions for the sandbox chapter ---------- */
const has=(sh,p)=>!!lookup(sh.root,ISOSH.split(HOME,p)).node;
const isDir=(sh,p)=>{const n=lookup(sh.root,ISOSH.split(HOME,p)).node;return!!n&&n.t==='d'};
const at=(sh,p)=>'/'+sh.cwd.join('/')===p;                       // the current directory is p
const isFile=(sh,p)=>{const n=lookup(sh.root,ISOSH.split(HOME,p)).node;return!!n&&n.t==='f'};
const rel=c=>c.split(/\s+/).slice(1).filter(a=>!a.startsWith('-')).every(a=>!/^[\/~]/.test(a));  // only relative paths
const MSETS={
  pwd:[
    {t:'Go to <code>Downloads</code> and print where you are.',h:'cd, then pwd',ok:(sh,c,o)=>/^pwd/.test(c)&&/^\/home\/student\/Downloads$/m.test(o)},
    {t:'Go to <code>/var/log</code>, then come back home with a <code>cd</code> that has no parameter.',h:'cd /var/log, then cd',ok:(sh,c)=>c==='cd'&&sh.old&&sh.old.join('/')==='var/log'},
    {t:'Return to <code>/var/log</code> without typing its path.',h:'cd -',ok:(sh,c)=>/^cd\s+-$/.test(c)&&at(sh,'/var/log')},
  ],
  ls:[
    {t:'Show the hidden files of your home directory.',h:'an option of ls',ok:(sh,c,o)=>/^ls\b.*-\w*a/.test(c)&&/\.bashrc/.test(o)},
    {t:'Show the size of <code>the_odyssey.mkv</code> in G, not in bytes.',h:'two options: long listing, human-readable',ok:(sh,c,o)=>/-\w*l/.test(c)&&/-\w*h/.test(c)&&/\d(\.\d)?G .*the_odyssey/.test(o)},
    {t:'List <code>/etc</code> and <code>Downloads</code> with <b>one</b> command.',h:'ls takes several FILE parameters',ok:(sh,c,o)=>/^ls\b/.test(c)&&/passwd/.test(o)&&/michael\.mp4/.test(o)},
  ],
  tree:[
    {t:'Show only the directories of your home.',h:'an option of tree',ok:(sh,c,o)=>/^tree\b.*-d/.test(c)&&!/watchlist/.test(o)&&/Movies/.test(o)},
    {t:'Show one level of the root <code>/</code>.',h:'-L and a path',ok:(sh,c,o)=>/^tree\b/.test(c)&&/-L\s*1/.test(c)&&/── usr/.test(o)&&!/── share/.test(o)},
    {t:'Show the tree of your home with the hidden files.',h:'-a',ok:(sh,c,o)=>/^tree\b/.test(c)&&/\.bashrc/.test(o)},
  ],
  find:[
    {t:'Find every <code>.mp4</code> file in your home.',h:'-name, with quotes',ok:(sh,c,o)=>/^find\b/.test(c)&&/supergirl\.mp4/.test(o)&&/michael\.mp4/.test(o)&&!/watchlist/.test(o)},
    {t:'List only the directories in your home.',h:'-type d',ok:(sh,c,o)=>/^find\b.*-type\s+d/.test(c)&&/Movies/.test(o)&&!/\.mkv/.test(o)},
    {t:'Find where the file <code>passwd</code> is, searching the whole tree.',h:'start from /',ok:(sh,c,o)=>/^find\s+\//.test(c)&&/\/etc\/passwd/.test(o)},
  ],
  cp:[
    {t:'Make a copy of <code>watchlist.txt</code> called <code>watchlist_old.txt</code>, in the same directory.',h:'cp SOURCE DEST',ok:sh=>isFile(sh,'~/watchlist_old.txt')&&isFile(sh,'~/watchlist.txt')},
    {t:'Copy the whole <code>Movies</code> directory to <code>/tmp</code>.',h:'cp needs an option for directories',ok:sh=>isFile(sh,'/tmp/Movies/the_odyssey.mkv')},
    {t:'Copy both <code>.mp4</code> files into <code>Movies</code> with one command.',h:'several sources, the last parameter is the directory',ok:sh=>isFile(sh,'~/Movies/supergirl.mp4')&&isFile(sh,'~/Movies/michael.mp4')&&isFile(sh,'~/Downloads/michael.mp4')},
  ],
  mv:[
    {t:'Rename <code>watchlist.txt</code> to <code>todo.txt</code>.',h:'renaming is moving',ok:sh=>isFile(sh,'~/todo.txt')&&!has(sh,'~/watchlist.txt')},
    {t:'Move <code>todo.txt</code> into <code>Downloads</code>.',h:'DEST is a directory',ok:sh=>isFile(sh,'~/Downloads/todo.txt')},
    {t:'Rename the directory <code>Downloads</code> to <code>Inbox</code>.',h:'mv works on directories without options',ok:sh=>isFile(sh,'~/Inbox/michael.mp4')&&!has(sh,'~/Downloads')},
  ],
  create:[
    {t:'Create <code>~/Projects/iso/lab02</code> with one command.',h:'mkdir -p',ok:sh=>isDir(sh,'~/Projects/iso/lab02')},
    {t:'Create an empty file <code>notes.txt</code> inside it.',h:'touch',ok:sh=>{const n=lookup(sh.root,ISOSH.split(HOME,'~/Projects/iso/lab02/notes.txt')).node;return!!n&&n.t==='f'}},
    {t:'Write your name in <code>~/name.txt</code> with <code>nano</code>, and save it.',h:'nano name.txt, Ctrl+O, Ctrl+X',ok:sh=>{const n=lookup(sh.root,ISOSH.split(HOME,'~/name.txt')).node;return!!n&&n.t==='f'&&n.data.trim().length>0}},
  ],
  rm:[
    {t:'Delete <code>watchlist.txt</code>.',h:'rm FILE',ok:sh=>!has(sh,'~/watchlist.txt')},
    {t:'Delete both <code>.mp4</code> files with one command, but keep <code>Downloads</code>.',h:'a * pattern',ok:sh=>isDir(sh,'~/Downloads')&&!has(sh,'~/Downloads/michael.mp4')&&!has(sh,'~/Downloads/supergirl.mp4')},
    {t:'Delete the now empty <code>Downloads</code> with the command that only removes empty directories.',h:'rmdir',ok:(sh,c)=>/^rmdir\b/.test(c)&&!has(sh,'~/Downloads')},
    {t:'Delete <code>Movies</code> and everything inside it.',h:'rm with an option',ok:sh=>!has(sh,'~/Movies')},
  ],
};
const fdTo=(sh,fd,re)=>(sh.procs||[]).some(p=>p.fds.some(f=>f.fd===fd&&re.test(f.to)));
const data=(sh,p)=>{const n=lookup(sh.root,ISOSH.split(HOME,p)).node;return n&&n.t==='f'?n.data:null};
Object.assign(MSETS,{
  fd:[
    {t:'Make <code>sort</code> open <code>fruits.txt</code> by itself, as an argument; watch index <code>3</code> in the table.',h:'sort FILE',ok:sh=>fdTo(sh,3,/fruits\.txt$/)},
    {t:'Count the lines of <code>fruits.txt</code> with <code>wc</code>, giving it the file name.',h:'wc -l FILE',ok:(sh,c,o)=>/^3 fruits\.txt$/m.test(o)},
    {t:'Look at the File Descriptor Table of a process, in <code>/proc</code>.',h:'ls -l /proc/self/fd',ok:(sh,c,o)=>/proc\/self\/fd/.test(c)&&/-> \/dev\/pts\/0/.test(o)},
  ],
  'redir-in':[
    {t:'Sort <code>fruits.txt</code> with the file as <code>stdin</code>, not as an argument.',h:'<',ok:sh=>fdTo(sh,0,/fruits\.txt$/)},
    {t:'Count the lines of <code>unsorted.txt</code> so that <code>wc</code> prints only the number.',h:'wc -l reads stdin, it does not know the name',ok:(sh,c,o)=>/^wc\b/.test(c)&&/^\s*5$/m.test(o)},
  ],
  'redir-out':[
    {t:'Save the listing of <code>/etc</code> into <code>etc.txt</code>.',h:'>',ok:sh=>/passwd/.test(data(sh,'~/etc.txt')||'')},
    {t:'Add a second line to <code>log.txt</code> without deleting the first one.',h:'echo one > log.txt, then >>',ok:(sh,c)=>/>>/.test(c)&&(data(sh,'~/log.txt')||'').trim().split('\n').length>=2},
    {t:'Run <code>ls /etc /nope</code> and keep only its <b>errors</b> in <code>errors.txt</code>.',h:'2>',ok:sh=>{const d=data(sh,'~/errors.txt')||'';return/cannot access/.test(d)&&!/passwd/.test(d)}},
    {t:'Run it again with <b>both</b> the output and the errors in <code>all.txt</code>.',h:'> all.txt 2>&1, or &>',ok:sh=>{const d=data(sh,'~/all.txt')||'';return/cannot access/.test(d)&&/passwd/.test(d)}},
  ],
  pipe:[
    {t:'Count the entries of <code>/etc</code> with a pipe.',h:'ls DIR | wc -l',ok:(sh,c,o)=>/\|/.test(c)&&/^\s*3$/m.test(o)},
    {t:'Print the lines of <code>unsorted.txt</code> sorted, each one only once.',h:'sort | uniq (or sort -u)',ok:(sh,c,o)=>/\|/.test(c)&&/^apple\nfig\nkiwi\npear$/m.test(o)},
    {t:'Print only the first 2 fruits, in alphabetical order.',h:'sort | head',ok:(sh,c,o)=>/\|/.test(c)&&/^apple\nbanana\n?$/.test(o)},
  ],
  dev:[
    {t:'Run <code>ls /nope</code> without seeing the error.',h:'send stderr to the black hole',ok:sh=>fdTo(sh,2,/^\/dev\/null$/)},
    {t:'Show 16 random bytes.',h:'xxd -l and /dev/urandom',ok:(sh,c,o)=>/urandom/.test(c)&&/16/.test(c)&&/^00000000: /m.test(o)},
    {t:'Check with <code>ls -l</code> that <code>/dev/zero</code> is a character device.',h:'the first letter is c',ok:(sh,c,o)=>/^crw.*zero/m.test(o)},
  ],
  links:[
    {t:'Make a soft link <code>shortcut.txt</code> to <code>notes.txt</code> and print through it.',h:'ln -s TARGET LINK_NAME, then cat',ok:(sh,c,o)=>/^cat\b.*shortcut/.test(c)&&/buy milk/.test(o)},
    {t:'Make a link <code>docs</code> to <code>/usr/share/doc</code> and list the folder through it.',h:'ln -s /usr/share/doc docs; ls docs/',ok:(sh,c,o)=>/^ls\b.*docs/.test(c)&&/bash/.test(o)&&/git/.test(o)},
    {t:'Make a link in <code>backup/</code> that works and points to <code>~/notes.txt</code>, with a <b>relative</b> path.',h:'relative to the folder of the link: ../notes.txt',ok:sh=>{const b=lookup(sh.root,ISOSH.split(HOME,'~/backup')).node, n=lookup(sh.root,ISOSH.split(HOME,'~/notes.txt')).node;return!!b&&b.t==='d'&&!!n&&Object.entries(b.c).some(([k,v])=>v.t==='l'&&!v.target.startsWith('/')&&lookup(sh.root,ISOSH.split(HOME,'~/backup/'+k)).node===n)}},
    {t:'Delete <code>notes.txt</code> and see that <code>shortcut.txt</code> is now broken.',h:'rm, then cat the link',ok:(sh,c,o)=>/^cat\b.*shortcut/.test(c)&&!has(sh,'~/notes.txt')},
  ],
  proc:[
    {t:'Print the PID of the shell.',h:'$$',ok:(sh,c,o)=>/^4100$/m.test(o)},
    {t:'Show that the parent of <code>cat</code> is the shell.',h:'cat /proc/self/status: PPid',ok:(sh,c,o)=>/PPid:\s+4100/.test(o)&&/Name:\s+cat/.test(o)},
    {t:'Print the executable that <code>readlink</code> was loaded from, using <code>/proc</code>.',h:'readlink /proc/self/exe',ok:(sh,c,o)=>/^\/usr\/bin\/readlink$/m.test(o)},
    {t:'Find the zombie process with <code>ps</code>.',h:'ps -e -o pid,stat,comm, look for Z',ok:(sh,c,o)=>/^ps\b/.test(c)&&/ Z .*myapp-worker/.test(o)},
  ],
});
const hist=(sh,re)=>sh.hist.some(h=>re.test(h));
const fdata=(sh,p)=>{const n=lookup(sh.root,ISOSH.split(sh.cwd,p)).node;return n&&n.t==='f'?n.data:''};
Object.assign(MSETS,{
  'mk-hello':[
    {t:'Build <code>hello</code> with <code>make</code>.',h:'make',ok:(sh,c,o)=>/^make\b/.test(c)&&/gcc hello\.o -o hello/.test(o)},
    {t:'Run <code>make</code> again: nothing to do.',h:'make',ok:(sh,c,o)=>/'hello' is up to date/.test(o)},
    {t:'Make <code>hello.c</code> newer with <code>touch</code>, then <code>make</code>.',h:'touch hello.c',ok:(sh,c,o)=>hist(sh,/^touch\s+hello\.c/)&&/^make\b/.test(c)&&/gcc -c hello\.c/.test(o)},
    {t:'Change <code>TIMES</code> to <code>5</code> with <code>pico hello.c</code>, rebuild and run <code>./hello</code>.',h:'pico, Ctrl+O, Ctrl+X, make, ./hello',ok:(sh,c,o)=>/Hello, 4!/.test(o)},
  ],
  'mk-run':[
    {t:'Build the project: four commands.',h:'make',ok:(sh,c,o)=>/^make\b/.test(c)&&/gcc -c main\.c/.test(o)&&/-o app/.test(o)},
    {t:'<code>touch print.c</code>, then <code>make</code>: only two commands run.',h:'main.o and lib.o are still newer than their sources',ok:(sh,c,o)=>hist(sh,/^touch\s+print\.c/)&&/^make\s*$/.test(c)&&/gcc -c print\.c/.test(o)&&!/gcc -c (main|lib)\.c/.test(o)},
    {t:'Build only <code>lib.o</code>, by naming the target.',h:'make TARGET',ok:(sh,c)=>/^make\s+lib\.o\s*$/.test(c)},
    {t:'Ask <code>make</code> to explain its decisions.',h:'make --debug=v (after a touch)',ok:(sh,c,o)=>/--debug=v/.test(c)&&/Must remake/.test(o)},
  ],
  'mk-short':[
    {t:'Look at the short <code>Makefile</code>.',h:'cat',ok:(sh,c,o)=>/^cat\b.*Makefile/.test(c)&&/%\.o: %\.c/.test(o)},
    {t:'Build: see how <code>$(CC)</code>, <code>$&lt;</code> and <code>$@</code> were filled in.',h:'make',ok:(sh,c,o)=>/gcc -Wall -g -c main\.c -o main\.o/.test(o)},
    {t:'Add <code>-O2</code> to <code>CFLAGS</code> with <code>pico Makefile</code>, then rebuild everything.',h:'make -B: the Makefile is not a prerequisite',ok:(sh,c,o)=>/-O2/.test(o)&&/gcc .*-c/.test(o)},
  ],
  'mk-phony':[
    {t:'Build and run the program with one target.',h:'make run',ok:(sh,c,o)=>/^make\s+run/.test(c)&&/sum = /.test(o)},
    {t:'Delete everything that was built.',h:'make clean',ok:(sh,c,o)=>/rm -f \*\.o app/.test(o)},
    {t:'Create a file named <code>clean</code>; check that <code>make clean</code> still works.',h:'.PHONY protects it',ok:(sh,c,o)=>hist(sh,/^touch\s+clean/)&&/rm -f/.test(o)},
  ],
  'mk-headers':[
    {t:'Build, then set <code>MAX</code> to <code>100</code> in <code>lib.h</code> (<code>pico lib.h</code>) and run <code>make</code>.',h:'make says up to date: the bug',ok:(sh,c,o)=>/#define MAX 100\b/.test(fdata(sh,'lib.h'))&&/up to date/.test(o)},
    {t:'Run <code>./app</code>: it still prints 55.',h:'main.o was compiled with MAX 10',ok:(sh,c,o)=>/#define MAX 100\b/.test(fdata(sh,'lib.h'))&&/sum = 55$/m.test(o)},
    {t:'Add the header lines to the <code>Makefile</code>, <code>make</code>, and get 5050.',h:'main.o: lib.h print.h / lib.o: lib.h / print.o: print.h',ok:(sh,c,o)=>/sum = 5050/.test(o)},
  ],
});
const ex=(sh,p)=>!!lookup(sh.root,ISOSH.split(sh.cwd,p)).node;
Object.assign(MSETS,{
  'cc-pipe':[
    {t:'Compile <code>hello.c</code> into <code>hello</code> with one <code>gcc</code> command, and run it.',h:'gcc hello.c -o hello, then ./hello',ok:(sh,c,o)=>/^\.\/hello$/.test(c)&&/Hello, 2!/.test(o)&&hist(sh,/^gcc\b.*hello\.c/)},
    {t:'Stop after the <b>preprocessor</b>: make <code>hello.i</code>, and count its lines.',h:'gcc -E hello.c -o hello.i, then wc -l',ok:(sh,c,o)=>ex(sh,'hello.i')&&/^wc\b/.test(c)&&/hello\.i/.test(o)},
    {t:'Stop after the <b>compiler</b>: make the assembly file <code>hello.s</code>.',h:'gcc -S',ok:sh=>ex(sh,'hello.s')},
    {t:'Stop after the <b>assembler</b>: make <code>hello.o</code> and list what it defines and what it needs.',h:'gcc -c, then nm hello.o',ok:(sh,c,o)=>/^nm\b/.test(c)&&/U printf/.test(o)},
    {t:'<b>Link</b> <code>hello.o</code> and check the type of the result with <code>file</code>.',h:'gcc hello.o -o hello; file hello',ok:(sh,c,o)=>/^file\b/.test(c)&&/pie executable/.test(o)},
    {t:'Build a <b>static</b> <code>hello-static</code> and compare its size with <code>hello</code>.',h:'gcc -static hello.o -o hello-static; ls -lh',ok:(sh,c,o)=>/^ls\b/.test(c)&&/637K .*hello-static|hello-static/.test(o)&&/637K/.test(o)},
  ],
  'cc-files':[
    {t:'Compile each <code>.c</code> of the project to its own <code>.o</code>.',h:'gcc -c, three times',ok:sh=>['main.o','lib.o','print.o'].every(f=>ex(sh,f))},
    {t:'Link the three object files into <code>app</code> and run it.',h:'gcc main.o lib.o print.o -o app; ./app',ok:(sh,c,o)=>/^\.\/app$/.test(c)&&/sum = 55/.test(o)},
    {t:'Get a <b>linker</b> error: leave <code>lib.o</code> out of the link.',h:'gcc main.o print.o -o app',ok:(sh,c,o)=>/undefined reference to `sum'/.test(o)},
    {t:'Change the label <code>"sum"</code> to <code>"total"</code> in <code>main.c</code> (<code>pico</code>), rebuild only what is needed, and run.',h:'gcc -c main.c, then link again',ok:(sh,c,o)=>/total = 55/.test(o)},
  ],
  'cc-libs':[
    {t:'Put <code>lib.o</code> in a static library <code>libsum.a</code>, link <code>app</code> with <code>-lsum</code>, and run it.',h:'compile first; ar rcs libsum.a lib.o; gcc main.o print.o -L. -lsum -o app',ok:(sh,c,o)=>ex(sh,'libsum.a')&&/^\.\/app/.test(c)&&/sum = 55/.test(o)},
    {t:'Make a shared library <code>libsum.so</code>, link <code>app</code> with it and look at what <code>app</code> needs.',h:'gcc -shared lib.o -o libsum.so; link; ldd app',ok:(sh,c,o)=>ex(sh,'libsum.so')&&/^ldd\b/.test(c)&&/libsum\.so =>/.test(o)},
    {t:'Run the program that needs <code>libsum.so</code>, telling the loader where to find it.',h:'LD_LIBRARY_PATH=. ./app',ok:(sh,c,o)=>/LD_LIBRARY_PATH=/.test(c)&&/sum = 55/.test(o)},
  ],
});
const MISSIONS=MSETS.sandbox=[
  {t:'Go to <code>~/Movies</code> with a <b>relative</b> path, then print where you are.',h:'cd Movies, then pwd',ok:(sh,c)=>sh.cwd.join('/')==='home/student/Movies'&&/^pwd\b/.test(c)},
  {t:'From <code>~/Movies</code>, show the content of <code>~/watchlist.txt</code> without leaving the directory.',h:'cat ../watchlist.txt',ok:(sh,c,o)=>sh.cwd.join('/')==='home/student/Movies'&&/^cat\b/.test(c)&&/Project Hail Mary/.test(o)},
  {t:'Create the directory <code>~/backup</code> and copy <code>watchlist.txt</code> into it.',h:'mkdir ~/backup, then cp ~/watchlist.txt ~/backup/',ok:sh=>has(sh,'~/backup/watchlist.txt')&&has(sh,'~/watchlist.txt')},
  {t:'Copy the whole <code>Movies</code> directory into <code>~/backup</code>.',h:'cp needs -r for a directory',ok:sh=>has(sh,'~/backup/Movies/the_odyssey.mkv')},
  {t:'Make <code>~/Movies/2026/animation</code> with <b>one</b> command.',h:'mkdir -p',ok:(sh,c)=>isDir(sh,'~/Movies/2026/animation')&&/^mkdir\b.*-p/.test(c)},
  {t:'Move both <code>.mp4</code> files from <code>~/Downloads</code> into <code>~/Movies</code>, with one command.',h:'mv ~/Downloads/*.mp4 ~/Movies/',ok:sh=>has(sh,'~/Movies/supergirl.mp4')&&has(sh,'~/Movies/michael.mp4')&&!has(sh,'~/Downloads/supergirl.mp4')&&!has(sh,'~/Downloads/michael.mp4')},
  {t:'Rename <code>~/Movies/michael.mp4</code> to <code>michael_2026.mp4</code>.',h:'mv, same directory, new name',ok:sh=>has(sh,'~/Movies/michael_2026.mp4')&&!has(sh,'~/Movies/michael.mp4')},
  {t:'List every <code>.mkv</code> file under your home, with absolute paths.',h:'find ~ -name "*.mkv"',ok:(sh,c,o)=>/^find\b/.test(c)&&/\/home\/student\/(backup\/)?Movies\/the_odyssey\.mkv/.test(o)},
  {t:'Delete <code>~/backup</code> and everything inside it.',h:'rmdir refuses, rm needs -r',ok:(sh,c)=>!has(sh,'~/backup')&&/^rm\b/.test(c)},
];


/* ---------- syntax highlighting: C, Makefiles, JSON (shared by the widgets) ---------- */
const hesc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const htok=(text,rules)=>{const big=new RegExp(rules.map(([r],i)=>'(?<g'+i+'>'+r+')').join('|'),'gm');let out='',pos=0,m;
  while((m=big.exec(text))){if(!m[0]){big.lastIndex++;continue}out+=hesc(text.slice(pos,m.index));const i=+Object.keys(m.groups).find(k=>m.groups[k]!==undefined).slice(1);const c=rules[i][1];out+=c?'<span class="hl-'+c+'">'+hesc(m[0])+'</span>':hesc(m[0]);pos=m.index+m[0].length}
  return out+hesc(text.slice(pos))};
const HLR={
  c:[[String.raw`//[^\n]*|/\*[\s\S]*?\*/`,'c'],[String.raw`"(?:\\.|[^"\\\n])*"|<[\w./]+\.h>`,'s'],[String.raw`^[ \t]*#[ \t]*\w+`,'p'],[String.raw`\b(?:int|void|char|double|float|long|unsigned|const|static|struct|return|for|while|if|else|extern|sizeof)\b`,'k'],[String.raw`\b\d+\b`,'n'],[String.raw`\b[A-Za-z_]\w*(?=\s*\()`,'f']],
  json:[[String.raw`"(?:\\.|[^"\\])*"(?=\s*:)`,'t'],[String.raw`"(?:\\.|[^"\\])*"`,'s'],[String.raw`\b\d[\d.]*\b|\btrue\b|\bfalse\b`,'n']],
  asm:[[String.raw`#[^\n]*`,'c'],[String.raw`^[.\w]+:`,'t'],[String.raw`\$\w+|%\w+`,'n'],[String.raw`^\s+[a-z]+`,'k'],[String.raw`[\w.]+@PLT`,'f']],
  mkv:[[String.raw`\$\([^)]*\)`,'v'],[String.raw`\$[@<^*?]`,'a'],['%','a']],
};
function hlMake(text){
  return text.split('\n').map(l=>{
    if(l.startsWith('\t')){const m=l.slice(1).match(/^(@?\S+)([\s\S]*)$/);if(!m)return l;return '\t'+(/^\$/.test(m[1])?htok(m[1],HLR.mkv):'<span class="hl-f">'+hesc(m[1])+'</span>')+htok(m[2],HLR.mkv)}
    const c=l.indexOf('#'),code=c>=0?l.slice(0,c):l,com=c>=0?'<span class="hl-c">'+hesc(l.slice(c))+'</span>':'';
    let m=code.match(/^(\s*)([A-Za-z_]\w*)(\s*[:?+]?=)([\s\S]*)$/);
    if(m)return m[1]+'<span class="hl-v">'+m[2]+'</span>'+hesc(m[3])+htok(m[4],HLR.mkv)+com;
    m=code.match(/^(-?include)(\b[\s\S]*)$/);if(m)return '<span class="hl-p">'+m[1]+'</span>'+htok(m[2],HLR.mkv)+com;
    m=code.match(/^([^:=\s#][^:=]*?)(\s*:)([^=][\s\S]*|)$/);
    if(m)return(m[1].startsWith('.')?'<span class="hl-p">'+hesc(m[1])+'</span>':'<span class="hl-t">'+htok(m[1],HLR.mkv).replace(/^/,'')+'</span>')+hesc(m[2])+'<span class="hl-q">'+htok(m[3],HLR.mkv)+'</span>'+com;
    return hesc(code)+com}).join('\n');
}
const ISOHL=(t,lang)=>lang==='make'?hlMake(t):HLR[lang]?htok(t,HLR[lang]):hesc(t);
window.ISOHL=ISOHL;

/* ---------- the tree next to the terminal ---------- */
function treeHTML(before,after,sh,mode,hidden){
  const base=mode==='home'?HOME:[], cwd=sh.cwd.join('/');
  const pb=paths(before), pa=paths(after);
  const changed=[];for(const[k,v]of pa)if(pb.get(k)!==v)changed.push(k);for(const k of pb.keys())if(!pa.has(k))changed.push(k);
  const get=(r,parts)=>lookup(r,parts).node;
  const lines=[];
  const rootLabel=mode==='home'?'~ (/home/student)':'/';
  lines.push(`<span class="${cwd===base.join('/')?'h':''}">${esc(rootLabel)}${cwd===base.join('/')?' <i class="cwd">📍</i>':''}</span>`);
  const open=p=>mode==='home'||p.split('/').length<=1||('/'+cwd).startsWith('/'+p+'/')||'/'+cwd==='/'+p||changed.some(c=>c.startsWith('/'+p+'/'))||p.startsWith('home/student');
  const rec=(b,a,parts,pre)=>{
    const names=sortNames([...new Set([...Object.keys(b&&b.t==='d'?b.c:{}),...Object.keys(a&&a.t==='d'?a.c:{})])].filter(n=>hidden||!n.startsWith('.')));
    names.forEach((n,i)=>{
      const last=i===names.length-1, p=parts.concat(n), key='/'+p.join('/');
      const nb=b&&b.t==='d'?b.c[n]:null, na=a&&a.t==='d'?a.c[n]:null, node=na||nb;
      let cls='', mark='';
      if(!nb){cls='n';mark=' +'}else if(!na){cls='g';mark=' −'}else if(pb.get(key)!==pa.get(key)&&node.t==='f'){cls='m'}
      const here=p.join('/')===cwd;
      const name=esc(n)+(node.t==='d'?'/':'')+(node.t==='l'?'</b><span class="ln"> -> '+esc(node.target)+'</span><b>':'');
      lines.push(`<span class="${cls}${here?' h':''}">${pre}${last?'└── ':'├── '}<b>${name}</b>${mark}${here?' <i class="cwd">📍</i>':''}</span>`);
      if(node.t==='d'){
        if(open(p.join('/')))rec(nb,na,p,pre+(last?'    ':'│   '));
        else if(Object.keys(node.c).length)lines.push(`<span class="dim">${pre}${last?'    ':'│   '}└── …</span>`);
      }
    });
  };
  rec(get(before,base),get(after,base),base,'');
  return lines.join('\n');
}

function wShell(root){
  const sh=new Shell({cwd:root.dataset.cwd||'~',profile:root.dataset.profile,variant:root.dataset.variant});sh.color=true;
  let side=root.dataset.side||'tree', lastProcs=null;
  const cmds=(root.dataset.cmds||'').split('|').filter(Boolean);
  const MS=Object.assign({},MSETS,window.ISO_MSETS||{});
  const mset=root.dataset.missions?(MS[root.dataset.missions==='1'?'sandbox':root.dataset.missions]||[]):[], withMissions=mset.length>0;
  const ext=(window.ISO_SIDE||{})[root.dataset.side];     // a side panel given by another script (git, lecture 07)
  const title=root.dataset.title||'Sandbox: a shell in the page';
  let mode=root.dataset.view||'home', hidden=false, before=clone(sh.root), hist=[], hpos=0, done=new Set();
  const sub=root.dataset.sub||'A terminal simulated in this page, not a real Linux: only the commands of the lectures work. Break things freely, <code>reset</code> starts again.';
  root.innerHTML=`<div class="wd shellw${ext?' extw':''}"><div class="wd-h"><div><h3>${title}</h3><p>${sub}</p></div><span class="badge" data-r="badge">bash</span></div>
  ${cmds.length?`<div class="ctrls cmdchips"><span class="chl">try:</span>${cmds.map(c=>`<button type="button" class="chip" data-c="${esc(c)}">${esc(c)}</button>`).join('')}</div>`:''}
  <div class="wd-b sb${ext?' ext':''}"><div class="tcol"><div class="tbar"><i></i><i></i><i></i><span data-r="ttl"></span><b class="demo">DEMO</b></div><div class="term" data-r="term"><div class="tout" data-r="out"></div><div class="tline" data-r="line"><span class="pr" data-r="pr"></span><input data-r="in" autocomplete="off" autocapitalize="off" spellcheck="false" aria-label="command"></div></div></div>
  <div class="trcol">${ext?'<div class="extp" data-r="ext"></div>':`${sh.profile==='03'?'':'<!--'}<div class="seg sidetab" data-seg="side"><button type="button" data-v="tree" class="${side==='tree'?'on':''}">files</button><button type="button" data-v="fd" class="${side==='fd'?'on':''}">file descriptors</button></div>${sh.profile==='03'?'':'-->'}<div class="fdview" data-r="fdv"></div><div class="trwrap" data-r="trw"><div class="trbar"><div class="seg" data-seg="view"><button type="button" data-v="home" class="${mode==='home'?'on':''}">~</button><button type="button" data-v="root" class="${mode==='root'?'on':''}">/</button></div><label class="hid"><input type="checkbox" data-r="hid"> hidden files</label></div><pre class="tree live" data-r="tree"></pre>
  <div class="tleg"><span><i class="cwd">📍</i> current directory</span><span class="n">+ created</span><span class="g">− removed</span><span class="m">changed</span></div></div>`}</div></div>
  ${withMissions?`<div class="missions"><div class="mh"><b>Missions</b> <span data-r="mcount"></span>${cmds.length?'<em class="mnote">type them yourself, the buttons above are only examples</em>':''}</div><ol data-r="ml">${mset.map((m,i)=>`<li data-i="${i}"><span class="mt">${m.t}</span> <details><summary>hint</summary>${esc(m.h)}</details></li>`).join('')}</ol></div>`:''}
  <div class="wd-f">Tab completes a name, ↑ ↓ bring back the previous commands, <code>help</code> lists the commands, <code>man cp</code> shows a short manual page.</div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const out=q('out'), inp=q('in'), term=q('term');
  const phtml=()=>{const p=sh.prompt(),i=p.indexOf(':');return `<span class="pu">${esc(p.slice(0,i))}</span>:<span class="pp">${esc(p.slice(i+1,-1))}</span>$`};
  const out2=t=>esc(t).replace(/\u0001/g,'<span class="dir">').replace(/\u0003/g,'<span class="lnk">').replace(/\u0004/g,'<span class="dev">').replace(/\u0006/g,'<span class="gr">').replace(/\u0007/g,'<span class="rd">').replace(/\u000e/g,'<span class="yl">').replace(/\u0002/g,'</span>');
  const print=(html,cls)=>{out.insertAdjacentHTML('beforeend',`<div class="${cls||''}">${html}</div>`);term.scrollTop=term.scrollHeight};
  const prompt=()=>{q('pr').innerHTML=phtml();q('ttl').textContent=sh.prompt().slice(0,-1)+' (demo)'};
  const fdName=(f)=>f.kind==='tty'?(f.fd===0?'keyboard':f.fd===1?'display':'error display')+' <i>(terminal)</i>':f.kind==='pipe'?(f.fd===0?'pipe (read end)':'pipe (write end)'):esc(f.to);
  const std=['stdin','stdout','stderr'];
  const fdHTML=()=>{
    const ps=lastProcs&&lastProcs.length?lastProcs:null;
    const box=(title,rows)=>`<div class="fdp"><div class="fdh">${title}</div><table class="fdt">${rows.map(f=>`<tr class="${f.changed?'ch':''}${f.opened?' op':''}"><td>${f.fd}</td><td>${f.fd<3?std[f.fd]:'opened'}</td><td>→ ${fdName(f)}</td></tr>`).join('')}</table></div>`;
    if(!ps)return box('bash · PID 4100 <span>(the shell)</span>',[0,1,2].map(fd=>({fd,kind:'tty'})))+'<p class="fdhint">Run a command: its File Descriptor Table shows up here, the changed entries highlighted.</p>';
    return ps.map((p,i)=>(i?'<div class="pipeline">│ pipe: stdout above → stdin below ▼</div>':'')+box(`<b>${esc(p.cmd)}</b> · PID ${p.pid}`,p.fds)).join('');
  };
  const api={print:(h,c)=>print(h,c||''),draw:()=>draw()};
  const draw=()=>{if(ext)ext.draw(sh,q('ext'),api);else{q('tree').innerHTML=treeHTML(before,sh.root,sh,mode,hidden);q('fdv').innerHTML=fdHTML();q('fdv').hidden=side!=='fd';q('trw').hidden=side!=='tree'}prompt()};
  const mcheck=(c,o)=>{if(!withMissions)return;
    mset.forEach((m,i)=>{if(!done.has(i)&&m.ok(sh,c,o)){done.add(i)}});
    root.querySelectorAll('[data-r="ml"] li').forEach(li=>li.classList.toggle('ok',done.has(+li.dataset.i)));
    q('mcount').textContent=done.size+' / '+mset.length;
    const b=q('badge');b.textContent=done.size===mset.length?'all missions done':done.size+' / '+mset.length+' missions';b.className='badge'+(done.size===mset.length?' ok':'');
  };
  function exec(c,chip){
    print(`<span class="pr">${phtml()}</span> ${esc(c)}`,'cmd');
    if(c.trim()){hist.push(c);}
    hpos=hist.length;
    const snap=clone(sh.root);
    const r=sh.run(c);
    if(r.clear)out.innerHTML='';
    let text='';
    for(const x of r.seq){if(x.out){print(x.hl?ISOHL(x.out,x.hl):out2(x.out));text+=x.out.replace(/[\u0001-\u0007\u000e]/g,'')+'\n'}if(x.err){print(out2(x.err),'err');text+=x.err.replace(/[\u0001-\u0007\u000e]/g,'')+'\n'}if(x.note)print(esc(x.note),'dim')}
    if(r.procs&&r.procs.length)lastProcs=r.procs.filter(p=>p.cmd);
    const ps=paths(snap),pa=paths(sh.root);
    if(ps.size!==pa.size||[...pa].some(([k,v])=>ps.get(k)!==v))before=snap;   // keep the last change visible
    if(c.trim()==='reset'){before=clone(sh.root);done.clear()}
    draw();if(!chip)mcheck(c.trim(),text);   // the example buttons do not solve missions
    if(r.edit)nano(r.edit);
  }
  function nano(e){
    const base=e.name.replace(/^.*\//,''), lang=/^(GNU)?[Mm]akefile$/.test(base)?'make':/\.[ch]$/.test(base)?'c':/\.json$/.test(base)?'json':null;
    const box=el(`<div class="nano"><div class="nbar">GNU nano (demo) &nbsp; ${esc(e.name)}${e.ro?' [read only]':''}</div><div class="nedit"><pre class="nhl" aria-hidden="true"></pre><textarea spellcheck="false"></textarea></div><div class="nbar nk"><b>^O</b> Write Out &nbsp; <b>^X</b> Exit <span data-n="st"></span></div></div>`);
    const ta=box.querySelector('textarea'), st=box.querySelector('[data-n="st"]'), hp=box.querySelector('.nhl');
    const paint=()=>{hp.innerHTML=(lang?ISOHL(ta.value,lang):hesc(ta.value))+'\n';hp.scrollTop=ta.scrollTop;hp.scrollLeft=ta.scrollLeft};
    ta.addEventListener('input',paint);ta.addEventListener('scroll',()=>{hp.scrollTop=ta.scrollTop;hp.scrollLeft=ta.scrollLeft});
    ta.value=e.text; let saved=e.text, ask=false; paint();
    term.hidden=true; term.parentNode.appendChild(box); ta.focus();
    const close=()=>{box.remove();term.hidden=false;inp.focus();before=clone(sh.root);draw();mcheck('','')};
    ta.addEventListener('keydown',k=>{
      if(ask){k.preventDefault();if(/^[yY]$/.test(k.key)){if(!e.ro){const b=clone(sh.root);sh.save(e.parts,ta.value);before=b}box.remove();term.hidden=false;inp.focus();draw();mcheck('','')}else if(/^[nN]$/.test(k.key))close();else if(k.key==='Escape'){ask=false;st.textContent=''}return}
      if(k.key==='Tab'){k.preventDefault();const p=ta.selectionStart;ta.value=ta.value.slice(0,p)+'\t'+ta.value.slice(ta.selectionEnd);ta.selectionStart=ta.selectionEnd=p+1;paint();return}
      if(k.ctrlKey&&(k.key==='o'||k.key==='O')){k.preventDefault();if(e.ro){st.textContent='  [ Permission denied ]';return}const b=clone(sh.root);sh.save(e.parts,ta.value);saved=ta.value;st.textContent='  [ Wrote '+ta.value.split('\n').length+' lines ]';before=b;draw();mcheck('','')}
      else if(k.ctrlKey&&(k.key==='x'||k.key==='X')){k.preventDefault();if(ta.value!==saved){ask=true;st.textContent='  Save modified buffer? Y / N'}else close()}
    });
  }
  inp.addEventListener('keydown',e=>{
    if(e.key==='Enter'){e.preventDefault();const c=inp.value;inp.value='';exec(c)}
    else if(e.key==='ArrowUp'){e.preventDefault();if(hpos>0){hpos--;inp.value=hist[hpos]}}
    else if(e.key==='ArrowDown'){e.preventDefault();if(hpos<hist.length-1){hpos++;inp.value=hist[hpos]}else{hpos=hist.length;inp.value=''}}
    else if(e.key==='l'&&e.ctrlKey){e.preventDefault();out.innerHTML=''}
    else if(e.key==='Tab'){e.preventDefault();
      const v=inp.value, i=v.search(/\S*$/), w=v.slice(i), m=sh.complete(w);
      if(m.length===1)inp.value=v.slice(0,i)+m[0]+(m[0].endsWith('/')?'':' ');
      else if(m.length>1){let p=m[0];for(const x of m)while(!x.startsWith(p))p=p.slice(0,-1);
        if(p.length>w.length)inp.value=v.slice(0,i)+p;else{print(`<span class="pr">${phtml()}</span> ${esc(v)}`,'cmd');print(esc(m.map(x=>x.slice(x.lastIndexOf('/',x.length-2)+1)).join('  ')))}}
    }
  });
  term.addEventListener('click',()=>{if(!getSelection().toString())inp.focus({preventScroll:true})});
  root.querySelectorAll('.chip').forEach(b=>b.addEventListener('click',()=>{exec(b.dataset.c,true);inp.focus({preventScroll:true})}));
  root.querySelectorAll('[data-seg="side"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="side"] button').forEach(x=>x.classList.toggle('on',x===b));side=b.dataset.v;draw()}));
  root.querySelectorAll('[data-seg="view"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-seg="view"] button').forEach(x=>x.classList.toggle('on',x===b));mode=b.dataset.v;draw()}));
  if(!ext)q('hid').addEventListener('change',e=>{hidden=e.target.checked;draw()});
  print('<span class="dim">Demo terminal, simulated in your browser: nothing runs on a real computer.\nType a command and press Enter. Try <b>help</b>.</span>');
  draw();mcheck('','');
}

/* ---------- a real Linux, emulated by v86 ---------- */
/* everything comes from public CDNs, nothing is deployed with the site:
   the emulator from npm (jsDelivr), the BIOS from the v86 repository (jsDelivr),
   the Buildroot kernel from the image server of the v86 author (i.copy.sh, the one copy.sh/v86 uses) */
const V86CFG=Object.assign({
  lib:'https://cdn.jsdelivr.net/npm/v86@0.5.471/build/libv86.js',
  wasm:'https://cdn.jsdelivr.net/npm/v86@0.5.471/build/v86.wasm',
  bios:'https://cdn.jsdelivr.net/gh/copy/v86@0.5/bios/seabios.bin',
  vga:'https://cdn.jsdelivr.net/gh/copy/v86@0.5/bios/vgabios.bin',
  bzimage:'https://i.copy.sh/buildroot-bzimage68.bin',
},window.ISO_V86||{});
const SEED='mkdir -p ~/Downloads ~/Movies && echo "Project Hail Mary" > ~/watchlist.txt && touch ~/Downloads/supergirl.mp4 ~/Downloads/michael.mp4 ~/Movies/the_odyssey.mkv && cd ~ && clear && ls -l\n';
function wLinux(root){
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>A real Linux in the page</h3><p>The <a href="https://github.com/copy/v86" target="_blank" rel="noopener">v86</a> emulator boots a small Buildroot Linux in your browser. Same commands, real coreutils (BusyBox), nothing is installed.</p></div><span class="badge off" data-r="st">off</span></div>
  <div class="ctrls"><button type="button" class="btn" data-r="boot">Boot Linux <span aria-hidden="true">→</span></button><button type="button" class="btn ghost" data-r="seed" disabled>Create the lecture files</button><span class="small" data-r="msg">≈ 12 MB download from public servers, about 10 s to boot. Click the screen before typing.</span></div>
  <div class="v86s" data-r="scr" hidden><div class="v86t"></div><canvas hidden></canvas></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  let emu=null, started=false;
  const st=(t,c)=>{const b=q('st');b.textContent=t;b.className='badge '+(c||'')};
  const fail=m=>{st('error','bad');q('msg').textContent='Could not start: '+m}
  q('boot').addEventListener('click',async()=>{
    if(emu)return; q('boot').disabled=true; st('loading','warn');
    try{
      if(!window.V86)await new Promise((ok,ko)=>{const s=document.createElement('script');s.src=V86CFG.lib;s.onload=ok;s.onerror=()=>ko(new Error('could not load the emulator ('+V86CFG.lib+')'));document.head.appendChild(s)});
      q('scr').hidden=false;
      emu=new window.V86({wasm_path:V86CFG.wasm,memory_size:64*1024*1024,vga_memory_size:2*1024*1024,screen_container:q('scr'),
        bios:{url:V86CFG.bios},vga_bios:{url:V86CFG.vga},bzimage:{url:V86CFG.bzimage},cmdline:'tsc=reliable mitigations=off random.trust_cpu=on',autostart:true});
      q('msg').textContent='Downloading…';
      emu.add_listener('download-progress',e=>{if(!started&&e.lengthComputable&&e.total)q('msg').textContent='Downloading '+(e.file_name||'').replace(/^.*\//,'')+' · '+Math.round(100*e.loaded/e.total)+' %'});
      emu.add_listener('download-error',e=>fail('the download of '+e.file_name+' failed. Check the internet connection and try again (reload the page).'));
      emu.add_listener('emulator-started',()=>{started=true;st('running','ok');q('msg').textContent='Booting… log in as root when asked (no password).';q('seed').disabled=false});
      setTimeout(()=>{if(!started)fail('nothing arrived in 60 s. A public server may be down or blocked on this network; reload the page to try again.')},60000);
    }catch(e){fail(e.message);q('boot').disabled=false}
  });
  q('seed').addEventListener('click',()=>{if(emu){emu.keyboard_send_text(SEED);q('scr').focus()}});
}

const W=window.DK_W||(window.DK_W={});
W.shell=wShell; W.linux=wLinux;
})();
