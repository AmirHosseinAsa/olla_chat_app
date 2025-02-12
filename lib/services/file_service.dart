import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:excel/excel.dart' as excel;

class FileService {
  final Set<String> _allowedExtensions = {
    'json',
    'md',
    'txt',
    'cs',
    'js',
    'py',
    'java',
    'cpp',
    'css',
    'html',
    'xml',
    'yaml',
    'ini',
    'toml',
    'htm',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  };

  final Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
  };

  bool isImageFile(String extension) {
    return _imageExtensions.contains(extension.toLowerCase());
  }

  Future<List<PlatformFile>> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions.toList(),
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        return result.files.take(10).toList(); // Limit to 10 files
      }
    } catch (e) {
      print('Error picking files: $e');
    }
    return [];
  }

  Future<String?> readDocumentContent(PlatformFile file) async {
    try {
      final extension = file.extension?.toLowerCase() ?? '';

      switch (extension) {
        case 'pdf':
          final pdfFile = File(file.path!);
          final document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          final String text = extractor.extractText();
          document.dispose();
          return text;

        case 'doc':
        case 'docx':
          final bytes = await File(file.path!).readAsBytes();
          return docxToText(bytes);

        case 'xls':
        case 'xlsx':
          final bytes = await File(file.path!).readAsBytes();
          final ex = excel.Excel.decodeBytes(bytes);
          final buffer = StringBuffer();

          for (var table in ex.tables.keys) {
            buffer.writeln('Sheet: $table');
            for (var row in ex.tables[table]!.rows) {
              buffer.writeln(
                  row.map((cell) => cell?.value.toString() ?? '').join('\t'));
            }
            buffer.writeln();
          }
          return buffer.toString();

        case 'txt':
        case 'json':
        case 'md':
        case 'py':
        case 'js':
        case 'java':
        case 'cpp':
        case 'cs':
        case 'html':
        case 'css':
        case 'xml':
        case 'yaml':
        case 'ini':
        case 'toml':
        case 'htm':
          return await File(file.path!).readAsString();

        default:
          print('Unsupported file type: $extension');
          return null;
      }
    } catch (e) {
      print('Error reading file content: $e');
      return null;
    }
  }

  Future<String?> saveFile({
    required String suggestedName,
    List<String>? allowedExtensions,
  }) async {
    try {
      return await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: suggestedName,
        allowedExtensions: allowedExtensions,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
      );
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }
}
