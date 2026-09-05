// backend/src/config/db.js
// PostgreSQL connection pool
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  min: 2,
  idleTimeoutMillis: 10000,
  connectionTimeoutMillis: 2000,
  keepAlive: true,
});

pool.on('error', (err) => {
  console.error('Unexpected DB pool error:', err);
});

module.exports = pool;
