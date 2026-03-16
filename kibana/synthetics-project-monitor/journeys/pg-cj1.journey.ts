import { journey, step } from "@elastic/synthetics";

// Reproduces STACK-3058:
// Both journeys below use the same base name "pg-cj1" but with env suffix (the workaround).
// Pushing both at once to a single deployment simulates what you'd see across 2 deployments.

const env = process.env.NODE_ENV || "staging";

// --- BEFORE workaround: same ID regardless of env (the bug) ---
journey("pg-cj1", async ({ page }) => {
  step("User loads landing page", async () => {
    await page.goto("https://example.com");
  });
});

// --- AFTER workaround: unique ID per env ---
journey(`pg-cj1-${env}`, async ({ page }) => {
  step("User loads landing page", async () => {
    await page.goto("https://example.com");
  });
});
