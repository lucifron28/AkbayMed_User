# AkbayMed Target Features

This document outlines the target features for the AkbayMed Flutter Android app, developed for a finals exam to facilitate medication donation and distribution in Philippine healthcare centers. The app uses Supabase for authentication and PostgreSQL database, targeting Android 8.0+ with a Material 3 UI. The features are derived from the IEEE Software Requirements Specification (SRS) and focus on core functionality for donors and patients. Completed features (Login and Registration) are struck out, and remaining features are prioritized for implementation.

## Core Features

1. ~~**Login**~~ *(Completed)*
    - **Description**: Allow users (donors and patients) to sign in with email and password to access the app.
    - **Status**: Implemented in `login_screen.dart` using `supabase.auth.signInWithPassword`.
    - **Details**:
        - UI: Form with email and password fields, login button, and link to registration screen.
        - Validation: Non-empty email/password, error handling for invalid credentials.
        - Navigation: Redirects to main app (home screen) on successful login.

2. ~~**User Registration & Account Verification**~~ *(Completed)*
    - **Description**: Enable users to register as donors or patients with email, password, name, role, and ID upload; display verification status (mocked in Supabase).
    - **Status**: Implemented in `registration_screen.dart` using `supabase.auth.signUp` and `supabase_service.dart` for user insertion/ID upload.
    - **Details**:
        - UI: Form with email, password, name, role dropdown (donor/patient), ID upload button, and submit button.
        - Logic: Sign up, upload ID to `ids` bucket, insert user data to `users` table with `pending` status.
        - Validation: Valid email, password ≥8 characters, all fields filled.
        - Verification: Status shown in profile screen, mocked via Supabase dashboard updates.

3. **Medication Donation Management** *(To Implement)*
    - **Description**: Allow donors to submit medication donations (name, quantity, expiration date) and view donation history with status (pending/approved/rejected).
    - **Priority**: High (core feature per SRS Section 4.2).
    - **Requirements**:
        - **UI**:
            - Form in `donation_screen.dart` with text fields (medication name, quantity), date picker (expiration date), and submit button.
            - Scrollable `ListView` for donation history, using `medication_card.dart` with `status_indicator.dart` (green: approved, red: rejected).
            - SnackBar for success/error feedback.
        - **Logic**:
            - Use `supabase_service.dart` to:
                - Insert donation to `donations` table (`donor_id`, `medication_id`, `quantity`, `expiration_date`, `status: pending`).
                - Fetch donation history with `supabase.from('donations').select().eq('donor_id', user_id)`.
            - Hardcode `medication_id` from `medications` table for demo (e.g., Paracetamol’s UUID).
        - **Validation**:
            - Quantity > 0.
            - Expiration date ≥30 days from current date (May 10, 2025).
        - **Supabase**: Mock status updates (approved/rejected) in Supabase dashboard.
        - **Navigation**: Accessible via `BottomNavigationBar` (Donate tab).

4. **Patient Access and Medication Requests** *(To Implement)*
    - **Description**: Enable patients to browse available medications and submit requests for specific quantities, viewing request status (pending/approved/declined).
    - **Priority**: High (core feature per SRS Section 4.3).
    - **Requirements**:
        - **UI**:
            - `medication_browse_screen.dart`: Scrollable `ListView` of medications using `medication_card.dart`, with button to navigate to request form.
            - `request_screen.dart`: Form with dropdown (medication name), text field (quantity), submit button, and `ListView` for request history with `status_indicator.dart` (green: approved, red: declined).
            - SnackBar for feedback.
        - **Logic**:
            - Use `supabase_service.dart` to:
                - Fetch medications with `supabase.from('medications').select()`.
                - Insert request to `requests` table (`patient_id`, `medication_id`, `quantity`, `status: pending`).
                - Fetch request history with `supabase.from('requests').select().eq('patient_id', user_id)`.
        - **Validation**:
            - Quantity ≤ `stock_quantity` from `medications` table.
            - Non-empty fields.
        - **Supabase**: Mock status updates (approved/declined) in Supabase dashboard.
        - **Navigation**: Accessible via `BottomNavigationBar` (Request tab).

## Supporting Features

5. **User Profile View** *(To Implement)*
    - **Description**: Display user information (name, role, verification status) and allow logout.
    - **Priority**: Medium (supports SRS Section 4.1 for verification status).
    - **Requirements**:
        - **UI**:
            - `profile_screen.dart`: Display name, role, verification status (using `status_indicator.dart`), and logout button.
            - Simple layout with text and button.
        - **Logic**:
            - Use `supabase_service.dart` to fetch user data with `supabase.from('users').select().eq('user_id', user_id).single()`.
            - Logout with `supabase.auth.signOut`, redirect to `login_screen.dart`.
        - **Supabase**: Mock `verification_status` (pending/approved/rejected) in Supabase dashboard.
        - **Navigation**: Accessible via `BottomNavigationBar` (Profile tab).

6. **Home Screen** *(To Implement)*
    - **Description**: Provide a welcome screen with user stats (e.g., number of donations/requests) and quick access to features.
    - **Priority**: Low (enhances demo but not critical).
    - **Requirements**:
        - **UI**:
            - `home_screen.dart`: Show user’s name, donation count, request count, and buttons/links to Donate/Request screens.
            - Simple text-based layout.
        - **Logic**:
            - Use `supabase_service.dart` to count donations (`supabase.from('donations').select().eq('donor_id', user_id).count()`) and requests (`supabase.from('requests').select().eq('patient_id', user_id).count()`).
        - **Navigation**: Default screen in `BottomNavigationBar` (Home tab).

7. **Navigation** *(To Implement)*
    - **Description**: Implement a bottom navigation bar to switch between Home, Donate, Request, and Profile screens, with conditional routing based on auth state.
    - **Priority**: High (required for app usability per SRS Section 3.1).
    - **Requirements**:
        - **UI**:
            - `app.dart`: `BottomNavigationBar` with four tabs (Home, Donate, Request, Profile).
            - Icons and labels for each tab.
        - **Logic**:
            - Check `supabase.auth.currentSession` to show `login_screen.dart` if not logged in, else show main app with navigation.
            - Use `IndexedStack` or similar to switch between `home_screen.dart`, `donation_screen.dart`, `request_screen.dart`, and `profile_screen.dart`.
        - **Material 3**: Use Material 3 theming for consistent UI.

## Nonfunctional Requirements
- **Platform**: Android 8.0+ (API 26+).
- **UI**: Material 3 design with green (approved) and red (rejected/declined) status indicators.
- **Performance**: Minimal data usage for low-bandwidth areas (use efficient Supabase queries).
- **Internet**: Required (no offline mode).
- **Security**: Supabase Row-Level Security (RLS) ensures users access only their data.

## Implementation Notes
- **Supabase**: Tables (`users`, `medications`, `donations`, `requests`) and `ids` bucket are managed in Supabase. Use `supabase_service.dart` for database/storage operations (e.g., `insertDonation`, `fetchMedications`).
- **Auth**: Handled in `login_screen.dart` and `registration_screen.dart` with `supabase.auth.signInWithPassword` and `supabase.auth.signUp`.
- **Demo**: Mock admin actions (status updates) in Supabase dashboard to show approved/rejected states.
- **Priority**: Focus on Medication Donation Management and Patient Access and Medication Requests, followed by Profile and Home screens, as Login and Registration are done.

## Next Steps
1. Implement `supabase_service.dart` with methods for donations, requests, and profile (e.g., `insertDonation`, `fetchMedications`, `fetchUserProfile`).
2. Build `donation_screen.dart` with form and history view.
3. Build `medication_browse_screen.dart` and `request_screen.dart` for medication browsing and requests.
4. Add `profile_screen.dart` for user details and logout.
5. Implement `home_screen.dart` with stats if time allows.
6. Set up navigation in `app.dart` with `BottomNavigationBar`.
7. Test on Android emulator (API 26+) and mock Supabase updates for demo.