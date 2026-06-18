import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/car.dart';
import '../theme.dart';

class ApiService {
  static const _base = kApiBase;

  static Future<List<Car>> getCars() async {
    final res = await http.get(Uri.parse('$_base/cars'));
    _check(res);
    return (jsonDecode(res.body) as List<dynamic>)
        .map((j) => Car.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Car> getCar(int id) async {
    final res = await http.get(Uri.parse('$_base/cars/$id'));
    _check(res);
    return Car.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Car> createCar({
    required String name,
    String? brand,
    int? year,
    int? horsepower,
    String? engine,
    int? mileage,
    String? owner,
    String? location,
    double? latitude,
    double? longitude,
    List<({Uint8List bytes, String name})> photos = const [],
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/cars'));
    req.fields['name'] = name;
    if (brand != null) req.fields['brand'] = brand;
    if (year != null) req.fields['year'] = year.toString();
    if (horsepower != null) req.fields['horsepower'] = horsepower.toString();
    if (engine != null) req.fields['engine'] = engine;
    if (mileage != null) req.fields['mileage'] = mileage.toString();
    if (owner != null) req.fields['owner'] = owner;
    if (location != null) req.fields['location'] = location;
    if (latitude != null) req.fields['latitude'] = latitude.toString();
    if (longitude != null) req.fields['longitude'] = longitude.toString();
    for (final p in photos) {
      req.files.add(http.MultipartFile.fromBytes('photos', p.bytes, filename: p.name));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _check(res);
    return Car.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Car> updateCar(int id, Map<String, dynamic> fields) async {
    final res = await http.put(
      Uri.parse('$_base/cars/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );
    _check(res);
    return Car.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deleteCar(int id) async {
    final res = await http.delete(Uri.parse('$_base/cars/$id'));
    if (res.statusCode != 204) throw Exception('Delete failed');
  }

  static Future<Car> addPhotos(int carId, List<({Uint8List bytes, String name})> photos) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/cars/$carId/photos'));
    for (final p in photos) {
      req.files.add(http.MultipartFile.fromBytes('photos', p.bytes, filename: p.name));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _check(res);
    return Car.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deletePhoto(int carId, int photoId) async {
    final res = await http.delete(Uri.parse('$_base/cars/$carId/photos/$photoId'));
    if (res.statusCode != 204) throw Exception('Delete photo failed');
  }

  static void _check(http.Response res) {
    if (res.statusCode >= 400) throw Exception('API ${res.statusCode}: ${res.body}');
  }
}
