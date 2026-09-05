// backend/src/middleware/auth.js
const admin = require('../config/firebase');

const _cache = new Map();
const CACHE_TTL_MS = 5 * 60 * 1000;

function getCached(token) {
  const e = _cache.get(token);
  if (!e) return null;
  if (Date.now() - e.ts > CACHE_TTL_MS) { _cache.delete(token); return null; }
  return e.decoded;
}
function setCached(token, decoded) {
  if (_cache.size > 500) _cache.clear();
  _cache.set(token, { decoded, ts: Date.now() });
}

/**
 * Verifies Firebase ID token from Authorization header.
 * Attaches decoded token as req.user. Cached for 5 min for speed.
 */
const requireAuth = async (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    const idToken = header.split('Bearer ')[1];
    if (!idToken || idToken.length < 20) return res.status(401).json({ error: 'Invalid token' });

    const cached = getCached(idToken);
    if (cached) { req.user = cached; return next(); }

    const decoded = await admin.auth().verifyIdToken(idToken, true);
    setCached(idToken, decoded);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized: ' + err.message });
  }
};

/**
 * Requires the requesting user to be an admin.
 * Must be used AFTER requireAuth.
 */
const requireAdmin = async (req, res, next) => {
  try {
    const { customClaims } = await admin.auth().getUser(req.user.uid);
    if (!customClaims?.admin) {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Forbidden: ' + err.message });
  }
};

module.exports = { requireAuth, requireAdmin };