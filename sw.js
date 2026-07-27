const CACHE = "nid-champions-v0.6.4";
const CORE = [
  "./","./index.html","./manifest.webmanifest","./config.js",
  "./css/base.css","./css/predictions.css","./css/ranking.css","./css/clubs.css","./css/champions.css","./css/layout.css","./css/teams.css","./css/avatars.css","./css/communication.css","./css/social.css","./css/admin.css",
  "./js/core.js","./js/avatars.js","./js/teams.js","./js/notifications.js","./js/social.js","./js/rivals.js","./js/support.js","./js/owl.js","./js/auth.js","./js/data.js","./js/champions.js","./js/profile.js","./js/predictions.js","./js/ranking.js","./js/admin.js","./js/realtime.js","./js/app.js",
  "./assets/assets-manifest.json","./assets/avatars/avatar-catalog.json","./assets/icons/icon-192.png","./assets/icons/icon-512.png","./assets/branding/owl/owl-masked-main.png","./assets/avatars/nid/avatar-hibou-or.png"
];
self.addEventListener("install",event=>{event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(CORE)));self.skipWaiting();});
self.addEventListener("activate",event=>{event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))));self.clients.claim();});
self.addEventListener("fetch",event=>{
  if(event.request.method!=="GET")return;const url=new URL(event.request.url);if(url.origin!==location.origin)return;
  event.respondWith(fetch(event.request).then(response=>{const clone=response.clone();caches.open(CACHE).then(cache=>cache.put(event.request,clone));return response;}).catch(()=>caches.match(event.request).then(r=>r||caches.match("./index.html"))));
});
self.addEventListener("push",event=>{
  let data={};try{data=event.data?.json()||{};}catch{data={title:"Le Nid des Champions",body:event.data?.text()||"Nouvelle notification"};}
  const title=data.title||"Le Nid des Champions";const icon=new URL(data.icon||"assets/icons/icon-192.png",self.registration.scope).href;const badge=new URL(data.badge||"assets/icons/icon-192.png",self.registration.scope).href;const options={body:data.body||"",icon,badge,tag:data.tag||undefined,renotify:false,data:data.data||{deepLink:"home"}};
  event.waitUntil(self.registration.showNotification(title,options));
});
self.addEventListener("notificationclick",event=>{
  event.notification.close();const deepLink=event.notification.data?.deepLink||"home";
  event.waitUntil(self.clients.matchAll({type:"window",includeUncontrolled:true}).then(clients=>{
    for(const client of clients){if("focus" in client){client.postMessage({type:"nidc-deep-link",deepLink});return client.focus();}}
    return self.clients.openWindow(`./?deepLink=${encodeURIComponent(deepLink)}`);
  }));
});
