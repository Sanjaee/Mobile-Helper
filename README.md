# Mobile Helper App

A Flutter mobile application with authentication features that connects to a Go backend API through an API Gateway.

## Features

- **User Authentication**

  - User registration with email verification
  - Login with email/password
  - OTP verification for email confirmation
  - Password reset functionality
  - Google OAuth integration (placeholder)

- **User Management**

  - User profile viewing
  - Profile information display
  - Secure token management

- **Clean Architecture**
  - Modular folder structure
  - Reusable widgets
  - API service layer
  - Local storage management

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── constants/              # App constants
│   │   ├── api_endpoints.dart  # API endpoints
│   │   ├── app_colors.dart     # Color scheme (black/white)
│   │   ├── app_text_styles.dart # Text styles
│   │   └── app_assets.dart     # Asset paths
│   ├── utils/                  # Utility classes
│   │   ├── validators.dart     # Form validation
│   │   ├── storage_helper.dart # Local storage
│   │   └── navigation.dart     # Navigation helpers
│   └── widgets/                # Reusable widgets
│       ├── custom_button.dart  # Custom buttons
│       ├── custom_text_field.dart # Custom input fields
│       └── loading_indicator.dart # Loading widgets
├── data/
│   ├── models/                 # Data models
│   │   └── user_model.dart     # User and auth models
│   └── services/               # API services
│       ├── api_client.dart     # HTTP client setup
│       └── auth_service.dart   # Authentication service
├── presentation/
│   ├── auth/                   # Authentication pages
│   │   ├── login_page.dart     # Login screen
│   │   ├── register_page.dart  # Registration screen
│   │   ├── verify_otp_page.dart # OTP verification
│   │   ├── reset_password_page.dart # Password reset request
│   │   └── change_password_page.dart # Password change
│   ├── home/                   # Home page
│   │   └── home_page.dart      # Main dashboard
│   └── splash/                 # Splash screen
│       └── splash_page.dart    # App loading screen
└── routes/
    └── app_routes.dart         # App routing configuration
```

## API Integration

The app connects to a Go backend through an API Gateway running on `http://localhost:5000`.

### Available Endpoints

- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/verify-otp` - OTP verification
- `POST /api/v1/auth/resend-otp` - Resend OTP
- `POST /api/v1/auth/refresh-token` - Token refresh
- `POST /api/v1/auth/google-oauth` - Google OAuth
- `POST /api/v1/auth/request-reset-password` - Request password reset
- `POST /api/v1/auth/verify-reset-password` - Verify password reset
- `GET /api/v1/user/profile` - Get user profile
- `PUT /api/v1/user/profile` - Update user profile

## Design System

The app uses a clean black and white design system:

- **Primary Color**: Black
- **Secondary Color**: White
- **Background**: White
- **Text**: Black (primary), Grey (secondary)
- **Borders**: Black
- **Buttons**: Black background with white text

## Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Go backend running on localhost:5000

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

1. Make sure your Go backend is running on `http://localhost:5000`
2. Run the Flutter app:
   ```bash
   flutter run
   ```

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Dependencies

- `dio` - HTTP client for API requests
- `provider` - State management
- `shared_preferences` - Local storage
- `go_router` - Navigation
- `form_validator` - Form validation
- `flutter_spinkit` - Loading indicators

## Security Features

- JWT token management
- Automatic token refresh
- Secure local storage
- Input validation
- Error handling

## Future Enhancements

- Google OAuth implementation
- Profile update functionality
- Push notifications
- Offline support
- Biometric authentication
- Dark mode support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
