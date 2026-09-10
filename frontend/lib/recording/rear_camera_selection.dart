import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Back cameras in order for finger PPG: prefer main [CameraLensType.wide], then others.
List<CameraDescription> orderedBackCamerasForPpg(List<CameraDescription> all) {
  final back =
      all.where((c) => c.lensDirection == CameraLensDirection.back).toList();
  if (back.isEmpty) return [];

  final ordered = <CameraDescription>[];

  for (final c in back) {
    if (c.lensType == CameraLensType.wide) {
      ordered.add(c);
    }
  }

  for (final c in back) {
    if (c.lensType == CameraLensType.ultraWide ||
        c.lensType == CameraLensType.telephoto) {
      continue;
    }
    if (!ordered.contains(c)) ordered.add(c);
  }

  for (final c in back) {
    if (!ordered.contains(c)) ordered.add(c);
  }

  if (ordered.isNotEmpty) {
    final first = ordered.first;
    debugPrint(
      'PPG camera order: ${ordered.map((c) => "${c.name}/${c.lensType}").join(", ")}; '
      'using ${first.name}/${first.lensType} first',
    );
  }

  return ordered;
}

/// Index of [preferredName] in [cameras], or 0 if missing / empty name.
int preferredPpgCameraIndex(
  List<CameraDescription> cameras, {
  String? preferredName,
}) {
  if (cameras.isEmpty) return 0;
  final name = preferredName;
  if (name == null || name.isEmpty) return 0;
  final index = cameras.indexWhere((c) => c.name == name);
  if (index >= 0) {
    debugPrint('PPG preferred camera: $name at index $index');
    return index;
  }
  debugPrint('PPG preferred camera not found ($name); using index 0');
  return 0;
}
