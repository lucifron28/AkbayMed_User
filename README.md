# AkbayMed

A Flutter Android app developed for a finals exam to facilitate medication donation and distribution in Philippine healthcare centers. The app uses Supabase for authentication and PostgreSQL database, and integrates with the openFDA API for medication information. It targets Android 8.0+ with a Material 3 UI following healthcare design principles.

## Core Features

1. ~~**Login**~~ **(Completed)**
    - **Description**: Allow users (donors and patients) to sign in with email and password to access the app.
    - **Status**: Implemented in `login_screen.dart` using `supabase.auth.signInWithPassword`.
    - **Details**:
        - UI: Form with email and password fields, login button, and link to registration screen.
        - Validation: Non-empty email/password, error handling for invalid credentials.
        - Navigation: Redirects to main app (home screen) on successful login.
        - Design: Material 3 with healthcare-themed colors and accessible UI elements.

2. ~~**User Registration & Account Verification**~~ **(Completed)**
    - **Description**: Enable users to register as donors or patients with email, password, and name.
    - **Status**: Implemented in `registration_screen.dart` using `supabase.auth.signUp` and direct Supabase database operations.
    - **Details**:
        - UI: Form with email, password, name, and submit button.
        - Logic: Sign up and insert user data to `users` table.
        - Validation: Valid email, password ≥8 characters, all fields filled.
        - Design: Consistent Material 3 theming with the login screen.

3. ~~**Medication Donation Management**~~ **(Completed)**
    - **Description**: Allow donors to submit medication donations (name, quantity, expiration date).
    - **Status**: Implemented in `donation_screen.dart` with direct Supabase database operations and openFDA API integration.
    - **Details**:
        - UI: Form with medication name field (with FDA suggestions), quantity input, expiration date picker, and submit button.
        - Logic: 
            - Integrates with openFDA API to suggest generic medication names
            - Creates new medication entries in the database
            - Records donation details with proper validation
        - Validation:
            - Non-empty medication name
            - Quantity > 0
            - Valid expiration date selected
        - Design: Responsive Material 3 UI with healthcare theming and user-friendly interactions.

4. **Patient Access and Medication Requests** *(In Progress)*
    - **Description**: Enable patients to browse available medications and submit requests for specific quantities.
    - **Status**: Started in `request_screen.dart` with openFDA API integration foundation.
    - **Requirements**:
        - UI: Medication browsing view and request form with feedback indicators.
        - Logic: Fetch available medications and process requests with status tracking.
        - Validation: Request quantities against available stock.

## Supporting Features

5. ~~**User Profile View**~~ **(Completed)**
    - **Description**: Display user information and allow logout.
    - **Status**: Implemented in `profile_screen.dart` with direct Supabase integration.
    - **Details**:
        - UI: Displays user information and provides logout functionality.
        - Logic: Fetches user data from Supabase and handles session management.
        - Design: Consistent healthcare-themed Material 3 styling.

6. **Home Screen** *(To Implement)*
    - **Description**: Provide a welcome screen with user stats and quick access to features.
    - **Priority**: Low (enhances demo but not critical).

7. ~~**Navigation**~~ **(Completed)**
    - **Description**: Bottom navigation bar to switch between screens.
    - **Status**: Implemented in `app.dart` with Material 3 styling.
    - **Details**:
        - UI: Bottom navigation with Home, Donate, Request, and Profile tabs.
        - Logic: Auth state detection and screen switching based on selected tab.
        - Design: Themed icons and indicators following Material 3 guidelines.

## Technical Implementation Details

- **Authentication**: Implemented with Supabase Auth directly in UI components.
- **Database**: Using Supabase PostgreSQL with the following schema:
  ```sql
  CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donor_id UUID REFERENCES auth.users(id),
    medication_id UUID REFERENCES medications(id),
    quantity INTEGER NOT NULL,
    expiration_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP DEFAULT NOW()
  );
  ```
- **API Integration**: Using openFDA API for medication information instead of maintaining a separate medication database.
  - Implementation in `donation_screen.dart` allows searching and suggesting generic medication names.
  - Example endpoint: `https://api.fda.gov/drug/label.json?search=openfda.generic_name:{query}`

## UI/UX

- **Design System**: Material 3 with a healthcare-focused color palette (teals and whites)
- **Responsive**: All screens adapt to different device sizes and orientations
- **Accessibility**: High contrast elements and clear labels for better usability

## Next Steps

1. Complete the medication request functionality in `request_screen.dart`
2. Implement medication browsing for patients
3. Add medication request history view
4. Build the home screen with user statistics
5. Enhance error handling and offline support
6. Add comprehensive user guides and tooltips

## Development Environment

- Flutter 3.x
- Supabase for backend services
- Android API 26+ (Android 8.0+)
- openFDA API for medication data
