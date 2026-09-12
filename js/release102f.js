"use strict";

// Le Nid des Champions V1.0.2f
// Correctif affichage des clubs dans les classements C1.
// IMPORTANT : `state` est un binding global lexical déclaré par core.js ;
// il n'est pas attaché à l’objet Window.
(() => {
  const safe = value => Array.isArray(value) ? value : [];

  const normalize = value => String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[’'`´]/g, " ")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");

  // Filet de sécurité pour les joueurs J1 déjà injectés manuellement.
  // Le club_id reste prioritaire ; ce mapping n'est utilisé que si la référence
  // ne correspond plus à un club actuellement chargé.
  const aliases = {
    psg:["Paris Saint-Germain","Paris Saint-Germain FC","PSG","Paris-SG"],
    dortmund:["Borussia Dortmund","Dortmund","B. Dortmund"],
    stuttgart:["VfB Stuttgart","Stuttgart"],
    slavia:["Slavia Praha","Slavia Prague","SK Slavia Praha"],
    mancity:["Manchester City","Man City","Manchester City FC"],
    bayern:["Bayern München","Bayern Munich","FC Bayern München","Bayern"],
    barca:["FC Barcelona","Barcelona","FC Barcelone"],
    betis:["Real Betis","Real Betis Balompié","Betis"],
    lille:["Lille","LOSC","LOSC Lille"],
    real:["Real Madrid","Real Madrid CF"],
    inter:["Inter","Inter Milan","Internazionale","FC Internazionale Milano"],
    feyenoord:["Feyenoord","Feyenoord Rotterdam"],
    liverpool:["Liverpool","Liverpool FC"],
    atleti:["Atlético de Madrid","Atletico Madrid","Atlético Madrid","Atleti"],
    sporting:["Sporting CP","Sporting Portugal","Sporting Clube de Portugal","Sporting"],
    gala:["Galatasaray","Galatasaray SK"],
    arsenal:["Arsenal","Arsenal FC"],
    napoli:["Napoli","SSC Napoli"],
    fener:["Fenerbahçe","Fenerbahce","Fenerbahçe SK"],
    roma:["Roma","AS Roma"],
    psv:["PSV","PSV Eindhoven"],
    shakhtar:["Shakhtar Donetsk","FK Shakhtar Donetsk","Chakhtar Donetsk","Shakhtar"],
    como:["Como","Como 1907"],
    leipzig:["RB Leipzig","Leipzig"],
    bodo:["Bodø/Glimt","Bodo/Glimt","Bodö/Glimt"],
    manutd:["Manchester United","Man United","Manchester United FC"],
    sabah:["Sabah","Sabah FC","Sabah FK"],
    lens:["RC Lens","Lens","Racing Club de Lens"],
    porto:["FC Porto","Porto"],
    villa:["Aston Villa","Aston Villa FC"],
    brugge:["Club Brugge","Club Brugge KV","Club Bruges"],
    villarreal:["Villarreal","Villarreal CF"],
    slovan:["Slovan Bratislava","ŠK Slovan Bratislava","S. Bratislava"]
  };

  const playerClub = new Map(Object.entries({
    "Ferran Torres":"psg",
    "Ousmane Dembélé":"psg",
    "Fabián Ruiz":"psg",
    "Serhou Guirassy":"dortmund",
    "Ermedin Demirović":"stuttgart",
    "Danijel Šturm":"slavia",
    "Erling Haaland":"mancity",
    "Michael Olise":"bayern",
    "Raphinha":"barca",
    "Marc Bartra":"betis",
    "Troy Parrott":"betis",
    "Ethan Mbappé":"lille",
    "Fermín López Bernal":"betis",
    "Marc Roca":"betis",
    "Dean Huijsen":"real",
    "Hakan Çalhanoğlu":"inter",
    "Lautaro Martínez":"inter",
    "Yann Bisseck":"inter",
    "Dani Olmo":"barca",
    "Casper Vanhoutte":"feyenoord",
    "Alexis Mac Allister":"liverpool",
    "Dominik Szoboszlai":"liverpool",
    "Odin Bjørtuft":"bodo",
    "Mikuláš Konečný":"slavia",
    "Gianluigi Donnarumma":"mancity",
    "Kerem Aktürkoğlu":"fener",
    "Natan":"betis",
    "Gleiker Mendoza":"shakhtar",
    "Kylian Mbappé":"real",
    "Harry Kane":"bayern",
    "Jamal Musiala":"bayern",
    "Martin Ødegaard":"arsenal",
    "Billy Gilmour":"napoli",
    "Lorenzo Lucca":"napoli",
    "Sergiño Dest":"psv",
    "Martin Baturina":"como",
    "Nico Paz":"como"
  }).map(([name,key]) => [normalize(name), key]));

  function clubsV102f(){
    // `state` vient de core.js. Utiliser directement ce binding lexical.
    return (typeof state !== "undefined") ? safe(state.clubs) : [];
  }

  function clubByIdV102f(id){
    if(id == null) return null;
    if(typeof clubById === "function"){
      const c = clubById(id);
      if(c) return c;
    }
    return clubsV102f().find(c => String(c?.id) === String(id)) || null;
  }

  function clubByAliasesV102f(key){
    const names = safe(aliases[key]).map(normalize).filter(Boolean);
    if(!names.length) return null;
    const clubs = clubsV102f();

    const exact = clubs.find(c => [c?.name,c?.short_name,c?.tla]
      .map(normalize)
      .some(n => names.includes(n)));
    if(exact) return exact;

    const fuzzy = clubs.filter(c => [c?.name,c?.short_name]
      .map(normalize)
      .some(n => n && names.some(a => a.length >= 5 && (n.includes(a) || a.includes(n)))));
    return fuzzy.length === 1 ? fuzzy[0] : null;
  }

  function siblingClubV102f(row){
    if(typeof state === "undefined") return null;
    const key = normalize(row?.player_name);
    if(!key) return null;
    const rows = [...safe(state.uclScorersV101), ...safe(state.uclDisciplineV101)];
    for(const other of rows){
      if(normalize(other?.player_name) !== key) continue;
      const c = clubByIdV102f(other?.club_id);
      if(c) return c;
    }
    return null;
  }

  function resolveClubV102f(row){
    let club = clubByIdV102f(row?.club_id);
    if(club) return club;

    club = siblingClubV102f(row);
    if(club) return club;

    const aliasKey = playerClub.get(normalize(row?.player_name));
    return aliasKey ? clubByAliasesV102f(aliasKey) : null;
  }

  // release101 consulte précisément cette fonction si elle existe.
  // On remplace donc le résolveur cassé de 1.0.2e.
  window.uclResolvePlayerClubV102e = resolveClubV102f;
  window.uclResolvePlayerClubV102f = resolveClubV102f;

  function repairRowsV102f(){
    if(typeof state === "undefined") return;
    const groups = [safe(state.uclScorersV101), safe(state.uclDisciplineV101)];
    for(const rows of groups){
      for(const row of rows){
        const club = resolveClubV102f(row);
        if(club) row.club_id = club.id;
      }
    }
  }
  window.repairUclPlayerClubsV102f = repairRowsV102f;

  // Corrige aussi le no-op de 1.0.2d : utiliser le binding lexical `state`.
  function cleanRowsV102f(){
    if(typeof state === "undefined") return;
    if(typeof window.uclDedupeRowsV102d === "function"){
      state.uclScorersV101 = window.uclDedupeRowsV102d(state.uclScorersV101, "scorers");
      state.uclDisciplineV101 = window.uclDedupeRowsV102d(state.uclDisciplineV101, "discipline");
    }
    repairRowsV102f();
  }
  window.cleanUclPlayerStatsV102f = cleanRowsV102f;

  // Les wrappers précédents sont conservés ; ce wrapper final travaille avec
  // le vrai binding `state`, puis laisse la chaîne existante effectuer le rendu.
  const previousLoad = window.loadUclCenterData;
  if(typeof previousLoad === "function"){
    window.loadUclCenterData = async function(){
      const result = await previousLoad.apply(this, arguments);
      cleanRowsV102f();
      return result;
    };
  }

  const previousRender = window.renderUclCenter;
  if(typeof previousRender === "function"){
    window.renderUclCenter = function(){
      cleanRowsV102f();
      return previousRender.apply(this, arguments);
    };
  }

  window.renderRelease102f = cleanRowsV102f;
})();
