# Binder

Binder is a high-fidelity document scanning application built with Flutter, designed to offer a premium, native-feeling experience for iOS users. By combining "Liquid Glass" visual effects with robust hardware integration, Binder allows users to digitize documents while tracking critical information like expiration dates and warranties.

---

## 📱 Features

### **Liquid Glass Navigation**
The application features a custom-built, floating navigation bar that utilizes modern iOS design principles.
* **Glassmorphism:** Uses `BackdropFilter` with high-sigma blurring to create a translucent "glass" effect that interacts with background content.
* **Fluid Transitions:** Features a sliding selection pill powered by `AnimatedPositioned` and `Cubic` easing curves to mimic native system physics.
* **SF Symbols:** Integrated with `CupertinoIcons` to maintain visual consistency with the Apple ecosystem.

### **Native Document Scanning**
A fully integrated camera experience designed for high-speed document capture.
* **In-App Preview:** Utilizes the `camera` package to provide a live viewfinder directly within the application UI.
* **Permission Management:** Configured for secure access to iOS camera and microphone hardware.
* **Simulator Support:** Includes error-trapping logic to detect hardware availability and prevent crashes on virtual devices.

---

## 📂 Project Structure

The application is architected around three core views:

* **Home Dashboard:** Features a "Welcome" interface and a Bento-style grid. It prioritizes time-sensitive documents in an "Expires Soon" section.
* **Scan Interface:** A focused camera environment with dedicated capture controls and immediate save functionality.
* **Document Browser:** A central repository for viewing and managing saved scans and metadata.

---

## 🚀 Getting Started

### **Prerequisites**
* Flutter SDK (Latest Stable)
* Xcode 15+ (for iOS deployment)
* CocoaPods

### **Installation**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/binder.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure iOS Signing:**
   * Open `ios/Runner.xcworkspace` in Xcode.
   * Under **Target > Runner > Signing & Capabilities**, select your development team and provide a unique Bundle Identifier.

4. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev)
* **Language:** [Dart](https://dart.dev)
* **Icons:** [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
* **Hardware:** [Camera Plugin](https://pub.dev/packages/camera)

---

## 📄 License

This project is for educational purposes. All design assets were prototyped in Figma to align with modern mobile UI standards.
