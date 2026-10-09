'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"manifest.json": "32e4e03665a674caa8312129c60f6b15",
"icons/Icon-512.png": "df2d5bcd922dad6bd241f7094c9cd406",
"icons/Icon-192.png": "cdac32dd749b997b8f4462a81b9947ce",
"icons/Icon-maskable-192.png": "625c04999a6ece3cb21f4a7a910ceac2",
"icons/startup/startup-1242x2208.png": "9a4ac789e8cd4e4c6268cc334a4d4264",
"icons/startup/startup-1242x2688.png": "a017617e83a14083759af67a4974c19a",
"icons/startup/startup-828x1792.png": "a78b4cbd1dcece9fccd7db86966f0a98",
"icons/startup/startup-1125x2436.png": "2256cf58412d51b77764b6c5398cbbdb",
"icons/startup/startup-1260x2736.png": "676ff8565b7369c037329c866921bbad",
"icons/startup/startup-1290x2796.png": "b704b711bdb604452e6961ff6a82e513",
"icons/startup/startup-1206x2622.png": "af7210ae3ff496108ac93fd36e6ae1ef",
"icons/startup/startup-1170x2532.png": "b44bcc56ae08eccdb2322e418b9de8c0",
"icons/startup/startup-1179x2556.png": "690bb6daaa516fee2826d54193198f64",
"icons/startup/startup-750x1334.png": "c35a5e21e12e7b9a5955203df235eaea",
"icons/startup/startup-1284x2778.png": "672054845c04a6a1bb40504abd4d5335",
"icons/startup/startup-1320x2868.png": "e330e40ceb728810b74f90c28c68f6a5",
"icons/apple-touch-icon.png": "367359b308b83f4bb68bb760ba3a9c7f",
"icons/Icon-maskable-512.png": "459aef287b8ebd1d49f76dda9a33044a",
"panel.html": "4a0bfa1a4235d2f5f410470c142873b5",
"flutter_bootstrap.js": "ae65c2c179421d4f24123f469c785e83",
"assets/AssetManifest.bin.json": "0835b6a85272376b8413d85a23961983",
"assets/AssetManifest.json": "1b6f805dd695ba0e12f2790b129e139c",
"assets/assets/brand/letter-d.png": "6c9e3b97599b20c06be8a2c572723607",
"assets/assets/brand/letter-b.png": "130e4e0630c1916ebaeb5b5ab79836d5",
"assets/assets/brand/letter-i.png": "27a703e53d81fc6b9dc4efbe76052bc0",
"assets/assets/brand/letter-o.png": "4aff3545c9f39886c1784e76f16b39e9",
"assets/assets/brand/letter-y.png": "6894c67d7e0d6078c5f823c0889e5ea5",
"assets/assets/brand/logo-white.png": "30b3a7ef4b40c2158b0ce20f7050310c",
"assets/assets/brand/logo-red.png": "a0b72218161af7c34cfd1a3a9d699433",
"assets/assets/sounds/zil.wav": "e0cb13c964ed71d1de0ae06357350193",
"assets/assets/photos/afis_dondurma.jpg": "32a402759465d88577d5dd44bf9b8ecd",
"assets/assets/photos/kola.jpg": "2521033761011b5be24eacfbd249b7a2",
"assets/assets/photos/helva.jpg": "61db39435230d19498c61b1bbf36ad4c",
"assets/assets/photos/tava.jpg": "3891f2a39c4f822134f26b3805dbf39a",
"assets/assets/photos/lah_menu.jpg": "48d0d6b86536d9879147a0cdf036d4de",
"assets/assets/photos/afis_durum.jpg": "70a3d50e3608416f89176d954d82f241",
"assets/assets/photos/pide_kusbasi.jpg": "6f40d00452d96619c34aac51d683ff84",
"assets/assets/photos/logo_ld.jpg": "2eac87daff660741f6ab353f9fd79316",
"assets/assets/photos/cig_porsiyon.jpg": "9fda58646436127cf91bcde39b305651",
"assets/assets/photos/ud_kapak.jpg": "ec37e24a11165b91989d9b3f4ffdc876",
"assets/assets/photos/ck_kapak.jpg": "5eb0ec6ff0ab23232f8fe85d46e71ecb",
"assets/assets/photos/k/afis_dondurma.jpg": "b633a4ec1bd181be9357a376947a3758",
"assets/assets/photos/k/kola.jpg": "e5ad2d2db1b056507eaba09bca03e4a2",
"assets/assets/photos/k/helva.jpg": "a4c14ad27201007101668ab502c20133",
"assets/assets/photos/k/tava.jpg": "e62936656378391f142cc767bdcc36e1",
"assets/assets/photos/k/lah_menu.jpg": "c29af4a1b5a54b9edc3e3e60abec28a2",
"assets/assets/photos/k/afis_durum.jpg": "17839149472d8a6f736a26aaacf0d436",
"assets/assets/photos/k/pide_kusbasi.jpg": "e02da7bc0527acd7cde3c322e2934931",
"assets/assets/photos/k/logo_ld.jpg": "fb7702db9e79fcd1cbac39e803e18eaf",
"assets/assets/photos/k/cig_porsiyon.jpg": "da831f8d27e54dc18f13bb55bfc5c1b5",
"assets/assets/photos/k/ud_kapak.jpg": "697fc9d83ac78a7ebfa00c163449484a",
"assets/assets/photos/k/ck_kapak.jpg": "5473b8319446f48a33b26e80f14c37e8",
"assets/assets/photos/k/logo_ck.jpg": "f1b2fbf8372fc00f21f0ac352814db57",
"assets/assets/photos/k/adana.jpg": "e1287968f609fef36e0cf3dc5b585915",
"assets/assets/photos/k/su.jpg": "07a9f0b380496a8387125b52a7c3ca76",
"assets/assets/photos/k/dondurma.jpg": "3223b54ec41cdc8d785ccd1597576fb8",
"assets/assets/photos/k/ayran.jpg": "a8db0be54f8fedafc205b6b3b38a336a",
"assets/assets/photos/k/lah_kiymali.jpg": "4b4090ffe16d835ad9858f2dfd3dd29b",
"assets/assets/photos/k/tavuk.jpg": "3e347ec7231ab0e2a0bcbf242a87e0af",
"assets/assets/photos/k/pide_yumurtali.jpg": "05554737abfa40d56a2b5edf58771dcb",
"assets/assets/photos/k/dondurma2.jpg": "aa6aa35da3b8255d9e94d6986752e940",
"assets/assets/photos/k/ld_kapak.jpg": "15553228ab096ba4bf9791c50d0a45e9",
"assets/assets/photos/k/pide_karisik.jpg": "ce8177a949b792c075570521819ec39c",
"assets/assets/photos/k/pide_kasarli.jpg": "c5e6b14364fa9b52cc2481719e26d510",
"assets/assets/photos/k/lah_acili.jpg": "598d3929fadb13546caf198f36c66ced",
"assets/assets/photos/k/eli.jpg": "be5e361f7fa4548c122de551b0150c65",
"assets/assets/photos/k/logo_ud.jpg": "b168c460715d48faf550f6ef4c7c9794",
"assets/assets/photos/k/urfa.jpg": "bc68828ac62e83250de4c111c933be36",
"assets/assets/photos/k/salgam.jpg": "bc4f5db6806a6a194e5af73c29cf1b9f",
"assets/assets/photos/k/lahmacun.jpg": "90b7c3e2d854557f76aa729956ae10d7",
"assets/assets/photos/k/fp_kapak.jpg": "d329dd0b7b3cb6f7b254429f7244700e",
"assets/assets/photos/k/kd_kapak.jpg": "3223b54ec41cdc8d785ccd1597576fb8",
"assets/assets/photos/k/logo_kd.jpg": "24698c95e80f4fb8eb6c4b85c378236f",
"assets/assets/photos/k/logo_fp.jpg": "ad4f5e679d50df31505e1210aa3951f2",
"assets/assets/photos/k/ayran2.jpg": "9867d6c831a7be81876db3d0ac55d477",
"assets/assets/photos/k/cig_durum.jpg": "33ca8b46b0df39043255cdde104a284f",
"assets/assets/photos/logo_ck.jpg": "16ca5392656b5f5be7ce13cac3ccc30a",
"assets/assets/photos/adana.jpg": "f5e2402249d0fc08a13519779ded4b77",
"assets/assets/photos/su.jpg": "70c289b016c2ab0c11955c371fcd897c",
"assets/assets/photos/dondurma.jpg": "026c7657237f5d7511902516a1abc382",
"assets/assets/photos/ayran.jpg": "401354236f25d8816a295037bade94f8",
"assets/assets/photos/lah_kiymali.jpg": "8a27ab4c5f5668993dfc27ecb144de9f",
"assets/assets/photos/tavuk.jpg": "d36d2b3f8b2eae500d643a6449deff1b",
"assets/assets/photos/pide_yumurtali.jpg": "f5964426bb3a9f6ba15e8fc425f63edf",
"assets/assets/photos/dondurma2.jpg": "25fe7d42badc238cb71e2b209bad9548",
"assets/assets/photos/ld_kapak.jpg": "6a0bc3dc10c1a1842a22bb71f32e33cb",
"assets/assets/photos/pide_karisik.jpg": "9ad9abc10cc4cb994e024a8dbc4b7902",
"assets/assets/photos/pide_kasarli.jpg": "2773df3eaadae2b8cd050d5cbd1e8be1",
"assets/assets/photos/lah_acili.jpg": "811389690da5a9a15bc0c80f125e0e8d",
"assets/assets/photos/eli.jpg": "0b75a3b027755d0dacb0de2ccb9829b0",
"assets/assets/photos/logo_ud.jpg": "5e3d55ddec7d0cdf1a689dcfd4218260",
"assets/assets/photos/urfa.jpg": "cc8853552511f18913bcc690ff73b184",
"assets/assets/photos/salgam.jpg": "72d5bc4945d343ddcff58c12f8f74f0d",
"assets/assets/photos/lahmacun.jpg": "435e005672b29d39a11fa7f59d7a76c8",
"assets/assets/photos/fp_kapak.jpg": "b249025fce317e4515b80ebdaf8ee084",
"assets/assets/photos/kd_kapak.jpg": "026c7657237f5d7511902516a1abc382",
"assets/assets/photos/logo_kd.jpg": "49317fd39f0c33511cbf294faba4507e",
"assets/assets/photos/logo_fp.jpg": "96968cd276b6a0fdd1a8e32d19693802",
"assets/assets/photos/ayran2.jpg": "d1cc11b4746a722ce486edddff5ca0f8",
"assets/assets/photos/cig_durum.jpg": "b40cae4c1d014a104df65a7f2a6cf71c",
"assets/assets/fonts/Fredoka-SemiBold.ttf": "437beaeef0910069993742ca906baba9",
"assets/assets/fonts/Figtree-ExtraBold.ttf": "6b30ab0e33b14d6ae0269b96eff95e4a",
"assets/assets/fonts/Figtree-Medium.ttf": "5be67d9769cbdb1215ecfee01c4208f9",
"assets/assets/fonts/Fredoka-Bold.ttf": "2b9dfbe2d737b42134ec1bd238204fc1",
"assets/assets/fonts/Figtree-Bold.ttf": "954d8b0c5f18813a26b95739bd9b3693",
"assets/assets/fonts/Fredoka-Medium.ttf": "ca801c5fa15785b4902dcbd123cb4e95",
"assets/assets/fonts/Figtree-Regular.ttf": "7d889215a6a304a052a041e86ed6dacd",
"assets/assets/fonts/Figtree-SemiBold.ttf": "ed8cfbad3da01eaf9bc45442d9c62f86",
"assets/NOTICES": "d18fac89b646d50da1033fef18d8c494",
"assets/AssetManifest.bin": "3ba568e302eaea0cabae2c795dd3364e",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/FontManifest.json": "24d9e0aeb71c6fa37c07bc045a86500d",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "9b48f5ecc5a5b01fc676d638b119a3a1",
"index.html": "f4cab2212b8c26fda7739eb4d94b9cc5",
"/": "f4cab2212b8c26fda7739eb4d94b9cc5",
"version.json": "28dca64774bb4656e8b74e4c86a7df4f",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "1f2b11662e55118383a4aa578299d67c",
"main.dart.js": "ae2c2e6c097256036f8334bef023ae0b",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"panel.webmanifest": "b5646fc1659f2651e92d01d24a5ef8c2"};
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
