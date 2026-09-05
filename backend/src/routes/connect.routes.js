// backend/src/routes/connect.routes.js
const router = require('express').Router();
const c = require('../controllers/connect.controller');
const { requireAuth } = require('../middleware/auth');

router.post('/request', requireAuth, c.sendRequest);
router.put('/:id/respond', requireAuth, c.respondRequest);
router.get('/my', requireAuth, c.getMyConnections);
router.get('/pending', requireAuth, c.getPendingRequests);

module.exports = router;
