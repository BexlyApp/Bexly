# Bexly Documentation

Welcome to the Bexly development documentation. This folder contains all technical guides and references for developing, building, and deploying the Bexly expense tracker app.

## 📚 Documentation Index

### [DEVELOPMENT.md](./DEVELOPMENT.md)
Complete development guide covering:
- Environment setup
- Project structure
- Technology stack (Flutter, Riverpod, Drift)
- Development workflow
- Code style guidelines
- Common commands
- Troubleshooting

### [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)
Firebase integration documentation:
- Firebase project configuration
- Package ID migration (com.layground.pockaw → com.joy.bexly)
- FlutterFire setup process
- Enabled services (Analytics, Crashlytics, Performance)
- Security considerations
- Multi-environment setup

### [BUILD_DEPLOYMENT.md](./BUILD_DEPLOYMENT.md)
Build and deployment procedures:
- Quick build commands
- Android APK/AAB building
- iOS build process
- Web deployment
- Version management
- Store deployment (Play Store, App Store)
- CI/CD setup
- Post-deployment monitoring

## 🚀 Quick Start

### Run the App
```bash
# Quick run with helper script
D:\Projects\DOSafe\run_bexly.bat

# Or directly with Flutter
D:\Dev\flutter\bin\flutter run
```

### Build for Production
```bash
# Android APK
D:\Dev\flutter\bin\flutter build apk --release

# Location: build\app\outputs\flutter-apk\app-release.apk
```

## 📦 Project Information

- **App Name**: Bexly
- **Package ID**: `com.joy.bexly`
- **Firebase Project**: `bexly-app`
- **Flutter Path**: `D:\Dev\flutter`
- **Project Path**: `D:\Projects\DOSafe`

## 🛠️ Essential Commands

```bash
# Install dependencies
D:\Dev\flutter\bin\flutter pub get

# Generate database code
D:\Dev\flutter\bin\dart run build_runner build

# Run tests
D:\Dev\flutter\bin\flutter test

# Analyze code
D:\Dev\flutter\bin\flutter analyze
```

## 📱 Features

- **Expense Tracking**: Record daily expenses and income
- **Multi-Wallet**: Manage multiple wallets with different currencies
- **Offline-First**: All data stored locally with SQLite
- **Budget Management**: Set and track budgets
- **Analytics**: Visual reports and insights
- **Categories**: Customizable expense categories
- **Firebase Integration**: Analytics, crash reporting, performance monitoring

## 🏗️ Architecture

The app follows a feature-based clean architecture:
- **State Management**: Riverpod with Hooks
- **Database**: Drift (SQLite)
- **Navigation**: Go Router
- **UI**: Material Design with flex_color_scheme

## 📄 License

This project is based on the open-source Pockaw project and has been customized for the JOY brand ecosystem.

## 🤝 Contributing

Please refer to [DEVELOPMENT.md](./DEVELOPMENT.md) for development guidelines and coding standards.

## 📞 Support

For questions or issues related to development, please check the troubleshooting sections in the respective documentation files.

---

*Last updated: September 2025*