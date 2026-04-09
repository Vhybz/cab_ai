class Prediction {
  final String diseaseName;
  final double confidence;
  final String description;
  final String treatment;
  final String imagePath;
  final DateTime dateTime;

  Prediction({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.treatment,
    required this.imagePath,
    required this.dateTime,
  });

  // Convert a Prediction into a Map. The keys must correspond to the names of the
  // columns in the database or keys in JSON.
  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'description': description,
      'treatment': treatment,
      'imagePath': imagePath,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Convert a Map into a Prediction.
  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      diseaseName: map['diseaseName'],
      confidence: map['confidence'],
      description: map['description'],
      treatment: map['treatment'],
      imagePath: map['imagePath'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
