class BoundingBoxModel {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double w;
  final double h;

  BoundingBoxModel({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory BoundingBoxModel.fromJson(Map<String, dynamic> json) {
    return BoundingBoxModel(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
    );
  }
}

class PredictionModel {
  final int? id;
  final String? imageUrl;
  final String species;
  final double confidence;
  final List<ClassProbabilityModel> probabilities;
  final List<BoundingBoxModel> boundingBoxes;
  final String? scientificName;
  final String? botanicalFamily;
  final String? nativeHabitat;
  final String? floweringSeason;
  final String? detailedDescription;
  final List<String> characteristics;
  final String speciesKey;
  final String createdAt;

  PredictionModel({
    this.id,
    this.imageUrl,
    required this.species,
    required this.confidence,
    required this.probabilities,
    required this.boundingBoxes,
    this.scientificName,
    this.botanicalFamily,
    this.nativeHabitat,
    this.floweringSeason,
    this.detailedDescription,
    required this.characteristics,
    required this.speciesKey,
    required this.createdAt,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'] as int?,
      imageUrl: json['image_url'] as String?,
      species: json['species'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: (json['probabilities'] as List<dynamic>?)
              ?.map((e) => ClassProbabilityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      boundingBoxes: (json['bounding_boxes'] as List<dynamic>?)
              ?.map((e) => BoundingBoxModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scientificName: json['scientific_name'] as String?,
      botanicalFamily: json['botanical_family'] as String?,
      nativeHabitat: json['native_habitat'] as String?,
      floweringSeason: json['flowering_season'] as String?,
      detailedDescription: json['detailed_description'] as String?,
      characteristics: (json['characteristics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      speciesKey: json['species_key'] as String? ?? 'setosa',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ClassProbabilityModel {
  final String className;
  final double probability;

  ClassProbabilityModel({
    required this.className,
    required this.probability,
  });

  factory ClassProbabilityModel.fromJson(Map<String, dynamic> json) {
    return ClassProbabilityModel(
      className: json['class_name'] as String,
      probability: (json['probability'] as num).toDouble(),
    );
  }
}
