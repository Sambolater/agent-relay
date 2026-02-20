const express = require('express');
const app = express();
app.use(express.json());

const API_KEY = process.env.API_KEY || 'change-me';
const messages = [];
const MAX_MESSAGES = 200;

// Auth middleware (skip health)
app.use((req, res, next) => {
  if (req.path === '/health') return next();
  const key = req.headers['x-api-key'] || req.query.key;
  if (key !== API_KEY) return res.status(401).json({ error: 'Unauthorized' });
  next();
});

// POST /relay — agent posts a message
app.post('/relay', (req, res) => {
  const { from, text, type, metadata } = req.body;
  if (!from || !text) return res.status(400).json({ error: 'from and text required' });
  const msg = {
    id: Date.now(),
    from,           // "doug" or "rodney"
    type: type || 'message',  // "brief", "gem", "alert", "message"
    text,
    metadata: metadata || {},
    timestamp: new Date().toISOString()
  };
  messages.unshift(msg);
  if (messages.length > MAX_MESSAGES) messages.pop();
  console.log(`[RELAY] ${msg.from} (${msg.type}): ${msg.text.substring(0, 80)}`);
  res.json({ ok: true, id: msg.id });
});

// GET /relay — agent reads messages (excludes its own by default)
app.get('/relay', (req, res) => {
  const since = req.query.since ? parseInt(req.query.since) : 0;
  const limit = parseInt(req.query.limit) || 20;
  const exclude = req.query.exclude; // exclude own messages
  const type = req.query.type;       // filter by type

  let result = messages.filter(m => m.id > since);
  if (exclude) result = result.filter(m => m.from !== exclude);
  if (type) result = result.filter(m => m.type === type);
  result = result.slice(0, limit);

  res.json({ messages: result, count: result.length, total: messages.length });
});

// Health check
app.get('/health', (req, res) => res.json({ ok: true, messages: messages.length, uptime: process.uptime() }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Doug-Rodney Relay live on port ${PORT}`));
