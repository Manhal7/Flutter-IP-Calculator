# 🌐 Flutter IP Calculator

A powerful and modern IP address calculator built with Flutter, supporting both IPv4 and IPv6 calculations with a beautiful Material Design interface.


## ✨ Features

- **Dual Protocol Support**
  - 📱 IPv4 address calculations
  - 🚀 IPv6 address calculations
  - 🔄 Automatic protocol detection

- **Comprehensive Network Analysis**
  - 🔍 Network/Subnet calculations
  - 📊 CIDR notation support
  - 🎯 Host range determination
  - 🌐 Network class identification

- **IPv4 Specific Features**
  - 📝 Network, Broadcast, and Wildcard mask calculations
  - 🔢 Usable host range
  - 📌 RFC 1918 compliance checking
  - 🔄 Reverse DNS notation

- **IPv6 Specific Features**
  - 🔄 Address compression/expansion
  - 🎨 Scope identification
  - 🏷️ Interface ID extraction
  - 🌍 Global routing prefix detection

- **Modern UI Features**
  - 💎 Material Design 3
  - 📋 Copy to clipboard functionality
  - 💾 JSON export capability
  - 📱 Responsive layout
  - 🌙 Error handling with user feedback

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Manhal7/Flutter-IP-Calculator.git
```

2. Navigate to the project directory:
```bash
cd Flutter-IP-Calculator
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## 💻 Usage

1. **Enter IP Address**
   - Input any IPv4 or IPv6 address
   - The app automatically detects the IP version

2. **Specify Prefix Length**
   - Enter CIDR notation (e.g., 24 for IPv4 or 64 for IPv6)

3. **Calculate**
   - Press the calculate button
   - View comprehensive network information
   - Copy results or export as JSON

## 📸 Screenshots

Here are some screenshots of the IP Calculator app:

| Home Screen | IPv4 Calculation | IPv6 Calculation |
|-------------|-----------------|------------------|
| ![Home Screen](screenshots/home_screen.png) | ![IPv4 Calculation](screenshots/ipv4_calculation.png) | ![IPv6 Calculation](screenshots/ipv6_calculation.png) |

## 📥 Download

You can download the latest release of the IP Calculator app from the link below:

[Download IP Calculator APK](https://github.com/Manhal7/Flutter-IP-Calculator/releases/download/v1.0.0/IP.Calculator.apk)



### Example Inputs

#### IPv4
```
IP Address: 192.168.1.1
Prefix Length: 24
```

#### IPv6
```
IP Address: 2001:db8::1
Prefix Length: 64
```

## 🛠️ Technical Details

### Architecture
- Clean, modular Flutter architecture
- Separation of concerns between UI and calculation logic
- Extensive error handling and input validation

### Key Components
- `NetworkInfo` class for structured data representation
- Comprehensive IPv4 and IPv6 calculation engines
- Material Design widgets for modern UI

## 📝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Acknowledgments

- Flutter team for the amazing framework
- Material Design for the beautiful UI guidelines
- All contributors who help improve this project

## 📞 Contact

Your Name - [@manhal_77](https://twitter.com/manhal_77)

Project Link: [https://github.com/Manhal7/Flutter-IP-Calculator](https://github.com/Manhal7/flutter_ip_calculator)

---

Made with ❤️ using Flutter