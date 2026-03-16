import { SyntheticsConfig } from "@elastic/synthetics";

// Mirrors customer config from STACK-3058
// Note: no `environment` field in project block (not a valid field)
const env = process.env.NODE_ENV || "staging";

console.log(`[synthetics.config] NODE_ENV = "${process.env.NODE_ENV}", resolved env = "${env}"`);

type Env = "staging" | "production";

const ENV_PARAMS: Record<Env, { kibanaUrl: string }> = {
  staging:    { kibanaUrl: process.env.STAGING_KIBANA_URL ?? "" },
  production: { kibanaUrl: process.env.PROD_KIBANA_URL ?? "" },
};

const isPush = process.argv.includes("push");

const config: SyntheticsConfig = {
  params: isPush ? undefined : ENV_PARAMS[env as Env],
  monitor: {
    schedule: 10,
    locations: ["singapore"],
  },
  project: {
    id: "lab-synthetics-project",
    url: ENV_PARAMS[env as Env]?.kibanaUrl,
    space: "default",
  },
};

export default config;
