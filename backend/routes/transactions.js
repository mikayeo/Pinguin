const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const auth = require('../middleware/auth');

// Send money
router.post('/send', auth, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { recipientAccountNumber, amount } = req.body;

    // Get sender's account
    const [senderAccounts] = await connection.query(
      'SELECT * FROM accounts WHERE user_id = ?',
      [req.user.userId]
    );

    if (senderAccounts.length === 0) {
      throw new Error('Sender account not found');
    }

    const senderAccount = senderAccounts[0];

    // Check sufficient balance
    if (senderAccount.balance < amount) {
      throw new Error('Insufficient funds');
    }

    // Get recipient's account
    const [recipientAccounts] = await connection.query(
      'SELECT * FROM accounts WHERE account_number = ?',
      [recipientAccountNumber]
    );

    if (recipientAccounts.length === 0) {
      throw new Error('Recipient account not found');
    }

    const recipientAccount = recipientAccounts[0];

    // Update balances
    await connection.query(
      'UPDATE accounts SET balance = balance - ? WHERE id = ?',
      [amount, senderAccount.id]
    );

    await connection.query(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [amount, recipientAccount.id]
    );

    // Record transaction
    await connection.query(
      `INSERT INTO transactions 
       (sender_account_id, recipient_account_id, amount, type) 
       VALUES (?, ?, ?, 'transfer')`,
      [senderAccount.id, recipientAccount.id, amount]
    );

    await connection.commit();
    res.json({ message: 'Transfer successful' });
  } catch (error) {
    await connection.rollback();
    console.error('Transfer error:', error);
    res.status(400).json({ message: error.message });
  } finally {
    connection.release();
  }
});

// Get transaction history
router.get('/history', auth, async (req, res) => {
  try {
    const [accounts] = await pool.query(
      'SELECT id FROM accounts WHERE user_id = ?',
      [req.user.userId]
    );

    if (accounts.length === 0) {
      return res.status(404).json({ message: 'Account not found' });
    }

    const accountId = accounts[0].id;

    const [transactions] = await pool.query(
      `SELECT t.*, 
              sa.account_number as sender_account_number,
              ra.account_number as recipient_account_number,
              su.full_name as sender_name,
              ru.full_name as recipient_name
       FROM transactions t
       JOIN accounts sa ON t.sender_account_id = sa.id
       JOIN accounts ra ON t.recipient_account_id = ra.id
       JOIN users su ON sa.user_id = su.id
       JOIN users ru ON ra.user_id = ru.id
       WHERE t.sender_account_id = ? OR t.recipient_account_id = ?
       ORDER BY t.created_at DESC`,
      [accountId, accountId]
    );

    res.json(transactions);
  } catch (error) {
    console.error('Get transaction history error:', error);
    res.status(500).json({ message: 'Error fetching transaction history' });
  }
});

module.exports = router; 