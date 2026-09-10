// backend/src/controllers/users.controller.js
const db = require('../config/db');
const admin = require('../config/firebase');

// ── GET /users/:id ──────────────────────────────────────
exports.getUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query(
      `SELECT u.*,
        (SELECT COUNT(*) FROM connections c WHERE (c.requester_id = u.id OR c.receiver_id = u.id) AND c.status = 'accepted') AS connections_count,
        (SELECT COUNT(*) FROM notes n WHERE n.uploader_id = u.id AND n.is_approved = true) AS notes_count,
        (SELECT COALESCE(SUM(amount), 0) FROM points_ledger pl WHERE pl.user_id = u.id) AS points
       FROM users u WHERE u.id = $1`,
      [id]
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// ── GET /users/me ────────────────────────────────────────
exports.getMe = async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT u.*,
        (SELECT COUNT(*) FROM connections c WHERE (c.requester_id = u.id OR c.receiver_id = u.id) AND c.status = 'accepted') AS connections_count,
        (SELECT COUNT(*) FROM notes n WHERE n.uploader_id = u.id AND n.is_approved = true) AS notes_count,
        (SELECT COALESCE(SUM(amount), 0) FROM points_ledger pl WHERE pl.user_id = u.id) AS points
       FROM users u WHERE u.firebase_uid = $1`,
      [req.user.uid]
    );
    if (rows.length) return res.json(rows[0]);

    const email = req.user.email || '';
    const name = req.user.name || req.user.displayName || email.split('@')[0] || 'User';
    const photo = req.user.picture || req.user.photoURL || req.user.photo_url || null;

    const { rows: created } = await db.query(
      `INSERT INTO users (firebase_uid, email, name, photo_url)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email RETURNING *`,
      [req.user.uid, email, name, photo]
    );
    const { rows: withCounts } = await db.query(
      `SELECT u.*,
        (SELECT COUNT(*) FROM connections c WHERE (c.requester_id = u.id OR c.receiver_id = u.id) AND c.status = 'accepted') AS connections_count,
        (SELECT COUNT(*) FROM notes n WHERE n.uploader_id = u.id AND n.is_approved = true) AS notes_count,
        (SELECT COALESCE(SUM(amount), 0) FROM points_ledger pl WHERE pl.user_id = u.id) AS points
       FROM users u WHERE u.id = $1`,
      [created[0].id]
    );
    return res.json(withCounts[0] || created[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// ── PUT /users/:id/profile ──────────────────────────────
exports.updateProfile = async (req, res) => {
  try {
    const firebaseUid = req.user.uid;

    // Verify that the authenticated Firebase user exists
    const { rows: user } = await db.query(
      'SELECT id, firebase_uid FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );

    if (!user.length) {
      return res.status(404).json({ error: 'User not found' });
    }

    const {
      name,
      college,
      state,
      city,
      course,
      branch,
      year_of_study,
      bio,
      skills,
      profile_complete,
      photo_url,
    } = req.body;

    const { rows } = await db.query(
      `UPDATE users SET
         name = COALESCE($1, name),
         college = COALESCE($2, college),
         state = COALESCE($3, state),
         city = COALESCE($4, city),
         course = COALESCE($5, course),
         branch = COALESCE($6, branch),
         year_of_study = COALESCE($7, year_of_study),
         bio = COALESCE($8, bio),
         skills = COALESCE($9, skills),
         profile_complete = COALESCE($10, profile_complete),
         photo_url = COALESCE($11, photo_url),
         updated_at = NOW()
       WHERE firebase_uid = $12
       RETURNING *`,
      [
        name,
        college,
        state,
        city,
        course,
        branch,
        year_of_study,
        bio,
        skills,
        profile_complete,
        photo_url,
        firebaseUid,
      ]
    );

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// ── POST /users/:id/photo ──────────────────────────────
exports.uploadPhoto = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file' });
    const firebaseUid = req.user.uid;
    const fileUrl = `/uploads/${req.file.filename}`;
    const { rows } = await db.query(
      `UPDATE users SET photo_url = $1, updated_at = NOW() WHERE firebase_uid = $2 RETURNING *`,
      [fileUrl, firebaseUid]
    );
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    const host = `${req.protocol}://${req.get('host')}`;
    const fullUrl = `${host}${fileUrl}`;
    res.json({ ...rows[0], photo_url: fullUrl, file_url: fullUrl });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// ── GET /connect/discover ────────────────────────────────
exports.discoverStudents = async (req, res) => {
  try {
    const { state, city, branch, year, skill, q, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const conditions = ['u.profile_complete = true', 'u.firebase_uid != $1'];
    const params = [req.user.uid];
    let pi = 2;

    if (state) { conditions.push(`u.state = $${pi++}`); params.push(state); }
    if (city) { conditions.push(`u.city = $${pi++}`); params.push(city); }
    if (branch) { conditions.push(`u.branch ILIKE $${pi++}`); params.push(`%${branch}%`); }
    if (year) { conditions.push(`u.year_of_study = $${pi++}`); params.push(parseInt(year)); }
    if (skill) { conditions.push(`$${pi++} = ANY(u.skills)`); params.push(skill); }
    if (q) {
      conditions.push(`(u.name ILIKE $${pi} OR u.college ILIKE $${pi})`);
      params.push(`%${q}%`); pi++;
    }

    params.push(parseInt(limit), parseInt(offset));

    const { rows } = await db.query(
      `SELECT u.id, u.name, u.college, u.city, u.state, u.branch, u.year_of_study,
              u.skills, u.photo_url, u.is_verified, u.is_premium,
              (SELECT COUNT(*) FROM connections c WHERE (c.requester_id = u.id OR c.receiver_id = u.id) AND c.status = 'accepted') AS connections_count
       FROM users u
       WHERE ${conditions.join(' AND ')}
       ORDER BY u.is_verified DESC, u.created_at DESC
       LIMIT $${pi++} OFFSET $${pi++}`,
      params
    );
    res.json({ data: rows, page: parseInt(page) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};
