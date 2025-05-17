# AkbayMed

<div id="logo" align="center">
  <img src="assets/images/akbaymed-logo.png" alt="AkbayMed Logo" width="600"/>
</div>

A Flutter-based Android application designed to facilitate medication donation and distribution in Philippine healthcare centers. The app connects donors with patients in need, ensuring safe and transparent medicine redistribution.

## Table of Contents
- [AkbayMed](#akbaymed)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
    - [Authentication](#authentication)
    - [Medication Donation](#medication-donation)
    - [Medication Requests](#medication-requests)
    - [User Profile](#user-profile)
    - [Home Dashboard](#home-dashboard)
  - [Tech Stack](#tech-stack)
    - [Frontend](#frontend)
    - [Backend](#backend)
    - [Dependencies](#dependencies)
  - [Installation](#installation)
  - [Project Structure](#project-structure)
  - [API Integration](#api-integration)
    - [openFDA API](#openfda-api)
    - [Supabase Integration](#supabase-integration)
  - [Database Schema](#database-schema)
    - [Users Table](#users-table)
    - [Donations Table](#donations-table)
    - [Requests Table](#requests-table)
  - [UI/UX Design](#uiux-design)
    - [Design System](#design-system)
    - [Color Scheme](#color-scheme)
  - [Development Setup](#development-setup)
  - [Contributing](#contributing)
  - [License](#license)
  - [Acknowledgments](#acknowledgments)

## Features

### Authentication
Secure and user-friendly authentication system for both donors and patients.

<div align="center">
  <img src="assets/screenshots/login-screen.jpg" alt="Login Screen" width="300"/>
  <img src="assets/screenshots/registration-screen.jpg" alt="Registration Screen" width="300"/>
</div>

- Email and password-based authentication
- User registration with role selection
- Secure session management
- Profile management with avatar upload

### Medication Donation
Streamlined process for donors to contribute medications to those in need.

<div align="center">
  <img src="assets/screenshots/donation-screen.jpg" alt="Donation Screen" width="300"/>
  <img src="assets/screenshots/search-suggestions.jpg" alt="Medication Search" width="300"/>
</div>

- Donation submission with medication details
- Integration with openFDA API for medication verification
- Expiration date tracking
- Donation history and status tracking

### Medication Requests
Easy-to-use interface for patients to request needed medications.

<div align="center">
  <img src="assets/screenshots/request-screen.jpg" alt="Request Screen" width="300"/>
</div>

- Browse available medications
- Submit medication requests
- Track request status
- View request history

### User Profile
Personalized user experience with comprehensive profile management.

<div align="center">
  <img src="assets/screenshots/profile-screen.jpg" alt="Profile Screen" width="300"/>
  <img src="assets/screenshots/update-profile-feature.jpg" alt="Update Profile" width="300"/>
</div>

- View and edit personal information
- Track donation/request history
- Update profile picture
- Manage account settings

### Home Dashboard
Centralized hub for all user activities and quick access to features.

<div align="center">
  <img src="assets/screenshots/home-screen.jpg" alt="Home Screen" width="300"/>
</div>

- Personalized welcome screen
- Activity tracking
- Quick access to main features
- Recent transactions overview

## Tech Stack

### Frontend
- **Framework**: Flutter 3.29.3
- **Language**: Dart 3.7.2
- **UI Components**: Material 3
- **State Management**: Flutter's built-in StatefulWidget
- **Navigation**: Flutter Navigator 2.0

### Backend
- **Authentication**: Supabase Auth
- **Database**: Supabase PostgreSQL
- **Storage**: Supabase Storage
- **API Integration**: 
  - openFDA API for medication information
  - RESTful API architecture

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.9.0
  flutter_dotenv: ^5.2.1
  logger: ^2.5.0
  image_picker: ^1.0.4
  path: ^1.8.3
  permission_handler: ^11.0.0
  http: ^1.4.0
  intl: ^0.19.0
```

## Installation

1. **Prerequisites**
   - Flutter SDK 3.x
   - Android Studio / VS Code
   - Android SDK (API level 26+)
   - Git

2. **Setup Steps**
   ```bash
   # Clone the repository
   git clone https://github.com/lucifron28/AkbayMed_User.git
   cd AkbayMed_User

   # Install dependencies
   flutter pub get

   # Create .env file
   cp .env.example .env
   ```

3. **Environment Configuration**
   Create a `.env` file in the root directory with:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart           # Application entry point
├── app.dart            # Main app configuration
└── screens/           # UI screens
    ├── home_screen.dart
    ├── login_screen.dart
    ├── registration_screen.dart
    ├── donation_screen.dart
    ├── request_screen.dart
    └── profile_screen.dart
```

## API Integration

### openFDA API
- Endpoint: `https://api.fda.gov/drug/label.json`
- Used for medication verification and information
- Implements rate limiting and error handling

### Supabase Integration
- Authentication
- Real-time database
- File storage
- Row Level Security (RLS) policies

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    donation_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Donations Table
```sql
CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donor_id UUID REFERENCES auth.users(id),
    medication_id UUID REFERENCES medications(id),
    quantity INTEGER NOT NULL,
    expiration_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Requests Table
```sql
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES auth.users(id),
    medication_id UUID REFERENCES medications(id),
    quantity INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);
```

## UI/UX Design

### Design System
- Material 3 components
- Healthcare-focused color palette
- Accessible design elements
- Responsive layouts

### Color Scheme
- Primary: `#00796B` (Teal)
- Secondary: `#004D40` (Dark Teal)
- Background: `#E0F2F1` (Light Teal)
- Accent: `#B2DFDB` (Pale Teal)

## Development Setup

1. **IDE Configuration**
   - Install Flutter and Dart plugins
   - Configure Android SDK
   - Set up Flutter SDK path

2. **Code Style**
   - Follow Flutter style guide
   - Use Flutter lints
   - Implement proper error handling

3. **Testing**
   - Unit tests
   - Widget tests
   - Integration tests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend services
- openFDA for medication data
- All contributors and supporters
