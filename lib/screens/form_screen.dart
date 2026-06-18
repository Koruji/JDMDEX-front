import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/car.dart';
import '../services/api_service.dart';
import '../theme.dart';

class FormScreen extends StatefulWidget {
  final Car? car;
  final bool openCamera;

  const FormScreen({super.key, this.car, this.openCamera = false});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  static const int _maxPhotos = 5;

  double? _lat, _lng;
  final List<({Uint8List bytes, String name})> _newPhotos = [];
  bool _submitting = false;
  String? _geoStatus;

  int get _totalPhotos => (widget.car?.photos.length ?? 0) + _newPhotos.length;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) _fillFromCar(widget.car!);
    if (widget.openCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhoto(fromCamera: true));
    }
  }

  void _fillFromCar(Car car) {
    _nameCtrl.text = car.name;
    _brandCtrl.text = car.brand ?? '';
    _yearCtrl.text = car.year?.toString() ?? '';
    _hpCtrl.text = car.horsepower?.toString() ?? '';
    _engineCtrl.text = car.engine ?? '';
    _kmCtrl.text = car.mileage?.toString() ?? '';
    _ownerCtrl.text = car.owner ?? '';
    _locationCtrl.text = car.location ?? '';
    _lat = car.latitude;
    _lng = car.longitude;
  }

  Future<void> _pickPhoto({bool fromCamera = false}) async {
    if (_totalPhotos >= _maxPhotos) {
      _showError('Maximum $_maxPhotos photos par voiture');
      return;
    }

    final picker = ImagePicker();
    final file = fromCamera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _newPhotos.add((bytes: bytes, name: file.name)));
  }

  Future<void> _getLocation() async {
    setState(() => _geoStatus = 'Localisation…');
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        setState(() => _geoStatus = 'Accès refusé');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;

      try {
        final res = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json',
        ));
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        final loc = addr?['city'] ?? addr?['town'] ?? addr?['village'] ?? data['display_name'];
        _locationCtrl.text = loc as String? ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      } catch (_) {
        _locationCtrl.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }

      setState(() => _geoStatus = null);
    } catch (_) {
      setState(() => _geoStatus = 'Erreur de géolocalisation');
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Le nom du modèle est requis');
      return;
    }

    setState(() => _submitting = true);

    try {
      final year = int.tryParse(_yearCtrl.text);
      final hp = int.tryParse(_hpCtrl.text);
      final km = int.tryParse(_kmCtrl.text);

      if (widget.car != null) {
        await ApiService.updateCar(widget.car!.id, {
          'name': name,
          'brand': _brandCtrl.text,
          'year': year,
          'horsepower': hp,
          'engine': _engineCtrl.text,
          'mileage': km,
          'owner': _ownerCtrl.text,
          'location': _locationCtrl.text,
          'latitude': _lat,
          'longitude': _lng,
        });
        if (_newPhotos.isNotEmpty) {
          await ApiService.addPhotos(widget.car!.id, _newPhotos);
        }
      } else {
        await ApiService.createCar(
          name: name,
          brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
          year: year,
          horsepower: hp,
          engine: _engineCtrl.text.isEmpty ? null : _engineCtrl.text,
          mileage: km,
          owner: _ownerCtrl.text.isEmpty ? null : _ownerCtrl.text,
          location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
          latitude: _lat,
          longitude: _lng,
          photos: _newPhotos,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (_) {
      _showError('Erreur lors de l\'enregistrement');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _brandCtrl, _yearCtrl, _hpCtrl, _engineCtrl, _kmCtrl, _ownerCtrl, _locationCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.car != null;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isEdit),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoArea(),
                    const SizedBox(height: 20),
                    _buildRow([
                      _field('Marque', _brandCtrl, hint: 'Nissan'),
                      _field('Année', _yearCtrl, hint: '1999', type: TextInputType.number),
                    ]),
                    const SizedBox(height: 14),
                    _field('Modèle *', _nameCtrl, hint: 'Skyline GT-R R34'),
                    const SizedBox(height: 14),
                    _buildRow([
                      _field('Chevaux', _hpCtrl, hint: '280', type: TextInputType.number),
                      _field('Kilométrage', _kmCtrl, hint: '85 000', type: TextInputType.number),
                    ]),
                    const SizedBox(height: 14),
                    _field('Moteur', _engineCtrl, hint: 'RB26DETT 2.6L Twin-Turbo'),
                    const SizedBox(height: 20),
                    const Divider(color: kBorder),
                    const SizedBox(height: 16),
                    const Text('INFORMATIONS FACULTATIVES', style: TextStyle(color: kTextDim, fontSize: 11, letterSpacing: 2)),
                    const SizedBox(height: 14),
                    _field('Propriétaire', _ownerCtrl, hint: 'Nom du propriétaire'),
                    const SizedBox(height: 14),
                    _buildGeoSection(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                        child: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isEdit ? 'Enregistrer les modifications' : 'Ajouter à la collection'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kBgElevated, shape: BoxShape.circle, border: Border.all(color: kBorder)),
                child: const Icon(Icons.arrow_back_ios_new, size: 14, color: kText),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Modifier' : 'Nouvelle entrée',
              style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );

  Widget _buildPhotoArea() {
    final existingPhotos = widget.car?.photos ?? [];
    final canAdd = _totalPhotos < _maxPhotos;

    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...existingPhotos.map((p) => _photoThumb(
            child: Image.network('$kUploadsBase/${p.filename}', fit: BoxFit.cover),
          )),
          ..._newPhotos.map((p) => _photoThumb(
            child: Image.memory(p.bytes, fit: BoxFit.cover),
          )),
          if (canAdd)
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                width: 140,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: kBgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kTextMuted),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: kTextMuted, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      _totalPhotos == 0 ? 'Ajouter une photo' : '${_totalPhotos}/$_maxPhotos photos',
                      style: const TextStyle(color: kTextMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoThumb({required Widget child}) => Container(
        width: 140,
        height: 140,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        clipBehavior: Clip.hardEdge,
        child: child,
      );

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: kRed),
              title: const Text('Prendre une photo', style: TextStyle(color: kText)),
              onTap: () { Navigator.pop(context); _pickPhoto(fromCamera: true); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kRed),
              title: const Text('Galerie', style: TextStyle(color: kText)),
              onTap: () { Navigator.pop(context); _pickPhoto(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<Widget> children) => Row(
        children: children
            .map((w) => Expanded(child: w))
            .toList()
            .expand((w) => [w, const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? type}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(color: kBg, fontSize: 14),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );

  Widget _buildGeoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIEU DE LA PRISE DE PHOTO', style: TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _getLocation,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kCream),
                foregroundColor: kCream,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.location_on_outlined, size: 16),
              label: const Text('Utiliser ma position', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          if (_geoStatus != null) ...[
            const SizedBox(height: 6),
            Text(_geoStatus!, style: const TextStyle(color: kTextDim, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _locationCtrl,
            style: const TextStyle(color: kBg, fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Ex : Tokyo, Japon',
              prefixIcon: Icon(Icons.location_on, color: kRed, size: 16),
            ),
          ),
        ],
      );
}
