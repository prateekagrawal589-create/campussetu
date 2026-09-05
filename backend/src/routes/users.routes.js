// backend/src/routes/users.routes.js
const router = require('express').Router();
const c = require('../controllers/users.controller');
const { requireAuth } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.get('/me', requireAuth, c.getMe);
router.get('/discover', requireAuth, c.discoverStudents);
router.get('/:id', requireAuth, c.getUser);
router.put('/:id/profile', requireAuth, validate(schemas.updateProfile), c.updateProfile);

module.exports = router;
