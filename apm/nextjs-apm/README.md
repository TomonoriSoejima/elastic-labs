# Next.js with Elastic APM

Next.js application starter with Elastic APM instrumentation.

## Structure

```
nextjs-elastic-apm-starter/
  - Next.js application
  - Elastic APM Node.js configuration
```

## Setup

```bash
cd nextjs-elastic-apm-starter
npm install
```

## Run Development Server

```bash
npm run dev
```

Visit http://localhost:3000

## Build

```bash
npm run build
npm start
```

## APM Configuration

Edit `elastic-apm-node.js` to configure:
- Server URL
- Service name
- Environment
- API key

## Notes

- .next/ build output is gitignored
- Requires Node.js 18+
- APM captures both server-side and API routes
