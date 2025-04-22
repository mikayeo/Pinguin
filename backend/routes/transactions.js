const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const auth = require('../middleware/auth');

// Send money
router.post('/send', auth, async (req, res) => {
  try {
    const { recipient_phone, amount } = req.body;
    const senderId = req.user.userId;

    // Clean phone numbers
    const cleanRecipientPhone = recipient_phone.trim();

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

    // Check if recipient exists
    console.log('Looking for recipient:', cleanRecipientPhone);
    console.log('Recipient phone type:', typeof cleanRecipientPhone);
    console.log('Recipient phone length:', cleanRecipientPhone.length);
    
    // Get all users first to debug
    const [allUsers] = await pool.query('SELECT id, username, phoneNumber FROM users');
    console.log('All users:', JSON.stringify(allUsers, null, 2));
    
    const [recipients] = await pool.query(
      'SELECT * FROM users WHERE phoneNumber = ?',
      [cleanRecipientPhone]
    );
    console.log('Found recipients:', JSON.stringify(recipients, null, 2));

    if (recipients.length === 0) {
      console.log('No recipient found with phone:', cleanRecipientPhone);
      return res.status(404).json({ message: 'Recipient not found' });
    }

    // Start transaction
    await pool.query('START TRANSACTION');

    try {
      // Record transaction first
      const [result] = await pool.query(
        'INSERT INTO transactions (sender_phone, recipient_phone, amount, type) VALUES (?, ?, ?, ?)',
        [senderAccount.phoneNumber, cleanRecipientPhone, amount, 'transfer']
      );

      // Update sender's balance
      const [senderUpdate] = await pool.query(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, senderAccount.id]
      );

      if (senderUpdate.affectedRows === 0) {
        throw new Error('Failed to update sender balance');
      }

      // Update recipient's balance
      const [recipientUpdate] = await pool.query(
        'UPDATE accounts SET balance = balance + ? WHERE user_id = ?',
        [amount, recipients[0].id]
      );

      if (recipientUpdate.affectedRows === 0) {
        throw new Error('Failed to update recipient balance');
      }

      // Get the updated transaction record
      const [transactions] = await pool.query(
        `SELECT t.*, 
                t.sender_phone,
                t.recipient_phone
         FROM transactions t
         WHERE t.id = ?`,
        [result.insertId]
      );

      await pool.query('COMMIT');
      
      // Return the transaction details
      res.json({
        message: 'Money sent successfully',
        transaction: transactions[0]
      });
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
              u1.phoneNumber as sender_phone,
              u2.phoneNumber as recipient_phone,
              CASE 
                WHEN t.sender_phone = ? THEN -t.amount
                WHEN t.recipient_phone = ? THEN t.amount
              END as amount_with_sign,
              CASE 
                WHEN t.sender_phone = ? THEN 'send'
                WHEN t.recipient_phone = ? THEN 'receive'
              END as transaction_type
       FROM transactions t
       JOIN users u1 ON t.sender_phone = u1.phoneNumber
       JOIN users u2 ON t.recipient_phone = u2.phoneNumber
       WHERE t.sender_phone = ? OR t.recipient_phone = ?
       ORDER BY t.created_at DESC`,
      [phoneNumber, phoneNumber, phoneNumber, phoneNumber, phoneNumber, phoneNumber]
    );

    res.json(transactions);
  } catch (error) {
    console.error('Get transaction history error:', error);
    res.status(500).json({ message: 'Error fetching transaction history' });
  }
});

module.exports = router; 