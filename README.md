# TwelveStars 🌟

A beautifully designed, premium Flutter application to count and shine stars.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **CI/CD / Verification**: Flutter test suite (Unit, Widget, and Golden/Screenshot tests)

---

## 💻 Local Development Setup

To run the application locally, make sure you have the Flutter SDK installed and then execute:

1. **Install Dependencies & Assemble Database**:
   ```bash
   cd app
   flutter pub get
   dart run bin/assemble_db.dart
   ```

2. **Run All Tests**:
   ```bash
   cd app
   flutter test
   ```

3. **Update Golden Screenshot Tests**:
   ```bash
   cd app
   flutter test --update-goldens
   ```

4. **Launch the App**:
   ```bash
   cd app
   flutter run
   ```

5. **Generate App Launcher Icons**:
   When raw assets in `assets/` are updated, regenerate icons across Android, iOS, and Web:
   ```bash
   ./bin/generate_icons.sh
   ```
   To verify that generated icons match checked-in icons without making changes:
   ```bash
   ./bin/generate_icons.sh --check
   ```
