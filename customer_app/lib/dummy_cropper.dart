// Dummy implementation for web platform where image_cropper is not available
class CropAspectRatio {
  final double ratioX;
  final double ratioY;

  const CropAspectRatio({required this.ratioX, required this.ratioY});
}

class CropAspectRatioPreset {
  static const square = CropAspectRatio(ratioX: 1, ratioY: 1);
}

class AndroidUiSettings {
  final String? toolbarTitle;
  final dynamic toolbarColor;
  final dynamic toolbarWidgetColor;
  final CropAspectRatio? initAspectRatio;
  final bool lockAspectRatio;

  const AndroidUiSettings({
    this.toolbarTitle,
    this.toolbarColor,
    this.toolbarWidgetColor,
    this.initAspectRatio,
    this.lockAspectRatio = false,
  });
}

class IOSUiSettings {
  final String? title;
  final bool aspectRatioLockEnabled;

  const IOSUiSettings({
    this.title,
    this.aspectRatioLockEnabled = false,
  });
}

class CroppedFile {
  final String path;

  CroppedFile(this.path);
}

class ImageCropper {
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    CropAspectRatio? aspectRatio,
    List<dynamic>? uiSettings,
  }) async {
    // Return null for web - no cropping available
    return null;
  }
}
