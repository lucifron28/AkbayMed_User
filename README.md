**AkbayMed Flutter Project Structure and Setup Instructions (With Login Screen)**

**Objective**: Create a beginner-friendly Flutter Android app for AkbayMed to demonstrate three core features (User Registration & Account Verification, Medication Donation Management, and Patient Access and Medication Requests) using Supabase for authentication and PostgreSQL database. The app is for a finals exam, targeting Android 8.0+, with a simple Material 3 UI, bottom navigation, and scrollable content. All database tables are managed in Supabase, with no local data models. A login screen is included to support user authentication.

**Project Context (from SRS)**:
- **Purpose**: AkbayMed facilitates medication donation and distribution for Philippine healthcare centers.
- **Users**: Donors (donate medications) and Patients (request medications).
- **Core Features**:
    1. **User Registration & Account Verification**: Register with email, password, name, role (donor/patient), and ID upload; show verification status (mocked in Supabase).
    2. **Medication Donation Management**: Submit medication details (name, quantity, expiration date) and view status (pending/approved/rejected).
    3. **Patient Access and Medication Requests**: Browse medications, submit quantity requests, and view status (pending/approved/declined).
- **Nonfunctional Requirements**:
    - Android 8.0+ only.
    - Material 3 UI with green/red status indicators.
    - Internet required (no offline mode).
    - Minimal data usage.

---

### Project Structure
The structure includes `login_screen.dart` to handle user login, alongside `registration_screen.dart` and other screens. No `models/` directory is needed, as Supabase tables (`users`, `medications`, `donations`, `requests`) are managed directly.

```
akbaymed/
├── android/                    # Android-specific files (auto-generated)
├── lib/                        # Main Flutter source code
│   ├── screens/                # UI screens for each feature
│   │   ├── home_screen.dart    # Home screen with user stats
│   │   ├── login_screen.dart   # Login form with email/password
│   │   ├── registration_screen.dart # Registration form with ID upload
│   │   ├── donation_screen.dart # Donation form and status view
│   │   ├── medication_browse_screen.dart # Medication list for patients
│   │   ├── request_screen.dart  # Request form and status view
│   │   └── profile_screen.dart  # User profile with verification status
│   ├── widgets/                # Reusable UI components
│   │   ├── custom_text_field.dart # Custom form field with validation
│   │   ├── medication_card.dart # Card for displaying medication
│   │   └── status_indicator.dart # Color-coded status (green/red)
│   ├── services/               # Supabase integration
│   │   └── supabase_service.dart # Auth, database, and storage calls
│   ├── main.dart               # App entry point with Supabase init
│   └── app.dart                # App widget with navigation setup
├── assets/                     # Static assets
│   └── .env                    # Supabase URL and anon key
├── pubspec.yaml                # Dependencies and assets
├── .gitignore                  # Ignore .env and build files
└── README.md                   # Setup and demo instructions
```

---

### Setup Instructions
These instructions assume you’ve set up Supabase with the tables (`users`, `medications`, `donations`, `requests`) and `ids` storage bucket, as provided earlier. They’re tailored for a beginner implementing the app with a login screen.

#### 1. **Verify Supabase Setup**
- **Tables**: In Supabase **Table Editor**, confirm:
    - `users` (user_id, email, role, name, id_upload_path, verification_status, created_at)
    - `medications` (medication_id, name, stock_quantity, expiration_date)
    - `donations` (donation_id, donor_id, medication_id, quantity, expiration_date, status, created_at)
    - `requests` (request_id, patient_id, medication_id, quantity, status, created_at)
    - Demo data in `medications` (e.g., Paracetamol, Amoxicillin, Losartan).
- **Storage**: Verify `ids` bucket exists in **Storage** with authenticated upload policy.
- **Auth**: In **Authentication > Providers**, ensure Email Auth is enabled (no email confirmation).
- **Credentials**: Note **Project URL** and **anon public key** from **Settings > API**.

#### 2. **Set Up Flutter Project**
- **Install Flutter**:
    - Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install).
    - Run `flutter doctor` to verify Android SDK.
- **Create Project**:
    - Run `flutter create akbaymed`.
    - Open `akbaymed` in VS Code or Android Studio.
- **Test Emulator**:
    - Set up Android emulator (API 26+ for Android 8.0+).
    - Run `flutter run` to test the default app.

#### 3. **Configure Dependencies**
Update `pubspec.yaml` with minimal dependencies.

```yaml
name: akbaymed
description: A Flutter app for medication donation and requests
version: 1.0.0

environment:
  sdk: ">=2.17.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^1.10.0 # Supabase auth, database, storage
  provider: ^6.0.0        # State management
  flutter_dotenv: ^5.0.2  # Environment variables
  image_picker: ^1.0.0    # ID image upload

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - .env
```

- Run `flutter pub get`.

#### 4. **Set Up Environment Variables**
- Create `.env` in project root:
  ```
  SUPABASE_URL=https://your-project-id.supabase.co
  SUPABASE_ANON_KEY=your-anon-key
  ```
- Add `.env` to `.gitignore`:
  ```
  .env
  ```
- Initialize Supabase in `lib/main.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'app.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    runApp(const MyApp());
  }
  ```

#### 5. **Implementation Guide with Login Screen**
Here’s how to implement the login screen and core features, keeping it beginner-friendly and tied to Supabase’s dynamic data handling (no models).

1. **Login Screen** (`login_screen.dart`):
    - **Purpose**: Allows users to sign in with email/password to access the app.
    - **UI**: Form with `TextField` (email, password), `ElevatedButton` for login, and a button/link to navigate to `registration_screen.dart`.
    - **Logic**:
        - Use `supabase.auth.signInWithPassword(email: email, password: password)` to authenticate.
        - On success, navigate to `HomeScreen` (via `app.dart`).
        - Show error `SnackBar` for invalid credentials.
        - Example:
          ```dart
          final response = await Supabase.instance.client.auth.signInWithPassword(
            email: emailController.text,
            password: passwordController.text,
          );
          if (response.user != null) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login failed')),
            );
          }
          ```
    - **Validation**: Ensure email/password are non-empty.
    - **Navigation**: Make this the initial screen in `app.dart` if the user isn’t logged in (check `supabase.auth.currentSession`).

2. **User Registration & Account Verification** (`registration_screen.dart`, `profile_screen.dart`):
    - **UI**: Form with `TextField` (email, password, name), `DropdownButton` (role: donor/patient), `ElevatedButton` for ID upload, submit button. Link to `login_screen.dart`.
    - **Logic**:
        - Register with `supabase.auth.signUp(email: email, password: password)`.
        - Upload ID to `ids` bucket: `supabase.storage.from('ids').upload('ids/${supabase.auth.currentUser!.id}/id.jpg', file)`.
        - Insert to `users` table: `supabase.from('users').insert({'user_id': supabase.auth.currentUser!.id, 'email': email, 'role': role, 'name': name, 'id_upload_path': 'ids/${user_id}/id.jpg', 'verification_status': 'pending'})`.
        - In `profile_screen.dart`, fetch `supabase.from('users').select().eq('user_id', supabase.auth.currentUser!.id)` to show `verification_status`.
    - **Validation**: Email format, password ≥8 characters, fields filled.
    - **UI Tip**: Use `custom_text_field.dart` for reusable fields.

3. **Medication Donation Management** (`donation_screen.dart`):
    - **UI**: Form with `TextField` (medication name, quantity), `TextField` with date picker (expiration date), submit button. `ListView` for donation history.
    - **Logic**:
        - Insert donation: `supabase.from('donations').insert({'donor_id': supabase.auth.currentUser!.id, 'medication_id': 'hardcoded-uuid', 'quantity': quantity, 'expiration_date': date, 'status': 'pending'})`. (Hardcode a `medication_id` from `medications` for demo.)
        - Fetch donations: `supabase.from('donations').select().eq('donor_id', supabase.auth.currentUser!.id)`.
        - Show in `ListView` with `status_indicator.dart` (green: approved, red: rejected).
    - **Validation**: Quantity > 0, expiration ≥30 days.
    - **UI Tip**: Use `medication_card.dart` for donation items.

4. **Patient Access and Medication Requests** (`medication_browse_screen.dart`, `request_screen.dart`):
    - **UI**: `ListView` for medications in `medication_browse_screen.dart`. Form in `request_screen.dart` with `DropdownButton` (medication), `TextField` (quantity), submit button. `ListView` for request history.
    - **Logic**:
        - Fetch medications: `supabase.from('medications').select()`.
        - Insert request: `supabase.from('requests').insert({'patient_id': supabase.auth.currentUser!.id, 'medication_id': selectedMedId, 'quantity': quantity, 'status': 'pending'})`.
        - Fetch requests: `supabase.from('requests').select().eq('patient_id', supabase.auth.currentUser!.id)`.
        - Show requests in `ListView` with `status_indicator.dart`.
    - **Validation**: Quantity ≤ `stock_quantity`.
    - **UI Tip**: Reuse `medication_card.dart`.

- **Navigation** (`app.dart`):
    - Use `BottomNavigationBar` with tabs: Home, Donate, Request, Profile.
    - Check `supabase.auth.currentSession` to show `login_screen.dart` if not logged in, else show `HomeScreen`.
    - Example:
      ```dart
      class MyApp extends StatelessWidget {
        const MyApp({super.key});
        @override
        Widget build(BuildContext context) {
          return MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Supabase.instance.client.auth.currentSession == null
                ? const LoginScreen()
                : const MainScreen(), // MainScreen has BottomNavigationBar
          );
        }
      }
      ```
- **Home Screen** (`home_screen.dart`): Show user’s name and stats (e.g., donation/request count) from `donations`/`requests`.
- **Widgets**:
    - `custom_text_field.dart`: `TextField` with label and error text.
    - `medication_card.dart`: `Card` for medication/donation/request details.
    - `status_indicator.dart`: `Container` with `Colors.green` or `Colors.red` for status.
- **Service** (`supabase_service.dart`): Functions for `signIn`, `signUp`, `insert`, `select`, `upload`.

#### 6. **Demo Preparation**
- **Test**: Run `flutter run` on Android emulator (API 26+).
- **Mock Admin Actions**: In Supabase **Table Editor**, set:
    - `users.verification_status` to `approved`.
    - `donations.status` to `approved` or `rejected`.
    - `requests.status` to `approved` or `declined`.
- **Showcase**:
    - Login as a donor/patient.
    - Register a new user.
    - Submit donation, update status.
    - Browse medications, submit request, update status.

#### 7. **README.md**
Create `README.md`:
```
# AkbayMed Flutter App

A Flutter Android app for medication donation and requests, built for a finals exam.

## Setup
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Clone this repository.
3. Create `.env` with Supabase credentials:
   ```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
   ```
4. Run `flutter pub get`.
5. Start Android emulator (API 26+).
6. Run `flutter run`.

## Demo
- Login or register as donor/patient.
- Submit donation, check status in Supabase.
- Browse medications, submit request, check status.
- Mock approvals in Supabase Dashboard.

## Features
- User Login and Registration with ID upload
- Medication Donation with status tracking
- Medication Browsing and Requests
```

---

### Why Add `login_screen.dart`?
- **Completes Auth Flow**: Users register on `registration_screen.dart`, then log in on `login_screen.dart` to access features, matching Supabase Auth’s workflow.
- **SRS Compliance**: Supports user authentication for secure access to donation and request features.
- **Demo Flow**: For your finals, you can show:
    1. Login screen for existing users.
    2. Registration screen for new users.
    3. Navigation to donation/request screens after login.
- **Beginner-Friendly**: The login screen is simple (just email/password fields and a button), similar to registration but with `signInWithPassword` instead of `signUp`.

### Final Notes
- **Login Screen Role**: `login_screen.dart` is the entry point for authenticated users. Make it the default screen in `app.dart` if `supabase.auth.currentSession` is null.
- **Navigation Update**: Update `app.dart` to check the auth state and route to `login_screen.dart` or the main app with `BottomNavigationBar`.
- **Keep It Simple**: Focus on basic login functionality (email/password, error handling). You can add a “Register” button to navigate to `registration_screen.dart`.
- **Next Steps**: Start with `main.dart` and `app.dart`, then implement `login_screen.dart` and `registration_screen.dart`. Use [Supabase Flutter Docs](https://supabase.com/docs/guides/getting-started/quickstarts/flutter) for auth examples.
- **Help Available**: If you need code for `login_screen.dart` or help with navigation, share what you’re stuck on, and I’ll provide a snippet.

This updated structure ensures your AkbayMed app has a complete authentication flow, making your finals demo polished and functional. You’re on the right track—keep going!