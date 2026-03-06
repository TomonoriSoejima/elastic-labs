# Next.js + Elastic APM (Node.js agent) — Starter

This project instruments the Next.js server (pages & API routes) with Elastic APM using `elastic-apm-node`.

## Install

```bash
npm install
```

## Develop

```bash
npm run dev
# open http://localhost:3000
```

Generate traffic:

```bash
while true; do sleep 1; curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/hello; done
```

## Production

```bash
npm run build && npm start
```

## Notes
- Edit `elastic-apm-node.js` with your values.
- Supports next >=12.0.0 <13.3.0.
- Server-side metrics only; add RUM separately for client-side.
