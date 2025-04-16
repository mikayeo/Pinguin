const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const auth = require('../middleware/auth');

// Send money
router.post('/send', auth, async (req, res) => {
  try {
    const { recipientPhone, amount } = req.body;
    const senderId = req.user.userId;

    // Get sender's account
    const [senderAccounts] = await pool.query(
      `SELECT a.*, u.phoneNumber 
       FROM accounts a 
       JOIN users u ON a.user_id = u.id 
       WHERE a.user_id = ?`,
      [senderId]
    );

    if (senderAccounts.length === 0) {
      return res.status(404).json({ message: 'Sender account not found' });
    }

    const senderAccount = senderAccounts[0];

    // Check if sender has sufficient balance
    if (senderAccount.balance < amount) {
      return res.status(400).json({ message: 'Insufficient funds' });
    }

    // Get recipient's account
    const [recipientAccounts] = await pool.query(
      `SELECT a.*, u.phoneNumber 
       FROM accounts a 
       JOIN users u ON a.user_id = u.id 
       WHERE u.phoneNumber = ?`,
      [recipientPhone]
    );

    if (recipientAccounts.length === 0) {
      return res.status(404).json({ message: 'Recipient account not found' });
    }

    const recipientAccount = recipientAccounts[0];

    // Start transaction
    await pool.query('START TRANSACTION');

    try {
      // Update sender's balance
      await pool.query(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, senderAccount.id]
      );

      // Update recipient's balance
      await pool.query(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, recipientAccount.id]
      );

      // Record transaction
      await pool.query(
        'INSERT INTO transactions (sender_phone, recipient_phone, amount, type) VALUES (?, ?, ?, ?)',
        [senderAccount.phoneNumber, recipientAccount.phoneNumber, amount, 'transfer']
      );

      await pool.query('COMMIT');
      res.json({ message: 'Money sent successfully' });
    } catch (error) {
      await pool.query('ROLLBACK');
      throw error;
    }
  } catch (error) {
    console.error('Send money error:', error);
    res.status(500).json({ message: 'Error sending money' });
  }
});

// Get transaction history
router.get('/history', auth, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user's phone number
    const [users] = await pool.query(
      'SELECT phoneNumber FROM users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const phoneNumber = users[0].phoneNumber;

    // Get transactions
    const [transactions] = await pool.query(
      `SELECT t.*, 
              CASE 
                WHEN t.sender_phone = ? THEN 'sent'
                WHEN t.recipient_phone = ? THEN 'received'
              END as type
       FROM transactions t
       WHERE t.sender_phone = ? OR t.recipient_phone = ?
       ORDER BY t.created_at DESC`,
      [phoneNumber, phoneNumber, phoneNumber, phoneNumber]
    );

    res.json(transactions);
  } catch (error) {
    console.error('Get transaction history error:', error);
    res.status(500).json({ message: 'Error fetching transaction history' });
  }
});

module.exports = router; 