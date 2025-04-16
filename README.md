# Pinguin Money Transfer App

A Flutter-based money transfer application similar to Wave, allowing users to send and receive money using phone numbers.

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── config/                   # Configuration files
│   └── api_config.dart       # API endpoints and configuration
├── models/                   # Data models
│   ├── account.dart          # Account model
│   ├── transaction.dart      # Transaction model
│   └── user.dart             # User model
├── providers/                # State management
│   ├── account_provider.dart # Account state management
│   └── auth_provider.dart    # Authentication state management
├── screens/                  # UI screens
│   ├── auth/                 # Authentication screens
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/                 # Home and related screens
│       ├── home_screen.dart
│       └── qr_scanner_screen.dart
└── services/                 # API services
    ├── account_service.dart  # Account-related API calls
    └── auth_service.dart     # Authentication-related API calls
```

## Database Implementation

### Current State
- The application is using a REST API backend
- User authentication is implemented with JWT tokens
- Account management is handled through API endpoints
- QR code scanning for phone numbers is implemented

### Database Schema

#### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Accounts Table
```sql
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Transactions Table
```sql
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES accounts(id),
    recipient_id INTEGER REFERENCES accounts(id),
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login with phone number and password

### Accounts
- `GET /api/accounts/me` - Get current user's account details
- `POST /api/accounts/send-money` - Send money to another account

## Implementation Tasks

1. **Database Setup**
   - Set up PostgreSQL database
   - Create tables using the provided schema
   - Implement database migrations

2. **Backend API**
   - Implement user registration and login endpoints
   - Create account management endpoints
   - Implement transaction processing
   - Add input validation and error handling

3. **Security**
   - Implement JWT token generation and validation
   - Add password hashing
   - Set up CORS policies
   - Implement rate limiting

4. **Testing**
   - Write unit tests for database operations
   - Test API endpoints
   - Implement integration tests

## Development Setup

1. **Prerequisites**
   - Flutter SDK
   - PostgreSQL
   - Node.js (for backend)
   - Git

2. **Frontend Setup**
   ```bash
   flutter pub get
   flutter run
   ```

3. **Backend Setup**
   ```bash
   cd backend
   npm install
   npm run dev
   ```

## Environment Variables

Create a `.env` file in the backend directory with the following variables:
```
DATABASE_URL=postgresql://username:password@localhost:5432/pinguin
JWT_SECRET=your_jwt_secret
PORT=3000
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
