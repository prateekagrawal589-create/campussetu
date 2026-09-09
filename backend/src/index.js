// backend/src/index.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');

// ── Routes ────────────────────────────────────────────────
const usersRouter = require('./routes/users.routes');
const postsRouter = require('./routes/posts.routes');
const connectRouter = require('./routes/connect.routes');
const tshareRouter = require('./routes/tshare.routes');
const notesRouter = require('./routes/notes.routes');
const jobsRouter = require('./routes/jobs.routes');
const productsRouter = require('./routes/products.routes');
const adminRouter = require('./routes/admin.routes');

const app = express();
app.set('trust proxy', 1);
const PORT = process.env.PORT || 3000;

// ── Security & Logging ─────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }));
app.use(morgan('dev'));
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Rate Limiting ──────────────────────────────────────────
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api', globalLimiter);

// ── Static files (uploaded notes) ──────────────────────────
app.use('/uploads', express.static(path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads')));

// ── API Routes ─────────────────────────────────────────────
app.use('/api/v1/users', usersRouter);
app.use('/api/v1/feed', postsRouter);
app.use('/api/v1/posts', postsRouter);
app.use('/api/v1/connect', connectRouter);
app.use('/api/v1/tshare', tshareRouter);
app.use('/api/v1/notes', notesRouter);
app.use('/api/v1/jobs', jobsRouter);
app.use('/api/v1/products', productsRouter);
app.use('/api/v1/admin', adminRouter);

// ── Health check ───────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', ts: new Date().toISOString(), env: process.env.NODE_ENV });
});
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', ts: new Date().toISOString(), env: process.env.NODE_ENV });
});
app.get('/api/v1/chats', (req, res) => {
  res.json([]);
});

// ── 404 handler ────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` });
});

// ── Error handler ──────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

// ── Start ──────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀  CampusSetu API running at http://localhost:${PORT}`);
  console.log(`📊  Health: http://localhost:${PORT}/health`);
  console.log(`🌍  ENV: ${process.env.NODE_ENV || 'development'}\n`);
});

module.exports = app;
