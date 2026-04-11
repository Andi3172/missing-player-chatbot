import 'file_service.dart';

class PersistenceManager {
  static final FileService _fileService = FileService();
  
  static const List<String> _requiredFiles = [
    'identity.md',
    'sheet.md',
    'session_log.md',
  ];

  static const String _assetPrefix = 'assets/agent/';

  /// Initializes the local persistence layer by copying default assets to 
  /// the local document directory if they do not already exist.
  static Future<void> init() async {
    for (final fileName in _requiredFiles) {
      final exists = await _fileService.localFileExists(fileName);
      if (!exists) {
        String assetPath;
        if (fileName == 'identity.md') {
          assetPath = '${_assetPrefix}personality/identity.md';
        } else if (fileName == 'sheet.md') {
          assetPath = '${_assetPrefix}stats/sheet.md';
        } else {
          assetPath = '${_assetPrefix}lore/session_log.md';
        }

        try {
          final content = await _fileService.readAssetFile(assetPath);
          await _fileService.writeLocalFile(fileName, content);
          print('Copied $fileName from assets to local storage.');
        } catch (e) {
          print('Error initializing $fileName: $e');
        }
      }
    }
  }
}
