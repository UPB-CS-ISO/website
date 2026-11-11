(()=>{'use strict';
const C=window.COURSE, M=window.COURSE_META, KEY=M.key;
let done={};try{done=JSON.parse(localStorage.getItem(KEY)||'{}')||{}}catch(e){}
const save=()=>{try{localStorage.setItem(KEY,JSON.stringify(done))}catch(e){}};
const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
const pages=[];C.forEach((c,ci)=>c.pages.forEach((p,pi)=>pages.push({c,ci,p,pi,key:c.id+'/'+p.id})));
const total=pages.length;
const chDone=c=>c.pages.every(p=>done[c.id+'/'+p.id]);
const home=$('#home'), chv=$('#chapter');

function renderMap(){
  const map=$('#map');map.innerHTML='<svg class="links"></svg>';
  const cur=C.find(c=>!chDone(c));
  C.forEach((c,i)=>{
    const a=document.createElement('a');a.className='mnode'+(chDone(c)?' done':'')+(c===cur?' cur':'');
    a.href='#'+c.id+'/'+c.pages[0].id;
    const row=Math.floor(i/4), col=i%4, rev=row%2===1;
    a.style.gridRow=row+1;a.style.gridColumn=(rev?4-col:col+1);
    const n=c.pages.length;
    a.innerHTML=`<div class="circ">${String(i+1).padStart(2,'0')}</div><h3>${c.title}</h3><p>${c.desc}</p><div class="mt">${c.min} min · ${n} ${n===1?'page':'pages'}</div>`;
    map.appendChild(a);
  });
  requestAnimationFrame(drawLinks);
  const nd=Object.keys(done).filter(k=>done[k]).length;
  $('#pcount').textContent=`${nd} / ${total} pages done`;
  $('#ccount').textContent=`${C.filter(chDone).length} / ${C.length} chapters`;
  $('#ptrack').style.width=(100*nd/total)+'%';
  const nxt=pages.find(x=>!done[x.key])||pages[0];
  $('#startbtn').href='#'+nxt.key;
  $('#startlbl').textContent=nd?'Continue':'Start the course';
  $('#starth').textContent=nd?`Next: ${nxt.c.title}.`:M.starth;
}
function drawLinks(){
  const map=$('#map'), svg=$('svg.links',map); if(!svg)return;
  const mr=map.getBoundingClientRect(), cs=$$('.circ',map).map(e=>{const r=e.getBoundingClientRect();return{x:r.left-mr.left+r.width/2,y:r.top-mr.top+r.height/2,r:r.width/2}});
  const mobile=innerWidth<=720;let d='';
  for(let i=0;i<cs.length-1;i++){const a=cs[i],b=cs[i+1];
    if(mobile){d+=`M${a.x},${a.y+a.r+4} L${b.x},${b.y-b.r-4} `;continue}
    if(Math.abs(a.y-b.y)<2){const s=Math.sign(b.x-a.x);d+=`M${a.x+s*(a.r+8)},${a.y} L${b.x-s*(b.r+8)},${b.y} `}
    else{const s=a.x>mr.width/2?1:-1, ex=s>0?mr.width+28:-28;d+=`M${a.x+s*(a.r+8)},${a.y} C${ex},${a.y} ${ex},${b.y} ${b.x+s*(b.r+8)},${b.y} `}
  }
  svg.innerHTML=`<path d="${d}"/>`;
}
addEventListener('resize',()=>{if(!home.hidden)drawLinks()});

function show(key){
  const i=pages.findIndex(x=>x.key===key); if(i<0){go('');return}
  const P=pages[i], c=P.c;
  home.hidden=true;chv.hidden=false;document.body.classList.remove('all');
  $('#crumb').textContent=`${String(P.ci+1).padStart(2,'0')} · ${c.title}`;
  $('#ppos').textContent=`Page ${P.pi+1} / ${c.pages.length}`;
  $('#snum').textContent=String(P.ci+1).padStart(2,'0');$('#stitle').textContent=c.title;$('#stime').textContent=`${c.min} min · ${c.pages.length} ${c.pages.length===1?'page':'pages'}`;
  $('#smenu').innerHTML=c.pages.map((p,j)=>`<li><a href="#${c.id}/${p.id}" class="${j===P.pi?'on':''} ${done[c.id+'/'+p.id]?'dn':''}"><b>${j+1}</b><span>${p.title}</span></a></li>`).join('');
  const pc=C[P.ci-1], nc=C[P.ci+1], cp=$('#chprev'), cn=$('#chnext');
  cp.classList.toggle('off',!pc); cn.classList.toggle('off',!nc);
  if(pc){cp.href='#'+pc.id+'/'+pc.pages[0].id;cp.textContent='‹ '+String(P.ci).padStart(2,'0')+' · '+pc.title}
  if(nc){cn.href='#'+nc.id+'/'+nc.pages[0].id;cn.textContent=String(P.ci+2).padStart(2,'0')+' · '+nc.title+' ›'}
  $$('article.pg').forEach(a=>a.classList.toggle('show',a.dataset.key===key));
  $('#bpos').innerHTML=`<b>${P.pi+1} / ${c.pages.length}</b> <span>&nbsp; ${c.title}</span>`;
  const prev=pages[i-1], next=pages[i+1];
  const bp=$('#bprev');bp.style.visibility=prev?'visible':'hidden';if(prev)bp.href='#'+prev.key;
  const bn=$('#bnext');bn.dataset.key=key;
  bn.href=next?'#'+next.key:'#map';
  $('#bnextl').textContent=next?(next.c!==c?'Next chapter':'Continue'):'Back to the map';
  $$('.nav a').forEach(a=>a.classList.remove('on'));
  scrollTo({top:0,behavior:'instant'});
  const art=$(`article.pg[data-key="${key}"]`);
  document.dispatchEvent(new CustomEvent('pageshown',{detail:art}));
  document.title=`${P.p.title} · ${M.short} · ISO`;
}
function showAll(){
  home.hidden=true;chv.hidden=false;document.body.classList.add('all');
  $$('article.pg').forEach(a=>a.classList.add('show'));
  $('#crumb').textContent='Read it all';$('#ppos').textContent=`${total} pages`;
  $('#snum').textContent='L'+M.num;$('#stitle').textContent='All chapters';$('#stime').textContent='';
  $$('.nav a').forEach(a=>a.classList.toggle('on',a.getAttribute('href')==='#all'));
  scrollTo({top:0});
  $$('article.pg').forEach(a=>document.dispatchEvent(new CustomEvent('pageshown',{detail:a})));
}
function go(h){location.hash=h}
function route(){
  const h=decodeURIComponent(location.hash.slice(1));
  if(h==='all')return showAll();
  if(h&&h!=='map')return show(h);
  chv.hidden=true;home.hidden=false;document.body.classList.remove('all');
  $$('.nav a').forEach(a=>a.classList.toggle('on',a.getAttribute('href')==='#map'));
  document.title=M.title;
  renderMap();scrollTo({top:0});
}
$('#bnext').addEventListener('click',e=>{done[e.currentTarget.dataset.key]=true;save()});
$('#reset').addEventListener('click',e=>{e.preventDefault();done={};save();renderMap()});
addEventListener('hashchange',route);

// quiz
$$('.q').forEach(q=>{
  const ok=+q.dataset.ok, fb=$('.fb',q);
  $$('button.o',q).forEach((b,i)=>b.addEventListener('click',()=>{
    $$('button.o',q).forEach(x=>x.classList.remove('ok','no'));
    b.classList.add(i===ok?'ok':'no'); if(i!==ok)$$('button.o',q)[ok].classList.add('ok');
    q.classList.add('answered');
    fb.innerHTML=(i===ok?'<b>Correct.</b> ':'<b>Not quite.</b> ')+fb.dataset.x;
  }));
});
$$('.codetabs .tabs button').forEach(b=>b.addEventListener('click',()=>{const l=b.dataset.l;
  $$('.codetabs').forEach(t=>{$$('.tabs button',t).forEach(x=>x.classList.toggle('on',x.dataset.l===l));$$('pre',t).forEach(p=>p.hidden=p.dataset.l!==l)})}));
const al=$('#aboutlink');if(al)al.addEventListener('click',e=>{e.preventDefault();const d=$('.aboutd');if(d)d.open=true;$('#about').scrollIntoView({behavior:'smooth'})});
route();
})();
