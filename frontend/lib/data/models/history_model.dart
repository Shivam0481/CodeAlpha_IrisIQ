class HistoryRecordModel {
  final int id;
  final double sepalLength;
  final double sepalWidth;
  final double petalLength;
  final double petalWidth;
  final String prediction;
  final double confidence;
  final String createdAt;

  HistoryRecordModel({
    required this.id,
    required this.sepalLength,
    required this.sepalWidth,
    required this.petalLength,
    required this.petalWidth,
    required this.prediction,
    required this.confidence,
    required this.createdAt,
  });

  factory HistoryRecordModel.fromJson(Map<String, dynamic> json) {
    return HistoryRecordModel(
      id: json['id'] as int,
      sepalLength: (json['sepal_length'] as num?)?.toDouble() ?? 0.0,
      sepalWidth: (json['sepal_width'] as num?)?.toDouble() ?? 0.0,
      petalLength: (json['petal_length'] as num?)?.toDouble() ?? 0.0,
      petalWidth: (json['petal_width'] as num?)?.toDouble() ?? 0.0,
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: json['created_at'] as String,
    );
  }

  // Converts a record to a CSV row for export features
  List<String> toCsvRow() {
    return [
      id.toString(),
      sepalLength.toString(),
      sepalWidth.toString(),
      petalLength.toString(),
      petalWidth.toString(),
      prediction,
      (confidence * 100).toStringAsFixed(1),
      createdAt,
    ];
  }

  static List<String> get csvHeader => [
        'ID',
        'Sepal Length (cm)',
        'Sepal Width (cm)',
        'Petal Length (cm)',
        'Petal Width (cm)',
        'Predicted Species',
        'Confidence (%)',
        'Timestamp'
      ];
}
