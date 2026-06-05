import 'csv_exporter_stub.dart'
    if (dart.library.html) 'csv_exporter_web.dart'
    if (dart.library.io) 'csv_exporter_mobile.dart';

abstract class CsvExporter {
  Future<void> exportCsv(String csvContent, String filename);
  
  static CsvExporter get instance => getExporter();
}
