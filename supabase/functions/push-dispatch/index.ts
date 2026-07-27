import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || (() => {
  try { return JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}").default || ""; } catch { return ""; }
})();
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || (() => {
  try { return JSON.parse(Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") || "{}").default || ""; } catch { return ""; }
})();
const VAPID_PUBLIC = Deno.env.get("PUSH_VAPID_PUBLIC_KEY") || "";
const VAPID_PRIVATE = Deno.env.get("PUSH_VAPID_PRIVATE_KEY") || "";
const VAPID_SUBJECT = Deno.env.get("PUSH_VAPID_SUBJECT") || "mailto:admin@example.invalid";
const CRON_SECRET = Deno.env.get("PUSH_CRON_SECRET") || "";

if (VAPID_PUBLIC && VAPID_PRIVATE) webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC, VAPID_PRIVATE);

const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

function categoryPrefKey(category: string) {
  return ({
    matches: "category_matches", champion: "category_champion", results: "category_results",
    rival: "category_rival", team: "category_team", owl: "category_owl", system: "category_system",
    ranking: "category_ranking", support: "category_support", social: "category_social",
  } as Record<string,string>)[category] || "notifications_enabled";
}

function timeMinutes(value = "00:00:00") {
  const [h,m] = String(value).split(":").map(Number); return (h || 0) * 60 + (m || 0);
}

function localMinutes(timeZone: string) {
  try {
    const parts = new Intl.DateTimeFormat("en-GB", { timeZone, hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).formatToParts(new Date());
    const h = Number(parts.find(p => p.type === "hour")?.value || 0);
    const m = Number(parts.find(p => p.type === "minute")?.value || 0);
    return h * 60 + m;
  } catch { return new Date().getUTCHours() * 60 + new Date().getUTCMinutes(); }
}

function insideQuiet(pref: any) {
  if (!pref?.quiet_hours_enabled) return false;
  const now = localMinutes(pref.timezone || "Europe/Paris");
  const start = timeMinutes(pref.quiet_start), end = timeMinutes(pref.quiet_end);
  return start === end ? false : start < end ? now >= start && now < end : now >= start || now < end;
}

async function logDelivery(notificationId: string | null, userId: string, subscriptionId: string | null, status: string, responseCode?: number, errorMessage?: string, kind = "notification") {
  await admin.from("push_delivery_logs").insert({
    notification_id: notificationId, user_id: userId, subscription_id: subscriptionId,
    delivery_kind: kind, status, response_code: responseCode || null, error_message: errorMessage?.slice(0,1000) || null,
  });
}

async function deliverNotification(n: any, kind = "notification") {
  if (!VAPID_PUBLIC || !VAPID_PRIVATE) return { sent: 0, failed: 0, skipped: 1, reason: "VAPID non configuré" };
  const { data: pref } = await admin.from("notification_preferences").select("*").eq("user_id", n.user_id).maybeSingle();
  const key = categoryPrefKey(n.category);
  const critical = n.category === "system" && n.payload?.critical === true;
  if (pref && (!pref.push_enabled || (!critical && (!pref.notifications_enabled || pref[key] === false)))) {
    await admin.from("notifications").update({ push_sent_at: new Date().toISOString() }).eq("id", n.id);
    await logDelivery(n.id,n.user_id,null,"skipped",undefined,"Préférence utilisateur",kind);
    return { sent:0,failed:0,skipped:1 };
  }
  const bypass = n.importance === "urgent" || (n.payload?.urgent === true && pref?.urgent_bypass_quiet !== false);
  if (pref && insideQuiet(pref) && !bypass) return { sent:0,failed:0,skipped:1, quiet:true };

  const { data: subs, error } = await admin.from("push_subscriptions").select("*").eq("user_id",n.user_id).eq("active",true);
  if (error) throw error;
  if (!subs?.length) {
    await admin.from("notifications").update({ push_sent_at:new Date().toISOString() }).eq("id",n.id);
    await logDelivery(n.id,n.user_id,null,"skipped",undefined,"Aucun appareil actif",kind);
    return {sent:0,failed:0,skipped:1};
  }

  let sent=0,failed=0;
  const payload = JSON.stringify({
    title:n.title, body:n.body, icon:"assets/icons/icon-192.png", badge:"assets/icons/icon-192.png",
    tag:n.source_key || n.id, data:{ notificationId:n.id, deepLink:n.deep_link || "home", ...n.payload },
  });
  for (const s of subs) {
    try {
      await webpush.sendNotification({ endpoint:s.endpoint, keys:{ p256dh:s.p256dh, auth:s.auth_key } }, payload, { TTL: 3600 });
      sent++;
      await admin.from("push_subscriptions").update({ last_success_at:new Date().toISOString(), failure_count:0 }).eq("id",s.id);
      await logDelivery(n.id,n.user_id,s.id,"sent",201,undefined,kind);
    } catch (e:any) {
      failed++;
      const code = Number(e?.statusCode || e?.status || 0) || null;
      const expired = code === 404 || code === 410;
      await admin.from("push_subscriptions").update({
        last_failure_at:new Date().toISOString(), failure_count:Number(s.failure_count||0)+1,
        ...(expired ? {active:false,disabled_at:new Date().toISOString()} : {}),
      }).eq("id",s.id);
      await logDelivery(n.id,n.user_id,s.id,expired?"expired":"failed",code || undefined,String(e?.message||e),kind);
    }
  }
  await admin.from("notifications").update({ push_sent_at:new Date().toISOString() }).eq("id",n.id);
  return {sent,failed,skipped:0};
}

async function createReminderNotifications() {
  const now = Date.now();
  const future = new Date(now + 25*60*60*1000).toISOString();
  const { data: seasons } = await admin.from("seasons").select("id").eq("is_active",true).limit(1);
  const season = seasons?.[0]; if (!season) return {created:0};
  const { data: matches } = await admin.from("matches").select("id,matchday_id,kickoff_at,status").eq("season_id",season.id).eq("status","scheduled").gt("kickoff_at",new Date(now).toISOString()).lte("kickoff_at",future).order("kickoff_at");
  if (!matches?.length) return {created:0};
  const byMd = new Map<string,any[]>(); for (const m of matches) { if(!m.matchday_id) continue; const arr=byMd.get(m.matchday_id)||[];arr.push(m);byMd.set(m.matchday_id,arr); }
  const { data: users } = await admin.from("profiles").select("id,username").eq("status","active");
  const { data: prefs } = await admin.from("notification_preferences").select("*");
  const prefMap = new Map((prefs||[]).map((p:any)=>[p.user_id,p]));
  let created=0;
  for (const [matchdayId, fixtures] of byMd) {
    const first = new Date(fixtures[0].kickoff_at).getTime(); const deltaMin=(first-now)/60000;
    const windows = [[1440,"reminder_24h"],[180,"reminder_3h"],[60,"reminder_1h"],[30,"reminder_30m"]] as const;
    const activeWindow = windows.find(([min])=>deltaMin<=min && deltaMin>min-16); if(!activeWindow) continue;
    const [minutes,prefKey]=activeWindow;
    const ids=fixtures.map(x=>x.id);
    const { data: preds } = await admin.from("predictions").select("user_id,match_id").in("match_id",ids);
    const done = new Map<string,Set<string>>(); for(const p of preds||[]){const set=done.get(p.user_id)||new Set();set.add(p.match_id);done.set(p.user_id,set);}
    for(const u of users||[]){
      const pref=prefMap.get(u.id); if(pref && (pref.notifications_enabled===false || pref.category_matches===false || pref[prefKey]===false)) continue;
      const missing=ids.filter(id=>!done.get(u.id)?.has(id)).length; if(!missing) continue;
      const urgent=minutes<=30;
      const row={user_id:u.id,season_id:season.id,category:"matches",title:`⏰ ${missing} pronostic${missing>1?"s":""} t’attend${missing>1?"ent":""}`,body:`La soirée commence dans ${minutes===1440?"24 h":minutes+" min"}.`,importance:urgent?"important":"info",deep_link:`matches:${matchdayId}`,payload:{matchday_id:matchdayId,missing,minutes,urgent},source_key:`reminder:${matchdayId}:${minutes}`,push_requested:true,expires_at:new Date(first+3600000).toISOString()};
      const { error }=await admin.from("notifications").insert(row); if(!error) created++;
    }
  }
  return {created};
}


async function createChampionReminders() {
  const { data: seasons }=await admin.from("seasons").select("id").eq("is_active",true).limit(1); const season=seasons?.[0]; if(!season)return {created:0};
  const windows = [[1440,"reminder_24h"],[180,"reminder_3h"],[60,"reminder_1h"],[30,"reminder_30m"]] as const;
  let created=0;
  for(const pick of [1,2]){
    if(pick===2){const {data:finished}=await admin.rpc("league_phase_finished_v040",{p_season_id:season.id});if(!finished)continue;}
    const fn=pick===1?"champion_first_close_at_v040":"champion_second_close_at_v040";
    const {data:close}=await admin.rpc(fn,{p_season_id:season.id}); if(!close)continue;
    const delta=(new Date(close).getTime()-Date.now())/60000;if(delta<=0||delta>1456)continue;
    const w=windows.find(([m])=>delta<=m&&delta>m-16);if(!w)continue;const [minutes,prefKey]=w;
    const [{data:users},{data:prefs},{data:picks}]=await Promise.all([
      admin.from("profiles").select("id").eq("status","active"),admin.from("notification_preferences").select("*"),admin.from("champion_predictions").select("user_id").eq("season_id",season.id).eq("pick_number",pick)
    ]);
    const has=new Set((picks||[]).map((x:any)=>x.user_id));const prefMap=new Map((prefs||[]).map((x:any)=>[x.user_id,x]));
    for(const u of users||[]){const pref=prefMap.get(u.id);if(has.has(u.id)||pref?.category_champion===false||pref?.notifications_enabled===false||pref?.[prefKey]===false)continue;const urgent=minutes<=30;const {error}=await admin.from("notifications").insert({user_id:u.id,season_id:season.id,category:"champion",title:"🏆 Ton champion n’est toujours pas choisi",body:`Le choix n°${pick} se verrouille dans ${minutes===1440?"24 h":minutes+" min"}.`,importance:urgent?"important":"info",deep_link:"profile",payload:{pick_number:pick,minutes,urgent},source_key:`champion-reminder:${season.id}:${pick}:${minutes}`,push_requested:true,expires_at:close});if(!error)created++;}
  }
  return {created};
}

async function createCompletedMatchdaySummaries(){
  const {data:seasons}=await admin.from("seasons").select("id").eq("is_active",true).limit(1);const season=seasons?.[0];if(!season)return {created:0};
  const {data:mds}=await admin.from("matchdays").select("id,name").eq("season_id",season.id);let created=0;
  const {data:users}=await admin.from("profiles").select("id").eq("status","active");
  const {data:rivals}=await admin.from("player_rivals").select("user_id,rival_user_id").eq("season_id",season.id);const rivalMap=new Map((rivals||[]).map((r:any)=>[r.user_id,r.rival_user_id]));
  for(const md of mds||[]){
    const {data:matches}=await admin.from("matches").select("id,status").eq("matchday_id",md.id);if(!matches?.length||matches.some((m:any)=>!["finished","cancelled"].includes(m.status)))continue;
    const ids=matches.filter((m:any)=>m.status==="finished").map((m:any)=>m.id);if(!ids.length)continue;
    const {data:preds}=await admin.from("predictions").select("user_id,points").in("match_id",ids);const totals=new Map<string,number>();for(const pr of preds||[])totals.set(pr.user_id,(totals.get(pr.user_id)||0)+Number(pr.points||0));
    for(const u of users||[]){const points=totals.get(u.id)||0;const rid=rivalMap.get(u.id);const rpoints=rid?(totals.get(rid)||0):null;const extra=rpoints==null?"":` Ton rival en marque ${rpoints}.`;const {error}=await admin.from("notifications").insert({user_id:u.id,season_id:season.id,category:"results",title:"⚽ La journée est terminée",body:`Tu marques ${points} point${points>1?"s":""}.${extra}`,importance:"info",deep_link:"ranking",payload:{matchday_id:md.id,points,rival_points:rpoints},source_key:`result-summary:${md.id}`,push_requested:true});if(!error)created++;}
  }
  return {created};
}

async function updateRankingNotifications(){
  const {data:seasons}=await admin.from("seasons").select("id").eq("is_active",true).limit(1);const season=seasons?.[0];if(!season)return {created:0};
  const {data:rows,error}=await admin.rpc("get_leaderboard_v040",{p_season_id:season.id,p_scope:"general",p_matchday_id:null,p_evening_date:null,p_include_live:true});if(error||!rows)return {created:0};
  const {data:oldRows}=await admin.from("ranking_notification_state").select("*").eq("season_id",season.id);const old=new Map((oldRows||[]).map((r:any)=>[r.user_id,r]));const nowMap=new Map((rows||[]).map((r:any)=>[r.user_id,r]));
  const {data:rivals}=await admin.from("player_rivals").select("user_id,rival_user_id").eq("season_id",season.id);const rivalMap=new Map((rivals||[]).map((r:any)=>[r.user_id,r.rival_user_id]));let created=0;
  for(const r of rows||[]){const prev:any=old.get(r.user_id);if(prev&&Number(prev.rank)!==Number(r.rank)){
      const from=Number(prev.rank),to=Number(r.rank);let title="📈 Le classement bouge",body=`Tu passes #${from} → #${to}.`,push=false;
      if(from>3&&to<=3){title="🏆 Entrée sur le podium";push=true;}else if(from<=3&&to>3){title="Le podium s’éloigne";push=true;}else if(from!==1&&to===1){title="👑 Tu prends la tête du Nid";push=true;}else if(from===1&&to!==1){title="La première place vient de changer de bec";push=true;}
      const rivalId=rivalMap.get(r.user_id),oldR=old.get(rivalId),newR=nowMap.get(rivalId);if(oldR&&newR){const wasAhead=from<Number(oldR.rank),isAhead=to<Number(newR.rank);if(wasAhead!==isAhead){title=isAhead?"⚔️ Tu dépasses ton rival":"⚔️ Ton rival vient de te dépasser";body=isAhead?`Tu passes devant ton rival : #${to} contre #${newR.rank}.`:`Ton rival est #${newR.rank}, toi #${to}.`;push=true;}}
      const {error:nErr}=await admin.from("notifications").insert({user_id:r.user_id,season_id:season.id,category:push&&title.includes("rival")?"rival":"ranking",title,body,importance:push?"important":"normal",deep_link:push&&title.includes("rival")?"rival":"ranking",payload:{from_rank:from,to_rank:to},source_key:`rank-change:${r.user_id}:${Date.now()}`,push_requested:push});if(!nErr)created++;
    }
    await admin.from("ranking_notification_state").upsert({season_id:season.id,user_id:r.user_id,rank:Number(r.rank),points:Number(r.points||0),updated_at:new Date().toISOString()},{onConflict:"season_id,user_id"});
  }
  return {created};
}

async function createRivalPreMatchNotifications() {
  const now=Date.now(); const horizon=new Date(now+3*60*60*1000).toISOString();
  const {data:seasons}=await admin.from("seasons").select("id").eq("is_active",true).limit(1);const season=seasons?.[0];if(!season)return {created:0};
  const {data:matches}=await admin.from("matches").select("matchday_id,kickoff_at,status").eq("season_id",season.id).eq("status","scheduled").gt("kickoff_at",new Date(now).toISOString()).lte("kickoff_at",horizon).not("matchday_id","is",null).order("kickoff_at");
  if(!matches?.length)return {created:0};
  const firstByMd=new Map<string,number>();for(const m of matches){const t=new Date(m.kickoff_at).getTime();if(!firstByMd.has(m.matchday_id)||t<(firstByMd.get(m.matchday_id)||Infinity))firstByMd.set(m.matchday_id,t);}
  const [{data:rivals},{data:profiles},{data:prefs}]=await Promise.all([
    admin.from("player_rivals").select("user_id,rival_user_id").eq("season_id",season.id),
    admin.from("profiles").select("id,username").eq("status","active"),
    admin.from("notification_preferences").select("user_id,category_rival,notifications_enabled")
  ]);
  const names=new Map((profiles||[]).map((p:any)=>[p.id,p.username]));const prefMap=new Map((prefs||[]).map((p:any)=>[p.user_id,p]));let created=0;
  for(const [matchdayId,first] of firstByMd){const delta=(first-now)/60000;if(delta>180||delta<=165)continue;
    for(const r of rivals||[]){const pref=prefMap.get(r.user_id);if(pref?.notifications_enabled===false||pref?.category_rival===false)continue;
      const {data:duels}=await admin.from("rival_duels").select("result").eq("season_id",season.id).eq("user_id",r.user_id).eq("rival_user_id",r.rival_user_id).not("finalized_at","is",null);
      const wins=(duels||[]).filter((d:any)=>d.result==="win").length,draws=(duels||[]).filter((d:any)=>d.result==="draw").length,losses=(duels||[]).filter((d:any)=>d.result==="loss").length;
      const mutual=(rivals||[]).some((x:any)=>x.user_id===r.rival_user_id&&x.rival_user_id===r.user_id);
      const rivalName=names.get(r.rival_user_id)||"ton rival";const title=mutual?"⚔️ Rivalité mutuelle ce soir":"⚔️ Le duel reprend ce soir";
      const body=`Tu affrontes ${rivalName}. Bilan : ${wins} V · ${draws} N · ${losses} D. Le Hibou a déjà sorti le carnet.`;
      const {error}=await admin.from("notifications").insert({user_id:r.user_id,season_id:season.id,category:"rival",title,body,importance:"info",deep_link:"rival",payload:{matchday_id:matchdayId,rival_user_id:r.rival_user_id,mutual},source_key:`rival-pre:${matchdayId}`,push_requested:true,expires_at:new Date(first+60*60*1000).toISOString()});if(!error)created++;
    }
  }
  return {created};
}

async function refreshRivals() {
  const { data: seasons }=await admin.from("seasons").select("id").eq("is_active",true).limit(1); const season=seasons?.[0]; if(!season)return;
  const { data: mds }=await admin.from("matchdays").select("id").eq("season_id",season.id);
  for(const md of mds||[]) await admin.rpc("refresh_rival_duels_v060",{p_matchday_id:md.id});
}

async function deliverPending(limit=100) {
  const nowIso=new Date().toISOString();
  const { data: rows, error } = await admin.from("notifications").select("*").eq("push_requested",true).is("push_sent_at",null).is("deleted_at",null).or(`push_not_before.is.null,push_not_before.lte.${nowIso}`).order("created_at").limit(limit);
  if(error) throw error;
  const valid=(rows||[]).filter((n:any)=>!n.expires_at||new Date(n.expires_at).getTime()>Date.now());
  const expired=(rows||[]).filter((n:any)=>n.expires_at&&new Date(n.expires_at).getTime()<=Date.now());
  if(expired.length) await admin.from("notifications").update({deleted_at:nowIso}).in("id",expired.map((n:any)=>n.id));
  let sent=0,failed=0,skipped=0;
  for(const n of valid){const r=await deliverNotification(n);sent+=r.sent||0;failed+=r.failed||0;skipped+=r.skipped||0;}
  return {notifications:valid.length,expired:expired.length,sent,failed,skipped};
}

async function authenticatedUser(req:Request) {
  const auth=req.headers.get("Authorization")||""; const token=auth.replace(/^Bearer\s+/i,""); if(!token)return null;
  const { data, error }=await admin.auth.getUser(token); if(error||!data.user)return null; return data.user;
}

Deno.serve(async (req) => {
  if(req.method==="OPTIONS") return new Response("ok",{headers:corsHeaders});
  if(req.method!=="POST") return json({error:"POST requis"},405);
  try{
    const body=await req.json().catch(()=>({})); const action=String(body.action||"run");
    if(action==="public-key") return json({publicKey:VAPID_PUBLIC,configured:Boolean(VAPID_PUBLIC&&VAPID_PRIVATE)});

    if(action==="test"){
      const user=await authenticatedUser(req); if(!user)return json({error:"Connexion requise"},401);
      const { data:profile }=await admin.from("profiles").select("role,status").eq("id",user.id).maybeSingle();
      if(profile?.role!=="super_admin"||profile?.status!=="active")return json({error:"Réservé au Super Admin"},403);
      const target=body.target_user_id||user.id;
      const title=String(body.title||"🔔 Test du Nid").slice(0,160);
      const message=String(body.body||"Si tu lis ceci, les plumes sont correctement raccordées.").slice(0,2000);
      const { data:n,error }=await admin.from("notifications").insert({user_id:target,category:"system",title,body:message,importance:"important",deep_link:String(body.deep_link||"home"),payload:{test:true},source_key:`push-test:${Date.now()}:${target}`,push_requested:true,created_by:user.id}).select("*").single();
      if(error)throw error; const result=await deliverNotification(n,"test"); return json({ok:true,notification_id:n.id,...result});
    }

    const secret=req.headers.get("x-cron-secret")||String(body.cron_secret||"");
    if(!CRON_SECRET || secret!==CRON_SECRET)return json({error:"Secret cron invalide"},403);
    const reminders=await createReminderNotifications(); const champions=await createChampionReminders(); const rivalPre=await createRivalPreMatchNotifications(); await refreshRivals(); const results=await createCompletedMatchdaySummaries(); const ranking=await updateRankingNotifications(); const delivery=await deliverPending();
    // purge notifications ordinaires expirées et appareils invalides vieux de 30 jours
    await admin.from("notifications").update({deleted_at:new Date().toISOString()}).lt("expires_at",new Date().toISOString()).is("deleted_at",null);
    await admin.from("push_subscriptions").delete().eq("active",false).lt("disabled_at",new Date(Date.now()-30*86400000).toISOString());
    return json({ok:true,reminders,champions,rivalPre,results,ranking,delivery});
  }catch(e:any){console.error(e);return json({error:String(e?.message||e)},500);}
});
