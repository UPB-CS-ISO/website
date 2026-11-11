/* ========== W6: flashcards / recap ========== */
function wFlash(root){
  const grid=root.querySelector('.rgrid'), cards=[...grid.children], KEY=window.COURSE_META.key+'-fc';
  let known=new Set();try{known=new Set(JSON.parse(localStorage.getItem(KEY)||'[]'))}catch(e){}
  const save=()=>{try{localStorage.setItem(KEY,JSON.stringify([...known]))}catch(e){}};
  cards.forEach((c,i)=>c.dataset.i=i);
  const chs=[...new Set(cards.map(c=>c.dataset.ch))];
  // the name of every chapter, from the label of its first card ("02 · Paths")
  const chName=ch=>{const c=cards.find(x=>x.dataset.ch===ch);const m=c&&c.querySelector('.rmeta');return m?m.textContent.split('·').slice(1).join('·').trim():''};
  let mode='recap', filt='all', deck=[], pos=0;
  const bar=el(`<div class="rbar"><div class="seg rmode" data-seg="mode"><button type="button" data-v="recap" class="on">Recap</button><button type="button" data-v="flash">Flashcard</button></div>
    <div class="rchips"><span class="rchl">Chapter</span><button type="button" data-f="all" class="on">All</button>${chs.map(c=>`<button type="button" data-f="${c}" title="${chName(c)}">${c} <span>${chName(c)}</span></button>`).join('')}</div></div>`);
  const empty=el(`<div class="rempty" hidden><p></p><button type="button" class="btn">Show them again</button></div>`);
  grid.appendChild(empty);
  const ctl=el(`<div class="rctl" hidden><div class="fbtns"><button type="button" data-a="prev">←</button><button type="button" data-a="next">→</button><button type="button" data-a="shuf">Shuffle</button></div>
    <div class="rpos"></div><div class="fbtns"><button type="button" class="r" data-a="again">Again</button><button type="button" class="k" data-a="know">Got it</button></div>
    <div class="rstat"></div></div>`);
  root.insertBefore(bar,grid); root.appendChild(ctl);
  const inF=c=>filt==='all'||c.dataset.ch===filt;
  function render(){
    root.classList.toggle('flashmode',mode==='flash'); ctl.hidden=mode!=='flash';
    cards.forEach(c=>{c.classList.remove('cur','flip');c.hidden=!inF(c)});
    empty.hidden=true;
    bar.querySelectorAll('.rchips button').forEach(x=>x.classList.remove('here'));
    if(mode==='recap')return;
    if(!deck.length){
      cards.forEach(c=>c.hidden=true);
      empty.querySelector('p').innerHTML=`You marked every card ${filt==='all'?'':'of chapter <b>'+filt+' · '+chName(filt)+'</b> '}with <b>Got it</b>.`;
      empty.hidden=false; ctl.querySelector('.rpos').textContent='0 / 0'; stat(); return}
    cards.forEach(c=>c.hidden=true); const c=cards[deck[pos]]; c.hidden=false; c.classList.add('cur');
    // the chapter of the card on screen is marked in the chapter row
    const chip=bar.querySelector(`.rchips button[data-f="${c.dataset.ch}"]`); if(chip&&filt==='all')chip.classList.add('here');
    ctl.querySelector('.rpos').textContent='card '+(pos+1)+' / '+deck.length; stat();
  }
  function stat(){const sel=cards.filter(inF);ctl.querySelector('.rstat').innerHTML=`Got it: <b>${sel.filter(c=>known.has(+c.dataset.i)).length}</b> of ${sel.length} · <a href="#" data-a="reset">reset</a>`}
  function rebuild(){deck=cards.filter(c=>inF(c)&&!known.has(+c.dataset.i)).map(c=>+c.dataset.i);pos=Math.min(pos,Math.max(deck.length-1,0));render()}
  bindSeg(root,'mode',v=>{mode=v;pos=0;rebuild()});
  bar.querySelectorAll('.rchips button').forEach(b=>b.addEventListener('click',()=>{bar.querySelectorAll('.rchips button').forEach(x=>x.classList.toggle('on',x===b));filt=b.dataset.f;pos=0;rebuild()}));
  empty.querySelector('button').addEventListener('click',()=>{cards.filter(inF).forEach(c=>known.delete(+c.dataset.i));save();pos=0;rebuild()});
  const flip=()=>{const c=root.querySelector('.rc.cur');if(c)c.classList.toggle('flip')};
  cards.forEach(c=>c.addEventListener('click',e=>{if(mode!=='flash'||e.target.closest('a'))return;flip()}));
  ctl.addEventListener('click',e=>{const a=e.target.closest('[data-a]');if(!a)return;e.preventDefault();const act=a.dataset.a;
    if(act==='reset'){known.clear();save();rebuild();return}
    if(!deck.length)return;
    if(act==='next')pos=(pos+1)%deck.length;
    else if(act==='prev')pos=(pos-1+deck.length)%deck.length;
    else if(act==='shuf'){for(let i=deck.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[deck[i],deck[j]]=[deck[j],deck[i]]}pos=0}
    else if(act==='know'){known.add(deck[pos]);save();rebuild();return}
    else if(act==='again'){const i=deck.splice(pos,1)[0];deck.push(i);if(pos>=deck.length)pos=0}
    render()});
  addEventListener('keydown',e=>{if(mode!=='flash'||!root.offsetParent||/INPUT|SELECT|TEXTAREA/.test(document.activeElement.tagName))return;
    if(e.code==='Space'){e.preventDefault();flip()}else if(e.key==='ArrowRight')ctl.querySelector('[data-a=next]').click();else if(e.key==='ArrowLeft')ctl.querySelector('[data-a=prev]').click()});
  rebuild();
}

