// Elastic APM + Restify Example
// Based on: https://www.elastic.co/docs/reference/apm/agents/nodejs/restify

// Add this to the very top of the first file loaded in your app
var apm = require('elastic-apm-node').start({
  serviceName: 'my-service-name',
  secretToken: 'hTQpenENkzgJrX8bjd', 
  serverUrl: 'https://1ba2ff1d5f344eccbb02806cd8445fcc.apm.asia-northeast1.gcp.cloud.es.io:443',
  environment: 'my-node',
  metricsInterval: '1m'
});


const restify = require('restify');

const server = restify.createServer({
  name: 'apm-restify-demo',
  version: '1.0.0'
});

server.get('/', function (req, res, next) {
  res.send('Hello from Restify with Elastic APM!');
  return next();
});

server.listen(18080, function () {
  console.log('%s listening at %s', server.name, server.url);
});
