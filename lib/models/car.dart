class Photo {
  final int id;
  final int carId;
  final String filename;
  final bool isPrimary;

  const Photo({
    required this.id,
    required this.carId,
    required this.filename,
    required this.isPrimary,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as int,
        carId: json['car_id'] as int,
        filename: json['filename'] as String,
        isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
      );
}

class Car {
  final int id;
  final String name;
  final String? brand;
  final int? year;
  final int? horsepower;
  final String? engine;
  final int? mileage;
  final String? owner;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<Photo> photos;
  final String createdAt;

  const Car({
    required this.id,
    required this.name,
    this.brand,
    this.year,
    this.horsepower,
    this.engine,
    this.mileage,
    this.owner,
    this.location,
    this.latitude,
    this.longitude,
    this.photos = const [],
    required this.createdAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        year: json['year'] as int?,
        horsepower: json['horsepower'] as int?,
        engine: json['engine'] as String?,
        mileage: json['mileage'] as int?,
        owner: json['owner'] as String?,
        location: json['location'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((p) => Photo.fromJson(p as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at'] as String? ?? '',
      );

  Photo? get primaryPhoto =>
      photos.firstWhere((p) => p.isPrimary, orElse: () => photos.isNotEmpty ? photos.first : throw StateError(''));

  Photo? get primaryPhotoOrNull {
    try {
      return primaryPhoto;
    } catch (_) {
      return null;
    }
  }
}

class RecognizeResult {
  final String brand;
  final String name;
  final int? year;
  final int? horsepower;
  final String? engine;
  final int confidence;

  const RecognizeResult({
    required this.brand,
    required this.name,
    this.year,
    this.horsepower,
    this.engine,
    required this.confidence,
  });

  factory RecognizeResult.fromJson(Map<String, dynamic> json) => RecognizeResult(
        brand: json['brand'] as String,
        name: json['name'] as String,
        year: json['year'] as int?,
        horsepower: json['horsepower'] as int?,
        engine: json['engine'] as String?,
        confidence: json['confidence'] as int,
      );
}
