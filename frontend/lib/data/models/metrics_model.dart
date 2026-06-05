class MetricsSummaryModel {
  final int totalPredictions;
  final Map<String, int> speciesDistribution;
  final double averageConfidence;
  final DatasetInfoModel datasetInfo;
  final ModelMetricsModel metrics;

  MetricsSummaryModel({
    required this.totalPredictions,
    required this.speciesDistribution,
    required this.averageConfidence,
    required this.datasetInfo,
    required this.metrics,
  });

  factory MetricsSummaryModel.fromJson(Map<String, dynamic> json) {
    // Deserialize species distribution map safely
    final rawDist = json['species_distribution'] as Map<String, dynamic>? ?? {};
    final dist = rawDist.map((k, v) => MapEntry(k, v as int));

    return MetricsSummaryModel(
      totalPredictions: json['total_predictions'] as int? ?? 0,
      speciesDistribution: dist,
      averageConfidence: (json['average_confidence'] as num? ?? 0.0).toDouble(),
      datasetInfo: DatasetInfoModel.fromJson(json['dataset_info'] as Map<String, dynamic>),
      metrics: ModelMetricsModel.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }
}

class DatasetInfoModel {
  final String datasetName;
  final int datasetSize;
  final int featuresCount;
  final List<String> features;
  final int classesCount;
  final List<String> classes;

  DatasetInfoModel({
    required this.datasetName,
    required this.datasetSize,
    required this.featuresCount,
    required this.features,
    required this.classesCount,
    required this.classes,
  });

  factory DatasetInfoModel.fromJson(Map<String, dynamic> json) {
    return DatasetInfoModel(
      datasetName: json['dataset_name'] as String? ?? '',
      datasetSize: json['dataset_size'] as int? ?? 0,
      featuresCount: json['features_count'] as int? ?? 0,
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      classesCount: json['classes_count'] as int? ?? 0,
      classes: (json['classes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class ModelMetricsModel {
  final double trainAccuracy;
  final double testAccuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final List<double> precisionPerClass;
  final List<double> recallPerClass;
  final List<double> f1ScorePerClass;
  final List<List<int>> confusionMatrix;

  ModelMetricsModel({
    required this.trainAccuracy,
    required this.testAccuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.precisionPerClass,
    required this.recallPerClass,
    required this.f1ScorePerClass,
    required this.confusionMatrix,
  });

  factory ModelMetricsModel.fromJson(Map<String, dynamic> json) {
    final matrixRaw = json['confusion_matrix'] as List<dynamic>? ?? [];
    final matrix = matrixRaw.map((row) {
      return (row as List<dynamic>).map((e) => e as int).toList();
    }).toList();

    return ModelMetricsModel(
      trainAccuracy: (json['train_accuracy'] as num? ?? 0.0).toDouble(),
      testAccuracy: (json['test_accuracy'] as num? ?? 0.0).toDouble(),
      precision: (json['precision'] as num? ?? 0.0).toDouble(),
      recall: (json['recall'] as num? ?? 0.0).toDouble(),
      f1Score: (json['f1_score'] as num? ?? 0.0).toDouble(),
      precisionPerClass: (json['precision_per_class'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      recallPerClass: (json['recall_per_class'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      f1ScorePerClass: (json['f1_score_per_class'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      confusionMatrix: matrix,
    );
  }
}
