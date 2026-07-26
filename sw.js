const CACHE = "nid-champions-v0.5.4";
const CORE = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./config.js",
  "./css/base.css",
  "./css/predictions.css",
  "./css/ranking.css",
  "./css/clubs.css",
  "./css/champions.css",
  "./css/layout.css",
  "./css/teams.css",
  "./css/avatars.css",
  "./js/core.js",
  "./js/avatars.js",
  "./js/teams.js",
  "./js/auth.js",
  "./js/data.js",
  "./js/champions.js",
  "./js/profile.js",
  "./js/predictions.js",
  "./js/ranking.js",
  "./js/admin.js",
  "./js/realtime.js",
  "./js/app.js",
  "./assets/assets-manifest.json",
  "./assets/avatars/avatar-catalog.json",
  "./assets/icons/icon-192.png",
  "./assets/icons/icon-512.png",
  "./assets/branding/owl/owl-masked-main.png",
  "./assets/avatars/nid/avatar-hibou-or.png"
];
self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(CORE)));
  self.skipWaiting();
});
self.addEventListener("activate", event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  if (url.origin !== location.origin) return;
  event.respondWith(fetch(event.request).then(response => {
    const clone = response.clone();
    caches.open(CACHE).then(cache => cache.put(event.request, clone));
    return response;
  }).catch(() => caches.match(event.request).then(r => r || caches.match("./index.html"))));
});
