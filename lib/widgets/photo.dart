import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Kamera ya da galeriden fotoğraf seçtirir, küçültüp telefona kaydeder ve kimliğini döner.
Future<String?> pickPhoto(BuildContext context, {String title = 'Fotoğraf ekle', bool allowRemove = false}) async {
  final s = AppScope.read(context);
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: display(22)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_camera_outlined, color: C.red),
            title: Text('Kamerayla çek', style: body(15, weight: FontWeight.w800)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_library_outlined, color: C.red),
            title: Text('Galeriden seç', style: body(15, weight: FontWeight.w800)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (allowRemove)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: C.muted),
              title: Text('Fotoğrafı kaldır', style: body(15, weight: FontWeight.w800, color: C.muted)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ]),
      ),
    ),
  );
  if (source == null) return null;
  if (source == 'remove') return '';
  try {
    final x = await ImagePicker().pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 72,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return await s.addPhoto(bytes);
  } catch (_) {
    if (context.mounted) snack(context, 'Fotoğraf alınamadı. Tekrar dene.');
    return null;
  }
}

/// Kayıtlı fotoğrafı gösterir; yoksa [placeholder].
class PhotoBox extends StatelessWidget {
  final String? id;
  final double? width;
  final double? height;
  final double radius;
  final Widget? placeholder;
  final BoxFit fit;
  const PhotoBox(this.id, {super.key, this.width, this.height, this.radius = 14, this.placeholder, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final bytes = AppScope.of(context).photo(id);
    if (bytes == null) return placeholder ?? SizedBox(width: width, height: height);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        cacheWidth: math.min(1000, ((width != null && width!.isFinite ? width! : MediaQuery.of(context).size.width) * dpr * 1.8).round()),
      ),
    );
  }
}

/// Tam ekran fotoğraf.
void showPhoto(BuildContext context, String id) {
  final bytes = AppScope.read(context).photo(id);
  if (bytes == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
      ),
    ),
  );
}

/// Tek fotoğraflık alan: önizleme + ekle/değiştir.
class PhotoField extends StatelessWidget {
  final String? id;
  final String label;
  final ValueChanged<String?> onChanged;
  final double height;
  final IconData icon;
  const PhotoField({super.key, required this.id, required this.label, required this.onChanged, this.height = 140, this.icon = Icons.photo_camera_outlined});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final has = s.photo(id) != null;
    return Material(
      color: C.line,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final r = await pickPhoto(context, title: label, allowRemove: has);
          if (r == null) return;
          if (r.isEmpty) {
            s.removePhoto(id);
            onChanged(null);
          } else {
            if (has) s.removePhoto(id);
            onChanged(r);
          }
        },
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: has
              ? Stack(fit: StackFit.expand, children: [
                  PhotoBox(id, radius: 18),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
                      child: Text('Değiştir', style: body(13, color: Colors.white, weight: FontWeight.w800)),
                    ),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: C.red, size: 30),
                  const SizedBox(height: 6),
                  Text(label, style: body(14, color: C.redDeep, weight: FontWeight.w800)),
                ]),
        ),
      ),
    );
  }
}

/// Birden çok fotoğraf: küçük resimler + ekle.
class PhotoStrip extends StatelessWidget {
  final List<String> ids;
  final String addLabel;
  final ValueChanged<String>? onAdd;
  final ValueChanged<String>? onRemove;
  final int max;
  const PhotoStrip({super.key, required this.ids, this.addLabel = 'Fotoğraf ekle', this.onAdd, this.onRemove, this.max = 4});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final id in ids)
        GestureDetector(
          onTap: () => showPhoto(context, id),
          child: Stack(children: [
            PhotoBox(id, width: 76, height: 76, radius: 12),
            if (onRemove != null)
              Positioned(
                right: 2,
                top: 2,
                child: InkWell(
                  onTap: () => onRemove!(id),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ]),
        ),
      if (onAdd != null && ids.length < max)
        Material(
          color: C.line,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final r = await pickPhoto(context, title: addLabel);
              if (r != null && r.isNotEmpty) onAdd!(r);
            },
            child: SizedBox(
              width: 76,
              height: 76,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_a_photo_outlined, color: C.red),
                Text('Ekle', style: body(12, color: C.redDeep, weight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

/// Telefonla arama.
Future<void> callPhone(BuildContext context, String? phone, {String who = 'Numara'}) async {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.length < 10 || (phone ?? '').contains('*')) {
    snack(context, '$who eklenmemiş.');
    return;
  }
  final ok = await launchUrl(Uri(scheme: 'tel', path: digits));
  if (!ok && context.mounted) snack(context, 'Arama başlatılamadı.');
}

/// Haritada göster / yol tarifi.
Future<void> openMap(BuildContext context, {String? query, double? lat, double? lng}) async {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  Uri uri;
  if (lat != null && lng != null) {
    uri = ios
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  } else {
    final q = Uri.encodeComponent('${query ?? ''}, Kahramanmaraş');
    uri = ios ? Uri.parse('https://maps.apple.com/?q=$q') : Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) snack(context, 'Harita açılamadı.');
}

Uint8List? photoBytes(BuildContext context, String? id) => AppScope.read(context).photo(id);
