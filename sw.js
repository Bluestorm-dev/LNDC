const CACHE = "nid-champions-v0.9.9-icons-maskable";
const CORE = [
  "./","./index.html","./manifest.webmanifest","./config.js",
  "./css/base.css","./css/icons.css","./css/predictions.css","./css/ranking.css","./css/clubs.css","./css/champions.css","./css/layout.css","./css/teams.css","./css/avatars.css","./css/communication.css","./css/social.css","./css/admin.css","./css/gamification.css","./css/ucl.css","./css/evenings.css","./css/v080.css","./css/career.css","./css/admin095.css","./css/finale098.css","./css/final-report098.css","./css/preseason099.css",
  "./js/core.js","./js/icons.js","./js/avatars.js","./js/teams.js","./js/notifications.js","./js/social.js","./js/rivals.js","./js/support.js","./js/owl.js","./js/auth.js","./js/data.js","./js/champions.js","./js/ucl.js","./js/evenings.js","./js/profile.js","./js/career.js","./js/predictions.js","./js/ranking.js","./js/admin.js","./js/admin-test.js","./js/admin095.js","./js/finale098.js","./js/preseason099.js","./js/realtime.js","./js/gamification.js","./js/app.js",
  "./finale.html","./diplome.html","./js/final-report098.js","./assets/assets-manifest.json","./assets/avatars/avatar-catalog.json","./assets/icons/icon-192.png","./assets/icons/icon-512.png","./assets/icons/icon-maskable-192.png","./assets/icons/icon-maskable-512.png","./assets/branding/owl/owl-masked-main.png","./assets/avatars/nid/avatar-hibou-or.png","./assets/icons/runtime/home.png","./assets/icons/runtime/predictions.png","./assets/icons/runtime/knockout.png","./assets/icons/runtime/ranking.png","./assets/icons/runtime/season.png","./assets/icons/runtime/trophy.png","./assets/icons/runtime/live.png","./assets/icons/runtime/teams.png","./assets/icons/runtime/museum.png","./assets/icons/runtime/profile.png","./assets/icons/runtime/admin.png","./assets/icons/runtime/notification.png","./assets/icons/runtime/settings.png","./assets/icons/runtime/search.png","./assets/icons/runtime/lock.png","./assets/icons/runtime/success.png","./assets/icons/runtime/warning.png","./assets/icons/runtime/error.png","./assets/icons/runtime/football.png","./assets/icons/runtime/genius.png","./assets/icons/runtime/rivalry.png","./assets/icons/runtime/calendar.png","./assets/icons/runtime/refresh.png","./assets/icons/runtime/owl.png"
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
