# E-Pelelangan (E-Auction)

A modern mobile application for managing and participating in online auctions, built with Flutter.

## Description

E-Pelelangan is a comprehensive auction platform that connects buyers and administrators in a seamless digital marketplace. The application provides an intuitive interface for managing auctions, placing bids, and tracking auction history with location-based features.

## Application Screenshots

### User Authentication
| Role Selection | Login Screen |
|----------------|--------------|
| ![image](https://github.com/user-attachments/assets/ee6fce23-e063-4a27-8da5-8c35d30506b1) | ![image](https://github.com/user-attachments/assets/0425d171-ad59-413c-84ca-b05134ef4cfe) |

The application supports two user roles:
- **Admin**: For managing auctions and overseeing the platform
- **Pembeli (Buyer)**: For participating in auctions

### Main Features
| Home Screen | Map View | History |
|-------------|----------|----------|
| ![image](https://github.com/user-attachments/assets/eb4f4572-6f7b-4a16-8f0a-ed915b753a83) | ![image](https://github.com/user-attachments/assets/875e7545-d203-4467-b71f-deb284517671) | ![image](https://github.com/user-attachments/assets/8ac4c831-b9fc-4744-a894-b228046207b4) |

### More Features
| Add Auction Item | Bid Page |
|-----------------|--------------|
| ![image](https://github.com/user-attachments/assets/b9c044bf-859d-4cf4-a282-cfdb9011b35b) | ![image](https://github.com/user-attachments/assets/b5c62566-25a0-407f-a23d-487450972c01) |

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

### New Features Added
- Fetching real location data from external APIs such as Google Places API to display nearby places of worship.
- Integration of Google Maps using the `google_maps_flutter` package to display dynamic location pins on the map.
- Enhanced user experience with real-time location-based data visualization.

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
- `google_maps_flutter`: Google Maps integration for dynamic location pins
- HTTP client packages for API data fetching

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

## Technical Challenges and Solutions

### Challenges
- Integrating real-time location data from external APIs such as Google Places API.
- Managing API authentication and handling network requests efficiently.
- Displaying dynamic location pins on Google Maps within the Flutter application.
- Handling user permissions for location access across multiple platforms.
- Ensuring smooth performance and responsiveness with real-time data updates.

### Solutions
- Utilized the `google_maps_flutter` package for seamless Google Maps integration.
- Implemented HTTP client packages to fetch and parse data from Google Places API.
- Managed location permissions using the `permission_handler` package.
- Optimized state management to update map pins dynamically without performance degradation.
- Conducted thorough testing on multiple platforms to ensure consistent behavior.

## Contact

Instagram @Snnyrkh17_

---

*Note: Screenshots shown are from the actual application running on Android device. The app features a modern purple-themed design with intuitive navigation.*
