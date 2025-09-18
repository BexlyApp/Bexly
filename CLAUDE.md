# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pockaw is a Flutter-based personal finance and budget tracking application with a focus on offline-first functionality and cross-platform support. The project uses a feature-based clean architecture with Riverpod for state management and Drift for local database storage.

## Essential Commands

### Development
```bash
# Install/update dependencies
flutter pub get

# Run the app
flutter run                    # Debug mode (default)
flutter run --profile          # Profile mode for performance analysis
flutter run --release          # Release mode

# Code generation (required after modifying Drift database schemas)
dart run build_runner build    # One-time generation
dart run build_runner watch    # Watch mode for continuous generation
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Run tests (minimal coverage currently)
flutter test
```

### Building
```bash
# Android
flutter build apk              # APK for direct installation
flutter build appbundle        # For Play Store submission

# Other platforms (planned)
flutter build web              # Web version
flutter build windows          # Windows desktop
```

### App Icons
```bash
# Regenerate app icons after changes to flutter_launcher_icons.yaml
flutter pub run flutter_launcher_icons:main
```

## Architecture Overview

### State Management Pattern
The app uses Riverpod with Hooks for state management. Each feature typically has:
- A provider file defining the state providers
- Domain models with Freezed for immutability
- Repository pattern for data access
- UI components using HookConsumerWidget

### Database Architecture
Uses Drift (formerly Moor) for SQLite database management:
- Tables defined in `lib/core/database/tables/`
- DAOs (Data Access Objects) in `lib/core/database/daos/`
- Database instance managed through Riverpod providers
- Schema migrations tracked in `drift_schemas/`

### Navigation Structure
Uses Go Router for declarative routing:
- Routes defined in `lib/core/router/`
- Deep linking support
- Named routes for type-safe navigation

### Feature Module Pattern
Each feature in `lib/features/` is self-contained with:
```
feature_name/
├── domain/          # Business logic and models
├── presentation/    # UI screens and widgets
├── riverpod/        # State management providers
└── utils/           # Feature-specific utilities
```

## Key Technical Decisions

### Multi-Wallet Architecture
- Each wallet can have a different currency
- Transactions are scoped to individual wallets
- Wallet switching handled via dedicated UI component

### Offline-First Design
- All data stored locally using Drift/SQLite
- No mandatory authentication required
- Backup/restore functionality for data portability

### Theme System
- Uses flex_color_scheme for advanced theming
- Dark/light mode toggle
- Custom color schemes per wallet

### Form Handling
- Custom keyboard implementation for amount entry
- Date pickers with calendar integration
- Category picker with icon support

## Development Guidelines

### When Adding New Features
1. Create a new directory under `lib/features/`
2. Follow the existing feature structure pattern
3. Use Riverpod providers for state management
4. Add database tables/DAOs if persistent storage needed
5. Update router configuration for new screens

### When Modifying Database
1. Update table definitions in `lib/core/database/tables/`
2. Run `dart run build_runner build` to regenerate code
3. Handle migrations if schema changes affect existing data

### When Working with Transactions
- Transactions belong to wallets
- Categories are shared across wallets
- Date/time handling uses local timezone
- Amount stored as double with currency-specific decimal places

### Common UI Patterns
- Use components from `lib/core/components/` for consistency
- Follow Material Design guidelines with custom enhancements
- Responsive design using responsive_framework
- Custom bottom sheets for forms and pickers

## Current Development Focus

The app is in active development with focus on:
- Android platform stability (currently in Play Store beta)
- Core expense/income tracking features
- Budget and goal management
- Basic analytics and reporting

Upcoming priorities include:
- Enhanced analytics and charts
- Web and desktop platform support
- Improved test coverage
- Multi-language support via localization