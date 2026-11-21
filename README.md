# WiFi Voucher App

A Flutter app for managing WiFi vouchers, backed by Firebase Authentication and
Cloud Firestore.

## Run the app

```bash
flutter pub get
flutter run
```

The Firebase project configuration is included for Android and Web. Firebase
Email/Password sign-in must be enabled in the Firebase Console for login and
account creation to work.

## Account access

The login screen allows users to create accounts. Newly created accounts are
signed in immediately and receive administrator access. Use this only for a
trusted audience; public registration allows anyone to access the administrator
portal.
