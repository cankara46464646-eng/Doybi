/// Konum: telefonun GPS'i, haritadan adres bulma (OpenStreetMap) ve mesafe.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LatLngPoint {
  final double lat;
  final double lng;
  const LatLngPoint(this.lat, this.lng);
}

/// Kahramanmaraş şehir merkezi.
const maras = LatLngPoint(37.5858, 36.9371);

/// Doybi'nin hizmet verdiği mahallelerin yaklaşık merkezleri (mesafe tahmini için).
const mahalleCenters = {
  'Yenişehir': LatLngPoint(37.5905, 36.9140),
  'Hayrullah': LatLngPoint(37.5830, 36.9300),
  'Kurtuluş': LatLngPoint(37.5760, 36.9330),
  'Mimar Sinan': LatLngPoint(37.5980, 36.9280),
  'Bağlarbaşı': LatLngPoint(37.5700, 36.9500),
  'Şazibey': LatLngPoint(37.5860, 36.9450),
};

const ilceler = ['Onikişubat', 'Dulkadiroğlu'];

/// Açık şehir ve oylamadaki şehirler (oy sayısı başlangıç değeri).
const openCity = 'Kahramanmaraş';
const voteCities = [
  ('Gaziantep', 100),
  ('Adana', 78),
  ('İstanbul', 71),
  ('Osmaniye', 54),
  ('Hatay', 47),
  ('Adıyaman', 39),
  ('Malatya', 31),
  ('Ankara', 28),
  ('İzmir', 22),
];

/// İki nokta arası mesafe (km).
double distanceKm(LatLngPoint a, LatLngPoint b) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

String kmText(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// En yakın hizmet mahallesi.
String nearestMahalle(LatLngPoint p) {
  String best = mahalleCenters.keys.first;
  var bestD = double.infinity;
  mahalleCenters.forEach((k, v) {
    final d = distanceKm(p, v);
    if (d < bestD) {
      bestD = d;
      best = k;
    }
  });
  return best;
}

/// Telefonun konumunu ister. Hata metni ya da konum döner.
Future<({LatLngPoint? point, String? error})> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (point: null, error: 'Telefonunun konum servisi kapalı. Ayarlardan açıp tekrar dene.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return (point: null, error: 'Konum izni verilmedi. İstersen adresi haritadan ya da elle seçebilirsin.');
    }
    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
    return (point: LatLngPoint(pos.latitude, pos.longitude), error: null);
  } catch (_) {
    return (point: null, error: 'Konum alınamadı. Haritadan seçmeyi dene.');
  }
}

class ReverseResult {
  final String? city; // il
  final String? ilce;
  final String? mahalle;
  final String? street;
  final String? building;
  final String display;
  const ReverseResult({this.city, this.ilce, this.mahalle, this.street, this.building, required this.display});

  bool get inMaras => (city ?? '').contains('Kahramanmaraş') || display.contains('Kahramanmaraş');
}

String _stripMah(String s) => s.replaceAll(RegExp(r'\s+(Mahallesi|Mah\.?)$', caseSensitive: false), '').trim();

/// Koordinattan adres (OpenStreetMap Nominatim).
Future<ReverseResult?> reverseGeocode(LatLngPoint p) async {
  try {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&accept-language=tr&zoom=18&lat=${p.lat}&lon=${p.lng}');
    final res = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final a = Map<String, dynamic>.from(j['address'] ?? const {});
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final mah = pick(['neighbourhood', 'suburb', 'quarter', 'village']);
    return ReverseResult(
      city: pick(['province', 'state', 'city']),
      ilce: pick(['town', 'city_district', 'district', 'county', 'municipality']),
      mahalle: mah == null ? null : _stripMah(mah),
      street: pick(['road', 'pedestrian', 'residential']),
      building: pick(['house_number']),
      display: (j['display_name'] ?? '') as String,
    );
  } catch (_) {
    return null;
  }
}

/// Bulunan mahalle Doybi'nin hizmet listesinde var mı? Varsa listedeki adı döner.
String? matchServedMahalle(String? name) {
  if (name == null) return null;
  String norm(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().replaceAll(' ', '');
  for (final m in mahalleCenters.keys) {
    if (norm(m) == norm(name)) return m;
  }
  return null;
}
