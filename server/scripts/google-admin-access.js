// Local operator tool. Never imported by the game or the running backend.
import {GoogleAuth, OAuth2Client} from 'google-auth-library';
import {createServer} from 'node:http';
import {randomBytes, timingSafeEqual} from 'node:crypto';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {resolve, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const privateFolder = resolve(root, '.private/google-access');
const tokenFile = resolve(privateFolder, 'admob-token.json');
const PACKAGE = 'com.savethebaby.game';
export const ADMOB_SCOPE = 'https://www.googleapis.com/auth/admob.readonly';

async function readJson(path) {
  return JSON.parse((await readFile(path, 'utf8')).replace(/^\uFEFF/, ''));
}

export function desktopSettings(data) {
  const settings = data.installed;
  if (!settings?.client_id || !settings.client_secret) {
    throw new Error('Use a downloaded Desktop app OAuth client JSON from the Save the Baby Google Cloud project.');
  }
  if (settings.project_id !== 'save-the-baby-513514') {
    throw new Error('This OAuth client belongs to a different Google Cloud project. Use save-the-baby-513514.');
  }
  return settings;
}

export function validState(actual, expected) {
  if (typeof actual !== 'string' || typeof expected !== 'string') return false;
  const a = Buffer.from(actual), b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function safeFailure(error) {
  // Google client errors can contain authorization headers and private request
  // bodies. Never print the error object, stack, config or raw OAuth responses.
  const status = Number(error.response?.status || 0);
  if (status === 403) return 'Google denied access (403). Check API enablement, account permissions and OAuth test-user access.';
  if (status === 401) return 'Google rejected the authorization (401). Sign in again or check the credential.';
  if (status === 404) return 'Google could not find the requested app/account (404). Check account access.';
  if (status) return `Google request failed (HTTP ${status}). No credentials were printed.`;
  if (error.code === 'ENOENT') return 'The credential or saved authorization file is missing. Check the file path.';
  return 'Connection failed. Check the credential type, local file access and network. No credentials were printed.';
}

async function get(client, url) {
  const parsed = new URL(url);
  if (!['androidpublisher.googleapis.com', 'admob.googleapis.com'].includes(parsed.hostname) || parsed.protocol !== 'https:') {
    throw new Error('Unsupported API host.');
  }
  const result = await client.request({url, method: 'GET', timeout: 20000, retry: false});
  return result.data;
}

export function callbackServer(expectedState, consumeCode, timeoutMs = 1800000) {
  let complete, fail, timer, consumed = false;
  const done = new Promise((resolve, reject) => { complete = resolve; fail = reject; });
  const server = createServer(async (request, response) => {
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
    response.setHeader('Content-Type', 'text/plain; charset=utf-8');
    if (request.method !== 'GET') { response.writeHead(405).end('Use the browser sign-in callback.'); return; }
    const url = new URL(request.url, 'http://127.0.0.1');
    if (url.pathname !== '/oauth/callback') { response.writeHead(404).end('Not found.'); return; }
    if (!validState(url.searchParams.get('state'), expectedState)) { response.writeHead(400).end('Invalid sign-in state.'); return; }
    if (consumed) { response.writeHead(409).end('Sign-in is already being processed.'); return; }
    const code = url.searchParams.get('code');
    if (url.searchParams.has('error') || !code) {
      consumed = true;
      response.writeHead(400).end('Authorization was canceled. Return to your editor to retry.');
      fail(new Error('Google authorization was canceled.'));
      return;
    }
    consumed = true;
    try {
      await consumeCode(code);
      response.end('AdMob authorization saved. You can close this tab and return to your editor.');
      complete();
    } catch (error) {
      response.writeHead(500).end('Authorization could not be saved. Return to your editor to retry.');
      fail(error);
    }
  });
  server.on('error', fail);
  const ready = new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => resolve(`http://127.0.0.1:${server.address().port}/oauth/callback`));
  });
  timer = setTimeout(() => fail(new Error('Google sign-in timed out. Run the connection command again.')), timeoutMs);
  const close = () => { clearTimeout(timer); server.close(); server.closeAllConnections(); };
  // Attach a rejection handler immediately, including while the browser opens.
  done.catch(() => {});
  return {ready, done, close};
}

async function openBrowser(url) {
  // The URL comes from Google's auth library, not shell interpolation.
  const child = process.platform === 'win32'
    ? spawn('rundll32.exe', ['url.dll,FileProtocolHandler', url], {stdio: 'ignore', windowsHide: true})
    : spawn(process.platform === 'darwin' ? 'open' : 'xdg-open', [url], {stdio: 'ignore'});
  await new Promise((resolve, reject) => { child.once('error', reject); child.once('exit', code => code === 0 ? resolve() : reject(new Error('Browser could not open.'))); });
}

async function connectAdmob(clientPath) {
  const settings = desktopSettings(await readJson(clientPath));
  const state = randomBytes(32).toString('hex');
  const oauth = new OAuth2Client(settings.client_id, settings.client_secret);
  const {codeVerifier, codeChallenge} = await oauth.generateCodeVerifierAsync();
  const callback = callbackServer(state, async code => {
    const {tokens} = await oauth.getToken({code, codeVerifier});
    if (!tokens.refresh_token) throw new Error('No refresh token was granted. Retry the Google consent step.');
    if (tokens.scope && !tokens.scope.split(' ').includes(ADMOB_SCOPE)) throw new Error('AdMob read permission was not granted.');
    await mkdir(privateFolder, {recursive: true, mode: 0o700});
    await writeFile(tokenFile, JSON.stringify({clientPath: resolve(clientPath), tokens}), {mode: 0o600});
  });
  try {
    oauth.redirectUri = await callback.ready;
    const url = oauth.generateAuthUrl({access_type: 'offline', prompt: 'consent', scope: [ADMOB_SCOPE], state, code_challenge: codeChallenge, code_challenge_method: 'S256'});
    console.log('Opening Google. Choose the account that owns AdMob and approve read-only access.');
    console.log('Keep this terminal open until authorization finishes. You have 30 minutes to complete sign-in.');
    await openBrowser(url);
    await callback.done;
    console.log('AdMob authorization saved locally. Run admob-status to verify access.');
  } finally { callback.close(); }
}

async function admobStatus() {
  const saved = await readJson(tokenFile);
  const settings = desktopSettings(await readJson(saved.clientPath));
  const client = new OAuth2Client(settings.client_id, settings.client_secret);
  client.setCredentials(saved.tokens);
  const result = await get(client, 'https://admob.googleapis.com/v1/accounts');
  const accounts = [];
  for (const account of result.account || []) {
    const url = `https://admob.googleapis.com/v1/${account.name}/apps?pageSize=20000`;
    let next = url;
    const apps = [];
    do {
      const page = await get(client, next);
      apps.push(...(page.apps || []));
      next = page.nextPageToken ? `${url}&pageToken=${encodeURIComponent(page.nextPageToken)}` : '';
    } while (next);
    accounts.push({publisherId: account.publisherId, appCount: apps.length, game: apps.filter(app => app.linkedAppInfo?.appStoreId === PACKAGE)});
  }
  console.log(JSON.stringify({service: 'AdMob', connected: true, accounts}, null, 2));
}

async function admobAudit() {
  const saved = await readJson(tokenFile);
  const settings = desktopSettings(await readJson(saved.clientPath));
  const client = new OAuth2Client(settings.client_id, settings.client_secret);
  client.setCredentials(saved.tokens);
  const accounts = await get(client, 'https://admob.googleapis.com/v1/accounts');
  const report = {checkedAt: new Date().toISOString(), accounts: []};
  for (const account of accounts.account || []) {
    const apps = await get(client, `https://admob.googleapis.com/v1/${account.name}/apps?pageSize=20000`);
    const game = (apps.apps || []).find(app => app.linkedAppInfo?.appStoreId === PACKAGE);
    if (!game) continue;
    const units = [];
    let pageUrl = `https://admob.googleapis.com/v1/${account.name}/adUnits?pageSize=20000`;
    do {
      const page = await get(client, pageUrl);
      units.push(...(page.adUnits || []));
      pageUrl = page.nextPageToken ? `https://admob.googleapis.com/v1/${account.name}/adUnits?pageSize=20000&pageToken=${encodeURIComponent(page.nextPageToken)}` : '';
    } while (pageUrl);
    const entry = {publisherId: account.publisherId, game, adUnits: units.filter(unit => unit.appId === game.appId)};
    const end = new Date(), start = new Date(end);
    start.setUTCDate(start.getUTCDate() - 29);
    const date = value => ({year: value.getUTCFullYear(), month: value.getUTCMonth()+1, day: value.getUTCDate()});
    try {
      const response = await client.request({url: `https://admob.googleapis.com/v1/${account.name}/networkReport:generate`, method: 'POST', timeout: 30000, retry: false, data: {reportSpec: {
        dateRange: {startDate: date(start), endDate: date(end)},
        dimensions: ['DATE','AD_UNIT'], metrics: ['AD_REQUESTS','MATCHED_REQUESTS','IMPRESSIONS','CLICKS'],
        dimensionFilters: [{dimension: 'APP', matchesAny: {values: [game.appId]}}], maxReportRows: 10000,
      }}});
      entry.networkReport = response.data;
    } catch (error) { entry.networkReport = {error: safeFailure(error)}; }
    report.accounts.push(entry);
  }
  await mkdir(privateFolder, {recursive: true, mode: 0o700});
  await writeFile(resolve(privateFolder, 'admob-audit.json'), JSON.stringify(report, null, 2), {mode: 0o600});
  console.log(JSON.stringify(report, null, 2));
}

async function playStatus(keyFile) {
  const credential = await readJson(keyFile);
  if (credential.type !== 'service_account' || credential.project_id !== 'save-the-baby-513514') {
    console.log('Use the Save the Baby service-account JSON file. No credentials were printed.');
    process.exitCode = 1;
    return;
  }
  const auth = new GoogleAuth({credentials: credential, scopes: ['https://www.googleapis.com/auth/androidpublisher']});
  const client = await auth.getClient();
  const response = await get(client, `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/reviews?maxResults=1`);
  console.log(JSON.stringify({service: 'Google Play', connected: true, packageName: PACKAGE, check: 'read reviews', reviewReturned: Boolean(response.reviews?.length), limitation: 'No release, listing, purchase or account changes were made. This does not prove access to every Console setting.'}, null, 2));
}

export async function inspectPlayVisibility(client) {
  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/edits`;
  // Play exposes these reads inside an edit transaction. Never commit it.
  const {data: edit} = await client.request({url: base, method: 'POST', data: {}, timeout: 20000, retry: false});
  const editUrl = `${base}/${encodeURIComponent(edit.id)}`;
  const report = {packageName: PACKAGE, checkedAt: new Date().toISOString(), publishedChanges: false};
  try {
    for (const [key, path] of [['tracks','tracks'], ['productionCountries','countryAvailability/production'], ['listings','listings']]) {
      try { report[key] = await get(client, `${editUrl}/${path}`); }
      catch (error) { report[key] = {error: safeFailure(error)}; }
    }
  } finally {
    try {
      await client.request({url: editUrl, method: 'DELETE', timeout: 20000, retry: false});
      report.temporaryEditDeleted = true;
    } catch (error) {
      report.temporaryEditDeleted = false;
      report.cleanupError = safeFailure(error);
    }
  }
  return report;
}

async function playVisibility(keyFile) {
  const credential = await readJson(keyFile);
  if (credential.type !== 'service_account' || credential.project_id !== 'save-the-baby-513514') throw new Error('Wrong credential project.');
  const auth = new GoogleAuth({credentials: credential, scopes: ['https://www.googleapis.com/auth/androidpublisher']});
  const report = await inspectPlayVisibility(await auth.getClient());
  await mkdir(privateFolder, {recursive: true, mode: 0o700});
  await writeFile(resolve(privateFolder, 'play-visibility.json'), JSON.stringify(report, null, 2), {mode: 0o600});
  console.log(JSON.stringify(report, null, 2));
}

async function main() {
  const [command, path] = process.argv.slice(2);
  if (command === 'play-status' && path) await playStatus(path);
  else if (command === 'play-visibility' && path) await playVisibility(path);
  else if (command === 'connect-admob' && path) await connectAdmob(path);
  else if (command === 'admob-status') await admobStatus();
  else if (command === 'admob-audit') await admobAudit();
  else console.log('Usage: node server/scripts/google-admin-access.js play-status SERVICE_ACCOUNT_JSON | play-visibility SERVICE_ACCOUNT_JSON | connect-admob DESKTOP_OAUTH_JSON | admob-status');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => { console.error(safeFailure(error)); process.exitCode = 1; });
}
