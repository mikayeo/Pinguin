const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// Create a new payment
router.post('/', auth, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { payment_type, reference_number, amount } = req.body;
    const userId = req.user.userId;

    // Validate required fields
    if (!payment_type || !reference_number || !amount) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Get user's current balance
    const [accounts] = await connection.query(
      'SELECT balance FROM accounts WHERE user_id = ?',
      [userId]
    );

    if (accounts.length === 0) {
      await connection.rollback();
      return res.status(404).json({ message: 'Account not found' });
    }

    const currentBalance = accounts[0].balance;
    if (currentBalance < amount) {
      await connection.rollback();
      return res.status(400).json({ message: 'Insufficient funds' });
    }

    // Update account balance
    await connection.query(
      'UPDATE accounts SET balance = balance - ? WHERE user_id = ?',
      [amount, userId]
    );

    // Create payment record
    const [result] = await connection.query(
      'INSERT INTO payments (user_id, payment_type, reference_number, amount, status) VALUES (?, ?, ?, ?, ?)',
      [userId, payment_type, reference_number, amount, 'completed']
    );
    
    const paymentId = result.insertId;

    // Get the created payment
    const [payments] = await connection.query(
      'SELECT * FROM payments WHERE id = ?',
      [paymentId]
    );
    
    await connection.commit();
    res.status(201).json(payments[0]);
  } catch (error) {
    console.error('Error creating payment:', error);
    await connection.rollback();
    res.status(500).json({ message: 'Error creating payment' });
  } finally {
    connection.release();
  }
});

// Get user's payment history
router.get('/history', auth, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user.userId;
    
    const [payments] = await connection.query(
      'SELECT * FROM payments WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );
    
    res.json(payments);
  } catch (error) {
    console.error('Error getting payment history:', error);
    res.status(500).json({ message: 'Error getting payment history' });
  } finally {
    connection.release();
  }
});

// Update payment status
router.patch('/:paymentId/status', auth, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const { paymentId } = req.params;
    const { status } = req.body;
    const userId = req.user.userId;

    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }

    // Update payment status
    const [result] = await connection.query(
      'UPDATE payments SET status = ? WHERE id = ? AND user_id = ?',
      [status, paymentId, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Get updated payment
    const [payments] = await connection.query(
      'SELECT * FROM payments WHERE id = ?',
      [paymentId]
    );

    res.json(payments[0]);
  } catch (error) {
    console.error('Error updating payment status:', error);
    res.status(500).json({ message: 'Error updating payment status' });
  } finally {
    connection.release();
  }
});

module.exports = router;
