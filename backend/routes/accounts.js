const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const auth = require('../middleware/auth');

// Get account details
router.get('/', auth, async (req, res) => {
  try {
    const [accounts] = await pool.query(
      `SELECT a.*, u.full_name, u.email 
       FROM accounts a 
       JOIN users u ON a.user_id = u.id 
       WHERE a.user_id = ?`,
      [req.user.userId]
    );

    if (accounts.length === 0) {
      return res.status(404).json({ message: 'Account not found' });
    }

    res.json(accounts[0]);
  } catch (error) {
    console.error('Get account error:', error);
    res.status(500).json({ message: 'Error fetching account details' });
  }
});

// Get account by account number
router.get('/:accountNumber', auth, async (req, res) => {
  try {
    const [accounts] = await pool.query(
      `SELECT a.account_number, u.full_name 
       FROM accounts a 
       JOIN users u ON a.user_id = u.id 
       WHERE a.account_number = ?`,
      [req.params.accountNumber]
    );

    if (accounts.length === 0) {
      return res.status(404).json({ message: 'Account not found' });
    }

    res.json(accounts[0]);
  } catch (error) {
    console.error('Get account by number error:', error);
    res.status(500).json({ message: 'Error fetching account details' });
  }
});

module.exports = router; 