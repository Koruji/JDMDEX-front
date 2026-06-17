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

  double? _lat, _lng;
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoPreviewUrl;
  bool _submitting = false;
  String? _aiLabel;
  String? _geoStatus;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) _fillFromCar(widget.car!);
    if (widget.openCamera) WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhoto(fromCamera: true));
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
    final p = car.primaryPhotoOrNull;
    if (p != null) _photoPreviewUrl = '$kUploadsBase/${p.filename}';
  }

  void _fillFromAI(RecognizeResult r) {
    _brandCtrl.text = r.brand;
    _nameCtrl.text = r.name;
    if (r.year != null) _yearCtrl.text = r.year.toString();
    if (r.horsepower != null) _hpCtrl.text = r.horsepower.toString();
    if (r.engine != null) _engineCtrl.text = r.engine!;
    setState(() => _aiLabel = '${r.brand} ${r.name} — ${r.confidence}% confiance');
  }

  Future<void> _pickPhoto({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final file = fromCamera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoName = file.name;
      _photoPreviewUrl = null;
      _aiLabel = null;
    });

    // Recognize
    try {
      final result = await ApiService.recognize(bytes, file.name);
      if (mounted) _fillFromAI(result);
    } catch (_) {}
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
        if (_photoBytes != null) {
          await ApiService.addPhotos(widget.car!.id, [(bytes: _photoBytes!, name: _photoName ?? 'photo.jpg')]);
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
          photoBytes: _photoBytes,
          photoName: _photoName,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
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
            Text(isEdit ? 'Modifier' : 'Nouvelle entrée',
                style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _buildPhotoArea() {
    final hasPhoto = _photoBytes != null || _photoPreviewUrl != null;
    return GestureDetector(
      onTap: () => _showPhotoOptions(),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: kBgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasPhoto ? kBorder : kTextMuted, style: hasPhoto ? BorderStyle.solid : BorderStyle.solid),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_photoBytes != null)
              Image.memory(_photoBytes!, fit: BoxFit.cover)
            else if (_photoPreviewUrl != null)
              Image.network(_photoPreviewUrl!, fit: BoxFit.cover)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: kTextMuted, size: 36),
                  const SizedBox(height: 8),
                  const Text('Ajouter une photo', style: TextStyle(color: kTextDim, fontSize: 12)),
                ],
              ),
            if (_aiLabel != null)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.15),
                    border: Border.all(color: kGreen),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_aiLabel!, style: const TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
        children: children.map((w) => Expanded(child: w)).toList().expand((w) => [w, const SizedBox(width: 10)]).toList()..removeLast(),
      );

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? type}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: kTextDim, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(color: kText, fontSize: 14),
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
                side: const BorderSide(color: kGreen),
                foregroundColor: kGreen,
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
          if (_locationCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              style: const TextStyle(color: kGreen, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Lieu',
                prefixIcon: Icon(Icons.location_on, color: kGreen, size: 16),
              ),
              onChanged: (v) => _locationCtrl.text = v,
            ),
          ],
        ],
      );
}
