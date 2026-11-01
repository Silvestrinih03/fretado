import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/avatar_image.dart';

enum AvatarSource { gallery, camera }

abstract class AvatarImagePicker {
  bool get supportsCamera;
  Future<AvatarImage?> pick(AvatarSource source);
  Future<AvatarImage?> recoverLostImage();
}

class DeviceAvatarImagePicker implements AvatarImagePicker {
  final ImagePicker _picker;
  DeviceAvatarImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  bool get supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<AvatarImage> _read(XFile file) async {
    if (await file.length() > maxAvatarBytes) {
      throw const AvatarSelectionException('A foto deve ter no máximo 5 MB.');
    }
    return AvatarImage.fromBytes(await file.readAsBytes());
  }

  @override
  Future<AvatarImage?> pick(AvatarSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == AvatarSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        requestFullMetadata: false,
      );
      return file == null ? null : await _read(file);
    } on PlatformException catch (error) {
      throw AvatarSelectionException(_platformMessage(error.code));
    }
  }

  @override
  Future<AvatarImage?> recoverLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      if (response.exception != null) {
        throw AvatarSelectionException(
          _platformMessage(response.exception!.code),
        );
      }
      final files = response.files;
      return files == null || files.isEmpty ? null : await _read(files.first);
    } on PlatformException catch (error) {
      throw AvatarSelectionException(_platformMessage(error.code));
    }
  }

  String _platformMessage(String code) => switch (code) {
    'camera_access_denied' ||
    'camera_access_restricted' ||
    'photo_access_denied' ||
    'photo_access_restricted' =>
      'Permita o acesso à câmera ou às fotos nas configurações do dispositivo.',
    'no_available_camera' =>
      'Não foi possível acessar a câmera. Escolha uma foto da galeria.',
    _ => 'Não foi possível selecionar a foto. Tente novamente.',
  };
}
