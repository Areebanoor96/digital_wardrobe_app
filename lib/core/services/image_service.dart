import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
class ImageService {
  ImageService(this._picker);

  final ImagePicker _picker;

  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery);

  Future<XFile?> takePhoto() => _picker.pickImage(source: ImageSource.camera);

  Future<Uint8List> readBytes(XFile image) => image.readAsBytes();

  Future<List<XFile>> pickMultipleFromGallery({required int limit}) {
    return _picker.pickMultiImage(limit: limit);
  }
  Future<XFile?> pickImageFile() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>[
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
    );

    if (file == null) {
      return null;
    }

    final String? path = file.path;

    if (path == null || path.isEmpty) {
      return null;
    }

    return XFile(path);
  }
  Future<Uint8List> readAndCompressBytes(
      XFile image, {
        int quality = 80,
        int minWidth = 1600,
        int minHeight = 1600,
      }) async {
    final Uint8List originalBytes = await image.readAsBytes();


    if (originalBytes.lengthInBytes <= 500 * 1024) {
      return originalBytes;
    }

    final Uint8List compressedBytes =
    await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (compressedBytes.isEmpty) {
      return originalBytes;
    }

    return compressedBytes;
  }
}

