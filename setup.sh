#!/usr/bin/env bash
# One-time setup: generates the Android platform folder, installs packages,
# creates launcher icons and runs the formula tests.
set -e
flutter create --org com.finwise --project-name finwise --platforms=android .
sed -i 's/android:label="[^"]*"/android:label="Finwise"/' android/app/src/main/AndroidManifest.xml
flutter pub get
dart run flutter_launcher_icons
flutter test
# Offline guarantee: the main (release) manifest must not request INTERNET.
if grep -q "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml; then
  echo "ERROR: INTERNET permission found in main manifest"; exit 1
fi
echo "Setup complete. Run:  flutter run   |   flutter build apk --release"
