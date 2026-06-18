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

  static int? _toInt(dynamic v) {
    if (v == null || v == '') return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null || v == '') return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? _toStr(dynamic v) {
    if (v == null || v == '') return null;
    return v.toString();
  }

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: _toStr(json['brand']),
        year: _toInt(json['year']),
        horsepower: _toInt(json['horsepower']),
        engine: _toStr(json['engine']),
        mileage: _toInt(json['mileage']),
        owner: _toStr(json['owner']),
        location: _toStr(json['location']),
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
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

