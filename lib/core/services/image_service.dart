import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService(this._picker);

  final ImagePicker _picker;

  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery);

  Future<XFile?> takePhoto() => _picker.pickImage(source: ImageSource.camera);

  Future<Uint8List> readBytes(XFile image) => image.readAsBytes();
  Future<List<XFile>> pickMultipleFromGallery() =>
      _picker.pickMultiImage();
}
