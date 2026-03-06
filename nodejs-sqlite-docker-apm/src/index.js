var apm = require('elastic-apm-node').start({
    serviceName: 'my-service-name',
    secretToken: 'YOUR_SECRET_TOKEN_HERE',
    serverUrl: 'https://YOUR_CLUSTER_ID.apm.REGION.cloud.es.io:443',
    environment: 'my-environment'
  });
  
  const express = require('express');
  const sqlite3 = require('sqlite3').verbose();
  const fs = require('fs');
  const app = express();
  const port = 3000;
  
  const dbFile = './db/database.sqlite';
  const dbExists = fs.existsSync(dbFile);
  const db = new sqlite3.Database(dbFile, (err) => {
      if (err) {
          console.error(err.message);
      } else {
          console.log('Connected to SQLite database.');
      }
  });
  
  // Create table if it doesn't exist
  db.serialize(() => {
      db.run(`CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE
      )`);
  
      if (!dbExists) {
          // Seed initial data only if database is newly created
          db.run(`INSERT INTO users (name, email) VALUES 
          ('John Doe', 'john@example.com'),
          ('Jane Doe', 'jane@example.com')`);
      }
  });
  
  app.use(express.json());
  
  app.get('/users', (req, res) => {
      db.all('SELECT * FROM users', [], (err, rows) => {
          if (err) {
              res.status(500).json({ error: err.message });
              return;
          }
          res.json(rows);
      });
  });
  
  app.post('/users', (req, res) => {
      const { name, email } = req.body;
      db.run('INSERT INTO users (name, email) VALUES (?, ?)', [name, email], function(err) {
          if (err) {
              res.status(500).json({ error: err.message });
              return;
          }
          res.json({ id: this.lastID });
      });
  });
  
  app.listen(port, () => {
      console.log(`Server running on port ${port}`);
  });
  