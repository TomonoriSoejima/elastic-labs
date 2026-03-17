'use strict';

/**
 * Minimal Chrome DevTools Protocol (CDP) client
 * Connects to a remote Node.js inspector and takes heap snapshots.
 *
 * This is the Node.js equivalent of triggering a Java heap dump via jcmd:
 *   jcmd <pid> GC.heap_dump /tmp/heap.hprof
 */

const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

const INSPECTOR_HOST = process.env.INSPECTOR_HOST || 'localhost';
const INSPECTOR_PORT = process.env.INSPECTOR_PORT || '9229';
const SNAPSHOTS_DIR  = process.env.SNAPSHOTS_DIR  || '/snapshots';

/**
 * Fetch the list of inspector targets from the HTTP endpoint.
 * e.g. http://kibana:9229/json
 */
function getInspectorTargets() {
  return new Promise((resolve, reject) => {
    // Node.js inspector validates the Host header and rejects anything other
    // than localhost/127.0.0.1, even when bound to 0.0.0.0
    const req = http.get({
      hostname: INSPECTOR_HOST,
      port:     INSPECTOR_PORT,
      path:     '/json',
      headers:  { Host: 'localhost' },
    }, res => {
      let data = '';
      res.on('data', chunk => (data += chunk));
      res.on('end', () => resolve(JSON.parse(data)));
    });
    req.on('error', reject);
    req.setTimeout(5000, () => {
      req.destroy(new Error('Timeout connecting to inspector'));
    });
  });
}

/**
 * Connect to the inspector WebSocket and take a heap snapshot.
 * Returns the local file path where the snapshot was saved.
 */
function takeHeapSnapshot(wsUrl, outputPath) {
  return new Promise((resolve, reject) => {
    // Same Host header override required for the WebSocket upgrade
    const ws = new WebSocket(wsUrl, { headers: { Host: 'localhost' } });
    const chunks = [];
    let cmdId = 1;

    function send(method, params = {}) {
      const msg = JSON.stringify({ id: cmdId++, method, params });
      ws.send(msg);
    }

    ws.on('open', () => {
      console.log(`[cdp] Connected to ${wsUrl}`);
      // Enable the HeapProfiler domain
      send('HeapProfiler.enable');
    });

    ws.on('message', raw => {
      const msg = JSON.parse(raw);

      // HeapProfiler.enable acknowledged → start snapshot
      if (msg.id === 1 && !msg.error) {
        console.log('[cdp] HeapProfiler enabled, starting snapshot…');
        send('HeapProfiler.takeHeapSnapshot', { reportProgress: false });
      }

      // Snapshot chunks streamed back as events
      if (msg.method === 'HeapProfiler.addHeapSnapshotChunk') {
        chunks.push(msg.params.chunk);
        process.stdout.write('.');
      }

      // Snapshot complete
      if (msg.method === 'HeapProfiler.reportHeapSnapshotProgress' &&
          msg.params.finished) {
        process.stdout.write('\n');
      }

      // takeHeapSnapshot command acknowledged (after all chunks received)
      if (msg.id === 2) {
        ws.close();
      }
    });

    ws.on('close', () => {
      const snapshot = chunks.join('');
      fs.writeFileSync(outputPath, snapshot);
      const sizeMb = (Buffer.byteLength(snapshot) / 1024 / 1024).toFixed(2);
      console.log(`[cdp] Snapshot saved → ${outputPath} (${sizeMb} MB)`);
      resolve(outputPath);
    });

    ws.on('error', reject);

    // Safety timeout: 5 minutes for large heaps
    setTimeout(() => reject(new Error('Snapshot timed out after 5 min')), 5 * 60 * 1000);
  });
}

async function captureSnapshot() {
  const targets = await getInspectorTargets();
  if (!targets.length) throw new Error('No inspector targets found');

  // Pick the first Node.js target (Kibana's main process)
  const target = targets[0];
  // Build the WebSocket URL directly from INSPECTOR_HOST:PORT + target ID
  // (avoids host-rewriting bugs caused by the Host header override above)
  const wsUrl = `ws://${INSPECTOR_HOST}:${INSPECTOR_PORT}/${target.id}`;
  console.log(`[cdp] Target: ${target.title || target.id}`);
  console.log(`[cdp] WebSocket: ${wsUrl}`);

  fs.mkdirSync(SNAPSHOTS_DIR, { recursive: true });
  const filename = `kibana-heap-${Date.now()}.heapsnapshot`;
  const filepath  = path.join(SNAPSHOTS_DIR, filename);

  await takeHeapSnapshot(wsUrl, filepath);
  return { filename, filepath };
}

module.exports = { captureSnapshot, getInspectorTargets };
