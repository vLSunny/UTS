import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permissions
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();

  // Initialize providers with stored data
  final appState = AppState();
  await appState.loadStoredData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appState),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: const EPelelanganApp(),
    ),
  );
}

// Role Provider
class RoleProvider with ChangeNotifier {
  String? _role; // "admin" or "buyer"
  String? get role => _role;
  void setRole(String? role) {
    _role = role;
    notifyListeners();
  }
}

// Theme Provider with SharedPreferences
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  ThemeProvider() {
    _loadTheme();
  }
  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// User Profile Provider
class UserProfileProvider with ChangeNotifier {
  String? _name;
  String? _photoPath;
  String? get name => _name;
  String? get photoPath => _photoPath;
  UserProfileProvider() {
    _loadProfile();
  }
  void setName(String name) async {
    _name = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  void setPhoto(String path) async {
    _photoPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhoto', path);
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('userName');
    _photoPath = prefs.getString('userPhoto');
    notifyListeners();
  }
}

// Bid Model
enum BidStatus { pending, approved, rejected }

class Bid {
  String bidderName;
  double amount;
  BidStatus status;
  final DateTime timestamp;

  Bid({
    required this.bidderName,
    required this.amount,
    this.status = BidStatus.pending,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Check if bid has expired (24 hours)
  bool get isExpired {
    return DateTime.now().difference(timestamp).inHours >= 24;
  }

  // Get remaining time until expiration
  Duration get timeRemaining {
    final expiration = timestamp.add(const Duration(hours: 24));
    final remaining = expiration.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'bidderName': bidderName,
      'amount': amount,
      'status': status.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      bidderName: json['bidderName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: BidStatus.values[json['status'] ?? 0],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }
}

// Barang Lelang Model
class BarangLelang {
  String nama;
  double harga;
  int jumlah;
  double hargaAwal;
  bool terjual;
  String? fotoPath;
  double? latitude;
  double? longitude;
  List<Bid> bidList;
  String deskripsi;

  BarangLelang({
    required this.nama,
    required this.harga,
    required this.jumlah,
    required this.hargaAwal,
    this.terjual = false,
    this.fotoPath,
    this.latitude,
    this.longitude,
    this.bidList = const [],
    required this.deskripsi,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'harga': harga,
      'jumlah': jumlah,
      'hargaAwal': hargaAwal,
      'terjual': terjual,
      'fotoPath': fotoPath,
      'latitude': latitude,
      'longitude': longitude,
      'bidList': bidList.map((bid) => bid.toJson()).toList(),
      'deskripsi': deskripsi,
    };
  }

  factory BarangLelang.fromJson(Map<String, dynamic> json) {
    return BarangLelang(
      nama: json['nama'] ?? '',
      harga: (json['harga'] ?? 0.0).toDouble(),
      jumlah: json['jumlah'] ?? 0,
      hargaAwal: (json['hargaAwal'] ?? 0.0).toDouble(),
      terjual: json['terjual'] ?? false,
      fotoPath: json['fotoPath'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      bidList: (json['bidList'] as List<dynamic>?)
              ?.map((b) => Bid.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      deskripsi: json['deskripsi'] ?? '',
    );
  }
}

// App State
class AppState with ChangeNotifier {
  List<BarangLelang> _barangLelang = [];
  List<BarangLelang> _histori = [];
  Map<String, List<BarangLelang>> _pembelianByUser = {};

  Future<void> loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load barang lelang data
      final barangData = prefs.getString('barangLelang');
      if (barangData != null) {
        final List<dynamic> decoded = jsonDecode(barangData);
        _barangLelang =
            decoded.map((item) => BarangLelang.fromJson(item)).toList();
      }

      // Load history data
      final historiData = prefs.getString('histori');
      if (historiData != null) {
        final List<dynamic> decoded = jsonDecode(historiData);
        _histori = decoded.map((item) => BarangLelang.fromJson(item)).toList();
      }

      // Load user purchases data
      final pembelianData = prefs.getString('pembelianByUser');
      if (pembelianData != null) {
        final Map<String, dynamic> decoded = jsonDecode(pembelianData);
        _pembelianByUser = decoded.map((key, value) {
          final List<dynamic> items = value;
          return MapEntry(
            key,
            items.map((item) => BarangLelang.fromJson(item)).toList(),
          );
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error loading stored data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save barang lelang data
      await prefs.setString('barangLelang',
          jsonEncode(_barangLelang.map((item) => item.toJson()).toList()));

      // Save history data
      await prefs.setString('histori',
          jsonEncode(_histori.map((item) => item.toJson()).toList()));

      // Save user purchases data
      final pembelianEncoded = jsonEncode(
        _pembelianByUser.map((key, value) => MapEntry(
              key,
              value.map((item) => item.toJson()).toList(),
            )),
      );
      await prefs.setString('pembelianByUser', pembelianEncoded);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  List<BarangLelang> get barangLelang =>
      _barangLelang.where((b) => !b.terjual).toList();
  List<BarangLelang> get histori => _histori;

  List<BarangLelang> pembelianUser(String userName) =>
      _pembelianByUser[userName] ?? [];

  void tambahBarang(BarangLelang barang) {
    _barangLelang.add(barang);
    notifyListeners();
    _saveData();
  }

  void tandaiTerjual(BarangLelang barang, {String? buyerName, Bid? bid}) {
    barang.terjual = true;
    _histori.add(barang);
    _barangLelang.remove(barang);
    if (buyerName != null) {
      _pembelianByUser.putIfAbsent(buyerName, () => []);
      _pembelianByUser[buyerName]!.add(barang);
    }
    if (bid != null) {
      // Update the bid status to approved
      final bidIndex = barang.bidList.indexWhere((b) => b == bid);
      if (bidIndex != -1) {
        barang.bidList[bidIndex].status = BidStatus.approved;
      }
    }
    notifyListeners();
  }

  void rejectBid(BarangLelang barang, Bid bid) {
    final bidIndex = barang.bidList.indexWhere((b) => b == bid);
    if (bidIndex != -1) {
      barang.bidList[bidIndex].status = BidStatus.rejected;
      notifyListeners();
    }
  }

  void hapusBarang(BarangLelang barang) {
    _barangLelang.remove(barang);
    notifyListeners();
    _saveData();
  }

  void updateBarang() => notifyListeners();
}

// Main App
class EPelelanganApp extends StatelessWidget {
  const EPelelanganApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'E-Pelelangan',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.purple.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: RolePickerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 1. ROLE PICKER PAGE (Admin/Pembeli)
class RolePickerPage extends StatelessWidget {
  const RolePickerPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Masuk Sebagai",
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
                const SizedBox(height: 32),
                SizedBox(
                  width: 220,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings, size: 28),
                    label: const Text("Admin", style: TextStyle(fontSize: 20)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage(role: "admin")),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person, size: 28),
                    label:
                        const Text("Pembeli", style: TextStyle(fontSize: 20)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage(role: "buyer")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 1.1 Halaman Login
class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.white
                                : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                      onSaved: (value) => _username = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.white
                                : Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                      onSaved: (value) => {}, // Password not stored or used
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            // Simulasi login
                            Provider.of<RoleProvider>(context, listen: false)
                                .setRole(widget.role);
                            Provider.of<UserProfileProvider>(context,
                                    listen: false)
                                .setName(_username); // Set username as ID
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => MainScaffold()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child:
                            const Text('Login', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 2. MAIN SCAFFOLD & NAVIGATION
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  static final List<Widget> _pages = [
    HomeItemsPage(),
    MapPage(),
    HistoriPage(),
  ];

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Prevent popping the route
    }
    return true; // Allow popping the route
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text("E-Pelelangan"),
          actions: [
            IconButton(
              icon: Icon(Provider.of<ThemeProvider>(context).themeMode ==
                      ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode),
              onPressed: () =>
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(),
            ),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurpleAccent.shade400,
          unselectedItemColor: Colors.black54,
          onTap: (idx) {
            setState(() => _selectedIndex = idx);
          },
          items: [
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? Colors.deepPurpleAccent.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Icon(Icons.home,
                    color: _selectedIndex == 0
                        ? Colors.deepPurpleAccent.shade700
                        : Colors.black54),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? Colors.deepPurpleAccent.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Icon(Icons.map,
                    color: _selectedIndex == 1
                        ? Colors.deepPurpleAccent.shade700
                        : Colors.black54),
              ),
              label: "Peta",
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  color: _selectedIndex == 2
                      ? Colors.deepPurpleAccent.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Icon(Icons.history,
                    color: _selectedIndex == 2
                        ? Colors.deepPurpleAccent.shade700
                        : Colors.black54),
              ),
              label: "History",
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButton: _selectedIndex == 0 &&
                Provider.of<RoleProvider>(context).role == "admin"
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LelangFormPage()));
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}

// 3. DRAWER (Modern, Profil di Atas)
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfileProvider>(context);
    return Drawer(
      width: 220,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ProfilPage())),
                  child: Container(
                    width: double.infinity,
                    height: 120, // Increased image height
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.deepPurple,
                          backgroundImage: userProfile.photoPath != null
                              ? FileImage(File(userProfile.photoPath!))
                              : null,
                          child: userProfile.photoPath == null
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            userProfile.name ?? "Profil",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ProfilPage())),
                  child: const Text("Edit Profil",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(context, Icons.home, "Home", 0),
                _drawerTile(context, Icons.map, "Peta", 1),
                _drawerTile(context, Icons.history, "History", 2),
                if (Provider.of<RoleProvider>(context).role == "admin")
                  _drawerTile(context, Icons.add_box, "Tambahkan Barang", 3),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.deepPurple),
            title: const Text("Logout", style: TextStyle(fontSize: 15)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Tidak"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                Provider.of<RoleProvider>(context, listen: false).setRole(null);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => RolePickerPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
      BuildContext context, IconData icon, String title, int idx) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = idx),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: Container(
        color: _hoveredIndex == idx
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: Colors.deepPurple),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          onTap: () {
            Navigator.pop(context);
            if (idx == 3) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => LelangFormPage()));
            } else {
              MainScaffold? main =
                  context.findAncestorWidgetOfExactType<MainScaffold>();
              if (main != null) {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => MainScaffold()));
              }
            }
          },
        ),
      ),
    );
  }
}

// 4. HOME ITEMS PAGE (Grid Card Kecil, Nama & Harga Bagus, Warna)
class HomeItemsPage extends StatelessWidget {
  const HomeItemsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final role = Provider.of<RoleProvider>(context).role;
    final userName = Provider.of<UserProfileProvider>(context).name;
    return Consumer<AppState>(
      builder: (context, appState, _) {
        var barangList = appState.barangLelang;
        if (barangList.isEmpty) {
          return const Center(child: Text('Belum ada barang yang dilelang.'));
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            itemCount: barangList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85, // Made taller for better photo display
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final barang = barangList[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.deepPurple.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.06),
                      offset: const Offset(2, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: barang.fotoPath != null
                            ? Image.file(File(barang.fotoPath!),
                                fit: BoxFit.cover)
                            : Container(
                                color: Colors.deepPurple.shade100,
                                child: const Icon(Icons.gavel,
                                    color: Colors.white, size: 36),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(
                        barang.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18), // Increased font size
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Text(
                        barang.deskripsi,
                        style: const TextStyle(
                            fontSize: 14), // Increased font size
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Text(
                        'Rp ${barang.harga.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 16), // Increased font size
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: role == "admin"
                          ? Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.deepPurple, size: 20),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditBarangPage(
                                                  barang: barang),
                                            ));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      onPressed: () {
                                        Provider.of<AppState>(context,
                                                listen: false)
                                            .hapusBarang(barang);
                                      },
                                    ),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          minimumSize: const Size(0, 28),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                        ),
                                        onPressed: () {
                                          Provider.of<AppState>(context,
                                                  listen: false)
                                              .tandaiTerjual(barang);
                                        },
                                        child: const Text('Jual',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      minimumSize: const Size(0, 32),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminBidManagementPage(
                                                  barang: barang),
                                        ),
                                      );
                                    },
                                    child: const Text('Manage Bids',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                minimumSize: const Size(double.infinity,
                                    36), // Increased button size
                              ),
                              onPressed: () async {
                                final bidAmount = await showDialog<double>(
                                  context: context,
                                  builder: (_) => BidDialog(barang: barang),
                                );
                                if (bidAmount != null && userName != null) {
                                  final newBid = Bid(
                                    bidderName: userName,
                                    amount: bidAmount,
                                  );
                                  barang.bidList = List.from(barang.bidList)
                                    ..add(newBid);
                                  Provider.of<AppState>(context, listen: false)
                                      .updateBarang();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Bid Rp ${bidAmount.toStringAsFixed(2)} dikirim!')),
                                  );
                                }
                              },
                              child: const Text('Bid',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// 5. DIALOG BID
class BidDialog extends StatefulWidget {
  final BarangLelang barang;
  const BidDialog({super.key, required this.barang});
  @override
  State<BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<BidDialog> {
  double? _bid;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Masukkan Bid Anda'),
      content: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Bid (Rp)'),
        onChanged: (val) => _bid = double.tryParse(val),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _bid),
          child: const Text('Bid'),
        ),
      ],
    );
  }
}

// 6. EDIT BARANG PAGE (Admin)
class EditBarangPage extends StatefulWidget {
  final BarangLelang barang;
  const EditBarangPage({super.key, required this.barang});
  @override
  State<EditBarangPage> createState() => _EditBarangPageState();
}

class _EditBarangPageState extends State<EditBarangPage> {
  final _formKey = GlobalKey<FormState>();
  late String _nama;
  late double _harga;
  late int _jumlah;
  late double _hargaAwal;
  late String _deskripsi;

  @override
  void initState() {
    super.initState();
    _nama = widget.barang.nama;
    _harga = widget.barang.harga;
    _jumlah = widget.barang.jumlah;
    _hargaAwal = widget.barang.hargaAwal;
    _deskripsi = widget.barang.deskripsi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _nama,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
                onSaved: (value) => _nama = value!,
              ),
              TextFormField(
                initialValue: _harga.toString(),
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
                onSaved: (value) => _harga = double.parse(value!),
              ),
              TextFormField(
                initialValue: _jumlah.toString(),
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
                onSaved: (value) => _jumlah = int.parse(value!),
              ),
              TextFormField(
                initialValue: _hargaAwal.toString(),
                decoration: const InputDecoration(labelText: 'Harga Awal'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
                onSaved: (value) => _hargaAwal = double.parse(value!),
              ),
              TextFormField(
                initialValue: _deskripsi,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi Barang'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
                onSaved: (value) => _deskripsi = value!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.barang.nama = _nama;
                    widget.barang.harga = _harga;
                    widget.barang.jumlah = _jumlah;
                    widget.barang.hargaAwal = _hargaAwal;
                    widget.barang.deskripsi = _deskripsi;
                    Provider.of<AppState>(context, listen: false)
                        .updateBarang();
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

// 7. FORM TAMBAH BARANG (Admin)
class LelangFormPage extends StatefulWidget {
  const LelangFormPage({super.key});
  @override
  State<LelangFormPage> createState() => _LelangFormPageState();
}

class _LelangFormPageState extends State<LelangFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _nama = '';
  double _harga = 0;
  int _jumlah = 1;
  double _hargaAwal = 0;
  String? _fotoPath;
  LatLng? _pickedLatLng;
  String _deskripsi = '';

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
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() {
                    _fotoPath = picked.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () async {
                Navigator.of(context).pop();
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() {
                    _fotoPath = picked.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Cari Gambar Online'),
              onTap: () async {
                Navigator.of(context).pop();
                final url = Uri.parse('https://www.google.com/search?tbm=isch');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation(BuildContext context) async {
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PickLocationPage(initial: LatLng(pos.latitude, pos.longitude)),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLatLng = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Barang Lelang')),
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Wajib diisi' : null,
                  onSaved: (value) => _nama = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Harga',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixText: 'Rp ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    final cleanValue = value.replaceAll(',', '');
                    final n = double.tryParse(cleanValue);
                    if (n == null) return 'Harga harus berupa angka';
                    return null;
                  },
                  onSaved: (value) =>
                      _harga = double.parse(value!.replaceAll(',', '')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Jumlah (maksimal 10)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    final n = int.tryParse(value);
                    if (n == null) return 'Jumlah harus berupa angka';
                    if (n < 1) return 'Jumlah minimal 1';
                    if (n > 10) return 'Jumlah maksimal 10';
                    return null;
                  },
                  onSaved: (value) => _jumlah = int.parse(value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Harga Awal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    prefixText: 'Rp ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    final cleanValue = value.replaceAll(',', '');
                    final n = double.tryParse(cleanValue);
                    if (n == null) return 'Harga Awal harus berupa angka';
                    return null;
                  },
                  onSaved: (value) =>
                      _hargaAwal = double.parse(value!.replaceAll(',', '')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Barang',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Wajib diisi' : null,
                  onSaved: (value) => _deskripsi = value!,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.deepPurple.shade50,
                  ),
                  child: _fotoPath != null
                      ? Image.file(File(_fotoPath!), fit: BoxFit.cover)
                      : const Center(
                          child: Text(
                            'No Image Selected',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text("Pilih Foto (Opsional)"),
                  onPressed: _pickImage,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: const Text("Pilih Lokasi di Peta"),
                      onPressed: () => _pickLocation(context),
                    ),
                    const SizedBox(width: 12),
                    if (_pickedLatLng != null)
                      Text(
                          "Lat: ${_pickedLatLng!.latitude.toStringAsFixed(4)}, Lng: ${_pickedLatLng!.longitude.toStringAsFixed(4)}"),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 300, // Enlarged map size
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      options: MapOptions(
                        center: _pickedLatLng ?? LatLng(-6.200000, 106.816666),
                        zoom: 13.0,
                        onTap: (_, latLng) {
                          setState(() {
                            _pickedLatLng = latLng;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        if (_pickedLatLng != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pickedLatLng!,
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_pickedLatLng == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Pilih lokasi barang di peta!")));
                        return;
                      }
                      _formKey.currentState!.save();
                      Provider.of<AppState>(context, listen: false)
                          .tambahBarang(
                        BarangLelang(
                          nama: _nama,
                          harga: _harga,
                          jumlah: _jumlah,
                          hargaAwal: _hargaAwal,
                          fotoPath: _fotoPath,
                          latitude: _pickedLatLng!.latitude,
                          longitude: _pickedLatLng!.longitude,
                          deskripsi: _deskripsi,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Tambah Barang'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
