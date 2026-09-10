"use strict";

// Le Nid des Champions V0.9.14 — badges 2026, reveals par rareté et Musée interactif.
(() => {
  const RARITY_ORDER={common:1,rare:2,epic:3,legendary:4,secret:5};

  function badgeDateV0914(value){
    if(!value)return "—";
    const d=new Date(value);if(Number.isNaN(d.getTime()))return fmtDate(value);
    return d.toLocaleDateString("fr-FR",{day:"2-digit",month:"long",year:"numeric"});
  }
  function highestRarityV0914(rows){
    return [...(rows||[])].sort((a,b)=>(RARITY_ORDER[b?.rarity]||0)-(RARITY_ORDER[a?.rarity]||0))[0]?.rarity||"common";
  }
  function findBadgeV0914(id){
    return (state.museumSummary?.badges||[]).find(b=>String(b.badge_id||b.id)===String(id));
  }
  function particlesHTMLV0914(count=18){
    return `<div class="badge-particles-v0914" aria-hidden="true">${Array.from({length:count},(_,i)=>`<i style="--i:${i}"></i>`).join("")}</div>`;
  }
  function ringsHTMLV0914(){return `<div class="badge-rings-v0914" aria-hidden="true"><i></i><i></i><i></i></div>`;}

  function animateWithWAAPIV0914(stage,rarity){
    const emblem=stage?.querySelector(".badge-art-v0914");
    const card=stage?.closest(".badge-reveal-card-v0914,.museum-badge-detail-v0914")||stage;
    if(!emblem)return;
    const base=[{opacity:0,transform:"translateY(18px) scale(.72)"},{opacity:1,transform:"translateY(0) scale(1)"}];
    emblem.animate(base,{duration:rarity==="legendary"?820:rarity==="epic"?680:480,easing:"cubic-bezier(.2,.85,.2,1)",fill:"both"});
    if(rarity==="rare") card?.animate([{filter:"brightness(.8)"},{filter:"brightness(1.28)"},{filter:"brightness(1)"}],{duration:900,easing:"ease-out"});
    if(rarity==="epic") emblem.animate([{transform:"scale(.7) rotate(-8deg)"},{transform:"scale(1.1) rotate(3deg)"},{transform:"scale(1) rotate(0)"}],{duration:900,easing:"cubic-bezier(.18,.9,.22,1)"});
    if(rarity==="legendary") card?.animate([{boxShadow:"0 0 0 rgba(255,210,88,0)"},{boxShadow:"0 0 110px rgba(255,210,88,.48)"},{boxShadow:"0 0 58px rgba(255,210,88,.22)"}],{duration:1500,easing:"ease-out",fill:"both"});
    if(rarity==="secret") emblem.animate([{opacity:0,filter:"blur(14px)",transform:"scale(.78)"},{opacity:1,filter:"blur(0)",transform:"scale(1.04)"},{transform:"scale(1)"}],{duration:1050,easing:"cubic-bezier(.2,.8,.2,1)",fill:"both"});
  }

  function playBadgeAnimationV0914(stage,rarity="common"){
    if(!stage)return;
    const card=stage.closest(".badge-reveal-card-v0914,.museum-badge-detail-v0914")||stage;
    const emblem=stage.querySelector(".badge-art-v0914");
    const title=card.querySelector(".badge-reveal-title-v0914,.museum-badge-detail-title-v0914");
    const meta=[...card.querySelectorAll(".badge-reveal-meta-v0914,.museum-badge-detail-meta-v0914,.museum-badge-detail-desc-v0914")];
    const particles=[...stage.querySelectorAll(".badge-particles-v0914 i")];
    const rings=[...stage.querySelectorAll(".badge-rings-v0914 i")];
    if(window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches){stage.classList.add("anim-done-v0914");return;}

    if(window.gsap){
      const g=window.gsap;
      const tl=g.timeline({defaults:{ease:"power3.out"}});
      g.set(card,{transformOrigin:"50% 50%"});
      tl.from(card,{autoAlpha:0,y:22,scale:.94,duration:.32})
        .from(emblem,{autoAlpha:0,scale:.54,rotation:-7,duration:.48},"<.04");
      if(title)tl.from(title,{autoAlpha:0,y:14,duration:.22},"-=.2");
      if(meta.length)tl.from(meta,{autoAlpha:0,y:10,stagger:.05,duration:.18},"-=.12");

      if(rarity==="common"){
        tl.to(emblem,{scale:1.035,duration:.14,yoyo:true,repeat:1,ease:"sine.inOut"},"-=.08");
      }else if(rarity==="rare"){
        tl.fromTo(rings,{scale:.45,autoAlpha:.9},{scale:1.7,autoAlpha:0,stagger:.12,duration:.7,ease:"power2.out"},"-=.28");
        tl.to(emblem,{filter:"drop-shadow(0 0 18px rgba(80,190,255,.72))",duration:.28,yoyo:true,repeat:1},"-=.62");
      }else if(rarity==="epic"){
        tl.to(card,{boxShadow:"0 0 85px rgba(142,78,255,.34)",duration:.32},"-=.28");
        particles.forEach((p,i)=>g.fromTo(p,{x:0,y:0,scale:0,autoAlpha:0},{x:(i%2?1:-1)*(28+(i%7)*12),y:-25-(i%5)*20,scale:.5+(i%4)*.18,autoAlpha:1,duration:.42+(i%3)*.08,delay:i*.012,ease:"power2.out"}));
        if(window.anime){
          window.anime({targets:emblem,scale:[.72,1.13,1],rotate:[-9,4,0],duration:1050,easing:"easeOutElastic(1,.62)"});
        }else tl.to(emblem,{scale:1.1,rotation:3,duration:.22,yoyo:true,repeat:1},"-=.42");
      }else if(rarity==="legendary"){
        tl.fromTo(card,{filter:"brightness(.72)",boxShadow:"0 0 0 rgba(255,213,92,0)"},{filter:"brightness(1.16)",boxShadow:"0 0 120px rgba(255,213,92,.5)",duration:.52},"-=.32")
          .to(card,{filter:"brightness(1)",boxShadow:"0 0 62px rgba(255,213,92,.24)",duration:.48});
        tl.fromTo(rings,{scale:.2,autoAlpha:.95,rotation:-30},{scale:2.1,autoAlpha:0,rotation:25,stagger:.11,duration:.86,ease:"power2.out"},"-=.82");
        particles.forEach((p,i)=>g.fromTo(p,{x:0,y:8,scale:0,autoAlpha:0},{x:(i%2?1:-1)*(38+(i%6)*15),y:-38-(i%5)*24,scale:.6+(i%4)*.2,autoAlpha:1,duration:.65+(i%4)*.08,delay:i*.014,ease:"power2.out"}));
        tl.to(emblem,{scale:1.075,duration:.2,yoyo:true,repeat:1,ease:"sine.inOut"},"-=.7");
      }else if(rarity==="secret"){
        tl.fromTo(card,{filter:"blur(8px) brightness(.55)"},{filter:"blur(0) brightness(1.08)",duration:.58},"-=.28")
          .to(card,{filter:"brightness(1)",duration:.28});
        if(window.anime){
          window.anime({targets:emblem,opacity:[0,1],scale:[.65,1.08,1],filter:["blur(14px)","blur(0px)"],duration:1150,easing:"easeOutExpo"});
        }
        particles.forEach((p,i)=>g.fromTo(p,{x:0,y:0,scale:0,autoAlpha:0},{x:(i%2?1:-1)*(22+(i%8)*10),y:(i%3-1)*(24+(i%5)*14),scale:.45+(i%5)*.17,autoAlpha:.85,duration:.75,delay:i*.018,ease:"power2.out"}));
      }
      tl.call(()=>stage.classList.add("anim-done-v0914"));
      return;
    }
    animateWithWAAPIV0914(stage,rarity);
    stage.classList.add("anim-done-v0914");
  }

  function badgeArtHTMLV0914(b,large=false){
    const locked=!b?.obtained,secretLocked=b?.is_secret&&locked;
    const visual=(!secretLocked&&badgeVisual(b))?`<img src="${esc(badgeVisual(b))}" alt="">`:`<b>${secretLocked?"?":genericBadgeIcon(b?.rarity)}</b>`;
    return `<div class="badge-art-v0914 ${esc(b?.rarity||"common")} ${large?"large":""}">${visual}<span class="badge-rarity-mark-v0914">${rarityIcon(b?.rarity)}</span></div>`;
  }

  function openMuseumBadgeV0914(id){
    const b=findBadgeV0914(id);if(!b)return;
    const locked=!b.obtained,secretLocked=b.is_secret&&locked,p=badgeProgressData(b);
    const title=secretLocked?"Succès secret":badgeVisibleName(b);
    const root=modal(`🏛️ ${title}`,`<div class="museum-badge-detail-v0914 rarity-${esc(b.rarity)} ${locked?"locked":"obtained"}">
      <div class="badge-stage-v0914 museum-stage-v0914">
        ${particlesHTMLV0914(b.rarity==="legendary"?26:b.rarity==="epic"||b.rarity==="secret"?22:14)}${ringsHTMLV0914()}
        ${badgeArtHTMLV0914(b,true)}
      </div>
      <div class="museum-badge-detail-copy-v0914">
        <div class="museum-badge-detail-chips-v0914"><span>${esc(rarityLabel(b.rarity))}</span>${b.category?`<span>${esc(b.category)}</span>`:""}<span>${b.scope==="career"?"Carrière":"Saison"}</span>${b.first_discovery?"<span>🥇 Premier découvreur</span>":""}</div>
        <h2 class="museum-badge-detail-title-v0914">${esc(title)}</h2>
        <p class="museum-badge-detail-desc-v0914">${esc(secretLocked?"Ce succès secret n’a pas encore été découvert.":b.description||"")}</p>
        <div class="museum-badge-detail-meta-v0914"><div><small>Statut</small><strong>${locked?"À débloquer":"Débloqué"}</strong></div><div><small>Date d’obtention</small><strong>${b.earned_at?esc(badgeDateV0914(b.earned_at)):"—"}</strong></div></div>
        ${locked&&p?`<div class="badge-progress detail-v0914"><i style="width:${p.pct}%"></i></div><small class="museum-badge-detail-progress-v0914">${esc(p.label)}</small>`:""}
      </div>
    </div>`);
    const detail=root.querySelector(".museum-badge-detail-v0914");
    requestAnimationFrame(()=>playBadgeAnimationV0914(detail?.querySelector(".badge-stage-v0914")||detail,b.rarity));
  }
  window.openMuseumBadgeV0914=openMuseumBadgeV0914;

  // V0.9.14 replaces the older reveal while keeping the existing award detection.
  window.showBadgeReveal=function showBadgeRevealV0914(badges){
    const rows=(badges||[]).filter(Boolean);if(!rows.length||document.querySelector("#badgeRevealV0914"))return;
    const rarity=highestRarityV0914(rows),single=rows.length===1,first=rows[0];
    const wrap=document.createElement("div");wrap.id="badgeRevealV0914";wrap.className=`badge-reveal-v0914 reveal-${rarity}`;
    const title=single?(first.is_secret?"SECRET DÉCOUVERT":"NOUVEAU SUCCÈS"):`${rows.length} NOUVEAUX SUCCÈS`;
    const date=single&&first.earned_at?badgeDateV0914(first.earned_at):"";
    wrap.innerHTML=`<div class="badge-reveal-card-v0914 rarity-${esc(rarity)}"><div class="badge-stage-v0914">
      ${particlesHTMLV0914(rarity==="legendary"?30:rarity==="epic"||rarity==="secret"?24:14)}${ringsHTMLV0914()}
      ${single?badgeArtHTMLV0914(first,true):`<div class="badge-reveal-gallery-v0914">${rows.slice(0,8).map(b=>badgeArtHTMLV0914(b,false)).join("")}</div>`}
      </div>
      <span class="eyebrow gold badge-reveal-kicker-v0914">${esc(title)}</span>
      <h2 class="badge-reveal-title-v0914">${esc(single?(first.name||"Succès"):"Le Musée s’agrandit")}</h2>
      <p class="badge-reveal-meta-v0914">${esc(single?(first.description||""):`Le niveau de révélation suit le succès le plus rare obtenu.`)}</p>
      ${date?`<time class="badge-reveal-meta-v0914">Débloqué le ${esc(date)}</time>`:""}
      <div class="badge-reveal-actions-v0914"><button class="btn gold" type="button" id="badgeRevealMuseumV0914">Voir dans le Musée</button><button class="btn secondary" type="button" id="badgeRevealCloseV0914">Continuer</button></div>
    </div>`;
    document.body.appendChild(wrap);
    const stage=wrap.querySelector(".badge-stage-v0914");requestAnimationFrame(()=>playBadgeAnimationV0914(stage,rarity));
    const close=()=>wrap.remove();
    wrap.querySelector("#badgeRevealCloseV0914")?.addEventListener("click",close);
    wrap.addEventListener("click",e=>{if(e.target===wrap)close();});
    wrap.querySelector("#badgeRevealMuseumV0914")?.addEventListener("click",()=>{
      close();setView("museum");
      if(single)setTimeout(()=>openMuseumBadgeV0914(first.badge_id||first.id),220);
    });
  };

  function wireMuseumV0914(){
    const root=document.querySelector("#museumRoot");if(!root||root.dataset.badgeClickV0914)return;
    root.dataset.badgeClickV0914="1";
    root.addEventListener("click",e=>{
      const card=e.target.closest(".museum-badge[data-badge-id]");if(!card||!root.contains(card))return;
      openMuseumBadgeV0914(card.dataset.badgeId);
    });
    root.addEventListener("keydown",e=>{
      if(e.key!=="Enter"&&e.key!==" ")return;
      const card=e.target.closest(".museum-badge[data-badge-id]");if(!card||!root.contains(card))return;
      e.preventDefault();openMuseumBadgeV0914(card.dataset.badgeId);
    });
    const observer=new MutationObserver(()=>{
      root.querySelectorAll(".museum-badge[data-badge-id]").forEach(card=>{
        card.tabIndex=0;card.setAttribute("role","button");card.setAttribute("aria-label",`Ouvrir le succès ${card.querySelector("h4")?.textContent||""}`.trim());
      });
    });
    observer.observe(root,{subtree:true,childList:true});
    root.querySelectorAll(".museum-badge[data-badge-id]").forEach(card=>{card.tabIndex=0;card.setAttribute("role","button");});
  }

  function initV0914(){wireMuseumV0914();}
  if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",initV0914,{once:true});else initV0914();
})();
