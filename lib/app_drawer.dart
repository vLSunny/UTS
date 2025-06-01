import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'pages.dart';

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
    final role = Provider.of<RoleProvider>(context).role;
    return Drawer(
      width: 220,
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfilPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: userProfile.photoPath != null
                          ? FileImage(File(userProfile.photoPath!))
                          : null,
                      child: userProfile.photoPath == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.deepPurple)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userProfile.name ?? "Profil",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (role != null)
                            Text(
                              role == "admin" ? "Admin" : "Pembeli",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  "Jakarta, Indonesia",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
