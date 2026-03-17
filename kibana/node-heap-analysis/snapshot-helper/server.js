'use strict';

/**
 * HTTP server wrapping the CDP snapshot client.
 * Exposes simple REST endpoints so the lab.sh script can trigger snapshots
 * without needing Chrome open.
 */

const http  = require('http');
const fs    = require('fs');
const path  = require('path');
const { captureSnapshot, getInspectorTargets } = require('./cdp');

const SNAPSHOTS_DIR = process.env.SNAPSHOTS_DIR || '/snapshots';
const PORT = 3001;

function writeJson(res, obj, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(obj, null, 2));
}

let snapshotInProgress = false;

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');

  // POST /snapshot  – take a heap snapshot of Kibana
  if (req.method === 'POST' && url.pathname === '/snapshot') {
    if (snapshotInProgress) {
      return writeJson(res, { ok: false, error: 'Snapshot already in progress' }, 409);
    }
    snapshotInProgress = true;
    try {
      const result = await captureSnapshot();
      writeJson(res, { ok: true, ...result });
    } catch (err) {
      console.error('[server] Snapshot failed:', err.message);
      writeJson(res, { ok: false, error: err.message }, 500);
    } finally {
      snapshotInProgress = false;
    }
    return;
  }

  // GET /targets  – list CDP inspector targets (Kibana processes)
  if (req.method === 'GET' && url.pathname === '/targets') {
    try {
      const targets = await getInspectorTargets();
      return writeJson(res, { targets });
    } catch (err) {
      return writeJson(res, { ok: false, error: err.message }, 500);
    }
  }

  // GET /snapshots  – list saved snapshots
  if (req.method === 'GET' && url.pathname === '/snapshots') {
    fs.mkdirSync(SNAPSHOTS_DIR, { recursive: true });
    const files = fs.readdirSync(SNAPSHOTS_DIR)
      .filter(f => f.endsWith('.heapsnapshot'))
      .map(f => {
        const stat = fs.statSync(path.join(SNAPSHOTS_DIR, f));
        return { file: f, sizeMb: (stat.size / 1024 / 1024).toFixed(2), mtime: stat.mtime };
      })
      .sort((a, b) => new Date(b.mtime) - new Date(a.mtime));
    return writeJson(res, { snapshots: files });
  }

  // GET /snapshot/:file  – download a snapshot
  if (req.method === 'GET' && url.pathname.startsWith('/snapshot/')) {
    const file     = path.basename(url.pathname.replace('/snapshot/', ''));
    const filepath = path.join(SNAPSHOTS_DIR, file);
    if (!file.endsWith('.heapsnapshot') || !fs.existsSync(filepath)) {
      return writeJson(res, { error: 'not found' }, 404);
    }
    res.writeHead(200, {
      'Content-Type':        'application/octet-stream',
      'Content-Disposition': `attachment; filename="${file}"`,
    });
    return fs.createReadStream(filepath).pipe(res);
  }

  writeJson(res, {
    endpoints: {
      'GET  /targets':          'List Node.js inspector targets (Kibana processes)',
      'POST /snapshot':         'Capture Kibana heap snapshot via CDP',
      'GET  /snapshots':        'List saved snapshots',
      'GET  /snapshot/:file':   'Download a snapshot file',
    },
  });
});

server.listen(PORT, () => {
  console.log(`[snapshot-helper] Listening on http://localhost:${PORT}`);
  console.log(`[snapshot-helper] Inspector target: ${process.env.INSPECTOR_HOST}:${process.env.INSPECTOR_PORT}`);
});
