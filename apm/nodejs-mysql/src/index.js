const express = require('express');
const apm = require('elastic-apm-node').start({
  serviceName: process.env.ELASTIC_APM_SERVICE_NAME || 'my-mysql-name',
  secretToken: process.env.ELASTIC_APM_SECRET_TOKEN || 'KccJBiegUMyJYwYH8y',
  serverUrl: process.env.ELASTIC_APM_SERVER_URL || 'https://cedeca8f6b694f5aa9cb7a29816a539a.apm.asia-northeast1.gcp.cloud.es.io:443',
  environment: process.env.ELASTIC_APM_ENVIRONMENT || 'my-environment'
});

const pool = require('../config/db');
const app = express();

app.get('/users', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users');
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Database error' });
  }
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
