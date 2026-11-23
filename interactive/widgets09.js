/* ISO lecture 09 widgets: the step-by-step pictures drawn by build_09.py (data-w="scene"), the hub / switch
   (data-w="star"), the mask calculator (data-w="mask"), the routing table (data-w="route"), the tcpdump filters
   (data-w="filter"); and the simulated laptop of the demo terminal (profile '09'): ip, ping, traceroute, nmcli, host,
   dig, resolvectl, ss, netstat, curl, tcpdump, sudo, arp, with the side panels "net" and "trouble" and the missions */
(()=>{'use strict';
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const W=window.DK_W||(window.DK_W={});
const Q=root=>s=>root.querySelector(`[data-r="${s}"]`);
/* the arrow heads of the pictures drawn by build_09.py, defined once for the page (first in the body, visible) */
if(typeof document!=='undefined')(()=>{const C={navy:'#004d65',teal:'#00838f',orange:'#d79b00',hl:'#e65100',green:'#2e7d46',red:'#b85450',grey:'#7d8d93',blue:'#6c8ebf'};
  const d=document.createElement('div');d.innerHTML=`<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>${Object.entries(C).map(([k,c])=>`<marker id="f3-${k}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${c}"/></marker>`).join('')}</defs></svg>`;
  document.body.insertBefore(d.firstChild,document.body.firstChild)})();

/* ---------- keep a widget where it is on the screen while a button redraws it: whatever moves the page (a step
   of another height, the browser re-anchoring the scroll), the widget is put back where the reader saw it ---------- */
function keep(root,fn){
  const top=()=>root.getBoundingClientRect().top, t0=top(), y0=scrollY;
  fn();
  const fix=()=>{const d=top()-t0;if(Math.abs(d)>2)window.scrollTo({top:scrollY+d,behavior:'instant'})};
  fix();requestAnimationFrame(fix);setTimeout(fix,120);setTimeout(()=>{if(Math.abs(scrollY-y0)>40&&Math.abs(top()-t0)>40)fix()},400);
}
if(typeof document!=='undefined')document.addEventListener('click',e=>{const b=e.target.closest&&e.target.closest('.wd button');const w=b&&b.closest('[data-w]');
  if(w&&!b.closest('.term,.tryjump'))keep(w,()=>{})},true);

/* ---------- shared: Back, dots, Next (as procs.js) ---------- */
const NAV=()=>`<div class="ps-nav" data-r="nav"><button type="button" class="btn ghost" data-r="prev">← Back</button><span class="pdots" data-r="dots" aria-hidden="true"></span><button type="button" class="btn" data-r="next">Next →</button></div>`;
function stepper(root,count,draw){
  let i=0;const q=Q(root);
  const go=k=>{i=Math.max(0,Math.min(count()-1,k));draw(i);
    q('dots').innerHTML=Array.from({length:count()},(_,k)=>`<i class="${k===i?'on':k<i?'dn':''}"></i>`).join('');
    q('prev').disabled=i===0;q('next').disabled=i===count()-1;q('nav').style.display=count()<2?'none':''};
  q('prev').addEventListener('click',()=>go(i-1));
  q('next').addEventListener('click',()=>go(i+1));
  return go;
}
const segHTML=(name,labels,on)=>`<div class="seg" data-seg="${name}">${labels.map((l,i)=>`<button type="button" data-v="${i}" class="${i===on?'on':''}">${esc(l)}</button>`).join('')}</div>`;
function onSeg(root,name,cb){root.querySelectorAll(`[data-seg="${name}"] button`).forEach(b=>b.addEventListener('click',()=>{root.querySelectorAll(`[data-seg="${name}"] button`).forEach(x=>x.classList.toggle('on',x===b));cb(+b.dataset.v)}))}

/* ---------- the scene: pictures drawn at build time, one <template> per step ---------- */
W.scene=root=>{
  const T=[...root.querySelectorAll('template')].map(t=>({s:+t.dataset.s,x:t.dataset.x,c:t.dataset.c,html:t.innerHTML}));
  const labels=(root.dataset.labels||'').split('|'), layout=root.dataset.layout||'side';
  let sc=0;
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>${esc(root.dataset.title||'')}</h3><p>${root.dataset.sub||''}</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls ps-c">${labels.length>1?segHTML('sc',labels,0):'<span></span>'}${NAV()}</div>
  <div class="ps-x" data-r="x" aria-live="polite"></div><div class="sc-b" data-r="body"></div></div>`;
  const q=Q(root), steps=()=>T.filter(t=>t.s===sc);
  /* every step has its own height: the widget never gets shorter on Next / Back (a shorter page makes the browser
     scroll up); it keeps the height of the tallest step shown so far, until its width changes */
  let cur=0, w0=0;
  const hold=()=>{const b=q('body'),x=q('x'),w=root.offsetWidth;if(!w)return;
    if(w!==w0){w0=w;b.style.minHeight=x.style.minHeight=''}
    b.style.boxSizing=x.style.boxSizing='border-box';b.style.minHeight=b.offsetHeight+'px';x.style.minHeight=x.offsetHeight+'px'};
  const go=stepper(root,()=>steps().length,i=>{cur=i;const st=steps()[i];q('x').innerHTML=st.x;const b=q('body');b.className='sc-b '+layout+' '+st.c;b.innerHTML=st.html;hold();
    q('b').textContent=steps().length>1?`step ${i+1} / ${steps().length}`:labels[sc]});
  onSeg(root,'sc',v=>{sc=v;go(0)});
  go(0);
};

/* ---------- small SVG drawings, the same as the Python ones ---------- */
const NAVY='#004d65',HL='#e65100',OKC='#2e7d46',BADC='#c62828';
const svgT=(x,y,s,size=15,w=400,fill='#1f2d33',a='middle',mono=false)=>`<text x="${x}" y="${y}" text-anchor="${a}" style="font:${w} ${size}px ${mono?"'SF Mono',Menlo,Consolas,monospace":'system-ui,-apple-system,sans-serif'}" fill="${fill}">${esc(s)}</text>`;
const laptop=(x,y,on)=>{const st=on?HL:NAVY,sw=on?2.6:2;return `<rect x="${x-20}" y="${y-16}" width="40" height="26" rx="3" fill="#e8f1f3" stroke="${st}" stroke-width="${sw}"/><rect x="${x-15}" y="${y-11}" width="30" height="16" rx="1" fill="#bfdde3"/><path d="M${x-26},${y+14} h52 l-4,5 h-44 z" fill="${st}"/>`};
const box=(x,y,kind)=>{const c=kind==='hub'?'#6c8ebf':'#b85450';let b=`<rect x="${x-34}" y="${y-16}" width="68" height="32" rx="7" fill="${c}"/>`;
  if(kind==='hub')for(let k=0;k<5;k++)b+=`<circle cx="${x-20+k*10}" cy="${y}" r="2.6" fill="#fff"/>`;
  else b+=`<path d="M${x-19},${y-6} h34 m-7,-5 l7,5 l-7,5" fill="none" stroke="#fff" stroke-width="2.2"/><path d="M${x+19},${y+6} h-34 m7,-5 l-7,5 l7,5" fill="none" stroke="#fff" stroke-width="2.2"/>`;return b};
const mk=(x,y,ok)=>`<circle cx="${x}" cy="${y}" r="11" fill="${ok?OKC:BADC}"/><path d="${ok?`M${x-5},${y} l3.5,4 l6.5,-8`:`M${x-4.5},${y-4.5} l9,9 M${x+4.5},${y-4.5} l-9,9`}" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round"/>`;

/* ---------- hub and switch ---------- */
const HOSTS=[{n:'Ana',mac:'5c:8f:2a:91:d4:07',x:70,y:62},{n:'Bogdan',mac:'e4:3b:71:0c:9a:52',x:70,y:240},{n:'Carla',mac:'08:d1:6e:b3:47:ac',x:450,y:62},{n:'Dan',mac:'f0:9e:4a:c2:16:3d',x:450,y:240}];
const CX=260,CY=151,BC='ff:ff:ff:ff:ff:ff';
W.star=root=>{
  const dev=root.dataset.dev==='hub'?'hub':'switch', isSw=dev==='switch', free=root.dataset.mode==='free';
  /* the guided steps, as in the slides; the state is replayed from the start for every step */
  const SCRIPT=isSw?[{a:'none'},{a:'send',f:0,t:2},{a:'send',f:2,t:0},{a:'send',f:0,t:2},{a:'send',f:3,t:4},{a:'two'}]
                   :[{a:'none'},{a:'send',f:0,t:2},{a:'send',f:0,t:4},{a:'two'}];
  let from=0, to=2, S=null, log=[];
  const fresh=()=>({table:[],newRows:[],frames:0,last:null,x:''});
  const title=free?(isSw?'Try it yourself: send frames through a switch':'Try it yourself: send frames through a hub'):(isSw?'Step by step: how a switch learns':'Step by step: a hub');
  const sub=free?'Choose who sends and to whom, press <b>Send</b>, then <b>Reply</b>, again and again: each frame is added to the list below.':'Press <b>Next</b>: one frame at a time, as in the slides.';
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>${title}</h3><p>${sub}</p></div><span class="badge" data-r="b"></span></div>
  ${free?`<div class="ctrls st-c">
   <div class="st-g"><span class="st-l">from</span>${segHTML('from',HOSTS.map(h=>h.n),0)}</div>
   <div class="st-g"><span class="st-l">to</span>${segHTML('to',HOSTS.map(h=>h.n).concat('everyone'),2)}</div>
   <div class="st-g"><button type="button" class="btn" data-r="send">Send →</button><button type="button" class="btn ghost" data-r="reply" disabled>↩ Reply</button></div>
</div>`
  :`<div class="ctrls ps-c"><span class="st-l">${isSw?'the switch learns':'the hub repeats'}</span>${NAV()}</div>`}
  <div class="ps-x" data-r="x" aria-live="polite"></div>
  <div class="st-b"><div data-r="pic"></div><div data-r="tab"></div></div>
  ${free?`<div class="st-log"><div class="st-lh"><span class="sc-h">Frames sent</span><span class="st-g st-more"><button type="button" class="chip" data-r="two">${isSw?'Ana + Bogdan → Carla, at once':'Ana + Dan, at once'}</button><button type="button" class="chip" data-r="clr">${isSw?'restart the switch':'start again'}</button></span></div><ol data-r="log"><li class="st-none">none yet</li></ol></div>`:''}</div>`;
  const q=Q(root);
  const pt=(i,t)=>[HOSTS[i].x+(CX-HOSTS[i].x)*t,HOSTS[i].y+(CY-HOSTS[i].y)*t];
  /* an arrow on the wire of host i; the head is a plain triangle (no SVG markers) */
  const arrow=(i,inward,c)=>{const [a,b]=inward?[pt(i,.2),pt(i,.66)]:[pt(i,.66),pt(i,.2)];const col={g:OKC,r:BADC,n:NAVY,o:HL}[c];
    const dx=b[0]-a[0],dy=b[1]-a[1],L=Math.hypot(dx,dy),ux=dx/L,uy=dy/L,H=14,W2=8,e=[b[0]-ux*H,b[1]-uy*H];
    const p=[[b[0],b[1]],[e[0]-uy*W2,e[1]+ux*W2],[e[0]+uy*W2,e[1]-ux*W2]].map(v=>v[0].toFixed(1)+','+v[1].toFixed(1)).join(' ');
    return `<line x1="${a[0].toFixed(1)}" y1="${a[1].toFixed(1)}" x2="${e[0].toFixed(1)}" y2="${e[1].toFixed(1)}" stroke="${col}" stroke-width="5" stroke-linecap="round"/><polygon points="${p}" fill="${col}"/>`};
  const env=(i,c)=>{const [x,y]=pt(i,.43);const col=c==='n'?NAVY:HL;
    return `<g transform="translate(${(x-13).toFixed(1)},${(y-9).toFixed(1)})"><rect width="26" height="18" rx="2" fill="#fff" stroke="${col}" stroke-width="1.8"/><path d="M1,1 L13,10 L25,1" fill="none" stroke="${col}" stroke-width="1.6"/></g>`};
  const name=m=>m===BC?'everyone':HOSTS.find(h=>h.mac===m).n;
  /* one action on the state s: returns the explanation and a short line for the log */
  function act(s,a){
    s.newRows=[];
    const learn=i=>{const m=HOSTS[i].mac;if(isSw&&!s.table.some(r=>r.mac===m)){s.table.push({mac:m,port:i+1});s.newRows.push(s.table.length-1);return true}return false};
    if(a.a==='none'){s.last=null;return[isSw?'The switch was just turned on: its <b>MAC table is empty</b>. It knows nobody yet.':'A hub: four computers, one cable each, one central device.','']}
    if(a.a==='two'){s.frames+=2;
      if(!isSw){s.last={boom:true,frames:[],marks:[]};return['Ana and Dan send <b>at the same time</b>: on a hub the signals mix, a <b>collision</b>; everyone receives garbage. The rule of the hub, <i>CSMA/CD</i>: listen before sending; on a collision stop, wait a random time, try again.','Ana and Dan at once: <b>collision</b>']}
      learn(0);learn(1);const known=s.table.some(r=>r.mac===HOSTS[2].mac);
      s.last={frames:[{from:0,dst:HOSTS[2].mac,c:'o',out:known?[2]:[2,3]},{from:1,dst:HOSTS[2].mac,c:'n',out:[]}],marks:[[2,true]],queue:1};
      return known?['Ana <b>and</b> Bogdan send to Carla at the same time. Each port is separate: <b>no collision</b>. Port 3 sends Ana\'s frame; Bogdan\'s <b>waits in the queue</b> of port 3 and goes next.','Ana and Bogdan → Carla: one waits in the <b>queue</b> of port 3']
                  :['Ana and Bogdan send to Carla at the same time: no collision, each port has its <b>queue</b>. Carla is not in the table yet, so both frames are flooded, one after the other.','Ana and Bogdan → Carla: flooded, one after the other']}
    const f=a.f, t=a.t, all=t===4, dmac=all?BC:HOSTS[t].mac, others=[0,1,2,3].filter(j=>j!==f), fr={from:f,dst:dmac,c:'o',out:[]}, marks=[];
    s.frames++;
    const who=`${HOSTS[f].n} → ${all?'everyone':HOSTS[t].n}`;
    if(!isSw){fr.out=others;others.forEach(j=>marks.push([j,all||j===t]));s.last={frames:[fr],marks};
      return all?[`${HOSTS[f].n} sends a <b>broadcast</b>, to <code>ff:ff:ff:ff:ff:ff</code>: the hub sends it on all the ports and <b>everyone keeps it</b>.`,who+': all ports, everyone keeps it']
                :[`${HOSTS[f].n} sends a frame to ${HOSTS[t].n}. The hub copies the <b>bits</b> on <b>all</b> the ports. Every card reads the destination MAC: only ${HOSTS[t].n} keeps it, the others <b>drop</b> it.`,who+': all ports, only '+HOSTS[t].n+' keeps it']}
    const nw=learn(f), row=!all&&s.table.find(r=>r.mac===dmac);
    const l1=nw?`<b>① learn</b>: the source MAC is ${HOSTS[f].n}'s, it came on port ${f+1}: a new row. `:`<b>① learn</b>: ${HOSTS[f].n} is already in the table. `;
    let l2,lg;
    if(all){fr.out=others;others.forEach(j=>marks.push([j,true]));l2=`<b>② look up</b> <code>ff:ff:ff:ff:ff:ff</code>: a <b>broadcast</b>, out on all the other ports; everyone keeps it.`;lg='broadcast, all ports'}
    else if(row){fr.out=[t];marks.push([t,true]);l2=`<b>② look up</b> ${HOSTS[t].n}: in the table, port ${row.port}: out <b>only on port ${row.port}</b>. The others see nothing.`;lg='only port '+row.port}
    else{fr.out=others;others.forEach(j=>marks.push([j,j===t]));l2=`<b>② look up</b> ${HOSTS[t].n}: <b>not in the table</b>, so out on all the other ports (<b>flooding</b>); only ${HOSTS[t].n} keeps it.`;lg='flooded: '+HOSTS[t].n+' unknown'}
    s.last={frames:[fr],marks};return[l1+l2,who+': '+lg+(nw?` · learned ${HOSTS[f].n} = port ${f+1}`:'')];
  }
  let hw=0;
  const holdH=()=>{const t=q('tab'),x=q('x'),w=root.offsetWidth;if(!w)return;if(w!==hw){hw=w;t.style.minHeight=x.style.minHeight=''}
    t.style.boxSizing=x.style.boxSizing='border-box';t.style.minHeight=t.offsetHeight+'px';x.style.minHeight=x.offsetHeight+'px'};
  function draw(){
    const s=S, L=s.last;let g='';
    HOSTS.forEach(h=>{g+=`<line x1="${h.x}" y1="${h.y}" x2="${CX}" y2="${CY}" stroke="#9aa9ae" stroke-width="3"/>`});
    if(L){if(L.boom)HOSTS.forEach((h,i)=>{g+=arrow(i,false,'r')});else for(const f of L.frames){g+=arrow(f.from,true,f.c);f.out.forEach(j=>{g+=arrow(j,false,f.c)})}}
    const senders=L&&!L.boom?L.frames.map(f=>f.from):L&&L.boom?[0,3]:[];
    HOSTS.forEach((h,i)=>{g+=laptop(h.x,h.y-6,senders.includes(i));g+=svgT(h.x,h.y+34,h.n,15,700);g+=svgT(h.x,h.y+51,h.mac,12,400,'#5b6b71','middle',true);
      if(isSw){const [px,py]=pt(i,.8);g+=`<rect x="${(px-9).toFixed(1)}" y="${(py-9).toFixed(1)}" width="18" height="18" rx="3" fill="#37474f"/>`+svgT(px.toFixed(1),(py+4.5).toFixed(1),String(i+1),11.5,800,'#fff')}});
    g+=box(CX,CY,dev)+svgT(CX,CY+(isSw?54:34),isSw?'SWITCH · layer 2':'HUB · layer 1',13,800,'#5b6b71');
    if(L&&L.boom)g+=`<circle cx="${CX}" cy="${CY-34}" r="16" fill="#ffd54f" stroke="${BADC}" stroke-width="2"/>`+svgT(CX,CY-29,'!',18,900,BADC);
    if(L&&!L.boom){for(const f of L.frames)g+=env(f.from,f.c);for(const [j,ok] of L.marks){const h=HOSTS[j];g+=mk(h.x+(h.x<CX?42:-42),h.y-26,ok)}}
    if(L&&L.queue){g+=svgT(392,150,'queue of port 3',11.5,700,'#5b6b71');for(let k=0;k<3;k++)g+=`<rect x="${362+k*22}" y="158" width="18" height="14" rx="2" fill="${k<L.queue?'#ffe6cc':'#fff'}" stroke="${k<L.queue?'#d79b00':'#9aa9ae'}" stroke-width="1.4"/>`}
    q('pic').innerHTML=`<svg class="st-svg" viewBox="0 0 520 300" role="img" aria-label="Four computers connected to a ${dev}">${g}</svg>`;
    const fr=L&&!L.boom?L.frames.map(f=>`<tr><td>${f.c==='n'?'<b style="color:'+NAVY+'">frame 2</b>':'<b style="color:'+HL+'">frame</b>'}</td><td class="st-fr">${HOSTS[f.from].n} → ${name(f.dst)}<br><small>from <code>${HOSTS[f.from].mac.slice(0,8)}…</code> to <code>${f.dst===BC?BC:f.dst.slice(0,8)+'…'}</code></small></td></tr>`).join(''):'';
    q('tab').innerHTML=(fr?`<div class="sc-h">The frame</div><table class="t sc-t">${fr}</table>`:'')+(isSw?
      `<div class="sc-h">The MAC table of the switch</div><table class="t sc-t"><tr><th>MAC address</th><th>port</th></tr>${s.table.length?s.table.map((r,k)=>`<tr class="${s.newRows.includes(k)?'ch':''}"><td><code>${r.mac}</code> <small>${name(r.mac)}</small></td><td>${r.port}</td></tr>`).join(''):'<tr><td colspan="2"><em>empty</em></td></tr>'}</table>`:
      '<div class="sc-h">The hub</div><p class="sc-n">No MAC table: a hub repeats the <b>bits</b> on every port, it does not read the frames.</p>');
    q('x').innerHTML=s.x;holdH();
    if(free){q('log').innerHTML=log.length?log.map((l,k)=>`<li class="${k===log.length-1?'on':''}">${l}</li>`).join(''):'<li class="st-none">none yet</li>';q('log').scrollTop=q('log').scrollHeight;
      q('b').textContent=isSw?S.table.length+' / 4 learned · '+S.frames+' frames':S.frames+' frames'}
  }
  if(!free){
    const go=stepper(root,()=>SCRIPT.length,i=>{S=fresh();for(let k=0;k<=i;k++)S.x=act(S,SCRIPT[k])[0];draw();q('b').textContent=`step ${i+1} / ${SCRIPT.length}`});
    go(0);return;
  }
  let pair=null;    // the last frame from one computer to one computer: Reply sends it back
  const setSeg=(seg,v)=>root.querySelectorAll(`[data-seg="${seg}"] button`).forEach(b=>b.classList.toggle('on',+b.dataset.v===v));
  const replyBtn=()=>{const b=q('reply');b.disabled=!pair;b.title=pair?`${HOSTS[pair.t].n} answers ${HOSTS[pair.f].n}`:'send a frame first'};
  const run=a=>{const [x,l]=act(S,a);S.x=x;if(l)log.push(l);pair=a.a==='send'&&a.t!==4?{f:a.f,t:a.t}:null;draw();replyBtn()};
  onSeg(root,'from',v=>{from=v});
  onSeg(root,'to',v=>{to=v});
  q('send').addEventListener('click',()=>{if(from===to){S.x=`${HOSTS[from].n} cannot send to ${HOSTS[from].n}: choose another destination.`;S.last=null;draw();return}run({a:'send',f:from,t:to})});
  q('two').addEventListener('click',()=>run({a:'two'}));
  q('reply').addEventListener('click',()=>{if(!pair)return;const f=pair.t,t=pair.f;from=f;to=t;setSeg('from',f);setSeg('to',t);run({a:'send',f,t})});
  q('clr').addEventListener('click',()=>{S=fresh();log=[];pair=null;replyBtn();S.x=isSw?'The switch restarted: its MAC table is <b>empty</b> again.':'Start again.';draw()});
  S=fresh();S.x=isSw?'Your own switch, its MAC table <b>empty</b>. Choose <b>from</b> and <b>to</b>, then <b>Send</b>; <b>Reply</b> sends a frame back. Watch the table fill in.':'Choose <b>from</b> and <b>to</b>, then <b>Send</b>.';
  draw();
};

/* ---------- IPv4 helpers ---------- */
const ip2n=s=>{const m=/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(String(s).trim());if(!m)return null;const o=m.slice(1).map(Number);if(o.some(v=>v>255))return null;return((o[0]<<24)>>>0)+(o[1]<<16)+(o[2]<<8)+o[3]};
const n2ip=n=>[n>>>24,(n>>>16)&255,(n>>>8)&255,n&255].join('.');
const maskN=p=>p===0?0:(0xffffffff<<(32-p))>>>0;
const inNet=(ip,net,p)=>((ip&maskN(p))>>>0)===((net&maskN(p))>>>0);

/* ---------- the mask calculator ---------- */
W.mask=root=>{
  const P=[['192.168.1.105',24],['172.16.45.130',20],['10.1.2.3',8],['141.85.220.33',16]];
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>The mask, bit by bit</h3><p>Type an address, move the prefix: the <b style="color:#a86f00">network bits</b> and the <b style="color:#2e7d46">host bits</b>.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls mk-c"><label>address <input type="text" data-r="ip" value="192.168.1.105" spellcheck="false" aria-label="IP address"></label>
  <label>prefix <input type="range" min="1" max="32" value="24" data-r="p" aria-label="prefix length"><span class="mk-n" data-r="pn">/24</span></label>
  <div class="tf-ch">${P.map(([a,p])=>`<button type="button" class="chip" data-p="${a}/${p}">${a}/${p}</button>`).join('')}</div></div>
  <div class="mk-b" data-r="out"></div>
  <div class="mk-same"><span>Is</span><input type="text" data-r="o" value="192.168.1.20" spellcheck="false" aria-label="another address"><span>in the same network?</span><span class="mk-v" data-r="v"></span></div></div>`;
  const q=Q(root);
  const row=(k,n,p,dec)=>{const bits=n.toString(2).padStart(32,'0');let h='';for(let B=0;B<4;B++){h+='<span class="mk-by">';for(let i=B*8;i<B*8+8;i++)h+=`<i class="${i>=p?'h':''}${i===p&&p%8?' cut':''}">${bits[i]}</i>`;h+='</span>'}
    return `<div class="mk-row"><span class="mk-k">${k}</span><span class="mk-bits">${h}</span><span class="mk-d">${dec}</span></div>`};
  function draw(){
    const p=+q('p').value;q('pn').textContent='/'+p;
    let v=q('ip').value.trim();const m=/^(.+)\/(\d+)$/.exec(v);if(m&&+m[2]>=1&&+m[2]<=32){q('p').value=m[2];q('ip').value=m[1];return draw()}
    const ip=ip2n(v);
    if(ip===null){q('out').innerHTML='<p class="mk-err">Not an IPv4 address: four numbers from 0 to 255, with dots, like <code>192.168.1.105</code>.</p>';q('v').textContent='';q('b').textContent='?';return}
    const M=maskN(p),net=(ip&M)>>>0,bc=(net|(~M>>>0))>>>0;
    const hosts=p<=30?(2**(32-p)-2):null;
    q('out').innerHTML=row('IP address',ip,p,n2ip(ip))+row('mask',M,p,n2ip(M))+row('network',net,p,n2ip(net))+row('broadcast',bc,p,n2ip(bc))+
      `<div class="mk-f"><span><b>mask:</b> ${p} bits of <code>1</code> = <code>${n2ip(M)}</code></span><span><b>network:</b> <code>${n2ip(net)}/${p}</code> (host bits all <code>0</code>)</span>
       <span><b>broadcast:</b> <code>${n2ip(bc)}</code> (host bits all <code>1</code>)</span><span><b>devices:</b> ${hosts!==null?`<code>${n2ip(net+1)}</code> to <code>${n2ip(bc-1)}</code>: <b>${hosts.toLocaleString('en')}</b>`:p===31?'2 addresses: a link between two routers':'one address: a single computer'}</span></div>`;
    q('b').textContent=n2ip(net)+'/'+p;
    const o=ip2n(q('o').value);const V=q('v');
    if(o===null){V.className='mk-v';V.textContent='(type an address)';return}
    const same=((o&M)>>>0)===net;V.className='mk-v '+(same?'ok':'no');
    V.textContent=same?`✓ yes: its network is ${n2ip(net)} too, they talk directly`:`✗ no: its network is ${n2ip((o&M)>>>0)}; the packet goes through a router`;
  }
  q('ip').addEventListener('input',draw);q('p').addEventListener('input',draw);q('o').addEventListener('input',draw);
  root.querySelectorAll('[data-p]').forEach(b=>b.addEventListener('click',()=>{const [a,p]=b.dataset.p.split('/');q('ip').value=a;q('p').value=p;
    q('o').value={'192.168.1.105':'192.168.1.20','172.16.45.130':'172.16.50.1','10.1.2.3':'10.200.0.1','141.85.220.33':'141.85.241.99'}[a];draw()}));
  draw();
};

/* ---------- the routing table ---------- */
W.route=root=>{
  const R=[{dst:'default',net:0,p:0,txt:'default via 192.168.1.1 dev enp0s31f6 proto dhcp src 192.168.1.10 metric 100'},
           {dst:'192.168.1.0/24',net:ip2n('192.168.1.0'),p:24,txt:'192.168.1.0/24 dev enp0s31f6 proto kernel scope link src 192.168.1.10 metric 100'}];
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>Ana's routing table: where does this packet go?</h3><p>Type a destination; the kernel keeps the lines that match and picks the <b>longest prefix</b>.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls rt-c"><label>destination <input type="text" data-r="d" value="192.168.2.20" spellcheck="false" aria-label="destination IP address"></label>
  <div class="tf-ch">${['192.168.1.11','192.168.2.20','8.8.8.8','141.85.220.33'].map(a=>`<button type="button" class="chip" data-a="${a}">${a}</button>`).join('')}</div>
  <label><input type="checkbox" data-r="def" checked> the <code>default</code> line</label></div>
  <div class="rt-b"><table class="t rt-t" data-r="t"></table><div class="rt-r" data-r="r"></div></div></div>`;
  const q=Q(root);
  function draw(){
    const d=ip2n(q('d').value), useDef=q('def').checked;
    if(d===null){q('t').innerHTML='';q('r').className='rt-r rt-bad';q('r').innerHTML='Type an IPv4 address, like <code>192.168.2.20</code>.';q('b').textContent='?';return}
    const rows=R.filter(r=>useDef||r.p>0).map(r=>({...r,ok:inNet(d,r.net,r.p)}));
    const win=rows.filter(r=>r.ok).sort((a,b)=>b.p-a.p)[0];
    q('t').innerHTML='<tr><th>the line of <code>ip route</code></th><th>does it match?</th></tr>'+R.map(r=>{const x=rows.find(y=>y.dst===r.dst);if(!x)return `<tr class="off"><td><code>${r.txt}</code></td><td>removed</td></tr>`;
      const chk=r.p===0?`<span class="y">✓ /0: every address</span>`:x.ok?`<span class="y">✓ /${r.p}: ${n2ip((d&maskN(r.p))>>>0)} = ${n2ip(r.net)}</span>`:`<span class="n">✗ /${r.p}: ${n2ip((d&maskN(r.p))>>>0)} ≠ ${n2ip(r.net)}</span>`;
      return `<tr class="${x===win?'rt-win':''}"><td><code>${r.txt}</code></td><td>${chk}</td></tr>`}).join('');
    const r=q('r');
    if(!win){r.className='rt-r rt-bad';r.innerHTML=`No line matches <code>${n2ip(d)}</code>: <code>ping: connect: Network is unreachable</code>. No frame is sent.`;q('b').textContent='unreachable'}
    else if(win.p===0){r.className='rt-r';r.innerHTML=`<b>default</b> wins (the only match): sent to the <b>gateway</b> <code>192.168.1.1</code>. Ana asks ARP for the <b>router's</b> MAC; the IP destination stays <code>${n2ip(d)}</code>.`;q('b').textContent='via the gateway'}
    else{r.className='rt-r';r.innerHTML=`<code>/24</code> wins (longer than <code>/0</code>): <code>${n2ip(d)}</code> is in Ana's network, sent <b>directly</b>. Ana asks ARP for <b>its</b> MAC.`;q('b').textContent='directly'}
  }
  q('d').addEventListener('input',draw);q('def').addEventListener('change',draw);
  root.querySelectorAll('[data-a]').forEach(b=>b.addEventListener('click',()=>{q('d').value=b.dataset.a;draw()}));
  draw();
};

/* ---------- the sample traffic of the laptop (the filter widget and tcpdump) ---------- */
const LIP='192.168.1.105',GIP='192.168.1.1',UIP='141.85.220.33',SIP='141.85.241.99',LMAC='3c:a9:f4:5e:21:7b',GMAC='70:b5:e8:2d:91:4c';
const PK=[
  {arp:{op:'req',sip:LIP,tip:GIP},src:LMAC,dst:'ff:ff:ff:ff:ff:ff'},
  {arp:{op:'rep',sip:GIP,tip:LIP},src:GMAC,dst:LMAC},
  {ip:{src:LIP,dst:GIP,p:'udp',ttl:64},sp:40211,dp:53,info:'4660+ A? upb.ro. (24)',len:52,raw:'E..4.+@.@.........4.......upb.ro.....'},
  {ip:{src:GIP,dst:LIP,p:'udp',ttl:64},sp:53,dp:40211,info:'4660 1/0/0 A 141.85.220.33 (40)',len:68,raw:'E..D..@.@.........5.....upb.ro.............U.!'},
  {ip:{src:LIP,dst:UIP,p:'icmp',ttl:64},info:'ICMP echo request, id 7, seq 1, length 64',len:84},
  {ip:{src:UIP,dst:LIP,p:'icmp',ttl:60},info:'ICMP echo reply, id 7, seq 1, length 64',len:84},
  {ip:{src:LIP,dst:UIP,p:'tcp',ttl:64},sp:51034,dp:443,info:'Flags [S], seq 1000, win 64240, options [mss 1460], length 0',len:60},
  {ip:{src:UIP,dst:LIP,p:'tcp',ttl:60},sp:443,dp:51034,info:'Flags [S.], seq 5000, ack 1001, win 65160, options [mss 1400], length 0',len:60},
  {ip:{src:LIP,dst:UIP,p:'tcp',ttl:64},sp:51034,dp:443,info:'Flags [.], ack 1, win 502, length 0',len:52},
  {ip:{src:LIP,dst:UIP,p:'tcp',ttl:64},sp:51034,dp:443,info:'Flags [P.], seq 1:518, ack 1, win 502, length 517',len:569,raw:'E.....@.@.......5.......<encrypted TLS data>'},
  {ip:{src:LIP,dst:SIP,p:'tcp',ttl:64},sp:48522,dp:22,info:'Flags [P.], seq 1:37, ack 1, win 501, length 36',len:88,raw:'E..X..@.@.......<encrypted SSH data>'},
  {ip:{src:SIP,dst:LIP,p:'tcp',ttl:60},sp:22,dp:48522,info:'Flags [P.], seq 1:53, ack 37, win 509, length 52',len:104,raw:'E..h..@.<.......<encrypted SSH data>'},
  {ip:{src:LIP,dst:UIP,p:'tcp',ttl:64},sp:51040,dp:80,info:'Flags [P.], seq 1:79, ack 1, win 502, length 78: HTTP: GET / HTTP/1.1',len:130,raw:'E.....@.@.......P.....\nGET / HTTP/1.1\nHost: upb.ro\nUser-Agent: curl/8.9.1\nAccept: */*'},
  {ip:{src:LIP,dst:GIP,p:'icmp',ttl:64},info:'ICMP echo request, id 8, seq 1, length 64',len:84},
  {ip:{src:GIP,dst:LIP,p:'icmp',ttl:64},info:'ICMP echo reply, id 8, seq 1, length 64',len:84},
  {ip:{src:LIP,dst:GIP,p:'udp',ttl:64},sp:68,dp:67,info:'BOOTP/DHCP, Request from 3c:a9:f4:5e:21:7b, length 300',len:328},
];
const HNAME={[LIP]:'iso',[GIP]:'_gateway',[UIP]:'www.upb.ro'};
const PNAME={53:'domain',80:'http',443:'https',22:'ssh',67:'bootps',68:'bootpc',123:'ntp',25:'smtp'};
const PNUM={domain:53,http:80,https:443,ssh:22,bootps:67,bootpc:68,ntp:123,smtp:25};
const FHOST={'upb.ro':UIP,'www.upb.ro':UIP,'_gateway':GIP,'localhost':'127.0.0.1','dns.google':'8.8.8.8','iso':LIP};
/* one packet, as tcpdump prints it; o: n (numbers), e (MACs), v (verbose), t (no time), A (data), any (-i any), i (its number) */
function pkLine(p,o){
  const H=a=>o.n?a:(HNAME[a]||a), P=x=>o.n?x:(PNAME[x]||x);
  let body;
  if(p.arp)body=p.arp.op==='req'?`Request who-has ${H(p.arp.tip)} tell ${H(p.arp.sip)}, length 28`:`Reply ${H(p.arp.sip)} is-at ${GMAC}, length 28`;
  else body=`${H(p.ip.src)}${p.sp!=null?'.'+P(p.sp):''} > ${H(p.ip.dst)}${p.dp!=null?'.'+P(p.dp):''}: ${p.info}`;
  const out=p.ip?p.ip.src===LIP:p.src===LMAC;
  const smac=p.src||(out?LMAC:GMAC), dmac=p.dst||(out?GMAC:LMAC);
  let pre='';
  if(!o.t){const us=1103251+o.i*137413;pre='14:20:'+String(Math.floor(us/1e6)).padStart(2,'0')+'.'+String(us%1e6).padStart(6,'0')+' '}
  if(o.any)pre+='wlp2s0 '+(out?'Out':'In ')+' ';
  const proto={udp:'UDP (17)',tcp:'TCP (6)',icmp:'ICMP (1)'};
  const vv=p.ip&&o.v?`(tos 0x0, ttl ${p.ip.ttl}, id ${4242+o.i*17}, offset 0, flags [DF], proto ${proto[p.ip.p]}, length ${p.len})\n    `:'';
  let s;
  if(o.e)s=pre+`${smac} > ${dmac}, ethertype ${p.ip?'IPv4 (0x0800)':'ARP (0x0806)'}, length ${p.ip?p.len+14:42}: `+vv+body;
  else s=pre+(p.ip?'IP '+vv:'ARP, ')+body;
  if(o.A&&p.ip)s+='\n'+(p.raw||'E..T..@.@.........');
  return s;
}

/* ---------- pcap filters: [proto] [dir] [type] value, not / and / or, parentheses (man pcap-filter) ---------- */
const PROTOS=['ip','ip6','arp','tcp','udp','icmp'],DIRS=['src','dst'],TYPES=['host','net','port'];
function parseFilter(src){
  const toks=(src.match(/&&|\|\||[()!]|[^\s()!&|]+/g)||[]);
  let i=0,last=null;
  const peek=()=>toks[i], next=()=>toks[i++];
  const isOp=t=>['and','or','&&','||'].includes(t), isNot=t=>t==='not'||t==='!';
  const kw=t=>PROTOS.includes(t)||DIRS.includes(t)||TYPES.includes(t)||isOp(t)||isNot(t)||t==='('||t===')';
  const err=m=>{throw new Error(m)};
  function value(q,v){
    if(q.type==='port'){const n=/^\d+$/.test(v)?+v:PNUM[v];if(n==null)err(`unknown port '${v}'`);if(n>65535)err(`illegal port number ${n} > 65535`);return n}
    if(q.type==='net'){const m=/^(\d+(?:\.\d+){0,3})(?:\/(\d+))?$/.exec(v);if(!m)err(`unknown network '${v}'`);const parts=m[1].split('.');while(parts.length<4)parts.push('0');
      const n=ip2n(parts.join('.'));if(n===null)err(`unknown network '${v}'`);const p=m[2]!=null?+m[2]:m[1].split('.').length*8;if(p>32)err('mask length must be <= 32');
      if(((n&maskN(p))>>>0)!==n)err('non-network bits set in "'+v+'"');return{n,p}}
    const a=ip2n(v)!==null?v:FHOST[v];if(!a)err(`unknown host '${v}'`);return a;
  }
  function prim(){
    const q={proto:null,dir:null,type:null};
    if(PROTOS.includes(peek()))q.proto=next();
    if(DIRS.includes(peek()))q.dir=next();
    if(TYPES.includes(peek()))q.type=next();
    const t=peek();
    if(t!==undefined&&!kw(t)){
      next();
      if(!q.proto&&!q.dir&&!q.type&&last)Object.assign(q,{proto:last.proto,dir:last.dir,type:last.type});
      q.type=q.type||'host';
      if(q.proto==='icmp'||((q.proto==='tcp'||q.proto==='udp')&&q.type!=='port')||((q.proto==='ip'||q.proto==='ip6'||q.proto==='arp')&&q.type==='port'))err(`'${q.proto}' modifier applied to ${q.type}`);
      last=q;return{q,v:t,val:value(q,t)};
    }
    if(q.proto&&!q.dir&&!q.type){last=null;return{q}}
    err("can't parse filter expression: syntax error");
  }
  function unary(){
    const t=peek();
    if(t===undefined)err("can't parse filter expression: syntax error");
    if(isNot(t)){next();return{op:'not',x:unary()}}
    if(t==='('){next();const e=expr();if(next()!==')')err("can't parse filter expression: syntax error");return e}
    return prim();
  }
  function expr(){
    let l=unary();
    while(isOp(peek())){const op=next();const r=unary();l={op:op==='&&'||op==='and'?'and':'or',l,r}}
    return l;
  }
  try{
    if(!toks.length)return{ast:null};
    const ast=expr();if(i<toks.length)err("can't parse filter expression: syntax error");
    return{ast};
  }catch(e){return{err:e.message}}
}
function match(a,p){
  if(!a)return true;
  if(a.op==='and')return match(a.l,p)&&match(a.r,p);
  if(a.op==='or')return match(a.l,p)||match(a.r,p);
  if(a.op==='not')return!match(a.x,p);
  const q=a.q, ip=p.ip, l4=ip&&(ip.p==='tcp'||ip.p==='udp');
  if(a.v===undefined)return{ip:!!ip,arp:!!p.arp,tcp:!!ip&&ip.p==='tcp',udp:!!ip&&ip.p==='udp',icmp:!!ip&&ip.p==='icmp',ip6:false}[q.proto];
  if(q.type==='port'){if(!l4||(q.proto&&ip.p!==q.proto))return false;return q.dir==='src'?p.sp===a.val:q.dir==='dst'?p.dp===a.val:(p.sp===a.val||p.dp===a.val)}
  if(q.proto==='ip'&&!ip||q.proto==='arp'&&!p.arp||q.proto==='ip6')return false;
  const s=ip?ip.src:p.arp.sip, d=ip?ip.dst:p.arp.tip;
  const t=x=>q.type==='net'?inNet(ip2n(x),a.val.n,a.val.p):x===a.val;
  return q.dir==='src'?t(s):q.dir==='dst'?t(d):(t(s)||t(d));
}
function describe(a,top=true){
  if(!a)return'every packet: no filter';
  const W2=x=>x.op&&x.op!=='not'?'['+describe(x,false)+']':describe(x,false);
  if(a.op==='not')return'everything except '+W2(a.x);
  if(a.op)return W2(a.l)+' <b>'+a.op+'</b> '+W2(a.r);
  const q=a.q, P={tcp:'TCP',udp:'UDP',ip:'IPv4',ip6:'IPv6',arp:'ARP',icmp:'ICMP'};
  if(a.v===undefined)return{icmp:'ICMP packets (ping)',arp:'ARP messages',tcp:'TCP segments',udp:'UDP datagrams',ip:'IPv4 packets',ip6:'IPv6 packets'}[q.proto];
  return(q.proto?P[q.proto]+' packets':'packets')+' '+(q.dir==='src'?'<b>from</b>':q.dir==='dst'?'<b>to</b>':'to or from')+' '+(q.type==='net'?'the network ':q.type==='port'?'port ':'')+'<code>'+esc(a.v)+'</code>';
}

/* ---------- the filter playground ---------- */
W.filter=root=>{
  const combo=root.dataset.set==='combo';
  const P=combo?['not port 22','host 192.168.1.1 and icmp','icmp or arp','host 192.168.1.1 and (icmp or arp)','tcp and not port 443','port 53 or 67']
               :['icmp','host 192.168.1.1','src host 192.168.1.105','net 141.85.0.0/16','udp port 53','tcp dst port 443','tcp host 192.168.1.1','tcp and host 192.168.1.105'];
  root.innerHTML=`<div class="wd"><div class="wd-h"><div><h3>${combo?'Combine filters':'Try a filter'} on the traffic of the laptop</h3><p>${PK.length} packets the laptop sent and received; the ones your filter keeps are highlighted.</p></div><span class="badge" data-r="b"></span></div>
  <div class="ctrls tf-c"><div class="tf-in"><b>$ sudo tcpdump -n -t</b><input type="text" data-r="f" value="${esc(P[combo?3:4])}" spellcheck="false" autocomplete="off" aria-label="the filter"></div>
  <div class="tf-ch"><span class="chl">try:</span>${P.map(f=>`<button type="button" class="chip${f==='tcp host 192.168.1.1'?' tf-bad':''}" data-f="${esc(f)}"${f==='tcp host 192.168.1.1'?' title="a mistake: see what tcpdump says"':''}>${esc(f)}${f==='tcp host 192.168.1.1'?' ✗':''}</button>`).join('')}</div></div>
  <div class="tf-x" data-r="x" aria-live="polite"></div><ol class="tf-l" data-r="l"></ol></div>`;
  const q=Q(root);
  function draw(){
    const f=q('f').value, r=parseFilter(f);
    q('f').classList.toggle('tf-err',!!r.err);
    const lines=PK.map((p,i)=>pkLine(p,{n:true,t:true,i}));
    if(r.err){q('x').className='tf-x tf-xbad';const m=/^'(\w+)' modifier applied to (\w+)$/.exec(r.err);
      q('x').innerHTML='<code>tcpdump: '+esc(r.err)+'</code>'+(m?` <span class="tf-why">The real tcpdump refuses it too: <code>${m[1]}</code> ${m[1]==='tcp'||m[1]==='udp'?'goes only before <code>port</code>':m[1]==='icmp'?'stands alone':'goes only before <code>host</code> or <code>net</code>'}. To combine them, join two filters: <code>${m[1]} and ${m[2]} …</code></span>`:'');q('l').innerHTML=lines.map(l=>`<li>${esc(l)}</li>`).join('');q('b').textContent='error';return}
    const m=PK.map(p=>match(r.ast,p)), n=m.filter(Boolean).length;
    const quote=/[()!]/.test(f)?` <span class="small">In bash, quote it: <code>sudo tcpdump -n '${esc(f.trim())}'</code></span>`:'';
    q('x').className='tf-x';q('x').innerHTML='Keeps '+describe(r.ast)+': <b>'+n+'</b> of '+PK.length+' packets.'+quote;
    q('l').innerHTML=lines.map((l,i)=>`<li class="${m[i]?'m':''}">${esc(l)}</li>`).join('');
    q('b').textContent=n+' / '+PK.length+' packets';
  }
  q('f').addEventListener('input',draw);
  root.querySelectorAll('[data-f]').forEach(b=>b.addEventListener('click',()=>{q('f').value=b.dataset.f;draw()}));
  draw();
};

/* ================================================================ the laptop of the demo terminal (profile '09') */
if(typeof ISOSH!=='undefined'){
const S=ISOSH, SH=S.Shell.prototype;
const SERVICES=`# /etc/services: the names of the ports (an excerpt)
ssh             22/tcp                          # The Secure Shell (SSH) Protocol
smtp            25/tcp          mail
domain          53/tcp                          # name-domain server
domain          53/udp
bootps          67/udp                          # DHCP server
bootpc          68/udp                          # DHCP client
http            80/tcp          www www-http    # WorldWideWeb HTTP
ntp             123/udp                         # Network Time Protocol
imap            143/tcp         imap2           # Interim Mail Access Proto v2
https           443/tcp                         # http protocol over TLS/SSL
microsoft-ds    445/tcp                         # SMB, Windows file sharing
imaps           993/tcp                         # IMAP over SSL
mysql           3306/tcp
ms-wbt-server   3389/tcp                        # RDP, remote desktop
postgresql      5432/tcp        postgres        # PostgreSQL Database
`;
S.PROFILES['09']=(fs,{D,F})=>{
  const h=fs.c.home.c.student.c;delete h.Downloads;delete h.Movies;delete h['watchlist.txt'];
  fs.c.sys.c.class.c.net=D({lo:D({address:F('00:00:00:00:00:00\n')}),enp0s31f6:D({address:F('8c:16:45:a2:3b:91\n')}),wlp2s0:D({address:F('3c:a9:f4:5e:21:7b\n')})});
  fs.c.etc.c.hosts=F('127.0.0.1   localhost localhost.localdomain\n::1         localhost localhost.localdomain\n');
  fs.c.etc.c['resolv.conf']=F('# Generated by systemd-resolved: the programs ask the local cache,\n# which asks the DNS server of each card (resolvectl dns)\nnameserver 127.0.0.53\noptions edns0 trust-ad\n');
  fs.c.etc.c.services=F(SERVICES);
};

/* ---------- the state of the network ---------- */
const CONNS={HomeWiFi:{uuid:'6e2c8d5b-1f0a-4c3e-9b7d-2a51c0e8f913',type:'wifi',ip:'192.168.1.105',p:24,gw:'192.168.1.1',pass:'my secret'},
  CafeFree:{uuid:'3f1d7c92-b5e4-4a08-8c6d-9e2f0a1b7c43',type:'wifi',ip:'10.0.5.23',p:24,gw:'10.0.5.1'},
  lo:{uuid:'8d3b5f0e-6a41-4d2c-9e7b-1c0a2f4d6e85',type:'loopback'},
  'Wired connection 1':{uuid:'b7e2a419-0c5d-3f86-a1e4-6d9c2b8f0e57',type:'ethernet'}};
const AIR=[['HomeWiFi','70:B5:E8:2D:91:4D','Infra','36','540 Mbit/s','82','****','WPA2 WPA3'],['Neighbours','7A:15:C2:09:8E:41','Infra','6','130 Mbit/s','47','**  ','WPA2'],
  ['CafeFree','02:1F:6B:3D:77:10','Infra','11','65 Mbit/s','30','*   ','--'],['LabGame','D2:5F:0A:31:44:9E','Ad-Hoc','1','54 Mbit/s','25','*   ','--']];
const FAULTS=['radio','dhcp','gw','isp','dns','server'];
const NET=sh=>{if(!sh.net){const f=sh.fault!==undefined?sh.fault:(sh.variant&&sh.variant!=='random'?sh.variant:null);
  sh.net={fault:f,radio:f!=='radio',conn:f==='radio'?null:'HomeWiFi',acn:7,neigh:[{ip:GIP,mac:GMAC,st:'REACHABLE'},{ip:'192.168.1.107',mac:'a2:5e:1c:44:90:3b',st:'STALE'}]}}return sh.net};
function ST(sh){const n=NET(sh), c=n.radio&&n.conn?CONNS[n.conn]:null, dhcp=n.fault==='dhcp';
  const a=c&&!dhcp?{ip:c.ip,p:c.p,net:n2ip((ip2n(c.ip)&maskN(c.p))>>>0),gw:n.fault==='gw'?null:c.gw,dns:c.gw}:null;
  return{n,c,a,state:!n.radio?'unavailable':!n.conn?'disconnected':dhcp?'connecting (getting IP configuration)':'connected'}}
const LANH={'192.168.1.1':{mac:GMAC,t:1.91},'192.168.1.107':{mac:'a2:5e:1c:44:90:3b',t:3.12},'192.168.1.106':{mac:'b8:27:eb:5a:10:c4',t:2.64},'10.0.5.1':{mac:'0e:5c:22:7a:01:01',t:2.2}};
const NETH={'141.85.220.33':{ttl:60,t:4.21,name:'www.upb.ro'},'8.8.8.8':{ttl:117,t:12.4,name:'dns.google',via:['72.14.218.98','142.251.65.13']},'8.8.4.4':{ttl:117,t:12.7,name:'dns.google',via:['72.14.218.98','142.251.65.13']},
  '1.1.1.1':{ttl:57,t:9.82,name:'one.one.one.one',via:['162.158.84.1']},'142.251.39.110':{ttl:117,t:12.1,name:'bud02s39-in-f14.1e100.net',via:['72.14.218.98','142.251.65.13']},'141.85.241.99':{ttl:60,t:4.83},'141.85.220.250':{drop:true}};
const DNSDB={'upb.ro':{A:['141.85.220.33'],MX:['0 ironport.upb.ro.']},'www.upb.ro':{A:['141.85.220.33']},'google.com':{A:['142.251.39.110'],AAAA:['2a00:1450:4017:80e::200e'],MX:['10 smtp.google.com.']},
  'dns.google':{A:['8.8.8.8','8.8.4.4'],AAAA:['2001:4860:4860::8888']},'one.one.one.one':{A:['1.1.1.1']}};
const REV={'141.85.220.33':'www.upb.ro','8.8.8.8':'dns.google','8.8.4.4':'dns.google','1.1.1.1':'one.one.one.one','192.168.1.1':'_gateway'};
/* a name to an address: {ip} or {err: 'nx' | 'fail' | 'servfail'} */
function resolve(sh,name){
  if(ip2n(name)!==null||name.includes(':'))return{ip:name};
  if(name==='localhost')return{ip:'127.0.0.1'};
  const s=ST(sh);
  if(name==='_gateway')return s.a&&s.a.gw?{ip:s.a.gw}:{err:'nx'};
  if(!s.a)return{err:'fail'};
  if(s.n.fault==='dns')return{err:'fail'};
  if(s.n.fault==='isp')return{err:'servfail'};
  const r=DNSDB[name.replace(/\.$/,'')];return r?{ip:r.A[0],rec:r}:{err:'nx'};
}
/* where a packet to ip goes: ok / unreach (no route) / hostun (my network, no ARP answer) / loss (no answer) */
function reach(sh,ip){
  const s=ST(sh);
  if(ip==='::1'||/^127\./.test(ip))return{ok:1,ttl:64,t:.041,local:1};
  if(/^fe80:/i.test(ip))return /%wlp2s0$/.test(ip)&&s.n.radio&&s.n.conn?{ok:1,ttl:64,t:2.31,lan:1}:{bad:'ping: connect: Invalid argument'};
  if(ip.includes(':'))return s.a&&s.a.gw&&s.n.fault!=='isp'?{ok:1,ttl:117,t:12.4,hops:[]}:s.a&&s.a.gw?{loss:1}:{unreach:1};
  if(!s.a)return{unreach:1};
  if(ip===s.a.ip)return{ok:1,ttl:64,t:.052,local:1};
  const d=ip2n(ip);
  if(inNet(d,ip2n(s.a.net),s.a.p)){const h=LANH[ip];return h?{ok:1,ttl:64,t:h.t,lan:1,mac:h.mac}:{hostun:1}}
  if(!s.a.gw)return{unreach:1};
  const first=[s.a.gw,'10.20.0.1',null,'37.128.225.9'];
  if(s.n.fault==='isp')return{loss:1,hops:[s.a.gw]};
  const h=NETH[ip];if(!h||h.drop)return{loss:1,hops:first};
  return{ok:1,ttl:h.ttl,t:h.t,hops:first.concat(h.via||[],[ip])};
}
const ft=t=>t<1?t.toFixed(3):t<10?t.toFixed(2):t<100?t.toFixed(1):t.toFixed(0);
const JIT=[1,.945,.962,.976,1.012,.99,.97,1.004];
const notRoot=c=>({err:c+': you need to be root: try sudo '+c,code:1});
const what=(sh,h)=>{sh.what=h};

/* ---------- ping ---------- */
SH.c_ping=function(args){
  let n=null,host=null;
  for(let i=0;i<args.length;i++){const a=args[i];
    if(a==='-c'){n=parseInt(args[++i],10);if(!(n>0))return{err:'ping: invalid argument: \''+(args[i]||'')+'\'',code:1};continue}
    if(/^-c\d+$/.test(a)){n=+a.slice(2);continue}
    if(a==='-4'||a==='-6'||a==='-n'||a==='-q')continue;
    if(/^-[iWw]$/.test(a)){i++;continue}
    if(a.startsWith('-'))return{err:'ping: invalid option -- \''+a.slice(1)+'\'\n(iso-demo: this ping knows -c N)',code:2};
    host=a}
  if(!host)return{err:'ping: usage error: Destination address required',code:1};
  const note=n===null?'(iso-demo: without -c, ping runs until Ctrl+C; here it stopped after 4)':null;n=n||4;
  const r0=resolve(this,host);
  if(r0.err){what(this,r0.err==='nx'?`No such name: DNS answered that <code>${esc(host)}</code> does not exist.`:'The name could not be turned into an address: <b>DNS</b> did not answer.');
    return{err:'ping: '+host+': '+(r0.err==='nx'?'Name or service not known':'Temporary failure in name resolution'),code:2}}
  const ip=r0.ip, v6=ip.includes(':'), r=reach(this,ip), s=ST(this), named=ip!==host;
  if(r.bad)return{err:r.bad,code:2};
  if(r.unreach){what(this,'No line of the routing table matches '+esc(ip)+': <b>no route</b>, no frame was sent'+(s.a?' (no default gateway).':' (the card has no address).'));return{err:'ping: connect: Network is unreachable',code:2}}
  const head=`PING ${host} (${ip}) ${v6?'56 data bytes':'56(84) bytes of data.'}`;
  const out=[head];
  if(r.hostun){for(let k=1;k<=Math.min(n,3);k++)out.push(`From ${s.a.ip} icmp_seq=${k} Destination Host Unreachable`);
    const nb=NET(this).neigh;if(!nb.some(x=>x.ip===ip))nb.push({ip,st:'FAILED'});
    out.push('',`--- ${host} ping statistics ---`,`${n} packets transmitted, 0 received, +${Math.min(n,3)} errors, 100% packet loss, time ${(n-1)*1000+50}ms`);
    what(this,esc(ip)+' is in <b>my network</b>: the laptop asked ARP for its MAC address and nobody answered. <code>ip neigh</code> now shows it <code>FAILED</code>.');
    return{out:out.join('\n'),code:1,note}}
  if(r.loss){out.push('',`--- ${host} ping statistics ---`,`${n} packets transmitted, 0 received, 100% packet loss, time ${(n-1)*1000+31}ms`);
    what(this,'The requests left through the gateway; <b>no answer</b> came back: the computer is down, a firewall drops <code>ping</code>, or the way out is broken (try <code>traceroute -n</code>).');
    return{out:out.join('\n'),code:1,note}}
  const ts=[];for(let k=1;k<=n;k++){const t=+ft(r.t*JIT[(k-1)%JIT.length]);ts.push(t);
    out.push(`64 bytes from ${named&&!v6?(REV[ip]||host)+' ('+ip+')':ip}: icmp_seq=${k} ttl=${r.ttl} time=${ft(t)} ms`)}
  const avg=ts.reduce((a,b)=>a+b,0)/n, md=Math.sqrt(ts.reduce((a,b)=>a+b*b,0)/n-avg*avg)||0;
  out.push('',`--- ${host} ping statistics ---`,`${n} packets transmitted, ${n} received, 0% packet loss, time ${(n-1)*1000+5}ms`,
    `rtt min/avg/max/mdev = ${Math.min(...ts).toFixed(3)}/${avg.toFixed(3)}/${Math.max(...ts).toFixed(3)}/${md.toFixed(3)} ms`);
  if(r.lan&&r.mac){const nb=NET(this).neigh,e=nb.find(x=>x.ip===ip);if(e){e.st='REACHABLE';e.mac=r.mac}else nb.push({ip,mac:r.mac,st:'REACHABLE'})}
  what(this,r.local?'The loopback: the packets never left the computer.':r.lan?'Directly, in the LAN: ARP gave the MAC address of '+esc(ip)+'; no router on the way (<code>ttl=64</code>).':
    `ICMP echo requests to ${esc(ip)}, through the gateway <code>${s.a?s.a.gw:''}</code>${named?' (DNS gave the address first)':''}; the answers came back with <code>ttl=${r.ttl}</code>.`);
  return{out:out.join('\n'),note};
};

/* ---------- traceroute ---------- */
const TT={0:[1.912,1.874,1.851],1:[3.420,3.402,3.389],3:[4.103,4.087,4.152]};
SH.c_traceroute=function(args){
  const o=args.filter(a=>a.startsWith('-')), hs=args.filter(a=>!a.startsWith('-'));
  if(!hs.length)return{err:'Usage:\n  traceroute [ -46dFITnreAUDV ] host [ packetlen ]',code:2};
  const N=o.some(a=>/n/.test(a)), host=hs[0], r0=resolve(this,host);
  if(r0.err)return{err:host+': '+(r0.err==='nx'?'Name or service not known':'Temporary failure in name resolution')+'\nCannot handle "host" cmdline arg `'+host+"' on position 1 (argc 1)",code:2};
  const ip=r0.ip, r=reach(this,ip), s=ST(this);
  if(r.unreach){what(this,'No route: the kernel has no line for '+esc(ip)+'.');return{err:'connect: Network is unreachable',code:1}}
  const name=a=>N?a:((a===GIP||a===(s.a&&s.a.gw))?'_gateway':REV[a]||a)+' ('+a+')';
  const out=[`traceroute to ${host} (${ip}), 30 hops max, 60 byte packets`];
  const line=(k,a,base)=>out.push(` ${k}  ${N?a.padEnd(15):name(a)+'  '}${base.map(t=>t.toFixed(3)+' ms').join('  ')}`);
  if(r.local||r.lan){line(1,ip,[r.t,r.t*.97,r.t*.95]);what(this,'One hop: the destination is in my network (or it is me).');return{out:out.join('\n')}}
  const hops=r.ok?r.hops:(r.hops||[]);
  hops.forEach((a,k)=>{if(a===null){out.push(` ${k+1}  * * *`);return}
    const last=r.ok&&k===hops.length-1, base=last?[r.t,r.t*.997,r.t*.992]:TT[k]||[4.3+k*.6,4.28+k*.6,4.31+k*.6];line(k+1,a,base)});
  if(!r.ok){for(let k=hops.length+1;k<=hops.length+3;k++)out.push(` ${k}  * * *`);out.push(' …  (iso-demo: more lines of * * *, up to 30)');
    what(this,'The packets passed the first '+hops.length+' router(s), then <b>no more answers</b>: they are lost after that point, or the destination drops them.');return{out:out.join('\n'),code:0}}
  what(this,`${hops.length-1} routers, then the destination. Each line is a packet sent with TTL 1, 2, 3, …; the router where it reached 0 answered. <code>* * *</code>: a router that does not answer, but forwards.`);
  return{out:out.join('\n')};
};

/* ---------- ip ---------- */
const FLAGS={lo:'<LOOPBACK,UP,LOWER_UP>',eth:'<NO-CARRIER,BROADCAST,MULTICAST,UP>',wup:'<BROADCAST,MULTICAST,UP,LOWER_UP>',wdown:'<NO-CARRIER,BROADCAST,MULTICAST,UP>'};
function cards(sh){const s=ST(sh), wl=!!(s.n.radio&&s.n.conn);
  return[{i:1,n:'lo',st:'UNKNOWN',mac:'00:00:00:00:00:00',fl:FLAGS.lo,a4:'127.0.0.1/8',a6:'::1/128',kind:'loopback'},
    {i:2,n:'enp0s31f6',st:'DOWN',mac:'8c:16:45:a2:3b:91',fl:FLAGS.eth,kind:'ether'},
    {i:3,n:'wlp2s0',st:wl?'UP':'DOWN',mac:LMAC,fl:wl?FLAGS.wup:FLAGS.wdown,a4:s.a?s.a.ip+'/'+s.a.p:null,a6:wl?'fe80::8d2c:41a7:3b6e:f019/64':null,kind:'ether',wl:1}]}
SH.c_ip=function(args){
  let br=false,a=args.slice();
  while(a[0]&&a[0].startsWith('-')){const f=a.shift();if(/^-(br|brief)$/.test(f))br=true;else if(/^-(c|color|4)$/.test(f)||/^-color=/.test(f)){}else return{err:'Option "'+f+'" is unknown, try "ip -help".',code:255}}
  const obj=a.shift()||'', rest=a, s=ST(this), C=cards(this);
  const isObj=(w,list)=>list.includes(w);
  if(!obj)return{err:'Usage: ip [ OPTIONS ] OBJECT { COMMAND | help }\nwhere  OBJECT := { address | link | neigh | route | ... }\n       OPTIONS := { -br[ief] | -c[olor] | ... }',code:255};
  const dev=(()=>{const k=rest.indexOf('dev');return k>=0?rest[k+1]:rest.find(x=>C.some(c=>c.n===x))})();
  const sel=dev?C.filter(c=>c.n===dev):C;
  if(dev&&!sel.length)return{err:`Device "${dev}" does not exist.`,code:1};
  if(isObj(obj,['l','li','link'])){
    if(rest[0]==='set'){if(!this.asRoot)return{err:'RTNETLINK answers: Operation not permitted',code:2};
      const up=rest.includes('up'), dn=rest.includes('down');if(dev==='wlp2s0'&&(up||dn)){const n=NET(this);if(dn){n.conn=null}else if(n.radio){n.conn=n.last||'HomeWiFi'}
        what(this,dn?'The card was turned off (<code>UP</code> is gone): no carrier, no address.':'The card was turned on; NetworkManager connects it again.')}return{}}
    what(this,'The cards (network interfaces) the kernel sees, with their state and MAC address.');
    if(br)return{out:sel.map(c=>c.n.padEnd(17)+c.st.padEnd(15)+c.mac+' '+c.fl).join('\n')};
    return{out:sel.map(c=>`${c.i}: ${c.n}: ${c.fl} mtu ${c.n==='lo'?65536:1500} qdisc ${c.n==='enp0s31f6'?'fq_codel':'noqueue'} state ${c.st} mode ${c.wl?'DORMANT':'DEFAULT'} group default qlen 1000\n    link/${c.kind} ${c.mac} brd ${c.n==='lo'?'00:00:00:00:00:00':'ff:ff:ff:ff:ff:ff'}`).join('\n')};
  }
  if(isObj(obj,['a','addr','address'])){
    what(this,s.a?`The Wi-Fi card has <code>${s.a.ip}/${s.a.p}</code>: network <code>${s.a.net}/${s.a.p}</code>.`:'The Wi-Fi card has <b>no IPv4 address</b>'+(s.n.radio&&s.n.conn?' (DHCP did not answer)':'')+'.');
    if(br)return{out:sel.map(c=>(c.n.padEnd(17)+c.st.padEnd(15)+[c.a4,c.a6].filter(Boolean).join(' ')).trimEnd()).join('\n')};
    return{out:sel.map(c=>{let t=`${c.i}: ${c.n}: ${c.fl} mtu ${c.n==='lo'?65536:1500} qdisc ${c.n==='enp0s31f6'?'fq_codel':'noqueue'} state ${c.st} group default qlen 1000\n    link/${c.kind} ${c.mac} brd ${c.n==='lo'?'00:00:00:00:00:00':'ff:ff:ff:ff:ff:ff'}`;
      if(c.a4)t+=`\n    inet ${c.a4} ${c.n==='lo'?'scope host lo':'brd '+n2ip((ip2n(s.a.ip)|(~maskN(s.a.p)>>>0))>>>0)+' scope global dynamic noprefixroute '+c.n}\n       valid_lft ${c.n==='lo'?'forever':'86137sec'} preferred_lft ${c.n==='lo'?'forever':'86137sec'}`;
      if(c.a6)t+=`\n    inet6 ${c.a6} scope ${c.n==='lo'?'host':'link'} noprefixroute\n       valid_lft forever preferred_lft forever`;return t}).join('\n')};
  }
  if(isObj(obj,['r','ro','route'])){
    const L=[];if(s.a){if(s.a.gw)L.push(`default via ${s.a.gw} dev wlp2s0 proto dhcp src ${s.a.ip} metric 600`);L.push(`${s.a.net}/${s.a.p} dev wlp2s0 proto kernel scope link src ${s.a.ip} metric 600`)}
    what(this,!s.a?'The routing table is <b>empty</b>: the card has no address, the laptop reaches nothing.':s.a.gw?`Two lines: <code>${s.a.net}/${s.a.p}</code> directly, everything else (<code>default</code>) through the gateway <code>${s.a.gw}</code>.`:'<b>No <code>default</code> line</b>: the laptop reaches only its own network.');
    return{out:L.join('\n')};
  }
  if(isObj(obj,['n','neigh','neighbor','neighbour'])){
    const L=s.n.radio&&s.n.conn?NET(this).neigh.filter(e=>s.a&&inNet(ip2n(e.ip),ip2n(s.a.net),s.a.p)):[];
    what(this,'The neighbor table (ARP cache): the MAC addresses the laptop found in its network.');
    return{out:L.map(e=>e.st==='FAILED'?`${e.ip} dev wlp2s0  FAILED`:`${e.ip} dev wlp2s0 lladdr ${e.mac} ${e.st}`).join('\n')};
  }
  return{err:`Object "${obj}" is unknown, try "ip help".\n(iso-demo: this ip knows link, address, route, neigh)`,code:1};
};
SH.c_arp=function(args){
  const s=ST(this);const L=s.n.radio&&s.n.conn&&s.a?NET(this).neigh.filter(e=>e.st!=='FAILED'&&inNet(ip2n(e.ip),ip2n(s.a.net),s.a.p)):[];
  const N=args.includes('-n');
  return{out:['Address                  HWtype  HWaddress           Flags Mask            Iface'].concat(L.map(e=>((N?e.ip:(e.ip===GIP?'_gateway':e.ip)).padEnd(25)+'ether   '+e.mac.padEnd(20)+'C                     wlp2s0'))).join('\n')};
};

/* ---------- nmcli ---------- */
const pad=(r,w)=>r.map((x,i)=>i<r.length-1?String(x).padEnd(w[i]):x).join('').trimEnd();
SH.c_nmcli=function(args){
  const n=NET(this), s=ST(this), a=args.slice();
  const ab=(w,full)=>w&&full.startsWith(w);
  const obj=a.shift();
  const ifn=(()=>{const k=a.indexOf('ifname');return k>=0?a[k+1]:null})();
  const activate=(name,iface)=>{n.conn=name;n.last=name;if(n.fault==='dhcp')n.fault=null;n.acn++;const c=CONNS[name];
    what(this,`NetworkManager connected <code>wlp2s0</code> to <b>${esc(name)}</b>; DHCP gave it <code>${c.ip}/${c.p}</code>, the gateway and the DNS server <code>${c.gw}</code>.`)};
  if(!obj)return{out:(s.state==='connected'?`wlp2s0: connected to ${n.conn}\n        "Intel Wi-Fi 6 AX201"\n        wifi (iwlwifi), ${LMAC.toUpperCase()}, hw, mtu 1500\n        ip4 default\n        inet4 ${s.a.ip}/${s.a.p}`:'wlp2s0: '+s.state)+'\n\nenp0s31f6: unavailable\n\nlo: connected (externally) to lo\n\n(iso-demo: try nmcli device status)'};
  if(ab(obj,'device')){
    const sub=a.shift()||'status';
    if(ab(sub,'status')){what(this,'The cards NetworkManager manages, and the saved connection each one uses.');
      return{out:[['DEVICE','TYPE','STATE','CONNECTION'],['wlp2s0','wifi',s.state,n.radio&&n.conn?n.conn:'--'],['lo','loopback','connected (externally)','lo'],['p2p-dev-wlp2s0','wifi-p2p',n.radio?'disconnected':'unavailable','--'],['enp0s31f6','ethernet','unavailable','--']].map(r=>pad(r,[16,10,24])).join('\n')}}
    if(sub==='wifi'){
      const w=a.shift()||'list';
      if(ab(w,'list')||w==='ifname'){if(ifn&&ifn!=='wlp2s0')return{err:`Error: Device '${ifn}' ${ifn==='enp0s31f6'?'is not a Wi-Fi device':'not found'}.`,code:10};
        if(!n.radio){what(this,'The Wi-Fi radio is off: the card hears nothing.');return{out:''}}
        what(this,'The networks the Wi-Fi card hears around it; <code>*</code> is the one it uses.');
        return{out:[['IN-USE','BSSID','SSID','MODE','CHAN','RATE','SIGNAL','BARS','SECURITY']].concat(AIR.map(r=>[n.conn===r[0]?'*':' ',...r.slice(1,2),r[0],...r.slice(2)])).map(r=>pad(r,[8,19,12,8,6,12,8,6])).join('\n')}}
      if(ab(w,'connect')){
        const ssid=a[0], k=a.indexOf('password'), pw=k>=0?a[k+1]:null;
        if(!ssid||ssid==='ifname'||ssid==='password')return{err:'Error: SSID or BSSID are missing.',code:2};
        if(ifn&&ifn!=='wlp2s0')return{err:`Error: Device '${ifn}' ${ifn==='enp0s31f6'?'is not a Wi-Fi device':'not found'}.`,code:10};
        if(!n.radio)return{err:'Error: Connection activation failed: No suitable device found for this connection (device wlp2s0 not available because the Wi-Fi radio is off).\n(iso-demo: nmcli radio wifi on)',code:4};
        const net=AIR.find(r=>r[0]===ssid);if(!net)return{err:`Error: No network with SSID '${ssid}' found.`,code:10};
        if(ssid==='LabGame')return{err:'iso-demo: LabGame is an Ad-Hoc network of two laptops, with no Internet: this demo does not join it.',code:1};
        if(ssid==='Neighbours'||(ssid==='HomeWiFi'&&pw!==CONNS.HomeWiFi.pass)){what(this,'Wrong or missing password: the access point refused the laptop.');return{err:'Error: Connection activation failed: Secrets were required, but not provided.',code:4}}
        activate(ssid);return{out:`Device 'wlp2s0' successfully activated with '${CONNS[ssid].uuid}'.`}}
      return{err:`Error: argument '${w}' not understood. Try passing --help instead.`,code:2};
    }
    if(ab(sub,'connect')||ab(sub,'disconnect')){
      const d=a[0];if(!d)return{err:'Error: No interface specified.',code:2};
      if(d==='enp0s31f6')return sub.startsWith('c')?{err:'Error: Connection activation failed: No suitable device found for this connection (device enp0s31f6 not available because device has no carrier).',code:4}:{err:"Error: Device 'enp0s31f6' (/org/freedesktop/NetworkManager/Devices/2) disconnecting failed: This device is not active",code:6};
      if(d!=='wlp2s0')return{err:`Error: Device '${d}' not found.`,code:10};
      if(ab(sub,'disconnect')){if(!n.conn||!n.radio)return{err:"Error: Device 'wlp2s0' (/org/freedesktop/NetworkManager/Devices/3) disconnecting failed: This device is not active",code:6};
        n.conn=null;what(this,'The card left the network: no address, no routes. The connection stays <b>saved</b>.');return{out:"Device 'wlp2s0' successfully disconnected."}}
      if(!n.radio)return{err:'Error: Connection activation failed: No suitable device found for this connection (device wlp2s0 not available because the Wi-Fi radio is off).',code:4};
      activate(n.last||'HomeWiFi');return{out:`Device 'wlp2s0' successfully activated with '${CONNS[n.conn].uuid}'.`};
    }
    if(ab(sub,'show')){const d=a[0]||'wlp2s0';if(d!=='wlp2s0')return{out:`GENERAL.DEVICE:                         ${d}\nGENERAL.STATE:                          ${d==='lo'?'100 (connected (externally))':'20 (unavailable)'}`};
      const L=[['GENERAL.DEVICE:','wlp2s0'],['GENERAL.TYPE:','wifi'],['GENERAL.HWADDR:',LMAC.toUpperCase()],['GENERAL.MTU:','1500'],['GENERAL.STATE:',s.state==='connected'?'100 (connected)':s.state==='unavailable'?'20 (unavailable)':s.state==='disconnected'?'30 (disconnected)':'70 (connecting (getting IP configuration))'],
        ['GENERAL.CONNECTION:',n.radio&&n.conn?n.conn:'--']];
      if(s.a){L.push(['IP4.ADDRESS[1]:',s.a.ip+'/'+s.a.p],['IP4.GATEWAY:',s.a.gw||'--'],['IP4.ROUTE[1]:',`dst = ${s.a.net}/${s.a.p}, nh = 0.0.0.0, mt = 600`]);if(s.a.gw)L.push(['IP4.ROUTE[2]:',`dst = 0.0.0.0/0, nh = ${s.a.gw}, mt = 600`]);L.push(['IP4.DNS[1]:',s.a.dns],['IP6.ADDRESS[1]:','fe80::8d2c:41a7:3b6e:f019/64'],['IP6.GATEWAY:','--'])}
      what(this,s.a?'What the card received from DHCP: address and mask, gateway, DNS server.':'The card has no IP configuration.');
      return{out:L.map(([k,v])=>k.padEnd(40)+v).join('\n')}}
    return{err:`Error: argument '${sub}' not understood. Try passing --help instead.`,code:2};
  }
  if(ab(obj,'connection')){
    const sub=a.shift()||'show';
    if(ab(sub,'show')){what(this,'The saved connections; DEVICE: the card that uses it now.');
      return{out:[['NAME','UUID','TYPE','DEVICE']].concat(['HomeWiFi','lo','CafeFree','Wired connection 1'].map(k=>[k,CONNS[k].uuid,CONNS[k].type,k==='lo'?'lo':n.radio&&n.conn===k?'wlp2s0':'--'])).map(r=>pad(r,[20,38,10])).join('\n')}}
    if(ab(sub,'up')||ab(sub,'down')){
      const name=a.filter((x,i)=>x!=='ifname'&&a[i-1]!=='ifname').join(' ');const c=CONNS[name];
      if(!name)return{err:'Error: No connection specified.',code:2};
      if(!c)return{err:`Error: unknown connection '${name}'.`,code:10};
      if(ab(sub,'down')){if(n.conn!==name||!n.radio)return{err:`Error: '${name}' is not an active connection.`,code:10};n.conn=null;what(this,'The connection was stopped; the card is now disconnected.');return{out:`Connection '${name}' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/${n.acn})`}}
      if(c.type==='ethernet'||ifn==='enp0s31f6'&&c.type==='wifi'){
        return{err:c.type==='ethernet'?'Error: Connection activation failed: No suitable device found for this connection (device enp0s31f6 not available because device has no carrier).':
          'Error: Connection activation failed: No suitable device found for this connection (device enp0s31f6 not available because profile is not compatible with device (mismatching connection type)).',code:4}}
      if(c.type==='loopback')return{out:'Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/1)'};
      if(ifn&&ifn!=='wlp2s0')return{err:`Error: device '${ifn}' not found.\n(iso-demo: no USB Wi-Fi dongle is plugged into this laptop)`,code:10};
      if(!n.radio)return{err:'Error: Connection activation failed: No suitable device found for this connection (device wlp2s0 not available because the Wi-Fi radio is off).',code:4};
      activate(name);return{out:`Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/${n.acn})`};
    }
    return{err:`Error: argument '${sub}' not understood. Try passing --help instead.`,code:2};
  }
  if(ab(obj,'radio')){
    const what_=a[0], v=a[1];
    if(!what_)return{out:'WIFI-HW  WIFI     WWAN-HW  WWAN\nenabled  '+(n.radio?'enabled ':'disabled')+' missing  enabled'};
    if(what_==='wifi'||what_==='all'){
      if(!v)return{out:n.radio?'enabled':'disabled'};
      if(v==='off'){n.radio=false;what(this,'The Wi-Fi radio is off: the card is <code>unavailable</code>, no network.');return{}}
      if(v==='on'){if(!n.radio){n.radio=true;if(n.fault==='radio')n.fault=null;n.conn=n.last||'HomeWiFi';n.acn++;what(this,'The radio is on again; NetworkManager connected to the saved network <b>'+n.conn+'</b> by itself.')}return{}}
      return{err:`Error: '${v}' is not valid; use [on, off].`,code:2};
    }
    return{err:`Error: argument '${what_}' not understood. Try passing --help instead.`,code:2};
  }
  return{err:`Error: argument '${obj}' not understood. Try passing --help instead.\n(iso-demo: this nmcli knows device, connection, radio)`,code:2};
};

/* ---------- DNS: host, dig, resolvectl ---------- */
SH.c_host=function(args){
  let t=null;const a=args.slice();const k=a.indexOf('-t');if(k>=0){t=(a[k+1]||'').toUpperCase();a.splice(k,2)}
  const name=a[0];if(!name)return{err:'Usage: host [-t type] hostname [server]',code:1};
  const s=ST(this);
  if(ip2n(name)!==null){const r=REV[name];if(!s.a||s.n.fault==='dns')return{out:';; connection timed out; no servers could be reached',code:1};
    return r?{out:name.split('.').reverse().join('.')+'.in-addr.arpa domain name pointer '+r+'.'}:{err:`Host ${name.split('.').reverse().join('.')}.in-addr.arpa. not found: 3(NXDOMAIN)`,code:1}}
  const r=resolve(this,name);
  if(r.err==='fail'){what(this,'The DNS server did not answer: '+(s.a?'the router is there, its DNS does not work.':'the laptop has no network.'));return{out:';; connection timed out; no servers could be reached',code:1}}
  if(r.err==='servfail'){what(this,'The router answered, but it could not ask the provider: <code>SERVFAIL</code>.');return{err:`Host ${name} not found: 2(SERVFAIL)`,code:1}}
  if(r.err)return{err:`Host ${name} not found: 3(NXDOMAIN)`,code:1};
  const rec=r.rec||{A:[r.ip]},out=[];
  if(!t||t==='A')(rec.A||[]).forEach(x=>out.push(`${name} has address ${x}`));
  if(!t||t==='AAAA')(rec.AAAA||[]).forEach(x=>out.push(`${name} has IPv6 address ${x}`));
  if(!t||t==='MX')(rec.MX||[]).forEach(x=>out.push(`${name} mail is handled by ${x}`));
  if(t&&!out.length)out.push(`${name} has no ${t} record`);
  what(this,`The laptop asked its DNS server <code>${s.a.dns}</code> about <code>${esc(name)}</code>: A is an IPv4 address, AAAA IPv6, MX the mail server.`);
  return{out:out.join('\n')};
};
SH.c_dig=function(args){
  const name=args.find(x=>!x.startsWith('+')&&!x.startsWith('-')&&!x.startsWith('@'));
  if(!name)return{err:'iso-demo: try dig +short upb.ro',code:1};
  const r=resolve(this,name);
  if(!args.includes('+short'))return{note:'iso-demo: this dig only knows +short: dig +short '+name};
  if(r.err==='fail')return{out:';; communications error to 127.0.0.53#53: timed out\n;; no servers could be reached',code:9};
  if(r.err)return{out:''};
  return{out:(r.rec?r.rec.A:[r.ip]).join('\n')};
};
SH.c_resolvectl=function(args){
  const s=ST(this), sub=args[0]||'status';
  if(sub==='dns'){what(this,'The DNS server of each card; it came from DHCP. <code>systemd-resolved</code> asks it for the programs.');
    return{out:'Global:\nLink 2 (enp0s31f6):\nLink 3 (wlp2s0):'+(s.a?' '+s.a.dns:'')}}
  if(sub==='query'){const n=args[1];if(!n)return{err:'No name specified.',code:1};const r=resolve(this,n);
    if(r.err)return{err:n+': '+(r.err==='nx'?"resolve call failed: '"+n+"' not found":'resolve call failed: All attempts to contact name servers or networks failed'),code:1};
    return{out:`${n}: ${(r.rec?r.rec.A:[r.ip]).join('\n'+' '.repeat(n.length+2))}                     -- link: wlp2s0\n\n-- Information acquired via protocol DNS in 3.1ms.\n-- Data is authenticated: no; Data was acquired via local or encrypted transport: no`}}
  if(sub==='status')return{out:'Global\n         Protocols: LLMNR=resolve -mDNS -DNSOverTLS DNSSEC=no/unsupported\n  resolv.conf mode: stub\n\nLink 2 (enp0s31f6)\n    Current Scopes: none\n\nLink 3 (wlp2s0)\n    Current Scopes: '+(s.a?'DNS LLMNR/IPv4':'none')+(s.a?'\n Current DNS Server: '+s.a.dns+'\n        DNS Servers: '+s.a.dns:'')};
  return{err:`Unknown command verb '${sub}'.\n(iso-demo: resolvectl dns, status, query NAME)`,code:1};
};

/* ---------- ss and netstat ---------- */
function sockets(sh){const s=ST(sh);const L=[
  {p:'udp',st:'UNCONN',rq:0,sq:0,la:'127.0.0.53%lo',lp:53,pa:'0.0.0.0',pp:'*',prog:'systemd-resolve',pid:640,fd:18},
  {p:'udp',st:'UNCONN',rq:0,sq:0,la:'0.0.0.0',lp:68,pa:'0.0.0.0',pp:'*',prog:'NetworkManager',pid:702,fd:24},
  {p:'tcp',st:'LISTEN',rq:0,sq:4096,la:'127.0.0.53%lo',lp:53,pa:'0.0.0.0',pp:'*',prog:'systemd-resolve',pid:640,fd:19},
  {p:'tcp',st:'LISTEN',rq:0,sq:511,la:'0.0.0.0',lp:443,pa:'0.0.0.0',pp:'*',prog:'nginx',pid:1033,fd:6},
  {p:'tcp',st:'LISTEN',rq:0,sq:128,la:'0.0.0.0',lp:22,pa:'0.0.0.0',pp:'*',prog:'sshd',pid:812,fd:3},
  {p:'tcp',st:'LISTEN',rq:0,sq:511,la:'0.0.0.0',lp:80,pa:'0.0.0.0',pp:'*',prog:'nginx',pid:1033,fd:7}];
  if(s.a&&s.a.gw&&s.n.fault!=='isp'&&s.n.fault!=='server')L.push({p:'tcp',st:'ESTAB',rq:0,sq:0,la:s.a.ip,lp:51034,pa:UIP,pp:443,prog:'firefox',pid:2310,fd:87,mine:1},{p:'tcp',st:'ESTAB',rq:0,sq:0,la:s.a.ip,lp:48522,pa:SIP,pp:22,prog:'ssh',pid:2455,fd:3,mine:1});
  return L}
function sockOpts(args,cmd){const o={};for(const a of args){if(!a.startsWith('-'))return{err:cmd==='ss'?`ss: bad filter "${a}"\n(iso-demo: this ss knows the options -t -u -l -a -n -p)`:`netstat: invalid option -- '${a}'`};
  if(a==='--tcp')o.t=1;else if(a==='--udp')o.u=1;else if(a==='--listening')o.l=1;else if(a==='--numeric')o.n=1;else if(a==='--processes'||a==='--program')o.p=1;else if(a==='--all')o.a=1;
  else for(const c of a.slice(1)){if(!'tulnpa'.includes(c))return{err:`${cmd}: invalid option -- '${c}'\n(iso-demo: this ${cmd} knows -t -u -l -a -n -p)`};o[c]=1}}return{o}}
SH.c_ss=function(args){
  const r=sockOpts(args,'ss');if(r.err)return{err:r.err,code:1};const o=r.o;
  const both=!o.t&&!o.u||o.t&&o.u;
  const L=sockets(this).filter(x=>(both||o.t&&x.p==='tcp'||o.u&&x.p==='udp')&&(o.a||(o.l?x.st!=='ESTAB':x.st==='ESTAB')));
  const P=x=>o.n?String(x):(PNAME[x]||String(x));
  const head=(both?'Netid ':'')+'State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process';
  const rows=L.map(x=>(both?x.p.padEnd(6):'')+x.st.padEnd(7)+String(x.rq).padEnd(7)+String(x.sq).padEnd(7)+(x.la.padStart(13)+':'+P(x.lp).padEnd(5)+(' '+x.pa).padStart(13)+':'+(x.pp==='*'?'*':P(x.pp)).padEnd(6)+
    (o.p&&(this.asRoot||x.mine)?`users:(("${x.prog}",pid=${x.pid},fd=${x.fd}))`:'')).trimEnd());
  what(this,o.l?'The sockets that <b>wait</b> for data: the servers of this laptop. <code>0.0.0.0</code>: every address; <code>127.0.0.53%lo</code>: only the loopback.':'The <b>connections</b> open now: <code>ESTAB</code>, from a local port given by the OS to the port of a server.'+(o.p&&!this.asRoot?' Without <code>sudo</code>, only your own programs are shown.':''));
  return{out:[head].concat(rows).join('\n')};
};
SH.c_netstat=function(args){
  const r=sockOpts(args,'netstat');if(r.err)return{err:r.err,code:1};const o=r.o;
  const both=!o.t&&!o.u||o.t&&o.u;
  const L=sockets(this).filter(x=>(both||o.t&&x.p==='tcp'||o.u&&x.p==='udp')&&(o.a||(o.l?x.st!=='ESTAB':x.st==='ESTAB')));
  const P=x=>o.n?String(x):(PNAME[x]||String(x));
  const out=[];
  if(o.p&&!this.asRoot)out.push('(Not all processes could be identified, non-owned process info','will not be shown, you would have to be root to see it all.)');
  out.push('Active Internet connections '+(o.a?'(servers and established)':o.l?'(only servers)':'(w/o servers)'));
  out.push('Proto Recv-Q Send-Q Local Address           Foreign Address         State      '+(o.p?' PID/Program name':''));
  for(const x of L)out.push((x.p.padEnd(6)+String(x.rq).padStart(6)+String(x.sq===4096||x.sq===511||x.sq===128?0:x.sq).padStart(7)+' '+(x.la.replace('%lo','')+':'+P(x.lp)).padEnd(24)+(x.pa+':'+(x.pp==='*'?'*':P(x.pp))).padEnd(24)+(x.p==='udp'?'':x.st==='ESTAB'?'ESTABLISHED':x.st).padEnd(12)+(o.p?(this.asRoot||x.mine?x.pid+'/'+x.prog:'-'):'')).trimEnd());
  what(this,'The same sockets as <code>ss</code>, with the older command (<i>net-tools</i>).');
  return{out:out.join('\n')};
};

/* ---------- curl ---------- */
SH.c_curl=function(args){
  const I=args.some(a=>/^-\w*I/.test(a)||a==='--head'), url=args.find(a=>!a.startsWith('-'));
  if(!url)return{err:"curl: try 'curl --help' for more information",code:2};
  const m=/^(?:(https?):\/\/)?([^/:]+)(?::(\d+))?(\/.*)?$/.exec(url);if(!m)return{err:'curl: (3) URL rejected: Malformed input to a URL function',code:3};
  const sch=m[1]||'http', host=m[2], port=m[3]||(sch==='https'?443:80);
  const r0=resolve(this,host);
  if(r0.err){what(this,'curl could not turn the name into an address: '+(r0.err==='nx'?'no such name.':'<b>DNS</b> does not work.'));return{err:`curl: (6) Could not resolve host: ${host}`,code:6}}
  const r=reach(this,r0.ip), s=ST(this);
  const down=r0.ip===UIP&&s.n.fault==='server';
  if(r.unreach||r.hostun||r.loss||down||!(r0.ip===UIP||r0.ip===GIP||r0.ip==='142.251.39.110'||r0.ip==='127.0.0.1')){
    what(this,down?'The packets reach the server (<code>ping</code> works), but <b>nobody listens on port '+port+'</b>: the server sent back a TCP <code>RST</code>. The problem is the server, not my network.':'No TCP connection could be opened to '+esc(r0.ip)+':'+port+'.');
    return{err:`curl: (7) Failed to connect to ${host} port ${port} after ${down?3:r.loss?10003:0} ms: ${down?'Could not connect to server':r.loss?'Timeout was reached':'Could not connect to server'}`,code:7}}
  const g=r0.ip==='142.251.39.110', local=r0.ip==='127.0.0.1'||r0.ip===s.a?.ip;
  what(this,`curl opened a TCP connection to <code>${r0.ip}:${port}</code> and sent <code>${I?'HEAD':'GET'} /</code>; the server answered.`);
  if(I)return{out:g?`HTTP/2 301\nlocation: https://www.google.com/\ncontent-type: text/html; charset=UTF-8\ndate: Sun, 22 Nov 2026 14:20:01 GMT\nserver: gws`:
    (sch==='http'&&!local?`HTTP/1.1 301 Moved Permanently\nServer: nginx\nDate: Sun, 22 Nov 2026 14:20:01 GMT\nLocation: https://${host}/`:`HTTP/${sch==='https'?'2':'1.1'} 200${sch==='https'?'':' OK'}\nserver: nginx\ndate: Sun, 22 Nov 2026 14:20:01 GMT\ncontent-type: text/html; charset=UTF-8`)};
  return{out:local?'<!doctype html>\n<html><head><title>Welcome to nginx!</title></head>\n<body><h1>Welcome to nginx!</h1></body></html>':
    '<!doctype html>\n<html lang="ro">\n<head><title>'+(g?'Google':'Universitatea Politehnica din București')+'</title></head>\n<body>\n  …\n</body>\n</html>'};
};

/* ---------- tcpdump ---------- */
SH.c_tcpdump=function(args){
  const o={n:false,t:false,e:false,v:false,A:false,D:false,c:null,i:null,w:null,r:null};const rest=[];
  for(let k=0;k<args.length;k++){const a=args[k];
    if(a==='-nn'){o.n=true;continue}
    if(/^-[ivcwr]$/.test(a)&&a!=='-v'){o[a[1]]=args[++k];if(o[a[1]]===undefined)return{err:`tcpdump: option requires an argument -- '${a[1]}'`,code:1};continue}
    if(/^-c\d+$/.test(a)){o.c=a.slice(2);continue}
    if(/^-[ntevADvq]+$/.test(a)){for(const ch of a.slice(1))if(ch!=='q')o[ch]=true;continue}
    if(/^-[ntevA]+[icwr]$/.test(a)){for(const ch of a.slice(1,-1))o[ch]=true;o[a.slice(-1)]=args[++k];continue}
    if(a.startsWith('-'))return{err:`tcpdump: invalid option -- '${a.slice(1)}'\n(iso-demo: this tcpdump knows -D -i -n -t -e -v -A -c -w -r)`,code:1};
    rest.push(a)}
  if(o.D)return{out:'1.wlp2s0 [Up, Running, Wireless, Associated]\n2.any (Pseudo-device that captures on all interfaces) [Up, Running]\n3.lo [Up, Running, Loopback]\n4.enp0s31f6 [Up, Disconnected]\n5.bluetooth-monitor (Bluetooth Linux Monitor) [Wireless]\n6.nflog (Linux netfilter log (NFLOG) interface) [none]\n7.nfqueue (Linux netfilter queue (NFQUEUE) interface) [none]'};
  const f=rest.join(' '), pf=parseFilter(f);
  if(pf.err)return{err:'tcpdump: '+pf.err,code:1};
  const cnt=o.c!==null?parseInt(o.c,10):null;if(o.c!==null&&!(cnt>0))return{err:'tcpdump: invalid packet count '+o.c,code:1};
  const fmt=(p,i)=>pkLine(p,{n:o.n,t:o.t,e:o.e,v:o.v,A:o.A,i,any:o.i==='any'});
  if(o.r){const x=S.lookup(this.root,S.split(this.cwd,o.r));
    if(x.err)return{err:`tcpdump: ${o.r}: No such file or directory`,code:1};
    if(!x.node.pcap)return{err:`tcpdump: ${o.r}: unknown file format`,code:1};
    let L=x.node.pcap.map(i=>PK[i]).filter(p=>match(pf.ast,p));if(cnt)L=L.slice(0,cnt);
    what(this,'Read from the file: no card, no <code>sudo</code> needed. The filter applies again.');
    return{seq:[{out:`reading from file ${o.r}, link-type EN10MB (Ethernet), snapshot length 262144`},{out:L.map(p=>fmt(p,PK.indexOf(p))).join('\n')}]}}
  if(!this.asRoot){what(this,'Only <code>root</code> may read every packet of a card.');return{err:`tcpdump: ${o.i&&o.i!=='any'?o.i:'wlp2s0'}: You don't have permission to perform this capture on that device\n(socket: Operation not permitted)`,code:1}}
  const s=ST(this), dev=o.i||'wlp2s0';
  if(!['wlp2s0','any','lo','enp0s31f6'].includes(dev))return{err:`tcpdump: ${dev}: No such device exists\n(No such device exists)`,code:1};
  if(dev==='wlp2s0'&&!s.n.radio)return{err:'tcpdump: wlp2s0: That device is not up',code:1};
  const live=(dev==='wlp2s0'||dev==='any')&&s.n.conn&&s.n.radio;
  let L=live?PK.filter(p=>match(pf.ast,p)):[];
  const head=dev==='any'?'listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes':`listening on ${dev}, link-type EN10MB (Ethernet), snapshot length 262144 bytes`;
  const seq=[];
  if(!o.w&&!o.v)seq.push({out:'tcpdump: verbose output suppressed, use -v[v]... for full protocol decode'});
  seq.push({out:(o.w||o.v?'tcpdump: ':'')+head});
  const stop=cnt!==null&&L.length>=cnt;if(cnt)L=L.slice(0,cnt);
  if(o.w){const parts=S.split(this.cwd,o.w);if(!S.writable(parts))return{err:`tcpdump: ${o.w}: Permission denied`,code:1};
    const par=S.lookup(this.root,parts.slice(0,-1));if(!par.node||par.node.t!=='d')return{err:`tcpdump: ${o.w}: No such file or directory`,code:1};
    const nd=S.F('',24+L.length*120);nd.pcap=L.map(p=>PK.indexOf(p));par.node.c[parts[parts.length-1]]=nd;
    what(this,`${L.length} packets saved in <code>${esc(o.w)}</code>: read them with <code>tcpdump -r</code>, or open the file in Wireshark.`)}
  else{if(L.length)seq.push({out:L.map(p=>fmt(p,PK.indexOf(p))).join('\n')});
    what(this,live?`tcpdump read every frame of <code>${dev}</code> and printed the <b>${L.length}</b> that match${f?' the filter <code>'+esc(f)+'</code>':' (no filter: all of them)'}.`:'Nothing goes through this card: '+(dev==='lo'?'the loopback is quiet now.':dev==='enp0s31f6'?'no cable.':'it is not connected.'))}
  if(!stop)seq.push({out:'^C'});
  seq.push({out:`${L.length} packet${L.length===1?'':'s'} captured\n${L.length+(f?3:0)} packets received by filter\n0 packets dropped by kernel`});
  return{seq,note:stop?null:'(iso-demo: the sample traffic ended here; a real tcpdump waits for more, until Ctrl+C)'};
};

/* ---------- sudo, dnf, help ---------- */
SH.c_sudo=function(args){
  if(!args.length)return{err:'usage: sudo command\n(iso-demo: no password is asked in this demo)',code:1};
  const cmd=args[0], fn=this['c_'+cmd];
  if(!fn)return{err:`sudo: ${cmd}: command not found`,code:1};
  this.asRoot=true;try{return fn.call(this,args.slice(1))||{}}finally{this.asRoot=false}
};
SH.c_dnf=function(args){
  if(args[0]!=='install'||!args[1])return{note:'iso-demo: this dnf only knows: sudo dnf install PACKAGE'};
  if(!this.asRoot)return{err:'Error: This command has to be run with superuser privileges (under the root user on most systems).',code:1};
  return{out:args.slice(1).map(p=>`Package "${p}" is already installed.`).join('\n')+'\n\nNothing to do.'};
};
SH.c_tracepath=function(args){return{note:'iso-demo: use traceroute -n '+(args[0]||'141.85.220.33')+' here (tracepath does almost the same)'}};
const H0=SH.c_help;
SH.c_help=function(){const r=H0.call(this);if(this.profile==='09')r.out+='\nlecture 09: ip ping traceroute nmcli host dig resolvectl ss netstat curl tcpdump arp sudo\n           the laptop: wlp2s0 (Wi-Fi), enp0s31f6 (Ethernet, no cable), lo';return r};
const R0=SH.reset;SH.reset=function(){R0.call(this);this.net=null;this.what=null};
Object.assign(S.MAN,{
  ip:['ip - show / manipulate routing, network devices, interfaces','ip [ -br ] { link | address | route | neigh } [ show ] [ dev IFNAME ]\nip link set dev IFNAME { up | down }','-br  brief: one line for each card\nlink: the cards and their MAC addresses; address: their IP addresses\nroute: the routing table; neigh: the MAC addresses found with ARP',8],
  ping:['ping - send ICMP ECHO_REQUEST to network hosts','ping [-c count] destination','-c count  stop after count replies\nno -c: until Ctrl+C\nEvery reply line: icmp_seq (missing: lost), ttl (what is left of it), time (the round trip).'],
  traceroute:['traceroute - print the route packets trace to network host','traceroute [-n] [-I] host','-n  print the addresses as numbers, do not look up names\n-I  use ICMP ECHO (ping) packets\nSends packets with TTL 1, 2, 3, ...: each router where the TTL reaches 0 answers.'],
  nmcli:['nmcli - command-line tool for controlling NetworkManager','nmcli device { status | show [IFNAME] | connect IFNAME | disconnect IFNAME }\nnmcli device wifi { list [ifname IFNAME] | connect SSID [password PASSWORD] [ifname IFNAME] }\nnmcli connection { show | up NAME [ifname IFNAME] | down NAME }\nnmcli radio { wifi | all } [ on | off ]','Every word can be shortened: nmcli d = nmcli device, nmcli c = nmcli connection.'],
  host:['host - DNS lookup utility','host [-t type] name','-t type  only one record type: A, AAAA, MX\nA name gives its addresses (A, AAAA) and its mail servers (MX); an address gives its name.'],
  dig:['dig - DNS lookup utility','dig +short name','+short  only the answer (this demo knows only +short)'],
  resolvectl:['resolvectl - resolve names, show the DNS servers','resolvectl { dns | status | query NAME }','dns: the DNS server of every card\nquery NAME: ask for a name, through systemd-resolved'],
  ss:['ss - another utility to investigate sockets','ss [-t] [-u] [-l] [-a] [-n] [-p]','-t TCP  -u UDP\n-l only the sockets that wait for data (listening)  -a all\n-n numbers, not names (443, not https)\n-p the program (root sees every program)',8],
  netstat:['netstat - print network connections (net-tools, older)','netstat [-t] [-u] [-l] [-a] [-n] [-p]','The same options as ss.',8],
  curl:['curl - transfer a URL','curl [-I] URL','-I  only the headers of the answer (HEAD)\nThe URL: https://upb.ro, http://upb.ro'],
  tcpdump:['tcpdump - dump traffic on a network','tcpdump [-D] [-i interface] [-n] [-t] [-e] [-v] [-A] [-c count] [-w file] [-r file] [ filter ]','-D list the cards  -i listen on this card (any: on all)\n-n numbers, not names  -t no time  -e the MAC addresses  -v more details  -A the data as text\n-c stop after count packets  -w save in a file  -r read from a file\nfilter: [tcp|udp|ip|arp|icmp] [src|dst] [host|net|port] value, with not / and / or and ( ): man pcap-filter',8],
  sudo:['sudo - execute a command as another user','sudo command [args]','Runs the command as root (in this demo: without asking for a password).',8],
  arp:['arp - manipulate the system ARP cache (net-tools, older)','arp [-n]','-n numbers, not names. The same table as ip neigh.',8],
  dnf:['dnf - package manager (Fedora)','dnf install PACKAGE','Installs a package; needs root.',8],
  tracepath:['tracepath - traces path to a network host','tracepath host','Like traceroute, usually already installed.',8],
});

/* ---------- the side panel: the laptop ---------- */
const SIDE=window.ISO_SIDE||(window.ISO_SIDE={});
SIDE.net={draw(sh,el){
  const s=ST(sh),n=s.n;
  const wl=!n.radio?'<span class="nl-down">○ Wi-Fi radio off</span>':!n.conn?'<span class="nl-down">○ disconnected</span>':`<span class="nl-up">● connected</span> to <b>${esc(n.conn)}</b>`;
  el.innerHTML=`<div class="nl-cols"><div><div class="nl-h">The laptop</div><table class="nl-t">
  <tr><td>wlp2s0</td><td>${wl}<br><code>${s.a?s.a.ip+'/'+s.a.p:n.conn&&n.radio?'no address (DHCP)':'no address'}</code></td></tr>
  <tr><td>enp0s31f6</td><td><span class="nl-dim">○ no cable</span></td></tr>
  <tr><td>lo</td><td><span class="nl-dim">loopback</span> <code>127.0.0.1/8</code></td></tr></table>
  </div><div><div class="nl-h">Routes and DNS</div><table class="nl-t"><tr><td>gateway</td><td>${s.a&&s.a.gw?'<code>'+s.a.gw+'</code>':'<span class="nl-down">none</span>'}</td></tr><tr><td>DNS</td><td>${s.a?'<code>'+s.a.dns+'</code>':'–'}</td></tr></table>
  </div><div class="nl-what">${sh.what?'<b>What happened:</b> '+sh.what:'Run a command: what it did shows up here.'}</div></div>`;
}};

/* ---------- the troubleshooting lab ---------- */
const pubIP=a=>{const n=ip2n(a);return n!==null&&!/^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)/.test(a)};
const CHECKS=[
  ['card','Is the card connected?',c=>/^(sudo\s+)?ip\s+(-\S+\s+)*(l|li|link)\b/.test(c)||/^nmcli(\s+(d|dev|device)(\s+status)?)?\s*$/.test(c)],
  ['address','Do I have an IP address?',c=>/^ip\s+(-\S+\s+)*(a|addr|address)\b/.test(c)||/^nmcli\s+(d|dev|device)\s+show/.test(c)],
  ['gateway','Do I have a gateway?',c=>/^ip\s+(-\S+\s+)*(r|ro|route)\b/.test(c)||/^nmcli\s+(d|dev|device)\s+show/.test(c)],
  ['internet','Does the Internet answer?',c=>/^(ping|traceroute)\b/.test(c)&&c.split(/\s+/).some(pubIP)],
  ['dns','Do names work?',c=>/^(host|dig|resolvectl\s+query)\b/.test(c)||/^(ping|curl|traceroute)\b/.test(c)&&/\s[a-z][\w-]*\.[a-z]{2,}(\s|\/|$)/.test(c)],
  ['server','Does the server answer?',c=>/^curl\b/.test(c)]];
const ANS={radio:'card',dhcp:'address',gw:'gateway',isp:'internet',dns:'dns',server:'server'};
const LABEL={card:'the card',address:'the address (DHCP)',gateway:'the gateway',internet:'the router / provider',dns:'DNS',server:'the server'};
const EXPL={
  radio:'The Wi-Fi <b>radio was off</b>: <code>nmcli device status</code> says <code>unavailable</code>, <code>ip -br link</code> shows <code>wlp2s0 DOWN</code>. Fix it: <code>nmcli radio wifi on</code>, then <code>ping -c 2 8.8.8.8</code>.',
  dhcp:'The card is connected to HomeWiFi, but <b>DHCP gave no address</b>: <code>ip -br address</code> shows only <code>fe80::…</code>, <code>ip route</code> is empty. Fix it: connect again, <code>nmcli device connect wlp2s0</code>.',
  gw:'There is an address, but <b>no <code>default</code> line</b> in <code>ip route</code>: <code>ping 8.8.8.8</code> says <code>Network is unreachable</code>. Names still work: the DNS server is the router, in the LAN. Adding the gateway by hand: next lecture.',
  isp:'Everything works up to the router (<code>ping 192.168.1.1</code> answers), but <b>nothing beyond it</b>: <code>ping 8.8.8.8</code> loses every packet, <code>traceroute -n 8.8.8.8</code> stops after the gateway. Call the provider, or restart the home router.',
  dns:'<code>ping 8.8.8.8</code> works, but <b>names do not</b>: <code>host upb.ro</code> times out, <code>ping upb.ro</code> says <i>Temporary failure in name resolution</i>. Setting another DNS server: next lecture.',
  server:'The network is fine, <code>ping upb.ro</code> answers, but <code>curl</code> cannot connect to port 443: <b>the web server is down</b>. Not your problem: wait, or tell its admins.'};
SIDE.trouble={draw(sh,el,api){
  if(!sh.tb){const f=sh.variant&&sh.variant!=='random'?sh.variant:FAULTS[Math.floor(Math.random()*FAULTS.length)];sh.fault=f;sh.net=null;sh.tb={start:0,ans:null,solved:0,n:1,done:new Set()}}
  const tb=sh.tb;
  sh.hist.slice(tb.start).forEach(c=>{c=c.replace(/^sudo\s+/,'');CHECKS.forEach(([k,,re])=>{if(re(c))tb.done.add(k)})});
  el.innerHTML=`<div class="nl-cols"><div><div class="nl-h">Problem ${tb.n} · the checks you ran</div><ol class="tb-ck">${CHECKS.map(([k,t],i)=>`<li class="${tb.done.has(k)?'done':''}"><i>${tb.done.has(k)?'✓':i+1}</i>${t}</li>`).join('')}</ol>
  </div><div><div class="nl-h">What is broken?</div><div class="tb-ans">${CHECKS.map(([k])=>`<button type="button" data-k="${k}" class="${tb.ans&&tb.ans[k]?tb.ans[k]:''}">${LABEL[k]}</button>`).join('')}</div>
  <div class="tb-fb" data-r="fb">${tb.fb||'Run the checks from the bottom up; the first one that fails is the answer.'}</div>
  <button type="button" class="btn ghost tb-new" data-r="new">New problem →</button>${tb.solved?`<p class="small">Solved: ${tb.solved}</p>`:''}</div></div>`;
  el.querySelectorAll('[data-k]').forEach(b=>b.addEventListener('click',()=>{const k=b.dataset.k, ok=ANS[sh.fault]===k;tb.ans=tb.ans||{};tb.ans[k]=ok?'ok':'no';
    if(ok&&!tb.right){tb.right=true;tb.solved++}
    tb.fb=ok?'✓ Right. '+EXPL[sh.fault]:`✗ Not ${LABEL[k]}. ${CHECKS.findIndex(c=>c[0]===k)<CHECKS.findIndex(c=>c[0]===ANS[sh.fault])?'Its check passes: run it and look.':'Look lower: a check below it already fails.'}`;
    SIDE.trouble.draw(sh,el,api)}));
  el.querySelector('[data-r="new"]').addEventListener('click',()=>{const others=FAULTS.filter(f=>f!==sh.fault);sh.fault=others[Math.floor(Math.random()*others.length)];sh.net=null;
    Object.assign(tb,{start:sh.hist.length,ans:null,right:false,fb:null,n:tb.n+1,done:new Set()});api.print('<span class="dim">— a new problem: something else is broken now —</span>');SIDE.trouble.draw(sh,el,api)});
}};

/* ---------- the missions ---------- */
const hist=(sh,re)=>sh.hist.some(h=>re.test(h));
const MS=window.ISO_MSETS||(window.ISO_MSETS={});
MS.wifi=[
  {t:'Show the state of every card.',h:'nmcli device status',ok:(sh,c,o)=>/^nmcli\s+(d|dev|device)(\s+status)?\s*$/.test(c)&&/DEVICE/.test(o)},
  {t:'List the Wi-Fi networks the laptop hears.',h:'nmcli device wifi list',ok:(sh,c,o)=>/BSSID/.test(o)},
  {t:'Disconnect the Wi-Fi card.',h:'nmcli device disconnect wlp2s0',ok:(sh,c,o)=>/successfully disconnected/.test(o)},
  {t:'Connect it back, without typing the password.',h:'nmcli device connect wlp2s0',ok:(sh,c,o)=>/^nmcli\s+(d|dev|device)\s+connect\s+wlp2s0/.test(c)&&/successfully activated/.test(o)},
  {t:'Use the saved connection <code>CafeFree</code> instead.',h:'nmcli connection up CafeFree',ok:sh=>NET(sh).conn==='CafeFree'&&NET(sh).radio},
  {t:'Go back to <code>HomeWiFi</code> by name and password (<code>my secret</code>).',h:"nmcli device wifi connect HomeWiFi password 'my secret'",ok:(sh,c,o)=>/wifi\s+connect\s+HomeWiFi/.test(c)&&/successfully activated/.test(o)},
  {t:'Turn the Wi-Fi radio off, check that it is off, and turn it back on.',h:'nmcli radio wifi off; nmcli radio wifi; nmcli radio wifi on',ok:(sh,c)=>hist(sh,/radio\s+(wifi|all)\s+off/)&&hist(sh,/radio\s+wifi\s*$/)&&/radio\s+(wifi|all)\s+on/.test(c)&&NET(sh).radio},
];
MS.ip=[
  {t:'List the cards with their MAC addresses, one line each.',h:'ip -br link',ok:(sh,c,o)=>/^ip\s+-br\w*\s+(l|li|link)\b/.test(c)&&/wlp2s0/.test(o)},
  {t:'Show the IPv4 address and the mask of the Wi-Fi card.',h:'ip -br address',ok:(sh,c,o)=>/^ip\b/.test(c)&&/192\.168\.1\.105\/24/.test(o)},
  {t:'Read the MAC address of <code>wlp2s0</code> from <code>/sys</code>.',h:'cat /sys/class/net/wlp2s0/address',ok:(sh,c,o)=>/^cat\b.*\/sys\/class\/net\/wlp2s0\/address/.test(c)&&/3c:a9/.test(o)},
  {t:'Ping the UPB server <code>141.85.220.33</code> exactly 3 times.',h:'ping -c 3 141.85.220.33',ok:(sh,c,o)=>/^ping\b/.test(c)&&/3 packets transmitted, 3 received/.test(o)&&/141\.85\.220\.33/.test(o)},
  {t:'Ping this computer through the IPv6 loopback.',h:'ping -c 1 ::1',ok:(sh,c,o)=>/bytes from ::1:/.test(o)},
  {t:'Ping a name: <code>upb.ro</code>.',h:'ping -c 2 upb.ro',ok:(sh,c,o)=>/^ping\b.*upb\.ro/.test(c)&&/received/.test(o)},
];
MS.route=[
  {t:'Show the routing table: which gateway does the laptop use?',h:'ip route',ok:(sh,c,o)=>/^ip\s+(r|ro|route)\b/.test(c)&&/default via/.test(o)},
  {t:'Find the MAC address of the gateway.',h:'ip neigh (or arp -n)',ok:(sh,c,o)=>/70:b5:e8:2d:91:4c/.test(o)&&/^(ip|arp)\b/.test(c)},
  {t:'List the routers on the way to <code>141.85.220.33</code>, by IP only.',h:'traceroute -n 141.85.220.33',ok:(sh,c,o)=>/^traceroute\b.*-n/.test(c)&&/141\.85\.220\.33 {2}\d/.test(o)},
  {t:'Ping <code>192.168.1.20</code>, a computer that is not in the LAN.',h:'ping -c 1 192.168.1.20',ok:(sh,c,o)=>/Destination Host Unreachable/.test(o)},
  {t:'Find it in the neighbor table now.',h:'ip neigh',ok:(sh,c,o)=>/192\.168\.1\.20 dev wlp2s0 {2}FAILED/.test(o)},
  {t:'Disconnect the Wi-Fi, then see what <code>ping 8.8.8.8</code> says without a route.',h:'nmcli device disconnect wlp2s0; ping 8.8.8.8',ok:(sh,c,o)=>/Network is unreachable/.test(o)},
];
MS.ports=[
  {t:'List the TCP and UDP ports that wait for data, as numbers.',h:'ss -tuln',ok:(sh,c,o)=>/^ss\b/.test(c)&&/LISTEN/.test(o)&&/UNCONN/.test(o)&&/:443\b/.test(o)},
  {t:'Find which program listens on port 443.',h:'sudo ss -tlnp',ok:(sh,c,o)=>/"nginx",pid=1033|1033\/nginx/.test(o)},
  {t:'Show the TCP ports with their names instead of numbers.',h:'ss -tl (no -n)',ok:(sh,c,o)=>/^(sudo\s+)?(ss|netstat)\b/.test(c)&&/:https\b/.test(o)},
  {t:'See the TCP connections that are open now.',h:'ss -tn',ok:(sh,c,o)=>/ESTAB/.test(o)},
  {t:'Do it with the older <code>netstat</code> too.',h:'netstat -tln',ok:(sh,c,o)=>/^(sudo\s+)?netstat\b/.test(c)&&/Active Internet connections/.test(o)},
  {t:'Find the name of port 22 in <code>/etc/services</code>.',h:'grep 22/ /etc/services',ok:(sh,c,o)=>/^grep\b.*\/etc\/services/.test(c)&&/^ssh\s+22\/tcp/m.test(o)},
];
MS.dns=[
  {t:'Find the address of <code>upb.ro</code>.',h:'host upb.ro',ok:(sh,c,o)=>/upb\.ro has address 141\.85\.220\.33/.test(o)},
  {t:'Find the IPv6 address of <code>google.com</code>.',h:'host google.com',ok:(sh,c,o)=>/has IPv6 address/.test(o)},
  {t:'Which DNS server does the Wi-Fi card ask?',h:'resolvectl dns',ok:(sh,c,o)=>/Link 3 \(wlp2s0\): 192\.168\.1\.1/.test(o)},
  {t:'Show only the <code>IP4</code> lines of what DHCP gave the card.',h:'nmcli device show wlp2s0 | grep IP4',ok:(sh,c,o)=>/\|\s*grep/.test(c)&&/IP4\.DNS/.test(o)&&!/GENERAL/.test(o)},
  {t:'Look at the names written by hand, in <code>/etc/hosts</code>.',h:'cat /etc/hosts',ok:(sh,c,o)=>/^cat\b.*\/etc\/hosts/.test(c)&&/localhost/.test(o)},
];
MS.capture=[
  {t:'List the cards <code>tcpdump</code> can listen on.',h:'sudo tcpdump -D',ok:(sh,c,o)=>/1\.wlp2s0/.test(o)},
  {t:'Capture only 2 ping packets on <code>wlp2s0</code>, with numbers.',h:'sudo tcpdump -i wlp2s0 -n -c 2 icmp',ok:(sh,c,o)=>/\bicmp\b/.test(c)&&/-c\s*2\b/.test(c)&&/ICMP echo request/.test(o)&&/2 packets captured/.test(o)},
  {t:'Capture ARP, with the MAC addresses.',h:'sudo tcpdump -n -e arp',ok:(sh,c,o)=>/ethertype ARP/.test(o)},
  {t:'Show only DNS: UDP, port 53.',h:"sudo tcpdump -n 'udp port 53'",ok:(sh,c,o)=>/A\? upb\.ro/.test(o)&&!/ICMP|Flags/.test(o)},
  {t:'Show only the packets going <b>to</b> port 443.',h:'sudo tcpdump -n tcp dst port 443',ok:(sh,c,o)=>/\.443: Flags/.test(o)&&!/\.443 >/.test(o)},
  {t:'Save the packets in <code>cap.pcap</code>, then read them back <b>without</b> <code>sudo</code>.',h:'sudo tcpdump -w cap.pcap; tcpdump -n -r cap.pcap',ok:(sh,c,o)=>/^tcpdump\b.*-r\s*cap\.pcap/.test(c)&&/reading from file/.test(o)},
  {t:'Read the text of the HTTP request from the file.',h:'tcpdump -n -A -r cap.pcap port 80',ok:(sh,c,o)=>/-\w*A/.test(c)&&/GET \/ HTTP\/1\.1\nHost: upb\.ro/.test(o)},
];
}
})();
