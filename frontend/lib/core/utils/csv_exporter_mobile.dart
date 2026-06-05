import 'dart:io' show File, Platform;
import 'package:path_provider/path_provider.dart';
import 'csv_exporter.dart';

class MobileCsvExporter implements CsvExporter {
  @override
  Future<void> exportCsv(String csvContent, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsString(csvContent);
  }
}

CsvExporter getExporter() => MobileCsvExporter();
