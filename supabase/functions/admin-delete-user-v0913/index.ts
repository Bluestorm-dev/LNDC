import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const json=(body:any,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});

Deno.serve(async req=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
  if(req.method!=="POST")return json({ok:false,error:"Méthode non autorisée."},405);
  try{
    const url=Deno.env.get("SUPABASE_URL")!;
    const anonKey=Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const auth=req.headers.get("Authorization")||"";
    if(!auth)return json({ok:false,error:"Authentification requise."},401);
    const caller=createClient(url,anonKey,{global:{headers:{Authorization:auth}}});
    const admin=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:{user},error:uerr}=await caller.auth.getUser();
    if(uerr||!user)return json({ok:false,error:"Session invalide."},401);
    const {data:me}=await admin.from("profiles").select("id,role,status,username").eq("id",user.id).maybeSingle();
    if(!me||me.role!=="super_admin"||me.status!=="active")return json({ok:false,error:"Réservé au Super Admin."},403);
    const body=await req.json().catch(()=>({}));const targetId=String(body?.user_id||"");
    if(!/^[0-9a-f-]{36}$/i.test(targetId))return json({ok:false,error:"Identifiant utilisateur invalide."},400);
    if(targetId===user.id)return json({ok:false,error:"Tu ne peux pas supprimer ton propre compte Super Admin."},400);
    const {data:target,error:terr}=await admin.from("profiles").select("id,username,role,status,avatar_storage_path").eq("id",targetId).maybeSingle();
    if(terr||!target)return json({ok:false,error:"Compte introuvable."},404);
    if(target.role==="super_admin")return json({ok:false,error:"Un compte Super Admin ne peut pas être supprimé ici."},400);

    // Libère la contrainte capitaine avant suppression du profil.
    const {data:captained,error:teamErr}=await admin.from("teams").select("id,name,season_id").eq("captain_user_id",targetId);
    if(teamErr)throw teamErr;
    for(const team of captained||[]){
      const {data:members}=await admin.from("team_memberships").select("user_id,joined_at").eq("team_id",team.id).is("left_at",null).neq("user_id",targetId).order("joined_at").limit(1);
      const replacement=members?.[0]?.user_id;
      if(replacement){const {error}=await admin.from("teams").update({captain_user_id:replacement,updated_at:new Date().toISOString()}).eq("id",team.id);if(error)throw error;}
      else{const {error}=await admin.from("teams").delete().eq("id",team.id);if(error)throw error;}
    }

    if(target.avatar_storage_path){try{await admin.storage.from("player-avatars").remove([target.avatar_storage_path]);}catch(_){}}
    try{await admin.from("audit_logs").insert({actor_id:user.id,action:"account_hard_delete_v0913",entity_type:"profile",entity_id:targetId,old_data:{username:target.username,role:target.role,status:target.status},new_data:{deleted:true}});}catch(_){}
    const {error:delErr}=await admin.auth.admin.deleteUser(targetId,false);
    if(delErr)throw delErr;
    return json({ok:true,deleted_user_id:targetId,username:target.username});
  }catch(err){console.error("admin-delete-user-v0913",err);return json({ok:false,error:err instanceof Error?err.message:String(err)},500);}
});
