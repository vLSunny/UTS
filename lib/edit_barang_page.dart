import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'main.dart';
import 'pages.dart';

class EditBarangPage extends StatefulWidget {
  final BarangLelang? barang;
  const EditBarangPage({super.key, this.barang});

  @override
  _EditBarangPageState createState() => _EditBarangPageState();
}

class _EditBarangPageState extends State<EditBarangPage> {
  final _formKey = GlobalKey<FormState>();
  late String _nama;
  late double _harga;
  late double _hargaAwal;
  late int _jumlah;
  late String _deskripsi;
  String? _fotoPath;
  LatLng? _lokasi;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nama = widget.barang?.nama ?? '';
    _harga = widget.barang?.harga ?? 0.0;
    _hargaAwal = widget.barang?.hargaAwal ?? 0.0;
    _jumlah = widget.barang?.jumlah ?? 1;
    _deskripsi = widget.barang?.deskripsi ?? '';
    _fotoPath = widget.barang?.fotoPath;
    _lokasi = widget.barang != null &&
            widget.barang!.latitude != null &&
            widget.barang!.longitude != null
        ? LatLng(widget.barang!.latitude!, widget.barang!.longitude!)
        : null;
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _fotoPath = image.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() {
                    _fotoPath = photo.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Cari Gambar Online'),
              onTap: () async {
                Navigator.of(context).pop();
                final Uri url =
                    Uri.parse('https://www.google.com/search?tbm=isch');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tidak dapat membuka browser')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pilihLokasi() async {
    final LatLng initial = _lokasi ?? LatLng(-6.200000, 106.816666);
    final LatLng? selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickLocationPage(initial: initial),
      ),
    );
    if (selected != null) {
      setState(() {
        _lokasi = selected;
      });
    }
  }

  String _formatCurrency(double value) {
    // Format with thousand separators and 2 decimal places
    final formatted = value.toStringAsFixed(2);
    final parts = formatted.split('.');
    final wholePart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return '$wholePart.${parts[1]}';
  }

  double _parseFormattedNumber(String value) {
    // Remove thousand separators and parse
    return double.parse(value.replaceAll(',', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.barang == null ? 'Tambah Barang' : 'Edit Barang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _nama,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Nama barang harus diisi'
                    : null,
                onSaved: (value) => _nama = value ?? '',
              ),
              TextFormField(
                initialValue: _formatCurrency(_harga),
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga harus diisi';
                  }
                  final n = double.tryParse(value);
                  if (n == null) return 'Harga harus berupa angka';
                  return null;
                },
                onSaved: (value) =>
                    _harga = _parseFormattedNumber(value ?? '0'),
              ),
              TextFormField(
                initialValue: _formatCurrency(_hargaAwal),
                decoration: const InputDecoration(labelText: 'Harga Awal'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga Awal harus diisi';
                  }
                  final n = double.tryParse(value);
                  if (n == null) return 'Harga Awal harus berupa angka';
                  return null;
                },
                onSaved: (value) =>
                    _hargaAwal = _parseFormattedNumber(value ?? '0'),
              ),
              TextFormField(
                initialValue: _jumlah.toString(),
                decoration:
                    const InputDecoration(labelText: 'Jumlah Barang (max 10)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah barang harus diisi';
                  }
                  final n = int.tryParse(value);
                  if (n == null) return 'Jumlah barang harus berupa angka';
                  if (n < 1 || n > 10) {
                    return 'Jumlah barang harus antara 1 sampai 10';
                  }
                  return null;
                },
                onSaved: (value) => _jumlah = int.parse(value ?? '1'),
              ),
              TextFormField(
                initialValue: _deskripsi,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
                onSaved: (value) => _deskripsi = value ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _fotoPath != null
                      ? Image.file(
                          File(_fotoPath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(
                          width: 100, height: 100, child: Icon(Icons.image)),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Tambah Foto'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pilihLokasi,
                child: const Text('Pilih Lokasi di Peta'),
              ),
              if (_lokasi != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      'Lokasi terpilih: ${_lokasi!.latitude.toStringAsFixed(5)}, ${_lokasi!.longitude.toStringAsFixed(5)}'),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    if (widget.barang != null) {
                      // Update existing item
                      widget.barang!.nama = _nama;
                      widget.barang!.harga = _harga;
                      widget.barang!.hargaAwal = _hargaAwal;
                      widget.barang!.jumlah = _jumlah;
                      widget.barang!.deskripsi = _deskripsi;
                      widget.barang!.fotoPath = _fotoPath;
                      widget.barang!.latitude = _lokasi?.latitude;
                      widget.barang!.longitude = _lokasi?.longitude;
                      Provider.of<AppState>(context, listen: false)
                          .updateBarang();
                    } else {
                      // Create new item
                      final barang = BarangLelang(
                        nama: _nama,
                        harga: _harga,
                        hargaAwal: _hargaAwal,
                        jumlah: _jumlah,
                        deskripsi: _deskripsi,
                        fotoPath: _fotoPath,
                        latitude: _lokasi?.latitude,
                        longitude: _lokasi?.longitude,
                      );
                      Provider.of<AppState>(context, listen: false)
                          .tambahBarang(barang);
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
