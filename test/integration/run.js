// Every run owns a new local app and temporary MongoDB database. No deployment
// URL or production credentials are accepted by this runner.
const express = require('express');
const { ParseServer } = require('parse-server');
const { MongoMemoryServer } = require('mongodb-memory-server-core');
const { spawn } = require('node:child_process');
const { randomUUID } = require('node:crypto');
const os = require('node:os');
const path = require('node:path');

const mongoVersion = '8.0.17';
process.env.MONGOMS_DOWNLOAD_DIR ||= path.join(os.tmpdir(), 'parse-stack-mongodb-binaries');

class MemoryFilesAdapter {
  constructor(serverURL, appId) {
    this.serverURL = serverURL;
    this.appId = appId;
    this.files = new Map();
  }
  async createFile(name, data) { this.files.set(name, Buffer.from(data)); }
  async deleteFile(name) { this.files.delete(name); }
  async getFileData(name) {
    if (!this.files.has(name)) throw new Error('File not found');
    return this.files.get(name);
  }
  getFileLocation(_config, name) {
    return `${this.serverURL}/files/${this.appId}/${encodeURIComponent(name)}`;
  }
}

async function main() {
  let mongo, server, listener;
  try {
    mongo = await MongoMemoryServer.create({
      binary: { version: mongoVersion },
      instance: { ip: '127.0.0.1', dbName: `sdk_${randomUUID().replaceAll('-', '')}` },
    });
    const app = express();
    listener = await new Promise((resolve, reject) => {
      const http = app.listen(0, '127.0.0.1', () => resolve(http));
      http.once('error', reject);
    });
    const mountPath = '/sdk/parse';
    const serverURL = `http://127.0.0.1:${listener.address().port}${mountPath}`;
    const appId = `sdk-${randomUUID()}`;
    const masterKey = randomUUID();
    const restAPIKey = randomUUID();
    server = new ParseServer({
      appId, masterKey, restAPIKey, serverURL,
      databaseURI: mongo.getUri(),
      masterKeyIps: ['127.0.0.1', '::1'],
      allowClientClassCreation: true,
      cloud: path.join(__dirname, 'cloud.js'),
      filesAdapter: new MemoryFilesAdapter(serverURL, appId),
      requestComplexity: { batchRequestLimit: 20 },
      logLevel: 'error',
    });
    // The Express listener is owned here rather than by ParseServer.listen().
    // Register it so Parse Server can close it and its database connections.
    server.server = listener;
    await server.start();
    app.use(mountPath, server.app);
    console.log(`Integration baseline: Parse Server ${require('parse-server/package.json').version}, MongoDB ${mongoVersion}, Node ${process.versions.node}`);
    const status = await new Promise((resolve, reject) => {
      const child = spawn(process.env.RUBY || 'ruby', ['-Ilib', path.join(__dirname, 'rest_api_test.rb')], {
        cwd: path.resolve(__dirname, '../..'),
        env: {
          ...process.env,
          PARSE_STACK_INTEGRATION: '1',
          PARSE_STACK_INTEGRATION_URL: serverURL,
          PARSE_STACK_INTEGRATION_APP_ID: appId,
          PARSE_STACK_INTEGRATION_MASTER_KEY: masterKey,
          PARSE_STACK_INTEGRATION_REST_KEY: restAPIKey,
        },
        stdio: 'inherit',
      });
      const timeout = setTimeout(() => child.kill('SIGTERM'), 120000);
      child.once('error', error => { clearTimeout(timeout); reject(error); });
      child.once('exit', code => { clearTimeout(timeout); resolve(code === null ? 1 : code); });
    });
    process.exitCode = status;
  } finally {
    try {
      if (server) await server.handleShutdown();
      else if (listener) await new Promise(resolve => listener.close(resolve));
    } finally {
      if (mongo) await mongo.stop();
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
