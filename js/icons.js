"use strict";
// Le Nid des Champions — bibliothèque d'icônes UI 0.10 (raccordement graphique)
const NIDC_ICON_BASE="assets/icons/runtime/";
const NIDC_ICON_NAMES=new Set(["add", "admin", "arrow-down", "arrow-left", "arrow-right", "arrow-up", "award", "badge-crown", "badge-star", "bronze-medal", "calendar", "close", "cloud-sync", "crown", "cup", "delete", "download", "edit", "eliminated", "error", "external-link", "filter", "final-score", "football", "genius", "gold-medal", "group-stage", "hall-of-fame", "help", "hide", "home", "hot-match", "hourglass", "info", "knockout", "legend", "live", "lock", "master-predictor", "match-timer", "medal", "menu", "more", "museum", "news", "next", "next-match", "notification", "notification-off", "offline", "online", "owl", "pan", "perfect-score", "podium", "poll", "predictions", "predictions-list", "previous", "profile", "qualified", "ranking", "red-card", "refresh", "remove", "results", "rivalry", "scoreboard", "search", "season", "settings", "share", "shield", "show", "silver-medal", "sort", "stadium", "stats", "success", "sync", "tactics", "teams", "timer", "top-streak", "tournament", "trophy", "ui-help", "ui-search", "ui-success", "unlock", "upload", "venue-map", "vote", "warning", "whistle", "yellow-card"]);
function iconPath(name){return `${NIDC_ICON_BASE}${NIDC_ICON_NAMES.has(name)?name:"owl"}.png`;}
function iconHTML(name,className="nid-icon nid-icon-inline",alt=""){
  const safe=NIDC_ICON_NAMES.has(name)?name:"owl";
  return `<img class="${className}" src="${NIDC_ICON_BASE}${safe}.png" alt="${esc(alt)}" aria-hidden="${alt?"false":"true"}">`;
}
function iconNode(name,className="nid-icon nid-icon-inline",alt=""){
  const img=document.createElement("img");img.className=className;img.src=iconPath(name);img.alt=alt||"";if(!alt)img.setAttribute("aria-hidden","true");return img;
}

const NIDC_GLYPH_ICONS=new Map([
  ["⌂","home"],["⚽","football"],["⚔","rivalry"],["🏆","trophy"],["⭐","badge-star"],["🌙","live"],["☾","live"],
  ["🛡","teams"],["🏛","museum"],["♙","profile"],["♟","profile"],["⚙","settings"],["🔧","settings"],["🛠","admin"],
  ["🔔","notification"],["🔒","lock"],["🔓","unlock"],["⚠","warning"],["🚨","warning"],["❌","error"],["🚫","error"],["✅","ui-success"],["✓","ui-success"],
  ["🗳","poll"],["🏅","medal"],["🥇","gold-medal"],["🥈","silver-medal"],["🥉","bronze-medal"],["👑","crown"],["♛","crown"],
  ["🔥","hot-match"],["⚡","hot-match"],["🎯","perfect-score"],["✨","genius"],["💡","genius"],["🧠","genius"],["🍳","pan"],
  ["📊","stats"],["📈","stats"],["🔍","search"],["⌕","search"],["👁","show"],["🗑","delete"],["✍","edit"],["📥","download"],["📤","upload"],
  ["🔄","sync"],["↻","refresh"],["📡","online"],["⏳","hourglass"],["⏰","timer"],["🗓","calendar"],["📅","calendar"],["🧭","venue-map"],["🌍","group-stage"],["🌐","group-stage"],
  ["🚪","external-link"],["📦","download"],["🎫","help"],["📜","predictions-list"],["📘","predictions-list"],["🚩","venue-map"],["🔑","unlock"],
  ["🏁","final-score"],["🕵","owl"],["🦉","owl"],["🪹","home"],["🪶","owl"],["🎭","profile"],["📱","notification"],
  ["★","badge-star"],["✦","badge-star"],["✧","badge-star"],["✹","badge-star"]
]);
const NIDC_ICONIFY_SELECTOR="button,h1,h2,h3,h4,h5,h6,.eyebrow,.chip,.status-chip,.nav-icon,.admin-dash-icon,.admin-search-v095>span,.champion-profile-note>span,.record-card>span,.badge-emblem,.empty";
const NIDC_KEEP_EMOJI="[data-keep-emoji],.player-reaction-grid,.player-reaction-trigger,[data-send-reaction]";
const NIDC_GLYPH_RE=new RegExp("("+[...NIDC_GLYPH_ICONS.keys()].sort((a,b)=>b.length-a.length).map(x=>x.replace(/[.*+?^${}()|[\\]\\]/g,"\\$&")).join("|")+")(?:\\uFE0F)?","gu");
function iconifyTextNode(node){
  if(!node?.nodeValue||!node.parentElement||node.parentElement.closest(NIDC_KEEP_EMOJI))return;
  const text=node.nodeValue;NIDC_GLYPH_RE.lastIndex=0;if(!NIDC_GLYPH_RE.test(text))return;NIDC_GLYPH_RE.lastIndex=0;
  const frag=document.createDocumentFragment();let last=0,match;
  while((match=NIDC_GLYPH_RE.exec(text))){
    if(match.index>last)frag.append(document.createTextNode(text.slice(last,match.index)));
    frag.append(iconNode(NIDC_GLYPH_ICONS.get(match[1]),"nid-icon nid-icon-inline"));last=match.index+match[0].length;
  }
  if(last<text.length)frag.append(document.createTextNode(text.slice(last)));node.replaceWith(frag);
}
function iconifyUI(root=document){
  const targets=[];
  if(root.nodeType===1&&root.matches?.(NIDC_ICONIFY_SELECTOR))targets.push(root);
  if(root.querySelectorAll)targets.push(...root.querySelectorAll(NIDC_ICONIFY_SELECTOR));
  for(const el of targets){
    if(el.closest(NIDC_KEEP_EMOJI))continue;
    const walker=document.createTreeWalker(el,NodeFilter.SHOW_TEXT,{acceptNode:n=>n.parentElement?.closest(NIDC_KEEP_EMOJI)?NodeFilter.FILTER_REJECT:NodeFilter.FILTER_ACCEPT});
    const nodes=[];while(walker.nextNode())nodes.push(walker.currentNode);nodes.forEach(iconifyTextNode);
  }
}
function startIconObserver(){
  iconifyUI(document);
  const observer=new MutationObserver(records=>{for(const r of records){if(r.type==="characterData")iconifyTextNode(r.target);for(const n of r.addedNodes){if(n.nodeType===1)iconifyUI(n);else if(n.nodeType===3&&n.parentElement?.closest(NIDC_ICONIFY_SELECTOR))iconifyTextNode(n);}}});
  observer.observe(document.body,{subtree:true,childList:true,characterData:true});
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",startIconObserver,{once:true});else startIconObserver();
