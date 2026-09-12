"use strict";

// Le Nid des Champions V1.0.2e
// Répare l'affichage des clubs des buteurs/cartons après dédoublonnage.
// - préfère toujours un club actif réellement chargé dans state.clubs
// - recoupe buteurs <-> discipline
// - utilise le mapping J1 déjà importé comme dernier filet de sécurité
(() => {
  const safe = value => Array.isArray(value) ? value : [];
  const normalize = value => String(value || "")
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .toLowerCase().replace(/[’'`´]/g, " ")
    .replace(/[^a-z0-9]+/g, " ").trim().replace(/\s+/g, " ");

  const clubAliases = {"aek":["AEK Athens","AEK Athènes","AEK"],"lask":["LASK","LASK Linz","Linz ASK"],"brugge":["Club Brugge","Club Brugge KV","Club Bruges"],"villa":["Aston Villa","Aston Villa FC"],"dortmund":["Borussia Dortmund","B. Dortmund","Dortmund"],"villarreal":["Villarreal","Villarreal CF"],"porto":["FC Porto","Porto"],"mancity":["Manchester City","Man City","Manchester City FC"],"lille":["Lille","LOSC","LOSC Lille"],"betis":["Real Betis","Real Betis Balompié","Betis Séville","Betis"],"real":["Real Madrid","Real Madrid CF"],"inter":["Inter","Inter Milan","Internazionale","FC Internazionale Milano"],"barca":["FC Barcelona","Barcelona","FC Barcelone"],"feyenoord":["Feyenoord","Feyenoord Rotterdam"],"stuttgart":["VfB Stuttgart","Stuttgart"],"viking":["Viking","Viking FK","Viking Stavanger"],"liverpool":["Liverpool","Liverpool FC"],"atleti":["Atlético de Madrid","Atletico Madrid","Atlético Madrid","Atleti"],"psg":["Paris Saint-Germain","Paris Saint-Germain FC","Paris-SG","PSG","Paris"],"slovan":["Slovan Bratislava","ŠK Slovan Bratislava","S. Bratislava"],"sporting":["Sporting CP","Sporting Portugal","Sporting Clube de Portugal","Sporting"],"gala":["Galatasaray","Galatasaray SK"],"napoli":["Napoli","SSC Napoli","Naples"],"arsenal":["Arsenal","Arsenal FC"],"fener":["Fenerbahçe","Fenerbahce","Fenerbahçe SK"],"roma":["Roma","AS Roma","AS Rome"],"psv":["PSV","PSV Eindhoven"],"shakhtar":["Shakhtar Donetsk","Chakhtar Donetsk","Shakhtar"],"como":["Como","Como 1907","Côme"],"leipzig":["RB Leipzig","Leipzig"],"bayern":["Bayern München","Bayern Munich","FC Bayern München","Bayern"],"bodo":["Bodø/Glimt","Bodo/Glimt","Bodö/Glimt"],"manutd":["Manchester United","Man United","Manchester United FC"],"sabah":["Sabah","Sabah FC","Sabah FK"],"slavia":["Slavia Praha","Slavia Prague","SK Slavia Praha"],"lens":["RC Lens","Lens","Racing Club de Lens"]};
  const playerClubRaw = {"Răzvan Marin":"aek","Luka Jović":"aek","Melayro Bogarde":"lask","John McGinn":"villa","Emiliano Buendía":"villa","Nicolas Jackson":"villa","Hugo Vetlesen":"brugge","Nicolò Tresoldi":"brugge","Ian Maatsen":"villa","João Gomes":"villa","Hans Vanaken":"brugge","Jan Virgili":"brugge","Romeo Vermant":"brugge","Santiago Mouriño":"villarreal","Serhou Guirassy":"dortmund","Waldemar Anton":"dortmund","Pau Navarro":"villarreal","Sergi Cardona":"villarreal","Erling Haaland":"mancity","Pablo Rosario":"porto","Joško Gvardiol":"mancity","Gianluigi Donnarumma":"mancity","Ayase Ueda":"lille","Alexsandro":"lille","Marc Bartra":"betis","Troy Parrott":"betis","Ethan Mbappé":"lille","Olivier Giroud":"lille","Natan":"betis","Fermín López Bernal":"betis","Marc Roca":"betis","Kylian Mbappé":"real","Federico Valverde":"real","Carlos Augusto":"inter","Dean Huijsen":"real","Hakan Çalhanoğlu":"inter","Lautaro Martínez":"inter","Yann Bisseck":"inter","Raphinha":"barca","Karim Adeyemi":"barca","Lamine Yamal":"barca","Gabriel Jesus":"barca","Sem Steijn":"feyenoord","Dani Olmo":"barca","Casper Vanhoutte":"feyenoord","Ermedin Demirović":"stuttgart","Zlatko Tripić":"viking","Kristoffer Askildsen":"viking","Peter Christiansen":"viking","Joe Bell":"viking","Marcos Llorente":"atleti","Dominik Szoboszlai":"liverpool","Alexis Mac Allister":"liverpool","Marc Pubill":"atleti","Ousmane Dembélé":"psg","Ferran Torres":"psg","Fabián Ruiz":"psg","Suleiman Camara":"slovan","César Blackman":"slovan","Geny Catamo":"sporting","Luis Suárez":"sporting","Rodrigo Zalazar":"sporting","Sergi Altimira":"sporting","Eren Elmalı":"gala","Deniz Gül":"gala","Ismail Jakobs":"gala","Martin Ødegaard":"arsenal","Billy Gilmour":"napoli","Lorenzo Lucca":"napoli","Archie Brown":"fener","Bryan Cristante":"roma","Kerem Aktürkoğlu":"fener","Mert Müldür":"fener","İsmail Yüksek":"fener","Devyne Rensch":"roma","Sergiño Dest":"psv","Gleiker Mendoza":"shakhtar","Armando Obispo":"psv","Ruben van Bommel":"psv","Vinícius Tobias":"shakhtar","Pedro Henrique":"shakhtar","Valeriy Bondar":"shakhtar","Dmytro Kryskiv":"shakhtar","Marlon Gomes":"shakhtar","Martin Baturina":"como","Anastasios Douvikas":"como","Assane Diao":"como","Máximo Perrone":"como","Andrija Maksimović":"leipzig","Nico Paz":"como","Willi Orbán":"leipzig","Christopher Nkunku":"leipzig","Ezechiel Banzuzi":"leipzig","Jamal Musiala":"bayern","Harry Kane":"bayern","Alphonso Davies":"bayern","Michael Olise":"bayern","Sondre Fet":"bodo","Odin Bjørtuft":"bodo","Matheus Cunha":"manutd","Bruno Fernandes":"manutd","Benjamin Šeško":"manutd","Lisandro Martínez":"manutd","Patrick Dorgu":"manutd","Ivan Lepinjica":"sabah","Danijel Šturm":"slavia","Abdallah Sima":"lens","Florian Thauvin":"lens","Ruben Aguilar":"lens","Mikuláš Konečný":"slavia","Ibrahima Ganiou":"lens"};
  const playerClub = new Map(Object.entries(playerClubRaw).map(([name,key])=>[normalize(name),key]));

  function findClubByAliasesV102e(clubKey){
    const aliases = clubAliases[clubKey] || [];
    if(!aliases.length) return null;
    const needles = new Set(aliases.map(normalize).filter(Boolean));
    const clubs = safe(window.state?.clubs);
    let exact = clubs.find(c => [c?.name,c?.short_name,c?.tla].some(v=>needles.has(normalize(v))));
    if(exact) return exact;
    // Fallback prudent pour les noms enrichis "FC", "FK", etc.
    const fuzzy = clubs.filter(c => [c?.name,c?.short_name].some(v=>{
      const n=normalize(v); if(!n) return false;
      return [...needles].some(a => a.length >= 5 && (n.includes(a) || a.includes(n)));
    }));
    return fuzzy.length===1 ? fuzzy[0] : null;
  }

  function validClubByIdV102e(id){
    if(id==null) return null;
    const club = safe(window.state?.clubs).find(c=>String(c?.id)===String(id));
    return club || null;
  }

  function resolveFromSiblingRowsV102e(row){
    const key = normalize(row?.player_name);
    if(!key) return null;
    const siblings = [...safe(window.state?.uclScorersV101), ...safe(window.state?.uclDisciplineV101)]
      .filter(x=>normalize(x?.player_name)===key);
    for(const x of siblings){
      const club=validClubByIdV102e(x?.club_id);
      if(club) return club;
    }
    return null;
  }

  function resolvePlayerClubV102e(row){
    let club = validClubByIdV102e(row?.club_id);
    if(club) return club;

    club = resolveFromSiblingRowsV102e(row);
    if(club) return club;

    const clubKey = playerClub.get(normalize(row?.player_name));
    if(clubKey) club = findClubByAliasesV102e(clubKey);
    return club || null;
  }
  window.uclResolvePlayerClubV102e = resolvePlayerClubV102e;

  function repairRowsV102e(){
    if(!window.state) return;
    for(const rows of [safe(state.uclScorersV101),safe(state.uclDisciplineV101)]){
      for(const row of rows){
        const club=resolvePlayerClubV102e(row);
        if(club && String(row?.club_id)!==String(club.id)) row.club_id=club.id;
      }
    }
  }
  window.repairUclPlayerClubsV102e = repairRowsV102e;

  const baseLoad = window.loadUclCenterData;
  if(typeof baseLoad==="function"){
    window.loadUclCenterData=async function(){
      const result=await baseLoad.apply(this,arguments);
      repairRowsV102e();
      return result;
    };
  }

  const baseRender = window.renderUclCenter;
  if(typeof baseRender==="function"){
    window.renderUclCenter=function(){
      repairRowsV102e();
      return baseRender.apply(this,arguments);
    };
  }

  window.renderRelease102e=function(){ repairRowsV102e(); };
})();
