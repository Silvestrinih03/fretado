import 'dart:typed_data';

const maxAvatarBytes = 5 * 1024 * 1024;

class AvatarImage {
  final Uint8List bytes;
  final String filename;
  final String contentType;

  const AvatarImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  factory AvatarImage.fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const AvatarSelectionException('Selecione uma imagem não vazia.');
    }
    if (bytes.length > maxAvatarBytes) {
      throw const AvatarSelectionException('A foto deve ter no máximo 5 MB.');
    }
    final String extension;
    final String mime;
    bool startsWith(List<int> signature) =>
        bytes.length >= signature.length &&
        List.generate(
          signature.length,
          (i) => bytes[i] == signature[i],
        ).every((v) => v);
    if (startsWith([0xff, 0xd8, 0xff])) {
      extension = 'jpg';
      mime = 'image/jpeg';
    } else if (startsWith([137, 80, 78, 71, 13, 10, 26, 10])) {
      extension = 'png';
      mime = 'image/png';
    } else if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      extension = 'webp';
      mime = 'image/webp';
    } else {
      throw const AvatarSelectionException('Use uma imagem JPEG, PNG ou WebP.');
    }
    return AvatarImage(
      bytes: bytes,
      filename: 'avatar.$extension',
      contentType: mime,
    );
  }
}

class AvatarSelectionException implements Exception {
  final String message;
  const AvatarSelectionException(this.message);
  @override
  String toString() => message;
}
