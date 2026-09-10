// backend/src/controllers/admin.controller.js
const db = require('../config/db');
const admin = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

// ── POST /admin/points {user_id | campus_id, amount, reason?} ──
// Admin can grant (or revoke with negative amount) any points
exports.grantPoints = async (req, res) => {
  try {
    const { user_id, campus_id, amount, reason } = req.body;
    const pts = parseInt(amount);
    if (!pts || pts === 0) return res.status(400).json({ error: 'valid non-zero amount required' });
    if (Math.abs(pts) > 1000000) return res.status(400).json({ error: 'amount too large' });

    let targetId = user_id;
    if (!targetId && campus_id) {
      const { rows } = await db.query('SELECT id FROM users WHERE UPPER(campus_id) = $1', [String(campus_id).trim().toUpperCase()]);
      if (!rows.length) return res.status(404).json({ error: 'Student not found' });
      targetId = rows[0].id;
    }
    if (!targetId) return res.status(400).json({ error: 'user_id or campus_id required' });

    const { rows: u } = await db.query('SELECT id, name FROM users WHERE id = $1', [targetId]);
    if (!u.length) return res.status(404).json({ error: 'Student not found' });

    await db.query(
      `INSERT INTO points_ledger (id, user_id, amount, reason) VALUES ($1,$2,$3,$4)`,
      [uuidv4(), targetId, pts, `admin_grant:${(reason || 'reward').toString().slice(0, 60)}`]
    );
    const { rows: b } = await db.query('SELECT COALESCE(SUM(amount),0)::int AS bal FROM points_ledger WHERE user_id = $1', [targetId]);
    res.json({ user_id: targetId, name: u[0].name, granted: pts, new_balance: b[0].bal });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /admin/stats ──────────────────────────────────────
exports.getStats = async (req, res) => {
  try {
    const [users, posts, reports, pendingJobs] = await Promise.all([
      db.query('SELECT COUNT(*) FROM users'),
      db.query('SELECT COUNT(*) FROM posts WHERE is_deleted = false'),
      db.query("SELECT COUNT(*) FROM reports WHERE status = 'pending'"),
      db.query("SELECT COUNT(*) FROM jobs WHERE is_approved = false"),
    ]);
    res.json({
      total_users: parseInt(users.rows[0].count),
      total_posts: parseInt(posts.rows[0].count),
      pending_reports: parseInt(reports.rows[0].count),
      pending_jobs: parseInt(pendingJobs.rows[0].count),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /admin/reports ────────────────────────────────────
exports.getReports = async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT r.*, row_to_json(u.*) AS reporter
       FROM reports r JOIN users u ON u.id = r.reporter_id
       WHERE r.status = 'pending'
       ORDER BY r.created_at DESC LIMIT 50`
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── POST /admin/reports/:id/resolve ───────────────────────
exports.resolveReport = async (req, res) => {
  try {
    const { action } = req.body; // 'dismiss' | 'delete_content' | 'ban_user'
    const { rows: report } = await db.query(
      `UPDATE reports SET status = 'resolved', resolution = $1, resolved_at = NOW()
       WHERE id = $2 RETURNING *`,
      [action, req.params.id]
    );
    if (!report.length) return res.status(404).json({ error: 'Report not found' });

    if (action === 'delete_content' && report[0].target_type === 'post') {
      await db.query('UPDATE posts SET is_deleted = true WHERE id = $1', [report[0].target_id]);
    }
    if (action === 'ban_user') {
      await db.query('UPDATE users SET is_banned = true WHERE id = $1', [report[0].reported_user_id]);
      await admin.auth().updateUser(report[0].firebase_uid, { disabled: true });
    }

    res.json(report[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /admin/jobs/pending ───────────────────────────────
exports.getPendingJobs = async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT j.*, row_to_json(u.*) AS posted_by
       FROM jobs j JOIN users u ON u.id = j.poster_id
       WHERE j.is_approved = false ORDER BY j.created_at DESC`
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── PUT /admin/jobs/:id/approve ───────────────────────────
exports.approveJob = async (req, res) => {
  try {
    const { rows } = await db.query(
      'UPDATE jobs SET is_approved = true WHERE id = $1 RETURNING *',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Job not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── PUT /admin/notes/:id/approve ──────────────────────────
exports.approveNote = async (req, res) => {
  try {
    const { rows } = await db.query(
      'UPDATE notes SET is_approved = true WHERE id = $1 RETURNING *',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Note not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── POST /admin/broadcast ─────────────────────────────────
exports.broadcast = async (req, res) => {
  try {
    const { title, body, topic = 'all_students' } = req.body;
    const message = {
      notification: { title, body },
      topic,
    };
    const result = await admin.messaging().send(message);
    res.json({ success: true, messageId: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
