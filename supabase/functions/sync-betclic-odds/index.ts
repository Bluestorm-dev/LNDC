// V0.9.11 — adaptation TypeScript expérimentale du protocole documenté par TapsHTS/betclic-api.
// Projet source : https://github.com/TapsHTS/betclic-api — licence MIT © TapsHTS.
// Voir docs/THIRD_PARTY_BETCLIC_API_NOTICE.md. Aucun code de pari automatisé.
import { createClient } from "npm:@supabase/supabase-js@^2";
import { corsHeaders } from "npm:@supabase/supabase-js@^2/cors";

// Le Nid des Champions V0.9.11
// Source expérimentale non officielle : Betclic gRPC-web / offering.begmedia.com.
// Port TypeScript minimal inspiré du projet MIT TapsHTS/betclic-api.
// Aucun pari automatisé : lecture de cotes publiques 1N2 uniquement.

type ProtoValue = number | Uint8Array;
type ProtoFields = Map<number, ProtoValue[]>;
type BTeam = { name: string; short?: string | null };
type BMatch = {
  id: number | null;
  name: string;
  date: string;
  competition: string;
  isLive: boolean;
  teams: BTeam[];
};
type BSelection = { name: string; odds: number };
type BMarket = { name: string; suspended: boolean; selections: BSelection[] };
type ClubRef = { name?: string | null; short_name?: string | null; tla?: string | null };
type NidMatch = {
  id: string;
  kickoff_at: string;
  status: string;
  odds_provider?: string | null;
  odds_updated_at?: string | null;
  home_club: ClubRef | null;
  away_club: ClubRef | null;
};

const BASE_URL = "https://offering.begmedia.com/web/offering.access.api";
const RESULT_MARKET = "ca_ftb_rslt";
const PAGE_SIZE = 40;
const MAX_PAGES = 10;
const json = (body: unknown, status = 200) => Response.json(body, { status, headers: corsHeaders });
const decoder = new TextDecoder();

const BETCLIC_HEADERS: Record<string,string> = {
  "Content-Type": "application/grpc-web+proto",
  "Accept": "*/*",
  "x-grpc-web": "1",
  "x-bg-ref-platform": "DESKTOP",
  "x-bg-regulation": "FR",
  "x-bg-ref-brand": "BETCLIC",
  "x-bg-ref-regulator-zone": "FR",
  "Origin": "https://www.betclic.fr",
  "Referer": "https://www.betclic.fr/",
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125 Safari/537.36",
  "Accept-Language": "fr-FR,fr;q=0.9",
};

function concat(parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((n,p)=>n+p.length,0);
  const out = new Uint8Array(total);
  let offset=0;
  for(const p of parts){out.set(p,offset);offset+=p.length;}
  return out;
}

function encodeVarint(value: number): Uint8Array {
  let v = Math.max(0, Math.floor(value));
  const bytes:number[]=[];
  while(v > 0x7f){bytes.push((v % 128) + 128);v=Math.floor(v/128);}
  bytes.push(v);
  return new Uint8Array(bytes);
}
function encodeFieldVarint(field:number,value:number):Uint8Array{
  return concat([encodeVarint(field*8),encodeVarint(value)]);
}
function encodeFieldString(field:number,value:string):Uint8Array{
  const b=new TextEncoder().encode(value);
  return concat([encodeVarint(field*8+2),encodeVarint(b.length),b]);
}
function grpcFrame(payload:Uint8Array):Uint8Array{
  const out=new Uint8Array(5+payload.length);
  out[0]=0;
  new DataView(out.buffer).setUint32(1,payload.length,false);
  out.set(payload,5);
  return out;
}

function decodeVarint(data:Uint8Array,start:number):[number,number]{
  let result=0,mult=1,pos=start;
  while(pos<data.length){
    const b=data[pos++];
    result += (b & 0x7f) * mult;
    if(!(b&0x80)) break;
    mult*=128;
    if(mult>Number.MAX_SAFE_INTEGER) break;
  }
  return [result,pos];
}
function decodeProto(data:Uint8Array):ProtoFields{
  const fields:ProtoFields=new Map();
  let pos=0;
  while(pos<data.length){
    const [tag,next]=decodeVarint(data,pos);pos=next;
    if(!tag) break;
    const field=Math.floor(tag/8), wire=tag&7;
    let value:ProtoValue;
    if(wire===0){[value,pos]=decodeVarint(data,pos);}
    else if(wire===1){
      if(pos+8>data.length) break;
      value=data.slice(pos,pos+8);pos+=8;
    }else if(wire===2){
      const [len,p2]=decodeVarint(data,pos);pos=p2;
      if(pos+len>data.length) break;
      value=data.slice(pos,pos+len);pos+=len;
    }else if(wire===5){
      if(pos+4>data.length) break;
      value=data.slice(pos,pos+4);pos+=4;
    }else break;
    const arr=fields.get(field)||[];arr.push(value);fields.set(field,arr);
  }
  return fields;
}
function bytes(v:ProtoValue|undefined):Uint8Array|null{return v instanceof Uint8Array?v:null;}
function str(v:ProtoValue|undefined):string|null{
  if(!(v instanceof Uint8Array))return null;
  try{
    const s=decoder.decode(v);
    if(!s)return null;
    for(const c of s){const n=c.charCodeAt(0);if(n<32 && c!=="\n"&&c!=="\r"&&c!=="\t")return null;}
    return s;
  }catch{return null;}
}
function fixed64Double(v:ProtoValue|undefined):number|null{
  if(!(v instanceof Uint8Array)||v.length!==8)return null;
  const n=new DataView(v.buffer,v.byteOffset,v.byteLength).getFloat64(0,true);
  return Number.isFinite(n)?n:null;
}
function parseFrames(raw:Uint8Array):Array<{flags:number,data:Uint8Array}>{
  const out:Array<{flags:number,data:Uint8Array}>=[];
  let pos=0;
  while(pos+5<=raw.length){
    const flags=raw[pos],len=new DataView(raw.buffer,raw.byteOffset+pos+1,4).getUint32(0,false);
    pos+=5;if(pos+len>raw.length)break;
    out.push({flags,data:raw.slice(pos,pos+len)});pos+=len;
  }
  return out;
}
function hasTrailer(raw:Uint8Array):boolean{return parseFrames(raw).some(f=>(f.flags&0x80)!==0);}

async function grpcPost(service:string,method:string,payload:Uint8Array):Promise<Array<{flags:number,data:Uint8Array}>>{
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),9000);
  let response:Response;
  try{
    response=await fetch(`${BASE_URL}/${service}/${method}`,{
      method:"POST",headers:BETCLIC_HEADERS,body:grpcFrame(payload),signal:controller.signal
    });
    if(!response.ok)throw new Error(`Betclic HTTP ${response.status}: ${(await response.text()).slice(0,180)}`);
    if(!response.body)throw new Error("Betclic : réponse vide.");
    const reader=response.body.getReader(),chunks:Uint8Array[]=[];
    let total=0;
    try{
      while(total<350000){
        const {done,value}=await reader.read();if(done)break;
        if(value){chunks.push(value);total+=value.length;}
        const raw=concat(chunks);
        if(raw.length>5 && hasTrailer(raw))break;
      }
    }catch(err){
      if(!(err instanceof DOMException && err.name==="AbortError"))console.warn("Flux Betclic interrompu",err);
    }finally{try{await reader.cancel();}catch{}}
    const raw=concat(chunks);
    if(!raw.length)throw new Error("Betclic : aucune donnée reçue.");
    return parseFrames(raw);
  }finally{clearTimeout(timer);}
}

function parseMatch(data:Uint8Array):BMatch{
  const f=decodeProto(data);
  const match:BMatch={id:null,name:"",date:"",competition:"",isLive:false,teams:[]};
  const id=f.get(1)?.[0];if(typeof id==="number")match.id=id;
  for(const v of f.get(2)||[]){const s=str(v);if(s&&s.includes(" - ")){match.name=s;break;}if(s&&!match.name)match.name=s;}
  for(const v of f.get(3)||[]){const s=str(v);if(s&&(s.includes("T")||s.includes("-"))){match.date=s;break;}}
  const live=f.get(6)?.[0];if(typeof live==="number")match.isLive=live===1;
  const comp=bytes(f.get(8)?.[0]);if(comp){const cf=decodeProto(comp);const n=str(cf.get(2)?.[0]);if(n)match.competition=n;}
  for(const v of f.get(12)||[]){
    const td=bytes(v);if(!td)continue;
    const tf=decodeProto(td),name=str(tf.get(3)?.[0]),short=str(tf.get(4)?.[0]);
    if(name)match.teams.push({name,short});
  }
  if(!match.name&&match.teams.length>=2)match.name=`${match.teams[0].name} - ${match.teams[1].name}`;
  return match;
}
function parseMatches(frames:Array<{flags:number,data:Uint8Array}>):{matches:BMatch[],total:number}{
  const matches:BMatch[]=[];let total=0;
  for(const frame of frames){
    if(frame.flags&0x80)continue;
    const root=decodeProto(frame.data);
    const t=root.get(5)?.[0];if(typeof t==="number")total=t;
    for(const w of root.get(1)||[]){
      const wb=bytes(w);if(!wb)continue;
      const wf=decodeProto(wb);
      for(const md of wf.get(3)||[]){const mb=bytes(md);if(!mb)continue;const m=parseMatch(mb);if(m.id&& (m.name||m.teams.length))matches.push(m);}
    }
  }
  return {matches,total};
}
function parseSearch(frames:Array<{flags:number,data:Uint8Array}>):BMatch[]{
  const found=new Map<number,BMatch>();
  const add=(raw:Uint8Array)=>{
    const m=parseMatch(raw);
    if(m.id&&(m.name||m.teams.length))found.set(m.id,m);
  };
  for(const frame of frames){
    if(frame.flags&0x80)continue;
    const root=decodeProto(frame.data);
    for(const values of root.values()){
      for(const entry of values){
        const eb=bytes(entry);if(!eb)continue;
        const direct=parseMatch(eb);
        if(direct.id&&(direct.name||direct.teams.length)){found.set(direct.id,direct);continue;}
        const sub=decodeProto(eb);
        for(const subValues of sub.values()){
          for(const subEntry of subValues){
            const sb=bytes(subEntry);if(sb)add(sb);
          }
        }
      }
    }
  }
  return [...found.values()];
}
function parseSelection(data:Uint8Array):BSelection|null{
  const f=decodeProto(data);let name:string|null=null;
  for(const field of [10,11,2,3]){const s=str(f.get(field)?.[0]);if(s){name=s;break;}}
  if(!name)return null;
  const n=fixed64Double(f.get(12)?.[0]);
  if(n==null||n<=1||n>=10000)return null;
  return {name,odds:Math.round(n*100)/100};
}
function extractSelections(data:Uint8Array,depth=0):BSelection[]{
  if(depth>4)return [];
  const f=decodeProto(data),out:BSelection[]=[];
  for(const v of f.get(16)||[]){const b=bytes(v);if(b){const s=parseSelection(b);if(s)out.push(s);}}
  if(!out.length){
    for(const g of f.get(10)||[]){
      const gb=bytes(g);if(!gb)continue;const gf=decodeProto(gb);
      for(const item of gf.get(1)||[]){
        const ib=bytes(item);if(!ib)continue;const inf=decodeProto(ib),subs=inf.get(1)||[];
        if(subs.length){for(const sub of subs){const sb=bytes(sub);if(sb){const s=parseSelection(sb);if(s)out.push(s);}}}
        else {const s=parseSelection(ib);if(s)out.push(s);}
      }
    }
  }
  if(!out.length){for(const sm of f.get(13)||[]){const b=bytes(sm);if(b)out.push(...extractSelections(b,depth+1));}}
  return out;
}
function extractMarkets(matchData:Uint8Array):BMarket[]{
  const f=decodeProto(matchData),markets:BMarket[]=[];
  for(const wrapper of f.get(11)||[]){
    const wb=bytes(wrapper);if(!wb)continue;const wf=decodeProto(wb);
    for(const mv of [...(wf.get(3)||[]),...(wf.get(1)||[])]){
      const mb=bytes(mv);if(!mb)continue;const mf=decodeProto(mb);
      let name:string|null=null;for(const field of [2,3]){const s=str(mf.get(field)?.[0]);if(s&&s.length>2){name=s;break;}}
      if(!name)continue;
      const suspended=mf.get(9)?.[0]===3,selections=extractSelections(mb);
      if(selections.length)markets.push({name,suspended,selections});
    }
  }
  return markets;
}
function parseDetail(frames:Array<{flags:number,data:Uint8Array}>):{match:BMatch,markets:BMarket[]}{
  let match:BMatch={id:null,name:"",date:"",competition:"",isLive:false,teams:[]},markets:BMarket[]=[];
  for(const frame of frames){
    if(frame.flags&0x80)continue;const root=decodeProto(frame.data);
    for(const w of root.get(1)||[]){
      const wb=bytes(w);if(!wb)continue;const wf=decodeProto(wb);
      for(const md of wf.get(1)||[]){const mb=bytes(md);if(!mb)continue;match=parseMatch(mb);markets=extractMarkets(mb);return {match,markets};}
    }
  }
  return {match,markets};
}
async function getBetclicMatches(offset:number):Promise<{matches:BMatch[],total:number}>{
  let payload=encodeFieldString(1,"football");
  payload=concat([payload,encodeFieldString(2,"fr"),encodeFieldVarint(4,offset),encodeFieldVarint(5,PAGE_SIZE)]);
  return parseMatches(await grpcPost("offering.access.api.MatchService","GetMatchesBySportWithNotifications",payload));
}
async function getBetclicResult(matchId:number):Promise<{match:BMatch,markets:BMarket[]}>{
  let payload=encodeFieldVarint(1,matchId);
  payload=concat([payload,encodeFieldString(2,"fr"),encodeFieldString(3,RESULT_MARKET)]);
  return parseDetail(await grpcPost("offering.access.api.MatchService","GetMatchWithNotification",payload));
}
async function searchBetclic(query:string):Promise<BMatch[]>{
  let payload=encodeFieldString(1,query);
  payload=concat([payload,encodeFieldString(2,"fr")]);
  return parseSearch(await grpcPost("offering.access.api.SearchService","SearchMatchesWithNotifications",payload));
}

const NAME_ALIASES:Record<string,string[]>={
  "paris saint germain":["psg","paris sg"],
  "internazionale":["inter","inter milan"],
  "bayern munchen":["bayern munich","bayern"],
  "aek athens":["aek athenes","pae aek","aek"],
  "pae aek":["aek athens","aek athenes","aek"],
  "sporting cp":["sporting lisbonne","sporting"],
  "olympiacos":["olympiakos","olympiacos piree"],
  "atletico madrid":["atletico de madrid"],
};
function normalizeName(input:unknown):string{
  return String(input||"").normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase()
    .replace(/\b(fc|cf|afc|ac|ssc|club|football|futbol|calcio|pae|sk|fk|kv|vfb|rc)\b/g," ")
    .replace(/[^a-z0-9]+/g," ").trim().replace(/\s+/g," ");
}
function expandName(input:unknown):Set<string>{
  const n=normalizeName(input),out=new Set<string>();if(!n)return out;out.add(n);
  for(const [key,aliases] of Object.entries(NAME_ALIASES)){
    const all=[key,...aliases].map(normalizeName);
    if(all.includes(n))all.forEach(x=>out.add(x));
  }
  return out;
}
function namesMatch(a:unknown,b:unknown):boolean{
  const aa=expandName(a),bb=expandName(b);if(!aa.size||!bb.size)return false;
  for(const x of aa)for(const y of bb){
    if(x===y)return true;
    if(x.length>=5&&y.length>=5&&(x.includes(y)||y.includes(x)))return true;
    const tx=new Set(x.split(" ").filter(t=>t.length>2)),ty=new Set(y.split(" ").filter(t=>t.length>2));
    const common=[...tx].filter(t=>ty.has(t)).length;
    if(common>=Math.min(2,Math.min(tx.size,ty.size)))return true;
  }
  return false;
}
function localTeamNames(c:ClubRef|null):string[]{return [c?.name,c?.short_name,c?.tla].filter(Boolean).map(String);}
function eventTeamNames(t:BTeam|undefined):string[]{return t?[t.name,t.short||""].filter(Boolean):[];}
function teamMatches(local:ClubRef|null,event:BTeam|undefined):boolean{
  return localTeamNames(local).some(a=>eventTeamNames(event).some(b=>namesMatch(a,b)));
}
function eventMatchesLocal(local:NidMatch,event:BMatch):boolean{
  if(event.teams.length<2)return false;
  if(!teamMatches(local.home_club,event.teams[0])||!teamMatches(local.away_club,event.teams[1]))return false;
  const a=new Date(local.kickoff_at).getTime(),b=new Date(event.date).getTime();
  return Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<=36*3600_000;
}
function eventRange(events:BMatch[]):{from:string|null,to:string|null}{
  const times=events.map(e=>new Date(e.date).getTime()).filter(Number.isFinite).sort((a,b)=>a-b);
  return {from:times.length?new Date(times[0]).toISOString():null,to:times.length?new Date(times[times.length-1]).toISOString():null};
}
function preferredClubSearch(club:ClubRef|null):string{
  return String(club?.short_name||club?.name||club?.tla||"").trim();
}
function isAlreadyPaired(localId:string,pairs:Array<{local:NidMatch,event:BMatch}>):boolean{
  return pairs.some(p=>p.local.id===localId);
}
function pairFromPool(
  candidates:NidMatch[],
  pool:BMatch[],
  pairs:Array<{local:NidMatch,event:BMatch}>,
  used:Set<number>,
  limit:number
){
  for(const local of candidates){
    if(pairs.length>=limit)break;
    if(isAlreadyPaired(local.id,pairs))continue;
    const event=pool.find(e=>e.id&&!used.has(e.id)&&eventMatchesLocal(local,e));
    if(event&&event.id){pairs.push({local,event});used.add(event.id);}
  }
}
function isDrawLabel(name:string):boolean{
  const n=normalizeName(name);return ["n","x","nul","match nul","draw"].includes(n)||n.includes("nul");
}
function extract1N2(detail:{match:BMatch,markets:BMarket[]}):{home:number,draw:number,away:number,market:string}|null{
  const homeTeam=detail.match.teams[0],awayTeam=detail.match.teams[1];
  for(const market of detail.markets){
    if(market.suspended)continue;
    let home:number|undefined,draw:number|undefined,away:number|undefined;
    for(const sel of market.selections){
      const raw=String(sel.name||"").trim(),n=normalizeName(raw);
      if(raw==="1"||n==="1"||eventTeamNames(homeTeam).some(t=>namesMatch(t,raw)))home=sel.odds;
      else if(raw==="2"||n==="2"||eventTeamNames(awayTeam).some(t=>namesMatch(t,raw)))away=sel.odds;
      else if(isDrawLabel(raw))draw=sel.odds;
    }
    if([home,draw,away].every(v=>typeof v==="number"&&Number.isFinite(v)&&v>1))return {home:home!,draw:draw!,away:away!,market:market.name};
  }
  return null;
}

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return json({ok:true});
  if(req.method!=="POST")return json({ok:false,error:"Méthode non autorisée."},405);
  try{
    const supabaseUrl=Deno.env.get("SUPABASE_URL"),serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if(!supabaseUrl||!serviceKey)throw new Error("Configuration Supabase incomplète.");
    const token=(req.headers.get("Authorization")||"").replace(/^Bearer\s+/i,"").trim();
    if(!token)return json({ok:false,error:"Authentification requise."},401);
    const admin=createClient(supabaseUrl,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:userData,error:userError}=await admin.auth.getUser(token),user=userData?.user;
    if(userError||!user)return json({ok:false,error:"Session invalide."},401);
    const {data:profile}=await admin.from("profiles").select("role,status").eq("id",user.id).maybeSingle();
    if(!profile||profile.status!=="active"||!["admin","super_admin"].includes(profile.role))return json({ok:false,error:"Réservé aux administrateurs."},403);

    const body=await req.json().catch(()=>({}));
    const action=String(body?.action||"sync")==="probe"?"probe":"sync";
    const seasonSlug=String(body?.seasonSlug||"ucl-2026-27");
    const matchdayId=body?.matchdayId?String(body.matchdayId):null;
    const limit=Math.max(1,Math.min(50,Number(body?.limit||24)));

    const {data:setting}=await admin.from("app_settings").select("value").eq("key","feature_betclic_odds").maybeSingle();
    if(setting?.value===false && profile.role!=="super_admin")return json({ok:false,code:"betclic_disabled",error:"La source Betclic expérimentale est désactivée."},403);

    const allMap=new Map<number,BMatch>();let total=0;
    for(let page=0;page<MAX_PAGES;page++){
      const offset=page*PAGE_SIZE;
      const result=await getBetclicMatches(offset);
      total=Math.max(total,result.total||0);
      result.matches.forEach(m=>{if(m.id)allMap.set(m.id,m);});
      if(!result.matches.length)break;
      if(total>0&&offset+PAGE_SIZE>=total)break;
    }
    const events=[...allMap.values()];
    if(action==="probe"){
      const range=eventRange(events);
      return json({ok:true,provider:"betclic-unofficial",received:events.length,total,feedFrom:range.from,feedTo:range.to,warning:"Source non officielle, susceptible de changer.",sample:events.slice(0,30).map(m=>({id:m.id,name:m.name,date:m.date,competition:m.competition,teams:m.teams}))});
    }

    const {data:season,error:seasonError}=await admin.from("seasons").select("id,slug").eq("slug",seasonSlug).maybeSingle();
    if(seasonError||!season)throw new Error(`Saison ${seasonSlug} introuvable.`);
    // Charge toute la saison puis filtre côté Function.
    // Important : d'anciennes lignes peuvent avoir is_test=NULL ; NULL signifie ici "pas un test".
    const {data:seasonRows,error:matchError}=await admin.from("matches")
      .select("id,matchday_id,kickoff_at,status,is_test,odds_provider,odds_updated_at,home_club:clubs!matches_home_club_id_fkey(name,short_name,tla),away_club:clubs!matches_away_club_id_fkey(name,short_name,tla)")
      .eq("season_id",season.id).order("kickoff_at");
    if(matchError)throw matchError;

    const allEligible=((seasonRows||[]) as any[]).filter(m=>
      m?.is_test!==true &&
      ["scheduled","postponed"].includes(String(m?.status||"").toLowerCase())
    ) as unknown as NidMatch[];

    // Si une journée a été demandée mais qu'elle ne fournit aucun match exploitable,
    // on retombe automatiquement sur toute la saison.
    const scopedEligible=matchdayId
      ? allEligible.filter((m:any)=>String((m as any).matchday_id||"")===String(matchdayId))
      : allEligible;
    const matchdayFallback=Boolean(matchdayId && scopedEligible.length===0 && allEligible.length>0);
    const eligible=matchdayFallback?allEligible:scopedEligible;

    const manualProtected=eligible.filter(m=>String(m.odds_provider||"")==="manual").length;
    const candidates=eligible.filter(m=>String(m.odds_provider||"")!=="manual");
    const pairs:Array<{local:NidMatch,event:BMatch}>=[];
    const used=new Set<number>();
    const discovered=new Map<number,BMatch>();
    events.forEach(e=>{if(e.id)discovered.set(e.id,e);});
    const feedRange=eventRange(events);

    // 1) Flux général : rapide, mais limité aux 400 premiers matchs football.
    pairFromPool(candidates,events,pairs,used,limit);
    const matchedFromFeed=pairs.length;

    // 2) Recherche compétition : toujours exécutée.
    // Cela nous donne un diagnostic Betclic même si le filtre local retourne 0 candidat.
    let searchQueries=0,searchReceived=0;
    const searchErrors:string[]=[];
    for(const q of ["Ligue des Champions","Champions League"]){
      try{
        searchQueries++;
        const found=await searchBetclic(q);
        searchReceived+=found.length;
        found.forEach(e=>{if(e.id)discovered.set(e.id,e);});
        if(candidates.length)pairFromPool(candidates,found,pairs,used,limit);
        if(candidates.length && pairs.length>=Math.min(limit,candidates.length))break;
      }catch(err){
        searchErrors.push(`${q}: ${err instanceof Error?err.message:String(err)}`);
      }
    }

    // 3) Recherche ciblée par club pour les prochains matchs encore non appariés.
    // Maximum 18 requêtes : un matchday C1 contient 18 rencontres.
    const searchedTerms=new Set<string>();
    if(candidates.length && pairs.length<Math.min(limit,candidates.length)){
      const unresolved=candidates.filter(c=>!isAlreadyPaired(c.id,pairs)).slice(0,limit);
      for(const local of unresolved){
        if(searchQueries>=20)break; // 2 compétitions + 18 clubs max
        const term=preferredClubSearch(local.home_club);
        const key=normalizeName(term);
        if(!term||searchedTerms.has(key))continue;
        searchedTerms.add(key);
        try{
          searchQueries++;
          const found=await searchBetclic(term);
          searchReceived+=found.length;
          found.forEach(e=>{if(e.id)discovered.set(e.id,e);});
          pairFromPool(candidates,found,pairs,used,limit);
          if(pairs.length>=Math.min(limit,candidates.length))break;
        }catch(err){
          searchErrors.push(`${term}: ${err instanceof Error?err.message:String(err)}`);
        }
      }
    }

    const allDiscovered=[...discovered.values()];
    const discoveredRange=eventRange(allDiscovered);
    const matchedFromSearch=Math.max(0,pairs.length-matchedFromFeed);
    const unresolvedSample=candidates
      .filter(c=>!isAlreadyPaired(c.id,pairs))
      .slice(0,8)
      .map(c=>({
        match_id:c.id,
        kickoff_at:c.kickoff_at,
        home:c.home_club?.name||c.home_club?.short_name||"",
        away:c.away_club?.name||c.away_club?.short_name||""
      }));

    let updated=0,noMarket=0,failed=0;const details:any[]=[];
    for(const pair of pairs){
      try{
        const detail=await getBetclicResult(pair.event.id!);
        const odds=extract1N2(detail);
        if(!odds){noMarket++;details.push({match_id:pair.local.id,betclic_id:pair.event.id,name:pair.event.name,status:"no_1n2"});continue;}
        const now=new Date().toISOString();
        const {error}=await admin.from("matches").update({
          odds_home:odds.home,odds_draw:odds.draw,odds_away:odds.away,
          odds_provider:"betclic-unofficial",odds_bookmaker:"Betclic",
          odds_source_season:season.slug,odds_is_test_shifted:false,odds_updated_at:now,updated_at:now
        }).eq("id",pair.local.id);
        if(error)throw error;
        updated++;details.push({match_id:pair.local.id,betclic_id:pair.event.id,name:pair.event.name,market:odds.market,home:odds.home,draw:odds.draw,away:odds.away,status:"updated"});
      }catch(err){
        failed++;details.push({match_id:pair.local.id,betclic_id:pair.event.id,name:pair.event.name,status:"error",error:err instanceof Error?err.message:String(err)});
      }
    }

    await admin.from("audit_logs").insert({actor_id:user.id,action:"betclic_odds_sync_v0911",entity_type:matchdayId?"matchday":"season",entity_id:matchdayId||season.slug,new_data:{provider:"betclic-unofficial",received:events.length,localSeasonRows:(seasonRows||[]).length,eligibleLocal:eligible.length,candidates:candidates.length,manualProtected,requestedMatchdayId:matchdayId,matchdayFallback,matched:pairs.length,matchedFromFeed,matchedFromSearch,searchQueries,searchReceived,updated,noMarket,failed,feedFrom:feedRange.from,feedTo:feedRange.to,discoveredFrom:discoveredRange.from,discoveredTo:discoveredRange.to,searchErrors:searchErrors.slice(0,4)}});
    return json({ok:true,provider:"betclic-unofficial",received:events.length,total,localSeasonRows:(seasonRows||[]).length,eligibleLocal:eligible.length,candidates:candidates.length,manualProtected,requestedMatchdayId:matchdayId,matchdayFallback,matched:pairs.length,matchedFromFeed,matchedFromSearch,searchQueries,searchReceived,updated,noMarket,failed,feedFrom:feedRange.from,feedTo:feedRange.to,discoveredFrom:discoveredRange.from,discoveredTo:discoveredRange.to,searchErrors:searchErrors.slice(0,4),unresolvedSample,warning:"Betclic est une source non officielle ; la saisie manuelle reste le secours.",details});
  }catch(err){
    console.error("sync-betclic-odds",err);
    return json({ok:false,provider:"betclic-unofficial",code:"betclic_unavailable",error:err instanceof Error?err.message:"Erreur Betclic inconnue.",warning:"La source Betclic est expérimentale. Le Nid reste fonctionnel sans elle et les cotes peuvent être saisies manuellement."},200);
  }
});
