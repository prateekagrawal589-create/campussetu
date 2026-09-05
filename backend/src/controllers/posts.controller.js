// backend/src/controllers/posts.controller.js
const db = require('../config/db');

// ── GET /feed ────────────────────────────────────────────
exports.getFeed = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    // Get caller's DB id
    const { rows: me } = await db.query('SELECT id FROM users WHERE firebase_uid = $1', [req.user.uid]);
    if (!me.length) return res.status(404).json({ error: 'User not found' });
    const userId = me[0].id;

    const { rows } = await db.query(
      `SELECT p.*,
         row_to_json(u.*) AS author,
         (SELECT COUNT(*) FROM post_likes pl WHERE pl.post_id = p.id) AS likes_count,
         (SELECT COUNT(*) FROM post_comments pc WHERE pc.post_id = p.id) AS comments_count,
         EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.user_id = $1) AS is_liked
       FROM posts p
       JOIN users u ON u.id = p.author_id
       WHERE p.is_deleted = false
       ORDER BY p.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, parseInt(limit), parseInt(offset)]
    );
    res.json({ data: rows, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── POST /posts ──────────────────────────────────────────
exports.createPost = async (req, res) => {
  try {
    const { content, image_url } = req.body;
    const { rows: me } = await db.query('SELECT id FROM users WHERE firebase_uid = $1', [req.user.uid]);
    if (!me.length) return res.status(404).json({ error: 'User not found' });

    const { rows } = await db.query(
      'INSERT INTO posts (author_id, content, image_url) VALUES ($1, $2, $3) RETURNING *',
      [me[0].id, content, image_url || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── POST /posts/:id/like ──────────────────────────────────
exports.toggleLike = async (req, res) => {
  try {
    const { rows: me } = await db.query('SELECT id FROM users WHERE firebase_uid = $1', [req.user.uid]);
    if (!me.length) return res.status(404).json({ error: 'User not found' });
    const userId = me[0].id;

    const { rows: existing } = await db.query(
      'SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2',
      [req.params.id, userId]
    );

    if (existing.length) {
      await db.query('DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2', [req.params.id, userId]);
      res.json({ liked: false });
    } else {
      await db.query('INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)', [req.params.id, userId]);
      res.json({ liked: true });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /posts/:id/comments ──────────────────────────────
exports.getComments = async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT c.*, row_to_json(u.*) AS author
       FROM post_comments c JOIN users u ON u.id = c.author_id
       WHERE c.post_id = $1 ORDER BY c.created_at ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── POST /posts/:id/comment ───────────────────────────────
exports.addComment = async (req, res) => {
  try {
    const { content } = req.body;
    const { rows: me } = await db.query('SELECT id FROM users WHERE firebase_uid = $1', [req.user.uid]);
    if (!me.length) return res.status(404).json({ error: 'User not found' });

    const { rows } = await db.query(
      'INSERT INTO post_comments (post_id, author_id, content) VALUES ($1, $2, $3) RETURNING *',
      [req.params.id, me[0].id, content]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── DELETE /posts/:id ─────────────────────────────────────
exports.deletePost = async (req, res) => {
  try {
    const { rows: me } = await db.query('SELECT id FROM users WHERE firebase_uid = $1', [req.user.uid]);
    if (!me.length) return res.status(404).json({ error: 'User not found' });

    const { rows: post } = await db.query('SELECT author_id FROM posts WHERE id = $1', [req.params.id]);
    if (!post.length) return res.status(404).json({ error: 'Post not found' });
    if (post[0].author_id !== me[0].id) return res.status(403).json({ error: 'Forbidden' });

    await db.query('UPDATE posts SET is_deleted = true WHERE id = $1', [req.params.id]);
    res.json({ deleted: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
