"use strict";

// Le Nid des Champions V1.0.2c
// - dédoublonnage défensif des classements buteurs / cartons
// - affichage mobile correct de la sanction la plus importante
// - conservation du club connu quand une ligne doublon n'en possède pas
(() => {
  const safe = value => Array.isArray(value) ? value : [];
  const byId = id => document.getElementById(id);

  const playerKeyV102c = value => String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[’'`´]/g, " ")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");

  function preferredRowV102c(rows){
    return rows.slice().sort((a,b)=>
      Number(Boolean(b.club_id))-Number(Boolean(a.club_id)) ||
      Number(Number(b.player_external_id)>0)-Number(Number(a.player_external_id)>0) ||
      new Date(b.updated_at||0)-new Date(a.updated_at||0)
    )[0] || {};
  }

  function preferredClubV102c(rows){
    const row = rows.slice().sort((a,b)=>
      Number(Boolean(b.club_id))-Number(Boolean(a.club_id)) ||
      Number(Number(b.player_external_id)>0)-Number(Number(a.player_external_id)>0) ||
      new Date(b.updated_at||0)-new Date(a.updated_at||0)
    ).find(x=>x.club_id);
    return row?.club_id || null;
  }

  function dedupeRowsV102c(rows, kind){
    const groups = new Map();
    safe(rows).forEach(row=>{
      const key = playerKeyV102c(row?.player_name) || `id:${row?.player_external_id}`;
      if(!groups.has(key)) groups.set(key,[]);
      groups.get(key).push(row);
    });

    const out=[];
    for(const items of groups.values()){
      const base={...preferredRowV102c(items)};
      base.club_id = preferredClubV102c(items) || base.club_id || null;
      if(kind === "scorers"){
        for(const field of ["played_matches","goals","assists","penalties"]){
          base[field]=Math.max(...items.map(x=>Number(x?.[field]||0)),0);
        }
      }else{
        for(const field of ["yellow_cards","yellow_red_cards","red_cards"]){
          base[field]=Math.max(...items.map(x=>Number(x?.[field]||0)),0);
        }
      }
      out.push(base);
    }

    if(kind === "scorers"){
      out.sort((a,b)=>Number(b.goals||0)-Number(a.goals||0)||Number(b.assists||0)-Number(a.assists||0)||Number(b.played_matches||0)-Number(a.played_matches||0)||String(a.player_name||"").localeCompare(String(b.player_name||""),"fr"));
    }else{
      const score=x=>Number(x.red_cards||0)*100+Number(x.yellow_red_cards||0)*20+Number(x.yellow_cards||0);
      out.sort((a,b)=>score(b)-score(a)||String(a.player_name||"").localeCompare(String(b.player_name||""),"fr"));
    }
    return out;
  }

  function cleanUclPlayerStatsV102c(){
    if(!window.state) return;
    state.uclScorersV101 = dedupeRowsV102c(state.uclScorersV101,"scorers");
    state.uclDisciplineV101 = dedupeRowsV102c(state.uclDisciplineV101,"discipline");
  }
  window.cleanUclPlayerStatsV102c=cleanUclPlayerStatsV102c;

  function visibleDisciplineRowsV102c(){
    const score=x=>Number(x.red_cards||0)*100+Number(x.yellow_red_cards||0)*20+Number(x.yellow_cards||0);
    return dedupeRowsV102c(state?.uclDisciplineV101,"discipline").filter(x=>score(x)>0).slice(0,30);
  }

  function fixDisciplineDisplayV102c(){
    const root=byId("uclCenterRoot");
    if(!root || root._fixingCardsV102c) return;
    const grid=root.querySelector("#uclTabBody .ucl-stats-grid-v101");
    if(!grid) return;
    const section=grid.querySelectorAll(":scope > section")[1];
    if(!section) return;
    const buttons=[...section.querySelectorAll(".ucl-player-row-v101")];
    const rows=visibleDisciplineRowsV102c();
    root._fixingCardsV102c=true;
    try{
      buttons.forEach((button,index)=>{
        const data=rows[index]; if(!data)return;
        button.classList.add("ucl-discipline-row-v102c");
        const main=button.querySelector(":scope > b.cards-v101");
        const detail=button.querySelector(":scope > small:last-child");
        const y=Number(data.yellow_cards||0),yr=Number(data.yellow_red_cards||0),r=Number(data.red_cards||0);
        let primary="";
        if(r>0) primary=`${r} 🟥`;
        else if(yr>0) primary=`${yr} 🟨🟥`;
        else primary=`${y} 🟨`;
        if(main) main.textContent=primary;
        const all=[];
        if(y>0) all.push(`${y} 🟨`);
        if(yr>0) all.push(`${yr} 🟨🟥`);
        if(r>0) all.push(`${r} 🟥`);
        if(detail) detail.textContent=all.join(" · ");
        button.title=all.join(" · ");
      });
    }finally{root._fixingCardsV102c=false;}
  }
  window.fixDisciplineDisplayV102c=fixDisciplineDisplayV102c;

  function watchUclCenterV102c(){
    const root=byId("uclCenterRoot");
    if(!root || root._watchV102c)return;
    let timer=null;
    const observer=new MutationObserver(()=>{
      clearTimeout(timer);
      timer=setTimeout(()=>{cleanUclPlayerStatsV102c();fixDisciplineDisplayV102c();},20);
    });
    observer.observe(root,{childList:true,subtree:true});
    root._watchV102c=observer;
  }

  const baseLoadV102c=window.loadUclCenterData;
  if(typeof baseLoadV102c==="function"){
    window.loadUclCenterData=async function(){
      const out=await baseLoadV102c.apply(this,arguments);
      cleanUclPlayerStatsV102c();
      return out;
    };
  }

  const baseRenderUclV102c=window.renderUclCenter;
  if(typeof baseRenderUclV102c==="function"){
    window.renderUclCenter=function(){
      cleanUclPlayerStatsV102c();
      const out=baseRenderUclV102c.apply(this,arguments);
      watchUclCenterV102c();
      fixDisciplineDisplayV102c();
      return out;
    };
  }

  window.renderRelease102c=function(){
    cleanUclPlayerStatsV102c();
    watchUclCenterV102c();
    fixDisciplineDisplayV102c();
  };
})();
