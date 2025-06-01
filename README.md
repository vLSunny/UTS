# E-Pelelangan (E-Auction)

A modern mobile application for managing and participating in online auctions, built with Flutter.

## Description

E-Pelelangan is a comprehensive auction platform that connects buyers and administrators in a seamless digital marketplace. The application provides an intuitive interface for managing auctions, placing bids, and tracking auction history with location-based features.

## Application Screenshots

### User Authentication
| Role Selection | Login Screen |
|----------------|--------------|
| <img src="screenshots/role_selection.png" width="300"> | <img src="screenshots/login.png" width="300"> |

The application supports two user roles:
- **Admin**: For managing auctions and overseeing the platform
- **Pembeli (Buyer)**: For participating in auctions

### Main Features
| Home Screen | Map View | History |
|-------------|----------|----------|
| <img src="screenshots/home.png" width="300"> | <img src="screenshots/map.png" width="300"> | <img src="screenshots/history.png" width="300"> |

### Admin Features
| Add Auction Item | Profile Page |
|-----------------|--------------|
| <img src="screenshots/add_item.png" width="300"> | <img src="screenshots/profile.png" width="300"> |

## Features

### For Buyers
- Browse available auction items with detailed information
- Real-time bidding system with purple-themed UI
- View item locations on an interactive map (Jakarta area)
- Track bidding history with detailed transaction records
- Profile management
- Location-based item filtering

### For Administrators
- Complete auction item management
  - Add new items with details (Nama Barang, Harga, Jumlah, Harga Awal)
  - Add item descriptions and upload images
  - Set item location using interactive map
- Bid management and oversight
- User management system

### General Features
- Dual role system (Admin/Buyer)
- Secure authentication with username/password
- Interactive maps with Jakarta location services
- Image gallery for auction items
- Modern purple-themed UI design
- Bottom navigation with Home, Map (Peta), and History tabs
- Dark/Light theme support

## Technical Specifications

### Built With
- Flutter SDK
- Dart programming language

### Key Dependencies
- `flutter_map` & `latlong2`: Interactive mapping functionality
- `geolocator`: GPS and location services
- `carousel_slider`: Image gallery display
- `provider`: State management
- `image_picker`: Image upload capability
- `shared_preferences`: Local data storage
- `permission_handler`: Device permission management
- `google_fonts`: Custom typography
- `url_launcher`: External link handling

### Platform Support
- Android ✅
- iOS ✅
- Web ✅
- Windows ✅
- macOS ✅
- Linux ✅

## Getting Started

### Prerequisites
- Flutter (SDK >=2.17.0 <3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile deployment)

### Installation

1. Clone the repository
```bash
git clone [repository-url]
cd e_pelelangan
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the application
```bash
flutter run
```

### Project Structure
```
lib/
├── main.dart              # Main application entry point
├── pages.dart             # All page implementations
├── app_drawer.dart        # Navigation drawer
└── edit_barang_page.dart  # Item editing functionality
```

## App Navigation

The application features a bottom navigation bar with three main sections:
- **Home**: Browse and bid on auction items
- **Peta (Map)**: View item locations on interactive map
- **History**: Track your bidding history

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is proprietary software. All rights reserved.

## Contact

For any inquiries about this project, please contact the development team.

---

*Note: Screenshots shown are from the actual application running on Android device. The app features a modern purple-themed design with intuitive navigation.*
