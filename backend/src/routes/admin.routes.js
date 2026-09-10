// backend/src/routes/admin.routes.js
const router = require('express').Router();
const c = require('../controllers/admin.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');

// All admin routes require auth + admin claim
router.use(requireAuth, requireAdmin);

router.get('/stats', c.getStats);
router.get('/reports', c.getReports);
router.post('/reports/:id/resolve', c.resolveReport);
router.get('/jobs/pending', c.getPendingJobs);
router.put('/jobs/:id/approve', c.approveJob);
router.put('/notes/:id/approve', c.approveNote);
router.post('/broadcast', c.broadcast);
router.post('/points', c.grantPoints);

module.exports = router;
