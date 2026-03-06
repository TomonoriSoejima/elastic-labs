export default function handler(req, res) {
  const start = Date.now();
  while (Date.now() - start < 30) {
    // busy wait 30ms
  }
  res.status(200).json({ message: 'Hello from Next.js API route!' });
}