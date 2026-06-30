// Gestion des photos de machines, stockées LOCALEMENT sur l'appareil.
// Seul le nom de fichier est sauvegardé dans le state (et synchronisé) ;
// les octets de l'image restent sur le téléphone (même gym, photo 1×).

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MachinePhotos {
  MachinePhotos._();
  static final MachinePhotos instance = MachinePhotos._();

  final ImagePicker _picker = ImagePicker();
  Directory? _dir;

  /// Dossier dédié aux photos de machines (créé si absent).
  Future<Directory> _photosDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/machine_photos');
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    _dir = d;
    return d;
  }

  /// Chemin absolu d'une photo à partir de son nom de fichier.
  /// Sur le Web (preview), le stockage fichier n'existe pas -> null.
  Future<String?> pathFor(String filename) async {
    if (filename.isEmpty || kIsWeb) return null;
    final d = await _photosDir();
    final p = '${d.path}/$filename';
    return await File(p).exists() ? p : null;
  }

  /// Prend une photo (caméra ou galerie), la copie dans le dossier de l'app,
  /// et retourne le nom de fichier généré. Null si annulé/erreur.
  Future<String?> capture(String exerciseId,
      {required bool fromCamera}) async {
    // Le stockage fichier local n'est pas dispo sur le Web (preview).
    if (kIsWeb) return null;
    try {
      final XFile? picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (picked == null) return null;

      final d = await _photosDir();
      final ext = _ext(picked.path);
      final filename =
          'm_${exerciseId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = File('${d.path}/$filename');
      await File(picked.path).copy(dest.path);
      return filename;
    } catch (e) {
      debugPrint('MachinePhotos: capture failed ($e)');
      return null;
    }
  }

  /// Supprime le fichier image local (best-effort).
  Future<void> delete(String filename) async {
    if (filename.isEmpty) return;
    try {
      final d = await _photosDir();
      final f = File('${d.path}/$filename');
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('MachinePhotos: delete failed ($e)');
    }
  }

  String _ext(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return '.jpg';
    final e = path.substring(i).toLowerCase();
    return (e == '.png' || e == '.jpeg' || e == '.jpg') ? e : '.jpg';
  }
}
