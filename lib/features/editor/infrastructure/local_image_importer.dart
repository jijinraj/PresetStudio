import 'package:file_picker/file_picker.dart';

class LocalImageImporter {
  const LocalImageImporter();

  Future<String?> pickImage() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (file == null) {
      return null;
    }

    return file.path;
  }
}
