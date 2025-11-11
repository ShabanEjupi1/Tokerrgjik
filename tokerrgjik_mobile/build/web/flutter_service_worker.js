'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"android-chrome-192x192.png": "a1d5e5505cdba2f5b66964c224d0262e",
"android-chrome-512x512.png": "bc110aa7d2ab1e241ff140f344442600",
"apple-touch-icon.png": "35076c01c055c1618948758148cdb5ed",
"assets/AssetManifest.bin": "a508c6dca21d22bca8160588d0d32a05",
"assets/AssetManifest.bin.json": "3f09b4c0ad7e1bb46a70b8a0558aa6cf",
"assets/AssetManifest.json": "b320f6695a20b41f68d3cc8c61fa7470",
"assets/assets/icon.png": "a440a1cfac2a505b03d9ee7e6f086679",
"assets/assets/sounds/background.wav": "e4d73217503c76afea7ecc0f6493f1c6",
"assets/assets/sounds/click.wav": "581368e2dec602d5be5619013df7f703",
"assets/assets/sounds/coin.wav": "abd0ca9e32a4915c211fef3e809d9056",
"assets/assets/sounds/lose.wav": "723a82707b70a4e8d0d31f1ce4bf23ea",
"assets/assets/sounds/mill.wav": "397e21a314eb311e0e69b1fba52d44b9",
"assets/assets/sounds/move.wav": "5226db8dac25421730526f66b793b0c1",
"assets/assets/sounds/place.wav": "04684f4998453878ce882d1a69583892",
"assets/assets/sounds/remove.wav": "1091e8a62fceee6108bbeb3be96cf38c",
"assets/assets/sounds/win.wav": "7bd5a1bd09e284268b62897b84fdd89c",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "b3315302576ee507d6ce3d05bce2fe38",
"assets/NOTICES": "8c57b762dd384bf8a9d23ed29a44b333",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"BingSiteAuth.xml": "82d6dab04474bc04ede1d4ccc5f86f18",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon-16x16.png": "29b745d13de7016d30e45de8a6b35f4f",
"favicon-32x32.png": "cb1a87e39c56c40f2c8ad449aa8321a0",
"favicon.ico": "b8ef72badd49f4d921b88c6ed96b8efd",
"favicon.png": "29b745d13de7016d30e45de8a6b35f4f",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "4f3a231f110a5f9c1d8093eb3f570ba6",
"google9d4f44d9d273f067.html": "31ba4e2d2542ca5ec7db4db4c86acfb9",
"icons/favicon-16x16.png": "29b745d13de7016d30e45de8a6b35f4f",
"icons/Icon-16.png": "b7309066e39bb569d4e76c8f2c45ee24",
"icons/Icon-192.png": "5d0bfa25e73e9bbc1638294d73070c1a",
"icons/Icon-32.png": "2e3a8b246eeaf1fa1e4331a1463bdfdc",
"icons/Icon-512.png": "2dd2452122e9e8893df6296171fb01c1",
"icons/Icon-96.png": "c8a14a50ea08f64aef5c9c1d94f208d1",
"icons/Icon-maskable-192.png": "ecd714500c7c00960c587d69a00bcad4",
"icons/Icon-maskable-512.png": "2dd2452122e9e8893df6296171fb01c1",
"index.html": "cb6d0a69d0f7e3afd06148e77cbbc9a2",
"/": "cb6d0a69d0f7e3afd06148e77cbbc9a2",
"license.html": "212bf2660dbf564269d7905bffa6b7a3",
"main.dart.js": "d317b1d6c2c2afae4ebac17472b084ed",
"manifest.json": "435d66d156a4fda647aca1441d73f180",
"robots.txt": "3a5be03e5461b0a20a0276b03dd15ef4",
"sitemap.xml": "5b9fe724aceb469f6e91b9a3069f4462",
"version.json": "6e792a47118407ca1b44ac3f8a068b72"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
