# Pinguin - Money Transfer App

A modern money transfer application built with Flutter (frontend) and Node.js (backend).

## Project Structure

```
pinguin/
├── backend/           # Node.js backend
│   ├── config/       # Database and other configurations
│   ├── middleware/   # Authentication middleware
│   ├── routes/       # API routes
│   ├── schema.sql    # Database schema
│   └── server.js     # Main server file
└── frontend/         # Flutter frontend
```

## Prerequisites

- Node.js (v14 or higher)
- MySQL (v8.0 or higher)
- Flutter SDK (v3.6.1 or higher)
- Git

## Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file in the backend directory with the following content:
   ```
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=pinguin
   JWT_SECRET=your_jwt_secret_key
   PORT=3000
   ```
   Replace `your_mysql_password` with your MySQL root password and `your_jwt_secret_key` with a secure random string.

4. Set up the database:
   - Open MySQL command line or MySQL Workbench
   - Run the schema.sql file:
     ```sql
     source path/to/backend/schema.sql
     ```

5. Start the backend server:
   ```bash
   npm run dev
   ```
   The server will start on http://localhost:3000

## Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Flutter app:
   ```bash
   flutter run
   ```

## API Endpoints

### Authentication
- POST `/api/auth/register` - Register a new user
- POST `/api/auth/login` - Login user

### Accounts
- GET `/api/accounts` - Get user's account details
- GET `/api/accounts/:accountNumber` - Get account details by account number

### Transactions
- POST `/api/transactions/send` - Send money
- GET `/api/transactions/history` - Get transaction history

## Environment Variables

### Backend (.env)
- `DB_HOST` - MySQL host (default: localhost)
- `DB_USER` - MySQL username (default: root)
- `DB_PASSWORD` - MySQL password
- `DB_NAME` - Database name (default: pinguin)
- `JWT_SECRET` - Secret key for JWT tokens
- `PORT` - Server port (default: 3000)

## Dependencies

### Backend
- express
- mysql2
- cors
- dotenv
- bcryptjs
- jsonwebtoken

### Frontend
- provider
- shared_preferences
- dio
- form_validator
- flutter_svg
- intl
- flutter_secure_storage

## Contributing

1. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them:
   ```bash
   git commit -m "Add your feature description"
   ```

3. Push to your branch:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request

## Troubleshooting

### Database Connection Issues
- Verify MySQL is running
- Check if the credentials in .env match your MySQL setup
- Ensure the database and tables are created

### Backend Issues
- Check if all dependencies are installed
- Verify the .env file exists with correct values
- Ensure the server port is not in use

### Frontend Issues
- Run `flutter clean` and `flutter pub get` if dependencies are not resolving
- Check if the backend server is running before testing API calls
- Verify the API base URL in the frontend configuration

## License

This project is licensed under the MIT License.
