const pool = require('../db');

class Payment {
  static async create(userId, paymentType, referenceNumber, amount) {
    try {
      const [result] = await pool.query(
        'INSERT INTO payments (user_id, payment_type, reference_number, amount) VALUES (?, ?, ?, ?)',
        [userId, paymentType, referenceNumber, amount]
      );
      return result.insertId;
    } catch (error) {
      console.error('Error creating payment:', error);
      throw error;
    }
  }

  static async getByUserId(userId) {
    try {
      const [payments] = await pool.query(
        'SELECT * FROM payments WHERE user_id = ? ORDER BY created_at DESC',
        [userId]
      );
      return payments;
    } catch (error) {
      console.error('Error getting payments:', error);
      throw error;
    }
  }

  static async updateStatus(paymentId, status) {
    try {
      const [result] = await pool.query(
        'UPDATE payments SET status = ? WHERE id = ?',
        [status, paymentId]
      );
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Error updating payment status:', error);
      throw error;
    }
  }

  static async getById(paymentId) {
    try {
      const [payments] = await pool.query(
        'SELECT * FROM payments WHERE id = ?',
        [paymentId]
      );
      return payments[0];
    } catch (error) {
      console.error('Error getting payment:', error);
      throw error;
    }
  }
}
