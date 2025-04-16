const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const auth = require('../middleware/auth');

// Get account details
router.get('/', auth, async (req, res) => {
  try {
    const userId = parseInt(req.user.userId);
    const [accounts] = await pool.query(
      `SELECT a.*, u.username, u.phoneNumber 
       FROM accounts a 
       JOIN users u ON a.user_id = u.id 
       WHERE a.user_id = ?`,
      [userId]
    );

    if (accounts.length === 0) {
      return res.status(404).json({ message: 'Account not found' });
    }

    const account = accounts[0];
    // Format the response to match frontend expectations
    res.json({
      id: account.id,
      full_name: account.full_name,
      email: account.email,
      balance: account.balance,
      phone_number: account.phoneNumber
    });
  } catch (error) {
    console.error('Get account error:', error);
    res.status(500).json({ message: 'Error fetching account details' });
  }
});

// Get account by phone number
router.get('/:phoneNumber', auth, async (req, res) => {
  try {
    const userId = parseInt(req.user.userId);
    const [accounts] = await pool.query(
      `SELECT a.*, u.username 
       FROM accounts a 
       JOIN users u ON a.user_id = u.id 
       WHERE u.phoneNumber = ? AND a.user_id = ?`,
      [req.params.phoneNumber, userId]
    );

    if (accounts.length === 0) {
      return res.status(404).json({ message: 'Account not found' });
    }

    res.json(accounts[0]);
  } catch (error) {
    console.error('Get account by phone error:', error);
    res.status(500).json({ message: 'Error fetching account details' });
  }
});

module.exports = router; 