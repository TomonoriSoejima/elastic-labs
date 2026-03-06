const fs = require("fs");
const path = require("path");

const targetOverrideFilePath =
  process.env.ELASTIC_APM_TARGET_OVERRIDE_PATH ||
  path.join(__dirname, "apm-target.override.json");

const readTargetOverride = () => {
  try {
    if (!fs.existsSync(targetOverrideFilePath)) return null;
    const text = fs.readFileSync(targetOverrideFilePath, "utf8");
    const parsed = text ? JSON.parse(text) : null;
    if (!parsed?.serverUrl || !parsed?.secretToken) return null;
    return parsed;
  } catch {
    return null;
  }
};

const writeTargetOverride = (target) => {
  fs.writeFileSync(targetOverrideFilePath, JSON.stringify(target, null, 2), "utf8");
};

const activeTargetOverride = readTargetOverride();
const activeApmServerUrl = activeTargetOverride?.serverUrl || process.env.ELASTIC_APM_SERVER_URL;
const activeApmSecretToken =
  activeTargetOverride?.secretToken || process.env.ELASTIC_APM_SECRET_TOKEN;
const activeApmServiceName =
  activeTargetOverride?.serviceName || process.env.ELASTIC_APM_SERVICE_NAME || "demo-node";

if (activeApmServerUrl) process.env.ELASTIC_APM_SERVER_URL = activeApmServerUrl;
if (activeApmSecretToken) process.env.ELASTIC_APM_SECRET_TOKEN = activeApmSecretToken;
if (activeApmServiceName) process.env.ELASTIC_APM_SERVICE_NAME = activeApmServiceName;

const apm = require("elastic-apm-node").start({
  serviceName: activeApmServiceName,
  serverUrl: activeApmServerUrl,
  secretToken: activeApmSecretToken,
  environment: process.env.ELASTIC_APM_ENVIRONMENT || "repro",
  logLevel: process.env.ELASTIC_APM_LOG_LEVEL || "info",
  captureBody: "all",
});

const express = require("express");
const app = express();

const cloudApiBaseUrl =
  process.env.ELASTIC_CLOUD_API_BASE_URL || "https://api.elastic-cloud.com";
const cloudApiPrefix = process.env.ELASTIC_CLOUD_API_PREFIX || "/api/v1";
const cloudAuthScheme = process.env.ELASTIC_CLOUD_AUTH_SCHEME || "ApiKey";
const configuredKibanaUrl = process.env.ELASTIC_APM_KIBANA_URL || "";
const pythonWorkerBaseUrl = process.env.PYTHON_WORKER_URL || "http://python-worker:3001";
const javaWorkerBaseUrl = process.env.JAVA_WORKER_URL || "http://java-worker:3002";
const goWorkerBaseUrl = process.env.GO_WORKER_URL || "http://go-worker:3003";

app.use(express.static("public"));
app.use(express.json());

const runWork = async () => {
  let x = 0;
  for (let i = 0; i < 2000000; i++) x += i % 7;
  await new Promise((r) => setTimeout(r, 80));
  return x;
};

const postJson = async (url, payload) => {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const text = await response.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch {
    body = { raw: text };
  }
  if (!response.ok) {
    const error = new Error(`HTTP ${response.status}`);
    error.statusCode = response.status;
    error.payload = body;
    throw error;
  }
  return body;
};

const toCloudUrl = (path) => {
  if (/^https?:\/\//.test(path)) return path;
  const normalizedPath = path.startsWith("/api/")
    ? path
    : `${cloudApiPrefix}${path.startsWith("/") ? "" : "/"}${path}`;
  return `${cloudApiBaseUrl.replace(/\/$/, "")}${normalizedPath}`;
};

const getCloudApiKey = (req) =>
  req.get("x-elastic-cloud-api-key") || process.env.ELASTIC_CLOUD_API_KEY || "";

const cloudGetJson = async (req, path) => {
  const apiKey = getCloudApiKey(req);
  if (!apiKey) {
    const error = new Error("Missing Elastic Cloud API key");
    error.statusCode = 400;
    throw error;
  }

  const response = await fetch(toCloudUrl(path), {
    headers: {
      Authorization: `${cloudAuthScheme} ${apiKey}`,
      "Content-Type": "application/json",
    },
  });

  const text = await response.text();
  let payload;
  try {
    payload = text ? JSON.parse(text) : {};
  } catch {
    payload = { raw: text };
  }

  if (!response.ok) {
    const error = new Error(`Elastic Cloud API error (${response.status})`);
    error.statusCode = response.status;
    error.payload = payload;
    throw error;
  }

  return payload;
};

const extractDeployments = (payload) => {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.deployments)) return payload.deployments;
  return [];
};

const getDeploymentId = (deployment) =>
  deployment?.id || deployment?.deployment_id || deployment?.resources?.id;

const hasHostInObject = (value, host) => {
  if (!host) return false;
  if (typeof value === "string") return value.includes(host);
  if (Array.isArray(value)) return value.some((item) => hasHostInObject(item, host));
  if (value && typeof value === "object") {
    return Object.values(value).some((item) => hasHostInObject(item, host));
  }
  return false;
};

const findApmRefId = (deployment) => {
  const apmResources = deployment?.resources?.apm;
  if (Array.isArray(apmResources) && apmResources.length > 0) {
    return apmResources[0].ref_id || apmResources[0].refId || "main-apm";
  }
  return "main-apm";
};

const getDeploymentVersion = (deployment) => {
  const esResources = deployment?.resources?.elasticsearch;
  if (Array.isArray(esResources) && esResources.length > 0) {
    const info = esResources[0]?.info || {};
    return (
      info.service_version ||
      info.plan_info?.current?.plan?.elasticsearch?.version ||
      ""
    );
  }
  return "";
};

const serializeDeployment = (deployment) => ({
  id: getDeploymentId(deployment),
  shortId: String(getDeploymentId(deployment) || "").slice(0, 6),
  name: deployment?.name || deployment?.alias || "",
  version: getDeploymentVersion(deployment),
  healthy: deployment?.healthy,
  resources: {
    hasElasticsearch: Boolean(deployment?.resources?.elasticsearch?.length),
    hasKibana: Boolean(deployment?.resources?.kibana?.length),
    hasApm: Boolean(deployment?.resources?.apm?.length),
    hasIntegrationsServer: Boolean(deployment?.resources?.integrations_server?.length),
  },
});

const extractApmTarget = (deploymentPayload) => {
  const deployment = deploymentPayload?.resources ? deploymentPayload : deploymentPayload?.deployment;
  if (!deployment) return null;


  const integration = deployment?.resources?.integrations_server?.[0];
  const integrationInfo = integration?.info || {};
  const metadata = integrationInfo?.metadata || {};
  const servicesUrls = Array.isArray(metadata?.services_urls) ? metadata.services_urls : [];
  const apmServiceUrl =
    servicesUrls.find((item) => item?.service === "apm")?.url ||
    metadata?.service_url ||
    metadata?.aliased_url ||
    "";

  const secretToken =
    integrationInfo?.plan_info?.current?.plan?.integrations_server?.system_settings?.secret_token ||
    "";

  const kibanaMetadata = deployment?.resources?.kibana?.[0]?.info?.metadata || {};
  const kibanaBaseUrl = kibanaMetadata?.aliased_url || kibanaMetadata?.service_url || "";
  const kibanaApmServicesUrl = kibanaBaseUrl ? `${kibanaBaseUrl.replace(/\/$/, "")}/app/apm/services` : "";

  return {
    deploymentId: getDeploymentId(deployment),
    deploymentName: deployment?.name || "",
    version: getDeploymentVersion(deployment),
    apmServerUrl: apmServiceUrl,
    secretToken,
    kibanaApmServicesUrl,
    apmRefId: findApmRefId(deployment),
  };
};

app.get("/info", (_req, res) => {
  res.json({
    serviceName: activeApmServiceName,
    environment: process.env.ELASTIC_APM_ENVIRONMENT || "repro",
    serverUrl: activeApmServerUrl || "",
    kibanaUrl: configuredKibanaUrl,
    targetSource: activeTargetOverride ? "override" : "env",
    activeTarget: {
      deploymentId: activeTargetOverride?.deploymentId || "",
      deploymentName: activeTargetOverride?.deploymentName || "",
      kibanaApmServicesUrl: activeTargetOverride?.kibanaApmServicesUrl || "",
      activatedAt: activeTargetOverride?.activatedAt || "",
    },
  });
});

app.post("/apm/activate-target", (req, res) => {
  try {
    const serverUrl = String(req.body?.serverUrl || "").trim();
    const secretToken = String(req.body?.secretToken || "").trim();
    const deploymentId = String(req.body?.deploymentId || "").trim();
    const deploymentName = String(req.body?.deploymentName || "").trim();
    const kibanaApmServicesUrl = String(req.body?.kibanaApmServicesUrl || "").trim();
    const serviceName = String(req.body?.serviceName || "").trim();

    if (!serverUrl || !secretToken) {
      return res.status(400).json({
        ok: false,
        message: "serverUrl and secretToken are required",
      });
    }

    writeTargetOverride({
      serverUrl,
      secretToken,
      deploymentId,
      deploymentName,
      kibanaApmServicesUrl,
      serviceName,
      activatedAt: new Date().toISOString(),
    });

    fetch(`${pythonWorkerBaseUrl}/internal/restart`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    }).catch(() => {
      // best-effort
    });

    fetch(`${javaWorkerBaseUrl}/internal/restart`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    }).catch(() => {
      // best-effort
    });

    fetch(`${goWorkerBaseUrl}/internal/restart`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    }).catch(() => {
      // best-effort
    });

    res.json({ ok: true, message: "APM target activated. Restarting app to apply new destination..." });

    setTimeout(() => {
      process.exit(0);
    }, 300);
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: error.message,
    });
  }
});

app.get("/cloud/list-deployments", async (req, res) => {
  try {
    const payload = await cloudGetJson(req, "/deployments");
    const deployments = extractDeployments(payload).map(serializeDeployment);
    res.json({ ok: true, count: deployments.length, deployments });
  } catch (error) {
    res.status(error.statusCode || 500).json({
      ok: false,
      message: error.message,
      details: error.payload || null,
    });
  }
});

app.get("/cloud/deployments/:deploymentId", async (req, res) => {
  try {
    const payload = await cloudGetJson(req, `/deployments/${req.params.deploymentId}`);
    res.json({ ok: true, deployment: payload });
  } catch (error) {
    res.status(error.statusCode || 500).json({
      ok: false,
      message: error.message,
      details: error.payload || null,
    });
  }
});

app.get("/cloud/deployments/:deploymentId/apm-resource-info", async (req, res) => {
  try {
    const refId = String(req.query.refId || "main-apm");
    const candidatePaths = [
      `/deployments/${req.params.deploymentId}/apm/${refId}/_info`,
      `/deployments/${req.params.deploymentId}/apm/${refId}/info`,
      `/deployments/${req.params.deploymentId}/apm/${refId}`,
    ];

    let payload;
    let lastError;
    for (const path of candidatePaths) {
      try {
        payload = await cloudGetJson(req, path);
        break;
      } catch (error) {
        lastError = error;
        if (error.statusCode !== 404) throw error;
      }
    }

    if (!payload) throw lastError || new Error("Unable to load APM resource info");

    res.json({ ok: true, deploymentId: req.params.deploymentId, refId, info: payload });
  } catch (error) {
    res.status(error.statusCode || 500).json({
      ok: false,
      message: error.message,
      details: error.payload || null,
    });
  }
});

app.get("/cloud/deployments/:deploymentId/apm-target", async (req, res) => {
  try {
    const payload = await cloudGetJson(req, `/deployments/${req.params.deploymentId}`);
    const target = extractApmTarget(payload);

    if (!target || !target.apmServerUrl) {
      return res.status(404).json({
        ok: false,
        message: "No APM target data found for this deployment",
      });
    }

    res.json({ ok: true, target });
  } catch (error) {
    res.status(error.statusCode || 500).json({
      ok: false,
      message: error.message,
      details: error.payload || null,
    });
  }
});

app.get("/cloud/discover", async (req, res) => {
  try {
    const requestedKibanaUrl = String(req.query.kibanaUrl || configuredKibanaUrl || "");
    if (!requestedKibanaUrl) {
      return res.status(400).json({
        ok: false,
        message: "Missing kibanaUrl query parameter (or ELASTIC_APM_KIBANA_URL env var)",
      });
    }

    const kibanaHost = new URL(requestedKibanaUrl).host;
    const payload = await cloudGetJson(req, "/deployments");
    const deployments = extractDeployments(payload);
    let matched = deployments.find((deployment) => hasHostInObject(deployment, kibanaHost));
    let matchedDetails = matched || null;

    if (!matched) {
      for (const deployment of deployments) {
        const deploymentId = getDeploymentId(deployment);
        if (!deploymentId) continue;

        const details = await cloudGetJson(req, `/deployments/${deploymentId}`);
        if (hasHostInObject(details, kibanaHost)) {
          matched = deployment;
          matchedDetails = details;
          break;
        }
      }
    }

    if (!matched) {
      return res.status(404).json({
        ok: false,
        message: `No deployment matched Kibana host: ${kibanaHost}`,
      });
    }

    const deploymentId = getDeploymentId(matched);
    const apmRefId = findApmRefId(matchedDetails || matched);
    res.json({
      ok: true,
      kibanaHost,
      deploymentId,
      apmRefId,
      deployment: serializeDeployment(matchedDetails || matched),
    });
  } catch (error) {
    res.status(error.statusCode || 500).json({
      ok: false,
      message: error.message,
      details: error.payload || null,
    });
  }
});

app.get("/health", (_req, res) => res.json({ ok: true }));

app.get("/work", async (_req, res) => {
  const language = String(_req.query.language || "js");
  const deploymentId = String(_req.query.deploymentId || "");

  if (language === "python") {
    try {
      const result = await fetch(
        `${pythonWorkerBaseUrl}/work?language=${encodeURIComponent(language)}&deploymentId=${encodeURIComponent(deploymentId)}`
      );
      const body = await result.json();
      return res.status(result.status).json(body);
    } catch (error) {
      return res.status(502).json({ ok: false, message: "Python worker unavailable", details: error.message });
    }
  }

  if (language === "java") {
    try {
      const result = await fetch(
        `${javaWorkerBaseUrl}/work?language=${encodeURIComponent(language)}&deploymentId=${encodeURIComponent(deploymentId)}`
      );
      const body = await result.json();
      return res.status(result.status).json(body);
    } catch (error) {
      return res.status(502).json({ ok: false, message: "Java worker unavailable", details: error.message });
    }
  }

  if (language === "go") {
    try {
      const result = await fetch(
        `${goWorkerBaseUrl}/work?language=${encodeURIComponent(language)}&deploymentId=${encodeURIComponent(deploymentId)}`
      );
      const body = await result.json();
      return res.status(result.status).json(body);
    } catch (error) {
      return res.status(502).json({ ok: false, message: "Go worker unavailable", details: error.message });
    }
  }

  apm.setLabel("test_language", language);
  if (deploymentId) apm.setLabel("test_deployment_id", deploymentId);

  const started = Date.now();
  const x = await runWork();
  res.json({ ok: true, x, durationMs: Date.now() - started, language, deploymentId });
});

app.post("/work/batch", async (req, res) => {
  const requestedCount = Number(req.body?.count || 1);
  const count = Math.min(Math.max(requestedCount, 1), 1000);
  const language = String(req.body?.language || "js");
  const deploymentId = String(req.body?.deploymentId || "");

  if (language === "python") {
    try {
      const body = await postJson(`${pythonWorkerBaseUrl}/work/batch`, {
        count,
        language,
        deploymentId,
      });
      return res.json(body);
    } catch (error) {
      return res.status(error.statusCode || 502).json({
        ok: false,
        message: "Python worker batch failed",
        details: error.payload || error.message,
      });
    }
  }

  if (language === "java") {
    try {
      const body = await postJson(`${javaWorkerBaseUrl}/work/batch`, {
        count,
        language,
        deploymentId,
      });
      return res.json(body);
    } catch (error) {
      return res.status(error.statusCode || 502).json({
        ok: false,
        message: "Java worker batch failed",
        details: error.payload || error.message,
      });
    }
  }

  if (language === "go") {
    try {
      const body = await postJson(`${goWorkerBaseUrl}/work/batch`, {
        count,
        language,
        deploymentId,
      });
      return res.json(body);
    } catch (error) {
      return res.status(error.statusCode || 502).json({
        ok: false,
        message: "Go worker batch failed",
        details: error.payload || error.message,
      });
    }
  }

  apm.setLabel("test_language", language);
  if (deploymentId) apm.setLabel("test_deployment_id", deploymentId);

  const started = Date.now();

  for (let i = 0; i < count; i++) {
    await runWork();
  }

  res.json({ ok: true, count, durationMs: Date.now() - started, language, deploymentId });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  console.log(`listening on ${port}`);
});