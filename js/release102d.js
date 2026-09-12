"use strict";

// Le Nid des Champions V1.0.2d
// - dédoublonnage robuste des buteurs/cartons par nom normalisé
// - priorité aux identifiants provider positifs
// - affichage d'une seule synthèse de cartons par joueur
(() => {
  const safe = value => Array.isArray(value) ? value : [];

  function playerKeyV102d(value){
    return String(value || "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/[’'`´]/g, " ")
      .replace(/[^a-z0-9]+/g, " ")
      .trim()
      .replace(/\s+/g, " ");
  }
  window.uclPlayerKeyV102d = playerKeyV102d;

  function preferredRowV102d(items){
    return items.slice().sort((a,b)=>
      Number(Number(b?.player_external_id) > 0) - Number(Number(a?.player_external_id) > 0) ||
      Number(Boolean(b?.club_id)) - Number(Boolean(a?.club_id)) ||
      new Date(b?.updated_at || 0) - new Date(a?.updated_at || 0)
    )[0] || {};
  }

  function bestClubV102d(items){
    const provider = items.slice().sort((a,b)=>
      Number(Number(b?.player_external_id) > 0) - Number(Number(a?.player_external_id) > 0) ||
      new Date(b?.updated_at || 0) - new Date(a?.updated_at || 0)
    ).find(x=>x?.club_id);
    return provider?.club_id || null;
  }

  function dedupeRowsV102d(rows, kind="scorers"){
    const groups = new Map();
    for(const row of safe(rows)){
      const key = playerKeyV102d(row?.player_name) || `id:${row?.player_external_id}`;
      if(!groups.has(key)) groups.set(key, []);
      groups.get(key).push(row);
    }

    const out=[];
    for(const items of groups.values()){
      const base={...preferredRowV102d(items)};
      base.club_id = bestClubV102d(items) || base.club_id || null;
      const bestName = items.find(x=>String(x?.player_name||"").trim())?.player_name;
      if(bestName) base.player_name = bestName;

      if(kind === "discipline"){
        for(const field of ["yellow_cards","yellow_red_cards","red_cards"]){
          base[field] = Math.max(0, ...items.map(x=>Number(x?.[field] || 0)));
        }
      }else{
        for(const field of ["played_matches","goals","assists","penalties"]){
          base[field] = Math.max(0, ...items.map(x=>Number(x?.[field] || 0)));
        }
      }
      out.push(base);
    }
    return out;
  }
  window.uclDedupeRowsV102d = dedupeRowsV102d;

  function disciplineLabelV102d(row){
    const y=Number(row?.yellow_cards||0), yr=Number(row?.yellow_red_cards||0), r=Number(row?.red_cards||0);
    const parts=[];
    if(y>0) parts.push(`${y} 🟨`);
    if(yr>0) parts.push(`${yr} 🟨🟥`);
    if(r>0) parts.push(`${r} 🟥`);
    return parts.join(" · ") || "0";
  }
  window.uclDisciplineLabelV102d = disciplineLabelV102d;

  function cleanStateV102d(){
    if(!window.state) return;
    state.uclScorersV101 = dedupeRowsV102d(state.uclScorersV101, "scorers");
    state.uclDisciplineV101 = dedupeRowsV102d(state.uclDisciplineV101, "discipline");
  }
  window.cleanUclPlayerStatsV102d = cleanStateV102d;

  // Nettoie également après chaque rechargement API/manuel.
  const baseLoad = window.loadUclCenterData;
  if(typeof baseLoad === "function"){
    window.loadUclCenterData = async function(){
      const result = await baseLoad.apply(this, arguments);
      cleanStateV102d();
      return result;
    };
  }

  const baseRender = window.renderUclCenter;
  if(typeof baseRender === "function"){
    window.renderUclCenter = function(){
      cleanStateV102d();
      return baseRender.apply(this, arguments);
    };
  }

  window.renderRelease102d = function(){ cleanStateV102d(); };
})();
