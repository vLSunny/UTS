import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

// ProfilPage
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(child: Text('Profil Page')),
    );
  }
}

// AdminBidManagementPage
class AdminBidManagementPage extends StatelessWidget {
  final BarangLelang barang;
  const AdminBidManagementPage({super.key, required this.barang});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pendingBids =
        barang.bidList.where((b) => b.status == BidStatus.pending).toList();
    final approvedBids =
        barang.bidList.where((b) => b.status == BidStatus.approved).toList();
    final rejectedBids =
        barang.bidList.where((b) => b.status == BidStatus.rejected).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Manage Bids for ${barang.nama}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (pendingBids.isEmpty) const Text('No pending bids.'),
            if (pendingBids.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: pendingBids.length,
                  itemBuilder: (context, index) {
                    final bid = pendingBids[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                            '${bid.bidderName} - Rp ${bid.amount.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                // Approve bid: mark item sold, add to buyer purchase, update bid status
                                appState.tandaiTerjual(barang,
                                    buyerName: bid.bidderName, bid: bid);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Bid approved and item sold to ${bid.bidderName}')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                appState.rejectBid(barang, bid);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (approvedBids.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Approved Bids:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...approvedBids.map((bid) => ListTile(
                        title: Text(
                            '${bid.bidderName} - Rp ${bid.amount.toStringAsFixed(2)}'),
                        leading: const Icon(Icons.check, color: Colors.green),
                      )),
                ],
              ),
            if (rejectedBids.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rejected Bids:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...rejectedBids.map((bid) => ListTile(
                        title: Text(
                            '${bid.bidderName} - Rp ${bid.amount.toStringAsFixed(2)}'),
                        leading: const Icon(Icons.close, color: Colors.red),
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// MapPage with Nearby Location Filtering
class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Marker> markers = [];
  List<Marker> placeMarkers = []; // Markers for places of worship
  LatLng? currentPosition;
  String currentMapStyle = 'OpenStreetMap';
  double nearbyRadius = 5000; // default radius in meters
  bool isLoading = false;
  Map<String, String> mapStyles = {
    'OpenStreetMap': 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'OpenTopoMap': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    'Stamen Toner':
        'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png',
  };

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _searchNearbyPlaces();
  }

  void _loadMarkers() {
    final barangList =
        Provider.of<AppState>(context, listen: false).barangLelang;
    markers = [];
    if (currentPosition == null) return;
    final Distance distance = Distance();
    for (var barang in barangList) {
      if (barang.latitude != null && barang.longitude != null) {
        final itemPos = LatLng(barang.latitude!, barang.longitude!);
        final dist = distance(currentPosition!, itemPos);
        if (dist <= nearbyRadius) {
          markers.add(
            Marker(
              width: 80,
              height: 80,
              point: itemPos,
              child: GestureDetector(
                onTap: () {
                  // Navigate to product details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(barang: barang),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        barang.nama,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    // Add nearby places markers
    for (var place in placeMarkers) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: place.point,
          child: Tooltip(
            message: 'Tempat Ibadah',
            child: const Icon(Icons.place, color: Colors.blue, size: 40),
          ),
        ),
      );
    }
  }

  void _addMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: point,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        _loadMarkers();
      });

      // Start real-time location updates
      _startLocationUpdates();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        _loadMarkers();
      });
    });
  }

  void _changeMapStyle(String style) {
    setState(() {
      currentMapStyle = style;
    });
  }

  void _startNavigation(LatLng destination) async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current position not available')),
      );
      return;
    }
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition!.latitude},${currentPosition!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch navigation')),
      );
    }
  }

  void _updateRadius(double value) {
    setState(() {
      nearbyRadius = value;
      _loadMarkers();
    });
  }

  Future<void> _searchNearbyPlaces() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi saat ini tidak tersedia')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      placeMarkers.clear();
    });

    try {
      final radius = (nearbyRadius / 1000).toStringAsFixed(1); // Convert to km
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search.php?q=tempat+ibadah'
          '&format=jsonv2'
          '&limit=10'
          '&lat=${currentPosition!.latitude}'
          '&lon=${currentPosition!.longitude}'
          '&radius=$radius'
          '&addressdetails=1');

      final response = await http.get(url, headers: {
        'User-Agent': 'EPelanggan/1.0', // Required by Nominatim
      });

      if (response.statusCode == 200) {
        final List<dynamic> places = json.decode(response.body);

        for (var place in places) {
          final lat = double.parse(place['lat']);
          final lon = double.parse(place['lon']);
          final name = place['display_name'] ?? 'Tempat Ibadah';

          placeMarkers.add(
            Marker(
              width: 80,
              height: 80,
              point: LatLng(lat, lon),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Detail Tempat Ibadah'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name),
                          const SizedBox(height: 8),
                          Text('Latitude: ${lat.toStringAsFixed(6)}'),
                          Text('Longitude: ${lon.toStringAsFixed(6)}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startNavigation(LatLng(lat, lon));
                          },
                          child: const Text('Navigasi'),
                        ),
                      ],
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Tempat Ibadah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.place_outlined,
                        color: Colors.purple, size: 40),
                  ],
                ),
              ),
            ),
          );
        }

        setState(() {
          markers = [...markers, ...placeMarkers];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta'),
        actions: [
          // Tombol cari tempat ibadah
          IconButton(
            icon: const Icon(Icons.church),
            onPressed: _searchNearbyPlaces,
            tooltip: 'Cari Tempat Ibadah Terdekat',
          ),
          PopupMenuButton<String>(
            onSelected: _changeMapStyle,
            itemBuilder: (context) {
              return mapStyles.keys
                  .map((style) => PopupMenuItem(
                        value: style,
                        child: Text(style),
                      ))
                  .toList();
            },
            icon: const Icon(Icons.map),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentPosition,
            tooltip: 'Current Location',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              final deviceInfo = 'Markers: ${markers.length}\n'
                  'Current Position: ${currentPosition?.latitude.toStringAsFixed(4) ?? 'N/A'}, '
                  '${currentPosition?.longitude.toStringAsFixed(4) ?? 'N/A'}\n'
                  'Radius: ${nearbyRadius.toStringAsFixed(0)} meters';
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Device Info'),
                  content: Text(deviceInfo),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    )
                  ],
                ),
              );
            },
            tooltip: 'Device Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Koordinat Lokasi Pengguna
          if (isLoading)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.deepPurple.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: Colors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi Anda:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      Text(
                        currentPosition != null
                            ? 'Lat: ${currentPosition!.latitude.toStringAsFixed(6)}'
                            : 'Lat: Mencari lokasi...',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        currentPosition != null
                            ? 'Lng: ${currentPosition!.longitude.toStringAsFixed(6)}'
                            : 'Lng: Mencari lokasi...',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentPosition != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'AKTIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Slider(
            value: nearbyRadius,
            min: 1000,
            max: 20000,
            divisions: 19,
            label: '${nearbyRadius.toStringAsFixed(0)} m',
            onChanged: _updateRadius,
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: currentPosition ??
                    (markers.isNotEmpty
                        ? markers[0].point
                        : LatLng(-6.200000, 106.816666)),
                zoom: 13.0,
                onTap: (tapPosition, latlng) {
                  _addMarker(latlng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: mapStyles[currentMapStyle]!,
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.epelangganx',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (markers.isNotEmpty) {
            _startNavigation(markers.last.point);
          }
        },
        tooltip: 'Start Navigation to Last Marker',
        child: const Icon(Icons.navigation),
      ),
    );
  }
}

// HistoriPage
class HistoriPage extends StatelessWidget {
  const HistoriPage({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final role = Provider.of<RoleProvider>(context).role;
    final userName = Provider.of<UserProfileProvider>(context).name;

    List<BarangLelang> itemsToShow;
    if (role == "admin") {
      // Admin sees all sold items
      itemsToShow = appState.histori;
    } else if (role == "buyer" && userName != null) {
      // Buyer sees only their purchased items
      itemsToShow = appState.pembelianUser(userName);
    } else {
      itemsToShow = [];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Histori')),
      body: itemsToShow.isEmpty
          ? const Center(child: Text('Belum ada histori transaksi.'))
          : ListView.builder(
              itemCount: itemsToShow.length,
              itemBuilder: (context, index) {
                final barang = itemsToShow[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(barang.nama),
                    subtitle: Text(barang.deskripsi),
                    trailing: Text('Rp ${barang.harga.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
    );
  }
}

// PickLocationPage
class PickLocationPage extends StatefulWidget {
  final LatLng initial;
  const PickLocationPage({super.key, required this.initial});
  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

// Product Detail Page
class ProductDetailPage extends StatelessWidget {
  final BarangLelang barang;

  const ProductDetailPage({super.key, required this.barang});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(barang.nama),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (barang.fotoPath != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(barang.fotoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Rp ${barang.harga.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              barang.deskripsi,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lokasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(barang.latitude!, barang.longitude!),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(barang.latitude!, barang.longitude!),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Provider.of<RoleProvider>(context).role == "buyer"
          ? FloatingActionButton.extended(
              onPressed: () async {
                final bidAmount = await showDialog<double>(
                  context: context,
                  builder: (_) => BidDialog(barang: barang),
                );
                if (bidAmount != null) {
                  final userName =
                      Provider.of<UserProfileProvider>(context, listen: false)
                          .name;
                  if (userName != null) {
                    final newBid = Bid(
                      bidderName: userName,
                      amount: bidAmount,
                      timestamp: DateTime.now(),
                    );
                    barang.bidList = List.from(barang.bidList)..add(newBid);
                    Provider.of<AppState>(context, listen: false)
                        .updateBarang();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Bid Rp ${bidAmount.toStringAsFixed(2)} dikirim!')),
                    );
                  }
                }
              },
              label: const Text('Bid Sekarang'),
              icon: const Icon(Icons.gavel),
            )
          : null,
    );
  }
}

// Bid Dialog
class BidDialog extends StatefulWidget {
  final BarangLelang barang;
  const BidDialog({super.key, required this.barang});

  @override
  State<BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<BidDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final text = _controller.text.replaceAll(',', '.');
    final amount = double.tryParse(text);
    if (amount == null) {
      setState(() => _errorText = 'Masukkan angka yang valid');
      return;
    }
    if (amount <= widget.barang.harga) {
      setState(() => _errorText = 'Bid harus lebih tinggi dari harga saat ini');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Masukkan Jumlah Bid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Harga Saat Ini: Rp ${widget.barang.harga.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Jumlah Bid (Rp)',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _validateAndSubmit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _validateAndSubmit,
          child: const Text('Bid'),
        ),
      ],
    );
  }
}

class _PickLocationPageState extends State<PickLocationPage> {
  late LatLng _pickedLocation;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initial;
  }

  void _handleTap(LatLng latlng) {
    setState(() {
      _pickedLocation = latlng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi Barang"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _pickedLocation);
            },
            child: const Text(
              "Simpan",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: _pickedLocation,
          zoom: 15.0,
          onTap: (tapPosition, latlng) {
            _handleTap(latlng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.epelangganx',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80,
                height: 80,
                point: _pickedLocation,
                child:
                    const Icon(Icons.location_on, color: Colors.blue, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
