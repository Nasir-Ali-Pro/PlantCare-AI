class DiagnosisReport {
  final String id;
  final String
  source; // e.g. "On-Device AI", "Gemini Cloud AI", "Cloud Verified"
  final String plantName;
  final String diseaseName;
  final double confidence;
  final String severity; // Low, Moderate, High, Critical
  final String description;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;
  final String imagePath;
  final DateTime dateTime;

  final bool isOfflineResult;
  final bool needsVerification;
  final String? localCritiqueExplanation;

  DiagnosisReport({
    required this.id,
    required this.source,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.imagePath,
    required this.dateTime,
    this.isOfflineResult = false,
    this.needsVerification = false,
    this.localCritiqueExplanation,
  });

  DiagnosisReport copyWith({
    String? id,
    String? source,
    String? plantName,
    String? diseaseName,
    double? confidence,
    String? severity,
    String? description,
    List<String>? symptoms,
    List<String>? treatment,
    List<String>? prevention,
    String? imagePath,
    DateTime? dateTime,
    bool? isOfflineResult,
    bool? needsVerification,
    String? localCritiqueExplanation,
  }) {
    return DiagnosisReport(
      id: id ?? this.id,
      source: source ?? this.source,
      plantName: plantName ?? this.plantName,
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      treatment: treatment ?? this.treatment,
      prevention: prevention ?? this.prevention,
      imagePath: imagePath ?? this.imagePath,
      dateTime: dateTime ?? this.dateTime,
      isOfflineResult: isOfflineResult ?? this.isOfflineResult,
      needsVerification: needsVerification ?? this.needsVerification,
      localCritiqueExplanation: localCritiqueExplanation ?? this.localCritiqueExplanation,
    );
  }

  /// Factory constructor to generate an "Unrecognized / Unknown" placeholder report.
  factory DiagnosisReport.unrecognized({
    required String id,
    required String imagePath,
    String? message,
  }) {
    return DiagnosisReport(
      id: id,
      source: "On-Device Gatekeeper",
      plantName: "Unknown Species",
      diseaseName: "Unrecognized Item",
      confidence: 1.0,
      severity: "Low",
      description:
          message ??
          "Could not identify this item as one of the 14 supported PlantVillage crops. Please ensure the leaf is in focus and fills the frame.",
      symptoms: ["No plant disease symptoms could be determined."],
      treatment: [
        "Try scanning again in brighter lighting.",
        "Ensure a single leaf fills the frame.",
      ],
      prevention: [
        "Check your internet connection to enable Gemini Cloud fallback diagnostics.",
      ],
      imagePath: imagePath,
      dateTime: DateTime.now(),
      isOfflineResult: true,
      needsVerification: true,
    );
  }

  // ── JSON Serialization for History persistence ─────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'description': description,
      'symptoms': symptoms,
      'treatment': treatment,
      'prevention': prevention,
      'imagePath': imagePath,
      'dateTime': dateTime.toIso8601String(),
      'isOfflineResult': isOfflineResult,
      'needsVerification': needsVerification,
      'localCritiqueExplanation': localCritiqueExplanation,
    };
  }

  factory DiagnosisReport.fromJson(Map<String, dynamic> json) {
    return DiagnosisReport(
      id: json['id'] ?? '',
      source: json['source'] ?? '',
      plantName: json['plantName'] ?? '',
      diseaseName: json['diseaseName'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] ?? '',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      treatment: List<String>.from(json['treatment'] ?? []),
      prevention: List<String>.from(json['prevention'] ?? []),
      imagePath: json['imagePath'] ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
      isOfflineResult: json['isOfflineResult'] ?? false,
      needsVerification: json['needsVerification'] ?? false,
      localCritiqueExplanation: json['localCritiqueExplanation'],
    );
  }
}
