import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'csv_exporter.dart';

class WebCsvExporter implements CsvExporter {
  @override
  Future<void> exportCsv(String csvContent, String filename) async {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
      
    html.Url.revokeObjectUrl(url);
  }
}

CsvExporter getExporter() => WebCsvExporter();
