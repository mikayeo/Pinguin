const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');

// Register
router.post('/register', async (req, res) => {
  try {
    const { username, password, phoneNumber } = req.body;

    // Validate required fields
    if (!username || !password || !phoneNumber) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    // Check if username already exists
    const [existing] = await pool.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Username already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert into users table
    const [result] = await pool.query(
      'INSERT INTO users (username, password, PhoneNumber) VALUES (?, ?, ?)',
      [username, hashedPassword, phoneNumber]
    );

    // Create account for the user
    await pool.query(
      'INSERT INTO accounts (user_id, email, password, full_name, balance) VALUES (?, ?, ?, ?, ?)',
      [result.insertId, username, hashedPassword, username, 0.00]
    );

    // Generate token
    const token = jwt.sign(
      { userId: result.insertId.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({
      token,
      userId: result.insertId.toString(),
      message: 'User registered successfully'
    });
  } catch (error) {
    console.error('Registration error:', error);
    if (!res.headersSent) {
      res.status(500).json({ message: 'Error registering user' });
    }
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Get user by username
    const [users] = await pool.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );

    if (users.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = users[0];

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user.id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      userId: user.id.toString(),
      message: 'Login successful'
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Error logging in' });
  }
});

// Helper function to generate account number
function generateAccountNumber() {
  return Math.floor(1000000000 + Math.random() * 9000000000).toString();
}

module.exports = router; 