/* ISO lecture 08 widgets (Shell Scripting); the interpreter is bashrun.js (window.ISOBASH)
   - data-w="dbg"    the debugger of the slides: a script, the line that runs, the command after the expansions,
                     the exit code, the variables and the output, step by step (data-d: JSON, one or more scenarios)
   - data-w="lab"    the script lab: edit a script, run it or step through it, missions (window.ISO_LABS)
   - data-w="split"  IFS: how an unquoted $x, a quoted "$x" and read cut a value
   - data-w="pit"    "the shell sees the words": a pitfall, the words bash makes, the terminal (+ try your own line)
   - data-w="runsc"  ./backup.sh and bash backup.sh: shell, kernel and bash, step by step
   - data-w="subst"  $(command): the copy of bash, the captured output, the line that runs
   - data-w="globs"  case patterns: which pattern matches a word, which branch case picks
   - data-w="calc"   $(( )) and bc on the same expression */
(()=>{'use strict';
const B=window.ISOBASH;
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const md=s=>String(s||'').split(/(`[^`]+`)/).map((x,i)=>i%2?'<code>'+esc(x.slice(1,-1))+'</code>':esc(x).replace(/\[\[(.+?)\]\]/g,'<kbd>$1</kbd>').replace(/\*\*(.+?)\*\*/g,'<b>$1</b>').replace(/(^|[^\w*])\*(?!\s)(.+?)\*(?!\w)/g,'$1<em>$2</em>')).join('');
const hl=t=>B?B.hl(t):esc(t);
/* bash highlighting for window.ISOHL(text,'bash'), the other languages unchanged */
if(window.ISOHL&&!window.ISOHL.bash08){const old=window.ISOHL;window.ISOHL=(t,l)=>l==='bash'||l==='sh'?hl(t):old(t,l);window.ISOHL.bash08=true}
const term=t=>esc(t).replace(/\u0001/g,'<span class="db-err">').replace(/\u0002/g,'</span>');
const plain=t=>String(t||'').replace(/[\u0001\u0002]/g,'');
const NAV=(dots=true)=>`<div class="ps-nav"><button type="button" class="btn ghost" data-r="prev">← Back</button>${dots?'<span class="pdots" data-r="dots" aria-hidden="true"></span>':''}<button type="button" class="btn" data-r="next">Next →</button></div>`;
function stepper(root,count,draw){
  let i=0;const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=k=>{i=Math.max(0,Math.min(count()-1,k));draw(i);
    const d=q('dots'),n=count();if(d){d.innerHTML=n<=14?Array.from({length:n},(_,k)=>`<i class="${k===i?'on':k<i?'dn':''}"></i>`).join(''):`<span class="pcount">${i+1} / ${n}</span>`}
    q('prev').disabled=i===0;q('next').disabled=i===n-1};
  q('prev').addEventListener('click',()=>go(i-1));
  q('next').addEventListener('click',()=>go(i+1));
  return go}
const chipsHTML=ws=>ws.map(([t,k])=>`<span class="w8 ${k||''}">${t===''?'<i>""</i>':esc(t).replace(/\n/g,'<i>\\n</i>')}</span>`).join('');

/* ================================================================ the debugger */
function stateAt(sc,i){
  const vars=new Map(),tags=new Map();
  for(const[k,v]of Object.entries(sc.init||{})){vars.set(k,v&&typeof v==='object'?v.v:v);if(v&&v.tag)tags.set(k,v.tag)}
  let out='',cur='';const changed=new Set(),gone=new Set();
  for(let k=0;k<=i&&k<sc.steps.length;k++){const s=sc.steps[k];
    for(const n of s.unset||[]){if(k===i)gone.add(n);else{vars.delete(n);tags.delete(n)}}
    for(const[n,v]of Object.entries(s.vars||{})){vars.set(n,v);if(k===i)changed.add(n)}
    for(const[n,t]of Object.entries(s.tags||{})){if(t==null)tags.delete(n);else tags.set(n,t);if(k===i)changed.add(n)}
    const o=s.o!=null?s.o:'';if(k===i)cur=o;else out+=o}
  return{vars,tags,changed,gone,out,cur}}
/* a line of the script with some pieces marked: {t: text found from the left, or s/e: positions, c: class};
   the dotted frames (db-exp: what bash replaces) may sit inside the other marks */
function markLine(line,marks){
  const outer=[],inner=[];
  for(const m of marks){let r=null;
    if(m.s!=null)r={s:m.s,e:m.e,c:m.c};
    else if(m.t){const list=m.c==='db-exp'?inner:outer;let from=0,at;while((at=line.indexOf(m.t,from))>=0){if(!list.some(x=>at<x.e&&at+m.t.length>x.s)){r={s:at,e:at+m.t.length,c:m.c};break}from=at+1}}
    if(!r)continue;const list=r.c==='db-exp'?inner:outer;if(!list.some(x=>r.s<x.e&&r.e>x.s))list.push(r)}
  outer.sort((x,y)=>x.s-y.s);inner.sort((x,y)=>x.s-y.s);
  const seg=(a,b)=>{let o='',p=a;for(const r of inner){if(r.s<a||r.e>b)continue;o+=hl(line.slice(p,r.s))+'<mark class="db-exp">'+hl(line.slice(r.s,r.e))+'</mark>';p=r.e}return o+hl(line.slice(p,b))};
  let o='',p=0;
  for(const r of outer){o+=seg(p,r.s)+`<mark class="${r.c}">${seg(r.s,r.e)}</mark>`;p=r.e}
  return o+seg(p,line.length)}
function codeHTML(sc,s){
  const lines=sc.code.split('\n');
  return lines.map((l,k)=>{const n=k+1,cur=s&&s.line===n;let marks=[];
    if(cur){[].concat(s.part||[]).forEach(t=>marks.push({t,c:'db-part'}));if(s.compute)marks.push({t:s.compute,c:'db-cmp'});[].concat(s.expand||[]).forEach(t=>marks.push({t,c:'db-exp'}));
      if(s.run!=null||s.compute){const rx=/\$\{[^}]*\}|\$\(\(.*?\)\)|\$\([^)]*\)|\$[A-Za-z_]\w*|\$[0-9#?@*]|~(?=\/|\s|$)/g;let m;const pt=[].concat(s.part||[]).map(t=>[l.indexOf(t),l.indexOf(t)+t.length]).filter(x=>x[0]>=0);
        while((m=rx.exec(l)))if(!pt.length||pt.some(([a,b])=>m.index>=a&&m.index+m[0].length<=b))marks.push({s:m.index,e:m.index+m[0].length,c:'db-exp'})}}
    if(s&&s.also)for(const[ln,t]of s.also)if(ln===n)marks.push({t,c:'db-also'});
    return `<span class="db-ln${cur?' cur':''}"><b>${n}</b><span>${marks.length?markLine(l,marks):hl(l)||' '}</span></span>`}).join('')}
function runHTML(s){
  if(!s)return '<span class="db-lab">not started</span>';
  let h='';
  if(s.who==='copy')h+='<span class="db-who">a copy of bash</span>';
  if(s.compute&&!s.run)h+='<span class="db-lab">the shell computes</span>';
  else if(s.run!=null)h+=`<span class="db-lab">${s.who==='copy'?'runs':'bash runs'}</span><code class="db-cmd">${hl(s.run)}</code>`;
  else h+='<span class="db-lab">bash</span>';
  if(s.status!=null)h+=`<span class="db-ec ${s.status?'bad':'ok'}" title="exit code">${s.status}</span>`;
  if(s.info)h+=`<span class="db-info">${md(s.info)}</span>`;
  return h}
function varsHTML(st){
  if(!st.vars.size&&!st.gone.size)return '<p class="db-none">no variables yet</p>';
  const rank=k=>/^\$\d+$/.test(k)?+k.slice(1):k==='$#'?50:100;
  return '<table class="db-vt">'+[...st.vars].map((e,i)=>[e,i]).sort((a,b)=>rank(a[0][0])-rank(b[0][0])||a[1]-b[1]).map(x=>x[0]).map(([k,v])=>{const c=st.gone.has(k)?'x':st.changed.has(k)?'ch':'';const t=st.tags.get(k);
    return `<tr class="${c}"><td>${esc(k)}</td><td><code>"${esc(v).replace(/\n/g,'<i>\\n</i>')}"</code>${t?` <em>${esc(t)}</em>`:''}</td></tr>`}).join('')+'</table>'}
function filesHTML(sc,s){
  if(!sc.files)return '';
  return '<div class="db-files">'+Object.entries(sc.files).map(([nm,ls])=>`<div class="db-file"><div>${esc(nm)}</div><pre>${ls.map((l,k)=>{const on=s&&((s.match&&l.includes(s.match))||(s.read&&s.read.includes(k+1)));return `<span class="${on?'on':''}">${esc(l)}</span>`}).join('\n')}</pre></div>`).join('')+'</div>'}
function outHTML(sc,st,cmd){const c=cmd||sc.cmd;return(c?`<span class="db-pr">$</span> ${esc(c)}\n`:'')+term(st.out)+(st.cur?`<span class="db-new">${term(st.cur)}</span>`:'')}
function dbgBody(){return `<div class="db-b"><div class="db-l"><div class="db-fh" data-r="fn"></div><pre class="db-code" data-r="code"></pre><div class="db-run" data-r="run"></div></div>
  <div class="db-r"><div class="db-h">variables</div><div data-r="vars"></div><div class="db-h">output</div><pre class="db-out" data-r="out"></pre><div data-r="files"></div></div></div>`}
function drawDbg(root,sc,i,opt={}){
  const q=s=>root.querySelector(`[data-r="${s}"]`);const s=i>=0?sc.steps[i]:null,st=stateAt(sc,i);
  q('fn').innerHTML=`<b>${esc(sc.file||(sc.cmd||'').split(' ')[0].replace(/^\.\//,'')||'script.sh')}</b><span>${s?'line '+s.line:''}</span>`;
  if(!opt.keepCode)q('code').innerHTML=codeHTML(sc,s);
  q('run').innerHTML=runHTML(s);
  q('vars').innerHTML=varsHTML(st);
  q('out').innerHTML=outHTML(sc,st,opt.cmd);q('out').scrollTop=q('out').scrollHeight;
  q('files').innerHTML=filesHTML(sc,s)}
function defNote(s){if(!s)return '';if(s.note)return md(s.note);
  if(s.who==='copy')return 'Inside <code>$(...)</code>: a <b>copy</b> of bash runs it, its output is captured, nothing reaches the screen.';
  if(s.compute)return 'The shell itself computes, no program is started.';
  if(s.status!=null)return 'Exit code <b>'+s.status+'</b>'+(s.status?' – not 0: <i>false</i>, an error.':' – <i>true</i>, success.');
  return 'Line '+s.line+'.'}
function wDbg(root){
  const D=JSON.parse(root.dataset.d);const scs=D.sc;let k=0;
  root.innerHTML=`<div class="wd dbg"><div class="wd-h"><div><h3>${md(D.title)}</h3><p>${md(D.sub||'Step through the script: the line that runs (orange), what bash runs after replacing the variables, its exit code, the variables and the output.')}</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c">${scs.length>1?`<div class="seg" data-r="seg">${scs.map((s,j)=>`<button type="button" data-v="${j}" class="${j?'':'on'}">${esc(s.label)}</button>`).join('')}</div>`:''}${NAV()}</div>
  <div class="ps-x" data-r="x"></div>${dbgBody()}</div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=stepper(root,()=>scs[k].steps.length,i=>{const sc=scs[k],s=sc.steps[i];drawDbg(root,sc,i);q('x').innerHTML=defNote(s);q('b').textContent='step '+(i+1)+' / '+sc.steps.length});
  root.querySelectorAll('[data-r="seg"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-r="seg"] button').forEach(x=>x.classList.toggle('on',x===b));k=+b.dataset.v;go(0)}));
  go(0)}

/* ================================================================ the script lab */
const LABS=window.ISO_LABS=window.ISO_LABS||{};
const strip=s=>s.replace(/^\s*#.*$/gm,'');
const has=(r,rx)=>rx.test(strip(r.src));
const out=(r,rx)=>rx.test(r.out);
const linesIn=(r,arr)=>{const ls=r.out.split('\n').map(x=>x.trim());let p=0;for(const x of ls){if(x===arr[p])p++;if(p===arr.length)return true}return false};
Object.assign(LABS,{
  scripts:[
    {t:'Run the script as it is: <b>▶ Run</b>.',h:'the button above the output',free:true,ok:r=>/done/.test(r.out)},
    {t:'Add a last line that prints <code>all files copied</code>.',h:'echo "all files copied"',ok:r=>/all files copied\s*$/.test(r.out)},
    {t:'Add a comment that explains the script (it must still run).',h:'a line that starts with #',ok:r=>/^\s*#(?!!).+/m.test(r.src)&&r.status===0},
    {t:'Put two commands on the same line.',h:'separate them with ;',ok:r=>r.status===0&&/^[^#'"\n]*\w[^#'"\n]*;\s*\w/m.test(r.src)},
    {t:'Write one command on two lines.',h:'a \\ at the end of the first line',ok:r=>/\\\n/.test(r.src)&&r.status===0},
  ],
  vars:[
    {t:'Put <code>Alice Smith</code> in <code>name</code> and print <code>Hi, Alice Smith</code>.',h:'quotes keep the space in the value',ok:r=>r.vars.name==='Alice Smith'&&/Hi, Alice Smith/.test(r.out)},
    {t:'With <code>user=alice</code>, print <code>alice_notes.txt</code> using the variable.',h:'${user}_notes.txt',ok:r=>r.vars.user==='alice'&&/alice_notes\.txt/.test(r.out)&&has(r,/\$\{user\}/)},
    {t:'Make <code>greeting</code> hold <code>Hello, bob</code>, built from another variable.',h:'greeting="Hello, $name"',ok:r=>r.vars.greeting==='Hello, bob'&&has(r,/greeting=[^\n]*\$/)},
    {t:'Delete a variable, then print it between brackets: <code>[]</code>.',h:'unset name; echo "[$name]"',ok:r=>has(r,/\bunset\s+\w/)&&/^\[\]$/m.test(r.out)},
  ],
  words:[
    {t:'Print <code>[Alice   Smith:20]</code>, the three spaces kept.',h:'quote the variable',ok:r=>/\[Alice   Smith:20\]/.test(r.out)},
    {t:'Print <code>[Alice   Smith]</code> and <code>[20]</code>, one per line.',h:'IFS=: before the printf',ok:r=>/\[Alice   Smith\]\n\[20\]/.test(r.out)},
    {t:'Make <code>printf</code> print an empty word: <code>[]</code>.',h:'IFS=: and a value with ::',ok:r=>/\[\]/.test(r.out)&&has(r,/IFS=/)},
    {t:'End the script with <code>IFS</code> back to the default.',h:'unset IFS',ok:r=>has(r,/IFS/)&&r.vars.IFS==='space tab newline'},
  ],
  read:[
    {t:'Read two words into <code>first</code> and <code>last</code>, print <code>last, first</code>.',h:'read first last; the keyboard box has the line',ok:r=>r.vars.first&&r.vars.last&&r.out.includes(r.vars.last+', '+r.vars.first)},
    {t:'Read <code>2:11:2026</code> into <code>d m y</code> and print <code>2026-11-2</code>.',h:'IFS=: read d m y; put the date in the keyboard box',ok:r=>/2026-11-2\b/.test(r.out)&&has(r,/IFS=:\s*read/)},
    {t:'Read the first line of <code>/etc/passwd</code> and print <code>root has UID 0</code>.',h:'IFS=: read user x uid rest < /etc/passwd',ok:r=>/root has UID 0/.test(r.out)},
    {t:'Print the line of <code>path.txt</code> with its backslashes: <code>C:\\new\\temp</code>.',h:'read -r',ok:r=>/C:\\new\\temp/.test(r.out)&&has(r,/read\s+(-\w*\s+)*-r/)},
  ],
  subst:[
    {t:'Print <code>today is Thursday</code> using <code>date</code>.',h:'$(date +%A)',ok:r=>/today is Thursday/.test(r.out)&&has(r,/\$\(date/)},
    {t:'Put the number of lines with <code>apple</code> in <code>apples</code>.',h:'grep -c apple fruits.txt',ok:r=>r.vars.apples==='3'},
    {t:'Put the first line of <code>fruits.txt</code> in <code>first</code>.',h:'head -n 1',ok:r=>r.vars.first==='banana'},
    {t:'Print how many <code>.txt</code> files there are: <code>3 files</code>.',h:'ls *.txt | wc -l',ok:r=>/\b3 files/.test(r.out)&&has(r,/\$\(/)},
  ],
  arith:[
    {t:'Print <code>7 / 2</code> and <code>7 % 2</code>: <code>3 1</code>.',h:'echo $((a / b)) $((a % b))',ok:r=>/^3 1$/m.test(r.out)&&has(r,/%/)},
    {t:'Print 2 to the power 10.',h:'**',ok:r=>/\b1024\b/.test(r.out)&&has(r,/\*\*/)},
    {t:'Count <code>n</code> from 0 to 3 with <code>(( ))</code>.',h:'((n++)) three times, or a loop',ok:r=>r.vars.n==='3'&&has(r,/\(\(\s*(n\s*\+\+|\+\+\s*n|n\s*\+=)/)},
    {t:'Put <code>3.5 * 2</code> in <code>total</code>: <code>7.0</code>.',h:'total=$(echo "3.5 * 2" | bc)',ok:r=>r.vars.total==='7.0'},
    {t:'Compute <code>4 + 5</code> with <code>expr</code> into <code>sum</code>.',h:'sum=$(expr 4 + 5)',ok:r=>r.vars.sum==='9'&&has(r,/expr/)},
  ],
  cond:[
    {t:'Print <code>a file</code> if <code>notes.txt</code> is a file.',h:'if [ -f notes.txt ]; then ...',ok:r=>/a file/.test(r.out)&&has(r,/\[\s+-f\s/)},
    {t:'With <code>a=7</code> and <code>b=3</code>, print <code>a is bigger</code> with <code>[</code>.',h:'[ $a -gt $b ]',ok:r=>/a is bigger/.test(r.out)&&has(r,/\[\s+"?\$a"?\s+-gt\s+"?\$b"?\s+\]/)},
    {t:'With <code>n=50</code>, print <code>small</code> (under 10), <code>medium</code> (under 100) or <code>big</code>.',h:'if, elif, else',ok:r=>/^medium$/m.test(r.out)&&has(r,/\belif\b/)&&r.vars.n==='50'},
    {t:'Print <code>empty</code> when <code>x</code> is empty, with no error.',h:'[ -z "$x" ]',ok:r=>/^empty$/m.test(r.out)&&!/\u0001/.test(r.term)},
    {t:'Use <code>(( ))</code> as the condition of an <code>if</code>.',h:'if (( a > b )); then',ok:r=>has(r,/if\s+\(\(/)&&r.status===0&&r.out.trim()!==''},
  ],
  case:[
    {t:'Print <code>yes</code> for <code>y</code>, <code>Y</code>, <code>yes</code> or <code>Yes</code>.',h:'[yY]*)',ok:r=>has(r,/\[yY\]|\[Yy\]/)&&/^yes$/m.test(r.out)},
    {t:'Add a default branch that prints <code>unknown</code>, and make it run.',h:'*) echo "unknown" ;; – last',ok:r=>/^unknown$/m.test(r.out)&&has(r,/\*\)/)},
    {t:'Print <code>text</code> for a name that ends in <code>.txt</code>.',h:'*.txt)',ok:r=>/^text$/m.test(r.out)&&has(r,/\*\.txt\)/)},
    {t:'Use one branch for two patterns.',h:'apple|cherry)',ok:r=>has(r,/^\s*\(?[^\s|()]+\|[^\s()]+\)/m)&&r.status===0&&r.out.trim()!==''},
  ],
  while:[
    {t:'Count down from <code>5</code> to <code>1</code>.',h:'n=5; while [ $n -gt 0 ]',ok:r=>linesIn(r,['5','4','3','2','1'])&&has(r,/\bwhile\b/)},
    {t:'Print <code>1</code>, <code>2</code>, <code>3</code> with <code>until</code>.',h:'until [ $n -eq 3 ]',ok:r=>linesIn(r,['1','2','3'])&&has(r,/\buntil\b/)},
    {t:'Print <code>buy apple</code> and <code>buy kiwi</code> from <code>shopping.txt</code>.',h:'while read f; do ...; done < shopping.txt',ok:r=>/buy apple\nbuy kiwi/.test(r.out)&&has(r,/done\s*<\s*shopping\.txt/)},
    {t:'Count the lines of <code>fruits.txt</code> in a loop and print <code>7</code> after it.',h:'c=$((c + 1)) in the body, < fruits.txt after done',ok:r=>/^7$/m.test(r.out)&&has(r,/done\s*<\s*fruits\.txt/)&&!has(r,/wc/)},
  ],
  for:[
    {t:'Print the name of every <code>.txt</code> file.',h:'for f in *.txt',ok:r=>/fruits\.txt/.test(r.out)&&/words\.txt/.test(r.out)&&has(r,/for\s+\w+\s+in\s+\*\.txt/)},
    {t:'Print <code>1 4 7 10</code> with <code>seq</code>.',h:'$(seq 1 3 10)',ok:r=>/1\s+4\s+7\s+10/.test(r.out)&&has(r,/seq/)},
    {t:'Print the same numbers with a C-like <code>for</code>.',h:'for ((i = 1; i <= 10; i += 3))',ok:r=>/1\s+4\s+7\s+10/.test(r.out)&&has(r,/for\s*\(\(/)},
    {t:'Print <code>[Alice Smith]</code> and <code>[Bob Jones]</code> from <code>people.txt</code>.',h:'while read, or IFS=$\'\\n\'',ok:r=>/\[Alice Smith\]\n\[Bob Jones\]/.test(r.out)},
  ],
  func:[
    {t:'Write <code>add</code>, which prints the sum of its two parameters; <code>sum=$(add 2 3)</code>.',h:'echo $(( $1 + $2 ))',ok:r=>r.vars.sum==='5'&&has(r,/add\s*\(\)/)},
    {t:'Make a function end with <code>1</code> when it gets no parameters, and print <code>nobody</code> with <code>||</code>.',h:'[ $# -eq 0 ] && return 1',ok:r=>/^nobody$/m.test(r.out)&&has(r,/return\s+1/)&&has(r,/\|\|/)},
    {t:'Change a variable inside a function with <code>local</code>, so the <code>name</code> of the script stays <code>alice</code>.',h:'local name="bob"',ok:r=>has(r,/\blocal\b/)&&r.vars.name==='alice'},
    {t:'Write <code>max</code>, which prints the bigger of two numbers; <code>m=$(max 4 9)</code>.',h:'if [ $1 -gt $2 ]',ok:r=>r.vars.m==='9'&&has(r,/max\s*\(\)/)},
  ],
  params:[
    {t:'Print <code>first: alice</code>, with <code>alice</code> taken from the parameters.',h:'echo "first: $1"',ok:r=>/first: alice/.test(r.out)&&has(r,/\$\{?1/)&&r.args[0]==='alice'},
    {t:'Print every parameter between <code>[ ]</code>, <code>Alice Smith</code> as one.',h:'for p in "$@"',ok:r=>/\[Alice Smith\]/.test(r.out)&&has(r,/"\$@"/)},
    {t:'Without parameters, print <code>usage: ...</code> and stop with <code>exit 1</code>. Try it: empty the parameters.',h:'if [ $# -eq 0 ]; then echo "usage: ..."; exit 1; fi',ok:r=>r.args.length===0&&r.status===1&&/usage/i.test(r.out)},
  ],
});
function wLab(root){
  const set=LABS[root.dataset.set]||[];
  const name=root.dataset.name||'./script.sh',files=(root.dataset.files||'fruits.txt,notes.txt,words.txt').split(',');
  const start=root.dataset.src||'',kbOn=root.dataset.kb!=null,title=root.dataset.title||'Script lab';
  const EX=root.dataset.ex?JSON.parse(root.dataset.ex):[];
  const norm=s=>s.replace(/\s+/g,' ').trim();const known=new Set([start,...EX.map(e=>e.src)].map(norm));
  let mode='edit',sc=null,done=new Set();
  root.innerHTML=`<div class="wd lab"><div class="wd-h"><div><h3>${esc(title)}</h3><p>Write a script and run it: the bash of this page runs it on the files of the lecture. <b>Step by step</b> shows it the way the debugger of the slides does.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls lb-c"><button type="button" class="btn" data-r="go">▶ Run</button><button type="button" class="btn ghost" data-r="dbg">Step by step</button><button type="button" class="btn ghost" data-r="edit" hidden>✎ Edit</button>${EX.length?`<span class="chl">examples:</span>${EX.map((e,j)=>`<button type="button" class="chip" data-x="${j}">${esc(e.label)}</button>`).join('')}`:''}<button type="button" class="lb-reset" data-r="reset">reset</button><span class="lb-nav" data-r="nav" hidden>${NAV()}</span></div>
  <div class="ps-x lb-x" data-r="x" hidden></div>
  <div class="db-b"><div class="db-l"><div class="db-fh" data-r="fn"></div>
    <div class="lb-ed" data-r="ed"><pre class="lb-hl" aria-hidden="true" data-r="hlp"></pre><textarea spellcheck="false" autocapitalize="off" aria-label="the script" data-r="ta"></textarea></div>
    <pre class="db-code" data-r="code" hidden></pre><div class="db-run" data-r="run" hidden></div>
    <div class="lb-args"><span class="db-pr">$</span> <code>${esc(name)}</code> <input data-r="args" value="${esc(root.dataset.args||'')}" placeholder="parameters" aria-label="parameters" spellcheck="false"></div>
    ${kbOn?`<label class="lb-kb"><span>keyboard: what the user types, one line for every <code>read</code></span><textarea rows="2" data-r="kb" spellcheck="false">${esc(root.dataset.input||'')}</textarea></label>`:''}</div>
  <div class="db-r"><div class="db-h">variables</div><div data-r="vars"><p class="db-none">run the script</p></div><div class="db-h">output</div><pre class="db-out" data-r="out"><span class="db-none">press ▶ Run</span></pre><div data-r="files"></div></div></div>
  ${set.length?`<div class="missions"><div class="mh"><b>Missions</b> <span data-r="mcount"></span><button type="button" class="mall" data-r="mall">show all</button><em class="mnote">the examples do not count: change them</em></div><ol data-r="ml">${set.map((m,i)=>`<li data-i="${i}"><span class="mt">${m.t}</span> <details><summary>hint</summary><code>${esc(m.h)}</code></details></li>`).join('')}</ol></div>`:''}</div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const ta=q('ta'),hp=q('hlp');
  const paint=()=>{hp.innerHTML=hl(ta.value)+'\n';hp.scrollTop=ta.scrollTop;fit()};
  const fit=()=>{ta.style.height='auto';const h=Math.max(150,Math.min(420,ta.scrollHeight+4));ta.style.height=h+'px';hp.style.height=h+'px'};
  ta.value=start;
  ta.addEventListener('input',paint);ta.addEventListener('scroll',()=>{hp.scrollTop=ta.scrollTop;hp.scrollLeft=ta.scrollLeft});
  ta.addEventListener('keydown',e=>{if(e.key==='Tab'){e.preventDefault();const p=ta.selectionStart;ta.value=ta.value.slice(0,p)+'    '+ta.value.slice(ta.selectionEnd);ta.selectionStart=ta.selectionEnd=p+4;paint()}
    if(e.key==='Enter'&&(e.ctrlKey||e.metaKey)){e.preventDefault();run(false)}});
  q('fn').innerHTML=`<b>${esc(name.replace(/^\.\//,''))}</b><span>Ctrl+Enter runs it</span>`;
  const mcheck=r=>{if(!set.length)return;
    const changed=!known.has(norm(r.src));
    set.forEach((m,i)=>{if(!done.has(i)&&(m.free||changed)){try{if(m.ok(r))done.add(i)}catch(e){}}});
    root.querySelectorAll('[data-r="ml"] li').forEach(li=>li.classList.toggle('ok',done.has(+li.dataset.i)));
    q('mcount').textContent=done.size+' / '+set.length;
    root.querySelector('.missions').classList.toggle('fin',done.size===set.length);
    const b=q('b');b.textContent=done.size===set.length?'all missions done':done.size+' / '+set.length+' missions';b.className='badge'+(done.size===set.length?' ok':'')};
  let go=null;
  const setMode=m=>{mode=m;const st=m==='step';q('ed').hidden=st;q('code').hidden=!st;q('run').hidden=!st;q('nav').hidden=!st;q('x').hidden=!st;q('edit').hidden=!st;q('dbg').hidden=st;
    q('fn').innerHTML=`<b>${esc(name.replace(/^\.\//,''))}</b><span>${st?'':'Ctrl+Enter runs it'}</span>`;if(!st)setTimeout(fit,0)};
  function run(step){
    const src=ta.value,args=B.words(q('args').value),input=kbOn?q('kb').value.replace(/\n?$/,'\n'):'';
    const r=B.run(src,{name,args,input,files,maxSteps:600});
    sc={code:src,cmd:name+(q('args').value.trim()?' '+q('args').value.trim():''),file:name.replace(/^\.\//,''),steps:r.steps,init:r.init};
    const res={src,out:plain(r.term),term:r.term,vars:r.vars,status:r.status,steps:r.steps,args,files:r.files,input};
    mcheck(res);
    if(step&&r.steps.length){setMode('step');go(0);return}
    setMode('edit');
    const stt=stateAt(sc,r.steps.length-1);stt.changed.clear();stt.gone.clear();stt.out+=stt.cur;stt.cur='';
    q('vars').innerHTML=varsHTML(stt);
    q('out').innerHTML=outHTML(sc,stt)+`<span class="db-pr">$</span> <span class="db-st">echo $? → ${r.status}</span>`;q('out').scrollTop=q('out').scrollHeight;q('files').innerHTML=''}
  go=stepper(root,()=>sc?sc.steps.length:1,i=>{if(!sc)return;drawDbg(root,sc,i);q('x').innerHTML=defNote(sc.steps[i]);
    const ln=root.querySelector('.db-ln.cur');if(ln){const c=q('code');c.scrollTop=Math.max(0,ln.offsetTop-c.clientHeight/2)}});
  q('go').addEventListener('click',()=>run(false));
  q('dbg').addEventListener('click',()=>run(true));
  q('edit').addEventListener('click',()=>{setMode('edit');ta.focus()});
  q('reset').addEventListener('click',()=>{ta.value=start;q('args').value=root.dataset.args||'';if(kbOn)q('kb').value=root.dataset.input||'';setMode('edit');paint()});
  root.querySelectorAll('[data-x]').forEach(b=>b.addEventListener('click',()=>{const e=EX[+b.dataset.x];ta.value=e.src;if(e.args!=null)q('args').value=e.args;if(kbOn&&e.input!=null)q('kb').value=e.input;setMode('edit');paint();run(false)}));
  if(set.length)q('mall').addEventListener('click',()=>{const all=root.querySelector('.missions').classList.toggle('all');q('mall').textContent=all?'only the next one':'show all'});
  setTimeout(paint,0);paint();
  if(set.length){q('mcount').textContent='0 / '+set.length;q('b').textContent='0 / '+set.length+' missions'}else q('b').textContent='bash (demo)';
}

/* ================================================================ IFS: $x, "$x" and read */
const IFSV={def:[' \t\n','space, tab, newline','default'],colon:[':',':','IFS=:'],comma:[',',',','IFS=,'],nl:['\n','newline',"IFS=$'\\n'"],empty:['','nothing','IFS=']};
function ifsLine(v,ifs,cut){return '<span class="sp-line">'+[...v].map(c=>{const sep=cut&&ifs.includes(c);const t=c===' '?'·':c==='\t'?'→':c==='\n'?'\\n':c;return `<span class="${sep?'sep':''}${c===' '||c==='\t'||c==='\n'?' ws':''}">${esc(t)}</span>`}).join('')+'</span>'}
function wSplit(root){
  const modes=(root.dataset.modes||'unq,q').split(','),ifsL=(root.dataset.ifs||'def,colon').split(',');
  const names=(root.dataset.names||'a b c').split(' ');
  const pres=JSON.parse(root.dataset.pre||'["Alice   Smith:20","  a   b  ","a b::c"]');
  let mode=modes[0],ifs=ifsL[0];
  const ML={unq:'$x',q:'"$x"',read:'read '+names.join(' ')};
  root.innerHTML=`<div class="wd sp"><div class="wd-h"><div><h3>${esc(root.dataset.title||'Where does the shell cut?')}</h3><p>${md(root.dataset.sub||'Type a value, choose `IFS` and how the value is used: the separators are orange, every piece is a word.')}</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls sp-c"><label class="sp-v"><span>the value</span><textarea rows="1" data-r="v" spellcheck="false">${esc(pres[0])}</textarea></label>
  <div><span class="chl">IFS</span><div class="seg" data-seg="ifs">${ifsL.map(k=>`<button type="button" data-v="${k}" class="${k===ifs?'on':''}">${esc(IFSV[k][1])}</button>`).join('')}</div></div>
  ${modes.length>1?`<div><span class="chl">used as</span><div class="seg" data-seg="mode">${modes.map(k=>`<button type="button" data-v="${k}" class="${k===mode?'on':''}">${esc(ML[k])}</button>`).join('')}</div></div>`:''}
  <div class="sp-pre"><span class="chl">try:</span>${pres.map((p,j)=>`<button type="button" class="chip" data-p="${j}">${esc(p.replace(/\n/g,'\\n'))}</button>`).join('')}</div></div>
  <div class="ps-x" data-r="x"></div><div class="sp-b" data-r="body"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const draw=()=>{
    const v=q('v').value,I=IFSV[ifs][0];let ws,html,x;
    
    if(mode==='read'){const vals=B.readSplit(v.split('\n')[0],I,names,true);
      html=`<div class="sp-row"><span class="sp-k">the line</span>${ifsLine(v.split('\n')[0],I,true)}</div><div class="sp-row sp-rd"><code class="sp-cmd">${hl((ifs==='def'?'':IFSV[ifs][2]+' ')+'read '+names.join(' '))}</code><div class="sp-map">${vals.map((val,k)=>`<span><span class="w8 new">${val===''?'<i>""</i>':esc(val)}</span><b>${esc(names[k])}</b></span>`).join('')}</div></div>`;
      x=I===''?'`IFS=` (empty): nothing is cut, the first variable takes the whole line.':'One word for every variable, cut at the characters of `IFS`; the **last** variable takes the rest of the line, separators included.';
      ws=vals}
    else{const cut=mode==='unq';ws=cut?B.split(v,I):[v];
      const xq=/[\n\t]/.test(v)?B.shq(v):'"'+v.replace(/(["\\$`])/g,'\\$1')+'"';
      const sh=`$ x=${xq}\n`+(ifs==='def'?'':`$ ${IFSV[ifs][2]}\n`)+`$ printf '[%s]\\n' ${ML[mode]}\n`+(ws.length?ws.map(w=>'['+w+']').join('\n'):'[]');
      html=`<div class="sp-row"><span class="sp-k">$x</span>${ifsLine(v,I,cut)}</div><div class="sp-row"><span class="sp-k">${cut?'cut at IFS':'quoted: not cut'}</span><div>${ws.length?chipsHTML(ws.map(w=>[w,'new'])):'<span class="db-none">no word at all: the variable disappears</span>'}</div></div><pre class="sh sp-sh">${shHTML(sh)}</pre>`;
      const nonws=[...I].some(c=>!/\s/.test(c));
      x=!cut?'Quoted: **one** word, `IFS` does not matter, the spaces are kept.':I===''?'`IFS` is empty: nothing is cut, one word.':ws.includes('')?'Two separators in a row that are not spaces make an **empty** word.':!nonws&&/(^\s|\s$|\s\s)/.test(v)?'Spaces, tabs and newlines in a row are **one** cut; at the start and at the end they are dropped.':nonws&&/\s/.test(v)&&!I.includes(' ')?'Only the characters of `IFS` cut: here the space is a normal character.':'Every piece between the separators is a separate word.'}
    q('body').innerHTML=html;q('x').innerHTML=md(x);q('b').textContent=ws.length+(ws.length===1?' word':' words')};
  root.querySelectorAll('[data-seg]').forEach(sg=>sg.querySelectorAll('button').forEach(b=>b.addEventListener('click',()=>{sg.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));if(sg.dataset.seg==='ifs')ifs=b.dataset.v;else mode=b.dataset.v;draw()})));
  root.querySelectorAll('[data-p]').forEach(b=>b.addEventListener('click',()=>{q('v').value=pres[+b.dataset.p];q('v').rows=q('v').value.includes('\n')?2:1;draw()}));
  q('v').addEventListener('input',()=>{q('v').rows=q('v').value.includes('\n')?2:1;draw()});
  draw()}

/* ================================================================ the shell sees the words */
function typedHTML(pieces,ok){return pieces.map(p=>Array.isArray(p)?`<u class="${ok?'good':'bad'}">${hl(p[0])}</u>`:hl(p)).join('')}
function shHTML(t){return t.split('\n').map(l=>l.startsWith('$ ')?`<span class="p">$</span> <span class="c">${hl(l.slice(2))}</span>`:l.startsWith('!')?`<span class="db-err">${esc(l.slice(1))}</span>`:`<span class="o">${esc(l)}</span>`).join('\n')}
function wPit(root){
  const D=JSON.parse(root.dataset.d);const scs=D.sc;let k=0;
  root.innerHTML=`<div class="wd pw"><div class="wd-h"><div><h3>${md(D.title||'What does the shell see?')}</h3><p>${md(D.sub||'Before running anything, bash cuts the line into words. Pick a line: the mistake is underlined, the chips are the words bash makes.')}</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><div class="pw-chips">${scs.map((s,j)=>`<button type="button" class="chip${j?'':' on'}" data-k="${j}">${esc(s.l)}</button>`).join('')}</div>${NAV()}</div>
  <div class="ps-x" data-r="x"></div>
  <div class="pw-b"><div>${D.files?`<div class="pw-files"><div class="db-h">the file</div>${Object.entries(D.files).map(([nm,ls])=>`<div class="db-file"><div>${esc(nm)}</div><pre>${ls.map(l=>esc(l)).join('\n')}</pre></div>`).join('')}</div>`:''}<div class="db-h">you typed</div><div class="pw-t" data-r="t"></div><div class="db-h" data-r="wh">the shell sees the words</div><div class="pw-w" data-r="w"></div></div><div><div class="db-h">in a terminal</div><pre class="sh pw-sh" data-r="sh"></pre></div></div>
  ${D.try?`<div class="pw-try"><label><span>try your own line</span><input data-r="in" spellcheck="false" autocapitalize="off" value="${esc(D.try.v||'')}"></label><div class="pw-tw" data-r="tw"></div><pre class="sh pw-sh" data-r="tsh"></pre>${D.try.note?`<p class="small">${md(D.try.note)}</p>`:''}</div>`:''}</div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  let tryRun=null;
  const go=stepper(root,()=>scs.length,i=>{k=i;const s=scs[i];
    if(D.try){q('in').value=s.typed.map(p=>Array.isArray(p)?p[0]:p).join('');if(tryRun)tryRun()}
    root.querySelectorAll('[data-k]').forEach(b=>b.classList.toggle('on',+b.dataset.k===i));
    q('t').innerHTML=`<span class="pw-mk">${s.ok?'✅':'❌'}</span><code>${typedHTML(s.typed,s.ok)}</code>`;
    q('w').innerHTML=s.words?chipsHTML(s.words):'<span class="db-none">–</span>';
    q('wh').innerHTML=md(s.wh||D.wh||'the shell sees the words');
    q('sh').innerHTML=shHTML(s.out);q('x').innerHTML=md(s.x);q('b').textContent=(i+1)+' / '+scs.length});
  root.querySelectorAll('[data-k]').forEach(b=>b.addEventListener('click',()=>go(+b.dataset.k)));
  if(D.try){const t=()=>{const v=q('in').value;if(!v.trim()){q('tw').innerHTML='';q('tsh').innerHTML='';return}
      const r=B.line(v,{vars:D.try.vars||{},files:D.try.files});
      q('tw').innerHTML=r.chips.length?chipsHTML(r.chips.map(c=>[c.t,c.k==='cmd'?'cmd':c.k==='asg'?'asg':c.k==='redir'?'redir':''])):'<span class="db-none">not a simple command: no chips</span>';
      q('tsh').innerHTML=`<span class="p">$</span> <span class="c">${hl(v)}</span>\n`+term(r.term)+`<span class="k">exit code ${r.status}</span>`};
    q('in').addEventListener('input',t);tryRun=t}
  go(0)}

/* ================================================================ running a script */
const BK=['#!/bin/bash','echo "backing up"','mkdir -p ~/backup','cp notes.txt ~/backup/','echo "done"'];
const RS={
  dot:{typed:[['./backup.sh','cmd']],steps:[
    {who:'you',t:'type <code>./backup.sh</code> and press Enter',x:'The command is a <b>path</b>: it has a <code>/</code>.'},
    {who:'shell',t:'a <b>path</b>: no <code>PATH</code> search, it asks the kernel to run the file',x:'Because of the <code>/</code>, the shell does not look in <code>PATH</code>: it calls <code>execve("./backup.sh", …)</code>.'},
    {who:'kernel',t:'checks the permission: <code>x</code> is required',perm:'check',x:'The kernel runs only files with the <code>x</code> permission for you.'},
    {who:'kernel',t:'reads the first line: <code>#!/bin/bash</code> – run it with <code>/bin/bash</code>',bang:'read',x:'<code>#!</code> (<i>shebang</i>) at the start of the file: the program written after it runs the file.'},
    {who:'kernel',t:'starts a new process: <span class="w8 cmd">/bin/bash</span><span class="w8 new">./backup.sh</span>',bang:'read',x:'The script becomes a <b>parameter</b> of <code>bash</code>.'},
    {who:'bash',t:'runs the file, line by line – <code>#!/bin/bash</code> is a comment for it',bang:'comment',lines:[2,3,4,5],out:true,x:'For <code>bash</code>, a line starting with <code>#</code> is a comment, so the shebang is skipped.'}]},
  bash:{typed:[['bash','cmd'],['backup.sh','']],steps:[
    {who:'you',t:'type <code>bash backup.sh</code> and press Enter',x:'The command is <code>bash</code>, the script is its parameter.'},
    {who:'shell',t:'a <b>name</b>: finds <code>/bin/bash</code> in <code>PATH</code>, asks the kernel to run it',x:'No <code>/</code> in <code>bash</code>: the shell searches the folders of <code>PATH</code>.'},
    {who:'kernel',t:'checks the <code>x</code> of <code>/bin/bash</code>, <b>not</b> of <code>backup.sh</code>',perm:'skip',x:'<code>chmod +x</code> is not needed: the kernel runs <code>bash</code>, which only <i>reads</i> the script.'},
    {who:'kernel',t:'starts a new process: <span class="w8 cmd">/bin/bash</span><span class="w8">backup.sh</span> – <code>#!</code> is not read',x:'The kernel never opens the script, so it never sees <code>#!</code>.'},
    {who:'bash',t:'opens <code>backup.sh</code> and runs it, line by line',bang:'comment',lines:[2,3,4,5],out:true,x:'Same result: <code>#!/bin/bash</code> is just a comment.'}]},
  nox:{typed:[['./backup.sh','cmd']],pre:'$ chmod -x backup.sh',steps:[
    {who:'you',t:'remove the <code>x</code>: <code>chmod -x backup.sh</code>, then <code>./backup.sh</code>',x:'The same script, without the execute permission.',perms:'-rw-r--r--'},
    {who:'shell',t:'a <b>path</b>: it asks the kernel to run the file',perms:'-rw-r--r--',x:'The shell does not check anything itself.'},
    {who:'kernel',t:'checks the permission: no <code>x</code> – it <b>refuses</b>',perm:'none',perms:'-rw-r--r--',err:true,x:'<code>execve</code> fails with <code>EACCES</code>; the shell prints <i>Permission denied</i>, exit code <code>126</code>. <code>bash backup.sh</code> still works.'}]},
};
function wRunsc(root){
  let sc='dot';
  root.innerHTML=`<div class="wd rs"><div class="wd-h"><div><h3>What happens after Enter</h3><p>Who does what when a script starts: the <b>shell</b> you type in, the <b>kernel</b>, the new <b>bash</b> that runs the file.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><div class="seg" data-r="seg"><button type="button" data-v="dot" class="on">./backup.sh</button><button type="button" data-v="bash">bash backup.sh</button><button type="button" data-v="nox">without x</button></div>${NAV()}</div>
  <div class="ps-x" data-r="x"></div>
  <div class="rs-b"><div><div class="db-h">you type</div><div class="rs-typed" data-r="typed"></div><ol class="rs-steps" data-r="steps"></ol></div>
  <div><div class="db-file rs-f"><div><b>backup.sh</b> <span data-r="perm"></span></div><pre data-r="file"></pre></div><div class="db-h">output</div><pre class="db-out rs-out" data-r="out"></pre></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const perm=(m,p)=>{const P=p||'-rwxr-xr-x';return '<code class="rs-perm">'+[...P].map((c,k)=>k%3===0&&k?(m==='check'&&c==='x'?`<b class="chk">x</b>`:m==='skip'&&c==='x'?`<s>x</s>`:m==='none'&&k>0&&c==='-'?`<b class="no">-</b>`:esc(c)):esc(c)).join('')+'</code>'};
  const go=stepper(root,()=>RS[sc].steps.length,i=>{const S=RS[sc],s=S.steps[i];
    q('typed').innerHTML=(S.pre?`<code>${esc(S.pre)}</code><br>`:'')+chipsHTML(S.typed);
    q('steps').innerHTML=S.steps.map((x,k)=>`<li class="${k===i?'on':k<i?'dn':'todo'}"><span class="rs-a ${x.who}">${x.who}</span><span>${x.t}</span></li>`).join('');
    q('perm').innerHTML=perm(s.perm,s.perms);
    q('file').innerHTML=BK.map((l,k)=>{const n=k+1;let c='';if(n===1&&s.bang==='read')c='bang';else if(n===1&&s.bang==='comment')c='dim';else if(s.lines&&s.lines.includes(n))c='run';
      return `<span class="${c}">${n===1&&s.bang==='read'?'<b>#!</b>'+esc(l.slice(2))+' <em>the kernel reads it</em>':hl(l)}</span>`}).join('\n');
    q('out').innerHTML=`<span class="db-pr">$</span> ${esc(S.typed.map(t=>t[0]).join(' '))}\n`+(s.out?'backing up\ndone':s.err?'<span class="db-err">bash: ./backup.sh: Permission denied</span>':'');
    q('x').innerHTML=s.x;q('b').textContent='step '+(i+1)+' / '+S.steps.length});
  root.querySelectorAll('[data-r="seg"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-r="seg"] button').forEach(x=>x.classList.toggle('on',x===b));sc=b.dataset.v;go(0)}));
  go(0)}

/* ================================================================ $(command) */
const SB={
  count:{before:'count=',part:'$(wc -l < fruits.txt)',after:'',inner:[['wc','cmd'],['-l',''],['<','redir'],['fruits.txt','redir']],printed:'7\n',result:[['count=7','new']],out:''},
  date:{before:'echo "today is ',part:'$(date +%A)',after:'"',inner:[['date','cmd'],['+%A','']],printed:'Thursday\n',result:[['echo','cmd'],['today is Thursday','new']],out:'today is Thursday'},
  ls:{before:'echo ',part:'$(ls *.txt)',after:'',inner:[['ls','cmd'],['fruits.txt','new'],['notes.txt','new'],['words.txt','new']],printed:'fruits.txt\nnotes.txt\nwords.txt\n',result:[['echo','cmd'],['fruits.txt','new'],['notes.txt','new'],['words.txt','new']],out:'fruits.txt notes.txt words.txt'},
};
const SBX=[
  'Before running the line, the shell finds the <code>$(...)</code>.',
  'It starts a <b>copy of itself</b> (a <i>subshell</i>) that runs the command, with its parameters.',
  'The output of the command is <b>captured</b>, not shown; the last <i>newline</i> is removed.',
  'The output takes the place of <code>$(...)</code>, as text; then the line runs.'];
function wSubst(root){
  let sc='count';
  root.innerHTML=`<div class="wd sb"><div class="wd-h"><div><h3>The shell runs a line with <code>$( )</code></h3><p>The command inside runs first, in a copy of bash; its output becomes text in the line.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c"><div class="seg" data-r="seg"><button type="button" data-v="count" class="on">count=$(wc …)</button><button type="button" data-v="date">"… $(date +%A)"</button><button type="button" data-v="ls">echo $(ls *.txt)</button></div>${NAV()}</div>
  <div class="ps-x" data-r="x"></div><div class="sb-b" data-r="body"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const go=stepper(root,()=>4,i=>{const S=SB[sc];
    const box=(t,body,on,hid)=>`<div class="sb-box${on?' on':''}${hid?' hid':''}"><div class="sb-t">${t}</div>${body}</div>`;
    q('body').innerHTML=
      box('<code>bash</code> – the shell',`<code class="sb-line">${hl(S.before)}<mark class="db-part">${hl(S.part)}</mark>${hl(S.after)}</code>`+(i===3?`<div class="sb-then"><span class="db-lab">then runs</span>${chipsHTML(S.result)}</div>`:''),i===0||i===3)+
      `<div class="sb-mid${i<1?' hid':''}"><span class="sb-ar${i===1?' on':''}">↓ starts a <b>copy</b> of itself</span><span class="sb-ar up${i>=2?' on':''}${i<2?' hid':''}">↑ back as <b>text</b></span></div>`+
      `<div class="sb-row${i<1?' hid':''}">`+box('<code>bash</code> – a copy (a <i>subshell</i>)',chipsHTML(S.inner),i===1)+`<span class="sb-pipe">stdout →</span>`+box('captured',`<pre>${esc(i>=2?S.printed.replace(/\n$/,''):S.printed)}${i===1?'':''}</pre>${i>=2?'<span class="sb-nl">last newline removed</span>':''}`,i===2,i<2)+`</div>`+
      (i===3&&S.out?`<pre class="sh sb-sh"><span class="p">$</span> <span class="c">${hl(S.before+S.part+S.after)}</span>\n<span class="o">${esc(S.out)}</span></pre>`:'');
    q('x').innerHTML=SBX[i]+(i===3&&sc==='ls'?' Unquoted, the <i>newlines</i> of the output separate words, like spaces.':'');q('b').textContent='step '+(i+1)+' / 4'});
  root.querySelectorAll('[data-r="seg"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-r="seg"] button').forEach(x=>x.classList.toggle('on',x===b));sc=b.dataset.v;go(0)}));
  go(0)}

/* ================================================================ case patterns */
const GL=[['apple','exactly this text'],['a*','<code>a</code>, then any text (or none)'],['*.txt','any text, then <code>.txt</code>'],['???','exactly three characters'],['[yY]*','<code>y</code> or <code>Y</code>, then any text'],['apple|kiwi','<code>apple</code> <b>or</b> <code>kiwi</code> (only in <code>case</code>)'],['*','any text: the default branch']];
function wGlobs(root){
  const words=['apple','apples','Apple','banana','notes.txt','fig','kiwi','yes','Y','no'];
  root.innerHTML=`<div class="wd gl"><div class="wd-h"><div><h3>Which pattern matches?</h3><p>Type a word: every pattern says ✅ or ❌, and <code>case</code> picks the <b>first</b> one that matches, top to bottom.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls"><label class="gl-in"><span>the word</span><input data-r="w" value="apple" spellcheck="false" autocapitalize="off"></label><div class="sp-pre"><span class="chl">try:</span>${words.map(w=>`<button type="button" class="chip" data-g="${esc(w)}">${esc(w)}</button>`).join('')}</div></div>
  <div class="ps-x" data-r="x"></div>
  <div class="gl-b"><table class="t gl-t"><tr><th>Pattern</th><th>Means</th><th>Matches?</th></tr><tbody data-r="rows"></tbody></table><div><div class="db-h">the case</div><pre class="sh gl-code" data-r="code"></pre><div class="db-h">glob or regex?</div><div class="gl-rx" data-r="rx"></div></div></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const draw=()=>{const w=q('w').value;let first=-1;
    const res=GL.map(([p],k)=>{const ok=p.split('|').some(x=>B.patRx(x).test(w));if(ok&&first<0)first=k;return ok});
    q('rows').innerHTML=GL.map(([p,m],k)=>`<tr class="${k===first?'pick':''}"><td><code>${esc(p)}</code></td><td>${m}</td><td class="${res[k]?'y':'n'}">${res[k]?'✅':'❌'}${k===first?' <b>case picks it</b>':''}</td></tr>`).join('');
    q('code').innerHTML=hl('case "'+w+'" in')+'\n'+GL.map(([p],k)=>`<span class="${k===first?'cur':''}">    ${hl(p+') echo "'+(k+1)+'" ;;')}</span>`).join('\n')+'\n'+hl('esac');
    const g=B.patRx('n.*').test(w),r=/n.*/.test(w);
    q('rx').innerHTML=`<div><code>n.*</code> as a <b>glob</b> (case): <code>n</code>, a dot, any text → ${g?'✅':'❌'}</div><div><code>n.*</code> as a <b>regex</b> (grep): <code>n</code> anywhere, then any characters → ${r?'✅':'❌'}</div>`;
    q('x').innerHTML=first<0?'No pattern matches.':first===GL.length-1?'Only <code>*</code> matches: the default branch, always <b>last</b>.':`<code>${esc(w)}</code> matches <code>${esc(GL[first][0])}</code> first: <code>;;</code> jumps after <code>esac</code>, the patterns below are not tried.`;
    q('b').textContent=res.filter(Boolean).length+' patterns match'};
  q('w').addEventListener('input',draw);
  root.querySelectorAll('[data-g]').forEach(b=>b.addEventListener('click',()=>{q('w').value=b.dataset.g;draw()}));
  draw()}

/* ================================================================ $(( )) and bc */
function wCalc(root){
  const ex=['7 / 2','7 % 2','2 ** 10','3 > 2','1 && 0','1 << 4','5 > 3 ? 10 : 20','(2 + 3) * 4','a * b + 1','x += 2','3.5 * 2'];
  let vars={a:'2',b:'3',x:'5'},bm='';
  root.innerHTML=`<div class="wd ca"><div class="wd-h"><div><h3>The same expression, two calculators</h3><p><code>$(( ))</code> is bash itself: integers only. <code>bc</code> is a program that reads the expression from <code>stdin</code>: decimals too.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls"><label class="gl-in ca-in"><span>expression</span><input data-r="e" value="7 / 2" spellcheck="false" autocapitalize="off"></label><div class="sp-pre"><span class="chl">try:</span>${ex.map(e=>`<button type="button" class="chip" data-e="${esc(e)}">${esc(e)}</button>`).join('')}</div></div>
  <div class="ca-b"><div><div class="db-h">bash: <code>$(( ))</code></div><pre class="sh" data-r="a"></pre></div><div><div class="db-h ca-bh"><span>the program <code>bc</code></span><span class="seg" data-r="bm"><button type="button" data-v="" class="on">bc</button><button type="button" data-v="l">bc -l</button><button type="button" data-v="s">scale=2</button></span></div><pre class="sh" data-r="c"></pre></div></div>
  <div class="ps-x ca-x" data-r="x"></div></div>`;
  const q=s=>root.querySelector(`[data-r="${s}"]`);
  const draw=()=>{const e=q('e').value;const r=B.calc(e,vars);
    const pre=`<span class="k"># a=${vars.a} b=${vars.b} x=${vars.x}</span>\n`;
    q('a').innerHTML=pre+`<span class="p">$</span> <span class="c">${hl('echo $(('+e+'))')}</span>\n`+(r.error?`<span class="db-err">${esc(r.error)}</span>`:`<span class="o">${esc(r.value)}</span>`);
    const bcIn=e.replace(/\b[abx]\b/g,m=>vars[m]);const okBc=!/<<|>>|\?|[^=!<>]=(?!=)|\+\+|--/.test(bcIn);
    const bExpr=(bm==='s'?'scale=2; ':'')+bcIn.replace(/\*\*/g,'^');
    const b=okBc?B.bc(bExpr+'\n',bm==='l'):{out:'',err:'(standard_in) 1: syntax error\n'};
    q('c').innerHTML=`<span class="p">$</span> <span class="c">${hl('echo "'+bExpr+'" | bc'+(bm==='l'?' -l':''))}</span>\n`+(b.err?`<span class="db-err">${esc(b.err.trim())}</span>`:`<span class="o">${esc(b.out.trim())}</span>`);
    q('x').innerHTML=r.error&&/\./.test(e)?'<b>No decimals</b> in bash: <code>3.5</code> is not a number for it, the error is at <code>.5</code>. <code>bc</code> computes it.':/\//.test(e)&&!r.error?'Integer division: the decimals are <b>cut</b>, not rounded. <code>bc</code> too, by default: <code>scale</code> (the number of decimals) is <code>0</code>. Set it in the text, <code>scale=2;</code>, or start <code>bc -l</code>: 20 decimals, and math functions such as <code>s(x)</code> (sine) and <code>sqrt(x)</code>.':/\+=|\+\+|--|-=/.test(e)&&!r.error?'<code>+=</code> <b>changes</b> the variable: after it, <code>x</code> is '+esc(r.vars.x)+'. Only bash can do that, <code>bc</code> gets only text.':/[<>=!]=?|&&|\|\|/.test(e)&&!/<</.test(e)?'A comparison is <code>1</code> (true) or <code>0</code> (false) here – the opposite of exit codes.':'Inside <code>(( ))</code> the variables need no <code>$</code>; the operators are the ones of C.';
    q('b').textContent=r.error?'bash: error':'= '+r.value};
  q('e').addEventListener('input',draw);
  root.querySelectorAll('[data-r="bm"] button').forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll('[data-r="bm"] button').forEach(x=>x.classList.toggle('on',x===b));bm=b.dataset.v;draw()}));
  root.querySelectorAll('[data-e]').forEach(b=>b.addEventListener('click',()=>{q('e').value=b.dataset.e;draw()}));
  draw()}

const W=window.DK_W||(window.DK_W={});
Object.assign(W,{dbg:wDbg,lab:wLab,split:wSplit,pit:wPit,runsc:wRunsc,subst:wSubst,globs:wGlobs,calc:wCalc});
})();
