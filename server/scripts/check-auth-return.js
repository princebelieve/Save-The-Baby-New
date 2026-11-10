// Read-only check against the deployed server; no login or credentials needed.
const base = (process.argv[2] || '').replace(/\/$/, '');
if (!/^https?:\/\//.test(base)) {
 console.error('Usage: node scripts/check-auth-return.js https://YOUR-SERVICE.onrender.com');
 process.exit(1);
}
try {
 for (const agent of ['Mozilla/5.0 (Linux; Android 14) Chrome/130 Mobile', 'Mozilla/5.0 Desktop']) {
  const response = await fetch(`${base}/auth/return`, {headers: {'User-Agent': agent}, signal: AbortSignal.timeout(60000)});
  const html = await response.text();
  if (!response.ok || response.headers.get('x-auth-return-version') !== '2' ||
      !html.includes('id="return-to-game"') || !html.includes('>Return to Save the Baby Game</a>') ||
      !html.includes(agent.includes('Android') ? 'intent://auth/complete' : 'href="savethebaby://auth/complete"')) {
   throw new Error(`Deployed login-return page is missing or outdated (HTTP ${response.status}). Deploy the updated server before calling this fixed.`);
  }
 }
 console.log('LIVE_AUTH_RETURN: PASS. Android and desktop return buttons are deployed. A phone login is still needed to confirm the app opens.');
} catch (error) {
 console.error(`LIVE_AUTH_RETURN: FAIL. ${error.message}`);
 process.exitCode = 1;
}
