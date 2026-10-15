import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  static const String currentVersion = '1.0.0+1';
  static const String configCollection = 'config';
  static const String appConfigDoc = 'app';

  /// Revisa la versión actual contra Firestore y muestra un diálogo obligatorio si está desactualizada.
  static Future<void> checkVersion(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance.collection(configCollection).doc(appConfigDoc).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final minVersion = data['minVersion'] as String?;
      final downloadUrl = data['downloadUrl'] as String?;

      if (minVersion != null && _isUpdateRequired(currentVersion, minVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, downloadUrl ?? 'https://drive.google.com/drive/folders/1ZgbLLREVEcngmXaPU8AR-_5VKW-aeYI7?usp=sharing');
        }
      }
    } catch (e) {
      debugPrint('Error al revisar versión: $e');
    }
  }

  static bool _isUpdateRequired(String current, String min) {
    final currentParts = current.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final minParts = min.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final m = i < minParts.length ? minParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    
    // Si la base es igual, chequear el build number
    final currentBuild = current.contains('+') ? int.tryParse(current.split('+')[1]) ?? 0 : 0;
    final minBuild = min.contains('+') ? int.tryParse(min.split('+')[1]) ?? 0 : 0;
    
    return currentBuild < minBuild;
  }

  static void _showUpdateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obligatorio
      builder: (context) => PopScope(
        canPop: false, // Prevenir back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.system_update_rounded, color: Color(0xFF2196F3)),
              SizedBox(width: 8),
              Text('Actualización Disponible'),
            ],
          ),
          content: const Text(
            'Hay una nueva versión del juego. Para continuar jugando debes descargar e instalar la nueva actualización desde Google Drive.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Descargar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
