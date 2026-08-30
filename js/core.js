"use strict";

// Le Nid des Champions V0.9.0 — noyau, état et utilitaires
  const CFG = window.NIDC_CONFIG || {};
  const configured = Boolean(
    CFG.SUPABASE_URL && CFG.SUPABASE_ANON_KEY &&
    !String(CFG.SUPABASE_URL).includes("YOUR_PROJECT") &&
    !String(CFG.SUPABASE_ANON_KEY).includes("YOUR_SUPABASE")
  );
  const demoMode = !configured && CFG.DEMO_WHEN_UNCONFIGURED !== false;
  let registrationInProgress = false;
  const sb = configured ? window.supabase.createClient(CFG.SUPABASE_URL, CFG.SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  }) : null;

  const $ = (s, p = document) => p.querySelector(s);
  const $$ = (s, p = document) => [...p.querySelectorAll(s)];
  const esc = (v = "") => String(v).replace(/[&<>'"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
  const fmtDate = iso => new Intl.DateTimeFormat("fr-FR", {weekday:"short",day:"2-digit",month:"2-digit",hour:"2-digit",minute:"2-digit",timeZone:"Europe/Paris"}).format(new Date(iso));
  const fmtShortDate = iso => new Intl.DateTimeFormat("fr-FR", {weekday:"short",day:"2-digit",month:"2-digit",timeZone:"Europe/Paris"}).format(new Date(iso));
  const fmtTime = iso => new Intl.DateTimeFormat("fr-FR", {hour:"2-digit",minute:"2-digit",timeZone:"Europe/Paris"}).format(new Date(iso));
  const fmtOdds = value => Number.isFinite(Number(value)) ? new Intl.NumberFormat("fr-FR",{minimumFractionDigits:2,maximumFractionDigits:2}).format(Number(value)) : "—";
  const localDateKey = iso => new Intl.DateTimeFormat("fr-CA", {year:"numeric",month:"2-digit",day:"2-digit",timeZone:"Europe/Paris"}).format(new Date(iso));
  const pct = (n,d) => d ? Math.round((Number(n||0) * 1000) / Number(d)) / 10 : 0;
  const editableStatus = status => ["scheduled", "postponed"].includes(status);
  const isLocked = m => !editableStatus(m.status) || new Date(m.kickoff_at).getTime() <= Date.now();
  const statusLabel = status => ({scheduled:"À venir",live:"LIVE",finished:"Terminé",postponed:"Reporté",cancelled:"Annulé"}[status] || status);
  const statusClass = status => ({live:"live",finished:"finished",postponed:"postponed",cancelled:"cancelled"}[status] || "");


  const state = {
    user: null,
    profile: null,
    season: null,
    availableSeasons: [],
    selectedSeasonSlug: null,
    seasonMemoryTab: "overview",
    seasonProfileStats: null,
    careerLeaderboard: [],
    playerCareer: null,
    hallOfFame: [],
    seasonReplay: [],
    generalPolls: [],
    titleHolder: null,
    seasonMemoryLoaded: false,
    seasonMemoryLoading: false,
    seasonMemoryError: null,
    matchdays: [],
    selectedMatchdayId: null,
    matches: [],
    allMatches: [],
    adminAllMatches: [],
    adminAllMatchdays: [],
    clubs: [],
    clubMemberships: [],
    clubPreviewFilter: "CL",
    phases: [],
    knockoutTies: [],
    selectedKnockoutPhase: "KNOCKOUT_PLAYOFF",
    tiePredictions: new Map(),
    championStatus: null,
    championCandidates: {1:[],2:[]},
    championBoards: {1:[],2:[]},
    predictions: new Map(),
    standings: [],
    rankingRows: [],
    rankingScope: "general",
    rankingScopeManuallyChosen: false,
    rankingAutoTestActive: false,
    collectiveStats: null,
    selectedEveningDate: null,
    teamDirectory: [],
    teamDirectoryMap: new Map(),
    myTeam: null,
    teamMembers: [],
    teamEvents: [],
    teamRequests: [],
    teamInvite: null,
    teamLeaderboardRows: [],
    teamRankingMode: "average",
    teamTab: "overview",
    teamMigrationError: null,
    profileDirectory: new Map(),
    avatarDraft: null,
    notificationPreferences: null,
    notifications: [],
    notificationFilter: "all",
    pushSubscriptions: [],
    pushDeliveryLogs: [],
    adminPushSubscriptions: [],
    currentRival: null,
    rivalDuels: [],
    rivalChanges: [],
    rivalSummary: null,
    owlMessages: [],
    supportTickets: [],
    adminSupportTickets: [],
    history: [],
    channel: null,
    realtimeTimer: null,
    livePollTimer: null,
    livePollBusy: false,
    liveFallbackEventsBound: false,
    museumSummary: null,
    gamificationEvents: [],
    gamificationRecords: [],
    gamificationSettings: null,
    narrativeTemplates: [],
    museumTab: "overview",
    museumFilter: "all",
    museumSearch: "",
    adminGamificationTab: "overview",
    adminBadges: [],
    adminPlayerBadges: [],
    adminNarrativeTemplates: [],
    gamificationAudit: [],
    gamificationLoadedOnce: false,
    uclMatches: [],
    uclStandings: [],
    uclTab: "overview",
    uclCalendarFilter: "all",
    uclClubSearch: "",
    uclSelectedClubId: null,
    uclCenterLoaded: false,
    uclCenterLoading: false,
    uclCenterError: null,
    eveningRankingRows: [],
    solitaryLeaderboard: [],
    solitaryEvents: [],
    monthlyPolls: [],
    eveningTab: "summary",
    eveningLoadedDate: null,
    eveningLoading: false,
    eveningError: null,
    demoUsers: JSON.parse(localStorage.getItem("nidc_demo_users") || "null") || [
      {id:"demo-parkaf", username:"Parkaf", role:"super_admin", status:"active", club_heart:"Stade Brestois", avatar_key:"avatar-hibou-humour-personnages-chanceux", avatar_source:"library", avatar_storage_path:null, avatar_moderation_status:"approved"},
      {id:"demo-ju", username:"Ju", role:"player", status:"active", club_heart:"PSG", avatar_key:"avatar-hibou-saphir", avatar_source:"library", avatar_storage_path:null, avatar_moderation_status:"approved"},
      {id:"demo-tourteau", username:"Tourteau", role:"player", status:"active", club_heart:"Real Madrid", avatar_key:"avatar-hibou-amethyste", avatar_source:"library", avatar_storage_path:null, avatar_moderation_status:"approved"}
    ]
  };

  const demoClubs = [
    ["c1","Paris SG","PSG",524,"France","Parc des Princes"],
    ["c2","Bayern Munich","BAY",5,"Allemagne","Allianz Arena"],
    ["c3","Real Madrid","RMA",86,"Espagne","Santiago Bernabéu"],
    ["c4","Arsenal","ARS",57,"Angleterre","Emirates Stadium"],
    ["c5","Inter Milan","INT",108,"Italie","San Siro"],
    ["c6","FC Barcelone","BAR",81,"Espagne","Camp Nou"],
    ["c7","Liverpool","LIV",64,"Angleterre","Anfield"],
    ["c8","Dortmund","BVB",4,"Allemagne","Signal Iduna Park"],
    ["c9","Olympique de Marseille","OM",516,"France","Orange Vélodrome"]
  ].map(([id,name,short_name,external_id,country,venue]) => ({
    id,name,short_name,tla:short_name,country,venue,external_provider:"football-data",external_id,
    logo_url:`https://crests.football-data.org/${external_id}.png`, logo_storage_path:null, is_active:true
  }));

  function demoInit() {
    state.season = {id:"season-demo", name:"Champions League 2026–27", slug:"ucl-2026-27", status:"preparation", points_wrong:0, points_result:3, points_difference:5, points_exact:7, champion_1_bonus:100, champion_2_bonus:50};
    state.availableSeasons=[state.season]; state.selectedSeasonSlug=state.season.slug;
    state.phases=[{id:"ph-league",code:"LEAGUE",name:"Phase de ligue",sort_order:10,default_multiplier:1},{id:"ph-po",code:"KNOCKOUT_PLAYOFF",name:"Barrages",sort_order:20,default_multiplier:1},{id:"ph-r16",code:"ROUND_OF_16",name:"Huitièmes de finale",sort_order:30,default_multiplier:1},{id:"ph-qf",code:"QUARTER_FINAL",name:"Quarts de finale",sort_order:40,default_multiplier:1},{id:"ph-sf",code:"SEMI_FINAL",name:"Demi-finales",sort_order:50,default_multiplier:1},{id:"ph-f",code:"FINAL",name:"Finale",sort_order:60,default_multiplier:1}];
    state.knockoutTies=JSON.parse(localStorage.getItem("nidc_demo_knockout_ties")||"[]");
    state.tiePredictions=new Map(Object.values(JSON.parse(localStorage.getItem("nidc_demo_tie_predictions")||"{}")).filter(x=>x.user_id===state.user?.id).map(x=>[x.tie_id,x]));
    state.clubs = demoClubs;
    const base = Date.now() + 4 * 24 * 3600_000;
    state.matchdays = [
      {id:"md1", season_id:"season-demo", number:1, name:"Journée 1", starts_at:new Date(base).toISOString(), ends_at:new Date(base + 27 * 3600_000).toISOString()},
      {id:"md2", season_id:"season-demo", number:2, name:"Journée 2", starts_at:new Date(base + 14 * 24 * 3600_000).toISOString(), ends_at:new Date(base + 15 * 24 * 3600_000).toISOString()}
    ];
    if (!state.selectedMatchdayId || !state.matchdays.some(md => md.id === state.selectedMatchdayId)) state.selectedMatchdayId = "md1";
    const savedResults = JSON.parse(localStorage.getItem("nidc_demo_results") || "{}");
    const fixtures = [
      ["m1","md1",0,"c1","c2"],["m2","md1",20,"c3","c4"],["m3","md1",24*60,"c5","c6"],["m4","md1",24*60+20,"c7","c8"],
      ["m5","md2",14*24*60,"c2","c3"],["m6","md2",14*24*60+20,"c4","c1"],["m7","md2",15*24*60,"c6","c7"],["m8","md2",15*24*60+20,"c8","c5"]
    ];
    state.allMatches = fixtures.map(([id,matchday_id,minutes,homeId,awayId]) => {
      const r = savedResults[id] || {};
      const demoOdds = {
        m1:[1.92,3.55,3.80], m2:[1.76,3.85,4.45], m3:[2.18,3.45,3.15], m4:[1.64,4.10,5.10],
        m5:[1.88,3.70,3.95], m6:[2.05,3.55,3.45], m7:[2.30,3.60,2.85], m8:[3.25,3.65,2.08]
      }[id] || [null,null,null];
      return {
        id, season_id:"season-demo", matchday_id, kickoff_at:new Date(base + minutes*60_000).toISOString(),
        status:r.status || "scheduled", data_source:"manual", home_score:r.home_score ?? null, away_score:r.away_score ?? null,
        stadium:r.stadium || demoClubs.find(c=>c.id===homeId)?.venue || null,
        odds_home:demoOdds[0], odds_draw:demoOdds[1], odds_away:demoOdds[2],
        odds_provider:"demo", odds_bookmaker:"Cotes démo", odds_source_season:"2026/27", odds_is_test_shifted:false, odds_updated_at:new Date().toISOString(),
        home_club:demoClubs.find(c=>c.id===homeId), away_club:demoClubs.find(c=>c.id===awayId)
      };
    });
    state.matches = state.allMatches.filter(m => m.matchday_id === state.selectedMatchdayId);
  }

  function isAdminProfile(){return ["admin","super_admin"].includes(state.profile?.role)&&state.profile?.status==="active";}

  function toast(text, kind = "ok") {
    const el = document.createElement("div");
    el.className = `toast ${kind}`;
    el.textContent = text;
    $("#toastStack").appendChild(el);
    setTimeout(() => el.remove(), 3400);
  }

  function setMsg(id, text, kind = "") {
    const el = $(id);
    if (!el) return;
    el.textContent = text;
    el.className = `form-msg ${kind}`;
  }

  function showAuth() { $("#authScreen").classList.remove("hidden"); $("#appScreen").classList.add("hidden"); }
  function showApp() { $("#authScreen").classList.add("hidden"); $("#appScreen").classList.remove("hidden"); }

  function setView(name) {
    // V0.4.1 : le choix champion vit désormais dans Profil.
    if(name === "champions") name = "profile";
    // V0.9.11 : une fonction verrouillée par le Super Admin disparaît aussi des accès directs.
    if(typeof window.featureViewAllowedV0911==="function" && !window.featureViewAllowedV0911(name)){
      toast("🔒 Cette fonction n’est pas encore ouverte aux joueurs.");
      name="home";
    }
    const titles={home:"Accueil",matches:"Pronostics",knockout:"Phases finales",ranking:"Classements",season:"Saison",ucl:"Ligue des champions",evenings:"Soirées européennes",teams:"Teams",museum:"Musée",profile:"Profil & champions",rival:"Rivalités",admin:"Administration"};
    $$(".view").forEach(v => v.classList.toggle("hidden", v.id !== `view-${name}`));
    $$('[data-view]').forEach(b => b.classList.toggle("active", b.dataset.view === name));
    const title=$("#pageTitle");
    if(title) title.textContent=titles[name]||"Le Nid des Champions";
    if(name==="museum"&&typeof renderMuseum==="function")renderMuseum();
    if((name==="season"||name==="profile")&&typeof loadSeasonMemoryData==="function"&&!state.seasonMemoryLoaded&&!state.seasonMemoryLoading){loadSeasonMemoryData().then(()=>{if(name==="season")renderSeasonMemory?.();else renderProfileCareerV090?.();}).catch(err=>toast(friendlyError(err),"error"));}
    if(name==="ucl"&&typeof loadUclCenterData==="function"){loadUclCenterData().then(()=>renderUclCenter?.()).catch(err=>toast(friendlyError(err),"error"));}
    if(name==="evenings"&&typeof loadEveningHubData==="function"){loadEveningHubData().then(()=>renderEveningHub?.()).catch(err=>toast(friendlyError(err),"error"));}
    window.scrollTo({top:0, behavior:"smooth"});
  }

  function modal(title, html) {
    let root = $("#modalRoot");
    if (!root) {
      root = document.createElement("div");
      root.id = "modalRoot";
      document.body.appendChild(root);
      console.warn("[LNDC] modalRoot absent : conteneur recréé automatiquement.");
    }
    root.innerHTML = `<div id="modalOverlay" class="modal-overlay"><div class="card card-pad modal-card"><div class="modal-head"><h3>${esc(title)}</h3><button id="modalClose" class="btn secondary small">Fermer</button></div><div class="modal-body">${html}</div></div></div>`;
    const close = $("#modalClose", root);
    if (close) close.onclick = () => root.innerHTML = "";
    return root;
  }

  function publicLogoUrl(club) {
    if (!club) return null;
    if (club.logo_storage_path && configured) {
      return `${String(CFG.SUPABASE_URL).replace(/\/$/,"")}/storage/v1/object/public/club-logos/${club.logo_storage_path}`;
    }
    return club.logo_source_url || club.logo_url || null;
  }

  function crestHTML(club, large = false) {
    const url = publicLogoUrl(club);
    const short = esc((club?.short_name || club?.tla || "?").slice(0,3));
    return `<span class="crest ${large ? "large" : ""}">${url ? `<img src="${esc(url)}" alt="" loading="lazy" onerror="this.remove();this.parentElement.classList.add('crest-fallback')">` : ""}<b>${short}</b></span>`;
  }

  // V0.6.6 — drapeaux via FlagCDN : rendu identique sur Windows, Android et iOS.
  // Le second champ est le code attendu par FlagCDN (ISO 3166-1, ou subdivision GB).
  const COUNTRY_DISPLAY = {
    France:["France","fr"],
    Germany:["Allemagne","de"], Allemagne:["Allemagne","de"],
    Spain:["Espagne","es"], Espagne:["Espagne","es"],
    England:["Angleterre","gb-eng"], Angleterre:["Angleterre","gb-eng"],
    Italy:["Italie","it"], Italie:["Italie","it"],
    Portugal:["Portugal","pt"],
    Netherlands:["Pays-Bas","nl"], "Pays-Bas":["Pays-Bas","nl"],
    Belgium:["Belgique","be"], Belgique:["Belgique","be"],
    Denmark:["Danemark","dk"], Danemark:["Danemark","dk"],
    Norway:["Norvège","no"], Norvège:["Norvège","no"],
    Greece:["Grèce","gr"], Grèce:["Grèce","gr"],
    Turkey:["Turquie","tr"], Türkiye:["Turquie","tr"], Turquie:["Turquie","tr"],
    Czechia:["Tchéquie","cz"], "Czech Republic":["Tchéquie","cz"], Tchéquie:["Tchéquie","cz"],
    Austria:["Autriche","at"], Autriche:["Autriche","at"],
    Switzerland:["Suisse","ch"], Suisse:["Suisse","ch"],
    Scotland:["Écosse","gb-sct"], Écosse:["Écosse","gb-sct"],
    Wales:["Pays de Galles","gb-wls"], "Pays de Galles":["Pays de Galles","gb-wls"],
    "Northern Ireland":["Irlande du Nord","gb-nir"], "Irlande du Nord":["Irlande du Nord","gb-nir"],
    "United Kingdom":["Royaume-Uni","gb"], "Royaume-Uni":["Royaume-Uni","gb"],
    Cyprus:["Chypre","cy"], Chypre:["Chypre","cy"],
    Azerbaijan:["Azerbaïdjan","az"], Azerbaïdjan:["Azerbaïdjan","az"],
    Kazakhstan:["Kazakhstan","kz"]
  };

  function clubCountry(club) {
    if (!club) return {name:"",code:""};
    // Monaco évolue dans le système français : pour le Nid, son pays sportif affiché est la France.
    const identity = `${club.name||""} ${club.short_name||""} ${club.tla||""}`.toLocaleLowerCase("fr");
    if (identity.includes("monaco")) return {name:"France",code:"fr"};
    const raw = String(club.country || "").trim();
    if (!raw) return {name:"",code:""};
    const mapped = COUNTRY_DISPLAY[raw];
    return mapped ? {name:mapped[0],code:mapped[1]} : {name:raw,code:""};
  }

  function flagCdnUrl(code) {
    const safe = String(code || "").toLowerCase().replace(/[^a-z0-9-]/g, "");
    return safe ? `https://flagcdn.com/${safe}.svg` : "";
  }

  function clubCountryHTML(club) {
    const country = clubCountry(club);
    if (!country.name) return "";
    const url = flagCdnUrl(country.code);
    const fallback = country.code ? String(country.code).replace(/^gb-/, "").slice(0,3).toUpperCase() : "";
    const flag = url ? `<span class="country-flag-wrap" aria-hidden="true"><img class="country-flag" src="${esc(url)}" alt="" loading="lazy" decoding="async" referrerpolicy="no-referrer" onerror="this.hidden=true;this.nextElementSibling.hidden=false"><span class="country-flag-fallback" hidden>${esc(fallback)}</span></span>` : "";
    return `<small class="club-country">${flag}<span>${esc(country.name)}</span></small>`;
  }

  function debounce(fn,ms){let t;return(...args)=>{clearTimeout(t);t=setTimeout(()=>fn(...args),ms);};}
  function friendlyError(err){const msg=err?.message||String(err||"Erreur inconnue");if(/Invalid login|invalid credentials/i.test(msg))return"Pseudo ou mot de passe incorrect.";if(/Failed to send a request to the Edge Function|FunctionsFetchError/i.test(msg))return"Une Edge Function du Nid ne répond pas. Vérifie son déploiement.";if(/duplicate|unique/i.test(msg))return"Cette valeur existe déjà.";if(/Pronostic verrouillé/i.test(msg))return"Ce pronostic est désormais verrouillé.";return msg;}
